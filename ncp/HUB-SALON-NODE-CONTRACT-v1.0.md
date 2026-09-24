# HUB SALÓN v1.0 — NODE CONTRACT
## Node Construction Protocol — Architectural Node Specification

**Versión:** 1.0.0  
**Estado:** DEFINED / PENDING DIRECTOR APPROVAL  
**Fase Metodológica:** DEFINIR → RELACIONAR → VALIDAR  
**Ámbito:** Cockpit Operacional, Resumen de Sede, Visibilidad de Staff y Ancla de Contexto SaaS  
**Autoridad Raíz:** Director del Proyecto GlowApp SaaS  

---

## 1. NODE_ID

```text
HUB-SALON-v1.0
```

---

## 2. NAME

```text
Hub Salón Operational Cockpit & Overview Protocol v1.0
```

---

## 3. PURPOSE

Formalizar el contrato arquitectónico para el espacio de trabajo operacional (Cockpit) del establecimiento activo (`establishment_id`) en GlowApp SaaS. Este nodo provee la interfaz de entrada, la consulta consolidada del estado y perfil de la sucursal activa (`GET /summary`), el listado de colaboradores vinculados a dicha sede (`GET /staff`) y la visibilidad de rol contextual para el usuario (`OWNER`, `MANAGER`, `PROFESSIONAL`, `RECEPTIONIST`), consumiendo estrictamente el contexto validado por `ACTIVE CONTEXT v1.0` (`x-active-membership-id`) bajo el aislamiento multitenant de PostgreSQL RLS.

---

## 4. SCOPE

### En Alcance:
1. **Punto de Entrada Operacional (Cockpit):** Servir como tablero de comando principal para la sede física activa una vez validado el `Active Context`.
2. **Contrato de Resumen de Establecimiento (`GET /api/v1/saas/hub/summary`):**
   * Retornar información del establecimiento activo (`id`, `name`, `slug`, `phone`, `address`, `city`, `is_active`, `operating_hours`).
   * Retornar información de la organización matriz (`id`, `legal_name`).
   * Retornar contexto del usuario activo (`membership_id`, `role`, `relation_type`).
   * Retornar métricas resumen no transaccionales (p. ej. conteo de miembros activos del staff).
3. **Contrato de Visibilidad de Equipo / Staff (`GET /api/v1/saas/hub/staff`):**
   * Retornar la lista de colaboradores con membresía `ACTIVE` vinculados al `establishment_id` activo (`membership_id`, `user_id`, `user_name`, `user_email`, `role`, `relation_type`, `status`, `joined_at`).
4. **Conmutación de Contexto (Branch Switcher):**
   * Reutilizar exclusivamente el flujo de `Context Resolution v1.0` (para listar disponibles) y `Active Context v1.0` (para activar nuevo `membership_id`) sin duplicar lógica de conmutación.
5. **Alineación con SOUL + Governance:**
   * Aplicar tokens de diseño y estándares de presentación según la capa transversal de gobernanza.

---

## 5. NON_SCOPE

### Fuera de Alcance Absoluto:
1. **Cero Módulos Transaccionales Complejos:** Prohibido implementar en este nodo:
   * Agenda / Turnos / Citas en tiempo real (Pertenecen a futuros nodos de Agenda).
   * Punto de Venta (POS) / Caja / Facturación / Cobros / Comisiones (Pertenecen a futuros nodos de Finanzas/Caja).
   * Gestión de Inventario y Stock de Productos (Pertenecen a futuros nodos de Inventario).
2. **Cero Motor RBAC Granular o Permisos Custom:** No diseñar matrices complejas de capabilities o permisos ad-hoc. El rol se deriva rígidamente del enum existente (`OWNER`, `MANAGER`, `PROFESSIONAL`, `RECEPTIONIST`).
3. **Cero Aprovisionamiento / Onboarding:** `CREAR DESDE CERO` y asistentes de registro pertenecen a flujos de aprovisionamiento previos. Hub Salón NO crea organizaciones, NO crea establecimientos y NO ejecuta onboarding inicial.
4. **Cero Endpoint de Modificación de Configuración (`PUT /settings`):** La edición y actualización de datos de la sede queda expresamente excluida de esta versión v1.0.
5. **Cero Modificación a Pre-Nodo 01:** Ningún acoplamiento con la lógica ni controladores del core B2C/Prestador individual.
6. **Cero Nuevas Entidades o Tablas:** No crear entidades `Hub`, `HubContext`, `SalonContext`, ni columnas `hub_id`.

---

## 6. INPUTS

Hub Salón consume la petición autenticada y el contexto activo validado server-side:

### A. Transporte de Contexto (ARCH-AC-001)
* **Header HTTP Requerido:** `x-active-membership-id: <UUID>`

