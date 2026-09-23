/**
 * VERIFICACIÓN FASE 1 contra Postgres real.
 * Compara el ragService de main (antes) con el de la Fase 1 (después) sobre las MISMAS filas
 * de prueba, para cada filtro que "apagaba" el retrieval.
 *
 * El embedding es sintético (vector unitario (1,0,0,...) de 1024 d) porque el modelo real de
 * 1024 dims está retirado: aquí se verifica el comportamiento de los FILTROS y de las CITAS,
 * no el ranking (eso es Fase 0/2). El umbral se pone en -1 para que no interfiera.
 *
 * Uso: node "…/probe_fase1.js"   (crea y borra sus propias filas: document_id 'zz-fase1-probe')
 */
const B = 'C:/beauty-app/backend';
require(B + '/node_modules/dotenv').config({ path: B + '/.env.local' });
require(B + '/node_modules/dotenv').config({ path: B + '/.env' });

// config/db crea `ragPool` desde RAG_DATABASE_URL (pool REAL, sin fallback a memoria) y
// `pool` desde DATABASE_URL. Se alinean para que la preparación y la limpieza usen la
// misma base que el retrieval: el fallback en memoria serviría datos fabricados.
process.env.DATABASE_URL = process.env.RAG_DATABASE_URL || process.env.DATABASE_URL;
if (!process.env.DATABASE_URL) {
  console.error('FALLO: falta RAG_DATABASE_URL/DATABASE_URL (se aborta para no medir contra memoria fabricada)');
  process.exit(1);
}

const path = require('path');
const DIMS = 1024;
const vec = () => { const v = new Array(DIMS).fill(0); v[0] = 1; return v; };

function stubEmbedding() {
  const embPath = require.resolve(B + '/src/services/embeddingService');
  require.cache[embPath] = {
    id: embPath, filename: embPath, loaded: true, exports: {
      generateEmbedding: async () => vec(),
      generateNvidiaEmbedding: async () => vec(),
    },
  };
}

const FILAS = [
  // document_id común para poder limpiar; categorías y metadata reales del corpus
  { cat: 'guias_unas', skin: ['all'], titulo: 'Esmaltado semipermanente', fuente: 'canon/guias_unas', seccion: 'tecnicas' },
  { cat: 'guias_unas', skin: ['all'], titulo: 'Cuidado de cutícula', fuente: 'canon/guias_unas', seccion: 'cuidado' },
  { cat: 'diagnostico_capilar', skin: ['seca'], titulo: 'Porosidad del cabello seco', fuente: 'canon/diagnostico_capilar', seccion: 'diagnostico' },
  { cat: 'diagnostico_capilar', skin: ['seca'], titulo: 'Frizz en cabello seco', fuente: 'canon/diagnostico_capilar', seccion: 'diagnostico' },
  { cat: 'textura_poros', skin: ['grasa'], titulo: 'Poros dilatados en piel grasa', fuente: 'canon/textura_poros', seccion: 'fisiologia' },
];

