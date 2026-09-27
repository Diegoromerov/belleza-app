# ORDEN A-07 — «El gate tiene que decir la verdad» · revisión con el mapa medido

**Para:** Antigravity (Ejecutor) · **De:** Hermes (Arquitecto) · **Fecha:** 2026-09-26
**Esta es la orden vigente.** Reemplaza al borrador `PROMPT-ANTIGRAVITY-A-07-GATE-CLASIFICADO-2026-09-26.md` (marcado como superseded, conservado en git): hoy ya existe la **clasificación medida** de las 10 suites rojas, así que no tenés que reproducir esa parte.
**Rama:** **`fix/gate-clasificado`**, creada **desde `b545ef22`** (cabeza de `fase-a/verdad-operativa`). Una orden = una rama.
**Base de evidencia:** `docs/knowledge/CLASIFICACION-GATE-2026-09-26.md` (corridas aisladas, base limpia real, checkout **LF**).

---

## §0. Qué NO es el objetivo (leelo antes de tocar nada)

**El gate no puede quedar verde todavía**, y no por tu trabajo:
- En el CI, el paso 7 (**escaneo de credenciales**) falla primero y **todo lo demás queda `skipped`** ⇒ el paso de tests **nunca corrió en GitHub** (verificado por mí en los 4 runs del PR #16).
- Aun resolviendo eso, quedan **CI-14** (decisión del Dueño sobre 5 líneas de prosa) y **2b** (`fix/jwt-sin-respaldo`) ⇒ el escáner seguiría encontrando credenciales.

⇒ El objetivo es que el rojo sea **honesto, mínimo y explicado**: cada una de las 10 suites con **causa raíz medida**, decisión explícita y prueba. **Prohibido** maquillar el gate (§4).

## §1. El mapa (ya medido — usalo, no lo repitas)

| Suite | Aislada (LF, base real) | Primera falla | Clase |
|---|---|---|---|
| `adminPreciosRoutes` | 4F/1P | 403 esperado → **400** | semántica de autorización |
| `audit360-remediation` | 1F/18P | test del escáner de credenciales | depende de CI-14/2b |
| `business.integration` | 7F/11 | 200 esperado → **500** | 500 en endpoint |
| `businessAdminDocs.integration` | 8F/8 | 200 esperado → **500** | 500 |
| `businessHardening.integration` | 12F/12 | 200 esperado → **500** | 500 |
| `businessRAG.integration` | 1F/14 | `"success"` → **`"not_found"`** | datos/contrato |
| `businessSystem.integration` | 10F/16 | 200 esperado → **500** | 500 |
| `rateLimiter` | 7F/12 | `TIER_LIMITS` **undefined** | contrato de módulo roto |
| `sequelizeTenantContext` | 8F/8 | `cablearContextoEnSequelize is not a function` | contrato de módulo roto |
| `sprint2_agents` | 1F/5 | `"14:00"` esperado → **undefined** | puede ser bug real |

**Regla de medición obligatoria:** corré las suites en un checkout **LF**. En CRLF los tests que leen archivos mienten (CI-31: `audit360-remediation` pasa 19/19 en CRLF y falla en LF, mismo commit). Para crear uno:
`git -c core.autocrlf=false worktree add --detach <ruta> b545ef22`

## §2. Cargos

**Cargo 1 — Los dos contratos roto.** `rateLimiter` importa `TIER_LIMITS` y `sequelizeTenantContext` importa `cablearContextoEnSequelize`; ninguno existe. Determiná, **con evidencia**, cuál de las dos cosas es cierta y actuá:
 (a) el módulo **debe** exportarlo (entonces falta cablearlo) ⇒ arreglá el módulo, test-first;
 (b) el test quedó **obsoleto** (la API cambió de nombre o de forma) ⇒ retiralo **con justificación escrita** (§4), no en silencio.

**Cargo 2 — Los cinco 500.** Para cada suite: encontrá el endpoint, el error real que el 500 se traga y **la causa**. Clasificá y actuá:
 - si es **falta de datos/fixtures**, el test debe **fabricar lo que necesita** (tenant, usuario, plan, lo que sea) — o la superficie debe responder lo que corresponde a «no hay datos»; nunca un 500 por consulta vacía;
 - si es **bug real**, arreglalo test-first y dejá el test que lo prueba.
 Requisito duro: **un 500 no es una respuesta aceptable**; si el endpoint no puede cumplir, tiene que decir por qué, y eso se prueba.

**Cargo 3 — Los tres de expectativa/semántica.**
 - `adminPreciosRoutes` (403 vs 400): un usuario **autenticado con rol insuficiente** debe recibir **403**, no 400 ⇒ el arreglo va en la ruta, test-first.
 - `businessRAG` (`"success"` vs `"not_found"`): decidí cuál es la respuesta **honesta** con la base que hay, y probá esa.
 - `sprint2_agents` (`"14:00"` vs `undefined`): **investigá antes de tocar la expectativa** — puede ser un defecto real de cálculo del agente; si lo es, se arregla el agente.

**Cargo 4 — Los falsos rojos del arnés.** El gate muestra 1-3 suites que **no fallan: no corren** (`Test suite failed to run`, `TypeError: Converting circular structure to JSON … at messageParent (jest-worker/…)`), y `--maxWorkers=2` **no lo arregla** (mueve el crash a otra suite: medido). Dejá escrito:
 - cómo distinguir «falló por aserción» de «no corrió» (una suite que no corrió **no cuenta** como roja);
 - si el crash es evitable (¿algo serializa un objeto circular al fallar?), arreglalo; si no, documentalo con la evidencia de las corridas.

**Cargo 5 — La tabla final.** Entregá: suite → causa raíz medida → decisión (arreglada / retirada con justificación / abierta y por qué) → evidencia cruda. Debe permitir que un lector decida el aterrizaje **sin volver a medir**.

## §3. Colisión con el aterrizaje pendiente (importante)

Ocho ramas aceptadas esperan aterrizaje y ya tocan estos archivos: **`index.js`**, `scripts/{smokeSurfaces,listRoutes,inspectCiSuites,verifyNoVersionedSecrets}.js`, `src/config/db.js`, `src/middleware/degradedLock.js`, `src/controllers/providerController.js`, `src/services/adminMetricsService.js`, `.github/workflows/ci.yml`, `scripts/COMO_EJECUTAR.md`, `migrations/056,058`, y por A-08: `backend/jest.config.js`, `src/config/tenantRouting.js`, `src/jobs/paymentJobs.js`, `src/services/biometricCryptoService.js`.

**No los modifiques en esta orden.** Las suites rojas levantan la app por `index.js` ⇒ si la causa raíz de un 500 vive ahí, **pará y reportá** (yo decido si se toca y cómo se compone con el tren). Tu territorio: los archivos de las suites y los módulos que ellas ejercitan (motor de negocio, rate limiter, contexto de Sequelize, precios admin, agentes).

## §4. Regla anti-maquillaje

Si un test está obsoleto y hay que retirarlo: (1) justificación escrita en `docs/knowledge/DEUDA.md` con la evidencia de que la API cambió, (2) el retiro va en su propio commit, (3) lo audito yo. **Bajar un número borrando un test no es cerrar una brecha.** Y todo fix nace de un test que **primero falla**.

## §5. Prohibiciones

No toques C-01/C-02/C-03 (OTP, cobro, wallet, disputas); no toques migraciones `.sql`; no toques `backend/public` ni reconstruyas el bundle; no mergees; no empujes a `main`; no borres ramas del remoto; no uses `--force` ni `--force-with-lease`. Los archivos de §3 quedan fuera de alcance.

## §6. Compuertas mecánicas antes de empujar

1. `git status --porcelain` + `git log -1 --format='%h %s'` (declaralos en la entrega).
2. Las 10 suites corridas **aisladas en LF**, antes y después, con la tabla comparativa (exit + `Tests:` + primera falla).
3. `node --check` de todo archivo que toques.
4. Por cada fix: la mutación que lo voltea, ejecutada y restaurada con `sha256` idéntico antes/después.
5. Lo que no puedas medir, decilo como **«no medido»** y por qué. Un «debería» no es evidencia.
