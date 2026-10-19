// backend/src/services/biometric/scanSession.service.js
//
// Y-F1: persistencia de la llamada completa a YouCam.
//
// Guarda el bloque de métricas cifrado (ADR-001: los scores derivados de una foto son
// datos biométricos) junto con los metadatos no identificatorios que permiten auditar
// qué se pidió y qué no volvió: provider_task_id, acciones pedidas, acciones ausentes
// y número de métricas.
//
// No lanza si la escritura falla cuando se le pide `tolerante: true` (el análisis ya
// se pagó; perder el registro no debe romper la respuesta al usuario), pero devuelve
// `persisted: false` y el motivo para que el llamador lo registre.

const { pool } = require('../../config/db');
const biometricCryptoService = require('../biometricCryptoService');
const logger = require('../../config/logger');

class ScanSessionService {
  /**
   * @param {Object} params
   * @param {number} params.userId
   * @param {Object} params.faceScores - Resultado completo de youcam.client.analyzeFace
   * @param {boolean} [params.tolerante] - Si true, no propaga el error de escritura
   * @returns {Promise<{persisted: boolean, id?: number, metricsCount: number, reason?: string}>}
   */
  async saveScan({ userId, faceScores, geometry = null, quality = null, tolerante = true }) {
    const metrics = faceScores?.metrics && typeof faceScores.metrics === 'object' ? faceScores.metrics : {};
    const metricsCount = Object.keys(metrics).length;

    if (!Number.isInteger(userId) || userId <= 0) {
      return { persisted: false, metricsCount, reason: 'userId inválido' };
    }
    if (metricsCount === 0) {
      return { persisted: false, metricsCount, reason: 'sin métricas para persistir' };
    }

    const payload = {
      version: 1,
      provider: 'youcam',
      providerTaskId: faceScores.providerTaskId || null,
      requestedActions: faceScores.requestedActions || [],
      missing: faceScores.missing || [],
      metrics,
      skinType: faceScores.skinType || null,
      skinAge: faceScores.skinAge || null,
      overall: faceScores.overall || null,
      legacy: {
        hydration: faceScores.hydration,
        wrinkles: faceScores.wrinkles,
        spots: faceScores.spots,
        pores: faceScores.pores,
        subtono: faceScores.subtono,
        bioAge: faceScores.bioAge,
      },
      masks: faceScores.masks || [],
    };

    const encrypted = biometricCryptoService.encrypt(payload);

    try {
      const result = await pool.query(
        `INSERT INTO biometric_scan_sessions
           (user_id, provider, provider_task_id, metrics_encrypted, metrics_count,
            requested_actions, missing_metrics, geometry, quality)
         VALUES ($1, 'youcam', $2, $3, $4, $5::jsonb, $6::jsonb, $7::jsonb, $8::jsonb)
         RETURNING id, captured_at`,
        [
          userId,
          payload.providerTaskId,
          encrypted,
          metricsCount,
          JSON.stringify(payload.requestedActions),
          JSON.stringify(payload.missing),
          geometry ? JSON.stringify(geometry) : null,
          quality ? JSON.stringify(quality) : null,
        ]
      );

      const row = result.rows[0];
      return { persisted: true, id: row.id, capturedAt: row.captured_at, metricsCount };
    } catch (error) {
      logger.error('No se pudo persistir la sesión de escaneo biométrico', {
        userId,
        metricsCount,
        error: error.message,
      });
      if (!tolerante) throw error;
      return { persisted: false, metricsCount, reason: error.message };
    }
  }

  /** Descifra una sesión guardada. Uso: verificación y fases de delta (Y-F3). */
  async getScan(id) {
    const result = await pool.query(
      `SELECT id, user_id, provider, provider_task_id, metrics_encrypted, metrics_count,
              requested_actions, missing_metrics, geometry, quality, captured_at
         FROM biometric_scan_sessions WHERE id = $1`,
      [id]
    );
    if (result.rows.length === 0) return null;

    const row = result.rows[0];
    return {
      id: row.id,
      userId: row.user_id,
      provider: row.provider,
      providerTaskId: row.provider_task_id,
      metricsCount: row.metrics_count,
      requestedActions: row.requested_actions,
      missing: row.missing_metrics,
      geometry: row.geometry,
      quality: row.quality,
      capturedAt: row.captured_at,
      payload: biometricCryptoService.decrypt(row.metrics_encrypted),
    };
  }
}

module.exports = new ScanSessionService();
