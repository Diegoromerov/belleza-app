# NODO-03A-v1.0 — ARCHITECTURAL NODE CONTRACT (RECONCILED R1)
## Staff Operational Availability & Schedule Runtime

**ESTADO DEL DOCUMENTO:** `RECONCILED — READY FOR DIRECTOR APPROVAL 🔒`  
**VERSIÓN:** 1.0.0 (R1 Reconciled)  
**TIPO:** Architectural Node Contract Definition  
**AUTORIDAD RAÍZ:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `GOAL — N03A-NODE-CONTRACT-01` / `GOAL — N03A-002`  
**DOCUMENTO DE BASE APROBADO:** [`/ncp/N03A-STAFF-AVAILABILITY-DISCOVERY-01.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/N03A-STAFF-AVAILABILITY-DISCOVERY-01.md)  
**DECISION BUNDLE RATIFICADO:** [`/ncp/N03A-DEC-001-STAFF-AVAILABILITY-SEMANTIC-DECISION-BUNDLE.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/N03A-DEC-001-STAFF-AVAILABILITY-SEMANTIC-DECISION-BUNDLE.md)  
**FECHA DE RECONCILIACIÓN:** 2026-09-11  

---

## 1. NODE ID
`NODO-03A-v1.0`

---

## 2. NAME
**Staff Operational Availability & Schedule Runtime**

---

## 3. TYPE
**Conceptual & Architectural Node Contract** (Pre-Implementation Contract)

---

## 4. PURPOSE (PROPÓSITO)
`NODO-03A` resuelve la definición, consulta, actualización y eliminación de la **jornada laboral y disponibilidad operativa semanal recurrente de los colaboradores (`MEMBERSHIPS`) dentro del contexto de una sede específica (`ESTABLISHMENT`)**, bajo estricto aislamiento multi-tenant (`TENANT`).

El nodo proporciona la capacidad formal para que la administración del salón (`OWNER`, `MANAGER`) y los propios colaboradores (`PROFESSIONAL` bajo auto-gestión acotada) mantengan las ventanas de tiempo en las que el personal presta servicios en el establecimiento, desacoplado de los horarios comerciales generales de la sede y de los perfiles individuales B2C.

---

## 5. SCOPE (ALCANCE INCLUIDO)
1. **`SET_STAFF_SCHEDULE`:** Crear o reemplazar la disponibilidad semanal recurrente de una membresía profesional en la sede activa.
2. **`GET_STAFF_SCHEDULE`:** Consultar la disponibilidad semanal configurada para una membresía específica en la sede activa.
3. **`LIST_ESTABLISHMENT_STAFF_SCHEDULES`:** Listar las disponibilidades configuradas de todos los colaboradores activos de la sede.
4. **`DELETE_STAFF_SCHEDULE`:** Eliminar la configuración de horario de un colaborador (dejando su disponibilidad en estado no configurado).
5. **Validación de Integridad Contextual:** Garantizar que el colaborador pertenezca a la sede activa, al tenant activo y posea estado `ACTIVE`.
6. **Validación de Intervalos Horarios:** Validar consistencia cronológica (`inicio < fin`, `00:00..23:59`, prohibición de solapamiento intradía).
7. **Comparación Informativa con Horario de Sede:** Emitir advertencia no bloqueante (`out_of_operating_hours_warning`) si los bloques exceden el horario comercial de la sede.

---

## 6. NON-SCOPE (FUERA DE ALCANCE EXPLÍCITO)
1. **Generación de Slots de Cita:** `NODO-03A` no genera intervalos de agendamiento (`slots`); es un mantenedor de disponibilidad declarativa únicamente.
2. **Reservas, Agenda y Calendario:** Cero gestión de citas, bookings internos o reservas de clientes.
3. **Esquema B2C / Marketplace (`Pre-Nodo 01`):** Cero mutación en `public.services`, `public.bookings` o `public.perfiles_prestador`.
4. **Sincronización con `weekly_schedule` B2C:** No existe replicación automática hacia el perfil marketplace (`DEC-SE-002.6` 🔒).
5. **Excepciones de Calendario / Vacaciones:** Vacaciones, ausencias, licencias médicas y bloqueos puntuales están fuera de alcance para v1.0 (`N03A-DEC-06` 🔒).
6. **Cálculo de Pagos, Comisiones y Nómina:** Cero gestión financiera de horas laboradas.
7. **Control de Asistencia Físico (Clock-in / Clock-out):** Cero registro biométrico o de asistencia en tiempo real.
8. **Asignación de Servicios (`NODO-02`):** No modifica `service_offers` ni `service_assignments`.
9. **Handover Boundary & NODO-01:** Permanece desacoplado e inmutable.
10. **Implementación de UI Frontend:** Este contrato define la capa lógica y de servicio; la interfaz gráfica es downstream.

