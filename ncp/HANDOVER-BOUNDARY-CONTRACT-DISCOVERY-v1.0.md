# HANDOVER BOUNDARY CONTRACT DISCOVERY REPORT v1.0
## Descubrimiento del Contrato en la Frontera de Handover: SaaS → Pre-Nodo 01

**Versión:** 1.0.0  
**Estado:** DISCOVERY COMPLETE / PENDING DIRECTOR ARCHITECTURAL REVIEW 🟡  
**Autoridad:** Director del Proyecto GlowApp SaaS  
**Carácter:** Read-Only Architectural Discovery (Cero Modificaciones a Código, BD o Nodos Protegidos)

---

## 1. PURPOSE

El propósito de este informe es determinar con exactitud qué información mínima, suficiente y semánticamente correcta debe cruzar la frontera:

```text
SAAS COCKPIT (HUB / CREAR DESDE CERO)
              ↓
   HANDOVER BOUNDARY (DTO)
              ↓
     RECEPTOR DOWNSTREAM
              ↓
   PRE-NODO 01 (CORE B2C INMUTABLE)
```

sin otorgar autoridad de negocio indebida al frontend, al transporte o al adaptador, y garantizando la integridad de los dominios organizacionales y transaccionales.

---

## 2. SCOPE

### Fuentes Físicas Auditadas:
- **Plano SaaS:**
  - `backend/migrations/065_saas_foundation_core.sql` (`organizations`, `establishments`, `memberships`).
  - `backend/src/services/crearDesdeCeroService.js` (Lógica de ensamblaje de `Context Package`).
  - `backend/src/controllers/crearDesdeCeroController.js` (Endpoint `POST /bootstrap`).
  - `backend/src/routes/crearDesdeCeroRoutes.js`.
- **Plano Pre-Nodo 01 (Core B2C):**
  - `backend/init.sql` (`usuarios`, `perfiles_prestador`, `services`, `bookings`).
  - `backend/src/controllers/serviceController.js`.
  - `backend/src/controllers/providerController.js`.
  - `backend/src/controllers/bookingController.js`.
- **Informes de Discovery Previos:**
  - `SERVICE-EXECUTION-SEMANTIC-DISCOVERY-REPORT-v1.0.md`
  - `SERVICE-EXECUTION-SEMANTIC-MODEL-DISCOVERY-REPORT-v1.0.md`

---

## 3. SEMANTIC BOUNDARY

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        PLANO SAAS (AUTORIDAD B2B)                      │
│                                                                        │
│  - Autoridad de Tenancy: tenant_id, organization_id                    │
│  - Autoridad de Sede: establishments (location, operating_hours)       │
│  - Autoridad de Staff: memberships (role, status, relation_type)       │
│  - Autoridad de Catálogo de Sede: relevant_services (oferta comercial)│
│  - Autoridad de Asignación: people_initial_roles.assigned_categories   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    │ HANDOVER BOUNDARY
                                    │ (Mínimo Handover Package)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   PLANO CORE B2C (PRE-NODO 01 INMUTABLE)               │
│                                                                        │
│  - Autoridad de Identidad Base: usuarios.id                            │
│  - Autoridad Operativa de Prestador: perfiles_prestador                │
│  - Autoridad de Catálogo Personal: public.services (provider_id)       │
│  - Autoridad de Agenda y Transacciones: public.bookings                │
│  - Autoridad de Disponibilidad: slots en tiempo real                   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 4. EVIDENCE

Todas las conclusiones se fundamentan en evidencia directa de archivos y funciones existentes.

---

## 5. PREGUNTAS CANÓNICAS (HB-Q01 → HB-Q04)

### HB-Q01 — IDENTIDAD
* **Pregunta:** ¿Qué identidad SaaS puede ser relacionada legítimamente con `usuarios.id` y `perfiles_prestador.id`?
* **Evidencia Física:**
  - `backend/migrations/065_saas_foundation_core.sql` L76, L86-87: `memberships.user_id INTEGER NOT NULL REFERENCES usuarios(id, tenant_id)`.
  - `backend/init.sql` L43-44: `CREATE TABLE usuarios (id SERIAL PRIMARY KEY, ...)`.
  - `backend/init.sql` L60: `CREATE TABLE perfiles_prestador (id INTEGER PRIMARY KEY REFERENCES usuarios(id) ...)`.
  - `backend/src/services/crearDesdeCeroService.js` L146: `user_id: staff.user_id`.
* **Conclusión:** El único identificador canónico, estable e interoperable es **`usuarios.id`** (`INTEGER`). `membership_id` (`UUID`) es un identificador relacional interno del plano SaaS y no existe en B2C.

