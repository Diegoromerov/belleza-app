const { pool } = require('../config/db');
const { resolverPrecio } = require('../services/precioService');
const wompiClient = require('../services/wompiClient');
const { discriminarIva } = require('../utils/iva');
const dianInvoiceClient = require('../services/dianInvoiceClient');
const { cotizarEnvio } = require('../services/shippingService');

const verifyWompiSignature = (req) => {
  if (!process.env.WOMPI_EVENTS_SECRET && process.env.NODE_ENV === 'test') {
    return true;
  }

  const headerChecksum = req.header('x-event-checksum');
  const resultado = wompiClient.verifyEventChecksum(req.body, headerChecksum);

  if (!resultado.valid) {
    console.warn(`🚨 [FINTECH SECURITY ALERT] Evento Wompi rechazado desde IP ${req.ip}: ${resultado.reason}`);
  }

  return resultado.valid;
};

// POST /api/store/checkout → Crear un nuevo pedido
exports.createOrder = async (req, res) => {
  const compradorId = req.user.id;
  const userRole = req.user.role; // 'client', 'provider', 'salon', 'admin'
  const { 
    booking_id, 
    nombre_entrega, 
    direccion_entrega, 
    items,
    // Campos estructurados de dirección (opcionales, vienen del frontend si el usuario seleccionó una dirección guardada)
    tipo_via,
    numero_principal,
    letra_principal,
    numero_secundario,
    letra_secundaria,
    complemento,
    barrio,
    ciudad,
    departamento,
    codigo_postal,
    referencia,
    direccion_entrega_id
  } = req.body;

  if (!items || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ error: 'Se requiere una lista de productos (items)' });
  }
  if (!nombre_entrega || !direccion_entrega) {
    return res.status(400).json({ error: 'Se requiere nombre y dirección de entrega' });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    let prestadorComisionadoId = null;
    let tieneDescuentoReserva = false;

    // Si está asociado a una cita, validar
    if (booking_id) {
      if (userRole === 'provider') {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Un prestador no puede asociar compras a una reserva' });
      }

      const bookingRes = await client.query(
        'SELECT id, provider_id, client_id FROM bookings WHERE id = $1;',
        [booking_id]
      );

      if (bookingRes.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Reserva no encontrada' });
      }

      const booking = bookingRes.rows[0];
      if (booking.client_id !== compradorId) {
        await client.query('ROLLBACK');
        return res.status(403).json({ error: 'No tienes acceso a esta reserva' });
      }

      prestadorComisionadoId = booking.provider_id;
      tieneDescuentoReserva = true;
    }

    let subtotal = 0;
    let comisionTotal = 0;
    const processedItems = [];

    // Validar productos, resolver precios y stock
    for (const item of items) {
      const { producto_id, cantidad } = item;
      if (!producto_id || !cantidad || cantidad <= 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'ID de producto y cantidad válidos son obligatorios' });
      }

      // Obtener producto
      const prodRes = await client.query(
        'SELECT * FROM productos WHERE id = $1 FOR UPDATE;', // Bloqueo para concurrencia
        [producto_id]
      );

      if (prodRes.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: `Producto con ID ${producto_id} no encontrado` });
      }

      const product = prodRes.rows[0];

      // Resolver precio por nivel y validar unidad_minima ANTES de tocar stock
      let resPrecio;
      try {
        resPrecio = await resolverPrecio({
          rol: userRole,
          productoId: product.id,
          cantidad: cantidad
        });
      } catch (precioErr) {
        if (precioErr.code === 'MINIMO_NO_CUMPLIDO') {
          await client.query('ROLLBACK');
          return res.status(400).json({
            error: precioErr.message,
            unidad_minima: precioErr.unidad_minima,
            lista: precioErr.lista
          });
        }
        throw precioErr;
      }

      if (!resPrecio || resPrecio.estado === 'sin_precio' || resPrecio.precio === null || resPrecio.precio === undefined) {
        await client.query('ROLLBACK');
        return res.status(403).json({ error: `No tienes acceso al producto ${product.nombre}` });
      }

      // Validar stock
      if (product.stock < cantidad) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: `Stock insuficiente para ${product.nombre}. Disponible: ${product.stock}` });
      }

      const precioUnitario = resPrecio.precio;
      const comisionUnitaria = 0;

      // Restar stock
      await client.query(
        'UPDATE productos SET stock = stock - $1 WHERE id = $2;',
        [cantidad, producto_id]
      );

      subtotal += precioUnitario * cantidad;
      comisionTotal += comisionUnitaria * cantidad;

      processedItems.push({
        producto_id,
        cantidad,
        precio_unitario_pagado: precioUnitario,
        comision_unitaria_prestador: comisionUnitaria,
        nombre: product.nombre
      });
    }

    // Calcular envío e IVA usando el motor de cotización por zonas (L5)
    // Si tiene descuento por reserva (entrega en cita), envío gratis
    let costoEnvio = 0;
    let transportadoraSugerida = null;
    let diasEstimados = null;

    if (!tieneDescuentoReserva) {
      // Usar campos estructurados si vienen en el request, sino fallback a parsing direccion_entrega
      const ciudad = req.body.ciudad;
      const departamento = req.body.departamento;
      const codigo_postal = req.body.codigo_postal;
      const pesoEstimadoKg = req.body.peso_total_kg || 0.5; // default 500g

      if (ciudad && departamento) {
        try {
          const cotizacion = await cotizarEnvio({
            ciudad,
            departamento,
            codigo_postal,
            peso_total_kg: pesoEstimadoKg,
            valor_pedido: subtotal
          });
          costoEnvio = cotizacion.costo;
          transportadoraSugerida = cotizacion.transportadora;
          diasEstimados = cotizacion.dias_estimados;
        } catch (err) {
          console.warn('⚠️ Error cotizando envío, usando tarifa plana:', err.message);
          costoEnvio = 12000;
        }
      } else {
        // Fallback tarifa plana si no hay dirección estructurada
        costoEnvio = 12000;
      }
    }

    const iva = subtotal * 0.19; // 19% IVA
    const total = subtotal + iva + costoEnvio;

    // El estado NO se escribe aquí: lo pone el DEFAULT del esquema, que ya es
    // el correcto ('PENDIENTE_PAGO' en
    // migrations/010_implement_glowstore_schema.sql:66). Antes se metía el
    // literal 'PAGADO' en el INSERT, así que el pedido NACÍA pagado sin que
    // ninguna pasarela hubiera cobrado: la fila quedaba en la base como prueba
    // de un pago que nunca ocurrió. Un pedido solo pasa a 'PAGADO' cuando
    // existe una transacción verificada que lo respalde.
    const orderInsertRes = await client.query(
      `INSERT INTO pedidos_tienda 
        (comprador_id, rol_comprador, booking_id, prestador_comisionado_id, comision_total_prestador, subtotal, envio, iva, total, nombre_entrega, direccion_entrega,
         tipo_via, numero_principal, letra_principal, numero_secundario, letra_secundaria, complemento, barrio, ciudad, departamento, codigo_postal, referencia, direccion_entrega_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11,
               $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23)
       RETURNING *;`,
      [
        compradorId,
        userRole === 'provider' ? 'PRESTADOR' : userRole === 'salon' ? 'SALON' : 'CLIENTE',
        booking_id || null,
        prestadorComisionadoId,
        comisionTotal,
        subtotal,
        costoEnvio,
        iva,
        total,
        nombre_entrega,
        direccion_entrega,
        tipo_via || null,
        numero_principal || null,
        letra_principal || null,
        numero_secundario || null,
        letra_secundaria || null,
        complemento || null,
        barrio || null,
        ciudad || null,
        departamento || null,
        codigo_postal || null,
        referencia || null,
        direccion_entrega_id || null
      ]
    );

    const order = orderInsertRes.rows[0];

    // Crear los detalles del pedido
    for (const pItem of processedItems) {
      await client.query(
        `INSERT INTO detalles_pedido_tienda 
          (pedido_id, producto_id, cantidad, precio_unitario_pagado, comision_unitaria_prestador)
         VALUES ($1, $2, $3, $4, $5);`,
        [
          order.id,
          pItem.producto_id,
          pItem.cantidad,
          pItem.precio_unitario_pagado,
          pItem.comision_unitaria_prestador
        ]
      );
    }

    await client.query('COMMIT');

    res.status(201).json({
      success: true,
      data: {
        order,
        items: processedItems
      }
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ ERROR EN CHECKOUT DE TIENDA:', error);
    res.status(500).json({ error: 'Error al procesar el checkout' });
  } finally {
    client.release();
  }
};

