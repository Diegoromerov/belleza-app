# NODO-07 — ARQUITECTURA FÍSICA v1.0
## Physical Architecture Specification — Flutter SaaS Client Infrastructure

================================================================================
PROJECT: GlowApp SaaS  
AUTHORITY: Director del Proyecto  
NODE IDENTIFIER: NODO-07  
NODE NAME: Canonical SaaS Screen Flow & Physical Architecture  
DOCUMENT VERSION: v1.0.0 (RECONCILED DRAFT)  
CLASSIFICATION: FORMAL PHYSICAL ARCHITECTURE DEFINITION — NO CODE IMPLEMENTED  
BASELINE CONTRACT: ncp/NODO-07-SAAS-SCREEN-FLOW-CONTRACT-v1.0.md (CLOSED / IMMUTABLE)  
STATUS: PHYSICAL ARCHITECTURE DRAFT / ENDPOINT RECONCILIATION COMPLETE / AWAITING DIRECTOR FINAL REVIEW 🟡  
================================================================================

---

## 1. SCOPE

El presente documento define la **Arquitectura Física** de la capa de presentación (Frontend Flutter) para la materialización del flujo canónico SaaS de GlowApp. 

### En Alcance:
1. Definición de la topología de componentes físicos en Flutter (`Screens`, `Services`, `State Holders`, `HTTP Interceptors`, `Models/DTOs`).
2. Mapeo físico de la cadena canónica de 13 etapas desde `PERSONA` hasta `OPERACIÓN SaaS`.
3. Especificación de integración con los contratos backend cerrados (`Context Resolution`, `Active Context`, `Hub Salón`, `Crear Desde Cero`, `NODO-01..NODO-06`).
4. Reconciliación forense y documental de todos los endpoints canónicos backend.
5. Fronteras estrictas de aislamiento del código heredado B2C Marketplace.
6. Identificación de bloqueos y dependencias no autorizadas (`ARCHITECTURAL STOPS` y `IMPLEMENTATION CONSTRAINTS`).

### Fuera de Alcance Absoluto:
- Modificación de código fuente (Dart, JS, SQL).
- Modificación de esquemas de base de datos o migraciones.
- Implementación de pantallas, widgets, servicios o guards.
- Modificación o alteración de nodos cerrados (Foundation a NODO-06, `public.bookings`).

---

## 2. AUTHORITY

### 2.1. Jerarquía de Autoridad
1. **Director del Proyecto GlowApp SaaS:** Autoridad máxima y exclusiva para la aprobación de arquitectura y levantamiento de bloqueos.
2. **NODO-07 Contract v1.0 (CLOSED / IMMUTABLE):** Fuente de verdad funcional y canónica para el flujo de pantallas.
3. **SOUL + Architectural Governance Protocol v1.0**
4. **Contratos Cerrados Backend:** Foundation (065/066), Context Resolution, Active Context, Hub Salón, Crear Desde Cero, Handover Boundary y NODO-01 a NODO-06.
5. **Código Flutter Existente:** Evidencia física del estado actual (no es fuente de verdad arquitectónica).

> [!IMPORTANT]
> Toda propuesta técnica no refrendada explícitamente por el Director queda clasificada como `PROPOSAL — NOT APPROVED`.

---

## 3. PHYSICAL ARCHITECTURE OVERVIEW

La arquitectura física desacopla formalmente el runtime de Flutter en dos subsistemas soberanos conectados a un núcleo común de identidad:

```
+---------------------------------------------------------------------------------------+
|                                    NÚCLEO DE IDENTIDAD                                |
|             Persona ──> Register (Neutral) ──> Account (DB) ──> Identity (JWT)         |
+-------------------------------------------┬-------------------------------------------+
                                            │
                                            ▼
                           +---------------------------------+
                           |   [JOURNEY DECISION BOUNDARY]   |  <── ARCHITECTURAL STOP A
                           +----------------┬----------------+
                                            │
               ┌────────────────────────────┴────────────────────────────┐
               ▼                                                         ▼
+-----------------------------+                           +-----------------------------+
|    SUBSISTEMA B2C LEGACY    |                           |    SUBSISTEMA SaaS SALÓN    |
| - Home / Marketplace Mapa   |                           | - SaaS Eligibility          |
| - IA Aura / Diagnósticos    |                           | - Available Context Selector|
| - ProviderDashboard (B2C)   |                           | - Active Context Holder     |
| - Client Bookings           |                           | - Hub Salón Cockpit         |
| (Sin header de membresía)   |                           | - Crear Desde Cero Wizard   |
+-----------------------------+                           | - Operación N02..N06        |
                                                          | (Header x-active-membership)|
                                                          +-----------------------------+
```

