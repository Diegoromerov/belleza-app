# Fase 3: Billing, Usage & API Keys Screens

**Objetivo:** Pantallas SaaS para facturación (planes, suscripción, facturas, checkout Stripe), métricas de uso y gestión de API Keys.

---

## 1. Pantallas Requeridas

| Pantalla | Ruta | Provider | Descripción |
|----------|------|----------|-------------|
| `BillingScreen` | `/saas/billing` | `billingProvider` | Plan actual, upgrade/downgrade, historial facturas, métodos de pago |
| `UsageScreen` | `/saas/usage` | `usageProvider` | Gráficos uso (staff, API calls, bookings), alertas, límites por plan |
| `ApiKeysScreen` | `/saas/api-keys` | `apiKeysProvider` | Listar, crear, revocar API keys con scopes |

---

## 2. BillingScreen (`/saas/billing`)

**Estado:** `ConsumerWidget` usando `billingProvider` + `plansProvider`

**UI:**
- **Plan Actual**: Card con tier, precio, estado (trial/active/past_due/canceled), días restantes trial
- **Cambiar Plan**: Lista planes disponibles (STARTER/PRO/ENTERPRISE) → botón "Cambiar" abre checkout Stripe
- **Facturas**: Lista `Invoice` (número, fecha, monto, estado, PDF)
- **Métodos de Pago**: Tarjetas guardadas (Stripe PaymentMethod) + "Agregar tarjeta"
- **Próximo cobro**: Fecha + monto

**Acciones:**
- `createCheckoutSession()` → redirige a Stripe Checkout
- `downloadInvoice(invoiceId)` → PDF
- `addPaymentMethod()` → Stripe Billing Portal o SetupIntent
- `cancelSubscription()` → confirmación + llamada API

---

## 3. UsageScreen (`/saas/usage`)

**Estado:** `ConsumerWidget` usando `usageProvider`

**UI:**
- **Resumen**: `UsageSummary` con tarjetas KPI (staff actual, API calls mes, bookings mes, storage)
- **Gráficos** (fl_chart):
  - Línea: API calls últimos 30 días
  - Barras: Bookings por día/semana
  - Pie: Distribución uso por feature
- **Alertas**: `UsageAlert` activas (warning/critical) con badge color
- **Límites del Plan**: Tabla comparativa actual vs límite (staff, API, storage)

**Acciones:**
- Refresh manual
- Configurar alertas (umbrales personalizados)

---

## 4. ApiKeysScreen (`/saas/api-keys`)

**Estado:** `ConsumerWidget` usando `apiKeysProvider`

**UI:**
- **Lista API Keys**: Nombre, prefijo (gsk_...), scopes (badges), última uso, estado (activa/revocada), creada
- **Crear Key**: Dialog → nombre + scopes (checkboxes: bookings:read, bookings:write, clients:read, etc.) → muestra key **una sola vez** al crear
- **Revocar**: Confirmación → `revokeApiKey()`

**Acciones:**
- `createApiKey(CreateApiKeyRequest)` → muestra key + copy to clipboard
- `revokeApiKey(keyId)` → soft delete
- Copy key al clipboard (solo al crear)

---

## 5. Integración Navegación

**main.dart** - agregar rutas:
```dart
'/saas/billing': (_) => const BillingScreen(),
'/saas/usage': (_) => const UsageScreen(),
'/saas/api-keys': (_) => const ApiKeysScreen(),
```

**SalonDashboardScreen** / **TeamManagementScreen** - tabs o drawer navegan a estas 3 pantallas.

---

## 6. Dependencias

- `fl_chart: ^0.68.0` ✅ (ya en pubspec.yaml)
- `url_launcher: ^6.2.0` (para Stripe Checkout URL)
- `share_plus: ^12.0.2` ✅ (para compartir API key)

---

## 7. Secuencia Implementación

| Paso | Archivo | Acción |
|------|---------|--------|
| 1 | `billing_screen.dart` | Crear pantalla completa |
| 2 | `usage_screen.dart` | Crear pantalla con gráficos fl_chart |
| 3 | `api_keys_screen.dart` | Crear pantalla CRUD API keys |
| 4 | `main.dart` | Registrar 3 rutas + imports |
| 5 | `salon_dashboard_screen.dart` | Agregar navegación (tabs/drawer) |
| 6 | `team_management_screen.dart` | Agregar navegación a billing/usage/api-keys |
| 7 | Test: flutter analyze + build web |

---

## 8. Criterios Aceptación Fase 3

- [ ] `/saas/billing`: Muestra plan actual, permite upgrade via Stripe Checkout, lista facturas con PDF
- [ ] `/saas/usage`: Gráficos interactivos (fl_chart), alertas visuales, límites por plan
- [ ] `/saas/api-keys`: CRUD completo, key mostrada una vez al crear, copy to clipboard
- [ ] Navegación integrada desde dashboard y team management
- [ ] 0 errores `flutter analyze`, build web OK

---

## 9. Autorización Requerida

```
AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — F7.006-FASE7-SAAS-FRONTEND-FASE3
```