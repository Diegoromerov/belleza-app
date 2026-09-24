# NODO-04 — PHYSICAL ARCHITECTURE DESIGN v1.0
## DOWNSTREAM B2C MATERIALIZATION ADAPTER — FINAL RECONCILED PHYSICAL ARCHITECTURE DESIGN

**DOCUMENT ID**: `ARCH-DESIGN-N04-PHYSICAL-01`  
**NODE**: `NODO-04 (Downstream B2C Materialization Adapter)`  
**DATE**: 2026-09-11  
**AUTHORITY**: Director del Proyecto GlowApp SaaS  
**GOAL ORIGIN**: `GO — NODO-04-PHYSICAL-ARCHITECTURE-FINAL-RECONCILIATION-01`  
**STATUS**: `PHYSICAL ARCHITECTURE DESIGN — FINAL RECONCILIATION / READY FOR DIRECTOR GATE 🟡`  
**IMPLEMENTATION**: `NOT AUTHORIZED 🔴`

---

## 1. EVIDENCE (EVIDENCIA FÍSICA Y ESTRUCTURAL) `[FACT]`

A partir de la inspección forense read-only del catálogo de PostgreSQL (`beauty_db`), se constatan los siguientes hechos estructurales inmutables sobre las 6 tablas dentro del scope directo de `NODO-04`:

### 1.1. Dominio B2C (Downstream)
1. **`public.services`**:
   - `id`: `UUID` (PK, default `gen_random_uuid()`).
   - `provider_id`: `INTEGER NOT NULL` con constraint `FOREIGN KEY (provider_id) REFERENCES perfiles_prestador(id) ON DELETE CASCADE`.
   - `name`: `VARCHAR(255) NOT NULL`.
   - `description`: `TEXT` (NULLABLE).
   - `price`: `NUMERIC(10,2) NOT NULL` (CHECK `price >= 0`).
   - `duration_minutes`: `INTEGER NOT NULL` (CHECK `duration_minutes > 0`).
   - `category`: `VARCHAR(50)` (NULLABLE).
   - `is_active`: `BOOLEAN DEFAULT true` (Valor por defecto preexistente en el esquema físico legacy).
   - `tenant_id`: `INTEGER` (RLS habilitado).
   - `created_at`: `TIMESTAMPTZ DEFAULT now()`.
   - **No posee** columnas de origen SaaS (`service_offer_id`, `establishment_id`, `membership_id`) ni índices únicos compuestos sobre `(tenant_id, provider_id, name)`.
2. **`public.perfiles_prestador`**:
   - `id`: `INTEGER` (PK) con constraint `FOREIGN KEY (id) REFERENCES usuarios(id) ON DELETE CASCADE`.
   - Trigger: `trg_crear_wallet AFTER INSERT` que inserta en `provider_wallet`.

### 1.2. Dominio SaaS Core y Catálogo (Upstream)
1. **`public.usuarios`**:
   - `id`: `INTEGER` (PK).
   - `tenant_id`: `INTEGER NOT NULL` (`FOREIGN KEY (tenant_id) REFERENCES tenants(id)`).
   - Constraint de unicidad: `uq_usuarios_id_tenant (id, tenant_id)`.
2. **`public.memberships`**:
   - `id`: `UUID` (PK).
   - `tenant_id`: `INTEGER NOT NULL`, `establishment_id`: `UUID NOT NULL`, `user_id`: `INTEGER NOT NULL`.
   - FK compuesta: `(user_id, tenant_id) REFERENCES usuarios(id, tenant_id)`.
   - FK compuesta: `(establishment_id, tenant_id) REFERENCES establishments(id, tenant_id)`.
   - Constraints de unicidad: `uq_membership_establishment_user (establishment_id, user_id)` y `uq_membership_id_establishment_tenant (id, establishment_id, tenant_id)`.
   - Constraints check: `role ∈ {'OWNER', 'MANAGER', 'PROFESSIONAL', 'RECEPTIONIST'}`, `status ∈ {'INVITED', 'ACTIVE', 'SUSPENDED', 'REVOKED'}`.
