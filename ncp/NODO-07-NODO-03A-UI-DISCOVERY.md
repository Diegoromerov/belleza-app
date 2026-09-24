# NODO-07 — DISCOVERY FÍSICO DE UI: NODO-03A
## STAFF OPERATIONAL AVAILABILITY & SCHEDULE RUNTIME

**Documento:** `NODO-07-NODO-03A-UI-DISCOVERY.md`  
**Estado:** `DISCOVERY COMPLETE — AWAITING DIRECTOR REVIEW`  
**Alcance:** Descubrimiento forense de arquitectura física para la interfaz de usuario de disponibilidad y horarios operativos de personal (NODO-03A / SCR-09).  
**Restricción:** `ZERO CODE CHANGES` — No se modifica código Dart, JS ni SQL durante esta fase.

---

## A. OBJETIVO

Determinar de manera determinista, mediante evidencia física del repositorio, la arquitectura física requerida para construir posteriormente la interfaz SaaS de **NODO-03A: STAFF OPERATIONAL AVAILABILITY & SCHEDULE RUNTIME**.

La UI permitirá:
1. Consultar la disponibilidad semanal y estado de configuración de horarios del personal activo en la sede.
2. Configurar y editar horarios semanales atómicos por bloques de tiempo (`start_time` - `end_time`).
3. Respetar la matriz de autoridad RBAC cerrada (`OWNER`/`MANAGER` gestión global, `PROFESSIONAL` autogestión, `RECEPTIONIST` lectura).
4. Operar estrictamente bajo el Active Context vigente inyectando `x-active-membership-id`.
5. Visualizar advertencias (*warnings*) no bloqueantes cuando los bloques configurados se ubiquen fuera del horario de funcionamiento del establecimiento.

---

## B. EVIDENCIA BACKEND REAL

Se inspeccionaron físicamente los archivos del backend de Node.js/Express y migraciones PostgreSQL:
- **DDL:** [`backend/migrations/069_staff_schedules.sql`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/migrations/069_staff_schedules.sql)
- **Router:** [`backend/src/routes/staffAvailabilityRoutes.js`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/routes/staffAvailabilityRoutes.js)
- **Controller:** [`backend/src/controllers/staffAvailabilityController.js`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/controllers/staffAvailabilityController.js)
- **Service:** [`backend/src/services/staffAvailabilityService.js`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/services/staffAvailabilityService.js)
- **Tests:** [`backend/tests/test_staff_availability_suite.js`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/tests/test_staff_availability_suite.js)

### Modelo de Datos Físico (`staff_schedules`):
- `id` UUID PRIMARY KEY
- `tenant_id` INTEGER NOT NULL
- `establishment_id` UUID NOT NULL
- `membership_id` UUID NOT NULL
- `day_of_week` INTEGER (1=Lunes .. 7=Domingo) NOT NULL
- `start_time` TIME NOT NULL
- `end_time` TIME NOT NULL
- `created_at` TIMESTAMPTZ, `updated_at` TIMESTAMPTZ
- Restricciones: `start_time < end_time`, foreign keys vinculadas a `memberships(id, establishment_id, tenant_id)`.

---

## C. ENDPOINTS REALES VERIFICADOS

