# NODO-04 — NODE CONTRACT v1.0
## DOWNSTREAM B2C MATERIALIZATION ADAPTER

**ESTADO:** CLOSED / IMMUTABLE 🔒  
**CONTRATO:** v1.0 — RATIFIED  
**IMPLEMENTACIÓN:** CONFORMANT  
**AUDITORÍA:** PASS (17/17 Casos Conformes, N04-FINAL-AUDIT-02)  
**FECHA DE CIERRE:** 2026-09-12  
**AUTORIDAD DE CIERRE:** Director del Proyecto GlowApp SaaS (GO-07.2)  

---

## 1. IDENTIFICACIÓN Y ROL ARQUITECTÓNICO

- **Node ID**: `NODO-04`
- **Nombre Canónico**: Downstream B2C Materialization Adapter
- **Rol Arquitectónico**: Frontera técnica downstream de proyección entre el estado operativo SaaS y las estructuras B2C existentes.
- **Tipo de Contrato**: Node Contract (Agnóstico de transporte e implementación).
- **Mandato Central**: "NODO-04 constituye la frontera downstream mediante la cual un estado SaaS explícitamente autorizado puede ser proyectado hacia estructuras B2C existentes."

---

## 2. PROPÓSITO Y POSICIÓN EN LA ARQUITECTURA

`NODO-04` actúa como el adaptador técnico de frontera downstream encargado de proyectar conceptualmente el estado operativo interno de SaaS (`service_offers`, `service_assignments`, `memberships`) hacia estructuras transaccionales de catálogo existentes en el modelo B2C (`public.services`), **únicamente ante un acto explícito de autorización** emitido por un actor administrativo con autoridad en el Active Context (`DEC-AS-003`).

`NODO-04` **NO es un nuevo dominio de negocio SaaS** ni una extensión del catálogo interno; es una frontera downstream que preserva el desacoplamiento estricto y la soberanía del dominio SaaS.

```text
================================================================================
                    POSICIÓN ARQUITECTÓNICA DE NODO-04
================================================================================

┌─────────────────────────────────────────────────────────────────────────────┐
│                            DOMINIO SAAS MULTI-TENANT                        │
│                                                                             │
│  [SaaS Foundation (065, 066)]                                               │
│  └── Tenants / Establishments / Active Context Resolution                   │
│            │                                                                │
│            ▼                                                                │
│  [NODO-02: SaaS Catalog & Assignments (067, 068)]                           │
│  ├── service_offers (Catálogo durable de sede)                              │
│  └── service_assignments (Asignación Offer ↔ Professional)                  │
│            │                                                                │
│            ▼                                                                │
│  [NODO-03A: Staff Availability & Schedules (069)]                           │
│  └── staff_schedules (Disponibilidad semanal del staff)                     │
│            │                                                                │
│            ▼                                                                │
│  [DEC-AS-003: Acto Explícito de Autorización de Materialización]            │
│  └── Acto deliberado emitido por OWNER / MANAGER en Active Context          │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       │ (Payload de Autorización Validado)
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│               NODO-04: DOWNSTREAM B2C MATERIALIZATION ADAPTER               │
│                                                                             │
│  1. Recepción y validación de autorización contextual (OWNER / MANAGER)     │
│  2. Verificación de precondiciones normativas SaaS                          │
│  3. Proyección conceptual: (SERVICE_OFFER + ASSIGNMENT) ➔ B2C               │
│  4. Interfaz downstream hacia public.services                                │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       │ (Proyección Downstream)
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ESTRUCTURAS B2C EXISTENTES                           │
│                                                                             │
│  • public.perfiles_prestador (Dependencia de clave foránea física)          │
│  • public.services (Catálogo B2C de destino)                                │
└─────────────────────────────────────────────────────────────────────────────┘
================================================================================
```

---

## 3. SEPARACIÓN ESTRICTA DE CONCEPTOS

El contrato ratifica la separación conceptual de las siguientes dimensiones:

```text
================================================================================
                    DISTINCIÓN DE DOMINIOS Y CONCEPTOS
================================================================================
1. DOMINIO:          SaaS (Upstream Canónico)  ≠  B2C (Destino Downstream)
2. ENTIDAD:          SERVICE_OFFER             ≠  public.services
3. ACCIÓN:           MATERIALIZATION           ≠  PUBLICATION  ≠  ACTIVATION
4. IDENTIDAD:        Membership / Usuario SaaS ≠  perfiles_prestador
================================================================================
```

- **Materialization**: El acto técnico downstream de proyectar una oferta SaaS asignada hacia el catálogo B2C.
- **Publication**: La visibilidad pública del servicio en el marketplace (Lifecycle B2C independiente).
- **Activation**: El estado operativo de disponibilidad de la oferta/servicio (Lifecycle independiente).

