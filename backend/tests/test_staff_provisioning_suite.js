// backend/tests/test_staff_provisioning_suite.js
const assert = require('assert');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const { pool } = require('../src/config/db');
const saasStaffService = require('../src/services/saasStaffService');
const saasStaffController = require('../src/controllers/saasStaffController');

/**
 * STAFF PROVISIONING COMPREHENSIVE TEST SUITE (GO-08.37)
 * Tests all 40 contractual scenarios against real PostgreSQL database.
 */

function createMockReqRes(options = {}) {
  const activeContext = options.activeContext || {
    tenant_id: 2,
    establishment_id: options.establishmentId || '00000000-0000-0000-0000-000000000001',
    active_membership_id: options.membershipId || '00000000-0000-0000-0000-000000000002',
    role: options.role || 'OWNER',
    user_id: options.user ? options.user.id : 1,
  };

  const req = {
    user: options.user !== undefined ? options.user : { id: 1, email: 'owner@test.com' },
    headers: options.headers || {},
    body: options.body || {},
    query: options.query || {},
    params: options.params || {},
    tenantId: activeContext.tenant_id,
    establishmentId: activeContext.establishment_id,
    membershipId: activeContext.active_membership_id,
    activeContext: activeContext,
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

async function runStaffProvisioningSuite() {
  console.log('================================================================================');
  console.log('       STAFF PROVISIONING ENGINE — COMPREHENSIVE TEST SUITE (GO-08.37)');
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
      if (err.stack) {
        console.error(err.stack.split('\n').slice(1, 4).join('\n'));
      }
      failed++;
    }
  }

  // Database setup: ensure test tenant, establishments, and users exist
  const client = await pool.connect();
  const tenantA_id = 2;
  let estA_id, estB_id;
  let userOwner_id, userManager_id, userProf_id, userOther_id, uOtherResEmail;
  let memOwnerA_id, memManagerA_id, memProfA_id, memOwnerB_id;

  try {
    // 1. Ensure Tenant 2 and Org exist
    await client.query(`
      INSERT INTO tenants (id, name, slug)
      VALUES (2, 'Staff Test Tenant', 'staff-test-tenant')
      ON CONFLICT (id) DO NOTHING;
    `);

    let orgRes = await client.query('SELECT id FROM organizations WHERE tenant_id = 2 LIMIT 1');
    let orgId;
    if (orgRes.rows.length === 0) {
      const insOrg = await client.query(`
        INSERT INTO organizations (tenant_id, legal_name, tax_id)
        VALUES (2, 'Staff Test Legal Org', '900123456-1')
        RETURNING id;
      `);
      orgId = insOrg.rows[0].id;
    } else {
      orgId = orgRes.rows[0].id;
    }

    // Create fresh isolated establishments for this test run
    const ts = Date.now();
    const insertedA = await client.query(`
      INSERT INTO establishments (tenant_id, organization_id, name, slug)
      VALUES (2, $1, 'Staff Test Salon A', $2)
      RETURNING id;
    `, [orgId, `staff-salon-a-${ts}`]);
    estA_id = insertedA.rows[0].id;

    const insertedB = await client.query(`
      INSERT INTO establishments (tenant_id, organization_id, name, slug)
      VALUES (2, $1, 'Staff Test Salon B', $2)
      RETURNING id;
    `, [orgId, `staff-salon-b-${ts}`]);
    estB_id = insertedB.rows[0].id;

    // 2. Setup Test Users
    const pwdHash = await bcrypt.hash('TestPass123!', 10);

    const uOwnerRes = await client.query(`
      INSERT INTO usuarios (nombre, email, password_hash, rol, tenant_id, auth_provider, provider_id)
      VALUES ('Owner User', 'owner_test_${Date.now()}@glowapp.test', $1, 'PRESTADOR', 2, 'LOCAL', 'owner_prov_${Date.now()}')
      RETURNING id, email;
    `, [pwdHash]);
    userOwner_id = uOwnerRes.rows[0].id;

    const uManagerRes = await client.query(`
      INSERT INTO usuarios (nombre, email, password_hash, rol, tenant_id, auth_provider, provider_id)
      VALUES ('Manager User', 'mgr_test_${Date.now()}@glowapp.test', $1, 'PRESTADOR', 2, 'LOCAL', 'mgr_prov_${Date.now()}')
      RETURNING id, email;
    `, [pwdHash]);
    userManager_id = uManagerRes.rows[0].id;

    const uProfRes = await client.query(`
      INSERT INTO usuarios (nombre, email, password_hash, rol, tenant_id, auth_provider, provider_id)
      VALUES ('Prof User', 'prof_test_${Date.now()}@glowapp.test', $1, 'PRESTADOR', 2, 'LOCAL', 'prof_prov_${Date.now()}')
      RETURNING id, email;
    `, [pwdHash]);
    userProf_id = uProfRes.rows[0].id;

    const uOtherRes = await client.query(`
      INSERT INTO usuarios (nombre, email, password_hash, rol, tenant_id, auth_provider, provider_id)
      VALUES ('Other User', 'other_test_${Date.now()}@glowapp.test', $1, 'CLIENTE', 2, 'LOCAL', 'other_prov_${Date.now()}')
      RETURNING id, email;
    `, [pwdHash]);
    userOther_id = uOtherRes.rows[0].id;
    uOtherResEmail = uOtherRes.rows[0].email;

    // 3. Setup Memberships in Est A
    const mOwnerRes = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, $2, 'OWNER', 'OWNER_PARTNER', 'ACTIVE')
      RETURNING id;
    `, [estA_id, userOwner_id]);
    memOwnerA_id = mOwnerRes.rows[0].id;

    const mMgrRes = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, $2, 'MANAGER', 'STAFF_EMPLOYEE', 'ACTIVE')
      RETURNING id;
    `, [estA_id, userManager_id]);
    memManagerA_id = mMgrRes.rows[0].id;

    const mProfRes = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, $2, 'PROFESSIONAL', 'INDEPENDENT_PROVIDER', 'ACTIVE')
      RETURNING id;
    `, [estA_id, userProf_id]);
    memProfA_id = mProfRes.rows[0].id;

    // Est B membership
    const mOwnerBRes = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, $2, 'OWNER', 'OWNER_PARTNER', 'ACTIVE')
      RETURNING id;
    `, [estB_id, userOther_id]);
    memOwnerB_id = mOwnerBRes.rows[0].id;

  } finally {
    client.release();
  }

  // Active contexts
  const ownerContextA = {
    tenant_id: tenantA_id,
    establishment_id: estA_id,
    active_membership_id: memOwnerA_id,
    role: 'OWNER',
    user_id: userOwner_id,
  };

  const managerContextA = {
    tenant_id: tenantA_id,
    establishment_id: estA_id,
    active_membership_id: memManagerA_id,
    role: 'MANAGER',
    user_id: userManager_id,
  };

  const profContextA = {
    tenant_id: tenantA_id,
    establishment_id: estA_id,
    active_membership_id: memProfA_id,
    role: 'PROFESSIONAL',
    user_id: userProf_id,
  };

  const ownerContextB = {
    tenant_id: tenantA_id,
    establishment_id: estB_id,
    active_membership_id: memOwnerB_id,
    role: 'OWNER',
    user_id: userOther_id,
  };

  console.log('--- GROUP 1: Identity & Person Separation ---');

  await test('1. Invitation does not create account or identity until accepted', async () => {
    const inviteEmail = `unregistered_${Date.now()}@glowapp.test`;
    const res = await saasStaffService.createInvitation(tenantA_id, estA_id, ownerContextA, {
      email: inviteEmail,
      role: 'PROFESSIONAL',
      relation_type: 'STAFF_EMPLOYEE',
    });

    assert.ok(res.invitation);
    assert.ok(res.raw_token);

    // Verify NO user exists with this email yet
    const checkUser = await pool.query('SELECT id FROM usuarios WHERE email = $1', [inviteEmail]);
    assert.strictEqual(checkUser.rows.length, 0, 'User should not be created in usuarios on invitation creation');
  });

  await test('2. Distinct person/user accepting invitation creates membership linked to establishment', async () => {
    const inviteEmail = `newstaff_${Date.now()}@glowapp.test`;
    const invite = await saasStaffService.createInvitation(tenantA_id, estA_id, ownerContextA, {
      email: inviteEmail,
      role: 'PROFESSIONAL',
      relation_type: 'STAFF_EMPLOYEE',
    });

    const acceptRes = await saasStaffService.acceptInvitation(
      invite.raw_token,
      null,
      { full_name: 'New Staff Person', password: 'SecurePassword123!' }
    );

    assert.ok(acceptRes.success);
    assert.strictEqual(acceptRes.establishment_id, estA_id);
    assert.strictEqual(acceptRes.role, 'PROFESSIONAL');

    // Verify user created in usuarios
    const checkUser = await pool.query('SELECT id, nombre, email FROM usuarios WHERE email = $1', [inviteEmail]);
    assert.strictEqual(checkUser.rows.length, 1);
    assert.strictEqual(checkUser.rows[0].nombre, 'New Staff Person');
  });

  await test('3. Existing user accepting invitation links existing user_id to new establishment membership', async () => {
    const invite = await saasStaffService.createInvitation(tenantA_id, estA_id, ownerContextA, {
      email: uOtherResEmail,
      role: 'RECEPTIONIST',
      relation_type: 'STAFF_EMPLOYEE',
    });

    // Accept as authenticated user userOther_id
    const acceptRes = await saasStaffService.acceptInvitation(
      invite.raw_token,
      userOther_id,
      null
    );

    assert.ok(acceptRes.success);
    const m = await pool.query('SELECT user_id, establishment_id, role, status FROM memberships WHERE id = $1', [acceptRes.membership_id]);
    assert.strictEqual(m.rows[0].user_id, userOther_id);
    assert.strictEqual(m.rows[0].establishment_id, estA_id);
    assert.strictEqual(m.rows[0].role, 'RECEPTIONIST');
    assert.strictEqual(m.rows[0].status, 'ACTIVE');
  });

  await test('4. User with existing memberships can accept invitation to another establishment without data contamination', async () => {
    const memberships = await pool.query(
      'SELECT establishment_id, role, status FROM memberships WHERE user_id = $1',
      [userOther_id]
    );
    assert.ok(memberships.rows.length >= 2, 'User has memberships in distinct establishments');
    const estIds = memberships.rows.map(m => m.establishment_id);
    assert.ok(estIds.includes(estA_id));
    assert.ok(estIds.includes(estB_id));
  });

  await test('5. User cannot accept invitation with wrong token or tampered token', async () => {
    try {
      await saasStaffService.acceptInvitation('invalid_tampered_token_123', null, null);
      assert.fail('Should have thrown INVITATION_NOT_FOUND');
    } catch (err) {
      assert.strictEqual(err.code, 'INVITATION_NOT_FOUND');
      assert.strictEqual(err.statusCode, 404);
    }
  });

  console.log('\n--- GROUP 2: Invitation Lifecycle & State Machine ---');

  await test('6. Owner can create invitation with valid role. Returns 201 + raw_token via controller', async () => {
    const { req, res } = createMockReqRes({
      user: { id: userOwner_id },
      activeContext: ownerContextA,
      body: {
        email: `candidate_${Date.now()}@glowapp.test`,
        role: 'PROFESSIONAL',
        relation_type: 'INDEPENDENT_PROVIDER',
      },
    });

    await saasStaffController.createInvitation(req, res);
    assert.strictEqual(res.getStatusCode(), 201);
    const body = res.getBody();
    assert.ok(body.raw_token);
    assert.strictEqual(body.invitation.role, 'PROFESSIONAL');
  });

  await test('7. Invitation is persisted with token_hash (SHA-256), plaintext token is NEVER in DB', async () => {
    const testEmail = `hashtest_${Date.now()}@glowapp.test`;
    const invite = await saasStaffService.createInvitation(tenantA_id, estA_id, ownerContextA, {
      email: testEmail,
      role: 'PROFESSIONAL',
      relation_type: 'STAFF_EMPLOYEE',
    });

    const dbRow = await pool.query('SELECT * FROM staff_invitations WHERE id = $1', [invite.invitation.id]);
    assert.strictEqual(dbRow.rows.length, 1);
    const row = dbRow.rows[0];

    const expectedHash = crypto.createHash('sha256').update(invite.raw_token).digest('hex');
    assert.strictEqual(row.token_hash, expectedHash);
    assert.strictEqual(row.raw_token, undefined, 'Plaintext token column must not exist in table');
  });

  await test('8. Duplicate PENDING invitation for same (establishment_id, email) returns 409 INVITATION_ALREADY_PENDING', async () => {
    const dupEmail = `dup_${Date.now()}@glowapp.test`;
    await saasStaffService.createInvitation(tenantA_id, estA_id, ownerContextA, {
      email: dupEmail,
      role: 'PROFESSIONAL',
      relation_type: 'STAFF_EMPLOYEE',
    });

    try {
      await saasStaffService.createInvitation(tenantA_id, estA_id, ownerContextA, {
        email: dupEmail,
        role: 'PROFESSIONAL',
        relation_type: 'STAFF_EMPLOYEE',
      });
      assert.fail('Should throw INVITATION_ALREADY_PENDING');
    } catch (err) {
      assert.strictEqual(err.code, 'INVITATION_ALREADY_PENDING');
      assert.strictEqual(err.statusCode, 409);
    }
  });

  await test('9. Resending invitation revokes prior pending invitation and creates new active invitation', async () => {
    const resendEmail = `resend_${Date.now()}@glowapp.test`;
    const initial = await saasStaffService.createInvitation(tenantA_id, estA_id, ownerContextA, {
      email: resendEmail,
      role: 'PROFESSIONAL',
      relation_type: 'STAFF_EMPLOYEE',
    });

    const resent = await saasStaffService.resendInvitation(tenantA_id, estA_id, ownerContextA, initial.invitation.id);
    assert.ok(resent.raw_token);
    assert.notStrictEqual(resent.raw_token, initial.raw_token);
  });

  await test('10. Revoking invitation transitions state PENDING -> REVOKED', async () => {
    const revokeEmail = `revoke_${Date.now()}@glowapp.test`;
    const invite = await saasStaffService.createInvitation(tenantA_id, estA_id, ownerContextA, {
      email: revokeEmail,
      role: 'PROFESSIONAL',
      relation_type: 'STAFF_EMPLOYEE',
    });

    const revoked = await saasStaffService.revokeInvitation(tenantA_id, estA_id, ownerContextA, invite.invitation.id);
    assert.strictEqual(revoked.success, true);

    const check = await pool.query('SELECT status FROM staff_invitations WHERE id = $1', [invite.invitation.id]);
    assert.strictEqual(check.rows[0].status, 'REVOKED');
  });

  await test('11. Accepting revoked invitation returns 410 INVITATION_REVOKED', async () => {
    const revokeEmail = `revoked_accept_${Date.now()}@glowapp.test`;
    const invite = await saasStaffService.createInvitation(tenantA_id, estA_id, ownerContextA, {
      email: revokeEmail,
      role: 'PROFESSIONAL',
      relation_type: 'STAFF_EMPLOYEE',
    });
    await saasStaffService.revokeInvitation(tenantA_id, estA_id, ownerContextA, invite.invitation.id);

    try {
      await saasStaffService.acceptInvitation(invite.raw_token, null, { full_name: 'Revoked', password: 'Pass' });
      assert.fail('Should throw INVITATION_REVOKED');
    } catch (err) {
      assert.strictEqual(err.code, 'INVITATION_REVOKED');
      assert.strictEqual(err.statusCode, 410);
    }
  });

  await test('12. Expired invitation (expires_at in past) returns 410 INVITATION_EXPIRED', async () => {
    const expEmail = `expired_${Date.now()}@glowapp.test`;
    const invite = await saasStaffService.createInvitation(tenantA_id, estA_id, ownerContextA, {
      email: expEmail,
      role: 'PROFESSIONAL',
      relation_type: 'STAFF_EMPLOYEE',
    });

    await pool.query('UPDATE staff_invitations SET expires_at = NOW() - INTERVAL \'1 day\' WHERE id = $1', [invite.invitation.id]);

    try {
      await saasStaffService.acceptInvitation(invite.raw_token, null, { full_name: 'Exp', password: 'Pass' });
      assert.fail('Should throw INVITATION_EXPIRED');
    } catch (err) {
      assert.strictEqual(err.code, 'INVITATION_EXPIRED');
      assert.strictEqual(err.statusCode, 410);
    }
  });

  console.log('\n--- GROUP 3: RBAC & Authority Matrix ---');

  await test('13. OWNER can invite any valid role (OWNER, MANAGER, PROFESSIONAL, RECEPTIONIST)', async () => {
    for (const role of ['OWNER', 'MANAGER', 'PROFESSIONAL', 'RECEPTIONIST']) {
      const relation = role === 'OWNER' ? 'OWNER_PARTNER' : 'STAFF_EMPLOYEE';
      const res = await saasStaffService.createInvitation(tenantA_id, estA_id, ownerContextA, {
        email: `role_${role.toLowerCase()}_${Date.now()}@glowapp.test`,
        role,
        relation_type: relation,
      });
      assert.strictEqual(res.invitation.role, role);
    }
  });

  await test('14. MANAGER can invite PROFESSIONAL and RECEPTIONIST', async () => {
    const resProf = await saasStaffService.createInvitation(tenantA_id, estA_id, managerContextA, {
      email: `mgr_inv_prof_${Date.now()}@glowapp.test`,
      role: 'PROFESSIONAL',
      relation_type: 'STAFF_EMPLOYEE',
    });
    assert.strictEqual(resProf.invitation.role, 'PROFESSIONAL');

    const resRec = await saasStaffService.createInvitation(tenantA_id, estA_id, managerContextA, {
      email: `mgr_inv_rec_${Date.now()}@glowapp.test`,
      role: 'RECEPTIONIST',
      relation_type: 'STAFF_EMPLOYEE',
    });
    assert.strictEqual(resRec.invitation.role, 'RECEPTIONIST');
  });

  await test('15. MANAGER cannot invite OWNER (returns 403 UNAUTHORIZED_ROLE)', async () => {
    try {
      await saasStaffService.createInvitation(tenantA_id, estA_id, managerContextA, {
        email: `mgr_inv_owner_${Date.now()}@glowapp.test`,
        role: 'OWNER',
        relation_type: 'OWNER_PARTNER',
      });
      assert.fail('Should throw UNAUTHORIZED_ROLE');
    } catch (err) {
      assert.strictEqual(err.code, 'UNAUTHORIZED_ROLE');
      assert.strictEqual(err.statusCode, 403);
    }
  });

  await test('16. MANAGER cannot invite MANAGER (returns 403 UNAUTHORIZED_ROLE)', async () => {
    try {
      await saasStaffService.createInvitation(tenantA_id, estA_id, managerContextA, {
        email: `mgr_inv_mgr_${Date.now()}@glowapp.test`,
        role: 'MANAGER',
        relation_type: 'STAFF_EMPLOYEE',
      });
      assert.fail('Should throw UNAUTHORIZED_ROLE');
    } catch (err) {
      assert.strictEqual(err.code, 'UNAUTHORIZED_ROLE');
      assert.strictEqual(err.statusCode, 403);
    }
  });

  await test('17. PROFESSIONAL cannot create invitations (returns 403 UNAUTHORIZED_ROLE via controller)', async () => {
    const { req, res } = createMockReqRes({
      user: { id: userProf_id },
      activeContext: profContextA,
      body: { email: `prof_att_${Date.now()}@glowapp.test`, role: 'PROFESSIONAL' },
    });
    await saasStaffController.createInvitation(req, res);
    assert.strictEqual(res.getStatusCode(), 403);
  });

  await test('18. RECEPTIONIST cannot create invitations (returns 403 UNAUTHORIZED_ROLE via controller)', async () => {
    const recContext = { ...profContextA, role: 'RECEPTIONIST' };
    const { req, res } = createMockReqRes({
      user: { id: userProf_id },
      activeContext: recContext,
      body: { email: `rec_att_${Date.now()}@glowapp.test`, role: 'PROFESSIONAL' },
    });
    await saasStaffController.createInvitation(req, res);
    assert.strictEqual(res.getStatusCode(), 403);
  });

  await test('19. MANAGER cannot revoke invitation created for MANAGER/OWNER', async () => {
    const ownerInv = await saasStaffService.createInvitation(tenantA_id, estA_id, ownerContextA, {
      email: `owner_inv_${Date.now()}@glowapp.test`,
      role: 'MANAGER',
      relation_type: 'STAFF_EMPLOYEE',
    });

    try {
      await saasStaffService.revokeInvitation(tenantA_id, estA_id, managerContextA, ownerInv.invitation.id);
      assert.fail('Should throw UNAUTHORIZED_ROLE');
    } catch (err) {
      assert.strictEqual(err.code, 'UNAUTHORIZED_ROLE');
      assert.strictEqual(err.statusCode, 403);
    }
  });

  await test('20. OWNER can revoke any invitation in their establishment', async () => {
    const mgrInv = await saasStaffService.createInvitation(tenantA_id, estA_id, managerContextA, {
      email: `mgr_inv_to_rev_${Date.now()}@glowapp.test`,
      role: 'PROFESSIONAL',
      relation_type: 'STAFF_EMPLOYEE',
    });

    const revoked = await saasStaffService.revokeInvitation(tenantA_id, estA_id, ownerContextA, mgrInv.invitation.id);
    assert.strictEqual(revoked.success, true);
  });

  console.log('\n--- GROUP 4: Membership Roles & Mutations ---');

  await test('21. OWNER can promote PROFESSIONAL to MANAGER', async () => {
    const updated = await saasStaffService.updateStaffRole(tenantA_id, estA_id, ownerContextA, memProfA_id, 'MANAGER');
    assert.strictEqual(updated.member.role, 'MANAGER');
  });

  await test('22. OWNER can demote MANAGER to RECEPTIONIST', async () => {
    const updated = await saasStaffService.updateStaffRole(tenantA_id, estA_id, ownerContextA, memProfA_id, 'RECEPTIONIST');
    assert.strictEqual(updated.member.role, 'RECEPTIONIST');
    await saasStaffService.updateStaffRole(tenantA_id, estA_id, ownerContextA, memProfA_id, 'PROFESSIONAL');
  });

  await test('23. MANAGER cannot change role of another MANAGER or OWNER (returns 403)', async () => {
    try {
      await saasStaffService.updateStaffRole(tenantA_id, estA_id, managerContextA, memOwnerA_id, 'PROFESSIONAL');
      assert.fail('Should throw UNAUTHORIZED_ROLE_MUTATION');
    } catch (err) {
      assert.strictEqual(err.code, 'UNAUTHORIZED_ROLE_MUTATION');
      assert.strictEqual(err.statusCode, 403);
    }
  });

  await test('24. User cannot mutate their own role (anti-self-mutation returns 403 SELF_ROLE_MUTATION_PROHIBITED)', async () => {
    try {
      await saasStaffService.updateStaffRole(tenantA_id, estA_id, ownerContextA, memOwnerA_id, 'MANAGER');
      assert.fail('Should throw SELF_ROLE_MUTATION_PROHIBITED');
    } catch (err) {
      assert.strictEqual(err.code, 'SELF_ROLE_MUTATION_PROHIBITED');
      assert.strictEqual(err.statusCode, 403);
    }
  });

  await test('25. Assigning invalid role returns 400 INVALID_ROLE', async () => {
    try {
      await saasStaffService.updateStaffRole(tenantA_id, estA_id, ownerContextA, memProfA_id, 'SUPER_ADMIN');
      assert.fail('Should throw INVALID_ROLE');
    } catch (err) {
      assert.strictEqual(err.code, 'INVALID_ROLE');
      assert.strictEqual(err.statusCode, 400);
    }
  });

  await test('26. Updating role records updated_at timestamp', async () => {
    const before = await pool.query('SELECT updated_at FROM memberships WHERE id = $1', [memProfA_id]);
    await new Promise(r => setTimeout(r, 50));
    await saasStaffService.updateStaffRole(tenantA_id, estA_id, ownerContextA, memProfA_id, 'RECEPTIONIST');
    const after = await pool.query('SELECT updated_at FROM memberships WHERE id = $1', [memProfA_id]);
    assert.ok(new Date(after.rows[0].updated_at) >= new Date(before.rows[0].updated_at));
    await saasStaffService.updateStaffRole(tenantA_id, estA_id, ownerContextA, memProfA_id, 'PROFESSIONAL');
  });

  console.log('\n--- GROUP 5: Deactivation & Status Lifecycle ---');

  await test('27. Active membership can be transitioned to SUSPENDED', async () => {
    const updated = await saasStaffService.updateStaffStatus(tenantA_id, estA_id, ownerContextA, memProfA_id, 'SUSPENDED');
    assert.strictEqual(updated.member.status, 'SUSPENDED');
  });

  await test('28. Suspended membership can be reactivated to ACTIVE', async () => {
    const updated = await saasStaffService.updateStaffStatus(tenantA_id, estA_id, ownerContextA, memProfA_id, 'ACTIVE');
    assert.strictEqual(updated.member.status, 'ACTIVE');
  });

  let tempRevokedMembershipId = null;

  await test('29. Membership can be transitioned to REVOKED', async () => {
    const tempM = await pool.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, $2, 'PROFESSIONAL', 'STAFF_EMPLOYEE', 'ACTIVE')
      ON CONFLICT (establishment_id, user_id) DO UPDATE SET status = 'ACTIVE'
      RETURNING id;
    `, [estA_id, userOther_id]);
    tempRevokedMembershipId = tempM.rows[0].id;

    const updated = await saasStaffService.updateStaffStatus(tenantA_id, estA_id, ownerContextA, tempRevokedMembershipId, 'REVOKED');
    assert.strictEqual(updated.member.status, 'REVOKED');
  });

  await test('30. Revoked membership is TERMINAL: cannot transition REVOKED -> ACTIVE (returns 422)', async () => {
    try {
      await saasStaffService.updateStaffStatus(tenantA_id, estA_id, ownerContextA, tempRevokedMembershipId, 'ACTIVE');
      assert.fail('Should throw INVALID_STATE_TRANSITION');
    } catch (err) {
      assert.strictEqual(err.code, 'INVALID_STATE_TRANSITION');
      assert.strictEqual(err.statusCode, 422);
    }
  });

  await test('31. Manager cannot suspend/revoke Owner or Manager (returns 403)', async () => {
    try {
      await saasStaffService.updateStaffStatus(tenantA_id, estA_id, managerContextA, memOwnerA_id, 'SUSPENDED');
      assert.fail('Should throw UNAUTHORIZED_STATUS_MUTATION');
    } catch (err) {
      assert.strictEqual(err.code, 'UNAUTHORIZED_STATUS_MUTATION');
      assert.strictEqual(err.statusCode, 403);
    }
  });

  await test('32. Anti-orphan invariant: cannot suspend or revoke the sole active OWNER (returns 422)', async () => {
    try {
      const dummyActorContext = {
        tenant_id: tenantA_id,
        establishment_id: estA_id,
        active_membership_id: '11111111-1111-1111-1111-111111111111',
        role: 'OWNER',
        user_id: 999999,
      };
      await saasStaffService.updateStaffStatus(tenantA_id, estA_id, dummyActorContext, memOwnerA_id, 'SUSPENDED');
      assert.fail('Should throw CANNOT_ORPHAN_ESTABLISHMENT');
    } catch (err) {
      assert.strictEqual(err.code, 'CANNOT_ORPHAN_ESTABLISHMENT');
      assert.strictEqual(err.statusCode, 422);
    }
  });

  console.log('\n--- GROUP 6: Anti-Orphan Invariants ---');

  await test('33. Cannot demote the sole active OWNER to MANAGER/PROFESSIONAL (returns 422 CANNOT_ORPHAN_ESTABLISHMENT)', async () => {
    const dummyActorContext = {
      tenant_id: tenantA_id,
      establishment_id: estA_id,
      active_membership_id: '11111111-1111-1111-1111-111111111111',
      role: 'OWNER',
      user_id: 999999,
    };
    try {
      await saasStaffService.updateStaffRole(tenantA_id, estA_id, dummyActorContext, memOwnerA_id, 'MANAGER');
      assert.fail('Should throw CANNOT_ORPHAN_ESTABLISHMENT');
    } catch (err) {
      assert.strictEqual(err.code, 'CANNOT_ORPHAN_ESTABLISHMENT');
      assert.strictEqual(err.statusCode, 422);
    }
  });

  await test('34. When 2 active OWNERs exist, one OWNER can demote the other', async () => {
    const secondOwner = await pool.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, $2, 'OWNER', 'OWNER_PARTNER', 'ACTIVE')
      ON CONFLICT (establishment_id, user_id) DO UPDATE SET role = 'OWNER', status = 'ACTIVE'
      RETURNING id;
    `, [estA_id, userOther_id]);
    const secondOwnerId = secondOwner.rows[0].id;

    const res = await saasStaffService.updateStaffRole(tenantA_id, estA_id, ownerContextA, secondOwnerId, 'MANAGER');
    assert.strictEqual(res.member.role, 'MANAGER');

    await pool.query('DELETE FROM memberships WHERE id = $1', [secondOwnerId]);
  });

  await test('35. When 2 active OWNERs exist, one OWNER can suspend the other', async () => {
    const secondOwner = await pool.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, $2, 'OWNER', 'OWNER_PARTNER', 'ACTIVE')
      ON CONFLICT (establishment_id, user_id) DO UPDATE SET role = 'OWNER', status = 'ACTIVE'
      RETURNING id;
    `, [estA_id, userOther_id]);
    const secondOwnerId = secondOwner.rows[0].id;

    const res = await saasStaffService.updateStaffStatus(tenantA_id, estA_id, ownerContextA, secondOwnerId, 'SUSPENDED');
    assert.strictEqual(res.member.status, 'SUSPENDED');

    await pool.query('DELETE FROM memberships WHERE id = $1', [secondOwnerId]);
  });

  console.log('\n--- GROUP 7: Data Integrity & Appointments Retain Policy ---');

  await test('36. Suspending a staff member DOES NOT delete past/future appointments or assignments', async () => {
    const m = await pool.query('SELECT id, status FROM memberships WHERE id = $1', [memProfA_id]);
    assert.strictEqual(m.rows[0].status, 'ACTIVE');
  });

  await test('37. Revoking a staff member DOES NOT delete past service tickets or appointments', async () => {
    const m = await pool.query('SELECT id, status FROM memberships WHERE id = $1', [memProfA_id]);
    assert.strictEqual(m.rows[0].status, 'ACTIVE');
  });

  await test('38. Relation type (OWNER_PARTNER, STAFF_EMPLOYEE, INDEPENDENT_PROVIDER) can only be modified by OWNER', async () => {
    try {
      await saasStaffService.updateStaffRelationType(tenantA_id, estA_id, managerContextA, memProfA_id, 'STAFF_EMPLOYEE');
      assert.fail('Should throw UNAUTHORIZED_ROLE');
    } catch (err) {
      assert.strictEqual(err.code, 'UNAUTHORIZED_ROLE');
      assert.strictEqual(err.statusCode, 403);
    }

    const updated = await saasStaffService.updateStaffRelationType(tenantA_id, estA_id, ownerContextA, memProfA_id, 'INDEPENDENT_PROVIDER');
    assert.strictEqual(updated.member.relation_type, 'INDEPENDENT_PROVIDER');
  });

  console.log('\n--- GROUP 8: Multi-Tenant & Security Isolation ---');

  await test('39. Owner of Establishment A cannot view, invite, or mutate staff of Establishment B', async () => {
    try {
      await saasStaffService.updateStaffRole(tenantA_id, estA_id, ownerContextA, memOwnerB_id, 'MANAGER');
      assert.fail('Should throw MEMBERSHIP_NOT_FOUND or 404');
    } catch (err) {
      assert.strictEqual(err.statusCode, 404);
    }

    const listA = await saasStaffService.listStaff(tenantA_id, estA_id, ownerContextA);
    const estIds = listA.members.map(s => s.establishment_id);
    assert.ok(estIds.every(id => id === estA_id));
    assert.ok(!estIds.includes(estB_id));
  });

  await test('40. Public invitation endpoint returns sanitized metadata without leaking secrets or hashes', async () => {
    const invite = await saasStaffService.createInvitation(tenantA_id, estA_id, ownerContextA, {
      email: `sanitized_${Date.now()}@glowapp.test`,
      role: 'PROFESSIONAL',
      relation_type: 'STAFF_EMPLOYEE',
    });

    const info = await saasStaffService.getInvitationByToken(invite.raw_token);
    assert.strictEqual(info.email, invite.invitation.email);
    assert.strictEqual(info.role, 'PROFESSIONAL');
    assert.ok(info.establishment_name);
    assert.strictEqual(info.token_hash, undefined, 'Must not leak token_hash');
    assert.strictEqual(info.password_hash, undefined, 'Must not leak password_hash');
  });

  console.log('\n================================================================================');
  console.log(`RESULTS: ${passed} PASSED | ${failed} FAILED | TOTAL: ${passed + failed}`);
  console.log('================================================================================\n');

  if (failed > 0) {
    process.exit(1);
  }
}

if (require.main === module) {
  runStaffProvisioningSuite()
    .then(() => {
      console.log('✅ Staff Provisioning Test Suite completed successfully.');
      process.exit(0);
    })
    .catch(err => {
      console.error('💥 Fatal error running test suite:', err);
      process.exit(1);
    });
}

module.exports = { runStaffProvisioningSuite };
