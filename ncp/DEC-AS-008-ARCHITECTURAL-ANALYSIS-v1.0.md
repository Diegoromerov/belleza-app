# DEC-AS-008 — ANÁLISIS DE DISEÑO ARQUITECTÓNICO v1.0 (RECONCILIADO R1)
## Identidad Física y Estructura Mínima de Assignment

**DECISION_ID:** `DEC-AS-008`  
**ESTADO:** `DEC-AS-008 — ANALYSIS COMPLETED — PENDING DIRECTOR DECISION 🟡`  
**TIPO:** Physical Identity & Minimum Relational Structure Reconciliation  
**AUTORIDAD:** Director Arquitectónico del Proyecto GlowApp SaaS  
**GOALS ORIGEN:** `DEC-AS-008` / `DEC-AS-008-R1`  
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
**FECHA DE RECONCILIACIÓN:** 2026-09-10  

---

## 1. EXECUTIVE SUMMARY & RECONCILIACIÓN R1

El presente análisis técnico reconcilia y delimita la **identidad física mínima y la estructura relacional básica** para la entidad independiente `ASSIGNMENT` (`DEC-AS-006`), integrando la estrategia de integridad referencial declarativa (`DEC-AS-007`) para vincular `SERVICE_OFFER` (`DEC-AS-005`) con `MEMBERSHIP` (Foundation `065`).

### 1.1. Principios y Correcciones Clave (R1)
1. **Supresión de Políticas de Borrado Prematuras:**  
   Las semánticas de borrado permanecen formalmente `UNDEFINED`. La propuesta física no fija ninguna cláusula `ON DELETE` (`RESTRICT`, `CASCADE`, `SET NULL`), declarando dicho comportamiento como `UNDEFINED — PENDING FUTURE DECISION`.
2. **Revisión Rigurosa de Identidad Compuesta:**  
   Se corrige la afirmación sobre la clave primaria compuesta: una PK natural sobre `(service_offer_id, membership_id)` impone unicidad sobre la pareja, condicionando la representación de múltiples instancias simultáneas. Sin embargo, histórico, lifecycle y auditoría dependen de decisiones adicionales que permanecen `UNDEFINED`.
3. **Separación Conceptual Reforzada:**  
   $$\mathbf{ASSIGNMENT\_IDENTITY} \neq \mathbf{RELATION\_UNIQUENESS} \neq \mathbf{CARDINALITY} \neq \mathbf{LIFECYCLE} \neq \mathbf{AUDIT\_HISTORY}$$
4. **Fundamento Estricto del UUID Propio:**  
   La recomendación de identidad propia UUID se sustenta en:
   - Identidad independiente de la instancia de asignación.
   - Estabilidad ante reasignaciones.
   - Referencias downstream simples de 1 columna.
   - Consistencia tipológica con Foundation `065`.
   - Neutralidad total ante futuras decisiones de cardinalidad y lifecycle.
5. **Condición de Dominio:**  
   `membership.status = ACTIVE` y la autoridad de asignación (`DEC-AS-001`) son condiciones de dominio que la estructura física no resuelve por sí misma.

---

## 2. DECISIONES ARQUITECTÓNICAS PREVIAS APLICABLES

```text
================================================================================
CADENA DE AUTORIDAD CERRADA:

DEC-CAT-001 ──► SERVICE_OFFER es estado operativo durable post-handover con identidad propia.
DEC-SE-001  ──► SERVICE_OFFER ≠ public.services (desacoplamiento B2C).
DEC-AS-001  ──► Asignación autorizada por OWNER/MANAGER en contexto activo hacia profesional activo.
DEC-AS-002  ──► ASSIGNMENT = DURABLE SAAS STATE (sobrevive al request de creación).
DEC-AS-005  ──► SERVICE_OFFER posee UUID propio y pertenece físicamente a ESTABLISHMENT.
DEC-AS-006  ──► ASSIGNMENT es entidad física independiente; Target = MEMBERSHIP (065).
DEC-AS-007  ──► Integridad referencial física vía doble FK compuesta triple (establishment + tenant).
================================================================================
```

---

## 3. EVALUACIÓN DE ALTERNATIVAS DE IDENTIDAD FÍSICA PARA ASSIGNMENT

