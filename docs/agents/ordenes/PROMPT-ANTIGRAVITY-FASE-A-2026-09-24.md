# GOAL — Fase A: Verdad operativa (Belleza App / GlowApp)

**Goal (una frase):** que el backend y la app dejen de afirmar éxito cuando no lo tuvieron — ninguna
superficie responde 2xx si su consulta falló, la degradación es visible desde fuera, el CI existe y
puede fallar, y un solo comando recorre todas las superficies y sale ≠0 si alguna finge.

**Repo:** `C:\beauty-app` · **Rama a crear:** `fase-a/verdad-operativa` · **Base:** `origin/main` (su `HEAD` debe registrarse en la entrega; el valor que medí en el clon local fue `e6e116bd`, confírmalo con `git fetch && git log -1 --format='%h %s' origin/main`).
**Tamaño:** 2,0 días-persona · **Una sola rama**, commits por tarea, PR al final.

---

## 0. Reglas del encargo (no negociables)

1. **Nunca** push directo a `main`, **nunca** `--force`, **nunca** reescribir historia.
2. Trabaja en tu propio worktree (`C:/Users/Compu casa/.gemini/antigravity/worktrees/beauty-app/<nombre>`), cortado de `origin/main`, **no** del árbol sucio. Otra persona edita `C:\beauty-app` en paralelo: no hagas `git switch main` allí ni toques sus archivos.
3. **Toda afirmación va con evidencia ejecutada**: comando + salida cruda, o `archivo:línea`. Prohibido "todo funciona", "se corrigió" o "queda funcionando".
4. **Los números de línea derivan**: antes de cada edición re-verifica el ancla con `grep -n` sobre tu árbol. Si el ancla no está donde digo, **reporta el desfase y detente en esa tarea**, no adivines.
5. **Una clase de arreglo: honestidad de estado.** Nada de arreglar flujos de negocio en esta rama (ver §5 NO TOCAR).
6. Si algo no lo puedes verificar en tu entorno, escribe **no verificable** y por qué. Nunca lo declares verde.

---

## 1. Contexto medido (esto es lo que hay hoy, comprobado)

| Hecho | Evidencia |
|---|---|
| El CI está muerto: `ci.yml` no es YAML válido por marcadores de conflicto de merge commiteados, y también están en `main` | `git show main:.github/workflows/ci.yml \| grep -n '^<<<<<<<'` → 60 (`=======` en 84, `>>>>>>>` en 90). Parser: `ScannerError … line 60, column 1` / `line 61, column 7` |
| El otro workflow está sano | `python -c "import yaml;yaml.safe_load(open('.github/workflows/rag-evaluation.yml'))"` → OK |
| `.gitignore` también tiene marcadores | `git show main:.gitignore \| grep -n '^<<<<<<<'` → 32, 84 |
| El detector de datos fabricados **nunca se enciende** | `src/config/db.js:709` declara `let servingFabricatedData = false;`, `:720-723` lo expone en `getDbStatus()`; `grep -n servingFabricatedData src/config/db.js` → solo 709 y 722: **0 asignaciones** |
| `/api/health` ya sabe reportar degradación, pero nunca la ve | `index.js:418-428` responde 503 `DEGRADED` si `servingFabricatedData \|\| pgAvailable === false` |
| Una superficie devuelve `200` cuando su consulta falla | `src/controllers/providerController.js:170-173`: `catch` → `res.status(200).json({ success: true, count: 0, data: [] })` |
| Existe un fallback geográfico que inventa coordenadas | `src/controllers/providerController.js:117-139` (lat/lon fijos `4.6739/-74.1422`, sin radio ni verificación) |
| En `test` el modo memoria está habilitado por defecto | `src/config/db.js:140-149` (en producción **aborta** el boot si `ALLOW_MEMORY_FALLBACK=true`; en `NODE_ENV=test` o `!== production` sirve memoria) |
| Stack local disponible | `backend/docker-compose.yml`: `postgres` 5435, `redis` 6379, `backend` 8080 |
| Guardianes ya escritos que se deben **cablear**, no reescribir | `backend/scripts/`: `verifyNoFabricatedPayments.js`, `verifyNoVersionedSecrets.js`, `verifyTenantIsolation.js`, `verifyTestBaseline.js`, `prepareRlsDatabase.js`, `smoke_test_prod.js` |