### B. Contexto de Seguridad Server-Side (Inyectado por `activeContextMiddleware`)
* **`req.user.id` (`identity_id`):** Identificador primario de la identidad autenticada.
* **`req.tenantId`:** Tenant ID resuelto server-side vía `fn_resolve_user_tenant`.
* **`req.establishmentId`:** Establecimiento UUID derivado de la membresía activa.
* **`req.activeContext`:** DTO completo de Active Context validado.

### Regla de Autoridad de Entrada:
```text
CLIENT INPUT       = ONLY Authorization Bearer token + x-active-membership-id header
SERVER DERIVATION  = tenant_id, organization_id, establishment_id, role, relation_type, is_active
```
El cliente **NUNCA** provee `tenant_id`, `establishment_id` ni `role` en el query string o body como parámetros autoritativos.

---

## 7. OUTPUTS

### A. Output Contract: Resumen del Salón (`GET /api/v1/saas/hub/summary`)
```json
{
  "status": "success",
  "data": {
    "summary": {
      "establishment": {
        "id": "841b5d26-c479-432d-b0c9-6653343aa3f1",
        "name": "Salón Elegance Studio Chicó",
        "slug": "elegance-studio-chico",
        "phone": "+573101234567",
        "address": "Carrera 11 # 93-45",
        "city": "Bogotá",
        "is_active": true,
        "operating_hours": {
          "monday_friday": "08:00-20:00",
          "saturday": "09:00-19:00",
          "sunday": "closed"
        }
      },
      "organization": {
        "id": "876ba9e8-f8e0-42b4-a805-a5ef94619664",
        "legal_name": "Luxe Beauty Group S.A.S."
      },
      "active_user_context": {
        "membership_id": "3f183a7e-ae88-4588-b7a9-8925463997e0",
        "role": "OWNER",
        "relation_type": "OWNER_PARTNER",
        "membership_status": "ACTIVE"
      },
      "staff_summary": {
        "active_members_count": 5
      }
    }
  }
}
```

### B. Output Contract: Equipo / Staff del Salón (`GET /api/v1/saas/hub/staff`)
```json
{
  "status": "success",
  "data": {
    "establishment_id": "841b5d26-c479-432d-b0c9-6653343aa3f1",
    "staff_count": 2,
    "members": [
      {
        "membership_id": "3f183a7e-ae88-4588-b7a9-8925463997e0",
        "user_id": 7,
        "role": "OWNER",
        "relation_type": "OWNER_PARTNER",
        "status": "ACTIVE",
        "joined_at": "2026-09-10T21:34:43.413Z"
      },
      {
        "membership_id": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
        "user_id": 12,
        "role": "PROFESSIONAL",
        "relation_type": "STAFF_EMPLOYEE",
        "status": "ACTIVE",
        "joined_at": "2026-09-10T22:15:00.000Z"
      }
    ]
  }
}
```

---

## 8. PRECONDITIONS

Para que Hub Salón v1.0 pueda operar, el entorno debe satisfacer:
1. **Nodos Previos Cerrados:** `PRE-NODE-01`, `SAAS-FOUNDATION-v1.0`, `CONTEXT-RESOLUTION-v1.0`, `NCP-CORE-v1.0` y `ACTIVE-CONTEXT-v1.0` en estado `CLOSED`.
2. **Identidad Autenticada:** Petición HTTP con identidad válida server-side (`req.user.id`).
3. **Active Context Validado:** Petición con header `x-active-membership-id: <UUID>` válido e interceptado por `activeContextMiddleware`.
4. **Aislamiento Multitenant Activo:** Consultas ejecutadas bajo `SET LOCAL app.tenant_id = '<tenant_id>'` y rol `beauty_app_user`.

---

## 9. DEPENDENCIES

```text
┌────────────────────────────────────────────────────────┐
│               SAAS FOUNDATION v1.0                     │ [CLOSED]
│  Esquema físico, RLS, tenants, establishments          │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│              CONTEXT RESOLUTION v1.0                   │ [CLOSED]
│  Resolución de Available Contexts (NO / ONE / MULTIPLE)│
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│               ACTIVE CONTEXT v1.0                      │ [CLOSED]
│  activeContextMiddleware & x-active-membership-id      │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│                 HUB SALÓN v1.0                         │ [ESTE CONTRATO]
│  Cockpit Operacional, GET /summary, GET /staff         │
└────────────────────────────────────────────────────────┘
```

---

## 10. ENTITIES

Hub Salón **NO CREA ENTIDADES NUEVAS**. Consume exclusivamente las entidades físicas existentes de SaaS Foundation v1.0:
1. **`tenants`:** Límite supremo de aislamiento.
2. **`organizations`:** Entidad jurídica/comercial.
3. **`establishments`:** Unidad física/salón activo (`name`, `slug`, `phone`, `address`, `city`, `is_active`, `operating_hours`).
4. **`memberships`:** Miembros del staff vinculados al establecimiento (`user_id`, `role`, `relation_type`, `status`).
5. **`usuarios`:** Identidad básica de los miembros del equipo.

