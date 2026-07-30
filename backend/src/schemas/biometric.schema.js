// backend/src/schemas/biometric.schema.js
const { z } = require('zod');

/**
 * Zod Schema para la validación estricta de POST /api/biometric/analyze y /api/biometric/scan
 * Cumplimiento ADR-001 (Checklist Item 3): Validación Zod obligatoria en endpoints mutantes.
 */
const biometricAnalyzeSchema = z.object({
  faceImage: z.string().min(1, 'La imagen facial base64 es obligatoria'),
  handsImage: z.string().optional().nullable(),
  entryPoint: z.enum(['ideas', 'vto', 'scanner', 'other']).default('ideas'),
  lat: z.number().min(-90).max(90).optional().nullable(),
  lng: z.number().min(-180).max(180).optional().nullable(),
  consentToken: z.string().optional().nullable(),
});

/**
 * Zod Schema para la validación estricta de la consulta de perfil biométrico
 */
const biometricProfileParamSchema = z.object({
  userId: z.string().or(z.number()).transform((val) => String(val)),
});

module.exports = {
  biometricAnalyzeSchema,
  biometricProfileParamSchema,
};
