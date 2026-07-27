const NodeCache = require('node-cache');
const usageCache = new NodeCache({ stdTTL: 86400 }); // 1 día default TTL

/**
 * Rate limiting middleware factory.
 *
 * If called without options (isUserMode), it limits each authenticated user to a maximum of 3 heavy analyses per day.
 * If options are provided (windowMs, max, message), it creates a window-based rate limiter per user/IP.
 *
 * @param {Object} [options] - Configuration for rate limiting.
 * @param {number} [options.windowMs=86400000] - Time window in milliseconds.
 * @param {number} [options.max=100] - Maximum allowed requests in the window.
 * @param {string} [options.message='Too many requests'] - Message returned when limit is exceeded.
 * @returns {function} Express middleware.
 */
module.exports = (options = {}) => {
  const { windowMs = 86400000, max = 100, message = 'Too many requests' } = options;
  const isUserMode = Object.keys(options).length === 0;

  return (req, res, next) => {
    try {
      if (isUserMode) {
        const userId = req.userId || (req.user && req.user.id);
        if (!userId) return next();
        const key = `usage_${userId}_${new Date().toDateString()}`;
        const current = usageCache.get(key) || 0;
        if (current >= 3) {
          return res.status(429).json({ error: 'Límite diario alcanzado', message: 'Máximo 3 análisis por día' });
        }
        usageCache.set(key, current + 1);
        return next();
      } else {
        const userId = req.userId || (req.user && req.user.id);
        const ip = req.ip || req.headers['x-forwarded-for'] || req.connection?.remoteAddress;
        const identifier = userId ? `user_${userId}` : `ip_${ip}`;
        const windowStart = Math.floor(Date.now() / windowMs);
        const key = `limiter_${identifier}_${windowStart}`;
        const current = usageCache.get(key) || 0;
        if (current >= max) {
          return res.status(429).json({ error: message });
        }
        usageCache.set(key, current + 1);
        return next();
      }
    } catch (err) {
      console.error('RateLimiter error:', err);
      return res.status(500).json({ error: 'Error interno del limitador de peticiones' });
    }
  };
};
