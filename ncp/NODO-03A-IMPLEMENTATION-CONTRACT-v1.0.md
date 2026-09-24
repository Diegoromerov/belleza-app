# NODO-03A-v1.0 — IMPLEMENTATION CONTRACT (RECONCILED R1)
## Staff Operational Availability & Schedule Runtime Implementation Specification

**ESTADO DEL DOCUMENTO:** `DRAFTED — READY FOR DIRECTOR APPROVAL 🔒`  
**VERSIÓN:** 1.1.0 (R1 Reconciled)  
**TIPO:** Implementation Contract Specification  
**AUTORIDAD RAÍZ:** Director del Proyecto GlowApp SaaS  
**NODO ASOCIADO:** `NODO-03A-v1.0` (Staff Operational Availability & Schedule Runtime)  
**DOCUMENTOS DE BASE APROBADOS Y CERRADOS:**
- [`/ncp/NODO-03A-NODE-CONTRACT-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NODO-03A-NODE-CONTRACT-v1.0.md) (Reconciled R1 🔒)
- [`/ncp/N03A-DEC-001-STAFF-AVAILABILITY-SEMANTIC-DECISION-BUNDLE.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/N03A-DEC-001-STAFF-AVAILABILITY-SEMANTIC-DECISION-BUNDLE.md) (Decisiones `N03A-DEC-01` a `08` 🔒)
- [`/ncp/ARCH-BUNDLE-N03A-PHYSICAL-01.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/ARCH-BUNDLE-N03A-PHYSICAL-01.md) (Reconciled R2 🔒)
- [`/ncp/DEC-FC-001-MEMBERSHIP-REFERENTIAL-INTEGRITY-KEY.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/DEC-FC-001-MEMBERSHIP-REFERENTIAL-INTEGRITY-KEY.md) (Opción A 🔒)
- [`065_saas_foundation_core.sql`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/migrations/065_saas_foundation_core.sql), [`067_service_offers.sql`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/migrations/067_service_offers.sql) & [`068_service_assignments.sql`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/migrations/068_service_assignments.sql)

---

## 1. ARCHITECTURAL PRECONDITIONS & CLOSED CONTEXT

El presente contrato de implementación asume como precondiciones inmutables los siguientes componentes **CLOSED 🔒**:

1. **SaaS Foundation Core (`065`):** `tenants`, `organizations`, `establishments`, `memberships` con aislamiento RLS nativo (`app.tenant_id`).
2. **Context Resolution & Active Context (`066`):** `authMiddleware` y `activeContextMiddleware` resuelven server-side `req.tenantId`, `req.establishmentId`, `req.membershipId` y el rol contextual del actor autenticado.
3. **NODO-01 & NODO-02 (`067`, `068`):** Catálogo de servicios (`service_offers`) y asignaciones operativas (`service_assignments`). La disponibilidad horaria es conceptual y físicamente independiente de las asignaciones de servicios.
4. **DEC-FC-001 (Opción A 🔒):** Clave única compuesta `memberships(id, establishment_id, tenant_id)`.
5. **Axiomas de Dominio (`N03A-DEC-01` a `08` 🔒):**
   - **Autoridad (`N03A-DEC-01`):** `OWNER`, `MANAGER` y `PROFESSIONAL` (auto-gestión acotada: `req.membershipId === target_membership_id`).
   - **Alcance (`N03A-DEC-02`):** `(MEMBERSHIP, ESTABLISHMENT)` dentro de `TENANT`.
   - **Modelo Semanal (`N03A-DEC-03`):** 7 días (`1..7`), $0..N$ intervalos por día.
   - **Prohibición de Solapamiento (`N03A-DEC-04`):** Invariante estricto (`FORBIDDEN`).
   - **Horario de Sede (`N03A-DEC-05`):** `WARNING ONLY` (no bloqueante en v1.0).
   - **Excepciones/Vacaciones (`N03A-DEC-06`):** Fuera de alcance v1.0.
   - **Estado (`N03A-DEC-07`):** Presencia/ausencia declarativa. Validez derivada de `memberships.status === 'ACTIVE'`.
   - **Generación de Slots (`N03A-DEC-08`):** Exclusivamente downstream.

---

## 2. PHYSICAL SCHEMA SPECIFICATION (TABLA `staff_schedules`)

La persistencia física de `NODO-03A` se materializará mediante **una única tabla física nueva** en una migración formal `backend/migrations/069_staff_schedules.sql`:

```sql
-- 1. Estructura de la Tabla staff_schedules
CREATE TABLE IF NOT EXISTS staff_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id INTEGER NOT NULL,
    establishment_id UUID NOT NULL,
    membership_id UUID NOT NULL,
    day_of_week SMALLINT NOT NULL,
    start_time TIME WITHOUT TIME ZONE NOT NULL,
    end_time TIME WITHOUT TIME ZONE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Restricciones de Dominio
    CONSTRAINT chk_staff_schedules_day_range 
        CHECK (day_of_week BETWEEN 1 AND 7),
    CONSTRAINT chk_staff_schedules_time_order 
        CHECK (start_time < end_time),

    -- Integridad Referencial Compuesta (ON DELETE RESTRICT)
    CONSTRAINT fk_staff_schedules_tenant 
        FOREIGN KEY (tenant_id) 
        REFERENCES tenants(id) ON DELETE RESTRICT,
    CONSTRAINT fk_staff_schedules_establishment 
        FOREIGN KEY (establishment_id, tenant_id) 
        REFERENCES establishments(id, tenant_id) ON DELETE RESTRICT,
    CONSTRAINT fk_staff_schedules_membership 
        FOREIGN KEY (membership_id, establishment_id, tenant_id) 
        REFERENCES memberships(id, establishment_id, tenant_id) ON DELETE RESTRICT,

    -- Unicidad de Inicio de Intervalo Exacto (Exact-Start Duplication Prevention)
    CONSTRAINT uq_staff_schedules_exact_interval 
        UNIQUE (establishment_id, membership_id, day_of_week, start_time)
);

-- 2. Índices de Rendimiento No Especulativos
CREATE INDEX IF NOT EXISTS idx_staff_schedules_tenant_id 
    ON staff_schedules(tenant_id);

CREATE INDEX IF NOT EXISTS idx_staff_schedules_establishment_tenant 
    ON staff_schedules(establishment_id, tenant_id);

CREATE INDEX IF NOT EXISTS idx_staff_schedules_membership_establishment 
    ON staff_schedules(membership_id, establishment_id);

-- 3. Row-Level Security (RLS)
ALTER TABLE staff_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_staff_schedules ON staff_schedules
    FOR ALL
    USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer)
    WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::integer);
```

---

## 3. OPERATIONS SPECIFICATION (ESPECIFICACIÓN DETALLADA DE OPERACIONES)

```text
================================================================================
                    MATRIZ DE OPERACIONES RUNTIME NODO-03A
================================================================================
  OP-01: SET_STAFF_SCHEDULE               PUT    /api/v1/saas/hub/staff/:membership_id/schedule
  OP-02: GET_STAFF_SCHEDULE               GET    /api/v1/saas/hub/staff/:membership_id/schedule
  OP-03: LIST_ESTABLISHMENT_STAFF_SCHEDULES GET  /api/v1/saas/hub/staff/schedules
  OP-04: DELETE_STAFF_SCHEDULE            DELETE /api/v1/saas/hub/staff/:membership_id/schedule
================================================================================
```

---

### 3.1. OP-01: `SET_STAFF_SCHEDULE` (Creación o Reemplazo Atómico de Horario Semanal)

- **Propósito:** Establecer o reemplazar completamente la disponibilidad semanal recurrente de una membresía profesional en la sede activa.
- **Verbo y Ruta:** `PUT /api/v1/saas/hub/staff/:membership_id/schedule`
- **Actores Autorizados (`N03A-DEC-01` 🔒):**
  - `OWNER`: Autorizado para cualquier membresía de la sede activa.
  - `MANAGER`: Autorizado para cualquier membresía de la sede activa.
  - `PROFESSIONAL`: Autorizado **únicamente para su propia membresía** (`req.membershipId === req.params.membership_id`).
  - `RECEPTIONIST`: **Denegado (`403 Forbidden`)**.
- **Server-Derived Context (Inyectado por Middleware):**
  - `tenant_id = req.tenantId`
  - `establishment_id = req.establishmentId`
  - `actor_membership_id = req.membershipId`
  - `actor_role = req.activeContext.role`
