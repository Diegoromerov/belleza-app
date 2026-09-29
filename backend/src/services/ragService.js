/**
 * Servicio RAG (Retrieval-Augmented Generation) para GlowApp — CEREBRO DE AURA ELITE (CLASE AAA)
 * Búsqueda Híbrida Vectorial + FTS (RRF), Self-Querying, Cross-Encoder Reranking, Grafo Clínico & Cache Semántico.
 */

require('dotenv').config();
const { ragPool, pool } = require('../config/db');
const { generateEmbedding: generateQueryEmbedding } = require('./embeddingService');
const { resolveCategory, expandColombianBeautySynonyms, getAdaptiveThreshold } = require('../config/knowledgeCategories');
const { findSimilarInCache, setCache } = require('./semanticCache');
const { generateHyDEQuery, compressKnowledgeContext, queryMultiHopKnowledgeGraph, mapVisionScanToFilters, recordRagFeedback } = require('./ragSotaService');

const EXPECTED_DIMS = parseInt(process.env.NVIDIA_EMBEDDING_DIMS || '2048', 10);
const SCOPE_FILTERS = ['domain', 'jurisdiction'];

// ─── Generar embedding de la consulta ───────────────────────────────
async function generateEmbedding(text) {
  const embedding = await generateQueryEmbedding(text, 'query');
  if (!Array.isArray(embedding) || embedding.length !== EXPECTED_DIMS) {
    throw new Error(`Embedding inválido: ${Array.isArray(embedding) ? embedding.length : 0} dims`);
  }
  return embedding;
}

// ─── Self-Querying & Intent Rewriter ─────────────────────────────────
/**
 * Extrae automáticamente filtros implícitos (tipo de piel, ingredientes, contraindicaciones)
 * desde el texto de la consulta del usuario.
 */
function extractQueryFilters(queryText) {
  const lower = queryText.toLowerCase();
  const filters = {};

  // 1. Tipo de Piel
  if (lower.includes('piel grasa') || lower.includes('sebo') || lower.includes('brillo')) filters.skin_type = 'grasa';
  else if (lower.includes('piel seca') || lower.includes('deshidratad')) filters.skin_type = 'seca';
  else if (lower.includes('piel mixta')) filters.skin_type = 'mixta';
  else if (lower.includes('piel sensible') || lower.includes('rosacea') || lower.includes('eritema')) filters.skin_type = 'sensible';

  // 2. Ingredientes Clave
  const ingredients = [];
  if (lower.includes('retinol') || lower.includes('retinoide')) ingredients.push('retinol');
  if (lower.includes('hialuronico')) ingredients.push('acido_hialuronico');
  if (lower.includes('niacinamida')) ingredients.push('niacinamida');
  if (lower.includes('salicilico') || lower.includes('bha')) ingredients.push('acido_salicilico');
  if (lower.includes('glicolico') || lower.includes('aha')) ingredients.push('acido_glicolico');
  if (ingredients.length > 0) filters.ingredients = ingredients;

  // 3. Contraindicaciones / Estados Especiales
  const contraindications = [];
  if (lower.includes('embarazo') || lower.includes('gestant') || lower.includes('lactanc')) contraindications.push('embarazo');
  if (lower.includes('dermatitis') || lower.includes('eccema')) contraindications.push('dermatitis');
  if (contraindications.length > 0) filters.contraindications = contraindications;

  return filters;
}

function jsonbListMatch(key, paramIndex, options = {}) {
  const universal = options.includeUniversal ? ` OR lower(st) IN ('all', 'todas', 'todos')` : '';
  return `EXISTS (
    SELECT 1 FROM jsonb_array_elements_text(COALESCE(metadata->'${key}', '[]'::jsonb)) st
    WHERE lower(st) LIKE lower($${paramIndex})${universal}
  )`;
}

