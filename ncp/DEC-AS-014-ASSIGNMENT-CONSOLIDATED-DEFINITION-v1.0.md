# DEC-AS-014 — DEFINICIÓN ARQUITECTÓNICA CONSOLIDADA v1.0
## Assignment Consolidated Architectural Definition

**DECISION_ID:** `DEC-AS-014`  
**ESTADO:** `APPROVED / CONSOLIDATED DEFINITION — CONSISTENCY PASS 🔒`  
**TIPO:** Consolidated Architectural Domain Definition & Consistency Synthesis  
**AUTORIDAD:** Director Arquitectónico del Proyecto GlowApp SaaS  
**GOALS ORIGEN:** `DEC-AS-001` a `DEC-AS-013` / `DEC-AS-014`  
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
- `DEC-AS-007-ARCHITECTURAL-ANALYSIS-v1.0.md` (Composite Referential Integrity)  
- `DEC-AS-008-ARCHITECTURAL-ANALYSIS-v1.0.md` (Assignment Identity Model)  
- `DEC-AS-009-ARCHITECTURAL-ANALYSIS-v1.0.md` (Derived Validity Semantics)  
- `DEC-AS-010-ARCHITECTURAL-ANALYSIS-v1.0.md` (Cardinality Model Analysis)  
- `DEC-AS-011-ARCHITECTURAL-ANALYSIS-v1.0.md` (Relation Multiplicity Analysis)  
- `DEC-AS-012-ARCHITECTURAL-ANALYSIS-v1.0.md` (Assignment Delete Semantics)  
- `DEC-AS-013-DECISION-RECORD-v1.0.md` (Assignment Audit Attributes Decision Record)  

---

## 1. PURPOSE (PROPÓSITO)

El propósito de este documento es construir y consolidar la **Definición Canónica y Arquitectónica del Dominio ASSIGNMENT** en el ecosistema SaaS GlowApp, sintetizando exclusivamente las 17 decisiones previamente aprobadas y cerradas por la Dirección (`DEC-AS-001` hasta `DEC-AS-013-F`).

Este documento:
1. Responde de forma exhaustiva e inequívoca las 16 preguntas fundamentales de dominio sobre `ASSIGNMENT`.
2. Establece el modelo conceptual y sus fronteras exactas frente a B2C, auditoría, y capas físicas.
3. Ejecuta la prueba formal de consistencia lógica entre todas las decisiones cerradas.
4. Mantiene la política estricta de CERO mutaciones, cero DDL y cero implementación en runtime.

---

## 2. DEFINITION OF ASSIGNMENT (DEFINICIÓN DE ASSIGNMENT)

> **ASSIGNMENT** es una relación asociativa, durable e independiente dentro del contexto de una sede (`ESTABLISHMENT`) perteneciente a un `TENANT`, que vincula a una oferta de servicio (`SERVICE_OFFER`) con un miembro del equipo operativo (`MEMBERSHIP`), confiriendo la capacidad operativa para que dicho profesional preste dicho servicio en dicha sede.

### Diagrama de Jerarquía y Aislamiento Conceptual:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       TENANT (Aislamiento Transversal)                      │
│                                                                             │
│   ESTABLISHMENT                                                             │
│         │                                                                   │
│         ├── SERVICE_OFFER                                                   │
│         │                                                                   │
│         └── MEMBERSHIP                                                      │
│                 │                                                           │
│                 └── PROFESSIONAL CONTEXT                                    │
│                                                                             │
│                                                                             │
│   SERVICE_OFFER                                                             │
│         ↕                                                                   │
│     ASSIGNMENT (Relación Durable e Independiente)                           │
│         ↕                                                                   │
│   MEMBERSHIP                                                                │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. WHAT ASSIGNMENT IS (QUÉ ES ASSIGNMENT)

1. **Estado Durable en SaaS (`DEC-AS-002`):** Es una entidad/relación persistente en la capa SaaS de GlowApp que sobrevive al ciclo de vida del request.
2. **Vínculo Contextual Directo (`DEC-AS-006`):** Es la conexión explícita entre un `SERVICE_OFFER` de sede y una `MEMBERSHIP` activa de dicha sede.
3. **Capacidad Operativa Interna:** Es la declaración formal en el SaaS de que un profesional está habilitado para realizar un servicio determinado en una sede específica.
4. **Relación M:N Multi-servicio y Multi-profesional (`DEC-AS-010`):** Permite que múltiples profesionales presten el mismo servicio y que un profesional preste múltiples servicios.
5. **Entidad con Identidad Propia (`DEC-AS-008`):** Posee identidad conceptual propia e independiente de las entidades que vincula.

