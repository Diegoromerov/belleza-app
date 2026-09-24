# DEC-AS-011 — ANÁLISIS DE DISEÑO ARQUITECTÓNICO v1.0
## Assignment Relation Uniqueness Analysis (Pair Identity vs Duplication)

**DECISION_ID:** `DEC-AS-011`  
**ESTADO:** `DEC-AS-011 — ANALYSIS COMPLETED — PENDING DIRECTOR DECISION 🟡`  
**TIPO:** Architectural Relation Uniqueness Analysis  
**AUTORIDAD:** Director Arquitectónico del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `DEC-AS-011`  
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
**FECHA DE EMISIÓN:** 2026-09-10  

---

## 1. EXECUTIVE SUMMARY

El presente análisis técnico investiga y determina la **semántica de unicidad de la relación** en la entidad `ASSIGNMENT` (`DEC-AS-006`), respondiendo a la pregunta fundamental de si una misma pareja de entidades:
$$(\text{SERVICE\_OFFER } S, \text{ MEMBERSHIP } M)$$
puede tener una única instancia representativa o si se permiten múltiples instancias simultáneas en el estado operativo de SaaS.

### 1.1. Pregunta Central de Investigación
> **Para un mismo `SERVICE_OFFER = S` y `MEMBERSHIP = M` dentro del mismo `ESTABLISHMENT`, ¿debe existir como máximo una relación `ASSIGNMENT` activa/representativa entre ambos?**

---

## 2. DECISIONES CANÓNICAS APLICABLES

```text
================================================================================
ESTADO ARQUITECTÓNICO CERRADO:

1. SERVICE_OFFER (DEC-AS-005):
   - Identidad propia UUID (inmutable).
   - Pertenece directamente a ESTABLISHMENT (065).
   - Es una oferta comercial del catálogo de la sede física (SaaS).
   - NO es public.services ni contiene provider_id.

2. ASSIGNMENT (DEC-AS-006, 007, 008, 009, 010):
   - Estado SaaS durable, entidad relacional independiente con PK UUID propia.
   - Referencia SERVICE_OFFER y MEMBERSHIP bajo integridad referencial triple.
   - Validez derivada dinámicamente de membership.status = 'ACTIVE'.
   - CARDINALITY = N:M (DEC-AS-010): 1 oferta a N miembros, 1 miembro a M ofertas.
   - RELATION UNIQUENESS = PENDIENTE DEC-AS-011.

3. MEMBERSHIP (065 Foundation Core):
   - Constraint de unicidad de usuario en la sede: UNIQUE (establishment_id, user_id).
================================================================================
```

---

## 3. INVESTIGACIÓN DE EVIDENCIA EN EL DOMINIO

1. **Evidencia en Salones de Belleza Reales:**  
   Un profesional $M_1$ (e.g. María) o bien está habilitada/asignada para prestar el servicio comercial $S_1$ ("Corte Dama"), o bien no lo está. No existe significado operacional para que María esté asignada *dos veces simultáneamente* al mismo "Corte Dama" en la misma peluquería.
2. **Evidencia en Foundation `065`:**  
   La tabla `memberships` aplica el mismo principio de unicidad relacional: un usuario no puede tener dos membresías en el mismo establecimiento (`UNIQUE (establishment_id, user_id)`).
3. **Evidencia en `HBC v1.0` y `CDC v1.0`:**  
   Los payloads de catálogo configuran pares unívocos de ofertas y profesionales. Duplicar la misma pareja generaría redundancia en consultas de disponibilidad, agendas y comisiones.

---

## 4. DISTINCIÓN EPISTEMOLÓGICA ENTRE DIMENSIONES RELACIONALES

Para evitar confusiones conceptuales, se delimitan rigurosamente cinco planos independientes:

```text
================================================================================
DISTINCIÓN CONCEPTUAL RIGUROSA:

1. RELATION IDENTITY (DEC-AS-008):
   - Resuelto por: id UUID PRIMARY KEY.
   - Es el identificador unívoco de cada fila física en la tabla.

2. RELATION UNIQUENESS (DEC-AS-011 - Presente Análisis):
   - Pregunta: ¿Puede repetirse la misma pareja (SERVICE_OFFER_i, MEMBERSHIP_j)?
   - Resuelve si la relación es un CONJUNTO MATEMÁTICO (sin duplicados) o un MULTICONJUNTO.

3. CARDINALITY (DEC-AS-010):
   - Resuelto por: N:M.
   - 1 Oferta puede asociarse a N miembros distintos; 1 Miembro a M ofertas distintas.

4. LIFECYCLE (DEC-AS-009):
   - Resuelto por: Validez derivada dinámicamente de membership.status = 'ACTIVE'.

5. AUDIT HISTORY (UNDEFINED):
   - Trazabilidad y logs históricos (no legislados, fuera del alcance).
================================================================================
```

