# DEC-AS-010 — ANÁLISIS DE DISEÑO ARQUITECTÓNICO v1.0
## Assignment Cardinality Analysis (SERVICE_OFFER ↔ ASSIGNMENT ↔ MEMBERSHIP)

**DECISION_ID:** `DEC-AS-010`  
**ESTADO:** `DEC-AS-010 — ANALYSIS COMPLETED — PENDING DIRECTOR DECISION 🟡`  
**TIPO:** Architectural Cardinality & Relational Domain Analysis  
**AUTORIDAD:** Director Arquitectónico del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `DEC-AS-010`  
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
**FECHA DE EMISIÓN:** 2026-09-10  

---

## 1. EXECUTIVE SUMMARY

El presente análisis técnico investiga y determina la **cardinalidad conceptual** de la relación entre `SERVICE_OFFER` (`DEC-AS-005`), `ASSIGNMENT` (`DEC-AS-006`) y `MEMBERSHIP` (Foundation `065`) dentro del dominio SaaS de GlowApp.

### 1.1. Pregunta Central de Cardinalidad
> **¿Cuántos profesionales pueden realizar una `SERVICE_OFFER` y cuántas `SERVICE_OFFER` puede realizar un `PROFESSIONAL` dentro del mismo `ESTABLISHMENT`?**

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

2. ASSIGNMENT (DEC-AS-006, 007, 008, 009):
   - Estado SaaS durable, entidad relacional independiente con PK UUID propia.
   - Referencia SERVICE_OFFER y MEMBERSHIP bajo integridad referencial triple.
   - Validez derivada dinámicamente de membership.status = 'ACTIVE'.
   - CARDINALITY = UNDEFINED (hasta este análisis).

3. MEMBERSHIP (065 Foundation Core):
   - Vínculo contextual: Usuario ◄──► Sede (Establishment) ◄──► Tenant.
   - Roles: OWNER, MANAGER, PROFESSIONAL, RECEPTIONIST.
   - Estados: INVITED, ACTIVE, SUSPENDED, REVOKED.
================================================================================
```

---

## 3. INVESTIGACIÓN DE EVIDENCIA

### 3.1. Evidencia en B2C Existente (`public.services`, `providers`)
- **Estructura B2C:** En el marketplace legacy (`public.services`), cada registro cuenta con una columna física `provider_id INTEGER NOT NULL`.
- **Comportamiento B2C:** 1 proveedor B2C puede tener $N$ servicios publicados ($1 : N$). Sin embargo, cada fila de `public.services` pertenece estrictamente a 1 solo `provider_id`.
- **Límite de Evidencia:** En B2C no existe el concepto de "Catálogo de Sede compartida". Si dos estilistas prestaban el mismo servicio, se creaban 2 filas separadas e inconexas en `public.services`.
- **Conclusión:** La estructura B2C es evidencia histórica pero **no constituye autoridad para SaaS**, donde la oferta comercial es un activo del establecimiento (`DEC-AS-005`).

### 3.2. Evidencia en SaaS Existente (Foundation `065`)
- **Organización Operativa:** Un establecimiento (`establishments`) puede tener múltiples membresías (`memberships`) activas con rol `PROFESSIONAL`, `OWNER` o `MANAGER`.
- **Naturaleza del Salón de Belleza:**
  1. En una sede real con 5 estilistas, todos ellos típicamente pueden realizar el "Corte de Cabello Dama" estándar de la peluquería.
  2. Un mismo estilista típicamente realiza múltiples servicios del catálogo del salón (Corte, Cepillado, Colorimetría, Tratamientos).

### 3.3. Evidencia en el Handover Boundary Contract (`HBC v1.0`)
- **Estructura del Payload:**
  - `service_offers: [...]` contiene un array de $N$ servicios comerciales creados para la sede.
  - `professional_context: [...]` contiene un array de $M$ profesionales colaboradores registrados para la sede.
  - `assignment.status = NOT_ESTABLISHED` durante el handover.
- **Conclusión de HBC:** El contrato formaliza la coexistencia simultánea de múltiples ofertas y múltiples colaboradores dentro del mismo establecimiento, sin imponer acoplamientos 1:1.

---

## 4. ANÁLISIS DE PREGUNTAS DE DOMINIO

```text
================================================================================
EVALUACIÓN DE DIMENSIONES DE ASIGNACIÓN EN EL SALÓN:

A. PERSPECTIVA DE LA OFERTA (SERVICE_OFFER):
   - 0 Profesionales: SÍ (Oferta recién creada en catálogo sin asignar, NOT_ESTABLISHED).
   - 1 Profesional: SÍ (Servicio especializado o atendido por 1 único colaborador).
   - N Profesionales: SÍ (Servicio estándar realizado por múltiples colaboradores del staff).

B. PERSPECTIVA DEL PROFESIONAL (MEMBERSHIP):
   - 0 Ofertas: SÍ (Colaborador recién incorporado o rol administrativo como RECEPTIONIST).
   - 1 Oferta: SÍ (Especialista en un único tratamiento específico).
   - M Ofertas: SÍ (Colaborador integral que ejecuta múltiples servicios del catálogo).
================================================================================
```

---

## 5. EVALUACIÓN DE ALTERNATIVAS DE CARDINALIDAD

```text
================================================================================
ALTERNATIVAS DE CARDINALIDAD:

OPTION A: 1:1 Rígido (1 Oferta ◄──► 1 Profesional)
  - 1 SERVICE_OFFER solo puede asignarse a 1 MEMBERSHIP.
  - 1 MEMBERSHIP solo puede tener 1 SERVICE_OFFER.

OPTION B: 1:N Restringido (1 Oferta ◄──► 1 Profesional, 1 Profesional ──► M Ofertas)
  - Cada fila de oferta solo puede tener 1 colaborador asignado.
  - Si 3 estilistas hacen "Corte", el salón debe crear 3 ofertas duplicadas en catálogo.

OPTION C: N:M Bidireccional Completo (RECOMENDADA)
  - 1 SERVICE_OFFER puede asignarse a Múltiples Profesionales (0..N).
  - 1 MEMBERSHIP puede tener asignadas Múltiples Ofertas (0..M).
  - Cada vínculo es una fila en service_assignments.
================================================================================
```

### 5.1. Option A — 1:1 Rígido
- **Evaluación:** Totalmente inviable en el negocio de salones de belleza y barberías. Obligaría a que cada profesional solo pueda realizar 1 único servicio en toda su jornada y que ningún otro compañero pueda realizarlo.

### 5.2. Option B — 1:N Restringido (Oferta Unipersonal)
- **Evaluación:** Obliga a romper la normalización del catálogo. Para que 4 manicuristas atiendan "Manicure Tradicional", el establecimiento tendría que registrar 4 servicios comerciales idénticos en su catálogo, generando duplicación de precios, nombres y descripciones. Antipatrón de diseño.

### 5.3. Option C — N:M Bidireccional Completo (Recomendada)
- **Evaluación:**
  1. **Preserva la Integridad del Catálogo:** La oferta comercial "Corte de Cabello" se crea **una sola vez** como activo de la sede (`DEC-AS-005`).
  2. **Flexibilidad Operacional Real:** El administrador puede asignar dicho servicio a 1, 3 o todos los estilistas del local.
  3. **Multi-Capacidad del Profesional:** Cada colaborador puede tener asignados todos los servicios para los cuales está capacitado.
  4. **Alineación con `DEC-AS-008`:** La estructura física desacoplada de `service_assignments` con clave primaria UUID propia soporta naturalmente este modelo sin modificaciones.

---

## 6. MATRIZ COMPARATIVA DE ALTERNATIVAS

| Criterio de Evaluación | Option A (1:1 Rígido) | Option B (1:N Restringido) | Option C (N:M Bidireccional) |
| :--- | :--- | :--- | :--- |
| **Modelado de Salones Reales** | **INVIABLE** | **DEFICIENTE** (Duplica catálogo)| **ÓPTIMO** (Refleja la realidad operativa) |
| **Normalización de Catálogo** | **INVIABLE** | **INVIABLE** (N ofertas idénticas)| **ÓPTIMO** (1 oferta única en la sede) |
| **Multi-Especialidad del Staff** | **INVIABLE** | **SOPORTADA** | **ÓPTIMO** |
| **Multi-Staff por Servicio** | **INVIABLE** | **INVIABLE** | **ÓPTIMO** |
| **Compatibilidad DEC-AS-005** | **REGULAR** | **REGULAR** | **ÓPTIMO** (Catálogo desacoplado) |
| **Compatibilidad DEC-AS-008** | **REGULAR** (Fuerza UNIQUEs) | **REGULAR** (Fuerza UNIQUE oferta)| **ÓPTIMO** (Estructura mínima nativa) |
| **Mantenibilidad del Esquema** | **DEFICIENTE** | **DEFICIENTE** | **ÓPTIMA** |

---

## 7. CARDINALIDAD RECOMENDADA (`PROPUESTA — NO APROBADA`)

> [!IMPORTANT]
> **PROPUESTA TÉCNICA — NO APROBADA — REQUIERE DECISIÓN FORMAL DEL DIRECTOR**

Se recomienda al Director formalizar la **Cardinalidad $N:M$ Bidireccional Completa** entre `SERVICE_OFFER` y `MEMBERSHIP` dentro del mismo `ESTABLISHMENT`:

```text
================================================================================
REGLA DE CARDINALIDAD PROPUESTA:

1. UNA OFERTA COMERCIAL (SERVICE_OFFER):
   - Puede tener CERO (0), UNO (1) o MÚLTIPLES (N) profesionales asignados.
   - Cardinalidad: 0 .. N

2. UN COLABORADOR / MEMBRESÍA (MEMBERSHIP):
   - Puede tener CERO (0), UNO (1) o MÚLTIPLES (M) servicios asignados.
   - Cardinalidad: 0 .. M

3. VÍNCULO DE ASIGNACIÓN (ASSIGNMENT):
   - Representa un par unívoco (SERVICE_OFFER_i, MEMBERSHIP_j) perteneciente a la misma sede.
================================================================================
```

---

## 8. CONSECUENCIAS FÍSICAS FUTURAS (`NOT IMPLEMENTED`)

Si la propuesta de cardinalidad $N:M$ es aprobada por el Director:

1. **NO se añadirán restricciones `UNIQUE(service_offer_id)`:**  
   Una oferta puede aparecer en múltiples filas de `service_assignments`.
2. **NO se añadirán restricciones `UNIQUE(membership_id)`:**  
   Un profesional puede aparecer en múltiples filas de `service_assignments`.
3. **Unicidad de la Relación (Relation Uniqueness):**  
   Para evitar que se inserte exactamente el mismo profesional en el mismo servicio más de una vez simultáneamente, se podrá declarar futuramente una restricción única compuesta sobre la pareja:
   ```sql
   CONSTRAINT uq_service_assignment_offer_membership UNIQUE (service_offer_id, membership_id)
   ```
   *(Esta restricción controla la unicidad del par, no limita la cardinalidad $N:M$).*

---

## 9. DECISIONES ABIERTAS PRESERVADAS (OPEN DECISIONS)

El presente análisis mantiene rigurosamente `UNDEFINED` el resto de decisiones:

```text
| Dimensión / Decisión            | Estado Epistemológico               |
| ------------------------------- | ----------------------------------- |
| ASSIGNMENT Cardinality          | PROPOSAL: N:M (PENDING APPROVAL)    |
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
- **Inmutabilidad de Contratos:** `Foundation (065/066)`, `CDC`, `HBC`, `NODO-01`, `DEC-SE-001/002`, `DEC-AS-001/002/003/005/006/007/008/009` permanecen 100% protegidos.

---

## 11. CONDICIONES DE PARADA ARQUITECTÓNICA (ARCHITECTURAL STOP)

$$\mathbf{STOP \ ARQUITECTONICO: \ ANALISIS \ DEC\text{-}AS\text{-}010 \ COMPLETADO}$$

El análisis de cardinalidad de `ASSIGNMENT` queda formalizado y listo para la evaluación del Director.

---

## 12. ESTADO FINAL DEL ENTREGABLE

$$\text{ESTADO: } \mathbf{DEC\text{-}AS\text{-}010 \text{ — ANALYSIS COMPLETED — PENDING DIRECTOR DECISION } \odot}
