# ARCH-BUNDLE-SO-01-R1 — DEFINICIÓN ARQUITECTÓNICA DURABLE DE SERVICE OFFER v1.0
## Service Offer Durable Architectural Definition & Boundary Consolidation (Reconciliación Final R1)

**BUNDLE_ID:** `ARCH-BUNDLE-SO-01-R1`  
**ESTADO:** `APPROVED / CONSOLIDATED DEFINITION — CONSISTENCY PASS — RECONCILIATION R1 PASS 🔒`  
**TIPO:** Durable Architectural Domain Definition & Boundary Synthesis (Reconciliation R1)  
**AUTORIDAD:** Director del Proyecto GlowApp SaaS  
**GOAL ORIGEN:** `ARCH-BUNDLE-SO-01` / `ARCH-BUNDLE-SO-01-R1`  
**NIVEL DE IMPLEMENTACIÓN:** `ZERO IMPLEMENTATION — ZERO MIGRATIONS — ZERO RUNTIME CHANGES`  
**CONTRATOS Y ACTIVOS PROTEGIDOS E INTACTOS:**  
- `065_saas_foundation_core.sql` (SaaS Foundation Core)  
- `066_context_resolution_tenant_resolver.sql` (Context Resolution Engine)  
- `ACTIVE-CONTEXT-NODE-CONTRACT-v1.0.md` (Active Context Node)  
- `HUB-SALON-NODE-CONTRACT-v1.0.md` (Hub Salón Node)  
- `CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md` (Crear Desde Cero Node)  
- `HANDOVER-BOUNDARY-CONTRACT-v1.0.md` (Handover Boundary Contract v1.0)  
- `NODO-01-NODE-CONTRACT-v1.0.md` (NODO-01 Runtime Engine)  
- `DEC-SE-001-DECISION-RECORD-v1.0.md` (Service Materialization Semantics)  
- `DEC-SE-002-DECISION-RECORD-v1.0.md` (Location & Schedule Independence)  
- `DEC-AS-001-DECISION-RECORD-v1.0.md` (Assignment Authority & Validation)  
- `DEC-CAT-001-DECISION-RECORD-v1.0.md` (Service Offer Lifecycle & Identity)  
- `DEC-AS-002-DECISION-RECORD-v1.0.md` (Assignment Durability & Scope)  
- `DEC-PUB-001-ARCHITECTURAL-DECISION-ANALYSIS-v1.0.md` (Publication/Availability Semantics)  
- `DEC-AS-003-MATERIALIZATION-TRIGGER-ANALYSIS-v1.0.md` (Materialization Trigger Authority)  
- `DEC-AS-004-PHYSICAL-STATE-MODEL-ANALYSIS-v1.0.md` (Physical State Model Reconciliation)  
- `DEC-AS-005-SERVICE-OFFER-IDENTITY-OWNERSHIP-ANALYSIS-v1.0.md` (Identity & Ownership Analysis)  
- `DEC-AS-006-DECISION-RECORD-v1.0.md` (Assignment Independent Entity ADR)  
- `DEC-AS-007-ARCHITECTURAL-ANALYSIS-v1.0.md` (Composite Referential Integrity)  
- `DEC-AS-008-ARCHITECTURAL-ANALYSIS-v1.0.md` (Assignment Identity Model)  
- `DEC-AS-009-ARCHITECTURAL-ANALYSIS-v1.0.md` (Derived Validity Semantics)  
- `DEC-AS-010-ARCHITECTURAL-ANALYSIS-v1.0.md` (Cardinality Model Analysis)  
- `DEC-AS-011-ARCHITECTURAL-ANALYSIS-v1.0.md` (Relation Multiplicity Analysis)  
- `DEC-AS-012-ARCHITECTURAL-ANALYSIS-v1.0.md` (Assignment Delete Semantics)  
- `DEC-AS-013-DECISION-RECORD-v1.0.md` (Assignment Audit Attributes Decision Record)  
- `DEC-AS-014-ASSIGNMENT-CONSOLIDATED-DEFINITION-v1.0.md` (Assignment Consolidated Architectural Definition)  

---

## 1. EXECUTIVE SUMMARY (RESUMEN EJECUTIVO)

El presente documento consolida la arquitectura conceptual de **`SERVICE_OFFER` (Estado Durable SaaS)** tras la aplicación de la **Reconciliación Directiva R1**, la cual ajusta estrictamente la delimitación epistemológica de dos dimensiones:
1. **Habilitación Operativa (`is_active`):** Formalizada como `UNDEFINED / PENDING DECISION`.
2. **Semántica de Borrado (`DELETE SERVICE_OFFER`):** Formalizada como `UNDEFINED / FUTURE DECISION`.

