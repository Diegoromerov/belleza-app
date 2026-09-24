# NODO-02 v1.0 — IMPLEMENTATION CONTRACT
## SaaS Catalog & Operational Assignment Runtime Implementation Specification

**VERSION:** 1.0.0  
**ESTADO:** CONTRACT DRAFT — READY FOR DIRECTOR GATE 🔒  
**TIPO:** Technical Implementation Contract / Runtime Engineering Specification  
**FASE METODOLÓGICA:** DEFINIR → RELACIONAR → VALIDAR → PRESENTAR AL DIRECTOR  
**AUTORIDAD RAÍZ:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `GOAL — N02-IMPLEMENTATION-CONTRACT-01`  
**NIVEL DE ACCIÓN:** IMPLEMENTATION CONTRACT SPECIFICATION ONLY — ZERO RUNTIME CODE / ZERO DDL AUTHORIZED  

**DOCUMENTOS BASE Y ACTIVOS PROTEGIDOS INTACTOS:**  
- [`NODO-02-NODE-CONTRACT-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NODO-02-NODE-CONTRACT-v1.0.md) (Aprobado y Cerrado)
- `065_saas_foundation_core.sql` (SaaS Foundation Core Schema)
- `066_context_resolution_tenant_resolver.sql` (Context Resolution Engine)
- `067_service_offers.sql` (SaaS Service Offers Physical Schema — Applied/Ratified/Closed)
- `068_service_assignments.sql` (SaaS Service Assignments Physical Schema — Applied/Ratified/Closed)
- `ACTIVE-CONTEXT-NODE-CONTRACT-v1.0.md` (Active Context Node Contract)
- `HUB-SALON-NODE-CONTRACT-v1.0.md` (Hub Salón Cockpit Overview Node Contract)
- `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md` (Crear Desde Cero Node Contract)
- `HANDOVER-BOUNDARY-CONTRACT-v1.0.md` (Handover Boundary Contract v1.0)
- `NODO-01-NODE-CONTRACT-v1.0.md` (NODO-01 Handover Ingestion Engine)
- `DEC-SE-001` & `DEC-SE-002` (Service Materialization & Schedule Independence)
- `DEC-AS-001` a `DEC-AS-014` (Assignment ADRs)
- `DEC-FC-001` (Foundation Compatibility Option A — Ratified)
- `GOVERNANCE-STOP-001-CLOSURE-v1.0.md` (Governance Closure & Ratification)
- `ARCH-BUNDLE-SO-ASSIGNMENT-RUNTIME-DISCOVERY-01.md` (Runtime Discovery Findings)
- `Pre-Nodo 01` (B2C Core Marketplace & Bookings — Immutable)

---

## 1. IMPLEMENTATION OBJECTIVE

Establecer la especificación técnica, determinista y exhaustiva para la implementación en código del **NODO-02 (SaaS Catalog & Operational Assignment Runtime)**, definiendo:

1. La arquitectura modular y desacoplada de controladores, servicios y rutas en backend Node.js / Express.
2. El consumo riguroso de la infraestructura de base de datos física ya existente y ratificada (`service_offers`, `service_assignments`, `memberships`, `establishments`, `tenants`).
3. El aislamiento estricto por tenant y sede activa (`activeContextMiddleware`, `SET LOCAL app.tenant_id = $1`, RLS y Foreign Keys compuestas).
4. El régimen de validación, manejo determinista de errores HTTP/JSON y transaccionalidad atómica.
5. El plan de pruebas unitarias, de integración, de aislamiento y de no-regresión que validará la futura implementación.

> **[REGLA FUNDAMENTAL DE GOBERNANZA]:**  
> Este contrato **NO IMPLEMENTA CÓDIGO**. Se rige por el principio **"NO CODE BEFORE CONTRACT"**.

---

## 2. NODE CONTRACT REFERENCE

Este contrato de implementación deriva formalmente de y se subordina a:

- **Documento Rector:** [`/ncp/NODO-02-NODE-CONTRACT-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NODO-02-NODE-CONTRACT-v1.0.md) (v1.0.0, R1 Reconciled).
- **Decisiones Fundacionales Clave:**
  - `DEC-AS-001` (RBAC: Solo `OWNER` o `MANAGER` administran asignaciones).
  - `DEC-AS-002` / `DEC-AS-006` (Asignación como relación $N:M$ pura).
  - `DEC-AS-005` (La oferta pertenece a la sede y es independiente del personal).
  - `DEC-AS-009` (La validez operativa de la asignación deriva del estado `ACTIVE` de la membresía).
  - `DEC-AS-011` (Unicidad estricta del par `(service_offer_id, membership_id)`).
  - `DEC-AS-012` (Desasignación pura: `DELETE_ASSIGNMENT` no destruye ofertas ni membresías).
  - `DEC-FC-001` (Compatibilidad de Foundation: FKs compuestas triples validadas).
  - `DEC-SE-001` & `DEC-PUB-001` (Desacoplamiento total de `public.services` y marketplace B2C).

