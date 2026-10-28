# GlowApp — Separación en Dos Apps (Cliente / Proveedor)
## Documento Exportable: Arquitectura, Fases 0–4 y Estado Actual
*Versión: 2026-10-27 | Rama: `feat/split-client-provider-apps` | Commit base: `edfb20c0`*

---

## 1. Resumen No Técnico (Visión General)

### El Problema
GlowApp era una **única aplicación Flutter monolítica** (`frontend/`) que servía a dos audiencias muy distintas:
- **Clientes finales** — reservan servicios, compran productos, usan Glow IA+, ven contenido Academy
- **Proveedores/Salones** — gestionan agenda, servicios, negocio, SaaS (facturación, equipo, API keys), wallet, caja

Esto generaba:
- Código mezclado (lógica de cliente y proveedor en mismos archivos)
- Build innecesariamente grande (cada app cargaba código del otro)
- Dificultad para deploy independiente, testing y escalado
- Un solo `google-services.json` / proyecto Firebase para ambos

### La Solución: Split en Dos Apps Publicables
Separar el monolito en **tres paquetes** dentro de un **monorepo**:
| Paquete | Propósito | Público |
|---------|-----------|---------|
| `packages/glow_core` | Capa compartida: modelos, servicios, tema, widgets genéricos, GlowGuide engine, SAAS providers | Interno (dependency) |
| `apps/glow_client` | App **cliente final** (app.glowapp.com) | Play Store / App Store / Web |
| `apps/glow_provider` | App **proveedor/salón** (app.glowapp.com/provider) | Play Store / App Store / Web |

**Backend único** (`api.glowapp.com`) con **audience scoping**:
- Un login → JWT con `roles[]`
- Cada app envía header `X-App-Audience: client|provider`
- Middleware `requireAnyRole` + RLS por `roles[]`

### Beneficios Clave
- ✅ **Builds independientes** — cada app solo compila su código
- ✅ **Deploys separados** — actualizar cliente no toca proveedor
- ✅ **Firebase aislado** — dos proyectos (`glowapp-client`, `glowapp-provider`)
- ✅ **Equipos paralelos** — frontend client y provider trabajan sin conflictos
- ✅ **Testing enfocado** — tests unitarios por app, integración compartida en core

---

## 2. Arquitectura Técnica (Decisiones Clave)

### 2.1 Monorepo Tooling (Fase 0)
- **Melos** para gestión de workspace Flutter + Dart
- **pnpm** para scripts de nodo (CI/CD, utilidades)
- Estructura:
```
belleza-app-audit/
├── melos.yaml              # Scripts: bootstrap, analyze, test, build:client, build:provider
├── pnpm-workspace.yaml     # Workspace npm
├── packages/
│   └── glow_core/          # Paquete compartido (publicable)
└── apps/
    ├── glow_client/        # App cliente
    └── glow_provider/      # App proveedor
```

### 2.2 Capa Compartida — `glow_core` (Fase 1)
**10 módulos extraídos del monolito** (103 archivos, ~24k LOC):
| Módulo | Contenido |
|--------|-----------|
| `services/` | 32 servicios: api, auth, fcm, analytics, booking_recovery, saas_api, superadmin_api, business_api, connectivity, crash_reporting, notification, web_geolocation, audio_player, location, permission_rationale, secure_storage, social_share, support, dispute, reply_reconcile |
| `models/` | 15 modelos: provider, service, biometric_result, glow_cycle, glow_product, business_profile, owner_dashboard_metrics, saas_models, superadmin_models |
| `design/` | Componentes luxe, iconos (5 archivos), gradientes, tokens |
| `core/theme/` | AppTheme moderno + BellezaLuxeTheme + Tokens |
| `shared/` | glow_tokens, mens_theme, theme (legacy), calculations, currency_formatter, glow_store_tokens, onboarding_helper, background_video_player, app_tokens |
| `widgets/` | 18 genéricos + owner (cross_tenant_warning_banner) + profile (colombian_address_builder, delivery_addresses_section, luxe_list_tile, profile_header) |
| `glowguide/` | Motor **solo** (engine, contracts, audio, persistence, observer, presenter, state, model, utils, service) — **config por app** |
| `utils/` | json_num |
| `data/` | colombia_municipalities |
| `l10n/` | app_localizations (es/en) |
| `providers/` | **saas_providers** (8 Riverpod providers: businessProfile, team, billing, usage, apiKeys, plans, currentBusinessProfileId, hasBusinessProfile) |

