#!/usr/bin/env node
/**
 * backend/scripts/ingestCanonicalCorpus.js
 * RAG FASE 1 — Ingesta e Idempotencia del CORPUS CANÓNICO en BD local
 * Lee corpus_canonico.json y realiza upsert idempotente con ON CONFLICT (document_id, chunk_id)
 * Genera embeddings NVIDIA reales (passage, 2048-dim por defecto para nemotron-3-embed-1b)
 *
 * Uso: node scripts/ingestCanonicalCorpus.js [--limit=N] [--dry-run] [--batch-size=N]
 */

require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { ragPool } = require('../src/config/db');

const CORPUS_PATH = path.join(__dirname, '..', 'src', 'data', 'corpus_canonico', 'corpus_canonico.json');
const NVIDIA_API_KEY = process.env.NVIDIA_API_KEY;
const NVIDIA_API_URL = process.env.NVIDIA_API_URL || 'https://integrate.api.nvidia.com/v1/embeddings';
const NVIDIA_EMBEDDING_MODEL = process.env.NVIDIA_EMBEDDING_MODEL || 'nvidia/nemotron-3-embed-1b';
const EXPECTED_DIMS = parseInt(process.env.NVIDIA_EMBEDDING_DIMS || '2048', 10);
const DELAY_MS = 50; // rate limiting entre lotes

async function generateEmbedding(text) {
  const MAX_EMBED_CHARS = 1400;
  const embeddingText = text.length > MAX_EMBED_CHARS ? text.substring(0, MAX_EMBED_CHARS) : text;
  const response = await fetch(NVIDIA_API_URL, {
    method: 'POST',
    headers: {
      'Authorization': 'Bearer ' + NVIDIA_API_KEY,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: NVIDIA_EMBEDDING_MODEL,
      input: [embeddingText],
      input_type: 'passage',
      encoding_format: 'float',
    }),
  });
  if (!response.ok) {
    const errText = await response.text();
    throw new Error('NVIDIA API ' + response.status + ': ' + errText.substring(0, 200));
  }
  const data = await response.json();
  const emb = data.data && data.data[0] && data.data[0].embedding;
  if (!emb || emb.length !== EXPECTED_DIMS) {
    throw new Error(`Embedding con dimensiones incorrectas: esperado ${EXPECTED_DIMS}, recibido ${emb ? emb.length : 0}`);
  }
  return emb;
}

async function upsertChunk(chunk, dryRun) {
  const is2048 = EXPECTED_DIMS === 2048;
  const targetCol = is2048 ? 'embedding_next' : 'embedding';
  
  const sql = `
    INSERT INTO beauty_knowledge_embeddings
    (title, category, content, metadata, ${targetCol}, document_id, document_version, chunk_id, content_hash, fuente, seccion, created_at)
    VALUES ($1, $2, $3, $4, $5::vector, $6, $7, $8, $9, $10, $11, NOW())
    ON CONFLICT (document_id, chunk_id) DO UPDATE SET
      title = EXCLUDED.title,
      category = EXCLUDED.category,
      content = EXCLUDED.content,
      metadata = EXCLUDED.metadata,
      ${targetCol} = EXCLUDED.${targetCol},
      content_hash = EXCLUDED.content_hash,
      fuente = EXCLUDED.fuente,
      seccion = EXCLUDED.seccion
    RETURNING (xmax = 0) AS inserted;
  `;
  const params = [
    chunk.title || '',
    chunk.category || 'general',
    chunk.content || '',
    JSON.stringify(chunk.metadata || {}),
    '[' + (chunk.embedding).join(',') + ']',
    chunk.document_id,
    chunk.document_version || '1.0',
    chunk.chunk_id,
    chunk.content_hash,
    chunk.fuente || 'unknown',
    chunk.seccion || 'unknown',
  ];
  const res = await ragPool.query(sql, params);
  return res.rows[0].inserted ? 'inserted' : 'updated';
}

