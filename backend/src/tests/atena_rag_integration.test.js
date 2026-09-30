// backend/src/tests/atena_rag_integration.test.js
const atenaAgent = require('../services/agents/atenaAgent');
const transformationEngine = require('../services/transformationEngine');

describe('GLOW IA+ — NODO 3: Atena & RAG Knowledge Integration (CONTRACT_04 & CONTRACT_06)', () => {
  test('1. generateRAGRationale responde con fallback seguro cuando RAG no está activo', async () => {
    const res = await atenaAgent.generateRAGRationale('hydration', ['Ácido Hialurónico', 'Ceramidas']);
    expect(res).toHaveProperty('hasRagEvidence');
    expect(res).toHaveProperty('ragReferences');
    expect(Array.isArray(res.ragReferences)).toBe(true);
    expect(res.rationale).toBeDefined();
  });

  test('2. generateTransformationPlan incluye las referencias RAG en CONTRACT_06', async () => {
    const plan = await transformationEngine.generateTransformationPlan({
      userId: 1,
      cycleType: 'skin',
      targetMetricKey: 'hydration',
      faceScores: { hydration: 45 }
    });

    expect(plan.success).toBe(true);
    expect(plan).toHaveProperty('ragReferences');
    expect(plan.planSummary).toContain('hydration');
  });
});
