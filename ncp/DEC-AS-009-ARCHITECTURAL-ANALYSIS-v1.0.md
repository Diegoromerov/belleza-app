# DEC-AS-009 — ANÁLISIS DE DISEÑO ARQUITECTÓNICO v1.0
## Assignment Validity & Lifecycle Semantics Analysis

**DECISION_ID:** `DEC-AS-009`  
**ESTADO:** `DEC-AS-009 — ANALYSIS COMPLETED — PENDING DIRECTOR DECISION 🟡`  
**TIPO:** Assignment Validity & Lifecycle Semantics Analysis  
**AUTORIDAD:** Director Arquitectónico del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `DEC-AS-009`  
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
**FECHA DE EMISIÓN:** 2026-09-10  

---

## 1. EXECUTIVE SUMMARY

El presente análisis técnico determina la **semántica de validez operacional y ciclo de vida** de la entidad `ASSIGNMENT` (`DEC-AS-006`), evaluando cómo impactan las mutaciones y transiciones de estado de la entidad objetivo `MEMBERSHIP` (Foundation `065`) sobre una asignación existente.

### 1.1. Pregunta Central de Investigación
> **¿Qué significa arquitectónicamente un `ASSIGNMENT` cuando el `MEMBERSHIP` objetivo:**
> A. Permanece `ACTIVE`?  
> B. Pasa a `SUSPENDED`?  
> C. Pasa a `REVOKED`?  
> D. Deja de existir físicamente?  
> E. Cambia de `ROLE`?  
> F. Deja de cumplir la condición `ACTIVE PROFESSIONAL CONTEXT`?

---

## 2. EVIDENCIA FÍSICA EXISTENTE EN FOUNDATION (`065`)

En la tabla `memberships` desplegada por `065_saas_foundation_core.sql`, existen las siguientes restricciones y estados demostrados:

```text
================================================================================
EVIDENCIA DE ESTADOS EN MEMBERSHIPS (065 CORE):

1. COLUMNA status:
   - Tipo: VARCHAR(30) NOT NULL DEFAULT 'ACTIVE'
   - Constraint: CHECK (status IN ('INVITED', 'ACTIVE', 'SUSPENDED', 'REVOKED'))

2. COLUMNA role:
   - Tipo: VARCHAR(50) NOT NULL
   - Constraint: CHECK (role IN ('OWNER', 'MANAGER', 'PROFESSIONAL', 'RECEPTIONIST'))

3. COLUMNA relation_type:
   - Tipo: VARCHAR(50) NOT NULL DEFAULT 'STAFF_EMPLOYEE'
   - Constraint: CHECK (relation_type IN ('OWNER_PARTNER', 'STAFF_EMPLOYEE', 'INDEPENDENT_PROVIDER'))

4. MARCAS TEMPORALES:
   - joined_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
   - revoked_at TIMESTAMPTZ NULL
================================================================================
```

---

## 3. MODELO DE VALIDEZ DE ASSIGNMENT (VALIDITY MODEL)

Para preservar la pureza relacional y evitar redundancias o desincronizaciones de estado, se formaliza la separación entre:

```text
================================================================================
SEPARACIÓN CONCEPTUAL: EXISTENCIA vs VALIDEZ OPERACIONAL

1. EXISTENCIA FÍSICA (ASSIGNMENT EXISTS):
   - Una tupla de asignación existe de forma durable en PostgreSQL vinculando
     (service_offer_id, membership_id, establishment_id, tenant_id).
   - Significa: "El establecimiento ha configurado a este colaborador para realizar este servicio".

2. VALIDEZ OPERACIONAL (ASSIGNMENT IS CURRENTLY VALID / OPERABLE):
   - Es una condición evaluada en tiempo de consulta / ejecución.
   - Requiere estrictamente que la tupla exista Y que la MEMBERSHIP objetivo
     cumpla la condición de dominio:
     
     ASSIGNMENT_VALID ◄══► (ASSIGNMENT_EXISTS ∧ MEMBERSHIP.status = 'ACTIVE' ∧ ROL_ELEGIBLE)
================================================================================
```

---

## 4. TRANSICIONES DE ESTADO DE MEMBERSHIP Y SU IMPACTO

Se analizan sistemáticamente los 6 escenarios planteados:

```text
| Escenario de Transición en MEMBERSHIP | ¿Existe el Registro ASSIGNMENT? | ¿Es Operacionalmente VÁLIDO? | Impacto Semántico y de Negocio |
| :--- | :---: | :---: | :--- |
| **A. Permanece `ACTIVE`** | **SÍ** | **SÍ** | Asignación plenamente válida, operable y agendable. |
| **B. Pasa a `SUSPENDED`** | **SÍ** | **NO** | La asignación permanece configurada pero entra en estado *inoperable temporal*. Si el profesional es reactivado (`status = 'ACTIVE'`), la validez se restablece automáticamente sin reconfigurar el catálogo. |
| **C. Pasa a `REVOKED`** | **SÍ** | **NO** | Contrato finalizado (`revoked_at`). La asignación queda inoperable. Su persistencia o eliminación física dependerá de las semánticas de borrado (`DELETE SEMANTICS = UNDEFINED`). |
| **D. Deja de existir (Físico)** | **NO** | **NO** | Supeditado a políticas de clave foránea física (`DEC-AS-008: ON DELETE = UNDEFINED`). |
| **E. Cambia de `ROLE`** | **SÍ** | **CONDICIONADO** | Si el nuevo rol conserva capacidad de prestación (e.g. `OWNER` que también atiende), es válido. Si cambia a rol administrativo puro sin atención (e.g. `RECEPTIONIST`), queda inoperable por dominio. |
| **F. Deja de cumplir condición PROFESSIONAL** | **SÍ** | **NO** | Deja de ser elegible para ejecución transaccional. |
```

---

## 5. EVALUACIÓN DE ALTERNATIVAS DE MODELO DE CICLO DE VIDA

```text
================================================================================
ALTERNATIVAS DE LIFECYCLE PARA ASSIGNMENT:

OPTION A: Validez Derivada Dinámica (Derived Validity - RECOMENDADA)
  - service_assignments no almacena columnas de estado.
  - La validez se deriva dinámicamente del estado actual de la MEMBERSHIP.

OPTION B: Eliminación / Mutación Destructiva ante Inactivación
  - El registro de asignación se destruye físicamente si status != 'ACTIVE'.

OPTION C: Lifecycle / Status Propio Embebido en ASSIGNMENT
  - service_assignments incorpora columna status ('ACTIVE', 'INACTIVE', 'SUSPENDED').
================================================================================
```

### 5.1. Option A — Validez Derivada Dinámica (Recomendada)
- **Semántica:** La existencia del registro representa la configuración estructural del salón. La validez operativa se deriva evaluando `membership.status = 'ACTIVE'` en tiempo de consulta.
- **Ventajas:**
  1. **Cero Redundancia:** No duplica los estados de `memberships` en la tabla de asignaciones.
  2. **Cero Riesgo de Desincronización:** Imposible que una membresía esté en `REVOKED` y su asignación figure en `ACTIVE`.
  3. **Resiliencia ante Suspensiones Temporales:** Si un profesional se suspende por vacaciones o incapacidad (`SUSPENDED`), sus servicios quedan automáticamente no disponibles; al reactivarlo (`ACTIVE`), todo su catálogo asignado vuelve a operar de inmediato sin requerir re-asignación manual.
  4. **Simplicidad y Economía:** La tabla `service_assignments` se mantiene con sus 5 columnas mínimas (`DEC-AS-008`).
- **Desventajas:** Las consultas operativas de catálogo asignado deben incluir la condición `memberships.status = 'ACTIVE'` en el `JOIN` o `WHERE`.

### 5.2. Option B — Eliminación / Mutación Destructiva ante Inactivación
- **Semántica:** Si una membresía deja de ser `ACTIVE`, se borran físicamente sus asignaciones.
- **Desventajas Críticas:** Destructivo. Una suspensión temporal de 2 días destruiría todas las asignaciones del colaborador, forzando al administrador a reasignar uno a uno todos los servicios al reactivarlo. Antipatrón operativo.

### 5.3. Option C — Lifecycle / Status Propio Embebido en ASSIGNMENT
- **Semántica:** Agregar columna `status` a `service_assignments`.
- **Desventajas Críticas:** Introduce estados sintéticos no demostrados, duplica estados y requiere workers o triggers para sincronizar `assignment.status` con `membership.status`.

---

## 6. MATRIZ COMPARATIVA DE ALTERNATIVAS

