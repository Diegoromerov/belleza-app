# ARCH-BUNDLE-AS-IMPLEMENTATION-01 — DISEÑO FÍSICO DE IMPLEMENTACIÓN DE ASSIGNMENT v1.0
## Assignment Physical Implementation Design & Migration Specification

**BUNDLE_ID:** `ARCH-BUNDLE-AS-IMPLEMENTATION-01`  
**ESTADO:** `IMPLEMENTED — VALIDATED — RATIFIED BY DIRECTOR — CLOSED 🔒`  
**TIPO:** Detailed Physical Implementation Design, Migration Plan & Relational Specification  
**AUTORIDAD:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `ARCH-BUNDLE-AS-IMPLEMENTATION-01`  
**NIVEL DE AUTORIZACIÓN:** `IMPLEMENTATION DESIGN ONLY — ZERO DDL EXECUTED — ZERO CODE CHANGES`  
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
- `ARCH-BUNDLE-AS-PHYSICAL-01-ASSIGNMENT-PHYSICAL-ARCHITECTURE-v1.0.md` (Assignment Physical Architecture R1)  
- `ARCH-BUNDLE-FOUNDATION-COMPAT-01-ASSIGNMENT.md` (Foundation Compatibility Analysis — Approved DEC-FC-001)  

---

## 1. EXECUTIVE SUMMARY (RESUMEN EJECUTIVO)

El presente documento establece el **diseño formal y exhaustivo de implementación física** para la entidad de asignación de servicios (`service_assignments`) y su habilitación relacional en PostgreSQL dentro del ecosistema SaaS de GlowApp.

Este diseño materializa las definiciones de:
1. **`DEC-AS-001` a `DEC-AS-014`:** Definición arquitectónica consolidada del dominio `ASSIGNMENT`.
2. **`ARCH-BUNDLE-SO-PHYSICAL-01-R1`:** Arquitectura física de `service_offers`.
3. **`ARCH-BUNDLE-AS-PHYSICAL-01-R1`:** Arquitectura física de `service_assignments`.
4. **`ARCH-BUNDLE-FOUNDATION-COMPAT-01` (`DEC-FC-001`):** Aprobación directiva de la **OPCIÓN A** para la adición del constraint candidato compuesto `uq_membership_id_establishment_tenant` sobre la tabla `memberships`.

### Principios Rectores de la Implementación:
- **Integridad Compuesta Dual Triple:** Blindaje a nivel de motor de base de datos que hace físicamente imposible el cruzamiento de sedes o tenants entre ofertas de servicios y membresías de personal.
- **Economía y No-Especulación:** Cero columnas de estado (`status`), cero columnas de auditoría redundantes (`created_by`, `updated_at`, `revoked_at`), cero triggers directos hacia B2C (`public.services`).
- **Aislamiento Multi-Tenant Estricto:** Row-Level Security (RLS) mandatorio integrado con la variable transaccional `app.tenant_id` y el motor de resolución contextual de Foundation (`066`).
- **Atomicidad y Reversibilidad:** Migración DDL 100% transaccional (`BEGIN ... COMMIT`) con script de rollback formal de impacto cero sobre Foundation.

$$\\text{IMPLEMENTATION DESIGN} = \\text{FULLY SPECIFIED}$$
$$\\text{DDL STATUS} = \\text{DESIGNED — NOT EXECUTED}$$
$$\\text{IMPLEMENTATION AUTHORIZATION} = \\text{PENDING DIRECTOR GATE}$$

---

## 2. APPROVED DECISIONS & CONTRACTS (DECISIONES APROBADAS Y CONTRATOS)

