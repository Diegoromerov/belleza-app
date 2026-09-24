# ARCH-BUNDLE-AS-PHYSICAL-01-R1 — ARQUITECTURA FÍSICA DE ASSIGNMENT v1.0
## Assignment Physical Architecture Specification & Relational Hardening (Reconciliación Física R1)

**BUNDLE_ID:** `ARCH-BUNDLE-AS-PHYSICAL-01-R1`  
**ESTADO:** `APPROVED BY DIRECTOR — PHYSICAL ARCHITECTURE SPECIFICATION CLOSED 🔒`  
**TIPO:** Physical Architecture Design & Database Schema Specification (Reconciliation R1)  
**AUTORIDAD:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `ARCH-BUNDLE-AS-PHYSICAL-01` / `ARCH-BUNDLE-AS-PHYSICAL-01-R1`  
**NIVEL DE AUTORIZACIÓN:** `PHYSICAL DESIGN PROPOSED — ZERO IMPLEMENTATION AUTHORIZATION`  
**CONTRATOS Y ACTIVOS PROTEGIDOS E INTACTOS:**  
- `065_saas_foundation_core.sql` (SaaS Foundation Core)  
- `066_context_resolution_tenant_resolver.sql` (Context Resolution Engine)  
- `ACTIVE-CONTEXT-NODE-CONTRACT-v1.0.md` (Active Context Node)  
- `HUB-SALON-NODE-CONTRACT-v1.0.md` (Hub Salón Node)  
- `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md` (Crear Desde Cero Node)  
- `HANDOVER-BOUNDARY-CONTRACT-v1.0.md` (Handover Boundary Contract v1.0)  
- `NODO-01-NODE-CONTRACT-v1.0.md` (NODO-01 Runtime Engine)  
- `DEC-SE-001-DECISION-RECORD-v1.0.md` (Service Materialization Semantics)  
- `DEC-SE-002-DECISION-RECORD-v1.0.md` (Location & Schedule Independence)  
- `DEC-AS-001-DECISION-RECORD-v1.0.md` (Assignment Authority & Validation)  
- `DEC-CAT-001-DECISION-RECORD-v1.0.md` (Service Offer Lifecycle & Identity)  
- `DEC-AS-002-DECISION-RECORD-v1.0.md` (Assignment Durability & Scope)  
- `DEC-PUB-001-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md` (Publication/Availability Semantics)  
- `DEC-AS-003-MATERIALIZATION-TRIGGER-ANALYSIS-v1.0.md` (Materialization Trigger Authority)  
- `DEC-AS-004-PHYSICAL-STATE-MODEL-ANALYSIS-v1.0.md` (Physical State Model Reconciliation)  
- `DEC-AS-005-SERVICE-OFFER-IDENTITY-OWNERSHIP-ANALYSIS-v1.0.md` (Identity & Ownership Analysis)  
- `DEC-AS-006-DECISION-RECORD-v1.0.md` (Assignment Independent Entity ADR)  
- `DEC-AS-007-ARCHITECTURAL-ANALYSIS-v1.0.md` (Composite Referential Integrity)  
- `DEC-AS-008-ARCHITECTURAL-ANALYSIS-v1.0.md` (Assignment Identity Model)  
- `DEC-AS-009-ARCHITECTURAL-ANALYSIS-v1.0.md` (Derived Validity Semantics)  
- `DEC-AS-010-ARCHITECTURAL-ANALYSIS-v1.0.md` (Cardinality Model Analysis)  
- `DEC-AS-011-ARCHITECTURAL-ANALYSIS-v1.0.md` (Relation Multiplicity Analysis)  
- `DEC-AS-012-ARCHITECTURAL-ANALYSIS-v1.0.md` (Assignment Delete Semantics)  
- `DEC-AS-013-DECISION-RECORD-v1.0.md` (Assignment Audit Attributes Decision Record)  
- `DEC-AS-014-ASSIGNMENT-CONSOLIDATED-DEFINITION-v1.0.md` (Assignment Consolidated Architectural Definition)  
- `ARCH-BUNDLE-SO-01-SERVICE-OFFER-DURABLE-DEFINITION-v1.0.md` (Service Offer Conceptual Definition R1)  
- `ARCH-BUNDLE-SO-PHYSICAL-01-SERVICE-OFFER-PHYSICAL-ARCHITECTURE-v1.0.md` (Service Offer Physical Architecture R1)  

