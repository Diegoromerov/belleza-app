# NODO-07 — FASE 6A — ARQUITECTURA FÍSICA: CREAR DESDE CERO (SCR-06)
## GlowApp SaaS — Initial Provisioning Wizard & Handover Architecture

================================================================================
PROJECT: GlowApp SaaS  
AUTHORITY: Director del Proyecto GlowApp SaaS  
NODE IDENTIFIER: NODO-07 — FASE 6A  
DOCUMENT CLASSIFICATION: FORMAL PHYSICAL ARCHITECTURE DESIGN (NO CODE CHANGES)  
DATE: 2026-09-12  
STATUS: PHYSICAL ARCHITECTURE PROPOSED / ARCHITECTURAL STOP / AWAITING DIRECTOR AUDIT 🟡  
================================================================================

---

## 1. OBJETIVO

Definir la **Arquitectura Física Formal** para la futura implementación de **CREAR DESDE CERO (`SCR-06`)** en el cliente Flutter, garantizando:

1. La captura interactiva y estructurada de la intención operativa inicial de la sede (actividades comerciales, catálogo de servicios base en tránsito y asignación preliminar de categorías a colaboradores activos preexistentes).
2. La compilación y entrega determinista del **`Context Package` transitorio (in-memory)** al backend mediante `POST /api/v1/saas/hub/onboarding/bootstrap`.
3. El respeto irrestricto de la frontera semántica hacia **`PRE-NODO 01`** definida en `HANDOVER-BOUNDARY-CONTRACT-v1.0.md`.
4. El consumo exclusivo de la autoridad contextual provista por `ActiveContextHolder` y el transporte canónico del header `x-active-membership-id`.
5. **Cero persistencia indebida:** No crear tablas, no persistir catálogo en SQLite ni almacenamiento local, y no mutar el backend cerrado.

---

## 2. CONTRATOS DE AUTORIDAD

Esta arquitectura física se rige y subordina estrictamente a las siguientes fuentes normativas:

1. **`CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md`:** Especificación del nodo de aprovisionamiento, axioma de transitoriedad y reglas `DEC-CDC-001` (Cero persistencia de catálogo en base de datos) y `DEC-CDC-002` (Referenciación exclusiva de staff activo preexistente).
2. **`HANDOVER-BOUNDARY-CONTRACT-v1.0.md`:** Definición de los 16 atributos del `Context Package`, matriz de soberanía de datos y frontera estricta hacia `PRE-NODO 01`.
3. **`NODO-07-SAAS-SCREEN-FLOW-CONTRACT-v1.0.md`:** Contrato de pantallas SaaS, especificación de `SCR-06` (`CrearDesdeCeroWizardScreen`) y principios de desacoplamiento.
4. **`NODO-07-PHASE-05-SAAS-NAVIGATION-PHYSICAL-ARCHITECTURE.md`:** Regla canónica *No Route Without Consumer* y soberanía de `ActiveContextHolder`.
5. **`NODO-07-PHASE-05-SAAS-NAVIGATION-IMPLEMENTATION-REPORT.md`:** Evidencia de 41/41 tests SaaS pasando y circuito `/saas/hub` inmutable.

---

## 3. EVIDENCIA FORENSE BACKEND (READ-ONLY)

La inspección forense del backend confirma la existencia y cierre físico de los siguientes componentes:

* **Rutas (`backend/src/routes/crearDesdeCeroRoutes.js`):**
  * Montado en `backend/index.js:273`:
    ```javascript
    app.use('/api/v1/saas/hub/onboarding', require('./src/routes/crearDesdeCeroRoutes'));
    ```
  * Endpoint declarado:
    ```javascript
    router.post('/bootstrap', authMiddleware, activeContextMiddleware, crearDesdeCeroController.bootstrap);
    ```
* **Controlador (`backend/src/controllers/crearDesdeCeroController.js`):**
  * Extrae `req.user.id`, `req.tenantId`, `req.establishmentId`, `req.activeContext`.
  * Valida respuestas y mapea errores estandarizados (`INSUFFICIENT_PROVISIONING_ROLE`, `MEMBERSHIP_NOT_ACTIVE`, `ACTIVE_CONTEXT_REQUIRED`, `ESTABLISHMENT_NOT_FOUND`).
