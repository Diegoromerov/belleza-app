/**
 * ¿Funciona el pipeline vectorial con un modelo VIVO?
 * Prueba aislada (tabla de scratch, no toca beauty_knowledge_embeddings):
 *   1. embeddings reales de 3 documentos (input_type=passage) y de 1 consulta (query)
 *   2. similitud coseno en Postgres con el operador <=>
 *   3. ranking: ¿gana el documento correcto?
 */
const B = 'C:/beauty-app/backend';
require(B + '/node_modules/dotenv').config({ path: 'C:/beauty-app/.env' });
require(B + '/node_modules/dotenv').config({ path: B + '/.env' });
require(B + '/node_modules/dotenv').config({ path: B + '/.env.local' });

const MODELO_VIVO = 'nvidia/nemotron-3-embed-1b';
process.env.NVIDIA_EMBEDDING_MODEL = MODELO_VIVO;

const { Pool } = require(B + '/node_modules/pg');
const { generateEmbedding } = require(B + '/src/services/embeddingService');

const DOCS = [
  { id: 'd1', t: 'La niacinamida reduce los poros dilatados y regula la producción de sebo en pieles grasas.' },
  { id: 'd2', t: 'El ácido hialurónico es un humectante que retiene agua en la piel deshidratada.' },
  { id: 'd3', t: 'El retinol aumenta la renovación celular y se contraindica durante el embarazo.' },
  { id: 'd4', t: 'La normativa sanitaria exige bioseguridad y consentimiento informado en centros de estética.' },
];
const QUERY = 'tengo los poros muy abiertos y la piel grasa';
const ESPERADO = 'd1';

(async () => {
  const pool = new Pool({ connectionString: process.env.RAG_DATABASE_URL, connectionTimeoutMillis: 5000 });
  console.log('modelo solicitado:', MODELO_VIVO, '| key presente:', Boolean(process.env.NVIDIA_API_KEY));

  const OPT = { model: MODELO_VIVO, expectedDimension: 2048 }; // se relaja el gate de 1024 para medir
  const docVecs = [];
  for (const d of DOCS) {
    const v = await generateEmbedding(d.t, 'passage', OPT);
    docVecs.push({ ...d, v });
  }
  const dims = docVecs[0].v.length;
  console.log('dims de los documentos:', dims);

  const qv = await generateEmbedding(QUERY, 'query', OPT);
  console.log('dims de la consulta:', qv.length);

  await pool.query('DROP TABLE IF EXISTS zz_rag_probe');
  await pool.query(`CREATE TABLE zz_rag_probe (id text primary key, content text, embedding vector(${dims}))`);
  for (const d of docVecs) {
    await pool.query('INSERT INTO zz_rag_probe (id, content, embedding) VALUES ($1,$2,$3::vector)', [d.id, d.t, '[' + d.v.join(',') + ']']);
  }

  const { rows } = await pool.query(
    `SELECT id, 1 - (embedding <=> $1::vector) AS sim FROM zz_rag_probe ORDER BY embedding <=> $1::vector LIMIT $2`,
    ['[' + qv.join(',') + ']', DOCS.length]
  );
  console.log('\nranking por similitud coseno (consulta: "' + QUERY + '"):');
  rows.forEach((r, i) => console.log(`  ${i + 1}. ${r.id}  sim=${Number(r.sim).toFixed(4)}${r.id === ESPERADO ? '   <-- esperado' : ''}`));
  console.log('\nganador =', rows[0].id, '| correcto:', rows[0].id === ESPERADO);
  console.log('umbral de producción del repo:', 0.45, '| ganador lo supera:', Number(rows[0].sim) >= 0.45);
  console.log('separación ganador-2º:', (Number(rows[0].sim) - Number(rows[1].sim)).toFixed(4));

  await pool.query('DROP TABLE IF EXISTS zz_rag_probe');
  await pool.end();
  process.exit(0);
})().catch(e => { console.error('ERROR:', e.message); process.exit(1); });
