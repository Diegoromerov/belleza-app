# ORDEN A · Fase A · RONDA 7 (corta) — «sin comprobar no es lo mismo que sano»

**Para:** Antigravity (Ejecutor). **De:** Hermes (Arquitecto).
**Base obligatoria:** `fix/arranque-y-estado-honesto` @ **`07e7225e`** (encadenada: la ronda 6 todavía no está mergeada; verificá con `git merge-base --is-ancestor 07e7225e HEAD`). **Rama:** `fix/candado-comprueba-si-desconoce`.
**Prohibido:** `--force`/`--force-with-lease` sin pedirlo; borrar ramas; reescribir historia; tocar C-01/C-02/C-03, migraciones, el bundle `backend/public`, `tenantRouting.js` (CI-21, sin autorización del Dueño), la línea de `scripts/COMO_EJECUTAR.md` (CI-14, sin autorización); recortar superficies del guardián o ampliar exenciones del escáner; mergear.

## Por qué existe (medido sobre tu propia entrega `07e7225e`)

Arreglaste bien el tri-estado, pero el candado quedó a medias: con `pgAvailable === null` devuelve `shouldBlock: false` (`reason: 'UNCHECKED'`) **sin comprobar nada**. Medido con la base caída en un proceso que sirve sin el callback de arranque (que es el camino de los tests y de cualquier harness): `/api/health` = **200 `UNKNOWN`**, `/api/products` = **500** y `/api/providers` = **503**. No hay `2xx` fabricado, pero **antes de tu ronda el candado bloqueaba desde la primera petición**; ahora la protección depende de que cada ruta falle honestamente. Mi C1.3 pedía otra cosa: *si el estado es «sin comprobar», la comprobación ocurre (una vez, con caché acotada) y decide*.

## Cargo 1 — el candado comprueba cuando no sabe

1. Si `pgAvailable === null`, el candado **provoca la comprobación** (`testConnection()` o el mecanismo que ya uses) **una sola vez**, con caché acotada (TTL corto), y decide con el resultado: `true` ⇒ pasa; `false`/`servingFabricatedData` ⇒ **503** como hoy.
2. Misma regla en `/api/health`: si el estado es `null`, comprueba antes de clasificar (ya lo hacés en `/api/test-db`, `index.js:449-451`) ⇒ con base arriba debe decir **200 `OK`** (no `UNKNOWN`); con base caída, **503 `DEGRADED`**. `UNKNOWN` queda sólo para el caso «comprobación en vuelo / no concluyente», nunca como sustituto de una comprobación no hecha.
3. **No** vuelvas a «bloquear siempre cuando `null`»: eso reintroduce el falso `DEGRADED` con la base sana que cerró CI-20. La garantía es **comprobar**, no bloquear a ciegas.
4. El middleware puede volverse `async`; cuidá no bloquear el event loop ni encadenar comprobaciones por petición (caché).

**Criterio de aceptación (en el camino SIN callback de arranque: `require('../index')` + `app.listen`, `NODE_ENV=test`, y los dos sentidos pegados):**
- **a)** Base arriba ⇒ `/api/health` **200 `OK`** con `pgAvailable: true` y `/api/products` **200**.
- **b)** Base caída (URL a puerto muerto) ⇒ `/api/health` **503 `DEGRADED`** y `/api/products` **503 `DATA_LAYER_DEGRADED`**, **ya en la primera petición** de datos (no en la segunda).
**C1** lo anterior. **C2** el fix nace de un test que **primero falla**: casos puros (`null` ⇒ comprueba y con fallo decide bloquear) + **mutación pegada** (quitar la comprobación ⇒ rojo).

## Cargo 2 — el timeout del guardián, probado

El guardián ya falla explícito por timeout (`smokeSurfaces.js:211-212`) pero eso **nunca se midió**. Agregá un test que, con el hijo imposible de alcanzar (por ejemplo un `PORT` ocupado o un entry que no responde), verifique: (a) **no cuelga** (termina dentro del timeout), (b) sale **≠0**, (c) **mata el hijo** (`SIGTERM`, sin procesos huérfanos). Pegá la corrida y la mutación (quitar el timeout ⇒ el test debe caer).

## Cargo 3 (opcional, **solo con autorización del Dueño**): CI-14

Si el Dueño autoriza, borrá las 5 líneas de prosa de CI-14 (`AUDITORIA_PREPRODUCCION_MASTER.md:84`, `BLOQUE_TRABAJO_1_BASELINE.md:144`, `auditoria-belleza-app.md:232`, `:233`, `scripts/COMO_EJECUTAR.md:35`) en una rama aparte y con el escáner corriendo antes y después (8 ⇒ 3). Sin autorización: **no la toques** y decilo.

## Entrega

Evidencia obligatoria: `git log -1 --format='%h %s'` + `git status --porcelain`; los comandos exactos y sus salidas (los dos sentidos del Cargo 1 en el camino sin arranque, con `HealthStatus`/`PgAvailable` visibles); **la mutación pegada** (RED→GREEN) de cada cargo; y la declaración de si el Cargo 3 se hizo. Si algo no se puede cumplir, **parás y reportás el motivo medido**.
