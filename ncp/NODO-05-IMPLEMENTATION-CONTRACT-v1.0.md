# NODO-05 — IMPLEMENTATION CONTRACT v1.0 (RECONCILED)
## Availability Projection & Booking Slot Engine — Executable Implementation Specification

**DOCUMENT IDENTIFIER:** `NODO-05-IMPLEMENTATION-CONTRACT-v1.0`  
**STATUS:** `IMPLEMENTATION CONTRACT READY FOR DIRECTOR GO 🟡`  
**DATE:** 2026-09-11  
**ROLE:** Senior Implementation Architect & Lead Engineer  
**AUTORIDAD RAÍZ:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `GO — NODO-05 IMPLEMENTATION CONTRACT FINAL RECONCILIATION v1.1`  
**CONTRATO DE NODO BASE:** [`/ncp/NODO-05-NODE-CONTRACT-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NODO-05-NODE-CONTRACT-v1.0.md)  
**DISCOVERY FÍSICO RATIFICADO:** [`/ncp/NODO-05-PHYSICAL-ARCHITECTURE-DISCOVERY-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NODO-05-PHYSICAL-ARCHITECTURE-DISCOVERY-v1.0.md)  
**DECISIÓN DE ZONA HORARIA:** [`/ncp/NODO-05-TIMEZONE-DECISION-ANALYSIS-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NODO-05-TIMEZONE-DECISION-ANALYSIS-v1.0.md) (`America/Bogota` Ratified 🔒)  
**CLASSIFICATION:** IMPLEMENTATION CONTRACT — ZERO RUNTIME MODIFICATION / ZERO DDL  
**METHODOLOGY:** DEFINIR → RELACIONAR → INTEGRAR → VALIDAR → CERRAR → AVANZAR  
**IMPLEMENTATION AUTHORIZATION:** NOT YET AUTHORIZED 🛑 (Contract Reconciled — Requires Director GO Authorization)

---

## 1. NODE IDENTITY

- **NODE_ID:** `NODO-05`
- **VERSION:** `1.0`
- **NAME:** `Availability Projection & Booking Slot Engine`
- **TYPE:** `Read-Only Computational Projection Runtime (In-Memory Application Service)`
- **LAYER:** `SaaS Core Engine / Availability Domain`

---

## 2. ARCHITECTURAL BASELINE

El motor de proyección de disponibilidad opera sobre la siguiente cadena física cerrada e inmutable:

```text
================================================================================
                    LÍNEA BASE FÍSICA Y CONTRACTUAL CERRADA
================================================================================
  1. [065] FOUNDATION:     tenants, establishments, memberships, usuarios 🔒
  2. [066] CONTEXT:        fn_resolve_user_tenant() & activeContextMiddleware 🔒
  3. [067] SERVICE OFFERS: service_offers (base_duration INTEGER NOT NULL) 🔒
  4. [068] ASSIGNMENTS:    service_assignments (M:N Offer <-> Membership) 🔒
  5. [069] STAFF SCHEDULE: staff_schedules (Weekly recurring 1..7 intervals) 🔒
  6. [070] MATERIALIZATION:saas_service_materializations (B2C Bridge) 🔒
  7. [PRE-N01] BOOKINGS:   public.bookings (Read-Only Occupancy Source) 🔒
================================================================================
```

### Principio de Flujo Físico:
$$\text{Hechos DB Existentes} \longrightarrow \text{Lecturas SELECT con RLS} \longrightarrow \text{Servicio de Aplicación en Node.js} \longrightarrow \text{Cálculo en Memoria} \longrightarrow \text{DTO Canónico}$$

---

## 3. INPUT CONTRACT (CONTRATO DE ENTRADA)

### 3.1. Contexto Inyectado por el Servidor (Server-Derived — Zero Client Spoofing)
- `req.tenantId`: `INTEGER` (Inyectado por `activeContextMiddleware`).
- `req.establishmentId`: `UUID` (Inyectado por `activeContextMiddleware`).
- `req.activeContext`: Descriptor de contexto con rol (`OWNER`, `MANAGER`, `PROFESSIONAL`, `RECEPTIONIST`).

### 3.2. Parámetros de Entrada de la Solicitud (Request Query Parameters)
```typescript
interface AvailabilityProjectionRequest {
  service_offer_id: string;      // UUID obligatorio
  target_date: string;           // YYYY-MM-DD obligatorio (ISO 8601 Date)
  projection_mode?: "TARGETED" | "AGGREGATED"; // Opcional (derivado de presencia de membership_id)
  membership_id?: string;        // UUID opcional (Requerido en modo TARGETED)
  step_minutes?: number;         // Entero opcional (Default: 15)
}
```

---

## 4. OUTPUT CONTRACT (CONTRATO DE SALIDA CANÓNICO)

El DTO de salida preserva **estrictamente y sin adiciones no autorizadas** el siguiente esquema:

```json
{
  "establishment_id": "e4b2d3c1-7a89-4f5e-b123-456789abcdef",
  "service_offer_id": "f5a1b2c3-d4e5-6f7a-8b9c-0d1e2f3a4b5c",
  "target_date": "2026-09-15",
  "day_of_week": 2,
  "service_duration_minutes": 45,
  "step_minutes": 15,
  "projection_mode": "AGGREGATED",
  "slots": [
    {
      "start_time": "09:00",
      "end_time": "09:45",
      "available_memberships": [
        "1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d",
        "8f3b2a1c-4d5e-6f7a-8b9c-0d1e2f3a4b5c"
      ]
    },
    {
      "start_time": "09:15",
      "end_time": "10:00",
      "available_memberships": [
        "8f3b2a1c-4d5e-6f7a-8b9c-0d1e2f3a4b5c"
      ]
    }
  ]
}
```

> [!IMPORTANT]
> Queda terminantemente excluido del DTO canónico cualquier campo no aprobado por el Director, incluyendo: `total_slots_count`, `availability_state`, `slot_id`, `provider_id`, `price`, `booking_id` o estados de publicación. Cuando una oferta no tiene personal asignado, el payload retorna de forma determinística `slots: []`.

---

## 5. DATA SOURCE CONTRACT (CONTRATO DE FUENTES DE DATOS)

`NODO-05` lee exclusivamente de las siguientes tablas físicas existentes:

| Tabla Física | Modos de Acceso | Columnas Utilizadas | Filtros Obligatorios |
| :--- | :---: | :--- | :--- |
| `public.establishments` | `SELECT` | `id`, `operating_hours` | `id = :establishmentId AND tenant_id = :tenantId` |
| `public.service_offers` | `SELECT` | `id`, `name`, `base_duration` | `id = :serviceOfferId AND establishment_id = :establishmentId AND tenant_id = :tenantId` |
| `public.service_assignments` | `SELECT` | `service_offer_id`, `membership_id` | `service_offer_id = :serviceOfferId AND establishment_id = :establishmentId AND tenant_id = :tenantId` |
| `public.memberships` | `SELECT` | `id`, `user_id`, `status` | `id = :membershipId AND establishment_id = :establishmentId AND tenant_id = :tenantId AND status = 'ACTIVE'` |
| `public.staff_schedules` | `SELECT` | `membership_id`, `day_of_week`, `start_time`, `end_time` | `establishment_id = :establishmentId AND tenant_id = :tenantId AND day_of_week = :dayOfWeek AND membership_id = ANY(:memberships)` |
| `public.bookings` | `SELECT` | `provider_id`, `scheduled_at`, `estado`, `service_id` | `provider_id = ANY(:userIds) AND estado != 'CANCELADA' AND scheduled_at >= :startUtc AND scheduled_at < :endUtc` |

---

## 6. ACTIVE CONTEXT RESOLUTION

1. El runtime extrae `tenantId` y `establishmentId` de `req.tenantId` y `req.establishmentId`.
2. Las consultas a PostgreSQL se ejecutan configurando la sesión transaccional con RLS:
   ```sql
   SET LOCAL app.tenant_id = :tenantId;
   ```
3. Ninguna solicitud puede eludir o sobrescribir el contexto resuelto por el servidor.

---

## 7. SERVICE OFFER RESOLUTION

1. Se consulta `service_offers` por `(id, establishment_id, tenant_id)`.
2. Si no existe fila: Retornar error `404 SERVICE_OFFER_NOT_FOUND`.
3. La duración utilizada para todos los cálculos es estrictamente `service_offers.base_duration` (minutos).
4. No se permite inferir duración de tablas B2C ni de reservas anteriores.

---

## 8. ASSIGNMENT RESOLUTION

1. Se obtienen todas las asignaciones activas en `service_assignments` para la oferta en la sede activa vinculadas a `memberships` con `status = 'ACTIVE'`.
2. Si existen 0 asignaciones activas: Aplicar la regla de **Zero Assignments** (Sección 10.2).

---

## 9. TARGETED MODE

- **Condición:** Se provee `membership_id` en la solicitud.
- **Validaciones Obligatorias:**
  1. `membership_id` debe existir en la sede activa y tener `status = 'ACTIVE'`. (Si no: `404 MEMBERSHIP_NOT_FOUND` o `422 INACTIVE_MEMBERSHIP`).
  2. `membership_id` debe estar presente en `service_assignments` para esa oferta. (Si no: `422 UNASSIGNED_PROFESSIONAL`).
- **Comportamiento:** Calcula los slots exclusivamente para ese colaborador.
- **Salida:** En cada slot proyectado, `available_memberships` contendrá únicamente `[membership_id]`.

---

## 10. AGGREGATED MODE & ZERO ASSIGNMENTS

### 10.1. AGGREGATED Mode
- **Condición:** No se provee `membership_id` en la solicitud.
- **Comportamiento:**
  1. Proyecta los slots de cada colaborador activo asignado de forma independiente.
  2. Realiza la unión temporal de las franjas de inicio disponibles.
  3. En cada franja resultante, agrega la lista de colaboradores capaces de atender: `available_memberships: [UUID_1, UUID_2, ...]`.
  4. **Prohibición:** Cero ordenamiento por preferencia, calificación, carga o jerarquía.

### 10.2. Zero Assignments Behavior (`N05-DEC-06`)
- Si una oferta de servicio válida tiene 0 asignaciones activas:
  - **HTTP Status:** `200 OK`.
  - **Payload:** `slots: []`.
  - No constituye error 404 ni 500.

---

## 11. STAFF SCHEDULE RESOLUTION

1. Para la fecha `target_date`, se deriva el día de la semana local en Colombia:
   $$\text{day\_of\_week} \in [1 \dots 7] \quad (1=\text{Lunes}, \dots, 7=\text{Domingo})$$
2. Se consultan las filas en `staff_schedules` para las membresías asignadas en ese `day_of_week`.
3. Cada fila representa un bloque de disponibilidad nominal $[S_{\text{start}}, S_{\text{end}}]$.
4. Si un colaborador no tiene filas para ese día, su disponibilidad es vacía ($\emptyset$).

---

## 12. ESTABLISHMENT OPERATING HOURS INTERSECTION (`N05-DEC-02`)

1. Se obtiene `operating_hours JSONB` de `establishments`.
2. Se extrae el horario del día $[E_{\text{start}}, E_{\text{end}}]$ usando el parser polimórfico validado (soporte llaves inglés/español, booleanos `is_open`/`activo`, horas string o número).
3. **Regla de Intersección Estricta:**
   $$\text{Ventana Proyectable} = [S_{\text{start}}, S_{\text{end}}] \cap [E_{\text{start}}, E_{\text{end}}] = [\max(S_{\text{start}}, E_{\text{start}}), \min(S_{\text{end}}, E_{\text{end}})]$$
4. Si $\max(S_{\text{start}}, E_{\text{start}}) \ge \min(S_{\text{end}}, E_{\text{end}})$ o el establecimiento está cerrado (`is_open = false`): La ventana resultante es nula.
5. **Invariante:** Ningún slot candidato puede iniciar ni finalizar fuera de $[E_{\text{start}}, E_{\text{end}}]$.

---

## 13. BOOKING OCCUPANCY RESOLUTION (`N05-DEC-03`)

1. Para cada colaborador asignado, se obtiene su `user_id` (`memberships.user_id ≡ usuarios.id`).
2. Se consultan las citas en `public.bookings` donde:
   - `provider_id = ANY(:userIds)`
   - `estado != 'CANCELADA'`
   - `scheduled_at >= :startOfDayUtc AND scheduled_at < :endOfDayUtc`
3. Cada cita genera un intervalo ocupado:
   $$[B_{\text{start}}, B_{\text{end}}) = [\text{scheduled\_at}, \text{scheduled\_at} + \text{service.duration\_minutes})$$
4. **Cero Mutación:** La interacción con `public.bookings` es estrictamente de solo lectura (`SELECT`).

---

## 14. TIMEZONE ARCHITECTURAL SPECIFICATION (`America/Bogota`)

### 14.1. Decisión Arquitectónica Ratificada
- **Zona Horaria de Plataforma:** `America/Bogota` (UTC-5 constante, sin Daylight Saving Time).

### 14.2. Mecanismo de Implementación de Consulta
- **Conversión de `target_date` (`YYYY-MM-DD`):**
  - Inicio del día local en UTC: `Date.UTC(YYYY, MM - 1, DD, 5, 0, 0, 0)` ($00:00\text{ COT}$).
  - Fin del día local en UTC: `Date.UTC(YYYY, MM - 1, DD + 1, 4, 59, 59, 999)` ($23:59:59.999\text{ COT}$).
- **Traducción de Citas `TIMESTAMPTZ` a Minutos Locales:**
  $$\text{minutos\_locales} = \big((\text{booking.scheduled\_at.getUTCHours()} - 5 + 24) \pmod{24}\big) \times 60 + \text{booking.scheduled\_at.getUTCMinutes()}$$
- **Representación en DTO:** Los slots se emiten en formato de hora local `"HH:MM"` (`"09:00"`, `"09:45"`).

---

## 15. INTERVAL MODEL & COLLISION ALGEBRA

- **Modelo Formal:** Intervalos semi-abiertos $[t_{\text{start}}, t_{\text{end}})$.
- **Regla de No Colisión:** Un slot candidato $[S_{\text{slot}}, E_{\text{slot}})$ es válido frente a una cita $[S_{\text{book}}, E_{\text{book}})$ si y solo si:
  $$\neg \big( S_{\text{slot}} < E_{\text{book}} \land E_{\text{slot}} > S_{\text{book}} \big) \iff \big( E_{\text{slot}} \le S_{\text{book}} \lor S_{\text{slot}} \ge E_{\text{book}} \big)$$
- **Consecuencia:** Una cita que finaliza a las `10:00` ($E_{\text{book}} = 10:00$) permite un slot que inicia a las `10:00` ($S_{\text{slot}} = 10:00$) de forma continua sin colisión.

---

## 16. SLOT GENERATION PIPELINE

Para cada ventana disponible $[W_{\text{start}}, W_{\text{end}})$ de un colaborador:
1. $t = W_{\text{start}}$.
2. Mientras $t + \text{base\_duration} \le W_{\text{end}}$:
   a. Definir candidato: $[t, t + \text{base\_duration})$.
   b. Verificar si colisiona con alguna cita activa del colaborador.
   c. Si no colisiona: El slot es válido y se agrega a la colección de ese colaborador.
   d. Avanzar: $t = t + \text{step\_minutes}$.

---

## 17. STEP MINUTES SPECIFICATION (`N05-DEC-01`)

1. **Valor por Defecto Aprobado:** `step_minutes = 15`.
2. **Guardia de Validación de Implementación (Sanitización Técnica):**
   - Debe ser un entero positivo.
   - Rango técnico permitido: $5 \le \text{step\_minutes} \le 120$.
   - Si no cumple: Retornar error de validación `400 INVALID_STEP_MINUTES`.

---

## 18. DETERMINISM GUARANTEE

1. **Orden de Slots:** Cronológico ascendente por `start_time ASC`.
2. **Orden de Colaboradores:** Al agrupar `available_memberships`, la lista se ordena de forma determinística por `membership_id ASC` (alfanumérico estándar).
3. **Invarianza:** Mismos datos en BD + mismos parámetros = idéntico JSON DTO de salida en el 100% de las ejecuciones.

---

## 19. SECURITY / RLS

1. El endpoint requiere autenticación JWT obligatoria (`authMiddleware`).
2. Requiere resolución de contexto activo obligatoria (`activeContextMiddleware`).
3. El rol autenticado debe pertenecer a la membresía activa de la sede.
4. Se aplica `SET LOCAL app.tenant_id = :tenantId` en toda conexión con PostgreSQL.

---

## 20. TRANSACTION MODEL

- **Transaccionalidad:** Al ser una operación de solo lectura computacional (`SELECT`), **NO se requiere transacción de escritura ni bloqueo de filas (`FOR UPDATE`)**.
- Las lecturas se ejecutan concurrentemente sobre el pool de conexiones estándar de PostgreSQL con aislamiento de lectura `READ COMMITTED` (default de PostgreSQL).

---

## 21. ERROR CONTRACT (CONTRATO DE ERRORES HTTP)

Se evaluó la taxonomía de errores contra las convenciones existentes del backend (`handleError`, `staffAvailabilityController`, `nodo04MaterializationController`):

```text
+-------------+---------------------------+------------------------------------+---------------------------------------------------------------+
| Código HTTP | Error Code                | Clasificación Arquitectónica       | Condición Disparadora                                         |
+-------------+---------------------------+------------------------------------+---------------------------------------------------------------+
| 400         | INVALID_TARGET_DATE       | FACT — Convención Existente        | target_date no tiene formato YYYY-MM-DD o fecha inválida.     |
| 400         | INVALID_STEP_MINUTES      | IMPLEMENTATION CONTRACT GUARD      | step_minutes menor a 5 o mayor a 120.                         |
| 401         | UNAUTHORIZED              | FACT — authMiddleware Existente    | Token ausente, expirado o con firma inválida.                 |
| 403         | FORBIDDEN_CONTEXT         | FACT — activeContextMiddleware     | Rol/Membresía no pertenece a la sede/tenant solicitada.       |
| 404         | SERVICE_OFFER_NOT_FOUND   | IMPLEMENTATION CONTRACT            | Oferta no existe o no pertenece al contexto activo.           |
| 404         | MEMBERSHIP_NOT_FOUND      | IMPLEMENTATION CONTRACT            | En modo TARGETED, la membresía no existe en la sede.          |
| 422         | UNASSIGNED_PROFESSIONAL   | IMPLEMENTATION CONTRACT            | En modo TARGETED, el miembro no está asignado al servicio.    |
| 422         | INACTIVE_MEMBERSHIP       | IMPLEMENTATION CONTRACT            | En modo TARGETED, membresía en estado SUSPENDED o REVOKED.    |
+-------------+---------------------------+------------------------------------+---------------------------------------------------------------+
```

---

## 22. TRANSPORT PROPOSAL — NOT APPROVED (PROPUESTA TÉCNICA DE TRANSPORTE)

> [!WARNING]
> La siguiente definición de transporte constituye exclusivamente una **PROPUESTA TÉCNICA — NOT APPROVED**. No autoriza endpoints hasta su ratificación formal por el Director.

```text
HTTP Method: GET
Path:        /api/v1/saas/hub/availability/projection
Middleware:  authMiddleware, activeContextMiddleware
Query Params:
  • service_offer_id (UUID, Required)
  • target_date (YYYY-MM-DD, Required)
  • membership_id (UUID, Optional)
  • step_minutes (Integer, Optional)
```

---

## 23. IMPLEMENTATION FILE SET — PROPOSED (LISTA BLANCA PROPUESTA)

Queda propuesta la siguiente lista blanca de archivos para la futura implementación:

1. `backend/src/services/nodo05AvailabilityService.js` `[NEW]` (Lógica pura de orquestación y proyección en memoria).
2. `backend/src/controllers/nodo05AvailabilityController.js` `[NEW]` (Validación de request, dispatch y formateo HTTP).
3. `backend/src/routes/nodo05AvailabilityRoutes.js` `[NEW]` (Definición de ruta REST protegida por middlewares).
4. `backend/index.js` `[MODIFY]` (Montaje exclusivo de la ruta en la aplicación Express si es ratificada).
5. `backend/tests/test_nodo05_availability_suite.js` `[NEW]` (Batería exhaustiva de pruebas automatizadas).

---

## 24. TEST CONTRACT & 20-CATEGORY TRACEABILITY MATRIX

Se establece la matriz de trazabilidad exacta entre las **20 categorías requeridas por el Director** y la suite automatizada `test_nodo05_availability_suite.js`:

```text
+----+--------------------------------------------+------------------------------------------+-----------------+
| #  | Categoría Requerida por el Director        | Test Case ID en Suite NODO-05            | Estado Mapeo    |
+----+--------------------------------------------+------------------------------------------+-----------------+
| 01 | Basic Projection                           | T01_BASIC_PROJECTION_SUCCESS             | CUBIERTO 🟢     |
| 02 | Default step_minutes (15 min)              | T02_DEFAULT_STEP_MINUTES_15              | CUBIERTO 🟢     |
| 03 | Custom step_minutes (30 min / 45 min)      | T03_CUSTOM_STEP_MINUTES_30               | CUBIERTO 🟢     |
| 04 | TARGETED Mode Projection                   | T04_TARGETED_PROJECTION_SUCCESS          | CUBIERTO 🟢     |
| 05 | AGGREGATED Mode Projection                 | T05_AGGREGATED_PROJECTION_SUCCESS        | CUBIERTO 🟢     |
| 06 | Zero Assignments Behavior (200 OK [])      | T06_ZERO_ASSIGNMENTS_EMPTY_200           | CUBIERTO 🟢     |
| 07 | Staff Schedule Intersection (069)          | T07_STAFF_SCHEDULE_INTERSECTION          | CUBIERTO 🟢     |
| 08 | Establishment Operating Hours Intersection | T08_ESTABLISHMENT_HOURS_INTERSECTION     | CUBIERTO 🟢     |
| 09 | Booking Collision Exclusion (Active)       | T09_BOOKING_COLLISION_EXCLUSION          | CUBIERTO 🟢     |
| 10 | Cancelled Booking Exclusion (Ignored)      | T10_CANCELLED_BOOKING_IGNORED            | CUBIERTO 🟢     |
| 11 | Back-to-Back Availability (Contiguous)     | T11_BACK_TO_BACK_CONTIGUOUS              | CUBIERTO 🟢     |
| 12 | Deterministic Ordering (Slots & Members)   | T12_DETERMINISTIC_ORDERING               | CUBIERTO 🟢     |
| 13 | Cross-Establishment Isolation              | T13_CROSS_ESTABLISHMENT_ISOLATION        | CUBIERTO 🟢     |
| 14 | Cross-Tenant Isolation (RLS)               | T14_CROSS_TENANT_ISOLATION_RLS           | CUBIERTO 🟢     |
| 15 | Invalid Service Offer Handling (404)       | T15_SERVICE_OFFER_NOT_FOUND_404          | CUBIERTO 🟢     |
| 16 | Invalid / Inactive Membership (404/422)    | T16_INVALID_INACTIVE_MEMBERSHIP_422      | CUBIERTO 🟢     |
| 17 | Timezone Boundary Handling (America/Bogota)| T17_TIMEZONE_BOUNDARY_HANDLING           | CUBIERTO 🟢     |
| 18 | Date / Day-of-Week Correctness (1..7)      | T18_DATE_DAY_OF_WEEK_CORRECTNESS         | CUBIERTO 🟢     |
| 19 | Service Duration Correctness (base_dur)    | T19_SERVICE_DURATION_CORRECTNESS         | CUBIERTO 🟢     |
| 20 | Concurrent Read Behavior (Parallel SELECT) | T20_CONCURRENT_READ_BEHAVIOR             | CUBIERTO 🟢     |
+----+--------------------------------------------+------------------------------------------+-----------------+
```

---

## 25. NON-GOALS (LÍMITES EXPLÍCITOS DEL NODO)

`NODO-05` no implementará:
- Citas de salón ni reservas (`bookings` / `appointments`).
- Agenda de salón (NODO-06).
- Checkout, pasarelas de pago ni tarifas.
- Publicación o activación B2C.
- Materialización downstream (NODO-04).
- Persistencia o tablas de slots.
- Modificación de horarios de personal o sedes.

---

## 26. PROTECTED ASSETS (ACTIVOS INMUTABLES)

Queda prohibido modificar:
- `backend/migrations/065` a `070`.
- Todo el código de `Foundation`, `NODO-01`, `NODO-02`, `NODO-03A`, `NODO-04`.
- Todo el código de `Pre-Nodo 01` (`bookingController.js`, `serviceController.js`, etc.).

---

## 27. ARCHITECTURAL RISKS (GESTIÓN DE RIESGOS)

- **Riesgo:** Desfase horario por conversión de fechas en clientes externos.  
  **Mitigación:** Toda la aritmética de fecha se ejecuta forzando el corte `America/Bogota` (UTC-5) y emitiendo horas locales `"HH:MM"`.
- **Riesgo:** Inyección de tenant por query params.  
  **Mitigación:** `tenantId` proviene exclusivamente de `req.tenantId` inyectado por `activeContextMiddleware`.

---

## 28. OPEN DECISIONS (DECISIONES ABIERTAS)

**CERO (0) DECISIONES ABIERTAS.**  
Todas las decisiones semánticas (`N05-DEC-01` a `N05-DEC-09`), de zona horaria (`America/Bogota`), de persistencia (cero DDL) y de modelo de intervalos ($[start, end)$) han sido formalmente ratificadas.

---

## 29. IMPLEMENTATION AUTHORIZATION GATE

```text
================================================================================
                         DIRECTOR GATE STATUS
================================================================================
  ESTADO FINAL:
  IMPLEMENTATION CONTRACT READY FOR DIRECTOR GO 🟢

  DICTAMEN TÉCNICO:
  1. El contrato de implementación traduce con exactitud matemática y física
     la totalidad de los requisitos de NODO-05.
  2. Cumple con la cobertura completa de las 20 categorías de prueba.
  3. No introduce nuevas tablas, migraciones DDL ni mutaciones en esquemas B2C.
  4. Queda listo para la emisión formal del GO de Implementación por el Director.

  AUTORIZACIÓN DE IMPLEMENTACIÓN:
  NOT YET AUTHORIZED 🛑 (Esperando GO de Implementación del Director)
================================================================================
```
