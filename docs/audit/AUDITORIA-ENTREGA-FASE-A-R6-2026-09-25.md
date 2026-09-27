# Auditoría — Fase A · ronda 6 (arranque real + estado honesto) · `07e7225e`

**Fecha:** 2026-09-25 · **Auditor:** Hermes
**Procedencia:** `fix/arranque-y-estado-honesto` @ **`07e7225e`** (`fix(smoke): honest db status, pure classification engine, and real entry child process launch (Ronda 6)`), ancestro de `b545ef22` ✓, `git status --porcelain` **limpio**.
**Diff vs `b545ef22`:** `backend/index.js` +34 · `backend/scripts/smokeSurfaces.js` +118 · `backend/src/config/db.js` +3 · `backend/src/middleware/degradedLock.js` +61 · `backend/src/tests/dbStatusLock.test.js` +78 · los dos informes de `docs/audit/`. (Su informe menciona `scripts/COMO_EJECUTAR.md`: **no está en el diff** — no lo tocó, y hace bien: esa es la línea de CI-14 y necesita autorización.)
**Nota de forma:** el walkthrough dice «Siguiente paso: commit y push», pero **el commit ya estaba hecho**. Sin impacto.

---

## Veredicto: **ACEPTADA con residuos** (1 residuo nuevo: CI-23). Cierra **CI-17** y **CI-20**.

Todo lo que sigue es medición mía sobre un worktree limpio de `07e7225e` en scratch, nunca lectura de su informe.

### C1 · El estado de la base dice la verdad — ✓ con un punto parcialmente incumplido

- **Tri-estado ✓**: `getDbStatus()` (`db.js:742`) devuelve `pgAvailable: null` mientras `dbMode === 'indefinido'` (`:550`), y `true/false` tras la comprobación. Medido antes de tocar nada, en un proceso sin arranque: `{"pgAvailable":null,"servingFabricatedData":false,"dbMode":"indefinido"}` ✓.
- **`/api/health` honesto ✓**: sin comprobación responde **200 `UNKNOWN`** («…estado de base de datos sin comprobar»), no `DEGRADED`; con la base arriba, **200 `OK`**; con la base caída, **503 `DEGRADED`** + `X-GlowApp-Degraded` (medido en los tres caminos).
- **Motor puro ✓**: `clasificarSalud` y `decidirBloqueo` exportadas y usadas por el middleware y por los dos handlers (`index.js:431-462`). El diff de `index.js` **sólo** toca el `require`, `/api/health` y `/api/test-db` ✓ (que además ahora comprueba si el estado es `null`, `:449-451`).
- **C1.3 PARCIAL ✗→CI-23**: el candado, con `null`, devuelve `shouldBlock:false` (`reason:'UNCHECKED'`) **sin ejecutar ninguna comprobación**. Mi orden pedía «si el estado es “sin comprobar”, **la comprobación ocurre** (una vez, con caché acotada) y decide». Medido con la base caída y un proceso que sirve sin el callback de arranque: `/api/health` = **200 `UNKNOWN`**, `/api/products` = **500** (honesto) y `/api/providers` = **503** + cabecera. **No se demostró ningún `2xx` fabricado** (el flag se activa en esa primera respuesta y el candado bloquea desde la siguiente), pero **antes de esta ronda el candado bloqueaba desde la primera petición**: la garantía pasó de estructural a depender de que cada ruta falle honestamente ⇒ **CI-23**.

### C2 · El guardián arranca la app como la arranca la app — ✓

`spawn('node', ['index.js'])` (`smokeSurfaces.js:171`) + sondeo de `/api/health` en bucle con `setTimeout(…,400)` **dentro** del bucle (`:200`, no es una espera fija única) y **fallo explícito** por timeout (`:211` «❌ TIMEOUT: El servidor real no logró comprobar el estado de la base de datos a tiempo») con `serverProcess.kill('SIGTERM')` (`:212` y también en el cierre normal, `:251`).
**Medido por mí, dos corridas completas** (checkout limpio, credencial de desarrollo, `DB_HOST=127.0.0.1`):
- **Base arriba:** `🚀 Iniciando servidor backend vía proceso hijo real (node index.js)` · `📊 Estado del servidor detectado: IsDegraded=false, HealthStatus=200, PgAvailable=true` · 308 rutas del stack vivo · 122 superficies · **0 fakes** · informe `smoke-2026-09-25-ok.json` · `EXIT=0`.
- **Base caída** (URL a puerto muerto): `IsDegraded=true, HealthStatus=503, PgAvailable=false` · informe `-degraded.json` · 0 fakes · `EXIT=0` (degradado no es fingir).
- **El hijo muere**: 0 conexiones en el puerto tras cada corrida ✓.
- *No medido por mí:* el camino de timeout cuando el hijo no llega a estar disponible (verifiqué su existencia en el código, no lo provoqué). Queda como Cargo 2 de la ronda 7.

