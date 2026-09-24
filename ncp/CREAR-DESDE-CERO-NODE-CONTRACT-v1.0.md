# CREAR DESDE CERO v1.0 — NODE CONTRACT
## Node Construction Protocol — Architectural Node Specification

**Versión:** 1.0.0  
**Estado:** DEFINED / PENDING DIRECTOR APPROVAL 🟡  
**Fase Metodológica:** DEFINIR → RELACIONAR → VALIDAR  
**Ámbito:** Flujo de Aprovisionamiento Inicial, Captura de Catálogo en Tránsito y Handover de Context Package  
**Autoridad Raíz:** Director del Proyecto GlowApp SaaS  

---

## 1. NODE_ID

```text
CREAR-DESDE-CERO-v1.0
```

---

## 2. NAME

```text
Crear Desde Cero SaaS Initial Provisioning & Handover Protocol v1.0
```

---

## 3. PURPOSE

Formalizar el contrato arquitectónico para el flujo orquestador de aprovisionamiento y configuración inicial de sede física en GlowApp SaaS.

`CREAR DESDE CERO v1.0` se inicia exclusivamente desde el cockpit operativo de `HUB SALÓN v1.0`, consumiendo el `Active Context` autenticado server-side (`req.tenantId`, `req.establishmentId`, `req.user.id`, `role IN ('OWNER', 'MANAGER')`). Su responsabilidad es estructurar la intención operativa inicial del salón (actividades comerciales y catálogo de servicios base en tránsito) y referenciar el equipo activo preexistente, compilando deterministamente un **`Context Package` transitorio (en memoria)** destinado exclusivamente a **`PRE-NODO 01`** (Core B2C / Motor de Servicios).

> **Axioma Fundamental:**  
> **Crear Desde Cero prepara y empaqueta el contexto inicial para Pre-Nodo 01; no ejecuta la operación, agenda, cobro ni reservas del salón.**

---

## 4. SCOPE

### En Alcance:
1. **Punto de Entrada e Ingestión Contextual:** Consumir el `Active Context` validado en `HUB SALÓN v1.0` bajo el header canónico `x-active-membership-id: <UUID>`.
2. **Validación de Autoridad:** Restricción estricta del flujo a miembros con rol contextual `OWNER` o `MANAGER`.
3. **Selección de Actividades Comerciales:** Captura estructurada de líneas y especialidades del salón (p. ej. Peluquería, Uñas, Barbería, Estética Facial, Spa).
4. **Captura de Intención de Servicios en Tránsito (DEC-CDC-001 Opción B):** Captura en memoria de la lista base de servicios (nombre, duración en minutos, precio base, categoría) sin generar persistencia en base de datos.
5. **Referenciación de Staff Activo Preexistente (DEC-CDC-002 Opción A / H-CDC-004):** Mapeo de miembros del staff que ya posean membresía con `status = 'ACTIVE'` en el `establishment_id` activo.
6. **Compilación del Context Package Canónico (UAQ-01):** Ensamblaje en memoria del DTO transitorio estructurado bajo los 16 atributos del handover contract.
7. **Evaluación de Bloqueos y Derivación de Estado (H-CDC-002):** Derivación determinista del estado del flujo (`INITIAL`, `IN_PROGRESS`, `BLOCKED`, `READY_FOR_PRE_NODE_01`).
8. **Handover Contract hacia Pre-Nodo 01 (H-CDC-001):** Entrega formal y determinista del `Context Package` a la frontera de ingestión de `PRE-NODO 01`.

---

## 5. NON_SCOPE

### Fuera de Alcance Absoluto:
1. **Cero Persistencia de Servicios de Sede (DEC-CDC-001):** Prohibido crear tablas relacionales `establishment_services`, `salon_services` o similares. Prohibido alterar o forzar la tabla `public.services` (acoplada a `perfiles_prestador` de Pre-Nodo 01).
2. **Cero Creación de Usuarios, Memberships o Invitaciones (DEC-CDC-002 / H-CDC-004):** Prohibido implementar motores de invitaciones, envío de correos, generación de tokens temporales o creación/modificación de cuentas de usuario, membresías o roles.
3. **Cero Modificación o Creación de Roles / RBAC:** Prohibido crear nuevos roles, matrices RBAC o permisos custom.
4. **Cero Módulos Transaccionales u Operativos:** Prohibido implementar:
   * Agenda / Turnos / Calendario / Cálculo de slots en tiempo real.
   * Carrito de compras / Checkout / Reservas B2C.
   * Punto de Venta (POS) / Caja / Facturación / Cobros / Pasarelas de Pago.
   * Comisiones de prestadores / Liquidaciones / Billeteras.
   * Sistema de Reseñas / Calificaciones / Feedback.