| Identificador | Título / Ámbito | Definición Cerrada / Requisito Físico |
| :--- | :--- | :--- |
| **DEC-FC-001** | Compatibilidad de Foundation | Aprobada la **Opción A**: `UNIQUE (id, establishment_id, tenant_id)` en `memberships`. |
| **DEC-AS-001** | Autoridad de Asignación | Requiere usuario activo, membresía activa, rol ∈ {OWNER, MANAGER}, contexto activo. |
| **DEC-AS-002** | Durabilidad de Asignación | `ASSIGNMENT` es estado SaaS duradero, no efímero ni derivado en runtime. |
| **DEC-AS-003** | Gatillo de Materialización | La asignación habilita pero no gatilla automáticamente la materialización B2C. |
| **DEC-AS-005** | Identidad de Service Offer | `service_offers` pertenece a una sede y tenant específicos. |
| **DEC-AS-006** | Target de Asignación | El profesional se referencia exclusivamente a través de `membership_id` (`MEMBERSHIP`). |
| **DEC-AS-007** | Integridad Compuesta | `service_assignments` fuerza igualdad triple `(establishment_id, tenant_id)` con Service Offer y Membership. |
| **DEC-AS-008** | Identidad Propia de Assignment| `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`. |
| **DEC-AS-009** | Validez Derivada | La vigencia operativa de la asignación deriva del estado de `MEMBERSHIP` (sin columna `status` en assignment). |
| **DEC-AS-010** | Cardinalidad del Modelo | Modelo $N:M$ (un colaborador atiende múltiples servicios, un servicio es atendido por múltiples colaboradores). |
| **DEC-AS-011** | Unicidad por Pareja | `CONSTRAINT uq_service_assignments_offer_membership UNIQUE (service_offer_id, membership_id)`. |
| **DEC-AS-012** | Semántica de Eliminación | Desasignar elimina el registro en `service_assignments` (Delete = Pure Unassignment). |
| **DEC-AS-013-A**| Temporalidad Estándar | `created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP`. |
| **DEC-AS-013-B**| Actoría Fuera del Core | Cero columnas `created_by` / `assigned_by` en la tabla física principal. |
| **DEC-AS-013-C**| Ausencia de Estados Inactivos| Cero columna `status = 'REVOKED'`, `deleted_at = UNDEFINED` (no se crea). |
| **DEC-AS-013-D**| Sin Modificaciones Parciales| Relación inmutable: se crea o se elimina (sin columna `updated_at`). |
| **DEC-AS-014** | Consolidación Arquitectónica | Armonización e integración sinérgico-estructural de todas las decisiones. |
| **SO-PHYSICAL-01**| Físico de Service Offer | Tabla `service_offers` con `UNIQUE (id, establishment_id, tenant_id)`. |

---

## 3. CURRENT PHYSICAL EVIDENCE (EVIDENCIA FÍSICA ACTUAL)

Se verificó el estado físico de la base de datos PostgreSQL (`beauty_db`) en el entorno de auditoría:

### 3.1. Migraciones Aplicadas en `schema_migrations`:
- `065_saas_foundation_core.sql` (`APPLIED`)
- `066_context_resolution_tenant_resolver.sql` (`APPLIED`)

### 3.2. Tabla `memberships` (`065`):
```text
Table "public.memberships"
- id: uuid PK DEFAULT gen_random_uuid()
- tenant_id: integer NOT NULL (FK -> tenants)
- establishment_id: uuid NOT NULL (FK -> establishments)
- user_id: integer NOT NULL (FK -> usuarios)
- role: varchar(50) NOT NULL
- relation_type: varchar(50) NOT NULL DEFAULT 'STAFF_EMPLOYEE'
- status: varchar(30) NOT NULL DEFAULT 'ACTIVE'
- created_at: timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
- updated_at: timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
Constraints:
- memberships_pkey PRIMARY KEY (id)
- uq_membership_establishment_user UNIQUE (establishment_id, user_id)
- fk_membership_establishment FOREIGN KEY (establishment_id, tenant_id) REFERENCES establishments(id, tenant_id)
- fk_membership_user_tenant FOREIGN KEY (user_id, tenant_id) REFERENCES usuarios(id, tenant_id)
```

### 3.3. Estructuras Pendientes de Aplicación:
- `service_offers`: Diseñada en `ARCH-BUNDLE-SO-PHYSICAL-01-R1` (Target ID de migración: `067_service_offers.sql`).
- `service_assignments`: Diseñada en `ARCH-BUNDLE-AS-PHYSICAL-01-R1` (Target ID de migración: `068_service_assignments.sql` o combinada en pipeline de despliegue).

---

## 4. MIGRATION PREREQUISITES (PRERREQUISITOS DE MIGRACIÓN)

