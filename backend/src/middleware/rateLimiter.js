// backend/src/middleware/rateLimiter.js

const requestsMap = new Map();

/**
 * Middleware de Rate Limiting ligero y nativo en memoria (evita dependencias externas)
 * diseñado para proteger endpoints críticos de fuerza bruta en producción.
 * 
 * @param {Object} options configuración del limitador
 * @param {number} options.windowMs Ventana de tiempo en milisegundos
 * @param {number} options.max Intentos máximos en la ventana
 * @param {string} options.message Mensaje de error personalizado
 */
module.exports = (options = {}) => {
  const windowMs = options.windowMs || 60 * 1000; // 1 minuto por defecto
  const max = options.max || 10; // 10 peticiones máx
  const message = options.message || 'Demasiadas peticiones. Por favor intenta más tarde.';

  return (req, res, next) => {
    const ip = req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    const now = Date.now();

    if (!requestsMap.has(ip)) {
      requestsMap.set(ip, []);
    }

    const requestTimestamps = requestsMap.get(ip);

    // Filtrar marcas de tiempo fuera de la ventana actual
    const activeTimestamps = requestTimestamps.filter(timestamp => now - timestamp < windowMs);
    
    if (activeTimestamps.length >= max) {
      return res.status(429).json({
        success: false,
        error: 'TOO_MANY_REQUESTS',
        message
      });
    }

    // Registrar petición actual y actualizar mapa
    activeTimestamps.push(now);
    requestsMap.set(ip, activeTimestamps);

    next();
  };
};
