# NODO-04 — IMPLEMENTATION CONTRACT v1.0
## DOWNSTREAM B2C MATERIALIZATION ADAPTER — RECONCILED IMPLEMENTATION CONTRACT

**DOCUMENT ID**: `N04-IMPLEMENTATION-CONTRACT-v1.0`  
**NODE ID**: `NODO-04`  
**NAME**: Downstream B2C Materialization Adapter  
**STATUS**: `IMPLEMENTATION CONTRACT — RECONCILED / READY FOR DIRECTOR APPROVAL 🟡`  
**VERSION**: 1.0.0  
**DATE**: 2026-09-11  
**AUTHORITY**: Director del Proyecto GlowApp SaaS  
**GOAL ORIGIN**: `GO — NODO-04-IMPLEMENTATION-CONTRACT-RECONCILIATION-01`  
**IMPLEMENTATION AUTHORIZATION**: `NOT AUTHORIZED 🔴`

---

## 1. PRECONDICIONES ARQUITECTÓNICAS Y FUENTE DE VERDAD

Este Contrato de Implementación traduce con fidelidad matemática y estricta neutralidad las decisiones arquitectónicas aprobadas y cerradas por el **Director del Proyecto GlowApp SaaS**:

1. **`NODO-04 Node Contract v1.0`**: `APPROVED / CLOSED 🔒` (Adaptador downstream sin automatismos).
2. **`DEC-AS-003`**: `APPROVED / CLOSED 🔒` (Acto explícito de autorización por `OWNER`/`MANAGER` en Active Context).
3. **`NODO-04 Physical Architecture Design v1.0` & `Director Gate 01`**: `APPROVED / CLOSED 🔒` (Resolución canónica de Provider, Rechazo de Auto-Provisioning, Identidad Tridimensional y Granularidad 1:1).
4. **`NODO-03A`**: `CLOSED / RATIFIED 🔒` (Disponibilidad y turnos operativos del staff).
5. **`NODO-02`**: `CLOSED / RATIFIED 🔒` (`service_offers` y `service_assignments` durables).
6. **`NODO-01 / Foundation Core (065, 066)`**: `CLOSED 🔒` (`tenants`, `establishments`, `memberships`, `usuarios`, `activeContextMiddleware`).

> **REGLA MANDATORIA DE IMPLEMENTACIÓN:**  
> Ninguna línea de código, migración SQL o endpoint podrá ser creada o ejecutada hasta que este contrato reciba la ratificación formal del Director del Proyecto.

---

## 2. ESPECIFICACIÓN FÍSICA DE BASE DE DATOS (MIGRATION 070)

Para implementar la persistencia del mapping técnico downstream sin alterar el esquema legacy de `public.services`, se define la migración física:

**Archivo de Migración Propuesto**: `backend/migrations/070_saas_service_materializations.sql`

