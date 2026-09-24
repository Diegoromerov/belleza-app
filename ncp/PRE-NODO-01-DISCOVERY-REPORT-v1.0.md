# PRE-NODO 01 DISCOVERY REPORT v1.0
## SaaS → Pre-Nodo 01 Handover Boundary Discovery

**Versión:** 1.0.0  
**Estado:** DISCOVERY COMPLETE / PENDING DIRECTOR ARCHITECTURAL REVIEW 🟡  
**Autoridad:** Director del Proyecto GlowApp SaaS  
**Carácter:** Read-Only Discovery (Cero Modificaciones a Código, Esquema o Nodos Protegidos)

---

## 1. ESTADO ACTUAL (PN01-Q03)

`PRE-NODO 01` se encuentra en estado:
```text
IMPLEMENTED / OPERATIVO / IMMUTABLE (Core B2C Monolítico Preexistente)
DESACOPLADO DEL MODELO MULTITENANT SAAS
```
* **Evidencia Física:** El monolito original cuenta con tablas físicas activas (`usuarios`, `perfiles_prestador`, `services`, `bookings`, `reviews`, `portfolio_items`), controladores REST en `backend/src/controllers/` y pantallas cliente/prestador en `frontend/lib/screens/`.
* **Inmutabilidad NCP:** Formalmente clasificado como activo protegido e inmutable (`CLOSED 🟢 / IMMUTABLE` en `NCP-CORE-CONTRACT-v1.0.md` línea 252 y `NCP-GOAL-EXECUTION-PROTOCOL-v1.0.md` línea 406).

---

## 2. RESPONSABILIDAD ARQUITECTÓNICA (PN01-Q01 / PN01-Q02)

* **Definición:** `Pre-Nodo 01` es el motor transaccional B2C original de GlowApp enfocado en la relación 1-a-1 entre un cliente final y un prestador individual de belleza.
* **Responsabilidades Nucleares:**
  1. Autenticación y registro de usuarios base (`usuarios`).
  2. Gestión del perfil profesional independiente (`perfiles_prestador`).
  3. Gestión del catálogo de servicios personales del prestador (`services` vinculados a `provider_id = usuarios.id`).
  4. Geolocalización mediante PostGIS (`ST_DWithin`, `ST_Distance` sobre `perfiles_prestador.ubicacion`).
  5. Motor de turnos, cálculo de disponibilidad de slots (`/api/providers/:id/slots`) y ciclo de reservas B2C (`bookings`).

---

## 3. PUNTO DE ENTRADA (PN01-Q04)

### A. Superficie HTTP / Backend Actual
* **Autenticación:** `POST /api/auth/login`, `POST /api/auth/register`, `PATCH /api/auth/onboarding`
* **Catálogo Individual:** `GET /api/services/provider`, `POST /api/services`, `PUT /api/services/:id`, `DELETE /api/services/:id`
* **Directorio de Prestadores:** `GET /api/providers`, `GET /api/providers/:id`, `GET /api/providers/:id/slots`
* **Reservas:** `POST /api/bookings`, `GET /api/bookings/provider`, `PATCH /api/bookings/:id/start`, `POST /api/bookings/:id/verify-pin`

### B. Superficie Frontend Actual
* `LoginScreen` / `RegisterScreen` (`frontend/lib/screens/auth/`)
* `ProviderDashboardScreen` (`frontend/lib/screens/provider_dashboard_screen.dart`)
* `HomeScreen` (`frontend/lib/screens/home/home_screen.dart`)
* `BookingScreen` (`frontend/lib/screens/booking_screen.dart`)

> **Hallazgo:** No existe actualmente ningún endpoint HTTP, controlador ni pantalla en Pre-Nodo 01 diseñado para recibir el `Context Package` SaaS.

---

## 4. INPUTS ACTUALES (PN01-Q05)

1. **Identidad:** `req.user.id` derivado del JWT, validado mediante `usuarios.rol` (`'CLIENTE'`, `'PRESTADOR'`, `'ADMIN'`).
2. **Contexto:** **Cero contexto organizacional.** No consume ni valida `tenant_id`, `organization_id`, `establishment_id` ni el header `x-active-membership-id`.
3. **Datos de Negocio:**
   - Catálogo: `{ name, description, price, duration_minutes, category, is_active }`.
   - Perfil / Horario: `{ business_name, description, active_start_hour, active_end_hour, weekly_schedule }`.
   - Agenda / Reserva: `{ provider_id, service_id, scheduled_at, client_id, valor_bruto }`.