* **Servicio (`backend/src/services/crearDesdeCeroService.js`):**
  * `compileContextPackage(...)`: Valida server-side que el rol sea estrictamente `OWNER` o `MANAGER`.
  * Ejecuta consulta a `establishments`, `organizations` y `memberships` bajo RLS (`app.tenant_id`).
  * Ensambla en memoria el `context_package` con los 16 atributos canónicos.
  * Deriva el estado determinista (`INITIAL`, `IN_PROGRESS`, `BLOCKED`, `READY_FOR_PRE_NODE_01`).
* **Suite Automatizada (`backend/tests/test_crear_desde_cero_suite.js`):**
  * 100% pruebas de backend pasando en aislamiento RLS multitenant.

---

## 4. EVIDENCIA FORENSE FRONTEND (READ-ONLY)

* **Infraestructura Reutilizable Existente:**
  * `frontend/lib/services/active_context_holder.dart`: Singleton reactivo portador de `activeMembershipId`, `currentOrganization`, `currentEstablishment`, `currentRole`.
  * `frontend/lib/services/api_service.dart`: Cliente HTTP con interceptor automático para inyectar `x-active-membership-id` en URLs `/api/v1/saas/*`.
* **Componentes SaaS Cerrados e Inmutables:**
  * `frontend/lib/screens/saas/hub_salon_screen.dart` (`/saas/hub`): Cockpit de sede.
  * `frontend/lib/screens/saas/available_context_selector_screen.dart`: Selector explícito de sede.
* **Componentes Faltantes para SCR-06 (A Diseñar):**
  * DTO Model: `frontend/lib/models/saas/crear_desde_cero_model.dart`.
  * Service: `frontend/lib/services/crear_desde_cero_service.dart`.
  * Screen: `frontend/lib/screens/saas/crear_desde_cero_screen.dart`.

---

## 5. ENDPOINT CONTRACT

```http
POST /api/v1/saas/hub/onboarding/bootstrap
Authorization: Bearer <JWT_TOKEN>
x-active-membership-id: <UUID>
Content-Type: application/json
```

### 5.1. Seguridad y Compuertas Server-Side
1. `authMiddleware`: Valida identidad de la cuenta (`req.user.id`).
2. `activeContextMiddleware`: Valida `x-active-membership-id`, verifica pertenencia al tenant resuelto y puebla `req.activeContext`.
3. `crearDesdeCeroService`: Exige de forma estricta:
   - `role IN ('OWNER', 'MANAGER')` $	o$ Si es otro rol (ej. `PROFESSIONAL`, `RECEPTIONIST`), retorna `403 FORBIDDEN` con código `INSUFFICIENT_PROVISIONING_ROLE`.
   - `membership_status == 'ACTIVE'` $	o$ Si está suspendida o inactiva, retorna `403 FORBIDDEN` con código `MEMBERSHIP_NOT_ACTIVE`.

---

## 6. PAYLOAD CONTRACT

### 6.1. Request Payload (Enviado por el Frontend)
```json
{
  "activities": [
    "Peluquería",
    "Barbería",
    "Uñas & Manicure"
  ],
  "services": [
    {
      "name": "Corte de Cabello Signature",
      "category": "Peluquería",
      "duration_minutes": 45,
      "price": 35000,
      "description": "Corte y peinado personalizado"
    },
    {
      "name": "Manicure Ruso",
      "category": "Uñas & Manicure",
      "duration_minutes": 60,
      "price": 45000,
      "description": "Limpieza y esmaltado semipermanente"
    }
  ],
  "staff_assignments": [
    {
      "membership_id": "b789c012-3456-789a-bcde-f0123456789a",
      "assigned_categories": [
        "Peluquería"
      ]
    }
  ],
  "decisions": {
    "catalog_mode": "STANDARD_SETUP",
    "provisioning_source": "CREAR_DESDE_CERO_v1.0"
  }
}
```