`SERVICE_OFFER` representa la unidad canónica de oferta de catálogo perteneciente de manera directa y soberana a una sede (`ESTABLISHMENT`) dentro del aislamiento transversal de un `TENANT`. Posee identidad conceptual propia e independiente (`DEC-CAT-001`, `DEC-AS-005`), no contiene prestadores (`provider_id`) embebidos, se vincula con el personal (`MEMBERSHIP`) exclusivamente a través de la relación independiente `ASSIGNMENT` ($N:M$) y está estrictamente desacoplado del motor relacional B2C (`public.services`).

Se sintetiza la totalidad de la evidencia arquitectónica existente, respondiendo exhaustivamente las 16 preguntas canónicas (`SO-01` a `SO-16`), definiendo los invariantes de dominio, separando con rigor las capas (Conceptual vs. Física vs. Operacional) y ejecutando el autochequeo de consistencia cruzada:
$$\text{SERVICE OFFER ARCHITECTURAL DEFINITION} = \text{CONSISTENT}$$
$$\text{CONSOLIDATED CONSISTENCY} = \text{PASS}$$
$$\text{RECONCILIATION R1} = \text{PASS 🔒}$$

---

## 2. EVIDENCE REVIEWED (EVIDENCIA REVISADA)

1. **`DEC-CAT-001` (Option B — Operational State):** `SERVICE_OFFER` adquiere formalmente la naturaleza de activo operativo duradero (`OPERATIONAL STATE`) post-handover, con identidad conceptual estable (`IDENTITY REQUIREMENT = DEMONSTRATED`).
2. **`DEC-SE-001` (Instanciación Tardía / Asignación Explícita):** `SERVICE_OFFER ≠ public.services`. Una oferta de servicio en SaaS puede coexistir legítimamente sin asignación (`assignment = NOT_ESTABLISHED`), y jamás materializa automáticamente filas en `public.services`.
3. **`DEC-SE-002` (Autonomía de Ubicación y Horarios):** La oferta de catálogo no impone ni restringe horarios o cabinas físicas en su definición core.
4. **`DEC-PUB-001` (Publication & Availability Semantics):** La publicación comercial y la disponibilidad en agenda son conceptos ortogonales y desacoplados del catálogo SaaS.
5. **`HBC v1.0` & `NODO-01 Node Contract v1.0`:** En la frontera de onboarding, `service_offers` es un snapshot inmutable en memoria; NODO-01 no inventa `provider_id`, no realiza auto-asignaciones y no muta B2C.
6. **`DEC-AS-005` a `DEC-AS-014`:** `SERVICE_OFFER` tiene identidad propia y ownership directo sobre `ESTABLISHMENT`; se relaciona con `MEMBERSHIP` exclusivamente a través de la entidad independiente `ASSIGNMENT` ($N:M$, validez derivada de `membership.status`, desasignación pura `DELETE ASSIGNMENT = PURE UNASSIGNMENT`).
7. **Estructura Existente en Base de Datos:**
   - `public.establishments`: Representa la sede física/operativa en PostgreSQL.
   - `public.services`: Tabla B2C preexistente (Pre-Nodo 01) con restricción `provider_id INTEGER NOT NULL`.
   - `065_saas_foundation_core.sql` & `066_context_resolution_tenant_resolver.sql`: Aislamiento multi-tenant por `tenant_id` y resolución de contexto por `establishment_id`.

---

## 3. RESPUESTAS A LAS PREGUNTAS CANÓNICAS (SO-01 A SO-16)

### SO-01 — IDENTIDAD
- **¿Qué ES SERVICE_OFFER?**  
  `SERVICE_OFFER` es una entidad conceptual del dominio SaaS que representa una oferta o ítem del catálogo comercial/operativo de una sede.
- **Significado Conceptual de su Identidad:**  
  Posee **identidad propia e independiente** (`DEC-AS-005`, `DEC-CAT-001`). Su existencia ontológica no depende de las personas que lo ejecutan ni de las sesiones de agenda. Es un objeto identificable unívocamente dentro de la sede (`IDENTITY REQUIREMENT = DEMONSTRATED`).

### SO-02 — OWNERSHIP
- **¿A qué pertenece conceptualmente?**  
  Pertenece de forma directa y exclusiva a un **`ESTABLISHMENT`** (`DEC-AS-005`). La sede es el sujeto titular de su catálogo comercial.
