# Arquitectura real — Belleza App / GlowApp

**Medición:** 2026-09-24 · **Base:** worktree limpio de `main` @ `f5a1b4fc` (rama `docs/sistema-agentes`)
**Método:** lectura de código y de git. Todo número de este documento tiene el comando que lo produce.
**Regla de evidencia:** cada afirmación lleva `archivo:línea`. Lo que no se pudo verificar dice **NO VERIFICADO** — no se rellena con plausibilidad.

---

## 0. Cifras medidas (con el comando)

| Pieza | Medido | Comando |
|---|---|---|
| Archivos de ruta | **40** entradas en `backend/src/routes` = 39 `.js` + el subdirectorio `v1/` (3 rutas más) | `ls backend/src/routes \| wc -l`; `ls backend/src/routes/*.js \| wc -l` |
| Controladores | **29** `.js` | `ls backend/src/controllers/*.js \| wc -l` |
| Servicios | **51** entradas en `backend/src/services` = 48 `.js` + 3 subdirectorios (`agents/`, `biometric/`, `vto/`) | `ls backend/src/services \| wc -l`; `ls backend/src/services/*.js \| wc -l` |
| Modelos Sequelize | **23** `.js` | `ls backend/src/models/*.js \| wc -l` |
| Migraciones | **87** entradas = 78 `.sql` + 7 `.js` + los subdirectorios `manual/` y `rollback/` | `ls backend/migrations \| wc -l`; `ls backend/migrations/*.sql \| wc -l` |
| Suites de test | **62** archivos (61 `*.test.js` + `contract/biometric-scan.contract.test.js`) | `find backend/src/tests -type f \| wc -l` |
| Scripts de backend | **86** | `ls backend/scripts \| wc -l` |
| Frontend Flutter | **159** `.dart` en `lib/`; `lib/screens` 71 archivos (15 sueltos + 12 subdirectorios); `lib/widgets` 15 (9 sueltos + 4 subdirectorios); 58 archivos `*_screen.dart` | `find frontend/lib -name '*.dart' \| wc -l` |

> Dos cifras del enunciado **no coinciden** con la medición y se corrigen aquí: `backend/scripts` tiene **86** archivos (no 85), y las pantallas/widgets Flutter son **71/15** archivos bajo `lib/screens`/`lib/widgets` (no 25/13; el conteo 25/13 sólo cuadra si se miran los 15 + 9 archivos sueltos de primer nivel, y aun así no da 25/13).

---

## 1. Cómo se arranca y qué sirve cada pieza

### 1.1 Entry, puerto y ciclo de arranque

| Hecho | Evidencia |
|---|---|
| El entry real es `backend/index.js` | `backend/package.json:5` (`"main": "index.js"`), `backend/package.json:8` (`"start": "node index.js"`), `backend/Dockerfile:21` y `backend/Dockerfile.prod:19` (`CMD ["node", "index.js"]`) |
| Puerto por defecto **8080** | `backend/index.js:72` (`process.env.PORT \|\| 8080`); `backend/Dockerfile:20` (`EXPOSE 8080`); `docker-compose.prod.yml:8-9` publica `8080:8080` |
| En `NODE_ENV=test` **no** se levanta el servidor HTTP | `backend/index.js:1773` |
| La inicialización es asíncrona y **no bloquea** el `listen` | `backend/index.js:1774` abre el servidor y dentro del callback encadena: auto-ingesta del corpus (`:1782`), `testConnection()` (`:1788`), `initDatabase()` (`:1789`), `inicializarJobs()` (`:1791`), `initWebSocketServer(server)` (`:1794`). En `:1792` dice literalmente `// (WORKERS DESHABILITADOS)` |
| Timeouts alineados con el proxy reverso | `backend/index.js:1798-1800` (keepAlive 65 s, headers 70 s, request 240 s) |
| `/api/health` | `backend/index.js:420-430` |
| `/status` (monitor) y `/api-docs` (Swagger) | `backend/index.js:97-105` y `:94-95` |

### 1.2 Las cuatro piezas desplegables

| Pieza | Rol | Dónde |
|---|---|---|
| Backend Node/Express | API + sirve estáticos + WebSocket + jobs de dinero en proceso | `backend/index.js`; montaje de rutas en `:380-416`, `:524-528`, `:985` |
| Frontend Flutter Web | SPA | `frontend/` (`pubspec.yaml`, `lib/`) |
| Admin dashboard | Next.js 15 (React 19, Tailwind 4, Recharts) en puerto **3001** | `admin-dashboard/package.json:6-8`, `:11-17` |
| Worker de IA | **FastAPI** en `ai_worker/` | `ai_worker/main.py`, `ai_worker/Dockerfile` |
| Postgres + Redis | Datos y caché/blacklist de tokens | `docker-compose.prod.yml:27-40`; `backend/src/config/redis.js` referenciado en `backend/index.js:1837` |

### 1.3 El bundle Flutter **está commiteado** dentro del backend

| Hecho | Evidencia |
|---|---|
| `backend/public/` es un build Flutter Web completo (81 MB) | `ls backend/public` → `main.dart.js`, `flutter_bootstrap.js`, `canvaskit/`, `assets/`, `index.html` |
| Está **rastreado por git**: 192 archivos | `git ls-files backend/public \| wc -l` → 192 |
| El backend lo sirve como raíz estática | `backend/index.js:351` (`app.use(express.static(path.join(__dirname, 'public')))`) |
| Y como fallback SPA para todo lo que no sea `/api`, `/uploads` ni `/admin` | `backend/index.js:354-356` (`res.sendFile(path.join(__dirname, 'public/index.html'))`) |
| El contexto de build del backend incluye `public/` en la imagen | `backend/Dockerfile:15` (`COPY --chown=node:node . .`); `backend/.dockerignore` sólo excluye `node_modules`, `npm-debug.log`, `.git`, `.gitignore` |

**Consecuencia directa: ningún fix de frontend llega a producción sin un rebuild manual + commit del bundle.**

