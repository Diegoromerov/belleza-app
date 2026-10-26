#!/usr/bin/env node
// Sonda de auditoría — orquestador AURA y agentes (2026-10-24)
//
// Qué es: evidencia reproducible de docs/audit/AUDITORIA-AGENTES-AURA-2026-10-24.md.
// No toca la base ni el repositorio: inyecta un pool falso en require.cache y
// ejercita los agentes reales con esas respuestas.
//
// Uso:
//   node backend/scripts/auditAgentsBehaviour.js
//
// Salida esperada mientras A-01..A-06 sigan abiertos: VALKYRIE "autoriza" con
// una sola reserva, un usuario consulta la economía de otro prestador, HESTIA
// devuelve productos que no contienen los ingredientes del perfil y CHRONOS
// pierde el hito del día 15 entre los días 18 y 29.

const path = require('path');

const BACKEND = path.resolve(__dirname, '..');
const resolve = (p) => require.resolve(path.join(BACKEND, 'src', p));

// ── Pool falso: registra el SQL ejecutado y responde por patrón ────────────
const calls = [];
const fakePool = {
  query: async (sql, params) => {
    calls.push({ sql: sql.replace(/\s+/g, ' ').trim(), params });
    // VALKYRIE: una sola fila (miércoles = 3, una reserva en 30 días)
    if (/EXTRACT\(ISODOW/i.test(sql)) {
      return { rows: [{ day_of_week: '3', total_bookings: '1' }] };
    }
    // HESTIA: catálogo que NO contiene los ingredientes del perfil
    if (/FROM productos/i.test(sql)) {
      return {
        rows: [
          { id: 'prod-001', nombre: 'Esmalte rojo', precio: 5000, stock: 10 },
          { id: 'prod-002', nombre: 'Shampoo anticaspa', precio: 6000, stock: 4 },
        ],
      };
    }
    return { rows: [] };
  },
};

const dbPath = resolve('config/db.js');
require.cache[dbPath] = { id: dbPath, filename: dbPath, loaded: true, exports: { pool: fakePool } };

// Redis apagado: fuerza el camino PostgreSQL de ATENA.
try {
  const redisPath = resolve('config/redis.js');
  require.cache[redisPath] = {
    id: redisPath, filename: redisPath, loaded: true,
    exports: { isOpen: false, get: async () => null, set: async () => {}, setEx: async () => {} },
  };
} catch (_) { /* config/redis es opcional en esta sonda */ }

const valkyrie = require(path.join(BACKEND, 'src/services/agents/valkyrieAgent.js'));
const hestia = require(path.join(BACKEND, 'src/services/agents/hestiaAgent.js'));
const chronos = require(path.join(BACKEND, 'src/services/agents/chronosAgent.js'));
const { executeAuraTool, AURA_TOOLS_DEFINITIONS } = require(path.join(BACKEND, 'src/services/auraToolExecutor.js'));

const line = (t) => console.log(`\n=== ${t} ===`);

(async () => {
  line('P1. VALKYRIE autoriza descuento con 1 sola reserva en 30 días');
  const v = await valkyrie.getProviderInsights({ providerId: 5 });
  console.log(JSON.stringify(v.insights?.dynamicPromotion, null, 2));

  line('P2. Cualquier usuario consulta la economía de CUALQUIER prestador');
  const b2b = await executeAuraTool('get_provider_b2b_insights', { providerId: 777 }, 1 /* userId */);
  console.log('userId=1 pidió providerId=777 →', b2b.status, '| promo:', b2b.insights?.dynamicPromotion?.promoCode);

  line('P3. HESTIA sin perfil: devuelve catálogo igual');
  const h = await hestia.recommendProducts({ userId: 42, category: 'piel' });
  console.log('matchedIngredients reportados :', h.matchedIngredients);
  console.log('productos devueltos          :', h.products.map((p) => `${p.nombre} ($${p.precio})`));

  line('P3b. HESTIA con ingredientes REALES del perfil: ¿los usa?');
  const atena = require(resolve('services/agents/atenaAgent.js'));
  atena.getBiometricDiagnosis = async () => ({
    status: 'success',
    recommendedIngredients: ['Niacinamida 10%', 'Ácido Salicílico'],
  });
  calls.length = 0;
  const h2 = await hestia.recommendProducts({ userId: 42 });
  const productosSql = calls.find((c) => /FROM productos/i.test(c.sql))?.sql;
  console.log('ATENA dice que necesita :', h2.matchedIngredients);
  console.log('HESTIA devuelve        :', h2.products.map((p) => p.nombre));
  console.log('SQL ejecutado          :', productosSql);
  console.log('¿filtra por ingrediente?', /ingredient/i.test(productosSql || '') ? 'SÍ' : 'NO');

  line('P4. CHRONOS: hitos y desbordes de fecha');
  const dayAgo = (n) => new Date(Date.now() - n * 86400000);
  const mk = (n, dur = 30) => ({ id: 1, status: 'active', start_date: dayAgo(n), duration_days: dur, checkin_history: [] });
  for (const d of [0, 14, 15, 17, 18, 29, 30, 45]) {
    const r = chronos.evaluateCycleContinuity(mk(d));
    console.log(`día ${String(r.currentDayNumber).padStart(2)} → ${r.temporalState.padEnd(20)} next=${r.nextMilestoneDay}`);
  }
  const overrun = chronos.evaluateCycleContinuity(mk(45, 30));
  console.log('ciclo vencido hace 15 días → action:', overrun.actionRequired);

  line('P5. Superficie de herramientas expuesta al modelo');
  console.log('total tools:', AURA_TOOLS_DEFINITIONS.length, '→', AURA_TOOLS_DEFINITIONS.map((t) => t.function.name).join(', '));

  line('P6. Herramienta inexistente / args no validados');
  console.log('tool desconocida →', JSON.stringify(await executeAuraTool('drop_all_tables', {}, 1)));
  console.log('redirección con moduleKey inventado →',
    JSON.stringify(await executeAuraTool('trigger_ui_redirection', { moduleKey: 'no-existe' }, 1)));

  console.log('\nConsultas ejecutadas:', calls.length);
})();