En [`staffAvailabilityRoutes.js`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/routes/staffAvailabilityRoutes.js#L17-L28) existen físicamente 4 operaciones canónicas protegidas por `authMiddleware` y `activeContextMiddleware`:

| Operación | Método | Ruta Canónica Backend | Handler Controller | Propósito / Semántica |
| :--- | :--- | :--- | :--- | :--- |
| **OP-03** | `GET` | `/api/v1/saas/hub/staff/schedules` | `listEstablishmentStaffSchedules` | Lista horarios y estado (`CONFIGURED`/`NOT_CONFIGURED`) de todo el personal activo en la sede. |
| **OP-02** | `GET` | `/api/v1/saas/hub/staff/:membership_id/schedule` | `getStaffSchedule` | Consulta el horario semanal completo y bloques del colaborador especificado. |
| **OP-01** | `PUT` | `/api/v1/saas/hub/staff/:membership_id/schedule` | `setStaffSchedule` | **Reemplazo atómico semanal:** Guarda o actualiza los bloques de lunes a domingo para el colaborador. |
| **OP-04** | `DELETE` | `/api/v1/saas/hub/staff/:membership_id/schedule` | `deleteStaffSchedule` | Elimina todos los bloques de horario del colaborador en la sede, revirtiendo a `NOT_CONFIGURED`. |

> [!IMPORTANT]
> **Hallazgo sobre `POST` vs `PUT`:**
> El contrato físico de NODO-03A utiliza exclusivamente `PUT` para guardar/configurar el horario semanal atómico de un colaborador (`setStaffSchedule`). Maneja de forma idempotente tanto la primera configuración como las ediciones posteriores. No existe un endpoint `POST` separado.

---

## D. EVIDENCIA FRONTEND

Se inspeccionó la infraestructura Flutter en `frontend/lib/`:
- **Contexto Activo:** [`ActiveContextHolder`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/frontend/lib/services/active_context_holder.dart) mantiene en RAM el `activeMembershipId`.
- **Cliente HTTP:** [`ApiService`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/frontend/lib/services/api_service.dart) inyecta de forma transparente el header `x-active-membership-id` en todas las rutas bajo `/api/v1/saas/*`.
- **Hub Salón:** [`HubSalonScreen`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/frontend/lib/screens/saas/hub_salon_screen.dart#L22) ya declara explícitamente el hook de navegación `onNavigateToStaffSchedules`.
- **Directorio de Personal:** [`HubStaffMember`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/frontend/lib/models/saas/hub_salon_model.dart#L234-L289) proporciona la estructura de datos base para identificar a los miembros de la sede.

---

## E. COMPONENTES REUTILIZABLES

Para la UI de NODO-03A se pueden reutilizar sin duplicación:
1. `ActiveContextHolder` (Gestión de contexto en memoria).
2. `ApiService` (Métodos `get`, `put`, `delete` con autenticación y contexto).
3. `HubStaffMember` (Estructura de miembros de equipo).
4. Diálogos y selectores estándar de Flutter Material 3 (`TimeOfDay`, `showTimePicker`, tarjetas de días de la semana).

---

## F. ACTIVE CONTEXT INTEGRATION

- **Reutilización:** N03A UI consumirá exclusivamente `ActiveContextHolder` y `ApiService`.
- **Transporte:** Toda llamada a `/api/v1/saas/hub/staff/*` transmitirá automáticamente `x-active-membership-id`.
- **Invariante:** Cero persistencia local de estado de sesión y cero manipulación de identificadores sintéticos.

---

## G. MEMBERSHIP RESOLUTION (RESOLUCIÓN DE COLABORADORES)

Para consultar o editar horarios, la UI requiere asociar los datos a un `membership_id`:
1. **Listado Global (OP-03):** `GET /api/v1/saas/hub/staff/schedules` entrega directamente la tupla `{ membership_id, user_name, role, schedule_state, weekly_schedule }` para todos los miembros activos.
2. **Descubrimiento Complementario:** `GET /api/v1/saas/hub/staff` entrega el directorio detallado del personal (`user_email`, `relation_type`, `joined_at`).
3. **Identificación de Autogestión:** El usuario autenticado conoce su propio `membership_id` a través de `ActiveContextHolder().activeMembershipId`.

---

## H. ESTABLISHMENT OPERATING HOURS (HORARIOS DEL ESTABLECIMIENTO)

### Evidencia:
- En backend, [`staffAvailabilityService.js:142-182`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/services/staffAvailabilityService.js#L142-L182) compara los intervalos del staff contra `establishments.operating_hours`.
- Si un bloque queda fuera del rango o en día inactivo, el backend incluye `out_of_operating_hours_warning: true` en el payload de respuesta de `getStaffSchedule` y `setStaffSchedule`.
- En frontend, `GET /api/v1/saas/hub/summary` ya retorna `operating_hours` dentro de `HubEstablishment.operatingHours` ([`hub_salon_model.dart:16`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/frontend/lib/models/saas/hub_salon_model.dart#L16)).

### Comportamiento UI:
- El frontend puede mostrar un banner informativo / badge de advertencia visual: *"Atención: El horario configurado excede el horario comercial del establecimiento"*.
- **Invariante:** Este warning es puramente informativo (no bloquea el guardado en backend ni en frontend).

---

## I. RBAC UX (MATRIZ DE EXPERIENCIA POR ROL)

| Rol del Actor | Capacidad en UI | Comportamiento Visual |
| :--- | :--- | :--- |
| **OWNER / MANAGER** | Gestión total de cualquier colaborador | Visualiza listado de todo el personal; puede abrir y editar/eliminar el horario de cualquier miembro. |
| **PROFESSIONAL** | Autogestión exclusiva | Accede a su propio horario (`actorMembershipId == targetMembershipId`); botones de edición habilitados solo para su ficha. Para otros miembros, modo solo lectura o restringido. |
| **RECEPTIONIST** | Solo lectura | Puede consultar horarios de la sede pero los botones de guardar, editar y eliminar están completamente ocultos/deshabilitados. |

---

## J. OPERACIONES A SOPORTAR EN LA UI

1. **Visualización Semanal (Lunes a Domingo):**
   - Selector / acordeón por día (`monday` .. `sunday`).
   - Switch de día laborable (`is_working: true/false`).
   - Lista de bloques de tiempo (`start_time` - `end_time`) para cada día laborable.
2. **Edición / Configuración de Bloques:**
   - Botón `+ Agregar Bloque` por día.
   - Selector de hora (`showTimePicker` de Flutter) para hora de inicio y fin.
   - Validación local en formulario: `start_time < end_time` y no solapamiento intradía.
3. **Guardado Atómico (PUT):**
   - Envío de todo el objeto `weekly_schedule` con todos los días de la semana.
4. **Eliminación / Reseteo de Horario (DELETE):**
   - Diálogo de confirmación explícito para limpiar todos los horarios del colaborador en la sede.

---

## K. OPCIONES DE ARQUITECTURA DE UI

* **OPCIÓN A (Recomendada — Pantalla Dedicada Modular `StaffScheduleScreen` / SCR-09):**
  - Pantalla completa con selector de colaboradores (para `OWNER`/`MANAGER`) o vista directa (para `PROFESSIONAL`), con cuadrícula o lista interactiva de los 7 días de la semana.
  - Sigue exactamente el patrón probado en `CrearDesdeCeroScreen` (SCR-06) y `ServiceOfferAssignmentScreen` (SCR-08).
  - Máxima claridad para edición de turnos y visualización de advertencias.

* **OPCIÓN B (Pestaña embebida en Hub Salón):**
  - Sobrecargaría el Cockpit Operativo del Hub Salón, violando el principio de aislamiento y cierre inmutable de Fase 4.

* **OPCIÓN C (Modal emergente desde el Directorio de Staff):**
  - Incómodo en pantallas móviles para configurar múltiples bloques de los 7 días de la semana.

---

## L. RECOMENDACIÓN TÉCNICA

Se recomienda formalmente la **OPCIÓN A**:
Crear una pantalla dedicada `StaffScheduleScreen` (SCR-09) que permita:
1. Modo Administrador (`OWNER`/`MANAGER`): Ver matriz de staff con estado (`CONFIGURED`/`NOT_CONFIGURED`) y seleccionar colaborador para editar.
2. Modo Profesional (`PROFESSIONAL`): Editar directamente su propio horario semanal.
3. Modo Recepción (`RECEPTIONIST`): Consultar horarios sin controles de edición.

---

## M. NAVEGACIÓN PROPUESTA

- **Ruta Canónica Propuesta:** `/saas/staff-schedules` (o `/saas/schedules`).
- **Regla Inmutable:** `NO ROUTE WITHOUT CONSUMER`. No se registrará en `main.dart` hasta que sea autorizada la fase de integración de navegación correspondiente.
- **Punto de Enlace:** Hook `onNavigateToStaffSchedules` ya previsto en `HubSalonScreen`.

---

## N. LÍMITES Y FRONTERAS DE NODO-03A

- **NODO-03A administra exclusivamente:** Intervalos base recurrentes semanales de personal (`staff_schedules`).
- **Prohibido en NODO-03A:**
  - Cálculo de slots o disponibilidad dinámica (NODO-05).
  - Agendamiento de citas, reservas o estados de turnos (NODO-06).
  - Gestión de excepciones por fechas específicas, festivos o vacaciones.
  - Gestión de precios o servicios asignados (NODO-02).

---

## O. DEPENDENCIAS IDENTIFICADAS

1. **Dependencia de Contexto:** Requiere `ActiveContextHolder` con sesión activa.
2. **Dependencia de Personal:** Consume `GET /api/v1/saas/hub/staff/schedules` y `GET /api/v1/saas/hub/staff`.
3. **Dependencia de Horario Comercial:** Consume `operating_hours` desde `GET /api/v1/saas/hub/summary` para evaluar advertencias visuales.

---

## P. RIESGOS Y AMBIGÜEDADES EVALUADAS

| Aspecto | Evaluación Forense | Mitigación |
| :--- | :--- | :--- |
| **POST vs PUT** | El router no tiene `POST`, solo `PUT`. | El servicio Flutter usará `PUT` para guardar horarios tanto nuevos como editados (reemplazo atómico). |
| **Solapamiento de intervalos** | Backend rechaza con 400 `OVERLAPPING_INTERVALS`. | Validación frontend antes de enviar el payload para prevenir errores de usuario. |
| **Formato de Horas** | Backend exige `HH:MM` estricto (24 horas). | Formateo consistente de `TimeOfDay` a `HH:mm` (ej. `09:00`, `18:30`). |

---

## Q. DECISIONES QUE REQUIEREN REVISIÓN DEL DIRECTOR

1. **Ratificación de Opción de UI:** Confirmar la aprobación de la **Opción A** (Pantalla dedicada `StaffScheduleScreen` / SCR-09).
2. **Ruta Canónica:** Confirmar `/saas/staff-schedules` como la ruta futura a registrar.
3. **Autorización para Fase Siguiente:** Proceder a la redacción de la **Arquitectura Física Formal de NODO-03A UI**.

---

```
============================================================
DISCOVERY COMPLETE
AWAITING DIRECTOR REVIEW
============================================================
```