// GET /api/store/orders → Obtener pedidos del usuario logueado
exports.getOrders = async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;

    let query = '';
    const params = [userId];

    if (userRole === 'provider') {
      // Un prestador ve sus compras y también las ventas que debe entregar
      query = `
        SELECT DISTINCT pt.* 
        FROM pedidos_tienda pt
        WHERE pt.comprador_id = $1 OR pt.prestador_comisionado_id = $1
        ORDER BY pt.creado_en DESC;
      `;
    } else if (userRole === 'salon') {
      // Un salón ve sus compras (como cliente)
      query = `
        SELECT pt.* 
        FROM pedidos_tienda pt
        WHERE pt.comprador_id = $1
        ORDER BY pt.creado_en DESC;
      `;
    } else if (userRole === 'admin') {
      // Admin ve todo
      query = `
        SELECT pt.* 
        FROM pedidos_tienda pt
        ORDER BY pt.creado_en DESC;
      `;
      // Limpiar params para admin ya que no filtra por ID de comprador por defecto
      params.pop();
    } else {
      // Cliente normal solo ve sus propias compras
      query = `
        SELECT pt.* 
        FROM pedidos_tienda pt
        WHERE pt.comprador_id = $1
        ORDER BY pt.creado_en DESC;
      `;
    }

    const { rows } = await pool.query(query, params);

    res.json({
      success: true,
      count: rows.length,
      data: rows
    });
  } catch (error) {
    console.error('❌ ERROR EN GET /api/store/orders:', error);
    res.status(500).json({ error: 'Error al obtener pedidos' });
  }
};

