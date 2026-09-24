# DEC-AS-013 — ANÁLISIS DE DISEÑO ARQUITECTÓNICO v1.0 (RECONCILIADO R1)
## Assignment Audit Attributes Architectural Analysis

**DECISION_ID:** `DEC-AS-013`  
**ESTADO:** `DEC-AS-013 — RECONCILED ANALYSIS R1 — PENDING DIRECTOR DECISION 🟡`  
**TIPO:** Architectural Analysis of Audit Attributes & Traceability Separation  
**AUTORIDAD:** Director Arquitectónico del Proyecto GlowApp SaaS  
**GOALS ORIGEN:** `DEC-AS-013` / `DEC-AS-013-R1`  
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
- `DEC-AS-012-ARCHITECTURAL-ANALYSIS-v1.0.md` (Assignment Delete Semantics Analysis)  
**FECHA DE RECONCILIACIÓN:** 2026-09-10  

---

## 1. EVIDENCE (EVIDENCIA ARQUITECTÓNICA Y DE CÓDIGO)

Para analizar rigurosamente los atributos de auditoría de `ASSIGNMENT`, se examinó la evidencia empírica en las migraciones de Foundation y en los servicios SaaS existentes:

### 1.1. Evidencia en SaaS Foundation Core (`065_saas_foundation_core.sql`)

Al auditar `backend/migrations/065_saas_foundation_core.sql`, se observan los siguientes patrones de persistencia y trazabilidad:

```text
================================================================================
EVIDENCIA DE TIMESTAMPS Y TRAZABILIDAD EN FOUNDATION 065:

1. TABLA organizations:
   - created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
   - updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
   - Sin campos de actor (created_by / updated_by).

2. TABLA establishments:
   - created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
   - updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
   - Sin campos de actor.

3. TABLA memberships:
   - joined_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP  (Evento de Dominio)
   - revoked_at TIMESTAMPTZ                                     (Evento de Dominio / Status)
   - created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP  (Auditoría Técnica Row)
   - updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP  (Auditoría Técnica Row)
   - Sin campos de actor (created_by / revoked_by).
================================================================================
```

### 1.2. Hallazgos Derivados de la Evidencia
1. **Diferenciación entre Dominio y Registro Técnico:**  
   En `memberships`, `joined_at` representa el momento en que el usuario ingresó formalmente al establecimiento (evento de negocio), mientras que `created_at` es la marca técnica de creación del registro.
2. **Ausencia de Columnas de Actor en el Esquema Relacional Core:**  
   Foundation `065` no incorpora columnas `created_by` o `actor_id` en sus tablas relacionales. La autoridad operativa se verifica en runtime a través de `Active Context` (`066` / `activeContextMiddleware.js`), garantizando que quien ejecuta una acción sea un `OWNER` o `MANAGER` activo.
3. **Comportamiento ante Inactivación vs Borrado:**  
   `memberships` posee `status IN ('INVITED', 'ACTIVE', 'SUSPENDED', 'REVOKED')` y registra `revoked_at` cuando el estado muta a `REVOKED`. Por el contrario, para `ASSIGNMENT`, `DEC-AS-009` descartó formalmente la existencia de un `status` propio y `DEC-AS-012` estableció que la desasignación es `DELETE ASSIGNMENT` (Desasignación Pura).

---

## 2. ARCHITECTURAL QUESTION (PREGUNTAS ARQUITECTÓNICAS)

El presente análisis resuelve las siguientes cuestiones estructurales sobre la auditoría y trazabilidad de `ASSIGNMENT`:

- **Pregunta A:** ¿`ASSIGNMENT` necesita timestamps propios para existir conceptualmente?
- **Pregunta B:** Si existen timestamps, ¿cuál es la diferencia conceptual entre `created_at`, `assigned_at`, `updated_at`, `revoked_at` y `deleted_at`?
- **Pregunta C:** ¿`ASSIGNMENT` necesita registrar quién realizó la asignación?
- **Pregunta D:** Si existe actoría, ¿es parte de la identidad de Assignment, atributo operativo o auditoría histórica?
- **Pregunta E:** ¿Quién realizó la asignación debe ser `user_id`, `membership_id`, otro concepto o `UNDEFINED`?
- **Pregunta F:** ¿Debe existir conceptualmente una fecha de desasignación (`revoked_at` / `deleted_at`) en la tupla de Assignment?
- **Pregunta G:** ¿`ASSIGNMENT` necesita una columna de razón/motivo (`reason`)?
- **Pregunta H:** ¿Qué atributos son estrictamente necesarios para representar la relación durable (CORE) y cuáles son meramente auditoría (AUDIT / AUDIT HISTORY)?
- **Pregunta I:** ¿Cuál es el conjunto mínimo conceptual recomendado?
- **Pregunta J:** ¿Qué decisiones deben permanecer abiertas para un futuro diseño físico?

---

## 3. CURRENT CLOSED DECISIONS (MARCO DE AUTORIDAD CERRADO)

```text
================================================================================
ESTADO CANÓNICO DE DECISIONES PREVIAS:

DEC-AS-005 ──► SERVICE_OFFER tiene identidad propia (UUID) y ownership en ESTABLISHMENT.
DEC-AS-006 ──► ASSIGNMENT es entidad física independiente; Target = MEMBERSHIP (065).
DEC-AS-007 ──► Integridad referencial compuesta (tenant_id + establishment_id).
DEC-AS-008 ──► Identidad física propia (UUID) y estructura relacional mínima conceptual.
DEC-AS-009 ──► Sin status propio; validez derivada dinámicamente de MEMBERSHIP (status = 'ACTIVE').
DEC-AS-010 ──► Cardinalidad ASSIGNMENT = N:M.
DEC-AS-011 ──► Unicidad relacional: Máximo 1 tupla representativa por pareja (SERVICE_OFFER, MEMBERSHIP).
DEC-AS-012 ──► DELETE ASSIGNMENT = DESASIGNACIÓN PURA. ON DELETE físico = UNDEFINED. Audit History = UNDEFINED.
================================================================================
```

---

## 4. ANALYSIS (ANÁLISIS ARQUITECTÓNICO RECONCILIADO R1)

### 4.1. Análisis de Existencia vs Temporalidad (Pregunta A)
- **Existencia Ontológica:** La existencia de la relación `ASSIGNMENT` como estado SaaS durable (`DEC-AS-002`) es un hecho lógico-estructural: la oferta comercial $S$ está vinculada con el profesional $M$.
- **Independencia Conceptual:** La relación no necesita una estampa temporal para ser evaluada por el motor de agendamiento o catálogo (la presencia de la relación determina la asignación).
- **Conclusión:** El timestamp no es constitutivo de la existencia conceptual de la relación, sino un **metadato de observación temporal/auditoría**.

### 4.2. Taxonomía y Distinción de Timestamps Candidatos (Pregunta B)

```text
┌─────────────────┬───────────────────────────────┬────────────────────────────────────────┐
│ Timestamp       │ Plano Arquitectónico          │ Estado Conceptual / Aplicabilidad      │
├─────────────────┼───────────────────────────────┼────────────────────────────────────────┤
│ created_at      │ Temporal / Auditoría          │ PROPOSAL — TEMPORAL/AUDIT ATTRIBUTE    │
│ assigned_at     │ Dominio / Evento de Asignación│ UNDEFINED (No asumir identidad)        │
│ updated_at      │ Técnico / Mutación            │ UNDEFINED                              │
│ revoked_at      │ Dominio / Ciclo de Vida       │ CLOSED AS INAPPLICABLE (Sin status)    │
│ deleted_at      │ Técnico / Soft Delete         │ UNDEFINED                              │
└─────────────────┴───────────────────────────────┴────────────────────────────────────────┘
```

1. **`created_at` vs `assigned_at` (Corrección R1):**  
   - `created_at` se plantea exclusivamente como **`PROPOSAL — TEMPORAL/AUDIT ATTRIBUTE`** (no aprobado).
   - No se prejuzga si existirá físicamente, su nulabilidad, tipo, valor por defecto, ni si representa persistencia técnica o evento de negocio.
   - Se mantiene rigurosamente la separación conceptual: **`created_at ≠ necesariamente assigned_at`**. No se colapsa una posible coincidencia temporal práctica en una identidad semántica formal. `assigned_at` permanece **`UNDEFINED`**.