- **Request Body (Payload Canónico):**
  ```json
  {
    "weekly_schedule": {
      "monday": {
        "is_working": true,
        "time_blocks": [
          { "start_time": "08:00", "end_time": "12:00" },
          { "start_time": "14:00", "end_time": "18:00" }
        ]
      },
      "tuesday": {
        "is_working": true,
        "time_blocks": [{ "start_time": "08:00", "end_time": "17:00" }]
      },
      "wednesday": { "is_working": false, "time_blocks": [] },
      "thursday": { "is_working": true, "time_blocks": [{ "start_time": "08:00", "end_time": "17:00" }] },
      "friday": { "is_working": true, "time_blocks": [{ "start_time": "08:00", "end_time": "17:00" }] },
      "saturday": { "is_working": true, "time_blocks": [{ "start_time": "09:00", "end_time": "14:00" }] },
      "sunday": { "is_working": false, "time_blocks": [] }
    }
  }
  ```
- **Validaciones de Negocio y Precondiciones:**
  1. **Autorización:** Si `actor_role === 'PROFESSIONAL'` y `req.params.membership_id !== actor_membership_id`, abortar con `403 FORBIDDEN_SELF_MANAGEMENT_ONLY`.
  2. **Existencia y Estado de Membresía:** Consultar `memberships` verificando que `id = req.params.membership_id`, `establishment_id = req.establishmentId`, `tenant_id = req.tenantId`. Si no existe o pertenece a otra sede/tenant, abortar con `404 MEMBERSHIP_NOT_FOUND` / `422 ESTABLISHMENT_MISMATCH`. Si `status !== 'ACTIVE'`, abortar con `422 INACTIVE_MEMBERSHIP`.
  3. **Validación de Días (1..7 / monday..sunday):** La estructura debe contener días canónicos válidos.
  4. **Validación de Intervalos Horarios:**
     - Formato: `HH:MM` o `HH:MM:SS` válido (`00:00` a `23:59`).
     - Orden Cronológico: `start_time < end_time` para cada bloque. En caso contrario, abortar con `400 INVALID_TIME_ORDER`.
  5. **Validación de Solapamiento Intradía (`N03A-DEC-04` 🔒):**
     - Para cada día con $N \ge 2$ bloques, ordenar los bloques por `start_time` y verificar que:
       $$orall \, k \in [1, N-1]: \quad 	ext{end\_time}_k \le 	ext{start\_time}_{k+1}$$
     - Si existe cualquier intersección ($	ext{start}_{k+1} < 	ext{end}_k$), abortar con `400 OVERLAPPING_INTERVALS`.
  6. **Evaluación de Horario de Sede (`N03A-DEC-05` 🔒):**
     - Comparar los bloques del colaborador con `establishments.operating_hours`.
     - Si algún bloque excede el horario comercial o cae en día no operativo de la sede, marcar `out_of_operating_hours_warning = true` (comportamiento informativo no bloqueante).
- **Comportamiento Transaccional y Persistencia:**
  - Ejecutar dentro de una transacción con `SET LOCAL app.tenant_id = $1`:
    1. Control de consistencia concurrente: Serializar la operación para la tupla `(membership_id, establishment_id)`.
    2. Eliminación de disponibilidad previa: `DELETE FROM staff_schedules WHERE establishment_id = $1 AND membership_id = $2`.
    3. Inserción de los nuevos intervalos normalizados en batch:
       ```sql
       INSERT INTO staff_schedules (tenant_id, establishment_id, membership_id, day_of_week, start_time, end_time)
       VALUES ($1, $2, $3, $4, $5, $6);
       ```
- **Respuesta Canónica (`200 OK`):**
  ```json
  {
    "success": true,
    "data": {
      "membership_id": "8f3b2a1c-4d5e-6f7a-8b9c-0d1e2f3a4b5c",
      "establishment_id": "e4b2d3c1-7a89-4f5e-b123-456789abcdef",
      "tenant_id": 2,
      "schedule_state": "CONFIGURED",
      "out_of_operating_hours_warning": false,
      "weekly_schedule": {
        "monday": { "is_working": true, "time_blocks": [{ "start_time": "08:00", "end_time": "12:00" }, { "start_time": "14:00", "end_time": "18:00" }] },
        "tuesday": { "is_working": true, "time_blocks": [{ "start_time": "08:00", "end_time": "17:00" }] },
        "wednesday": { "is_working": false, "time_blocks": [] },
        "thursday": { "is_working": true, "time_blocks": [{ "start_time": "08:00", "end_time": "17:00" }] },
        "friday": { "is_working": true, "time_blocks": [{ "start_time": "08:00", "end_time": "17:00" }] },
        "saturday": { "is_working": true, "time_blocks": [{ "start_time": "09:00", "end_time": "14:00" }] },
        "sunday": { "is_working": false, "time_blocks": [] }
      }
    }
  }
  ```

