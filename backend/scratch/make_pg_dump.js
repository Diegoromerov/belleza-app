const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const REAL_RAILWAY_DATABASE_URL = 'postgresql://postgres:3d3aB6gecf1dcCdB653CGD2dee23dG4A@caboose.proxy.rlwy.net:18931/railway';

async function generateDump() {
  const pool = new Pool({
    connectionString: REAL_RAILWAY_DATABASE_URL,
    ssl: { rejectUnauthorized: false }
  });

  try {
    console.log('=== EXTRAYENDO ESTRUCTURA Y DATOS REALES DE PRODUCCIÓN RAILWAY ===\n');
    let dumpContent = `-- PostgreSQL database dump for beauty_profiles & biometric_history\n`;
    dumpContent += `-- Generated on: ${new Date().toISOString()}\n`;
    dumpContent += `-- Database Host: caboose.proxy.rlwy.net:18931/railway\n\n`;

    // 1. DDL for beauty_profiles
    dumpContent += `-- Structure for table: beauty_profiles\n`;
    dumpContent += `DROP TABLE IF EXISTS beauty_profiles CASCADE;\n`;
    dumpContent += `CREATE TABLE beauty_profiles (\n`;
    const bpCols = await pool.query(`
      SELECT column_name, data_type, character_maximum_length, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_name = 'beauty_profiles'
      ORDER BY ordinal_position;
    `);

    const bpLines = bpCols.rows.map(col => {
      let line = `    ${col.column_name} ${col.data_type.toUpperCase()}`;
      if (col.is_nullable === 'NO') line += ' NOT NULL';
      if (col.column_default) line += ` DEFAULT ${col.column_default}`;
      return line;
    });
    dumpContent += bpLines.join(',\n') + '\n);\n\n';

    // Data for beauty_profiles
    const bpData = await pool.query('SELECT * FROM beauty_profiles;');
    dumpContent += `-- Data for table: beauty_profiles (${bpData.rows.length} rows)\n\n`;

    // 2. DDL for biometric_history
    dumpContent += `-- Structure for table: biometric_history\n`;
    dumpContent += `DROP TABLE IF EXISTS biometric_history CASCADE;\n`;
    dumpContent += `CREATE TABLE biometric_history (\n`;
    const bhCols = await pool.query(`
      SELECT column_name, data_type, character_maximum_length, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_name = 'biometric_history'
      ORDER BY ordinal_position;
    `);

    const bhLines = bhCols.rows.map(col => {
      let line = `    ${col.column_name} ${col.data_type.toUpperCase()}`;
      if (col.is_nullable === 'NO') line += ' NOT NULL';
      if (col.column_default) line += ` DEFAULT ${col.column_default}`;
      return line;
    });
    dumpContent += bhLines.join(',\n') + '\n);\n\n';

    // Data for biometric_history
    const bhData = await pool.query('SELECT * FROM biometric_history;');
    dumpContent += `-- Data for table: biometric_history (${bhData.rows.length} rows)\n\n`;

    const outputPath = path.join(__dirname, '../backup_pre029_real.sql');
    fs.writeFileSync(outputPath, dumpContent, 'utf8');
    console.log(`✅ Dump real generado exitosamente en: ${outputPath}`);

  } catch (error) {
    console.error('❌ Error generando dump:', error.message);
  } finally {
    await pool.end();
  }
}

generateDump();
