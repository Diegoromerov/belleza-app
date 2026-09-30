// backend/src/tests/transformation_engine.test.js
const transformationEngine = require('../services/transformationEngine');

describe('GLOW IA+ — NODO 2: Transformation Engine Refactor (CONTRACT_08, CONTRACT_09, CONTRACT_10)', () => {
  const samplePlan = {
    amRoutine: [
      { step: 1, action: 'Limpiador Suave', time: '08:00' },
      { step: 2, action: 'Sérum Exfoliante', time: '08:15' }
    ],
    pmRoutine: [
      { step: 1, action: 'Limpiador Nocturno', time: '20:00' }
    ]
  };

  test('1. Medición no confiable (qualityScore < 0.50): debe retornar unreliable_measurement_warning', () => {
    const res = transformationEngine.adaptPlanBasedOnDelta({
      currentPlan: samplePlan,
      delta: 10,
      metricKey: 'hydration',
      currentValue: 60,
      targetValue: 75,
      adherenceRate: 0.90,
      qualityScore: 0.35
    });

    expect(res.adaptationType).toBe('unreliable_measurement_warning');
    expect(res.amRoutine).toHaveLength(2);
    expect(res.pmRoutine).toHaveLength(1);
  });

  test('2. Objetivo alcanzado: debe retornar completed', () => {
    const res = transformationEngine.adaptPlanBasedOnDelta({
      currentPlan: samplePlan,
      delta: 25,
      metricKey: 'hydration',
      currentValue: 75,
      targetValue: 75,
      adherenceRate: 0.85
    });

    expect(res.adaptationType).toBe('completed');
    expect(res.isGoalReached).toBe(true);
  });

  test('3. Delta positivo + Alta adherencia (>= 0.70): debe retornar maintain', () => {
    const res = transformationEngine.adaptPlanBasedOnDelta({
      currentPlan: samplePlan,
      delta: 10,
      metricKey: 'hydration',
      currentValue: 60,
      targetValue: 75,
      adherenceRate: 0.85
    });

    expect(res.adaptationType).toBe('maintain');
    expect(res.adaptationReason).toContain('alta adherencia');
  });

  test('4. Delta positivo + Baja adherencia (< 0.70): debe retornar maintain_with_habit_warning', () => {
    const res = transformationEngine.adaptPlanBasedOnDelta({
      currentPlan: samplePlan,
      delta: 10,
      metricKey: 'hydration',
      currentValue: 60,
      targetValue: 75,
      adherenceRate: 0.40
    });

    expect(res.adaptationType).toBe('maintain_with_habit_warning');
    expect(res.adaptationReason).toContain('adherencia es baja');
  });

  test('5. Sin progreso (delta <= 0) + Baja adherencia (< 0.70): debe retornar reinforce_adherence', () => {
    const res = transformationEngine.adaptPlanBasedOnDelta({
      currentPlan: samplePlan,
      delta: 0,
      metricKey: 'hydration',
      currentValue: 50,
      targetValue: 75,
      adherenceRate: 0.30
    });

    expect(res.adaptationType).toBe('reinforce_adherence');
    expect(res.adaptationReason).toContain('baja adherencia');
  });

  test('6. Sin progreso (delta = 0) + Alta adherencia (>= 0.70): debe retornar intensify e incluir booster en PM', () => {
    const res = transformationEngine.adaptPlanBasedOnDelta({
      currentPlan: samplePlan,
      delta: 0,
      metricKey: 'hydration',
      currentValue: 50,
      targetValue: 75,
      adherenceRate: 0.90
    });

    expect(res.adaptationType).toBe('intensify');
    expect(res.pmRoutine.length).toBe(samplePlan.pmRoutine.length + 1);
    expect(res.pmRoutine[res.pmRoutine.length - 1].action).toContain('Mascarilla Reparadora');
  });

  test('7. Variación negativa (-10) + Alta adherencia (>= 0.70): debe retornar modify y sustituir exfoliante', () => {
    const res = transformationEngine.adaptPlanBasedOnDelta({
      currentPlan: samplePlan,
      delta: -10,
      metricKey: 'hydration',
      currentValue: 40,
      targetValue: 75,
      adherenceRate: 0.95
    });

    expect(res.adaptationType).toBe('modify');
    expect(res.amRoutine[1].action).toContain('Limpiador Ultra-Suave');
  });
});
