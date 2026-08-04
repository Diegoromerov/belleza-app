// backend/src/routes/biometricRoutes.js
const express = require('express');
const router = express.Router();
const orchestrator = require('../services/biometric/orchestrator');
const profileService = require('../services/biometric/profile.service');
const { authMiddleware } = require('../middleware/auth');
const idempotencyMiddleware = require('../middleware/idempotency');
const biometricConsentGuard = require('../middleware/biometricConsentGuard');
const { biometricAnalyzeSchema, biometricProfileParamSchema } = require('../schemas/biometric.schema');

/**
 * POST /api/biometric/analyze
 * ADR-001 Compliance:
 * - Checklist Item 1: Guard de Consentimiento biométrico inmutable.
 * - Checklist Item 3: Validación Zod obligatoria en endpoints mutantes.
 * - Checklist Item 4: Eliminación de userId || 'guest' (Exigencia de JWT válido).
 * - Checklist Item 5: Header Idempotency-Key obligatorio.
 */
router.post('/analyze', authMiddleware, biometricConsentGuard, idempotencyMiddleware, async (req, res) => {
  const userId = req.user?.id;
  if (!userId) {
    return res.status(401).json({
      error: 'UNAUTHORIZED',
      message: 'Se requiere una sesión de usuario autenticada válida.',
    });
  }

  console.log(`📥 [BIOMETRIC] Request recibida en POST /analyze - IP: ${req.ip}, User ID JWT: ${userId}`);

  // Validación Zod de entrada
  const parseResult = biometricAnalyzeSchema.safeParse(req.body);
  if (!parseResult.success) {
    const errorDetails = parseResult.error.errors.map(e => e.message).join(', ');
    console.warn(`⚠️ [BIOMETRIC] Error de validación Zod en /analyze: ${errorDetails}`);
    return res.status(400).json({
      error: 'VALIDATION_ERROR',
      message: errorDetails,
      details: parseResult.error.format(),
    });
  }

  const { faceImage, handsImage, entryPoint, lat, lng } = parseResult.data;

  // Validar tamaño de payload base64 (máx 20MB por imagen)
  const faceSize = Buffer.from(faceImage, 'base64').length;
  const handsSize = handsImage ? Buffer.from(handsImage, 'base64').length : 0;

  if (faceSize > 20 * 1024 * 1024 || handsSize > 20 * 1024 * 1024) {
    return res.status(400).json({
      error: 'PAYLOAD_TOO_LARGE',
      message: 'Las imágenes no pueden superar el tamaño límite de 20MB por archivo.',
    });
  }

  try {
    const faceBuffer = Buffer.from(faceImage, 'base64');
    const handsBuffer = handsImage ? Buffer.from(handsImage, 'base64') : null;

    const result = await orchestrator.analyze(
      userId,
      faceBuffer,
      handsBuffer,
      entryPoint || 'ideas',
      lat,
      lng
    );

    res.status(201).json({
      success: true,
      profileId: result.profileId,
      results: {
        face: result.face,
        hands: result.hands,
        recommendation: result.recommendation,
        keyIngredients: result.keyIngredients,
        vtoTones: result.vtoTones,
      },
      createdAt: result.createdAt,
    });
  } catch (error) {
    console.error('❌ Error en el orquestador biométrico:', error.message);
    res.status(500).json({
      success: false,
      error: 'INTERNAL_ERROR',
      message: 'Error al procesar el análisis biométrico. Por favor intenta nuevamente.',
    });
  }
});

/**
 * GET /api/biometric/profile/:userId
 * ADR-001 Compliance: JWT estricto y validación de parámetros con Zod.
 */
router.get('/profile/:userId', authMiddleware, async (req, res) => {
  const parseResult = biometricProfileParamSchema.safeParse(req.params);
  if (!parseResult.success) {
    return res.status(400).json({ error: 'INVALID_USER_ID', message: 'El identificador de usuario es inválido.' });
  }

  const { userId } = parseResult.data;

  // Validar que el usuario solo consulte su propio perfil salvo permisos de admin
  if (req.user?.id !== userId && req.user?.role !== 'admin') {
    return res.status(403).json({ error: 'FORBIDDEN', message: 'No tienes permisos para acceder a este perfil.' });
  }

  try {
    const profile = await profileService.getProfile(parseInt(userId, 10));
    if (!profile) {
      return res.status(404).json({ error: 'NOT_FOUND', message: 'Perfil biométrico no encontrado.' });
    }
    res.json(profile);
  } catch (error) {
    console.error('❌ Error obteniendo perfil biométrico:', error.message);
    res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Error al obtener el perfil biométrico.' });
  }
});

/**
 * DELETE /api/biometric/profile/:userId
 * ADR-001 Compliance: Aplicación de Habeas Data / Derecho al Olvido bajo JWT.
 */
router.delete('/profile/:userId', authMiddleware, async (req, res) => {
  const parseResult = biometricProfileParamSchema.safeParse(req.params);
  if (!parseResult.success) {
    return res.status(400).json({ error: 'INVALID_USER_ID', message: 'El identificador de usuario es inválido.' });
  }

  const { userId } = parseResult.data;

  if (req.user?.id !== userId && req.user?.role !== 'admin') {
    return res.status(403).json({ error: 'FORBIDDEN', message: 'No tienes permisos para eliminar este perfil.' });
  }

  try {
    await profileService.deleteProfile(parseInt(userId, 10));
    res.json({ success: true, message: 'Perfil biométrico eliminado correctamente (Habeas Data aplicado).' });
  } catch (error) {
    console.error('❌ Error eliminando perfil biométrico:', error.message);
    res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Error al eliminar el perfil biométrico.' });
  }
});

module.exports = router;

