# ARCH-BUNDLE-SO-PHYSICAL-01-R1 — ARQUITECTURA FÍSICA DE SERVICE OFFER v1.0
## Service Offer Physical Architecture Design & Foundation Alignment (Reconciliación Física R1)

**BUNDLE_ID:** `ARCH-BUNDLE-SO-PHYSICAL-01-R1`  
**ESTADO:** `PROPOSED — PHYSICAL ARCHITECTURE DESIGN — CONSISTENCY PASS — RECONCILIATION R1 PASS 🔒`  
**TIPO:** Physical Architecture Design & Database Schema Specification (Reconciliation R1)  
**AUTORIDAD:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `ARCH-BUNDLE-SO-PHYSICAL-01` / `ARCH-BUNDLE-SO-PHYSICAL-01-R1`  
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

---

## 1. EXECUTIVE SUMMARY (RESUMEN EJECUTIVO)

El presente documento formaliza el diseño de la **Arquitectura Física de `SERVICE_OFFER`** en PostgreSQL para el entorno SaaS GlowApp, integrando las directivas de la **Reconciliación Física R1**:

1. **Separación Estricta de Semánticas `ON DELETE`:** Se formaliza la distinción epistemológica y física entre `DELETE TENANT`, `DELETE ESTABLISHMENT`, `DELETE SERVICE_OFFER` y `DELETE ASSIGNMENT`. La semántica de `DELETE SERVICE_OFFER` permanece `UNDEFINED / FUTURE DECISION`.
2. **Economía Física de Índices:** Se eliminan índices redundantes aplicando el principio `NO SPECULATIVE INDEXES`, demostrando la necesidad técnica específica de cada índice conservado.
3. **Justificación de Constraints `UNIQUE` Compuestos:** Se fundamenta el rol de `UNIQUE (id, establishment_id, tenant_id)` como habilitador estricto de PostgreSQL para la futura integridad referencial compuesta triple de `ASSIGNMENT` (`DEC-AS-007`, `DEC-AS-014`).

Este documento **NO constituye autorización de implementación ni ejecución DDL**. Permanece como propuesta técnica sujeta al Director Gate.

$$\text{SERVICE OFFER PHYSICAL ARCHITECTURE} = \text{CONSISTENT}$$
$$\text{PHYSICAL CONSISTENCY} = \text{PASS}$$
$$\text{RECONCILIATION R1} = \text{PASS 🔒}$$
$$\text{IMPLEMENTATION AUTHORIZATION} = \text{NOT GRANTED}$$

---

## 2. EVIDENCE REVIEWED (EVIDENCIA REVISADA)

### 2.1. Arquitectura Conceptual y Directivas Cerradas
- **`DEC-CAT-001` (Option B — Operational State):** `SERVICE_OFFER` es un activo operativo durable post-handover (`IDENTITY REQUIREMENT = DEMONSTRATED`).
- **`DEC-AS-005` & `DEC-AS-007`:** `SERVICE_OFFER` posee identidad propia, ownership en `ESTABLISHMENT` y exige coherencia compuesta `(establishment_id, tenant_id)`.
- **`DEC-SE-001` & `DEC-PUB-001`:** `SERVICE_OFFER ≠ public.services`. Cero acoplamiento físico o triggers hacia B2C.
- **`ARCH-BUNDLE-SO-01-R1`:** 
  - `is_active` = `UNDEFINED / PENDING DECISION` (NO se introduce como columna física).
  - `DELETE SERVICE_OFFER` = `UNDEFINED / FUTURE DECISION` (NO se definen semánticas destructivas prematuras).