**Baseline de suites que SÍ medí** (en `C:/beauty-app/backend`, no en tu worktree):
`NODE_ENV=test npx jest tests/booking.test.js tests/payment.test.js src/tests/provider_schedule.test.js --silent` → **3 suites, 8 tests, 0 fallos**.

**La suite completa NO la medí.** Tu primera tarea es medirla y reportarla antes de tocar código (ver §4, tarea 0).

---

## 2. Tareas, en orden de ejecución

### TAREA 0 — Línea base (obligatoria, antes de todo) · S
```bash
cd backend
NODE_ENV=test npx jest --maxWorkers=2 --silent 2>&1 | tail -6
```
Entrega: `BASE = <suites fallidas> / <total>` + la lista de nombres de suites fallidas + si el comando necesitó `DATABASE_URL`. Si el número difiere del que yo medí en los 3 archivos de arriba, repórtalo crudo: puede ser mi entorno, y quiero saberlo.

---

### TAREA A2.T1 — `ci.yml` vuelve a ser un workflow válido · S
**Archivo:** `.github/workflows/ci.yml`, bloques en las líneas 60/84/90 (ancla: `<<<<<<< HEAD` … `>>>>>>> origin/main`).
**Decisión ya tomada (no la re-litigues):** al resolver el conflicto, **quédate con el lado que prepara RLS** — `node scripts/prepareRlsDatabase.js` + `node scripts/verifyTenantIsolation.js`, con `DATABASE_URL_ADMIN` y `RLS_ROLE_PASSWORD` — y **descarta** el lado que hacía `npm run migrate` / `sequelize.sync({force:true})`. Razón: un esquema derivado de los modelos Sequelize no lleva políticas de RLS y ya divergió del esquema desplegado.
**Verificación (pega la salida):**
```bash
python -c "import yaml;yaml.safe_load(open('.github/workflows/ci.yml'));print('YAML OK')"
grep -c '^<<<<<<<' .github/workflows/ci.yml   # debe imprimir 0
```
**Nota de comportamiento que debes reportar:** con `ci.yml` inválido en `main`, GitHub no ejecuta ningún workflow en `main`; en **tu rama** (que lo arregla) sí correrá. Comprueba que el run aparece en el PR y pega su URL.

### TAREA A2.T2 — `.gitignore` sin marcadores · S
**Archivo:** `.gitignore`, bloques en 32/36/37 y 84/85/94.
**Cambio:** fusiona **ambos** lados del conflicto (reglas de informes de baseline **y** `frontend/android/gradle/wrapper/`, `*.pkl`, `analyze_rows.pkl`, `audit_lib.pkl`). Perder una regla reintroduce artefactos versionados.
**Verificación:** `grep -c '^<<<<<<<' .gitignore` = 0 y `git status --porcelain` sin artefactos de Gradle/`.pkl` tras un build local.

### TAREA A2.T3 — Compuerta anti-marcadores + cableado de guardianes · S
**Crear:** `backend/scripts/checkNoConflictMarkers.js` — recorre los archivos versionados (`git ls-files`) y falla (exit 1) si alguno contiene una línea que empiece por `<<<<<<<`, `=======` o `>>>>>>>`. Excluye `node_modules`, `.git`, artefactos binarios.
**Editar:** `.github/workflows/ci.yml` — añade el step de esa compuerta y, si no está, un step `node scripts/verifyNoVersionedSecrets.js`.
**Mutación obligatoria (pega las dos salidas):** antes → RED con el marcador insertado a mano en un archivo temporal (bórralo después); después → GREEN sobre el árbol limpio.

