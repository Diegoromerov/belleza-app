/**
 * Servicio RAG (Retrieval-Augmented Generation) para GlowApp
 * Busca conocimiento técnico y regulatorio de belleza con aislamiento Multi-Tenant (BUS-RAG-001)
 *
 * Pipeline (port R1-R4, 2026-09-22):
 *   1. embedding real de la consulta vía embeddingService (NVIDIA NIM + circuit breaker, SIN dummy)
 *   2. búsqueda vectorial pgvector (HNSW, similitud coseno) con filtros de metadata, tenant y vigencia
 *   3. si el paso 1 o 2 fallan → fallback full-text (tsvector español) sobre la misma tabla
 *   El tenant viaja SIEMPRE como parámetro ligado ($n), nunca interpolado en el SQL.
 */

require('dotenv').config();
const { ragPool, pool } = require('../config/db');
const { generateEmbedding: generateQueryEmbedding } = require('./embeddingService');

const EXPECTED_DIMS = 1024;

// ─── Generar embedding de la consulta ───────────────────────────────
async function generateEmbedding(text) {
  // Sin vector fabricado: si NVIDIA no está disponible, esto lanza y el retrieval
  // degrada a full-text (nunca se busca con un embedding sin valor semántico).
  const embedding = await generateQueryEmbedding(text, 'query');

  if (!Array.isArray(embedding) || embedding.length !== EXPECTED_DIMS) {
    throw new Error(`Embedding inválido: ${Array.isArray(embedding) ? embedding.length : 0} dims`);
  }

  return embedding;
}

// ─── Construir filtros de metadata ───────────────────────────────────
function buildMetadataFilters(filters = {}, startIndex = 1) {
  const conditions = [];
  const params = [];
  let paramIndex = startIndex;

  if (filters.skin_type && filters.skin_type !== 'all') {
    conditions.push(`skin_type ILIKE $${paramIndex}`);
    params.push(`%${filters.skin_type}%`);
    paramIndex++;
  }

  if (filters.category) {
    conditions.push(`category = $${paramIndex}`);
    params.push(filters.category);
    paramIndex++;
  }

  if (filters.domain) {
    conditions.push(`metadata->>'domain' = $${paramIndex}`);
    params.push(filters.domain);
    paramIndex++;
  }

  if (filters.jurisdiction) {
    conditions.push(`metadata->>'jurisdiction' = $${paramIndex}`);
    params.push(filters.jurisdiction);
    paramIndex++;
  }

  if (filters.contraindications && Array.isArray(filters.contraindications)) {
    filters.contraindications.forEach(c => {
      conditions.push(`contraindications::text ILIKE $${paramIndex}`);
      params.push(`%${c}%`);
      paramIndex++;
    });
  }

  if (filters.ingredients && Array.isArray(filters.ingredients)) {
    filters.ingredients.forEach(i => {
      conditions.push(`ingredients::text ILIKE $${paramIndex}`);
      params.push(`%${i}%`);
      paramIndex++;
    });
  }

  const whereClause = conditions.length > 0 ? conditions.join(' AND ') : '';

  return { whereClause, params, nextIndex: paramIndex };
}

/**
 * Añade la condición de aislamiento multi-tenant con parámetro LIGADO ($n).
 * Con tenantId: conocimiento GLOBAL (tenant_id IS NULL) o propio del tenant.
 * Sin tenantId: solo GLOBAL.
 * Devuelve el siguiente índice de parámetro disponible.
 */
function appendTenantCondition(additionalConditions, params, paramIndex, tenantId) {
  if (tenantId) {
    additionalConditions.push(`(tenant_id IS NULL OR tenant_id::text = $${paramIndex})`);
    params.push(String(tenantId));
    return paramIndex + 1;
  }

  additionalConditions.push(`tenant_id IS NULL`);
  return paramIndex;
}