// GET /api/store/orders/:id → Obtener detalle de un pedido específico
exports.getOrderById = async (req, res) => {
  try {
    const orderId = req.params.id;
    const userId = req.user.id;
    const userRole = req.user.role;

    // Obtener cabecera
    const orderRes = await pool.query(
      'SELECT * FROM pedidos_tienda WHERE id = $1;',
      [orderId]
    );

    if (orderRes.rows.length === 0) {
      return res.status(404).json({ error: 'Pedido no encontrado' });
    }

    const order = orderRes.rows[0];

    // Validar propiedad de visualización
    if (
      userRole !== 'admin' &&
      order.comprador_id !== userId &&
      order.prestador_comisionado_id !== userId
    ) {
      return res.status(403).json({ error: 'No autorizado para ver este pedido' });
    }

    // Obtener detalles
    const detailsRes = await pool.query(
      `SELECT dpt.*, p.nombre, p.imagen_url, p.tag_especialidad 
       FROM detalles_pedido_tienda dpt
       JOIN productos p ON dpt.producto_id = p.id
       WHERE dpt.pedido_id = $1;`,
      [orderId]
    );

    res.json({
      success: true,
      data: {
        order,
        items: detailsRes.rows
      }
    });
  } catch (error) {
    console.error('❌ ERROR EN GET /api/store/orders/:id:', error);
    res.status(500).json({ error: 'Error al obtener detalle del pedido' });
  }
};

