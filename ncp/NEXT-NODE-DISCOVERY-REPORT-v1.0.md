# NEXT NODE ARCHITECTURAL DISCOVERY — POST NODO-03A v1.0
## ARCHITECTURAL DISCOVERY REPORT & CANDIDATE EVALUATION

**DOCUMENT IDENTIFIER**: `NEXT-NODE-DISCOVERY-REPORT-v1.0`  
**CURRENT COMPLETED NODE**: `NODO-03A` (Staff Operational Availability & Schedule Runtime — CLOSED / RATIFIED)  
**DATE**: 2026-09-11  
**ROLE**: Senior Architecture Discovery Agent  
**AUTHORITY**: Director del Proyecto GlowApp SaaS  
**CLASSIFICATION**: READ-ONLY ARCHITECTURAL DISCOVERY — ZERO IMPLEMENTATION  
**DISCOVERY STATUS**: READY FOR DIRECTOR DECISION 🟡  
**IMPLEMENTATION AUTHORIZATION**: NOT GRANTED 🛑

---

## 1. ESTADO DE PARTIDA (CURRENT CLOSED ARCHITECTURAL STATE)

El proyecto GlowApp SaaS ha consolidado e inmunizado formalmente los siguientes componentes arquitectónicos:

```text
================================================================================
                    ESTADO CERRADO E INMUTABLE (POST NODO-03A)
================================================================================
  1. SaaS Foundation Core (065):     tenants, organizations, establishments,
                                     memberships, usuarios (RLS + isolation).
  2. Context Resolution Core (066):  fn_resolve_user_tenant() + activeContext.
  3. Cockpit & Onboarding:           HUB-SALON v1.0, CREAR-DESDE-CERO v1.0,
                                     HANDOVER-BOUNDARY-CONTRACT v1.0, NODO-01.
  4. SaaS Operational Catalog (067): service_offers (NODO-02 — Ratified).
  5. Staff Operational Link (068):   service_assignments (NODO-02 — Ratified).
  6. Staff Availability (069):       staff_schedules (NODO-03A — Ratified).
                                     (7-day weekly half-open intervals,
                                      bounded self-management, row locking).
  7. Test Battery Suite:             106 / 106 Tests Green (0 regressions).
================================================================================
```

### Cadena Operacional SaaS Actual:
$$	ext{TENANT} \longrightarrow 	ext{ORGANIZATION} \longrightarrow 	ext{ESTABLISHMENT}$$
$$\Big\downarrow$$
$$	ext{MEMBERSHIPS (Staff)} \quad \longleftrightarrow \quad 	ext{SERVICE OFFERS (Commercial Catalog)}$$
$$\Big\downarrow \hspace{5.5cm} \Big\downarrow$$
$$	ext{STAFF SCHEDULES (Availability)} \quad \longleftarrow \quad 	ext{SERVICE ASSIGNMENTS (Capability Matrix)}$$

---

## 2. PREGUNTA DE DESCUBRIMIENTO

> **"Después de NODO-03A, ¿cuál es la siguiente capacidad arquitectónica que el SaaS NECESITA para continuar coherentemente?"**

No se busca diseñar funcionalidades por especulación ni anticipar todo el roadmap comercial, sino identificar la siguiente transición o dependencia real demostrable en el sistema.

---

## 3. EVIDENCIA REVISADA (EVIDENCE FIRST)

Se auditó de forma estrictamente *read-only* el cuerpo contractual y físico del repositorio:

| Activo / Contrato | Tipo | Evidencia Factual y Estado Actual |
|---|---|---|
| [`/backend/migrations/067_service_offers.sql`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/migrations/067_service_offers.sql) | DDL Físico | Catálogo local durable por establecimiento (`name`, `duration`, `price`). Sin `provider_id`. |
| [`/backend/migrations/068_service_assignments.sql`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/migrations/068_service_assignments.sql) | DDL Físico | Vínculo $M:N$ formal entre `service_offers` y `memberships` de rol `PROFESSIONAL`. |
| [`/backend/migrations/069_staff_schedules.sql`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/migrations/069_staff_schedules.sql) | DDL Físico | Disponibilidad semanal $1..7$ de colaboradores por sede con restricción de no-solapamiento. |
| [`/backend/src/controllers/serviceController.js`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/controllers/serviceController.js) | Legacy B2C | Opera exclusivamente sobre `public.services` con `provider_id = req.user.id`. Desconectado de SaaS. |
| [`/backend/src/controllers/bookingController.js`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/controllers/bookingController.js) | Legacy B2C | Motor de reservas B2C que consume `public.services` y `public.perfiles_prestador`. |
| [`/ncp/DEC-SE-001-DECISION-RECORD-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/DEC-SE-001-DECISION-RECORD-v1.0.md) | Decisión | `SERVICE_OFFER ≠ public.services`. La instanciación en B2C es tardía y no automática. |
| [`/ncp/DEC-AS-003-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/DEC-AS-003-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md) | Decisión | **`ARCHITECTURAL STOP`**. El disparador de materialización hacia B2C permanece **`UNDEFINED`**. |
| [`/ncp/DEC-PUB-001-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/DEC-PUB-001-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md) | Decisión | `PUBLICATION = NOT PRESENT` en el código; B2C opera mediante flag `is_active = TRUE`. |
| [`/ncp/N03A-DEC-001-STAFF-AVAILABILITY-SEMANTIC-DECISION-BUNDLE.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/N03A-DEC-001-STAFF-AVAILABILITY-SEMANTIC-DECISION-BUNDLE.md) | Decisión | `N03A-DEC-06`: Excepciones y bloqueos por fecha específica quedaron fuera de v1.0. |

