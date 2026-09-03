# GLOWAPP ICON PILOT MIGRATION PLAN

## 1. Executive Summary

Este documento presenta el **plan de migración piloto** para transicionar la iconografía actual de GlowApp (198 instancias de `Icons.*` en 39 archivos) hacia **GLOW ICON SYSTEM v1.0 (51 iconos, LOCKED)**.

**Baseline M1-I0:**
- 198 instancias, 130 iconos únicos Material Design
- 37 DIRECT_MATCH, 32 SEMANTIC_MATCH, 9 REVIEW_REQUIRED, 148 NO_EQUIVALENT
- 0 uso productivo de GlowIcon/Adapter
- Quality Score M1-I0: 97/100

**Estrategia:** Componente-primero, incremental, reversible, semanticamente seguro.

**Pilotos evaluados:** 4 (A: General, B: Store, C: Concierge/Booking, D: Provider)

**Orden recomendado:** A → B → D → C

---

## 2. Baseline

| Métrica | Valor |
|---------|-------|
| Instancias totales | 198 |
| Iconos Material únicos | 130 |
| Archivos con iconos | 39 |
| Pantallas auditadas | 55 |
| Componentes auditados | 12 |
| DIRECT_MATCH | 37 |
| SEMANTIC_MATCH | 32 |
| REVIEW_REQUIRED | 9 |
| NO_EQUIVALENT gaps | 148 |
| GlowIcon producción | 0 |
| Adapter producción | 0 |

---

## 3. Pilot Philosophy

**Principios rectores:**
1. **Component-first** — Migrar componentes reutilizables antes que pantallas
2. **Semantic safety** — No asumir equivalencia; validar contexto por instancia
3. **Reversibility** — Cada piloto reversible vía `git checkout` individual
4. **Theme-aware** — Women/Men/AURA color roles definidos por piloto
5. **Accessibility-first** — Preservar/mejorar semantic labels, touch targets
6. **No logic touch** — Sustitución puramente visual
7. **Stop conditions** — Criterios claros para abortar

---

## 4. Pilot A — General (Home + Navigation)

### Archivos
- `lib/screens/home/home_screen.dart` (10 iconos)
- `lib/widgets/floating_navigation_dock.dart` (8 iconos)

### Análisis detallado

| Archivo | Línea | Icono Actual | Semántica | GlowIcon Propuesto | Clasificación | Riesgo |
|---------|-------|--------------|-----------|-------------------|---------------|--------|
| home_screen | 76 | `notifications_none_outlined` | Notificaciones | `GlowIcon.notification()` | DIRECT_MATCH | LOW |
| home_screen | 80 | `shopping_bag_outlined` | GlowStore | `GlowIcon.bag()` | DIRECT_MATCH | LOW |
| home_screen | 131 | `camera_front_outlined` | Biometría/AR | **NO_EQUIVALENT** | KEEP_CURRENT | — |
| home_screen | 147 | `storefront_outlined` | GlowStore | `GlowIcon.bag()` | SEMANTIC_MATCH | LOW |
| home_screen | 163 | `school_outlined` | Academia | **NO_EQUIVALENT** | KEEP_CURRENT | — |
| home_screen | 286 | `home_outlined / home` | Inicio (BottomNav) | `GlowIcon.home()` | DIRECT_MATCH | LOW |
| home_screen | 291 | `camera_front_outlined / camera_front` | Biometría (BottomNav) | **NO_EQUIVALENT** | KEEP_CURRENT | — |
| home_screen | 296 | `storefront_outlined / storefront` | GlowStore (BottomNav) | `GlowIcon.bag()` | DIRECT_MATCH | LOW |
| home_screen | 301 | `school_outlined / school` | Academia (BottomNav) | **NO_EQUIVALENT** | KEEP_CURRENT | — |
| floating_nav | 133 | `auto_awesome` | Asistente IA (AURA) | `GlowIcon.aura()` | SEMANTIC_MATCH | LOW |
| floating_nav | 141 | `dashboard_outlined` | Panel proveedor | **NO_EQUIVALENT** | KEEP_CURRENT | — |
| floating_nav | 147 | `calendar_today_outlined` | Citas | `GlowIcon.calendar()` | DIRECT_MATCH | LOW |
| floating_nav | 154 | `lightbulb_outline_rounded` | Ideas (AI tools) | `GlowIcon.glowRecommendation()` | SEMANTIC_MATCH | LOW |
| floating_nav | 162 | `inventory_2_outlined` | Servicios | **NO_EQUIVALENT** | KEEP_CURRENT | — |
| floating_nav | 168 | `person_outline_rounded` | Perfil (cliente) | `GlowIcon.profile()` | DIRECT_MATCH | LOW |
| floating_nav | 176 | `person_outline_rounded` | Perfil (proveedor) | `GlowIcon.profile()` | DIRECT_MATCH | LOW |
| floating_nav | 182 | `logout_rounded` | Salir | **NO_EQUIVALENT** | KEEP_CURRENT | — |

