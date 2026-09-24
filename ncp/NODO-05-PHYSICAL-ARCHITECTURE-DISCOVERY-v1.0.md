# NODO-05 — PHYSICAL ARCHITECTURE DISCOVERY v1.0 (RECONCILED)
## Availability Projection & Booking Slot Engine — Minimum Physical Architecture & Execution Pipeline

**DOCUMENT IDENTIFIER:** `NODO-05-PHYSICAL-ARCHITECTURE-DISCOVERY-v1.0`  
**STATUS:** `PHYSICAL ARCHITECTURE READY FOR DIRECTOR APPROVAL 🟡`  
**DATE:** 2026-09-11  
**ROLE:** Senior Physical Architecture & Infrastructure Auditor  
**AUTORIDAD RAÍZ:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `GOAL — NODO-05 PHYSICAL ARCHITECTURE DISCOVERY RECONCILIATION v1.1`  
**CONTRATO BASE APROBADO:** [`/ncp/NODO-05-NODE-CONTRACT-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NODO-05-NODE-CONTRACT-v1.0.md)  
**DECISION BUNDLE RATIFICADO:** [`/ncp/NODO-05-SEMANTIC-DECISION-BUNDLE-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NODO-05-SEMANTIC-DECISION-BUNDLE-v1.0.md)  
**CLASSIFICATION:** READ-ONLY PHYSICAL ARCHITECTURE DISCOVERY — ZERO IMPLEMENTATION / ZERO DDL  
**METHODOLOGY:** DEFINIR → RELACIONAR → INTEGRAR → VALIDAR → CERRAR → AVANZAR  
**IMPLEMENTATION AUTHORIZATION:** NOT GRANTED 🛑 (Discovery Only — Requires Implementation Contract & Director Authorization)

---

## 1. EXECUTIVE SUMMARY

El presente informe establece el **descubrimiento de arquitectura física mínima** requerida para implementar `NODO-05` (Availability Projection & Booking Slot Engine), conforme a su Contrato de Nodo formalmente cerrado.

### Hallazgos Físicos Principales:
1. **[ARQUITECTURA FÍSICA SELECCIONADA: OPCIÓN A (PURE APPLICATION-SERVICE COMPUTATION)]**  
   `NODO-05` no requiere nuevas tablas, nuevas columnas ni funciones almacenadas complejas en PostgreSQL. Se estructura técnicamente como un **servicio de aplicación en Node.js de solo lectura**, que realiza consultas SQL a las tablas ya existentes (`065`, `067`, `068`, `069` y `public.bookings`) y ejecuta el álgebra de intervalos temporales (intersección, discretización en `step_minutes` y sustracción de colisiones) **100% en memoria**.
2. **[CERO MIGRACIONES / CERO DDL]**  
   Todas las estructuras físicas necesarias existen en PostgreSQL. Se ratifica: **0 tablas nuevas, 0 columnas nuevas y 0 migraciones SQL**.
3. **[AISLAMIENTO Y SEGURIDAD RLS]**  
   Toda lectura se ejecuta bajo `activeContextMiddleware` y contexto transaccional RLS (`SET LOCAL app.tenant_id = :tenant_id`), garantizando que jamás se mezclen datos de diferentes sedes o tenants.
4. **[POLÍTICA DE ZONA HORARIA — OPEN / DIRECTOR DECISION REQUIRED]**  
   Se identificó que el código existente (`bookingController.js` L116 y Dockerfile) opera de facto bajo `America/Bogota` (UTC-5), pero no existe una columna de zona horaria en `establishments` ni una decisión formalizada que la sancione como invariante multiplataforma. Queda formalmente como **OPEN / DIRECTOR DECISION REQUIRED**.
5. **[TRANSPORTE Y RUTAS — PROPOSAL NOT APPROVED]**  
   Cualquier ruta, método HTTP o controlador mencionado en este informe constituye exclusivamente una **propuesta técnica de integración no aprobada**, cuya definición formal corresponde privativamente al Implementation Contract.
