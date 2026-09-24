# N03A-DEC-001 — STAFF AVAILABILITY SEMANTIC DECISION BUNDLE
## Architectural Semantic Decision Analysis & Proposal for Staff Operational Availability

**BUNDLE ID:** `N03A-DEC-001`  
**VERSION:** 1.0.0 (DECISION PROPOSAL)  
**ESTADO:** `PROPOSAL — PENDING DIRECTOR DECISION 🟡`  
**TIPO:** Architectural Semantic Decision Analysis & Consistency Bundle  
**AUTORIDAD RAÍZ:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `GOAL — N03A-DEC-001`  
**DOCUMENTOS PREVIOS CERRADOS DE REFERENCIA:**  
- `065_saas_foundation_core.sql` / `066_context_resolution_tenant_resolver.sql` (Foundation Core 🔒)  
- `067_service_offers.sql` / `068_service_assignments.sql` (Physical Migrations Ratified 🔒)  
- `ACTIVE-CONTEXT-NODE-CONTRACT-v1.0.md` / `HUB-SALON-NODE-CONTRACT-v1.0.md` (🔒)  
- `NODO-01-NODE-CONTRACT-v1.0.md` / `NODO-02-NODE-CONTRACT-v1.0.md` / `NODO-02-FORMAL-CLOSURE-v1.0.md` (🔒)  
- `DEC-SE-001` (Service Instantiation) / `DEC-SE-002` (Location & Schedule Independence 🔒)  
- `DEC-AS-001` ... `DEC-AS-014` (Assignment Consolidated Definition 🔒)  
- `DEC-PUB-001` / `DEC-AS-003` (Availability & Materialization Trigger 🛑)  
- [`/ncp/N03A-STAFF-AVAILABILITY-DISCOVERY-01.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/N03A-STAFF-AVAILABILITY-DISCOVERY-01.md) (Approved Discovery 🔒)  
- [`/ncp/NODO-03A-NODE-CONTRACT-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NODO-03A-NODE-CONTRACT-v1.0.md) (Proposal Contract 🟡)  
**FECHA:** 2026-09-11  

---

## 1. EXECUTIVE SUMMARY (RESUMEN EJECUTIVO)

El presente bundle de decisiones arquitectónicas resuelve de forma previa y formal las **8 definiciones semánticas esenciales** requeridas antes de someter a ratificación directiva el Node Contract `NODO-03A-v1.0` (*Staff Operational Availability & Schedule Runtime*).

En estricta observancia del principio **"NO CODE BEFORE CONTRACT"** y preservando la inmutabilidad de los activos de Foundation (`065`, `066`), Pre-Nodo 01, NODO-01 y NODO-02, este documento:
1. Evalúa las opciones semánticas para cada dimensión sin prejuzgar esquemas físicos DDL, tablas ni migraciones.
2. Mantiene el desacoplamiento axiomático:
   $$\text{ESTABLISHMENT OPERATING HOURS} \neq \text{STAFF AVAILABILITY} \neq \text{SERVICE ASSIGNMENT} \neq \text{APPOINTMENT SLOT}$$
3. Concluye con una matriz de consistencia integral y una compuerta formal de aprobación directiva (**Director Gate**).

---

## 2. DETAILED DECISION ANALYSES (ANÁLISIS DE LAS 8 DECISIONES)

---

### DECISION 01 — AVAILABILITY ADMINISTRATION AUTHORITY

- **DECISION ID:** `N03A-DEC-01`
- **QUESTION:** ¿Quién tiene la autoridad formal para crear, modificar y eliminar la disponibilidad operativa de un colaborador en la sede?
- **EVIDENCE:**
  - `DEC-AS-001` cerró que `OWNER` y `MANAGER` poseen la autoridad administrativa de asignación y gestión de personal en el establecimiento dentro de `activeContext`.
  - El rol `PROFESSIONAL` representa al colaborador operativo en sede (`065_saas_foundation_core.sql`).
  - En la operativa real de salones de belleza, los profesionales frecuentemente autogestionan o declaran sus horas de presencia, mientras que la administración mantiene supervisión y autoridad delegada.
- **OPTIONS:**
  - **Option A:** Exclusivamente `OWNER` y `MANAGER` (Gobierno centralizado estricto de la sede).
  - **Option B:** Exclusivamente el propio `PROFESSIONAL` (Auto-gestión pura sin control administrativo).
  - **Option C:** `OWNER` / `MANAGER` (para cualquier colaborador de la sede) **+** `PROFESSIONAL` (auto-gestión exclusiva de su propio horario: `target_membership_id === req.membershipId`).
  - **Option D:** Otros (Roles granulares / RBAC adicional no existente en Foundation).