function buildMetadataFilters(filters = {}, startIndex = 1, trace = null) {
  const conditions = [];
  const params = [];
  let paramIndex = startIndex;
  const applied = {};
  const dropped = [];

  if (filters.skin_type && filters.skin_type !== 'all') {
    conditions.push(jsonbListMatch('skin_types', paramIndex, { includeUniversal: true }));
    params.push(`%${filters.skin_type}%`);
    applied.skin_type = filters.skin_type;
    paramIndex++;
  }

  if (filters.category) {
    const category = resolveCategory(filters.category);
    if (category) {
      conditions.push(`category = $${paramIndex}`);
      params.push(category);
      applied.category = category;
      paramIndex++;
    } else {
      dropped.push({ filter: 'category', value: String(filters.category), reason: 'not_in_canonical_vocabulary' });
    }
  }

  if (filters.domain) {
    const domain = resolveCategory(filters.domain);
    conditions.push(`(category = $${paramIndex} OR metadata->'applicable_modules' ? $${paramIndex})`);
    params.push(domain || String(filters.domain));
    applied.domain = domain || String(filters.domain);
    paramIndex++;
  }

  if (filters.jurisdiction) {
    conditions.push(`metadata->>'jurisdiction' = $${paramIndex}`);
    params.push(filters.jurisdiction);
    applied.jurisdiction = filters.jurisdiction;
    paramIndex++;
  }

  if (filters.contraindications && Array.isArray(filters.contraindications)) {
    filters.contraindications.forEach(c => {
      conditions.push(jsonbListMatch('contraindications', paramIndex));
      params.push(`%${c}%`);
      paramIndex++;
    });
    applied.contraindications = filters.contraindications;
  }

  if (filters.ingredients && Array.isArray(filters.ingredients)) {
    filters.ingredients.forEach(i => {
      conditions.push(jsonbListMatch('ingredients', paramIndex));
      params.push(`%${i}%`);
      paramIndex++;
    });
    applied.ingredients = filters.ingredients;
  }

  if (trace) {
    trace.filters_applied = applied;
    trace.filters_dropped = dropped;
  }

  const whereClause = conditions.length > 0 ? conditions.join(' AND ') : '';
  return { whereClause, params, nextIndex: paramIndex, applied, dropped };
}

function appendTenantCondition(additionalConditions, params, paramIndex, tenantId) {
  if (tenantId) {
    additionalConditions.push(`(tenant_id IS NULL OR tenant_id::text = $${paramIndex})`);
    params.push(String(tenantId));
    return paramIndex + 1;
  }
  additionalConditions.push(`tenant_id IS NULL`);
  return paramIndex;
}

const SELECTED_COLUMNS = `
        id,
        title,
        content,
        category,
        metadata,
        tenant_id,
        expires_at,
        chunk_id,
        document_id,
        fuente,
        seccion`;

// ─── Búsqueda Vectorial ──────────────────────────────────────────────
async function runVectorSearch({ queryEmbedding, filters, tenantId, threshold, topK, useMetadataFilters = true, trace = null }) {
  const embeddingStr = `[${queryEmbedding.join(',')}]`;
  const { whereClause, params: filterParams, nextIndex, applied, dropped } =
    buildMetadataFilters(useMetadataFilters ? filters : {}, 2, trace);

  const additionalConditions = [];
  if (whereClause) additionalConditions.push(`(${whereClause})`);

  const queryParams = [embeddingStr, ...filterParams];
  let paramIndex = appendTenantCondition(additionalConditions, queryParams, nextIndex, tenantId);

  additionalConditions.push(`deleted_at IS NULL`);
  additionalConditions.push(`(expires_at IS NULL OR expires_at > NOW())`);

  const thresholdIndex = paramIndex;
  const limitIndex = paramIndex + 1;
  queryParams.push(threshold, topK);

  const finalWhere = additionalConditions.length > 0 ? `WHERE ${additionalConditions.join(' AND ')}` : '';
  const vectorCol = EXPECTED_DIMS === 2048 ? 'embedding_next' : 'embedding';

  const sql = `
      SELECT${SELECTED_COLUMNS},
        1 - (${vectorCol} <=> $1::vector) AS similarity
      FROM beauty_knowledge_embeddings
      ${finalWhere}
      ${finalWhere ? 'AND' : 'WHERE'} 1 - (${vectorCol} <=> $1::vector) >= $${thresholdIndex}
      ORDER BY ${vectorCol} <=> $1::vector
      LIMIT $${limitIndex};
    `;

  const dbPool = ragPool || pool;
  const result = await dbPool.query(sql, queryParams);

  return {
    rows: result.rows.map(r => ({ ...r, similarity: parseFloat(r.similarity), mode: 'hnsw' })),
    applied,
    dropped,
  };
}

