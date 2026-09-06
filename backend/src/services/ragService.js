/**
 * Servicio RAG (Retrieval-Augmented Generation) para GlowApp
 * Busca conocimiento técnico y regulatorio de belleza con aislamiento Multi-Tenant (BUS-RAG-001)
 */

require('dotenv').config();
const { ragPool, pool } = require('../config/db');
const axios = require('axios');

const NVIDIA_API_KEY = process.env.NVIDIA_API_KEY;
const NVIDIA_API_URL = process.env.NVIDIA_API_URL || 'https://integrate.api.nvidia.com/v1/embeddings';
const NVIDIA_EMBEDDING_MODEL = process.env.NVIDIA_EMBEDDING_MODEL || 'nvidia/nv-embedqa-e5-v5';
const EXPECTED_DIMS = 1024;

// ─── Generar embedding de un texto ───────────────────────────────────
async function generateEmbedding(text) {
  if (!NVIDIA_API_KEY) {
    // Fallback determinístico si NVIDIA_API_KEY no está disponible en dev/test
    const hash = require('crypto').createHash('sha256').update(text).digest();
    const embedding = new Array(EXPECTED_DIMS).fill(0).map((_, i) => (hash[i % 32] / 255 - 0.5) * 0.01);
    const norm = Math.sqrt(embedding.reduce((sum, v) => sum + v * v, 0));
    return embedding.map(v => v / norm);
  }

  try {
    const response = await axios.post(
      NVIDIA_API_URL,
      {
        model: NVIDIA_EMBEDDING_MODEL,
        input: [text.slice(0, 8000)],
        input_type: 'query',
        encoding_format: 'float',
      },
      {
        headers: {
          'Authorization': `Bearer ${NVIDIA_API_KEY}`,
          'Content-Type': 'application/json',
        },
        timeout: 15000,
      }
    );

    const embedding = response.data?.data?.[0]?.embedding;
    if (!embedding || embedding.length !== EXPECTED_DIMS) {
      throw new Error(`Embedding inválido: ${embedding ? embedding.length : 0} dims`);
    }
    return embedding;
  } catch (err) {
    console.warn('⚠️ Error llamando a API Embedding, usando fallback determinístico:', err.message);
    const hash = require('crypto').createHash('sha256').update(text).digest();
    const embedding = new Array(EXPECTED_DIMS).fill(0).map((_, i) => (hash[i % 32] / 255 - 0.5) * 0.01);
    const norm = Math.sqrt(embedding.reduce((sum, v) => sum + v * v, 0));
    return embedding.map(v => v / norm);
  }
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

// ─── Búsqueda vectorial principal con aislamiento Multi-Tenant ────────────────────────────────────
async function searchBeautyKnowledge(query, options = {}) {
  const { topK = 5, threshold = 0.45, filters = {}, tenantId = null } = options;

  try {
    const queryEmbedding = await generateEmbedding(query);
    const embeddingStr = `[${queryEmbedding.join(',')}]`;

    const { whereClause, params: filterParams, nextIndex } = buildMetadataFilters(filters, 2);

    const additionalConditions = [];
    if (whereClause) {
      additionalConditions.push(`(${whereClause})`);
    }

    // MULTI-TENANT ISOLATION BOUNDARY:
    // Permite conocimiento GLOBAL (tenant_id IS NULL) O conocimiento propio del tenant especificado.
    // IMPIDE terminantemente la filtración de documentos privados de otros tenants.
    if (tenantId) {
      additionalConditions.push(`(tenant_id IS NULL OR tenant_id::text = '${tenantId}')`);
    } else {
      additionalConditions.push(`tenant_id IS NULL`);
    }

    // Soft delete & Expiration
    additionalConditions.push(`deleted_at IS NULL`);
    additionalConditions.push(`(expires_at IS NULL OR expires_at > NOW())`);

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
      ${finalWhere ? 'AND' : 'WHERE'} 1 - (embedding <=> $1::vector) >= $${nextIndex}
      ORDER BY embedding <=> $1::vector
      LIMIT $${nextIndex + 1};
    `;

    const queryParams = [embeddingStr, ...filterParams, threshold, topK];
    const dbPool = ragPool || pool;
    const result = await dbPool.query(sql, queryParams);

    return result.rows.map(r => ({
      ...r,
      similarity: parseFloat(r.similarity),
    }));

  } catch (error) {
    console.warn('⚠️ [RAG] Vectorial falló o DB desatendida, ejecutando fallback full-text:', error.message);

    try {
      const { whereClause, params: filterParams, nextIndex } = buildMetadataFilters(filters, 3);
      const textCondition = `(title ILIKE $1 OR content ILIKE $1)`;

      const additionalConditions = [textCondition];
      if (whereClause) {
        additionalConditions.push(`(${whereClause})`);
      }
      if (tenantId) {
        additionalConditions.push(`(tenant_id IS NULL OR tenant_id::text = '${tenantId}')`);
      } else {
        additionalConditions.push(`tenant_id IS NULL`);
      }
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
        LIMIT $2;
      `;

      const fallbackParams = [`%${query}%`, topK, ...filterParams];
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