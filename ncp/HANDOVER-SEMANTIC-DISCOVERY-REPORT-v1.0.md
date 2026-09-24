# HANDOVER SEMANTIC DISCOVERY REPORT v1.0
## Contrato Semántico Mínimo del Handover: SaaS → Pre-Nodo 01

**Versión:** 1.0.0  
**Estado:** DISCOVERY COMPLETE / PENDING DIRECTOR ARCHITECTURAL REVIEW 🟡  
**Autoridad:** Director del Proyecto GlowApp SaaS  
**Carácter:** Read-Only Architectural Discovery (Cero Modificaciones a Código, BD o Nodos Protegidos)

---

## 1. EXECUTIVE SUMMARY

El presente informe formaliza el descubrimiento arquitectónico de la frontera semántica entre el aprovisionamiento SaaS (**`CREAR DESDE CERO v1.0`**) y el motor transaccional B2C (**`PRE-NODO 01`**).

Se ha determinado con evidencia física del repositorio que:
1. **Unidad Mínima:** El handover debe transportar el **`Context Package` canónico completo** (16 atributos), dado que no existe persistencia previa en base de datos (`DEC-CDC-001`, `DEC-CDC-002`).
2. **Naturaleza del Handover:** Es un contrato de **transferencia semántica unidireccional (ONE-WAY)** que separa la validación contextual de la ingestión/persistencia B2C.
3. **Brecha de Dominio:** En el plano SaaS, los servicios pertenecen a una sede física (`establishment_id`) con staff asignado (`people_initial_roles`). En Pre-Nodo 01, los servicios están rígidamente acoplados a un prestador individual (`services.provider_id = usuarios.id`).
4. **Roles vs. Prestadores:** Los roles SaaS (`OWNER`, `MANAGER`, `PROFESSIONAL`, `RECEPTIONIST`) **NO son equivalentes automáticos a prestadores B2C**. Solo identidades con competencias técnicas y asignación explícita pueden actuar como prestadores operativos.
5. **Estado de Cruce:** El paquete cruza la frontera en estado **`HANDOVER_READY`** (`READY_FOR_PRE_NODE_01`) y requiere un adaptador formal de ingestión antes de alcanzar los estados `PERSISTED`, `OPERATIONAL` y `PUBLISHED`.

---

## 2. SCOPE AND EVIDENCE BOUNDARY

### Fuentes de Evidencia Físicamente Auditadas:
- **Contratos NCP:** [`CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/CREAR-DESDE-CERO-NODE-CONTRACT-v1.0.md), [`HUB-SALON-NODE-CONTRACT-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/HUB-SALON-NODE-CONTRACT-v1.0.md), [`ACTIVE-CONTEXT-NODE-CONTRACT-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/ACTIVE-CONTEXT-NODE-CONTRACT-v1.0.md), [`NCP-CORE-CONTRACT-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NCP-CORE-CONTRACT-v1.0.md).
- **Servicios y Controladores SaaS:** `backend/src/services/crearDesdeCeroService.js`, `backend/src/controllers/crearDesdeCeroController.js`, `backend/src/routes/crearDesdeCeroRoutes.js`.
- **Controladores y Modelos B2C (Pre-Nodo 01):** `backend/src/controllers/serviceController.js`, `backend/src/controllers/providerController.js`, `backend/src/controllers/bookingController.js`, `backend/src/models/index.js` (`Service.belongsTo(User, { foreignKey: 'provider_id' })`).
- **Frontend B2C:** `frontend/lib/screens/provider_dashboard_screen.dart`, `frontend/lib/screens/booking_screen.dart`.

---

## 3. MEANING OF HANDOVER (HS-Q01)

El término **Handover** en esta arquitectura no es una operación homogénea. Se compone de 6 fases conceptualmente diferenciadas:

```text
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                   FASES DEL HANDOVER                                        │
├──────────────┬──────────────────┬─────────────┬──────────────┬──────────────┬───────────────┤
│  Transporte  │  Transformación  │  Ingestión  │ Persistencia │ Provisioning │  Activación   │
├──────────────┼──────────────────┼─────────────┼──────────────┼──────────────┼───────────────┤
│ Emisión del  │ Adaptación DTO   │ Recepción y │ Escritura en │ Configuración│ Puesta en     │
│ Context Pkg  │ SaaS a modelo    │ validación  │ tablas B2C   │ de entidades │ línea y slots │
│ in-memory    │ relacional B2C   │ en frontera │ (services)   │ y permisos   │ disponibles   │
└──────────────┴──────────────────┴─────────────┴──────────────┴──────────────┴───────────────┘
```

> **Axioma Semántico:**  
> **Handover** es estrictamente el **Contrato y Protocolo de Transferencia Semántica (Transporte + Desacoplamiento)** que entrega la intención validada de la sede al receptor downstream sin ejecutar por sí mismo la persistencia física ni la activación comercial.

---

## 4. MINIMUM HANDOVER UNIT (HS-Q02)

* **Pregunta:** ¿Cuál es la unidad mínima que debe cruzar la frontera?
* **Evidencia Física:** 
  - `Crear Desde Cero` no persiste borradores ni catálogos temporales en tablas intermedias (`NEW TABLES = 0`).
  - No existe un identificador de sesión persistido (`execution_id` / `session_id`) que pueda pasarse como referencia.
* **Conclusión:** La unidad mínima obligatoria que debe cruzar la frontera es el **`Context Package` canónico completo** en memoria. Debe ser autocontenido, estructurado y determinista para permitir al receptor downstream validar, transformar e ingerir sin necesidad de re-consultar o inferir datos del plano SaaS.

---

## 5. CONTEXT PACKAGE 16-ATTRIBUTE ANALYSIS (HS-Q03)

Clasificación rigurosa de los 16 atributos canónicos según su impacto operacional downstream:

| # | Atributo | Clasificación Semántica | Justificación Técnica basada en Evidencia |
| :-: | :--- | :---: | :--- |
| **1** | `organization` | **METADATA** | Provee razón social y personería jurídica. No tiene tabla en B2C. |
| **2** | `establishments` | **REQUIRED** | Provee nombre, dirección, ciudad, teléfono y horarios de la sede física. |
| **3** | `activities` | **OPTIONAL** | Líneas comerciales (ej. `HAIR_STYLING`). B2C las mapea a categorías. |
| **4** | `relevant_services` | **REQUIRED** | Catálogo base en tránsito (nombre, duración, precio, descripción). |
| **5** | `people_initial_roles` | **REQUIRED** | Personal activo con membresía asignado a categorías de servicio. |
| **6** | `identity` | **REQUIRED** | Identidad del autorizador (Owner/Manager) que ejecuta el aprovisionamiento. |
| **7** | `state` | **REQUIRED** | Condición habilitante: debe ser `READY_FOR_PRE_NODE_01`. |
| **8** | `known_evidence` | **METADATA** | Trazabilidad y garantías de verificación contextual previa. |
| **9** | `decisions` | **OPTIONAL** | Opciones de configuración del asistente (ej. `STANDARD_SETUP`). |
| **10**| `applicable_rules` | **METADATA** | Reglas de gobernanza y RLS del plano SaaS. |
| **11**| `conditions` | **METADATA** | Checklist de validación contextual superada. |
| **12**| `procedures` | **METADATA** | Metadatos de procedimiento de entrega. |
| **13**| `dependencies` | **METADATA** | Lista de dependencias satisfechas (`ACTIVE_ESTABLISHMENT_CONTEXT`). |
| **14**| `blocks` | **REQUIRED** | Lista de bloqueos: debe estar estrictamente vacía `[]`. |
| **15**| `route` | **METADATA** | Ruta lógica de handover (`HUB_SALON -> CREAR_DESDE_CERO -> PRE_NODO_01`). |
| **16**| `entry_state` | **METADATA** | Descriptor conceptual de origen (`HUB_SALON_ACTIVE_CONTEXT`). |

---

## 6. PRE-NODO 01 OPERATIONAL REQUIREMENTS (HS-Q04)

Requisitos de datos de Pre-Nodo 01 discriminados por dominio:

```text
IDENTITY   → usuarios.id (Autenticado vía JWT)
PROVIDER   → perfiles_prestador (id = usuarios.id, estatus_verificacion = 'APROBADO')
SERVICE    → public.services (provider_id = usuarios.id, name, price, duration_minutes, is_active)
LOCATION   → perfiles_prestador.ubicacion (PostGIS Point 4326)
SCHEDULE   → perfiles_prestador (active_start_hour, active_end_hour, weekly_schedule)
BOOKING    → public.bookings (client_id, provider_id, service_id, scheduled_at)
```

---

## 7. SAAS ↔ B2C SEMANTIC MAPPING (HS-Q05)

| Concepto Plano SaaS (B2B) | Concepto Plano Pre-Nodo 01 (B2C) | Estado de Mapeo Físico |
| :--- | :--- | :---: |
| `establishments` (Sede física multitenant) | `perfiles_prestador` (Persona física geolocalizada) | **DESACOPLADO** (No existe FK) |
| `memberships` (Vínculo sede-usuario con rol) | No existe entidad equivalente en B2C | **DESACOPLADO** (No existe en B2C) |
| `relevant_services` (Catálogo transitorio de sede) | `public.services` (Catálogo persistido de prestador) | **MAPEO PENDIENTE DE INGESTIÓN** |
| `people_initial_roles` (Staff activo asignado) | `usuarios` (`rol = 'PRESTADOR'`) + `perfiles_prestador` | **MAPEO CONDICIONAL** |
| `identity` (`req.user.id` + rol activo) | `usuarios.id` | **COMPATIBLE** (Misma tabla base) |

---

## 8. SERVICE / ESTABLISHMENT / MEMBERSHIP / PROVIDER GAP (HS-Q06)

### A. Relación Existente vs. Faltante
* **Existente en B2C:** `services` vinculados rígidamente a `provider_id` $\rightarrow$ `usuarios.id` (`backend/src/models/index.js` línea 24).
* **Existente en SaaS:** `relevant_services` vinculados transitoriamente a `establishment_id` con asignación en `people_initial_roles`.
* **Faltante:** No existe tabla ni columna que relacione un servicio B2C con un establecimiento SaaS o con una membresía.

### B. ¿Puede establecerse una transformación sin modificar Pre-Nodo 01?
**SÍ**, mediante un adaptador de ingestión que tome los servicios del Context Package y genere los registros en `public.services` asignándolos al `provider_id` correspondiente a cada miembro profesional del staff (`people_initial_roles.user_id`) o al Owner/Manager como prestador anfitrión.

### C. Decisión Arquitectónica Requerida
Determinar si en B2C los servicios se asignan individualmente a cada miembro del staff o si la sede opera bajo una cuenta anfitriona delegada.

---

## 9. ROLE ↔ PROVIDER ANALYSIS (HS-Q07)

```text
================================================================================
                    ANÁLISIS DE EQUIVALENCIA DE ROLES
================================================================================
OWNER         ≠  PRESTADOR AUTOMÁTICO (Puede ser administrador no estilista)
MANAGER       ≠  PRESTADOR AUTOMÁTICO (Puede ser administrador de sede)
PROFESSIONAL  ≈  PRESTADOR B2C        (Ejecutor técnico de servicios)
RECEPTIONIST  ≠  PRESTADOR B2C        (Personal de atención; NUNCA presta servicios)
================================================================================
```

> **Regla Semántica:**  
> **Prohibido asumir equivalencia universal entre Roles SaaS y Prestadores B2C.** Un usuario con membresía solo puede ser mapeado como prestador en Pre-Nodo 01 si posee rol técnico (`PROFESSIONAL` u `OWNER`/`MANAGER` con categorías asignadas) y registro formal en `perfiles_prestador`.

---

## 10. STATE BOUNDARY ANALYSIS (HS-Q08)

Evolución del ciclo de vida semántico a través de la frontera:

```text
PLANO SAAS                    FRONTERA                     PLANO B2C (CORE)
┌───────────┐  POST /bootstrap  ┌────────────────┐  Ingestion  ┌───────────┐  Activación  ┌─────────────┐
│ CAPTURED  │ ────────────────> │ HANDOVER_READY │ ──────────> │ PERSISTED │ ───────────> │ OPERATIONAL │
│ VALIDATED │                   │ (READY_FOR_PN1)│   Bridge    │           │              │  PUBLISHED  │
└───────────┘                   └────────────────┘             └───────────┘              └─────────────┘
```

