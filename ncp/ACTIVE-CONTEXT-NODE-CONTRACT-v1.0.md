# ACTIVE CONTEXT v1.0 — NODE CONTRACT
## Node Construction Protocol — Architectural Node Specification

**Versión:** 1.0.0  
**Estado:** DEFINED / READY FOR DIRECTOR APPROVAL  
**Fase Metodológica:** ARCHITECTURAL RECONCILIATION → VALIDATION  
**Ámbito:** Selección Explícita, Activación y Propagación de Contexto de Establecimiento SaaS  
**Autoridad Raíz:** Director del Proyecto GlowApp SaaS  

---

## 1. NODE_ID

```text
ACTIVE-CONTEXT-v1.0
```

---

## 2. NAME

```text
Active Context Resolution & Propagation Protocol v1.0
```

---

## 3. PURPOSE

Formalizar el contrato arquitectónico mediante el cual una identidad autenticada (`req.user.id`), habiendo obtenido su conjunto determinista de contextos disponibles (`Available Contexts`) resueltos server-side mediante la arquitectura de `Context Resolution v1.0`, solicita la activación explícita de un único contexto de establecimiento (`membership_id`), permitiendo al servidor validar la pertenencia legítima, verificar el estado activo de la membresía y propagar el contexto transaccional y operativo necesario para alimentar subsecuentes peticiones hacia el Hub de Salón bajo estricto aislamiento multitenant (PostgreSQL RLS).

---

## 4. SCOPE

### En Alcance:
1. **Contrato de Solicitud de Activación:** Recibir la selección explícita del contexto deseado mediante su identificador técnico estable (`membership_id`).
2. **Validación Server-Side Estricta:**
   * Verificación de existencia física de la membresía solicitada.
   * Verificación de pertenencia estricta: `memberships.user_id == req.user.id`.
   * Verificación de estado: `memberships.status == 'ACTIVE'`.
   * Verificación de afinidad de Tenant: `memberships.tenant_id == usuarios.tenant_id` (resuelto server-side vía `fn_resolve_user_tenant`).
   * Verificación de integridad relacional: Asociación válida de la membresía con su establecimiento (`establishments`) y derivación server-side hacia la organización matriz (`organizations`).
3. **Derivación Determinista del Contexto Activo:** Extracción server-side de los metadatos contextuales (`tenant_id`, `organization_id`, `establishment_id`, `establishment_name`, `establishment_slug`, `establishment_is_active`, `role`, `relation_type`).
4. **Respeto a Multiplicidad:** Tratamiento determinista de los estados de entrada: `NO_CONTEXT`, `ONE_CONTEXT`, `MULTIPLE_CONTEXTS`.
5. **Generación del Output Contract de Active Context:** Estructura de respuesta y transporte para consumo de capas superiores.
6. **Manejo Determinista de Fallos:** Respuestas estandarizadas sin degradación silenciosa ni accesos implícitos.

---

## 5. NON_SCOPE

### Fuera de Alcance Absoluto:
1. **Cero Creación de Entidades "Context":** Prohibido crear tablas `contexts`, columnas `context_id`, UUIDs de contexto sintéticos o registros persistentes de sesión de contexto en base de datos.
2. **Cero Modificación a la Estructura de Memberships:** Prohibido crear columnas `organization_id` o FKs directas a `organizations` dentro de la tabla `memberships`.
3. **Cero Funciones SQL Inventadas:** Prohibido crear nuevas funciones SQL o alterar la migración 066 (`fn_resolve_user_tenant`).
4. **Cero Motor RBAC / Permisos Granulares:** No diseñar matrices de permisos, capabilities, ACLs complejas ni roles custom. El rol se deriva rígidamente del enum existente (`OWNER`, `MANAGER`, `PROFESSIONAL`, `RECEPTIONIST`).
5. **Cero Lógica de Negocio de Salón:** No diseñar interfaces, vistas ni flujos operacionales de `Hub Salón`, Agenda, Caja, Clientes, Empleados o Inventario.
6. **Cero Modificación a Pre-Nodo 01:** Ninguna alteración a rutas, controladores o esquemas del core B2C.
7. **Cero Modificación a Foundation v1.0 y Context Resolution v1.0:** Inmutabilidad absoluta de migraciones 065 y 066.
8. **Cero Selección Automática No Autorizada:** No priorizar roles (`OWNER`/`MANAGER`), no utilizar orden de creación, no invocar `id_dueno` ni `usuarios.rol`.