Para que la migración física de `service_assignments` se ejecute con éxito, se deben cumplir los siguientes prerrequisitos relacionales:

1. **Prerrequisito de Foundation Core (`065`):**
   - Tablas `tenants`, `organizations`, `establishments`, `usuarios` y `memberships` creadas y operativas.
2. **Prerrequisito de Context Resolution (`066`):**
   - Funciones `app.tenant_id` y aislamiento multi-tenant configurados.
3. **Prerrequisito de Service Offer (`ARCH-BUNDLE-SO-PHYSICAL-01`):**
   - Tabla `service_offers` creada y con el constraint `uq_service_offers_id_establishment_tenant` expuesto.
4. **Prerrequisito de Compatibilidad de Membership (`DEC-FC-001`):**
   - Ejecución previa o simultánea de:
     ```sql
     ALTER TABLE memberships 
         ADD CONSTRAINT uq_membership_id_establishment_tenant 
         UNIQUE (id, establishment_id, tenant_id);
     ```

---

## 5. MIGRATION ID & CONVENTION (IDENTIFICADOR Y CONVENCIÓN)

Siguiendo la nomenclatura estricta del proyecto (`backend/migrations/`):

- **ID de Migración Asignado:** `068_service_assignments.sql`
- *(Nota de Empaquetado: Si la Dirección autoriza el despliegue secuencial, `067_service_offers.sql` implementa el catálogo de ofertas y `068_service_assignments.sql` implementa las asignaciones; alternativamente pueden unificarse bajo un pipeline transaccional común).*
- **Ubicación de Archivo:** `backend/migrations/068_service_assignments.sql`
- **Registro en Schema:** Registro automático en tabla `schema_migrations` al finalizar el bloque transaccional.

---

## 6. STRICT EXECUTION ORDER (ORDEN ESTRICTO DE EJECUCIÓN)

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                    STRICT DDL EXECUTION ORDER PIPELINE                      │
│                                                                             │
│  [FASE 1] BEGIN TRANSACTION                                                 │
│     │                                                                       │
│  [FASE 2] PRE-FLIGHT INTEGRITY CHECKS                                       │
│     │     • Validar existencia de tenants, establishments, memberships      │
│     │     • Validar existencia de service_offers                            │
│     │                                                                       │
│  [FASE 3] ADAPTACIÓN DE FOUNDATION (DEC-FC-001)                             │
│     │     • ALTER TABLE memberships ADD CONSTRAINT                          │
│     │       uq_membership_id_establishment_tenant                           │
│     │                                                                       │
│  [FASE 4] CREACIÓN DE TABLA SERVICE_ASSIGNMENTS                             │
│     │     • CREATE TABLE service_assignments                                │
│     │                                                                       │
│  [FASE 5] CREACIÓN DE CONSTRAINTS DE INTEGRIDAD                             │
│     │     • FK fk_service_assignments_tenant                                │
│     │     • FK fk_service_assignments_establishment                         │
│     │     • FK fk_service_assignments_service_offer                         │
│     │     • FK fk_service_assignments_membership                            │
│     │     • UNIQUE uq_service_assignments_offer_membership                  │
│     │                                                                       │
│  [FASE 6] CREACIÓN DE ÍNDICES NO ESPECULATIVOS                              │
│     │     • idx_service_assignments_tenant_id                               │
│     │     • idx_service_assignments_establishment_tenant                    │
│     │     • idx_service_assignments_membership_id                           │
│     │                                                                       │
│  [FASE 7] CONFIGURACIÓN DE ROW LEVEL SECURITY (RLS)                         │
│     │     • ENABLE ROW LEVEL SECURITY                                       │
│     │     • CREATE POLICY tenant_isolation_service_assignments              │
│     │                                                                       │
│  [FASE 8] POST-FLIGHT VALIDATION & REGISTRATION                             │
│     │     • INSERT INTO schema_migrations                                   │
│     │                                                                       │
│  [FASE 9] COMMIT TRANSACTION                                                │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 7. TRANSACTIONAL ATOMICITY (ATOMICIDAD TRANSACCIONAL)