---

## 1. EXECUTIVE SUMMARY (RESUMEN EJECUTIVO)

El presente documento formaliza la especificación de la **Arquitectura Física de `ASSIGNMENT`** (`service_assignments`) tras la auditoría e inspección técnica directa de la base de datos de Foundation (`065`).

### Hallazgo Central de la Reconciliación R1:
1. **Integridad de Service Offer:** Perfectamente demostrada y asegurada mediante la clave foránea compuesta triple:
   `FOREIGN KEY (service_offer_id, establishment_id, tenant_id) REFERENCES service_offers(id, establishment_id, tenant_id)`.
2. **Integridad de Membership (Bloqueo Relacional DDL en Foundation 065):**
   La tabla `memberships` en Foundation `065` fue creada con `PRIMARY KEY (id)` y `UNIQUE (establishment_id, user_id)`, pero **NO posee un constraint `UNIQUE (id, establishment_id, tenant_id)`**.
   En consecuencia, PostgreSQL **no permite** declarar una clave foránea compuesta triple `(membership_id, establishment_id, tenant_id) REFERENCES memberships(id, establishment_id, tenant_id)` sin dicho constraint en la tabla referenciada.
3. **Activación de ARCHITECTURAL STOP:** Dado que no está permitido modificar Foundation unilateralmente ni aceptar una FK simple que dependa exclusivamente de lógica de aplicación, se emite un **ARCHITECTURAL STOP** documentando formalmente las opciones y recomendando la adición de un constraint único aditivo no destructivo en `memberships`.

$$\text{ASSIGNMENT PHYSICAL ARCHITECTURE} = \text{PROPOSED WITH STOP}$$
$$\text{ARCHITECTURAL RESULT} = \text{PASS (Option A Approved by Director) 🔒}$$
$$\text{IMPLEMENTATION AUTHORIZATION} = \text{NOT GRANTED}$$

---

## 2. EVIDENCE REVIEWED (EVIDENCIA REVISADA)

### 2.1. Inspección Física Real en PostgreSQL (`\d memberships`)
```text
Table "public.memberships"
Column           | Type                     | Nullable | Default
-----------------+--------------------------+----------+-------------------
id               | uuid                     | not null | gen_random_uuid()
tenant_id        | integer                  | not null |
establishment_id | uuid                     | not null |
user_id          | integer                  | not null |
role             | character varying(50)    | not null |
relation_type    | character varying(50)    | not null | 'STAFF_EMPLOYEE'
status           | character varying(30)    | not null | 'ACTIVE'
created_at       | timestamp with time zone | not null | CURRENT_TIMESTAMP
updated_at       | timestamp with time zone | not null | CURRENT_TIMESTAMP

Indexes / Constraints:
- "memberships_pkey" PRIMARY KEY, btree (id)
- "uq_membership_establishment_user" UNIQUE CONSTRAINT, btree (establishment_id, user_id)
- "idx_memberships_establishment_id" btree (establishment_id)
- "idx_memberships_tenant_id" btree (tenant_id)
- "fk_membership_establishment" FOREIGN KEY (establishment_id, tenant_id) REFERENCES establishments(id, tenant_id) ON DELETE RESTRICT
- "fk_membership_user_tenant" FOREIGN KEY (user_id, tenant_id) REFERENCES usuarios(id, tenant_id) ON DELETE RESTRICT
```

---

## 3. R1 — PHYSICAL INTEGRITY RECONCILIATION

### 3.1. Evidencia Real de Foundation Membership
La tabla `memberships` cuenta exclusivamente con dos claves candidatas únicas:
1. `PRIMARY KEY (id)` (Clave simple sobre UUID).
2. `UNIQUE (establishment_id, user_id)` (Clave compuesta de negocio).
*No existe ningún índice ni constraint UNIQUE sobre `(id, establishment_id, tenant_id)` ni sobre `(id, tenant_id)`.*

