const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER || 'glowapp',
  host: process.env.DB_HOST || '127.0.0.1',
  database: process.env.DB_NAME || 'glowapp',
  password: process.env.DB_PASSWORD || 'glowapp_dev_2026',
  port: parseInt(process.env.DB_PORT || '5432', 10) === 5435 ? 5432 : parseInt(process.env.DB_PORT || '5432', 10),
});

async function runSchemaCheck() {
  try {
    console.log('=== VERIFICACIÓN DE ESQUEMA EN POSTGRESQL ===\n');

    // 1. Columnas de beauty_profiles
    const beautyProfilesColumns = await pool.query(`
      SELECT table_name, column_name, data_type, udt_name
      FROM information_schema.columns
      WHERE table_name = 'beauty_profiles'
      ORDER BY ordinal_position;
    `);

    console.log('--- BEAUTY_PROFILES ---');
    console.table(beautyProfilesColumns.rows);

    // 2. Columnas de biometric_history
    const biometricHistoryColumns = await pool.query(`
      SELECT table_name, column_name, data_type, udt_name
      FROM information_schema.columns
      WHERE table_name = 'biometric_history'
      ORDER BY ordinal_position;
    `);

    console.log('\n--- BIOMETRIC_HISTORY ---');
    console.table(biometricHistoryColumns.rows);

    // 3. Revisar filas existentes en beauty_profiles
    const beautyProfilesRows = await pool.query(`
      SELECT * FROM beauty_profiles LIMIT 20;
    `);
    console.log('\n--- FILAS EXISTENTES EN BEAUTY_PROFILES ---');
    console.table(beautyProfilesRows.rows);

    // 4. Revisar filas existentes en biometric_history
    const biometricHistoryRows = await pool.query(`
      SELECT * FROM biometric_history LIMIT 20;
    `);
    console.log('\n--- FILAS EXISTENTES EN BIOMETRIC_HISTORY ---');
    console.table(biometricHistoryRows.rows);

    // 5. Verificar si hay columnas o tablas usuarios / usuarios.id
    const usuariosColumns = await pool.query(`
      SELECT table_name, column_name, data_type, udt_name
      FROM information_schema.columns
      WHERE table_name = 'usuarios'
      ORDER BY ordinal_position;
    `);
    console.log('\n--- USUARIOS ---');
    console.table(usuariosColumns.rows);

  } catch (error) {
    console.error('❌ Error ejecutando consulta de verificación:', error);
  } finally {
    await pool.end();
  }
}

runSchemaCheck();