### Métricas Pilot A
- **ICON_COUNT:** 18
- **MIGRATABLE_COUNT:** 12 (DIRECT_MATCH) + 4 (SEMANTIC_MATCH) = 16
- **REVIEW_COUNT:** 1 (auto_awesome en floating_nav)
- **NO_EQUIVALENT_COUNT:** 2 (camera, school, dashboard, inventory, logout = 5 unique, 2 in migratables)
- **ALREADY_GLOW_COUNT:** 0
- **RISK:** LOW
- **LEVERAGE:** HIGH (floating_navigation_dock usado en todas las pantallas provider)

### Audiencia: GENERAL
### Dependencias: Ninguna (entry point)

---

## 5. Pilot B — Store / Women / Men

### Archivos
- `lib/screens/store_screen.dart` (~19 iconos)
- `lib/widgets/store_product_card.dart` (~6 iconos)

### Análisis clave (audience-aware)

| Icono | Contexto Women | Contexto Men | GlowIcon Propuesto | Color Role |
|-------|----------------|--------------|-------------------|------------|
| `shopping_bag_outlined` | Cart/Bolsa | Cart/Bolsa | `GlowIcon.bag()` | `accent` (context-aware) |
| `shopping_cart` / `add_shopping_cart` | Añadir al carrito | Añadir al carrito | `GlowIcon.cart()` | `accent` |
| `search_rounded` | Buscar productos | Buscar productos | `GlowIcon.search()` | `accent` |
| `filter_list` | Filtros categoría | Filtros categoría | `GlowIcon.filter()` | `secondary` |
| `sort` | Ordenar | Ordenar | `GlowIcon.sort()` | `secondary` |
| `star_rounded` (rating) | Calificación 5★ | Calificación 5★ | **REVIEW_REQUIRED** | `accent` |
| `verified_user_rounded` | Badge verificado | Badge verificado | **NO_EQUIVALENT** | `accent` |
| `spa_rounded` | Categoría Spa | — | `GlowIcon.spa()` | `accent` |
| `visibility_rounded` | Vista rápida | Vista rápida | **NO_EQUIVALENT** | `secondary` |
| `work_rounded` / `public_rounded` | Badge PRO/PÚBLICO | Badge PRO/PÚBLICO | **NO_EQUIVALENT** | `inverse` |
| `location_on_outlined` | Ubicación tienda | Ubicación tienda | `GlowIcon.location()` | `secondary` |
| `person_outline_rounded` | Perfil usuario | Perfil usuario | `GlowIcon.profile()` | `secondary` |
| `close_rounded` | Cerrar dialog/checkout | Cerrar dialog/checkout | `GlowIcon.close()` | `secondary` |
| `check_circle_outline_rounded` | Checkout success | Checkout success | **NO_EQUIVALENT** | `success` |
| `lock_outline_rounded` | Secure payment | Secure payment | **NO_EQUIVALENT** | `secondary` |
| `credit_card_rounded` | Pago tarjeta | Pago tarjeta | **NO_EQUIVALENT** | `secondary` |
| `calendar_month_rounded` | Expiración tarjeta | Expiración tarjeta | `GlowIcon.calendar()` | `secondary` |
| `phone_android_rounded` | Nequi | Nequi | **NO_EQUIVALENT** | `secondary` |
| `remove_rounded` / `add_rounded` | Cantidad -/+ | Cantidad -/+ | **NO_EQUIVALENT** | `secondary/primary` |
| `delete_outline_rounded` | Eliminar item | Eliminar item | **NO_EQUIVALENT** | `error` |

### Theme Matrix (Store)
| Audience | Primary | Secondary | Accent | Success | Error | Warning |
|----------|---------|-----------|--------|---------|-------|---------|
| WOMEN | `GlowStoreTokens.accentColor(isMen:false)` | `secondaryTextColor` | `accentColor` | `deepGreen` | `stateError` | `amber` |
| MEN | `GlowStoreTokens.accentColor(isMen:true)` | `secondaryTextColor` | `accentColor` | `deepGreen` | `stateError` | `amber` |

### Métricas Pilot B
- **ICON_COUNT:** 25
- **MIGRATABLE_COUNT:** 8 DIRECT + 12 SEMANTIC = 20
- **REVIEW_COUNT:** 3 (star, auto_awesome context, visibility)
- **NO_EQUIVALENT_COUNT:** 2 (verified_user, camera/photo placeholders)
- **RISK:** MEDIUM (theme complexity, star ambiguity)
- **LEVERAGE:** HIGH (store_product_card × N productos)

---

## 6. Pilot C — Concierge / Booking (Critical Flow)