6. **[DICTAMEN FINAL]** `PHYSICAL ARCHITECTURE READY FOR DIRECTOR APPROVAL 🟡`.

---

## 2. PHYSICAL BASELINE (LÍNEA BASE FÍSICA POST-NODO-04)

```text
================================================================================
                    LÍNEA BASE FÍSICA RATIFICADA EN POSTGRESQL
================================================================================
  1. [065] FOUNDATION:     public.tenants (id SERIAL PRIMARY KEY)
                           public.establishments (id UUID, tenant_id INT, operating_hours JSONB)
                           public.memberships (id UUID, tenant_id INT, establishment_id UUID, user_id INT, status)
  2. [066] RESOLUTION:     public.fn_resolve_user_tenant() & activeContextMiddleware
  3. [067] SERVICE OFFERS: public.service_offers (id UUID, tenant_id INT, establishment_id UUID, base_duration INT)
  4. [068] ASSIGNMENTS:    public.service_assignments (id UUID, tenant_id INT, establishment_id UUID, service_offer_id UUID, membership_id UUID)
  5. [069] STAFF SCHEDULE: public.staff_schedules (id UUID, tenant_id INT, establishment_id UUID, membership_id UUID, day_of_week SMALLINT, start_time TIME, end_time TIME)
  6. [070] MATERIALIZATION:public.saas_service_materializations (id UUID, tenant_id INT, establishment_id UUID, service_offer_id UUID, membership_id UUID, service_id UUID)
  7. [PRE-N01] BOOKINGS:   public.bookings (id UUID, provider_id INT, service_id UUID, scheduled_at TIMESTAMPTZ, estado USER-DEFINED, tenant_id INT)
================================================================================
```

---

## 3. ACTIVE CONTEXT INTEGRATION (INTEGRACIÓN CON CONTEXTO ACTIVO)

`NODO-05` se integra directamente con el subsistema `activeContextMiddleware` cerrado en `NODO-01`:

```text
HTTP Request (GET)
  ├── Header: Authorization: Bearer <JWT>
  ├── Header: x-establishment-id: <UUID> (Opcional si es unitenant)
  ▼
activeContextMiddleware
  ├── Valida JWT y resuelve usuario (req.user.id)
  ├── Invoca fn_resolve_user_tenant(user_id, establishment_id)
  ├── Inyecta en req:
  │     ├── req.tenantId (INTEGER)
  │     ├── req.establishmentId (UUID)
  │     ├── req.membershipId (UUID)
  │     └── req.activeContext (Role, Relation, Status)
  ▼
Nodo 05 Controller / Service (Propuesto)
```

- **Invariante:** `NODO-05` **NUNCA** lee `tenant_id` de los query parameters del cliente. El tenant es resuelto exclusivamente del lado del servidor.

---

## 4. SERVICE OFFER PHYSICAL SOURCE (FUENTE FÍSICA DE OFERTA)

- **Tabla:** `public.service_offers` (Migración `067_service_offers.sql`).
- **Columnas Requeridas:** `id`, `name`, `base_duration`, `establishment_id`, `tenant_id`.
- **Integridad:** `CONSTRAINT chk_service_offers_duration CHECK (base_duration > 0)`.
- **Patrón de Lectura SQL:**
  ```sql
  SELECT id, name, base_duration 
  FROM service_offers 
  WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3;
  ```

---

## 5. SERVICE ASSIGNMENT PHYSICAL SOURCE (FUENTE FÍSICA DE ASIGNACIONES)

