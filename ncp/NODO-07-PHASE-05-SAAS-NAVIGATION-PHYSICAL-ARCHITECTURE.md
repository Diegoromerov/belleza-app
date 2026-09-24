# NODO-07 — FASE 5 — ARQUITECTURA FÍSICA DE NAVEGACIÓN SAAS
**Document ID**: NODO-07-PHASE-05-SAAS-NAVIGATION-PHYSICAL-ARCHITECTURE  
**Status**: APPROVED / ARCHITECTURE SPECIFIED (AWAITING IMPLEMENTATION AUTHORIZATION)  
**Date**: 2026-09-12  
**Author**: Director del Proyecto GlowApp SaaS / Agentic System Architecture  
**Scope**: Especificación física y diseño de integración de navegación para el Hub Salón en Flutter.  
**Rule**: ZERO CODE IMPLEMENTATION. PHYSICAL ARCHITECTURE DESIGN ONLY.

---

## 1. EXECUTIVE SUMMARY

El presente documento define la **Arquitectura Física Formal** para integrar el flujo de navegación de GlowApp SaaS dentro de la aplicación Flutter existente, conectando los componentes físicos cerrados e inmutables:
- `AvailableContextSelectorScreen` (NODO-07 Fase 3 — CLOSED)
- `ActiveContextHolder` (NODO-07 Fase 1 — CLOSED)
- `HubSalonScreen` (NODO-07 Fase 4 — CLOSED)

### Decisiones Arquitectónicas Clave:
1. **Ruta Canónica Única (`/saas/hub`)**: Se aprueba como único objetivo físico de enrutamiento la ruta `'/saas/hub' -> (_) => const HubSalonScreen()`. [FACT / PROPOSAL]
2. **Descarte de `/saas/context/available` (Regla: No Route Without Consumer)**: Dado que `HubSalonScreen` invoca directamente `AvailableContextSelectorScreen` mediante `MaterialPageRoute` y ningún componente requiere navegación por nombre hacia el selector, **NO se registrará** la ruta `/saas/context/available`. [FACT]
3. **Cero Guards Globales**: No se implementarán `SaaSRouteGuard`, `ActiveContextGuard` ni middlewares Flutter en `main.dart`. Si se navega a `/saas/hub` sin contexto, `HubSalonScreen` gestiona autónomamente el estado `active_context_missing`. [FACT]
4. **Cambio Mínimo en `main.dart`**: La futura implementación requerirá exactamente **1 import** y **1 línea en el mapa `routes`**, dejando intactas todas las rutas B2C y el flujo de Auth. [PROPOSAL]
5. **Aislamiento Absoluto de Journey y B2C**: Journey permanece en **`ARCHITECTURAL STOP`**. Cero detección automática de rol o desvío condicional en `LoginScreen` y `RegisterScreen`. [ARCHITECTURAL STOP]

---

## 2. CURRENT NAVIGATION EVIDENCE

### 2.1 Evidencia Forense en `frontend/lib/main.dart`
- **Mecanismo**: `MaterialApp` con diccionario declarativo de rutas:
  ```dart
  routes: <String, WidgetBuilder>{
    '/login': (_) => const LoginScreen(),
    '/register': (_) => const RegisterScreen(),
    '/home': (_) => const ProvidersScreen(),
    '/provider': (_) => const ProviderDashboardScreen(),
    ...
  }
  ```
- **Ruta Inicial**: `initialRoute: '/home'`.
- **Navegador**: `NotificationService.navigatorKey`.
- **Clasificación**: `FACT` (Verificado en `main.dart`).

### 2.2 Evidencia en `available_context_selector_screen.dart`
- **Mecanismo de Salida**: Línea 84 invoca `Navigator.of(context).pushReplacementNamed('/saas/hub')` cuando el callback `onContextSelected` es nulo.
- **Clasificación**: `FACT` (Implementación cerrada en Fase 3).

### 2.3 Evidencia en `hub_salon_screen.dart`
- **Manejo de Contexto Nulo**: Líneas 59-73 activan `_activeContextMissing = true` si `activeMembershipId == null`.
- **Mecanismo de Cambio de Sede**: Líneas 133-153 ejecutan `Navigator.push(MaterialPageRoute(builder: (_) => const AvailableContextSelectorScreen()))`.
- **Clasificación**: `FACT` (Implementación cerrada en Fase 4).

---

## 3. CANONICAL `/saas/hub` ROUTE SPECIFICATION