4. **Configuración:** Parámetros globales en `platform_config` (coordenadas GPS por defecto, radio en metros).

---

## 5. REQUISITOS NECESARIOS VS. OPCIONALES (PN01-Q06)

| Tipo | Atributo / Entidad | Relevancia en Pre-Nodo 01 |
| :--- | :--- | :--- |
| **NECESARIO** | `usuarios.id` autenticado | Requerido para resolver `provider_id`. |
| **NECESARIO** | `perfiles_prestador` asociado | Requerido para verificación de estado (`estatus_verificacion = 'APROBADO'`). |
| **NECESARIO** | `services.name`, `price`, `duration_minutes` | Requerido para cálculo de slots y cotización. |
| **NECESARIO** | `perfiles_prestador.ubicacion` / horarios | Requerido para aparecer en directorio y cálculo de slots. |
| **OPCIONAL** | `category`, `description` | Metadatos de búsqueda y visualización. |
| **OPCIONAL** | `portfolio_items`, `reviews` | Información de reputación. |

---

## 6. CONTRATO DE ENTRADA ACTUAL (PN01-Q07)

```text
NO EXISTE CONTRATO EXPLÍCITO DE INGESTIÓN SAAS
```
* Pre-Nodo 01 no posee una especificación OpenAPI/NCP de ingestión masiva o contextual.
* Opera únicamente bajo contratos implícitos REST/CRUD de endpoints aislados (`POST /api/services`, `POST /api/bookings`).

---

## 7. MECANISMO ACTUAL DE CONTEXTO (PN01-Q08)

* **En Pre-Nodo 01:** El contexto es puramente la sesión de usuario autenticado (`req.user.id`). No existe objeto, DTO ni middleware equivalente a `Active Context` o `Context Package`.
* **En la Cadena SaaS:** El `Context Package` es un DTO transitorio en memoria de 16 atributos producido por `CREAR DESDE CERO v1.0`.

---

## 8. COMPATIBILIDAD DEL CONTEXT PACKAGE (PN01-Q09)

* **Clasificación:** **`PARCIALMENTE COMPATIBLE`**
* **Fundamento:**
  - El `Context Package` provee la información requerida de catálogo (`relevant_services`) y personal (`people_initial_roles`).
  - Sin embargo, Pre-Nodo 01 **no puede consumirlo directamente sin un adaptador / capa de ingestión**, debido a que:
    1. Pre-Nodo 01 asume que los servicios pertenecen a un `provider_id` (`usuarios.id`), mientras que en el SaaS los servicios pertenecen a la sede (`establishment_id`) o son ejecutados por miembros (`memberships`).
    2. Pre-Nodo 01 carece de conocimiento de organizaciones y multitenancy RLS (`tenants`).

---

## 9. MAPPING DE LOS 16 ATRIBUTOS CANÓNICOS (PN01-Q10)

| # | Atributo Context Package | Estado en Pre-Nodo 01 | Justificación Técnica / Evidencia Física |
| :-: | :--- | :---: | :--- |
| **1** | `organization` | **NOT USED** | Pre-Nodo 01 no posee entidad ni concepto de persona jurídica/organización. |
| **2** | `establishments` | **NOT USED** | Pre-Nodo 01 geolocaliza personas (`perfiles_prestador`), no sedes físicas (`establishments`). |
| **3** | `activities` | **NOT USED** | Pre-Nodo 01 maneja categorías sueltas en servicios (`services.category`). |
| **4** | `relevant_services` | **USED** | Conceptualmente coincide con `name`, `duration_minutes`, `price`, `description` de `services`. |
| **5** | `people_initial_roles` | **USED** | Conceptualmente mapeable a los prestadores (`usuarios` / `perfiles_prestador`). |
| **6** | `identity` | **USED** | Mapea a `req.user.id` autenticado. |
| **7** | `state` | **NOT USED** | Pre-Nodo 01 no implementa máquina de estados de aprovisionamiento. |
| **8** | `known_evidence` | **NOT USED** | Metadatos de auditoría y trazabilidad NCP. |
| **9** | `decisions` | **NOT USED** | Metadatos de configuración SaaS. |
| **10**| `applicable_rules` | **NOT USED** | Reglas de gobernanza y RLS del plano SaaS. |
| **11**| `conditions` | **NOT USED** | Metadatos de validación contextual. |
| **12**| `procedures` | **NOT USED** | Metadatos de procedimiento. |
| **13**| `dependencies` | **NOT USED** | Metadatos de dependencias SaaS. |
| **14**| `blocks` | **NOT USED** | Lista de impedimentos de aprovisionamiento. |
| **15**| `route` | **NOT USED** | Ruta lógica de handover. |
| **16**| `entry_state` | **NOT USED** | Estado conceptual de entrada. |

