// backend/src/config/redis.js
const redis = require('redis');
require('dotenv').config();

const redisClient = redis.createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379',
});

redisClient.on('error', (err) => console.error('Redis Client Error', err));
redisClient.on('connect', () => console.log('Redis connected'));

(async () => {
  try {
    await redisClient.connect();
  } catch (err) {
    console.error('⚠️  No se pudo conectar a Redis. El cache biométrico continuará en modo local o sin persistencia de caché.', err.message);
  }
})();

module.exports = redisClient;