```text
================================================================================
CANDIDATOS DE IDENTIDAD FÍSICA:

OPTION 1: Identidad Propia UUID (Recomendada)
  id UUID PRIMARY KEY DEFAULT gen_random_uuid()

OPTION 2: Identidad Compuesta Natural
  PRIMARY KEY (service_offer_id, membership_id)

OPTION 3: Clave Compuesta Triple Contextual
  PRIMARY KEY (establishment_id, service_offer_id, membership_id)

OPTION 4: Clave Surrogada Entera (BIGSERIAL / INTEGER)
  id BIGSERIAL PRIMARY KEY
================================================================================
```

### 3.1. Option 1 — Identidad Propia UUID (`gen_random_uuid()`)
- **Independencia de Identidad:** Cada instancia de asignación posee un identificador global único e inmutable, totalmente desacoplado de las entidades que vincula.
- **Estabilidad y Referenciación:** Facilita que referencias downstream (consumos, trazabilidad, agenda) apunten a una clave simple de 1 sola columna.
- **Neutralidad Estructural:** No impone restricciones prematuras sobre unicidad de pareja ni cardinalidad ($1:1$, $1:N$, $N:M$).
- **Alineación con Foundation `065`:** Consistencia tipológica estricta con `organizations.id`, `establishments.id`, `memberships.id` y `service_offers.id`.

### 3.2. Option 2 — Identidad Compuesta Natural (`PRIMARY KEY (service_offer_id, membership_id)`)
- **Propiedad Técnica:** Una identidad compuesta basada en `service_offer_id + membership_id` impone unicidad intrínseca sobre la pareja y, por tanto, condiciona la posibilidad de representar múltiples instancias simultáneas de la misma relación.
- **Delimitación R1:** No se asume que esto afecte histórico o ciclo de vida, pues dichas dimensiones permanecen formalmente `UNDEFINED`.
- **Desventaja:** Obliga a que cualquier referencia externa downstream utilice una clave compuesta de 2 columnas (32 bytes).

### 3.3. Option 3 — Clave Compuesta Triple (`PRIMARY KEY (establishment_id, service_offer_id, membership_id)`)
- **Propiedad:** Agrupa físicamente el índice por sede.
- **Desventaja:** Genera claves primarias de 48 bytes (3 UUIDs) innecesariamente pesadas para indexación relacional, sin aportar ventajas diferenciales sobre la Option 1.

### 3.4. Option 4 — Clave Surrogada Entera (`BIGSERIAL / INTEGER`)
- **Desventaja:** Introduce discordancia tipológica con el ecosistema UUID de la Foundation `065` y riesgos en entornos multi-tenant distribuidos.

---

## 4. ESTRUCTURA MÍNIMA DE ASSIGNMENT

Se define estrictamente la estructura mínima indispensable:

```text
================================================================================
DESCOMPOSICIÓN DE LA ESTRUCTURA MÍNIMA DE ASSIGNMENT:

1. CAPA DE IDENTIDAD (IDENTITY):
   - id UUID PRIMARY KEY (Identificador unívoco e inmutable de la asignación)

2. CAPA DE REFERENCIAS DE RELACIÓN (RELATION REFERENCES):
   - service_offer_id UUID NOT NULL  ──► Puntero a la oferta comercial
   - membership_id UUID NOT NULL     ──► Puntero al profesional contextual (065)

3. CAPA DE CONTEXTO RELACIONAL (REFERENTIAL INTEGRITY CONTEXT - DEC-AS-007):
   - establishment_id UUID NOT NULL  ──► Contexto de sede compartida
   - tenant_id INTEGER NOT NULL      ──► Contexto de aislamiento tenant

TOTAL COLUMNAS MÍNIMAS = 5
================================================================================
```

### 4.1. Exclusiones Explícitas de la Estructura Mínima
En estricta observancia de los límites de alcance, se excluyen formalmente:
- **Semánticas de Borrado:** Cero cláusulas `ON DELETE` fijadas (`UNDEFINED`).
- **Restricciones de Cardinalidad:** Cero restricciones `UNIQUE` sobre `service_offer_id` o `membership_id` (`UNDEFINED`).
- **Atributos de Auditoría:** Cero columnas `created_at`, `updated_at`, `assigned_by`, `revoked_at` (`UNDEFINED`).
- **Campos de Estado:** Cero columnas `status`, `is_active` (`UNDEFINED`).
- **Campos de Dominio B2C:** Cero columnas `provider_id` (Prohibido en SaaS).
- **Campos de Publicación:** Cero columnas de publicación (`DEC-PUB-001`).

---

