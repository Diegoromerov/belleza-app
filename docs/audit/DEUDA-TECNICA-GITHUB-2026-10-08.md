# DEUDA TÉCNICA — `Diegoromerov/belleza-app`

**Fecha:** 2026-10-08
**Commit analizado:** `788a0f4492e22bd1d519fe121a0c0e549992b6a9` (main, = `origin/main`, working tree limpio)
**Método:** inspección directa del repo + API de GitHub + ejecución real (`flutter analyze`, `eslint`, `npm test`) en la máquina local.

**Estado de sincronización (2026-10-08 13:2x):** `git fetch origin --prune` ejecutado. `main` local = `origin/main` = `b520803cc` (0 ahead / 0 behind). Se podaron **231 refs locales de ramas ya borradas en GitHub**. GitHub se toma como punto de verdad. Nota: `main` avanzó 2 commits (`8c443f7b0`, `b520803cc`) por trabajo de Antigravity **durante** este análisis, ya pusheados.

> ⚠️ **LEER PRIMERO §0.c (ESTADO REAL DEL GATE, 2026-10-09): manda sobre §0, §0.b y §1.1.** Los
> números de las secciones §0/§1.1 se midieron **con `DATABASE_URL` exportado** y ya no reflejan
> el estado de la rama `fix/quality-debt-p0`. §0.c trae la medición canónica (sin `DATABASE_URL`)
> y marca qué puntos de este informe quedaron cerrados.
>
> Criterio de evidencia: cada hallazgo lleva archivo:línea o salida de comando reproducible.
> Lo que NO pude verificar con herramienta queda marcado como *(no verificado)*.

---

## 0. RESULTADO VERIFICADO HOY (evidencia dura)

| Comprobación | Resultado | Cómo se obtuvo |
|---|---|---|
| CI en `main` | **ROJO en todos los pushes** (3597 runs históricos, ninguno verde reciente) | `GET /repos/.../actions/runs` |
| Job Backend del último run (`37820606187`) | Falla en el paso 13 «Run Backend Integration & Unit Tests» | `GET /actions/runs/{id}/jobs` |
| Tests backend (último run) | **22 suites rojas / 62 tests rojos** de 127 suites / 927 tests | annotación del check-run |
| Job Frontend del último run | Verde (analyze con `--no-fatal-infos --no-fatal-warnings`) | idem |
| `flutter analyze` local | **467 issues** = 435 info + 32 warning + **0 error** | `flutter analyze` (tras arreglar `PUB_CACHE`) |
| `eslint` admin-dashboard | **118 problemas (108 errores, 10 warnings)** | `npx eslint . -f json` |
| `npm test` admin-dashboard | 47 pass / 0 fail (suite pequeña, mayormente *source-contract*) | `npm test` |
| `railway.yml` → build ai-worker | `context: ../ai-worker` **apunta a un directorio inexistente** (el real es `ai_worker/`) | `railway.yml:48` vs `ls` |

---

## 0.b CORRECCIONES APLICADAS Y VERIFICADAS (2026-10-08, local)

> Diego pidió corregir la deuda sobre el espejo local. Seis arreglos cerrados con test real (FIX 1-6).

### ✅ FIX 1 — Token blacklist: fail-closed por defecto (P0 seguridad)
- **Archivo:** `backend/src/middleware/auth.js`
- **Antes:** `if (redisClient && redisClient.isReady) { … }` → con Redis caído se **omitía** la comprobación de revocación incluso en producción (fail-open silencioso).
- **Ahora:** constante `FAIL_OPEN_ENVS = {'development','test'}`; cualquier otro valor (ausente, `staging`, typo) cierra con **503** y mensaje `…no disponible…`; en dev/test emite `console.warn('…Redis deshabilitado en dev/test…')` y continúa.
- **Evidencia (línea base roja → verde):**
  - Antes: `Tests: 6 failed, 6 total` en `tokenBlacklistFailClosed*.test.js` (reproduce el fallo de CI).
  - Después: `Tests: 6 passed, 6 total`, `Test Suites: 2 passed`.
- **Regresión:** cero. Los 8 suites que importan `authMiddleware` dan **el mismo set de 5 fallos con y sin el cambio** (`deleteBiometricDataHttpStatus`, `deleteBiometricDataRealDeletion`) — preexistentes, dependen de BD real. Verificado con `git stash` A/B.

### ✅ FIX 2 — Deriva de contrato OpenAPI (compuerta roja en `main`)
- **Causa raíz:** el commit `b520803cc` («implementar GET /api/admin/products», de Antigravity, 13:17) montó la ruta pero **no regeneró** el artefacto → `checkOpenApiSpec.js` en rojo (`1 operación montada SIN contrato`, exit 1). **`main` quedaba rojo en el paso 9 del CI.**
- **Fix:** `npm run openapi:generate` (remediación prescrita por la propia compuerta). Diff mínimo: +16/-2 líneas, sólo el stub de la operación nueva + contadores.
- **Evidencia:** gate → `✅ CONTRATO OPENAPI — compuerta en verde`, `260/260 operaciones (100%)`, `artefacto … en sincronía`, exit 0. `openapi.contract.test.js` → **8/8**. `critical-endpoints.contract.test.js` → **15/15**.
- **Nota de diseño:** los 4 `/admin/products` (GET incluido) quedan como **stubs** (`x-glowapp-documented: false`), igual que POST/PUT/DELETE ya existentes. Es la convención aceptada del proyecto (los contratos explícitos se reservan a auth/booking/payment/admin-dashboard/disputes). Si quieres contrato explícito también aquí, es un añadido en `criticalContract.js`, no un arreglo del gate.