- **RECOMMENDATION:** **Option C** (Propuesta recomendada: `OWNER`/`MANAGER` con potestad general de sede y `PROFESSIONAL` con auto-gestión acotada a su propia membresía). Alternativa estricta: **Option A**.
- **ARCHITECTURAL IMPACT:** Reutiliza estrictamente el modelo de roles de Foundation (`memberships.role`) e inyecciones de `activeContext`. Cero creación de RBAC granular o capabilities artificiales.
- **STATUS:** `REQUIRES DIRECTOR DECISION 🛑`

---

### DECISION 02 — AVAILABILITY SCOPE

- **DECISION ID:** `N03A-DEC-02`
- **QUESTION:** ¿A qué ámbito ontológico pertenece conceptualmente la disponibilidad operativa de personal?
- **EVIDENCE:**
  - `065_saas_foundation_core.sql` define `MEMBERSHIP` como el vínculo contractual contextualizado a una pareja `(tenant_id, establishment_id)`.
  - `DEC-SE-002.1` y `002.3` establecieron que la infraestructura, horarios y operaciones pertenecen autónomamente a la sede (`ESTABLISHMENT`).
  - Un usuario puede tener múltiples membresías en distintas sedes dentro de un mismo tenant o en tenants distintos.
- **OPTIONS:**
  - **Option A:** Pertenece al `MEMBERSHIP` de forma global (incoherente, pues la membresía ya está ligada a un establecimiento).
  - **Option B:** Pertenece a la pareja contextual `(MEMBERSHIP, ESTABLISHMENT)` dentro del `TENANT`.
  - **Option C:** Pertenece al `PROFESSIONAL` globalmente (`user_id` transversal) (violación de aislamiento multi-sede).
- **RECOMMENDATION:** **Option B** (La disponibilidad es estrictamente contextual a la membresía en esa sede específica; un profesional con 2 membresías en 2 sedes gestiona horarios 100% independientes en cada sede).
- **ARCHITECTURAL IMPACT:** Preserva la autonomía multi-sede (`DEC-SE-002`), previene cruces de agenda inter-sede y se alinea con la integridad referencial de Foundation (`065`).
- **STATUS:** `PROPOSED 🟡`

---

### DECISION 03 — WEEKLY RECURRING MODEL

- **DECISION ID:** `N03A-DEC-03`
- **QUESTION:** ¿Cuál es la estructura conceptual mínima requerida para modelar la disponibilidad operativa semanal de un colaborador?
- **EVIDENCE:**
  - En la operativa de estética y bienestar, los profesionales laboran en jornadas partidas (ej. turnos matutino y vespertino con descansos intermedios) o jornadas continuas.
  - El esquema legacy `perfiles_prestador` utilizaba un único inicio/fin diario (`active_start_hour`/`active_end_hour`), lo cual demostró ser limitante al impedir modelar pausas o jornadas fraccionadas.
- **OPTIONS:**
  - **Option A:** Rango monolítico único por día (`start_time` y `end_time` continuos).
  - **Option B:** Matriz semanal canónica de 7 días (`monday` a `sunday`), donde cada día contiene un indicador de día laborable (`is_working`) y una lista de $0..N$ intervalos de tiempo no solapados (`time_blocks: [{start_time, end_time}]`). Días no laborables se representan con `is_working = false` o lista vacía.
  - **Option C:** Series temporales continuas con fechas absolutas (sobrecomplejidad innecesaria para disponibilidad base recurrente).
- **RECOMMENDATION:** **Option B** (Modelo semanal recurrente de $0..N$ bloques horarios por día; proporciona flexibilidad para turnos partidos y descansos sin requerir entidades complejas).
- **ARCHITECTURAL IMPACT:** Modela la realidad operativa de los salones sin crear esquemas rígidos ni tipos físicos prematuros.
- **STATUS:** `PROPOSED 🟡`

---

### DECISION 04 — OVERLAPPING INTERVALS SEMANTICS

- **DECISION ID:** `N03A-DEC-04`
- **QUESTION:** ¿Cómo se tratan semánticamente los intervalos de tiempo solapados para un mismo colaborador en el mismo día y en la misma sede?
- **EVIDENCE:**
  - Un colaborador no puede encontrarse físicamente en dos turnos de trabajo concurrentes y solapados dentro del mismo establecimiento.
  - El cálculo determinista de disponibilidad exige que la unión de intervalos de un día represente franjas disjuntas.