---

### 3.2. OP-02: `GET_STAFF_SCHEDULE` (Consulta de Horario de Colaborador)

- **Propósito:** Recuperar la disponibilidad semanal configurada para una membresía en la sede activa.
- **Verbo y Ruta:** `GET /api/v1/saas/hub/staff/:membership_id/schedule`
- **Actores Autorizados:** `OWNER`, `MANAGER`, `PROFESSIONAL`, `RECEPTIONIST` dentro del contexto activo.
- **Validaciones:**
  - Verificar que la membresía objetivo pertenezca a la sede activa y al tenant activo.
  - Si la membresía no existe o no pertenece a la sede: `404 MEMBERSHIP_NOT_FOUND` / `422 ESTABLISHMENT_MISMATCH`.
- **Comportamiento ante Colaborador sin Horario Registrado (`N03A-DEC-07` 🔒):**
  - Si no existen filas en `staff_schedules` para la membresía: Retornar `200 OK` con `schedule_state: "NOT_CONFIGURED"`, `out_of_operating_hours_warning: false` y los 7 días con `is_working: false` y `time_blocks: []`.
- **Respuesta Canónica (`200 OK`):** Mismo DTO estructurado de `StaffScheduleDTO`.

---

### 3.3. OP-03: `LIST_ESTABLISHMENT_STAFF_SCHEDULES` (Listado de Disponibilidades de la Sede)

- **Propósito:** Listar la disponibilidad semanal configurada de todos los colaboradores activos de la sede.
- **Verbo y Ruta:** `GET /api/v1/saas/hub/staff/schedules`
- **Actores Autorizados:** `OWNER`, `MANAGER`, `PROFESSIONAL`, `RECEPTIONIST` dentro del contexto activo.
- **Persistencia SQL:**
  ```sql
  SELECT m.id AS membership_id, m.status, u.nombre, u.apellido, m.role,
         s.id AS schedule_id, s.day_of_week, s.start_time, s.end_time
  FROM memberships m
  JOIN usuarios u ON m.user_id = u.id
  LEFT JOIN staff_schedules s ON m.id = s.membership_id AND s.establishment_id = m.establishment_id
  WHERE m.establishment_id = $1 AND m.tenant_id = $2 AND m.status = 'ACTIVE'
  ORDER BY m.id, s.day_of_week, s.start_time;
  ```
- **Respuesta Canónica (`200 OK`):**
  ```json
  {
    "success": true,
    "data": [
      {
        "membership_id": "8f3b2a1c-4d5e-6f7a-8b9c-0d1e2f3a4b5c",
        "user_name": "Ana Gómez",
        "role": "PROFESSIONAL",
        "schedule_state": "CONFIGURED",
        "weekly_schedule": { ... }
      },
      {
        "membership_id": "3a4b5c6d-7e8f-9a0b-1c2d-3e4f5a6b7c8d",
        "user_name": "Carlos Ruíz",
        "role": "PROFESSIONAL",
        "schedule_state": "NOT_CONFIGURED",
        "weekly_schedule": { ... }
      }
    ]
  }
  ```

---

### 3.4. OP-04: `DELETE_STAFF_SCHEDULE` (Eliminación Completa de Disponibilidad en Sede Activa)

- **Propósito:** Eliminar toda la disponibilidad declarada (`staff_schedules`) para una membresía en el contexto de la sede activa, retornando al colaborador al estado semántico `NOT_CONFIGURED`.
- **Verbo y Ruta:** `DELETE /api/v1/saas/hub/staff/:membership_id/schedule`
- **Semántica Exacta:** `DELETE ALL SCHEDULES FOR TARGET MEMBERSHIP IN ACTIVE ESTABLISHMENT CONTEXT`.
  - **No elimina la Membresía (`memberships`).**
  - **No modifica `memberships.status`** (preserva su estado administrativo).
  - **No elimina el Establecimiento (`establishments`).**
  - **No afecta las Asignaciones de Servicios (`service_assignments`).**
  - **No afecta las Ofertas de Servicios (`service_offers`).**
  - **No modifica `establishments.operating_hours`.**
  - **No interactúa con el esquema B2C.**
