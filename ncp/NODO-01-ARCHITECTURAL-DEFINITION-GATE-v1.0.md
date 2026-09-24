# NODO 01 — ARCHITECTURAL DEFINITION GATE REPORT v1.0
## Definición Arquitectónica Canónica, Mapa de Responsabilidad y Fronteras

**Versión:** 1.1.0 (Reconciled & Closed)  
**Fecha:** 2026-09-10  
**Estado:** ARCHITECTURAL DEFINITION READY FOR DIRECTOR CLOSURE 🟡  
**Autoridad:** Director del Proyecto GlowApp SaaS  
**Carácter:** Architectural Definition Gate (Cero Implementación / Cero Creación de Contratos Físicos / Cero Mutaciones a Código o BD)  

---

## 1. CONTEXTO Y PROPÓSITO ARQUITECTÓNICO

El presente documento formaliza el cierre de la **Compuerta de Definición Arquitectónica de NODO 01**. Su propósito exclusivo es fijar la definición canónica, responsabilidades y límites de Nodo 01 dentro de la cadena de arquitectura:

```text
REGISTER → ACCOUNT → IDENTITY → JOURNEY SaaS → SAAS ELIGIBILITY → SAAS ACCESS 
→ AVAILABLE CONTEXT → ACTIVE CONTEXT → HUB SALÓN → CREAR DESDE CERO 
→ HANDOVER BOUNDARY v1.0 → PRE-NODO 01 → NODO 01
```

Esta definición permite avanzar a la redacción formal de `NODO-01-NODE-CONTRACT-v1.0.md` manteniendo desacopladas y en estado **`PENDING`** las decisiones downstream `DEC-SE-001` y `DEC-SE-002`.

---

## 2. CORRECCIÓN ARQUITECTÓNICA FUNDAMENTAL (HBC ≠ NODO 01)

Se establece con total rigidez conceptual la separación de fronteras:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   SEPARACIÓN ESTRUCTURAL DE FRONTERAS                  │
├────────────────────────────────────────────────────────────────────────┤
│ 1. HANDOVER BOUNDARY (HBC v1.0):                                       │
│    - Es la frontera semántica de entrega entre SaaS y Downstream.      │
│    - Define el DTO inmutable y garantiza la neutralidad de dominios.   │
│    - NO absorbe responsabilidades de procesamiento downstream.         │
│                                                                        │
│ 2. NODO 01:                                                            │
│    - Es el componente/capa downstream que recibe el handover válido.   │
│    - Opera como frontera de ingestión y adaptación downstream.         │
│    - NO reescribe ni modifica el Handover Boundary Contract v1.0.      │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. DEFINICIÓN CANÓNICA DE NODO 01

```text
================================================================================
                    NODO 01 = HANDOVER INGESTION & DOWNSTREAM ADAPTER
================================================================================
```

### Responsabilidad Conceptual Mínima:
1. **Aceptación de Handover:** Aceptar exclusivamente entregas válidas conformes a `HANDOVER-BOUNDARY-CONTRACT-v1.0`.
2. **Validación de Frontera:** Verificar las condiciones y garantías de entrada que corresponden a su límite.
3. **Preservación de Aislamiento:** Mantener estrictamente separada la semántica SaaS (catálogo y staff de sede) de la semántica operacional B2C (prestadores individuales y transacciones).
4. **Preparación y Adaptación Downstream:** Preparar y adaptar conceptualmente la información recibida para el consumo del plano operacional B2C (`DOWNSTREAM ADAPTATION RESULT`).
5. **Delegación de Materialización:** Delegar cualquier decisión de materialización o persistencia física a reglas arquitectónicas formalmente aprobadas (`DEC-SE-001`, `DEC-SE-002`).
6. **Invariabilidad Retroactiva:** Impedir terminantemente que cualquier decisión o necesidad downstream altere retroactivamente el modelo SaaS o el contrato `HBC v1.0`.