- **Tabla:** `public.service_assignments` (Migración `068_service_assignments.sql`).
- **Columnas Requeridas:** `service_offer_id`, `membership_id`, `establishment_id`, `tenant_id`.
- **Integridad Referencial:** Claves foráneas compuestas triples a `service_offers` y `memberships`.
- **Patrón de Lectura SQL (con filtro de membresía activa):**
  ```sql
  SELECT sa.membership_id, m.user_id, u.nombre AS staff_name
  FROM service_assignments sa
  JOIN memberships m ON sa.membership_id = m.id 
                     AND sa.establishment_id = m.establishment_id 
                     AND sa.tenant_id = m.tenant_id
  JOIN usuarios u ON m.user_id = u.id
  WHERE sa.service_offer_id = $1 
    AND sa.establishment_id = $2 
    AND sa.tenant_id = $3 
    AND m.status = 'ACTIVE';
  ```

---

## 6. STAFF SCHEDULE PHYSICAL SOURCE (FUENTE FÍSICA DE HORARIOS DE PERSONAL)

- **Tabla:** `public.staff_schedules` (Migración `069_staff_schedules.sql`).
- **Columnas Requeridas:** `membership_id`, `day_of_week`, `start_time`, `end_time`.
- **Mapeo de Fecha a Día de la Semana:**
  - `target_date` (`YYYY-MM-DD`) se mapea en JavaScript/PostgreSQL al rango $1..7$ ($1 = \text{Lunes}, \dots, 7 = \text{Domingo}$).
- **Patrón de Lectura SQL:**
  ```sql
  SELECT membership_id, start_time, end_time 
  FROM staff_schedules 
  WHERE establishment_id = $1 
    AND tenant_id = $2 
    AND day_of_week = $3 
    AND membership_id = ANY($4::uuid[])
  ORDER BY start_time ASC;
  ```

---

## 7. ESTABLISHMENT HOURS PHYSICAL SOURCE (FUENTE FÍSICA DE HORARIOS DE SEDE)

### 7.1. Hechos Fácticos en Base de Datos y Código (FACT)
- **Tabla:** `public.establishments` (Migración `065_saas_foundation_core.sql`).
- **Columna:** `operating_hours JSONB NOT NULL DEFAULT '{}'::jsonb`.
- **Estructura Factual Demostrada en `staffAvailabilityService.js` (L142-182):**
  - Soporta llaves de día en inglés (`"monday"`, `"tuesday"`) y español (`"lunes"`, `"martes"`).
  - Flags de estado activo: `is_open: true`, `activo: true`, `active: true`.
  - Formato de horas numéricas (`inicio: 8, fin: 18`) o strings (`start_time: "08:00", end_time: "18:00"`).

### 7.2. Consumo Propuesto en NODO-05 (PROPOSAL — NOT APPROVED)
- `NODO-05` utiliza el parser polimórfico existente para extraer la ventana comercial $[E_{\text{start}}, E_{\text{end}}]$ del día de la semana correspondiente.
- Si el día está marcado como no activo (`is_open = false`), la ventana comercial es nula y no se generan slots.

---

## 8. BOOKING OCCUPANCY PHYSICAL SOURCE (FUENTE FÍSICA DE OCUPACIÓN)

- **Tabla:** `public.bookings` (Pre-Nodo 01).
- **Columnas Requeridas:** `provider_id`, `scheduled_at`, `estado`, `service_id`.
- **Derivación de Duración:** Se resuelve vía `LEFT JOIN services s ON b.service_id = s.id` (o fallback a `service_offers.base_duration` vía `saas_service_materializations`).
- **Patrón de Lectura SQL (Solo Lectura):**
  ```sql
  SELECT b.provider_id, b.scheduled_at, COALESCE(s.duration_minutes, so.base_duration, 60) AS duration_minutes
  FROM bookings b
  LEFT JOIN services s ON b.service_id = s.id
  LEFT JOIN saas_service_materializations mat ON b.service_id = mat.service_id
  LEFT JOIN service_offers so ON mat.service_offer_id = so.id
  WHERE b.provider_id = ANY($1::int[])
    AND b.estado != 'CANCELADA'
    AND b.scheduled_at >= $2::timestamptz 
    AND b.scheduled_at < $3::timestamptz;
  ```