3. **`public.service_offers`**:
   - `id`: `UUID` (PK).
   - `establishment_id`: `UUID NOT NULL`, `tenant_id`: `INTEGER NOT NULL`.
   - `name`: `VARCHAR(255) NOT NULL`, `base_price`: `NUMERIC(10,2) NOT NULL`, `base_duration`: `INTEGER NOT NULL`.
   - Constraints de unicidad: `uq_service_offers_id_tenant (id, tenant_id)` y `uq_service_offers_id_establishment_tenant (id, establishment_id, tenant_id)`.
4. **`public.service_assignments`**:
   - `id`: `UUID` (PK).
   - `establishment_id`: `UUID NOT NULL`, `tenant_id`: `INTEGER NOT NULL`, `service_offer_id`: `UUID NOT NULL`, `membership_id`: `UUID NOT NULL`.
   - **Constraint de unicidad física preexistente**: `uq_service_assignments_offer_membership UNIQUE (service_offer_id, membership_id)` (Existente en PostgreSQL; no creada por NODO-04).
   - FK compuesta a oferta: `(service_offer_id, establishment_id, tenant_id) REFERENCES service_offers(id, establishment_id, tenant_id)`.
   - FK compuesta a membresía: `(membership_id, establishment_id, tenant_id) REFERENCES memberships(id, establishment_id, tenant_id)`.
   - FK compuesta a sede: `(establishment_id, tenant_id) REFERENCES establishments(id, tenant_id)`.

---

## 2. CURRENT PHYSICAL STATE (ESTADO FÍSICO ACTUAL) `[FACT]`

```text
================================================================================
                    ESTADO FÍSICO ACTUAL DEL SISTEMA
================================================================================
DOMINIO SAAS (UPSTREAM)               FRONTERA                  DOMINIO B2C (DOWNSTREAM)
-----------------------               --------                  ------------------------
service_offers (067)             [SIN ENLACE FÍSICO]            public.services
      │                                       │                       │
      ▼                                       │                       ▼
service_assignments (068)                     │                 perfiles_prestador
      │                                       │                       │
      ▼                                       │                       ▼
memberships (065, 066)                        │                 usuarios
      │                                       │                       ▲
      └──────── user_id (INT) ────────────────┴───────────────────────┘
================================================================================
```

- Existe convergencia física en el identificador de usuario (`memberships.user_id` $\equiv$ `usuarios.id` $\equiv$ `perfiles_prestador.id`).
- **No existe ningún enlace físico persistido** entre la asignación de servicio SaaS y la fila resultante en `public.services`.
- Todas las 6 tablas en scope poseen `rowsecurity = true` en PostgreSQL.

---

## 3. APPROVED ARCHITECTURAL CONSTRAINTS `[APPROVED]`

El diseño físico está estrictamente delimitado por las decisiones ratificadas por el Director:

1. **`DEC-A` (Provider Resolution) `[APPROVED 🔒]`**:  
   La resolución de prestador se realiza exclusivamente mediante la identidad de usuario subyacente:
   ```text
   memberships.user_id ──► usuarios.id ≡ perfiles_prestador.id
   ```
   Se preserva la separación conceptual: `Membership ≠ Provider`. La membresía profesional apunta a un usuario (`usuarios.id`), el cual a su vez posee un perfil en `perfiles_prestador`. Queda prohibido crear claves foráneas artificiales `memberships ➔ perfiles_prestador`.
2. **`DEC-B` (Provider Provisioning) `[APPROVED — REJECTED AUTO-PROVISION 🔒]`**:  
   `NODO-04` tiene terminantemente prohibido crear automáticamente `perfiles_prestador` o `provider_wallet`. La preexistencia de la fila en `perfiles_prestador` es una precondición física indispensable. Si no existe, la operación aborta como `MATERIALIZATION_NOT_EXECUTABLE`.
3. **`DEC-C` (Materialization Identity) `[APPROVED CONCEPTUALLY 🔒]`**:  
   La identidad indivisible de materialización es la tupla tridimensional:
   ```text
   (establishment_id, service_offer_id, membership_id)
   ```
   Se aprueba conceptualmente el uso de una entidad técnica de mapeo downstream para desacoplar el origen SaaS del catálogo B2C.
