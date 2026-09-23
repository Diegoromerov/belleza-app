// backend/src/services/beautyKnowledgeService.js
/**
 * @deprecated Fachada de compatibilidad. La recuperación canónica de Aura es
 * `ragService.searchBeautyKnowledge` → `ragPool` → `beauty_knowledge_embeddings`.
 *
 * Se conserva solo para consumidores externos que aún importan este módulo.
 * No tiene lógica propia: sin embeddings dummy, sin tabla paralela
 * (`aura_knowledge_chunks` no existe en ninguna migración) y sin pool propio.
 *
 * Port R1-R4 (2026-09-22): reemplaza la implementación legacy que devolvía
 * vectores dummy y consultaba una tabla inexistente. 0 callers en backend/src.
 */

const canonicalRag = require('./ragService');

async function searchBeautyKnowledge(query, topK = 3, threshold = 0.7) {
  return canonicalRag.searchBeautyKnowledge(query, { topK, threshold });
}

module.exports = {
  searchBeautyKnowledge,
  formatKnowledgeContext: canonicalRag.formatKnowledgeContext,
};