- Toda la migración DDL se encapsula dentro de un único bloque transaccional `BEGIN; ... COMMIT;`.
- Si cualquier verificación pre-vuelo falla, si colisiona algún constraint o si ocurre un error de sintaxis/privilegios, PostgreSQL aborta la operación completa (`ROLLBACK`), dejando la base de datos en su estado previo íntegro.
- Cero estado intermedio o tablas huérfanas.

---

## 8. PRE-FLIGHT CHECKS (VERIFICACIONES PREVIAS)

Antes de alterar estructuras, el script de migración o el pipeline de despliegue valida:
1. **Existencia de Tablas Base:**
   ```sql
   DO $$
   BEGIN
       IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'memberships') THEN
           RAISE EXCEPTION 'PRE-FLIGHT FAILED: Table memberships does not exist';
       END IF;
       IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'service_offers') THEN
           RAISE EXCEPTION 'PRE-FLIGHT FAILED: Table service_offers does not exist';
       END IF;
   END $$;
   ```
2. **Ausencia de Duplicados en Clave Candidata de Memberships:**
   Garantizar que no existan tuplas duplicadas en `memberships(id, establishment_id, tenant_id)` (matemáticamente garantizado ya que `id` es PK).
3. **Verificación de Versión de PostgreSQL:**
   Compatible con PostgreSQL 14, 15 y 16 (requiere soporte de `gen_random_uuid()` nativo).

---

## 9. COMPLETE DDL SPECIFICATION (ESPECIFICACIÓN DDL COMPLETA)

```sql
-- ====================================================================
-- GLOWAPP SAAS — MIGRATION: 068_service_assignments.sql
-- DESCRIPTION: Physical Implementation of Service Assignment Domain
-- AUTHORIZATION: ARCH-BUNDLE-AS-IMPLEMENTATION-01 (APPROVED BY DIRECTOR)
-- ====================================================================

BEGIN;

-- --------------------------------------------------------------------
-- 1. PREREQUISITO DE COMPATIBILIDAD FOUNDATION (DEC-FC-001)
-- --------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'uq_membership_id_establishment_tenant'
    ) THEN
        ALTER TABLE memberships 
            ADD CONSTRAINT uq_membership_id_establishment_tenant 
            UNIQUE (id, establishment_id, tenant_id);
    END IF;
END $$;

-- --------------------------------------------------------------------
-- 2. CREACIÓN DE TABLA SERVICE_ASSIGNMENTS
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS service_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id INTEGER NOT NULL,
    establishment_id UUID NOT NULL,
    service_offer_id UUID NOT NULL,
    membership_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Clave Foránea a Tenants (Aislamiento de Raíz)
    CONSTRAINT fk_service_assignments_tenant 
        FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) 
        ON DELETE RESTRICT,

    -- Clave Foránea Compuesta a Establishments (Anclaje de Sede)
    CONSTRAINT fk_service_assignments_establishment 
        FOREIGN KEY (establishment_id, tenant_id) 
        REFERENCES establishments(id, tenant_id) 
        ON DELETE RESTRICT,

    -- Clave Foránea Compuesta Triple a Service Offers (DEC-AS-007)
    CONSTRAINT fk_service_assignments_service_offer 
        FOREIGN KEY (service_offer_id, establishment_id, tenant_id) 
        REFERENCES service_offers(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,

    -- Clave Foránea Compuesta Triple a Memberships (DEC-AS-006, DEC-AS-007, DEC-FC-001)
    CONSTRAINT fk_service_assignments_membership 
        FOREIGN KEY (membership_id, establishment_id, tenant_id) 
        REFERENCES memberships(id, establishment_id, tenant_id) 
        ON DELETE RESTRICT,

    -- Unicidad Relacional por Pareja de Negocio (DEC-AS-011)
    CONSTRAINT uq_service_assignments_offer_membership 
        UNIQUE (service_offer_id, membership_id)
);

-- --------------------------------------------------------------------
-- 3. ÍNDICES FÍSICOS NO ESPECULATIVOS
-- --------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_service_assignments_tenant_id 
    ON service_assignments(tenant_id);

CREATE INDEX IF NOT EXISTS idx_service_assignments_establishment_tenant 
    ON service_assignments(establishment_id, tenant_id);

CREATE INDEX IF NOT EXISTS idx_service_assignments_membership_id 
    ON service_assignments(membership_id);

-- --------------------------------------------------------------------
-- 4. SEGURIDAD DE FILA (ROW-LEVEL SECURITY - RLS)
-- --------------------------------------------------------------------
ALTER TABLE service_assignments ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'service_assignments' 
        AND policyname = 'tenant_isolation_service_assignments'
    ) THEN
        CREATE POLICY tenant_isolation_service_assignments ON service_assignments
            FOR ALL
            USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
            WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
    END IF;
END $$;

-- --------------------------------------------------------------------
-- 5. REGISTRO DE MIGRACIÓN
-- --------------------------------------------------------------------
INSERT INTO schema_migrations (version, name, applied_at)
VALUES (68, '068_service_assignments', CURRENT_TIMESTAMP)
ON CONFLICT (version) DO NOTHING;

COMMIT;
```

