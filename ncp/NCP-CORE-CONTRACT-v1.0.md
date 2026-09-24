# NCP CORE CONTRACT v1.0
## Node Construction Protocol — Master Architectural Specification

**Versión:** 1.0.0  
**Estado:** DEFINED / READY FOR DIRECTOR APPROVAL  
**Fase Metodológica:** DEFINIR  
**Ámbito:** Gobernanza, Control y Orquestación de la Construcción Evolutiva SaaS  
**Autoridad Raíz:** Director del Proyecto GlowApp SaaS  

---

## 1. IDENTITY

* **Nombre Oficial:** Node Construction Protocol (NCP).
* **Versión:** 1.0.0.
* **Naturaleza:** Capa de gobierno metodológico, coordinación sistemática, control de calidad y orquestación de ingeniería.
* **Declaración Negativa (Qué NO es NCP):**
  * NO es un módulo funcional ni una característica de negocio de GlowApp.
  * NO es un servicio en tiempo de ejecución (runtime) para usuarios finales.
  * NO es una extensión ni reemplazo del AI Orchestrator B2C (`backend/src/services/aiOrchestratorService.js`).
  * NO es una autoridad arquitectónica autónoma (el Director es la única Authority Root).

---

## 2. PURPOSE

Garantizar que la construcción, extensión y evolución de la arquitectura GlowApp SaaS proceda de forma determinista, modular, reproducible y estrictamente verificada nodo por nodo, eliminando el trabajo especulativo, las regresiones en activos protegidos, la toma de decisiones no autorizadas y el acoplamiento cruzado de dominios.

---

## 3. AUTHORITY

La jerarquía de autoridad canónica en GlowApp SaaS y NCP es estricta, vertical y no negociable:

```text
1. DIRECTOR — AUTHORITY ROOT
2. APPROVED ARCHITECTURAL DECISIONS
3. APPROVED NODE CONTRACT
4. SOUL + GOVERNANCE
5. EXISTING CLOSED ARCHITECTURE
6. PHYSICAL CODE AS EVIDENCE
7. AGENT / CODEX PROPOSALS
```

### Reglas de Autoridad:
1. **Director como Authority Root:** El Director del Proyecto es la única y absoluta autoridad raíz. Ningún agente, contrato o regla automática puede autoaprobarse o sustituir una directiva del Director.
2. **Approved Architectural Decisions:** Una decisión arquitectónica formalmente aprobada por el Director (`ARCH-*`) prima sobre cualquier interpretación previa y no puede ser modificada unilateralmente por un Node Contract ni por SOUL/Governance.
3. **Approved Node Contract:** Un Node Contract aprobado formalmente por el Director define la verdad técnica vinculante para la fase de implementación de dicho nodo y prevalece sobre generalidades de políticas cuando existan especificaciones locales acotadas.
4. **SOUL + Governance:** Actúa como Policy Layer transversal inmutable (seguridad, aislamiento multi-tenant, zero-trace, control de calidad). No puede anular decisiones arquitectónicas explícitas ni contratos aprobados por el Director.
5. **Existing Closed Architecture:** La arquitectura ya cerrada y validada (SaaS Foundation v1.0, Pre-Nodo 01, Context Resolution v1.0) constituye un conjunto de activos protegidos e inmutables.
6. **Physical Code as Evidence:** El código fuente y los esquemas físicos representan evidencia de la realidad técnica implementada, nunca autoridad arquitectónica por encima de decisiones o contratos aprobados.
7. **Agent / Codex Proposals:** Las propuestas generadas por agentes o Codex son insumos técnicos de nivel inferior, sujetos a revisión y sin validez vinculante hasta contar con aprobación expresa del Director.

---

## 4. SCOPE