---

## 4. COMPONENT MODEL

Modelo físico de componentes propuestos para Flutter (sin implementar):

| Categoría | Nombre del Componente Físico | Responsabilidad Técnica | Dependencia Externa | Estado de Autorización |
| :--- | :--- | :--- | :--- | :---: |
| **HTTP** | `SaaSHttpClient` / `SaaSInterceptor` | Inyecta header `x-active-membership-id` en `/api/v1/saas/*` | `ActiveContextHolder` | `PROPOSAL` |
| **STATE** | `ActiveContextHolder` | Mantiene en memoria el `membership_id` activo | N/A (RAM de app) | `PROPOSAL` |
| **SERVICE** | `SaaSContextService` | Consume `GET /api/v1/saas/context/available` | `ApiService` | `PROPOSAL` |
| **SERVICE** | `HubSalonService` | Consume `GET /summary` y `GET /staff` | `SaaSHttpClient` | `PROPOSAL` |
| **SERVICE** | `CrearDesdeCeroService` | Consume `POST /api/v1/saas/hub/onboarding/bootstrap` | `SaaSHttpClient` | `PROPOSAL` |
| **SCREEN** | `AvailableContextSelectorScreen` | Interfaz de selección explícita para `MULTIPLE_CONTEXTS` | `SaaSContextService` | `PROPOSAL` |
| **SCREEN** | `HubSalonScreen` | Cockpit operacional de la sede activa | `HubSalonService` | `PROPOSAL` |
| **SCREEN** | `CrearDesdeCeroWizardScreen` | Asistente interactivo de aprovisionamiento de sede | `CrearDesdeCeroService` | `PROPOSAL` |
| **SCREEN** | `SaaSAgendaScreen` | Agenda operativa y máquina de estados NODO-06 | `AppointmentsService` | `PROPOSAL` |

---

## 5. NAVIGATION MODEL

### 5.1. Topología de Rutas
- **Rutas Comunes de Identidad:** `/login`, `/register`, `/forgot-password`.
- **Rutas B2C Soberanas:** `/home`, `/client-bookings`, `/provider` (aislada), `/ideas`, `/store`.
- **Rutas SaaS Soberanas (Prefijo `/saas/*`):**
  - `/saas/context-selector`
  - `/saas/hub`
  - `/saas/crear-desde-cero`
  - `/saas/agenda`
  - `/saas/services`
  - `/saas/staff`

### 5.2. Separación de Responsabilidades
- **Navigation State:** Control de historial y transiciones de pantalla en Flutter (`Navigator`).
- **Application Context:** Identificador de membresía activa en memoria (`ActiveContextHolder`).
- **Backend Authorization:** Validación transaccional de membresía, tenant y RLS en PostgreSQL.

---

## 6. STATE MODEL

1. **Identity State:** Mantiene el JWT obtenido en el login/register. Almacenado de forma segura vía `FlutterSecureStorage` (clave `'token'`).
2. **Available Context State:** Lista volátil de organizaciones, sedes y membresías devuelta por `GET /api/v1/saas/context/available`.
3. **Active Context State:** Representa el estado transaccional en tiempo de ejecución.
   - **Propietario:** `ActiveContextHolder` (singleton / provider en memoria).
   - **Contenido:** Exclusivamente `membership_id` (UUID v4).
   - **Invariante:** Cero auto-restauración, cero persistencia como autoridad y cero uso de almacenamiento local para forzar contextos previos sin validación explícita.

---

## 7. HTTP/API INTEGRATION MODEL