4. **`DEC-D` (Granularidad) `[APPROVED 🔒]`**:  
   Una operación de materialización equivale exactamente a una asignación individual:
   ```text
   Unidad de Operación = (service_offer_id, membership_id)
   ```
   No se permiten comandos batch ni proyecciones masivas no explícitas.
5. **Separación de Dimensiones de Lifecycle `[APPROVED 🔒]`**:  
   ```text
   MATERIALIZATION ≠ PUBLICATION ≠ ACTIVATION
   ```
   `NODO-04` **NO adquiere autoridad de publicación ni activación**. El ciclo de vida de activación/publicación en B2C permanece fuera del alcance de este nodo.

---

## 4. PROPOSED PHYSICAL ARCHITECTURE `[PROPOSAL — NOT APPROVED]`

Se propone una arquitectura física desacoplada basada en 3 capas de ejecución:

```text
================================================================================
               ARQUITECTURA FÍSICA PROPUESTA PARA NODO-04
================================================================================

┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. CAPA DE TRANSPORTE Y CONTEXTO [PROPOSAL — NOT APPROVED]                  │
│    • Route: POST /api/v1/saas/hub/materializations/services                 │
│    • Middlewares: authMiddleware + activeContextMiddleware                  │
│    • Payload: { "service_offer_id": UUID, "membership_id": UUID }           │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 2. CAPA DE SERVICIO Y TRANSACTION BOUNDARY (ATOMIC) [PROPOSAL — NOT APPROVED]│
│    • Inicia Transacción PostgreSQL (BEGIN)                                  │
│    • Fija Contexto RLS: set_config('app.tenant_id', tenant_id, true)        │
│    • Verificación FOR SHARE de Oferta, Membresía y Asignación SaaS          │
│    • Verificación de preexistencia de perfiles_prestador (DEC-B)            │
│    • Evaluación de Mapeo Downstream                                         │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 3. CAPA DE PERSISTENCIA DOWNSTREAM [PROPOSAL — NOT APPROVED]                │
│    • Tabla Destino B2C: public.services (INSERT de fila proyectada)         │
│    • Tabla Técnica de Mapeo: saas_service_materializations (INSERT mapping) │
│    • COMMIT Transaccional                                                   │
└─────────────────────────────────────────────────────────────────────────────┘
================================================================================
```

---

## 5. MAPPING ENTITY PROPOSAL (ESTRUCTURA NORMALIZADA) `[PROPOSAL — NOT APPROVED]`

Aplicando el principio de **economía de datos y normalización relacional**, se separa de forma tajante el **Core Mapping** de los **Metadatos de Auditoría**:

### 5.1. Definición Propuesta para `saas_service_materializations`

```sql
CREATE TABLE public.saas_service_materializations (
    -- =========================================================================
    -- A. CORE MAPPING (Columnas Estrictamente Necesarias para Identidad y RLS)
    -- =========================================================================
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id INTEGER NOT NULL,
    establishment_id UUID NOT NULL,
    service_offer_id UUID NOT NULL,
    membership_id UUID NOT NULL,
    service_id UUID NOT NULL,

    -- =========================================================================
    -- B. METADATOS DE AUDITORÍA Y TRAZABILIDAD [PROPOSAL — NOT APPROVED]
    -- =========================================================================
    materialized_by_user_id INTEGER,
    materialized_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- =========================================================================
    -- C. RESTRICCIONES DE INTEGRIDAD Y AISLAMIENTO SAAS [PROPOSAL — NOT APPROVED]
    -- =========================================================================
    CONSTRAINT fk_mat_tenant 
        FOREIGN KEY (tenant_id) 
        REFERENCES public.tenants(id) 
        ON DELETE RESTRICT,

    CONSTRAINT fk_mat_assignment 
        FOREIGN KEY (service_offer_id, membership_id) 
        REFERENCES public.service_assignments(service_offer_id, membership_id) 
        ON DELETE RESTRICT,

    CONSTRAINT fk_mat_offer_context 
        FOREIGN KEY (service_offer_id, establishment_id, tenant_id) 
        REFERENCES public.service_offers(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,

    CONSTRAINT fk_mat_membership_context 
        FOREIGN KEY (membership_id, establishment_id, tenant_id) 
        REFERENCES public.memberships(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,

    -- =========================================================================
    -- D. INTEGRIDAD DOWNSTREAM HACIA B2C [PROPOSAL — NOT APPROVED]
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
    -- E. RESTRICCIONES DE UNICIDAD E IDEMPOTENCIA [PROPOSAL — NOT APPROVED]
    -- =========================================================================
    CONSTRAINT uq_mat_assignment_establishment 
        UNIQUE (establishment_id, service_offer_id, membership_id),

    CONSTRAINT uq_mat_service_id 
        UNIQUE (service_id)
);
```

