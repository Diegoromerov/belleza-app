/**
 * Sondeo del endpoint de embeddings: ¿acepta lote? ¿cuánto tarda? ¿cuántos tokens?
 * Mide tamaños de lote crecientes y verifica que devuelva N embeddings en orden.
 */
const B = 'C:/beauty-app/backend';
require(B + '/node_modules/dotenv').config({ path: 'C:/beauty-app/.env' });
const axios = require(B + '/node_modules/axios');

const URL = 'https://integrate.api.nvidia.com/v1/embeddings';
const MODEL = 'nvidia/nemotron-3-embed-1b';
const KEY = process.env.NVIDIA_API_KEY;

const texto = (i) => `Chunk ${i}: la niacinamida reduce los poros dilatados y regula el sebo en pieles grasas mixtas.`;

(async () => {
  for (const n of [1, 8, 32, 64, 128]) {
    const input = new Array(n).fill(0).map((_, i) => texto(i));
    const t0 = Date.now();
    try {
      const r = await axios.post(URL, { input, model: MODEL, input_type: 'passage', encoding_format: 'float' },
        { headers: { Authorization: `Bearer ${KEY}`, 'Content-Type': 'application/json' }, timeout: 120000 });
      const dt = Date.now() - t0;
      const embs = r.data?.data || [];
      console.log(`lote=${String(n).padStart(3)}  HTTP 200  ${String(dt).padStart(5)}ms  ${(dt / n).toFixed(0).padStart(4)}ms/embedding  embeddings=${embs.length}  dims=${embs[0]?.embedding?.length}  tokens=${r.data?.usage?.total_tokens ?? 'n/a'}`);
    } catch (e) {
      const st = e.response?.status;
      const det = JSON.stringify(e.response?.data || {}).slice(0, 160);
      console.log(`lote=${String(n).padStart(3)}  HTTP ${st}  ${JSON.stringify(det)}`);
    }
  }
  process.exit(0);
})();