```
[Flutter UI Widget]
        │
        ▼
[SaaS Service Layer] (ej. HubSalonService)
        │
        ▼
[HTTP Client / Interceptor]
   ├── Agrega 'Authorization': 'Bearer <token>'
   └── Si la URL contiene '/api/v1/saas/' ──> Agrega 'x-active-membership-id': '<UUID>'
        │
        ▼
[Node.js Express Backend]
   ├── authMiddleware (Valida JWT -> req.user.id)
   ├── contextResolution / fn_resolve_user_tenant (Deriva req.tenantId)
   └── activeContextMiddleware (Valida header -> Inyecta req.activeContext + set_config RLS)
        │
        ▼
[PostgreSQL Database (beauty_db)] (RLS aplicado)
```

---

## 8. REGISTER BOUNDARY & CONSTRAINT

### 8.1. Diagnóstico Físico del Backend Actual
La inspección forense de `backend/src/controllers/authController.js:14-35` evidencia:
```javascript
const { full_name, email, password, phone, role } = req.body;
const userRole = (role && role.toUpperCase() === 'PRESTADOR') ? 'PRESTADOR' : 'CLIENTE';
const onboarding = (userRole === 'CLIENTE');

const result = await pool.query(
  `INSERT INTO usuarios (nombre, email, password_hash, phone, auth_provider, provider_id, rol, onboarding_completo) 
   VALUES ($1, $2, $3, $4, 'LOCAL', $5, $6, $7) ...`,
  [full_name, cleanEmail, hashedPassword, phone || null, providerId, userRole, onboarding]
);
```

### 8.2. Reclasificación de Dependencia (`IMPLEMENTATION CONSTRAINT`)
- Si el frontend omite el campo `role` en un registro neutral de persona, el backend actual asigna por defecto `rol = 'CLIENTE'` y `onboarding_completo = true`.
- Esto permite la creación física de la cuenta sin fallos 400 (`HTTP 201 Created`).
- **Naturaleza:** La columna `usuarios.rol` es un concepto B2C heredado sin autoridad en el subsistema SaaS. En SaaS, la autoridad y rol emanan estrictamente de `memberships.role`.
- **Reclasificación:** Pasa de ser un bloqueo arquitectónico a una **Restricción de Implementación / Dependencia Legacy** inocua para la arquitectura física del cliente Flutter.

---

## 9. JOURNEY BOUNDARY

### 9.1. Definición de la Frontera
Se formaliza la frontera física:
$$\text{IDENTITY (JWT)} \longrightarrow [\text{JOURNEY DECISION BOUNDARY}] \longrightarrow (\text{SaaS} \lor \text{B2C})$$

### 9.2. Estado de Gobernanza
- **ARCHITECTURAL STOP A:** El mecanismo físico exacto que operará dentro de `[JOURNEY DECISION BOUNDARY]` no está aprobado por el Director.
- Las opciones evaluadas (modal interactivo vs selector en AppBar) permanecen como `PROPOSAL — NOT APPROVED`.

---

## 10. SAAS ELIGIBILITY

- **Endpoint Físico Backend:** `GET /api/v1/saas/context/available`.
- **Integración Cliente:** El servicio cliente invocará este endpoint tras autenticar la identidad.
- **Autoridad:** El backend es la única autoridad para dictaminar si el usuario es elegible para operar en SaaS.

---

## 11. AVAILABLE CONTEXT

### 11.1. Manejo de Multiplicidad en la Capa Física
1. **`NO_CONTEXT` (0 membresías):** La interfaz muestra vista informativa y ofrece la ruta de onboarding/aprovisionamiento inicial.
2. **`ONE_CONTEXT` (1 membresía):** El cliente toma el único `membership_id` devuelto y avanza al Hub Salón.
3. **`MULTIPLE_CONTEXTS` (>1 membresías):** Despliegue obligatorio de `AvailableContextSelectorScreen`.
   - **Prohibición Física:** Cero algoritmos de auto-selección o restauración de última sede.

---

## 12. ACTIVE CONTEXT

- **Naturaleza Física:** Estado en memoria (`ActiveContextHolder`).
- **Transporte Obligatorio:** Header HTTP `x-active-membership-id: <UUID>`.
- **Prohibición Expresa:** Queda terminantemente prohibido utilizar identificadores sintéticos (`active_salon_id`, `active_establishment_id`, `active_tenant_id`, `current_branch_id`).