| Criterio de Evaluación | Option A (Validez Derivada Dinámica) | Option B (Mutación Destructiva) | Option C (Status Propio Embebido) |
| :--- | :--- | :--- | :--- |
| **Consistencia con DEC-AS-006** | **ÓPTIMA** (`status = ACTIVE` es condición de dominio) | **DEFICIENTE** | **REGULAR** (Crea estados sintéticos)|
| **Riesgo de Desincronización** | **NULO** (Fuente única de verdad en `065`)| **MEDIO** | **ALTO** (Inconsistencia de doble status)|
| **Soporte de Suspensión Temporal**| **ÓPTIMA** (Reversible sin pérdida de config)| **INVIABLE** (Destruye la configuración)| **MEDIA** (Requiere actualizar N filas)|
| **Simplicidad de Esquema** | **ÓPTIMA** (5 columnas mínimas de `DEC-AS-008`)| **MEDIA** | **DEFICIENTE** (Campos y enums extra) |
| **Impacto sobre Integridad Referencial**| **NULO** (Protegido por FKs de `DEC-AS-007`) | **ALTO** (Cascadas continuas) | **NULO** |
| **Economía y Mantenibilidad** | **ÓPTIMA** | **DEFICIENTE** | **DEFICIENTE** |

---

## 7. ARQUITECTURA RECOMENDADA (`PROPUESTA — NO APROBADA`)

> [!IMPORTANT]
> **PROPUESTA TÉCNICA — NO APROBADA — REQUIERE DECISIÓN FORMAL DEL DIRECTOR**

Se recomienda al Director adoptar el **Modelo de Validez Derivada Dinámica (Option A)**:

```text
================================================================================
MODELO DE VALIDEZ Y LIFECYCLE RECOMENDADO (PROPUESTA — NO APROBADA):

1. ESTRUCTURA FÍSICA:
   - service_assignments permanece con la estructura mínima de 5 columnas (DEC-AS-008).
   - NO se agrega columna de status ni campos transicionales a service_assignments.

2. REGLA DE EXISTENCIA:
   - ASSIGNMENT EXISTS = Vínculo durable configurado entre SERVICE_OFFER y MEMBERSHIP.
   - NO ASSIGNMENT = Inexistencia de la tupla relacional.

3. REGLA DE VALIDEZ OPERACIONAL:
   - Una asignación existente es OPERACIONALMENTE VÁLIDA si y solo si:
     MEMBERSHIP.status = 'ACTIVE' (en Foundation 065).
   - Si MEMBERSHIP pasa a 'SUSPENDED' o 'REVOKED', la asignación se torna
     automática e inmediatamente INOPERABLE sin mutar la tabla service_assignments.
   - Si MEMBERSHIP retorna a 'ACTIVE', la asignación recupera su validez de inmediato.
================================================================================
```

---

## 8. DECISIONES ABIERTAS PRESERVADAS (OPEN DECISIONS)

El presente análisis preserva formalmente todas las decisiones abiertas del sistema:

```text
| Dimensión / Decisión            | Estado Epistemológico               |
| ------------------------------- | ----------------------------------- |
| ASSIGNMENT Cardinality          | UNDEFINED (Neutral a 1:1, 1:N, N:M) |
| ASSIGNMENT Delete Semantics     | UNDEFINED (Políticas ON DELETE)     |
| ASSIGNMENT Audit Attributes     | UNDEFINED (created_at, etc.)        |
| ASSIGNMENT Physical Table Name  | UNDEFINED (Nombre definitivo)       |
| ASSIGNMENT Workflow UI/API      | UNDEFINED                           |
| MATERIALIZATION Implementation  | UNDEFINED (Downstream desacoplado)  |
| PUBLICATION Workflow / Flags    | NOT PRESENT / NOT USED              |
| PHYSICAL IMPLEMENTATION AUTH    | NONE (ZERO CODE / ZERO DDL)         |
```

---

## 9. FRONTERA DE IMPLEMENTACIÓN (IMPLEMENTATION BOUNDARY)

- **Cero Código:** Prohibida la creación o edición de código en `backend/src/`.
- **Cero Migraciones / DDL:** Prohibida la creación de archivos SQL en `backend/migrations/` o ejecución de DDL.
- **Cero Mutaciones:** Cero modificaciones de datos en PostgreSQL.
- **Inmutabilidad de Contratos:** `Foundation (065/066)`, `CDC`, `HBC`, `NODO-01`, `DEC-SE-001/002`, `DEC-AS-001/002/003/005/006/007/008` permanecen 100% protegidos.

---

## 10. CONDICIONES DE PARADA ARQUITECTÓNICA (ARCHITECTURAL STOP)

$$\mathbf{STOP \ ARQUITECTONICO: \ ANALISIS \ DEC\text{-}AS\text{-}009 \ COMPLETADO}$$

El análisis de validez y ciclo de vida de `ASSIGNMENT` queda formalizado y listo para la evaluación del Director.

---

## 11. ESTADO FINAL DEL ENTREGABLE

$$\text{ESTADO: } \mathbf{DEC\text{-}AS\text{-}009 \text{ — ANALYSIS COMPLETED — PENDING DIRECTOR DECISION } \odot}
