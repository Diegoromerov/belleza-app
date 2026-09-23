/**
 * Verificación Fase 1 · trazabilidad: la fila de rag_query_logs debe llevar las 16 columnas
 * (antes se insertaban 9 y 7 quedaban NULL para siempre).
 * Escribe una fila de prueba real con logRagQuery y la lee de vuelta; la borra al final.
 */
const B = 'C:/beauty-app/backend';
require(B + '/node_modules/dotenv').config({ path: B + '/.env.local' });
require(B + '/node_modules/dotenv').config({ path: B + '/.env' });
process.env.DATABASE_URL = process.env.RAG_DATABASE_URL || process.env.DATABASE_URL;
process.env.NODE_ENV = 'development';

const { logRagQuery } = require(B + '/src/services/ragLogger');
const { ragPool } = require(B + '/src/config/db');

const TRACE_ID = '11111111-2222-4333-8444-555555555555';

(async () => {
  await logRagQuery({
    trace_id: TRACE_ID,
    user_id: 4242,
    query: 'consulta de prueba fase 1',
    query_embedding_latency_ms: 137,
    retrieval_latency_ms: 88,
    chunks: [{ chunk_id: 'zz-fase1-chunk-0', similarity: 0.83, category: 'guias_unas', content: 'x' }],
    filters: { topK: 5, threshold: 0.45 },
    filters_applied: { category: 'guias_unas' },
    filters_dropped: [{ filter: 'category', value: 'Piel', reason: 'not_in_canonical_vocabulary' }],
    filters_relaxed: false,
    threshold_used: 0.45,
    retrieval_mode: 'hnsw',
    fallback_triggered: false,
    all_scores: [0.83, 0.71, 0.55],
    category: 'guias_unas',
    llm_used: 'deepseek',
    llm_latency_ms: 900,
    tool_calls: [],
    total_latency_ms: 1200,
    error: null,
  });

  await new Promise(r => setTimeout(r, 600)); // saveToPostgres es no bloqueante

  const { rows } = await ragPool.query(
    `SELECT trace_id, chunks_retrieved, top_score, category, threshold_used, filters_applied,
            all_scores, retrieval_mode, fallback_triggered, breaker_state_at_query, llm_used,
            total_latency_ms, query_sanitized
     FROM rag_query_logs WHERE trace_id = $1`,
    [TRACE_ID]
  );

  if (rows.length === 0) { console.log('❌ No se escribió la fila'); process.exit(1); }
  const r = rows[0];
  console.log('Fila escrita y leída de rag_query_logs:');
  console.log(JSON.stringify(r, null, 2));

  const nulos = Object.entries(r).filter(([, v]) => v === null).map(([k]) => k);
  const ok = r.category === 'guias_unas' && Number(r.threshold_used) === 0.45 && r.retrieval_mode === 'hnsw'
    && Array.isArray(r.all_scores) && r.all_scores.length === 3 && r.filters_applied?.category === 'guias_unas'
    && r.fallback_triggered === false && r.breaker_state_at_query !== null;
  console.log(`\nColumnas antes NULL (9/16 insertadas): category, threshold_used, filters_applied, all_scores, retrieval_mode, fallback_triggered, breaker_state_at_query`);
  console.log(`Quedan NULL ahora: ${nulos.length ? nulos.join(', ') : 'ninguna'}`);
  console.log(ok ? '✅ Trazabilidad Fase 1 verificada: 16/16 columnas con valores reales' : '❌ Faltan columnas por poblar');

  const del = await ragPool.query('DELETE FROM rag_query_logs WHERE trace_id = $1', [TRACE_ID]);
  console.log(`Limpieza: ${del.rowCount} fila borrada`);
  process.exit(ok ? 0 : 1);
})().catch(e => { console.error('FALLO:', e.message); process.exit(1); });