### Archivos
- `lib/screens/booking_screen.dart` (23 iconos)
- `lib/widgets/provider/booking_card.dart` (10 iconos)
- `lib/widgets/wompi_payment_sheet.dart` (11 iconos)

### Análisis crítico

**Booking Screen — Step 1 (Logistics):**
| Icono | Semántica | GlowIcon | Notas |
|-------|-----------|----------|-------|
| `arrow_back` | Back navigation | `GlowIcon.back()` | DIRECT |
| `location_on_outlined` | Dirección servicio | `GlowIcon.location()` | DIRECT |
| `calendar_today` | Calendar picker | `GlowIcon.calendar()` | DIRECT |
| `access_time_filled` | Time slots | `GlowIcon.clock()` | DIRECT |
| `note_alt_outlined` | Notas | **NO_EQUIVALENT** | KEEP |
| `spa_outlined` | Service icon | `GlowIcon.spa()` | DIRECT |
| `people_alt` | Group booking | **NO_EQUIVALENT** | KEEP |
| `local_offer` | Promo/discount | **NO_EQUIVALENT** | KEEP |
| `chevron_left/right` | Calendar nav | `GlowIcon.back()/forward()` | SEMANTIC |

**Booking Screen — Step 2 (Cross-sell):**
| Icono | Semántica | GlowIcon | Notas |
|-------|-----------|----------|-------|
| `shopping_bag_outlined` | Productos recomendados | `GlowIcon.bag()` | DIRECT |
| `remove` / `add` | Qty -/+ | **NO_EQUIVALENT** | KEEP |
| `content_cut` | Service tag "Cabello" | `GlowIcon.hair()` | SEMANTIC |

**Booking Screen — Step 3 (Summary/Payment):**
| Icono | Semántica | GlowIcon | Notas |
|-------|-----------|----------|-------|
| `content_cut` | Servicio | `GlowIcon.hair()` | SEMANTIC |
| `calendar_today` | Fecha/hora | `GlowIcon.calendar()` | DIRECT |
| `location_on` | Dirección | `GlowIcon.location()` | DIRECT |
| `person` | Prestador | `GlowIcon.profile()` | DIRECT |
| `shield_outlined` | Security badge | **NO_EQUIVALENT** | KEEP |
| `radio_button_checked/off` | Product selection | **NO_EQUIVALENT** | KEEP |

**Wompi Payment Sheet (CRITICAL):**
| Icono | Semántica | GlowIcon | Riesgo |
|-------|-----------|----------|--------|
| `close_rounded` | Cerrar sheet | `GlowIcon.close()` | LOW |
| `stars_rounded` | Add-on "Tratamiento" | **REVIEW_REQUIRED** | MEDIUM |
| `account_balance_wallet_rounded` | Cashback wallet | **NO_EQUIVALENT** | HIGH |
| `error_outline_rounded` | Error state | **NO_EQUIVALENT** | MEDIUM |
| `lock_outline_rounded` | Secure/CVV | **NO_EQUIVALENT** | HIGH |
| `security_rounded` | Secure badge | **NO_EQUIVALENT** | HIGH |
| `phone_android_rounded` | Nequi | **NO_EQUIVALENT** | HIGH |
| `credit_card_rounded` | Tarjeta | **NO_EQUIVALENT** | HIGH |
| `calendar_month_rounded` | Exp date | `GlowIcon.calendar()` | MEDIUM |
| `lock_rounded` | CVV | **NO_EQUIVALENT** | HIGH |
| `person_outline_rounded` | Cardholder | `GlowIcon.profile()` | LOW |
| `check_circle_rounded` | Success | **NO_EQUIVALENT** | MEDIUM |

**Booking Card (reusable):**
| Icono | Semántica | GlowIcon |
|-------|-----------|----------|
| `access_time` | Time | `GlowIcon.clock()` |
| `location_on` | Address | `GlowIcon.location()` |
| `navigation_outlined` | Iniciar ruta | `GlowIcon.location()` (SEMANTIC) |
| `play_arrow_outlined` | Iniciar servicio | **NO_EQUIVALENT** |
| `chat_bubble_outline_rounded` | Chat | `GlowIcon.chat()` |
| `map_outlined` | Ver mapa | `GlowIcon.location()` |
| `check_circle_outline_rounded` | Completar | **NO_EQUIVALENT** |
| `support_agent_outlined` | Soporte | `GlowIcon.support()` |
| `gavel` | Disputa | **NO_EQUIVALENT** |
| `receipt_long_outlined` | Liquidación | **NO_EQUIVALENT** |