---

## 6. FK / CONSTRAINT STRATEGY & CONTEXTUAL COHERENCE `[PROPOSAL — NOT APPROVED]`

Para garantizar físicamente que la materialización pertenezca exactamente al mismo `(Tenant + Establishment + Service Offer + Membership)` **utilizando exclusivamente constraints reales existentes**:

### 6.1. Evidencia Física de Constraints Existentes `[FACT]`
1. `service_assignments` cuenta con la restricción `uq_service_assignments_offer_membership UNIQUE (service_offer_id, membership_id)`.
2. `service_offers` cuenta con la restricción `uq_service_offers_id_establishment_tenant UNIQUE (id, establishment_id, tenant_id)`.
3. `memberships` cuenta con la restricción `uq_membership_id_establishment_tenant UNIQUE (id, establishment_id, tenant_id)`.

### 6.2. Estrategia de Coherencia de Contexto `[PROPOSAL — NOT APPROVED]`
- La constraint `fk_mat_assignment` referencia directamente a `uq_service_assignments_offer_membership`.
- Las constraints compuestas `fk_mat_offer_context` y `fk_mat_membership_context` validan a nivel de motor PostgreSQL que el `establishment_id` y `tenant_id` de la oferta y de la membresía sean idénticos al del registro de mapeo.
- Se asegura la coherencia estricta de sede y tenant sin crear relaciones físicas artificiales en las tablas del SaaS.
- La futura FK del mapping hacia Assignment permanece como `PROPOSAL — NOT APPROVED` hasta la formal aprobación de DDL.

---

## 7. B2C SERVICE LINKAGE STRATEGY `[PROPOSAL — NOT APPROVED]`

### 7.1. Problema de Enlace Seguro
¿Cómo garantizar que `saas_service_materializations.service_id` corresponde a la materialización correcta y no a un servicio arbitrario de B2C, **sin modificar `public.services`**?

### 7.2. Mecanismo de Garantía Propuesto
1. **Unicidad 1:1 (`uq_mat_service_id UNIQUE (service_id)`)**:  
   Garantiza que ningún `public.services.id` pueda estar asociado a más de un registro de materialización SaaS.
2. **Generación e Inserción Transaccional Cerrada**:  
   El runtime genera el `UUID` e inserta simultáneamente en `public.services` y en `saas_service_materializations` dentro del mismo bloque transaccional atómico.
3. **Cero Alteraciones a `public.services`**:  
   El catálogo B2C permanece 100% puro y libre de columnas de tracking SaaS.

---

## 8. RLS STRATEGY (ESTRATEGIA DE AISLAMIENTO MULTI-TENANT) `[PROPOSAL — NOT APPROVED]`

### 8.1. Estado Actual de RLS en las 6 Tablas en Scope `[FACT]`
| Tabla | Row Level Security (RLS) | Política Actual |
|---|---|---|
| `usuarios` | **ENABLED** | `tenant_isolation_usuarios USING (tenant_id = current_setting('app.tenant_id')::int)` |
| `perfiles_prestador` | **ENABLED** | `tenant_isolation_perfiles_prestador USING (tenant_id = current_setting('app.tenant_id')::int)` |
| `services` | **ENABLED** | `tenant_isolation_services USING (tenant_id = current_setting('app.tenant_id')::int)` |
| `memberships` | **ENABLED** | `tenant_isolation_memberships USING (tenant_id = current_setting('app.tenant_id')::int)` |
| `service_offers` | **ENABLED** | `tenant_isolation_service_offers USING (tenant_id = current_setting('app.tenant_id')::int)` |
| `service_assignments` | **ENABLED** | `tenant_isolation_service_assignments USING (tenant_id = current_setting('app.tenant_id')::int)` |