---

## 13. HUB SALÓN

- **Componente Físico:** `HubSalonScreen`.
- **Endpoints Físicos Consumidos:**
  - `GET /api/v1/saas/hub/summary`
  - `GET /api/v1/saas/hub/staff`
- **Aislamiento B2C:** `ProviderDashboardScreen` (3,053 líneas) se mantiene 100% aislada como consola de prestador domiciliario B2C.

---

## 14. CREATE FROM ZERO

- **Componente Físico:** `CrearDesdeCeroWizardScreen`.
- **Endpoint Canónico Verificado:**
  ```http
  POST /api/v1/saas/hub/onboarding/bootstrap
  ```
- **Comportamiento Físico:** El asistente captura datos en memoria (tránsito) y envía el payload estructurado del `Context Package` al endpoint de bootstrap.

---

## 15. PRE-NODO 01 BOUNDARY

- **Naturaleza Física:** Frontera arquitectónica backend de ingestión (*HBC Ingestion / NODO-01*).
- **Manifestación UI:** Cero pantallas técnicas de "Pre-Nodo 01". La UI únicamente muestra la confirmación de éxito y redirige a la operación.

---

## 16. N02..N06 INTEGRATION BOUNDARIES

Mapeo de integración reconciliado con los contratos cerrados del backend:

| Nodo Técnico | Endpoints Backend Canónicos Verificados | Operaciones / Componente UI Futuro | Restricción Arquitectónica |
| :--- | :--- | :--- | :--- |
| **NODO-02** | `POST /api/v1/saas/hub/services`<br>`GET /api/v1/saas/hub/services`<br>`PUT /api/v1/saas/hub/services/:id`<br>`POST /api/v1/saas/hub/assignments`<br>`GET /api/v1/saas/hub/assignments`<br>`DELETE /api/v1/saas/hub/assignments/:id` | Catálogo de Ofertas de Servicio y Asignaciones a Staff (`ServiceOffersScreen`) | Runtime Operacional de Ofertas y Staff. Requiere `x-active-membership-id`. |
| **NODO-03A** | `POST /api/v1/saas/hub/staff/:membership_id/schedule`<br>`GET /api/v1/saas/hub/staff/:membership_id/schedule`<br>`GET /api/v1/saas/hub/staff/schedules`<br>`DELETE /api/v1/saas/hub/staff/:membership_id/schedule` | Horarios Semanales de Disponibilidad del Personal (`StaffSchedulesScreen`) | Horarios Continuos Semanales. Ingestión y validación de solapamientos. |
| **NODO-04** | `POST /api/v1/saas/hub/materializations/services`<br>`GET /api/v1/saas/hub/materializations/services` | Ingestión y Auditoría de Materialización Marketplace (OP-01 / OP-02) | Sincronización Downstream B2C. Cero endpoint `/sync`. Error `409` si no autorizado. |
| **NODO-05** | `GET /api/v1/saas/hub/availability/check` | Visualizador / Selector de Slots de Disponibilidad | **Read-Only / Transient / Cero Creación de Citas**. |
| **NODO-06** | `POST /api/v1/saas/hub/appointments`<br>`PATCH /api/v1/saas/hub/appointments/:id/status`<br>`GET /api/v1/saas/hub/appointments/agenda`<br>`GET /api/v1/saas/hub/appointments/:id` | Agenda Operativa y Máquina de Estados (`SaaSAgendaScreen`) | **Creación de Citas, Restricciones GiST y Transiciones de Estado**. |

---

## 17. DIRECTOR ENDPOINT RECONCILIATION

A continuación se formaliza la tabla de evidencia forense de todos los endpoints del backend SaaS verificados contra el árbol de código fuente:

| Subsistema / Nodo | Endpoint Canónico | Método | Archivo de Ruta / Controlador | Verificación Forense |
| :--- | :--- | :---: | :--- | :---: |
| **Auth / Identity** | `/api/v1/auth/register` | `POST` | `backend/src/routes/authRoutes.js`<br>`backend/src/controllers/authController.js` | `VERIFIED` |
| **Auth / Identity** | `/api/v1/auth/login` | `POST` | `backend/src/routes/authRoutes.js`<br>`backend/src/controllers/authController.js` | `VERIFIED` |
| **Context Resolution**| `/api/v1/saas/context/available` | `GET` | `backend/src/routes/saasContextRoutes.js`<br>`backend/src/controllers/saasContextController.js` | `VERIFIED` |
| **Hub Salón** | `/api/v1/saas/hub/summary` | `GET` | `backend/src/routes/hubSalonRoutes.js`<br>`backend/src/controllers/hubSalonController.js` | `VERIFIED` |
| **Hub Salón** | `/api/v1/saas/hub/staff` | `GET` | `backend/src/routes/hubSalonRoutes.js`<br>`backend/src/controllers/hubSalonController.js` | `VERIFIED` |
| **Crear Desde Cero**| `/api/v1/saas/hub/onboarding/bootstrap`| `POST`| `backend/src/routes/crearDesdeCeroRoutes.js`<br>`backend/src/controllers/crearDesdeCeroController.js`| `VERIFIED` |
| **NODO-02** | `/api/v1/saas/hub/services` | `POST` | `backend/src/routes/serviceOfferRoutes.js`<br>`backend/src/controllers/serviceOfferController.js` | `VERIFIED` |
| **NODO-02** | `/api/v1/saas/hub/services` | `GET` | `backend/src/routes/serviceOfferRoutes.js`<br>`backend/src/controllers/serviceOfferController.js` | `VERIFIED` |
| **NODO-02** | `/api/v1/saas/hub/services/:id` | `PUT` | `backend/src/routes/serviceOfferRoutes.js`<br>`backend/src/controllers/serviceOfferController.js` | `VERIFIED` |
| **NODO-02** | `/api/v1/saas/hub/assignments` | `POST` | `backend/src/routes/serviceAssignmentRoutes.js`<br>`backend/src/controllers/serviceAssignmentController.js`| `VERIFIED` |
| **NODO-02** | `/api/v1/saas/hub/assignments` | `GET` | `backend/src/routes/serviceAssignmentRoutes.js`<br>`backend/src/controllers/serviceAssignmentController.js`| `VERIFIED` |
| **NODO-02** | `/api/v1/saas/hub/assignments/:id` | `DELETE`| `backend/src/routes/serviceAssignmentRoutes.js`<br>`backend/src/controllers/serviceAssignmentController.js`| `VERIFIED` |
| **NODO-03A** | `/api/v1/saas/hub/staff/:membership_id/schedule`| `POST/PUT`| `backend/src/routes/staffAvailabilityRoutes.js`<br>`backend/src/controllers/staffAvailabilityController.js`| `VERIFIED` |
| **NODO-03A** | `/api/v1/saas/hub/staff/:membership_id/schedule`| `GET` | `backend/src/routes/staffAvailabilityRoutes.js`<br>`backend/src/controllers/staffAvailabilityController.js`| `VERIFIED` |
| **NODO-03A** | `/api/v1/saas/hub/staff/schedules` | `GET` | `backend/src/routes/staffAvailabilityRoutes.js`<br>`backend/src/controllers/staffAvailabilityController.js`| `VERIFIED` |
| **NODO-03A** | `/api/v1/saas/hub/staff/:membership_id/schedule`| `DELETE`| `backend/src/routes/staffAvailabilityRoutes.js`<br>`backend/src/controllers/staffAvailabilityController.js`| `VERIFIED` |
| **NODO-04** | `/api/v1/saas/hub/materializations/services` | `POST` | `backend/src/routes/nodo04MaterializationRoutes.js`<br>`backend/src/controllers/nodo04MaterializationController.js` | `VERIFIED` |
| **NODO-04** | `/api/v1/saas/hub/materializations/services` | `GET` | `backend/src/routes/nodo04MaterializationRoutes.js`<br>`backend/src/controllers/nodo04MaterializationController.js` | `VERIFIED` |
| **NODO-05** | `/api/v1/saas/hub/availability/check` | `GET` | `backend/src/routes/nodo05AvailabilityRoutes.js`<br>`backend/src/controllers/nodo05AvailabilityController.js` | `VERIFIED` |
| **NODO-06** | `/api/v1/saas/hub/appointments` | `POST` | `backend/src/routes/nodo06AppointmentsRoutes.js`<br>`backend/src/controllers/nodo06AppointmentsController.js` | `VERIFIED` |
| **NODO-06** | `/api/v1/saas/hub/appointments/:id/status`| `PATCH`| `backend/src/routes/nodo06AppointmentsRoutes.js`<br>`backend/src/controllers/nodo06AppointmentsController.js` | `VERIFIED` |
| **NODO-06** | `/api/v1/saas/hub/appointments/agenda` | `GET` | `backend/src/routes/nodo06AppointmentsRoutes.js`<br>`backend/src/controllers/nodo06AppointmentsController.js` | `VERIFIED` |
| **NODO-06** | `/api/v1/saas/hub/appointments/:id` | `GET` | `backend/src/routes/nodo06AppointmentsRoutes.js`<br>`backend/src/controllers/nodo06AppointmentsController.js` | `VERIFIED` |