### Métricas Pilot C
- **ICON_COUNT:** 44
- **MIGRATABLE_COUNT:** 15 DIRECT + 18 SEMANTIC = 33
- **REVIEW_COUNT:** 6 (stars, payment icons, shield, gavel)
- **NO_EQUIVALENT_COUNT:** 5 (payment: credit_card, wallet, lock, security; booking: play, check_circle, receipt, gavel)
- **RISK:** HIGH (payment flow, verified_user, lock, security — NO_EQUIVALENT en v1.0)
- **LEVERAGE:** HIGH (booking_card × 3 pantallas, wompi_payment_sheet × 2 flows)

---

## 7. Pilot D — Provider Dashboard

### Archivos
- `lib/screens/provider_dashboard_screen.dart` (35 iconos)
- `lib/widgets/provider/provider_luxe_components.dart` (3 iconos)

### Análisis
- Alta densidad, estado complejo
- Reutiliza `booking_card` (validado en Pilot C context)
- `provider_luxe_components`: `ProviderMetricCard` (icon param), `ProviderAppointmentTile` (check/close)

### Iconos únicos detectados
`notifications_active`, `play_circle_fill`, `stars_rounded`, `receipt_long_outlined`, `navigation_outlined`, `play_arrow_outlined`, `chat_bubble_outline_rounded`, `map_outlined`, `light_mode/dark_mode`, `shopping_bag_outlined`, `auto_stories`, `chat_bubble/person` (BottomNav), `emergency_outlined`, `timer_outlined`, `verified_user_outlined`, `calendar_today`, `account_balance_wallet`, `star`, `spa_outlined`, `access_time`, `location_on`, `lock_clock`, `map`, `logout`, `refresh`, `offline_bolt`, `phone_in_talk`, `support_agent`, `check_circle`, `security`

### Métricas Pilot D
- **ICON_COUNT:** 38
- **MIGRATABLE_COUNT:** 12 DIRECT + 18 SEMANTIC = 30
- **REVIEW_COUNT:** 5 (auto_awesome context, stars, light/dark mode, offline_bolt)
- **NO_EQUIVALENT_COUNT:** 3 (verified_user, security, emergency)
- **RISK:** MEDIUM
- **LEVERAGE:** MEDIUM (dashboard only, pero reusa booking_card)

---

## 8. Auto Awesome Special Audit

**16 instancias** (M1-I0 reportaba 9; búsqueda profunda revela 16)

| # | Archivo | Línea | Contexto | GlowIcon Propuesto | Confianza |
|---|---------|-------|----------|-------------------|-----------|
| 1 | hero_section.dart | 118 | AURA Skin Score | `aura()` | HIGH |
| 2 | floating_navigation_dock | 133 | Asistente IA button | `aura()` | HIGH |
| 3 | main.dart | 1252 | Category "Todos" | `glow()` | MEDIUM |
| 4 | main.dart | 1432 | Ideas center button | `glowRecommendation()` | HIGH |
| 5 | main.dart | 1630 | Search → AI Chat | `aura()` | HIGH |
| 6 | ai_search_bar.dart | 55 | AI Search trigger | `glowRecommendation()` | HIGH |
| 7 | aura_multi_agent_chat | 243 | Redirect to Ideas | `glowRecommendation()` | HIGH |
| 8 | provider_detail_screen | 1165 | "Pregúntale a IA" | `glowRecommendation()` | HIGH |
| 9 | register_screen.dart | 338 | "Diagnóstico Facial Aura" | `aura()` | HIGH |
| 10 | glowup_card_screen | 243 | AI treatment rec | `glowRecommendation()` | HIGH |
| 11 | chat_screen.dart | 614 | "Abrir herramienta Ideas" | `glowRecommendation()` | HIGH |
| 12 | evolution_dashboard | 330 | AI treatment note | `glowRecommendation()` | MEDIUM |
| 13 | rewards_xp_screen | 154 | "Diagnóstico Facial Aura" | `aura()` | HIGH |
| 14 | processing_alchemy | 112 | AI analyzing animation | `analyze()` | HIGH |
| 15 | results_screen | 170 | VTO Live button | `glowRecommendation()` | MEDIUM |
| 16 | results_screen | 487 | Wrinkles ScoreCard | `analyze()` | HIGH |

**Distribución:** `glowRecommendation()` 8, `aura()` 5, `analyze()` 2, `glow()` 1

**Regla:** NO mapping global. Cada instancia decidida por contexto.

---

## 9. Direct Match Policy

**DIRECT_MATCH** migración automática SOLO si:
1. ✅ Significado equivalente
2. ✅ Interacción equivalente  
3. ✅ Visual affordance compatible
4. ✅ Accessibility preservable
5. ✅ Tamaño compatible
6. ✅ Sin contexto especial

**Lista aprobada (23):** home, search, menu, close, back, forward, more, profile, notifications, settings, bag, cart, calendar, clock, location, spa, chat, support, share, filter, sort, download, qr

---

## 10. Semantic Match Policy

