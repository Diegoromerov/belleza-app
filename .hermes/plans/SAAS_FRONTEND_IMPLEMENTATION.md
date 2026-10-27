# Plan de Implementación: Frontend SaaS (Flutter + Admin Dashboard)

**Objetivo:** Exponer funcionalidades SaaS backend (`/api/saas/*`) en la UI para que salones gestionen Team, Billing, Usage, API Keys y Subscription.

---

## 1. Flutter App (Consumer) — `frontend/lib/`

### 1.1 Modelos de datos (`models/saas/`)
| Archivo | Descripción |
|---------|-------------|
| `business_profile.dart` | `BusinessProfile`, `Membership`, `Plan` (FREE_TRIAL, STARTER, PROFESSIONAL, ENTERPRISE) |
| `team_member.dart` | `TeamMember`, `Role` (OWNER, ADMIN, MANAGER, STAFF), `Invitation` |
| `billing.dart` | `Invoice`, `Subscription`, `PaymentMethod`, `CheckoutSession` |
| `usage.dart` | `UsageMetrics`, `Limit`, `Alert` (api_calls, bookings, staff, storage) |
| `api_key.dart` | `ApiKey`, `Scopes`, `RateLimit` |

### 1.2 Servicios API (`services/`)
| Archivo | Métodos a agregar en `api_service.dart` o nuevo `saas_api_service.dart` |
|---------|--------------------------------------------------------------------------|
| **Team** | `getTeamMembers(businessId)`, `inviteMember(businessId, email, role)`, `updateMemberRole(businessId, memberId, role)`, `removeMember(businessId, memberId)`, `resendInvitation(businessId, invitationId)` |
| **Billing** | `getInvoices(businessId)`, `getSubscription(businessId)`, `createCheckoutSession(businessId, planId)`, `getPaymentMethods(businessId)`, `attachPaymentMethod(businessId, pmId)`, `downloadInvoicePdf(invoiceId)` |
| **Usage** | `getUsageMetrics(businessId)`, `getLimits(businessId)`, `getUsageAlerts(businessId)` |
| **API Keys** | `getApiKeys(businessId)`, `createApiKey(businessId, name, scopes)`, `revokeApiKey(businessId, keyId)`, `rotateApiKey(businessId, keyId)` |
| **Business Profile** | `createBusinessProfile(data)`, `getBusinessProfile(businessId)`, `updateBusinessProfile(businessId, data)`, `onboardingComplete(businessId)` |

### 1.3 Pantallas (`screens/saas/`)
| Ruta | Pantalla | Descripción |
|------|----------|-------------|
| `/saas/onboarding` | `SaasOnboardingScreen` | Paso a paso: nombre, slug, plan, pago (si no FREE_TRIAL) → crea `business_profile` + membership OWNER |
| `/saas/team` | `TeamManagementScreen` | Lista miembros, invitar, cambiar rol, revocar, reenviar invitación |
| `/saas/billing` | `BillingScreen` | Suscripción actual, facturas (lista + PDF), métodos de pago, upgrade/downgrade plan |
| `/saas/usage` | `UsageScreen` | Dashboard métricas (barras/progreso), límites, alertas, historial |
| `/saas/apikeys` | `ApiKeysScreen` | Lista keys, crear nueva (nombre + scopes), revocar, rotar, copiar key |
| `/saas/settings` | `SaasSettingsScreen` | Configuración general del negocio (nombre, slug, timezone, moneda) |

### 1.4 Navegación y Entry Points
- **SalonDashboardScreen** (`salon_dashboard_screen.dart:392`) → ya muestra `plan_saas` → agregar botón "Gestionar SaaS" que navegue a `/saas/team` (o onboarding si no hay `business_profile`)
- **OwnerDashboardScreen** → agregar sección SaaS
- **Router** (`main.dart` o `router.dart`) → registrar rutas `/saas/*` con guard de autenticación + `business_profile` requerido

### 1.5 Estado y Providers
- `BusinessProfileProvider` (Riverpod/Provider) → cache `business_profile` + `membership` del usuario logueado
- `SaasApiProvider` → wrappers con retry, error handling, loading states

---

## 2. Admin Dashboard (Next.js) — `admin-dashboard/src/`

### 2.1 Sidebar (`components/dashboard/Sidebar.tsx:56-68`)
Agregar sección **SaaS SuperAdmin**:
```tsx
{ href: '/admin/saas/tenants', label: 'Tenants SaaS', icon: Users },
{ href: '/admin/saas/billing', label: 'Facturación Global', icon: CreditCard },
{ href: '/admin/saas/usage', label: 'Uso Global', icon: BarChart },
{ href: '/admin/saas/plans', label: 'Planes y Precios', icon: Settings },
```

### 2.2 Páginas SuperAdmin (`app/(dashboard)/admin/saas/`)
| Ruta | Componente | Descripción |
|------|------------|-------------|
| `/admin/saas/tenants` | `SaasTenantsPage` | Lista todos los `business_profiles`, filtros por plan, estado, búsqueda; acciones: ver detalle, suspender, cambiar plan, ver métricas |
| `/admin/saas/billing` | `SaasBillingPage` | Vista global: MRR, churn, facturas pendientes, dunning, exportar CSV |
| `/admin/saas/usage` | `SaasUsagePage` | Agregados: API calls totales, bookings, staff, storage por tenant; top consumers |
| `/admin/saas/plans` | `SaasPlansPage` | CRUD planes: nombre, precio, límites (staff, api_calls, bookings, storage), features, trial_days |