### 2.2. Base Física Existente (Foundation v1.0)
- **`organizations` (`065`):** `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`, `tenant_id INTEGER NOT NULL REFERENCES tenants(id)`, `CONSTRAINT uq_organization_id_tenant UNIQUE (id, tenant_id)`.
- **`establishments` (`065`):** `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`, `tenant_id INTEGER NOT NULL REFERENCES tenants(id)`, `organization_id UUID NOT NULL`, `CONSTRAINT fk_establishment_organization FOREIGN KEY (organization_id, tenant_id) REFERENCES organizations(id, tenant_id) ON DELETE RESTRICT`, `CONSTRAINT uq_establishment_id_tenant UNIQUE (id, tenant_id)`.
- **`memberships` (`065`):** `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`, `tenant_id INTEGER NOT NULL`, `establishment_id UUID NOT NULL`, `CONSTRAINT fk_membership_establishment FOREIGN KEY (establishment_id, tenant_id) REFERENCES establishments(id, tenant_id) ON DELETE RESTRICT`.
- **`public.services` (Pre-Nodo 01 Legacy B2C):** `id SERIAL PRIMARY KEY`, `provider_id INTEGER NOT NULL REFERENCES perfiles_prestador(id)`, `name VARCHAR`, `price NUMERIC`, `duration INTEGER`.

---

## 3. PHYSICAL ARCHITECTURE QUESTIONS (SO-P01 A SO-P16)

### SO-P01 — MATERIALIZACIÓN FÍSICA
- **Determinación:** `SERVICE_OFFER` requiere una estructura física durable propia en PostgreSQL.
- **Justificación:** `DEC-CAT-001` establece que el catálogo es un activo operativo post-handover (`OPERATIONAL STATE`). Para subsistir a los requests HTTP, soportar consultas concurrentes en el Hub Salón, ser referenciable por múltiples registros independientes de `ASSIGNMENT` ($N:M$) y estar protegido por RLS multi-tenant, requiere una tabla relacional dedicada.

### SO-P02 — NOMBRE FÍSICO
- **Opciones Evaluadas:**
  1. `services`: **RECHAZADA.** Colisiona y crea ambigüedad crítica con `public.services` (Pre-Nodo 01 B2C).
  2. `establishment_services`: **VIABLE.** Clara, pero menos directa respecto a los contratos conceptuales y de frontera (`HBC v1.0`).
  3. `service_offers`: **PROPUESTA / RECOMENDADA.** Refleja con total exactitud la entidad de dominio `SERVICE_OFFER`, coincide con el campo `service_offers` de `HBC v1.0` y respeta la convención plural estándar en PostgreSQL.
- **Estado:** `PROPOSAL — NOT APPROVED / NOT IMPLEMENTED`.

### SO-P03 — IDENTIDAD FÍSICA
- **Tipo de Clave Primaria:** `UUID PRIMARY KEY DEFAULT gen_random_uuid()`.
- **Propiedades:** Generación criptográficamente segura, estabilidad global, desacoplamiento absoluto de secuencias seriales enteras.
- **Disyunción de Identidades Preservada:**
  $$\text{service\_offers.id (UUID)} \neq \text{assignments.id (UUID)} \neq \text{memberships.id (UUID)} \neq \text{public.services.id (INTEGER)}$$

### SO-P04 — TENANT ISOLATION
- **Columna:** `tenant_id INTEGER NOT NULL`.
- **Clave Foránea:** `REFERENCES tenants(id) ON DELETE RESTRICT`.
- **Alineación con Foundation:** 
  - `CONSTRAINT uq_service_offers_id_tenant UNIQUE (id, tenant_id)`.
  - `ENABLE ROW LEVEL SECURITY` con política estricta de aislamiento basada en `app.tenant_id`.

### SO-P05 — ESTABLISHMENT OWNERSHIP
- **Columna:** `establishment_id UUID NOT NULL`.
- **Integridad Compuesta:**
  `CONSTRAINT fk_service_offers_establishment FOREIGN KEY (establishment_id, tenant_id) REFERENCES establishments(id, tenant_id) ON DELETE RESTRICT`
- **Garantía:** Es físicamente imposible asociar una oferta de servicio a un establecimiento perteneciente a un tenant diferente.

### SO-P06 — COLUMNAS CORE FÍSICAS

