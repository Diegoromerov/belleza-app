# NODO-07 — FASE NODO-03A UI / SCR-09: STAFF OPERATIONAL AVAILABILITY & SCHEDULE RUNTIME
# ARQUITECTURA FÍSICA DETALLADA

**Estado**: CLOSED & RECONCILED — READY FOR DIRECTOR APPROVAL  
**Fecha de Elaboración**: 2026-09-12  
**Autoridad Arquitectónica**: NODO-03A Backend (Closed / Immutable) | NODO-07 Fase 1-6A (Closed / Immutable) | NODO-02 UI (Closed / Immutable)  
**Alcance**: Frontend SaaS (Flutter/Dart) — Módulo de Horarios Operativos de Personal (`StaffScheduleScreen` / SCR-09).  
**Regla de Oro**: ZERO CODE CHANGES durante la fase de Arquitectura Física. No modificar backend, SQL, migraciones ni pantallas cerradas.

---

## ÍNDICE DE SECCIONES
1. [A. Archivos Físicos Autorizados y Estructura de Directorios](#a-archivos-físicos-autorizados-y-estructura-de-directorios)
2. [B. Endpoints Backend, Métodos HTTP y Desglose de Autoridad (READ / WRITE / DELETE)](#b-endpoints-backend-métodos-http-y-desglose-de-autoridad-read--write--delete)
3. [C. DTOs de Request y Response Canónicos](#c-dtos-de-request-y-response-canónicos)
4. [D. Modelo de Estado del Cliente (Dart Data Classes)](#d-modelo-de-estado-del-cliente-dart-data-classes)
5. [E. Estructura y Maquetación de Pantalla (Screen Layout & UX Structure)](#e-estructura-y-maquetación-de-pantalla-screen-layout--ux-structure)
6. [F. Manejo de Días de la Semana y Ordenamiento Canónico](#f-manejo-de-días-de-la-semana-y-ordenamiento-canónico)
7. [G. Formato y Reglas de Bloques Horarios (Time Blocks)](#g-formato-y-reglas-de-bloques-horarios-time-blocks)
8. [H. Manejo del Warning de Horario Operativo (Out-of-Operating-Hours Warning)](#h-manejo-del-warning-de-horario-operativo-out-of-operating-hours-warning)
9. [I. Validaciones de Formulario y UX de Errores](#i-validaciones-de-formulario-y-ux-de-errores)
10. [J. Matriz de Autoridad Backend vs Matriz RBAC de UX](#j-matriz-de-autoridad-backend-vs-matriz-rbac-de-ux)
11. [K. Máquina de Estados de la Pantalla (State Transitions)](#k-máquina-de-estados-de-la-pantalla-state-transitions)
12. [L. Integración con Active Context y Multitenancy](#l-integración-con-active-context-y-multitenancy)
13. [M. Inyección de Dependencias y Testabilidad](#m-inyección-de-dependencias-y-testabilidad)
14. [N. Estrategia de Pruebas Unitarias y Widgets (Mock Contracts)](#n-estrategia-de-pruebas-unitarias-y-widgets-mock-contracts)
15. [O. Seguridad de Regresión y Preservación de Nodos Previos](#o-seguridad-de-regresión-y-preservación-de-nodos-previos)
16. [P. Checklist de Restricciones Arquitectónicas](#p-checklist-de-restricciones-arquitectónicas)
17. [Q. Alcance Prohibido y Non-Goals Explícitos](#q-alcance-prohibido-y-non-goals-explícitos)
18. [R. Criterios de Aceptación Funcionales y Técnicos](#r-criterios-de-aceptación-funcionales-y-técnicos)
19. [S. Punto de Integración en Hub Salón (SCR-02)](#s-punto-de-integración-en-hub-salón-scr-02)
20. [T. Detalles de Navegación y Rutas](#t-detalles-de-navegación-y-rutas)
21. [U. Presupuesto de Tamaño de Archivo y Modularidad](#u-presupuesto-de-tamaño-de-archivo-y-modularidad)
22. [V. Orden de Implementación y Declaración de Preparación](#v-orden-de-implementación-y-declaración-de-preparación)

---

## A. Archivos Físicos Autorizados y Estructura de Directorios

La implementación física de NODO-03A UI creará estrictamente cuatro (4) archivos de código y un (1) reporte final de implementación:

```
frontend/
├── lib/
│   ├── models/
│   │   └── saas/
│   │       └── staff_schedule_model.dart              [NEW] Modelo de datos canónico N03A
│   ├── services/
│   │   └── saas/
│   │       └── staff_schedule_service.dart            [NEW] Servicio HTTP/API N03A
│   └── screens/
│       └── saas/
│           └── staff_schedule_screen.dart             [NEW] Pantalla interactiva SCR-09
└── test/
    └── saas_staff_schedule_test.dart                  [NEW] Suite de pruebas automatizadas N03A

ncp/
└── NODO-07-NODO-03A-UI-IMPLEMENTATION-REPORT.md       [NEW] Reporte formal de implementación
```

### Prohibición Estricta:
- **NO** modificar `frontend/lib/services/api_service.dart`.
- **NO** modificar `frontend/lib/services/active_context_holder.dart`.
- **NO** modificar `frontend/lib/screens/saas/hub_salon_screen.dart` (ya posee el callback listo).
- **NO** modificar ningún archivo de backend (`backend/src/**`), base de datos ni migraciones.
- **NO** registrar `/saas/staff-schedules` en `frontend/lib/main.dart` hasta autorización explícita del Director.

---

## B. Endpoints Backend, Métodos HTTP y Desglose de Autoridad (READ / WRITE / DELETE)

La UI consumirá exclusivamente los endpoints del router `staffAvailabilityRoutes.js` montado bajo el prefijo `/api/v1/saas/hub`.

### 1. Desglose Estricto de Niveles de Autoridad Backend

A continuación se detalla la autoridad real que impone el código backend inmutable (`staffAvailabilityService.js`):

| Dimensión | Endpoint | Autoridad Backend Real | Restricción por Rol |
|---|---|---|---|
| **A. READ (Listado)** | `GET /api/v1/saas/hub/staff/schedules` | **Lectura Global del Establecimiento** | Permitido para `OWNER`, `MANAGER`, `PROFESSIONAL` y `RECEPTIONIST`. Devuelve todos los miembros activos del establecimiento y sus horarios. |
| **A. READ (Individual)** | `GET /api/v1/saas/hub/staff/:membership_id/schedule` | **Lectura de Membresía del Establecimiento** | Permitido para `OWNER`, `MANAGER`, `PROFESSIONAL` y `RECEPTIONIST`. Valida pertenencia al establecimiento activo; no impone restricción `self` a nivel de lectura. |
| **B. WRITE (Reemplazo)** | `PUT /api/v1/saas/hub/staff/:membership_id/schedule` | **Escritura / Reemplazo Semanal** | • `OWNER` / `MANAGER`: Autorizado para cualquier colaborador del establecimiento.<br>• `PROFESSIONAL`: **Autogestión exclusiva (`actorMembershipId === targetMembershipId`)**. Si intenta modificar a otro: `403 FORBIDDEN_SELF_MANAGEMENT_ONLY`.<br>• `RECEPTIONIST`: Prohibido (`403 FORBIDDEN_ROLE`). |
| **C. DELETE (Reset)** | `DELETE /api/v1/saas/hub/staff/:membership_id/schedule` | **Eliminación / Reset a Vacío** | • `OWNER` / `MANAGER`: Autorizado.<br>• `PROFESSIONAL`: **Prohibido (`403 FORBIDDEN_ROLE`)**.<br>• `RECEPTIONIST`: **Prohibido (`403 FORBIDDEN_ROLE`)**. |

> **Nota Crítica de Inmutabilidad**: NO existe endpoint `POST`. La creación y actualización se realiza atómicamente vía `PUT`.

---

## C. DTOs de Request y Response Canónicos

### 1. `GET /api/v1/saas/hub/staff/schedules`
- **Headers**: `Authorization: Bearer <token>`, `x-establishment-id: <uuid>` (opcional si ya está en contexto de sesión).
- **Response Success (200 OK)**:
```json
{
  "establishment_id": "936d5c5f-3d07-4e6f-870f-1558bf2a0ad6",
  "staff_count": 2,
  "schedules": [
    {
      "membership_id": "4b684dc3-fc92-4f38-89c0-6ef6c172ee29",
      "user_id": "d1354da1-7f93-4927-a065-27a3d3c85a49",
      "user_name": "Ana Profesional",
      "user_email": "ana@example.com",
      "role": "PROFESSIONAL",
      "status": "ACTIVE",
      "schedule_state": "CONFIGURED",
      "weekly_schedule": {
        "monday": {
          "is_working": true,
          "time_blocks": [
            { "start_time": "09:00", "end_time": "13:00" },
            { "start_time": "14:00", "end_time": "18:00" }
          ]
        },
        "tuesday": {
          "is_working": true,
          "time_blocks": [
            { "start_time": "09:00", "end_time": "18:00" }
          ]
        },
        "wednesday": { "is_working": false, "time_blocks": [] },
        "thursday": { "is_working": false, "time_blocks": [] },
        "friday": { "is_working": false, "time_blocks": [] },
        "saturday": { "is_working": false, "time_blocks": [] },
        "sunday": { "is_working": false, "time_blocks": [] }
      }
    }
  ]
}
```

### 2. `GET /api/v1/saas/hub/staff/:membership_id/schedule`
- **Response Success (200 OK)**:
```json
{
  "membership_id": "4b684dc3-fc92-4f38-89c0-6ef6c172ee29",
  "establishment_id": "936d5c5f-3d07-4e6f-870f-1558bf2a0ad6",
  "tenant_id": "3c0f4f03-62c6-43b2-9dbe-206e8fb29b71",
  "schedule_state": "CONFIGURED",
  "out_of_operating_hours_warning": false,
  "weekly_schedule": {
    "monday": {
      "is_working": true,
      "time_blocks": [
        { "start_time": "09:00", "end_time": "18:00" }
      ]
    },
    "tuesday": { "is_working": false, "time_blocks": [] },
    "wednesday": { "is_working": false, "time_blocks": [] },
    "thursday": { "is_working": false, "time_blocks": [] },
    "friday": { "is_working": false, "time_blocks": [] },
    "saturday": { "is_working": false, "time_blocks": [] },
    "sunday": { "is_working": false, "time_blocks": [] }
  }
}
```

### 3. `PUT /api/v1/saas/hub/staff/:membership_id/schedule`
- **Request Body (JSON)**:
```json
{
  "weekly_schedule": {
    "monday": {
      "is_working": true,
      "time_blocks": [
        { "start_time": "09:00", "end_time": "13:00" },
        { "start_time": "14:00", "end_time": "18:00" }
      ]
    },
    "tuesday": {
      "is_working": true,
      "time_blocks": [
        { "start_time": "10:00", "end_time": "19:00" }
      ]
    },
    "wednesday": { "is_working": false, "time_blocks": [] },
    "thursday": { "is_working": false, "time_blocks": [] },
    "friday": { "is_working": false, "time_blocks": [] },
    "saturday": { "is_working": false, "time_blocks": [] },
    "sunday": { "is_working": false, "time_blocks": [] }
  }
}
```
- **Response Success (200 OK)**:
```json
{
  "success": true,
  "message": "Staff schedule updated successfully",
  "schedule_state": "CONFIGURED",
  "out_of_operating_hours_warning": true,
  "weekly_schedule": { ... }
}
```

### 4. `DELETE /api/v1/saas/hub/staff/:membership_id/schedule`
- **Response Success (200 OK)**:
```json
{
  "success": true,
  "message": "Staff schedule deleted successfully",
  "schedule_state": "EMPTY",
  "weekly_schedule": {
    "monday": { "is_working": false, "time_blocks": [] },
    "tuesday": { "is_working": false, "time_blocks": [] },
    "wednesday": { "is_working": false, "time_blocks": [] },
    "thursday": { "is_working": false, "time_blocks": [] },
    "friday": { "is_working": false, "time_blocks": [] },
    "saturday": { "is_working": false, "time_blocks": [] },
    "sunday": { "is_working": false, "time_blocks": [] }
  }
}
```

---

## D. Modelo de Estado del Cliente (Dart Data Classes)

El archivo `frontend/lib/models/saas/staff_schedule_model.dart` implementará las siguientes clases inmutables con serialización segura y métodos helper:

```dart
class TimeBlockModel {
  final String startTime; // 'HH:mm'
  final String endTime;   // 'HH:mm'

  const TimeBlockModel({
    required this.startTime,
    required this.endTime,
  });

  factory TimeBlockModel.fromJson(Map<String, dynamic> json) => TimeBlockModel(
    startTime: json['start_time'] as String? ?? '',
    endTime: json['end_time'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'start_time': startTime,
    'end_time': endTime,
  };

  TimeBlockModel copyWith({String? startTime, String? endTime}) => TimeBlockModel(
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
  );
}

class DayScheduleModel {
  final bool isWorking;
  final List<TimeBlockModel> timeBlocks;

  const DayScheduleModel({
    required this.isWorking,
    required this.timeBlocks,
  });

  factory DayScheduleModel.fromJson(Map<String, dynamic> json) => DayScheduleModel(
    isWorking: json['is_working'] as bool? ?? false,
    timeBlocks: (json['time_blocks'] as List<dynamic>?)
        ?.map((e) => TimeBlockModel.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
  );

  Map<String, dynamic> toJson() => {
    'is_working': isWorking,
    'time_blocks': timeBlocks.map((e) => e.toJson()).toList(),
  };

  static DayScheduleModel empty() => const DayScheduleModel(
    isWorking: false,
    timeBlocks: [],
  );
}

class WeeklyScheduleModel {
  final DayScheduleModel monday;
  final DayScheduleModel tuesday;
  final DayScheduleModel wednesday;
  final DayScheduleModel thursday;
  final DayScheduleModel friday;
  final DayScheduleModel saturday;
  final DayScheduleModel sunday;

  const WeeklyScheduleModel({
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
  });

  factory WeeklyScheduleModel.fromJson(Map<String, dynamic> json) => WeeklyScheduleModel(
    monday: json['monday'] != null ? DayScheduleModel.fromJson(json['monday']) : DayScheduleModel.empty(),
    tuesday: json['tuesday'] != null ? DayScheduleModel.fromJson(json['tuesday']) : DayScheduleModel.empty(),
    wednesday: json['wednesday'] != null ? DayScheduleModel.fromJson(json['wednesday']) : DayScheduleModel.empty(),
    thursday: json['thursday'] != null ? DayScheduleModel.fromJson(json['thursday']) : DayScheduleModel.empty(),
    friday: json['friday'] != null ? DayScheduleModel.fromJson(json['friday']) : DayScheduleModel.empty(),
    saturday: json['saturday'] != null ? DayScheduleModel.fromJson(json['saturday']) : DayScheduleModel.empty(),
    sunday: json['sunday'] != null ? DayScheduleModel.fromJson(json['sunday']) : DayScheduleModel.empty(),
  );

  Map<String, dynamic> toJson() => {
    'monday': monday.toJson(),
    'tuesday': tuesday.toJson(),
    'wednesday': wednesday.toJson(),
    'thursday': thursday.toJson(),
    'friday': friday.toJson(),
    'saturday': saturday.toJson(),
    'sunday': sunday.toJson(),
  };

  static WeeklyScheduleModel empty() => WeeklyScheduleModel(
    monday: DayScheduleModel.empty(),
    tuesday: DayScheduleModel.empty(),
    wednesday: DayScheduleModel.empty(),
    thursday: DayScheduleModel.empty(),
    friday: DayScheduleModel.empty(),
    saturday: DayScheduleModel.empty(),
    sunday: DayScheduleModel.empty(),
  );

  DayScheduleModel getDay(String dayKey) {
    switch (dayKey.toLowerCase()) {
      case 'monday': return monday;
      case 'tuesday': return tuesday;
      case 'wednesday': return wednesday;
      case 'thursday': return thursday;
      case 'friday': return friday;
      case 'saturday': return saturday;
      case 'sunday': return sunday;
      default: return DayScheduleModel.empty();
    }
  }
}

class StaffScheduleItemModel {
  final String membershipId;
  final String userId;
  final String userName;
  final String userEmail;
  final String role;
  final String status;
  final String scheduleState; // 'CONFIGURED' | 'EMPTY'
  final WeeklyScheduleModel weeklySchedule;

  const StaffScheduleItemModel({
    required this.membershipId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.role,
    required this.status,
    required this.scheduleState,
    required this.weeklySchedule,
  });

  factory StaffScheduleItemModel.fromJson(Map<String, dynamic> json) => StaffScheduleItemModel(
    membershipId: json['membership_id'] as String? ?? '',
    userId: json['user_id'] as String? ?? '',
    userName: json['user_name'] as String? ?? '',
    userEmail: json['user_email'] as String? ?? '',
    role: json['role'] as String? ?? '',
    status: json['status'] as String? ?? '',
    scheduleState: json['schedule_state'] as String? ?? 'EMPTY',
    weeklySchedule: json['weekly_schedule'] != null
        ? WeeklyScheduleModel.fromJson(json['weekly_schedule'] as Map<String, dynamic>)
        : WeeklyScheduleModel.empty(),
  );
}

class StaffScheduleDetailModel {
  final String membershipId;
  final String establishmentId;
  final String tenantId;
  final String scheduleState;
  final bool outOfOperatingHoursWarning;
  final WeeklyScheduleModel weeklySchedule;

  const StaffScheduleDetailModel({
    required this.membershipId,
    required this.establishmentId,
    required this.tenantId,
    required this.scheduleState,
    required this.outOfOperatingHoursWarning,
    required this.weeklySchedule,
  });

  factory StaffScheduleDetailModel.fromJson(Map<String, dynamic> json) => StaffScheduleDetailModel(
    membershipId: json['membership_id'] as String? ?? '',
    establishmentId: json['establishment_id'] as String? ?? '',
    tenantId: json['tenant_id'] as String? ?? '',
    scheduleState: json['schedule_state'] as String? ?? 'EMPTY',
    outOfOperatingHoursWarning: json['out_of_operating_hours_warning'] as bool? ?? false,
    weeklySchedule: json['weekly_schedule'] != null
        ? WeeklyScheduleModel.fromJson(json['weekly_schedule'] as Map<String, dynamic>)
        : WeeklyScheduleModel.empty(),
  );
}
```

---

## E. Estructura y Maquetación de Pantalla (Screen Layout & UX Structure)

La pantalla `StaffScheduleScreen` se organiza en un layout responsivo y modular con dos modos operacionales según el rol del usuario:

### 1. Encabezado de Contexto (Header)
- **Key**: `Key('staff_schedule_header')`
- Título: **"Horarios Operativos del Personal (N03A)"**
- Subtítulo con badges de:
  - Establecimiento Activo (`ActiveContextHolder.establishmentName`).
  - Rol del usuario actual (`ActiveContextHolder.role`).
  - Badge de Modo: `Administrador` (OWNER/MANAGER) vs `Mi Horario` (PROFESSIONAL) vs `Solo Lectura` (RECEPTIONIST).

### 2. Modo Administrador (OWNER / MANAGER)
- **Selector de Personal**:
  - Lista de profesionales cargados desde `GET /staff/schedules`.
  - Muestra nombre, rol (`PROFESSIONAL`, `OWNER`, etc.), y estado del horario (`[CONFIGURADO]` verde vs `[SIN HORARIO]` gris).
  - Al seleccionar un colaborador, carga su horario en el editor semanal.
  - Botón de Refrescar (`Key('btn_refresh_schedules')`).
- **Acciones**:
  - Botón Guardar (`PUT`) y Botón Reset (`DELETE`) habilitados.

### 3. Modo Profesional (PROFESSIONAL — Decisión UX: "Mi Horario")
- **Diseño de Autogestión Acotada**:
  - Por diseño UX, el profesional no administra a terceros. La pantalla bloquea la selección de otros miembros del staff y se fija automáticamente en su propia membresía (`ActiveContextHolder.currentMembershipId`).
  - Muestra un badge destacado: `Mi Perfil Operativo`.
- **Acciones**:
  - Editor semanal habilitado para su horario personal.
  - Botón Guardar (`PUT`) habilitado (respeta `actorMembershipId === targetMembershipId`).
  - Botón Reset (`DELETE`) **oculto/deshabilitado** (el backend devuelve 403 para PROFESSIONAL).

### 4. Modo Recepcionista (RECEPTIONIST — Modo Solo Lectura)
- **Diseño de Consulta Operativa**:
  - Permite seleccionar cualquier colaborador para consultar su disponibilidad semanal en agenda.
- **Acciones**:
  - Editor en modo solo lectura (`read-only`).
  - Botones Guardar (`PUT`) y Reset (`DELETE`) **ocultos/deshabilitados** (el backend devuelve 403 para RECEPTIONIST).

### 5. Editor Semanal de Horarios (Weekly Schedule Editor)
- **Warning Banner** (`Key('warning_operating_hours_banner')`):
  - Visible si `out_of_operating_hours_warning == true`.
  - Icono `Icons.warning_amber_rounded`, color ámbar/amarillo, texto informativo:
    *"Aviso: Uno o más bloques horarios están fuera del horario operativo general del establecimiento. Este horario sigue siendo válido pero revise su alineación."*
- **Acordeón / Tarjetas por Día (Lunes a Domingo)**:
  - Para cada día de la semana (`monday`..`sunday`):
    - Switch de Activación del Día: `is_working` (`Key('switch_day_monday')`, etc.).
    - Si `is_working == false`: Muestra etiqueta *"No laborable / Descanso"*.
    - Si `is_working == true`: Lista de bloques horarios (`TimeBlockModel`).
      - Para cada bloque:
        - Selector de Hora Inicio (Dropdown o Input `HH:mm`) (`Key('input_start_monday_0')`).
        - Selector de Hora Fin (Dropdown o Input `HH:mm`) (`Key('input_end_monday_0')`).
        - Botón Eliminar Bloque (`Key('btn_remove_block_monday_0')`).
      - Botón Añadir Bloque (`Key('btn_add_block_monday')`): Añade un nuevo bloque por defecto (ej. `09:00 - 18:00`).

### 6. Barra de Acciones (Action Footer)
- **Botón Guardar Horario** (`Key('btn_save_schedule')`):
  - Ejecuta `PUT /staff/:membership_id/schedule`.
  - Deshabilitado/Oculto en rol `RECEPTIONIST`.
  - Muestra spinner durante el guardado (`isSaving`).
- **Botón Reset / Borrar Horario** (`Key('btn_delete_schedule')`):
  - Ejecuta `DELETE /staff/:membership_id/schedule`.
  - Confirmación modal dialog (`Key('dialog_confirm_delete_schedule')`).
  - Deshabilitado/Oculto para `PROFESSIONAL` y `RECEPTIONIST`.

---

## F. Manejo de Días de la Semana y Ordenamiento Canónico

Para asegurar estricta concordancia con la base de datos y los contratos ISO/Postgres:

### Constantes Canónicas:
```dart
const List<String> kCanonicalWeekdays = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

const Map<String, String> kWeekdayLabels = {
  'monday': 'Lunes',
  'tuesday': 'Martes',
  'wednesday': 'Miércoles',
  'thursday': 'Jueves',
  'friday': 'Viernes',
  'saturday': 'Sábado',
  'sunday': 'Domingo',
};
```

### Reglas de Renderizado:
1. El orden de renderizado en UI siempre es `monday` → `sunday`.
2. Al serializar el payload hacia `PUT`, se incluyen explícitamente los 7 días (los días no trabajados se envían como `{"is_working": false, "time_blocks": []}`).

---

## G. Formato y Reglas de Bloques Horarios (Time Blocks)

1. **Formato Estricto de Hora**: Cadena de 5 caracteres en formato de 24 horas `HH:mm` (ej. `08:30`, `14:00`, `20:00`).
2. **Validación Temporal del Bloque**:
   - `start_time < end_time` (hora de inicio estrictamente menor a hora de fin).
   - Intervalos que crucen medianoche no están permitidos en un solo bloque (deben expresarse como bloques dentro del mismo día calendario 00:00 a 23:59).
3. **No Solapamiento Intra-Día**:
   - Si un día tiene múltiples bloques (ej. turno mañana `09:00-13:00` y turno tarde `14:00-18:00`), el cliente valida que no haya solapamiento (`blockB.start_time >= blockA.end_time`).
4. **Al menos 1 bloque si `is_working == true`**: Si un día está marcado como laborable, debe contener al menos un bloque de tiempo válido.

---

## H. Manejo del Warning de Horario Operativo (Out-of-Operating-Hours Warning)

El backend de NODO-03A evalúa dinámicamente si los bloques asignados al profesional caen fuera del horario general del establecimiento (`establishments.operating_hours`), devolviendo el booleano:
```json
"out_of_operating_hours_warning": true
```

### Comportamiento UI:
- **No Bloqueante**: NO impide guardar ni borra el horario.
- **Visualización**:
  - Si es `true`, se despliega un `Container` decorado con borde y fondo ámbar suave (`Colors.amber.shade50`), icono de advertencia y mensaje claro.
  - Se muestra tanto al cargar un horario existente como inmediatamente después de una respuesta exitosa de `PUT` que contenga `"out_of_operating_hours_warning": true`.
  - Si es `false` o no hay horario, el banner no se renderiza.

---

## I. Validaciones de Formulario y UX de Errores

| Código / Error Backend | Causa en UI | Mensaje Presentado al Usuario |
|---|---|---|
| `VALIDATION_FAILED` (400) | Formato `HH:mm` inválido o `start >= end` | *"Revise los horarios: la hora de inicio debe ser menor a la hora de fin y tener formato HH:mm."* |
| `BLOCKS_OVERLAP` (400) | Bloques de un mismo día se solapan | *"Los bloques horarios de un mismo día no pueden superponerse."* |
| `FORBIDDEN_ROLE` (403) | `RECEPTIONIST` intenta guardar/borrar, o `PROFESSIONAL` intenta borrar | *"No cuenta con permisos para realizar esta operación sobre el horario."* |
| `FORBIDDEN_SELF_MANAGEMENT_ONLY` (403) | Profesional intentando editar a otro colaborador | *"Solo puedes configurar y editar tu propio horario de trabajo."* |
| `MEMBERSHIP_NOT_FOUND` (404) | Membresía no encontrada en el establecimiento | *"El miembro del personal seleccionado no existe en este establecimiento."* |
| `500 INTERNAL ERROR` | Fallo de conexión o base de datos | *"Error al comunicarse con el servidor. Intente nuevamente."* |

---

## J. Matriz de Autoridad Backend vs Matriz RBAC de UX

Para eliminar cualquier ambigüedad, separamos explícitamente la **Autoridad Backend Real** del **Comportamiento UX de la Pantalla**:

### 1. Matriz de Autoridad Backend Real (Inmutable)

| Rol Activo | READ (Listado Establecimiento) | READ (Detalle Individual) | WRITE / PUT (Reemplazo Semanal) | DELETE (Reset a Vacío) |
|---|---|---|---|---|
| **OWNER** | Autorizado (Global) | Autorizado (Cualquier staff) | Autorizado (Cualquier staff) | Autorizado (Cualquier staff) |
| **MANAGER** | Autorizado (Global) | Autorizado (Cualquier staff) | Autorizado (Cualquier staff) | Autorizado (Cualquier staff) |
| **PROFESSIONAL** | Autorizado (Global) | Autorizado (Cualquier staff) | **Restringido a Self (`actorId === targetId`)** (403 si ajeno) | **Prohibido (403 FORBIDDEN_ROLE)** |
| **RECEPTIONIST** | Autorizado (Global) | Autorizado (Cualquier staff) | **Prohibido (403 FORBIDDEN_ROLE)** | **Prohibido (403 FORBIDDEN_ROLE)** |

### 2. Matriz RBAC de UX (Decisión de Diseño DEC-N03A-UX-01)

| Rol en Active Context | Modo de Pantalla | Selector de Personal | Edición Semanal | Botón Guardar (`PUT`) | Botón Reset (`DELETE`) | Warning Horario |
|---|---|---|---|---|---|---|
| **OWNER** | Administrador | Habilitado (todos) | Habilitado | Habilitado | Habilitado | Visible si aplica |
| **MANAGER** | Administrador | Habilitado (todos) | Habilitado | Habilitado | Habilitado | Visible si aplica |
| **PROFESSIONAL** | Mi Horario | **Fijado en Self** (Oculto/Bloqueado) | Habilitado (solo self) | Habilitado (solo self) | **Oculto / Inaccesible** | Visible si aplica |
| **RECEPTIONIST** | Solo Lectura | Habilitado (todos) | **Solo Lectura** | **Oculto / Inaccesible** | **Oculto / Inaccesible** | Visible si aplica |

> **Principio de Seguridad UX**: La interfaz de usuario nunca ofrece controles de mutación que resultarían en un `403` en backend, garantizando una experiencia coherente y libre de errores de autorización.

---

## K. Máquina de Estados de la Pantalla (State Transitions)

```
       [Init Screen]
             │
             ▼
      [State: LOADING] ──(GET /staff/schedules)──► Error? ──► [State: ERROR] (Botón Reintentar)
             │
             ├─► Éxito (Lista de staff cargada)
             ▼
      [State: LOADED] (Visualiza selector de staff y editor semanal del staff seleccionado)
             │
             ├──► Cambio de selección de staff (Admin) ──► [State: LOADING_DETAIL] (GET /staff/:id/schedule) ──► [State: LOADED]
             │
             ├──► Modificación de días / bloques (Estado mutable en memoria local)
             │
             ├──► Tap en "Guardar Horario" ──► [State: SAVING] (PUT /staff/:id/schedule)
             │        │
             │        ├─► Éxito (200) ──► SnackBar éxito + Actualiza warning + [State: LOADED]
             │        └─► Error (400/403/500) ──► SnackBar error + Permanece en [State: LOADED]
             │
             └──► Tap en "Resetear Horario" (Solo Owner/Manager) ──► Modal Confirmación
                      │
                      ├─► Confirma ──► [State: SAVING] (DELETE /staff/:id/schedule)
                      │        │
                      │        ├─► Éxito (200) ──► SnackBar éxito + Horario vacío + [State: LOADED]
                      │        └─► Error ──► SnackBar error + [State: LOADED]
                      │
                      └─► Cancela ──► Permanece en [State: LOADED]
```

---

## L. Integración con Active Context y Multitenancy

La pantalla `StaffScheduleScreen` interactúa con el contexto del establecimiento a través de `ActiveContextHolder`:

1. **Lectura de Contexto**:
   - `ActiveContextHolder.currentEstablishmentId`: Utilizado para el header y validaciones de establecimiento activo.
   - `ActiveContextHolder.currentMembershipId`: Identifica al usuario actual para resolver el modo `self` en `PROFESSIONAL`.
   - `ActiveContextHolder.currentRole`: Determina la matriz de permisos de UI.
2. **Propagación HTTP**:
   - Todos los requests HTTP emitidos por `StaffScheduleService` adjuntan automáticamente el token de autenticación (`Bearer <token>`) y el header `x-establishment-id` administrado por `ApiService`.

---

## M. Inyección de Dependencias y Testabilidad

Para garantizar el desacoplamiento total y permitir pruebas de widgets deterministas:

```dart
class StaffScheduleScreen extends StatefulWidget {
  final StaffScheduleService? service;
  final String? initialMembershipId;
  final VoidCallback? onBack;

  const StaffScheduleScreen({
    super.key,
    this.service,
    this.initialMembershipId,
    this.onBack,
  });

  @override
  State<StaffScheduleScreen> createState() => _StaffScheduleScreenState();
}
```

- Si `service == null`, se instancia `StaffScheduleService()` por defecto usando `ApiService.instance`.
- En pruebas unitarias y de widgets, se provee un mock/stub de `StaffScheduleService` con métodos predecibles.

---

## N. Estrategia de Pruebas Unitarias y Widgets (Mock Contracts)

El archivo de pruebas `frontend/test/saas_staff_schedule_test.dart` verificará los siguientes 15 casos de prueba esenciales:

1. **Model Parsing**:
   - Parseo de `TimeBlockModel` a partir de JSON y serialización correcta.
   - Parseo de `DayScheduleModel` con días activos e inactivos.
   - Parseo de `WeeklyScheduleModel` garantizando los 7 días canónicos.
   - Parseo de `StaffScheduleItemModel` y `StaffScheduleDetailModel` con warning `true`/`false`.
2. **Service Unit Tests**:
   - `listStaffSchedules`: Envía request GET a `/staff/schedules` y mapea lista.
   - `getStaffSchedule`: Envía request GET a `/staff/:id/schedule` y mapea detalle.
   - `setStaffSchedule`: Envía request PUT con payload canónico `weekly_schedule`.
   - `deleteStaffSchedule`: Envía request DELETE y confirma reset.
3. **Screen Widget Tests**:
   - **Renderizado Inicial**: Muestra spinner en estado `loading` y luego lista de personal.
   - **Manejo de Errores de Carga**: Muestra mensaje de error y botón reintentar.
   - **Warning de Horario Operativo**: Muestra banner ámbar cuando `out_of_operating_hours_warning == true` y lo oculta cuando es `false`.
   - **RBAC OWNER/MANAGER**: Muestra selector de personal, botón de guardar y botón de reset.
   - **RBAC PROFESSIONAL**: Oculta selector de personal ajeno (modo Mi Horario), muestra solo su propio horario, oculta botón de reset.
   - **RBAC RECEPTIONIST**: Muestra selector en modo solo lectura, deshabilita botones de guardado y reset.
   - **Interacción de Edición**: Permite conmutar días laborales y añadir/eliminar bloques de tiempo.
   - **Validación Local de Solapamiento**: Impide guardar si dos bloques se cruzan.

---

## O. Seguridad de Regresión y Preservación de Nodos Previos

- **NODO-01 a NODO-05**: Preservados al 100%. Ningún endpoint existente es alterado.
- **NODO-07 Fases 1 a 6A**: Preservadas. El test suite completo continuará pasando los 67 tests existentes + los nuevos tests de N03A.
- **NODO-02 UI (SCR-08)**: Intacto. Ningún modelo ni servicio de N02 es importado o modificado de manera destructiva.

---

## P. Checklist de Restricciones Arquitectónicas

- [x] Zero code changes durante la fase de arquitectura física.
- [x] Endpoints y DTOs auditados directamente contra el código backend real.
- [x] Distinción explícita e inequívoca entre READ, WRITE y DELETE.
- [x] No inventar endpoint POST (N03A utiliza exclusivamente PUT atómico).
- [x] Respetar orden canónico de días lunes a domingo (`monday` -> `sunday`).
- [x] Soporte para bloques múltiples intra-día con validación `start_time < end_time`.
- [x] Advertencia no bloqueante de `out_of_operating_hours_warning`.
- [x] Restricción de RBAC (Owner/Manager completo, Professional self-only sin delete, Receptionist read-only).
- [x] Desacoplamiento vía inyección de dependencias (`service`).
- [x] Verificación de `git status --short` antes y después.

---

## Q. Alcance Prohibido y Non-Goals Explícitos

1. **NO** implementar excepciones de calendario ni días festivos (pertenecen a N03B / Overrides).
2. **NO** implementar motor de cálculo de citas ni reservas de clientes (pertenecen a N04/N05).
3. **NO** crear rutas POST en backend.
4. **NO** modificar `HubSalonScreen` ni `main.dart` sin instrucción directa del Director.
5. **NO** alterar tablas SQL ni esquemas de base de datos.

---

## R. Criterios de Aceptación Funcionales y Técnicos

1. `flutter test test/saas_staff_schedule_test.dart` ejecuta y pasa 100% verde sin advertencias.
2. `flutter analyze` reporta 0 errores en los archivos creados.
3. La regresión completa de SaaS (Fases 1–6A, N02 UI, N03A UI) se mantiene verde.
4. El layout responde limpiamente a los diferentes roles y estados del horario.

---

## S. Punto de Integración en Hub Salón (SCR-02)

`HubSalonScreen` ya contiene la declaración física y el enlace visual:
- Botón: `btn_modulo_personal` (Etiqueta: `'Horarios (N03A)'`).
- Callback: `final VoidCallback? onNavigateToStaffSchedules;`.

Cuando la pantalla sea completada y autorizada para cableado, simplemente se inyectará la navegación a `StaffScheduleScreen` en dicho callback.

---

## T. Detalles de Navegación y Rutas

- **Ruta declarativa futura**: `/saas/staff-schedules`.
- **Navegación directa**: Vía `Navigator.push(context, MaterialPageRoute(builder: (_) => StaffScheduleScreen(...)))`.
- **Botón Volver**: Invoca `onBack` si está definido, o `Navigator.of(context).pop()`.

---

## U. Presupuesto de Tamaño de Archivo y Modularidad

| Archivo | Límite de Líneas Sugerido | Responsabilidad Única |
|---|---|---|
| `staff_schedule_model.dart` | ~180 líneas | Estructuras de datos inmutables y deserializadores JSON. |
| `staff_schedule_service.dart` | ~120 líneas | Métodos HTTP (`GET`, `PUT`, `DELETE`) y manejo de errores. |
| `staff_schedule_screen.dart` | ~450 líneas | UI interactiva, selector de staff, acordeón semanal y validaciones. |
| `saas_staff_schedule_test.dart` | ~350 líneas | Pruebas unitarias de modelos, servicio y widgets. |

---

## V. Orden de Implementación y Declaración de Preparación

Una vez que el Director otorgue el `GO DE IMPLEMENTACIÓN`:

1. **Paso 1**: Crear `frontend/lib/models/saas/staff_schedule_model.dart`.
2. **Paso 2**: Crear `frontend/lib/services/saas/staff_schedule_service.dart`.
3. **Paso 3**: Crear `frontend/lib/screens/saas/staff_schedule_screen.dart`.
4. **Paso 4**: Crear `frontend/test/saas_staff_schedule_test.dart` y ejecutar validaciones de análisis y test.
5. **Paso 5**: Generar `ncp/NODO-07-NODO-03A-UI-IMPLEMENTATION-REPORT.md`.

**ESTADO ACTUAL**: `PHYSICAL ARCHITECTURE READY FOR DIRECTOR APPROVAL`.