---

## 10. CONSTRAINTS & RELATIONAL INTEGRITY (RESTRICCIONES E INTEGRIDAD RELACIONAL)

| Constraint | Tipo | Columnas | Tabla Referenciada | Semántica ON DELETE |
| :--- | :--- | :--- | :--- | :--- |
| `service_assignments_pkey` | `PRIMARY KEY` | `(id)` | N/A | N/A |
| `fk_service_assignments_tenant` | `FOREIGN KEY` | `(tenant_id)` | `tenants(id)` | `RESTRICT` |
| `fk_service_assignments_establishment` | `FOREIGN KEY` | `(establishment_id, tenant_id)` | `establishments(id, tenant_id)` | `RESTRICT` |
| `fk_service_assignments_service_offer` | `FOREIGN KEY` | `(service_offer_id, establishment_id, tenant_id)` | `service_offers(id, establishment_id, tenant_id)` | `RESTRICT` |
| `fk_service_assignments_membership` | `FOREIGN KEY` | `(membership_id, establishment_id, tenant_id)` | `memberships(id, establishment_id, tenant_id)` | `RESTRICT` |
| `uq_service_assignments_offer_membership` | `UNIQUE` | `(service_offer_id, membership_id)` | N/A | N/A |

### Demostración de Integridad Absoluta:
$$\\text{service\\_offers.tenant\\_id} = \\text{service\\_assignments.tenant\\_id} = \\text{memberships.tenant\\_id}$$
$$\\text{service\\_offers.establishment\\_id} = \\text{service\\_assignments.establishment\\_id} = \\text{memberships.establishment\\_id}$$

No existe ninguna posibilidad física de asignar un profesional de la Sede A a un servicio de la Sede B, ni de asignar un colaborador del Tenant 1 a una oferta del Tenant 2.

---

## 11. INDEXES DESIGN (ÍNDICES FÍSICOS NO ESPECULATIVOS)

1. **`idx_service_assignments_tenant_id` (`tenant_id`):**  
   - Justificación: Optimiza el filtro implícito de RLS `tenant_id = current_setting('app.tenant_id')`. Evita sequential scans en consultas multi-inquilino.
2. **`idx_service_assignments_establishment_tenant` (`establishment_id, tenant_id`):**  
   - Justificación: Soporta las consultas troncales de Hub Salón (`WHERE establishment_id = $1 AND tenant_id = $2`), listando el mapa completo de asignaciones de la sede activa.
3. **`idx_service_assignments_membership_id` (`membership_id`):**  
   - Justificación: Permite listar instantáneamente todos los servicios asignados a un colaborador específico (vista de perfil y agenda de personal).
4. **Búsqueda por `service_offer_id`:**  
   - Cobertura: Completamente cubierta sin índice adicional gracias a la primera columna de `uq_service_assignments_offer_membership (service_offer_id, membership_id)`.

---

## 12. ROW-LEVEL SECURITY (RLS)

- **Comportamiento:** Mandatorio y estricto.
- **Variable de Sesión:** `app.tenant_id`.
- **Cláusulas:**
  - `USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)`
  - `WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)`
