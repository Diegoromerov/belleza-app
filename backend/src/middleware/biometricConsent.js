/**
 * backend/src/middleware/biometricConsent.js
 * Middleware para validar consentimiento biométrico antes de procesar datos sensibles
 * Cumple Ley 1581/2012: consentimiento previo, expreso, informado, verificable
 */

const { pool } = require('../config/db');
const { getRedisClient } = require('./rateLimiter');

/**
 * Cache en memoria para consentimientos (TTL 5 min)
 * Fallback si Redis no disponible
 */
const consentCache = new Map();
const CACHE_TTL = 5 * 60 * 1000; // 5 minutos

/**
 * Tipos de consentimiento válidos
 */
const VALID_CONSENT_TYPES = [
  'facial_analysis',
  'skin_scan', 
  'hair_analysis',
  'body_measurement',
  'virtual_try_on',
  'all_biometric'
];

/**
 * Tipos de acceso válidos para auditoría
 */
const VALID_ACCESS_TYPES = [
  'read_profile',
  'analyze_photo',
  'update_profile', 
  'delete_data',
  'virtual_try_on'
];

/**
 * Verifica si un usuario tiene consentimiento válido para un tipo específico
 * @param {string} userId - UUID del usuario
 * @param {string} consentType - Tipo de consentimiento requerido
 * @returns {Promise<{ allowed: boolean, reason: string, consent: Object|null }>}
 */
async function verifyConsent(userId, consentType) {
  try {
    // Validar tipo de consentimiento
    if (!VALID_CONSENT_TYPES.includes(consentType)) {
      return { 
        allowed: false, 
        reason: `Tipo de consentimiento inválido: ${consentType}`,
        consent: null 
      };
    }
    
    // Intentar cache primero
    const cacheKey = `${userId}:${consentType}`;
    const cached = consentCache.get(cacheKey);
    if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
      return cached.result;
    }
    
    // Intentar Redis
    const redis = await getRedisClient();
    if (redis) {
      try {
        const redisKey = `consent:${userId}:${consentType}`;
        const cachedRedis = await redis.get(redisKey);
        if (cachedRedis) {
          const result = JSON.parse(cachedRedis);
          consentCache.set(cacheKey, { result, timestamp: Date.now() });
          return result;
        }
      } catch (e) {
        console.warn('⚠️ Redis cache error, usando DB:', e.message);
      }
    }
    
    // Consultar base de datos
    const query = `
      SELECT id, granted, granted_at, revoked_at, purpose, version_terms
      FROM biometric_consents
      WHERE user_id = $1 AND consent_type = $2
      ORDER BY version_terms DESC
      LIMIT 1
    `;
    
    const res = await pool.query(query, [userId, consentType]);
    
    let result;
    
    if (res.rows.length === 0) {
      result = {
        allowed: false,
        reason: 'NO_CONSENT_FOUND: Usuario no ha otorgado consentimiento para este tipo de dato biométrico',
        consent: null,
        code: 'NO_CONSENT'
      };
    } else {
      const consent = res.rows[0];
      
      if (!consent.granted) {
        result = {
          allowed: false,
          reason: 'CONSENT_DENIED: Usuario rechazó el consentimiento',
          consent: { ...consent, granted: false },
          code: 'CONSENT_DENIED'
        };
      } else if (consent.revoked_at) {
        result = {
          allowed: false,
          reason: 'CONSENT_REVOKED: Usuario revocó el consentimiento',
          consent: { ...consent, granted: false },
          code: 'CONSENT_REVOKED'
        };
      } else {
        result = {
          allowed: true,
          reason: 'CONSENT_VALID',
          consent: consent
        };
      }
    }
    
    // Cachear resultado
    consentCache.set(cacheKey, { result, timestamp: Date.now() });
    
    // Guardar en Redis si disponible
    if (redis) {
      try {
        const redisKey = `consent:${userId}:${consentType}`;
        await redis.setEx(redisKey, 300, JSON.stringify(result)); // 5 min TTL
      } catch (e) {
        // Ignorar errores de Redis
      }
    }
    
    return result;
    
  } catch (error) {
    console.error('❌ Error verificando consentimiento:', error.message);
    // Fail closed por seguridad legal
    return {
      allowed: false,
      reason: 'CONSENT_CHECK_ERROR: Error interno verificando consentimiento',
      consent: null,
      code: 'CONSENT_ERROR'
    };
  }
}

/**
 * Middleware Express para validar consentimiento en rutas biométricas
 * @param {string} consentType - Tipo de consentimiento requerido
 * @returns {Function} Middleware Express
 */