### TAREA A1.T1 — Encender el detector `servingFabricatedData` · M
**Archivos:** `src/config/db.js` — `handleMemoryQuery` (:149), `pasarAMemoria` (:591-595), la rama de recuperación (:609-624), `testConnection` (:657-680), `getDbStatus` (:709-723).
**Cambio:** `servingFabricatedData = true` en el instante exacto en que una consulta se responde desde memoria; `false` cuando el modo vuelve a `postgres`. `pgAvailable` debe derivarse de `dbMode === 'postgres'`, no de un flag que nadie actualiza. **No elimines el fallback de memoria** en dev/test: la decisión ya tomada es que se queda, pero visible.
**Test nuevo:** `src/tests/dbTruthfulDegradation.test.js` — con un error de enlace simulado: `getDbStatus().servingFabricatedData === true`; tras una recuperación simulada: `false`.
**Mutación (pega las dos salidas):** con el fallback activo, `GET /api/health` ⇒ **503 `DEGRADED`** y `database.servingFabricatedData: true`. Hoy responde 200 `OK`.
**Trampa:** existen `src/tests/audit360-remediation.test.js:57-88` (exige que `getDbStatus()` tenga `servingFabricatedData`, `memoryFallbackAllowed`, `pgAvailable`, y que en producción sin opt-in el fallback no esté permitido) y `src/tests/memoryFallbackProductionGuard.test.js`. Ámbos deben seguir **verdes**; si alguno se pone rojo, es tu cambio el que está mal, no el test.

### TAREA A1.T2 — La degradación viaja en la respuesta · S
**Archivo:** `index.js`, junto a los middlewares de `:340-380`.
**Cambio:** si `getDbStatus().servingFabricatedData`, añadir la cabecera `X-GlowApp-Degraded: memory-fallback` a toda respuesta. Sin esto, un cliente no puede distinguir una lista vacía legítima de una fabricada.
**Mutación:** en modo memoria, toda respuesta lleva la cabecera; en modo Postgres, ninguna. Pega `curl -si` de ambos casos.

### TAREA A1.T3 — `GET /api/providers` deja de mentir · M
**Archivo:** `src/controllers/providerController.js:170-173` (y el fallback de `:117-139`).
**Cambio:** (a) si la consulta falla ⇒ `503 { error: 'PROVIDER_SEARCH_UNAVAILABLE' }`; el `200 {count:0}` queda reservado a "la consulta corrió y no hay resultados". (b) El fallback PostGIS no se borra: márcalo en el cuerpo con `degraded: true` y una nota de que las coordenadas no son reales.
**Mutación (pega las dos salidas):** con Postgres detenido ⇒ 503; con la base viva y una ciudad sin prestadores ⇒ 200 `count: 0`. Hoy ambos casos devuelven lo mismo.
**Trampa:** `providerController.getProviders` es público (sin `authMiddleware`) y lo consume el mapa de la app. No cambies la forma de la respuesta en el caso feliz (`success/count/data` + campos ya existentes).

### TAREA A1.T4 — Barrido mecánico: `catch` que responde 2xx · M
**Crear:** `backend/scripts/auditFakeSuccess.js` — reporta cada `catch` cuyo `res.status(2xx)`/`res.json(...)` de éxito esté a ≤15 líneas. Salida JSON + lista ordenada por archivo.
**Entregable:** `docs/audit/fake-success-2026-09-24.json` con `archivo:línea` y veredicto por caso: `finge` o `legítimo con aviso`.
**Orden importante:** córrelo **antes** de A1.T3 y guarda esa salida como línea base (debe detectar `providerController.js:170`); luego vuelve a correrlo.
**Caso ya visto para decidir (no arreglar a ciegas):** `src/controllers/analyticsController.js:36` devuelve `200 { message: 'Telemetry processed with warning' }` en el `catch`. Mi recomendación: mantener 200 (es telemetría) pero renombrar a `warnings: [...]`. Si no lo tienes claro, **déjalo como está y súbelo a la lista de preguntas abiertas del PR**.

