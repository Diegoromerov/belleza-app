// backend/tests/test_service_offers_and_assignments_physical_suite.js
const assert = require('assert');
const { pool } = require('../src/config/db');

async function runPhysicalVerificationSuite() {
  console.log('================================================================================');
  console.log('    SERVICE OFFERS & SERVICE ASSIGNMENTS — PHYSICAL VERIFICATION SUITE');
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
    // -------------------------------------------------------------------------
    // TEST 1: Verificar existencia y schema de service_offers
    // -------------------------------------------------------------------------
    await test('T1. service_offers schema, columns, defaults & non-nullability', async () => {
      const res = await client.query(`
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns
        WHERE table_name = 'service_offers'
        ORDER BY ordinal_position;
      `);
      const cols = res.rows.reduce((acc, r) => { acc[r.column_name] = r; return acc; }, {});
      assert(cols.id, 'Column id must exist');
      assert.strictEqual(cols.id.data_type, 'uuid');
      assert.strictEqual(cols.id.is_nullable, 'NO');

      assert(cols.tenant_id, 'Column tenant_id must exist');
      assert.strictEqual(cols.tenant_id.data_type, 'integer');
      assert.strictEqual(cols.tenant_id.is_nullable, 'NO');

      assert(cols.establishment_id, 'Column establishment_id must exist');
      assert.strictEqual(cols.establishment_id.data_type, 'uuid');
      assert.strictEqual(cols.establishment_id.is_nullable, 'NO');

      assert(cols.name, 'Column name must exist');
      assert.strictEqual(cols.name.data_type, 'character varying');

      assert(cols.description, 'Column description must exist');
      assert.strictEqual(cols.description.data_type, 'text');

      assert(cols.base_duration, 'Column base_duration must exist');
      assert.strictEqual(cols.base_duration.data_type, 'integer');

      assert(cols.base_price, 'Column base_price must exist');
      assert.strictEqual(cols.base_price.data_type, 'numeric');

      assert(cols.created_at, 'Column created_at must exist');
      assert(cols.updated_at, 'Column updated_at must exist');

      // Zero forbidden/speculative columns
      assert(!cols.is_active, 'Forbidden column is_active must NOT exist in service_offers');
      assert(!cols.provider_id, 'Forbidden column provider_id must NOT exist in service_offers');
      assert(!cols.deleted_at, 'Forbidden column deleted_at must NOT exist in service_offers');
    });

    // -------------------------------------------------------------------------
    // TEST 2: Verificar existencia y schema de service_assignments
    // -------------------------------------------------------------------------
    await test('T2. service_assignments schema, columns, defaults & non-nullability', async () => {
      const res = await client.query(`
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns
        WHERE table_name = 'service_assignments'
        ORDER BY ordinal_position;
      `);
      const cols = res.rows.reduce((acc, r) => { acc[r.column_name] = r; return acc; }, {});
      assert(cols.id, 'Column id must exist');
      assert.strictEqual(cols.id.data_type, 'uuid');
      assert(cols.tenant_id, 'Column tenant_id must exist');
      assert(cols.establishment_id, 'Column establishment_id must exist');
      assert(cols.service_offer_id, 'Column service_offer_id must exist');
      assert(cols.membership_id, 'Column membership_id must exist');
      assert(cols.created_at, 'Column created_at must exist');

      // Zero forbidden columns in assignments (DEC-AS-013)
      assert(!cols.status, 'Forbidden column status must NOT exist in service_assignments');
      assert(!cols.created_by, 'Forbidden column created_by must NOT exist in service_assignments');
      assert(!cols.assigned_by, 'Forbidden column assigned_by must NOT exist in service_assignments');
      assert(!cols.provider_id, 'Forbidden column provider_id must NOT exist in service_assignments');
      assert(!cols.deleted_at, 'Forbidden column deleted_at must NOT exist in service_assignments');
      assert(!cols.revoked_at, 'Forbidden column revoked_at must NOT exist in service_assignments');
      assert(!cols.updated_at, 'Forbidden column updated_at must NOT exist in service_assignments');
    });

    // -------------------------------------------------------------------------
    // TEST 3: Verificar constraints de Foundation Compat (DEC-FC-001) y service_assignments
    // -------------------------------------------------------------------------
    await test('T3. Constraints integrity (DEC-FC-001, composite FKs & UNIQUEs)', async () => {
      // 3.1 Check memberships constraint
      const memRes = await client.query(`
        SELECT conname, contype 
        FROM pg_constraint 
        WHERE conrelid = 'memberships'::regclass AND conname = 'uq_membership_id_establishment_tenant';
      `);
      assert.strictEqual(memRes.rows.length, 1, 'uq_membership_id_establishment_tenant must exist on memberships');
      assert.strictEqual(memRes.rows[0].contype, 'u', 'Must be UNIQUE constraint');

      // 3.2 Check service_offers constraints
      const soRes = await client.query(`
        SELECT conname, contype 
        FROM pg_constraint 
        WHERE conrelid = 'service_offers'::regclass;
      `);
      const soConstraints = soRes.rows.map(r => r.conname);
      assert(soConstraints.includes('service_offers_pkey'), 'service_offers PK must exist');
      assert(soConstraints.includes('fk_service_offers_tenant'), 'fk_service_offers_tenant must exist');
      assert(soConstraints.includes('fk_service_offers_establishment'), 'fk_service_offers_establishment must exist');
      assert(soConstraints.includes('uq_service_offers_id_tenant'), 'uq_service_offers_id_tenant must exist');
      assert(soConstraints.includes('uq_service_offers_id_establishment_tenant'), 'uq_service_offers_id_establishment_tenant must exist');
      assert(soConstraints.includes('chk_service_offers_duration'), 'chk_service_offers_duration must exist');
      assert(soConstraints.includes('chk_service_offers_price'), 'chk_service_offers_price must exist');

      // 3.3 Check service_assignments constraints
      const saRes = await client.query(`
        SELECT conname, contype 
        FROM pg_constraint 
        WHERE conrelid = 'service_assignments'::regclass;
      `);
      const saConstraints = saRes.rows.map(r => r.conname);
      assert(saConstraints.includes('service_assignments_pkey'), 'service_assignments PK must exist');
      assert(saConstraints.includes('fk_service_assignments_tenant'), 'fk_service_assignments_tenant must exist');
      assert(saConstraints.includes('fk_service_assignments_establishment'), 'fk_service_assignments_establishment must exist');
      assert(saConstraints.includes('fk_service_assignments_service_offer'), 'fk_service_assignments_service_offer must exist');
      assert(saConstraints.includes('fk_service_assignments_membership'), 'fk_service_assignments_membership must exist');
      assert(saConstraints.includes('uq_service_assignments_offer_membership'), 'uq_service_assignments_offer_membership must exist');
    });

    // -------------------------------------------------------------------------
    // TEST 4: Verificar índices físicos no especulativos
    // -------------------------------------------------------------------------
    await test('T4. Indexes presence on service_offers & service_assignments', async () => {
      const idxRes = await client.query(`
        SELECT indexname 
        FROM pg_indexes 
        WHERE tablename IN ('service_offers', 'service_assignments');
      `);
      const indexes = idxRes.rows.map(r => r.indexname);
      assert(indexes.includes('idx_service_offers_tenant_id'), 'idx_service_offers_tenant_id must exist');
      assert(indexes.includes('idx_service_offers_establishment_tenant'), 'idx_service_offers_establishment_tenant must exist');
      assert(indexes.includes('idx_service_assignments_tenant_id'), 'idx_service_assignments_tenant_id must exist');
      assert(indexes.includes('idx_service_assignments_establishment_tenant'), 'idx_service_assignments_establishment_tenant must exist');
      assert(indexes.includes('idx_service_assignments_membership_id'), 'idx_service_assignments_membership_id must exist');
    });

    // -------------------------------------------------------------------------
    // TEST 5: Verificar RLS activo y políticas
    // -------------------------------------------------------------------------
    await test('T5. Row-Level Security (RLS) enabled and policies active', async () => {
      const rlsRes = await client.query(`
        SELECT relname, relrowsecurity 
        FROM pg_class 
        WHERE relname IN ('service_offers', 'service_assignments');
      `);
      for (const row of rlsRes.rows) {
        assert.strictEqual(row.relrowsecurity, true, `Table ${row.relname} must have row security enabled`);
      }

      const polRes = await client.query(`
        SELECT tablename, policyname 
        FROM pg_policies 
        WHERE tablename IN ('service_offers', 'service_assignments');
      `);
      const policies = polRes.rows.map(r => `${r.tablename}.${r.policyname}`);
      assert(policies.includes('service_offers.tenant_isolation_service_offers'), 'service_offers policy must exist');
      assert(policies.includes('service_assignments.tenant_isolation_service_assignments'), 'service_assignments policy must exist');
    });

    // -------------------------------------------------------------------------
    // TEST 6: Inserción relacional completa (Positive Test)
    // -------------------------------------------------------------------------
    await test('T6. Positive insertion flow (Service Offer + Service Assignment)', async () => {
      await client.query('BEGIN;');
      try {
        // Obtenemos o creamos fixtures en Sede Demo
        const estRes = await client.query('SELECT id, tenant_id FROM establishments LIMIT 1;');
        assert(estRes.rows.length > 0, 'Establishment fixture must exist');
        const estId = estRes.rows[0].id;
        const tenantId = estRes.rows[0].tenant_id;

        const memRes = await client.query('SELECT id FROM memberships WHERE establishment_id = $1 LIMIT 1;', [estId]);
        assert(memRes.rows.length > 0, 'Membership fixture must exist');
        const memId = memRes.rows[0].id;

        // Inserción de oferta
        const offerRes = await client.query(`
          INSERT INTO service_offers (tenant_id, establishment_id, name, description, base_duration, base_price)
          VALUES ($1, $2, 'Corte Premium Test', 'Prueba automatizada DDL', 60, 50000.00)
          RETURNING id;
        `, [tenantId, estId]);
        const offerId = offerRes.rows[0].id;

        // Inserción de asignación
        const assignRes = await client.query(`
          INSERT INTO service_assignments (tenant_id, establishment_id, service_offer_id, membership_id)
          VALUES ($1, $2, $3, $4)
          RETURNING id;
        `, [tenantId, estId, offerId, memId]);
        assert(assignRes.rows[0].id, 'Assignment ID should be returned');

        // Rollback para no ensuciar la base
        await client.query('ROLLBACK;');
      } catch (err) {
        await client.query('ROLLBACK;');
        throw err;
      }
    });

    // -------------------------------------------------------------------------
    // TEST 7: Rechazo de Cruzamiento Inter-Sede (Negative Test - Cross-Establishment)
    // -------------------------------------------------------------------------
    await test('T7. Negative rejection: Cross-establishment assignment blocked by composite FK', async () => {
      await client.query('BEGIN;');
      try {
        const estRes = await client.query('SELECT id, tenant_id FROM establishments LIMIT 1;');
        const est1Id = estRes.rows[0].id;
        const tenantId = estRes.rows[0].tenant_id;

        // Creamos una segunda sede dentro del mismo tenant para la prueba
        const est2Res = await client.query(`
          INSERT INTO establishments (tenant_id, organization_id, name, slug)
          SELECT tenant_id, organization_id, 'Sede B Test', 'sede-b-test-' || gen_random_uuid()
          FROM establishments WHERE id = $1
          RETURNING id;
        `, [est1Id]);
        const est2Id = est2Res.rows[0].id;

        // Membership en Sede 1
        const memRes = await client.query('SELECT id FROM memberships WHERE establishment_id = $1 LIMIT 1;', [est1Id]);
        const memId = memRes.rows[0].id;

        // Offer en Sede 2
        const offerRes = await client.query(`
          INSERT INTO service_offers (tenant_id, establishment_id, name, description, base_duration, base_price)
          VALUES ($1, $2, 'Servicio Sede B', 'Desc', 30, 25000.00)
          RETURNING id;
        `, [tenantId, est2Id]);
        const offer2Id = offerRes.rows[0].id;

        // Intento ilegal: Asignar Offer de Sede 2 a Membership de Sede 1 bajo Sede 2
        let errorCaught = false;
        try {
          await client.query(`
            INSERT INTO service_assignments (tenant_id, establishment_id, service_offer_id, membership_id)
            VALUES ($1, $2, $3, $4);
          `, [tenantId, est2Id, offer2Id, memId]);
        } catch (fkErr) {
          errorCaught = true;
          assert(
            fkErr.message.includes('fk_service_assignments_membership') || 
            fkErr.code === '23503',
            `Expected FK constraint violation, got: ${fkErr.message}`
          );
        }

        assert(errorCaught, 'Database MUST reject cross-establishment assignment via composite FK');
        await client.query('ROLLBACK;');
      } catch (err) {
        await client.query('ROLLBACK;');
        throw err;
      }
    });

    // -------------------------------------------------------------------------
    // TEST 8: Rechazo de Duplicados por Pareja (Negative Test - UNIQUE pair)
    // -------------------------------------------------------------------------
    await test('T8. Negative rejection: Duplicate (service_offer_id, membership_id) blocked by UNIQUE', async () => {
      await client.query('BEGIN;');
      try {
        const estRes = await client.query('SELECT id, tenant_id FROM establishments LIMIT 1;');
        const estId = estRes.rows[0].id;
        const tenantId = estRes.rows[0].tenant_id;
        const memRes = await client.query('SELECT id FROM memberships WHERE establishment_id = $1 LIMIT 1;', [estId]);
        const memId = memRes.rows[0].id;

        const offerRes = await client.query(`
          INSERT INTO service_offers (tenant_id, establishment_id, name, description, base_duration, base_price)
          VALUES ($1, $2, 'Corte Unicidad', 'Desc', 45, 30000.00)
          RETURNING id;
        `, [tenantId, estId]);
        const offerId = offerRes.rows[0].id;

        // Primer insert
        await client.query(`
          INSERT INTO service_assignments (tenant_id, establishment_id, service_offer_id, membership_id)
          VALUES ($1, $2, $3, $4);
        `, [tenantId, estId, offerId, memId]);

        // Segundo insert (duplicado)
        let dupError = false;
        try {
          await client.query(`
            INSERT INTO service_assignments (tenant_id, establishment_id, service_offer_id, membership_id)
            VALUES ($1, $2, $3, $4);
          `, [tenantId, estId, offerId, memId]);
        } catch (uErr) {
          dupError = true;
          assert(
            uErr.message.includes('uq_service_assignments_offer_membership') || 
            uErr.code === '23505',
            `Expected UNIQUE constraint violation, got: ${uErr.message}`
          );
        }

        assert(dupError, 'Database MUST reject duplicate assignment pair');
        await client.query('ROLLBACK;');
      } catch (err) {
        await client.query('ROLLBACK;');
        throw err;
      }
    });

    // -------------------------------------------------------------------------
    // TEST 9: Aislamiento RLS en Tiempo de Ejecución
    // -------------------------------------------------------------------------
    await test('T9. RLS Tenant isolation evaluation (Zero cross-tenant leakage)', async () => {
      await client.query('BEGIN;');
      try {
        const estRes = await client.query('SELECT id, tenant_id FROM establishments LIMIT 1;');
        const estId = estRes.rows[0].id;
        const tenant1 = estRes.rows[0].tenant_id;

        const offerRes = await client.query(`
          INSERT INTO service_offers (tenant_id, establishment_id, name, description, base_duration, base_price)
          VALUES ($1, $2, 'Oferta Tenant 1', 'Desc', 45, 30000.00)
          RETURNING id;
        `, [tenant1, estId]);
        const offerId = offerRes.rows[0].id;

        // Seteamos contexto para tenant 9999 (distinto)
        await client.query("SELECT set_config('app.tenant_id', '9999', true);");

        const readRes = await client.query('SELECT * FROM service_offers WHERE id = $1;', [offerId]);
        assert.strictEqual(readRes.rows.length, 0, 'RLS must hide Tenant 1 offer from Tenant 9999');

        await client.query('ROLLBACK;');
      } catch (err) {
        await client.query('ROLLBACK;');
        throw err;
      }
    });

  } finally {
    client.release();
    await pool.end();
  }

  console.log('\n--------------------------------------------------------------------------------');
  console.log(`TOTAL: ${passed + failed} | PASSED: ${passed} | FAILED: ${failed}`);
  console.log('--------------------------------------------------------------------------------\n');

  if (failed > 0) {
    process.exit(1);
  }
}

runPhysicalVerificationSuite().catch((err) => {
  console.error('FATAL SUITE ERROR:', err);
  process.exit(1);
});