### ✅ FIX 3 — 3 suites «fantasma» que jest recogía y no podía correr
- **Archivos:** `src/tests/adminAuditLog.test.js`, `src/tests/dbMemorySecurityGuard.test.js`, `tests/rls_usuarios_isolation.test.js`.
- **Causa raíz:** están escritas para el runner nativo `node:test` (`const test = require('node:test')`) pero se llamaban `*.test.js`, así que jest las coleccionaba, veía **0 tests** y las marcaba rojas con «Your test suite must contain at least one test». Nunca podían pasar bajo jest.
- **Fix:** `git mv … → *.nodetest.js`. `jest.config.js` sólo matchea `*.test.js`, así que quedan fuera del gate; el sufijo deja claro su runner. *(No se usó `testPathIgnorePatterns`: el CI pasa `--testPathIgnorePatterns` por CLI y **sobreescribe** el del config.)*
- **Se les da runner de verdad** (antes no lo tenía ninguno): script `test:node` en `backend/package.json` + paso **bloqueante** «Guardas node:test» en `.github/workflows/ci.yml`.
- **Evidencia:** gate 19 → **16** suites rojas (los 3 fantasmas aportaban 0 tests: el total de tests no cambia). `npm run test:node` → **21/21 verde**, exit 0.

### ✅ FIX 4 — Invariante de seguridad violada que el rojo fantasma ocultaba
- **Archivo:** `backend/src/middleware/auth.js`
- **Causa raíz:** `tests/rls_usuarios_isolation.nodetest.js` prohíbe leer `usuarios` por id directamente («fuga / 401 global»), y `auth.js` lo hacía en un **fallback** (`SELECT rol FROM usuarios WHERE id = $1`) cuando `app_usuario_identidad()` fallaba. Bajo RLS+FORCE esa consulta va sin contexto de inquilino → 0 filas → **401 global**.
- **Fix:** eliminado el fallback. Si `app_usuario_identidad()` falla, se falla **cerrado (503)**, coherente con el FIX 1.
- **Evidencia:** la suite pasa de `tests 20 / pass 19 / fail 1` a **21/21**. *(El primer intento seguía rojo porque mi propio comentario contenía el literal que la guarda busca — es textual, no distingue comentarios; reescrito.)*

### ✅ FIX 5 — RBAC: el OWNER no podía generar documentos (hueco en la matriz)
- **Archivo:** `backend/src/services/authorizationService.js`
- **Causa raíz:** `businessRoutes.js:75` exige `requirePermission(RESOURCES.BUSINESS_PROFILE, ACTIONS.CREATE)`, pero la matriz de `OWNER` tenía READ/UPDATE/DELETE_BUSINESS/TRANSFER_OWNERSHIP y **no CREATE**. Resultado: **403 para todos** al generar cualquier documento, incluido el dueño del negocio. Y como eso dejaba `createdDocId` en `null`, arrastraba download/sign/version/audit en cascada.
- **Fix:** una entrada — `${RESOURCES.BUSINESS_PROFILE}:${ACTIONS.CREATE}` en `OWNER`.
- **Evidencia:** `business.integration` → **PASS** (antes 1 fallo). Una línea de matriz, ~28 tests desbloqueados.

### ✅ FIX 6 — El emulador de BD mentía sobre los tipos (causa de los 403 restantes)
- **Archivo:** `backend/src/config/pgMemory.js`
- **Causa raíz:** el arnés de tests sustituye el pool por `pg-mem`. Su `SCHEMA_SQL` declaraba `business_documents.provider_id VARCHAR(36)` mientras `migrations/012_business_engine.sql:194` lo declara **`INTEGER`** — y la propia migración lo documenta en su línea 21 («`provider_id` = INTEGER, no VARCHAR(36)», porque `ownerController.js:185` filtra `= ANY($1::int[])`). El emulador nunca se actualizó.
- **Sonda que lo probó:** el INSERT contra el emulador devolvía `provider_id="101"` **tipo string** → `doc.provider_id !== providerId` (`"101" !== 101`) → 403.
- **Fix:** alineados los tipos con la migración real — `business_documents.provider_id INTEGER`, `business_documents.signed_by INTEGER`, `document_audit_logs.provider_id VARCHAR(64) DEFAULT 'system'`. Más una nota «REGLA QUE NO SE PUEDE ROMPER: se omiten FK y CHECK, pero **nunca los tipos**» junto a `SCHEMA_SQL`.
- **Evidencia:** `businessAdminDocs` 8 fallos → **1**; `businessHardening` 12 → **4**; `businessSystem` 2 → **1**. *(Ojo: `infra.observability.prometheus` marcó 0 en una pasada y 1 en la siguiente — es inestable, no lo cuento como arreglado.)*
- **⚠️ Regresión que introduje y corregí (por qué se mide cada paso):** alineé también `business_profiles.provider_id` a INTEGER y eso **rompió** `businessRAG.integration` (0→14) y `businessRatingDebugging` (0→2), porque sus fixtures insertan ids no numéricos. Ese cambio no era necesario para el fallo que perseguía → **revertido**; ambos vuelven a **PASS**. Queda como divergencia pendiente documentada.

### 🔴 BUG DE PRODUCCIÓN EXPUESTO POR EL FIX 6 — firmar un documento daría 500
- `signDocument` escribe el **nombre** del firmante en `signed_by` (`documentGeneratorService.js:239-244` → `updateDocumentSignature(docId,'SIGNED', signerName, hash)`), pero `migrations/012_business_engine.sql` declara `signed_by INTEGER REFERENCES usuarios(id)`.
- Al alinear el emulador, la sonda lo reprodujo: `SIGN THREW: invalid input syntax for integer: Rep Legal`.
- **En producción**: con esa columna `INTEGER`, firmar revienta. La spec del test (`signedBy === 'Peluquería Alpha Rep. Legal'`) y el propio fallback del código (`` `Prestador (${providerId})` ``) dicen que ahí va un **nombre**, no un id → la columna debería ser `VARCHAR(150)`.
- **Requiere decisión tuya:** nueva migración `ALTER TABLE business_documents ALTER COLUMN signed_by TYPE VARCHAR(150)` (recomendado) **o** cambiar el código para guardar el id.

