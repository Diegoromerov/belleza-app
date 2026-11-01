# GLOWAPP — PLAN DE TRABAJO UNIFICADO (BASELINE AUDITABLE)
**Versión:** 1.1 — 2026-11-01 (revisión con evidencia E1 verificada)  
**Propósito:** Unificar plan split-architecture + observabilidad en una sola ruta auditable fase a fase  
**Estado:** Baseline consolidado — sin desviaciones a partir de esta versión

**Snapshot verificado 2026-11-01:** backend operativo en **staging y producción** (`/api/health` 200, `/api/providers` 200, PostGIS 3.4.3, RLS 37/37 en producción). Fase 8 (Cleanup & Docs) **COMPLETADA** — siguiente: 7 (Cloudflare) y 6 (custom domains), ambas bloqueadas por factores externos.

---

## ARQUITECTURA OBJETIVO (Inmutable)

| Lado | App | Dominio | Audiencia | Backend |
|------|-----|---------|-----------|---------|
| **USUARIOS** | `glow_client` | `app.glowapp.com` | `client` | API única `api.glowapp.com` |
| **PRESTADORES** | `glow_provider` | `pro.glowapp.com` | `provider` / `salon` | JWT `roles[]` + `audience` + header `X-App-Audience` |
| **ADMIN** | `admin-dashboard` | `admin.glowapp.com` | `admin` | RLS PostgreSQL por rol/tenant |

**Monorepo:** `packages/glow_core` (shared) → `apps/glow_client` + `apps/glow_provider` + `admin-dashboard` + `backend`

---

## PLAN UNIFICADO — 10 FASES (0-9)

| Fase | Nombre | Objetivo Principal | Estado Actual | Autorización Requerida |
|------|--------|-------------------|---------------|------------------------|
| **0** | **Foundation** | Monorepo tooling, `glow_core` skeleton, `video_mapping.dart` stub | ✅ **100% COMPLETADA** | — |
| **1** | **Core Migration** | Mover 10 módulos a `glow_core`, fix imports, `flutter analyze` clean | ✅ **100% COMPLETADA** | — |
| **2** | **Client App** | Scaffold `glow_client`, pantallas usuario, routes, build web | ✅ **100% COMPLETADA** | — |
| **3** | **Provider App** | Scaffold `glow_provider`, pantallas prestador/salón/academy, routes, build web | ✅ **100% COMPLETADA** | — |
| **4** | **Backend Audience Scoping** | JWT `roles[]`+`audience`, middleware `requireAnyRole`, route guards, contract tests | ✅ **100% COMPLETADA** | `GLOWAPP-F004-BACKEND` |
|| **5** | **Firebase & Deploy Ops** | 2 proyectos Firebase, FCM, Service Accounts, secrets, keystores, certs, Firestore rules | ✅ **100% COMPLETADA** | `GLOWAPP-F005` |
|| **6** | **CI/CD + Firebase Hosting + DNS** | Pipeline dual, Firebase Hosting `glowapp-client`/`glowapp-provider`, backend Railway, DNS custom domains | 🟡 **95%** (deploy backend staging ✅ **y producción ✅**, Firebase Hosting staging ✅; solo faltan custom domains) | `GLOWAPP-F006-RAILWAY` |
|| **7** | **Cloudflare Stream** | Subir 16 videos, poblar `video_mapping.dart`, eliminar assets locales, iframe player HLS | 🟡 **45%** (Firebase Storage ✅, assets eliminados, Cloudflare bloqueado) | `GLOWAPP-F007` |
|| **8** | **Cleanup & Docs** | Archivar `frontend/`, docs finales, e2e smoke tests, **esquema BD reproducible + RLS verificado** | ✅ **100% COMPLETADA** (E2E 25/25) | `GLOWAPP-F008` |
| **9** | **Observabilidad (NUEVA)** | OpenTelemetry, Prometheus/Grafana/Loki/Tempo, dashboards, alertas, runbooks | ✅ **95% COMPLETADA** (PRODUCCIÓN) | `GLOWAPP-F009-OBS` |

---

## DETALLE POR FASE (AUDITABLE)

---

### FASE 0 — FOUNDATION ✅ COMPLETADA
**Entregables:**
- [x] `melos.yaml` + `pnpm-workspace.yaml` configurados
- [x] `packages/glow_core/pubspec.yaml` + `lib/glow_core.dart` (barrel export)
- [x] `packages/glow_core/lib/src/glowguide/config/video_mapping.dart` (stub)
- [x] `melos bootstrap` exitoso, `flutter analyze` sin errores en `glow_core`

