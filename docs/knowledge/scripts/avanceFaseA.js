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
 * NOTA DE DENOMINADOR: A-07 (el gate tiene que decir la verdad) nació el 2026-09-26, DESPUÉS de declarados
 * los criterios: no entra en el denominador, para que el total siga siendo comparable con las rondas previas.
 * Se reporta aparte y se imprime el total alternativo por si el Dueño decide incorporarlo.
 */

const criterios = [
  { id: 'S1', nota: 1.00, evidencia: 'con la base caída `/api/products` ⇒ 503 DATA_LAYER_DEGRADED (r6/r7, medido por el Auditor)' },
  { id: 'S2', nota: 1.00, evidencia: '`/api/health` 503 DEGRADED con pgAvailable:false y 200 con true (ronda 7, base arriba)' },
  { id: 'S3', nota: 0.90, evidencia: 'SUBE 0,85→0,90: medido HOY con el comando exacto del CI — el gate da **10 suites / 55 tests** rojos con 0 `failed-to-run` (6/28 tras A-07 r2) y el «rojo fantasma» quedó **atribuido y reproducido** (error de timeout de `execSync` no serializable). Sigue sin 1,0 porque el criterio literal —«romper un test ⇒ run rojo» **observado en GitHub**— no se pudo medir: en el PR #16 el paso de tests nunca llegó a correr (todo `skipped` detrás del paso 7 ❌)' },
  { id: 'S4', nota: 1.00, evidencia: '`smoke:surfaces` sale ≠0 si algo finge; camino de timeout medido (3/3 + mutación)' },
];

const entregables = [
  { id: 'A-01', nota: 1.00, evidencia: 'r2 ✓ `ba06e563`; **re-medido HOY sobre el tren de 9 ramas**: compuerta de aislamiento exit 0, **22 pruebas ejecutadas / 0 omitidas** (13 tablas RLS+FORCE, escritura ajena 42501, trigger de tenant_id) ⇒ el cableado de Sequelize de A-08 no rompió el aislamiento' },
  { id: 'A-02', nota: 1.00, evidencia: 'r2 ✓ + r3 `6f2f656f` (CI-18 cerrada: el mes proyectado ya no salta un mes)' },
  { id: 'A-03', nota: 1.00, evidencia: '`38a9afe9` ✓ — 57 rutas retiradas (308→252), 0 pérdidas; mutaciones A/B rojas' },
  { id: 'A-04', nota: 0.00, evidencia: '`backend/public`: 192 archivos versionados pese a `.gitignore:68` — **bloqueada por decisión del Dueño**, no es trabajo pendiente del Arquitecto' },
  { id: 'A-05', nota: 0.85, evidencia: '`6268afff` en el tren (merge limpio): documenta la procedencia del recuento y retira el patrón `authRoutes` que no matcheaba nada; hoy verifiqué además que su `inspectCiSuites.js` es **robusto al CRLF** (salida idéntica en CRLF y LF); sin auditoría propia ⇒ no 1,0' },
  { id: 'A-06', nota: 0.90, evidencia: 'SUBE 0,85→0,90: r5 `85687237` ✓ y **verifiqué hoy su afirmación central**: el escáner nuevo da **8 hallazgos en CRLF y 8 en LF** (el viejo: 1 vs 39 ⇒ CI-31), o sea el gate dice lo mismo en Windows y en el CI. Residuos que **no son trabajo del Arquitecto**: 2b `dbb87293` espera confirmación en Railway y CI-14 espera decisión del Dueño' },
];

const aterrizaje = {
  nota: 0.15,
  evidencia: 'SUBE 0,10→0,15: el paquete está **verificado hoy** — tren de 9 ramas re-ensayado (`f6e1964d`, 9 merges, 0 conflictos, anti-marcadores exit 0), compuerta RLS exit 0 sobre ESE tren, los números honestos del gate medidos y el runbook y el cuerpo del PR actualizados. Lo que bloquea no cambió: PR #16 sigue `open`/`mergeable` con 9 commits y **ningún CI verde** (backend ❌ en el paso 7; el paso de tests nunca corrió en GitHub), y **0 merges a `main`**',
};

// Trabajo nuevo, fuera del denominador declarado (ver nota de cabecera)
const trabajoNuevo = [
    { id: 'A-07', nota: 0.95, evidencia: 'el gate tiene que decir la verdad — r1 **RECHAZADA** (introdujo un agujero de escalada), r2 aceptada parcialmente (reversiones verificadas por diff; rojo del gate **10/55 → 6/25**), **r3 ACEPTADA CON RESIDUOS** (`1a9f13ef`): el crash del worker quedó arreglado con prueba determinista (helper `safeExecSync` serializable, `bash -n` con timeout) y el hallazgo del 403 verificado por el Auditor (CI-40). Residuos: CI-37 (mitigación del arnés) y `adminPreciosRoutes` (declarada verde 3 rondas, medida con 4 fallos) ⇒ **ronda 4 emitida**; **r4 ACEPTADA** (`4e9145ad`, 3 archivos): el test importa `getJwtSecret` de la app ⇒ **5/5 con y sin `JWT_SECRET`** (medido por mí) ⇒ **CI-41 cerrada**; CI-37 queda como mitigación **sin demostración** (ninguna de las dos mutaciones disparó el arnés)' },
];

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

// Alternativa: si el Dueño decide incorporar A-07 al denominador declarado
const eCon = prom(entregables.concat(trabajoNuevo));
const totalCon = PESOS.criterios * c + PESOS.entregables * eCon + PESOS.aterrizaje * a;

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
console.log('TRABAJO NUEVO — FUERA DEL DENOMINADOR (no altera el total de arriba)');
trabajoNuevo.forEach((x) => console.log(fila(x)));
console.log('  Si el Dueño decide incorporarlo al denominador: entregables ⇒ ' + pc(eCon) + ' · total ⇒ ' + pc(totalCon));
console.log('');
console.log('Ronda anterior (informe del mismo día): 73,6 %  ⇒  hoy ' + pc(total) + '  (delta ' + ((total - 0.736) * 100).toFixed(1).replace('.', ',') + ' pp)');
