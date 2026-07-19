const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const DB_URL = process.env.DATABASE_URL || 'postgres://postgres:3d3aB6gecf1dcCdB653CGD2dee23dG4A@caboose.proxy.rlwy.net:18931/railway';

async function run() {
  const client = new Client({ connectionString: DB_URL, ssl: { rejectUnauthorized: false } });
  try {
    console.log('🔌 Conectando a la base de datos de Railway...');
    await client.connect();
    console.log('✅ Conectado!');

    const sqlPath = path.join(__dirname, 'migrations', '025_curso_colorimetria_cabello.sql');
    console.log(`📖 Leyendo archivo SQL de migración: ${sqlPath}`);
    const sqlContent = fs.readFileSync(sqlPath, 'utf8');

    console.log('🚀 Ejecutando script de migración para el curso de colorimetría...');
    await client.query(sqlContent);
    console.log('🎉 Migración y carga del curso ficticio completada con éxito!');
  } catch (e) {
    console.error('❌ Error ejecutando la migración del curso:', e.message);
  } finally {
    await client.end();
  }
}

run();
