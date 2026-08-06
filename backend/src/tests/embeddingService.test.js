/**
 * backend/src/tests/embeddingService.test.js
 * Tests unitarios para embeddingService.js
 */

const { 
  generateEmbedding, 
  generateNvidiaEmbedding, 
  generateBatchEmbeddings,
  generateDummyEmbedding,
  validateEmbeddingDimension,
  checkNvidiaAvailability,
  DEFAULT_CONFIG 
} = require('../services/embeddingService');

describe('embeddingService', () => {
  
  describe('generateDummyEmbedding', () => {
    test('debe generar embedding determinístico de 1024 dimensiones', () => {
      const embedding = generateDummyEmbedding('texto de prueba');
      
      expect(embedding).toHaveLength(1024);
      expect(Array.isArray(embedding)).toBe(true);
      
      // Verificar normalización (norma = 1)
      const norm = Math.sqrt(embedding.reduce((sum, v) => sum + v * v, 0));
      expect(norm).toBeCloseTo(1, 5);
    });
    
    test('debe ser determinista (mismo input = mismo output)', () => {
      const emb1 = generateDummyEmbedding('texto idéntico');
      const emb2 = generateDummyEmbedding('texto idéntico');
      
      expect(emb1).toEqual(emb2);
    });
    
    test('debe generar embeddings diferentes para textos diferentes', () => {
      const emb1 = generateDummyEmbedding('texto uno');
      const emb2 = generateDummyEmbedding('texto dos');
      
      expect(emb1).not.toEqual(emb2);
    });
    
    test('debe manejar string vacío', () => {
      const embedding = generateDummyEmbedding('');
      expect(embedding).toHaveLength(1024);
    });
  });
  
  describe('validateEmbeddingDimension', () => {
    test('debe validar embedding de 1024 dimensiones', () => {
      const embedding = new Array(1024).fill(0.01);
      expect(() => validateEmbeddingDimension(embedding, 1024)).not.toThrow();
    });
    
    test('debe rechazar embedding con dimensión incorrecta', () => {
      const embedding = new Array(768).fill(0.01);
      
      expect(() => validateEmbeddingDimension(embedding, 1024))
        .toThrow('Dimensión embedding incorrecta: esperado 1024, recibido 768');
    });
    
    test('debe rechazar embedding no array', () => {
      expect(() => validateEmbeddingDimension('no es array', 1024))
        .toThrow('Embedding no es un array');
    });
    
    test('debe advertir sobre embedding de ceros', () => {
      const consoleSpy = jest.spyOn(console, 'warn').mockImplementation();
      const embedding = new Array(1024).fill(0);
      
      validateEmbeddingDimension(embedding, 1024);
      
      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining('Embedding consiste solo de ceros')
      );
      consoleSpy.mockRestore();
    });
  });
  
  describe('DEFAULT_CONFIG', () => {
    test('debe tener configuración por defecto correcta', () => {
      expect(DEFAULT_CONFIG.expectedDimension).toBe(1024);
      expect(DEFAULT_CONFIG.timeout).toBe(15000);
      expect(DEFAULT_CONFIG.maxRetries).toBe(3);
      expect(DEFAULT_CONFIG.baseDelayMs).toBe(1000);
      expect(DEFAULT_CONFIG.maxDelayMs).toBe(10000);
      expect(DEFAULT_CONFIG.model).toBeDefined();
    });
  });
  
  describe('generateNvidiaEmbedding', () => {
    test('debe lanzar error si no hay API key', async () => {
      // Mock process.env sin API key
      const originalKey = process.env.NVIDIA_API_KEY;
      delete process.env.NVIDIA_API_KEY;
      
      await expect(generateNvidiaEmbedding('test'))
        .rejects.toThrow('NVIDIA_API_KEY no configurada');
      
      // Restaurar
      process.env.NVIDIA_API_KEY = originalKey;
    });
    
    // Los tests de integración real con NVIDIA requieren API key y red
    // Se omiten aquí pero se pueden ejecutar en CI con credenciales reales
  });
  
  describe('generateEmbedding (con circuit breaker)', () => {
    test('debe usar dummy embedding si circuit breaker está abierto', async () => {
      // Forzar contador local al máximo
      global.nvidiaEmbeddingFailureCount = 10;
      
      const embedding = await generateEmbedding('test');
      
      expect(embedding).toHaveLength(1024);
      
      // Limpiar
      global.nvidiaEmbeddingFailureCount = 0;
    });
    
    test('debe retornar embedding de 1024 dims', async () => {
      // Forzar fallback dummy
      global.nvidiaEmbeddingFailureCount = 10;
      
      const embedding = await generateEmbedding('test query');
      
      expect(embedding).toHaveLength(1024);
      
      global.nvidiaEmbeddingFailureCount = 0;
    });
  });
  
  describe('generateBatchEmbeddings', () => {
    test('debe procesar lote con rate limiting', async () => {
      // Forzar dummy embeddings
      global.nvidiaEmbeddingFailureCount = 10;
      
      const texts = ['texto 1', 'texto 2', 'texto 3'];
      const embeddings = await generateBatchEmbeddings(texts, 'passage', { 
        batchSize: 2, 
        delayMs: 10 
      });
      
      expect(embeddings).toHaveLength(3);
      embeddings.forEach(emb => {
        expect(emb).toHaveLength(1024);
      });
      
      global.nvidiaEmbeddingFailureCount = 0;
    });
  });
  
  describe('checkNvidiaAvailability', () => {
    test('debe retornar false si no hay API key', async () => {
      const originalKey = process.env.NVIDIA_API_KEY;
      delete process.env.NVIDIA_API_KEY;
      
      const available = await checkNvidiaAvailability();
      
      expect(available).toBe(false);
      
      process.env.NVIDIA_API_KEY = originalKey;
    });
  });
});