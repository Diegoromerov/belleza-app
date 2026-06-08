// backend/src/controllers/bookingController.js
const { pool } = require('../config/db');
const { Booking, Service, User } = require('../models');
const { Op } = require('sequelize');

// 🔹 CREAR RESERVA
exports.createBooking = async (req, res) => {
  try {
    const clientId = req.user.id;
    const { provider_id, service_id, scheduled_at, service_address, notes } = req.body;

    if (!provider_id || !service_id || !scheduled_at) {
      return res.status(400).json({ error: 'Faltan campos requeridos' });
    }

    const service = await Service.findByPk(service_id);
    if (!service) {
      return res.status(404).json({ error: 'Servicio no encontrado' });
    }

    const price = parseFloat(service.price);
    const durationMinutes = parseInt(service.duration_minutes);
    const total_amount = price;

    // 🔸 Validación de solapamiento de horarios (Collision Check)
    const newStart = new Date(scheduled_at);
    const newEnd = new Date(newStart.getTime() + durationMinutes * 60 * 1000);
    const dateStr = newStart.toISOString().split('T')[0];

    // Consulta de solapamiento usando Sequelize
    const overlaps = await Booking.findAll({
      where: {
        provider_id,
        estado: { [Op.ne]: 'CANCELADA' }
      },
      include: [{
        model: Service,
        as: 'service',
        attributes: ['duration_minutes']
      }]
    });

    // Filtrar por el mismo día y verificar solapamiento
    for (const b of overlaps) {
      const bStart = new Date(b.scheduled_at);
      if (bStart.toISOString().split('T')[0] === dateStr) {
        const bDuration = parseInt(b.service.duration_minutes);
        const bEnd = new Date(bStart.getTime() + bDuration * 60 * 1000);

        if (newStart.getTime() < bEnd.getTime() && newEnd.getTime() > bStart.getTime()) {
          return res.status(409).json({ error: 'El horario seleccionado ya está reservado o entra en conflicto con otra cita' });
        }
      }
    }

    const pin = Math.floor(1000 + Math.random() * 9000).toString();

    const newBooking = await Booking.create({
      client_id: clientId,
      provider_id,
      service_id,
      scheduled_at: newStart,
      valor_bruto: total_amount,
      service_address: service_address || null,
      notes: notes || null,
      estado: 'PENDIENTE_PAGO',
      pin_verificacion: pin
    });

    console.log(`📅 Nueva cita creada: ${newBooking.id} para usuario ${clientId} con PIN ${pin}`);

    res.json({
      success: true,
      message: 'Cita reservada exitosamente',
      booking_id: newBooking.id,
      pin_verificacion: pin
    });

  } catch (error) {
    console.error('❌ ERROR EN /api/bookings:', { message: error.message, code: error.code });
    res.status(500).json({ error: 'Error al crear la reserva' });
  }
};

// 🔹 Panel de Prestador: Obtener citas
exports.getProviderBookings = async (req, res) => {
  try {
    if (req.user.role !== 'provider' && req.user.role !== 'PRESTADOR') {
      return res.status(403).json({ error: 'Acceso denegado: solo para proveedores' });
    }

    // Usamos pool para queries directas si son a tablas no mapeadas (o complejas), 
    // pero Sequelize es genial para obtener la estructura limpia.
    // Usamos pool para transacciones y relaciones para mantener compatibilidad con transactions
    const query = `
      SELECT 
        b.id, b.scheduled_at, b.estado AS status, b.valor_bruto AS total_amount, 
        b.comision_plataforma AS platform_commission, b.impuestos_estado AS state_tax, b.pago_neto_prestador AS provider_net_amount,
        b.client_id, b.pin_verificacion, b.service_address,
        s.name as service_name, s.price,
        u.nombre as client_name, u.phone as client_phone,
        t.external_id AS wompi_reference, t.status AS payout_status
      FROM bookings b
      JOIN services s ON b.service_id = s.id
      JOIN usuarios u ON b.client_id = u.id
      LEFT JOIN transactions t ON b.id = t.booking_id
      WHERE b.provider_id = $1
      ORDER BY b.scheduled_at ASC;
    `;
    
    const result = await pool.query(query, [req.user.id]);
    
    const formattedBookings = result.rows.map(row => ({
      id: row.id,
      client_id: row.client_id.toString(),
      scheduled_at: row.scheduled_at ? new Date(row.scheduled_at).toISOString() : null,
      status: row.status,
      total_amount: parseFloat(row.total_amount) || 0,
      platform_commission: parseFloat(row.platform_commission) || 0,
      state_tax: parseFloat(row.state_tax) || 0,
      provider_net_amount: parseFloat(row.provider_net_amount) || 0,
      service_name: row.service_name,
      price: parseFloat(row.price) || 0,
      client_name: row.client_name,
      client_phone: row.client_phone,
      service_address: row.service_address || '',
      pin_verificacion: row.pin_verificacion || null,
      wompi_reference: row.wompi_reference || null,
      payout_status: row.payout_status || null
    }));
    
    res.json({ success: true, count: formattedBookings.length, data: formattedBookings });
    
  } catch (error) {
    console.error('❌ ERROR EN /api/bookings/provider:', { message: error.message, code: error.code });
    res.status(500).json({ error: 'Error interno al cargar citas' });
  }
};

