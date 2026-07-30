// backend/src/routes/biometricConsentRoutes.js
const express = require('express');
const router = express.Router();
const { pool } = require('../config/db');
const authMiddleware = require('../middleware/auth');
const idempotencyMiddleware = require('../middleware/idempotency');

/**
 * POST /api/consent
 * ADR-001 Compliance:
 * - Checklist Item 1: Transaccionalidad atómica en biometric_consents (BEGIN/COMMIT/ROLLBACK).
 * - Checklist Item 5: Header Idempotency-Key obligatorio.
 */
router.post('/', authMiddleware, idempotencyMiddleware, async (req, res) => {
  const userId = req.user.id;
  const { version, accepted } = req.body;

  if (accepted !== true) {
    return res.status(400).json({
      error: 'VALIDATION_ERROR',
      message: 'Debe aceptar expresamente los términos de consentimiento biométrico para continuar.',
    });
  }

  const clientIP = req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress;
  const userAgent = req.headers['user-agent'] || 'Unknown';

  const client = await pool.connect();

  try {
    // Iniciar transacción atómica (Evita consentimientos huérfanos o en estado inconsistente)
    await client.query('BEGIN');

    // 1. Desactivar consentimientos anteriores del usuario
    await client.query(
      `UPDATE biometric_consents 
       SET active = false, revoked_at = NOW() 
       WHERE user_id = $1 AND active = true`,
      [parseInt(userId, 10)]
    );

    // 2. Insertar nuevo consentimiento activo
    const result = await client.query(
      `INSERT INTO biometric_consents (user_id, version, ip, user_agent, active) 
       VALUES ($1, $2, $3, $4, true) 
       RETURNING id, version, accepted_at`,
      [parseInt(userId, 10), version || '1.0', clientIP, userAgent]
    );

    // Confirmar transacción
    await client.query('COMMIT');

    res.status(201).json({
      success: true,
      consentId: result.rows[0].id,
      version: result.rows[0].version,
      acceptedAt: result.rows[0].accepted_at,
    });
  } catch (error) {
    // Revertir transacción en caso de fallo
    await client.query('ROLLBACK');
    console.error('❌ Error guardando consentimiento biométrico:', error.message);
    res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Error interno al registrar el consentimiento legal.' });
  } finally {
    client.release();
  }
});

/**
 * POST /api/consent/revoke
 * ADR-001 Compliance: Transaccionalidad atómica e idempotencia.
 */
router.post('/revoke', authMiddleware, idempotencyMiddleware, async (req, res) => {
  const userId = req.user.id;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const result = await client.query(
      `UPDATE biometric_consents 
       SET active = false, revoked_at = NOW() 
       WHERE user_id = $1 AND active = true 
       RETURNING id`,
      [parseInt(userId, 10)]
    );

    await client.query('COMMIT');

    res.json({
      success: true,
      message: 'Consentimiento revocado con éxito.',
      revoked: result.rowCount > 0,
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Error revocando consentimiento biométrico:', error.message);
    res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Error interno al revocar el consentimiento.' });
  } finally {
    client.release();
  }
});

/**
 * GET /api/consent/status/:userId
 * ADR-001 Compliance: Verificación de consentimiento inmutable bajo JWT.
 */
router.get('/status/:userId', authMiddleware, async (req, res) => {
  const { userId } = req.params;

  if (req.user?.id !== String(userId) && req.user?.role !== 'admin') {
    return res.status(403).json({ error: 'FORBIDDEN', message: 'No tienes permisos para consultar este estado de consentimiento.' });
  }

  try {
    const result = await pool.query(
      `SELECT id, version, accepted_at 
       FROM biometric_consents 
       WHERE user_id = $1 AND active = true 
       LIMIT 1`,
      [parseInt(userId, 10)]
    );

    if (result.rows.length > 0) {
      res.json({
        success: true,
        hasActiveConsent: true,
        version: result.rows[0].version,
        acceptedAt: result.rows[0].accepted_at,
      });
    } else {
      res.json({
        success: true,
        hasActiveConsent: false,
      });
    }
  } catch (error) {
    console.error('❌ Error consultando estado del consentimiento biométrico:', error.message);
    res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Error interno al verificar el estado del consentimiento.' });
  }
});

module.exports = router;