### C3 · El `-ok.json` deja de mentir — ✓ (y además es reproducible, no fabricado)

Sus dos informes commiteados traen los campos nuevos y **coinciden campo a campo** con los que produce el código: `routes_source: express_stack`, `server_degraded`, `health_status`, `pg_available`, `total_surfaces_tested: 122`, `faked_success_count: 0` (sólo difiere `timestamp`; el suyo `06:44Z`, el mío `14:26Z`). **Mis corridas reescribieron ambos archivos** ⇒ reproducibles. Detalle: `/api/products` aparece **200** en el informe sano y **503** en el degradado, con `/api/providers` y `/api/health` en la misma línea ⇒ la pareja de informes *es* la discriminación que faltaba.

### C4 · Los dos sentidos del criterio — ✓ (medidos sobre el arranque real del guardián)

| Escenario | `/api/health` | `/api/products` | `/api/providers` |
|---|---|---|---|
| Base arriba | **200** (`pgAvailable: true`) | **200** | **200** |
| Base caída | **503 `DEGRADED`** + cabecera | **503 `DATA_LAYER_DEGRADED`** + cabecera | **503** + cabecera |

### C5 · El test es de comportamiento y caza las desviaciones — ✓

Su suite `dbStatusLock.test.js` (6 casos) llama a las funciones puras y afirma salidas ✓ (el único `toContain` es sobre el mensaje que produce el código, no sobre texto de archivo). **Mis dos mutaciones propias la pusieron en rojo**, ancladas en el código y pegando la línea mutada:
1. `decidirBloqueo`: «sin comprobar» ⇒ `shouldBlock: true` → **`1 failed, 5 passed`**.
2. `clasificarSalud`: «sin comprobar» ⇒ `status: 'OK'` → **`1 failed, 5 passed`**.
Archivo restaurado idéntico en ambos casos ✓. Regla §6 de `TRAMPAS.md` respetada (nada anclado en comentarios).

### C6 · CI-21 no se tocó — ✓

`tenantRouting` aparece **0 veces** en el diff ✓. Declarado en su informe ✓.

### C7 · Regresión — ✓ en las suites que dependen de esto

Corridas por mí en su commit: `dbStatusLock` **6/6** ✓ · `degradedLockBehavior` **4/4** ✓ (no la tocó y sigue verde) · `audit360-remediation` **19/19** ✓ · `memoryFallbackProductionGuard` **2/2** ✓ · `smokeSurfaces` (ronda 5) **4/4** ✓. *No corrido por mí:* la suite completa (66 coleccionables) y las 15 rojas heredadas ⇒ `NO MEDIDO` en esta ronda.

---

## Residuos

- **CI-23 (nueva)**: el candado no comprueba cuando el estado es «sin comprobar» ⇒ la protección deja de ser estructural en cualquier proceso que sirva sin el callback de arranque (tests, harness). Sin fuga demostrada. → **ronda 7**.
- **CI-14** sigue siendo el cuello del CI (paso 7) y **sigue sin autorización** del Dueño.
- Efecto lateral declarado: el guardián ahora arranca la app en modo desarrollo, así que **aplica migraciones** a la base contra la que corre (visto en la corrida local: «78 migraciones aplicables» y avisos de deriva). Es coherente con «arrancar la app como la app», pero conviene saberlo antes de cablearlo en CI alguna vez (hoy **no** está en los workflows: verificado por `grep smoke .github/workflows/*.yml` = 0).

## Lo que esta ronda cierra

- **CI-17 CERRADA**: el caso sano ya se produce y está medido por mí (informe `-ok.json`, `IsDegraded=false`, `EXIT=0`).
- **CI-20 CERRADA**: el informe y su nombre dicen la verdad del entorno y el artefacto commiteado se regenera.
- **CI-22 CERRADA**: `pgAvailable` ya distingue «sin comprobar» (`null`) de «comprobado y falló» (`false`).