### 🔎 CORRECCIÓN DE UN HALLAZGO MÍO — el guard de migraciones NO está roto
- Los números duplicados (002, 003, 004, 008, 011, 012, 026, 029, 030, 032, 033, 034, 065, 066, 067) **están en un baseline legacy explícito** que el guard verifica. `node tests/migrationsNoDuplicateNumbers.test.js` → **7/7 verde**, y falla si el baseline se extiende. No es una compuerta decorativa; es una excepción gobernada. Huecos reales: 022, 024, 038-043, 049-052, 077-078.

### ⏸️ ESTADO DEL GATE TRAS LOS FIXES
- **Reproducido en local con el runner real.** Docker arriba, `postgis/postgis:16-3.4` en 5432, mismos pasos 11-12 del CI (`prepareRlsDatabase.js` + `verifyTenantIsolation.js`) → **ambos verdes**. El único rojo del CI es el paso 13 (jest).
- **Progresión medida (misma máquina, mismo runner):** `19 suites / 53 tests rojos` (línea base) → **`15 suites / 36 tests rojos`** tras FIX 3-6. **−32 % de tests rojos, cero regresiones** (comparado suite-a-suite contra la línea base).
- **Las 15 suites que siguen rojas** son las que requieren decisiones de diseño, no arreglos mecánicos: `adminDisputasNoEntraPorEmail` (mock de la consulta vieja) y el resto de §1.1.c/§1.1.d.
- **Lo que NO he tocado:** `railway.yml` ai-worker (`context: ../ai-worker` → el real es `ai_worker/`) — es un fallo objetivo de ruta, pero arreglarlo **cambia el deploy**. Decisión tuya: corregir la ruta o borrar el servicio.

---

## 0.c ESTADO REAL DEL GATE — MEDIDO (2026-10-09)

> **Esta sección manda sobre §0, §0.b y §1.1.** Los números de §0 y §1.1 se midieron **con
> `DATABASE_URL` exportado**, y eso cambia el resultado: buena parte de aquellos rojos eran el
> arnés conectando a una base alcanzable en vez de usar su camino canónico.

**Configuración exacta de la medición** (sin esto, los números no son comparables):
worktree propio `C:/beauty-app-work`, rama `fix/quality-debt-p0`, tip **`4b1e933b4`**,
`NODE_ENV=test`, **`DATABASE_URL` SIN exportar** (arnés canónico), `JWT_SECRET` de test,
`DEEPSEEK_API_KEY`/`GEMINI_API_KEY` **fuera del shell** (los fija cada test),
**jest 29.7.0** del lock vía `npm test` / `./node_modules/.bin/jest` — **nunca `npx jest`**
(resuelve un 30.5.2 de caché y da "0 tests"), `node_modules` propio del worktree.

| Paso del CI | Antes (`main`) | Ahora | Rojos |
|---|---|---|---|
| Paso 1 (`ci.yml:171`) | 17 suites / 58 tests | **127 suites / 127 ✓** — 976 passed, 5 skipped | 0 |
| Paso 2 (`ci.yml:203`) | 15 suites / 31 tests | **24 suites ✓** — 160 passed, 1 skipped | 0 |
| Paso 3 (`ci.yml:108`) | 2 suites (0 tests, no cargan) | **2 suites / 23 tests ✓** | 0 |
| Guardas `node:test` | sin runner | **21 / 21 ✓** | 0 |
| **Total** | **34 suites / 89 tests rojos** | **0** | **0** |

`biometric-scan.contract.test.js` falla de forma intermitente **solo bajo la carga de la corrida
completa**: pasa 3/3 en aislamiento, con y sin los cambios de la rama. Familia
`inestables_conocidos`, no es rojo de la rama.

### Lo que cambió de sentido respecto a las secciones anteriores

| Sección | Decía | Realidad medida |
|---|---|---|
| §1.2 | «fail-closed especificado pero NO implementado» (fail-open) | **Cerrado** — FIX 1 lo implementa; verificado con las suites `tokenBlacklistFailClosed*` |
| §7 | «Token blacklist fail-open — **Abierto**» | **Cerrado**, mismo punto |
| §1.1.e | `degradedLockBehavior` «espera 503, recibe 500» | **Cerrado.** Eran **dos causas apiladas**: (a) el emulador `productos` no tenía `descripcion`/`imagen_url`/`tag_especialidad`/`tipo_visibilidad`, que **sí existen en las migraciones reales** → `ColumnNotFound` → 500; (b) el fixture del test pasaba `memoryFallbackAllowed: true` y exigía bloqueo, cuando la regla (`degradedLock.js:141-143`) no bloquea en ese estado. Se completó el emulador y se corrigió el fixture; **cero cambio de producción** |
| §0.b FIX 6 (nota final) | `business_profiles.provider_id` «divergencia pendiente documentada» (alinearlo rompía `businessRAG.integration` y `businessRatingDebugging`) | **Resuelto** (`c6860a702`): `provider_id INTEGER` y `tenant_id VARCHAR(64)` según la migración 012. La regresión que se documentó **ya no se reproduce** — verificado: `businessRAG.integration` + `businessRatingDebugging` **17/17 con y sin el cambio** (los fixtures se corrigieron después) |
| §1.1.f | «9 familias excluidas — TAMBIÉN rojas: 25 tests rojos» | **Cerrado**: esas familias son el paso 2, hoy 0 rojos |
| — | `geminiFallback.test.js` tenía el único `test.skip` del repo («bug scope `parsedUserId`») | **Cerrado** (`4b1e933b4`). El bug **ya no existe** (`parsedUserId` no está en `geminiService.js`); el skip ocultaba una garantía real — que con todos los proveedores caídos se persiste igualmente una respuesta segura. Restaurado y verde. **Quedan 0 `test.skip` en el repo** |