- **Actores Autorizados (`N03A-DEC-01` 🔒):**
  - `OWNER`: Autorizado.
  - `MANAGER`: Autorizado.
  - `PROFESSIONAL`: **Denegado (`403 Forbidden`)**.
  - `RECEPTIONIST`: **Denegado (`403 Forbidden`)**.
- **Persistencia SQL:**
  ```sql
  DELETE FROM staff_schedules 
  WHERE establishment_id = $1 AND membership_id = $2 AND tenant_id = $3;
  ```
- **Respuesta Canónica (`200 OK`):**
  ```json
  {
    "success": true,
    "message": "Staff schedule deleted successfully. State reverted to NOT_CONFIGURED.",
    "membership_id": "8f3b2a1c-4d5e-6f7a-8b9c-0d1e2f3a4b5c",
    "schedule_state": "NOT_CONFIGURED"
  }
  ```

---

## 4. OVERLAP ENFORCEMENT & CONCURRENCY IMPLEMENTATION PATTERN

### 4.1. Contractual Requirement vs Implementation Mechanism
- **Requisito Contractual de Dominio (`N03A-DEC-04` 🔒 & ARCH-BUNDLE R2):** La implementación debe garantizar de forma estricta e inviolable que **no existan intervalos solapados** para el mismo `(membership_id, establishment_id, day_of_week)`. La implementación debe mitigar y resolver condiciones de carrera concurrentes.
- **Límite Físico:** `uq_staff_schedules_exact_interval` previene únicamente la duplicación exacta de `start_time`.
- **Mecanismo de Implementación de Runtime:**
  - El mecanismo permitido para serializar operaciones concurrentes sobre el horario de un colaborador es la ejecución dentro de una transacción con bloqueo de fila sobre la membresía objetivo:
    ```sql
    SELECT id, status, establishment_id 
    FROM memberships 
    WHERE id = $target_membership_id AND establishment_id = $active_establishment_id
    FOR UPDATE;
    ```
  - *Clasificación Técnica:* Este mecanismo se define formalmente como un **IMPLEMENTATION MECHANISM** (detalle de implementación de software) y **NO como una decisión de arquitectura cerrada**. Garantiza la serialización de escrituras concurrentes para el mismo colaborador, evitando que dos transacciones simultáneas inserten intervalos incompatibles.
  - Cero dependencias de extensiones `btree_gist`, cero exclusion constraints físicos en DB, cero advisory locks y cero nuevas tablas/columnas.

---

## 5. FILES TO CREATE, MODIFY AND PROTECT

### 5.1. Files to Create (`[NEW]`)
1. `backend/migrations/069_staff_schedules.sql`: Migración física para tabla `staff_schedules`, índices, RLS y foreign keys con `ON DELETE RESTRICT`.
2. `backend/src/services/staffAvailabilityService.js`: Lógica de negocio, validaciones temporales, comparación con horarios de sede y reemplazo atómico transaccional.
3. `backend/src/controllers/staffAvailabilityController.js`: Controladores HTTP para endpoints `/api/v1/saas/hub/staff/...`.
4. `backend/src/routes/staffAvailabilityRoutes.js`: Definición de rutas protegidas bajo `authMiddleware` y `activeContextMiddleware`.
5. `backend/tests/test_staff_availability_suite.js`: Suite completa de pruebas automatizadas unitarias, de integración y RLS.

### 5.2. Files That May Be Modified (`[MODIFY]`)
1. `backend/index.js`: Montaje de `staffAvailabilityRoutes` en `/api/v1/saas/hub/staff`.

### 5.3. Protected Assets (`[PROTECTED — ZERO TOUCH]`)
- `backend/migrations/065_saas_foundation_core.sql` 🔒
- `backend/migrations/066_context_resolution_tenant_resolver.sql` 🔒
- `backend/migrations/067_service_offers.sql` 🔒
- `backend/migrations/068_service_assignments.sql` 🔒
- `backend/src/middleware/activeContextMiddleware.js` 🔒
- `backend/src/services/contextResolutionService.js` 🔒
- `backend/src/services/activeContextService.js` 🔒
- `backend/src/services/serviceOfferService.js` 🔒
- `backend/src/services/serviceAssignmentService.js` 🔒
- Todas las suites de pruebas existentes (`test_nodo01_suite.js`, `test_nodo02_runtime_suite.js`, etc.).
- Todo el frontend y tablas B2C (`public.services`, `public.bookings`, `public.perfiles_prestador`).

