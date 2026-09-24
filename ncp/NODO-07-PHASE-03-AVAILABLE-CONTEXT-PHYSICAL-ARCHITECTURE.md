# NODO-07 — FASE 3 — AVAILABLE CONTEXT
## PHYSICAL ARCHITECTURE SPECIFICATION — FLUTTER CLIENT INFRASTRUCTURE

================================================================================
PROJECT: GlowApp SaaS  
AUTHORITY: Director del Proyecto  
NODE IDENTIFIER: NODO-07  
PHASE: FASE 3 — Available Context (Physical Architecture Specification)  
DOCUMENT VERSION: v1.0.0  
CLASSIFICATION: FORMAL PHYSICAL ARCHITECTURE DEFINITION — ZERO CODE IMPLEMENTED  
BASELINE CONTRACT: ncp/NODO-07-SAAS-SCREEN-FLOW-CONTRACT-v1.0.md (CLOSED / IMMUTABLE)  
PHYSICAL ARCHITECTURE BASE: ncp/NODO-07-PHYSICAL-ARCHITECTURE-v1.0.md (APPROVED)  
INFRASTRUCTURE BASE: NODO-07 FASE 1 (CLOSED / IMMUTABLE)  
CONTRACT CLOSURE: ncp/NODO-07-PHASE-02-AVAILABLE-CONTEXT-DISCOVERY.md (CLOSED)  
DIRECTOR DECISION: DEC-N07-AC-001 (ADOPTED & ENFORCED)  
STATUS: PHYSICAL ARCHITECTURE SPECIFIED / AWAITING IMPLEMENTATION AUTHORIZATION 🟡  
================================================================================

---

## 1. EXECUTIVE SUMMARY

El presente documento define la **Arquitectura Física** detallada para la materialización de la capa **Available Context** en el cliente Flutter de GlowApp SaaS.

### Principios Rectores:
1. **Zero Framework Bloat:** No se introducen gestores de estado externos (Bloc, Riverpod, Redux, GetX). Se utiliza la infraestructura estándar de Flutter (`StatefulWidget` / `ChangeNotifier` / `ValueNotifier`).
2. **Cero Autorización en Frontend:** El cliente Flutter no interpreta roles ni otorga permisos. Se limita a consultar el endpoint, representar el estado visual y capturar la selección explícita del operador.
3. **Desacoplamiento Estricto de Carga y Selección:** La invocación a `GET /api/v1/saas/context/available` es una consulta de solo lectura pura que **jamás muta `ActiveContextHolder`**.
4. **Cumplimiento Inflexible de DEC-N07-AC-001:** Tanto `ONE_CONTEXT` como `MULTIPLE_CONTEXTS` requieren una **acción explícita del usuario** antes de establecer `membership_id` en `ActiveContextHolder`.
5. **Aislamiento B2C y Resguardo de Fases:** Cero alteraciones en el subsistema B2C, cero modificaciones en `ActiveContextHolder` (Fase 1 inmutable) y preservación del `ARCHITECTURAL STOP` en Journey.

---

## 2. EXISTING CONTRACT & DECISION BASELINE

De acuerdo con los contratos cerrados (`NODO-07 Contract v1.0`, `Fase 1` y `Fase 2`):