## 5. NATURALEZA DEL CONTEXTO RELACIONAL (TENANT Y ESTABLISHMENT)

Las columnas `establishment_id` y `tenant_id` dentro de `ASSIGNMENT` cumplen un rol puramente físico-relacional:
1. **Cero Autoridad Conceptual:** No crean una nueva relación de propiedad entre la asignación y la sede; la oferta ya pertenece al establecimiento (`DEC-AS-005`) y la membresía ya pertenece al establecimiento (`065`).
2. **Propósito Exclusivo:** Proveer el contexto requerido por el motor relacional PostgreSQL para evaluar las claves foráneas compuestas triples de `DEC-AS-007`.
3. **Garantía Infranqueable:** Bloquea deterministamente cualquier intento de vincular una oferta de la Sede A con un profesional de la Sede B o de Tenants distintos (`error 23503`).

---

## 6. DISTINCIÓN: IDENTIDAD vs UNICIDAD vs CARDINALIDAD vs LIFECYCLE vs AUDITORÍA

Se formaliza la separación conceptual entre estos cinco planos arquitectónicos:

```text
================================================================================
DISTINCIÓN CONCEPTUAL RIGUROSA:

1. ASSIGNMENT IDENTITY (¿Cómo se identifica la tupla física?):
   - Resuelto por: id UUID PRIMARY KEY.
   - Provee un handle estable e independiente para la instancia.

2. RELATION UNIQUENESS (¿Se restringe la coexistencia de tuplas idénticas?):
   - Nivel Relacional: Restricción UNIQUE opcional (UNDEFINED).
   - No debe confundirse con la identidad de la entidad.

3. CARDINALITY (¿Cuántos profesionales por oferta y cuántas ofertas por profesional?):
   - Nivel de Dominio / Negocio: 1:1 vs 1:N vs N:M.
   - Permanece formalmente: UNDEFINED.

4. LIFECYCLE (¿Qué estados transicionales experimenta la asignación?):
   - Nivel de Dominio: Ausencia de registro = No asignado.
   - Permanece formalmente: UNDEFINED.

5. AUDIT HISTORY (¿Se conserva un log de cambios históricos?):
   - Nivel de Trazabilidad: Depende de requerimientos futuros de auditoría.
   - Permanece formalmente: UNDEFINED.
================================================================================
```

---

## 7. CONDICIONES DE DOMINIO Y AUTORIDAD (STATUS ACTIVE)

- **Condición de Dominio:** Conforme a `DEC-AS-006`, la condición `membership.status = 'ACTIVE'` es un predicado de validez de negocio.
- **Delimitación:** La estructura física relacional de `ASSIGNMENT` **no valida ni resuelve por sí misma**:
  1. La condición dinámica `membership.status = ACTIVE`.
  2. La autorización de asignación por `OWNER/MANAGER` (`DEC-AS-001`).
  3. El workflow transaccional de asignación.
  Dichas garantías residen en las capas de servicio y contratos de dominio.

---

## 8. COMPATIBILIDAD CON ROW-LEVEL SECURITY (RLS)

1. **Alineación con Foundation `065`:**  
   Al incluir `tenant_id INTEGER NOT NULL REFERENCES tenants(id)`, la entidad de asignación se acopla inmediatamente a las políticas RLS:
   ```sql
   ALTER TABLE service_assignments ENABLE ROW LEVEL SECURITY;
   CREATE POLICY tenant_isolation_service_assignments ON service_assignments
       FOR ALL
       USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
       WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
   ```
2. **Inyección Segura:**  
   El `tenant_id` es inyectado por el middleware de contexto verificado (`066`), impidiendo manipulación por cliente.

---

## 9. MATRIZ COMPARATIVA DE CANDIDATOS DE IDENTIDAD

| Criterio de Evaluación | Option 1 (UUID Propio) | Option 2 (PK Compuesta Natural) | Option 3 (PK Triple) | Option 4 (BIGSERIAL) |
| :--- | :--- | :--- | :--- | :--- |
| **Independencia de Identidad** | **ÓPTIMA** (Totalmente autónoma)| **DEFICIENTE** (Acoplada a FKs)| **DEFICIENTE** (Acoplada) | **ÓPTIMA** |
| **Estabilidad ante Reasignación**| **ÓPTIMA** (Inmutable) | **CONDICIONADA** (Condiciona tuplas) | **CONDICIONADA** | **ÓPTIMA** |
| **Alineación con Foundation 065**| **ÓPTIMA** (Estándar UUID Core)| **REGULAR** | **DEFICIENTE** | **INVIABLE** (Tipo incompatible)|
| **Neutralidad de Cardinalidad** | **ÓPTIMA** (Agnóstica a 1:1/1:N)| **REGULAR** (Fuerza par único)| **REGULAR** | **ÓPTIMA** |
| **Referencias Downstream** | **ÓPTIMA** (PK simple 1 columna)| **DEFICIENTE** (FKs compuestas)| **DEFICIENTE** (3 columnas)| **REGULAR** |
| **Simplicidad Relacional** | **ÓPTIMA** | **MEDIA** | **BAJA** | **MEDIA** |