```sql
-- Migration 070: SaaS to B2C Service Materialization Mapping Table
-- Purpose: Technical downstream mapping between SaaS Service Assignment and B2C public.services

CREATE TABLE IF NOT EXISTS public.saas_service_materializations (
    -- =========================================================================
    -- A. CORE MAPPING (Identidad y Dimensiones de Aislamiento Requeridas)
    -- =========================================================================
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id INTEGER NOT NULL,
    establishment_id UUID NOT NULL,
    service_offer_id UUID NOT NULL,
    membership_id UUID NOT NULL,
    service_id UUID NOT NULL,

    -- =========================================================================
    -- B. METADATOS DE TRAZABILIDAD Y AUDITORÍA [PROPOSAL — NOT APPROVED]
    -- =========================================================================
    materialized_by_user_id INTEGER,
    materialized_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- =========================================================================
    -- C. CLAVES FORÁNEAS DE CONTEXTO E INTEGRIDAD SAAS
    -- =========================================================================
    CONSTRAINT fk_mat_tenant 
        FOREIGN KEY (tenant_id) 
        REFERENCES public.tenants(id) 
        ON DELETE RESTRICT,

    -- Referencia a constraint física existente: uq_service_assignments_offer_membership
    CONSTRAINT fk_mat_assignment 
        FOREIGN KEY (service_offer_id, membership_id) 
        REFERENCES public.service_assignments(service_offer_id, membership_id) 
        ON DELETE RESTRICT,

    -- Referencia a constraint física existente: uq_service_offers_id_establishment_tenant
    CONSTRAINT fk_mat_offer_context 
        FOREIGN KEY (service_offer_id, establishment_id, tenant_id) 
        REFERENCES public.service_offers(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,

    -- Referencia a constraint física existente: uq_membership_id_establishment_tenant
    CONSTRAINT fk_mat_membership_context 
        FOREIGN KEY (membership_id, establishment_id, tenant_id) 
        REFERENCES public.memberships(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,

    -- =========================================================================
    -- D. INTEGRIDAD DOWNSTREAM HACIA B2C
    -- =========================================================================
    CONSTRAINT fk_mat_service 
        FOREIGN KEY (service_id) 
        REFERENCES public.services(id) 
        ON DELETE CASCADE,

    CONSTRAINT fk_mat_actor_user 
        FOREIGN KEY (materialized_by_user_id, tenant_id) 
        REFERENCES public.usuarios(id, tenant_id) 
        ON DELETE RESTRICT,

    -- =========================================================================
    -- E. RESTRICCIONES DE UNICIDAD E IDEMPOTENCIA
    -- =========================================================================
    CONSTRAINT uq_mat_assignment_establishment 
        UNIQUE (establishment_id, service_offer_id, membership_id),

    CONSTRAINT uq_mat_service_id 
        UNIQUE (service_id)
);

-- Índices de Rendimiento y RLS
CREATE INDEX IF NOT EXISTS idx_mat_tenant_est 
    ON public.saas_service_materializations(tenant_id, establishment_id);

CREATE INDEX IF NOT EXISTS idx_mat_service 
    ON public.saas_service_materializations(service_id);

CREATE INDEX IF NOT EXISTS idx_mat_membership 
    ON public.saas_service_materializations(membership_id);

-- Habilitación de Row Level Security (RLS)
ALTER TABLE public.saas_service_materializations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation_saas_service_materializations ON public.saas_service_materializations;

CREATE POLICY tenant_isolation_saas_service_materializations ON public.saas_service_materializations
    FOR ALL
    USING (tenant_id = (NULLIF(current_setting('app.tenant_id', true), ''))::integer)
    WITH CHECK (tenant_id = (NULLIF(current_setting('app.tenant_id', true), ''))::integer);
```

---

## 3. CATÁLOGO DE OPERACIONES RUNTIME

`NODO-04` implementa exactamente dos operaciones canónicas:

| Operación | Método HTTP | Ruta Canónica | Propósito |
|---|---|---|---|
| **`OP-01`** | `POST` | `/api/v1/saas/hub/materializations/services` | Ejecuta la materialización explícita de una asignación específica hacia `public.services`. |
| **`OP-02`** | `GET` | `/api/v1/saas/hub/materializations/services` | Lista los servicios materializados de la sede activa. |

---

## 4. ESPECIFICACIÓN DETALLADA: OP-01 (MATERIALIZE ASSIGNMENT)

### 4.1. Endpoint y Transporte
- **Ruta**: `POST /api/v1/saas/hub/materializations/services`
- **Middlewares**: `authMiddleware` $ightarrow$ `activeContextMiddleware`
- **Headers Requeridos**:
  - `Authorization: Bearer <jwt>`
  - `x-active-membership-id: <uuid>` (Obligatorio para resolver Active Context)

### 4.2. Request Payload (Input DTO)
- **Granularidad Estricta (`DEC-D`)**: Exactamente 1 Asignación = 1 Materialización.
```json
{
  "service_offer_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
  "membership_id": "c1a2b3c4-d5e6-4f7a-8b9c-0d1e2f3a4b5c"
}
```
*Validación DTO*: Ambos campos deben ser strings en formato `UUIDv4` válidos. No se permiten arrays, lotes ni comandos batch ("all assignments").

### 4.3. Matriz Secuencial de Precondiciones y Validaciones
Dentro de la transacción atómica, el runtime valida secuencialmente:

```text
================================================================================
           MATRIZ DE VALIDACIÓN SECUENCIAL — OP-01 (ATOMIC TRANSACTION)
================================================================================
1. AUTENTICACIÓN:    Usuario autenticado con JWT válido (req.user).
2. ACTIVE CONTEXT:   req.activeContext resuelto server-side (tenant_id, establishment_id, role, status).
3. RBAC (DEC-AS-003): req.activeContext.role ∈ {'OWNER', 'MANAGER'}. Si no -> 403.
4. PAYLOAD CHECK:    service_offer_id y membership_id son UUIDs válidos. Si no -> 400.
5. CONTEXT LOCK (OFFER):
   SELECT id, name, description, base_price, base_duration 
   FROM service_offers 
   WHERE id = $service_offer_id AND establishment_id = $establishment_id AND tenant_id = $tenant_id
   FOR SHARE;
   -> Si no existe fila -> 404 (SERVICE_OFFER_NOT_FOUND).
   -> Si base_duration <= 0 o base_price < 0 -> 400 (INVALID_SERVICE_OFFER).
6. CONTEXT LOCK (MEMBERSHIP):
   SELECT id, user_id, role, status 
   FROM memberships 
   WHERE id = $membership_id AND establishment_id = $establishment_id AND tenant_id = $tenant_id
   FOR SHARE;
   -> Si no existe fila -> 404 (MEMBERSHIP_NOT_FOUND).
   -> Si status != 'ACTIVE' o role != 'PROFESSIONAL' -> 422 (NON_OPERABLE_STAFF_MEMBER).
7. ASSIGNMENT CHECK:
   SELECT id FROM service_assignments 
   WHERE service_offer_id = $service_offer_id AND membership_id = $membership_id;
   -> Si no existe fila -> 404 (SERVICE_ASSIGNMENT_NOT_FOUND).
8. PROVIDER PRECONDITION (DEC-B / REJECTED AUTO-PROVISION):
   SELECT id FROM perfiles_prestador 
   WHERE id = $memberships.user_id AND tenant_id = $tenant_id;
   -> Si no existe fila -> 422 (MATERIALIZATION_NOT_EXECUTABLE / PROVIDER_PROFILE_REQUIRED).
      (NODO-04 jamás provisiona perfiles_prestador ni wallets automáticamente).
9. RE-MATERIALIZATION BEHAVIOR CHECK [OPEN / DECISION REQUIRED]:
   SELECT id, service_id FROM saas_service_materializations
   WHERE establishment_id = $establishment_id 
     AND service_offer_id = $service_offer_id 
     AND membership_id = $membership_id;
   -> Si ya existe fila de mapeo previa:
      La operación NO podrá actualizar automáticamente public.services, sincronizar
      atributos, hacer NO-OP determinista, crear una segunda materialización ni
      modificar la materialización existente. La operación se DETIENE y ABORTA
      hasta que exista un dictamen formal del Director.
================================================================================
```

### 4.4. Escritura en PostgreSQL (Atomic Mutation)
Superadas todas las precondiciones:
1. **Generación de ID B2C**: `new_service_id = gen_random_uuid()`.
2. **Escritura Downstream en `public.services`**:
   ```sql
   INSERT INTO public.services (
       id, provider_id, name, description, price, duration_minutes, tenant_id
   ) VALUES (
       $new_service_id, $memberships.user_id, $offer.name, $offer.description,
       $offer.base_price, $offer.base_duration, $tenant_id
   ) RETURNING id, provider_id, name, price, duration_minutes, created_at;
   ```
   *Nota de Activación:* `NODO-04` no fija ni decide el valor de `is_active`. El valor insertado corresponde al `DEFAULT true` preexistente en el esquema físico de PostgreSQL `[FACT]`.
3. **Escritura en `public.saas_service_materializations`**:
   ```sql
   INSERT INTO public.saas_service_materializations (
       tenant_id, establishment_id, service_offer_id, membership_id,
       service_id, materialized_by_user_id
   ) VALUES (
       $tenant_id, $establishment_id, $service_offer_id, $membership_id,
       $new_service_id, $req.user.id
   ) RETURNING id, materialized_at;
   ```

### 4.5. Response Payload Exitoso (`201 Created`)
```json
{
  "success": true,
  "data": {
    "materialization_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "service_id": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
    "tenant_id": 2,
    "establishment_id": "11111111-2222-3333-4444-555555555555",
    "service_offer_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
    "membership_id": "c1a2b3c4-d5e6-4f7a-8b9c-0d1e2f3a4b5c",
    "provider_id": 105,
    "projected_service": {
      "name": "Corte y Peinado Profesional",
      "description": "Servicio de alta peluquería",
      "price": "45000.00",
      "duration_minutes": 45
    },
    "materialized_at": "2026-09-11T13:40:00.000Z"
  }
}
```

---

## 5. ESPECIFICACIÓN DETALLADA: OP-02 (LIST MATERIALIZATIONS)

### 5.1. Endpoint y Transporte
- **Ruta**: `GET /api/v1/saas/hub/materializations/services`
- **Middlewares**: `authMiddleware` $ightarrow$ `activeContextMiddleware`
- **RBAC**: `OWNER`, `MANAGER`, `PROFESSIONAL`, `RECEPTIONIST` (Lectura autorizada en su Active Context).

