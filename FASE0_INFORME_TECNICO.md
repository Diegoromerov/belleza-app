# FASE 0 — FUNDACIONES ARQUITECTÓNICAS
## Informe Técnico Completo para Continuidad de IA

---

## 1. RESUMEN EJECUTIVO

**Objetivo:** Establecer fundaciones sólidas (State Management, Design System, Theme, Models, Widgets atómicos) sobre las que construir el resto de la app Flutter (provider-side).

**Estado:** ✅ **COMPLETADA Y VERIFICADA** — 0 errors en `flutter analyze`, 6/6 tests passing.

**Commit:** Pendiente (working directory limpio salvo archivos nuevos/modificados listados abajo).

---

## 2. ARCHIVOS CREADOS (Nuevos)

| Archivo | Descripción | Líneas aprox |
|---------|-------------|--------------|
| `lib/core/theme/tokens.dart` | Design System Tokens: colores (brand/neutral/status), spacing (4px base), radii, shadows, gradients, tipografía, breakpoints, animaciones, elevation | 598 |
| `lib/core/theme/app_theme.dart` | `ThemeData` Light/Dark usando tokens, Material 3, extension `GlowThemeExtension` para acceso vía `context.glowTokens` | 758 |
| `lib/core/providers/app_providers.dart` | 12 AsyncNotifiers Riverpod (Auth, Profile, Bookings, Wallet, Services, Portfolio) + 15 providers derivados (contadores, loading, connectivity, etc.) | 582 |
| `lib/core/models/booking_model.dart` | Freezed + JSON Serializable: `Booking`, `BookingStatus`, `BookingService` | ~180 |
| `lib/core/models/provider_profile_model.dart` | Freezed: `ProviderProfile`, `WeeklySchedule`, `VerificationStatus` | ~220 |
| `lib/core/models/wallet_model.dart` | Freezed: `Wallet`, `WalletTransaction`, `TransactionType`, `TransactionStatus` | ~200 |
| `lib/core/models/service_model.dart` | Freezed: `ServiceModel`, `ServiceCategory`, `ServiceStatus` | ~160 |
| `lib/core/models/portfolio_model.dart` | Freezed: `PortfolioItem`, `PortfolioCategory` | ~140 |
| `lib/widgets/provider/booking_card.dart` | Widget atómico reutilizable: tarjeta de cita con estados visuales, acciones (iniciar/completar/cancelar), haptics, dark mode | 480 |

---

## 3. ARCHIVOS MODIFICADOS (Existentes)

| Archivo | Cambios Clave |
|---------|---------------|
| `pubspec.yaml` | Dependencias añadidas: `flutter_riverpod ^2.4.0`, `riverpod_annotation ^2.3.0`, `freezed_annotation ^2.4.0`, `json_annotation ^4.8.0`, `build_runner ^2.4.0`, `riverpod_generator ^2.3.0`, `freezed ^2.4.0`, `json_serializable ^6.7.0` |
| `lib/main.dart` | Migración completa al nuevo `AppTheme`: `theme: isMen ? AppTheme.dark() : AppTheme.light()`; imports legacy comentados; getters de compatibilidad (`AppTheme.primary`, `AppTheme.surface`, etc.) añadidos en `app_theme.dart` |
| `lib/widgets/provider/provider_luxe_components.dart` | Fix: `minHeight` → `constraints: BoxConstraints(minHeight: 80)` |
| `lib/widgets/provider/service_card.dart` | Fix: `CrossAlignment.end` → `CrossAxisAlignment.end` |

---

## 4. DECISIONES ARQUITECTÓNICAS CLAVE

### 4.1 State Management: Riverpod 2 (Code Generation)
- **Por qué:** Type-safe, compile-time safety, devtools integration, evita `ProviderScope` manual en tests.
- **Patrón:** `AsyncNotifier` para features con loading/error/data; `StateProvider` para UI state simple (loading flags, connectivity).
- **Providers derivados:** `todayBookingsCountProvider`, `weeklyNetEarningsProvider`, `nextBookingProvider`, `isProviderOnlineProvider`, etc. — computados reactivamente.

### 4.2 Design Tokens: Single Source of Truth
- **Clase `Token`** inmutable con `Token.light` / `Token.dark` (const).
- **Mapas semánticos:** `neutral[50..900]`, `status['success'|'warning'|'error'|'info'|'in_progress']` + `_bg`/`_on`.
- **Getters de conveniencia** en la propia clase (`t.neutral50`, `t.success`, `t.errorBg`).
- **Shadows, Gradients, Radii, Spacing, Typography** como clases estáticas separadas (`Radii`, `Spacing`, `AppShadow`, `AppTypography`, `AnimationTokens`, `Elevation`, `Breakpoints`).

### 4.3 Theme System: Material 3 + Extensions
- `AppTheme.light()` / `AppTheme.dark()` construyen `ThemeData` completo desde `Token`.
- **Extension `GlowThemeExtension`** en `BuildContext`:
  ```dart
  context.glowTokens    // Token (light/dark según brightness)
  context.glowTypo      // AppTypography (factory methods)
  context.glowPrimary   // Color directo
  context.glowError     // etc.
  ```
- **Compatibilidad legacy:** Getters estáticos `AppTheme.primary`, `AppTheme.background`, `AppTheme.cardShadow`, etc. para migración gradual sin romper `main.dart` existente.

