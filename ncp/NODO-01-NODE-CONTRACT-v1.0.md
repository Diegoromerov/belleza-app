# NODO-01-NODE-CONTRACT-v1.0
## Contrato de Nodo: Handover Ingestion & Downstream Adapter

**NODE_ID:** `NODO-01-v1.0`  
**NAME:** Node 01 — Handover Ingestion & Downstream Adapter  
**TYPE:** Downstream Boundary / Ingestion / Adapter  
**STATUS:** DEFINED / CONTRACT_PENDING  
**AUTORIDAD:** Director del Proyecto GlowApp SaaS  
**DECISIÓN BASE:** N01-DEC-001 (APPROVED / CLOSED)  
**CARÁCTER:** Node Specification Contract (Cero Implementación / Cero Creación de Esquemas Físicos)  

---

## 1. OBJETIVO

Formalizar normativamente la especificación del nodo **`NODO-01-v1.0`**, convirtiendo la definición arquitectónica aprobada (`N01-DEC-001`) en una especificación técnica auditable, cerrada en su alcance de frontera y abierta exclusivamente en las dependencias downstream formalmente declaradas como pendientes (`DEC-SE-001` y `DEC-SE-002`).

Este contrato no implementa código, no genera migraciones ni autoriza la mutación física de esquemas en esta etapa.

---

## 2. IDENTIDAD DEL NODO

```text
================================================================================
NODE_ID:      NODO-01-v1.0
NAME:         Node 01 — Handover Ingestion & Downstream Adapter
TYPE:         Downstream Boundary / Ingestion / Adapter
STATUS:       DEFINED / CONTRACT_PENDING
UPSTREAM:     HANDOVER-BOUNDARY-CONTRACT-v1.0 (CREAR-DESDE-CERO-v1.0)
DOWNSTREAM:   PRE-NODO-01 (Core B2C Engine / Marketplace)
================================================================================
```

---

## 3. PURPOSE (PROPÓSITO)

El propósito exclusivo y delimitado de `NODO-01-v1.0` es:
1. **Recepción:** Recibir un DTO de Handover válido emitido conforme a `HANDOVER-BOUNDARY-CONTRACT-v1.0`.
2. **Verificación:** Comprobar la conformidad de seguridad, integridad y completitud de entrada.
3. **Aislamiento Semántico:** Preservar la separación estricta entre el modelo SaaS (sede multitenant) y el modelo B2C (prestador individual).
4. **Adaptación:** Producir un `DOWNSTREAM ADAPTATION RESULT` conceptualmente estructurado para el dominio operacional B2C.
5. **Neutralidad de Materialización:** Mantener las decisiones de materialización y persistencia física fuera de la definición contractual mientras permanezcan pendientes.

---

## 4. INPUT CONTRACT (CONTRATO DE ENTRADA)

La entrada canónica e inmutable a `NODO-01-v1.0` es el DTO formal de `HANDOVER-BOUNDARY-CONTRACT-v1.0`:

```json
{
  "handover_contract_version": "1.0.0",
  "establishment_context": {
    "id": "e4b2d3c1-7a89-4f5e-b123-456789abcdef",
    "name": "Salón Elegance Poblado",
    "city": "Medellín",
    "address": "Cra 43A # 1-50",
    "location": {
      "type": "Point",
      "coordinates": [-75.567, 6.208]
    },
    "operating_hours": {
      "monday": { "open": "08:00", "close": "19:00", "is_closed": false }
    }
  },
  "professional_context": [
    {
      "user_id": 7,
      "role": "OWNER",
      "status": "ACTIVE",
      "capabilities": ["HAIR_STYLING"]
    }
  ],
  "service_offers": [
    {
      "name": "Corte de Cabello Estilo & Cepillado",
      "category": "HAIR_STYLING",
      "duration_minutes": 45,
      "price": 45000.00,
      "description": "Corte personalizado con lavado y finalización",
      "is_active": true
    }
  ],
  "authorizing_identity": {
    "user_id": 7,
    "role": "OWNER"
  },
  "assignment": {
    "status": "NOT_ESTABLISHED"
  },
  "source_state": "READY_FOR_PRE_NODE_01"
}
```

