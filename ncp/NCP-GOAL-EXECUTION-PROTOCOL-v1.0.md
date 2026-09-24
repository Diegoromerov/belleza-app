# NCP GOAL EXECUTION PROTOCOL v1.0
## Node Construction Protocol — Operational Execution Specification

**Versión:** 1.0.0  
**Estado:** DEFINED / READY FOR DIRECTOR APPROVAL  
**Fase Metodológica:** DEFINIR  
**Ámbito:** Protocolo Operativo Estándar para la Emisión, Validación, Despacho, Handoff y Cierre de GOALs bajo NCP  
**Autoridad Raíz:** Director del Proyecto GlowApp SaaS  
**Documento Base:** [`/ncp/NCP-CORE-CONTRACT-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NCP-CORE-CONTRACT-v1.0.md)

---

## 1. IDENTITY & PURPOSE

### Identidad
* **Nombre Oficial:** NCP GOAL Execution Protocol.
* **Versión:** 1.0.0.
* **Naturaleza:** Protocolo documental operativo y normativo que rige la ejecución de directivas de trabajo dentro del marco del Node Construction Protocol (NCP).
* **Declaración Negativa (Qué NO es este protocolo):**
  * NO es una implementación de software ni un runtime ejecutable.
  * NO crea agentes automatizados ni bots autónomos.
  * NO crea tablas, esquemas, APIs ni endpoints en base de datos o backend.
  * NO modifica la arquitectura cerrada ni los activos protegidos.

### Propósito y Pregunta Operativa Central
Este protocolo responde de manera determinista a la pregunta fundamental del flujo de trabajo:
> **¿Qué ocurre exactamente desde que el Director emite un GOAL hasta que NCP Core verifica precondiciones, autoriza su ejecución, lo despacha al agente asignado, recibe el paquete de entrega (Handoff), lo somete a validación/auditoría y determina si la ejecución continúa, se detiene o queda lista para la decisión de cierre?**

---

## 2. CANONICAL AUTHORITY HIERARCHY

El presente protocolo se subordina estrictamente a la jerarquía de autoridad canónica definida en el **NCP Core Contract v1.0**:

```text
1. DIRECTOR — AUTHORITY ROOT
2. APPROVED ARCHITECTURAL DECISIONS (ARCH-*)
3. APPROVED NODE CONTRACT
4. SOUL + GOVERNANCE (Policy Layer)
5. EXISTING CLOSED ARCHITECTURE (Protected Assets)
6. PHYSICAL CODE AS EVIDENCE
7. AGENT / CODEX PROPOSALS
```

### Reglas de Autoridad Operativa:
1. **Director como Authority Root:** El Director es la única entidad con facultad para emitir GOALs, resolver excepciones (`STOPs`), aprobar decisiones arquitectónicas (`ARCH-*`) y declarar el cierre formal (`CLOSED`) de un nodo.
2. **Inmutabilidad del Node Contract:** Ningún GOAL, agente ni Handoff puede reinterpretar, flexibilizar ni modificar un Node Contract formalmente aprobado por el Director.
3. **NCP Core como Orquestador:** NCP Core valida y canaliza las ejecuciones; no posee autoridad para autoaprobar contratos ni decisiones.
4. **Implementer / Codex Acotado:** El ejecutor sólo puede realizar modificaciones físicas expresamente autorizadas en el `ALLOWED_SCOPE` del GOAL.
5. **Propuestas Subordinadas:** Cualquier recomendación técnica de un agente es una propuesta sin validez vinculante hasta contar con la aprobación explícita del Director.

---

## 3. TRIPARTITE CONCEPTUAL DISTINCTION

Para evitar solapamientos y desvíos de alcance, el protocolo establece una separación conceptual estricta y obligatoria entre tres instrumentos:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. NODE CONTRACT                                                            │
│ Define QUÉ ES EL NODO: Modelo de datos, reglas de negocio, límites de       │
│ seguridad, fronteras de integración, RLS e invariantes del sistema.         │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ gobierna
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 2. GOAL (Execution Contract)                                                │
│ Define QUÉ EJECUCIÓN AUTORIZADA SE REALIZA: Instrucción acotada, alcance    │
│ permitido, agente asignado, precondiciones y criterios de parada.           │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ produce
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 3. HANDOFF (Delivery Package)                                               │
│ Define QUÉ RESULTADO SE ENTREGA: Hechos verificados, evidencia física,      │
│ acciones ejecutadas, hallazgos y declaración formal de estado.              │
└─────────────────────────────────────────────────────────────────────────────┘
```

> [!IMPORTANT]
> Un **GOAL** nunca sustituye a un **Node Contract**. Un **Handoff** nunca introduce cambios fuera del **GOAL**.

---

## 4. GOAL AS AN EXECUTION CONTRACT

Todo GOAL emitido bajo NCP constituye un **Contrato de Ejecución Formal**. La estructura obligatoria de un GOAL es:

```text
GoalExecutionContract {
    GOAL_ID                 : String (Identificador único, ej. "GOAL-CR-004-INTEGRATE")
    NODE_TARGET             : NodeID (Nodo al que pertenece la tarea, ej. "CONTEXT-RESOLUTION-v1.0")
    OBJECTIVE               : String (Propósito conciso y determinista de la ejecución)
    AUTHORITY               : String (Directivas del Director y decisiones ARCH-* aplicables)
    INPUT_CONTRACT          : String (Parámetros de entrada, identidades o precondiciones de datos)
    ALLOWED_SCOPE           : Array<FilePath | DirectoryPath> (Archivos autorizados para modificación)
    PROTECTED_SCOPE         : Array<AssetRef> (Activos intocables durante la ejecución)
    FORBIDDEN_ACTIONS       : Array<String> (Acciones terminantemente prohibidas)
    DEPENDENCIES            : Array<NodeID | DecisionID> (Nodos o decisiones requeridas)
    PRECONDITIONS           : Array<String> (Condiciones técnicas del entorno y DB)
    TEST_SUITE_REQUIREMENTS : Array<TestRequirement> (Pruebas obligatorias de validación)
    STOP_CONDITIONS         : Array<String> (Criterios de aborto inmediato y escalamiento)
    EXPECTED_OUTPUT         : String (Formato y contenido esperado del entregable)
    CLOSURE_EXPECTATION     : String (Expectativa de transición o reporte final)
}
```

---

## 5. PRE-EXECUTION GATE (LOS 12 CHECKS)

Antes de autorizar o despachar cualquier GOAL para su ejecución física o analítica, NCP Core debe ejecutar de forma obligatoria el **Pre-Execution Gate** compuesto por 12 verificaciones deterministas:

```text
                                EMISIÓN DE GOAL POR EL DIRECTOR
                                              │
                                              ▼
┌───────────────────────────────────────────────────────────────────────────────────────────┐
│                                 PRE-EXECUTION GATE (12 CHECKS)                            │
│                                                                                           │
│   [ 1] Node Target identificado en catálogo/roadmap formal                                │
│   [ 2] Node Contract existente en repositorio documental                                  │
│   [ 3] Node Contract en estado formal CONTRACT_APPROVED (o fase DEFINIR autorizada)       │
│   [ 4] Estructura del GOAL completa y conforme al Execution Contract                      │
│   [ 5] Jerarquía de Authority válida y respaldada por el Director                         │
│   [ 6] Allowed Scope explícito, acotado y no ambiguo                                      │
│   [ 7] Protected Scope identificado (SaaS Foundation, Pre-Nodo 01, etc.)                  │
│   [ 8] Precondiciones técnicas y de datos verificadas                                     │
│   [ 9] Dependencias arquitectónicas satisfechas                                           │
│   [10] Cero STOPs abiertos o incompatibles en el nodo objetivo                            │
│   [11] Nodos previos requeridos en estado CLOSED                                          │
│   [12] Políticas SOUL + Governance aplicables identificadas                               │
└─────────────────────────────────────────────┬─────────────────────────────────────────────┘
                                              │
                     ┌────────────────────────┴────────────────────────┐
                     │ ¿Supera el 100% de los 12 Checks?               │
                     └───────┬─────────────────────────────────┬───────┘
                             │ SÍ                              │ NO
                             ▼                                 ▼
                     ┌───────────────┐                 ┌───────────────┐
                     │  AUTHORIZED   │                 │   NO EXECUTE  │
                     │  (Despacho)   │                 │   (STOP 🔴)   │
                     └───────────────┘                 └───────────────┘
```

> [!CAUTION]
> **Prohibición de Ejecución por Inferencia:** Si cualquiera de los 12 checks falla o presenta ambigüedad, la ejecución se cancela de inmediato (**`NO EXECUTE`**) y se emite el STOP correspondiente al Director. Queda estrictamente prohibida la ejecución parcial o basada en supuestos.

---

## 6. GOAL EXECUTION LIFECYCLE

El ciclo de vida de un GOAL es independiente del ciclo de vida del Nodo. Representa el estado transaccional de una tarea operativa específica:

```text
┌─────────┐     ┌──────────┐     ┌───────────┐     ┌────────────┐     ┌────────────┐
│  DRAFT  ├────►│  ISSUED  ├────►│ PRECHECK  ├────►│ AUTHORIZED ├────►│ DISPATCHED │
└─────────┘     └──────────┘     └─────┬─────┘     └────────────┘     └──────┬─────┘
                                       │                                     │
                                       ▼ (Fallo)                             ▼
                                ┌─────────────┐                       ┌─────────────┐
                                │   STOPPED   │                       │ IN_PROGRESS │
                                └─────────────┘                       └──────┬──────┘
                                                                             │
                                                                             ▼
┌───────────┐     ┌───────────────┐     ┌────────────────────┐     ┌─────────────────┐
│ COMPLETED │◄────┤ AUDIT_PENDING │◄────┤ VALIDATION_PENDING │◄────┤ EJECUCIÓN FÍSICA│
└───────────┘     └───────┬───────┘     └─────────┬──────────┘     └─────────────────┘
                          │ (Fallo)               │ (Fallo)
                          ▼                       ▼
                   ┌─────────────┐         ┌─────────────┐
                   │   STOPPED   │         │   STOPPED   │
                   └─────────────┘         └─────────────┘
```

### Matriz de Estados del GOAL:
| Estado del GOAL | Descripción | Transición Siguiente | Agente Activo |
| :--- | :--- | :--- | :--- |
| **`DRAFT`** | Redacción inicial del contrato de ejecución | `ISSUED` | Director / NCP Core |
| **`ISSUED`** | GOAL emitido formalmente por el Director | `PRECHECK` | NCP Core |
| **`PRECHECK`** | Evaluación de los 12 checks del Pre-Execution Gate | `AUTHORIZED`, `STOPPED` | NCP Core |
| **`AUTHORIZED`** | Precondiciones satisfechas; autorización formal de ejecución | `DISPATCHED` | NCP Core |
| **`DISPATCHED`** | Tarea asignada al agente específico según reglas de despacho | `IN_PROGRESS` | NCP Core $\rightarrow$ Agente |
| **`IN_PROGRESS`** | Ejecución activa bajo el alcance estricto del GOAL | `VALIDATION_PENDING`, `STOPPED` | Agente Asignado |
| **`VALIDATION_PENDING`** | Pruebas técnicas ejecutadas por el implementador listas para revisión | `AUDIT_PENDING`, `STOPPED` | Implementer / NCP Core |
| **`AUDIT_PENDING`** | Auditoría independiente de no-regresión y seguridad en curso | `COMPLETED`, `STOPPED` | Audit Agent |
| **`COMPLETED`** | GOAL ejecutado, validado y auditado con Handoff aceptado | Siguiente GOAL / Cierre | NCP Core / Director |

### Estados de Excepción del GOAL:
* **`STOPPED`:** Ejecución suspendida por la activación de un STOP protocol (requiere decisión del Director o corrección de precondición).
* **`REJECTED`:** GOAL rechazado en Pre-Execution Gate por violación de invariantes o falta de autorización.
* **`FAILED`:** Fallo irrecuperable en validación técnica o pruebas de integración.
* **`CANCELLED`:** GOAL revocado o cancelado explícitamente por el Director.

> [!NOTE]
> **Separación Ontológica:** El estado `COMPLETED` de un GOAL **NO** significa que el nodo esté `CLOSED`. Un nodo requiere la satisfacción total de su Node Contract y la aprobación final del Director.

---

## 7. DETERMINISTIC DISPATCH RULES

NCP Core aplica reglas deterministas para seleccionar y activar **únicamente al agente necesario** para la tarea:

```text
┌──────────────────────────┬──────────────────────┬────────────────────────────────────────────────────────┐
│ Tipo de Tarea            │ Agente Asignado      │ Mandato Exclusivo                                      │
├──────────────────────────┼──────────────────────┼────────────────────────────────────────────────────────┤
│ Inspección Física / Data │ EVIDENCE AGENT       │ Inspeccionar DB, logs y código existente (READ ONLY).  │
│ Modelado / Propuestas    │ ARCHITECT AGENT      │ Analizar impactos, redactar contratos y proponer ARCH. │
│ Integración / Código     │ IMPLEMENTER / CODEX  │ Modificar código/DB autorizado en Node Contract.       │
│ Verificación / Seguridad │ AUDIT AGENT          │ Pruebas independientes, RLS, seguridad y no-regresión. │
└──────────────────────────┴──────────────────────┴────────────────────────────────────────────────────────┘
```

### Principios Rectores de Despacho:
1. **`NO RESEARCH WITHOUT A QUESTION`:** Prohibido iniciar investigaciones exploratorias sin una pregunta técnica precisa formulada en el GOAL.
2. **`NO CROSS-DOMAIN EXPLORATION`:** Prohibido explorar o interactuar con módulos ajenos al nodo objetivo.
3. **`ONE NODE AT A TIME`:** Se ejecuta un único nodo a la vez de forma secuencial y determinista.
4. **`EVIDENCE FIRST`:** Toda afirmación técnica debe sustentarse en evidencia física verificable (queries, AST, logs, tests).
5. **`MINIMAL AGENT ACTIVATION`:** No se activa ningún agente si la tarea puede resolverse directamente mediante inspección determinista de NCP Core.

---

## 8. HANDOFF PROTOCOL & PACKAGE STRUCTURE

El intercambio de resultados entre participantes sigue un flujo cerrado y estructurado:

```text
┌──────────────┐     ┌──────────────┐     ┌─────────────────┐     ┌──────────────┐     ┌───────────────┐
│   NCP CORE   ├───► │ AGENT ASIG.  ├───► │ HANDOFF PACKAGE ├───► │   NCP CORE   ├───► │   NEXT GATE   │
└──────────────┘     └──────────────┘     └─────────────────┘     └──────────────┘     └───────────────┘
```

### Estructura Canónica del Handoff Package:
```text
HandoffPackage {
    source_agent        : Enum ("EVIDENCE" | "ARCHITECT" | "IMPLEMENTER" | "AUDIT" | "NCP_CORE")
    target_agent        : Enum ("NCP_CORE" | "ARCHITECT" | "IMPLEMENTER" | "AUDIT" | "DIRECTOR")
    goal_id             : String
    node_id             : String
    timestamp           : ISO8601Timestamp
    verified_facts      : Array<String>
    physical_evidence   : Array<EvidenceRecord { type: String, path_or_query: String, output: String }>
    actions_executed    : Array<String>
    identified_findings : Array<String>
    unresolved_issues   : Array<String>
    status_declaration  : Enum ("PASS" | "STOP" | "IN_PROGRESS")
}
```

### Epistemología Obligatoria del Handoff:
Para evitar la contaminación de supuestos, todo elemento del Handoff debe clasificarse con rigor:
* **`FACT` (Hecho):** Realidad empírica comprobada directamente en el sistema físico.
* **`EVIDENCE` (Evidencia):** Salida exacta de comando, traza de test, consulta SQL o fragmento de archivo que respalda el Hecho.
* **`FINDING` (Hallazgo):** Observación técnica, discrepancia o anomalía identificada durante la ejecución.
* **`PROPOSAL` (Propuesta):** Alternativa técnica sugerida para resolver un problema (no vinculante).
* **`DECISION` (Decisión):** Resolución vinculante aprobada exclusivamente por el Director.

---

## 9. STOP PROTOCOL INTEGRATION

Cuando un agente encuentra una condición de bloqueo, anomalía de seguridad o necesidad de decisión arquitectónica, la ejecución se detiene de forma instantánea mediante la integración con el **STOP Protocol del NCP Core Contract**:

### Catálogo de STOPs:
* **`ARCHITECTURAL_STOP`:** Ambigüedad, contradicción o decisión arquitectónica requerida (`ARCH-*`).
* **`SECURITY_STOP`:** Vulnerabilidad, falla en RLS, bypass de tenant o exposición de datos.
* **`SCOPE_STOP`:** Necesidad o intento de modificar archivos fuera del `ALLOWED_SCOPE`.
* **`DATA_STOP`:** Riesgo de pérdida de datos, inconsistencia estructural o violación de integridad referencial.
* **`DEPENDENCY_STOP`:** Precondición técnica o dependencia de nodo previo no cumplida.
* **`CONTRACT_STOP`:** Desalineación entre los requisitos del Node Contract y la realidad técnica.
* **`VALIDATION_FAILED`:** Fallo en suite de pruebas unitarias, de integración o regresión.

### Estructura Canónica del Reporte de STOP:
```text
================================================================================
                                [TIPO DE STOP] 🔴
================================================================================
GOAL ID           : [Identificador del GOAL activo]
NODE ID           : [Identificador del nodo objetivo]
AGENTE EMISOR     : [EVIDENCE | ARCHITECT | IMPLEMENTER | AUDIT | NCP_CORE]
--------------------------------------------------------------------------------
1. PROBLEMA       : Descripción exacta y concisa del bloqueo o contradicción.
2. EVIDENCIA      : Código físico, traza de error, query o salida de prueba.
3. IMPACTO        : Consecuencias arquitectónicas, de seguridad o de integridad.
4. OPCIONES       : Alternativas técnicas mutuamente excluyentes (A, B, C).
5. RECOMENDACIÓN  : Propuesta técnica del agente con justificación.
6. DECISIÓN REQ.  : Pregunta binaria o selección concreta requerida al Director.
================================================================================
```

> [!CAUTION]
> **Prohibición de Continuación Silenciosa:** Ningún agente ni proceso puede continuar la ejecución tras la activación de un STOP. La ejecución permanece congelada hasta que el Director emita una resolución explícita.

---

## 10. CHANGE CONTROL & SCOPE INVIOLABILITY

Un GOAL no otorga una autorización arquitectónica general. Los límites del cambio son absolutos:

```text
                                GOAL ≠ AUTORIZACIÓN ARQUITECTÓNICA GENERAL
```

### Prohibiciones Taxativas del GOAL:
* **NO ampliar su propio alcance:** Queda prohibido modificar archivos no listados en `ALLOWED_SCOPE`.
* **NO alterar el Node Contract:** El contrato es inmutable durante la fase de integración.
* **NO crear tablas o entidades especulativas:** Cero tablas "preventivas" o para "fases futuras".
* **NO modificar relaciones existentes:** Prohibido alterar claves foráneas, tipos o nulabilidad fuera de contrato.
* **NO alterar Activos Protegidos:** Prohibido modificar SaaS Foundation v1.0, Pre-Nodo 01 o Context Resolution v1.0 sin una directiva expresa de la Dirección.
* **NO eludir gates de validación:** Prohibido omitir pruebas o pasos de auditoría.

### Protocolo ante Necesidad Imprevista:
```text
Necesidad Técnica Imprevista
             ↓
        STOP INMEDIATO
             ↓
     Captura de Evidencia
             ↓
    Propuesta Estructurada
             ↓
    Decisión del Director
```

---

## 11. VALIDATION & AUDIT BOUNDARY

El proceso de cierre de ejecución garantiza una estricta segregación de funciones:

```text
┌─────────────────────────┐
│   IMPLEMENTER / CODEX   │ ──► Ejecuta cambios y pruebas técnicas locales
└────────────┬────────────┘
             │ Emite Handoff con Evidencia
             ▼
┌─────────────────────────┐
│   VALIDATION PROCESS    │ ──► Verifica suites de pruebas completas (100% PASS)
└────────────┬────────────┘
             │ Superado
             ▼
┌─────────────────────────┐
│       AUDIT AGENT       │ ──► Auditoría independiente de no-regresión, RLS y seguridad
└─────────────────────────┘
```

### Reglas de Frontera:
1. El Implementador puede declarar que su trabajo técnico ha concluido (`VALIDATING`), pero **NUNCA puede declarar por sí mismo que el nodo está `CLOSED` ni que la auditoría está aprobada**.
2. El Implementador debe entregar evidencia física completa y reproducible (comandos de prueba, scripts de testing, logs limpios).
3. La auditoría debe ser ejecutada de manera independiente, evaluando activamente posibles regresiones en activos protegidos y verificando el aislamiento tenant.

---

## 12. CLOSURE BOUNDARY & FORMULA

El protocolo establece dos axiomas fundamentales de no-equivalencia:

$$\text{GOAL COMPLETED} \neq \text{NODE CLOSED}$$
$$\text{AUDIT PASS} \neq \text{DIRECTOR APPROVAL}$$

### Fórmula Canónica de Cierre (`CLOSED`):

$$\begin{aligned}
\text{Cierre Formal del Nodo} = &\quad \text{AUDIT PASS (100\% pruebas y seguridad)} \\
&+ \text{ZERO OPEN STOPS (Cero bloqueos pendientes)} \\
&+ \text{CLOSURE CRITERIA SATISFIED (Criterios del Node Contract cumplidos)} \\
&+ \text{DIRECTOR APPROVAL (Resolución expresa del Director)}
\end{aligned}$$

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                            CONDICIONES DE CIERRE                            │
│                                                                             │
│   [✓] 100% Pruebas de Validación y Regresión Pasadas                        │
│   [✓] Auditoría de Seguridad, RLS y Aislamiento Multi-Tenant Certificada   │
│   [✓] Cero STOPs Abiertos                                                  │
│   [✓] Criterios de Aceptación del Node Contract Verificados                 │
│   [✓] APROBACIÓN EXPLÍCITA DEL DIRECTOR                                     │
│                                                                             │
│                                     ▼                                       │
│                             ESTADO: CLOSED 🟢                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 13. ENGINEERING ECONOMY (ANTI-BLOAT PROTOCOL)

NCP exige máxima eficiencia operativa y rigor contra el desperdicio técnico:

1. **`NO FUTURE WORK`:** Prohibido codificar hooks, interfaces, endpoints o entidades pensando en necesidades de nodos futuros.
2. **`NO SPECULATIVE RESEARCH`:** Prohibido auditar o explorar componentes del código fuente que no formen parte de la pregunta específica del GOAL.
3. **`NO COSMETIC REFACTORS`:** Prohibido reformatear, reestructurar o renombrar código existente que no requiera modificación funcional directa.
4. **`NO SPECULATIVE ENTITIES`:** Si un nodo no requiere cambios en base de datos, se declara formalmente `NEW_TABLES = 0`, `NEW_COLUMNS = 0`.
5. **`NO SPECULATIVE AGENTS`:** No instanciar ni simular agentes para tareas que pueden ser resueltas por NCP Core o por el agente primario asignado.
6. **`ZERO INFRASTRUCTURE DUPLICATION`:** Reutilizar estrictamente los servicios, middlewares y utilidades ya probados y cerrados.

---

## 14. COMPATIBILITY MATRIX WITH PROTECTED ASSETS

| Activo Protegido | Estado Actual | Regla de Compatibilidad en GOAL Execution |
| :--- | :--- | :--- |
| **SaaS Foundation v1.0** | `CLOSED 🟢` | Inmutable. Ningún GOAL puede alterar `tenants`, `organizations`, `establishments`, `memberships`, `usuarios` ni migración `065`. |
| **Pre-Nodo 01** | `CLOSED 🟢` | Inmutable. Ningún GOAL puede alterar tablas ni contratos base de identidad previos. |
| **Context Resolution v1.0** | `IMPLEMENTED 🟢` / `VALIDATED 🟢` | Inmutable. `fn_resolve_user_tenant`, migración `066` y servicios de resolución de contexto permanecen intactos. |
| **NCP Core Contract v1.0** | `DEFINED 🟢` | Inmutable. Define la especificación maestra y jerarquía de autoridad que este protocolo ejecuta. |

---

## 15. DOCUMENTATION DIRECTORY STRUCTURE CONSTRAINTS

De conformidad con las directivas de la Dirección, este protocolo reside exclusivamente en:

```text
/ncp/NCP-GOAL-EXECUTION-PROTOCOL-v1.0.md
```

Queda expresamente prohibida la creación anticipada de directorios o subdirectorios físicos tales como:
* `/ncp/agents/`
* `/ncp/state/`
* `/ncp/protocols/`
* `/ncp/goals/`
* `/ncp/contracts/`
* `/ncp/audits/`

Cualquier estructuración física de directorios se ejecutará únicamente bajo autorización y GOAL específico emitido por el Director.