- **OPTIONS:**
  - **Option A:** Prohibición estricta (**FORBIDDEN**): Ningún bloque horario $[s_1, e_1]$ puede solaparse con $[s_2, e_2]$ en el mismo día ($\max(s_1, s_2) < \min(e_1, e_2)$ es inválido).
  - **Option B:** Permitido con fusión automática (**ALLOWED & MERGED**): El sistema fusiona silenciosamente bloques solapados.
  - **Option C:** Indefinido (**UNDEFINED**).
- **RECOMMENDATION:** **Option A** (Invariante semántico: bloques solapados intradía son estrictamente rechazados como entrada inválida `400 Bad Request`).
- **ARCHITECTURAL IMPACT:** Garantiza integridad declarativa, evita ambigüedad en slots y simplifica la validación en la capa de servicios.
- **STATUS:** `PROPOSED 🟡`

---

### DECISION 05 — ESTABLISHMENT OPERATING HOURS RELATION

- **DECISION ID:** `N03A-DEC-05`
- **QUESTION:** ¿Cuál es la relación semántica exacta entre la disponibilidad del colaborador y el horario comercial de la sede (`establishments.operating_hours`), y cómo se manifiesta en runtime?
- **EVIDENCE:**
  - `DEC-SE-002` ratificó que $\text{professional.schedule} \subseteq \text{establishment.operating_hours}$ es una relación conceptual de subconjunto de negocio, **NO una identidad de datos ni una sincronización automática**.
  - En la realidad comercial, un profesional puede requerir franjas ligeramente fuera del horario al público (ej. preparación previa de cabina o cierre administrativo) o el salón puede operar con flexibilidad.
- **DISTINCIÓN OBLIGATORIA:**
  1. *Relación Arquitectónica:* El horario del establecimiento es el **marco macro de referencia comercial** de la sede.
  2. *Regla de Validación en Runtime:* Se debe decidir si violar la contención es un rechazo bloqueante o una advertencia informativa.
- **OPTIONS:**
  - **Option A:** Comparación estrictamente informativa (Cero validación, solo referencia analítica).
  - **Option B:** Advertencia informativa (**WARNING ONLY**): Si el horario del personal excede el de la sede, la operación se acepta pero el DTO incluye `out_of_operating_hours_warning: true`.
  - **Option C:** Validación estricta bloqueante (**HARD VALIDATION**): Se rechaza con `422 Unprocessable Entity` cualquier bloque de personal que no esté 100% contenido en el horario comercial de la sede.
  - **Option D:** Indefinido (**UNDEFINED**).
- **RECOMMENDATION:** **Option B** (Advertencia informativa `WARNING ONLY`), preservando la soberanía del salón para autorizar excepciones operativas sin trabas rígidas.
- **ARCHITECTURAL IMPACT:** Respeta `DEC-SE-002.4` y `002.5`, evita acoplamientos destructivos y no genera bloqueos operacionales innecesarios.
- **STATUS:** `REQUIRES DIRECTOR DECISION 🛑`

---

### DECISION 06 — EXCEPTIONS, TIME-OFF & ABSENCES BOUNDARY

- **DECISION ID:** `N03A-DEC-06`
- **QUESTION:** ¿Debe `NODO-03A v1.0` incorporar el modelado de excepciones de calendario (vacaciones, ausencias médicas, licencias, cierres puntuales)?
- **EVIDENCE:**
  - El discovery `N03A-STAFF-AVAILABILITY-DISCOVERY-01` demostró que la brecha fundamental e inmediata es la **disponibilidad semanal recurrente**.
  - Los sistemas de ausencias y vacaciones requieren calendarios absolutos por rango de fechas, aprobaciones y flujos de RRHH independientes.
- **OPTIONS:**
  - **Option A:** Incluir en `NODO-03A v1.0` (Aumenta significativamente la complejidad del nodo inicial).
  - **Option B:** Excluir formalmente de `NODO-03A v1.0` y clasificarlo como **`UNDEFINED / FUTURE CAPABILITY`**.
- **RECOMMENDATION:** **Option B** (`NODO-03A v1.0` se limita estrictamente a la disponibilidad semanal recurrente; las excepciones temporales por fecha se difieren como extensión posterior).
- **ARCHITECTURAL IMPACT:** Permite cerrar un nodo mínimo, seguro y altamente desacoplado, evitando sobrediseño prematuro.
- **STATUS:** `PROPOSED 🟡`

---