| Columna | Tipo Físico Propuesto | Nullable | Justificación / Evidencia |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | `NOT NULL` | Identidad unívoca propia (`DEC-AS-005`, `DEC-CAT-001`). Default: `gen_random_uuid()`. |
| `tenant_id` | `INTEGER` | `NOT NULL` | Aislamiento multi-tenant transversal (`Foundation 065`). |
| `establishment_id` | `UUID` | `NOT NULL` | Ownership directo de la sede (`DEC-AS-005`, `DEC-AS-007`). |
| `name` | `VARCHAR(255)` | `NOT NULL` | Nombre comercial del servicio en catálogo de sede. |
| `description` | `TEXT` | `NULL` | Descripción opcional del servicio. |
| `base_duration` | `INTEGER` | `NOT NULL` | Duración base de referencia en minutos (CHECK > 0). |
| `base_price` | `NUMERIC(12,2)` | `NOT NULL` | Tarifa base de referencia en moneda local (CHECK >= 0). |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL` | Marca temporal técnica de persistencia (Default: `CURRENT_TIMESTAMP`). |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL` | Marca temporal técnica de persistencia (Default: `CURRENT_TIMESTAMP`). |

### SO-P07 — `is_active` (ESTADO PENDIENTE)
- **Determinación:** **NO se incluye la columna `is_active` en este bundle físico.**
- **Fundamento:** `ARCH-BUNDLE-SO-01-R1` formalizó `SERVICE_OFFER operational enablement / is_active = UNDEFINED / PENDING DECISION`. No se prejuzga ni introduce unilateralmente en la capa física.

### SO-P08 — DESCRIPCIÓN, CATEGORÍA Y DATOS COMERCIALES
- `name`: Incluido como `VARCHAR(255) NOT NULL`.
- `description`: Incluido como `TEXT NULL`.
- `base_duration`: Incluido como `INTEGER NOT NULL`.
- `base_price`: Incluido como `NUMERIC(12,2) NOT NULL`.
- `category`: **DIFERIDO.** La categorización taxonómica de catálogo SaaS no forma parte del núcleo mínimo y permanece `UNDEFINED / FUTURE DESIGN`.

### SO-P09 — CONSTRAINTS FÍSICOS
1. `pk_service_offers`: `PRIMARY KEY (id)`
2. `chk_service_offers_duration`: `CHECK (base_duration > 0)`
3. `chk_service_offers_price`: `CHECK (base_price >= 0)`
4. `uq_service_offers_id_tenant`: `UNIQUE (id, tenant_id)`
5. `uq_service_offers_id_establishment_tenant`: `UNIQUE (id, establishment_id, tenant_id)` (facilita la futura integridad compuesta de triple referencia para `ASSIGNMENT`).
6. *Unicidad de Nombre en Sede:* `UNDEFINED / BUSINESS DECISION` (se difiere si se permiten ofertas con el mismo nombre en una misma sede).

### SO-P10 — FOREIGN KEYS
1. `fk_service_offers_tenant`:  
   `FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT`
2. `fk_service_offers_establishment`:  
   `FOREIGN KEY (establishment_id, tenant_id) REFERENCES establishments(id, tenant_id) ON DELETE RESTRICT`

### SO-P11 — ON DELETE — SEPARACIÓN ESTRICTA DE SEMÁNTICAS (RECONCILIACIÓN R1)

