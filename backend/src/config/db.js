const { Pool } = require('pg');
require('dotenv').config();

// 🛡️ PARCHE DE SEGURIDAD Y AISLAMIENTO DE ENTORNOS
const isProduction = process.env.NODE_ENV === 'production';
const isStaging = process.env.NODE_ENV === 'staging';

if (isProduction && !process.env.DATABASE_URL) {
  console.warn('⚠️ [ENTORNO PRODUCCIÓN] DATABASE_URL no configurada explícitamente en producción.');
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ...(process.env.DATABASE_URL ? {} : {
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
  }),
  ssl: (process.env.DATABASE_URL || isProduction || isStaging) ? { rejectUnauthorized: false } : false,
  max: isProduction ? 30 : 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on('error', (err) => {
  console.error('❌ Error inesperado en el pool de PostgreSQL:', err.message);
});

const testConnection = async () => {
  try {
    const client = await pool.connect();
    const res = await client.query('SELECT current_database(), current_user');
    client.release();
    console.log(`✅ Conexión exitosa a PostgreSQL [DB: ${res.rows[0].current_database}, Entorno: ${process.env.NODE_ENV || 'development'}]`);
    return true;
  } catch (err) {
    console.error('❌ Error conectando a PostgreSQL:', err.message);
    return false;
  }
};

// ── Conexión a la base de datos RAG (pgvector) ──
// Solo se crea si existe la variable RAG_DATABASE_URL
const ragPool = process.env.RAG_DATABASE_URL
  ? new Pool({
      connectionString: process.env.RAG_DATABASE_URL,
      ssl: process.env.RAG_DATABASE_URL.includes('railway.internal')
        ? false
        : { rejectUnauthorized: false },
      max: isProduction ? 15 : 10,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
    })
  : null;

const testRagConnection = async () => {
  if (!ragPool) {
    console.warn('⚠️ ragPool no configurado — RAG_DATABASE_URL ausente');
    return false;
  }
  try {
    const client = await ragPool.connect();
    const res = await client.query('SELECT current_database()');
    client.release();
    console.log(`✅ RAG conectado a: ${res.rows[0].current_database}`);
    return true;
  } catch (err) {
    console.error('❌ Error conectando a RAG:', err.message);
    return false;
  }
};

module.exports = { pool, testConnection, ragPool, testRagConnection };
