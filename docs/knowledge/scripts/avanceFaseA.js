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
  { id: 'S3', nota: 1.00, evidencia: 'CIERRA 1,00 el 2026-09-28 (medido por el Auditor): la mutacion llego a GitHub y el gate la nombro. Run 36457686836 — push a main @ 0ad91fb7e, el merge del PR #18 — con la anotacion que publica el propio CI: "Test Suites: 5 failed, 72 passed, 77 total · Tests: 24 failed, 1 skipped, 567 passed, 592 total", contra el baseline de main 4 failed/73 passed y 23/1/568/592: +1 suite y +1 test fallido, con el test mutado nombrado por la anotacion ("valor por defecto literal para variable sensible") y su linea (expect(res.exitCode).toBe(0), Expected 0 / Received 1). La mutacion fue revertida en c98503b33 y el arbol quedo identico al previo al merge (git diff 0ad91fb7e^1 c98503b33 vacio). Antes de esto no era medible porque el paso de tests del CI quedaba skipped detras de un paso previo roto (CI-46) y, una vez arreglado, porque las suites no cargaban por el motor de Node (CI-54).' },
  { id: 'S4', nota: 1.00, evidencia: '`smoke:surfaces` sale ≠0 si algo finge; camino de timeout medido (3/3 + mutación)' },
];

const entregables = [
  { id: 'A-01', nota: 1.00, evidencia: 'r2 ✓ `ba06e563`; **re-medido el 2026-09-26 sobre el tren de 9 ramas**: compuerta de aislamiento exit 0, **22 pruebas ejecutadas / 0 omitidas** (13 tablas RLS+FORCE, escritura ajena 42501, trigger de tenant_id) ⇒ el cableado de Sequelize de A-08 no rompió el aislamiento' },
  { id: 'A-02', nota: 1.00, evidencia: 'r2 ✓ + r3 `6f2f656f` (CI-18 cerrada: el mes proyectado ya no salta un mes)' },
  { id: 'A-03', nota: 1.00, evidencia: '`38a9afe9` ✓ — 57 rutas retiradas (308→252), 0 pérdidas; mutaciones A/B rojas' },
  { id: 'A-04', nota: 1.00, evidencia: '**Verificado por el Arquitecto el 2026-09-27**: diff del `.gitignore`, 192 archivos intactos, `git status` limpio y los dos scratch des-ignorados inexistentes ⇒ sin efectos colaterales · backend/public: versionado intencional aceptado y configurado en .gitignore para servido estático de la app web Flutter (A-04)' },
  { id: 'A-05', nota: 1.00, evidencia: '**AUDITADA POR EL ARQUITECTO (2026-09-27)**: el patrón `authRoutes` está retirado de verdad (0 archivos del repo lo contienen; la única mención es el comentario que lo explica) y la lista de 9 patrones de exclusión coincide con la del CI; `inspectCiSuites.js` robusto al CRLF (misma salida en CRLF y LF). **Defecto encontrado y corregido en esta misma rama**: la cifra que documentaba había envejecido (decía 66 de 79 con 13 excluidas; medido hoy: **77 dentro del gate de 92 coleccionadas, 15 excluidas**, con el comando `npx jest --listTests` para re-derivarla). Con la cifra refrescada y re-derivable, el entregable queda cerrado' },
  { id: 'A-06', nota: 1.00, evidencia: '**RESIDUOS CERRADOS Y VERIFICADOS (2026-09-27)**: (a) TEC-53/CI-14 quedó **aceptada y aterrizada en `main`** — el literal salió y el escáner da 0 en `main`; (b) la confirmación de Railway que esperaba 2b (`dbb87293`) **medida EN VIVO hoy** con `railway variables --json` (sin imprimir valores): `JWT_SECRET` 32 bytes, `BIOMETRIC_ENCRYPTION_KEY` y `ENCRYPTION_KEY` **64 hex = 32 bytes cada una**, `DATABASE_URL` presente; 42 variables en producción ⇒ el fail-fast no rompe nada. Su afirmación central (el escáner dice lo mismo en CRLF y en LF: 8 = 8, contra 1 vs 39 del viejo ⇒ CI-31) sigue medida' },
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
