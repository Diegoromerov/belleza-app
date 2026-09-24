// backend/tests/test_staff_availability_suite.js
const assert = require('assert');
const { pool } = require('../src/config/db');
const staffAvailabilityService = require('../src/services/staffAvailabilityService');
const staffAvailabilityController = require('../src/controllers/staffAvailabilityController');

function createMockReqRes(options = {}) {
  const req = {
    user: options.user !== undefined ? options.user : { id: 7, email: 'demo@beautyapp.com' },
    headers: options.headers || {},
    body: options.body || {},
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

async function runStaffAvailabilitySuite() {
  console.log('================================================================================');
  console.log('       NODO-03A — STAFF OPERATIONAL AVAILABILITY & SCHEDULE SUITE');
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

  try {
    // 0. Runtime Privileges & RLS Safety Check
    const roleRes = await client.query('SELECT rolname, rolsuper, rolbypassrls FROM pg_roles WHERE rolname = current_user;');
    console.log('[Runtime Privileges]:', roleRes.rows[0]);
    if (roleRes.rows[0].rolsuper !== false || roleRes.rows[0].rolbypassrls !== false) {
      throw new Error('FATAL: Runtime user is superuser or bypasses RLS!');
    }

    // Set Tenant Context for Tenant 2
    await client.query("SELECT set_config('app.tenant_id', '2', false);");

    // Fetch test establishment for Tenant 2
    const estRes = await client.query('SELECT id, organization_id, operating_hours FROM establishments WHERE tenant_id = 2 LIMIT 1;');
    assert(estRes.rows.length > 0, 'Establishment must exist for Tenant 2');
    const testEstId = estRes.rows[0].id;
    const testOrgId = estRes.rows[0].organization_id;

    // Fetch active OWNER membership
    const ownerRes = await client.query("SELECT id, user_id FROM memberships WHERE tenant_id = 2 AND establishment_id = $1 AND role = 'OWNER' AND status = 'ACTIVE' LIMIT 1;", [testEstId]);
    assert(ownerRes.rows.length > 0, 'Active OWNER membership must exist');
    const ownerMembershipId = ownerRes.rows[0].id;
    const ownerUserId = ownerRes.rows[0].user_id;

    const ownerContext = {
      membershipId: ownerMembershipId,
      active_membership_id: ownerMembershipId,
      role: 'OWNER',
      relation_type: 'OWNER_PARTNER',
      membership_status: 'ACTIVE',
    };

    // Fetch or create active MANAGER membership
    let mgrRes = await client.query("SELECT id, user_id FROM memberships WHERE tenant_id = 2 AND establishment_id = $1 AND role = 'MANAGER' AND status = 'ACTIVE' LIMIT 1;", [testEstId]);
    let mgrMembershipId;
    if (mgrRes.rows.length === 0) {
      const uRes = await client.query("INSERT INTO usuarios (tenant_id, email, nombre, password_hash, rol, auth_provider, provider_id, is_active) VALUES (2, 'manager_staff@beautyapp.com', 'Manager SaaS', 'hash', 'CLIENTE', 'LOCAL', 'mgr-staff-local', TRUE) ON CONFLICT (email) DO UPDATE SET is_active=TRUE RETURNING id;");
      const mRes = await client.query("INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status) VALUES (2, $1, $2, 'MANAGER', 'STAFF_EMPLOYEE', 'ACTIVE') ON CONFLICT (establishment_id, user_id) DO UPDATE SET status='ACTIVE', role='MANAGER' RETURNING id;", [testEstId, uRes.rows[0].id]);
      mgrMembershipId = mRes.rows[0].id;
    } else {
      mgrMembershipId = mgrRes.rows[0].id;
    }
    const mgrContext = {
      membershipId: mgrMembershipId,
      active_membership_id: mgrMembershipId,
      role: 'MANAGER',
      relation_type: 'STAFF_EMPLOYEE',
      membership_status: 'ACTIVE',
    };

    // Fetch or create active PROFESSIONAL membership 1
    let profRes = await client.query("SELECT id, user_id FROM memberships WHERE tenant_id = 2 AND establishment_id = $1 AND role = 'PROFESSIONAL' AND status = 'ACTIVE' LIMIT 1;", [testEstId]);
    let profMembershipId;
    if (profRes.rows.length === 0) {
      const uRes = await client.query("INSERT INTO usuarios (tenant_id, email, nombre, password_hash, rol, auth_provider, provider_id, is_active) VALUES (2, 'prof_staff1@beautyapp.com', 'Laura Estilista', 'hash', 'PRESTADOR', 'LOCAL', 'prof-staff1-local', TRUE) ON CONFLICT (email) DO UPDATE SET is_active=TRUE RETURNING id;");
      const mRes = await client.query("INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status) VALUES (2, $1, $2, 'PROFESSIONAL', 'STAFF_EMPLOYEE', 'ACTIVE') ON CONFLICT (establishment_id, user_id) DO UPDATE SET status='ACTIVE', role='PROFESSIONAL' RETURNING id;", [testEstId, uRes.rows[0].id]);
      profMembershipId = mRes.rows[0].id;
    } else {
      profMembershipId = profRes.rows[0].id;
    }
    const profContext = {
      membershipId: profMembershipId,
      active_membership_id: profMembershipId,
      role: 'PROFESSIONAL',
      relation_type: 'STAFF_EMPLOYEE',
      membership_status: 'ACTIVE',
    };

    // Create another PROFESSIONAL membership 2 (for testing cross-professional prohibition)
    const uRes2 = await client.query("INSERT INTO usuarios (tenant_id, email, nombre, password_hash, rol, auth_provider, provider_id, is_active) VALUES (2, 'prof_staff2@beautyapp.com', 'Pedro Colorista', 'hash', 'PRESTADOR', 'LOCAL', 'prof-staff2-local', TRUE) ON CONFLICT (email) DO UPDATE SET is_active=TRUE RETURNING id;");
    const mRes2 = await client.query("INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status) VALUES (2, $1, $2, 'PROFESSIONAL', 'STAFF_EMPLOYEE', 'ACTIVE') ON CONFLICT (establishment_id, user_id) DO UPDATE SET status='ACTIVE', role='PROFESSIONAL' RETURNING id;", [testEstId, uRes2.rows[0].id]);
    const prof2MembershipId = mRes2.rows[0].id;

    // Create RECEPTIONIST membership
    const uRec = await client.query("INSERT INTO usuarios (tenant_id, email, nombre, password_hash, rol, auth_provider, provider_id, is_active) VALUES (2, 'receptionist_staff@beautyapp.com', 'Sofia Recepcion', 'hash', 'CLIENTE', 'LOCAL', 'rec-staff-local', TRUE) ON CONFLICT (email) DO UPDATE SET is_active=TRUE RETURNING id;");
    const mRec = await client.query("INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status) VALUES (2, $1, $2, 'RECEPTIONIST', 'STAFF_EMPLOYEE', 'ACTIVE') ON CONFLICT (establishment_id, user_id) DO UPDATE SET status='ACTIVE', role='RECEPTIONIST' RETURNING id;", [testEstId, uRec.rows[0].id]);
    const recMembershipId = mRec.rows[0].id;
    const recContext = {
      membershipId: recMembershipId,
      active_membership_id: recMembershipId,
      role: 'RECEPTIONIST',
      relation_type: 'STAFF_EMPLOYEE',
      membership_status: 'ACTIVE',
    };

    // Create SUSPENDED membership
    const uSusp = await client.query("INSERT INTO usuarios (tenant_id, email, nombre, password_hash, rol, auth_provider, provider_id, is_active) VALUES (2, 'suspended_staff@beautyapp.com', 'Inactivo Staff', 'hash', 'CLIENTE', 'LOCAL', 'susp-staff-local', TRUE) ON CONFLICT (email) DO UPDATE SET is_active=TRUE RETURNING id;");
    const mSusp = await client.query("INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status) VALUES (2, $1, $2, 'PROFESSIONAL', 'STAFF_EMPLOYEE', 'SUSPENDED') ON CONFLICT (establishment_id, user_id) DO UPDATE SET status='SUSPENDED', role='PROFESSIONAL' RETURNING id;", [testEstId, uSusp.rows[0].id]);
    const suspendedMembershipId = mSusp.rows[0].id;

    // Setup a Foreign Tenant 1 and Establishment
    let t1EstId = null;
    let t1ProfMemId = null;
    const t1Res = await client.query('SELECT id FROM tenants WHERE id = 1;');
    if (t1Res.rows.length > 0) {
      await client.query("SELECT set_config('app.tenant_id', '1', false);");
      const org1 = await client.query("INSERT INTO organizations (tenant_id, legal_name, tax_id, billing_email) VALUES (1, 'Foreign Org T1', '900111222-1', 'foreign@t1.com') ON CONFLICT DO NOTHING RETURNING id;");
      const org1Id = org1.rows.length > 0 ? org1.rows[0].id : (await client.query('SELECT id FROM organizations WHERE tenant_id = 1 LIMIT 1;')).rows[0].id;
      const est1 = await client.query("INSERT INTO establishments (tenant_id, organization_id, name, slug) VALUES (1, $1, 'Foreign Sede T1', 'foreign-sede-t1-staff') ON CONFLICT (slug) DO UPDATE SET name='Foreign Sede T1' RETURNING id;", [org1Id]);
      t1EstId = est1.rows[0].id;
      const u1 = await client.query("INSERT INTO usuarios (tenant_id, email, nombre, password_hash, rol, auth_provider, provider_id, is_active) VALUES (1, 'user_t1_staff@beautyapp.com', 'Foreign UserT1', 'hash', 'PRESTADOR', 'LOCAL', 'foreign-t1-local', TRUE) ON CONFLICT (email) DO UPDATE SET is_active=TRUE RETURNING id;");
      const m1 = await client.query("INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status) VALUES (1, $1, $2, 'PROFESSIONAL', 'STAFF_EMPLOYEE', 'ACTIVE') ON CONFLICT (establishment_id, user_id) DO UPDATE SET status='ACTIVE' RETURNING id;", [t1EstId, u1.rows[0].id]);
      t1ProfMemId = m1.rows[0].id;
      // Switch back to Tenant 2
      await client.query("SELECT set_config('app.tenant_id', '2', false);");
    }

    // Clean up test staff schedules before tests
    await client.query('DELETE FROM staff_schedules WHERE establishment_id = $1;', [testEstId]);

    // ==========================================
    // TEST SUITE EXECUTION
    // ==========================================

    // 1. OWNER can manage schedule (SET_STAFF_SCHEDULE)
    await test('1. OWNER can set complete weekly schedule for a professional', async () => {
      const { req, res } = createMockReqRes({
        tenantId: 2,
        establishmentId: testEstId,
        membershipId: ownerMembershipId,
        activeContext: ownerContext,
        params: { membership_id: profMembershipId },
        body: {
          weekly_schedule: {
            monday: { is_working: true, time_blocks: [{ start_time: '08:00', end_time: '12:00' }, { start_time: '14:00', end_time: '18:00' }] },
            tuesday: { is_working: true, time_blocks: [{ start_time: '08:00', end_time: '17:00' }] },
            wednesday: { is_working: false, time_blocks: [] },
            thursday: { is_working: true, time_blocks: [{ start_time: '08:00', end_time: '17:00' }] },
            friday: { is_working: true, time_blocks: [{ start_time: '08:00', end_time: '17:00' }] },
            saturday: { is_working: true, time_blocks: [{ start_time: '09:00', end_time: '14:00' }] },
            sunday: { is_working: false, time_blocks: [] }
          }
        }
      });

      await staffAvailabilityController.setStaffSchedule(req, res);
      assert.strictEqual(res.getStatusCode(), 200);
      const data = res.getBody().data;
      assert.strictEqual(data.schedule_state, 'CONFIGURED');
      assert.strictEqual(data.membership_id, profMembershipId);
      assert.strictEqual(data.weekly_schedule.monday.time_blocks.length, 2);
      assert.strictEqual(data.weekly_schedule.tuesday.time_blocks.length, 1);
      assert.strictEqual(data.weekly_schedule.wednesday.is_working, false);
    });

    // 2. MANAGER can manage schedule
    await test('2. MANAGER can manage schedule of a professional', async () => {
      const { req, res } = createMockReqRes({
        tenantId: 2,
        establishmentId: testEstId,
        membershipId: mgrMembershipId,
        activeContext: mgrContext,
        params: { membership_id: prof2MembershipId },
        body: {
          weekly_schedule: {
            monday: { is_working: true, time_blocks: [{ start_time: '09:00', end_time: '17:00' }] },
            friday: { is_working: true, time_blocks: [{ start_time: '09:00', end_time: '17:00' }] }
          }
        }
      });

      await staffAvailabilityController.setStaffSchedule(req, res);
      assert.strictEqual(res.getStatusCode(), 200);
      assert.strictEqual(res.getBody().data.schedule_state, 'CONFIGURED');
    });

    // 3. PROFESSIONAL can manage own schedule (bounded self-management)
    await test('3. PROFESSIONAL can manage own schedule (self-management authorized)', async () => {
      const { req, res } = createMockReqRes({
        tenantId: 2,
        establishmentId: testEstId,
        membershipId: profMembershipId,
        activeContext: profContext,
        params: { membership_id: profMembershipId },
        body: {
          weekly_schedule: {
            monday: { is_working: true, time_blocks: [{ start_time: '10:00', end_time: '16:00' }] }
          }
        }
      });

      await staffAvailabilityController.setStaffSchedule(req, res);
      assert.strictEqual(res.getStatusCode(), 200);
      assert.strictEqual(res.getBody().data.schedule_state, 'CONFIGURED');
    });

    // 4. PROFESSIONAL cannot manage another professional
    await test('4. PROFESSIONAL cannot manage another professional schedule (403 Forbidden)', async () => {
      const { req, res } = createMockReqRes({
        tenantId: 2,
        establishmentId: testEstId,
        membershipId: profMembershipId,
        activeContext: profContext,
        params: { membership_id: prof2MembershipId }, // Target is Pedro, not self
        body: {
          weekly_schedule: {
            monday: { is_working: true, time_blocks: [{ start_time: '08:00', end_time: '12:00' }] }
          }
        }
      });

      await staffAvailabilityController.setStaffSchedule(req, res);
      assert.strictEqual(res.getStatusCode(), 403);
      assert.strictEqual(res.getBody().code, 'FORBIDDEN_SELF_MANAGEMENT_ONLY');
    });

    // 5. RECEPTIONIST cannot write schedule
    await test('5. RECEPTIONIST cannot write schedule (403 Forbidden)', async () => {
      const { req, res } = createMockReqRes({
        tenantId: 2,
        establishmentId: testEstId,
        membershipId: recMembershipId,
        activeContext: recContext,
        params: { membership_id: profMembershipId },
        body: {
          weekly_schedule: {
            monday: { is_working: true, time_blocks: [{ start_time: '08:00', end_time: '12:00' }] }
          }
        }
      });

      await staffAvailabilityController.setStaffSchedule(req, res);
      assert.strictEqual(res.getStatusCode(), 403);
      assert.strictEqual(res.getBody().code, 'FORBIDDEN_ROLE');
    });

    // 6. Inactive membership rejected
    await test('6. Inactive (SUSPENDED) membership rejected with 422 INACTIVE_MEMBERSHIP', async () => {
      const { req, res } = createMockReqRes({
        tenantId: 2,
        establishmentId: testEstId,
        membershipId: ownerMembershipId,
        activeContext: ownerContext,
        params: { membership_id: suspendedMembershipId },
        body: {
          weekly_schedule: {
            monday: { is_working: true, time_blocks: [{ start_time: '08:00', end_time: '12:00' }] }
          }
        }
      });

      await staffAvailabilityController.setStaffSchedule(req, res);
      assert.strictEqual(res.getStatusCode(), 422);
      assert.strictEqual(res.getBody().code, 'INACTIVE_MEMBERSHIP');
    });

    // 7. Wrong active establishment rejected
    await test('7. Target membership in different establishment rejected (422 CROSS_ESTABLISHMENT_MISMATCH)', async () => {
      const dummyEstId = 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d';
      const { req, res } = createMockReqRes({
        tenantId: 2,
        establishmentId: dummyEstId,
        membershipId: ownerMembershipId,
        activeContext: ownerContext,
        params: { membership_id: profMembershipId },
        body: {
          weekly_schedule: {
            monday: { is_working: true, time_blocks: [{ start_time: '08:00', end_time: '12:00' }] }
          }
        }
      });

      await staffAvailabilityController.setStaffSchedule(req, res);
      assert.strictEqual(res.getStatusCode(), 422);
      assert.strictEqual(res.getBody().code, 'CROSS_ESTABLISHMENT_MISMATCH');
    });

    // 8. Foreign tenant rejected
    await test('8. Foreign tenant membership rejected under active tenant context', async () => {
      if (t1ProfMemId) {
        const { req, res } = createMockReqRes({
          tenantId: 2,
          establishmentId: testEstId,
          membershipId: ownerMembershipId,
          activeContext: ownerContext,
          params: { membership_id: t1ProfMemId },
          body: {
            weekly_schedule: {
              monday: { is_working: true, time_blocks: [{ start_time: '08:00', end_time: '12:00' }] }
            }
          }
        });

        await staffAvailabilityController.setStaffSchedule(req, res);
        assert.ok([404, 422].includes(res.getStatusCode()));
      }
    });

    // 9. Invalid day rejected
    await test('9. Invalid day structure rejected with 400', async () => {
      const { req, res } = createMockReqRes({
        tenantId: 2,
        establishmentId: testEstId,
        membershipId: ownerMembershipId,
        activeContext: ownerContext,
        params: { membership_id: profMembershipId },
        body: {
          weekly_schedule: {
            monday: "NOT_AN_OBJECT"
          }
        }
      });

      await staffAvailabilityController.setStaffSchedule(req, res);
      assert.strictEqual(res.getStatusCode(), 400);
      assert.strictEqual(res.getBody().code, 'INVALID_DAY_STRUCTURE');
    });

    // 10. start >= end rejected
    await test('10. start_time >= end_time rejected with 400 INVALID_TIME_ORDER', async () => {
      const { req, res } = createMockReqRes({
        tenantId: 2,
        establishmentId: testEstId,
        membershipId: ownerMembershipId,
        activeContext: ownerContext,
        params: { membership_id: profMembershipId },
        body: {
          weekly_schedule: {
            monday: { is_working: true, time_blocks: [{ start_time: '18:00', end_time: '08:00' }] }
          }
        }
      });

      await staffAvailabilityController.setStaffSchedule(req, res);
      assert.strictEqual(res.getStatusCode(), 400);
      assert.strictEqual(res.getBody().code, 'INVALID_TIME_ORDER');
    });

    // 11. Overlapping intervals rejected
    await test('11. Overlapping intervals (09:00-11:00 and 10:00-12:00) rejected with 400 OVERLAPPING_INTERVALS', async () => {
      const { req, res } = createMockReqRes({
        tenantId: 2,
        establishmentId: testEstId,
        membershipId: ownerMembershipId,
        activeContext: ownerContext,
        params: { membership_id: profMembershipId },
        body: {
          weekly_schedule: {
            monday: {
              is_working: true,
              time_blocks: [
                { start_time: '09:00', end_time: '11:00' },
                { start_time: '10:00', end_time: '12:00' }
              ]
            }
          }
        }
      });

      await staffAvailabilityController.setStaffSchedule(req, res);
      assert.strictEqual(res.getStatusCode(), 400);
      assert.strictEqual(res.getBody().code, 'OVERLAPPING_INTERVALS');
    });

    // 12. Adjacent intervals accepted
    await test('12. Adjacent intervals [08:00, 12:00) and [12:00, 17:00) are accepted', async () => {
      const { req, res } = createMockReqRes({
        tenantId: 2,
        establishmentId: testEstId,
        membershipId: ownerMembershipId,
        activeContext: ownerContext,
        params: { membership_id: profMembershipId },
        body: {
          weekly_schedule: {
            monday: {
              is_working: true,
              time_blocks: [
                { start_time: '08:00', end_time: '12:00' },
                { start_time: '12:00', end_time: '17:00' }
              ]
            }
          }
        }
      });

      await staffAvailabilityController.setStaffSchedule(req, res);
      assert.strictEqual(res.getStatusCode(), 200);
      const blocks = res.getBody().data.weekly_schedule.monday.time_blocks;
      assert.strictEqual(blocks.length, 2);
    });

    // 13. Multiple non-overlapping intervals in same day accepted
    await test('13. Multiple non-overlapping intervals (morning + afternoon shift) accepted', async () => {
      const { req, res } = createMockReqRes({
        tenantId: 2,
        establishmentId: testEstId,
        membershipId: ownerMembershipId,
        activeContext: ownerContext,
        params: { membership_id: profMembershipId },
        body: {
          weekly_schedule: {
            tuesday: {
              is_working: true,
              time_blocks: [
                { start_time: '08:00', end_time: '12:00' },
                { start_time: '14:00', end_time: '18:00' }
              ]
            }
          }
        }
      });

      await staffAvailabilityController.setStaffSchedule(req, res);
      assert.strictEqual(res.getStatusCode(), 200);
      assert.strictEqual(res.getBody().data.weekly_schedule.tuesday.time_blocks.length, 2);
    });

    // 14. Operating hours violation produces warning only
    await test('14. Hours exceeding establishment operating hours produce WARNING ONLY (out_of_operating_hours_warning: true)', async () => {
      const { req, res } = createMockReqRes({
        tenantId: 2,
        establishmentId: testEstId,
        membershipId: ownerMembershipId,
        activeContext: ownerContext,
        params: { membership_id: profMembershipId },
        body: {
          weekly_schedule: {
            monday: { is_working: true, time_blocks: [{ start_time: '06:00', end_time: '22:00' }] }
          }
        }
      });

      await staffAvailabilityController.setStaffSchedule(req, res);
      assert.strictEqual(res.getStatusCode(), 200);
      assert.strictEqual(res.getBody().data.out_of_operating_hours_warning, true);
    });

    // 15. Replacement is atomic
    await test('15. Schedule replacement is atomic and replaces previous week completely', async () => {
      // Step 1: Set Monday + Tuesday
      const req1 = createMockReqRes({
        tenantId: 2,
        establishmentId: testEstId,
        membershipId: ownerMembershipId,
        activeContext: ownerContext,
        params: { membership_id: profMembershipId },
        body: {
          weekly_schedule: {
            monday: { is_working: true, time_blocks: [{ start_time: '08:00', end_time: '12:00' }] },
            tuesday: { is_working: true, time_blocks: [{ start_time: '08:00', end_time: '12:00' }] }
          }
        }
      });
      await staffAvailabilityController.setStaffSchedule(req1.req, req1.res);

      // Step 2: Replace with only Friday
      const req2 = createMockReqRes({
        tenantId: 2,
        establishmentId: testEstId,
        membershipId: ownerMembershipId,
        activeContext: ownerContext,
        params: { membership_id: profMembershipId },
        body: {
          weekly_schedule: {
            friday: { is_working: true, time_blocks: [{ start_time: '09:00', end_time: '15:00' }] }
          }
        }
      });
      await staffAvailabilityController.setStaffSchedule(req2.req, req2.res);
      assert.strictEqual(req2.res.getStatusCode(), 200);

      // Verify in DB that Monday and Tuesday were removed completely
      const rows = await client.query('SELECT day_of_week FROM staff_schedules WHERE establishment_id = $1 AND membership_id = $2;', [testEstId, profMembershipId]);
      assert.strictEqual(rows.rows.length, 1);
      assert.strictEqual(rows.rows[0].day_of_week, 5); // Friday = 5
    });

    // 16. GET_STAFF_SCHEDULE returns structured DTO & NOT_CONFIGURED when empty
    await test('16. GET_STAFF_SCHEDULE returns NOT_CONFIGURED for staff without configured schedule', async () => {
      // Ensure owner has no schedule
      await client.query('DELETE FROM staff_schedules WHERE membership_id = $1;', [ownerMembershipId]);

      const { req, res } = createMockReqRes({
        tenantId: 2,
        establishmentId: testEstId,
        membershipId: ownerMembershipId,
        activeContext: ownerContext,
        params: { membership_id: ownerMembershipId }
      });

      await staffAvailabilityController.getStaffSchedule(req, res);
      assert.strictEqual(res.getStatusCode(), 200);
      const data = res.getBody().data;
      assert.strictEqual(data.schedule_state, 'NOT_CONFIGURED');
      assert.strictEqual(data.weekly_schedule.monday.is_working, false);
      assert.strictEqual(data.weekly_schedule.monday.time_blocks.length, 0);
    });

    // 17. LIST_ESTABLISHMENT_STAFF_SCHEDULES lists all active staff
    await test('17. LIST_ESTABLISHMENT_STAFF_SCHEDULES lists all active staff with their schedule state', async () => {
      const { req, res } = createMockReqRes({
        tenantId: 2,
        establishmentId: testEstId,
        membershipId: ownerMembershipId,
        activeContext: ownerContext
      });

      await staffAvailabilityController.listEstablishmentStaffSchedules(req, res);
      assert.strictEqual(res.getStatusCode(), 200);
      const list = res.getBody().data;
      assert.ok(Array.isArray(list));
      assert.ok(list.length >= 2);
      const profEntry = list.find(s => s.membership_id === profMembershipId);
      assert.ok(profEntry);
      assert.strictEqual(profEntry.schedule_state, 'CONFIGURED');
    });

    // 18. DELETE_STAFF_SCHEDULE removes schedule and leaves Membership intact
    await test('18. DELETE_STAFF_SCHEDULE removes all schedules and preserves Membership intact', async () => {
      const { req, res } = createMockReqRes({
        tenantId: 2,
        establishmentId: testEstId,
        membershipId: ownerMembershipId,
        activeContext: ownerContext,
        params: { membership_id: profMembershipId }
      });

      await staffAvailabilityController.deleteStaffSchedule(req, res);
      assert.strictEqual(res.getStatusCode(), 200);
      assert.strictEqual(res.getBody().data.schedule_state, 'NOT_CONFIGURED');

      // Verify DB schedule is 0 rows
      const sRes = await client.query('SELECT count(*)::int AS cnt FROM staff_schedules WHERE membership_id = $1;', [profMembershipId]);
      assert.strictEqual(sRes.rows[0].cnt, 0);

      // Verify Membership is STILL ACTIVE and unchanged
      const mRes = await client.query('SELECT status, role FROM memberships WHERE id = $1;', [profMembershipId]);
      assert.strictEqual(mRes.rows.length, 1);
      assert.strictEqual(mRes.rows[0].status, 'ACTIVE');
      assert.strictEqual(mRes.rows[0].role, 'PROFESSIONAL');
    });

    // 19. PROFESSIONAL cannot DELETE schedule (403 Forbidden)
    await test('19. PROFESSIONAL cannot delete schedule (403 Forbidden)', async () => {
      const { req, res } = createMockReqRes({
        tenantId: 2,
        establishmentId: testEstId,
        membershipId: profMembershipId,
        activeContext: profContext,
        params: { membership_id: profMembershipId }
      });

      await staffAvailabilityController.deleteStaffSchedule(req, res);
      assert.strictEqual(res.getStatusCode(), 403);
      assert.strictEqual(res.getBody().code, 'FORBIDDEN_ROLE');
    });

    // 20. RLS Isolation check across tenants
    await test('20. RLS Isolation: Schedule created in Tenant 2 is invisible when app.tenant_id = 1', async () => {
      // Configure schedule for profMembershipId in Tenant 2
      const setReq = createMockReqRes({
        tenantId: 2,
        establishmentId: testEstId,
        membershipId: ownerMembershipId,
        activeContext: ownerContext,
        params: { membership_id: profMembershipId },
        body: {
          weekly_schedule: {
            monday: { is_working: true, time_blocks: [{ start_time: '08:00', end_time: '12:00' }] }
          }
        }
      });
      await staffAvailabilityController.setStaffSchedule(setReq.req, setReq.res);
      assert.strictEqual(setReq.res.getStatusCode(), 200);

      // Connect as non-superuser client and switch app.tenant_id to '1'
      const isolatedClient = await pool.connect();
      try {
        await isolatedClient.query("SELECT set_config('app.tenant_id', '1', false);");
        const rlsRes = await isolatedClient.query('SELECT * FROM staff_schedules WHERE membership_id = $1;', [profMembershipId]);
        assert.strictEqual(rlsRes.rows.length, 0, 'RLS must block access to staff_schedules of Tenant 2 when tenant_id=1');
      } finally {
        isolatedClient.release();
      }
    });

  } finally {
    client.release();
  }

  console.log('\n================================================================================');
  console.log(`TEST RESULTS: ${passed} PASSED | ${failed} FAILED`);
  console.log('================================================================================\n');

  if (failed > 0) {
    throw new Error(`${failed} tests failed in Staff Availability test suite.`);
  }
}

if (require.main === module) {
  runStaffAvailabilitySuite()
    .then(() => {
      console.log('✅ Staff Availability Suite executed successfully.');
      process.exit(0);
    })
    .catch((err) => {
      console.error('❌ Test Suite Execution Failed:', err);
      process.exit(1);
    });
}

module.exports = { runStaffAvailabilitySuite };
