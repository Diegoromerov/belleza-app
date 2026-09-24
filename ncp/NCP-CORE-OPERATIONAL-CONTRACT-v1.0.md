# NCP CORE OPERATIONAL CONTRACT v1.0
## Node Construction Protocol — Core Orchestrator Operational Specification

**Versión:** 1.0.0  
**Estado:** DEFINED / READY FOR DIRECTOR APPROVAL  
**Fase Metodológica:** DEFINIR  
**Ámbito:** Contrato Operativo Maestro para el Motor Orquestador y de Gobernanza de NCP  
**Autoridad Raíz:** Director del Proyecto GlowApp SaaS  
**Documentos Base Inmutables:**  
* [`/ncp/NCP-CORE-CONTRACT-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NCP-CORE-CONTRACT-v1.0.md)  
* [`/ncp/NCP-GOAL-EXECUTION-PROTOCOL-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NCP-GOAL-EXECUTION-PROTOCOL-v1.0.md)  
* [`/ncp/NCP-ARCHITECTURE-STATE-DECISION-REGISTRY-PROTOCOL-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NCP-ARCHITECTURE-STATE-DECISION-REGISTRY-PROTOCOL-v1.0.md)

---

## 1. IDENTITY & NATURE OF NCP CORE

### Identidad
* **Nombre Oficial:** NCP Core (Node Construction Protocol Core Orchestrator).
* **Versión:** 1.0.0.
* **Naturaleza:** Motor de orquestación, verificación documental, control de calidad y aplicación de políticas de gobernanza metodológica.

### Declaración Positiva (Qué ES NCP Core):
* Es el **coordinador operativo** del ciclo de vida de los nodos SaaS.
* Es el **evaluador determinista de precondiciones y gates** pre-ejecución, validación y auditoría.
* Es el **enrutador de despacho** que selecciona el agente idóneo según la naturaleza de la instrucción.
* Es el **receptor y clasificador de Handoff Packages**.
* Es el **detector temprano de violaciones, excepciones y STOPs**.

### Declaración Negativa (Qué NO ES NCP Core):
```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                           QUÉ NO ES NCP CORE                                │
├─────────────────────────────────────────────────────────────────────────────┤
│ ❌ NO ES AUTORIDAD ARQUITECTÓNICA (El Director es la única Authority Root)  │
│ ❌ NO ES PARTE DEL RUNTIME DE GLOWAPP (Cero acoplamiento a Express/Flutter) │
│ ❌ NO ES UN AGENTE CONVERSACIONAL B2C (No es atenaAgent ni chronosAgent)    │
│ ❌ NO ES LÓGICA DE NEGOCIO (No gestiona reservas, pagos ni catálogos)       │
│ ❌ NO ES AUTORIDAD DE BASE DE DATOS (No ejecuta DDL ni migraciones directas)│
│ ❌ NO ES UN ARQUITECTO AUTÓNOMO (No autoaprueba decisiones ni contratos)    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. CANONICAL AUTHORITY HIERARCHY

NCP Core opera bajo la subordinación estricta y vertical a la jerarquía de 7 niveles:

```text
1. DIRECTOR — AUTHORITY ROOT
2. APPROVED ARCHITECTURAL DECISIONS (ARCH-*)
3. APPROVED NODE CONTRACT
4. SOUL + GOVERNANCE (Policy Layer)
5. EXISTING CLOSED ARCHITECTURE (Protected Assets)
6. PHYSICAL CODE AS EVIDENCE
7. AGENT / CODEX PROPOSALS
```

### Reglas de Autoridad en NCP Core:
1. **Director como Única Authority Root:** Toda decisión arquitectónica, aprobación de Node Contract, resolución de STOP y declaración de estado `CLOSED` proviene exclusivamente del Director.
2. **Prohibición de Autoaprobación:** NCP Core **NUNCA** puede aprobar sus propias propuestas, ni emitir resoluciones vinculantes sin la aprobación explícita del Director.
3. **Inviolabilidad de Contratos:** NCP Core no puede reinterpretar, omitir ni flexibilizar los requisitos establecidos en un Node Contract aprobado.

---

## 3. INPUT CONTRACT (ENTRADAS DE NCP CORE)

Para procesar cualquier instrucción operativa, NCP Core consume un conjunto estricto y tipificado de entradas:

```text
┌──────────────────────────────┬──────────────────┬────────────────────────────────────────────────────────┐
│ Input                        │ Naturaleza       │ Descripción                                            │
├──────────────────────────────┼──────────────────┼────────────────────────────────────────────────────────┤
│ `GOAL`                       │ REQUIRED INPUT   │ Contrato de ejecución emitido por el Director.         │
│ `NODE_ID`                    │ REQUIRED INPUT   │ Identificador unívoco del nodo objetivo.               │
│ `NODE_CONTRACT`              │ REQUIRED INPUT   │ Contrato formal del nodo objetivo en repositorio.      │
│ `ARCHITECTURE_STATE`         │ REQUIRED INPUT   │ Modelo conceptual del estado arquitectónico actual.    │
│ `DECISION_RECORDS`           │ REQUIRED INPUT   │ Registro de decisiones `ARCH-*` aprobadas y vigentes.  │
│ `PROTECTED_ASSETS`           │ REQUIRED INPUT   │ Catálogo canónico de activos protegidos inmutables.    │
│ `SOUL_GOVERNANCE_REFS`       │ REQUIRED INPUT   │ Políticas transversales de seguridad y zero-trace.     │
│ `PRECONDITIONS`              │ REQUIRED INPUT   │ Requisitos técnicos y de entorno indispensables.       │
│ `DEPENDENCIES`               │ REQUIRED INPUT   │ Nodos y decisiones previas requeridas.                 │
│ `PHYSICAL_EVIDENCE_INPUT`    │ OPTIONAL INPUT   │ Traza, logs o dumps previos adjuntos al GOAL.         │
└──────────────────────────────┴──────────────────┴────────────────────────────────────────────────────────┘
```

---

## 4. OUTPUT CONTRACT (SALIDAS DE NCP CORE)

NCP Core emite exclusivamente las siguientes salidas tipificadas:

```text
┌──────────────────────────────┬───────────────────────────────────────────────────────────────────────────┐
│ Output                       │ Descripción y Significado Operativo                                       │
├──────────────────────────────┼───────────────────────────────────────────────────────────────────────────┤
│ `PRECHECK_RESULT`            │ Resultado booleano y detallado del Pre-Execution Gate (12 checks).        │
│ `DISPATCH_INSTRUCTION`       │ Paquete de despacho dirigido al agente asignado con scope explícito.      │
│ `HANDOFF_ACCEPTANCE`         │ Dictamen de conformidad tras recibir un Handoff Package estructurado.     │
│ `STATE_TRANSITION`           │ Propuesta/aplicación de transición operativa según la máquina de estados. │
│ `STOP_RECORD`                │ Reporte estructurado de detención formal ante anomalías o bloqueos.       │
│ `VALIDATION_GATE_RESULT`     │ Certificación del paso de la suite completa de pruebas funcionales.       │
│ `AUDIT_GATE_RESULT`          │ Dictamen de auditoría independiente de seguridad, RLS y no-regresión.    │
│ `CLOSURE_RECOMMENDATION`     │ Paquete final presentado al Director para solicitar el cierre formal.     │
│ `DIRECTOR_DECISION_REQUEST`  │ Formulación de solicitud de resolución ante un ARCHITECTURAL STOP.        │
└──────────────────────────────┴───────────────────────────────────────────────────────────────────────────┘
```

> [!CAUTION]
> **Axiomas de No-Equivalencia en Salidas:**
> $$\text{CLOSURE\_RECOMMENDATION} \neq \text{CLOSED}$$
> $$\text{DIRECTOR\_DECISION\_REQUEST} \neq \text{DIRECTOR\_DECISION}$$
> Una recomendación o solicitud emitida por NCP Core **NO produce efectos vinculantes** hasta que el Director emite su aprobación explícita.

---

## 5. CORE RESPONSIBILITIES (A - I)

NCP Core ejecuta 9 responsabilidades orquestadoras deterministas:

```text
  [A] LOAD       ──► Cargar contexto documental completo (Contratos, Decisiones, Estado).
  [B] VERIFY     ──► Verificar precondiciones, dependencias, alcance y estado fáctico.
  [C] GATE       ──► Evaluar los 12 checks del Pre-Execution Gate y gates de validación/auditoría.
  [D] DISPATCH   ──► Seleccionar y activar únicamente al agente indispensable para la tarea.
  [E] RECEIVE    ──► Recibir, validar e indexar los Handoff Packages estructurados.
  [F] RECONCILE  ──► Comparar evidencia física contra estado declarado (No Silent Reconciliation).
  [G] STOP       ──► Disparar detención inmediata y congelar ejecución ante anomalías.
  [H] TRANSITION ──► Gestionar transiciones operativas permitidas sin fabricar aprobaciones.
  [I] REPORT     ──► Emitir reportes de trazabilidad con separación estricta de hechos y propuestas.
```

---

## 6. DECISION BOUNDARY (MAY VS. MAY NOT)

Para prevenir la usurpación de autoridad arquitectónica, se define una frontera infranqueable:

```text
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ NCP CORE MAY (Operaciones Permitidas)                                                                   │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ ✔ Verificar precondiciones, dependencias y consistencia de datos.                                       │
│ ✔ Comparar evidencia física contra contratos y decisiones aprobadas.                                   │
│ ✔ Clasificar y enrutar solicitudes según las reglas de despacho deterministas.                         │
│ ✔ Despachar tareas acotadas a Evidence, Architect, Implementer o Audit.                                │
│ ✔ Rechazar formalmente un GOAL inválido o incompleto en el Pre-Execution Gate.                         │
│ ✔ Detener la ejecución de forma inmediata emitiendo un STOP tipificado.                                 │
│ ✔ Solicitar evidencia física adicional al Evidence Agent.                                               │
│ ✔ Formular solicitudes estructuradas de decisión (`DIRECTOR_DECISION_REQUEST`) al Director.             │
│ ✔ Preparar y elevar una recomendación de cierre (`CLOSURE_RECOMMENDATION`) al Director.                │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

```text
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ NCP CORE MAY NOT (Operaciones Terminantemente Prohibidas)                                               │
├─────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ ❌ APROBAR arquitectura o validar contratos unilateralmente.                                            │
│ ❌ CREAR o registrar nuevas decisiones `ARCH-*` sin resolución expresa del Director.                    │
│ ❌ MODIFICAR, sobrescribir o interpretar libremente una decisión `ARCH-*` aprobada.                    │
│ ❌ APROBAR o modificar un Node Contract formal.                                                         │
│ ❌ AMPLIAR el alcance (`ALLOWED_SCOPE`) de un GOAL de forma autónoma.                                   │
│ ❌ DECLARAR un nodo en estado `CLOSED`.                                                                 │
│ ❌ MODIFICAR, eliminar o alterar Activos Protegidos (`SaaS Foundation`, `Pre-Nodo 01`, etc.).            │
│ ❌ CREAR tablas, esquemas, columnas o APIs especulativas o no autorizadas.                             │
│ ❌ AUTORIZAR trabajo futuro o refactorizaciones cosméticas no requeridas por el GOAL.                  │
│ ❌ SALTAR, relajar o ignorar gates de validación o auditoría obligatorios.                              │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 7. RELATION WITH ACTORS & AGENTS

NCP Core orquesta la interacción entre participantes bajo estrictas reglas de frontera:

```text
                                    ┌──────────────────────┐
                                    │       DIRECTOR       │ ◄── AUTHORITY ROOT
                                    │   (Emite / Aprueba)  │
                                    └──────────┬───────────┘
                                               │
                                               ▼
                                    ┌──────────────────────┐
                                    │       NCP CORE       │ ◄── ORCHESTRATION ENGINE
                                    │ (Verifica / Despacha)│
                                    └──────────┬───────────┘
                                               │
         ┌─────────────────────────┬───────────┴───────────┬─────────────────────────┐
         ▼                         ▼                       ▼                         ▼
  EVIDENCE AGENT            ARCHITECT AGENT        IMPLEMENTER / CODEX          AUDIT AGENT
(READ / INSPECT)          (ANALYZE / PROPOSE)     (IMPLEMENT / TEST)         (VERIFY / AUDIT)
```

### 1. Relación con el Director (Authority Root)
* El Director es el único emisor de GOALs y resolutor de STOPs.
* Ante un bloqueo, NCP Core emite `DECISION_REQUIRED`; **nunca** emite `DECISION_APPROVED` por sí mismo.
* La transición a `CLOSED` exige la aprobación expresa e intransferible del Director.

### 2. Relación con el Architect Agent
* Despacho: Cuando se requiere modelar contratos, analizar dependencias o formular alternativas para un `ARCHITECTURAL_STOP`.
* Mandato: `ANALYZE / RELATE / PROPOSE / STOP`.
* Límite: NCP Core recibe sus propuestas como insumos técnicos no vinculantes, sin convertirlas en decisiones vigentes.

### 3. Relación con el Evidence Agent
* Despacho: Cuando surge una pregunta técnica concreta que requiere comprobación física en BD, logs o código.
* Mandato: `READ / INSPECT / REPORT`.
* Límite: Cero modificaciones físicas. Principio `EVIDENCE FIRST`: no se aceptan afirmaciones sin evidencia tangible.

### 4. Relación con Implementer / Codex
* Despacho: **Únicamente** cuando el Node Contract está en estado `CONTRACT_APPROVED` y el Pre-Execution Gate es `PASS`.
* Mandato: `INSPECT / IMPLEMENT / TEST / REPORT`.
* Límite: Modificaciones estrictamente acotadas al `ALLOWED_SCOPE`. Prohibidas las decisiones arquitectónicas unilaterales; ante cualquier imprevisto, se emite un STOP.

### 5. Relación con el Audit Agent
* Despacho: Cuando el implementador concluye y declara `VALIDATING`.
* Mandato: `VERIFY / TEST / AUDIT / REPORT / STOP` de forma totalmente independiente del implementador.
* Límite: Evalúa seguridad, RLS, no-regresión y cumplimiento de contrato. Un dictamen `AUDIT PASS` habilita `READY_FOR_CLOSURE`, pero **nunca** el estado `CLOSED`.

---

## 8. CANONICAL ORCHESTRATION FLOW

El flujo secuencial orquestado por NCP Core procede según el siguiente diagrama determinista:

```text
  [DIRECTOR] ──► Emite GOAL
                     │
                     ▼
  [NCP CORE] ──► Evalúa Pre-Execution Gate (12 Checks)
                     │
          ┌──────────┴──────────┐
          │ ¿Pre-checks 100% OK?│
          └─────┬─────────┬─────┘
                │ SÍ      │ NO ──► [STOP 🔴] ──► [DIRECTOR] Resuelve
                ▼
  [NCP CORE] ──► Despacha al Agente Específico (Evidence / Architect / Implementer)
                     │
                     ▼
  [AGENTE]   ──► Ejecuta tarea acotada dentro del scope
                     │
                     ▼
  [AGENTE]   ──► Emite Handoff Package con Evidencia Física
                     │
                     ▼
  [NCP CORE] ──► Verifica Handoff y canaliza a Suite de Validación
                     │
          ┌──────────┴──────────┐
          │ ¿Validación PASS?   │
          └─────┬─────────┬─────┘
                │ SÍ      │ NO ──► [VALIDATION_FAILED 🔴] ──► Re-despacho o STOP
                ▼
  [AUDIT AG] ──► Ejecuta Auditoría Independiente (Seguridad, RLS, Regresión)
                     │
          ┌──────────┴──────────┐
          │ ¿Auditoría PASS?    │
          └─────┬─────────┬─────┘
                │ SÍ      │ NO ──► [SECURITY_STOP / CONTRACT_STOP 🔴]
                ▼
  [NCP CORE] ──► Declara estado READY_FOR_CLOSURE
                     │
                     ▼
  [DIRECTOR] ──► Evalúa y otorga Aprobación Formal
                     │
                     ▼
             ESTADO: CLOSED 🟢
```

---

## 9. STATE TRANSITION & CONSUMPTION RULES

### Consumo de ArchitectureState y DecisionRegistry:
1. **Lectura y Consulta Exclusiva:** NCP Core consulta el estado (`ArchitectureState`) y las decisiones (`DecisionRegistry`) para validar precondiciones, detectar STOPs y orientar el flujo.
2. **Prohibición de Registro Físico:** En esta fase, el estado se evalúa a partir de especificaciones documentales y evidencias del repositorio.
3. **Inmutabilidad Histórica:** NCP Core no puede suprimir, sobrescribir ni ignorar decisiones marcadas como `SUPERSEDED` o `DEPRECATED`.

### Distinción de Transiciones:
* **Transición Operativa:** Cambios de estado dentro del ciclo transaccional del GOAL (`ISSUED → PRECHECK → AUTHORIZED → DISPATCHED → IN_PROGRESS → VALIDATION_PENDING → AUDIT_PENDING`). Gestionadas de forma determinista por NCP Core.
* **Aprobación Arquitectónica:** Transiciones a `CONTRACT_APPROVED` o `CLOSED`. Exigen de forma absoluta la resolución vinculante del Director.

---

## 10. PROTECTED ASSETS & SECURITY ENFORCEMENT

NCP Core actúa como el guardián de los Activos Protegidos:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ACTIVOS PROTEGIDOS CANÓNICOS                         │
├─────────────────────────────────────────────────────────────────────────────┤
│ 1. SaaS Foundation v1.0 (Tablas base, Composite FKs, RLS, Migración 065)    │
│ 2. Pre-Nodo 01 (Cuentas, Identidades Base, Catálogo Previo)                 │
│ 3. Context Resolution v1.0 (fn_resolve_user_tenant, Migración 066, Serv.)   │
│ 4. SOUL Design Tokens (frontend/lib/core/theme/tokens.dart)                 │
│ 5. Todos los Nodos Cerrados (CLOSED) Posteriores                            │
└─────────────────────────────────────────────────────────────────────────────┘
```

> [!CAUTION]
> Si durante la evaluación de pre-checks, ejecución o auditoría se detecta una modificación, eliminación o reescritura de un Activo Protegido no autorizada expresamente por el Director, NCP Core dispara de inmediato un **`SCOPE_STOP`** o **`SECURITY_STOP`**, congelando la ejecución.

---

## 11. ECONOMY ENGINE & ANTI-BLOAT PROTOCOL

NCP Core aplica de forma activa los 10 principios de economía de ingeniería:

1. **`NO RESEARCH WITHOUT A QUESTION`:** Cero auditorías sin una pregunta técnica concreta.
2. **`NO CROSS-DOMAIN EXPLORATION`:** Prohibida la interacción con módulos ajenos al nodo activo.
3. **`NO FUTURE WORK`:** Prohibido adelantar código o contratos para fases posteriores.
4. **`NO SPECULATIVE TABLES`:** Prohibida la creación de entidades no requeridas formalmente.
5. **`NO MOCKS AS ARCHITECTURE`:** Las simulaciones o mocks no sustituyen contratos formales.
6. **`NO REFACTOR FOR CLEANLINESS`:** Prohibidos los refactors cosméticos durante tareas funcionales.
7. **`ONE NODE AT A TIME`:** Construcción estrictamente secuencial.
8. **`EVIDENCE FIRST`:** Validación sustentada exclusivamente en hechos empíricos.
9. **`MINIMAL AGENT ACTIVATION`:** Activación del mínimo número de agentes indispensables.
10. **`STOP WHEN THE QUESTION IS ANSWERED`:** Conclusión inmediata al responder la directiva del GOAL.

---

## 12. FAILURE & EXCEPTION MODEL

Respuestas deterministas ante escenarios de falla en NCP Core:

```text
┌──────────────────────────────┬─────────────────────────────┬─────────────────────────────────────────────┐
│ Escenario de Falla           │ Acción Inmediata            │ Estado Resultante                           │
├──────────────────────────────┼─────────────────────────────┼─────────────────────────────────────────────┤
│ GOAL incompleto / inválido   │ Rechazo en Pre-Execution    │ `REJECTED` $\rightarrow$ Retorno a Director │
│ Node Contract no existente   │ Bloqueo Pre-Execution      │ `DEPENDENCY_STOP` 🔴                        │
│ Node Contract no aprobado    │ Bloqueo Pre-Execution      │ `CONTRACT_STOP` 🔴                          │
│ Violación de Scope           │ Aborto de Implementación    │ `SCOPE_STOP` 🔴                             │
│ Falla de Seguridad / RLS     │ Aborto Inmediato            │ `SECURITY_STOP` 🔴                          │
│ Inconsistencia de Datos      │ Aborto Inmediato            │ `DATA_STOP` 🔴                              │
│ Falla en Suite de Pruebas    │ Rechazo de Handoff          │ `VALIDATION_FAILED` 🔴                      │
│ Falla en Auditoría           │ Bloqueo de Cierre           │ `STOP` correspondiente $\rightarrow$ Report │
└──────────────────────────────┴─────────────────────────────┴─────────────────────────────────────────────┘
```

> [!IMPORTANT]
> **Prohibición de Recuperación Silenciosa:** Queda terminantemente prohibido el reintento silencioso, la ampliación automática de scope o la sincronización no reportada ante fallas que involucren impacto arquitectónico o de seguridad.

---

## 13. IDEMPOTENCY & TRACEABILITY

* **Idempotencia Conceptual:** La reevaluación o reejecución de un proceso de NCP Core bajo las mismas entradas debe producir exactamente el mismo resultado determinista, sin generar decisiones duplicadas, estados contradictorios ni re-ejecuciones de GOALs ya completados.
* **Trazabilidad Unívoca:** Toda acción del sistema debe vincular de forma indeleble:
  $$\text{GOAL\_ID} \longleftrightarrow \text{NODE\_ID} \longleftrightarrow \text{CONTRACT} \longleftrightarrow \text{DECISIONS} \longleftrightarrow \text{AGENT} \longleftrightarrow \text{HANDOFF} \longleftrightarrow \text{AUDIT} \longleftrightarrow \text{DIRECTOR}$$

---

## 14. NO RUNTIME COUPLING

NCP Core reside en la capa de gobernanza metodológica del proyecto:
* **Desacoplamiento Absoluto:** NCP Core **NO se ejecuta dentro del ciclo de vida del frontend (Flutter) ni del backend (Express/Node.js)** de GlowApp.
* **Cero Impacto en Producción:** No consume recursos de clientes finales, no interactúa con peticiones HTTP de negocio, ni altera el rendimiento del runtime B2C.
* **Inspección Pasiva:** Su interacción con el código fuente se limita a la inspección estática, ejecución de suites de prueba y auditoría de esquemas.

---

## 15. DOCUMENTATION DIRECTORY LOCATION

Este contrato reside exclusivamente en:

```text
/ncp/NCP-CORE-OPERATIONAL-CONTRACT-v1.0.md
```

Queda prohibida la creación de archivos complementarios, librerías ejecutables o directorios físicos auxiliares (`/ncp/core/`, `/ncp/runtime/`, etc.) en esta fase.