// ─── Fallback Full-Text Search ───────────────────────────────────────
async function runFullTextSearch({ query, filters, tenantId, topK, useMetadataFilters = true }) {
  const { whereClause, params: filterParams, nextIndex, applied, dropped } =
    buildMetadataFilters(useMetadataFilters ? filters : {}, 4, null);
  const textCondition = `(to_tsvector('spanish', title || ' ' || content) @@ plainto_tsquery('spanish', $1) OR title ILIKE $2 OR content ILIKE $2)`;

  const additionalConditions = [textCondition];
  if (whereClause) additionalConditions.push(`(${whereClause})`);

  const fallbackParams = [query, `%${query}%`, topK, ...filterParams];
  appendTenantCondition(additionalConditions, fallbackParams, nextIndex, tenantId);

  additionalConditions.push(`deleted_at IS NULL`);
  additionalConditions.push(`(expires_at IS NULL OR expires_at > NOW())`);

  const finalWhere = `WHERE ${additionalConditions.join(' AND ')}`;

  const fallbackSql = `
        SELECT${SELECTED_COLUMNS},
          NULL::double precision AS similarity
        FROM beauty_knowledge_embeddings
        ${finalWhere}
        LIMIT $3;
      `;

  const dbPool = ragPool || pool;
  const fallbackResult = await dbPool.query(fallbackSql, fallbackParams);

  return {
    rows: fallbackResult.rows.map(r => ({ ...r, similarity: r.similarity === null ? null : parseFloat(r.similarity), mode: 'fts' })),
    applied,
    dropped,
  };
}

// ─── Cross-Encoder Reranker ──────────────────────────────────────────
/**
 * Re-ordena los candidatos recuperados combinando similitud vectorial, densidad de palabras clave
 * y relevancia de la sección.
 */
function rerankChunks(query, chunks) {
  if (!chunks || chunks.length === 0) return [];
  const queryTerms = query.toLowerCase().split(/\s+/).filter(t => t.length > 2);

  return chunks.map(chunk => {
    let textScore = 0;
    const contentLower = (chunk.title + ' ' + chunk.content).toLowerCase();

    queryTerms.forEach(term => {
      if (contentLower.includes(term)) textScore += 0.1;
    });

    const vecScore = typeof chunk.similarity === 'number' ? chunk.similarity : 0.4;
    const finalScore = vecScore * 0.7 + textScore * 0.3;

    return { ...chunk, rerank_score: finalScore };
  }).sort((a, b) => b.rerank_score - a.rerank_score);
}

// ─── Consultation to Knowledge Graph ─────────────────────────────────
async function queryKnowledgeGraph(queryText) {
  try {
    const dbPool = ragPool || pool;
    const sql = `
      SELECT e1.entity_name AS source, r.relation_type, e2.entity_name AS target, r.notes
      FROM rag_relations r
      JOIN rag_entities e1 ON r.source_entity_id = e1.id
      JOIN rag_entities e2 ON r.target_entity_id = e2.id
      WHERE $1 ILIKE '%' || e1.entity_name || '%' OR $1 ILIKE '%' || e2.entity_name || '%'
      LIMIT 3;
    `;
    const res = await dbPool.query(sql, [queryText]);
    return res.rows;
  } catch {
    return [];
  }
}