### En Alcance:
* Gobierno del ciclo de vida de los nodos SaaS: **DEFINIR $\rightarrow$ RELACIONAR $\rightarrow$ INTEGRAR $\rightarrow$ VALIDAR $\rightarrow$ CERRAR**.
* Orquestación y delimitación de roles para los agentes de ingeniería (Evidence, Architect, Implementer, Audit).
* Control de transiciones de estado, gates de validación y protocolos de STOP.
* Protección de activos cerrados e inmutables.
* Generación estructurada de contratos de ejecución (GOALs) y paquetes de entrega (Handoffs).

### Fuera de Alcance:
* Lógica operativa B2C (Bookings, Reviews, Marketplace, E-commerce).
* Agentes conversacionales de IA para clientes (`atenaAgent`, `chronosAgent`, etc.).
* Automatización no autorizada de despliegues o modificación autónoma de bases de datos.

---

## 5. AGENT ARCHITECTURE

NCP define una estructura de agentes de ingeniería desacoplados, donde cada rol posee un mandato exclusivo y límites infranqueables:

```text
                        DIRECTOR (Authority Root)
                                   │
                                   ▼
                        NCP CORE / ORCHESTRATOR
                                   │
         ┌─────────────────────────┼─────────────────────────┐
         ▼                         ▼                         ▼
   EVIDENCE AGENT           ARCHITECT AGENT          IMPLEMENTER / CODEX
(READ / INSPECT / REPORT) (ANALYZE/RELATE/PROPOSE) (INSPECT/IMPLEMENT/TEST)
         │                         │                         │
         └─────────────────────────┼─────────────────────────┘
                                   │
                                   ▼
                              AUDIT AGENT
                      (VERIFY / TEST / AUDIT / STOP)
                                   │
                                   ▼
                          VALIDATION / CLOSURE
```

### Roles y Mandatos:
1. **Director (Authority Root):** Aprueba contratos, resuelve excepciones, autoriza cambios de arquitectura y declara el cierre (`CLOSED`).
2. **NCP Core / Orchestrator:** Coordina el flujo, verifica precondiciones, despacha GOALs, recibe Handoffs, gestiona estados y activa STOPs. No aprueba sus propias propuestas.
3. **Evidence Agent:** Realiza inspección física de código, base de datos y logs. Mandato: `READ / INSPECT / REPORT`. Cero modificaciones de código.
4. **Architect Agent:** Analiza relaciones, modela contratos, detecta impactos y formula propuestas estructuradas. Mandato: `ANALYZE / RELATE / PROPOSE / STOP`. Cero implementación de código.
5. **Implementer / Codex:** Ejecuta cambios autorizados en estricto apego al GOAL y Node Contract asignado. Mandato: `INSPECT / IMPLEMENT / TEST / REPORT`. Cero decisiones arquitectónicas unilaterales.
6. **Audit Agent:** Ejecuta verificación independiente de seguridad, regresión, RLS y pruebas físicas. Mandato: `VERIFY / TEST / AUDIT / REPORT / STOP`. Cero aprobación de cambios fuera de contrato.

---

## 6. STATE MACHINE (MÁQUINA DE ESTADOS NCP)

El ciclo de vida de cualquier nodo en NCP se rige por una máquina de estados finita y determinista:

```text
┌──────────────┐     ┌───────────┐     ┌───────────────────┐     ┌─────────────────────┐
│ NOT_DEFINED  ├────►│  DEFINED  ├────►│ CONTRACT_PENDING  ├────►│  CONTRACT_APPROVED  │
└──────────────┘     └───────────┘     └───────────────────┘     └──────────┬──────────┘
                                                                            │
                                                                            ▼
┌──────────────┐     ┌───────────┐     ┌───────────────────┐     ┌─────────────────────┐
│    CLOSED    │◄────┤ READY_FOR │◄────┤     AUDITING      │◄────┤     VALIDATING      │
│              │     │  CLOSURE  │     │                   │     │          ▲          │
└──────────────┘     └───────────┘     └───────────────────┘     └──────────┼──────────┘
                                                                            │
                                                                 ┌──────────┴──────────┐
                                                                 │    IMPLEMENTING     │
                                                                 │          ▲          │
                                                                 └──────────┼──────────┘
                                                                            │
                                                                 ┌──────────┴──────────┐
                                                                 │        READY        │
                                                                 └─────────────────────┘
```

