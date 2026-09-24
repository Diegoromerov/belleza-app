# NODO-02 v1.0 — NODE CONTRACT (R1 RECONCILED)
## SaaS Catalog & Operational Assignment Runtime Protocol

**VERSION:** 1.0.0 (R1 Reconciled)  
**ESTADO:** CONTRACT RECONCILED — READY FOR DIRECTOR GATE 🔒  
**TIPO:** Runtime Architectural Node Contract / Operational Domain Specification  
**FASE METODOLÓGICA:** DEFINIR → VALIDAR → PRESENTAR AL DIRECTOR  
**AUTORIDAD RAÍZ:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `N02-NODE-CONTRACT-R1` (Reconciliación Directiva R1)  
**NIVEL DE ACCIÓN:** CONTRACT RECONCILIATION ONLY — ZERO IMPLEMENTATION AUTHORIZED  

**CONTRATOS Y ACTIVOS PROTEGIDOS E INTACTOS:**  
- `065_saas_foundation_core.sql` (SaaS Foundation Core)  
- `066_context_resolution_tenant_resolver.sql` (Context Resolution Engine)  
- `067_service_offers.sql` (SaaS Service Offers Physical Schema — Ratified)  
- `068_service_assignments.sql` (SaaS Service Assignments Physical Schema — Ratified)  
- `ACTIVE-CONTEXT-NODE-CONTRACT-v1.0.md` (Active Context Node)  
- `HUB-SALON-NODE-CONTRACT-v1.0.md` (Hub Salón Cockpit Overview Node)  
- `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md` (Crear Desde Cero Node)  
- `HANDOVER-BOUNDARY-CONTRACT-v1.0.md` (Handover Boundary Contract v1.0)  
- `NODO-01-NODE-CONTRACT-v1.0.md` (NODO-01 Handover Ingestion Engine)  
- `DEC-SE-001` & `DEC-SE-002` (Service Materialization & Schedule Independence)  
- `DEC-AS-001` a `DEC-AS-014` (Assignment ADRs)  
- `DEC-FC-001` (Foundation Compatibility Option A — Ratified)  
- `GOVERNANCE-STOP-001-CLOSURE-v1.0.md` (Governance Closure & Ratification)  
- `ARCH-BUNDLE-SO-ASSIGNMENT-RUNTIME-DISCOVERY-01.md` (Runtime Discovery Findings)  
- `Pre-Nodo 01` (B2C Core Marketplace & Bookings — Immutable)  

---

## 1. NODE_ID

```text
NODO-02-v1.0
```

---

## 2. NAME

```text
SaaS Catalog & Operational Assignment Runtime Protocol v1.0
```

---

## 3. TYPE

```text
Runtime Architectural Node Contract / Operational Domain Specification
```

---

## 4. PURPOSE (PROPÓSITO)

Formalizar y delimitar contractualmente el comportamiento en tiempo de ejecución (backend runtime) para la administración operativa exclusiva de:

1. **`SERVICE_OFFER`** (Catálogo durable de ofertas de servicio propias de la sede).
2. **`SERVICE_ASSIGNMENT`** (Relación asociativa durable $N:M$ entre oferta de servicio y membresía de personal profesional elegible).

Este nodo opera estrictamente dentro del contexto de una sede activa (`establishment_id`) y un tenant activo (`tenant_id`), consumiendo el contexto validado por `ACTIVE CONTEXT v1.0` bajo el aislamiento de PostgreSQL RLS y protegiendo de forma absoluta la frontera desacoplada con el marketplace B2C (`public.services`).

---

## 5. SCOPE (ALCANCE)

### Operaciones en Alcance Formal:

#### A. Dominio Service Offer:
1. **Creación de Oferta de Catálogo (`CREATE_SERVICE_OFFER`):** Registro de nombre, descripción opcional, duración base (>0) y precio base (>=0) en la sede activa.
2. **Listado de Ofertas de la Sede (`LIST_SERVICE_OFFERS`):** Consulta de la totalidad de ofertas de catálogo vinculadas al establecimiento activo.
3. **Consulta de Oferta por ID (`GET_SERVICE_OFFER_BY_ID`):** Obtención del detalle de una oferta específica verificando pertenencia estricta a la sede activa.
4. **Actualización Comercial de Oferta (`UPDATE_SERVICE_OFFER`):** Modificación controlada de nombre, descripción, duración base y precio base.

#### B. Dominio Assignment:
1. **Creación de Asignación (`CREATE_ASSIGNMENT`):** Vinculación explícita de un colaborador elegible (`membership_id`) a una oferta (`service_offer_id`) dentro de la sede activa.
2. **Listado de Asignaciones de la Sede (`LIST_ESTABLISHMENT_ASSIGNMENTS`):** Consulta del mapa completo de asignaciones de la sede activa.
3. **Consulta de Asignaciones por Colaborador (`GET_ASSIGNMENTS_BY_STAFF`):** Listado de ofertas asignadas a un colaborador específico.
4. **Consulta de Asignaciones por Oferta (`GET_ASSIGNMENTS_BY_OFFER`):** Listado de colaboradores habilitados para prestar una oferta específica.
5. **Desasignación Pura (`DELETE_ASSIGNMENT`):** Destrucción exclusiva del registro de asignación sin impacto colateral en ofertas ni membresías (`DEC-AS-012`).

---

## 6. NON-SCOPE (FUERA DE ALCANCE ABSOLUTO — MATERIAS PENDIENTES R4)

Quedan **estricta y expresamente excluidas** de este nodo las siguientes materias, las cuales **NO deben resolverse por inferencia**:

1. **Eliminación de Ofertas de Catálogo (`DELETE SERVICE_OFFER`):** Permanece `UNDEFINED / FUTURE DECISION`.
2. **Habilitación / Activación Comercial de Catálogo (`service_offers.is_active`):** Permanece `UNDEFINED / PENDING DECISION`.
3. **Taxonomías o Categorías de Servicio (`category`):** Permanece `UNDEFINED / FUTURE DESIGN`.
4. **Auditoría Histórica Física de Asignaciones (`DEC-AS-013-B/F`):** Permanece `UNDEFINED / FUTURE AUDIT SUBSYSTEM`.
5. **Publicación y Activación Comercial (`DEC-PUB-001`):** La asignación SaaS no constituye publicación ni disponibilidad comercial.
6. **Workflow de Publicación / Activación:** Permanece `UNDEFINED / FUTURE WORKFLOW`.
7. **Materialización Automática o Sincronización B2C (`public.services`):** Prohibido crear `provider_id`, crear registros en `public.services` o alterar tablas del marketplace (`DEC-SE-001`, `DEC-AS-003`).
8. **Perfiles B2C (`perfiles_prestador`):** Prohibida su creación o alteración.
9. **Gestión de Agenda, Citas y Turnos Horarios:** Pertenecen a futuros nodos de Agenda.
10. **Bookings / Reservas:** Pertenecen al motor B2C inmutable (Pre-Nodo 01).
11. **Punto de Venta (POS), Facturación, Pagos, Inventario y Clientes.**
12. **Componentes de Interfaz de Usuario (UI / Frontend).**
13. **Modificación de Foundation, HBC, NODO-01 o Pre-Nodo 01.**

---

## 7. INPUTS (CONTRATO DE ENTRADA)

El cliente HTTP interactúa con NODO-02 bajo el estándar de contexto activo:

### 7.1. Headers Obligatorios:
- `Authorization: Bearer <jwt_token>` (Identidad autenticada).
- `x-active-membership-id: <UUID>` (Identificador de la membresía activa seleccionada).