| Por qué | Evidencia |
|---|---|
| El CI **no compila** Flutter: sólo `flutter analyze` | `.github/workflows/ci.yml:106-127` (`frontend-ci` termina en `flutter analyze --no-fatal-infos --no-fatal-warnings`, línea `:127`) |
| El CI **no copia** nada a `backend/public` | `.github/workflows/ci.yml` completo; `grep -rln "public" --include=*.yml --include=*.sh --include=*.ps1 .` sólo encuentra `backend/docker-compose.yml` |
| El script de build local tampoco copia: compila y sirve el directorio de build directamente | `scripts/build_and_serve_glowapp.ps1:202` (`flutter build web --release`), `:231-244` valida `main.dart.js` en `$BuildDir`, `:270` hace `Set-Location $BuildDir` y sirve desde ahí |
| El `.gitignore` **sí** ignora `backend/public/` — pero los 192 archivos ya estaban rastreados | `.gitignore:71` (`backend/public/`) vs. `git check-ignore -v backend/public/index.html` → **exit 1** (no ignorado, está rastreado) |
| Un archivo **nuevo** bajo `backend/public/` sí se ignora | `git check-ignore -v backend/public/NUEVO_inexistente.js` → `.gitignore:71:backend/public/` (exit 0) |

Es decir: un rebuild que **modifique** artefactos ya rastreados (`main.dart.js`, `index.html`, `assets/…` existentes) se commitea normalmente, pero cualquier artefacto **nuevo** (p. ej. un chunk con hash distinto, un asset añadido) **no** se añade con `git add .` y hay que forzarlo. Y en ningún caso el pipeline produce ese commit: es una acción humana en cada release.

**Detalle importante — hay DOS raíces estáticas para el frontend, no una:**

| Ruta | Evidencia | ¿Existe en el checkout? |
|---|---|---|
| `backend/public` (bundle commiteado) | `backend/index.js:351` y `:354-356` | sí |
| `../frontend/build/web` (build local) | `backend/index.js:205-214` (se resuelve **una vez** al arrancar: `hasWebBuild`) y `:1762-1768` (segundo fallback SPA) | **no** (`ls frontend/build/web` → no existe) |

El propio código lo documenta en `backend/index.js:205-208`: en el contenedor desplegado esa ruta no existe porque el contexto de build es `./backend` y el web lo sirve nginx. Eso confirma que **la pieza que realmente se sirve en producción desde el backend es `backend/public`**, y que el fallback de `:1762-1768` está muerto en el contenedor.

### 1.4 Notas de despliegue que afectan al arranque

| Hecho | Evidencia |
|---|---|
| El frontend tiene **dos** Dockerfiles, con comportamiento distinto | `frontend/Dockerfile` (3 etapas, `nginxinc/nginx-unprivileged`, puerto dinámico `${PORT:-8080}`) vs. `frontend/Dockerfile.prod` (nginx clásico, `:80`) |
| `frontend/Dockerfile` consume un cliente OAuth **embebido en el repo** | `frontend/Dockerfile:4` (`ARG GOOGLE_WEB_CLIENT_ID=374223351186-…`) usado en `:10` con `--dart-define` |
| `docker-compose.prod.yml` no declara ningún servicio de IA | `docker-compose.prod.yml:1-45`: sólo `backend`, `frontend`, `postgres`, `redis` |
| `railway.yml` sí declara `ai-worker`, pero apuntando a un directorio que no existe | `railway.yml:35-38` (`context: ../ai-worker`, con guion) mientras el directorio real es `ai_worker/` (guion bajo) |
| `backend/docker-compose.yml` (dev) tampoco lo declara | `backend/docker-compose.yml:1-49` |

---

## 2. Mapa de componentes con rutas reales

### 2.1 Montaje de rutas (orden real en `backend/index.js`)

| Prefijo | Router | Línea |
|---|---|---|
| `/api` | `paymentRoutes`, `bookingRoutes`, `serviceRoutes`, `chatRoutes`, `productRoutes`, `providerRoutes`, `ticketRoutes`, `disputeRoutes` | `:380-387` |
| `/api/salon` | `salonRoutes` (**montado dos veces**: `:388` y `:525`) | `:388`, `:525` |
| `/api/consent` | `biometricConsentRoutes` y `consentRoutes` (dos routers en el mismo prefijo) | `:389`, `:391` |
| `/api/biometric` | `biometricRoutes` | `:392` |
| `/api/glow-cycle` | `glowCycleRoutes` | `:393` |
| `/api/v1/beauty`, `/api/v1/beauty-scan`, `/api/v1/workforce` | `routes/v1/*` | `:394-396` |
| `/api/vto`, `/api/color` | `vtoRoutes`, `colorRoutes` | `:397-398` |
| `/api/academy`, `/api/admin/academy` | `academyRoutes`, `academyAdminRoutes` | `:399-400` |
| `/api/admin` | `adminPreciosRoutes` (`:401`) **y** `adminRoutes` (`:985`) — dos routers en el mismo prefijo | `:401`, `:985` |
| `/api/glow-pro` | `glowProRoutes` + `eventRoutes` + `eventRegistrationRoutes` | `:402-404` |
| `/api/analytics`, `/api/metrics`, `/api/portfolio`, `/api/community`, `/api/mentorship`, `/api/xp-logs` | — | `:405-410` |
| `/api/v1/business`, `/api/v1/memberships` | — | `:415-416` |
| `/api/auth`, `/api/users`, `/api/designs`, `/api/nia-beauty` | — | `:524-528` |
| 404 JSON explícito para `/api/*` | `app.use('/api/*', …)` | `:1346-1348` |

### 2.2 Rutas y controladores por flujo

