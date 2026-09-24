# SERVICE EXECUTION SEMANTIC DISCOVERY REPORT v1.0
## Descubrimiento Semántico de la Unidad Operacional: Sede, Servicio, Profesional y Reserva

**Versión:** 1.0.0  
**Estado:** DISCOVERY COMPLETE / PENDING DIRECTOR ARCHITECTURAL REVIEW 🟡  
**Autoridad:** Director del Proyecto GlowApp SaaS  
**Carácter:** Read-Only Architectural Discovery (Cero Modificaciones a Código, BD o Nodos Protegidos)

---

## 1. EXECUTIVE SUMMARY

El presente informe formaliza el descubrimiento arquitectónico de la **unidad operacional real** que rige la ejecución de servicios y la creación de reservas en GlowApp, comparando el modelo organizacional multitenant del plano **SaaS** con el modelo transaccional de **Pre-Nodo 01 (Core B2C)**.

### Hallazgos Principales:
1. **Unidad Operacional Dominante en B2C:** En Pre-Nodo 01, la unidad operacional indivisible es el binomio **`PROVIDER + SERVICE`** (`perfiles_prestador` + `public.services`). Toda consulta de catálogo, cálculo de turnos (`slots`) y reserva (`bookings`) exige obligatoriamente ambos identificadores.
2. **Representación de `services`:** Físicamente, un registro en `public.services` representa una **oferta personal exclusiva de un prestador individual** (`provider_id INTEGER NOT NULL`). No representa un servicio de sede ni un catálogo global compartido.
3. **Escenario Multi-Profesional:** Pre-Nodo 01 **no soporta de forma nativa** que un único registro de servicio sea ejecutado por múltiples profesionales. Para que $N$ profesionales ofrezcan el mismo servicio en una sede bajo el modelo B2C actual, el servicio debe existir duplicado físicamente en $N$ filas de `public.services`.
4. **Desconexión de Sedes en Reservas:** La tabla `public.bookings` desconoce totalmente la existencia de `establishments` y `organizations`. Las reservas se ejecutan exclusivamente en la relación `CLIENTE → PROVIDER (con un SERVICE específico)`.
5. **Separación Conceptual:** Existe una brecha entre la **Oferta de Sede** (`relevant_services` en SaaS) y la **Ejecución del Servicio** (`public.services.provider_id` en B2C), requiriendo una política explícita de ingestión en el diseño de Nodo 01.

---

## 2. EVIDENCE BOUNDARY

### Fuentes Físicas Auditadas:
- **Esquema B2C:** [`backend/init.sql`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/init.sql) (Líneas 59-120: tablas `perfiles_prestador`, `services`, `bookings`).
- **Modelos Sequelize:** [`backend/src/models/index.js`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/models/index.js) (`Service.belongsTo(User, { foreignKey: 'provider_id' })`, `Booking.belongsTo(Service)`).
- **Controladores de Ejecución B2C:**
  - [`backend/src/controllers/serviceController.js`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/controllers/serviceController.js) (`getProviderServices`, `createService`, `updateService`).
  - [`backend/src/controllers/providerController.js`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/controllers/providerController.js) (`getProviders`, `getProviderSlots`).
  - [`backend/src/controllers/bookingController.js`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/src/controllers/bookingController.js) (`createBooking`, `getProviderBookings`, `getClientBookings`).
- **SaaS Foundation:** [`backend/migrations/065_saas_foundation_core.sql`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/backend/migrations/065_saas_foundation_core.sql) (Tablas `tenants`, `organizations`, `establishments`, `memberships`).
- **Contratos NCP:** `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md` y reportes de discovery previos.

---

## 3. SERVICE REPRESENTATION (SE-Q01)

### Pregunta: ¿Qué representa actualmente `services`?
* **Respuesta:** **`C — Servicio de un Provider`** (personal e individual).

### Evidencia Física:
1. **Esquema BD (`backend/init.sql` L83-93):**
   ```sql
   CREATE TABLE services (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     provider_id INTEGER NOT NULL REFERENCES perfiles_prestador(id) ON DELETE CASCADE,
     name VARCHAR(255) NOT NULL,
     description TEXT,
     price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
     duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
     category VARCHAR(50),
     is_active BOOLEAN DEFAULT TRUE,
     created_at TIMESTAMPTZ DEFAULT NOW()
   );
   ```
