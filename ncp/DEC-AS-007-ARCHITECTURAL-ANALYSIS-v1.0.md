# DEC-AS-007 — ANÁLISIS DE DISEÑO ARQUITECTÓNICO v1.0 (RECONCILIADO R1)
## Diseño de Integridad Referencial Física de Assignment (Tenant & Establishment Integrity)

**DECISION_ID:** `DEC-AS-007`  
**ESTADO:** `DEC-AS-007 — RECONCILED ANALYSIS — PENDING DIRECTOR DECISION 🟡`  
**TIPO:** Physical Referential Integrity & Relational Architecture Reconciliation  
**AUTORIDAD:** Director Arquitectónico del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `DEC-AS-007` / `DEC-AS-007-R1`  
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
**FECHA DE RECONCILIACIÓN:** 2026-09-10  

---

## 1. EXECUTIVE SUMMARY & RECONCILIACIÓN R1

El presente análisis técnico reconcilia y delimita con precisión matemática la estrategia física en PostgreSQL para implementar la **Integridad Referencial Física** de la asignación (`DEC-AS-006`) vinculando `SERVICE_OFFER` (`DEC-AS-005`) con `MEMBERSHIP` (Foundation `065`).

### 1.1. Delimitación Epistemológica Obligatoria (R1)
Se establece la separación formal entre:
1. **Integridad Referencial Física (Motor PostgreSQL):**  
   Garantiza que `SERVICE_OFFER`, `ASSIGNMENT` y `MEMBERSHIP` compartan de forma obligatoria y estricta el mismo `tenant_id` y el mismo `establishment_id`, impidiendo corrupciones cross-tenant y cross-establishment a nivel de base de datos.
2. **Condición de Dominio Operacional (`DEC-AS-006`):**  
   `TARGET CONDITION = ACTIVE PROFESSIONAL CONTEXT` (`membership.status = 'ACTIVE'`).
3. **Declaración Taxativa:**  
   > **"Option C garantiza identidad referencial de tenant y establishment, pero NO garantiza por sí sola `membership.status = ACTIVE`."**

---

## 2. REFERENTIAL INTEGRITY vs DOMAIN STATE

```text
================================================================================
SEPARACIÓN CONCEPTUAL: INTEGRIDAD REFERENCIAL vs ESTADO DE DOMINIO

┌────────────────────────────────────────┐  ┌────────────────────────────────────────┐
│     INTEGRIDAD REFERENCIAL FÍSICA      │  │           ESTADO DE DOMINIO            │
│          (Garantizado por PG)          │  │       (Regla de Negocio / DEC)         │
├────────────────────────────────────────┤  ├────────────────────────────────────────┤
│ • Existencia de Entidad SERVICE_OFFER  │  │ • membership.status = 'ACTIVE'         │
│ • Existencia de Entidad MEMBERSHIP     │  │ • Rol operativo válido                 │
│ • Pertenencia a ESTABLISHMENT idéntico │  │ • Capacidad del profesional            │
│ • Aislamiento a TENANT idéntico        │  │ • Autorización OWNER/MANAGER (DEC-001) │
│ • Prevención de Huérfanos Estructurales│  │ • Elegibilidad de ejecución            │
└────────────────────────────────────────┘  └────────────────────────────────────────┘
================================================================================
```

1. **Alcance de la Integridad Referencial Física:**  
   Las claves foráneas compuestas de PostgreSQL actúan sobre la *existencia y coincidencia de tuplas identificadoras*. Garantizan que la fila referenciada exista en la tabla padre con las columnas indicadas (`id`, `establishment_id`, `tenant_id`).
2. **Límite Relacional:**  
   Una clave foránea estándar **no valida predicados de estado dinámico** (como `status = 'ACTIVE'`). Si una membresía pasa a `status = 'REVOKED'`, la clave foránea física no se invalida relacionalmente (la fila sigue existiendo con su misma PK/Sede/Tenant).
