# SERVICE EXECUTION SEMANTIC MODEL DISCOVERY REPORT v1.0
## Modelo Semántico de Ejecución: Capacidad, Oferta, Asignación, Ejecución y Reserva

**Versión:** 1.0.0  
**Estado:** DISCOVERY COMPLETE / PENDING DIRECTOR ARCHITECTURAL REVIEW 🟡  
**Autoridad:** Director del Proyecto GlowApp SaaS  
**Carácter:** Read-Only Architectural Discovery (Cero Modificaciones a Código, BD o Nodos Protegidos)

---

## 1. PURPOSE

El propósito de este informe es determinar, con evidencia física rigurosa del repositorio de GlowApp, cuál debe ser la **unidad semántica de ejecución de un servicio en SaaS** antes de definir cualquier contrato de integración downstream con Pre-Nodo 01.

La investigación desglosa formalmente las 5 capas del ciclo de vida del servicio:
```text
┌──────────────┐     ┌───────────┐     ┌────────────────┐     ┌─────────────┐     ┌───────────┐
│  CAPABILITY  │ ──> │   OFFER   │ ──> │   ASSIGNMENT   │ ──> │  EXECUTION  │ ──> │  BOOKING  │
├──────────────┤     ├───────────┤     ├────────────────┤     ├─────────────┤     ├───────────┤
│ Aptitud del  │     │ Catálogo  │     │ Habilitación   │     │ Conjunción  │     │ Registro  │
│ Profesional  │     │ de Sede   │     │ Sede-Prof-Serv │     │ en Tiempo   │     │ Cliente   │
└──────────────┘     └───────────┘     └────────────────┘     └─────────────┘     └───────────┘
```

---

## 2. SCOPE

### Fuentes Físicas Auditadas:
- **Plano SaaS (B2B Multitenant):**
  - `backend/migrations/065_saas_foundation_core.sql` (`organizations`, `establishments`, `memberships`).
  - `backend/src/services/crearDesdeCeroService.js` (Estructura de `Context Package`, `relevant_services`, `people_initial_roles`).
- **Plano Core B2C (Pre-Nodo 01 Inmutable):**
  - `backend/init.sql` (`usuarios`, `perfiles_prestador`, `services`, `bookings`).
  - `backend/src/controllers/serviceController.js` (Gestión de catálogo personal).
  - `backend/src/controllers/providerController.js` (Directorio PostGIS y slots).
  - `backend/src/controllers/bookingController.js` (Creación y solapamiento de reservas).
  - `backend/src/models/index.js` (Asociaciones ORM Sequelize).

---

## 3. EVIDENCE

Todas las conclusiones de este informe se fundamentan en evidencia directa de archivos y funciones existentes, descartando suposiciones.

---

## 4. PREGUNTA ARQUITECTÓNICA CENTRAL

### Evaluación de Interpretaciones Semánticas:
- **A — SERVICE-CENTRIC (`ESTABLISHMENT → SERVICE → PROFESSIONAL`):** Describe la intención de catálogo de la sede, pero es insuficiente por sí sola para el agendamiento B2C porque no considera la disponibilidad individual de la persona.
- **B — PROFESSIONAL-CENTRIC (`PROFESSIONAL → SERVICE → ESTABLISHMENT`):** Es el modelo físico legado de Pre-Nodo 01 (`services.provider_id`), pero es ciego respecto a la existencia de sedes y organizaciones.
- **C — ASSIGNMENT-CENTRIC (`ESTABLISHMENT → SERVICE → ASSIGNMENT → PROFESSIONAL`):** Modela con precisión el catálogo y la asignación en tiempo de configuración.
- **D — EXECUTION-CENTRIC (`ESTABLISHMENT + PROFESSIONAL + SERVICE → EXECUTION → BOOKING`):** **Modelo Semántico Dominante**.

> **Conclusión de la Pregunta Central:**  
> La semántica necesaria para GlowApp es **`D — EXECUTION-CENTRIC`** en tiempo de reserva y **`C — ASSIGNMENT-CENTRIC`** en tiempo de catálogo. Una ejecución válida y reservable solo existe cuando coinciden un **Servicio**, un **Profesional capacitado/asignado** y un **Establecimiento** en un **Horario no colisionante**.

---

## 5. PREGUNTAS CANÓNICAS (SEM-Q01 → SEM-Q04)

### SEM-Q01 — CAPABILITY (Capacidad Profesional)
- **Definición:** Competencia técnica o cualificación intrínseca de una persona para realizar una categoría de procedimientos estéticos.
- **Evidencia Física:**
  1. `backend/src/services/crearDesdeCeroService.js` líneas 152, 166: `people_initial_roles[i].assigned_categories` captura las categorías que el colaborador puede ejecutar.
  2. `backend/init.sql` línea 65: `perfiles_prestador.portafolio_servicios` almacena JSONB con categorías.
