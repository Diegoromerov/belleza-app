# ENSAYO DE INTEGRACIÓN — TREN A (las 5 aceptadas sobre el vehículo)

**Ejecutado por:** Hermes (Arquitecto) — *no por el Ejecutor*: hice el ensayo yo, así que **la orden O-015 queda sin efecto** (no hay que volver a hacerlo).
**Fecha:** 2026-09-25. **Método:** worktree detachado en `b545ef22` (`fase-a/verdad-operativa`, el vehículo de PR #16), merges **locales en detach** (sin crear rama), worktree retirado al terminar. `fase-a` y `main` **no se movieron**.

## 1. Mapa de merges (en el orden propuesto)

| # | Rama | SHA | Merge | Archivos del merge | Resultado |
|---|---|---|---|---|---|
| 1 | `fix/ci-procedencia` | `6268afff` | `4b242722` | 2 | ✅ **sin conflicto** |
| 2 | `fix/rls-056-058-cadena` | `ba06e563` | `afb90162` | 2 | ✅ **sin conflicto** |
| 3 | `fix/montajes-unicos` | `38a9afe9` | `0943e0cd` | 4 | ✅ **sin conflicto** |
| 4 | `fix/admin-metricas-sin-datos` | `f565037c` | `87631940` | 3 | ✅ **sin conflicto** (pese a **no estar rebasada**) |
| 5 | `fix/arranque-y-estado-honesto` | `07e7225e` | `e468d432` | 7 | ✅ **sin conflicto** |

**Cinco merges, cero conflictos de texto.** El riesgo que se temía (tres ramas tocan `backend/index.js`) no se materializó textualmente.

## 2. Suites sobre el tren integrado (`e468d432`) — **aquí está el problema**

| Suite | Resultado |
|---|---|
| `adminMetricsDataStatus.test.js` | ✅ PASS |
| `dbStatusLock.test.js` | ✅ PASS |
| `smokeSurfaces.test.js` | ✅ PASS |
| `degradedLockBehavior.test.js` | ✅ PASS |
| **`routing.contract.test.js`** | ❌ **FAIL** — `C2, C4`: «`/api/admin/precios/precios` DEBE responder 404» ⇒ **recibió 503** |

**Medido tres veces, mismo resultado:** sin base (503), con base real (`NODE_ENV=test` + `DATABASE_URL`, 503) y con `NODE_ENV=development` + base real (503).

## 3. Causa raíz (código citado)

- A-03 nace de `c1069e9f`, **antes** de que existiera el candado de degradación (`fase-a` r5/r6). Su test de contrato se escribió, entonces, sin candado: espera que una URL inexistente dé **404**.
- El tren **sí** trae el candado: `backend/src/middleware/degradedLock.js:57-59` marca degradado cuando `servingFabricatedData === true || pgAvailable === false`, y `:86-90` responde **503 `DATA_LAYER_DEGRADED`** a *cualquier superficie de datos bajo `/api`* ⇒ intercepta **antes** de que el router decida el 404.
- Y en el proceso del test el estado nunca se comprueba: `require('../index')` **no ejecuta el arranque** (`app.listen` ⇒ `testConnection()`), el defecto ya catalogado (**CI-22/CI-23**). Con `NODE_ENV=test` el pool sirve memoria ⇒ `servingFabricatedData: true` ⇒ **siempre** 503.
- El test **no menciona el candado** (0 referencias): fue escrito para un mundo sin él.

⇒ **No es un fallo de enrutamiento: es un choque entre dos tests/defectos del mismo vehículo.** El enrutamiento de A-03 está bien (sus 3 casos pasan en su rama sola y los otros dos siguen pasando en el tren).

## 4. Consecuencia para el aterrizaje

**Hoy el tren NO debe aterrizar tal cual**: al integrarse en `fase-a`, `routing.contract.test.js` queda rojo — y con el CI en `NODE_ENV=test` y base del pipeline, **no hay razón para esperar que allí pase** (el candado 503 depende del estado, no del entorno). Es decir: aterrizar sin arreglarlo mete un test rojo en el PR que se va a mergear a `main`.

**Lo que se necesita (orden O-016, corta):** hacer **determinista** el caso C2/C4 de A-03:
1. si el candado está activo, la aserción de «404» no es válida para esa URL ⇒ el test debe aislar el enrutamiento (montar el router/superficie sin el candado) **o** aceptar explícitamente `404` **y** `503 DEGRADED` declarando el estado;
2. **y** el caso debe seguir cazando la regresión real (mutación pegada: volver el prefijo duplicado ⇒ rojo).
3. Encaja con la **ronda 7** (O-013): cuando el candado *compruebe* en vez de asumir (CI-23), con base arriba dará `404` y sin base `503` ⇒ el test determinista debe declarar ambos.

**Orden recomendado de aterrizaje (una vez O-016 esté):** el mismo del ensayo (1→5), con **merge commit** (no squash) y volviendo a correr las suites clave sobre el resultado integrado.

## 5. Verificación de no-interferencia

- `fase-a/verdad-operativa` = `b545ef22` (sin mover) · `main` = `f5a1b4fc` (sin mover).
- Las 5 ramas del tren: SHA intactos (`6268afff`, `ba06e563`, `38a9afe9`, `f565037c`, `07e7225e`).
- Worktree de ensayo **retirado**; no se creó ninguna rama (`detach`); nada se empujó.