> **DECLARACIONES NEGATIVAS OBLIGATORIAS:**  
> - Nodo 01 **NO** es un motor de provisioning.  
> - Nodo 01 **NO** persiste registros en base de datos en esta definición.  
> - Nodo 01 **NO** crea perfiles de prestador.  
> - Nodo 01 **NO** crea servicios físicos en `public.services`.  
> - Nodo 01 **NO** asigna profesionales a servicios.

---

## 4. FRONTERA DE ENTRADA (INPUT BOUNDARY)

La frontera de entrada de Nodo 01 es estrictamente el **DTO de HANDOVER-BOUNDARY-CONTRACT-v1.0**, que permanece inmutable:
- `establishment_context`: `{ id, name, city, address, location, operating_hours }`
- `professional_context`: `[{ user_id, role, status: 'ACTIVE', capabilities }]`
- `service_offers`: `[{ name, category, duration_minutes, price, description, is_active }]` (**SIN `provider_id`**)
- `authorizing_identity`: `{ user_id, role }`
- `assignment`: `{ status: 'NOT_ESTABLISHED' }`
- `source_state`: `"READY_FOR_PRE_NODE_01"` (Metadato informativo de salida de Crear Desde Cero)

---

## 5. FRONTERA DE SALIDA (OUTPUT BOUNDARY)

La salida de Nodo 01 se define exclusivamente como:

```text
================================================================================
                      DOWNSTREAM ADAPTATION RESULT
================================================================================
```

- Representa el conjunto estructurado de datos de sede y staff adaptados conceptualmente para el plano downstream.
- **Sin Cristalización Física Prematura:** No define ni presupone sentencias `INSERT`/`UPDATE`, esquemas de duplicación, inyección forzada de `provider_id`, mutación de tablas ni mecanismos de sincronización de horarios.
- La materialización concreta de este resultado queda gobernada por las directivas que el Director promulgue para `DEC-SE-001` y `DEC-SE-002`.

---

## 6. EVALUACIÓN SISTEMÁTICA DE CANDIDATURAS (A → F)

| Candidatura | Calificación | Justificación y Relación con Decisiones Pendientes |
| :--- | :---: | :--- |
| **A. Handover Receiver** | Insuficiente aislada | Mero receptor técnico de red. No resuelve la preparación para B2C. |
| **B. Validation Gate** | Insuficiente aislada | Guardia de seguridad y formato. No prepara la adaptación de modelo. |
| **C. Transformation Layer** | Parcial | Mapeo en memoria. Requiere desacoplarse de la persistencia física. |
| **D. Provisioning Engine** | **RECHAZADA como definición pura** | Forzaría mutaciones físicas prematuras y violaría la neutralidad de las decisiones pendientes. |
| **E. Orchestration / Adapter** | Parcial | Riesgo de sobreextensión si asume tareas de runtime transaccional. |
| **F. Combinación Controlada (Aprobada)** | **CANÓNICA** | **Fase 1 (Ingestion Gateway):** Recepción y validación estricta del DTO de `HBC v1.0`.<br>**Fase 2 (Downstream Adapter):** Preparación del `DOWNSTREAM ADAPTATION RESULT` desacoplado de la persistencia física. |

---

## 7. RESPONSIBILITY MAP (MAPA DE RESPONSABILIDADES)

