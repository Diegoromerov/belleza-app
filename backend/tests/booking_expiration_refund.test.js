const { pool } = require('../src/config/db');
const { procesarExpiracionReservas, procesarRefundOutbox } = require('../src/jobs/paymentJobs');
const wompiService = require('../src/services/wompiService');
const crypto = require('crypto');

async function runN01Tests() {
  console.log('🚀 Iniciando suite exhaustiva N01: Booking Expiration & Wompi Refund...');
  let passed = 0;
  let total = 0;

  function assert(condition, name) {
    total++;
    if (condition) {
      console.log(`  ✅ [PASS] ${name}`);
      passed++;
    } else {
      console.error(`  ❌ [FAIL] ${name}`);
      throw new Error(`Test failed: ${name}`);
    }
  }

  const client = await pool.connect();

  try {
    // Obtener cliente y prestador reales existentes
    const clientRes = await client.query(`SELECT id FROM usuarios WHERE id > 0 LIMIT 1;`);
    const clientId = clientRes.rows[0].id;

    const provRes = await client.query(`SELECT id FROM perfiles_prestador LIMIT 1;`);
    let providerId;
    if (provRes.rows.length > 0) {
      providerId = provRes.rows[0].id;
    } else {
      // Crear perfil prestador si no existe
      await client.query(`INSERT INTO perfiles_prestador (id, is_online) VALUES ($1, true) ON CONFLICT DO NOTHING;`, [clientId]);
      providerId = clientId;
    }

    const servRes = await client.query(`SELECT id FROM services LIMIT 1;`);
    let serviceId;
    if (servRes.rows.length > 0) {
      serviceId = servRes.rows[0].id;
    } else {
      const newSId = crypto.randomUUID();
      await client.query(`
        INSERT INTO services (id, prestador_id, nombre, precio, duracion_minutos)
        VALUES ($1, $2, 'Corte Test', 50000, 30)
      `, [newSId, providerId]);
      serviceId = newSId;
    }

    // Helper para crear booking
    async function createTestBooking({ estado = 'CONFIRMADA', paid_at = null, valor = 50000 }) {
      const bId = crypto.randomUUID();
      const sched = new Date(Date.now() + 24 * 3600 * 1000); // Mañana
      await client.query(`
        INSERT INTO bookings (id, client_id, provider_id, service_id, scheduled_at, valor_bruto, estado, paid_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      `, [bId, clientId, providerId, serviceId, sched, valor, estado, paid_at]);
      return bId;
    }

    // TEST 1: Booking CONFIRMADA con < 15 min NO expira
    const b1 = await createTestBooking({ paid_at: new Date(Date.now() - 5 * 60 * 1000) }); // 5 min atrás
    await procesarExpiracionReservas();
    const res1 = await client.query(`SELECT estado FROM bookings WHERE id = $1`, [b1]);
    assert(res1.rows[0].estado === 'CONFIRMADA', '1. Booking CONFIRMADA < 15 min NO expira');

    // TEST 2: Booking CONFIRMADA con > 15 min EXPIRA a CANCELADA
    const b2 = await createTestBooking({ paid_at: new Date(Date.now() - 16 * 60 * 1000) }); // 16 min atrás
    await procesarExpiracionReservas();
    const res2 = await client.query(`SELECT estado, motivo_cancelacion FROM bookings WHERE id = $1`, [b2]);
    assert(res2.rows[0].estado === 'CANCELADA' && res2.rows[0].motivo_cancelacion === 'EXPIRACION_AUTOMATICA', '2. Booking CONFIRMADA > 15 min expira a CANCELADA');

    // TEST 3: Booking expirada crea exactamente 1 registro en refund_outbox y procesa a SUCCESS
    const outbox2 = await client.query(`SELECT status, amount FROM refund_outbox WHERE booking_id = $1`, [b2]);
    assert(outbox2.rows.length === 1 && outbox2.rows[0].status === 'SUCCESS', '3. Crea exactamente un registro en refund_outbox y procesa a SUCCESS');

    // TEST 4: Booking sin paid_at NO expira
    const b4 = await createTestBooking({ estado: 'CONFIRMADA', paid_at: null });
    await procesarExpiracionReservas();
    const res4 = await client.query(`SELECT estado FROM bookings WHERE id = $1`, [b4]);
    assert(res4.rows[0].estado === 'CONFIRMADA', '4. Booking sin paid_at NO expira');

    // TEST 5: Booking EN_PROGRESO NO expira aunque paid_at > 15 min
    const b5 = await createTestBooking({ estado: 'EN_PROGRESO', paid_at: new Date(Date.now() - 30 * 60 * 1000) });
    await procesarExpiracionReservas();
    const res5 = await client.query(`SELECT estado FROM bookings WHERE id = $1`, [b5]);
    assert(res5.rows[0].estado === 'EN_PROGRESO', '5. Booking EN_PROGRESO NO expira');

    // TEST 6: Doble ejecución del worker es idempotente
    await procesarExpiracionReservas();
    const outbox2_dup = await client.query(`SELECT COUNT(*) FROM refund_outbox WHERE booking_id = $1`, [b2]);
    assert(parseInt(outbox2_dup.rows[0].count) === 1, '6. Doble ejecución no duplica refund_outbox');

    // TEST 7: Wompi idempotencia - ALREADY_VOIDED se resuelve como SUCCESS
    const b7 = await createTestBooking({ paid_at: new Date(Date.now() - 20 * 60 * 1000) });
    await client.query(`
      INSERT INTO transactions (booking_id, amount, status, payment_method, external_id)
      VALUES ($1, 50000, 'paid', 'NEQUI', 'FORCE_ALREADY_VOIDED')
    `, [b7]);
    await procesarExpiracionReservas();
    const outbox7 = await client.query(`SELECT status FROM refund_outbox WHERE booking_id = $1`, [b7]);
    assert(outbox7.rows[0].status === 'SUCCESS', '7. Wompi ALREADY_VOIDED tratado como SUCCESS');

    // TEST 8: Wompi Retryable error (500) pasa a RETRYABLE_FAILURE
    const b8 = await createTestBooking({ paid_at: new Date(Date.now() - 20 * 60 * 1000) });
    await client.query(`
      INSERT INTO transactions (booking_id, amount, status, payment_method, external_id)
      VALUES ($1, 50000, 'paid', 'NEQUI', 'FORCE_500')
    `, [b8]);
    await procesarExpiracionReservas();
    const outbox8 = await client.query(`SELECT status, attempts FROM refund_outbox WHERE booking_id = $1`, [b8]);
    assert(outbox8.rows[0].status === 'RETRYABLE_FAILURE' && outbox8.rows[0].attempts === 1, '8. Wompi error 500 transiciona a RETRYABLE_FAILURE');

    // TEST 9: Wompi Fatal error (400) pasa a FINAL_FAILURE
    const b9 = await createTestBooking({ paid_at: new Date(Date.now() - 20 * 60 * 1000) });
    await client.query(`
      INSERT INTO transactions (booking_id, amount, status, payment_method, external_id)
      VALUES ($1, 50000, 'paid', 'NEQUI', 'FORCE_400')
    `, [b9]);
    await procesarExpiracionReservas();
    const outbox9 = await client.query(`SELECT status, attempts FROM refund_outbox WHERE booking_id = $1`, [b9]);
    assert(outbox9.rows[0].status === 'FINAL_FAILURE', '9. Wompi error fatal 400 pasa a FINAL_FAILURE');

    // TEST 10: Disponibilidad - Booking CANCELADO por expiración no bloquea disponibilidad
    const b10 = await createTestBooking({ paid_at: new Date(Date.now() - 20 * 60 * 1000) });
    await procesarExpiracionReservas();
    const checkBlocked = await client.query(`
      SELECT b.id FROM bookings b WHERE b.id = $1 AND b.estado != 'CANCELADA'
    `, [b10]);
    assert(checkBlocked.rows.length === 0, '10. Booking expirado queda excluido de bloqueos de disponibilidad');

    console.log(`\n🎉 Todos los tests N01 completados con éxito: ${passed}/${total} PASS.`);
  } finally {
    client.release();
  }
}

runN01Tests()
  .then(() => process.exit(0))
  .catch(err => {
    console.error('❌ Error en ejecución de tests N01:', err);
    process.exit(1);
  });