---

### HB-Q02 — ESTABLISHMENT
* **Pregunta:** ¿Qué información del establecimiento necesita conocer Pre-Nodo 01 para una ejecución?
* **Análisis por Atributo:**
  - `establishment_id` (UUID): **`ABSENT_IN_B2C` / `DERIVED`**. Pre-Nodo 01 no almacena este ID, pero SaaS lo usa como raíz de contexto.
  - `organization_id` (UUID): **`NOT_REQUIRED` / `ABSENT_IN_B2C`**. Pertenece a la capa legal/fiscal SaaS; B2C no lo consume.
  - `nombre` (`name`): **`USEFUL`**. Útil para descripción comercial y recibos B2C.
  - `dirección` / `ciudad` (`address`, `city`): **`REQUIRED`**. Alimenta `service_address` en `bookings` (`init.sql` L109).
  - `coordenadas` (`location` Point 4326): **`REQUIRED`**. Es indispensable para alimentar `perfiles_prestador.ubicacion`, requerida por `providerController.js` para búsquedas PostGIS (`ST_DWithin`).
  - `horarios` (`operating_hours` JSONB): **`REQUIRED`**. Es indispensable para alimentar `perfiles_prestador.weekly_schedule`, requerida por `providerController.js` L213 para cálculo de slots.
  - `estado operativo` (`is_active`): **`DERIVED` / `USEFUL`**. Metadata operacional.

---

### HB-Q03 — PROFESSIONAL
* **Pregunta:** ¿Qué información mínima de un miembro SaaS es necesaria para que Pre-Nodo 01 identifique al profesional operativo?
* **Análisis:**
  - `user_id` (INTEGER): **`REQUIRED`**. Identifica a la persona en `usuarios`.
  - `membership_id` (UUID): **`NOT_REQUIRED en B2C`** (Interno del plano SaaS).
  - `role` (`PROFESSIONAL`, `OWNER`, `MANAGER`): **`REQUIRED en frontera`**. Para validar capacidad técnica (excluyendo `RECEPTIONIST`).
  - `relation_type`: **`NOT_REQUIRED en B2C`**.
  - `status` (`ACTIVE`): **`REQUIRED en frontera`**. Solo miembros activos pueden ser transferidos.
  - `provider_id`: **`DERIVED`** (`= user_id`).
  - `provider profile`: **`CONDITIONAL`** (Debe existir o instanciarse en `perfiles_prestador`).
  - `verification status`: **`REQUIRED en B2C`** (`estatus_verificacion = 'APROBADO'`).
  - `assigned_categories`: **`REQUIRED`**. Define las categorías que el profesional puede ejecutar.

---

### HB-Q04 — SERVICE
* **Pregunta:** ¿Qué información de `relevant_services` puede cruzar legítimamente hacia `services`?
* **Análisis:**
  - `name`: **`SOURCE OF TRUTH`** (Pasa directamente a `services.name`).
  - `description`: **`SOURCE OF TRUTH`** (Pasa a `services.description`).
  - `price`: **`SOURCE OF TRUTH`** (Pasa a `services.price`).
  - `duration_minutes`: **`SOURCE OF TRUTH`** (Pasa a `services.duration_minutes`).
  - `category`: **`SOURCE OF TRUTH`** (Pasa a `services.category`).
  - `is_active`: **`SOURCE OF TRUTH`** (`true`).
  - `provider_id`: **`MISSING en relevant_services`**. En SaaS el catálogo es de sede; en B2C `provider_id` debe asignarse en la frontera cruzando con `people_initial_roles.user_id`.
  - `establishment_id`: **`NOT REQUIRED en B2C` / `SOURCE OF TRUTH en SaaS`**.

---

## 6. ASIGNACIÓN (HB-Q05 → HB-Q06)

### HB-Q05 — Presencia de la Triple Relación en el Context Package
En el Context Package actual:
- `ESTABLISHMENT`: **`EXPLICIT`** (`context_package.establishments`).
- `PROFESSIONAL`: **`EXPLICIT`** (`context_package.people_initial_roles`).
- `SERVICE`: **`EXPLICIT`** (`context_package.relevant_services`).
- `ESTABLISHMENT + PROFESSIONAL`: **`EXPLICIT`** (Todos los miembros pertenecen a la sede activa).
- `ESTABLISHMENT + SERVICE`: **`EXPLICIT`** (Todos los servicios pertenecen al catálogo de la sede activa).
- `PROFESSIONAL + SERVICE`: **`IMPLICIT / DERIVED`** (Mediante la coincidencia entre `relevant_services.category` y `people_initial_roles.assigned_categories`).

