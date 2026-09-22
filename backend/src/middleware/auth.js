// backend/src/middleware/auth.js
const jwt = require('jsonwebtoken');
const { pool } = require('../config/db');
const { getJwtSecret, toApiRole } = require('../config/jwt');
const redisClient = require('../config/redis');
const tenantContextMiddleware = require('./tenantContext');

// 1. Middleware para verificar autenticación
const authMiddleware = async (req, res, next) => {
  // If req.user is already set (e.g., by test mock), skip verification
  if (req.user) {
    return next();
  }
  const authHeader = req.header('Authorization') || '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7).trim() : null;
  if (!token) return res.status(401).json({ error: 'UNAUTHORIZED' });

  try {
    // PARCHE DE SEGURIDAD: Token Blacklisting con Redis (FAIL-SAFE)
    if (redisClient && redisClient.isReady) {
      try {
        const isBlacklisted = await redisClient.get(`beauty:token_blacklist:${token}`);
        if (isBlacklisted) {
          return res.status(401).json({ error: 'Token revocado. Por favor inicie sesión de nuevo.' });
        }
      } catch (redisErr) {
        console.error('Error de Redis en authMiddleware:', redisErr.message);
      }
    }

    const verified = jwt.verify(token, getJwtSecret());

    // Consultar el rol y tenant_id actual del usuario en la base de datos
    const userRes = await pool.query('SELECT rol, tenant_id FROM usuarios WHERE id = $1', [verified.id]);
    if (userRes.rows.length === 0) {
      return res.status(401).json({ error: 'Usuario no encontrado en el sistema.' });
    }

    const dbRole = userRes.rows[0].rol;
    const dbTenantId = userRes.rows[0].tenant_id;
    
    // NOTA DE SEGURIDAD (065): aquí se ejecutaba
    //   pool.query('SELECT set_config($1, $2, false)', ['app.tenant_id', dbTenantId])
    // con is_local = false, es decir a NIVEL DE SESIÓN. La conexión volvía al
    // pool con el tenant aún fijado y la siguiente petición que la reutilizara
    // —incluida una no autenticada, que no pasa por el `if`— heredaba el tenant
    // anterior: fuga cross-tenant. Además nunca se reseteaba.
    //
    // El contexto se fija ahora de forma transaccional y con limpieza garantizada
    // (set_config con is_local = true + ROLLBACK/COMMIT + release en finally),
    // en el middleware tenantContext, que es el único punto autorizado a
    // establecer app.tenant_id. Se conserva dbTenantId en req.user para que ese
    // middleware y los controladores lo usen.

    req.user = {
      id: verified.id,
      email: verified.email,
      role: toApiRole(dbRole),
      rol: dbRole,
      tenant_id: dbTenantId,
      token
    };

    // Se encadena el contexto de tenant aquí porque este es el único punto donde
    // req.user ya está poblado. Con el flag desactivado (por defecto) es un
    // passthrough. Los fallos del middleware se envían al manejador de errores
    // de Express para que no se confundan con un 'Token inválido'.
    tenantContextMiddleware(req, res, next).catch(next);
    return;
  } catch (err) {
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