### Tabla de Estados de Ciclo de Vida:
| Estado | Significado | Entrada Permitida Desde | Salida Hacia | Producido Por |
| :--- | :--- | :--- | :--- | :--- |
| **`NOT_DEFINED`** | Nodo identificado en roadmap pero sin alcance delimitado | Baseline | `DEFINED` | Director / NCP Core |
| **`DEFINED`** | Propósito y fronteras del nodo especificados conceptualmente | `NOT_DEFINED` | `CONTRACT_PENDING` | Architect Agent |
| **`CONTRACT_PENDING`** | Node Contract redactado, esperando revisión de Dirección | `DEFINED` | `CONTRACT_APPROVED`, `CONTRACT_STOP` | Architect Agent |
| **`CONTRACT_APPROVED`** | Node Contract formalmente aprobado y congelado por el Director | `CONTRACT_PENDING` | `READY` | Director |
| **`READY`** | Precondiciones y dependencias verificadas para comenzar implementación | `CONTRACT_APPROVED` | `IMPLEMENTING` | NCP Core |
| **`IMPLEMENTING`** | Ejecución activa de cambios mínimos autorizados en código/DB | `READY` | `VALIDATING`, `STOP_*` | Implementer / Codex |
| **`VALIDATING`** | Pruebas técnicas y funcionales ejecutadas por el implementador | `IMPLEMENTING` | `AUDITING`, `VALIDATION_FAILED` | Implementer |
| **`AUDITING`** | Verificación técnica independiente, seguridad y no-regresión | `VALIDATING` | `READY_FOR_CLOSURE`, `STOP_*` | Audit Agent |
| **`READY_FOR_CLOSURE`** | Todas las pruebas y auditorías superadas; listo para gate final | `AUDITING` | `CLOSED` | Audit Agent / NCP Core |
| **`CLOSED`** | Nodo formalmente cerrado, inmutable y protegido como Foundation | `READY_FOR_CLOSURE` | Inmutable (Requiere Directiva) | Director |

### Estados de Excepción (STOPs):
* **`ARCHITECTURAL_STOP`:** Contradicción, ambigüedad o decisión arquitectónica requerida.
* **`SECURITY_STOP`:** Vulnerabilidad de seguridad, fallo en RLS o violación de privilegios.
* **`SCOPE_STOP`:** Intento de modificar componentes fuera del alcance asignado.
* **`DATA_STOP`:** Inconsistencia estructural o riesgo de pérdida de datos.
* **`DEPENDENCY_STOP`:** Precondición insatisfecha o nodo previo no cerrado.
* **`CONTRACT_STOP`:** Desalineación entre implementación y el Node Contract.
* **`VALIDATION_FAILED`:** Fallo en suite de pruebas funcionales o de integración.

---

## 7. NODE CONTRACT SPECIFICATION

Todo nodo en GlowApp SaaS debe contar con un **Node Contract** formal antes de su implementación.

