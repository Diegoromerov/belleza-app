# Fase 2: Onboarding Unificado SaaS + Team Management Screens

**Objetivo:** Unificar onboarding existente (`onboarding_screen.dart`) con SaaS (plan, team) → una sola pantalla.
Luego crear pantallas Team Management para gestión posterior.

---

## 1. Análisis de `onboarding_screen.dart` (líneas 32-53, 200-400 aprox)

**Campos actuales (rol SALON):**
- `_salonNameCtrl` — nombre salón
- `_salonNitCtrl` — NIT
- `_salonAddressCtrl` — dirección
- `_salonPhoneCtrl` — teléfono
- `_salonCityCtrl` — ciudad
- Mapa: `_salonLocation`, `_salonLocationConfirmed`, `_salonLocationPublic`
- Dirección estructurada Colombia: `_viaType`, `_viaNumCtrl`, `_generatorNumCtrl`, `_plateNumCtrl`, `_complementCtrl`

**Flujo actual:**
1. Selecciona rol SALON
2. Completa formulario + mapa
3. POST `/api/auth/register` con `role: "SALON"` + datos
4. Backend crea `users` + `business_profiles` (Business Engine)

---

## 2. Cambios Requeridos en `onboarding_screen.dart`

### 2.1 Agregar imports SaaS
```dart
import '../../models/saas/saas_models.dart';
import '../../services/saas_api_service.dart';
import '../../providers/saas_providers.dart';
```

### 2.2 Agregar estado SaaS
```dart
SaasPlanTier _selectedPlan = SaasPlanTier.freeTrial;
final List<TeamInvitationRequest> _teamInvites = []; // email + role
bool _isCreatingSaasProfile = false;
```

### 2.3 UI: Selector de Plan (después de datos básicos, antes de mapa)
```dart
// RadioGroup o SegmentedButton con SaasPlanTier.values
// Mostrar: tier.label, tier.formattedPrice, límites clave (staff, api_calls)
```

### 2.4 UI: Invitar Equipo (opcional, expandible)
```dart
// "Agregar miembro" → dialog: email + role (ADMIN/MANAGER/STAFF)
// Lista chips con botón eliminar
```

### 2.5 Modificar `_handleSalonRegister()` / submit
```dart
// ANTES: POST /api/auth/register con role=SALON
// DESPUÉS: 
// 1. POST /api/auth/register (solo user auth)
// 2. POST /api/saas/business-profiles con CreateBusinessProfileRequest:
//    - name, slug (generado desde name), description, timezone, currency, plan_id
//    - team_invites: [{email, role}, ...]
// 3. Backend crea: user + business_profile + membership (OWNER) + invitations + subscription (trial)
```

### 2.6 Manejo de errores y loading
```dart
// _isCreatingSaasProfile para deshabilitar botón
// SnackBar específicos por error (plan, slug duplicado, email inválido)
```

---

## 3. Pantallas Team Management (post-onboarding)

### 3.1 `lib/screens/saas/team_management_screen.dart`
**Ruta:** `/saas/team`
**Estado:** `ConsumerWidget` usando `teamProvider` + `currentBusinessProfileIdProvider`

**UI:**
- AppBar: "Mi Equipo" + botón "Invitar"
- Lista `TeamMember`:
  - Avatar + nombre + email
  - Chip rol (color según `MembershipRole.color`)
  - Badge "Pendiente" si `isPending`
  - Menú (3 dots): Cambiar rol / Revocar / Reenviar invitación
- Sección "Invitaciones Pendientes":
  - Email + rol + botón "Reenviar" + "Cancelar"

**Acciones:**
- `invite()` → `TeamNotifier.invite()`
- `updateRole()` → `TeamNotifier.updateRole()`
- `remove()` → `TeamNotifier.remove()`
- `resendInvitation()` → `TeamNotifier.resendInvitation()`

### 3.2 `lib/screens/saas/invite_member_dialog.dart`
**Dialog reutilizable** para invitar/editar miembro.

---

## 4. Integración Navegación

### 4.1 `main.dart` / router
```dart
GoRoute(
  path: '/saas/team',
  builder: (context, state) => const TeamManagementScreen(),
),
GoRoute(
  path: '/saas/onboarding',
  builder: (context, state) => const SaasOnboardingScreen(), // si se separa
),
```

### 4.2 Entry point desde `SalonDashboardScreen`
```dart
// Línea 392: ya muestra plan_saas
// Agregar botón "Gestionar mi negocio" → navega a /saas/team
// Si no hay business_profile → navega a onboarding unificado
```

---

## 5. Backend - Verificar contrato

**Endpoint:** `POST /api/saas/business-profiles`
```json
{
  "name": "Mi Salón",
  "slug": "mi-salon",
  "description": "",
  "timezone": "America/Bogota",
  "currency": "COP",
  "plan_id": "FREE_TRIAL",
  "team_invites": [
    {"email": "staff@email.com", "role": "STAFF"}
  ]
}
```

**Response:** `SaasBusinessProfile` + `Membership` + `Subscription` + `TeamInvitation[]`

---

## 6. Secuencia de Implementación

| Paso | Archivo | Acción |
|------|---------|--------|
| 1 | `onboarding_screen.dart` | Agregar imports, estado plan/team, UI selector plan + invites |
| 2 | `onboarding_screen.dart` | Modificar submit → llamar `SaasApiService.createBusinessProfile()` |
| 3 | `team_management_screen.dart` | Crear pantalla completa con Riverpod |
| 4 | `invite_member_dialog.dart` | Dialog reutilizable |
| 5 | `main.dart` / router | Registrar rutas `/saas/team` |
| 6 | `salon_dashboard_screen.dart` | Agregar botón "Gestionar mi negocio" |
| 7 | Test: flutter analyze + build web |

---

## 7. Criterios de Aceptación Fase 2

- [ ] Usuario SALON registra: user + business_profile SaaS + plan + team invites en **una sola pantalla**
- [ ] Plan FREE_TRIAL por defecto, editable a STARTER/PRO (sin pago en onboarding)
- [ ] Invitaciones de equipo se envían (email transaccional `teamInvite`)
- [ ] Post-login: botón "Gestionar mi negocio" → `/saas/team` muestra miembros + invitaciones
- [ ] Acciones team: cambiar rol, revocar, reenviar funcionan
- [ ] 0 errores `flutter analyze`, build web OK

---

## 8. Autorización Requerida

```
AUTORIZACIÓN EXPLÍCITA DEL DIRECTOR — F7.006-FASE7-SAAS-FRONTEND-FASE2
```