---

## 11. RELATIONSHIPS

Las consultas de Hub Salón operan sobre la jerarquía relacional física de Foundation v1.0:

```text
ESTABLISHMENT (id = req.establishmentId, tenant_id = req.tenantId)
    ├── [FK: organization_id, tenant_id] ────────► ORGANIZATIONS (id, tenant_id)
    │
    └── [FK: establishment_id, tenant_id] ◄─────── MEMBERSHIPS (id, user_id, role, status='ACTIVE', tenant_id)
                                                    │
                                                    └── [FK: user_id, tenant_id] ─► USUARIOS (id, tenant_id)
```

---

## 12. BUSINESS_RULES

1. **Aislamiento por Sede Activa:** El Hub Salón solo expone datos pertenecientes al `establishment_id` validado en el Active Context. Cero visualización o cruce de datos entre sucursales distintas.
2. **Filtrado de Staff Activo:** El endpoint `/staff` lista exclusivamente membresías con `status = 'ACTIVE'`. Membresías `INVITED`, `SUSPENDED` o `REVOKED` son excluidas de la lista operativa de colaboradores.
3. **Semántica de `establishments.is_active`:** `is_active` es metadato informativo. Si `is_active = false`, el Hub responde exitosamente con `is_active: false` permitiendo a los administradores (`OWNER`/`MANAGER`) visualizar el estado de cierre/mantenimiento.
4. **Presentación de Rol Contextual:** La información del usuario activo dentro del Hub refleja estrictamente su `role` en la membresía actual (`OWNER`, `MANAGER`, `PROFESSIONAL`, `RECEPTIONIST`), sin recurrir a columnas legacy (`usuarios.rol`, `id_dueno`).
5. **Reutilización de Conmutación de Contexto:** El cambio de sucursal se delega enteramente a `Active Context v1.0` mediante una nueva petición con el `x-active-membership-id` de la otra sede.

---

## 13. SECURITY_RULES

1. **Protección Obligatoria por Middleware:** Todo endpoint de Hub Salón debe estar custodiado por `authMiddleware` seguido obligatoriamente de `activeContextMiddleware`.
2. **Zero Client Authority:** El `establishment_id` y `tenant_id` se obtienen exclusivamente de `req.establishmentId` y `req.tenantId` inyectados por el middleware server-side.
3. **Prevención de Enumeración / Fuga de Datos:** Las consultas ejecutan bajo `SET LOCAL app.tenant_id = '<tenant_id>'` garantizando que el motor RLS de PostgreSQL impida físicamente acceder a organizaciones o sucursales de otros tenants.
4. **Ejecución bajo Principio de Mínimo Privilegio:** Operaciones de lectura ejecutadas bajo el usuario de runtime no privilegiado `beauty_app_user`.

---

## 14. DATA_RULES

```text
NEW TABLES        = 0
NEW COLUMNS       = 0
NEW ENTITIES      = 0
NEW MIGRATIONS    = 0
MODIFIED TABLES   = 0
```

---

## 15. INTEGRATION_BOUNDARIES

```text
┌────────────────────────────────────────────────────────┐
│                  ACTIVE CONTEXT v1.0                   │
│  Inyecta: req.activeContext, req.establishmentId       │
└──────────────────────────┬─────────────────────────────┘
                           │ (Petición HTTP con x-active-membership-id)
                           ▼
┌────────────────────────────────────────────────────────┐
│                   HUB SALÓN v1.0                       │
│  Expone: GET /summary, GET /staff                      │
└──────────────────────────┬─────────────────────────────┘
                           │ (Punto de ancla y navegación)
                           ▼
┌────────────────────────────────────────────────────────┐
│            FUTUROS SUB-NODOS OPERACIONALES             │
│  [Agenda / Turnos] [Catálogo Servicios] [Caja / POS]   │
└────────────────────────────────────────────────────────┘
```

---

## 16. ALLOWED_CHANGES

Durante la futura fase de implementación (cuando sea autorizada por el Director), los únicos cambios permitidos serán:
* Creación de `backend/src/services/hubSalonService.js` (Lógica de consulta de resumen y staff).
* Creación de `backend/src/controllers/hubSalonController.js` (Controladores HTTP `/summary` y `/staff`).
* Creación de `backend/src/routes/hubSalonRoutes.js` (Enrutador `/api/v1/saas/hub`).
* Montaje seguro de `hubSalonRoutes` en `backend/index.js` (o `app.js`).
* Creación de suite de tests unitarios y de integración para Hub Salón.

---