---

## 9. MEMBERSHIP / PROVIDER RESOLUTION (RESOLUCIÓN DE IDENTIDAD)

- **Invariante Ratificado en NODO-04:**
  $$\text{memberships.user\_id} \equiv \text{usuarios.id} \equiv \text{perfiles\_prestador.id}$$
- **Mapeo Físico:**
  - Al consultar `service_assignments` $\to$ `memberships`, se obtiene `m.user_id`.
  - El array de `user_ids` se pasa como filtro `b.provider_id = ANY($1::int[])` a `public.bookings`.
  - **Cero tablas intermedias ni nuevos mapeos requeridos.**

---

## 10. TENANT / RLS ISOLATION (AISLAMIENTO MULTI-TENANT)

1. El acceso a las tablas SaaS (`service_offers`, `service_assignments`, `staff_schedules`, `establishments`, `memberships`) está estrictamente protegido por PostgreSQL Row-Level Security (RLS).
2. El cliente de base de datos ejecuta:
   ```sql
   SET LOCAL app.tenant_id = :tenant_id;
   ```
3. Ninguna consulta puede retornar filas de otros tenants.

---

## 11. QUERY ARCHITECTURE (ARQUITECTURA DE CONSULTAS)

### 11.1. Agrupación Propuesta de Consultas (PROPOSED QUERY GROUPING — NOT APPROVED)

Se propone técnicamente una agrupación en 2 consultas para optimizar la latencia y carga de base de datos:

1. **Consulta 1 (Metadatos SaaS):** Obtener `service_offer` + `service_assignments` activos + `operating_hours` del establecimiento.
2. **Consulta 2 (Horarios & Citas Ocupadas):** Obtener `staff_schedules` del día para las membresías asignadas + `bookings` activas para los `user_ids` correspondientes.

> [!NOTE]
> La cantidad de consultas SQL constituye una **propuesta de optimización técnica**, no un invariante arquitectónico vinculante. El runtime final podrá ejecutar 1, 2 o más consultas siempre que se preserven el aislamiento RLS y el determinismo.

---

## 12. COMPUTATION LOCATION: SQL vs APPLICATION (UBICACIÓN DEL CÁLCULO)

Se evaluó dónde debe residir el álgebra de intervalos:

| Criterio | Opción 1: Puro SQL / PlPgSQL | Opción 2: Puro JavaScript (Node.js Service) [PROPUESTA TÉCNICA] |
| :--- | :--- | :--- |
| **Complejidad de Mantenimiento** | Alta (Funciones SQL complejas, difícil debugging) | **Baja (Funciones puras, testeable con unit tests simples)** |
| **Portabilidad y Testabilidad** | Requiere DB activa para cada test unitario | **100% testeable sin base de datos (Unit Test in-memory)** |
| **Carga en Base de Datos** | Mayor consumo de CPU en PostgreSQL | **Descarga de CPU de DB; cálculo trivial en Node.js (< 1 ms)** |
| **Volumen de Datos Transferidos** | Mínimo | **Idéntico (solo 5-20 filas transferidas)** |
| **Dictamen** | No Recomendado | **PROPUESTA TÉCNICA RECOMENDADA: Opción 2 🟢** |

---

## 13. INTERVAL MODEL (MODELO DE INTERVALOS Y COLISIÓN)

### 13.1. Evidencia Factual en el Repositorio (FACT)
En `backend/src/controllers/bookingController.js` (L144), la validación de colisiones de citas utiliza desigualdades estrictas:
```javascript
if (newStart.getTime() < bEnd.getTime() && newEnd.getTime() > bStart.getTime())
```
Y en `backend/src/services/staffAvailabilityService.js` (L125):
```javascript
if (next.start_min < current.end_min)
```

