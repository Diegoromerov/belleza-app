// Stub de config/db para ejecutar el código REAL de origin/main fuera del repo
const path = 'C:/beauty-app/backend';
const { Pool } = require(path + '/node_modules/pg');

const pool = new Pool({ connectionString: process.env.RAG_DATABASE_URL, connectionTimeoutMillis: 5000 });

module.exports = { pool, ragPool: pool };
