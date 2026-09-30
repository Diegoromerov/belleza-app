// backend/src/services/chronosNotificationService.js
const { pool } = require('../config/db');
const chronosAgent = require('./agents/chronosAgent');
const fcmNotificationService = require('./fcmNotificationService');
const logger = require('../config/logger');

class ChronosNotificationService {
  /**
   * Procesa ciclos activos para enviar notificaciones push dinámicas según el estado temporal en Bogotá
   */
  async processCycleReminders() {
    logger.info('🔔 [CHRONOS Notification] Evaluando recordatorios de Glow Cycle en tiempo local');

    const query = `
      SELECT gc.*, u.fcm_token as device_token
      FROM glow_cycles gc
      JOIN users u ON gc.user_id = u.id
      WHERE gc.status IN ('active', 'reassessment_due');
    `;

    try {
      const res = await pool.query(query);
      if (res.rows.length === 0) {
        logger.info('🔔 [CHRONOS Notification] No hay ciclos activos que requieran notificación.');
        return { processed: 0 };
      }

      let sentCount = 0;
      for (const cycle of res.rows) {
        const evaluation = chronosAgent.evaluateCycleContinuity(cycle);
        const deviceToken = cycle.device_token || 'MOCK_TOKEN';

        if (evaluation.temporalState === 'DAY_15_RESCAN_DUE') {
          await fcmNotificationService.sendGlowCyclePushNotification(deviceToken, {
            cycleId: cycle.id,
            reminderType: 'RESCAN_DUE',
            title: '📸 ¡Tu Hito del Día 15 está listo!',
            body: evaluation.reminderMessage
          });
          sentCount++;
        } else if (evaluation.temporalState === 'IN_PROGRESS_AM_PM' && !evaluation.isTodayCheckinCompleted) {
          const reminderType = evaluation.isAmCompleted ? 'ROUTINE_PM' : 'ROUTINE_AM';
          const title = reminderType === 'ROUTINE_PM' ? '🌙 Rutina de Noche Pendiente' : '🌅 Rutina de Mañana Pendiente';
          const body = reminderType === 'ROUTINE_PM'
            ? 'No olvides completar tu paso de noche para mantener tu adherencia alta.'
            : 'Comienza tu día completando tu rutina de mañana Glow IA+.';

          await fcmNotificationService.sendGlowCyclePushNotification(deviceToken, {
            cycleId: cycle.id,
            reminderType,
            title,
            body
          });
          sentCount++;
        }
      }

      return { success: true, processed: res.rows.length, notificationsSent: sentCount };
    } catch (err) {
      logger.warn('⚠️ [CHRONOS Notification] Notificación degradada (BD no disponible o sin registros):', err.message);
      return { success: true, processed: 0, notificationsSent: 0 };
    }
  }
}

module.exports = new ChronosNotificationService();