function requireBiometricConsent(consentType) {
  return async (req, res, next) => {
    try {
      const userId = req.user?.id;
      
      if (!userId) {
        return res.status(401).json({
          error: 'unauthorized',
          message: 'Autenticación requerida para acceder a datos biométricos'
        });
      }
      
      const { allowed, reason, consent, code } = await verifyConsent(userId, consentType);
      
      if (!allowed) {
        // Log de intento sin consentimiento (auditoría)
        await logBiometricAccess({
          userId,
          accessedBy: 'middleware',
          accessType: `attempt_${consentType}`,
          consentId: consent?.id,
          ip: req.ip,
          details: { reason, code, endpoint: req.originalUrl }
        });
        
        return res.status(403).json({
          error: 'biometric_consent_required',
          code,
          message: reason,
          consent_type: consentType,
          action_required: code === 'CONSENT_REVOKED' ? 're_grant' : 'grant_initial'
        });
      }
      
      // Adjuntar consentimiento al request para uso posterior
      req.biometricConsent = consent;
      next();
      
    } catch (error) {
      console.error('❌ Error en middleware consentimiento:', error.message);
      res.status(500).json({
        error: 'internal_error',
        message: 'Error verificando consentimiento biométrico'
      });
    }
  };
}

/**
 * Registra acceso a datos biométricos (auditoría Ley 1581)
 * @param {Object} params - Parámetros del acceso
 */
async function logBiometricAccess({ userId, accessedBy, accessType, consentId, ip, details = {} }) {
  try {
    const query = `
      INSERT INTO biometric_access_log 
      (user_id, accessed_by, access_type, consent_id, ip_address, details)
      VALUES ($1, $2, $3, $4, $5, $6)
    `;
    
    await pool.query(query, [
      userId,
      accessedBy,
      accessType,
      consentId || null,
      ip || null,
      JSON.stringify(details)
    ]);
  } catch (error) {
    console.error('❌ Error logging biometric access:', error.message);
    // No fallar el request principal por error de auditoría
  }
}

/**
 * Obtiene todos los consentimientos de un usuario
 * @param {string} userId - UUID del usuario
 * @returns {Promise<Array>} Lista de consentimientos
 */
async function getUserConsents(userId) {
  try {
    const query = `
      SELECT id, consent_type, granted, granted_at, revoked_at, purpose, version_terms, created_at
      FROM biometric_consents
      WHERE user_id = $1
      ORDER BY consent_type
    `;
    
    const res = await pool.query(query, [userId]);
    return res.rows;
  } catch (error) {
    console.error('❌ Error obteniendo consentimientos:', error.message);
    return [];
  }
}

/**
 * Otorga consentimiento biométrico
 * @param {Object} params - { userId, consentType, purpose, ip, userAgent, versionTerms }
 * @returns {Promise<Object>} Consentimiento creado
 */
async function grantConsent({ userId, consentType, purpose, ip, userAgent, versionTerms = '1.0' }) {
  try {
    if (!VALID_CONSENT_TYPES.includes(consentType)) {
      throw new Error(`Tipo de consentimiento inválido: ${consentType}`);
    }
    
    if (!purpose || purpose.length < 10) {
      throw new Error('Finalidad (purpose) requerida y debe tener al menos 10 caracteres');
    }
    
    const query = `
      INSERT INTO biometric_consents 
      (user_id, consent_type, granted, granted_at, purpose, ip_address, user_agent, version_terms)
      VALUES ($1, $2, TRUE, NOW(), $3, $4, $5, $6)
      ON CONFLICT (user_id, consent_type, version_terms) 
      DO UPDATE SET 
        granted = TRUE,
        granted_at = NOW(),
        revoked_at = NULL,
        purpose = EXCLUDED.purpose,
        ip_address = EXCLUDED.ip_address,
        user_agent = EXCLUDED.user_agent,
        updated_at = NOW()
      RETURNING *
    `;
    
    const res = await pool.query(query, [
      userId, 
      consentType, 
      purpose, 
      ip || null, 
      userAgent || null, 
      versionTerms
    ]);
    
    // Invalidar cache
    const cacheKey = `${userId}:${consentType}`;
    consentCache.delete(cacheKey);
    
    // Log de auditoría
    await logBiometricAccess({
      userId,
      accessedBy: 'user_self',
      accessType: 'grant_consent',
      ip: ip,
      details: { consentType, purpose, versionTerms }
    });
    
    return res.rows[0];
  } catch (error) {
    console.error('❌ Error otorgando consentimiento:', error.message);
    throw error;
  }
}