---

## 10. ESTADO ACTUAL DEL HANDOVER (PN01-Q04 / PN01-Q08)

```text
HANDOVER NOT FORMALLY IMPLEMENTED
```
* `CREAR DESDE CERO v1.0` compila y emite con éxito el `Context Package` en memoria bajo `POST /api/v1/saas/hub/onboarding/bootstrap`.
* **Falta el receptor:** Pre-Nodo 01 no dispone de un endpoint receptor, adaptador o mecanismo de ingestión que consuma dicho DTO para instanciar servicios o aprovisionar la sede en el motor B2C.

---

## 11. DATOS Y PERSISTENCIA

* Pre-Nodo 01 espera que los datos ya residan **persistidos en base de datos** (`public.services`, `public.perfiles_prestador`, `public.usuarios`) para poder listarlos, cotizarlos y agendarlos.
* El `Context Package` de Crear Desde Cero es **estrictamente transitorio (en memoria)**.
* **Conclusión:** La persistencia final requerida por el motor de servicios B2C deberá ser resuelta en el siguiente nodo arquitectónico (Nodo 01 o Ingestion Gateway), sin violar las decisiones `DEC-CDC-001` y `DEC-CDC-002`.

---

## 12. SEGURIDAD Y TENANCY

* **En Pre-Nodo 01:** Autenticación básica mediante JWT legacy que expone `req.user.id` y `req.user.role`. Consultas SQL no ejecutan `SET LOCAL app.tenant_id` y no aplican políticas RLS multitenant.
* **En el Plano SaaS:** Autenticación custodiada por `authMiddleware` + `activeContextMiddleware`, resolución estricta server-side vía `fn_resolve_user_tenant`, validación de membresías y RLS activo (`SET LOCAL app.tenant_id = $1`).

---

## 13. SAAS / B2C BOUNDARY (FRONTERA ARQUITECTÓNICA)

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        PLANO SAAS B2B (TENANT AWARE)                   │
│                                                                        │
│  - Foundations & Multitenancy (tenants, organizations, establishments) │
│  - Context Resolution & Active Context (memberships, roles SaaS)       │
│  - Hub Salón v1.0 (Cockpit operativo de sede)                          │
│  - Crear Desde Cero v1.0 (Captura transitoria de intención)            │
│  - Context Package (DTO Transitorio de 16 Atributos)                  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                         FRONTERA DE HANDOVER
                       (INGESTIÓN / ADAPTADOR)
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                        PLANO CORE B2C (PRE-NODO 01)                    │
│                                                                        │
│  - Identidades y Perfiles Individuales (usuarios, perfiles_prestador)  │
│  - Catálogo Físico de Servicios (public.services)                      │
│  - Directorio Geolocalizado y Slots (PostGIS)                          │
│  - Reservas, Checkout, Pagos y Calificaciones B2C                      │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 14. EVIDENCIA DE CÓDIGO LEGACY

* `backend/src/controllers/serviceController.js`: Valida `req.user.role !== 'provider' && req.user.role !== 'PRESTADOR'` y vincula servicios directamente a `provider_id: req.user.id`.
* `backend/src/controllers/providerController.js`: Ejecuta geolocalización PostGIS asumiendo que el prestador es una persona individual con coordenadas en `perfiles_prestador`.
* `frontend/lib/screens/provider_dashboard_screen.dart`: Dashboard móvil enfocado en turnos de un prestador independiente con PIN de validación y liquidación individual por Nequi/Wompi.

---

## 15. BRECHAS ARQUITECTÓNICAS (ARCHITECTURAL GAPS)

1. **Brecha de Identidad de Catálogo:** `public.services` requiere `provider_id` (prestador individual), mientras que el SaaS define servicios a nivel de establecimiento/sede con staff asignado.
2. **Brecha de Ingestión:** Falta un protocolo formal para transformar el `Context Package` transitorio en entidades operables en el motor B2C.
3. **Brecha de Multitenancy:** Pre-Nodo 01 no opera con `SET LOCAL app.tenant_id`.