### 13.2. Evaluación de Semántica de Intervalos
- **Factualidad Demostrada:** La desigualdad estricta implica matemáticamente un **modelo de intervalos semi-abiertos $[t_{\text{start}}, t_{\text{end}})$**:
  - Si una cita termina a las `10:00` ($b_{\text{end}} = 10:00$) y otra cita inicia a las `10:00` ($newStart = 10:00$), $newStart < b_{\text{end}}$ evalúa como `false` (NO colisiona).
  - Esto permite citas contiguas (*back-to-back*) exactas.
- **Estado:** `SUPPORTED BY CODE EVIDENCE — SUBJECT TO DIRECTOR RATIFICATION 🟡`.

---

## 14. TEMPORAL / TIMEZONE ANALYSIS

### 14.1. Evidencia Factual en el Repositorio (FACT)
1. **Dockerfile (L4):** `ENV TZ=America/Bogota`.
2. **`bookingController.js` (L116-121):**
   ```javascript
   // 🇨🇴 Filtrar citas del mismo día considerando la zona horaria de Colombia (America/Bogota UTC-5)
   const baseDate = new Date(scheduled_at);
   const startOfDay = new Date(Date.UTC(baseDate.getUTCFullYear(), baseDate.getUTCMonth(), baseDate.getUTCDate(), 5, 0, 0, 0));
   ```
3. **Tablas Físicas:**
   - `establishments.city DEFAULT 'Bogotá'` (sin columna `timezone`).
   - `staff_schedules.start_time TIME WITHOUT TIME ZONE`.
   - `establishments.operating_hours` almacena horas nominales de reloj (ej. `"08:00"`).
   - `bookings.scheduled_at TIMESTAMPTZ` (UTC).

### 14.2. Dictamen de Zona Horaria
- **Estado:** `TIMEZONE POLICY: OPEN / DIRECTOR DECISION REQUIRED 🟡`.
- **Justificación:** Aunque el código opera de facto en `America/Bogota` (UTC-5), no existe una columna `timezone` en `establishments` ni una decisión formal del Director que sancione si el sistema opera bajo una zona horaria fija de plataforma o configurable por sede.

---

## 15. DETERMINISM REQUIREMENTS (GARANTÍA DE DETERMINISMO)

Para garantizar determinismo absoluto:
1. **Ordenamiento de Slots:** Cronológico ascendente por `start_time ASC`.
2. **Ordenamiento de Membresías en Slot:** Léxico ascendente por `membership_id ASC`.
3. **Algoritmo de Discretización:** Generación determinística por saltos fijos de `step_minutes` a partir del inicio de cada bloque disponible.

---

## 16. PERSISTENCE ANALYSIS (EVALUACIÓN DE PERSISTENCIA)

```text
+------------------------------+---------------------------+------------------------------------+
| Entidad Física               | ¿Requerida en NODO-05?    | Justificación Técnica              |
+------------------------------+---------------------------+------------------------------------+
| Tabla `slots`                | NO 🛑                     | Generaría bloat e inconsistencias. |
| Tabla `availability_cache`   | NO 🛑                     | Prematuro; cálculo toma < 1 ms.    |
| Columna en `service_offers`  | NO 🛑                     | Duración base ya existe en 067.    |
| Migraciones DDL              | NO 🛑                     | 0 migraciones requeridas.          |
+------------------------------+---------------------------+------------------------------------+
```

---

## 17. TRANSPORT / ROUTING ANALYSIS (PROPOSAL — NOT APPROVED)

> [!WARNING]
> Las siguientes rutas y nombres de archivos constituyen exclusivamente una **PROPUESTA TÉCNICA DE INTEGRACIÓN — PROPOSAL NOT APPROVED**. El Contrato de Nodo no aprobó endpoints específicos; estos serán fijados formalmente en el Implementation Contract.