### Invariantes del Contrato de Entrada:
- `assignment.status` **DEBE** ser `"NOT_ESTABLISHED"`.
- `service_offers` **NO DEBE** contener `provider_id`.
- No se permiten campos adicionales ni reinterpretaciones de tipos.

---

## 5. INPUT VALIDATION (VALIDACIONES DE ENTRADA)

Nodo 01 ejecuta exclusivamente las siguientes validaciones de frontera:

1. **Identity Validation:** La petición y el campo `authorizing_identity` deben corresponder a un usuario autenticado con rol `OWNER` o `MANAGER` en la sede activa.
2. **Context Validation:** `establishment_context` debe contener `id` (UUID), `name`, `city`, `address`, `location` (Point válido) y `operating_hours`.
3. **Professional Context Validation:** `professional_context` debe contener únicamente miembros con `status = 'ACTIVE'` y roles autorizados (`OWNER`, `MANAGER`, `PROFESSIONAL`).
4. **Service Offers Validation:** Cada oferta en `service_offers` debe conservar su semántica de catálogo de sede con nombre no vacío, `duration_minutes > 0` y `price >= 0`. **Queda prohibida su transformación automática en asignación personal en la entrada.**
5. **Assignment Status Validation:** `assignment.status` debe ser estrictamente `"NOT_ESTABLISHED"`.
6. **Source State Validation:** `source_state` es metadata informativa. `READY_FOR_PRE_NODE_01` no constituye una obligación de estado para el nodo downstream.

---

## 6. OUTPUT CONTRACT (CONTRATO DE SALIDA)

La salida de `NODO-01-v1.0` se define conceptualmente como:

```text
================================================================================
                      DOWNSTREAM ADAPTATION RESULT
================================================================================
```

### Especificación Conceptual:
- **Propósito:** Entregar la información del establecimiento, staff y catálogo adaptada semánticamente para el consumo del plano operacional B2C.
- **Contenido Conceptual:**
  - `target_establishment_descriptor`: Metadatos de la sede validados para referencia de ubicación y horario.
  - `eligible_professionals`: Lista de identidades operativas (`user_id`) con sus capacidades temáticas declaradas.
  - `catalog_offer_descriptors`: Lista de servicios ofertados por la sede.
  - `adaptation_status`: `"ADAPTATION_READY"`.
- **Límites Estrictos:**
  - **NO** representa sentencias `INSERT`, `UPDATE` o `UPSERT`.
  - **NO** crea `provider_id` ni filas en `public.services`.
  - **NO** crea filas en `perfiles_prestador`.
  - **NO** define tablas intermedias ni claves foráneas físicas.

---

## 7. RESPONSIBILITIES (RESPONSABILIDADES DE NODO 01)

`NODO-01-v1.0` asume única y exclusivamente las siguientes seis responsabilidades:

- **R01 — Handover Acceptance:** Aceptar únicamente cargas útiles que cumplan estrictamente con `HANDOVER-BOUNDARY-CONTRACT-v1.0`.
- **R02 — Boundary Validation:** Validar criptográfica, estructural y semánticamente la conformidad del DTO en la frontera.
- **R03 — Semantic Isolation:** Garantizar que los conceptos del plano SaaS (tenancy, sede, membresía) no se colapsen ni confundan con conceptos de Pre-Nodo 01 (prestador individual, transacciones).
- **R04 — Downstream Adaptation:** Preparar en memoria la estructura neutral `DOWNSTREAM ADAPTATION RESULT`.
- **R05 — Decision Compliance:** Supeditar cualquier materialización física a las directivas aprobadas del Director (`DEC-SE-001`, `DEC-SE-002`).
- **R06 — Boundary Integrity:** Bloquear cualquier intento downstream de alterar retroactivamente el modelo SaaS o el contrato HBC.

---

## 8. EXPLICIT NON-RESPONSIBILITIES (NO-RESPONSABILIDADES)