El estado formal y exacto al cruzar la frontera es **`HANDOVER_READY`** (`READY_FOR_PRE_NODE_01`).

---

## 11. RESPONSIBILITY BOUNDARY (HS-Q09)

| Operación Conceptual | Plano SaaS | Frontera Handover | Plano B2C | UNKNOWN |
| :--- | :---: | :---: | :---: | :---: |
| Captura de intención | **X** | | | |
| Validación contextual | **X** | | | |
| Transformación semántica | | **X** | | |
| Ingestión / Recepción | | **X** | | |
| Persistencia física B2C | | | **X** | |
| Creación de servicios | | | **X** | |
| Asociación servicio/profesional | | **X** | | |
| Activación operacional | | | **X** | |
| Publicación en Marketplace | | | **X** | |

---

## 12. ONE-WAY / TWO-WAY ANALYSIS (HS-Q10)

* **Evidencia:** `CREAR DESDE CERO v1.0` compila el paquete y lo emite como resultado de un endpoint de aprovisionamiento inicial. No requiere polling continuo, sincronización bidireccional de estados ni locks compartidos en memoria.
* **Conclusión:** El handover es estrictamente **`ONE-WAY` (Unidireccional por Ingestión Explícita)**. Downstream responde con el resultado del procesamiento (éxito/error transaccional), pero el flujo de aprovisionamiento no mantiene acoplamiento bidireccional continuo.

---

## 13. HECHOS CONFIRMADOS (CONFIRMED FACTS)

1. `Pre-Nodo 01` es inmutable y no tiene conocimiento de tenants, sedes ni membresías.
2. `CREAR DESDE CERO v1.0` entrega con éxito un Context Package de 16 atributos en memoria.
3. `public.services` está físicamente acoplada a `provider_id = usuarios.id`.
4. `establishments.is_active` es metadata operacional y no controla el acceso SaaS.
5. No existen tablas de borrador persistente en el SaaS (`NEW TABLES = 0`).

---

## 14. INCÓGNITAS (UNKNOWNS)

1. ¿Quién ejecuta físicamente la llamada de ingestión: el frontend cliente tras recibir el Context Package, o un worker/servicio backend interno?
2. ¿Qué ocurre si un miembro asignado en `people_initial_roles` aún no tiene registro en `perfiles_prestador`?

---

## 15. BRECHAS ARQUITECTÓNICAS (ARCHITECTURAL GAPS)

1. **Gap de Ingestión:** Falta la especificación formal del nodo receptor (`NODO 01`).
2. **Gap de Persistencia de Catálogo:** Discrepancia entre catálogo por sede (SaaS) y catálogo por usuario (B2C).
3. **Gap de Activación:** Desacoplamiento entre estar aprovisionado y estar publicado en el directorio PostGIS.

---

## 16. DECISION GATES (ARCHITECTURAL STOP)

### DEC-HS-001 — MECANISMO DE INVOCACIÓN DE LA INGESTIÓN
```text
================================================================================
                              ARCHITECTURAL_STOP 🔴
================================================================================
GOAL ID           : HANDOVER-SEMANTIC-DISCOVERY-v1.0
NODE ID           : SAAS-TO-B2C-HANDOVER
AGENTE EMISOR     : DISCOVERY_ENGINE
--------------------------------------------------------------------------------
1. PROBLEMA       : El Context Package reside en memoria tras POST /bootstrap.
                    Se debe definir quién entrega el DTO al receptor downstream.
2. EVIDENCIA      : crearDesdeCeroController.js entrega { status: 'success', data: { context_package } } al cliente HTTP.
3. IMPACTO        : Bloquea la definición del punto de entrada de Nodo 01.
4. OPCIONES       : 
   A) Frontend Orchestrated: El cliente recibe el Context Package de Crear Desde Cero y lo envía a POST /api/v1/nodo01/ingest.
   B) Backend Direct Handover: El servicio de Crear Desde Cero invoca internamente el servicio de ingestión.
5. RECOMENDACIÓN  : Opción A (Frontend Orchestrated / Handover Explícito) [PROPUESTA — NO APROBADA].
6. DECISIÓN REQ.  : Director debe decidir el mecanismo de transporte del Handover.
================================================================================
```