2. **`updated_at`:**  
   Dado que `ASSIGNMENT` no posee atributos operativos mutables propios (`DEC-AS-009` descartó status, `DEC-AS-008` definió estructura relacional pura), el estado de `updated_at` permanece **`UNDEFINED`**.
3. **`revoked_at`:**  
   En `memberships`, `revoked_at` acompaña a `status = 'REVOKED'`. Como `ASSIGNMENT` **no tiene status propio** (`DEC-AS-009`), no experimenta el estado "revocado". Por ende, `revoked_at` queda **`CLOSED AS INAPPLICABLE`** para la entidad de asignación.
4. **`deleted_at`:**  
   Implicaría introducir *soft delete*, lo cual alteraría las restricciones de unicidad de pareja (`DEC-AS-011`) y la semántica de desasignación pura (`DEC-AS-012`). Permanece **`UNDEFINED`**.

### 4.3. Actoría y Autoría de la Asignación (Preguntas C, D y E)
- **Autoridad en Runtime vs Persistencia:** `DEC-AS-001` garantiza que la creación de asignaciones solo es autorizada por roles `OWNER` o `MANAGER` dentro del contexto activo verificado (`066`).
- **Naturaleza de la Actoría:**  
  La actoría (`created_by`) **no es parte de la identidad** de `ASSIGNMENT` ni altera su comportamiento operacional en el motor de agendamiento. Pertenece estrictamente al plano de **auditoría administrativa y trazabilidad**.
- **Tipo de Sujeto Actor (`user_id` vs `membership_id`):**  
  - Almacenar `user_id` registraría al sujeto físico que ejecutó la acción.
  - Almacenar `membership_id` registraría el contexto administrativo desde el cual se emitió la autorización.
  - El estado epistemológico permanece:  
    $$\mathbf{created\_by = UNDEFINED \ — \ ACTOR \ REPRESENTATION \ PENDING}$$

### 4.4. Fecha de Desasignación e Invalidación (Pregunta F)
Se distingue rigurosamente entre tres fenómenos:
1. **`DELETE ASSIGNMENT` (Desasignación Pura - DEC-AS-012):**  
   Al destruirse la relación activa, una fecha de desasignación no puede persistir en la propia relación. Solo podría existir en un mecanismo de auditoría histórica independiente.
2. **`REVOKE ASSIGNMENT`:**  
   Concepto inválido. No existe la transición "revocada" dentro de `ASSIGNMENT`.
3. **`INVALIDATION BY MEMBERSHIP` (DEC-AS-009):**  
   Si el profesional pasa a `SUSPENDED` o `REVOKED`, dicha fecha ya se encuentra capturada en `memberships.revoked_at` (Foundation `065`). La asignación no requiere duplicar dicho timestamp.

### 4.5. Justificación de Razón/Motivo (`reason`) (Pregunta G)
- No existe evidencia en el modelo SaaS de GlowApp, ni en Foundation `065`, ni en `NODO-01` que justifique la captura de un texto o catálogo de `reason` al momento de asignar.
- Clasificación: **`UNDEFINED / NO EVIDENCE`**.

---

## 5. CORE RELATION VS AUDIT SEPARATION (SEPARACIÓN DE CAPAS)

Se formalizan los tres planos arquitectónicos independientes:

```text
================================================================================
SEPARACIÓN CONCEPTUAL RIGUROSA:

┌──────────────────────────────────────────────────────────────────────────────┐
│ 1. CORE RELATION ATTRIBUTES (Conceptualmente Definido):                      │
│    • Identidad propia de la asignación (DEC-AS-008)                          │
│    • Referencia a SERVICE_OFFER (DEC-AS-005)                                 │
│    • Referencia a MEMBERSHIP (DEC-AS-006)                                    │
│    • Contexto relacional ESTABLISHMENT (DEC-AS-007)                          │
│    • Contexto de aislamiento TENANT (DEC-AS-007 / 065)                       │
│    STATUS: CONCEPTUALLY DEFINED — PHYSICAL MATERIALIZATION PENDING           │
├──────────────────────────────────────────────────────────────────────────────┤
│ 2. AUDIT ATTRIBUTES (Atributos de Auditoría de la Relación):                │
│    • created_at: PROPOSAL — TEMPORAL/AUDIT ATTRIBUTE (No Aprobado)           │
│    • assigned_at: UNDEFINED (No asumir equivalencia)                         │
│    • updated_at: UNDEFINED                                                   │
│    • created_by: UNDEFINED — ACTOR REPRESENTATION PENDING                    │
├──────────────────────────────────────────────────────────────────────────────┤
│ 3. AUDIT HISTORY (Trazabilidad Histórica):                                   │
│    • Registro/log histórico de eventos de asignación y desasignación         │
│    • STATUS: CONCEPTUALLY INDEPENDENT / PHYSICAL MECHANISM UNDEFINED         │
└──────────────────────────────────────────────────────────────────────────────┘
================================================================================
```

---

## 6. CANDIDATE AUDIT ATTRIBUTES (EVALUACIÓN DE CANDIDATOS)

| Atributo Candidato | Rol / Concepto | Justificación Arquitectónica | Estado Epistemológico |
| :--- | :--- | :--- | :--- |
| **`created_at`** | Temporal / Auditoría | Propuesta de marca temporal de creación. No aprobado. | **PROPOSAL — TEMPORAL/AUDIT ATTRIBUTE** |
| **`assigned_at`** | Dominio / Negocio | Marca temporal de evento de asignación. No prejuzgar equivalencia. | **UNDEFINED** |
| **`updated_at`** | Técnico / Mutación | La relación carece de atributos mutables propios. | **UNDEFINED** |
| **`revoked_at`** | Dominio / Ciclo de Vida | No existe status `REVOKED` en `ASSIGNMENT` (`DEC-AS-009`). | **CLOSED AS INAPPLICABLE** |
| **`deleted_at`** | Técnico / Soft Delete | Requiere soft delete, no autorizado por `DEC-AS-012`. | **UNDEFINED** |
| **`created_by`** | Actor Reference | Trazabilidad de quién autorizó la asignación. | **UNDEFINED — ACTOR REPRESENTATION PENDING** |
| **`revoked_by`** | Actor Reference | Desasignación es física (`DEC-AS-012`); pertenecería a histórico. | **UNDEFINED (NO APLICABLE A RELACIÓN ACTIVA)** |
| **`reason`** | Texto / Motivo | Cero evidencia en requerimientos o contratos de negocio. | **UNDEFINED / NO EVIDENCE** |

---

## 7. EPISTEMOLOGICAL MATRIX (MATRIZ EPISTEMOLÓGICA)

```text
| Dimensión / Decisión            | Estado Epistemológico                                      |
| ------------------------------- | ---------------------------------------------------------- |
| ASSIGNMENT Cardinality          | CLOSED: N:M (DEC-AS-010)                                   |
| ASSIGNMENT Relation Uniqueness  | CLOSED — MÁXIMO UNA RELACIÓN SIMULTÁNEA POR PAR (DEC-AS-011)|
| ASSIGNMENT Lifecycle            | CLOSED — DERIVED VALIDITY (DEC-AS-009)                     |
| ASSIGNMENT Delete Semantics     | CLOSED CONCEPTUALLY — PURE UNASSIGNMENT (DEC-AS-012)        |
| Core Relation Attributes        | CONCEPTUALLY DEFINED — PHYSICAL MATERIALIZATION PENDING    |
| created_at                      | PROPOSAL — TEMPORAL/AUDIT ATTRIBUTE                        |
| assigned_at                     | UNDEFINED                                                  |
| updated_at                      | UNDEFINED                                                  |
| created_by                      | UNDEFINED — ACTOR REPRESENTATION PENDING                   |
| revoked_at                      | CLOSED AS INAPPLICABLE                                     |
| deleted_at                      | UNDEFINED                                                  |
| reason                          | UNDEFINED / NO EVIDENCE                                    |
| Audit History                   | CONCEPTUALLY INDEPENDENT / PHYSICAL MECHANISM UNDEFINED    |
| Physical ON DELETE              | UNDEFINED                                                  |
| Physical Table Name             | UNDEFINED                                                  |
| Workflow UI/API                 | UNDEFINED                                                  |
| Materialization Implementation  | UNDEFINED                                                  |
| PHYSICAL IMPLEMENTATION AUTH    | NONE (ZERO CODE / ZERO DDL)                                |
```

