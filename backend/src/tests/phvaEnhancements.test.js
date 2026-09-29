/**
 * backend/src/tests/phvaEnhancements.test.js
 * Suite de Pruebas Unitarias para las Mejoras PHVA de Aura RAG:
 *   1. Diccionario de Sinónimos Dialectales Colombianos
 *   2. Umbral Adaptativo por Categoría
 *   3. Enriquecimiento de Consultas en searchBeautyKnowledge
 */

const {
  expandColombianBeautySynonyms,
  getAdaptiveThreshold,
} = require('../config/knowledgeCategories');
const { searchBeautyKnowledge } = require('../services/ragService');
const { generateEmbedding } = require('../services/embeddingService');
const { ragPool } = require('../config/db');

jest.mock('../services/embeddingService', () => ({
  generateEmbedding: jest.fn(),
}));

jest.mock('../config/db', () => ({
  ragPool: { query: jest.fn() },
  pool: { query: jest.fn() },
}));

describe('Aura RAG — Suite de Mejoras Continuas PHVA', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('1. Diccionario de Sinónimos Dialectales Colombianos', () => {
    test('enriquece términos populares como repolarización con jerga técnica', () => {
      const enriched = expandColombianBeautySynonyms('Necesito una repolarizacion capilar');
      expect(enriched).toContain('tratamiento lipidico capilar restaurador reestructurante');
    });

    test('enriquece término repitiendo tinte con mantenimiento pigmentario', () => {
      const enriched = expandColombianBeautySynonyms('Cliente repitiendo tinte en raíz');
      expect(enriched).toContain('mantenimiento pigmentario colorimetria capilar');
    });

    test('enriquece barboterapia con barbería e higiene dermo-facial', () => {
      const enriched = expandColombianBeautySynonyms('Servicio de barboterapia con toalla caliente');
      expect(enriched).toContain('barberia protocolo higienico barboterapia dermo-facial');
    });

    test('no altera consultas que no contengan modismos colombianos', () => {
      const original = 'Consulta sobre acido hialuronico';
      const enriched = expandColombianBeautySynonyms(original);
      expect(enriched).toBe(original);
    });
  });

  describe('2. Umbral Adaptativo por Categoría (Adaptive Thresholding)', () => {
    test('devuelve umbral estricto (0.35) para categorías críticas como contraindicaciones', () => {
      const threshold = getAdaptiveThreshold('ingredientes_activos_contraindicaciones');
      expect(threshold).toBe(0.35);
    });

    test('devuelve umbral relajado (0.25) para categorías creativas o virales', () => {
      const threshold = getAdaptiveThreshold('tendencias_belleza_virales');
      expect(threshold).toBe(0.25);
    });

    test('devuelve umbral por defecto (0.30) para categorías generales o no clasificadas', () => {
      const threshold = getAdaptiveThreshold('skincare_rutinas_por_tipo_piel');
      expect(threshold).toBe(0.30);
    });
  });

  describe('3. Integración en searchBeautyKnowledge', () => {
    test('searchBeautyKnowledge usa la consulta enriquecida y registra el umbral adaptativo en la traza', async () => {
      generateEmbedding.mockResolvedValue(new Array(2048).fill(0.1));
      ragPool.query.mockResolvedValue({ rows: [] });

      const trace = {};
      await searchBeautyKnowledge('repolarizacion para cabello maltratado', {
        filters: { category: 'ingredientes_activos_contraindicaciones' },
        trace,
      });

      expect(trace.enriched_query).toContain('tratamiento lipidico capilar restaurador reestructurante');
      expect(trace.threshold_used).toBe(0.35);
    });
  });
});