### 3.1 Definición Técnica
- **Nombre de Ruta**: `'/saas/hub'`.
- **Widget Destino**: `HubSalonScreen`.
- **Constructor**: `const HubSalonScreen()`.
- **Import Requerido**: `import 'screens/saas/hub_salon_screen.dart';`.
- **Compatibilidad**: 100% compatible con el mapa `routes` de `MaterialApp`.
- **Clasificación**: `PROPOSAL` (Aprobado como objetivo de implementación).

### 3.2 Comportamiento en Tiempo de Ejecución
| Contexto Activo | Estado Resultante en Hub | Comportamiento en UI |
| :--- | :--- | :--- |
| **`activeMembershipId != null`** | `_isLoading -> loaded` | Invoca `getCockpitData()` y presenta el Cockpit operacional completo. |
| **`activeMembershipId == null`** | `_activeContextMissing = true` | Cero peticiones de backend. Muestra mensaje explicativo y botón "Seleccionar Sede Operativa". |

---

## 4. `/saas/context/available` ARCHITECTURAL DECISION

### 4.1 Principio: "NO ROUTE WITHOUT CONSUMER"
Se evaluó si es técnicamente necesario registrar `'/saas/context/available'` en `main.dart`:
1. `HubSalonScreen` navega hacia `AvailableContextSelectorScreen` mediante `MaterialPageRoute` directo.
2. Ningún componente en `frontend/lib/` invoca `Navigator.pushNamed('/saas/context/available')`.
3. Registrar rutas no consumidas incrementa la superficie de ataque y el acoplamiento innecesario en `main.dart`.

### 4.2 Decisión Arquitectónica
- **DECISIÓN**: **NO REGISTRAR `/saas/context/available` EN `main.dart`**.
- El selector se mantiene como pantalla modal / flujo directo instanciado bajo demanda.
- **Clasificación**: `FACT / PROPOSAL`.

---

## 5. ACTIVE CONTEXT BOUNDARY

```
┌───────────────────────────────────────────────────────────────────┐
│                      NAVEGACIÓN A '/saas/hub'                     │
└─────────────────────────────────┬─────────────────────────────────┘
                                  │
                                  ▼
                     [ Instancia HubSalonScreen ]
                                  │
                                  ▼
               [ Lee ActiveContextHolder.activeMembershipId ]
                                  │
                 ┌────────────────┴────────────────┐
                 │                                 │
           [ Valor == null ]              [ Valor != null ]
                 │                                 │
                 ▼                                 ▼
   [ Estado: active_context_missing ]     [ Estado: loading -> loaded ]
                 │                                 │
                 ▼                                 ▼
   [ Botón Seleccionar Sede ]             [ Cockpit Operacional SaaS ]
                 │
                 ▼
   [ PUSH AvailableContextSelectorScreen ]
```

### Invariantes de Frontera:
- **CERO GUARDS EN `main.dart`**: Se prohíbe introducir envoltorios tipo `SaaSRouteGuard` que intercepten la ruta.
- **AUTONOMÍA DE PANTALLA**: `HubSalonScreen` es la única responsable de evaluar el estado de `ActiveContextHolder` al montarse.
- **Clasificación**: `FACT`.

---

## 6. AVAILABLE CONTEXT -> HUB FLOW

El flujo de transición desde la selección de sede hacia el Hub se preserva de forma canónica y sin modificaciones:

1. Usuario abre `AvailableContextSelectorScreen`.
2. Usuario realiza una **selección explícita** obligatoria (`DEC-N07-AC-001`).
3. `_handleExplicitSelection` ejecuta:
   ```dart
   ActiveContextHolder().setActiveMembershipId(item.membershipId);
   ```
4. Inmediatamente ejecuta:
   ```dart
   Navigator.of(context).pushReplacementNamed('/saas/hub');
   ```
5. `HubSalonScreen` se monta, lee el `activeMembershipId` recién establecido en RAM y carga los datos de la sede.
- **Clasificación**: `FACT`.

---

## 7. HUB -> AVAILABLE CONTEXT FLOW

El flujo de cambio de sede desde el Hub se preserva de forma canónica y sin modificaciones:

1. Usuario presiona el botón "Cambiar Sede" (`btn_cambiar_sede`) en el AppBar del Hub.
2. `HubSalonScreen._handleContextSwitch()` ejecuta:
   ```dart
   await Navigator.of(context).push(
     MaterialPageRoute(builder: (_) => const AvailableContextSelectorScreen()),
   );
   ```