Queda expresamente establecido que `NODO-01-v1.0` **NO**:
- Administra Tenants, Cuentas ni Organizaciones (soberanía de SaaS Foundation).
- Administra Identidades (`usuarios.id`) ni Membresías (`memberships`).
- Define Roles de SaaS ni crea capacidades (`capabilities`).
- Crea ofertas de catálogo de sede (soberanía de Crear Desde Cero).
- Define asignaciones de servicio ni inventa `provider_id`.
- Crea o muta perfiles de prestador (`perfiles_prestador`).
- Crea o muta servicios en base de datos (`public.services`).
- Crea o gestiona reservas (`public.bookings`).
- Calcula slots de disponibilidad en tiempo real.
- Procesa pagos, transacciones financieras ni comisiones.
- Ejecuta la activación comercial en el marketplace (`is_active = true` público).
- Modifica el esquema o código de Pre-Nodo 01.
- Modifica el contrato `HANDOVER-BOUNDARY-CONTRACT-v1.0`.

---

## 9. DEC-SE-001 (ESTRATEGIA DE INSTANCIACIÓN DE SERVICIOS)

```text
STATUS: PENDING DIRECTOR DECISION
TÍTULO: Estrategia de Instanciación / Asignación de Servicios en B2C
```

### Declaraciones Normativas:
1. `NODO-01-v1.0` reconoce formalmente la incompatibilidad de cardinalidad entre `service_offers` (catálogo de sede) y `public.services` (`provider_id INTEGER NOT NULL`).
2. `NODO-01-v1.0` **NO** resuelve esta incompatibilidad por cuenta propia.
3. Queda prohibido seleccionar de forma anticipada la *Opción A (Duplicación por Staff)* o la *Opción B (Host Delegado / Owner)*.
4. Queda prohibido crear tablas alternativas de asignación en este contrato.
5. La directiva que el Director promulgue para `DEC-SE-001` gobernará exclusivamente el adaptador de persistencia downstream posterior.

---

## 10. DEC-SE-002 (SINCRONIZACIÓN DE UBICACIÓN Y HORARIOS)

```text
STATUS: PENDING DIRECTOR DECISION
TÍTULO: Estrategia de Sincronización de Ubicación y Horarios hacia B2C
```

### Declaraciones Normativas:
1. `NODO-01-v1.0` recibe e interpreta conceptualmente `location` y `operating_hours` de la sede.
2. Queda prohibido asumir que la ubicación de la sede sea automáticamente la ubicación de `perfiles_prestador`.
3. Queda prohibido asumir que los horarios de la sede sean automáticamente el `weekly_schedule` de `perfiles_prestador`.
4. Queda prohibido definir sentencias `UPDATE`/`UPSERT` o sincronización automática hacia `perfiles_prestador`.
5. La directiva que el Director promulgue para `DEC-SE-002` gobernará exclusivamente el adaptador de persistencia downstream posterior.

---

## 11. AUTHORITY MODEL (MATRIZ DE SOBERANÍA)

| Concepto / Entidad | Autoridad Canónica | Justificación Técnica |
| :--- | :--- | :--- |
| **Tenant** | SaaS Foundation | Clave `tenants.id`, aislada por RLS y `fn_resolve_user_tenant`. |
| **Organization** | SaaS Foundation | Entidad legal/fiscal (`organizations`). |
| **Establishment** | SaaS Core | Sede física multitenant (`establishments`). |
| **Membership** | SaaS Foundation | Vinculación contractual (`memberships`). |
| **Active Context** | Active Context Module | Contexto de sesión y rol activo validado server-side. |
| **Capability** | SaaS Onboarding | Declaración temática en `people_initial_roles`. |
| **Service Offer** | SaaS Onboarding | Oferta comercial de sede en `relevant_services`. |
| **Handover Contract**| HBC v1.0 | Especificación del DTO de tránsito inmutable. |
| **Assignment** | **PENDING DEC-SE-001** | Vinculación de ejecución pendiente de directiva. |
| **Provider Profile** | Pre-Nodo 01 | Perfil marketplace en `perfiles_prestador`. |
| **B2C Service** | Pre-Nodo 01 | Registro físico persistido en `public.services`. |
| **Booking** | Pre-Nodo 01 | Transacción de cita en `public.bookings`. |
| **Execution** | Pre-Nodo 01 | Validación por PIN y confirmación en tiempo real. |