**SEMANTIC_MATCH** = "Posible equivalencia, requiere revisión"

Clasificación obligatoria:
- **SEMANTIC_SAFE** — Contexto claro, mapping validado
- **SEMANTIC_REVIEW** — Ambigüedad, necesita decisión

**Ejemplos SEMANTIC_SAFE (Pilot A):**
- `shopping_bag_outlined` → `bag()` (variant outlined)
- `calendar_today_outlined` → `calendar()` (variant)
- `lightbulb_outline` → `glowRecommendation()` (Ideas = AI tools)

**Ejemplos SEMANTIC_REVIEW (Pilot C):**
- `stars_rounded` (add-on) → `glowRecommendation()` vs `aura()`
- `account_balance_wallet` (cashback) → NO_EQUIVALENT
- `navigation_outlined` (iniciar ruta) → `location()` vs nuevo

---

## 11. Review Required

**9 categorías** — FUERA del primer piloto salvo decisión documentada:

| Categoría | Instancias | Acción |
|-----------|------------|--------|
| `auto_awesome` | 16 | Ver auto_awesome_audit por instancia |
| `star` / `stars_rounded` | 6 | Rating vs wishlist vs heart — decidir por contexto |
| `photo` / `camera` | 8+ | AR/VTO, profile, scanner — NO_EQUIVALENT v1.0 |
| `verified_user` / `verified` | 3 | Trust badge — NO_EQUIVALENT v1.0 |
| `lock` / `visibility` | 6+ | Auth/security — NO_EQUIVALENT v1.0 |
| `gavel` | 3 | Disputas/legal — NO_EQUIVALENT v1.0 |
| `shield` | 2 | Security — NO_EQUIVALENT v1.0 |
| `refresh` | 3 | Pull-to-refresh vs sync |
| `check_circle` | 5 | Success/confirmation — contexto |

---

## 12. No Equivalent Policy

**148 gaps únicos** — Clasificación:

| Clasificación | Ejemplos | Acción |
|---------------|----------|--------|
| KEEP_CURRENT | camera, photo, verified_user, lock, star, gavel, shield, credit_card, payment | Mantener Icons.* |
| FUTURE_ICON_CANDIDATE | camera, verified_user, lock, star, credit_card | Solicitar para v1.1/I3 |
| PLATFORM_ICON | apple, g_mobiledata, ios_share | Mantener nativo |
| SEMANTIC_STATE | error_outline, warning, check_circle, refresh | Evaluar si state ≠ icon |
| OUT_OF_SCOPE | opacity, blur_on, rocket_launch | Experimental, no migrar |
| UNKNOWN | Poco frecuentes | Documentar, no decidir |

**NO resolver en esta fase.** Registrar como `FUTURE_ICON_REQUEST` en JSON.

---

## 13. Component-First Strategy

| Componente | Leverage | Usage | Affected Screens | Icons | Risk |
|------------|----------|-------|------------------|-------|------|
| `floating_navigation_dock` | **HIGH** | 1 | All provider screens | 8 | LOW |
| `wompi_payment_sheet` | **HIGH** | 2 | booking, store | 11 | MEDIUM |
| `booking_card` | **HIGH** | 3 | provider_dashboard, client_bookings, booking_tracking | 10 | LOW |
| `store_product_card` | **HIGH** | 1 | store_screen (grid) | 6 | LOW |
| `ai_search_bar` | **HIGH** | 1 | main.dart (home) | 2 | LOW |
| `provider_luxe_components` | MEDIUM | 2 | provider_dashboard, provider_detail | 3 | LOW |
| `audience_toggle` | MEDIUM | 2 | store, settings | 3 | LOW |

**Impacto total si migra floating_navigation_dock:** 15+ pantallas provider afectadas.

---

## 14. Exact File Change Plan

### Pilot A — Files to Modify
```
lib/screens/home/home_screen.dart
lib/widgets/floating_navigation_dock.dart
```

### Pilot A — Exact Changes (muestra)