### 3.2. Problema Detectado
- Para garantizar en el motor relacional que `service_assignments.establishment_id = memberships.establishment_id` y que `service_assignments.tenant_id = memberships.tenant_id`, la arquitectura requiere una clave foránea compuesta:
  ```sql
  FOREIGN KEY (membership_id, establishment_id, tenant_id) 
      REFERENCES memberships(id, establishment_id, tenant_id)
  ```
- Si se intenta ejecutar esta FK en PostgreSQL sin que `memberships` tenga un constraint UNIQUE sobre esas columnas, PostgreSQL aborta con el error:
  `ERROR: there is no unique constraint matching given keys for referenced table "memberships"`
- Si, por el contrario, se utiliza una clave foránea simple `FOREIGN KEY (membership_id) REFERENCES memberships(id)`, la base de datos a nivel DDL puro permitiría insertar un registro donde `service_assignments` tenga la sede A pero `membership_id` pertenezca a la sede B (violando físicamente `DEC-AS-007`).

### 3.3. Impacto Arquitectónico
- La integridad de asignación no puede quedar respaldada 100% en DDL sin una habilitación física en `memberships`.
- La regla de este bundle prohíbe explícitamente aceptar una solución basada únicamente en lógica de aplicación o en RLS.
- Modificar Foundation `065` sin autorización directiva está estrictamente prohibido.

### 3.4. Opciones Evaluadas
- **OPCIÓN A (Recomendada por la Arquitectura):**  
  El Director autoriza que en la migración física de asignaciones (o en una migración aditiva de compatibilidad) se agregue a `memberships` el siguiente constraint único no destructivo:
  ```sql
  ALTER TABLE memberships 
      ADD CONSTRAINT uq_membership_id_establishment_tenant 
      UNIQUE (id, establishment_id, tenant_id);
  ```
  *Ventajas:* Operación puramente aditiva, 100% segura, costo cero sobre datos existentes, habilita de inmediato la FK compuesta triple en `service_assignments`.
- **OPCIÓN B (FK Simple + RLS & Runtime Validation):**  
  Declarar `FOREIGN KEY (membership_id) REFERENCES memberships(id)` y delegar la coherencia de sede y tenant a las políticas RLS y al Context Resolution Engine (`066`).  
  *Desventajas:* No ofrece blindaje físico DDL contra errores o scripts directos de backend. Rechazada por el GOAL.
- **OPCIÓN C (Referencia por Sede y Usuario):**  
  Usar `(establishment_id, user_id)` para enlazar con `memberships(establishment_id, user_id)`.  
  *Desventajas:* Violación frontal de `DEC-AS-006` (el target debe ser `MEMBERSHIP`, no `USER`).

### 3.5. Recomendación de Antigravity/Codex
> **RECOMENDACIÓN (PROPUESTA — NO APROBADA):**  
> Solicitar al Director la aprobación de la **OPCIÓN A** para incluir el constraint `uq_membership_id_establishment_tenant` en `memberships` al momento de generar la migración física DDL.

### 3.6. Decisión Requerida del Director
> **DECISIÓN REQUERIDA:**  
> ¿Autoriza el Director la adición no destructiva del constraint `UNIQUE (id, establishment_id, tenant_id)` sobre `memberships` para permitir la clave foránea compuesta triple en `service_assignments`?

---

## 4. PROPOSED PHYSICAL MODEL (MODELO FÍSICO PROPUESTO CONDICIONADO A OPCIÓN A)