3. **Estado de la Condición `ACTIVE`:**  
   La forma en que se garantizará y filtrará operacionalmente la condición `ACTIVE` permanece como un aspecto de autoridad de negocio y consulta operacional, sin forzar triggers PL/pgSQL artificiales.

---

## 3. EVIDENCIA FÍSICA ACTUAL (CURRENT PHYSICAL EVIDENCE)

Se examinó la estructura física desplegada en PostgreSQL por la migración `065_saas_foundation_core.sql`:

```text
================================================================================
ESTRUCTURA FÍSICA ACTUAL EN FOUNDATION 065:

1. TABLA organizations:
   - id UUID PRIMARY KEY DEFAULT gen_random_uuid()
   - tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT
   - CONSTRAINT uq_organization_id_tenant UNIQUE (id, tenant_id)

2. TABLA establishments:
   - id UUID PRIMARY KEY DEFAULT gen_random_uuid()
   - tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT
   - organization_id UUID NOT NULL
   - CONSTRAINT fk_establishment_organization FOREIGN KEY (organization_id, tenant_id)
       REFERENCES organizations(id, tenant_id) ON DELETE RESTRICT
   - CONSTRAINT uq_establishment_id_tenant UNIQUE (id, tenant_id)

3. TABLA memberships:
   - id UUID PRIMARY KEY DEFAULT gen_random_uuid()
   - tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT
   - establishment_id UUID NOT NULL
   - user_id INTEGER NOT NULL
   - role VARCHAR(50) NOT NULL CHECK (role IN ('OWNER', 'MANAGER', 'PROFESSIONAL', 'RECEPTIONIST'))
   - status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('INVITED', 'ACTIVE', 'SUSPENDED', 'REVOKED'))
   - CONSTRAINT fk_membership_establishment FOREIGN KEY (establishment_id, tenant_id)
       REFERENCES establishments(id, tenant_id) ON DELETE RESTRICT
   - CONSTRAINT fk_membership_user_tenant FOREIGN KEY (user_id, tenant_id)
       REFERENCES usuarios(id, tenant_id) ON DELETE RESTRICT
   - CONSTRAINT uq_membership_establishment_user UNIQUE (establishment_id, user_id)
================================================================================
```

### 3.1. Requisitos Relacionales para Claves Foráneas Compuestas
- En PostgreSQL, para que una tabla dependiente (`ASSIGNMENT`) pueda declarar una FK hacia `(service_offer_id, establishment_id, tenant_id)` y hacia `(membership_id, establishment_id, tenant_id)`, las tablas padre deben exponer restricciones `UNIQUE` sobre dichas columnas:
  1. `service_offers` requerirá: `CONSTRAINT uq_service_offer_establishment_tenant UNIQUE (id, establishment_id, tenant_id)`.
  2. `memberships` requerirá: `CONSTRAINT uq_membership_establishment_tenant UNIQUE (id, establishment_id, tenant_id)`.

---

## 4. NATURALEZA DE LAS COLUMNAS DUPLICADAS EN ASSIGNMENT

En la entidad conceptual `ASSIGNMENT`:
$$\text{Columnas: } \{ \text{service\_offer\_id}, \text{membership\_id}, \text{establishment\_id}, \text{tenant\_id} \}$$

- **Principio de Autoridad de Dominio:**  
  Las columnas `establishment_id` y `tenant_id` en `ASSIGNMENT` **NO representan nueva autoridad de dominio ni crean entidades independientes**.
- **Propósito Exclusivo:**  
  Son **contexto físico relacional** requerido por el motor PostgreSQL para enlazar ambas claves foráneas compuestas y forzar que ambas apunten exactamente al mismo establecimiento y tenant.

---

## 5. EVALUACIÓN DE ALTERNATIVAS DE DISEÑO FÍSICO

