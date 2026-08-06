/**
 * backend/src/routes/biometricConsentRoutes.js
 * Rutas API para gestion de consentimientos biometricos
 * Cumple Ley 1581/2012: derechos de acceso, rectificacion, supresion
 */

const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const { 
  getUserConsents, 
  grantConsent, 
  revokeConsent, 
  deleteBiometricData,
  getAccessLogs,
  verifyConsent,
  VALID_CONSENT_TYPES
} = require('../middleware/biometricConsent');

/**
 * @route GET /api/consent/biometric
 * @description Obtiene todos los consentimientos biometricos del usuario autenticado
 * @access Private
 * @returns {Object} Lista de consentimientos con estado
 */
router.get('/biometric', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const consents = await getUserConsents(userId);
    
    res.json({
      success: true,
      data: consents,
      message: 'Consentimientos biometricos obtenidos'
    });
  } catch (error) {
    console.error('Error GET /consent/biometric:', error.message);
    res.status(500).json({ 
      error: 'internal_error', 
      message: 'Error obteniendo consentimientos' 
    });
  }
});

/**
 * @route GET /api/consent/biometric/:consentType
 * @description Verifica si el usuario tiene consentimiento especifico
 * @access Private
 * @returns {Object} Estado del consentimiento
 */
router.get('/biometric/:consentType', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const { consentType } = req.params;
    
    if (!VALID_CONSENT_TYPES.includes(consentType)) {
      return res.status(400).json({
        error: 'invalid_consent_type',
        message: 'Tipo de consentimiento invalido. Validos: ' + VALID_CONSENT_TYPES.join(', ')
      });
    }
    
    const { allowed, reason, consent, code } = await verifyConsent(userId, consentType);
    
    res.json({
      success: true,
      data: {
        consent_type: consentType,
        allowed,
        reason,
        code,
        consent: consent ? {
          id: consent.id,
          granted: consent.granted,
          granted_at: consent.granted_at,
          revoked_at: consent.revoked_at,
          purpose: consent.purpose,
          version_terms: consent.version_terms
        } : null
      }
    });
  } catch (error) {
    console.error('Error GET /consent/biometric/:type:', error.message);
    res.status(500).json({ 
      error: 'internal_error', 
      message: 'Error verificando consentimiento' 
    });
  }
});

/**
 * @route POST /api/consent/biometric
 * @description Otorga consentimiento biometrico
 * @access Private
 * @body { consent_type, purpose, version_terms? }
 * @returns {Object} Consentimiento creado
 */
router.post('/biometric', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const { consent_type, purpose, version_terms = '1.0' } = req.body;
    
    // Validaciones
    if (!consent_type || !VALID_CONSENT_TYPES.includes(consent_type)) {
      return res.status(400).json({
        error: 'invalid_consent_type',
        message: 'Tipo de consentimiento requerido y debe ser uno de: ' + VALID_CONSENT_TYPES.join(', ')
      });
    }
    
    if (!purpose || purpose.trim().length < 10) {
      return res.status(400).json({
        error: 'invalid_purpose',
        message: 'La finalidad (purpose) es requerida y debe tener al menos 10 caracteres'
      });
    }
    
    const consent = await grantConsent({
      userId,
      consentType: consent_type,
      purpose: purpose.trim(),
      ip: req.ip,
      userAgent: req.get('user-agent'),
      versionTerms: version_terms
    });
    
    res.status(201).json({
      success: true,
      data: {
        id: consent.id,
        consent_type: consent.consent_type,
        granted: consent.granted,
        granted_at: consent.granted_at,
        purpose: consent.purpose,
        version_terms: consent.version_terms
      },
      message: 'Consentimiento biometrico otorgado correctamente'
    });
  } catch (error) {
    console.error('Error POST /consent/biometric:', error.message);
    res.status(500).json({ 
      error: 'internal_error', 
      message: 'Error otorgando consentimiento' 
    });
  }
});

/**
 * @route DELETE /api/consent/biometric/:consentType
 * @description Revoca consentimiento biometrico (derecho de supresion)
 * @access Private
 * @returns {Object} Consentimiento revocado
 */
router.delete('/biometric/:consentType', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const { consentType } = req.params;
    
    if (!VALID_CONSENT_TYPES.includes(consentType)) {
      return res.status(400).json({
        error: 'invalid_consent_type',
        message: 'Tipo de consentimiento invalido. Validos: ' + VALID_CONSENT_TYPES.join(', ')
      });
    }
    
    const consent = await revokeConsent(userId, consentType);
    
    res.json({
      success: true,
      data: {
        id: consent.id,
        consent_type: consent.consent_type,
        granted: consent.granted,
        revoked_at: consent.revoked_at
      },
      message: 'Consentimiento revocado. Ahora puede solicitar eliminacion de sus datos biometricos (derecho de supresion Art. 15 Ley 1581)'
    });
  } catch (error) {
    console.error('Error DELETE /consent/biometric/:type:', error.message);
    res.status(500).json({ 
      error: 'internal_error', 
      message: 'Error revocando consentimiento' 
    });
  }
});

