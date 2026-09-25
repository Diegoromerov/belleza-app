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

## 6. CORRECCIÓN (R-06) — 2026-09-25, mismo día

En §2 escribí «con base real» y «NODE_ENV=development + base real». **Era falso: el demonio de Docker estaba caído**
(contenedor beauty-postgres parado, ECONNREFUSED 127.0.0.1:5435) ⇒ esas corridas **no tenían base**. El hallazgo (**CI-28**)
sigue en pie y quedó demostrado con el fix (3/3 en los 4 escenarios) y su mutación, pero la cita era incorrecta y se corrige aquí.

**Nota de entorno:** con Docker caído, /api/health da 503 y **parece** que el candado bloquea; verificá el banco de trabajo antes
de concluir nada sobre el candado. Y la credencial del contenedor **no conecta dentro de una URL** (postgres://admin:***@… caía a
memoria); los mismos datos como campos sueltos (DB_USER/DB_PASSWORD/DB_NAME/DB_HOST/DB_PORT, soportados en db.js:28-34) sí
(TCP OK → beauty_db).

## 7. Ensayo con O-016 (posterior, mismo día)

Con fix/contrato-convive-con-candado (3a9148ad) integrado: **6 merges, 0 conflictos** (HEAD 0384b058) y **5 suites / 21 tests PASS**,
routing.contract **verde** (antes rojo). fase-a y main sin mover. **El tren puede aterrizar** en cuanto el Dueño lo decida.

## 8. Ensayo del tren COMPLETO — 2026-09-25 (con las tres ramas nuevas)

Worktree detachado en `b545ef22` + las **8** ramas aceptadas, en orden de aterrizaje.

- **8 merges, 0 conflictos de texto, 0 abortados** (HEAD del ensayo `e819ae5c`). Comprobado por ancestro:
  `fix/ci-procedencia`, `fix/rls-056-058-cadena`, `fix/montajes-unicos`, `fix/admin-metricas-sin-datos`,
  `fix/arranque-y-estado-honesto`, `fix/contrato-convive-con-candado`, `fix/candado-comprueba-si-desconoce`,
  `fix/compuerta-secretos-reproducible` — las 8 son ancestro del HEAD del tren.
- **Suites clave: 10/10 verdes, 45 tests**. Incluye las cuatro piezas nuevas de hoy: `routing.contract` (O-016),
  `candadoCompruebaSiDesconoce` (r7), `smokeSurfacesTimeout` (Cargo 2), `adminMetricsProjectedMonth` (A-02 r3) y
  `verifyNoVersionedSecretsEtiqueta` (A-06 r5).
- **Escáner (paso 7 del CI) sobre el tren: 8 hallazgos**, todos «valor por defecto literal para variable sensible»:
  las 5 líneas de prosa de CI-14 + `jwt.js:1`, `jwt.js:2` y `biometricCryptoService.js:18`.
- `fase-a` = `b545ef22`, `main` = `f5a1b4fc` y el vehículo = `0a32f718` **sin mover**. Nada commiteado ni empujado por el ensayo.

### Qué haría el CI con esto (medido por API pública, no supuesto)

- **PR #16** (base `main`): `open`, `mergeable: true`, 9 commits (+4752/-48). Es el **único** camino que produce jobs reales.
- Los runs de `ci.yml` en ramas nacidas de `main` existen como `failure` pero con **0 jobs** (runs vacíos, re-medido hoy): no son veredictos.
- Las ramas nacidas de `fase-a` (las nuestras) **no disparan** `ci.yml` al empujarlas: el workflow válido tiene filtro `branches: [main, staging]`.
- ⇒ **la evidencia de CI aparecerá sólo cuando el tren entre en `fase-a` y PR #16 se actualice**, y el paso 7 seguirá rojo por CI-14.