---

## 4. CANDIDATOS ENCONTRADOS

A partir del análisis riguroso de vacíos e integraciones downstream, se descubren exactamente **3 candidatos legítimos**:

```carousel
### CANDIDATO 1: Downstream B2C Materialization & Provider Adapter (NODO-04)
<!-- slide -->
**NOMBRE PROVISIONAL:** `NODO-04: B2C Service Materialization & Provider Linkage Adapter`  
**NECESIDAD QUE RESUELVE:** Proyecta la oferta comercial y asignación operativa validada en SaaS hacia la tabla transaccional `public.services` y perfil de prestador `public.perfiles_prestador`, permitiendo que los servicios del salón sean reservados por clientes finales en el marketplace B2C.  
**EVIDENCIA ENCONTRADA:**
- PostgreSQL impone `public.services.provider_id INTEGER NOT NULL REFERENCES perfiles_prestador(id)`.
- `DEC-SE-001` declara que `SERVICE_OFFER` requiere materialización tardía hacia `public.services`.
- `DEC-AS-003` identifica las condiciones de elegibilidad pero mantiene el disparador en `ARCHITECTURAL STOP`.
**DEPENDENCIA QUE LO ORIGINA:**
- `NODO-02` (`service_offers` + `service_assignments`)
- `NODO-03A` (`staff_schedules`)
- B2C Marketplace (`public.services`, `public.perfiles_prestador`, `public.bookings`)
**PROBLEMA SI NO EXISTE:** La parametrización del salón en SaaS permanece como un silo interno sin conexión con la aplicación móvil de clientes ni con el motor transaccional de reservas de GlowApp.  
**RELACIÓN CON NODO-03A:** Consume el personal disponible y asignado para materializar la capacidad operativa real.  
**DECISIONES PENDIENTES:** Requiere resolver obligatoriamente `DEC-AS-003` (Disparador de materialización: manual vs automático vs onboarding) y la vinculación de `memberships` con `perfiles_prestador`.  
**¿PUEDE SER NODO INDEPENDIENTE?:** Sí. Es un adaptador downstream desacoplado.  
**¿DEBE SER EL SIGUIENTE NODO?:** **SÍ**, siempre que el Director resuelva previamente la decisión bloqueante `DEC-AS-003`.
<!-- slide -->
### CANDIDATO 2: SaaS Internal Appointment & Agenda Runtime (NODO-04B)
<!-- slide -->
**NOMBRE PROVISIONAL:** `NODO-04B: SaaS Internal Appointment & Agenda Runtime`  
**NECESIDAD QUE RESUELVE:** Provee al establecimiento (`HUB-SALON`) una agenda/calendario interno para crear, consultar, reagendar y cancelar citas operativas de clientes presenciales o telefónicos (walk-in) directamente en el cockpit SaaS.  
**EVIDENCIA ENCONTRADA:**
- `HUB-SALON` v1.0 proveyó resumen (`/summary`) y equipo (`/staff`), pero carece de vista de agenda.
- `staff_schedules` (NODO-03A), `service_assignments` (NODO-02) y `service_offers` (NODO-02) contienen todos los datos necesarios para calcular slots de atención disponibles.
**DEPENDENCIA QUE LO ORIGINA:**
- `NODO-02` (Duración y precio del servicio).
- `NODO-03A` (Horarios y turnos de atención del staff).
- `activeContext` (Aislamiento por sede y tenant).
**PROBLEMA SI NO EXISTE:** El administrador y los profesionales del salón no pueden gestionar su flujo de citas diarias dentro del SaaS.  
**RELACIÓN CON NODO-03A:** Consume directamente la disponibilidad semanal para la validación y reserva de franjas horarias.  
**DECISIONES PENDIENTES:** Modelo de clientes internos (walk-in vs cuentas B2C), estados de cita (`SCHEDULED`, `CONFIRMED`, `COMPLETED`, `CANCELLED`, `NO_SHOW`).  
**¿PUEDE SER NODO INDEPENDIENTE?:** Sí. Constituye un subsistema transaccional interno del SaaS.  
**¿DEBE SER EL SIGUIENTE NODO?:** Alternativa válida si el Director prefiere priorizar la autonomía del SaaS B2B antes de conectar con el marketplace B2C.
<!-- slide -->
### CANDIDATO 3: Staff Availability Exceptions & Date Overrides (NODO-03B)
<!-- slide -->
**NOMBRE PROVISIONAL:** `NODO-03B: Staff Availability Exceptions & Date Overrides`  
**NECESIDAD QUE RESUELVE:** Permite registrar bloqueos temporales por fecha específica, vacaciones, licencias médicas y días festivos para colaboradores, sobrepasando el template semanal recurrente de NODO-03A.  
**EVIDENCIA ENCONTRADA:**
- `N03A-DEC-06` declaró explícitamente: `EXCEPTIONS = OUT OF V1.0 SCOPE` y estableció que las excepciones por fecha específica se diferían.
**DEPENDENCIA QUE LO ORIGINA:**
- `NODO-03A` (`staff_schedules`, `memberships`).
**PROBLEMA SI NO EXISTE:** Los colaboradores son considerados disponibles todas las semanas del año de forma idéntica; no se pueden bloquear días concretos en el calendario.  
**RELACIÓN CON NODO-03A:** Extensión directa de la capa de disponibilidad.  
**DECISIONES PENDIENTES:** Modelo físico de excepciones (`specific_date`, tipo de bloqueo, validación contra agenda existente).  
**¿PUEDE SER NODO INDEPENDIENTE?:** Sí (subnodo de disponibilidad).  
**¿DEBE SER EL SIGUIENTE NODO?:** **NO PRIORITARIO**. La disponibilidad semanal base de NODO-03A es suficiente para desbloquear la materialización o el agendamiento básico.
```