---

## 16. DECISIONES PENDIENTES DEL DIRECTOR (DECISION GATES)

### DEC-PN01-001 — MECANISMO DE INGESTIÓN DEL CONTEXT PACKAGE HACIA B2C
* **Problema:** Pre-Nodo 01 es inmutable y no tiene un endpoint para ingerir el `Context Package`.
* **Evidencia:** `crearDesdeCeroRoutes.js` expone `/bootstrap` que compila el DTO en memoria, pero no existe consumidor downstream en `backend/`.
* **Impacto:** El flujo de Crear Desde Cero termina en la emisión del DTO transitorio sin instanciar la operación del salón.
* **Opciones:**
  - **Opción A (Nodo 01 Ingestion Bridge):** Definir un nuevo nodo (`NODO-01-INGESTION-v1.0`) que actúe como puente/adaptador oficial de ingestión entre el Context Package SaaS y el motor de servicios B2C.
  - **Opción B (Direct Handover a Base de Datos):** Crear una persistencia SaaS dedicada de servicios de sede (`establishment_services`) desacoplada de `public.services`.
* **Recomendación:** **Opción A (Nodo 01 Ingestion Bridge)**, preservando la inmutabilidad de Pre-Nodo 01 y la pureza transitoria de Crear Desde Cero.
* **Estado:** `PENDING DIRECTOR DECISION`

### DEC-PN01-002 — MODELO DE RELACIÓN SALÓN ↔ PRESTADOR EN CATÁLOGO B2C
* **Problema:** En Pre-Nodo 01, las reservas se hacen contra un `services.provider_id`. En un salón SaaS, el servicio pertenece a la sede y puede ser ejecutado por múltiples profesionales asignados (`people_initial_roles`).
* **Evidencia:** `serviceController.js` línea 57 (`provider_id: req.user.id`) vs `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md` sección 8.
* **Impacto:** Si un cliente B2C reserva en una sede, el motor B2C actual requiere conocer el prestador o asignar el servicio al Owner/Staff.
* **Opciones:**
  - **Opción A:** En la ingestión, vincular los servicios al Owner/Manager como prestador anfitrión de la sede en Pre-Nodo 01.
  - **Opción B:** Extender en un nodo futuro el motor de reservas para soportar `establishment_id`.
* **Recomendación:** **Opción A** como mecanismo puente sin tocar esquemas protegidos, o evaluar la extensión formal en la definición de `NODO 01`.
* **Estado:** `PENDING DIRECTOR DECISION`

---

## 17. ACTIVOS PROTEGIDOS

Permanecen 100% inalterados e íntegros:
1. `SaaS Foundation v1.0` (Migraciones 065/066, `fn_resolve_user_tenant`)
2. `Context Resolution v1.0`
3. `Active Context v1.0`
4. `Hub Salón v1.0`
5. `Crear Desde Cero v1.0`
6. `Pre-Nodo 01` (Core B2C intacto)
7. `SOUL` / `Governance` / `NCP Core`

---

## 18. INTEGRIDAD GIT

- **Archivos de runtime modificados:** **0**
- **Nuevas tablas / migraciones / columnas:** **0**
- **Único archivo creado:** Este reporte documental [`/ncp/PRE-NODO-01-DISCOVERY-REPORT-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/PRE-NODO-01-DISCOVERY-REPORT-v1.0.md).

---

## 19. CONCLUSIÓN

El Discovery de la frontera `CREAR DESDE CERO → CONTEXT PACKAGE → PRE-NODO 01` ha finalizado con éxito.
Se ha demostrado con evidencia física que:
1. Pre-Nodo 01 es el core B2C transaccional preexistente e inmutable.
2. El `Context Package` contiene los datos de negocio requeridos (servicios, staff, identidad), pero carece de un endpoint receptor formal en Pre-Nodo 01 (`HANDOVER NOT FORMALLY IMPLEMENTED`).
3. Se requiere la intervención y decisión formal del Director sobre `DEC-PN01-001` y `DEC-PN01-002` antes de redactar el siguiente contrato arquitectónico (`NODO 01`).

```text
================================================================================
ESTADO FINAL:
DISCOVERY COMPLETE / PENDING DIRECTOR ARCHITECTURAL REVIEW 🟡
================================================================================
```