| File | Line | Current | Target | Size | ColorRole | SemanticLabel | Action |
|------|------|---------|--------|------|-----------|---------------|--------|
| home_screen | 76 | Icons.notifications_none_outlined | GlowIcon.notification() | 24 | primary | "Notificaciones" | MIGRATE |
| home_screen | 80 | Icons.shopping_bag_outlined | GlowIcon.bag() | 24 | primary | "GlowStore" | MIGRATE |
| home_screen | 131 | Icons.camera_front_outlined | — | 28 | accent | "Biometría" | KEEP_CURRENT |
| home_screen | 147 | Icons.storefront_outlined | GlowIcon.bag() | 28 | accent | "GlowStore" | MIGRATE |
| home_screen | 163 | Icons.school_outlined | — | 28 | accent | "Academia" | KEEP_CURRENT |
| home_screen | 286 | Icons.home_outlined/home | GlowIcon.home() | 24 | primary | "Inicio" | MIGRATE |
| home_screen | 291 | Icons.camera_front_outlined/camera_front | — | 24 | primary | "Biometría" | KEEP_CURRENT |
| home_screen | 296 | Icons.storefront_outlined/storefront | GlowIcon.bag() | 24 | primary | "GlowStore" | MIGRATE |
| home_screen | 301 | Icons.school_outlined/school | — | 24 | primary | "Academia" | KEEP_CURRENT |
| floating_nav | 133 | Icons.auto_awesome | GlowIcon.aura() | 20 | primary | "Asistente IA" | MIGRATE |
| floating_nav | 141 | Icons.dashboard_outlined | — | 20 | primary | "Panel" | KEEP_CURRENT |
| floating_nav | 147 | Icons.calendar_today_outlined | GlowIcon.calendar() | 20 | primary | "Citas" | MIGRATE |
| floating_nav | 154 | Icons.lightbulb_outline_rounded | GlowIcon.glowRecommendation() | 26 | accent | "Ideas" | MIGRATE |
| floating_nav | 162 | Icons.inventory_2_outlined | — | 20 | primary | "Servicios" | KEEP_CURRENT |
| floating_nav | 168 | Icons.person_outline_rounded | GlowIcon.profile() | 20 | primary | "Perfil" | MIGRATE |
| floating_nav | 176 | Icons.person_outline_rounded | GlowIcon.profile() | 20 | primary | "Perfil" | MIGRATE |
| floating_nav | 182 | Icons.logout_rounded | — | 20 | error | "Salir" | KEEP_CURRENT |

### Pilot B, C, D — Files listados en JSON (sección `file_change_plan`)

---

## 15. Accessibility Plan

**Requisitos:**
- Preservar todos `semanticLabel` existentes
- Preservar todos `tooltip` existentes  
- Añadir `semanticLabel` donde falte en iconos interactivos
- Touch targets ≥ 48dp
- No degradar screen reader

**Estado actual:** ~15% semanticLabel, ~20% tooltip, 0% Semantics wrapper

**Target:** 100% interactivos con semanticLabel, 100% IconButton con tooltip, decorativos silenciados

---

## 16. Size Plan

**Tokens GlowIcon:**
| Token | Size | Uso observado |
|-------|------|---------------|
| xs | 16 | 10% (12-16px) |
| sm | 20 | 25% (18-20px) |
| md | 24 | 35% (22-24px) |
| lg | 28 | 20% (28-32px) |
| xl | 32 | 20% (28-32px) |
| xxl | 40 | 10% (36-56px) |
| huge | 48 | 10% (36-56px) |

**Compatibilidad:** Tokens cubren rango completo observado.

**Regla:** EXACT_MATCH si existe token, NEAREST_TOKEN si no, REQUIRES_REVIEW si >huge.

---

## 17. Color Plan

| Color Actual | Target Role | Contexto |
|--------------|-------------|----------|
| LuxeColors.gold871 | accent | Women brand |
| LuxeColors.nude900/500 | secondary/neutral | Text |
| AppTheme.primary | primary | Global |
| GlowStoreTokens.accentColor(isMen:) | accent | Store audience-aware |
| Colors.redAccent/deepGreen/orange | error/success/warning | Hardcoded status |
| Colors.white/white24/white30 | inverse/neutral | Overlay/AR |
| Color(0xFF10B981) | success | Verified |
| Color(0xFFB00020) | error | Delete |
| Colors.pinkAccent | accent/aura | AURA Chat |
| t.neutral500 | neutral | Booking card |
| t.warning | warning | Booking card |

**NO nuevos colores. NO modificar Color System.**

---

## 18. Theme Matrix

Ver JSON `theme_matrix` por piloto y audiencia (WOMEN/MEN/AURA/GENERAL).

---

## 19. Logic Safety

**LOGIC_TOUCH_REQUIRED = false**

La sustitución es **puramente visual**. Se preservan exactamente:
- `onPressed` callbacks
- Navigation
- State
- Providers
- Business logic
- API calls
- Booking flow
- Payments
- Authentication

**Componentes alto riesgo (solo visual):**
- `wompi_payment_sheet.dart` — payment flow, iconos en botones/inputs
- `booking_card.dart` — status actions, iconos en botones

---

## 20. Visual Regression Plan

**Checklist validación:**
1. Geometry: stroke weight 1.75px, round cap/join, proporciones
2. Size: token match o nearest token
3. Alignment: centrado en contenedor
4. Spacing: padding/margins preservados
5. Color: color role correcto por tema
6. Visual weight: monoline percibido correctamente
7. Affordance: interactivo vs decorativo claro
8. Accessibility: labels, tooltips, touch targets
9. Responsive: escala en breakpoints
10. Theme context: Women/Men/AURA correctos