- **Ruta Propuesta:** `GET /api/v1/saas/hub/availability/projection`
- **Controlador Propuesto:** `backend/src/controllers/nodo05AvailabilityController.js`
- **Servicio Propuesto:** `backend/src/services/nodo05AvailabilityService.js`
- **Rutas Propuestas:** `backend/src/routes/nodo05AvailabilityRoutes.js`

---

## 18. TEST ARCHITECTURE (PROPUESTA DE PRUEBAS FÍSICAS)

Se define la matriz de casos de prueba propuesta para la futura fase de implementación:

```text
================================================================================
          PROPUESTA DE CASOS DE PRUEBA FÍSICOS (PROPOSAL — NOT APPROVED)
================================================================================
  T01. TARGETED Mode: Proyección determinística de slots para 1 colaborador.
  T02. AGGREGATED Mode: Fusión de slots y lista de available_memberships por franja.
  T03. Step Minutes: Generación a 15 min (default), 30 min y 45 min.
  T04. Establishment Hours ∩ Staff Schedule: Truncamiento estricto a horario de sede.
  T05. Booking Collision: Exclusión de slots que solapan con citas activas.
  T06. Booking Cancellation: Citas con estado CANCELADA NO bloquean slots.
  T07. Contiguous Back-to-Back: Slots contiguos a una cita son permitidos.
  T08. Zero Assignments: Retorno 200 OK con slots: [] y NO_STAFF_ASSIGNED.
  T09. Staff Not Working: Retorno 200 OK con slots: [] cuando no hay turno ese día.
  T10. Establishment Closed: Retorno 200 OK con slots: [] cuando la sede cierra.
  T11. Fully Booked: Retorno 200 OK con slots: [] cuando toda la jornada está ocupada.
  T12. Unassigned Professional: Retorno 422 en modo TARGETED con miembro no asignado.
  T13. Inactive Membership: Retorno 422 en modo TARGETED con miembro SUSPENDED/REVOKED.
  T14. Multi-Tenant Isolation: No proyecta ofertas ni lee reservas de otro tenant.
  T15. Cross-Establishment Isolation: No mezcla horarios de distintas sedes.
  T16. Invalid Target Date: Retorno 400 con fecha sintácticamente inválida.
  T17. Determinism: Dos ejecuciones idénticas producen idéntico payload DTO.
================================================================================
```

---

## 19. B2C BOUNDARY (AISLAMIENTO DE FRONTERAS B2C)

- **Lecturas B2C:** Exclusivamente `public.bookings` (SELECT).
- **Escrituras B2C:** **CERO (0)**.
- **Gobernanza:** `NODO-05` no crea prestadores, no activa servicios y no modifica esquemas B2C.

---

## 20. PROTECTED ASSETS (INVENTARIO DE ACTIVOS INMUTABLES)

Quedan formalmente protegidos contra cualquier modificación:
- `backend/migrations/065_saas_foundation_core.sql`
- `backend/migrations/066_context_resolution_tenant_resolver.sql`
- `backend/migrations/067_service_offers.sql`
- `backend/migrations/068_service_assignments.sql`
- `backend/migrations/069_staff_schedules.sql`
- `backend/migrations/070_saas_service_materializations.sql`
- Todos los servicios y controladores de NODO-01, NODO-02, NODO-03A, NODO-04.

---

## 21. PHYSICAL ARCHITECTURE OPTIONS (OPCIONES EVALUADAS)

```text
+----------+-------------------------------------------------+---------------------+---------------------------------------------------------------+
| Opción   | Descripción Técnica                             | Viabilidad          | Dictamen                                                      |
+----------+-------------------------------------------------+---------------------+---------------------------------------------------------------+
| OPCIÓN A | Pure Application-Service (Node.js + PostgreSQL) | ALTA 🟢             | PROPUESTA RECOMENDADA: Cero DDL, ultra-rápida, 100% testeable.|
| OPCIÓN B | PostgreSQL Stored Function (PL/pgSQL)           | MEDIA 🟡            | Rechazada: Innecesaria sobrecarga procedural en la base.      |
| OPCIÓN C | Nueva Tabla Física `availability_slots`         | NULA 🛑             | Rechazada: Viola el Contrato de Nodo y genera bloat masivo.   |
+----------+-------------------------------------------------+---------------------+---------------------------------------------------------------+
```

