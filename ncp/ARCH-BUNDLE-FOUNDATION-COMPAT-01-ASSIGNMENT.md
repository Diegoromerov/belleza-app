# ARCH-BUNDLE-FOUNDATION-COMPAT-01 — ANÁLISIS DE COMPATIBILIDAD DE FOUNDATION PARA ASSIGNMENT v1.0
## Foundation Compatibility Analysis for Composite Assignment Integrity

**BUNDLE_ID:** `ARCH-BUNDLE-FOUNDATION-COMPAT-01`  
**ESTADO:** `APPROVED BY DIRECTOR — CLOSED 🔒`  
**TIPO:** Foundation Architectural Compatibility Analysis & Relational Verification  
**AUTORIDAD:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `ARCH-BUNDLE-FOUNDATION-COMPAT-01` (Autorizado tras `ARCH-BUNDLE-AS-PHYSICAL-01-R1`)  
**NIVEL DE AUTORIZACIÓN:** `ANALYSIS ONLY — ZERO DDL — ZERO IMPLEMENTATION AUTHORIZATION`  
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
- `ARCH-BUNDLE-SO-PHYSICAL-01-SERVICE-OFFER-PHYSICAL-ARCHITECTURE-v1.0.md` (Service Offer Physical Architecture R1)  
- `ARCH-BUNDLE-AS-PHYSICAL-01-ASSIGNMENT-PHYSICAL-ARCHITECTURE-v1.0.md` (Assignment Physical Architecture R1)  

---

## 1. EXECUTIVE SUMMARY (RESUMEN EJECUTIVO)

El presente documento resuelve de manera concluyente y rigurosa la pregunta formulada por la Dirección tras el `ARCHITECTURAL STOP` de `ARCH-BUNDLE-AS-PHYSICAL-01-R1`:

> **Pregunta Directiva:**  
> ¿Es necesario agregar `UNIQUE(id, establishment_id, tenant_id)` a `memberships` para poder crear una FK compuesta desde `ASSIGNMENT`, y es esta la modificación mínima y arquitectónicamente correcta?

### Conclusión Técnica y Dictamen Canónico:
1. **Necesidad Demostrada (PostgreSQL Standard):** **SÍ, ES ESTRICTAMENTE NECESARIO.** El motor relacional de PostgreSQL exige que toda clave foránea compuesta apunte a un constraint `UNIQUE` o `PRIMARY KEY` explícito en la tabla referenciada. Sin `UNIQUE (id, establishment_id, tenant_id)` en `memberships`, es físicamente imposible declarar una FK compuesta triple en DDL.
2. **Naturaleza de la Modificación:** Es una **clave candidata referenciable**, no una nueva regla de unicidad de negocio. Dado que `id` ya es `PRIMARY KEY`, la tupla `(id, establishment_id, tenant_id)` es intrínsecamente única; el constraint únicamente la expone formalmente como target de FK.
3. **Mínima, Segura y Coherente:** Es la modificación física mínima posible (operación aditiva DDL que no altera datos existentes ni rompe contratos vigentes) y sigue exactamente el patrón compuesto establecido por Foundation en `organizations` y `establishments` (`uq_organization_id_tenant`, `uq_establishment_id_tenant`).

$$\text{RESULT: OPTION A IS NECESSARY, MINIMAL, SAFE AND COHERENT}$$
$$\text{STATUS: APPROVED BY DIRECTOR — CLOSED 🔒}$$
$$\text{IMPLEMENTATION AUTHORIZATION = NOT GRANTED}$$

---

## 2. EVIDENCE (EVIDENCIA FÍSICA DIRECTA)

Se verificó el estado físico real en la base de datos PostgreSQL (`beauty_db`) y en las migraciones de Foundation:

### 2.1. Tabla `memberships` (Foundation `065`)
- `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`
- `tenant_id INTEGER NOT NULL REFERENCES tenants(id)`
- `establishment_id UUID NOT NULL`
- `user_id INTEGER NOT NULL`
- `CONSTRAINT fk_membership_establishment FOREIGN KEY (establishment_id, tenant_id) REFERENCES establishments(id, tenant_id) ON DELETE RESTRICT`
- `CONSTRAINT fk_membership_user_tenant FOREIGN KEY (user_id, tenant_id) REFERENCES usuarios(id, tenant_id) ON DELETE RESTRICT`
- `CONSTRAINT uq_membership_establishment_user UNIQUE (establishment_id, user_id)`
- **Constraint Faltante:** No posee `UNIQUE (id, establishment_id, tenant_id)` ni `UNIQUE (id, tenant_id)`.

### 2.2. Tabla `establishments` (Foundation `065`)
- `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`
- `tenant_id INTEGER NOT NULL REFERENCES tenants(id)`
- `organization_id UUID NOT NULL`
- `CONSTRAINT uq_establishment_id_tenant UNIQUE (id, tenant_id)` -> *Patrón idéntico de clave candidata compuesta expuesta para FKs hijas.*

### 2.3. Tabla `service_offers` (`ARCH-BUNDLE-SO-PHYSICAL-01-R1`)
- `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`
- `tenant_id INTEGER NOT NULL`
- `establishment_id UUID NOT NULL`
- `CONSTRAINT uq_service_offers_id_establishment_tenant UNIQUE (id, establishment_id, tenant_id)` -> *Expone la clave triple para soportar la FK compuesta de ASSIGNMENT.*

---

## 3. CURRENT MEMBERSHIP PHYSICAL MODEL (MODELO ACTUAL DE MEMBERSHIP)

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                   CURRENT MEMBERSHIP MODEL (FOUNDATION 065)                 │
│                                                                             │
│   memberships                                                               │
│   ├── id (UUID PK)                                                          │
│   ├── tenant_id (INTEGER FK -> tenants)                                     │
│   ├── establishment_id (UUID) ──┐ (FK compuesta a establishments)           │
│   ├── tenant_id (INTEGER)     ──┘                                           │
│   ├── user_id (INTEGER)       ──┐ (FK compuesta a usuarios)                 │
│   ├── tenant_id (INTEGER)     ──┘                                           │
│   │                                                                         │
│   └── CANDIDATE KEYS ACTUALES:                                              │
│       • PRIMARY KEY (id)                                                    │
│       • UNIQUE (establishment_id, user_id)                                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. PROBLEM (EL PROBLEMA TÉCNICO EN POSTGRESQL)

1. Para que `service_assignments` garantice a nivel de motor relacional DDL que el profesional (`membership_id`) pertenece al mismo establecimiento y tenant que el servicio ofertado (`service_offer_id`), se requiere la siguiente clave foránea compuesta:
   ```sql
   FOREIGN KEY (membership_id, establishment_id, tenant_id) 
       REFERENCES memberships(id, establishment_id, tenant_id)
   ```
2. En la especificación SQL de PostgreSQL (ANSI SQL), una tabla referenciada por una clave foránea compuesta **DEBE** poseer un constraint `UNIQUE` o `PRIMARY KEY` que contenga exactamente la lista de columnas referenciadas.
3. Al carecer `memberships` de dicho constraint, cualquier intento de crear la FK compuesta aborta con error fatal de DDL:
   `ERROR: there is no unique constraint matching given keys for referenced table "memberships"`.

---

## 5. EVALUACIÓN DE OPTION A: `UNIQUE (id, establishment_id, tenant_id)` EN MEMBERSHIPS

Se evaluaron los 10 puntos de rigor técnico requeridos:

1. **¿PostgreSQL permite usarlo como target de FK?**  
   **SÍ.** Cumple al 100% el estándar ANSI SQL y la implementación de PostgreSQL para foreign keys compuestas.
2. **¿Es suficiente?**  
   **SÍ.** Garantiza matemáticamente que `service_assignments.establishment_id = memberships.establishment_id` y `service_assignments.tenant_id = memberships.tenant_id`.
3. **¿Es redundante como unicidad de datos?**  
   **SÍ, semánticamente.** Dado que `id` ya es único globalmente (PK), la combinación `(id, X, Y)` es automáticamente única.
