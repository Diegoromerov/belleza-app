#!/usr/bin/env node
/** Canonical, reproducible Aura RAG ingestion for beauty_knowledge_embeddings. */

require('dotenv').config();
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { ragPool } = require('../src/config/db');
const { processDocumentWithFrontmatter } = require('../src/services/chunkingService');
const { generateEmbedding } = require('../src/services/embeddingService');

function sha256(value) {
  return crypto.createHash('sha256').update(value, 'utf8').digest('hex');
}

function parseArgs() {
  const parsed = { source: 'corpus', dryRun: false, verbose: false };
  for (const arg of process.argv.slice(2)) {
    if (arg === '--dry-run') parsed.dryRun = true;
    else if (arg === '--verbose') parsed.verbose = true;
    else if (arg.startsWith('--source=')) parsed.source = arg.slice('--source='.length);
  }
  return parsed;
}

function parseMarkdownFile(filePath) {
  const rawContent = fs.readFileSync(filePath, 'utf8');
  const match = rawContent.match(/^---\n([\s\S]*?)\n---\s*/);
  const metadata = {};
  if (match) {
    for (const line of match[1].split('\n')) {
      const separator = line.indexOf(':');
      if (separator > 0) {
        metadata[line.slice(0, separator).trim()] = line.slice(separator + 1).trim().replace(/^['"]|['"]$/g, '');
      }
    }
  }
  return { filePath, rawContent, content: rawContent, metadata };
}

function readCorpus(corpusDir) {
  return fs.readdirSync(corpusDir)
    .filter((file) => file.endsWith('.md') || file.endsWith('.txt'))
    .sort()
    .map((file) => parseMarkdownFile(path.join(corpusDir, file)));
}

function createChunkIdentity(doc, chunk, corpusDir) {
  const relativePath = path.relative(corpusDir, doc.filePath).replace(/\\/g, '/');
  const fuente = doc.metadata.source || relativePath;
  const documentId = sha256(relativePath);
  const documentVersion = doc.metadata.document_version || doc.metadata.version || sha256(doc.rawContent);
  const contentHash = sha256(chunk.content.trim().replace(/\s+/g, ' '));
  const chunkId = sha256(`${documentId}:${documentVersion}:${chunk.index}:${contentHash}`);
  return {
    documentId,
    documentVersion,
    chunkId,
    contentHash,
    fuente,
    seccion: chunk.sectionTitle || doc.metadata.section || 'unknown',
  };
}

async function processDocument(doc, { corpusDir, verbose }) {
  if (doc.content.trim().length < 50) return { chunks: [], errors: 1 };
  const rawChunks = processDocumentWithFrontmatter(doc.content, {
    maxTokens: 600, overlapTokens: 50, respectSentences: true, respectParagraphs: true,
  });
  const chunks = [];
  let errors = 0;
  for (const chunk of rawChunks) {
    try {
      const metadata = chunk.metadata || {};
      const identity = createChunkIdentity(doc, chunk, corpusDir);
      const embedding = await generateEmbedding(chunk.content, 'passage');
      chunks.push({
        title: `${metadata.title || path.basename(doc.filePath)} - Parte ${chunk.index + 1}`,
        category: metadata.category || 'unknown', content: chunk.content, embedding,
        metadata: { ...metadata, chunkIndex: chunk.index, totalChunks: chunk.totalChunks, sectionTitle: chunk.sectionTitle },
        skinType: metadata.skin_type || null, seasonStation: metadata.season_station || null,
        ageRange: metadata.age_range || null, ingredients: metadata.ingredients || null,
        contraindications: metadata.contraindications || null, ...identity,
      });
    } catch (error) {
      errors++;
      console.error(`❌ Embedding failed for ${path.basename(doc.filePath)} chunk ${chunk.index + 1}: ${error.message}`);
    }
  }
  if (verbose) console.log(`   ${rawChunks.length} chunks, ${errors} embedding errors`);
  return { chunks, errors };
}

async function upsertChunks(chunks, dryRun = false) {
  const result = { inserted: 0, updated: 0, duplicatesDetected: 0, duplicatesAvoided: 0, errors: 0 };
  for (const chunk of chunks) {
    if (dryRun) continue;
    try {
      const sql = `
        INSERT INTO beauty_knowledge_embeddings
          (title, category, content, metadata, embedding, skin_type, season_station, age_range, ingredients, contraindications,
           document_id, document_version, chunk_id, content_hash, fuente, seccion)
        VALUES ($1, $2, $3, $4::jsonb, $5::vector, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
        ON CONFLICT (document_id, document_version, chunk_id) DO UPDATE SET
          title = EXCLUDED.title, category = EXCLUDED.category, content = EXCLUDED.content, metadata = EXCLUDED.metadata,
          embedding = EXCLUDED.embedding, skin_type = EXCLUDED.skin_type, season_station = EXCLUDED.season_station,
          age_range = EXCLUDED.age_range, ingredients = EXCLUDED.ingredients, contraindications = EXCLUDED.contraindications,
          content_hash = EXCLUDED.content_hash, fuente = EXCLUDED.fuente, seccion = EXCLUDED.seccion, updated_at = NOW()
        RETURNING (xmax = 0) AS inserted;`;
      const values = [chunk.title, chunk.category, chunk.content, JSON.stringify(chunk.metadata), `[${chunk.embedding.join(',')}]`,
        chunk.skinType, chunk.seasonStation, chunk.ageRange, chunk.ingredients, chunk.contraindications,
        chunk.documentId, chunk.documentVersion, chunk.chunkId, chunk.contentHash, chunk.fuente, chunk.seccion];
      const response = await ragPool.query(sql, values);
      if (response.rows[0].inserted) result.inserted++;
      else { result.updated++; result.duplicatesDetected++; result.duplicatesAvoided++; }
    } catch (error) {
      result.errors++;
      console.error(`❌ Upsert failed for ${chunk.chunkId}: ${error.message}`);
    }
  }
  return result;
}

async function main() {
  const args = parseArgs();
  if (args.source !== 'corpus') throw new Error('Only the canonical --source=corpus is supported. Historical SQL ingestion is not an active writer.');
  if (!ragPool) throw new Error('RAG_DATABASE_URL is required; ingestion never falls back to DATABASE_URL/pool.');
  const corpusDir = path.join(__dirname, '..', 'src', 'data', 'beauty_corpus');
  const documents = readCorpus(corpusDir);
  const stats = { documentsProcessed: documents.length, documentsSuccessful: 0, documentsWithError: 0, chunksGenerated: 0,
    chunksInserted: 0, chunksUpdated: 0, duplicatesDetected: 0, duplicatesAvoided: 0, embeddingsGenerated: 0,
    embeddingsFailed: 0, upsertErrors: 0 };
  const start = Date.now();
  for (const doc of documents) {
    const processed = await processDocument(doc, { corpusDir, verbose: args.verbose });
    stats.chunksGenerated += processed.chunks.length + processed.errors;
    stats.embeddingsGenerated += processed.chunks.length;
    stats.embeddingsFailed += processed.errors;
    const writes = await upsertChunks(processed.chunks, args.dryRun);
    stats.chunksInserted += writes.inserted;
    stats.chunksUpdated += writes.updated;
    stats.duplicatesDetected += writes.duplicatesDetected;
    stats.duplicatesAvoided += writes.duplicatesAvoided;
    stats.upsertErrors += writes.errors;
    if (processed.errors || writes.errors) stats.documentsWithError++; else stats.documentsSuccessful++;
  }
  stats.durationSeconds = Number(((Date.now() - start) / 1000).toFixed(1));
  console.log(JSON.stringify({ ...stats, errorsTotal: stats.embeddingsFailed + stats.upsertErrors, dryRun: args.dryRun }, null, 2));
  if (stats.embeddingsFailed || stats.upsertErrors) process.exitCode = 1;
  return stats;
}

if (require.main === module) main().catch((error) => { console.error(`❌ Ingestion failed: ${error.message}`); process.exitCode = 1; });

module.exports = { parseArgs, readCorpus, parseMarkdownFile, createChunkIdentity, processDocument, upsertChunks, main };