3. El usuario selecciona una nueva sede en la pantalla superpuesta.
4. `AvailableContextSelectorScreen` actualiza `ActiveContextHolder.setActiveMembershipId(...)`.
5. Al completarse la selección o cerrarse el modal, `HubSalonScreen` compara el `activeMembershipId` actual con `_lastLoadedMembershipId`.
6. Si detecta un cambio, dispara automáticamente `_loadCockpitData()` para la nueva sede.
- **Clasificación**: `FACT`.

---

## 8. `MAIN.DART` INTEGRATION BOUNDARY

### 8.1 Alcance Exacto de Modificación Futura
La futura Fase 5 de Implementación se limitará estrictamente a realizar la siguiente modificación mínima en `frontend/lib/main.dart`:

```diff
--- a/frontend/lib/main.dart
+++ b/frontend/lib/main.dart
@@ -60,6 +60,7 @@
 import 'models/provider_model.dart';
 import 'shared/theme.dart';
+import 'screens/saas/hub_salon_screen.dart';
 
 import 'dart:async';
 import 'package:flutter/foundation.dart';
@@ -212,6 +213,7 @@
                 '/wardrobe': (_) => const WardrobeDashboardScreen(),
                 '/outfit-result': (_) => const OutfitResultScreen(),
+                '/saas/hub': (_) => const HubSalonScreen(),
               },
             );
           },
```

### 8.2 Invariantes de `main.dart`:
- **CERO MODIFICACIÓN** de `initialRoute` (permanece en `'/home'`).
- **CERO MODIFICACIÓN** de rutas existentes (B2C, Auth, Provider, IA).
- **CERO LÓGICA CONDICIONAL** dentro del constructor de ruta.
- **Clasificación**: `PROPOSAL`.

---

## 9. B2C ISOLATION

- Las rutas `/home`, `/provider`, `/client-bookings`, `/provider-route` y `/store` no tienen conocimiento del namespace `/saas/*`.
- `ProvidersScreen` y `ProviderDashboardScreen` no importan `ActiveContextHolder` ni son alteradas.
- La navegación B2C y la navegación SaaS operan en planos paralelos y completamente aislados.
- **Clasificación**: `FACT`.

---

## 10. JOURNEY ISOLATION

- **`JOURNEY STATUS: ARCHITECTURAL STOP`**.
- `login_screen.dart` y `register_screen.dart` **NO se modifican**.
- No se agrega ninguna lógica post-login para evaluar `memberships`, `tenants` o redirigir automáticamente a `/saas/hub`.
- El acceso a SaaS es una acción deliberada del runtime y no una interferencia en el login de usuarios.
- **Clasificación**: `ARCHITECTURAL STOP`.

---

## 11. FUTURE SAAS NAMESPACE

Se reserva el prefijo unificado `'/saas/*'` para todos los módulos empresariales futuros de GlowApp SaaS:

| Ruta Futura | Módulo Asociado | Estado Actual |
| :--- | :--- | :--- |
| `'/saas/hub'` | Cockpit Operacional (Fase 4) | **Aprobado para Fase 5** |
| `'/saas/catalog'` | Catálogo Comercial (NODO-02) | Futura fase (Fuera de scope) |
| `'/saas/staff'` | Horarios y Personal (NODO-03A) | Futura fase (Fuera de scope) |
| `'/saas/agenda'` | Agenda y Citas (NODO-06) | Futura fase (Fuera de scope) |

> **Regla**: Ninguna ruta futura se registrará en `main.dart` hasta que su nodo correspondiente sea formalmente cerrado y autorizado.
- **Clasificación**: `PROPOSAL`.

---

## 12. PHYSICAL FILE PLAN

### 12.1 Archivo Objetivo de Modificación (FASE 5 - IMPLEMENTACIÓN)
- `frontend/lib/main.dart` (`MODIFY` — 2 líneas añadidas: 1 import + 1 entrada en `routes`).

### 12.2 Archivo Nuevo de Pruebas (FASE 5 - IMPLEMENTACIÓN)
- `frontend/test/saas_navigation_test.dart` (`NEW` — Suite de pruebas de navegación).

