/**
 * backend/src/middleware/rateLimiter.js
 * Middleware de Rate Limiting con Redis - Sliding Window
 * Límites por tier: Free 30/min, Premium 100/min, Anónimo 10/min
 * Límite global por IP: 200/min
 */

const Redis = require('redis');

/**
 * Cliente Redis singleton
 */
let redisClient = null;
let redisConnected = false;

async function getRedisClient() {
  if (redisClient && redisConnected) return redisClient;
  
  try {
    const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';
    redisClient = Redis.createClient({ url: redisUrl });
    
    redisClient.on('error', (err) => {
      console.error('❌ Redis rate limiter error:', err.message);
      redisConnected = false;
    });
    
    redisClient.on('connect', () => {
      console.log('✅ Redis rate limiter conectado');
      redisConnected = true;
    });
    
    await redisClient.connect();
    return redisClient;
  } catch (error) {
    console.warn('⚠️ Redis no disponible para rate limiting:', error.message);
    redisConnected = false;
    return null;
  }
}

/**
 * Configuración de límites por tier
 */
const TIER_LIMITS = {
  free: { requests: 30, windowMs: 60000 },      // 30/min
  premium: { requests: 100, windowMs: 60000 },  // 100/min
  anonymous: { requests: 10, windowMs: 60000 }, // 10/min por IP
};

/**
 * Límite global por IP (protección DDoS básica)
 */
const GLOBAL_IP_LIMIT = { requests: 200, windowMs: 60000 }; // 200/min por IP

/**
 * Claves Redis para rate limiting
 */
const REDIS_KEYS = {
  user: (userId, tier) => `ratelimit:user:${tier}:${userId}`,
  ip: (ip) => `ratelimit:ip:${ip}`,
  globalIp: (ip) => `ratelimit:global:${ip}`,
  abuse: (userId) => `abuse:${userId}`,
};

/**
 * Obtiene el límite para un tier
 * @param {string} tier - 'free', 'premium', 'anonymous'
 * @returns {Object} { requests, windowMs }
 */
function getTierLimit(tier) {
  return TIER_LIMITS[tier] || TIER_LIMITS.free;
}

/**
 * Implementación de Sliding Window usando Redis sorted sets
 * Cada request añade un entry con timestamp como score
 * Se eliminan entries fuera de la ventana
 * 
 * @param {Object} redis - Cliente Redis
 * @param {string} key - Clave Redis
 * @param {number} limit - Límite de requests
 * @param {number} windowMs - Ventana en milisegundos
 * @returns {Promise<{ allowed: boolean, remaining: number, resetAt: Date, total: number }>}
 */
async function checkSlidingWindow(redis, key, limit, windowMs) {
  const now = Date.now();
  const windowStart = now - windowMs;
  
  // Pipeline atómico: limpiar viejo + contar + añadir + expirar
  const pipeline = redis.multi();
  
  // 1. Eliminar entradas fuera de la ventana
  pipeline.zRemRangeByScore(key, 0, windowStart);
  
  // 2. Contar entradas actuales
  pipeline.zCard(key);
  
  // 3. Añadir nueva entrada (timestamp como score, UUID como member)
  const member = `${now}:${Math.random().toString(36).substring(7)}`;
  pipeline.zAdd(key, { score: now, value: member });
  
  // 4. Establecer TTL (ventana + buffer)
  pipeline.expire(key, Math.ceil(windowMs / 1000) + 10);
  
  const results = await pipeline.exec();
  
  // results[1] es el zCard (conteo actual)
  const currentCount = results[1] || 0;
  const allowed = currentCount <= limit;
  const remaining = Math.max(0, limit - currentCount);
  
  // Calcular cuándo se resetea (timestamp del entry más antiguo + windowMs)
  const oldest = await redis.zRange(key, 0, 0);
  const resetAt = oldest.length > 0 
    ? new Date(parseInt(oldest[0].split(':')[0]) + windowMs)
    : new Date(now + windowMs);
  
  return { allowed, remaining, resetAt, total: currentCount };
}

/**
 * Middleware de rate limiting por usuario (con tier)
 * @param {Object} options - { tier?: string, customLimit?: { requests, windowMs } }
 * @returns {Function} Middleware Express
 */
