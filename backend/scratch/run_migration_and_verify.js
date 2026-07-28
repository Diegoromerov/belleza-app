process.env.DB_USER = 'glowapp';
process.env.DB_PASSWORD = 'glowapp_dev_2026';
process.env.DB_NAME = 'glowapp';
process.env.DB_HOST = '127.0.0.1';
process.env.DB_PORT = '5432';

const { pool } = require('../src/config/db');
const fs = require('fs');
const path = require('path');
const biometricOrchestrator = require('../src/services/biometric/orchestrator');

async function executeMigrationAndVerify() {
  console.log('=== INICIANDO EJECUCIÓN Y VERIFICACIÓN DE MIGRACIÓN 029 ===\n');

  try {
    // 1. Leer y ejecutar la migración 029
    const migrationPath = path.join(__dirname, '../migrations/029_fix_beauty_profiles_user_id_type.sql');
    const sql = fs.readFileSync(migrationPath, 'utf8');

    console.log('🔄 Ejecutando migración 029_fix_beauty_profiles_user_id_type.sql...');
    await pool.query(sql);
    console.log('✅ Migración 029 ejecutada exitosamente.\n');

    // 2. Consulta de verificación en information_schema.columns
    const columnsQuery = `
      SELECT table_name, column_name, data_type, udt_name
      FROM information_schema.columns
      WHERE table_name IN ('beauty_profiles', 'biometric_history')
      ORDER BY table_name, ordinal_position;
    `;
    const resColumns = await pool.query(columnsQuery);
    console.log('=== RESULTADO DE INFORMATION_SCHEMA.COLUMNS ===');
    console.table(resColumns.rows);

    // 3. Verificar si existe un usuario de prueba en usuarios
    const userCheck = await pool.query('SELECT id FROM usuarios LIMIT 1;');
    let testUserId = 7;
    if (userCheck.rows.length > 0) {
      testUserId = userCheck.rows[0].id;
    } else {
      const newUser = await pool.query(
        "INSERT INTO usuarios (nombre, email, password, rol) VALUES ('Test Biometric', 'test_biometric@glowapp.com', 'hashed_pass', 'CLIENTE') RETURNING id;"
      );
      testUserId = newUser.rows[0].id;
    }

    console.log(`\n🔄 Ejecutando llamada de prueba a biometricOrchestrator.analyze para usuario ID: ${testUserId}...`);
    
    // Crear buffer simulado de imagen
    const dummyImageBuffer = Buffer.from('R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7', 'base64');
    
    const testResult = await biometricOrchestrator.analyze(
      testUserId,
      dummyImageBuffer,
      dummyImageBuffer,
      'ideas_test'
    );

    console.log('\n✅ BIOMETRIC ORCHESTRATOR PRUEBA EXITOSA:');
    console.log(JSON.stringify(testResult, null, 2));

  } catch (error) {
    console.error('❌ Error en ejecución o verificación:', error);
  } finally {
    await pool.end();
  }
}

executeMigrationAndVerify();
