# DEC-AS-006 — REGISTRO DE DECISIÓN ARQUITECTÓNICA (ADR) v1.0
## Formalización de Assignment como Entidad Física / Relación Desacoplada

**DECISION_ID:** `DEC-AS-006`  
**ESTADO:** `DEC-AS-006 — APPROVED / CLOSED 🔒`  
**TIPO:** Architectural Decision Record (ADR)  
**AUTORIDAD:** Director Arquitectónico del Proyecto GlowApp SaaS  
**GOALS ORIGEN:** `DEC-AS-006-001` / `DEC-AS-006-002`  
**AUTORIZACIÓN DE IMPLEMENTACIÓN:** `NONE — NO IMPLEMENTATION AUTHORIZED BY THIS DECISION`  
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
**FECHA DE APROBACIÓN:** 2026-09-10  

---

## 1. DECLARACIÓN DE DECISIÓN FORMAL

El Director Arquitectónico del Proyecto GlowApp SaaS aprueba y formaliza como regla canónica del sistema:

```text
DEC-AS-006
────────────────────────────────────────────────────────────────────────────────
ASSIGNMENT:
DURABLE SAAS STATE

PHYSICAL REPRESENTATION:
INDEPENDENT ASSIGNMENT ENTITY / RELATION

TARGET:
MEMBERSHIP

TARGET CONDITION:
ACTIVE PROFESSIONAL CONTEXT (membership.status = 'ACTIVE')

CARDINALITY:
UNDEFINED

LIFECYCLE:
UNDEFINED (NO ASSIGNMENT = ABSENCE OF ASSIGNMENT LINK)

OWNERSHIP:
SERVICE_OFFER → ESTABLISHMENT

ASSIGNMENT:
SERVICE_OFFER → ACTIVE PROFESSIONAL

TENANT INTEGRITY:
REQUIRED (SERVICE_OFFER.tenant == ASSIGNMENT.tenant == MEMBERSHIP.tenant)

ESTABLISHMENT INTEGRITY:
REQUIRED (SERVICE_OFFER.establishment == MEMBERSHIP.establishment)

MATERIALIZATION:
SEPARATE (ASSIGNMENT ≠ MATERIALIZATION)

PUBLICATION:
NOT USED (ASSIGNMENT ≠ PUBLICATION)

IMPLEMENTATION:
NOT AUTHORIZED BY THIS DECISION
────────────────────────────────────────────────────────────────────────────────
```

---

## 2. MODELO FÍSICO CONCEPTUAL FORMALIZADO

La representación física de Assignment se estructura como una **entidad/relación desacoplada e independiente** de `SERVICE_OFFER`:

```text
================================================================================
MODELO ESTRUCTURAL SAAS (DEC-AS-005 + DEC-AS-006):

                      ┌──────────────────────────────┐
                      │        ESTABLISHMENT         │
                      └──────────────┬───────────────┘
                                     │
                                     │ (physical ownership - DIRECT FK)
                                     ▼
                      ┌──────────────────────────────┐
                      │        SERVICE_OFFER         │
                      │  (UUID Propio Inmutable)     │
                      └──────────────┬───────────────┘
                                     │
                                     │ (durable link)
                                     ▼
                    ┌──────────────────────────────────┐
                    │            ASSIGNMENT            │
                    │  (Entidad Física Independiente)  │
                    └────────────────┬─────────────────┘
                                     │
                                     │ (target link)
                                     ▼
                    ┌──────────────────────────────────┐
                    │      MEMBERSHIP (065 Core)       │
                    │  (Active Professional Context)   │
                    └──────────────────────────────────┘
================================================================================
```

---

## 3. TARGET DE ASIGNACIÓN: `MEMBERSHIP`

1. **Definición del Target:**  
   Se aprueba formalmente que el target conceptual y de referencia física de la asignación sea la entidad **`MEMBERSHIP`** de Foundation `065`.
2. **Componentes del Target:**  
   En Foundation `065`, `memberships` encapsula `user_id + establishment_id + tenant_id + role + relation_type + status`.
3. **Condición de Validez Operacional:**  
   Requiere estrictamente:
   $$\text{membership.status} = \text{'ACTIVE'}$$
   y el target debe representar al colaborador contextual perteneciente a la misma sede física.

---

## 4. FRONTERA ESTRICTA CON B2C (NO CONFUNDIR)

Queda terminantemente prohibido utilizar conceptos, columnas o tablas B2C como sustitutos de la asignación SaaS:
- $\mathbf{SAAS\_PROFESSIONAL} \neq \mathbf{B2C\_PROVIDER}$
- Prohibido el uso de `provider_id`, `public.services` o `perfiles_prestador` dentro del modelo de asignación SaaS.
- La relación con B2C pertenece exclusivamente a la materialización downstream (`DEC-SE-001`, `DEC-AS-003`) y permanece completamente separada.