---

## 5. COMPARACIÓN DE CANDIDATOS

| Criterio de Evaluación | Candidato 1: B2C Materialization | Candidato 2: SaaS Agenda Interna | Candidato 3: Excepciones de Staff |
|---|---|---|---|
| **Impacto en el Negocio** | **Máximo** (Habilita reservas reales B2C) | **Alto** (Operación interna del salón) | **Medio** (Refinamiento de disponibilidad) |
| **Alineación con la Cadena SaaS** | Natural (Conecta SaaS con Marketplace) | Natural (Extensión de Hub Salón) | Menor (Comportamiento de borde) |
| **Bloqueo de Decisiones Previas** | **SÍ** (`DEC-AS-003` en STOP 🛑) | **Bajo** (Requiere modelar Citas SaaS) | **Bajo** (Modelo sencillo de excepciones) |
| **Desacoplamiento Arquitectónico** | Total (Adaptador unidireccional) | Total (Entidad durable en SaaS) | Alto (Depende de NODO-03A) |
| **Economía de Desarrollo** | Alta eficiencia (Reutiliza B2C existente) | Media (Requiere nueva entidad `citas`) | Alta (Extensión puntual) |

---

## 6. EVALUACIÓN DE ECONOMÍA ARQUITECTÓNICA (ALCANCE / ARQUITECTURA / NECESIDAD / ECONOMÍA)

1. **¿Es realmente necesario ahora?**
   - El ecosistema SaaS ya configuró Sede, Miembros, Roles, Catálogo, Asignaciones y Horarios.
   - Si no se construye el puente hacia el agendamiento (sea materialización B2C o Agenda SaaS), el SaaS queda en un estado puramente administrativo sin retorno transaccional.
2. **¿Existe evidencia de dependencia?**
   - Sí. `public.bookings` (B2C) depende de `public.services`. A su vez, `public.services` no puede poblarse manualmente en salones SaaS sin romper la consistencia con `service_offers` y `service_assignments`.
3. **¿Puede esperar?**
   - El Candidato 3 (Excepciones) puede esperar sin riesgo operacional.
   - El Candidato 1 (Materialización) o Candidato 2 (Agenda Interna) representan el paso obligatorio para dar vida operativa al sistema.
4. **¿Crear este nodo obligaría a decidir temas no definidos?**
   - Para el **Candidato 1**, **SÍ**: Obliga a resolver `DEC-AS-003` (Trigger de Materialización). Por ello, el descubrimiento concluye que **el paso inmediato no es codificar el nodo, sino resolver la decisión directiva `DEC-AS-003`**.

---

## 7. ANÁLISIS DE DEPENDENCIAS

