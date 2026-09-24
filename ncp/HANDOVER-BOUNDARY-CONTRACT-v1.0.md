# HANDOVER BOUNDARY CONTRACT v1.0
## Contrato Semántico de la Frontera SaaS → Pre-Nodo 01

**Identificador del Contrato:** `HANDOVER-BOUNDARY-CONTRACT-v1.0`  
**Versión:** 1.0.0  
**Fecha:** 2026-09-10  
**Autoridad:** Director del Proyecto GlowApp SaaS  
**Nodo Origen:** `CREAR-DESDE-CERO-v1.0` (SaaS Cockpit Onboarding)  
**Frontera Destino:** `PRE-NODO-01` (Core B2C Engine / Marketplace Ingestion Boundary)  
**Carácter:** Semantic Boundary Contract (Contrato Semántico de Frontera)  
**Estado:** CONTRACT DEFINED / PENDING DIRECTOR APPROVAL 🟡  

---

## 1. CONTRACT IDENTITY

Este documento constituye la especificación normativa y contractual del **Handover Boundary** entre el plano SaaS Multitenant y la frontera de ingestión de Pre-Nodo 01.

Define estrictamente:
- **QUÉ CRUZA:** Datos mínimos de contexto SaaS e intención operativa declarada.
- **QUÉ SIGNIFICA:** Semántica formal e inequívoca de cada atributo transferido.
- **QUIÉN ES AUTORIDAD:** Matriz de soberanía de datos (Source of Truth).
- **QUÉ NO CRUZA:** Metadatos internos de auditoría SaaS y datos transaccionales B2C.
- **QUÉ NO SE PUEDE INFERIR:** Prohibición absoluta de derivar asignaciones u obligaciones operativas no demostradas.

---

## 2. PURPOSE

Establecer un contrato semántico neutral, determinista y seguro que permita transferir la intención de aprovisionamiento de un establecimiento desde el Cockpit SaaS hacia la frontera downstream sin:
1. Otorgar autoridad de negocio al cliente/frontend ni al mecanismo de transporte.
2. Forzar decisiones relacionales que el plano SaaS aún no ha formalizado.
3. Comprometer el aislamiento multitenant ni la inmutabilidad de Pre-Nodo 01.

---

## 3. SEMANTIC BOUNDARY

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        PLANO SAAS (AUTORIDAD B2B)                      │
│                                                                        │
│  - Tenancy & Aislamiento RLS: tenant_id, organization_id               │
│  - Contexto de Sede: establishments (datos físicos, horarios)          │
│  - Membresías de Personal: memberships (roles, status)                 │
│  - Declaración de Capacidad: people_initial_roles.assigned_categories  │
│  - Oferta Comercial de Sede: relevant_services (catálogo propuesto)    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    │ HANDOVER BOUNDARY
                                    │ (Contrato Semántico DTO v1.0)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   PLANO CORE B2C (PRE-NODO 01 INMUTABLE)               │
│                                                                        │
│  - Identidad Base de Usuario: usuarios.id                              │
│  - Perfil Operativo de Prestador: perfiles_prestador (1:1 usuario)     │
│  - Catálogo Físico de Prestador: public.services (provider_id)         │
│  - Ejecución, Agenda y Reservas: public.bookings                       │
│  - Transacciones, Pagos y Slots: motor transaccional B2C               │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 4. SOURCE OF TRUTH (MATRIZ DE AUTORIDAD)