---

## 4. WHAT ASSIGNMENT IS NOT (QUÉ NO ES ASSIGNMENT)

1. **NO es un atributo embebido de `SERVICE_OFFER` (`DEC-AS-005`):** `SERVICE_OFFER` no contiene listas o IDs de profesionales dentro de su registro.
2. **NO es un atributo embebido de `MEMBERSHIP` (`DEC-AS-006`):** `MEMBERSHIP` no contiene listas de servicios asignados dentro de su registro.
3. **NO es una relación con el `USER` global (`DEC-AS-006`):** El target es estrictamente `MEMBERSHIP` (contextual a la sede), no el usuario global.
4. **NO es una máquina de estados con status propio (`DEC-AS-009`):** No posee columna `status` ni estados como `ACTIVE`, `PENDING` o `REVOKED`.
5. **NO es materialización B2C (`DEC-SE-001`, `DEC-AS-003`):** No crea registros en `public.services` ni representa un servicio final publicado al consumidor.
6. **NO es publicación ni disponibilidad (`DEC-PUB-001`, `DEC-SE-002`):** No define horarios de agenda ni publica automáticamente en marketplaces externos.
7. **NO es el registro de auditoría (`DEC-AS-013-B`, `DEC-AS-013-F`):** No es el log histórico de quién asignó ni cuándo se desasignó.

---

## 5. RELATIONSHIP MODEL (MODELO RELACIONAL)

### Entidades que Relaciona:
- **`SERVICE_OFFER` (Origen del Servicio en Sede):** Oferta de servicio perteneciente al `ESTABLISHMENT`.
- **`MEMBERSHIP` (Destino Profesional en Sede):** Vínculo contractual/operativo del profesional con el `ESTABLISHMENT`.

### Coherencia Compuesta y Aislamiento (`DEC-AS-007`):
Toda asignación exige que `SERVICE_OFFER` y `MEMBERSHIP` pertenezcan rigurosamente al **mismo `tenant_id`** y al **mismo `establishment_id`**. El aislamiento transversal del `TENANT` garantiza que no existan cruces inter-tenant ni asignaciones cruzadas entre sedes distintas.

---

## 6. IDENTITY (IDENTIDAD CONCEPTUAL)

- **Identidad Propia (`DEC-AS-008`):** `ASSIGNMENT` posee identidad conceptual propia (distinta de la clave compuesta de sus miembros), garantizando estabilidad referencial, desacoplamiento de auditoría y neutralidad física.
- **5 Dimensiones Conceptuales del Núcleo:**
  1. Identidad Propia (`id`)
  2. Referencia a Oferta de Servicio (`service_offer_id`)
  3. Referencia a Membresía Profesional (`membership_id`)
  4. Contexto de Sede (`establishment_id`)
  5. Contexto de Tenant (`tenant_id`)

---

## 7. CARDINALITY (CARDINALIDAD Y UNICIDAD)

- **Cardinalidad $N:M$ Bidireccional (`DEC-AS-010`):**
  - Un `SERVICE_OFFER` puede relacionarse con $N$ `MEMBERSHIP`s en la misma sede.
  - Una `MEMBERSHIP` puede relacionarse con $M$ `SERVICE_OFFER`s en la misma sede.
- **Unicidad de la Relación (`DEC-AS-011`):**
  - Para un par dado `(SERVICE_OFFER, MEMBERSHIP)`, existe como máximo **una ($1$) relación Assignment simultánea representativa**.
  - No coexisten asignaciones duplicadas para el mismo profesional y el mismo servicio en la misma sede.

---

## 8. VALIDITY (VALIDEZ Y VIGENCIA OPERATIVA)

- **Validez Derivada (`DEC-AS-009`):**
  - `ASSIGNMENT` es operativamente válido si y solo si la `MEMBERSHIP` asociada se encuentra en estado activo:
    $$\text{ASSIGNMENT es OPERATIVAMENTE VÁLIDO} \iff \text{MEMBERSHIP.status} = \text{'ACTIVE'}$$