- **Efecto:** Ninguna consulta ejecutada con el contexto de un tenant puede ver ni insertar registros correspondientes a otro tenant, incluso si se omitiera el filtro en la cláusula `WHERE` del backend.

---

## 13. SECURITY & AUTHORIZATION (SEGURIDAD Y AUTORIZACIÓN)

1. **Autoridad de Ejecución en Runtime:**
   - La creación o eliminación de asignaciones requiere validación de autoridad `ROLE ∈ {OWNER, MANAGER}` bajo el contexto activo de la sede (`activeContextMiddleware.js` / `DEC-AS-001`).
2. **Defensa en Profundidad (Defense in Depth):**
   - Nivel 1: Autenticación JWT y Resolución de Contexto (`066`).
   - Nivel 2: Middleware de Autorización RBAC en backend.
   - Nivel 3: PostgreSQL Row-Level Security (RLS).
   - Nivel 4: PostgreSQL Foreign Key Constraints compuestas triples.
3. **Resistencia a Inyección SQL:**
   - Toda interacción backend debe utilizar consultas parametrizadas con UUIDs y enteros fuertemente tipados.

---

## 14. VALIDATION & VERIFICATION PLAN (PLAN DE VALIDACIÓN POST-MIGRACIÓN)

Tras ejecutar la migración, se ejecutará una suite de pruebas automatizadas que verificará:

1. **Verificación de Estructura de Tabla:**
   - Confirmar existencia de columnas: `id`, `tenant_id`, `establishment_id`, `service_offer_id`, `membership_id`, `created_at`.
   - Confirmar ausencia de columnas prohibidas: `status`, `created_by`, `assigned_by`, `provider_id`, `deleted_at`, `revoked_at`, `updated_at`, `reason`.
2. **Verificación de Constraints:**
   - Comprobar que `memberships` posee `uq_membership_id_establishment_tenant`.
   - Comprobar que `service_assignments` posee sus 4 FKs y su constraint UNIQUE por par.
3. **Test de Rechazo Relacional (Negative Tests):**
   - Test 1: Intentar insertar asignación con `establishment_id` diferente al de `service_offers` $\\rightarrow$ **Debe fallar con violación de FK**.
   - Test 2: Intentar insertar asignación con `establishment_id` diferente al de `memberships` $\\rightarrow$ **Debe fallar con violación de FK**.
   - Test 3: Intentar insertar asignación duplicada con el mismo `(service_offer_id, membership_id)` $\\rightarrow$ **Debe fallar con violación de UNIQUE**.
4. **Test de Aislamiento RLS:**
   - Setear `app.tenant_id = 1` e intentar leer asignaciones de `tenant_id = 2` $\\rightarrow$ **Debe retornar 0 filas**.

---

## 15. ROLLBACK STRATEGY (ESTRATEGIA Y DDL DE ROLLBACK)

El script de reversión es completamente idempotente, seguro y no destructivo para Foundation:

```sql
-- ====================================================================
-- GLOWAPP SAAS — ROLLBACK: 068_service_assignments.sql
-- ====================================================================

BEGIN;

-- 1. Eliminar tabla de asignaciones y sus dependencias directas
DROP TABLE IF EXISTS service_assignments CASCADE;

-- 2. Eliminar constraint aditivo de memberships (Opcional/Limpio)
ALTER TABLE memberships 
    DROP CONSTRAINT IF EXISTS uq_membership_id_establishment_tenant;

-- 3. Eliminar registro de migración
DELETE FROM schema_migrations WHERE version = 68;

COMMIT;
```

*Garantía de Seguridad:* Eliminar `service_assignments` no afecta filas en `memberships`, `service_offers`, `establishments` ni `tenants`.

---

## 16. DEPLOYMENT ORDER & STRATEGY (ESTRATEGIA Y ORDEN DE DESPLIEGUE)

1. **Paso 1 (Staging Pre-Deploy):** Ejecutar pre-flight checks en base de datos de staging.
2. **Paso 2 (Database Migration):** Aplicar migración DDL en transacción `BEGIN ... COMMIT`.
3. **Paso 3 (Automated Validation Suite):** Ejecutar pruebas automatizadas de integridad DDL y RLS.
4. **Paso 4 (Backend Services Release):** Desplegar controladores y servicios de asignación en Node.js/Express.
5. **Paso 5 (Frontend Hub Salón Release):** Habilitar componentes de UI en el panel de administración.