2. **Controlador (`serviceController.js` L11-13, L56-64):**
   - `Service.findAll({ where: { provider_id: req.user.id } })`
   - `Service.create({ provider_id: req.user.id, ... })`
3. **ORM Sequelize (`models/index.js` L24-25):**
   - `Service.belongsTo(User, { foreignKey: 'provider_id', as: 'provider' })`

**Conclusión:** Un registro en `public.services` no es una plantilla ni un ítem de catálogo de sede; es una oferta concreta y propia de un prestador específico.

---

## 4. BOOKING REPRESENTATION (SE-Q02)

### Pregunta: ¿Qué representa actualmente `bookings`?
* **Respuesta:** La unidad de reserva real es la tupla:
  ```text
  CLIENTE + SERVICIO + PROVIDER + TIEMPO
  ```

### Evidencia Física:
1. **Esquema BD (`backend/init.sql` L96-101):**
   - `client_id INTEGER NOT NULL REFERENCES usuarios(id)`
   - `provider_id INTEGER NOT NULL REFERENCES perfiles_prestador(id)`
   - `service_id UUID NOT NULL REFERENCES services(id)`
   - `scheduled_at TIMESTAMPTZ NOT NULL`
2. **Controlador (`bookingController.js` L56-66, L123-147):**
   - Se valida que `service_id` pertenezca al `provider_id`:
     `Service.findAll({ where: { id: service_ids, provider_id } })`
   - La comprobación de solapamiento de horarios (collision check) se ejecuta contra `overlaps = Booking.findAll({ where: { provider_id, scheduled_at } })`.

**Conclusión:** La reserva conceptual actual es estrictamente `CLIENTE → PROVIDER (con un SERVICE específico)`. No existe en el sistema la posibilidad de reservar en una sede sin especificar el prestador.

---

## 5. PROVIDER REPRESENTATION (SE-Q03)

### Pregunta: ¿Qué representa actualmente `perfiles_prestador`?
* **Respuesta:** Representa una **PERSONA PROFESIONAL / PRESTADOR AUTÓNOMO INDIVIDUAL**, conteniendo una mezcla histórica de:
  - **Identidad/Fiscal:** `id` (FK a `usuarios.id`), `documento_id_url`, `rut_url`, `certificacion_url`.
  - **Reputación Personal:** `rating_avg`, `rating_count`.
  - **Micro-Comercial:** `business_name`, `description`, `portafolio_servicios`.
  - **Micro-Logística:** `ubicacion` (`GEOGRAPHY(Point, 4326)`), `is_online`.
  - **Disponibilidad:** `active_start_hour`, `active_end_hour`, `weekly_schedule`.
  - **Fintech:** `metodo_retiro`, `numero_cuenta_nequi`, `documento_titular`.

**Conclusión:** `perfiles_prestador` no modela una sede física comercial ni una persona jurídica; modela exclusivamente las capacidades operativas de un individuo.

---

## 6. SERVICE → PROVIDER RELATIONSHIP (SE-Q04)

```text
services.provider_id ──(FK NOT NULL)──> perfiles_prestador.id ──(PK/FK)──> usuarios.id
```
- **Cardinalidad:** $N$ servicios pertenecen a $1$ provider. ($1$ servicio pertenece exactamente a $1$ provider).
- **Integridad Referencial:** `ON DELETE CASCADE` (si el provider es eliminado, todos sus servicios se eliminan automáticamente).
- **Control de Creación/Edición:** `serviceController.js` fuerza que el `provider_id` coincida con el usuario autenticado (`req.user.id`).

---

## 7. PROVIDER → ESTABLISHMENT RELATIONSHIP (SE-Q05)

- **En el plano Pre-Nodo 01 (B2C):** **0 Establecimientos**. La tabla `perfiles_prestador` no posee FK, columna ni join hacia `establishments`.
- **En el plano SaaS Foundation:** Un usuario puede tener membresías en **$N$ Establecimientos** (`memberships.establishment_id`).
- **Conclusión:** La vinculación de un prestador a una sede existe únicamente en el plano SaaS (`memberships`), pero es completamente inexistente en el plano físico de B2C.

