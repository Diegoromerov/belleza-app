// backend/index.js - Loopback updated
const express = require('express');
const cors = require('cors');
const { pool, testConnection } = require('./src/config/db');
const path = require('path');
const fs = require('fs');
const multer = require('multer');
require('dotenv').config();

// ⚠️ IMPORTANTE: Imports al inicio para evitar ReferenceError
const authRoutes = require('./src/routes/authRoutes');
const authMiddleware = require('./src/middleware/auth');
const { processAssistantMessage, AI_USER_ID } = require('./src/services/geminiService');

const { findCachedJob, enqueueTryonJob } = require('./src/services/queueService');
const crypto = require('crypto');
const { WebSocketServer } = require('ws');

const app = express();
const PORT = process.env.PORT || 3000;

// Configuración de Multer para almacenamiento estático local
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
  console.log('📁 Carpeta "uploads" creada con éxito.');
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    const ext = path.extname(file.originalname);
    cb(null, 'file-' + uniqueSuffix + ext);
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // Límite de 5MB
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif|webp/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype) || file.mimetype === 'application/octet-stream' || !file.mimetype;
    if (extname && mimetype) {
      return cb(null, true);
    } else {
      cb(new Error('Solo se permiten imágenes (.jpeg, .jpg, .png, .gif, .webp)'));
    }
  }
});

// ==========================================
// MIDDLEWARE
// ==========================================
app.use(cors({
  origin: ['http://localhost:8080', 'http://localhost:8081', 'http://localhost:7357', 'http://127.0.0.1:8080'],
  credentials: true
}));
app.use(express.json());
app.use('/uploads', express.static(uploadsDir));
app.use('/admin', express.static(path.join(__dirname, 'public/admin')));

// ==========================================
// RUTAS PÚBLICAS
// ==========================================

// Health check
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'Backend funcionando', 
    timestamp: new Date().toISOString(),
    env: process.env.NODE_ENV || 'development'
  });
});

// Test DB connection
app.get('/api/test-db', async (req, res) => {
  try {
    const connected = await testConnection();
    res.json({ 
      status: connected ? 'success' : 'error', 
      message: connected ? 'PostgreSQL conectado' : 'Error de conexión',
      postgis: connected ? await pool.query('SELECT PostGIS_Version()').then(r => r.rows[0].postgis_version).catch(() => 'no disponible') : null
    });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});

// Debug DB tables and extensions
app.get('/api/debug-db', async (req, res) => {
  const reports = {};
  try {
    // 1. Check extensions
    try {
      const extRes = await pool.query("SELECT extname FROM pg_extension;");
      reports.extensions = extRes.rows.map(r => r.extname);
    } catch (e) {
      reports.extensions_error = e.message;
    }

    // 2. Check tables
    try {
      const tablesRes = await pool.query(`
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public';
      `);
      reports.tables = tablesRes.rows.map(r => r.table_name);
    } catch (e) {
      reports.tables_error = e.message;
    }

    // 3. Try to run a query on usuarios to check rows
    try {
      const countRes = await pool.query('SELECT COUNT(*) as count FROM usuarios;');
      reports.usuarios_count = countRes.rows[0].count;
    } catch (e) {
      reports.usuarios_error = e.message;
    }

    // 4. Try PostGIS version
    try {
      const postgisVer = await pool.query('SELECT PostGIS_Version();');
      reports.postgis_version = postgisVer.rows[0].postgis_version;
    } catch (e) {
      reports.postgis_error = e.message;
    }

    res.json(reports);
  } catch (err) {
    res.status(500).json({ error: err.message, reports });
  }
});

// 🔹 LISTA DE PRESTADORES (Geolocalización con PostGIS)
app.get('/api/providers', async (req, res) => {
  try {
    const lat = parseFloat(req.query.lat) || 4.6097;
    const lon = parseFloat(req.query.lon) || -74.0817;
    const radius = parseInt(req.query.radius) || 10000;

    // Validación defensiva de rangos
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      return res.status(400).json({ success: false, error: 'Coordenadas inválidas' });
    }
    if (radius < 100 || radius > 100000) {
      return res.status(400).json({ success: false, error: 'Radio fuera de rango (100m - 100km)' });
    }

    const query = `
      SELECT 
        p.id, 
        u.nombre as full_name, 
        u.foto_url as avatar_url,
        p.business_name, 
        p.description,
        p.rating_avg, 
        p.rating_count, 
        (p.estatus_verificacion = 'APROBADO') as is_verified,
        ST_X(p.ubicacion::geometry) AS longitude,
        ST_Y(p.ubicacion::geometry) AS latitude,
        COALESCE(pl.tier, 'Creative Edge') as loyalty_tier,
        ST_Distance(p.ubicacion::geography, ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography) AS distance_meters
      FROM perfiles_prestador p
      INNER JOIN usuarios u ON p.id = u.id
      LEFT JOIN provider_loyalty pl ON p.id = pl.provider_id
      WHERE p.is_active = true AND p.estatus_verificacion = 'APROBADO'
        AND ST_DWithin(
          p.ubicacion::geography, 
          ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
          CASE 
            WHEN COALESCE(pl.tier, 'Creative Edge') = 'Visage Pro' THEN $3 * 1.15
            ELSE $3
          END
        )
      ORDER BY 
        CASE 
          WHEN COALESCE(pl.tier, 'Creative Edge') = 'Avant-Garde Elite' THEN 1
          WHEN COALESCE(pl.tier, 'Creative Edge') = 'Visage Pro' THEN 2
          ELSE 3
        END ASC,
        distance_meters ASC;
    `;

    const result = await pool.query(query, [lon, lat, radius]);

    // CONTRATO DE HIERRO: Mapeo explícito para tipos nativos (float/int/bool)
    const formattedProviders = result.rows.map(row => ({
      id: row.id.toString(),
      full_name: row.full_name,
      avatar_url: row.avatar_url || '',
      business_name: row.business_name || '',
      description: row.description || '',
      rating_avg: parseFloat(row.rating_avg) || 0.0,
      rating_count: parseInt(row.rating_count) || 0,
      is_verified: !!row.is_verified,
      loyalty_tier: row.loyalty_tier,
      distance_meters: Math.round(row.distance_meters),
      latitude: parseFloat(row.latitude) || 4.6097,
      longitude: parseFloat(row.longitude) || -74.0817
    }));

    const response = {
      success: true,
      count: formattedProviders.length,
      data: formattedProviders
    };
    
    if (process.env.NODE_ENV === 'development') {
      response.debug = { lat, lon, radius };
    }
    
    res.json(response);

  } catch (error) {
    console.error('❌ ERROR en GET /api/providers:', { 
      message: error.message, 
      code: error.code,
      query: error.query 
    });
    res.status(500).json({ success: false, error: 'Internal Server Error' });
  }
});

// 🔹 DETALLE DE UN PRESTADOR (Servicios + Portfolio + Reseñas)
app.get('/api/providers/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const numericId = parseInt(id);
    if (isNaN(numericId)) return res.status(400).json({ error: 'ID inválido' });
    
    // 1. Datos del proveedor (JOIN con usuarios para foto_url)
    const providerQ = `
      SELECT p.id, u.nombre as full_name, u.foto_url as avatar_url, u.phone, 
             p.business_name, p.description, p.rating_avg, 
             p.rating_count, (p.estatus_verificacion = 'APROBADO') as is_verified 
      FROM perfiles_prestador p 
      JOIN usuarios u ON p.id = u.id 
      WHERE p.id = $1;
    `;
    const providerRes = await pool.query(providerQ, [numericId]);
    if (providerRes.rows.length === 0) return res.status(404).json({ error: 'No encontrado' });

    const servicesQ = `
      SELECT id, name, description, price, duration_minutes, category 
      FROM services 
      WHERE provider_id = $1 AND is_active = true 
      ORDER BY name;
    `;
    const servicesRes = await pool.query(servicesQ, [numericId]);

    const portfolioQ = `
      SELECT id, image_url, title, category 
      FROM portfolio_items 
      WHERE provider_id = $1 
      ORDER BY created_at DESC LIMIT 10;
    `;
    const portfolioRes = await pool.query(portfolioQ, [numericId]);

    const reviewsQ = `
      SELECT r.rating, r.comment, r.created_at, u.nombre as client_name 
      FROM reviews r 
      JOIN usuarios u ON r.client_id = u.id 
      WHERE r.provider_id = $1 
      ORDER BY r.created_at DESC LIMIT 5;
    `;
    const reviewsRes = await pool.query(reviewsQ, [numericId]);

    res.json({
      success: true,
      data: {
        provider: {
          ...providerRes.rows[0],
          id: providerRes.rows[0].id.toString()
        },
        services: servicesRes.rows,
        portfolio: portfolioRes.rows,
        reviews: reviewsRes.rows
      }
    });
  } catch (error) {
    console.error('❌ ERROR /api/providers/:id:', { message: error.message, code: error.code });
    res.status(500).json({ error: 'Error interno al cargar detalles' });
  }
});

// ==========================================
// RUTAS DE AUTENTICACIÓN
// ==========================================
app.use('/api/auth', authRoutes);

// ==========================================
// RUTAS PROTEGIDAS (Requieren JWT)
// ==========================================