### 7.2. Prohibición de Parámetros de Autoridad en Payload:
```text
CLIENT INPUT       = ONLY JWT Token + x-active-membership-id Header + Resource Payload
SERVER DERIVATION  = tenant_id, organization_id, establishment_id, role, status
```
El servidor **RECHAZA INMEDIATAMENTE** (`400 Bad Request`) cualquier intento del cliente de especificar `tenant_id`, `establishment_id`, `organization_id`, `user_id` o `provider_id` en el body o query string para suplantar contexto o autoridad.

---

## 8. AUTHORITY MODEL (MODELO DE AUTORIDAD — RECONCILIACIÓN R2)

De conformidad con `DEC-AS-001` y la directiva R2:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                            AUTHORITY MATRIX                                 │
├──────────────────────────┬──────────────────────────────────────────────────┤
│ OPERACIÓN                │ CONDICIÓN DE AUTORIDAD REQUERIDA                 │
├──────────────────────────┼──────────────────────────────────────────────────┤
│ CREATE_SERVICE_OFFER     │ ACTIVE USER + ACTIVE MEMBERSHIP                  │
│                          │ + ROLE ∈ {OWNER, MANAGER} + ACTIVE CONTEXT       │
│                          │ + TARGET ESTABLISHMENT == ACTIVE ESTABLISHMENT   │
├──────────────────────────┼──────────────────────────────────────────────────┤
│ UPDATE_SERVICE_OFFER     │ ACTIVE USER + ACTIVE MEMBERSHIP                  │
│                          │ + ROLE ∈ {OWNER, MANAGER} + ACTIVE CONTEXT       │
│                          │ + TARGET ESTABLISHMENT == ACTIVE ESTABLISHMENT   │
├──────────────────────────┼──────────────────────────────────────────────────┤
│ CREATE_ASSIGNMENT        │ ACTIVE USER + ACTIVE MEMBERSHIP                  │
│                          │ + ROLE ∈ {OWNER, MANAGER} + ACTIVE CONTEXT       │
│                          │ + TARGET ESTABLISHMENT == ACTIVE ESTABLISHMENT   │
│                          │ + VALID SERVICE_OFFER                            │
│                          │ + TARGET MEMBERSHIP STATUS == ACTIVE             │
│                          │ + TARGET MEMBERSHIP REPRESENTS AN                │
│                          │   ELIGIBLE PROFESSIONAL CONTEXT                  │
├──────────────────────────┼──────────────────────────────────────────────────┤
│ DELETE_ASSIGNMENT        │ ACTIVE USER + ACTIVE MEMBERSHIP                  │
│                          │ + ROLE ∈ {OWNER, MANAGER} + ACTIVE CONTEXT       │
│                          │ + TARGET ESTABLISHMENT == ACTIVE ESTABLISHMENT   │
├──────────────────────────┼──────────────────────────────────────────────────┤
│ LIST_SERVICE_OFFERS      │ ROLE ∈ {OWNER, MANAGER, PROFESSIONAL, RECEPT.}   │
│ GET_SERVICE_OFFER_BY_ID  │ ROLE ∈ {OWNER, MANAGER, PROFESSIONAL, RECEPT.}   │
│ LIST_ASSIGNMENTS         │ ROLE ∈ {OWNER, MANAGER, PROFESSIONAL, RECEPT.}   │
│ GET_ASSIGNMENTS_BY_STAFF │ ROLE ∈ {OWNER, MANAGER, PROFESSIONAL, RECEPT.}   │
│ GET_ASSIGNMENTS_BY_OFFER │ ROLE ∈ {OWNER, MANAGER, PROFESSIONAL, RECEPT.}   │
└──────────────────────────┴──────────────────────────────────────────────────┘
```

> **Regla Estricta R2:** No asumir que cualquier `Membership ACTIVE` puede ser destino de asignación. No permitir inferencias arbitrarias desde `OWNER`, `MANAGER`, `RECEPTIONIST`, `capabilities`, `provider_id` ni `usuarios.rol`.

---

## 9. ACTIVE CONTEXT REQUIREMENTS (REQUISITOS DE CONTEXTO ACTIVO)

Toda invocación a NODO-02 debe ser pre-procesada por `activeContextMiddleware.js`, el cual garantiza:

1. `req.user.id` existe y es un entero válido.
2. `x-active-membership-id` es un UUID válido.
3. La membresía del actor existe, pertenece a `req.user.id` y tiene `status = 'ACTIVE'`.
4. Se inyectan en el objeto de request:
   - `req.tenantId` (INTEGER)
   - `req.establishmentId` (UUID)
   - `req.membershipId` (UUID)
   - `req.activeContext` (DTO de contexto con rol y relación)

---

## 10. NAMESPACE Y TRANSPORTE HTTP (RECONCILIACIÓN R3)

### Definición Formal de Transporte:
Las rutas de NODO-02 utilizan el prefijo de transporte `/api/v1/saas/hub/`:
- `/api/v1/saas/hub/services`
- `/api/v1/saas/hub/assignments`

### Clarificación Arquitectónica Inviolable (R3):
> **[DECLARACIÓN DE DISYUNCIÓN ARQUITECTÓNICA]:**  
> El namespace `/hub/` es exclusivamente una **decisión de transporte / enrutamiento HTTP** y **NO significa** que NODO-02 sea arquitectónicamente parte de `HUB-SALON-v1.0`.
> 
> - **`HUB-SALON-v1.0`:** Operational Cockpit / Sede Overview / Staff Overview (`/summary`, `/staff`).
> - **`NODO-02`:** SaaS Catalog & Operational Assignment Runtime Protocol.
> 
> Son dos nodos formal e independientemente delimitados. NODO-02 puede ser consumido desde la experiencia operacional de la consola del salón, pero **NO modifica, NO amplía ni altera el Node Contract de `HUB-SALON-v1.0`**.

---

## 11. SERVICE OFFER OPERATIONS (OPERACIONES DE SERVICE OFFER — RECONCILIACIÓN R1)

### 11.1. `CREATE_SERVICE_OFFER`
- **Ruta:** `POST /api/v1/saas/hub/services`
- **Autoridad:** `ROLE ∈ {OWNER, MANAGER}`
- **Payload:**
  ```json
  {
    "name": "Corte de Cabello Estilo & Cepillado",
    "description": "Corte y peinado profesional",
    "base_duration": 45,
    "base_price": 45000.00
  }
  ```
- **Invariantes:**
  - `name`: String no vacío (longitud 1..255).
  - `description`: String opcional (nullable).
  - `base_duration`: Entero estrictamente > 0.
  - `base_price`: Numérico estrictamente >= 0.00.
  - `tenant_id` y `establishment_id` inyectados desde `req.activeContext`.

### 11.2. `LIST_SERVICE_OFFERS`
- **Ruta:** `GET /api/v1/saas/hub/services`
- **Autoridad:** `ROLE ∈ {OWNER, MANAGER, PROFESSIONAL, RECEPTIONIST}`
- **Filtro SQL:** `WHERE establishment_id = req.establishmentId AND tenant_id = req.tenantId`.
- **Ordenamiento:** `ORDER BY created_at ASC`.

### 11.3. `GET_SERVICE_OFFER_BY_ID`
- **Ruta:** `GET /api/v1/saas/hub/services/:id`
- **Autoridad:** `ROLE ∈ {OWNER, MANAGER, PROFESSIONAL, RECEPTIONIST}`
- **Validación:** `:id` debe ser un UUID válido y pertenecer a `(req.establishmentId, req.tenantId)`.

### 11.4. `UPDATE_SERVICE_OFFER` (RECONCILIACIÓN R1 — INMUTABILIDAD ESTRUCTURAL)
- **Ruta:** `PUT /api/v1/saas/hub/services/:id`
- **Autoridad:** `ROLE ∈ {OWNER, MANAGER}`
- **Payload Permitido:** Modificaciones de `name`, `description`, `base_duration`, `base_price`.
- **Campos Estrictamente Inmutables (R1):**
  > **[PROHIBICIÓN ABSOLUTA R1]:** `UPDATE_SERVICE_OFFER` **NO PUEDE MODIFICAR**:
  > - `id`
  > - `tenant_id`
  > - `establishment_id`
  > 
  > Una oferta de servicio **NO PUEDE SER MOVIDA** de un establecimiento a otro. La pertenencia a `ESTABLISHMENT` forma parte indisoluble de su **identidad estructural**.
- **Actualización:** Fija `updated_at = CURRENT_TIMESTAMP`.

---

## 12. ASSIGNMENT OPERATIONS (OPERACIONES DE ASSIGNMENT — RECONCILIACIÓN R2)

### 12.1. `CREATE_ASSIGNMENT` (REGLA R2: ACTIVE PROFESSIONAL TARGET)
- **Ruta:** `POST /api/v1/saas/hub/assignments`
- **Autoridad:** `ROLE ∈ {OWNER, MANAGER}` (`DEC-AS-001`)
- **Payload:**
  ```json
  {
    "service_offer_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "membership_id": "7b12d3e4-8a90-4f5e-b123-456789abcdef"
  }
  ```
- **Validaciones Mandatorias Server-Side:**
  1. `service_offer_id`: UUID existente que pertenece a `(req.establishmentId, req.tenantId)` (`DEC-AS-005`).
  2. `membership_id`: UUID existente que pertenece a `(req.establishmentId, req.tenantId)` (`DEC-AS-006`).
  3. `membership.status`: Debe estar estrictamente en estado `'ACTIVE'` (`DEC-AS-001`, `DEC-AS-009`).
  4. `Active Professional Target (R2)`: La membresía target debe representar un contexto profesional elegible para prestar servicios en la sede activa.
  5. Unicidad de Pareja: Si ya existe una asignación para `(service_offer_id, membership_id)`, responder de forma determinista (`409 Conflict` / `ASSIGNMENT_ALREADY_EXISTS`).

### 12.2. `LIST_ESTABLISHMENT_ASSIGNMENTS`
- **Ruta:** `GET /api/v1/saas/hub/assignments`
- **Autoridad:** `ROLE ∈ {OWNER, MANAGER, PROFESSIONAL, RECEPTIONIST}`
- **Filtro SQL:** `WHERE establishment_id = req.establishmentId AND tenant_id = req.tenantId`.

### 12.3. `GET_ASSIGNMENTS_BY_STAFF`
- **Ruta:** `GET /api/v1/saas/hub/assignments/staff/:membership_id`
- **Autoridad:** `ROLE ∈ {OWNER, MANAGER, PROFESSIONAL, RECEPTIONIST}`
- **Filtro SQL:** `WHERE membership_id = :membership_id AND establishment_id = req.establishmentId AND tenant_id = req.tenantId`.

### 12.4. `GET_ASSIGNMENTS_BY_OFFER`
- **Ruta:** `GET /api/v1/saas/hub/assignments/offer/:service_offer_id`
- **Autoridad:** `ROLE ∈ {OWNER, MANAGER, PROFESSIONAL, RECEPTIONIST}`
- **Filtro SQL:** `WHERE service_offer_id = :service_offer_id AND establishment_id = req.establishmentId AND tenant_id = req.tenantId`.

### 12.5. `DELETE_ASSIGNMENT` (PURE UNASSIGNMENT)
- **Ruta:** `DELETE /api/v1/saas/hub/assignments/:id`
- **Autoridad:** `ROLE ∈ {OWNER, MANAGER}`
- **Semántica:** `DELETE FROM service_assignments WHERE id = :id AND establishment_id = req.establishmentId AND tenant_id = req.tenantId`.
- **Invariante:** Cero efectos colaterales sobre `service_offers` ni sobre `memberships` (`DEC-AS-012`).

---

## 13. VALIDATION RULES (REGLAS DE VALIDACIÓN TÉCNICA)

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                           VALIDATION SPECIFICATION                          │
├──────────────────────────┬──────────────────────────────────────────────────┤
│ CAMPO                    │ REGLAS DE VALIDACIÓN                             │
├──────────────────────────┼──────────────────────────────────────────────────┤
│ UUIDs (id, offer, member)│ Formato regex UUID v4 estricto                   │
│ name                     │ Type: string, min: 1, max: 255, trim whitespace │
│ description              │ Type: string | null, max: 2000, optional         │
│ base_duration            │ Type: integer, strictly > 0, max: 1440 (24h)     │
│ base_price               │ Type: number/numeric, strictly >= 0.00           │
│ membership target        │ status == 'ACTIVE', establishment == active_est, │
│                          │ represents active professional context           │
│ offer target             │ establishment == active_est, tenant == active_ten│
└──────────────────────────┴──────────────────────────────────────────────────┘
```