---

## 3. IMPLEMENTATION SCOPE

El alcance de implementación abarca exclusivamente las 9 operaciones funcionales de NODO-02:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                           NODO-02 FUNCTIONAL SCOPE                          │
├─────────────────────────────────────────────────────────────────────────────┤
│ DOMINIO SERVICE OFFER (Catálogo Durable de Sede)                            │
│  1. CREATE_SERVICE_OFFER       POST   /api/v1/saas/hub/services             │
│  2. LIST_SERVICE_OFFERS        GET    /api/v1/saas/hub/services             │
│  3. GET_SERVICE_OFFER_BY_ID    GET    /api/v1/saas/hub/services/:id         │
│  4. UPDATE_SERVICE_OFFER       PUT    /api/v1/saas/hub/services/:id         │
├─────────────────────────────────────────────────────────────────────────────┤
│ DOMINIO SERVICE ASSIGNMENT (Relación Operativa N:M)                         │
│  5. CREATE_ASSIGNMENT          POST   /api/v1/saas/hub/assignments          │
│  6. LIST_ESTABLISHMENT_ASSIGN. GET    /api/v1/saas/hub/assignments          │
│  7. GET_ASSIGNMENTS_BY_STAFF   GET    /api/v1/saas/hub/assignments/staff/:id│
│  8. GET_ASSIGNMENTS_BY_OFFER   GET    /api/v1/saas/hub/assignments/offer/:id│
│  9. DELETE_ASSIGNMENT          DELETE /api/v1/saas/hub/assignments/:id      │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. RUNTIME COMPONENTS

NODO-02 se divide internamente en **dos subsistemas runtime conceptualmente separados** pero orquestados armónicamente bajo el mismo nodo:

```text
                               ┌─────────────────────────┐
                               │  HTTP REQUEST / ROUTER  │
                               └────────────┬────────────┘
                                            │
                                            ▼
                               ┌─────────────────────────┐
                               │ activeContextMiddleware │
                               └────────────┬────────────┘
                                            │
                     ┌──────────────────────┴──────────────────────┐
                     ▼                                             ▼
        ┌─────────────────────────┐                   ┌─────────────────────────┐
        │  Service Offer Runtime  │                   │Service Assignment Runt. │
        │                         │                   │                         │
        │ • serviceOfferController│                   │ • serviceAssignController│
        │ • serviceOfferService   │                   │ • serviceAssignService  │
        │                         │                   │                         │
        │ Entidad: service_offers │                   │ Entidad: service_assign.│
        └────────────┬────────────┘                   └────────────┬────────────┘
                     │                                             │
                     └──────────────────────┬──────────────────────┘
                                            │
                                            ▼
                               ┌─────────────────────────┐
                               │   PostgreSQL DB Pool    │
                               │  SET LOCAL app.tenant_id│
                               │  RLS + Composite FKs    │
                               └─────────────────────────┘
```

---

## 5. FILE PLAN (PLAN DE ARCHIVOS)

### A. Archivos Nuevos Propuestos para Futura Implementación:
1. `backend/src/services/serviceOfferService.js`: Lógica de negocio y consultas SQL para ofertas de servicio.
2. `backend/src/services/serviceAssignmentService.js`: Lógica de negocio y consultas SQL para asignaciones operativas.
3. `backend/src/controllers/serviceOfferController.js`: Manejo de requests/responses HTTP para catálogo de ofertas.
4. `backend/src/controllers/serviceAssignmentController.js`: Manejo de requests/responses HTTP para asignaciones.
5. `backend/src/routes/serviceOfferRoutes.js`: Definición de endpoints y middlewares para `/services`.
6. `backend/src/routes/serviceAssignmentRoutes.js`: Definición de endpoints y middlewares para `/assignments`.
7. `backend/tests/test_nodo02_runtime_suite.js`: Suite completa de pruebas automatizadas Jest/Supertest para NODO-02.