---

## 22. RECOMMENDED PHYSICAL ARCHITECTURE (ARQUITECTURA FÍSICA RECOMENDADA)

Se propone para ratificación la **OPCIÓN A: Pure Application-Service**:
1. **Cálculo en Memoria:** Servicio Node.js con funciones puras de álgebra de intervalos.
2. **Consultas a Base de Datos:** Consultas `SELECT` eficientes sobre tablas existentes con RLS.
3. **Persistencia Cero:** Cero tablas DDL, cero migraciones.

---

## 23. PHYSICAL RISKS & GAPS

| Riesgo / Brecha Física | Severidad | Mitigación Técnica Propuesta |
| :--- | :---: | :--- |
| **Zona Horaria no parametrizada en BD** | Media | Clasificada como `OPEN / DIRECTOR DECISION REQUIRED`. Utilizar `America/Bogota` por defecto de facto. |
| **Parseo de `operating_hours` heterogéneo** | Baja | Reutilización del parser polimórfico ya probado en NODO-03A. |
| **Inyección de Tenant falso** | Alta | Bloqueada físicamente: `tenant_id` se extrae de `req.tenantId` inyectado por middleware. |

---

## 24. DECISIONS REQUIRED (DECISIONES REQUERIDAS DEL DIRECTOR GATE)

```text
================================================================================
                    DECISIONES REQUERIDAS DEL DIRECTOR GATE
================================================================================

1. [TIMEZONE POLICY]:
   • Ratificar si NODO-05 opera bajo la zona horaria fija de plataforma America/Bogota (UTC-5)
     conforme al código existente, o si requiere definición formal de columna en establishments.
   • Estado: OPEN / DIRECTOR DECISION REQUIRED.

2. [INTERVAL BOUNDARY RATIFICATION]:
   • Ratificar el modelo de intervalos semi-abiertos [start, end) evidenciado en bookingController.js.
   • Estado: SUPPORTED BY EVIDENCE — PENDING RATIFICATION.

3. [IMPLEMENTATION WHITELIST & ROUTING]:
   • Ratificar en el Implementation Contract la lista blanca de archivos y ruta definitiva:
     - backend/src/services/nodo05AvailabilityService.js [NEW]
     - backend/src/controllers/nodo05AvailabilityController.js [NEW]
     - backend/src/routes/nodo05AvailabilityRoutes.js [NEW]
     - backend/index.js [MODIFY]
     - backend/tests/test_nodo05_availability_suite.js [NEW]
   • Estado: PROPOSAL — NOT APPROVED.
================================================================================
```

---

## 25. DIRECTOR GATE

```text
================================================================================
                         DIRECTOR GATE STATUS
================================================================================
  ESTADO DE LA ARQUITECTURA FÍSICA:
  PHYSICAL ARCHITECTURE READY FOR DIRECTOR APPROVAL 🟡

  DICTAMEN TÉCNICO:
  1. Se demostró la viabilidad física completa de NODO-05 con CERO nuevas tablas.
  2. La arquitectura de cálculo en memoria (Opción A) es determinística, segura y eficiente.
  3. Se preservan al 100% el aislamiento multi-tenant, RLS y las fronteras B2C.
  4. Todas las decisiones pendientes (Timezone, Routing, Whitelist) quedan explícitamente clasificadas.

  AUTORIZACIÓN DE IMPLEMENTACIÓN:
  NOT GRANTED 🛑 (Esperando Aprobación del Director Gate)
================================================================================
```