---

## 6. INPUTS

Active Context recibe una combinación estricta de contexto de seguridad server-side e input explícito del cliente:

### A. Contexto de Seguridad Server-Side (Inmutable por el Cliente)
* **`req.user.id` (`identity_id`):** Identificador primario de la identidad autenticada (Integer derivado del token de autenticación/sesión existente).
* **`usuarios.tenant_id`:** Tenant resuelto server-side mediante `fn_resolve_user_tenant(req.user.id)`.

### B. Input de Selección del Cliente (Transporte Canónico ARCH-AC-001)
* **Header HTTP:** `x-active-membership-id: <UUID>` (UUID v4 de la membresía que el usuario desea activar explícitamente).

```http
x-active-membership-id: c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33
```

### Regla de Autoridad de Entrada:
```text
CLIENT AUTHORITY = ONLY membership_id selection via x-active-membership-id header
SERVER AUTHORITY = identity_id, tenant_id, organization_id, establishment_id, role, relation_type
```
El cliente **NUNCA** puede proveer `tenant_id`, `organization_id`, `establishment_id`, `role` ni `relation_type` como parámetros autoritativos.

---

## 7. OUTPUTS

Active Context produce dos estructuras claramente diferenciadas:

### A. Referencia Canónica Activa (Para Transporte)
* **`active_membership_id`:** UUID de la membresía activa validada.

### B. DTO de Contexto Activo Derivado Server-Side (Para Consumo de UI / Hub)
```json
{
  "active_context": {
    "membership_id": "c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33",
    "tenant_id": 2,
    "tenant_name": "Demo Tenant",
    "organization_id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
    "organization_legal_name": "Luxe Beauty Group S.A.S. (Demo)",
    "establishment_id": "b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22",
    "establishment_name": "Salón Elegance Studio Chicó (Demo)",
    "establishment_slug": "elegance-studio-chico",
    "establishment_is_active": true,
    "role": "OWNER",
    "relation_type": "OWNER_PARTNER",
    "membership_status": "ACTIVE",
    "activated_at": "2026-09-10T17:55:00Z"
  }
}
```

---

## 8. PRECONDITIONS

Para que Active Context pueda operar, el entorno debe satisfacer:
1. **Identidad Autenticada:** Petición HTTP con identidad válida verificada server-side (`req.user.id` no nulo).
2. **Resolución de Tenant Persistida:** Función SQL `fn_resolve_user_tenant(p_user_id)` operativa en PostgreSQL (migración 066).
3. **Context Resolution v1.0 Operativa:** Servicio de resolución de Available Contexts (`contextResolutionService.js`) cerrado y disponible.
4. **Infraestructura Multitenant Activa:** Tablas `tenants`, `organizations`, `establishments`, `memberships` con RLS habilitado y rol `beauty_app_user`.
5. **Nodos Previos Cerrados:** `PRE-NODE-01`, `SAAS-FOUNDATION-v1.0`, `CONTEXT-RESOLUTION-v1.0`, `NCP-CORE-v1.0` en estado `CLOSED`.

---

## 9. DEPENDENCIES

```text
┌────────────────────────────────────────────────────────┐
│               SAAS FOUNDATION v1.0                     │ [CLOSED]
│  Esquema físico, RLS, memberships, establishments      │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│              CONTEXT RESOLUTION v1.0                   │ [CLOSED]
│  fn_resolve_user_tenant() & contextResolutionService   │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│               ACTIVE CONTEXT v1.0                      │ [ESTE CONTRATO]
│  Selección, validación y propagación de membership_id   │
└────────────────────────────────────────────────────────┘
```