- **Aislamiento de TENANT:**  
  Está subordinado al aislamiento transversal del `TENANT` al que pertenece la sede (`DEC-AS-007`). No pueden existir ofertas huérfanas de establecimiento ni accesibles fuera del tenant respectivo.

### SO-03 — NATURALEZA
- **Naturaleza de Dominio:**  
  Representa un **elemento de catálogo y oferta comercial/operativa de sede** en el SaaS B2B. Define *qué servicios ofrece el establecimiento* (ej. "Corte de Cabello", "Manicura Spa") con sus parámetros de referencia (nombre, duración base, precio base).
- **Distinción respecto a `public.services`:**  
  `SERVICE_OFFER` es un objeto SaaS de sede (sin prestador). `public.services` es una entidad física B2C del motor de reservas histórico que exige obligatoriamente un prestador individualizado (`provider_id NOT NULL`).

### SO-04 — ESTADO DURABLE
- **Evolución de Ciclo de Vida (`DEC-CAT-001`):**
  1. *Transient during Create From Zero (CDC):* Nace como intención de configuración en memoria (DTO) sin persistencia física (`NEW TABLES = 0`).
  2. *Handover Snapshot (HBC v1.0 / NODO-01):* Se transporta e ingesta como snapshot inmutable en memoria con `assignment = NOT_ESTABLISHED` y sin `provider_id`.
  3. *Operational State Post-Handover:* Al superar NODO-01, se convierte formalmente en un **activo operativo duradero** del establecimiento dentro del SaaS, persistente y gobernable en el tiempo.

### SO-05 — RELACIÓN CON ASSIGNMENT
- **Vínculo Relacional:**  
  `SERVICE_OFFER` se conecta con `MEMBERSHIP` exclusivamente a través de la entidad relacional independiente `ASSIGNMENT` (`DEC-AS-006`, `DEC-AS-014`).
- **Casuística Operativa:**
  - *Sin Assignment ($0$ asignaciones):* Completamente válido en SaaS (`DEC-SE-001`). El servicio existe en el catálogo de la sede aunque nadie esté habilitado para prestarlo en ese instante.
  - *Con $1$ Assignment:* Un profesional queda formalmente habilitado en SaaS para prestar la oferta.
  - *Con Múltiples Assignments ($N$ asignaciones):* Múltiples profesionales pueden prestar simultáneamente la misma oferta de servicio en la sede ($N:M$, `DEC-AS-010`).
  - *Eliminación de Assignment:* Se aplica desasignación pura (`DEC-AS-012`); `SERVICE_OFFER` permanece **100% intacto** en el catálogo de la sede.

### SO-06 — RELACIÓN CON MEMBERSHIP
- **Relación Indirecta:**  
  `SERVICE_OFFER` **NO tiene relación directa ni atributos embebidos** que apunten a `MEMBERSHIP` o `USER`.
- **Invariante:**  
  Cualquier relación operativa entre una oferta de servicio y un profesional se realiza estrictamente a través de `ASSIGNMENT` (`DEC-AS-006`). No existen columnas ni arrays de colaboradores embebidos dentro de `SERVICE_OFFER`.

### SO-07 — RELACIÓN CON HBC
- **Papel en Handover Boundary Contract v1.0:**  
  `service_offers` constituye el array de snapshots de catálogo configurados durante el onboarding inicial.
- **Semántica de Snapshot:**  
  Representa el catálogo base que la sede desea habilitar al iniciar su operación SaaS. Llega con `assignment = "NOT_ESTABLISHED"` y sin `provider_id`, garantizando que NODO-01 reciba una declaración comercial pura de la sede.

### SO-08 — RELACIÓN CON NODO-01
- **Ingesta Conceptual en NODO-01:**  
  NODO-01 valida la estructura del payload y preserva la integridad del catálogo de sede.
- **Prohibiciones Absolutas de NODO-01:**  
  NODO-01 **NO** crea proveedores, **NO** inventa `provider_id`, **NO** asigna automáticamente personal por inferencia de categoría, **NO** materializa registros en `public.services` y **NO** publica servicios en B2C (`NODO-01-NODE-CONTRACT-v1.0.md`, `DEC-SE-001`).

### SO-09 — RELACIÓN CON B2C (`public.services`)
- **Axioma:**  
  $$\text{SERVICE\_OFFER} \neq \text{public.services}$$
- **Información Compartida vs Responsabilidad Downstream:**  
  Comparte atributos descriptivos de negocio (nombre, precio base, duración base), pero `SERVICE_OFFER` es propiedad del establecimiento. La transformación a `public.services` pertenece exclusivamente al proceso posterior de **materialización explícita downstream**, donde cada asignación autorizada puede dar lugar a un registro B2C enlazado al `provider_id` correspondiente.