| Elemento / Dominio | SaaS Foundation / Cockpit | Handover Boundary (HBC) | NODO 01 (Ingestion & Adapter) | Pre-Node 01 (Core B2C) | Futuro Operational Domain |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Identity (`usuarios`)** | `validates` | `provides` (`user_id`) | `consumes` / `validates` | `owns` / `persists` | `consumes` |
| **Tenant (`tenants`)** | `owns` / `validates` | `transforms` (RLS) | Agnóstico | Inexistente | Inexistente |
| **Active Context (`memberships`)** | `owns` / `validates` | `provides` (`ACTIVE`) | `validates` (regla de rol) | Inexistente | Inexistente |
| **Establishment Context** | `owns` / `provides` | `provides` (DTO) | `consumes` / `transforms` | Inexistente | Inexistente |
| **Professional Context** | `owns` / `provides` | `provides` (DTO) | `consumes` / `transforms` | Inexistente | Inexistente |
| **Capability (`assigned_categories`)**| `owns` / `provides` | `provides` (`CAPABILITY`)| `consumes` / `validates` | Inexistente | Inexistente |
| **Service Offer (`relevant_services`)**| `owns` / `provides` | `provides` (DTO) | `consumes` / `transforms` | Inexistente | Inexistente |
| **Assignment** | `provides` (`NOT_ESTABLISHED`)| `provides` (`NOT_ESTABLISHED`)| `adapts` (**UNRESOLVED DEC-SE-001**) | `owns` (`provider_id NOT NULL`)| `consumes` |
| **Provider Profile (`perfiles_prestador`)**| Inexistente | Inexistente | `adapts` (**UNRESOLVED DEC-SE-002**) | `owns` / `persists` | `consumes` |
| **B2C Service (`public.services`)** | Inexistente | Inexistente | `adapts` (**UNRESOLVED DEC-SE-001**) | `owns` / `persists` | `consumes` |
| **Provider-Service Relation** | Inexistente | Inexistente | `adapts` (**UNRESOLVED DEC-SE-001**) | `owns` (`FK provider_id`)| `consumes` |
| **Location (`ubicacion` Point 4326)**| `owns` (Sede) | `provides` (DTO Sede) | `adapts` (**UNRESOLVED DEC-SE-002**) | `owns` (Prestador) | `consumes` (PostGIS) |
| **Schedule (`weekly_schedule` JSONB)**| `owns` (Sede) | `provides` (DTO Sede) | `adapts` (**UNRESOLVED DEC-SE-002**) | `owns` (Prestador) | `consumes` (Slots) |
| **Availability (Slots en tiempo real)**| Inexistente | Inexistente | Fuera de Alcance | `owns` / `calculates` | `consumes` |
| **Booking (`public.bookings`)** | Inexistente | Inexistente | Fuera de Alcance | `owns` / `persists` | `consumes` / `activates` |
| **Execution (PIN, check-in, check-out)**| Inexistente | Inexistente | Fuera de Alcance | `owns` / `validates` | `consumes` / `activates` |
| **Marketplace Activation** | Inexistente | Inexistente | Fuera de Alcance | `owns` (`is_active`) | `activates` (Comercial) |

---

## 8. AUTHORITY MAP (MATRIZ DE SOBERANÍA CANÓNICA)

```text
┌────────────────────────────────────────────────────────────────────────┐
│                          MATRIZ DE SOBERANÍA                           │
├─────────────────────────┬──────────────────────────────────────────────┤
│ Dominio                 │ Soberanía Canónica                           │
├─────────────────────────┼──────────────────────────────────────────────┤
│ Identidad Base          │ Pre-Nodo 01 (usuarios) / Shared Kernel       │
│ Tenant / Aislamiento    │ SaaS Foundation (tenants, RLS)               │
│ Establecimiento         │ SaaS Core (establishments)                   │
│ Membresía / Staff SaaS  │ SaaS Foundation (memberships)                │
│ Rol Contextual SaaS     │ Active Context (OWNER, MANAGER, PROFESSIONAL)│
│ Capability Declarada    │ SaaS Onboarding (people_initial_roles)       │
│ Oferta de Catálogo Sede │ SaaS Onboarding (relevant_services)          │
│ Assignment de Servicio  │ PENDIENTE DIRECTIVA (DEC-SE-001)             │
│ Perfil B2C / Prestador  │ Pre-Nodo 01 (perfiles_prestador)             │
│ Servicio Persistido B2C │ Pre-Nodo 01 (public.services)                │
│ Booking / Transacciones │ Pre-Nodo 01 (public.bookings / runtime)      │
│ Ejecución de Servicio   │ Pre-Nodo 01 (PIN / confirmación de cita)     │
│ Activación Marketplace  │ Fuera de Frontera (Decisión Comercial)      │
└─────────────────────────┴──────────────────────────────────────────────┘
```