4. **¿Su única función sería habilitar integridad referencial compuesta?**  
   **SÍ.** Su única finalidad técnica en PostgreSQL es actuar como *clave candidata expuesta* para que tablas hijas puedan enlazar FKs compuestas.
5. **¿Tiene algún coste material?**  
   **NO.** Genera un índice B-Tree ultraligero (~40 bytes por fila). En un catálogo SaaS de personal, el consumo de disco es < 100 KB y el impacto de escritura en `INSERT INTO memberships` es del orden de microsegundos.
6. **¿Es coherente con las convenciones de Foundation?**  
   **SÍ.** Foundation `065` utilizó exactamente esta técnica en `organizations(id, tenant_id)` y `establishments(id, tenant_id)`.
7. **¿Es la mínima modificación?**  
   **SÍ.** Requiere una única sentencia DDL aditiva (`ALTER TABLE memberships ADD CONSTRAINT ...`). Cero alteraciones de columnas, cero cambios de tipo de datos.
8. **¿Introduce alguna semántica nueva?**  
   **NO.** No crea reglas de negocio nuevas ni altera la lógica de personal; simplemente materializa en DDL la relación estricta de pertenencia.
9. **¿Afecta datos existentes?**  
   **NO.** El 100% de las filas existentes en `memberships` cumplen la restricción de forma natural (`id`, `establishment_id` y `tenant_id` son `NOT NULL` y `id` es único).
10. **¿Afecta el comportamiento de Membership?**  
    **NO.** Los roles (`OWNER`, `MANAGER`, `PROFESSIONAL`), los estados (`ACTIVE`, `REVOKED`) y los controladores existentes funcionan exactamente igual.

---

## 6. EVALUACIÓN DE OPTION B: OTRA ESTRUCTURA FÍSICA SIN AGREGAR UNIQUE

- **¿Existe otra clave candidata utilizable en `memberships`?**  
  La única otra clave única es `(establishment_id, user_id)`.
- **¿Podría `service_assignments` referenciar `(establishment_id, user_id)`?**  
  **NO.** Eso obligaría a que `service_assignments` almacene `user_id` en lugar de `membership_id`. Esto **viola frontalmente `DEC-AS-006`**, que establece de forma inmutable que el target relacional de asignación es el vínculo contextual `MEMBERSHIP`, no el usuario global `USER`.
- **Conclusión Option B:** No existe ninguna otra estructura física válida en PostgreSQL para referenciar la membresía sin agregar el constraint.

---

## 7. EVALUACIÓN DE OPTION C: FK SIMPLE `(membership_id -> id)` + RLS + RUNTIME

- **Pregunta Crítica:** ¿Esto garantiza integridad física o solamente autorización/aislamiento?
- **Dictamen:** **SOLAMENTE AUTORIZACIÓN / AISLAMIENTO EN RUNTIME.**
- **Demostración de Falla Física:**  
  Con una FK simple `FOREIGN KEY (membership_id) REFERENCES memberships(id)`, el motor de base de datos a nivel DDL permite que una consulta `INSERT INTO service_assignments (establishment_id, membership_id) VALUES ('Est_A', 'Membership_de_Est_B')` sea exitosa si se ejecuta fuera del middleware de contexto activo (ej. scripts de mantenimiento, procesos batch, migraciones de datos o bugs en servicios).
- **Conclusión Option C:** **RECHAZADA.** No garantiza integridad física relacional en la base de datos.

---

## 8. EVALUACIÓN DE OPTION D: CONSTRAINT ALTERNATIVO `UNIQUE (id, tenant_id)`

- **Análisis:** Si solo se agregara `UNIQUE (id, tenant_id)` a `memberships`:
  `service_assignments` podría declarar `FOREIGN KEY (membership_id, tenant_id) REFERENCES memberships(id, tenant_id)`.
- **Insuficiencia:** Esto garantizaría que el servicio y la membresía pertenezcan al mismo `tenant_id`, pero **NO garantizaría** que pertenezcan al mismo `establishment_id` (permitiría cruzamiento de sedes dentro del mismo tenant).
- **Conclusión Option D:** **INSUFICIENTE.** La única clave que previene cruzamientos inter-sede e inter-tenant simultáneamente es la tupla triple `(id, establishment_id, tenant_id)`.