function rateLimitByUser(options = {}) {
  const { tier = 'free', customLimit } = options;
  const limitConfig = customLimit || getTierLimit(tier);
  
  return async (req, res, next) => {
    try {
      const userId = req.user?.id || req.user?.userId;
      
      if (!userId) {
        // Usuario no autenticado - usar rateLimitByIP
        return rateLimitByIP({ limit: TIER_LIMITS.anonymous.requests, windowMs: TIER_LIMITS.anonymous.windowMs })(req, res, next);
      }
      
      const redis = await getRedisClient();
      
      // Si Redis no disponible, fallar open (permitir request pero loggear)
      if (!redis) {
        console.warn('⚠️ Rate limiter: Redis no disponible, permitiendo request');
        return next();
      }
      
      // Verificar límite global por IP primero
      const clientIp = req.ip || req.connection?.remoteAddress || 'unknown';
      const globalResult = await checkSlidingWindow(
        redis, 
        REDIS_KEYS.globalIp(clientIp), 
        GLOBAL_IP_LIMIT.requests, 
        GLOBAL_IP_LIMIT.windowMs
      );
      
      if (!globalResult.allowed) {
        console.warn(`🚫 Global IP rate limit excedido: ${clientIp}`);
        return res.status(429).json({
          error: 'rate_limit_exceeded',
          message: 'Demasiadas requests desde esta IP. Intente más tarde.',
          retry_after: Math.ceil((globalResult.resetAt.getTime() - Date.now()) / 1000),
        });
      }
      
      // Verificar límite por usuario/tier
      const userKey = REDIS_KEYS.user(userId, tier);
      const userResult = await checkSlidingWindow(
        redis,
        userKey,
        limitConfig.requests,
        limitConfig.windowMs
      );
      
      // Headers informativos
      res.set({
        'X-RateLimit-Limit': limitConfig.requests,
        'X-RateLimit-Remaining': userResult.remaining,
        'X-RateLimit-Reset': Math.ceil(userResult.resetAt.getTime() / 1000),
      });
      
      if (!userResult.allowed) {
        const retryAfter = Math.ceil((userResult.resetAt.getTime() - Date.now()) / 1000);
        
        // Loggear para detección de abuso
        console.warn(`🚫 Rate limit excedido - User: ${userId}, Tier: ${tier}, Total: ${userResult.total}`);
        
        // Trackear abuso
        try {
          const { trackAbuse } = require('../services/abuseDetection');
          await trackAbuse(userId, 'rate_limit_exceeded');
        } catch (e) {
          // Ignorar errores de abuse detection
        }
        
        return res.status(429).json({
          error: 'rate_limit_exceeded',
          message: `Límite de ${limitConfig.requests} requests/min excedido para tier ${tier}`,
          retry_after: retryAfter,
          tier,
        });
      }
      
      next();
    } catch (error) {
      console.error('❌ Error en rateLimitByUser:', error.message);
      // Fail open - permitir request en caso de error
      next();
    }
  };
}

/**
 * Middleware de rate limiting por IP (para endpoints públicos/anónimos)
 * @param {Object} options - { limit: number, windowMs: number }
 * @returns {Function} Middleware Express
 */
function rateLimitByIP(options = {}) {
  const { limit = TIER_LIMITS.anonymous.requests, windowMs = TIER_LIMITS.anonymous.windowMs } = options;
  
  return async (req, res, next) => {
    try {
      const clientIp = req.ip || req.connection?.remoteAddress || 'unknown';
      const redis = await getRedisClient();
      
      if (!redis) {
        return next();
      }
      
      // Verificar límite global por IP
      const globalResult = await checkSlidingWindow(
        redis,
        REDIS_KEYS.globalIp(clientIp),
        GLOBAL_IP_LIMIT.requests,
        GLOBAL_IP_LIMIT.windowMs
      );
      
      if (!globalResult.allowed) {
        return res.status(429).json({
          error: 'rate_limit_exceeded',
          message: 'Demasiadas requests desde esta IP',
          retry_after: Math.ceil((globalResult.resetAt.getTime() - Date.now()) / 1000),
        });
      }
      
      // Verificar límite específico por IP
      const ipResult = await checkSlidingWindow(
        redis,
        REDIS_KEYS.ip(clientIp),
        limit,
        windowMs
      );
      
      res.set({
        'X-RateLimit-Limit': limit,
        'X-RateLimit-Remaining': ipResult.remaining,
        'X-RateLimit-Reset': Math.ceil(ipResult.resetAt.getTime() / 1000),
      });
      
      if (!ipResult.allowed) {
        console.warn(`🚫 IP rate limit excedido: ${clientIp}`);
        return res.status(429).json({
          error: 'rate_limit_exceeded',
          message: `Límite de ${limit} requests/min excedido para esta IP`,
          retry_after: Math.ceil((ipResult.resetAt.getTime() - Date.now()) / 1000),
        });
      }
      
      next();
    } catch (error) {
      console.error('❌ Error en rateLimitByIP:', error.message);
      next();
    }
  };
}

/**
 * Verifica rate limit sin middleware (para uso programático)
 * @param {string} userId - ID del usuario
 * @param {string} tier - 'free' | 'premium'
 * @returns {Promise<{ allowed: boolean, remaining: number, resetAt: Date, total: number }>}
 */
async function checkRateLimit(userId, tier = 'free') {
  try {
    const redis = await getRedisClient();
    if (!redis) return { allowed: true, remaining: 999, resetAt: new Date(Date.now() + 60000), total: 0 };
    
    const limitConfig = getTierLimit(tier);
    return await checkSlidingWindow(
      redis,
      REDIS_KEYS.user(userId, tier),
      limitConfig.requests,
      limitConfig.windowMs
    );
  } catch (error) {
    console.error('❌ Error en checkRateLimit:', error.message);
    return { allowed: true, remaining: 999, resetAt: new Date(Date.now() + 60000), total: 0 };
  }
}

/**
 * Resetea el rate limit de un usuario (para admin)
 * @param {string} userId - ID del usuario
 * @param {string} tier - 'free' | 'premium' | 'all'
 * @returns {Promise<void>}
 */
async function resetRateLimit(userId, tier = 'all') {
  try {
    const redis = await getRedisClient();
    if (!redis) return;
    
    if (tier === 'all') {
      await redis.del(REDIS_KEYS.user(userId, 'free'));
      await redis.del(REDIS_KEYS.user(userId, 'premium'));
      await redis.del(REDIS_KEYS.user(userId, 'anonymous'));
    } else {
      await redis.del(REDIS_KEYS.user(userId, tier));
    }
  } catch (error) {
    console.error('❌ Error en resetRateLimit:', error.message);
  }
}

/**
 * Verifica si Redis está disponible
 * @returns {boolean}
 */
function isRedisAvailable() {
  return redisConnected && redisClient !== null;
}

module.exports = {
  rateLimitByUser,
  rateLimitByIP,
  checkRateLimit,
  resetRateLimit,
  isRedisAvailable,
  getTierLimit,
  TIER_LIMITS,
  GLOBAL_IP_LIMIT,
};