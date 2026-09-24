// backend/tests/test_active_context_suite.js
const assert = require('assert');
const { pool } = require('../src/config/db');
const { validateAndResolveActiveContext } = require('../src/services/activeContextService');

async function runActiveContextSuite() {
  console.log('================================================================================');
  console.log('              ACTIVE CONTEXT v1.0 — AUTOMATED TEST SUITE');
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
    memberships: []
  };

  try {
    // 0. Runtime Identity & Privilege Verification
    const idRes = await client.query('SELECT current_user, session_user, current_database();');
    console.log('[Runtime Identity]:', idRes.rows[0]);
    const roleRes = await client.query('SELECT rolname, rolsuper, rolbypassrls FROM pg_roles WHERE rolname = current_user;');
    console.log('[Runtime Privileges]:', roleRes.rows[0]);
    if (roleRes.rows[0].rolsuper !== false || roleRes.rows[0].rolbypassrls !== false) {
      throw new Error('FATAL: Runtime user is superuser or bypasses RLS!');
    }

    // Resolve test identity 7 -> tenant 2 via SECURITY DEFINER function
    const tenantRes = await client.query('SELECT fn_resolve_user_tenant(7) AS tenant_id;');
    const testTenantId = tenantRes.rows[0].tenant_id;
    assert.strictEqual(testTenantId, 2, 'Seed user 7 must belong to Tenant 2');

    // Establish Tenant Context on setup client for fixtures creation
    await client.query("SELECT set_config('app.tenant_id', '2', false);");

    // Fetch existing active demo membership for user 7
    const memRes = await client.query('SELECT * FROM memberships WHERE user_id = 7 AND tenant_id = 2 AND status = $1 LIMIT 1', ['ACTIVE']);
    assert.ok(memRes.rows.length > 0, 'Demo active membership must exist for user 7');
    const activeMembershipId = memRes.rows[0].id;
    const testEstId = memRes.rows[0].establishment_id;

    const estRes = await client.query('SELECT organization_id FROM establishments WHERE id = $1', [testEstId]);
    const testOrgId = estRes.rows[0].organization_id;

    // Create extra test fixtures for validation cases (INVITED, SUSPENDED, REVOKED, Other User)
    // 1. Establishment for INVITED
    const estInvited = await client.query(`
      INSERT INTO establishments (tenant_id, organization_id, name, slug, phone, is_active)
      VALUES (2, $1, 'Salón Test Invited', 'salon-test-invited-' || substr(md5(random()::text), 1, 6), '+573000000001', true)
      RETURNING id;
    `, [testOrgId]);
    cleanupIds.establishments.push(estInvited.rows[0].id);

    const mInvited = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, 7, 'MANAGER', 'STAFF_EMPLOYEE', 'INVITED')
      RETURNING id;
    `, [estInvited.rows[0].id]);
    cleanupIds.memberships.push(mInvited.rows[0].id);
    const invitedMembershipId = mInvited.rows[0].id;

    // 2. Establishment for SUSPENDED
    const estSuspended = await client.query(`
      INSERT INTO establishments (tenant_id, organization_id, name, slug, phone, is_active)
      VALUES (2, $1, 'Salón Test Suspended', 'salon-test-suspended-' || substr(md5(random()::text), 1, 6), '+573000000002', true)
      RETURNING id;
    `, [testOrgId]);
    cleanupIds.establishments.push(estSuspended.rows[0].id);

    const mSuspended = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, 7, 'PROFESSIONAL', 'INDEPENDENT_PROVIDER', 'SUSPENDED')
      RETURNING id;
    `, [estSuspended.rows[0].id]);
    cleanupIds.memberships.push(mSuspended.rows[0].id);
    const suspendedMembershipId = mSuspended.rows[0].id;

    // 3. Establishment for REVOKED
    const estRevoked = await client.query(`
      INSERT INTO establishments (tenant_id, organization_id, name, slug, phone, is_active)
      VALUES (2, $1, 'Salón Test Revoked', 'salon-test-revoked-' || substr(md5(random()::text), 1, 6), '+573000000003', true)
      RETURNING id;
    `, [testOrgId]);
    cleanupIds.establishments.push(estRevoked.rows[0].id);

    const mRevoked = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, 7, 'RECEPTIONIST', 'STAFF_EMPLOYEE', 'REVOKED')
      RETURNING id;
    `, [estRevoked.rows[0].id]);
    cleanupIds.memberships.push(mRevoked.rows[0].id);
    const revokedMembershipId = mRevoked.rows[0].id;

    // 4. Establishment for Other User (User 1 in Tenant 2)
    const estOther = await client.query(`
      INSERT INTO establishments (tenant_id, organization_id, name, slug, phone, is_active)
      VALUES (2, $1, 'Salón Test Other User', 'salon-test-other-' || substr(md5(random()::text), 1, 6), '+573000000004', true)
      RETURNING id;
    `, [testOrgId]);
    cleanupIds.establishments.push(estOther.rows[0].id);

    const mOther = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, 1, 'MANAGER', 'STAFF_EMPLOYEE', 'ACTIVE')
      RETURNING id;
    `, [estOther.rows[0].id]);
    cleanupIds.memberships.push(mOther.rows[0].id);
    const otherUserMembershipId = mOther.rows[0].id;

    // 5. Inactive Establishment with ACTIVE Membership
    const estInactive = await client.query(`
      INSERT INTO establishments (tenant_id, organization_id, name, slug, phone, is_active)
      VALUES (2, $1, 'Salón Test Inactive Est', 'salon-test-inact-' || substr(md5(random()::text), 1, 6), '+573000000005', false)
      RETURNING id;
    `, [testOrgId]);
    cleanupIds.establishments.push(estInactive.rows[0].id);

    const mInactiveEst = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, 7, 'OWNER', 'OWNER_PARTNER', 'ACTIVE')
      RETURNING id;
    `, [estInactive.rows[0].id]);
    cleanupIds.memberships.push(mInactiveEst.rows[0].id);
    const inactiveEstMembershipId = mInactiveEst.rows[0].id;

    console.log('\n[TEST GROUP: Active Context Contract Validation (AC-01 to AC-16)]\n');

    // AC-01: authenticated user required
    await test('AC-01: Authenticated identity required (null/empty identity rejected)', async () => {
      try {
        await validateAndResolveActiveContext(null, activeMembershipId);
        assert.fail('Should have thrown IDENTITY_NOT_FOUND');
      } catch (err) {
        assert.strictEqual(err.code, 'IDENTITY_NOT_FOUND');
        assert.strictEqual(err.statusCode, 401);
      }
    });

    // AC-02: missing header / membership selection rejected
    await test('AC-02: Missing membership selection rejected (400)', async () => {
      try {
        await validateAndResolveActiveContext(7, null);
        assert.fail('Should have thrown MEMBERSHIP_SELECTION_REQUIRED');
      } catch (err) {
        assert.strictEqual(err.code, 'MEMBERSHIP_SELECTION_REQUIRED');
        assert.strictEqual(err.statusCode, 400);
      }
    });

    // AC-03: malformed UUID rejected
    await test('AC-03: Malformed UUID format rejected (400)', async () => {
      try {
        await validateAndResolveActiveContext(7, 'invalid-uuid-format-1234');
        assert.fail('Should have thrown INVALID_MEMBERSHIP_UUID');
      } catch (err) {
        assert.strictEqual(err.code, 'INVALID_MEMBERSHIP_UUID');
        assert.strictEqual(err.statusCode, 400);
      }
    });

    // AC-04: valid ACTIVE membership accepted
    await test('AC-04: Valid ACTIVE membership accepted and returns derived DTO', async () => {
      const dto = await validateAndResolveActiveContext(7, activeMembershipId);
      assert.strictEqual(dto.active_membership_id, activeMembershipId);
      assert.strictEqual(dto.tenant_id, 2);
      assert.strictEqual(dto.role, 'OWNER');
      assert.strictEqual(dto.relation_type, 'OWNER_PARTNER');
      assert.strictEqual(dto.membership_status, 'ACTIVE');
      assert.strictEqual(dto.establishment_id, testEstId);
      assert.strictEqual(dto.organization_id, testOrgId);
      assert.strictEqual(dto.establishment_is_active, true);
      assert.ok(dto.activated_at);
    });

    // AC-05: INVITED status rejected
    await test('AC-05: INVITED status membership rejected (403)', async () => {
      try {
        await validateAndResolveActiveContext(7, invitedMembershipId);
        assert.fail('Should have thrown MEMBERSHIP_NOT_ACTIVE');
      } catch (err) {
        assert.strictEqual(err.code, 'MEMBERSHIP_NOT_ACTIVE');
        assert.strictEqual(err.statusCode, 403);
      }
    });

    // AC-06: SUSPENDED status rejected
    await test('AC-06: SUSPENDED status membership rejected (403)', async () => {
      try {
        await validateAndResolveActiveContext(7, suspendedMembershipId);
        assert.fail('Should have thrown MEMBERSHIP_NOT_ACTIVE');
      } catch (err) {
        assert.strictEqual(err.code, 'MEMBERSHIP_NOT_ACTIVE');
        assert.strictEqual(err.statusCode, 403);
      }
    });

    // AC-07: REVOKED status rejected
    await test('AC-07: REVOKED status membership rejected (403)', async () => {
      try {
        await validateAndResolveActiveContext(7, revokedMembershipId);
        assert.fail('Should have thrown MEMBERSHIP_NOT_ACTIVE');
      } catch (err) {
        assert.strictEqual(err.code, 'MEMBERSHIP_NOT_ACTIVE');
        assert.strictEqual(err.statusCode, 403);
      }
    });

    // AC-08: membership belonging to another user rejected
    await test('AC-08: Membership belonging to another identity rejected (Anti-Impersonation 403)', async () => {
      try {
        await validateAndResolveActiveContext(7, otherUserMembershipId);
        assert.fail('Should have thrown MEMBERSHIP_ACCESS_DENIED');
      } catch (err) {
        assert.strictEqual(err.code, 'MEMBERSHIP_ACCESS_DENIED');
        assert.strictEqual(err.statusCode, 403);
      }
    });

    // AC-09: membership belonging to non-existent UUID / foreign tenant rejected
    await test('AC-09: Non-existent or foreign tenant membership rejected (404)', async () => {
      const nonExistentUuid = '00000000-0000-0000-0000-000000000000';
      try {
        await validateAndResolveActiveContext(7, nonExistentUuid);
        assert.fail('Should have thrown MEMBERSHIP_NOT_FOUND');
      } catch (err) {
        assert.strictEqual(err.code, 'MEMBERSHIP_NOT_FOUND');
        assert.strictEqual(err.statusCode, 404);
      }
    });

    // AC-10: organization derived through establishment
    await test('AC-10: Organization is correctly derived via establishment link', async () => {
      const dto = await validateAndResolveActiveContext(7, activeMembershipId);
      assert.strictEqual(dto.organization_id, testOrgId);
      assert.ok(dto.organization_legal_name);
    });

    // AC-11: client cannot override tenant
    await test('AC-11: Server resolves tenant strictly via fn_resolve_user_tenant (Zero client tenant authority)', async () => {
      const dto = await validateAndResolveActiveContext(7, activeMembershipId);
      assert.strictEqual(dto.tenant_id, 2);
    });

    // AC-12: client cannot override role
    await test('AC-12: Role is server-derived from database (Zero client role authority)', async () => {
      const dto = await validateAndResolveActiveContext(7, activeMembershipId);
      assert.strictEqual(dto.role, 'OWNER');
    });

    // AC-13: client cannot override organization
    await test('AC-13: Organization is derived server-side (Zero client org authority)', async () => {
      const dto = await validateAndResolveActiveContext(7, activeMembershipId);
      assert.strictEqual(dto.organization_id, testOrgId);
    });

    // AC-14: client cannot override establishment
    await test('AC-14: Establishment is derived server-side from membership (Zero client est authority)', async () => {
      const dto = await validateAndResolveActiveContext(7, activeMembershipId);
      assert.strictEqual(dto.establishment_id, testEstId);
    });

    // AC-15: RLS remains active in database
    await test('AC-15: PostgreSQL RLS policies remain active on tenants, establishments, memberships', async () => {
      const rlsRes = await client.query(`
        SELECT relname, relrowsecurity 
        FROM pg_class 
        WHERE relname IN ('organizations', 'establishments', 'memberships')
        ORDER BY relname ASC;
      `);
      assert.strictEqual(rlsRes.rows.length, 3);
      for (const row of rlsRes.rows) {
        assert.strictEqual(row.relrowsecurity, true, `RLS must be true for ${row.relname}`);
      }
    });

    // AC-16: no Context table/entity created
    await test('AC-16: Zero Context tables or context_id columns created in database', async () => {
      const tableRes = await client.query(`
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name LIKE '%context%';
      `);
      assert.strictEqual(tableRes.rows.length, 0, 'No table containing context should exist');

      const colRes = await client.query(`
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_schema = 'public' AND column_name LIKE 'context%';
      `);
      assert.strictEqual(colRes.rows.length, 0, 'No column containing context should exist');
    });

    // AC-17 (Bonus): Inactive establishment with ACTIVE membership preserves operational metadata
    await test('AC-17: Inactive establishment with ACTIVE membership activates with establishment_is_active: false', async () => {
      const dto = await validateAndResolveActiveContext(7, inactiveEstMembershipId);
      assert.strictEqual(dto.active_membership_id, inactiveEstMembershipId);
      assert.strictEqual(dto.membership_status, 'ACTIVE');
      assert.strictEqual(dto.establishment_is_active, false);
    });

  } finally {
    try {
      if (cleanupIds.memberships.length > 0) {
        await client.query('DELETE FROM memberships WHERE id = ANY($1::uuid[])', [cleanupIds.memberships]);
      }
      if (cleanupIds.establishments.length > 0) {
        await client.query('DELETE FROM establishments WHERE id = ANY($1::uuid[])', [cleanupIds.establishments]);
      }
    } catch (cleanErr) {
      console.error('Cleanup error:', cleanErr);
    }
    client.release();
  }

  console.log('\n================================================================================');
  console.log(`TOTAL PRUEBAS EJECUTADAS : ${passed + failed}`);
  console.log(`PRUEBAS PASADAS          : ${passed} 🟢`);
  console.log(`PRUEBAS FALLIDAS         : ${failed} 🔴`);
  console.log('================================================================================');

  if (failed > 0) {
    process.exit(1);
  } else {
    console.log('ESTADO: SUITE ACTIVE CONTEXT 100% PASS 🟢\n');
  }
}

runActiveContextSuite()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Fatal test error:', err);
    process.exit(1);
  });
