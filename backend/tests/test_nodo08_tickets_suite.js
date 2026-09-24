// backend/tests/test_nodo08_tickets_suite.js
const assert = require('assert');
const { pool } = require('../src/config/db');
const nodo08TicketsService = require('../src/services/nodo08TicketsService');
const nodo08TicketsController = require('../src/controllers/nodo08TicketsController');

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

async function runNodo08Suite() {
  console.log('================================================================================');
  console.log('       NODO-08 — SAAS SERVICE TICKET & FINANCIAL CHECKOUT ENGINE TEST SUITE');
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
      console.error(err);
      if (err.stack) console.error(`    Stack: ${err.stack}`);
      failed++;
    }
  }

  // Setup fixtures in Tenant 2
  const tenantId = 2;
  let establishmentId = null;
  let serviceOfferId1 = null;
  let serviceOfferId2 = null;
  let ownerMembershipId = null;
  let managerMembershipId = null;
  let receptionistMembershipId = null;
  let profMembershipId1 = null;
  let profMembershipId2 = null;
  let inactiveProfMembershipId = null;
  let customerUserId = 7;
  let appointmentInServiceId = null;
  let appointmentScheduledId = null;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', '2', true);");

    // 1. Establishment
    const estRes = await client.query('SELECT id FROM establishments WHERE tenant_id = $1 LIMIT 1;', [tenantId]);
    assert(estRes.rows.length > 0, 'Must have at least one establishment in tenant 2');
    establishmentId = estRes.rows[0].id;

    // 2. OWNER membership
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

    // 3. MANAGER membership
    const mgrUserRes = await client.query(`
      INSERT INTO usuarios (email, nombre, rol, tenant_id, auth_provider, provider_id, password_hash)
      VALUES ('nodo08_mgr@beautyapp.com', 'NODO-08 Manager', 'PRESTADOR', 2, 'LOCAL', 'nodo08-mgr-loc', 'hash')
      ON CONFLICT (email) DO UPDATE SET is_active = true
      RETURNING id;
    `);
    const mgrUserId = mgrUserRes.rows[0].id;

    const mgrMem = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, status)
      VALUES ($1, $2, $3, 'MANAGER', 'ACTIVE')
      ON CONFLICT (establishment_id, user_id) DO UPDATE SET status = 'ACTIVE', role = 'MANAGER'
      RETURNING id;
    `, [tenantId, establishmentId, mgrUserId]);
    managerMembershipId = mgrMem.rows[0].id;

    // 4. RECEPTIONIST membership
    const recUserRes = await client.query(`
      INSERT INTO usuarios (email, nombre, rol, tenant_id, auth_provider, provider_id, password_hash)
      VALUES ('nodo08_rec@beautyapp.com', 'NODO-08 Receptionist', 'PRESTADOR', 2, 'LOCAL', 'nodo08-rec-loc', 'hash')
      ON CONFLICT (email) DO UPDATE SET is_active = true
      RETURNING id;
    `);
    const recUserId = recUserRes.rows[0].id;

    const recMem = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, status)
      VALUES ($1, $2, $3, 'RECEPTIONIST', 'ACTIVE')
      ON CONFLICT (establishment_id, user_id) DO UPDATE SET status = 'ACTIVE', role = 'RECEPTIONIST'
      RETURNING id;
    `, [tenantId, establishmentId, recUserId]);
    receptionistMembershipId = recMem.rows[0].id;

    // 5. Professional 1 & Professional 2
    const p1UserRes = await client.query(`
      INSERT INTO usuarios (email, nombre, rol, tenant_id, auth_provider, provider_id, password_hash)
      VALUES ('nodo08_prof1@beautyapp.com', 'NODO-08 Stylist 1', 'PRESTADOR', 2, 'LOCAL', 'nodo08-p1-loc', 'hash')
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
      VALUES ('nodo08_prof2@beautyapp.com', 'NODO-08 Stylist 2', 'PRESTADOR', 2, 'LOCAL', 'nodo08-p2-loc', 'hash')
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

    // Inactive Professional
    const inactUserRes = await client.query(`
      INSERT INTO usuarios (email, nombre, rol, tenant_id, auth_provider, provider_id, password_hash)
      VALUES ('nodo08_inact@beautyapp.com', 'NODO-08 Inactive Stylist', 'PRESTADOR', 2, 'LOCAL', 'nodo08-inact-loc', 'hash')
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

    // 6. Service Offers
    const so1 = await client.query(`
      INSERT INTO service_offers (tenant_id, establishment_id, name, description, base_duration, base_price)
      VALUES ($1, $2, 'N08 Balayage Deluxe', 'Coloración capilar avanzada', 120, 180000.00)
      RETURNING id;
    `, [tenantId, establishmentId]);
    serviceOfferId1 = so1.rows[0].id;

    const so2 = await client.query(`
      INSERT INTO service_offers (tenant_id, establishment_id, name, description, base_duration, base_price)
      VALUES ($1, $2, 'N08 Peinado Fiesta', 'Peinado elegante', 45, 60000.00)
      RETURNING id;
    `, [tenantId, establishmentId]);
    serviceOfferId2 = so2.rows[0].id;

    // 7. Service Assignments (Offer 1 -> Prof 1 only; Offer 2 -> Prof 2 only)
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

    // 8. Appointments for linkage tests with unique timestamps
    const randomOffsetDays = Math.floor(Math.random() * 50000) + 1000;
    const apptInServ = await client.query(`
      INSERT INTO saas_appointments (
        tenant_id, establishment_id, service_offer_id, membership_id,
        guest_name, guest_phone, scheduled_at, end_time,
        service_name_snapshot, duration_minutes_snapshot, price_snapshot,
        status
      ) VALUES (
        $1, $2, $3, $4,
        'Cita In Service Guest', '+573009998877', NOW() + ($5 * INTERVAL '1 day'), (NOW() + ($5 * INTERVAL '1 day')) + (120 * INTERVAL '1 minute'),
        'N08 Balayage Deluxe', 120, 180000.00,
        'IN_SERVICE'
      ) RETURNING id;
    `, [tenantId, establishmentId, serviceOfferId1, profMembershipId1, randomOffsetDays]);
    appointmentInServiceId = apptInServ.rows[0].id;

    const apptSched = await client.query(`
      INSERT INTO saas_appointments (
        tenant_id, establishment_id, service_offer_id, membership_id,
        guest_name, guest_phone, scheduled_at, end_time,
        service_name_snapshot, duration_minutes_snapshot, price_snapshot,
        status
      ) VALUES (
        $1, $2, $3, $4,
        'Cita Scheduled Guest', '+573009998877', NOW() + (($5 + 1) * INTERVAL '1 day'), (NOW() + (($5 + 1) * INTERVAL '1 day')) + (45 * INTERVAL '1 minute'),
        'N08 Peinado Fiesta', 45, 60000.00,
        'SCHEDULED'
      ) RETURNING id;
    `, [tenantId, establishmentId, serviceOfferId2, profMembershipId2, randomOffsetDays]);
    appointmentScheduledId = apptSched.rows[0].id;

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }

  // Define Context Helper
  function getContext(role = 'OWNER', membershipId = ownerMembershipId) {
    return {
      tenant_id: tenantId,
      establishment_id: establishmentId,
      active_membership_id: membershipId,
      role: role
    };
  }

  // ============================================================================
  // TEST CASES
  // ============================================================================

  // T01: Creación de Ticket con cliente GUEST válido
  let testTicketId = null;
  await test('T01: Creación de Ticket con cliente GUEST válido (Folio TICK-000001 asignado)', async () => {
    const ctx = getContext('RECEPTIONIST', receptionistMembershipId);
    const { req, res } = createMockReqRes({
      activeContext: ctx,
      body: {
        client_mode: 'GUEST',
        guest_name: 'Camila Rodriguez',
        guest_phone: '+573001234567',
        guest_email: 'camila@example.com',
        notes: 'Cliente de paso'
      }
    });

    await nodo08TicketsController.createTicket(req, res);
    assert.strictEqual(res.getStatusCode(), 201);
    const body = res.getBody();
    assert(body.id, 'Must return ticket id');
    assert.strictEqual(body.client_mode, 'GUEST');
    assert.strictEqual(body.guest_name_snapshot, 'Camila Rodriguez');
    assert.strictEqual(body.status, 'DRAFT');
    assert(/^TICK-\d{6}$/.test(body.ticket_number), 'Ticket number must match format TICK-000001');
    assert.strictEqual(parseFloat(body.subtotal_amount), 0.00);
    assert.strictEqual(parseFloat(body.balance_due), 0.00);

    testTicketId = body.id;
  });

  // T02: Creación de Ticket con cliente REGISTERED válido
  await test('T02: Creación de Ticket con cliente REGISTERED válido', async () => {
    const ctx = getContext('MANAGER', managerMembershipId);
    const { req, res } = createMockReqRes({
      activeContext: ctx,
      body: {
        client_mode: 'REGISTERED',
        customer_user_id: customerUserId
      }
    });

    await nodo08TicketsController.createTicket(req, res);
    assert.strictEqual(res.getStatusCode(), 201);
    const body = res.getBody();
    assert.strictEqual(body.client_mode, 'REGISTERED');
    assert.strictEqual(body.customer_user_id, customerUserId);
    assert.strictEqual(body.guest_name_snapshot, null);
    assert.strictEqual(body.status, 'DRAFT');
  });

  // T03: Validación XOR de cliente (conflicto GUEST con customer_user_id)
  await test('T03: Validación XOR de cliente (GUEST con customer_user_id genera error 400)', async () => {
    const ctx = getContext('OWNER', ownerMembershipId);
    const { req, res } = createMockReqRes({
      activeContext: ctx,
      body: {
        client_mode: 'GUEST',
        guest_name: 'Camila',
        customer_user_id: customerUserId
      }
    });

    await nodo08TicketsController.createTicket(req, res);
    assert.strictEqual(res.getStatusCode(), 400);
    const body = res.getBody();
    assert.strictEqual(body.error.code, 'INVALID_CLIENT_MODE');
  });

  // T04: Validación XOR de cliente (GUEST sin guest_name)
  await test('T04: Validación XOR de cliente (GUEST sin guest_name genera error 400)', async () => {
    const ctx = getContext('OWNER', ownerMembershipId);
    const { req, res } = createMockReqRes({
      activeContext: ctx,
      body: {
        client_mode: 'GUEST'
      }
    });

    await nodo08TicketsController.createTicket(req, res);
    assert.strictEqual(res.getStatusCode(), 400);
    const body = res.getBody();
    assert.strictEqual(body.error.code, 'INVALID_CLIENT_MODE');
  });

  // T05: Folio incremental consecutivo por establecimiento
  await test('T05: Folio incremental consecutivo por establecimiento (TICK-00000X)', async () => {
    const ctx = getContext('OWNER', ownerMembershipId);
    const res1 = await nodo08TicketsService.createTicket(ctx, {
      client_mode: 'GUEST',
      guest_name: 'Cliente Seq 1'
    });
    const res2 = await nodo08TicketsService.createTicket(ctx, {
      client_mode: 'GUEST',
      guest_name: 'Cliente Seq 2'
    });

    const num1 = parseInt(res1.ticket_number.replace('TICK-', ''), 10);
    const num2 = parseInt(res2.ticket_number.replace('TICK-', ''), 10);
    assert.strictEqual(num2, num1 + 1, 'Folio must increment by exactly 1');
  });

  // T06: Folio concurrente atómico seguro
  await test('T06: Folio concurrente atómico seguro (10 creaciones paralelas sin duplicados)', async () => {
    const ctx = getContext('OWNER', ownerMembershipId);
    const promises = Array.from({ length: 10 }, (_, i) =>
      nodo08TicketsService.createTicket(ctx, {
        client_mode: 'GUEST',
        guest_name: `Concurrent Client ${i}`
      })
    );

    const results = await Promise.all(promises);
    const ticketNumbers = results.map(r => r.ticket_number);
    const uniqueNumbers = new Set(ticketNumbers);
    assert.strictEqual(uniqueNumbers.size, 10, 'All 10 ticket numbers must be unique');
  });

  // T07: Creación de SERVICE item válido
  let itemId1 = null;
  await test('T07: Creación de SERVICE item válido (precio base snapshot y recálculo total)', async () => {
    const ctx = getContext('RECEPTIONIST', receptionistMembershipId);
    const { req, res } = createMockReqRes({
      activeContext: ctx,
      params: { id: testTicketId },
      body: {
        item_type: 'SERVICE',
        service_offer_id: serviceOfferId1,
        performed_by_membership_id: profMembershipId1,
        quantity: 1,
        discount_amount: 10000.00
      }
    });

    await nodo08TicketsController.addItem(req, res);
    assert.strictEqual(res.getStatusCode(), 201);
    const body = res.getBody();
    assert(body.item, 'Must return item object');
    assert.strictEqual(body.item.title_snapshot, 'N08 Balayage Deluxe');
    assert.strictEqual(parseFloat(body.item.unit_price_snapshot), 180000.00);
    assert.strictEqual(parseFloat(body.item.discount_amount), 10000.00);
    assert.strictEqual(parseFloat(body.item.total_amount), 170000.00);

    assert(body.ticket, 'Must return updated ticket');
    assert.strictEqual(parseFloat(body.ticket.subtotal_amount), 170000.00);
    assert.strictEqual(parseFloat(body.ticket.total_amount), 170000.00);
    assert.strictEqual(parseFloat(body.ticket.balance_due), 170000.00);

    itemId1 = body.item.id;
  });

  // T08: Rechazo de SERVICE item sin service_assignment
  await test('T08: Rechazo de SERVICE item sin service_assignment (422 INVALID_SERVICE_ASSIGNMENT)', async () => {
    const ctx = getContext('OWNER', ownerMembershipId);
    const { req, res } = createMockReqRes({
      activeContext: ctx,
      params: { id: testTicketId },
      body: {
        item_type: 'SERVICE',
        service_offer_id: serviceOfferId1, // Assigned to prof 1, NOT prof 2
        performed_by_membership_id: profMembershipId2,
        quantity: 1
      }
    });

    await nodo08TicketsController.addItem(req, res);
    assert.strictEqual(res.getStatusCode(), 422);
    const body = res.getBody();
    assert.strictEqual(body.error.code, 'INVALID_SERVICE_ASSIGNMENT');
  });

  // T09: Rechazo de SERVICE item con membership inactivo
  await test('T09: Rechazo de SERVICE item con membership inactivo / SUSPENDED (422 INACTIVE_MEMBERSHIP)', async () => {
    const ctx = getContext('OWNER', ownerMembershipId);
    const { req, res } = createMockReqRes({
      activeContext: ctx,
      params: { id: testTicketId },
      body: {
        item_type: 'SERVICE',
        service_offer_id: serviceOfferId1,
        performed_by_membership_id: inactiveProfMembershipId,
        quantity: 1
      }
    });

    await nodo08TicketsController.addItem(req, res);
    assert.strictEqual(res.getStatusCode(), 422);
    const body = res.getBody();
    assert.strictEqual(body.error.code, 'INACTIVE_MEMBERSHIP');
  });

  // T10: Creación de CUSTOM item válido
  let customItemId = null;
  await test('T10: Creación de CUSTOM item válido (concepto libre y precio unitario)', async () => {
    const ctx = getContext('RECEPTIONIST', receptionistMembershipId);
    const { req, res } = createMockReqRes({
      activeContext: ctx,
      params: { id: testTicketId },
      body: {
        item_type: 'CUSTOM',
        title: 'Tratamiento Ampolla Keratina',
        performed_by_membership_id: profMembershipId1,
        quantity: 2,
        unit_price: 25000.00,
        discount_amount: 5000.00
      }
    });

    await nodo08TicketsController.addItem(req, res);
    assert.strictEqual(res.getStatusCode(), 201);
    const body = res.getBody();
    assert.strictEqual(body.item.item_type, 'CUSTOM');
    assert.strictEqual(body.item.title_snapshot, 'Tratamiento Ampolla Keratina');
    assert.strictEqual(parseFloat(body.item.unit_price_snapshot), 25000.00);
    // (2 * 25000) - 5000 = 45000
    assert.strictEqual(parseFloat(body.item.total_amount), 45000.00);
    // Ticket total: 170000 + 45000 = 215000
    assert.strictEqual(parseFloat(body.ticket.subtotal_amount), 215000.00);

    customItemId = body.item.id;
  });

  // T11: Modificación de ítem en DRAFT
  await test('T11: Modificación de ítem en DRAFT (cambio de cantidad y descuento)', async () => {
    const ctx = getContext('RECEPTIONIST', receptionistMembershipId);
    const { req, res } = createMockReqRes({
      activeContext: ctx,
      params: { id: testTicketId, itemId: customItemId },
      body: {
        quantity: 1,
        discount_amount: 0.00
      }
    });

    await nodo08TicketsController.updateItem(req, res);
    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert.strictEqual(body.item.quantity, 1);
    assert.strictEqual(parseFloat(body.item.total_amount), 25000.00);
    // Ticket total: 170000 + 25000 = 195000
    assert.strictEqual(parseFloat(body.ticket.subtotal_amount), 195000.00);
  });

  // T12: Eliminación de ítem en DRAFT
  await test('T12: Eliminación de ítem en DRAFT (recalcula subtotal y balance)', async () => {
    const ctx = getContext('RECEPTIONIST', receptionistMembershipId);
    const { req, res } = createMockReqRes({
      activeContext: ctx,
      params: { id: testTicketId, itemId: customItemId }
    });

    await nodo08TicketsController.deleteItem(req, res);
    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert.strictEqual(body.deleted, true);
    // Ticket subtotal back to 170000
    assert.strictEqual(parseFloat(body.ticket.subtotal_amount), 170000.00);
  });

  // T13: Ajustes de cabecera en DRAFT
  await test('T13: Aplicación de ajustes de cabecera en DRAFT (descuento con motivo, propina, notas)', async () => {
    const ctx = getContext('RECEPTIONIST', receptionistMembershipId);
    const { req, res } = createMockReqRes({
      activeContext: ctx,
      params: { id: testTicketId },
      body: {
        discount_amount: 20000.00,
        discount_reason: 'Descuento cliente frecuente',
        tip_amount: 10000.00,
        notes: 'Atendido en sillón 3'
      }
    });

    await nodo08TicketsController.applyAdjustments(req, res);
    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert.strictEqual(parseFloat(body.discount_amount), 20000.00);
    assert.strictEqual(body.discount_reason, 'Descuento cliente frecuente');
    assert.strictEqual(parseFloat(body.tip_amount), 10000.00);
    // Total: 170000 - 20000 + 10000 = 160000
    assert.strictEqual(parseFloat(body.total_amount), 160000.00);
    assert.strictEqual(parseFloat(body.balance_due), 160000.00);
  });

  // T14: Confirmación de Ticket DRAFT -> OPEN
  await test('T14: Confirmación de Ticket DRAFT -> OPEN', async () => {
    const ctx = getContext('RECEPTIONIST', receptionistMembershipId);
    const { req, res } = createMockReqRes({
      activeContext: ctx,
      params: { id: testTicketId }
    });

    await nodo08TicketsController.confirmTicket(req, res);
    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert.strictEqual(body.status, 'OPEN');
    assert.strictEqual(parseFloat(body.total_amount), 160000.00);
  });

  // T15: Rechazo de confirmación de Ticket DRAFT vacío sin ítems
  await test('T15: Rechazo de confirmación de Ticket DRAFT vacío sin ítems (422 EMPTY_TICKET)', async () => {
    const ctx = getContext('OWNER', ownerMembershipId);
    const emptyTicket = await nodo08TicketsService.createTicket(ctx, {
      client_mode: 'GUEST',
      guest_name: 'Empty Ticket Guest'
    });

    const { req, res } = createMockReqRes({
      activeContext: ctx,
      params: { id: emptyTicket.id }
    });

    await nodo08TicketsController.confirmTicket(req, res);
    assert.strictEqual(res.getStatusCode(), 422);
    const body = res.getBody();
    assert.strictEqual(body.error.code, 'EMPTY_TICKET');
  });

  // T16: Registro de pago en ticket OPEN (CASH)
  await test('T16: Registro de pago en ticket OPEN (método CASH, reduce balance_due)', async () => {
    const ctx = getContext('RECEPTIONIST', receptionistMembershipId);
    const { req, res } = createMockReqRes({
      activeContext: ctx,
      params: { id: testTicketId },
      body: {
        payment_method: 'CASH',
        amount: 60000.00
      }
    });

    await nodo08TicketsController.addPayment(req, res);
    assert.strictEqual(res.getStatusCode(), 201);
    const body = res.getBody();
    assert.strictEqual(body.payment.payment_method, 'CASH');
    assert.strictEqual(parseFloat(body.payment.amount), 60000.00);
    assert.strictEqual(parseFloat(body.ticket.paid_amount), 60000.00);
    assert.strictEqual(parseFloat(body.ticket.balance_due), 100000.00);
    assert.strictEqual(body.ticket.status, 'OPEN');
  });

  // T17: Rechazo de sobrepago
  await test('T17: Rechazo de sobrepago (422 OVERPAYMENT_NOT_ALLOWED)', async () => {
    const ctx = getContext('RECEPTIONIST', receptionistMembershipId);
    const { req, res } = createMockReqRes({
      activeContext: ctx,
      params: { id: testTicketId },
      body: {
        payment_method: 'CARD',
        amount: 150000.00 // Remaining is 100000
      }
    });

    await nodo08TicketsController.addPayment(req, res);
    assert.strictEqual(res.getStatusCode(), 422);
    const body = res.getBody();
    assert.strictEqual(body.error.code, 'OVERPAYMENT_NOT_ALLOWED');
  });

  // T18: Soporte Split Tender y transición automática a PAID
  await test('T18: Soporte Split Tender (segundo pago CARD) y transición automática a PAID', async () => {
    const ctx = getContext('RECEPTIONIST', receptionistMembershipId);
    const { req, res } = createMockReqRes({
      activeContext: ctx,
      params: { id: testTicketId },
      body: {
        payment_method: 'CARD',
        amount: 100000.00,
        reference_code: 'AUTH-998822'
      }
    });

    await nodo08TicketsController.addPayment(req, res);
    assert.strictEqual(res.getStatusCode(), 201);
    const body = res.getBody();
    assert.strictEqual(parseFloat(body.ticket.paid_amount), 160000.00);
    assert.strictEqual(parseFloat(body.ticket.balance_due), 0.00);
    assert.strictEqual(body.ticket.status, 'PAID', 'Ticket must transition automatically to PAID');
  });

  // T19: Cierre definitivo de Ticket PAID -> CLOSED
  await test('T19: Cierre definitivo de Ticket PAID -> CLOSED', async () => {
    const ctx = getContext('RECEPTIONIST', receptionistMembershipId);
    const { req, res } = createMockReqRes({
      activeContext: ctx,
      params: { id: testTicketId }
    });

    await nodo08TicketsController.closeTicket(req, res);
    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert.strictEqual(body.status, 'CLOSED');
    assert.strictEqual(body.closed_by_membership_id, receptionistMembershipId);
    assert(body.closed_at, 'Must have closed_at timestamp');
  });

  // T20: Inmutabilidad estricta de ticket CLOSED
  await test('T20: Inmutabilidad estricta de ticket CLOSED (rechazo de pagos, ítems o ajustes)', async () => {
    const ctx = getContext('OWNER', ownerMembershipId);

    // Try add item
    const { req: r1, res: res1 } = createMockReqRes({
      activeContext: ctx,
      params: { id: testTicketId },
      body: {
        item_type: 'CUSTOM',
        title: 'Item Ilegal',
        performed_by_membership_id: profMembershipId1,
        unit_price: 10000
      }
    });
    await nodo08TicketsController.addItem(r1, res1);
    assert.strictEqual(res1.getStatusCode(), 422);

    // Try add payment
    const { req: r2, res: res2 } = createMockReqRes({
      activeContext: ctx,
      params: { id: testTicketId },
      body: { payment_method: 'CASH', amount: 1000 }
    });
    await nodo08TicketsController.addPayment(r2, res2);
    assert.strictEqual(res2.getStatusCode(), 422);
  });

  // T21: Anulación de Ticket DRAFT o OPEN -> VOID
  await test('T21: Anulación de Ticket (OPEN -> VOID con motivo)', async () => {
    const ctx = getContext('MANAGER', managerMembershipId);
    const t = await nodo08TicketsService.createTicket(ctx, {
      client_mode: 'GUEST',
      guest_name: 'Ticket to Void'
    });
    await nodo08TicketsService.addItem(ctx, t.id, {
      item_type: 'SERVICE',
      service_offer_id: serviceOfferId1,
      performed_by_membership_id: profMembershipId1,
      quantity: 1
    });
    await nodo08TicketsService.confirmTicket(ctx, t.id);

    const { req, res } = createMockReqRes({
      activeContext: ctx,
      params: { id: t.id },
      body: { reason: 'Cliente se retiró antes del servicio' }
    });

    await nodo08TicketsController.voidTicket(req, res);
    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert.strictEqual(body.status, 'VOID');
    assert.strictEqual(body.void_reason, 'Cliente se retiró antes del servicio');
    assert.strictEqual(body.voided_by_membership_id, managerMembershipId);
  });

  // T22: Rechazo de anulación por RECEPTIONIST
  await test('T22: Rechazo de anulación por rol RECEPTIONIST (403 UNAUTHORIZED_ROLE)', async () => {
    const ctxRec = getContext('RECEPTIONIST', receptionistMembershipId);
    const ctxMgr = getContext('MANAGER', managerMembershipId);
    const t = await nodo08TicketsService.createTicket(ctxMgr, {
      client_mode: 'GUEST',
      guest_name: 'Ticket Void Test'
    });

    const { req, res } = createMockReqRes({
      activeContext: ctxRec,
      params: { id: t.id },
      body: { reason: 'Intento de anulación no autorizado' }
    });

    await nodo08TicketsController.voidTicket(req, res);
    assert.strictEqual(res.getStatusCode(), 403);
    const body = res.getBody();
    assert.strictEqual(body.error.code, 'UNAUTHORIZED_ROLE');
  });

  // T23: Restricciones de rol PROFESSIONAL
  await test('T23: Restricciones de rol PROFESSIONAL (403 al crear tickets o listar)', async () => {
    const ctxProf = getContext('PROFESSIONAL', profMembershipId1);

    // Create ticket attempt
    const { req: r1, res: res1 } = createMockReqRes({
      activeContext: ctxProf,
      body: { client_mode: 'GUEST', guest_name: 'Prof Ticket' }
    });
    await nodo08TicketsController.createTicket(r1, res1);
    assert.strictEqual(res1.getStatusCode(), 403);

    // List tickets attempt
    const { req: r2, res: res2 } = createMockReqRes({
      activeContext: ctxProf,
      query: {}
    });
    await nodo08TicketsController.listTickets(r2, res2);
    assert.strictEqual(res2.getStatusCode(), 403);
  });

  // T24: Consulta de Ticket por PROFESSIONAL (sólo sus propios ítems)
  await test('T24: Consulta de Ticket por PROFESSIONAL (sólo sus propios ítems)', async () => {
    const ctxOwner = getContext('OWNER', ownerMembershipId);
    const t = await nodo08TicketsService.createTicket(ctxOwner, {
      client_mode: 'GUEST',
      guest_name: 'Multi Prof Ticket'
    });
    await nodo08TicketsService.addItem(ctxOwner, t.id, {
      item_type: 'SERVICE',
      service_offer_id: serviceOfferId1,
      performed_by_membership_id: profMembershipId1,
      quantity: 1
    });
    await nodo08TicketsService.addItem(ctxOwner, t.id, {
      item_type: 'SERVICE',
      service_offer_id: serviceOfferId2,
      performed_by_membership_id: profMembershipId2,
      quantity: 1
    });

    const ctxProf1 = getContext('PROFESSIONAL', profMembershipId1);
    const { req, res } = createMockReqRes({
      activeContext: ctxProf1,
      params: { id: t.id }
    });

    await nodo08TicketsController.getTicketById(req, res);
    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert.strictEqual(body.items.length, 1, 'Prof 1 should only see their own item');
    assert.strictEqual(body.items[0].performed_by_membership_id, profMembershipId1);
    assert.strictEqual(body.payments.length, 0, 'Prof 1 should not see payment details');
  });

  // T25: Relación con Cita Operacional (IN_SERVICE permitido, SCHEDULED rechazado)
  await test('T25: Relación con Cita Operacional (IN_SERVICE permitido, SCHEDULED rechazado 422)', async () => {
    const ctx = getContext('OWNER', ownerMembershipId);

    // 1. Scheduled appointment attempt -> Fail
    const { req: r1, res: res1 } = createMockReqRes({
      activeContext: ctx,
      body: {
        appointment_id: appointmentScheduledId,
        client_mode: 'GUEST',
        guest_name: 'Scheduled Guest'
      }
    });
    await nodo08TicketsController.createTicket(r1, res1);
    assert.strictEqual(res1.getStatusCode(), 422);
    assert.strictEqual(res1.getBody().error.code, 'INVALID_APPOINTMENT_STATUS');

    // 2. In Service appointment attempt -> Pass
    const { req: r2, res: res2 } = createMockReqRes({
      activeContext: ctx,
      body: {
        appointment_id: appointmentInServiceId,
        client_mode: 'GUEST',
        guest_name: 'In Service Guest'
      }
    });
    await nodo08TicketsController.createTicket(r2, res2);
    assert.strictEqual(res2.getStatusCode(), 201);
    assert.strictEqual(res2.getBody().appointment_id, appointmentInServiceId);
  });

  // T26: Unicidad de Cita Activa (rechazo de segundo ticket activo para la misma cita)
  await test('T26: Unicidad de Cita Activa (rechazo 409 para segundo ticket activo en la misma cita)', async () => {
    const ctx = getContext('OWNER', ownerMembershipId);
    const { req, res } = createMockReqRes({
      activeContext: ctx,
      body: {
        appointment_id: appointmentInServiceId,
        client_mode: 'GUEST',
        guest_name: 'Duplicate Ticket Guest'
      }
    });

    await nodo08TicketsController.createTicket(req, res);
    assert.strictEqual(res.getStatusCode(), 409);
    assert.strictEqual(res.getBody().error.code, 'APPOINTMENT_ALREADY_TICKETED');
  });

  // T27: Listado de tickets con filtros y paginación
  await test('T27: Listado de tickets con filtros y paginación para RECEPTIONIST', async () => {
    const ctx = getContext('RECEPTIONIST', receptionistMembershipId);
    const { req, res } = createMockReqRes({
      activeContext: ctx,
      query: { status: 'CLOSED', page: 1, limit: 10 }
    });

    await nodo08TicketsController.listTickets(req, res);
    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert(Array.isArray(body.tickets), 'Must return tickets array');
    assert(body.pagination, 'Must return pagination object');
    assert(body.tickets.every(t => t.status === 'CLOSED'), 'All returned tickets must be CLOSED');
  });

  // T28: Aislamiento Multi-Tenant y Active Context RLS
  await test('T28: Aislamiento Multi-Tenant (Tenant 999 no puede acceder a tickets de Tenant 2)', async () => {
    const foreignCtx = {
      tenant_id: 999,
      establishment_id: establishmentId,
      active_membership_id: ownerMembershipId,
      role: 'OWNER'
    };

    const { req, res } = createMockReqRes({
      activeContext: foreignCtx,
      params: { id: testTicketId }
    });

    await nodo08TicketsController.getTicketById(req, res);
    assert.strictEqual(res.getStatusCode(), 404);
    assert.strictEqual(res.getBody().error.code, 'TICKET_NOT_FOUND');
  });

  // T29: Modificación de ítem en estado OPEN por MANAGER/OWNER
  await test('T29: Modificación de ítem en estado OPEN por MANAGER (aumentar cantidad con recálculo)', async () => {
    const ctxMgr = getContext('MANAGER', managerMembershipId);
    const t = await nodo08TicketsService.createTicket(ctxMgr, {
      client_mode: 'GUEST',
      guest_name: 'Open Edit Test Guest'
    });
    const itemRes = await nodo08TicketsService.addItem(ctxMgr, t.id, {
      item_type: 'SERVICE',
      service_offer_id: serviceOfferId1,
      performed_by_membership_id: profMembershipId1,
      quantity: 1
    });
    await nodo08TicketsService.confirmTicket(ctxMgr, t.id);

    const { req, res } = createMockReqRes({
      activeContext: ctxMgr,
      params: { id: t.id, itemId: itemRes.item.id },
      body: { quantity: 2 }
    });

    await nodo08TicketsController.updateItem(req, res);
    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert.strictEqual(body.item.quantity, 2);
    // 2 * 180000 = 360000
    assert.strictEqual(parseFloat(body.item.total_amount), 360000.00);
    assert.strictEqual(parseFloat(body.ticket.total_amount), 360000.00);
  });

  // T30: Rechazo de modificación de ítem en estado OPEN por RECEPTIONIST
  await test('T30: Rechazo de modificación de ítem en estado OPEN por RECEPTIONIST (403 UNAUTHORIZED_ROLE)', async () => {
    const ctxMgr = getContext('MANAGER', managerMembershipId);
    const ctxRec = getContext('RECEPTIONIST', receptionistMembershipId);
    const t = await nodo08TicketsService.createTicket(ctxMgr, {
      client_mode: 'GUEST',
      guest_name: 'Open Edit Rec Test Guest'
    });
    const itemRes = await nodo08TicketsService.addItem(ctxMgr, t.id, {
      item_type: 'SERVICE',
      service_offer_id: serviceOfferId1,
      performed_by_membership_id: profMembershipId1,
      quantity: 1
    });
    await nodo08TicketsService.confirmTicket(ctxMgr, t.id);

    const { req, res } = createMockReqRes({
      activeContext: ctxRec,
      params: { id: t.id, itemId: itemRes.item.id },
      body: { quantity: 3 }
    });

    await nodo08TicketsController.updateItem(req, res);
    assert.strictEqual(res.getStatusCode(), 403);
    assert.strictEqual(res.getBody().error.code, 'UNAUTHORIZED_ROLE');
  });

  // T31: Creación de nuevo ticket para una cita previa tras anulación (VOID) del ticket anterior
  await test('T31: Creación de nuevo ticket para cita tras anulación (VOID) del ticket anterior (FINDING-AUD-002)', async () => {
    const ctxOwner = getContext('OWNER', ownerMembershipId);
    
    // Crear cita adicional en IN_SERVICE
    const randDays = Math.floor(Math.random() * 50000) + 20000;
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', '2', true);");
    const apptRes = await client.query(`
      INSERT INTO saas_appointments (
        tenant_id, establishment_id, service_offer_id, membership_id,
        guest_name, guest_phone, scheduled_at, end_time,
        service_name_snapshot, duration_minutes_snapshot, price_snapshot,
        status
      ) VALUES (
        $1, $2, $3, $4,
        'Cita Void Re-ticket Guest', '+573001112233', NOW() + ($5 * INTERVAL '1 day'), (NOW() + ($5 * INTERVAL '1 day')) + (120 * INTERVAL '1 minute'),
        'N08 Balayage Deluxe', 120, 180000.00,
        'IN_SERVICE'
      ) RETURNING id;
    `, [tenantId, establishmentId, serviceOfferId1, profMembershipId1, randDays]);
    await client.query('COMMIT');
    const targetApptId = apptRes.rows[0].id;

    // Primer ticket
    const t1 = await nodo08TicketsService.createTicket(ctxOwner, {
      appointment_id: targetApptId,
      client_mode: 'GUEST',
      guest_name: 'Primer Ticket'
    });

    // Anular primer ticket
    await nodo08TicketsService.voidTicket(ctxOwner, t1.id, { reason: 'Error en asignación' });

    // Segundo ticket para la misma cita -> DEBE tener éxito porque t1 está VOID
    const { req, res } = createMockReqRes({
      activeContext: ctxOwner,
      body: {
        appointment_id: targetApptId,
        client_mode: 'GUEST',
        guest_name: 'Segundo Ticket Valido'
      }
    });

    await nodo08TicketsController.createTicket(req, res);
    assert.strictEqual(res.getStatusCode(), 201);
    assert.strictEqual(res.getBody().appointment_id, targetApptId);
  });

  // T32: Rechazo de SERVICE item con oferta de otro establecimiento
  await test('T32: Rechazo de SERVICE item con oferta de otro establecimiento (404 SERVICE_OFFER_NOT_FOUND)', async () => {
    const ctx = getContext('OWNER', ownerMembershipId);
    const t = await nodo08TicketsService.createTicket(ctx, {
      client_mode: 'GUEST',
      guest_name: 'Cross Est Test'
    });

    const fakeOfferId = 'a0000000-0000-0000-0000-000000000099';
    const { req, res } = createMockReqRes({
      activeContext: ctx,
      params: { id: t.id },
      body: {
        item_type: 'SERVICE',
        service_offer_id: fakeOfferId,
        performed_by_membership_id: profMembershipId1,
        quantity: 1
      }
    });

    await nodo08TicketsController.addItem(req, res);
    assert.strictEqual(res.getStatusCode(), 404);
    assert.strictEqual(res.getBody().error.code, 'SERVICE_OFFER_NOT_FOUND');
  });

  // T33: Inmutabilidad de estado VOID
  await test('T33: Inmutabilidad de ticket VOID (rechazo de agregar pagos o ítems)', async () => {
    const ctx = getContext('OWNER', ownerMembershipId);
    const t = await nodo08TicketsService.createTicket(ctx, {
      client_mode: 'GUEST',
      guest_name: 'Void Inmutability Test'
    });
    await nodo08TicketsService.voidTicket(ctx, t.id, { reason: 'Anulado inmediatamente' });

    const { req, res } = createMockReqRes({
      activeContext: ctx,
      params: { id: t.id },
      body: {
        item_type: 'CUSTOM',
        title: 'Item Post-Void',
        performed_by_membership_id: profMembershipId1,
        unit_price: 50000
      }
    });

    await nodo08TicketsController.addItem(req, res);
    assert.strictEqual(res.getStatusCode(), 422);
    assert.strictEqual(res.getBody().error.code, 'IMMUTABLE_TICKET_STATUS');
  });

  // T34: Rechazo de confirmación o cierre en ticket CLOSED
  await test('T34: Rechazo de transiciones inválidas en ticket CLOSED (422)', async () => {
    const ctx = getContext('OWNER', ownerMembershipId);
    const { req, res } = createMockReqRes({
      activeContext: ctx,
      params: { id: testTicketId } // testTicketId was closed in T19
    });

    await nodo08TicketsController.closeTicket(req, res);
    assert.strictEqual(res.getStatusCode(), 422);
    assert.strictEqual(res.getBody().error.code, 'INVALID_STATUS_FOR_CLOSE');
  });

  console.log('\n================================================================================');
  console.log(`NODO-08 SUITE RESULT: ${passed} Passed, ${failed} Failed`);
  console.log('================================================================================\n');

  if (failed > 0) {
    throw new Error(`NODO-08 Suite failed with ${failed} failing tests`);
  }
}

if (require.main === module) {
  runNodo08Suite()
    .then(() => {
      console.log('NODO-08 Suite completed successfully.');
      process.exit(0);
    })
    .catch((err) => {
      console.error('NODO-08 Suite failed:', err);
      process.exit(1);
    });
}

module.exports = { runNodo08Suite };