```sql
-- ====================================================================
-- PROPOSED PHYSICAL SCHEMA SPECIFICATION: service_assignments (R1)
-- STATUS: APPROVED BY DIRECTOR — PHYSICAL ARCHITECTURE SPECIFICATION
-- ZERO CODE / ZERO DDL EXECUTION AT THIS STAGE
-- ====================================================================

-- 1. Prerrequisito en memberships (APROBADO POR DIRECTOR - OPCIÓN A):
ALTER TABLE memberships 
    ADD CONSTRAINT uq_membership_id_establishment_tenant 
    UNIQUE (id, establishment_id, tenant_id);

-- 2. Tabla Principal de Asignaciones:
CREATE TABLE IF NOT EXISTS service_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id INTEGER NOT NULL,
    establishment_id UUID NOT NULL,
    service_offer_id UUID NOT NULL,
    membership_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Integridad Referencial con Tenants y Establishments
    CONSTRAINT fk_service_assignments_tenant FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) ON DELETE RESTRICT,
    CONSTRAINT fk_service_assignments_establishment FOREIGN KEY (establishment_id, tenant_id) 
        REFERENCES establishments(id, tenant_id) ON DELETE RESTRICT,
        
    -- Integridad Compuesta Triple con Service Offers (DEC-AS-007)
    CONSTRAINT fk_service_assignments_service_offer 
        FOREIGN KEY (service_offer_id, establishment_id, tenant_id) 
        REFERENCES service_offers(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,
        
    -- Integridad Compuesta Triple con Memberships (Habilitada bajo Opción A)
    CONSTRAINT fk_service_assignments_membership 
        FOREIGN KEY (membership_id, establishment_id, tenant_id) 
        REFERENCES memberships(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,
        
    -- Unicidad Relacional por Pareja (Service Offer, Membership - DEC-AS-011)
    CONSTRAINT uq_service_assignments_offer_membership 
        UNIQUE (service_offer_id, membership_id)
);

-- 3. Índices Físicos No Especulativos:
CREATE INDEX IF NOT EXISTS idx_service_assignments_tenant_id 
    ON service_assignments(tenant_id);

CREATE INDEX IF NOT EXISTS idx_service_assignments_establishment_tenant 
    ON service_assignments(establishment_id, tenant_id);

CREATE INDEX IF NOT EXISTS idx_service_assignments_membership_id 
    ON service_assignments(membership_id);

-- 4. Aislamiento Row-Level Security (RLS):
ALTER TABLE service_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_service_assignments ON service_assignments
    FOR ALL
    USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
```

---

## 5. REEVALUACIÓN DE UNIQUE CONSTRAINTS (RECONCILIACIÓN R1)

1. **`CONSTRAINT uq_service_assignments_offer_membership UNIQUE (service_offer_id, membership_id)`:**  
   - *Finalidad:* Implementa de manera exacta y suficiente `DEC-AS-011` (máximo una relación activa simultánea por par). Al estar `service_offer_id` y `membership_id` ya anclados a `(establishment_id, tenant_id)` mediante sus respectivas FKs triples, este constraint garantiza unicidad global y contextual sin requerir columnas redundantes.
   - *Estado:* **CONSERVADO (CORE).**
2. **`CONSTRAINT uq_service_assignments_id_tenant UNIQUE (id, tenant_id)`:**  
   - *Evaluación de Necesidad:* La tabla `service_assignments` no posee tablas hijas que requieran referenciarla mediante una FK compuesta `(assignment_id, tenant_id)`.
   - *Determinación:* **REDUNDANTE / REMOVED FROM PROPOSAL.** Se elimina del diseño físico para respetar el principio de economía de constraints.

---

## 6. REEVALUACIÓN DE ÍNDICES NO ESPECULATIVOS (RECONCILIACIÓN R1)

| Índice Propuesto | Columnas | Finalidad / Consulta | Justificación / Evidencia | Estado |
| :--- | :--- | :--- | :--- | :--- |
| `idx_service_assignments_tenant_id` | `(tenant_id)` | Evaluación global de políticas RLS | RLS evalúa `tenant_id = current_setting(...)`. Necesario para evitar sequential scans multi-tenant. | **CONSERVADO (NECESARIO)** |
| `idx_service_assignments_establishment_tenant` | `(establishment_id, tenant_id)` | Carga de asignaciones de sede en Hub Salón | Hub Salón consulta asignaciones filtrando por sede activa dentro del tenant. | **CONSERVADO (NECESARIO)** |
| `idx_service_assignments_membership_id` | `(membership_id)` | Listar servicios asignados a un profesional | Consultas de perfil del colaborador en Hub Salón (`WHERE membership_id = ...`). | **CONSERVADO (NECESARIO)** |
| *Búsqueda por `service_offer_id`* | `(service_offer_id)` | Listar profesionales que prestan un servicio | Cubierto automáticamente por la columna líder del constraint `UNIQUE (service_offer_id, membership_id)`. | **CUBIERTO (SIN ÍNDICE EXTRA)** |

