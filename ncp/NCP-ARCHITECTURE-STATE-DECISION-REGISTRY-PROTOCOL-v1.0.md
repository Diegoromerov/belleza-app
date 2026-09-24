# NCP ARCHITECTURE STATE & DECISION REGISTRY PROTOCOL v1.0
## Node Construction Protocol — Architectural State & Decision Traceability Specification

**Versión:** 1.0.0  
**Estado:** DEFINED / READY FOR DIRECTOR APPROVAL  
**Fase Metodológica:** DEFINIR  
**Ámbito:** Modelo Conceptual de Estado Arquitectónico y Trazabilidad de Decisiones para GlowApp SaaS  
**Autoridad Raíz:** Director del Proyecto GlowApp SaaS  
**Documentos Base:**  
* [`/ncp/NCP-CORE-CONTRACT-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NCP-CORE-CONTRACT-v1.0.md)  
* [`/ncp/NCP-GOAL-EXECUTION-PROTOCOL-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NCP-GOAL-EXECUTION-PROTOCOL-v1.0.md)

---

## 1. IDENTITY & PURPOSE

### Identidad
* **Nombre Oficial:** NCP Architecture State & Decision Registry Protocol.
* **Versión:** 1.0.0.
* **Naturaleza:** Protocolo conceptual, lógico y normativo para el modelado, consulta, verificación y trazabilidad del estado arquitectónico de GlowApp SaaS y sus decisiones vinculantes.
* **Declaración Negativa (Qué NO es este protocolo en esta fase):**
  * NO es una base de datos física (`NEW_TABLES = 0`, `NEW_COLUMNS = 0`).
  * NO es una API, microservicio ni endpoint backend (`NEW_APIS = 0`, `NEW_SERVICES = 0`).
  * NO es un registro autónomo en el filesystem ni una herramienta CLI (`NEW_EXECUTABLES = 0`).
  * NO es una automatización desatendida.

### Pregunta Operativa Central
Este protocolo resuelve de manera unívoca y determinista:
> **¿Cómo sabe NCP qué decisiones arquitectónicas están formalmente aprobadas, qué nodos están cerrados, cuál es el único nodo activo, qué contrato está vigente, qué activos están protegidos, qué STOPs permanecen abiertos y cuál es la siguiente acción permitida del sistema?**

---

## 2. CANONICAL AUTHORITY HIERARCHY

Este protocolo se encuentra estrictamente subordinado a la jerarquía de autoridad canónica e inmutable:

```text
1. DIRECTOR — AUTHORITY ROOT
2. APPROVED ARCHITECTURAL DECISIONS (ARCH-*)
3. APPROVED NODE CONTRACT
4. SOUL + GOVERNANCE (Policy Layer)
5. EXISTING CLOSED ARCHITECTURE (Protected Assets)
6. PHYSICAL CODE AS EVIDENCE
7. AGENT / CODEX PROPOSALS
```

### Principios de Autoridad:
1. **Director como Authority Root:** La validez de cualquier estado o decisión emana exclusivamente de la aprobación del Director.
2. **NCP Core como Consumidor/Orquestador:** NCP Core consulta y valida el estado arquitectónico para evaluar precondiciones y gates; **NO es el propietario de la verdad arquitectónica ni puede autoaprobar estados**.
3. **Inmutabilidad del Registro:** Ningún agente ni proceso automático puede alterar, sobrescribir o dar por aprobada una decisión sin un acto formal del Director.

---

## 3. NATURE OF STATE & EPISTEMOLOGICAL SEPARATION