### Lo que de verdad estaba roto en producción (2 de 89)

De los **89 rojos cerrados, sólo 2 eran defectos reales de producción**; los otros 87 eran el
instrumento midiendo mal (Redis sin mockear, guards de entorno, mocks que respondían vacío a
todo, aserciones imposibles, un 500 satisfaciendo un `not.toBe(503)`, un fixture que se
contradecía):

1. **`biometricCryptoService.js:53-58` — fail-open en la clave biométrica** (`4decdf1e6`). Fuera
   de `NODE_ENV==='test'`, una clave de longitud inválida se **hasheaba y aceptaba en silencio**.
   Ahora falla cerrado en todos los entornos.
2. **`geminiService.js` — 105 líneas duplicadas a mano de las herramientas AURA** (`a4305d574`).
   La ruta Gemini declaraba 8 herramientas copiadas mientras la fuente (`AURA_TOOLS_DEFINITIONS`)
   tiene **11**, con **nombres de parámetros divergentes** (`user_id`/STRING en Gemini vs
   `userId`/number en la fuente). Ahora se derivan de la fuente única: +32/−108.

**Y un tercero de clase distinta, todavía abierto** (§0.b, sigue vigente): `business_documents.signed_by`
es `INTEGER` en la migración 012 pero el código escribe el **nombre** del firmante → firmar un
documento daría 500 en producción. Requiere una decisión tuya (nueva migración `VARCHAR(150)`
o cambiar el código).

### Lo que NO está hecho

- `backend/public/` sigue sirviendo el bundle Flutter desde git (§2.2) — decisión de arquitectura.
- `railway.yml` ai-worker (`context: ../ai-worker` → real `ai_worker/`) — sin tocar, decisión tuya.
- Higiene de repo (§2.1 672 `.md` raíz, §2.3 basura trackeada, §2.4 ramas solo-locales) — intacto.
- `admin-dashboard` sigue sin puerta de calidad en CI (§5.1).
- **Donde el 100 % NO aplica**: el gate está al 100 % de sus tres pasos, pero eso **no** es el
  100 % de la deuda auditada. Los 89 rojos eran el termómetro; de la deuda del informe siguen
  abiertos §2 (higiene), §3.1-3.5 (backend), §4 (frontend), §5 (panel) y §6 (config).

---

## 1. DEUDA P0 — BLOQUEA LA VERDAD DEL PIPELINE

### 1.1 La puerta de tests del backend está roja de forma permanente
- **Evidencia:** el job `Backend Tests & Lint` falla siempre en el paso 13. Annotación: `Test Suites: 22 failed, 105 passed, 127 total / Tests: 62 failed, 865 passed, 927 total`, con título «suites fallaron al cargar».
- **Reproducido en local (2026-10-08, PG 16.4 + PostGIS reales):** `Test Suites: 19 failed, 109 passed, 128 total · Tests: 53 failed, 5 skipped, 875 passed, 933 total` (exit 1). Pasos 11 (`prepareRlsDatabase`) y 12 (`verifyTenantIsolation`) del CI **sí pasan** en local; el único rojo es el 13.

#### 1.1.a Causa raíz nº1 — 3 suites escritas para `node:test` que jest recoge y no puede correr
Son las que el CI reporta como «suites fallaron al cargar». Llevan `const test = require('node:test')` pero se llaman `*.test.js`, así que `testMatch` de jest las colecciona, jest ve **0 tests** y las marca rojas con «must contain at least one test». **No pueden pasar nunca bajo jest.**

| Archivo | Nota |
|---|---|
| `src/tests/adminAuditLog.test.js` | Existe la versión correcta `adminAuditLog.test.mjs` (11 KB) que **pasa 12/12** con `node --test`; jest no la ve porque su `testMatch` sólo acepta `.test.js` |
| `src/tests/dbMemorySecurityGuard.test.js` | 5 casos; con `node --test` los 5 **pasan** |
| `tests/rls_usuarios_isolation.test.js` | 10 casos; ver 1.1.b |

#### 1.1.b 🔴 Hallazgo oculto por el rojo «de carga» — invariante de seguridad violada
Al correrla con su runner nativo, `tests/rls_usuarios_isolation.test.js` **falla de verdad**:
```
✖ auth.js resuelve la identidad con app_usuario_identidad()
  auth.js no debe leer usuarios por id directamente (fuga / 401 global).
  at tests/rls_usuarios_isolation.test.js:117
ℹ tests 16 · pass 15 · fail 1
```
- La invariante exige que `auth.js` **no** consulte `usuarios` por id directo.
- `backend/src/middleware/auth.js:62` lo hace: `SELECT rol FROM usuarios WHERE id = $1` como **fallback** cuando `app_usuario_identidad()` falla (`:58-60`).
- Bajo RLS+FORCE esa lectura directa sin contexto devuelve 0 filas → **401 global**. Es exactamente lo que la test llama «fuga / 401 global».
- **Lo grave no es el fallo, es que llevaba invisible**: el mensaje «must contain at least one test» tapaba la aserción real. El CI marcaba rojo el archivo por la razón equivocada.

