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
  { id: 'S3', nota: 0.90, evidencia: 'SUBE 0,85→0,90: medido el 2026-09-26 con el comando exacto del CI — el gate da **10 suites / 55 tests** rojos con 0 `failed-to-run` (6/28 tras A-07 r2) y el «rojo fantasma» quedó **atribuido y reproducido** (error de timeout de `execSync` no serializable). Sigue sin 1,0 porque el criterio literal —«romper un test ⇒ run rojo» **observado en GitHub**— no se pudo medir: en el PR #16 el paso de tests nunca llegó a correr (todo `skipped` detrás del paso 7 ❌)' },
  { id: 'S4', nota: 1.00, evidencia: '`smoke:surfaces` sale ≠0 si algo finge; camino de timeout medido (3/3 + mutación)' },
];

const entregables = [
  { id: 'A-01', nota: 1.00, evidencia: 'r2 ✓ `ba06e563`; **re-medido el 2026-09-26 sobre el tren de 9 ramas**: compuerta de aislamiento exit 0, **22 pruebas ejecutadas / 0 omitidas** (13 tablas RLS+FORCE, escritura ajena 42501, trigger de tenant_id) ⇒ el cableado de Sequelize de A-08 no rompió el aislamiento' },
  { id: 'A-02', nota: 1.00, evidencia: 'r2 ✓ + r3 `6f2f656f` (CI-18 cerrada: el mes proyectado ya no salta un mes)' },
  { id: 'A-03', nota: 1.00, evidencia: '`38a9afe9` ✓ — 57 rutas retiradas (308→252), 0 pérdidas; mutaciones A/B rojas' },
  { id: 'A-04', nota: 1.00, evidencia: 'backend/public: versionado intencional aceptado y configurado en .gitignore para servido estático de la app web Flutter (A-04)' },
  { id: 'A-05', nota: 0.85, evidencia: '6268afff en el tren (merge limpio): documenta la procedencia del recuento y retira el patrón authRoutes que no matcheaba nada; verifiqué el 2026-09-26 además que su inspectCiSuites.js es robusto al CRLF (salida idéntica en CRLF y LF); sin auditoría propia ⇒ no 1,0' },
  { id: 'A-06', nota: 0.90, evidencia: 'SUBE 0,85→0,90: r5 85687237 ✓ y verifiqué el 2026-09-26 su afirmación central: el escáner nuevo da 8 hallazgos en CRLF y 8 en LF (el viejo: 1 vs 39 ⇒ CI-31), o sea el gate dice lo mismo en Windows y en el CI. Residuos que no son trabajo del Arquitecto: 2b dbb87293 espera confirmación en Railway y CI-14 espera decisión del Dueño' },
  { id: 'A-07', nota: 0.95, evidencia: 'el gate tiene que decir la verdad — r4 ACEPTADA (4e9145ad): test importa getJwtSecret de la app ⇒ 5/5 con y sin JWT_SECRET (medido por el Auditor) ⇒ CI-41 cerrada; incorporada al denominador por decisión del Dueño' },
];

const aterrizaje = {
  nota: 1.00,
  evidencia: 'ATERRIZÓ: **`main`**, verificado por el Arquitecto contra el remoto.'
};

const PESOS = { criterios: 0.50, entregables: 0.30, aterrizaje: 0.20 };
const prom = (xs) => xs.reduce((a, x) => a + x.nota, 0) / xs.length;
const pc = (x) => (x * 100).toFixed(1).replace('.', ',') + ' %';

const c = prom(criterios);
const e = prom(entregables);
const a = aterrizaje.nota;
const total = PESOS.criterios * c + PESOS.entregables * e + PESOS.aterrizaje * a;

const fila = (x) => `  ${x.id.padEnd(6)} ${x.nota.toFixed(2)}  ${x.evidencia}`;

console.log('TRES NÚMEROS');
console.log('  1) trabajo técnico hecho :', pc(total));
console.log('  2) criterios firmables   :', pc(c), ` (${criterios.filter((x) => x.nota === 1).length}/${criterios.length} plenos)`);
console.log('  3) fase cerrada          : aterrizaje en', a.toFixed(2), 'de 1,00 — en main');
console.log('');
console.log('CRITERIOS (peso ' + PESOS.criterios + ')  ⇒ ' + pc(c));
criterios.forEach((x) => console.log(fila(x)));
console.log('');
console.log('ENTREGABLES (peso ' + PESOS.entregables + ') ⇒ ' + pc(e));
entregables.forEach((x) => console.log(fila(x)));
console.log('');
console.log('ATERRIZAJE (peso ' + PESOS.aterrizaje + ')  ⇒ ' + pc(a));
console.log('  ' + aterrizaje.evidencia);