---

## 6. TEST SUITE REQUIREMENTS (MATRIZ DE PRUEBAS OBLIGATORIA)

La implementación deberá validar los siguientes escenarios automatizados al 100%:

| ID | Test Scenario | Actor / Request | Comportamiento Esperado |
| :--- | :--- | :--- | :--- |
| **TS-01** | `SET_STAFF_SCHEDULE` por `OWNER` con semana completa válida | `OWNER`, payload con bloques en varios días | `200 OK`, `schedule_state: "CONFIGURED"`, intervalos persistidos |
| **TS-02** | `SET_STAFF_SCHEDULE` por `MANAGER` para colaborador | `MANAGER`, payload válido | `200 OK`, disponibilidad persistida |
| **TS-03** | Auto-gestión `PROFESSIONAL` propia (`req.membershipId === target`) | `PROFESSIONAL` autenticado para sí mismo | `200 OK`, disponibilidad persistida |
| **TS-04** | Intento de `PROFESSIONAL` de mutar horario de otro colaborador | `PROFESSIONAL` (`req.membershipId !== target`) | `403 Forbidden` (`FORBIDDEN_SELF_MANAGEMENT_ONLY`) |
| **TS-05** | Intento de `SET_STAFF_SCHEDULE` por `RECEPTIONIST` | `RECEPTIONIST` | `403 Forbidden` (`FORBIDDEN_ROLE`) |
| **TS-06** | `SET_STAFF_SCHEDULE` con `start_time >= end_time` (ej. 18:00 a 08:00) | `OWNER`, payload inválido | `400 Bad Request` (`INVALID_TIME_ORDER`) |
| **TS-07** | `SET_STAFF_SCHEDULE` con intervalos solapados en el mismo día | `OWNER`, payload con 08:00-12:00 y 10:00-14:00 | `400 Bad Request` (`OVERLAPPING_INTERVALS`) |
| **TS-08** | `SET_STAFF_SCHEDULE` fuera de horario comercial de la sede | `OWNER`, horas excedentes | `200 OK` con `out_of_operating_hours_warning: true` |
| **TS-09** | `SET_STAFF_SCHEDULE` sobre membresía `SUSPENDED` o `REVOKED` | `OWNER`, membresía inactiva | `422 Unprocessable Entity` (`INACTIVE_MEMBERSHIP`) |
| **TS-10** | `SET_STAFF_SCHEDULE` sobre membresía de otra sede (mismatch) | `OWNER`, target de otra sede | `422 Unprocessable Entity` / `404 Not Found` |
| **TS-11** | `GET_STAFF_SCHEDULE` para colaborador configurado | Cualquier rol contextual | `200 OK` con DTO estructurado completo |
| **TS-12** | `GET_STAFF_SCHEDULE` para colaborador no configurado | Cualquier rol contextual | `200 OK` con `schedule_state: "NOT_CONFIGURED"` y arrays vacíos |
| **TS-13** | `LIST_ESTABLISHMENT_STAFF_SCHEDULES` | Cualquier rol contextual | `200 OK`, lista de todos los colaboradores activos |
| **TS-14** | `DELETE_STAFF_SCHEDULE` por `OWNER` / `MANAGER` | `OWNER` / `MANAGER` | `200 OK`, horario eliminado, retorna a `NOT_CONFIGURED` |
| **TS-15** | `DELETE_STAFF_SCHEDULE` por `PROFESSIONAL` | `PROFESSIONAL` (incluso propio) | `403 Forbidden` (`FORBIDDEN_ROLE`) |
| **TS-16** | Aislamiento RLS Cross-Tenant (consulta de horarios de otro tenant) | Token de Tenant 1 consultando horarios de Tenant 2 | `0` filas retornadas / `404 Not Found` (Inviolabilidad RLS) |
| **TS-17** | Regresión Cero en Suites Existentes | Ejecución de suites Foundation, NODO-01 y NODO-02 | 86/86 tests previos pasan inalterados |

---

## 7. NON-SCOPE & BOUNDARIES (LÍMITES EXPLÍCITOS DE NO ALCANCE)

Quedan formalmente excluidos de la implementación de `NODO-03A`:
1. **Generación de Slots de Citas:** Cálculo dinámico de intervalos agendables.
2. **Bookings, Calendario y Citas:** Creación o mutación de reservas de clientes.
3. **Sincronización B2C:** Cero impacto en `perfiles_prestador.weekly_schedule`.
4. **Excepciones de Calendario / Vacaciones:** Ausencias puntuales y licencias.
5. **Nómina y Comisiones:** Contabilidad de horas laboradas.
6. **Frontend UI:** Pantallas o componentes visuales de React/Next.js/HTML.

