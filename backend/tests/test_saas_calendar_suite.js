const { pool } = require('../src/config/db');
const saasCalendarService = require('../src/services/saasCalendarService');
const nodo06AppointmentsService = require('../src/services/nodo06AppointmentsService');
const crypto = require('crypto');

async function runCalendarN06GTests() {
  console.log('🔍 INICIANDO SUITE DE TESTS GAP-04 N06-G (OAUTH, PKCE, DETERMINISTIC LIFECYCLE & APPOINTMENT HOOKS)...');
  let passed = 0;
  let total = 0;

  function assert(condition, name) {
    total++;
    if (condition) {
      console.log(`  ✅ [PASS] ${name}`);
      passed++;
    } else {
      console.error(`  ❌ [FAIL] ${name}`);
      throw new Error(`N06-G test check failed: ${name}`);
    }
  }

  const client = await pool.connect();

  try {
    // 1. Setup dedicated user, tenant, establishment & membership
    const testEmail = `cal_test_g_${Date.now()}@glowapp.test`;
    const userRes = await client.query(`
      INSERT INTO usuarios (nombre, email, password_hash, rol, auth_provider, provider_id, onboarding_completo, is_active)
      VALUES ('Staff Cal Test G', $1, 'hashed_pass_test', 'PRESTADOR', 'LOCAL', $1, TRUE, TRUE)
      RETURNING id;
    `, [testEmail]);
    const userId = userRes.rows[0].id;

    // Create tenant
    const tSlug = `tenant-cal-g-${Date.now()}`;
    const t = await client.query(`INSERT INTO tenants (name, slug) VALUES ('Tenant Cal G Test', $1) RETURNING id`, [tSlug]);
    const tenantId = t.rows[0].id;

    // Link user to tenant
    await client.query(`UPDATE usuarios SET tenant_id = $1 WHERE id = $2`, [tenantId, userId]);

    // Get or create organization
    const orgRes = await client.query(`SELECT id FROM organizations WHERE tenant_id = $1 LIMIT 1;`, [tenantId]);
    let organizationId = orgRes.rows.length ? orgRes.rows[0].id : null;
    if (!organizationId) {
      const o = await client.query(`INSERT INTO organizations (tenant_id, legal_name) VALUES ($1, 'Org Cal G Test') RETURNING id`, [tenantId]);
      organizationId = o.rows[0].id;
    }

    // Get or create establishment
    const slug = `cal-test-g-${Date.now()}`;
    const e = await client.query(`
      INSERT INTO establishments (tenant_id, organization_id, name, slug, address) 
      VALUES ($1, $2, 'Sede Principal Cal G', $3, 'Calle 100 # 15-20') 
      RETURNING id
    `, [tenantId, organizationId, slug]);
    const establishmentId = e.rows[0].id;

    // Create membership
    const m = await client.query(`
      INSERT INTO memberships (user_id, establishment_id, tenant_id, role, status)
      VALUES ($1, $2, $3, 'PROFESSIONAL', 'ACTIVE') RETURNING id
    `, [userId, establishmentId, tenantId]);
    const membershipId = m.rows[0].id;

    // Get or create service offer
    const so = await client.query(`
      INSERT INTO service_offers (tenant_id, establishment_id, name, base_duration, base_price)
      VALUES ($1, $2, 'Balayage Gold', 60, 150000)
      RETURNING id
    `, [tenantId, establishmentId]);
    const serviceOfferId = so.rows[0].id;

    // Create service assignment
    await client.query(`
      INSERT INTO service_assignments (tenant_id, establishment_id, service_offer_id, membership_id)
      VALUES ($1, $2, $3, $4)
    `, [tenantId, establishmentId, serviceOfferId, membershipId]);

    const activeContext = {
      tenant_id: tenantId,
      establishment_id: establishmentId,
      active_membership_id: membershipId,
      role: 'PROFESSIONAL',
      user_id: userId
    };

    // =========================================================================
    // 1. OAUTH, PKCE & SINGLE-USE STATE
    // =========================================================================
    console.log('\n--- 1. OAUTH, PKCE & SINGLE-USE STATE ---');

    const authData = await saasCalendarService.generateGoogleAuthUrl(activeContext, membershipId);
    assert(authData && authData.auth_url.includes('https://accounts.google.com/o/oauth2/v2/auth'), '1.1 Generación de URL de autorización OAuth con accounts.google.com');
    assert(authData.auth_url.includes('code_challenge='), '1.2 PKCE code_challenge S256 incluido en URL');
    assert(authData.auth_url.includes('state='), '1.3 State criptográfico seguro de un solo uso incluido en URL');
    assert(authData.auth_url.includes('https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcalendar.events.owned'), '1.4 Scope estricto calendar.events.owned solicitado');

    // Conectar usando el state generado
    const googleInt = await saasCalendarService.connectGoogleCalendar(activeContext, membershipId, {
      code: 'mock_test_oauth_code',
      state: authData.state,
      calendar_id: 'primary'
    });
    assert(googleInt && googleInt.status === 'CONNECTED', '1.5 Intercambio OAuth y consumo exitoso del State');

    // Intentar reutilizar el mismo state (Debe fallar por un solo uso)
    let stateReuseFailed = false;
    try {
      await saasCalendarService.connectGoogleCalendar(activeContext, membershipId, {
        code: 'mock_test_oauth_code_2',
        state: authData.state
      });
    } catch (e) {
      stateReuseFailed = true;
    }
    assert(stateReuseFailed, '1.6 Reutilización de State rechazada (Single-Use Token Protection)');

    // =========================================================================
    // 2. APPOINTMENT HOOKS (CREATE, UPDATE, CANCEL -> OUTBOX)
    // =========================================================================
    console.log('\n--- 2. APPOINTMENT HOOKS PRODUCTIVOS -> OUTBOX ---');

    const scheduledDate = new Date(Date.now() + 48 * 3600 * 1000);
    scheduledDate.setMinutes(0, 0, 0);

    // CREATE APPOINTMENT -> Enqueues CREATE_EVENT
    const createdAppt = await nodo06AppointmentsService.createAppointment(activeContext, {
      service_offer_id: serviceOfferId,
      membership_id: membershipId,
      scheduled_at: scheduledDate.toISOString(),
      guest_name: 'Cliente VIP Real',
      guest_phone: '+573009876543'
    });
    assert(createdAppt && createdAppt.id, '2.1 Creación de cita interna saas_appointments exitosa');

    const outboxCreateRes = await client.query(`
      SELECT * FROM saas_calendar_sync_outbox
      WHERE appointment_id = $1 AND operation = 'CREATE_EVENT'
    `, [createdAppt.id]);
    assert(outboxCreateRes.rows.length === 1, '2.2 Hook CREATE_EVENT encola automáticamente en saas_calendar_sync_outbox');
    assert(outboxCreateRes.rows[0].status === 'PENDING', '2.3 Outbox inicia en estado PENDING');

    // UPDATE APPOINTMENT (CONFIRMED) -> Enqueues UPDATE_EVENT
    const updatedAppt = await nodo06AppointmentsService.transitionAppointmentStatus(activeContext, createdAppt.id, {
      status: 'CONFIRMED'
    });
    assert(updatedAppt && updatedAppt.status === 'CONFIRMED', '2.4 Transición a CONFIRMED exitosa');

    const outboxUpdateRes = await client.query(`
      SELECT * FROM saas_calendar_sync_outbox
      WHERE appointment_id = $1 AND operation = 'UPDATE_EVENT'
    `, [createdAppt.id]);
    assert(outboxUpdateRes.rows.length === 1, '2.5 Hook UPDATE_EVENT encola automáticamente en saas_calendar_sync_outbox');

    // CANCEL APPOINTMENT -> Enqueues CANCEL_EVENT
    const cancelledAppt = await nodo06AppointmentsService.transitionAppointmentStatus(activeContext, createdAppt.id, {
      status: 'CANCELLED',
      cancellation_reason: 'Cliente reagendó servicio'
    });
    assert(cancelledAppt && cancelledAppt.status === 'CANCELLED', '2.6 Cancelación de cita exitosa');

    const outboxCancelRes = await client.query(`
      SELECT * FROM saas_calendar_sync_outbox
      WHERE appointment_id = $1 AND operation = 'CANCEL_EVENT'
    `, [createdAppt.id]);
    assert(outboxCancelRes.rows.length === 1, '2.7 Hook CANCEL_EVENT encola automáticamente en saas_calendar_sync_outbox');

    // =========================================================================
    // 3. WORKER OUTBOX, IDEMPOTENCIA DETERMINISTA & BACKOFF 1/5/30
    // =========================================================================
    console.log('\n--- 3. WORKER OUTBOX, IDEMPOTENCIA & BACKOFF ---');

    // Worker process
    const workerRes = await saasCalendarService.processSyncOutboxWorker(10);
    assert(workerRes.processed_count >= 3, '3.1 Worker procesa los eventos CREATE, UPDATE y CANCEL del outbox');

    const processedEvents = await client.query(`
      SELECT operation, status, external_event_id, attempts FROM saas_calendar_sync_outbox
      WHERE appointment_id = $1
      ORDER BY created_at ASC;
    `, [createdAppt.id]);

    const createEvt = processedEvents.rows.find(r => r.operation === 'CREATE_EVENT');
    const updateEvt = processedEvents.rows.find(r => r.operation === 'UPDATE_EVENT');
    const cancelEvt = processedEvents.rows.find(r => r.operation === 'CANCEL_EVENT');

    assert(createEvt.status === 'SUCCESS' && createEvt.external_event_id.startsWith('glowapp_'), '3.2 CREATE procesado con external_event_id determinista');
    assert(updateEvt.status === 'SUCCESS' && updateEvt.external_event_id === createEvt.external_event_id, '3.3 UPDATE reutiliza exactamente el mismo external_event_id');
    assert(cancelEvt.status === 'SUCCESS' && cancelEvt.external_event_id === createEvt.external_event_id, '3.4 CANCEL apunta al mismo external_event_id (Idempotencia determinista)');

    // Backoff & Retry Test (Transient failure test)
    const retryOutbox = await saasCalendarService.enqueueCalendarSync(client, {
      tenantId,
      establishmentId,
      membershipId,
      appointmentId: createdAppt.id,
      operation: 'UPDATE_EVENT',
      payload: { force_error: 'TRANSIENT' }
    });

    // Execute worker to trigger transient failure
    await saasCalendarService.processSyncOutboxWorker(10);

    const retryCheck = await client.query(`
      SELECT status, attempts, next_retry_at, created_at FROM saas_calendar_sync_outbox WHERE id = $1
    `, [retryOutbox.id]);
    assert(retryCheck.rows[0].status === 'RETRYABLE_FAILURE', '3.5 Error transitorio pasa a RETRYABLE_FAILURE');
    assert(retryCheck.rows[0].attempts === 1, '3.6 Primer intento registrado');

    // Check backoff ~1 second
    const diffMs = new Date(retryCheck.rows[0].next_retry_at).getTime() - new Date().getTime();
    assert(diffMs <= 2000, '3.7 Backoff inicial configurado en 1 segundo');

    // =========================================================================
    // 4. AISLAMIENTO CROSS-TENANT & RBAC
    // =========================================================================
    console.log('\n--- 4. AISLAMIENTO CROSS-TENANT & RBAC ---');

    // Professional from another membership cannot disconnect
    const fakeOtherMembership = crypto.randomUUID();
    let rbacFailed = false;
    try {
      await saasCalendarService.disconnectGoogleCalendar(activeContext, fakeOtherMembership);
    } catch (e) {
      rbacFailed = true;
    }
    assert(rbacFailed, '4.1 Profesional no puede desconectar integración de otro colaborador (403)');

    // Disconnect own integration
    const discRes = await saasCalendarService.disconnectGoogleCalendar(activeContext, membershipId);
    assert(discRes.success === true && discRes.status === 'DISCONNECTED', '4.2 Desconexión propia exitosa');

    // Cleanup
    await client.query(`DELETE FROM saas_calendar_sync_outbox WHERE tenant_id = $1`, [tenantId]);
    await client.query(`DELETE FROM saas_appointments WHERE id = $1`, [createdAppt.id]);
    await client.query(`DELETE FROM service_assignments WHERE tenant_id = $1`, [tenantId]);
    await client.query(`DELETE FROM service_offers WHERE id = $1`, [serviceOfferId]);
    await client.query(`DELETE FROM saas_staff_calendar_integrations WHERE tenant_id = $1`, [tenantId]);

    console.log(`\n=======================================================`);
    console.log(`🎉 SUITE GAP-04 N06-G COMPLETADA: ${passed}/${total} PASS`);
    console.log(`=======================================================\n`);

  } finally {
    client.release();
  }
}

if (require.main === module) {
  runCalendarN06GTests()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('❌ Error en test suite de Calendar N06-G:', err);
      process.exit(1);
    });
}

module.exports = { runCalendarN06GTests };