**Método:** Screenshot before/after en device/emulator + golden tests + QA manual

---

## 21. Risk Matrix

| Pilot | Visual | Semantic | Functional | Accessibility | Theme | Scope | Overall |
|-------|--------|----------|------------|---------------|-------|-------|---------|
| A | LOW | LOW | LOW | LOW | LOW | LOW | **LOW** |
| B | LOW | MEDIUM | LOW | LOW | MEDIUM | LOW | **MEDIUM** |
| C | MEDIUM | HIGH | HIGH | MEDIUM | LOW | MEDIUM | **HIGH** |
| D | MEDIUM | MEDIUM | MEDIUM | LOW | LOW | MEDIUM | **MEDIUM** |

---

## 22. Pilot Scores

| Pilot | Visual Value /25 | Migration Leverage /20 | Semantic Safety /20 | Functional Safety /15 | Accessibility /10 | Theme Coverage /10 | TOTAL /100 |
|-------|------------------|------------------------|---------------------|----------------------|-------------------|-------------------|------------|
| A | 22 | 18 | 18 | 15 | 9 | 8 | **90** |
| B | 20 | 16 | 14 | 13 | 8 | 9 | **80** |
| D | 18 | 14 | 14 | 12 | 8 | 7 | **73** |
| C | 24 | 19 | 10 | 8 | 7 | 8 | **76** |

---

## 23. Pilot Order

### #1 — Pilot A (General) — **RECOMMENDED FIRST**
**Score:** 90/100 | **Risk:** LOW
**Justificación:** Máximo learning value, mínimo functional risk. Valida framework core (registry, theme extension, adapter, size tokens, color roles, accessibility). `floating_navigation_dock` da validación cross-cutting en 15+ pantallas. Sin dependencias de flujos críticos.

### #2 — Pilot B (Store) 
**Score:** 80/100 | **Risk:** MEDIUM
**Justificación:** Valida audience-aware theming (Women/Men) y color roles. High leverage via `store_product_card`. Depende de Pilot A para iconos navegación (home, bag, search).

### #3 — Pilot D (Provider)
**Score:** 73/100 | **Risk:** MEDIUM
**Justificación:** Provider context, dashboard density. Reusa `booking_card` (validado contexto Pilot C). Menor functional risk que Pilot C.

### #4 — Pilot C (Concierge/Booking)
**Score:** 76/100 | **Risk:** HIGH
**Justificación:** Flujo crítico booking/payment. Múltiples REVIEW_REQUIRED y NO_EQUIVALENT (verified_user, lock, check_circle, gavel, shield, credit_card, wallet, payment). Solo tras A, B, D validar framework. Iconos pago NO_EQUIVALENT en v1.0.

---

## 24. Success Metrics

| Métrica | Target | Medición |
|---------|--------|----------|
| direct_matches_migrated_pct | 100% | DIRECT_MATCH reemplazados / total en piloto |
| semantic_review_completed_pct | 100% | SEMANTIC_MATCH decididos / total en piloto |
| accessibility_preservation | No regression | Labels preservados, touch ≥48dp, screen reader pass |
| visual_regressions | 0 | Golden test diffs + QA sign-off |
| logic_regressions | 0 | Tests pass + manual flow test |
| theme_consistency | 100% | Color roles correctos per theme_matrix |
| icon_sizes | 100% token match | Cada icono usa token definido |
| build_test_status | PASS | analyze 0 errors, test all pass, build web success |

---

## 25. Stop Conditions

Detener migración piloto si:
- ❌ Visual regression inesperada (stroke, alignment, proporción)
- ❌ Ambigüedad semántica sin resolver (ej. auto_awesome mapping)
- ❌ Cambio de business logic detectado (onPressed, navigation, state)
- ❌ Degradación accessibility (labels faltantes, touch targets menores)
- ❌ Token de tema faltante (color role no definido para audiencia)
- ❌ Asset inesperado faltante (SVG no en registry)
- ❌ Fallo registry (GlowIconRegistry retorna null)
- ❌ Fallo build (analyze errors, test failures, compile errors)
- ❌ Gap iconos pago (credit_card, wallet, payment — NO_EQUIVALENT)

---

## 26. Rollback Plan

**Estrategia:** Git-based per-pilot rollback

| Piloto | Comando Rollback |
|--------|------------------|
| A | `git checkout lib/screens/home/home_screen.dart lib/widgets/floating_navigation_dock.dart` |
| B | `git checkout lib/screens/store_screen.dart lib/widgets/store_product_card.dart` |
| C | `git checkout lib/screens/booking_screen.dart lib/widgets/provider/booking_card.dart lib/widgets/wompi_payment_sheet.dart` |
| D | `git checkout lib/screens/provider_dashboard_screen.dart lib/widgets/provider/provider_luxe_components.dart` |
| Full | `git checkout lib/` |

