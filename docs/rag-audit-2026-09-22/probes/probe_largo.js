/** ¿Cuánto contenido pierde el truncado a 1400 chars y acepta el modelo vivo textos largos? */
const B = 'C:/beauty-app/backend';
require(B + '/node_modules/dotenv').config({ path: 'C:/beauty-app/.env' });
const corpus = require(B + '/src/data/corpus_canonico/corpus_canonico.json').chunks;

const largos = corpus.map((c) => ((c.title || '') + '\n\n' + (c.content || '')).length);
const trunc = largos.filter((n) => n > 1400).length;
const s = [...largos].sort((a, b) => a - b);
const q = (p) => s[Math.floor(p * (s.length - 1))];
console.log('=== tamaño real del texto por chunk (title + content) ===');
console.log(`  chunks=${corpus.length} | >1400 chars (hoy se truncan) = ${trunc} (${((100 * trunc) / largos.length).toFixed(1)}%)`);
console.log(`  p50=${q(0.5)}  p90=${q(0.9)}  p99=${q(0.99)}  max=${s[s.length - 1]} chars`);
console.log(`  caracteres que hoy NUNCA llegan al modelo: ${largos.reduce((a, n) => a + Math.max(0, n - 1400), 0).toLocaleString('es-CO')}`);

(async () => {
  const largo = (corpus.find((c) => ((c.title || '') + (c.content || '')).length > 3000) || corpus[0]);
  const full = (largo.title || '') + '\n\n' + (largo.content || '');
  console.log('\n=== ¿el modelo vivo acepta textos largos? (chunk de', full.length, 'chars) ===');
  for (const n of [1400, 4000, full.length]) {
    const t = full.slice(0, n);
    try {
      const r = await fetch('https://integrate.api.nvidia.com/v1/embeddings', {
        method: 'POST',
        headers: { Authorization: 'Bearer ' + process.env.NVIDIA_API_KEY, 'Content-Type': 'application/json' },
        body: JSON.stringify({ input: [t], model: 'nvidia/nemotron-3-embed-1b', input_type: 'passage', encoding_format: 'float' }),
      });
      const j = await r.json();
      console.log(`  ${String(n).padStart(5)} chars → HTTP ${r.status} | dims=${j.data?.[0]?.embedding?.length} | tokens=${j.usage?.total_tokens ?? 'n/a'}`);
      if (r.status !== 200) console.log('   ', JSON.stringify(j).slice(0, 140));
    } catch (e) { console.log(`  ${n} chars → fallo: ${e.message}`); }
  }
  process.exit(0);
})();