### TAREA A1.T5 — La UI no afirma lo que no se ejecuta · M
**Archivos:** `frontend/lib/widgets/wompi_payment_sheet.dart` (formularios Nequi/Tarjeta en `:594-684`) y `frontend/lib/screens/provider_dashboard_screen.dart:350-378`.
**Cambio:** (a) mientras no exista pasarela integrada, **no recoger número de tarjeta, vencimiento, CVV ni titular**; sustitúyelo por un aviso explícito de "cobro en línea no disponible" manteniendo la firma pública de `showWompiCheckoutSheet`. (b) El desglose de liquidación debe usar `comision_plataforma` / `impuestos_estado` / `pago_neto_prestador` que la API **ya devuelve** (`backend/src/controllers/bookingController.js:246-281`), y hay que borrar el `gross * 0.20` hardcodeado (`:354-355`) y la frase "la plataforma asume y reporta este impuesto en tu beneficio" (`:365-374`), que contradice el asiento real.
**Verificación:** `grep -rn "0\.20\|_cvvCtrl\|_cardCtrl" frontend/lib` ⇒ 0 coincidencias en las rutas de cobro de cita.
**Trampas:** (1) ese sheet es **compartido** con la tienda (`frontend/lib/screens/store_screen.dart:10`): el cambio no debe romper el camino de error honesto de la tienda ni las llamadas de analítica (`logInitiateCheckout(..., itemType: ...)`). (2) El bundle Flutter web que sirve el backend es un artefacto **commiteado** (`backend/public`): **no** lo reconstruyas ni lo commitees en esta rama; dilo en el PR como "requiere rebuild (decisión del dueño)".

### TAREA A3.T1 — Inventario mecánico de rutas · S
**Crear:** `backend/scripts/listRoutes.js` — levanta la app sin `listen()` y recorre `app._router.stack` para emitir `{method, path, middlewares}` de todos los mounts (`index.js:379-414`, `:522-526`, `:983`).
**Entregable:** `docs/audit/routes-2026-09-24.json`. Nada de listas escritas a mano.
**Verificación:** el JSON incluye `POST /api/bookings` y `POST /api/payments/wompi-webhook`; pega `jq '.length'`.

### TAREA A3.T2 — Smoke honesto por superficie · M
**Crear:** `backend/scripts/smokeSurfaces.js` + script npm `smoke:surfaces`.
**Comportamiento:** levanta el stack local (`cd backend && docker compose up -d`), toma un token por rol (cliente, prestador, admin) y recorre el inventario de A3.T1. Por ruta reporta: `status`, `empty_like` (2xx con cuerpo vacío o `data: []`), `degraded_header`, `wrote_to_db` y `faked_success` (2xx en una mutación que debía fallar). Por defecto **solo métodos seguros (GET)**: si necesitas un POST, usa un fixture propio y bórralo con conteos antes/después.
**Entregable:** `docs/audit/smoke-<fecha>.json` + resumen en consola + `exit ≠ 0` si hay cualquier `faked_success`.
**Verificación:** con el stack arriba, `npm run smoke:surfaces` termina con los conteos de `bookings` y `services` **iguales** a los de antes de la corrida (el smoke no deja residuo; pega los dos conteos).

### TAREA A3.T3 — La corrida roja que abre la siguiente fase · S
Con Postgres detenido (`docker compose stop postgres`), corre el smoke y guarda el reporte. Ese archivo es la lista priorizada de lo que hoy finge, y es lo que alimenta las fases B y C.

---

## 3. Guardián de la fase (RED antes, GREEN después — obligatorio)

**Guardián:** `npm run smoke:surfaces` en dos estados.
1. **RED esperado** (antes de A1.T1-T3, con Postgres detenido): el reporte debe listar al menos `GET /api/providers` como `faked_success` (200 con `count: 0`) y `GET /api/health` como 200 `OK` en modo degradado. Pega el bloque JSON de esas dos entradas.
2. **GREEN** (después): cero `faked_success`, `GET /api/health` en 503 `DEGRADED`, `GET /api/providers` en 503, y las rutas legítimamente públicas respondiendo lo mismo que antes.
3. Ambas corridas con el **mismo inventario** de rutas, y con los conteos de `bookings`/`services` intactos antes y después (pega los 4 números).