```text
================================================================================
ALTERNATIVAS DE DISEÑO DE INTEGRIDAD:

OPTION A (FKs Simples + Validación Exclusiva por Aplicación):
  assignment.service_offer_id ──(FK simple)──► service_offers.id
  assignment.membership_id    ──(FK simple)──► memberships.id
  (Dictamen: Deficiente. Permite cross-tenant y cross-establishment si la app falla)

OPTION B (FKs Compuestas Parciales por Tenant):
  assignment(service_offer_id, tenant_id) ──► service_offers(id, tenant_id)
  assignment(membership_id, tenant_id)    ──► memberships(id, tenant_id)
  (Dictamen: Insuficiente. Permite cross-establishment entre sedes del mismo tenant)

OPTION C (Doble FK Compuesta Triple con Sede y Tenant Compartidos - PROPUESTA):
  assignment(service_offer_id, establishment_id, tenant_id) ──► service_offers(id, establishment_id, tenant_id)
  assignment(membership_id, establishment_id, tenant_id)    ──► memberships(id, establishment_id, tenant_id)
  (Dictamen: Óptima para integridad referencial física. Imposibilidad matemática de cross-tenant y cross-establishment)

OPTION D (Triggers PL/pgSQL de Validación Dinámica):
  Triggers BEFORE INSERT OR UPDATE ON assignments.
  (Dictamen: Antipatrón frente a constraints declarativas nativas)
================================================================================
```

---

## 6. MATRIZ COMPARATIVA DE ALTERNATIVAS

| Criterio de Evaluación | Option A (FKs Simples + App) | Option B (FKs Compuestas Tenant) | Option C (Doble FK Triple Compuesta) | Option D (Triggers PG) |
| :--- | :--- | :--- | :--- | :--- |
| **Garantía Tenant Integrity** | **DEFICIENTE** (Solo app) | **ÓPTIMA** (Motor PG) | **ÓPTIMA** (Motor PG) | **REGULAR** (Trigger) |
| **Garantía Establishment Integrity**| **DEFICIENTE** (Solo app) | **INSUFICIENTE** (Permite cross-sede en mismo tenant) | **ÓPTIMA** (Motor PG) | **REGULAR** (Trigger) |
| **Garantiza `membership.status = ACTIVE`**| **NO** | **NO** | **NO (Requiere regla de dominio)**| **PARCIAL** (Overhead) |
| **Riesgo Cross-Tenant** | **ALTO** (Fallo por bug de app) | **NULO** (Bloqueo físico PG)| **NULO** (Bloqueo físico PG)| **BAJO** |
| **Riesgo Cross-Establishment** | **ALTO** (Fallo por bug de app) | **ALTO** (Entre sedes del mismo tenant) | **NULO** (Bloqueo físico PG)| **BAJO** |
| **Complejidad Declarativa** | **MÍNIMA** (FKs simples) | **MEDIA** | **MEDIA** (Estándar relacional) | **ALTA** (Código PL/pgSQL)|
| **Impacto sobre RLS** | **REGULAR** | **ÓPTIMA** (`tenant_id` explícito)| **ÓPTIMA** (`tenant_id` explícito)| **REGULAR** |
| **Dependencia de Aplicación** | **100% DEPENDIENTE** | **50% DEPENDIENTE** | **0% PARA SEDE/TENANT** | **BAJA** |
| **Economía de Ejecución** | Alta | Alta | **ÓPTIMA** (Índices únicos nativos)| Regular (Overhead PL)|

---

## 7. ANÁLISIS DE INTEGRIDAD REFERENCIAL POSTGRESQL (DEMOSTRACIÓN FORMAL)

