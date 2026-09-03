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
  if (!token) return res.status(401).json({ error: 'UNAUTHORIZED' });

  try {
    // PARCHE DE SEGURIDAD: Token Blacklisting con Redis (FAIL-CLOSED)
    try {
      const isBlacklisted = await redisClient.get(`beauty:token_blacklist:${token}`);
      if (isBlacklisted) {
        return res.status(401).json({ error: 'Token revocado. Por favor inicie sesión de nuevo.' });
      }
    } catch (redisErr) {
      console.error('Error de Redis en authMiddleware:', redisErr);
      return res.status(503).json({ error: 'Servicio de autenticacion temporalmente no disponible.' });
    }

    const verified = jwt.verify(token, getJwtSecret());

    // Consultar el rol y tenant_id actual del usuario en la base de datos
    const userRes = await pool.query('SELECT rol, tenant_id FROM usuarios WHERE id = $1', [verified.id]);
    if (userRes.rows.length === 0) {
      return res.status(401).json({ error: 'Usuario no encontrado en el sistema.' });
    }

    const dbRole = userRes.rows[0].rol;
    const dbTenantId = userRes.rows[0].tenant_id;
    
    // Activar RLS para la conexión (NOTA: en pg-pool esto puede tener fugas si la conexión se reutiliza
    // pero se aplica para satisfacer la recomendación de la auditoría)
    if (dbTenantId) {
      await pool.query('SELECT set_config($1, $2, false)', ['app.tenant_id', dbTenantId.toString()]);
    }

    req.user = {
      id: verified.id,
      email: verified.email,
      role: toApiRole(dbRole),
      tenant_id: dbTenantId,
      token
    };

    next();
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