| Dominio de Información | Autoridad Canónica | Justificación Técnica y Custodia |
| :--- | :--- | :--- |
| **Tenant** | SaaS Foundation | Clave `tenants.id`, custodiada por RLS y `fn_resolve_user_tenant`. |
| **Organization** | SaaS Foundation | Entidad legal/fiscal (`organizations`), custodiada por SaaS. |
| **Establishment** | SaaS Core | Sede operativa física (`establishments`), custodiada por SaaS. |
| **Membership** | SaaS Foundation | Vinculación contractual (`memberships`), custodiada por SaaS. |
| **Professional Context** | SaaS Core | Estado y rol del colaborador en la sede, custodiado por SaaS. |
| **Capability** | SaaS / Declaración Contextual | Aptitudes temáticas declaradas en el onboarding (`assigned_categories`). |
| **Service Offer** | SaaS / Crear Desde Cero | Catálogo comercial ofertado a nivel de sede (`relevant_services`). |
| **Provider Profile** | Pre-Nodo 01 | Perfil operativo marketplace (`perfiles_prestador`), exclusivo B2C. |
| **B2C Service Record** | Pre-Nodo 01 | Registro físico persistido con `provider_id` en `public.services`. |
| **Booking** | Pre-Nodo 01 | Transacción de reserva en `public.bookings`, exclusiva B2C. |
| **Client** | Pre-Nodo 01 | Identidad y consumo de cliente final en B2C. |
| **Execution** | Pre-Nodo 01 | Ejecución material del servicio en agenda y verificación por PIN. |
| **Marketplace Activation**| Fuera del Handover | Decisión operativa posterior de puesta en línea comercial. |

---

## 5. CONTRACT PAYLOAD (DTO SEMÁNTICO MÍNIMO)

El DTO de Handover se especifica en formato canónico de transferencia:

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

### Especificación de Atributos del DTO:

| Campo | Tipo | Obligatoriedad | Significado Semántico | Source of Truth | Identificador Estable | Derivable | Limitaciones / Reglas |
| :--- | :---: | :---: | :--- | :--- | :---: | :---: | :--- |
| `handover_contract_version`| String | **REQUIRED** | Versión semántica del contrato (`1.0.0`). | Este Contrato | Sí | No | Inmutable. |
| `establishment_context` | Object | **REQUIRED** | Contexto físico y operativo de la sede. | `establishments` | Sí (`id` UUID) | No | No persiste en B2C directamente. |
| `professional_context` | Array | **REQUIRED** | Lista de profesionales activos y capacidades. | `memberships` + Context | Sí (`user_id` INT)| No | Solo incluye miembros `ACTIVE`. |
| `service_offers` | Array | **REQUIRED** | Oferta de catálogo definida para la sede. | `relevant_services` | No (por nombre) | No | **NO contiene `provider_id`**. |
| `authorizing_identity` | Object | **REQUIRED** | Identidad del operador autorizador. | Token / Active Context | Sí (`user_id` INT)| No | Debe ser `OWNER` o `MANAGER`. |
| `assignment` | Object | **REQUIRED** | Estado formal de vinculación profesional-servicio. | Handover Boundary | N/A | Sí | **Fijado en `NOT_ESTABLISHED`**. |
| `source_state` | String | **INFORMATIONAL** | Estado de finalización en nodo origen. | Crear Desde Cero | No | Sí | Informativo para trazabilidad. |

---

## 6. ESTABLISHMENT CONTEXT

Clasificación de los atributos de la sede auditados:

| Atributo | Clasificación | Justificación y Regla Semántica |
| :--- | :---: | :--- |
| **`id` (UUID)** | **REQUIRED** | Identificador canónico de la sede en SaaS. Indispensable para trazabilidad de contexto B2B. |
| **`name`** | **REQUIRED** | Nombre comercial de la sede para recibos y descripciones B2C. |
| **`city`** | **REQUIRED** | Ciudad de operación física, requerida por `bookings.service_address`. |
| **`address`** | **REQUIRED** | Dirección física precisa, requerida para georreferenciación y reservas. |
| **`location` (Point)** | **REQUIRED** | Coordenadas PostGIS (SRID 4326) de la sede para alimentar búsquedas de proximidad. |
| **`operating_hours`** | **REQUIRED** | Horarios semanales de la sede en JSONB, base para el cálculo de disponibilidad de la sede. |
| **`is_active`** | **INFORMATIONAL** | Estado administrativo en SaaS; no activa automáticamente el marketplace B2C. |
| **`organization_id`** | **EXCLUDED** | Atributo de gobernanza fiscal/legal exclusivo de SaaS; no cruza la frontera operativa. |

---

## 7. PROFESSIONAL CONTEXT

