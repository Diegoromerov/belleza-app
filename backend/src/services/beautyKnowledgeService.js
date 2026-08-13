/**
 * @deprecated Aura's canonical retrieval is ragService ->
 * beauty_knowledge_embeddings. Kept solely as a compatibility facade for
 * external consumers that have not yet migrated their import.
 */

const canonicalRag = require('./ragService');

async function searchBeautyKnowledge(query, topK = 3, threshold = 0.7) {
  return canonicalRag.searchBeautyKnowledge(query, { topK, threshold });
}

module.exports = {
  searchBeautyKnowledge,
  formatKnowledgeContext: canonicalRag.formatKnowledgeContext,
};