// ─── Búsqueda vectorial principal con aislamiento Multi-Tenant ────────────────────────────────────
async function searchBeautyKnowledge(query, options = {}) {
  const { topK = 5, threshold = 0.45, filters = {}, tenantId = null } = options;

  try {
    const queryEmbedding = await generateEmbedding(query);
    const embeddingStr = `[${queryEmbedding.join(',')}]`;

    // $1 = vector de la consulta; los filtros de metadata empiezan en $2
    const { whereClause, params: filterParams, nextIndex } = buildMetadataFilters(filters, 2);

    const additionalConditions = [];
    if (whereClause) {
      additionalConditions.push(`(${whereClause})`);
    }

    // MULTI-TENANT ISOLATION BOUNDARY (BUS-RAG-001):
    // Permite conocimiento GLOBAL (tenant_id IS NULL) O conocimiento propio del tenant especificado.
    // IMPIDE terminantemente la filtración de documentos privados de otros tenants.
    const queryParams = [embeddingStr, ...filterParams];
    let paramIndex = appendTenantCondition(additionalConditions, queryParams, nextIndex, tenantId);

    // Soft delete & Expiration
    additionalConditions.push(`deleted_at IS NULL`);
    additionalConditions.push(`(expires_at IS NULL OR expires_at > NOW())`);

    const thresholdIndex = paramIndex;
    const limitIndex = paramIndex + 1;
    queryParams.push(threshold, topK);

    const finalWhere = additionalConditions.length > 0 ? `WHERE ${additionalConditions.join(' AND ')}` : '';

    const sql = `
      SELECT
        id,
        title,
        content,
        category,
        metadata,
        tenant_id,
        expires_at,
        1 - (embedding <=> $1::vector) AS similarity
      FROM beauty_knowledge_embeddings
      ${finalWhere}
      ${finalWhere ? 'AND' : 'WHERE'} 1 - (embedding <=> $1::vector) >= $${thresholdIndex}
      ORDER BY embedding <=> $1::vector
      LIMIT $${limitIndex};
    `;

    const dbPool = ragPool || pool;
    const result = await dbPool.query(sql, queryParams);

    return result.rows.map(r => ({
      ...r,
      similarity: parseFloat(r.similarity),
    }));

  } catch (error) {
    console.warn('⚠️ [RAG] Vectorial falló o DB desatendida, ejecutando fallback full-text:', error.message);

    try {
      // $1 = query, $2 = patrón ILIKE, $3 = LIMIT; los filtros de metadata empiezan en $4
      const { whereClause, params: filterParams, nextIndex } = buildMetadataFilters(filters, 4);
      const textCondition = `(to_tsvector('spanish', title || ' ' || content) @@ plainto_tsquery('spanish', $1) OR title ILIKE $2 OR content ILIKE $2)`;

      const additionalConditions = [textCondition];
      if (whereClause) {
        additionalConditions.push(`(${whereClause})`);
      }

      const fallbackParams = [query, `%${query}%`, topK, ...filterParams];
      appendTenantCondition(additionalConditions, fallbackParams, nextIndex, tenantId);

      additionalConditions.push(`deleted_at IS NULL`);
      additionalConditions.push(`(expires_at IS NULL OR expires_at > NOW())`);

      const finalWhere = `WHERE ${additionalConditions.join(' AND ')}`;

      const fallbackSql = `
        SELECT
          id,
          title,
          content,
          category,
          metadata,
          tenant_id,
          expires_at,
          0.5 AS similarity
        FROM beauty_knowledge_embeddings
        ${finalWhere}
        LIMIT $3;
      `;

      const dbPool = ragPool || pool;
      const fallbackResult = await dbPool.query(fallbackSql, fallbackParams);

      return fallbackResult.rows.map(r => ({
        ...r,
        similarity: parseFloat(r.similarity),
      }));

    } catch (fallbackError) {
      console.warn('⚠️ [RAG] Fallback full-text también falló, devolviendo array vacío:', fallbackError.message);
      return [];
    }
  }
}

// ─── Formatear chunks para inyección en prompt ───────────────────────
function formatKnowledgeContext(chunks) {
  if (!chunks || chunks.length === 0) return '';

  return chunks.map((chunk, idx) => {
    const source = chunk.metadata?.source || chunk.metadata?.legal_basis || chunk.category || 'GlowApp Canon';
    const jurisdiction = chunk.metadata?.jurisdiction ? ` [Jurisdicción: ${chunk.metadata.jurisdiction}]` : '';
    const authority = chunk.metadata?.authority ? ` [Autoridad: ${chunk.metadata.authority}]` : '';
    const version = chunk.metadata?.version ? ` [Versión: ${chunk.metadata.version}]` : '';

    return `[${idx + 1}] ${chunk.title} (Similitud: ${(chunk.similarity * 100).toFixed(0)}%)\n   📚 Fuente: ${source}${jurisdiction}${authority}${version}\n   ${chunk.content}`;
  }).join('\n\n');
}

module.exports = {
  searchBeautyKnowledge,
  formatKnowledgeContext,
  generateEmbedding,
};