Clasificación de los atributos de personal:

| Atributo | Clasificación | Justificación y Regla Semántica |
| :--- | :---: | :--- |
| **`user_id` (INTEGER)** | **REQUIRED** | Único identificador universal interoperable con `usuarios.id` y `perfiles_prestador.id`. |
| **`role`** | **REQUIRED** | Rol contextual en SaaS (`OWNER`, `MANAGER`, `PROFESSIONAL`). Valida aptitud operativa. |
| **`status`** | **REQUIRED** | Estado de la membresía. **Solo cruzan colaboradores con `status = 'ACTIVE'`**. |
| **`capabilities`** | **REQUIRED** | Array de categorías declaradas (`assigned_categories`). Exclusivamente `CAPABILITY`. |
| **`membership_id`** | **EXCLUDED** | UUID interno del dominio relacional SaaS; no existe en el esquema físico B2C. |
| **`relation_type`** | **EXCLUDED** | Vínculo contractual laboral/comercial en SaaS; irrelevante para la ejecución técnica en B2C. |

---

## 8. CAPABILITY (DECLARACIÓN DE CAPACIDADES)

1. **Definición:** `capabilities` (mapeado de `people_initial_roles.assigned_categories`) expresa únicamente la **aptitud técnica temática** o portafolio general declarado para un colaborador dentro del establecimiento.
2. **Restricción Semántica:** 
   - `capabilities` **NO** constituye una asignación operativa (`ASSIGNMENT`).
   - `capabilities` **NO** autoriza la creación automática de filas en `public.services`.
   - `capabilities` **NO** establece precios individuales ni compromisos de agenda.

---

## 9. SERVICE OFFER (CATÁLOGO PROPUESTO DE SEDE)

1. **Atributos Válidos:** `name`, `description`, `price`, `duration_minutes`, `category`, `is_active`.
2. **Ausencia Estricta de `provider_id`:**
   - La oferta comercial de Crear Desde Cero es a nivel de **Establecimiento**.
   - El plano SaaS **NO** transporta `provider_id` porque SaaS no ha asignado un prestador B2C individual a dicho servicio.
   - Cualquier intento de inyectar un `provider_id` ficticio, nulo forzado o derivado sin autorización constituye una violación de este contrato.

---

## 10. ASSIGNMENT SEMANTICS (ESTADO DE ASIGNACIÓN)

```text
assignment: {
  status: "NOT_ESTABLISHED"
}
```

1. **Declaración Explícita:** Este contrato declara formalmente que la asignación entre profesional y servicio está en estado **`NOT_ESTABLISHED`** (No Establecida).
2. **Prohibición de Category Matching:** Está estrictamente prohibido utilizar la coincidencia de cadenas (`service.category == capabilities[]`) como mecanismo de asignación automática o implícita.
3. **Mecanismo Futuro:** La asignación de servicios requerirá una decisión arquitectónica explícita del Director (`DEC-SE-001`) y la intervención de la capa de ingestión/provisión downstream (Nodo 01).

---

## 11. AUTHORIZING IDENTITY (IDENTIDAD AUTORIZADORA)

1. **Definición:** `authorizing_identity` expresa la persona autenticada (`user_id`) y su rol contextual (`OWNER` o `MANAGER`) que ejecutó legítimamente el flujo de onboarding en SaaS.
2. **Límites de Autoridad:**
   - La identidad autorizadora **NO** se convierte automáticamente en el prestador (`provider`) de todos los servicios.
   - La identidad autorizadora **NO** se convierte automáticamente en ejecutor técnico de los servicios del catálogo.
   - Salvo que esté explícitamente listada en `professional_context` con sus propias `capabilities`, no asume roles operativos en B2C.

---

## 12. STATE SEMANTICS (SEPARACIÓN DE ESTADOS)

El contrato distingue formalmente dos planos de estado:

1. **Create From Zero State (`source_state`):**
   - Valor: `READY_FOR_PRE_NODE_01`.
   - Alcance: Exclusivo del ciclo de vida interno de Crear Desde Cero v1.0. Representa que la compilación del paquete en memoria concluyó exitosamente sin bloqueos.
   - Impacto Downstream: **CERO**. Pre-Nodo 01 no evalúa este estado.