### SO-10 — ESTADO / ACTIVACIÓN / PUBLICACIÓN (RECONCILIACIÓN R1)
```text
SERVICE_OFFER operational enablement / is_active = UNDEFINED / PENDING DECISION
```
- **Declaraciones Canónicas de Reconciliación:**
  1. La existencia de `is_active` en otras estructuras (como `public.services.is_active`) **NO constituye por sí sola una decisión arquitectónica** para `SERVICE_OFFER`.
  2. `public.services.is_active` **NO debe propagarse automáticamente** al modelo SaaS.
  3. Las dimensiones de **publicación** (`publication`), **activación** (`activation`), **disponibilidad** (`availability`) y **habilitación en catálogo** (`catalog enablement`) permanecen formal y conceptualmente **separadas y desacopladas** (`DEC-PUB-001`, `DEC-SE-002`).
  4. **NO se define columna física** ni tipo de dato para este concepto en este bundle.
  5. **NO se define un lifecycle operacional adicional** en el core.

### SO-11 — CICLO DE VIDA CONCEPTUAL
El único ciclo de vida respaldado por las decisiones vigentes es:
```text
TRANSIENT (Create From Zero)
       ↓
HANDOVER SNAPSHOT (HBC v1.0 / NODO-01)
       ↓
DURABLE / OPERATIONAL STATE (Post-Handover SaaS Catalog - DEC-CAT-001)
```
*No se inventan máquinas de estado complejas ni estados como `DRAFT`, `ARCHIVED`, `SUSPENDED` o `PUBLISHED` en el core.*

### SO-12 — SEPARACIÓN ESTRICTA DE IDENTIDADES
Se ratifica la disyunción absoluta de identidades en la arquitectura SaaS GlowApp:
```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       STRICT IDENTITY DISJUNCTION                           │
│                                                                             │
│   SERVICE_OFFER identity   (Catálogo comercial propio de la Sede)           │
│             ≠                                                               │
│   ASSIGNMENT identity      (Relación asociativa de habilitación durable)    │
│             ≠                                                               │
│   MEMBERSHIP identity      (Vínculo contextual del profesional con la Sede) │
│             ≠                                                               │
│   USER identity            (Identidad global de cuenta de usuario)          │
│             ≠                                                               │
│   B2C service identity     (Fila materializada individualizada en B2C)      │
└─────────────────────────────────────────────────────────────────────────────┘
```

### SO-13 — DATOS CORE VS DATOS OPERACIONALES

| Categoría | Atributos / Conceptos Incluidos | Justificación Conceptual |
| :--- | :--- | :--- |
| **CORE MÍNIMO** | • Identidad Propia (`id`)<br>• Ownership de Sede (`establishment_id`)<br>• Aislamiento de Tenant (`tenant_id`)<br>• Nombre / Título del Servicio<br>• Duración Base de Referencia<br>• Precio / Tarifa Base de Referencia | Información descriptiva indispensable para que la sede gestione su oferta en el Hub Salón (`DEC-CAT-001`, `DEC-AS-005`). |
| **PENDIENTE / DIFERIDO** | • Habilitación Operativa de Catálogo (`is_active`) | `UNDEFINED / PENDING DECISION` (Reconciliación SO-10). |
| **NO CORE / DESACOPLADO** | • `provider_id` / Prestadores embebidos<br>• Arrays de asignaciones de personal<br>• Horarios, turnos y calendarios de agenda<br>• Cabinas, estaciones o recursos físicos<br>• Canales de publicación / Visibilidad B2C<br>• Auditoría histórica de modificaciones | Pertenecen a dominios ortogonales (`ASSIGNMENT`, `SCHEDULES`, `MATERIALIZATION`, `AUDIT`). |

### SO-14 — DELETE / DESVINCULACIÓN (RECONCILIACIÓN R1)
```text
SERVICE_OFFER deletion semantics = UNDEFINED / FUTURE DECISION
```
- **Declaraciones Canónicas de Reconciliación:**
  1. `DEC-AS-012` define **exclusivamente** `DELETE ASSIGNMENT = PURE UNASSIGNMENT`.
  2. **NO existe todavía una decisión equivalente para `DELETE SERVICE_OFFER`.**
  3. **NO se determina el destino de los Assignments dependientes** (si deben eliminarse, desactivarse, bloquearse o persistir históricamente).
  4. **NO se determina la cláusula física `ON DELETE`** (ni en DDL ni en lógica de aplicación).
  5. **NO se determina borrado físico vs. borrado lógico (`deleted_at`).**
  6. **NO se determina conservación histórica ni archivado.**
  7. **NO se determina cascada (`CASCADE`).**
  8. **NO se determina bloqueo (`RESTRICT`).**
  9. **Cero impacto sobre `MEMBERSHIP`:** La eliminación de una oferta de catálogo no altera la existencia, validez ni estado (`membership.status`) del personal.

