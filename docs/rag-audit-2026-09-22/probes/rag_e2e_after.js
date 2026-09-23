/**
 * Prueba end-to-end del aislamiento multi-tenant del RAG contra el Postgres real.
 * Inserta 3 filas de prueba (GLOBAL, TENANT_AJENO_99, BORRADO_99), ejecuta
 *   (A) el SQL VIEJO (interpolado, tal como está en origin/main) y
 *   (B) el searchBeautyKnowledge NUEVO (tenant parametrizado),
 * con el mismo payload de inyección, y compara. Limpia al final.
 */
const path = 'C:/beauty-app/backend';
require(path + '/node_modules/dotenv').config({ path: path + '/.env.local' });
require(path + '/node_modules/dotenv').config({ path: path + '/.env' });

const { Pool } = require(path + '/node_modules/pg');
const { searchBeautyKnowledge } = require(path + '/src/services/ragService');
const { ragPool } = require(path + '/src/config/db');

const PAYLOAD = "10') OR TRUE --";
const PROBE_DOC = 'zz-probe-rag-tenant';
const vec = '[' + new Array(1024).fill(0).map((_, i) => ((i % 7) + 1) / 1000).join(',') + ']';

async function main() {
  const pool = new Pool({ connectionString: process.env.RAG_DATABASE_URL, connectionTimeoutMillis: 5000 });
  console.log('BD:', (await pool.query('SELECT current_database() AS db')).rows[0].db,
              '| ragPool activo:', Boolean(ragPool), '| NVIDIA_API_KEY:', Boolean(process.env.NVIDIA_API_KEY));

  // tenant_id tiene FK a tenants(id): se usan dos tenants reales de la BD local
  const ids = (await pool.query('SELECT id FROM tenants ORDER BY id LIMIT 2')).rows.map(r => r.id);
  const [TENANT_A, TENANT_B] = ids;
  console.log('tenants usados: propio =', TENANT_A, '| ajeno/borrado =', TENANT_B);

  await pool.query(`DELETE FROM beauty_knowledge_embeddings WHERE document_id = $1`, [PROBE_DOC]);
  await pool.query(
    `INSERT INTO beauty_knowledge_embeddings
       (title, category, content, metadata, embedding, document_id, chunk_id, tenant_id, deleted_at)
     VALUES
       ('PROBE global',  'skincare', 'conocimiento global sobre niacinamida', '{}', $1::vector, $2, 'c1', NULL, NULL),
       ('PROBE propio',  'skincare', 'documento privado del tenant consultado sobre niacinamida', '{}', $1::vector, $2, 'c4', $4, NULL),
       ('PROBE ajeno',   'skincare', 'documento privado de otro tenant sobre niacinamida', '{}', $1::vector, $2, 'c2', $3, NULL),
       ('PROBE borrado', 'skincare', 'documento borrado del tenant sobre niacinamida', '{}', $1::vector, $2, 'c3', $3, NOW())`,
    [vec, PROBE_DOC, TENANT_B, TENANT_A]
  );

  // (A) SQL VIEJO: réplica literal de origin/main (backend/src/services/ragService.js:102-105)
  const oldSql = `SELECT title FROM beauty_knowledge_embeddings WHERE (tenant_id IS NULL OR tenant_id::text = '${PAYLOAD}') AND deleted_at IS NULL AND (expires_at IS NULL OR expires_at > NOW())`;
  let oldRows = [];
  try {
    oldRows = (await pool.query(oldSql)).rows;
  } catch (e) {
    console.log('SQL viejo lanzó:', e.message);
  }
  console.log('\n(A) ANTES (tenant interpolado) con tenantId =' + JSON.stringify(PAYLOAD), '->', oldRows.length, 'filas:', oldRows.map(r => r.title).join(' | '));

  // (B) CAMINO NUEVO
  const nuevo = await searchBeautyKnowledge('niacinamida', { tenantId: PAYLOAD });
  console.log('(B) DESPUÉS (tenant $param)  con tenantId =' + JSON.stringify(PAYLOAD), '->', nuevo.length, 'filas:', nuevo.map(r => r.title).join(' | '));

  const legitimo = await searchBeautyKnowledge('niacinamida', { tenantId: TENANT_A });
  console.log('(C) tenant legítimo', TENANT_A, '->', legitimo.length, 'filas:', legitimo.map(r => r.title).join(' | '));

  const global = await searchBeautyKnowledge('niacinamida');
  console.log('(D) sin tenant (chat de cliente) ->', global.length, 'filas:', global.map(r => r.title).join(' | '));

  const otro = await searchBeautyKnowledge('niacinamida', { tenantId: TENANT_B });
  console.log('(E) tenant legítimo', TENANT_B, '->', otro.length, 'filas:', otro.map(r => r.title).join(' | '));

  await pool.query(`DELETE FROM beauty_knowledge_embeddings WHERE document_id = $1`, [PROBE_DOC]);
  const { rows: [c] } = await pool.query(`SELECT count(*)::int AS n FROM beauty_knowledge_embeddings WHERE document_id = $1`, [PROBE_DOC]);
  console.log('\nlimpieza: filas de prueba restantes =', c.n);
  await pool.end();
  process.exit(0);
}
main().catch(e => { console.error('ERROR:', e.message); process.exit(1); });
