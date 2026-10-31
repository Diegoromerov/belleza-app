# GlowApp — Arquitectura Split Final (Client / Provider)

**Versión:** 1.0 — 2026-10-31  
**Estado:** Producción-ready (backend Railway, frontend Firebase Hosting staging validado)

---

## 1. Visión General

Monorepo Flutter + Node.js backend separado por audiencia:

```
belleza-app-audit/
├── packages/glow_core/          # Shared package (100% migración completa)
├── apps/glow_client/            # App usuarios finales (client)
├── apps/glow_provider/          # App prestadores/salones (provider)
├── backend/                     # API única (Node.js/Express + PostgreSQL)
├── monitoring/                  # Observabilidad stack (Grafana Cloud)
└── docs/                        # Documentación
```

---

## 2. Arquitectura de Audiencias

| Lado | App | Dominio | Audiencia JWT (`aud`) | Header Requerido | Backend Scope |
|------|-----|---------|----------------------|------------------|---------------|
| **USUARIOS** | `glow_client` | `app.glowapp.com` | `client` | `X-App-Audience: client` | RLS `role=CLIENTE` |
| **PRESTADORES** | `glow_provider` | `pro.glowapp.com` | `provider` / `salon` | `X-App-Audience: provider` | RLS `role=PRESTADOR/SALON` |
| **ADMIN** | `admin-dashboard` | `admin.glowapp.com` | `admin` | `X-App-Audience: admin` | RLS `role=ADMIN` |

**Middleware crítico:** `validateAppAudience` (global en `/api/*`) + `requireAnyRole` (guards por endpoint)

---

## 3. Monorepo — packages/glow_core

**Módulos compartidos (10 módulos migrados):**

```
packages/glow_core/lib/src/
├── services/           # api, auth, fcm, storage, analytics
├── models/             # provider, service, business_profile, glow_product, saas, superadmin
├── design/             # components, icons, tokens
├── core/               # theme, photography
├── shared/             # theme, tokens, calculations, currency, onboarding_helper
├── widgets/            # genéricos + owner/ + profile/
├── utils/              # json_num
├── data/               # colombia_municipalities
├── l10n/               # localizaciones (es/CO)
└── glowguide/          # Motor onboarding completo
    ├── engine/         # GlowGuideEngine, estado, persistencia
    ├── presenter/      # GlowGuidePresenter, GlowStepVideoPlayer
    ├── config/         # ClientGuide, ProviderGuide, video_mapping.dart
    ├── model/          # GlowGuideStep, AuraContent
    ├── state/          # GlowGuideState, GlowGuideStatus
    └── utils/          # helpers
```

**Dependencias clave:** `flutter_riverpod`, `firebase_core/messaging`, `video_player`, `go_router`, `google_sign_in`, `flutter_map`

---

## 4. Backend — API Unificada

**Stack:** Node.js 20 + Express + PostgreSQL (Railway) + Redis + Firebase Admin SDK

**Estructura:**
```
backend/
├── src/
│   ├── index.js                    # Entry point + instrumentation OTel
│   ├── instrumentation.ts          # OpenTelemetry SDK init
│   ├── metrics.ts                  # 20+ métricas Prometheus custom
│   ├── middleware/
│   │   ├── appAudience.js          # validateAppAudience (X-App-Audience)
│   │   ├── requireAnyRole.js       # Guards por rol
│   │   └── auth.js                 # JWT verification + audience claim
│   ├── controllers/
│   │   └── authController.js       # login/oauth/switchContext → JWT con `aud` claim + FCM roles[]
│   ├── config/
│   │   └── jwt.js                  # JWT_SECRET validation (≥32 chars prod)
│   ├── routes/                     # Modular: auth, providers, services, bookings, wallet, academy, chat, disputes, support, admin
│   ├── services/                   # fcmNotification, pushNotification, email, storage
│   └── tests/contract/             # 47 tests: audience-binding (17), openapi (8), critical-endpoints (15), routersMontados (7)
├── Dockerfile                      # Multi-stage production
└── package.json
```

**Autenticación:**
- Login único → JWT con `roles[]` array + `audience` claim (`aud`)
- `switchContext` permite cambiar rol sin re-login (emite nuevo JWT)
- FCM token se guarda con `roles[]` del usuario autenticado

**Observabilidad:**
- OpenTelemetry → OTLP traces a Tempo (Grafana Cloud)
- Prometheus metrics en `/metrics` + custom business metrics
- Logs estructurados → Loki
- Dashboards: System Health (golden signals), DB Pool, Business, Traces
- Alertas: HighErrorRate, HighLatency, DBPoolExhausted, HostingDown

---

## 5. Frontend — Apps Split

### glow_client (Usuario Final)
- **Pantallas:** 31 archivos en `lib/screens/` (providers, booking, tracking, profile, auth, store, chat, disputes, support, ideas, designs)
- **Routing:** GoRouter con `APP_AUDIENCE=client`
- **Firebase:** `glowapp-client` (634593218804)
- **Build:** `flutter build web --release --dart-define=APP_AUDIENCE=client`

### glow_provider (Prestador/Salón)
- **Pantallas:** 13 grupos (provider dashboard/services/portfolio, salon hub, owner, saas, superadmin, wallet, auth, academy, chat, disputes, support)
- **Academy completa:** Hub, course_detail, quiz, nback, colorimetría, glass_card, glow_beauty, consent_widget
- **Routing:** GoRouter con `APP_AUDIENCE=provider`
- **Firebase:** `glowapp-provider` (509840252897)

---

## 6. Despliegue — Firebase Hosting + Railway

