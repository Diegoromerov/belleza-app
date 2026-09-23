/**
 * Servicio RAG (Retrieval-Augmented Generation) para GlowApp
 * Busca conocimiento técnico y regulatorio de belleza con aislamiento Multi-Tenant (BUS-RAG-001)
 *
 * Pipeline:
 *   1. embedding real de la consulta vía embeddingService (NVIDIA NIM + circuit breaker, SIN dummy)
 *   2. búsqueda vectorial pgvector (HNSW, similitud coseno) con filtros de metadata, tenant y vigencia
 *   3. si el paso 1 o 2 fallan → fallback full-text (tsvector español) sobre la misma tabla
 *   El tenant viaja SIEMPRE como parámetro ligado ($n), nunca interpolado en el SQL.
 *
 * Filtros (Fase 1, 2026-09-23):
 *   - Los predicados apuntan a los CAMPOS QUE LA INGESTA REALMENTE ESCRIBE. La ingesta
 *     canónica (`ingestCanonicalCorpus.js`) escribe: title, category, content, metadata,
 *     embedding, document_id, document_version, chunk_id, content_hash, fuente, seccion.
 *     Las columnas `skin_type`, `ingredients` y `contraindications` quedan NULL: los datos
 *     viven en `metadata->'skin_types' | 'ingredients' | 'contraindications'`.
 *   - Un `category` fuera del vocabulario canónico (`config/knowledgeCategories.js`) NO se
 *     aplica como filtro: se registra en la traza y se busca sin él (fail-open). Antes
 *     devolvía 0 filas en silencio, con apariencia de "no hay información".
 *   - Si la búsqueda filtrada devuelve 0 filas, se reintenta UNA vez sin filtros de metadata
 *     (la condición de tenant y la vigencia NUNCA se relajan) y se marca `relaxed`.
 *   - El fallback full-text ya no inventa `similarity = 0.5`: devuelve `similarity = null`
 *     y `mode = 'fts'`, para que nadie presente una similitud que no se midió.
 */

require('dotenv').config();
const { ragPool, pool } = require('../config/db');
const { generateEmbedding: generateQueryEmbedding } = require('./embeddingService');
const { resolveCategory } = require('../config/knowledgeCategories');

const EXPECTED_DIMS = 1024;

/**
 * Filtros de ALCANCE: acotan de qué trata la respuesta (normativa vs belleza). NO se relajan
 * nunca: si el dominio no tiene documentos, devolver contenido de otro dominio rotulado como
 * regulatorio sería peor que no devolver nada. El resto de filtros (category, skin_type,
 * ingredients, contraindications) son PISTAS de relevancia y sí pueden relajarse.
 */
const SCOPE_FILTERS = ['domain', 'jurisdiction'];

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

/**
 * Predicado para un filtro sobre una lista JSONB de metadata (skin_types, ingredients,
 * contraindications). Compara cada elemento de la lista, no el JSON entero: el ILIKE
 * sobre `metadata::text` coincidía con nombres de archivo y textos no relacionados.
 *
 * @param {string} key - clave de metadata (ej. 'skin_types')
 * @param {number} paramIndex
 * @param {object} options - { includeUniversal: boolean } añade los valores universales
 *                           ('all' | 'todas' | 'todos'), que marcan contenido válido para
 *                           cualquier caso: 4.526 de 5.619 chunks están etiquetados 'all'.
 * @returns {string} condición SQL con `$n` ligado
 */
function jsonbListMatch(key, paramIndex, options = {}) {
  const universal = options.includeUniversal
    ? ` OR lower(st) IN ('all', 'todas', 'todos')`
    : '';
  return `EXISTS (
            SELECT 1 FROM jsonb_array_elements_text(COALESCE(metadata->'${key}', '[]'::jsonb)) AS st
            WHERE st ILIKE $${paramIndex}${universal}
          )`;
}

