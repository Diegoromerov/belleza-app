/**
 * Ejecuta el código REAL de origin/main (extraído con git show, no la rama del PR)
 * con la key NVIDIA real, para separar los dos caminos:
 *   A) ingesta  -> embeddingService.generateEmbedding(..., 'passage')
 *   B) retrieval -> ragService.searchBeautyKnowledge(...)  CON key
 *   C) retrieval -> ragService.searchBeautyKnowledge(...)  SIN key
 */
const SCR = 'C:/Users/Compu casa/AppData/Local/hermes/cache/scratch/maincode';
const B = 'C:/beauty-app/backend';
require(B + '/node_modules/dotenv').config({ path: 'C:/beauty-app/.env' });
require(B + '/node_modules/dotenv').config({ path: B + '/.env.local' });

const CLAVE_REAL = process.env.NVIDIA_API_KEY;
const { Pool } = require(B + '/node_modules/pg');
const { pool } = require(SCR + '/config/db');
const embeddingService = require(SCR + '/services/embeddingService');
const ragService = require(SCR + '/services/ragService');

const vec1024 = '[' + new Array(1024).fill(0).map((_, i) => ((i % 7) + 1) / 1000).join(',') + ']';
const DOC = 'zz-probe-main-ingesta';

(async () => {
  console.log('=== A) INGESTA con key real y modelo retirado (embeddingService de origin/main) ===');
  process.env.NVIDIA_API_KEY = CLAVE_REAL;
  try {
    const v = await embeddingService.generateEmbedding('La niacinamida reduce los poros dilatados.', 'passage');
    const dummy = embeddingService.generateDummyEmbedding('La niacinamida reduce los poros dilatados.');
    const esDummy = JSON.stringify(v) === JSON.stringify(dummy);
    console.log('  resultado: vector de', v.length, 'dims | ¿es el DUMMY fabricado?', esDummy, '| ¿lanzó error? NO');
  } catch (e) {
    console.log('  resultado: LANZÓ error ->', e.message);
  }

  // fila de prueba para el retrieval
  await pool.query(`DELETE FROM beauty_knowledge_embeddings WHERE document_id = $1`, [DOC]);
  await pool.query(
    `INSERT INTO beauty_knowledge_embeddings (title, category, content, metadata, embedding, document_id, chunk_id)
     VALUES ('PROBE main', 'skincare', 'conocimiento sobre niacinamida y poros', '{}', $1::vector, $2, 'k1')`,
    [vec1024, DOC]
  );

  console.log('\n=== B) RETRIEVAL con key real y modelo retirado (ragService de origin/main) ===');
  process.env.NVIDIA_API_KEY = CLAVE_REAL;
  const conKey = await ragService.searchBeautyKnowledge('niacinamida', { tenantId: null });
  console.log('  filas:', conKey.length, '| similarity:', conKey.map(r => r.similarity).join(','), '(0.5 == fallback full-text)');

  console.log('\n=== C) RETRIEVAL sin key (ragService de origin/main) ===');
  delete process.env.NVIDIA_API_KEY;
  const sinKey = await ragService.searchBeautyKnowledge('niacinamida', { tenantId: null });
  console.log('  filas:', sinKey.length, '| similarity:', sinKey.map(r => r.similarity).join(',') || '(ninguna)');

  await pool.query(`DELETE FROM beauty_knowledge_embeddings WHERE document_id = $1`, [DOC]);
  const { rows: [{ n }] } = await pool.query(`SELECT count(*)::int AS n FROM beauty_knowledge_embeddings WHERE document_id = $1`, [DOC]);
  console.log('\nlimpieza: filas de prueba restantes =', n);
  await pool.end();
  process.exit(0);
})().catch(e => { console.error('ERROR:', e.message); process.exit(1); });
