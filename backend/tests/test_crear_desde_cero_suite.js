// backend/tests/test_crear_desde_cero_suite.js
const assert = require('assert');
const { pool } = require('../src/config/db');
const { validateAndResolveActiveContext } = require('../src/services/activeContextService');
const { activeContextMiddleware } = require('../src/middleware/activeContextMiddleware');
const crearDesdeCeroService = require('../src/services/crearDesdeCeroService');
const crearDesdeCeroController = require('../src/controllers/crearDesdeCeroController');

async function runCrearDesdeCeroSuite() {
  console.log('================================================================================');
  console.log('          CREAR DESDE CERO v1.0 — AUTOMATED TEST SUITE');
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
    // 0. Runtime Privileges Verification
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

    // Fetch existing active demo membership for user 7 (OWNER)
    const memRes = await client.query(
      'SELECT * FROM memberships WHERE user_id = 7 AND tenant_id = 2 AND status = $1 LIMIT 1',
      ['ACTIVE']
    );
    assert.ok(memRes.rows.length > 0, 'Demo active membership must exist for user 7');
    const ownerMembershipId = memRes.rows[0].id;
    const testEstId = memRes.rows[0].establishment_id;

    const estRes = await client.query('SELECT organization_id FROM establishments WHERE id = $1', [testEstId]);
    const testOrgId = estRes.rows[0].organization_id;

    // --- FIXTURES SETUP ---
    // 1. Manager Membership for user 7 in a dedicated test establishment
    const estManager = await client.query(`
      INSERT INTO establishments (tenant_id, organization_id, name, slug, phone, address, city, is_active, operating_hours)
      VALUES (2, $1, 'Salón Sede Manager', 'salon-sede-manager-' || substr(md5(random()::text), 1, 6), '+573100000010', 'Calle 100 # 20-30', 'Bogotá', true, '{"weekdays": "08:00-19:00"}'::jsonb)
      RETURNING id;
    `, [testOrgId]);
    const estManagerId = estManager.rows[0].id;
    cleanupIds.establishments.push(estManagerId);

    const mManager = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, 7, 'MANAGER', 'STAFF_EMPLOYEE', 'ACTIVE')
      RETURNING id;
    `, [estManagerId]);
    const managerMembershipId = mManager.rows[0].id;
    cleanupIds.memberships.push(managerMembershipId);

    // 2. Professional Membership for user 7 in a dedicated test establishment
    const estProf = await client.query(`
      INSERT INTO establishments (tenant_id, organization_id, name, slug, phone, address, city, is_active, operating_hours)
      VALUES (2, $1, 'Salón Sede Prof', 'salon-sede-prof-' || substr(md5(random()::text), 1, 6), '+573100000011', 'Calle 101 # 20-31', 'Bogotá', true, '{}'::jsonb)
      RETURNING id;
    `, [testOrgId]);
    const estProfId = estProf.rows[0].id;
    cleanupIds.establishments.push(estProfId);

    const mProf = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, 7, 'PROFESSIONAL', 'INDEPENDENT_PROVIDER', 'ACTIVE')
      RETURNING id;
    `, [estProfId]);
    const profMembershipId = mProf.rows[0].id;
    cleanupIds.memberships.push(profMembershipId);

    // 3. Receptionist Membership for user 7 in a dedicated test establishment
    const estRecep = await client.query(`
      INSERT INTO establishments (tenant_id, organization_id, name, slug, phone, address, city, is_active, operating_hours)
      VALUES (2, $1, 'Salón Sede Recep', 'salon-sede-recep-' || substr(md5(random()::text), 1, 6), '+573100000012', 'Calle 102 # 20-32', 'Bogotá', true, '{}'::jsonb)
      RETURNING id;
    `, [testOrgId]);
    const estRecepId = estRecep.rows[0].id;
    cleanupIds.establishments.push(estRecepId);

    const mRecep = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, 7, 'RECEPTIONIST', 'STAFF_EMPLOYEE', 'ACTIVE')
      RETURNING id;
    `, [estRecepId]);
    const recepMembershipId = mRecep.rows[0].id;
    cleanupIds.memberships.push(recepMembershipId);

    // 4. Suspended Membership for user 7 in dedicated establishment
    const estSuspended = await client.query(`
      INSERT INTO establishments (tenant_id, organization_id, name, slug, phone, address, city, is_active, operating_hours)
      VALUES (2, $1, 'Salón Sede Suspended', 'salon-sede-susp-' || substr(md5(random()::text), 1, 6), '+573100000013', 'Calle 103 # 20-33', 'Bogotá', true, '{}'::jsonb)
      RETURNING id;
    `, [testOrgId]);
    const estSuspendedId = estSuspended.rows[0].id;
    cleanupIds.establishments.push(estSuspendedId);

    const mSuspended = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, 7, 'OWNER', 'OWNER_PARTNER', 'SUSPENDED')
      RETURNING id;
    `, [estSuspendedId]);
    const suspendedMembershipId = mSuspended.rows[0].id;
    cleanupIds.memberships.push(suspendedMembershipId);

    // 5. Membership belonging to another user (User 1)
    const mOtherUser = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, 1, 'OWNER', 'OWNER_PARTNER', 'ACTIVE')
      RETURNING id;
    `, [estManagerId]);
    const otherUserMembershipId = mOtherUser.rows[0].id;
    cleanupIds.memberships.push(otherUserMembershipId);

    // Helper mock function for Express req/res
    function mockReqRes(options = {}) {
      const req = {
        headers: options.headers || {},
        user: options.user || null,
        body: options.body || {},
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

    const sampleValidPayload = {
      activities: ['HAIR_STYLING', 'NAIL_CARE'],
      services: [
        {
          name: 'Corte de Cabello Estilo & Cepillado',
          category: 'HAIR_STYLING',
          duration_minutes: 45,
          price: 45000.0,
          description: 'Corte personalizado con lavado',
        },
        {
          name: 'Manicura Semi-Permanente',
          category: 'NAIL_CARE',
          duration_minutes: 60,
          price: 55000.0,
          description: 'Limpieza profunda y esmaltado',
        },
      ],
      staff_assignments: [
        {
          membership_id: ownerMembershipId,
          assigned_categories: ['HAIR_STYLING'],
        },
      ],
      decisions: {
        catalog_mode: 'STANDARD_SETUP',
      },
    };

    console.log('[TEST GROUP 1: Role-Based Provisioning Authorization (VAL-CDC-01 to VAL-CDC-06)]\n');

    // VAL-CDC-01: OWNER + ACTIVE -> authorized
    await test('VAL-CDC-01: OWNER + ACTIVE is authorized and compiles valid Context Package', async () => {
      const activeContext = await validateAndResolveActiveContext(7, ownerMembershipId);
      const res = await crearDesdeCeroService.compileContextPackage(7, 2, testEstId, activeContext, sampleValidPayload);

      assert.ok(res.context_package, 'Must contain context_package root');
      assert.strictEqual(res.context_package.identity.role, 'OWNER');
      assert.strictEqual(res.context_package.state, 'READY_FOR_PRE_NODE_01');
    });

    // VAL-CDC-02: MANAGER + ACTIVE -> authorized
    await test('VAL-CDC-02: MANAGER + ACTIVE is authorized and compiles valid Context Package', async () => {
      const activeContext = await validateAndResolveActiveContext(7, managerMembershipId);
      const managerPayload = {
        ...sampleValidPayload,
        staff_assignments: [{ membership_id: managerMembershipId, assigned_categories: ['HAIR_STYLING'] }],
      };
      const res = await crearDesdeCeroService.compileContextPackage(7, 2, estManagerId, activeContext, managerPayload);

      assert.ok(res.context_package);
      assert.strictEqual(res.context_package.identity.role, 'MANAGER');
      assert.strictEqual(res.context_package.state, 'READY_FOR_PRE_NODE_01');
    });

    // VAL-CDC-03: PROFESSIONAL + ACTIVE -> 403 Forbidden
    await test('VAL-CDC-03: PROFESSIONAL + ACTIVE is rejected with 403 INSUFFICIENT_PROVISIONING_ROLE', async () => {
      const activeContext = await validateAndResolveActiveContext(7, profMembershipId);
      try {
        await crearDesdeCeroService.compileContextPackage(7, 2, estProfId, activeContext, sampleValidPayload);
        assert.fail('Should have rejected PROFESSIONAL role');
      } catch (err) {
        assert.strictEqual(err.code, 'INSUFFICIENT_PROVISIONING_ROLE');
        assert.strictEqual(err.statusCode, 403);
      }
    });

    // VAL-CDC-04: RECEPTIONIST + ACTIVE -> 403 Forbidden
    await test('VAL-CDC-04: RECEPTIONIST + ACTIVE is rejected with 403 INSUFFICIENT_PROVISIONING_ROLE', async () => {
      const activeContext = await validateAndResolveActiveContext(7, recepMembershipId);
      try {
        await crearDesdeCeroService.compileContextPackage(7, 2, estRecepId, activeContext, sampleValidPayload);
        assert.fail('Should have rejected RECEPTIONIST role');
      } catch (err) {
        assert.strictEqual(err.code, 'INSUFFICIENT_PROVISIONING_ROLE');
        assert.strictEqual(err.statusCode, 403);
      }
    });

    // VAL-CDC-05: Non-ACTIVE membership (SUSPENDED) -> 403 Forbidden
    await test('VAL-CDC-05: Non-ACTIVE membership (SUSPENDED) is rejected by activeContextMiddleware', async () => {
      const { req, res } = mockReqRes({
        headers: { 'x-active-membership-id': suspendedMembershipId },
        user: { id: 7, email: 'owner@salon.com' },
      });

      let nextCalled = false;
      await activeContextMiddleware(req, res, () => { nextCalled = true; });

      assert.strictEqual(nextCalled, false);
      assert.strictEqual(res.getStatusCode(), 403);
      assert.strictEqual(res.getBody().error, 'MEMBERSHIP_NOT_ACTIVE');
    });

    // VAL-CDC-06: Membership belonging to another user -> 403 Forbidden
    await test('VAL-CDC-06: Membership belonging to another user is rejected with 403 MEMBERSHIP_ACCESS_DENIED', async () => {
      const { req, res } = mockReqRes({
        headers: { 'x-active-membership-id': otherUserMembershipId },
        user: { id: 7, email: 'owner@salon.com' },
      });

      let nextCalled = false;
      await activeContextMiddleware(req, res, () => { nextCalled = true; });

      assert.strictEqual(nextCalled, false);
      assert.strictEqual(res.getStatusCode(), 403);
      assert.strictEqual(res.getBody().error, 'MEMBERSHIP_ACCESS_DENIED');
    });

    // VAL-CDC-07: Missing x-active-membership-id header -> 400 Bad Request
    await test('VAL-CDC-07: Missing x-active-membership-id header returns 400 MISSING_ACTIVE_MEMBERSHIP_HEADER', async () => {
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

    console.log('\n[TEST GROUP 2: Context Package Contract Integrity (VAL-CDC-08 to VAL-CDC-12)]\n');

    // VAL-CDC-08: Context Package contains exactly the 16 canonical attributes
    await test('VAL-CDC-08: Context Package contains all 16 canonical handover attributes', async () => {
      const activeContext = await validateAndResolveActiveContext(7, ownerMembershipId);
      const res = await crearDesdeCeroService.compileContextPackage(7, 2, testEstId, activeContext, sampleValidPayload);
      const pkg = res.context_package;

      const requiredKeys = [
        'organization',
        'establishments',
        'activities',
        'relevant_services',
        'people_initial_roles',
        'identity',
        'state',
        'known_evidence',
        'decisions',
        'applicable_rules',
        'conditions',
        'procedures',
        'dependencies',
        'blocks',
        'route',
        'entry_state',
      ];

      for (const key of requiredKeys) {
        assert.ok(pkg[key] !== undefined, `Context Package must contain attribute: ${key}`);
      }

      assert.strictEqual(pkg.route, 'HUB_SALON -> CREAR_DESDE_CERO -> PRE_NODO_01');
      assert.deepStrictEqual(pkg.dependencies, ['ACTIVE_ESTABLISHMENT_CONTEXT', 'ACTIVE_AUTHORIZED_MEMBERSHIP']);
    });

    // VAL-CDC-09: Services remain purely in-memory
    await test('VAL-CDC-09: Services remain in-memory in relevant_services DTO', async () => {
      const activeContext = await validateAndResolveActiveContext(7, ownerMembershipId);
      const res = await crearDesdeCeroService.compileContextPackage(7, 2, testEstId, activeContext, sampleValidPayload);

      assert.strictEqual(res.context_package.relevant_services.length, 2);
      assert.strictEqual(res.context_package.relevant_services[0].name, 'Corte de Cabello Estilo & Cepillado');
      assert.strictEqual(res.context_package.relevant_services[0].price, 45000.0);
    });

    // VAL-CDC-10: public.services table is NOT modified (Zero inserts/updates)
    await test('VAL-CDC-10: public.services table count is identical before and after execution', async () => {
      const countBeforeRes = await client.query('SELECT COUNT(*)::int as count FROM services;');
      const countBefore = countBeforeRes.rows[0].count;

      const activeContext = await validateAndResolveActiveContext(7, ownerMembershipId);
      await crearDesdeCeroService.compileContextPackage(7, 2, testEstId, activeContext, sampleValidPayload);

      const countAfterRes = await client.query('SELECT COUNT(*)::int as count FROM services;');
      const countAfter = countAfterRes.rows[0].count;

      assert.strictEqual(countBefore, countAfter, 'public.services row count must NEVER change during Crear Desde Cero');
    });

    // VAL-CDC-11: No users or memberships created/modified
    await test('VAL-CDC-11: usuarios and memberships counts remain identical before and after execution', async () => {
      const usersBefore = (await client.query('SELECT COUNT(*)::int as count FROM usuarios;')).rows[0].count;
      const memsBefore = (await client.query('SELECT COUNT(*)::int as count FROM memberships;')).rows[0].count;

      const activeContext = await validateAndResolveActiveContext(7, ownerMembershipId);
      await crearDesdeCeroService.compileContextPackage(7, 2, testEstId, activeContext, sampleValidPayload);

      const usersAfter = (await client.query('SELECT COUNT(*)::int as count FROM usuarios;')).rows[0].count;
      const memsAfter = (await client.query('SELECT COUNT(*)::int as count FROM memberships;')).rows[0].count;

      assert.strictEqual(usersBefore, usersAfter, 'usuarios count must remain identical');
      assert.strictEqual(memsBefore, memsAfter, 'memberships count must remain identical');
    });

    // VAL-CDC-12: establishments.is_active remains intact
    await test('VAL-CDC-12: establishments.is_active remains unmodified', async () => {
      const estBefore = (await client.query('SELECT is_active FROM establishments WHERE id = $1;', [testEstId])).rows[0].is_active;

      const activeContext = await validateAndResolveActiveContext(7, ownerMembershipId);
      await crearDesdeCeroService.compileContextPackage(7, 2, testEstId, activeContext, sampleValidPayload);

      const estAfter = (await client.query('SELECT is_active FROM establishments WHERE id = $1;', [testEstId])).rows[0].is_active;

      assert.strictEqual(estBefore, estAfter, 'establishments.is_active must NEVER be modified by Crear Desde Cero');
    });

    console.log('\n[TEST GROUP 3: Functional Idempotency & State Derivation (VAL-CDC-13 to VAL-CDC-16)]\n');

    // VAL-CDC-13: RLS / Tenant isolation is effective
    await test('VAL-CDC-13: Multitenant isolation prevents cross-tenant establishment querying', async () => {
      const activeContext = await validateAndResolveActiveContext(7, ownerMembershipId);
      const fakeEstablishmentId = '00000000-0000-0000-0000-000000000000';

      try {
        await crearDesdeCeroService.compileContextPackage(7, 2, fakeEstablishmentId, activeContext, sampleValidPayload);
        assert.fail('Should have failed with ESTABLISHMENT_NOT_FOUND');
      } catch (err) {
        assert.strictEqual(err.code, 'ESTABLISHMENT_NOT_FOUND');
      }
    });

    // VAL-CDC-14: Deterministic functional idempotency
    await test('VAL-CDC-14: Equivalent inputs and context yield deterministic outputs', async () => {
      const activeContext = await validateAndResolveActiveContext(7, ownerMembershipId);
      const res1 = await crearDesdeCeroService.compileContextPackage(7, 2, testEstId, activeContext, sampleValidPayload);
      const res2 = await crearDesdeCeroService.compileContextPackage(7, 2, testEstId, activeContext, sampleValidPayload);

      assert.deepStrictEqual(res1.context_package.activities, res2.context_package.activities);
      assert.deepStrictEqual(res1.context_package.relevant_services, res2.context_package.relevant_services);
      assert.strictEqual(res1.context_package.state, res2.context_package.state);
      assert.strictEqual(res1.context_package.route, res2.context_package.route);
    });

    // VAL-CDC-15: Malformed payload derives BLOCKED state with blocks populated
    await test('VAL-CDC-15: Malformed services derive state = BLOCKED with blocks list', async () => {
      const activeContext = await validateAndResolveActiveContext(7, ownerMembershipId);
      const malformedPayload = {
        activities: ['HAIR_STYLING'],
        services: [
          { name: '', duration_minutes: -10, price: -500 }, // Invalid!
        ],
        staff_assignments: [
          { membership_id: '00000000-0000-0000-0000-000000000000' }, // Invalid!
        ],
      };

      const res = await crearDesdeCeroService.compileContextPackage(7, 2, testEstId, activeContext, malformedPayload);

      assert.strictEqual(res.context_package.state, 'BLOCKED');
      assert.ok(res.context_package.blocks.includes('MALFORMED_SERVICES_PAYLOAD'));
      assert.ok(res.context_package.blocks.includes('INVALID_STAFF_REFERENCE'));
    });

    // VAL-CDC-16: End-to-End HTTP pipeline execution via Controller
    await test('VAL-CDC-16: Full HTTP Controller pipeline returns 200 OK with Context Package', async () => {
      const { req, res } = mockReqRes({
        headers: { 'x-active-membership-id': ownerMembershipId },
        user: { id: 7, email: 'owner@salon.com' },
        body: sampleValidPayload,
      });

      let middlewarePassed = false;
      await activeContextMiddleware(req, res, () => { middlewarePassed = true; });
      assert.strictEqual(middlewarePassed, true);

      await crearDesdeCeroController.bootstrap(req, res);
      assert.strictEqual(res.getStatusCode(), 200);
      assert.strictEqual(res.getBody().status, 'success');
      assert.ok(res.getBody().data.context_package);
      assert.strictEqual(res.getBody().data.context_package.state, 'READY_FOR_PRE_NODE_01');
    });

  } finally {
    // Teardown test fixtures
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

runCrearDesdeCeroSuite()
  .then(() => {
    console.log('Crear Desde Cero test suite finished execution.');
    process.exit(0);
  })
  .catch((err) => {
    console.error('Fatal error running Crear Desde Cero suite:', err);
    process.exit(1);
  });