// 🔹 Actualizar estado de cita
exports.updateBookingStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const bookingId = req.params.id;
    const providerId = req.user.id;

    const mapStatusToDb = (status) => {
      const s = status.toUpperCase();
      if (s === 'PENDING' || s === 'PENDIENTE_PAGO') return 'PENDIENTE_PAGO';
      if (s === 'CONFIRMED' || s === 'CONFIRMADA') return 'CONFIRMADA';
      if (s === 'COMPLETED' || s === 'COMPLETADA') return 'COMPLETADA';
      if (s === 'CANCELLED' || s === 'CANCELADA') return 'CANCELADA';
      return s;
    };

    const dbStatus = mapStatusToDb(status);

    const validStatuses = ['PENDIENTE_PAGO', 'CONFIRMADA', 'EN_PROGRESO', 'FINALIZADA_PRESTADOR', 'COMPLETADA', 'CANCELADA'];
    if (!validStatuses.includes(dbStatus)) {
      return res.status(400).json({ error: `Estado inválido. Permitidos: ${validStatuses.join(', ')}` });
    }

    const booking = await Booking.findOne({
      where: { id: bookingId, provider_id: providerId }
    });

    if (!booking) {
      return res.status(404).json({ error: 'Cita no encontrada o no te pertenece' });
    }

    booking.estado = dbStatus;
    await booking.save();

    console.log('✅ Cita actualizada a estado:', dbStatus);
    
    res.json({ 
      success: true, 
      booking: {
        id: booking.id,
        status: booking.estado
      } 
    });
    
  } catch (error) {
    console.error('❌ ERROR EN PATCH /api/bookings/:id/status:', { message: error.message, code: error.code });
    res.status(500).json({ error: 'Error al actualizar estado' });
  }
};

// 🔹 Historial de Citas del Cliente
exports.getClientBookings = async (req, res) => {
  try {
    const clientId = req.user.id;

    const query = `
      SELECT 
        b.id, b.scheduled_at, b.estado AS status, b.valor_bruto AS total_amount, b.service_address, b.notes, b.pin_verificacion,
        s.name as service_name, s.duration_minutes as service_duration,
        u_prov.nombre as provider_name,
        p.business_name as provider_business_name,
        u_prov.foto_url as provider_avatar_url,
        u_prov.phone as provider_phone,
        r.id as review_id, r.rating as review_rating, r.comment as review_comment
      FROM bookings b
      JOIN services s ON b.service_id = s.id
      JOIN perfiles_prestador p ON b.provider_id = p.id
      JOIN usuarios u_prov ON p.id = u_prov.id
      LEFT JOIN reviews r ON b.id = r.booking_id
      WHERE b.client_id = $1
      ORDER BY b.scheduled_at DESC;
    `;
    
    const result = await pool.query(query, [clientId]);
    
    const formattedBookings = result.rows.map(row => ({
      id: row.id,
      scheduled_at: row.scheduled_at ? new Date(row.scheduled_at).toISOString() : null,
      status: row.status,
      total_amount: parseFloat(row.total_amount) || 0,
      service_address: row.service_address || '',
      notes: row.notes || '',
      pin_verificacion: row.pin_verificacion || null,
      service_name: row.service_name,
      service_duration: parseInt(row.service_duration) || 0,
      provider_name: row.provider_name,
      provider_business_name: row.provider_business_name || '',
      provider_avatar_url: row.provider_avatar_url || '',
      provider_phone: row.provider_phone || '',
      is_reviewed: row.review_id !== null,
      review: row.review_id ? {
        id: row.review_id,
        rating: parseInt(row.review_rating) || 0,
        comment: row.review_comment || ''
      } : null
    }));
    
    res.json({ success: true, count: formattedBookings.length, data: formattedBookings });
    
  } catch (error) {
    console.error('❌ ERROR EN /api/bookings/client:', { message: error.message, code: error.code });
    res.status(500).json({ error: 'Error interno al cargar el historial de citas' });
  }
};