### 8.2. Política Propuesta para la Tabla de Mapeo `[PROPOSAL — NOT APPROVED]`
```sql
ALTER TABLE public.saas_service_materializations ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_saas_service_materializations ON public.saas_service_materializations
    FOR ALL
    USING (tenant_id = (NULLIF(current_setting('app.tenant_id', true), ''))::integer)
    WITH CHECK (tenant_id = (NULLIF(current_setting('app.tenant_id', true), ''))::integer);
```

---

## 9. TRANSACTION BOUNDARY (DELIMITACIÓN TRANSACCIONAL ATÓMICA) `[PROPOSAL — NOT APPROVED]`

```text
================================================================================
                    SECUENCIA TRANSACCIONAL ATÓMICA
================================================================================
BEGIN TRANSACTION;

  -- 1. Inyectar Contexto RLS
  SELECT set_config('app.tenant_id', $tenant_id, true);

  -- 2. Validación SaaS (FOR SHARE Locks)
  --    Verifica oferta activa en la sede activa
  SELECT id, name, description, base_price, base_duration 
  FROM service_offers 
  WHERE id = $service_offer_id AND establishment_id = $establishment_id AND tenant_id = $tenant_id
  FOR SHARE;

  --    Verifica membresía profesional activa en la sede activa
  SELECT id, user_id, role, status 
  FROM memberships 
  WHERE id = $membership_id AND establishment_id = $establishment_id AND tenant_id = $tenant_id
  FOR SHARE;

  --    Verifica existencia formal de la asignación
  SELECT id FROM service_assignments 
  WHERE service_offer_id = $service_offer_id AND membership_id = $membership_id;

  -- 3. Verificación de Preexistencia de Provider Profile (DEC-B)
  SELECT id FROM perfiles_prestador 
  WHERE id = $memberships.user_id AND tenant_id = $tenant_id;
  --> SI NO EXISTE: ABORTA CON MATERIALIZATION_NOT_EXECUTABLE

  -- 4. Verificación de Mapeo Previo (Identidad DEC-C)
  SELECT id, service_id FROM saas_service_materializations
  WHERE establishment_id = $establishment_id 
    AND service_offer_id = $service_offer_id 
    AND membership_id = $membership_id;
  --> SI YA EXISTE: COMPORTAMIENTO SEGÚN DECISIÓN DE RE-MATERIALIZACIÓN (OPEN)

  -- 5. Proyección Downstream en public.services (Respetando defaults de esquema existente)
  INSERT INTO public.services (
      id, provider_id, name, description, price, duration_minutes, tenant_id
  ) VALUES (
      $new_service_uuid, $memberships.user_id, $offer.name, $offer.description, 
      $offer.base_price, $offer.base_duration, $tenant_id
  );

  -- 6. Persistencia de Mapeo Downstream
  INSERT INTO public.saas_service_materializations (
      tenant_id, establishment_id, service_offer_id, membership_id, 
      service_id, materialized_by_user_id
  ) VALUES (
      $tenant_id, $establishment_id, $service_offer_id, $membership_id,
      $new_service_uuid, $actor_user_id
  );

COMMIT;
================================================================================
```

---

## 10. MATERIALIZATION PRECONDITIONS `[FACT / APPROVED]`

