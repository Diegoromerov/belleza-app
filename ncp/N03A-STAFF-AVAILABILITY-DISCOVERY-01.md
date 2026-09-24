# N03A — STAFF OPERATIONAL AVAILABILITY & SCHEDULE DISCOVERY v1.0
## Architectural Discovery & Evidence Report on Staff Availability and Working Hours

**VERSION:** 1.0.0  
**ESTADO:** COMPLETED — PENDING DIRECTOR DECISION 🟡  
**FECHA:** 2026-09-11  
**TIPO:** Architectural Discovery Report (READ-ONLY)  
**AUTORIDAD RAÍZ:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `GOAL — N03A-001`  
**CONTRATOS Y DECISIONES DE REFERENCIA:**  
- `065_saas_foundation_core.sql` / `066_context_resolution_tenant_resolver.sql` (Foundation Core)  
- `067_service_offers.sql` / `068_service_assignments.sql` (Physical Migrations Ratified)  
- `ACTIVE-CONTEXT-NODE-CONTRACT-v1.0.md` / `HUB-SALON-NODE-CONTRACT-v1.0.md`  
- `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md` / `HANDOVER-BOUNDARY-CONTRACT-v1.0.md`  
- `NODO-01-NODE-CONTRACT-v1.0.md` / `NODO-02-NODE-CONTRACT-v1.0.md` / `NODO-02-FORMAL-CLOSURE-v1.0.md`  
- `DEC-SE-001` (Service Instantiation) / `DEC-SE-002` (Location & Schedule Independence 🔒)  
- `DEC-AS-001` ... `DEC-AS-014` (Assignment Consolidated Definition 🔒)  
- `DEC-PUB-001` / `DEC-AS-003` (Availability & Materialization Trigger)  

---

## 1. EXECUTIVE FINDING (HALLAZGO EJECUTIVO)

La investigación exhaustiva y estrictamente *read-only* de los activos de código, contratos y bases de datos del repositorio concluye:

1. **[EVIDENCIA DE HORARIOS COMERCIALES EXISTENTES]** El sistema SaaS posee exclusivamente `establishments.operating_hours` (`065_saas_foundation_core.sql`), el cual representa única y normativamente el **horario comercial de apertura y cierre de las instalaciones físicas de la sede** (`DEC-SE-002.4`).
2. **[AUSENCIA TOTAL DE DISPONIBILIDAD DE STAFF EN SAAS]** En la capa SaaS actual (`memberships`, `service_offers`, `service_assignments`, `hubSalonService.js`), **NO EXISTE** ningún modelo, tabla, columna o lógica para representar la jornada laboral, turnos semanales, descansos o indisponibilidades de un colaborador en una sede.
3. **[DESACOPLAMIENTO DE HORARIOS B2C]** En el esquema B2C heredado existe `perfiles_prestador.weekly_schedule` (`providerController.js`), pero pertenece exclusivamente al prestador independiente en el marketplace individual y no distingue entre sedes ni tenants (`DEC-SE-002.5`).
4. **[BRECHA OPERACIONAL DEMOSTRADA]** El sistema SaaS puede expresar qué servicios tiene una sede (`service_offers`) y qué profesionales están habilitados para realizarlos (`service_assignments`), pero **no puede determinar en qué momentos o franjas horarias un profesional asignado está presente en la sede para ejecutar el servicio**.
5. **[DICTAMEN DE DISCOVERY]** Conforme a la evidencia analizada, se concluye con **OPTION A**: Existe una **necesidad arquitectónica real y delimitable** de contar con una capacidad propia de *Staff Operational Availability & Schedule* en SaaS para soportar el cálculo de disponibilidad operativa y la futura agenda interna de la sede.

---

## 2. CURRENT EVIDENCE (EVIDENCIA ACTUAL EN EL REPOSITORIO)

Se realizó un escaneo exhaustivo de conceptos de horarios, turnos y disponibilidad en la base de código:

```text
+-----------------------------------+--------------------+---------------------------------------------------------------+
| Concepto / Campo                  | Clasificación      | Ubicación y Evidencia en Código                               |
+-----------------------------------+--------------------+---------------------------------------------------------------+
| establishments.operating_hours    | REAL SAAS          | • 065_saas_foundation_core.sql:46 (JSONB DEFAULT '{}')        |
|                                   |                    | • hubSalonService.js:85 / crearDesdeCeroService.js:179        |
|                                   |                    | • DEC-SE-002.4 (Horario comercial de sede)                   |
+-----------------------------------+--------------------+---------------------------------------------------------------+
| perfiles_prestador.weekly_schedule| REAL B2C (LEGACY)  | • backend/index.js:1515 (JSONB días/horas)                    |
| active_start_hour/active_end_hour |                    | • providerController.js:213-242 (Cálculo de slots marketplace)|
|                                   |                    | • DEC-SE-002.5 (Disponibilidad individual prestador B2C)      |
+-----------------------------------+--------------------+---------------------------------------------------------------+
| memberships.schedule / shifts     | NO EXISTE          | • 065_saas_foundation_core.sql (Solo id, tenant, est, user,   |
|                                   |                    |   role, status). Cero columnas o tablas de turnos.            |
+-----------------------------------+--------------------+---------------------------------------------------------------+
| service_assignments.schedule      | NO EXISTE          | • 068_service_assignments.sql (Solo id, tenant, est, offer,   |
|                                   |                    |   membership). Cero columnas de horario.                      |
+-----------------------------------+--------------------+---------------------------------------------------------------+
| SaaS Availability Windows / Breaks| NO EXISTE          | Cero entidades o endpoints para descansos o pausas laborales. |
+-----------------------------------+--------------------+---------------------------------------------------------------+
| SaaS Absence / Vacation / Time Off| NO EXISTE          | memberships.status solo maneja ACTIVE/SUSPENDED/TERMINATED.   |
|                                   |                    | Cero modelado de ausencias temporales o vacaciones.           |
+-----------------------------------+--------------------+---------------------------------------------------------------+
| SaaS Slot Availability Engine     | NO EXISTE          | Cero lógica de cálculo de slots libres por sede y staff.      |
+-----------------------------------+--------------------+---------------------------------------------------------------+
```

---

## 3. ESTABLISHMENT OPERATING HOURS ANALYSIS (ANÁLISIS DE HORARIO DE SEDE)

### 3.1. Qué representa `establishments.operating_hours` [FACT]:
- Definido en PostgreSQL como:
  ```sql
  operating_hours JSONB NOT NULL DEFAULT '{}'::jsonb
  ```
- Almacena la estructura de apertura/cierre de la sede física (ej. `{"monday": {"open": "08:00", "close": "19:00", "is_closed": false}}`).
- Es retornado por `hubSalonService.js:getHubSalonSummary` y consumido por `NODO-01` en el DTO `target_establishment_descriptor`.

### 3.2. Resolución Normativa `DEC-SE-002` [CLOSED 🔒]:
- `DEC-SE-002.4` formalizó que `establishments.operating_hours` representa el **horario comercial de apertura y cierre de las instalaciones de la sede**.
- **NO contiene** la disponibilidad particular de los profesionales ni sus turnos.
- **NO existe ambigüedad:** La sede define el marco temporal macro en el cual el negocio está abierto al público.

---

## 4. MEMBERSHIP AVAILABILITY ANALYSIS (ANÁLISIS DE DISPONIBILIDAD DE MEMBERSHIP)

### 4.1. Estado Actual de `memberships` [FACT]:
La tabla `memberships` (`065_saas_foundation_core.sql:67`) modela exclusivamente la pertenencia contractual del usuario a la sede:
- `user_id`
- `establishment_id`
- `tenant_id`
- `role` (`OWNER`, `MANAGER`, `PROFESSIONAL`, `RECEPTIONIST`)
- `status` (`ACTIVE`, `SUSPENDED`, `TERMINATED`, `INACTIVE`)

### 4.2. Limitaciones Factuales del Sistema Actual:
Actualmente el sistema **NO PUEDE EXPRESAR**:
1. **Días Laborales Diferenciados:** Que un profesional trabaje los lunes y otro los martes.
2. **Jornadas Parciales:** Que un profesional trabaje solo en la mañana (ej. 08:00 - 13:00) y otro en la tarde.
3. **Multi-Sede Temporal:** Que un profesional con membresías en dos sedes trabaje Lunes/Miércoles en la Sede A y Martes/Jueves en la Sede B.
4. **Pausas y Descansos:** Bloques no disponibles dentro de la jornada (ej. almuerzo 13:00 - 14:00).
5. **Indisponibilidades Temporales:** Vacaciones, permisos médicos o licencias (actualmente solo se podría suspender administrativamente la membresía completa, lo cual apaga la autoridad y acceso al sistema).

---

## 5. ASSIGNMENT RELATION ANALYSIS (RELACIÓN CON ASSIGNMENT)

### 5.1. Frontera Conceptual Cerrada (`DEC-AS-014` 🔒):
El modelo consolidado de NODO-02 establece:
$$\text{SERVICE\_OFFER} \longleftrightarrow \text{ASSIGNMENT} \longleftrightarrow \text{MEMBERSHIP}$$

