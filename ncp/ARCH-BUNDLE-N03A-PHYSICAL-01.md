# ARCH-BUNDLE-N03A-PHYSICAL-01 (RECONCILED R2)
## NODO-03A — Staff Operational Availability & Schedule
## Physical Architecture Design Specification

**ESTADO DEL DOCUMENTO:** `PHYSICAL ARCHITECTURE: APPROVED / CLOSED BY DIRECTOR 🔒`  
**VERSIÓN:** 1.2.0 (R2 Final Reconciliation)  
**TIPO:** Physical Database Architecture Design Specification  
**AUTORIDAD RAÍZ:** Director del Proyecto GlowApp SaaS  
**NODO ASOCIADO:** `NODO-03A-v1.0` (Staff Operational Availability & Schedule Runtime)  
**CONTRATOS Y DECISIONES DE BASE:**
- [`/ncp/NODO-03A-NODE-CONTRACT-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NODO-03A-NODE-CONTRACT-v1.0.md) (Reconciled R1 🔒)
- [`/ncp/N03A-DEC-001-STAFF-AVAILABILITY-SEMANTIC-DECISION-BUNDLE.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/N03A-DEC-001-STAFF-AVAILABILITY-SEMANTIC-DECISION-BUNDLE.md) (Decisiones `N03A-DEC-01` a `08` 🔒)
- [`/ncp/DEC-FC-001-MEMBERSHIP-REFERENTIAL-INTEGRITY-KEY.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/DEC-FC-001-MEMBERSHIP-REFERENTIAL-INTEGRITY-KEY.md) (Opción A 🔒)
- [`065_saas_foundation_core.sql`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/migrations/065_saas_foundation_core.sql), [`067_service_offers.sql`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/migrations/067_service_offers.sql) & [`068_service_assignments.sql`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/migrations/068_service_assignments.sql)

---

## 1. EXECUTIVE DECISION (DECISIÓN EJECUTIVA DE DISEÑO)

Para la persistencia relacional de la disponibilidad operativa semanal de los colaboradores en `NODO-03A`, bajo los principios de **economía relacional, no redundancia, tipado estricto, separación físico/runtime e inviolabilidad multi-tenant**:

1. **Estructura Física Mínima:** **UNA ÚNICA TABLA FÍSICA NUEVA** denominada `staff_schedules`.
2. **Modelo Atómico Normalizado:** Cada tupla física representa exactamente un **intervalo semanal recurrente** `[start_time, end_time]` para una combinación `(membership_id, establishment_id, day_of_week)`.
3. **Identidad Física:** Clave primaria subrogada `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`, preservando la homogeneidad con el estándar Foundation (`065`, `067`, `068`).
4. **Anclaje de Integridad Referencial Triple Compuesta:** Clave foránea `(membership_id, establishment_id, tenant_id)` referenciando `memberships(id, establishment_id, tenant_id)` conforme a `DEC-FC-001` (Opción A 🔒), con regla conservadora **`ON DELETE RESTRICT`** (Integridad Física Referencial).
5. **Semántica Declarativa Pura de Presencia/Ausencia:** Cero columnas de estado operativo (`is_active`, `status`, `revoked`, `suspended`); la existencia del registro representa disponibilidad, su ausencia representa no disponibilidad, y la validez operativa depende exclusivamente de `memberships.status = 'ACTIVE'` (`N03A-DEC-07` 🔒).
6. **Desacoplamiento Estricto de Horarios de Sede:** Cero duplicación de `establishments.operating_hours`, cero foreign keys cruzadas, cero triggers y cero constraints de base de datos (`N03A-DEC-05` 🔒).

---

## 2. CURRENT SCHEMA EVIDENCE (EVIDENCIA DEL ESQUEMA FÍSICO ACTUAL)

Inspección de las estructuras físicas existentes en PostgreSQL:

```text
================================================================================
           EVIDENCIA DE ESTRUCTURAS FÍSICAS RELEVANTES (FOUNDATION + NODO-02)
================================================================================

1. TABLA `tenants`:
   - PK: `id` (INTEGER).
   - Rol: Raíz absoluta de aislamiento multi-tenant.

2. TABLA `usuarios`:
   - PK: `id` (INTEGER).
   - Composite Unique: `(id, tenant_id)` via `uq_usuarios_id_tenant`.
   - FK: `tenant_id` -> `tenants(id)` ON DELETE RESTRICT.

3. TABLA `establishments`:
   - PK: `id` (UUID).
   - Composite Unique: `(id, tenant_id)` via `uq_establishment_id_tenant`.
   - FK: `(organization_id, tenant_id)` -> `organizations(id, tenant_id)` ON DELETE RESTRICT.
   - Columna: `operating_hours` (JSONB) - Horario comercial de la sede (DEC-SE-002 🔒).

4. TABLA `memberships`:
   - PK: `id` (UUID).
   - Composite Unique (Foundation): `(establishment_id, user_id)` via `uq_membership_establishment_user`.
   - Composite Unique (DEC-FC-001 / Migración 068): `(id, establishment_id, tenant_id)` via `uq_membership_id_establishment_tenant`.
   - FK: `(establishment_id, tenant_id)` -> `establishments(id, tenant_id)` ON DELETE RESTRICT.
   - FK: `(user_id, tenant_id)` -> `usuarios(id, tenant_id)` ON DELETE RESTRICT.
   - Columnas: `role` (VARCHAR), `status` (VARCHAR: 'INVITED', 'ACTIVE', 'SUSPENDED', 'REVOKED').

5. TABLA `service_offers` (NODO-02):
   - PK: `id` (UUID).
   - Composite Unique: `(id, establishment_id, tenant_id)` via `uq_service_offers_id_establishment_tenant`.
   - FK: `(establishment_id, tenant_id)` -> `establishments(id, tenant_id)` ON DELETE RESTRICT.

6. TABLA `service_assignments` (NODO-02):
   - PK: `id` (UUID).
   - FK Triple: `(service_offer_id, establishment_id, tenant_id)` -> `service_offers(...)` ON DELETE RESTRICT.
   - FK Triple: `(membership_id, establishment_id, tenant_id)` -> `memberships(...)` ON DELETE RESTRICT.
   - Composite Unique: `(service_offer_id, membership_id)`.

7. GENERACIÓN DE UUID EN BASE DE DATOS:
   - 065 ejecuta: `CREATE EXTENSION IF NOT EXISTS "uuid-ossp";`
   - Sin embargo, las tablas 065 (`organizations`, `establishments`, `memberships`), 067 (`service_offers`) y 068 (`service_assignments`) definen:
     `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`
   - `gen_random_uuid()` es la función nativa del estándar PostgreSQL (integrada nativamente en el núcleo desde PostgreSQL 13).

8. CONVENCIONES DE SEGURIDAD Y RLS:
   - Todas las tablas SaaS implementan `ENABLE ROW LEVEL SECURITY`.
   - Política obligatoria: `tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer`.
   - Timestamps de auditoría técnica: `created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP`, `updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP`.
================================================================================
```

---

## 3. PHYSICAL ENTITY PROPOSAL (PROPUESTA DE ENTIDAD FÍSICA)

Se evalúan las alternativas de persistencia:

| Alternativa | Descripción | Veredicto | Justificación Arquitectónica |
| :--- | :--- | :--- | :--- |
| **A. Una tabla normalizada (`staff_schedules`)** | Cada tupla es un intervalo semanal `(membership, establishment, day, start, end)`. | **SELECCIONADA** | Mínima, atómica, fuertemente tipada, relacionalmente indexable y sin sobrecarga de joins. |
| **B. Múltiples tablas (Header + Detail)** | Separación en cabecera `staff_schedules` + detalle `staff_schedule_intervals`. | **RECHAZADA** | Sobrecarga de claves UUID y joins artificiales; la cabecera carece de atributos propios o estado independiente (`N03A-DEC-07`). |
| **C. Columna JSONB en `memberships`** | Almacenar JSON con los 7 días dentro de `memberships`. | **RECHAZADA** | Viola desacoplamiento de Foundation (`065`), degrada validación de integridad relacional e impide checks nativos de orden temporal. |
| **D. Reutilización de `perfiles_prestador.weekly_schedule` (B2C)** | Reusar tabla legacy del marketplace. | **RECHAZADA** | Viola `DEC-SE-002.6` (Axioma de Desacoplamiento B2B/B2C) y el límite del Handover Boundary Contract. |

**Decisión:** Se adopta la **Alternativa A**: Una sola tabla física normalizada `staff_schedules`.

---

## 4. CARDINALITY (CARDINALIDAD FÍSICA)

Conforme a **`N03A-DEC-03` 🔒** (Modelo Semanal Recurrente: 7 días $	imes$ $0..N$ intervalos/día):

```text
[tenants] 1 ──── N [establishments] 1 ──── N [memberships] 1 ──── 0..N [staff_schedules]
```

- **Por Membresía en una Sede:** Admite desde $0$ filas (colaborador sin horario explícito registrado) hasta $M$ filas ($M = \sum_{d=1}^7 K_d$, donde $K_d$ es el número de bloques del día $d$).
- **Por Día de la Semana:** Admite $0$ intervalos (día no laborable / descanso) o $N \ge 1$ intervalos continuos o fraccionados (ej. turnos partidos).

---

## 5. IDENTITY (ESTRATEGIA DE IDENTIDAD)

Se adopta una **clave primaria subrogada UUID (`id`)**:

```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
```

### Justificación Arquitectónica:
1. **Homogeneidad de Plataforma:** Consistencia con todas las tablas de Foundation y NODO-02 (`organizations`, `establishments`, `memberships`, `service_offers`, `service_assignments`).
2. **Desacoplamiento de Atributos Mutables:** Separa la identidad física inmutable del registro de sus coordenadas temporales (`day_of_week`, `start_time`, `end_time`), permitiendo operaciones atómicas e identificables individualmente.

---

## 6. COLUMNS / DATA TYPES (DEFINICIÓN DE COLUMNAS Y TIPOS DE DATOS)

| Columna | Tipo PostgreSQL | Nullable | Default | Propósito / Justificación |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `UUID` | `NOT NULL` | `gen_random_uuid()` | Identificador primario subrogado. |
| `tenant_id` | `INTEGER` | `NOT NULL` | - | Raíz de aislamiento multi-tenant y partición RLS. |
| `establishment_id` | `UUID` | `NOT NULL` | - | Sede operativa contextual donde rige la disponibilidad. |
| `membership_id` | `UUID` | `NOT NULL` | - | Membresía profesional titular del horario. |
| `day_of_week` | `SMALLINT` | `NOT NULL` | - | Día de la semana (1 = Lunes, 2 = Martes, ..., 7 = Domingo, ISO 8601). |
| `start_time` | `TIME WITHOUT TIME ZONE` | `NOT NULL` | - | Hora de inicio del intervalo disponible (`HH:MM:SS` / `HH:MM`). |
| `end_time` | `TIME WITHOUT TIME ZONE` | `NOT NULL` | - | Hora de finalización del intervalo disponible (`HH:MM:SS` / `HH:MM`). |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL` | `CURRENT_TIMESTAMP` | Timestamp de auditoría técnica de creación. |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL` | `CURRENT_TIMESTAMP` | Timestamp de auditoría técnica de última modificación. |

### Justificación de Tipos Temporales:
- **`SMALLINT` para `day_of_week`:** Representación estándar ISO 8601 (1=Lunes .. 7=Domingo). Alta eficiencia en almacenamiento (2 bytes), indexación e index scans.
- **`TIME WITHOUT TIME ZONE` para `start_time` / `end_time`:** El horario semanal recurrente representa una ventana horaria local de la sede. No debe usar fechas absolutas ni zonas horarias, ya que las excepciones de calendario están fuera de alcance para v1.0 (`N03A-DEC-06` 🔒).

---

## 7. FOREIGN KEYS (INTEGRIDAD REFERENCIAL Y AISLAMIENTO)

Para garantizar la imposibilidad física de inconsistencias cross-tenant o cross-establishment:

### 7.1. Clave Foránea a Tenants (Aislamiento Raíz)
```sql
CONSTRAINT fk_staff_schedules_tenant
    FOREIGN KEY (tenant_id)
    REFERENCES tenants(id)
    ON DELETE RESTRICT
```

### 7.2. Clave Foránea Compuesta a Establishments (Anclaje de Sede)
```sql
CONSTRAINT fk_staff_schedules_establishment
    FOREIGN KEY (establishment_id, tenant_id)
    REFERENCES establishments(id, tenant_id)
    ON DELETE RESTRICT
```

### 7.3. Clave Foránea Triple Compuesta a Memberships (DEC-FC-001 Opción A)
```sql
CONSTRAINT fk_staff_schedules_membership
    FOREIGN KEY (membership_id, establishment_id, tenant_id)
    REFERENCES memberships(id, establishment_id, tenant_id)
    ON DELETE RESTRICT
```

> [!IMPORTANT]
> La FK triple compuesta garantiza a nivel del motor relacional que:
> $$	ext{membership.establishment\_id} = 	ext{availability.establishment\_id}$$
> $$	ext{membership.tenant\_id} = 	ext{availability.tenant\_id}$$
> Es físicamente imposible asociar la disponibilidad de un colaborador a una sede o tenant distintos de los de su membresía.

---

## 8. UNIQUE CONSTRAINTS (RESTRICCIONES DE UNICIDAD)

```sql
CONSTRAINT uq_staff_schedules_exact_interval
    UNIQUE (establishment_id, membership_id, day_of_week, start_time)
```

- **Propósito y Límite Físico:** Esta restricción previene la duplicidad exacta de la hora de inicio para el mismo colaborador en el mismo día y sede.
- **Aclaración Crítica de R2:** Este constraint **NO previene solapamientos con horas de inicio distintas** (ej. `09:00–11:00` y `10:00–12:00`). Dicha garantía es provista por la estrategia formal documentada en la Sección 10 y Sección 24.

---

## 9. CHECK CONSTRAINTS (RESTRICCIONES DE DOMINIO TEMPORAL)

### 9.1. Validación de Rango de Día de la Semana
```sql
CONSTRAINT chk_staff_schedules_day_range
    CHECK (day_of_week BETWEEN 1 AND 7)
```

### 9.2. Validación de Orden Cronológico de Intervalo
```sql
CONSTRAINT chk_staff_schedules_time_order
    CHECK (start_time < end_time)
```

---

## 10. OVERLAP STRATEGY (ESTRATEGIA DE NO SOLAPAMIENTO — DOMINIO VS FÍSICO)

Conforme a **`N03A-DEC-04` 🔒**, el no solapamiento es un **INVARIANTE DE DOMINIO CERRADO**:
$$orall \, i 
eq j 	ext{ en el mismo (membership, establishment, day): } [start_i, end_i) \cap [start_j, end_j) = \emptyset$$

### Separación Formal de Responsabilidades:
1. **Invariante de Dominio:** La presencia de intervalos solapados es inválida.
2. **Restricción Física (Exact-Start):** `uq_staff_schedules_exact_interval` previene la colisión de inicios exactos.
3. **Mecanismo de Exigibilidad Integral:** Análisis detallado en la **Sección 24 (R2)** evaluando aplicación, concurrencia, bloqueo transaccional y constraints GiST.

---

## 11. DELETE SEMANTICS (SEMÁNTICA DE ELIMINACIÓN Y CONSERVADURISMO)

Se establece una distinción taxonómica estricta:

$$	ext{DELETE INTERVAL} 
eq 	ext{DELETE ALL SCHEDULES} 
eq 	ext{MEMBERSHIP STATUS CHANGE} 
eq 	ext{DELETE MEMBERSHIP}$$

| Evento | Comportamiento Físico | Comportamiento Semántico |
| :--- | :--- | :--- |
| **Cambio de Estado de Membresía (`SUSPENDED` / `REVOKED`)** | **CERO mutación física** en `staff_schedules`. | `MEMBERSHIP.status` es la autoridad administrativa. La disponibilidad persiste físicamente pero su validez operativa queda dinámicamente inhabilitada (`N03A-DEC-07` 🔒). |
| **Eliminación de un Intervalo Específico** | `DELETE FROM staff_schedules WHERE id = $1` | Remueve únicamente el bloque horario puntual. |
| **Eliminación de Todo el Horario de un Colaborador** | `DELETE FROM staff_schedules WHERE membership_id = $1` | Retorna al colaborador al estado semántico `NOT_CONFIGURED`. |
| **Eliminación Física de Registro Padre (`memberships`, `establishments`, `tenants`)** | **`ON DELETE RESTRICT`** | Regla conservadora estándar de Foundation (`PHYSICAL REFERENTIAL INTEGRITY`). Impide borrados accidentales en cascada. |

---

## 12. TIMESTAMPS (TRAZABILIDAD Y AUDITORÍA TÉCNICA)

Se definen:
- `created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP`
- `updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP`

### Separación de Requisito:
- **Técnico / Auditoría de Infraestructura:** Permite conocer la antigüedad del registro y diagnosticar sincronizaciones o desactualizaciones de horario.
- **Cero Campos de Actor:** No se agregan columnas no solicitadas (`created_by`, `updated_by`, `reason`, `deleted_at`).

---

## 13. RLS DESIGN (DISEÑO DE ROW-LEVEL SECURITY)

Aislamiento multi-tenant nativo e inviolable:

```sql
ALTER TABLE staff_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_staff_schedules ON staff_schedules
    FOR ALL
    USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
```

### Invariantes de Seguridad:
1. RLS se evalúa obligatoriamente en cada sentencia SQL cuando el usuario de conexión es `beauty_app_user` (`NO SUPERUSER`).
2. La variable `app.tenant_id` se inyecta de forma derivada y segura en cada transacción por el middleware de contexto del servidor.

---

## 14. INDEX ECONOMY (EVALUACIÓN Y ECONOMÍA DE ÍNDICES)

Evaluación exhaustiva de patrones de acceso, prefijo izquierdo (*leftmost prefix*) y no redundancia:

```sql
-- 1. Índice para filtrado de aislamiento RLS y consultas por tenant
CREATE INDEX IF NOT EXISTS idx_staff_schedules_tenant_id 
    ON staff_schedules(tenant_id);

-- 2. Índice compuesto para listado de disponibilidades de una sede
CREATE INDEX IF NOT EXISTS idx_staff_schedules_establishment_tenant 
    ON staff_schedules(establishment_id, tenant_id);

-- 3. Índice compuesto para consulta de horario semanal de un colaborador en una sede
CREATE INDEX IF NOT EXISTS idx_staff_schedules_membership_establishment 
    ON staff_schedules(membership_id, establishment_id);
```

### Análisis de Necesidad y Cobertura:
| Índice | Leftmost Prefix | Query Pattern Justificado | ¿Por qué es Necesario? |
| :--- | :--- | :--- | :--- |
| `idx_staff_schedules_tenant_id` | `tenant_id` | RLS filtering en consultas globales por tenant. | Evita escaneo secuencial en tablas con volumen multi-tenant. |
| `idx_staff_schedules_establishment_tenant` | `establishment_id` | Filtrado de horarios de todos los colaboradores de una sede (`WHERE establishment_id = $1 AND tenant_id = $2`). | `idx_staff_schedules_tenant_id` no cubre búsquedas por `establishment_id` al ser éste el discriminador principal de sede. |
| `idx_staff_schedules_membership_establishment` | `membership_id` | Recuperación del horario específico de un colaborador (`WHERE membership_id = $1 AND establishment_id = $2`). | Búsqueda por punto de alta frecuencia para validación de agenda y visualización de perfil staff. |

---

## 15. OPERATING HOURS RELATION (RELACIÓN CON HORARIOS DE LA SEDE)

Conforme a **`DEC-SE-002` 🔒** y **`N03A-DEC-05` 🔒**:

1. **Cero Duplicación:** `staff_schedules` **NO copia** la columna `establishments.operating_hours`.
2. **Cero Restricción Física en DB:** No se implementa ningún trigger, foreign key ni check en PostgreSQL que condicione `start_time` y `end_time` respecto al horario comercial de la sede.
3. **Naturaleza Runtime:** La comparación es exclusivamente un aviso informativo no bloqueante en tiempo de ejecución.

---

## 16. FOUNDATION COMPATIBILITY (COMPATIBILIDAD CON SAAS FOUNDATION)

- **`065_saas_foundation_core.sql`:** Totalmente respetada en modo read-only.
- **`DEC-FC-001` (Opción A):** Utiliza de forma exacta la restricción `uq_membership_id_establishment_tenant` introducida en la migración 068.
- **`067_service_offers.sql` & `068_service_assignments.sql`:** Ortogonalidad garantizada. La asignación de servicios y la disponibilidad horaria permanecen desacopladas física y relacionalmente.

---

## 17. FUTURE COMPATIBILITY (COMPATIBILIDAD CON FUTURO MOTOR DE CITAS)

- **Consulta Downstream:** El diseño permite a un futuro motor de agendamiento consultar de forma eficiente los intervalos disponibles de un colaborador en un día específico:
  ```sql
  SELECT start_time, end_time 
  FROM staff_schedules 
  WHERE membership_id = $1 AND establishment_id = $2 AND day_of_week = $3
  ORDER BY start_time ASC;
  ```
- Cero acoplamiento prematuro con tablas de reservas, slots o bloqueos.

---

## 18. PHYSICAL IMPACT SUMMARY (RESUMEN DEL IMPACTO FÍSICO)

```text
================================================================================
                 RESUMEN DEL IMPACTO FÍSICO FINAL RECONCILIADO (R2)
================================================================================
  Tablas Creadas:            1 (`staff_schedules`)
  Tablas Modificadas:        0
  Columnas Creadas:          9 (`id`, `tenant_id`, `establishment_id`, `membership_id`,
                                `day_of_week`, `start_time`, `end_time`, `created_at`, `updated_at`)
  Claves Primarias:          1 (`id` UUID con DEFAULT gen_random_uuid())
  Claves Foráneas:           3 (`fk_staff_schedules_tenant` [RESTRICT], 
                                `fk_staff_schedules_establishment` [RESTRICT], 
                                `fk_staff_schedules_membership` [Triple Compuesta, RESTRICT])
  Restricciones de Unicidad: 1 (`uq_staff_schedules_exact_interval`)
  Restricciones CHECK:       2 (`chk_staff_schedules_day_range`, `chk_staff_schedules_time_order`)
  Políticas RLS:             1 (`tenant_isolation_staff_schedules` FOR ALL)
  Índices Creados:           3 (`idx_staff_schedules_tenant_id`, 
                                `idx_staff_schedules_establishment_tenant`, 
                                `idx_staff_schedules_membership_establishment`)
  Extensiones Requeridas:    0 (Usa función estándar gen_random_uuid())
================================================================================
```

---

## 19. ALTERNATIVES REJECTED (ALTERNATIVAS EVALUADAS Y RECHAZADAS)

1. **`ON DELETE CASCADE` sobre `memberships`:** Rechazada en R1/R2 en favor de `ON DELETE RESTRICT` para evitar borrados silenciosos y preservar la autoridad de `memberships.status`.
2. **Columnas fijas por día (`monday_start`, etc.):** Rechazada por violar el modelo $0..N$ intervalos/día (`N03A-DEC-03`).
3. **Columna JSONB única en `memberships`:** Rechazada por degradar tipado e indexación relacional.
4. **Campos `TIMESTAMP` con fecha:** Rechazada por no pertenecer a disponibilidad semanal recurrente (`N03A-DEC-06`).

---

## 20. OPEN TECHNICAL DECISIONS (DECISIONES TÉCNICAS ABIERTAS PARA EL DIRECTOR)

Todas las decisiones semánticas y físicas de NODO-03A están cerradas. No quedan decisiones abiertas que bloqueen el diseño físico.

---

## 21. IMPLEMENTATION BOUNDARY (FRONTERA DE IMPLEMENTACIÓN)

```text
ESTE DOCUMENTO ES EXCLUSIVAMENTE UNA ESPECIFICACIÓN DE DISEÑO FÍSICO ARQUITECTÓNICO.

QUEDA ESTRICTAMENTE PROHIBIDO:
- Crear archivos de migración SQL (ej. 069_*.sql).
- Ejecutar DDL o DML en la base de datos PostgreSQL.
- Crear o modificar código JavaScript/Node.js en backend/src/.
- Crear o modificar componentes de frontend.
- Ejecutar pruebas sobre componentes no implementados.

CUALQUIER IMPLEMENTACIÓN REQUIERE LA APROBACIÓN PREVIA DEL DIRECTOR DEL PROYECTO
Y LA EMISIÓN DEL CORRESPONDIENTE IMPLEMENTATION CONTRACT DE NODO-03A.
```

---

## 22. GOVERNANCE SELF-CHECK (AUTO-VERIFICACIÓN DE GOBERNANZA)

```text
[X] No DB mutation
[X] No DDL
[X] No migration
[X] No code
[X] No tests modified
[X] No Foundation modification
[X] No NODO-02 modification
[X] No NODO-03A Contract modification
[X] No frontend
[X] No B2C
[X] No API
[X] No implementation
[X] Overlap invariant preserved
[X] Physical guarantee documented accurately
[X] Concurrency considered
[X] DELETE RESTRICT correctly classified as Physical Referential Integrity
```

---

## 23. R1 RECONCILIATION SUMMARY (RESUMEN DE RECONCILIACIÓN R1)

```text
================================================================================
                    R1 RECONCILIATION SUMMARY
================================================================================
1. DELETE SEMANTICS: Adoptado ON DELETE RESTRICT sobre todas las Foreign Keys.
2. OVERLAP ENFORCEMENT ANALYSIS: Separación formal entre Invariante de Dominio y Mecanismo Físico.
3. UUID / EXTENSION VERIFICATION: Verificado gen_random_uuid() nativo de PostgreSQL 13+.
4. INDEX ECONOMY: Conjunto de 3 índices no redundantes con prefijo izquierdo analizado.
5. FK INTEGRITY: Ratificación de FK triple compuesta (membership_id, establishment_id, tenant_id).
6. RUNTIME / PHYSICAL SEPARATION: Desacoplamiento de códigos HTTP y clases de servicio del esquema físico.
7. FINAL PHYSICAL DESIGN: Tabla única staff_schedules con tipado estricto.
================================================================================
```

---

## 24. R2 — FINAL TEMPORAL ENFORCEMENT RECONCILIATION (PRECISIÓN TÉCNICA Y GARANTÍAS)

```text
================================================================================
          R2 — ANÁLISIS DE ENFORCEMENT TEMPORAL, CONCURRENCIA Y GARANTÍAS
================================================================================
```

### 24.1. Invariante de Dominio (`N03A-DEC-04` 🔒)
El dominio del proyecto define de forma inmutable que **los intervalos de disponibilidad solapados para el mismo colaborador, en la misma sede y en el mismo día están estrictamente prohibidos**:
$$\forall \, i \neq j \text{ en } (establishment\_id, membership\_id, day\_of\_week): \quad [start\_time_i, end\_time_i) \cap [start\_time_j, end\_time_j) = \emptyset$$

### 24.2. Límite del Constraint Físico `UNIQUE`
La restricción física propuesta:
```sql
CONSTRAINT uq_staff_schedules_exact_interval 
    UNIQUE (establishment_id, membership_id, day_of_week, start_time)
```
- **Garantía Provista:** Previene la duplicación exacta del instante de inicio para un colaborador en un día específico.
- **Límite Explícito:** **NO previene solapamientos con horas de inicio desalineadas.**
  *Ejemplo:*
  - Intervalo 1: `09:00` a `11:00`
  - Intervalo 2: `10:00` a `12:00`
  Ambos registros tienen distinto `start_time` (`09:00` $\neq$ `10:00`), por lo que **no violan el constraint UNIQUE físico**.

### 24.3. Análisis de Concurrencia y Condición de Carrera (Race Condition Analysis)
Si la validación de no solapamiento se realizara exclusivamente en memoria a nivel de aplicación mediante lecturas no bloqueantes:
```text
  Transacción A (SET 09:00–11:00)              Transacción B (SET 10:00–12:00)
────────────────────────────────────────────────────────────────────────────────
1. SELECT staff_schedules (ve vacío)        1. SELECT staff_schedules (ve vacío)
2. Valida solapamiento en memoria (OK)      2. Valida solapamiento en memoria (OK)
3. INSERT (09:00–11:00)                     3. INSERT (10:00–12:00)
4. COMMIT                                   4. COMMIT
────────────────────────────────────────────────────────────────────────────────
   Resultado: Ambos inserts son exitosos, violando el Invariante de Dominio en la BD.
```
**Conclusión:** Una validación en aplicación basada en lecturas concurrentes sin control transaccional o de bloqueo es vulnerable a condiciones de carrera.

### 24.4. Evaluación de Alternativas de Enforcement

```text
+-------------------+-------------------------------------------------------------------------------------------------------+
| Alternativa       | Evaluación Técnica                                                                                    |
+-------------------+-------------------------------------------------------------------------------------------------------+
| OPTION A:         | - Correctness: Alta en operaciones normales; vulnerable a concurrencia sin bloqueo de fila.           |
| Validación en     | - Complexity: Mínima.                                                                                 |
| Aplicación Pura   | - Dependencies: Cero dependencias adicionales.                                                        |
|                   | - Multi-tenant Safety: Alta (resuelve por tenant en memoria).                                         |
|                   | - Concurrency: Débil sin mecanismo transaccional de serialización.                                   |
|                   | - Maintainability / Economy: Excelente.                                                               |
+-------------------+-------------------------------------------------------------------------------------------------------+
| OPTION B:         | - Correctness: Absoluta a nivel de motor SQL (bloquea físicamente cualquier solapamiento).            |
| PostgreSQL        | - Complexity: Alta. Requiere transformar `TIME` en rangos sintéticos `tsrange` sobre fechas dummy.     |
| Exclusion         | - Dependencies: Requiere extensión `btree_gist` (no habilitada en Foundation).                         |
| Constraint (GiST) | - Multi-tenant Safety: Total.                                                                         |
|                   | - Concurrency: Total (el motor resuelve los locks a nivel de página/índice GiST).                     |
|                   | - Maintainability / Economy: Regular (overhead de indexación GiST y complejidad de casting).          |
+-------------------+-------------------------------------------------------------------------------------------------------+
| OPTION C:         | - Correctness: Total (eliminación y carga atómica por colaborador).                                   |
| Validación        | - Complexity: Baja.                                                                                   |
| Atómica de        | - Dependencies: Cero extensiones nuevas; usa PostgreSQL estándar.                                     |
| Servicio bajo     | - Multi-tenant Safety: Total (operación contextualizada bajo RLS).                                    |
| Bloqueo / Batch   | - Concurrency: Total (bloqueo a nivel de membresía `SELECT ... FOR UPDATE` o reemplazo atómico).       |
| Transaccional     | - Maintainability / Economy: Óptima. Coincide exactamente con la semántica semanal de NODO-03A.       |
+-------------------+-------------------------------------------------------------------------------------------------------+
```

### 24.5. Enfoque Arquitectónico Seleccionado para v1.0
Se ratifica la **OPTION C (Validación Atómica de Servicio bajo Transacción)** respaldada por el constraint físico `uq_staff_schedules_exact_interval`:
1. La semántica de actualización de disponibilidad de un colaborador es un **reemplazo declarativo de su semana completa** (`PUT /hub/staff/:membership_id/schedule`).
2. En tiempo de ejecución, la transacción backend valida en memoria el orden y no solapamiento de la lista recibida y ejecuta atómicamente el ciclo de actualización para esa membresía en la sede activa bajo el aislamiento de `app.tenant_id`.
3. Esto garantiza integridad total, concurrencia controlada, cero extensiones pesadas GiST y máxima economía relacional.

### 24.6. Garantía Real Provista por el Diseño Físico v1.0
- **Garantizado por PostgreSQL (Motor Físico):**
  1. No duplicidad de inicios exactos (`uq_staff_schedules_exact_interval`).
  2. Rango de día válido $1..7$ (`chk_staff_schedules_day_range`).
  3. Orden cronológico de intervalo `start_time < end_time` (`chk_staff_schedules_time_order`).
  4. Inviolabilidad contextual multi-tenant y de sede (`fk_staff_schedules_membership` triple compuesta).
  5. Aislamiento por tenant a nivel de políticas de seguridad de fila (`RLS`).
- **Garantizado por la Capa de Servicio / Runtime:**
  1. Prohibición estricta de solapamiento de intervalos desalineados (`N03A-DEC-04` 🔒).
  2. Advertencia no bloqueante de exceso sobre horario de sede (`N03A-DEC-05` 🔒).

### 24.7. Clarificación de `ON DELETE RESTRICT`
La regla `ON DELETE RESTRICT` en `fk_staff_schedules_membership` se clasifica estrictamente como **INTEGRIDAD REFERENCIAL FÍSICA** (*Physical Referential Integrity*):
- Su propósito es proteger la consistencia de la base de datos impidiendo borrados físicos silenciosos e incontrolados en cascada.
- **NO constituye una regla de negocio administrativa sobre la membresía:** La gestión de vida de un colaborador en el salón se rige administrativamente por `memberships.status` (`ACTIVE`, `SUSPENDED`, `REVOKED`), donde el cambio de estado no ejecuta `DELETE` sobre `memberships` ni sobre `staff_schedules` (`N03A-DEC-07` 🔒).

---

```text
================================================================================
FINAL STATUS:
  PHYSICAL ARCHITECTURE: APPROVED / CLOSED BY DIRECTOR 🔒
  IMPLEMENTATION: NOT AUTHORIZED (NO CODE BEFORE IMPLEMENTATION CONTRACT)
================================================================================
```