| # | Precondición | Nivel de Verificación | Condición de Rechazo | Código Contractual |
|---|---|---|---|---|
| **1** | Sesión Autenticada | Auth Layer | Token ausente / inválido | `401 UNAUTHENTICATED` |
| **2** | Active Context Válido | Middleware | `req.activeContext` ausente o incompleto | `400 ACTIVE_CONTEXT_REQUIRED` |
| **3** | Autoridad Administrativa | RBAC (`DEC-AS-003`) | `activeContext.role ∉ {'OWNER', 'MANAGER'}` | `403 INSUFFICIENT_ROLE_AUTHORITY` |
| **4** | Confinamiento de Sede | SQL / Context | `service_offer` o `membership` ajenos a `establishment_id` | `404 SERVICE_OFFER_NOT_FOUND` |
| **5** | Validez de Oferta | SQL Check | Oferta inexistente, `base_duration <= 0` o `base_price < 0` | `400 INVALID_SERVICE_OFFER` |
| **6** | Existencia de Asignación | SQL Check | No existe tupla en `service_assignments` | `404 SERVICE_ASSIGNMENT_NOT_FOUND` |
| **7** | Operabilidad de Colaborador | SQL Check (`DEC-AS-009`) | `memberships.status != 'ACTIVE'` o `role != 'PROFESSIONAL'` | `422 NON_OPERABLE_STAFF_MEMBER` |
| **8** | Preexistencia de Provider | SQL Check (`DEC-B`) | No existe fila en `perfiles_prestador` para `memberships.user_id` | `422 MATERIALIZATION_NOT_EXECUTABLE` |

---

## 11. B2C WRITE BOUNDARY & ACTIVATION STATUS

### 11.1. Columnas Físicas Escritas en `public.services` `[FACT]`
- `id`: UUID generado (`gen_random_uuid()`).
- `provider_id`: `memberships.user_id` (validado contra `perfiles_prestador.id`).
- `name`: Copiado de `service_offers.name`.
- `description`: Copiado de `service_offers.description`.
- `price`: Copiado de `service_offers.base_price`.
- `duration_minutes`: Copiado de `service_offers.base_duration`.
- `category`: Copiado si existe o `NULL`.
- `tenant_id`: Inyectado desde `activeContext.tenant_id`.
- `created_at`: `CURRENT_TIMESTAMP`.

### 11.2. Delimitación de `public.services.is_active` `[OUT OF SCOPE FOR NODO-04 / FUTURE LIFECYCLE 🔒]`
- En virtud del principio mandatario:
  ```text
  MATERIALIZATION ≠ PUBLICATION ≠ ACTIVATION
  ```
- `NODO-04` **no adquiere autoridad de publicación ni activación** sobre el catálogo B2C.
- El estado comercial de activación o publicación en marketplace permanece como **`OUT OF SCOPE FOR NODO-04 / FUTURE LIFECYCLE`**.
- Físicamente, el esquema existente de PostgreSQL cuenta con `is_active BOOLEAN DEFAULT true` `[FACT]`. `NODO-04` no diseña ni asume activación implícita.

---

## 12. FINAL MAPPING NORMALIZATION (NORMALIZACIÓN Y ECONOMÍA DE DATOS) `[PROPOSAL — NOT APPROVED]`

Se evalúa la necesidad física estricta de cada columna de la tabla técnica `saas_service_materializations`:

| Elemento / Columna | Necesidad Física | Justificación Técnica / Normalización | Clasificación |
|---|---|---|---|
| **`id`** | **Obligatoria** | Identificador técnico primario de la fila de mapeo (`UUID`). | `PROPOSAL — NOT APPROVED` |
| **`tenant_id`** | **Obligatoria** | Indispensable para aislamiento por RLS (`USING tenant_id = app.tenant_id`) y FKs compuestas. | `PROPOSAL — NOT APPROVED` |
| **`establishment_id`** | **Obligatoria** | Indispensable para validación compuesta de sede (`fk_mat_offer_context`, `fk_mat_membership_context`) y consultas directas por salón sin joins cuádruples. | `PROPOSAL — NOT APPROVED` |
| **`service_offer_id`** | **Obligatoria** | Dimensión 1 de la identidad conceptual aprobada (`DEC-C`). | `PROPOSAL — NOT APPROVED` |
| **`membership_id`** | **Obligatoria** | Dimensión 2 de la identidad conceptual aprobada (`DEC-C`). Permite derivar `provider_id`. | `PROPOSAL — NOT APPROVED` |
| **`service_id`** | **Obligatoria** | Enlace biunívoco downstream con `public.services(id)` (`UNIQUE (service_id)`). | `PROPOSAL — NOT APPROVED` |
| **`provider_id`** | **NO REQUERIDA (Omitida)** | **Redundante**: Se deriva unívocamente de `membership_id ➔ memberships.user_id ➔ usuarios.id ≡ perfiles_prestador.id` y ya existe persistido en `public.services.provider_id`. Omitirlo cumple con el principio de economía de datos. | `PROPOSAL — NOT APPROVED` |
| **`materialized_by_user_id`** | **Metadato de Auditoría** | No forma parte del core de identidad de materialización. Representa metadato de actoría administrativa (`req.user.id`). | `PROPOSAL — NOT APPROVED` |
| **`materialized_at`** | **Metadato de Auditoría** | Timestamp de registro técnico downstream inicial. | `PROPOSAL — NOT APPROVED` |
| **`updated_at`** | **NO REQUERIDA (Omitida)** | Innecesaria mientras el comportamiento ante re-materialización permanezca OPEN. | `PROPOSAL — NOT APPROVED` |

