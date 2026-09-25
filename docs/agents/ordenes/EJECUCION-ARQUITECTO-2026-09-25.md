# EJECUCIÓN DEL ARQUITECTO — 2026-09-25 (O-013/ronda 7 y O-016)

Por instrucción del Dueño («continuar en la ejecución»), el Arquitecto ejecutó **dos** de las órdenes en vuelo. **Declaración de conflicto de interés: quien escribe ejecutó y verificó su propio código**; la evidencia está pegada abajo para que el Ejecutor o el Dueño puedan revisarla. No se saltó ninguna regla del sistema: ramas nuevas, sin `--force`, sin tocar `main` ni el vehículo, sin mergear.

## 1. O-016 — `fix/contrato-convive-con-candado` @ `3a9148ad` (pushed)

**Cierra CI-28** (el test de contrato de A-03 chocaba con el candado de degradación).

- **Autoría:** el cambio del test **ya estaba escrito en el worktree** cuando fui a implementarlo (apareció 2m36s después de crear el worktree; Antigravity estaba activo). **No fui yo.** No lo edité: lo verifiqué, lo cerré tal cual y lo declaré en el mensaje del commit.
- **Qué hace:** el caso C2/C4 neutraliza la capa del candado (`degradedLockMiddleware`) antes de medir, porque el candado responde `503 DATA_LAYER_DEGRADED` a cualquier superficie de datos bajo `/api` cuando el estado no está verificado y taparía el 404 que ese caso mide.
- **Evidencia:**
  - **4 escenarios**: `NODE_ENV=test` y `development` × con base real y sin base ⇒ **3/3 PASS en los cuatro** (ya no depende del estado de la base).
  - **Mutación pegada**: `app.use('/api/admin', adminPreciosRoutes)` → `'/api/admin/precios'` ⇒ **2 failed / 1 passed** (caen C1,C3 y C2,C4); `index.js` restaurado **IDÉNTICO**.
  - Hash del archivo de test inalterado durante las corridas (sin escritura concurrente mientras medía).

## 2. O-013 — Fase A ronda 7 — `fix/candado-comprueba-si-desconoce` @ `e3c75840` (pushed)

**Implementa CI-23**: el candado (y `/api/health`) ahora **comprueban** cuando el estado es desconocido, en vez de decidir sin saber.

- `degradedLock.js`: nueva `asegurarEstadoComprobado()` — caché TTL de 5 s + promesa en vuelo (una comprobación por ventana, sin martillar la base); el middleware pasa a `async` y decide con el estado ya comprobado. Si la comprobación falla o explota, **no se inventa estado**: se decide con lo que `getDbStatus()` reporte (sigue «desconocido» ⇒ no bloquea a ciegas, que reintroduciría el falso `DEGRADED` con la base sana que cerró CI-20).
- `index.js`: `/api/health` consume la **misma** función (una fuente de verdad y el mismo TTL); `/api/test-db` ya lo hacía desde la ronda 6.
- **Test nuevo** `candadoCompruebaSiDesconoce.test.js` (6 casos: comprueba-y-pasa · comprueba-y-bloquea · caché exactamente 1 · no recomprueba si ya sabe · allowlist sigue exenta · si la comprobación explota no se inventa estado).
- **Evidencia:**
  - **RED primero** (a y b fallaban: el middleware nunca llamaba a `testConnection`); **GREEN: 6/6**.
  - **Mutación pegada** (quitar `await db.testConnection()`) ⇒ **3 failed / 3 passed** (caen a, b y c).
  - **Regresión**: `dbStatusLock` 6/6 · `degradedLockBehavior` 4/4 · `smokeSurfaces` 4/4 = **14/14**.
  - **Comportamiento real** (proceso que sirve **sin** el arranque de `index.js`, igual que el guardián): base **arriba** ⇒ `/api/health` **200 `pgAvailable=true` `dbMode=postgres` `status=OK`** en la primera petición y `/api/products` **200**; base **caída** ⇒ `/api/health` **503 `DEGRADED`** y `/api/products` **503 `DATA_LAYER_DEGRADED`**.
- **Pendiente en esa misma rama:** Cargo 2 (test del timeout del guardián) y Cargo 3 (CI-14, condicionado a autorización del Dueño).

## 3. Ensayo del tren **con O-016** — el tren puede aterrizar

Worktree detachado en `b545ef22` + merges: `fix/ci-procedencia`, `fix/rls-056-058-cadena`, `fix/montajes-unicos`, `fix/admin-metricas-sin-datos`, `fix/arranque-y-estado-honesto`, `fix/contrato-convive-con-candado`.

- **6 merges, 0 conflictos** (HEAD del ensayo `0384b058`).
- **5 suites / 21 tests PASS**: `routing.contract` ✅ (antes de O-016: rojo), `dbStatusLock`, `degradedLockBehavior`, `smokeSurfaces`, `adminMetricsDataStatus`.
- `fase-a/verdad-operativa` = `b545ef22` y `main` = `f5a1b4fc` **sin mover**.

⇒ **Con O-016 integrado, el tren pasa las suites clave.** Queda una sola cosa entre el tren y `main`: la decisión del Dueño (y CI-14, que es lo que impide que el CI llegue a ejecutar la suite).

## 4. Corrección mía (R-06) y hallazgos de entorno

- **Corrección:** en `ENSAYO-TREN-A-2026-09-25.md` escribí que el rojo del tren estaba «medido con base real». **Era falso: el demonio de Docker estaba caído** (contenedor `beauty-postgres` parado, `ECONNREFUSED 5435`) ⇒ esa corrida no tenía base. El hallazgo (**CI-28**) sigue en pie —el fix y los 4 escenarios lo demuestran— pero la cita era incorrecta.
- **La credencial del contenedor no sirve dentro de una URL**: `postgres://admin:***@127.0.0.1:5435/beauty_db` caía a memoria; los mismos datos como campos sueltos (`DB_USER/DB_PASSWORD/DB_NAME/DB_HOST/DB_PORT`, que `db.js:28-34` soporta) conectan (`TCP OK → beauty_db`). Nunca se imprimió el valor.
- **Docker caído se confunde con el candado**: con el daemon parado, `/api/health` da 503 y parece «el candado bloquea» cuando en realidad no hay base. **Antes de concluir nada sobre el candado, verificar que el banco de trabajo está arriba.**
- **Escritura paralela:** el fix de O-016 apareció sin commitear en **mi** worktree mientras Antigravity estaba activo ⇒ **regla propuesta al Dueño: un worktree = un agente**.