---

## 7. INPUTS (ENTRADAS Y CONTEXTO)
### 7.1. Contexto Inyectado por el Servidor (Server-Derived — Zero Client Spoofing)
- `req.tenantId`: UUID derivado por `authMiddleware` / `activeContextMiddleware`.
- `req.establishmentId`: UUID de la sede activa.
- `req.membershipId`: UUID de la membresía del actor autenticado.
- `req.activeContext`: Descriptor de contexto autenticado.

### 7.2. Entradas del Cliente (Payload de Request)
- `target_membership_id`: UUID de la membresía del colaborador objetivo.
- `weekly_schedule`: Estructura canónica de 7 días de la semana (`monday` a `sunday`), con:
  - `is_working`: boolean.
  - `time_blocks`: array de $0..N$ intervalos `[{ start_time: "HH:MM", end_time: "HH:MM" }]`.

---

## 8. OUTPUTS (SALIDAS CANÓNICAS)
### 8.1. DTO Canónico de Horario de Colaborador (`StaffScheduleDTO`)
```json
{
  "membership_id": "8f3b2a1c-4d5e-6f7a-8b9c-0d1e2f3a4b5c",
  "establishment_id": "e4b2d3c1-7a89-4f5e-b123-456789abcdef",
  "tenant_id": "c1d2e3f4-a5b6-7c8d-9e0f-1a2b3c4d5e6f",
  "schedule_state": "CONFIGURED",
  "out_of_operating_hours_warning": false,
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
    "wednesday": {
      "is_working": true,
      "time_blocks": [{ "start_time": "08:00", "end_time": "17:00" }]
    },
    "thursday": {
      "is_working": true,
      "time_blocks": [{ "start_time": "08:00", "end_time": "17:00" }]
    },
    "friday": {
      "is_working": true,
      "time_blocks": [{ "start_time": "08:00", "end_time": "17:00" }]
    },
    "saturday": {
      "is_working": false,
      "time_blocks": []
    },
    "sunday": {
      "is_working": false,
      "time_blocks": []
    }
  },
  "created_at": "2026-09-11T10:00:00.000Z",
  "updated_at": "2026-09-11T10:00:00.000Z"
}
```

---

## 9. ACTORS & AUTHORIZATION MATRIX (MATRIZ DE AUTORIDAD RATIFICADA)

Conforme a la directiva **`N03A-DEC-01` 🔒**, la autoridad queda formalizada con **Auto-Gestión Acotada para el Profesional**:

| Operación | Método & Ruta | `OWNER` | `MANAGER` | `PROFESSIONAL` | `RECEPTIONIST` |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **`SET_STAFF_SCHEDULE`** | `PUT /api/v1/saas/hub/staff/:membership_id/schedule` | **ALLOW** | **ALLOW** | **SELF-ONLY (`req.membershipId === target`)** | **DENY (403)** |
| **`GET_STAFF_SCHEDULE`** | `GET /api/v1/saas/hub/staff/:membership_id/schedule` | **ALLOW** | **ALLOW** | **ALLOW** | **ALLOW** |
| **`LIST_STAFF_SCHEDULES`** | `GET /api/v1/saas/hub/staff/schedules` | **ALLOW** | **ALLOW** | **ALLOW** | **ALLOW** |
| **`DELETE_STAFF_SCHEDULE`** | `DELETE /api/v1/saas/hub/staff/:membership_id/schedule` | **ALLOW** | **ALLOW** | **DENY (403)** | **DENY (403)** |

---

## 10. BUSINESS RULES (REGLAS DE NEGOCIO E INVARIANTES)

1. **R01 — Pertenencia Estricta a Sede (`N03A-DEC-02` 🔒):** `target_membership_id` debe pertenecer rigurosamente al `establishment_id` y `tenant_id` activos. Intento cruzado retorna `422 Unprocessable Entity` (`CROSS_ESTABLISHMENT_MISMATCH`).
2. **R02 — Membresía Activa Requerida:** La membresía objetivo debe tener `status === 'ACTIVE'`. Membresías en `SUSPENDED` o `TERMINATED` no pueden recibir configuración de horario (`422 INACTIVE_MEMBERSHIP_TARGET`).
3. **R03 — Roles Elegibles para Horario:** Solo miembros con rol operativo (`PROFESSIONAL`, `OWNER`, `MANAGER`) pueden tener horarios de servicio.
4. **R04 — Validación Cronológica de Bloques (`N03A-DEC-03` 🔒):**
   - Formato estricto `HH:MM` (24 horas: `00:00` a `23:59`).
   - Para cada bloque: `start_time < end_time`.
   - Duración mínima de bloque $\ge 15$ minutos.