---

## 8. IMPLEMENTATION STOP CONDITIONS & CLOSURE CRITERIA

### Condiciones de Parada durante la Fase de Implementación:
- Si se detecta necesidad de crear tablas adicionales no aprobadas → **ARCHITECTURAL STOP**.
- Si se requiere relajar las restricciones de RLS o bypass de `app.tenant_id` → **ARCHITECTURAL STOP**.
- Si falla cualquier test de las 86 pruebas existentes de Foundation, NODO-01 o NODO-02 → **REGRESSION STOP**.

### Criterios de Cierre de NODO-03A:
1. Migración `069_staff_schedules.sql` aplicada con éxito.
2. Controladores, servicios y rutas de `NODO-03A` operativos.
3. Suite `test_staff_availability_suite.js` con 100% de tests pasando.
4. Suites de regresión previas con 86/86 tests pasando.
5. Auditoría independiente final con veredicto PASS y cero observaciones.

---

## 9. GOVERNANCE SELF-CHECK

```text
[X] No implementation
[X] No DB mutation
[X] No DDL executed
[X] No migration created
[X] No code created
[X] No test modification
[X] No Foundation modification
[X] No closed-node modification
[X] No Contract modification
[X] No Physical Architecture modification
[X] No architectural invention
[X] Concurrency requirement preserved
[X] Mechanism correctly classified (Implementation Mechanism vs Architectural Decision)
[X] DELETE semantics explicitly traced (DELETE ALL SCHEDULES FOR TARGET MEMBERSHIP IN ACTIVE ESTABLISHMENT)
[X] Closed decisions preserved
[X] Scope unchanged
[X] Implementation remains unauthorized
```

---

## 10. R1 — DIRECTOR RECONCILIATION REGISTRATION

```text
================================================================================
                    R1 DIRECTOR RECONCILIATION REGISTRATION
================================================================================

1. CONCURRENCY MECHANISM CLASSIFICATION:
   - Requisito: La consistencia concurrente y la garantía contra condiciones de carrera
     son un CONTRACTUAL REQUIREMENT.
   - Clasificación de FOR UPDATE: Se documenta explícitamente como un IMPLEMENTATION MECHANISM
     (detalle de software de runtime) y NO como una decisión de arquitectura cerrada.
   - Justificación: Permite serializar las operaciones concurrentes sobre el horario de un
     mismo colaborador sin introducir extensiones, advisory locks ni esquemas pesados.

2. DELETE_STAFF_SCHEDULE SEMANTICS:
   - Trazabilidad y Significado Exacto: Representa la eliminación completa de toda la
     disponibilidad configurada (DELETE ALL SCHEDULES FOR TARGET MEMBERSHIP IN ACTIVE
     ESTABLISHMENT CONTEXT).
   - Invariantes Confirmados:
     * NO elimina la fila en memberships.
     * NO altera memberships.status (mantiene su vigencia administrativa).
     * NO elimina establishments ni tenants.
     * NO altera service_assignments ni service_offers.
     * NO muta establishments.operating_hours.
     * NO interactúa con esquemas B2C.
     * Retorna la disponibilidad del colaborador al estado declarativo NOT_CONFIGURED.

3. TRACEABILITY TO APPROVED NODE CONTRACT:
   - Se auditaron las 4 operaciones (OP-01 a OP-04), coincidiendo exactamente al 100%
     con NODO-03A-NODE-CONTRACT-v1.0.md.
   - Cero operaciones agregadas o eliminadas.
   - Roles y matriz de autorización intactos (OWNER, MANAGER, PROFESSIONAL self-management,
     RECEPTIONIST denegado para escritura).

4. CONFIRMATION OF SCOPE & NON-SCOPE:
   - Se ratifica la absoluta preservación del alcance y límites aprobados.
   - Ninguna decisión arquitectónica cerrada fue reabierta.
================================================================================
```

---

```text
================================================================================
FINAL STATUS:
  NODO-03A IMPLEMENTATION CONTRACT:
  DRAFTED — READY FOR DIRECTOR APPROVAL 🔒

NO IMPLEMENTATION AUTHORIZED.
================================================================================
```