---

## 10. ENTITIES

Active Context **NO CREA ENTIDADES NUEVAS**. Opera exclusivamente sobre las entidades físicas existentes de SaaS Foundation v1.0:

1. **`usuarios`:** Identidad (`id`, `tenant_id`, `email`).
2. **`tenants`:** Límite supremo de aislamiento (`id`, `name`, `status`).
3. **`organizations`:** Entidad jurídica/comercial (`id`, `tenant_id`, `legal_name`).
4. **`establishments`:** Unidad física/salón (`id`, `tenant_id`, `organization_id`, `name`, `slug`, `is_active`).
5. **`memberships`:** Vínculo canónico de acceso (`id`, `tenant_id`, `establishment_id`, `user_id`, `role`, `relation_type`, `status`).

---

## 11. RELATIONSHIPS

El contexto activo es una proyección determinista derivada exclusivamente de la jerarquía relacional física de SaaS Foundation:

```text
MEMBERSHIP (id, user_id, establishment_id, tenant_id, role, relation_type, status)
    │
    ├── [FK: user_id, tenant_id] ────────► USUARIOS (id, tenant_id)
    │
    └── [FK: establishment_id, tenant_id] ─► ESTABLISHMENTS (id, organization_id, tenant_id)
                                                    │
                                                    └── [FK: organization_id, tenant_id] ─► ORGANIZATIONS (id, tenant_id)
```

### Reglas Relacionales Estrictas:
1. **Derivación de Organización:** `memberships` **NO** contiene columna `organization_id` ni clave foránea directa hacia `organizations`. La organización se deriva server-side mediante el salto físico: `memberships.establishment_id -> establishments.id -> establishments.organization_id -> organizations.id`.
2. **Aislamiento Compuesto por Tenant:** Las claves foráneas compuestas de PostgreSQL (`establishment_id, tenant_id`, `organization_id, tenant_id`, `user_id, tenant_id`) garantizan a nivel de base de datos que todos los componentes de la cadena pertenecen inequívocamente al mismo `tenant_id`.

---

## 12. BUSINESS_RULES

1. **Selección Explícita Obligatoria:** Toda activación de contexto debe provenir de una selección explícita del `membership_id` por parte del cliente o una confirmación explícita.
2. **Prohibición de Fallback y Selección Implícita:** Prohibido seleccionar el primer contexto por orden de creación, por mayor jerarquía (`OWNER`), por campos legacy (`id_dueno`, `usuarios.rol`) o de forma aleatoria.
3. **Membresía Exclusivamente ACTIVE:** Únicamente membresías con `memberships.status = 'ACTIVE'` son elegibles para convertirse en Active Context. Membresías `INVITED`, `SUSPENDED` o `REVOKED` disparan rechazo determinista.
4. **Semántica de `establishments.is_active`:** `is_active` es metadato operativo. Un establecimiento con `is_active = false` pero con membresía `ACTIVE` **puede** activarse, viajando `establishment_is_active: false` en el payload para permitir labores administrativas de reactivación/auditoría.
5. **Multiplicidad de Entrada:**
   * **`NO_CONTEXT`:** Si `available_contexts_count == 0`, la activación es rechazada de inmediato con `NO_CONTEXT_AVAILABLE`.
   * **`ONE_CONTEXT`:** Si `available_contexts_count == 1`, el cliente despacha dicho `membership_id` para activación formal.
   * **`MULTIPLE_CONTEXTS`:** Si `available_contexts_count >= 2`, el cliente debe presentar la UI de selección al usuario para que elija explícitamente qué salón activar.

---

## 13. SECURITY_RULES