### 5.2. Query Ejecutada
```sql
SELECT 
    m.id AS materialization_id,
    m.service_offer_id,
    so.name AS service_offer_name,
    m.membership_id,
    u.nombre AS professional_name,
    m.service_id,
    s.price AS b2c_price,
    s.duration_minutes AS b2c_duration,
    s.is_active AS b2c_is_active,
    m.materialized_at
FROM public.saas_service_materializations m
JOIN public.service_offers so ON m.service_offer_id = so.id
JOIN public.memberships mem ON m.membership_id = mem.id
JOIN public.usuarios u ON mem.user_id = u.id
JOIN public.services s ON m.service_id = s.id
WHERE m.establishment_id = $establishment_id AND m.tenant_id = $tenant_id
ORDER BY m.materialized_at DESC;
```

---

## 6. CATÁLOGO FORMAL DE ERRORES RUNTIME

| Código Semántico | HTTP Status | Causa Física / Contractual |
|---|---|---|
| `UNAUTHENTICATED` | `401 Unauthorized` | Token JWT ausente, expirado o con firma inválida. |
| `ACTIVE_CONTEXT_REQUIRED` | `400 Bad Request` | Contexto activo no inicializado o incompleto en el request. |
| `INSUFFICIENT_ROLE_AUTHORITY` | `403 Forbidden` | Actor con rol distinto a `OWNER` o `MANAGER` intenta autorizar materialización. |
| `INVALID_PAYLOAD` | `400 Bad Request` | `service_offer_id` o `membership_id` ausentes o no cumplen formato UUIDv4. |
| `SERVICE_OFFER_NOT_FOUND` | `404 Not Found` | La oferta de servicio no existe en la sede activa o pertenece a otro tenant. |
| `INVALID_SERVICE_OFFER` | `400 Bad Request` | La oferta posee `base_duration <= 0` o `base_price < 0`. |
| `MEMBERSHIP_NOT_FOUND` | `404 Not Found` | La membresía especificada no existe en la sede activa o pertenece a otro tenant. |
| `NON_OPERABLE_STAFF_MEMBER` | `422 Unprocessable` | El colaborador tiene membresía en `INVITED`, `SUSPENDED`, `REVOKED` o su rol no es `PROFESSIONAL`. |
| `SERVICE_ASSIGNMENT_NOT_FOUND` | `404 Not Found` | No existe registro formal en `service_assignments` vinculando la oferta al colaborador. |
| `MATERIALIZATION_NOT_EXECUTABLE` | `422 Unprocessable` | El colaborador no posee perfil previo en `perfiles_prestador` (`DEC-B`). |

---

## 7. MATRIZ DE SEGURIDAD Y AISLAMIENTO MULTI-TENANT

1. **Aislamiento Contextual Server-Side**:  
   `activeContextMiddleware` valida e inyecta server-side `req.activeContext = { tenant_id, establishment_id, role, status }`. Prohibido aceptar parámetros contextuales enviados en el body por el cliente.
2. **Aislamiento a Nivel de PostgreSQL (RLS)**:  
   Toda conexión de servicio ejecuta al inicio de la transacción:
   ```sql
   SELECT set_config('app.tenant_id', $1, true);
   ```
   Asegurando que tanto las tablas SaaS (`service_offers`, `service_assignments`, `memberships`, `saas_service_materializations`) como las tablas B2C (`services`, `perfiles_prestador`) filtren automáticamente por `tenant_id`.
3. **Locks de Concurrencia**:  
   Se adquieren locks `FOR SHARE` sobre `service_offers` y `memberships` durante la validación para impedir mutaciones concurrentes mientras se ejecuta la proyección downstream.

---

## 8. PLAN DE PRUEBAS Y CRITERIOS DE TESTABILIDAD (TEST CONTRACT)

### 8.1. Estado de la Suite
- **17 CONTRACTUAL TEST CASES DEFINED** (Casos contractuales definidos formalmente; la suite no ha sido ejecutada y se evaluará únicamente tras la autorización formal de implementación).

### 8.2. Definición de Casos de Prueba
La futura suite de pruebas (`test_nodo04_materialization_suite.js`) deberá evaluar los siguientes casos contractuales exactos:

1. **`T01: Authenticated Identity`**: Valida rechazo ante ausencia o invalidez de JWT (`401 UNAUTHENTICATED`).
2. **`T02: Active Context Required`**: Valida rechazo ante ausencia de header `x-active-membership-id` (`400 ACTIVE_CONTEXT_REQUIRED`).
3. **`T03: OWNER Authorization`**: Creación exitosa de materialización con rol `OWNER` (`201 Created`).
4. **`T04: MANAGER Authorization`**: Creación exitosa de materialización con rol `MANAGER` (`201 Created`).
5. **`T05: PROFESSIONAL Rejected`**: Rechazo de intento de materialización por `PROFESSIONAL` (`403 INSUFFICIENT_ROLE_AUTHORITY`).
6. **`T06: RECEPTIONIST Rejected`**: Rechazo de intento de materialización por `RECEPTIONIST` (`403 INSUFFICIENT_ROLE_AUTHORITY`).
7. **`T07: Inactive Membership Rejected`**: Rechazo si el colaborador tiene membresía `SUSPENDED` o `REVOKED` (`422 NON_OPERABLE_STAFF_MEMBER`).
8. **`T08: Cross-Establishment Rejected`**: Rechazo si la oferta o membresía pertenece a otra sede (`404 SERVICE_OFFER_NOT_FOUND` / `MEMBERSHIP_NOT_FOUND`).
9. **`T09: Cross-Tenant Rejected`**: Rechazo y aislamiento RLS estricto ante recursos de otro tenant.
10. **`T10: Invalid Service Offer`**: Rechazo ante oferta inexistente o con duración $\le 0$ o precio $< 0$ (`400 INVALID_SERVICE_OFFER`).
11. **`T11: Invalid Assignment`**: Rechazo ante oferta no asignada previamente al colaborador (`404 SERVICE_ASSIGNMENT_NOT_FOUND`).
12. **`T12: Provider Profile Absent (DEC-B)`**: Rechazo estricto si el colaborador no posee registro previo en `perfiles_prestador` (`422 MATERIALIZATION_NOT_EXECUTABLE / PROVIDER_PROFILE_REQUIRED`).
13. **`T13: Provider Profile Present`**: Ejecución exitosa de proyección downstream cuando el perfil de prestador existe previamente.
14. **`T14: Successful Materialization & Mapping Persistence`**: Valida que la fila en `public.services` y la fila en `saas_service_materializations` se insertan correctamente con los datos y referencias esperadas.
15. **`T15: Atomic Rollback`**: Valida que ante un error simulado o fallo de constraint, toda la transacción hace `ROLLBACK` y no quedan registros huérfanos en `public.services`.
16. **`T16: RLS Isolation`**: Valida que la lectura de materializaciones (`OP-02`) está estrictamente confinada al tenant activo.
17. **`T17: Existing Materialization (Behavior Open Check)`**: Verifica que una solicitud sobre una tupla ya materializada **no muta, no actualiza automáticamente ni duplica** la materialización mientras la decisión de re-materialización permanezca `OPEN`.

---

## 9. REGRESSION GUARANTEES & BASELINE

- **Resultado Histórico Validado**:
  ```text
  HISTORICAL VALIDATED REGRESSION (PRE-NODO-04) = 106/106 PASS 🔒
  ```
  *(106/106 corresponde a la línea base de regresión previamente validada en el cierre de NODO-03A, antes de NODO-04).*

- **Criterio de Regresión del Contrato**:
  ```text
  BASELINE REGRESSION CRITERION: 106/106 PASS
  ```
  *(NODO-04 no ha sido ejecutado contra esta línea base. La suite completa de regresión + NODO-04 se ejecutará exclusivamente tras la autorización de implementación).*

---

## 10. PROTECTED ASSETS (ACTIVOS PROTEGIDOS E INMUTABLES)

Queda estrictamente prohibido alterar, mutar o degradar los siguientes activos del sistema:
- `backend/migrations/065_saas_foundation_core.sql`
- `backend/migrations/066_context_resolution_tenant_resolver.sql`
- `backend/migrations/067_service_offers.sql`
- `backend/migrations/068_service_assignments.sql`
- `backend/migrations/069_staff_schedules.sql`
- Código de servicios y controladores de NODO-01, NODO-02 y NODO-03A.
- Esquema de tablas B2C: `public.services`, `public.perfiles_prestador`, `public.bookings`, `public.reservas`.

---

## 11. ESTADO DEL DOCUMENTO

```text
================================================================================
NODO-04 — DOWNSTREAM B2C MATERIALIZATION ADAPTER
STATUS: IMPLEMENTATION CONTRACT — RECONCILED / READY FOR DIRECTOR APPROVAL 🟡

AUTHORITY: DIRECTOR DEL PROYECTO GLOWAPP SAAS
IMPLEMENTATION: NOT AUTHORIZED 🔴

CODE CHANGES: 0
DATABASE CHANGES: 0
MIGRATIONS: 0
CLOSED NODES MODIFIED: 0
================================================================================
```