---

## 18. LEGACY ISOLATION

Límites de preservación física de componentes heredados:
- `home_screen.dart`: **KEEP / APPROVED ARCHITECTURE** (Marketplace B2C).
- `booking_tracking_screen.dart`: **KEEP / APPROVED ARCHITECTURE** (Rastreo B2C).
- `ideas/*`: **KEEP / APPROVED ARCHITECTURE** (Aura IA y VTO).
- `forgot_password_screen.dart`: **KEEP / APPROVED ARCHITECTURE** (Recuperación OTP).
- `onboarding_screen.dart`: **ISOLATE / LEGACY** (Documentos prestador B2C).
- `verification_pending_screen.dart`: **ISOLATE / LEGACY** (Revisión B2C).
- `provider_dashboard_screen.dart`: **ISOLATE / LEGACY** (Consola domiciliaria B2C).

---

## 19. FILE IMPACT MATRIX

| Archivo | Acción Física | Razón Arquitectónica | Dependencia | Riesgo | Clasificación de Estado |
| :--- | :---: | :--- | :--- | :---: | :---: |
| `frontend/lib/services/api_service.dart` | `MODIFY` | Inyección de `x-active-membership-id` | `ActiveContextHolder` | Bajo | `PROPOSAL` |
| `frontend/lib/services/saas_context_service.dart` | `NEW` | Consumo de `/api/v1/saas/context/*` | `ApiService` | Bajo | `PROPOSAL` |
| `frontend/lib/services/hub_salon_service.dart` | `NEW` | Consumo de `/api/v1/saas/hub/*` | `ApiService` | Bajo | `PROPOSAL` |
| `frontend/lib/screens/auth/register_screen.dart` | `MODIFY` | Limpieza de selector de rol B2C | Auth Backend | Bajo | `PROPOSAL` (Constraint B) |
| `frontend/lib/screens/auth/login_screen.dart` | `MODIFY` | Despacho hacia Journey | Journey Decision | Medio | `BLOCKED` (Stop A) |
| `frontend/lib/screens/saas/available_context_screen.dart` | `NEW` | Selector explícito de sede | `SaaSContextService` | Bajo | `PROPOSAL` |
| `frontend/lib/screens/saas/hub_salon_screen.dart` | `NEW` | Cockpit de sede activa | `HubSalonService` | Medio | `PROPOSAL` |
| `frontend/lib/screens/saas/crear_desde_cero_screen.dart` | `NEW` | Wizard de bootstrap | Bootstrap API | Medio | `PROPOSAL` |
| `frontend/lib/main.dart` | `MODIFY` | Registro de rutas `/saas/*` | Nuevas Screens | Bajo | `PROPOSAL` |

---

## 20. ARCHITECTURAL STOPS & CONSTRAINTS

