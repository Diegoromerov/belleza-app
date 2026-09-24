// backend/tests/test_hub_salon_suite.js
const assert = require('assert');
const { pool } = require('../src/config/db');
const { validateAndResolveActiveContext } = require('../src/services/activeContextService');
const { activeContextMiddleware } = require('../src/middleware/activeContextMiddleware');
const hubSalonService = require('../src/services/hubSalonService');
const hubSalonController = require('../src/controllers/hubSalonController');

async function runHubSalonSuite() {
  console.log('================================================================================');
  console.log('              HUB SALÓN v1.0 — AUTOMATED TEST SUITE');
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

  const client = await pool.connect();
  const cleanupIds = {
    establishments: [],
    memberships: [],
  };

  try {
    // 0. Runtime Identity & Privilege Verification
    const roleRes = await client.query('SELECT rolname, rolsuper, rolbypassrls FROM pg_roles WHERE rolname = current_user;');
    console.log('[Runtime Privileges]:', roleRes.rows[0]);
    if (roleRes.rows[0].rolsuper !== false || roleRes.rows[0].rolbypassrls !== false) {
      throw new Error('FATAL: Runtime user is superuser or bypasses RLS!');
    }

    // Resolve test identity 7 -> tenant 2 via SECURITY DEFINER function
    const tenantRes = await client.query('SELECT fn_resolve_user_tenant(7) AS tenant_id;');
    const testTenantId = tenantRes.rows[0].tenant_id;
    assert.strictEqual(testTenantId, 2, 'Seed user 7 must belong to Tenant 2');

    // Establish Tenant Context for setup client
    await client.query("SELECT set_config('app.tenant_id', '2', false);");

    // Fetch existing active demo membership for user 7
    const memRes = await client.query(
      'SELECT * FROM memberships WHERE user_id = 7 AND tenant_id = 2 AND status = $1 LIMIT 1',
      ['ACTIVE']
    );
    assert.ok(memRes.rows.length > 0, 'Demo active membership must exist for user 7');
    const activeMembershipId = memRes.rows[0].id;
    const testEstId = memRes.rows[0].establishment_id;

    const estRes = await client.query('SELECT organization_id FROM establishments WHERE id = $1', [testEstId]);
    const testOrgId = estRes.rows[0].organization_id;

    // --- FIXTURES SETUP ---
    // Fixture 1: Second establishment for isolation test (Establishment B)
    const estBRes = await client.query(`
      INSERT INTO establishments (tenant_id, organization_id, name, slug, phone, address, city, is_active, operating_hours)
      VALUES (2, $1, 'Salón Sede Norte', 'salon-sede-norte-' || substr(md5(random()::text), 1, 6), '+573110000002', 'Calle 140 # 15-20', 'Bogotá', true, '{"monday": "09:00-18:00"}'::jsonb)
      RETURNING id;
    `, [testOrgId]);
    const estBId = estBRes.rows[0].id;
    cleanupIds.establishments.push(estBId);

    // Staff in Establishment B (user 7 as MANAGER in Est B)
    const memBRes = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, 7, 'MANAGER', 'STAFF_EMPLOYEE', 'ACTIVE')
      RETURNING id;
    `, [estBId]);
    const memBId = memBRes.rows[0].id;
    cleanupIds.memberships.push(memBId);

    // Staff in Establishment B (user 1 as PROFESSIONAL in Est B)
    const memB2Res = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, 1, 'PROFESSIONAL', 'INDEPENDENT_PROVIDER', 'ACTIVE')
      RETURNING id;
    `, [estBId]);
    cleanupIds.memberships.push(memB2Res.rows[0].id);

    // Fixture 2: Inactive Establishment (is_active = false)
    const estInactiveRes = await client.query(`
      INSERT INTO establishments (tenant_id, organization_id, name, slug, phone, address, city, is_active, operating_hours)
      VALUES (2, $1, 'Salón Sede Cerrada', 'salon-sede-cerrada-' || substr(md5(random()::text), 1, 6), '+573110000003', 'Carrera 7 # 45-10', 'Bogotá', false, '{"status": "closed_for_renovation"}'::jsonb)
      RETURNING id;
    `, [testOrgId]);
    const estInactiveId = estInactiveRes.rows[0].id;
    cleanupIds.establishments.push(estInactiveId);

    const memInactiveEstRes = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, 7, 'OWNER', 'OWNER_PARTNER', 'ACTIVE')
      RETURNING id;
    `, [estInactiveId]);
    const memInactiveEstId = memInactiveEstRes.rows[0].id;
    cleanupIds.memberships.push(memInactiveEstId);

    // Fixture 3: Other user membership (User 1) for anti-impersonation test
    const memOtherUserRes = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, 1, 'RECEPTIONIST', 'STAFF_EMPLOYEE', 'ACTIVE')
      RETURNING id;
    `, [testEstId]);
    const memOtherUserId = memOtherUserRes.rows[0].id;
    cleanupIds.memberships.push(memOtherUserId);

    // Helper mock function for Express req/res
    function mockReqRes(options = {}) {
      const req = {
        headers: options.headers || {},
        user: options.user || null,
        activeContext: options.activeContext || null,
        tenantId: options.tenantId || null,
        establishmentId: options.establishmentId || null,
        membershipId: options.membershipId || null,
      };

      let statusCode = 200;
      let responseBody = null;

      const res = {
        status: (code) => {
          statusCode = code;
          return res;
        },
        json: (body) => {
          responseBody = body;
          return res;
        },
        getStatusCode: () => statusCode,
        getBody: () => responseBody,
      };

      return { req, res };
    }

    console.log('[TEST GROUP: Formal Node Contract Validation (VAL-HUB-01 to VAL-HUB-08)]\n');

    // VAL-HUB-01: Summary with Active Context valid
    await test('VAL-HUB-01: GET /summary with valid Active Context returns 200 with full DTO', async () => {
      const activeContext = await validateAndResolveActiveContext(7, activeMembershipId);
      const summaryData = await hubSalonService.getHubSummary(2, testEstId, activeContext);

      assert.ok(summaryData.summary, 'Must contain summary root object');
      assert.strictEqual(summaryData.summary.establishment.id, testEstId);
      assert.ok(summaryData.summary.establishment.name, 'Establishment name must exist');
      assert.ok(summaryData.summary.establishment.slug, 'Establishment slug must exist');
      assert.strictEqual(summaryData.summary.establishment.is_active, true);
      assert.ok(summaryData.summary.establishment.operating_hours !== undefined, 'operating_hours must exist');
      assert.strictEqual(summaryData.summary.organization.id, testOrgId);
      assert.ok(summaryData.summary.organization.legal_name, 'Organization legal name must exist');
      assert.strictEqual(summaryData.summary.active_user_context.membership_id, activeMembershipId);
      assert.strictEqual(summaryData.summary.active_user_context.role, activeContext.role);
      assert.strictEqual(summaryData.summary.active_user_context.relation_type, activeContext.relation_type);
      assert.strictEqual(summaryData.summary.active_user_context.status, 'ACTIVE');
      assert.strictEqual(summaryData.summary.active_user_context.membership_status, undefined, 'membership_status must NOT be present in active_user_context');
      assert.ok(typeof summaryData.summary.staff_summary.active_members_count === 'number', 'Staff count must be a number');
      assert.ok(summaryData.summary.staff_summary.active_members_count >= 1, 'Must count at least 1 active member');
    });

    // VAL-HUB-02: Staff with Active Context valid
    await test('VAL-HUB-02: GET /staff with valid Active Context returns 200 with staff list', async () => {
      const staffData = await hubSalonService.getHubStaff(2, testEstId);

      assert.strictEqual(staffData.establishment_id, testEstId);
      assert.ok(typeof staffData.staff_count === 'number');
      assert.strictEqual(staffData.staff_count, staffData.members.length);
      assert.ok(staffData.members.length >= 1);

      const member = staffData.members.find((m) => m.membership_id === activeMembershipId);
      assert.ok(member, 'User 7 active membership must be in staff list');
      assert.strictEqual(member.user_id, 7);
      assert.ok(member.user_name, 'User name must be resolved from usuarios.nombre');
      assert.ok(member.user_email, 'User email must be resolved from usuarios.email');
      assert.ok(member.role, 'Role must exist');
      assert.ok(member.relation_type, 'Relation type must exist');
      assert.strictEqual(member.status, 'ACTIVE');
      assert.ok(member.joined_at, 'Joined timestamp must exist');
    });

    // VAL-HUB-03: Summary without x-active-membership-id header
    await test('VAL-HUB-03: GET /summary without x-active-membership-id returns 400 MISSING_ACTIVE_MEMBERSHIP_HEADER', async () => {
      const { req, res } = mockReqRes({
        headers: {},
        user: { id: 7, email: 'owner@salon.com' },
      });

      let nextCalled = false;
      await activeContextMiddleware(req, res, () => { nextCalled = true; });

      assert.strictEqual(nextCalled, false);
      assert.strictEqual(res.getStatusCode(), 400);
      assert.strictEqual(res.getBody().error, 'MISSING_ACTIVE_MEMBERSHIP_HEADER');
    });

    // VAL-HUB-04: Summary without authenticated identity
    await test('VAL-HUB-04: GET /summary without authenticated identity returns 401 IDENTITY_NOT_FOUND', async () => {
      const { req, res } = mockReqRes({
        headers: { 'x-active-membership-id': activeMembershipId },
        user: null,
      });

      let nextCalled = false;
      await activeContextMiddleware(req, res, () => { nextCalled = true; });

      assert.strictEqual(nextCalled, false);
      assert.strictEqual(res.getStatusCode(), 401);
      assert.strictEqual(res.getBody().error, 'IDENTITY_NOT_FOUND');
    });

    // VAL-HUB-05: Membership belonging to another user
    await test('VAL-HUB-05: Petición con membership ajena retorna 403 MEMBERSHIP_ACCESS_DENIED', async () => {
      const { req, res } = mockReqRes({
        headers: { 'x-active-membership-id': memOtherUserId }, // belongs to user 1
        user: { id: 7, email: 'user7@test.com' },
      });

      let nextCalled = false;
      await activeContextMiddleware(req, res, () => { nextCalled = true; });

      assert.strictEqual(nextCalled, false);
      assert.strictEqual(res.getStatusCode(), 403);
      assert.strictEqual(res.getBody().error, 'MEMBERSHIP_ACCESS_DENIED');
    });

    // VAL-HUB-06: Isolation between establishments
    await test('VAL-HUB-06: Aislamiento entre sedes (Sede A solo lista staff de Sede A; excluye Sede B)', async () => {
      const staffA = await hubSalonService.getHubStaff(2, testEstId);
      const staffB = await hubSalonService.getHubStaff(2, estBId);

      // Verify Sede B members
      const estBMemberIds = staffB.members.map((m) => m.membership_id);
      assert.ok(estBMemberIds.includes(memBId), 'Sede B must contain memBId');

      // Verify Sede A does NOT contain Sede B membership
      const estAMemberIds = staffA.members.map((m) => m.membership_id);
      assert.strictEqual(estAMemberIds.includes(memBId), false, 'Sede A must NEVER contain Sede B members');

      // Verify Sede B does NOT contain Sede A primary membership
      assert.strictEqual(estBMemberIds.includes(activeMembershipId), false, 'Sede B must NEVER contain Sede A members');
    });

    // VAL-HUB-07: Inactive establishment (is_active = false)
    await test('VAL-HUB-07: Sede inactiva (is_active = false) retorna 200 OK con establishment.is_active = false', async () => {
      const activeContextInactive = await validateAndResolveActiveContext(7, memInactiveEstId);
      const summaryData = await hubSalonService.getHubSummary(2, estInactiveId, activeContextInactive);

      assert.strictEqual(summaryData.summary.establishment.id, estInactiveId);
      assert.strictEqual(summaryData.summary.establishment.is_active, false);
      assert.deepStrictEqual(summaryData.summary.establishment.operating_hours, { status: 'closed_for_renovation' });
    });

    // VAL-HUB-08: Tenant isolation / RLS
    await test('VAL-HUB-08: Aislamiento RLS / multitenant (Tenant 2 cannot access non-existent/cross-tenant establishment)', async () => {
      const fakeEstablishmentId = '00000000-0000-0000-0000-000000000000';
      const fakeContext = {
        active_membership_id: activeMembershipId,
        role: 'OWNER',
        relation_type: 'OWNER_PARTNER',
        membership_status: 'ACTIVE',
      };

      try {
        await hubSalonService.getHubSummary(2, fakeEstablishmentId, fakeContext);
        assert.fail('Should have thrown ESTABLISHMENT_NOT_FOUND');
      } catch (err) {
        assert.strictEqual(err.code, 'ESTABLISHMENT_NOT_FOUND');
      }
    });

    console.log('\n[TEST GROUP: Controller & Middleware End-to-End Handlers]\n');

    // Controller summary success via middleware
    await test('E2E-HUB-01: Full HTTP pipeline for GET /api/v1/saas/hub/summary', async () => {
      const { req, res } = mockReqRes({
        headers: { 'x-active-membership-id': activeMembershipId },
        user: { id: 7, email: 'owner@salon.com' },
      });

      let middlewarePassed = false;
      await activeContextMiddleware(req, res, () => { middlewarePassed = true; });
      assert.strictEqual(middlewarePassed, true);

      await hubSalonController.getSummary(req, res);
      assert.strictEqual(res.getStatusCode(), 200);
      assert.strictEqual(res.getBody().status, 'success');
      assert.ok(res.getBody().data.summary);
      assert.strictEqual(res.getBody().data.summary.establishment.id, testEstId);
    });

    // Controller staff success via middleware
    await test('E2E-HUB-02: Full HTTP pipeline for GET /api/v1/saas/hub/staff', async () => {
      const { req, res } = mockReqRes({
        headers: { 'x-active-membership-id': activeMembershipId },
        user: { id: 7, email: 'owner@salon.com' },
      });

      let middlewarePassed = false;
      await activeContextMiddleware(req, res, () => { middlewarePassed = true; });
      assert.strictEqual(middlewarePassed, true);

      await hubSalonController.getStaff(req, res);
      assert.strictEqual(res.getStatusCode(), 200);
      assert.strictEqual(res.getBody().status, 'success');
      assert.ok(res.getBody().data.members);
      assert.strictEqual(res.getBody().data.establishment_id, testEstId);
    });

    // Controller error when activeContext is uninitialized
    await test('E2E-HUB-03: Controller returns 400 when activeContext is uninitialized', async () => {
      const { req, res } = mockReqRes({
        headers: {},
        user: { id: 7 },
      });

      await hubSalonController.getSummary(req, res);
      assert.strictEqual(res.getStatusCode(), 400);
      assert.strictEqual(res.getBody().error, 'ACTIVE_CONTEXT_NOT_INITIALIZED');

      const { req: req2, res: res2 } = mockReqRes({
        headers: {},
        user: { id: 7 },
      });

      await hubSalonController.getStaff(req2, res2);
      assert.strictEqual(res2.getStatusCode(), 400);
      assert.strictEqual(res2.getBody().error, 'ACTIVE_CONTEXT_NOT_INITIALIZED');
    });

  } finally {
    // Clean up test fixtures created in this test run
    console.log('\n[Teardown]: Cleaning up test fixtures...');
    try {
      await client.query("SELECT set_config('app.tenant_id', '2', false);");
      if (cleanupIds.memberships.length > 0) {
        await client.query('DELETE FROM memberships WHERE id = ANY($1::uuid[]);', [cleanupIds.memberships]);
      }
      if (cleanupIds.establishments.length > 0) {
        await client.query('DELETE FROM establishments WHERE id = ANY($1::uuid[]);', [cleanupIds.establishments]);
      }
      console.log('  ✓ Test fixtures cleaned up successfully.');
    } catch (cleanErr) {
      console.error('  ✗ Error during cleanup:', cleanErr.message);
    } finally {
      client.release();
    }
  }

  console.log('\n================================================================================');
  console.log(`TOTAL TESTS: ${passed + failed} | PASSED: ${passed} | FAILED: ${failed}`);
  console.log('================================================================================\n');

  if (failed > 0) {
    process.exit(1);
  }
}

runHubSalonSuite()
  .then(() => {
    console.log('Hub Salón test suite finished execution.');
    process.exit(0);
  })
  .catch((err) => {
    console.error('Fatal error running Hub Salón suite:', err);
    process.exit(1);
  });