---

## 14. BUSINESS RULES (REGLAS DE NEGOCIO CERRADAS)

1. **`BR-N02-01` (Independencia Ontológica):** `SERVICE_OFFER` y `ASSIGNMENT` son entidades separadas. Una oferta puede existir con 0 colaboradores asignados.
2. **`BR-N02-02` (Validez Derivada):** `ASSIGNMENT` no posee máquina de estados propia (`status`). Si una membresía es suspendida o revocada (`status != 'ACTIVE'`), sus asignaciones pierden validez operativa de forma derivada (`DEC-AS-009`).
3. **`BR-N02-03` (Multiplicidad N:M):** Un colaborador puede atender múltiples ofertas; una oferta puede ser atendida por múltiples colaboradores (`DEC-AS-010`).
4. **`BR-N02-04` (Unicidad por Pareja):** Existe como máximo una relación activa simultánea por par `(service_offer_id, membership_id)` (`DEC-AS-011`).
5. **`BR-N02-05` (Desasignación Pura):** Eliminar una asignación no desactiva la oferta ni revoca la membresía (`DEC-AS-012`).
6. **`BR-N02-06` (Inmutabilidad de Sede R1):** `service_offers.establishment_id` e `id` son inmutables tras su creación.

---

## 15. SECURITY & RUNTIME SEPARATION (SEGURIDAD Y SEPARACIÓN)

