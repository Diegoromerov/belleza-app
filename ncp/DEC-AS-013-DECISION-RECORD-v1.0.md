# DEC-AS-013 — ARCHITECTURAL DECISION RECORD v1.0
## Assignment Audit Attributes Decision Records

**DECISION_RECORD_ID:** `DEC-AS-013`  
**ESTADO:** `APPROVED / CLOSED 🔒 (CON DECISIONES PENDIENTES DELIMITADAS)`  
**TIPO:** Architectural Decision Record (ADR) — Temporal, Actor & Audit Attributes  
**AUTORIDAD:** Director Arquitectónico del Proyecto GlowApp SaaS  
**GOALS ORIGEN:** `DEC-AS-013` / `DEC-AS-013-R1` / `DEC-AS-013-002` / `DEC-AS-013-002-R1` / `DEC-AS-013-003` / `DEC-AS-013-B-DECISION-RECORD`  
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
- `DEC-AS-013-ARCHITECTURAL-ANALYSIS-v1.0.md` (Assignment Audit Attributes Analysis R1)  
- `DEC-AS-013-002-DECISION-ANALYSIS-v1.0.md` (Assignment Audit Attributes Decision Analysis R1)  
- `DEC-AS-013-B-ACTOR-ANALYSIS-v1.0.md` (Assignment Actor Representation Analysis)  
**FECHA DE DECISIÓN FORMAL:** 2026-09-10  

---

## 1. MARCO DE AUTORIDAD Y DIRECTIVA DEL DIRECTOR

El presente documento formaliza las directivas y decisiones arquitectónicas emitidas por el Director Arquitectónico respecto a los atributos de **temporalidad**, **actoría**, **desasignación**, **mutabilidad** y **auditoría** para la entidad de dominio SaaS `ASSIGNMENT`.

```text
================================================================================
CADENA DE DECISIONES DE AUDITORÍA Y ATRIBUTOS DE ASSIGNMENT:

DEC-AS-013-A ──► TEMPORALIDAD: No se requiere assigned_at independiente. Creación temporal permitida.
DEC-AS-013-B ──► ACTORÍA: No forma parte del Core ASSIGNMENT. created_by = NO FORMA PARTE DEL CORE.
DEC-AS-013-C ──► DESASIGNACIÓN: Sin status REVOKED. revoked_at/by inaplicables. deleted_at = UNDEFINED.
DEC-AS-013-D ──► MUTABILIDAD: updated_at NO es requerimiento arquitectónico del dominio.
DEC-AS-013-E ──► RAZÓN / MOTIVO: reason = UNDEFINED / NO CURRENT DOMAIN REQUIREMENT.
DEC-AS-013-F ──► AUDIT HISTORY: Conceptualmente independiente de ASSIGNMENT. Mecanismo = UNDEFINED.
================================================================================
```

---

## 2. DECISION RECORDS POR DIMENSIÓN

---

### 2.1. DEC-AS-013-A — TEMPORALIDAD DE CREACIÓN / ASIGNACIÓN

- **Decision ID:** `DEC-AS-013-A`
- **Pregunta Arquitectónica:** ¿Requiere `ASSIGNMENT` un atributo temporal de negocio (`assigned_at`) independiente del momento de persistencia técnica?
- **Decisión Formal:**  
  $$\mathbf{ASSIGNMENT \ NO \ requiere \ un \ atributo \ conceptual \ independiente \ "assigned\_at"}$$  
  `ASSIGNMENT` puede poseer conceptualmente una marca temporal de creación como atributo de auditoría de la relación.
- **Racional de Decisión (Rationale):**
  1. No existe evidencia actual de asignaciones programadas a futuro en el núcleo SaaS.
  2. No existe evidencia actual de asignaciones retroactivas.
  3. No existe un segundo evento de dominio claramente separado de la creación de la relación asociativa.
  4. No se duplicará temporalidad sin semántica independiente.