Para garantizar la integridad y evitar alucinaciones operativas, el protocolo establece una separación ontológica estricta entre tres dimensiones del conocimiento:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. FACTUAL STATE (Estado Fáctico)                                           │
│ Realidad empírica demostrada mediante evidencia física directa: esquemas de │
│ PostgreSQL, migraciones aplicadas, AST de código, endpoints y tests reales.  │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ se valida contra
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 2. DECLARED STATE (Estado Declarado)                                        │
│ Realidad formal emanada de la autoridad: Decisiones ARCH-* aprobadas,      │
│ Node Contracts vigentes y resoluciones expresas de cierre del Director.     │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ se aísla de
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 3. INFERRED STATE (Estado Inferido)                                         │
│ Hipótesis, conjeturas, deducciones o extrapolaciones hechas por un agente.  │
│ Queda TERMINANTEMENTE PROHIBIDO tratar una inferencia como estado confirmado│
└─────────────────────────────────────────────────────────────────────────────┘
```

> [!CAUTION]
> **Axioma Epistemológico Fundamental:** NCP **NUNCA** puede tratar una inferencia como estado arquitectónico confirmado. Todo estado debe ser fáctico (probado con evidencia) o declarado (aprobado por el Director).

---

## 4. ARCHITECTURE STATE MODEL

El `ArchitectureState` es el modelo lógico conceptual mínimo y suficiente que NCP requiere para gobernar el avance evolutivo del SaaS:

```text
ArchitectureState {
    FOUNDATION_VERSION      : String ("v1.0")
    ACTIVE_BRANCH           : String ("database_audit_read_only")
    LAST_APPLIED_MIGRATION  : String ("066_context_resolution_tenant_resolver.sql")
    CLOSED_NODES            : Array<NodeID> ["PRE-NODE-01", "SAAS-FOUNDATION-v1.0", "CONTEXT-RESOLUTION-v1.0"]
    CURRENT_ACTIVE_NODE     : NodeID | NULL ("NCP-CORE-v1.0" [ILUSTRATIVO])
    CURRENT_NODE_STATE      : Enum (DEFINED | CONTRACT_APPROVED | IMPLEMENTING | VALIDATING | AUDITING | etc.)
    ACTIVE_NODE_CONTRACT    : ContractRef ("ncp/NCP-CORE-CONTRACT-v1.0.md")
    PROTECTED_ASSETS        : Array<AssetRef> [Catálogo de Activos Protegidos]
    ACTIVE_STOPS            : Array<StopRecord> [Colección de STOPs abiertos]
    NEXT_ALLOWED_ACTION     : String (Salida determinista del estado confirmado)
}
```

---

## 5. CLOSED NODES PROTOCOL

Un nodo figura en `CLOSED_NODES` **únicamente** cuando se ha satisfecho la totalidad de las siguientes condiciones deterministas:

$$\begin{aligned}
\text{Condición CLOSED} = &\quad \text{Node Contract Aprobado por Director} \\
&+ \text{Implementación Física Completada dentro del Scope} \\
&+ \text{Validación Funcional Superada (100\% Tests)} \\
&+ \text{Auditoría Independiente de Seguridad y RLS Superada} \\
&+ \text{Cero STOPs Abiertos en el Nodo} \\
&+ \text{Criterios de Cierre del Contrato Satisfechos} \\
&+ \text{Aprobación Explícita y Vinculante del Director}
\end{aligned}$$

### Reglas de Cierre:
* Un agente **NUNCA** puede declarar unilateralmente un nodo como `CLOSED`.
* Un GOAL en estado `COMPLETED` **NO** convierte automáticamente al nodo en `CLOSED`.
* Un nodo en estado `CLOSED` se convierte inmediatamente en un **PROTECTED ASSET** inmutable.

---

## 6. ACTIVE NODE GOVERNANCE (ONE NODE AT A TIME)

El atributo `CURRENT_ACTIVE_NODE` es la referencia lógica al **único nodo** que se encuentra en proceso activo de diseño o implementación.

### Reglas de Concurrencia de Nodos:
* **0 Nodos Activos:** Válido (Estado de reposo, auditoría global o espera de directivas).
* **1 Nodo Activo:** Válido (Ejecución determinista estándar bajo NCP).
* **> 1 Nodos Activos:** **VIOLACIÓN CRÍTICA $\rightarrow$ `ARCHITECTURAL_STOP` instantáneo.**

> [!IMPORTANT]
> Se prohíbe terminantemente la ejecución en paralelo de múltiples nodos o la exploración cruzada entre dominios. La evolución procede **nodo por nodo de forma estrictamente secuencial**.

---

## 7. ACTIVE NODE CONTRACT REFERENCE

El atributo `ACTIVE_NODE_CONTRACT` identifica el contrato formal que gobierna el nodo activo:

### Invariantes del Contrato Activo:
1. **Existencia Fisiológica:** El archivo markdown del Node Contract debe existir físicamente en el repositorio.
2. **Aprobación Previa:** Debe encontrarse en estado `CONTRACT_APPROVED` por el Director antes de iniciar cualquier implementación en código.
3. **Versión Canónica:** Debe ser la versión exacta aprobada; cualquier modificación requiere un nuevo ciclo de revisión.
4. **Prohibición de Edición Silenciosa:** Queda prohibido modificar el contrato durante la fase de implementación.
5. **Divergencia de Estado:** Si existe discrepancia entre el estado pretendido por un agente y el texto del Node Contract, se dispara de inmediato un **`CONTRACT_STOP`**.

---

## 8. DECISION REGISTRY SPECIFICATION

El `DecisionRegistry` es el modelo conceptual de trazabilidad que registra las decisiones arquitectónicas fundamentales (`ARCH-*`) emitidas o aprobadas por el Director:

```text
ArchitectureDecisionRecord {
    DECISION_ID                 : String (Identificador único, ej. "ARCH-CR-001", "ARCH-CR-002")
    TITLE                       : String (Título descriptivo de la decisión)
    DECISION_SUMMARY            : String (Resumen claro y conciso de la solución aprobada)
    RATIONALE                   : String (Justificación técnica, motivos de seguridad y contexto)
    AUTHORITY                   : "DIRECTOR" (Autoridad raíz que aprobó la decisión)
    SCOPE                       : Array<NodeID> (Nodos a los que aplica la decisión)
    AFFECTED_ENTITIES           : Array<String> (Tablas, funciones, rutas o módulos impactados)
    PROHIBITED_INTERPRETATIONS  : Array<String> (Límites negativos e interpretaciones vedadas)
    STATUS                      : Enum ("APPROVED" | "DEPRECATED" | "SUPERSEDED")
    DEPENDENCIES                : Array<DecisionID> (Decisiones previas requeridas)
    DATE_APPROVED               : ISO8601Timestamp (Fecha formal de aprobación)
}
```

### Catálogo de Decisiones Reales Aprobadas en el Proyecto:
* **`ARCH-CR-001`:** Aprobación de función controlada `SECURITY DEFINER` (`fn_resolve_user_tenant`) para resolver server-side `identity_id → tenant_id` bajo runtime no privilegiado (`beauty_app_user`), mitigando la dependencia circular con RLS de Foundation.
* **`ARCH-CR-002`:** Persistencia formal y versionada del resolver mediante la migración `backend/migrations/066_context_resolution_tenant_resolver.sql`, revocando permisos a `PUBLIC` y otorgando `EXECUTE` exclusivo a `beauty_app_user`.

> [!NOTE]
> Este registro modela la historia viva y canónica de la arquitectura. Queda prohibido inventar decisiones no aprobadas o suprimir decisiones históricas.

---

## 9. DECISION LIFECYCLE & STATUS

El ciclo de vida de una decisión arquitectónica es determinista y sólo puede ser alterado por el Director:

```text
┌──────────────┐     ┌──────────────┐
│   APPROVED   ├────►│  SUPERSEDED  │ (Reemplazada por nueva decisión explícita)
└──────┬───────┘     └──────────────┘
       │
       ▼