5. **Cero Políticas Comerciales o de Reserva Complejas:** Prohibido implementar o exigir seña previa, auto-confirmación, penalizaciones por cancelación o anticipación obligatoria en este nodo.
6. **Cero Modificación a `establishments.is_active` (UAQ-03):** `establishments.is_active` es metadata operacional y queda 100% fuera de alcance. Crear Desde Cero NO activa, NO desactiva y NO condiciona el acceso a la sede física.
7. **Cero Modificación a Nodos Cerrados ni a Pre-Nodo 01:** Cero cambios a `SAAS-FOUNDATION-v1.0` (065/066), `CONTEXT-RESOLUTION-v1.0`, `ACTIVE-CONTEXT-v1.0`, `HUB-SALON-v1.0` y `PRE-NODE-01`.
8. **Cero Nuevas Entidades o Tablas:** `NEW TABLES = 0`, `NEW COLUMNS = 0`, `NEW ENTITIES = 0`, `NEW MIGRATIONS = 0`.

---

## 6. INPUT CONTRACT (H-CDC-008)

Crear Desde Cero separa de forma estricta las entradas provistas por el cliente de la autoridad derivada por el servidor:

### A. CLIENT INPUT (Entrada provista por el Cliente)
* **Token de Identidad:** `Authorization: Bearer <JWT>`
* **Header de Transporte Contextual (ARCH-AC-001):** `x-active-membership-id: <UUID>`
* **Datos Estructurados de Captura (Payload de Configuración en Tránsito):**
  * Actividades comerciales seleccionadas.
  * Catálogo de servicios inicial (nombre, categoría, duración en minutos, precio, descripción).
  * Referencias a membresías activas asignadas a especialidades.
  * Opciones o decisiones operativas del asistente.

### B. SERVER-DERIVED AUTHORITY (Autoridad derivada por el Servidor)
* **`user identity` (`req.user.id`):** Identificador primario de la identidad validado por `authMiddleware`.
* **`tenant` (`req.tenantId`):** Tenant ID resuelto server-side vía `fn_resolve_user_tenant`.
* **`organization` (`req.activeContext.organization_id`, `legal_name`):** Organización legal validada por `activeContextMiddleware`.
* **`establishment` (`req.establishmentId`, `req.activeContext.establishment_name`):** Sede validada por el contexto activo.
* **`membership` (`req.membershipId`):** Membresía activa del usuario validada en base de datos.
* **`role` (`req.activeContext.role`):** Rol server-side derivado de la membresía (`OWNER`, `MANAGER`).
* **`relation_type` (`req.activeContext.relation_type`):** Vinculación contractual (`OWNER_PARTNER`, `STAFF_EMPLOYEE`).
* **`membership status` (`req.activeContext.membership_status`):** Estado server-side (`ACTIVE`).
* **`establishment metadata`:** Metadatos de la sede física (`slug`, `address`, `city`, `phone`, `operating_hours`, `is_active`).

### Regla de Cero Autoridad del Cliente:
```text
CLIENT AUTHORITY   = ZERO on tenant_id, organization_id, establishment_id, role, relation_type, status, is_active
SERVER AUTHORITY   = 100% authoritative derivation of security, tenancy, identity, and membership
```

---

## 7. AUTHORIZATION BOUNDARY

1. **Custodia por Middleware:** Toda ruta de Crear Desde Cero debe estar custodiada obligatoriamente por `authMiddleware` seguido de `activeContextMiddleware`.
2. **Autorización por Rol Contextual:** Solo identidades con membresía activa cuyo `role` sea `OWNER` o `MANAGER` pueden ejecutar el flujo. Peticiones con roles `PROFESSIONAL` o `RECEPTIONIST` son rechazadas con `403 Forbidden` (`INSUFFICIENT_PROVISIONING_ROLE`).
3. **Aislamiento Multitenant (RLS):** Consultas auxiliares ejecutan bajo `SET LOCAL app.tenant_id = '<tenant_id>'` y usuario no privilegiado `beauty_app_user`.
4. **Prohibición de Columnas Legacy:** Queda expresamente prohibido usar `usuarios.rol` o `id_dueno` para determinar autorización.

---

## 8. CONTEXT PACKAGE CONTRACT (DTO DE HANDOVER)