### B. Archivos Existentes a Modificar (Montaje Exclusivo):
1. `backend/index.js` (o enrutador principal): Montar las dos nuevas rutas bajo el namespace `/api/v1/saas/hub/`.

### C. Archivos Estrictamente Protegidos (Prohibida su Modificación):
- `backend/src/middleware/authMiddleware.js`
- `backend/src/middleware/activeContextMiddleware.js`
- `backend/src/services/activeContextService.js`
- `backend/src/services/contextResolutionService.js`
- `backend/src/services/hubSalonService.js` & `backend/src/controllers/hubSalonController.js`
- `backend/src/services/nodo01Service.js` & `backend/src/controllers/nodo01Controller.js`
- `backend/src/services/crearDesdeCeroService.js` & `backend/src/controllers/crearDesdeCeroController.js`
- `backend/migrations/*` (Especialmente `065`, `066`, `067`, `068`).
- `backend/init.sql`

---

## 6. ROUTE CONTRACT (CONTRATO DE ENRUTAMIENTO)

```text
┌───────────────────────────────────────────────────┬────────┬─────────────────────────┬──────────────────────────┐
│ ENDPOINT                                          │ MÉTODO │ HANDLER CONTROLADOR     │ AUTORIDAD MÍNIMA         │
├───────────────────────────────────────────────────┼────────┼─────────────────────────┼──────────────────────────┤
│ /api/v1/saas/hub/services                         │ POST   │ createServiceOffer      │ OWNER, MANAGER           │
│ /api/v1/saas/hub/services                         │ GET    │ listServiceOffers       │ OWNER, MGR, PROF, RECEP  │
│ /api/v1/saas/hub/services/:id                     │ GET    │ getServiceOfferById     │ OWNER, MGR, PROF, RECEP  │
│ /api/v1/saas/hub/services/:id                     │ PUT    │ updateServiceOffer      │ OWNER, MANAGER           │
│ /api/v1/saas/hub/assignments                      │ POST   │ createAssignment        │ OWNER, MANAGER           │
│ /api/v1/saas/hub/assignments                      │ GET    │ listAssignments         │ OWNER, MGR, PROF, RECEP  │
│ /api/v1/saas/hub/assignments/:id                  │ DELETE │ deleteAssignment        │ OWNER, MANAGER           │
│ /api/v1/saas/hub/assignments/staff/:membership_id │ GET    │ getAssignmentsByStaff   │ OWNER, MGR, PROF, RECEP  │
│ /api/v1/saas/hub/assignments/offer/:offer_id      │ GET    │ getAssignmentsByOffer   │ OWNER, MGR, PROF, RECEP  │
└───────────────────────────────────────────────────┴────────┴─────────────────────────┴──────────────────────────┘
```

> **[CLARIFICACIÓN DE TRANSPORTE R3]:**  
> El prefijo `/api/v1/saas/hub/` es exclusivamente una decisión de enrutamiento API y no vincula ni altera el Node Contract de `HUB-SALON-v1.0`.

---

## 7. AUTHENTICATION (AUTENTICACIÓN)

- Todo endpoint requiere obligatoriamente el header `Authorization: Bearer <JWT>`.
- Es procesado por `authMiddleware.js`, el cual:
  1. Verifica la firma y expiración del token JWT.
  2. Extrae el identificador del usuario autenticado (`req.user = { id: ... }`).
  3. Si el token es inválido o no está presente, interrumpe el ciclo con `401 Unauthorized` (`IDENTITY_NOT_FOUND`).

---

## 8. ACTIVE CONTEXT INTEGRATION (INTEGRACIÓN CON CONTEXTO ACTIVO)

