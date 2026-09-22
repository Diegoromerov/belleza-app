#!/usr/bin/env node
/**
 * backend/scripts/prepareRlsDatabase.js
 *
 * Deja una base de datos lista para PROBAR el aislamiento multi-tenant:
 * aplica el esquema, crea los roles RLS y transfiere la propiedad de las tablas
 * multi-tenant al rol no superusuario que lo demuestra.
 *
 * POR QUÉ NO SIRVE `npm run migrate`
 * --------------------------------
 * `npm run migrate` es `sequelize.sync({ force: true })`: crea tablas desde los
 * modelos, y ninguna política de RLS vive en un modelo. Levantar PostgreSQL en el
 * CI y ejecutar ese script deja una base sin `tenant_id`, sin políticas y sin
 * `FORCE`: el verificador fallaría, o peor, pasaría por accidente.
 *
 * QUÉ APLICA Y EN QUÉ ORDEN
 * -------------------------
 * El orden importa y está probado contra un PostgreSQL 16 real:
 *   init.sql                              esquema base
 *   055_create_tenants_table.sql          tenants          (067 depende de ella)
 *   056_add_tenant_id_to_core_tables.sql  tenant_id en las tablas base
 *   057_backfill_tenant_id.sql            relleno del inquilino por defecto
 *   058_enable_rls_policies.sql           RLS inicial (lo sustituye 068)
 *   065_multi_tenant_hardening.sql        tenant_id en las tablas SaaS
 *   067_create_multi_salon_ddl.sql        salones / salon_miembros / invitaciones
 *   068_force_rls_strict_isolation.sql    políticas estrictas + FORCE + trigger
 *
 * Uso:
 *   DATABASE_URL_ADMIN=postgres://postgres:postgres@localhost:5432/glowtest \
 *   RLS_ROLE_PASSWORD=ci_only_password \
 *     node backend/scripts/prepareRlsDatabase.js
 *
 * Salida: 0 = preparada | 1 = fallo | 2 = no se pudo probar (falta configuración)
 */

const fs = require('fs');
const path = require('path');
const { Client } = require('pg');

const RAIZ = path.join(__dirname, '..');
const ADMIN_URL = process.env.DATABASE_URL_ADMIN || process.env.DATABASE_URL;
const PASSWORD = process.env.RLS_ROLE_PASSWORD || 'ci_only_password';

const MIGRACIONES = [
  'init.sql',
  'migrations/055_create_tenants_table.sql',
  'migrations/056_add_tenant_id_to_core_tables.sql',
  'migrations/057_backfill_tenant_id.sql',
  'migrations/058_enable_rls_policies.sql',
  'migrations/065_multi_tenant_hardening.sql',
  'migrations/067_create_multi_salon_ddl.sql',
  'migrations/068_force_rls_strict_isolation.sql',
];