```
================================================================================
                           ARCHITECTURAL STOP A
================================================================================
PROBLEMA:
El mecanismo físico de resolución de Journey post-login no está formalmente definido.

EVIDENCIA:
`login_screen.dart:49-60` utiliza un salto ciego basado en `role == 'provider'`,
ignorando el ecosistema multi-tenant y la coexistencia B2C/SaaS.

IMPACTO:
Bloquea la implementación de la navegación post-autenticación.

OPCIONES:
- Opción A: Modal interactivo post-login de selección de Journey.
- Opción B: Conmutador de modo en el AppBar sin diálogo obstructivo.

ESTADO:
BLOCKED / PROPOSAL — NOT APPROVED (Requiere Decisión del Director).
================================================================================
```

```
================================================================================
                      IMPLEMENTATION CONSTRAINT (EX-STOP B)
================================================================================
NATURALEZA:
La tabla backend `usuarios` posee la columna legacy `rol` y el controlador `authController.js`
asigna por defecto `rol = 'CLIENTE'` si el frontend no envía dicho campo.

EVIDENCIA:
`backend/src/controllers/authController.js:25-33`.

EVALUACIÓN ARQUITECTÓNICA:
El registro neutral no genera error HTTP en el backend. La persistencia de `rol = 'CLIENTE'`
es un valor default heredado de base de datos sin valor de autorización en el subsistema SaaS.
En SaaS, la autoridad reside en `memberships.role`.

ESTADO:
RESOLVED AS IMPLEMENTATION CONSTRAINT (No bloquea la Arquitectura Física).
================================================================================
```

---

## 21. IMPLEMENTATION SEQUENCE

Propuesta de orden de ejecución estrictamente condicionada:

1. **FASE 0 — Resolución de Stops Directivos:** Decisión sobre Journey (Stop A).  
   *Estado:* **PENDING DIRECTOR DECISION**
2. **FASE 1 — Infraestructura Base Cliente:** `ActiveContextHolder` y soporte de header en `ApiService`.  
   *Estado:* **CONTRACT REQUIRED**
3. **FASE 2 — Available Context & Selector:** `SaaSContextService` y `AvailableContextSelectorScreen`.  
   *Estado:* **CONTRACT REQUIRED**
4. **FASE 3 — Hub Salón Cockpit:** `HubSalonService` y `HubSalonScreen`.  
   *Estado:* **CONTRACT REQUIRED**
5. **FASE 4 — Crear Desde Cero Wizard:** Asistente de aprovisionamiento (`POST /bootstrap`).  
   *Estado:* **CONTRACT REQUIRED**
6. **FASE 5 — Operación SaaS (N02..N06):** Pantallas de Catálogo, Horarios y Agenda.  
   *Estado:* **CONTRACT REQUIRED (Fases posteriores)**

---

## 22. VALIDATION

La definición de Arquitectura Física aquí documentada cumple rigurosamente:
- Cero modificaciones sobre NODO-01 a NODO-06.
- Cero modificaciones sobre el Backend o Base de Datos.
- Cero invención de endpoints (todos verificados en código físico y contratos cerrados).
- Cero introducción de roles no canónicos o entidades sintéticas.
- Cero auto-selección o persistencia no autorizada de Active Context.
- Cero asimilación de `ProviderDashboardScreen` como Hub Salón.
- NODO-05 validado como Read-Only Pre-Check y NODO-06 como motor de citas y máquina de estados.

---

## 23. OPEN DECISIONS

1. **Decisión sobre Journey (Stop A):** Seleccionar el mecanismo físico de conmutación B2C vs SaaS para desbloquear la navegación post-login.

---

## 24. STATUS

```
================================================================================
                   ESTADO FORMAL DE NODO-07 PHYSICAL ARCHITECTURE
================================================================================
NODO: NODO-07 (Canonical SaaS Screen Flow & Physical Architecture)
CONTRATO: CLOSED / IMMUTABLE
PHYSICAL DISCOVERY: CLOSED / RECONCILED
PHYSICAL ARCHITECTURE DEFINITION: RECONCILED DRAFT (ncp/NODO-07-PHYSICAL-ARCHITECTURE-v1.0.md)
ENDPOINT RECONCILIATION: COMPLETE & VERIFIED FORENSICALLY
BLOQUEADOR ACTIVO: ARCHITECTURAL STOP A (Journey Resolution)
IMPLEMENTACIÓN: NOT AUTHORIZED
ESTADO: AWAITING DIRECTOR FINAL REVIEW 🟡
================================================================================
```