### DECISION 07 — STATE MODEL & LIFECYCLE SEMANTICS

- **DECISION ID:** `N03A-DEC-07`
- **QUESTION:** ¿Requiere la disponibilidad de personal una máquina de estados explícita (`status`) o se gobierna por semántica de presencia/ausencia con validez derivada?
- **EVIDENCE:**
  - `DEC-AS-009` y `DEC-AS-013-C` demostraron para `ASSIGNMENT` que añadir máquinas de estado internas (`ACTIVE`, `REVOKED`) genera redundancia y desincronización con el estado maestro de `MEMBERSHIP`.
  - La disponibilidad es un registro declarativo: o está configurada o no lo está.
- **OPTIONS:**
  - **Option A:** Ciclo de vida con máquina de estados explícita (`status: DRAFT / ACTIVE / INACTIVE / ARCHIVED`).
  - **Option B:** Semántica de presencia/ausencia declarativa (**PRESENCE / ABSENCE SEMANTICS**):
    - La configuración existe (`CONFIGURED`) o no existe (`NOT_CONFIGURED`).
    - La validez operativa se deriva dinámicamente:
      $$\text{SCHEDULE es OPERATIVAMENTE VÁLIDO} \iff \text{MEMBERSHIP.status} = \text{'ACTIVE'}$$
  - **Option C:** Indefinido (**UNDEFINED**).
- **RECOMMENDATION:** **Option B** (Semántica declarativa pura sin columna de estado propia; la operatividad se deriva del estado activo de la membresía).
- **ARCHITECTURAL IMPACT:** Coherencia total con la doctrina de `DEC-AS-009` y eliminación de divergencias de estado en runtime.
- **STATUS:** `PROPOSED 🟡`

---

### DECISION 08 — SLOT GENERATION BOUNDARY

- **DECISION ID:** `N03A-DEC-08`
- **QUESTION:** ¿Debe `NODO-03A` generar slots de agendamiento o limitarse exclusivamente a la declaración de disponibilidad?
- **EVIDENCE:**
  - El cálculo de slots libres es una función dependiente de: (1) Duración del servicio (`service_offers`), (2) Asignación técnica (`service_assignments`), (3) Horario del colaborador (`staff_schedules`), (4) Ocupación por reservas existentes (`bookings`).
  - Mezclar el mantenimiento de horarios con el cálculo de slots violaría el principio de responsabilidad única.
- **OPTIONS:**
  - **Option A:** `NODO-03A` mantiene horarios y calcula slots.
  - **Option B:** `NODO-03A` es **exclusivamente declarativo y de mantenimiento de disponibilidad**. La generación y cálculo de slots de agendamiento corresponde a un nodo downstream posterior (`SaaS Appointment & Booking Engine`).
- **RECOMMENDATION:** **Option B** (Declaración de disponibilidad únicamente; generación de slots downstream).
- **ARCHITECTURAL IMPACT:** Blindaje modular estricto entre almacenamiento de disponibilidad y algoritmos de agendamiento.
- **STATUS:** `PROPOSED 🟡`

---

## 3. CONSOLIDATED DECISION MATRIX (MATRIZ CONSOLIDADA)

| Decision ID | Materia / Dimensión | Propuesta Recomendada | Clasificación de Estado |
| :--- | :--- | :--- | :---: |
| **N03A-DEC-01** | Autoridad de Administración | `OWNER`/`MANAGER` + `PROFESSIONAL` (Auto-gestión acotada) | **REQUIRES DIRECTOR DECISION 🛑** |
| **N03A-DEC-02** | Ámbito / Scope de Horario | Contextual a `(MEMBERSHIP, ESTABLISHMENT)` en `TENANT` | **PROPOSED 🟡** |
| **N03A-DEC-03** | Modelo Semanal Recurrente | 7 Días, $0..N$ Intervalos horarios no solapados por día | **PROPOSED 🟡** |
| **N03A-DEC-04** | Intervalos Solapados | Prohibición estricta (`FORBIDDEN`) a nivel de dominio | **PROPOSED 🟡** |
| **N03A-DEC-05** | Relación con Horario de Sede | Advertencia informativa (`WARNING ONLY`) | **REQUIRES DIRECTOR DECISION 🛑** |
| **N03A-DEC-06** | Excepciones / Vacaciones | Excluidas de v1.0 (`UNDEFINED / FUTURE CAPABILITY`) | **PROPOSED 🟡** |
| **N03A-DEC-07** | Modelo de Estados | Presencia/Ausencia declarativa + Validez derivada | **PROPOSED 🟡** |
| **N03A-DEC-08** | Frontera de Slots | Declaración de disponibilidad únicamente (Slots downstream) | **PROPOSED 🟡** |

