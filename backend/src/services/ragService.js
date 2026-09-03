/**
 * Servicio RAG (Retrieval-Augmented Generation)
 * Busca conocimiento técnico de belleza en la base de datos pgvector
 */

require('dotenv').config();
const { ragPool } = require('../config/db');
const axios = require('axios');

const NVIDIA_API_KEY = process.env.NVIDIA_API_KEY;
const NVIDIA_API_URL = process.env.NVIDIA_API_URL || 'https://integrate.api.nvidia.com/v1/embeddings';
const NVIDIA_EMBEDDING_MODEL = process.env.NVIDIA_EMBEDDING_MODEL || 'nvidia/nv-embedqa-e5-v5';
const EXPECTED_DIMS = 1024;

// ─── Generar embedding de un texto ───────────────────────────────────
async function generateEmbedding(text) {
  if (!NVIDIA_API_KEY) throw new Error('NVIDIA_API_KEY no configurada');

  const response = await axios.post(
    NVIDIA_API_URL,
    {
      model: NVIDIA_EMBEDDING_MODEL,
      input: [text],
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
}

// ─── Construir filtros de metadata ───────────────────────────────────
// FIX BUG #5: acepta startIndex para no chocar con $1 del vector
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

  const whereClause = conditions.length > 0
    ? `WHERE ${conditions.join(' AND ')}`
    : '';

  return { whereClause, params };
}

// ─── Búsqueda vectorial principal ────────────────────────────────────
async function searchBeautyKnowledge(query, options = {}) {
  const { topK = 5, threshold = 0.45, filters = {} } = options;

  try {
    // Generar embedding del query
    const queryEmbedding = await generateEmbedding(query);
    const embeddingStr = `[${queryEmbedding.join(',')}]`;

    // Construir filtros de metadata
    const { whereClause, params: filterParams } = buildMetadataFilters(filters, 2);

    // Construir condiciones adicionales: tenant, retention, soft delete
    const additionalConditions = [];
    if (whereClause.trim() !== '') {
      additionalConditions.push(`(${whereClause})`);
    }
    // Condición de tenant: GLOBAL (tenant_id IS NULL) o TENANT-SCOPED del tenant actual
    additionalConditions.push(`(tenant_id IS NULL OR (current_setting('app.tenant_id') <> '' AND tenant_id = current_setting('app.tenant_id')::int))`);
    // Soft delete: excluir eliminados lógicamente
    additionalConditions.push(`deleted_at IS NULL`);
    // Retención: excluir expirados
    additionalConditions.push(`(expires_at IS NULL OR expires_at > NOW())`);

    const finalWhere = additionalConditions.length > 0 ? `WHERE ${additionalConditions.join(' AND ')}` : '';

    // FIX BUG #5: startIndex=2 porque $1 es el vector de búsqueda
    // Ahora, los parámetros de filtros empiezan en $2, pero ya hemos ajustado en buildMetadataFilters(startIndex=2)
    // La similitud y el límite usan los índices siguientes a los de filtros
    const sql = `
      SELECT
        id,
        title,
        content,
        category,
        1 - (embedding <=> $1::vector) AS similarity
      FROM beauty_knowledge_embeddings
      ${finalWhere}
      ${finalWhere ? 'AND' : 'WHERE'} 1 - (embedding <=> $1::vector) >= $${filterParams.length + 2}
      ORDER BY embedding <=> $1::vector
      LIMIT $${filterParams.length + 3};
    `;

    const queryParams = [embeddingStr, ...filterParams, threshold, topK];
    const result = await ragPool.query(sql, queryParams);

    return result.rows.map(r => ({
      ...r,
      similarity: parseFloat(r.similarity),
    }));

  } catch (error) {
    console.error('❌ Error en searchBeautyKnowledge:', error.message);

    // FIX BUG #4: fallback full-text con manejo correcto de WHERE/AND
    try {
      console.warn('⚠️ RAG Vectorial falló. Usando fallback full-text...');
      const { whereClause, params: filterParams } = buildMetadataFilters(filters, 2);
      const textCondition = `(to_tsvector('spanish', title || ' ' || content) @@ plainto_tsquery('spanish', $1) OR title ILIKE $2 OR content ILIKE $2)`;

      // Construir condiciones adicionales para el fallback
      const additionalConditions = [];
      if (whereClause.trim() !== '') {
        additionalConditions.push(`(${whereClause})`);
      }
      additionalConditions.push(`(tenant_id IS NULL OR (current_setting('app.tenant_id') <> '' AND tenant_id = current_setting('app.tenant_id')::int))`);
      additionalConditions.push(`deleted_at IS NULL`);
      additionalConditions.push(`(expires_at IS NULL OR expires_at > NOW())`);

      const finalWhere = additionalConditions.length > 0 ? `WHERE ${additionalConditions.join(' AND ')}` : '';

      const fallbackSql = `
        SELECT
          id,
          title,
          content,
          category,
          0.5 AS similarity
        FROM beauty_knowledge_embeddings
        ${finalWhere}
        ${finalWhere ? 'AND' : 'WHERE'} ${textCondition}
        LIMIT $${filterParams.length + 3};
      `;

      const fallbackParams = [query, `%${query}%`, ...filterParams, topK];
      const fallbackResult = await ragPool.query(fallbackSql, fallbackParams);

      return fallbackResult.rows;

    } catch (fallbackError) {
      console.error('❌ Fallback full-text también falló:', fallbackError.message);
      return [];
    }
  }
}

// ─── Formatear chunks para inyección en prompt ───────────────────────
function formatKnowledgeContext(chunks) {
  if (!chunks || chunks.length === 0) return '';

  return chunks.map((chunk, idx) => {
    const source = chunk.sources || chunk.metadata?.sources;
    const sourceText = source
      ? `\n   📚 Fuente: ${typeof source === 'string' ? source : JSON.stringify(source)}`
      : '';
    return `[${idx + 1}] ${chunk.title} (similitud: ${chunk.similarity?.toFixed(2) || 'N/A'})\n${chunk.content}${sourceText}`;
  }).join('\n\n');
}

module.exports = {
  searchBeautyKnowledge,
  formatKnowledgeContext,
  generateEmbedding,
};