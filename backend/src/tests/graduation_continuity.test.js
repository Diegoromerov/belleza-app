// backend/src/tests/graduation_continuity.test.js
const glowCycleService = require('../services/glowCycleService');

describe('GLOW IA+ — NODO 4: Graduation & Continuity Contract (CONTRACT_12)', () => {

  describe('1. recommendNextGlowCycle', () => {
    test('Tras graduar un ciclo de hydration, recomienda el ciclo de pores', () => {
      const rec = glowCycleService.recommendNextGlowCycle('hydration', 25);
      expect(rec.suggestedMetricKey).toBe('pores');
      expect(rec.reasoning).toContain('Hidratación consolidada');
    });

    test('Tras graduar un ciclo de pores, recomienda el ciclo de wrinkles', () => {
      const rec = glowCycleService.recommendNextGlowCycle('pores', 15);
      expect(rec.suggestedMetricKey).toBe('wrinkles');
      expect(rec.reasoning).toContain('firmeza');
    });

    test('Para cualquier otra métrica graduada, recomienda mantenimiento hidratante', () => {
      const rec = glowCycleService.recommendNextGlowCycle('wrinkles', 10);
      expect(rec.suggestedMetricKey).toBe('hydration');
      expect(rec.suggestedGoal).toContain('Mantenimiento');
    });
  });
});
