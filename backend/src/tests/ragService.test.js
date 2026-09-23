/**
 * Test suite para ragService (Retrieval vectorial NVIDIA + Fallback FTS PostgreSQL)
 * Rescatado y adaptado de codex/rag-aura-r1-r4
 *
 * Port R1-R4 (2026-09-22): el embedding de consulta se pide a embeddingService
 * (breaker NVIDIA incluido, sin dummy) y el tenantId viaja como parámetro ligado.
 */

process.env.NVIDIA_API_KEY = 'test-mock-nvidia-key';

jest.mock('../config/db', () => ({
  ragPool: { query: jest.fn() },
  pool: { query: jest.fn() },
}));

jest.mock('../services/embeddingService', () => ({
  generateNvidiaEmbedding: jest.fn(),
  generateEmbedding: jest.fn(),
}));

const { ragPool } = require('../config/db');
const { generateEmbedding } = require('../services/embeddingService');
const { searchBeautyKnowledge } = require('../services/ragService');

describe('ragService retrieval', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('uses a NVIDIA query embedding for pgvector retrieval', async () => {
    generateEmbedding.mockResolvedValue(new Array(1024).fill(0.1));
    ragPool.query.mockResolvedValue({
      rows: [
        { id: 1, title: 'Niacinamida', content: 'Info niacinamida', similarity: '0.83', metadata: {} },
      ],
    });

    const result = await searchBeautyKnowledge('niacinamida');
    expect(generateEmbedding).toHaveBeenCalledWith('niacinamida', 'query');
    expect(ragPool.query.mock.calls[0][0]).toContain('embedding <=>');
    expect(result[0].similarity).toBe(0.83);
  });

  test('uses PostgreSQL full-text search when NVIDIA fails; no vector query is made', async () => {
    generateEmbedding.mockRejectedValue(new Error('NVIDIA unavailable'));
    ragPool.query.mockResolvedValue({
      rows: [
        { id: 2, title: 'Retinol', content: 'Guía de uso', similarity: '0.5', metadata: {} },
      ],
    });

    const result = await searchBeautyKnowledge('retinol');
    expect(ragPool.query).toHaveBeenCalledTimes(1);
    expect(ragPool.query.mock.calls[0][0]).toContain('to_tsvector');
    expect(ragPool.query.mock.calls[0][0]).not.toContain('embedding <=>');
    expect(result[0].title).toBe('Retinol');
  });

  test('rejects embeddings with wrong dimensions and degrades to full-text', async () => {
    generateEmbedding.mockResolvedValue(new Array(768).fill(0.1));
    ragPool.query.mockResolvedValue({ rows: [] });

    await searchBeautyKnowledge('acido hialuronico');

    expect(ragPool.query.mock.calls[0][0]).toContain('to_tsvector');
  });

  test('binds tenantId as a query parameter and never interpolates it (BUS-RAG-001)', async () => {
    const maliciousTenantId = "10') OR TRUE --";
    generateEmbedding.mockResolvedValue(new Array(1024).fill(0.1));
    ragPool.query.mockResolvedValue({ rows: [] });

    await searchBeautyKnowledge('consulta', { tenantId: maliciousTenantId });

    const [sql, params] = ragPool.query.mock.calls[0];

    // El payload no puede aparecer en el SQL y el predicado va parametrizado
    expect(sql).not.toContain('OR TRUE');
    expect(sql).not.toContain(maliciousTenantId);
    expect(sql).toContain('tenant_id::text = $2');

    // Y el tenant es un parámetro ligado, con el threshold/limit desplazados
    expect(params[1]).toBe(maliciousTenantId);
    expect(params[2]).toBe(0.45);
    expect(params[3]).toBe(5);
  });

  test('without tenantId only GLOBAL knowledge is searched (tenant_id IS NULL)', async () => {
    generateEmbedding.mockResolvedValue(new Array(1024).fill(0.1));
    ragPool.query.mockResolvedValue({ rows: [] });

    await searchBeautyKnowledge('consulta');

    const [sql, params] = ragPool.query.mock.calls[0];

    expect(sql).toContain('tenant_id IS NULL');
    expect(sql).not.toContain('tenant_id::text =');
    expect(params).toHaveLength(3); // embedding + threshold + topK
  });

  test('keeps the tenant isolation in the full-text fallback too', async () => {
    const maliciousTenantId = "10') OR TRUE --";
    generateEmbedding.mockRejectedValue(new Error('NVIDIA unavailable'));
    ragPool.query.mockResolvedValue({ rows: [] });

    await searchBeautyKnowledge('consulta', {
      tenantId: maliciousTenantId,
      filters: { category: 'skincare' },
    });

    const [sql, params] = ragPool.query.mock.calls[0];

    expect(sql).toContain('to_tsvector');
    expect(sql).not.toContain('OR TRUE');
    // $1=query, $2=patrón, $3=LIMIT, $4=category, $5=tenantId
    expect(sql).toContain('category = $4');
    expect(sql).toContain('tenant_id::text = $5');
    expect(params[4]).toBe(maliciousTenantId);
  });
});