async function main() {
  if (!ADMIN_URL) {
    console.error('❌ Falta DATABASE_URL_ADMIN (o DATABASE_URL): no se puede preparar la base.');
    process.exit(2);
  }

  const cliente = new Client({ connectionString: ADMIN_URL });
  try {
    await cliente.connect();
  } catch (error) {
    console.error(`❌ No se pudo conectar a la base: ${error.message}`);
    process.exit(2);
  }

  try {
    // ── 1. Esquema ─────────────────────────────────────────────────────────
    // `init.sql` NO es idempotente: usa CREATE TABLE sin IF NOT EXISTS, así que
    // aplicarlo dos veces falla con 'relation "nail_tryon_jobs" already exists'.
    // Es el arranque del esquema, no una migración, así que solo se aplica si la
    // base está vacía. Las migraciones numeradas sí son idempotentes y se aplican
    // siempre (es lo que permite reintentar este script y el job del CI).
    const { rows: [estado] } = await cliente.query(
      `SELECT count(*)::int AS tablas
         FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public' AND c.relkind = 'r'`
    );
    const baseVacia = estado.tablas === 0;

    console.log(
      baseVacia
        ? '📦 Base vacía: se aplica el esquema completo (init.sql incluido).'
        : `📦 Base ya inicializada (${estado.tablas} tablas): se aplican solo las migraciones idempotentes.`
    );
    for (const relativa of MIGRACIONES) {
      if (relativa === 'init.sql' && !baseVacia) {
        console.log('   ⏭️  init.sql omitido — no es idempotente y el esquema ya existe.');
        continue;
      }
      const absoluta = path.join(RAIZ, relativa);
      if (!fs.existsSync(absoluta)) {
        console.error(`❌ Falta ${relativa}. No se puede preparar la base.`);
        process.exit(1);
      }
      const sql = fs.readFileSync(absoluta, 'utf8');
      try {
        await cliente.query(sql);
        console.log(`   ✅ ${relativa}`);
      } catch (error) {
        console.error(`   ❌ ${relativa}: ${error.message}`);
        process.exit(1);
      }
    }

    // ── 2. Roles RLS ───────────────────────────────────────────────────────
    // app_rls_user (la aplicación, sin privilegios) y app_system (BYPASSRLS para
    // webhooks y jobs), más app_owner: un PROPIETARIO no superusuario, que es el
    // único rol con el que FORCE demuestra algo — un superusuario se salta las
    // políticas siempre, incluso con FORCE.
    console.log('\n👤 Creando los roles RLS:');
    await cliente.query(fs.readFileSync(path.join(__dirname, 'setupRlsRole.sql'), 'utf8'));

    // app_owner primero: setupRlsRole.sql no lo crea (es solo para poder probar
    // FORCE con un propietario no superusuario), y no se puede ALTER un rol que
    // todavía no existe.
    await cliente.query(
      `DO $$ BEGIN
         IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_owner') THEN
           CREATE ROLE app_owner LOGIN NOSUPERUSER NOBYPASSRLS NOCREATEDB NOCREATEROLE NOINHERIT;
         END IF;
       END $$;`
    );
    for (const rol of ['app_rls_user', 'app_owner']) {
      await cliente.query(`ALTER ROLE ${rol} WITH LOGIN PASSWORD '${PASSWORD.replace(/'/g, "''")}'`);
    }
    console.log('   ✅ app_rls_user (aplicación), app_system (BYPASSRLS), app_owner (propietario de prueba)');

    // ── 3. Propiedad de las tablas multi-tenant ────────────────────────────
    // La lista se DERIVA del catálogo (toda tabla con tenant_id) en vez de
    // mantenerse a mano, para que no se quede desactualizada en silencio.
    const { rows: tablas } = await cliente.query(
      `SELECT c.relname
         FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public' AND c.relkind = 'r'
          AND EXISTS (SELECT 1 FROM information_schema.columns i
                       WHERE i.table_schema = 'public' AND i.table_name = c.relname
                         AND i.column_name = 'tenant_id')
        ORDER BY c.relname`
    );
    console.log(`\n🔑 Transfiriendo la propiedad de ${tablas.length} tablas multi-tenant a app_owner:`);
    for (const { relname } of tablas) {
      await cliente.query(`ALTER TABLE public."${relname}" OWNER TO app_owner`);
    }
    await cliente.query('GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_owner');
    await cliente.query('GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_owner');
    await cliente.query('GRANT USAGE ON SCHEMA public TO app_owner');
    console.log(`   ✅ ${tablas.map((t) => t.relname).join(', ')}`);

    // ── 4. Resumen verificable ─────────────────────────────────────────────
    // `usuarios` es la ÚNICA excepción y es deliberada: `auth.js` la consulta para
    // DESCUBRIR el inquilino, cuando todavía no hay contexto; forzarla dejaría el
    // sistema entero en 401 (razón documentada en la cabecera de 068). Todo lo
    // demás debe tener FORCE y política: otra tabla sin ellas es una fuga.
    const EXENTAS_DE_FORCE = ['usuarios'];

    const { rows: [resumen] } = await cliente.query(
      `SELECT count(*)::int AS total,
              count(*) FILTER (WHERE c.relforcerowsecurity)::int AS con_force,
              coalesce(array_agg(c.relname::text ORDER BY c.relname)
                       FILTER (WHERE NOT c.relforcerowsecurity), '{}'::text[]) AS sin_force,
              coalesce(array_agg(c.relname::text ORDER BY c.relname)
                       FILTER (WHERE NOT EXISTS (SELECT 1 FROM pg_policy p WHERE p.polrelid = c.oid)), '{}'::text[]) AS sin_politica
         FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public' AND c.relkind = 'r'
          AND EXISTS (SELECT 1 FROM information_schema.columns i
                       WHERE i.table_schema = 'public' AND i.table_name = c.relname
                         AND i.column_name = 'tenant_id')`
    );
    console.log(`\n📊 Tablas con tenant_id: ${resumen.total} | con FORCE: ${resumen.con_force}`);
    console.log(`   exentas de FORCE (deliberado): ${EXENTAS_DE_FORCE.join(', ')}`);
    console.log(`   sin FORCE (catálogo)         : ${resumen.sin_force.join(', ') || '(ninguna)'}`);
    console.log(`   sin política                 : ${resumen.sin_politica.join(', ') || '(ninguna)'}`);

    const base = ADMIN_URL.replace(/\/\/[^@]*@/, '//');
    console.log('\n✅ Base preparada. URLs para las pruebas:');
    console.log(`   app (DATABASE_URL)              postgres://app_rls_user:<password>@${base.split('//')[1]}`);
    console.log(`   propietario (TEST_DATABASE_URL) postgres://app_owner:<password>@${base.split('//')[1]}`);

    const sinForceInesperadas = resumen.sin_force.filter((t) => !EXENTAS_DE_FORCE.includes(t));
    const sinPoliticaInesperadas = resumen.sin_politica.filter((t) => !EXENTAS_DE_FORCE.includes(t));
    if (sinForceInesperadas.length || sinPoliticaInesperadas.length) {
      console.error(
        '\n❌ Aislamiento incompleto. Sin FORCE: ' +
        `${sinForceInesperadas.join(', ') || '—'}. Sin política: ${sinPoliticaInesperadas.join(', ') || '—'}. Revisa 068.`
      );
      process.exit(1);
    }
    process.exit(0);
  } catch (error) {
    console.error(`\n❌ Error preparando la base: ${error.message}`);
    console.error(error.stack);
    process.exit(1);
  } finally {
    await cliente.end().catch(() => {});
  }
}

main();
