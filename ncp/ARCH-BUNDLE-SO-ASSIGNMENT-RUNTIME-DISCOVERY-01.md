# ARCH-BUNDLE-SO-ASSIGNMENT-RUNTIME-DISCOVERY-01 v1.0
## Descubrimiento Arquitectónico del Runtime de Service Offer + Assignment

**DOCUMENTO:** `ARCH-BUNDLE-SO-ASSIGNMENT-RUNTIME-DISCOVERY-01`  
**TÍTULO:** Descubrimiento Arquitectónico del Runtime de Service Offer + Assignment  
**ESTADO:** `DISCOVERY COMPLETE — NO IMPLEMENTATION AUTHORIZED 🔒`  
**TIPO:** Architectural Discovery & Runtime Boundary Determination  
**AUTORIDAD:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `ARCH-BUNDLE-SO-ASSIGNMENT-RUNTIME-DISCOVERY-01`  
**REGLA FUNDAMENTAL:** `NO CODE BEFORE CONTRACT — DISCOVERY ONLY`  

**CONTRATOS Y ACTIVOS PROTEGIDOS E INTACTOS:**  
- `065_saas_foundation_core.sql` (SaaS Foundation Core)  
- `066_context_resolution_tenant_resolver.sql` (Context Resolution Engine)  
- `067_service_offers.sql` (SaaS Service Offers Schema — Ratified)  
- `068_service_assignments.sql` (SaaS Service Assignments Schema — Ratified)  
- `ACTIVE-CONTEXT-NODE-CONTRACT-v1.0.md` (Active Context Node)  
- `HUB-SALON-NODE-CONTRACT-v1.0.md` (Hub Salón Node)  
- `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md` (Crear Desde Cero Node)  
- `HANDOVER-BOUNDARY-CONTRACT-v1.0.md` (Handover Boundary Contract v1.0)  
- `NODO-01-NODE-CONTRACT-v1.0.md` (NODO-01 Runtime Engine)  
- `DEC-SE-001` & `DEC-SE-002` (Service Materialization & Schedule Independence)  
- `DEC-AS-001` a `DEC-AS-014` (Assignment Architectural Definition)  
- `DEC-FC-001` (Foundation Compatibility Option A — Ratified)  
- `GOVERNANCE-STOP-001-CLOSURE-v1.0.md` (Governance Ratification & Closure)  
- `Pre-Nodo 01` (B2C Core Marketplace & Bookings — Immutable)  

---

## 1. OBJETIVO (GOAL PURPOSE)

Determinar, con base en la evidencia física del repositorio y en las decisiones arquitectónicas ya cerradas y ratificadas, cuál es el siguiente componente funcional o runtime del sistema que debe consumir y operar sobre las estructuras físicas recién consolidadas:

```text
SERVICE_OFFER
      +
ASSIGNMENT
      +
ACTIVE MEMBERSHIP / ACTIVE CONTEXT
      +
ESTABLISHMENT / TENANT
```

### Límites Estrictos de este Discovery:
- **CERO CÓDIGO** (No controllers, no services, no routes, no middlewares).
- **CERO DDL / DML** (No migraciones, no modificaciones en base de datos).
- **CERO MODIFICACIONES EN DOMINIOS PROTEGIDOS** (Foundation, B2C, Pre-Nodo 01, HBC).
- **CERO ESPECULACIÓN** (Toda afirmación se categoriza como: EVIDENCIA, DECISIÓN YA CERRADA, INFERENCIA o PROPUESTA — NO APROBADA).

---

## 2. EVIDENCIA EN REPOSITORIO (REPOSITORY EVIDENCE)

Se ejecutó una inspección exhaustiva en la totalidad del árbol de backend (`backend/src/`):

### 2.1. Búsqueda de Términos Físicos y Conceptuales:
1. **`service_offers` en `backend/src/`:**
   - *Hallazgo:* 1 única ocurrencia en `backend/src/services/nodo01Service.js` (Línea 233), correspondiente a un comentario explicativo sobre la frontera downstream.
   - *Estado:* **[EVIDENCIA]** Cero consumo en tiempo de ejecución.
2. **`service_assignments` en `backend/src/`:**
   - *Hallazgo:* 0 ocurrencias en todo `backend/src/`.
   - *Estado:* **[EVIDENCIA]** Cero consumo en tiempo de ejecución.
