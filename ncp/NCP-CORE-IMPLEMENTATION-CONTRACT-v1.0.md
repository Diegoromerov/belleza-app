# NCP CORE IMPLEMENTATION CONTRACT v1.0
## Node Construction Protocol — Core Orchestrator Implementation Specification

**Versión:** 1.0.0  
**Estado:** DEFINED / READY FOR DIRECTOR APPROVAL  
**Fase Metodológica:** DEFINIR $\rightarrow$ RELACIONAR $\rightarrow$ VALIDAR  
**Ámbito:** Contrato Técnico de Implementación Ejecutable para los Componentes Físicos de NCP Core  
**Autoridad Raíz:** Director del Proyecto GlowApp SaaS  
**Documentos Base Inmutables de Referencia:**  
1. [`/ncp/NCP-CORE-CONTRACT-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NCP-CORE-CONTRACT-v1.0.md)  
2. [`/ncp/NCP-GOAL-EXECUTION-PROTOCOL-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NCP-GOAL-EXECUTION-PROTOCOL-v1.0.md)  
3. [`/ncp/NCP-ARCHITECTURE-STATE-DECISION-REGISTRY-PROTOCOL-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NCP-ARCHITECTURE-STATE-DECISION-REGISTRY-PROTOCOL-v1.0.md)  
4. [`/ncp/NCP-CORE-OPERATIONAL-CONTRACT-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NCP-CORE-OPERATIONAL-CONTRACT-v1.0.md)  
5. [`/ncp/NCP-CORE-PHYSICAL-ARCHITECTURE-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NCP-CORE-PHYSICAL-ARCHITECTURE-v1.0.md)

---

## 1. IDENTITY & PURPOSE

### Identidad
* **Nombre Oficial:** NCP Core Implementation Contract.
* **Versión:** 1.0.0.
* **Naturaleza:** Especificación formal y vinculante de los requisitos de implementación física, interfaces, contratos de datos, fronteras de seguridad y manejo de errores para el desarrollo de NCP Core.
* **Declaración Negativa:** Este contrato **NO implementa código ejecutable** en esta fase. Es el marco contractual exhaustivo que gobernará la fase posterior de integración física.

### Objetivo
Establecer con precisión determinista cómo se estructurarán, comunicarán y ejecutarán los tres componentes físicos mínimos de NCP Core en el repositorio, garantizando el aislamiento absoluto respecto al runtime de GlowApp y el respeto irrestricto a la jerarquía de autoridad.

---

## 2. CANONICAL AUTHORITY HIERARCHY

Toda futura implementación física de NCP Core estará estrictamente gobernada por la jerarquía canónica:

```text
1. DIRECTOR — AUTHORITY ROOT
2. APPROVED ARCHITECTURAL DECISIONS (ARCH-*)
3. APPROVED NODE CONTRACT
4. SOUL + GOVERNANCE (Policy Layer)
5. EXISTING CLOSED ARCHITECTURE (Protected Assets)
6. PHYSICAL CODE AS EVIDENCE
7. AGENT / CODEX PROPOSALS
```

### Reglas de Autoridad:
1. **Director como Authority Root:** La única entidad facultada para autorizar implementaciones, resolver STOPs, aprobar enmiendas y dictaminar cierres formales (`CLOSED`).
2. **Inmutabilidad de Contratos:** Los componentes de NCP Core no pueden reinterpretar ni flexibilizar los requisitos definidos en este contrato ni en los protocolos base.
3. **NCP Core como Orquestador:** NCP Core es un motor de gobernanza y control; carece de autoridad para autoaprobar cambios arquitectónicos o decisiones.

---

## 3. IMPLEMENTATION SCOPE & CANONICAL LOCATION

### A. Alcance de Componentes Físicos Autorizados:
La implementación física de NCP Core se restringirá exclusivamente a los **tres componentes mínimos aprobados**:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. NCP Core Orchestrator (CLI)                                              │
│ Archivo Canónico: `/ncp/ncp-core.js`                                        │
│ Responsabilidad: Punto de entrada CLI, ciclo de vida del GOAL, evaluación  │
│ de los 12 checks del Pre-Execution Gate, despacho y emisión de STOPs.       │
├─────────────────────────────────────────────────────────────────────────────┤
│ 2. Document & State Reader                                                  │
│ Archivo Canónico: `/ncp/reader.js`                                          │
│ Responsabilidad: Parser determinista de GOALs, Node Contracts, estado       │
│ documental (`ArchitectureState`) y decisiones aprobadas (`ARCH-*`).         │
├─────────────────────────────────────────────────────────────────────────────┤
│ 3. Gate & Verification Engine                                               │
│ Archivo Canónico: `/ncp/verifier.js`                                        │
│ Responsabilidad: Ejecución de suites de prueba Jest, verificación de RLS,   │
│ no-regresión, auditoría de integridad Git y validación de Activos Protegidos│
└─────────────────────────────────────────────────────────────────────────────┘
```

### B. Hogar Canónico:
* Todos los archivos y artefactos de gobierno de NCP residen exclusivamente en `/ncp/`.
* Queda terminantemente prohibido ubicar archivos de NCP Core en `backend/src/`, `backend/scripts/` o `frontend/`.

---

## 4. EXECUTION & OPERATIONAL MODEL

NCP Core operará como una **herramienta de línea de comandos (CLI) de ejecución puntual (One-Shot Execution)**:

```text
                                INVOCACIÓN CLI PUNTUAL
                                          │
                                          ▼
                               ┌──────────────────────┐
                               │  LECTURA DE ENTRADAS │ (GOAL, Contratos, Estado)
                               └──────────┬───────────┘
                                          │
                                          ▼
                               ┌──────────────────────┐
                               │  PRE-EXECUTION GATE  │ (Evaluación de 12 Checks)
                               └──────────┬───────────┘
                                          │
                        ┌─────────────────┴─────────────────┐
                        │ ¿Pasa Pre-Execution Gate?         │
                        └────────┬─────────────────┬────────┘
                                 │ SÍ              │ NO
                                 ▼                 ▼
                        ┌────────────────┐ ┌────────────────┐
                        │   DESPACHO /   │ │    STOP 🔴 /   │
                        │   VALIDACIÓN   │ │    RECHAZO     │
                        └────────┬───────┘ └────────┬───────┘
                                 │                 │
                                 ▼                 ▼
                        ┌───────────────────────────────────┐
                        │   EMISIÓN DE REPORTE Y SALIDA     │
                        └─────────────────┬─────────────────┘
                                          │
                                          ▼
                                FINALIZACIÓN DE PROCESO
```

### Características Obligatorias de Ejecución:
* **`ONE-SHOT`:** Cada comando ejecuta una tarea determinista y termina su proceso.
* **`STATELESS`:** No mantiene procesos en segundo plano, daemons, servidores HTTP ni sockets abiertos.
* **`DETERMINISTIC EXIT CODES`:**
  * `Exit Code 0 (SUCCESS)`: Operación completada exitosamente (Pre-check PASS, Validación PASS, Handoff aceptado).
  * `Exit Code 1 (STOP / BLOCK)`: Detención formal por STOP protocol o precondición insatisfecha.
  * `Exit Code 2 (INVALID_INPUT / ERROR)`: Error de sintaxis en GOAL, archivo inexistente o violación de esquema.

---

## 5. INPUT & OUTPUT DATA CONTRACTS

### A. Contrato de Entradas (Inputs):
```text
┌───────────────────────────┬──────────────┬────────────────────────────────────────────────────────┐
│ Parámetro de Entrada      │ Tipificación │ Descripción / Formato Requerido                        │
├───────────────────────────┼──────────────┼────────────────────────────────────────────────────────┤
│ `GOAL`                    │ REQUIRED     │ Archivo Markdown con contrato de ejecución estructurado│
│ `NODE_ID`                 │ REQUIRED     │ Identificador del nodo objetivo (ej. `SAAS-NODE-02`).  │
│ `NODE_CONTRACT`           │ REQUIRED     │ Ruta al Node Contract aprobado (`/ncp/NCP-*-CONTRACT`) │
│ `ARCHITECTURE_STATE`      │ REQUIRED     │ Estado documental de referencia en Markdown.           │
│ `DECISION_RECORDS`        │ REQUIRED     │ Colección documental de decisiones `ARCH-*` aprobadas. │
│ `PROTECTED_ASSETS`        │ REQUIRED     │ Catálogo canónico de activos protegidos inmutables.    │
│ `PRECONDITIONS`           │ REQUIRED     │ Lista de condiciones técnicas requeridas en el GOAL.   │
│ `DEPENDENCIES`            │ REQUIRED     │ Nodos previos en estado `CLOSED` requeridos.           │
│ `PHYSICAL_EVIDENCE_INPUT` │ CONDITIONAL  │ Logs, salidas de test o queries aportadas en Handoff.  │
└───────────────────────────┴──────────────┴────────────────────────────────────────────────────────┘
```

### B. Contrato de Salidas (Outputs):
NCP Core emite estructuras tipificadas en Markdown / JSON estándar:
* **`PRECHECK_RESULT`:** Dictamen de los 12 checks pre-ejecución.
* **`DISPATCH_INSTRUCTION`:** Instrucción formal al agente con `ALLOWED_SCOPE` delimitado.
* **`HANDOFF_ACCEPTANCE`:** Aceptación o rechazo de un Handoff Package recibido.
* **`STATE_TRANSITION`:** Registro de transición operativa dentro de la máquina de estados.
* **`STOP_RECORD`:** Reporte canónico de STOP ante cualquier inconsistencia o anomalía.
* **`VALIDATION_GATE_RESULT`:** Resultado de pruebas funcionales y suites de validación.
* **`AUDIT_GATE_RESULT`:** Dictamen de auditoría de seguridad, RLS y no-regresión.
* **`CLOSURE_RECOMMENDATION`:** Paquete de evidencias elevado al Director solicitando cierre.
* **`DIRECTOR_DECISION_REQUEST`:** Solicitud formal de resolución ante un `ARCHITECTURAL_STOP`.

> [!CAUTION]
> **Separación de Salidas:**
> $$\text{CLOSURE\_RECOMMENDATION} \neq \text{CLOSED}$$
> $$\text{DIRECTOR\_DECISION\_REQUEST} \neq \text{DIRECTOR\_DECISION}$$

---

## 6. AUTHORITY BOUNDARY & WRITE MODEL

### Regla de Oro:
> **`NCP CORE = NO TIENE AUTORIDAD GENÉRICA DE ESCRITURA SOBRE EL REPOSITORIO`**

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ NCP CORE (Capacidad Operativa)                                              │
│ • READ: Inspección estática del repositorio.                                │
│ • VERIFY: Comprobación de integridad, esquemas y pruebas.                   │
│ • GATE: Evaluación de precondiciones y criterios de validación.             │
│ • DISPATCH: Enrutamiento al agente asignado.                                │
│ • RECEIVE: Validación de Handoff Packages.                                  │
│ • STOP: Aborto inmediato ante excepciones.                                  │
│ • REPORT: Escritura de reportes documentales de gobierno en `/ncp/`.         │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼ Despacha con ALLOWED_SCOPE
┌─────────────────────────────────────────────────────────────────────────────┐
│ IMPLEMENTER / CODEX (Capacidad de Modificación de Código)                   │
│ • WRITE / IMPLEMENT: Modificación física de archivos de aplicación          │
│   ÚNICAMENTE dentro del `ALLOWED_SCOPE` explícitamente autorizado.          │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Semántica de Persistencia Documental:
1. **Artefactos de Gobierno de NCP (`/ncp/*.md`):** NCP Core sólo puede generar o actualizar reportes de auditoría, registros de trazabilidad y packages de handoff formalmente vinculados a un GOAL activo.
2. **Archivos de Aplicación (`backend/`, `frontend/`, etc.):** NCP Core tiene **prohibida la escritura**. Toda modificación física es ejecutada exclusivamente por el Implementer / Codex bajo supervisión de scope.
3. **Inmutabilidad de `ALLOWED_SCOPE`:** NCP Core **no puede ampliar** el alcance de un GOAL de forma autónoma. Si surge la necesidad, emite un `STOP` al Director.

---

## 7. COMPONENT RESPONSIBILITIES & INTERACTION MATRIX

```text
┌────────────────────────┬─────────────────────────────────────────────────┬──────────────────────────────┐
│ Componente             │ Responsabilidades Exclusivas                    │ Límites Infranqueables       │
├────────────────────────┼─────────────────────────────────────────────────┼──────────────────────────────┤
│ **NCP Core CLI**       │ • Orquesta el ciclo de vida del GOAL.           │ • No aprueba arquitectura.   │
│ (`/ncp/ncp-core.js`)   │ • Ejecuta el Pre-Execution Gate (12 checks).    │ • No modifica código app.    │
│                        │ • Despacha a Evidence / Architect / Implementer.│ • No amplía scope.           │
│                        │ • Procesa y valida Handoffs.                    │ • No declara CLOSED.         │
│                        │ • Emite reportes de STOP y solicitudes Director.│                              │
├────────────────────────┼─────────────────────────────────────────────────┼──────────────────────────────┤
│ **Doc & State Reader** │ • Parsea sintaxis y secciones de GOALs (.md).   │ • Operación 100% read-only.  │
│ (`/ncp/reader.js`)     │ • Parsea Node Contracts y extrae reglas/scope.  │ • Cero modificaciones de     │
│                        │ • Parsea modelo conceptual ArchitectureState.   │   archivos.                  │
│                        │ • Lee Decision Records `ARCH-*`.                │                              │
├────────────────────────┼─────────────────────────────────────────────────┼──────────────────────────────┤
│ **Gate & Verifier**    │ • Invoca suites Jest/tests de validación.       │ • Ejecuta pruebas en sandbox.│
│ (`/ncp/verifier.js`)   │ • Comprueba no-regresión en Activos Protegidos. │ • Cero modificaciones DDL en │
│                        │ • Ejecuta queries de verificación (Read-Only).  │   PostgreSQL.                │
│                        │ • Audita el `git status` y scope modificado.    │                              │
└────────────────────────┴─────────────────────────────────────────────────┴──────────────────────────────┘
```

---

## 8. EXISTING INFRASTRUCTURE REUSE SPECIFICATION

```text
┌─────────────────────────────────────────┬──────────────────┬────────────────────────────────────────────────────────┐
│ Componente Existente                    │ Clasificación    │ Directiva de Uso en la Implementación                  │
├─────────────────────────────────────────┼──────────────────┼────────────────────────────────────────────────────────┤
│ Node.js Runtime (v18+)                  │ **REUSE**        │ Runtime de ejecución de los scripts CLI en `/ncp/`.    │
│ Driver PostgreSQL (`pg` v8.22)          │ **REUSE**        │ Sólo consultas SELECT de catálogo (Read-Only).         │
│ Jest Test Runner (`jest` v29.7)         │ **REUSE**        │ Ejecución de pruebas unitarias y de integración.       │
│ Formato Documental Markdown             │ **REUSE**        │ Formato exclusivo de contratos, estados y reportes.    │
│ Standalone Scripts (`backend/scripts/`) │ **REF. ONLY**    │ Patrón de diseño de scripts CLI; NO es ubicación.      │
│ Winston Logger Express                  │ **DO NOT USE**   │ No introducir dependencias de servidor web en el CLI.  │
│ Express Middleware / `traceId`          │ **DO NOT USE**   │ No aplicable a herramientas CLI fuera de runtime.      │
│ `aiOrchestratorService` & B2C Agents    │ **DO NOT USE**   │ Totalmente aislado del dominio B2C conversacional.     │
└─────────────────────────────────────────┴──────────────────┴────────────────────────────────────────────────────────┘
```

---

## 9. STATE & DECISION REGISTRY CONSUMPTION MODEL

NCP Core implementará el consumo de estado y decisiones de forma estrictamente **documental y conceptual**:

1. **Sin Base de Datos de Gobernanza:** `NEW_TABLES = 0`, `NEW_COLUMNS = 0`, `NEW_SCHEMAS = 0`.
2. **Fuente de Estado Declarado:** Parseo directo de los archivos de contrato y especificación en `/ncp/`.
3. **Fuente de Estado Fáctico:** Inspección de esquemas reales en PostgreSQL y de la estructura de archivos en Git.
4. **Regla de Reconciliación:** Si `Estado Fáctico ≠ Estado Declarado`, el componente **NUNCA** sincroniza silenciosamente; dispara un **`CONTRACT_STOP`** o **`DATA_STOP`** para decisión del Director.

---

## 10. PROTECTED ASSETS ENFORCEMENT ENGINE

El componente `Gate & Verification Engine` (`verifier.js`) incorporará un guard hard-coded que verificará antes y después de cada ejecución que la lista de **Activos Protegidos Canónicos** permanezca intacta:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                   CATÁLOGO INMUTABLE DE ACTIVOS PROTEGIDOS                  │
├─────────────────────────────────────────────────────────────────────────────┤
│ 1. SaaS Foundation v1.0 (Tablas base, Composite FKs, RLS, Migración 065)    │
│ 2. Pre-Nodo 01 (Cuentas, Identidades Base, Catálogo Previo)                 │
│ 3. Context Resolution v1.0 (fn_resolve_user_tenant, Migración 066, Serv.)   │
│ 4. SOUL Design Tokens (frontend/lib/core/theme/tokens.dart)                 │
│ 5. Contratos y Protocolos NCP (`/ncp/NCP-*.md`)                             │
│ 6. Todos los Nodos Cerrados (CLOSED) Posteriores                            │
└─────────────────────────────────────────────────────────────────────────────┘
```

> [!CAUTION]
> Cualquier modificación no autorizada a un Activo Protegido detectada en `git status` o mediante hash de archivo aborta de inmediato la operación emitiendo un **`SECURITY_STOP`** o **`SCOPE_STOP`**.

---

## 11. SECURITY & INTEGRITY CONTROLS

1. **Validación de Path Traversal:** Toda ruta provista en un GOAL es sanitizada para impedir accesos o escrituras fuera de los límites del repositorio.
2. **Principio de Mínimo Privilegio:** Consultas a base de datos para auditoría se ejecutan exclusivamente con el rol `beauty_app_user` (sin privilegios de superusuario ni DDL).
3. **Inviolabilidad de la Seguridad SaaS:** NCP Core tiene terminantemente prohibido alterar políticas de RLS, firmas JWT, hashes de contraseñas o middlewares de autenticación de GlowApp.

---

## 12. FAILURE & STOP MODEL

El contrato de implementación define respuestas unívocas ante fallos:

```text
┌──────────────────────────────┬──────────────────────────────┬─────────────────────────────┐
│ Condición de Error           │ Tipo de STOP / Estado        │ Salida y Acción             │
├──────────────────────────────┼──────────────────────────────┼─────────────────────────────┤
│ GOAL inválido o incompleto   │ `REJECTED`                   │ Exit Code 2 + Error Report  │
│ Contrato ausente / no aprob. │ `CONTRACT_STOP` 🔴           │ Exit Code 1 + Stop Record   │
│ Dependencia insatisfecha     │ `DEPENDENCY_STOP` 🔴         │ Exit Code 1 + Stop Record   │
│ Intento de bypass de scope   │ `SCOPE_STOP` 🔴              │ Exit Code 1 + Stop Record   │
│ Violación RLS o seguridad    │ `SECURITY_STOP` 🔴           │ Exit Code 1 + Stop Record   │
│ Inconsistencia en BD         │ `DATA_STOP` 🔴               │ Exit Code 1 + Stop Record   │
│ Pruebas fallidas             │ `VALIDATION_FAILED` 🔴       │ Exit Code 1 + Test Report   │
└──────────────────────────────┴──────────────────────────────┴─────────────────────────────┘
```

> [!IMPORTANT]
> **Prohibición de Recuperación Silenciosa:** Ningún componente de NCP Core implementará reintentos automáticos, ampliaciones dinámicas de scope ni correcciones automáticas de código ante fallos de validación o STOPs.

---

## 13. IDEMPOTENCY & AUDIT TRACEABILITY

1. **Idempotencia:** La ejecución repetida del CLI con el mismo GOAL bajo el mismo estado del repositorio:
   * Produce exactamente el mismo resultado y Exit Code.
   * No duplica reportes ni transiciones de estado.
   * No altera archivos ya validados.
2. **Cadena de Trazabilidad:** Todo reporte emitido por NCP Core incluye la tupla canónica de auditoría:
   $$\langle \text{GOAL\_ID}, \text{NODE\_ID}, \text{CONTRACT\_VER}, \text{AGENT}, \text{TIMESTAMP}, \text{GIT\_COMMIT}, \text{STATUS} \rangle$$

---

## 14. VALIDATION CONTRACT & CLOSURE BOUNDARY

Para que un nodo alcance los estados finales, el componente de verificación debe certificar:

```text
Condición READY_FOR_CLOSURE:
  [✓] Pre-Execution Gate: 12/12 PASS
  [✓] Allowed Scope respetado estrictamente (0 archivos no autorizados modificados)
  [✓] Suite de Pruebas de Validación: 100% PASS
  [✓] Auditoría de Seguridad, RLS y Aislamiento Multi-Tenant: 100% PASS
  [✓] Activos Protegidos: 100% INTACTOS
  [✓] Cero STOPs Abiertos
```

```text
Condición CLOSED (Cierre Definitivo):
  [✓] READY_FOR_CLOSURE certificado por NCP Core
  [✓] RESOLUCIÓN Y APROBACIÓN EXPRESA DEL DIRECTOR
```

---

## 15. ENGINEERING ECONOMY & ZERO PHYSICAL OVERHEAD

* **Cero Dependencias Nuevas:** La implementación se construirá usando las librerías ya instaladas en el repositorio (`pg`, `jest`, `dotenv`, módulos nativos `fs`, `path`, `child_process`).
* **Cero Procesos Persistentes:** Cero consumo de memoria en reposo.
* **Cero Código Especulativo:** Prohibido implementar funciones o parsers para nodos o features que no forman parte de los contratos aprobados.

---

## 16. ACCEPTANCE CRITERIA MATRIX

| Criterio de Aceptación | Estado en el Contrato |
| :--- | :--- |
| Consistencia con NCP Core Contract v1.0 | `PASS` |
| Consistencia con GOAL Execution Protocol v1.0 | `PASS` |
| Consistencia con Architecture State Protocol v1.0 | `PASS` |
| Consistencia con Operational Contract v1.0 | `PASS` |
| Consistencia con Physical Architecture v1.0 | `PASS` |
| Delimitación estricta de Autoridad de Escritura | `PASS` |
| Enforzamiento de `ALLOWED_SCOPE` | `PASS` |
| Protección Inmutable de Activos Protegidos | `PASS` |
| Modelo de Estado y Decisiones Documental | `PASS` |
| Manejo Determinista de Fallas y STOPs | `PASS` |
| Idempotencia y Trazabilidad Unívoca | `PASS` |
| Economía de Ingeniería (Cero dependencias nuevas) | `PASS` |
| Alcance de Implementación Explícito (3 componentes) | `EXPLICIT` |

---

## 17. DOCUMENTATION DIRECTORY LOCATION

Este contrato reside exclusivamente en:

```text
/ncp/NCP-CORE-IMPLEMENTATION-CONTRACT-v1.0.md
```

Queda terminantemente prohibido crear archivos ejecutables o directorios de código hasta la emisión formal de un GOAL de integración física aprobado por el Director.