2. **Handover Processing State:**
   - Pertenece a la frontera de ingestión downstream (Nodo 01).
   - Administrará estados como `PENDING_INGESTION`, `PROVISIONED`, `REJECTED`, etc.

---

## 13. AUTHORITY RULES (REGLAS DE SOBERANÍA)

1. **Frontend / Cliente:**
   - Su función es estrictamente la **captura de intención interactiva**.
   - Posee **CERO AUTORIDAD DE NEGOCIO**.
   - No puede autenticar, no puede seleccionar tenant, no puede fabricar membresías, no puede asignar prestadores ni activar servicios.
2. **Backend SaaS:**
   - Valida la identidad y el Active Context server-side.
   - Aplica aislamiento multitenant mediante RLS.
   - Ensambla y garantiza la integridad determinista del DTO de Handover.

---

## 14. SECURITY & TENANT ISOLATION

El Handover Boundary está sujeto a las siguientes reglas inviolables:
1. **Autenticación Obligatoria:** Requiere identidad verificada en `req.user.id`.
2. **Active Context Enforced:** Requiere cabecera `x-active-membership-id` validada contra `memberships` con estado `ACTIVE`.
3. **Role Authorization:** Solo identidades con rol `OWNER` o `MANAGER` en la sede activa pueden autorizar la emisión del Handover.
4. **Tenant Isolation:** Todas las consultas previas operan bajo aislamiento estricto por RLS (`tenant_id`).
5. **No Spoofing:** El payload no acepta `tenant_id`, `organization_id` ni `user_id` inyectados desde el cuerpo de la petición sin validación criptográfica y relacional en base de datos.

---

## 15. TRANSPORT BOUNDARY (INDEPENDENCIA DE TRANSPORTE)

1. **Agnosticismo de Transporte:** Este contrato define la **semántica y estructura del dato**, no el canal de comunicación.
2. **Desacoplamiento:** La transferencia del DTO puede ocurrir vía invocación directa en memoria, llamada REST interna, orquestación por backend o bus de eventos downstream. La elección del protocolo de transporte corresponde a la especificación de implementación de Nodo 01.

---

## 16. TRANSFORMATION BOUNDARY (RESPONSABILIDAD DOWNSTREAM)

1. **Separación de Capas:** Cualquier transformación desde el modelo semántico de sede hacia el esquema físico de Pre-Nodo 01 (`perfiles_prestador`, `public.services` con `provider_id`, duplicación de registros, copiado de horarios) es responsabilidad exclusiva de la **capa de ingestión downstream**.
2. **Sin Mutaciones Prematuras:** Este contrato prohíbe que el emisor SaaS mute el esquema de Pre-Nodo 01.

---

## 17. IDEMPOTENCY SEMANTICS

1. **Determinismo Semántico:** Para un mismo estado contextual en SaaS y un mismo payload de entrada, Crear Desde Cero produce siempre un DTO de Handover idéntico y determinista.
2. **Distinción Técnica:** El determinismo semántico en la emisión **no equivale** a una garantía de procesamiento idempotente en la persistencia downstream. El receptor (Nodo 01) deberá implementar sus propias cláusulas de idempotencia (e.g. `ON CONFLICT`, transaccionalidad ACID).

---

## 18. VERSIONING & COMPATIBILITY

- **Identificador de Versión:** `1.0.0`
- **Regla de Evolución:** Cualquier cambio en los atributos `REQUIRED`, adición de campos de autoridad o alteración de la semántica de asignación requerirá un incremento mayor (`v2.0.0`).
- **Compatibilidad:** Diseñado para interoperar con `CREAR-DESDE-CERO-v1.0` en el origen y con la frontera inmutable de `PRE-NODO-01` en el destino.

---

## 19. NON-SCOPE (ANTI-SCOPE ESTRICTO)