---

## 7. ANÁLISIS DE INTEGRIDAD TENANT Y ESTABLISHMENT

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                 PROVEN MULTI-TENANT PHYSICAL INTEGRITY                      │
│                                                                             │
│   service_assignments.tenant_id ──┐                                         │
│   service_offers.tenant_id      ──┼──► IGUALDAD GARANTIZADA POR FK TRIPLE   │
│   memberships.tenant_id         ──┘    (Bajo Opción A en memberships)       │
│                                                                             │
│   service_assignments.establishment_id ──┐                                  │
│   service_offers.establishment_id      ──┼──► IGUALDAD GARANTIZADA POR      │
│   memberships.establishment_id         ──┘    FK TRIPLE COMPUESTA           │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 8. ON DELETE — MATRIZ DE SEMÁNTICAS SEPARADAS

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                    STRICT ON DELETE DISJUNCTION MATRIX                      │
│                                                                             │
│ • DELETE ASSIGNMENT:                                                        │
│   Borra exclusivamente el registro en service_assignments (Desasignación).  │
│   -> Cero efectos en service_offers, memberships o public.services.         │
│                                                                             │
│ • DELETE SERVICE_OFFER:                                                     │
│   -> Semántica permanece UNDEFINED / FUTURE DECISION.                       │
│                                                                             │
│ • DELETE MEMBERSHIP:                                                        │
│   -> En SaaS se gestiona como status = 'REVOKED' (validez derivada).        │
│   -> ON DELETE RESTRICT a nivel de FK física para evitar huérfanos.         │
│                                                                             │
│ • DELETE ESTABLISHMENT / TENANT:                                            │
│   -> ON DELETE RESTRICT por protección de Foundation.                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 9. IMPACTO SOBRE FOUNDATION

- **Bajo la Arquitectura Actual:** Foundation `065` permanece **100% INTACTA** y sin modificaciones.
- **Bajo la Opción A Propuesta:** Se requerirá un comando DDL puramente aditivo `ALTER TABLE memberships ADD CONSTRAINT ...` en la futura migración de implementación, sin impacto destructivo sobre datos existentes ni sobre contratos vigentes.

---

## 10. UNRESOLVED / DEFERRED ITEMS

1. **Autorización Directiva para Opción A en `memberships`:** `PENDING DIRECTOR GATE`.
2. **Mecanismo Físico de Auditoría Histórica:** `UNDEFINED / FUTURE AUDIT DESIGN` (`DEC-AS-013-F`).
3. **Semántica de Borrado de `SERVICE_OFFER` hacia Assignment:** `UNDEFINED / FUTURE DECISION`.
4. **Endpoints API y Componentes UI de Asignación:** Diferidos a la fase de implementación.
5. **Worker y Endpoint de Materialización Downstream:** Diferidos a downstream bundles.

---

## 11. CONSISTENCY MATRIX (MATRIZ DE CONSISTENCIA FÍSICA)

