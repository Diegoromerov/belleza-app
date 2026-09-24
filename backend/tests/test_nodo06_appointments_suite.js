// backend/tests/test_nodo06_appointments_suite.js
const assert = require('assert');
const { pool } = require('../src/config/db');
const nodo06AppointmentsService = require('../src/services/nodo06AppointmentsService');
const nodo06AppointmentsController = require('../src/controllers/nodo06AppointmentsController');

function createMockReqRes(options = {}) {
  const req = {
    user: options.user !== undefined ? options.user : { id: 7, email: 'demo@beautyapp.com' },
    headers: options.headers || {},
    body: options.body || {},
    query: options.query || {},
    params: options.params || {},
    tenantId: options.tenantId !== undefined ? options.tenantId : 2,
    establishmentId: options.establishmentId || null,
    membershipId: options.membershipId || null,
    activeContext: options.activeContext || null,
    ...options.extraReq,
  };

  let statusCode = 200;
  let jsonBody = null;

  const res = {
    status(code) {
      statusCode = code;
      return this;
    },
    json(data) {
      jsonBody = data;
      return this;
    },
    getStatusCode() {
      return statusCode;
    },
    getBody() {
      return jsonBody;
    },
  };

  return { req, res };
}

async function runNodo06Suite() {
  console.log('================================================================================');
  console.log('       NODO-06 — SAAS APPOINTMENTS & OPERATIONAL AGENDA ENGINE TEST SUITE');
  console.log('================================================================================\n');

  let passed = 0;
  let failed = 0;

  async function test(name, fn) {
    try {
      await fn();
      console.log(`  ✓ PASS: ${name}`);
      passed++;
    } catch (err) {
      console.error(`  ✗ FAIL: ${name}`);
      console.error(`    Error: ${err.message}`);
      if (err.stack) console.error(`    Stack: ${err.stack.split('\n')[1]}`);
      failed++;
    }
  }

  // Configuración de fixtures de prueba bajo Tenant 2
  const tenantId = 2;
  let establishmentId = null;
  let serviceOfferId1 = null;
  let serviceOfferId2 = null;
  let ownerMembershipId = null;
  let profMembershipId1 = null;
  let profMembershipId2 = null;
  let inactiveProfMembershipId = null;
  let customerUserId = 7;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', '2', true);");

    // 1. Obtener Sede activa de Tenant 2
    const estRes = await client.query(`
      SELECT id FROM establishments WHERE tenant_id = $1 LIMIT 1;
    `, [tenantId]);
    assert(estRes.rows.length > 0, 'Must have at least one establishment in tenant 2');
    establishmentId = estRes.rows[0].id;

    // 2. Crear / Obtener Membresía OWNER
    const ownerRes = await client.query(`
      SELECT id FROM memberships 
      WHERE tenant_id = $1 AND establishment_id = $2 AND role = 'OWNER' AND status = 'ACTIVE'
      LIMIT 1;
    `, [tenantId, establishmentId]);
    if (ownerRes.rows.length > 0) {
      ownerMembershipId = ownerRes.rows[0].id;
    } else {
      const newOwner = await client.query(`
        INSERT INTO memberships (tenant_id, establishment_id, user_id, role, status)
        VALUES ($1, $2, $3, 'OWNER', 'ACTIVE')
        RETURNING id;
      `, [tenantId, establishmentId, customerUserId]);
      ownerMembershipId = newOwner.rows[0].id;
    }

    // 3. Crear / Obtener dos profesionales activos
    const p1UserRes = await client.query(`
      INSERT INTO usuarios (email, nombre, rol, tenant_id, auth_provider, provider_id, password_hash)
      VALUES ('nodo06_prof1@beautyapp.com', 'NODO-06 Prof One', 'PRESTADOR', 2, 'LOCAL', 'nodo06-prof1-loc', 'hash')
      ON CONFLICT (email) DO UPDATE SET is_active = true
      RETURNING id;
    `);
    const p1UserId = p1UserRes.rows[0].id;

    const p1Mem = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, status)
      VALUES ($1, $2, $3, 'PROFESSIONAL', 'ACTIVE')
      ON CONFLICT (establishment_id, user_id) DO UPDATE SET status = 'ACTIVE', role = 'PROFESSIONAL'
      RETURNING id;
    `, [tenantId, establishmentId, p1UserId]);
    profMembershipId1 = p1Mem.rows[0].id;

    const p2UserRes = await client.query(`
      INSERT INTO usuarios (email, nombre, rol, tenant_id, auth_provider, provider_id, password_hash)
      VALUES ('nodo06_prof2@beautyapp.com', 'NODO-06 Prof Two', 'PRESTADOR', 2, 'LOCAL', 'nodo06-prof2-loc', 'hash')
      ON CONFLICT (email) DO UPDATE SET is_active = true
      RETURNING id;
    `);
    const p2UserId = p2UserRes.rows[0].id;

    const p2Mem = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, status)
      VALUES ($1, $2, $3, 'PROFESSIONAL', 'ACTIVE')
      ON CONFLICT (establishment_id, user_id) DO UPDATE SET status = 'ACTIVE', role = 'PROFESSIONAL'
      RETURNING id;
    `, [tenantId, establishmentId, p2UserId]);
    profMembershipId2 = p2Mem.rows[0].id;

    // Membresía Inactiva para pruebas
    const inactUserRes = await client.query(`
      INSERT INTO usuarios (email, nombre, rol, tenant_id, auth_provider, provider_id, password_hash)
      VALUES ('nodo06_inact@beautyapp.com', 'NODO-06 Inactive Prof', 'PRESTADOR', 2, 'LOCAL', 'nodo06-inact-loc', 'hash')
      ON CONFLICT (email) DO UPDATE SET is_active = true
      RETURNING id;
    `);
    const inactUserId = inactUserRes.rows[0].id;

    const inactMem = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, status)
      VALUES ($1, $2, $3, 'PROFESSIONAL', 'SUSPENDED')
      ON CONFLICT (establishment_id, user_id) DO UPDATE SET status = 'SUSPENDED', role = 'PROFESSIONAL'
      RETURNING id;
    `, [tenantId, establishmentId, inactUserId]);
    inactiveProfMembershipId = inactMem.rows[0].id;

    // 4. Crear Ofertas de Servicio
    const so1 = await client.query(`
      INSERT INTO service_offers (tenant_id, establishment_id, name, description, base_duration, base_price)
      VALUES ($1, $2, 'N06 Corte Master', 'Corte Premium', 45, 55000.00)
      RETURNING id;
    `, [tenantId, establishmentId]);
    serviceOfferId1 = so1.rows[0].id;

    const so2 = await client.query(`
      INSERT INTO service_offers (tenant_id, establishment_id, name, description, base_duration, base_price)
      VALUES ($1, $2, 'N06 Barba Express', 'Arreglo de barba', 30, 30000.00)
      RETURNING id;
    `, [tenantId, establishmentId]);
    serviceOfferId2 = so2.rows[0].id;

    // 5. Asignar Oferta 1 a Prof 1 y Oferta 2 a Prof 2
    await client.query(`
      INSERT INTO service_assignments (tenant_id, establishment_id, service_offer_id, membership_id)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (service_offer_id, membership_id) DO NOTHING;
    `, [tenantId, establishmentId, serviceOfferId1, profMembershipId1]);

    await client.query(`
      INSERT INTO service_assignments (tenant_id, establishment_id, service_offer_id, membership_id)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (service_offer_id, membership_id) DO NOTHING;
    `, [tenantId, establishmentId, serviceOfferId2, profMembershipId2]);

    // 6. Horarios de Personal para Proyección de Agenda (Martes = 2)
    await client.query(`
      INSERT INTO staff_schedules (tenant_id, establishment_id, membership_id, day_of_week, start_time, end_time)
      VALUES ($1, $2, $3, 2, '08:00:00', '13:00:00')
      ON CONFLICT (establishment_id, membership_id, day_of_week, start_time) DO NOTHING;
    `, [tenantId, establishmentId, profMembershipId1]);

    await client.query(`
      INSERT INTO staff_schedules (tenant_id, establishment_id, membership_id, day_of_week, start_time, end_time)
      VALUES ($1, $2, $3, 2, '14:00:00', '18:00:00')
      ON CONFLICT (establishment_id, membership_id, day_of_week, start_time) DO NOTHING;
    `, [tenantId, establishmentId, profMembershipId1]);

    // Limpiar citas anteriores de prueba
    await client.query(`DELETE FROM saas_appointments WHERE establishment_id = $1;`, [establishmentId]);

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }

  const activeContextOwner = {
    tenantId,
    establishmentId,
    membershipId: ownerMembershipId,
    role: 'OWNER'
  };

  const activeContextProf1 = {
    tenantId,
    establishmentId,
    membershipId: profMembershipId1,
    role: 'PROFESSIONAL'
  };

  const activeContextProf2 = {
    tenantId,
    establishmentId,
    membershipId: profMembershipId2,
    role: 'PROFESSIONAL'
  };

  const activeContextInactive = {
    tenantId,
    establishmentId,
    membershipId: inactiveProfMembershipId,
    role: 'PROFESSIONAL'
  };

  // ================================================================================
  // PRUEBAS DE CREACIÓN Y VALIDACIÓN (N06-DEC-01 a N06-DEC-09)
  // ================================================================================

  let createdAppt1Id = null;

  await test('1. Creación exitosa de Appointment para Cliente Registrado con Snapshot', async () => {
    const res = await nodo06AppointmentsService.createAppointment(activeContextOwner, {
      service_offer_id: serviceOfferId1,
      membership_id: profMembershipId1,
      scheduled_at: '2026-09-15T09:00:00-05:00',
      customer_user_id: customerUserId
    });

    assert.strictEqual(res.status, 'SCHEDULED');
    assert.strictEqual(res.client_mode, 'REGISTERED');
    assert.strictEqual(res.customer_user_id, customerUserId);
    assert.strictEqual(res.guest_name, null);
    assert.strictEqual(res.service_name_snapshot, 'N06 Corte Master');
    assert.strictEqual(res.duration_minutes_snapshot, 45);
    assert.strictEqual(res.price_snapshot, '55000.00');
    assert.strictEqual(res.scheduled_at, '2026-09-15T09:00:00-05:00');
    assert.strictEqual(res.end_time, '2026-09-15T09:45:00-05:00');
    createdAppt1Id = res.id;
  });

  await test('2. Creación exitosa de Appointment para Cliente Invitado (Guest)', async () => {
    const res = await nodo06AppointmentsService.createAppointment(activeContextOwner, {
      service_offer_id: serviceOfferId2,
      membership_id: profMembershipId2,
      scheduled_at: '2026-09-15T10:00:00-05:00',
      guest_name: 'Camila Rodriguez',
      guest_phone: '+573001234567',
      guest_email: 'camila@guest.com'
    });

    assert.strictEqual(res.status, 'SCHEDULED');
    assert.strictEqual(res.client_mode, 'GUEST');
    assert.strictEqual(res.customer_user_id, null);
    assert.strictEqual(res.guest_name, 'Camila Rodriguez');
    assert.strictEqual(res.guest_phone, '+573001234567');
    assert.strictEqual(res.duration_minutes_snapshot, 30);
    assert.strictEqual(res.end_time, '2026-09-15T10:30:00-05:00');
  });

  await test('3. Rechazo por conflicto XOR (Registrado con campos Guest)', async () => {
    try {
      await nodo06AppointmentsService.createAppointment(activeContextOwner, {
        service_offer_id: serviceOfferId1,
        membership_id: profMembershipId1,
        scheduled_at: '2026-09-15T11:00:00-05:00',
        customer_user_id: customerUserId,
        guest_name: 'Invalido'
      });
      assert.fail('Should have failed with INVALID_CLIENT_IDENTITY_MODE');
    } catch (err) {
      assert.strictEqual(err.code, 'INVALID_CLIENT_IDENTITY_MODE');
      assert.strictEqual(err.status, 400);
    }
  });

  await test('4. Rechazo por Guest inválido (sin teléfono o nombre corto)', async () => {
    try {
      await nodo06AppointmentsService.createAppointment(activeContextOwner, {
        service_offer_id: serviceOfferId1,
        membership_id: profMembershipId1,
        scheduled_at: '2026-09-15T11:00:00-05:00',
        guest_name: 'A',
        guest_phone: '123'
      });
      assert.fail('Should have failed with INVALID_CLIENT_IDENTITY_MODE');
    } catch (err) {
      assert.strictEqual(err.code, 'INVALID_CLIENT_IDENTITY_MODE');
      assert.strictEqual(err.status, 400);
    }
  });

  await test('5. Rechazo por formato timestamp inválido', async () => {
    try {
      await nodo06AppointmentsService.createAppointment(activeContextOwner, {
        service_offer_id: serviceOfferId1,
        membership_id: profMembershipId1,
        scheduled_at: 'invalid-date-string',
        customer_user_id: customerUserId
      });
      assert.fail('Should have failed with INVALID_TIME_FORMAT');
    } catch (err) {
      assert.strictEqual(err.code, 'INVALID_TIME_FORMAT');
      assert.strictEqual(err.status, 400);
    }
  });

  await test('6. Rechazo por Oferta de Servicio no encontrada (404)', async () => {
    try {
      await nodo06AppointmentsService.createAppointment(activeContextOwner, {
        service_offer_id: '00000000-0000-0000-0000-000000000000',
        membership_id: profMembershipId1,
        scheduled_at: '2026-09-15T11:00:00-05:00',
        customer_user_id: customerUserId
      });
      assert.fail('Should have failed with SERVICE_OFFER_NOT_FOUND');
    } catch (err) {
      assert.strictEqual(err.code, 'SERVICE_OFFER_NOT_FOUND');
      assert.strictEqual(err.status, 404);
    }
  });

  await test('7. Rechazo por Membresía Inactiva en creación (422)', async () => {
    try {
      await nodo06AppointmentsService.createAppointment(activeContextOwner, {
        service_offer_id: serviceOfferId1,
        membership_id: inactiveProfMembershipId,
        scheduled_at: '2026-09-15T11:00:00-05:00',
        customer_user_id: customerUserId
      });
      assert.fail('Should have failed with INACTIVE_MEMBERSHIP');
    } catch (err) {
      assert.strictEqual(err.code, 'INACTIVE_MEMBERSHIP');
      assert.strictEqual(err.status, 422);
    }
  });

  await test('8. Rechazo por Profesional no asignado al Servicio (422)', async () => {
    try {
      // Prof 1 intentando crear Oferta 2 (solo asignada a Prof 2)
      await nodo06AppointmentsService.createAppointment(activeContextOwner, {
        service_offer_id: serviceOfferId2,
        membership_id: profMembershipId1,
        scheduled_at: '2026-09-15T11:00:00-05:00',
        customer_user_id: customerUserId
      });
      assert.fail('Should have failed with INVALID_SERVICE_ASSIGNMENT');
    } catch (err) {
      assert.strictEqual(err.code, 'INVALID_SERVICE_ASSIGNMENT');
      assert.strictEqual(err.status, 422);
    }
  });

  await test('9. Concurrencia Intra-SaaS: Exclusión mutua GiST sobre mismo slot (409)', async () => {
    // Intentar agendar en [09:15, 10:00), el cual colisiona con Appt 1 [09:00, 09:45)
    try {
      await nodo06AppointmentsService.createAppointment(activeContextOwner, {
        service_offer_id: serviceOfferId1,
        membership_id: profMembershipId1,
        scheduled_at: '2026-09-15T09:15:00-05:00',
        customer_user_id: customerUserId
      });
      assert.fail('Should have failed with APPOINTMENT_OCCUPANCY_COLLISION');
    } catch (err) {
      assert.strictEqual(err.code, 'APPOINTMENT_OCCUPANCY_COLLISION');
      assert.strictEqual(err.status, 409);
    }
  });

  await test('10. Concurrencia: Slot adyacente exacto exitoso sin colisión', async () => {
    // Appt 1 termina a las 09:45:00. Agendar exactamente a las 09:45:00 debe tener éxito
    const res = await nodo06AppointmentsService.createAppointment(activeContextOwner, {
      service_offer_id: serviceOfferId1,
      membership_id: profMembershipId1,
      scheduled_at: '2026-09-15T09:45:00-05:00',
      customer_user_id: customerUserId
    });

    assert.strictEqual(res.scheduled_at, '2026-09-15T09:45:00-05:00');
    assert.strictEqual(res.end_time, '2026-09-15T10:30:00-05:00');
  });

  await test('11. Control de Acceso: Professional intentando agendar para otro profesional (403)', async () => {
    try {
      // Prof 1 intenta agendar cita para Prof 2
      await nodo06AppointmentsService.createAppointment(activeContextProf1, {
        service_offer_id: serviceOfferId2,
        membership_id: profMembershipId2,
        scheduled_at: '2026-09-15T12:00:00-05:00',
        customer_user_id: customerUserId
      });
      assert.fail('Should have failed with UNAUTHORIZED_ROLE');
    } catch (err) {
      assert.strictEqual(err.code, 'UNAUTHORIZED_ROLE');
      assert.strictEqual(err.status, 403);
    }
  });

  // ================================================================================
  // PRUEBAS DE MÁQUINA DE ESTADOS (N06-DEC-05)
  // ================================================================================

  let testLifeCycleApptId = null;

  await test('12. Ciclo de Vida Completo: SCHEDULED -> CONFIRMED -> CHECKED_IN -> IN_SERVICE -> COMPLETED', async () => {
    const created = await nodo06AppointmentsService.createAppointment(activeContextProf1, {
      service_offer_id: serviceOfferId1,
      membership_id: profMembershipId1,
      scheduled_at: '2026-09-15T14:00:00-05:00',
      customer_user_id: customerUserId
    });
    testLifeCycleApptId = created.id;

    // 1. confirm
    const conf = await nodo06AppointmentsService.transitionAppointmentStatus(activeContextProf1, testLifeCycleApptId, {
      status: 'CONFIRMED'
    });
    assert.strictEqual(conf.status, 'CONFIRMED');

    // 2. check_in
    const check = await nodo06AppointmentsService.transitionAppointmentStatus(activeContextProf1, testLifeCycleApptId, {
      status: 'CHECKED_IN'
    });
    assert.strictEqual(check.status, 'CHECKED_IN');

    // 3. start_service
    const inSvc = await nodo06AppointmentsService.transitionAppointmentStatus(activeContextProf1, testLifeCycleApptId, {
      status: 'IN_SERVICE'
    });
    assert.strictEqual(inSvc.status, 'IN_SERVICE');

    // 4. complete
    const comp = await nodo06AppointmentsService.transitionAppointmentStatus(activeContextProf1, testLifeCycleApptId, {
      status: 'COMPLETED'
    });
    assert.strictEqual(comp.status, 'COMPLETED');
  });

  await test('13. Estado Terminal Inmutable: Intentar transicionar cita COMPLETED (422)', async () => {
    try {
      await nodo06AppointmentsService.transitionAppointmentStatus(activeContextProf1, testLifeCycleApptId, {
        status: 'CANCELLED'
      });
      assert.fail('Should have failed with INVALID_STATE_TRANSITION');
    } catch (err) {
      assert.strictEqual(err.code, 'INVALID_STATE_TRANSITION');
      assert.strictEqual(err.status, 422);
    }
  });

  await test('14. Regla 10: CHECKED_IN -> NO_SHOW prohibido (422)', async () => {
    const appt = await nodo06AppointmentsService.createAppointment(activeContextProf1, {
      service_offer_id: serviceOfferId1,
      membership_id: profMembershipId1,
      scheduled_at: '2026-09-15T15:00:00-05:00',
      customer_user_id: customerUserId
    });
    await nodo06AppointmentsService.transitionAppointmentStatus(activeContextProf1, appt.id, { status: 'CHECKED_IN' });

    try {
      await nodo06AppointmentsService.transitionAppointmentStatus(activeContextProf1, appt.id, { status: 'NO_SHOW' });
      assert.fail('Should have failed with INVALID_STATE_TRANSITION');
    } catch (err) {
      assert.strictEqual(err.code, 'INVALID_STATE_TRANSITION');
      assert.strictEqual(err.status, 422);
    }
  });

  await test('15. Regla 12: IN_SERVICE -> CANCELLED exige cancellation_reason (422)', async () => {
    const appt = await nodo06AppointmentsService.createAppointment(activeContextProf1, {
      service_offer_id: serviceOfferId1,
      membership_id: profMembershipId1,
      scheduled_at: '2026-09-15T16:00:00-05:00',
      customer_user_id: customerUserId
    });
    await nodo06AppointmentsService.transitionAppointmentStatus(activeContextProf1, appt.id, { status: 'CHECKED_IN' });
    await nodo06AppointmentsService.transitionAppointmentStatus(activeContextProf1, appt.id, { status: 'IN_SERVICE' });

    // Intento sin motivo
    try {
      await nodo06AppointmentsService.transitionAppointmentStatus(activeContextProf1, appt.id, { status: 'CANCELLED' });
      assert.fail('Should have failed with CANCELLATION_REASON_REQUIRED');
    } catch (err) {
      assert.strictEqual(err.code, 'CANCELLATION_REASON_REQUIRED');
      assert.strictEqual(err.status, 422);
    }

    // Cancelación con motivo válido
    const cancelled = await nodo06AppointmentsService.transitionAppointmentStatus(activeContextProf1, appt.id, {
      status: 'CANCELLED',
      cancellation_reason: 'Corte de energía eléctrica en la cabina'
    });
    assert.strictEqual(cancelled.status, 'CANCELLED');
    assert.strictEqual(cancelled.cancellation_reason, 'Corte de energía eléctrica en la cabina');
  });

  await test('16. Liberación de Slot: Cita CANCELLED libera la franja en el índice GiST', async () => {
    // Reagendar exactamente en la franja liberada [16:00, 16:45)
    const newAppt = await nodo06AppointmentsService.createAppointment(activeContextProf1, {
      service_offer_id: serviceOfferId1,
      membership_id: profMembershipId1,
      scheduled_at: '2026-09-15T16:00:00-05:00',
      customer_user_id: customerUserId
    });
    assert.strictEqual(newAppt.status, 'SCHEDULED');
  });

  await test('17. Membresía Inactiva intentando ejecutar transiciones bloqueada (422)', async () => {
    // Si la llamada la realiza una membresía suspendida
    try {
      await nodo06AppointmentsService.transitionAppointmentStatus(activeContextInactive, createdAppt1Id, {
        status: 'CONFIRMED'
      });
      assert.fail('Should have failed with INACTIVE_MEMBERSHIP_CANNOT_EXECUTE');
    } catch (err) {
      assert.strictEqual(err.code, 'INACTIVE_MEMBERSHIP_CANNOT_EXECUTE');
      assert.strictEqual(err.status, 422);
    }
  });

  // ================================================================================
  // PRUEBAS DE PROYECCIÓN DE AGENDA OPERATIVA (N06-DEC-04)
  // ================================================================================

  await test('18. Proyección de Agenda Diaria de Sede (AgendaProjectionResponseDTO)', async () => {
    const agenda = await nodo06AppointmentsService.getAgendaProjection(activeContextOwner, {
      target_date: '2026-09-15'
    });

    assert.strictEqual(agenda.establishment_id, establishmentId);
    assert.strictEqual(agenda.target_date, '2026-09-15');
    assert.strictEqual(agenda.timezone, 'America/Bogota');
    assert(Array.isArray(agenda.professionals), 'Must return array of professionals');
    assert(agenda.professionals.length >= 2, 'Must include active professionals');

    const prof1Agenda = agenda.professionals.find(p => p.membership_id === profMembershipId1);
    assert(prof1Agenda !== undefined, 'Must find Prof 1 in agenda');
    assert(Array.isArray(prof1Agenda.shifts), 'Must have shifts array');
    assert(Array.isArray(prof1Agenda.appointments), 'Must have appointments array');
    assert(prof1Agenda.appointments.length >= 1, 'Prof 1 must have appointments');
  });

  await test('19. Proyección de Agenda filtrada por Professional Role (solo propias)', async () => {
    const agenda = await nodo06AppointmentsService.getAgendaProjection(activeContextProf1, {
      target_date: '2026-09-15'
    });

    assert.strictEqual(agenda.professionals.length, 1);
    assert.strictEqual(agenda.professionals[0].membership_id, profMembershipId1);
  });

  // ================================================================================
  // PRUEBAS DE INTEGRACIÓN DE CONTROLLER HTTP
  // ================================================================================

  await test('20. Controller HTTP: createAppointment 201 Response', async () => {
    const { req, res } = createMockReqRes({
      activeContext: activeContextOwner,
      body: {
        service_offer_id: serviceOfferId1,
        membership_id: profMembershipId1,
        scheduled_at: '2026-09-15T17:00:00-05:00',
        customer_user_id: customerUserId
      }
    });

    await nodo06AppointmentsController.createAppointment(req, res);
    assert.strictEqual(res.getStatusCode(), 201);
    const body = res.getBody();
    assert.strictEqual(body.status, 'SCHEDULED');
    assert.strictEqual(body.service_name_snapshot, 'N06 Corte Master');
  });

  await test('21. Controller HTTP: getAppointmentById 200 Response', async () => {
    const { req, res } = createMockReqRes({
      activeContext: activeContextOwner,
      params: { id: createdAppt1Id }
    });

    await nodo06AppointmentsController.getAppointmentById(req, res);
    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert.strictEqual(body.id, createdAppt1Id);
  });

  await test('22. Controller HTTP: Error estructurado 409 APPOINTMENT_OCCUPANCY_COLLISION', async () => {
    const { req, res } = createMockReqRes({
      activeContext: activeContextOwner,
      body: {
        service_offer_id: serviceOfferId1,
        membership_id: profMembershipId1,
        scheduled_at: '2026-09-15T17:15:00-05:00', // solapa con 17:00
        customer_user_id: customerUserId
      }
    });

    await nodo06AppointmentsController.createAppointment(req, res);
    assert.strictEqual(res.getStatusCode(), 409);
    const body = res.getBody();
    assert.strictEqual(body.error.code, 'APPOINTMENT_OCCUPANCY_COLLISION');
  });

  await test('23. Controller HTTP: Error estructurado 404 APPOINTMENT_NOT_FOUND', async () => {
    const { req, res } = createMockReqRes({
      activeContext: activeContextOwner,
      params: { id: '00000000-0000-0000-0000-000000000000' }
    });

    await nodo06AppointmentsController.getAppointmentById(req, res);
    assert.strictEqual(res.getStatusCode(), 404);
    const body = res.getBody();
    assert.strictEqual(body.error.code, 'APPOINTMENT_NOT_FOUND');
  });

  await test('24. Controller HTTP: Error estructurado 403 UNAUTHORIZED_ROLE sin Active Context', async () => {
    const { req, res } = createMockReqRes({
      activeContext: null
    });

    await nodo06AppointmentsController.createAppointment(req, res);
    assert.strictEqual(res.getStatusCode(), 403);
    const body = res.getBody();
    assert.strictEqual(body.error.code, 'UNAUTHORIZED_ROLE');
  });

  await test('25. Controller HTTP: getAgendaProjection 200 Response', async () => {
    const { req, res } = createMockReqRes({
      activeContext: activeContextOwner,
      query: { target_date: '2026-09-15' }
    });

    await nodo06AppointmentsController.getAgendaProjection(req, res);
    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert.strictEqual(body.timezone, 'America/Bogota');
    assert(Array.isArray(body.professionals));
  });

  console.log(`\n================================================================================`);
  console.log(`TOTAL TESTS: ${passed + failed} | PASSED: ${passed} | FAILED: ${failed}`);
  console.log(`================================================================================\n`);

  if (failed > 0) {
    process.exit(1);
  }
}

if (require.main === module) {
  runNodo06Suite()
    .then(() => pool.end())
    .catch((err) => {
      console.error('Fatal error running suite:', err);
      pool.end();
      process.exit(1);
    });
}

module.exports = { runNodo06Suite };