## 17. PROTECTED_ASSETS

Los siguientes activos permanecen estrictamente inmutables y protegidos:
1. `backend/migrations/065_saas_foundation_core.sql`
2. `backend/migrations/066_context_resolution_tenant_resolver.sql`
3. `fn_resolve_user_tenant` (PostgreSQL)
4. `backend/src/services/contextResolutionService.js`
5. `backend/src/controllers/contextController.js`
6. `backend/src/routes/contextRoutes.js`
7. `backend/src/services/activeContextService.js`
8. `backend/src/controllers/activeContextController.js`
9. `backend/src/middleware/activeContextMiddleware.js`
10. `backend/src/routes/activeContextRoutes.js`
11. `Pre-Nodo 01` (Core B2C intacto)
12. `SOUL` / `Governance` / Contratos NCP anteriores

---

## 18. FORBIDDEN_CHANGES

* Prohibido crear tablas o columnas en base de datos.
* Prohibido implementar lógica transaccional de Agenda, Citas o Turnos.
* Prohibido implementar lógica de Pagos, Caja o Facturación.
* Prohibido implementar endpoints de modificación (`PUT /settings`) en esta versión.
* Prohibido crear asistentes de Onboarding o aprovisionamiento dentro de este nodo.
* Prohibido modificar o acoplar controladores de `PRE-NODE-01`.
* Prohibido eludir `activeContextMiddleware`.

---

## 19. VALIDATION_PLAN

El plan de validación para la fase de implementación incluirá los siguientes escenarios formales:

| ID | Escenario de Prueba | Entrada | Resultado Esperado |
| :--- | :--- | :--- | :--- |
| **VAL-HUB-01** | Consulta de resumen con Active Context válido | `GET /summary` + `x-active-membership-id` legítimo | `200 OK` + DTO de resumen con establecimiento, organización y conteo de staff |
| **VAL-HUB-02** | Consulta de staff con Active Context válido | `GET /staff` + `x-active-membership-id` legítimo | `200 OK` + Lista de miembros `ACTIVE` del establecimiento |
| **VAL-HUB-03** | Petición sin header `x-active-membership-id` | `GET /summary` sin header | `400 Bad Request` (`MISSING_ACTIVE_MEMBERSHIP_HEADER`) |
| **VAL-HUB-04** | Petición con identidad no autenticada | `GET /summary` sin token | `401 Unauthorized` (`IDENTITY_NOT_FOUND`) |
| **VAL-HUB-05** | Petición con membresía de otro usuario | `GET /summary` + membership ajena | `403 Forbidden` (`MEMBERSHIP_ACCESS_DENIED`) |
| **VAL-HUB-06** | Aislamiento entre sucursales de un mismo tenant | `GET /staff` en sucursal A | Retorna únicamente miembros de sucursal A; excluye sucursal B |
| **VAL-HUB-07** | Establecimiento inactivo (`is_active = false`) | `GET /summary` en local cerrado | `200 OK` con `establishment.is_active: false` |
| **VAL-HUB-08** | Aislamiento RLS en consultas del Hub | Consultas `/summary` y `/staff` | Ejecución estricta bajo `app.tenant_id` sin fugas cross-tenant |

---

## 20. CLOSURE_CRITERIA

El nodo `HUB-SALON-v1.0` se considerará cerrado únicamente cuando:
1. El presente Node Contract sea aprobado formalmente por el Director del Proyecto.
2. Los componentes autorizados en `ALLOWED_CHANGES` estén implementados físicamente.
3. El 100% de las pruebas del `VALIDATION_PLAN` (VAL-HUB-01 a VAL-HUB-08) pasen exitosamente.
4. Ningún activo protegido haya sido modificado.
5. La auditoría independiente emita dictamen de `READY_FOR_CLOSURE`.
6. El Director emita la declaración formal de `CLOSED`.

---

## 21. OPEN_DECISIONS

Las siguientes definiciones permanecen documentadas para eventual consideración futura:

### OPEN_DECISION_01: Incorporación de Endpoint de Configuración Básica (`PUT /settings`)
* **Estado:** `DEFERRED / FUERA DE SCOPE v1.0`
* **Pregunta:** ¿Debe permitirse a los roles `OWNER`/`MANAGER` actualizar teléfono, horarios o descripción del salón desde este nodo o en un nodo dedicado de Administración de Sede?
* **Decisión Actual del Director:** Queda expresamente fuera de alcance para `HUB SALÓN v1.0`, asegurando máxima economía y enfoque exclusivo en el cockpit de consulta y visualización.

---

```text
================================================================================
             HUB SALÓN v1.0 — NODE CONTRACT FORMAL SPECIFICATION
================================================================================
ESTADO: DEFINED — PENDING DIRECTOR APPROVAL 🟡
================================================================================
```