- **Base de Evidencia:** Análisis de migraciones `065`, servicios `nodo01Service.js`, `crearDesdeCeroService.js` y contratos `DEC-SE-001/002`.
- **Frontera de Implementación Física:**  
  No se decide todavía la columna física, nombre físico, tipo de dato, valor por defecto, ni obligatoriedad (`NOT NULL`). Dichos aspectos corresponden a la fase de diseño físico.
- **Estado Epistemológico:**  
  $$\mathbf{DEC\text{-}AS\text{-}013\text{-}A = APPROVED \ — \ CLOSED \ 🔒}$$

---

### 2.2. DEC-AS-013-B — ACTORÍA Y AUTORÍA DE LA ASIGNACIÓN

- **Decision ID:** `DEC-AS-013-B`
- **Título:** `ASSIGNMENT ACTOR REPRESENTATION`
- **Pregunta Arquitectónica:** ¿Forma parte la actoría del núcleo conceptual de `ASSIGNMENT` o debe materializarse como atributo en la relación activa?
- **Decisión Formal:**  
  $$\mathbf{La \ actoría \ NO \ forma \ parte \ del \ núcleo \ conceptual \ de \ ASSIGNMENT}$$  
  `ASSIGNMENT` representa exclusivamente la relación durable entre:  
  $$\mathbf{SERVICE\_OFFER \ \longleftrightarrow \ MEMBERSHIP}$$  
  La información relativa a quién ejecutó la acción pertenece conceptualmente a la capa de trazabilidad/auditoría y no constituye identidad ni núcleo relacional de `ASSIGNMENT`.  
  $$\mathbf{created\_by = NO \ FORMA \ PARTE \ DEL \ CORE \ ASSIGNMENT}$$  
  y no debe materializarse como atributo de Assignment en el diseño físico actual.
- **Semántica Aprobada:**
  1. **`USER / IDENTITY`:** Representa al sujeto autenticado que físicamente ejecutó la acción.
  2. **`MEMBERSHIP`:** Representa el contexto administrativo/mandato desde el cual dicho sujeto tenía autoridad para ejecutar la acción (`DEC-AS-001`).
  3. Estas dos dimensiones son conceptualmente diferentes.
  4. **NO** se incorporan actualmente como atributos del núcleo de `ASSIGNMENT`.
- **Relación con Audit History:**
  - La actoría puede formar parte conceptualmente de una futura representación de `AUDIT HISTORY`.
  - **NO** afirmar que ya existe un mecanismo físico de auditoría.
  - **NO** afirmar que se almacenarán necesariamente user + membership.
  - **NO** decidir tabla de auditoría, event store, log, servicio, eventos, retención, estructura física, columnas ni FK.
  - El mecanismo de `AUDIT HISTORY` permanece: `UNDEFINED / PENDING FUTURE DESIGN`.
- **Distinciones Obligatorias:**
  - $\mathbf{ACTOR \neq ASSIGNMENT\_IDENTITY}$
  - $\mathbf{USER \neq MEMBERSHIP}$
  - `USER` responde: *"¿Quién ejecutó la acción?"*
  - `MEMBERSHIP` responde: *"¿Desde qué contexto/mandato tenía autoridad?"*
  - `ASSIGNMENT` responde: *"¿Qué SERVICE_OFFER está vinculada a qué MEMBERSHIP?"*
  Estas responsabilidades permanecen estrictamente separadas.
- **Frontera de Implementación Física:**  
  Prohibida la creación de columnas de actor o foreign keys en la relación activa.
- **Estado Epistemológico:**  
  $$\mathbf{DEC\text{-}AS\text{-}013\text{-}B = APPROVED \ — \ CLOSED \ 🔒}$$

---

### 2.3. DEC-AS-013-C — SEMÁNTICA ANTE LA DESASIGNACIÓN