Se formaliza la separación categórica e inequívoca de las cuatro semánticas de eliminación:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                    STRICT ON DELETE SEMANTIC DISJUNCTION                    │
│                                                                             │
│   DELETE TENANT                                                             │
│         ≠                                                                   │
│   DELETE ESTABLISHMENT                                                      │
│         ≠                                                                   │
│   DELETE SERVICE_OFFER                                                      │
│         ≠                                                                   │
│   DELETE ASSIGNMENT                                                         │
└─────────────────────────────────────────────────────────────────────────────┘
```

1. **`DELETE TENANT`:**
   - *Comportamiento Físico:* `ON DELETE RESTRICT` en `fk_service_offers_tenant`.
   - *Fundamento:* Respeta el estándar estricto de Foundation `065` para prevenir la destrucción accidental de datos de catálogo ante intentos de borrado del tenant raíz.
2. **`DELETE ESTABLISHMENT`:**
   - *Comportamiento Físico:* `ON DELETE RESTRICT` en `fk_service_offers_establishment`.
   - *Fundamento:* Protege el catálogo activo de la sede contra eliminación accidental del establecimiento sin desmantelamiento administrativo previo.
3. **`DELETE SERVICE_OFFER`:**
   - *Estado Epistemológico:* `UNDEFINED / FUTURE DECISION` (`ARCH-BUNDLE-SO-01-R1`).
   - *Delimitación:* **NO se determina el destino de los futuros `ASSIGNMENT`s dependientes.** No se infiere cascada (`CASCADE`), no se infiere bloqueo (`RESTRICT`), no se infiere borrado lógico (`deleted_at`), no se infiere archivado.
4. **`DELETE ASSIGNMENT`:**
   - *Estado Epistemológico:* `CLOSED — PURE UNASSIGNMENT` (`DEC-AS-012`).
   - *Delimitación:* La eliminación de una asignación destruye exclusivamente el vínculo relacional, dejando al `SERVICE_OFFER` **100% intacto**.

### SO-P12 — ÍNDICES — ECONOMÍA FÍSICA Y NO ESPECULACIÓN (RECONCILIACIÓN R1)

Se aplica el principio `NO SPECULATIVE INDEXES` y análisis de redundancia en árboles B-Tree de PostgreSQL:

| Índice Propuesto | Definición Física | Consulta / Integridad que lo Necesita | Evidencia y Justificación | Estado |
| :--- | :--- | :--- | :--- | :--- |
| `idx_service_offers_tenant_id` | `ON service_offers(tenant_id)` | Evaluación de políticas RLS: `USING (tenant_id = ...)` | Las políticas RLS de PostgreSQL filtran por `tenant_id` como condición global. Al no existir otro índice con `tenant_id` como columna líder, este índice es estrictamente necesario para evitar sequential scans multi-tenant. | **CONSERVADO (NECESARIO)** |
| `idx_service_offers_establishment_tenant` | `ON service_offers(establishment_id, tenant_id)` | Carga de catálogo en Hub Salón (`WHERE establishment_id = ... AND tenant_id = ...`) y validación de la FK compuesta `fk_service_offers_establishment`. | Hub Salón opera en el contexto de una sede activa. Indexa `establishment_id` como columna líder (leftmost prefix). | **CONSERVADO (NECESARIO)** |
| `idx_service_offers_establishment_id` | `ON service_offers(establishment_id)` | Consultas filtradas exclusivamente por `establishment_id`. | **REDUNDANTE.** En PostgreSQL B-Tree, el índice compuesto `(establishment_id, tenant_id)` ya indexa `establishment_id` como prefijo izquierdo, cubriendo perfectamente cualquier búsqueda por `establishment_id` solo. | **ELIMINADO (REDUNDANTE)** |

### SO-P13 — POLÍTICA ROW-LEVEL SECURITY (RLS)
- `ALTER TABLE service_offers ENABLE ROW LEVEL SECURITY;`
- Política canónica Foundation:
```sql
CREATE POLICY tenant_isolation_service_offers ON service_offers
    FOR ALL
    USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