#### 1.1.c CORREGIDO — los 403 de negocio NO eran deriva de fixtures: era el emulador de BD
> **Corrección de un hallazgo mío.** En la primera pasada atribuí los `200 → 403` de las suites `business.*` a
> «fixtures sin actualizar tras el refactor». **Era falso.** La causa real está en
> `backend/src/config/pgMemory.js`: el emulador declara `business_documents.provider_id VARCHAR(36)`
> mientras `migrations/012_business_engine.sql:194` lo declara `INTEGER`. El servicio compara de forma
> estricta (`documentGeneratorService.js:133`, `doc.provider_id !== providerId`); en el emulador el id
> llega como `"101"` (string) y el number `101` nunca coincide → **403 al dueño de su propio documento**.
> Y como eso dejaba `createdDocId` en `null`, arrastraba en cascada download/sign/version/audit.
> **En producción no existe**: la columna es `INTEGER` y node-pg devuelve number. Ver §0.b FIX 5.

| Suite | Esperado → Recibido | Causa real | Estado |
|---|---|---|---|
| `business.integration` | 200 → 403 | RBAC: falta `BUSINESS_PROFILE:CREATE` en `OWNER` | ✅ corregido |
| `businessAdminDocs.integration` | 200 → 403 (×4) | emulador: `provider_id` varchar | ✅ corregido |
| `businessHardening.integration` | 200 → 403 | idem | ⚠️ mejora (12→4) |
| `businessSystem.integration` | 200 → 403 | idem | ⚠️ mejora (2→1) |
| `adminDisputasNoEntraPorEmail` | 403 → **401** | mock de la consulta vieja a `usuarios`; el código usa `app_usuario_identidad()` | ⏳ pendiente |
| `e2e-saas-verification` | `'bp-salon-a'` → `undefined` | ⏳ pendiente |
| `tenant-isolation` | 404 → 200 | ⏳ pendiente |
| `membership-flow` | error zod cambió de forma (`VALIDATION_ERROR` + `details`) | ⏳ pendiente |

**Y el hallazgo mayor que esto destapó:** con `NODE_ENV=test` **el pool entero se sustituye por `pg-mem`**
(`pgMemory.js:33`). Los 128 suites del gate **nunca tocan el Postgres real** que el CI monta en los pasos
11-12; esos pasos sólo alimentan los scripts sueltos. Es decir: el arnés de pruebas valida contra un
**emulador con esquema propio** (22 tablas, sin FK ni CHECK), no contra la base de producción.


#### 1.1.d Causa raíz nº3 — tests que analizan el texto fuente, no el comportamiento
- `tests/deleteBiometricDataHttpStatus.test.js` y `tests/deleteBiometricDataRealDeletion.test.js` fallan con `require no soportado en el sandbox estático: '../config/db'`. Son tests que **leen el código con un sandbox propio** en vez de ejercitar el endpoint. El sandbox no soporta `require` del módulo real.
- Realidad doble: (a) el harness está roto; (b) su objeto de prueba (que la supresión borre de ≥7 tablas reales) **no se está verificando**. `deleteBiometricDataRealDeletion` B3 reportó `tablas canónicas borradas = []`.

#### 1.1.e Otros rojos con causa propia
| Suite | Causa |
|---|---|
| `ragService.test.js` | la test espera SQL `embedding <=>`; el servicio ahora hace **full-text** (`to_tsvector('spanish', …)`) — test obsoleto o cambio sin contrato |
| `infra.observability.prometheus` | espera `glowapp_db_available = 0`, recibe `1` |
| `degradedLockBehavior` | espera 503, recibe 500 |
| `jwtProductionGuard` | espera que `require('index')` lance `FATAL SECURITY ERROR`; no lanza |
| `youcam.client.integration` / `gemini.client.integration` | «Network Error» — el retry/fallback no captura |
| `src/tests/dbMemorySecurityGuard` | (nº1.a) pasa con su runner nativo |

- **Ya corregido (ver §0.b FIX 1):** el par `tokenBlacklistFailClosed*.test.js` fallaba porque pedía un string de log que el código ya no emitía; se implementó el fail-closed y ahora pasa 6/6.
- **Consecuencia de fondo:** la puerta es decorativa. Como el paso 13 falla, el paso 15 («Suites excluidas del gate») queda `skipped`, de modo que el estado real de las 9 familias excluidas **nunca se publica**. El comentario del propio CI (`ci.yml:160-162`) lo admite: «En el runner remoto sigue NO MEDIDO».

#### 1.1.f Las 9 familias excluidas — medidas en local: TAMBIÉN rojas
Corridas con el mismo patrón del paso 15 (`geminiService|geminiFallback|auraToolExecutor|contract|biometric|resilience|contextCompressor|fase5|api.cors`):
```
Test Suites: 11 failed, 13 passed, 24 total
Tests:       25 failed, 1 skipped, 136 passed, 162 total   (exit 1)
```
| Suite roja | Nota |
|---|---|
| `src/tests/resilience.test.js` | **122 s** — la más lenta del repo |
| `src/tests/geminiService.test.js` | 31 s |
| `src/tests/fase5_e2e_integration.test.js` | 30 s |
| `src/tests/orchestrator.resilience.test.js` | — |
| `src/tests/geminiFallback.test.js` | — |
| `src/tests/auraToolExecutor.test.js` | — |
| `src/services/biometricCryptoService.test.js` | — |
| `src/tests/biometric.integration.test.js` | — |
| `src/tests/biometricConsentGuard.test.js` | — |
| `tests/deleteBiometricDataHttpStatus.test.js` | (también en el gate: la mayúscula de `deleteBiometricData` esquiva el patrón en minúsculas) |
| `tests/deleteBiometricDataRealDeletion.test.js` | idem |

**Balance real del backend:** ~30 suites rojas y ~78 tests rojos. El CI sólo hace visible la mitad, y de esa mitad el 40 % son rojos fantasma (causa 1.1.a).