### Frontend (Firebase Hosting)
| App | Proyecto Firebase | Staging URL | Production URL (pendiente DNS) |
|-----|------------------|-------------|-------------------------------|
| Client | `glowapp-client` | `https://glowapp-client--staging-dxkv99y1.web.app` | `https://app.glowapp.com` |
| Provider | `glowapp-provider` | `https://glowapp-provider--staging-srdlyu0q.web.app` | `https://pro.glowapp.com` |

**Config:** `firebase.json` con SPA rewrites, cache headers, cleanUrls, preview channels (staging/live)

### Backend (Railway)
- **Proyecto:** `glowapp` (ID: `a6f51ac4-aac5-4cd6-915e-f87e9da05f2a`)
- **Servicio:** `glowapp-api` → `https://glowapp-api-production.up.railway.app`
- **DB:** PostgreSQL `postgres-4a1e` (interno `postgres.railway.internal:5432`)
- **Redis:** Interno `redis.railway.internal:6379`
- **Variables:** 22 configuradas (APP_AUDIENCE=admin, JWT_SECRET, DATABASE_URL, REDIS_URL, 2x Firebase Service Accounts, 2x VAPID Keys, etc.)

### CI/CD (`.github/workflows/glowapp-firebase-deploy.yml`)
- Dual pipeline: jobs independientes `deploy-client-*` / `deploy-provider-*`
- Trigger: push a `staging` → preview channel `staging`; push a `main` → channel `live`
- Backend: `glowapp-build-deploy.yml` (tests, lint, deploy Railway)

---

## 7. Videos Onboarding — Firebase Storage (Temporal) → Cloudflare Stream (Futuro)

**Estado actual:** 30 URLs en `video_mapping.dart` (MP4 + WebM por step)

| Audiencia | Steps | Formatos | Ubicación |
|-----------|-------|----------|-----------|
| Client | 8 (welcome → despedida) | MP4 + WebM | `gs://glowapp-client.firebasestorage.app/*` |
| Provider | 7 (inicio → perfil) | MP4 + WebM | `gs://glowapp-provider.firebasestorage.app/*` |

**Presenter:** `GlowStepVideoPlayer` usa `VideoPlayerController.networkUrl()` con detección:
- iOS/Safari/Mac → MP4 (H.264)
- Chrome/Android/Web → WebM (VP8/VP9)

**Futuro (Cloudflare Stream):** Reemplazar URLs por iframe HLS adaptativo `https://iframe.videodelivery.net/UID_XXX` — **bloqueado por pago**

---

## 8. Firebase Projects

| Proyecto | Project ID | Número | Uso |
|----------|-----------|--------|-----|
| glowapp-client | `glowapp-client` | 634593218804 | Auth, FCM, Storage, Hosting (client) |
| glowapp-provider | `glowapp-provider` | 509840252897 | Auth, FCM, Storage, Hosting (provider) |

**Service Accounts (5 totales):**
- Backend: `firebase-adminsdk-fbsvc@glowapp-client.iam.gserviceaccount.com` + `glowapp-provider`
- Frontend: Service Accounts separados con `private_key_id` distintos

**FCM VAPID Keys:**
- Client: `BPesRggflU9ZV1O0hRwynJoXNEvF3eXUVvhtWZDRoGUOob8dsD-4XS6oX2FIszHQOiRJN8IewGtO4syKTkd3m7s`
- Provider: `BKJVD0PXlUulswEAGWKxRB8XThAJ1DfPmCdDkYllaWA5qVgVSow1io30UHrUQn1wKPoLAioc5-Lu8MY4EOOD3H0`

---

## 9. Android Build

| App | Package | Keystore | Alias | Status |
|-----|---------|----------|-------|--------|
| Client | `com.glowapp.client` | `glow_client_key` | `glowclient` | ✅ Generado |
| Provider | `com.glowapp.provider` | `glow_provider_key` | `glowprovider` | ✅ Generado |

**iOS:** No disponible (sin Apple Developer Program) — solo web + Android

---

## 10. GitHub Secrets (47 configurados)

Categorías:
- Firebase configs (14: 7 client + 7 provider)
- Grafana Cloud (6)
- JWT_SECRET, keystores (4)
- Email SMTP (3)
- Service Accounts (5)
- VAPID Keys (2)
- Railway (4 service names + PROJECT_ID + TOKEN)
- DB/Redis/Seed (3)

---

## 11. Branches Strategy

| Branch | Propósito |
|--------|-----------|
| `main` | Producción (protected, ff-only merges via PR) |
| `staging` | Validación pre-prod (Firebase preview channels) |
| `feat/split-client-provider-apps` | Split architecture Fases 0-3 (merged a main) |
| `fix-observability-workflow` | Fase 6-7 CI/CD fixes + video migration (actual) |

---

## 12. Decisiones Clave Registradas

| ID | Decisión |
|----|----------|
| D-GL-027 | Frontend → Firebase Hosting (no Railway + Cloudflare) |
| D-GL-028 | Video strategy: Firebase Storage inmediato (MP4+WebM) → Cloudflare Stream futuro (HLS) |
| D-GL-029 | Monorepo melos + pnpm, shared package `glow_core` |
| D-GL-030 | Auth: login único, JWT `roles[]` + `aud` claim, header `X-App-Audience` |

---

## 13. Próximos Pasos (Post-Fase 8)

1. **Fase 7 completitud:** Cloudflare Stream (requiere pago) → HLS adaptativo
2. **Fase 9:** Observabilidad 100% (runbooks finales, SLO dashboards)
3. **Producción:** DNS custom domains (`app.glowapp.com`, `pro.glowapp.com`, `api.glowapp.com`)
4. **iOS:** Apple Developer Program → certs + TestFlight → App Store

---

*Generado automáticamente como parte de Fase 8 — Cleanup & Docs*