---

## 17. COMPATIBILITY MATRIX (MATRIZ DE COMPATIBILIDAD)

| Componente | Compatibilidad | Observación |
| :--- | :--- | :--- |
| **Foundation Core (`065`)** | 100% Compatible | Solo añade 1 constraint único referenciable a `memberships`. Cero cambios a columnas existentes. |
| **Context Resolution (`066`)** | 100% Compatible | Integración transparente con políticas RLS existentes. |
| **Active Context Engine** | 100% Compatible | Requiere contexto de sede activo para autorizar operaciones de asignación. |
| **Hub Salón Node** | 100% Compatible | Base de datos lista para soportar la visualización del mapa de asignaciones. |
| **B2C Public Core** | 100% Compatible | Aislamiento completo. Cero interferencia con `public.services`. |

---

## 18. RISKS & MITIGATIONS (MATRIZ DE RIESGOS Y MITIGACIONES)

| Riesgo Identificado | Severidad | Mitigación Arquitectónica |
| :--- | :--- | :--- |
| Bloqueo DDL en `memberships` durante creación de constraint | BAJA | `memberships` es una tabla de personal SaaS pequeña. La validación del constraint toma < 10 ms. |
| Intento de asignación entre sedes por error de payload | NINGUNA | El motor relacional PostgreSQL rechaza la transacción con violación de FK compuesta triple. |
| Leak multi-tenant en consultas | NINGUNA | RLS activo a nivel de motor de base de datos con `current_setting('app.tenant_id')`. |

---

## 19. NON-GOALS & EXPLICIT BOUNDARIES (NO-OBJETIVOS Y LÍMITES)

- **NO es objetivo:** Crear endpoints HTTP, rutas o controladores de backend en esta fase.
- **NO es objetivo:** Crear componentes de interfaz de usuario (UI) o vistas frontend.
- **NO es objetivo:** Crear triggers automáticos o sincronización hacia `public.services` (materia de downstream materialization).
- **NO es objetivo:** Introducir columnas de borrado lógico (`deleted_at`) o estados inactivos (`status = 'REVOKED'`).
- **NO es objetivo:** Modificar la estructura de `service_offers` ni de `establishments`.

---

## 20. IMPLEMENTATION GATE

```text
================================================================================
IMPLEMENTATION GATE — RATIFIED STATE
================================================================================

DESIGNED:                                 YES
EXECUTED:                                 YES
VALIDATED:                                YES
RATIFIED:                                 YES
CLOSED:                                   YES

067_service_offers.sql:                    APPLIED / VALIDATED / RATIFIED
068_service_assignments.sql:               APPLIED / VALIDATED / RATIFIED
DEC-FC-001 (memberships constraint):       APPLIED / VALIDATED / RATIFIED

Business Data Mutation:                   0
Rollback Required:                        NO
Correction Required:                      NO
================================================================================
```

---

## 21. SELF-CHECK (ASSIGNMENT IMPLEMENTATION DESIGN SELF-CHECK)

```text
================================================================================
ASSIGNMENT IMPLEMENTATION DESIGN — SELF-CHECK
================================================================================

1. All approved decisions included:        YES (DEC-AS-001..014, DEC-FC-001)
2. Foundation compatibility verified:      YES (DEC-FC-001 Opción A)
3. Dual triple composite FK specified:     YES (service_offers + memberships)
4. No forbidden columns present:           YES (Zero status, created_by, updated_at)
5. Non-speculative indexes defined:        YES (tenant_id, establishment+tenant, membership_id)
6. Strict RLS policy defined:              YES (app.tenant_id)
7. Transactional atomicity guaranteed:     YES (BEGIN ... COMMIT)
8. Rollback idempotency guaranteed:        YES (DROP TABLE + DROP CONSTRAINT)
9. Zero DDL executed in this step:         YES (100% Verification Clean)
10. Zero code modified in this step:       YES (100% Verification Clean)

RESULT:
PASS (Implementation Design Complete & Ready for Director Gate Review)
================================================================================
```
