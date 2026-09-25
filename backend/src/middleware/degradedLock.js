const db = require('../config/db');

/**
 * Allowlist explícita de rutas de API exentas del bloqueo automático 503 durante estado degradado.
 * 
 * REGLAS OBLIGATORIAS (C7):
 * 1. Cada entrada TIENE un motivo explícito documentado a su lado.
 * 2. PROHIBIDO usar prefijos comodín (ej: /api/*, /api/public/*).
 */
const DEGRADED_ALLOWLIST = new Set([
  '/api/health',    // Motivo: Endpoint de salud del sistema que debe reportar el estado de degradación (503 DEGRADED) por sí mismo.
  '/api/providers', // Motivo: Endpoint de búsqueda de prestadores con manejo propio de degradación que responde 503 + PROVIDER_SEARCH_DEGRADED.
  '/api/test-db',   // Motivo: Endpoint de diagnóstico de conectividad SQL y versión de PostGIS.
]);

/**
 * Middleware para bloquear superficies de datos bajo /api cuando la capa de datos está degradada.
 * Garantiza que ninguna superficie de datos engañe al cliente con HTTP 200 y datos en memoria/fabricados.
 */
function degradedLockMiddleware(req, res, next) {
  const dbStatus = db.getDbStatus();
  const isDegraded = dbStatus.servingFabricatedData === true || dbStatus.pgAvailable === false;

  if (!isDegraded) {
    return next();
  }

  // Extraer el path completo de la URL sin query parameters
  const rawUrl = req.originalUrl || req.url || '';
  const reqPath = rawUrl.split('?')[0];

  // Si la ruta está en la allowlist motivada, permitir que su propio controller procese y responda
  if (DEGRADED_ALLOWLIST.has(reqPath)) {
    return next();
  }

  // Para cualquier otra superficie de datos bajo /api: bloquear con 503 y declarar la degradación
  res.setHeader('X-GlowApp-Degraded', 'memory-fallback');
  return res.status(503).json({
    success: false,
    error: 'DATA_LAYER_DEGRADED',
    message: 'Servicio no disponible en modo degradado sin conexión a la base de datos'
  });
}

module.exports = {
  DEGRADED_ALLOWLIST,
  degradedLockMiddleware
};
