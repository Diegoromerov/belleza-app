/**
 * backend/src/tests/ragSota.test.js
 * Suite de Pruebas Unitarias para las 5 Innovaciones SOTA (Grado S) de Aura RAG:
 *   1. HyDE (Hypothetical Document Embeddings) & Multi-Query Expansion
 *   2. Compresión Contextual y Destilación de Prompts
 *   3. Grafo de Conocimiento Multi-Salto (Multi-Hop GraphRAG)
 *   4. Integración Multimodal Vision-RAG (YouCam Skin Metrics Mapper)
 *   5. Bucle de Auto-Corrección RLHF (Feedback Signals)
 */

const {
  generateHyDEQuery,
  compressKnowledgeContext,
  mapVisionScanToFilters,
  recordRagFeedback,
  queryMultiHopKnowledgeGraph,
} = require('../services/ragSotaService');

const { pool, ragPool } = require('../config/db');

jest.mock('../config/db', () => ({
  pool: { query: jest.fn() },
  ragPool: { query: jest.fn() },
}));

describe('Aura RAG — Suite de Innovación SOTA (Grado S)', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('1. HyDE (Hypothetical Document Embeddings)', () => {
    test('expande consultas cortas o ambiguas ("me arde la piel") agregando contexto técnico hipotético', () => {
      const hyde = generateHyDEQuery('me arde la piel');
      expect(hyde).toContain('[Contexto Hipotético HyDE:');
      expect(hyde).toContain('Eritema cutáneo');
    });

    test('expande consultas sobre tinte con contexto de colorimetría y alcalinización', () => {
      const hyde = generateHyDEQuery('tinte capilar');
      expect(hyde).toContain('Colorimetría capilar fondo de aclaración');
    });

    test('no altera consultas largas (>6 palabras) que ya son técnicamente descriptivas', () => {
      const longQuery = 'Protocolo técnico de aplicación de ácido glicólico al 10% en fototipo III';
      const hyde = generateHyDEQuery(longQuery);
      expect(hyde).toBe(longQuery);
    });
  });

  describe('2. Compresión Contextual y Destilación de Prompts', () => {
    test('comprime contenido de chunks eliminando oraciones irrelevantes y conservando datos clínicos y cuantitativos', () => {
      const chunks = [
        {
          title: 'Protocolo Peeling',
          content: 'Bienvenido al manual del centro. El ácido glicólico requiere un pH entre 3.0 y 3.5 para conservar una fracción libre eficaz. Para más información consulte al administrador de la sede.',
        },
      ];

      const compressed = compressKnowledgeContext(chunks, 'ácido glicólico pH');
      expect(compressed[0].compressed).toBe(true);
      expect(compressed[0].content).toContain('ácido glicólico requiere un pH entre 3.0 y 3.5');
      expect(compressed[0].content).not.toContain('Bienvenido al manual del centro');
    });
  });

  describe('3. Grafo de Conocimiento Multi-Salto (Multi-Hop GraphRAG)', () => {
    test('ejecuta consulta de 2 saltos en rag_entities y rag_relations', async () => {
      const mockResult = {
        rows: [
          {
            entity_start: 'Ácido Salicílico',
            relation_1: 'causa',
            entity_mid: 'Adelgazamiento Estrato Córneo',
            relation_2: 'aumenta_fotosensibilidad',
            entity_end: 'Luz Solar UV',
          },
        ],
      };
      pool.query.mockResolvedValue(mockResult);
      if (ragPool) ragPool.query.mockResolvedValue(mockResult);

      const multiHop = await queryMultiHopKnowledgeGraph('Ácido Salicílico');
      expect(multiHop).toHaveLength(1);
      expect(multiHop[0].entity_start).toBe('Ácido Salicílico');
      expect(multiHop[0].entity_end).toBe('Luz Solar UV');
    });
  });

  describe('4. Integración Multimodal Vision-RAG (YouCam Skin Metrics Mapper)', () => {
    test('mapea métricas de escáner facial con eritema > 60 a filtros de piel sensible y prioridad antiinflamatoria', () => {
      const mapped = mapVisionScanToFilters({ erythema_score: 75, hydration_score: 50 });
      expect(mapped.filters.skin_type).toBe('sensible');
      expect(mapped.priorities).toContain('descongestion_antiinflamatoria');
    });

    test('mapea sebo > 65 a piel grasa y prioridad regulación sebácea', () => {
      const mapped = mapVisionScanToFilters({ sebum_score: 80 });
      expect(mapped.filters.skin_type).toBe('grasa');
      expect(mapped.priorities).toContain('regulacion_sebasea_acne');
    });

    test('mapea índice de pigmentación > 50 a categoría contraindicaciones y prioridad despigmentación', () => {
      const mapped = mapVisionScanToFilters({ pigmentation_index: 60 });
      expect(mapped.filters.category).toBe('ingredientes_activos_contraindicaciones');
      expect(mapped.priorities).toContain('despigmentacion_melasma');
    });
  });

  describe('5. Bucle de Auto-Corrección y Re-Calibración RLHF (Feedback Signals)', () => {
    test('registra valoración de retroalimentación en rag_feedback_signals', async () => {
      pool.query.mockResolvedValue({
        rows: [{ id: 1, rating: 1, feedback_type: 'clinical_accuracy' }],
      });

      const res = await recordRagFeedback({
        traceId: 'trace-123',
        userIdHash: 'hash-user',
        queryText: 'peeling acido salicilico',
        rating: 1,
        feedbackType: 'clinical_accuracy',
        notes: 'Respuesta excelente con dosis adecuada',
      });

      expect(res.success).toBe(true);
      expect(res.record.rating).toBe(1);
      expect(res.record.feedback_type).toBe('clinical_accuracy');
    });
  });
});