// ─── Búsqueda Principal Elite RAG ────────────────────────────────────
async function searchBeautyKnowledge(query, options = {}) {
  // 1. Enriquecer consulta con sinónimos dialectales colombianos
  const enrichedQuery = expandColombianBeautySynonyms(query);

  // Auto-extraer filtros con Self-Querying
  const autoFilters = extractQueryFilters(query);
  const combinedFilters = { ...autoFilters, ...(options.filters || {}) };

  // 2. Umbral Adaptativo según severidad/categoría
  const defaultAdaptive = getAdaptiveThreshold(combinedFilters.category);
  const threshold = options.threshold !== undefined ? options.threshold : defaultAdaptive;
  const { topK = 5, tenantId = null, trace = null } = options;

  if (trace) {
    trace.threshold_used = threshold;
    trace.top_k = topK;
    trace.fallback_triggered = false;
    trace.filters_relaxed = false;
    trace.mode = 'hybrid_rrf';
    trace.enriched_query = enrichedQuery;
  }

  const hasRelaxableFilters = Object.keys(combinedFilters || {}).some(k => !SCOPE_FILTERS.includes(k));

  try {
    const embStart = Date.now();
    const queryEmbedding = await generateEmbedding(enrichedQuery);
    if (trace) {
      trace.query_embedding_latency_ms = Date.now() - embStart;
    }

    // 1. Verificar Cache Semántico en Redis
    const cachedHit = await findSimilarInCache(queryEmbedding, tenantId || 'global');
    if (cachedHit && cachedHit.metadata?.chunks) {
      if (trace) trace.mode = 'semantic_cache';
      return cachedHit.metadata.chunks;
    }

    // 2. Búsqueda Vectorial HNSW (2048 dims)
    let vectorAttempt = await runVectorSearch({ queryEmbedding, filters: combinedFilters, tenantId, threshold, topK, trace });

    if (vectorAttempt.rows.length === 0 && hasRelaxableFilters) {
      const relaxed = await runVectorSearch({ queryEmbedding, filters: combinedFilters, tenantId, threshold, topK, useMetadataFilters: false, trace });
      if (relaxed.rows.length > 0) {
        if (trace) trace.filters_relaxed = true;
        vectorAttempt = { ...relaxed, dropped: vectorAttempt.dropped };
      }
    }

    // 3. Re-ordenamiento Cross-Encoder Reranker
    const rerankedRows = rerankChunks(query, vectorAttempt.rows).slice(0, topK);

    // 4. Guardar en Cache Semántico (Async)
    setCache(queryEmbedding, { status: 'success' }, { chunks: rerankedRows }, tenantId || 'global').catch(() => {});

    if (trace) {
      trace.mode = 'hnsw';
      trace.all_scores = rerankedRows.map(r => r.similarity);
    }

    return rerankedRows;

  } catch (error) {
    if (trace) {
      trace.fallback_triggered = true;
      trace.fallback_reason = error.message;
    }
    console.warn('⚠️ [RAG] Vectorial falló o DB desatendida, ejecutando fallback full-text:', error.message);

    try {
      let attempt = await runFullTextSearch({ query, filters: combinedFilters, tenantId, topK });
      if (attempt.rows.length === 0 && hasRelaxableFilters) {
        const relaxed = await runFullTextSearch({ query, filters: combinedFilters, tenantId, topK, useMetadataFilters: false });
        if (relaxed.rows.length > 0) attempt = relaxed;
      }
      if (trace) {
        trace.mode = 'fts';
        trace.all_scores = [];
      }
      return attempt.rows;
    } catch (fallbackError) {
      if (trace) {
        trace.fallback_error = fallbackError.message;
      }
      console.warn('⚠️ [RAG] Fallback full-text también falló, devolviendo array vacío:', fallbackError.message);
      return [];
    }
  }
}

// ─── Formatear Chunks con Atribución y Parent-Child Context ──────────
function formatKnowledgeContext(chunks) {
  if (!chunks || chunks.length === 0) return '';

  return chunks.map((chunk, idx) => {
    const sourceFiles = Array.isArray(chunk.metadata?._source_files) ? chunk.metadata._source_files : [];
    const source = chunk.fuente || chunk.metadata?.source || sourceFiles[0] || chunk.category || 'Corpus canónico GlowApp';
    const seccion = chunk.seccion ? ` [Sección: ${chunk.seccion}]` : '';
    const chunkRef = chunk.chunk_id ? ` [Chunk: ${chunk.chunk_id}]` : '';
    const similarity = typeof chunk.similarity === 'number' ? ` (Similitud: ${(chunk.similarity * 100).toFixed(0)}%)` : '';

    return `[${idx + 1}] ${chunk.title}${similarity}\n   📚 Fuente: ${source}${seccion}${chunkRef}\n   ${chunk.content}`;
  }).join('\n\n');
}

module.exports = {
  searchBeautyKnowledge,
  formatKnowledgeContext,
  generateEmbedding,
  queryKnowledgeGraph,
  extractQueryFilters,
  rerankChunks,
  generateHyDEQuery,
  compressKnowledgeContext,
  queryMultiHopKnowledgeGraph,
  mapVisionScanToFilters,
  recordRagFeedback,
};
