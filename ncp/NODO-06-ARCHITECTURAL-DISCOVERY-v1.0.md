# NODO-06 ARCHITECTURAL DISCOVERY v1.0
## Post NODO-05 Capability Analysis, Forensic Booking Audit & Next Node Discovery Report

================================================================================
PROJECT: GlowApp SaaS  
AUTHORITY: Director del Proyecto  
CORPUS / REPOSITORY: Diegoromerov/belleza-app  
WORKTREE: `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\database_audit_read_only`  
CLASSIFICATION: READ-ONLY ARCHITECTURAL DISCOVERY — ZERO IMPLEMENTATION  
BASELINE: NODO-05 CLOSED / IMPLEMENTED / VALIDATED / AUDITED (25/25 Tests, 155/155 Regression)  
DISCOVERY VERDICT: READY FOR SEMANTIC DEFINITION 🟢  
================================================================================

---

## 1. EXECUTIVE SUMMARY

Con la culminación, validación exhaustiva, auditoría de seguridad y cierre formal otorgado por el Director del Proyecto para **NODO-05 (Availability Projection & Booking Slot Engine)**, GlowApp SaaS cuenta con un motor computacional de proyección temporal en memoria, capaz de calcular de manera transitoria, determinista y bajo estricto aislamiento multi-tenant RLS la grilla de slots de agendamiento libres para cualquier oferta de servicio en cualquier fecha y sede.

El presente descubrimiento arquitectónico realiza una auditoría forense *read-only* sobre la totalidad del repositorio, analizando la brecha de capacidad (*Capability Gap*) existente entre la proyección matemática de disponibilidad y la operación transaccional real del SaaS.

### Conclusiones Principales del Discovery:
1. **[Naturaleza de NODO-05]** NODO-05 es un motor puramente **computacional, transitorio y de solo lectura**. No persiste slots, no adquiere bloqueos de concurrencia, no crea citas ni gestiona clientes.
2. **[La Brecha Central Post-NODO-05]** La proyección de slots por sí sola no constituye una operación de negocio. Para convertir un slot proyectado en una cita efectiva, el sistema requiere la capacidad de **capturar, persistir y gobernar citas operativas internas de sede (`SaaS Internal Appointments & Salon Agenda`)** o bien articular la **reserva desde el marketplace B2C**.
3. **[Hallazgo Forense sobre `public.bookings`]** La tabla física `public.bookings` es un modelo B2C legacy/marketplace orientado al prestador individual (`provider_id`), dependiente de usuarios registrados (`client_id`) y pasarelas de pago (Wompi), careciendo de `establishment_id`, soporte para clientes no registrados (walk-ins / telefónicos) y estados operacionales de cabina de salón (`CHECKED_IN`, `IN_SERVICE`, `NO_SHOW`).
4. **[Candidato Recomendado para NODO-06]** Se identifica como siguiente capacidad arquitectónica crítica e indispensable:
   $$\mathbf{NODO\text{-}06: \text{ SaaS Internal Appointments \& Operational Agenda Engine (Agenda y Citas Operativas de Sede)}}$$
   permitiendo al personal del salón (Recepcionista, Manager, Owner, Profesional) agendar citas directas/presenciales/telefónicas consumiendo los slots de NODO-05 y gestionando el ciclo de vida del servicio en salón.
5. **[Veredicto Formal]** **`READY FOR SEMANTIC DEFINITION`**. No existen bloqueadores insalvables que impidan la definición semántica, pero se formulan 3 decisiones arquitectónicas esenciales que deben someterse a la compuerta directiva (*Director Gate*).

---

## 2. CURRENT STATE AFTER NODO-05 (ESTADO FACTUAL DEL SISTEMA)

El sistema opera sobre una cadena de 6 capas arquitectónicas cerradas, inmutables y ratificadas:

```text
================================================================================
              FOTOGRAFÍA FACTUAL DE CAPAS CERRADAS (POST NODO-05)
================================================================================
  [CAPA 1: FUNDACIÓN MULTI-TENANT & RLS] 🔒
  ├── tenants (id, name, plan)
  ├── organizations (id, tenant_id, legal_name, tax_id)
  ├── establishments (id, tenant_id, organization_id, operating_hours JSONB)
  ├── memberships (id, tenant_id, establishment_id, user_id, role, status)
  └── usuarios (id, tenant_id, email, rol, is_active)

  [CAPA 2: RESOLUCIÓN CONTEXTUAL & ONBOARDING] 🔒
  ├── fn_resolve_user_tenant() (Stored Procedure PostgreSQL)
  ├── activeContextMiddleware (Inyección de req.tenantId, req.establishmentId)
  ├── HUB-SALON v1.0 (/summary, /staff)
  └── CREAR-DESDE-CERO v1.0 & NODO-01 (Ingestión neutral in-memory)

  [CAPA 3: CATÁLOGO LOCAL & ASIGNACIÓN SAAS (NODO-02)] 🔒
  ├── service_offers (id, tenant_id, establishment_id, name, base_duration, base_price)
  └── service_assignments (id, tenant_id, establishment_id, service_offer_id, membership_id)

  [CAPA 4: DISPONIBILIDAD OPERATIVA SEMANAL (NODO-03A)] 🔒
  └── staff_schedules (id, tenant_id, establishment_id, membership_id, day_of_week, start_time, end_time)

  [CAPA 5: ADAPTADOR DE MATERIALIZACIÓN DOWNSTREAM B2C (NODO-04)] 🔒
  ├── saas_service_materializations (id, tenant_id, establishment_id, service_offer_id, membership_id, service_id)
  └── Proyección hacia public.services(provider_id = user_id)

  [CAPA 6: MOTOR DE PROYECCIÓN DE DISPONIBILIDAD & SLOTS (NODO-05)] 🔒
  ├── nodo05AvailabilityService.projectAvailability()
  ├── Cálculo en memoria: (Operating Hours ∩ Staff Schedule) \ Active Bookings
  └── Modos TARGETED & AGGREGATED bajo zona horaria America/Bogota (UTC-5)

  [BATERÍA GLOBAL DE REGRESIÓN] 🔒
  └── 10 / 10 Suites Pass | 155 / 155 Tests Verdes (100% PASS)
================================================================================
```

---

## 3. NODO-05 BOUNDARY (FRONTERA Y ALCANCE DE NODO-05)

Para delimitar con exactitud el punto de partida de NODO-06, se documenta formalmente qué entrega y qué NO entrega NODO-05:

```text
  ┌────────────────────────────────────────────────────────────────────────┐
  │                           NODO-05 ENTRADA                              │
  │  (tenant_id, establishment_id, service_offer_id, target_date, ...)     │
  └───────────────────────────────────┬────────────────────────────────────┘
                                      │
                                      ▼
  ┌────────────────────────────────────────────────────────────────────────┐
  │                 AVAILABILITY PROJECTION ENGINE                         │
  │  1. Valida oferta y membresías activas asignadas                       │
  │  2. Obtiene horario de sede (operating_hours)                          │
  │  3. Obtiene turnos de colaboradores (staff_schedules)                  │
  │  4. Obtiene ocupaciones físicas (public.bookings)                      │
  │  5. Computa intersección y resta de intervalos                         │
  └───────────────────────────────────┬────────────────────────────────────┘
                                      │
                                      ▼
  ┌────────────────────────────────────────────────────────────────────────┐
  │                      NODO-05 SALIDA (TRANSIENT)                        │
  │  { slots: [ { start_time: "09:00", end_time: "09:45", ... } ] }       │
  └───────────────────────────────────┬────────────────────────────────────┘
                                      │
                                      ▼
  ┌────────────────────────────────────────────────────────────────────────┐
  │                        ¿QUÉ CAPACIDAD FALTA?                           │
  │  NODO-05 entrega una lista de strings de horas libres en memoria.      │
  │  NO PERSISTE, NO RESERVA, NO ASIGNA CLIENTE, NO GESTIONA AGENDA.       │
  └────────────────────────────────────────────────────────────────────────┘
```

### Lo que NODO-05 SÍ Entrega:
1. Proyección determinista de slots discretos para una fecha y oferta específica.
2. Modos dirigidos a colaborador (`TARGETED`) y agregados de salón (`AGGREGATED`).
3. Detección y exclusión de colisiones contra reservas activas (`public.bookings`).
4. Aislamiento estricto multi-tenant y multi-sede.