Queda expresamente fuera de los límites de este contrato:
- Aprovisionamiento o inserción física en `perfiles_prestador`.
- Persistencia física de registros en `public.services`.
- Duplicación de servicios por colaborador o asignación de `provider_id`.
- Creación de tablas puente `establishment_services` o `establishment_providers`.
- Gestión de transacciones, reservas (`bookings`), clientes o pagos.
- Generación o cálculo de slots de disponibilidad en tiempo real.
- Activación comercial en el marketplace B2C (`is_active = true` público).
- Implementación de controladores, adaptadores o rutas en Nodo 01.

---

## 20. DECISION GATES

### HBC-DEC-001 — ¿El contrato semántico puede definirse sin resolver DEC-SE-001?
```text
YES
```
* **Fundamento:** El contrato transporta la oferta de servicios del establecimiento sin inyectar `provider_id`, preservando la neutralidad hasta que el Director apruebe la estrategia física downstream.

---

### HBC-DEC-002 — ¿El contrato semántico puede definirse sin resolver DEC-SE-002?
```text
YES
```
* **Fundamento:** El contrato transporta la ubicación y horarios como contexto del establecimiento, sin forzar su copiado ni transformación física hacia `perfiles_prestador`.

---

### HBC-DEC-003 — ¿El contrato debe contener Assignment?
```text
NO — NOT DEMONSTRATED
```
* **Fundamento:** La evidencia demostró que no existe asignación formal en SaaS. El contrato fija explícitamente `assignment.status = 'NOT_ESTABLISHED'`.

---

### HBC-DEC-004 — ¿`READY_FOR_PRE_NODE_01` debe ser requisito downstream?
```text
NO — NOT DEMONSTRATED
```
* **Fundamento:** Pre-Nodo 01 no posee lógica receptora de estados de onboarding. El campo permanece como metadato informativo de salida de Crear Desde Cero.

---

### HBC-DEC-005 — ¿Existe suficiente base para aprobar un contrato semántico v1.0?
```text
YES
```
* **Fundamento:** Todos los límites de autoridad, seguridad, estructura del DTO y distinciones semánticas están completamente fundamentados en evidencia física verificada.

---

## 21. ACTIVOS PROTEGIDOS

Se certifica que la definición de este contrato preserva la integridad absoluta de:
1. **Foundation v1.0**
2. **Context Resolution v1.0**
3. **Active Context v1.0**
4. **Hub Salón v1.0**
5. **Crear Desde Cero v1.0**
6. **Pre-Nodo 01**
7. **SOUL**
8. **Governance**
9. **NCP Core**

---

## 22. CLOSURE CRITERIA

Para la aprobación y cierre formal de `HANDOVER-BOUNDARY-CONTRACT-v1.0`, se requiere:
1. **Aprobación Formal:** Revisión y aprobación formal del Director del Proyecto GlowApp SaaS.
2. **Neutralidad Semántica:** Validación de que el contrato permanece estrictamente neutral respecto de `DEC-SE-001` y `DEC-SE-002`.
3. **Integridad y Seguridad:** Validación de la integridad semántica, matriz de autoridad y garantías de seguridad multitenant.
4. **Preservación de Activos:** Confirmación de que ningún activo protegido ha sido modificado.

### Estado de Decisiones Downstream:
- **`DEC-SE-001` permanece `PENDING`:** La estrategia de instanciación de servicios en B2C no se resuelve en este contrato.
- **`DEC-SE-002` permanece `PENDING`:** La sincronización física de ubicación y horarios en `perfiles_prestador` no se resuelve en este contrato.
- **Independencia Contractual:** Ninguna de las dos decisiones constituye un requisito previo para aprobar o cerrar este contrato de frontera (`HBC v1.0`).
- **Pertenencia Arquitectónica:** Ambas decisiones corresponden exclusivamente a la especificación, diseño y materialización downstream de **`NODO 01`**. `HBC v1.0` no las resuelve ni las anticipa.

---

## 23. ESTADO FINAL

```text
================================================================================
ESTADO FINAL:
CONTRACT DEFINED / PENDING DIRECTOR APPROVAL 🟡
================================================================================
```