> **PRINCIPIO CANÓNICO DE DISTINCIÓN:**  
> `IDENTITY` (`usuarios.id`) $\neq$ `PROFESSIONAL CAPABILITY` (`assigned_categories`) $\neq$ `OPERATIONAL ASSIGNMENT` (`public.services.provider_id`).  
> Ninguna capa intermedia puede colapsar estas tres dimensiones en una equivalencia implícita.

---

## 9. EVALUACIÓN Y REGLA DE AVANCE RESPECTO A DEC-SE-001 Y DEC-SE-002

### DEC-SE-001 (Estrategia de Instanciación de Servicios)
- **Estado:** **`PENDING DIRECTOR DECISION`**.
- **Impacto:** No bloquea la definición conceptual de Nodo 01. Condiciona exclusivamente la estrategia de materialización del catálogo en B2C.

### DEC-SE-002 (Sincronización de Ubicación y Horarios)
- **Estado:** **`PENDING DIRECTOR DECISION`**.
- **Impacto:** No bloquea la definición conceptual de Nodo 01. Condiciona exclusivamente la estrategia de sincronización de ubicación y horarios en `perfiles_prestador`.

### REGLA DE AVANCE HACIA NODE CONTRACT:
> **REGLA:** El Node Contract (`NODO-01-NODE-CONTRACT-v1.0.md`) **PUEDE REDACTARSE** mientras `DEC-SE-001` y `DEC-SE-002` permanezcan `PENDING`, siempre que el contrato:
> 1. Mantenga explícitamente esas decisiones como dependencias pendientes.
> 2. No cristalice prematuramente ninguna de sus alternativas.
> 3. No autorice implementación física condicionada.
> 4. Defina estrictamente las responsabilidades, fronteras y validaciones ya aprobadas.

---

## 10. ANTI-COUPLING FINAL (BLINDAJE DE LÍMITES)

Se certifica formalmente que la definición canónica de NODO 01:
1. **SaaS NO conoce `provider_id`:** El modelo multitenant ignora la existencia de claves de prestador B2C.
2. **HBC NO conoce `provider_id`:** El DTO de entrega no transporta asignaciones B2C.
3. **Crear Desde Cero NO decide `provider_id`:** El onboarding solo captura la oferta de la sede.
4. **Nodo 01 NO inventa `provider_id`:** No crea asignaciones artificiales sin directiva aprobada.
5. **Desacoplamiento Geográfico y Temporal:** `SaaS location` $\neq$ automáticamente `Provider Profile location`; `SaaS operating_hours` $\neq$ automáticamente `Provider weekly_schedule`. Ambas quedan sujetas a `DEC-SE-002`.
6. **No Persistencia en Frontera:** Handover Boundary y Context Package permanecen como estructuras en memoria/tránsito sin persistencia intermedia forzada.

---

## 11. N01-DEC-001 — ARCHITECTURAL DEFINITION OF NODE 01

### A. FACTS (Hechos Demostrados por Evidencia)
1. `HANDOVER-BOUNDARY-CONTRACT-v1.0` define un DTO formal de sede con `assignment = NOT_ESTABLISHED` y sin `provider_id`.
2. Pre-Nodo 01 exige físicamente `provider_id INTEGER NOT NULL` en `public.services` y opera acoplado al prestador individual (`perfiles_prestador`).
3. No existe ningún componente físico de ingestión en el repositorio actual.
4. `assigned_categories` es exclusivamente una `CAPABILITY` declarada; el *category matching* no constituye una asignación operativa.