**Patrón de exports**: `lib/` contiene **re-exports** (`export '../src/...'`) → apps importan `package:glow_core/...` limpio.

**Compatibilidad theme**: `AppTheme` expone getters deprecated (`nude50-900`, `premiumGradient`, `error/errorBg`, `spacing*`, `textSecondary/tertiary/divider`) para migración gradual sin romper pantallas legacy. `MensTheme` añade 8 colores semánticos.

### 2.3 App Cliente — `glow_client` (Fase 2)
- **32 pantallas** copiadas del monolito: auth (8), core (providers, bookings, chat, store, disputes, support, profile), ideas (10), perfil (8)
- **10 widgets** propios: audience_toggle, app_update_gate + ideas widgets
- **main.dart**: rutas estáticas + `onGenerateRoute` para pantallas con parámetros (ChatScreen, TicketChatScreen, BiometricHistoryScreen, EvolutionScreen, GlowstoreRecipeScreen, MakeupLookbookScreen, NailVtoScreen)
- **Stubs en core**: `BookingScreen`, `ProviderDetailScreen` (API compartida)
- **Tema**: `AppTheme.light()/dark()` + `MensTheme` para modo hombres

### 2.4 App Proveedor — `glow_provider` (Fase 3)
- **51 pantallas** copiadas del monolito en 14 directorios:
  - `provider/` (7), `provider/business/` (4), `saas/` (4), `salon/` (3), `owner/` (1)
  - `academy/` (6), `auth/` (9), `profile/` (7), `chat/` (2), `booking/` (2)
  - `services/` (1), `store/` (1), `wallet/` (1), `support/` (3)
- **main.dart**: rutas proveedor + `onGenerateRoute` con parsing de argumentos (ProviderRouteScreen, CajaScreen, Academy quiz, BusinessTaskDetailScreen)
- **Widgets copiados** de glow_client: audience_toggle, app_update_gate, VTO painters
- **Fixes masivos**: BOM UTF-8, `invalid_constant` (~300 → 0), imports legacy → `package:glow_core/...`

### 2.5 Audience Scoping / API Middleware (Fase 4)
**Problema**: Backend único debe saber qué app llama para aplicar RLS y autorización correcta.

**Solución implementada en `glow_core`**:
```dart
// api_service.dart
static String appAudience = 'client';  // Se setea en main() de cada app

static Future<Map<String, String>> _getAuthHeaders() async {
  headers['X-App-Audience'] = appAudience;  // 'client' | 'provider'
  headers['Authorization'] = 'Bearer $token';
  headers['x-active-salon-id'] = activeSalonId;  // ya existía
  return headers;
}
```

**Cobertura total**:
- 100+ métodos genéricos (`get`, `post`, `put`, `patch`, `delete`)
- 5 `MultipartRequest` (uploadImage, classifyGarment, analyzeFaceShape, analyzeDesignWithAI, compareDiagnostics)
- 19 métodos con headers manuales (GlowCycle, MedicalValidation, GlowAI Premium, etc.)

**Config por app**:
```dart
// glow_client/main.dart
ApiService.appAudience = 'client';

// glow_provider/main.dart
ApiService.appAudience = 'provider';
```

**Backend esperado** (`api.glowapp.com`):
- Middleware `requireAnyRole` lee `X-App-Audience`
- Valida `roles[]` en JWT contra audiencia
- RLS policies filtran por `roles[]`

