# DEC-AS-013-B — ANÁLISIS DE REPRESENTACIÓN DE ACTOR v1.0
## Assignment Actor Representation Decision Analysis

**DECISION_ID:** `DEC-AS-013-B`  
**ESTADO:** `DEC-AS-013-B — ANALYSIS COMPLETED — PENDING DIRECTOR DECISION 🟡`  
**TIPO:** Architectural Actor Representation & Audit Attribute Analysis  
**AUTORIDAD:** Director Arquitectónico del Proyecto GlowApp SaaS  
**GOALS ORIGEN:** `DEC-AS-013` / `DEC-AS-013-R1` / `DEC-AS-013-002` / `DEC-AS-013-003` / `DEC-AS-013-B`  
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
- `DEC-AS-013-DECISION-RECORD-v1.0.md` (Assignment Audit Attributes ADR)  
**FECHA DE ANÁLISIS:** 2026-09-10  

---

## 1. ARCHITECTURAL QUESTION (PREGUNTA ARQUITECTÓNICA)

Cuando un `OWNER` o `MANAGER` ejecuta una asignación de `SERVICE_OFFER` a `MEMBERSHIP` bajo la autoridad canónica de `DEC-AS-001`:

$$\mathbf{¿Qué \ entidad \ conceptual \ debe \ representar \ al \ actor \ que \ ejecutó \ la \ acción?}$$

El presente análisis evalúa rigurosamente las siguientes alternativas conceptuales:
- **Opción A:** `USER / PERSON` (Sujeto humano o cuenta autenticada).
- **Opción B:** `MEMBERSHIP` (Contexto administrativo y mandato de autoridad en la sede).
- **Opción C:** `USER + MEMBERSHIP` (Doble referencia persistida).
- **Opción D:** `OTRO CONCEPTO` (Delegación, rol abstracto o token).
- **Opción E:** `NINGUNO EN LA RELACIÓN ACTIVA` (Actoría 100% confinada a `AUDIT HISTORY`).

---

## 2. EVIDENCE (EVIDENCIA ARQUITECTÓNICA Y DE CÓDIGO)

### 2.1. Evidencia en SaaS Foundation Core (`065_saas_foundation_core.sql`)

```text
===============================================================================
EVIDENCIA DE ACTORÍA Y AUDITORÍA EN FOUNDATION 065:

1. TABLAS NUCLEARES (organizations, establishments, memberships):
   - Cero columnas "created_by", "created_by_user", "created_by_membership"
     en todo el esquema de Foundation 065.
   - Las tablas registran timestamps técnicos (created_at, updated_at) y
     momentos de dominio (joined_at, revoked_at), pero NO almacenan la
     identidad del usuario que ejecutó el DML.

2. TABLA memberships:
   - Vincula: user_id (INTEGER) + establishment_id (UUID) + tenant_id (INTEGER).
   - Define: role ('OWNER', 'MANAGER', 'PROFESSIONAL', 'RECEPTIONIST').
   - Invariante: Un usuario físico sólo puede actuar sobre un establecimiento
     a través de una MEMBERSHIP activa (065).
===============================================================================
```

### 2.2. Evidencia en Middleware de Contexto (`066` / `activeContextMiddleware.js`)

```javascript
// Evidencia en runtime:
// req.user (Sujeto autenticado: user_id)
// req.activeContext (Contexto verificado: tenant_id, establishment_id, membership_id, role)
```

1. La autorización en tiempo de ejecución exige la presencia coordinada de **ambos** componentes:
   $$\text{Usuario Autenticado} \land \text{Membresía Activa con Rol } \in \{\text{OWNER}, \text{MANAGER}\} \land \text{Sede Coincidente}$$
2. La autorización es transaccional y efímera: evalúa la capacidad de actuar en el instante $t_0$.

---

## 3. CURRENT CLOSED DECISIONS (MARCO DE AUTORIDAD CERRADO)

