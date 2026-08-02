// scripts/apply_address_columns_node.js
// Fallback Node.js para aplicar columnas de dirección si psql no está disponible.
// Usa variables de entorno: PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD

// Resuelve 'pg' desde el node_modules del backend si no está instalado en scripts/
const path = require('path');
const MODULE_PATHS = [
  path.join(__dirname, '..', 'backend', 'node_modules'),
  path.join(__dirname, 'node_modules'),
];
MODULE_PATHS.forEach(p => {
  if (!require.resolve.paths('pg').includes(p)) {
    require.resolve.paths('pg').unshift(p);
  }
});
// Permite require() encontrar pg en el backend
process.env.NODE_PATH = MODULE_PATHS.join(require('path').delimiter);
require('module').Module._initPaths();

const { Pool } = require('pg');
const fs = require('fs');

const LOG_FILE = path.join(__dirname, 'verify_columns_node.log');

function log(msg) {
  const line = `[${new Date().toISOString()}] ${msg}`;
  console.log(line);
  fs.appendFileSync(LOG_FILE, line + '\n');
}

async function main() {
  const required = ['PGHOST', 'PGPORT', 'PGDATABASE', 'PGUSER', 'PGPASSWORD'];
  const missing = required.filter((k) => !process.env[k]);
  if (missing.length > 0) {
    console.error(`❌ Faltan variables de entorno: ${missing.join(', ')}`);
    process.exit(1);
  }

  const pool = new Pool({
    host: process.env.PGHOST,
    port: parseInt(process.env.PGPORT, 10),
    database: process.env.PGDATABASE,
    user: process.env.PGUSER,
    password: process.env.PGPASSWORD,
    ssl: process.env.PGSSL === 'true' ? { rejectUnauthorized: false } : false,
  });

  const sqlPath = path.join(__dirname, '..', 'backend', 'sql', 'add_address_columns.sql');
  if (!fs.existsSync(sqlPath)) {
    console.error(`❌ No se encontró el archivo SQL: ${sqlPath}`);
    process.exit(1);
  }
  const sql = fs.readFileSync(sqlPath, 'utf8');

  const client = await pool.connect();
  try {
    log('Iniciando transacción...');
    await client.query('BEGIN');
    await client.query(sql);
    await client.query('COMMIT');
    log('✅ ALTER TABLE ejecutado y confirmado (COMMIT).');
  } catch (err) {
    await client.query('ROLLBACK');
    log(`❌ Error ejecutando SQL, ROLLBACK realizado: ${err.message}`);
    process.exitCode = 1;
    return;
  } finally {
    client.release();
  }

  // Verificación en information_schema
  try {
    const columnasEsperadas = [
      'tipo_via', 'numero_via', 'numero_placa',
      'numero_complemento', 'complemento_interior', 'barrio', 'localidad',
    ];
    const res = await pool.query(
      `SELECT column_name, data_type
       FROM information_schema.columns
       WHERE table_name = 'bookings' AND column_name = ANY($1)
       ORDER BY column_name;`,
      [columnasEsperadas]
    );

    log(`Columnas encontradas (${res.rows.length}/${columnasEsperadas.length}):`);
    res.rows.forEach((r) => log(`  - ${r.column_name} (${r.data_type})`));

    const encontradas = res.rows.map((r) => r.column_name);
    const faltantes = columnasEsperadas.filter((c) => !encontradas.includes(c));
    if (faltantes.length > 0) {
      log(`⚠️ Columnas NO encontradas: ${faltantes.join(', ')}`);
      process.exitCode = 1;
    } else {
      log('✅ Todas las columnas esperadas están presentes.');
    }
  } catch (err) {
    log(`❌ Error verificando columnas: ${err.message}`);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}

main().catch((err) => {
  console.error('❌ Error fatal:', err.message);
  process.exit(1);
});
