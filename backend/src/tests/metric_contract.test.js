// backend/src/tests/metric_contract.test.js
const {
  METRIC_DEFINITIONS,
  getMetricDefinition,
  calculateSemanticDelta,
  isGoalReached,
  normalizeMeasurement
} = require('../services/glowContracts');

describe('GLOW IA+ — NODO 1: Metric & Measurement Contracts (CONTRACT_01, CONTRACT_02, CONTRACT_03)', () => {

  describe('1. CONTRACT_01 — Metric Definitions & Semantic Delta', () => {
    test('DECREASE_IS_BETTER: Pores (50 -> 35) representa una mejora positiva (+15)', () => {
      const delta = calculateSemanticDelta('pores', 50, 35);
      expect(delta).toBe(15);
    });

    test('DECREASE_IS_BETTER: Wrinkles (40 -> 25) representa una mejora positiva (+15)', () => {
      const delta = calculateSemanticDelta('wrinkles', 40, 25);
      expect(delta).toBe(15);
    });

    test('DECREASE_IS_BETTER: Pores empeoramiento (35 -> 50) representa delta negativo (-15)', () => {
      const delta = calculateSemanticDelta('pores', 35, 50);
      expect(delta).toBe(-15);
    });

    test('INCREASE_IS_BETTER: Hydration (50 -> 65) representa una mejora positiva (+15)', () => {
      const delta = calculateSemanticDelta('hydration', 50, 65);
      expect(delta).toBe(15);
    });

    test('INCREASE_IS_BETTER: Hydration empeoramiento (65 -> 50) representa delta negativo (-15)', () => {
      const delta = calculateSemanticDelta('hydration', 65, 50);
      expect(delta).toBe(-15);
    });
  });

  describe('2. CONTRACT_01 — Target Goal Evaluation (isGoalReached)', () => {
    test('DECREASE_IS_BETTER: Pores (actual 30, target 35) alcanza el objetivo (30 <= 35)', () => {
      const reached = isGoalReached('pores', 30, 35);
      expect(reached).toBe(true);
    });

    test('DECREASE_IS_BETTER: Pores (actual 40, target 35) NO alcanza el objetivo', () => {
      const reached = isGoalReached('pores', 40, 35);
      expect(reached).toBe(false);
    });

    test('INCREASE_IS_BETTER: Hydration (actual 75, target 70) alcanza el objetivo (75 >= 70)', () => {
      const reached = isGoalReached('hydration', 75, 70);
      expect(reached).toBe(true);
    });

    test('INCREASE_IS_BETTER: Hydration (actual 65, target 70) NO alcanza el objetivo', () => {
      const reached = isGoalReached('hydration', 65, 70);
      expect(reached).toBe(false);
    });
  });

  describe('3. CONTRACT_02 & CONTRACT_03 — Measurement Normalization & Provenance', () => {
    test('normalizeMeasurement asigna la zona horaria local de Bogotá y conserva provenance', () => {
      const rawScores = { Hydration: 65, Pores: '40' };
      const provenance = { source: 'YOUCAM', analysisId: 'test_ana_123', qualityScore: 0.95 };

      const norm = normalizeMeasurement(rawScores, provenance);

      expect(norm.scores.hydration).toBe(65);
      expect(norm.scores.pores).toBe(40);
      expect(norm.provenance.source).toBe('YOUCAM');
      expect(norm.provenance.analysisId).toBe('test_ana_123');
      expect(norm.provenance.confidenceLevel).toBe('HIGH');
      expect(norm.provenance.localDate).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    });
  });
});