// 🔹 Cancelar cita por cliente
exports.cancelBooking = async (req, res) => {
  try {
    const bookingId = req.params.id;
    const clientId = req.user.id;

    const booking = await Booking.findOne({
      where: { id: bookingId, client_id: clientId }
    });

    if (!booking) {
      return res.status(404).json({ error: 'Cita no encontrada o no tienes permisos para cancelarla' });
    }

    if (booking.estado === 'CANCELADA') {
      return res.status(400).json({ error: 'La cita ya está cancelada' });
    }
    if (booking.estado === 'COMPLETADA') {
      return res.status(400).json({ error: 'No se puede cancelar una cita que ya ha sido completada' });
    }

    booking.estado = 'CANCELADA';
    await booking.save();

    console.log(`❌ Cita ${bookingId} cancelada por el cliente ${clientId}`);

    res.json({
      success: true,
      message: 'Cita cancelada exitosamente',
      booking: {
        id: booking.id,
        status: booking.estado
      }
    });

  } catch (error) {
    console.error('❌ ERROR EN PATCH /api/bookings/:id/cancel:', { message: error.message, code: error.code });
    res.status(500).json({ error: 'Error interno al cancelar la cita' });
  }
};

// 🔹 Simular Pago con Wompi para una cita (Cliente)
exports.payBooking = async (req, res) => {
  try {
    const bookingId = req.params.id;
    const clientId = req.user.id;
    const { payment_method } = req.body;

    const method = (payment_method || 'NEQUI').toUpperCase();
    if (!['NEQUI', 'CARD'].includes(method)) {
      return res.status(400).json({ error: 'Método de pago inválido. Permitidos: NEQUI, CARD' });
    }

    const booking = await Booking.findOne({
      where: { id: bookingId, client_id: clientId }
    });

    if (!booking) {
      return res.status(404).json({ error: 'Cita no encontrada o no tienes permisos para pagarla' });
    }

    if (booking.estado !== 'PENDIENTE_PAGO') {
      return res.status(400).json({ error: `La cita no se encuentra en estado PENDIENTE_PAGO. Estado actual: ${booking.estado}` });
    }

    await new Promise(resolve => setTimeout(resolve, 1500));

    const referenceToken = 'wompi_tx_' + Math.random().toString(36).substring(2, 11).toUpperCase();

    const clientDb = await pool.connect();
    try {
      await clientDb.query('BEGIN');

      // 1. Actualizar el estado de la cita
      await clientDb.query(
        `UPDATE bookings
         SET estado = 'CONFIRMADA', payment_status = 'paid'
         WHERE id = $1 AND client_id = $2`,
        [bookingId, clientId]
      );

      // 2. Registrar la transacción
      const txQuery = `
        INSERT INTO transactions (booking_id, amount, status, payment_method, external_id)
        VALUES ($1, $2, 'paid', $3, $4)
        ON CONFLICT (booking_id)
        DO UPDATE SET
          amount = EXCLUDED.amount,
          status = 'paid',
          payment_method = EXCLUDED.payment_method,
          external_id = EXCLUDED.external_id;
      `;
      await clientDb.query(txQuery, [bookingId, booking.valor_bruto, method, referenceToken]);

      await clientDb.query('COMMIT');

      console.log(`\n💳 [WOMPI WEBHOOK SIMULATOR] Pago completado con éxito. Cita: ${bookingId}. Referencia: ${referenceToken}`);

      res.json({
        success: true,
        message: 'Pago procesado y verificado con éxito por Wompi',
        booking_id: bookingId,
        reference: referenceToken,
        amount: parseFloat(booking.valor_bruto),
        payment_method: method
      });

    } catch (dbErr) {
      await clientDb.query('ROLLBACK');
      throw dbErr;
    } finally {
      clientDb.release();
    }

  } catch (error) {
    console.error('❌ ERROR EN POST /api/bookings/:id/pay:', error);
    res.status(500).json({ error: 'Error interno al procesar el pago' });
  }
};

