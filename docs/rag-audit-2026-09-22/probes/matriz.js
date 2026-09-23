/**
 * Matriz antes/después sobre el código REAL extraído de GitHub (no la rama de trabajo).
 *   uso: node runner.js <dir-del-codigo> [--sin-key]
 * Mide:
 *   A) ingesta  : embeddingService.generateEmbedding(texto, 'passage')
 *   B) retrieval: ragService.searchBeautyKnowledge('niacinamida')
 */
const DIR = process.argv[2];
const SIN_KEY = process.argv.includes('--sin-key');
const B = 'C:/beauty-app/backend';

require(B + '/node_modules/dotenv').config({ path: 'C:/beauty-app/.env' });
require(B + '/node_modules/dotenv').config({ path: B + '/.env.local' });
if (SIN_KEY) delete process.env.NVIDIA_API_KEY;

const { Pool } = require(B + '/node_modules/pg');
const pool = new Pool({ connectionString: process.env.RAG_DATABASE_URL, connectionTimeoutMillis: 5000 });

// require después de fijar el entorno: ambos módulos capturan la key al cargarse
const embeddingService = require(DIR + '/services/embeddingService');
const ragService = require(DIR + '/services/ragService');

const vec1024 = '[' + new Array(1024).fill(0).map((_, i) => ((i % 7) + 1) / 1000).join(',') + ']';
const DOC = 'zz-probe-matriz';

(async () => {
  console.log(`\n### ${DIR.includes('before') ? 'ANTES (main 43170150)' : 'DESPUÉS (merge #6)'} | key ${SIN_KEY ? 'AUSENTE' : 'PRESENTE'}`);

  try {
    const v = await embeddingService.generateEmbedding('La niacinamida reduce los poros dilatados.', 'passage');
    const dummy = embeddingService.generateDummyEmbedding('La niacinamida reduce los poros dilatados.');
    console.log('A) ingesta    -> vector de', v.length, 'dims | ¿es DUMMY fabricado?', JSON.stringify(v) === JSON.stringify(dummy), '| error: NO');
  } catch (e) {
    console.log('A) ingesta    -> LANZÓ error:', e.message.slice(0, 60));
  }

  await pool.query(`DELETE FROM beauty_knowledge_embeddings WHERE document_id = $1`, [DOC]);
  await pool.query(
    `INSERT INTO beauty_knowledge_embeddings (title, category, content, metadata, embedding, document_id, chunk_id)
     VALUES ('PROBE', 'skincare', 'conocimiento sobre niacinamida y poros', '{}', $1::vector, $2, 'k1')`,
    [vec1024, DOC]
  );

  const r = await ragService.searchBeautyKnowledge('niacinamida', { tenantId: null });
  console.log('B) retrieval  -> filas:', r.length, '| similitud:', r.map(x => x.similarity).join(',') || '(ninguna)',
              r.length === 0 ? '| NO hay fallback -> Aura sin conocimiento' :
              (r[0].similarity === 0.5 ? '| FTS (degradado pero funcionando)' : '| vectorial'));

  await pool.query(`DELETE FROM beauty_knowledge_embeddings WHERE document_id = $1`, [DOC]);
  await pool.end();
  process.exit(0);
})().catch(e => { console.error('ERROR:', e.message); process.exit(1); });
