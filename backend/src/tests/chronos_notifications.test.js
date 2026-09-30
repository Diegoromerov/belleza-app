// backend/src/tests/chronos_notifications.test.js
const chronosNotificationService = require('../services/chronosNotificationService');

describe('GLOW IA+ — FRONT 2: Chronos Push Notification Engine', () => {
  test('processCycleReminders evalúa ciclos sin lanzar errores y procesa notificaciones simulated', async () => {
    const result = await chronosNotificationService.processCycleReminders();
    expect(result).toHaveProperty('processed');
  });
});
