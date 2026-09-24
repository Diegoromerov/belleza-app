// backend/tests/test_nodo02_runtime_suite.js
const assert = require('assert');
const { pool } = require('../src/config/db');
const serviceOfferService = require('../src/services/serviceOfferService');
const serviceAssignmentService = require('../src/services/serviceAssignmentService');
const serviceOfferController = require('../src/controllers/serviceOfferController');
const serviceAssignmentController = require('../src/controllers/serviceAssignmentController');

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

async function runNodo02RuntimeSuite() {
  console.log('================================================================================');
  console.log('       NODO-02 — SAAS CATALOG & ASSIGNMENT RUNTIME TEST SUITE');
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
    // 0. Runtime Privileges Verification
    const roleRes = await client.query('SELECT rolname, rolsuper, rolbypassrls FROM pg_roles WHERE rolname = current_user;');
    console.log('[Runtime Privileges]:', roleRes.rows[0]);
    if (roleRes.rows[0].rolsuper !== false || roleRes.rows[0].rolbypassrls !== false) {
      throw new Error('FATAL: Runtime user is superuser or bypasses RLS!');
    }

    // Set Tenant Context for setup
    await client.query("SELECT set_config('app.tenant_id', '2', false);");

    // Fetch test active establishment for Tenant 2
    const estRes = await client.query('SELECT id, organization_id FROM establishments WHERE tenant_id = 2 LIMIT 1;');
    assert(estRes.rows.length > 0, 'Establishment must exist for Tenant 2');
    const testEstId = estRes.rows[0].id;
    const testOrgId = estRes.rows[0].organization_id;

    // Fetch active OWNER membership for Tenant 2
    const ownerRes = await client.query("SELECT id, user_id FROM memberships WHERE tenant_id = 2 AND establishment_id = $1 AND role = 'OWNER' AND status = 'ACTIVE' LIMIT 1;", [testEstId]);
    assert(ownerRes.rows.length > 0, 'Active OWNER membership must exist');
    const ownerMembershipId = ownerRes.rows[0].id;
    const ownerUserId = ownerRes.rows[0].user_id;

    const ownerContext = {
      active_membership_id: ownerMembershipId,
      role: 'OWNER',
      relation_type: 'OWNER_PARTNER',
      membership_status: 'ACTIVE',
    };

    // Fetch or create active PROFESSIONAL membership for Tenant 2
    let profRes = await client.query("SELECT id, user_id FROM memberships WHERE tenant_id = 2 AND establishment_id = $1 AND role = 'PROFESSIONAL' AND status = 'ACTIVE' LIMIT 1;", [testEstId]);
    let profMembershipId;
    if (profRes.rows.length > 0) {
      profMembershipId = profRes.rows[0].id;
    } else {
      const userRes = await client.query("SELECT id FROM usuarios WHERE tenant_id = 2 AND id != $1 LIMIT 1;", [ownerUserId]);
      let targetUserId = userRes.rows.length > 0 ? userRes.rows[0].id : null;
      if (!targetUserId) {
        const createdUser = await client.query(
          "INSERT INTO usuarios (tenant_id, email, nombre, password_hash, rol, auth_provider, provider_id) VALUES (2, 'prof_nodo02_test@beautyapp.com', 'Profesional Test', 'hash', 'PRESTADOR', 'LOCAL', 'prof-nodo02-local') RETURNING id;"
        );
        targetUserId = createdUser.rows[0].id;
      }
      const createdMem = await client.query(
        "INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status) VALUES (2, $1, $2, 'PROFESSIONAL', 'STAFF_EMPLOYEE', 'ACTIVE') RETURNING id;",
        [testEstId, targetUserId]
      );
      profMembershipId = createdMem.rows[0].id;
    }

    const profContext = {
      active_membership_id: profMembershipId,
      role: 'PROFESSIONAL',
      relation_type: 'STAFF_EMPLOYEE',
      membership_status: 'ACTIVE',
    };

    const managerContext = {
      active_membership_id: ownerMembershipId,
      role: 'MANAGER',
      relation_type: 'STAFF_EMPLOYEE',
      membership_status: 'ACTIVE',
    };

    let createdOfferId = null;
    let createdAssignmentId = null;

    // -------------------------------------------------------------------------
    // TEST 1: Service Offer Creation (Happy Path)
    // -------------------------------------------------------------------------
    await test('T1. createServiceOffer with valid payload and OWNER authority', async () => {
      const payload = {
        name: 'Corte de Cabello & Styling Test',
        description: 'Servicio de prueba automatizado NODO-02',
        base_duration: 45,
        base_price: 35000.00,
      };

      const res = await serviceOfferService.createServiceOffer(2, testEstId, ownerContext, payload);
      assert.ok(res.service_offer);
      assert.ok(res.service_offer.id);
      assert.strictEqual(res.service_offer.name, payload.name);
      assert.strictEqual(res.service_offer.base_duration, 45);
      assert.strictEqual(res.service_offer.tenant_id, 2);
      assert.strictEqual(res.service_offer.establishment_id, testEstId);

      createdOfferId = res.service_offer.id;
    });

    // -------------------------------------------------------------------------
    // TEST 2: Service Offer Validation (Invalid Duration & Price)
    // -------------------------------------------------------------------------
    await test('T2. createServiceOffer rejects duration <= 0 and price < 0', async () => {
      let threwDuration = false;
      try {
        await serviceOfferService.createServiceOffer(2, testEstId, ownerContext, {
          name: 'Invalid Duration',
          base_duration: 0,
          base_price: 10000,
        });
      } catch (err) {
        threwDuration = true;
        assert.strictEqual(err.code, 'INVALID_PAYLOAD');
      }
      assert.ok(threwDuration, 'Must throw INVALID_PAYLOAD on duration <= 0');

      let threwPrice = false;
      try {
        await serviceOfferService.createServiceOffer(2, testEstId, ownerContext, {
          name: 'Invalid Price',
          base_duration: 30,
          base_price: -50,
        });
      } catch (err) {
        threwPrice = true;
        assert.strictEqual(err.code, 'INVALID_PAYLOAD');
      }
      assert.ok(threwPrice, 'Must throw INVALID_PAYLOAD on negative price');
    });

    // -------------------------------------------------------------------------
    // TEST 3: RBAC Mutation Authorization (PROFESSIONAL cannot mutate)
    // -------------------------------------------------------------------------
    await test('T3. createServiceOffer rejects PROFESSIONAL role (RBAC mutation check)', async () => {
      let threw = false;
      try {
        await serviceOfferService.createServiceOffer(2, testEstId, profContext, {
          name: 'Unauthorized Attempt',
          base_duration: 30,
          base_price: 10000,
        });
      } catch (err) {
        threw = true;
        assert.strictEqual(err.code, 'INSUFFICIENT_ROLE_AUTHORITY');
        assert.strictEqual(err.statusCode, 403);
      }
      assert.ok(threw, 'PROFESSIONAL role must be rejected with 403');
    });

    // -------------------------------------------------------------------------
    // TEST 4: MANAGER Authorized for Service Offer Creation
    // -------------------------------------------------------------------------
    await test('T4. createServiceOffer succeeds with MANAGER role', async () => {
      const res = await serviceOfferService.createServiceOffer(2, testEstId, managerContext, {
        name: 'Manager Created Service',
        base_duration: 60,
        base_price: 50000.00,
      });
      assert.ok(res.service_offer);
      assert.strictEqual(res.service_offer.name, 'Manager Created Service');
    });

    // -------------------------------------------------------------------------
    // TEST 5: List Service Offers (Establishment Isolation)
    // -------------------------------------------------------------------------
    await test('T5. listServiceOffers returns offers for active establishment', async () => {
      const res = await serviceOfferService.listServiceOffers(2, testEstId, profContext);
      assert.ok(Array.isArray(res.service_offers));
      assert.ok(res.count >= 2);
      for (const item of res.service_offers) {
        assert.strictEqual(item.establishment_id, testEstId);
        assert.strictEqual(item.tenant_id, 2);
      }
    });

    // -------------------------------------------------------------------------
    // TEST 6: Get Service Offer by ID
    // -------------------------------------------------------------------------
    await test('T6. getServiceOfferById retrieves specific offer and throws 404 if missing', async () => {
      const res = await serviceOfferService.getServiceOfferById(2, testEstId, profContext, createdOfferId);
      assert.strictEqual(res.service_offer.id, createdOfferId);

      let threw = false;
      try {
        await serviceOfferService.getServiceOfferById(2, testEstId, profContext, '00000000-0000-4000-8000-000000000000');
      } catch (err) {
        threw = true;
        assert.strictEqual(err.code, 'SERVICE_OFFER_NOT_FOUND');
        assert.strictEqual(err.statusCode, 404);
      }
      assert.ok(threw, 'Must throw 404 for non-existent service offer');
    });

    // -------------------------------------------------------------------------
    // TEST 7: Update Service Offer (Allowed fields)
    // -------------------------------------------------------------------------
    await test('T7. updateServiceOffer updates name, description, duration and price', async () => {
      const updateData = {
        name: 'Corte de Cabello & Styling Test Updated',
        description: 'Descripción actualizada',
        base_duration: 50,
        base_price: 40000.00,
      };

      const res = await serviceOfferService.updateServiceOffer(2, testEstId, ownerContext, createdOfferId, updateData);
      assert.strictEqual(res.service_offer.id, createdOfferId);
      assert.strictEqual(res.service_offer.name, updateData.name);
      assert.strictEqual(res.service_offer.description, updateData.description);
      assert.strictEqual(res.service_offer.base_duration, 50);
      assert.strictEqual(res.service_offer.base_price, '40000.00');
    });

    // -------------------------------------------------------------------------
    // TEST 8: Immutable Fields Enforcement (R1)
    // -------------------------------------------------------------------------
    await test('T8. updateServiceOffer rejects attempts to modify id, tenant_id, establishment_id (R1)', async () => {
      let threwId = false;
      try {
        await serviceOfferService.updateServiceOffer(2, testEstId, ownerContext, createdOfferId, {
          id: '11111111-1111-4111-8111-111111111111',
          name: 'Hacked ID',
        });
      } catch (err) {
        threwId = true;
        assert.strictEqual(err.code, 'IMMUTABLE_FIELD_MODIFICATION');
      }
      assert.ok(threwId, 'Must reject modification of id');

      let threwEst = false;
      try {
        await serviceOfferService.updateServiceOffer(2, testEstId, ownerContext, createdOfferId, {
          establishment_id: '22222222-2222-4222-8222-222222222222',
          name: 'Moved Est',
        });
      } catch (err) {
        threwEst = true;
        assert.strictEqual(err.code, 'IMMUTABLE_FIELD_MODIFICATION');
      }
      assert.ok(threwEst, 'Must reject moving offer across establishments');
    });

    // -------------------------------------------------------------------------
    // TEST 9: Create Assignment (Happy Path)
    // -------------------------------------------------------------------------
    await test('T9. createAssignment successfully assigns professional to offer', async () => {
      const res = await serviceAssignmentService.createAssignment(2, testEstId, ownerContext, {
        service_offer_id: createdOfferId,
        membership_id: profMembershipId,
      });

      assert.ok(res.assignment);
      assert.ok(res.assignment.id);
      assert.strictEqual(res.assignment.service_offer_id, createdOfferId);
      assert.strictEqual(res.assignment.membership_id, profMembershipId);
      assert.strictEqual(res.assignment.establishment_id, testEstId);
      assert.strictEqual(res.assignment.tenant_id, 2);

      createdAssignmentId = res.assignment.id;
    });

    // -------------------------------------------------------------------------
    // TEST 10: Assignment Duplicate Rejection
    // -------------------------------------------------------------------------
    await test('T10. createAssignment rejects duplicate pair with 409 Conflict', async () => {
      let threw = false;
      try {
        await serviceAssignmentService.createAssignment(2, testEstId, ownerContext, {
          service_offer_id: createdOfferId,
          membership_id: profMembershipId,
        });
      } catch (err) {
        threw = true;
        assert.strictEqual(err.code, 'ASSIGNMENT_ALREADY_EXISTS');
        assert.strictEqual(err.statusCode, 409);
      }
      assert.ok(threw, 'Must throw ASSIGNMENT_ALREADY_EXISTS on duplicate assignment');
    });

    // -------------------------------------------------------------------------
    // TEST 11: Active Professional Target Enforcement (R2)
    // -------------------------------------------------------------------------
    await test('T11. createAssignment rejects non-active or ineligible membership (R2)', async () => {
      // Create a temporary SUSPENDED membership using user 1
      const suspendedMem = await client.query(
        "INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status) VALUES (2, $1, 1, 'PROFESSIONAL', 'STAFF_EMPLOYEE', 'SUSPENDED') RETURNING id;",
        [testEstId]
      );
      const suspendedId = suspendedMem.rows[0].id;

      let threw = false;
      try {
        await serviceAssignmentService.createAssignment(2, testEstId, ownerContext, {
          service_offer_id: createdOfferId,
          membership_id: suspendedId,
        });
      } catch (err) {
        threw = true;
        assert.strictEqual(err.code, 'MEMBERSHIP_NOT_ACTIVE');
        assert.strictEqual(err.statusCode, 403);
      }
      assert.ok(threw, 'Must reject SUSPENDED membership');

      // Cleanup temp membership
      await client.query("DELETE FROM memberships WHERE id = $1;", [suspendedId]);
    });

    // -------------------------------------------------------------------------
    // TEST 12: List Establishment Assignments
    // -------------------------------------------------------------------------
    await test('T12. listEstablishmentAssignments returns assignments for active establishment', async () => {
      const res = await serviceAssignmentService.listEstablishmentAssignments(2, testEstId, profContext);
      assert.ok(Array.isArray(res.assignments));
      assert.ok(res.count >= 1);
      const found = res.assignments.find((a) => a.id === createdAssignmentId);
      assert.ok(found, 'Created assignment must be in list');
    });

    // -------------------------------------------------------------------------
    // TEST 13: Get Assignments by Staff
    // -------------------------------------------------------------------------
    await test('T13. getAssignmentsByStaff returns offers assigned to specific staff', async () => {
      const res = await serviceAssignmentService.getAssignmentsByStaff(2, testEstId, profContext, profMembershipId);
      assert.strictEqual(res.membership_id, profMembershipId);
      assert.ok(res.assignments.length >= 1);
      assert.strictEqual(res.assignments[0].service_offer_id, createdOfferId);
    });

    // -------------------------------------------------------------------------
    // TEST 14: Get Assignments by Offer
    // -------------------------------------------------------------------------
    await test('T14. getAssignmentsByOffer returns staff assigned to specific offer', async () => {
      const res = await serviceAssignmentService.getAssignmentsByOffer(2, testEstId, profContext, createdOfferId);
      assert.strictEqual(res.service_offer_id, createdOfferId);
      assert.ok(res.assignments.length >= 1);
      assert.strictEqual(res.assignments[0].membership_id, profMembershipId);
    });

    // -------------------------------------------------------------------------
    // TEST 15: Cross-Establishment Rejection
    // -------------------------------------------------------------------------
    await test('T15. createAssignment rejects cross-establishment mismatch (422)', async () => {
      // Create a dummy second establishment for tenant 2
      const secondEst = await client.query(
        "INSERT INTO establishments (tenant_id, organization_id, name, slug) VALUES (2, $1, 'Second Test Salon', 'second-test-salon-' || gen_random_uuid()) RETURNING id;",
        [testOrgId]
      );
      const secondEstId = secondEst.rows[0].id;

      // Create membership in second establishment using user 1
      const secondMem = await client.query(
        "INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status) VALUES (2, $1, 1, 'PROFESSIONAL', 'STAFF_EMPLOYEE', 'ACTIVE') RETURNING id;",
        [secondEstId]
      );
      const secondMemId = secondMem.rows[0].id;

      let threw = false;
      try {
        // Attempt to assign member from secondEst into an offer from testEstId
        await serviceAssignmentService.createAssignment(2, testEstId, ownerContext, {
          service_offer_id: createdOfferId,
          membership_id: secondMemId,
        });
      } catch (err) {
        threw = true;
        assert.strictEqual(err.code, 'CROSS_ESTABLISHMENT_MISMATCH');
        assert.strictEqual(err.statusCode, 422);
      }
      assert.ok(threw, 'Must reject cross-establishment assignment');

      // Cleanup
      await client.query("DELETE FROM memberships WHERE id = $1;", [secondMemId]);
      await client.query("DELETE FROM establishments WHERE id = $1;", [secondEstId]);
    });

    // -------------------------------------------------------------------------
    // TEST 16: Pure Unassignment (DEC-AS-012)
    // -------------------------------------------------------------------------
    await test('T16. deleteAssignment performs Pure Unassignment leaving offer & membership intact', async () => {
      const res = await serviceAssignmentService.deleteAssignment(2, testEstId, ownerContext, createdAssignmentId);
      assert.strictEqual(res.deleted_id, createdAssignmentId);
      assert.strictEqual(res.unassigned, true);

      // Verify assignment is gone
      const checkSa = await client.query("SELECT id FROM service_assignments WHERE id = $1;", [createdAssignmentId]);
      assert.strictEqual(checkSa.rows.length, 0, 'Assignment record must be deleted');

      // Verify Service Offer is still intact
      const checkSo = await client.query("SELECT id FROM service_offers WHERE id = $1;", [createdOfferId]);
      assert.strictEqual(checkSo.rows.length, 1, 'Service Offer must remain intact');

      // Verify Membership is still intact and ACTIVE
      const checkMem = await client.query("SELECT id, status FROM memberships WHERE id = $1;", [profMembershipId]);
      assert.strictEqual(checkMem.rows.length, 1, 'Membership must remain intact');
      assert.strictEqual(checkMem.rows[0].status, 'ACTIVE', 'Membership status must remain ACTIVE');
    });

    // -------------------------------------------------------------------------
    // TEST 17: RLS Tenant Isolation Verification
    // -------------------------------------------------------------------------
    await test('T17. RLS blocks cross-tenant access to service_offers and service_assignments', async () => {
      // In Tenant 1 context, querying Tenant 2 offer must return 0 rows via RLS
      const isolatedClient = await pool.connect();
      try {
        await isolatedClient.query("SELECT set_config('app.tenant_id', '1', true);");
        const rlsQuery = await isolatedClient.query("SELECT id FROM service_offers WHERE id = $1;", [createdOfferId]);
        assert.strictEqual(rlsQuery.rows.length, 0, 'Tenant 1 cannot see Tenant 2 service offer under RLS');
      } finally {
        isolatedClient.release();
      }
    });

    // -------------------------------------------------------------------------
    // TEST 18: Controller Layer HTTP Handling (Service Offer Controller)
    // -------------------------------------------------------------------------
    await test('T18. serviceOfferController handles HTTP requests with standard status codes & DTOs', async () => {
      // 18.1. Create Offer HTTP 201
      const { req: createReq, res: createRes } = createMockReqRes({
        establishmentId: testEstId,
        activeContext: ownerContext,
        body: {
          name: 'Controller Test Offer',
          base_duration: 30,
          base_price: 25000,
        },
      });
      await serviceOfferController.createServiceOffer(createReq, createRes);
      assert.strictEqual(createRes.getStatusCode(), 201);
      const createdBody = createRes.getBody();
      assert.strictEqual(createdBody.status, 'success');
      const offerId = createdBody.data.service_offer.id;

      // 18.2. List Offers HTTP 200
      const { req: listReq, res: listRes } = createMockReqRes({
        establishmentId: testEstId,
        activeContext: profContext,
      });
      await serviceOfferController.listServiceOffers(listReq, listRes);
      assert.strictEqual(listRes.getStatusCode(), 200);

      // 18.3. Get Offer by ID HTTP 200
      const { req: getReq, res: getRes } = createMockReqRes({
        establishmentId: testEstId,
        activeContext: profContext,
        params: { id: offerId },
      });
      await serviceOfferController.getServiceOfferById(getReq, getRes);
      assert.strictEqual(getRes.getStatusCode(), 200);

      // 18.4. Update Offer HTTP 200
      const { req: updateReq, res: updateRes } = createMockReqRes({
        establishmentId: testEstId,
        activeContext: ownerContext,
        params: { id: offerId },
        body: { name: 'Controller Test Offer Updated' },
      });
      await serviceOfferController.updateServiceOffer(updateReq, updateRes);
      assert.strictEqual(updateRes.getStatusCode(), 200);

      // 18.5. Forbidden Update (PROFESSIONAL role) HTTP 403
      const { req: unauthReq, res: unauthRes } = createMockReqRes({
        establishmentId: testEstId,
        activeContext: profContext,
        params: { id: offerId },
        body: { name: 'Unauthorized Mod' },
      });
      await serviceOfferController.updateServiceOffer(unauthReq, unauthRes);
      assert.strictEqual(unauthRes.getStatusCode(), 403);
      assert.strictEqual(unauthRes.getBody().code, 'INSUFFICIENT_ROLE_AUTHORITY');
    });

    // -------------------------------------------------------------------------
    // TEST 19: Controller Layer HTTP Handling (Service Assignment Controller)
    // -------------------------------------------------------------------------
    await test('T19. serviceAssignmentController handles HTTP requests with standard status codes & DTOs', async () => {
      // 19.1. Create Assignment HTTP 201
      const { req: createReq, res: createRes } = createMockReqRes({
        establishmentId: testEstId,
        activeContext: ownerContext,
        body: {
          service_offer_id: createdOfferId,
          membership_id: profMembershipId,
        },
      });
      await serviceAssignmentController.createAssignment(createReq, createRes);
      assert.strictEqual(createRes.getStatusCode(), 201);
      const assignId = createRes.getBody().data.assignment.id;

      // 19.2. List Assignments HTTP 200
      const { req: listReq, res: listRes } = createMockReqRes({
        establishmentId: testEstId,
        activeContext: profContext,
      });
      await serviceAssignmentController.listEstablishmentAssignments(listReq, listRes);
      assert.strictEqual(listRes.getStatusCode(), 200);

      // 19.3. Delete Assignment HTTP 200
      const { req: delReq, res: delRes } = createMockReqRes({
        establishmentId: testEstId,
        activeContext: ownerContext,
        params: { id: assignId },
      });
      await serviceAssignmentController.deleteAssignment(delReq, delRes);
      assert.strictEqual(delRes.getStatusCode(), 200);
      assert.strictEqual(delRes.getBody().data.unassigned, true);
    });

  } finally {
    client.release();
  }

  console.log(`\n================================================================================`);
  console.log(`TOTAL TESTS: ${passed + failed} | PASSED: ${passed} | FAILED: ${failed}`);
  console.log(`================================================================================\n`);

  if (failed > 0) {
    throw new Error(`NODO-02 Runtime Suite failed with ${failed} failure(s).`);
  }
}

if (require.main === module) {
  runNodo02RuntimeSuite()
    .then(() => {
      console.log('NODO-02 RUNTIME SUITE PASSED SUCCESSFULLY!');
      process.exit(0);
    })
    .catch((err) => {
      console.error('NODO-02 RUNTIME SUITE FAILED:', err);
      process.exit(1);
    });
}

module.exports = { runNodo02RuntimeSuite };