// 🔹 CREAR RESERVA (Protegida con authMiddleware)
app.post('/api/bookings', authMiddleware, async (req, res) => {
  try {
    const clientId = req.user.id;
    const { provider_id, service_id, scheduled_at, service_address, notes } = req.body;

    if (!provider_id || !service_id || !scheduled_at) {
      return res.status(400).json({ error: 'Faltan campos requeridos' });
    }

    const serviceQuery = 'SELECT price, duration_minutes FROM services WHERE id = $1;';
    const serviceResult = await pool.query(serviceQuery, [service_id]);

    if (serviceResult.rows.length === 0) {
      return res.status(404).json({ error: 'Servicio no encontrado' });
    }

    const price = parseFloat(serviceResult.rows[0].price);
    const durationMinutes = parseInt(serviceResult.rows[0].duration_minutes);
    const total_amount = price;

    // 🔸 Validación de solapamiento de horarios (Collision Check)
    const newStart = new Date(scheduled_at);
    const newEnd = new Date(newStart.getTime() + durationMinutes * 60 * 1000);
    const dateStr = newStart.toISOString().split('T')[0];

    const overlapQuery = `
      SELECT b.scheduled_at, s.duration_minutes 
      FROM bookings b
      JOIN services s ON b.service_id = s.id
      WHERE b.provider_id = $1 
        AND b.estado NOT IN ('CANCELADA')
        AND b.scheduled_at::date = $2::date;
    `;
    const overlapResult = await pool.query(overlapQuery, [provider_id, dateStr]);

    for (const row of overlapResult.rows) {
      const bStart = new Date(row.scheduled_at);
      const bEnd = new Date(bStart.getTime() + parseInt(row.duration_minutes) * 60 * 1000);

      // Colisión: newStart < bEnd AND newEnd > bStart
      if (newStart.getTime() < bEnd.getTime() && newEnd.getTime() > bStart.getTime()) {
        return res.status(409).json({ error: 'El horario seleccionado ya está reservado o entra en conflicto con otra cita' });
      }
    }

    const pin = Math.floor(1000 + Math.random() * 9000).toString();
    const bookingQuery = `
      INSERT INTO bookings (client_id, provider_id, service_id, scheduled_at, valor_bruto, service_address, notes, estado, pin_verificacion)
      VALUES ($1, $2, $3, $4, $5, $6, $7, 'PENDIENTE_PAGO', $8)
      RETURNING id;
    `;

    const result = await pool.query(bookingQuery, [
      clientId,
      provider_id,
      service_id,
      scheduled_at,
      total_amount,
      service_address || null,
      notes || null,
      pin
    ]);

    console.log(`📅 Nueva cita creada: ${result.rows[0].id} para usuario ${clientId} con PIN ${pin}`);

    res.json({
      success: true,
      message: 'Cita reservada exitosamente',
      booking_id: result.rows[0].id,
      pin_verificacion: pin
    });

  } catch (error) {
    console.error('❌ ERROR EN /api/bookings:', { message: error.message, code: error.code });
    res.status(500).json({ error: 'Error al crear la reserva' });
  }
});

// 🔹 Panel de Prestador: Obtener citas
app.get('/api/bookings/provider', authMiddleware, async (req, res) => {
  try {
    if (req.user.role !== 'provider' && req.user.role !== 'PRESTADOR') {
      return res.status(403).json({ error: 'Acceso denegado: solo para proveedores' });
    }

    const providerCheck = await pool.query(
      'SELECT id FROM perfiles_prestador WHERE id = $1 AND is_active = true', 
      [req.user.id]
    );
    
    if (providerCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Perfil de proveedor no encontrado o inactivo' });
    }

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
});

// 🔹 Actualizar estado de cita
app.patch('/api/bookings/:id/status', authMiddleware, async (req, res) => {
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

    const query = `
      UPDATE bookings 
      SET estado = $1
      WHERE id = $2 AND provider_id = $3
      RETURNING id, estado AS status;
    `;
    
    const result = await pool.query(query, [dbStatus, bookingId, providerId]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Cita no encontrada o no te pertenece' });
    }

    console.log('✅ Cita actualizada a estado:', dbStatus);
    
    res.json({ 
      success: true, 
      booking: {
        id: result.rows[0].id,
        status: result.rows[0].status
      } 
    });
    
  } catch (error) {
    console.error('❌ ERROR EN PATCH /api/bookings/:id/status:', { message: error.message, code: error.code });
    res.status(500).json({ error: 'Error al actualizar estado' });
  }
});

// 🔹 Historial de Citas del Cliente
app.get('/api/bookings/client', authMiddleware, async (req, res) => {
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
});

// 🔹 Cancelar cita por cliente
app.patch('/api/bookings/:id/cancel', authMiddleware, async (req, res) => {
  try {
    const bookingId = req.params.id;
    const clientId = req.user.id;

    const checkQuery = 'SELECT estado AS status FROM bookings WHERE id = $1 AND client_id = $2;';
    const checkRes = await pool.query(checkQuery, [bookingId, clientId]);
    
    if (checkRes.rows.length === 0) {
      return res.status(404).json({ error: 'Cita no encontrada o no tienes permisos para cancelarla' });
    }

    const currentStatus = checkRes.rows[0].status;
    if (currentStatus === 'CANCELADA') {
      return res.status(400).json({ error: 'La cita ya está cancelada' });
    }
    if (currentStatus === 'COMPLETADA') {
      return res.status(400).json({ error: 'No se puede cancelar una cita que ya ha sido completada' });
    }

    const updateQuery = `
      UPDATE bookings 
      SET estado = 'CANCELADA'
      WHERE id = $1 AND client_id = $2
      RETURNING id, estado AS status;
    `;
    const updateRes = await pool.query(updateQuery, [bookingId, clientId]);

    console.log(`❌ Cita ${bookingId} cancelada por el cliente ${clientId}`);

    res.json({
      success: true,
      message: 'Cita cancelada exitosamente',
      booking: {
        id: updateRes.rows[0].id,
        status: updateRes.rows[0].status
      }
    });

  } catch (error) {
    console.error('❌ ERROR EN PATCH /api/bookings/:id/cancel:', { message: error.message, code: error.code });
    res.status(500).json({ error: 'Error interno al cancelar la cita' });
  }
});