### 6.2. Response Payload (Retornado por el Backend — 200 OK)
```json
{
  "status": "success",
  "data": {
    "context_package": {
      "organization": {
        "id": 2,
        "legal_name": "Beauty Luxe Corp S.A.S."
      },
      "establishments": {
        "id": "e4b2d3c1-7a89-4f5e-b123-456789abcdef",
        "name": "Salón Elegance Poblado",
        "slug": "salon-elegance-poblado",
        "city": "Medellín",
        "address": "Cra 43A # 1-50",
        "phone": "+573001234567",
        "operating_hours": {
          "monday": { "open": "08:00", "close": "19:00", "is_closed": false }
        }
      },
      "activities": [
        "Peluquería",
        "Barbería",
        "Uñas & Manicure"
      ],
      "relevant_services": [
        {
          "name": "Corte de Cabello Signature",
          "category": "Peluquería",
          "duration_minutes": 45,
          "price": 35000,
          "description": "Corte y peinado personalizado"
        }
      ],
      "people_initial_roles": [
        {
          "membership_id": "b789c012-3456-789a-bcde-f0123456789a",
          "user_id": 7,
          "user_name": "Diego Romero",
          "user_email": "diego@beautyluxe.com",
          "role": "OWNER",
          "relation_type": "OWNER_PARTNER",
          "status": "ACTIVE",
          "assigned_categories": ["Peluquería"]
        }
      ],
      "identity": {
        "id": 7,
        "role": "OWNER"
      },
      "state": "READY_FOR_PRE_NODE_01",
      "known_evidence": {
        "active_context_verified": true,
        "tenant_isolation_verified": true,
        "authorized_membership_verified": true
      },
      "decisions": {
        "catalog_mode": "STANDARD_SETUP",
        "provisioning_source": "CREAR_DESDE_CERO_v1.0"
      },
      "applicable_rules": [
        "ARCH-AC-001-HEADER-TRANSPORT",
        "ARCH-RLS-TENANT-ISOLATION",
        "ARCH-OWNER-MANAGER-AUTHORITY"
      ],
      "conditions": {
        "active_membership_satisfied": true,
        "establishment_context_satisfied": true
      },
      "procedures": {
        "handover_target": "PRE_NODE_01",
        "handover_type": "IN_MEMORY_TRANSIENT"
      },
      "dependencies": [
        "ACTIVE_ESTABLISHMENT_CONTEXT",
        "ACTIVE_AUTHORIZED_MEMBERSHIP"
      ],
      "blocks": [],
      "route": "HUB_SALON -> CREAR_DESDE_CERO -> PRE_NODO_01",
      "entry_state": {
        "context_source": "HUB_SALON_ACTIVE_CONTEXT",
        "provisioning_mode": "INITIAL_BOOTSTRAP"
      }
    }
  }
}
```

---

## 7. HANDOVER BOUNDARY (FRONTERA SAAS → PRE-NODO 01)

```
┌────────────────────────────────────────────────────────────────────────┐
│                        FLUTTER CLIENT (UX / SCR-06)                    │
│                                                                        │
│  - Captura datos en memoria (Actividades, Servicios, Staff)            │
│  - Adjunta header x-active-membership-id                               │
│  - Invoca POST /api/v1/saas/hub/onboarding/bootstrap                   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        SAAS BACKEND (CDC SERVICE)                      │
│                                                                        │
│  - Valida ActiveContext, Rol (OWNER/MGR) y Tenant Isolation            │
│  - Ensambla el Context Package Canónico (16 atributos)                 │
│  - Deriva State = READY_FOR_PRE_NODE_01                                │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    │ HANDOVER BOUNDARY
                                    │ (Contrato Semántico DTO v1.0)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        PRE-NODO 01 (CORE B2C INMUTABLE)                │
│                                                                        │
│  - Ingestión in-memory del Context Package (HBC Ingestion)             │
│  - Cero persistencia forzada de tablas relacionales en frontend        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 8. MODELO FÍSICO PROPUESTO (`frontend/lib/models/saas/crear_desde_cero_model.dart`)

```dart
// DTOs de Entrada (Payload del Wizard)
class ServiceDraft {
  final String name;
  final String category;
  final int durationMinutes;
  final double price;
  final String description;

  const ServiceDraft({
    required this.name,
    required this.category,
    required this.durationMinutes,
    required this.price,
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'duration_minutes': durationMinutes,
    'price': price,
    'description': description,
  };
}

class StaffCategoryAssignmentDraft {
  final String membershipId;
  final List<String> assignedCategories;

  const StaffCategoryAssignmentDraft({
    required this.membershipId,
    required this.assignedCategories,
  });