// ─── Construir filtros de metadata ───────────────────────────────────
/**
 * @param {object} filters - filtros solicitados
 * @param {number} startIndex - primer índice de parámetro disponible
 * @param {object} [trace] - objeto de traza que se completa con lo aplicado/descartado
 * @returns {{whereClause: string, params: Array, nextIndex: number, applied: object, dropped: Array}}
 */
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
      // Fail-open: filtrar por un valor inexistente devolvía 0 filas sin explicación.
      dropped.push({ filter: 'category', value: String(filters.category), reason: 'not_in_canonical_vocabulary' });
    }
  }

  if (filters.domain) {
    // `domain` se compara contra los campos que existen: la categoría canónica o los
    // módulos aplicables. El corpus NO tiene `metadata->>'domain'` (0 de 5.619 chunks):
    // ese predicado devolvía vacío siempre. Si el dominio no existe en el corpus, la
    // búsqueda puede quedar vacía legítimamente (p. ej. 'BUSINESS': el corpus canónico
    // no contiene documentos regulatorios), y la traza lo deja registrado.
    const domain = resolveCategory(filters.domain);
    conditions.push(`(category = $${paramIndex} OR metadata->'applicable_modules' ? $${paramIndex})`);
    params.push(domain || String(filters.domain));
    applied.domain = domain || String(filters.domain);
    paramIndex++;
  }

  if (filters.jurisdiction) {
    // `metadata->>'jurisdiction'` no existe en el corpus canónico (0 de 5.619): se mantiene
    // el predicado por contrato, pero queda registrado en la traza para que un resultado
    // vacío sea diagnosticable en lugar de silencioso.
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

// Columnas que devuelve todo retrieval: identidad del chunk para citar en la respuesta.
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

/**
 * Búsqueda vectorial. `useMetadataFilters = false` permite el reintento relajado.
 * La condición de tenant y la vigencia (soft delete / expiración) NUNCA se relajan.
 */
async function runVectorSearch({ queryEmbedding, filters, tenantId, threshold, topK, useMetadataFilters = true }) {
  const embeddingStr = `[${queryEmbedding.join(',')}]`;

  // $1 = vector de la consulta; los filtros de metadata empiezan en $2
  const { whereClause, params: filterParams, nextIndex, applied, dropped } =
    buildMetadataFilters(useMetadataFilters ? filters : {}, 2, null);

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
      SELECT${SELECTED_COLUMNS},
        1 - (embedding <=> $1::vector) AS similarity
      FROM beauty_knowledge_embeddings
      ${finalWhere}
      ${finalWhere ? 'AND' : 'WHERE'} 1 - (embedding <=> $1::vector) >= $${thresholdIndex}
      ORDER BY embedding <=> $1::vector
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

/** Fallback full-text. Sin filtros de metadata cuando `useMetadataFilters = false`. */
async function runFullTextSearch({ query, filters, tenantId, topK, useMetadataFilters = true }) {
  // $1 = query, $2 = patrón ILIKE, $3 = LIMIT; los filtros de metadata empiezan en $4
  const { whereClause, params: filterParams, nextIndex, applied, dropped } =
    buildMetadataFilters(useMetadataFilters ? filters : {}, 4, null);
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
        SELECT${SELECTED_COLUMNS},
          NULL::double precision AS similarity
        FROM beauty_knowledge_embeddings
        ${finalWhere}
        LIMIT $3;
      `;

  const dbPool = ragPool || pool;
  const fallbackResult = await dbPool.query(fallbackSql, fallbackParams);

  // similarity null: el full-text no mide similitud coseno y no se inventa un valor.
  return {
    rows: fallbackResult.rows.map(r => ({ ...r, similarity: r.similarity === null ? null : parseFloat(r.similarity), mode: 'fts' })),
    applied,
    dropped,
  };
}

// ─── Búsqueda principal con aislamiento Multi-Tenant ────────────────────────────────────
/**
 * @param {string} query - consulta del usuario
 * @param {object} [options] - { topK, threshold, filters, tenantId, trace }
 *   `trace` (opcional) se completa con: mode, threshold_used, filters_applied,
 *   filters_dropped, filters_relaxed, fallback_triggered, fallback_reason, all_scores.
 * @returns {Promise<Array>} chunks con similarity (null si vino del fallback full-text)
 */
async function searchBeautyKnowledge(query, options = {}) {
  const { topK = 5, threshold = 0.45, filters = {}, tenantId = null, trace = null } = options;

  if (trace) {
    trace.threshold_used = threshold;
    trace.top_k = topK;
    trace.fallback_triggered = false;
    trace.filters_relaxed = false;
    trace.mode = null;
  }

  // Sólo se relaja si hay filtros que son pistas de relevancia (nunca filtros de alcance).
  const hasRelaxableFilters = Object.keys(filters || {}).some(k => !SCOPE_FILTERS.includes(k));

  try {
    const embStart = Date.now();
    const queryEmbedding = await generateEmbedding(query);
    if (trace) {
      trace.query_embedding_latency_ms = Date.now() - embStart;
    }

    let attempt = await runVectorSearch({ queryEmbedding, filters, tenantId, threshold, topK });

    // Red de seguridad: un filtro de metadata que no existe en el corpus (categoría
    // desconocida, skin_type con datos sucios) devolvía 0 filas como si no hubiera
    // conocimiento. Se reintenta UNA vez sin esos filtros. Los filtros de ALCANCE
    // (domain/jurisdiction) NO se relajan: acotan el tema de la respuesta.
    if (attempt.rows.length === 0 && hasRelaxableFilters) {
      const relaxed = await runVectorSearch({ queryEmbedding, filters, tenantId, threshold, topK, useMetadataFilters: false });
      if (relaxed.rows.length > 0) {
        if (trace) {
          trace.filters_relaxed = true;
          trace.relaxed_reason = '0 filas con filtros de metadata; reintento sin filtros (tenant y vigencia intactos)';
        }
        attempt = { ...relaxed, dropped: attempt.dropped };
      }
    }

    if (trace) {
      trace.mode = 'hnsw';
      trace.filters_applied = attempt.applied;
      trace.filters_dropped = attempt.dropped;
      trace.all_scores = attempt.rows.map(r => r.similarity);
    }

    return attempt.rows;

  } catch (error) {
    if (trace) {
      trace.fallback_triggered = true;
      trace.fallback_reason = error.message;
    }
    console.warn('⚠️ [RAG] Vectorial falló o DB desatendida, ejecutando fallback full-text:', error.message);

    try {
      let attempt = await runFullTextSearch({ query, filters, tenantId, topK });

      if (attempt.rows.length === 0 && hasRelaxableFilters) {
        const relaxed = await runFullTextSearch({ query, filters, tenantId, topK, useMetadataFilters: false });
        if (relaxed.rows.length > 0) {
          if (trace) {
            trace.filters_relaxed = true;
            trace.relaxed_reason = '0 filas con filtros de metadata; reintento sin filtros (tenant y vigencia intactos)';
          }
          attempt = { ...relaxed, dropped: attempt.dropped };
        }
      }

      if (trace) {
        trace.mode = 'fts';
        trace.filters_applied = attempt.applied;
        trace.filters_dropped = attempt.dropped;
        trace.all_scores = [];
      }

      return attempt.rows;

    } catch (fallbackError) {
      if (trace) {
        trace.mode = 'unavailable';
        trace.fallback_error = fallbackError.message;
      }
      console.warn('⚠️ [RAG] Fallback full-text también falló, devolviendo array vacío:', fallbackError.message);
      return [];
    }
  }
}

// ─── Formatear chunks para inyección en prompt ───────────────────────
/**
 * Cita con los campos reales del corpus: `fuente` y `seccion` (columnas que escribe la
 * ingesta). `metadata.source | legal_basis | jurisdiction | authority | version` existen en
 * 0 de 5.619 chunks, así que la "Fuente" que se mostraba antes era el slug de categoría o
 * el literal 'GlowApp Canon'. La similitud sólo se muestra cuando se midió de verdad
 * (el fallback full-text devuelve null).
 */
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
};
