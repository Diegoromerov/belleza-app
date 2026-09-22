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

module.exports = {
  authLimiter,
  otpLimiter,
  paymentLimiter,
};