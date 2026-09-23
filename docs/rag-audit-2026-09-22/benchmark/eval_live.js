/**
 * EVAL RAG con el modelo VIVO (nvidia/nemotron-3-embed-1b) sobre el corpus canónico completo.
 * - Réplica exacta del texto que embebe la ingesta: (title + '\n\n' + content).slice(0, 1400)
 * - Embeddings en LOTE (64 por llamada), normalizados → coseno = producto punto
 * - Métricas sobre el dataset alineado v2: R@1/5/10/50, MRR@10, misses
 * - Comparativas: vector puro | BM25 léxico | híbrido RRF(vec, bm25)
 * - Calibración de umbral: distribución de similitud de los gold vs los no-gold
 * NO escribe en la base de datos: todo en memoria.
 */
const B = 'C:/beauty-app/backend';
require(B + '/node_modules/dotenv').config({ path: 'C:/beauty-app/.env' });
const fs = require('fs');

const URL = 'https://integrate.api.nvidia.com/v1/embeddings';
const MODEL = process.env.NVIDIA_EMBEDDING_MODEL_LIVE || 'nvidia/nemotron-3-embed-1b';
const KEY = process.env.NVIDIA_API_KEY;
const BATCH = 64;
const MAX_CHARS = 1400;

const OUT = 'C:/Users/Compu casa/AppData/Local/hermes/cache/scratch/eval_live_result.json';
const corpus = require(B + '/src/data/corpus_canonico/corpus_canonico.json').chunks;
const dataset = require(B + '/src/data/eval/evaluation_dataset_v2.json').queries;

const t0 = Date.now();
const log = (...a) => console.log(`[${((Date.now() - t0) / 1000).toFixed(0)}s]`, ...a);

async function embed(inputs, inputType) {
  for (let intento = 1; intento <= 4; intento++) {
    try {
      const r = await fetch(URL, {
        method: 'POST',
        headers: { Authorization: 'Bearer ' + KEY, 'Content-Type': 'application/json' },
        body: JSON.stringify({ input: inputs, model: MODEL, input_type: inputType, encoding_format: 'float' }),
      });
      if (!r.ok) throw new Error('HTTP ' + r.status + ' ' + (await r.text()).slice(0, 160));
      const j = await r.json();
      const embs = (j.data || []).map((d) => d.embedding);
      if (embs.length !== inputs.length) throw new Error(`lote incompleto: ${embs.length}/${inputs.length}`);
      return embs;
    } catch (e) {
      if (intento === 4) throw e;
      await new Promise((res) => setTimeout(res, 1500 * intento));
    }
  }
}