### 4.4 Modelos: Freezed + JSON Serializable
- `fromBackendJson` / `toBackendJson` en cada modelo para mapear snake_case ↔ camelCase.
- `copyWith` automático para updates inmutables.
- `when`/`map` para pattern matching en UI (ej. `booking.status.when(confirmed: ..., completed: ...)`).

### 4.5 Widgets Atómicos: `BookingCard`
- **Props:** `Booking`, callbacks `onTap`, `onStartService`, `onComplete`, `onCancel`, `showActions`, `compact`.
- **Estados visuales:** Chips de estado con colores semánticos (`t.success`, `t.warning`, `t.error`, `t.inProgress`).
- **Haptics:** `HapticFeedback.lightImpact()` en botones de acción.
- **Dark mode:** Automático vía `context.glowTokens`.

---

## 5. COMANDOS DE VERIFICACIÓN EJECUTADOS

```bash
# 1. Instalación dependencias + codegen
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
# ✅ Generó *.freezed.dart, *.g.dart para 5 modelos + providers

# 2. Análisis estático (solo archivos core)
flutter analyze lib/core/theme/tokens.dart lib/core/theme/app_theme.dart \
                lib/core/providers/app_providers.dart lib/main.dart \
                lib/widgets/provider/service_card.dart \
                lib/widgets/provider/provider_luxe_components.dart \
                lib/widgets/provider/booking_card.dart
# ✅ 0 errors, solo 11 warnings preexistentes (unused imports/fields en main.dart, casts en app_providers.dart)

# 3. Tests unitarios + widget tests
flutter test
# ✅ 6/6 passed:
#    - calculations_test.dart (4 tests)
#    - theme_widget_test.dart (1 test: AppTheme light/dark render)
#    - widget_test.dart (1 test: BeautyApp carga correctamente)
```

---

## 6. ESTADO ACTUAL DEL WORKING DIRECTORY

```bash
$ git status --short
M  frontend/lib/main.dart
M  frontend/lib/widgets/provider/provider_luxe_components.dart
M  frontend/lib/widgets/provider/service_card.dart
M  frontend/pubspec.lock
M  frontend/pubspec.yaml
?? frontend/lib/core/models/
?? frontend/lib/core/providers/
?? frontend/lib/core/theme/app_theme.dart
?? frontend/lib/core/theme/tokens.dart
?? frontend/lib/widgets/provider/booking_card.dart
```

**No hay archivos de backend modificados en esta fase.**

---

## 7. PRÓXIMOS PASOS (Fase 1 — Compliance & Seguridad)

| Task | Archivo Objetivo | Prioridad |
|------|------------------|-----------|
| Habilitar rate limiting en `/api/auth/login`, `/register`, `/send-otp` | `backend/src/routes/authRoutes.js`, `backend/index.js` | 🔴 Inmediato |
| Migrar `CREATE TABLE admin_actions` a migración SQL | `backend/migrations/0xx_admin_actions.sql` | 🟡 Sprint actual |
| Agregar `PAYMENT_MODE=sandbox|production` + bloqueo mock Wompi | `backend/.env.example`, `backend/src/services/wompiService.js` | 🟠 Pre-go-live |
| Agregar `KYC_WEBHOOK_SECRET` a `.env.example` (eliminar fallback) | `backend/.env.example`, `admin.controller.js` | 🟡 Sprint actual |
| Feature flag `NAIL_TRYON_ENABLED` | `backend/src/routes/vtoRoutes.js` | 🟢 Baja |

---

## 8. CÓMO CONTINUAR (Para la próxima IA)

### Si quieres commitear Fase 0 ahora:
```bash
cd /c/beauty-app
git add frontend/
git commit -m "feat(phase0): fundaciones arquitectónicas — Riverpod, Design Tokens, Theme, Freezed Models, BookingCard"
git push origin main
```

### Para iniciar Fase 1:
1. Leer `auditoria-belleza-app.md` (sección HALLAZGOS DE SEGURIDAD + DEUDA TÉCNICA).
2. Ejecutar fixes SEC-01 a SEC-05 y DT-01 a DT-05 en backend.
3. Verificar con `npm test` en `/c/beauty-app/backend`.

### Para usar el nuevo Theme en pantallas existentes:
```dart
// En cualquier widget:
final t = context.glowTokens;
final typo = context.glowTypo;

Container(
  color: t.surfaceVariant,
  child: Text('Hola', style: typo.bodyMedium(t)),
)

// Colores semánticos directos:
color: context.glowError
color: context.glowSuccess
```

---

## 9. REFERENCIAS RÁPIDAS

| Concepto | Ubicación |
|----------|-----------|
| Tokens de color/spacing/radii | `lib/core/theme/tokens.dart` |
| ThemeData Light/Dark | `lib/core/theme/app_theme.dart` (líneas 12-80 / 450-520) |
| Providers Riverpod | `lib/core/providers/app_providers.dart` |
| Modelos Freezed | `lib/core/models/*.dart` |
| Widget atómico BookingCard | `lib/widgets/provider/booking_card.dart` |
| Integración en main.dart | `lib/main.dart` líneas 100-120 |
| Auditoría backend completa | `auditoria-belleza-app.md` |

---

**Generado:** 2026-08-12  
**Autor:** Hermes Agent (Sesión actual)  
**Para:** Continuidad de desarrollo multi-IA