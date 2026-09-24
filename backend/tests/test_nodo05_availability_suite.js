// backend/tests/test_nodo05_availability_suite.js
const assert = require('assert');
const { pool } = require('../src/config/db');
const nodo05AvailabilityService = require('../src/services/nodo05AvailabilityService');
const nodo05AvailabilityController = require('../src/controllers/nodo05AvailabilityController');

function createMockReqRes(options = {}) {
  const req = {
    user: options.user !== undefined ? options.user : { id: 7, email: 'demo@beautyapp.com' },
    headers: options.headers || {},
    body: options.body || {},
    query: options.query || {},
    params: options.params || {},
    tenantId: options.tenantId !== undefined ? options.tenantId : 2,
    establishmentId: options.establishmentId || null,
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

async function runNodo05Suite() {
  console.log('================================================================================');
  console.log('       NODO-05 — AVAILABILITY PROJECTION & BOOKING SLOT ENGINE TEST SUITE');
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
  await client.query('BEGIN');
  await client.query("SELECT set_config('app.tenant_id', '2', true);");

  try {
    // Check runtime database privileges (must not be superuser or bypassrls)
    const privRes = await client.query(`
      SELECT rolname, rolsuper, rolbypassrls 
      FROM pg_roles 
      WHERE rolname = current_user;
    `);
    console.log('[Runtime Privileges]:', privRes.rows[0]);
    if (privRes.rows[0].rolsuper || privRes.rows[0].rolbypassrls) {
      throw new Error('FATAL: Runtime user is superuser or bypasses RLS!');
    }

    const tenantId = 2;
    const foreignTenantId = 1;

    // 1. Get or create test establishment in Tenant 2
    const estRes = await client.query("SELECT id FROM establishments WHERE tenant_id = $1 LIMIT 1;", [tenantId]);
    assert.ok(estRes.rows.length > 0, 'Establishment must exist for Tenant 2');
    const establishmentId = estRes.rows[0].id;

    // Update establishment operating_hours to standard Tuesday 08:00 - 18:00
    const testOperatingHours = {
      tuesday: { is_open: true, open_time: '08:00', close_time: '18:00' },
      sunday: { is_open: false, open_time: '09:00', close_time: '14:00' }
    };
    await client.query(
      "UPDATE establishments SET operating_hours = $1 WHERE id = $2;",
      [JSON.stringify(testOperatingHours), establishmentId]
    );

    // Foreign establishment for Tenant 1
    await client.query("SELECT set_config('app.tenant_id', '1', true);");
    const foreignEstRes = await client.query("SELECT id FROM establishments WHERE tenant_id = $1 LIMIT 1;", [foreignTenantId]);
    assert.ok(foreignEstRes.rows.length > 0, 'Establishment must exist for Tenant 1');
    const foreignEstablishmentId = foreignEstRes.rows[0].id;

    // Switch back to Tenant 2
    await client.query("SELECT set_config('app.tenant_id', '2', true);");

    // 2. Create/Get Staff 1 User & Active Membership
    const staff1UserRes = await client.query(`
      INSERT INTO usuarios (email, nombre, rol, tenant_id, auth_provider, provider_id, password_hash)
      VALUES ('nodo05_staff1@beautyapp.com', 'NODO-05 Staff One', 'PRESTADOR', 2, 'LOCAL', 'nodo05-staff1-loc', 'hash')
      ON CONFLICT (email) DO UPDATE SET is_active = true
      RETURNING id;
    `);
    const staff1UserId = staff1UserRes.rows[0].id;

    // Ensure perfiles_prestador exists for staff1 in tenant 2
    await client.query(`
      INSERT INTO perfiles_prestador (id, tenant_id, is_active)
      VALUES ($1, $2, true)
      ON CONFLICT (id) DO UPDATE SET tenant_id = $2;
    `, [staff1UserId, tenantId]);

    const staff1MemberRes = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, $2, 'PROFESSIONAL', 'STAFF_EMPLOYEE', 'ACTIVE')
      ON CONFLICT (establishment_id, user_id)
      DO UPDATE SET status = 'ACTIVE', role = 'PROFESSIONAL'
      RETURNING id;
    `, [establishmentId, staff1UserId]);
    const staff1MembershipId = staff1MemberRes.rows[0].id;

    // 3. Create/Get Staff 2 User & Active Membership
    const staff2UserRes = await client.query(`
      INSERT INTO usuarios (email, nombre, rol, tenant_id, auth_provider, provider_id, password_hash)
      VALUES ('nodo05_staff2@beautyapp.com', 'NODO-05 Staff Two', 'PRESTADOR', 2, 'LOCAL', 'nodo05-staff2-loc', 'hash')
      ON CONFLICT (email) DO UPDATE SET is_active = true
      RETURNING id;
    `);
    const staff2UserId = staff2UserRes.rows[0].id;

    // Ensure perfiles_prestador exists for staff2 in tenant 2
    await client.query(`
      INSERT INTO perfiles_prestador (id, tenant_id, is_active)
      VALUES ($1, $2, true)
      ON CONFLICT (id) DO UPDATE SET tenant_id = $2;
    `, [staff2UserId, tenantId]);

    const staff2MemberRes = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, $2, 'PROFESSIONAL', 'STAFF_EMPLOYEE', 'ACTIVE')
      ON CONFLICT (establishment_id, user_id)
      DO UPDATE SET status = 'ACTIVE', role = 'PROFESSIONAL'
      RETURNING id;
    `, [establishmentId, staff2UserId]);
    const staff2MembershipId = staff2MemberRes.rows[0].id;

    // 4. Create/Get Inactive / Suspended Staff Membership
    const staffSuspUserRes = await client.query(`
      INSERT INTO usuarios (email, nombre, rol, tenant_id, auth_provider, provider_id, password_hash)
      VALUES ('nodo05_staff_susp@beautyapp.com', 'NODO-05 Suspended Staff', 'PRESTADOR', 2, 'LOCAL', 'nodo05-staffsusp-loc', 'hash')
      ON CONFLICT (email) DO UPDATE SET is_active = true
      RETURNING id;
    `);
    const staffSuspUserId = staffSuspUserRes.rows[0].id;

    const staffSuspMemberRes = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES (2, $1, $2, 'PROFESSIONAL', 'STAFF_EMPLOYEE', 'SUSPENDED')
      ON CONFLICT (establishment_id, user_id)
      DO UPDATE SET status = 'SUSPENDED', role = 'PROFESSIONAL'
      RETURNING id;
    `, [establishmentId, staffSuspUserId]);
    const staffSuspMembershipId = staffSuspMemberRes.rows[0].id;

    // 5. Setup Staff Schedules for Tuesday (day_of_week = 2)
    await client.query("DELETE FROM staff_schedules WHERE membership_id = ANY($1::uuid[]);", [[staff1MembershipId, staff2MembershipId, staffSuspMembershipId]]);

    // Staff 1 works Tuesday 09:00 - 13:00 and 14:00 - 18:00
    await client.query(`
      INSERT INTO staff_schedules (tenant_id, establishment_id, membership_id, day_of_week, start_time, end_time)
      VALUES 
        (2, $1, $2, 2, '09:00', '13:00'),
        (2, $1, $2, 2, '14:00', '18:00');
    `, [establishmentId, staff1MembershipId]);

    // Staff 2 works Tuesday 10:00 - 16:00
    await client.query(`
      INSERT INTO staff_schedules (tenant_id, establishment_id, membership_id, day_of_week, start_time, end_time)
      VALUES 
        (2, $1, $2, 2, '10:00', '16:00');
    `, [establishmentId, staff2MembershipId]);

    // 6. Create Service Offer 1 (Duration = 45 min)
    const offer1Res = await client.query(`
      INSERT INTO service_offers (tenant_id, establishment_id, name, description, base_price, base_duration)
      VALUES (2, $1, 'Corte & Peinado NODO-05', 'Servicio de prueba NODO-05', 45000, 45)
      RETURNING id;
    `, [establishmentId]);
    const serviceOfferId = offer1Res.rows[0].id;

    // Create Service Offer 2 (Zero Assignments Offer)
    const offerZeroRes = await client.query(`
      INSERT INTO service_offers (tenant_id, establishment_id, name, description, base_price, base_duration)
      VALUES (2, $1, 'Oferta Sin Asignar NODO-05', 'Servicio sin staff', 60000, 30)
      RETURNING id;
    `, [establishmentId]);
    const serviceOfferZeroId = offerZeroRes.rows[0].id;

    // Create Service Offer 3 (Duration = 90 min)
    const offer90Res = await client.query(`
      INSERT INTO service_offers (tenant_id, establishment_id, name, description, base_price, base_duration)
      VALUES (2, $1, 'Colorimetria Larga NODO-05', 'Servicio largo 90 min', 120000, 90)
      RETURNING id;
    `, [establishmentId]);
    const serviceOffer90Id = offer90Res.rows[0].id;

    // 7. Assign Staff 1 and Staff 2 to Service Offer 1
    await client.query("DELETE FROM service_assignments WHERE service_offer_id = ANY($1::uuid[]);", [[serviceOfferId, serviceOfferZeroId, serviceOffer90Id]]);
    await client.query(`
      INSERT INTO service_assignments (tenant_id, establishment_id, service_offer_id, membership_id)
      VALUES 
        (2, $1, $2, $3),
        (2, $1, $2, $4),
        (2, $1, $5, $3);
    `, [establishmentId, serviceOfferId, staff1MembershipId, staff2MembershipId, serviceOffer90Id]);

    // 8. Create a test B2C service for booking linkage (60 min duration)
    const b2cServRes = await client.query(`
      INSERT INTO services (provider_id, name, description, price, duration_minutes, is_active, tenant_id)
      VALUES ($1, 'Servicio B2C NODO-05', 'Test', 50000, 60, true, 2)
      RETURNING id;
    `, [staff1UserId]);
    const b2cServiceId = b2cServRes.rows[0].id;

    // Clean up any old test bookings for staff1 and staff2 on target date 2026-09-15
    await client.query(`
      DELETE FROM bookings 
      WHERE provider_id = ANY($1::int[]) 
        AND scheduled_at >= '2026-09-15 00:00:00+00' 
        AND scheduled_at <= '2026-09-16 23:59:59+00';
    `, [[staff1UserId, staff2UserId, staffSuspUserId]]);

    await client.query('COMMIT');

    const activeContext = {
      tenant_id: 2,
      establishment_id: establishmentId,
      role: 'OWNER',
      status: 'ACTIVE',
      membership_id: staff1MembershipId,
    };

    console.log('Test fixtures initialized successfully.\n');

    // =========================================================================
    // TEST CATEGORY 01: BASIC PROJECTION SUCCESS
    // =========================================================================
    await test('T01_BASIC_PROJECTION_SUCCESS', async () => {
      const { req, res } = createMockReqRes({
        tenantId,
        establishmentId,
        activeContext,
        query: {
          service_offer_id: serviceOfferId,
          target_date: '2026-09-15', // Tuesday
        },
      });

      await nodo05AvailabilityController.getAvailabilityProjection(req, res);
      assert.strictEqual(res.getStatusCode(), 200);

      const body = res.getBody();
      assert.strictEqual(body.status, 'success');
      assert.ok(body.data);
      assert.strictEqual(body.data.establishment_id, establishmentId);
      assert.strictEqual(body.data.service_offer_id, serviceOfferId);
      assert.strictEqual(body.data.target_date, '2026-09-15');
      assert.strictEqual(body.data.day_of_week, 2);
      assert.strictEqual(body.data.service_duration_minutes, 45);
      assert.strictEqual(body.data.step_minutes, 15);
      assert.strictEqual(body.data.projection_mode, 'AGGREGATED');
      assert.ok(Array.isArray(body.data.slots));
      assert.ok(body.data.slots.length > 0);

      const firstSlot = body.data.slots[0];
      assert.ok(firstSlot.start_time);
      assert.ok(firstSlot.end_time);
      assert.ok(Array.isArray(firstSlot.available_memberships));
      assert.strictEqual(firstSlot.start_time, '09:00');
      assert.strictEqual(firstSlot.end_time, '09:45');
    });

    // =========================================================================
    // TEST CATEGORY 02: DEFAULT STEP MINUTES (15 MIN)
    // =========================================================================
    await test('T02_DEFAULT_STEP_MINUTES_15', async () => {
      const result = await nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
        service_offer_id: serviceOfferId,
        target_date: '2026-09-15',
      });

      assert.strictEqual(result.step_minutes, 15);
      assert.strictEqual(result.slots[0].start_time, '09:00');
      assert.strictEqual(result.slots[1].start_time, '09:15');
      assert.strictEqual(result.slots[2].start_time, '09:30');
    });

    // =========================================================================
    // TEST CATEGORY 03: CUSTOM STEP MINUTES (30 MIN)
    // =========================================================================
    await test('T03_CUSTOM_STEP_MINUTES_30', async () => {
      const result = await nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
        service_offer_id: serviceOfferId,
        target_date: '2026-09-15',
        step_minutes: 30,
      });

      assert.strictEqual(result.step_minutes, 30);
      assert.strictEqual(result.slots[0].start_time, '09:00');
      assert.strictEqual(result.slots[1].start_time, '09:30');
      assert.strictEqual(result.slots[2].start_time, '10:00');
    });

    // =========================================================================
    // TEST CATEGORY 04: TARGETED MODE PROJECTION (EXPLICIT & DERIVED)
    // =========================================================================
    await test('T04_TARGETED_PROJECTION_SUCCESS', async () => {
      // 1. Explicit projection_mode = 'TARGETED'
      const resultExplicit = await nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
        service_offer_id: serviceOfferId,
        target_date: '2026-09-15',
        projection_mode: 'TARGETED',
        membership_id: staff1MembershipId,
      });

      assert.strictEqual(resultExplicit.projection_mode, 'TARGETED');
      assert.ok(resultExplicit.slots.length > 0);
      for (const slot of resultExplicit.slots) {
        assert.deepStrictEqual(slot.available_memberships, [staff1MembershipId]);
      }

      // 2. Omitted projection_mode with membership_id -> Derived TARGETED
      const resultDerived = await nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
        service_offer_id: serviceOfferId,
        target_date: '2026-09-15',
        membership_id: staff1MembershipId,
      });
      assert.strictEqual(resultDerived.projection_mode, 'TARGETED');
    });

    // =========================================================================
    // TEST CATEGORY 04B: TARGETED MODE VALIDATION (MISSING MEMBERSHIP_ID)
    // =========================================================================
    await test('T04B_TARGETED_MODE_MISSING_MEMBERSHIP_400', async () => {
      let threw = false;
      try {
        await nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
          service_offer_id: serviceOfferId,
          target_date: '2026-09-15',
          projection_mode: 'TARGETED',
          // membership_id absent
        });
      } catch (err) {
        threw = true;
        assert.strictEqual(err.statusCode, 400);
        assert.strictEqual(err.code, 'MEMBERSHIP_ID_REQUIRED');
      }
      assert.ok(threw, 'Must throw 400 MEMBERSHIP_ID_REQUIRED when projection_mode=TARGETED lacks membership_id');
    });

    // =========================================================================
    // TEST CATEGORY 05: AGGREGATED MODE PROJECTION (EXPLICIT & DERIVED)
    // =========================================================================
    await test('T05_AGGREGATED_PROJECTION_SUCCESS', async () => {
      // 1. Explicit projection_mode = 'AGGREGATED'
      const resultExplicit = await nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
        service_offer_id: serviceOfferId,
        target_date: '2026-09-15',
        projection_mode: 'AGGREGATED',
      });

      assert.strictEqual(resultExplicit.projection_mode, 'AGGREGATED');
      const slot0900 = resultExplicit.slots.find((s) => s.start_time === '09:00');
      assert.ok(slot0900);
      assert.deepStrictEqual(slot0900.available_memberships, [staff1MembershipId]);

      const slot1000 = resultExplicit.slots.find((s) => s.start_time === '10:00');
      assert.ok(slot1000);
      const expectedMembers = [staff1MembershipId, staff2MembershipId].sort();
      assert.deepStrictEqual(slot1000.available_memberships, expectedMembers);
    });

    // =========================================================================
    // TEST CATEGORY 05B: AGGREGATED MODE VALIDATION (UNAUTHORIZED MEMBERSHIP_ID)
    // =========================================================================
    await test('T05B_AGGREGATED_MODE_WITH_MEMBERSHIP_400', async () => {
      let threw = false;
      try {
        await nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
          service_offer_id: serviceOfferId,
          target_date: '2026-09-15',
          projection_mode: 'AGGREGATED',
          membership_id: staff1MembershipId, // Forbidden in AGGREGATED
        });
      } catch (err) {
        threw = true;
        assert.strictEqual(err.statusCode, 400);
        assert.strictEqual(err.code, 'INVALID_PROJECTION_MODE');
      }
      assert.ok(threw, 'Must throw 400 INVALID_PROJECTION_MODE when membership_id is supplied in AGGREGATED mode');
    });

    // =========================================================================
    // TEST CATEGORY 05C: INVALID PROJECTION MODE VALUE (400)
    // =========================================================================
    await test('T05C_INVALID_PROJECTION_MODE_400', async () => {
      let threw = false;
      try {
        await nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
          service_offer_id: serviceOfferId,
          target_date: '2026-09-15',
          projection_mode: 'INVALID_MODE',
        });
      } catch (err) {
        threw = true;
        assert.strictEqual(err.statusCode, 400);
        assert.strictEqual(err.code, 'INVALID_PROJECTION_MODE');
      }
      assert.ok(threw, 'Must throw 400 INVALID_PROJECTION_MODE for arbitrary mode strings');
    });

    // =========================================================================
    // TEST CATEGORY 06: ZERO ASSIGNMENTS BEHAVIOR (N05-DEC-06: 200 OK SLOTS [])
    // =========================================================================
    await test('T06_ZERO_ASSIGNMENTS_EMPTY_200', async () => {
      const { req, res } = createMockReqRes({
        tenantId,
        establishmentId,
        activeContext,
        query: {
          service_offer_id: serviceOfferZeroId,
          target_date: '2026-09-15',
        },
      });

      await nodo05AvailabilityController.getAvailabilityProjection(req, res);
      assert.strictEqual(res.getStatusCode(), 200);

      const body = res.getBody();
      assert.strictEqual(body.status, 'success');
      assert.strictEqual(body.data.service_offer_id, serviceOfferZeroId);
      assert.deepStrictEqual(body.data.slots, []);
    });

    // =========================================================================
    // TEST CATEGORY 07: STAFF SCHEDULE INTERSECTION (MIGRATION 069)
    // =========================================================================
    await test('T07_STAFF_SCHEDULE_INTERSECTION', async () => {
      const result = await nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
        service_offer_id: serviceOfferId,
        target_date: '2026-09-15',
        membership_id: staff1MembershipId,
      });

      const slot1215 = result.slots.find((s) => s.start_time === '12:15');
      assert.ok(slot1215, 'Slot 12:15 (ending at 13:00) should be available');
      assert.strictEqual(slot1215.end_time, '13:00');

      const slot1230 = result.slots.find((s) => s.start_time === '12:30');
      assert.strictEqual(slot1230, undefined, 'Slot 12:30 must NOT be available because it exceeds 13:00');

      const slot1300 = result.slots.find((s) => s.start_time === '13:00');
      assert.strictEqual(slot1300, undefined, 'Slot 13:00 must NOT be available during lunch break');

      const slot1400 = result.slots.find((s) => s.start_time === '14:00');
      assert.ok(slot1400, 'Slot 14:00 should be available');
    });

    // =========================================================================
    // TEST CATEGORY 08: ESTABLISHMENT OPERATING HOURS INTERSECTION (N05-DEC-02)
    // =========================================================================
    await test('T08_ESTABLISHMENT_HOURS_INTERSECTION', async () => {
      // 1. Closed day (Sunday)
      const sundayResult = await nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
        service_offer_id: serviceOfferId,
        target_date: '2026-09-20', // Sunday (day_of_week = 7)
      });
      assert.strictEqual(sundayResult.day_of_week, 7);
      assert.deepStrictEqual(sundayResult.slots, [], 'Closed establishment on Sunday returns empty slots');

      // 2. Modify establishment Tuesday opening hours to 10:00 - 17:00
      const modifyClient = await pool.connect();
      try {
        await modifyClient.query('BEGIN');
        await modifyClient.query("SELECT set_config('app.tenant_id', '2', true);");
        await modifyClient.query(
          "UPDATE establishments SET operating_hours = $1 WHERE id = $2;",
          [JSON.stringify({ tuesday: { is_open: true, open_time: '10:00', close_time: '17:00' } }), establishmentId]
        );
        await modifyClient.query('COMMIT');
      } finally {
        modifyClient.release();
      }

      const lateOpenResult = await nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
        service_offer_id: serviceOfferId,
        target_date: '2026-09-15',
        membership_id: staff1MembershipId,
      });

      const slot0900 = lateOpenResult.slots.find((s) => s.start_time === '09:00');
      assert.strictEqual(slot0900, undefined, 'No slot before establishment open time');
      assert.strictEqual(lateOpenResult.slots[0].start_time, '10:00');

      // Restore standard operating hours
      const restoreClient = await pool.connect();
      try {
        await restoreClient.query('BEGIN');
        await restoreClient.query("SELECT set_config('app.tenant_id', '2', true);");
        await restoreClient.query(
          "UPDATE establishments SET operating_hours = $1 WHERE id = $2;",
          [JSON.stringify(testOperatingHours), establishmentId]
        );
        await restoreClient.query('COMMIT');
      } finally {
        restoreClient.release();
      }
    });

    // =========================================================================
    // TEST CATEGORY 09: BOOKING COLLISION EXCLUSION (ACTIVE BOOKINGS)
    // =========================================================================
    await test('T09_BOOKING_COLLISION_EXCLUSION', async () => {
      let bookingId;
      const bClient = await pool.connect();
      try {
        await bClient.query('BEGIN');
        await bClient.query("SELECT set_config('app.tenant_id', '2', true);");
        const bRes = await bClient.query(`
          INSERT INTO bookings (client_id, provider_id, service_id, scheduled_at, estado, valor_bruto, tenant_id)
          VALUES (7, $1, $2, '2026-09-15 15:00:00+00', 'CONFIRMADA', 50000, 2)
          RETURNING id;
        `, [staff1UserId, b2cServiceId]);
        bookingId = bRes.rows[0].id;
        await bClient.query('COMMIT');
      } finally {
        bClient.release();
      }

      try {
        const result = await nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
          service_offer_id: serviceOfferId, // 45 min service duration
          target_date: '2026-09-15',
          membership_id: staff1MembershipId,
        });

        const slot0915 = result.slots.find((s) => s.start_time === '09:15');
        assert.ok(slot0915, 'Slot 09:15 (ending at 10:00) should be available');

        const slot0930 = result.slots.find((s) => s.start_time === '09:30');
        assert.strictEqual(slot0930, undefined, 'Slot 09:30 collides with booking and must be excluded');

        const slot1000 = result.slots.find((s) => s.start_time === '10:00');
        assert.strictEqual(slot1000, undefined, 'Slot 10:00 collides with booking and must be excluded');

        const slot1030 = result.slots.find((s) => s.start_time === '10:30');
        assert.strictEqual(slot1030, undefined, 'Slot 10:30 collides with booking and must be excluded');
      } finally {
        const delClient = await pool.connect();
        try {
          await delClient.query('BEGIN');
          await delClient.query("SELECT set_config('app.tenant_id', '2', true);");
          await delClient.query("DELETE FROM bookings WHERE id = $1;", [bookingId]);
          await delClient.query('COMMIT');
        } finally {
          delClient.release();
        }
      }
    });

    // =========================================================================
    // TEST CATEGORY 10: CANCELLED BOOKING EXCLUSION (IGNORED)
    // =========================================================================
    await test('T10_CANCELLED_BOOKING_IGNORED', async () => {
      let bookingId;
      const bClient = await pool.connect();
      try {
        await bClient.query('BEGIN');
        await bClient.query("SELECT set_config('app.tenant_id', '2', true);");
        const bRes = await bClient.query(`
          INSERT INTO bookings (client_id, provider_id, service_id, scheduled_at, estado, valor_bruto, tenant_id)
          VALUES (7, $1, $2, '2026-09-15 15:00:00+00', 'CANCELADA', 50000, 2)
          RETURNING id;
        `, [staff1UserId, b2cServiceId]);
        bookingId = bRes.rows[0].id;
        await bClient.query('COMMIT');
      } finally {
        bClient.release();
      }

      try {
        const result = await nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
          service_offer_id: serviceOfferId,
          target_date: '2026-09-15',
          membership_id: staff1MembershipId,
        });

        const slot1000 = result.slots.find((s) => s.start_time === '10:00');
        assert.ok(slot1000, 'Slot 10:00 should be available because booking is CANCELADA');
      } finally {
        const delClient = await pool.connect();
        try {
          await delClient.query('BEGIN');
          await delClient.query("SELECT set_config('app.tenant_id', '2', true);");
          await delClient.query("DELETE FROM bookings WHERE id = $1;", [bookingId]);
          await delClient.query('COMMIT');
        } finally {
          delClient.release();
        }
      }
    });

    // =========================================================================
    // TEST CATEGORY 11: BACK-TO-BACK AVAILABILITY (CONTIGUOUS SEMI-OPEN INTERVALS)
    // =========================================================================
    await test('T11_BACK_TO_BACK_CONTIGUOUS', async () => {
      let bookingId;
      const bClient = await pool.connect();
      try {
        await bClient.query('BEGIN');
        await bClient.query("SELECT set_config('app.tenant_id', '2', true);");
        const bRes = await bClient.query(`
          INSERT INTO bookings (client_id, provider_id, service_id, scheduled_at, estado, valor_bruto, tenant_id)
          VALUES (7, $1, $2, '2026-09-15 15:00:00+00', 'CONFIRMADA', 50000, 2)
          RETURNING id;
        `, [staff1UserId, b2cServiceId]);
        bookingId = bRes.rows[0].id;
        await bClient.query('COMMIT');
      } finally {
        bClient.release();
      }

      try {
        const result = await nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
          service_offer_id: serviceOfferId,
          target_date: '2026-09-15',
          membership_id: staff1MembershipId,
        });

        const slot1100 = result.slots.find((s) => s.start_time === '11:00');
        assert.ok(slot1100, 'Slot 11:00 must be available contiguous to booking ending at 11:00');
        assert.strictEqual(slot1100.end_time, '11:45');
      } finally {
        const delClient = await pool.connect();
        try {
          await delClient.query('BEGIN');
          await delClient.query("SELECT set_config('app.tenant_id', '2', true);");
          await delClient.query("DELETE FROM bookings WHERE id = $1;", [bookingId]);
          await delClient.query('COMMIT');
        } finally {
          delClient.release();
        }
      }
    });

    // =========================================================================
    // TEST CATEGORY 12: DETERMINISTIC ORDERING (SLOTS ASC, MEMBERS UUID ASC)
    // =========================================================================
    await test('T12_DETERMINISTIC_ORDERING', async () => {
      const result = await nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
        service_offer_id: serviceOfferId,
        target_date: '2026-09-15',
      });

      for (let i = 1; i < result.slots.length; i++) {
        assert.ok(result.slots[i].start_time > result.slots[i - 1].start_time, 'Slots must be strictly ascending');
      }

      for (const slot of result.slots) {
        const sortedCopy = [...slot.available_memberships].sort();
        assert.deepStrictEqual(slot.available_memberships, sortedCopy, 'Memberships must be sorted ASC');
      }
    });

    // =========================================================================
    // TEST CATEGORY 13: CROSS-ESTABLISHMENT ISOLATION
    // =========================================================================
    await test('T13_CROSS_ESTABLISHMENT_ISOLATION', async () => {
      let foreignOfferId;
      const fClient = await pool.connect();
      try {
        await fClient.query('BEGIN');
        await fClient.query("SELECT set_config('app.tenant_id', '1', true);");
        const foreignOfferRes = await fClient.query(`
          INSERT INTO service_offers (tenant_id, establishment_id, name, description, base_price, base_duration)
          VALUES (1, $1, 'Foreign Offer', 'Desc', 50000, 30)
          RETURNING id;
        `, [foreignEstablishmentId]);
        foreignOfferId = foreignOfferRes.rows[0].id;
        await fClient.query('COMMIT');
      } finally {
        fClient.release();
      }

      let threw = false;
      try {
        await nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
          service_offer_id: foreignOfferId,
          target_date: '2026-09-15',
        });
      } catch (err) {
        threw = true;
        assert.strictEqual(err.statusCode, 404);
        assert.strictEqual(err.code, 'SERVICE_OFFER_NOT_FOUND');
      }
      assert.ok(threw, 'Must throw 404 for cross-establishment offer');
    });

    // =========================================================================
    // TEST CATEGORY 14: CROSS-TENANT ISOLATION (RLS ENFORCEMENT)
    // =========================================================================
    await test('T14_CROSS_TENANT_ISOLATION_RLS', async () => {
      const foreignContext = {
        tenant_id: foreignTenantId,
        establishment_id: foreignEstablishmentId,
        role: 'OWNER',
        status: 'ACTIVE',
        membership_id: staff1MembershipId,
      };

      let threw = false;
      try {
        await nodo05AvailabilityService.projectAvailability(foreignTenantId, foreignEstablishmentId, foreignContext, {
          service_offer_id: serviceOfferId, // Belongs to Tenant 2
          target_date: '2026-09-15',
        });
      } catch (err) {
        threw = true;
        assert.strictEqual(err.statusCode, 404);
        assert.strictEqual(err.code, 'SERVICE_OFFER_NOT_FOUND');
      }
      assert.ok(threw, 'Must throw 404 when querying across tenant boundary');
    });

    // =========================================================================
    // TEST CATEGORY 15: INVALID SERVICE OFFER HANDLING (404)
    // =========================================================================
    await test('T15_SERVICE_OFFER_NOT_FOUND_404', async () => {
      const nonExistentOfferId = '00000000-0000-0000-0000-000000000000';
      let threw = false;
      try {
        await nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
          service_offer_id: nonExistentOfferId,
          target_date: '2026-09-15',
        });
      } catch (err) {
        threw = true;
        assert.strictEqual(err.statusCode, 404);
        assert.strictEqual(err.code, 'SERVICE_OFFER_NOT_FOUND');
      }
      assert.ok(threw, 'Must throw 404 for non-existent service offer UUID');
    });

    // =========================================================================
    // TEST CATEGORY 16: INVALID / INACTIVE MEMBERSHIP (422 / 404)
    // =========================================================================
    await test('T16_INVALID_INACTIVE_MEMBERSHIP_422', async () => {
      // 1. Inactive / Suspended membership
      let threwSusp = false;
      try {
        await nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
          service_offer_id: serviceOfferId,
          target_date: '2026-09-15',
          membership_id: staffSuspMembershipId,
        });
      } catch (err) {
        threwSusp = true;
        assert.strictEqual(err.statusCode, 422);
        assert.strictEqual(err.code, 'INACTIVE_MEMBERSHIP');
      }
      assert.ok(threwSusp, 'Must throw 422 for INACTIVE_MEMBERSHIP');

      // 2. Unassigned staff member
      let threwUnassigned = false;
      try {
        await nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
          service_offer_id: serviceOffer90Id, // Staff 2 is NOT assigned to offer 90
          target_date: '2026-09-15',
          membership_id: staff2MembershipId,
        });
      } catch (err) {
        threwUnassigned = true;
        assert.strictEqual(err.statusCode, 422);
        assert.strictEqual(err.code, 'UNASSIGNED_PROFESSIONAL');
      }
      assert.ok(threwUnassigned, 'Must throw 422 for UNASSIGNED_PROFESSIONAL');
    });

    // =========================================================================
    // TEST CATEGORY 17: TIMEZONE BOUNDARY HANDLING (AMERICA/BOGOTA UTC-5)
    // =========================================================================
    await test('T17_TIMEZONE_BOUNDARY_HANDLING', async () => {
      let bookingId;
      const bClient = await pool.connect();
      try {
        await bClient.query('BEGIN');
        await bClient.query("SELECT set_config('app.tenant_id', '2', true);");
        const bRes = await bClient.query(`
          INSERT INTO bookings (client_id, provider_id, service_id, scheduled_at, estado, valor_bruto, tenant_id)
          VALUES (7, $1, $2, '2026-09-15 14:00:00+00', 'CONFIRMADA', 50000, 2)
          RETURNING id;
        `, [staff1UserId, b2cServiceId]);
        bookingId = bRes.rows[0].id;
        await bClient.query('COMMIT');
      } finally {
        bClient.release();
      }

      try {
        const result = await nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
          service_offer_id: serviceOfferId,
          target_date: '2026-09-15',
          membership_id: staff1MembershipId,
        });

        const slot0900 = result.slots.find((s) => s.start_time === '09:00');
        assert.strictEqual(slot0900, undefined, 'Slot 09:00 COT must be excluded by 14:00 UTC booking');
      } finally {
        const delClient = await pool.connect();
        try {
          await delClient.query('BEGIN');
          await delClient.query("SELECT set_config('app.tenant_id', '2', true);");
          await delClient.query("DELETE FROM bookings WHERE id = $1;", [bookingId]);
          await delClient.query('COMMIT');
        } finally {
          delClient.release();
        }
      }
    });

    // =========================================================================
    // TEST CATEGORY 18: DATE / DAY-OF-WEEK CORRECTNESS (1..7)
    // =========================================================================
    await test('T18_DATE_DAY_OF_WEEK_CORRECTNESS', async () => {
      assert.strictEqual(nodo05AvailabilityService.getDayOfWeek('2026-09-14'), 1); // Monday
      assert.strictEqual(nodo05AvailabilityService.getDayOfWeek('2026-09-15'), 2); // Tuesday
      assert.strictEqual(nodo05AvailabilityService.getDayOfWeek('2026-09-16'), 3); // Wednesday
      assert.strictEqual(nodo05AvailabilityService.getDayOfWeek('2026-09-17'), 4); // Thursday
      assert.strictEqual(nodo05AvailabilityService.getDayOfWeek('2026-09-18'), 5); // Friday
      assert.strictEqual(nodo05AvailabilityService.getDayOfWeek('2026-09-19'), 6); // Saturday
      assert.strictEqual(nodo05AvailabilityService.getDayOfWeek('2026-09-20'), 7); // Sunday
    });

    // =========================================================================
    // TEST CATEGORY 19: SERVICE DURATION CORRECTNESS (BASE_DURATION)
    // =========================================================================
    await test('T19_SERVICE_DURATION_CORRECTNESS', async () => {
      const result90 = await nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
        service_offer_id: serviceOffer90Id,
        target_date: '2026-09-15',
        membership_id: staff1MembershipId,
      });

      assert.strictEqual(result90.service_duration_minutes, 90);
      assert.strictEqual(result90.slots[0].start_time, '09:00');
      assert.strictEqual(result90.slots[0].end_time, '10:30');
    });

    // =========================================================================
    // TEST CATEGORY 20: CONCURRENT READ BEHAVIOR (PARALLEL SELECTS)
    // =========================================================================
    await test('T20_CONCURRENT_READ_BEHAVIOR', async () => {
      const promises = [];
      for (let i = 0; i < 10; i++) {
        promises.push(
          nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
            service_offer_id: serviceOfferId,
            target_date: '2026-09-15',
          })
        );
      }

      const results = await Promise.all(promises);
      assert.strictEqual(results.length, 10);
      const baselineJson = JSON.stringify(results[0]);
      for (let i = 1; i < 10; i++) {
        assert.strictEqual(JSON.stringify(results[i]), baselineJson, 'Concurrent projection outputs must be identical');
      }
    });

    // =========================================================================
    // TEST CATEGORY 21: RLS SESSION CONTEXT LEAKAGE PREVENTION (FINDING 1)
    // =========================================================================
    await test('T21_RLS_SESSION_LEAK_PREVENTION', async () => {
      // 1. Run projection on Tenant 2
      await nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
        service_offer_id: serviceOfferId,
        target_date: '2026-09-15',
      });

      // 2. Acquire a connection from the pool and verify that app.tenant_id is NOT set to '2'
      const testClient = await pool.connect();
      try {
        const valRes = await testClient.query("SELECT current_setting('app.tenant_id', true) AS current_tenant;");
        const currentTenant = valRes.rows[0].current_tenant;
        assert.strictEqual(currentTenant === null || currentTenant === '', true,
          'Pooled connection must not leak app.tenant_id after transaction completion');
      } finally {
        testClient.release();
      }
    });

    // =========================================================================
    // TEST CATEGORY 22: AUTHORITATIVE DURATION RESOLUTION & SKIP INVALID (FINDING 4)
    // =========================================================================
    await test('T22_AUTHORITATIVE_DURATION_RESOLUTION', async () => {
      // 1. Create a 30-minute B2C service
      const b30Client = await pool.connect();
      let b2c30ServiceId;
      let bookingId;
      try {
        await b30Client.query('BEGIN');
        await b30Client.query("SELECT set_config('app.tenant_id', '2', true);");
        const sRes = await b30Client.query(`
          INSERT INTO services (provider_id, name, description, price, duration_minutes, is_active, tenant_id)
          VALUES ($1, 'Servicio Corto 30m NODO-05', 'Test', 30000, 30, true, 2)
          RETURNING id;
        `, [staff1UserId]);
        b2c30ServiceId = sRes.rows[0].id;

        // Insert booking from 10:00 to 10:30
        const bRes = await b30Client.query(`
          INSERT INTO bookings (client_id, provider_id, service_id, scheduled_at, estado, valor_bruto, tenant_id)
          VALUES (7, $1, $2, '2026-09-15 15:00:00+00', 'CONFIRMADA', 30000, 2)
          RETURNING id;
        `, [staff1UserId, b2c30ServiceId]);
        bookingId = bRes.rows[0].id;
        await b30Client.query('COMMIT');
      } finally {
        b30Client.release();
      }

      try {
        // Project availability for 45 min service.
        // With 30 min booking (10:00-10:30), slot at 10:30 (10:30-11:15) MUST BE AVAILABLE.
        // If a silent 60-min fallback were used, 10:30 would be blocked!
        const result = await nodo05AvailabilityService.projectAvailability(tenantId, establishmentId, activeContext, {
          service_offer_id: serviceOfferId, // 45 min service duration
          target_date: '2026-09-15',
          membership_id: staff1MembershipId,
        });

        const slot1000 = result.slots.find((s) => s.start_time === '10:00');
        assert.strictEqual(slot1000, undefined, 'Slot 10:00 collides with 30m booking and must be excluded');

        const slot1015 = result.slots.find((s) => s.start_time === '10:15');
        assert.strictEqual(slot1015, undefined, 'Slot 10:15 collides with 30m booking and must be excluded');

        const slot1030 = result.slots.find((s) => s.start_time === '10:30');
        assert.ok(slot1030, 'Slot 10:30 MUST be available because authoritative booking duration is 30 min (not 60 min fallback)');
      } finally {
        const delClient = await pool.connect();
        try {
          await delClient.query('BEGIN');
          await delClient.query("SELECT set_config('app.tenant_id', '2', true);");
          await delClient.query("DELETE FROM bookings WHERE id = $1;", [bookingId]);
          await delClient.query("DELETE FROM services WHERE id = $1;", [b2c30ServiceId]);
          await delClient.query('COMMIT');
        } finally {
          delClient.release();
        }
      }
    });

  } finally {
    client.release();
  }

  console.log('\n================================================================================');
  console.log(`  NODO-05 SUITE SUMMARY: ${passed} PASSED / ${failed} FAILED (TOTAL: ${passed + failed})`);
  console.log('================================================================================\n');

  if (failed > 0) {
    process.exit(1);
  }
}

if (require.main === module) {
  runNodo05Suite()
    .then(() => {
      process.exit(0);
    })
    .catch((err) => {
      console.error('Fatal Error during NODO-05 Suite Execution:', err);
      process.exit(1);
    });
}

module.exports = { runNodo05Suite };
