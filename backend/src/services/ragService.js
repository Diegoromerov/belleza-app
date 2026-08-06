// backend/src/services/ragService.js
// Servicio RAG vectorial con pgVector + NVIDIA NV-Embed-QA (1024d)
// Búsqueda por similitud coseno + filtrado por metadata + fallback seguro

const { pool } = require('../config/db');
const { breakers } = require('./circuitBreakerService');
const { sanitizeForLog } = require('../utils/piiSanitizer');
const { generateEmbedding, validateEmbeddingDimension } = require('./embeddingService');
require('dotenv').config();

// Feature flags
const ENABLE_BEAUTY_RAG = process.env.ENABLE_BEAUTY_RAG === 'true';
const RAG_TOP_K = parseInt(process.env.RAG_TOP_K || '5', 10);
const RAG_SIMILARITY_THRESHOLD = parseFloat(process.env.RAG_SIMILARITY_THRESHOLD || '0.72');

/**
 * Construye la cláusula WHERE para filtros de metadata
 * @param {Object} filters - Filtros opcionales
 * @returns {{whereClause: string, params: any[]}} SQL WHERE clause y parámetros
 */
function buildMetadataFilters(filters = {}) {
  const conditions = [];
  const params = [];
  let paramIndex = 1;

  if (filters.category) {
    conditions.push(`category = $${paramIndex++}`);
    params.push(filters.category);
  }

  if (filters.skin_type) {
    conditions.push(`skin_type = $${paramIndex++}`);
    params.push(filters.skin_type);
  }

  if (filters.season_station) {
    conditions.push(`season_station = $${paramIndex++}`);
    params.push(filters.season_station);
  }

  if (filters.age_range) {
    conditions.push(`age_range = $${paramIndex++}`);
    params.push(filters.age_range);
  }

  if (filters.ingredients && Array.isArray(filters.ingredients) && filters.ingredients.length > 0) {
    conditions.push(`ingredients && $${paramIndex++}`);
    params.push(filters.ingredients);
  }

  if (filters.contraindications && Array.isArray(filters.contraindications) && filters.contraindications.length > 0) {
    // Excluir chunks que tengan contraindicaciones relevantes
    conditions.push(`NOT (contraindications && $${paramIndex++})`);
    params.push(filters.contraindications);
  }

  const whereClause = conditions.length > 0 
    ? `WHERE ${conditions.join(' AND ')}`
    : '';

  return { whereClause, params };
}

/**
 * Busca chunks de conocimiento de belleza usando búsqueda vectorial + filtros metadata
 * @param {string} query - Consulta del usuario
 * @param {Object} options - Opciones de búsqueda
 * @param {number} options.topK - Número de resultados (default 5)
 * @param {number} options.threshold - Umbral de similitud coseno (default 0.72)
 * @param {Object} options.filters - Filtros por metadata
 * @returns {Promise<Array>} Chunks encontrados con score de similitud
 *         Cada chunk incluye metadata adicional para logging: _retrieval_latency_ms, _filters_applied
 */
async function searchBeautyKnowledge(query, options = {}) {
  const { 
    topK = RAG_TOP_K, 
    threshold = RAG_SIMILARITY_THRESHOLD,
    filters = {} 
  } = options;

  // Log sanitizado de la query
  console.log(`🔍 RAG Search: "${sanitizeForLog(query)}" [topK=${topK}, threshold=${threshold}]`);

  if (!ENABLE_BEAUTY_RAG) {
    console.log('⚠️ RAG deshabilitado por feature flag');
    return [];
  }

  const retrievalStart = Date.now();
  
  try {
    // Generar embedding de la query (input_type='query' para modelos asimétricos)
    const queryEmbedding = await generateEmbedding(query, 'query');
    const vectorLiteral = `[${queryEmbedding.join(',')}]`;

    // Construir filtros de metadata
    const { whereClause, params: filterParams } = buildMetadataFilters(filters);
    
    // Query principal: búsqueda vectorial con similitud coseno + filtros
    // similarity = 1 - (embedding <=> query_embedding)
    const sql = `
      SELECT 
        id,
        title,
        category,
        content,
        metadata,
        skin_type,
        season_station,
        age_range,
        ingredients,
        contraindications,
        1 - (embedding <=> $1::vector) as similarity
      FROM beauty_knowledge_embeddings
      ${whereClause}
        AND 1 - (embedding <=> $1::vector) > $${params.length + 1}
      ORDER BY embedding <=> $1::vector
      LIMIT $${params.length + 2}
    `;

    const queryParams = [vectorLiteral, ...filterParams, threshold, topK];
    
    const res = await pool.query(sql, queryParams);

    const retrievalLatencyMs = Date.now() - retrievalStart;
    
    console.log(`✅ RAG: ${res.rows.length} chunks encontrados (threshold=${threshold}, latencia: ${retrievalLatencyMs}ms)`);

    const chunks = res.rows.map(row => ({
      id: row.id,
      title: row.title,
      category: row.category,
      content: row.content,
      metadata: row.metadata,
      skinType: row.skin_type,
      seasonStation: row.season_station,
      ageRange: row.age_range,
      ingredients: row.ingredients,
      contraindications: row.contraindications,
      similarity: parseFloat(row.similarity),
      // Metadata para logging (no rompe compatibilidad)
      _retrieval_latency_ms: retrievalLatencyMs,
      _filters_applied: filters,
      _threshold: threshold,
      _topK: topK,
    }));

    return chunks;

  } catch (error) {
    console.error('❌ Error en searchBeautyKnowledge:', error.message);
    
    // Fallback seguro: búsqueda por texto simple si pgVector falla
    return await fallbackTextSearch(query, topK, filters);
  }
}