| Flujo | Rutas (archivo:línea) | Controlador / servicio |
|---|---|---|
| **Auth** | `backend/src/routes/authRoutes.js:9-23` (`/register`, `/login`, `/logout`, `/forgot-password`, `/reset-password`, `/oauth`, `/google`, `/select-role`, `/context/switch`, `/onboarding`, `/biometrics/consent`, `/fcm-token`, `/referral-info`, `/delete-account`, `/change-password`) | `backend/src/controllers/authController.js`, `oauthController.js`; middleware `backend/src/middleware/auth.js:8` |
| **Providers** | `providerRoutes.js:8-10` (`/providers`, `/providers/:id`, `/providers/:id/slots`) y `:15,40` (horario) | `providerController.js` |
| **Bookings** | `bookingRoutes.js:10` (`POST /bookings`), `:13` (`/bookings/provider`, con `pilaCheck`), `:16`, `:19`, `:22`, `:25` (pago), `:28` (**webhook**), `:31` (reseña), `:34` (`/start`, con `pilaCheck`) | `bookingController.js:42,237,292,342,397,438,737,805` |
| **Pagos / money-in** | `paymentRoutes.js:59` (`checkin`), `:104` (`complete`), `:180` (`confirm-otp`) | mismo router; `requirePrestador` en `:39` |
| **Wallet** | `paymentRoutes.js:401` (`GET /wallet`), `:507` (`/wallet/transactions`), `:545` y `:585/686/687` (cuenta bancaria), `:846` (`/wallet/model`) | tablas `provider_wallet`, `wallet_transactions` |
| **Retiros** | `paymentRoutes.js:691` (`POST /wallet/withdraw`) → `:818` `wompiService.crearPayout(...)` | `backend/src/services/wompiService.js:81` |
| **Jobs de dinero** | no son rutas: `setInterval` en proceso | `backend/src/jobs/paymentJobs.js:40` (maduración de saldos), `:98` (retiros automáticos), `:212` (conciliación diaria), `inicializarJobs()` en `:264`, arrancados en `backend/index.js:1791` |
| **Webhook Wompi** | `bookingRoutes.js:28` (`POST /api/payments/wompi-webhook`), limitado en `backend/index.js:375` | `bookingController.js:733` → `procesarWebhookWompi` (`:590`) → verificación de firma `verifyWompiSignature` (`:9`, invocada en `:592`) |
| **Aura / RAG (chat)** | `chatRoutes.js:11-14` | `chatController.js:173` → `processAssistantMessage` (`geminiService.js`, export en `:1072`) → `ragService.js` (export en `:401`) + `embeddingService.js` |
| **Biometría** | `biometricRoutes.js:20` (`POST /analyze` con `biometricConsentGuard` + idempotencia), `:99`, `:128` | `backend/src/services/biometric/orchestrator.js` |
| **Beauty scan (worker)** | `routes/v1/beautyScanRoutes.js:15` (proxy multipart de 4 imágenes) | llama al worker en `:13`/`:47` |
| **Glowshop / tienda** | `productRoutes.js:25-38` (catálogo + admin de productos), `:41` (`POST /store/checkout`), `:42-43` (órdenes) | `productController.js`, `orderController.js` |
| **Inventario** | `inventoryRoutes.js:9,12` | `inventoryController.js` |
| **Admin (finanzas/resolución)** | `adminRoutes.js:9` (`/disputes`), `:34` (`/disputes/:id/resolve`); `paymentRoutes.js:1007,1050,1088`; `adminPreciosRoutes.js:25-31` | `adminRoutes.js`, `paymentRoutes.js`, `adminPreciosController.js` |
| **Academia** | `academyRoutes.js:121-553`, `academyAdminRoutes.js:19-641` | `academyService.js`, `documentGeneratorService.js` |

### 2.3 Servicios que tocan dinero (los que importan)

| Archivo | Qué hace con el dinero |
|---|---|
| `backend/src/services/wompiService.js:26` (`disbursePayout`) | Escribe `transactions.status='paid'` (`:46-55`) — **simulado**. |
| `backend/src/services/wompiService.js:81` (`crearPayout`) | Marca `retiros.estado='COMPLETADO'` (`:96-103`) y `wallet_transactions.estado='COMPLETADO'` (`:106-114`) — **simulado**. |
| `backend/src/jobs/paymentJobs.js:40` | Madura saldos pendientes de `wallet_transactions` a `provider_wallet`. |
| `backend/src/jobs/paymentJobs.js:98` | Dispara retiros automáticos; llama `wompiService.crearPayout` en `:184` (con `.catch` en `:191`). |
| `backend/src/jobs/paymentJobs.js:212` | Conciliación diaria. |
| `backend/src/routes/paymentRoutes.js:401` | En `GET /wallet` **acredita saldo**: pasa `wallet_transactions` maduradas a `COMPLETADO` y suma a `provider_wallet.saldo_disponible` (`:406-440`). Una lectura con efecto de escritura. |
| `backend/src/routes/paymentRoutes.js:691` | Retiro por demanda dentro de una transacción con `FOR UPDATE` sobre `provider_wallet` (`:705`), valida pausa, cuenta verificada, mínimo, saldo y cadencia. |
| `backend/src/controllers/bookingController.js:590` | Webhook: exige firma (`:592`), idempotencia por `external_id` (`:621` es el log del evento duplicado ignorado), **valida que el monto pagado cubra `valor_bruto`** (`:631-634`), descuenta stock con `FOR UPDATE` (`:666`) |
| `backend/src/routes/xpLogRoutes.js:45` | `POST /convert-cashback` (conversión de XP a saldo). |
| `backend/src/modules/admin-glow/admin.routes.js:50,62` | `payout/approve` y `dashboard/financial-summary` — **inalcanzables** (ver trampa T-04). |

---

## 3. Capa de datos

### 3.1 `backend/src/config/db.js` exporta un **wrapper** del pool

```
backend/src/config/db.js:740
module.exports = { pool, testConnection, getDbStatus, ragPool, testRagConnection, dbEnMemoria };
```

El `pool` exportado **no** es el `Pool` de `pg`: es un objeto propio (`db.js:600-662`). El `Pool` crudo vive en `db.js:26-39` (`rawPool`) y no se exporta. Esa indirección es **el punto único de inyección del tenant**: cualquier `pool.query` de los ~300 call sites pasa por aquí y esta rama decide en qué conexión se ejecuta.

```
backend/src/config/db.js:607-610
const activeClient = tenantRouting.getActiveClient();
if (activeClient) {
  return activeClient.query(text, params);   // la conexión de la petición, que tiene app.tenant_id fijado
}
```

| Pieza del wrapper | Línea | Qué hace |
|---|---|---|
| `pool.query` | `db.js:601-646` | 1) cliente dedicado de la petición → 2) `pgMemory`/modo memoria → 3) pool real; sólo los **errores de enlace** degradan a memoria |
| `pool.connect` | `db.js:647-660` | devuelve un cliente real, o un `clienteEnMemoria()` (`db.js:586-591`) si no hay enlace |
| `pool.on` | `db.js:661` | reenvía al `rawPool` |
| `dbEnMemoria()` | `db.js:738` | expuesto para que los repositorios decidan si un error de SQL debe propagarse o si la memoria es fuente legítima |

### 3.2 Enrutado de la conexión por petición (`AsyncLocalStorage`)

