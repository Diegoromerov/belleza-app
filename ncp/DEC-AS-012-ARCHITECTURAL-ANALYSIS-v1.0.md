# DEC-AS-012 — ANÁLISIS DE DISEÑO ARQUITECTÓNICO v1.0 (RECONCILIADO R2)
## Assignment Delete Semantics Analysis

**DECISION_ID:** `DEC-AS-012`  
**ESTADO:** `DEC-AS-012 — RECONCILED ANALYSIS R2 — PENDING DIRECTOR DECISION 🟡`  
**TIPO:** Architectural Delete Semantics & Referential Lifecycle Reconciliation  
**AUTORIDAD:** Director Arquitectónico del Proyecto GlowApp SaaS  
**GOALS ORIGEN:** `DEC-AS-012` / `DEC-AS-012-R1` / `DEC-AS-012-R2`  
**NIVEL DE IMPLEMENTACIÓN:** `ZERO IMPLEMENTATION — ZERO MIGRATIONS — ZERO RUNTIME CHANGES`  
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
- `DEC-AS-007-ARCHITECTURAL-ANALYSIS-v1.0.md` (Referential Integrity Reconciliation)  
- `DEC-AS-008-ARCHITECTURAL-ANALYSIS-v1.0.md` (Physical Identity & Minimum Structure Reconciliation)  
- `DEC-AS-009-ARCHITECTURAL-ANALYSIS-v1.0.md` (Assignment Validity & Lifecycle Semantics)  
- `DEC-AS-010-ARCHITECTURAL-ANALYSIS-v1.0.md` (Assignment Cardinality Analysis)  
- `DEC-AS-011-ARCHITECTURAL-ANALYSIS-v1.0.md` (Assignment Relation Uniqueness Analysis)  
**FECHA DE RECONCILIACIÓN:** 2026-09-10  

---

## 1. EXECUTIVE SUMMARY & RECONCILIACIÓN R2

El presente análisis técnico reconcilia y delimita la **semántica arquitectónica del borrado** para la entidad `ASSIGNMENT` (`DEC-AS-006`) y las entidades relacionadas con ella (`SERVICE_OFFER`, `MEMBERSHIP`, `ESTABLISHMENT` y `TENANT`), separando estrictamente la política semántica conceptual de la implementación física del motor relacional.

### 1.1. Principios y Reglas Conceptuales Reconciliadas
1. **Semántica de Eliminación de Assignment:**  
   $$\mathbf{DELETE \ ASSIGNMENT} = \mathbf{DESASIGNACION \ PURA}$$
   - Elimina exclusiva y únicamente el vínculo de asignación.
   - **NO** elimina la `SERVICE_OFFER` ni altera el catálogo de la sede.
   - **NO** elimina la `MEMBERSHIP` ni modifica su `status`.
   - **NO** ejecuta mutaciones ni materializaciones en B2C (`public.services`).
   - **NO** publica ni despublica nada.
2. **Semántica de Entidades Referenciadas:**  
   Una entidad referenciada por `ASSIGNMENT` (`SERVICE_OFFER`, `MEMBERSHIP`) **no debe ser destruida automáticamente de forma que produzca pérdida silenciosa de relaciones SaaS dependientes**.
3. **Separación Semántica vs Física:**  
   La semántica de protección y no destrucción silenciosa es una regla de dominio conceptual; el mecanismo DDL exacto (`ON DELETE`) permanece formalmente **`UNDEFINED / PENDING FUTURE PHYSICAL DESIGN`**.

---

## 2. SEMANTIC DELETE POLICY VS PHYSICAL DELETE MECHANISM

```text
================================================================================
SEPARACIÓN FORMAL: POLÍTICA SEMÁNTICA vs MECANISMO FÍSICO

┌────────────────────────────────────────┐  ┌────────────────────────────────────────┐
│      POLÍTICA SEMÁNTICA DE BORRADO     │  │       MECANISMO FÍSICO DDL (PG)        │
│          (Regla de Dominio)            │  │          (Diseño Relacional)           │
├────────────────────────────────────────┤  ├────────────────────────────────────────┤
│ • Delete Assignment = Desasignación    │  │ • Cláusulas ON DELETE                  │
│ • Cero impacto colateral en miembros   │  │ • (RESTRICT / CASCADE / NO ACTION)     │
│ • Cero impacto colateral en ofertas    │  │ • Triggers de limpieza DDL             │
│ • Padres no se destruyen en silencio   │  │ • Índices y FKs físicas                │
│ • Protección de relaciones dependientes│  │                                        │
│   STATUS: APROBADO CONCEPTUALMENTE     │  │   STATUS: UNDEFINED (PENDING DESIGN)   │
└────────────────────────────────────────┘  └────────────────────────────────────────┘
================================================================================
```

---

## 3. EVIDENCIA FÍSICA EN SAAS FOUNDATION (`065`)

Al examinar `065_saas_foundation_core.sql`, se observa el contexto relacional existente en el núcleo de GlowApp SaaS:

```text
================================================================================
PATRÓN DE INTEGRIDAD EN FOUNDATION 065 CORE:

1. ORGANIZATIONS ──► TENANTS:
   - tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT

2. ESTABLISHMENTS ──► ORGANIZATIONS / TENANTS:
   - tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT
   - FOREIGN KEY (organization_id, tenant_id) REFERENCES organizations(id, tenant_id) ON DELETE RESTRICT

3. MEMBERSHIPS ──► ESTABLISHMENTS / USUARIOS / TENANTS:
   - tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT
   - FOREIGN KEY (establishment_id, tenant_id) REFERENCES establishments(id, tenant_id) ON DELETE RESTRICT
   - FOREIGN KEY (user_id, tenant_id) REFERENCES usuarios(id, tenant_id) ON DELETE RESTRICT

4. USUARIOS ──► TENANTS:
   - FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT
================================================================================
```

### 3.1. Alcance de la Evidencia de Foundation
- La presencia de `ON DELETE RESTRICT` en Foundation `065` constituye **evidencia del estándar de protección de datos** del sistema.
- Sin embargo, **no se extrapola automáticamente** como una decisión DDL cerrada para `ASSIGNMENT`; la asignación contará con su propia formalización física en el momento oportuno.

---

## 4. DISTINCIÓN ENTRE STATUS, VALIDEZ, DELETE Y AUDITORÍA

Se formaliza la separación conceptual entre estos cuatro ejes independientes:

```text
================================================================================
DISTINCIÓN CONCEPTUAL RIGUROSA:

1. MEMBERSHIP STATUS (Foundation 065 Core):
   - INVITED | ACTIVE | SUSPENDED | REVOKED (Estado contractual del usuario).

2. ASSIGNMENT VALIDITY (DEC-AS-009):
   - Validez operacional derivada: ASSIGNMENT_EXISTS ∧ MEMBERSHIP.status = 'ACTIVE'.
   - SUSPENDED ≠ DELETE ASSIGNMENT (La asignación existe, pero se torna inoperable temporalmente).
   - REVOKED ≠ DELETE ASSIGNMENT (La asignación existe, pero queda inoperable sin requerir borrado físico).

3. DELETE SEMANTICS (DEC-AS-012 - Presente Análisis):
   - Semántica conceptual ante la desaparición o eliminación de una entidad.

4. AUDIT HISTORY (UNDEFINED):
   - Mecanismos de trazabilidad histórica. El borrado de una asignación no resuelve ni impide la auditoría.
================================================================================
```

---

## 5. ANÁLISIS DE SEMÁNTICA CONCEPTUAL POR ENTIDAD

### 5.1. Eliminación de `ASSIGNMENT` (Desasignación)
- **Regla Conceptual:** La eliminación de una tupla en `ASSIGNMENT` representa **exclusivamente la desasignación**.
- **Invariantes:**
  - La `SERVICE_OFFER` continúa existiendo intacta en el catálogo de la sede.
  - La `MEMBERSHIP` continúa existiendo intacta en el equipo de la sede.
  - El `membership.status` no se altera.
  - Cero efectos en B2C.

### 5.2. Eliminación de `SERVICE_OFFER` (Oferta Comercial)
- **Regla Conceptual:** La eliminación de una oferta comercial no debe destruir en silencio relaciones SaaS dependientes. Las asignaciones que dependen de ella deben ser protegidas o tratadas explícitamente mediante workflows administrativos.

### 5.3. Eliminación de `MEMBERSHIP` (Membresía del Profesional)
- **Regla Conceptual:** En el flujo operativo normal de SaaS, las desvinculaciones se manejan vía `status = 'REVOKED'` (`DEC-AS-009`), manteniendo la integridad del histórico. Ante un intento de eliminación física de la entidad, debe preservarse la integridad evitando cascadas destructivas descontroladas.

### 5.4. Eliminación de `ESTABLISHMENT` y `TENANT`
- **Regla Conceptual:** Entidades raíz del ecosistema SaaS. Su eliminación está gobernada y protegida estructuralmente por las invariantes de Foundation `065`.

---

## 6. EVALUACIÓN DE ALTERNATIVAS DE DISEÑO SEMÁNTICO

```text
================================================================================
ALTERNATIVAS DE POLÍTICA DE BORRADO:

ALTERNATIVE A: Semántica Protegida (Recomendada)
  - Desasignación pura y autónoma para la entidad ASSIGNMENT.
  - No destrucción silenciosa de relaciones dependientes para entidades padre.
  - Implementación física DDL: UNDEFINED (PENDING FUTURE PHYSICAL DESIGN).

ALTERNATIVE B: Destrucción en Cascada Silenciosa
  - Eliminación destructiva automática de todo el grafo dependiente.
  - Antipatrón para integridad SaaS.
================================================================================
```

---

## 7. MATRIZ COMPARATIVA DE ALTERNATIVAS