---

## 4. INPUTS CONCEPTUALES

El input mínimo abstracto para procesar una solicitud de materialización downstream comprende:

1. **Identidad del Actor**: Identificador de la identidad autenticada (`actor_user_id`).
2. **Contexto Activo**: Tupla verificada `(tenant_id, establishment_id, actor_membership_id)`.
3. **Rol del Actor**: Rol resuelto server-side (`OWNER` | `MANAGER`).
4. **Objetivo de Materialización**: Identificador de la oferta (`service_offer_id`) y/o asignaciones de la sede activa.
5. **Acto Explícito de Autorización**: Manifestación deliberada de autorización de materialización hacia B2C (`DEC-AS-003`).

*Nota: Ningún identificador de tenant, establecimiento o rol provisto directamente por el cliente es aceptado; todo contexto es derivado e inyectado server-side por `activeContextMiddleware`.*

---

## 5. PRECONDICIONES NORMATIVAS (PRECONDITIONS)

Para procesar una solicitud de materialización en `NODO-04`, deben cumplirse simultáneamente:

1. **Autenticación e Identidad**: Identidad con sesión autenticada activa.
2. **Active Context**: Contexto activo inicializado y válido server-side.
3. **Autoridad Administrativa**: `actor.role ∈ {'OWNER', 'MANAGER'}` en el Active Context (`DEC-AS-003`).
4. **Confinamiento de Sede**: `target_establishment == activeContext.establishment_id`.
5. **Confinamiento de Tenant**: `target_tenant == activeContext.tenant_id`.
6. **Existencia y Validez de Oferta**: `service_offer` existe en la sede activa, con duración base > 0 y precio base >= 0.
7. **Existencia de Asignación**: Existe registro formal en `service_assignments` vinculando la oferta al colaborador.
8. **Operabilidad del Colaborador (DEC-AS-009)**: El colaborador asignado posee `memberships.status = 'ACTIVE'` y rol `'PROFESSIONAL'` en la misma sede activa.

> **Regla Crítica sobre Asignaciones (DEC-AS-009):**  
> `service_assignments` **NO tiene un estado operativo propio** (no existe `ACTIVE` ni `INACTIVE` en la asignación). Su validez y operabilidad derivan dinámicamente del estado de la membresía del colaborador (`memberships.status`).

---

## 6. RESPONSABILIDADES (RESPONSIBILITIES)

### In Scope:
1. **Recepción del Acto de Autorización**: Validar la presencia del acto explícito emitido por `OWNER` o `MANAGER` conforme a `DEC-AS-003`.
2. **Validación Contextual y Aislamiento**: Asegurar que la proyección downstream ocurra estrictamente dentro del tenant y establecimiento activo.
3. **Verificación de Precondiciones SaaS**: Comprobar la existencia y validez de `service_offers`, `service_assignments` y `memberships.status`.
4. **Proyección Conceptual Downstream**: Mapear los atributos comerciales de la oferta hacia la estructura de `public.services`.
5. **Reconocimiento de Dependencia Física**: Declarar y verificar la dependencia hacia `perfiles_prestador`.
6. **Consistencia Transaccional General**: Garantizar que la operación de materialización preserve consistencia transaccional.
7. **Emisión de Resultado Determinista**: Emitir el resultado conceptual del proceso de materialización.

---

## 7. NO-RESPONSABILIDADES (NON-SCOPE / FUERA DE ALCANCE)

Quedan **estricta y expresamente fuera del alcance de NODO-04**:

- ❌ **Service Offer Management**: Creación, edición, borrado o ciclo de vida de `service_offers` (Corresponde a NODO-02).
- ❌ **Assignment Management**: Creación, edición o eliminación de `service_assignments` (Corresponde a NODO-02).
- ❌ **Membership Management**: Gestión de miembros, invitaciones, roles o cambios de status en `memberships` (Corresponde a Foundation / Hub).
- ❌ **Staff Schedules & Shifts**: Gestión o modificación de `staff_schedules` (Corresponde a NODO-03A).
- ❌ **Active Context Management**: Resolución, switcheo o administración de contextos activos (Corresponde a Foundation Core 066).
- ❌ **Onboarding & Setup Flows**: Flujos guiados o asistentes iniciales (`CREAR-DESDE-CERO`).
- ❌ **Hub Salón**: Experiencia o vistas agregadas del panel de administración SaaS.
- ❌ **Bookings y Reservas**: Bookings, citas, reservas históricas o activas (`public.reservas`) están **completamente fuera del alcance de NODO-04**. NODO-04 no diseña ni asume reglas sobre reservas.
- ❌ **Clientes y Usuarios Finales**: Gestión de clientes finales B2C.
- ❌ **Slots y Disponibilidad de Reserva**: Cálculo o consulta de slots disponibles para clientes.
- ❌ **Agenda Interna del Salón**: Calendario interno de citas del establecimiento.
- ❌ **Pagos y Comisiones**: Pasarelas de pago, cobros, facturación o comisiones.
- ❌ **Publication Lifecycle**: Lógica o reglas de visibilidad pública / catálogo marketplace.
- ❌ **Activation Lifecycle**: Lógica de activación o desactivación de catálogo B2C.
- ❌ **B2C Synchronization**: No existe sincronización continua, bidireccionalidad ni reconciliación automática de estados B2C ➔ SaaS.
- ❌ **Provider Provisioning Design**: El diseño físico de cómo se aprovisiona o resuelve `perfiles_prestador` queda fuera de este contrato.

