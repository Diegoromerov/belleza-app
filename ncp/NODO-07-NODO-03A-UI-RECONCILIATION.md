# NODO-07 — RECONCILIACIÓN CONTRACTUAL: NODO-03A UI
## STAFF OPERATIONAL AVAILABILITY & SCHEDULE RUNTIME

**Documento:** `NODO-07-NODO-03A-UI-RECONCILIATION.md`  
**Estado:** `RECONCILIATION COMPLETE — AWAITING DIRECTOR DECISION`  
**Autoridad:** Auditoría Forense de Código y Contratos NODO-03A  
**Restricción:** `ZERO CODE CHANGES` — No se modifica código Dart, JS ni SQL durante esta fase.

---

## A. DTO REAL DE `GET /api/v1/saas/hub/staff/schedules`

La inspección física en [`staffAvailabilityService.js:424-505`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/services/staffAvailabilityService.js#L424-L505) y [`test_staff_availability_suite.js:553-571`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/tests/test_staff_availability_suite.js#L553-L571) determina que la respuesta de `GET /api/v1/saas/hub/staff/schedules` es:

```json
{
  "status": "success",
  "data": [
    {
      "membership_id": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
      "user_name": "Ana Profesional",
      "role": "PROFESSIONAL",
      "schedule_state": "CONFIGURED",
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
          "time_blocks": [
            { "start_time": "08:00", "end_time": "17:00" }
          ]
        },
        "wednesday": { "is_working": false, "time_blocks": [] },
        "thursday": { "is_working": true, "time_blocks": [...] },
        "friday": { "is_working": true, "time_blocks": [...] },
        "saturday": { "is_working": true, "time_blocks": [...] },
        "sunday": { "is_working": false, "time_blocks": [] }
      }
    }
  ]
}
```

### Respuestas a las Preguntas Específicas del Director:
- **A. ¿Suficiente información para matriz administrativa OWNER/MANAGER?**  
  **SÍ.** Entrega la lista de todo el personal activo en la sede con su identificador (`membership_id`), nombre (`user_name`), rol (`role`), estado de configuración (`schedule_state`: `CONFIGURED` / `NOT_CONFIGURED`) y el desglose de bloques por día de la semana.
- **B. ¿Identifica membership + identidad + role?**  
  **SÍ.** Incluye `membership_id`, `user_name` y `role` en cada registro.
- **C. ¿Devuelve exclusivamente miembros ACTIVE?**  
  **SÍ.** La consulta SQL filtra estrictamente: `WHERE m.establishment_id = $1 AND m.tenant_id = $2 AND m.status = 'ACTIVE'`.
- **D. ¿`weekly_schedule` representa el contrato exacto de N03A?**  
  **SÍ.** Estructura canónica con los 7 días (`monday`..`sunday`), cada uno con `is_working: bool` y `time_blocks: [{ start_time, end_time }]` formateados a `HH:MM`.
- **E. ¿Se requieren llamadas individuales adicionales a `GET /staff/:membership_id/schedule` para construir la pantalla?**  
  **NO para la lista inicial.** La llamada a `/staff/schedules` ya incluye los bloques de todos los miembros. La llamada individual a `GET /staff/:membership_id/schedule` se utiliza exclusivamente al abrir el editor individual o refrescar un miembro específico, pues entrega además el flag `out_of_operating_hours_warning`.

---

## B. COMPARACIÓN: `/staff` vs `/staff/schedules`

| Dimensión | `GET /api/v1/saas/hub/staff` | `GET /api/v1/saas/hub/staff/schedules` |
| :--- | :--- | :--- |
| **Controlador / Servicio** | `hubSalonController.getStaff` | `staffAvailabilityController.listEstablishmentStaffSchedules` |
| **Propósito de Dominio** | Directorio administrativo del personal de la sede (NODO-07 Hub). | Matriz operativa de horarios de disponibilidad semanal (NODO-03A). |
| **Datos Exclusivos** | `user_id`, `user_email`, `relation_type`, `status`, `joined_at`, `staff_count`. | `schedule_state` (`CONFIGURED`/`NOT_CONFIGURED`), `weekly_schedule` (bloques 7 días). |
| **Datos Compartidos** | `membership_id`, `user_name`, `role`. | `membership_id`, `user_name`, `role`. |
| **Rol en SCR-09 UI** | Datos complementarios (si se requiere email o fecha de ingreso). | **Fuente primaria obligatoria** para la pantalla de horarios. |

---

## C. RESOLUCIÓN DE MEMBERSHIP & PROFESIONAL SELF-MANAGEMENT

En [`staffAvailabilityService.js:239-253`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/services/staffAvailabilityService.js#L239-L253) y [`test_staff_availability_suite.js`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/tests/test_staff_availability_suite.js):

1. **Resolución de Actores:**
   - `actorMembershipId` se obtiene de `activeContext.active_membership_id` (inyectado desde el header `x-active-membership-id`).
   - `targetMembershipId` se obtiene de `req.params.membership_id` en la URL.

2. **Matriz RBAC Real en Backend:**
   - **`PUT /staff/:membership_id/schedule` (Guardar/Reemplazar Horario):**
     - `OWNER` / `MANAGER`: Puede configurar el horario de cualquier colaborador activo del establecimiento.
     - `PROFESSIONAL`: **Autogestión exclusiva.** Solo puede configurar si `actorMembershipId === targetMembershipId`. Si intenta modificar a otro miembro, el backend lanza `403` con código `FORBIDDEN_SELF_MANAGEMENT_ONLY` (`"Un colaborador con rol PROFESSIONAL solo puede gestionar su propia disponibilidad operativa."`).
     - `RECEPTIONIST`: Lanza `403` con código `FORBIDDEN_ROLE` (`"El rol RECEPTIONIST no tiene autorización para gestionar horarios de disponibilidad."`).
   - **`DELETE /staff/:membership_id/schedule` (Eliminar/Resetear Horario):**
     - `OWNER` / `MANAGER`: Puede eliminar el horario de cualquier colaborador.
     - `PROFESSIONAL` y `RECEPTIONIST`: Lanzan `403` con código `FORBIDDEN_ROLE` (`"Solo los roles OWNER o MANAGER pueden eliminar la disponibilidad de un colaborador."`).

---

## D. OPERATING HOURS WARNING (ADVERTENCIA DE HORARIOS COMERCIALES)

En [`staffAvailabilityService.js:142-182`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/services/staffAvailabilityService.js#L142-L182):
- **Cálculo:** La función `evaluateOperatingHoursWarning` compara los intervalos del horario del staff con `establishments.operating_hours`.
- **Condiciones que activan el warning (`true`):**
  - Si el colaborador tiene bloques en un día en que la sede está cerrada (`activo: false`).
  - Si la hora de inicio es anterior a la apertura (`start_min < estStartMin`).
  - Si la hora de fin es posterior al cierre (`end_min > estEndMin`).
- **Presencia en Respuestas:**
  - `GET /staff/:membership_id/schedule` -> Incluye `out_of_operating_hours_warning: boolean`.
  - `PUT /staff/:membership_id/schedule` -> Incluye `out_of_operating_hours_warning: boolean`.
  - `GET /staff/schedules` -> Retorna `false` por defecto para optimizar el listado agregado.
- **Semántica:** Es una advertencia informativa (**Warning No Bloqueante**). No impide el guardado ni altera transacciones. En la UI se presentará como un badge o banner amarillo de alerta.

---

## E. VERIFICACIÓN FÍSICA DEL HOOK DE NAVEGACIÓN EN EL HUB

Se auditó físicamente [`frontend/lib/screens/saas/hub_salon_screen.dart`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/frontend/lib/screens/saas/hub_salon_screen.dart):

1. **Declaración en Constructor:**
   - Línea 22: `final VoidCallback? onNavigateToStaffSchedules;`
   - Línea 30: `this.onNavigateToStaffSchedules,`

2. **Uso Físico en la UI:**
   - Líneas 501-507:
     ```dart
     Expanded(
       child: _buildShortcutButton(
         key: const Key('btn_modulo_personal'),
         icon: Icons.badge_outlined,
         label: 'Horarios (N03A)',
         onTap: widget.onNavigateToStaffSchedules ?? () => _showModulePlaceholder('Gestión de Horarios y Staff (NODO-03A)'),
       ),
     ),
     ```
3. **Veredicto:** El hook **EXISTE REALMENTE Y ESTÁ IMPLEMENTADO**. Si `onNavigateToStaffSchedules` es `null`, muestra el placeholder temporal; si se le provee un callback de navegación, ejecuta el salto a la pantalla correspondiente.

---

## F. IMPACTO EN LA ARQUITECTURA DE UI (SCR-09)

1. **Cliente API / Servicio:**
   - `listEstablishmentSchedules()` -> Consume `GET /api/v1/saas/hub/staff/schedules`.
   - `getStaffSchedule(membershipId)` -> Consume `GET /api/v1/saas/hub/staff/:membership_id/schedule`.
   - `setStaffSchedule(membershipId, weeklySchedule)` -> Consume `PUT /api/v1/saas/hub/staff/:membership_id/schedule`.
   - `deleteStaffSchedule(membershipId)` -> Consume `DELETE /api/v1/saas/hub/staff/:membership_id/schedule`.

2. **Flujo de Pantalla (`StaffScheduleScreen` / SCR-09):**
   - Para `OWNER` / `MANAGER`: Muestra la lista/matriz de colaboradores activos con chips de días configurados y estado (`CONFIGURADO` / `NO CONFIGURADO`). Al seleccionar un miembro, abre el editor semanal (7 días) para configurar o borrar bloques.
   - Para `PROFESSIONAL`: Abre directamente el editor semanal de su propio `activeMembershipId` (ocultando el selector de otros colaboradores y el botón de borrado total).
   - Para `RECEPTIONIST`: Muestra la matriz semanal en modo solo lectura sin botones de edición.

---

## G. RECOMENDACIÓN TÉCNICA FINAL

1. **Aprobar la Reconciliación Contractual:** Confirmar que `GET /api/v1/saas/hub/staff/schedules` es la fuente primaria autosuficiente para SCR-09, y que `PUT` es la única mutación atómica canónica.
2. **Autorizar Fase de Physical Architecture:** Proceder con la redacción del documento formal de Arquitectura Física `ncp/NODO-07-NODO-03A-UI-PHYSICAL-ARCHITECTURE.md`.

---

```
============================================================
RECONCILIATION COMPLETE
AWAITING DIRECTOR DECISION
============================================================
```