(async () => {
  log(`corpus=${corpus.length} chunks | queries=${dataset.length} | modelo=${MODEL}`);

  // ---------- 1. embeddings del corpus (en lote) ----------
  const textos = corpus.map((c) => ((c.title || '') + '\n\n' + (c.content || '')).slice(0, 4000).slice(0, MAX_CHARS));
  const truncados = corpus.map((c) => (c.title || '').length + 2 + (c.content || '').length).filter((n) => n > MAX_CHARS).length;

  const dims = 2048;
  const M = new Float32Array(corpus.length * dims);
  let llamadas = 0;
  const tEmb = Date.now();
  for (let i = 0; i < textos.length; i += BATCH) {
    const lote = textos.slice(i, i + BATCH);
    const embs = await embed(lote, 'passage');
    llamadas++;
    embs.forEach((e, k) => {
      if (e.length !== dims) throw new Error('dims ' + e.length);
      let n = 0;
      for (const v of e) n += v * v;
      n = Math.sqrt(n);
      for (let d = 0; d < dims; d++) M[(i + k) * dims + d] = e[d] / n;
    });
    if (llamadas % 10 === 0) log(`  embeddings ${i + lote.length}/${textos.length} (${llamadas} llamadas)`);
  }
  const msEmb = Date.now() - tEmb;
  log(`corpus embebido: ${llamadas} llamadas, ${(msEmb / 1000).toFixed(1)}s total, ${(msEmb / corpus.length).toFixed(0)}ms por chunk`);

  // ---------- 2. BM25 léxico (para el híbrido) ----------
  const stop = new Set('de la el los las un una unos unas y o que en para por con sin al del a los se su sus es son como más mas pero si no ni lo le mi tu yo te'.split(' '));
  const tok = (s) => (s || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').split(/[^a-z0-9]+/).filter((w) => w.length > 2 && !stop.has(w));
  const docsTok = textos.map(tok);
  const avgdl = docsTok.reduce((a, d) => a + d.length, 0) / docsTok.length;
  const df = new Map();
  docsTok.forEach((d) => new Set(d).forEach((w) => df.set(w, (df.get(w) || 0) + 1)));
  const idf = (w) => Math.log(1 + (docsTok.length - (df.get(w) || 0) + 0.5) / ((df.get(w) || 0) + 0.5));

  // ---------- 3. queries ----------
  const usables = dataset.filter((q) => Array.isArray(q.expected_chunks) && q.expected_chunks.length);
  const qEmbs = [];
  for (let i = 0; i < usables.length; i += BATCH) {
    const lote = usables.slice(i, i + BATCH).map((q) => q.query);
    qEmbs.push(...(await embed(lote, 'query')));
  }
  log(`queries embebidas: ${usables.length} (de ${dataset.length}; ${dataset.length - usables.length} sin gold = UNSUPPORTED_BY_CORPUS)`);

  // ---------- 4. ranking y métricas ----------
  const idxById = new Map(corpus.map((c, i) => [String(c.chunk_id), i]));
  const KS = [1, 5, 10, 50];
  const nuevo = { vec: { r: {}, mrr: 0, miss: 0 }, bm25: { r: {}, mrr: 0, miss: 0 }, rrf: { r: {}, mrr: 0, miss: 0 } };
  const goldSims = [];
  const noGoldMax = [];

  usables.forEach((q, qi) => {
    const gold = q.expected_chunks.map((g) => idxById.get(String(g))).filter((x) => x !== undefined);
    const qv = new Float32Array(dims);
    {
      let n = 0;
      for (const v of qEmbs[qi]) n += v * v;
      n = Math.sqrt(n);
      for (let d = 0; d < dims; d++) qv[d] = qEmbs[qi][d] / n;
    }
    const sims = new Float32Array(corpus.length);
    for (let i = 0; i < corpus.length; i++) {
      let s = 0;
      const off = i * dims;
      for (let d = 0; d < dims; d++) s += M[off + d] * qv[d];
      sims[i] = s;
    }
    const rankVec = Array.from(sims.keys()).sort((a, b) => sims[b] - sims[a]);

    // BM25
    const qt = tok(q.query);
    const bm = new Float32Array(corpus.length);
    for (let i = 0; i < corpus.length; i++) {
      const dl = docsTok[i].length || 1;
      const tf = new Map();
      docsTok[i].forEach((w) => tf.set(w, (tf.get(w) || 0) + 1));
      let s = 0;
      for (const w of qt) {
        const f = tf.get(w) || 0;
        if (f) s += idf(w) * ((f * 2.2) / (f + 1.2 * (1 - 0.75 + 0.75 * (dl / avgdl))));
      }
      bm[i] = s;
    }
    const rankBm = Array.from(bm.keys()).sort((a, b) => bm[b] - bm[a]);
    const rrfScore = new Float32Array(corpus.length);
    rankVec.forEach((d, r) => (rrfScore[d] += 1 / (60 + r + 1)));
    rankBm.forEach((d, r) => (rrfScore[d] += 1 / (60 + r + 1)));
    const rankRrf = Array.from(rrfScore.keys()).sort((a, b) => rrfScore[b] - rrfScore[a]);

    for (const [nombre, rank] of [['vec', rankVec], ['bm25', rankBm], ['rrf', rankRrf]]) {
      const pos = new Map();
      rank.forEach((d, r) => pos.set(d, r + 1));
      const rangos = gold.map((g) => pos.get(g)).filter(Boolean);
      for (const k of KS) {
        const hits = rangos.filter((r) => r <= k).length;
        nuevo[nombre].r[k] = (nuevo[nombre].r[k] || 0) + hits / gold.length;
      }
      const mejor = rangos.length ? Math.min(...rangos) : Infinity;
      nuevo[nombre].mrr += mejor <= 10 ? 1 / mejor : 0;
      if (!rangos.length || mejor > 50) nuevo[nombre].miss++;
    }

    const setGold = new Set(gold);
    let mejorGold = -1;
    let mejorNoGold = -1;
    rankVec.forEach((d, r) => {
      if (r > 200) return;
      if (setGold.has(d)) mejorGold = Math.max(mejorGold, sims[d]);
      else mejorNoGold = Math.max(mejorNoGold, sims[d]);
    });
    if (mejorGold >= 0) goldSims.push(mejorGold);
    if (mejorNoGold >= 0) noGoldMax.push(mejorNoGold);
  });

  const n = usables.length;
  for (const k of ['vec', 'bm25', 'rrf']) {
    for (const K of KS) nuevo[k].r[K] = nuevo[k].r[K] / n;
    nuevo[k].mrr = nuevo[k].mrr / n;
  }
  const q = (a, p) => { const s = [...a].sort((x, y) => x - y); return s[Math.floor(p * (s.length - 1))]; };

  // umbral óptimo por F1 sobre el mejor gold vs el mejor no-gold
  let mejorT = 0, mejorF1 = -1;
  for (let t = 0.1; t <= 0.9; t += 0.01) {
    let tp = 0, fn = 0, fp = 0;
    goldSims.forEach((s) => (s >= t ? tp++ : fn++));
    noGoldMax.forEach((s) => { if (s >= t) fp++; });
    const f1 = (2 * tp) / (2 * tp + fp + fn);
    if (f1 > mejorF1) { mejorF1 = f1; mejorT = t; }
  }

  const res = {
    modelo: MODEL, dims, chunks: corpus.length, queries_con_gold: n, llamadas_embed: llamadas,
    ms_por_chunk_lote: +(msEmb / corpus.length).toFixed(1),
    chunks_truncados_a_1400: truncados,
    metricas: nuevo,
    umbral_optimo_f1: +mejorT.toFixed(2), f1_en_umbral_optimo: +mejorF1.toFixed(3),
    sim_gold: { min: +Math.min(...goldSims).toFixed(3), p10: +q(goldSims, 0.1).toFixed(3), p50: +q(goldSims, 0.5).toFixed(3), p90: +q(goldSims, 0.9).toFixed(3), max: +Math.max(...goldSims).toFixed(3) },
    sim_no_gold_top: { p10: +q(noGoldMax, 0.1).toFixed(3), p50: +q(noGoldMax, 0.5).toFixed(3), p90: +q(noGoldMax, 0.9).toFixed(3) },
    segundos_totales: +((Date.now() - t0) / 1000).toFixed(1),
  };
  fs.writeFileSync(OUT, JSON.stringify(res, null, 2));

  console.log('\n================ RESULTADO ================');
  console.log(JSON.stringify(res, null, 2));
  console.log('\n--- TABLA ---');
  console.log('variante   R@1     R@5     R@10    R@50    MRR@10  misses(top50)');
  for (const k of ['vec', 'bm25', 'rrf']) {
    const m = nuevo[k];
    console.log(`${k.padEnd(9)} ${(m.r[1] * 100).toFixed(1).padStart(5)}%  ${(m.r[5] * 100).toFixed(1).padStart(5)}%  ${(m.r[10] * 100).toFixed(1).padStart(5)}%  ${(m.r[50] * 100).toFixed(1).padStart(5)}%  ${m.mrr.toFixed(3)}   ${m.miss}`);
  }
  console.log('\nReferencia histórica (modelo e5-v5, ciclos R5/R6, no estrictamente comparable): R@5 61.6%  R@10 65.5%  R@50 80.1%  MRR 0.722');
  process.exit(0);
})().catch((e) => { console.error('FALLO:', e.message); process.exit(1); });