5. **R05 — Prohibición Semántica de Solapamiento Intradía (`N03A-DEC-04` 🔒):** Para un mismo colaborador, sede y día, dos bloques horarios $[s_1, e_1]$ y $[s_2, e_2]$ no pueden intersectarse ($\max(s_1, s_2) < \min(e_1, e_2)$ es inválido y retorna `400 Bad Request`).
6. **R06 — Relación con Horario de Sede: Warning Only (`N03A-DEC-05` 🔒):** Si los bloques del colaborador exceden los límites de `establishments.operating_hours`, la operación **se acepta** pero el DTO incluye `out_of_operating_hours_warning: true` (cero rechazo bloqueante en v1.0).
7. **R07 — Inmutabilidad de Pertenencia:** El horario está indexado por `(tenant_id, establishment_id, membership_id)`. No puede transferirse a otra sede ni a otro colaborador.
8. **R08 — Semántica de Eliminación Pura:** `DELETE_STAFF_SCHEDULE` elimina la disponibilidad registrada sin alterar la membresía ni las asignaciones de servicios de `NODO-02`.

---

## 11. TEMPORAL MODEL (MODELO TEMPORAL)

Conforme a **`N03A-DEC-03`** y **`N03A-DEC-06`**:
```text
+------------------------------------+-----------------------+---------------------------------------------------+
| Dimensión Temporal                 | Estado en NODO-03A    | Tratamiento Contractual                           |
+------------------------------------+-----------------------+---------------------------------------------------+
| A. Weekly Recurring Availability   | INCLUIDO EN ALCANCE   | Matriz canónica semanal (7 días, 0..N bloques/día)|
| B. One-off Exception (Bloqueo día) | EXCLUIDO EN v1.0      | UNDEFINED / FUTURE CAPABILITY (N03A-DEC-06 🔒)    |
| C. Absence / Vacation / Medical    | EXCLUIDO EN v1.0      | UNDEFINED / FUTURE CAPABILITY (N03A-DEC-06 🔒)    |
| D. Shift Rotation (Turnos cíclicos)| EXCLUIDO EN v1.0      | UNDEFINED / FUTURE CAPABILITY                     |
+------------------------------------+-----------------------+---------------------------------------------------+
```

---

## 12. ESTABLISHMENT BOUNDARY (FRONTERA DE ESTABLECIMIENTO)
La disponibilidad pertenece estrictamente a la pareja `(MEMBERSHIP, ESTABLISHMENT)` (**`N03A-DEC-02` 🔒**). Si un usuario posee membresías en múltiples sedes, cada sede mantiene una configuración de horario completamente autónoma e independiente, en estricto cumplimiento de `DEC-SE-002.1` y `002.3`.

---

## 13. MEMBERSHIP BOUNDARY (FRONTERA DE MEMBRESÍA)
- Solo membresías en estado `ACTIVE` pueden crear, actualizar o tener disponibilidad operacional activa.
- Si una membresía transiciona a `SUSPENDED` o `TERMINATED`, su disponibilidad operativa queda dinámicamente inhabilitada en tiempo real sin mutar la entidad de horario (`N03A-DEC-07` 🔒).

---

## 14. RELATION TO ASSIGNMENT (RELACIÓN CON NODO-02)
- **Desacoplamiento Estricto:** `ASSIGNMENT` (`service_assignments`) confiere la idoneidad y autorización técnica para realizar un servicio (`DEC-AS-014` 🔒). `STAFF_SCHEDULE` modela la presencia temporal en sede.
- `NODO-03A` no consume ni modifica `service_assignments`. La conjunción entre idoneidad y horario para agendar citas corresponde a un motor downstream posterior (`SaaS Appointment Engine`).

---

## 15. RELATION TO OPERATING HOURS (RELACIÓN CON HORARIOS DE SEDE)
- `establishments.operating_hours` representa el horario comercial macro de la sede (`DEC-SE-002.4` 🔒).
- La relación conceptual es:
  $$	ext{staff_schedule.time_blocks} \subseteq 	ext{establishment.operating_hours}$$
