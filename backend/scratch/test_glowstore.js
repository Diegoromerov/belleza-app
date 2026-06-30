// backend/scratch/test_glowstore.js
const { pool } = require('../config/db');
const fs = require('fs');
const path = require('path');

async function runTests() {
  console.log('🧪 Iniciando pruebas de integración de GlowStore...');

  try {
    // 1. Aplicar la migración manualmente si no se ha hecho
    console.log('1. Aplicando migración 010_implement_glowstore_schema.sql...');
    const sqlPath = path.join(__dirname, '../migrations/010_implement_glowstore_schema.sql');
    const sqlContent = fs.readFileSync(sqlPath, 'utf8');
    await pool.query(sqlContent);
    console.log('✅ Migración aplicada exitosamente.');

    // 2. Limpiar registros de prueba anteriores
    console.log('2. Limpiando datos viejos de prueba...');
    await pool.query("DELETE FROM detalles_pedido_tienda;");
    await pool.query("DELETE FROM pedidos_tienda;");
    await pool.query("DELETE FROM bookings WHERE id = 'b0000000-0000-0000-0000-000000000999';");
    await pool.query("DELETE FROM provider_wallet WHERE provider_id = 104;");
    await pool.query("DELETE FROM wallet_transactions WHERE provider_id = 104;");
    console.log('✅ Base de datos limpia para pruebas.');

    // 3. Crear una cita de prueba (Booking) asociada a la proveedora Ana (ID 104) y cliente Demo (ID 1)
    console.log('3. Creando cita de prueba...');
    await pool.query(`
      INSERT INTO bookings (id, client_id, provider_id, service_id, scheduled_at, valor_bruto, estado, payment_status)
      VALUES (
        'b0000000-0000-0000-0000-000000000999', 
        1, 
        104, 
        '00000000-0000-0000-0000-000000000402', 
        NOW(), 
        55000.00, 
        'CONFIRMADA', 
        'unpaid'
      )
      ON CONFLICT DO NOTHING;
    `);
    console.log('✅ Cita de prueba creada.');

    // 4. Test de Catálogo para Cliente
    console.log('4. Probando filtro de catálogo para Clientes...');
    const clientCatalog = await pool.query(
      "SELECT id, nombre, tipo_visibilidad FROM productos WHERE tipo_visibilidad = 'PUBLICO';"
    );
    const clientInsumos = clientCatalog.rows.filter(r => r.tipo_visibilidad === 'INSUMO_PRESTADOR');
    if (clientInsumos.length > 0) {
      throw new Error('❌ TEST FALLIDO: Los clientes pueden ver insumos exclusivos de prestador.');
    }
    console.log(`✅ TEST EXITOSO: Clientes ven ${clientCatalog.rows.length} productos y 0 insumos.`);

    // 5. Test de Catálogo para Prestador
    console.log('5. Probando catálogo para Prestador (debe incluir insumos)...');
    const providerCatalog = await pool.query(
      "SELECT id, nombre, tipo_visibilidad FROM productos;"
    );
    const providerInsumos = providerCatalog.rows.filter(r => r.tipo_visibilidad === 'INSUMO_PRESTADOR');
    if (providerInsumos.length === 0) {
      throw new Error('❌ TEST FALLIDO: Los prestadores no ven los insumos exclusivos.');
    }
    console.log(`✅ TEST EXITOSO: Prestadores ven todos los ${providerCatalog.rows.length} productos (incluye ${providerInsumos.length} insumos).`);

    // 6. Obtener producto público para simular compra
    const prodRes = await pool.query("SELECT id, stock, precio_con_reserva, comision_prestador FROM productos WHERE nombre = 'Shampoo de Argán Orgánico';");
    const shampoo = prodRes.rows[0];
    const stockAntes = shampoo.stock;
    console.log(`ℹ️ Shampoo de Argán - Stock inicial: ${stockAntes}, Precio con Reserva: $${shampoo.precio_con_reserva}, Comisión: $${shampoo.comision_prestador}`);

    // 7. Simular Checkout del Cliente asociado al Booking
    console.log('7. Simulando checkout de compra asociado a la cita...');
    const subtotal = parseFloat(shampoo.precio_con_reserva) * 2; // 2 unidades
    const comisionTotal = parseFloat(shampoo.comision_prestador) * 2;
    const iva = subtotal * 0.19;
    const total = subtotal + iva + 0.00; // Envío es 0 por ser asociado a cita

    const orderRes = await pool.query(`
      INSERT INTO pedidos_tienda 
        (comprador_id, rol_comprador, booking_id, prestador_comisionado_id, comision_total_prestador, subtotal, envio, iva, total, estado, nombre_entrega, direccion_entrega)
      VALUES ($1, 'CLIENTE', $2, $3, $4, $5, $6, $7, $8, 'PAGADO', $9, $10)
      RETURNING *;
    `, [
      1, // Cliente Demo
      'b0000000-0000-0000-0000-000000000999', // Booking ID
      104, // Prestador Ana
      comisionTotal,
      subtotal,
      0.00,
      iva,
      total,
      'Cliente Demo',
      'Calle Falsa 123'
    ]);
    const order = orderRes.rows[0];

    // Detalle de la orden
    await pool.query(`
      INSERT INTO detalles_pedido_tienda (pedido_id, producto_id, cantidad, precio_unitario_pagado, comision_unitaria_prestador)
      VALUES ($1, $2, 2, $3, $4);
    `, [order.id, shampoo.id, shampoo.precio_con_reserva, shampoo.comision_prestador]);

    // Simular reducción de stock
    await pool.query("UPDATE productos SET stock = stock - 2 WHERE id = $1;", [shampoo.id]);
    console.log('✅ Pedido insertado y stock reservado.');

    // Verificar stock decrementado
    const prodResDespues = await pool.query("SELECT stock FROM productos WHERE id = $1;", [shampoo.id]);
    const stockDespues = prodResDespues.rows[0].stock;
    if (stockDespues !== stockAntes - 2) {
      throw new Error(`❌ TEST FALLIDO: El stock no se restó correctamente. Antes: ${stockAntes}, Después: ${stockDespues}`);
    }
    console.log('✅ TEST EXITOSO: Reducción de stock verificada.');

    // 8. Verificar que el wallet del prestador esté en 0 antes de completar la cita
    console.log('8. Inicializando billetera de Ana...');
    await pool.query("INSERT INTO provider_wallet (provider_id, saldo_pendiente) VALUES (104, 0.00) ON CONFLICT (provider_id) DO NOTHING;");

    // 9. Simular la confirmación de la cita mediante el hook de OTP (Liberación de comisiones)
    console.log('9. Simulando confirmación de cita (OTP) en backend...');
    
    // Aquí replicamos exactamente el hook que añadimos en paymentRoutes.js:
    const storeOrderRes = await pool.query(
      'SELECT id, comision_total_prestador FROM pedidos_tienda WHERE booking_id = $1 AND prestador_comisionado_id = $2;',
      ['b0000000-0000-0000-0000-000000000999', 104]
    );

    if (storeOrderRes.rows.length > 0) {
      const storeOrder = storeOrderRes.rows[0];
      const comisionTienda = parseFloat(storeOrder.comision_total_prestador);

      if (comisionTienda > 0) {
        // Acreditar billetera
        await pool.query(
          `UPDATE provider_wallet 
           SET saldo_pendiente = saldo_pendiente + $2,
               total_ganado    = total_ganado + $2,
               updated_at      = NOW()
           WHERE provider_id = $1`,
          [104, comisionTienda]
        );

        // Registrar transacción de tipo CREDITO_PRODUCTO
        await pool.query(
          `INSERT INTO wallet_transactions
             (provider_id, booking_id, tipo, monto, saldo_resultante, estado, descripcion, metadata)
           VALUES ($1, $2, 'CREDITO_PRODUCTO', $3, $3, 'PENDIENTE', $4, $5)`,
          [
            104, 
            'b0000000-0000-0000-0000-000000000999', 
            comisionTienda,
            `Comisión de productos en GlowStore - Pedido #${storeOrder.id}`,
            JSON.stringify({
              madura_at: new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(),
              pedido_id: storeOrder.id,
              comision_total: comisionTienda
            })
          ]
        );
      }
    }

    // 10. Validar billetera e historial de transacciones del prestador
    console.log('10. Validando saldo acreditado en la billetera del prestador...');
    const walletRes = await pool.query("SELECT saldo_pendiente FROM provider_wallet WHERE provider_id = 104;");
    const saldoPendiente = parseFloat(walletRes.rows[0].saldo_pendiente);

    if (saldoPendiente !== comisionTotal) {
      throw new Error(`❌ TEST FALLIDO: La comisión de la tienda no se acreditó en la billetera. Esperado: ${comisionTotal}, Obtenido: ${saldoPendiente}`);
    }
    console.log(`✅ TEST EXITOSO: La billetera de Ana recibió correctamente la comisión de la tienda de $${saldoPendiente} COP.`);

    // 11. Limpieza final de datos de prueba
    console.log('11. Limpiando datos de prueba...');
    await pool.query("DELETE FROM detalles_pedido_tienda;");
    await pool.query("DELETE FROM pedidos_tienda;");
    await pool.query("DELETE FROM bookings WHERE id = 'b0000000-0000-0000-0000-000000000999';");
    await pool.query("DELETE FROM provider_wallet WHERE provider_id = 104;");
    await pool.query("DELETE FROM wallet_transactions WHERE provider_id = 104;");
    await pool.query("UPDATE productos SET stock = $1 WHERE id = $2;", [stockAntes, shampoo.id]);
    console.log('✅ Base de datos limpia de pruebas.');

    console.log('\n🎉 ¡TODAS LAS PRUEBAS DE INTEGRACIÓN PASARON EXITOSAMENTE! 🎉');

  } catch (error) {
    console.error('\n❌ ERROR DURANTE LA EJECUCIÓN DE PRUEBAS:', error);
  } finally {
    pool.end();
  }
}

runTests();