- Todo endpoint ejecuta posteriormente `activeContextMiddleware.js`.
- **Entrada requerida del cliente:** Header `x-active-membership-id: <UUID>`.
- **Validación del middleware:**
  1. Verifica que `x-active-membership-id` sea un UUID válido.
  2. Invoca `activeContextService.resolveActiveContext(userId, membershipId)`.
  3. Comprueba que la membresía pertenezca al usuario autenticado y que `status === 'ACTIVE'`.
  4. Inyecta en el objeto `req`:
     - `req.tenantId`: Identificador entero del tenant resuelto.
     - `req.establishmentId`: UUID de la sede activa.
     - `req.membershipId`: UUID de la membresía activa del actor.
     - `req.activeContext`: Objeto con metadata de contexto (`role`, `organization_id`, etc.).

---

## 9. AUTHORIZATION (MODELO DE AUTORIZACIÓN RBAC)

La autorización se evalúa server-side a partir de `req.activeContext.role`:

```text
┌───────────────────────────┬──────────────────────────────────────────────────────────────┐
│ OPERACIÓN                 │ REGLA DE AUTORIZACIÓN EVALUADA                               │
├───────────────────────────┼──────────────────────────────────────────────────────────────┤
│ CREATE_SERVICE_OFFER      │ req.activeContext.role ∈ ['OWNER', 'MANAGER']                │
│ UPDATE_SERVICE_OFFER      │ req.activeContext.role ∈ ['OWNER', 'MANAGER']                │
│ CREATE_ASSIGNMENT         │ req.activeContext.role ∈ ['OWNER', 'MANAGER'] +              │
│                           │ Target Membership elegible como contexto profesional (R2)    │
│ DELETE_ASSIGNMENT         │ req.activeContext.role ∈ ['OWNER', 'MANAGER']                │
│ LECTURAS (LIST/GET)       │ req.activeContext.role ∈ ['OWNER', 'MANAGER', 'PROFESSIONAL',│
│                           │                           'RECEPTIONIST']                    │
└───────────────────────────┴──────────────────────────────────────────────────────────────┘
```

Si el rol del actor no cumple la condición, el backend rechaza inmediatamente la petición con `403 Forbidden` (`INSUFFICIENT_ROLE_AUTHORITY`).

---

## 10. SERVICE OFFER IMPLEMENTATION CONTRACT

### 10.1. `createServiceOffer(context, data)`
- **Validaciones:**
  - `name`: String no vacío, trim, longitud 1..255.
  - `description`: String opcional o `null`, max 2000 chars.
  - `base_duration`: Integer estrictamente > 0.
  - `base_price`: Decimal/Numeric estrictamente >= 0.00.
- **Campos Derivados Server-Side:**
  - `tenant_id = context.tenantId`
  - `establishment_id = context.establishmentId`
- **Operación SQL:**
  ```sql
  INSERT INTO service_offers (tenant_id, establishment_id, name, description, base_duration, base_price)
  VALUES ($1, $2, $3, $4, $5, $6)
  RETURNING id, tenant_id, establishment_id, name, description, base_duration, base_price, created_at, updated_at;
  ```

### 10.2. `listServiceOffers(context)`
- **Operación SQL:**
  ```sql
  SELECT id, tenant_id, establishment_id, name, description, base_duration, base_price, created_at, updated_at
  FROM service_offers
  WHERE establishment_id = $1 AND tenant_id = $2
  ORDER BY created_at ASC;
  ```

### 10.3. `getServiceOfferById(context, id)`
- **Operación SQL:**
  ```sql
  SELECT id, tenant_id, establishment_id, name, description, base_duration, base_price, created_at, updated_at
  FROM service_offers
  WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3;
  ```
- Si no existe: Retorna `404 Not Found` (`SERVICE_OFFER_NOT_FOUND`).

### 10.4. `updateServiceOffer(context, id, data)`
- **Inmutabilidad Estructural (R1):**
  - Si el payload contiene `id`, `tenant_id` o `establishment_id` con valores distintos al recurso existente, el backend responde `400 Bad Request` (`IMMUTABLE_FIELD_MODIFICATION`).
  - Prohibido transferir una oferta de una sede a otra.