---

## 4. CONSISTENCY TEST (PRUEBA FORMAL DE CONSISTENCIA CRUZADA)

Se evaluó la compatibilidad integral de las 8 propuestas frente a la arquitectura cerrada:

```text
================================================================================
                      MATRIZ DE CONSISTENCIA CRUZADA
================================================================================
  [X] No conflict with Foundation (065, 066):         PASS (Reutiliza memberships y RLS)
  [X] No conflict with Active Context:                PASS (Inyección server-side 100%)
  [X] No conflict with Membership:                    PASS (No altera roles ni status)
  [X] No conflict with DEC-SE-002:                    PASS (Autonomía horaria preservada)
  [X] No conflict with Assignment (DEC-AS-014):       PASS (Ortogonalidad absoluta)
  [X] No conflict with Service Offer:                 PASS (Cero acoplamiento de catálogo)
  [X] No conflict with NODO-02:                       PASS (No altera catálogo/asignaciones)
  [X] No conflict with NODO-01:                       PASS (No altera handover DTO)
  [X] No B2C coupling:                                PASS (Cero mutación en Pre-Nodo 01)
  [X] No slot generation:                             PASS (Diferido a motor de agendamiento)
  [X] No booking responsibility:                      PASS (Cero gestión de reservas)
  [X] No frontend responsibility:                     PASS (Definición conceptual y lógica)
  [X] No physical schema invented:                    PASS (Cero DDL, tablas o migraciones)
--------------------------------------------------------------------------------
  CONSOLIDATED CONSISTENCY EVALUATION:                100% PASS 🟢
================================================================================
```

---

## 5. DIRECTOR GATE (COMPUERTA DE DECISIÓN DIRECTIVA)

Se somete el bundle al Director del Proyecto para su ratificación y resolución de puntos pendientes:

```text
================================================================================
🛑 DIRECTOR GATE — DECISIÓN Y RATIFICACIÓN REQUERIDA
================================================================================

1. DECISIONES QUE REQUIEREN DEFINICIÓN DIRECTIVA EXPLÍCITA:
   --------------------------------------------------------
   [ ] N03A-DEC-01 (Autoridad):
       ( ) Opción C: OWNER/MANAGER + PROFESSIONAL (Auto-gestión acotada) [RECOMENDADA]
       ( ) Opción A: OWNER/MANAGER exclusivamente (Control centralizado)

   [ ] N03A-DEC-05 (Validación frente a Horario de Sede):
       ( ) Opción B: WARNING ONLY (Advertencia informativa no bloqueante) [RECOMENDADA]
       ( ) Opción C: HARD VALIDATION (Rechazo bloqueante 422 si excede horario sede)

2. DECISIONES RECOMENDADAS PARA RATIFICACIÓN EN BLOQUE:
   -----------------------------------------------------
   [ ] N03A-DEC-02: Scope contextual a (MEMBERSHIP, ESTABLISHMENT).
   [ ] N03A-DEC-03: Modelo semanal de 7 días con 0..N intervalos por día.
   [ ] N03A-DEC-04: Prohibición semántica de intervalos solapados intradía.
   [ ] N03A-DEC-06: Exclusión de excepciones/vacaciones de v1.0 (Diferidas).
   [ ] N03A-DEC-07: Semántica declarativa de presencia/ausencia + validez derivada.
   [ ] N03A-DEC-08: Declaración de disponibilidad pura (generación de slots downstream).

================================================================================
ESTADO: PROPOSAL — PENDING DIRECTOR DECISION 🟡
NO IMPLEMENTATION AUTHORIZED.
================================================================================
```

---

## 6. GOVERNANCE SELF-CHECK (AUTO-VERIFICACIÓN DE GOBERNANZA)

```text
[X] READ-ONLY
[X] No code changes
[X] No DB changes
[X] No DDL
[X] No migrations
[X] No API created
[X] No frontend modified
[X] No B2C touched
[X] No Foundation changes
[X] No NODO-02 changes
[X] No NODO-01 changes
[X] No HBC changes
[X] No physical model invented
[X] No Node Contract modification (NODO-03A-NODE-CONTRACT-v1.0.md intacto)
[X] No implementation
```

```text
================================================================================
FINAL STATE:
  DECISION BUNDLE — PROPOSAL
  WAIT FOR DIRECTOR DECISION 🛑
================================================================================
```