```text
===============================================================================
CADENA DE AUTORIDAD CERRADA APLICABLE:

DEC-AS-001  ──► Autoridad de asignación: ACTIVE USER + ACTIVE MEMBERSHIP + 
                 ROLE ∈ {OWNER, MANAGER} en active context verificado.
DEC-AS-006  ──► ASSIGNMENT es entidad física independiente; Target = MEMBERSHIP.
DEC-AS-008  ──► Identidad propia de ASSIGNMENT; desacoplada de actores.
DEC-AS-009  ──► Sin status propio; validez derivada de MEMBERSHIP.
DEC-AS-012  ──► DELETE ASSIGNMENT = PURE UNASSIGNMENT.
DEC-AS-013-A──► Sin assigned_at independiente. Marca de creación conceptualmente OK.
DEC-AS-013-B──► created_by permanece OPEN / UNDEFINED (Sujeto vs Contexto).
DEC-AS-013-F──► AUDIT HISTORY es conceptualmente independiente de ASSIGNMENT.
===============================================================================
```

---

## 4. SUBJECT VS IDENTITY VS CONTEXT (DISTINCIONES OBLIGATORIAS)

Para evitar colapsar conceptos distintos en una sola columna, se formaliza la separación de las 5 dimensiones del acto de asignación:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. SUJETO HUMANO / PERSONA                                                 │
│    • El individuo biológico que tomó la decisión y ejecutó la acción.       │
│    • Entidad de Dominio: Persona física asociada a la cuenta.              │
├─────────────────────────────────────────────────────────────────────────────┤
│ 2. IDENTIDAD / CUENTA AUTENTICADA (USER)                                   │
│    • La cuenta de usuario del sistema (usuarios.id / auth principal).      │
│    • Global al Tenant. No vinculada por sí sola a una sede específica.     │
├─────────────────────────────────────────────────────────────────────────────┤
│ 3. CONTEXTO ADMINISTRATIVO DE AUTORIDAD (MEMBERSHIP)                        │
│    • La relación formal entre el Usuario y el Establecimiento (065).       │
│    • Porta el Rol (OWNER / MANAGER) que legitimó jurídicamente la acción.  │
├─────────────────────────────────────────────────────────────────────────────┤
│ 4. ESTABLECIMIENTO ACTIVO (TARGET ESTABLISHMENT)                            │
│    • La unidad de negocio sobre la que se genera la oferta y la asignación. │
│    • Ya está presente en ASSIGNMENT como contexto de integridad (DEC-007). │
├─────────────────────────────────────────────────────────────────────────────┤
│ 5. AUDIT HISTORY                                                            │
│    • El registro histórico desacoplado de eventos y trazabilidad (DEC-013-F)│
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.1. Distinción Fundamental de Preguntas
- **Pregunta A (Sujeto / Autor):** *"¿Quién (qué persona física o cuenta) ejecutó este cambio?"*  
  $\rightarrow$ Responde a la rendición de cuentas personal y trazabilidad forense.
- **Pregunta B (Contexto / Legitimidad):** *"¿Desde qué cargo, mandato o membresía tenía autorización para ejecutarlo?"*  
  $\rightarrow$ Responde a la gobernanza institucional y validez del acto administrativo.

---

## 5. EVALUACIÓN DE ALTERNATIVAS CONCEPTUALES

---

### 5.1. Opción A — USER / PERSON como Actor (`created_by = user_id`)

- **Definición:** La tupla de asignación almacena una referencia directa a la cuenta de usuario (`user_id`) que originó la creación.
- **Ventajas:**
  1. **Inmutabilidad Personal:** El identificador del usuario persiste inalterado aun si la persona es transferida, suspendida o desvinculada del establecimiento.
  2. **Simplicidad Forense:** Responde directamente a la pregunta: *"¿Quién hizo esto?"*.
- **Limitaciones:**
  1. **Desconexión de Mandato:** No evidencia por sí solo desde qué membresía o rol se actuó si el usuario posee múltiples roles o membresías en el tenant.
  2. **Ruptura de Coherencia de Sede:** `usuarios` es una entidad a nivel de Tenant, no de Establecimiento.

---

### 5.2. Opción B — MEMBERSHIP como Actor (`created_by = membership_id`)

- **Definición:** La tupla de asignación almacena una referencia a la `MEMBERSHIP` desde la cual se invocó la operación.
- **Ventajas:**
  1. **Trazabilidad de Mandato Completa:** Captura simultáneamente el usuario (`membership.user_id`), el rol (`membership.role`) y la sede (`membership.establishment_id`).
  2. **Alineación con Foundation 065 y DEC-AS-001:** La autoridad para asignar emana estrictamente de una membresía activa (`OWNER`/`MANAGER`).
  3. **Coherencia Referencial Triple:** Comparte el mismo `establishment_id` y `tenant_id` de la asignación.