- `ASSIGNMENT` es una **capacidad operativa técnica**: declara formalmente que un colaborador está habilitado y autorizado para realizar un determinado servicio en esa sede.
- `ASSIGNMENT` **NO contiene ni debe contener** atributos de agenda, turnos ni marcas horarias (`DEC-AS-013-A`, `DEC-AS-014`).

### 5.2. Brecha de Ejecución Temporal:
Tener una oferta asignada a un colaborador (`ASSIGNMENT = VALID`) es una precondición necesaria pero **insuficiente** para agendar una cita o prestar el servicio en un momento determinado:
$$\text{Puede prestar el servicio} \quad (\text{ASSIGNMENT}) \quad \neq \quad \text{Está presente en la sede en este horario} \quad (\text{SCHEDULE})$$

---

## 6. B2C AVAILABILITY ANALYSIS (ANÁLISIS DE DISPONIBILIDAD EN B2C)

### 6.1. Dónde vive y qué hace el motor B2C [FACT]:
- Vive en `backend/src/controllers/providerController.js:getProviderSlots` y `backend/index.js:1515`.
- Consulta `perfiles_prestador.weekly_schedule`, `active_start_hour` y `active_end_hour` de `req.user.id`.
- Cruza la franja horaria del prestador con las reservas activas en `public.bookings` para generar slots libres (`HH:MM`).

### 6.2. Inadecuación para el Dominio SaaS B2B:
1. **Unicidad Global vs Multi-Sede SaaS:** `perfiles_prestador` es una tabla plana B2C indexada por `user_id`. Si un profesional trabaja en 3 salones distintos, un único `weekly_schedule` no permite modelar qué días/horas atiende en cada salón.
2. **Propiedad de Datos (`DEC-SE-002.5`):** `weekly_schedule` pertenece al prestador individual en el marketplace, no a la administración del salón.
3. **Aislamiento Multi-Tenant:** `perfiles_prestador` no tiene `tenant_id` ni `establishment_id`. No está protegido por RLS SaaS.

---

## 7. CONCEPTUAL DISTINCTIONS (DISTINCIONES CONCEPTUALES OBLIGATORIAS)

La evidencia analizada demuestra que deben separarse con rigor ontológico los siguientes conceptos:

```text
================================================================================
                    MAPA DE SEPARACIÓN CONCEPTUAL DE HORARIOS
================================================================================
1. [ESTABLISHMENT OPERATING HOURS] (Macro Marco de Sede - SaaS 065 🔒)
   - Horario de apertura del local comercial (ej. L-S 08:00 a 20:00).
   - Entidad: establishments.operating_hours.

2. [STAFF OPERATIONAL SCHEDULE / SHIFT PATTERN] (Jornada Base de Personal - DOMINIO IDENTIFICADO)
   - Horario semanal regular del colaborador en esa sede específica (ej. L-M-V 08:00 a 16:00).
   - Vínculo: MEMBERSHIP (contextual a Sede y Tenant).

3. [AVAILABILITY EXCEPTIONS / TIME OFF] (Excepciones Temporales - DOMINIO IDENTIFICADO)
   - Días u horas específicas donde el colaborador no labora (vacaciones, licencias, pausas).
   - Vínculo: MEMBERSHIP en fecha o rango específico.

4. [OPERATIONAL SERVICE ASSIGNMENT] (Capacidad Técnica - SaaS NODO-02 🔒)
   - Servicios que el colaborador sabe y puede ejecutar en la sede.
   - Entidad: service_assignments.

5. [EFFECTIVE OPERATIONAL AVAILABILITY] (Disponibilidad Derivada / Slots)
   - Intersección lógica calculada en tiempo real:
     (Horario Sede ∩ Turno Staff ∩ Asignación Servicio \ Excepciones \ Reservas Previas).
================================================================================
```

---

## 8. DEPENDENCY ANALYSIS (ANÁLISIS DE DEPENDENCIAS)