1. **Zero Client Tenant Authority:** El cliente no tiene autoridad para especificar `tenant_id`. El `tenant_id` se resuelve server-side vía `fn_resolve_user_tenant(req.user.id)` y se valida contra la membresía.
2. **Zero Client Role Authority:** El cliente no puede inyectar ni elevar su `role` ni `relation_type`.
3. **Aislamiento de Identidad (Anti-Impersonation):** La consulta de validación exige rígidamente `memberships.user_id = req.user.id`. El intento de activar una membresía perteneciente a otro usuario es un fallo de seguridad crítico (`SECURITY_VIOLATION`).
4. **Aislamiento Multitenant (Anti Cross-Tenant):** La membresía debe pertenecer al `tenant_id` resuelto de la identidad.
5. **No Bypass de RLS:** La validación se ejecuta respetando las políticas de RLS de PostgreSQL y el rol de runtime `beauty_app_user`.

---

## 14. DATA_RULES

```text
NEW TABLES        = 0
NEW COLUMNS       = 0
NEW ENTITIES      = 0
NEW DB FUNCTIONS  = 0 (Reutiliza fn_resolve_user_tenant de migración 066)
MODIFIED TABLES   = 0
```

---

## 15. INTEGRATION_BOUNDARIES

```text
┌────────────────────────────────────────────────────────┐
│                 CONTEXT RESOLUTION v1.0                │
│  Entrega: Array<AvailableContext>                      │
└──────────────────────────┬─────────────────────────────┘
                           │ (membership_id seleccionado)
                           ▼
┌────────────────────────────────────────────────────────┐
│                  ACTIVE CONTEXT v1.0                   │
│  Valida pertenencia, deriva metadatos, propaga estado  │
└──────────────────────────┬─────────────────────────────┘
                           │ (Active Context validado)
                           ▼
┌────────────────────────────────────────────────────────┐
│                       HUB SALÓN                        │
│  Recibe contexto validado, opera vistas de salón       │
└────────────────────────────────────────────────────────┘
```

---

## 16. ALLOWED_CHANGES

Durante la futura fase de implementación (cuando sea aprobada por el Director), los únicos cambios permitidos serán:
* Creación de `backend/src/services/activeContextService.js` (Lógica de validación de `membership_id` y derivación de establecimiento y organización).
* Creación de `backend/src/controllers/activeContextController.js` (Controlador de activación).
* Creación de `backend/src/routes/activeContextRoutes.js` (Endpoint de activación/verificación).
* Creación de middleware de validación contextual de transporte (`activeContextMiddleware.js`).
* Creación de suite de tests unitarios y de integración para Active Context.

---

## 17. PROTECTED_ASSETS

Los siguientes activos permanecen estrictamente inmutables y protegidos contra cualquier cambio:
1. `backend/migrations/065_saas_foundation_core.sql`
2. `backend/migrations/066_context_resolution_tenant_resolver.sql`
3. `backend/src/services/contextResolutionService.js`
4. `backend/src/controllers/contextController.js`
5. `backend/src/routes/contextRoutes.js`
6. `ncp/` (Todos los contratos NCP existentes)
7. Todos los módulos y rutas pertenecientes a `PRE-NODE-01` (Core B2C).

---

## 18. FORBIDDEN_CHANGES

* Prohibido crear tablas o columnas relacionadas con contexto.
* Prohibido crear columna `organization_id` en `memberships`.
* Prohibido crear nuevas funciones SQL o alterar la migración 066.
* Prohibido modificar los esquemas o funciones de Context Resolution.
* Prohibido implementar lógica de permisos o RBAC fuera de la derivación de `role`.
* Prohibido alterar el runtime user `beauty_app_user` o desactivar RLS.
* Prohibido modificar el frontend o diseñar pantallas de Hub Salón.

---

## 19. VALIDATION_PLAN

El plan de validación para la fase de implementación incluirá las siguientes pruebas de verificación física:

| ID | Escenario de Prueba | Entrada | Resultado Esperado |
| :--- | :--- | :--- | :--- |
| **VAL-AC-01** | Selección válida con 1 membresía (`ONE_CONTEXT`) | `membership_id` legítimo | `200 OK` + DTO de contexto activo derivado (`membership -> establishment -> organization`) |
| **VAL-AC-02** | Selección válida con N membresías (`MULTIPLE_CONTEXTS`) | `membership_id` legítimo | `200 OK` + DTO de contexto activo derivado |
| **VAL-AC-03** | Identidad sin membresías (`NO_CONTEXT`) | Intento de activación | `403 Forbidden` / `NO_CONTEXT_AVAILABLE` |
| **VAL-AC-04** | Membresía de otro usuario (Impersonation attempt) | `membership_id` ajeno | `403 Forbidden` / `MEMBERSHIP_ACCESS_DENIED` |
| **VAL-AC-05** | Membresía en estado no activo (`INVITED`/`SUSPENDED`) | `membership_id` inactivo | `403 Forbidden` / `MEMBERSHIP_NOT_ACTIVE` |
| **VAL-AC-06** | Inyección de `tenant_id` por el cliente | Payload con `tenant_id` manipulado | `tenant_id` del cliente ignorado; prevalece el del servidor |
| **VAL-AC-07** | Intento de selección implícita / vacía | Payload `{}` | `400 Bad Request` / `MEMBERSHIP_SELECTION_REQUIRED` |
| **VAL-AC-08** | Inexistencia de `membership_id` | UUID inexistente | `404 Not Found` / `MEMBERSHIP_NOT_FOUND` |
| **VAL-AC-09** | Establecimiento inactivo con membresía activa | `membership_id` en local cerrado | `200 OK` + `establishment_is_active: false` |
| **VAL-AC-10** | Aislamiento RLS en operaciones de contexto | Query de verificación | Ejecución estricta bajo `app.tenant_id` |

---

## 20. CLOSURE_CRITERIA

El nodo `ACTIVE-CONTEXT-v1.0` se considerará cerrado únicamente cuando:
1. El presente Node Contract cuente con la aprobación formal del Director.
2. Los componentes autorizados en `ALLOWED_CHANGES` estén implementados físicamente.
3. El 100% de las pruebas del `VALIDATION_PLAN` (VAL-AC-01 a VAL-AC-10) pasen exitosamente.
4. Ningún activo protegido haya sido alterado.
5. La auditoría independiente emita dictamen de `READY_FOR_CLOSURE`.
6. El Director emita la declaración formal de `CLOSED`.

---

## 21. OPEN_DECISIONS

Todas las decisiones técnicas han sido formalmente resueltas y aprobadas por el Director del Proyecto:

### ARCH-AC-001: Mecanismo de Transporte de Sesión Contextual (APROBADO)
* **Decisión:** **Opción A — Header de Contexto Validado Estructuralmente (`x-active-membership-id`).**
* **Autoridad:** Director del Proyecto GlowApp SaaS.
* **Detalle:** El cliente envía en cada petición el header `x-active-membership-id: <UUID>`. Un middleware server-side valida estructuralmente la membresía contra el `req.user.id` autenticado. No se crea nueva criptografía ni JWT contextual, garantizando statelessness, revalidación de estado en tiempo real y compatibilidad total con el aislamiento multitenant de PostgreSQL RLS.

### ARCH-AC-002: Flujo de Interfaz para `ONE_CONTEXT` (APROBADO)
* **Decisión:** **Opción A — Auto-despacho explícito del `membership_id` por parte del cliente.**
* **Autoridad:** Director del Proyecto GlowApp SaaS.
* **Detalle:** Cuando Context Resolution retorna `ONE_CONTEXT`, el cliente despacha automáticamente la solicitud de activación del `membership_id` único a nivel de protocolo de red hacia el backend, manteniendo el principio de no asunción en el servidor y agilizando la experiencia de usuario.

---

```text
================================================================================
           ACTIVE CONTEXT v1.0 — NODE CONTRACT FORMAL SPECIFICATION
================================================================================
ESTADO: APPROVED BY DIRECTOR → READY FOR IMPLEMENTATION 🟢
================================================================================
```