`backend/src/config/tenantRouting.js` es el módulo aislado a propósito (lo dice su cabecera, `:1-25`) y su comentario explica por qué existe: con un pool normal, `pool.query` toma cualquier conexión libre, así que fijar el contexto en un middleware no garantiza nada para las consultas posteriores (`:7-16`).

| Función | Línea | Qué hace |
|---|---|---|
| `storage` (AsyncLocalStorage) | `:27-29` | transporte del cliente dedicado |
| `getActiveClient()` | `:38-41` | lo que consulta el wrapper de `db.js` |
| `isPerRequestTransactionEnabled()` | `:65-72` | **activo por defecto**; se desactiva con `TENANT_TRANSACTION_PER_REQUEST=false` |
| `runInTenantTransaction(deps, tenantId, fn)` | `:86` | `BEGIN` → `set_config('app.tenant_id', …, **true**)` (`:99-104`) → `fn` → `COMMIT` (`:111`) / `ROLLBACK` (`:118`) → `release()` (`:126-127`) |
| `runAsSystemContext(fn)` | `:148-150` | marca contexto de sistema sin abrir conexión (para caminos Sequelize) |
| `runAsSystem(deps, fn)` | `:169` | `BEGIN` + `SET LOCAL ROLE app_system` (`:177`) → `fn` → `COMMIT`/`ROLLBACK` |

`SET LOCAL ROLE` es deliberadamente de alcance transaccional: un `SET ROLE` de sesión dejaría una conexión con `BYPASSRLS` circulando por el pool (`tenantRouting.js:158-162`).

**Pero ese middleware no está montado.** `tenantContextMiddleware` (`backend/src/middleware/tenantContext.js:50`) sólo aparece en su propio archivo (`:1,50,104,111`) y en `backend/src/tests/tenantContext.test.js:37`. `grep -rn "tenantContext" backend/src backend/index.js` no devuelve ningún `require` desde `index.js` ni desde `authRoutes.js`. Ver trampa **T-03**.

### 3.3 Fallback en memoria y su marca `servingFabricatedData`

| Elemento | Línea | Detalle |
|---|---|---|
| `handleMemoryQuery(text, params)` | `db.js:149-525` | intérprete de SQL por coincidencia de subcadenas: devuelve usuarios, proveedores, servicios, portafolio, reseñas, salones, bookings y memberships **inventados** |
| Credenciales demo hardcodeadas | `db.js:52-53` | `bcrypt.hash('password123', 10)` y `bcrypt.hash('Password123!', 10)`, asignadas a `demo1@demo.com`… (`:72-87`) |
| **Auto-creación de usuarios** | `db.js:167-179` | cualquier email desconocido obtiene un usuario nuevo; el rol sale del nombre del email (`:175`: contiene `salon` → `SALON`; `prestador`/`provider` → `PRESTADOR`) |
| Modo decidido en **arranque**, no por consulta | `db.js:549` (`let dbMode = 'indefinido'`) + `:581-584` (enfriamiento de 5 s) | el comentario `:532-548` documenta el defecto anterior: un solo tropiezo condenaba al proceso entero a memoria hasta reiniciar |
| Sólo degradan los errores de **enlace** | `db.js:567-572` (lista de códigos) y `:574-579` (`esErrorDeEnlace`) | |
| Un error de **SQL** se propaga, nunca se sustituye | `db.js:637-641` (`if (!esErrorDeEnlace(err)) throw err;`) | el comentario `:538-541` da el caso medido: `SELECT * FROM tabla_que_no_existe_zzz` antes devolvía `{rows: []}` |
| Guard de producción | `db.js:140-143` | `NODE_ENV=production` + `ALLOW_MEMORY_FALLBACK=true` → `console.error` + `process.exit(1)` |
| Tests herméticos | `db.js:560-563` | en `NODE_ENV=test` sin `DATABASE_URL` el módulo entra en memoria forzada y no toca ninguna base real |
| `memoryFallbackAllowed()` | `db.js:718-725` | en producción devuelve siempre `false` |

**La marca `servingFabricatedData`**

```
backend/src/config/db.js:715   let isPgAvailable = null;
backend/src/config/db.js:716   let servingFabricatedData = false;
backend/src/config/db.js:727-731  const getDbStatus = () => ({ pgAvailable: isPgAvailable, servingFabricatedData, ... });
backend/index.js:422           const degradado = db.servingFabricatedData || db.pgAvailable === false;
```

`grep -rn "servingFabricatedData" backend` devuelve exactamente 4 apariciones: la declaración (`db.js:716`), la lectura en `getDbStatus` (`db.js:729`), la lectura en `/api/health` (`index.js:422`) y una aserción de test (`backend/src/tests/audit360-remediation.test.js:62`). **Nunca se le asigna `true`.** Lo mismo con `isPgAvailable` (`db.js:715`), que nunca se reasigna. Consecuencia: `degradado` es siempre `false` y `/api/health` (`index.js:420-430`) **nunca devuelve 503**. Ver trampa **T-01**.

### 3.4 RLS multi-tenant

| Pieza | Evidencia |
|---|---|
| Aislamiento estricto: políticas + `FORCE ROW LEVEL SECURITY` + relleno de `tenant_id` | `backend/migrations/068_force_rls_strict_isolation.sql:1-30` (cabecera que documenta los 4 defectos que tapaban el aislamiento: `:1-20`) |
| Centralización de la lectura del contexto | `backend/migrations/065_multi_tenant_hardening.sql:44-52`: `app_current_tenant_id()` = `NULLIF(current_setting('app.tenant_id', true), '')::INTEGER` — el `true` es `missing_ok` |
| En 068 la función se redefine igual | `068_force_rls_strict_isolation.sql:69` |
| Políticas permisivas OR-eadas (la razón de borrar todas) | `058_enable_rls_policies.sql:63`, `062_optimize_business_saas_postgres.sql:72` |
| RLS para conocimiento/RAG | `034_enable_rls_knowledge.sql:8` (`tenant_id IS NULL OR tenant_id = current_setting('app.tenant_id')::int`) |
| Niveles de tenant en glowshop | `071_glowshop_niveles_a0.sql:86` y `:199` (`PERFORM set_config('app.tenant_id', id_plataforma::text, true)`) |
| `071` rota los roles que se saltan RLS | `071_glowshop_niveles_a0.sql:359` (`FOREACH r IN ARRAY ARRAY['app_rls_user', 'app_system', 'app_runtime_user', 'beauty_app_user']`) |

**Los tres roles y cómo se prueba el aislamiento**