### 1.2 El control de seguridad de «fail-closed» está especificado pero NO implementado
- **Evidencia:** `backend/src/tests/tokenBlacklistFailClosed.test.js:26-41` exige **HTTP 503 en producción cuando Redis está caído**.
  Pero `backend/src/middleware/auth.js:19-31`:
  ```js
  if (redisClient && redisClient.isReady) {   // ← si Redis está caído, NO entra
      ... check blacklist ...
  }
  ```
  Con Redis caído, `isReady === false` → **se salta la blacklist por completo incluso en producción**: los tokens revocados siguen valiendo (fail-OPEN silencioso).
- **Consecuencia:** control de seguridad mal implementado + test rojo que documenta el hueco. Alto riesgo en un flujo con datos biométricos.

### 1.3 El servicio AI Worker no puede construirse en el deploy declarado
- **Evidencia:** `railway.yml:48` → `context: ../ai-worker`, pero el directorio real es `ai_worker/` (`ls -d ai-worker` → *No such file*).
- Además viene con `MOCK_MODE: "true"` (`railway.yml`), `python:3.10-slim` EOL y sin usuario no-root (`ai_worker/Dockerfile:1`), y deps congeladas muy antiguas (`ai_worker/requirements.txt`: fastapi 0.104.1, pydantic 2.5.0, pillow 10.1.0, numpy 1.26.2).
- **Consecuencia:** el «scanner de belleza» que el backend llama (`backend/src/routes/v1/beautyScanRoutes.js:13` → `http://ai-worker:8000`) no tiene imagen construible en Railway. Feature fantasma.

---

## 2. DEUDA DE HIGIENE DE REPOSITORIO (la más grande en volumen)

### 2.1 672 archivos `.md` en la raíz, versionados
- **Evidencia:** `git ls-files "*.md" | grep -v "/" | wc -l` → **672**. La raíz tiene 721 archivos en total.
- Contiene auditorías (`AUDITORIA_*.md`), actas (`GIA-*`, `F7.00*`, `D001.*`, `D002.*`, `D004.*`), informes `.report`, gate files (`*-GATE.md`), etc. Todo en la raíz, mezclado con código.
- **Consecuencia:** la raíz es inoperable; cualquier `ls` necesita filtro; el ruido tapa el código real.

### 2.2 125 MB de artefactos de build versionados
- **Evidencia:** `backend/public/` → **205 archivos trackeados, 125 MB**, incluyendo `main.dart.js` (5.6 MB), `canvaskit.wasm` (7 MB ×3 variantes), y **mp4 de onboarding** (step_01..08 + intro, ~4 MB cada uno).
- El `.gitignore` lo declara «versionado intencionalmente» — es una decisión, pero es deuda: el repo `.git` pesa **1.3 GB**.
- También trackeado: `frontend/android/build/reports/problems/problems-report.html` (artefacto de build).

### 2.3 Basura de sesión versionada en la raíz
- `git ls-files` incluye: `0)ls`, `DEPLOY_TRIGGER.txt`, `frame.png`, `frame_cropped.png`, `test_face.jpg`, `nul` (artefacto de dispositivo Windows), `*.report`, `schema_run.log`, `schema_run2.log`.

### 2.4 Ramas: 47 en GitHub, 231 refs locales obsoletas
- **Evidencia (corregida 2026-10-08 tras `fetch --prune`):** el repo en GitHub tiene **47 ramas** (`GET /branches` → 47). El `git branch -r` **local** mostraba 279 porque arrastraba **231 refs de ramas ya borradas arriba**. Tras `git fetch origin --prune` quedan **48 refs** (`origin/HEAD` + 47), coincidiendo con GitHub.
  - → La cifra de «279 ramas / 191 `agent/*`» de la primera pasada era **metadata local obsoleta**, no el estado de GitHub. El estado real: **47 ramas**, mayoritariamente `agent/t_fix_*`.
- **Solo local (no existen en GitHub):** 20 ramas, casi todas restos de agentes (`agent/t_aud_*`, `codex/*`, `archive/fase1-mock`, `temp_merge_e3`, `prueba/*`). Contenido no publicado: **1-2 commits cada una** como máximo (auditorías y parches muertos).
- **Trabajo realmente no pusheado en todo el repo local:** los commits de las ramas con aspecto «adelantado» (`feat/glowshop-niveles-a0` +172, `feature/provider-floating-nav` +6) **ya están todos en alguna ref de GitHub** (`git rev-list --count <rama> --not --remotes=origin` → 0). No hay trabajo perdido.
- **13 worktrees** vivos (`git worktree list`) repartidos por `C:/`, `~/.codex/`, `~/.gemini/antigravity/` — restos de orquestación multi‑agente.
- **Consecuencia:** el repo de GitHub está razonablemente limpio; el ruido de ramas es **local**. El riesgo real es no saber qué rama es verdad sin mirar el remote.

### 2.5 62 «órdenes» de proceso dentro de `docs/`
- **Evidencia:** `docs/agents/ordenes/` → 62 archivos `PROMPT-ANTIGRAVITY-*` (rondas 2..5 de los mismos tickets). `docs/` acumula 558 archivos / 419 `.md`.
- **Consecuencia:** el proceso de trabajo se versiona como contenido, no como historial.

### 2.6 Tres sistemas de migración/esquema en paralelo
- **Evidencia:**
  - SQL crudo: `backend/migrations/*.sql` (83 archivos) con runner propio (`runMigrations.js`, `prepareRlsDatabase.js`).
  - Sequelize: `backend/src/models/` (23 modelos) + `backend/migrations/2026*.js`.
  - Knex: `backend/knexfile.js` + dependencia `knex ^3.3.0`.