### SO-15 — FRONTERA DE MATERIALIZACIÓN
Se ratifica la compuerta canónica de flujo entre SaaS B2B y Marketplace B2C:
```text
SERVICE_OFFER (Catálogo de Sede)
      ↓
ASSIGNMENT (Habilitación de Profesional en Sede)
      ↓
EXPLICIT MATERIALIZATION AUTHORIZATION (Compuerta Explícita - DEC-AS-003)
      ↓
B2C MATERIALIZATION (public.services con provider_id individual)
```
*Los detalles de sincronización, workers, endpoints y tablas puente B2C permanecen diferidos.*

### SO-16 — INVARIANTES CONCEPTUALES DEL DOMINIO
1. **Identidad Propia:** `SERVICE_OFFER` posee identidad conceptual propia y estable.
2. **Ownership Directo:** Toda `SERVICE_OFFER` pertenece a un único `ESTABLISHMENT`.
3. **Tenant Isolation:** Toda `SERVICE_OFFER` está estrictamente aislada bajo el `tenant_id` de su sede.
4. **No Provider Inside:** `SERVICE_OFFER` **NUNCA** contiene `provider_id` ni referencias embebidas a prestadores.
5. **No Implicit Assignment:** La existencia de un `SERVICE_OFFER` **NUNCA** genera asignaciones implícitas ni automáticas.
6. **Separación de Membership:** `SERVICE_OFFER` y `MEMBERSHIP` son ontológicamente independientes; solo se conectan vía `ASSIGNMENT`.
7. **Separación de B2C:** `SERVICE_OFFER` **NUNCA** es una fila directa de `public.services`.
8. **Separación de Publicación:** `SERVICE_OFFER` no gobierna agendas ni visibilidad en marketplace.
9. **Independencia ante Desasignación:** Eliminar un `ASSIGNMENT` jamás altera ni elimina el `SERVICE_OFFER`.
10. **Validez Autónoma de Catálogo:** Un `SERVICE_OFFER` es válido y existe en el catálogo de sede independientemente de tener $0, 1$ o $N$ asignaciones.

---

## 4. MODELO CONCEPTUAL

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       TENANT (Aislamiento Transversal)                      │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                         ESTABLISHMENT                               │   │
│   │                                                                     │   │
│   │   ┌───────────────────────┐             ┌───────────────────────┐   │   │
│   │   │     SERVICE_OFFER     │             │      MEMBERSHIP       │   │   │
│   │   │ ───────────────────── │             │ ───────────────────── │   │   │
│   │   │ • id (UUID propio)    │             │ • id (UUID propio)    │   │   │
│   │   │ • establishment_id    │             │ • establishment_id    │   │   │
│   │   │ • tenant_id           │             │ • tenant_id           │   │   │
│   │   │ • name / title        │             │ • user_id             │   │   │
│   │   │ • base_duration       │             │ • role (OWNER/MGR/...)│   │   │
│   │   │ • base_price          │             │ • status (ACTIVE/...) │   │   │
│   │   └───────────┬───────────┘             └───────────┬───────────┘   │   │
│   │               │                                     │               │   │
│   │               │        ┌───────────────────┐        │               │   │
│   │               └───────►│    ASSIGNMENT     │◄───────┘               │   │
│   │                  1     │ ───────────────── │     N                  │   │
│   │                        │ • id              │                        │   │
│   │                        │ • service_offer_id│                        │   │
│   │                        │ • membership_id   │                        │   │
│   │                        │ • establishment_id│                        │   │
│   │                        │ • tenant_id       │                        │   │
│   │                        │ (Validez Derivada)│                        │   │
│   │                        └───────────────────┘                        │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. RELACIÓN CON ASSIGNMENT

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                      SERVICE_OFFER ↔ ASSIGNMENT MATRIX                      │
│                                                                             │
│ • Cardinalidad: Un SERVICE_OFFER puede participar en 0, 1 o N ASSIGNMENTs.  │
│ • Autonomía: Un SERVICE_OFFER sin ASSIGNMENT es plenamente válido en SaaS.  │
│ • Desasignación Pura: DELETE ASSIGNMENT elimina la relación asociativa,     │
│   dejando el SERVICE_OFFER intacto en el catálogo (DEC-AS-012).             │
│ • Inmutabilidad Relacional: La asignación no muta atributos del servicio.   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. RELACIÓN CON HBC (HANDOVER BOUNDARY CONTRACT v1.0)