// 🔹 POST /api/store/orders/:id/pay — Pagar un pedido de tienda
// Mismo contrato que payBooking: crea transacción, exige acceptance_token y payment_method/phoneNumber
exports.payOrder = async (req, res) => {
  try {
    const userId = req.user.id;
    const orderId = req.params.id;
    const { payment_method, phone_number, payment_source_id, acceptance_token } = req.body;

    // Validar pedido
    const orderRes = await pool.query('SELECT * FROM pedidos_tienda WHERE id = $1;', [orderId]);
    if (orderRes.rows.length === 0) {
      return res.status(404).json({ error: 'Pedido no encontrado' });
    }
    const order = orderRes.rows[0];

    // Verificar propiedad
    if (order.comprador_id !== userId) {
      return res.status(403).json({ error: 'No autorizado para pagar este pedido' });
    }

    if (order.estado !== 'PENDIENTE_PAGO') {
      return res.status(400).json({ error: `El pedido ya está en estado ${order.estado}` });
    }

    // Validar instrumento de pago
    const validPaymentMethods = [
      'NEQUI', 'CARD', 'PSE', 'BANCOLOMBIA_TRANSFER', 'DAVIPLATA',
      'BANCO_DE_BOGOTA_TRANSFER', 'BANCO_DE_OCCIDENTE_TRANSFER',
      'BANCO_AV_VILLAS_TRANSFER', 'BANCO_POPULAR_TRANSFER', 'BANCO_PICHINCHA_TRANSFER'
    ];
    if (!payment_method || !validPaymentMethods.includes(payment_method.toUpperCase())) {
      return res.status(400).json({ 
        error: `Método de pago inválido. Válidos: ${validPaymentMethods.join(', ')}` 
      });
    }
    if (!acceptance_token || acceptance_token.trim().isEmpty) {
      return res.status(400).json({ error: 'acceptance_token es obligatorio (Habeas Data).' });
    }
    
    const method = payment_method.toUpperCase();
    
    // NEQUI requiere phone_number
    if (method === 'NEQUI' && (!phone_number || phone_number.trim().isEmpty)) {
      return res.status(400).json({ error: 'phone_number es obligatorio para pagos Nequi.' });
    }
    
    // CARD requiere payment_source_id (token de tarjeta)
    if (method === 'CARD' && (!payment_source_id || payment_source_id.trim().isEmpty)) {
      return res.status(400).json({ error: 'payment_source_id es obligatorio para pagos con tarjeta (fuente tokenizada).' });
    }
    
    // PSE y transferencias bancarias requieren redirect_url y customer_data
    const redirectMethods = [
      'PSE', 'BANCOLOMBIA_TRANSFER', 'DAVIPLATA',
      'BANCO_DE_BOGOTA_TRANSFER', 'BANCO_DE_OCCIDENTE_TRANSFER',
      'BANCO_AV_VILLAS_TRANSFER', 'BANCO_POPULAR_TRANSFER', 'BANCO_PICHINCHA_TRANSFER'
    ];
    if (redirectMethods.includes(method)) {
      // Para métodos redirect, se necesita redirect_url y customer_data
      if (!redirect_url || redirect_url.trim().isEmpty) {
        return res.status(400).json({ error: 'redirect_url es obligatorio para métodos de redirección (PSE, transferencias).' });
      }
      if (!customer_data || !customer_data.email || !customer_data.full_name || !customer_data.phone_number) {
        return res.status(400).json({ error: 'customer_data (email, full_name, phone_number) es obligatorio para métodos de redirección.' });
      }
      if (!customer_data.financial_institution_code) {
        return res.status(400).json({ error: 'customer_data.financial_institution_code es obligatorio para métodos de redirección.' });
      }
    }

    // Verificar monto
    const expectedAmount = parseFloat(order.total);
    if (isNaN(expectedAmount) || expectedAmount <= 0) {
      return res.status(500).json({ error: 'Total del pedido inválido.' });
    }

    // Crear transacción en estado PENDING (el webhook la confirmará)
    const externalId = 'wompi_order_' + orderId + '_' + Date.now();

    // Preparar datos para Wompi según el método
    const wompiTransactionData = {
      amountInCents: Math.round(expectedAmount * 100),
      currency: 'COP',
      reference: externalId,
      customerEmail: req.user.email || 'cliente@glowapp.co',
      acceptanceToken: acceptance_token,
      paymentSourceId: method === 'CARD' ? payment_source_id : null,
      paymentMethod: ['NEQUI', 'CARD'].includes(method) ? method : null,
      customerData: redirectMethods.includes(method) ? customer_data : null,
      redirectUrl: redirectMethods.includes(method) ? redirect_url : null,
      ip: req.ip || null,
      auth: 'private'
    };

    // Para métodos de redirección, Wompi espera payment_method con el tipo específico
    if (redirectMethods.includes(method)) {
      wompiTransactionData.paymentMethod = method;
      wompiTransactionData.paymentSourceId = null; // no se usa payment_source_id para redirección
    }

    const wompiClient = require('../services/wompiClient');
    const wompiTx = await wompiClient.createTransaction(wompiTransactionData);

    // Guardar transacción local
    const transactionRes = await pool.query(
      `INSERT INTO transactions
         (booking_id, client_id, provider_id, amount, monto_total, comision_plataforma,
          monto_neto_prestador, impuestos_retencion, status, payment_method, external_id,
          pasarela_pago, referencia_pasarela, estado_pago, liberado_al_prestador)
       VALUES (NULL, $1, NULL, $2, $2, 0, $2, 0, 'pending', $3, $4, 'wompi', $4, 'pending', false)
       RETURNING *;`,
      [userId, expectedAmount, method, externalId]
    );
    const transaction = transactionRes.rows[0];

    // Actualizar pedido a PENDIENTE_PAGO (ya lo está) y guardar external_id de la transacción
    await pool.query(
      `UPDATE pedidos_tienda SET metadata = jsonb_set(COALESCE(metadata, '{}'::jsonb), '{wompi_external_id}', to_jsonb($2)) WHERE id = $1;`,
      [orderId, externalId]
    );

    // Responder 202: la transacción se inició, el webhook confirma
    res.status(202).json({
      success: true,
      data: {
        transaction_id: transaction.id,
        external_id: externalId,
        amount: expectedAmount,
        status: 'pending',
        payment_method: method,
        // PSE / transferencias: el usuario debe abrir esta URL para autorizar el cobro.
        async_payment_url: wompiTx.asyncPaymentUrl || null,
        message: redirectMethods.includes(method)
          ? 'Transacción iniciada. Abre la URL de redirección para autorizar el pago.'
          : 'Transacción iniciada. El webhook de Wompi confirmará el pago.'
      }
    });

  } catch (error) {
    console.error('❌ ERROR EN POST /api/store/orders/:id/pay:', error);
    res.status(500).json({ error: 'Error al iniciar el pago del pedido' });
  }
};

