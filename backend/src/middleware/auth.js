// backend/src/middleware/auth.js
const jwt = require('jsonwebtoken');
const { pool } = require('../config/db');
const { getJwtSecret, toApiRole } = require('../config/jwt');
const redisClient = require('../config/redis');

// 1. Middleware para verificar autenticación
const authMiddleware = async (req, res, next) => {
  // If req.user is already set (e.g., by test mock), skip verification
  if (req.user) {
    return next();
  }
  const authHeader = req.header('Authorization') || '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7).trim() : null;
  if (!token) return res.status(401).json({ error: 'UNAUTHORIZED', message: 'Se requiere autenticación.' });

  try {
    // Opcional: Verificación de token revocado en Redis si está disponible
    if (redisClient && redisClient.isReady) {
      try {
        const isBlacklisted = await redisClient.get(`beauty:token_blacklist:${token}`);
        if (isBlacklisted) {
          return res.status(401).json({ error: 'Token revocado. Por favor inicie sesión de nuevo.' });
        }
      } catch (redisErr) {
        console.warn('⚠️ Warning Redis blacklist check:', redisErr.message);
      }
    }

    const verified = jwt.verify(token, getJwtSecret());

    // Consultar el rol y tenant_id actual del usuario en la base de datos
    let userRes;
    try {
      userRes = await pool.query('SELECT rol, tenant_id FROM app_usuario_identidad($1::integer)', [verified.id]);
    } catch (sqlErr) {
      console.warn('⚠️ app_usuario_identidad no disponible, realizando consulta fallback en usuarios:', sqlErr.message);
      try {
        userRes = await pool.query('SELECT rol FROM usuarios WHERE id = $1', [verified.id]);
      } catch (fallbackErr) {
        console.error('❌ Error al consultar usuario en DB:', fallbackErr.message);
        return res.status(401).json({ error: 'Usuario no encontrado en el sistema.' });
      }
    }

    if (!userRes || userRes.rows.length === 0) {
      return res.status(401).json({ error: 'Usuario no encontrado en el sistema.' });
    }

    const dbRole = userRes.rows[0].rol;
    const dbTenantId = userRes.rows[0].tenant_id || null;

    // AISLAMIENTO DE TENANT (fix P0 — tarjeta t_fix_tenant_04)
    // -------------------------------------------------------
    // authMiddleware NO debe fijar `app.tenant_id` sobre la conexión del pool.
    // El bloque anterior (`set_config($1, $2, false)`) era de alcance SESIÓN
    // (is_local = false): el ajuste sobrevivía al fin de la petición y quedaba
    // pegado a la conexión que volvía al pool. Cualquier petición posterior que
    // reutilizara esa conexión —antes de fijar su propio contexto, o en un
    // camino no autenticado— heredaba el tenant anterior: fuga cross-tenant.
    //
    // El contexto de tenant se establece de forma TRANSACCIONAL (is_local = true)
    // sobre una conexión DEDICADA, por la capa de enrutado de tenant
    // (config/tenantRouting.js + middleware/tenantContext.js), que además
    // redirige las consultas hechas con este `pool` a ESA conexión. Aquí solo se
    // publica el tenant en `req.user` para que esa capa lo aplique.
    //
    // NO reintroducir aquí un set_config de sesión. El test
    // `src/tests/tenantAuthIsolation.test.js` falla si vuelve.

    const rawBpId = verified.businessProfileId;
    const sanitizedBpId = (rawBpId && String(rawBpId).trim() !== 'null' && String(rawBpId).trim() !== 'undefined' && String(rawBpId).trim() !== '')
      ? String(rawBpId).trim()
      : null;

    req.user = {
      id: verified.id,
      email: verified.email,
      role: toApiRole(dbRole),
      // `req.user.rol` se leía en dos sitios sin que nadie lo seteara, así que el guard
      // de consentimiento biométrico nunca pasaba (A360-2026-09-22/A-01).
      rol: dbRole,
      tenant_id: dbTenantId,
      businessProfileId: sanitizedBpId,
      token
    };

    next();
  } catch (err) {
    console.error('❌ Error en authMiddleware:', err.message);
    res.status(400).json({ error: 'Token inválido o expirado.' });
  }
};

// 2. Middleware para verificar que el usuario sea admin
const adminMiddleware = async (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ error: 'Acceso denegado. Autenticación requerida.' });
  }

  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Acceso denegado. Se requieren privilegios de administrador.' });
  }

  next();
};

// 3. EXPORTAR AMBOS COMO UN OBJETO
module.exports = {
  authMiddleware,
  adminMiddleware,
  verifyToken: authMiddleware
};