---

## 3. Detalle por Fases

### Fase 0: Monorepo Tooling + glow_core Skeleton
| Acción | Detalle |
|--------|---------|
| Rama creada | `feat/split-client-provider-apps` desde `main@edfb20c0` |
| Melos + pnpm | `melos.yaml` (bootstrap, analyze, test, build:client, build:provider), `pnpm-workspace.yaml` |
| glow_core skeleton | Directorios 10 módulos, `pubspec.yaml` (218 deps), `glow_core.dart` barrel, `video_mapping.dart` stubs (8 client UIDs + 7 provider UIDs Cloudflare Stream) |
| Verificación | `flutter analyze` = 0 errores |
| Commit | `1cb5d68e` "Phase 0: monorepo tooling + glow_core skeleton" |

### Fase 1: Extract Shared Layer → glow_core
| Acción | Detalle |
|--------|---------|
| Copia masiva | 103 archivos desde `frontend/lib/` → `packages/glow_core/lib/src/` |
| Barrel export | 117 exports directos en `glow_core.dart` |
| Fixes críticos | 6: icons barrel, GlowGuideEngineFactory, firebase_options, package_config.json, relative imports, aura_3d_emblem |
| Verificación | `flutter analyze` = 0 errores (7 warnings deprecated) |
| Commit | `69cdb203` "Phase 1: extract shared layer to glow_core" |
| Doc exportable | `Fase_1_Extract_Shared_Layer.md` (técnico + no técnico) |

### Fase 2: Build glow_client
| Hito | Detalle |
|------|---------|
| Scaffold | `flutter create --org com.glowapp --project-name glow_client --platforms=web,android,ios` |
| Pubspec | 38 deps + `glow_core: path: ../../packages/glow_core` |
| Assets | Fuentes (Manrope, CormorantGaramond, JetBrainsMono), video onboarding, iconos glow |
| Pantallas | 32 copiadas + `providers_screen.dart` extraída de monolito (2869 líneas) |
| Widgets | 10 copiados + stubs `booking_screen`, `provider_detail_screen` |
| Main.dart | Rutas + temas + Riverpod + `onGenerateRoute` para 7 pantallas con params |
| Migración imports | Script Python: 40+ archivos `../../../services/...` → `package:glow_core/...` |
| **Bloqueador resuelto** | `package_config.json` **absolute file:// URIs** para `glow_core` (analyzer regeneraba config roto) |
| Limpieza errores | ~1,368 errores → 0 (screen-by-screen: const removidos, BOM UTF-8, stubs, rewrites completos habeas_data, product_scanner, providers_screen restaurada desde git) |
| Commits | `c657fd88` (inicial), `e8f7a2b1` (fixes), `322a2330` (final + re-exports corregidos) |

### Fase 3: Build glow_provider
| Hito | Detalle |
|------|---------|
| Scaffold | `flutter create` idéntico a client |
| Pubspec | 40 deps + `syncfusion_flutter_calendar: ^32.1.23`, `intl: ^0.20.2` |
| Pantallas | 51 copiadas del monolito en 14 directorios |
| Main.dart | Rutas proveedor + `onGenerateRoute` con args parsing |
| Widgets | Copiados de glow_client + imports migrados |
| Re-exports glow_core | 9 servicios, 10 módulos glowguide, 5 iconos, 3 widgets proveedor, locked_feature_card, bank_account_dialog, saas_providers |
| Theme compat | AppTheme + MensTheme extendidos (ver 2.2) |
| Fixes masivos | BOM UTF-8 batch, `invalid_constant` agresivo (~300→0), `themeColor` → `final`, rewrites `business_onboarding_screen`, `biometric_history`, `habeas_data` |
| SAAS providers | `saas_providers.dart` copiado del monolito (resuelve 20+ undefined identifiers) |
| Support screens | `create_ticket_screen`, `ticket_chat_screen` copiadas + imports fix |
| Commits | `3f5f147d` "Phase 3: build glow_provider app" (295 archivos, 45k inserciones) |

