# NODO-07 — INFORME DE IMPLEMENTACIÓN FÍSICA
## NODO-03A UI / SCR-09: STAFF OPERATIONAL AVAILABILITY & SCHEDULE RUNTIME

**Estado**: `IMPLEMENTATION COMPLETE / AWAITING DIRECTOR AUDIT`  
**Fecha de Ejecución**: 2026-09-12  
**Autoridad**: Aprobación del Director para Physical Architecture de NODO-03A UI / SCR-09  
**Alcance Autorizado**: Exclusivamente la UI SaaS de Horarios Operativos de Personal (`StaffScheduleScreen` / SCR-09) y sus pruebas asociadas.

---

### 1. Archivos Físicos Creados

| # | Archivo | Responsabilidad |
|---|---|---|
| 1 | `frontend/lib/models/saas/staff_schedule_model.dart` | Modelos de datos inmutables (`TimeBlockModel`, `DayScheduleModel`, `WeeklyScheduleModel`, `StaffScheduleItemModel`, `StaffScheduleDetailModel`), serializadores JSON y validadores temporales. |
| 2 | `frontend/lib/services/saas/staff_schedule_service.dart` | Cliente de servicio HTTP que consume los endpoints canónicos de N03A (`listStaffSchedules`, `getStaffSchedule`, `setStaffSchedule`, `deleteStaffSchedule`) mediante inyección de dependencias `ApiService`. |
| 3 | `frontend/lib/screens/saas/staff_schedule_screen.dart` | Pantalla operacional SCR-09 con selector de personal administrativo, modo "Mi Horario" para profesionales, modo "Solo Lectura" para recepcionistas, banner de advertencia (`out_of_operating_hours_warning`) y editor semanal. |
| 4 | `frontend/test/saas_staff_schedule_test.dart` | Suite de 16 pruebas automatizadas unitarias y de widgets que validan DTOs, llamadas HTTP, RBAC UX, validaciones de solapamiento y máquina de estados. |

---

### 2. Endpoints Backend Consumidos y Semántica

| Método | Endpoint Canónico | Semántica Operacional | RBAC Backend |
|---|---|---|---|
| `GET` | `/api/v1/saas/hub/staff/schedules` | Matriz de horarios de todo el personal en la sede activa | Permitido para `OWNER`, `MANAGER`, `PROFESSIONAL`, `RECEPTIONIST` |
| `GET` | `/api/v1/saas/hub/staff/:membership_id/schedule` | Detalle individual del horario y evaluación de horario operativo (`out_of_operating_hours_warning`) | Permitido para `OWNER`, `MANAGER`, `PROFESSIONAL`, `RECEPTIONIST` |
| `PUT` | `/api/v1/saas/hub/staff/:membership_id/schedule` | **Reemplazo atómico y completo** del horario semanal de 7 días | `OWNER`, `MANAGER` (global); `PROFESSIONAL` (estrictamente self); `RECEPTIONIST` (prohibido: 403) |
| `DELETE` | `/api/v1/saas/hub/staff/:membership_id/schedule` | **Reset total** del horario semanal a estado `NOT_CONFIGURED` / vacío | `OWNER`, `MANAGER` (global); `PROFESSIONAL` y `RECEPTIONIST` (prohibido: 403) |

> **Nota**: Se respetó la prohibición de crear o consumir endpoints `POST` o `PATCH`. La actualización se realiza atómicamente vía `PUT`.

---

### 3. Matriz RBAC de UX Implementada

1. **`OWNER` / `MANAGER` (Modo Administrador)**:
   - Selector de miembros del staff visible y habilitado.
   - Editor semanal de 7 días interactivo.
   - Botón `Guardar Horario` (`PUT`) habilitado.
   - Botón `Resetear` (`DELETE`) habilitado con diálogo modal de confirmación (`Key('dialog_confirm_delete_schedule')`).