(async () => {
  const { pool } = require(B + '/src/config/db');
  const pgVec = `[${vec().join(',')}]`;
  const out = [];

  // ── preparación: filas de prueba (identificables y borrables) ──────────────
  await pool.query(`DELETE FROM beauty_knowledge_embeddings WHERE document_id = 'zz-fase1-probe'`);
  for (let i = 0; i < FILAS.length; i++) {
    const f = FILAS[i];
    await pool.query(
      `INSERT INTO beauty_knowledge_embeddings
        (title, category, content, metadata, embedding, document_id, document_version, chunk_id, content_hash, fuente, seccion)
       VALUES ($1,$2,$3,$4::jsonb,$5::vector,'zz-fase1-probe','1.0',$6,$7,$8,$9)`,
      [f.titulo, f.cat, `Contenido de ${f.titulo}`, JSON.stringify({ skin_types: f.skin, applicable_modules: [f.cat] }), pgVec, `zz-fase1-chunk-${i}`, `hash-${i}`, f.fuente, f.seccion]
    );
  }
  const { rows: [{ n: total }] } = await pool.query(`SELECT COUNT(*)::int AS n FROM beauty_knowledge_embeddings WHERE document_id = 'zz-fase1-probe'`);
  console.log(`Filas de prueba cargadas: ${total} (note que la columna skin_type queda NULL, igual que la ingesta canónica)\n`);

  stubEmbedding();

  // ── ANTES: ragService de origin/main (cfa99da3) ────────────────────────────
  const antes = require(B + '/src/services/_oldRagServiceProbe.js');
  console.log('════ ANTES (código de main) ════');
  for (const [nombre, opts] of [
    ["category='Piel'", { filters: { category: 'Piel' } }],
    ["category='Uñas'", { filters: { category: 'Uñas' } }],
    ["skin_type='seca'", { filters: { skin_type: 'seca' } }],
    ["domain='BUSINESS'", { filters: { domain: 'BUSINESS' } }],
    ["sin filtros", {}],
  ]) {
    const r = await antes.searchBeautyKnowledge('poros', { threshold: -1, ...opts });
    console.log(`  ${nombre.padEnd(20)} → ${String(r.length).padStart(2)} chunks`);
    out.push({ antes: nombre, chunks: r.length });
  }

  // ── DESPUÉS: ragService de la Fase 1 (con traza) ───────────────────────────
  const despues = require(B + '/src/services/ragService.js');
  console.log('\n════ DESPUÉS (Fase 1) ════');
  const detalle = [];
  for (const [nombre, opts] of [
    ["category='Piel'", { filters: { category: 'Piel' } }],
    ["category='Uñas'", { filters: { category: 'Uñas' } }],
    ["category='guias_unas'", { filters: { category: 'guias_unas' } }],
    ["category='Guías Uñas'", { filters: { category: 'Guías Uñas' } }],
    ["skin_type='seca'", { filters: { skin_type: 'seca' } }],
    ["skin_type='grasa'", { filters: { skin_type: 'grasa' } }],
    ["domain='diagnostico_capilar'", { filters: { domain: 'diagnostico_capilar' } }],
    ["domain='BUSINESS'", { filters: { domain: 'BUSINESS' } }],
    ["sin filtros", {}],
  ]) {
    const trace = {};
    const r = await despues.searchBeautyKnowledge('poros', { threshold: -1, trace, ...opts });
    const cats = [...new Set(r.map(x => x.category))].join(',') || '—';
    console.log(`  ${nombre.padEnd(28)} → ${String(r.length).padStart(2)} chunks  [${cats}]  dropped=${JSON.stringify(trace.filters_dropped || [])}  relaxed=${trace.filters_relaxed === true}`);
    detalle.push({ caso: nombre, chunks: r.length, categorias: cats, dropped: trace.filters_dropped || [], relaxed: trace.filters_relaxed === true, modo: trace.mode });
  }

  // ── Citas con datos reales ────────────────────────────────────────────────
  const rCita = await despues.searchBeautyKnowledge('poros', { threshold: -1, filters: { category: 'guias_unas' } });
  const cita = despues.formatKnowledgeContext(rCita);
  console.log('\n════ CITA GENERADA ════');
  console.log(cita.split('\n').slice(0, 3).join('\n'));

  // ── limpieza ─────────────────────────────────────────────────────────────
  const del = await pool.query(`DELETE FROM beauty_knowledge_embeddings WHERE document_id = 'zz-fase1-probe'`);
  const { rows: [{ n: quedan }] } = await pool.query(`SELECT COUNT(*)::int AS n FROM beauty_knowledge_embeddings WHERE document_id = 'zz-fase1-probe'`);
  console.log(`\nLimpieza: ${del.rowCount} filas borradas, quedan ${quedan}`);
  console.log('EVIDENCIA_JSON ' + JSON.stringify({ antes: out, despues: detalle, cita_valida: /Fuente: canon\/guias_unas/.test(cita) && /\[Chunk: zz-fase1-chunk-/.test(cita) }));
  await pool.end();
})().catch(async (e) => { console.error('FALLO:', e.message); process.exit(1); });