- **Campos Mutables:** `name`, `description`, `base_duration`, `base_price`.
- **Operación SQL:**
  ```sql
  UPDATE service_offers
  SET name = COALESCE($1, name),
      description = COALESCE($2, description),
      base_duration = COALESCE($3, base_duration),
      base_price = COALESCE($4, base_price),
      updated_at = CURRENT_TIMESTAMP
  WHERE id = $5 AND establishment_id = $6 AND tenant_id = $7
  RETURNING id, tenant_id, establishment_id, name, description, base_duration, base_price, created_at, updated_at;
  ```

---

## 11. ASSIGNMENT IMPLEMENTATION CONTRACT

### 11.1. `createAssignment(context, data)`
- **Payload:** `{ service_offer_id: UUID, membership_id: UUID }`.
- **Verificaciones Server-Side Previas a la Inserción:**
  1. **Verificación de Oferta:**
     ```sql
     SELECT id FROM service_offers 
     WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3;
     ```
     Si no existe -> `404 Not Found` (`SERVICE_OFFER_NOT_FOUND`).
  2. **Verificación de Membresía Target:**
     ```sql
     SELECT id, status, role FROM memberships
     WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3;
     ```
     - Si no existe -> `404 Not Found` (`MEMBERSHIP_NOT_FOUND`).
     - Si `status !== 'ACTIVE'` -> `403 Forbidden` (`MEMBERSHIP_NOT_ACTIVE`).
     - Si no representa un contexto profesional elegible (R2) -> `403 Forbidden` (`INELIGIBLE_PROFESSIONAL_TARGET`).
  3. **Verificación de Duplicidad:**
     ```sql
     SELECT id FROM service_assignments
     WHERE service_offer_id = $1 AND membership_id = $2 AND establishment_id = $3 AND tenant_id = $4;
     ```
     Si ya existe -> `409 Conflict` (`ASSIGNMENT_ALREADY_EXISTS`).
- **Operación SQL de Inserción:**
  ```sql
  INSERT INTO service_assignments (tenant_id, establishment_id, service_offer_id, membership_id)
  VALUES ($1, $2, $3, $4)
  RETURNING id, tenant_id, establishment_id, service_offer_id, membership_id, created_at;
  ```

### 11.2. `listEstablishmentAssignments(context)`
- **Operación SQL:**
  ```sql
  SELECT id, tenant_id, establishment_id, service_offer_id, membership_id, created_at
  FROM service_assignments
  WHERE establishment_id = $1 AND tenant_id = $2
  ORDER BY created_at ASC;
  ```

### 11.3. `getAssignmentsByStaff(context, membershipId)`
- **Operación SQL:**
  ```sql
  SELECT id, tenant_id, establishment_id, service_offer_id, membership_id, created_at
  FROM service_assignments
  WHERE membership_id = $1 AND establishment_id = $2 AND tenant_id = $3
  ORDER BY created_at ASC;
  ```

### 11.4. `getAssignmentsByOffer(context, serviceOfferId)`
- **Operación SQL:**
  ```sql
  SELECT id, tenant_id, establishment_id, service_offer_id, membership_id, created_at
  FROM service_assignments
  WHERE service_offer_id = $1 AND establishment_id = $2 AND tenant_id = $3
  ORDER BY created_at ASC;
  ```

### 11.5. `deleteAssignment(context, id)` (Pure Unassignment)
- **Operación SQL:**
  ```sql
  DELETE FROM service_assignments
  WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3
  RETURNING id;
  ```
- Si ningún registro fue eliminado -> `404 Not Found` (`ASSIGNMENT_NOT_FOUND`).
- **Semántica Inviolable (`DEC-AS-012`):**
  - Cero mutación en `service_offers`.
  - Cero mutación en `memberships`.
  - No altera `membership.status` ni crea estado `REVOKED`.

---

## 12. TRANSACTION BOUNDARIES (LÍMITES TRANSACCIONALES)

Para garantizar consistencia atómica y aislamiento RLS, toda operación mutante se ejecuta dentro de un cliente reservado del pool con bloque transaccional:

```javascript
const client = await pool.connect();
try {
  await client.query('BEGIN');
  // 1. Configurar contexto de aislamiento RLS
  await client.query('SELECT set_config($1, $2, true)', ['app.tenant_id', String(tenantId)]);
  
  // 2. Ejecutar validaciones y mutaciones SQL de negocio
  // ...
  
  await client.query('COMMIT');
  return result;
} catch (error) {
  await client.query('ROLLBACK');
  throw error;
} finally {
  client.release();
}
```