---

## 5. CARDINALIDAD: ESTADO `UNDEFINED`

Se formaliza:
$$\mathbf{ASSIGNMENT\_CARDINALITY} = \mathbf{UNDEFINED}$$

- **Regla:** Queda prohibido aprobar de forma prematura $1:1$, $1:N$, $N:M$, restricciones `UNIQUE`, arrays o límites numéricos.
- **Garantía Estructural:** La entidad física independiente aprobada en este ADR es neutral y capaz de soportar la cardinalidad que posteriormente se legisle sin requerir cambios en el esquema de `SERVICE_OFFER`.

---

## 6. CICLO DE VIDA (LIFECYCLE): ESTADO `UNDEFINED`

Se formaliza:
$$\mathbf{ASSIGNMENT\_LIFECYCLE} = \mathbf{UNDEFINED}$$

- **Regla Única Vigente:**
  $$\mathbf{NO\_ASSIGNMENT} = \mathbf{ABSENCE\_OF\_ASSIGNMENT\_LINK}$$
- **Estados Sintéticos Prohibidos:** Queda prohibido introducir columnas o enums con estados como `UNASSIGNED`, `PENDING`, `ACTIVE`, `REVOKED`, `DISABLED` o `DELETED`. La existencia del registro constituye la asignación durable vigente.

---

## 7. INTEGRIDAD DE IDENTIDAD, SEDE Y TENANT

1. **Identidad de Assignment:**  
   Assignment posee conceptualmente identidad propia como relación/estado durable. La forma física exacta (UUID, entero, clave compuesta) permanece `UNDEFINED` hasta el diseño de DDL posterior.
2. **Requisito de Integridad de Establecimiento (Establishment Integrity):**  
   $$\text{SERVICE\_OFFER.establishment} == \text{ASSIGNMENT.target\_membership.establishment}$$
   *El mecanismo técnico exacto para garantizarlo (FK compuesta, constraint) será legislado en `DEC-AS-007`.*
3. **Requisito de Integridad Multi-Tenant (Tenant Integrity):**  
   $$\text{SERVICE\_OFFER.tenant} == \text{ASSIGNMENT.tenant} == \text{MEMBERSHIP.tenant}$$
   Debe garantizarse físicamente y ser plenamente compatible con el Row-Level Security (RLS) de Foundation `065`.

---

## 8. SEPARACIONES DE DOMINIO FORMALIZADAS

1. **Ownership $\neq$ Assignment:**  
   - `SERVICE_OFFER → ESTABLISHMENT` (Propiedad física directa inmutable, `DEC-AS-005`).
   - `SERVICE_OFFER → ASSIGNMENT → PROFESSIONAL` (Vínculo operacional subordinado y desacoplado, `DEC-AS-006`).
2. **Assignment $\neq$ Materialization:**  
   - Una asignación SaaS **NO** autoriza ni ejecuta inserciones automáticas en `public.services` (`DEC-AS-003`).
3. **Assignment $\neq$ Publication:**  
   - No existen estados de publicación ni activación en SaaS (`DEC-PUB-001`).

---

## 9. MATRIZ DE DECISIONES ABIERTAS (STATUS MATRIX)

```text
| Elemento                             | Estado Epistemológico               |
| ------------------------------------ | ----------------------------------- |
| ASSIGNMENT Physical Representation   | APPROVED: INDEPENDENT ENTITY (ADR)  |
| ASSIGNMENT Target                    | APPROVED: memberships.id (ADR)      |
| ASSIGNMENT Target Condition          | APPROVED: ACTIVE Status (ADR)       |
| ASSIGNMENT Physical Table Name       | UNDEFINED                           |
| ASSIGNMENT Physical Identity Type    | UNDEFINED                           |
| ASSIGNMENT Cardinality               | UNDEFINED                           |
| ASSIGNMENT Lifecycle                 | UNDEFINED (Absence = Not assigned)  |
| ASSIGNMENT Delete Semantics          | UNDEFINED                           |
| ASSIGNMENT Audit Attributes          | UNDEFINED                           |
| REFERENTIAL INTEGRITY MECHANISM      | PENDING DEC-AS-007                  |
| MATERIALIZATION Implementation       | UNDEFINED                           |
```

---

## 10. AUTORIZACIÓN Y CIERRE

- **Estado Formal:** `DEC-AS-006 — APPROVED / CLOSED 🔒`
- **Autorización de Implementación:** `NONE` (No se autoriza creación de código, tablas, migraciones DDL ni modificaciones a contratos cerrados).
- **Próximo Paso Arquitectónico:** Análisis del mecanismo físico de integridad referencial sede/tenant (`DEC-AS-007`).