/**
 * Fallback seguro: búsqueda full-text simple sin vectores
 * No inventa conocimiento médico, solo busca en contenido existente
 */
async function fallbackTextSearch(query, topK, filters) {
  console.warn('⚠️ RAG Vectorial falló. Usando fallback full-text...');
  
  try {
    const { whereClause, params: filterParams } = buildMetadataFilters(filters);
    
    const sql = `
      SELECT 
        id, title, category, content, metadata,
        skin_type, season_station, age_range,
        ingredients, contraindications,
        0.5 as similarity
      FROM beauty_knowledge_embeddings
      ${whereClause}
        AND to_tsvector('spanish', title || ' ' || content) @@ plainto_tsquery('spanish', $${filterParams.length + 1})
      ORDER BY ts_rank(to_tsvector('spanish', title || ' ' || content), plainto_tsquery('spanish', $${filterParams.length + 1})) DESC
      LIMIT $${filterParams.length + 2}
    `;

    const res = await pool.query(sql, [...filterParams, query, topK]);
    
    console.log(`✅ RAG Fallback: ${res.rows.length} chunks (full-text)`);
    
    return res.rows.map(row => ({
      id: row.id,
      title: row.title,
      category: row.category,
      content: row.content,
      metadata: row.metadata,
      skinType: row.skin_type,
      seasonStation: row.season_station,
      ageRange: row.age_range,
      ingredients: row.ingredients,
      contraindications: row.contraindications,
      similarity: 0.5, // Score fijo para indicar degradación
      _degraded: true, // Flag para que el orquestador sepa que es fallback
    }));

  } catch (fallbackError) {
    console.error('❌ Fallback full-text también falló:', fallbackError.message);
    return [];
  }
}

/**
 * Formatea chunks para inyección en system prompt
 * @param {Array} chunks - Chunks encontrados
 * @returns {string} Contexto formateado
 */
function formatKnowledgeContext(chunks) {
  if (!chunks || chunks.length === 0) return '';
  
  const isDegraded = chunks.some(c => c._degraded);
  const header = isDegraded 
    ? '--- CONOCIMIENTO TÉCNICO (MODO DEGRADADO: full-text fallback) ---'
    : '--- CONOCIMIENTO TÉCNICO DE BELLEZA (RAG Vectorial) ---';
  
  return chunks.map((chunk, i) => {
    const source = chunk.title || chunk.category || `fuente-${i + 1}`;
    const metaParts = [];
    if (chunk.skinType) metaParts.push(`piel: ${chunk.skinType}`);
    if (chunk.seasonStation) metaParts.push(`estación: ${chunk.seasonStation}`);
    if (chunk.ageRange) metaParts.push(`edad: ${chunk.ageRange}`);
    const metaStr = metaParts.length ? ` [${metaParts.join(', ')}]` : '';
    
    return `[Fuente ${i + 1}: ${source}${metaStr}] (sim: ${chunk.similarity.toFixed(3)})\n${chunk.content}`;
  }).join('\n\n');
}

/**
 * Función de ingesta para poblar knowledge base (para uso en jobs/cron)
 * @param {Array} documents - Array de {title, category, content, metadata, skin_type, season_station, age_range, ingredients, contraindications}
 * @returns {Promise<{success: number, failed: number}>}
 */
async function ingestKnowledge(documents) {
  if (!Array.isArray(documents) || documents.length === 0) {
    return { success: 0, failed: 0 };
  }

  let success = 0;
  let failed = 0;

  for (const doc of documents) {
    try {
      // Generar embedding tipo 'passage' para documentos de conocimiento
      const embedding = await generateEmbedding(doc.content, 'passage');
      const vectorLiteral = `[${embedding.join(',')}]`;

      const sql = `
        INSERT INTO beauty_knowledge_embeddings 
        (title, category, content, metadata, embedding, skin_type, season_station, age_range, ingredients, contraindications)
        VALUES ($1, $2, $3, $4, $5::vector, $6, $7, $8, $9, $10)
        ON CONFLICT (title) DO UPDATE SET
          content = EXCLUDED.content,
          metadata = EXCLUDED.metadata,
          embedding = EXCLUDED.embedding,
          skin_type = EXCLUDED.skin_type,
          season_station = EXCLUDED.season_station,
          age_range = EXCLUDED.age_range,
          ingredients = EXCLUDED.ingredients,
          contraindications = EXCLUDED.contraindications,
          updated_at = NOW()
      `;

      await pool.query(sql, [
        doc.title,
        doc.category || 'General',
        doc.content,
        JSON.stringify(doc.metadata || {}),
        vectorLiteral,
        doc.skin_type || null,
        doc.season_station || null,
        doc.age_range || null,
        doc.ingredients || null,
        doc.contraindications || null,
      ]);

      success++;
    } catch (error) {
      console.error(`❌ Ingesta fallida para "${sanitizeForLog(doc.title)}":`, error.message);
      failed++;
    }
  }

  console.log(`📥 Ingesta RAG completada: ${success} éxitos, ${failed} fallos`);
  return { success, failed };
}

module.exports = {
  searchBeautyKnowledge,
  formatKnowledgeContext,
  generateEmbedding: require('./embeddingService').generateEmbedding,
  ingestKnowledge,
  ENABLE_BEAUTY_RAG,
  sanitizeForLog,
};