- **Política Runtime v1.0 (`N03A-DEC-05` 🔒):** **WARNING ONLY.** La contención actúa como guía informativa de negocio. Si un colaborador registra franjas fuera del horario comercial, el sistema registra la advertencia `out_of_operating_hours_warning: true` sin bloquear la persistencia.

---

## 16. RELATION TO B2C (RELACIÓN CON DOMINIO B2C)
- `NODO-03A` no tiene dependencias ni mutaciones sobre el esquema B2C (`Pre-Nodo 01`).
- `perfiles_prestador.weekly_schedule` permanece desacoplado e inmutable (`DEC-SE-002.5` 🔒).

---

## 17. SLOT GENERATION BOUNDARY (FRONTERA DE GENERACIÓN DE SLOTS)
- Conforme a **`N03A-DEC-08` 🔒**, `NODO-03A` **MANTIENE DISPONIBILIDAD DECLARATIVA ÚNICAMENTE**.
- La generación dinámica de slots de citas (intersección de horarios, duración de servicio y ocupación de agenda) es responsabilidad exclusiva de un futuro motor downstream de agendamiento (`SaaS Appointment Engine`).

---

## 18. SECURITY & MULTI-TENANCY (SEGURIDAD Y RLS)
- Toda operación ejecuta `SELECT set_config('app.tenant_id', $1, true)` dentro de la transacción.
- Persistencia protegida mediante Row-Level Security (RLS) mandatorio:
  ```sql
  tenant_isolation_staff_schedules: tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid
  ```
- Integridad foránea compuesta: vinculación estricta con `memberships(id, establishment_id, tenant_id)`.

---

## 19. DATA MODEL IMPACT (IMPACTO EN MODELO DE DATOS)
- **Entidad Conceptual:** `STAFF_SCHEDULE` / `staff_schedules`.
- **Identificador y Clave Única:** `(tenant_id, establishment_id, membership_id)`.
- **Entidades Consumidas (Intactas):** `tenants`, `establishments`, `memberships`.
- *Restricción de Gobernanza:* Cero definición prematura de tipos DDL, nombres físicos definitivos o migraciones en este contrato.

---

## 20. STATE MODEL / LIFECYCLE (MODELO DE ESTADOS DECLARATIVO)

Conforme a **`N03A-DEC-07` 🔒** (Semántica de Presencia/Ausencia):
```text
  [NOT_CONFIGURED] (Colaborador sin horario explícito registrado en la sede)
         │
         ▼ (SET_STAFF_SCHEDULE)
    [CONFIGURED] (Disponibilidad semanal activa y consultable)
         │
         ├─── (SET_STAFF_SCHEDULE / Update) ───► [CONFIGURED] (Actualizado)
         │
         └─── (DELETE_STAFF_SCHEDULE) ─────────► [NOT_CONFIGURED]
```

*Invariante:* La vigencia operativa se deriva dinámicamente:
$$	ext{SCHEDULE es OPERATIVAMENTE VÁLIDO} \iff 	ext{MEMBERSHIP.status} = 	ext{'ACTIVE'}$$

---

## 21. DEPENDENCIES (DEPENDENCIAS DEL NODO)
- `065_saas_foundation_core.sql` (`establishments`, `memberships`, RLS 🔒).
- `066_context_resolution_tenant_resolver.sql` (`authMiddleware`, `activeContextMiddleware` 🔒).
- `DEC-SE-002` (Autonomía desacoplada de ubicación y horarios 🔒).
- `DEC-AS-014` (Assignment asociativo puro 🔒).

---

## 22. STOP CONDITIONS (CONDICIONES DE PARADA)
- CERO código, cero DDL, cero modificaciones a la base de datos o frontend durante la fase de reconciliación de contrato.
- Detenerse inmediatamente tras la emisión del contrato reconciliado.

---

## 23. VALIDATION MATRIX (MATRIZ DE VALIDACIÓN PREVISTA)