```
+───────────────────────────────────────────────────────────────────────────────+
|                         CADENA DE AUTORIDAD Y FLUJO                           |
+───────────────────────────────────────────────────────────────────────────────+

                 Authenticated Identity (JWT en Secure Storage)
                                       │
                                       ▼
                          [JOURNEY DECISION BOUNDARY]  <── ARCHITECTURAL STOP A
                                       │ (Ruta SaaS)
                                       ▼
                       GET /api/v1/saas/context/available
                                       │
                                       ▼
                            AvailableContextService
                                       │
                                       ▼
                             AvailableContextState
                        (Loading / Success / Empty / Error)
                                       │
                                       ▼
                        AvailableContextSelectorScreen
                                       │
         ┌─────────────────────────────┼─────────────────────────────┐
         ▼                             ▼                             ▼
   [NO_CONTEXT]                  [ONE_CONTEXT]              [MULTIPLE_CONTEXTS]
   available_count == 0          available_count == 1       available_count >= 2
   (Sin Active Context)          (DEC-N07-AC-001)           (Selección Obligatoria)
   Vista informativa             Tarjeta Sede Única         Lista de Tarjetas Sede
   CTA Crear Salón (Fase 4)      Acción Explícita Usuario   Acción Explícita Usuario
         │                             │                             │
         │                             └──────────────┬──────────────┘
         │                                            ▼
         │                             [Usuario toca/confirma Sede]
         │                                            │
         │                                            ▼
         │                             ActiveContextHolder.setActiveMembershipId(id)
         │                                            │
         │                                            ▼
         │                                      ACTIVE CONTEXT
         │                                 (Header x-active-membership-id)
         │                                            │
         │                                            ▼
         └─────────────────────────────────────> Hub Salón Cockpit
                                                 GET /api/v1/saas/hub/summary
```

---

## 3. BACKEND INTEGRATION BOUNDARY

- **Endpoint Único Autorizado:** `GET /api/v1/saas/context/available`
- **Método HTTP:** `GET`
- **Autenticación:** `Authorization: Bearer <token>`
- **Header Contextual:** **NO se envía** `x-active-membership-id` (este endpoint es previo a la selección).
- **Prohibición Expresa:**
  - Cero creación de endpoints alternativos o endpoints de "activación de contexto" en backend.
  - Cero persistencia en base de datos de la selección de sede.
  - La selección es un evento de runtime en memoria del cliente.

---

## 4. FRONTEND MODEL ARCHITECTURE

Ubicación propuesta: `frontend/lib/models/saas/available_context_model.dart`

### 4.1. Definición de Clases DTO Inmutables

```dart
// frontend/lib/models/saas/available_context_model.dart
import 'package:flutter/foundation.dart';

@immutable
class AvailableContextItem {
  final String membershipId;
  final String organizationLegalName;
  final String establishmentName;
  final String establishmentSlug;
  final bool establishmentIsActive;
  final String role;
  final String relationType;
  final String tenantName;

  const AvailableContextItem({
    required this.membershipId,
    required this.organizationLegalName,
    required this.establishmentName,
    required this.establishmentSlug,
    required this.establishmentIsActive,
    required this.role,
    required this.relationType,
    required this.tenantName,
  });

  factory AvailableContextItem.fromJson(Map<String, dynamic> json) {
    return AvailableContextItem(
      membershipId: json['membership_id'] as String,
      organizationLegalName: json['organization_legal_name'] as String? ?? '',
      establishmentName: json['establishment_name'] as String? ?? '',
      establishmentSlug: json['establishment_slug'] as String? ?? '',
      establishmentIsActive: json['establishment_is_active'] as bool? ?? true,
      role: json['role'] as String? ?? '',
      relationType: json['relation_type'] as String? ?? '',
      tenantName: json['tenant_name'] as String? ?? '',
    );
  }
}

@immutable
class AvailableContextResponse {
  final String resolutionStatus; // 'NO_CONTEXT' | 'ONE_CONTEXT' | 'MULTIPLE_CONTEXTS'
  final int availableContextsCount;
  final List<AvailableContextItem> availableContexts;

  const AvailableContextResponse({
    required this.resolutionStatus,
    required this.availableContextsCount,
    required this.availableContexts,
  });

  bool get isNoContext => resolutionStatus == 'NO_CONTEXT' || availableContextsCount == 0;
  bool get isOneContext => resolutionStatus == 'ONE_CONTEXT' && availableContextsCount == 1;
  bool get isMultipleContexts => resolutionStatus == 'MULTIPLE_CONTEXTS' && availableContextsCount >= 2;

  factory AvailableContextResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final rawList = data['available_contexts'] as List<dynamic>? ?? [];
    
    return AvailableContextResponse(
      resolutionStatus: data['resolution_status'] as String? ?? 'NO_CONTEXT',
      availableContextsCount: (data['available_contexts_count'] as num?)?.toInt() ?? rawList.length,
      availableContexts: rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => AvailableContextItem.fromJson(item))
          .toList(),
    );
  }
}
```