  Map<String, dynamic> toJson() => {
    'membership_id': membershipId,
    'assigned_categories': assignedCategories,
  };
}

class CrearDesdeCeroBootstrapRequest {
  final List<String> activities;
  final List<ServiceDraft> services;
  final List<StaffCategoryAssignmentDraft> staffAssignments;
  final Map<String, dynamic>? decisions;

  const CrearDesdeCeroBootstrapRequest({
    required this.activities,
    required this.services,
    required this.staffAssignments,
    this.decisions,
  });

  Map<String, dynamic> toJson() => {
    'activities': activities,
    'services': services.map((s) => s.toJson()).toList(),
    'staff_assignments': staffAssignments.map((a) => a.toJson()).toList(),
    if (decisions != null) 'decisions': decisions,
  };
}

// DTOs de Respuesta (Handover Context Package Response)
class ContextPackageResponse {
  final String status;
  final String derivedState;
  final String establishmentName;
  final String organizationName;
  final List<String> activities;
  final List<String> blocks;
  final Map<String, dynamic> rawPackage;

  const ContextPackageResponse({
    required this.status,
    required this.derivedState,
    required this.establishmentName,
    required this.organizationName,
    required this.activities,
    required this.blocks,
    required this.rawPackage,
  });

  factory ContextPackageResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final pkg = data['context_package'] as Map<String, dynamic>? ?? {};
    final org = pkg['organization'] as Map<String, dynamic>? ?? {};
    final est = pkg['establishments'] as Map<String, dynamic>? ?? {};
    final rawActivities = (pkg['activities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final rawBlocks = (pkg['blocks'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    return ContextPackageResponse(
      status: json['status']?.toString() ?? 'success',
      derivedState: pkg['state']?.toString() ?? 'INITIAL',
      establishmentName: est['name']?.toString() ?? '',
      organizationName: org['legal_name']?.toString() ?? '',
      activities: rawActivities,
      blocks: rawBlocks,
      rawPackage: pkg,
    );
  }
}
```

---

## 9. PANTALLA PROPUESTA (`CrearDesdeCeroWizardScreen`)

### 9.1. Especificación UX / Arquitectónica
* **Tipo:** `StatefulWidget` con navegación por pasos (Stepper / PageView de 4 pasos):
  * **Paso 1 (Especialidades / Actividades):** Selección múltiple de líneas del salón (Peluquería, Uñas, Barbería, Spa, etc.).
  * **Paso 2 (Catálogo Base en Tránsito):** Formulario dinámico para agregar 1 o más servicios en borrador (Nombre, Categoría, Duración, Precio).
  * **Paso 3 (Asignación de Personal Activo):** Lista de miembros del staff obtenidos de `HubSalonStaffMember` asignándoles categorías temáticas.
  * **Paso 4 (Revisión & Handover):** Resumen de configuración y botón "Confirmar y Finalizar Aprovisionamiento".
* **Regla de Soberanía:** No permite avanzar a submit si el rol en `ActiveContextHolder` no es `OWNER` o `MANAGER`.

---

## 10. SERVICIO PROPUESTO (`CrearDesdeCeroService`)

```dart
class CrearDesdeCeroService {
  final ApiService _apiService;
  final ActiveContextHolder _contextHolder;

  CrearDesdeCeroService({
    ApiService? apiService,
    ActiveContextHolder? contextHolder,
  })  : _apiService = apiService ?? ApiService(),
        _contextHolder = contextHolder ?? ActiveContextHolder();