---

## 8. RECOMMENDATION — PROPOSAL / NOT APPROVED

> [!IMPORTANT]
> **PROPUESTA ARQUITECTÓNICA — NO APROBADA — REQUIERE DECISIÓN FORMAL DEL DIRECTOR**

Se somete a la consideración del Director la siguiente delimitación conceptual:

### 8.1. Delimitación Conceptual Propuesta
1. **Atributos de Relación Nuclear (Core Relation Attributes):**
   - Conceptualmente definidos bajo los 5 conceptos relacionales: identidad propia, referencia a `SERVICE_OFFER`, referencia a `MEMBERSHIP`, contexto `ESTABLISHMENT`, contexto `TENANT`.
   - Su materialización física en columnas, nombres, tipos y FKs permanece: **`PHYSICAL MATERIALIZATION PENDING`**.
2. **Atributo Temporal / Auditoría (`created_at`):**
   - Se mantiene exclusivamente como **`PROPOSAL — TEMPORAL/AUDIT ATTRIBUTE`**.
   - No se define DDL, nulabilidad, valor por defecto, ni se unifica semánticamente con `assigned_at`.
3. **Historial de Auditoría (`Audit History`):**
   - Se formaliza como **`CONCEPTUALLY INDEPENDENT / PHYSICAL MECHANISM UNDEFINED`**.
   - No se prejuzga la existencia de tablas de log, event store, ni servicios externos.

---

## 9. OPEN DECISIONS (DECISIONES ABIERTAS PRESERVADAS)

Las siguientes decisiones permanecen estrictamente abiertas y no son prejuzgadas por este análisis:

1. **Materialización Física de Core Attributes:** Número de columnas físicas, tipos de datos, constraints relacionales y nombres.
2. **Aprobación e Implementación de `created_at`:** Decisión formal sobre su inclusión física, tipo y default.
3. **Mecanismo Físico de Actoría (`created_by`):** Representación de `user_id` vs `membership_id` y constraints.
4. **Presencia de `updated_at` y `assigned_at`:** Decisión abierta de diseño físico.
5. **Mecanismo Físico de `Audit History`:** Sin definición de tablas, retención o mecanismos de eventos.
6. **Nombre Físico de Tabla y Cláusulas DDL ON DELETE.**

---

## 10. IMPLEMENTATION BOUNDARY (FRONTERA DE IMPLEMENTACIÓN)

- **Cero Código:** Prohibida la creación o modificación de controladores, servicios o middlewares.
- **Cero Migraciones / DDL:** Prohibida la creación de archivos SQL en `backend/migrations/` o ejecución de sentencias DDL.
- **Cero Mutaciones de Base de Datos:** Cero modificaciones en tablas de PostgreSQL.
- **Protección de Contratos Cerrados:** `Foundation (065/066)`, `CDC`, `HBC`, `NODO-01`, `DEC-SE-001/002`, `DEC-AS-001..012` permanecen 100% inmutables.

---

## 11. ARCHITECTURAL STOP

$$\mathbf{STOP \ ARQUITECTONICO: \ RECONCILIACION \ DEC\text{-}AS\text{-}013\text{-}R1 \ COMPLETADA}$$

El análisis técnico reconciliado de atributos de auditoría y trazabilidad para `ASSIGNMENT` queda formalizado, eliminando toda sobreafirmación física o semántica y listo para la evaluación del Director.

---

## 12. ESTADO FINAL DEL ENTREGABLE

$$\text{ESTADO: } \mathbf{DEC\text{-}AS\text{-}013 \text{ — RECONCILED ANALYSIS R1 — PENDING DIRECTOR DECISION } \odot}$$
