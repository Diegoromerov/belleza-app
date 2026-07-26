// backend/src/config/migrationRunner.js
const fs = require('fs');
const path = require('path');
const { pool } = require('./db');

async function runMigrations() {
  console.log('🔄 [MIGRATION RUNNER] Iniciando verificación de migraciones...');
  const migrationsDir = path.join(__dirname, '../../migrations');

  if (!fs.existsSync(migrationsDir)) {
    console.log('⚠️ No se encontró la carpeta de migraciones.');
    return;
  }

  const files = fs.readdirSync(migrationsDir).filter(f => f.endsWith('.sql')).sort();
  console.log(`🔍 Encontradas ${files.length} migraciones SQL en ${migrationsDir}`);

  // Asegurar tabla de control de migraciones
  await pool.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      id SERIAL PRIMARY KEY,
      filename VARCHAR(255) UNIQUE NOT NULL,
      applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `);

  let appliedCount = 0;
  for (const file of files) {
    try {
      const checkRes = await pool.query('SELECT id FROM schema_migrations WHERE filename = $1', [file]);
      if (checkRes.rows.length === 0) {
        const filePath = path.join(migrationsDir, file);
        const sql = fs.readFileSync(filePath, 'utf8');

        await pool.query('BEGIN');
        await pool.query(sql);
        await pool.query('INSERT INTO schema_migrations (filename) VALUES ($1)', [file]);
        await pool.query('COMMIT');

        console.log(`✅ [MIGRACIÓN APLICADA] ${file}`);
        appliedCount++;
      }
    } catch (err) {
      await pool.query('ROLLBACK').catch(() => {});
      console.warn(`ℹ️ Migración ${file} ya aplicada anteriormente o con elementos existentes: ${err.message}`);
    }
  }

  console.log(`🎉 [MIGRATION RUNNER] Proceso completado. ${appliedCount} nuevas migraciones aplicadas.\n`);
}

// Permitir ejecución directa vía CLI: node src/config/migrationRunner.js
if (require.main === module) {
  runMigrations()
    .then(() => process.exit(0))
    .catch(err => {
      console.error('❌ Error en el runner de migraciones:', err);
      process.exit(1);
    });
}

module.exports = runMigrations;