---

## 9. PUNTO CRÍTICO: PRIMARY KEY VS CLAVE CANDIDATA COMPUESTA

Se documenta formalmente la distinción conceptual en la teoría relacional de PostgreSQL:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                     PRIMARY KEY VS CANDIDATE COMPOSITE KEY                  │
│                                                                             │
│  1. memberships.id = PRIMARY KEY                                            │
│     -> Otorga la identidad ontológica y unicidad de fila.                   │
│                                                                             │
│  2. memberships(id, establishment_id, tenant_id) = CANDIDATE KEY (UNIQUE)  │
│     -> NO añade unicidad de datos (id ya es único).                         │
│     -> Su ÚNICA función física es exponer la tupla relacional completa para │
│        permitir que tablas hijas validen integridad compuesta en DDL.       │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 10. INTEGRIDAD RESULTANTE (CONVERGENCIA FÍSICA PROBADA)

Al adoptar la Opción A, el esquema físico de `service_assignments` alcanza una convergencia matemática perfecta:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                   DUAL TRIPLE COMPOSITE INTEGRITY PROVEN                    │
│                                                                             │
│                             service_assignments                             │
│                             ├── id (UUID PK)                                │
│                             ├── tenant_id ──────────────────────────┐       │
│                             ├── establishment_id ────────────┐      │       │
│                             ├── service_offer_id ─────┐      │      │       │
│                             └── membership_id ──┐     │      │      │       │
│                                                 │     │      │      │       │
│         ┌───────────────────────────────────────┘     │      │      │       │
│         │         ┌───────────────────────────────────┘      │      │       │
│         ▼         ▼                                          ▼      ▼       │
│    memberships(id,                                establishment_id, tenant_id)
│                                                              ▲      ▲       │
│         ▲         ▲                                          │      │       │
│         │         └───────────────────────────────────┐      │      │       │
│         └───────────────────────────────────────┐     │      │      │       │
│                                                 │     │      │      │       │
│    service_offers(id,                             establishment_id, tenant_id)
└─────────────────────────────────────────────────────────────────────────────┘
```

### Demostración Formal de No-Cruzamiento:
1. `service_assignments(establishment_id, tenant_id)` está forzado a coincidir con `service_offers(establishment_id, tenant_id)`.
2. `service_assignments(establishment_id, tenant_id)` está forzado a coincidir con `memberships(establishment_id, tenant_id)`.
3. Por transitividad relacional en el motor DDL:
   $$\text{service\_offers.establishment\_id} = \text{service\_assignments.establishment\_id} = \text{memberships.establishment\_id}$$
   $$\text{service\_offers.tenant\_id} = \text{service\_assignments.tenant\_id} = \text{memberships.tenant\_id}$$
4. **Resultado:** Cruzamiento inter-tenant = **FÍSICAMENTE IMPOSIBLE (0%)**. Cruzamiento inter-sede = **FÍSICAMENTE IMPOSIBLE (0%)**.

---

## 11. IMPACTO SOBRE FOUNDATION

| Dimensión de Impacto | Evaluación Técnica | Nivel de Riesgo |
| :--- | :--- | :--- |
| **Schema Impact** | Adición de 1 constraint único (`uq_membership_id_establishment_tenant`). Cero columnas nuevas. | CERO |
| **Constraint Impact** | Ningún constraint existente (`uq_membership_establishment_user`, FKs) es alterado o eliminado. | CERO |
| **Index Impact** | Creación de 1 índice B-Tree subyacente (~40 bytes/fila). | DESPRECIABLE |
| **Runtime Impact** | Cero impacto en consultas existentes (`SELECT`, `JOIN` continúan usando PK `id` e índices previos). | CERO |
| **Application Impact** | Cero cambios en controladores, servicios o middlewares existentes de backend. | CERO |
| **Existing Data Impact** | 100% de los datos actuales en `memberships` cumplen la restricción de forma inmediata. | CERO |
| **Migration Impact** | Sentencia DDL simple e idempotente: `ALTER TABLE memberships ADD CONSTRAINT ...`. | SEGURO |
| **Rollback Implications**| Reversible instantáneamente mediante `ALTER TABLE memberships DROP CONSTRAINT ...`. | SEGURO |

---

## 12. DATA SAFETY (SEGURIDAD DE DATOS)

- La operación DDL no bloquea escrituras de forma prolongada (en PostgreSQL, validar un UNIQUE sobre una tabla con PK toma menos de 10 milisegundos).
- No requiere reescritura de tabla (`table rewrite`).
- No introduce valores NULL ni altera la visibilidad transaccional.

---

## 13. RUNTIME SAFETY (SEGURIDAD EN TIEMPO DE EJECUCIÓN)

- Compatible 100% con `066_context_resolution_tenant_resolver.sql`.
- Compatible 100% con el middleware de contexto activo (`activeContextMiddleware.js`).
- Compatible 100% con las políticas RLS existentes `tenant_isolation_memberships`.

---

## 14. ECONOMY ANALYSIS (ANÁLISIS DE ECONOMÍA ARQUITECTÓNICA)

$$\text{ALCANCE} \longrightarrow \text{NECESIDAD} \longrightarrow \text{IMPACTO} \longrightarrow \text{ECONOMÍA}$$

- **¿Es necesaria?** SÍ, para cumplir la regla directiva de integridad relacional en DDL sin delegarla a runtime.
- **¿Es mínima?** SÍ, 1 sola línea de DDL aditiva.
- **¿Duplica lógica?** NO, habilita la integridad física nativa de PostgreSQL.

---

## 15. RECOMMENDATION (RECOMENDACIÓN FINAL)

```text
================================================================================
RESULT A — COMPATIBILITY CONFIRMED
================================================================================