---

## 13. RE-MATERIALIZATION BEHAVIOR `[OPEN 🟡]`

La identidad de materialización `(establishment_id, service_offer_id, membership_id)` ya está aprobada `[DEC-C]`. El comportamiento físico ante una solicitud de materialización para una tupla que ya posee un registro previo en `saas_service_materializations` permanece formalmente como:
```text
RE-MATERIALIZATION BEHAVIOR = OPEN
```
(No se elige UPDATE, 409 ni NO-OP en este diseño; será dictaminado posteriormente).

---

## 14. DESMATERIALIZATION / UNASSIGNMENT LIFECYCLE `[FUTURE / OUT OF CURRENT NODE 🔒]`

El comportamiento ante desasignación en SaaS (`DELETE service_assignments`) o revocación de membresía (`memberships.status = 'REVOKED'`) se clasifica formalmente como:
```text
DESMATERIALIZATION / UNASSIGNMENT LIFECYCLE = OUT OF CURRENT NODE / FUTURE LIFECYCLE DECISION
```
No bloquea la arquitectura física de materialización inicial.

---

## 15. ESTADO INTEGRAL DE LAS DECISIONES FÍSICAS (DECISION STATUS MATRIX)

```text
================================================================================
           MATRIZ FINAL DE ESTADO DE DECISIONES FÍSICAS — NODO-04
================================================================================
```

| Elemento | Estado |
|---|---|
| **Provider Resolution** | **`APPROVED 🔒`** |
| **No Provider Provisioning** | **`APPROVED 🔒`** |
| **Materialization Identity** | **`APPROVED CONCEPTUALLY 🔒`** |
| **Materialization Granularity** | **`APPROVED 🔒`** |
| **Mapping Entity** | **`PROPOSAL — NOT APPROVED 🟡`** |
| **Mapping Columns** | **`PROPOSAL — NOT APPROVED 🟡`** |
| **Assignment FK** | **`PROPOSAL — NOT APPROVED 🟡`** |
| **RLS Strategy** | **`PROPOSAL — NOT APPROVED 🟡`** |
| **Transaction Boundary** | **`PROPOSAL — NOT APPROVED 🟡`** |
| **B2C Activation** | **`OUT OF SCOPE 🔒`** |
| **Re-materialization** | **`OPEN 🟡`** |
| **Desmaterialization** | **`FUTURE / OUT OF CURRENT NODE 🔒`** |
| **Audit Metadata** | **`PROPOSAL — NOT APPROVED 🟡`** |

---

## 16. VALIDACIÓN FINAL DE NO-MUTACIÓN

```text
================================================================================
                    VALIDACIÓN DE NO-MUTACIÓN FÍSICA
================================================================================
ARCHIVOS DE CÓDIGO MODIFICADOS:     0
ARCHIVOS DE MIGRACIÓN CREADOS:      0
TABLAS O VISTAS MUTADAS:            0
NODOS CERRADOS MODIFICADOS:         0
FRONTEND MODIFICADO:                0
================================================================================
```

---

## 17. ESTADO FINAL OBLIGATORIO

```text
================================================================================
NODO-04 — DOWNSTREAM B2C MATERIALIZATION ADAPTER
PHYSICAL ARCHITECTURE DESIGN — FINAL RECONCILIATION / READY FOR DIRECTOR GATE 🟡

IMPLEMENTATION — NOT AUTHORIZED 🔴
================================================================================
```
