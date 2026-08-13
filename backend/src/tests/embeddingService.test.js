const axios = require('axios');
process.env.NVIDIA_API_KEY = 'test-key';
const { generateEmbedding, validateEmbeddingDimension } = require('../services/embeddingService');

jest.mock('axios');

describe('embeddingService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('accepts only NVIDIA embeddings with 1024 dimensions', async () => {
    axios.post.mockResolvedValue({ data: { data: [{ embedding: new Array(1024).fill(0.1) }] } });
    await expect(generateEmbedding('consulta', 'query', { maxRetries: 1 })).resolves.toHaveLength(1024);
  });

  test('rejects a NVIDIA failure instead of returning a dummy embedding', async () => {
    axios.post.mockRejectedValue(new Error('NVIDIA unavailable'));
    await expect(generateEmbedding('consulta', 'query', { maxRetries: 1 })).rejects.toThrow('NVIDIA unavailable');
  });

  test('rejects an embedding with the wrong dimension', () => {
    expect(() => validateEmbeddingDimension([0.1], 1024)).toThrow('Dimensión embedding incorrecta');
  });
});