Un guardián que solo viste verde no mide nada: si no consigues el RED, dilo y detente; probablemente la mutación esté mal elegida.

---

## 4. Entrega

- **Rama:** `fase-a/verdad-operativa` desde `origin/main`. `git log -1 --format='%h padre=%p'` de la rama y el `HEAD` de `origin/main` con el que la cortaste.
- **Commits** por tarea, mensaje `fix(honestidad): <tarea> — <qué>`, sin mezclar T5 (frontend) con lo demás.
- **PR** con: URL real, resumen de 6-10 líneas, y una sección de evidencia con las salidas crudas de §2 y §3.
- **Dos números de suites** en el PR: `BASE = <fallidas>/<total>` y `TU RAMA = <fallidas>/<total>`, con el comando exacto y `--maxWorkers=2`. Si no corriste la suite, escribe "no ejecuté la suite" — omitirlo se lee como verde.
- **Nombres, no solo conteos:** si el conjunto de suites fallidas cambia, pega las dos listas.
- **Artefactos alcanzables:** di si las rutas tocadas son ejercitables con los datos de hoy (rol/tenant/usuario existentes). "Entregado" y "usable" son afirmaciones distintas.
- **Preguntas abiertas** (no decidas por el dueño): (a) `analyticsController.js:36`, ¿200 con `warnings` o 503?; (b) ¿se reconstruye y commitea el bundle Flutter en esta fase o en una tarea de despliegue aparte?; (c) ¿se retira definitivamente el fallback PostGIS de `providerController` o queda marcado como degradado?

---

## 5. NO TOCAR (fuera de alcance de esta rama)

- **El flujo de dinero y verificación:** `paymentRoutes.js` (OTP, `confirm-otp`, wallet, retiros, disputas), `bookingController.payBooking`, `wompiService.js`, `disputeController.js`. Ahí viven los hallazgos C-01/C-02/C-03: **no se arreglan aquí**.
- **Esquema y migraciones:** ninguna migración nueva, ninguna columna, ninguna "normalización" de datos. La deriva `memberships.business_profile_id` vs `establishment_id` es Fase B.
- El dataset compartido (productos/precios/pedidos): no lo toques ni lo "restaures".
- Ramas de otros agentes, `main`, y cualquier `git push --force`.
- El bundle `backend/public` y los artefactos generados por Flutter.
- Credenciales: ninguna en código, scripts, logs ni evidencia. Si necesitas un token, va por variable de entorno ya presente; si no está, escribe `BLOQUEADO-POR-CREDENCIAL` y sigue con el resto.

## 6. Definición de terminado (falsable)

1. `yaml.safe_load` de los dos workflows sin error y `grep -c '^<<<<<<<'` = 0 en `ci.yml` y `.gitignore`.
2. Run de CI visible en el PR con URL, y una mutación que lo puso rojo (evidencia pegada).
3. Compuerta anti-marcadores: RED con marcador insertado, GREEN limpio.
4. `/api/health`: 503 `DEGRADED` con la base caída / 200 `OK` con la base viva, `servingFabricatedData` cambiando de valor en ambos casos.
5. Cabecera `X-GlowApp-Degraded` presente solo en modo memoria.
6. `GET /api/providers`: 503 en fallo de consulta, 200 `count: 0` solo cuando la consulta corrió.
7. `auditFakeSuccess.js` + `docs/audit/fake-success-2026-09-24.json` entregados, con la corrida previa al fix como línea base.
8. `listRoutes.js` + `routes-2026-09-24.json` + `smokeSurfaces.js` con `npm run smoke:surfaces` ejecutable y determinista, sin residuo en la base (conteos pegados).
9. Smoke RED antes / GREEN después, con las salidas crudas.
10. `BASE` y `TU RAMA` de la suite completa, con nombres de suites fallidas.
11. PR con URL, padre de la rama y las 3 preguntas abiertas.