---

## 13. RLS / TENANT ISOLATION (AISLAMIENTO TENANT Y SEDE)

El aislamiento opera en tres capas redundantes (Defensa en Profundidad):

1. **Capa 1: Contexto de Sesión PostgreSQL (RLS)**
   - Se ejecuta `SELECT set_config('app.tenant_id', $1, true)` en cada conexión antes de consultar o mutar.
   - Las políticas RLS de `service_offers` y `service_assignments` bloquean automáticamente accesos cross-tenant.
2. **Capa 2: Filtro SQL Explícito en Cláusulas WHERE**
   - Toda consulta incluye explícitamente `WHERE establishment_id = $req.establishmentId AND tenant_id = $req.tenantId`.
3. **Capa 3: Restricciones Físicas de Integridad Foránea (FKs Compuestas Triples)**
   - `fk_service_assignments_service_offer` vincula `(service_offer_id, establishment_id, tenant_id)`.
   - `fk_service_assignments_membership` vincula `(membership_id, establishment_id, tenant_id)`.
   - Imposibilidad física de asociar ofertas o membresías de sedes o tenants cruzados.

---

## 14. VALIDATION SPECIFICATION (ESPECIFICACIÓN DE VALIDACIÓN)

```text
┌───────────────────────────────────────┬──────────────────────────────────────────────────────────┐
│ PARÁMETRO / CAMPO                     │ REGLAS DE VALIDACIÓN ESTRICTA                            │
├───────────────────────────────────────┼──────────────────────────────────────────────────────────┤
│ Header x-active-membership-id         │ Requerido, UUID v4 canónico                              │
│ Parámetros :id, :membership_id, :offer│ UUID v4 canónico                                         │
│ name (Service Offer)                  │ String no vacío, trim, min 1, max 255 chars              │
│ description (Service Offer)           │ String opcional o null, max 2000 chars                   │
│ base_duration                         │ Integer estrictamente > 0 y <= 1440 (minutos)            │
│ base_price                            │ Number/Decimal estrictamente >= 0.00                     │
│ Target Membership                     │ Debe existir, pertenecer a la sede activa y status=ACTIVE│
│ Target Professional Context           │ Debe representar contexto profesional elegible (R2)      │
│ Par Offer-Membership                  │ No debe existir asignación previa (Unique Constraint)    │
└───────────────────────────────────────┴──────────────────────────────────────────────────────────┘
```

---

## 15. ERROR CONTRACT (CONTRATO DETERMINISTA DE ERRORES)

```text
┌───────────────────────────────────┬────────────┬────────────────────────────────────────────────────────┐
│ CÓDIGO DE ERROR                   │ HTTP STATUS│ CONDICIÓN DE EMISIÓN                                   │
├───────────────────────────────────┼────────────┼────────────────────────────────────────────────────────┤
│ IDENTITY_NOT_FOUND                │ 401        │ Token JWT inválido, expirado o ausente                 │
│ MISSING_ACTIVE_MEMBERSHIP_HEADER  │ 400        │ Header x-active-membership-id no proporcionado         │
│ INVALID_MEMBERSHIP_UUID           │ 400        │ UUID malformado en headers o parámetros de ruta        │
│ INVALID_PAYLOAD                   │ 400        │ Parámetros inválidos (duración <= 0, precio < 0, etc.) │
│ IMMUTABLE_FIELD_MODIFICATION      │ 400        │ Intento de modificar id, tenant_id o establishment_id  │
│ INSUFFICIENT_ROLE_AUTHORITY       │ 403        │ Actor no posee rol OWNER o MANAGER                     │
│ MEMBERSHIP_NOT_ACTIVE             │ 403        │ Membresía destino no está en estado ACTIVE             │
│ INELIGIBLE_PROFESSIONAL_TARGET    │ 403        │ Membresía destino no es un contexto profesional (R2)   │
│ SERVICE_OFFER_NOT_FOUND           │ 404        │ Oferta no existe o no pertenece a la sede activa       │
│ MEMBERSHIP_NOT_FOUND              │ 404        │ Membresía no existe o no pertenece a la sede activa    │
│ ASSIGNMENT_NOT_FOUND              │ 404        │ Asignación no existe o no pertenece a la sede activa   │
│ ASSIGNMENT_ALREADY_EXISTS         │ 409        │ Asignación duplicada para la misma oferta y colaborador│
│ CROSS_ESTABLISHMENT_MISMATCH      │ 422        │ Violación de integridad de sede o tenant               │
│ INTERNAL_SERVER_ERROR             │ 500        │ Error inesperado en base de datos o runtime            │
└───────────────────────────────────┴────────────┴────────────────────────────────────────────────────────┘
```