```text
PRINCIPIO CANÓNICO INVIOLABLE:
IDENTITY (usuarios.id) ≠ CAPABILITY (assigned_categories) ≠ ASSIGNMENT (public.services.provider_id)
```

---

## 12. SECURITY & ISOLATION (SEGURIDAD Y AISLAMIENTO)

1. **Server-Side Authority:** Toda validación de identidad, membresía y rol se realiza en el servidor; el cliente tiene cero autoridad.
2. **No Client Authority:** El cliente no puede inyectar `tenant_id`, `provider_id` ni forzar `assignment`.
3. **Aislamiento RLS:** No se permite el bypass de RLS en ninguna consulta previa contra el plano SaaS.
4. **Preservación de Foundation:** No se modifican las tablas ni funciones del núcleo SaaS (`065`, `066`).
5. **No Elevación de Privilegios:** Solo usuarios con rol verificado `OWNER` o `MANAGER` pueden emitir el handover hacia Nodo 01.

---

## 13. TRANSPORT (AGNOSTICISMO DE TRANSPORTE)

Este contrato es estrictamente **`TRANSPORT AGNOSTIC`**:
- No impone protocolo HTTP, invocación interna de función en memoria, cola de mensajes, bus de eventos ni orquestación por cliente.
- El mecanismo de transporte físico será determinado en la fase de diseño de implementación.

---

## 14. PERSISTENCE (ESTRATEGIA DE PERSISTENCIA)

```text
Persistence Strategy = UNRESOLVED
```
- Este contrato **NO crea ni autoriza**:
  - Tablas de puente (`bridge tables`).
  - Tablas `establishment_services` o `establishment_providers`.
  - Tablas de aprovisionamiento o asignación intermedias.
  - Tablas de borradores (`drafts`).
  - Persistencia del Context Package.

---

## 15. IDEMPOTENCY (DETERMINISMO SEMÁNTICO)

- **Determinismo Semántico:** Para una misma entrada y contexto, Nodo 01 produce un `DOWNSTREAM ADAPTATION RESULT` idéntico.
- **Distinción Técnica:** El determinismo semántico no equivale a idempotencia de persistencia técnica (la cual será diseñada con transacciones ACID y directivas downstream).

---

## 16. PRE-NODE 01 INTEGRITY (INMUTABILIDAD DE B2C)

Pre-Nodo 01 permanece en estado **`IMPLEMENTED / IMMUTABLE`**.  
`NODO-01-v1.0` **NO modifica**:
- `usuarios`
- `perfiles_prestador`
- `services`
- `bookings`
- `reviews`
- `portfolio_items`
- Controladores y rutas B2C existentes
- Frontend B2C

---

## 17. NODE BOUNDARIES (DELIMITACIÓN DE LÍMITES)

```text
┌──────────────────────────────────────┐
│ UPSTREAM: Handover Boundary v1.0     │  (Entrega semántica inmutable)
└──────────────────┬───────────────────┘
                   │ DTO conforme a HBC
                   ▼
┌──────────────────────────────────────┐
│ NODO 01: Ingestion & Adapter         │  (Ingestión + Validación + Adaptación)
└──────────────────┬───────────────────┘
                   │ DOWNSTREAM ADAPTATION RESULT
                   ▼
┌──────────────────────────────────────┐
│ DOWNSTREAM: Pre-Nodo 01 / B2C Core   │  (Modelo transaccional inmutable)
└──────────────────────────────────────┘
```

---

## 18. STATE MODEL (MÁQUINA DE ESTADOS CONTRACTUAL)

Estados contractuales formales del ciclo de vida de `NODO-01-v1.0`:

```text
NOT_READY ────────► READY_TO_RECEIVE ────────► RECEIVED ────────► VALIDATED ────────► ADAPTATION_READY
                            │                     │                   │
                            │                     ▼                   ▼
                            └──────────────►  REJECTED             BLOCKED
```

- **`NOT_READY`:** Nodo no inicializado o dependencias no disponibles.
- **`READY_TO_RECEIVE`:** Listo para recibir payloads conformes a `HBC v1.0`.
- **`RECEIVED`:** DTO recibido en frontera de transporte.
- **`VALIDATED`:** DTO verificado contra reglas de `HBC v1.0`.
- **`ADAPTATION_READY`:** `DOWNSTREAM ADAPTATION RESULT` generado en memoria.
- **`BLOCKED`:** Bloqueo detectado por inconsistencia o regla de negocio.
- **`REJECTED`:** DTO rechazado por violación de contrato o falta de autorización.

> `READY_FOR_PRE_NODE_01` **NO** es un estado de Nodo 01; pertenece al contexto de salida de Crear Desde Cero como metadata informativa.

---

## 19. FAILURE & ARCHITECTURAL STOP CONDITIONS

Debe emitirse un **`ARCHITECTURAL STOP`** inmediato ante cualquiera de las siguientes condiciones:
1. Ausencia o malformación del DTO de `HBC v1.0`.
2. Identidad autorizadora no verificable en `memberships`.
3. Intento de imponer asignación de servicios sin directiva `DEC-SE-001` aprobada.
4. Intento de inventar o inyectar `provider_id` no autorizado.
5. Necesidad sobrevenida de modificar el plano SaaS Foundation.
6. Necesidad sobrevenida de mutar el esquema de Pre-Nodo 01.
7. Necesidad de alterar `HANDOVER-BOUNDARY-CONTRACT-v1.0`.
8. Requerimiento de crear entidades físicas intermedias no aprobadas.

### Formato Obligatorio de Reporte de Parada:
```text
PROBLEMA:          [Descripción técnica del impedimento]
EVIDENCIA:         [Ubicación y hecho físico observable]
IMPACTO:           [Consecuencia sobre aislamiento o contratos]
OPCIONES:          [Alternativas analizadas]
RECOMENDACIÓN:     [Propuesta técnica]
DECISIÓN REQUERIDA:[Punto formal sometido al Director]
```

---

## 20. VALIDATION MATRIX (MATRIZ CONTRACTUAL CONCEPTUAL)

| ID | Escenario / Caso de Prueba Conceptual | Input (Entrada) | Expected Result (Resultado Esperado) | Architectural Rule (Regla Aplicable) |
| :--- | :--- | :--- | :--- | :--- |
| **N01-VAL-01** | Handover Canónico Válido | DTO completo conforme a `HBC v1.0` con `OWNER` activo. | Transición a `VALIDATED` y emisión de `ADAPTATION_READY`. | R01, R02 — Conformidad estricta de contrato. |
| **N01-VAL-02** | Verificación de Catálogo sin Provider | `service_offers` sin `provider_id`. | Aceptado como oferta de sede. | R03 — Soberanía de catálogo SaaS. |
| **N01-VAL-03** | Estado de Asignación no Establecido | `assignment.status = "NOT_ESTABLISHED"`. | Aceptado; no infiere asignaciones. | R03 — Prohibición de category matching. |
| **N01-VAL-04** | Identidad Autorizadora Válida | Token y active context con rol `OWNER` o `MANAGER`. | Validación de seguridad exitosa. | R02 — Server-side authorization. |
| **N01-VAL-05** | Service Offer Válido | Servicios con nombre, precio $\ge 0$ y duración $> 0$. | Catálogo estructurado en salida conceptual. | R04 — Downstream Adaptation. |
| **N01-VAL-06** | Intento de Inyección de `provider_id` | DTO manipulado con `provider_id` forzado. | Transición a `REJECTED`. | R06 — Rechazo de asignaciones no demostradas. |
| **N01-VAL-07** | Intento de Asignación Automática | Payload que intente forzar `assignment.status = 'ASSIGNED'`. | Transición a `REJECTED` o `BLOCKED`. | R05 — Supeditación a DEC-SE-001. |
| **N01-VAL-08** | Dependencia DEC-SE-001 Pendiente | Solicitud de materialización física en `public.services`. | Suspensión de persistencia hasta directiva. | DEC-SE-001 = PENDING. |
| **N01-VAL-09** | Dependencia DEC-SE-002 Pendiente | Solicitud de mutación de `perfiles_prestador.ubicacion`. | Suspensión de sincronización hasta directiva. | DEC-SE-002 = PENDING. |
| **N01-VAL-10** | Solicitud de Mutación en Pre-Nodo 01 | Intento de alterar columnas en `init.sql`. | `ARCHITECTURAL STOP` inmediato. | Pre-Nodo 01 Immutability. |

