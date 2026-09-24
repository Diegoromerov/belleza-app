# NEXT NODE ARCHITECTURAL DISCOVERY — POST NODO-02 v1.0
## Architectural Evidence, Consumer Analysis & Next Node Evaluation Report

**VERSION:** 1.0.0  
**ESTADO:** COMPLETED — PENDING DIRECTOR DECISION 🟡  
**FECHA:** 2026-09-11  
**TIPO:** Architectural Discovery & Evidence Report (READ-ONLY)  
**AUTORIDAD RAÍZ:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `GOAL — N03-001`  
**CONTRATOS DE REFERENCIA CERRADOS:**  
- `065_saas_foundation_core.sql` / `066_context_resolution_tenant_resolver.sql` (SaaS Foundation Core)  
- `067_service_offers.sql` / `068_service_assignments.sql` (Physical Structures Ratified)  
- `ACTIVE-CONTEXT-NODE-CONTRACT-v1.0.md`  
- `HUB-SALON-NODE-CONTRACT-v1.0.md`  
- `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md`  
- `HANDOVER-BOUNDARY-CONTRACT-v1.0.md`  
- `NODO-01-NODE-CONTRACT-v1.0.md`  
- `DEC-SE-001` / `DEC-SE-002` / `DEC-CAT-001` / `DEC-AS-001` ... `DEC-AS-014` / `DEC-PUB-001` / `DEC-AS-003`  
- `NODO-02-NODE-CONTRACT-v1.0.md` / `NODO-02-IMPLEMENTATION-CONTRACT-v1.0.md` / `NODO-02-FORMAL-CLOSURE-v1.0.md`  

---

## 1. EXECUTIVE FINDING (HALLAZGO EJECUTIVO)

Tras el cierre formal y ratificación definitiva de **`NODO-02` (SaaS Catalog & Operational Assignment Runtime)**, la investigación exhaustiva y estrictamente *read-only* de los activos del repositorio concluye:

1. **[ESTADO POST-NODO-02]** El ecosistema SaaS posee plenamente implementadas y operativas las capacidades de gestión durable de catálogo local (`service_offers`) y asignación operativa multi-servicio/multi-colaborador (`service_assignments`), aisladas por `tenant_id` y contextualizadas por `establishment_id`.
2. **[INEXISTENCIA DE CONSUMIDORES DOWNSTREAM]** Actualmente **no existe ningún consumidor operacional en runtime** de las tablas `service_offers` ni `service_assignments` fuera del propio `NODO-02`. Ni el marketplace B2C (`public.services`, `public.bookings`), ni los controladores heredados, ni la interfaz de usuario consumen actualmente estas estructuras durables.
3. **[CUELLO DE BOTELLA ARQUITECTÓNICO]** La continuidad hacia el dominio B2C permanece explícitamente detenida por **`DEC-AS-003` (`ARCHITECTURAL STOP — DIRECTOR DECISION REQUIRED 🛑`)**, la cual no ha definido si el disparador de materialización hacia `public.services` es automático (adaptador) o mediante comando manual en el Cockpit.
4. **[BRECHA OPERACIONAL INTERNA]** Dentro del dominio exclusivo SaaS B2B, no existe aún el modelo de horarios/turnos individuales de personal (`Staff Operational Availability & Shift Scheduling`), impidiendo resolver la disponibilidad real de un servicio asignado.
5. **[DICTAMEN DE CONTINUIDAD]** Se emite dictamen conforme a **OPTION B**: Existen múltiples vectores arquitectónicos posibles que requieren definición estratégica previa por parte del Director antes de abrir un nuevo Node Contract.

---

## 2. CURRENT CLOSED STATE (FOTOGRAFÍA FACTUAL POST-NODO-02)

```text
================================================================================
                    FOTOGRAFÍA FACTUAL DEL ESTADO POST NODO-02
================================================================================
  TENEMOS (CLOSED & OPERATIONAL 🔒):
  1. Tenant Core & Isolation:       PostgreSQL RLS + set_config('app.tenant_id')
  2. Establishment Model:           Sedes operativas con operating_hours generales
  3. Membership Model:              Vínculo contractual contextual (status, roles)
  4. Context Resolution Engine:     fn_resolve_user_tenant() + activeContext
  5. Hub Salón & CDC Gateways:      Creación y consulta contextual
  6. Handover Boundary (NODO-01):   Adaptador neutral DTO en memoria
  7. Service Offer Core:            Entidad durable SaaS con inmutabilidad R1
  8. Assignment Core:               Relación durable M:N con target profesional R2
  9. Test Battery Suite:            86/86 Tests Green (0 regresiones)

  FALTA (NO IMPLEMENTADO / PENDING):
  1. Disparador / Acto de Materialización hacia B2C (DEC-AS-003 🛑).
  2. Modelo de Horarios y Turnos Operativos individuales del Staff en Sede.
  3. Integración de UI/Cockpit Frontend con los endpoints de NODO-02.
  4. Motor de Reservas / Agenda Interna SaaS (SaaS Appointments).
  5. Subsistema Físico de Auditoría Histórica (DEC-AS-013-F).
  6. Habilitación is_active / Borrado de Service Offer / Taxonomía (Diferidos).
================================================================================
```