### Estructura Estándar de Error JSON:
```json
{
  "status": "error",
  "code": "ASSIGNMENT_ALREADY_EXISTS",
  "message": "The specified professional is already assigned to this service offer in this establishment."
}
```

---

## 16. OUTPUT CONTRACT (CONTRATO DTO DE RESPUESTA)

### 16.1. Service Offer Standard DTO:
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

### 16.2. Service Offer List DTO:
```json
{
  "status": "success",
  "data": {
    "service_offers": [
      {
        "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "name": "Corte de Cabello Estilo & Cepillado",
        "description": "Corte y peinado profesional",
        "base_duration": 45,
        "base_price": "45000.00",
        "created_at": "2026-09-11T05:39:55.085Z",
        "updated_at": "2026-09-11T05:39:55.085Z"
      }
    ],
    "count": 1
  }
}
```

### 16.3. Assignment Standard DTO:
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

### 16.4. Delete Assignment DTO:
```json
{
  "status": "success",
  "data": {
    "deleted_id": "b1234567-89ab-cdef-0123-456789abcdef",
    "unassigned": true
  }
}
```

---

## 17. TEST PLAN (PLAN DE PRUEBAS DE NODO-02)

La futura suite `backend/tests/test_nodo02_runtime_suite.js` verificará obligatoriamente los siguientes 17 casos de prueba:

1. **Auth & Headers:** Rechazo de peticiones sin JWT (`401`) o sin `x-active-membership-id` (`400`).
2. **Context Resolution:** Inyección correcta de `req.tenantId`, `req.establishmentId`, `req.activeContext`.
3. **RBAC Authorization:** `OWNER` y `MANAGER` autorizados para mutaciones; `PROFESSIONAL` y `RECEPTIONIST` rechazados (`403`).
4. **Service Offer Creation:** Creación exitosa de oferta con validación de duración > 0 y precio >= 0.
5. **Service Offer Validation:** Rechazo de duración negativa/cero o precio negativo (`400`).
6. **Service Offer Immutable Fields (R1):** Rechazo de mutación de `id`, `tenant_id` o `establishment_id` (`400`).
7. **Service Offer Sede Isolation:** Aislamiento estricto de listados y lecturas a la sede activa.
8. **Assignment Creation (Happy Path):** Vinculación exitosa de oferta y colaborador activo.
9. **Active Professional Target (R2):** Rechazo de asignación a membresías no activas o no elegibles (`403`).
10. **Assignment Duplicate Rejection:** Rechazo con `409 Conflict` ante duplicación del par `(offer, membership)`.
11. **Cross-Establishment Rejection:** Rechazo cuando la oferta y la membresía pertenecen a sedes distintas (`422`/`404`).
12. **Cross-Tenant Rejection:** Rechazo ante intentos de acceso con tenant ajeno bloqueado por RLS.
13. **Staff Assignments Listing:** Consulta determinista de ofertas asignadas a un colaborador específico.
14. **Offer Assignments Listing:** Consulta determinista de colaboradores asignados a una oferta específica.
15. **Pure Unassignment (`DELETE_ASSIGNMENT`):** Eliminación de asignación comprobando que la oferta y la membresía quedan intactas.
16. **Transaction Integrity:** Verificación de rollback atómico ante errores en mutaciones.
17. **RLS Verification:** Verificación de `app.tenant_id` aplicado en todas las operaciones.

---

## 18. REGRESSION PLAN (PLAN DE NO-REGRESIÓN)

La implementación futura deberá ejecutar y aprobar al 100% las suites de componentes existentes:

```bash
# 1. Foundation Core & Resolution Tests
npm test backend/tests/test_active_context_suite.js

# 2. Crear Desde Cero & Onboarding Tests
npm test backend/tests/test_crear_desde_cero_suite.js

# 3. Hub Salón Cockpit Tests
npm test backend/tests/test_hub_salon_suite.js

# 4. NODO-01 Handover Ingestion Tests
npm test backend/tests/test_nodo01_suite.js

# 5. Service Offers & Assignments Physical DB Suite
npm test backend/tests/test_service_offers_and_assignments_physical_suite.js
```

---

## 19. PROTECTED ASSETS (ACTIVOS PROTEGIDOS)

Queda estrictamente prohibida la alteración de:
- Tablas y lógica de Foundation (`tenants`, `establishments`, `memberships`, `065`, `066`).
- Estructuras físicas ratificadas (`067_service_offers.sql`, `068_service_assignments.sql`).
- Contratos de nodos cerrados (`ACTIVE-CONTEXT`, `HUB-SALON`, `CREAR-DESDE-CERO`, `NODO-01`).
- Motores B2C y marketplace (`public.services`, `perfiles_prestador`, `reservas`, `usuarios`).
- Componentes de Frontend y UI.

---

## 20. NON-SCOPE (FUERA DE ALCANCE ABSOLUTO)

Quedan expresamente fuera de alcance y prohibidas de inferir:
1. `DELETE SERVICE_OFFER` (Permanece `UNDEFINED / FUTURE DECISION`).
2. `service_offers.is_active` (Permanece `UNDEFINED / PENDING DECISION`).
3. Taxonomías / Categorías de servicios (`UNDEFINED`).
4. Subsistema físico de auditoría histórica (`DEC-AS-013-B/F`).
5. Publicación comercial y activación de catálogo (`DEC-PUB-001`).
6. Sincronización o materialización hacia `public.services`.
7. Gestión de agenda, disponibilidad horaria, POS, inventario o clientes.

---

## 21. IMPLEMENTATION STOP CONDITIONS (CONDICIONES DE DETENCIÓN)

Durante la futura fase de implementación, se emitirá un **ARCHITECTURAL STOP** inmediato si:
1. Se detecta la necesidad de crear nuevas migraciones DDL o alterar tablas existentes.
2. Se requiere modificar archivos fuera del alcance de NODO-02 (ej. Foundation o B2C).
3. Se intenta resolver por inferencia un aspecto marcado como `UNDEFINED`.
4. Ocurre una regresión en cualquiera de las suites protegidas (Active Context, Hub, Nodo-01).

---

## 22. ACCEPTANCE CRITERIA (CRITERIOS DE ACEPTACIÓN)

Para declarar concluido NODO-02 tras su futura implementación, se requerirá:
1. Existencia y desacoplamiento de `serviceOfferService.js` y `serviceAssignmentService.js`.
2. Cumplimiento del 100% de las 9 rutas bajo `/api/v1/saas/hub/`.
3. Inmutabilidad estricta de `(id, tenant_id, establishment_id)` en updates (R1).
4. Exigencia de `Active Professional Target` en asignaciones (R2).
5. Desasignación pura verificada sin efectos colaterales (`DEC-AS-012`).
6. 100% PASS en la suite de pruebas unitarias/integración de NODO-02.
7. 100% PASS en las 5 suites de regresión protegidas.
8. Aprobación final por parte del Director del Proyecto.

---

## 23. GOVERNANCE SELF-CHECK

- [x] **¿Se respetó el principio "NO CODE BEFORE CONTRACT"?** SÍ. 0 líneas de código backend escritas.
- [x] **¿Se mantuvieron intactas las migraciones y DDL?** SÍ. 0 migraciones DDL/DML ejecutadas.
- [x] **¿Se preservó la inmutabilidad de Foundation y B2C?** SÍ. 0 modificaciones a esquemas externos.
- [x] **¿Se incorporaron todas las directivas de reconciliación (R1 a R4)?** SÍ.
- [x] **¿Se definieron las 23 secciones contractuales requeridas?** SÍ.

---

```text
============================================================
NODO-02 IMPLEMENTATION CONTRACT
→ READY FOR DIRECTOR GATE
============================================================
```