- **Riesgo añadido:** `backend/package.json` → `"migrate": "node -e \"require('./src/models').sequelize.sync({force:true});\""` — **`force:true` DROPEA todas las tablas**. Un `npm run migrate` mal invocado borra la base.
- Numeración con duplicados y huecos: dos `066_*`, dos `067_*`, sin `077`/`078`.
- **Consecuencia:** tres fuentes de verdad del esquema, y una de ellas destructiva.

### 2.7 Scripts de un solo uso en `backend/` raíz
- **Evidencia (untracked por `.gitignore`, presente en disco):** 64 `.js` en la raíz de `backend/`, incluidos 14 `test_*.js`, 27 `run_*.js`, 20 `check/validate/verify/investigate/inspect*`, y **9 versiones** de `fix_retention_service.py` (v1…v9).
- **Consecuencia:** el patrón «arreglar copiando el script con un número» sigue vivo; el `.gitignore` lo tapa en git pero no la causa raíz.

---

## 3. DEUDA DE CÓDIGO — BACKEND

### 3.1 `index.js` es un god-file de 1818 líneas con 59 `app.use`
- **Evidencia:** `backend/index.js` 1818 líneas / 71 KB; 59 montajes `app.use(`; definidos ahí mismo: CORS, Helmet/CSP, rate limit, Multer, Swagger, status-monitor, SSE, health, middleware admin, routers.
- **Deuda relacionada:** existe un **segundo entrypoint** `backend/src/startup/app.js` que nadie usa en producción (`Dockerfile` → `node index.js`), con CORS, rate limiter y error handler **distintos**. Duplicación divergente.

### 3.2 Logging sin estructura: 301 `console.log` en código de producción
- **Evidencia:** `grep -rc "console\.log" backend/src backend/index.js` → **301**; `console.warn|error` → **533**. Pese a que `winston` está en `package.json`, no se usa de forma consistente.
- **Consecuencia:** sin correlación ni niveles; `traceId` existe pero no atraviesa los logs.

### 3.3 Rate limiting: tiers y Redis quedaron en stubs no-op
- **Evidencia:** `backend/src/middleware/rateLimiter.js`:
  - `:89-92` `checkRateLimit` **siempre** devuelve `{ allowed: true }`.
  - `:94` `resetRateLimit = async () => {}` — función vacía.
  - `TIER_LIMITS` (`:79-83`) definido pero no aplicado a ninguna ruta.
- 6 instancias de `express-rate-limit` con configuración duplicada, y varias con `validate: { xForwardedForHeader: false, default: false }` (`:39, :62, :72`) — desactiva validaciones de IP tras proxy.
- **Consecuencia:** el límite «por tier (free/premium/anonymous)» prometido no existe; sólo queda el límite por IP global.

### 3.4 `beautyScanWorker.js` / workers referenciados inexistentes *(documentado, re-verificar)*
- La auditoría previa (`AUDITORIA_BACKEND_WORKERS.md:50-69`) afirma que `index.js` intenta cargar `nailTryonWorker`, `pqrsfReviewWorker`, `vtoAttributionWorker` y el directorio `src/workers/` no existe → fallan en un try/catch silencioso.
- **Estado hoy:** `ls backend/src/workers` sigue sin existir. El `GLOWAPP_LEGACY_REGISTRY.md:47-50` los marca «legacy» sin plan de retiro.
- **Consecuencia:** deuda registrada que nadie cerró ni justificó.

### 3.5 Duplicación de esquema de BD ⇒ *schema drift*
- Documentado en `AUDITORIA_RENDIMIENTO_BD.md:176-190`: `backend/schema.sql` no reflejaba producción (`usuarios` enum vs varchar, `services` vs `servicios`, `perfiles_prestador` ausente en el dump, `calc_booking_split` con dos fórmulas distintas).
- **Nota:** parte de esto se atacó después (migración `068_force_rls_strict_isolation.sql` + `src/config/tenantRouting.js` + `src/middleware/tenantContext.js` sí fijan `app.tenant_id` de forma transaccional). **Ese ítem concreto está en gran medida resuelto**; el drift de `schema.sql` vs `backup` conviene re-verificarlo contra la BD real (no verificado).

---

## 4. DEUDA DE FRONTEND (Flutter)

### 4.1 467 issues de analizador (0 errores)
- **Evidencia:** `flutter analyze` → 467 (435 info, 32 warning). Top archivos:
  | issues | archivo |
  |---|---|
  | 113 | `lib/main.dart` |
  | 73 | `lib/core/theme/app_theme.dart` |
  | 28 | `lib/shared/onboarding_helper.dart` |
  | 15 | `lib/screens/booking_screen.dart` |
- Reglas dominantes: `deprecated_member_use` (87 en el primer conteo) y `prefer_const_constructors`/`unused_*`.
- **Nota metodológica:** un primer conteo dio 666 por `PUB_CACHE=D:\Pub\Cache` inexistente (rompía la resolución de paquetes). Con caché correcto baja a 467. **No son 666.**
- El propio `docs/governance/implementation/G1_E_QualityDebt_Group1_Result.md:57` reconoce «684 issues … deuda preexistente».

### 4.2 God-screens
- `frontend/lib/screens/provider_dashboard_screen.dart` **4732 líneas**; `lib/main.dart` 3192; `provider_detail_screen.dart` 2388; `onboarding_screen.dart` 2024; `wallet_screen.dart` 1860; `booking_screen.dart` 1591.
- Sin state management (usan `setState`), ya señalado en `AUDITORIA_PREPRODUCCION_MASTER.md:139`.