3. **`memberships` en `backend/src/`:**
   - *Hallazgos:* Consumida activamente en `activeContextService.js` (validación de membresía y rol), `hubSalonService.js` (conteo y listado de staff activo) y `contextResolutionService.js` (resolución de membresías disponibles para el usuario).
   - *Estado:* **[EVIDENCIA]** Entidad base de personal plenamente integrada en el SaaS Runtime.
4. **`establishments` / `tenants` / `organizations` en `backend/src/`:**
   - *Hallazgos:* Consumidas en `activeContextService.js`, `hubSalonService.js`, `crearDesdeCeroService.js`.
   - *Estado:* **[EVIDENCIA]** Entidades de Foundation plenamente operativas en SaaS Runtime.

---

## 3. RUNTIME ACTUAL ENCONTRADO (CURRENT RUNTIME STATE)

### Diagnóstico de Módulos Existentes en `backend/src/`:
- **`src/services/activeContextService.js`:** Valida que el `x-active-membership-id` pertenezca al usuario autenticado, que esté en estado `ACTIVE`, y resuelve `tenant_id`, `establishment_id`, `role` y `relation_type`.
- **`src/middleware/activeContextMiddleware.js`:** Intercepta requests HTTP, extrae `x-active-membership-id`, invoca `activeContextService` y fija `req.activeContext`, `req.tenantId`, `req.establishmentId`, `req.membershipId`.
- **`src/services/hubSalonService.js`:** Provee `getHubSummary` (datos de sede, organización y conteo de staff) y `getHubStaff` (listado detallado de miembros activos de la sede).
- **`src/services/nodo01Service.js`:** Ingesta en memoria payloads de `HANDOVER-BOUNDARY-CONTRACT-v1.0` y valida la invariante `assignment.status === 'NOT_ESTABLISHED'`.
- **`src/services/crearDesdeCeroService.js`:** Asistente transaccional de creación de organización + establecimiento + membresía inicial (onboarding).

### Conclusión sobre Runtime Existente:
> **[EVIDENCIA]:** NO existe actualmente ningún runtime, servicio, controlador ni ruta en el backend que gestione, consulte, inserte, actualice o elimine `service_offers` ni `service_assignments`. Ambas entidades existen puramente a nivel físico DDL (migraciones 067 y 068 ratificadas).

---

## 4. SERVICE OFFER — CONSUMO ACTUAL (SERVICE OFFER CONSUMPTION)

| Dimensión | Estado Real en Código | Clasificación |
| :--- | :--- | :---: |
| **Creación de Oferta** | No implementada | **[EVIDENCIA]** |
| **Listado de Ofertas por Sede** | No implementado | **[EVIDENCIA]** |
| **Detalle de Oferta por ID** | No implementado | **[EVIDENCIA]** |
| **Actualización Comercial** | No implementada | **[EVIDENCIA]** |
| **Eliminación de Oferta** | No implementada (`DELETE = UNDEFINED`) | **[DECISIÓN YA CERRADA]** |
| **Habilitación `is_active`** | No implementada (`is_active = UNDEFINED`) | **[DECISIÓN YA CERRADA]** |
| **Sincronización con B2C** | Prohibida sin asignación (`DEC-SE-001`, `DEC-PUB-001`) | **[DECISIÓN YA CERRADA]** |

---

## 5. ASSIGNMENT — CONSUMO ACTUAL (ASSIGNMENT CONSUMPTION)

| Dimensión | Estado Real en Código | Clasificación |
| :--- | :--- | :---: |
| **Creación de Asignación** | No implementada | **[EVIDENCIA]** |
| **Listado de Asignaciones por Sede** | No implementado | **[EVIDENCIA]** |
| **Listado por Colaborador** | No implementado | **[EVIDENCIA]** |
| **Listado por Oferta** | No implementado | **[EVIDENCIA]** |
| **Desasignación (`DELETE`)** | No implementada (`DELETE = PURE UNASSIGNMENT`) | **[DECISIÓN YA CERRADA]** |
| **Estados Propios (`status`)** | Inexistentes (`Validez derivada de Membership`) | **[DECISIÓN YA CERRADA]** |
| **Actoría / Auditoría** | Diferida a subsistema de auditoría (`DEC-AS-013-B/F`) | **[DECISIÓN YA CERRADA]** |

---

## 6. ACTIVE CONTEXT — INTEGRACIÓN (ACTIVE CONTEXT INTEGRATION)