En el contexto de `HBC v1.0`:
- `service_offers` es un array inmutable de ofertas de catálogo iniciales capturadas en el asistente "Crear Desde Cero".
- Llega a la frontera sin prestador (`provider_id` ausente) y con estado de asignación `assignment = "NOT_ESTABLISHED"`.
- Constituye el contrato de entrada para que el establecimiento inicie su catálogo en el motor SaaS.

---

## 7. RELACIÓN CON NODO-01

En el contexto de `NODO-01 Node Contract v1.0`:
- NODO-01 valida y procesa el snapshot de `service_offers` en memoria.
- **Garantías de NODO-01:**
  - Cero inserciones en `public.services`.
  - Cero creación de `perfiles_prestador`.
  - Cero vinculación automática de colaboradores a servicios.
  - Cero mutaciones DDL en esquemas de base de datos.
- Traspasa la oferta de servicio al dominio post-handover como un activo operativo de catálogo (`DEC-CAT-001`).

---

## 8. RELACIÓN CON B2C (`public.services`)

```text
┌───────────────────────────────────┐         ┌───────────────────────────────────┐
│     SERVICE_OFFER (SaaS B2B)      │         │     public.services (Core B2C)    │
├───────────────────────────────────┤         ├───────────────────────────────────┤
│ • Catálogo comercial de la Sede   │         │ • Instancia ejecutable de reserva │
│ • Ownership: ESTABLISHMENT        │   ≠     │ • Ownership: Prestador individual │
│ • provider_id: NO EXISTE          │         │ • provider_id: INTEGER NOT NULL   │
│ • No requiere profesional         │         │ • Requiere profesional asignado   │
│ • Gobernado por OWNER / MANAGER   │         │ • Consumido por clientes B2C      │
└───────────────────────────────────┘         └───────────────────────────────────┘
```

---

## 9. CICLO CONCEPTUAL DE SERVICE OFFER

```
┌─────────────────────────┐
│        TRANSIENT        │  • En memoria durante Create From Zero (CDC)
│  (Configuración DTO)    │  • NEW TABLES = 0 (DEC-CDC-001)
└────────────┬────────────┘
             │ Handover Execution
             ▼
┌─────────────────────────┐
│    HANDOVER SNAPSHOT    │  • Inmutable en HBC v1.0 / NODO-01
│ (assignment=NOT_ESTAB)  │  • Sin provider_id, sin mutación B2C
└────────────┬────────────┘
             │ Boundary Crossing
             ▼
┌─────────────────────────┐
│    OPERATIONAL STATE    │  • Activo operativo durable en catálogo SaaS (DEC-CAT-001)
│   (SaaS Post-Handover)  │  • Sujeto a gestión en Hub Salón y asignación (DEC-AS-001)
└─────────────────────────┘
```

---

## 10. INVARIANTES ARQUITECTÓNICOS

1. **`INV-SO-01` (Identidad Exclusiva):** `SERVICE_OFFER` posee un identificador unívoco propio que no colisiona ni se sobrecarga con claves de otras entidades.
2. **`INV-SO-02` (Soberanía de Sede):** Toda oferta pertenece a un `ESTABLISHMENT`; no existen ofertas globales o compartidas entre sedes no federadas.
3. **`INV-SO-03` (Aislamiento Multi-Tenant):** Ninguna consulta o mutación de `SERVICE_OFFER` puede traspasar la frontera del `tenant_id` propietario.
4. **`INV-SO-04` (Pureza de Catálogo - No Provider):** `SERVICE_OFFER` jamás contiene columnas de identificación de prestador.
5. **`INV-SO-05` (Desacoplamiento de Asignación):** La asignación de personal es un vínculo externo gobernado por la entidad `ASSIGNMENT`.
6. **`INV-SO-06` (Independencia B2C):** Un `SERVICE_OFFER` no es una fila en `public.services` y su creación no altera el esquema B2C.
7. **`INV-SO-07` (Autoridad Administrativa):** Las operaciones sobre el catálogo de sede exigen autoridad de `OWNER` o `MANAGER` en contexto activo.

---

## 11. QUÉ ES / QUÉ NO ES