| Rol | Definición | Evidencia |
|---|---|---|
| `app_rls_user` | **La aplicación**. LOGIN, sin superusuario y **sin BYPASSRLS**, no propietaria de las tablas | `backend/scripts/setupRlsRole.sql:13,33-36` |
| `app_system` | BYPASSRLS, para webhooks y jobs | `setupRlsRole.sql:57-77` (`GRANT app_system TO app_rls_user` en `:77`) |
| `app_owner` | PROPIETARIO no superusuario (para poder probar con FORCE de verdad) | `backend/scripts/prepareRlsDatabase.js:116-129` (`ALTER TABLE … OWNER TO app_owner` en `:145`) |

| Cómo | Evidencia |
|---|---|
| La app se **conecta** como `app_rls_user` | `setupRlsRole.sql:9`, `.github/workflows/ci.yml:93` (`DATABASE_URL: postgres://app_rls_user:…`) |
| La prueba fija el inquilino con `set_config('app.tenant_id', …, true)` dentro de `BEGIN` | `backend/scripts/verifyTenantIsolation.js:63` (y el comentario `:57-62` explica por qué no puede usarse `SET LOCAL app.tenant_id = $1`) |
| «No poder comprobar no es aprobar»: sin URL el script sale con código **2** | `verifyTenantIsolation.js:10-16` y `:23-25` |
| El propio script detecta la mutación que rompería el aislamiento | `backend/scripts/verifyTenantIsolation.js:6-11` (quitar `FORCE`, añadir política permisiva, conectar con rol que salta RLS, o revertir `app_current_tenant_id()`) |
| Comprobación de que `app_rls_user` no tiene `rolbypassrls` | `setupRlsRole.sql:106-111` |
| En CI la compuerta es **bloqueante**, antes de los tests | `.github/workflows/ci.yml:65-78` |

> Precisión sobre el enunciado: **no existe ningún `SET ROLE app_rls_user` explícito** en el código. Lo que hay es (a) la app *conectándose* con ese rol y (b) una **escalada** a `app_system` con `SET LOCAL ROLE app_system` para los caminos de sistema (`tenantRouting.js:177`, `paymentJobs.js:11-23`). `grep -rn "SET ROLE" backend/src` sólo devuelve `app_system`.

### 3.5 El camino de Sequelize (segundo pool)

Hay dos caminos de datos que deben discrepar lo menos posible:

| Camino | Motor | Evidencia |
|---|---|---|
| Consultas crudas | `pg` a través del wrapper de `db.js` | `db.js:600-662` |
| Modelos | Sequelize con su **propio** pool | `backend/src/models/index.js`; la cabecera de `tenantRouting.js:53-62` explica que Sequelize necesita el valor del tenant para fijarlo él mismo |
| Tests de esa pieza | `SET ROLE app_system` con contexto de sistema; `RESET ROLE` + `RESET app.tenant_id` al liberar la conexión | `backend/src/tests/sequelizeTenantContext.test.js:74-96,115,124` |
| El esquema y los roles en CI los monta un script propio, **no** `npm run migrate` | `.github/workflows/ci.yml:61-68` (el comentario `:61-64` lo justifica: `sequelize.sync({force:true})` no lleva ninguna política de RLS) | |

---

## 4. Integraciones externas: qué es real y qué está simulado

### 4.1 Reales (hablan con un servicio por HTTP / SDK)

| Integración | Evidencia | Notas |
|---|---|---|
| **Gemini** (SDK) | `backend/package.json:20` (`@google/generative-ai`), `backend/src/services/geminiService.js:3`, `:25` (`process.env.GEMINI_API_KEY`), `:28` (`new GoogleGenerativeAI(...)`) | Si falta la clave: `geminiService.js:974` (`⚠️ Gemini API no configurada … No hay fallback disponible`) |
| **Gemini** (REST) | `backend/src/services/biometric/gemini.client.js:10` (`https://generativelanguage.googleapis.com/v1beta`), `axios.post` en `:30` y `:120` | |
| **DeepSeek** (motor de AURA, con tool calling) | `geminiService.js:20-22` (`DEEPSEEK_API_KEY`, modelo `deepseek-v4-flash`, `https://api.deepseek.com/chat/completions`), llamadas en `:545-590` y `:658-680`; sin clave: `:978` | El defecto de `DEEPSEEK_BASE_URL` en el router de AURA es `/chat/completions`; en `railway.yml:84` se inyecta `/v1/chat/completions` |
| **DeepSeek** (biometría) | `backend/src/services/biometric/deepseek.client.js:7-8`, `:38`, `:100` | |
| **NVIDIA NIM Embeddings** | `backend/src/services/embeddingService.js:14-16` (`nvidia/nv-embedqa-e5-v5`, `https://integrate.api.nvidia.com/v1`, 1024 dims), **sin fallback dummy** (`:134-147`) | El comentario de `ragService.js:43-44` lo confirma: si NVIDIA falla, el retrieval degrada a full-text en lugar de buscar con un vector sin valor semántico |
| **Wompi — recepción (webhook)** | Firma verificada en `bookingController.js:9` (definición) y `:592` (invocación); rechaza con 401 si no cuadra | Esta parte **sí** es real |
| **YouCam** (MakeupAR) | `backend/src/services/biometric/youcam.client.js:14-18` (`https://yce-api-01.makeupar.com/s2s/v2.0`, `pollIntervalMs` 3 s, `pollTimeoutMs` 60 s); orquestado en `backend/src/services/biometric/orchestrator.js:21-22` | Tiene *fallbacks* que devuelven valores **fijos** (`youcam.client.js:45-59`: `hd_moisture 75`, `hd_wrinkle 15`, `skin_age 28`…). Ver `§4.2` |
| **TheColorAPI** | `backend/src/services/theColorApi.js:6` (`https://www.thecolorapi.com`), `:18`, `:55` | |
| **OpenBeautyFacts** | `backend/src/services/openBeautyFacts.js:6` (`https://world.openbeautyfacts.org/api/v2`), `:15`, `:44` | |
| **OpenUV** | `backend/src/services/openUV.js:7-8` (`OPENUV_API_KEY`, `https://api.openuv.io/api/v1`), `:46` | Con resultado *mock* si falta clave (`:33-42`) |
| **OpenStreetMap / CartoDB** (tiles) | `backend/index.js:304-344` (proxy con caché en memoria de 3 000 entradas y PNG de respaldo embebido en `:337-343`) | |
| **Worker de IA (FastAPI)** | Llamado desde `backend/src/routes/v1/beautyScanRoutes.js:13` y `:47` | Ver `§4.3` |
| **Redis** | `backend/src/config/redis.js`; usado para *blacklist* de tokens en `backend/src/middleware/auth.js:31`, **fail-closed en producción** (`:22-25`) | |