- **Pérdida de Vigencia Operativa:**
  - Una asignación deja de ser operativamente válida de forma dinámica en tiempo real cuando `MEMBERSHIP.status` transiciona a un estado no activo (`SUSPENDED`, `TERMINATED`, `INACTIVE`), sin requerir mutación en la entidad `ASSIGNMENT`.

---

## 9. AUTHORIZATION (AUTORIDAD Y GOBERNANZA)

Para crear o eliminar una asignación (`DEC-AS-001`), el actor solicitante debe satisfacer la regla estricta de autoridad en runtime:
$$\text{AUTORIDAD} = \begin{cases}
\text{ACTIVE USER autenticado} \\
+ \\
\text{MEMBERSHIP activa del actor en la sede objetivo} \\
+ \\
\text{ROLE} \in \{\text{'OWNER'}, \text{'MANAGER'}\} \\
+ \\
\text{ACTIVE CONTEXT válido en runtime} \\
+ \\
\text{TARGET ESTABLISHMENT} == \text{ACTIVE ESTABLISHMENT}
\end{cases}$$

---

## 10. DELETION SEMANTICS (SEMÁNTICA DE BORRADO)

- **Semántica Aprobada (`DEC-AS-012`, `DEC-AS-013-C`):**  
  $$\text{DELETE ASSIGNMENT} = \text{DESASIGNACIÓN PURA}$$
- **Qué Ocurre:**
  - Se elimina exclusivamente el vínculo `ASSIGNMENT` entre el servicio y el miembro.
- **Qué NO Ocurre (Cero Efectos Colaterales):**
  - NO se elimina `SERVICE_OFFER`.
  - NO se elimina `MEMBERSHIP`.
  - NO se modifica `membership.status`.
  - NO se materializa ni muta B2C (`public.services`).
  - NO se crean estados de revocado (`REVOKED`).

---

## 11. MATERIALIZATION BOUNDARY (FRONTERA DE MATERIALIZACIÓN B2C)

- **Desacoplamiento Estricto (`DEC-SE-001`, `DEC-AS-003`, `DEC-PUB-001`):**
  - `ASSIGNMENT` pertenece 100% a la gobernanza interna del **SaaS B2B**.
  - La creación o existencia de una asignación **NO implica materialización automática** en el marketplace B2C (`public.services`).
  - La materialización downstream es un proceso desacoplado que requiere **autorización explícita**.

---

## 12. ACTOR / AUDIT BOUNDARY (FRONTERA DE ACTORÍA Y AUDITORÍA)

- **Actoría Fuera del Core (`DEC-AS-013-B`):**
  - El actor que ejecutó la acción (`created_by`, `user_id` del administrador) **NO forma parte del núcleo de ASSIGNMENT**.
- **Independencia de Audit History (`DEC-AS-013-F`):**
  - `AUDIT HISTORY` es un subsistema conceptualmente independiente y desacoplado del core relacional.
  - Los datos de auditoría histórica (quién autorizó, cuándo, eventos de ciclo de vida) pertenecen a la capa de trazabilidad.

---

## 13. CONSOLIDATED DECISION MATRIX (MATRIZ CONSOLIDADA DE DECISIONES)