### 15.1. Separación de Servicios Backend:
El contrato exige formalmente implementar dos servicios backend independientes:

```text
backend/src/services/
├── serviceOfferService.js        <-- Lógica pura de catálogo de ofertas
└── serviceAssignmentService.js   <-- Lógica pura de asignaciones N:M
```

Ambos servicios son orquestados a nivel HTTP por:
```text
backend/src/controllers/
├── serviceOfferController.js
└── serviceAssignmentController.js
```

### 15.2. Defensa en Profundidad:
1. Autenticación JWT (`authMiddleware`).
2. Resolución y Validación de Contexto Activo (`activeContextMiddleware`).
3. Verificación de Autoridad RBAC (`role IN ('OWNER', 'MANAGER')`).
4. Aislamiento Row-Level Security (`app.tenant_id`).
5. Foreign Keys Compuestas Triples en PostgreSQL DDL.

---

## 16. ROW-LEVEL SECURITY (RLS EXPECTATIONS)

Toda interacción de base de datos ejecutada por NODO-02 debe:

1. Abrir transacción o cliente de pool.
2. Ejecutar inmediatamente:
   ```sql
   SELECT set_config('app.tenant_id', $1, true);
   ```
   donde `$1` es el `req.tenantId` validado server-side.
3. Ejecutar las consultas SQL de negocio.
4. Liberar el cliente al pool.