// 🔹 POST /api/payments/store-webhook — Webhook de Wompi para pedidos de tienda
exports.storeWebhook = async (req, res) => {
  try {
    if (!verifyWompiSignature(req)) {
      return res.status(401).json({ error: 'Invalid event signature' });
    }

    const event = req.body;
    const eventType = event?.event?.type || event?.type;
    const data = event?.data?.transaction || event?.data || event;

    if (!eventType || !data) {
      return res.status(400).json({ error: 'Evento Wompi inválido' });
    }

    // Solo procesar transaction.updated / transaction.approved / transaction.declined
    if (!['transaction.updated', 'transaction.approved', 'transaction.declined'].includes(eventType)) {
      return res.json({ success: true });
    }

    const externalId = data.id || data.external_id;
    const status = data.status;
    const amount = data.amount_in_cents ? data.amount_in_cents / 100 : data.amount;

    if (!externalId) {
      console.warn('⚠️ Webhook store sin external_id');
      return res.json({ success: true });
    }

    // Buscar transacción
    const txRes = await pool.query('SELECT * FROM transactions WHERE external_id = $1;', [externalId]);
    if (txRes.rows.length === 0) {
      console.warn(`⚠️ Transacción no encontrada para external_id ${externalId}`);
      return res.json({ success: true });
    }
    const tx = txRes.rows[0];

    if (status === 'APPROVED') {
      // Idempotencia
      if (tx.status === 'paid') {
        return res.json({ success: true });
      }

      await pool.query('BEGIN');
      try {
        // Verificar monto
        if (parseFloat(amount) < parseFloat(tx.monto_total)) {
          throw new Error(`Monto pagado (${amount}) menor al esperado (${tx.monto_total})`);
        }

        // Marcar transacción pagada
        await pool.query(
          `UPDATE transactions SET status = 'paid', estado_pago = 'paid', monto_total = $2 WHERE id = $1;`,
          [tx.id, amount]
        );

        // Buscar pedido asociado via external_id en metadata
        const orderRes = await pool.query(
          `SELECT * FROM pedidos_tienda WHERE metadata->>'wompi_external_id' = $1;`,
          [externalId]
        );
        if (orderRes.rows.length > 0) {
          const order = orderRes.rows[0];
          await pool.query(
            `UPDATE pedidos_tienda SET estado = 'PAGADO' WHERE id = $1;`,
            [order.id]
          );
          console.log(`✅ [STORE WEBHOOK] Pedido ${order.id} marcado PAGADO`);
        }

        await pool.query('COMMIT');

          // 🔹 Generar factura electrónica DIAN para el pedido pagado
          if (orderRes.rows.length > 0) {
            const order = orderRes.rows[0];
            try {
              await generarFacturaDianPedido(order.id);
            } catch (invoiceError) {
              console.error(`❌ [DIAN INVOICE] Error generando factura para pedido ${order.id}:`, invoiceError.message);
              // No falla el webhook: la factura se puede reintentar manualmente
            }
          }
      } catch (err) {
        await pool.query('ROLLBACK');
        throw err;
      }
    } else if (['DECLINED', 'VOIDED', 'ERROR'].includes(status)) {
      await pool.query(
        `UPDATE transactions SET status = 'failed', estado_pago = 'failed' WHERE id = $1;`,
        [tx.id]
      );
      console.log(`⚠️ [STORE WEBHOOK] Transacción ${externalId} en ${status}`);
    }

    res.json({ success: true });
  } catch (error) {
    console.error('❌ ERROR EN /api/payments/store-webhook:', error);
    res.status(500).json({ error: 'Error al procesar webhook' });
  }
};

/**
 * Genera y envía la Factura Electrónica DIAN para un pedido de tienda pagado.
 */
