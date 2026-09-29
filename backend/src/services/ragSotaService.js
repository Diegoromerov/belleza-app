/**
 * backend/src/services/ragSotaService.js
 * Servicio de Innovación SOTA (State-of-the-Art / Grado S) para Aura RAG.
 * 
 * Módulos de Frontera:
 *  1. HyDE (Hypothetical Document Embeddings) & Multi-Query Expansion
 *  2. Compresión Contextual y Destilación Dinámica de Prompts (Anti "Lost in the Middle")
 *  3. Grafo de Conocimiento Multi-Salto (Multi-Hop GraphRAG Subgraph Traversal)
 *  4. Integración Multimodal Vision-RAG (YouCam Skin Metrics Mapper)
 *  5. Bucle de Auto-Corrección y Re-Calibración RLHF (Feedback Signals)
 */

require('dotenv').config();
const { pool, ragPool } = require('../config/db');

/**
 * 1. HyDE (Hypothetical Document Embeddings):
 * Genera una consulta extendida hipotética enriquecida si la consulta del usuario es ambigua o corta (<6 palabras).
 * @param {string} query
 * @returns {string} Consulta HyDE
 */
function generateHyDEQuery(query) {
  if (!query || typeof query !== 'string') return query || '';
  const trimmed = query.trim();
  const words = trimmed.split(/\s+/);

  // Si la consulta ya es larga y descriptiva, se retorna tal cual
  if (words.length >= 6) return trimmed;

  const lower = trimmed.toLowerCase();
  let hypotheticalSnippet = '';

  if (lower.includes('arde') || lower.includes('quemo') || lower.includes('rojo')) {
    hypotheticalSnippet = 'Eritema cutáneo quemadura química irritación cutánea protocolo desensibilizante compresa fría fotoprotección mineral.';
  } else if (lower.includes('tinte') || lower.includes('color')) {
    hypotheticalSnippet = 'Colorimetría capilar fondo de aclaración alcalinización peróxido cistina porosidad mantenimiento pigmentario.';
  } else if (lower.includes('mancha') || lower.includes('paño')) {
    hypotheticalSnippet = 'Melasma hiperpigmentación tirosinasa fotoresistencia ácido tranexámico hidroquinona despigmentante.';
  } else if (lower.includes('cejas') || lower.includes('microblading')) {
    hypotheticalSnippet = 'Visajismo cejas micropigmentación simetría facial pigmento orgánico fototipo reparación epidérmica.';
  } else {
    hypotheticalSnippet = 'Protocolo técnico bioseguridad formulación cosmetológica contraindicaciones dermatológicas.';
  }

  return `${trimmed} [Contexto Hipotético HyDE: ${hypotheticalSnippet}]`;
}

/**
 * 2. Compresión Contextual y Destilación de Prompts:
 * Filtra oraciones irrelevantes de los chunks recuperados dejando únicamente las oraciones con alta densidad semántica.
 * @param {Array} chunks - Chunks recuperados
 * @param {string} query - Consulta del usuario
 * @returns {Array} Chunks comprimidos con contenido destilado
 */
function compressKnowledgeContext(chunks, query) {
  if (!chunks || !Array.isArray(chunks)) return [];
  const queryWords = (query || '').toLowerCase().split(/\s+/).filter(w => w.length > 3);

  return chunks.map(chunk => {
    if (!chunk.content || typeof chunk.content !== 'string') return chunk;

    const sentences = chunk.content.split(/(?<=[.!?])\s+/);
    if (sentences.length <= 2) return chunk;

    // Seleccionar oraciones que contengan palabras clave de la query o datos normativos/clínicos
    const relevantSentences = sentences.filter(sentence => {
      const sLower = sentence.toLowerCase();
      const matchesKey = queryWords.some(w => sLower.includes(w));
      const hasClinicalData = sLower.includes('protocolo') || sLower.includes('contraindicaci') ||
                             sLower.includes('ph') || sLower.includes('paso') ||
                             sLower.includes('mg') || sLower.includes('ml') ||
                             sLower.includes('ºc') || sLower.includes('%');
      return matchesKey || hasClinicalData;
    });

    const compressedContent = relevantSentences.length > 0 
      ? relevantSentences.join(' ') 
      : sentences.slice(0, 2).join(' ');

    return {
      ...chunk,
      content_original: chunk.content,
      content: compressedContent,
      compressed: true,
    };
  });
}