---

## 17. TRANSACTIONAL EXPECTATIONS (EXPECTATIVAS TRANSACCIONALES)

- **Creación / Actualización:** Cada mutación debe ser atómica dentro de un bloque transaccional `BEGIN ... COMMIT`.
- **Integridad Foránea:** El motor PostgreSQL rechazará automáticamente cualquier discrepancia entre el `establishment_id` de la oferta y el de la membresía mediante las FKs compuestas triples `fk_service_assignments_service_offer` y `fk_service_assignments_membership`.

---

## 18. OUTPUT CONTRACT (CONTRATO DE SALIDA DTO)

### 18.1. Service Offer DTO:
```json
{
  "status": "success",
  "data": {
    "service_offer": {
      "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "tenant_id": 2,
      "establishment_id": "841b5d26-c479-432d-b0c9-6653343aa3f1",
      "name": "Corte de Cabello Estilo & Cepillado",
      "description": "Corte y peinado profesional",
      "base_duration": 45,
      "base_price": "45000.00",
      "created_at": "2026-09-11T05:39:55.085Z",
      "updated_at": "2026-09-11T05:39:55.085Z"
    }
  }
}
```

### 18.2. Assignment DTO:
```json
{
  "status": "success",
  "data": {
    "assignment": {
      "id": "b1234567-89ab-cdef-0123-456789abcdef",
      "tenant_id": 2,
      "establishment_id": "841b5d26-c479-432d-b0c9-6653343aa3f1",
      "service_offer_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "membership_id": "7b12d3e4-8a90-4f5e-b123-456789abcdef",
      "created_at": "2026-09-11T05:39:58.242Z"
    }
  }
}
```