async function generarFacturaDianPedido(pedidoId) {
  if (!dianInvoiceClient.isConfigured()) {
    console.info(`[DIAN INVOICE] Cliente no configurado (falta certificado/NIT). Saltando factura para pedido ${pedidoId}.`);
    return;
  }

  // Obtener datos del pedido con detalles
  const orderRes = await pool.query(
    `SELECT pt.*, u.id as comprador_id, u.email as comprador_email, u.first_name, u.last_name, u.document_number, u.document_type, u.phone, u.address
     FROM pedidos_tienda pt
     JOIN usuarios u ON pt.comprador_id = u.id
     WHERE pt.id = $1;`,
    [pedidoId]
  );

  if (orderRes.rows.length === 0) {
    throw new Error(`Pedido ${pedidoId} no encontrado para facturación`);
  }

  const order = orderRes.rows[0];

  // Obtener detalles del pedido
  const detailsRes = await pool.query(
    `SELECT dpt.*, p.nombre, p.tag_especialidad
     FROM detalles_pedido_tienda dpt
     JOIN productos p ON dpt.producto_id = p.id
     WHERE dpt.pedido_id = $1;`,
    [pedidoId]
  );

  // Datos del emisor
  const emisorNit = process.env.DIAN_NIT;
  const emisorDv = process.env.DIAN_DV || '0';
  const emisorRazonSocial = process.env.DIAN_RAZON_SOCIAL || 'GlowApp S.A.S.';
  const emisorDireccion = process.env.DIAN_DIRECCION || 'Calle 100 # 7-21';
  const emisorMunicipio = process.env.DIAN_MUNICIPIO || '11001';
  const emisorDepartamento = process.env.DIAN_DEPARTAMENTO || '11';
  const emisorTelefono = process.env.DIAN_TELEFONO || '+57 1 234 5678';
  const emisorEmail = process.env.DIAN_EMAIL || 'facturacion@glowapp.co';
  const emisorRutResponsabilidades = [48];

  // Calcular desglose IVA
  const subtotal = parseFloat(order.subtotal) || parseFloat(order.total) / 1.19;
  const totalImpuestos = parseFloat(order.iva) || (parseFloat(order.total) - subtotal);
  const totalFactura = parseFloat(order.total);

  // Preparar líneas
  const lineas = detailsRes.rows.map((item, index) => ({
    cantidad: item.cantidad,
    unidad: '94',
    descripcion: item.nombre || 'Producto GlowStore',
    valorUnitario: parseFloat(item.precio_unitario),
    ivaPorcentaje: item.iva_porcentaje || 19,
    codigo: item.producto_id
  }));

  const now = new Date();
  const fechaEmision = now.toISOString().split('T')[0];
  const horaEmision = now.toTimeString().split(' ')[0];

  // Generar XML UBL 2.1
  const xmlFirmado = await dianInvoiceClient.generarFacturaXml({
    numeroFactura: `FAC-STORE-${pedidoId}`,
    fechaEmision,
    horaEmision,
    tipoFactura: '01',
    metodoPago: '1',
    formaPago: '1',
    moneda: 'COP',
    tipoOperacion: '10',

    // Emisor
    emisorNit,
    emisorDv,
    emisorRazonSocial,
    emisorDireccion,
    emisorMunicipio,
    emisorDepartamento,
    emisorTelefono,
    emisorEmail,
    emisorRutResponsabilidades,

    // Adquiriente
    adquirienteTipoDoc: order.document_type === 'CC' ? 13 : 31,
    adquirienteNumeroDoc: order.document_number,
    adquirienteDv: order.document_dv || '0',
    adquirienteRazonSocial: `${order.first_name} ${order.last_name}`,
    adquirienteDireccion: order.address || 'Sin dirección',
    adquirienteMunicipio: order.city_code || '11001',
    adquirienteDepartamento: order.state_code || '11',
    adquirienteTelefono: order.phone || 'N/A',
    adquirienteEmail: order.comprador_email,

    // Líneas y totales
    lineas,
    subtotal,
    totalDescuentos: parseFloat(order.descuento) || 0,
    totalCargos: parseFloat(order.cargo_envio) || 0,
    totalImpuestos,
    totalFactura,

    observaciones: `Pedido GlowStore ${pedidoId}`
  });

  // Enviar a DIAN / Proveedor
  const resultado = await dianInvoiceClient.enviarFactura(xmlFirmado, `FAC-STORE-${pedidoId}`);

  if (!resultado.aceptada) {
    throw new Error(`Factura rechazada por DIAN: ${JSON.stringify(resultado.respuesta)}`);
  }

  // Guardar CUFE y QR en el pedido
  await pool.query(
    `UPDATE pedidos_tienda SET 
       cufe = $2, 
       qr_factura = $3, 
       factura_emitida = true, 
       factura_fecha = $4 
     WHERE id = $1;`,
    [pedidoId, resultado.cufe, resultado.qr, new Date()]
  );

  console.log(`✅ [DIAN INVOICE] Factura emitida para pedido ${pedidoId} - CUFE: ${resultado.cufe}`);
}

/**
 * POST /api/admin/store/orders/:id/dispatch — Marcar pedido como DESPACHADO (solo admin)
 * Body: { transportadora, guia, url_rastreo, observaciones }
 */