- **Decision ID:** `DEC-AS-013-C`
- **Pregunta Arquitectónica:** ¿Requiere la entidad activa atributos como `revoked_at`, `revoked_by` o `deleted_at` para representar la desasignación?
- **Decisión Formal:**  
  Cerrar conceptualmente las siguientes reglas canónicas:
  1. `ASSIGNMENT` **no tiene estado `REVOKED`**.
  2. **No existe `REVOKE ASSIGNMENT`** como transición propia de la entidad de asignación.
  3. `revoked_at` **no pertenece conceptualmente a `ASSIGNMENT`**.
  4. `revoked_by` **no pertenece conceptualmente a `ASSIGNMENT`**.
  5. **`DELETE ASSIGNMENT = PURE UNASSIGNMENT`** (`DEC-AS-012`).
  6. `deleted_at` permanece formalmente como:  
     $$\mathbf{deleted\_at = UNDEFINED \ / \ NO \ CURRENT \ EVIDENCE}$$
- **Racional de Decisión (Rationale):**
  - La validez es derivada dinámicamente (`DEC-AS-009`). La revocación de acceso o membresía es un concepto que pertenece a `MEMBERSHIP` (`065`), no a la asignación.
  - La desvinculación pura elimina la relación activa.
  - No se introduce *soft delete* sin justificación ni evidencia aprobada.
- **Base de Evidencia:** `DEC-AS-009`, `DEC-AS-012`, Foundation `065`.
- **Frontera de Implementación Física:**  
  No se crean columnas de revocación ni flags de borrado lógico en la relación activa.
- **Estado Epistemológico:**  
  $$\mathbf{DEC\text{-}AS\text{-}013\text{-}C = APPROVED \ — \ CLOSED \ 🔒}$$

---

### 2.4. DEC-AS-013-D — ATRIBUTO DE ACTUALIZACIÓN (`updated_at`)

- **Decision ID:** `DEC-AS-013-D`
- **Pregunta Arquitectónica:** ¿Requiere `ASSIGNMENT` un atributo de mutabilidad de dominio (`updated_at`)?
- **Decisión Formal:**  
  $$\mathbf{ASSIGNMENT \ NO \ requiere \ updated\_at \ como \ atributo \ de \ dominio}$$
- **Racional de Decisión (Rationale):**
  1. `ASSIGNMENT` no posee actualmente atributos mutables propios (precios en `SERVICE_OFFER`, personal en `MEMBERSHIP`).
  2. Los cambios en `MEMBERSHIP` no equivalen automáticamente a mutaciones de la fila de asignación.
  3. La validez de la asignación es derivada dinámicamente (`DEC-AS-009`).
  4. El fin del ciclo de vida es la desasignación pura (`DEC-AS-012`).
  5. **Importante:** Esto no prohíbe que un futuro diseño físico relacional incorpore timestamps técnicos automáticos por convención general de DDL; simplemente establece que `updated_at` **no es una necesidad arquitectónica del dominio**.
- **Base de Evidencia:** Modelo inmutable asociativo de asignaciones en contratos `NODO-01` y `DEC-AS-006..012`.
- **Frontera de Implementación Física:**  
  No se impone obligatoriedad de mutación de dominio en la tabla relacional.
- **Estado Epistemológico:**  
  $$\mathbf{DEC\text{-}AS\text{-}013\text{-}D = APPROVED \ — \ CLOSED \ 🔒}$$

---

### 2.5. DEC-AS-013-E — RAZÓN / MOTIVO DE LA ACCIÓN (`reason`)

- **Decision ID:** `DEC-AS-013-E`
- **Pregunta Arquitectónica:** ¿Requiere `ASSIGNMENT` un atributo para justificar con texto o catálogo el motivo de la asignación o desasignación?
- **Decisión Formal:**  
  $$\mathbf{reason = UNDEFINED \ / \ NO \ CURRENT \ DOMAIN \ REQUIREMENT}$$  
  No existe evidencia actual suficiente para requerir un atributo conceptual `reason` en `ASSIGNMENT`.