### 4.2 Simulados o directamente bloqueados

| Integración | Evidencia | Qué pasa realmente |
|---|---|---|
| **Wompi — salida de dinero** (payouts y retiros) | `backend/src/services/wompiService.js:9-17` (guardia `simuladorPermitido()` y `rechazarSimulacion()`) | **No llama a Wompi.** En producción sin `ALLOW_PAYMENT_SIMULATOR=true` **lanza error** (`:27` en `disbursePayout`, `:82` en `crearPayout`). Si se permite, genera una referencia **aleatoria** (`:42`, `:93`) y escribe `transactions.status='paid'` (`:46-55`) / `retiros.estado='COMPLETADO'` (`:96-103`) tras un `setTimeout` que sólo simula latencia (`:29` 1500 ms, `:84` 1000 ms) |
| **Email transaccional** | `backend/src/services/emailService.js:14-26` (el bloque de nodemailer está **comentado**: `:15` abre `/*`, `:24` cierra; sólo queda `console.log` en `:10-12` y `return true` en `:26`) y `backend/src/services/email.service.js:76-82` (`📧 [EMAIL SERVICE SIMULATION]`) | No se envía ningún correo |
| **Push FCM** | `backend/src/services/fcmNotificationService.js:85` (`📲 [FCM SIMULATION] Push enviada a token …`) | No se envía ningún push |
| **Catálogo de prueba virtual (VTO)** | `backend/src/services/vto/vtoService.js:16-35` (`mockCatalog` de marcas y tonos), devuelto en `:35` | Catálogo hardcodeado |
| **Búsqueda de diseños de uñas / análisis facial** | `backend/src/controllers/designsController.js:83-114` (`MOCK_NAIL_IMAGES`), `:116` (`MOCK_FACE_ANALYSIS`), usado en `:344-355` | Resultados fabricados |
| **Fallback de YouCam** | `backend/src/services/biometric/youcam.client.js:45-59` | Si el proveedor falla y el *breaker* está abierto, se devuelven puntuaciones **fijas** (`ui_score` 75/15/12/25, `skin_type: 'cálido'`) como si fueran una medición. La llamada real está en `:69-…` y el orquestador la envuelve en `breakers.youcam.execute` (`orchestrator.js:21-22`), con lo que el fallback es alcanzable |
| **`ai_worker` y modelos de ML** | `ai_worker/services/color_analysis.py:1-33` (`ALCANCE` en `:63`, `METODO_GLOBAL` en `:65-70`) | **No hay modelo entrenado.** Calcula estadísticas de píxeles (medias RGB, luminancia/saturación, gradiente, fracción de piel YCbCr) y declara explícitamente lo que no puede medir con `no_medido(campo, motivo)` (`:91`, `NO_MEDIDO_CAMPOS` en `:73-90`). Esto es *honesto*, no *simulado*, pero conviene no confundirlo con un motor clínico |
| **`MOCK_MODE`** | `railway.yml:45-46` declara `MOCK_MODE: "true"` para `ai-worker`, pero **`grep -rn "MOCK_MODE" ai_worker` no devuelve nada** | **NO VERIFICADO** qué servicio lee esa variable |

### 4.3 El worker de IA: dónde vive de verdad

| Hecho | Evidencia |
|---|---|
| **Existe**, pero se llama `ai_worker/` (guion **bajo**), no `ai-worker/` | `ls -d */` en la raíz lista `ai_worker/`; `ls -d ai-worker` → *No such file or directory* |
| Contenido | `ai_worker/main.py`, `models.py`, `requirements.txt`, `Dockerfile`, `services/color_analysis.py`, `services/skin_metrics.py`, `tests/test_beauty_scan_contract.py` |
| Framework y endpoints | FastAPI (`ai_worker/main.py:23` `app = FastAPI(...)`); `POST /api/v1/beauty-scan`, `POST /api/v1/analyze-skin`, `POST /v1/ai/consult` (docstring `main.py:1-19`) |
| Puerto por defecto | **8000**, no 8001: `ai_worker/Dockerfile:18` (`EXPOSE 8000`) y `:20` (`uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}`) |
| Cómo lo llama el backend | `backend/src/routes/v1/beautyScanRoutes.js:13` (`AI_WORKER_URL \|\| 'http://ai-worker:8000'`), `:47` (`axios.post(\`${AI_WORKER_URL}/api/v1/beauty-scan\`)`) |
| El proxy propaga el 4xx del worker en vez de enmascararlo con un 500 | `beautyScanRoutes.js:86-91` |

**Conclusión del hallazgo:** la documentación previa que afirmaba que existía un `ai-worker/` describía algo real, pero **con el nombre mal**: el directorio es `ai_worker/` y el puerto es 8000. Y ninguna de las dos configuraciones de despliegue lo levanta correctamente: `docker-compose.prod.yml` no lo declara en absoluto (`:1-45`), y `railway.yml:36-37` construye desde `../ai-worker` (guion), ruta inexistente. El fallo es de despliegue, no de código: `ai_worker/` existe y el backend sabe llamarlo.

---

## 5. Runner de migraciones: por qué una migración **debe** ser idempotente

El runner vive dentro del arranque, en `initDatabase()`:

```
backend/index.js:1619  // 11. Ejecución de migraciones automáticas (.sql en la carpeta migrations)
backend/index.js:1625   .filter(file => file.endsWith('.sql') && !file.endsWith('.down.sql'))
backend/index.js:1626   .sort();   // orden alfabético
backend/index.js:1662   try {
backend/index.js:1663     const sql = fs.readFileSync(filePath, 'utf8');
backend/index.js:1664     await pool.query(sql);          // ← UNA sola consulta por archivo
backend/index.js:1665     console.log(`✅ … Migración ${file} aplicada exitosamente.`);
backend/index.js:1676   } catch (err) {
backend/index.js:1678     if (!err.message.includes('already exists') && !err.message.includes('ya existe') &&
backend/index.js:1679         !err.message.includes('duplicate key value') && !err.message.includes('already a column')) {
backend/index.js:1679       console.warn(`⚠️ Advertencia en migración ${file}:`, err.message);
backend/index.js:1680       dbErrors.push({ stage: `migration-file-${file}`, message: err.message });
```