// 🔹 Webhook Simulado de Wompi
exports.wompiWebhook = async (req, res) => {
  try {
    const { event, data } = req.body;
    console.log('📡 [WOMPI WEBHOOK RECEIVED] Evento:', event);

    if (event === 'transaction.updated' && data && data.transaction) {
      const tx = data.transaction;
      const bookingId = tx.reference;
      const status = tx.status;
      const amount = tx.amount_in_cents / 100;
      const paymentMethod = tx.payment_method_type || 'NEQUI';
      const externalId = tx.id;

      if (status === 'APPROVED') {
        const clientDb = await pool.connect();
        try {
          await clientDb.query('BEGIN');

          await clientDb.query(
            "UPDATE bookings SET estado = 'CONFIRMADA', payment_status = 'paid' WHERE id = $1",
            [bookingId]
          );

          await clientDb.query(`
            INSERT INTO transactions (booking_id, amount, status, payment_method, external_id)
            VALUES ($1, $2, 'paid', $3, $4)
            ON CONFLICT (booking_id) DO UPDATE SET
              status = 'paid',
              external_id = EXCLUDED.external_id;
          `, [bookingId, amount, paymentMethod, externalId]);

          await clientDb.query('COMMIT');
          console.log(`✅ [WOMPI WEBHOOK SUCCESS] Cita ${bookingId} confirmada por webhook.`);
        } catch (dbErr) {
          await clientDb.query('ROLLBACK');
          throw dbErr;
        } finally {
          clientDb.release();
        }
      }
    }

    res.json({ success: true });
  } catch (error) {
    console.error('❌ ERROR EN /api/payments/wompi-webhook:', error);
    res.status(500).json({ error: 'Error al procesar el webhook' });
  }
};

// 🔹 Crear reseña para cita completada
exports.createReview = async (req, res) => {
  try {
    const bookingId = req.params.id;
    const clientId = req.user.id;
    const { rating, comment } = req.body;

    const parsedRating = parseInt(rating);
    if (isNaN(parsedRating) || parsedRating < 1 || parsedRating > 5) {
      return res.status(400).json({ error: 'La calificación debe ser un número entero entre 1 y 5' });
    }

    const booking = await Booking.findOne({
      where: { id: bookingId, client_id: clientId }
    });

    if (!booking) {
      return res.status(404).json({ error: 'Cita no encontrada o no tienes permisos para calificarla' });
    }

    if (booking.estado !== 'COMPLETADA') {
      return res.status(400).json({ error: 'Solo puedes calificar citas que hayan sido completadas' });
    }

    const reviewCheck = await pool.query('SELECT id FROM reviews WHERE booking_id = $1', [bookingId]);
    if (reviewCheck.rows.length > 0) {
      return res.status(400).json({ error: 'Esta cita ya ha sido calificada' });
    }

    const clientDb = await pool.connect();
    try {
      await clientDb.query('BEGIN');

      const insertReviewQuery = `
        INSERT INTO reviews (booking_id, client_id, provider_id, rating, comment)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING id;
      `;
      await clientDb.query(insertReviewQuery, [bookingId, clientId, booking.provider_id, parsedRating, comment || null]);

      const statsQuery = 'SELECT AVG(rating) as avg_rating, COUNT(id) as count_rating FROM reviews WHERE provider_id = $1;';
      const statsRes = await clientDb.query(statsQuery, [booking.provider_id]);
      const avg = parseFloat(statsRes.rows[0].avg_rating) || 0.0;
      const count = parseInt(statsRes.rows[0].count_rating) || 0;

      const updateProviderQuery = 'UPDATE perfiles_prestador SET rating_avg = $1, rating_count = $2 WHERE id = $3;';
      await clientDb.query(updateProviderQuery, [avg, count, booking.provider_id]);

      await clientDb.query('COMMIT');

      res.json({
        success: true,
        message: 'Reseña publicada con éxito y reputación del proveedor actualizada',
        data: { rating_avg: avg, rating_count: count }
      });
    } catch (e) {
      await clientDb.query('ROLLBACK');
      throw e;
    } finally {
      clientDb.release();
    }

  } catch (error) {
    console.error('❌ ERROR EN POST /api/bookings/:id/review:', { message: error.message, code: error.code });
    res.status(500).json({ error: 'Error interno al guardar la reseña' });
  }
};

// 🔹 INICIAR SERVICIO
exports.startService = async (req, res) => {
  try {
    const bookingId = req.params.id;
    const providerId = req.user.id;

    const booking = await Booking.findOne({
      where: { id: bookingId, provider_id: providerId }
    });

    if (!booking) {
      return res.status(404).json({ error: 'Cita no encontrada o no tienes permisos para iniciarla' });
    }

    if (booking.estado !== 'CONFIRMADA') {
      return res.status(400).json({ error: `No se puede iniciar el servicio. El estado actual es ${booking.estado} (debe ser CONFIRMADA).` });
    }

    booking.estado = 'EN_PROGRESO';
    await booking.save();

    console.log(`🚀 Servicio iniciado para cita ${bookingId} por prestador ${providerId}`);

    res.json({
      success: true,
      message: 'Servicio iniciado con éxito',
      booking: {
        id: booking.id,
        status: booking.estado
      }
    });

  } catch (error) {
    console.error('❌ ERROR EN PATCH /api/bookings/:id/start:', error);
    res.status(500).json({ error: 'Error interno al iniciar el servicio' });
  }
};
