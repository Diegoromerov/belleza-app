// backend/tests/test_nodo01_suite.js
const assert = require('assert');
const { pool } = require('../src/config/db');
const nodo01Service = require('../src/services/nodo01Service');
const nodo01Controller = require('../src/controllers/nodo01Controller');

async function runNodo01Suite() {
  console.log('================================================================================');
  console.log('          NODO-01-v1.0 — AUTOMATED TEST & VERIFICATION SUITE');
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

    // Set tenant context for multitenant queries
    await client.query("SELECT set_config('app.tenant_id', '2', false);");

    // Canonical HBC v1.0 Fixture
    const canonicalPayload = {
      handover_contract_version: '1.0.0',
      establishment_context: {
        id: 'e4b2d3c1-7a89-4f5e-b123-456789abcdef',
        name: 'Salón Elegance Poblado',
        city: 'Medellín',
        address: 'Cra 43A # 1-50',
        location: {
          type: 'Point',
          coordinates: [-75.567, 6.208],
        },
        operating_hours: {
          monday: { open: '08:00', close: '19:00', is_closed: false },
        },
      },
      professional_context: [
        {
          user_id: 7,
          role: 'OWNER',
          status: 'ACTIVE',
          capabilities: ['HAIR_STYLING'],
        },
      ],
      service_offers: [
        {
          name: 'Corte de Cabello Estilo & Cepillado',
          category: 'HAIR_STYLING',
          duration_minutes: 45,
          price: 45000.00,
          description: 'Corte personalizado con lavado y finalización',
          is_active: true,
        },
      ],
      authorizing_identity: {
        user_id: 7,
        role: 'OWNER',
      },
      assignment: {
        status: 'NOT_ESTABLISHED',
      },
      source_state: 'READY_FOR_PRE_NODE_01',
    };

    function mockReqRes(options = {}) {
      const req = {
        headers: options.headers || {},
        user: options.user || null,
        body: options.body || {},
        activeContext: options.activeContext || null,
        tenantId: options.tenantId || null,
        establishmentId: options.establishmentId || null,
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

    console.log('[TEST GROUP 1: Canonical Ingestion & Semantic Adaptation (N01-VAL-01 to N01-VAL-05)]\n');

    // N01-VAL-01: Handover Canónico Válido
    await test('N01-VAL-01: Canonical valid HBC v1.0 payload transitions to ADAPTATION_READY', async () => {
      const result = nodo01Service.ingestHandover(canonicalPayload, { userId: 7, role: 'OWNER' });
      assert.strictEqual(result.success, true);
      assert.strictEqual(result.node_id, 'NODO-01-v1.0');
      assert.strictEqual(result.state, nodo01Service.NODE_STATES.ADAPTATION_READY);
      assert.strictEqual(result.adaptation_status, 'ADAPTATION_READY');
      assert.deepStrictEqual(result.lifecycle, [
        nodo01Service.NODE_STATES.READY_TO_RECEIVE,
        nodo01Service.NODE_STATES.RECEIVED,
        nodo01Service.NODE_STATES.VALIDATED,
        nodo01Service.NODE_STATES.ADAPTATION_READY,
      ]);
    });

    // N01-VAL-02: Verificación de Catálogo sin Provider
    await test('N01-VAL-02: service_offers without provider_id is accepted as establishment catalog', async () => {
      const result = nodo01Service.ingestHandover(canonicalPayload);
      assert.strictEqual(result.success, true);
      assert.strictEqual(result.catalog_offer_descriptors.length, 1);
      assert.strictEqual(result.catalog_offer_descriptors[0].name, 'Corte de Cabello Estilo & Cepillado');
      assert.strictEqual(result.catalog_offer_descriptors[0].price, 45000.00);
      assert.strictEqual(result.catalog_offer_descriptors[0].duration_minutes, 45);
      assert.strictEqual(result.catalog_offer_descriptors[0].category, 'HAIR_STYLING');
      assert.strictEqual('provider_id' in result.catalog_offer_descriptors[0], false);
    });

    // N01-VAL-03: Estado de Asignación no Establecido
    await test('N01-VAL-03: assignment.status = NOT_ESTABLISHED is accepted and preserves unassigned state', async () => {
      const result = nodo01Service.ingestHandover(canonicalPayload);
      assert.strictEqual(result.success, true);
      assert.strictEqual(result.audit.assignment_status, 'NOT_ESTABLISHED');
      assert.strictEqual(result.semantic_declarations.identity_vs_capability_vs_assignment, 'PRESERVED');
    });

    // N01-VAL-04: Identidad Autorizadora Válida (OWNER / MANAGER)
    await test('N01-VAL-04: Authorizing identity with OWNER / MANAGER is accepted; non-authorized rejected', async () => {
      const ownerResult = nodo01Service.ingestHandover(canonicalPayload, { userId: 7, role: 'OWNER' });
      assert.strictEqual(ownerResult.success, true);

      const managerPayload = {
        ...canonicalPayload,
        authorizing_identity: { user_id: 8, role: 'MANAGER' },
      };
      const managerResult = nodo01Service.ingestHandover(managerPayload, { userId: 8, role: 'MANAGER' });
      assert.strictEqual(managerResult.success, true);

      const invalidRolePayload = {
        ...canonicalPayload,
        authorizing_identity: { user_id: 9, role: 'PROFESSIONAL' },
      };
      const invalidRoleResult = nodo01Service.ingestHandover(invalidRolePayload, { userId: 9, role: 'PROFESSIONAL' });
      assert.strictEqual(invalidRoleResult.success, false);
      assert.strictEqual(invalidRoleResult.state, nodo01Service.NODE_STATES.REJECTED);
      assert.ok(invalidRoleResult.rejection_reasons.some(r => r.includes('INSUFFICIENT_AUTHORIZING_ROLE')));
    });

    // N01-VAL-05: Service Offer Válido
    await test('N01-VAL-05: Multi-offer service catalog is correctly adapted in memory', async () => {
      const multiOfferPayload = {
        ...canonicalPayload,
        service_offers: [
          { name: 'Corte', category: 'HAIR', duration_minutes: 30, price: 30000, description: 'Corte', is_active: true },
          { name: 'Color', category: 'COLOR', duration_minutes: 90, price: 120000, description: 'Coloración', is_active: true },
        ],
      };
      const result = nodo01Service.ingestHandover(multiOfferPayload);
      assert.strictEqual(result.success, true);
      assert.strictEqual(result.catalog_offer_descriptors.length, 2);
      assert.strictEqual(result.catalog_offer_descriptors[1].name, 'Color');
      assert.strictEqual(result.catalog_offer_descriptors[1].price, 120000);
    });

    console.log('\n[TEST GROUP 2: Boundary Protection & Rejection Invariants (N01-VAL-06 to N01-VAL-07)]\n');

    // N01-VAL-06: Intento de Inyección de provider_id
    await test('N01-VAL-06: Injection of provider_id in service_offers is strictly REJECTED (R06)', async () => {
      const injectedPayload = {
        ...canonicalPayload,
        service_offers: [
          {
            name: 'Corte Inyectado',
            category: 'HAIR',
            duration_minutes: 30,
            price: 30000,
            provider_id: 7, // FORBIDDEN!
          },
        ],
      };
      const result = nodo01Service.ingestHandover(injectedPayload);
      assert.strictEqual(result.success, false);
      assert.strictEqual(result.state, nodo01Service.NODE_STATES.REJECTED);
      assert.strictEqual(result.error_code, 'HANDOVER_BOUNDARY_REJECTED');
      assert.ok(result.rejection_reasons.some(r => r.includes('FORBIDDEN_PROVIDER_ID_INJECTION')));
    });

    // N01-VAL-07: Intento de Asignación Automática
    await test('N01-VAL-07: Attempt to force assignment.status = ASSIGNED is strictly REJECTED (R05)', async () => {
      const assignedPayload = {
        ...canonicalPayload,
        assignment: {
          status: 'ASSIGNED', // FORBIDDEN!
        },
      };
      const result = nodo01Service.ingestHandover(assignedPayload);
      assert.strictEqual(result.success, false);
      assert.strictEqual(result.state, nodo01Service.NODE_STATES.REJECTED);
      assert.ok(result.rejection_reasons.some(r => r.includes('FORBIDDEN_ASSIGNMENT_STATUS')));
    });

    console.log('\n[TEST GROUP 3: Unresolved Decisions & Pending Directives (N01-VAL-08 to N01-VAL-09)]\n');

    // N01-VAL-08: DEC-SE-001 Pendiente
    await test('N01-VAL-08: DEC-SE-001 is declared strictly as PENDING in output DTO', async () => {
      const result = nodo01Service.ingestHandover(canonicalPayload);
      assert.strictEqual(result.pending_decisions.DEC_SE_001, 'PENDING');
      assert.strictEqual(result.semantic_declarations.assignment_resolution, 'DEFERRED_TO_DIRECTOR_DEC_SE_001');
    });

    // N01-VAL-09: DEC-SE-002 Pendiente
    await test('N01-VAL-09: DEC-SE-002 is declared strictly as PENDING in output DTO', async () => {
      const result = nodo01Service.ingestHandover(canonicalPayload);
      assert.strictEqual(result.pending_decisions.DEC_SE_002, 'PENDING');
      assert.strictEqual(result.semantic_declarations.schedule_sync_resolution, 'DEFERRED_TO_DIRECTOR_DEC_SE_002');
    });

    console.log('\n[TEST GROUP 4: Database Immutability & Zero Mutation (N01-VAL-10)]\n');

    // N01-VAL-10: Cero mutación en tablas físicas de base de datos
    await test('N01-VAL-10: Database counts remain 100% identical before and after execution', async () => {
      const countsBefore = {
        usuarios: (await client.query('SELECT COUNT(*)::int as count FROM usuarios;')).rows[0].count,
        perfiles_prestador: (await client.query('SELECT COUNT(*)::int as count FROM perfiles_prestador;')).rows[0].count,
        services: (await client.query('SELECT COUNT(*)::int as count FROM services;')).rows[0].count,
        memberships: (await client.query('SELECT COUNT(*)::int as count FROM memberships;')).rows[0].count,
        establishments: (await client.query('SELECT COUNT(*)::int as count FROM establishments;')).rows[0].count,
        bookings: (await client.query('SELECT COUNT(*)::int as count FROM bookings;')).rows[0].count,
      };

      // Ingest canonical payload
      const result = nodo01Service.ingestHandover(canonicalPayload, { userId: 7, role: 'OWNER' });
      assert.strictEqual(result.success, true);

      // Ingest multiple times to verify pure memory execution
      nodo01Service.ingestHandover(canonicalPayload);
      nodo01Service.ingestHandover(canonicalPayload);

      const countsAfter = {
        usuarios: (await client.query('SELECT COUNT(*)::int as count FROM usuarios;')).rows[0].count,
        perfiles_prestador: (await client.query('SELECT COUNT(*)::int as count FROM perfiles_prestador;')).rows[0].count,
        services: (await client.query('SELECT COUNT(*)::int as count FROM services;')).rows[0].count,
        memberships: (await client.query('SELECT COUNT(*)::int as count FROM memberships;')).rows[0].count,
        establishments: (await client.query('SELECT COUNT(*)::int as count FROM establishments;')).rows[0].count,
        bookings: (await client.query('SELECT COUNT(*)::int as count FROM bookings;')).rows[0].count,
      };

      assert.deepStrictEqual(countsBefore, countsAfter, 'All database table counts must remain strictly identical!');
    });

    console.log('\n[TEST GROUP 5: Determinism, Spoofing & HTTP Controller Pipeline]\n');

    // Determinismo Semántico
    await test('Semantic Determinism: Equivalent inputs yield identical output structures', async () => {
      const res1 = nodo01Service.ingestHandover(canonicalPayload);
      const res2 = nodo01Service.ingestHandover(canonicalPayload);

      assert.deepStrictEqual(res1.target_establishment_descriptor, res2.target_establishment_descriptor);
      assert.deepStrictEqual(res1.eligible_professionals, res2.eligible_professionals);
      assert.deepStrictEqual(res1.catalog_offer_descriptors, res2.catalog_offer_descriptors);
      assert.deepStrictEqual(res1.pending_decisions, res2.pending_decisions);
      assert.strictEqual(res1.adaptation_status, res2.adaptation_status);
    });

    // Identity Spoofing Protection
    await test('Security: Identity spoofing between session token and payload is REJECTED', async () => {
      const result = nodo01Service.ingestHandover(canonicalPayload, { userId: 999, role: 'OWNER' });
      assert.strictEqual(result.success, false);
      assert.strictEqual(result.state, nodo01Service.NODE_STATES.REJECTED);
      assert.ok(result.rejection_reasons.some(r => r.includes('IDENTITY_SPOOFING_DETECTED')));
    });

    // Controller HTTP Pipeline
    await test('Controller Pipeline: nodo01Controller.ingest returns 200 OK with ADAPTATION_READY', async () => {
      const { req, res } = mockReqRes({
        user: { id: 7, email: 'owner@salon.com' },
        activeContext: { role: 'OWNER', membership_status: 'ACTIVE' },
        tenantId: 2,
        establishmentId: 'e4b2d3c1-7a89-4f5e-b123-456789abcdef',
        body: canonicalPayload,
      });

      await nodo01Controller.ingest(req, res);
      assert.strictEqual(res.getStatusCode(), 200);
      assert.strictEqual(res.getBody().status, 'success');
      assert.strictEqual(res.getBody().data.state, 'ADAPTATION_READY');
      assert.strictEqual(res.getBody().data.adaptation_status, 'ADAPTATION_READY');
    });

    // Controller Rejection Pipeline
    await test('Controller Pipeline: Malformed/injected payload returns 422 with REJECTED state', async () => {
      const { req, res } = mockReqRes({
        user: { id: 7, email: 'owner@salon.com' },
        activeContext: { role: 'OWNER', membership_status: 'ACTIVE' },
        tenantId: 2,
        establishmentId: 'e4b2d3c1-7a89-4f5e-b123-456789abcdef',
        body: {
          ...canonicalPayload,
          service_offers: [{ name: 'Corte', duration_minutes: 30, price: 30000, provider_id: 7 }],
        },
      });

      await nodo01Controller.ingest(req, res);
      assert.strictEqual(res.getStatusCode(), 422);
      assert.strictEqual(res.getBody().status, 'error');
      assert.strictEqual(res.getBody().data.state, 'REJECTED');
    });

  } finally {
    client.release();
  }

  console.log('\n================================================================================');
  console.log(`TOTAL TESTS: ${passed + failed} | PASSED: ${passed} | FAILED: ${failed}`);
  console.log('================================================================================\n');

  if (failed > 0) {
    process.exit(1);
  }
}

runNodo01Suite()
  .then(() => {
    console.log('NODO 01 test suite finished execution successfully.');
    process.exit(0);
  })
  .catch((err) => {
    console.error('Fatal error running NODO 01 suite:', err);
    process.exit(1);
  });