### Fase 4: Audience Scoping / API Middleware
| Hito | Detalle |
|------|---------|
| Header `X-App-Audience` | Inyectado en **todas** las requests HTTP desde `glow_core` |
| Config por app | `ApiService.appAudience = 'client'|'provider'` en `main.dart` |
| Cobertura | 100+ métodos genéricos + 5 multipart + 19 manuales = **100% requests** |
| Verificación | `flutter analyze` = 0 errores workspace completo |
| Commit | Incluido en commit de Fase 3 (mismo PR) |

---

## 4. Estado Actual (Checklist)

| Componente | Estado | Evidencia |
|------------|--------|-----------|
| Monorepo tooling (Melos/pnpm) | ✅ Done | `melos bootstrap` OK, scripts funcionan |
| glow_core (shared layer) | ✅ Done | 0 errores analyze, 117 exports, 10 módulos |
| glow_client app | ✅ Done | 0 errores analyze, 32 pantallas, build OK |
| glow_provider app | ✅ Done | 0 errores analyze, 51 pantallas, build OK |
| Audience scoping header | ✅ Done | `X-App-Audience` en todas requests |
| SAAS providers en core | ✅ Done | 8 providers Riverpod exportados |
| Theme compatibility layer | ✅ Done | AppTheme + MensTheme extendidos |
| Package resolution fix | ✅ Done | Absolute file:// URIs en package_config.json |
| Git history | ✅ Clean | Commits atómicos por fase, rama aislada |
| Backend integration | 🔄 Pending | Requiere backend desplegado con middleware |

---

## 5. Próximos Pasos (Fases 5–8)

| Fase | Descripción | Dependencia |
|------|-------------|-------------|
| **5** | **Firebase & CI/CD** — Dos proyectos (`glowapp-client`, `glowapp-provider`), `google-services.json` inyectado por secrets, pipelines build/deploy separados | Fase 4 done |
| **6** | **Backend Middleware** — Implementar `requireAnyRole` + validación `X-App-Audience` + RLS en `api.glowapp.com` | Fase 4 done |
| **7** | **Cloudflare Stream & Video Mapping** — Poblar `video_mapping.dart` con UIDs reales (8 client + 7 provider) | Fase 1 stubs listos |
| **8** | **Archive Monolito** — Mover `frontend/` a `archive/`, limpiar referencias, documentar migración | Fases 1-7 done |

---

## 6. Convenciones y Reglas del Proyecto

| Regla | Descripción |
|-------|-------------|
| **Rama exclusiva** | Todo en `feat/split-client-provider-apps`. No merges de otras ramas (`feat/e02-*`, etc.) |
| **Commits atómicos** | 1 commit por fase autorizada, mensaje `Phase X: ...`, merge ff-only a main + push + health check |
| **No tocar `main`** | Hasta fin de fase autorizada. Monolito `frontend/` intacto hasta Fase 8 |
| **Academy 100% proveedor** | Creación, consumo, recursos, certificados solo en `glow_provider` |
| **Videos Cloudflare** | Cero en build. `video_mapping.dart` en core con UIDs; Fase 7 poblará |
| **Auth** | Un login, `roles[]` en JWT. Cada app valida audiencia via `X-App-Audience` |
| **Firebase** | Dos proyectos independientes con configs inyectados por CI |
| **Backend** | Single source of truth (`api.glowapp.com`) con middleware + RLS |
| **Cifras GlowApp** | COP redondeados a múltiplo de 1,000 (tarifas exactas se conservan) |
| **No credenciales** | En docs/resúmenes usar `[REDACTED]` |

---

## 7. Archivos Clave del Repositorio

