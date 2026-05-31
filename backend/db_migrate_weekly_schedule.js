const { pool } = require('./src/config/db');

async function migrate() {
  const defaultSchedule = JSON.stringify({
    lunes: { activo: true, inicio: 6, fin: 20 },
    martes: { activo: true, inicio: 6, fin: 20 },
    miercoles: { activo: true, inicio: 6, fin: 20 },
    jueves: { activo: true, inicio: 6, fin: 20 },
    viernes: { activo: true, inicio: 6, fin: 20 },
    sabado: { activo: true, inicio: 8, fin: 18 },
    domingo: { activo: false, inicio: 8, fin: 18 }
  });

  try {
    await pool.query(`
      ALTER TABLE perfiles_prestador 
      ADD COLUMN IF NOT EXISTS weekly_schedule JSONB DEFAULT '${defaultSchedule}'::jsonb;
    `);
    console.log('✅ Column weekly_schedule added to perfiles_prestador successfully');
  } catch (err) {
    console.error('❌ Migration Error:', err);
  } finally {
    pool.end();
  }
}

migrate();