async function dispatchOrder(req, res) {
  try {
    const orderId = req.params.id;
    const { transportadora, guia, url_rastreo, observaciones } = req.body;

    // Validar campos obligatorios
    if (!transportadora || !transportadora.trim()) {
      return res.status(400).json({ error: 'transportadora es obligatoria' });
    }
    if (!guia || !guia.trim()) {
      return res.status(400).json({ error: 'guia (número de guía) es obligatoria' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Verificar pedido y estado actual
      const orderRes = await client.query('SELECT * FROM pedidos_tienda WHERE id = $1;', [orderId]);
      if (orderRes.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Pedido no encontrado' });
      }
      const order = orderRes.rows[0];

      if (order.estado !== 'PAGADO') {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: `El pedido debe estar PAGADO para despachar. Estado actual: ${order.estado}` });
      }

      // Actualizar pedido a DESPACHADO con timestamp
      await client.query(
        `UPDATE pedidos_tienda SET estado = 'DESPACHADO', despachado_en = NOW() WHERE id = $1;`,
        [orderId]
      );

      // Crear registro en tabla envios
      const envioRes = await client.query(
        `INSERT INTO envios (pedido_id, transportadora, guia, url_rastreo, estado, observaciones)
         VALUES ($1, $2, $3, $4, 'CREADO', $5)
         RETURNING *;`,
        [orderId, transportadora, guia, url_rastreo || null, observaciones || null]
      );

      await client.query('COMMIT');

      console.log(`✅ [ADMIN DISPATCH] Pedido ${orderId} despachado vía ${transportadora} guía ${guia}`);

      res.json({
        success: true,
        data: {
          order: { ...order, estado: 'DESPACHADO', despachado_en: new Date() },
          envio: envioRes.rows[0]
        }
      });
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (error) {
    console.error('❌ ERROR EN POST /api/admin/store/orders/:id/dispatch:', error);
    res.status(500).json({ error: 'Error al despachar el pedido' });
  }
}

/**
 * POST /api/admin/store/orders/:id/deliver — Marcar pedido como ENTREGADO (solo admin)
 * Body: { observaciones }
 * Alternativa: PATCH /api/admin/envios/:guia/deliver
 */
async function deliverOrder(req, res) {
  try {
    const orderId = req.params.id;
    const { observaciones } = req.body;

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Verificar pedido y estado actual
      const orderRes = await client.query('SELECT * FROM pedidos_tienda WHERE id = $1;', [orderId]);
      if (orderRes.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Pedido no encontrado' });
      }
      const order = orderRes.rows[0];

      if (!['DESPACHADO', 'PAGADO'].includes(order.estado)) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: `El pedido debe estar DESPACHADO (o PAGADO) para marcar como entregado. Estado actual: ${order.estado}` });
      }

      // Actualizar pedido a ENTREGADO con timestamp
      await client.query(
        `UPDATE pedidos_tienda SET estado = 'ENTREGADO', entregado_en = NOW() WHERE id = $1;`,
        [orderId]
      );

      // Actualizar envío a ENTREGADO
      await client.query(
        `UPDATE envios SET estado = 'ENTREGADO', entregado_en = NOW(), observaciones = COALESCE($2, observaciones)
         WHERE pedido_id = $1;`,
        [orderId, observaciones || null]
      );

      await client.query('COMMIT');

      console.log(`✅ [ADMIN DELIVER] Pedido ${orderId} marcado ENTREGADO`);

      res.json({
        success: true,
        data: { order: { ...order, estado: 'ENTREGADO', entregado_en: new Date() } }
      });
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (error) {
    console.error('❌ ERROR EN POST /api/admin/store/orders/:id/deliver:', error);
    res.status(500).json({ error: 'Error al marcar pedido como entregado' });
  }
}

/**
 * POST /api/admin/store/orders/:id/cancel — Cancelar pedido (solo admin)
 * Body: { motivo }
 */
async function cancelOrder(req, res) {
  try {
    const orderId = req.params.id;
    const { motivo } = req.body;

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const orderRes = await client.query('SELECT * FROM pedidos_tienda WHERE id = $1;', [orderId]);
      if (orderRes.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Pedido no encontrado' });
      }
      const order = orderRes.rows[0];

      if (['ENTREGADO', 'CANCELADO'].includes(order.estado)) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: `No se puede cancelar un pedido en estado ${order.estado}` });
      }

      // Si estaba pagado, crear transacción de reembolso (stub)
      if (order.estado === 'PAGADO' || order.estado === 'DESPACHADO') {
        console.warn(`⚠️ [ADMIN CANCEL] Pedido ${orderId} cancelado tras pago/despacho — requiere reembolso manual`);
      }

      // Actualizar pedido a CANCELADO
      await client.query(
        `UPDATE pedidos_tienda SET estado = 'CANCELADO', cancelado_en = NOW() WHERE id = $1;`,
        [orderId]
      );

      // Cancelar envío si existe
      await client.query(
        `UPDATE envios SET estado = 'DEVUELTO', observaciones = COALESCE($2, observaciones) WHERE pedido_id = $1;`,
        [orderId, motivo || 'Cancelado por admin']
      );

      await client.query('COMMIT');

      console.log(`✅ [ADMIN CANCEL] Pedido ${orderId} cancelado`);

      res.json({
        success: true,
        data: { order: { ...order, estado: 'CANCELADO', cancelado_en: new Date() } }
      });
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (error) {
    console.error('❌ ERROR EN POST /api/admin/store/orders/:id/cancel:', error);
    res.status(500).json({ error: 'Error al cancelar el pedido' });
  }
}

/**
 * GET /api/admin/store/orders — Listar todos los pedidos (admin)
 * Query: estado, desde, hasta, page, limit
 */
