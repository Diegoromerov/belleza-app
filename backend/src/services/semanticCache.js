/**
 * backend/src/services/semanticCache.js
 * Cache semántico para embeddings y respuestas RAG
 * Usa similitud coseno entre embeddings para detectar queries equivalentes
 * Ahorro estimado: 30-40% tokens LLM + latencia
 */

const { getRedisClient } = require('../middleware/rateLimiter');

const SEMANTIC_CACHE_TTL = 24 * 60 * 60; // 24 horas
const SIMILARITY_THRESHOLD = 0.92; // Umbral para considerar queries equivalentes
const MAX_CACHE_SIZE = 10000; // Límite de entradas en cache

/**
 * Calcula similitud coseno entre dos vectores
 * @param {number[]} a - Vector A
 * @param {number[]} b - Vector B
 * @returns {number} Similitud coseno (0-1)
 */
function cosineSimilarity(a, b) {
  if (!a || !b || a.length !== b.length) return 0;
  
  let dotProduct = 0;
  let normA = 0;
  let normB = 0;
  
  for (let i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  
  if (normA === 0 || normB === 0) return 0;
  return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
}

/**
 * Genera clave de cache determinista para embedding
 * @param {number[]} embedding - Vector de embedding
 * @returns {string} Clave de cache
 */
function generateCacheKey(embedding) {
  // Usar hash de los primeros 32 valores (suficiente para unicidad)
  const sample = embedding.slice(0, 32).map(v => Math.round(v * 10000)).join(',');
  const crypto = require('crypto');
  return crypto.createHash('sha256').update(sample).digest('hex').substring(0, 32);
}

/**
 * Busca en cache semántico por similitud de embedding
 * @param {number[]} queryEmbedding - Embedding de la query
 * @returns {Promise<Object|null>} Entrada de cache o null
 */
async function findSimilarInCache(queryEmbedding) {
  const redis = await getRedisClient();
  if (!redis) return null;
  
  try {
    const cacheKey = `semantic:${generateCacheKey(queryEmbedding)}`;
    const cached = await redis.get(cacheKey);
    
    if (cached) {
      const entry = JSON.parse(cached);
      // Verificar similitud real (por si hash colisiona)
      const similarity = cosineSimilarity(queryEmbedding, entry.embedding);
      if (similarity >= SIMILARITY_THRESHOLD) {
        console.log(`🎯 Cache semántico HIT (similitud: ${similarity.toFixed(4)})`);
        return entry;
      }
    }
    
    // Buscar en índice de claves si no hay match exacto por hash
    // Estrategia: mantener índice de embeddings recientes para búsqueda aproximada
    const indexKey = 'semantic:index';
    const indexedKeys = await redis.lRange(indexKey, 0, 99); // Últimos 100
    
    for (const key of indexedKeys) {
      const entryData = await redis.get(`semantic:${key}`);
      if (entryData) {
        const entry = JSON.parse(entryData);
        const similarity = cosineSimilarity(queryEmbedding, entry.embedding);
        if (similarity >= SIMILARITY_THRESHOLD) {
          console.log(`🎯 Cache semántico HIT por búsqueda (similitud: ${similarity.toFixed(4)})`);
          // Mover al frente del índice (LRU)
          await redis.lRem(indexKey, 1, key);
          await redis.lPush(indexKey, key);
          return entry;
        }
      }
    }
    
    return null;
  } catch (error) {
    console.warn('⚠️ Error en cache semántico:', error.message);
    return null;
  }
}

/**
 * Guarda respuesta en cache semántico
 * @param {number[]} queryEmbedding - Embedding de la query
 * @param {Object} response - Respuesta a cachear
 * @param {Object} metadata - Metadata adicional (chunks, tools, etc.)
 * @returns {Promise<void>}
 */
async function setCache(queryEmbedding, response, metadata = {}) {
  const redis = await getRedisClient();
  if (!redis) return;
  
  try {
    const cacheKey = generateCacheKey(queryEmbedding);
    const fullKey = `semantic:${cacheKey}`;
    
    const entry = {
      embedding: queryEmbedding,
      response,
      metadata,
      timestamp: Date.now(),
      hits: 0,
    };
    
    // Guardar entrada
    await redis.setEx(fullKey, SEMANTIC_CACHE_TTL, JSON.stringify(entry));
    
    // Actualizar índice LRU
    const indexKey = 'semantic:index';
    await redis.lRem(indexKey, 1, cacheKey);
    await redis.lPush(indexKey, cacheKey);
    await redis.lTrim(indexKey, 0, MAX_CACHE_SIZE - 1);
    
    console.log(`💾 Cache semántico guardado: ${cacheKey}`);
  } catch (error) {
    console.warn('⚠️ Error guardando en cache semántico:', error.message);
  }
}

/**
 * Incrementa contador de hits de una entrada
 * @param {string} cacheKey - Clave de cache
 * @returns {Promise<void>}
 */
async function incrementHits(cacheKey) {
  const redis = await getRedisClient();
  if (!redis) return;
  
  try {
    const fullKey = `semantic:${cacheKey}`;
    const cached = await redis.get(fullKey);
    if (cached) {
      const entry = JSON.parse(cached);
      entry.hits += 1;
      await redis.setEx(fullKey, SEMANTIC_CACHE_TTL, JSON.stringify(entry));
    }
  } catch (error) {
    // Silencioso
  }
}

/**
 * Obtiene estadísticas del cache semántico
 * @returns {Promise<Object>} Stats del cache
 */
async function getCacheStats() {
  const redis = await getRedisClient();
  if (!redis) return { available: false };
  
  try {
    const indexKey = 'semantic:index';
    const keys = await redis.lRange(indexKey, 0, -1);
    
    let totalEntries = keys.length;
    let totalHits = 0;
    let oldestEntry = null;
    let newestEntry = null;
    
    for (const key of keys) {
      const entryData = await redis.get(`semantic:${key}`);
      if (entryData) {
        const entry = JSON.parse(entryData);
        totalHits += entry.hits || 0;
        if (!oldestEntry || entry.timestamp < oldestEntry) oldestEntry = entry.timestamp;
        if (!newestEntry || entry.timestamp > newestEntry) newestEntry = entry.timestamp;
      }
    }
    
    return {
      available: true,
      totalEntries,
      totalHits,
      hitRate: totalEntries > 0 ? (totalHits / totalEntries).toFixed(2) : 0,
      oldestEntry: oldestEntry ? new Date(oldestEntry).toISOString() : null,
      newestEntry: newestEntry ? new Date(newestEntry).toISOString() : null,
      ttlHours: SEMANTIC_CACHE_TTL / 3600,
      similarityThreshold: SIMILARITY_THRESHOLD,
    };
  } catch (error) {
    return { available: true, error: error.message };
  }
}

/**
 * Invalida cache semántico (para testing o cambios de modelo)
 * @returns {Promise<void>}
 */
async function invalidateCache() {
  const redis = await getRedisClient();
  if (!redis) return;
  
  try {
    const indexKey = 'semantic:index';
    const keys = await redis.lRange(indexKey, 0, -1);
    
    for (const key of keys) {
      await redis.del(`semantic:${key}`);
    }
    await redis.del(indexKey);
    console.log('🗑️ Cache semántico invalidado');
  } catch (error) {
    console.warn('⚠️ Error invalidando cache semántico:', error.message);
  }
}

/**
 * Middleware para integrar cache semántico en flujo RAG
 * @param {Object} options - Opciones
 * @returns {Function} Middleware Express
 */
function semanticCacheMiddleware(options = {}) {
  return async (req, res, next) => {
    // Solo para endpoints de chat/RAG
    if (!req.path.includes('/chat') && !req.path.includes('/rag')) {
      return next();
    }
    
    // El cache se usa dentro de geminiService.js, no como middleware Express
    // Este middleware es para estadísticas vía API
    next();
  };
}

module.exports = {
  findSimilarInCache,
  setCache,
  incrementHits,
  getCacheStats,
  invalidateCache,
  semanticCacheMiddleware,
  cosineSimilarity,
  generateCacheKey,
  SEMANTIC_CACHE_TTL,
  SIMILARITY_THRESHOLD,
};