| Criterio de Evaluación | Alternative A (Semántica Protegida) | Alternative B (Cascada Silenciosa) |
| :--- | :--- | :--- |
| **Preservación de Relaciones SaaS** | **ÓPTIMA** (Sin pérdida silenciosa) | **DEFICIENTE** (Borrado silencioso masivo) |
| **Claridad de Desasignación** | **ÓPTIMA** (Desasignación pura y limpia) | **REGULAR** |
| **Alineación con DEC-AS-009** | **ÓPTIMA** (Coherente con validez derivada)| **DEFICIENTE** |
| **Alineación con Foundation 065** | **ÓPTIMA** (Patrón protector) | **DEFICIENTE** (Contrario a Foundation) |
| **Flexibilidad de Diseño Físico** | **ÓPTIMA** (Deja DDL abierto para ADR físico)| **INVIABLE** (Fuerza CASCADE prematuro) |

---

## 8. SEMÁNTICA DE BORRADO CONCEPTUAL CERRADA (`CLOSED CONCEPTUALLY`)

> [!IMPORTANT]
> **DECISIÓN CONCEPTUAL CERRADA:**
> $$\mathbf{DELETE \ ASSIGNMENT} = \mathbf{DESASIGNACION \ PURA}$$

Se formaliza la **Semántica de Borrado Protegida (Alternative A)** como decisión conceptualmente cerrada:

```text
================================================================================
DECLARACIÓN DE SEMÁNTICA DE BORRADO CONCEPTUAL CERRADA:

1. ELIMINACIÓN DE ASSIGNMENT (CLOSED CONCEPTUALLY):
   - Semántica: Desasignación Pura.
   - Elimina única y exclusivamente el vínculo de asignación (tupla ASSIGNMENT).
   - NO elimina SERVICE_OFFER.
   - NO elimina MEMBERSHIP.
   - NO modifica membership.status.
   - NO materializa ni desmaterializa B2C (public.services).
   - NO publica ni despublica nada en el catálogo público.

2. ELIMINACIÓN DE ENTIDADES PADRE (SERVICE_OFFER / MEMBERSHIP):
   - Semántica: No destrucción silenciosa.
   - Una entidad padre referenciada no debe destruirse automáticamente
     produciendo pérdida silenciosa de relaciones dependientes en SaaS.

3. MECANISMO FÍSICO DDL:
   - El comportamiento relacional exacto (cláusulas ON DELETE) permanece:
     UNDEFINED — PENDING FUTURE PHYSICAL DESIGN.
================================================================================
```

---

## 9. DECISIONES ABIERTAS PRESERVADAS (OPEN DECISIONS)

El presente análisis mantiene rigurosamente intactas todas las decisiones abiertas del sistema:

```text
| Dimensión / Decisión            | Estado Epistemológico                                     |
| ------------------------------- | --------------------------------------------------------- |
| ASSIGNMENT Cardinality          | CLOSED: N:M (DEC-AS-010)                                  |
| ASSIGNMENT Relation Uniqueness  | CLOSED: UNIQUE (DEC-AS-011)                               |
| ASSIGNMENT Lifecycle            | CLOSED AS DERIVED VALIDITY (DEC-AS-009)                   |
| ASSIGNMENT Delete Semantics     | CLOSED CONCEPTUALLY: DELETE ASSIGNMENT = PURE UNASSIGNMENT |
| Physical ON DELETE Behavior     | UNDEFINED (PENDING FUTURE PHYSICAL DESIGN)                |
| ASSIGNMENT Audit Attributes     | UNDEFINED (created_at, etc.)                              |
| ASSIGNMENT Audit History        | UNDEFINED (Trazabilidad separada)                         |
| ASSIGNMENT Physical Table Name  | UNDEFINED (Nombre definitivo)                             |
| ASSIGNMENT Workflow UI/API      | UNDEFINED                                                 |
| MATERIALIZATION Implementation  | UNDEFINED (Downstream desacoplado)                        |
| PUBLICATION Workflow / Flags    | NOT PRESENT / NOT USED                                    |
| PHYSICAL IMPLEMENTATION AUTH    | NONE (ZERO CODE / ZERO DDL)                               |
```

---

## 10. FRONTERA DE IMPLEMENTACIÓN (IMPLEMENTATION BOUNDARY)

- **Cero Código:** Prohibida la creación o edición de código en `backend/src/`.
- **Cero Migraciones / DDL:** Prohibida la creación de archivos SQL en `backend/migrations/` o ejecución de DDL.
- **Cero Mutaciones:** Cero modificaciones de datos en PostgreSQL.
- **Inmutabilidad de Contratos:** `Foundation (065/066)`, `CDC`, `HBC`, `NODO-01`, `DEC-SE-001/002`, `DEC-AS-001/002/003/005/006/007/008/009/010/011` permanecen 100% protegidos.

---

## 11. CONDICIONES DE PARADA ARQUITECTÓNICA (ARCHITECTURAL STOP)

$$\mathbf{STOP \ ARQUITECTONICO: \ RECONCILIACION \ DEC\text{-}AS\text{-}012\text{-}R2 \ COMPLETADA}$$

El análisis reconciliado de semánticas de borrado queda formalizado y con estado epistemológico alineado con la decisión del Director.

---

## 12. ESTADO FINAL DEL ENTREGABLE

$$\text{ESTADO: } \mathbf{DEC\text{-}AS\text{-}012 \text{ — RECONCILED ANALYSIS R2 — PENDING DIRECTOR DECISION } \odot}$$
