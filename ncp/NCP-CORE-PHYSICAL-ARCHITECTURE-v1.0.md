# NCP CORE PHYSICAL ARCHITECTURE v1.0
## Node Construction Protocol — Minimal Physical Architecture & Tooling Specification

**Versión:** 1.0.0  
**Estado:** DEFINED / READY FOR DIRECTOR APPROVAL  
**Fase Metodológica:** DEFINIR $\rightarrow$ RELACIONAR  
**Ámbito:** Diseño de la Arquitectura Física Mínima, Desacoplada y Reutilizable para NCP Core  
**Autoridad Raíz:** Director del Proyecto GlowApp SaaS  
**Documentos Base Inmutables:**  
* [`/ncp/NCP-CORE-CONTRACT-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NCP-CORE-CONTRACT-v1.0.md)  
* [`/ncp/NCP-GOAL-EXECUTION-PROTOCOL-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NCP-GOAL-EXECUTION-PROTOCOL-v1.0.md)  
* [`/ncp/NCP-ARCHITECTURE-STATE-DECISION-REGISTRY-PROTOCOL-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NCP-ARCHITECTURE-STATE-DECISION-REGISTRY-PROTOCOL-v1.0.md)  
* [`/ncp/NCP-CORE-OPERATIONAL-CONTRACT-v1.0.md`](file:///C:/Users/Compu%20casa/.gemini/antigravity/worktrees/beauty-app/database_audit_read_only/ncp/NCP-CORE-OPERATIONAL-CONTRACT-v1.0.md)

---

## 1. IDENTITY, PURPOSE & CORE QUESTION

### Identidad
* **Nombre Oficial:** NCP Core Physical Architecture.
* **Versión:** 1.0.0.
* **Naturaleza:** Especificación de diseño de la arquitectura física mínima, modular y de bajo acoplamiento para el orquestador NCP Core.

### Pregunta Central de Diseño Físico
> **¿Dónde y cómo debe existir físicamente NCP Core para dar cumplimiento estricto a sus contratos aprobados, con el menor número posible de componentes nuevos, maximizando la reutilización de infraestructura existente y sin acoplarse bajo ninguna circunstancia al runtime funcional de GlowApp?**

---

## 2. CANONICAL AUTHORITY HIERARCHY

Este diseño físico se subordina de forma estricta a la jerarquía canónica:

```text
1. DIRECTOR — AUTHORITY ROOT
2. APPROVED ARCHITECTURAL DECISIONS (ARCH-*)
3. APPROVED NODE CONTRACT
4. SOUL + GOVERNANCE (Policy Layer)
5. EXISTING CLOSED ARCHITECTURE (Protected Assets)
6. PHYSICAL CODE AS EVIDENCE
7. AGENT / CODEX PROPOSALS
```

---

## 3. EVIDENCE FIRST: EXISTING REPOSITORY INFRASTRUCTURE AUDIT

Tras la inspección física del repositorio en su estado real, se clasifica la infraestructura existente bajo la taxonomía `REUSE`, `ADAPT` o `DO NOT USE`:

```text
┌─────────────────────────────────────────┬─────────────┬────────────────────────────────────────────────────────┐
│ Componente / Patrón Existente           │ Dictamen    │ Justificación y Evidencia Física                       │
├─────────────────────────────────────────┼─────────────┼────────────────────────────────────────────────────────┤
│ Node.js Runtime & NPM Environment       │ REUSE       │ Runtime presente en raíz y `backend/` para scripts.    │
│ Driver PostgreSQL (`pg` v8.22)          │ REUSE       │ Para queries de sólo lectura del Evidence Agent.       │
│ Jest Test Runner (`jest` v29.7)         │ REUSE       │ Motor de validación funcional y regresión existente.   │
│ Standalone Scripts (`backend/scripts/`) │ ADAPT       │ **PATRÓN DE REFERENCIA TÉCNICA** para scripts CLI      │
│                                         │ (Patrón)    │ deterministas. NO es ubicación física de NCP.          │
│ Formato Documental Markdown (`.md`)     │ REUSE       │ Estándar consolidado para contratos, estados y GOALs.  │
│ Logger Express (`winston`)              │ DO NOT USE  │ Acoplado a la API HTTP backend; NCP requiere CLI puro. │
│ `traceIdMiddleware`                     │ DO NOT USE  │ Middleware de ciclo de vida HTTP Express de negocio.   │
│ `aiOrchestratorService`                 │ DO NOT USE  │ Orquestador B2C de agentes conversacionales cliente.   │
│ B2C Agents (`atena`, `chronos`, etc.)   │ DO NOT USE  │ Agentes de dominio B2C en `backend/src/services/`.     │
└─────────────────────────────────────────┴─────────────┴────────────────────────────────────────────────────────┘
```

> [!IMPORTANT]
> **Aclaración sobre `backend/scripts/`:** La referencia a `backend/scripts/` representa exclusivamente un **patrón de referencia técnica** (cómo estructurar scripts Node.js independientes sin servidor web). **NO es la ubicación física de NCP**. El hogar canónico e inviolable de NCP continúa siendo `/ncp/`.

---

## 4. NCP / RUNTIME STRICT DECOUPLING

NCP Core opera exclusivamente en el plano de **Gobernanza y Tooling de Desarrollo**, completamente segregado del plano de **Runtime de Producción**:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                    PLANO DE GOBERNANZA & TOOLING (NCP)                      │
│                                                                             │
│   Ubicación Canónica: `/ncp/`                                               │
│   Ejecución: One-shot CLI / Scripts deterministas / Documentos Markdown     │
│   Acceso: Lectura estática de código, esquemas DB y ejecución de tests.     │
│   Usuarios: Director, Arquitecto, Implementador, Auditor.                   │
└─────────────────────────────────────────────────────────────────────────────┘
                                      ║
                          AISLAMIENTO TOTAL (CERO RUNTIME COUPLING)
                                      ║
┌─────────────────────────────────────────────────────────────────────────────┐
│                    PLANO DE RUNTIME DE PRODUCCIÓN (GLOWAPP)                 │
│                                                                             │
│   Backend: `backend/src/` (Express, Sequelize, RLS, PostGIS)                │
│   Frontend: `frontend/lib/` (Flutter, SOUL UI Tokens)                       │
│   B2C IA: `backend/src/services/aiOrchestratorService.js`, Atena, Chronos   │
│   Usuarios: Clientes, Salones, Profesionales de belleza.                    │
└─────────────────────────────────────────────────────────────────────────────┘
```

> [!CAUTION]
> Queda terminantemente prohibido importar librerías de NCP dentro de `backend/src/` o `frontend/lib/`, así como invocar controladores de negocio desde NCP Core.

---

## 5. ARCHITECTURAL OPTIONS COMPARISON & SELECTION

Se evaluaron tres opciones arquitectónicas para la materialización física de NCP Core:

```text
┌────────────────────────────────────────┬────────────────────────────────────────────────────────────────────────┐
│ Opción Evaluada                        │ Análisis Técnico y Veredicto                                           │
├────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────┤
│ **OPCIÓN A: NCP Documental + Scripts** │ **RECOMENDADA (SELECCIONADA)**                                         │
│ Protocolo en Markdown + scripts CLI    │ • Cero sobrecarga de infraestructura.                                  │
│ mínimos y modulares en `/ncp/`.        │ • Máxima transparencia y versionado completo en Git.                   │
│                                        │ • Idempotente, determinista y de bajo mantenimiento.                   │
├────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────┤
│ **OPCIÓN B: Módulo de Tooling NPM**    │ **DESCARTADA PARA ESTA FASE (Sobrediseño)**                            │
│ Paquete independiente con bundle,      │ • Introduce dependencias de compilación y empaquetado innecesarias.    │
│ dependencias propias y CLI global.     │ • Complejidad prematura que viola el principio de economía.            │
├────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────┤
│ **OPCIÓN C: Microservicio Daemon**     │ **DESCARTADA (Violación de Aislamiento)**                              │
│ Proceso en background con API REST/gRPC│ • Introduce estado persistente en memoria, riesgo de fuga de recursos  │
│ para coordinar agentes.                │   y acoplamiento operativo innecesario.                                │
└────────────────────────────────────────┴────────────────────────────────────────────────────────────────────────┘
```

---

## 6. COMPONENT CONSOLIDATION & WRITE AUTHORITY BOUNDARY

En lugar de crear 11 componentes aislados, NCP Core consolida sus responsabilidades en **tres componentes físicos mínimos de gobernanza**:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       1. NCP CORE ORCHESTRATOR (CLI)                        │
│                   Ubicación canónica: `/ncp/ncp-core.js`                    │
│                                                                             │
│   • Orquesta el ciclo de vida del GOAL.                                     │
│   • Ejecuta el Pre-Execution Gate (12 checks).                              │
│   • Despacha y enruta al agente asignado (Evidence, Architect, Implementer)│
│   • Procesa y valida Handoff Packages.                                      │
│   • Dispara STOPs estructurados de forma inmediata.                         │
│   • Emite reportes de trazabilidad y solicitudes de decisión al Director.   │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
         ┌─────────────────────────────┴─────────────────────────────┐
         ▼                                                           ▼
┌──────────────────────────────┐            ┌────────────────────────────────┐
│  2. DOCUMENT & STATE READER  │            │  3. GATE & VERIFICATION ENGINE │
│  (Módulo de Lectura Parser)  │            │  (Módulo de Validación/Tests)  │
│                              │            │                                │
│ • Lee y parsea GOALs (.md).  │            │ • Ejecuta suites Jest/tests.   │
│ • Parsea Node Contracts.     │            │ • Verifica RLS y no-regresión. │
│ • Parsea ArchitectureState.  │            │ • Comprueba integridad Git.    │
│ • Lee Decision Records ARCH-*│            │ • Certifica criterios de gate. │
└──────────────────────────────┘            └────────────────────────────────┘
```

### Regla Fundamental de Autoridad de Escritura:
> [!IMPORTANT]
> **`NCP CORE = NO TIENE AUTORIDAD GENÉRICA DE ESCRITURA SOBRE EL REPOSITORIO`**  
> NCP Core es un motor de orquestación, verificación y control. Sus funciones se limitan estrictamente a:  
> **`READ` $\cdot$ `INSPECT` $\cdot$ `VERIFY` $\cdot$ `GATE` $\cdot$ `DISPATCH` $\cdot$ `RECEIVE` $\cdot$ `RECONCILE` $\cdot$ `STOP` $\cdot$ `REPORT`**

La capacidad y autorización para realizar modificaciones físicas en el código fuente o esquemas reside **exclusivamente en el Implementer / Codex**, y sólo cuando se cumplen copulativamente las cuatro condiciones de despacho:
1. `NODE CONTRACT = APPROVED`
2. `GOAL = VALID`
3. `PRECHECK = PASS`
4. `ALLOWED_SCOPE = EXPLICIT`

---

## 7. ALLOWED_SCOPE SEMANTICS & BOUNDARY ENFORCEMENT

Para evitar ambigüedades operativas, se establece formalmente la semántica de `ALLOWED_SCOPE`:

* **Naturaleza:** `ALLOWED_SCOPE` **NO** constituye un permiso permanente de NCP Core ni una capacidad genérica de escritura del sistema.
* **Definición:** Es exclusivamente una **autorización de ejecución específica y temporal para el Implementer / Codex** dentro de un GOAL concreto emitido por el Director.
* **Rol de NCP Core:** NCP Core verifica, audita y hace cumplir dicho límite; **NCP Core NO puede ampliar el `ALLOWED_SCOPE` por sí mismo**.
* **Protocolo de Ampliación:** Si durante la implementación surge la necesidad técnica de tocar un archivo fuera de scope:
  $$\text{STOP INMEDIATO} \longrightarrow \text{RECOMMENDATION} \longrightarrow \text{DIRECTOR DECISION}$$

---

## 8. CANONICAL PHYSICAL EXECUTION FLOW

El flujo físico canónico modela con precisión la transferencia de control y la delimitación de la capacidad de modificación física:

```text
                                    DIRECTOR
                                       │
                                       ▼
                                      GOAL
                                       │
                                       ▼
                                    NCP CORE
                                       │
                                       ├── READ / VERIFY
                                       ├── PRECHECK
                                       ├── GATE
                                       └── DISPATCH
                                              │
                                              ▼
                                     IMPLEMENTER / CODEX
                                              │
                                              ├── READ
                                              ├── IMPLEMENT (Dentro de ALLOWED_SCOPE)
                                              └── TEST (Localmente)
                                                     │
                                                     ▼
                                                 HANDOFF
                                                     │
                                                     ▼
                                                  NCP CORE
                                                     │
                                                     ▼
                                                 VALIDATION
                                                     │
                                                     ▼
                                                   AUDIT
```

> [!NOTE]
> La capacidad de modificación física del código permanece estrictamente en el participante autorizado para la implementación (`Implementer / Codex`), nunca en NCP Core.

---

## 9. GOAL INPUT & ARTIFACT FORMAT

Para garantizar auditoría, versionado e inmutabilidad sin introducir dependencias pesadas:
* **Formato Canónico:** Archivo Markdown estructurado (`.md`) con bloques semánticos delimitados.
* **Ubicación Conceptual:** Los GOALs emitidos residen documentalmente en `/ncp/` o son suministrados directamente al CLI/Agente.
* **Criterios Satisfechos:**
  * **Auditabilidad:** Modificaciones trazables en Git `diff`.
  * **Legibilidad Humana:** Interpretación inmediata por el Director y desarrolladores.
  * **Determinismo:** Parseable mediante expresiones regulares o analizadores estándar sin librerías externas complejas.

---

## 10. EXECUTION MODEL: ONE-SHOT DETERMINISTIC TOOLING

NCP Core se concibe como una **herramienta de ejecución puntual (One-Shot CLI / Script)**:

```text
                                INVOCACIÓN PUNTUAL (CLI)
                                           │
                                           ▼
                                ┌─────────────────────┐
                                │   CARGA DE ESTADO   │
                                └──────────┬──────────┘
                                           │
                                           ▼
                                ┌─────────────────────┐
                                │ EJECUCIÓN DEL GATE  │
                                └──────────┬──────────┘
                                           │
                                           ▼
                                ┌─────────────────────┐
                                │ REPORTE / HANDOFF   │
                                └──────────┬──────────┘
                                           │
                                           ▼
                                  FIN DE PROCESO (Exit)
```

### Justificación Técnica:
* **Stateless:** No retiene estado en memoria entre ejecuciones, eliminando riesgos de corrupción o condiciones de carrera.
* **Idempotente:** La ejecución repetida bajo las mismas entradas produce exactamente el mismo resultado.
* **Eficiencia:** Cero consumo de CPU o memoria en segundo plano.

---

## 11. PERSISTENCE & DATA STORAGE ARCHITECTURE

El modelo de persistencia separa con rigor lo documental de lo temporal:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. MUST PERSIST (Persistencia Fija en Git)                                  │
│ • Node Contracts formalmente aprobados (`/ncp/NCP-*-CONTRACT-*.md`).        │
│ • Protocolos maestros de gobernanza.                                        │
│ • Decisiones arquitectónicas registradas (`ARCH-*`).                        │
│ • Historial de Handoff Packages y reportes de auditoría de cierre.          │
├─────────────────────────────────────────────────────────────────────────────┤
│ 2. CAN REMAIN DOCUMENTAL (Modelos Conceptuales)                             │
│ • `ArchitectureState`: Razonamiento de estado fáctico vs declarado.         │
│ • `DecisionRegistry`: Trazabilidad de decisiones históricas y vigentes.     │
├─────────────────────────────────────────────────────────────────────────────┤
│ 3. DERIVED TEMPORARY STATE (Memoria Volátil en Ejecución)                   │
│ • Matrices de evaluación de pre-checks (12 checks en runtime del script).   │
│ • Resultados intermedios de pruebas Jest y queries de validación.           │
├─────────────────────────────────────────────────────────────────────────────┤
│ 4. BASE DE DATOS FÍSICA PARA NCP                                            │
│ • `NEW_TABLES = 0`, `NEW_COLUMNS = 0`, `NEW_SCHEMAS = 0`.                   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 12. SECURITY & ACCESS BOUNDARY

```text
┌──────────────────────────────┬──────────────────┬────────────────────────────────────────────────────────┐
│ Frontera de Acceso           │ Participante     │ Mecanismo de Control y Límite                          │
├──────────────────────────────┼──────────────────┼────────────────────────────────────────────────────────┤
│ Filesystem (Lectura Global)  │ NCP Core / Evid. │ Inspección de solo lectura en todo el repositorio.     │
│ Filesystem (Escritura NCP)   │ NCP Core         │ **Restringido exclusivamente a reportes en `/ncp/`.**   │
│ Filesystem (Modif. Código)   │ Implementer/Codex│ **Restringido estrictamente al `ALLOWED_SCOPE` del GOAL│
│ Base de Datos PostgreSQL     │ Evidence / Audit │ Lectura de catálogo bajo runtime `beauty_app_user`.    │
│ Base de Datos PostgreSQL     │ Todos            │ **PROHIBIDO DDL directo** (exclusivo migraciones).     │
│ Activos Protegidos           │ Todos            │ Inmutables. Modificación aborta de inmediato (`STOP`). │
│ Privilegios del Sistema      │ Todos            │ Least Privilege. Sin permisos de administrador/root.   │
└──────────────────────────────┴──────────────────┴────────────────────────────────────────────────────────┘
```

---

## 13. PHYSICAL ARCHITECTURE COMPONENT MATRIX

```text
┌────────────────────────┬───────────────────┬───────────────────────────────────┬────────────────────────┐
│ Componente Físico      │ Ubicación Canónica│ Responsabilidad y Flujo           │ Frontera de Seguridad  │
├────────────────────────┼───────────────────┼───────────────────────────────────┼────────────────────────┤
│ **NCP Core CLI**       │ `/ncp/ncp-core.js`│ In: GOAL, Contrato, Estado        │ Control y orquestación.│
│                        │ (cuando se cree)  │ Out: Pre-check, Dispatch, STOP    │ Cero escritura código. │
├────────────────────────┼───────────────────┼───────────────────────────────────┼────────────────────────┤
│ **Doc & State Reader** │ `/ncp/reader.js`  │ In: Archivos Markdown en `/ncp/`  │ Sólo lectura           │
│                        │ (cuando se cree)  │ Out: Objetos estructurados parsed │ en filesystem.        │
├────────────────────────┼───────────────────┼───────────────────────────────────┼────────────────────────┤
│ **Gate & Verifier**    │ `/ncp/verifier.js`│ In: Suites de prueba / Git status │ Ejecuta tests sandbox; │
│                        │ (cuando se cree)  │ Out: PASS / STOP_RECORD           │ no modifica esquemas.  │
└────────────────────────┴───────────────────┴───────────────────────────────────┴────────────────────────┘
```

---

## 14. MINIMUM VIABLE NCP (MVP DEFINITION)

La implementación mínima viable física de NCP Core se compone exclusivamente de:

1. **Un punto de entrada CLI ejecutable** que cargue un GOAL en Markdown.
2. **Evaluador de los 12 checks del Pre-Execution Gate** (validación de contratos y dependencias).
3. **Mapeador determinista de despacho** hacia los roles de agentes.
4. **Verificador de suites de prueba Jest** existentes para gates de validación.
5. **Generador de reportes de STOP estructurados** en caso de discrepancias o fallos.

---

## 15. EXPLICIT NON-GOALS (LÍMITES DEL DISEÑO)

Quedan formalmente excluidos del diseño y alcance de NCP Core:
* ❌ Interfaces de usuario web (Dashboards, paneles de control).
* ❌ Aplicaciones móviles o interfaces de cliente.
* ❌ Agentes conversacionales o chatbots interactivos de IA.
* ❌ Toma autónoma de decisiones arquitectónicas o autoaprobación de contratos.
* ❌ Ejecución automática o desatendida de migraciones de base de datos en producción.
* ❌ Despliegues autónomos a entornos de staging/producción (CI/CD replacement).
* ❌ Acoplamiento con lógica B2C de GlowApp (reservas, pagos, profesionales).

---

## 16. DOCUMENTATION DIRECTORY LOCATION

Esta especificación física de diseño reside exclusivamente en:

```text
/ncp/NCP-CORE-PHYSICAL-ARCHITECTURE-v1.0.md
```

Queda prohibida la creación física prematura de scripts o directorios de código hasta contar con la aprobación del Director y un GOAL específico de integración física.
