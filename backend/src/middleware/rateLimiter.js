// backend/src/middleware/rateLimiter.js
const rateLimit = require('express-rate-limit');

// 1. Limitador estricto para rutas de Autenticación (Login, Registro, Password Reset)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: (process.env.NODE_ENV === 'test') ? 1000 : 10, // 10 intentos por IP en prod/dev, relajado en test
  message: { error: 'Demasiados intentos de autenticación. Intente de nuevo en 15 minutos.' },
  standardHeaders: true,
  legacyHeaders: false,
});

// 2. Limitador ultra estricto para OTP (Generación y Validación)
const otpLimiter = rateLimit({
  windowMs: 10 * 60 * 1000, // 10 minutos
  max: (process.env.NODE_ENV === 'test') ? 1000 : 5, // 5 intentos por IP
  message: { error: 'Demasiados intentos de código OTP. Intente de nuevo en 10 minutos.' },
  standardHeaders: true,
  legacyHeaders: false,
});

// 3. Limitador para Pagos y Creación de Reservas
const paymentLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: (process.env.NODE_ENV === 'test') ? 1000 : 20, // 20 transacciones por IP
  message: { error: 'Demasiadas solicitudes de pago/reserva. Intente de nuevo más tarde.' },
  standardHeaders: true,
  legacyHeaders: false,
});

// 4. Helper dinámico para rate limit por usuario (ej: Chat)
const rateLimitByUser = (options = {}) => {
  return rateLimit({
    windowMs: options.windowMs || 15 * 60 * 1000,
    max: (process.env.NODE_ENV === 'test') ? 1000 : (options.max || 100),
    message: { error: 'Demasiados mensajes de chat. Por favor intente más tarde.' },
    standardHeaders: true,
    legacyHeaders: false,
    validate: { xForwardedForHeader: false, default: false },
    keyGenerator: (req) => (req.user && req.user.id ? String(req.user.id) : req.ip),
  });
};

// 5. Helper por IP arbitrario
const rateLimitByIP = (options = {}) => {
  return rateLimit({
    windowMs: options.windowMs || 15 * 60 * 1000,
    max: (process.env.NODE_ENV === 'test') ? 1000 : (options.limit || options.max || 100),
    message: { error: 'Demasiadas solicitudes desde esta IP.' },
    standardHeaders: true,
    legacyHeaders: false,
  });
};

const TIER_LIMITS = {
  free: { requests: 30, windowMs: 60000 },
  premium: { requests: 100, windowMs: 60000 },
  anonymous: { requests: 10, windowMs: 60000 },
};

const GLOBAL_IP_LIMIT = { requests: 200, windowMs: 60000 };

const getTierLimit = (tier) => TIER_LIMITS[tier] || TIER_LIMITS.free;

const checkRateLimit = async (userId, tier = 'free') => {
  const limitConfig = getTierLimit(tier);
  return { allowed: true, remaining: limitConfig.requests, resetAt: new Date(Date.now() + limitConfig.windowMs), total: 0 };
};

const resetRateLimit = async (userId, tier = 'all') => {};

const isRedisAvailable = () => false;

module.exports = {
  authLimiter,
  otpLimiter,
  paymentLimiter,
  rateLimitByUser,
  rateLimitByIP,
  TIER_LIMITS,
  GLOBAL_IP_LIMIT,
  getTierLimit,
  checkRateLimit,
  resetRateLimit,
  isRedisAvailable,
};