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
 * Clasifica de forma pura el estado de salud de la base de datos sin mentir.
 * 
 * @param {Object} dbStatus - Objeto devuelto por getDbStatus()
 * @returns {{ status: string, message: string, httpStatus: number, degradado: boolean }}
 */
function clasificarSalud(dbStatus) {
  if (!dbStatus) {
    return { status: 'UNKNOWN', message: 'Estado de base de datos no disponible', httpStatus: 200, degradado: false };
  }

  // Estado sin comprobar (indefinido / null): NO es DEGRADED, es CHECKING / UNKNOWN con HTTP 200
  if (dbStatus.pgAvailable === null && !dbStatus.servingFabricatedData) {
    return { status: 'UNKNOWN', message: 'Backend con estado de base de datos sin comprobar', httpStatus: 200, degradado: false };
  }

  // Estado degradado real: pgAvailable === false o servingFabricatedData === true
  const degradado = dbStatus.servingFabricatedData === true || dbStatus.pgAvailable === false;
  if (degradado) {
    return { status: 'DEGRADED', message: 'Backend con capa de datos degradada', httpStatus: 503, degradado: true };
  }

  return { status: 'OK', message: 'Backend funcionando', httpStatus: 200, degradado: false };
}

/**
 * Decide de forma pura si el candado debe bloquear una petición según el estado de la BD.
 * 
 * @param {Object} dbStatus - Objeto devuelto por getDbStatus()
 * @returns {{ shouldBlock: boolean, reason: string, httpStatus?: number, header?: string }}
 */
function decidirBloqueo(dbStatus) {
  if (!dbStatus) {
    return { shouldBlock: false, reason: 'NO_STATUS' };
  }

  // Si la BD está sin comprobar (pgAvailable === null) y no se fabrican datos, NO se bloquea por flag rancio.
  if (dbStatus.pgAvailable === null && !dbStatus.servingFabricatedData) {
    return { shouldBlock: false, reason: 'UNCHECKED' };
  }

  const isDegraded = dbStatus.servingFabricatedData === true || dbStatus.pgAvailable === false;
  if (isDegraded) {
    return { shouldBlock: true, reason: 'DEGRADED_DB', httpStatus: 503, header: 'memory-fallback' };
  }

  return { shouldBlock: false, reason: 'HEALTHY' };
}

/**
 * Middleware para bloquear superficies de datos bajo /api cuando la capa de datos está degradada.
 * Garantiza que ninguna superficie de datos engañe al cliente con HTTP 200 y datos en memoria/fabricados.
 */
function degradedLockMiddleware(req, res, next) {
  const dbStatus = db.getDbStatus();
  const decision = decidirBloqueo(dbStatus);

  if (!decision.shouldBlock) {
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
  res.setHeader('X-GlowApp-Degraded', decision.header || 'memory-fallback');
  return res.status(decision.httpStatus || 503).json({
    success: false,
    error: 'DATA_LAYER_DEGRADED',
    message: 'Servicio no disponible en modo degradado sin conexión a la base de datos'
  });
}

module.exports = {
  DEGRADED_ALLOWLIST,
  degradedLockMiddleware,
  clasificarSalud,
  decidirBloqueo
};