---

## 8. REGLAS CONTRACTUALES DE NEGOCIO (BUSINESS RULES)

1. **`BR-N04-01` (Inexistencia Absoluta de Automatismos)**:  
   Ninguna mutación en tablas SaaS (`service_offers`, `service_assignments`, `staff_schedules`, `memberships`) desencadena materialización automática hacia B2C. `NODO-04` solo se ejecuta ante invocación deliberada.
2. **`BR-N04-02` (Exclusividad de Autoridad Administrativa — DEC-AS-003)**:  
   Solo identidades autenticadas con rol `OWNER` o `MANAGER` en el Active Context poseen autoridad para ordenar materialización.
3. **`BR-N04-03` (Confinamiento Estricto de Sede y Tenant)**:  
   La materialización está estrictamente acotada al establecimiento activo. Prohibida cualquier proyección sobre recursos de otros establecimientos o tenants.
4. **`BR-N04-04` (Precondición de Operabilidad — DEC-AS-009)**:  
   Una oferta solo puede materializarse si existe una asignación hacia un colaborador con `memberships.status = 'ACTIVE'` y `role = 'PROFESSIONAL'`. Colaboradores en `SUSPENDED` o `REVOKED` son inoperables.
5. **`BR-N04-05` (Separación de Identidad y de Modelos)**:  
   `SERVICE_OFFER ≠ public.services`. La proyección es conceptual y no asume igualdad de identificadores, ownership físico ni lifecycles compartidos.

---

## 9. MATRIZ DE AUTORIDAD Y RBAC

| Rol en Active Context | Autorización de Materialización |
|---|---|
| **OWNER** | **AUTORIZADO** |
| **MANAGER** | **AUTORIZADO** |
| **PROFESSIONAL** | **RECHAZADO (403)** |
| **RECEPTIONIST** | **RECHAZADO (403)** |
| **CLIENTE / OTRO** | **RECHAZADO (403)** |

---

## 10. SEGURIDAD Y AISLAMIENTO MULTI-TENANT

- **Zero Client Authority**: Prohibido aceptar parámetros de tenant, establecimiento o rol provenientes del cliente.
- **Context Injection**: Toda operación se ejecuta bajo el contexto verificado por `activeContextMiddleware`.
- **Tenant Encapsulation**: Aislamiento a nivel de PostgreSQL durante la verificación de entidades SaaS.

---

## 11. FRONTERA SAAS → B2C (PROYECCIÓN CONCEPTUAL)

La proyección entre la oferta SaaS asignada y la estructura downstream en `public.services` es conceptual:

```text
================================================================================
                PROYECCIÓN CONCEPTUAL SAAS ➔ B2C
================================================================================
ENTIDAD SAAS (FUENTE)                  ESTRUCTURA B2C (DESTINO)
--------------------                  -----------------------
service_offers.name           ───►    public.services.name
service_offers.description    ───►    public.services.description
service_offers.base_price     ───►    public.services.price
service_offers.base_duration  ───►    public.services.duration_minutes
memberships (Professional)    ───►    public.services.provider_id (Dependencia)
service_offers.tenant_id      ───►    public.services.tenant_id
================================================================================
```

---

## 12. DEPENDENCIA DEL MODELO PROVIDER (`perfiles_prestador`)

### Evidencia Física Existente en PostgreSQL:
```sql
FOREIGN KEY (provider_id) REFERENCES perfiles_prestador(id) ON DELETE CASCADE
```

### Declaración Contractual de NODO-04:
"Resolver la correspondencia entre Membership/Professional SaaS y perfiles_prestador constituye una dependencia arquitectónica/física pendiente de NODO-04."

### Cláusula de No Asunción:
- `NODO-04` **NO resuelve** dicha dependencia en este contrato.
- `NODO-04` **NO asume** que `Membership.id = perfiles_prestador.id`.
- `NODO-04` **NO asume** que `Membership.user_id = perfiles_prestador.id`.
- `NODO-04` **NO asume** que `usuarios.id = perfiles_prestador.id`.
- Una coincidencia de IDs física no constituye una relación arquitectónica.