### 2.3 API Client (`lib/api/saas.ts`)
```typescript
export const saasApi = {
  tenants: { list, get, update, suspend, changePlan },
  billing: { getInvoices, getMetrics, export },
  usage: { getAggregates, getTopConsumers },
  plans: { list, create, update, delete },
}
```

---

## 3. Backend — Verificación de Endpoints (ya existen)

| Endpoint | Método | Auth | Response |
|----------|--------|------|----------|
| `/api/saas/business-profiles` | POST/GET | JWT + membership | `BusinessProfile` |
| `/api/saas/business-profiles/:id` | GET/PUT/DELETE | JWT + membership (OWNER/ADMIN) | `BusinessProfile` |
| `/api/saas/team` | GET | JWT + membership | `TeamMember[]` |
| `/api/saas/team/invite` | POST | JWT + membership (OWNER/ADMIN) | `Invitation` |
| `/api/saas/team/:memberId` | PUT/DELETE | JWT + membership (OWNER/ADMIN) | `TeamMember` |
| `/api/saas/billing/subscription` | GET | JWT + membership | `Subscription` |
| `/api/saas/billing/checkout` | POST | JWT + membership (OWNER/ADMIN) | `CheckoutSession` |
| `/api/saas/billing/invoices` | GET | JWT + membership | `Invoice[]` |
| `/api/saas/usage` | GET | JWT + membership | `UsageMetrics` |
| `/api/saas/apikeys` | GET/POST | JWT + membership (OWNER/ADMIN) | `ApiKey[]` / `ApiKey` |
| `/api/saas/apikeys/:keyId` | DELETE/PUT | JWT + membership (OWNER/ADMIN) | `ApiKey` |

---

## 4. Secuencia de Ejecución (Fases)

### Fase 1: Flutter — Modelos + Servicios (2-3 días)
- [ ] Crear `models/saas/*.dart` (5 archivos)
- [ ] Crear `services/saas_api_service.dart` con todos los métodos
- [ ] Agregar `SaasApiProvider` / `BusinessProfileProvider`
- [ ] Tests unitarios de modelos y serialización

### Fase 2: Flutter — Onboarding + Team (3-4 días)
- [ ] `SaasOnboardingScreen` (multi-step form, validación slug único)
- [ ] `TeamManagementScreen` (lista, invitar, editar rol, revocar)
- [ ] Integración en `SalonDashboardScreen` → botón "Gestionar mi negocio"
- [ ] Guard de ruta: redirigir a onboarding si no hay `business_profile`

### Fase 3: Flutter — Billing + Usage + API Keys (4-5 días)
- [ ] `BillingScreen` (suscripción, facturas, checkout Stripe)
- [ ] `UsageScreen` (gráficos de progreso vs límites, alertas)
- [ ] `ApiKeysScreen` (crear, revocar, rotar, copy-to-clipboard)
- [ ] `SaasSettingsScreen`

### Fase 4: Admin Dashboard — SuperAdmin SaaS (3-4 días)
- [ ] Sidebar: agregar sección SaaS
- [ ] `SaasTenantsPage` (tabla + acciones)
- [ ] `SaasBillingPage` (KPIs + tabla facturas)
- [ ] `SaasUsagePage` (gráficos agregados)
- [ ] `SaasPlansPage` (CRUD planes)

### Fase 5: Integración y QA (2-3 días)
- [ ] E2E: registro → onboarding → invitar equipo → upgrade plan → crear API key
- [ ] Verificar emails transaccionales (trial ending, invoice, dunning, invitación)
- [ ] Pruebas de límites (usage alerts, hard limits)
- [ ] Deploy staging → validación con usuario real

---

## 5. Dependencias Técnicas

| Paquete | Uso |
|---------|-----|
| `flutter_riverpod` / `provider` | State management (ya en proyecto) |
| `fl_chart` | Gráficos en `UsageScreen` |
| `url_launcher` | Checkout Stripe (abrir URL externa) |
| `share_plus` | Compartir API key |
| `pdf` / `printing` | Descargar factura PDF (opcional, backend ya genera) |

---

## 6. Criterios de Aceptación (Definition of Done)

- [ ] Usuario salon puede: registrarse → onboarding SaaS → ver su plan → invitar 2 staff → ver límites de uso → crear API key → hacer upgrade a plan pagado
- [ ] SuperAdmin puede: ver todos los tenants → suspender uno → cambiar plan forzado → ver MRR global → exportar facturas
- [ ] Emails transaccionales llegan (trial ending, invoice emitted, dunning, team invite)
- [ ] Build Flutter web + Admin Dashboard deployan sin errores en Railway
- [ ] 0 errores `flutter analyze`, 0 warnings TypeScript/ESLint

---

## 7. Estimación Total: ~14-19 días laborables

| Fase | Días |
|------|------|
| 1. Modelos + Servicios | 3 |
| 2. Onboarding + Team | 4 |
| 3. Billing + Usage + API Keys | 5 |
| 4. Admin Dashboard SaaS | 4 |
| 5. Integración + QA | 3 |
| **Total** | **19** |

---

## 8. Próximo Paso Inmediato

**Autorización requerida:** `AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — F7.006-FASE7-SAAS-FRONTEND`

Una vez autorizado, iniciar **Fase 1** (modelos + servicios Flutter).