// C:\beauty-app\backend\src\services\queueService.js
const { createClient } = require('redis');
const { pool } = require('../config/db');
require('dotenv').config();

const redisUrl = process.env.REDIS_URL || `redis://${process.env.REDIS_HOST || 'localhost'}:${process.env.REDIS_PORT || 6379}`;

let redisClient;

async function getRedisClient() {
  if (!redisClient) {
    redisClient = createClient({ url: redisUrl });
    redisClient.on('error', (err) => console.error('❌ Redis Client Error:', err));
    await redisClient.connect();
    console.log('🔌 Conectado a Redis en:', redisUrl);
  }
  return redisClient;
}

/**
 * Busca si existe un trabajo completado recientemente con los mismos parámetros e imagen
 */
async function findCachedJob(imageHash, colorHex, shape, finish, decorationStyle) {
  try {
    const query = `
      SELECT id, preview_url 
      FROM nail_tryon_jobs 
      WHERE image_hash = $1 
        AND color_hex = $2 
        AND shape = $3 
        AND finish = $4 
        AND COALESCE(decoration_style, '') = COALESCE($5, '') 
        AND status = 'completed'
        AND expires_at > NOW()
      ORDER BY created_at DESC 
      LIMIT 1;
    `;
    const res = await pool.query(query, [
      imageHash,
      colorHex || null,
      shape || null,
      finish || null,
      decorationStyle || null
    ]);
    return res.rows.length > 0 ? res.rows[0] : null;
  } catch (err) {
    console.error('Error buscando caché de prueba virtual:', err);
    return null;
  }
}

/**
 * Encola un nuevo trabajo en la lista de Redis
 */
async function enqueueTryonJob(jobId, userId, params, originalImageUrl, imageHash) {
  try {
    const client = await getRedisClient();
    
    // Crear el payload del trabajo para la cola
    const jobPayload = JSON.stringify({
      job_id: jobId,
      user_id: userId,
      color_hex: params.color_hex,
      shape: params.shape,
      finish: params.finish,
      decoration_style: params.decoration_style,
      original_image_url: originalImageUrl,
      image_hash: imageHash,
      created_at: new Date().toISOString()
    });

    // RPUSH a la lista "nail_tryon_queue"
    await client.rPush('nail_tryon_queue', jobPayload);
    console.log(`📥 Trabajo encolado en Redis (ID: ${jobId})`);
    return true;
  } catch (err) {
    console.error('Error al encolar trabajo en Redis:', err);
    throw err;
  }
}

module.exports = {
  getRedisClient,
  findCachedJob,
  enqueueTryonJob
};