### Estructura Canónica de un Node Contract:
1. `NODE_ID` **[REQUIRED]**: Identificador unívoco (p. ej. `SAAS-NODE-01-AUTH`, `SAAS-NODE-02-CONTEXT`).
2. `NODE_NAME` **[REQUIRED]**: Nombre descriptivo del nodo.
3. `PURPOSE` **[REQUIRED]**: Objetivo arquitectónico principal en una frase clara.
4. `SCOPE` **[REQUIRED]**: Lista exhaustiva de elementos que sí componen el nodo.
5. `NON_SCOPE` **[REQUIRED]**: Lista exhaustiva de elementos prohibidos o diferidos a fases posteriores.
6. `INPUTS` **[REQUIRED]**: Datos, tokens o identidades que ingresan al nodo.
7. `OUTPUTS` **[REQUIRED]**: Estructura de respuesta, eventos o registros que emite el nodo.
8. `PRECONDITIONS` **[REQUIRED]**: Nodos cerrados y estado de base de datos requeridos.
9. `DEPENDENCIES` **[REQUIRED]**: Dependencias técnicas explícitas.
10. `ENTITIES` **[REQUIRED]**: Tablas o modelos afectados/consultados.
11. `RELATIONSHIPS` **[REQUIRED]**: Relaciones de cardinalidad y claves foráneas.
12. `BUSINESS_RULES` **[REQUIRED]**: Reglas de negocio deterministas.
13. `SECURITY_RULES` **[REQUIRED]**: Reglas de RLS, privilegios, roles y aislamiento tenant.
14. `DATA_RULES` **[REQUIRED]**: Políticas de borrado (`ON DELETE RESTRICT`), nulabilidad y tipos.
15. `INTEGRATION_BOUNDARIES` **[REQUIRED]**: Fronteras de entrada y salida con nodos adyacentes.
16. `ALLOWED_CHANGES` **[REQUIRED]**: Archivos y esquemas autorizados para modificación.
17. `PROTECTED_ASSETS` **[REQUIRED]**: Activos intocables durante la fase.
18. `FORBIDDEN_CHANGES` **[REQUIRED]**: Modificaciones terminantemente prohibidas.
19. `VALIDATION_PLAN` **[REQUIRED]**: Matriz de pruebas necesarias para validar el contrato.
20. `CLOSURE_CRITERIA` **[REQUIRED]**: Condiciones verificables para declarar el estado `CLOSED`.
21. `OPEN_DECISIONS` **[CONDITIONAL]**: Puntos pendientes de decisión por Dirección.

### Regla de Cero Cambios Estructurales (Zero Structural Changes Permitted):
Un Node Contract puede declarar formalmente:
* `ENTITIES = NONE`
* `RELATIONSHIPS = NONE`
* `NEW_TABLES = 0`
* `NEW_COLUMNS = 0`
* `NEW_FOREIGN_KEYS = 0`

La ausencia de modificaciones estructurales en base de datos es un resultado arquitectónico completamente válido y de primera clase cuando la funcionalidad del nodo se resuelve mediante lógica de servicio, consultas de lectura, funciones controladas o middleware sobre esquemas ya existentes.

Queda estrictamente prohibido crear tablas o columnas no solicitadas explícitamente:
* **`NO SPECULATIVE TABLES`:** Cero tablas anticipadas o "para uso futuro".
* **`NO FUTURE WORK`:** Cero diseño o implementación adelantada de nodos posteriores.
* **`NO CROSS-DOMAIN EXPLORATION`:** Cero acoplamiento o manipulación de esquemas ajenos al alcance del nodo.

---

## 8. ARCHITECTURE STATE MODEL

> **MODELO CONCEPTUAL — NO ES REGISTRO FÍSICO**  
> `ArchitectureState` es un modelo mental y de documentación para razonar formalmente sobre el estado consolidado de la arquitectura SaaS. **NO implica ni autoriza la creación de tablas, columnas, endpoints de API, servicios backend ni registros físicos de estado en base de datos en esta fase.** Los valores de ejemplo (p. ej. `current_active_node: "NCP-CORE-v1.0"`) son puramente ilustrativos.

Estructura conceptual de referencia:

```text
ArchitectureState {
    foundation_version    : String ("v1.0")
    active_branch         : String
    last_applied_migration: String ("066_context_resolution_tenant_resolver.sql")
    closed_nodes          : Array<NodeID> ["PRE-NODE-01", "SAAS-FOUNDATION-v1.0", "CONTEXT-RESOLUTION-v1.0"]
    current_active_node   : NodeID ("NCP-CORE-v1.0" [ILUSTRATIVO])
    node_lifecycle_state  : Enum (DEFINED | IMPLEMENTING | VALIDATING | etc.)
    active_node_contract  : ContractRef
    protected_assets      : Array<AssetRef>
    active_stops          : Array<StopRecord>
    next_allowed_action   : String
}
```

---