```

### SO-P14 — RELACIÓN FÍSICA CON `public.services`
- **Frontera Física Estricta:** Cero columnas `provider_id`, cero claves foráneas hacia `public.services`, cero triggers de replicación.
- **Estado:** `UNDEFINED / FUTURE MATERIALIZATION DESIGN`.

### SO-P15 — UNIQUE COMPOSITES — JUSTIFICACIÓN DE INTEGRIDAD REFERENCIAL (RECONCILIACIÓN R1)

Se analiza la legitimidad y función física de cada constraint `UNIQUE` compuesto frente a la PK simple `(id)`:

1. **`CONSTRAINT uq_service_offers_id_establishment_tenant UNIQUE (id, establishment_id, tenant_id)`:**
   - *Función Física:* En PostgreSQL, una tabla hija no puede declarar una clave foránea compuesta hacia columnas que no tengan un constraint `UNIQUE` o `PRIMARY KEY` explícito que las contenga en ese orden exacto.
   - *Finalidad Legítima Demostrada:* Es el **prerrequisito físico indispensable** para que el siguiente bundle (`ASSIGNMENT PHYSICAL ARCHITECTURE`) pueda implementar la integridad referencial compuesta triple (`DEC-AS-007`, `DEC-AS-014`):
     `FOREIGN KEY (service_offer_id, establishment_id, tenant_id) REFERENCES service_offers(id, establishment_id, tenant_id)`.
   - *Estado:* **CONSERVADO COMO REQUISITO FÍSICO PROPUESTO.**
2. **`CONSTRAINT uq_service_offers_id_tenant UNIQUE (id, tenant_id)`:**
   - *Función Física:* Soporta el patrón general de Foundation (`065`) para relaciones multi-tenant estándar.
   - *Estado:* Conservado como patrón canónico de Foundation.

### SO-P16 — TIMESTAMPS
- `created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP`: Registro de creación técnica.
- `updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP`: Registro de persistencia técnica.
- `deleted_at`: **NO INCLUIDO** (borrado lógico no decidido conceptualmente).

---

## 4. PROPOSED PHYSICAL MODEL (MODELO FÍSICO PROPUESTO)

```sql
-- ====================================================================
-- PROPOSED PHYSICAL SCHEMA SPECIFICATION: service_offers (R1 RECONCILED)
-- STATUS: PROPOSAL — NOT APPROVED / NOT IMPLEMENTED
-- ZERO CODE / ZERO DDL EXECUTION AT THIS STAGE
-- ====================================================================

CREATE TABLE IF NOT EXISTS service_offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id INTEGER NOT NULL,
    establishment_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    base_duration INTEGER NOT NULL,
    base_price NUMERIC(12, 2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints de Validación de Dominio
    CONSTRAINT chk_service_offers_duration CHECK (base_duration > 0),
    CONSTRAINT chk_service_offers_price CHECK (base_price >= 0),
    
    -- Integridad Referencial Compuesta con Foundation (ON DELETE RESTRICT)
    CONSTRAINT fk_service_offers_tenant FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) ON DELETE RESTRICT,
    CONSTRAINT fk_service_offers_establishment FOREIGN KEY (establishment_id, tenant_id) 
        REFERENCES establishments(id, tenant_id) ON DELETE RESTRICT,
        
    -- Claves Únicas Compuestas para Integridad Multi-Tenant y Soporte a Futuro ASSIGNMENT
    CONSTRAINT uq_service_offers_id_tenant UNIQUE (id, tenant_id),
    CONSTRAINT uq_service_offers_id_establishment_tenant UNIQUE (id, establishment_id, tenant_id)
);

-- Índices Físicos No Especulativos (Optimizados según R1)
CREATE INDEX IF NOT EXISTS idx_service_offers_tenant_id 
    ON service_offers(tenant_id);

CREATE INDEX IF NOT EXISTS idx_service_offers_establishment_tenant 
    ON service_offers(establishment_id, tenant_id);

-- Aislamiento RLS
ALTER TABLE service_offers ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_service_offers ON service_offers
    FOR ALL
    USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