/**
 * Revoca consentimiento biométrico (derecho de supresión Art. 15 Ley 1581)
 * @param {string} userId - UUID del usuario
 * @param {string} consentType - Tipo de consentimiento a revocar
 * @returns {Promise<Object>} Consentimiento revocado
 */
async function revokeConsent(userId, consentType) {
  try {
    const query = `
      UPDATE biometric_consents
      SET granted = FALSE, revoked_at = NOW(), updated_at = NOW()
      WHERE user_id = $1 AND consent_type = $2
      RETURNING *
    `;
    
    const res = await pool.query(query, [userId, consentType]);
    
    if (res.rows.length === 0) {
      throw new Error('Consentimiento no encontrado');
    }
    
    // Invalidar cache
    const cacheKey = `${userId}:${consentType}`;
    consentCache.delete(cacheKey);
    
    // Log de auditoría
    await logBiometricAccess({
      userId,
      accessedBy: 'user_self',
      accessType: 'revoke_consent',
      details: { consentType }
    });
    
    return res.rows[0];
  } catch (error) {
    console.error('❌ Error revocando consentimiento:', error.message);
    throw error;
  }
}

/**
 * Elimina datos biométricos tras revocación (derecho de supresión)
 * @param {string} userId - UUID del usuario
 * @param {string} consentType - Tipo de consentimiento revocado
 * @returns {Promise<{ deleted: number }>} Cantidad de registros eliminados
 */
async function deleteBiometricData(userId, consentType) {
  try {
    // Solo eliminar si el consentimiento está revocado
    const consentCheck = await pool.query(
      'SELECT revoked_at FROM biometric_consents WHERE user_id = $1 AND consent_type = $2',
      [userId, consentType]
    );
    
    if (consentCheck.rows.length === 0 || !consentCheck.rows[0].revoked_at) {
      throw new Error('No se puede eliminar: consentimiento no revocado');
    }
    
    let deleted = 0;
    
    // Eliminar según tipo de consentimiento
    // Nota: Ajustar tablas según tu schema real
    if (consentType === 'facial_analysis' || consentType === 'all_biometric') {
      // Eliminar embeddings faciales, fotos, etc.
      // const res = await pool.query('DELETE FROM facial_biometrics WHERE user_id = $1', [userId]);
      // deleted += res.rowCount;
    }
    
    if (consentType === 'skin_scan' || consentType === 'all_biometric') {
      // Eliminar análisis de piel, fotos, etc.
    }
    
    if (consentType === 'hair_analysis' || consentType === 'all_biometric') {
      // Eliminar análisis de cabello
    }
    
    // Log de auditoría
    await logBiometricAccess({
      userId,
      accessedBy: 'system',
      accessType: 'delete_data',
      details: { consentType, deleted }
    });
    
    return { deleted };
  } catch (error) {
    console.error('❌ Error eliminando datos biométricos:', error.message);
    throw error;
  }
}

/**
 * Obtiene logs de acceso biométrico (para auditoría SIC)
 * @param {Object} filters - { userId, startDate, endDate, accessType }
 * @returns {Promise<Array>} Logs de acceso
 */
async function getAccessLogs(filters = {}) {
  try {
    let query = `
      SELECT id, user_id, accessed_by, access_type, consent_id, ip_address, accessed_at, details
      FROM biometric_access_log
      WHERE 1=1
    `;
    const params = [];
    let paramIndex = 1;
    
    if (filters.userId) {
      query += ` AND user_id = $${paramIndex++}`;
      params.push(filters.userId);
    }
    if (filters.startDate) {
      query += ` AND accessed_at >= $${paramIndex++}`;
      params.push(filters.startDate);
    }
    if (filters.endDate) {
      query += ` AND accessed_at <= $${paramIndex++}`;
      params.push(filters.endDate);
    }
    if (filters.accessType) {
      query += ` AND access_type = $${paramIndex++}`;
      params.push(filters.accessType);
    }
    
    query += ` ORDER BY accessed_at DESC LIMIT 1000`;
    
    const res = await pool.query(query, params);
    return res.rows;
  } catch (error) {
    console.error('❌ Error obteniendo logs de acceso:', error.message);
    return [];
  }
}

module.exports = {
  verifyConsent,
  requireBiometricConsent,
  logBiometricAccess,
  getUserConsents,
  grantConsent,
  revokeConsent,
  deleteBiometricData,
  getAccessLogs,
  VALID_CONSENT_TYPES,
  VALID_ACCESS_TYPES
};