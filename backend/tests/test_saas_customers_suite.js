// backend/tests/test_saas_customers_suite.js
const assert = require('assert');
const { pool } = require('../src/config/db');
const saasCustomersService = require('../src/services/saasCustomersService');
const saasCustomersController = require('../src/controllers/saasCustomersController');

/**
 * CUSTOMER / CLIENT DIRECTORY COMPREHENSIVE TEST SUITE
 * Tests all 20 scenarios against real PostgreSQL database.
 */

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

async function runCustomerSuite() {
  console.log('================================================================================');
  console.log('       CUSTOMER / CLIENT DIRECTORY ENGINE — COMPREHENSIVE TEST SUITE');
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
      if (err.stack) console.error(`    Stack: ${err.stack}`);
      failed++;
    }
  }

  // Setup Fixtures in Tenant 2 and Tenant 1
  const tenantId1 = 1;
  const tenantId2 = 2;
  let establishmentId2A = null;
  let establishmentId2B = null;
  let establishmentId1 = null;
  let ownerMembershipId = null;
  let managerMembershipId = null;
  let receptionistMembershipId = null;
  let professionalMembershipId = null;
  let userT2Id = null;
  let userT1Id = null;

  const client = await pool.connect();
  try {
    // 1. Get or create establishments in Tenant 2
    let estRes = await client.query('SELECT id FROM establishments WHERE tenant_id = $1 LIMIT 2', [tenantId2]);
    if (estRes.rows.length < 2) {
      await client.query("INSERT INTO establishments (tenant_id, name, slug) VALUES (2, 'Sede 2A', 'sede-2a') ON CONFLICT DO NOTHING");
      await client.query("INSERT INTO establishments (tenant_id, name, slug) VALUES (2, 'Sede 2B', 'sede-2b') ON CONFLICT DO NOTHING");
      estRes = await client.query('SELECT id FROM establishments WHERE tenant_id = $1 LIMIT 2', [tenantId2]);
    }
    establishmentId2A = estRes.rows[0].id;
    establishmentId2B = estRes.rows[1] ? estRes.rows[1].id : estRes.rows[0].id;

    // Establishment in Tenant 1
    let est1Res = await client.query('SELECT id FROM establishments WHERE tenant_id = $1 LIMIT 1', [tenantId1]);
    if (est1Res.rows.length === 0) {
      await client.query("INSERT INTO establishments (tenant_id, name, slug) VALUES (1, 'Sede 1', 'sede-1') ON CONFLICT DO NOTHING");
      est1Res = await client.query('SELECT id FROM establishments WHERE tenant_id = $1 LIMIT 1', [tenantId1]);
    }
    establishmentId1 = est1Res.rows[0].id;

    // Users
    let u2Res = await client.query("SELECT id FROM usuarios WHERE tenant_id = 2 AND email LIKE '%@%' LIMIT 1");
    if (u2Res.rows.length === 0) {
      await client.query("INSERT INTO usuarios (nombre, email, rol, tenant_id, auth_provider, provider_id) VALUES ('User T2', 'user_t2_test@beautyapp.com', 'CLIENTE', 2, 'LOCAL', 'u2_prov')");
      u2Res = await client.query("SELECT id FROM usuarios WHERE tenant_id = 2 LIMIT 1");
    }
    userT2Id = u2Res.rows[0].id;

    let u1Res = await client.query("SELECT id FROM usuarios WHERE tenant_id = 1 LIMIT 1");
    if (u1Res.rows.length === 0) {
      await client.query("INSERT INTO usuarios (nombre, email, rol, tenant_id, auth_provider, provider_id) VALUES ('User T1', 'user_t1_test@beautyapp.com', 'CLIENTE', 1, 'LOCAL', 'u1_prov')");
      u1Res = await client.query("SELECT id FROM usuarios WHERE tenant_id = 1 LIMIT 1");
    }
    userT1Id = u1Res.rows[0].id;

    // Memberships for Tenant 2
    let memOwner = await client.query("SELECT id FROM memberships WHERE tenant_id = 2 AND role = 'OWNER' LIMIT 1");
    if (memOwner.rows.length === 0) {
      await client.query("INSERT INTO memberships (tenant_id, establishment_id, user_id, role) VALUES (2, $1, $2, 'OWNER')", [establishmentId2A, userT2Id]);
      memOwner = await client.query("SELECT id FROM memberships WHERE tenant_id = 2 AND role = 'OWNER' LIMIT 1");
    }
    ownerMembershipId = memOwner.rows[0].id;

    let memMgr = await client.query("SELECT id FROM memberships WHERE tenant_id = 2 AND role = 'MANAGER' LIMIT 1");
    if (memMgr.rows.length === 0) {
      await client.query("INSERT INTO memberships (tenant_id, establishment_id, user_id, role) VALUES (2, $1, $2, 'MANAGER')", [establishmentId2A, userT2Id]);
      memMgr = await client.query("SELECT id FROM memberships WHERE tenant_id = 2 AND role = 'MANAGER' LIMIT 1");
    }
    managerMembershipId = memMgr.rows[0].id;

    let memRecep = await client.query("SELECT id FROM memberships WHERE tenant_id = 2 AND role = 'RECEPTIONIST' LIMIT 1");
    if (memRecep.rows.length === 0) {
      await client.query("INSERT INTO memberships (tenant_id, establishment_id, user_id, role) VALUES (2, $1, $2, 'RECEPTIONIST')", [establishmentId2A, userT2Id]);
      memRecep = await client.query("SELECT id FROM memberships WHERE tenant_id = 2 AND role = 'RECEPTIONIST' LIMIT 1");
    }
    receptionistMembershipId = memRecep.rows[0].id;

    let memProf = await client.query("SELECT id FROM memberships WHERE tenant_id = 2 AND role = 'PROFESSIONAL' LIMIT 1");
    if (memProf.rows.length === 0) {
      await client.query("INSERT INTO memberships (tenant_id, establishment_id, user_id, role) VALUES (2, $1, $2, 'PROFESSIONAL')", [establishmentId2A, userT2Id]);
      memProf = await client.query("SELECT id FROM memberships WHERE tenant_id = 2 AND role = 'PROFESSIONAL' LIMIT 1");
    }
    professionalMembershipId = memProf.rows[0].id;

    // Clean test customers from previous runs in Tenant 2
    await client.query("DELETE FROM saas_customers WHERE tenant_id = 2 AND phone LIKE '+573999%'");
  } finally {
    client.release();
  }

  // Active Context objects for different roles
  const ownerCtx = {
    tenant_id: tenantId2,
    establishment_id: establishmentId2A,
    active_membership_id: ownerMembershipId,
    role: 'OWNER'
  };

  const managerCtx = {
    tenant_id: tenantId2,
    establishment_id: establishmentId2A,
    active_membership_id: managerMembershipId,
    role: 'MANAGER'
  };

  const receptionistCtx = {
    tenant_id: tenantId2,
    establishment_id: establishmentId2A,
    active_membership_id: receptionistMembershipId,
    role: 'RECEPTIONIST'
  };

  const professionalCtx = {
    tenant_id: tenantId2,
    establishment_id: establishmentId2A,
    active_membership_id: professionalMembershipId,
    role: 'PROFESSIONAL'
  };

  let createdCustomerId = null;

  // --- TEST CASES ---

  // T01: Active Context Missing
  await test('T01: Controller rechaza petición si falta Active Context', async () => {
    const { req, res } = createMockReqRes({ activeContext: null });
    await saasCustomersController.listCustomers(req, res);
    assert.strictEqual(res.getStatusCode(), 403);
    assert.strictEqual(res.getBody().error.code, 'ACTIVE_CONTEXT_REQUIRED');
  });

  // T02: Create Customer Atomicity (saas_customers + saas_customer_establishments)
  await test('T02: Creación atómica de cliente y relación con sede activa', async () => {
    const payload = {
      first_name: 'Carolina',
      last_name: 'Herrera',
      phone: '+5739990001',
      email: 'carolina.herrera@test.com',
      birth_date: '1990-03-15',
      local_notes: 'Cliente VIP'
    };
    const { req, res } = createMockReqRes({ activeContext: receptionistCtx, body: payload });
    await saasCustomersController.createCustomer(req, res);

    assert.strictEqual(res.getStatusCode(), 201);
    const body = res.getBody();
    assert.ok(body.id);
    assert.strictEqual(body.first_name, 'Carolina');
    assert.strictEqual(body.phone, '+5739990001');
    assert.strictEqual(body.tenant_id, 2);
    assert.strictEqual(body.status, 'ACTIVE');
    assert.ok(body.establishment_relation);
    assert.strictEqual(body.establishment_relation.establishment_id, establishmentId2A);
    assert.strictEqual(body.establishment_relation.local_notes, 'Cliente VIP');
    assert.strictEqual(body.establishment_relation.is_active, true);

    createdCustomerId = body.id;
  });

  // T03: Role PROFESSIONAL cannot create customer
  await test('T03: Rol PROFESSIONAL es rechazado al intentar crear cliente (403 FORBIDDEN_ROLE)', async () => {
    const payload = {
      first_name: 'Invalid',
      phone: '+5739990099'
    };
    const { req, res } = createMockReqRes({ activeContext: professionalCtx, body: payload });
    await saasCustomersController.createCustomer(req, res);
    assert.strictEqual(res.getStatusCode(), 403);
    assert.strictEqual(res.getBody().error.code, 'FORBIDDEN_ROLE');
  });

  // T04: Duplicate Detection Warning (POSSIBLE_DUPLICATE_FOUND)
  await test('T04: Detección de duplicado por teléfono retorna 409 con candidatos', async () => {
    const payload = {
      first_name: 'Carolina Clone',
      phone: '+5739990001'
    };
    const { req, res } = createMockReqRes({ activeContext: receptionistCtx, body: payload });
    await saasCustomersController.createCustomer(req, res);

    assert.strictEqual(res.getStatusCode(), 409);
    assert.strictEqual(res.getBody().error.code, 'POSSIBLE_DUPLICATE_FOUND');
    assert.ok(res.getBody().error.candidates);
    assert.ok(res.getBody().error.candidates.length > 0);
  });

  // T05: Duplicate Human Confirmation (confirm_duplicate: true)
  await test('T05: Confirmación humana de duplicado permite crear nuevo registro independiente', async () => {
    const payload = {
      first_name: 'Carolina Coincidencia',
      last_name: 'H.',
      phone: '+5739990001',
      confirm_duplicate: true
    };
    const { req, res } = createMockReqRes({ activeContext: receptionistCtx, body: payload });
    await saasCustomersController.createCustomer(req, res);

    assert.strictEqual(res.getStatusCode(), 201);
    const body = res.getBody();
    assert.ok(body.id);
    assert.notStrictEqual(body.id, createdCustomerId);
    assert.strictEqual(body.phone, '+5739990001');
  });

  // T06: Search Typeahead Minimum Length (q < 3 -> 400)
  await test('T06: Search con q de menos de 3 caracteres retorna 400 INVALID_SEARCH_QUERY', async () => {
    const { req, res } = createMockReqRes({ activeContext: receptionistCtx, query: { q: 'ca' } });
    await saasCustomersController.searchCustomers(req, res);
    assert.strictEqual(res.getStatusCode(), 400);
    assert.strictEqual(res.getBody().error.code, 'INVALID_SEARCH_QUERY');
  });

  // T07: Search Typeahead Contextual Match
  await test('T07: Search typeahead encuentra coincidencias por nombre o teléfono en tenant', async () => {
    const { req, res } = createMockReqRes({ activeContext: professionalCtx, query: { q: 'Carolina' } });
    await saasCustomersController.searchCustomers(req, res);

    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert.ok(body.results.length >= 2);
    assert.strictEqual(body.results[0].has_local_relation, true);
    assert.strictEqual(body.results[0].is_linked_to_user, false);
  });

  // T08: Directory Scope Establishment (Default)
  await test('T08: Listar directorio por defecto retorna clientes de la sede activa', async () => {
    const { req, res } = createMockReqRes({ activeContext: professionalCtx, query: {} });
    await saasCustomersController.listCustomers(req, res);

    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert.strictEqual(body.scope, 'establishment');
    assert.ok(body.customers.length > 0);
  });

  // T09: Directory Scope Tenant Allowed for OWNER
  await test('T09: Listar directorio corporativo (scope=tenant) permitido para OWNER', async () => {
    const { req, res } = createMockReqRes({ activeContext: ownerCtx, query: { scope: 'tenant' } });
    await saasCustomersController.listCustomers(req, res);

    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert.strictEqual(body.scope, 'tenant');
    assert.ok(body.total > 0);
  });

  // T10: Directory Scope Tenant Forbidden for RECEPTIONIST (403)
  await test('T10: Listar directorio con scope=tenant rechazado para RECEPTIONIST (403 FORBIDDEN_TENANT_SCOPE)', async () => {
    const { req, res } = createMockReqRes({ activeContext: receptionistCtx, query: { scope: 'tenant' } });
    await saasCustomersController.listCustomers(req, res);

    assert.strictEqual(res.getStatusCode(), 403);
    assert.strictEqual(res.getBody().error.code, 'FORBIDDEN_TENANT_SCOPE');
  });

  // T11: Get Customer Detail & Anti-IDOR
  await test('T11: Obtener detalle de cliente por ID con relación local', async () => {
    const { req, res } = createMockReqRes({ activeContext: professionalCtx, params: { id: createdCustomerId } });
    await saasCustomersController.getCustomerById(req, res);

    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert.strictEqual(body.id, createdCustomerId);
    assert.strictEqual(body.first_name, 'Carolina');
    assert.strictEqual(body.has_local_relation, true);
    assert.strictEqual(body.establishment_relation.local_notes, 'Cliente VIP');
  });

  // T12: Anti-IDOR Cross-Tenant Protection (Tenant 1 accessing Customer in Tenant 2 -> 404)
  await test('T12: Acceso cross-tenant por ID retorna 404 CUSTOMER_NOT_FOUND (Anti-IDOR)', async () => {
    const t1Ctx = {
      tenant_id: tenantId1,
      establishment_id: establishmentId1,
      active_membership_id: ownerMembershipId,
      role: 'OWNER'
    };
    const { req, res } = createMockReqRes({ activeContext: t1Ctx, params: { id: createdCustomerId } });
    await saasCustomersController.getCustomerById(req, res);

    assert.strictEqual(res.getStatusCode(), 404);
    assert.strictEqual(res.getBody().error.code, 'CUSTOMER_NOT_FOUND');
  });

  // T13: Update Canonical Contact Data by RECEPTIONIST
  await test('T13: Actualización de datos canónicos de contacto por RECEPTIONIST', async () => {
    const payload = {
      first_name: 'Carolina Sofia',
      last_name: 'Herrera Gomez',
      phone: '+5739990002'
    };
    const { req, res } = createMockReqRes({
      activeContext: receptionistCtx,
      params: { id: createdCustomerId },
      body: payload
    });
    await saasCustomersController.updateCustomer(req, res);

    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert.strictEqual(body.first_name, 'Carolina Sofia');
    assert.strictEqual(body.phone, '+5739990002');
  });

  // T14: Status Change Forbidden for RECEPTIONIST
  await test('T14: RECEPTIONIST intentando cambiar status recibe 403 UNAUTHORIZED_STATUS_CHANGE', async () => {
    const payload = {
      status: 'ARCHIVED'
    };
    const { req, res } = createMockReqRes({
      activeContext: receptionistCtx,
      params: { id: createdCustomerId },
      body: payload
    });
    await saasCustomersController.updateCustomer(req, res);

    assert.strictEqual(res.getStatusCode(), 403);
    assert.strictEqual(res.getBody().error.code, 'UNAUTHORIZED_STATUS_CHANGE');
  });

  // T15: Status Change Allowed for MANAGER
  await test('T15: MANAGER puede cambiar status canónico del cliente (ACTIVE -> INACTIVE)', async () => {
    const payload = {
      status: 'INACTIVE'
    };
    const { req, res } = createMockReqRes({
      activeContext: managerCtx,
      params: { id: createdCustomerId },
      body: payload
    });
    await saasCustomersController.updateCustomer(req, res);

    assert.strictEqual(res.getStatusCode(), 200);
    assert.strictEqual(res.getBody().status, 'INACTIVE');
  });

  // T16: Update Local Relation Notes by PROFESSIONAL
  await test('T16: PROFESSIONAL puede modificar notas locales de atención en sede activa', async () => {
    const payload = {
      local_notes: 'Nueva preferencia: Fórmula de color 7.1'
    };
    const { req, res } = createMockReqRes({
      activeContext: professionalCtx,
      params: { id: createdCustomerId },
      body: payload
    });
    await saasCustomersController.updateCurrentEstablishmentRelation(req, res);

    assert.strictEqual(res.getStatusCode(), 200);
    assert.strictEqual(res.getBody().local_notes, 'Nueva preferencia: Fórmula de color 7.1');
  });

  // T17: Link User Multi-Tenant Check (Same Tenant 2)
  await test('T17: MANAGER vincula explícitamente cuenta B2C del mismo tenant_id', async () => {
    const payload = {
      user_id: userT2Id
    };
    const { req, res } = createMockReqRes({
      activeContext: managerCtx,
      params: { id: createdCustomerId },
      body: payload
    });
    await saasCustomersController.linkUser(req, res);

    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert.strictEqual(body.user_id, userT2Id);
    assert.ok(body.linked_user);
  });

  // T18: Link User Cross-Tenant Rejection (User in Tenant 1 linked in Tenant 2 -> 403)
  await test('T18: Intento de vincular usuario de otro tenant es rechazado con 403 USER_CROSS_TENANT', async () => {
    const payload = {
      user_id: userT1Id
    };
    const { req, res } = createMockReqRes({
      activeContext: managerCtx,
      params: { id: createdCustomerId },
      body: payload
    });
    await saasCustomersController.linkUser(req, res);

    assert.strictEqual(res.getStatusCode(), 403);
    assert.strictEqual(res.getBody().error.code, 'USER_CROSS_TENANT');
  });

  // T19: History Derived with Linked User
  await test('T19: Consulta de historial con usuario vinculado retorna ATTRIBUTED_VIA_USER_ACCOUNT', async () => {
    const { req, res } = createMockReqRes({
      activeContext: professionalCtx,
      params: { id: createdCustomerId }
    });
    await saasCustomersController.getCustomerHistory(req, res);

    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert.strictEqual(body.attribution_status, 'ATTRIBUTED_VIA_USER_ACCOUNT');
    assert.strictEqual(body.user_id, userT2Id);
    assert.ok(Array.isArray(body.appointments));
    assert.ok(Array.isArray(body.tickets));
  });

  // T20: Unlink User and History Without Linked User (Zero GUEST Attribution)
  await test('T20: Desvincular usuario pasa a UNLINKED_NO_ATTRIBUTED_HISTORY con CERO atribución GUEST', async () => {
    // 1. Unlink
    const { req: unReq, res: unRes } = createMockReqRes({
      activeContext: ownerCtx,
      params: { id: createdCustomerId }
    });
    await saasCustomersController.unlinkUser(unReq, unRes);
    assert.strictEqual(unRes.getStatusCode(), 200);
    assert.strictEqual(unRes.getBody().user_id, null);

    // 2. Query History
    const { req: histReq, res: histRes } = createMockReqRes({
      activeContext: professionalCtx,
      params: { id: createdCustomerId }
    });
    await saasCustomersController.getCustomerHistory(histReq, histRes);

    assert.strictEqual(histRes.getStatusCode(), 200);
    const histBody = histRes.getBody();
    assert.strictEqual(histBody.attribution_status, 'UNLINKED_NO_ATTRIBUTED_HISTORY');
    assert.strictEqual(histBody.user_id, null);
    assert.strictEqual(histBody.appointments.length, 0);
    assert.strictEqual(histBody.tickets.length, 0);
  });

  console.log('\n================================================================================');
  console.log(`CUSTOMER SUITE FINISHED: ${passed} PASSED, ${failed} FAILED`);
  console.log('================================================================================\n');

  if (failed > 0) {
    process.exit(1);
  }
}

runCustomerSuite()
  .then(() => {
    console.log('Customer suite completed successfully.');
    process.exit(0);
  })
  .catch((err) => {
    console.error('Customer suite fatal error:', err);
    process.exit(1);
  });