### Patrón de Integración Demostrado:
El middleware existente `activeContextMiddleware.js` proporciona el anclaje de seguridad necesario para cualquier nuevo componente:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                    ACTIVE CONTEXT RUNTIME INTEGRATION                       │
│                                                                             │
│  [CLIENT HTTP REQUEST]                                                      │
│  ├── Authorization: Bearer <jwt>                                            │
│  └── x-active-membership-id: <UUID>                                         │
│            │                                                                │
│            ▼                                                                │
│  [activeContextMiddleware.js]                                               │
│  ├── Valida identidad del usuario (req.user.id)                             │
│  ├── Valida membresía activa en DB (memberships.status = 'ACTIVE')          │
│  └── Deriva server-side e inyecta en req:                                   │
│        • req.tenantId (INT)                                                 │
│        • req.establishmentId (UUID)                                         │
│        • req.membershipId (UUID)                                            │
│        • req.activeContext.role ('OWNER' | 'MANAGER' | 'PROFESSIONAL' | ...)│
│                                                                             │
│  [POSTGRESQL RLS ENCAPSULATION]                                             │
│  └── SELECT set_config('app.tenant_id', req.tenantId, true);                │
└─────────────────────────────────────────────────────────────────────────────┘
```

> **[EVIDENCIA + DECISIÓN YA CERRADA]:** Ningún endpoint de Service Offer ni Assignment requiere recibir `tenant_id` ni `establishment_id` desde el cliente. Ambos se derivan estrictamente server-side desde el contexto activo validado.

---

## 7. HUB SALÓN — RELACIÓN (HUB SALÓN BOUNDARY RELATION)

Se analizó el contrato aprobado `HUB-SALON-NODE-CONTRACT-v1.0.md`:
- **Propósito de Hub Salón:** Cockpit operacional, resumen de sucursal (`GET /summary`) y visibilidad de equipo (`GET /staff`).
- **Límites de Hub Salón (NON_SCOPE, Sección 5):**
  - Hub Salón v1.0 declaró explícitamente fuera de alcance la administración de catálogos y la gestión transaccional.
- **Relación Arquitectónica:**
  - `Hub Salón` es el *portal/anfitrión* operacional donde reside el contexto de la sede activa.
  - La administración de Catálogo (`service_offers`) y Asignaciones (`service_assignments`) constituye un **dominio funcional complementario** que consume el mismo Active Context que Hub Salón, pero excede el alcance del Node Contract de Hub Salón v1.0.

---

## 8. AUTORIZACIÓN EXISTENTE (REUSABLE AUTHORIZATION CONTROLS)

Se identificaron tres capas de control de autorización listas para reutilizar:

1. **Capa 1 — Autenticación de Identidad:**
   - Middleware `authMiddleware.js` / JWT verification (`req.user.id`).
2. **Capa 2 — Validación de Contexto Activo y Sede:**
   - Middleware `activeContextMiddleware.js` (`req.tenantId`, `req.establishmentId`, `req.activeContext`).
3. **Capa 3 — Control de Autoridad RBAC (`DEC-AS-001`):**
   - Regla cerrada: Para crear, modificar o eliminar ofertas y asignaciones se exige:
     $$	ext{req.activeContext.role} \in \{	ext{'OWNER'}, 	ext{'MANAGER'}\}$$
   - Para consultar ofertas y asignaciones:
     $$	ext{req.activeContext.role} \in \{	ext{'OWNER'}, 	ext{'MANAGER'}, 	ext{'PROFESSIONAL'}, 	ext{'RECEPTIONIST'}\}$$
4. **Capa 4 — Aislamiento Físico Multi-Tenant (PostgreSQL RLS):**
   - Transacción con `SET LOCAL app.tenant_id = $1` protegiendo `service_offers` y `service_assignments`.

---

## 9. OPERACIONES REALMENTE RESPALDADAS (BACKED OPERATIONS)

Las siguientes operaciones están **100% respaldadas** por contratos y decisiones arquitectónicas cerradas:

### 9.1. Dominio SERVICE_OFFER:
1. **`CREATE_SERVICE_OFFER` (`POST`):**
   - Requiere: Autoridad `OWNER` / `MANAGER` en contexto activo.
   - Parámetros: `name`, `description` (opcional), `base_duration` (>0), `base_price` (>=0).
   - Derivación: `tenant_id` y `establishment_id` inyectados desde Active Context.
2. **`LIST_SERVICE_OFFERS` (`GET`):**
   - Retorna todas las ofertas de la sede activa (`WHERE establishment_id = $1 AND tenant_id = $2`).
3. **`GET_SERVICE_OFFER_BY_ID` (`GET /:id`):**
   - Retorna detalle de una oferta específica verificando que pertenezca a la sede activa.
4. **`UPDATE_SERVICE_OFFER` (`PUT /:id`):**
   - Actualiza `name`, `description`, `base_duration`, `base_price` y `updated_at`.

### 9.2. Dominio ASSIGNMENT:
1. **`CREATE_ASSIGNMENT` (`POST`):**
   - Requiere: Autoridad `OWNER` / `MANAGER` en contexto activo (`DEC-AS-001`).
   - Parámetros: `service_offer_id` (UUID) y `membership_id` (UUID target).
   - Validación Server-Side:
     - `service_offer_id` pertenece a la sede activa (`DEC-AS-005`, `DEC-AS-007`).
     - `membership_id` pertenece a la sede activa y tiene status `ACTIVE` (`DEC-AS-001`, `DEC-AS-006`, `DEC-AS-009`).
   - Inserción: `INSERT INTO service_assignments (tenant_id, establishment_id, service_offer_id, membership_id)`.
2. **`LIST_ESTABLISHMENT_ASSIGNMENTS` (`GET`):**
   - Retorna la matriz de asignaciones de la sede activa.
3. **`LIST_ASSIGNMENTS_BY_STAFF` (`GET /staff/:membership_id`):**
   - Retorna servicios asignados a un colaborador específico dentro de la sede activa.
4. **`LIST_ASSIGNMENTS_BY_OFFER` (`GET /offers/:offer_id`):**
   - Retorna colaboradores asignados a un servicio específico dentro de la sede activa.
5. **`DELETE_ASSIGNMENT` (`DELETE /:id` o `DELETE /offer/:offer_id/staff/:membership_id`):**
   - Ejecuta desasignación pura (`DEC-AS-012`). No altera `service_offers` ni `memberships`.

---

## 10. VACÍOS ARQUITECTÓNICOS (ARCHITECTURAL GAPS & PENDING DECISIONS)

Las siguientes materias **NO están cerradas** y **NO deben implementarse** sin decisión directiva previa:

1. **`DELETE SERVICE_OFFER`:**
   - *Estado:* `UNDEFINED / FUTURE DECISION` (`ARCH-BUNDLE-SO-01-R1`).
   - *Vacio:* No está definido si el borrado de una oferta debe bloquearse (`RESTRICT`), desasignar colaboradores automáticamente o prohibirse.
2. **`is_active` en `SERVICE_OFFER`:**
   - *Estado:* `UNDEFINED / PENDING DECISION` (`ARCH-BUNDLE-SO-01-R1`).
   - *Vacio:* La columna no existe en la base de datos física. No implementar toggles comerciales de activación/desactivación de oferta.
3. **Taxonomía / Categorías de Servicio:**
   - *Estado:* `UNDEFINED / FUTURE DESIGN`. No implementar campos `category` inventados.
4. **Auditoría de Modificaciones de Asignación:**
   - *Estado:* `UNDEFINED / FUTURE AUDIT SUBSYSTEM` (`DEC-AS-013-F`).
5. **Materialización Downstream hacia B2C (`public.services`):**
   - *Estado:* `CLOSED AS DECOUPLED / PENDING MATERIALIZATION WORKER` (`DEC-SE-001`, `DEC-SE-002`, `DEC-AS-003`).

---

## 11. CONTRADICCIONES (CONTRADICTION ANALYSIS)

- **Evaluación:** Se comparó el estado del código actual en `backend/src/` con las decisiones `DEC-AS-001..014`, `DEC-FC-001`, `SO-PHYSICAL-01-R1` y `AS-PHYSICAL-01-R1`.
- **Resultado:** **CERO CONTRADICCIONES DETECTADAS.**
- El código existente de Foundation (`065`, `066`), Active Context y Hub Salón no contiene asunciones erróneas sobre asignación ni colisiona con las nuevas tablas.

---

## 12. DEPENDENCIAS (PROTECTED DOMAIN DEPENDENCIES)

- **Evaluación de Riesgo de Desbordamiento:** ¿La implementación del runtime de Service Offers y Assignments obliga a modificar algún dominio protegido?
- **Resultado:** **NO.**
  - Foundation permanece 100% protegida.
  - Context Resolution (`066`) permanece 100% protegida.
  - Active Context permanece 100% protegido.
  - Pre-Nodo 01 / B2C permanece 100% inmutable.
  - Las nuevas operaciones se ejecutarán exclusivamente sobre `service_offers` y `service_assignments` utilizando las funciones y middlewares ya establecidos.

---

## 13. OPCIONES ARQUITECTÓNICAS PARA EL RUNTIME

Se evaluaron dos opciones estructurales para la organización del nuevo runtime:

### OPCIÓN A — RUNTIME SEPARADO EN DOS SERVICIOS INDEPENDIENTES (Recomendada)
- **Estructura:**
  - `serviceOfferService.js` (Gestión pura de catálogo de ofertas).
  - `serviceAssignmentService.js` (Gestión pura de asignaciones $N:M$ entre Offer y Membership).
- **Controladores / Rutas:**
  - Rutas bajo el namespace `/api/v1/saas/hub/services` y `/api/v1/saas/hub/assignments` (o unificadas bajo `/api/v1/saas/catalog`).
- **Ventajas:**
  - Respeta la disyunción ontológica (`SERVICE_OFFER ≠ ASSIGNMENT`).
  - Previene el acoplamiento de lógica de personal dentro de la entidad de catálogo.
  - Facilita pruebas unitarias desacopladas.

### OPCIÓN B — SERVICIO MONOLÍTICO COMBINADO
- **Estructura:** Un único archivo `catalogManagementService.js` conteniendo lógica de ofertas y asignaciones mezcladas.
- **Desventajas:** Viola el principio de responsabilidad única y diluye la independencia de la entidad `ASSIGNMENT`.

---

## 14. RECOMENDACIÓN FORMAL AL DIRECTOR (TECHNICAL RECOMMENDATION)

1. **Adoptar la OPCIÓN A:** Diseñar el runtime con dos servicios desacoplados (`serviceOfferService` y `serviceAssignmentService`), consumiendo `activeContextMiddleware`.
2. **Definición de Nodo:** Proceder a la formulación del **Node Contract del Siguiente Nodo** (ej. `SAAS-CATALOG-ASSIGNMENT-NODE-CONTRACT-v1.0` o `NODO-02`), delimitando formalmente:
   - Endpoints de Catálogo de Ofertas (`POST`, `GET`, `GET /:id`, `PUT /:id`).
   - Endpoints de Asignación Operativa (`POST`, `GET`, `GET /staff/:id`, `GET /offer/:id`, `DELETE /:id`).
   - Matriz de validación RBAC (`OWNER`/`MANAGER`).
3. **Preservar Vacíos:** Mantener estrictamente fuera de alcance `DELETE SERVICE_OFFER`, `is_active` y materialización B2C hasta sus respectivos GOALs directivos.

---

## 15. DECISIONES QUE REQUIEREN AL DIRECTOR (DIRECTOR DECISION REQUIRED)

Se somete a consideración del Director:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                          DECISIONES PARA EL DIRECTOR                         │
├─────────────────────────────────────────────────────────────────────────────┤
│ 1. ¿Aprueba el Director el diagnóstico de descubrimiento y la OPCIÓN A      │
│    (Servicios desacoplados para Service Offer y Service Assignment)?        │
│                                                                             │
│ 2. ¿Autoriza el Director la emisión del Node Contract para el componente    │
│    de Runtime de Catálogo y Asignaciones (NODO-02 / Catalog & Assignment)?   │
│                                                                             │
│ 3. ¿Ratifica el Director que las operaciones respaldadas identificadas     │
│    (Sección 9) constituyen el alcance exacto de la siguiente fase?         │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 16. SELF-CHECK DE GOVERNANCE

```text
================================================================================
ARCH-BUNDLE-SO-ASSIGNMENT-RUNTIME-DISCOVERY-01 — SELF-CHECK
================================================================================

Code written in this GOAL:                  0
Endpoints created in this GOAL:             0
Controllers created in this GOAL:           0
Services created in this GOAL:              0
Routes created in this GOAL:                0
Frontend touched in this GOAL:              0

Migrations created in this GOAL:            0
DDL executed in this GOAL:                  0
DML executed in this GOAL:                  0

Foundation modified:                        0
Pre-Node 01 modified:                       0
HBC modified:                               0
NODO-01 modified:                           0
B2C modified:                               0

Evidence classified rigorously:             YES (EVIDENCIA / DECISIÓN / PROPUESTA)
Contradictions detected:                    0
Protected domain dependencies violated:     0

NEXT STEP:
AWAIT DIRECTOR GATE ON DISCOVERY FINDINGS
================================================================================
```