## 9. DECISION REGISTRY MODEL

Estructura conceptual para el registro formal de decisiones arquitectónicas (`ARCH-*`):

```text
ArchitectureDecisionRecord {
    decision_id             : String ("ARCH-CR-001", "ARCH-CR-002")
    title                   : String
    decision_summary        : String
    rationale               : String
    authority               : "DIRECTOR"
    scope                   : Array<NodeID>
    affected_entities       : Array<String>
    prohibited_interpretations: Array<String>
    status                  : Enum ("APPROVED" | "DEPRECATED" | "SUPERSEDED")
    dependencies            : Array<DecisionID>
    date_approved           : ISO8601Timestamp
}
```

---

## 10. PROTECTED ASSETS PROTOCOL

Cualquier activo marcado como **PROTECTED ASSET** queda congelado e inmutable.

### Catálogo de Activos Protegidos Canónicos:
1. **Pre-Nodo 01:** Registro, cuentas, identidades base y catálogo inicial.
2. **SaaS Foundation v1.0:** Tablas `tenants`, `organizations`, `establishments`, `memberships`, `usuarios`, claves foráneas compuestas, RLS y migración `065`.
3. **Context Resolution v1.0:** Función `fn_resolve_user_tenant`, migración `066`, `contextResolutionService.js`, `contextController.js`, `contextRoutes.js`.
4. **SOUL Design Tokens:** `frontend/lib/core/theme/tokens.dart`.
5. **Nodos CLOSED Posteriores:** Todo nodo que alcance formalmente el estado `CLOSED`.

> [!CAUTION]
> **Protocolo de Violación:** Cualquier intento no autorizado de modificar, reescribir o eliminar un Activo Protegido dispara de forma inmediata un **`SCOPE_STOP`** o **`SECURITY_STOP`**, abortando la ejecución.

---

## 11. GOAL CONTRACT SPECIFICATION

Todo GOAL emitido bajo NCP debe constituir un **Contrato de Ejecución** estructurado con:

1. `GOAL_ID` & `NODE_TARGET`: Identificador y nodo objetivo.
2. `OBJECTIVE`: Propósito exclusivo de la tarea.
3. `AUTHORITY`: Mandato y decisiones de Dirección aplicables.
4. `INPUT_CONTRACT`: Entradas técnicas verificadas.
5. `ALLOWED_SCOPE`: Archivos, tablas y módulos modificables.
6. `PROTECTED_SCOPE`: Activos prohibidos de alteración.
7. `FORBIDDEN_ACTIONS`: Lista explícita de acciones vedadas.
8. `TEST_SUITE_REQUIREMENTS`: Pruebas mínimas obligatorias.
9. `STOP_CONDITIONS`: Criterios explícitos que exigen detención inmediata.
10. `OUTPUT_FORMAT`: Estructura exacta requerida para el informe de cierre.

---

## 12. AGENT SELECTION RULES

Un agente sólo es activado por NCP Core cuando existe una pregunta técnica concreta o una tarea dentro de su mandato:

* **Activación de Evidence Agent:** Cuando se requiere auditar el estado real de base de datos, inspeccionar catálogo de PostgreSQL o revisar archivos físicos sin modificar código.
* **Activación de Architect Agent:** Cuando se requiere modelar un nuevo Node Contract, analizar dependencias o formular opciones para un ARCHITECTURAL STOP.
* **Activación de Implementer / Codex:** Cuando un Node Contract ha alcanzado el estado `CONTRACT_APPROVED` y se emite un GOAL de integración.
* **Activación de Audit Agent:** Cuando el implementador declara `VALIDATING` y se requiere una certificación independiente de no-regresión, seguridad y RLS.

---

## 13. HANDOFF CONTRACT (PAQUETE DE ENTREGA)

La transferencia entre agentes se realiza mediante un artefacto estructurado que prohíbe la transmisión informal de supuestos:

```text
HandoffPackage {
    source_agent        : Enum ("EVIDENCE" | "ARCHITECT" | "IMPLEMENTER" | "AUDIT")
    target_agent        : Enum ("NCP_CORE" | "ARCHITECT" | "IMPLEMENTER" | "AUDIT" | "DIRECTOR")
    timestamp           : ISO8601
    node_id             : String
    verified_facts      : Array<String>
    physical_evidence   : Array<EvidenceRecord>
    actions_executed    : Array<String>
    identified_findings : Array<String>
    unresolved_issues   : Array<String>
    status_declaration  : Enum ("PASS" | "STOP" | "IN_PROGRESS")
}
```

---

## 14. STOP PROTOCOL (PROTOCOLO DE DETENCIÓN FORMAL)

Ante cualquier bloqueo, ambigüedad o desalineación, el agente debe suspender modificaciones y emitir un reporte con la siguiente estructura obligatoria:

```text
================================================================================
                           [TIPO DE STOP] 🔴
================================================================================
1. PROBLEMA            : Descripción precisa del bloqueo técnico o conceptual.
2. EVIDENCIA DIRECTA   : Salidas de terminal, consultas SQL, logs o diffs reales.
3. IMPACTO TÉCNICO     : Consecuencias en arquitectura, seguridad o alcance.
4. OPCIONES EVALUADAS  : Alternativas viables (Opción A, B, C...).
5. RECOMENDACIÓN       : Propuesta técnica justificada (NO constituye aprobación).
6. DECISIÓN REQUERIDA  : Pregunta formal dirigida al Director para desbloqueo.
================================================================================
```

---

## 15. VALIDATION GATE (PUERTAS DE VALIDACIÓN TÉCNICA)

Antes de promover un nodo a auditoría final, se aplican los siguientes gates según la naturaleza del cambio:

1. **Gate Funcional:** Validación de contratos de entrada, lógica de negocio y salidas esperadas.
2. **Gate Arquitectónico:** Verificación de no-violación de límites de dominio ni acoplamiento indebido.
3. **Gate de Seguridad (RLS & Privilegios):** Ejecución bajo runtime no-superusuario (`beauty_app_user`), comprobación de `rolsuper = false`, `rolbypassrls = false` y aislamiento tenant.
4. **Gate de Integridad de Datos:** Verificación de claves foráneas compuestas y `ON DELETE RESTRICT`.
5. **Gate de No-Regresión:** Validación de que los endpoints y pruebas de nodos previos continúan operando al 100%.
6. **Gate de Reproducibilidad:** Comprobación de persistencia en migraciones versionadas y scripts idempotentes.
7. **Gate de Git & Scope:** Inspección de `git status` y `git diff --stat` para certificar que cero archivos fuera de alcance fueron tocados.

---

## 16. CLOSURE GATE (PUERTA DE CIERRE DEFINITIVO)

Un nodo sólo puede ser promovido de `READY_FOR_CLOSURE` a `CLOSED` cuando se satisfacen copulativamente:

* [ ] Todos los criterios de aceptación del Node Contract están cumplidos y demostrados con evidencia.
* [ ] La suite de pruebas de validación y seguridad presenta 100% PASS.
* [ ] Cero STOPs abiertos.
* [ ] Git working tree limpio y auditado sin contaminación de scope.
* [ ] **Aprobación y firma explícita del Director (Authority Root).**

---

## 17. AUTONOMY MATRIX (MATRIZ DE AUTONOMÍA Y AUTORIDAD)