┌──────────────┐
│  DEPRECATED  │ (Retirada formalmente sin reemplazo vigente)
└──────────────┘
```

### Definición de Estados:
* **`APPROVED`:** Decisión formalmente aprobada, vigente, obligatoria y vinculante para todos los agentes.
* **`SUPERSEDED`:** Decisión histórica que ha sido formalmente reemplazada por una decisión posterior (`ARCH-*`). **Una decisión superseded no puede ser utilizada como autoridad vigente bajo ninguna circunstancia.**
* **`DEPRECATED`:** Decisión retirada de forma explícita por la Dirección sin reemplazo directo.

### Inmutabilidad y Modificación:
* Queda terminantemente prohibido editar o reescribir silenciosamente una decisión `ARCH-*`.
* Toda modificación exige la emisión de un **`ARCHITECTURAL_STOP`** y la consecuente aprobación de una **nueva decisión** que marque a la anterior como `SUPERSEDED`, preservando la trazabilidad histórica completa.

---

## 10. PROTECTED ASSETS INTEGRATION

El `ArchitectureState` consume el catálogo oficial de **Activos Protegidos** establecido en el NCP Core Contract:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                        CATÁLOGO DE ACTIVOS PROTEGIDOS                       │
│                                                                             │
│  1. SaaS Foundation v1.0 (Tablas, Composites FKs, RLS, Migración 065)       │
│  2. Pre-Nodo 01 (Cuentas, Identidades Base, Catálogo Previo)                │
│  3. Context Resolution v1.0 (fn_resolve_user_tenant, Migración 066, Serv.)  │
│  4. SOUL Design Tokens (frontend/lib/core/theme/tokens.dart)                │
│  5. Todos los Nodos en Estado CLOSED                                        │
└─────────────────────────────────────────────────────────────────────────────┘
```