| ID | Escenario de Prueba Previsto | Comportamiento Esperado |
| :--- | :--- | :--- |
| **VAL-01** | `SET_STAFF_SCHEDULE` con payload válido semanal por `OWNER` | `200 OK`, horario persistido |
| **VAL-02** | `SET_STAFF_SCHEDULE` propio por `PROFESSIONAL` (`req.membershipId === target`) | `200 OK` (Auto-gestión autorizada) |
| **VAL-03** | `SET_STAFF_SCHEDULE` de otro colaborador por `PROFESSIONAL` (`req.membershipId !== target`) | `403 Forbidden` |
| **VAL-04** | `SET_STAFF_SCHEDULE` sobre membresía de otra sede (mismatch) | `422 Unprocessable Entity` |
| **VAL-05** | `SET_STAFF_SCHEDULE` con bloques solapados (ej. 08:00-12:00 y 10:00-14:00) | `400 Bad Request` |
| **VAL-06** | `SET_STAFF_SCHEDULE` con `start_time >= end_time` (ej. 18:00-08:00) | `400 Bad Request` |
| **VAL-07** | `SET_STAFF_SCHEDULE` sobre membresía `SUSPENDED` o `TERMINATED` | `422 INACTIVE_MEMBERSHIP` |
| **VAL-08** | `SET_STAFF_SCHEDULE` con horas fuera de horario de sede | `200 OK` con `out_of_operating_hours_warning: true` |
| **VAL-09** | `GET_STAFF_SCHEDULE` para colaborador no configurado | `200 OK` con `schedule_state: "NOT_CONFIGURED"` |
| **VAL-10** | `DELETE_STAFF_SCHEDULE` por `MANAGER` | `200 OK`, horario eliminado limpiamente |
| **VAL-11** | Intento de `SET_STAFF_SCHEDULE` por `RECEPTIONIST` | `403 Forbidden` |
| **VAL-12** | Aislamiento RLS Cross-Tenant (consulta de horarios de otro tenant) | `0` filas retornadas / `404 Not Found` |

---

## 24. RECONCILIATION REGISTRY (REGISTRO FORMAL DE RECONCILIACIÓN)

Las 8 decisiones del bundle `N03A-DEC-001` quedan incorporadas con carácter vinculante:

```text
================================================================================
          N03A-DEC-001 — REGISTRO DE DECISIONES RATIFICADAS POR EL DIRECTOR
================================================================================
  1. N03A-DEC-01 (AUTHORITY):
     -> APPROVED / CLOSED BY DIRECTOR: OWNER + MANAGER + PROFESSIONAL (Auto-gestión acotada).

  2. N03A-DEC-02 (SCOPE):
     -> APPROVED / CLOSED BY DIRECTOR: Contextual a (MEMBERSHIP, ESTABLISHMENT) en TENANT.

  3. N03A-DEC-03 (WEEKLY MODEL):
     -> APPROVED / CLOSED BY DIRECTOR: 7 Días, 0..N intervalos no solapados por día.

  4. N03A-DEC-04 (OVERLAP):
     -> APPROVED / CLOSED BY DIRECTOR: Prohibición semántica estricta (FORBIDDEN).

  5. N03A-DEC-05 (RELATION TO ESTABLISHMENT HOURS):
     -> APPROVED / CLOSED BY DIRECTOR: WARNING ONLY (No bloqueante en v1.0).

  6. N03A-DEC-06 (EXCEPTIONS):
     -> APPROVED / CLOSED BY DIRECTOR: OUT OF SCOPE v1.0 (Diferidas a futuro).

  7. N03A-DEC-07 (STATE MODEL):
     -> APPROVED / CLOSED BY DIRECTOR: Semántica declarativa presencia/ausencia + derivada.

  8. N03A-DEC-08 (SLOT GENERATION):
     -> APPROVED / CLOSED BY DIRECTOR: Declaración de disponibilidad pura (Slots downstream).
================================================================================
```

---

## 25. CLOSURE CRITERIA (CRITERIOS DE CIERRE DEL NODO)
1. Aprobación formal del presente Node Contract Reconciliado por el Director del Proyecto.
2. Emisión y aprobación del Implementation Contract de NODO-03A.
3. Implementación física conforme a contratos (controladores, rutas, servicios, migraciones aprobadas).
4. Batería de pruebas automatizadas al 100% (cero regresiones en suites existentes de 86 tests).
5. Auditoría independiente final con veredicto PASS y cero bloqueadores.

---

## 26. GOVERNANCE SELF-CHECK (AUTO-VERIFICACIÓN DE GOBERNANZA)
```text
[X] Only NODO-03A contract modified
[X] No code
[X] No database
[X] No DDL
[X] No migration
[X] No frontend
[X] No B2C
[X] No Foundation modification
[X] No NODO-02 modification
[X] No NODO-01 modification
[X] No HBC modification
[X] No physical design
[X] No implementation
[X] All eight decisions correctly reflected
[X] Contract remains subject to Director approval
```

---

```text
================================================================================
NODE CONTRACT:
  RECONCILED
  READY FOR DIRECTOR APPROVAL 🔒

NO IMPLEMENTATION AUTHORIZED.
================================================================================
```