El **Context Package** es un **DTO transitorio en memoria** (Handover Contract) estructurado bajo los 16 atributos canónicos:

```json
{
  "context_package": {
    "organization": {
      "id": "876ba9e8-f8e0-42b4-a805-a5ef94619664",
      "legal_name": "Luxe Beauty Group S.A.S."
    },
    "establishments": {
      "id": "841b5d26-c479-432d-b0c9-6653343aa3f1",
      "name": "Salón Elegance Studio Chicó",
      "slug": "elegance-studio-chico",
      "city": "Bogotá",
      "address": "Carrera 11 # 93-45",
      "phone": "+573101234567",
      "operating_hours": {
        "monday_friday": "08:00-20:00",
        "saturday": "09:00-19:00",
        "sunday": "closed"
      }
    },
    "activities": [
      "HAIR_STYLING",
      "NAIL_CARE"
    ],
    "relevant_services": [
      {
        "name": "Corte de Cabello Estilo & Cepillado",
        "category": "HAIR_STYLING",
        "duration_minutes": 45,
        "price": 45000.00,
        "description": "Corte personalizado con lavado y finalización"
      },
      {
        "name": "Manicura Semi-Permanente",
        "category": "NAIL_CARE",
        "duration_minutes": 60,
        "price": 55000.00,
        "description": "Limpieza profunda y esmaltado de larga duración"
      }
    ],
    "people_initial_roles": [
      {
        "membership_id": "3f183a7e-ae88-4588-b7a9-8925463997e0",
        "user_id": 7,
        "user_name": "Diana Ospina",
        "user_email": "diana@salon.com",
        "role": "OWNER",
        "relation_type": "OWNER_PARTNER",
        "status": "ACTIVE",
        "assigned_categories": ["HAIR_STYLING"]
      }
    ],
    "identity": {
      "id": 7,
      "role": "OWNER"
    },
    "state": "READY_FOR_PRE_NODE_01",
    "known_evidence": {
      "active_context_verified": true,
      "tenant_isolation_verified": true,
      "authorized_membership_verified": true
    },
    "decisions": {
      "catalog_mode": "STANDARD_SETUP",
      "provisioning_source": "CREAR_DESDE_CERO_v1.0"
    },
    "applicable_rules": [
      "ARCH-AC-001-HEADER-TRANSPORT",
      "ARCH-RLS-TENANT-ISOLATION",
      "ARCH-OWNER-MANAGER-AUTHORITY"
    ],
    "conditions": {
      "active_membership_satisfied": true,
      "establishment_context_satisfied": true
    },
    "procedures": {
      "handover_target": "PRE_NODE_01",
      "handover_type": "IN_MEMORY_TRANSIENT"
    },
    "dependencies": [
      "ACTIVE_ESTABLISHMENT_CONTEXT",
      "ACTIVE_AUTHORIZED_MEMBERSHIP"
    ],
    "blocks": [],
    "route": "HUB_SALON -> CREAR_DESDE_CERO -> PRE_NODO_01",
    "entry_state": {
      "context_source": "HUB_SALON_ACTIVE_CONTEXT",
      "provisioning_mode": "INITIAL_BOOTSTRAP"
    }
  }
}
```

> **IMPORTANTE:** Los 16 atributos son campos conceptuales del DTO de handover. **NO son 16 tablas ni entidades físicas de base de datos.**

---

## 9. CLASIFICACIÓN DE LOS 16 ATRIBUTOS CANÓNICOS