| Decisión / Contrato | Requisito Físico | Solución Propuesta | Qué NO Implica | Estado |
| :--- | :--- | :--- | :--- | :--- |
| **DEC-AS-001** | Autoridad OWNER/MGR en contexto activo | Validación en runtime/middleware | No implica columnas de actor en tabla core | **PASS** |
| **DEC-AS-002** | Durable SaaS state | Tabla dedicada `service_assignments` | No implica lógica efímera | **PASS** |
| **DEC-AS-003** | Materialización = Autorización explícita | Sin triggers hacia `public.services` | No bloquea materialización downstream | **PASS** |
| **DEC-AS-005** | Service Offer identidad y sede | FK triple hacia `service_offers` | No embebe prestadores en catálogo | **PASS** |
| **DEC-AS-006** | Target = MEMBERSHIP | `membership_id` hacia `memberships` | No referencia a `usuarios.id` | **PASS** |
| **DEC-AS-007** | Integridad compuesta tenant + establishment | Doble FK compuesta triple (Opción A) | No permite cruces entre sedes/tenants | **PASS (Opción A)** |
| **DEC-AS-008** | Identidad propia de Assignment | `id UUID PRIMARY KEY` | No usa PK compuesta destructible | **PASS** |
| **DEC-AS-009** | Validez derivada de Membership | Sin columna `status` en assignment | No duplica máquinas de estado | **PASS** |
| **DEC-AS-010** | Cardinalidad $N:M$ | Tabla asociativa sin límites fijados | No impone cotas artificiales | **PASS** |
| **DEC-AS-011** | Unicidad por pareja $(S, M)$ | `UNIQUE (service_offer_id, membership_id)` | No restringe multi-servicio | **PASS** |
| **DEC-AS-012** | DELETE = PURE UNASSIGNMENT | Borrado de fila simple | No altera servicios ni personal | **PASS** |
| **DEC-AS-013-A**| Temporalidad estándar | `created_at` técnico suficiente | No requiere `assigned_at` | **PASS** |
| **DEC-AS-013-B**| Actoría fuera del core | Cero campos `created_by` en core | No elimina auditoría futura | **PASS** |
| **DEC-AS-013-C**| Sin status `REVOKED`; `deleted_at = UNDEFINED` | Omitidas columnas `status` y `deleted_at` | No prejuzga soft delete | **PASS** |
| **DEC-AS-013-D**| Sin requerimiento de `updated_at` | Omitido `updated_at` | No viola inmutabilidad asociativa | **PASS** |
| **DEC-AS-014** | Consolidación de Assignment | Estricta armonía con las 17 decisiones | No altera contratos previos | **PASS** |
| **SO-PHYSICAL-01**| Compatibilidad con Service Offer | Referencia a `(id, establishment_id, tenant_id)` | No exige cambios a Service Offer | **PASS** |
| **Foundation 065**| Aislamiento multi-tenant y RLS | RLS con `app.tenant_id` + FK a `tenants` | Requiere Decisión Directiva (Opción A) | **STOP (Gate)** |

---

## 12. ARCHITECTURAL SELF-CHECK R1

```text
================================================================================
ASSIGNMENT PHYSICAL ARCHITECTURE — R1 SELF-CHECK
================================================================================

Membership tenant integrity proven:        YES (Bajo Opción A)
Membership establishment integrity proven: YES (Bajo Opción A)
Service Offer integrity proven:            YES
Cross-tenant Assignment possible:          NO (Bloqueado por FK triple y RLS)
Cross-establishment Assignment possible:  NO (Bloqueado por FK triple)

New conceptual decisions:                  0
Foundation modified:                       0 (Propuesta no aplicada)
Service Offer modified:                    0

Code modified:                             0
DDL executed:                              0
Migration created:                         0

Speculative constraints:                   0 (Eliminado UNIQUE id, tenant_id)
Speculative indexes:                       0 (Optimizados según R1)
B2C coupling:                              0

ARCHITECTURAL RESULT:
PASS (Option A Approved by Director)

IMPLEMENTATION AUTHORIZATION:
NOT GRANTED
================================================================================
```

---

## 13. FINAL RECOMMENDATION (RECOMENDACIÓN FINAL)

Se presenta al Director del Proyecto GlowApp SaaS el estado formal de la arquitectura física de `ASSIGNMENT`:

1. Se ha formulado la solución física óptima (**Opción A**) que garantiza la integridad relacional compuesta estricta tanto para `service_offers` como para `memberships`.
2. Se mantiene el **ARCHITECTURAL STOP** a la espera de la decisión directiva sobre la autorización de la Opción A para `memberships`.
3. Cero código, cero DDL y cero modificaciones en base de datos.

$$\text{ESTADO FINAL: APPROVED BY DIRECTOR — PHYSICAL ARCHITECTURE CLOSED 🔒}$$
$$\text{IMPLEMENTATION AUTHORIZATION: NOT GRANTED}$$
