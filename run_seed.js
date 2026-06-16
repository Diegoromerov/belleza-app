const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const sql = fs.readFileSync(path.join(__dirname, 'railway_seed.sql'), 'utf8');

const client = new Client({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function run() {
  try {
    console.log('🔌 Conectando a Railway...');
    await client.connect();
    console.log('✅ Conectado! Ejecutando seed...\n');
    await client.query(sql);
    console.log('\n✅ SEED COMPLETADO EXITOSAMENTE!');

    // Verificacion
    const result = await client.query(`
      SELECT 'usuarios'  AS tabla, COUNT(*) AS registros FROM usuarios          WHERE id IN (101,102,103,104,105)
      UNION ALL SELECT 'perfiles', COUNT(*) FROM perfiles_prestador WHERE id IN (101,102,103,104,105)
      UNION ALL SELECT 'services', COUNT(*) FROM services           WHERE provider_id IN (101,102,103,104,105)
      UNION ALL SELECT 'portfolio', COUNT(*) FROM portfolio_items   WHERE provider_id IN (101,102,103,104,105)
      UNION ALL SELECT 'bookings',  COUNT(*) FROM bookings          WHERE provider_id IN (101,102,103,104,105)
      UNION ALL SELECT 'reviews',   COUNT(*) FROM reviews           WHERE provider_id IN (101,102,103,104,105)
    `);
    
    console.log('\n📊 VERIFICACION:');
    console.table(result.rows);
  } catch (err) {
    console.error('❌ Error:', err.message);
  } finally {
    await client.end();
  }
}

run();
