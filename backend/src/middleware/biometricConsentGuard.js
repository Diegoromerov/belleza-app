// backend/src/middleware/biometricConsentGuard.js
/**
 * Middleware Biometric Consent Guard (ADR-001 / GDPR Art. 6 & Ley 1581)
 * Verifica inmutablemente que el usuario autenticado posea un consentimiento biométrico activo y no revocado antes de procesar cualquier escaneo.
 */
const { pool } = require('../config/db');

const biometricConsentGuard = async (req, res, next) => {
  const userId = req.user?.id;

  if (!userId) {
    return res.status(401).json({
      error: 'UNAUTHORIZED',
      message: 'Se requiere autenticación para verificar la base legal biométrica.',
    });
  }

  try {
    const result = await pool.query(
      `SELECT id, version, accepted_at 
       FROM biometric_consents 
       WHERE user_id = $1 AND active = true 
       LIMIT 1`,
      [parseInt(userId, 10)]
    );

    if (result.rows.length === 0) {
      console.warn(`⛔ [CONSENT_GUARD] Bloqueada petición biométrica para usuario ${userId}: Sin consentimiento activo.`);
      return res.status(403).json({
        error: 'CONSENT_DENIED',
        code: 'MISSING_ACTIVE_CONSENT',
        message: 'No existe un consentimiento biométrico activo. Debe aceptar las políticas de tratamiento de datos antes de continuar.',
      });
    }

    // Inyectar consentimiento validado en la petición
    req.biometricConsent = result.rows[0];
    next();
  } catch (error) {
    console.error('❌ Error en biometricConsentGuard:', error.message);
    res.status(500).json({
      error: 'INTERNAL_ERROR',
      message: 'Error al verificar la validez legal del consentimiento biométrico.',
    });
  }
};

module.exports = biometricConsentGuard;
