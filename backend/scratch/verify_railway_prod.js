const { Pool } = require('pg');

async function verifyRailwayProd() {
  console.log('=== VERIFICACIÓN EN BASE DE DATOS REAL DE RAILWAY (PRODUCCIÓN) ===\n');
  console.log('Host/URL de BD:', process.env.DATABASE_URL ? process.env.DATABASE_URL.replace(/:[^:@]+@/, ':****@') : 'NO DATABASE_URL');

  if (!process.env.DATABASE_URL) {
    console.error('❌ Error: DATABASE_URL no está definida en las variables de Railway.');
    process.exit(1);
  }

  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
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

    console.log('\n--- 1. COLUMNAS Y TIPOS REALES DE DATOS ---');
    console.table(columnsRes.rows);

    // 2. Conteo de filas en beauty_profiles
    const countProfilesRes = await pool.query('SELECT COUNT(*) FROM beauty_profiles;');
    const profilesCount = parseInt(countProfilesRes.rows[0].count, 10);
    console.log(`\n--- 2. CONTEO TOTAL DE FILAS EN beauty_profiles: ${profilesCount} ---`);

    if (profilesCount > 0) {
      const sampleProfiles = await pool.query('SELECT id, user_id, created_at FROM beauty_profiles LIMIT 5;');
      console.log('Muestra de los primeros 5 registros de beauty_profiles:');
      console.table(sampleProfiles.rows);
    }

    // 3. Conteo de filas en biometric_history
    const countHistoryRes = await pool.query('SELECT COUNT(*) FROM biometric_history;');
    const historyCount = parseInt(countHistoryRes.rows[0].count, 10);
    console.log(`\n--- 3. CONTEO TOTAL DE FILAS EN biometric_history: ${historyCount} ---`);

    if (historyCount > 0) {
      const sampleHistory = await pool.query('SELECT id, user_id, profile_id, created_at FROM biometric_history LIMIT 5;');
      console.log('Muestra de los primeros 5 registros de biometric_history:');
      console.table(sampleHistory.rows);
    }

  } catch (error) {
    console.error('❌ Error ejecutando verificación en Railway:', error.message);
  } finally {
    await pool.end();
  }
}

verifyRailwayProd();