### QUÉ ES:
- Es un ítem de catálogo comercial propio de la sede.
- Es un activo operativo durable en el SaaS post-handover.
- Es una entidad con identidad propia y ownership directo sobre `ESTABLISHMENT`.
- Es un objeto asociable a múltiples miembros del personal mediante `ASSIGNMENT`.
- Es el molde descriptivo de los servicios que la sede puede prestar y materializar.

### QUÉ NO ES:
- NO es un registro en `public.services`.
- NO es un servicio individualizado con prestador obligatorio (`provider_id`).
- NO es un contenedor o lista de colaboradores.
- NO es una reserva, turno ni slot de calendario.
- NO es una entidad transitoria descartable tras el onboarding.
- NO es un publicador automático en canales B2C.

---

## 12. QUÉ QUEDA DEFINIDO (NIVEL CONCEPTUAL CERRADO)

1. **Naturaleza Ontológica:** Oferta de catálogo comercial y activo operativo de sede (`DEC-CAT-001`).
2. **Identidad:** Identidad propia conceptual requerida y demostrada (`DEC-AS-005`, `DEC-CAT-001`).
3. **Ownership:** Pertenencia directa a `ESTABLISHMENT` bajo aislamiento de `TENANT`.
4. **Relación con Personal:** Exclusivamente vía `ASSIGNMENT` ($N:M$), sin prestadores embebidos.
5. **Comportamiento ante Desasignación:** Intacto ante eliminación de asignaciones (desasignación pura `DEC-AS-012`).
6. **Frontera B2C:** Desacoplado de `public.services`; materialización downstream bajo autorización explícita.
7. **Atributos Core Mínimos:** Identidad (`id`), Sede (`establishment_id`), Tenant (`tenant_id`), Nombre/Título, Duración base de referencia, Precio/Tarifa base de referencia.

---

## 13. QUÉ QUEDA INDEFINIDO / DIFERIDO (CAPA FÍSICA Y OPERACIONAL)

Las siguientes decisiones permanecen formal y explícitamente **UNDEFINED / DEFERRED** para futuros bundles de diseño:

1. **Habilitación Operativa (`is_active`):** `UNDEFINED / PENDING DECISION` (Reconciliación SO-10).
2. **Semántica de Eliminación de SERVICE_OFFER:** `UNDEFINED / FUTURE DECISION` (Reconciliación SO-14).
3. **Capa Física DDL:**
   - Nombre físico de la tabla (ej. `establishment_services`, `service_offers`, `saas_services`, etc.).
   - Nombres y tipos exactos de columnas DDL (`UUID`, `VARCHAR`, `NUMERIC`, `INTEGER`, etc.).
   - Sintaxis DDL de Foreign Keys e Índices.
   - Cláusula física `ON DELETE` al eliminar un `ESTABLISHMENT` o un `SERVICE_OFFER`.
4. **Capa Operacional / Runtime:**
   - Endpoints REST / GraphQL para mutaciones de catálogo en Hub Salón.
   - Componentes y pantallas de UI del catálogo.
   - Mecanismo de sincronización y worker de materialización hacia `public.services`.
   - Esquema físico de trazabilidad/auditoría histórica para cambios de catálogo.

---

## 14. MATRIZ DE CONSISTENCIA CRUZADA

Se evaluó la definición consolidada y reconciliada de `SERVICE_OFFER` frente a cada decisión y contrato vigente:

