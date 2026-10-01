const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

async function run() {
  try {
    const colRes = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name='biometric_consents' AND column_name='user_id';
    `);
    const totalRes = await pool.query(`SELECT count(*) as total FROM biometric_consents;`);
    const joinRes = await pool.query(`
      SELECT count(*) as active_joined 
      FROM biometric_consents bc 
      JOIN beauty_profiles bp ON bp.user_id = bc.user_id 
      WHERE bc.active = TRUE;
    `);

    console.log("=== MIGRATION 049 VERIFICATION RESULT ===");
    console.log("user_id Column Schema:", colRes.rows[0]);
    console.log("Total Consent Rows:", totalRes.rows[0].total);
    console.log("Active Joined Profiles:", joinRes.rows[0].active_joined);
    console.log("=========================================");
  } catch (err) {
    console.error("Migration check error:", err);
  } finally {
    await pool.end();
  }
}

run();