---

## 8. SERVICE → ESTABLISHMENT RELATIONSHIP (SE-Q06)

* **Clasificación:** **`NONE`**
* **Evidencia:** `public.services` no tiene `establishment_id` ni `tenant_id`. Tampoco existe relación indirecta a través de `perfiles_prestador`. El catálogo B2C desconoce por completo el concepto de sede física.

---

## 9. SERVICE → PROFESSIONAL RELATIONSHIP (SE-Q07)

* **Relación Existente:** La relación es exclusivamente `SERVICE → PROVIDER`.
* **Multiplicidad:** El modelo actual **NO permite** que `SERVICE X` sea asignado a `PROFESIONAL A, B, C` de forma compartida. No existe tabla relacional `service_professionals` ni estructura de asignación dinámica.

---

## 10. MULTI-PROFESSIONAL SCENARIO (SE-Q08)

### Escenario:
Sede A ofrece "Corte de Cabello" y cuenta con Ana, Carlos y Pedro como profesionales asignados.

### Representación en el Modelo Físico Actual:
* **Clasificación:** **`SUPPORTED WITH DUPLICATION`** (Soportado mediante replicación de filas).
* **Estructura Requerida en `public.services`:**
  1. Fila 1: `id = UUID_1, provider_id = Ana_id, name = 'Corte de Cabello', price = 45000, duration = 45`
  2. Fila 2: `id = UUID_2, provider_id = Carlos_id, name = 'Corte de Cabello', price = 45000, duration = 45`
  3. Fila 3: `id = UUID_3, provider_id = Pedro_id, name = 'Corte de Cabello', price = 45000, duration = 45`

Cada cliente agenda contra el servicio y provider específico del profesional seleccionado.

---

## 11. MULTI-ESTABLISHMENT SCENARIO (SE-Q09)

### Escenario:
Organización cuenta con Sede Chicó y Sede Chapinero, ambas ofreciendo "Corte de Cabello".

### Comportamiento en Pre-Nodo 01:
* **Clasificación:** **`NOT SUPPORTED (Sin distinción de sede)`**.
* **Evidencia:** B2C solo ve los prestadores individuales y sus coordenadas GPS. Si dos prestadores pertenecen a sedes distintas pero están en la misma zona geográfica, el marketplace B2C los lista según su distancia (`ST_Distance`) sin agruparlos ni identificarlos por sede física.

---

## 12. SERVICE IDENTITY (SE-Q10)

### Evidencia Física:
- `backend/init.sql` L84: `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`.
- No existen restricciones únicas compuestas (por ejemplo, `UNIQUE (provider_id, name)` no existe).

### Conclusión de Identidad:
La identidad de un servicio en Pre-Nodo 01 está determinada **exclusivamente por su clave primaria física `id UUID`**. Dos filas con el mismo `name`, `category`, `price` y `duration_minutes` son consideradas servicios totalmente independientes si poseen distinto `id` o distinto `provider_id`.

---

## 13. CAPABILITY VS OFFER VS ASSIGNMENT VS BOOKING (SE-Q11)

| Concepto | Definición Semántica | Presencia en Plano SaaS | Presencia en Plano B2C |
| :--- | :--- | :---: | :---: |
| **Capacidad Profesional** | Habilidad técnica de un colaborador para ejecutar una categoría. | `people_initial_roles.assigned_categories` | `perfiles_prestador.portafolio_servicios` |
| **Oferta de Servicio** | Catálogo comercial intencionado disponible en la sede. | `relevant_services` (En memoria) | `public.services` (Filas en BD) |
| **Asignación de Servicio** | Vinculación explícita de qué colaborador ejecuta qué servicio. | `people_initial_roles` $\leftrightarrow$ `activities` | **INEXISTENTE** (Fusionada rígidamente en `provider_id`) |
| **Reserva (Booking)** | Compromiso transaccional cliente-prestador en un slot de tiempo. | No aplica (Fuera de alcance SaaS) | `public.bookings` (Tabla física) |

---

## 14. CURRENT OPERATIONAL UNIT (SE-Q12)