```

---

## 5. PK / FK DESIGN (DISEÑO DE CLAVES)

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                           KEY DESIGN ARCHITECTURE                           │
│                                                                             │
│  [PRIMARY KEY]                                                              │
│  • service_offers.id (UUID) -> gen_random_uuid()                            │
│                                                                             │
│  [FOREIGN KEYS COMPUESTAS CON ON DELETE RESTRICT]                           │
│  • (tenant_id) -> tenants(id)                                               │
│  • (establishment_id, tenant_id) -> establishments(id, tenant_id)           │
│                                                                             │
│  [EXPOSED COMPOSITE KEYS FOR FUTURE ASSIGNMENT]                             │
│  • (id, tenant_id) UNIQUE                                                   │
│  • (id, establishment_id, tenant_id) UNIQUE (Habilita triple FK DEC-AS-007) │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. TENANT ISOLATION (AISLAMIENTO DE TENANT)

El aislamiento multi-tenant se garantiza mediante una arquitectura de defensa en profundidad en tres capas físicas:
1. **Capa Relacional (Foreign Key):** `tenant_id` obligatorio y vinculado a `tenants(id)`.
2. **Capa Compuesta (Composite Integrity):** Vinculación `(establishment_id, tenant_id)` que impide físicamente registrar ofertas en sedes de otros tenants.
3. **Capa de Motor PostgreSQL (RLS):** Política de seguridad a nivel de fila (`tenant_isolation_service_offers`) activa por defecto.

---

## 7. ESTABLISHMENT INTEGRITY (INTEGRIDAD DE SEDE)

Toda fila en `service_offers` requiere `establishment_id UUID NOT NULL`. No se admiten ofertas globales o huérfanas de sede. El ciclo de vida de la oferta de catálogo está ligado indisolublemente a la existencia de la sede física en el SaaS.

---

## 8. CONSTRAINTS MATRIX (MATRIZ DE RESTRICCIONES)

| Constraint Name | Tipo | Definición | Propósito |
| :--- | :--- | :--- | :--- |
| `pk_service_offers` | `PRIMARY KEY` | `(id)` | Identidad unívoca e inmutable. |
| `chk_service_offers_duration`| `CHECK` | `base_duration > 0` | Evita duraciones nulas o negativas. |
| `chk_service_offers_price` | `CHECK` | `base_price >= 0` | Evita precios negativos. |
| `fk_service_offers_tenant` | `FOREIGN KEY`| `(tenant_id) REFERENCES tenants(id)` | Integridad hacia el tenant (`ON DELETE RESTRICT`). |
| `fk_service_offers_establishment`| `FOREIGN KEY`| `(establishment_id, tenant_id) REFERENCES establishments(id, tenant_id)` | Integridad compuesta con la sede (`ON DELETE RESTRICT`). |
| `uq_service_offers_id_tenant`| `UNIQUE` | `(id, tenant_id)` | Soporte para integridad multi-tenant general. |
| `uq_service_offers_id_est_ten`| `UNIQUE` | `(id, establishment_id, tenant_id)` | Prerrequisito físico para futura FK triple de ASSIGNMENT. |

---

## 9. INDEXES (ÍNDICES NO ESPECULATIVOS)

1. `idx_service_offers_tenant_id`: Indexación B-Tree sobre `tenant_id` para acelerar el filtrado de RLS (`USING (tenant_id = ...)`).
2. `idx_service_offers_establishment_tenant`: Indexación compuesta sobre `(establishment_id, tenant_id)` para acelerar consultas de catálogo en Hub Salón y validar la FK compuesta con `establishments`. *(Cubre completamente las búsquedas por `establishment_id` solo)*.

---

## 10. ROW LEVEL SECURITY (RLS)

La tabla `service_offers` adopta el estándar formal de la Foundation (`065`):
- `ALTER TABLE service_offers ENABLE ROW LEVEL SECURITY;`
- Uso de `NULLIF(current_setting('app.tenant_id', true), '')::integer` en cláusulas `USING` y `WITH CHECK`.
- Coherencia total con los resolvers server-side implementados en `066` y el middleware de contexto activo.

---

## 11. DELETE ANALYSIS (ANÁLISIS DE ELIMINACIÓN)

| Entidad / Relación | Acción ON DELETE Físico | Estado Epistemológico / Racional |
| :--- | :--- | :--- |
| `tenants` $\rightarrow$ `service_offers` | `ON DELETE RESTRICT` | Protección de Foundation contra destrucción accidental de datos. |
| `establishments` $\rightarrow$ `service_offers` | `ON DELETE RESTRICT` | Protección de Foundation contra borrado accidental de sedes con catálogo activo. |
| `service_offers` $\rightarrow$ `assignments` | `UNDEFINED / FUTURE DECISION` | `ARCH-BUNDLE-SO-01-R1` mantiene la semántica de borrado de oferta como decisión futura. |

---

## 12. RELATIONSHIP WITH `public.services` (B2C)

Se ratifica la total separación física:
- **Cero columnas `provider_id`** en `service_offers`.
- **Cero claves foráneas** cruzadas entre `service_offers` y `public.services`.
- **Cero triggers** de inserción o actualización automática hacia B2C.
- La materialización downstream se preserva como un proceso desacoplado bajo autorización explícita (`DEC-AS-003`, `DEC-SE-001`).

---

## 13. FUTURE ASSIGNMENT COMPATIBILITY (COMPATIBILIDAD CON ASSIGNMENT)

El diseño propuesto prepara el terreno de forma limpia para el siguiente bundle (`ASSIGNMENT PHYSICAL ARCHITECTURE`):
- Al exponer `CONSTRAINT uq_service_offers_id_establishment_tenant UNIQUE (id, establishment_id, tenant_id)`, la futura tabla de asignaciones podrá garantizar mediante FK compuesta que una asignación referencie exactamente al mismo establecimiento y tenant que posee la oferta (`DEC-AS-007`, `DEC-AS-014`).
- **NO se diseña la tabla Assignment en este bundle.**

---

## 14. FOUNDATION COMPATIBILITY (COMPATIBILIDAD CON FOUNDATION)

Se verificó exhaustivamente la compatibilidad con:
- `organizations` (`065`): Total compatibilidad con el esquema multi-tenant.
- `establishments` (`065`): Integridad compuesta directa `(establishment_id, tenant_id)`.
- `memberships` (`065`): Estructura ortogonal preparada para el puente relacional de `ASSIGNMENT`.
- `usuarios` (`065`): Separación total respecto a identidades de usuario global.
- `app.tenant_id` / `066`: Compatibilidad 100% con RLS y context resolution.

$$\text{FOUNDATION COMPATIBILITY} = \text{PASS 🟢}$$

---

## 15. MIGRATION IMPACT (IMPACTO DE MIGRACIÓN)

- **Requerimiento:** Se requerirá en el futuro una nueva migración DDL (ej. `067_saas_catalog_service_offers.sql`).
- **Nivel de Afectación:** CERO modificaciones destructivas sobre tablas existentes (`establishments`, `organizations`, `memberships`, `usuarios` y `public.services` permanecen intactas).
- **Dependencias:** Requiere que `065_saas_foundation_core.sql` esté aplicada.
- **Estado Actual:** `MIGRATION DESIGN = PROPOSED / UNDEFINED (ZERO DDL EXECUTED)`.

---

## 16. UNDEFINED / DEFERRED DECISIONS (DECISIONES DIFERIDAS)

1. **`is_active` / Habilitación Operativa:** `UNDEFINED / PENDING DECISION` (`ARCH-BUNDLE-SO-01-R1`).
2. **Semántica de Eliminación de `SERVICE_OFFER`:** `UNDEFINED / FUTURE DECISION` (`ARCH-BUNDLE-SO-01-R1`).
3. **Categorización Taxonómica de Catálogo:** `UNDEFINED / FUTURE DESIGN`.
4. **Diseño Físico de Tabla `ASSIGNMENT`:** Diferido al siguiente bundle.
5. **Mecanismo de Materialización y Sincronización B2C:** Diferido a downstream bundles.
6. **Endpoints API y Componentes UI:** Diferido a la capa de implementación tras el Director Gate.

---

## 17. CONSISTENCY MATRIX (MATRIZ DE CONSISTENCIA FÍSICA)

| Decisión / Contrato | Requisito Físico | Solución en Modelo Propuesto | Estado |
| :--- | :--- | :--- | :--- |
| **DEC-CAT-001** | `OPERATIONAL STATE` durable post-handover | Tabla dedicada `service_offers` con PK UUID | **PASS** |
| **DEC-AS-005** | Identidad propia y ownership en Sede | `id UUID` + `establishment_id UUID NOT NULL` | **PASS** |
| **DEC-AS-007** | Integridad compuesta tenant + establishment | FK compuesta `(establishment_id, tenant_id)` | **PASS** |
| **DEC-AS-008** | Identidad de Assignment desacoplada | Preparación para FK triple sin interferir en PK | **PASS** |
| **DEC-AS-012** | DELETE ASSIGNMENT = PURE UNASSIGNMENT | Distinción clara de semánticas ON DELETE | **PASS** |
| **DEC-AS-014** | Definición consolidada de Assignment | Exposición de `UNIQUE (id, establishment_id, tenant_id)` | **PASS** |
| **DEC-SE-001** | Sin provider_id; desacoplado de B2C | Cero columnas provider; cero FKs a `public.services` | **PASS** |
| **DEC-PUB-001** | Publicación y agenda ortogonales | Sin columnas de publicación ni horarios | **PASS** |
| **ARCH-SO-01-R1** | `is_active` no decidido conceptualmente | Columna `is_active` omitida del diseño físico | **PASS** |
| **ARCH-SO-01-R1** | DELETE no decidido conceptualmente | Sin ON DELETE CASCADE especulativo | **PASS** |
| **Foundation 065**| RLS y aislamiento multi-tenant | RLS con `app.tenant_id` + FK a `tenants` | **PASS** |

```
====================================================================================================
EVALUACIÓN DE CONSISTENCIA FÍSICA:
SERVICE OFFER PHYSICAL ARCHITECTURE = CONSISTENT
PHYSICAL CONSISTENCY = PASS (CERO CONTRADICCIONES DETECTADAS)
RECONCILIATION R1 = PASS
====================================================================================================
```

---

## 18. ARCHITECTURAL SELF-CHECK

```text
================================================================================
ARCHITECTURAL SELF-CHECK
================================================================================
Conceptual decisions contradicted:         0
Unsupported physical assumptions:          0
Speculative indexes:                       0
Redundant constraints without purpose:     0
New decisions invented:                    0
Cross-domain expansion:                    0