### 12.3 Archivos Protegidos e Inmutables (`DO NOT TOUCH` / `IMMUTABLE`)
- `frontend/lib/services/active_context_holder.dart` (`IMMUTABLE`)
- `frontend/lib/services/api_service.dart` (`IMMUTABLE`)
- `frontend/lib/models/saas/available_context_model.dart` (`IMMUTABLE`)
- `frontend/lib/services/saas_context_service.dart` (`IMMUTABLE`)
- `frontend/lib/screens/saas/available_context_selector_screen.dart` (`IMMUTABLE`)
- `frontend/lib/models/saas/hub_salon_model.dart` (`IMMUTABLE`)
- `frontend/lib/services/hub_salon_service.dart` (`IMMUTABLE`)
- `frontend/lib/screens/saas/hub_salon_screen.dart` (`IMMUTABLE`)
- `frontend/lib/screens/auth/login_screen.dart` (`DO NOT TOUCH`)
- `frontend/lib/screens/auth/register_screen.dart` (`DO NOT TOUCH`)
- `frontend/lib/screens/provider_dashboard_screen.dart` (`DO NOT TOUCH`)

---

## 13. TEST ARCHITECTURE (FASE 5)

La futura suite `frontend/test/saas_navigation_test.dart` verificará 8 invariantes:
1. **Verificación de Ruta**: Comprobar que `/saas/hub` está presente en el mapa `routes` de `BeautyApp`.
2. **Instanciación Correcta**: `Navigator.pushNamed(context, '/saas/hub')` monta exitosamente `HubSalonScreen`.
3. **Comportamiento sin Contexto**: Entrar a `/saas/hub` con `activeMembershipId == null` renderiza `active_context_missing`.
4. **Comportamiento con Contexto**: Entrar a `/saas/hub` con `activeMembershipId` válido renderiza el Cockpit y llama al servicio.
5. **Transición Selector -> Hub**: Ejecutar selección explícita en `AvailableContextSelectorScreen` navega a `/saas/hub`.
6. **Inmutabilidad B2C**: Comprobar que `/home`, `/provider` y `/login` siguen instanciándose sin regresión.
7. **Cero Mutación en Route**: Comprobar que la resolución de ruta en `main.dart` no ejecuta `setActiveMembershipId`.
8. **Cero Efectos Journey**: Comprobar que no hay redirecciones automáticas basadas en rol en el flujo de arranque.

---

## 14. SECURITY & GOVERNANCE

1. **Rutas son Vistas, No Permisos**: El registro de `'/saas/hub'` en `main.dart` es meramente un puntero declarativo de UI. El backend (`activeContextMiddleware` + RLS PostgreSQL) es la autoridad exclusiva que concede o rechaza el acceso a los datos de la sede.
2. **Cero Fuga de Contexto**: `ActiveContextHolder` permanece en RAM. El enrutamiento de Flutter no persiste ni comparte el `membership_id` con terceros.

---

## 15. RISKS & MITIGATIONS

| Riesgo | Impacto | Mitigación Arquitectónica |
| :--- | :--- | :--- |
| Acceso directo a `/saas/hub` sin login previo | Bajo | `ApiService` arrojará 401 si no hay token, o el Hub mostrará `active_context_missing` si no hay membresía. |
| Colisión de nombres en `routes` | Nulo | Uso del prefijo unificado `/saas/hub`. |
| Regresión en `main.dart` | Nulo | Modificación puramente aditiva (1 import + 1 entrada en mapa). |

---

## 16. IMPLEMENTATION PRECONDITIONS

Antes de iniciar la implementación en Fase 5, se debe verificar:
1. NODO-07 Fase 4 completamente cerrada y aprobada.
2. Suite SaaS de Fases 1, 3 y 4 con 33/33 tests passing.
3. Autorización explícita del Director para modificar `frontend/lib/main.dart`.

---

## 17. EXPLICIT NON-GOALS

- **NO** implementar Journey.
- **NO** modificar `login_screen.dart` ni `register_screen.dart`.
- **NO** registrar `/saas/context/available`.
- **NO** crear guards o middlewares en `main.dart`.
- **NO** modificar `AvailableContextSelectorScreen` ni `HubSalonScreen`.
- **NO** registrar rutas de N02, N03A, N04, N05 ni N06.

---

## 18. FINAL ARCHITECTURAL VERDICT

```
====================================================================
PHYSICAL ARCHITECTURE VERDICT: APPROVED & SPECIFIED
TARGET: MINIMAL REGISTRATION OF '/saas/hub' IN main.dart
B2C ISOLATION: 100% PRESERVED
JOURNEY BOUNDARY: STRICT STOP PRESERVED
NEXT STEP: AWAITING DIRECTOR IMPLEMENTATION AUTHORIZATION
====================================================================
```