async function main() {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run');
  const limitArg = args.find(a => a.startsWith('--limit='));
  const limit = limitArg ? parseInt(limitArg.split('=')[1], 10) : null;
  const batchArg = args.find(a => a.startsWith('--batch-size='));
  const batchSize = batchArg ? parseInt(batchArg.split('=')[1], 10) : 16;

  // ── SEGURIDAD: abortar si RAG_DATABASE_URL apunta a producción ──
  const ragUrl = process.env.RAG_DATABASE_URL || '';
  if (!ragUrl) {
    console.error('🚫 RAG_DATABASE_URL no está definida. Abortando (seguridad).');
    process.exit(1);
  }
  const isLocal = ragUrl.includes('localhost') || ragUrl.includes('127.0.0.1') || ragUrl.includes('0.0.0.0');
  if (!isLocal) {
    console.error('🚫 RAG_DATABASE_URL NO apunta a BD LOCAL. Abortando ingesta (seguridad).');
    console.error(`   Host detectado: ${ragUrl.replace(/\/\/.*@/, '//***@')}`);
    process.exit(1);
  }
  console.log('✅ RAG_DATABASE_URL LOCAL verificada — ingesta permitida');
  console.log(`🤖 Modelo: ${NVIDIA_EMBEDDING_MODEL} (${EXPECTED_DIMS} dims)`);

  if (!dryRun && !NVIDIA_API_KEY) {
    console.error('❌ Falta NVIDIA_API_KEY');
    process.exit(1);
  }
  if (!fs.existsSync(CORPUS_PATH)) {
    console.error('❌ No existe corpus canónico: ' + CORPUS_PATH);
    process.exit(1);
  }

  const corpus = JSON.parse(fs.readFileSync(CORPUS_PATH, 'utf8'));
  let chunks = corpus.chunks;
  if (limit) chunks = chunks.slice(0, limit);

  console.log(`🚀 Ingesta corpus canónico: ${chunks.length} chunks (dry-run: ${dryRun}, batchSize: ${batchSize})`);
  const before = await ragPool.query('SELECT COUNT(*)::int AS c FROM beauty_knowledge_embeddings');
  console.log(`   Chunks en BD antes: ${before.rows[0].c}`);

  let inserted = 0, updated = 0, errors = 0;
  const startTime = Date.now();

  for (let i = 0; i < chunks.length; i += batchSize) {
    const batch = chunks.slice(i, i + batchSize);
    
    await Promise.all(batch.map(async (c) => {
      try {
        if (dryRun) {
          console.log(`[DRY] ${c.chunk_id}`);
          inserted++;
          return;
        }
        const embedding = await generateEmbedding((c.title || '') + '\n\n' + (c.content || '').substring(0, 4000));
        const result = await upsertChunk({ ...c, embedding }, dryRun);
        if (result === 'inserted') inserted++; else updated++;
      } catch (err) {
        errors++;
        console.error(`   ❌ ${c.chunk_id}: ${err.message}`);
      }
    }));

    const processed = Math.min(i + batchSize, chunks.length);
    if (processed % 50 === 0 || processed === chunks.length) {
      const elapsed = ((Date.now() - startTime) / 1000).toFixed(0);
      console.log(`   [${processed}/${chunks.length}] +${inserted} ~${updated} err=${errors} (${elapsed}s)`);
    }
    
    if (i + batchSize < chunks.length) {
      await new Promise(r => setTimeout(r, DELAY_MS));
    }
  }

  const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
  const after = await ragPool.query('SELECT COUNT(*)::int AS c FROM beauty_knowledge_embeddings');
  console.log('\n' + '='.repeat(50));
  console.log('📊 RESUMEN INGESTA CORPUS CANÓNICO (FASE 1)');
  console.log('   Chunks procesados: ' + chunks.length);
  console.log('   Insertados: ' + inserted);
  console.log('   Actualizados: ' + updated);
  console.log('   Errores: ' + errors);
  console.log('   Tiempo: ' + elapsed + 's');
  console.log('   Chunks en BD después: ' + after.rows[0].c);
  console.log('='.repeat(50));
  process.exit(errors > 0 ? 2 : 0);
}

main().catch(e => { console.error('❌ Fatal:', e.message); process.exit(1); });