- **Distinciones Semánticas:**
  - `Capacidad ≠ Oferta`: Que Ana sepa hacer "Uñas Acrílicas" no implica que la sede las ofrezca.
  - `Capacidad ≠ Asignación`: Que Ana sepa hacer "Uñas Acrílicas" no implica que la Sede A la haya autorizado para realizarlas en esa sede.
  - `Capacidad ≠ Disponibilidad`: Que Ana sepa hacer el servicio no implica que esté en turno en un momento $T$.

### SEM-Q02 — OFFER (Oferta de Servicio)
- **Definición:** Decisión comercial de un establecimiento de poner a disposición del público un servicio bajo un nombre, duración y precio determinado.
- **Evidencia Física:**
  1. En SaaS: `relevant_services` en `Context Package` (`crearDesdeCeroService.js` L125-132) define la oferta en memoria a nivel de sede.
  2. En B2C: `public.services` (`backend/init.sql` L83-93) modela la oferta, pero **fusionada rígidamente con un prestador individual** (`provider_id INTEGER NOT NULL`).
- **Distinción:** "El Salón Elegance ofrece Corte por $45.000" es una **Oferta de Sede**. En la base de datos física actual de Pre-Nodo 01, la oferta de sede **está ausente** como entidad independiente.

### SEM-Q03 — ASSIGNMENT (Asignación)
- **Definición:** Vínculo formal que habilita a un profesional específico para ejecutar una oferta específica de un establecimiento específico.
- **Evidencia Física:**
  1. En SaaS: La asignación existe de forma implícita mediante la intersección de `people_initial_roles.assigned_categories` y `relevant_services.category`.
  2. En B2C: La asignación está **FUSIONADA E INDISOLUBLE** en la columna `services.provider_id` ([`init.sql`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/init.sql#L85)). No existe entidad intermedia N-a-N.

### SEM-Q04 — EXECUTION (Ejecución)
- **Definición:** La materialización efectiva de un servicio por un profesional en una sede en un instante temporal determinado.
- **Evidencia Física:**
  - `backend/src/controllers/bookingController.js` líneas 56-66, 123-147.
  - Para una ejecución válida se requiere:
    1. **Identidad del Servicio:** `service_id` (duración, precio, nombre).
    2. **Ejecutor:** `provider_id` (`usuarios.id` verificado en `perfiles_prestador`).
    3. **Contexto / Ubicación:** Sede física o dirección de atención.
    4. **Disponibilidad:** Slot libre sin colisiones en `bookings` y dentro de `weekly_schedule`.
    5. **Receptor:** `client_id`.

---

## 6. ESCENARIOS CANÓNICOS (SEM-Q05 → SEM-Q11)

### SEM-Q05 — Un Profesional / Una Sede
```text
Sede A ──> Ana ──> Corte de cabello
```
* **Estado:** **`SUPPORTED`**
* **Evidencia:** En Pre-Nodo 01 se mapea directamente creando 1 registro en `public.services` con `provider_id = Ana_id`. Ana posee 1 registro en `perfiles_prestador` con la ubicación de la Sede A.

---

### SEM-Q06 — Varios Profesionales / Una Sede
```text
Sede A ──┬──> Ana    ──> Corte de cabello
         ├──> Carlos ──> Corte de cabello
         └──> Pedro  ──> Corte de cabello
```
* **Estado:** **`PARTIALLY_SUPPORTED`** (Soportado mediante duplicación física de filas).
* **Evidencia:**
  - En Pre-Nodo 01 (`services` L85), no se puede compartir una fila.
  - Se requieren 3 filas en `public.services` (una para Ana, una para Carlos, una para Pedro).
  - Cada cliente reserva contra la fila del profesional elegido. Conceptualmente el servicio es el mismo en la sede, pero físicamente son 3 entidades separadas.

---

### SEM-Q07 — Un Profesional / Varias Sedes
```text
Ana ──┬──> Sede A (Chicó)      ──> Corte de cabello
      └──> Sede B (Chapinero)  ──> Corte de cabello
```
* **Estado:** **`NOT_SUPPORTED`** en el modelo B2C actual.
* **Evidencia Física:**
  - `backend/init.sql` L64: `perfiles_prestador` tiene **una única columna `ubicacion`** (`GEOGRAPHY(Point, 4326)`).
  - `providerController.js` L43-58 calcula la distancia al cliente usando únicamente `p.ubicacion`.
  - Si Ana trabaja en Chicó y en Chapinero, Pre-Nodo 01 **no puede expresar dos ubicaciones físicas distintas** para el mismo `provider_id`.

---

### SEM-Q08 — Mismo Servicio / Varias Sedes
```text
Sede A (Chicó)      ──> Corte de cabello ($45.000)
Sede B (Chapinero)  ──> Corte de cabello ($45.000)
```
* **Estado:** **`PARTIALLY_SUPPORTED`**
* **Evidencia Física:** En B2C se crean servicios asociados a los prestadores de cada sede. Sin embargo, el marketplace B2C no agrupa ni identifica los servicios por sede u organización; solo los muestra por proximidad GPS individual del prestador.

---

### SEM-Q09 — Mismo Profesional / Mismo Servicio / Horarios Diferentes
```text
Ana ──┬──> Sede A ──> Corte ──> Lunes 08:00–12:00
      └──> Sede B ──> Corte ──> Lunes 14:00–18:00
```
* **Estado:** **`NOT_SUPPORTED`** en el modelo B2C actual.
* **Evidencia Física:**
  - `backend/src/controllers/providerController.js` L221-235: `weekly_schedule` en `perfiles_prestador` es una estructura JSON plana por día (`lunes: { inicio: 8, fin: 20 }`).
  - No admite segmentar un mismo día en diferentes sedes o ubicaciones.

---

### SEM-Q10 — Mismo Servicio / Varios Profesionales / Diferentes Capacidades
```text
Sede A ──┬──> Ana    (Disponible)
         ├──> Carlos (Disponible)
         └──> Pedro  (No Disponible / Sin Capacidad)
```
* **Estado:** **`SUPPORTED WITH CONDITIONAL ASSIGNMENT`**
* **Evidencia Física:** En SaaS, Pedro no tiene la categoría en `assigned_categories`. En B2C, simplemente no se genera una fila en `public.services` con `provider_id = Pedro_id`, o su servicio tiene `is_active = false`.

---

### SEM-Q11 — Elementos Mínimos de Booking
Evaluación física en [`backend/init.sql`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/init.sql#L96-L101):
* **`CLIENT`**: **`REQUIRED`** (`client_id INTEGER NOT NULL REFERENCES usuarios(id)`).
* **`SERVICE`**: **`REQUIRED`** (`service_id UUID NOT NULL REFERENCES services(id)`).
* **`PROFESSIONAL`**: **`REQUIRED`** (`provider_id INTEGER NOT NULL REFERENCES perfiles_prestador(id)`).
* **`ESTABLISHMENT`**: **`ABSENT`** en BD física (En SaaS sería conceptualmente **`DERIVED`** de la sede del prestador/servicio).
* **`TIME`**: **`REQUIRED`** (`scheduled_at TIMESTAMPTZ NOT NULL`).

---

## 7. IDENTIDAD VS CONTEXTO

| Nivel Conceptual | Definición Semántica | Identificador / Expresión Física |
| :--- | :--- | :--- |
| **Identidad del Servicio** | La definición abstracta del procedimiento (nombre, categoría base, descripción técnica). | `relevant_services.name` / `category` |
| **Oferta** | La publicación comercial del servicio en una sede a un precio y duración determinados. | `relevant_services` en Context Package de la Sede |
| **Capacidad** | La aptitud técnica de una persona para realizar esa categoría de servicios. | `people_initial_roles.assigned_categories` |
| **Asignación** | La habilitación explícita de un profesional para ejecutar la oferta en esa sede. | `people_initial_roles` $\cap$ `relevant_services` |
| **Ejecución** | La concurrencia válida de Servicio, Profesional y Sede en un slot libre. | Cálculo de disponibilidad en `providerController.getProviderSlots` |
| **Reserva** | El registro transaccional que bloquea el slot y vincula al cliente. | Fila en `public.bookings` |

---

## 8. MATRIZ SEMÁNTICA CANÓNICA

| Concepto | Representación Actual | Entidad / Campo | Estado | Observación |
| :--- | :--- | :--- | :---: | :--- |
| **Capability** | Categorías asignadas / portafolio | `people_initial_roles.assigned_categories` / `portafolio_servicios` | **PARCIAL** | En SaaS es contextual a la sede; en B2C es personal. |
| **Offer** | Catálogo en memoria / Servicios en BD | `relevant_services` (SaaS) / `public.services` (B2C) | **FUSIONADA** | En B2C la oferta está fusionada al prestador individual. |
| **Assignment** | Mapeo por categoría / FK directa | `people_initial_roles` (SaaS) / `services.provider_id` (B2C) | **FUSIONADA** | No existe tabla relacional intermedia N-a-N en B2C. |
| **Execution** | Tupla operativa en runtime | `provider_id` + `service_id` + `scheduled_at` | **ACOPLADA** | Requiere prestador individual obligatorio. |
| **Booking** | Registro de cita | `public.bookings` | **OPERATIVA** | Conoce cliente, prestador y servicio; desconoce sede. |
| **Professional** | Miembro de sede / Usuario prestador | `memberships` (`role = 'PROFESSIONAL'`) / `usuarios` | **DESACOPLADA** | Dominios desconectados. |
| **Establishment** | Sede física multitenant | `establishments` | **AISLADA SAAS** | Inexistente en tablas transaccionales B2C. |
| **Service** | Registro de catálogo | `public.services` | **INDIVIDUAL** | 1 servicio pertenece exactamente a 1 prestador. |

---

## 9. DECISIONES SEMÁNTICAS

### SEM-DEC-001 — Unidad Semántica Dominante de Handover
* **Conclusión:** La unidad semántica dominante que debe preservarse al pasar de SaaS hacia Pre-Nodo 01 es:
  ```text
  ESTABLISHMENT + PROFESSIONAL + SERVICE  (Unidad de Asignación / Ejecución)
  ```
* **Fundamento:** En SaaS la oferta nace en el `Establishment` con staff capacitado (`Professional`). Para ingresar al motor B2C inmutable, debe resolverse la terna `(Sede, Profesional, Servicio)` para instanciar el binomio operativo `(Provider, Service)` que Pre-Nodo 01 requiere.

---

### SEM-DEC-002 — Estado de la Relación `SERVICE ↔ PROFESSIONAL ↔ ESTABLISHMENT`
* **Evaluación:** **`C. FUSIONADO EN ENTIDADES EXISTENTES (y parcialmente contradictorio entre planos)`**.
* **Evidencia:**
  - En B2C, la relación está rígidamente fusionada en `services.provider_id`, omitiendo por completo el `establishment_id`.
  - En SaaS, está modelada en memoria en el `Context Package` (`relevant_services` + `people_initial_roles`), pero no tiene persistencia relacional (`NEW TABLES = 0`).

---

### SEM-DEC-003 — Evaluación de `DEC-SE-001` y `DEC-SE-002` Previos
* **`DEC-SE-001` (Duplicación por Staff vs. Host Delegado):** **`NOT RESOLVED — PENDING DIRECTOR DECISION`**.
  - *Evidencia aportada:* La duplicación física por staff (`Opción A`) es la única forma comprobada de permitir a múltiples profesionales tener slots independientes en Pre-Nodo 01 sin modificar esquemas protegidos.
* **`DEC-SE-002` (Herencia de Ubicación/Horarios de Sede):** **`NOT RESOLVED — PENDING DIRECTOR DECISION`**.
  - *Evidencia aportada:* La limitación física de `perfiles_prestador` (1 sola ubicación GPS y 1 solo horario semanal) impide de forma nativa que un prestador opere simultáneamente en múltiples sedes con horarios partidos (SEM-Q07 y SEM-Q09).

---

## 10. LIMITATIONS

1. Este informe se limita a documentar el estado semántico y físico existente. **No autoriza ni ejecuta cambios de código o esquema.**
2. Las limitaciones en escenarios multi-sede para un mismo prestador (SEM-Q07, SEM-Q09) son restricciones estructurales del esquema heredado de Pre-Nodo 01 (`perfiles_prestador`).

---

## 11. PROTECTED ASSETS INTEGRITY

Permanecen estrictamente intactos:
- `SaaS Foundation v1.0` (`065_saas_foundation_core.sql`, `066_context_resolution_tenant_resolver.sql`, `fn_resolve_user_tenant`)
- `Context Resolution v1.0`
- `Active Context v1.0`
- `Hub Salón v1.0`
- `Crear Desde Cero v1.0`
- `Pre-Nodo 01` (Core B2C inmutable)
- `SOUL` / `Governance` / `NCP Core`

---

## 12. GIT INTEGRITY

Verificación mediante `git status --short`:
- `0 runtime modifications`
- `0 database modifications`
- `0 migrations`
- `0 protected asset modifications`
- Único archivo creado: [`/ncp/SERVICE-EXECUTION-SEMANTIC-MODEL-DISCOVERY-REPORT-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/SERVICE-EXECUTION-SEMANTIC-MODEL-DISCOVERY-REPORT-v1.0.md).

---

## 13. DIRECTOR DECISION REQUIRED

Se solicita pronunciamiento formal del Director sobre:
1. Aprobación del presente informe de descubrimiento semántico.
2. Definición formal de la estrategia de resolución para `DEC-SE-001` (Política de catálogo multi-prestador) y `DEC-SE-002` (Sincronización de ubicación/horarios de sede).
3. Autorización para avanzar a la fase de diseño del contrato arquitectónico de **`NODO 01`**.

---

## 14. ESTADO FINAL

```text
================================================================================
ESTADO FINAL:
DISCOVERY COMPLETE / PENDING DIRECTOR ARCHITECTURAL REVIEW 🟡
================================================================================
```