- **Limitaciones:**
  1. **Dependencia de Ciclo de Vida:** Si la membresía del administrador llega a ser revocada en el futuro (`status = 'REVOKED'`), la FK sigue existiendo pero representa un vínculo inactivo.

---

### 5.3. Opción C — USER + MEMBERSHIP (`created_by_user` + `created_by_membership`)

- **Definición:** Persistir ambas referencias simultáneamente en la tupla activa.
- **Evaluación:**
  - Puesto que en Foundation `065` cada `MEMBERSHIP` posee ya un `user_id` inmutable y unívoco (`UNIQUE (establishment_id, user_id)`), almacenar ambos en la tupla activa constituye **duplicidad estructural innecesaria**.
  - No aporta información semántica adicional sobre la relación activa.

---

### 5.4. Opción D / E — NINGUNO EN LA RELACIÓN ACTIVA (Actoría 100% en Audit History)

- **Definición:** La relación `ASSIGNMENT` activa contiene exclusivamente su estructura nuclear (5 conceptos relacionales: `id`, `offer`, `member`, `establishment`, `tenant`) y su marca temporal básica de creación (`created_at`), confinando el registro del autor al subsistema independiente de **`AUDIT HISTORY`**.
- **Ventajas:**
  1. **Coherencia Total con Foundation 065:** Idéntico al estándar de `organizations`, `establishments` y `memberships`, donde ninguna tabla persiste `created_by`.
  2. **Pureza Operacional:** La entidad de asignación permanece liviana y desacoplada de metadatos de autoría que no intervienen en el motor de agendamiento.
  3. **Inmunidad ante Cambios de Personal:** No genera dependencias referenciales adicionales en la tabla activa ante la rotación de administradores.
- **Limitaciones:**
  - Requiere consultar el log de auditoría histórica para auditorías administrativas directas.

---

## 6. COMPARATIVA DE OPCIONES DE ACTORÍA

| Criterio de Evaluación | Opción A (USER) | Opción B (MEMBERSHIP) | Opción C (USER + MEMB) | Opción E (Audit History 100%) |
| :--- | :--- | :--- | :--- | :--- |
| **Responde "¿Quién?"** | **ÓPTIMA** (Directo) | **ÓPTIMA** (Vía membership) | **ÓPTIMA** (Redundante) | **ÓPTIMA** (Vía History) |
| **Responde "¿Bajo qué cargo/mandato?"** | **DEFICIENTE** | **ÓPTIMA** (Captura Rol) | **ÓPTIMA** | **ÓPTIMA** (Vía History) |
| **Coherencia con Foundation 065** | **REGULAR** (065 no usa) | **REGULAR** (065 no usa)| **DEFICIENTE** | **ÓPTIMA** (Estándar 065) |
| **Integridad de Sede (DEC-007)** | **MEDIA** (Global Tenant) | **ÓPTIMA** (Misma Sede) | **ÓPTIMA** | **ÓPTIMA** (Desacoplado) |
| **Simplicidad de la Relación Core** | **MEDIA** (+1 FK) | **MEDIA** (+1 FK) | **BAJA** (+2 FKs) | **ÓPTIMA** (Core Puro) |

---

## 7. AUDIT HISTORY RELATIONSHIP (RELACIÓN CON AUDIT HISTORY)

Conforme a `DEC-AS-013-F`, el historial de auditoría es **conceptualmente independiente de ASSIGNMENT**:

```text
===============================================================================
SEPARACIÓN DE RESPONSABILIDADES:

1. RELACIÓN ACTIVA (ASSIGNMENT):
   - Rol: Estado operativo durable para catálogo, agendamiento y disponibilidad.
   - Requerimiento: Conocer qué oferta está asignada a qué profesional en qué sede.
   - Atributo de Autoría: Opcional / No crítico para la operación de negocio.

2. HISTORIAL DE AUDITORÍA (AUDIT HISTORY):
   - Rol: Trazabilidad inmutable de eventos administrativos y forenses.
   - Requerimiento: Registrar quién (User), con qué mandato (Membership/Rol),
     cuándo (Timestamp), qué asignó/desasignó y desde qué contexto.
   - Atributo de Autoría: OBLIGATORIO Y EXHAUSTIVO.
===============================================================================
```

---

## 8. RECOMMENDATION — PROPOSAL / NOT APPROVED

