# NODO-07 — DISCOVERY: NODO-02 UI / SCR-08 (SERVICE OFFERS & ASSIGNMENTS)
## GlowApp SaaS — Catálogo de Servicios de Sede y Matriz de Asignaciones

================================================================================
PROJECT: GlowApp SaaS  
AUTHORITY: Director del Proyecto GlowApp SaaS  
NODE IDENTIFIER: NODO-07 — DISCOVERY SCR-08 (NODO-02 UI)  
DOCUMENT CLASSIFICATION: ARCHITECTURAL DISCOVERY REPORT (FORENSIC & READ-ONLY)  
DATE: 2026-09-12  
STATUS: DISCOVERY COMPLETE / ARCHITECTURAL STOP / AWAITING DIRECTOR AUDIT 🟡  
================================================================================

---

## 1. OBJETIVO

Realizar el **Discovery Forense y Arquitectónico** para la futura capa de presentación (Frontend Flutter) de:

$$	ext{NODO-02: SERVICE OFFERS \& ASSIGNMENTS (SCR-08)}$$

El objetivo es determinar, mediante evidencia empírica del repositorio:
1. Los endpoints, controladores, servicios y restricciones reales cerrados en backend.
2. La arquitectura canónica para la gestión duradera de **Ofertas de Servicio** de la sede (`service_offers`) y su vinculación $	ext{N:M}$ con colaboradores activos (**Asignaciones** en `service_assignments`).
3. El diseño de componentes, modelos DTO, servicios y pantallas mínimas necesarias en Flutter (`ServiceOffersScreen` / `SCR-08`).
4. Las fronteras estrictas frente a `NODO-03A` (Horarios), `NODO-04` (Materialización B2C), `NODO-05` (Pre-Check Slots) y `NODO-06` (Agenda de Citas).

---

## 2. EVIDENCIA FORENSE BACKEND (READ-ONLY)

La inspección forense del backend confirma los siguientes contratos, tablas y archivos:

### 2.1. Base de Datos / Migraciones Físicas (Cerradas e Inmutables)
* **`backend/migrations/067_service_offers.sql`:**
  * Tabla: `service_offers`
  * Columnas: `id` (UUID PK), `tenant_id` (INT FK), `establishment_id` (UUID FK), `name` (VARCHAR 255), `description` (TEXT), `base_duration` (INT > 0, minutos), `base_price` (NUMERIC(10,2) >= 0.00), `created_at`, `updated_at`.
  * RLS: Políticas activas que filtran por `tenant_id = current_setting('app.tenant_id')::integer`.
  * Invariantes Físicas: **NO existe columna `is_active`** ni columna `category` en la tabla física de base de datos.
* **`backend/migrations/068_service_assignments.sql`:**
  * Tabla: `service_assignments`
  * Columnas: `id` (UUID PK), `tenant_id` (INT FK), `establishment_id` (UUID FK), `service_offer_id` (UUID FK), `membership_id` (UUID FK), `created_at`.
  * Restricción de Unicidad: `UNIQUE (service_offer_id, membership_id, establishment_id, tenant_id)`.
  * RLS: Políticas de aislamiento multitenant activas.

### 2.2. Capa de Rutas, Controladores y Servicios
* **Service Offers:**
  * `backend/src/routes/serviceOfferRoutes.js`: Define prefijo base `/api/v1/saas/hub/services`.
  * `backend/src/controllers/serviceOfferController.js`: `createServiceOffer`, `listServiceOffers`, `getServiceOfferById`, `updateServiceOffer`.
  * `backend/src/services/serviceOfferService.js`: Valida Active Context, RBAC (`OWNER`/`MANAGER` para mutaciones; `OWNER`/`MANAGER`/`PROFESSIONAL`/`RECEPTIONIST` para lectura), RLS e inmutabilidad de claves estructurales (R1).
* **Service Assignments:**
  * `backend/src/routes/serviceAssignmentRoutes.js`: Define prefijo base `/api/v1/saas/hub/assignments`.
  * `backend/src/controllers/serviceAssignmentController.js`: `createAssignment`, `listEstablishmentAssignments`, `getAssignmentsByStaff`, `getAssignmentsByOffer`, `deleteAssignment`.
  * `backend/src/services/serviceAssignmentService.js`: Valida `ACTIVE` status en target membership, target role elegible (`PROFESSIONAL`, `OWNER`, `MANAGER`), previene duplicados y ejecuta **Pure Unassignment** (`DEC-AS-012`).

