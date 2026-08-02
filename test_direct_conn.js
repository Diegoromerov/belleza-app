require('dotenv').config();
const { Pool } = require('pg');

console.log('🔍 Verificando variables de entorno...');
console.log('DB_HOST:', process.env.DB_HOST);
console.log('DB_PORT:', process.env.DB_PORT);
console.log('DB_NAME:', process.env.DB_NAME);
console.log('DB_USER:', process.env.DB_USER);
console.log('NVIDIA_API_KEY:', process.env.NVIDIA_API_KEY ? '✅ Configurada' : '❌ Faltante');

const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT, 10),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('❌ Error de conexión directa:', err.message);
    console.log('💡 Tip: ¿Está el contenedor Docker corriendo? Ejecuta: docker ps');
  } else {
    console.log('✅ ¡Conexión exitosa! Hora del servidor:', res.rows[0].now);
  }
  pool.end();
});