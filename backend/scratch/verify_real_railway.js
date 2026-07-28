const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const REAL_RAILWAY_DATABASE_URL = 'postgresql://postgres:3d3aB6gecf1dcCdB653CGD2dee23dG4A@caboose.proxy.rlwy.net:18931/railway';

async function queryRealRailwayDB() {
  console.log('=== CONECTANDO A BASE DE DATOS REAL DE PRODUCCIÓN EN RAILWAY ===');
  console.log('Host:', 'caboose.proxy.rlwy.net:18931/railway\n');

  const pool = new Pool({
    connectionString: REAL_RAILWAY_DATABASE_URL,
    ssl: { rejectUnauthorized: false }
  });

  try {
    // 1. information_schema.columns para beauty_profiles y biometric_history
    const columnsRes = await pool.query(`
      SELECT table_name, column_name, data_type, udt_name
      FROM information_schema.columns
      WHERE table_name IN ('beauty_profiles', 'biometric_history')
      ORDER BY table_name, ordinal_position;
    `);

    console.log('--- 1. RESULTADO LITERAL DE INFORMATION_SCHEMA.COLUMNS ---');
    console.table(columnsRes.rows);

    // 2. Conteo de filas en beauty_profiles
    const countProfilesRes = await pool.query('SELECT COUNT(*)::int as count FROM beauty_profiles;');
    const profilesCount = countProfilesRes.rows[0].count;
    console.log(`\n--- 2. CONTEO TOTAL EN beauty_profiles: ${profilesCount} ---`);

    if (profilesCount > 0) {
      const sampleProfiles = await pool.query('SELECT id, user_id, created_at FROM beauty_profiles LIMIT 5;');
      console.log('Muestra de los primeros 5 registros de beauty_profiles:');
      console.table(sampleProfiles.rows);
    }

    // 3. Conteo de filas en biometric_history
    const countHistoryRes = await pool.query('SELECT COUNT(*)::int as count FROM biometric_history;');
    const historyCount = countHistoryRes.rows[0].count;
    console.log(`\n--- 3. CONTEO TOTAL EN biometric_history: ${historyCount} ---`);

    if (historyCount > 0) {
      const sampleHistory = await pool.query('SELECT id, user_id, profile_id, created_at FROM biometric_history LIMIT 5;');
      console.log('Muestra de los primeros 5 registros de biometric_history:');
      console.table(sampleHistory.rows);
    }

  } catch (error) {
    console.error('❌ Error conectando a Railway:', error.message);
  } finally {
    await pool.end();
  }
}

queryRealRailwayDB();