| # | Atributo Canónico | Naturaleza | Fuente Física / Origen / Reconciliación |
| :-: | :--- | :--- | :--- |
| **1** | **Organization** | *Disponible* | Active Context (`organization_id`, `organization_legal_name`) |
| **2** | **Establishments** | *Disponible* | Active Context + `establishments` (`id`, `name`, `slug`, `city`, `address`, `phone`, `operating_hours`) |
| **3** | **Activities** | *Producido* | Carga útil estructurada capturada durante el flujo |
| **4** | **Relevant Services** | *Producido (Transitorio)* | Catálogo capturado en memoria sin persistencia en BD (DEC-CDC-001) |
| **5** | **People / Initial Roles** | *Referenciado (H-CDC-004)* | Solo referencia memberships `ACTIVE` existentes asociadas a categorías (DEC-CDC-002) |
| **6** | **Identity** | *Disponible* | `req.user.id` + rol activo validado server-side |
| **7** | **State** | *Derivado (H-CDC-002)* | Estado real derivado: `INITIAL`, `IN_PROGRESS`, `BLOCKED`, `READY_FOR_PRE_NODE_01` |
| **8** | **Known Evidence** | *Recopilado (H-CDC-007)* | Evidencia conocida y disponible para el flujo según información validada |
| **9** | **Decisions** | *Producido* | Decisiones de configuración seleccionadas por el operador en el flujo |
| **10**| **Applicable Rules** | *Disponible* | Reglas de SOUL, Governance y aislamiento RLS |
| **11**| **Conditions** | *Evaluado (H-CDC-005)* | Condiciones reales determinadas por el flujo según evidencia disponible |
| **12**| **Procedures** | *Perteneciente a Pre-Nodo 01* | Protocolo de ingestión downstream (no implementado en este nodo) |
| **13**| **Dependencies** | *Evaluado (H-CDC-006 / H-CDC-009)* | Dependencias reales relevantes para el handover (`ACTIVE_ESTABLISHMENT_CONTEXT`, `ACTIVE_AUTHORIZED_MEMBERSHIP`) |
| **14**| **Blocks** | *Derivado* | Lista de impedimentos o inconsistencias detectadas |
| **15**| **Route** | *Ruta Lógica (H-CDC-001)* | `HUB_SALON -> CREAR_DESDE_CERO -> PRE_NODO_01` (Ruta lógica de handover) |
| **16**| **Entry State** | *Conceptual (H-CDC-003)* | Estado conceptual de entrada/handover (sin checksums ni execution IDs) |

> **Definición Canónica de `ACTIVE_AUTHORIZED_MEMBERSHIP` (H-CDC-009):**  
> Membership existente, perteneciente al usuario autenticado, con `status = 'ACTIVE'` y cuyo rol contextual esté autorizado para Crear Desde Cero (`OWNER` o `MANAGER`).


---

## 10. PROTOCOLO DE HANDOVER

```text
HUB SALÓN v1.0
     │ (Operador con Active Context OWNER/MANAGER inicia flujo)
     ▼
CREAR DESDE CERO v1.0
     │ (Captura actividades, catálogo en tránsito y referencia staff ACTIVE)
     ▼
COMPILACIÓN DEL CONTEXT PACKAGE
     │ (Ensambla DTO transitorio con 16 atributos en memoria)
     ▼
HANDOVER CONTRACT
     │ (Ruta lógica: HUB_SALON -> CREAR_DESDE_CERO -> PRE_NODO_01)
     ▼
PRE-NODO 01 (Core B2C Engine)
```

El handover es:
* **Explícito:** Invocado controladamente por el operador.
* **Determinista:** La misma entrada y estado contextual generan el mismo Context Package.
* **Transitorio:** No requiere almacenamiento en tablas intermedias de borrador ni altera esquemas físicos.
* **Auditable:** Estructurado bajo el contrato formal de 16 atributos.

---

## 11. ESTADOS DEL FLUJO (H-CDC-002)

Los estados del ciclo de vida del flujo son derivados deterministamente:

1. **`INITIAL`:** Flujo iniciado con Active Context válido, listo para captura de datos.
2. **`IN_PROGRESS`:** Captura interactiva de actividades y catálogo en curso.
3. **`BLOCKED`:** Bloqueo detectado (ausencia de header, rol no autorizado, inconsistencia en payload).
4. **`READY_FOR_PRE_NODE_01`:** Emitido **únicamente** cuando las condiciones contractuales están satisfechas y no existen bloqueos impeditivos.

> **Regla de Derivación:** `READY_FOR_PRE_NODE_01` NO es un valor forzado ni obligatorio; se deriva exclusivamente cuando la validación del paquete es completa y exitosa.

---

## 12. GESTIÓN DE BLOQUEOS (BLOCKS)

Un `Block` representa una condición real que impide emitir un Context Package apto para Pre-Nodo 01.

### Bloqueos Válidos:
* `IDENTITY_NOT_FOUND`: Petición no autenticada.
* `MISSING_ACTIVE_MEMBERSHIP_HEADER`: Ausencia de header `x-active-membership-id`.
* `MEMBERSHIP_ACCESS_DENIED`: Membresía no perteneciente a la identidad o no activa.
* `INSUFFICIENT_PROVISIONING_ROLE`: Rol distinto de `OWNER` o `MANAGER`.
* `MALFORMED_SERVICES_PAYLOAD`: Formato de servicios con duraciones no numéricas o precios negativos.
* `INVALID_STAFF_REFERENCE`: Intento de referenciar una membresía no vinculada a la sede o con estado distinto de `ACTIVE`.