---

## 21. ALLOWED SCOPE (ALCANCE PERMITIDO DE IMPLEMENTACIÓN)

El futuro implementador de `NODO-01-v1.0` podrá trabajar **únicamente** dentro de:
- Recepción de interfaz (`ingestion boundary`).
- Validación de DTO conforme a `HBC v1.0` (`validation gate`).
- Construcción en memoria de `DOWNSTREAM ADAPTATION RESULT`.
- Manejo de la máquina de estados contractual del nodo (`READY_TO_RECEIVE` $\rightarrow$ `ADAPTATION_READY`).
- Integraciones downstream formalmente aprobadas por el Director.

---

## 22. PROTECTED ASSETS (ACTIVOS PROTEGIDOS)

Se certifica formalmente que los siguientes activos permanecen **100% INTACTOS Y PROTEGIDOS**:
1. **Foundation 065/066 (`backend/migrations/065_saas_foundation_core.sql`)**
2. **`fn_resolve_user_tenant` (`backend/migrations/066_context_resolution_tenant_resolver.sql`)**
3. **Context Resolution v1.0**
4. **Active Context v1.0**
5. **Hub Salón v1.0**
6. **Crear Desde Cero v1.0**
7. **Handover Boundary Contract v1.0**
8. **Pre-Nodo 01 (`backend/init.sql` y controladores B2C)**
9. **SOUL + Governance & NCP Core**

---

## 23. NO FUTURE WORK (DELIMITACIÓN DE FUTURO)

Quedan expresamente fuera de este contrato y de cualquier fase inmediata:
- NODO 02 y posteriores.
- Sistema de agenda, slots transaccionales y reservas.
- Procesamiento de pagos, pasarelas fintech y comisiones.
- Sistema de reseñas y reputación.
- Publicación comercial en marketplace.
- RBAC avanzado o invitación masiva de staff externo.
- Arquitectura multi-sede en tiempo real.

---

## 24. CLOSURE CRITERIA (CRITERIOS DE CIERRE DEL CONTRATO)

Este contrato se considera formalmente cerrado y listo para aprobación tras verificar:
1. `N01-DEC-001` aprobado y cerrado.
2. `HBC v1.0` intacto.
3. Pre-Nodo 01 intacto e inmutable.
4. `DEC-SE-001` permanece `PENDING`.
5. `DEC-SE-002` permanece `PENDING`.
6. Contrato de entrada (`Input Contract`) rigurosamente especificado.
7. Contrato de salida (`Output Contract`) formalizado conceptualmente.
8. Responsabilidades R01–R06 delimitadas.
9. No-responsabilidades taxativamente enumeradas.
10. Fronteras de seguridad y RLS blindadas.
11. Condiciones de falla y parada arquitectónica documentadas.
12. Matriz de validación contractual (N01-VAL-01 a 10) completa.
13. Cero decisiones físicas inventadas.
14. Cero código de implementación introducido.
15. Cero modificaciones fuera del directorio `/ncp/`.

---

## 25. FINAL STATUS

```text
================================================================================
NODO-01-NODE-CONTRACT-v1.0

STATUS:
CONTRACT PROPOSED / PENDING DIRECTOR APPROVAL 🟡
================================================================================
```