| Acción / Decisión | NCP Core | Agentes Técnicos | Director Requerido |
| :--- | :---: | :---: | :---: |
| Inspeccionar repositorios y base de datos | ✅ Puede | ✅ Puede | ❌ No requerido |
| Ejecutar pruebas automatizadas | ✅ Puede | ✅ Puede | ❌ No requerido |
| Modificar código dentro del Node Contract aprobado | ❌ No | ✅ Implementer | ❌ No requerido |
| Formular propuestas arquitectónicas | ❌ No | ✅ Architect | ❌ No requerido |
| Crear o modificar entidades de base de datos | ❌ No | ❌ No | **OBLIGATORIO** |
| Modificar o crear relaciones / Foreign Keys | ❌ No | ❌ No | **OBLIGATORIO** |
| Alterar políticas RLS o roles de base de datos | ❌ No | ❌ No | **OBLIGATORIO** |
| Modificar o reinterpretar un Node Contract | ❌ No | ❌ No | **OBLIGATORIO** |
| Modificar cualquier Protected Asset (nodos CLOSED) | ❌ No | ❌ No | **OBLIGATORIO** |
| Ampliar el alcance (scope) de un GOAL | ❌ No | ❌ No | **OBLIGATORIO** |
| Declarar un nodo formalmente CLOSED | ❌ No | ❌ No | **OBLIGATORIO** |

---

## 18. ECONOMY RULES (REGLAS DE ECONOMÍA DE INGENIERÍA)

NCP impone principios estrictos para evitar desperdicio de contexto y sobreingeniería:

1. **NO RESEARCH WITHOUT A QUESTION:** Ninguna exploración sin un objetivo o hipótesis precisa.
2. **NO CROSS-DOMAIN EXPLORATION:** No inspeccionar ni modificar módulos fuera del nodo activo.
3. **NO FUTURE WORK:** Prohibido anticipar entidades, pantallas o lógica de fases posteriores.
4. **NO SPECULATIVE TABLES:** Cero creación de tablas o columnas "por si acaso".
5. **NO MOCKS AS ARCHITECTURE:** Los mocks son pruebas temporales, jamás arquitectura física.
6. **NO REFACTOR FOR CLEANLINESS:** No realizar refactors cosméticos o de estilo en código ajeno al scope.
7. **ONE NODE AT A TIME:** Un único nodo en implementación activa simultáneamente.
8. **EVIDENCE FIRST:** Toda afirmación debe sustentarse en evidencia de código, base de datos o logs.
9. **STOP WHEN THE QUESTION IS ANSWERED:** Detener la ejecución tan pronto se obtenga la evidencia requerida.

---

## 19. REUSE RULES (REUTILIZACIÓN DE INFRAESTRUCTURA EXISTENTE)

NCP aprovecha los patrones metodológicos y técnicos ya probados en el repositorio:
* **Taxonomía de Evidencia $E0 - E3$:** Consumo del estándar de clasificación de pruebas y telemetría.
* **Patrón de Ciclo $A \rightarrow H$:** Estructuración de fases documentales basada en los gates existentes.
* **Migration Runner:** Utilización del motor estándar de migraciones secuenciales idempotentes.
* **Trace ID & Telemetría:** Reutilización de `traceIdMiddleware` para auditoría y observabilidad.

---

## 20. CHANGE CONTROL & VERSIONING

* **Inmutabilidad del Contrato:** Una vez aprobado por el Director, este documento queda congelado.
* **Procedimiento de Enmienda:** Cualquier modificación a NCP Core Contract v1.0 requiere la emisión de un `ARCHITECTURAL STOP` y una directiva formal de actualización emitida por la Dirección.

---

## RESULTADO DEL DOCUMENTO

```text
================================================================================
                    NCP CORE CONTRACT v1.0 — DEFINITION
================================================================================
  [x] Document Location   : ncp/NCP-CORE-CONTRACT-v1.0.md
  [x] Authority Structure : FORMALIZED (Director = Authority Root)
  [x] Agent Architecture  : FORMALIZED (Evidence, Architect, Implementer, Audit)
  [x] State Machine       : 10 Lifecycle States + 7 STOP States
  [x] Protected Assets    : INTACT & GUARANTEED
  [x] Autonomy Matrix     : DEFINED (11 Operational Vectors)
  [x] Economy Rules       : ENFORCED (9 Strict Principles)
================================================================================
```

### NCP CORE CONTRACT v1.0
* **DEFINED 🟢**
* **VALIDATED 🟢**
* **READY FOR DIRECTOR APPROVAL 🟢**