### 2.3. Hallazgo de Montaje de Rutas en `backend/index.js`
* Las rutas de `serviceOfferRoutes.js` y `serviceAssignmentRoutes.js` están implementadas y testeadas en suites unitarias (`test_nodo02_runtime_suite.js`), pero requieren estar formalmente montadas en `backend/index.js`:
  ```javascript
  app.use('/api/v1/saas/hub/services', require('./src/routes/serviceOfferRoutes'));
  app.use('/api/v1/saas/hub/assignments', require('./src/routes/serviceAssignmentRoutes'));
  ```
  *(Nota Arquitectónica: Esto se documenta como prerrequisito para la fase de implementación; no se modifica backend en este Discovery).*

---

## 3. ENDPOINTS REALES (CONTRATO HTTP)

### 3.1. Namespace: `/api/v1/saas/hub/services` (Service Offers)
| Endpoint | Método | Auth / Context Requerido | Roles Autorizados | Propósito |
| :--- | :---: | :--- | :---: | :--- |
| `/api/v1/saas/hub/services` | POST | Bearer JWT + `x-active-membership-id` | `OWNER`, `MANAGER` | Crear nueva oferta de servicio en la sede |
| `/api/v1/saas/hub/services` | GET | Bearer JWT + `x-active-membership-id` | `OWNER`, `MANAGER`, `PROFESSIONAL`, `RECEPTIONIST` | Listar todas las ofertas de la sede activa |
| `/api/v1/saas/hub/services/:id` | GET | Bearer JWT + `x-active-membership-id` | `OWNER`, `MANAGER`, `PROFESSIONAL`, `RECEPTIONIST` | Consultar detalle de una oferta por UUID |
| `/api/v1/saas/hub/services/:id` | PUT | Bearer JWT + `x-active-membership-id` | `OWNER`, `MANAGER` | Actualizar nombre, descripción, duración o precio |

> [!NOTE]
> **OPERACIÓN DELETE NO EXISTE EN SERVICE OFFERS:**
> Por diseño del contrato NODO-02, las ofertas no se eliminan físicamente para preservar la integridad histórica y referencias operacionales.

---

### 3.2. Namespace: `/api/v1/saas/hub/assignments` (Service Assignments)
| Endpoint | Método | Auth / Context Requerido | Roles Autorizados | Propósito |
| :--- | :---: | :--- | :---: | :--- |
| `/api/v1/saas/hub/assignments` | POST | Bearer JWT + `x-active-membership-id` | `OWNER`, `MANAGER` | Asignar un colaborador a una oferta |
| `/api/v1/saas/hub/assignments` | GET | Bearer JWT + `x-active-membership-id` | `OWNER`, `MANAGER`, `PROFESSIONAL`, `RECEPTIONIST` | Listar todas las asignaciones de la sede |
| `/api/v1/saas/hub/assignments/staff/:membership_id` | GET | Bearer JWT + `x-active-membership-id` | `OWNER`, `MANAGER`, `PROFESSIONAL`, `RECEPTIONIST` | Consultar ofertas asignadas a 1 colaborador |
| `/api/v1/saas/hub/assignments/offer/:service_offer_id` | GET | Bearer JWT + `x-active-membership-id` | `OWNER`, `MANAGER`, `PROFESSIONAL`, `RECEPTIONIST` | Consultar colaboradores asignados a 1 oferta |
| `/api/v1/saas/hub/assignments/:id` | DELETE | Bearer JWT + `x-active-membership-id` | `OWNER`, `MANAGER` | **Pure Unassignment** (desvincular relación) |

---

## 4. PAYLOADS REALES (REQUEST / RESPONSE)

### 4.1. Crear / Actualizar Service Offer
* **Request (`POST /api/v1/saas/hub/services`):**
  ```json
  {
    "name": "Corte de Cabello Signature",
    "description": "Corte personalizado con lavado y peinado",
    "base_duration": 45,
    "base_price": 35000.00
  }
  ```
* **Response (201 Created):**
  ```json
  {
    "status": "success",
    "data": {
      "service_offer": {
        "id": "e4b2d3c1-7a89-4f5e-b123-456789abcdef",
        "tenant_id": 2,
        "establishment_id": "a1b2c3d4-0000-0000-0000-000000000001",
        "name": "Corte de Cabello Signature",
        "description": "Corte personalizado con lavado y peinado",
        "base_duration": 45,
        "base_price": "35000.00",
        "created_at": "2026-09-12T13:40:00.000Z",
        "updated_at": "2026-09-12T13:40:00.000Z"
      }
    }
  }
  ```

