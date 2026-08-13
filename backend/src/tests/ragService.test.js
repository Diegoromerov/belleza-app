jest.mock('../config/db', () => ({ ragPool: { query: jest.fn() } }));
jest.mock('../services/embeddingService', () => ({ generateNvidiaEmbedding: jest.fn() }));

const { ragPool } = require('../config/db');
const { generateNvidiaEmbedding } = require('../services/embeddingService');
const { searchBeautyKnowledge } = require('../services/ragService');

describe('ragService retrieval', () => {
  beforeEach(() => jest.clearAllMocks());

  test('uses a NVIDIA query embedding for pgvector retrieval', async () => {
    generateNvidiaEmbedding.mockResolvedValue(new Array(1024).fill(0.1));
    ragPool.query.mockResolvedValue({ rows: [{ id: 1, similarity: '0.83', document_id: 'doc', chunk_id: 'chunk' }] });
    const result = await searchBeautyKnowledge('niacinamida');
    expect(generateNvidiaEmbedding).toHaveBeenCalledWith('niacinamida', 'query');
    expect(ragPool.query.mock.calls[0][0]).toContain('embedding <=>');
    expect(result[0].similarity).toBe(0.83);
  });

  test('uses PostgreSQL full-text search when NVIDIA fails; no vector query is made', async () => {
    generateNvidiaEmbedding.mockRejectedValue(new Error('NVIDIA unavailable'));
    ragPool.query.mockResolvedValue({ rows: [{ id: 2, fuente: 'guide.md', seccion: 'Uso' }] });
    const result = await searchBeautyKnowledge('retinol');
    expect(ragPool.query).toHaveBeenCalledTimes(1);
    expect(ragPool.query.mock.calls[0][0]).toContain('to_tsvector');
    expect(ragPool.query.mock.calls[0][0]).not.toContain('embedding <=>');
    expect(result).toEqual([{ id: 2, fuente: 'guide.md', seccion: 'Uso' }]);
  });
});