```text
+-----------------------+-------------------+-------------------------------------------------------------+
| Capacidad Existente   | Tipo Dependencia  | Justificación y Evidencia                                   |
+-----------------------+-------------------+-------------------------------------------------------------+
| Foundation Core (065) | BASE ESTRUCTURAL  | Provee establishments.operating_hours y memberships.        |
| Context Resolution    | AUTORIDAD BASE    | Resuelve el contexto activo (tenant_id / establishment_id). |
| Active Context (066)  | CONSUMIDOR POT.   | Transporta el contexto del actor que configura los turnos.  |
| NODO-01 (Handover)    | SIN DEPENDENCIA   | NODO-01 permanece neutral en memoria (DEC-SE-002.9).        |
| NODO-02 (Catalog/Asg) | SIN DEPENDENCIA   | NODO-02 funciona 100% cerrado sin requerir horarios.        |
| Hub Salón Cockpit     | CONSUMIDOR POT.   | Visualización de grilla horaria del staff en frontend.      |
| SaaS Internal Booking | CONSUMIDOR CRÍTICO| No puede calcular citas ni slots libres sin turnos de staff.|
| B2C Materialization   | CONSUMIDOR POT.   | Podría validar que el profesional tenga turno antes de B2C. |
+-----------------------+-------------------+-------------------------------------------------------------+
```

---

## 9. BLOCKING ANALYSIS (ANÁLISIS DE BLOQUEO)

```text
================================================================================
ANÁLISIS DE BLOQUEO:

  1. ¿Bloquea capacidades SaaS cerradas (NODO-01 / NODO-02)?
     -> NO. NODO-01 y NODO-02 están 100% cerrados, validados (86/86 PASS) y
        operan de forma independiente.

  2. ¿Bloquea el agendamiento interno en el Cockpit SaaS (SaaS Appointments)?
     -> SÍ. Sin modelo de turnos de personal en sede, el Cockpit no puede saber
        a qué hora citar a un cliente con un profesional específico.

  3. ¿Bloquea la materialización B2C (NODO-03B)?
     -> NO DIRECTAMENTE (el bloqueador formal de B2C es DEC-AS-003), pero
        la ausencia de turnos en SaaS impide coordinar agendas sincronizadas.
================================================================================
```

---

## 10. ARCHITECTURAL CONCLUSION (CONCLUSIÓN ARQUITECTÓNICA)

Conforme a las opciones establecidas en el objetivo:

```text
================================================================================
CONCLUSIÓN: OPTION A
================================================================================
Existe una necesidad arquitectónica clara para una capacidad de:
  "Staff Operational Availability & Schedule"

Fundamentos Demostrados:
1. establishments.operating_hours pertenece a la sede y no modela colaboradores.
2. perfiles_prestador.weekly_schedule pertenece a B2C y es monosede/incompatible con SaaS.
3. memberships no posee actualmente estructura temporal ni de turnos.
4. service_assignments define idoneidad técnica pero no disponibilidad temporal.
5. El sistema no puede actualmente calcular slots de disponibilidad en sede.

ESTADO DE LA RECOMENDACIÓN:
PROPOSAL — NOT APPROVED
================================================================================
```

---

## 11. DIRECTOR GATE (COMPUERTA DE DECISIÓN DIRECTIVA)

Se somete el informe al Director del Proyecto para su consideración:

```text
================================================================================
🛑 DIRECTOR GATE — DECISIÓN REQUERIDA
================================================================================
El Director del Proyecto debe determinar si:

[OPCIÓN 1 — AUTORIZAR DEFINICIÓN DE NODO-03A]:
Aprobar este discovery y autorizar la emisión de:
`GOAL — N03A-NODE-CONTRACT-01` (Staff Operational Availability & Schedule Contract).

[OPCIÓN 2 — PRIORIZAR B2C MATERIALIZATION (RESOLVER DEC-AS-003)]:
Pausar el modelado de disponibilidad SaaS y resolver primero DEC-AS-003 para
construir el adaptador de materialización hacia el marketplace B2C.

[OPCIÓN 3 — ARCHITECTURAL STOP]:
Pausar la apertura de nuevos contratos hasta nueva orden directiva.
================================================================================
```

---

## 12. GOVERNANCE SELF-CHECK (AUTO-VERIFICACIÓN DE GOBERNANZA)

```text
[X] READ-ONLY
[X] No código modificado
[X] No DB modificada
[X] No DDL
[X] No migraciones
[X] No tablas nuevas
[X] No columnas nuevas
[X] No frontend modificado
[X] No B2C modificado
[X] No Foundation modificado
[X] No NODO-02 modificado
[X] No NODO-01 modificado
[X] No HBC modificado
[X] No decisiones arquitectónicas cerradas modificadas
[X] No solución física inventada
[X] No Node Contract creado
[X] No implementación
[X] Resultado termina en DIRECTOR GATE
```

```text
================================================================================
FINAL STATE:
  DISCOVERY ONLY
  NO IMPLEMENTATION
  WAIT FOR DIRECTOR DECISION 🛑
================================================================================
```
