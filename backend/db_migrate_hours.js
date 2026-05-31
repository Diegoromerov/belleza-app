const { pool } = require('./src/config/db');

async function migrate() {
  try {
    await pool.query(`
      ALTER TABLE perfiles_prestador 
      ADD COLUMN IF NOT EXISTS active_start_hour INT DEFAULT 6,
      ADD COLUMN IF NOT EXISTS active_end_hour INT DEFAULT 20;
    `);
    console.log('✅ Columns active_start_hour and active_end_hour added to perfiles_prestador successfully');
  } catch (err) {
    console.error('❌ Migration Error:', err);
  } finally {
    pool.end();
  }
}

migrate();