| Decision ID | Dimensión | Decisión Canónica Cerrada | Racional & Fundamento |
| :--- | :--- | :--- | :--- |
| **DEC-AS-001** | Autoridad de Asignación | `OWNER` / `MANAGER` en contexto activo de la misma sede | Seguridad y gobernanza en runtime (`066`) |
| **DEC-AS-002** | Durabilidad de Estado | `DURABLE SAAS STATE` (sobrevive al request) | Requerimiento de persistencia SaaS |
| **DEC-AS-003** | Trigger Materialización | `EXPLICIT AUTHORIZATION` (no automático) | Desacoplamiento B2B SaaS vs B2C Marketplace |
| **DEC-AS-005** | Service Offer Identity | UUID propio + Ownership directo en `ESTABLISHMENT` | Catálogo centralizado de sede sin provider embebido |
| **DEC-AS-006** | Assignment Physical Model | Entidad independiente; target = `MEMBERSHIP` | Independencia relacional y personal contextual |
| **DEC-AS-007** | Integridad Referencial | Coherencia compuesta `tenant_id + establishment_id` | Aislamiento estricto multi-tenant (Foundation `065`)|
| **DEC-AS-008** | Identidad de Assignment | Identidad propia (materialización pendiente) | Estabilidad, desacoplamiento y neutralidad DDL |
| **DEC-AS-009** | Validez y Lifecycle | Sin status propio; validez derivada de `MEMBERSHIP` | Estado de personal gobierna operatividad |
| **DEC-AS-010** | Cardinalidad | Relación $N:M$ bidireccional | Flexibilidad de asignación de servicios |
| **DEC-AS-011** | Unicidad de Relación | Máximo 1 relación simultánea por par $(S, M)$ | Evitar duplicidad de asignaciones activas |
| **DEC-AS-012** | Semántica de Borrado | `DELETE ASSIGNMENT = PURE UNASSIGNMENT` | Desvinculación limpia sin efectos colaterales |
| **DEC-AS-013-A**| Temporalidad | No se requiere `assigned_at`. Marca creación OK | Sin divergencia de vigencias en SaaS GlowApp |
| **DEC-AS-013-B**| Actoría | `created_by` NO forma parte del Core Assignment | Separación estricta entre core y auditoría |
| **DEC-AS-013-C**| Atributos Desasignación | Sin status `REVOKED`; `revoked_at/by` inaplicables | Coherente con validez derivada y desasignación pura|
| **DEC-AS-013-D**| Mutabilidad | `updated_at` NO es requerimiento de dominio | Relación es asociativa inmutable |
| **DEC-AS-013-E**| Motivo / Razón | `reason` = No requerido en el dominio actual | Cero evidencia en contratos de negocio |
| **DEC-AS-013-F**| Historial de Auditoría | `AUDIT HISTORY` conceptualmente independiente | Desacoplamiento de subsistema de trazabilidad |

---

## 14. CONSISTENCY TEST (PRUEBA DE CONSISTENCIA CRUZADA)

A continuación se evalúa de manera individual cada decisión frente al cuerpo doctrinal para verificar su compatibilidad integral:

| Decisión | Qué Establece | Qué Implica | Qué NO Implica | ¿Contradicción? |
| :--- | :--- | :--- | :--- | :--- |
| **DEC-AS-001** | Autoridad = `OWNER/MGR` en contexto activo | Validación en runtime antes de mutar | No implica actoría embebida en la relación durable | **NO (PASS)** |
| **DEC-AS-002** | `ASSIGNMENT = DURABLE SAAS STATE` | Persistencia en base de datos SaaS | No implica DDL ni definición de lifecycle físico | **NO (PASS)** |
| **DEC-AS-003** | Materialización = Autorización explícita | Aislamiento entre SaaS y B2C | No implica materialización automática tras asignar | **NO (PASS)** |
| **DEC-AS-005** | `SERVICE_OFFER` tiene identidad y ownership sede | Catálogo autónomo por establecimiento | No implica proveedores embebidos en el servicio | **NO (PASS)** |
| **DEC-AS-006** | `ASSIGNMENT` independiente; target `MEMBERSHIP` | Vinculación contextual con personal | No implica vinculación a `USER` global | **NO (PASS)** |
| **DEC-AS-007** | Coherencia compuesta `tenant + establishment` | Aislamiento multi-tenant integral | No implica definición de tipo físico de FK | **NO (PASS)** |
| **DEC-AS-008** | `ASSIGNMENT` posee identidad propia | Clave conceptual independiente | No implica elección de DDL para la clave | **NO (PASS)** |
| **DEC-AS-009** | Validez derivada de `membership.status` | Sin columna `status` en assignment | No implica máquinas de estado redundantes | **NO (PASS)** |
| **DEC-AS-010** | Cardinalidad $N:M$ bidireccional | Flexibilidad multi-servicio/personal | No implica restricciones cuantitativas fijas | **NO (PASS)** |
| **DEC-AS-011** | Unicidad de relación por par $(S, M)$ | Máximo 1 asignación activa por par | No implica unicidad multi-sede cruzada | **NO (PASS)** |
| **DEC-AS-012** | `DELETE = PURE UNASSIGNMENT` | Desvinculación limpia | No implica eliminación de servicio ni personal | **NO (PASS)** |
| **DEC-AS-013-A**| Sin necesidad de `assigned_at` | Creación estándar suficiente | No implica soporte a asignaciones programadas | **NO (PASS)** |
| **DEC-AS-013-B**| Actoría fuera del núcleo de Assignment | Core modela la realidad operativa | No implica ausencia de auditoría en el sistema | **NO (PASS)** |
| **DEC-AS-013-C**| Sin status `REVOKED`; `deleted_at = UNDEFINED` | Desasignación pura y validez derivada| No implica borrado lógico obligatorio en DDL | **NO (PASS)** |
| **DEC-AS-013-D**| `updated_at` no es requerimiento de dominio | Relación inmutable (crear/eliminar) | No implica prohibición técnica de timestamps | **NO (PASS)** |
| **DEC-AS-013-E**| `reason` no requerido en dominio actual | Modelo limpio sin sobrecarga | No implica bloqueo si el negocio cambia a futuro | **NO (PASS)** |
| **DEC-AS-013-F**| `AUDIT HISTORY` conceptualmente independiente| Trazabilidad desacoplada del core | No implica mecanismo físico predefinido | **NO (PASS)** |