  Future<ContextPackageResponse> bootstrapInitialSetup(
    CrearDesdeCeroBootstrapRequest request,
  ) async {
    final membershipId = _contextHolder.activeMembershipId;
    if (membershipId == null) {
      throw CrearDesdeCeroException(
        code: 'ACTIVE_CONTEXT_MISSING',
        message: 'No hay un contexto de sede activo para realizar el aprovisionamiento.',
      );
    }

    final response = await _apiService.post(
      '/api/v1/saas/hub/onboarding/bootstrap',
      request.toJson(),
    );

    if (response.statusCode == 200) {
      return ContextPackageResponse.fromJson(response.data);
    } else if (response.statusCode == 403) {
      final errCode = response.data['error']?.toString() ?? 'FORBIDDEN';
      final errMsg = response.data['message']?.toString() ?? 'Acceso denegado.';
      throw CrearDesdeCeroException(code: errCode, message: errMsg);
    } else {
      throw CrearDesdeCeroException(
        code: 'BOOTSTRAP_FAILED',
        message: 'Error en el aprovisionamiento inicial: ${response.statusCode}',
      );
    }
  }
}
```

---

## 11. NAVEGACIÓN PROPUESTA

### 11.1. Análisis *No Route Without Consumer*
* `CrearDesdeCeroWizardScreen` es un flujo modal/asistente lanzado exclusivamente desde una acción contextual dentro de `HubSalonScreen`.
* **Alternativa Canónica Recomendada:**
  - Invocación vía `Navigator.push(context, MaterialPageRoute(builder: (_) => const CrearDesdeCeroWizardScreen()))`.
  - **No registrar** `/saas/crear-desde-cero` como named route en `main.dart` salvo que un requerimiento expreso del Director lo exija.
  - Al culminar exitosamente el Handover (`state == 'READY_FOR_PRE_NODE_01'`), el wizard muestra feedback de éxito y hace `Navigator.pop(context, true)` retornando a `HubSalonScreen` para refrescar métricas.

---

## 12. INTEGRACIÓN CON ACTIVE CONTEXT

* **Consumo Transparente:** `CrearDesdeCeroService` y `CrearDesdeCeroWizardScreen` acceden a `ActiveContextHolder.instance`.
* **Inyección de Header:** El `ApiService` intercepta automáticamente la URL `/api/v1/saas/hub/onboarding/bootstrap` y adjunta `x-active-membership-id: <UUID>`.
* **Cero Persistencia Local:** Ni el wizard ni el servicio escriben en SharedPreferences, SQLite ni Secure Storage.

---

## 13. ESTADOS DE UI

| Estado de UI | Disparador / Condición | Presentación en Pantalla | Acción Disponible |
| :--- | :--- | :--- | :--- |
| `initial` | Carga del Wizard | Paso 1 (Actividades) listo para interacción | Seleccionar actividades y continuar |
| `in_progress` | Edición de catálogo y asignaciones | Paso 2 y 3 con formularios validados localmente | Avanzar / Retroceder pasos |
| `submitting` | Click en "Confirmar Aprovisionamiento" | Overlay de carga: *"Compilando Context Package y Handover..."* | Controles bloqueados |
| `success_handover`| Backend retorna `200 OK` con `READY_FOR_PRE_NODE_01` | Pantalla/Dialog de éxito: *"Aprovisionamiento completado con éxito"* | Botón "Volver al Hub" (`Navigator.pop`) |
| `blocked` | Backend retorna `200 OK` pero `blocks` contiene errores | Alerta de bloqueo y sugerencias de remediación | Corregir datos en wizard |
| `unauthorized` | Backend retorna `403 INSUFFICIENT_PROVISIONING_ROLE` | Banner: *"Solo OWNER o MANAGER pueden aprovisionar el catálogo"* | Botón "Cerrar" |
| `error_network` | Error de conexión / timeout | Banner de reintento | Botón "Reintentar" |

---

## 14. MANEJO DE ERRORES

```
+-----------------------------------+-----------------------------------+---------------------------------------+
| CÓDIGO HTTP / ERROR CODE          | CAUSA                             | COMPORTAMIENTO FRONTEND               |
+-----------------------------------+-----------------------------------+---------------------------------------+
| 401 IDENTITY_NOT_FOUND            | Token JWT ausente o inválido      | Muestra error de autenticación        |
| 400 ACTIVE_CONTEXT_NOT_INITIALIZED| activeMembershipId es null        | Bloquea submit, solicita sede activa  |
| 403 INSUFFICIENT_PROVISIONING_ROLE| Rol es PROFESSIONAL o RECEPTIONIST| Informa restricción de rol (Solo O/M) |
| 403 MEMBERSHIP_NOT_ACTIVE         | Membresía suspendida o inactiva   | Informa membresía no habilitada       |
| 404 ESTABLISHMENT_NOT_FOUND       | Sede no existe en tenant          | Informa inconsistencia de sede        |
| 500 INTERNAL_SERVER_ERROR         | Fallo transaccional backend       | Ofrece reintento seguro               |
+-----------------------------------+-----------------------------------+---------------------------------------+
```

---

## 15. TEST ARCHITECTURE (FUTURA SUITE DE PRUEBAS)

Se planifica la creación de la suite `frontend/test/saas_crear_desde_cero_test.dart` con las siguientes pruebas:

1. **Test DTO Serialización:** Verificación de `CrearDesdeCeroBootstrapRequest.toJson()` con actividades, servicios y staff assignments.
2. **Test DTO Parsing:** Verificación de `ContextPackageResponse.fromJson()` procesando los 16 atributos canónicos y estado `READY_FOR_PRE_NODE_01`.
3. **Test Inyección Header:** Comprobación de que `CrearDesdeCeroService` envía `x-active-membership-id` correcto.
4. **Test Role Guard / Manejo 403:** Simulación de error `INSUFFICIENT_PROVISIONING_ROLE` y verificación de mensaje al usuario.
5. **Test Manejo de Bloqueos:** Verificación de renderizado ante respuesta `state: 'BLOCKED'` con arreglo de `blocks`.
6. **Test Flujo Exitoso:** Simulación de submit exitoso, cierre modal y retorno al Hub.
7. **Test Transitoriedad / Inmutabilidad:** Verificación estricta de que el servicio NO persiste datos en storage local.
8. **Test Aislamiento B2C:** Verificación de que el flujo no interactúa con modelos B2C (`ProviderModel`, `perfiles_prestador`).

---

## 16. DEPENDENCIAS

```
ActiveContextHolder (Fase 1)
        ↓
HubSalonScreen (Fase 4)
        ↓
CrearDesdeCeroWizardScreen (SCR-06)
        ↓
CrearDesdeCeroService
        ↓
POST /api/v1/saas/hub/onboarding/bootstrap
        ↓
Context Package Handover (PRE-NODO 01)
```

---

## 17. ARCHIVOS PROTEGIDOS (CERO MODIFICACIÓN)

* `frontend/lib/services/active_context_holder.dart` (INMUTABLE)
* `frontend/lib/services/api_service.dart` (INMUTABLE)
* `frontend/lib/screens/saas/available_context_selector_screen.dart` (INMUTABLE)
* `frontend/lib/screens/saas/hub_salon_screen.dart` (INMUTABLE en esta fase; integración futura documentada)
* `frontend/lib/main.dart` (INMUTABLE)
* Todos los archivos de backend, migraciones SQL y suites previas (INMUTABLES).

---

## 18. RIESGOS

1. **Riesgo de Acoplamiento con NODO-01:** Intentar ejecutar lógica de `public.services` o `perfiles_prestador` en el cliente.  
   *Mitigación:* El frontend solo compila y envía el DTO; la ingestión es 100% server-side en `PRE-NODO 01`.
2. **Riesgo de Violación de Rol en UI:** Que un colaborador `PROFESSIONAL` intente ejecutar el wizard.  
   *Mitigación:* Verificación de rol en UI (`activeContext.role == 'OWNER' || 'MANAGER'`) y compuerta estricta en backend (`403 INSUFFICIENT_PROVISIONING_ROLE`).

---

## 19. ARCHITECTURAL STOPS

```
================================================================================
                           ARCHITECTURAL STOP #1: JOURNEY
================================================================================
ESTADO: ACTIVO / INMUTABLE
REGLA: Prohibido modificar Login, Register o Journey en esta fase.
================================================================================

================================================================================
                           ARCHITECTURAL STOP #2: HUB MUTATION
================================================================================
ESTADO: ACTIVO / INMUTABLE
REGLA: HubSalonScreen permanece CERRADO. No modificar HubSalonScreen para agregar
       botones hasta que el Director autorice la fase de implementación.
================================================================================
```

---

## 20. DECISIONES REQUERIDAS DEL DIRECTOR

1. **Aprobación de la Arquitectura Física:** Validar y aprobar el diseño físico presentado en este documento.
2. **Estrategia de Navegación:** Confirmar si `CrearDesdeCeroWizardScreen` se abrirá como `MaterialPageRoute` modal desde `HubSalonScreen` (Recomendado bajo *No Route Without Consumer*) o si se requiere registrar una named route `/saas/crear-desde-cero`.
3. **Autorización de Implementación:** Emitir el GO formal para iniciar la construcción física de `crear_desde_cero_model.dart`, `crear_desde_cero_service.dart`, `crear_desde_cero_screen.dart` y `saas_crear_desde_cero_test.dart`.

================================================================================
                     FIN DE LA ARQUITECTURA FÍSICA FASE 6A
================================================================================
