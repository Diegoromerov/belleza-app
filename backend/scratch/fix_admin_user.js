const { Client } = require('pg');
const bcrypt = require('bcryptjs');

const DATABASE_URL = 'postgres://postgres:3d3aB6gecf1dcCdB653CGD2dee23dG4A@caboose.proxy.rlwy.net:18931/railway';

const client = new Client({
  connectionString: DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function run() {
  try {
    console.log('🔌 Conectando a la base de datos de Railway (Público)...');
    await client.connect();
    console.log('✅ Conectado exitosamente.');

    console.log('🧹 Eliminando usuario admin existente (si aplica)...');
    await client.query("DELETE FROM usuarios WHERE email = 'admin@glow.app';");

    console.log('🔑 Generando hash de contraseña...');
    const passwordHash = bcrypt.hashSync('admin123', 10);
    console.log('Hash generado:', passwordHash);

    console.log('👤 Insertando nuevo usuario administrador...');
    await client.query(`
      INSERT INTO usuarios (id, email, password_hash, nombre, phone, auth_provider, provider_id, rol, onboarding_completo, is_active)
      VALUES (
          999,
          'admin@glow.app',
          $1,
          'Administrador Glow',
          '+57310000000',
          'LOCAL',
          'local_admin_glow',
          'ADMIN',
          true,
          true
      );
    `, [passwordHash]);

    console.log('🔍 Consultando usuario admin para verificar...');
    const res = await client.query("SELECT id, email, nombre, rol, is_active, auth_provider FROM usuarios WHERE email = 'admin@glow.app';");
    console.log('📊 Resultado:');
    console.table(res.rows);

  } catch (err) {
    console.error('❌ Error executing SQL:', err);
  } finally {
    await client.end();
  }
}

run();