Con base estricta en la evidencia física analizada:

```text
================================================================================
                     UNIDAD OPERACIONAL DOMINANTE EN B2C
================================================================================
                    D — PROVIDER + SERVICE (Binomio Indivisible)
================================================================================
```

Toda la operativa downstream (búsqueda en directorio, consulta de slots, solapamiento de horarios, cálculo de comisiones Wompi y verificación por PIN) está construida asumiendo la existencia simultánea y acoplada de un `provider_id` y un `service_id`.

---

## 15. HECHOS CONFIRMADOS (CONFIRMED FACTS)

1. `public.services` exige siempre un `provider_id` individual no nulo.
2. `public.bookings` exige `client_id`, `provider_id` y `service_id` no nulos.
3. No existe `establishment_id` en las tablas operativas B2C (`services`, `bookings`, `perfiles_prestador`).
4. Pre-Nodo 01 no dispone de un concepto de catálogo compartido por sede sin duplicación de filas.
5. El Context Package de Crear Desde Cero modela la intención a nivel de sede y staff, desacoplada de la persistencia B2C.

---

## 16. INCÓGNITAS (UNKNOWNS)

1. ¿Si la sede física cambia de dirección u horarios, cómo deben actualizarse las coordenadas y horarios en los `perfiles_prestador` de sus colaboradores vinculados?
2. ¿Qué ocurre si un colaborador renuncia o es revocado de la sede (`memberships.status = 'REVOKED'`) con respecto a sus filas en `public.services` y reservas pendientes?

---

## 17. BRECHAS ARQUITECTÓNICAS (ARCHITECTURAL GAPS)

1. **Brecha de Asignación de Servicios:** Falta un mecanismo que relacione los servicios del Context Package con los prestadores B2C sin forzar un rediseño invasivo de Pre-Nodo 01.
2. **Brecha de Identidad de Catálogo de Sede:** Pre-Nodo 01 trata cada duplicado de servicio como un ente aislado, sin agruparlos bajo un concepto de "Servicio de la Sede X".
3. **Brecha de Geolocalización de Sede vs. Prestador:** B2C busca por la ubicación personal del prestador, mientras que SaaS define la ubicación de la sede física (`establishments.location`).

---

## 18. DECISION GATES (ARCHITECTURAL STOP)

### DEC-SE-001 — ESTRATEGIA DE REPRESENTACIÓN DE CATÁLOGO MULTI-PRESTADOR
```text
================================================================================
                              ARCHITECTURAL_STOP 🔴
================================================================================
GOAL ID           : SERVICE-EXECUTION-SEMANTIC-DISCOVERY-v1.0
NODE ID           : SAAS-TO-B2C-SERVICE-EXECUTION
AGENTE EMISOR     : DISCOVERY_ENGINE
--------------------------------------------------------------------------------
1. PROBLEMA       : Pre-Nodo 01 solo admite 1 provider_id por fila en public.services.
                    Una sede puede tener N profesionales para el mismo servicio.
2. EVIDENCIA      : backend/init.sql línea 85 (provider_id NOT NULL REFERENCES perfiles_prestador).
3. IMPACTO        : Determina la política de instanciación en el receptor de ingestión.
4. OPCIONES       : 
   A) Duplicación por Staff Asignado (Replicación de Filas): La ingestión crea una fila en public.services por cada profesional asignado a la categoría en people_initial_roles.
   B) Host Delegado (Fila Única por Sede): La ingestión crea una sola fila en public.services asignada al Owner/Manager, quien actúa como anfitrión de la sede en B2C.
5. RECOMENDACIÓN  : Opción A (Duplicación por Staff Asignado) [PROPUESTA — NO APROBADA], ya que permite a los clientes seleccionar al profesional específico y calcular sus slots individuales de forma nativa en Pre-Nodo 01.
6. DECISIÓN REQ.  : Director debe aprobar la estrategia de instanciación física del catálogo.
================================================================================
```