```
melos.yaml                           # Monorepo scripts
pnpm-workspace.yaml                  # npm workspace
packages/glow_core/
  ├── pubspec.yaml                   # 218 shared deps
  ├── lib/
  │   ├── glow_core.dart             # Barrel principal (117 exports)
  │   ├── providers/saas_providers.dart
  │   ├── services/*.dart            # 32 re-exports
  │   ├── models/*.dart              # 15 re-exports
  │   ├── design/icons/*.dart        # 5 iconos
  │   ├── core/theme/app_theme.dart  # AppTheme + compat layer
  │   ├── shared/mens_theme.dart     # MensTheme + semantic colors
  │   ├── glowguide/...              # 10 módulos motor
  │   └── l10n/*.dart                # i18n
  └── lib/src/...                    # Implementaciones reales
apps/glow_client/
  ├── pubspec.yaml
  ├── lib/main.dart                  # appAudience = 'client'
  └── lib/screens/...                # 32 pantallas
apps/glow_provider/
  ├── pubspec.yaml
  ├── lib/main.dart                  # appAudience = 'provider'
  └── lib/screens/...                # 51 pantallas en 14 dirs
.hermes/plans/
  ├── GlowApp_Split_Architecture_v2.md      # Arquitectura inicial (Fase 0)
  ├── Fase_0_Monorepo_Tooling.md            # Exportable Fase 0
  ├── Fase_1_Extract_Shared_Layer.md        # Exportable Fase 1
  └── GlowApp_Split_Complete_Phases_0-4.md  # ESTE DOCUMENTO
```

---

## 8. Métricas de Código

| Métrica | Valor |
|---------|-------|
| Archivos glow_core (src) | 103 |
| Líneas glow_core | ~24,000 |
| Pantallas glow_client | 32 |
| Pantallas glow_provider | 51 |
| Widgets compartidos en core | 23 (genéricos + owner + profile) |
| Servicios en core | 32 |
| Modelos en core | 15 |
| SAAS providers | 8 |
| Commits en rama | 4 (Phase 0, 1, 2 final, 3+4) |
| Errores analyze (workspace) | **0** |
| Warnings deprecated (theme compat) | ~30 (esperados, no bloqueantes) |

---

## 9. Glosario

| Término | Definición |
|---------|------------|
| **Audience scoping** | Técnica para que backend sepa qué frontend llama y aplique autorización distinta |
| **Monorepo** | Repositorio único con múltiples paquetes/apps publicables |
| **Melos** | Herramienta Dart/Flutter para gestionar monorepos (bootstrap, analyze, test, versionado) |
| **Barrel export** | Archivo que re-exporta múltiples archivos (`export '...'`) para imports limpios |
| **RLS (Row Level Security)** | Políticas de seguridad a nivel fila en PostgreSQL |
| **Cloudflare Stream** | Plataforma de video streaming; UIDs referenciados en `video_mapping.dart` |
| **GlowGuide** | Motor de onboarding/tutoriales interactivos (compartido en core, config por app) |
| **SAAS providers** | Riverpod providers para funcionalidad SaaS multi-tenant (billing, team, apiKeys, etc.) |

---

## 10. Contacto y Referencias

- **Repositorio**: `github.com/Diegoromerov/belleza-app` (rama `feat/split-client-provider-apps`)
- **Copia canónica local**: `~/belleza-app-audit` (418 docs)
- **Bundle empresa**: `C:\Users\Compu casa\glowapp-company` (12 fases, DECISIONES/, PLAN-MAESTRO.md)
- **Backend**: `api.glowapp.com` (Postgres Railway, pgvector, middleware pendiente Fase 6)
- **Autor**: Diego (Diegoromerov) — Decisiones requieren `AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — GLOWAPP-F<NN>`

---

*Fin del documento. Este archivo resume la arquitectura completa desde la planificación inicial hasta la finalización de la Fase 4, listo para compartir con stakeholders técnicos y no técnicos.*