---

## 13. OUTPUT CONCEPTUAL DEL PROCESO

El contrato define los siguientes 4 resultados conceptuales posibles ante una solicitud de materialización:

1. **`AUTHORIZATION_ACCEPTED` / `MATERIALIZATION_EXECUTED`**:  
   La autorización fue validada, las precondiciones SaaS se cumplieron satisfactoriamente y la proyección downstream fue ejecutada.
2. **`MATERIALIZATION_ACCEPTED_PENDING`**:  
   La autorización fue aceptada, quedando la ejecución diferida o en procesamiento.
3. **`MATERIALIZATION_NOT_EXECUTABLE`**:  
   La solicitud cuenta con autorización y entidades SaaS válidas, pero una precondición de frontera (ej. falta de resolución de `perfiles_prestador`) impide la persistencia física downstream.
4. **`MATERIALIZATION_REJECTED`**:  
   La solicitud fue rechazada por falta de autoridad (`403`), contexto inválido (`401`/`400`) o incumplimiento de precondiciones normativas.

> **Regla Contractual:** Este resultado es estrictamente un valor conceptual de retorno de operación; no crea tablas ni estados persistentes adicionales en el dominio SaaS.

---

## 14. CONSISTENCIA TRANSACCIONAL GENERAL

- **Cláusula General**: "La materialización deberá preservar consistencia transaccional."
- **Cláusula de No Anticipación**: Los mecanismos físicos específicos (boundaries transaccionales, locks, niveles de aislamiento, políticas de reintento o transacciones compensatorias) corresponden al **Architectural Bundle Físico de NODO-04** y no a este contrato.

---

## 15. DECISIONES PENDIENTES / ARQUITECTURA FÍSICA POSTERIOR (OPEN DECISIONS)

Las siguientes decisiones quedan formalmente delimitadas como **decisiones arquitectónicas y físicas posteriores** y **NO** son resueltas en este contrato:

1. **Provider Resolution**: Mecanismo formal para mapear la identidad SaaS del colaborador a la entidad prestador.
2. **Provider Provisioning / Reuse**: Política de creación o reutilización de registros en `perfiles_prestador`.
3. **Physical B2C Ownership**: Esquema de propiedad física y aislamiento de filas en `public.services`.
4. **Materialization Persistence Model**: Mecánica física de persistencia downstream (insert, upsert, mapping table).
5. **Technical Idempotency**: Mecanismo técnico de idempotencia (claves de idempotencia, hashing, unique constraints).
6. **Endpoint / Transport Design**: Protocolo, URLs, métodos HTTP y schemas de transporte.
7. **Publication / Activation Relationship**: Reglas de publicación y activación dentro del ciclo de vida B2C.
8. **De-Materialization**: Tratamiento de des-materialización, bajas o desasignaciones (DELETE vs soft-delete vs inoperatividad).
9. **Synchronization Policy**: Políticas ante cambios posteriores en entidades SaaS upstream.

---

## 16. CRITERIOS DE TESTABILIDAD Y ACEPTACIÓN

1. **Verificación de No Automatismo**: Comprobar que inserciones/ediciones en NODO-02 y NODO-03A no produzcan escrituras automáticas en `public.services`.
2. **Verificación de Autoridad (RBAC)**: Validar que solo `OWNER` y `MANAGER` en Active Context puedan autorizar materializaciones.
3. **Verificación de Aislamiento Contextual**: Validar el rechazo de operaciones que intenten referenciar recursos de otros tenants o sedes.
4. **Verificación de Operabilidad de Membresía**: Validar que colaboradores con membresía suspendida/revocada sean rechazados para materialización.
5. **Inmutabilidad del Dominio SaaS**: Validar que la ejecución de `NODO-04` no altere las tablas maestras de Foundation ni de los nodos cerrados (`065`, `066`, `067`, `068`, `069`).

---

## 17. ESTADO FINAL DEL NODO Y MÉTRICAS DE IMPACTO

```text
================================================================================
NODO-04 — DOWNSTREAM B2C MATERIALIZATION ADAPTER
STATUS: CONTRACT APPROVED / CLOSED 🔒
DIRECTOR APPROVAL: RATIFIED 🔒

NEXT PHASE: PHYSICAL ARCHITECTURE DISCOVERY 🟡
IMPLEMENTATION: NOT AUTHORIZED 🔴

CODE CHANGES: 0
DATABASE CHANGES: 0
MIGRATIONS: 0
CLOSED NODES MODIFIED: 0
================================================================================
```