```text
================================================================================
ARBOL DE DEPENDENCIAS ARQUITECTÓNICAS:

              [ NODO-01: Handover Ingestion ]
                            │
                            ▼
              [ NODO-02: Catalog & Assignments ]
                            │
                            ▼
              [ NODO-03A: Staff Schedules ]
                            │
             ┌──────────────┴──────────────┐
             │                             │
             ▼                             ▼
    [ EJE 1: FRONTERA B2C ]        [ EJE 2: SAAS INTERNO ]
             │                             │
             ▼                             ▼
     RESOLVER DEC-AS-003          SaaS Internal Agenda
             │                      (Candidato 2)
             ▼
     NODO-04: B2C Adapter
       (Candidato 1)
================================================================================
```

---

## 8. RIESGOS IDENTIFICADOS

1. **Riesgo de Infracción de Frontera (SaaS vs B2C):** Intentar implementar materialización sin respetar que `public.services.provider_id` exige `perfiles_prestador(id)` causaría fallos de Foreign Key en PostgreSQL.
2. **Riesgo de Suposición de Disparador:** Implementar sincronización automática silenciosa violaría `DEC-SE-001` y el principio de explicitud.
3. **Riesgo de Regresión:** Mutar las tablas de Foundation o de B2C durante la materialización.

---

## 9. DECISIONES ARQUITECTÓNICAS PENDIENTES (BLOCKERS FORMALES)

### A. Bloqueador Principal: `DEC-AS-003` (Materialization Trigger)
- **Estado Actual:** `ARCHITECTURAL STOP 🛑`
- **Problema:** En el repositorio actual no existe un evento, endpoint ni comando formal de "Publicar Catálogo en B2C" ni de "Sincronización Automática".
- **Opciones para el Director:**
  - **Opción A (Disparo Manual / Comando Explícito):** Se define un endpoint en el Cockpit Hub Salón (`POST /api/v1/saas/hub/catalog/publish`) donde el `OWNER`/`MANAGER` decide cuándo materializar su catálogo asignado hacia B2C.
  - **Opción B (Disparo Automático Condicionado):** La materialización ocurre automáticamente en segundo plano cuando una asignación es creada Y el colaborador posee perfil de prestador B2C elegible.
  - **Opción C (Handover Onboarding Materialization):** La materialización ocurre al finalizar el asistente de onboarding si existen datos completos.

### B. Bloqueador Secundario: Vinculación de Identidad de Prestador
- **Problema:** Un colaborador en SaaS es una `membership` (`user_id` en `usuarios`). Para materializarse en `public.services` se requiere un `perfiles_prestador.id`.
- **Decisión:** ¿El sistema crea automáticamente un `perfiles_prestador` para los miembros de rol `PROFESSIONAL` al ser asignados, o se exige que el usuario lo tenga previamente?

---

## 10. RECOMENDACIÓN DEL SIGUIENTE NODO

```text
================================================================================
RECOMENDACIÓN ARQUITECTÓNICA FORMAL:

1. NO ABRIR IMPLEMENTACIÓN DIRECTA DE CÓDIGO TODAVÍA.

2. RUTA PRINCIPAL RECOMENDADA (CONVERGENCIA B2C):
   Paso 1: Emitir el GOAL directivo para resolver y cerrar formalmente DEC-AS-003
           (Resolución del Disparador de Materialización y Elegibilidad de Prestador).
   Paso 2: Con DEC-AS-003 cerrada, formular el Node Contract de:
           NODO-04 — DOWNSTREAM B2C MATERIALIZATION & ADAPTATION ADAPTER.

3. RUTA ALTERNATIVA (AUTONOMÍA SAAS PURA):
   Si el Director prefiere postergar la integración con el marketplace B2C:
   Formular el Node Contract de:
   NODO-04B — SAAS INTERNAL APPOINTMENT & AGENDA RUNTIME.
================================================================================
```

---

## 11. QUÉ NO DEBE HACERSE TODAVÍA

- **NO** implementar controladores de materialización ni endpoints de publicación.
- **NO** insertar filas en `public.services` ni mutar `public.perfiles_prestador`.
- **NO** modificar `service_offers`, `service_assignments` ni `staff_schedules`.
- **NO** asumir que la asignación publica automáticamente en B2C.
- **NO** crear tablas de citas ni alterar Foundation.
- **NO** modificar frontend.

---

## 12. RECOMENDACIÓN DE CIERRE DEL DISCOVERY

El proceso de descubrimiento arquitectónico ha identificado con precisión los candidatos, dependencias y bloqueos estructurales tras la ratificación de NODO-03A.

```text
================================================================================
  DISCOVERY STATUS: READY FOR DIRECTOR DECISION 🟡
  IMPLEMENTATION AUTHORIZATION: NOT GRANTED 🛑
================================================================================
```