### 4.2. Listar Service Offers
* **Response (`GET /api/v1/saas/hub/services` — 200 OK):**
  ```json
  {
    "status": "success",
    "data": {
      "service_offers": [
        {
          "id": "e4b2d3c1-7a89-4f5e-b123-456789abcdef",
          "tenant_id": 2,
          "establishment_id": "a1b2c3d4-0000-0000-0000-000000000001",
          "name": "Corte de Cabello Signature",
          "description": "Corte personalizado con lavado y peinado",
          "base_duration": 45,
          "base_price": "35000.00",
          "created_at": "2026-09-12T13:40:00.000Z",
          "updated_at": "2026-09-12T13:40:00.000Z"
        }
      ],
      "count": 1
    }
  }
  ```

### 4.3. Crear Assignment
* **Request (`POST /api/v1/saas/hub/assignments`):**
  ```json
  {
    "service_offer_id": "e4b2d3c1-7a89-4f5e-b123-456789abcdef",
    "membership_id": "b789c012-3456-789a-bcde-f0123456789a"
  }
  ```
* **Response (201 Created):**
  ```json
  {
    "status": "success",
    "data": {
      "assignment": {
        "id": "c123d456-789a-bcde-f012-3456789abcde",
        "tenant_id": 2,
        "establishment_id": "a1b2c3d4-0000-0000-0000-000000000001",
        "service_offer_id": "e4b2d3c1-7a89-4f5e-b123-456789abcdef",
        "membership_id": "b789c012-3456-789a-bcde-f0123456789a",
        "created_at": "2026-09-12T13:40:00.000Z"
      }
    }
  }
  ```

### 4.4. Eliminar Assignment (Pure Unassignment)
* **Response (`DELETE /api/v1/saas/hub/assignments/:id` — 200 OK):**
  ```json
  {
    "status": "success",
    "data": {
      "deleted_id": "c123d456-789a-bcde-f012-3456789abcde",
      "unassigned": true
    }
  }
  ```

---

## 5. MATRIZ DE AUTORIZACIÓN Y ROLES SERVER-SIDE

El backend es la única autoridad sobre permisos y acceso:

| Operación | OWNER | MANAGER | PROFESSIONAL | RECEPTIONIST | Error ante Rol Insuficiente |
| :--- | :---: | :---: | :---: | :---: | :--- |
| Crear Oferta de Servicio | ✅ | ✅ | ❌ | ❌ | `403 INSUFFICIENT_ROLE_AUTHORITY` |
| Modificar Oferta de Servicio | ✅ | ✅ | ❌ | ❌ | `403 INSUFFICIENT_ROLE_AUTHORITY` |
| Consultar Ofertas | ✅ | ✅ | ✅ | ✅ | N/A |
| Crear Asignación | ✅ | ✅ | ❌ | ❌ | `403 INSUFFICIENT_ROLE_AUTHORITY` |
| Eliminar Asignación (Unassign) | ✅ | ✅ | ❌ | ❌ | `403 INSUFFICIENT_ROLE_AUTHORITY` |
| Consultar Asignaciones | ✅ | ✅ | ✅ | ✅ | N/A |

> [!IMPORTANT]
> **UX VISIBILITY $
eq$ AUTHORIZATION:**
> En la interfaz Flutter, si el usuario autenticado tiene rol `PROFESSIONAL` o `RECEPTIONIST`, los botones de creación/edición/desvinculación deben ocultarse o deshabilitarse visualmente, pero la compuerta de seguridad fundamental reside en el backend.

---

## 6. INTEGRACIÓN CON ACTIVE CONTEXT

* **Consumo Transparente:** La capa de UI y el servicio de NODO-02 consumen `ActiveContextHolder.instance`.
* **Transporte Obligatorio:** Toda petición a `/api/v1/saas/hub/services*` y `/api/v1/saas/hub/assignments*` inyecta automáticamente el header `x-active-membership-id: <UUID>` a través de `ApiService`.
* **Derivación de Sede:** El `establishment_id` **NUNCA** se envía en el body ni se selecciona arbitrariamente en el frontend; el backend lo resuelve server-side a partir de la membresía activa (`req.establishmentId`).

---

## 7. ARQUITECTURA DE SERVICE OFFERS