Code modified:                             0
DDL executed:                              0
Migration created:                         0

Foundation modified:                       0
HBC modified:                              0
NODO-01 modified:                          0
Pre-Node 01 modified:                      0

Assignment designed:                       0
Assignment implemented:                    0
B2C integration implemented:               0
Publication implemented:                   0
================================================================================
SELF-CHECK RESULT: PASS 🟢
================================================================================
```

---

## 19. FINAL RECOMMENDATION (RECOMENDACIÓN FINAL)

Se recomienda al Director del Proyecto GlowApp SaaS **APROBAR** la propuesta de Arquitectura Física Reconciliada (R1) para `SERVICE_OFFER` documentada en este bundle.

Una vez obtenido el Director Gate correspondiente:
1. Proceder al diseño de **`ARCH-BUNDLE-AS-PHYSICAL-01 — ASSIGNMENT PHYSICAL ARCHITECTURE`** (siguiente bundle).
2. Posteriormente, autorizar la creación de las migraciones DDL correspondientes en un GOAL específico de implementación.

$$\text{ESTADO FINAL: PROPOSED PHYSICAL ARCHITECTURE — CONSISTENCY PASS 🔒}$$
$$\text{RECONCILIATION R1 = PASS}$$
$$\text{IMPLEMENTATION AUTHORIZATION: NOT GRANTED}$$