/**
 * @route DELETE /api/consent/biometric/:consentType/data
 * @description Elimina datos biometricos tras revocacion (derecho de supresion Art. 15 Ley 1581)
 * @access Private
 * @returns {Object} Confirmacion de eliminacion
 */
router.delete('/biometric/:consentType/data', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const { consentType } = req.params;
    
    if (!VALID_CONSENT_TYPES.includes(consentType)) {
      return res.status(400).json({
        error: 'invalid_consent_type',
        message: 'Tipo de consentimiento invalido. Validos: ' + VALID_CONSENT_TYPES.join(', ')
      });
    }
    
    const result = await deleteBiometricData(userId, consentType);
    
    res.json({
      success: true,
      data: result,
      message: 'Datos biometricos eliminados permanentemente (derecho de supresion Art. 15 Ley 1581)'
    });
  } catch (error) {
    console.error('Error DELETE /consent/biometric/:type/data:', error.message);
    res.status(500).json({ 
      error: 'internal_error', 
      message: error.message || 'Error eliminando datos biometricos' 
    });
  }
});

/**
 * @route GET /api/consent/access-logs
 * @description Obtiene logs de acceso a datos biometricos (auditoria)
 * @access Private (Admin o usuario propio)
 * @query { startDate, endDate, accessType }
 * @returns {Array} Logs de acceso
 */
router.get('/access-logs', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const { startDate, endDate, accessType } = req.query;
    
    // Solo admin puede ver logs de otros usuarios
    const isAdmin = req.user.rol === 'ADMIN';
    const targetUserId = isAdmin && req.query.userId ? req.query.userId : userId;
    
    const logs = await getAccessLogs({
      userId: targetUserId,
      startDate,
      endDate,
      accessType
    });
    
    res.json({
      success: true,
      data: logs,
      count: logs.length
    });
  } catch (error) {
    console.error('Error GET /consent/access-logs:', error.message);
    res.status(500).json({ 
      error: 'internal_error', 
      message: 'Error obteniendo logs de acceso' 
    });
  }
});

/**
 * @route GET /api/consent/terms
 * @description Obtiene los terminos y condiciones actuales para consentimiento biometrico
 * @access Public
 * @returns {Object} Terminos y version
 */
router.get('/terms', async (req, res) => {
  try {
    // En produccion, estos terminos vendrian de una tabla o archivo de configuracion
    const terms = {
      version: '1.0',
      last_updated: '2026-08-05',
      title: 'Consentimiento para Tratamiento de Datos Biometricos - GlowApp',
      sections: [
        {
          title: '1. Finalidad del Tratamiento',
          content: 'Los datos biometricos (rostro, piel, cabello, medidas corporales) se utilizan exclusivamente para: analisis de tipo de piel, recomendacion de rutinas cosmeticas, prueba virtual de productos, y mejora de recomendaciones personalizadas.'
        },
        {
          title: '2. Datos Recopilados',
          content: 'Embeddings faciales vectoriales, caracteristicas de piel (tipo, hidratacion, tono), caracteristicas de cabello (tipo, color, textura), medidas corporales si aplica. NO se almacenan imagenes originales, solo representaciones matematicas (embeddings).'
        },
        {
          title: '3. Derechos del Titular (Ley 1581/2012)',
          content: 'Acceso: Consultar que datos se tienen sobre usted\nRectificacion: Corregir datos inexactos\nSupresion: Eliminar sus datos biometricos en cualquier momento (Art. 15)\nRevocatoria: Retirar consentimiento sin efecto retroactivo\nQueja: Ante la SIC si considera vulnerados sus derechos'
        },
        {
          title: '4. Retencion y Seguridad',
          content: 'Datos biometricos se retienen solo mientras el consentimiento este vigente. Al revocar, se eliminan en 24h. Cifrado AES-256 en reposo, TLS 1.3 en transito. Acceso solo por personal autorizado (ATENA, AURA).'
        },
        {
          title: '5. Transferencia Internacional',
          content: 'Embeddings pueden procesarse en servidores NVIDIA (EE.UU.) para inferencia. No se almacenan alli. Clausulas contractuales tipo aprobadas por la SIC.'
        }
      ]
    };
    
    res.json({
      success: true,
      data: terms
    });
  } catch (error) {
    console.error('Error GET /consent/terms:', error.message);
    res.status(500).json({ 
      error: 'internal_error', 
      message: 'Error obteniendo terminos' 
    });
  }
});

module.exports = router;