| Hecho | Evidencia | Consecuencia |
|---|---|---|
| Cada `.sql` se manda en **una sola** `pool.query(sql)`, sin parámetros | `backend/index.js:1664` | node-postgres usa el protocolo *simple*; el servidor ejecuta el archivo entero en **una transacción implícita**. Si **una** sentencia falla, se revierte **todo** el archivo: no queda un estado a medias, queda el archivo **sin aplicar** |
| Al ser transacción única, un archivo **no idempotente** falla en la *primera* sentencia ya aplicada y nunca llega a las siguientes | `backend/index.js:1663-1664` | Esa migración **jamás** se completa en reintentos: sólo la primera ejecución en una base virgen la aplica |
| El error se convierte en **warning** y el arranque **continúa** | `backend/index.js:1676-1680` (no hay `throw`) y `:1695-1698` (sólo el fallo al leer el directorio es `console.error`) | Un esquema incompleto arranca igual. El único rastro está en `lastDbInitError` (`:1740-1748`), expuesto en `GET /api/debug-db` (`:449`) |
| Sólo los errores «ya existe» se silencian del todo | `backend/index.js:1678`, `:1682` | Es la idempotencia «tolerada» |
| Hay además un registro de migraciones aplicadas | tabla `schema_migrations` creada en `index.js:1634-1640`, checksum `sha256` recortado a 16 hex en `:1652`, consulta en `:1642-1643`, escritura en `:1668-1671` | Evita re-ejecutar; si el registro no está disponible, el runner **cae al modo idempotente anterior** (`:1645-1647`) |
| Deriva de migración se avisa pero **no se reaplica** | `index.js:1654-1657` (`⚠️ Deriva de migración: … cambió después de aplicarse … No se re-aplica; revisar a mano`) | Editar un `.sql` ya aplicado **no** tiene efecto |
| Los *rollbacks* nunca se aplican solos | `index.js:1625` (`!file.endsWith('.down.sql')`) y el comentario `:1624` («sólo un humano, a propósito») | correcto por diseño |
| Idempotencia observable en el propio arranque | `CREATE TABLE IF NOT EXISTS` en `index.js:1424,1447,1471,1529`; `CREATE INDEX IF NOT EXISTS` en `:1435,1459,1488,1551-1553`; `DROP TRIGGER IF EXISTS` en `:1569,1576`; `ADD COLUMN IF NOT EXISTS` en `:1389,1401,1413,1586-1588` | El estilo del repo ya asume el requisito |
| `ALTER TYPE … ADD VALUE 'APPLE'` tolera el duplicado por **código de error** | `index.js:1376-1382` (`if (e.code !== '42710')`) | 42710 = `duplicate_object` |
| Lo que el runner **no** aplica | `backend/migrations/*.js` son **7** archivos (p. ej. `20260716220001-create-academy_certificates.js`) y los subdirectorios `manual/` y `rollback/`: el filtro de `index.js:1625` sólo acepta archivos terminados en `.sql` en el nivel superior | 7 migraciones Sequelize quedan fuera del arranque |
| El único `.down.sql` está en un subdirectorio | `backend/migrations/rollback/035_fix_embedding_dimension_and_hnsw_index.down.sql` | doblemente excluido |

**Hay un segundo runner, independiente y no usado por `npm`:**

| Hecho | Evidencia |
|---|---|
| `backend/runMigrations.js` usa **Sequelize** y una lista de archivos **hardcodeada** de 6 nombres | `runMigrations.js:109-116` (`059_create_tipo_trabajador_enum.sql`, `060_add_worker_type_to_usuarios.sql`, `055`…`058`) |
| Tiene su propio *splitter* de sentencias (comillas simples y *dollar-quoting*) | `runMigrations.js:6-73`, usado en `:122-128` |
| **Aborta** al primer fallo | `runMigrations.js:134-137` (`process.exit(1)`) |
| No está en `package.json` | `backend/package.json:6-15`: los scripts son `dev`, `start`, `test`, `migrate`, `ingest:rag`, `purge:rag`, `eval:rag`, `ci:eval` |
| `npm run migrate` **no** ejecuta migraciones: es destructivo | `backend/package.json:9` → `node -e "require('./src/models').sequelize.sync({force:true});"` |

---

## 6. Trampas de esta arquitectura

1. **`/api/health` no puede degradar nunca (falso verde).**
   `servingFabricatedData` (`backend/src/config/db.js:716`) e `isPgAvailable` (`:715`) se declaran con valor fijo y se leen en `getDbStatus` (`:727-731`) y en el health check (`backend/index.js:422`), pero **ninguna línea del repo las reasigna** (`grep -rn "servingFabricatedData" backend` → 4 apariciones: `db.js:716`, `db.js:729`, `index.js:422`, `tests/audit360-remediation.test.js:62`). El proceso puede estar sirviendo `handleMemoryQuery` (`db.js:149-525`) y `/api/health` seguirá diciendo `OK` con 200. El comentario de `index.js:417-419` dice que se arregló el `setval` y el 200 con la BD caída — la mitad de ese arreglo quedó sin cablear.

2. **El bundle Flutter commiteado convierte cada fix de frontend en una tarea humana.**
   `.gitignore:71` ignora `backend/public/` pero sus **192 archivos** están rastreados (`git ls-files backend/public | wc -l`), y el CI no compila ni copia nada (`.github/workflows/ci.yml:106-127` sólo hace `flutter analyze`). Medido: un camino ya rastreado como `backend/public/index.html` **no** está ignorado (`git check-ignore` → exit 1), pero uno **nuevo** sí (`git check-ignore backend/public/NUEVO_inexistente.js` → `.gitignore:71`). Un rebuild que introduzca artefactos nuevos no se commiteará con `git add .`.

3. **El middleware que debía aislar el inquilino por transacción no está montado, y el tenant se fija a nivel de sesión.**
   `tenantContextMiddleware` (`backend/src/middleware/tenantContext.js:50`) no se importa desde `index.js` ni desde ningún router. Quien fija `app.tenant_id` es `backend/src/middleware/auth.js:57`, con `set_config($1, $2, **false**)` — alcance de sesión sobre una conexión del pool. El comentario de `tenantContext.js:22-24` afirma que «ese bloque se ha eliminado»; **sigue ahí**. La infraestructura correcta (`tenantRouting.runInTenantTransaction`, `tenantRouting.js:86`) existe y está probada, pero nadie la engancha al ciclo de vida de la petición.