> **Prohibición de Bloqueos Artificiales:**  
> Prohibido bloquear por no tener políticas de reserva configuradas, por no activar comercialmente la sede (`is_active`), o por no definir integración de pagos o agenda.

---

## 13. IDEMPOTENCIA (UAQ-02)

Crear Desde Cero es **funcionalmente idempotente**:
* Cada ejecución válida con idénticas entradas y estado contextual produce un `Context Package` determinista y coherente.
* **No requiere ni utiliza:** `idempotency_key`, `execution_id`, tabla de sesiones, ni historial persistente en base de datos.

---

## 14. DATA MODEL IMPACT

```text
================================================================================
                       DATA MODEL INTEGRITY DECLARATION
================================================================================
NEW TABLES                  = 0
NEW COLUMNS                 = 0
NEW ENTITIES                = 0
NEW MIGRATIONS              = 0
MODIFIED EXISTING TABLES    = 0
================================================================================
```

Tablas consumidas exclusivamente en modo de consulta / lectura:
* `tenants` (Aislamiento multitenant RLS)
* `organizations` (Lectura de razón social)
* `establishments` (Lectura de metadatos de la sede física)
* `memberships` (Referenciación de staff con `status = 'ACTIVE'`)
* `usuarios` (Lectura de nombre y correo de colaboradores activos)

---

## 15. INTEGRATION BOUNDARIES

```text
┌────────────────────────────────────────────────────────┐
│               SAAS FOUNDATION v1.0                     │ [CLOSED]
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│              CONTEXT RESOLUTION v1.0                   │ [CLOSED]
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│               ACTIVE CONTEXT v1.0                      │ [CLOSED]
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│                 HUB SALÓN v1.0                         │ [CLOSED]
└──────────────────────────┬─────────────────────────────┘
                           │ (Punto de Entrada: Active Context OWNER/MANAGER)
                           ▼
┌────────────────────────────────────────────────────────┐
│               CREAR DESDE CERO v1.0                    │ [ESTE CONTRATO]
│  Compila en memoria: Context Package (16 atributos)    │
└──────────────────────────┬─────────────────────────────┘
                           │ (Handover DTO en tránsito: Ruta lógica)
                           ▼
┌────────────────────────────────────────────────────────┐
│                    PRE-NODO 01                         │ [IMMUTABLE]
│  Core B2C: Consume Context Package en su frontera      │
└────────────────────────────────────────────────────────┘
```

---

## 16. SOUL + GOVERNANCE

* **Obligatoriedad:** Toda interacción visual en el cliente debe adherirse estrictamente al sistema de diseño SOUL y a las normas de Governance del proyecto.
* **Cero Duplicación:** No crear frameworks visuales ad-hoc, no duplicar tokens, ni crear una capa de gobernanza local.

---

## 17. ALLOWED CHANGES (PRE-IMPLEMENTATION REFERENCE)

> **Aviso:** La definición y aprobación de este contrato **NO autoriza la implementación de código**.

Durante la futura fase de implementación (cuando sea expresamente autorizada por el Director), los cambios quedarán estrictamente acotados a:
* Creación de `backend/src/services/crearDesdeCeroService.js` (Lógica de compilación y validación del Context Package).
* Creación de `backend/src/controllers/crearDesdeCeroController.js` (Controlador HTTP del flujo).
* Creación de `backend/src/routes/crearDesdeCeroRoutes.js` (Enrutador `/api/v1/saas/hub/onboarding` o similar).
* Montaje seguro y no invasivo en `backend/index.js`.
* Creación de suites de pruebas automatizadas dedicadas.

---

## 18. PROTECTED ASSETS

Permanecen estrictamente inmutables y protegidos:
1. `backend/migrations/065_saas_foundation_core.sql`
2. `backend/migrations/066_context_resolution_tenant_resolver.sql`
3. `fn_resolve_user_tenant` (PostgreSQL)
4. `Context Resolution v1.0` (`contextResolutionService`, `contextController`, `contextRoutes`)
5. `Active Context v1.0` (`activeContextService`, `activeContextController`, `activeContextMiddleware`, `activeContextRoutes`)
6. `Hub Salón v1.0` (`hubSalonService`, `hubSalonController`, `hubSalonRoutes`)
7. `Pre-Nodo 01` (Core B2C intacto)
8. `SOUL` / `Governance` / `NCP Core`
9. Contratos NCP cerrados

---

## 19. FORBIDDEN ACTIONS