### B. INFERENCES (Inferencias Válidas)
1. Se requiere un componente intermedio de frontera que reciba el DTO, valide su conformidad y adapte la disparidad de modelos.
2. La definición conceptual de dicho componente puede establecerse con total estabilidad sin resolver previamente `DEC-SE-001` y `DEC-SE-002`.

### C. APPROVED CONCEPTUAL DEFINITION
**NODO 01 = HANDOVER INGESTION & DOWNSTREAM ADAPTER**  
Frontera receptora y adaptadora downstream responsable de validar el DTO de `HBC v1.0`, preservar el aislamiento semántico y generar el `DOWNSTREAM ADAPTATION RESULT` neutral.

### D. PENDING DECISIONS
- `DEC-SE-001` (Estrategia de asignación/instanciación en `public.services`): `PENDING`.
- `DEC-SE-002` (Sincronización de ubicación y horarios en `perfiles_prestador`): `PENDING`.

### E. BOUNDARIES
- **Entrada:** DTO inmutable de `HANDOVER-BOUNDARY-CONTRACT-v1.0`.
- **Salida:** `DOWNSTREAM ADAPTATION RESULT` (Estructura conceptual adaptada para B2C).

### F. RECOMMENDATION
- **Aprobación de la Definición Conceptual de Nodo 01** como base normativa para redactar `NODO-01-NODE-CONTRACT-v1.0.md`.

> **ESTADO FORMAL DE LA COMPUERTA:**  
> **`N01-DEC-001 = PROPOSED FOR DIRECTOR APPROVAL`**

---

## 12. ACTIVOS PROTEGIDOS

Se certifica que la presente reconciliación preserva íntegramente:
1. **Foundation 065/066 (`backend/migrations/065_saas_foundation_core.sql`)**
2. **`fn_resolve_user_tenant` (`backend/migrations/066_context_resolution_tenant_resolver.sql`)**
3. **Context Resolution v1.0**
4. **Active Context v1.0**
5. **Hub Salón v1.0**
6. **Crear Desde Cero v1.0**
7. **Pre-Node 01 (`backend/init.sql` y controladores B2C)**
8. **Handover Boundary Contract v1.0**
9. **SOUL + Governance & NCP Core**

---

## 13. GIT SCOPE

Ejecución de `git status --short`:
```text
 M backend/docker-compose.yml
 M backend/index.js
 M backend/init.sql
?? backend/migrations/065_saas_foundation_core.sql
?? backend/migrations/066_context_resolution_tenant_resolver.sql
?? backend/src/controllers/activeContextController.js
?? backend/src/controllers/contextController.js
?? backend/src/controllers/crearDesdeCeroController.js
?? backend/src/controllers/hubSalonController.js
?? backend/src/middleware/activeContextMiddleware.js
?? backend/src/routes/activeContextRoutes.js
?? backend/src/routes/contextRoutes.js
?? backend/src/routes/crearDesdeCeroRoutes.js
?? backend/src/routes/hubSalonRoutes.js
?? backend/src/services/activeContextService.js
?? backend/src/services/contextResolutionService.js
?? backend/src/services/crearDesdeCeroService.js
?? backend/src/services/hubSalonService.js
?? backend/tests/test_active_context_controller.js
?? backend/tests/test_active_context_suite.js
?? backend/tests/test_crear_desde_cero_suite.js
?? backend/tests/test_hub_salon_suite.js
?? ncp/
```
*0 modificaciones de código runtime. Único archivo actualizado: `/ncp/NODO-01-ARCHITECTURAL-DEFINITION-GATE-v1.0.md`.*

---

## 14. ESTADO FINAL

```text
================================================================================
ESTADO FINAL:
ARCHITECTURAL DEFINITION READY FOR DIRECTOR CLOSURE 🟡
================================================================================
```