4. **`backend/src/modules/admin-glow/` es código muerto, y contiene dinero.**
   `admin.routes.js:50` (`POST /payout/approve`) y `:62` (`GET /dashboard/financial-summary`) no son alcanzables: `grep -rn "admin-glow" backend --include=*.js` no devuelve **ninguna** referencia, y `grep -rn "require(.*modules/" backend/src backend/index.js` tampoco. Un `curl` a esas rutas devuelve el 404 JSON de `index.js:1346-1348`.

5. **En producción, el retiro se confirma al usuario y luego falla en silencio.**
   `paymentRoutes.js:818-825` llama `wompiService.crearPayout(...)` **después** del `COMMIT` (`:816`) y le pone un `.catch` que sólo hace `console.error`. Como `crearPayout` lanza cuando no hay pasarela real (`wompiService.js:82`), el retiro queda en `PENDIENTE` y el usuario ya recibió `200` con «El dinero llegará en 1-2 días hábiles» y `estado: 'PROCESANDO'` (`paymentRoutes.js:827-835`). El error no llega a la respuesta ni a ninguna alerta.

6. **Una migración no idempotente se pierde para siempre, en silencio.**
   `index.js:1664` manda el archivo entero en una consulta (transacción implícita única) y `index.js:1676-1680` convierte el fallo en `console.warn` sin detener el arranque. Reintentar no ayuda: el archivo vuelve a fallar en la primera sentencia ya aplicada. La única señal es `GET /api/debug-db` (`index.js:449`).

7. **La configuración de despliegue del worker de IA apunta a un directorio que no existe.**
   `railway.yml:36-37` usa `context: ../ai-worker` (guion) y el directorio real es `ai_worker/` (guion bajo); `docker-compose.prod.yml:1-45` no declara ningún servicio de IA, mientras `beautyScanRoutes.js:13` resuelve por defecto a `http://ai-worker:8000`. El código del worker es correcto y el backend sabe llamarlo; falta que algo lo levante y con el nombre correcto.

8. **`.gitignore` y `.github/workflows/ci.yml` tienen marcadores de conflicto de merge sin resolver.**
   `.gitignore:32-37` y `:84-94` contienen `<<<<<<< HEAD` / `=======` / `>>>>>>> origin/main`; `ci.yml:60-90` ídem, con dos pasos distintos en cada rama (en `main` corre `verifyNoVersionedSecrets.js`, en la otra `prepareRlsDatabase.js` + `verifyTenantIsolation.js`). Ninguna de las dos versiones se ejecuta entera como el autor pretendía, y el archivo deja de ser interpretable por herramientas que no toleren el markup.

9. **El fallback en memoria crea usuarios con privilegios a partir del nombre del email, y trae credenciales demo hardcodeadas.**
   `db.js:167-179`: si el email no existe, se crea un usuario; el rol se deriva del texto (`:175`: `salon` → `SALON`, `prestador`/`provider` → `PRESTADOR`). Y `db.js:52-53` siembra `demo1@demo.com`… con contraseñas fijas (`password123`, `Password123!`). Está contenido detrás de `ALLOW_MEMORY_FALLBACK` (`db.js:140-143`, `:718-725`) y del modo hermético en test (`:560-563`), pero el camino existe.

10. **Dos raíces estáticas para el frontend y un SPA *fallback* duplicado, con uno de los dos muerto en producción.**
    `backend/index.js:209-214` sirve `../frontend/build/web` si existe (en este checkout **no** existe: `ls frontend/build/web` → no such file) y `:1762-1768` vuelve a hacer de SPA fallback sobre esa misma ruta; lo que realmente se sirve es `backend/public` (`:351` y `:354-356`). Es fácil editar/probar contra la raíz equivocada y creer que se ha cambiado algo.

11. **`npm run migrate` es destructivo y no migra.** `backend/package.json:9` → `sequelize.sync({force:true})`. El propio CI lo reemplaza por `scripts/prepareRlsDatabase.js` (`.github/workflows/ci.yml:61-68`), y la razón está escrita en `:61-64`: ninguna política de RLS vive en un modelo Sequelize.

12. **El webhook de pago es correcto, y por eso mismo destaca el contraste.** `bookingController.js:592` exige firma, `:621` registra la deduplicación por `external_id` y `:631-634` rechaza montos por debajo de `valor_bruto`. Es el único camino de dinero con controles reales; **el camino de salida** (`wompiService.js`) es un simulador (trampa T-05). Cualquier auditoría futura que sólo lea el webhook concluirá que los pagos están resueltos.

---

## 7. NO VERIFICADO

| Punto | Por qué no se pudo verificar |
|---|---|
| Qué servicio lee `MOCK_MODE` (declarado en `railway.yml:45-46`) | `grep -rn "MOCK_MODE" ai_worker` no devuelve nada; no se encontró ningún consumidor en el repo |
| Valores reales de las variables de entorno de producción (`PORT`, `DATABASE_URL`, `ALLOWED_ORIGINS`, `ALLOW_PAYMENT_SIMULATOR`, `TENANT_TRANSACTION_PER_REQUEST`, `AI_WORKER_URL`) | No hay `.env` versionado (`.gitignore:6-8`) y no se dispone del entorno desplegado |
| Si `backend/public` corresponde al `HEAD` de `frontend/` | Los artefactos compilados no llevan una referencia verificable al commit del frontend; `backend/public/.last_build_id` es un hash opaco. El único commit que lo tocó es `5c3e879c` (`git log -1 -- backend/public/main.dart.js`) |
| Si el runner de migraciones se ha ejecutado con éxito contra la base de producción, y en qué estado quedó `schema_migrations` | Requiere acceso a la base; este documento se basa sólo en el repositorio |
| Las 7 migraciones `.js` de `backend/migrations/` (¿se aplican por algún camino no encontrado?) | `grep -rn "require(.*modules/"` y los scripts de `backend/scripts` revisados no las referencian; `runMigrations.js:109-116` lista sólo 6 `.sql` |
| Estado de las ramas `main`/`staging` y de los despliegues de Railway | Fuera del alcance de la lectura del repositorio |