---

## 5. EVALUACIÓN DE ALTERNATIVAS DE UNICIDAD DE RELACIÓN

```text
================================================================================
ALTERNATIVAS EVALUADAS:

OPTION A: Relación Unívoca (Unique Relation - RECOMENDADA)
  - Para cada pareja (service_offer_id, membership_id), existe como máximo 1 instancia.
  - S1 ◄──► M1 (Única)
  - S1 ◄──► M2 (Permitido por N:M)
  - S2 ◄──► M1 (Permitido por N:M)
  - Prohibido: S1 ◄──► M1 duplicado simultáneamente.

OPTION B: Instancias Múltiples de la Misma Pareja (Multiple Same-Pair)
  - Se permite insertar N filas idénticas vinculando S1 con M1.

OPTION C: Unicidad Condicionada por Estado / Lifecycle
  - La unicidad depende de un campo status (e.g. único solo si status = 'ACTIVE').
================================================================================
```

### 5.1. Option A — Relación Unívoca (Unique Relation — Recomendada)
- **Semántica:** Una asignación representa el hecho de que un colaborador específico presta un servicio específico en la sede. Como hecho de configuración de catálogo, el vínculo es unívoco.
- **Ventajas:**
  1. **Prevención de Corrupción de Datos:** Impide que bugs en la interfaz o llamadas de API concurrentes dupliquen asignaciones.
  2. **Determinismo en Consultas:** Las consultas de "¿quiénes realizan este servicio?" o "¿qué servicios realiza este profesional?" retornan listas limpias sin requerir `SELECT DISTINCT`.
  3. **Preserva Totalmente la Cardinalidad $N:M$:** Un profesional sigue pudiendo realizar $M$ servicios distintos y una oferta sigue pudiendo ser realizada por $N$ profesionales distintos.

### 5.2. Option B — Instancias Múltiples de la Misma Pareja
- **Evaluación:** Antipatrón relacional en este nivel de dominio. Requeriría introducir atributos discriminadores artificiales (e.g. sub-roles, turnos) que no forman parte de la oferta de catálogo ni de la arquitectura cerrada.

### 5.3. Option C — Unicidad Condicionada por Lifecycle
- **Evaluación:** Depende de estados transicionales propios en `service_assignments`. Dado que `DEC-AS-009` estableció que `ASSIGNMENT` no posee columnas de estado propias y que la validez se deriva de `memberships.status`, esta opción carece de justificación técnica y violaría `DEC-AS-009`.

---

## 6. MATRIZ COMPARATIVA DE ALTERNATIVAS

| Criterio de Evaluación | Option A (Relación Unívoca) | Option B (Instancias Múltiples) | Option C (Unicidad Condicional) |
| :--- | :--- | :--- | :--- |
| **Modelado de Negocio** | **ÓPTIMO** (1 vínculo por pareja) | **INVIABLE** (Ambigüedad) | **DEFICIENTE** |
| **Determinismo en Consultas** | **ÓPTIMO** (Sin duplicados) | **DEFICIENTE** (Requiere DISTINCT)| **MEDIA** |
| **Compatibilidad con N:M** | **ÓPTIMA** (100% compatible) | **SOPORTADA** | **SOPORTADA** |
| **Compatibilidad con DEC-AS-009**| **ÓPTIMA** (Validez derivada) | **REGULAR** | **INCOMPATIBLE** (Viola DEC-009) |
| **Prevención de Bugs de Concurrencia**| **ÓPTIMA** (Motor relacional PG) | **NULA** | **REGULAR** |
| **Simplicidad Relacional** | **ÓPTIMA** | **DEFICIENTE** | **DEFICIENTE** |

---

## 7. UNICIDAD DE RELACIÓN RECOMENDADA (`PROPUESTA — NO APROBADA`)

> [!IMPORTANT]
> **PROPUESTA TÉCNICA — NO APROBADA — REQUIERE DECISIÓN FORMAL DEL DIRECTOR**

Se recomienda al Director formalizar el principio de **Relación Unívoca (Option A)**:

```text
================================================================================
REGLA DE UNICIDAD DE RELACIÓN PROPUESTA:

1. REGLA CONCEPTUAL:
   - Para un mismo SERVICE_OFFER (S) y un mismo MEMBERSHIP (M) dentro de un ESTABLISHMENT,
     debe existir como MÁXIMO UNA instancia de ASSIGNMENT.

2. COMPATIBILIDAD CON CARDINALIDAD N:M:
   - SERVICE_OFFER_A ──► { MEMBERSHIP_1, MEMBERSHIP_2, MEMBERSHIP_3 }
   - SERVICE_OFFER_B ──► { MEMBERSHIP_1, MEMBERSHIP_4 }
   - MEMBERSHIP_1    ──► { SERVICE_OFFER_A, SERVICE_OFFER_B }
   - Cada pareja (S_i, M_j) es única y no admite duplicados simultáneos.
================================================================================
```

---

## 8. CONSECUENCIAS FÍSICAS FUTURAS (`NOT IMPLEMENTED`)

Si la recomendación de unicidad de relación es aprobada por el Director:

1. **Restricción de Unicidad en la Tabla de Asignaciones:**  
   En la fase de diseño DDL futuro, se declarará una restricción única compuesta sobre el par `(service_offer_id, membership_id)`:
   ```sql
   CONSTRAINT uq_service_assignment_offer_membership UNIQUE (service_offer_id, membership_id)
   ```
   O alternativamente, incluyendo el contexto relacional de `DEC-AS-007`:
   ```sql
   CONSTRAINT uq_service_assignment_pair_context UNIQUE (service_offer_id, membership_id, establishment_id, tenant_id)
   ```
2. **Cero Impacto en PK:**  
   La clave primaria física sigue siendo `id UUID PRIMARY KEY` (`DEC-AS-008`). La restricción única es un índice de unicidad secundario.

---

## 9. DECISIONES ABIERTAS PRESERVADAS (OPEN DECISIONS)

El presente análisis mantiene formalmente intactas todas las decisiones abiertas del sistema:

```text
| Dimensión / Decisión            | Estado Epistemológico               |
| ------------------------------- | ----------------------------------- |
| ASSIGNMENT Cardinality          | CLOSED: N:M (DEC-AS-010)            |
| ASSIGNMENT Relation Uniqueness  | PROPOSAL: UNIQUE (PENDING APPROVAL) |
| ASSIGNMENT Lifecycle            | UNDEFINED (Ausencia = No asignado)  |
| ASSIGNMENT Delete Semantics     | UNDEFINED (Políticas ON DELETE)     |
| ASSIGNMENT Audit Attributes     | UNDEFINED (created_at, etc.)        |
| ASSIGNMENT Physical Table Name  | UNDEFINED (Nombre definitivo)       |
| ASSIGNMENT Workflow UI/API      | UNDEFINED                           |
| MATERIALIZATION Implementation  | UNDEFINED (Downstream desacoplado)  |
| PUBLICATION Workflow / Flags    | NOT PRESENT / NOT USED              |
| PHYSICAL IMPLEMENTATION AUTH    | NONE (ZERO CODE / ZERO DDL)         |
```

---

## 10. FRONTERA DE IMPLEMENTACIÓN (IMPLEMENTATION BOUNDARY)

- **Cero Código:** Prohibida la creación o edición de código en `backend/src/`.
- **Cero Migraciones / DDL:** Prohibida la creación de archivos SQL en `backend/migrations/` o ejecución de DDL.
- **Cero Mutaciones:** Cero modificaciones de datos en PostgreSQL.
- **Inmutabilidad de Contratos:** `Foundation (065/066)`, `CDC`, `HBC`, `NODO-01`, `DEC-SE-001/002`, `DEC-AS-001/002/003/005/006/007/008/009/010` permanecen 100% protegidos.

---

## 11. CONDICIONES DE PARADA ARQUITECTÓNICA (ARCHITECTURAL STOP)

$$\mathbf{STOP \ ARQUITECTONICO: \ ANALISIS \ DEC\text{-}AS\text{-}011 \ COMPLETADO}$$

El análisis de unicidad de la relación `ASSIGNMENT` queda formalizado y listo para la evaluación del Director.

---

## 12. ESTADO FINAL DEL ENTREGABLE

$$\text{ESTADO: } \mathbf{DEC\text{-}AS\text{-}011 \text{ — ANALYSIS COMPLETED — PENDING DIRECTOR DECISION } \odot}