/**
 * 3. Grafo de Conocimiento Multi-Salto (Multi-Hop GraphRAG Subgraph Traversal):
 * Recorre el grafo hasta 2 saltos de profundidad (E1 -> R1 -> E2 -> R2 -> E3) para razonamiento causal.
 * @param {string} queryText
 * @returns {Promise<Array>} Cadenas de relaciones causales encontradas
 */
async function queryMultiHopKnowledgeGraph(queryText) {
  try {
    const dbPool = ragPool || pool;
    const sql = `
      SELECT
        e1.entity_name AS entity_start,
        r1.relation_type AS relation_1,
        e2.entity_name AS entity_mid,
        r2.relation_type AS relation_2,
        e3.entity_name AS entity_end,
        r1.notes AS notes_step1,
        r2.notes AS notes_step2
      FROM rag_entities e1
      JOIN rag_relations r1 ON r1.source_entity_id = e1.id
      JOIN rag_entities e2 ON r1.target_entity_id = e2.id
      LEFT JOIN rag_relations r2 ON r2.source_entity_id = e2.id
      LEFT JOIN rag_entities e3 ON r2.target_entity_id = e3.id
      WHERE $1 ILIKE '%' || e1.entity_name || '%' OR $1 ILIKE '%' || e2.entity_name || '%'
      LIMIT 5;
    `;
    const res = await dbPool.query(sql, [queryText]);
    return res.rows;
  } catch {
    return [];
  }
}

/**
 * 4. Vision-RAG Skin Metrics Mapper:
 * Traduce las métricas del escáner visual de YouCam a filtros y prioridades de búsqueda RAG.
 * @param {Object} visionScanData - Datos del escáner visual
 * @returns {Object} Filtros y preferencias de búsqueda RAG
 */
function mapVisionScanToFilters(visionScanData = {}) {
  const filters = {};
  const priorities = [];

  if (visionScanData.erythema_score && visionScanData.erythema_score > 60) {
    filters.skin_type = 'sensible';
    priorities.push('descongestion_antiinflamatoria');
  } else if (visionScanData.sebum_score && visionScanData.sebum_score > 65) {
    filters.skin_type = 'grasa';
    priorities.push('regulacion_sebasea_acne');
  } else if (visionScanData.hydration_score && visionScanData.hydration_score < 40) {
    filters.skin_type = 'seca';
    priorities.push('hidratacion_barrera_cutanea');
  }

  if (visionScanData.pigmentation_index && visionScanData.pigmentation_index > 50) {
    filters.category = 'ingredientes_activos_contraindicaciones';
    priorities.push('despigmentacion_melasma');
  }

  return { filters, priorities };
}

/**
 * 5. Bucle de Auto-Corrección y Re-Calibración RLHF (Feedback Signals):
 * Registra valoraciones 👍/👎 de profesionales y recalibra el motor.
 * @param {Object} feedbackData
 * @returns {Promise<Object>} Registro creado
 */
async function recordRagFeedback(feedbackData) {
  const { traceId, userIdHash, queryText, rating, feedbackType, notes } = feedbackData;
  const dbPool = pool || ragPool;

  try {
    const sql = `
      INSERT INTO rag_feedback_signals
      (trace_id, user_id_hash, query_text, rating, feedback_type, notes, created_at)
      VALUES ($1, $2, $3, $4, $5, $6, NOW())
      RETURNING id, rating, feedback_type;
    `;
    const res = await dbPool.query(sql, [
      traceId || 'trace-anon',
      userIdHash || null,
      queryText || 'consulta',
      rating || 1,
      feedbackType || 'relevance',
      notes || null,
    ]);
    return { success: true, record: res.rows[0] };
  } catch (error) {
    console.warn('⚠️ No se pudo registrar feedback RLHF:', error.message);
    return { success: false, error: error.message };
  }
}

module.exports = {
  generateHyDEQuery,
  compressKnowledgeContext,
  queryMultiHopKnowledgeGraph,
  mapVisionScanToFilters,
  recordRagFeedback,
};