### DEC-HS-002 — ESTRATEGIA DE ASIGNACIÓN DE SERVICIOS EN B2C
```text
================================================================================
                              ARCHITECTURAL_STOP 🔴
================================================================================
GOAL ID           : HANDOVER-SEMANTIC-DISCOVERY-v1.0
NODE ID           : SAAS-TO-B2C-HANDOVER
AGENTE EMISOR     : DISCOVERY_ENGINE
--------------------------------------------------------------------------------
1. PROBLEMA       : services.provider_id requiere un usuarios.id individual.
2. EVIDENCIA      : backend/src/models/index.js línea 24 y serviceController.js.
3. IMPACTO        : Define cómo se poblará public.services durante la ingestión.
4. OPCIONES       : 
   A) Staff Direct Mapping: Se crea un registro en public.services por cada usuario asignado en people_initial_roles.
   B) Host Provider Mapping: Se crean los servicios asociados al identity.id (Owner/Manager) como anfitrión de sede.
5. RECOMENDACIÓN  : Opción A [PROPUESTA — NO APROBADA].
6. DECISIÓN REQ.  : Director debe resolver la política de persistencia B2C.
================================================================================
```

---

## 17. ACTIVOS PROTEGIDOS E INTEGRIDAD GIT

- **Activos Protegidos:** `Foundation v1.0` (065/066), `Context Resolution v1.0`, `Active Context v1.0`, `Hub Salón v1.0`, `Crear Desde Cero v1.0`, `Pre-Nodo 01`, `SOUL`, `Governance`, `NCP Core` permanecen **100% INTACTOS**.
- **Integridad Git:**
  - `0 runtime modifications`
  - `0 database modifications`
  - `0 migrations`
  - `0 protected asset modifications`
  - Único archivo creado: Este informe documental.

---

## 18. TABLA CANÓNICA DE RESULTADO

| Elemento | Evidencia Físicamente Auditada | Estado Semántico | Decisión Requerida |
| :--- | :--- | :---: | :---: |
| **Context Package** | `crearDesdeCeroService.js` (16 atributos) | **DEFINIDO / IN-MEMORY** | Ninguna (Cerrado) |
| **Handover** | Frontera lógica SaaS $\rightarrow$ Pre-Nodo 01 | **DISCOVERED / UNIDIRECCIONAL** | `DEC-HS-001` |
| **Service Mapping** | `relevant_services` vs `public.services` | **BRECHA DE DOMINIO** | `DEC-HS-002` |
| **Provider Mapping** | `people_initial_roles` vs `perfiles_prestador` | **CONDICIONAL POR ROL** | `DEC-HS-002` |
| **Establishment Mapping** | `establishments` vs `perfiles_prestador.ubicacion` | **DESACOPLADO** | Futuro Nodo 01 |
| **Membership Mapping** | `memberships` (SaaS) vs `usuarios` (B2C) | **AUTORIDAD SERVER-SIDE** | Ninguna (Cerrado) |
| **Persistencia** | `NEW TABLES = 0` en SaaS / DB requerida en B2C | **DELEGADA A DOWNSTREAM** | Futuro Nodo 01 |
| **Transformación** | Adaptador DTO 16 atributos a entidades B2C | **RESPONSABILIDAD FRONTERA** | Futuro Nodo 01 |
| **Activación Operacional** | `is_active` / slots en `perfiles_prestador` | **RESPONSABILIDAD B2C** | Futuro Nodo 01 |

---

## 19. DIRECTOR DECISION REQUIRED

Se requiere pronunciamiento formal del Director sobre:
1. Aprobación del presente Discovery Report.
2. Resolución de los Decision Gates `DEC-HS-001` y `DEC-HS-002`.
3. Autorización para proceder con la definición del contrato arquitectónico de **`NODO 01`**.

---

## 20. ESTADO FINAL

```text
================================================================================
ESTADO:
DISCOVERY COMPLETE / PENDING DIRECTOR ARCHITECTURAL REVIEW 🟡
================================================================================
```