**Evidencia:** Commits en `feat/split-client-provider-apps` + `main`

---

### FASE 1 — CORE MIGRATION ✅ COMPLETADA
**Entregables:**
- [x] 10 módulos movidos a `packages/glow_core/lib/src/`:
  - `services/` (api, auth, fcm, storage, analytics)
  - `models/` (provider, service, business_profile, glow_product, saas, superadmin)
  - `design/` (components, icons, tokens)
  - `core/` (theme, photography)
  - `shared/` (theme, tokens, calculations, currency, onboarding_helper)
  - `widgets/` (genéricos + owner/ + profile/)
  - `utils/` (json_num)
  - `data/` (colombia_municipalities)
  - `l10n/` (localizaciones)
  - `glowguide/` (motor completo: engine, contracts, state, observer, persistence, presenter, service, audio, config, model, utils)
- [x] `flutter analyze --no-fatal-infos --no-fatal-warnings` → 0 errores en `glow_core`

**Evidencia:** Estructura `packages/glow_core/` verificada en auditoría

---

### FASE 2 — CLIENT APP ✅ COMPLETADA
**Entregables:**
- [x] `apps/glow_client/pubspec.yaml` con `depends on: glow_core (path: ../../packages/glow_core)`
- [x] Pantallas usuario (31 archivos en `lib/screens/`): providers_screen, provider_detail, booking, booking_tracking, client_bookings, otp_confirm, store, chat_list, chat, profile/* (8), auth/* (8), disputes/, support/, ideas/, designs/
- [x] `lib/main.dart` con rutas cliente únicamente
- [x] `ProvidersScreen` extraído de monolito
- [x] `lib/widgets/` (13 genéricos: audience_toggle, app_update_gate)
- [x] `firebase_options.dart` cliente
- [x] `flutter build web --release --dart-define=APP_AUDIENCE=client` → OK en CI
- [x] Android (`com.glowapp.client`) + iOS (`com.glowapp.client`) scaffolding

**Evidencia:** `apps/glow_client/` completo, build web artifact en CI

---

### FASE 3 — PROVIDER APP ✅ COMPLETADA
**Entregables:**
- [x] `apps/glow_provider/pubspec.yaml` con `depends on: glow_core`
- [x] Pantallas prestador (13 grupos en `lib/screens/`):
  - `provider/` (dashboard, services, portfolio, profile, route, ai_copilot)
  - `salon/` (dashboard, hub)
  - `owner/` (owner screens)
  - `saas/` (team, billing, usage, api_keys)
  - `superadmin/` (superadmin screens)
  - `wallet_screen.dart`
  - `auth/` (routing → /provider o /salon)
  - `academy/` **COMPLETA** (hub, course_detail, quiz, nback, colorimetría, glass_card, glow_beauty, consent_widget)
  - `chat/` (chat_list, chat_screen — shared UI)
  - `disputes/` (shared UI)
  - `support/` (shared UI)
  - `profile/` (provider_profile)
- [x] `lib/main.dart` con rutas proveedor únicamente
- [x] `lib/widgets/` (13: provider/, owner/, store/, academy/)
- [x] `firebase_options.dart` proveedor
- [x] `flutter build web --release --dart-define=APP_AUDIENCE=provider` → OK en CI
- [x] Android (`com.glowapp.provider`) + iOS (`com.glowapp.provider`) scaffolding

**Evidencia:** `apps/glow_provider/` completo, build web artifact en CI

---

### FASE 4 — BACKEND AUDIENCE SCOPING ✅ **100% COMPLETADA**
**Entregables:**
- [x] **JWT payload** en `authController.js`: `roles: []` + `audience` claim
- [x] **Middleware** `requireAnyRole(...roles)` en `backend/src/middleware/audience.js`
- [x] **Route guards** en `index.js`:
  - Cliente: `/api/providers/search`, `/api/bookings`, `/api/store`, `/api/client-bookings`, `/api/my-glow` → `requireAnyRole('client')`
  - Proveedor: `/api/provider`, `/api/salon`, `/api/saas`, `/api/academy`, `/api/wallet` → `requireAnyRole('provider','salon')`
  - Admin: `/api/superadmin` → `requireAnyRole('admin')`
  - Compartidos: `/api/chat`, `/api/disputes`, `/api/support` → `requireAnyRole('client','provider','salon')`
- [x] **Frontend** `ApiService` en `glow_core`: header `X-App-Audience` desde `--dart-define=APP_AUDIENCE`
- [x] **Montaje global `appAudience`** en `index.js` (línea 252: `app.use('/api', validateAppAudience({ required: true }))`)
- [x] **JWT `aud` claim** en token firmado — 3 ubicaciones `authController.js`:
  - `login` (línea ~296): `jwt.sign(..., { expiresIn: '7d', audience })`
  - `oauth` (línea ~410): `jwt.sign(..., { expiresIn: '7d', audience })`
  - `switchContext` (línea ~955): `jwt.sign(..., { expiresIn: '7d', audience: roleToAudience[req.user.rol] || 'client' })`
- [x] **Tests de contrato** — 47/47 PASS:
  - `src/tests/contract/audience-binding.contract.test.js`: 17/17
  - `src/tests/contract/openapi.contract.test.js`: 8/8
  - `src/tests/contract/critical-endpoints.contract.test.js`: 15/15
  - `src/tests/contract/routersMontados.contract.test.js`: 7/7

**Autorización consumida:** `AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — GLOWAPP-F004-BACKEND`

**Evidencia:** Ejecución local con `JWT_SECRET=test-secret-key-for-testing-min-32-chars` — 47/47 PASS

---

### FASE 5 — FIREBASE & DEPLOY OPS ✅ **100% COMPLETADA**
**Entregables:**
- [x] 2 proyectos Firebase creados:
  - `glowapp-client` (634593218804)
  - `glowapp-provider` (509840252897)
- [x] `flutter build web` usa `--dart-define` para keys por app
- [x] 2 Keystores Android generados:
  - `glow_client_key` / `glowclient2026`
  - `glow_provider_key` / `glowprovider2026`
- [x] Firestore rules + indexes en `.secrets/`
- [x] **VAPID Keys configuradas** (ambas):
  - Client: `BPesRggflU9ZV1O0hRwynJoXNEvF3eXUVvhtWZDRoGUOob8dsD-4XS6oX2FIszHQOiRJN8IewGtO4syKTkd3m7s`
  - Provider: `BKJVD0PXlUulswEAGWKxRB8XThAJ1DfPmCdDkYllaWA5qVgVSow1io30UHrUQn1wKPoLAioc5-Lu8MY4EOOD3H0`
- [x] **FCM tokens con `roles[]` propagado** en `saveFcmToken` (authController.js)
- [x] **iOS certs documentados como N/A** (`docs/IOS_CERTS_NA.md`)
- [x] **Inventario GitHub Secrets completo** (`docs/GITHUB_SECRETS_INVENTORY.md`)
- [x] **2 Service Accounts backend** configurados en Railway + GitHub Secrets:
  - `BACKEND_FIREBASE_CLIENT_SERVICE_ACCOUNT`
  - `BACKEND_FIREBASE_PROVIDER_SERVICE_ACCOUNT`
- [x] **2 Service Accounts frontend** configurados:
  - `CLIENT_FIREBASE_SERVICE_ACCOUNT`
  - `PROVIDER_FIREBASE_SERVICE_ACCOUNT`
- [x] **28+ GitHub secrets** configurados (Railway, DNS, Backend SA, Observabilidad, VAPID, JWT_SECRET)
- [x] **Variables Railway 100% completas** (3 servicios, 0 vacías)
- [x] **JWT_SECRET** configurado en Railway + GitHub Secrets

**Autorización consumida:** `AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — GLOWAPP-F005`

**Evidencia:** `AUDITORIA_RAILWAY_2026-10-30.md` — 3 servicios Online, 0 variables vacías, `.env.glowapp-complete` consolidado

---

### FASE 6 — CI/CD + FIREBASE HOSTING + DNS 🟡 **EN PROGRESO (95%)**
**Entregables:**
- [x] **Workflow CI/CD Firebase Hosting** (`.github/workflows/glowapp-firebase-deploy.yml`):
  - Backend CI (tests, contrato, RLS)
  - Monorepo setup + analyze
  - Glow Client verify (test + build web con `--dart-define=APP_AUDIENCE=client`)
  - Glow Provider verify (test + build web con `--dart-define=APP_AUDIENCE=provider`)
  - **Deploy Client → Firebase Hosting** (`FirebaseExtended/action-hosting-deploy@v0` a `glowapp-client`, target `client`, channel `staging`/`live`)
  - **Deploy Provider → Firebase Hosting** (`FirebaseExtended/action-hosting-deploy@v0` a `glowapp-provider`, target `provider`, channel `staging`/`live`)
  - Pipeline dual: staging/main → Firebase preview channels
- [x] **Firebase Hosting configs** (`apps/glow_client/firebase.json`, `apps/glow_provider/firebase.json`): SPA rewrites, cache headers, cleanUrls
- [x] **Test deploy real staging** ✅ **VALIDADO**:
  - Client: `https://glowapp-client--staging-dxkv99y1.web.app` (200 OK)
  - Provider: `https://glowapp-provider--staging-srdlyu0q.web.app` (200 OK)
- [x] **Staging URLs operativas** — `.web.app` gratuitos listos para QA/E2E
- [ ] **Custom domains producción** (`app.glowapp.com`, `pro.glowapp.com`, `admin.glowapp.com`, `api.glowapp.com`) — **DIFERIDO** hasta compra de `glowapp.com` (razones de marca)
- [ ] **DNS A records en registrar** — Firebase provee IPs; se agregan cuando se compre el dominio
- [x] **Variables Railway** backend mantenidas (22/servicio ✅) — backend sigue en Railway
- [x] **Deploy backend a producción por CI** ✅ **VALIDADO (2026-11-01)**: push a `main` → job `Deploy Backend to Railway` success → deployment `01095a07` `● Online`, `/api/health` 200

**Autorización consumida:** `AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — GLOWAPP-F006-RAILWAY`

**Próximo:** solo custom domains (bloqueado por compra de `glowapp.com`). Fase 7 (Cloudflare Stream) queda pendiente de método de pago.

---

### FASE 7 — CLOUDFLARE STREAM 🟡 **EN PROGRESO (35%) — PARCIALMENTE BLOQUEADA (pago Cloudflare)**
**Entregables:**
- [x] **ClientGuide creado** (`packages/glow_core/lib/src/glowguide/config/client_guide.dart`) — 8 pasos cliente con `videoAssetId` local
- [x] **ProviderGuide existente** (`packages/glow_core/lib/src/glowguide/config/provider_guide.dart`) — 7 pasos proveedor
- [x] **video_mapping.dart poblad** con 30 URLs Firebase Storage (16 cliente MP4/WebM + 14 proveedor MP4/WebM) — **COMPLETADO**
- [x] **GlowGuidePresenter migrado** a `VideoPlayerController.networkUrl()` con detección automática MP4 (iOS/Safari) / WebM (Chrome/Android) — **COMPLETADO**
- [ ] **Subir 16 videos a Cloudflare Stream** (manual en dashboard Cloudflare) — **BLOQUEADO: tarjeta**
  - **Cliente (8):** step_01_welcome → step_08_despedida
  - **Proveedor (7):** step_01_inicio → step_07_perfil
  - **Onboarding intro** (1)
- [ ] **Poblar `video_mapping.dart`** con UIDs reales de Cloudflare Stream: `https://iframe.videodelivery.net/UID_XXX` (reemplazar URLs Firebase Storage)
- [x] **Eliminar assets videos locales** ✅ **COMPLETADO**:
  - `apps/glow_client/assets/videos/` (eliminado)
  - `apps/glow_provider/assets/videos/` (eliminado)
  - `backend/public/assets/assets/glowguide/videos/` (eliminado)
- [ ] **Actualizar `GlowGuidePresenter`** para usar iframe Player de Stream (HLS adaptativo)
- [ ] **Test onboarding reproducción en staging**

---

### 📋 TRABAJO TEMPORAL — FIREBASE STORAGE ✅ **COMPLETADO**
**Objetivo:** Quitar ~33 MB del build y servir videos desde Firebase Storage (compatibilidad universal MP4 + WebM) — **HECHO**

**Ejecutado:**
1. **Videos subidos a Firebase Storage** en ambos proyectos (`glowapp-client`, `glowapp-provider`) con estructura:
   - `step_01_welcome.mp4/.webm` ... `step_08_despedida.mp4/.webm` (cliente, raíz del bucket)
   - `step_01_inicio.mp4/.webm` ... `step_07_perfil.mp4/.webm` (proveedor, raíz del bucket)
2. **`video_mapping.dart` actualizado** con 30 URLs `mediaLink` firmadas (generation token) — listo para producción
3. **`GlowGuidePresenter` ya usa** `VideoPlayerController.networkUrl()` con detección de formato por user-agent (Safari → MP4, resto → WebM)
4. **Eliminación de assets locales** ✅ **COMPLETADA** — 22 archivos borrados del repo (~33 MB)

**Evidencia:** `packages/glow_core/lib/src/glowguide/config/video_mapping.dart` (30 URLs pobladas), `flutter analyze` clean en `glowguide/`, commit `abaa1421`

---

### FASE 8 — CLEANUP & DOCS ✅ **COMPLETADA (100%)**
**Entregables:**
- [x] Archivar `frontend/` (monolito original) → `frontend-archive/` ✅ **COMPLETADO** (309 MB)
- [x] Documentación final ✅ **COMPLETADA**:
  - `docs/SPLIT_ARCHITECTURE_FINAL.md` — arquitectura completa split client/provider
  - `docs/DEPLOY_RUNBOOK.md` — procedimientos deploy staging/prod, rollback, secrets
  - `docs/VIDEO_MAPPING_REGISTRY.md` — registro 30 URLs Firebase + migración Cloudflare
- [x] **Esquema de BD reproducible en contenedor** ✅ **COMPLETADO (2026-11-01)** — ver bloque siguiente
- [x] **RLS estructural verificado en staging y producción** ✅ (37/37 tablas con FORCE y política)
- [x] **Postgres legacy apagado** en ambos entornos, con respaldo de sus 9 filas (`.backups/`)
- [x] **Verificación RLS multi-tenant con tenants reales** ✅ **COMPLETADA (2026-11-01)**: `verifyTenantIsolation.js` exit 0 — 12 tablas con RLS+FORCE+política, fixture con dueño y 2 inquilinos, lectura cruzada 0 filas, escritura ajena rechazada (42501→403), trigger rellena `tenant_id`, PII aislada
- [x] **CI en verde en los dos jobs de backend** ✅ **COMPLETADO (2026-11-01)**: `Monorepo Setup & Analyze` y `Backend Tests & Lint` en `success` (runs `41281016747` y `41283534179`)
- [x] **Limpieza de branches** ✅ **COMPLETADO**: 2 remotas y 13 locales sin commits fuera de `main` borradas, con tag `archive/*-20261101`
- [x] **Drift de esquema staging ↔ producción** ✅ **RESUELTO (2026-11-01)**: clonado el esquema de producción hacia staging (`pg_dump --schema-only --no-owner --no-privileges`, restore con `ON_ERROR_STOP`, `prepareRlsDatabase.js` posterior). Resultado **122 = 122**, `comm` vacío en ambas direcciones, RLS 37/37, ambas APIs 200. Respaldo previo en `.backups/staging_pre_drift_20261101.sql`
- [x] **Redis de staging con credencial caducada** ✅ **CORREGIDO**: `WRONGPASS` en `AUTH` → el middleware `auth.js` (fail-closed) devolvía 503 en todo `/api`. `REDIS_URL` pasó de copia literal a referencia `${{Redis.REDIS_URL}}`
- [x] **Incidente de imagen en staging y recuperación** ✅ **RESUELTO (2026-11-01)**: el servicio se cambió a `pgvector/pgvector:pg16`, que no trae PostGIS y dejó la base vacía (0 tablas). Al volver a `postgis/postgis:16-3.4` el contenedor abortaba con `initdb: directory exists but is not empty` (el volumen rescatable era un clúster de **PostgreSQL 18**, incompatible, y la raíz del montaje tiene `lost+found`). Solución: volumen nuevo `postgres-postgis-volume`, `PGDATA=/var/lib/postgresql/data/pgdata`, restore del dump y `prepareRlsDatabase.js`. Resultado: 122 tablas, RLS 37/37, ambas APIs 200. **Regla: no cambiar la imagen a `pgvector` sola; haría falta una imagen con PostGIS + pgvector.**
- [x] **E2E smoke tests** ✅ **COMPLETADO (2026-11-01)**: **25/25, cero fallos** — login cliente y prestador, contrato (GET 200, aceptación y persistencia), reserva con split 20/0/80, propina (rechazo/aceptación/duplicado), reprogramación (200 → 409, contador), cancelación 100 %/50 %/0 %, umbrales D-GL-011, envío Bogotá/Cali (con y sin cobro), IVA incluido (base 75630 + iva 14370 = 100200), retención de 1.000 y estado de cuenta del prestador (bloque I). Desbloqueado con la migración **`121_scan_product_matches.sql`** (DDL de 029 sin `pgvector`) + `071 → 072 → 103`
- [!] **Deuda abierta**: staging quedó con **126 tablas** y producción con **122**. La diferencia son las 4 tablas de precios/tienda que solo se aplicaron en staging (`scan_product_matches`, `listas_precios`, `precios_historial`, `precios_producto`). Llevarlas a producción exige decisión del Director: es cambio de esquema en prod. Mientras no se haga, un E2E contra producción fallaría el bloque G

#### Trabajo ejecutado 2026-11-01 — cadena de fallos del backend

Cinco causas encadenadas mantenían `glowapp-api` caída y sin esquema:

| # | Causa | Fix |
|---|-------|-----|
| 1 | `.railwayignore` excluía `*.sql` → la imagen se construía sin `migrations/` ni `init.sql` | Exclusión eliminada; el build ya sube 128 archivos SQL |
| 2 | SQL embebido como constantes JS; `058_enable_rls_policies.sql` evaluaba a `NaN` | `prepareRlsDatabase.js` lee migraciones desde disco |
| 3 | Imagen `postgres-ssl` de Railway sin PostGIS | Servicios `postgres-postgis` (staging) y `postgres-postgis-prod` con `postgis/postgis:16-3.4` |
| 4 | `068` forzaba RLS sobre lista fija; `api_keys`, `invoices`, `subscriptions`, `usage_metrics` quedaban sin política → crash loop | Migración `120` genérica, type-aware (INTEGER/VARCHAR), sin pisar políticas de `062` |
| 5 | `frontend-archive/` (309 MB) no excluido del upload → `railway up` timeout | Excluido en `.railwayignore` |

**Evidencia verificada (E1):**

| Métrica | Producción | Staging |
|---|---|---|
| `/api/health` | 200 · `pgAvailable: true` | 200 |
| `/api/providers` (X-App-Audience: client) | 200 | 200 |
| PostGIS | 3.4.3 | 3.4.3 |
| Tablas | 122 | 107 |
| Roles RLS | `app_owner`, `app_rls_user`, `app_system` | ídem |
| Tablas con `tenant_id` con FORCE + política | 37/37 · 0 sin política | 30/30 |

**PRs fusionados:** #91 (migraciones desde disco + `.railwayignore`), #93 (migración `120`).

**Deuda conocida:** la base de producción se recreó vacía; el Postgres legacy (80 tablas, 1 usuario semilla, 8 productos) quedó **Offline** con respaldo en `.backups/legacy_*.json`, sin migrar.

**Autorización consumida:** `AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — GLOWAPP-F008`

---

### FASE 9 — OBSERVABILIDAD ✅ 95% COMPLETADA (TRACK PARALELO INTEGRADO)
**Entregables:**
- [x] **OpenTelemetry instrumentation** (`backend/src/instrumentation.ts`)
  - OTLP trace exporter → Tempo
  - Prometheus metric reader → `/metrics`
  - Resource attributes: `service.name=glowapp-backend`, `deployment.environment`, `cloud.provider=railway`
- [x] **Métricas Prometheus custom** (`backend/src/metrics.ts`) — 20+ métricas:
  - HTTP: `http_requests_total`, `http_request_duration_seconds`, `http_request_size_bytes`, `http_response_size_bytes`, `active_connections`
  - DB: `db_pool_*`, `db_query_duration_seconds`
  - Business: `reservas_*`, `proveedores_*`, `usuarios_*`
  - Cache: `cache_*`, Queue: `queue_*`
- [x] **Docker Compose stack** (`monitoring/docker-compose.yml`):
  - Loki + Promtail (logs)
  - Prometheus + Alertmanager (métricas/alertas)
  - Tempo (trazas)
  - Grafana (visualización)
- [x] **Configs**: `loki-config.yaml`, `promtail-config.yaml`, `prometheus.yml`, `alertmanager.yml`, `alerts.yml`, `tempo-config.yaml`, `grafana.ini`
- [x] **Dashboard** "GlowApp - System Health" (`monitoring/grafana/dashboards/system-health.json`) — 13 panels, golden signals
- [x] **Script provisioning Grafana Cloud** (`scripts/provision-grafana-cloud.js`):
  - 3 DataSources (Prometheus, Loki, Tempo) con cross-links
  - Dashboard System Health
  - 4 Alert Rules: HighErrorRate, HighLatency, DBPoolExhausted, HostingDown
  - Test alert firing
- [x] **Deploy a producción** (Grafana Cloud) — **OPERATIVO**
  - Stack: `heartylantern154`
  - DataSources: OK
  - Dashboard: OK
  - Alert Rules: OK
- [x] **Runbook** (`docs/runbooks/incident-response.md`) — 5 incidentes documentados
- [x] **Guía setup** (`docs/GRAFANA_CLOUD_SETUP.md`)

**PENDIENTE (5%):**
- [ ] Validación automática Loki readiness (endpoint `/ready` 404 en Grafana Cloud — datasource funciona)
- [ ] Alert notification channels (Slack/PagerDuty webhook) — preparado, pendiente URL

**Autorización consumida:** `AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — GLOWAPP-F006` (re-etiquetada como `F009-OBS` en este plan unificado)

**Evidencia:** Run #40816744890 exitoso, Grafana Cloud `heartylantern154.grafana.net` operativo

---

## MATRIZ DE TRAZABILIDAD (PLAN ORIGINAL vs UNIFICADO)

| Plan Original (split-architecture-v2.md) | Plan Unificado | Estado |
|------------------------------------------|----------------|--------|
| Fase 0 | Fase 0 | ✅ |
| Fase 1 | Fase 1 | ✅ |
| Fase 2 | Fase 2 | ✅ |
| Fase 3 | Fase 3 | ✅ |
|| Fase 4 | Fase 4 | ✅ 100% ||
| Fase 5 | Fase 5 | ✅ 100% ||
| Fase 6 (CI/CD Railway) | Fase 6 | 🟡 95% (backend staging + producción ✅; custom domains pendientes) |
| Fase 7 (Cloudflare Stream) | Fase 7 | 🟡 45% (Firebase Storage ✅, Cloudflare bloqueado por pago) |
| Fase 8 (Cleanup) | Fase 8 | ✅ 100% (docs, infra BD/RLS, CI, branches y E2E 25/25) |
| — (no existía) | **Fase 9 (Observabilidad)** | ✅ 95% |

---

## PRÓXIMAS AUTORIZACIONES EN ORDEN SECUENCIAL

**Consumidas:** F004-BACKEND ✅ · F005 ✅ · F006-RAILWAY ✅ · F007 ✅ (parcial, bloqueada por pago Cloudflare) · F008 ✅ (en curso)

```bash
# 1. Cerrar Fase 8: E2E smoke tests + RLS con tenants reales + limpieza de branches
AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — GLOWAPP-F008   # ya otorgada, trabajo restante

# 2. Fase 7 restante (requiere tarjeta en Cloudflare)
AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — GLOWAPP-F007
```

**Fase 5 (Firebase & Deploy Ops) completada — autorización F005 consumida.**  
**Fase 9 (Observabilidad) ya completada — no requiere autorización adicional.**

### Bloqueos externos (no dependen de código)

| Bloqueo | Fase afectada | Desbloqueo |
|---|---|---|
| Dominio `glowapp.com` no comprado | Fase 6 (custom domains) | Compra del dominio |
| Tarjeta en Cloudflare | Fase 7 (Stream / HLS) | Método de pago |
| Sin Apple Developer Program | Fase 5 (certs iOS) | Suscripción Apple |

---

## CRITERIOS DE CUMPLIMIENTO POR FASE (PARA AUDITORÍA)

| Fase | Criterio "Done" Verificable |
|------|----------------------------|
| 0 | `melos bootstrap` OK, `glow_core` analiza sin errores |
| 1 | 10 módulos en `glow_core/src/`, imports resueltos, analyze clean |
| 2 | `apps/glow_client` build web OK, 31 screens, routes cliente only |
| 3 | `apps/glow_provider` build web OK, 13 screen groups, academy completa |
| 4 | appAudience global, JWT aud claim, 47/47 contract tests PASS |
| 5 | 2 SA backend, 28 secrets, 2 VAPID provider, FCM con roles[] en staging, Railway 100% vars |
| 6 | 2 servicios Railway live, DNS resuelve, nginx por servicio, deploy dual OK |
| 7 | 16 videos en Stream, `video_mapping.dart` poblado, 0 assets videos locales |
| 8 | `frontend/` archivado/eliminado, docs finales, e2e smoke tests PASS |
| 9 | Grafana Cloud: 3 datasources OK, dashboard OK, 4 alerts OK, runbook existe |

---

## ARCHIVOS DE REFERENCIA (EN REPO)

| Archivo | Propósito |
|---------|-----------|
| `AUDIT_EXHAUSTIVO_2026-10-29.md` | Auditoría exhaustiva previa (este documento la reemplaza como baseline) |
| `glowapp-split-architecture-v2.md` | Plan original fases 0-8 |
| `.github/workflows/glowapp-build-deploy.yml` | CI/CD actual (Firebase) — migrar en Fase 6 |
| `.github/workflows/observability-deploy.yml` | CI/CD observabilidad (Fase 9) |
| `scripts/provision-grafana-cloud.js` | Provisioning automatizado Fase 9 |
| `docs/runbooks/incident-response.md` | Runbooks Fase 9 |

---

## GOBERNANZA

- **Una sola ruta** — este documento es la fuente de verdad única
- **Una autorización por fase** — formato exacto `AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — GLOWAPP-F<NN>-<SUFIJO>`
- **No desviaciones** — todo trabajo fuera de fase requiere autorización explícita nueva
- **Auditoría fase a fase** — cada autorización cierra una fase, se verifica criterio "Done", luego siguiente

---

**Baseline establecido. Próxima fase sujeta a autorización.**

---

## AUDITORÍA DEL FALTANTE — MONOLITO vs SPLIT (2026-11-01)

Comparación de `frontend-archive/lib` (201 archivos `.dart`) contra las tres raíces del split
(`glow_core` 209, `glow_client` 54, `glow_provider` 68), por nombre, hash byte a byte y tamaño.

| Métrica | Valor |
|---|---|
| Con contraparte en el split | **187/201 (93 %)** — 94 idénticos, 93 reescritos, 0 stubs |
| Sin contraparte | **14 archivos / 4.416 líneas** |

### Faltante y veredicto

| Pieza | Líneas | Veredicto | Estado |
|---|---|---|---|
| `l10n.yaml` + `app_en.arb` + `app_es.arb` | — | Migrar | ✅ **HECHO** — restaurados en `glow_core`; `flutter gen-l10n` exit 0 |
| `design/icons.dart` (barrel) | 20 | Migrar | ✅ **HECHO** — barrel creado en `glow_core/lib/src/design/icons/icons.dart` |
| `photography_repository` | 34 | Descartar | Código huérfano en el original (cero usos) |
| `glow_welcome_guide` | 229 | Descartar | Sustituido por `client_guide` + `provider_guide`; sin referencias |
| `inventario_screen` | 609 | Migrar + adaptar | ✅ **HECHO** — en `apps/glow_provider`, compila limpio |
| `alquileres_screen` | 481 | Migrar + adaptar | ✅ **HECHO** — en `apps/glow_provider`, compila limpio |
| `salon_dashboard_screen` | 1.230 | Reconstruir | Pendiente (fase 3) |
| `evolution_dashboard_screen` | 575 | Decidir alcance | Pendiente (fase 0) |
| Superadmin (5 screens + providers) | 1.352 | Reconstruir en `admin-dashboard` | Pendiente (fase 4) |
| RAG de Aura (`beauty_knowledge_embeddings`) | — | Infra | ✅ **Validado en local**: esquema completo aplicado sobre la imagen nueva (8/8 migraciones, `halfvec(2048)`, HNSW). Pendiente: registry + swap |

### Fases del plan

| Fase | Contenido | Estado |
|---|---|---|
| 1 | l10n, iconos, descartes justificados | ✅ **COMPLETADA** |
| 2 | Inventario y alquileres al provider, expuestos en el tab «Más» | ✅ **COMPLETADA** |
| 3 | Reconstruir dashboard de salón sobre `memberships` | ⏳ Pendiente |
| 4 | Superadmin en `admin-dashboard` (Next.js) | ⏳ Pendiente |
| 5 | Imagen PostGIS + pgvector, `031` y `migrations/rag/*` | 🟡 **Imagen construida y validada end-to-end en local**: restore del esquema de producción (122 tablas), extensiones idénticas, `030` → `031` → **8/8** migraciones RAG, columna `halfvec(2048)` e índice HNSW. Falta **publicar en un registry** y hacer el swap del servicio |

### Hallazgo del backend

Inventario y alquileres **sí tenían API**: `GET/POST /api/salon/:salonId/inventario`,
`/inventario/:itemId/movimientos`, `/recursos` y `/alquileres` existen en `salonRoutes.js`
y las tablas están en el esquema. Solo faltaba la UI, que es lo que se migró en fase 2.
