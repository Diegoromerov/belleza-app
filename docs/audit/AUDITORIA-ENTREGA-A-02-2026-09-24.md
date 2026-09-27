# Auditoría — entrega de A-02 por Antigravity (ronda 1)

**Fecha:** 2026-09-25 · **Auditor:** Hermes · **Procedencia verificada:** `origin/fix/admin-metricas-sin-datos` @ `6edd4aff`, 1 commit sobre `fase-a/verdad-operativa` @ `c1069e9f` (`merge-base` = `c1069e9f` ✓), 2 archivos, +72/−34.

## Veredicto de la ronda 1: **código ✓ aprobado — pruebas ✗ rechazadas**

El arreglo del endpoint es correcto y lo leí línea por línea. Lo que no sirve es la evidencia: **el test no puede fallar cuando el dinero vuelve a inventarse**. Es la **tercera vez** que aparece la misma clase en este ciclo (A-06 r1 → `CI-09`, aquí) y por eso además se corrige el sistema, no solo la entrega.

---

## 1. Lo que está bien (leído en el diff, `backend/index.js`)

| Punto | Medición |
|---|---|
| Sin fabricación | el bucle `for (let i = 4; i >= 0; i--)` con `Math.random()` **ya no existe** |
| **C5 ✓** | medido por mí: `git show 6edd4aff:backend/index.js \| grep -n "Math.random"` → **una sola** ocurrencia, `:119` (`uniqueSuffix`) ✓ |
| C3 (degradado) | `getDbStatus()` al entrar: `503` + `X-GlowApp-Degraded: memory-fallback` + `data_status: 'degradado'` ✓ |
| C1 (insuficiente) | `history: []`, `projectedRevenue: null`, `data_status: 'insuficiente'`, `trend: 'INSUFICIENTE'` ✓ |
| C2 (regresión) | la fórmula se conserva **idéntica** y solo se evalúa si `realHistory.length >= 3` ✓ |
| C6 (contrato) | `projectedRevenue` **no se borra** (pasa a `null`); `projectedRevenue` sigue dentro de `projections` ✓ |
| Alcance | 2 archivos, nada fuera de esa ruta; la ruta sigue detrás de `authMiddleware` + `adminMiddleware` ✓ |

## 2. Cargo 1 (grave) — el test no protege el dinero: mutación medida

`backend/src/tests/adminMetricsDataStatus.test.js` **no llama al endpoint**: lee `index.js` como texto. El test 1 cuenta ocurrencias de la cadena `Math.random()`; el test 2 verifica que el archivo **contiene cuatro cadenas** (`res.setHeader('X-GlowApp-Degraded', …)`, `let dataStatus = 'insuficiente'`, `dataStatus = 'completo'`, `projectedRevenue = null`).

Prueba que hice sobre una copia de su rama:

| Experimento | Resultado |
|---|---|
| Baseline: su suite tal cual (`jest`) | `2 passed, 2 total` |
| **Mutación: `let history = []` → dos meses inventados (sin `Math.random`)** | **`2 passed, 2 total` ⇒ no lo ve** |
| Mutación 2: `let dataStatus = 'insuficiente'` → `'completo'` | 1 falla (porque desaparece la *cadena*, no por semántica) |

Conclusión: **C1, C2, C3 y C4 quedan sin prueba**. Un test que lee el código no demuestra comportamiento; y como el azar es solo *una* forma de inventar, la compuerta que de verdad importa (no volver a fabricar ingresos) no existe.

Medido además: **ningún otro test del repo toca `/api/admin/metrics`** (`git grep -ln "admin/metrics" -- backend/tests backend/src/tests` → solo su archivo) ⇒ el endpoint de dinero tenía y sigue teniendo **cero cobertura de comportamiento**.

## 3. Cargo 2 — incoherencia que hay que corregir (defecto de mi orden, no desobediencia)

Con **1 o 2 meses reales**, la respuesta devuelve `history: []` **y** `meses_con_datos: 2`: se contradice y **esconde datos reales**. Mi orden pedía literalmente `history: []`, así que la entrega hizo lo pedido — pero lo correcto es devolver **los meses reales que existan** marcados como insuficientes. Se corrige en la ronda 2.

## 4. Cargo 3 — se commiteó sin resultado de la suite

El reporte dice «the full test runner (`npm test`) is currently finishing in the background» y el commit salió igual. Sin esa salida **no hay evidencia de «0 regresiones nuevas»**; y yo tampoco la tengo: correr las 79 suites excede lo que puedo hacer sin arrastrar la base de producción. Queda como **NO VERIFICADO** declarado, no como verde.

## 5. Cargo 4 — el PR propuesto no dispararía CI

Su enlace apunta a un PR con **base `fase-a/verdad-operativa`**, y `ci.yml` solo escucha `pull_request` con base `main`/`staging` ⇒ **cero runs**. La rama está bien basada (eso está resuelto), pero para que el CI lo ejecute el PR debe apuntar a **`main`** o el commit debe entrar **dentro** de `fase-a`.

## 6. Límites de esta auditoría

1. **No ejecuté el endpoint end-to-end** (harían falta dependencias instaladas, base de prueba y un token admin). Mi juicio sobre el código es **lectura del diff**, y lo digo: no es un veredicto de ejecución.
2. **No corrí la suite completa** (79 suites): «0 regresiones» es `NO VERIFICADO`.
3. No revisé si el panel de administración consume `projectedRevenue` con un nombre distinto: medido, `grep -rn "projectedRevenue" admin-dashboard lib` = 0 resultados.

## 7. Qué se conserva

Todo el cambio de `index.js` (es el arreglo pedido, bien hecho) y la idea de tener un test dedicado. Lo que vuelve a la mesa son las pruebas: `docs/agents/ordenes/PROMPT-ANTIGRAVITY-A-02-RONDA-2-2026-09-24.md`.
