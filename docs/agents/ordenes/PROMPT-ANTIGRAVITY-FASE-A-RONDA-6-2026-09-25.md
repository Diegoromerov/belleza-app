# ORDEN A · Fase A · RONDA 6 (corta) — «el estado que nunca se comprobó»

**Para:** Antigravity (Ejecutor). **De:** Hermes (Arquitecto).
**Base obligatoria:** `fase-a/verdad-operativa` @ **`b545ef22`** (verifica con `git merge-base --is-ancestor b545ef22 HEAD`). **Rama:** `fix/arranque-y-estado-honesto` (una rama = una tarea = un PR).
**Prohibido:** `--force` y `--force-with-lease` sin pedirlo; borrar ramas (locales o remotas); `gc`; reescribir historia; tocar C-01/C-02/C-03, migraciones, el bundle `backend/public`; recortar superficies del guardián o ampliar exenciones del escáner; mergear.

## Por qué existe esta ronda (medido, no inferido)

El guardián **nunca ejecuta el arranque de la app**: `smokeSurfaces.js:21` fuerza `NODE_ENV=test`, la app solo arranca con `NODE_ENV !== 'test'` (`index.js:1811`) y `await testConnection()` / `await initDatabase()` están **dentro** de ese callback (`:1826-1828`); el guardián llama `app.listen(PORT)` él mismo (`:203`). Resultado medido con la base **arriba** y credencial válida:

- `getDbStatus()` = `{"pgAvailable":false,…}` durante 20 s seguidos (sin transición) ⇒ `/api/health` **503** `DEGRADED` ⇒ `/api/products` **503** `DATA_LAYER_DEGRADED`.
- El informe sale **siempre** `-degraded.json` (`server_degraded: true`), incluso con 0 fakes.
- En cambio, la app arrancada **como en producción** (`NODE_ENV=development PORT=3958 node index.js`) responde `/api/health` **200**, `/api/test-db` **200**, `/api/products` **200 con 296 productos**.

O sea: `pgAvailable: false` hoy significa a la vez «comprobé y falló» y «nunca comprobé». Eso hace que el candado de degradación pueda bloquear `/api` **con la base sana**, y que un veredicto «la app dice la verdad» no se pueda emitir.

## Cargo 1 (app) — el estado de la base dice la verdad

1. `getDbStatus()` debe distinguir **«sin comprobar»** de **«comprobado y falló»** (p. ej. `pgAvailable: null` antes de la primera comprobación, `false` solo tras un fallo real, `true` tras un éxito). `db.js` es punto único de inyección del tenant: **no** cambies su API de conexión ni el wrapper del pool; el cambio es de *estado*, no de conexión.
2. `/api/health` (`index.js:431-441`) y `/api/test-db` (`:443+`) deben reportar ese estado **sin mentir**: mientras no haya comprobación, el `status` no puede decir `DEGRADED` (usá `'UNKNOWN'`/`'CHECKING'`) y `database.pgAvailable` debe reflejar `null`.
3. El candado de degradación (`src/middleware/degradedLock.js`) no puede bloquear `/api` por un flag **rancio**: si el estado es «sin comprobar», la comprobación ocurre (una vez, con caché acotada) y decide; si es `false` real, bloquea como hoy.
4. **Criterio de aceptación (los dos sentidos, obligatorio pegar ambos):**
   - **a)** Con la base arriba y el servidor levantado **por el mismo camino que en producción**, `GET /api/health` ⇒ `200` con `database.pgAvailable: true` y `GET /api/products` ⇒ `200` (no 503).
   - **b)** Con la base caída (parar el contenedor o apuntar a un puerto muerto), `GET /api/health` ⇒ `503 DEGRADED` y `GET /api/products` ⇒ `503 DATA_LAYER_DEGRADED`. **El comportamiento de (b) no se degrada.**

**C1** todo lo anterior + **C2** el fix nace de un test que **primero falla** (extraé la decisión a funciones puras exportadas: `clasificarSalud(dbStatus)` y `decidirBloqueo(dbStatus)`, y probá la tabla de casos: `null`⇒no bloquea/no DEGRADED, `true`⇒sirve, `false`+`servingFabricatedData`⇒bloquea).

## Cargo 2 (guardián) — arrancar la app como la arranca la app

1. `smokeSurfaces.js` no puede `require('../index')` y llamar `app.listen` por su cuenta: tiene que levantar el servidor por el **camino real** (proceso hijo `node index.js` con `NODE_ENV` de desarrollo, o el mecanismo que elijas) y **esperar disponibilidad real** (sondear `/api/health` hasta obtener una respuesta con estado comprobado, con timeout y fallo explícito si no llega). Nada de `sleep` fijo como única espera.
2. El informe debe registrar el estado crudo del entorno: `health_status`, `pg_available` y `routes_source` (ya está) ⇒ que un lector distinga una corrida sana de una degradada **sin leer la consola**.
3. **Criterio:** con la base arriba, el guardián escribe `docs/audit/smoke-<fecha>-ok.json` con `"server_degraded": false` y `routes_source: "express_stack"`; con la base caída, `-degraded.json`. **Pegá las dos corridas**, cada una con su línea `📊 Estado del servidor detectado (probes inicio): IsDegraded=…, HealthStatus=…`.

**C3** el `-ok.json` commiteado (ronda 4, sin `routes_source`) o se **regenera** con el código actual o se **declara obsoleto** en el propio archivo/KB. No lo dejes mintiendo: hoy dice `server_degraded: false` y no es reproducible.

## Cargo 3 (opcional, **solo si el Dueño lo autoriza**): CI-21

Con la base inalcanzable, `tenantRouting.js:170` (`runAsSystem` → `deps.pool.connect()`) deja un `Unhandled Rejection` sin dueño. Si hay autorización: capturá y logueá el fallo (sin cambiar la política de tenancy) y probá que el proceso **no** emite `unhandledRejection` con la base caída. Sin autorización, **no lo toques** y decilo en el informe.

## Prohibiciones y forma de entrega

- Nada de `--force`/`--force-with-lease`, ni podar ramas: si algo se resiste, **parás y reportás**.
- No toques C-01/C-02/C-03, migraciones, el bundle `backend/public`, ni `index.js` más allá del handler de salud y lo mínimo del candado.
- Evidencia obligatoria en el informe: `git log -1 --format='%h %s'` + `git status --porcelain`; el comando exacto y su salida pegada (incluidas las líneas `📊 Estado del servidor detectado…`); **la mutación pegada** (RED→GREEN) de C2; y la declaración de si Cargo 3 se hizo o no.
- Si un criterio no se puede cumplir, **parás y reportás el motivo medido** en vez de maquillar la salida. Un informe con «no pude» vale; un verde falso se rechaza.