| Decisión / Contrato | Qué Establece | Qué Implica para SERVICE_OFFER | Qué NO Implica | ¿Contradicción? |
| :--- | :--- | :--- | :--- | :--- |
| **DEC-AS-001** | Autoridad = `OWNER/MGR` en contexto activo | Mutaciones de catálogo y asignación exigen gobernanza estricta | No implica que el autor sea parte del servicio | **NO (PASS)** |
| **DEC-AS-002** | `ASSIGNMENT = DURABLE SAAS STATE` | `SERVICE_OFFER` es el extremo de catálogo en la relación durable | No implica que el servicio contenga al profesional | **NO (PASS)** |
| **DEC-AS-003** | Materialización = Autorización explícita | `SERVICE_OFFER` no se publica automáticamente al crearse | No implica bloqueo de materialización futura | **NO (PASS)** |
| **DEC-AS-004** | Modelo físico desacoplado | `SERVICE_OFFER` tiene ciclo de persistencia independiente | No implica elección prematura de DDL | **NO (PASS)** |
| **DEC-AS-005** | Identidad y Ownership en Establishment | UUID propio y pertenencia directa a la sede | No implica prestadores embebidos | **NO (PASS)** |
| **DEC-AS-006** | `ASSIGNMENT` independiente; target `MEMBERSHIP` | La conexión con personal ocurre fuera de `SERVICE_OFFER` | No implica relación directa con `USER` | **NO (PASS)** |
| **DEC-AS-007** | Integridad compuesta `tenant + establishment` | `SERVICE_OFFER` está estrictamente acotado por tenant y sede | No implica tipo físico de FK | **NO (PASS)** |
| **DEC-AS-008** | Identidad de Assignment | Estabilidad referencial independiente entre servicio y vínculo | No implica tabla física predeterminada | **NO (PASS)** |
| **DEC-AS-009** | Validez derivada de `membership.status` | El servicio permanece en catálogo aunque el personal se inactive | No implica status dependiente en el servicio | **NO (PASS)** |
| **DEC-AS-010** | Cardinalidad $N:M$ | Un servicio puede asignarse a $N$ miembros del personal | No implica límites cuantitativos fijos | **NO (PASS)** |
| **DEC-AS-011** | Unicidad por par $(S, M)$ | El servicio participa en máximo 1 asignación activa por miembro | No implica exclusividad mono-profesional | **NO (PASS)** |
| **DEC-AS-012** | Desasignación Pura (`DELETE ASSIGNMENT`) | Eliminar asignación deja al `SERVICE_OFFER` 100% intacto | No define semántica de `DELETE SERVICE_OFFER` | **NO (PASS)** |
| **DEC-AS-013** | Atributos de Auditoría y Actoría | Trazabilidad histórica desacoplada del core de catálogo | No implica columnas de auditoría forzadas | **NO (PASS)** |
| **DEC-AS-014** | Definición consolidada de Assignment | Armonía total con el modelo de asignación cerrado | No implica diseño físico | **NO (PASS)** |
| **DEC-CAT-001** | `OPTION B — OPERATIONAL STATE` | `SERVICE_OFFER` es activo operativo durable post-handover | No implica tabla física única o DDL | **NO (PASS)** |
| **DEC-SE-001** | Instanciación tardía B2C | `SERVICE_OFFER ≠ public.services`; asignación explícita demandada | No implica mutación de Pre-Nodo 01 | **NO (PASS)** |
| **DEC-PUB-001** | Publicación ortogonal | Catálogo desacoplado de canales de venta y agendas | No implica estados de publicación en core | **NO (PASS)** |
| **HBC v1.0** | Handover Snapshot inmutable | Entrada limpia sin `provider_id` y con `assignment=NOT_ESTABLISHED`| No implica auto-asignación en frontera | **NO (PASS)** |
| **NODO-01 v1.0** | Ingesta segura sin efectos colaterales | NODO-01 procesa el snapshot sin mutar B2C ni inventar prestadores | No implica descarte de la oferta | **NO (PASS)** |

```
====================================================================================================
EVALUACIÓN DE CONSISTENCIA CRUZADA:
SERVICE OFFER ARCHITECTURAL DEFINITION = CONSISTENT
CONSOLIDATED CONSISTENCY = PASS (CERO CONTRADICCIONES DETECTADAS)
RECONCILIATION R1 = PASS
====================================================================================================
```

---

## 15. ARCHITECTURAL SELF-CHECK

```text
================================================================================
ARCHITECTURAL SELF-CHECK
================================================================================
Contradicciones encontradas:               0 / 19 evaluadas
Decisiones nuevas inventadas:              0
Cross-domain no autorizado:                0
Código modificado:                         0
DDL ejecutado:                             0
Migraciones creadas:                       0
Foundation modificada:                     0
HBC modificada:                            0
NODO-01 modificado:                        0
Pre-Node 01 modificado:                    0
Provider mapping inventado:                0
Materialización diseñada prematuramente:   0
Publication diseñada prematuramente:       0
================================================================================
SELF-CHECK RESULT: PASS 🟢
================================================================================
```

---

## 16. RESULTADO FINAL

Se declara la arquitectura conceptual de **`SERVICE_OFFER` (Estado Durable SaaS)** como **CERRADA, RECONCILIADA, CONSOLIDADA Y CONSISTENTE**:

```text
ARCH-BUNDLE-SO-01
CONSOLIDATED CONSISTENCY = PASS
RECONCILIATION R1 = PASS
```

Queda formalmente establecido el puente conceptual entre el catálogo de sede y el subsistema de asignaciones, preparando el terreno de manera impecable para el siguiente bundle:

> **ASSIGNMENT PHYSICAL ARCHITECTURE**

$$\text{ESTADO FINAL: APPROVED / RECONCILIATION R1 — CONSISTENCY PASS 🔒}$$