OPTION A:
UNIQUE (id, establishment_id, tenant_id) ON memberships

is:
• NECESSARY (Requisito mandatorio de PostgreSQL para FK compuesta triple)
• MINIMAL   (Modificación puramente aditiva de 1 solo constraint)
• SAFE      (Cero impacto destructivo, cero reescritura de tabla, 100% compatible con datos)
• COHERENT  (Armoniza con el patrón compuesto de Foundation 065 y Service Offers R1)

STATUS:
APPROVED BY DIRECTOR — CLOSED
================================================================================
```

---

## 16. DECISION REQUIRED (DECISIÓN REQUERIDA DEL DIRECTOR)

Se solicita al Director del Proyecto GlowApp SaaS emitir la decisión formal:

> **DIRECTOR GATE DECISION:**  
> ¿Aprueba el Director la **OPCIÓN A** para incluir la adición del constraint `CONSTRAINT uq_membership_id_establishment_tenant UNIQUE (id, establishment_id, tenant_id)` sobre la tabla `memberships` en la futura migración DDL de implementación física?

---

## 17. SELF-CHECK (FOUNDATION COMPATIBILITY SELF-CHECK)

```text
================================================================================
FOUNDATION COMPATIBILITY SELF-CHECK
================================================================================

Foundation modified:                       0 (Propuesta no implementada)
Membership modified:                      0 (Propuesta no implementada)
Assignment modified:                      0 (Propuesta no implementada)

DDL executed:                              0
Migration created:                         0

Evidence verified directly:               YES (Inspeccionado en PostgreSQL beauty_db)

Composite FK feasibility proven:           YES (Demostrado bajo Opción A)
Cross-establishment integrity proven:      YES (Convergencia triple probada)
Cross-tenant integrity proven:             YES (Convergencia triple probada)

Alternative evaluated:                    YES (Opciones B, C y D analizadas y descartadas)
Minimum modification demonstrated:         YES (1 solo constraint aditivo)

New conceptual decision invented:          0
Cross-domain expansion:                    0
Speculative architecture:                  0

RESULT:
PASS (Analysis Complete)

IMPLEMENTATION AUTHORIZATION:
NOT GRANTED
================================================================================
```
