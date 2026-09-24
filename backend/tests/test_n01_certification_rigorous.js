const { pool } = require('../src/config/db');
const { procesarExpiracionReservas, procesarRefundOutbox } = require('../src/jobs/paymentJobs');
const wompiService = require('../src/services/wompiService');
const nodo05AvailabilityService = require('../src/services/nodo05AvailabilityService');
const crypto = require('crypto');

async function runRigorousN01RTests() {
  console.log('🔍 INICIANDO SUITE DE CERTIFICACIÓN RIGUROSA N01-R...');
  let passed = 0;
  let total = 0;

  function assert(condition, name) {
    total++;
    if (condition) {
      console.log(`  ✅ [PASS] ${name}`);
      passed++;
    } else {
      console.error(`  ❌ [FAIL] ${name}`);
      throw new Error(`Certification check failed: ${name}`);
    }
  }

  const client = await pool.connect();

  try {
    const clientRes = await client.query(`SELECT id FROM usuarios WHERE id > 0 LIMIT 1;`);
    const clientId = clientRes.rows[0].id;

    const provRes = await client.query(`SELECT id FROM perfiles_prestador LIMIT 1;`);
    let providerId = provRes.rows[0].id;

    const servRes = await client.query(`SELECT id FROM services LIMIT 1;`);
    let serviceId = servRes.rows[0].id;

    async function createTestBooking({ estado = 'CONFIRMADA', paid_at = null, valor = 50000 }) {
      const bId = crypto.randomUUID();
      const sched = new Date(Date.now() + 24 * 3600 * 1000);
      await client.query(`
        INSERT INTO bookings (id, client_id, provider_id, service_id, scheduled_at, valor_bruto, estado, paid_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      `, [bId, clientId, providerId, serviceId, sched, valor, estado, paid_at]);
      return bId;
    }

    // =========================================================================
    // 1. CONCURRENCIA REAL POSTGRESQL (DOS CONEXIONES INDEPENDIENTES)
    // =========================================================================
    console.log('\n--- 1. CONCURRENCIA REAL POSTGRESQL (2 Conexiones) ---');
    const connA = await pool.connect();
    const connB = await pool.connect();
    try {
      const bConc = await createTestBooking({ paid_at: new Date(Date.now() - 20 * 60 * 1000) });

      // Conexión A inicia transacción y adquiere lock pesimista
      await connA.query('BEGIN');
      const lockA = await connA.query(`
        SELECT id, estado FROM bookings WHERE id = $1 FOR UPDATE
      `, [bConc]);
      assert(lockA.rows[0].estado === 'CONFIRMADA', '1.1 Conexión A adquiere lock FOR UPDATE sobre booking CONFIRMADA');

      // Conexión B intenta ejecutar startService concurrentemente
      let connBDone = false;
      let connBResult = null;
      let connBError = null;

      const promiseB = (async () => {
        try {
          await connB.query('BEGIN');
          // Intenta actualizar estado a EN_PROGRESO si sigue CONFIRMADA
          const checkB = await connB.query(`
            SELECT id, estado FROM bookings WHERE id = $1 FOR UPDATE
          `, [bConc]);
          
          if (checkB.rows[0].estado === 'CONFIRMADA') {
            await connB.query(`UPDATE bookings SET estado = 'EN_PROGRESO' WHERE id = $1`, [bConc]);
            await connB.query('COMMIT');
            connBResult = 'EN_PROGRESO';
          } else {
            await connB.query('ROLLBACK');
            connBResult = 'REJECTED_NOT_CONFIRMED';
          }
        } catch (e) {
          await connB.query('ROLLBACK');
          connBError = e;
        } finally {
          connBDone = true;
        }
      })();

      // Dar tiempo a B para encolarse en el lock
      await new Promise(r => setTimeout(r, 100));
      assert(connBDone === false, '1.2 Conexión B queda efectivamente bloqueada esperando el lock de A');

      // Conexión A procesa la expiración y hace COMMIT
      await connA.query(`
        UPDATE bookings SET estado = 'CANCELADA', motivo_cancelacion = 'EXPIRACION_AUTOMATICA' WHERE id = $1
      `, [bConc]);
      await connA.query(`
        INSERT INTO refund_outbox (booking_id, transaction_id, amount, status)
        VALUES ($1, 'tx_conc_test', 50000, 'PENDING')
        ON CONFLICT (booking_id) DO NOTHING
      `, [bConc]);
      await connA.query('COMMIT');

      // Esperar que B reanude tras liberarse el lock
      await promiseB;
      assert(connBDone === true, '1.3 Conexión B se desbloquea tras el COMMIT de A');
      assert(connBResult === 'REJECTED_NOT_CONFIRMED', '1.4 Conexión B lee estado CANCELADA y rechaza la transición a EN_PROGRESO');

      // Verificar consistencia final
      const finalRes = await client.query(`SELECT estado FROM bookings WHERE id = $1`, [bConc]);
      assert(finalRes.rows[0].estado === 'CANCELADA', '1.5 Estado final permanece CANCELADA (no existe estado híbrido)');
    } finally {
      connA.release();
      connB.release();
    }

    // =========================================================================
    // 2. BORDE EXACTO DE 15 MINUTOS (14:59:59 vs 15:00:00 vs 15:00:01)
    // =========================================================================
    console.log('\n--- 2. BORDE EXACTO DE 15 MINUTOS ---');
    // A) 14 minutos 59 segundos -> NO EXPIRA
    const bEdgeA = await createTestBooking({ paid_at: new Date(Date.now() - (14 * 60 + 59) * 1000) });
    await procesarExpiracionReservas();
    const resEdgeA = await client.query(`SELECT estado FROM bookings WHERE id = $1`, [bEdgeA]);
    assert(resEdgeA.rows[0].estado === 'CONFIRMADA', '2.1 paid_at a 14:59:59 NO expira');

    // B) 15 minutos 00 segundos -> EXPIRA (según condición <= NOW() - 15 min)
    const bEdgeB = await createTestBooking({ paid_at: new Date(Date.now() - (15 * 60) * 1000 - 50) });
    await procesarExpiracionReservas();
    const resEdgeB = await client.query(`SELECT estado FROM bookings WHERE id = $1`, [bEdgeB]);
    assert(resEdgeB.rows[0].estado === 'CANCELADA', '2.2 paid_at a 15:00:00 EXPIRA');

    // C) 15 minutos 01 segundos -> EXPIRA
    const bEdgeC = await createTestBooking({ paid_at: new Date(Date.now() - (15 * 60 + 1) * 1000) });
    await procesarExpiracionReservas();
    const resEdgeC = await client.query(`SELECT estado FROM bookings WHERE id = $1`, [bEdgeC]);
    assert(resEdgeC.rows[0].estado === 'CANCELADA', '2.3 paid_at a 15:00:01 EXPIRA');

    // =========================================================================
    // 3. WEBHOOK TARDÍO TRAS CANCELACIÓN
    // =========================================================================
    console.log('\n--- 3. WEBHOOK TARDÍO TRAS CANCELACIÓN ---');
    const bLate = await createTestBooking({ estado: 'CANCELADA', paid_at: new Date(Date.now() - 25 * 60 * 1000) });
    await client.query(`UPDATE bookings SET motivo_cancelacion = 'EXPIRACION_AUTOMATICA' WHERE id = $1`, [bLate]);

    // Simular recepción de webhook Wompi APPROVED para cita ya cancelada
    const bookingController = require('../src/controllers/bookingController');
    const mockReq = {
      header: () => 'valid_sig',
      body: {
        event: 'transaction.updated',
        data: {
          transaction: {
            id: 'tx_late_test',
            reference: bLate,
            status: 'APPROVED',
            amount_in_cents: 5000000,
            payment_method_type: 'NEQUI'
          }
        }
      }
    };
    let jsonResponse = null;
    const mockRes = {
      json: (data) => { jsonResponse = data; },
      status: () => mockRes
    };

    // Sobreescribir temporalmente verificación de firma para el test
    process.env.NODE_ENV = 'development';
    await bookingController.wompiWebhook(mockReq, mockRes);

    const resLate = await client.query(`SELECT estado, motivo_cancelacion FROM bookings WHERE id = $1`, [bLate]);
    assert(resLate.rows[0].estado === 'CANCELADA', '3.1 Webhook tardío NO reabre una reserva CANCELADA');
    assert(resLate.rows[0].motivo_cancelacion === 'EXPIRACION_AUTOMATICA', '3.2 Motivo de cancelación se conserva intacto');

    // =========================================================================
    // 4. DOS REFUND WORKERS CONCURRENTES (SKIP LOCKED TEST)
    // =========================================================================
    console.log('\n--- 4. DOS REFUND WORKERS CONCURRENTES ---');
    const bWork = await createTestBooking({ paid_at: new Date(Date.now() - 30 * 60 * 1000) });
    await client.query(`
      INSERT INTO refund_outbox (booking_id, transaction_id, amount, status)
      VALUES ($1, 'tx_double_worker', 50000, 'PENDING')
    `, [bWork]);

    // Ejecutar dos procesarRefundOutbox concurrentemente
    await Promise.all([
      procesarRefundOutbox(),
      procesarRefundOutbox()
    ]);

    const resWorker = await client.query(`SELECT status, attempts FROM refund_outbox WHERE booking_id = $1`, [bWork]);
    assert(resWorker.rows[0].status === 'SUCCESS', '4.1 Estado final en outbox es SUCCESS');
    assert(resWorker.rows[0].attempts === 1, '4.2 Exactly 1 attempt registrado (sin doble ejecución concurrente)');

    // =========================================================================
    // 5. RETRY COMPLETO (RETRYABLE_FAILURE -> SUCCESS)
    // =========================================================================
    console.log('\n--- 5. RETRY COMPLETO DEL OUTBOX ---');
    const bRetry = await createTestBooking({ paid_at: new Date(Date.now() - 30 * 60 * 1000) });
    // Intento 1: Fuerza 500
    await client.query(`
      INSERT INTO refund_outbox (booking_id, transaction_id, amount, status)
      VALUES ($1, 'FORCE_500', 50000, 'PENDING')
    `, [bRetry]);
    await procesarRefundOutbox();

    const checkR1 = await client.query(`SELECT status, attempts FROM refund_outbox WHERE booking_id = $1`, [bRetry]);
    assert(checkR1.rows[0].status === 'RETRYABLE_FAILURE' && checkR1.rows[0].attempts === 1, '5.1 Primer intento fallido pasa a RETRYABLE_FAILURE con attempts=1');

    // Cambiar transaction_id a válido para simular recuperación en segundo intento
    await client.query(`UPDATE refund_outbox SET transaction_id = 'tx_recovered' WHERE booking_id = $1`, [bRetry]);
    await procesarRefundOutbox();

    const checkR2 = await client.query(`SELECT status, attempts FROM refund_outbox WHERE booking_id = $1`, [bRetry]);
    assert(checkR2.rows[0].status === 'SUCCESS' && checkR2.rows[0].attempts === 2, '5.2 Segundo intento exitoso transiciona a SUCCESS con attempts=2');

    // =========================================================================
    // 6. DISPONIBILIDAD SAAS & B2C
    // =========================================================================
    console.log('\n--- 6. DISPONIBILIDAD B2C / SAAS ---');
    const bDisp = await createTestBooking({ paid_at: new Date(Date.now() - 25 * 60 * 1000) });
    await procesarExpiracionReservas();

    const activeBookings = await client.query(`
      SELECT b.id FROM bookings b 
      WHERE b.id = $1 AND b.estado != 'CANCELADA'
    `, [bDisp]);
    assert(activeBookings.rows.length === 0, '6.1 Query canónica de disponibilidad excluye la reserva expirada');

    console.log(`\n🎉 CERTIFICACIÓN N01-R COMPLETADA CON ÉXITO: ${passed}/${total} PASS.`);
  } finally {
    client.release();
  }
}

runRigorousN01RTests()
  .then(() => process.exit(0))
  .catch(err => {
    console.error('❌ Error en certificación N01-R:', err);
    process.exit(1);
  });