* Prohibido crear tablas, columnas, vistas o migraciones.
* Prohibido modificar o reutilizar `public.services` vinculándola a establecimientos.
* Prohibido crear usuarios, memberships, roles o motores de invitaciones.
* Prohibido modificar o alterar `establishments.is_active`.
* Prohibido implementar lógica de Agenda, Turnos, Citas, POS, Caja, Facturación, Pagos, Comisiones o Reseñas.
* Prohibido eludir `activeContextMiddleware`.
* Prohibido confiar en identificadores de tenant, establecimiento, rol o estatus provistos por el cliente.

---

## 20. VALIDATION PLAN

| ID | Escenario de Prueba | Entrada | Resultado Esperado |
| :--- | :--- | :--- | :--- |
| **VAL-CDC-01** | Identity autenticada + Active Context válido (`OWNER`/`MANAGER`) | Header legítimo + Payload válido | `200 OK` + Context Package estructurado |
| **VAL-CDC-02** | Petición sin header `x-active-membership-id` | Request sin header | `400 Bad Request` (`MISSING_ACTIVE_MEMBERSHIP_HEADER`) |
| **VAL-CDC-03** | Membership UUID inexistente o no resoluble | Header con UUID falso | `404 Not Found` (`MEMBERSHIP_NOT_FOUND`) |
| **VAL-CDC-04** | Membership perteneciente a otro usuario | Header con membership ajena | `403 Forbidden` (`MEMBERSHIP_ACCESS_DENIED`) |
| **VAL-CDC-05** | Membership con estado no `ACTIVE` (ej. `INVITED`, `SUSPENDED`) | Header con status no active | `403 Forbidden` (`MEMBERSHIP_NOT_ACTIVE`) |
| **VAL-CDC-06** | Rol no autorizado (`PROFESSIONAL` o `RECEPTIONIST`) | Header de miembro colaborador | `403 Forbidden` (`INSUFFICIENT_PROVISIONING_ROLE`) |
| **VAL-CDC-07** | Validación de los 16 atributos del Context Package | Payload completo | Context Package contiene exactamente los 16 atributos canónicos |
| **VAL-CDC-08** | Servicios en tránsito sin persistencia física | Compilación exitosa | `SELECT COUNT(*) FROM services` permanece inalterado |
| **VAL-CDC-09** | Cero mutación en usuarios, memberships o invitaciones | Ejecución del flujo | Cero nuevos registros en `usuarios` o `memberships` |
| **VAL-CDC-10** | Inmutabilidad de `establishments.is_active` | Compilación en sede `is_active = false` | `establishments.is_active` permanece `false` |
| **VAL-CDC-11** | Aislamiento RLS en consultas auxiliares | Ejecución multitenant | `app.tenant_id` aplicado estrictamente |
| **VAL-CDC-12** | Derivación determinista de estado | Payload completo validado vs payload incompleto | `state = 'READY_FOR_PRE_NODE_01'` solo ante éxito; `state = 'BLOCKED'` ante inconsistencias |

---

## 21. ECONOMÍA ARQUITECTÓNICA

* **Alcance:** Exclusivamente bootstrap inicial, captura en tránsito y ensamblaje de handover.
* **Arquitectura:** Consume Active Context cerrado y produce Context Package transitorio hacia Pre-Nodo 01.
* **Necesidad:** Desacoplar el aprovisionamiento SaaS de la ejecución transaccional del core B2C.
* **Economía:** Cero cambios de esquema, cero nuevas migraciones, cero tablas intermedias de borrador y cero deuda estructural.

---

## 22. CLOSURE CRITERIA

El nodo `CREAR-DESDE-CERO-v1.0` se considerará cerrado únicamente cuando:
1. El presente Node Contract sea aprobado formalmente por el Director del Proyecto.
2. La fase de implementación sea expresamente autorizada por el Director y ejecutada quirúrgicamente.
3. El 100% de las pruebas del `VALIDATION_PLAN` (VAL-CDC-01 a VAL-CDC-12) pasen exitosamente.
4. Ningún activo protegido haya sido alterado.
5. La auditoría independiente final emita veredicto de `PASS — READY FOR DIRECTOR CLOSURE`.
6. El Director emita la declaración formal de `CLOSED`.

---

```text
================================================================================
       CREAR DESDE CERO v1.0 — NODE CONTRACT FORMAL SPECIFICATION
================================================================================
ESTADO: DEFINED — PENDING DIRECTOR APPROVAL 🟡
================================================================================
```