- **Racional de Decisión (Rationale):**
  - Cero requerimientos en los contratos de negocio de GlowApp SaaS que exijan capturar motivos para asociar un servicio a un estilista.
  - Se delimita como no requerido actualmente sin convertirlo en una prohibición absoluta futura si nuevos flujos administrativos lo requiriesen.
- **Base de Evidencia:** Auditoría documental de `Foundation 065`, `CDC`, `HBC`, `NODO-01`.
- **Frontera de Implementación Física:**  
  No se crean columnas de texto o enums de razón en la relación activa.
- **Estado Epistemológico:**  
  $$\mathbf{DEC\text{-}AS\text{-}013\text{-}E = APPROVED \ — \ CLOSED \ 🔒}$$

---

### 2.6. DEC-AS-013-F — HISTORIAL DE AUDITORÍA (`AUDIT HISTORY`)

- **Decision ID:** `DEC-AS-013-F`
- **Pregunta Arquitectónica:** ¿Cómo se relaciona el historial de auditoría con la entidad de asignación activa?
- **Decisión Formal:**  
  $$\mathbf{AUDIT \ HISTORY \ es \ conceptualmente \ independiente \ de \ ASSIGNMENT}$$  
  El mecanismo físico, tecnológico y estructural permanece formalmente:  
  $$\mathbf{UNDEFINED}$$
- **Racional de Decisión (Rationale):**
  1. Se cierra exclusivamente el principio conceptual de desacoplamiento e independencia.
  2. NO se decide todavía: tabla de auditoría, event store, log externo, servicio de trazabilidad, colas de eventos, políticas de retención, mecanismo físico, ni esquema histórico.
- **Base de Evidencia:** Principio de separación de responsabilidades entre estado operacional SaaS y trazabilidad histórica.
- **Frontera de Implementación Física:**  
  Prohibido diseñar o implementar tablas de log, triggers de auditoría o servicios de histórico en esta fase.
- **Estado Epistemológico:**  
  $$\mathbf{DEC\text{-}AS\text{-}013\text{-}F = APPROVED \ — \ CLOSED \ 🔒}$$

---

## 3. MATRIZ EPISTEMOLÓGICA CONSOLIDADA

```text
================================================================================
MATRIZ EPISTEMOLÓGICA CONSOLIDADA (POST DEC-AS-013-B CLOSURE):

| Dimensión / Atributo            | Estado Epistemológico Canónico                              |
| ------------------------------- | ----------------------------------------------------------- |
| ASSIGNMENT Cardinality          | CLOSED: N:M (DEC-AS-010)                                    |
| ASSIGNMENT Relation Uniqueness  | CLOSED — MÁXIMO UNA RELACIÓN SIMULTÁNEA POR PAR (DEC-AS-011) |
| ASSIGNMENT Lifecycle            | CLOSED — DERIVED VALIDITY (DEC-AS-009)                      |
| ASSIGNMENT Delete Semantics     | CLOSED CONCEPTUALLY — PURE UNASSIGNMENT (DEC-AS-012)         |
| Core Relation Attributes        | CONCEPTUALLY DEFINED — PHYSICAL MATERIALIZATION PENDING     |
| DEC-AS-013-A (assigned_at)      | CLOSED: NO REQUERIDO / CREACIÓN TEMPORAL CONCEPTUALMENTE OK |
| DEC-AS-013-B (created_by / act) | CLOSED: NO FORMA PARTE DEL CORE ASSIGNMENT                  |
| DEC-AS-013-C (revoked_at / by)  | CLOSED: INAPLICABLE A ASSIGNMENT / DELETE ES DESASIGNACIÓN  |
| DEC-AS-013-C (deleted_at)       | UNDEFINED / NO CURRENT EVIDENCE                             |
| DEC-AS-013-D (updated_at)       | CLOSED: NO REQUERIDO COMO ATRIBUTO DE DOMINIO               |
| DEC-AS-013-E (reason)           | CLOSED: UNDEFINED / NO CURRENT DOMAIN REQUIREMENT           |
| DEC-AS-013-F (Audit History)    | CLOSED CONCEPTUALLY INDEPENDENT / PHYSICAL MECHANISM UNDEF. |
| unassigned_at / unassigned_by   | UNDEFINED / CANDIDATE HISTORICAL ATTRIBUTES                 |
| Physical ON DELETE              | UNDEFINED (PENDING FUTURE PHYSICAL DESIGN)                  |
| Physical Table Name             | UNDEFINED (Nombre definitivo de tabla)                      |
| Physical Column Names & Types   | UNDEFINED (Tipos DDL y columnas exactas)                    |
| Workflow UI/API                 | UNDEFINED                                                   |
| Materialization Implementation  | UNDEFINED (Downstream desacoplado)                          |
| PHYSICAL IMPLEMENTATION AUTH    | NONE (ZERO CODE / ZERO DDL)                                 |
================================================================================
```

