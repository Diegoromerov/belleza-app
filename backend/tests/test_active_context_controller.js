// backend/tests/test_active_context_controller.js
const assert = require('assert');
const { activateContext, getActiveContext } = require('../src/controllers/activeContextController');
const { activeContextMiddleware } = require('../src/middleware/activeContextMiddleware');
const { pool } = require('../src/config/db');

async function runControllerAndMiddlewareSuite() {
  console.log('================================================================================');
  console.log('      ACTIVE CONTEXT v1.0 — CONTROLLER & MIDDLEWARE TEST SUITE');
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

  // Get active membership for user 7
  const client = await pool.connect();
  let activeMembershipId;
  try {
    await client.query("SELECT set_config('app.tenant_id', '2', false);");
    const mRes = await client.query('SELECT id FROM memberships WHERE user_id = 7 AND status = $1 LIMIT 1', ['ACTIVE']);
    activeMembershipId = mRes.rows[0].id;
  } finally {
    client.release();
  }

  // Helper mock for Express req, res
  function createMockReqRes(options = {}) {
    const req = {
      user: options.user !== undefined ? options.user : { id: 7, email: 'demo@beautyapp.com' },
      headers: options.headers || {},
      body: options.body || {},
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
    };

    return {
      req,
      res,
      getStatus: () => statusCode,
      getBody: () => jsonBody,
    };
  }

  console.log('[TEST GROUP: Controller (activateContext & getActiveContext)]');

  // Test 1: activateContext without user returns 401
  await test('Controller 1: activateContext without auth user returns 401', async () => {
    const { req, res, getStatus, getBody } = createMockReqRes({ user: null });
    await activateContext(req, res);
    assert.strictEqual(getStatus(), 401);
    assert.strictEqual(getBody().error, 'IDENTITY_NOT_FOUND');
  });

  // Test 2: activateContext without membership_id returns 400
  await test('Controller 2: activateContext without membership_id returns 400', async () => {
    const { req, res, getStatus, getBody } = createMockReqRes({ body: {} });
    await activateContext(req, res);
    assert.strictEqual(getStatus(), 400);
    assert.strictEqual(getBody().error, 'MEMBERSHIP_SELECTION_REQUIRED');
  });

  // Test 3: activateContext with membership_id in body but missing header returns 400 (ARCH-AC-001)
  await test('Controller 3: activateContext with membership_id in body but missing header is rejected (400)', async () => {
    const { req, res, getStatus, getBody } = createMockReqRes({
      headers: {},
      body: { membership_id: activeMembershipId }
    });
    await activateContext(req, res);
    assert.strictEqual(getStatus(), 400);
    assert.strictEqual(getBody().error, 'MEMBERSHIP_SELECTION_REQUIRED');
  });

  // Test 4: activateContext with valid header x-active-membership-id returns 200
  await test('Controller 4: activateContext with valid x-active-membership-id header returns 200', async () => {
    const { req, res, getStatus, getBody } = createMockReqRes({
      headers: { 'x-active-membership-id': activeMembershipId }
    });
    await activateContext(req, res);
    assert.strictEqual(getStatus(), 200);
    assert.strictEqual(getBody().status, 'success');
    assert.strictEqual(getBody().data.active_context.active_membership_id, activeMembershipId);
  });

  console.log('\n[TEST GROUP: Middleware (activeContextMiddleware)]');

  // Test 5: activeContextMiddleware without header returns 400
  await test('Middleware 1: Missing x-active-membership-id header returns 400', async () => {
    const { req, res, getStatus, getBody } = createMockReqRes({ headers: {} });
    let nextCalled = false;
    await activeContextMiddleware(req, res, () => { nextCalled = true; });
    assert.strictEqual(nextCalled, false);
    assert.strictEqual(getStatus(), 400);
    assert.strictEqual(getBody().error, 'MISSING_ACTIVE_MEMBERSHIP_HEADER');
  });

  // Test 6: activeContextMiddleware with invalid UUID returns 400
  await test('Middleware 2: Malformed x-active-membership-id header returns 400', async () => {
    const { req, res, getStatus, getBody } = createMockReqRes({
      headers: { 'x-active-membership-id': 'bad-uuid-123' }
    });
    let nextCalled = false;
    await activeContextMiddleware(req, res, () => { nextCalled = true; });
    assert.strictEqual(nextCalled, false);
    assert.strictEqual(getStatus(), 400);
    assert.strictEqual(getBody().error, 'INVALID_MEMBERSHIP_UUID');
  });

  // Test 7: activeContextMiddleware with valid header attaches req.activeContext and calls next()
  await test('Middleware 3: Valid x-active-membership-id attaches active context and calls next()', async () => {
    const { req, res } = createMockReqRes({
      headers: { 'x-active-membership-id': activeMembershipId }
    });
    let nextCalled = false;
    await activeContextMiddleware(req, res, () => { nextCalled = true; });
    assert.strictEqual(nextCalled, true);
    assert.ok(req.activeContext);
    assert.strictEqual(req.activeContext.active_membership_id, activeMembershipId);
    assert.strictEqual(req.tenantId, 2);
    assert.strictEqual(req.membershipId, activeMembershipId);
  });

  console.log('\n================================================================================');
  console.log(`TOTAL PRUEBAS EJECUTADAS : ${passed + failed}`);
  console.log(`PRUEBAS PASADAS          : ${passed} 🟢`);
  console.log(`PRUEBAS FALLIDAS         : ${failed} 🔴`);
  console.log('================================================================================');

  if (failed > 0) {
    process.exit(1);
  } else {
    console.log('ESTADO: SUITE CONTROLLER & MIDDLEWARE 100% PASS 🟢\n');
  }
}

runControllerAndMiddlewareSuite()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Fatal test error:', err);
    process.exit(1);
  });