### DEC-SE-002 — POLÍTICA DE GEOLOCALIZACIÓN Y HORARIOS EN INGESTIÓN
```text
================================================================================
                              ARCHITECTURAL_STOP 🔴
================================================================================
GOAL ID           : SERVICE-EXECUTION-SEMANTIC-DISCOVERY-v1.0
NODE ID           : SAAS-TO-B2C-SERVICE-EXECUTION
AGENTE EMISOR     : DISCOVERY_ENGINE
--------------------------------------------------------------------------------
1. PROBLEMA       : Pre-Nodo 01 calcula distancia y slots usando perfiles_prestador,
                    pero en SaaS las coordenadas y horarios pertenecen al establishment.
2. EVIDENCIA      : providerController.js líneas 43-46 (ST_Distance sobre p.ubicacion) y líneas 213-228.
3. IMPACTO        : Si perfiles_prestador no tiene las coordenadas y horarios de la sede, no aparecerá en búsquedas ni generará slots.
4. OPCIONES       : 
   A) Herencia Automática de Sede: La ingestión actualiza/sincroniza en perfiles_prestador las coordenadas (location) y horarios (operating_hours) de la sede física.
   B) Configuración Individual Obligatoria: El prestador debe ingresar independientemente a configurar su horario y GPS en su dashboard móvil.
5. RECOMENDACIÓN  : Opción A (Herencia Automática de Sede) [PROPUESTA — NO APROBADA].
6. DECISIÓN REQ.  : Director debe autorizar la sincronización de metadatos de sede en perfiles_prestador.
================================================================================
```

---

## 19. ACTIVOS PROTEGIDOS E INTEGRIDAD GIT

- **Activos Protegidos:** `Foundation v1.0`, `Context Resolution v1.0`, `Active Context v1.0`, `Hub Salón v1.0`, `Crear Desde Cero v1.0`, `Pre-Nodo 01`, `SOUL`, `Governance`, `NCP Core` permanecen **100% INTACTOS**.
- **Integridad Git:**
  - `0 runtime modifications`
  - `0 database modifications`
  - `0 migrations`
  - `0 protected asset modifications`
  - Único archivo creado: Este informe documental.

---

## 20. TABLA CANÓNICA DE RESULTADOS

| Relación | Evidencia Física | Estado Actual | Cardinalidad | Brecha Arquitectónica |
| :--- | :--- | :--- | :---: | :--- |
| **Establishment $\rightarrow$ Service** | `init.sql` / `065` | Inexistente en BD / En memoria en SaaS | 1 a $N$ (SaaS) / 0 (B2C) | Catálogo de sede desacoplado de BD |
| **Establishment $\rightarrow$ Provider** | `init.sql` / `065` | Inexistente en B2C / Vía `memberships` en SaaS | $N$ a $N$ (vía memberships) | Pre-Nodo 01 no relaciona prestadores con sedes |
| **Membership $\rightarrow$ Provider** | `065` / `init.sql` | Indirecta vía `usuarios.id` | 1 a 1 por usuario | Dominios desacoplados |
| **Service $\rightarrow$ Provider** | `init.sql` L85 | Acoplado rígidamente | $N$ services a 1 provider | Incompatible con multi-prestador por fila |
| **Service $\rightarrow$ Professional** | `init.sql` L85 | Fusionado en `provider_id` | 1 a 1 | No existe asignación dinámica $N$ a $N$ |
| **Provider $\rightarrow$ Booking** | `init.sql` L99 | Obligatorio (`NOT NULL`) | 1 provider a $N$ bookings | Operativo en B2C |
| **Service $\rightarrow$ Booking** | `init.sql` L100 | Obligatorio (`NOT NULL`) | 1 service a $N$ bookings | Operativo en B2C |
| **Establishment $\rightarrow$ Booking** | `init.sql` L96-120 | Inexistente | 0 | B2C desconoce sedes en reservas |

---

## 21. DIRECTOR DECISION REQUIRED

Se solicita pronunciamiento formal del Director sobre:
1. Aprobación del presente Discovery Report.
2. Resolución de los Decision Gates `DEC-SE-001` y `DEC-SE-002`.
3. Determinación de los requerimientos para proceder con la definición formal del Node Contract de **`NODO 01`**.

---

## 22. ESTADO FINAL

```text
================================================================================
ESTADO:
DISCOVERY COMPLETE / PENDING DIRECTOR ARCHITECTURAL REVIEW 🟡
================================================================================
```