### 4.2. Invariantes del Modelo
- **Campos Prohibidos:** No se agregan campos sintéticos como `isSelected`, `isDefault`, `isCurrent`, `activeSalonId` o `tenantId` como propiedad de estado.
- **Inmutabilidad:** Todas las propiedades son `final` y las clases están marcadas con `@immutable`.

---

## 5. SERVICE ARCHITECTURE

Ubicación propuesta: `frontend/lib/services/saas_context_service.dart`

### 5.1. Responsabilidades Técnicas
- Invocar de forma asíncrona `ApiService.get('/api/v1/saas/context/available')`.
- Deserializar la respuesta HTTP en la instancia `AvailableContextResponse`.
- Manejar excepciones de red y estructurar errores de forma limpia sin interpretar códigos como autorización.

### 5.2. Lo que el Servicio NO DEBE HACER
- **NO debe llamar a `ActiveContextHolder.setActiveMembershipId(...)`.**
- **NO debe navegar.**
- **NO debe almacenar en caché ni persistir la respuesta en disco.**
- **NO debe alterar el token JWT.**

---

## 6. STATE ARCHITECTURE

Se utilizará una arquitectura basada en `StatefulWidget` o `ValueNotifier` estándar de Flutter.

### 6.1. Enumeración de Estados del Ciclo de Vida
```dart
enum AvailableContextViewStatus {
  loading,
  success,
  empty,
  error,
}
```

### 6.2. Mapeo de Estados
1. **`loading`:** Estado inicial al montar la pantalla mientras se ejecuta la consulta HTTP.
2. **`success`:** La consulta respondió exitosamente (HTTP 200). Se bifurca visualmente según `resolutionStatus`:
   - `ONE_CONTEXT`: Renderiza la tarjeta de sede única y el botón explícito de ingreso.
   - `MULTIPLE_CONTEXTS`: Renderiza la lista seleccionable de tarjetas de sede.
3. **`empty` (`NO_CONTEXT`):** La consulta respondió exitosamente pero con `available_contexts_count == 0`. Renderiza la vista informativa y el CTA hacia Onboarding.
4. **`error`:** Ocurrió un fallo de red o error de servidor. Renderiza el mensaje de error con botón de "Reintentar".

---

## 7. SCREEN ARCHITECTURE (PROPOSED DESIGN)

Ubicación propuesta: `frontend/lib/screens/saas/available_context_selector_screen.dart`

### 7.1. Responsabilidades de la Pantalla
- Ejecutar la carga de contextos en el ciclo inicial (`initState`).
- Renderizar la vista correspondiente al estado (`LoadingState`, `ErrorState`, `NoContextView`, `OneContextView`, `MultipleContextsView`).
- Capturar la interacción táctil explícita del operador.
- Invocar `ActiveContextHolder().setActiveMembershipId(selectedId)` únicamente al recibir el evento explícito del usuario.
- Transicionar hacia `/saas/hub` mediante `Navigator.pushReplacementNamed`.

### 7.2. Prohibiciones Estrictas de la Pantalla
- Cero auto-selección en `initState` o en el callback de carga.
- Cero lógica de autorización o evaluación de roles en cliente.
- Cero mutación de `FlutterSecureStorage` o `SharedPreferences`.

---

## 8. SPECIFIC BEHAVIOR: ONE_CONTEXT (DEC-N07-AC-001)

El tratamiento de `ONE_CONTEXT` es conceptualmente idéntico a una selección deliberada:

```
[AvailableContextSelectorScreen detecta ONE_CONTEXT]
                        │
                        ▼
       [Renderiza UI de Sede Única Identificada]
       ├── Nombre de Empresa: "Glow Hair S.A.S."
       ├── Sede: "Sede Chicó Norte"
       ├── Rol: "PROFESIONAL"
       └── [Botón Explícito: "INGRESAR A ESTA SEDE"]
                        │
                        ▼ (Usuario pulsa el botón)
       [ActiveContextHolder().setActiveMembershipId(item.membershipId)]
                        │
                        ▼
       [Navigator.pushReplacementNamed(context, '/saas/hub')]
```