> [!IMPORTANT]
> **PROPUESTA ARQUITECTÓNICA — NO APROBADA — REQUIERE DECISIÓN FORMAL DEL DIRECTOR**

Se somete a la evaluación y decisión del Director la siguiente recomendación estructurada:

### 8.1. Recomendación Conceptual Principal
1. **Si el Director decide NO persistir actoría en la relación activa:**  
   - Adoptar la **Opción E (Alineación Estricta Foundation 065)**: La tabla activa de `ASSIGNMENT` no almacena columna de autor (`created_by`), delegando la captura del autor (`user_id` + `membership_id`) al subsistema independiente de **`AUDIT HISTORY`**.
2. **Si el Director decide persistir actoría en la relación activa como metadato de conveniencia:**  
   - Adoptar la **Opción B (`created_by = membership_id`)**: Almacenar la referencia a la `MEMBERSHIP` administradora que autorizó la acción, por ser la entidad que vincula simultáneamente al sujeto humano, al rol (`OWNER`/`MANAGER`) y a la sede bajo la autoridad canónica de `DEC-AS-001`.
3. **Descartar formalmente:**
   - La Opción C (`USER + MEMBERSHIP`) por duplicidad innecesaria.

---

## 9. EPISTEMOLOGICAL MATRIX (MATRIZ EPISTEMOLÓGICA)

```text
| Dimensión / Atributo            | Estado Epistemológico Canónico                              |
| ------------------------------- | ----------------------------------------------------------- |
| ASSIGNMENT Cardinality          | CLOSED: N:M (DEC-AS-010)                                    |
| ASSIGNMENT Relation Uniqueness  | CLOSED — MÁXIMO UNA RELACIÓN SIMULTÁNEA POR PAR (DEC-AS-011) |
| ASSIGNMENT Lifecycle            | CLOSED — DERIVED VALIDITY (DEC-AS-009)                      |
| ASSIGNMENT Delete Semantics     | CLOSED CONCEPTUALLY — PURE UNASSIGNMENT (DEC-AS-012)         |
| Core Relation Attributes        | CONCEPTUALLY DEFINED — PHYSICAL MATERIALIZATION PENDING     |
| DEC-AS-013-A (assigned_at)      | CLOSED: NO REQUERIDO / CREACIÓN TEMPORAL CONCEPTUALMENTE OK |
| DEC-AS-013-B (Actor Model)      | PROPOSAL: EVALUACIÓN OPCIÓN E (065) vs OPCIÓN B (MEMBERSHIP)|
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
```

---

## 10. OPEN QUESTIONS (PREGUNTAS ABIERTAS PARA EL DIRECTOR)

Para la resolución final de `DEC-AS-013-B`, se elevan las siguientes cuestiones de diseño al Director:

1. **¿Debe la relación activa contener un puntero al autor (`created_by`), o debe seguir la convención pura de Foundation `065` donde toda autoría reside en `AUDIT HISTORY`?**
2. **En caso de incluirse en la relación activa, ¿confirma el Director que `MEMBERSHIP` (Opción B) es la entidad que captura el mandato y autoridad requerida por `DEC-AS-001`?**

---

## 11. IMPLEMENTATION BOUNDARY (FRONTERA DE IMPLEMENTACIÓN)

- **Cero Código:** Prohibida la modificación o creación de código en `backend/src/`.
- **Cero DDL / Migraciones:** Prohibida la creación de scripts SQL en `backend/migrations/` o ejecución DDL.
- **Cero Mutaciones de Base de Datos:** Base de datos PostgreSQL intacta.
- **Inmutabilidad de Contratos:** `Foundation (065/066)`, `CDC`, `HBC`, `NODO-01`, `DEC-SE-001/002`, `DEC-AS-001..013` permanecen 100% protegidos.

---

## 12. ARCHITECTURAL STOP

$$\mathbf{STOP \ ARQUITECTONICO: \ ANALISIS \ DEC\text{-}AS\text{-}013\text{-}B \ COMPLETADO}$$

El análisis técnico de representación de actor para `DEC-AS-013-B` queda formalizado y listo para la decisión final del Director.

---

## 13. ESTADO FINAL DEL ENTREGABLE

$$\text{ESTADO: } \mathbf{DEC\text{-}AS\text{-}013\text{-}B \text{ — ANALYSIS COMPLETED — PENDING DIRECTOR DECISION } \odot}$$