---

## 4. ESTADOS QUE PERMANECEN FORMALMENTE ABIERTOS

En estricta observancia de las directivas del Director, las siguientes dimensiones permanecen **ABIERTAS (UNDEFINED)** para la posterior fase de diseño físico:

1. **`deleted_at`:** `UNDEFINED / NO CURRENT EVIDENCE` (Sin decisión física/conceptual de soft delete).
2. **`unassigned_at` / `unassigned_by`:** `UNDEFINED / CANDIDATE HISTORICAL ATTRIBUTES` (Sin definición de mecanismo).
3. **`reason`:** `UNDEFINED / NO CURRENT DOMAIN REQUIREMENT`.
4. **Mecanismo Físico de `Audit History`:** `UNDEFINED / PENDING FUTURE DESIGN` (Sin tablas de log, event store ni colas).
5. **Mecanismo Físico `ON DELETE`:** `UNDEFINED` (Cláusulas DDL relacionales RESTRICT, NO ACTION, etc.).
6. **Nombre Físico de Tabla:** `UNDEFINED` (`service_assignments`, etc.).
7. **Nombres Físicos de Columnas y Tipos de Datos:** `UNDEFINED` (DDL exacto en PostgreSQL).
8. **Diseño de UI / API / Endpoints:** `UNDEFINED` (Interfaces de usuario y rutas backend).
9. **Materialización B2C:** `UNDEFINED` (Mecanismo downstream desacoplado).

---

## 5. FRONTERA DE IMPLEMENTACIÓN (IMPLEMENTATION BOUNDARY)

- **Cero Código:** Prohibida la modificación o creación de código en `backend/src/`.
- **Cero DDL / Migraciones:** Prohibida la creación de archivos SQL en `backend/migrations/` o ejecución de sentencias DDL.
- **Cero Mutaciones de Base de Datos:** Base de datos PostgreSQL intacta.
- **Inmutabilidad de Contratos Cerrados:** `Foundation (065/066)`, `Context Resolution`, `Active Context`, `Hub Salón`, `Crear Desde Cero`, `HBC`, `NODO-01`, `DEC-SE-001/002`, `DEC-AS-001..012` y `DEC-AS-013` permanecen 100% protegidos.

---

## 6. PARADA ARQUITECTÓNICA (ARCHITECTURAL STOP)

$$\mathbf{STOP \ ARQUITECTONICO: \ DEC\text{-}AS\text{-}013\text{-}B\text{-}DECISION\text{-}RECORD \ COMPLETADO}$$

El registro formal de cierre de la decisión arquitectónica `DEC-AS-013-B` queda archivado y en plena vigencia.

---

## 7. ESTADO FINAL DEL ENTREGABLE

$$\text{ESTADO: } \mathbf{DEC\text{-}AS\text{-}013 \text{ — ALL DECISION RECORDS REGISTERED — APPROVED / CLOSED } 🔒}$$
