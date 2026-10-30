# GLOWAPP — PLAN DE TRABAJO UNIFICADO (BASELINE AUDITABLE)
**Versión:** 1.0 — 2026-10-29  
**Propósito:** Unificar plan split-architecture + observabilidad en una sola ruta auditable fase a fase  
**Estado:** Baseline consolidado — sin desviaciones a partir de esta versión

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
|| **6** | **CI/CD + Firebase Hosting + DNS** | Pipeline dual, Firebase Hosting `glowapp-client`/`glowapp-provider`, backend Railway, DNS custom domains | 🟡 **90%** (Firebase deploy staging ✅, custom domains diferidos) | `GLOWAPP-F006-RAILWAY` |
| **7** | **Cloudflare Stream** | Subir 16 videos, poblar `video_mapping.dart`, eliminar assets locales | ❌ **0%** | `GLOWAPP-F007` |
| **8** | **Cleanup & Docs** | Archivar `frontend/`, docs finales, e2e smoke tests | ❌ **0%** | `GLOWAPP-F008` |
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

### FASE 6 — CI/CD + FIREBASE HOSTING + DNS 🟡 **EN PROGRESO (90%)**
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

**Autorización consumida:** `AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — GLOWAPP-F006-RAILWAY`

**Próximo:** Fase 7 (Cloudflare Stream videos) — requiere `AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — GLOWAPP-F007`

---

### FASE 7 — CLOUDFLARE STREAM ❌ 0% (NO INICIADA)
**Entregables:**
- [ ] Subir 16 videos a Cloudflare Stream:
  - **Cliente (8):** step_01_welcome → step_08_despedida
  - **Proveedor (7):** step_01_inicio → step_07_perfil
  - **Onboarding intro** (1)
- [ ] Poblar `packages/glow_core/lib/src/glowguide/config/video_mapping.dart` con UIDs reales
- [ ] Eliminar assets videos locales:
  - `apps/glow_client/assets/videos/`
  - `apps/glow_provider/assets/videos/`
  - `backend/public/assets/assets/glowguide/videos/`
- [ ] Actualizar `GlowGuidePresenter` para usar iframe Player de Stream (HLS adaptativo)
- [ ] Test onboarding reproducción en staging

**Impacto:** -33 MB/build (gzipped ~6-8 MB client, ~8-10 MB provider)

**Autorización:** `AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — GLOWAPP-F007`

---

### FASE 8 — CLEANUP & DOCS ❌ 0% (NO INICIADA)
**Entregables:**
- [ ] Archivar `frontend/` (monolito original) → `frontend-archive/` o eliminar
- [ ] Documentación final:
  - `docs/SPLIT_ARCHITECTURE_FINAL.md`
  - `docs/DEPLOY_RUNBOOK.md`
  - `docs/VIDEO_MAPPING_REGISTRY.md`
- [ ] E2E smoke tests: login → mapa → reserva → pago → chat (ambas apps)
- [ ] Verificación RLS multi-tenant en staging con usuarios reales
- [ ] Limpieza branches feature antiguas (`feat/e02-*`, `feat/e03-*`, etc.)

**Autorización:** `AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — GLOWAPP-F008`

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
| Fase 6 (CI/CD Railway) | Fase 6 | ❌ 0% |
| Fase 7 (Cloudflare Stream) | Fase 7 | ❌ 0% |
| Fase 8 (Cleanup) | Fase 8 | ❌ 0% |
| — (no existía) | **Fase 9 (Observabilidad)** | ✅ 95% |

---

## PRÓXIMAS AUTORIZACIONES EN ORDEN SECUENCIAL

```bash
# 1. Completar backend audience scoping (15% restante)
AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — GLOWAPP-F004-BACKEND

# 2. CI/CD Railway + DNS (nueva - 0%)
AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — GLOWAPP-F006-RAILWAY

# 3. Cloudflare Stream videos (0%)
AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — GLOWAPP-F007

# 4. Cleanup + docs (0%)
AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — GLOWAPP-F008
```

**Fase 5 (Firebase & Deploy Ops) completada — autorización F005 consumida.**  
**Fase 9 (Observabilidad) ya completada — no requiere autorización adicional.**

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