> [!CAUTION]
> Cualquier intento no autorizado de alteración, eliminación o sobreescritura de un Activo Protegido dispara de forma inmediata e incondicional un **`SCOPE_STOP`** o **`SECURITY_STOP`**.

---

## 11. ACTIVE STOPS REGISTRY

El atributo `ACTIVE_STOPS` mantiene la colección lógica de bloqueos no resueltos que condicionan o impiden la continuación del trabajo:

```text
StopRecord {
    STOP_ID           : String (Identificador único, ej. "STOP-CR-001")
    STOP_TYPE         : Enum ("ARCHITECTURAL_STOP" | "SECURITY_STOP" | "SCOPE_STOP" | 
                              "DATA_STOP" | "DEPENDENCY_STOP" | "CONTRACT_STOP" | "VALIDATION_FAILED")
    NODE_ID           : NodeID (Nodo bloqueado)
    GOAL_ID           : String (GOAL durante el cual se produjo)
    AGENT             : Enum ("EVIDENCE" | "ARCHITECT" | "IMPLEMENTER" | "AUDIT" | "NCP_CORE")
    PROBLEM           : String (Descripción concisa del bloqueo)
    EVIDENCE          : String (Prueba física verificable)
    IMPACT            : String (Consecuencia en arquitectura o seguridad)
    RECOMMENDATION    : String (Propuesta técnica del agente)
    DECISION_REQUIRED : String (Pregunta explícita formulada al Director)
    STATUS            : Enum ("OPEN" | "RESOLVED" | "REJECTED")
}
```

### Invariantes de STOPs:
1. **Persistencia Obligatoria:** Un STOP permanece en estado `OPEN` hasta que exista una resolución formal del Director.
2. **Prohibición de Desaparición Silenciosa:** Un STOP nunca se elimina ni se ignora simplemente porque el agente continúe con otra instrucción.
3. **Bloqueo Preventivo:** Si existe un STOP abierto bloqueante en el nodo objetivo, el Pre-Execution Gate deniega el despacho (**`NO EXECUTE`**).

---

## 12. NEXT ALLOWED ACTION DETERMINATION

El campo `NEXT_ALLOWED_ACTION` es una **salida lógica determinista** derivada exclusivamente del cruce del estado fáctico y declarado:

```text
┌────────────────────────────────────────────────────┬──────────────────────────────────────┐
│ Condición del Estado Confirmado                    │ NEXT_ALLOWED_ACTION Resultante       │
├────────────────────────────────────────────────────┼──────────────────────────────────────┤
│ Hay un STOP abierto que requiere decisión          │ STOP / WAIT_FOR_DIRECTOR_DECISION    │
│ Nodo en roadmap sin contrato                       │ CREATE_NODE_CONTRACT                 │
│ Node Contract redactado esperando aprobación       │ WAIT_FOR_DIRECTOR_APPROVAL           │
│ Node Contract aprobado sin GOAL de integración     │ ISSUE_INTEGRATION_GOAL               │
│ GOAL emitido pendiente de evaluación de pre-checks │ RUN_PRECHECK                         │
│ Pre-checks superados                               │ DISPATCH_TO_ASSIGNED_AGENT           │
│ Implementación finalizada con tests locales OK     │ RUN_VALIDATION_SUITE                 │
│ Validación superada pendiente de auditoría         │ DISPATCH_AUDIT_AGENT                 │
│ Auditoría superada al 100% con cero STOPs          │ CLOSE_PENDING_DIRECTOR_APPROVAL      │
│ Aprobación explícita del Director otorgada         │ MARK_NODE_CLOSED_AND_FREEZE          │
└────────────────────────────────────────────────────┴──────────────────────────────────────┘
```

> [!IMPORTANT]
> `NEXT_ALLOWED_ACTION` **NO** autoriza por sí mismo una acción arquitectónica. Es una conclusión derivada del estado para orientar el flujo, no una fuente de autoridad.

---

## 13. STATE CONSISTENCY RULES (LAS 10 INVARIANTES)

El sistema debe satisfacer simultáneamente las 10 invariantes de consistencia:

1. **`CLOSED_NODE_CONTRACT_REQUIRED`:** Todo nodo marcado como `CLOSED` debe tener un Node Contract aprobado físicamente en repositorio.
2. **`ACTIVE_NODE_CONTRACT_REQUIRED`:** Todo nodo marcado como activo en implementación debe tener un Node Contract en estado `CONTRACT_APPROVED`.
3. **`GOAL_NODE_ALIGNMENT`:** Todo GOAL en ejecución debe pertenecer estrictamente al `CURRENT_ACTIVE_NODE`.
4. **`SINGLE_ACTIVE_NODE_INVARIANT`:** La existencia de más de un nodo activo en implementación dispara automáticamente un `ARCHITECTURAL_STOP`.
5. **`BLOCKING_STOP_PREVENTS_EXECUTION`:** Ninguna ejecución de código puede iniciarse si existe un STOP abierto en el nodo.
6. **`GOAL_COMPLETED_IS_NOT_NODE_CLOSED`:** La conclusión de una tarea operativa no equivale al cierre arquitectónico del nodo.
7. **`AUDIT_PASS_IS_NOT_DIRECTOR_APPROVAL`:** La aprobación técnica de auditoría no reemplaza la firma formal del Director.
8. **`PROPOSAL_IS_NOT_DECISION`:** Las sugerencias de agentes no constituyen decisiones vigentes sin aprobación explícita.
9. **`PHYSICAL_CODE_IS_NOT_AUTHORITY`:** La preexistencia de código no valida una arquitectura no aprobada.
10. **`INFERENCE_IS_NOT_STATE`:** Ninguna suposición no respaldada por evidencia o decreto del Director puede formar parte del estado confirmado.

---

## 14. SOURCE OF TRUTH & AUTHORITY VS EVIDENCE

Para dirimir discrepancias, se aplica la jerarquía formal distinguiendo con rigor entre **Autoridad** y **Evidencia**:

```text
                                  ORDEN DE PRECEDENCIA FORMAL:
                               1. DIRECTOR (Authority Root)
                                            ↓
                           2. APPROVED DECISIONS (ARCH-*)
                                            ↓
                              3. APPROVED NODE CONTRACT
                                            ↓
                            4. SOUL + GOVERNANCE (Policy)
                                            ↓
                            5. CLOSED SAAS ARCHITECTURE
                                            ↓
                            6. PHYSICAL CODE AS EVIDENCE
                                            ↓
                              7. AGENT / CODEX PROPOSALS
```