---

### HB-Q06 — Distinción de Sedes
- **En el plano SaaS (Context Package):** **SÍ contiene suficiente información**. `Sede A + Ana + Corte` y `Sede B + Ana + Corte` se distinguen inequívocamente por `establishment_id`, `establishment_name` y `address`.
- **En el plano B2C físico actual:** **NO se pueden distinguir** porque Pre-Nodo 01 no almacena `establishment_id` y `perfiles_prestador` solo admite una ubicación GPS por prestador.

---

## 7. EJECUCIÓN (HB-Q07)

Datos mínimos que Pre-Nodo 01 necesita para identificar una ejecución válida:
- `CLIENT`: **`REQUIRED`** (`client_id` en `bookings`).
- `ESTABLISHMENT`: **`ABSENT en B2C`** (En SaaS es **`REQUIRED`** como contexto de sede).
- `PROFESSIONAL`: **`REQUIRED`** (`provider_id` en `bookings`).
- `SERVICE`: **`REQUIRED`** (`service_id` en `bookings`).
- `TIME`: **`REQUIRED`** (`scheduled_at` en `bookings`).

---

## 8. BOOKING (HB-Q08)

1. **Datos que llegan desde SaaS:** `relevant_services` (catálogo de sede), `people_initial_roles` (staff asignado), `establishments` (ubicación y horarios).
2. **Datos propios de Pre-Nodo 01:** `client_id`, `pin_verificacion`, `comision_plataforma`, `impuestos_estado`, `pago_neto_prestador`, `payment_status`.
3. **Datos derivados durante la reserva:** `scheduled_at` (slot elegido por cliente), `valor_bruto`, colisiones de turnos.
4. **Datos que NO forman parte del handover de aprovisionamiento:** Datos transaccionales de clientes, PINs, pagos o turnos individuales. El handover transfiere **capacidad y catálogo**, no reservas.

---

## 9. MATRIZ DE AUTORIDAD (HB-Q09)

| Dominio de Información | Autoridad SaaS | Autoridad Pre-Nodo 01 | Justificación Técnica basada en Evidencia |
| :--- | :---: | :---: | :--- |
| **Establishment** | **X** | | Entidad multitenant custodiada por Foundation y RLS. |
| **Professional membership** | **X** | | Entidad SaaS custodiada por `memberships` y roles. |
| **Provider (Perfil B2C)** | | **X** | Entidad de Pre-Nodo 01 (`perfiles_prestador`). |
| **Service offer (Catálogo de Sede)**| **X** | | Definido en memoria en `Context Package`. |
| **Service execution (Fila en BD)** | | **X** | Fila en `public.services` vinculada a `provider_id`. |
| **Booking (Reserva B2C)** | | **X** | Tabla transaccional B2C (`public.bookings`). |
| **Location (Coordenadas de Sede)** | **X** | | `establishments.location` (Point 4326). |
| **Schedule (Horarios de Sede)** | **X** | | `establishments.operating_hours` (JSONB). |

---

## 10. TRANSPORTE VS SEMÁNTICA (HB-Q10)

```text
┌─────────────────┬───────────────────────────────────────────────────────────────────────┐
│ Dimensión       │ Definición y Alcance en la Frontera                                  │
├─────────────────┼───────────────────────────────────────────────────────────────────────┤
│ SEMÁNTICA       │ Significado formal: Intención de catálogo de sede + staff asignado.  │
│ TRANSPORTE      │ Protocolo de paso de datos: Payload JSON vía HTTP POST.               │
│ TRANSFORMACIÓN  │ Mapeo del DTO de sede a entidades individuales de Pre-Nodo 01.        │
│ INGESTIÓN       │ Validación de contrato y aceptación en la frontera downstream.       │
│ PERSISTENCIA    │ Escritura física en public.services y perfiles_prestador.             │
│ ACTIVACIÓN      │ Puesta en línea en el marketplace B2C (is_active = true, slots).      │
└─────────────────┴───────────────────────────────────────────────────────────────────────┘
```

---

## 11. FRONTEND Y AUTORIDAD (HB-Q11)

* **Captura de Intención:** El frontend es el medio interactivo por el cual el operador selecciona actividades, servicios y colaboradores.
* **Autoridad de Negocio:** **CERO AUTORIDAD EN EL FRONTEND**.
  - Toda la autoridad de tenancy, identidad, membresía y rol es resuelta exclusivamente por el servidor (`authMiddleware`, `activeContextMiddleware`, `fn_resolve_user_tenant`).
  - El frontend no puede autenticar ni alterar las reglas de negocio durante el handover.