async function getAllStoreOrdersAdmin(req, res) {
  try {
    const { estado, desde, hasta, page = 1, limit = 50 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    let where = '1=1';
    const params = [];
    let paramIdx = 1;

    if (estado) {
      where += ` AND pt.estado = $${paramIdx++}`;
      params.push(estado.toUpperCase());
    }
    if (desde) {
      where += ` AND pt.creado_en >= $${paramIdx++}`;
      params.push(desde);
    }
    if (hasta) {
      where += ` AND pt.creado_en <= $${paramIdx++}`;
      params.push(hasta);
    }

    params.push(parseInt(limit), offset);

    const query = `
      SELECT pt.*, u.email as comprador_email, u.first_name, u.last_name
      FROM pedidos_tienda pt
      JOIN usuarios u ON pt.comprador_id = u.id
      WHERE ${where}
      ORDER BY pt.creado_en DESC
      LIMIT $${paramIdx++} OFFSET $${paramIdx++};
    `;

    const countQuery = `
      SELECT COUNT(*) FROM pedidos_tienda pt WHERE ${where};
    `;

    const [dataRes, countRes] = await Promise.all([
      pool.query(query, params),
      pool.query(countQuery, params.slice(0, paramIdx - 3))
    ]);

    res.json({
      success: true,
      count: dataRes.rows.length,
      total: parseInt(countRes.rows[0].count),
      page: parseInt(page),
      limit: parseInt(limit),
      data: dataRes.rows
    });
  } catch (error) {
    console.error('❌ ERROR EN GET /api/admin/store/orders:', error);
    res.status(500).json({ error: 'Error al obtener pedidos' });
  }
}

/**
 * GET /api/admin/envios/:guia — Obtener tracking de envío
 */
async function getEnvioByGuia(req, res) {
  try {
    const { guia } = req.params;
    const resEnvio = await pool.query(
      `SELECT e.*, pt.estado as pedido_estado, pt.total, pt.nombre_entrega, pt.direccion_entrega
       FROM envios e
       JOIN pedidos_tienda pt ON e.pedido_id = pt.id
       WHERE e.guia = $1;`,
      [guia]
    );
    if (resEnvio.rows.length === 0) {
      return res.status(404).json({ error: 'Envío no encontrado' });
    }
    res.json({ success: true, data: resEnvio.rows[0] });
  } catch (error) {
    console.error('❌ ERROR EN GET /api/admin/envios/:guia:', error);
    res.status(500).json({ error: 'Error al obtener envío' });
  }
}

/**
 * PATCH /api/admin/envios/:guia/status — Actualizar estado de envío (webhook transportadora o manual)
 * Body: { estado, observaciones }
 */
async function updateEnvioStatus(req, res) {
  try {
    const { guia } = req.params;
    const { estado, observaciones } = req.body;

    const validEstados = ['CREADO', 'RECOGIDO', 'EN_TRANSITO', 'EN_CENTRO_DESTINO', 'SALIDA_ENTREGA', 'ENTREGADO', 'FALLIDO', 'DEVUELTO'];
    if (!validEstados.includes(estado)) {
      return res.status(400).json({ error: `Estado inválido. Válidos: ${validEstados.join(', ')}` });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const envioRes = await client.query('SELECT * FROM envios WHERE guia = $1;', [guia]);
      if (envioRes.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Envío no encontrado' });
      }

      const updateFields = ['estado = $2', 'actualizado_en = NOW()'];
      const updateParams = [guia, estado];
      let paramIdx = 3;

      if (estado === 'ENTREGADO') {
        updateFields.push(`entregado_en = NOW()`);
      }
      if (observaciones) {
        updateFields.push(`observaciones = $${paramIdx++}`);
        updateParams.push(observaciones);
      }

      await client.query(
        `UPDATE envios SET ${updateFields.join(', ')} WHERE guia = $1;`,
        updateParams
      );

      // Si ENTREGADO, también marcar pedido
      if (estado === 'ENTREGADO') {
        await client.query(
          `UPDATE pedidos_tienda SET estado = 'ENTREGADO', entregado_en = NOW() WHERE id = (SELECT pedido_id FROM envios WHERE guia = $1);`,
          [guia]
        );
      }

      await client.query('COMMIT');

      res.json({ success: true, data: { guia, estado } });
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (error) {
    console.error('❌ ERROR EN PATCH /api/admin/envios/:guia/status:', error);
    res.status(500).json({ error: 'Error al actualizar estado de envío' });
  }
}

async function cotizarEnvioPublic(req, res) {
  try {
    const { ciudad, departamento, codigo_postal, peso, valor } = req.query;
    if (!ciudad || !departamento) {
      return res.status(400).json({ error: 'ciudad y departamento son obligatorios' });
    }

    const { cotizarEnvio: cotizar } = require('../services/shippingService');
    const resultado = await cotizar({
      ciudad,
      departamento,
      codigo_postal: codigo_postal || null,
      peso_total_kg: parseFloat(peso) || 0.5,
      valor_pedido: parseFloat(valor) || 0
    });

    res.json({ success: true, data: resultado });
  } catch (error) {
    console.error('❌ ERROR EN GET /api/store/shipping/quote:', error);
    res.status(500).json({ error: 'Error al cotizar envío' });
  }
}

module.exports = {
  ...exports,
  generarFacturaDianPedido,
  dispatchOrder,
  deliverOrder,
  cancelOrder,
  getAllStoreOrdersAdmin,
  getEnvioByGuia,
  updateEnvioStatus,
  cotizarEnvioPublic
};