---

## 19. ERROR / REJECTION MODEL (MODELO DE ERRORES)

```text
┌───────────────────────────────────────┬────────────┬─────────────────────────────────────────────────┐
│ CÓDIGO DE ERROR                       │ HTTP STATUS│ CAUSA / CONDICIÓN                               │
├───────────────────────────────────────┼────────────┼─────────────────────────────────────────────────┤
│ MISSING_ACTIVE_MEMBERSHIP_HEADER      │ 400        │ Header x-active-membership-id ausente           │
│ INVALID_MEMBERSHIP_UUID               │ 400        │ Header o parámetro UUID malformado              │
│ INVALID_PAYLOAD                       │ 400        │ Validación de campos fallida (duración, precio) │
│ IMMUTABLE_FIELD_MODIFICATION          │ 400        │ Intento de modificar id, tenant_id o est_id(R1) │
│ IDENTITY_NOT_FOUND                    │ 401        │ Token JWT inválido o ausente                    │
│ INSUFFICIENT_ROLE_AUTHORITY           │ 403        │ Usuario no posee rol OWNER o MANAGER            │
│ MEMBERSHIP_NOT_ACTIVE                 │ 403        │ Membresía target no está en estado ACTIVE       │
│ INELIGIBLE_PROFESSIONAL_TARGET        │ 403        │ Membresía no representa contexto profesional(R2)│
│ SERVICE_OFFER_NOT_FOUND               │ 404        │ Oferta no existe en la sede activa              │
│ MEMBERSHIP_NOT_FOUND                  │ 404        │ Membresía no existe en la sede activa           │
│ ASSIGNMENT_NOT_FOUND                  │ 404        │ Asignación no existe en la sede activa          │
│ ASSIGNMENT_ALREADY_EXISTS             │ 409        │ Par (service_offer_id, membership_id) duplicado │
│ CROSS_ESTABLISHMENT_MISMATCH          │ 422        │ Oferta y membresía pertenecen a sedes distintas │
│ INTERNAL_SERVER_ERROR                 │ 500        │ Error inesperado en base de datos o runtime     │
└───────────────────────────────────────┴────────────┴─────────────────────────────────────────────────┘
```

---

## 20. IDEMPOTENCY / DETERMINISM (IDEMPOTENCIA Y DETERMINISMO)

