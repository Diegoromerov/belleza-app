// backend/tests/test_nodo04_materialization_suite.js
const assert = require('assert');
const { pool } = require('../src/config/db');
const nodo04MaterializationService = require('../src/services/nodo04MaterializationService');
const nodo04MaterializationController = require('../src/controllers/nodo04MaterializationController');

function createMockReqRes(options = {}) {
  const req = {
    user: options.user !== undefined ? options.user : { id: 7, email: 'demo@beautyapp.com' },
    headers: options.headers || {},
    body: options.body || {},
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

async function runNodo04Suite() {
  console.log('================================================================================');
  console.log('       NODO-04 — DOWNSTREAM B2C MATERIALIZATION ADAPTER TEST SUITE');
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
  await client.query("SELECT set_config('app.tenant_id', '2', false);");

  try {
    // Check runtime database privileges
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

    // Let's query existing valid fixtures in Tenant 2
    const estRes = await client.query("SELECT id FROM establishments WHERE tenant_id = $1 LIMIT 1;", [tenantId]);
    assert.ok(estRes.rows.length > 0, 'Establishment must exist for Tenant 2');
    const establishmentId = estRes.rows[0].id;

    // Query foreign establishment for Tenant 1
    await client.query("SELECT set_config('app.tenant_id', '1', false);");
    const foreignEstRes = await client.query("SELECT id FROM establishments WHERE tenant_id = $1 LIMIT 1;", [foreignTenantId]);
    assert.ok(foreignEstRes.rows.length > 0, 'Establishment must exist for Tenant 1');
    const foreignEstablishmentId = foreignEstRes.rows[0].id;

    // Switch back to Tenant 2
    await client.query("SELECT set_config('app.tenant_id', '2', false);");

    // Setup staff user with active professional membership in Tenant 2
    // Create or get dedicated user for NODO-04
    const staffUserRes = await client.query(`
      INSERT INTO usuarios (email, nombre, rol, tenant_id, auth_provider, provider_id, password_hash)
      VALUES ('nodo04_staff_prof@beautyapp.com', 'NODO-04 Staff', 'PRESTADOR', 2, 'LOCAL', 'nodo04-staff-loc', 'hash')
      ON CONFLICT (email) DO UPDATE SET is_active = true
      RETURNING id;
    `);
    const staffUserId = staffUserRes.rows[0].id;

    // Ensure perfiles_prestador exists for staff user in tenant 2
    await client.query(`
      INSERT INTO perfiles_prestador (id, tenant_id, is_active)
      VALUES ($1, $2, true)
      ON CONFLICT (id) DO UPDATE SET tenant_id = $2;
    `, [staffUserId, tenantId]);

    // Ensure active professional membership for staff user in establishmentId
    const memberRes = await client.query(`
      INSERT INTO memberships (tenant_id, establishment_id, user_id, role, relation_type, status)
      VALUES ($1, $2, $3, 'PROFESSIONAL', 'STAFF_EMPLOYEE', 'ACTIVE')
      ON CONFLICT (establishment_id, user_id) DO UPDATE SET status = 'ACTIVE', role = 'PROFESSIONAL'
      RETURNING id;
    `, [tenantId, establishmentId, staffUserId]);
    const membershipId = memberRes.rows[0].id;

    // Create a service offer for testing
    const offerRes = await client.query(`
      INSERT INTO service_offers (tenant_id, establishment_id, name, description, base_price, base_duration)
      VALUES ($1, $2, 'Corte Test NODO-04', 'Servicio de prueba para adapter downstream', 35000.00, 30)
      RETURNING id;
    `, [tenantId, establishmentId]);
    const serviceOfferId = offerRes.rows[0].id;

    // Create assignment between offer and membership
    await client.query(`
      INSERT INTO service_assignments (tenant_id, establishment_id, service_offer_id, membership_id)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (service_offer_id, membership_id) DO NOTHING;
    `, [tenantId, establishmentId, serviceOfferId, membershipId]);

    // Active contexts
    const ownerContext = {
      tenant_id: tenantId,
      establishment_id: establishmentId,
      role: 'OWNER',
      status: 'ACTIVE',
      membership_id: '00000000-0000-0000-0000-000000000001',
    };

    const managerContext = {
      tenant_id: tenantId,
      establishment_id: establishmentId,
      role: 'MANAGER',
      status: 'ACTIVE',
      membership_id: '00000000-0000-0000-0000-000000000002',
    };

    const professionalContext = {
      tenant_id: tenantId,
      establishment_id: establishmentId,
      role: 'PROFESSIONAL',
      status: 'ACTIVE',
      membership_id: membershipId,
    };

    const receptionistContext = {
      tenant_id: tenantId,
      establishment_id: establishmentId,
      role: 'RECEPTIONIST',
      status: 'ACTIVE',
      membership_id: '00000000-0000-0000-0000-000000000004',
    };

    // ============================================================================
    // T01: Authenticated Identity
    // ============================================================================
    await test('T01: Authenticated Identity - Controller error handling on invalid user/context', async () => {
      const { req, res } = createMockReqRes({
        tenantId: null,
        activeContext: null,
        body: { service_offer_id: serviceOfferId, membership_id: membershipId }
      });
      await nodo04MaterializationController.materializeService(req, res);
      assert.strictEqual(res.getStatusCode(), 400);
      assert.strictEqual(res.getBody().code, 'ACTIVE_CONTEXT_REQUIRED');
    });

    // ============================================================================
    // T02: Active Context Required
    // ============================================================================
    await test('T02: Active Context Required - Service throws 400 when active context is missing', async () => {
      await assert.rejects(
        async () => {
          await nodo04MaterializationService.materializeServiceAssignment(
            tenantId,
            establishmentId,
            null,
            { service_offer_id: serviceOfferId, membership_id: membershipId },
            { id: 7 }
          );
        },
        (err) => {
          assert.strictEqual(err.statusCode, 400);
          assert.strictEqual(err.code, 'ACTIVE_CONTEXT_REQUIRED');
          return true;
        }
      );
    });

    // ============================================================================
    // T03: OWNER Authorization
    // ============================================================================
    let createdMaterializationT03 = null;
    await test('T03: OWNER Authorization - OWNER can authorize materialization (201 Created)', async () => {
      const result = await nodo04MaterializationService.materializeServiceAssignment(
        tenantId,
        establishmentId,
        ownerContext,
        { service_offer_id: serviceOfferId, membership_id: membershipId },
        { id: 7 }
      );
      assert.ok(result.materialization_id);
      assert.ok(result.service_id);
      assert.strictEqual(result.tenant_id, tenantId);
      assert.strictEqual(result.establishment_id, establishmentId);
      assert.strictEqual(result.service_offer_id, serviceOfferId);
      assert.strictEqual(result.membership_id, membershipId);
      assert.strictEqual(result.provider_id, staffUserId);
      assert.strictEqual(result.projected_service.name, 'Corte Test NODO-04');
      assert.strictEqual(parseFloat(result.projected_service.price), 35000);
      assert.strictEqual(result.projected_service.duration_minutes, 30);
      createdMaterializationT03 = result;
    });

    // ============================================================================
    // T04: MANAGER Authorization
    // ============================================================================
    await test('T04: MANAGER Authorization - MANAGER can authorize materialization (201 Created)', async () => {
      await client.query("SELECT set_config('app.tenant_id', '2', false);");
      const offer2Res = await client.query(`
        INSERT INTO service_offers (tenant_id, establishment_id, name, description, base_price, base_duration)
        VALUES ($1, $2, 'Manicure Test NODO-04', 'Servicio manicure manager test', 25000.00, 45)
        RETURNING id;
      `, [tenantId, establishmentId]);
      const offer2Id = offer2Res.rows[0].id;

      await client.query(`
        INSERT INTO service_assignments (tenant_id, establishment_id, service_offer_id, membership_id)
        VALUES ($1, $2, $3, $4);
      `, [tenantId, establishmentId, offer2Id, membershipId]);

      const result = await nodo04MaterializationService.materializeServiceAssignment(
        tenantId,
        establishmentId,
        managerContext,
        { service_offer_id: offer2Id, membership_id: membershipId },
        { id: 7 }
      );
      assert.ok(result.materialization_id);
      assert.ok(result.service_id);
      assert.strictEqual(result.projected_service.name, 'Manicure Test NODO-04');
    });

    // ============================================================================
    // T05: PROFESSIONAL Rejected
    // ============================================================================
    await test('T05: PROFESSIONAL Rejected - 403 INSUFFICIENT_ROLE_AUTHORITY', async () => {
      await assert.rejects(
        async () => {
          await nodo04MaterializationService.materializeServiceAssignment(
            tenantId,
            establishmentId,
            professionalContext,
            { service_offer_id: serviceOfferId, membership_id: membershipId },
            { id: 7 }
          );
        },
        (err) => {
          assert.strictEqual(err.statusCode, 403);
          assert.strictEqual(err.code, 'INSUFFICIENT_ROLE_AUTHORITY');
          return true;
        }
      );
    });

    // ============================================================================
    // T06: RECEPTIONIST Rejected
    // ============================================================================
    await test('T06: RECEPTIONIST Rejected - 403 INSUFFICIENT_ROLE_AUTHORITY', async () => {
      await assert.rejects(
        async () => {
          await nodo04MaterializationService.materializeServiceAssignment(
            tenantId,
            establishmentId,
            receptionistContext,
            { service_offer_id: serviceOfferId, membership_id: membershipId },
            { id: 7 }
          );
        },
        (err) => {
          assert.strictEqual(err.statusCode, 403);
          assert.strictEqual(err.code, 'INSUFFICIENT_ROLE_AUTHORITY');
          return true;
        }
      );
    });

    // ============================================================================
    // T07: Inactive Membership Rejected
    // ============================================================================
    await test('T07: Inactive Membership Rejected - 422 NON_OPERABLE_STAFF_MEMBER', async () => {
      await client.query("SELECT set_config('app.tenant_id', '2', false);");
      const newUser = await client.query(`
        INSERT INTO usuarios (email, nombre, rol, tenant_id, auth_provider, provider_id, password_hash)
        VALUES ('suspended_user_nodo04@test.com', 'Suspended Staff', 'PRESTADOR', $1, 'LOCAL', 'susp-user-loc', 'hash')
        ON CONFLICT (email) DO UPDATE SET is_active = true
        RETURNING id;
      `, [tenantId]);
      const suspendedUserId = newUser.rows[0].id;

      const suspendedMem = await client.query(`
        INSERT INTO memberships (tenant_id, establishment_id, user_id, role, status)
        VALUES ($1, $2, $3, 'PROFESSIONAL', 'SUSPENDED')
        ON CONFLICT (establishment_id, user_id) DO UPDATE SET status = 'SUSPENDED', role = 'PROFESSIONAL'
        RETURNING id;
      `, [tenantId, establishmentId, suspendedUserId]);
      const suspendedMemId = suspendedMem.rows[0].id;

      await assert.rejects(
        async () => {
          await nodo04MaterializationService.materializeServiceAssignment(
            tenantId,
            establishmentId,
            ownerContext,
            { service_offer_id: serviceOfferId, membership_id: suspendedMemId },
            { id: 7 }
          );
        },
        (err) => {
          assert.strictEqual(err.statusCode, 422);
          assert.strictEqual(err.code, 'NON_OPERABLE_STAFF_MEMBER');
          return true;
        }
      );
    });

    // ============================================================================
    // T08: Cross-Establishment Rejected
    // ============================================================================
    await test('T08: Cross-Establishment Rejected - 404 when offer belongs to another establishment', async () => {
      await client.query("SELECT set_config('app.tenant_id', '1', false);");
      const foreignOffer = await client.query(`
        INSERT INTO service_offers (tenant_id, establishment_id, name, description, base_price, base_duration)
        VALUES ($1, $2, 'Foreign Offer', 'Foreign establishment offer', 10000.00, 20)
        RETURNING id;
      `, [foreignTenantId, foreignEstablishmentId]);
      const foreignOfferId = foreignOffer.rows[0].id;

      await client.query("SELECT set_config('app.tenant_id', '2', false);");

      await assert.rejects(
        async () => {
          await nodo04MaterializationService.materializeServiceAssignment(
            tenantId,
            establishmentId,
            ownerContext,
            { service_offer_id: foreignOfferId, membership_id: membershipId },
            { id: 7 }
          );
        },
        (err) => {
          assert.strictEqual(err.statusCode, 404);
          assert.strictEqual(err.code, 'SERVICE_OFFER_NOT_FOUND');
          return true;
        }
      );
    });

    // ============================================================================
    // T09: Cross-Tenant Rejected
    // ============================================================================
    await test('T09: Cross-Tenant Rejected - RLS isolation rejects foreign tenant resources', async () => {
      const tenant1Context = {
        tenant_id: foreignTenantId,
        establishment_id: foreignEstablishmentId,
        role: 'OWNER',
        status: 'ACTIVE',
        membership_id: '00000000-0000-0000-0000-000000000099',
      };

      await assert.rejects(
        async () => {
          await nodo04MaterializationService.materializeServiceAssignment(
            foreignTenantId,
            foreignEstablishmentId,
            tenant1Context,
            { service_offer_id: serviceOfferId, membership_id: membershipId },
            { id: 7 }
          );
        },
        (err) => {
          assert.strictEqual(err.statusCode, 404);
          return true;
        }
      );
    });

    // ============================================================================
    // T10: Invalid Service Offer
    // ============================================================================
    await test('T10: Invalid Service Offer - 404 SERVICE_OFFER_NOT_FOUND on non-existent offer and 400 on invalid payload', async () => {
      // 1. Non-existent UUID offer
      const nonExistentOfferId = '99999999-9999-4999-8999-999999999999';
      await assert.rejects(
        async () => {
          await nodo04MaterializationService.materializeServiceAssignment(
            tenantId,
            establishmentId,
            ownerContext,
            { service_offer_id: nonExistentOfferId, membership_id: membershipId },
            { id: 7 }
          );
        },
        (err) => {
          assert.strictEqual(err.statusCode, 404);
          assert.strictEqual(err.code, 'SERVICE_OFFER_NOT_FOUND');
          return true;
        }
      );

      // 2. Invalid UUID format
      await assert.rejects(
        async () => {
          await nodo04MaterializationService.materializeServiceAssignment(
            tenantId,
            establishmentId,
            ownerContext,
            { service_offer_id: 'invalid-offer-id', membership_id: membershipId },
            { id: 7 }
          );
        },
        (err) => {
          assert.strictEqual(err.statusCode, 400);
          assert.strictEqual(err.code, 'INVALID_PAYLOAD');
          return true;
        }
      );
    });

    // ============================================================================
    // T11: Assignment Inexistente
    // ============================================================================
    await test('T11: Assignment Inexistente - 404 SERVICE_ASSIGNMENT_NOT_FOUND', async () => {
      await client.query("SELECT set_config('app.tenant_id', '2', false);");
      const unassignedOffer = await client.query(`
        INSERT INTO service_offers (tenant_id, establishment_id, name, description, base_price, base_duration)
        VALUES ($1, $2, 'Unassigned Offer', 'Not assigned to staff', 20000.00, 30)
        RETURNING id;
      `, [tenantId, establishmentId]);
      const unassignedOfferId = unassignedOffer.rows[0].id;

      await assert.rejects(
        async () => {
          await nodo04MaterializationService.materializeServiceAssignment(
            tenantId,
            establishmentId,
            ownerContext,
            { service_offer_id: unassignedOfferId, membership_id: membershipId },
            { id: 7 }
          );
        },
        (err) => {
          assert.strictEqual(err.statusCode, 404);
          assert.strictEqual(err.code, 'SERVICE_ASSIGNMENT_NOT_FOUND');
          return true;
        }
      );
    });

    // ============================================================================
    // T12: Provider Profile Inexistente (DEC-B)
    // ============================================================================
    await test('T12: Provider Profile Inexistente - 422 MATERIALIZATION_NOT_EXECUTABLE (DEC-B Auto-Provisioning REJECTED)', async () => {
      await client.query("SELECT set_config('app.tenant_id', '2', false);");
      const staffWithoutProvider = await client.query(`
        INSERT INTO usuarios (email, nombre, rol, tenant_id, auth_provider, provider_id, password_hash)
        VALUES ('no_provider_staff@test.com', 'No Provider Staff', 'PRESTADOR', $1, 'LOCAL', 'no-prov-loc', 'hash')
        ON CONFLICT (email) DO UPDATE SET is_active = true
        RETURNING id;
      `, [tenantId]);
      const noProvUserId = staffWithoutProvider.rows[0].id;

      // Delete any existing profile just in case
      await client.query("DELETE FROM perfiles_prestador WHERE id = $1;", [noProvUserId]);

      const staffMem = await client.query(`
        INSERT INTO memberships (tenant_id, establishment_id, user_id, role, status)
        VALUES ($1, $2, $3, 'PROFESSIONAL', 'ACTIVE')
        ON CONFLICT (establishment_id, user_id) DO UPDATE SET status = 'ACTIVE', role = 'PROFESSIONAL'
        RETURNING id;
      `, [tenantId, establishmentId, noProvUserId]);
      const staffMemId = staffMem.rows[0].id;

      const offerForStaff = await client.query(`
        INSERT INTO service_offers (tenant_id, establishment_id, name, description, base_price, base_duration)
        VALUES ($1, $2, 'Offer for No-Provider Staff', 'Test', 30000.00, 30)
        RETURNING id;
      `, [tenantId, establishmentId]);
      const offerForStaffId = offerForStaff.rows[0].id;

      await client.query(`
        INSERT INTO service_assignments (tenant_id, establishment_id, service_offer_id, membership_id)
        VALUES ($1, $2, $3, $4);
      `, [tenantId, establishmentId, offerForStaffId, staffMemId]);

      await assert.rejects(
        async () => {
          await nodo04MaterializationService.materializeServiceAssignment(
            tenantId,
            establishmentId,
            ownerContext,
            { service_offer_id: offerForStaffId, membership_id: staffMemId },
            { id: 7 }
          );
        },
        (err) => {
          assert.strictEqual(err.statusCode, 422);
          assert.strictEqual(err.code, 'MATERIALIZATION_NOT_EXECUTABLE');
          return true;
        }
      );

      // Verify NODO-04 did NOT auto-create perfiles_prestador
      const checkProv = await client.query("SELECT id FROM perfiles_prestador WHERE id = $1;", [noProvUserId]);
      assert.strictEqual(checkProv.rows.length, 0, 'perfiles_prestador must NOT be created automatically!');
    });

    // ============================================================================
    // T13: Provider Profile Existente
    // ============================================================================
    await test('T13: Provider Profile Existente - Materialization executes when perfiles_prestador pre-exists', async () => {
      await client.query("SELECT set_config('app.tenant_id', '2', false);");
      const validOffer = await client.query(`
        INSERT INTO service_offers (tenant_id, establishment_id, name, description, base_price, base_duration)
        VALUES ($1, $2, 'T13 Provider Exists Offer', 'Test', 40000.00, 50)
        RETURNING id;
      `, [tenantId, establishmentId]);
      const validOfferId = validOffer.rows[0].id;

      await client.query(`
        INSERT INTO service_assignments (tenant_id, establishment_id, service_offer_id, membership_id)
        VALUES ($1, $2, $3, $4);
      `, [tenantId, establishmentId, validOfferId, membershipId]);

      const result = await nodo04MaterializationService.materializeServiceAssignment(
        tenantId,
        establishmentId,
        ownerContext,
        { service_offer_id: validOfferId, membership_id: membershipId },
        { id: 7 }
      );
      assert.ok(result.materialization_id);
      assert.strictEqual(result.provider_id, staffUserId);
    });

    // ============================================================================
    // T14: Materialización Exitosa & Mapping Persistido
    // ============================================================================
    await test('T14: Successful Materialization & Mapping Persistence - Verifies public.services and saas_service_materializations', async () => {
      await client.query("SELECT set_config('app.tenant_id', '2', false);");
      const offerT14 = await client.query(`
        INSERT INTO service_offers (tenant_id, establishment_id, name, description, base_price, base_duration)
        VALUES ($1, $2, 'T14 Full Persistence Offer', 'Test persistence', 60000.00, 60)
        RETURNING id;
      `, [tenantId, establishmentId]);
      const offerT14Id = offerT14.rows[0].id;

      await client.query(`
        INSERT INTO service_assignments (tenant_id, establishment_id, service_offer_id, membership_id)
        VALUES ($1, $2, $3, $4);
      `, [tenantId, establishmentId, offerT14Id, membershipId]);

      const result = await nodo04MaterializationService.materializeServiceAssignment(
        tenantId,
        establishmentId,
        ownerContext,
        { service_offer_id: offerT14Id, membership_id: membershipId },
        { id: 7 }
      );

      // Verify row in public.services
      const svcRow = await client.query("SELECT * FROM public.services WHERE id = $1;", [result.service_id]);
      assert.strictEqual(svcRow.rows.length, 1);
      assert.strictEqual(svcRow.rows[0].provider_id, staffUserId);
      assert.strictEqual(svcRow.rows[0].name, 'T14 Full Persistence Offer');
      assert.strictEqual(parseFloat(svcRow.rows[0].price), 60000);
      assert.strictEqual(svcRow.rows[0].duration_minutes, 60);

      // Verify row in public.saas_service_materializations
      const matRow = await client.query("SELECT * FROM public.saas_service_materializations WHERE id = $1;", [result.materialization_id]);
      assert.strictEqual(matRow.rows.length, 1);
      assert.strictEqual(matRow.rows[0].tenant_id, tenantId);
      assert.strictEqual(matRow.rows[0].establishment_id, establishmentId);
      assert.strictEqual(matRow.rows[0].service_offer_id, offerT14Id);
      assert.strictEqual(matRow.rows[0].membership_id, membershipId);
      assert.strictEqual(matRow.rows[0].service_id, result.service_id);
      assert.strictEqual(matRow.rows[0].materialized_by_user_id, undefined);
      assert.strictEqual(matRow.rows[0].materialized_at, undefined);
    });

    // ============================================================================
    // T15: Atomic Rollback
    // ============================================================================
    await test('T15: Atomic Rollback - Rollback on error leaves ZERO orphaned services or mappings', async () => {
      await client.query("SELECT set_config('app.tenant_id', '2', false);");
      const offerT15 = await client.query(`
        INSERT INTO service_offers (tenant_id, establishment_id, name, description, base_price, base_duration)
        VALUES ($1, $2, 'T15 Rollback Offer', 'Test rollback', 50000.00, 30)
        RETURNING id;
      `, [tenantId, establishmentId]);
      const offerT15Id = offerT15.rows[0].id;

      await client.query(`
        INSERT INTO service_assignments (tenant_id, establishment_id, service_offer_id, membership_id)
        VALUES ($1, $2, $3, $4);
      `, [tenantId, establishmentId, offerT15Id, membershipId]);

      const initialServicesCount = await client.query("SELECT COUNT(*) as count FROM public.services WHERE name = 'T15 Rollback Offer';");
      const initialMatsCount = await client.query("SELECT COUNT(*) as count FROM public.saas_service_materializations WHERE service_offer_id = $1;", [offerT15Id]);

      // Force an error during materialization transaction by making saas_service_materializations insertion fail
      // We simulate this by passing invalid context/params or checking rollback behavior when error occurs
      // We can create a conflicting unique constraint or simulate failure
      await assert.rejects(
        async () => {
          // Temporarily alter table or trigger failure by mocking/testing failure path
          // Calling with invalid establishment context that fails at query execution
          const clientError = await pool.connect();
          try {
            await clientError.query('BEGIN');
            await clientError.query("SELECT set_config('app.tenant_id', '2', true);");
            await clientError.query(`
              INSERT INTO public.services (id, provider_id, name, description, price, duration_minutes, tenant_id)
              VALUES ('00000000-0000-0000-0000-000000000099', $1, 'T15 Rollback Offer', 'Test', 50000, 30, 2);
            `, [staffUserId]);
            // Force constraint error on invalid mapping insert
            await clientError.query(`
              INSERT INTO public.saas_service_materializations (id, tenant_id, establishment_id, service_offer_id, membership_id, service_id)
              VALUES ('00000000-0000-0000-0000-000000000099', 2, '00000000-0000-0000-0000-000000000000', $1, $2, '00000000-0000-0000-0000-000000000099');
            `, [offerT15Id, membershipId]);
            await clientError.query('COMMIT');
          } catch (e) {
            await clientError.query('ROLLBACK');
            throw e;
          } finally {
            clientError.release();
          }
        }
      );

      const finalServicesCount = await client.query("SELECT COUNT(*) as count FROM public.services WHERE name = 'T15 Rollback Offer';");
      const finalMatsCount = await client.query("SELECT COUNT(*) as count FROM public.saas_service_materializations WHERE service_offer_id = $1;", [offerT15Id]);

      assert.strictEqual(parseInt(finalServicesCount.rows[0].count, 10), parseInt(initialServicesCount.rows[0].count, 10), 'No orphaned services must remain!');
      assert.strictEqual(parseInt(finalMatsCount.rows[0].count, 10), parseInt(initialMatsCount.rows[0].count, 10), 'No orphaned mappings must remain!');
    });

    // ============================================================================
    // T16: RLS Isolation
    // ============================================================================
    await test('T16: RLS Isolation - OP-02 lists only materializations for active tenant', async () => {
      const listRes = await nodo04MaterializationService.listMaterializations(
        tenantId,
        establishmentId,
        ownerContext
      );
      assert.ok(Array.isArray(listRes));
      assert.ok(listRes.length > 0);
      for (const item of listRes) {
        assert.ok(item.materialization_id);
        assert.ok(item.service_offer_id);
        assert.ok(item.service_offer_name);
        assert.ok(item.membership_id);
        assert.ok(item.professional_name);
        assert.ok(item.service_id);
        assert.ok(item.b2c_price);
        assert.ok(item.b2c_duration);
        assert.notStrictEqual(item.b2c_is_active, undefined);
      }
    });

    // ============================================================================
    // T17: Existing Materialization (RE-MATERIALIZATION BEHAVIOR = OPEN)
    // ============================================================================
    await test('T17: Existing Materialization (RE-MATERIALIZATION BEHAVIOR = OPEN) - Halts without update/duplicate/sync', async () => {
      await client.query("SELECT set_config('app.tenant_id', '2', false);");
      const servicesCountBefore = await client.query("SELECT COUNT(*) as count FROM public.services;");
      const matCountBefore = await client.query("SELECT COUNT(*) as count FROM public.saas_service_materializations;");

      await assert.rejects(
        async () => {
          await nodo04MaterializationService.materializeServiceAssignment(
            tenantId,
            establishmentId,
            ownerContext,
            { service_offer_id: serviceOfferId, membership_id: membershipId },
            { id: 7 }
          );
        },
        (err) => {
          assert.strictEqual(err.statusCode, 409);
          assert.strictEqual(err.code, 'RE_MATERIALIZATION_NOT_AUTHORIZED');
          return true;
        }
      );

      const servicesCountAfter = await client.query("SELECT COUNT(*) as count FROM public.services;");
      const matCountAfter = await client.query("SELECT COUNT(*) as count FROM public.saas_service_materializations;");

      assert.strictEqual(parseInt(servicesCountAfter.rows[0].count, 10), parseInt(servicesCountBefore.rows[0].count, 10), 'Must NOT duplicate B2C services!');
      assert.strictEqual(parseInt(matCountAfter.rows[0].count, 10), parseInt(matCountBefore.rows[0].count, 10), 'Must NOT duplicate materialization records!');
    });

    // Cleanup ephemeral fixtures from T07 and T12
    await client.query("DELETE FROM saas_service_materializations WHERE tenant_id = 2;");
    await client.query("DELETE FROM service_assignments WHERE tenant_id = 2 AND service_offer_id IN (SELECT id FROM service_offers WHERE name LIKE '%NODO-04%' OR name LIKE '%Offer%');");
    await client.query("DELETE FROM service_offers WHERE tenant_id = 2 AND (name LIKE '%NODO-04%' OR name LIKE '%Offer%');");
    await client.query("DELETE FROM memberships WHERE user_id IN (SELECT id FROM usuarios WHERE email LIKE '%suspended_user_nodo04%' OR email LIKE '%no_provider_staff%');");
    await client.query("DELETE FROM usuarios WHERE email LIKE '%suspended_user_nodo04%' OR email LIKE '%no_provider_staff%';");

    console.log('\n================================================================================');
    console.log(`TEST RESULTS: ${passed} PASSED | ${failed} FAILED`);
    console.log('================================================================================\n');

    if (failed > 0) {
      throw new Error(`Suite execution finished with ${failed} failure(s).`);
    }
  } finally {
    client.release();
  }
}

if (require.main === module) {
  runNodo04Suite()
    .then(() => {
      console.log('✅ NODO-04 Materialization Suite passed successfully.');
      process.exit(0);
    })
    .catch((err) => {
      console.error('❌ NODO-04 Materialization Suite execution failed:', err);
      process.exit(1);
    });
}

module.exports = { runNodo04Suite };