1. **Entidad Durable:** Las ofertas representan los servicios que la sede física ofrece a sus clientes.
2. **Inmutabilidad Estructural (R1):** Una oferta pertenece a un establecimiento y un tenant de por vida. No puede cambiarse de sede.
3. **Restricciones de Validación:**
   - `name`: 1 a 255 caracteres, no vacío.
   - `description`: Texto opcional, máx 2000 caracteres.
   - `base_duration`: Entero strictly $> 0$ y $\le 1440$ (24 horas).
   - `base_price`: Decimal $\ge 0.00$.

---

## 8. ARQUITECTURA DE ASSIGNMENTS

1. **Relación N:M:** Un colaborador puede tener múltiples servicios asignados; un servicio puede tener múltiples colaboradores habilitados.
2. **Regla de Unicidad:** Máximo 1 asignación activa simultánea por par `(service_offer_id, membership_id)`. Duplicados retornan `409 ASSIGNMENT_ALREADY_EXISTS`.
3. **Elegibilidad de Personal (R2):** La membresía destino debe estar en estado `ACTIVE` y pertenecer a un rol profesional operativo (`PROFESSIONAL`, `OWNER`, `MANAGER`).
4. **Pure Unassignment (`DEC-AS-012`):** `DELETE /assignments/:id` destruye exclusivamente la tupla de asignación. La oferta de servicio y la membresía del personal permanecen intactas.

---

## 9. EVIDENCIA FORENSE FRONTEND

* **Componentes Cerrados e Inmutables Reutilizables:**
  * `ActiveContextHolder`: Gestión de memoria del `membership_id`.
  * `ApiService`: Inyección de headers y llamadas HTTP.
  * `HubStaffMember` (`frontend/lib/models/saas/hub_salon_model.dart`): Reutilizable para mostrar el nombre y avatar de los colaboradores al gestionar asignaciones.
* **Componentes Faltantes (A Desarrollar para SCR-08):**
  * `frontend/lib/models/saas/service_offer_model.dart`
  * `frontend/lib/services/saas/service_offer_service.dart`
  * `frontend/lib/screens/saas/service_offers_screen.dart`

---

## 10. COMPONENTES PROPUESTOS (FRONTEND)

```
frontend/lib/
├── models/saas/
│   └── service_offer_model.dart
│       ├── ServiceOfferModel (DTO de Oferta)
│       ├── CreateServiceOfferRequest / UpdateServiceOfferRequest
│       ├── ServiceOfferListResponse
│       ├── ServiceAssignmentModel (DTO de Asignación)
│       ├── CreateAssignmentRequest
│       └── AssignmentListResponse
├── services/saas/
│   └── service_offer_service.dart
│       ├── listServiceOffers()
│       ├── createServiceOffer(request)
│       ├── getServiceOfferById(id)
│       ├── updateServiceOffer(id, request)
│       ├── listAssignments()
│       ├── createAssignment(offerId, membershipId)
│       ├── getAssignmentsByOffer(offerId)
│       ├── getAssignmentsByStaff(membershipId)
│       └── deleteAssignment(assignmentId)
└── screens/saas/
    └── service_offers_screen.dart (SCR-08)
        ├── Tab 1: "Catálogo de Servicios" (Lista de ofertas + Diálogo de creación/edición)
        └── Tab 2: "Asignación de Personal" (Matriz de colaboradores por servicio + Toggle de vinculación)
```

---

## 11. NAVEGACIÓN PROPUESTA

* **Regla Canónica *No Route Without Consumer*:**
  - `ServiceOffersScreen` se invoca inicialmente desde el cockpit de `HubSalonScreen` como navegación modal o push directo:
    ```dart
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceOffersScreen()));
    ```
  - La ruta nombrada `'/saas/services'` se evaluará para registro en `main.dart` únicamente cuando exista un consumidor declarativo explícito.
  - **No modificar `main.dart` ni `HubSalonScreen` en esta fase.**

---

## 12. DEPENDENCIAS ARQUITECTÓNICAS

```
ActiveContextHolder (Fase 1)
        ↓ (Header x-active-membership-id)
HubSalonScreen (Fase 4 Cockpit)
        ↓
ServiceOffersScreen (SCR-08 / NODO-02 UI)
        ↓
ServiceOfferService
        ↓
POST / GET / PUT /api/v1/saas/hub/services
POST / GET / DELETE /api/v1/saas/hub/assignments
        ↓
NODO-02 Backend (service_offers, service_assignments)
```

---

## 13. FRONTERAS FRENTE A NODOS POSTERIORES (03A, 04, 05, 06)

