// C:\beauty-app\backend\src\migrations\create_tryon_table.js
const { pool } = require('../config/db');

async function migrate() {
  try {
    console.log('🔄 Ejecutando migración: Creación de la tabla nail_tryon_jobs...');
    const query = `
      CREATE TABLE IF NOT EXISTS nail_tryon_jobs (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
        status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
        color_hex VARCHAR(7),
        shape VARCHAR(50),
        finish VARCHAR(50),
        decoration_style VARCHAR(100),
        original_image_url TEXT NOT NULL,
        preview_url TEXT,
        error_message TEXT,
        image_hash VARCHAR(64),
        created_at TIMESTAMPTZ DEFAULT NOW(),
        expires_at TIMESTAMPTZ NOT NULL
      );
      CREATE INDEX IF NOT EXISTS idx_nail_tryon_jobs_user ON nail_tryon_jobs(user_id);
      CREATE INDEX IF NOT EXISTS idx_nail_tryon_jobs_expires ON nail_tryon_jobs(expires_at);
    `;
    await pool.query(query);
    console.log('✅ Migración completada con éxito. Tabla nail_tryon_jobs e índices creados/verificados.');
  } catch (err) {
    console.error('❌ Error ejecutando migración:', err);
  } finally {
    pool.end();
  }
}

migrate();