### 7.1. Demostración de Bloqueo Cross-Establishment (Option C)
Supongamos la estructura con FKs triples compuestas:
1. Oferta $S_1$ registrada en Sede $E_1$, Tenant $T_1$: Fila en `service_offers` con $(id=S_1, establishment_id=E_1, tenant_id=T_1)$.
2. Membresía $M_2$ registrada en Sede $E_2$, Tenant $T_1$: Fila en `memberships` con $(id=M_2, establishment_id=E_2, tenant_id=T_1)$.
3. Intento de asignar $S_1$ con $M_2$ en tabla `service_assignments`:
   - Si la fila de asignación declara $establishment_id = E_1$:
     - `FK_service_offer` verifica $(S_1, E_1, T_1)$ en `service_offers` $longrightarrow$ **VÁLIDO**.
     - `FK_membership` verifica $(M_2, E_1, T_1)$ en `memberships` $longrightarrow$ **FALLA (No existe $M_2$ en $E_1$)**.
   - Si la fila de asignación declara $establishment_id = E_2$:
     - `FK_service_offer` verifica $(S_1, E_2, T_1)$ en `service_offers` $longrightarrow$ **FALLA (No existe $S_1$ en $E_2$)**.
4. **Resultado Motor:** PostgreSQL arroja automáticamente `error 23503 (foreign_key_violation)`.

### 7.2. Demostración de Bloqueo Cross-Tenant (Option C)
Si $S_1$ pertenece a Tenant $T_1$ y $M_3$ pertenece a Tenant $T_2$:
- La tabla de asignación solo puede tener un único `tenant_id`.
- Cualquiera sea el `tenant_id` colocado, una de las dos FKs compuestas fallará de forma determinista e infranqueable.

---

## 8. COMPATIBILIDAD CON ROW-LEVEL SECURITY (RLS)

1. **Alineación con Foundation `065`:**  
   Al contener `tenant_id INTEGER NOT NULL`, la entidad de asignación se acopla inmediatamente al esquema RLS del sistema:
   ```sql
   ALTER TABLE service_assignments ENABLE ROW LEVEL SECURITY;
   CREATE POLICY tenant_isolation_service_assignments ON service_assignments
       FOR ALL
       USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
       WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
   ```
2. **Defensa en Profundidad (Defense in Depth):**  
   - **Nivel 1 (RLS):** Oculta registros fuera del tenant del contexto activo.
   - **Nivel 2 (FK Compuesta Triple):** Bloquea corrupciones relacionales incluso ante fallos de configuración de RLS o transacciones privilegiadas.

---

## 9. ALTERNATIVAS DE IDENTIDAD FÍSICA PARA ASSIGNMENT

En cumplimiento de `DEC-AS-006`, la identidad física de Assignment permanece formalmente `UNDEFINED`:

| Alternativa de Identidad | Estructura | Pros | Contras |
| :--- | :--- | :--- | :--- |
| **Identidad Propia UUID (`id UUID PK`)** | `id UUID PRIMARY KEY DEFAULT gen_random_uuid()` | - Uniforme con `organizations`, `establishments`, `memberships` y `service_offers` de Foundation.<br>- Simplifica referencias futuras para auditoría y logs de ejecución. | Requiere un índice PK adicional en disco. |
| **Identidad Compuesta Natural** | `PRIMARY KEY (service_offer_id, membership_id)` | - Ahorra 16 bytes de UUID por fila.<br>- Previene asignaciones duplicadas de la misma pareja. | Fuerza implícitamente que una oferta y un profesional solo tengan un vínculo sin historial; rompe si se requiere auditar reasignaciones temporales. |
| **Clave Compuesta Triple** | `PRIMARY KEY (establishment_id, service_offer_id, membership_id)` | Agrupa físicamente por sede en índices. | Mayor tamaño de clave primaria. |

---

## 10. ARQUITECTURA RECOMENDADA (`PROPUESTA — NO APROBADA`)

> [!IMPORTANT]
> **PROPUESTA TÉCNICA — NO APROBADA — REQUIERE DECISIÓN FORMAL DEL DIRECTOR**

Se recomienda al Director considerar el patrón **Option C (Doble Clave Foránea Compuesta Triple)** para la resolución exclusiva de la integridad referencial física:

```text
================================================================================
PROPUESTA DE ESTRUCTURA FÍSICA (PROPUESTA — NO APROBADA):

1. TABLA service_offers (DEC-AS-005):
   - id UUID PRIMARY KEY DEFAULT gen_random_uuid()
   - tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT
   - establishment_id UUID NOT NULL
   - CONSTRAINT fk_service_offer_establishment
       FOREIGN KEY (establishment_id, tenant_id) REFERENCES establishments(id, tenant_id) ON DELETE RESTRICT
   - CONSTRAINT uq_service_offer_establishment_tenant
       UNIQUE (id, establishment_id, tenant_id)

2. TABLA memberships (Foundation 065 - Requiere adición de constraint UNIQUE para habilitar FK):
   - CONSTRAINT uq_membership_establishment_tenant
       UNIQUE (id, establishment_id, tenant_id)

3. TABLA service_assignments (DEC-AS-006):
   - id UUID (Identidad física UNDEFINED por DEC-AS-006)
   - tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT
   - establishment_id UUID NOT NULL
   - service_offer_id UUID NOT NULL
   - membership_id UUID NOT NULL
   - CONSTRAINT fk_assignment_service_offer
       FOREIGN KEY (service_offer_id, establishment_id, tenant_id)
       REFERENCES service_offers(id, establishment_id, tenant_id) ON DELETE RESTRICT
   - CONSTRAINT fk_assignment_membership
       FOREIGN KEY (membership_id, establishment_id, tenant_id)
       REFERENCES memberships(id, establishment_id, tenant_id) ON DELETE RESTRICT
================================================================================
```

---

## 11. DECISIONES ABIERTAS PRESERVADAS (OPEN DECISIONS)

El presente análisis reconciliado mantiene formalmente `UNDEFINED` todas las decisiones abiertas:

```text
| Dimensión / Decisión            | Estado Epistemológico               |
| ------------------------------- | ----------------------------------- |
| Enforce de membership ACTIVE    | UNDEFINED (Regla de Dominio/App)    |
| ASSIGNMENT Cardinality          | UNDEFINED (Soporta 1:1, 1:N, N:M)   |
| ASSIGNMENT Lifecycle            | UNDEFINED (Ausencia = No asignado)  |
| ASSIGNMENT Delete Semantics     | UNDEFINED (Políticas ON DELETE)     |
| ASSIGNMENT Audit Attributes     | UNDEFINED                           |
| ASSIGNMENT Physical Table Name  | UNDEFINED                           |
| ASSIGNMENT Physical Identity    | UNDEFINED                           |
| ASSIGNMENT Workflow UI/API      | UNDEFINED                           |
| MATERIALIZATION Implementation  | UNDEFINED (Downstream desacoplado)  |
| PUBLICATION Workflow / Flags    | NOT PRESENT / NOT USED              |
| PHYSICAL IMPLEMENTATION AUTH    | NONE (ZERO CODE / ZERO DDL)         |
```

---

## 12. FRONTERA DE IMPLEMENTACIÓN (IMPLEMENTATION BOUNDARY)

- **Cero Código:** Prohibida la creación o modificación de controladores, servicios o rutas.
- **Cero Migraciones / DDL:** Prohibida la ejecución de `CREATE TABLE`, `ALTER TABLE` o creación de archivos SQL en migraciones.
- **Cero Mutaciones de Datos:** Cero `INSERT`, `UPDATE` o `DELETE` en base de datos.
- **Inmutabilidad de Contratos:** `Foundation (065/066)`, `CDC`, `HBC`, `NODO-01`, `DEC-SE-001/002`, `DEC-AS-001/002/003/005/006` permanecen 100% protegidos.

---

## 13. ESTADO FINAL DEL ANÁLISIS RECONCILIADO

$$\text{ESTADO: } \mathbf{DEC\text{-}AS\text{-}007 \text{ — RECONCILED ANALYSIS — PENDING DIRECTOR DECISION } \odot}