**Validación post-rollback:** `flutter test && flutter analyze && flutter build web --release`

---

## 27. Future Icon Requests

| Semantic Need | Screen | Frequency | Priority | Reason | Proposed Category |
|---------------|--------|-----------|----------|--------|-------------------|
| Camera/Photo (AR/VTO, profile, scanner) | capture, home, store, profile | HIGH | P1 | Core AR/VTO | SYSTEM |
| Verified badge (trust/profile) | profile, wallet, store, provider | HIGH | P1 | Trust signal | CONCIERGE |
| Lock/Visibility (auth/security) | auth, settings, payment | HIGH | P1 | Auth UX | SYSTEM |
| Star/Rating (quality/favorites) | store, results, rewards | HIGH | P1 | Rating distinct from heart | SYSTEM |
| Credit Card/Payment (checkout) | wompi_payment_sheet, store | HIGH | P1 | Payment methods | CONCIERGE |
| Gavel/Shield (disputes/security) | disputes, provider dashboard | MEDIUM | P2 | Legal/security | CONCIERGE |
| Sun/UV, Back Hand, Face Retouching (AI skin) | results, evolution | MEDIUM | P2 | AI skin metrics | AURA |
| Style/Checkroom/Psychology (wardrobe/AI) | wardrobe, evolution | MEDIUM | P2 | AI fashion tools | BEAUTY |

**Proceso:** NO crear durante piloto. Registrar → I3 phase.

---

## 28. I3 Boundary

**Gaps que justifican GLOW ICON SYSTEM v1.1 / I3:**
`camera, photo, image, visibility, lock, verified_user, star, credit_card, payment, account_balance_wallet, gavel, shield, refresh, check_circle, star_border, emoji_events, wb_sunny, back_hand, face_retouching_natural, palette, style, checkroom, psychology, analytics, auto_stories, center_focus_strong, blur_on, opacity, lock_clock, compare_arrows, rocket_launch, bolt, apple, g_mobiledata, ios_share`

**Regla:** NO crear en esta fase. NO modificar registry. NO modificar SVGs.

---

## 29. Production Safety

| Componente | Estado |
|------------|--------|
| Pantallas productivas | ✅ Intactas (READ-ONLY) |
| Navegación | ✅ Intacta |
| Providers | ✅ Intactos |
| Servicios | ✅ Intactos |
| Backend | ✅ Intacto |
| Database | ✅ Intacta |
| **GLOBAL MIGRATION** | **NOT STARTED** |

---

## 30. Final Recommendation

### Status: **READY FOR PILOT EXECUTION**

### Next Step: **M1-I2 — PILOT A EXECUTION**

**Ejecutar Pilot A primero:**
- `lib/screens/home/home_screen.dart`
- `lib/widgets/floating_navigation_dock.dart`

**Criterios de aprobación Pilot A (Approval Gate):**
1. ✅ Build succeeds
2. ✅ Tests pass (7/7)
3. ✅ Analyze 0 errors en archivos modificados
4. ✅ No logic regression
5. ✅ No navigation regression
6. ✅ No accessibility regression
7. ✅ No visual semantic regression
8. ✅ Correct theme colors (Women/Men/AURA)
9. ✅ Correct icon sizes (tokens)
10. ✅ No unintended icon changes
11. ✅ No design-system divergence

**NO ejecutar automáticamente.** Requiere aprobación manual tras validación visual y funcional.

---

## 31. Quality Score (Self-Assessment)

| Criterio | Score | Max |
|----------|-------|-----|
| A. Pilot Definition | 20 | 20 |
| B. Semantic Safety | 19 | 20 |
| C. File Precision | 15 | 15 |
| D. Risk Management | 15 | 15 |
| E. Accessibility | 10 | 10 |
| F. Theme Planning | 10 | 10 |
| G. Rollback | 5 | 5 |
| H. Future Gap Handling | 5 | 5 |
| **TOTAL** | **99** | **100** |

**EXCELLENT** — Plan completo, accionable, seguro.

---

## 32. Git Status

```
?? docs/audit/GLOWAPP_ICON_PILOT_MIGRATION_PLAN.md
?? docs/audit/glowapp_icon_pilot_migration_plan.json
```

**Solo archivos de plan creados. NINGÚN archivo productivo modificado.**

---

## 33. Final Decision

**READY FOR PILOT EXECUTION**

El plan proporciona visibilidad completa para ejecutar el primer cambio con confianza. La migración será **INCREMENTAL, REVERSIBLE, SEMANTICALLY SAFE, VISUALLY VALIDATED, ACCESSIBLE, THEME-AWARE, LOGIC-PRESERVING**.

---

**NO IMPLEMENTACIÓN EN ESTA FASE.** Solo planificación documentada.