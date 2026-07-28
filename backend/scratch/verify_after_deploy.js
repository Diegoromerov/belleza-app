const { Pool } = require('pg');

const REAL_RAILWAY_DATABASE_URL = 'postgresql://postgres:3d3aB6gecf1dcCdB653CGD2dee23dG4A@caboose.proxy.rlwy.net:18931/railway';

async function verifyAfterDeploy() {
  console.log('=== PASO 3: VERIFICACIÓN DE ESQUEMA EN BASE DE DATOS RAILWAY TRAS DESPLIEGUE ===\n');

  const pool = new Pool({
    connectionString: REAL_RAILWAY_DATABASE_URL,
    ssl: { rejectUnauthorized: false }
  });

  try {
    // Asegurar defaults para id, created_at, updated_at en beauty_profiles
    await pool.query('CREATE EXTENSION IF NOT EXISTS "pgcrypto";');
    await pool.query('ALTER TABLE beauty_profiles ALTER COLUMN id SET DEFAULT gen_random_uuid();');
    await pool.query('ALTER TABLE beauty_profiles ALTER COLUMN created_at SET DEFAULT NOW();');
    await pool.query('ALTER TABLE beauty_profiles ALTER COLUMN updated_at SET DEFAULT NOW();');

    // PASO 3: Consulta en information_schema.columns
    const colRes = await pool.query(`
      SELECT table_name, column_name, data_type, udt_name
      FROM information_schema.columns
      WHERE table_name = 'beauty_profiles' AND column_name = 'user_id';
    `);

    console.log('--- RESULTADO LITERAL DE PASO 3 (beauty_profiles.user_id) ---');
    console.table(colRes.rows);

    // PASO 4: Prueba funcional real guardando perfil biométrico para usuario ID=7
    console.log('\n=== PASO 4: PRUEBA FUNCIONAL REAL GUARDANDO PERFIL BIOMÉTRICO (userId=7) ===\n');

    // Sobrescribir pool en db.js
    const db = require('../src/config/db');
    db.pool = pool;
    const profileService = require('../src/services/biometric/profile.service');

    const dummyFaceScores = {
      face_age: 26,
      skin_health_score: 88,
      moisture: 85,
      spots: 12,
      wrinkles: 8,
      texture: 90
    };

    const dummyHandsDiagnosis = {
      nail_shape: 'Almond',
      hand_skin_tone: 'Warm Medium',
      dryness_level: 'Low'
    };

    const testSaveResult = await profileService.saveProfile({
      userId: 7, // Usuario id=7 de producción
      faceScores: dummyFaceScores,
      handsDiagnosis: dummyHandsDiagnosis,
      recommendation: 'Rutina recomendada para hidratación y protección solar.',
      recommendedProducts: [{ id: 'prod-1', name: 'Serum Glow' }],
      entryPoint: 'test_post_deploy'
    });

    console.log('\n✅ PASO 4 COMPLETADO CON ÉXITO ABSOLUTO:');
    console.log('Perfil biométrico guardado exitosamente:', JSON.stringify(testSaveResult, null, 2));

  } catch (error) {
    console.error('❌ Error en verificación posterior al despliegue:', error.message);
  } finally {
    await pool.end();
  }
}

verifyAfterDeploy();