### 4.3 Sistemas de tema/design tokens duplicados
- Registrado en `GLOWAPP_LEGACY_REGISTRY.md:16-25`: `core/tokens.dart` (canónico) + `glow_store_tokens.dart` + `belleza_luxe_theme.dart` + `mens_theme.dart` + `AppTheme` legacy con getters de compatibilidad. Regla declarada: «LEGACY NO PUEDE CONVERTIRSE EN NUEVA AUTORIDAD».

### 4.4 `print()` en producción (28 casos)
- `frontend/lib/main.dart:79` y siguientes; sin logger remoto (sin Sentry) pese a existir archivos `crash_reporting_*` en `test/`.

---

## 5. DEUDA ADMIN-DASHBOARD (área más activa, sin ninguna puerta de calidad)

### 5.1 108 errores de lint fuera de CI
- **Evidencia:** `npx eslint .` → **108 errores, 10 warnings**. Reglas: `no-unused-vars` 62, `no-explicit-any` 40, `react-hooks/exhaustive-deps` 5, `jsx-a11y/alt-text` 3.
- Peor archivo: `src/app/(dashboard)/admin/academia/[id]/page.tsx` → **42 issues** (1484 líneas en un solo componente).
- **El CI no lintea ni testea `admin-dashboard/`**: `ci.yml` sólo tiene `backend-ci` y `frontend-ci` (Flutter).
- **Consecuencia:** el panel admin, que es lo que más se toca, no tiene red de seguridad automática.

### 5.2 40 `any` explícitos
- `src/` usa `: any` en 40 sitios (33 medidos solo en `src/app`), anulando el `strict` de TS justo en el BFF de datos.

---

## 6. DEUDA DE CONFIGURACIÓN / DEPS

| Hallazgo | Evidencia |
|---|---|
| `package.json` raíz declara `express ^5.2.1` mientras backend usa `^4.18.2` | `package.json` (raíz) vs `backend/package.json` |
| `main` de la raíz apunta a `run_seed.js`, que **no existe** | `ls run_seed.js` → *No such file* |
| 3 servicios Redis/Postgres declarados en `railway.yml` pero `docker-compose.yml` no incluye ai-worker | `backend/docker-compose.yml` |
| `.dockerignore` backend excluye `tests`, `*.md`, `docs` — bien — pero `Dockerfile` copia `COPY . .` sin multi-stage de assets | `backend/Dockerfile` |
| Falta `statement_timeout`/monitor en los pools | documentado `AUDITORIA_RENDIMIENTO_BD.md:26-28`; re-verificar |

---

## 7. DEUDAS PREVIAMENTE DOCUMENTADAS — ESTADO REAL HOY

| Deuda documentada | Estado verificado hoy |
|---|---|
| RLS multi-tenant inefectivo (`app.tenant_id` nunca setea) | **Resuelto en gran medida**: migración `068_force_rls_strict_isolation.sql` + `src/config/tenantRouting.js` + `middleware/tenantContext.js` fijan el contexto de forma transaccional (`is_local`). |
| Rate limiting de `/api/auth/*` deshabilitado | **Resuelto**: `routes/authRoutes.js:3,8-14` aplica `authLimiter`/`otpLimiter`. |
| `beauty-scan` proxy ausente en prod | **Parcial**: existe `src/routes/v1/beautyScanRoutes.js`, pero depende del ai-worker que no compila en Railway (§1.3). |
| Workers `nailTryon`/`pqrsf`/`vtoAttribution` inexistentes | **Abierto** (§3.4). |
| Graceful shutdown ausente | *(no verificado en este pase)* |
| Token blacklist fail-open | **Abierto y peor documentado que implementado** (§1.2). |
| `schema.sql` ≠ producción | **A re-verificar contra BD real** (no verificado). |

---

## 8. PRIORIZACIÓN SUGERIDA

**P0 — devolver verdad al pipeline (1-2 días)**
1. Poner verde el gate de tests o **reducir el conjunto que corre en verde** (marcar los 22 suites rojos con `testPathIgnorePatterns` explícito + ticket), de modo que el paso 15 deje de quedar `skipped` (§1.1).
2. Implementar de verdad el fail-closed de la blacklist (§1.2) o degradar el test a `it.skip` con ticket — decidir explícitamente.
3. Arreglar `context: ../ai-worker` → `ai_worker` o **borrar el servicio ai-worker** de `railway.yml` si no se usa (§1.3).

**P1 — higiene de repo (2-3 días)**
4. Mover los 672 `.md` de la raíz a `docs/archive/` (§2.1) y correr un guard de CI que limite `.md` en raíz.
5. Sacar `backend/public/` (125 MB) del git y servir el web desde el CDN/artefacto de build (§2.2).
6. Purgar basura trackeada (`0)ls`, `nul`, `*.report`, `test_face.jpg`, `frame*.png`) (§2.3).
7. Borrar las 20 ramas **solo-local** muertas (quedan en GitHub las 47 reales) (§2.4).
8. Unificar migraciones a **un** sistema y eliminar el script `force:true` (§2.6).

**P2 — calidad de código**
9. Añadir `admin-dashboard` al CI con `eslint` + `npm test` (§5.1).
10. `flutter analyze` como gate con umbral (falla si sube el contador) (§4.1).
11. Partir `index.js` (1818 líneas) y borrar `startup/app.js` o convertirlo en el único entrypoint (§3.1).
12. Reemplazar los stubs de `rateLimiter.js` (§3.3).

---

## 9. LO QUE NO PUDE VERIFICAR

- Log completo de la suite roja: `GET .../actions/jobs/{id}/logs` → **HTTP 403** (GitHub exige auth para logs, incluso en repo público). El detalle de las 22 suites viene sólo de la **annotación** del check-run.
- Estado real de la BD en Railway (RLS efectivo, drift de `schema.sql`, índices) — requiere conexión a la instancia.
- Contenido del log de los pasos frontend en el runner (no accesible).
