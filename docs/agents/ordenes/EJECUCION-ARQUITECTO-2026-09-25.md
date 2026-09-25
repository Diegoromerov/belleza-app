# EJECUCIÓN DEL ARQUITECTO — 2026-09-25 (O-013/ronda 7 y O-016)

Por instrucción del Dueño («continuar en la ejecución»), el Arquitecto ejecutó **dos** de las órdenes en vuelo. **Declaración de conflicto de interés: quien escribe ejecutó y verificó su propio código**; la evidencia está pegada abajo para que el Ejecutor o el Dueño puedan revisarla. No se saltó ninguna regla del sistema: ramas nuevas, sin `--force`, sin tocar `main` ni el vehículo, sin mergear.

## 1. O-016 — `fix/contrato-convive-con-candado` @ `3a9148ad` (pushed)

**Cierra CI-28** (el test de contrato de A-03 chocaba con el candado de degradación).

- **Autoría:** el cambio del test **ya estaba escrito en el worktree** cuando fui a implementarlo (apareció 2m36s después de crear el worktree; Antigravity estaba activo). **No fui yo.** No lo edité: lo verifiqué, lo cerré tal cual y lo declaré en el mensaje del commit.
- **Qué hace:** el caso C2/C4 neutraliza la capa del candado (`degradedLockMiddleware`) antes de medir, porque el candado responde `503 DATA_LAYER_DEGRADED` a cualquier superficie de datos bajo `/api` cuando el estado no está verificado y taparía el 404 que ese caso mide.
- **Evidencia:**
  - **4 escenarios**: `NODE_ENV=test` y `development` × con base real y sin base ⇒ **3/3 PASS en los cuatro** (ya no depende del estado de la base).
    *Precisión (medida después):* en esa primera corrida la credencial iba dentro de una URL que **no conecta** (ver §4), de modo que los dos escenarios «con base» eran en rigor «con `DATABASE_URL` puesta». **Re-medido con las credenciales que sí conectan** (`DB_*` sueltos, base arriba): `test` **3/3** y `development` **3/3**. La evidencia más fuerte sigue siendo el tren integrado (§3).
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

## 5. Segunda tanda (misma instrucción: «continúa»)

### 5.1 Cargo 2 de la ronda 7 — el timeout del guardián, medido @ `82f84f5e` (misma rama)

`smokeSurfaces.js:210-214` ya fallaba explícito por timeout pero **nunca se había medido**: el helper no estaba
exportado ni admitía inyección, así que ningún test podía recorrer ese camino. Ahora `startRealServerAndAwaitChecked(deps = {})`
acepta `spawn`/`makeRequest`/`exit`/`maxWaitMs`/`cwd`/`entry` (con `deps` vacío, comportamiento idéntico al real) y está exportado.

- **Test 3/3**: (a) no cuelga — termina dentro del timeout; (b) sale `≠0` (código 1); (c) mata al hijo con `SIGTERM`, una sola vez. + control: si el estado se comprueba, no mata ni sale.
- **Regresión**: el camino **real** del guardián (`smokeSurfaces.test.js`, arranca la app de verdad) verde; con `dbStatusLock`, `degradedLockBehavior` y `candadoCompruebaSiDesconoce` ⇒ **4 suites / 20 tests PASS**.
- **Mutación pegada**: eliminada la rama de timeout (7 líneas) ⇒ **2 failed / 1 passed**, archivo restaurado con `node --check` OK.
- **Nota de método (trampa §6)**: el primer intento de mutación **no se aplicó** (regex contra CRLF) y el test salió verde sobre un archivo sin mutar. Se rehízo por líneas y se verificó sintaxis antes y después: *una mutación que no se aplicó, o un archivo restaurado sin verificar, no son evidencia*.

### 5.2 A-02 ronda 3 — «el mes que miente» (CI-18) @ `6f2f656f`

**Causa raíz**: `nextMonthDate.setMonth(nextMonthDate.getMonth() + 1)` sobre **hoy**; si hoy es 29, 30 o 31 JavaScript
normaliza (31 de enero + 1 mes = 3 de marzo) y la etiqueta saltaba el mes. Además `toISOString()` es UTC sobre fecha local.
El **importe** era correcto: mentía el mes que ve el admin.

- **Fix**: mes calendario siguiente a `now` **anclado al día 1** (aritmética de enteros sobre año/mes) y formateado en **local**. Importe y tendencia intactos.
- **RED primero**: `now=2026-01-31 ⇒ '2026-03'` (debe ser `'2026-02'`) y `now=2026-03-31 ⇒ '2026-05'` (debe ser `'2026-04'`) ⇒ 2 failed.
- **GREEN 5/5** (incluye `2026-12-31 ⇒ '2027-01'` y que el importe no cambia) · suite heredada **4/4** · **mutación** (`setMonth` sobre hoy) ⇒ **2 failed / 3 passed**.
- El test importa el servicio y afirma sobre lo que devuelve (no mira el código como texto).

### 5.3 Estado tras la segunda tanda

| Rama | SHA | Contenido |
|---|---|---|
| `fix/candado-comprueba-si-desconoce` | `e3c75840` + `82f84f5e` | CI-23 + Cargo 2 (timeout del guardián) |
| `fix/admin-metricas-sin-datos` | `6f2f656f` | A-02 ronda 3 (CI-18) |
| `fix/contrato-convive-con-candado` | `3a9148ad` | O-016 (CI-28) |

**Ojo para el aterrizaje:** la rama de la ronda 7 ahora también toca `backend/scripts/smokeSurfaces.js`; al integrarla en el tren,
ese archivo viene de la misma base (`07e7225e`) y no debería dar conflicto, pero **el ensayo del tren debe re-correrse** antes de mergear. No se movió nada compartido: `main` = `f5a1b4fc`, `fase-a` = `b545ef22`, el vehículo sigue en `0a32f718` en el worktree de Antigravity (intacto).