### Distinción Vital:
* **AUTORIDAD:** Define qué está legalmente permitido, qué requisitos deben cumplirse y cómo debe comportarse el sistema.
* **EVIDENCIA:** Demuestra qué existe físicamente en el entorno de ejecución (tablas, funciones, archivos, logs).
* **Principio:** El código físico puede evidenciar un error o un estado previo, pero **nunca tiene autoridad para consagrar una violación arquitectónica por encima de un contrato o decisión aprobada**.

---

## 15. RECONCILIATION PROTOCOL (NO SILENT RECONCILIATION)

Cuando NCP detecta discrepancias estructurales entre diferentes fuentes:

$$\text{DOCUMENT} \neq \text{DATABASE} \quad\lor\quad \text{DATABASE} \neq \text{CODE} \quad\lor\quad \text{CODE} \neq \text{CONTRACT} \quad\lor\quad \text{STATE} \neq \text{EVIDENCE}$$

### Regla Fundamental:
> **`NO SILENT RECONCILIATION`:** Queda terminantemente prohibido "arreglar" silenciosamente el código, la base de datos o los documentos para que coincidan sin reporte previo.

### Procedimiento Obligatorio de Reconciliación:
```text
1. CAPTURA DE EVIDENCIA   : Ejecutar queries o inspección física de archivos.
2. FORMULACIÓN DE FINDING : Identificar la discrepancia exacta entre la Autoridad y la Evidencia.
3. EVALUACIÓN DE IMPACTO  : Determinar riesgo en Foundation, seguridad, RLS o datos.
4. EMISIÓN DE STOP        : Disparar ARCHITECTURAL_STOP o CONTRACT_STOP según corresponda.
5. DECISIÓN DEL DIRECTOR  : Esperar resolución formal antes de ejecutar cualquier sincronización.
```

---

## 16. RELATIONSHIP WITH NCP CORE & GOAL PROTOCOL

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                            ARCHITECTURE STATE                               │
│                   (Modelo Conceptual de Estado Canónico)                    │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ alimenta
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            GOAL PRE-EXECUTION                               │
│              (Evaluación de los 12 checks del Pre-Execution Gate)           │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ autoriza
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              GOAL EXECUTION                                 │
│             (Ejecución acotada por Implementer / Codex / Evidence)          │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ emite
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                             HANDOFF PACKAGE                                 │
│                    (Evidencia física + Hechos comprobados)                  │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ actualiza
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        REEVALUACIÓN DETERMINISTA                            │
│                 (Recálculo de NEXT_ALLOWED_ACTION / Gates)                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

> [!IMPORTANT]
> La actualización del estado (`STATE UPDATE`) tras un Handoff **NO constituye una aprobación arquitectónica automática**. Cualquier transición hacia `CLOSED` o resolución de un STOP permanece congelada hasta la intervención expresa del Director.

---

## 17. ENGINEERING ECONOMY & ZERO PHYSICAL OVERHEAD

Para garantizar que NCP no genere sobrecarga innecesaria ni burocracia técnica desmedida:

* **Cero Infraestructura Física:** Prohibido crear tablas, bases de datos auxiliares, dashboards, servicios de sincronización o agentes autónomos en esta fase.
* **Reutilización Canónica:** El estado y las decisiones se modelan y consumen a través de especificaciones documentales y consultas directas de solo lectura.
* **Prohibición de Trabajo Especulativo:** Prohibido redactar decisiones hipotéticas para nodos futuros (`NO FUTURE WORK`).
* **Enfoque Fáctico:** La verificación del estado siempre se sustenta en evidencia física verificable (`EVIDENCE FIRST`).

---

## 18. DOCUMENTATION LOCATION

Este protocolo se formaliza exclusivamente en el archivo canónico:

```text
/ncp/NCP-ARCHITECTURE-STATE-DECISION-REGISTRY-PROTOCOL-v1.0.md
```

Queda estrictamente prohibida la creación de archivos complementarios, submódulos o directorios físicos no autorizados.