```
====================================================================================================
EVALUACIÓN DE CONSISTENCIA CONSOLIDADA:
CONSOLIDATED CONSISTENCY = PASS
====================================================================================================
```

---

## 15. UNDEFINED PHYSICAL DECISIONS (DECISIONES FÍSICAS INDEFINIDAS / DIFERIDAS)

Las siguientes decisiones técnicas y físicas permanecen explícita y formalmente **UNDEFINED / DIFERIDAS** para futuras etapas de diseño físico:

1. **Nombre Físico de la Tabla:** `UNDEFINED` (ej. `establishment_service_assignments`, `service_assignments`, etc.).
2. **Nombres Físicos de Columnas:** `UNDEFINED`.
3. **Tipos de Datos Físicos DDL:** `UNDEFINED` (ej. `UUID`, `TIMESTAMPTZ`, etc.).
4. **Implementación de Claves Foráneas (FK DDL):** `UNDEFINED`.
5. **Cláusula Física ON DELETE:** `UNDEFINED` (la elección entre `RESTRICT`, `CASCADE` o aplicación pertenece al diseño físico DDL).
6. **Estrategia de Índices Físicos y Constraints:** `UNDEFINED`.
7. **Mecanismo Físico de Auditoría Histórica:** `UNDEFINED` (triggers, event sourcing, tabla histórica, etc.).
8. **Implementación de Interfaz de Usuario (UI):** `UNDEFINED`.
9. **Implementación de Endpoints y Rutas de API:** `UNDEFINED`.
10. **Diseño de Workflows y Workers de Materialización B2C:** `UNDEFINED`.

---

## 16. ARCHITECTURAL BOUNDARY (FRONTERA ARQUITECTÓNICA DEL DOMINIO)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           ARCHITECTURAL BOUNDARIES                          │
│                                                                             │
│  [CORE SAAS ASSIGNMENT]                                                     │
│  • Identidad propia (id)                                                    │
│  • service_offer_id                                                         │
│  • membership_id                                                            │
│  • establishment_id                                                         │
│  • tenant_id                                                                │
│  • Validez derivada: membership.status = 'ACTIVE'                           │
│  • Semántica: Desasignación Pura                                            │
│                                                                             │
│  ──────┬──────────────────────────────────────────────────────────────────  │
│        │ (Desacoplado)                                                      │
│        ▼                                                                    │
│  [AUDIT HISTORY SUBSYSTEM]                                                  │
│  • created_by (Actor USER)                                                  │
│  • acting_membership_id (Mandato Administrativo)                            │
│  • Eventos de Asignación / Desasignación / Invalidación                     │
│  • Mecanismo Físico: UNDEFINED                                              │
│                                                                             │
│  ──────┬──────────────────────────────────────────────────────────────────  │
│        │ (Compuerta Explícita)                                              │
│        ▼                                                                    │
│  [DOWNSTREAM B2C MATERIALIZATION]                                           │
│  • public.services                                                          │
│  • Publicación en Marketplace / Catálogo Público                            │
│  • Disponibilidad y Horarios de Agenda                                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 17. STOP

- **Consolidación Completada:** Se consolidaron exitosamente las 17 decisiones del dominio `ASSIGNMENT`.
- **Consistencia Total:** Cero contradicciones detectadas (`CONSOLIDATED CONSISTENCY = PASS`).
- **Estado de Ejecución:** Cero código, cero DDL, cero migraciones y cero mutaciones en base de datos.
- **Acción:** `STOP` — No avanzar a diseño físico ni implementación sin orden expresa del Director Arquitectónico.
