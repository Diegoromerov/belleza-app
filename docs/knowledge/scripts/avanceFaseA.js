#!/usr/bin/env node
/**
 * Avance de la Fase A — «verdad operativa».
 * Criterios y entregables tomados del documento de registro:
 *   - criterios S1..S4: docs/plans/2026-09-24_FASE-A-verdad-operativa.md (líneas 18-21)
 *   - entregables A-01..A-06: docs/agents/ordenes/PROMPT-ANTIGRAVITY-A-01-A-05-2026-09-24.md + A-06
 * Pesos declarados: criterios 0,50 · entregables 0,30 · aterrizaje 0,20 (los mismos de la ronda anterior,
 * para que dos porcentajes sean comparables).
 * Puntuación: 1,0 aceptada con su medición · 0,85-0,95 aceptada con residuos · 0,5 implementada sin evidencia
 *            · 0,0 no empezada o bloqueada por una decisión del Dueño.
 */

const criterios = [
  { id: 'S1', nota: 1.00, evidencia: 'con la base caída `/api/products` ⇒ 503 DATA_LAYER_DEGRADED (r6/r7, medido por el Auditor)' },
  { id: 'S2', nota: 1.00, evidencia: '`/api/health` 503 DEGRADED con pgAvailable:false y 200 con true (ronda 7, base arriba)' },
  { id: 'S3', nota: 0.85, evidencia: 'el CI existe, corre pasos reales y falla (run 36100419352, paso 7 ❌); el criterio literal «romper un test ⇒ run rojo» NO se observó en GitHub (el paso de tests nunca llegó a correr allí)' },
  { id: 'S4', nota: 1.00, evidencia: '`smoke:surfaces` sale ≠0 si algo finge; camino de timeout medido (3/3 + mutación)' },
];

const entregables = [
  { id: 'A-01', nota: 1.00, evidencia: 'r2 ✓ `ba06e563`; re-medido HOY: compuerta de aislamiento RLS exit 0 (cross-tenant invisible, sin contexto 0 filas, escritura ajena 42501)' },
  { id: 'A-02', nota: 1.00, evidencia: 'r2 ✓ + r3 `6f2f656f` (CI-18 cerrada: el mes proyectado ya no salta un mes)' },
  { id: 'A-03', nota: 1.00, evidencia: '`38a9afe9` ✓ — 57 rutas retiradas (308→252), 0 pérdidas; mutaciones A/B rojas' },
  { id: 'A-04', nota: 0.00, evidencia: '`backend/public`: 192 archivos versionados pese a `.gitignore:68` — **bloqueada por decisión del Dueño**, no es trabajo pendiente del Arquitecto' },
  { id: 'A-05', nota: 0.85, evidencia: '`6268afff` en el tren (merge limpio): documenta la procedencia del recuento y retira el patrón `authRoutes` que no matcheaba nada; sin auditoría propia ⇒ no 1,0' },
  { id: 'A-06', nota: 0.85, evidencia: 'r5 ✓ `85687237` (escáner 109→8, mutación roja); **residuos**: 2b `dbb87293` bloqueada por confirmación en Railway y Cargo 4 (CI-14) no autorizado' },
];

const aterrizaje = {
  nota: 0.10,
  evidencia: 'PR #16 open/mergeable: 2 checks — frontend ✅ success, backend ❌ failure en el paso 7; el tren integra 8/8 sin conflictos (los 8 SHAs re-verificados hoy); compuerta RLS verificada hoy; **nunca hubo CI verde ni merge**',
};

const PESOS = { criterios: 0.50, entregables: 0.30, aterrizaje: 0.20 };
const prom = (xs) => xs.reduce((a, x) => a + x.nota, 0) / xs.length;
const pc = (x) => (x * 100).toFixed(1).replace('.', ',') + ' %';

const c = prom(criterios);
const e = prom(entregables);
const a = aterrizaje.nota;
const total = PESOS.criterios * c + PESOS.entregables * e + PESOS.aterrizaje * a;

// Segundo denominador: sin A-04 (bloqueada por una decisión que no es trabajo)
const sinA04 = entregables.filter((x) => x.id !== 'A-04');
const eSin = prom(sinA04);
const totalSin = PESOS.criterios * c + PESOS.entregables * eSin + PESOS.aterrizaje * a;

const fila = (x) => `  ${x.id.padEnd(6)} ${x.nota.toFixed(2)}  ${x.evidencia}`;

console.log('TRES NÚMEROS');
console.log('  1) trabajo técnico hecho :', pc(total), '  (sin A-04:', pc(totalSin) + ')');
console.log('  2) criterios firmables   :', pc(c), ` (${criterios.filter((x) => x.nota === 1).length}/${criterios.length} plenos)`);
console.log('  3) fase cerrada          : 0,0 % (nada mergeado a main; el aterrizaje está en', a.toFixed(2), 'de 1,00)');
console.log('');
console.log('CRITERIOS (peso ' + PESOS.criterios + ')  ⇒ ' + pc(c));
criterios.forEach((x) => console.log(fila(x)));
console.log('');
console.log('ENTREGABLES (peso ' + PESOS.entregables + ') ⇒ ' + pc(e) + '  ·  sin A-04 ⇒ ' + pc(eSin));
entregables.forEach((x) => console.log(fila(x)));
console.log('');
console.log('ATERRIZAJE (peso ' + PESOS.aterrizaje + ')  ⇒ ' + pc(a));
console.log('  ' + aterrizaje.evidencia);
console.log('');
console.log('Ronda anterior: 66,0 %  ⇒  hoy ' + pc(total) + '  (delta ' + ((total - 0.66) * 100).toFixed(1).replace('.', ',') + ' pp)');