> [!CAUTION]
> **PROHIBICIÓN ESTRICTA:** Queda terminantemente prohibido invocar `setActiveMembershipId` de forma síncrona/automática dentro de `initState()`, `load()`, `then()`, o en el constructor del widget.

---

## 9. SPECIFIC BEHAVIOR: MULTIPLE_CONTEXTS

- La pantalla renderiza un `ListView.separated` con cada `AvailableContextItem`.
- Cada elemento es una tarjeta interactiva (`InkWell` / `Card`).
- Al pulsar una tarjeta, el handler extrae exclusivamente `item.membershipId`.
- Invoca `ActiveContextHolder().setActiveMembershipId(item.membershipId)` y navega al Hub Salón.
- **Cero selección por:** índice [0], rol de mayor privilegio, sede alfabética o último contexto utilizado.

---

## 10. SPECIFIC BEHAVIOR: NO_CONTEXT

- La pantalla renderiza una ilustración de bienvenida informativa: "Aún no tienes salones vinculados a tu cuenta".
- Presenta un botón secundario: "Crear y Aprovisionar Salón Desde Cero".
- **Invariantes:**
  - **NO llama** a `ActiveContextHolder.setActiveMembershipId(...)`.
  - **NO inventa** IDs sintéticos.
  - **NO navega** al Hub Salón.

---

## 11. ERROR STATE ARCHITECTURE

- Si la petición falla (ej. pérdida de conexión o HTTP 500):
  - El estado cambia a `AvailableContextViewStatus.error`.
  - Se presenta un banner amigable con el mensaje de error y un botón "Reintentar" que re-ejecuta el método de carga.
  - No se toma ninguna decisión de redirección automática hacia Login o Journey basada en códigos de error.

---

## 12. ACTIVE CONTEXT INTEGRATION (FASE 1 IMMUTABLE)

La integración con la Fase 1 es limpia, unidireccional y mínima:

$$	ext{User Click} \longrightarrow 	ext{ActiveContextHolder().setActiveMembershipId(membershipId)} \longrightarrow 	ext{RAM State Updated}$$

- **`ActiveContextHolder` permanece 100% inalterado.**
- **`ApiService` permanece 100% inalterado.**
- Los subsiguientes llamados que efectúe el Hub Salón (`/api/v1/saas/hub/*`) recibirán automáticamente `x-active-membership-id` inyectado por la infraestructura ya cerrada en la Fase 1.

---

## 13. NAVIGATION BOUNDARY

- **Ruta Proyectada:** `/saas/available-context` (se registrará formalmente en `main.dart` durante la subfase de implementación).
- **Ruta de Salida:** `/saas/hub` (Hub Salón Cockpit).
- **Aislamiento:** La navegación se realiza con `pushReplacementNamed` para evitar que el botón "Atrás" del dispositivo vuelva a un selector con sesión ya iniciada en una sede física.

---

## 14. JOURNEY BOUNDARY (ARCHITECTURAL STOP)

```
================================================================================
                           ARCHITECTURAL STOP A
================================================================================
El mecanismo físico exacto mediante el cual un usuario autenticado transiciona
desde el Login/Register hacia el flujo SaaS (SaaS Eligibility / Available Context)
permanece en ARCHITECTURAL STOP.

Esta Fase 3 define exclusivamente la topología interna de Available Context
una vez que el flujo ya ha ingresado a la ruta SaaS.
================================================================================
```

---

## 15. B2C BOUNDARY

- El subsistema B2C (`home_screen.dart`, `provider_dashboard_screen.dart`, `booking_tracking_screen.dart`) se mantiene totalmente aislado.
- `AvailableContextSelectorScreen` no comparte widgets de estado ni modelos con el Marketplace B2C.

---

## 16. PHYSICAL FILE PLAN (PROJECTION FOR IMPLEMENTATION)

Los archivos proyectados que se crearán/modificarán exclusivamente cuando el Director autorice la implementación son:

| Archivo Proyectado | Tipo de Acción | Responsabilidad Física |
| :--- | :---: | :--- |
| `frontend/lib/models/saas/available_context_model.dart` | `NEW` | Clases DTO inmutables `AvailableContextResponse` y `AvailableContextItem`. |
| `frontend/lib/services/saas_context_service.dart` | `NEW` | Servicio HTTP que consume `GET /api/v1/saas/context/available` vía `ApiService`. |
| `frontend/lib/screens/saas/available_context_selector_screen.dart` | `NEW` | Pantalla visual con soporte para los estados `NO_CONTEXT`, `ONE_CONTEXT`, `MULTIPLE_CONTEXTS`, loading y error. |
| `frontend/test/saas_available_context_test.dart` | `NEW` | Suite de pruebas unitarias y de widgets para Available Context. |

---

## 17. TEST PLAN (SPECIFICATION FOR IMPLEMENTATION)

Pruebas unitarias mínimas que se implementarán en la fase correspondiente:

1. **Test A (DTO Parsing):** Serialización y deserialización correcta del JSON real del backend.
2. **Test B (NO_CONTEXT State):** Respuesta con `available_contexts_count == 0` mapea a `isNoContext == true`.
3. **Test C (ONE_CONTEXT State):** Respuesta con `count == 1` mapea a `isOneContext == true`.
4. **Test D (MULTIPLE_CONTEXTS State):** Respuesta con `count >= 2` mapea a `isMultipleContexts == true`.
5. **Test E (Explicit Selection):** Al accionar el botón de selección, `ActiveContextHolder.activeMembershipId` recibe el UUID exacto.
6. **Test F (No Auto-Selection):** Montar el widget/servicio no muta `ActiveContextHolder` automáticamente en `ONE_CONTEXT`.
7. **Test G (No Persistence):** Verificación de que ninguna operación escribe en `SharedPreferences` o `FlutterSecureStorage`.
8. **Test H (Error Handling):** Manejo controlado de fallos HTTP (401, 500) sin lanzar excepciones no controladas.
9. **Test I (B2C Isolation):** La consulta de Available Context no altera llamadas o headers B2C.

---

## 18. ARCHITECTURAL RISKS & MITIGATIONS

| Riesgo Detectado | Nivel de Riesgo | Mitigación Arquitectónica |
| :--- | :---: | :--- |
| **Auto-selección accidental en `ONE_CONTEXT`** | Alto | Aplicación estricta de `DEC-N07-AC-001`. El handler de selección solo se dispara en el evento `onPressed` del botón en UI. |
| **Duplicación de estado con `ActiveContextHolder`** | Medio | `AvailableContextResponse` es un estado efímero de la pantalla; no se duplica como variable global de contexto activo. |
| **Intento de selección por `establishment_id`** | Alto | El DTO expone claramente `membershipId` y la llamada a `ActiveContextHolder` solo acepta `item.membershipId`. |
| **Bypass de Backend Authorization** | Alto | El frontend no valida permisos. El backend aplica RLS en cada petición subsiguiente. |

---

## 19. FINDINGS

- **FINDING-N07-05 (Decoupled Presentation):** La separación de `AvailableContextItem` como DTO inmutable garantiza que cualquier futura adición de metadata de sede (ej. logo, horarios) en el backend no romperá la estructura base de selección.
- **FINDING-N07-06 (No External Dependencies):** Al resolver la capa de estado con `StatefulWidget` estándar de Flutter, se mantiene la base de código libre de acoplamientos a librerías de terceros.

---

## 20. RECOMMENDATION

1. Aprobar formalmente la Arquitectura Física aquí especificada para Available Context.
2. Autorizar la ejecución de la **FASE 3 — IMPLEMENTACIÓN** para crear los 4 archivos planificados (`available_context_model.dart`, `saas_context_service.dart`, `available_context_selector_screen.dart` y `saas_available_context_test.dart`).

---

## 21. DIRECTOR DECISION REQUIRED

```
================================================================================
                    DECISIÓN REQUERIDA DEL DIRECTOR
================================================================================
¿Se aprueba la Arquitectura Física de Available Context y se autoriza la
subfase de implementación física de código y pruebas?
================================================================================
```