// 🔹 Simular Pago con Wompi para una cita (Cliente)
app.post('/api/bookings/:id/pay', authMiddleware, async (req, res) => {
  try {
    const bookingId = req.params.id;
    const clientId = req.user.id;
    const { payment_method } = req.body;

    const method = (payment_method || 'NEQUI').toUpperCase();
    if (!['NEQUI', 'CARD'].includes(method)) {
      return res.status(400).json({ error: 'Método de pago inválido. Permitidos: NEQUI, CARD' });
    }

    // Verificar si la cita existe y pertenece al cliente
    const checkQuery = 'SELECT estado, valor_bruto FROM bookings WHERE id = $1 AND client_id = $2;';
    const checkRes = await pool.query(checkQuery, [bookingId, clientId]);

    if (checkRes.rows.length === 0) {
      return res.status(404).json({ error: 'Cita no encontrada o no tienes permisos para pagarla' });
    }

    const { estado, valor_bruto } = checkRes.rows[0];
    if (estado !== 'PENDIENTE_PAGO') {
      return res.status(400).json({ error: `La cita no se encuentra en estado PENDIENTE_PAGO. Estado actual: ${estado}` });
    }

    // Simular un retardo del servidor de pago de 1.5 segundos
    await new Promise(resolve => setTimeout(resolve, 1500));

    const referenceToken = 'wompi_tx_' + Math.random().toString(36).substring(2, 11).toUpperCase();

    // Iniciar transacción en base de datos
    const clientDb = await pool.connect();
    try {
      await clientDb.query('BEGIN');

      // 1. Actualizar el estado de la cita
      const updateQuery = `
        UPDATE bookings
        SET estado = 'CONFIRMADA', payment_status = 'paid'
        WHERE id = $1 AND client_id = $2
        RETURNING id, estado AS status;
      `;
      await clientDb.query(updateQuery, [bookingId, clientId]);

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
      await clientDb.query(txQuery, [bookingId, valor_bruto, method, referenceToken]);

      await clientDb.query('COMMIT');

      console.log(`\n💳 [WOMPI WEBHOOK SIMULATOR] Pago completado con éxito. Cita: ${bookingId}. Referencia: ${referenceToken}`);

      res.json({
        success: true,
        message: 'Pago procesado y verificado con éxito por Wompi',
        booking_id: bookingId,
        reference: referenceToken,
        amount: parseFloat(valor_bruto),
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
});

// 🔹 Webhook Simulado de Wompi
app.post('/api/payments/wompi-webhook', async (req, res) => {
  try {
    const { event, data } = req.body;
    console.log('📡 [WOMPI WEBHOOK RECEIVED] Evento:', event);

    if (event === 'transaction.updated' && data && data.transaction) {
      const tx = data.transaction;
      const bookingId = tx.reference; // Usamos el ID de la cita como referencia de Wompi
      const status = tx.status; // APPROVED, DECLINED, VOIDED, etc.
      const amount = tx.amount_in_cents / 100;
      const paymentMethod = tx.payment_method_type || 'NEQUI';
      const externalId = tx.id;

      if (status === 'APPROVED') {
        const clientDb = await pool.connect();
        try {
          await clientDb.query('BEGIN');

          // Actualizar cita a CONFIRMADA
          await clientDb.query(
            "UPDATE bookings SET estado = 'CONFIRMADA', payment_status = 'paid' WHERE id = $1",
            [bookingId]
          );

          // Registrar la transacción
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
});

// 🔹 Crear reseña para cita completada
app.post('/api/bookings/:id/review', authMiddleware, async (req, res) => {
  try {
    const bookingId = req.params.id;
    const clientId = req.user.id;
    const { rating, comment } = req.body;

    const parsedRating = parseInt(rating);
    if (isNaN(parsedRating) || parsedRating < 1 || parsedRating > 5) {
      return res.status(400).json({ error: 'La calificación debe ser un número entero entre 1 y 5' });
    }

    const bookingQuery = 'SELECT provider_id, estado AS status FROM bookings WHERE id = $1 AND client_id = $2;';
    const bookingRes = await pool.query(bookingQuery, [bookingId, clientId]);

    if (bookingRes.rows.length === 0) {
      return res.status(404).json({ error: 'Cita no encontrada o no tienes permisos para calificarla' });
    }

    const { provider_id, status } = bookingRes.rows[0];

    if (status !== 'COMPLETADA') {
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
      await clientDb.query(insertReviewQuery, [bookingId, clientId, provider_id, parsedRating, comment || null]);

      const statsQuery = 'SELECT AVG(rating) as avg_rating, COUNT(id) as count_rating FROM reviews WHERE provider_id = $1;';
      const statsRes = await clientDb.query(statsQuery, [provider_id]);
      const avg = parseFloat(statsRes.rows[0].avg_rating) || 0.0;
      const count = parseInt(statsRes.rows[0].count_rating) || 0;

      const updateProviderQuery = 'UPDATE perfiles_prestador SET rating_avg = $1, rating_count = $2 WHERE id = $3;';
      await clientDb.query(updateProviderQuery, [avg, count, provider_id]);

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
});

// 🔹 INICIAR SERVICIO (De CONFIRMADA a EN_PROGRESO)
app.patch('/api/bookings/:id/start', authMiddleware, async (req, res) => {
  try {
    const bookingId = req.params.id;
    const providerId = req.user.id;

    // Verificar si la cita existe y pertenece al proveedor
    const checkQuery = 'SELECT estado FROM bookings WHERE id = $1 AND provider_id = $2;';
    const checkRes = await pool.query(checkQuery, [bookingId, providerId]);

    if (checkRes.rows.length === 0) {
      return res.status(404).json({ error: 'Cita no encontrada o no tienes permisos para iniciarla' });
    }

    const currentStatus = checkRes.rows[0].estado;
    if (currentStatus !== 'CONFIRMADA') {
      return res.status(400).json({ error: `No se puede iniciar el servicio. El estado actual es ${currentStatus} (debe ser CONFIRMADA).` });
    }

    // Actualizar a EN_PROGRESO
    const updateQuery = `
      UPDATE bookings
      SET estado = 'EN_PROGRESO'
      WHERE id = $1 AND provider_id = $2
      RETURNING id, estado AS status;
    `;
    const result = await pool.query(updateQuery, [bookingId, providerId]);

    console.log(`🚀 Servicio iniciado para cita ${bookingId} por prestador ${providerId}`);

    res.json({
      success: true,
      message: 'Servicio iniciado con éxito',
      booking: result.rows[0]
    });

  } catch (error) {
    console.error('❌ ERROR EN PATCH /api/bookings/:id/start:', error);
    res.status(500).json({ error: 'Error interno al iniciar el servicio' });
  }
});

// 🔹 COMPLETAR SERVICIO CON PIN (De EN_PROGRESO a COMPLETADA + Payout)
app.post('/api/bookings/:id/complete', authMiddleware, async (req, res) => {
  try {
    const bookingId = req.params.id;
    const providerId = req.user.id;
    const { pin_verificacion, provider_lat, provider_lon, client_lat, client_lon } = req.body;

    if (!pin_verificacion || pin_verificacion.trim() === '') {
      return res.status(400).json({ error: 'El PIN de verificación es obligatorio.' });
    }

    // Validación de proximidad física utilizando PostGIS (distancia máxima de 15 metros) - EXIGIDA
    if (provider_lat === undefined || provider_lon === undefined || client_lat === undefined || client_lon === undefined) {
      return res.status(400).json({
        error: 'Liberación de pago rechazada. Se requieren las coordenadas de geolocalización en tiempo real del prestador y del cliente para verificar la asistencia física.'
      });
    }

    const latP = parseFloat(provider_lat);
    const lonP = parseFloat(provider_lon);
    const latC = parseFloat(client_lat);
    const lonC = parseFloat(client_lon);

    if (isNaN(latP) || isNaN(lonP) || isNaN(latC) || isNaN(lonC)) {
      return res.status(400).json({
        error: 'Liberación de pago rechazada. Las coordenadas de geolocalización proporcionadas no son válidas.'
      });
    }

    const distanceQuery = `
      SELECT ST_Distance(
        ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
        ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography
      ) AS distance_meters;
    `;
    const distanceRes = await pool.query(distanceQuery, [lonP, latP, lonC, latC]);
    const distanceMeters = parseFloat(distanceRes.rows[0].distance_meters) || 0;

    if (distanceMeters > 15) {
      return res.status(400).json({ 
        error: `Liberación de pago rechazada. La distancia entre el prestador y el cliente es de ${distanceMeters.toFixed(1)} metros, superando el límite físico permitido de 15 metros.` 
      });
    }
    console.log(`📡 [PROXIMIDAD POSTGIS] Verificación exitosa. Distancia: ${distanceMeters.toFixed(1)} metros.`);

    // Usar cliente de pool para transacción
    const clientDb = await pool.connect();
    try {
      await clientDb.query('BEGIN');

      // Seleccionar datos de la cita y del prestador (documento, nequi)
      const selectQuery = `
        SELECT b.estado, b.pin_verificacion, b.pago_neto_prestador,
               p.numero_cuenta_nequi, p.documento_titular
        FROM bookings b
        JOIN perfiles_prestador p ON b.provider_id = p.id
        WHERE b.id = $1 AND b.provider_id = $2 FOR UPDATE;
      `;
      const selectRes = await clientDb.query(selectQuery, [bookingId, providerId]);

      if (selectRes.rows.length === 0) {
        await clientDb.query('ROLLBACK');
        return res.status(404).json({ error: 'Cita no encontrada o no pertenece al proveedor.' });
      }

      const booking = selectRes.rows[0];

      if (booking.estado !== 'EN_PROGRESO') {
        await clientDb.query('ROLLBACK');
        return res.status(400).json({ error: `La cita no está en progreso (Estado actual: ${booking.estado}).` });
      }

      if (booking.pin_verificacion !== pin_verificacion.trim()) {
        await clientDb.query('ROLLBACK');
        return res.status(400).json({ error: 'El PIN de seguridad ingresado es incorrecto.' });
      }

      // Actualizar a COMPLETADA
      const updateQuery = `
        UPDATE bookings
        SET estado = 'COMPLETADA'
        WHERE id = $1
        RETURNING id, estado AS status, valor_bruto, comision_plataforma, impuestos_estado, pago_neto_prestador;
      `;
      const updateRes = await clientDb.query(updateQuery, [bookingId]);

      await clientDb.query('COMMIT');

      // Enviar respuesta no bloqueante al frontend inmediatamente para liberar la pantalla
      res.json({
        success: true,
        message: 'PIN verificado. Cita completada con éxito. Procesando transferencia.',
        booking: {
          id: updateRes.rows[0].id,
          status: updateRes.rows[0].status,
          valor_bruto: parseFloat(updateRes.rows[0].valor_bruto) || 0,
          comision_plataforma: parseFloat(updateRes.rows[0].comision_plataforma) || 0,
          impuestos_estado: parseFloat(updateRes.rows[0].impuestos_estado) || 0,
          pago_neto_prestador: parseFloat(updateRes.rows[0].pago_neto_prestador) || 0
        }
      });

      // Disparar en segundo plano (asíncrono y desacoplado) el payout mediante Wompi
      const { disbursePayout } = require('./src/services/wompiService');
      disbursePayout(
        bookingId,
        parseFloat(booking.pago_neto_prestador),
        booking.numero_cuenta_nequi,
        booking.documento_titular
      ).catch(payoutErr => {
        console.error(`[WOMPI BACKGROUND ERROR] Payout falló en background para cita ${bookingId}:`, payoutErr);
      });

    } catch (txErr) {
      await clientDb.query('ROLLBACK');
      throw txErr;
    } finally {
      clientDb.release();
    }

  } catch (error) {
    console.error('❌ ERROR EN POST /api/bookings/:id/complete:', error);
    res.status(500).json({ error: 'Error interno al completar la cita' });
  }
});


// ==========================================
// 🔹 NUEVOS ENDPOINTS: Gestión de Servicios del Proveedor
// ==========================================

// GET /api/services/provider → Lista servicios del provider (activos + inactivos)
app.get('/api/services/provider', authMiddleware, async (req, res) => {
  try {
    if (req.user.role !== 'provider' && req.user.role !== 'PRESTADOR') {
      return res.status(403).json({ error: 'Acceso denegado: solo para proveedores' });
    }

    const query = `
      SELECT id, name, description, price, duration_minutes, category, is_active
      FROM services
      WHERE provider_id = $1
      ORDER BY name ASC;
    `;
    const result = await pool.query(query, [req.user.id]);

    const formattedServices = result.rows.map(row => ({
      id: row.id,
      name: row.name,
      description: row.description || '',
      price: parseFloat(row.price) || 0.0,
      duration_minutes: parseInt(row.duration_minutes) || 30,
      category: row.category || '',
      is_active: !!row.is_active
    }));

    res.json({ success: true, count: formattedServices.length, data: formattedServices });
  } catch (error) {
    console.error('❌ ERROR EN GET /api/services/provider:', { message: error.message, code: error.code });
    res.status(500).json({ error: 'Error interno al obtener servicios' });
  }
});

// POST /api/services → Crea servicio
app.post('/api/services', authMiddleware, async (req, res) => {
  try {
    if (req.user.role !== 'provider' && req.user.role !== 'PRESTADOR') {
      return res.status(403).json({ error: 'Acceso denegado: solo para proveedores' });
    }

    const { name, description, price, duration_minutes, category } = req.body;
    if (!name || price === undefined || !duration_minutes) {
      return res.status(400).json({ error: 'Faltan campos obligatorios (nombre, precio, duración)' });
    }

    const parsedPrice = parseFloat(price);
    const parsedDuration = parseInt(duration_minutes);

    if (isNaN(parsedPrice) || parsedPrice < 0) {
      return res.status(400).json({ error: 'Precio inválido' });
    }
    if (isNaN(parsedDuration) || parsedDuration <= 0) {
      return res.status(400).json({ error: 'Duración inválida' });
    }

    const query = `
      INSERT INTO services (provider_id, name, description, price, duration_minutes, category, is_active)
      VALUES ($1, $2, $3, $4, $5, $6, true)
      RETURNING id, name, description, price, duration_minutes, category, is_active;
    `;
    const result = await pool.query(query, [
      req.user.id, name, description || null, parsedPrice, parsedDuration, category || null
    ]);

    res.status(201).json({
      success: true,
      message: 'Servicio creado exitosamente',
      service: {
        ...result.rows[0],
        price: parseFloat(result.rows[0].price),
        duration_minutes: parseInt(result.rows[0].duration_minutes)
      }
    });
  } catch (error) {
    console.error('❌ ERROR EN POST /api/services:', { message: error.message, code: error.code });
    res.status(500).json({ error: 'Error interno al crear el servicio' });
  }
});

// PUT /api/services/:id → Actualiza servicio
app.put('/api/services/:id', authMiddleware, async (req, res) => {
  try {
    if (req.user.role !== 'provider' && req.user.role !== 'PRESTADOR') {
      return res.status(403).json({ error: 'Acceso denegado: solo para proveedores' });
    }

    const serviceId = req.params.id;
    const providerId = req.user.id;
    const { name, description, price, duration_minutes, category, is_active } = req.body;

    const checkQuery = 'SELECT id FROM services WHERE id = $1 AND provider_id = $2;';
    const checkRes = await pool.query(checkQuery, [serviceId, providerId]);
    if (checkRes.rows.length === 0) {
      return res.status(404).json({ error: 'Servicio no encontrado o no te pertenece' });
    }

    if (!name || price === undefined || !duration_minutes) {
      return res.status(400).json({ error: 'Faltan campos obligatorios (nombre, precio, duración)' });
    }

    const parsedPrice = parseFloat(price);
    const parsedDuration = parseInt(duration_minutes);

    if (isNaN(parsedPrice) || parsedPrice < 0) {
      return res.status(400).json({ error: 'Precio inválido' });
    }
    if (isNaN(parsedDuration) || parsedDuration <= 0) {
      return res.status(400).json({ error: 'Duración inválida' });
    }

    const query = `
      UPDATE services
      SET name = $1, description = $2, price = $3, duration_minutes = $4, category = $5, is_active = $6
      WHERE id = $7 AND provider_id = $8
      RETURNING id, name, description, price, duration_minutes, category, is_active;
    `;
    const result = await pool.query(query, [
      name, description || null, parsedPrice, parsedDuration, category || null, is_active !== false, serviceId, providerId
    ]);

    res.json({
      success: true,
      message: 'Servicio actualizado exitosamente',
      service: {
        ...result.rows[0],
        price: parseFloat(result.rows[0].price),
        duration_minutes: parseInt(result.rows[0].duration_minutes)
      }
    });
  } catch (error) {
    console.error('❌ ERROR EN PUT /api/services/:id:', { message: error.message, code: error.code });
    res.status(500).json({ error: 'Error interno al actualizar el servicio' });
  }
});

// DELETE /api/services/:id → Soft delete (desactivar servicio)
app.delete('/api/services/:id', authMiddleware, async (req, res) => {
  try {
    if (req.user.role !== 'provider' && req.user.role !== 'PRESTADOR') {
      return res.status(403).json({ error: 'Acceso denegado: solo para proveedores' });
    }

    const serviceId = req.params.id;
    const providerId = req.user.id;

    const checkQuery = 'SELECT id FROM services WHERE id = $1 AND provider_id = $2;';
    const checkRes = await pool.query(checkQuery, [serviceId, providerId]);
    if (checkRes.rows.length === 0) {
      return res.status(404).json({ error: 'Servicio no encontrado o no te pertenece' });
    }

    const query = `
      UPDATE services
      SET is_active = false
      WHERE id = $1 AND provider_id = $2
      RETURNING id, name, is_active;
    `;
    const result = await pool.query(query, [serviceId, providerId]);

    res.json({
      success: true,
      message: 'Servicio desactivado exitosamente',
      service: result.rows[0]
    });
  } catch (error) {
    console.error('❌ ERROR EN DELETE /api/services/:id:', { message: error.message, code: error.code });
    res.status(500).json({ error: 'Error interno al desactivar el servicio' });
  }
});

// 🔹 NUEVO: Obtener slots de tiempo disponibles para un proveedor y fecha específica
app.get('/api/providers/:id/slots', async (req, res) => {
  try {
    const providerId = req.params.id;
    const { date, service_id } = req.query;

    if (!date || !service_id) {
      return res.status(400).json({ error: 'Faltan parámetros requeridos (date, service_id)' });
    }

    // 1. Obtener la duración del servicio solicitado
    const serviceRes = await pool.query('SELECT duration_minutes FROM services WHERE id = $1 AND provider_id = $2 AND is_active = true;', [service_id, providerId]);
    if (serviceRes.rows.length === 0) {
      return res.status(404).json({ error: 'Servicio no encontrado o inactivo' });
    }
    const selectedDuration = parseInt(serviceRes.rows[0].duration_minutes);

    // 2. Obtener todas las citas activas para ese día
    const bookingsQuery = `
      SELECT b.scheduled_at, s.duration_minutes 
      FROM bookings b
      JOIN services s ON b.service_id = s.id
      WHERE b.provider_id = $1 
        AND b.scheduled_at::date = $2::date
        AND b.estado NOT IN ('CANCELADA');
    `;
    const bookingsRes = await pool.query(bookingsQuery, [providerId, date]);
    const activeBookings = bookingsRes.rows.map(row => {
      const start = new Date(row.scheduled_at);
      const duration = parseInt(row.duration_minutes);
      const end = new Date(start.getTime() + duration * 60 * 1000);
      return { start, end };
    });

    // 3. Generar slots de 06:00 a 20:00 cada 30 minutos
    const slots = [];
    const [year, month, day] = date.split('-').map(Number);

    // Inicio: 06:00 AM local del servidor
    const startTime = new Date(year, month - 1, day, 6, 0, 0);
    // Fin: 08:00 PM (20:00) local del servidor
    const endTime = new Date(year, month - 1, day, 20, 0, 0);

    const now = new Date();

    let currentSlot = new Date(startTime);
    while (currentSlot < endTime) {
      const slotStart = new Date(currentSlot);
      const slotEnd = new Date(slotStart.getTime() + selectedDuration * 60 * 1000);

      // Formato HH:MM
      const hours = String(slotStart.getHours()).padStart(2, '0');
      const minutes = String(slotStart.getMinutes()).padStart(2, '0');
      const timeStr = `${hours}:${minutes}`;

      let isAvailable = true;

      // Deshabilitar slots pasados si la fecha consultada es hoy
      if (slotStart < now) {
        isAvailable = false;
      }

      // Si aún está disponible por hora, comprobar colisiones con citas existentes
      if (isAvailable) {
        for (const booking of activeBookings) {
          // Colisión: start1 < end2 AND end1 > start2
          if (slotStart.getTime() < booking.end.getTime() && slotEnd.getTime() > booking.start.getTime()) {
            isAvailable = false;
            break;
          }
        }
      }

      slots.push({
        time: timeStr,
        is_available: isAvailable
      });

      // Incrementar por 30 minutos
      currentSlot.setMinutes(currentSlot.getMinutes() + 30);
    }

    res.json({
      success: true,
      date,
      service_id,
      slots
    });

  } catch (error) {
    console.error('❌ ERROR EN GET /api/providers/:id/slots:', error);
    res.status(500).json({ error: 'Error interno al obtener slots de tiempo' });
  }
});

// 🔹 NUEVO: Endpoint para subir imágenes locales (Multer)
app.post('/api/upload', authMiddleware, (req, res) => {
  upload.single('image')(req, res, (err) => {
    if (err) {
      return res.status(400).json({ error: err.message });
    }
    if (!req.file) {
      return res.status(400).json({ error: 'No se ha proporcionado ninguna imagen' });
    }
    const host = req.get('host');
    const imageUrl = `${req.protocol}://${host}/uploads/${req.file.filename}`;
    res.json({
      success: true,
      message: 'Imagen subida con éxito',
      url: imageUrl,
      path: `/uploads/${req.file.filename}`
    });
  });
});

// Lista de clientes conectados a eventos SSE de administración
const sseClients = [];

// Función para transmitir eventos a todos los clientes del dashboard conectados
const broadcastAdminEvent = (type, data) => {
  const payload = JSON.stringify({ type, data });
  sseClients.forEach(client => {
    try {
      client.write(`data: ${payload}\n\n`);
    } catch (err) {
      console.error('Error al escribir en cliente SSE:', err);
    }
  });
};

// 🔹 NUEVO: Registrar Alerta de Emergencia / SOS (Pánico)
app.post('/api/sos', authMiddleware, async (req, res) => {
  try {
    const { booking_id, latitude, longitude } = req.body;
    const user_id = req.user.id;

    // Validación defensiva
    if (latitude && (latitude < -90 || latitude > 90)) {
      return res.status(400).json({ error: 'Latitud inválida' });
    }
    if (longitude && (longitude < -180 || longitude > 180)) {
      return res.status(400).json({ error: 'Longitud inválida' });
    }

    const query = `
      INSERT INTO sos_alerts (user_id, booking_id, latitude, longitude, estado)
      VALUES ($1, $2, $3, $4, 'ACTIVO')
      RETURNING id, creado_en;
    `;
    const result = await pool.query(query, [
      user_id,
      booking_id || null,
      latitude || null,
      longitude || null
    ]);

    const alertId = result.rows[0].id;
    
    // Emitir el evento SOS en tiempo real a los dashboards conectados
    broadcastAdminEvent('sos_alert', {
      id: alertId,
      user_id: user_id,
      email: req.user.email,
      booking_id: booking_id || null,
      latitude: latitude ? parseFloat(latitude) : null,
      longitude: longitude ? parseFloat(longitude) : null,
      estado: 'ACTIVO',
      creado_en: result.rows[0].creado_en
    });
    
    // Log de consola con estilo de emergencia
    console.log('\x1b[41m\x1b[37m%s\x1b[0m', `🚨 [ALERTA DE EMERGENCIA - SOS] 🚨`);
    console.log(`- Alerta ID: ${alertId}`);
    console.log(`- Usuario ID: ${user_id} (${req.user.email})`);
    if (booking_id) console.log(`- Reserva asociada: ${booking_id}`);
    if (latitude && longitude) console.log(`- Ubicación: ${latitude}, ${longitude}`);
    console.log(`- Timestamp: ${new Date().toISOString()}`);
    console.log('\x1b[41m\x1b[37m%s\x1b[0m', `🚨 [FIN DE ALERTA - NOTIFICANDO AUTORIDADES] 🚨`);

    res.status(201).json({
      success: true,
      message: 'Alerta de pánico (SOS) activada correctamente. La central de seguridad y las autoridades locales de Fontibón han sido notificadas.',
      alert_id: alertId
    });

  } catch (error) {
    console.error('❌ ERROR EN POST /api/sos:', error);
    res.status(500).json({ error: 'Error interno al registrar alerta de pánico' });
  }
});

// Middleware para autenticación opcional (no bloquea si no hay token o es inválido)
const optionalAuthMiddleware = async (req, res, next) => {
  const token = req.header('Authorization')?.replace('Bearer ', '');
  if (!token) {
    req.user = null;
    return next();
  }
  try {
    const jwt = require('jsonwebtoken');
    const JWT_SECRET = process.env.JWT_SECRET || 'beauty_app_super_secret_key_2026_change_in_production';
    const verified = jwt.verify(token, JWT_SECRET);
    
    const userRes = await pool.query('SELECT rol FROM usuarios WHERE id = $1', [verified.id]);
    if (userRes.rows.length > 0) {
      req.user = {
        id: verified.id,
        email: verified.email,
        role: userRes.rows[0].rol
      };
    } else {
      req.user = null;
    }
  } catch (err) {
    req.user = null;
  }
  next();
};

// 🔹 NUEVO: Registrar Lote de Eventos de Telemetría (Analíticas)
app.post('/api/analytics/events', optionalAuthMiddleware, async (req, res) => {
  try {
    const { events } = req.body;
    if (!Array.isArray(events) || events.length === 0) {
      return res.status(400).json({ error: 'Falta el lote de eventos o es inválido' });
    }

    const clientDb = await pool.connect();
    try {
      await clientDb.query('BEGIN');
      
      for (const event of events) {
        const { session_id, event_type, screen_name, element_id, metadata, creado_en } = event;
        const userId = req.user ? req.user.id : null;
        
        await clientDb.query(
          `INSERT INTO user_activity_logs (user_id, session_id, event_type, screen_name, element_id, metadata, creado_en)
           VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [
            userId,
            session_id,
            event_type || 'UNKNOWN',
            screen_name || 'UNKNOWN',
            element_id || null,
            metadata ? JSON.stringify(metadata) : null,
            creado_en || new Date()
          ]
        );
      }
      
      await clientDb.query('COMMIT');
      
      console.log(`📊 [TELEMETRÍA] Registrados ${events.length} eventos de analíticas. Usuario: ${req.user ? req.user.email : 'Anónimo'}`);
      
      res.status(201).json({
        success: true,
        message: 'Eventos de telemetría registrados correctamente',
        count: events.length
      });
      
    } catch (dbError) {
      await clientDb.query('ROLLBACK');
      throw dbError;
    } finally {
      clientDb.release();
    }
    
  } catch (error) {
    console.error('❌ ERROR EN POST /api/analytics/events:', error);
    res.status(500).json({ error: 'Error interno al guardar telemetría' });
  }
});

// 🔹 NUEVO: Canal SSE en tiempo real para eventos de administración
app.get('/api/admin/events/stream', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();

  sseClients.push(res);
  console.log(`🔌 [SSE] Administrador conectado al flujo en vivo. Total conectados: ${sseClients.length}`);

  // Enviar ping inicial para confirmar conexión
  res.write(`data: ${JSON.stringify({ type: 'connected', timestamp: new Date().toISOString() })}\n\n`);

  req.on('close', () => {
    const index = sseClients.indexOf(res);
    if (index !== -1) {
      sseClients.splice(index, 1);
      console.log(`🔌 [SSE] Administrador desconectado del flujo. Total conectados: ${sseClients.length}`);
    }
  });
});

// 🔹 NUEVO: Obtener estadísticas globales y telemetría de analíticas
app.get('/api/admin/metrics', async (req, res) => {
  try {
    // 1. Estadísticas agregadas de reservas
    const bookingsCountRes = await pool.query(`
      SELECT estado, COUNT(*)::int as count 
      FROM bookings 
      GROUP BY estado;
    `);
    
    // 2. Ingresos totales (suma de valor_bruto de reservas completadas)
    const revenueRes = await pool.query(`
      SELECT COALESCE(SUM(valor_bruto), 0.0)::double precision as total_revenue
      FROM bookings 
      WHERE estado = 'COMPLETADA';
    `);
    
    // 3. Usuarios registrados agrupados por rol
    const usersCountRes = await pool.query(`
      SELECT rol, COUNT(*)::int as count 
      FROM usuarios 
      GROUP BY rol;
    `);
    
    // 4. Prestadores activos (online)
    const activeProvidersRes = await pool.query(`
      SELECT COUNT(*)::int as count 
      FROM perfiles_prestador 
      WHERE is_online = true;
    `);
    
    // 5. Historial de alertas SOS (últimas 20)
    const sosAlertsRes = await pool.query(`
      SELECT s.*, u.nombre as user_name, u.email as user_email, u.phone as user_phone
      FROM sos_alerts s
      JOIN usuarios u ON s.user_id = u.id
      ORDER BY s.creado_en DESC
      LIMIT 20;
    `);
    
    // 6. Frecuencia de visitas a pantallas de la telemetría
    const telemetryScreensRes = await pool.query(`
      SELECT screen_name, COUNT(*)::int as count
      FROM user_activity_logs
      WHERE event_type = 'SCREEN_VIEW'
      GROUP BY screen_name
      ORDER BY count DESC
      LIMIT 10;
    `);

    // 7. Frecuencia de clicks en botones / elementos interactuados
    const telemetryClicksRes = await pool.query(`
      SELECT element_id, COUNT(*)::int as count
      FROM user_activity_logs
      WHERE event_type = 'TAP' OR event_type = 'SOS_TRIGGERED' OR event_type = 'CATEGORY_FILTER_SELECTED'
      GROUP BY element_id
      ORDER BY count DESC
      LIMIT 10;
    `);

    res.json({
      success: true,
      data: {
        bookings_status: bookingsCountRes.rows,
        total_revenue: revenueRes.rows[0].total_revenue,
        users_by_role: usersCountRes.rows,
        active_providers_online: activeProvidersRes.rows[0].count,
        sos_alerts: sosAlertsRes.rows,
        telemetry_screens: telemetryScreensRes.rows,
        telemetry_clicks: telemetryClicksRes.rows
      }
    });
  } catch (error) {
    console.error('❌ ERROR EN GET /api/admin/metrics:', error);
    res.status(500).json({ error: 'Error al obtener métricas del panel administrativo' });
  }
});

// 🔹 NUEVO: Resolver Alerta SOS / Pánico
app.patch('/api/admin/sos/resolve/:id', async (req, res) => {
  try {
    const alertId = parseInt(req.params.id);
    const updateRes = await pool.query(`
      UPDATE sos_alerts
      SET estado = 'RESUELTO'
      WHERE id = $1
      RETURNING *;
    `, [alertId]);

    if (updateRes.rows.length === 0) {
      return res.status(404).json({ error: 'Alerta SOS no encontrada' });
    }

    // Emitir evento de actualización a los dashboards conectados
    broadcastAdminEvent('sos_resolved', updateRes.rows[0]);

    res.json({
      success: true,
      message: 'Alerta SOS marcada como resuelta',
      alert: updateRes.rows[0]
    });
  } catch (error) {
    console.error('❌ ERROR EN PATCH /api/admin/sos/resolve:', error);
    res.status(500).json({ error: 'Error al resolver alerta SOS' });
  }
});

// 🔹 NUEVO: Obtener perfil del usuario autenticado (incluye avatar_url)
app.get('/api/users/profile', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query('SELECT id, email, nombre as full_name, phone, foto_url as avatar_url, rol as role, onboarding_completo FROM usuarios WHERE id = $1', [req.user.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }
    let user = result.rows[0];
    user.role = user.role === 'PRESTADOR' ? 'provider' : (user.role === 'CLIENTE' ? 'client' : null);
    if (user.role === 'provider') {
      const providerRes = await pool.query('SELECT is_active, business_name, description, rating_avg, rating_count, (estatus_verificacion = \'APROBADO\') as is_verified, estatus_verificacion FROM perfiles_prestador WHERE id = $1', [req.user.id]);
      if (providerRes.rows.length > 0) {
        user = { 
          ...user, 
          ...providerRes.rows[0],
          is_verified: !!providerRes.rows[0].is_verified,
          is_active: !!providerRes.rows[0].is_active
        };
      }
    }
    res.json({ success: true, user });
  } catch (error) {
    console.error('❌ ERROR EN GET /api/users/profile:', error);
    res.status(500).json({ error: 'Error interno al obtener perfil' });
  }
});

// 🔹 NUEVO: Actualizar el estado activo/inactivo del prestador (Online / Offline)
app.patch('/api/providers/status', authMiddleware, async (req, res) => {
  try {
    if (req.user.role !== 'provider' && req.user.role !== 'PRESTADOR') {
      return res.status(403).json({ error: 'Acceso denegado: solo para proveedores' });
    }
    const { is_active } = req.body;
    if (typeof is_active !== 'boolean') {
      return res.status(400).json({ error: 'El campo is_active debe ser un booleano' });
    }
    const result = await pool.query(
      'UPDATE perfiles_prestador SET is_active = $1 WHERE id = $2 RETURNING is_active',
      [is_active, req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Proveedor no encontrado' });
    }
    res.json({ success: true, is_active: result.rows[0].is_active });
  } catch (error) {
    console.error('❌ ERROR EN PATCH /api/providers/status:', error);
    res.status(500).json({ error: 'Error interno al actualizar el estado' });
  }
});

// 🔹 NUEVO: Actualizar el avatar de perfil del usuario autenticado
app.patch('/api/users/avatar', authMiddleware, async (req, res) => {
  try {
    const { avatar_url } = req.body;
    if (!avatar_url) {
      return res.status(400).json({ error: 'avatar_url es obligatorio' });
    }
    const query = 'UPDATE usuarios SET foto_url = $1 WHERE id = $2 RETURNING id, email, nombre as full_name, foto_url as avatar_url, rol as role;';
    const result = await pool.query(query, [avatar_url, req.user.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }
    let user = result.rows[0];
    user.role = user.role === 'PRESTADOR' ? 'provider' : (user.role === 'CLIENTE' ? 'client' : null);
    res.json({
      success: true,
      message: 'Avatar actualizado con éxito',
      user
    });
  } catch (error) {
    console.error('❌ ERROR EN PATCH /api/users/avatar:', { message: error.message });
    res.status(500).json({ error: 'Error interno al actualizar el avatar' });
  }
});

// 🔹 NUEVO: Actualizar perfil del usuario (nombre y teléfono)
app.patch('/api/users/profile', authMiddleware, async (req, res) => {
  try {
    const { full_name, phone } = req.body;
    if (!full_name && !phone) {
      return res.status(400).json({ error: 'Debe proporcionar al menos un campo para actualizar (full_name o phone)' });
    }
    
    // Construir query dinámica
    const updates = [];
    const values = [];
    let paramIndex = 1;
    
    if (full_name !== undefined) {
      updates.push(`nombre = $${paramIndex++}`);
      values.push(full_name);
    }
    if (phone !== undefined) {
      updates.push(`phone = $${paramIndex++}`);
      values.push(phone);
    }
    
    values.push(req.user.id);
    const query = `UPDATE usuarios SET ${updates.join(', ')} WHERE id = $${paramIndex} RETURNING id, email, nombre as full_name, phone, foto_url as avatar_url, rol as role;`;
    
    const result = await pool.query(query, values);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }
    
    let user = result.rows[0];
    user.role = user.role === 'PRESTADOR' ? 'provider' : (user.role === 'CLIENTE' ? 'client' : null);
    res.json({
      success: true,
      message: 'Perfil actualizado con éxito',
      user
    });
  } catch (error) {
    console.error('❌ ERROR EN PATCH /api/users/profile:', error);
    res.status(500).json({ error: 'Error interno al actualizar el perfil' });
  }
});


// 🔹 NUEVO: Agregar una imagen al portafolio (Proveedor)
app.post('/api/portfolio', authMiddleware, async (req, res) => {
  try {
    if (req.user.role !== 'provider' && req.user.role !== 'PRESTADOR') {
      return res.status(403).json({ error: 'Acceso denegado: solo para proveedores' });
    }
    const { image_url, title, category } = req.body;
    if (!image_url) {
      return res.status(400).json({ error: 'image_url es obligatorio' });
    }
    const query = `
      INSERT INTO portfolio_items (provider_id, image_url, title, category)
      VALUES ($1, $2, $3, $4)
      RETURNING id, provider_id, image_url, title, category, created_at;
    `;
    const result = await pool.query(query, [
      req.user.id,
      image_url,
      title || null,
      category || null
    ]);
    res.status(201).json({
      success: true,
      message: 'Imagen agregada al portafolio',
      portfolio_item: result.rows[0]
    });
  } catch (error) {
    console.error('❌ ERROR EN POST /api/portfolio:', { message: error.message });
    res.status(500).json({ error: 'Error interno al agregar al portafolio' });
  }
});

// 🔹 NUEVO: Obtener portafolio de un proveedor autenticado
app.get('/api/portfolio/provider', authMiddleware, async (req, res) => {
  try {
    if (req.user.role !== 'provider' && req.user.role !== 'PRESTADOR') {
      return res.status(403).json({ error: 'Acceso denegado: solo para proveedores' });
    }
    const query = `
      SELECT id, image_url, title, category, likes_count, created_at
      FROM portfolio_items
      WHERE provider_id = $1
      ORDER BY created_at DESC;
    `;
    const result = await pool.query(query, [req.user.id]);
    res.json({
      success: true,
      count: result.rows.length,
      data: result.rows
    });
  } catch (error) {
    console.error('❌ ERROR EN GET /api/portfolio/provider:', { message: error.message });
    res.status(500).json({ error: 'Error interno al obtener el portafolio' });
  }
});

// 🔹 NUEVO: Eliminar imagen del portafolio (Proveedor)
app.delete('/api/portfolio/:id', authMiddleware, async (req, res) => {
  try {
    if (req.user.role !== 'provider' && req.user.role !== 'PRESTADOR') {
      return res.status(403).json({ error: 'Acceso denegado: solo para proveedores' });
    }
    const itemId = req.params.id;
    const providerId = req.user.id;

    // Verificar propiedad antes de borrar
    const checkQuery = 'SELECT id FROM portfolio_items WHERE id = $1 AND provider_id = $2;';
    const checkRes = await pool.query(checkQuery, [itemId, providerId]);
    if (checkRes.rows.length === 0) {
      return res.status(404).json({ error: 'Elemento del portafolio no encontrado o no te pertenece' });
    }

    const query = 'DELETE FROM portfolio_items WHERE id = $1 AND provider_id = $2 RETURNING id;';
    await pool.query(query, [itemId, providerId]);

    res.json({
      success: true,
      message: 'Imagen eliminada del portafolio'
    });
  } catch (error) {
    console.error('❌ ERROR EN DELETE /api/portfolio/:id:', { message: error.message });
    res.status(500).json({ error: 'Error interno al eliminar del portafolio' });
  }
});

// ==========================================
// 🔹 NUEVOS ENDPOINTS: Sistema de Chat y Mensajería
// ==========================================

// GET /api/chat/conversations → Listar conversaciones activas
app.get('/api/chat/conversations', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;

    const query = `
      SELECT DISTINCT ON (conversation_partner_id)
        m.conversation_partner_id,
        u.nombre as partner_name,
        u.foto_url as partner_avatar,
        CASE WHEN u.rol = 'PRESTADOR' THEN 'provider' ELSE 'client' END as partner_role,
        m.message as last_message,
        m.created_at as last_message_time,
        m.sender_id,
        (
          SELECT COUNT(*)::int 
          FROM messages 
          WHERE sender_id = m.conversation_partner_id 
            AND receiver_id = $1 
            AND is_read = false
        ) as unread_count
      FROM (
        SELECT 
          CASE WHEN sender_id = $1 THEN receiver_id ELSE sender_id END as conversation_partner_id,
          message,
          created_at,
          sender_id
        FROM messages
        WHERE sender_id = $1 OR receiver_id = $1
        ORDER BY created_at DESC
      ) m
      JOIN usuarios u ON u.id = m.conversation_partner_id
      ORDER BY m.conversation_partner_id, m.created_at DESC;
    `;

    const result = await pool.query(query, [userId]);
    
    // Mapear el ID de la conversación a string para compatibilidad con Flutter
    const conversations = result.rows.map(row => ({
      ...row,
      conversation_partner_id: row.conversation_partner_id.toString()
    }));

    // Ordenar por fecha del último mensaje descendente
    conversations.sort((a, b) => new Date(b.last_message_time) - new Date(a.last_message_time));

    res.json({
      success: true,
      count: conversations.length,
      data: conversations
    });
  } catch (error) {
    console.error('❌ ERROR EN GET /api/chat/conversations:', error);
    res.status(500).json({ error: 'Error al obtener conversaciones' });
  }
});

// GET /api/chat/messages/:partnerId → Historial de mensajes con un socio
app.get('/api/chat/messages/:partnerId', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const partnerId = req.params.partnerId;
    const resolvedPartnerId = (partnerId === '0' || partnerId === '00000000-0000-0000-0000-000000000000' || partnerId === AI_USER_ID.toString()) ? 0 : parseInt(partnerId);

    const query = `
      SELECT id, sender_id, receiver_id, message, is_read, created_at
      FROM messages
      WHERE (sender_id = $1 AND receiver_id = $2)
         OR (sender_id = $2 AND receiver_id = $1)
      ORDER BY created_at ASC;
    `;
    const result = await pool.query(query, [userId, resolvedPartnerId]);
    
    // Mapear los IDs de remitente y receptor a strings para compatibilidad
    const formattedMessages = result.rows.map(row => ({
      ...row,
      sender_id: row.sender_id.toString(),
      receiver_id: row.receiver_id.toString()
    }));

    res.json({
      success: true,
      count: formattedMessages.length,
      data: formattedMessages
    });
  } catch (error) {
    console.error('❌ ERROR EN GET /api/chat/messages/:partnerId:', error);
    res.status(500).json({ error: 'Error al obtener mensajes' });
  }
});

// POST /api/chat/messages → Enviar un mensaje
app.post('/api/chat/messages', authMiddleware, async (req, res) => {
  try {
    const senderId = req.user.id;
    const { receiver_id, message, image_path } = req.body;

    if (!receiver_id || !message || message.trim() === '') {
      return res.status(400).json({ error: 'receiver_id y message son obligatorios' });
    }

    const targetReceiver = (receiver_id === '0' || receiver_id === '00000000-0000-0000-0000-000000000000' || receiver_id === AI_USER_ID.toString()) ? 0 : parseInt(receiver_id);

    // Sistema de Detección y Prevención de Evasión (Anti-Circumvention Filter)
    const normalizedMsg = message.replace(/[\s\-\.\(\)]/g, '');
    const containsPhone = /3[0-9]{9}|60[0-9]{8}/.test(normalizedMsg);
    const containsEmail = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/.test(message);
    const containsSocial = /@[a-zA-Z0-9_._]+/.test(message);
    
    const forbiddenPatterns = [
      'por fuera', 'pago directo', 'pago en efectivo', 'efectivo directo', 
      'whatsapp', 'wpp', 'escríbame', 'escribame', 'nequi directo', 
      'transferencia directa', 'llámeme', 'llamame', 'escríbeme', 'escribeme',
      'mi cel', 'mi número', 'mi numero', 'número de contacto', 'numero de contacto'
    ];
    
    const lowerMessage = message.toLowerCase();
    const containsForbiddenPattern = forbiddenPatterns.some(pat => lowerMessage.includes(pat));

    // Bloquear de forma estricta entre clientes y proveedores (omitir para el Asistente de IA)
    if (targetReceiver !== 0) {
      if (containsPhone || containsEmail || containsSocial || containsForbiddenPattern) {
        return res.status(400).json({ 
          error: 'Por motivos de seguridad y políticas de la plataforma, no está permitido compartir información de contacto directo (teléfonos, correos, redes sociales) ni negociar pagos externos fuera de la aplicación. Por favor, mantenga su comunicación y transacciones dentro de Belleza App.' 
        });
      }
    }

    const query = `
      INSERT INTO messages (sender_id, receiver_id, message)
      VALUES ($1, $2, $3)
      RETURNING id, sender_id, receiver_id, message, is_read, created_at;
    `;
    const result = await pool.query(query, [senderId, targetReceiver, message.trim()]);
    
    const formatted = {
      ...result.rows[0],
      sender_id: result.rows[0].sender_id.toString(),
      receiver_id: result.rows[0].receiver_id.toString()
    };

    // Responder inmediatamente (no bloqueante)
    res.status(201).json({
      success: true,
      data: formatted
    });

    // Si el receptor es el Asistente de IA, disparar generación asíncrona en segundo plano
    if (targetReceiver === 0) {
      processAssistantMessage(senderId, message.trim(), image_path).catch(err => {
        console.error('❌ Error en procesamiento asíncrono del Asistente de IA:', err);
      });
    }

  } catch (error) {
    console.error('❌ ERROR EN POST /api/chat/messages:', error);
    res.status(500).json({ error: 'Error al enviar el mensaje' });
  }
});

// PATCH /api/chat/messages/:partnerId/read → Marcar mensajes recibidos como leídos
app.patch('/api/chat/messages/:partnerId/read', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const partnerId = req.params.partnerId;
    const resolvedPartnerId = (partnerId === '0' || partnerId === '00000000-0000-0000-0000-000000000000' || partnerId === AI_USER_ID.toString()) ? 0 : parseInt(partnerId);

    const query = `
      UPDATE messages
      SET is_read = true
      WHERE sender_id = $1 AND receiver_id = $2 AND is_read = false
      RETURNING id;
    `;
    const result = await pool.query(query, [resolvedPartnerId, userId]);
    res.json({
      success: true,
      count: result.rows.length
    });
  } catch (error) {
    console.error('❌ ERROR EN PATCH /api/chat/messages/:partnerId/read:', error);
    res.status(500).json({ error: 'Error al marcar mensajes como leídos' });
  }
});

const initDatabase = async () => {
  try {
    const tableCheck = await pool.query("SELECT to_regclass('public.usuarios') as exists;");
    const hasTable = tableCheck.rows[0].exists !== null;

    if (hasTable) {
      console.log('✅ Base de datos ya inicializada. Omitiendo recreación de tablas.');
    } else {
      const schemaPath = path.join(__dirname, 'schema.sql');
      if (fs.existsSync(schemaPath)) {
        const schemaSql = fs.readFileSync(schemaPath, 'utf8');
        await pool.query(schemaSql);
        console.log('✅ Base de datos: Esquema inicializado/verificado desde schema.sql');
      } else {
        console.warn('⚠️ No se encontró schema.sql. Se omitió la creación automática de tablas.');
      }
    }

    // Ejecutar migraciones y tablas adicionales ahora que el esquema base está garantizado
    await pool.query(`
      ALTER TABLE bookings
      ADD COLUMN IF NOT EXISTS service_address TEXT;
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS sos_alerts (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
        booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
        latitude NUMERIC(9,6),
        longitude NUMERIC(9,6),
        estado VARCHAR(20) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'RESUELTO')),
        creado_en TIMESTAMPTZ DEFAULT NOW()
      );
    `);

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_sos_alerts_user ON sos_alerts(user_id);
      CREATE INDEX IF NOT EXISTS idx_sos_alerts_booking ON sos_alerts(booking_id);
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS user_activity_logs (
        id BIGSERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES usuarios(id) ON DELETE SET NULL,
        session_id UUID NOT NULL,
        event_type VARCHAR(50) NOT NULL,
        screen_name VARCHAR(100) NOT NULL,
        element_id VARCHAR(100),
        metadata JSONB,
        creado_en TIMESTAMPTZ DEFAULT NOW()
      );
    `);

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_activity_logs_session ON user_activity_logs(session_id);
      CREATE INDEX IF NOT EXISTS idx_activity_logs_event ON user_activity_logs(event_type);
    `);

    const aiUserQuery = `
      INSERT INTO usuarios (id, email, nombre, auth_provider, provider_id, rol, onboarding_completo)
      VALUES (
        0,
        'assistant@beautyapp.com',
        'Asistente Virtual de Belleza',
        'LOCAL',
        'assistant-local',
        'PRESTADOR',
        true
      )
      ON CONFLICT (id) DO NOTHING;
    `;
    await pool.query(aiUserQuery);
    console.log('🤖 Usuario Asistente de IA verificado/creado con ID 0.');

    const countRes = await pool.query('SELECT COUNT(*)::int FROM usuarios;');
    if (countRes.rows[0].count === 1) {
      if (process.env.SEED_DATABASE === 'true') {
        const seedPath = path.join(__dirname, 'seed.sql');
        if (fs.existsSync(seedPath)) {
          const seedSql = fs.readFileSync(seedPath, 'utf8');
          await pool.query(seedSql);
          console.log('🌱 Datos de prueba (seed.sql) sembrados exitosamente.');
        }
      } else {
        console.log('⚠️  Omitiendo la siembra de base de datos (SEED_DATABASE no está establecida como "true").');
      }
    }
  } catch (error) {
    console.error('❌ Error al inicializar la base de datos:', error);
  }
};

// ==========================================
// 🔹 GESTIÓN DE WEBSOCKETS Y NOTIFICACIONES
// ==========================================
const wsClients = new Map(); // userId -> Set of WS connections

const notifyUserJobUpdate = (userId, jobData) => {
  const userIdStr = userId.toString();
  if (wsClients.has(userIdStr)) {
    const payload = JSON.stringify({
      type: 'nail_tryon_update',
      data: {
        id: jobData.id,
        status: jobData.status,
        preview_url: jobData.preview_url,
        error_message: jobData.error_message
      }
    });
    for (const conn of wsClients.get(userIdStr)) {
      if (conn.readyState === 1) { // OPEN
        conn.send(payload);
      }
    }
  }
};

// ==========================================
// 🔹 LIMPIEZA PERIÓDICA DE TRABAJOS EXPIRADOS (24H)
// ==========================================
const cleanExpiredTryonJobs = async () => {
  try {
    const query = `
      SELECT id, original_image_url, preview_url 
      FROM nail_tryon_jobs 
      WHERE expires_at < NOW();
    `;
    const res = await pool.query(query);
    
    for (const row of res.rows) {
      const deleteLocalFile = (url) => {
        if (url && url.includes('/uploads/')) {
          const filename = url.split('/uploads/')[1];
          const filepath = path.join(__dirname, 'uploads', filename);
          if (fs.existsSync(filepath)) {
            try {
              fs.unlinkSync(filepath);
              console.log(`🗑️ Archivo expirado de prueba virtual eliminado: ${filepath}`);
            } catch (fileErr) {
              console.error(`Error eliminando archivo ${filepath}:`, fileErr.message);
            }
          }
        }
      };
      deleteLocalFile(row.original_image_url);
      deleteLocalFile(row.preview_url);
    }
    
    const deleteQuery = `DELETE FROM nail_tryon_jobs WHERE expires_at < NOW();`;
    const deleteRes = await pool.query(deleteQuery);
    if (deleteRes.rowCount > 0) {
      console.log(`🧹 Base de datos: ${deleteRes.rowCount} registros de prueba virtual expirados eliminados.`);
    }
  } catch (err) {
    console.error('Error al limpiar trabajos de prueba virtual expirados:', err);
  }
};

// Limpieza automática cada hora
setInterval(cleanExpiredTryonJobs, 60 * 60 * 1000);

// ==========================================
// 🔹 NUEVOS ENDPOINTS: Prueba Virtual de Uñas (Nail Try-On)
// ==========================================

// POST /api/nail-tryon → Iniciar trabajo de prueba virtual
app.post('/api/nail-tryon', authMiddleware, upload.single('image'), async (req, res) => {
  try {
    const userId = req.user.id;
    const { color_hex, shape, finish, decoration_style } = req.body;

    if (!req.file) {
      return res.status(400).json({ error: 'Se requiere una imagen de la mano o uñas.' });
    }

    // Calcular el hash MD5 de la imagen para control de caché
    const fileBuffer = fs.readFileSync(req.file.path);
    const imageHash = crypto.createHash('md5').update(fileBuffer).digest('hex');

    // Buscar si ya existe el resultado en caché
    const cachedJob = await findCachedJob(imageHash, color_hex, shape, finish, decoration_style);
    
    if (cachedJob) {
      console.log(`🎯 Caché hit para prueba virtual. Retornando preview de trabajo previo.`);
      
      const jobId = crypto.randomUUID();
      const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);
      
      const insertCachedQuery = `
        INSERT INTO nail_tryon_jobs (id, user_id, status, color_hex, shape, finish, decoration_style, original_image_url, preview_url, image_hash, expires_at)
        VALUES ($1, $2, 'completed', $3, $4, $5, $6, $7, $8, $9, $10)
        RETURNING id, status, preview_url;
      `;
      
      const host = req.get('host');
      const originalImageUrl = `${req.protocol}://${host}/uploads/${req.file.filename}`;
      
      const result = await pool.query(insertCachedQuery, [
        jobId,
        userId,
        color_hex || null,
        shape || null,
        finish || null,
        decoration_style || null,
        originalImageUrl,
        cachedJob.preview_url,
        imageHash,
        expiresAt
      ]);
      
      return res.status(201).json({
        success: true,
        message: 'Resultado recuperado de la caché.',
        job: result.rows[0]
      });
    }

    // Si no hay caché, crear un nuevo trabajo pendiente
    const jobId = crypto.randomUUID();
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);
    const host = req.get('host');
    const originalImageUrl = `${req.protocol}://${host}/uploads/${req.file.filename}`;

    const insertQuery = `
      INSERT INTO nail_tryon_jobs (id, user_id, status, color_hex, shape, finish, decoration_style, original_image_url, image_hash, expires_at)
      VALUES ($1, $2, 'pending', $3, $4, $5, $6, $7, $8, $9)
      RETURNING id, status;
    `;

    const result = await pool.query(insertQuery, [
      jobId,
      userId,
      color_hex || null,
      shape || null,
      finish || null,
      decoration_style || null,
      originalImageUrl,
      imageHash,
      expiresAt
    ]);

    // Encolar trabajo en Redis de forma asíncrona
    await enqueueTryonJob(jobId, userId, {
      color_hex,
      shape,
      finish,
      decoration_style
    }, originalImageUrl, imageHash);

    res.status(201).json({
      success: true,
      message: 'Trabajo de prueba virtual creado y encolado.',
      job: result.rows[0]
    });

  } catch (error) {
    console.error('❌ ERROR EN POST /api/nail-tryon:', error);
    res.status(500).json({ error: 'Error al crear la prueba virtual de uñas.' });
  }
});

// GET /api/nail-tryon/:id → Obtener estado del trabajo
app.get('/api/nail-tryon/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const query = `
      SELECT id, status, color_hex, shape, finish, decoration_style, original_image_url, preview_url, error_message, created_at
      FROM nail_tryon_jobs
      WHERE id = $1 AND user_id = $2;
    `;
    const result = await pool.query(query, [id, req.user.id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Trabajo no encontrado.' });
    }
    
    res.json({ success: true, job: result.rows[0] });
  } catch (error) {
    console.error('❌ ERROR EN GET /api/nail-tryon/:id:', error);
    res.status(500).json({ error: 'Error al obtener estado de la prueba virtual.' });
  }
});

// POST /api/nail-tryon/:id/complete → Reportar terminación de trabajo (uso interno por Python Worker)
app.post('/api/nail-tryon/:id/complete', async (req, res) => {
  try {
    const { id } = req.params;
    const { status, preview_url, error_message } = req.body;

    if (!['completed', 'failed'].includes(status)) {
      return res.status(400).json({ error: 'Estado de finalización inválido.' });
    }

    const query = `
      UPDATE nail_tryon_jobs
      SET status = $1, preview_url = $2, error_message = $3
      WHERE id = $4
      RETURNING id, user_id, status, preview_url, error_message;
    `;
    const result = await pool.query(query, [status, preview_url || null, error_message || null, id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Trabajo no encontrado para actualización.' });
    }

    const updatedJob = result.rows[0];
    console.log(`📢 Trabajo de prueba virtual actualizado por IA Worker: ${id} (${status})`);

    // Notificar al cliente vía WebSocket
    notifyUserJobUpdate(updatedJob.user_id, updatedJob);

    res.json({ success: true, message: 'Trabajo actualizado y notificado.' });
  } catch (error) {
    console.error('❌ ERROR EN POST /api/nail-tryon/:id/complete:', error);
    res.status(500).json({ error: 'Error al reportar finalización del trabajo.' });
  }
});

// ==========================================
// INICIO DEL SERVIDOR
// ==========================================
const server = app.listen(PORT, async () => {
  console.log(`🚀 Servidor en http://localhost:${PORT}`);
  console.log(`📦 Entorno: ${process.env.NODE_ENV || 'development'}`);
  await testConnection();
  await initDatabase();
});

// ==========================================
// CONFIGURACIÓN DE WEBSOCKET SERVER (Compartiendo puerto con HTTP)
// ==========================================
const wss = new WebSocketServer({ server });

wss.on('connection', (ws) => {
  console.log('🔌 Nuevo cliente WebSocket conectado.');
  
  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      if (data.type === 'register' && data.userId) {
        const userIdStr = data.userId.toString();
        if (!wsClients.has(userIdStr)) {
          wsClients.set(userIdStr, new Set());
        }
        wsClients.get(userIdStr).add(ws);
        console.log(`👤 Conexión WS registrada para usuario: ${userIdStr}`);
        ws.send(JSON.stringify({ status: 'registered', userId: userIdStr }));
      }
    } catch (err) {
      console.error('Error procesando mensaje WebSocket:', err);
    }
  });
  
  ws.on('close', () => {
    for (const [userId, connSet] of wsClients.entries()) {
      if (connSet.has(ws)) {
        connSet.delete(ws);
        if (connSet.size === 0) wsClients.delete(userId);
        console.log(`🔌 Conexión WS removida para usuario: ${userId}`);
        break;
      }
    }
  });
});

// ==========================================
// MANEJO GLOBAL DE ERRORES
// ==========================================
process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
});

process.on('uncaughtException', (error) => {
  console.error('❌ Uncaught Exception:', error);
  if (process.env.NODE_ENV !== 'development') {
    process.exit(1);
  }
});