- Las operaciones `GET` son puramente de solo lectura y deterministas respecto al estado de la base de datos.
- Las operaciones `DELETE_ASSIGNMENT` son idempotentes (si el registro no existe, retornan `404` de forma consistente).
- La creación de duplicados de asignación está físicamente bloqueada por `uq_service_assignments_offer_membership`.

---

## 21. DEPENDENCIES (DEPENDENCIAS)

1. **`ACTIVE CONTEXT v1.0`:** Provee `activeContextMiddleware.js` y resolución de sede.
2. **PostgreSQL Database:** Tablas físicas `service_offers`, `service_assignments`, `memberships`, `establishments` y `tenants` creadas y ratificadas (`065`, `066`, `067`, `068`).
3. **Database Pool:** `backend/src/config/db.js` (`pg.Pool`).

---

## 22. PROTECTED ASSETS (ACTIVOS PROTEGIDOS)

NODO-02 **NO TIENE AUTORIZACIÓN** para modificar:
- `backend/src/services/nodo01Service.js`
- `backend/src/services/contextResolutionService.js`
- `backend/src/services/crearDesdeCeroService.js`
- `backend/src/services/hubSalonService.js` ni `HUB-SALON-NODE-CONTRACT-v1.0.md`.
- `backend/init.sql` ni tablas B2C (`public.services`, `perfiles_prestador`, `usuarios`, `reservas`).
- Migraciones de Foundation (`065`, `066`).

---

## 23. STATE MODEL (MODELO DE ESTADOS DE CICLO DE VIDA)

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       NODO-02 RUNTIME STATE MODEL                           │
│                                                                             │
│  [ACTIVE CONTEXT VALIDATED] ───► [RBAC AUTHORIZATION CHECK]                 │
│                                           │                                 │
│                                  (Authorized: OWNER/MGR)                    │
│                                           ▼                                 │
│                                  [TARGET ENTITY LOOKUP]                     │
│                                           │                                 │
│                           (Valid Offer & Eligible Staff)                    │
│                                           ▼                                 │
│                                 [ATOMIC TRANSACTION]                        │
│                                 • SET LOCAL app.tenant_id                   │
│                                 • INSERT / UPDATE / SELECT / DELETE         │
│                                 • COMMIT                                    │
│                                           ▼                                 │
│                                [STANDARDIZED DTO RESPONSE]                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 24. STOP CONDITIONS (CONDICIONES DE DETENCIÓN / ARCHITECTURAL STOP)

Si durante la futura implementación o ejecución se detecta:

1. Necesidad de crear columnas en `public.services` -> **ARCHITECTURAL STOP**.
2. Necesidad de inventar categorías o taxonomías -> **ARCHITECTURAL STOP**.
3. Necesidad de resolver `DELETE SERVICE_OFFER` sin directiva -> **ARCHITECTURAL STOP**.
4. Necesidad de introducir `is_active` en `service_offers` -> **ARCHITECTURAL STOP**.
5. Discrepancias en la verificación de contexto activo -> **ARCHITECTURAL STOP**.

---

## 25. IMPLEMENTATION BOUNDARY & CLOSURE CRITERIA (LÍMITES Y CIERRE)

> **[REGLA DE ORO]:** Este documento constituye exclusivamente la **ESPECIFICACIÓN FORMAL DEL CONTRATO RECONCILIADO**.  
> **CERO CÓDIGO** puede ser escrito hasta que el Director del Proyecto apruebe formalmente este contrato reconciliado.

El NODO-02 se considerará cerrado cuando:
1. El Director apruebe este Node Contract reconciliado (`NODO-02-NODE-CONTRACT-v1.0.md`).
2. Se emita el GOAL de implementación física de servicios y controladores.
3. La suite de pruebas alcance 100% PASS sin regresiones sobre Foundation, Active Context o NODO-01.