### Lo que NODO-05 NO Entrega (Non-Goals de NODO-05):
1. **Zero Persistencia de Slots**: No almacena slots en ninguna tabla.
2. **Zero Bloqueos de Concurrencia**: No reserva ni bloquea provisionalmente slots (*no reservation hold / lock*).
3. **Zero Creación de Citas**: No inserta registros en `bookings` ni en ninguna entidad transaccional.
4. **Zero Gestión de Clientes**: Desconoce datos del cliente (nombre, teléfono, notas, preferencias).
5. **Zero Vistas de Agenda**: No proporciona endpoints para visualizar la agenda diaria del salón (grilla de turnos/citas de todos los profesionales de la sede).
6. **Zero Máquina de Estados Operativa**: No gestiona check-in de clientes, inicio de servicio, término ni no-shows.

---

## 4. EXISTING BOOKING FORENSICS (AUDITORÍA FORENSE DE `public.bookings`)

Se realizó una inspección forense exhaustiva de la estructura física, controladores, modelos y rutas asociadas a `public.bookings` en el backend:

### 4.1. Esquema Físico de `public.bookings`:
```sql
-- DDL Físico en PostgreSQL:
CREATE TABLE public.bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id INTEGER NOT NULL REFERENCES public.usuarios(id) ON DELETE RESTRICT,
    provider_id INTEGER NOT NULL REFERENCES public.usuarios(id) ON DELETE RESTRICT,
    service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE RESTRICT,
    scheduled_at TIMESTAMPTZ NOT NULL,
    valor_bruto NUMERIC(10, 2) NOT NULL CHECK (valor_bruto >= 0),
    comision_plataforma NUMERIC(10, 2) DEFAULT 0.00,
    impuestos_estado NUMERIC(10, 2) DEFAULT 0.00,
    pago_neto_prestador NUMERIC(10, 2) DEFAULT 0.00,
    estado VARCHAR(50) DEFAULT 'PENDIENTE_PAGO',
    pin_verificacion VARCHAR(4),
    payment_status VARCHAR(20) DEFAULT 'unpaid',
    service_address TEXT,
    notes TEXT,
    tenant_id INTEGER NOT NULL REFERENCES public.tenants(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 4.2. Flujo y Controladores Existentes:
* **Creación B2C**: `POST /api/bookings` manejado por `backend/src/controllers/bookingController.js` (`createBooking`).
  - Asume autenticación B2C obligatoria (`req.user.id` asignado a `client_id`).
  - Requiere `provider_id` (`usuarios.id`), `service_id` (`public.services.id`), `scheduled_at`.
  - Calcula automáticamente comisión de plataforma (12%) e impuestos (8%) mediante trigger `calc_booking_split()`.
  - Integra validación de productos adicionales en stock y firma de webhooks Wompi (`verifyWompiSignature`).
* **Estados Existentes**: `'PENDIENTE'`, `'PENDIENTE_PAGO'`, `'CONFIRMADA'`, `'EN_PROCESO'`, `'COMPLETADA'`, `'CANCELADA'`, `'RECHAZADA'`.
* **Modificación de Estado**:
  - `PATCH /api/bookings/:id/status` (Aceptación/rechazo por prestador individual).
  - `PATCH /api/bookings/:id/cancel` (Cancelación por cliente o prestador).
  - `POST /api/bookings/:id/pay` & `POST /payments/wompi-webhook` (Transición financiera Wompi).
  - `PATCH /api/bookings/:id/start` (Inicio con PIN de verificación de 4 dígitos).

### 4.3. Hallazgos Forenses y Limitaciones para SaaS:
1. **Ausencia de `establishment_id`**: `public.bookings` no tiene noción de sede física ni organización SaaS. El vínculo es estrictamente B2C punto a punto: `Usuario Cliente <-> Usuario Prestador`.
2. **Dependencia de Usuario Registrado (`client_id NOT NULL`)**: Requiere que todo cliente tenga una cuenta creada en `public.usuarios` con email y contraseña. Esto **invalida la operación de salón** donde clientes walk-in o llamadas telefónicas no tienen (ni requieren) cuenta en la app B2C.
3. **Dependencia de `public.services` (Materializado)**: Requiere `service_id` de la tabla B2C, lo que obligaría a materializar previamente toda oferta para poder agendarla internamente en el salón.
4. **Acoplamiento Fintech Inmediato**: Todo `INSERT` en `public.bookings` dispara triggers de comisiones B2C (20% split) y campos Wompi, incompatibles con cobros directos en caja/datáfono de salón SaaS.
5. **Estados Orientados a Marketplace**: Carece de estados indispensables de gestión de cabina (`CHECKED_IN` / cliente en sala de espera, `NO_SHOW` / cliente no se presentó).

---

## 5. CAPABILITY GAP (ANÁLISIS DE BRECHA DE CAPACIDAD)

El cruce entre lo que NODO-05 entrega y las necesidades operativas de GlowApp revela **3 grandes vacíos de capacidad**:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                           CAPABILITY GAP MAP                                │
├─────────────────────────────────────────────────────────────────────────────┤
│ GAP 1: Inexistencia de Agenda Operativa de Sede (SaaS Salon Agenda View)    │
│        El salón (Owner, Manager, Recepcionista, Profesional) no tiene un    │
│        endpoint para consultar la grilla diaria de citas de la sede,        │
│        organizada por colaborador, franjas y estados.                       │
├─────────────────────────────────────────────────────────────────────────────┤
│ GAP 2: Imposibilidad de Agendamiento Interno (SaaS Internal Appointments)  │
│        No existe un mecanismo para crear citas presenciales, telefónicas    │
│        o directas en el salón, asociadas a una sede y oferta SaaS,          │
│        admitiendo clientes invitados (Walk-in / Guest Customers).           │
├─────────────────────────────────────────────────────────────────────────────┤
│ GAP 3: Desconexión del Checkout B2C con el Motor NODO-05                    │
│        El endpoint B2C legacy `POST /api/bookings` no valida disponibilidad │
│        contra el motor NODO-05, permitiendo potenciales colisiones si       │
│        un cliente B2C agenda en horarios fuera de turno de sede.            │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. CANDIDATE NEXT NODES (EVALUACIÓN DE CANDIDATOS)

Se evalúan 5 candidatos potenciales para constituir el siguiente hito arquitectónico:

---

### Candidato A: NODO-06 — SaaS Internal Appointments & Operational Agenda Engine
* **Problema que Resuelve**: Permite al personal del salón (Recepcionista, Manager, Owner, Profesional) visualizar la agenda operativa diaria/semanal de la sede y crear/gestionar citas internas (walk-in, telefónicas, citas directas) utilizando los slots proyectados por NODO-05.
* **Dependencia con NODO-05**: **CONSUMIDOR DIRECTO**. Utiliza la proyección de NODO-05 para validar que la cita interna no colisione con el horario de sede, turno del personal ni otras citas existentes. Al crearse, la cita pasa a ser una ocupación física que NODO-05 restará en futuras proyecciones.
* **Inputs**:
  - `activeContext` (`tenantId`, `establishmentId`, `membershipId`, `role`).
  - Consulta de agenda: `target_date`, `membership_id?`.
  - Creación de cita interna: `service_offer_id`, `membership_id`, `scheduled_at`, `client_name`, `client_phone`, `notes`.
* **Outputs**:
  - Vista de agenda diaria consolidada por sede/profesionales.
  - Entidad transaccional de cita operativa interna con ciclo de vida de salón (`SCHEDULED`, `CONFIRMED`, `CHECKED_IN`, `IN_SERVICE`, `COMPLETED`, `CANCELLED`, `NO_SHOW`).
* **Nuevos Componentes Físicos Tentativos**:
  - Nueva tabla física `saas_appointments` (aislada bajo `tenant_id`, `establishment_id`, `membership_id`, `service_offer_id`).
  - Rutas bajo `/api/v1/saas/hub/agenda` y `/api/v1/saas/hub/appointments`.
* **Riesgos**: Decidir el modelo de cliente para walk-ins (guest client) y asegurar que NODO-05 reste tanto `public.bookings` (B2C) como `saas_appointments` (SaaS) sin duplicidad.
* **Madurez de Definición**: **ALTA**. Resuelve directamente la operación primaria del software de gestión de salón.

---

### Candidato B: Booking Lifecycle & Unified Fintech Orchestration
* **Problema que Resuelve**: Estandariza la máquina de estados, pasarelas de pago, split de comisiones, facturación electrónica y webhooks para reservas.
* **Dependencia con NODO-05**: Secundaria (opera aguas abajo de la reserva).
* **Evaluación**: **PREMATURO**. Intentar formalizar la orquestación financiera y checkout unificado antes de que el salón pueda siquiera registrar una cita en su agenda generaría un acoplamiento indebido (*premature bundling*) entre SaaS B2B y Fintech B2C.

---

### Candidato C: B2C Marketplace Booking Consumption Adapter
* **Problema que Resuelve**: Conecta el flujo de reserva del cliente en la app móvil B2C con el motor NODO-05, forzando a que `POST /api/bookings` valide disponibilidad a través de `nodo05AvailabilityService`.
* **Dependencia con NODO-05**: Consumidor directo del motor.
* **Evaluación**: **DIFERIBLE / SECUNDARIO**. El marketplace B2C ya posee un endpoint funcional `POST /api/bookings` que opera con servicios materializados (NODO-04). Conectar la validación de slots B2C es trivial una vez que el modelo de ocupación unificada esté claro, pero no resuelve la necesidad operativa del salón SaaS.

---

### Candidato D: NODO-03B — Schedule Exceptions & Operational Overrides
* **Problema que Resuelve**: Permite registrar excepciones no recurrentes a los horarios de trabajo (festivos, incapacidades, vacaciones, bloqueos temporales de agenda, mantenimiento de sede).
* **Dependencia con NODO-05**: Entrada de filtrado adicional para NODO-05.
* **Evaluación**: **COMPLEMENTARIO / DIFERIBLE**. Es una optimización declarativa de disponibilidad. NODO-05 ya opera con éxito intersectando horarios regulares semanales y reservas existentes. La ausencia de excepciones no bloquea la creación de citas (un bloqueo manual puede registrarse como cita de bloqueo o gestionarse operativamente).

---

### Candidato E: SaaS Reservation Intent & Concurrency Lock Engine
* **Problema que Resuelve**: Adquiere un bloqueo transitorio con tiempo de expiración (TTL de 10 min en Redis o tabla temporal) para retener un slot mientras el cliente completa el pago.
* **Dependencia con NODO-05**: Capa intermedia entre proyección y confirmación.
* **Evaluación**: **PREMATURO**. En citas de salón SaaS (agendamiento presencial/telefónico), el bloqueo por TTL no es requerido (la recepcionista confirma inmediatamente la cita). En B2C, la concurrencia actual no justifica la sobrecarga de un motor de locks distribuido en esta etapa.

---

## 7. DEPENDENCY & FEASIBILITY MATRIX

| Criterio de Evaluación | Candidato A (Agenda & Citas SaaS) | Candidato B (Fintech Lifecycle) | Candidato C (B2C Consumption) | Candidato D (Schedule Exceptions) | Candidato E (Lock Engine) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Desbloqueo Operativo Inmediato** | **MÁXIMO (SaaS Operativo)** | Medio | Medio | Bajo | Bajo |
| **Consumo Directo de NODO-05** | **SÍ (Verificación de slots)** | No (Post-booking) | SÍ (Slots B2C) | SÍ (Filtro previo) | SÍ (Intermedio) |
| **Independencia de Nodos Cerrados** | **ALTA (No muta 01-05)** | Baja (Toca Fintech) | Media (Toca B2C) | Alta | Media |
| **Riesgo de Bundling Prematuro** | **BAJO (Aislado en B2B)** | ALTO (Mezcla pagos) | Medio | Bajo | Medio |
| **Complejidad de Implementación** | **MODERADA** | Alta | Baja | Moderada | Alta |
| **Recomendación Arquitectónica** | **RECOMENDADO (NODO-06)** | Descartar para N06 | Postergar a N07 | Postergar a N08 | Descartar por ahora |

---

## 8. ARCHITECTURAL RISKS IDENTIFIED

1. **Riesgo de Identidad del Cliente en Salón (Guest vs User)**:
   - *Riesgo*: Forzar a que todo cliente atendido en el salón sea un usuario de `public.usuarios` rompería la usabilidad de la recepcionista para registrar clientes casuales o llamadas telefónicas.
   - *Mitigación*: Diseñar la entidad de citas SaaS con soporte nativo para clientes invitados (`client_name`, `client_phone`, `client_email`) con enlace opcional a `customer_id` / `user_id`.
2. **Riesgo de Doble Carril de Ocupación Física (Dual-Lane Collision)**:
   - *Riesgo*: Si las citas internas se guardan en una tabla nueva (`saas_appointments`) y las reservas B2C en `public.bookings`, NODO-05 debe restar ambas fuentes de ocupación para el profesional sin degradación de rendimiento.
   - *Mitigación*: NODO-05 fue diseñado para restar intervalos de tiempo sobre `provider_id / user_id`. La consulta de ocupación de NODO-05 puede federar limpiamente ambas fuentes dentro del mismo rango de fecha.
3. **Riesgo de Acoplamiento con Facturación y Caja**:
   - *Riesgo*: Querer implementar el cobro, caja registradora, propinas y facturación dentro de la cita en NODO-06.
   - *Mitigación*: Regla estricta de no-bundling: NODO-06 debe gobernar la **agenda y estado de la cita operativa**; el módulo de cobro y caja pertenecerá a una capa downstream posterior.

---

## 9. RECOMMENDED NEXT NODE: NODO-06

Se recomienda formalmente al Director del Proyecto la adopción de:

$$\mathbf{NODO	ext{-}06: 	ext{ SaaS Internal Appointments \& Operational Agenda Engine}}$$

### Propósito Arquitectónico:
Dotar a GlowApp SaaS de la capacidad operativa para que el personal de la sede (Owner, Manager, Recepcionista, Profesional) pueda:
1. **Consultar la Agenda Diaria de Sede (`GET /api/v1/saas/hub/agenda`)**: Vista estructurada de la jornada por profesional con sus citas asignadas, turnos y slots libres.
2. **Crear Citas Operativas Internas (`POST /api/v1/saas/hub/appointments`)**: Agendamiento validado contra NODO-05 para ofertas de servicio SaaS y colaboradores asignados, admitiendo clientes registrados y clientes invitados.
3. **Gobernar el Ciclo de Vida en Cabina (`PATCH /api/v1/saas/hub/appointments/:id/status`)**: Transiciones de estado operacionales (`SCHEDULED` $	o$ `CONFIRMED` $	o$ `CHECKED_IN` $	o$ `IN_SERVICE` $	o$ `COMPLETED` / `CANCELLED` / `NO_SHOW`).

---

## 10. DECISIONS REQUIRED FOR DIRECTOR GATE

Se presentan las 3 decisiones arquitectónicas estructurales que requieren dictamen en el *Semantic Decision Bundle*:

### DECISIÓN 1: Modelo Físico de Persistencia de Citas de Salón
* **PROBLEMA**: ¿Dónde deben persistirse las citas operativas creadas internamente en el salón SaaS?
* **EVIDENCIA**: `public.bookings` carece de `establishment_id`, exige `client_id NOT NULL` a `usuarios.id` y dispara triggers financieros B2C (20% split).
* **IMPACTO**: Modificar `public.bookings` violaría la estabilidad de los módulos B2C cerrados y mezclaría semántica de marketplace con SaaS.
* **OPCIONES**:
  - *Opción 1.A*: Crear tabla física dedicada `saas_appointments` con RLS y claves compuestas `(tenant_id, establishment_id, membership_id, service_offer_id)`.
  - *Opción 1.B*: Alterar `public.bookings` añadiendo `establishment_id` opcional y flexibilizando constraints.
* **RECOMENDACIÓN**: **Opción 1.A** (Tabla dedicada `saas_appointments`). Preserva la inmutabilidad de `bookings` B2C y garantiza aislamiento multi-tenant limpio.
* **DECISIÓN REQUERIDA**: Autorizar la creación de `saas_appointments` para NODO-06.

---

### DECISIÓN 2: Modelo de Identidad del Cliente de Salón (Guest vs Registered)
* **PROBLEMA**: ¿Cómo debe identificarse el cliente atendido en una cita interna de salón?
* **EVIDENCIA**: En peluquerías y salones, el 60-80% de reservas iniciales ocurren por teléfono o presenciales sin que el cliente posea una cuenta en la app móvil.
* **IMPACTO**: Exigir cuenta en `usuarios` impediría el registro ágil en recepción.
* **OPCIONES**:
  - *Opción 2.A*: Soporte dual: Datos planos de invitado (`guest_name`, `guest_phone`, `guest_email`) con campo opcional `user_id` para clientes vinculados.
  - *Opción 2.B*: Creación automática silenciosa de usuario en `usuarios` para cada cliente de salón.
* **RECOMENDACIÓN**: **Opción 2.A** (Soporte dual directo sin creación de usuarios fantasma).
* **DECISIÓN REQUERIDA**: Ratificar el modelo de cliente invitado en citas de salón.

---

### DECISIÓN 3: Política de Ocupación Cruzada en NODO-05
* **PROBLEMA**: ¿Cómo debe reflejarse una cita interna de `saas_appointments` en el cálculo de disponibilidad de NODO-05?
* **EVIDENCIA**: NODO-05 consulta `public.bookings` para restar colisiones del `provider_id`.
* **IMPACTO**: Si un profesional tiene una cita interna en el salón a las 10:00 AM, NODO-05 debe bloquear automáticamente ese slot tanto para la agenda interna como para el marketplace B2C.
* **OPCIONES**:
  - *Opción 3.A*: Integrar en NODO-05 la lectura de `saas_appointments` activas (`status NOT IN ('CANCELLED', 'NO_SHOW')`) junto con `public.bookings`.
  - *Opción 3.B*: Mantener NODO-05 sin cambios y sincronizar citas mediante una vista o réplica.
* **RECOMENDACIÓN**: **Opción 3.A** (Consulta federada de ocupación en NODO-05 respetando el principio de ocupación física unificada del profesional).
* **DECISIÓN REQUERIDA**: Ratificar la inclusión de `saas_appointments` en el lector de ocupación de NODO-05.

---

## 11. EXPLICIT NON-GOALS (LÍMITES ESTRICTOS DE NODO-06)

Para evitar desvíos o *scope creep*, se declaran como NO-OBJETIVOS explícitos de NODO-06:
1. **NO Checkout ni Pasarela de Pagos**: No incluye cobro con Wompi, datáfono, efectivo ni links de pago.
2. **NO Facturación Electrónica / POS**: No incluye emisión de facturas DIAN ni gestión de caja registradora.
3. **NO Sistema de Comisiones ni Nómina**: No incluye cálculo de liquidación ni pago de comisiones al profesional.
4. **NO Notificaciones Push / WhatsApp**: No incluye envío de recordatorios automáticos (pertenecerá a NODO de comunicaciones).
5. **NO Rediseño de B2C Marketplace**: No altera el funcionamiento del checkout de clientes en la app B2C.

---

## 12. READ-ONLY EVIDENCE INVENTORY

Archivos y componentes físicos inspeccionados como evidencia para este descubrimiento:

| Componente / Archivo | Tipo | Observación Factual |
| :--- | :--- | :--- |
| `backend/init.sql` | DDL | Definición de `public.bookings`, `services`, `usuarios`. |
| `backend/migrations/065_070` | DDL | Núcleo SaaS Foundation, Contexto, Ofertas, Asignaciones, Horarios y Materializaciones. |
| `backend/src/controllers/bookingController.js` | Runtime | Lógica transaccional B2C de `public.bookings` (Wompi, split 20%, client_id auth). |
| `backend/src/routes/bookingRoutes.js` | Routing | 8 endpoints B2C existentes montados en `/api/bookings`. |
| `backend/src/services/nodo05AvailabilityService.js` | Runtime | Motor de proyección de slots en memoria (25 pruebas verdes). |
| `backend/src/controllers/hubSalonController.js` | Runtime | Endpoints de resumen de salón y colaboradores. |
| `ncp/NODO-05-NODE-CONTRACT-v1.0.md` | Contrato | Contrato canónico cerrado de proyección de disponibilidad. |

---

## 13. DISCOVERY VERDICT

```
================================================================================
                    VEREDICTO FINAL DE DISCOVERY NODO-06
================================================================================
ESTADO: READY FOR SEMANTIC DEFINITION 🟢
CANDIDATO RECOMENDADO: NODO-06 — SAAS INTERNAL APPOINTMENTS & OPERATIONAL AGENDA
BLOQUEADORES CRÍTICOS: CERO BLOQUEADORES FÍSICOS
DECISIONES DIRECTIVAS: 3 DECISIONES FORMULADAS (PERSISTENCIA, GUEST CLIENT, OCUPACIÓN)
PRÓXIMO PASO FORMAL: DIRECTOR GATE → NODO-06 SEMANTIC DECISION BUNDLE v1.0
================================================================================
```