---

## 12. MÍNIMO HANDOVER PACKAGE (PROPUESTA SEMÁNTICA)

El paquete que cruza la frontera debe contener **únicamente los elementos necesarios para la ingestión**, excluyendo metadatos de auditoría interna de SaaS:

| Atributo Semántico | Necesario | Fuente en SaaS | Semántica / Destino Downstream |
| :--- | :---: | :--- | :--- |
| **`establishment_context`** | **SÍ** | `establishments` | `{ id, name, city, address, location, operating_hours }` $\rightarrow$ Contexto de ubicación y horarios. |
| **`service_offers`** | **SÍ** | `relevant_services` | `[{ name, category, duration_minutes, price, description }]` $\rightarrow$ Catálogo a ofertar. |
| **`assigned_staff`** | **SÍ** | `people_initial_roles` | `[{ user_id, role, assigned_categories }]` $\rightarrow$ Profesionales activos autorizados. |
| **`authorizing_identity`** | **SÍ** | `identity` | `{ id, role }` $\rightarrow$ Identidad autorizadora (Owner/Manager). |
| **`state`** | **SÍ** | `state` | `READY_FOR_PRE_NODE_01` $\rightarrow$ Condición habilitante. |

> **Atributos Excluidos de la Ingestión:**  
> `organization`, `known_evidence`, `applicable_rules`, `conditions`, `procedures`, `dependencies`, `route`, `entry_state` se excluyen de la transferencia operativa por ser metadatos de auditoría y gobernanza interna de SaaS.

---

## 13. ANTI-SCOPE (LIMITACIONES ESTRICTAS)

Este documento **NO DECIDE NI AUTORIZA**:
- Cómo crear o modificar registros en `perfiles_prestador`.
- Cómo duplicar o mapear filas en `public.services`.
- Cómo alterar el esquema o lógica de `public.bookings`.
- La creación de adaptadores de ingestión, migraciones o endpoints downstream.

---

## 14. DECISION GATES

### HB-DEC-001 — Demostración del Mínimo Handover Package
* **Evaluación:** **`RESOLVED`**.
* **Fundamento:** La unidad mínima suficiente de información `(Establishment Context + Service Offers + Assigned Staff + Authorizing Identity)` está completamente identificada y demostrada.

---

### HB-DEC-002 — Representación Inequívoca de la Triple Relación
* **Evaluación:** **`YES (En el plano semántico del Handover)` / `NO (En el esquema físico de Pre-Nodo 01)`**.
* **Fundamento:** El Handover Package contiene todos los datos para expresar `(Sede + Profesional + Servicio)`. Sin embargo, Pre-Nodo 01 carece de columnas para persistir la sede sin un adaptador de transformación.

---

### HB-DEC-003 — Viabilidad de Definir el Contrato de Handover Físico
* **Evaluación:** **`REQUIRES ADDITIONAL DISCOVERY / PENDING DIRECTOR DECISION ON DEC-SE-001 & DEC-SE-002`**.
* **Fundamento:** Para formalizar el contrato físico de ingestión downstream (Nodo 01), el Director debe resolver previamente:
  1. `DEC-SE-001`: Estrategia de instanciación en `public.services` (Duplicación por Staff vs. Host Delegado).
  2. `DEC-SE-002`: Sincronización de ubicación y horarios de la sede en `perfiles_prestador`.

---

## 15. ACTIVOS PROTEGIDOS E INTEGRIDAD GIT

- **Activos Protegidos:** `Foundation v1.0`, `Context Resolution v1.0`, `Active Context v1.0`, `Hub Salón v1.0`, `Crear Desde Cero v1.0`, `Pre-Nodo 01`, `SOUL`, `Governance`, `NCP Core` permanecen **100% INTACTOS**.
- **Integridad Git:**
  - `0 runtime modifications`
  - `0 database modifications`
  - `0 migrations`
  - `0 protected asset modifications`
  - Único archivo creado: Este informe documental.

---

## 16. DIRECTOR DECISION REQUIRED

Se solicita pronunciamiento formal del Director sobre:
1. Aprobación del presente informe de descubrimiento del contrato de frontera.
2. Resolución formal de `DEC-SE-001` y `DEC-SE-002`.
3. Autorización de los términos de referencia para la especificación del Node Contract de **`NODO 01`**.

---

## 17. ESTADO FINAL

```text
================================================================================
ESTADO FINAL:
DISCOVERY COMPLETE / PENDING DIRECTOR ARCHITECTURAL REVIEW 🟡
================================================================================
```