---

## 10. ARQUITECTURA RECOMENDADA (`PROPUESTA — NO APROBADA`)

> [!IMPORTANT]
> **PROPUESTA TÉCNICA — NO APROBADA — REQUIERE DECISIÓN FORMAL DEL DIRECTOR**

Se recomienda al Director considerar la **Estructura Mínima con Identidad Propia UUID** sin fijar políticas de borrado ni constraints de cardinalidad:

```text
================================================================================
ESTRUCTURA FÍSICA MÍNIMA RECOMENDADA (PROPUESTA — NO APROBADA):

TABLA service_assignments:
  - id               UUID PRIMARY KEY DEFAULT gen_random_uuid()
  - tenant_id        INTEGER NOT NULL REFERENCES tenants(id)
  - establishment_id UUID NOT NULL
  - service_offer_id UUID NOT NULL
  - membership_id    UUID NOT NULL

CONSTRAINTS DE INTEGRIDAD FÍSICA (DEC-AS-007):
  - CONSTRAINT fk_assignment_service_offer
      FOREIGN KEY (service_offer_id, establishment_id, tenant_id)
      REFERENCES service_offers(id, establishment_id, tenant_id)
      /* ON DELETE: UNDEFINED — PENDING FUTURE DECISION */

  - CONSTRAINT fk_assignment_membership
      FOREIGN KEY (membership_id, establishment_id, tenant_id)
      REFERENCES memberships(id, establishment_id, tenant_id)
      /* ON DELETE: UNDEFINED — PENDING FUTURE DECISION */
================================================================================
```

---

## 11. DECISIONES ABIERTAS PRESERVADAS (OPEN DECISIONS)

El presente análisis preserva rigurosamente el estado de todas las decisiones abiertas:

```text
| Dimensión / Decisión            | Estado Epistemológico               |
| ------------------------------- | ----------------------------------- |
| ASSIGNMENT Cardinality          | UNDEFINED (Neutral a 1:1, 1:N, N:M) |
| ASSIGNMENT Lifecycle            | UNDEFINED (Ausencia = No asignado)  |
| ASSIGNMENT Delete Semantics     | UNDEFINED (ON DELETE no fijado)     |
| ASSIGNMENT Audit Attributes     | UNDEFINED (created_at, etc.)        |
| ASSIGNMENT Physical Table Name  | UNDEFINED (Nombre definitivo)       |
| ASSIGNMENT Workflow UI/API      | UNDEFINED                           |
| Condición membership ACTIVE     | DOMAIN STATE (DEC-AS-006 / 007-R1)  |
| MATERIALIZATION Implementation  | UNDEFINED (Downstream desacoplado)  |
| PUBLICATION Workflow / Flags    | NOT PRESENT / NOT USED              |
| PHYSICAL IMPLEMENTATION AUTH    | NONE (ZERO CODE / ZERO DDL)         |
```

---

## 12. FRONTERA DE IMPLEMENTACIÓN (IMPLEMENTATION BOUNDARY)

- **Cero Código:** Prohibida la creación o edición de código en `backend/src/`.
- **Cero Migraciones / DDL:** Prohibida la creación de archivos SQL en `backend/migrations/` o ejecución de DDL.
- **Cero Mutaciones:** Cero modificaciones de datos en PostgreSQL.
- **Inmutabilidad de Contratos:** `Foundation (065/066)`, `CDC`, `HBC`, `NODO-01`, `DEC-SE-001/002`, `DEC-AS-001/002/003/005/006/007` permanecen protegidos.

---

## 13. ESTADO FINAL DEL ENTREGABLE

$$\text{ESTADO: } \mathbf{DEC\text{-}AS\text{-}008 \text{ — ANALYSIS COMPLETED — PENDING DIRECTOR DECISION } \odot}