---

## 3. EVIDENCE REVIEWED (EVIDENCIA REVISADA)

Se auditó de forma exhaustiva la evidencia del repositorio:

| Activo / Ruta | Tipo | Hallazgo Clave |
| :--- | :--- | :--- |
| [`/backend/migrations/067_service_offers.sql`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/migrations/067_service_offers.sql) | DDL Físico | Estructura física cerrada: `(id, tenant_id, establishment_id, name, duration, price)`. Sin `is_active`, sin `provider_id`. |
| [`/backend/migrations/068_service_assignments.sql`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/migrations/068_service_assignments.sql) | DDL Físico | Estructura física cerrada: relación M:N con FK compuesta triple a `memberships` y `service_offers`. Sin `status`, sin `created_by`. |
| [`/backend/src/services/serviceOfferService.js`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/services/serviceOfferService.js) | Runtime | 4 operaciones de catálogo SaaS implementadas. Inmutabilidad R1 aplicada. |
| [`/backend/src/services/serviceAssignmentService.js`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/services/serviceAssignmentService.js) | Runtime | 5 operaciones de asignación implementadas. Verificación R2 de rol profesional aplicada. |
| [`/backend/src/controllers/serviceController.js`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/controllers/serviceController.js) | Legacy B2C | Opera exclusivamente sobre `public.services` con `provider_id = req.user.id`. Desconectado de `service_offers`. |
| [`/backend/src/controllers/bookingController.js`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/controllers/bookingController.js) | Legacy B2C | Opera exclusivamente sobre `public.bookings` consumiendo `public.services`. Desconectado de `service_assignments`. |
| [`/ncp/DEC-AS-003-MATERIALIZATION-TRIGGER-ANALYSIS-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/DEC-AS-003-MATERIALIZATION-TRIGGER-ANALYSIS-v1.0.md) | Decisión | Declara formalmente `ARCHITECTURAL STOP` sobre el disparador de persistencia B2C. |
| [`/ncp/DEC-PUB-001-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/DEC-PUB-001-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md) | Decisión | Establece que `PUBLICATION = NOT PRESENT` y `B2C Availability = is_active = TRUE`. |
| [`/ncp/DEC-AS-014-ASSIGNMENT-CONSOLIDATED-DEFINITION-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/DEC-AS-014-ASSIGNMENT-CONSOLIDATED-DEFINITION-v1.0.md) | Síntesis | Delimita fronteras estrictas entre Core SaaS, Auditoría y Materialización B2C. |

---

## 4. REAL CONSUMERS ANALYSIS (ANÁLISIS FACTUAL DE CONSUMIDORES)

```text
+----------------------+-------------------+-------------------------------------------------------------+
| Entidad / Concepto   | Clasificación     | Evidencia en Código                                         |
+----------------------+-------------------+-------------------------------------------------------------+
| service_offers       | REAL CONSUMER     | • serviceOfferService.js (CRUD Catálogo)                    |
|                      |                   | • serviceAssignmentService.js (Validación FK y consultas)    |
|                      |                   | • test_nodo02_runtime_suite.js / physical_suite             |
|                      +-------------------+-------------------------------------------------------------+
|                      | POTENTIAL CONSUMER| • Downstream B2C Materializer (DEC-AS-003 PENDING)          |
|                      |                   | • SaaS Internal Booking Engine (Agenda interna de salón)    |
|                      +-------------------+-------------------------------------------------------------+
|                      | LEGACY CONSUMER   | • Ninguno (B2C consume public.services, no service_offers)  |
|                      +-------------------+-------------------------------------------------------------+
|                      | NO CONSUMER       | • Frontend UI / HUB-SALON (aún no cableado)                 |
|                      |                   | • NODO-01 (adaptador in-memory DTO, sin I/O en tabla)       |
+----------------------+-------------------+-------------------------------------------------------------+
| service_assignments  | REAL CONSUMER     | • serviceAssignmentService.js (Gestión M:N de asignaciones) |
|                      |                   | • test_nodo02_runtime_suite.js / physical_suite             |
|                      +-------------------+-------------------------------------------------------------+
|                      | POTENTIAL CONSUMER| • Downstream B2C Materializer (DEC-AS-003 PENDING)          |
|                      |                   | • Staff Shift & Availability Engine (Turnos y Horarios)     |
|                      |                   | • SaaS Internal Booking Engine (Citas operacionales)        |
|                      +-------------------+-------------------------------------------------------------+
|                      | LEGACY CONSUMER   | • Ninguno                                                   |
|                      +-------------------+-------------------------------------------------------------+
|                      | NO CONSUMER       | • B2C Marketplace / Bookings (desconoce service_assignments)|
+----------------------+-------------------+-------------------------------------------------------------+
| memberships          | REAL CONSUMER     | • contextResolutionService.js (Resolución de membresías)    |
|                      |                   | • activeContextMiddleware.js (Validación de rol y status)   |
|                      |                   | • crearDesdeCeroService.js (Creación de membresía OWNER)    |
|                      |                   | • hubSalonService.js (Listado de colaboradores de sede)     |
|                      |                   | • serviceAssignmentService.js (Elegibilidad profesional R2) |
|                      +-------------------+-------------------------------------------------------------+
|                      | POTENTIAL CONSUMER| • Staff Shift & Availability Engine                         |
|                      |                   | • Payroll / Commissions Subsystem                           |
+----------------------+-------------------+-------------------------------------------------------------+
| establishments       | REAL CONSUMER     | • contextResolutionService.js / activeContextService.js     |
|                      |                   | • crearDesdeCeroService.js / hubSalonService.js             |
|                      |                   | • serviceOfferService.js / serviceAssignmentService.js      |
+----------------------+-------------------+-------------------------------------------------------------+
| Active Context       | REAL CONSUMER     | • activeContextMiddleware.js                                |
|                      |                   | • hubSalonController.js / serviceOfferController.js        |
|                      |                   | • serviceAssignmentController.js                            |
+----------------------+-------------------+-------------------------------------------------------------+
```

---

## 5. OPEN ARCHITECTURAL DECISIONS (DECISIONES ABIERTAS / PENDIENTES)

Se identifican exclusivamente las decisiones formalmente registradas como abiertas o diferidas:

| Decisión | Estado | Evidencia | ¿Bloquea el Siguiente Nodo? | Justificación |
| :--- | :--- | :--- | :---: | :--- |
| **`DEC-AS-003`** (Materialization Trigger Authority) | `ARCHITECTURAL STOP 🛑` | [`/ncp/DEC-AS-003-MATERIALIZATION-TRIGGER-ANALYSIS-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/DEC-AS-003-MATERIALIZATION-TRIGGER-ANALYSIS-v1.0.md) | **SÍ (si el siguiente nodo es B2C Materialization)** | No se puede diseñar ni implementar la persistencia en `public.services` sin definir si el trigger es automático o por comando SaaS. |
| **`DEC-PUB-001`** (Availability Semantics) | `RECONCILED ANALYSIS 🟡` | [`/ncp/DEC-PUB-001-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/DEC-PUB-001-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md) | **NO** | Reconciliada; `is_active` B2C y ausencia de `PUBLISH` quedaron demostradas. |
| **`service_offers.is_active`** | `UNDEFINED / PENDING` | `ARCH-BUNDLE-SO-01-R1` | **NO** | La oferta es durable; la operatividad se resuelve por asignación y personal activo. |
| **`DELETE SERVICE_OFFER`** | `UNDEFINED / DEFERRED` | `ARCH-BUNDLE-SO-01-R1` | **NO** | No bloquea consumo descendente de ofertas existentes. |
| **SaaS Catalog Taxonomy** | `UNDEFINED / DEFERRED` | `ARCH-BUNDLE-SO-PHYSICAL-01` | **NO** | No bloquea flujo operativo básico. |
| **Historical Audit Subsystem** | `UNDEFINED / DEFERRED` | `DEC-AS-013-F` | **NO** | Subsistema desacoplado de telemetría y logs. |
| **Staff Shifts & Operational Availability** | `UNDEFINED / NOT DESIGNED` | `065_saas_foundation_core.sql` | **SÍ (si el siguiente nodo es Disponibilidad / Agenda)** | `065` tiene `establishments.operating_hours`, pero no horarios individuales de colaboradores en SaaS. |

---

## 6. BLOCKING / NON-BLOCKING ANALYSIS

```text
================================================================================
ANÁLISIS DE CUELLOS DE BOTELLA Y DEPENDENCIAS CRÍTICAS:

  EJE 1: INTEGRACIÓN CON B2C MARKETPLACE (Downstream Materialization)
  ├── Requiere: public.services(provider_id) <- (service_offers + service_assignments)
  ├── Bloqueador: DEC-AS-003 (ARCHITECTURAL STOP 🛑)
  └── Diagnóstico: BLOQUEADO hasta resolución directiva de DEC-AS-003.

  EJE 2: GOBERNANZA OPERACIONAL INTERNA SAAS (Staff Availability & Shifts)
  ├── Requiere: Modelar horarios/turnos semanales de colaboradores por sede en SaaS
  ├── Bloqueador: Ausencia de contrato de disponibilidad operativa de colaboradores
  └── Diagnóstico: NO BLOQUEADO POR B2C, pero requiere Architectural Discovery.

  EJE 3: AGENDA / RESERVAS INTERNAS SAAS (Internal Salon Bookings)
  ├── Requiere: Catálogo (NODO-02 🔒) + Asignación (NODO-02 🔒) + Disponibilidad Horaria
  ├── Bloqueador: Eje 2 (Disponibilidad no modelada)
  └── Diagnóstico: DEPENDIENTE de la resolución previa del Eje 2.
================================================================================
```

---

## 7. CANDIDATE NEXT NODES (CANDIDATOS A SIGUIENTE NODO)

> [!IMPORTANT]
> Los siguientes candidatos constituyen exclusivamente **PROPUESTAS DE DISCOVERY — PROPOSALS NOT APPROVED**. Ninguno está aprobado ni autorizado para implementación.

```carousel
### CANDIDATO 1: Staff Operational Availability & Schedule Runtime (NODO-03A)
<!-- slide -->
**PROPÓSITO:**  
Modelar y gestionar los horarios operativos, turnos laborales y excepciones de disponibilidad de los colaboradores (`MEMBERSHIPS`) dentro del establecimiento (`ESTABLISHMENT`), en estricta observancia de `DEC-SE-002` (autonomía desacoplada frente a horarios B2C).

**ENTRADA:**  
- `activeContext` (`tenant_id`, `establishment_id`)
- `membership_id` (Colaborador activo)
- Definición de turnos / horarios semanales

**SALIDA:**  
- Estructura física / endpoints de horarios del staff en sede
- Cálculo de slots disponibles para asignaciones operativas

**DEPENDENCIAS:**  
- `065_saas_foundation_core.sql` (`establishments.operating_hours`, `memberships`)
- `NODO-02` (`service_assignments`)

**RIESGOS:**  
- Riesgo de acoplamiento prematuro con `perfiles_prestador.horarios_atencion` (debe permanecer aislado).

**POR QUÉ PODRÍA SER EL SIGUIENTE:**  
Completa el núcleo de gobernanza operativa del salón dentro del SaaS sin depender del desbloqueo de B2C ni de `DEC-AS-003`.
<!-- slide -->
### CANDIDATO 2: Downstream B2C Materialization Adapter (NODO-03B)
<!-- slide -->
**PROPÓSITO:**  
Implementar el adaptador de persistencia que materializa pares válidos `(SERVICE_OFFER + ASSIGNMENT)` hacia el esquema transaccional `public.services` con `provider_id = user_id`, haciendo los servicios agendables en el marketplace B2C.

**ENTRADA:**  
- `service_offers` + `service_assignments`
- `perfiles_prestador(id)` (Elegibilidad B2C)
- Disparador de materialización sancionado por el Director

**SALIDA:**  
- Filas creadas / sincronizadas en `public.services` con `is_active = true`

**DEPENDENCIAS:**  
- `NODO-02` (Catálogo y Asignaciones)
- Pre-Nodo 01 (`public.services`, `public.perfiles_prestador`)
- **RESOLUCIÓN OBLIGATORIA PREVIA DE `DEC-AS-003`**

**RIESGOS:**  
- Altísimo riesgo de inconsistencia o regresión si se intenta implementar sin cerrar antes `DEC-AS-003`.
- Posible contaminación de fronteras si no se respeta el aislamiento tenant/B2C.

**POR QUÉ PODRÍA SER EL SIGUIENTE:**  
Conecta la inversión SaaS realizada en NODO-01 y NODO-02 con el motor de negocio transaccional existente (Pre-Nodo 01).
<!-- slide -->
### CANDIDATO 3: Hub Cockpit Integration & Front Gateway (NODO-03C)
<!-- slide -->
**PROPÓSITO:**  
Exponer y cablear la capa de presentación y orquestación del Cockpit Hub Salón para permitir a los administradores (`OWNER`, `MANAGER`) operar interactivamente el catálogo y las asignaciones creadas en NODO-02.

**ENTRADA:**  
- Endpoints de `/api/v1/saas/hub/services` y `/api/v1/saas/hub/assignments`
- Sesión autenticada en frontend con selección de contexto activo

**SALIDA:**  
- Consumo real de APIs de NODO-02 por clientes web/móvil

**DEPENDENCIAS:**  
- `NODO-02`
- `activeContextMiddleware`

**RIESGOS:**  
- Puede ser prematuro si la definición de turnos y materialización modifica el flujo de experiencia de usuario.

**POR QUÉ PODRÍA SER EL SIGUIENTE:**  
Convierte las capacidades de backend de NODO-02 en una herramienta directamente utilizable por usuarios finales de la sede.
```

---

## 8. RECOMMENDATION (RECOMENDACIÓN ARQUITECTÓNICA)

Conforme a las opciones estipuladas en el protocolo:

```text
================================================================================
RECOMENDACIÓN: OPTION B
================================================================================
Existen múltiples capacidades arquitectónicas posibles post-NODO-02.

La elección de la siguiente unidad de trabajo depende de la PRIORIDAD ESTRATÉGICA
que determine el Director del Proyecto:

1. RUTA SAAS B2B PURA (Recomendada si se prioriza completar la gestión interna):
   -> Definir NODO-03 como "Staff Operational Availability & Schedule Runtime".
   -> Ventaja: Cero bloqueo por B2C; completa el modelo de turnos de la sede.

2. RUTA INTEGRACIÓN B2C (Recomendada si se prioriza monetizar / habilitar reservas B2C):
   -> Resolver y cerrar primeramente DEC-AS-003 (Materialization Trigger).
   -> Definir posteriormente NODO-03 como "Downstream B2C Materialization Adapter".
   -> Ventaja: Habilita el flujo de agendamiento en el marketplace existente.

ESTADO DE LAS PROPUESTAS:
PROPOSAL — NOT APPROVED
================================================================================
```

---

## 9. ARCHITECTURAL STOP / DIRECTOR GATE

Se emite formalmente la compuerta de gobierno:

```text
================================================================================
🛑 DIRECTOR GATE — DECISIÓN REQUERIDA
================================================================================
El Director del Proyecto debe instruir cuál de las siguientes directivas ejecutar:

[DIRECTIVA 1 — RESOLVER DEC-AS-003]:
Emitir el Goal de Decisión para resolver formalmente DEC-AS-003 (Trigger de
Materialización Automático vs Comando Manual), como paso previo obligatorio para
la integración con B2C (NODO-03B).

[DIRECTIVA 2 — DISCOVERY DE TURNOS / DISPONIBILIDAD SAAS]:
Autorizar exclusivamente el Architectural Discovery del Dominio de Disponibilidad
Operativa y Turnos de Personal en Sede (NODO-03A).

[DIRECTIVA 3 — ARCHITECTURAL STOP TOTAL]:
Detener la apertura de nuevos nodos hasta definir el roadmap de producto.
================================================================================
```

---

## 10. GOVERNANCE SELF-CHECK (AUTO-VERIFICACIÓN DE GOBERNANZA)

```text
[X] No se modificó código
[X] No se modificó DB
[X] No se ejecutó DDL
[X] No se crearon migraciones
[X] No se modificó Foundation
[X] No se modificó NODO-02
[X] No se modificó NODO-01
[X] No se modificó HBC
[X] No se modificó Pre-Nodo 01
[X] No se modificó frontend
[X] No se resolvieron decisiones pendientes
[X] No se asumió arquitectura futura
[X] No se convirtió evidencia legacy en autoridad
[X] No se implementó ningún candidato
[X] El informe termina en DIRECTOR GATE
```

```text
================================================================================
FINAL STATE:
  DISCOVERY ONLY
  NO IMPLEMENTATION
  WAIT FOR DIRECTOR DECISION 🛑
================================================================================
```