1. **Frontera con NODO-03A (Staff Schedules):** NODO-02 define *qué servicios puede realizar el staff*; NODO-03A define *en qué horarios trabaja el staff*. SCR-08 no configura horarios de personal.
2. **Frontera con NODO-04 (B2C Materialization):** NODO-02 define las ofertas internas de sede; NODO-04 proyecta dichas ofertas hacia el marketplace B2C. SCR-08 no gestiona la publicación B2C.
3. **Frontera con NODO-05 (Availability Pre-Check):** NODO-05 calcula la disponibilidad en tiempo real intersectando horarios y citas. SCR-08 es un catálogo estático / asignación.
4. **Frontera con NODO-06 (Agenda & Citas):** NODO-06 crea citas asociando un cliente con una oferta de NODO-02 y un staff asignado en NODO-02. SCR-08 no genera citas.

---

## 14. RIESGOS Y MITIGACIONES

1. **Riesgo: Intentar implementar DELETE en Service Offers.**  
   *Mitigación:* El backend no expone `DELETE /services/:id`. La UI solo provee edición (`PUT`) y listado (`GET`).
2. **Riesgo: Intentar crear categorías relacionales o taxonomías no contractuales.**  
   *Mitigación:* La tabla `service_offers` no posee columna `category`. La UI debe apegarse estrictamente a `name`, `description`, `base_duration`, `base_price`.
3. **Riesgo: Intentar realizar autorizaciones en cliente.**  
   *Mitigación:* Toda mutación es validada server-side; el frontend solo maneja feedback visual determinista ante errores `403`.

---

## 15. ARCHITECTURAL STOPS VIGENTES

```
================================================================================
                           ARCHITECTURAL STOP #1: JOURNEY
================================================================================
ESTADO: ACTIVO / INMUTABLE
REGLA: Prohibido modificar Login, Register o Journey en esta fase.
================================================================================

================================================================================
                           ARCHITECTURAL STOP #2: BACKEND IMMUTABILITY
================================================================================
ESTADO: ACTIVO / INMUTABLE
REGLA: NODO-02 Backend (067/068) y Fases 1 a 6A permanecen inmutables.
       Zero modificaciones de código en esta fase de Discovery.
================================================================================
```

---

## 16. TEST ARCHITECTURE (FUTURA SUITE DE PRUEBAS)

Se planifica la suite `frontend/test/saas_service_offers_test.dart` cubriendo:

1. **Service Offers DTOs:** Serialización y deserialización de `ServiceOfferModel`, `CreateServiceOfferRequest`, `UpdateServiceOfferRequest`.
2. **Assignments DTOs:** Serialización y deserialización de `ServiceAssignmentModel`, `CreateAssignmentRequest`.
3. **Service Offer Operations:** Mapeo de `listServiceOffers()`, `createServiceOffer()`, `updateServiceOffer()`.
4. **Assignment Operations:** Mapeo de `listAssignments()`, `createAssignment()`, `deleteAssignment()` (Pure Unassignment).
5. **Control de Errores & RBAC:** Verificación de manejo determinista de `403 INSUFFICIENT_ROLE_AUTHORITY`, `409 ASSIGNMENT_ALREADY_EXISTS`, `404 SERVICE_OFFER_NOT_FOUND`.
6. **Active Context Header:** Verificación de inyección de `x-active-membership-id`.
7. **Invariante de Inmutabilidad:** `ActiveContextHolder` permanece inmutable tras cada operación.
8. **Aislamiento B2C:** Cero interacción con modelos legacy de `ProviderModel` o `perfiles_prestador`.

---

## 17. RECOMENDACIÓN TÉCNICA DEL AGENTE

1. Proceder a la redacción de la **Arquitectura Física Formal de NODO-02 UI (SCR-08)** consolidando los modelos DTO, el servicio `ServiceOfferService` y la pantalla `ServiceOffersScreen`.
2. En la fase de implementación posterior, asegurar el montaje de las rutas en `backend/index.js` para los namespaces `/api/v1/saas/hub/services` y `/api/v1/saas/hub/assignments`.

---

## 18. DECISIÓN REQUERIDA DEL DIRECTOR

* [ ] **DECISIÓN 1:** Aprobar este Discovery de NODO-02 UI / SCR-08 y autorizar la construcción de la **Arquitectura Física Formal**.
* [ ] **DECISIÓN 2:** Instrucción directiva alternativa.

================================================================================
                     FIN DEL DISCOVERY NODO-02 UI (SCR-08)
================================================================================