2. **`PROFESSIONAL` (Modo "Mi Horario")**:
   - Selector de terceros oculto/bloqueado. Pantalla fijada en su propia membresía (`ActiveContextHolder().activeMembershipId`).
   - Editor semanal de 7 días interactivo para su horario propio.
   - Botón `Guardar Horario` (`PUT`) habilitado (respeta `actorMembershipId === targetMembershipId`).
   - Botón `Resetear` (`DELETE`) **oculto/deshabilitado** (evitando errores `403 FORBIDDEN_ROLE`).
3. **`RECEPTIONIST` (Modo "Solo Lectura")**:
   - Selector de miembros del staff habilitado para consultar cualquier disponibilidad de equipo.
   - Editor semanal en modo solo lectura (`read-only`).
   - Botones `Guardar Horario` y `Resetear` **ocultos/deshabilitados**.

---

### 4. Manejo de Advertencias y Validaciones UX

- **Advertencia de Horario Operativo (`out_of_operating_hours_warning`)**:
  - Renderiza un banner ámbar visible (`Key('warning_operating_hours_banner')`) cuando el backend reporta bloques fuera de los horarios generales del local.
  - Comportamiento no bloqueante: permite guardar válidamente.
- **Validaciones Preventivas en Cliente**:
  - Valida formato `HH:mm` en cada bloque horario.
  - Valida `start_time < end_time` por bloque.
  - Valida que no existan intervalos solapados dentro del mismo día calendario.
  - Valida que los días activos contengan al menos un bloque configurado.

---

### 5. Resultados de Pruebas Automatizadas

#### A. Suite N03A UI (`test/saas_staff_schedule_test.dart`):
```
00:00 +1: 1. TimeBlockModel parses JSON and serializes correctly
00:00 +2: 2. WeeklyScheduleModel parses 7 canonical days and produces complete JSON
00:00 +3: 3. StaffScheduleItemModel and DetailModel parse and reflect warning state
00:00 +4: 4. listStaffSchedules parses API response correctly
00:00 +5: 5. getStaffSchedule fetches detailed schedule with warning flag
00:00 +6: 6. setStaffSchedule performs atomic PUT replacement
00:00 +7: 7. deleteStaffSchedule calls DELETE and resets schedule
00:00 +8: 14 & 15. Zero Mutation: ActiveContextHolder remains intact across service calls
00:01 +9: 8. Warning banner is rendered when outOfOperatingHoursWarning is true
00:01 +10: 9. OWNER role has staff selector, save and delete buttons
00:01 +11: 10. MANAGER role has full management capabilities
00:01 +12: 11 & 12. PROFESSIONAL role operates in "Mi Horario" mode without staff selector of others and NO DELETE button
00:01 +13: 13. RECEPTIONIST role operates in read-only mode (save and delete hidden)
00:01 +14: 16. States: Missing active context shows empty state
00:01 +15: 16b. States: Error state shows retry button and recovers on retry
00:01 +16: 17 & 18. Form Validations: start < end and overlap prevention in UI
00:02 +16: All tests passed!
```

#### B. Regresión SaaS Completa (7 suites de prueba):
```
flutter test \
 test/saas_client_infrastructure_test.dart \
 test/saas_available_context_test.dart \
 test/saas_hub_salon_test.dart \
 test/saas_navigation_test.dart \
 test/saas_crear_desde_cero_test.dart \
 test/saas_service_offer_assignment_test.dart \
 test/saas_staff_schedule_test.dart

Resultado: 83 / 83 tests pasaron exitosamente (100% verde).
```

---

### 6. Verificación Forense de Git

- **Archivos de producción modificados**: 0 (ZERO CODE CHANGES en backend, SQL, migraciones, `main.dart`, Hub ni ActiveContextHolder).
- **Archivos nuevos creados**:
  - `frontend/lib/models/saas/staff_schedule_model.dart`
  - `frontend/lib/services/saas/staff_schedule_service.dart`
  - `frontend/lib/screens/saas/staff_schedule_screen.dart`
  - `frontend/test/saas_staff_schedule_test.dart`
  - `ncp/NODO-07-NODO-03A-UI-IMPLEMENTATION-REPORT.md`

---

**ESTADO FINAL**: `IMPLEMENTATION COMPLETE / AWAITING DIRECTOR AUDIT`
