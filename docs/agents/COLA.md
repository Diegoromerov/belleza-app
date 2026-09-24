# COLA de trabajo — órdenes, decisiones y rondas

**Regla:** nada pendiente vive solo en la cabeza de alguien. Aquí está qué se pidió, en qué estado está y qué lo bloquea. El Arquitecto la actualiza al cerrar cada ronda; una orden sin movimiento a los 5 días se archiva y se replantea.

**Última actualización:** 2026-09-24 · por Hermes (Arquitecto) · tras la autorización D-001..D-005

---

## 1. Órdenes en curso o pendientes

| ID | Orden | Agente | Rama | Estado | Artefacto / prompt | Bloqueada por |
|---|---|---|---|---|---|---|
| O-001 | **Fase A ronda 3** — S1 (ninguna superficie 2xx si su consulta falló: `/api/products` responde 200 con datos fabricados) y S4 (`smoke:surfaces` sale 0 mientras miente) | Ejecutor | `fase-a/verdad-operativa` (o rama propia si el PR ya está abierto) | **pendiente** | `docs/agents/ordenes/PROMPT-ANTIGRAVITY-FASE-A-RONDA-3-2026-09-24.md` | — |
| O-002 | **Grafo de ramas ronda 2** — 6 aristas nacidas del fondo del tronco, leyenda con conteos hardcodeados, PNG que no se regenera, artefacto commiteado que no se reproduce | Ejecutor | `chore/grafo-rama-2` (rama propia desde `main`) | **pendiente** | `docs/agents/ordenes/PROMPT-ANTIGRAVITY-GRAFO-RONDA-2-2026-09-24.md` | O-001 no la bloquea, pero no conviene abrir dos PR tocando `docs/audit/` a la vez |
| O-003 | **P1 · Triage y alineación** — `branchTriage.js` + `checkAlignment.sh`, solo lectura, con `no verificado` si la API de PRs falla | Ejecutor | `chore/ramas-p1-triage` | **pendiente** | `docs/agents/ordenes/PROMPT-ANTIGRAVITY-RAMAS-P1-TRIAGE-2026-09-24.md` | — |
| O-004 | **P2 · Política en el repo y en CI** — `docs/policies/ramas.md` + sección en `AGENTS.md` + job semanal y chequeo ligero por PR | Ejecutor | `docs/ramas-p2-politica` | **pendiente** | `docs/agents/ordenes/PROMPT-ANTIGRAVITY-RAMAS-P2-POLITICA-2026-09-24.md` | O-003 (el job invoca los scripts de P1) |
| O-005 | **Mutación de CI (S3 falsable)** — probar que la compuerta **puede** fallar: rama con un test roto a propósito dentro del paso bloqueante ⇒ CI rojo ⇒ se cierra | Ejecutor | `tmp/mutacion-ci` (se borra al cerrar) | **pendiente** | esta misma orden, §3 | PR de `fase-a` abierto (si no, no hay run del que observar nada) |
| O-006 | **Sistema de agentes + base de conocimiento** | Arquitecto (Hermes) | `docs/sistema-agentes` | **entregada** 2026-09-24 (pendiente de PR) | este repo, `docs/agents/` y `docs/knowledge/` | — |
| O-007 | **P3 · Poda de ramas** | — | — | **ejecutada** 2026-09-24 | `INFORME-PODA-2026-09-24.md` | — |
| O-008 | **Autorización y procedimiento de D-001..D-005** — qué se autoriza, por dónde se ejecuta, puertas, verificación y rollback de cada una; incluye el criterio técnico medido sobre el fósil | Arquitecto (Hermes) | `docs/sistema-agentes` | **entregada** 2026-09-24 · **ejecución pendiente de permiso efectivo** | `docs/agents/ordenes/AUTORIZACION-D-001-A-D-005-2026-09-24.md` | Vía CLI con la credencial del `credential.helper`: **bloqueada por la plataforma** (aprobación no entregable al cliente). Vía navegador: sin sesión de GitHub. Vía vault: sin entradas. ⇒ lo ejecuta el Dueño en la UI, o un agente en sesión con aprobaciones |
| O-009 | **Auditoría de `ci.yml` + `.gitignore` + `index.js`** entregados por el Dueño; incluye la **simulación del CI sobre base descartable** que destapó A-01 | Auditor (Hermes) | `docs/sistema-agentes` | **entregada** 2026-09-24 | `docs/audit/AUDITORIA-CI-INDEX-GITIGNORE-2026-09-24.md` | — |
| O-010 | **Órdenes A-01 a A-05** (salidas de O-009): cadena RLS 056/058, métricas de dinero inventadas, montajes duplicados, procedencia de cifras; y el escalado de A-04/TEC-68 al Dueño | Ejecutor | ver cada orden | **pendiente** | `docs/agents/ordenes/PROMPT-ANTIGRAVITY-A-01-A-05-2026-09-24.md` | A-05 depende de A-01; A-04 espera decisión del Dueño |
| O-011 | **Auditoría del primer run del PR #16** (run [#1681](https://github.com/Diegoromerov/belleza-app/actions/runs/36072881287)): frontend verde, backend rojo en el paso 7 (compuerta de secretos), pasos 8-11 saltados, y la compuerta demostrada **no reproducible** entre copias del mismo commit | Auditor (Hermes) | `docs/sistema-agentes` | **entregada** 2026-09-24 | `docs/audit/AUDITORIA-PR-16-RUN-1681-2026-09-24.md` | — |
| O-012 | **Orden A-06** — compuerta de credenciales reproducible: fin de línea, alcance a código/configuración y autotest que pueda fallar. Además destapó **TEC-53 (crítico)**: el fallback del `JWT_SECRET` es incondicional y estaba declarado «falso positivo dev» | Ejecutor | `fix/compuerta-secretos-reproducible` | **ronda 1 entregada `5020e4df` → ✗ RECHAZADA; ronda 2 emitida** | ronda 1: `docs/audit/AUDITORIA-ENTREGA-A-06-2026-09-24.md` · ronda 2: `docs/agents/ordenes/PROMPT-ANTIGRAVITY-A-06-RONDA-2-2026-09-24.md` | 4 cargos: (1) la allowlist `glowapp_/dev_/default/root/postgres` deja la compuerta ciega al convenio del proyecto — mutación demostrada; (2) 3 hallazgos de seguridad declarados falsos positivos, entre ellos el secreto de firma JWT; (3) autotest tautológico; (4) `^\.github/workflows/` y prefijos de iniciales exentos enteros. Sin PR ⇒ C6 sin demostrar |

## 2. Decisiones del Dueño (escaladas)

| ID | Decisión | Estado | Qué desbloquea |
|---|---|---|---|
| D-001 | **Abrir el PR de `fase-a/verdad-operativa`** | **ejecutada** 2026-09-24 — [PR #16](https://github.com/Diegoromerov/belleza-app/pull/16), run [#1681](https://github.com/Diegoromerov/belleza-app/actions/runs/36072881287) | El primer run del repo **con pasos reales**: frontend ✅, backend ❌ en el paso 7 (compuerta de secretos) ⇒ ahora existen los hallazgos CI-06 y CI-07 y la orden A-06 |
| D-002 | `delete_branch_on_merge = on` en Settings → General → Pull Requests | **autorizada, sin ejecutar** | Que el merge borre su rama solo |
| D-003 | **Clon fósil**: qué se publica de sus 331 commits únicos | **resuelta técnicamente: NO publicar** — las 5 ramas sensibles (todas del 2026-07-31) arrastran `backend/.env.production` y `backend/.env.example` + `scratch/*.js` con patrones de credencial en 8 archivos, y el repo es público. Bundle de 319 MB archivado sin publicar. **Acción real: rotar los secretos**, porque `backend/.env.production` ya está en el historial de `main` (2 commits que lo tocan) | Cerrar SEG-04 (dueño: D) y enterrar la línea de trabajo sin filtrar credenciales |
| D-004 | **Mergear `docs/sistema-agentes`** (sistema de agentes + base de conocimiento) | **autorizada, sin ejecutar** — puerta de despliegue verificada: el único workflow con deploy (`rag-evaluation.yml`) limita sus `paths` a 5 archivos de RAG, `docs/**` no está entre ellos. Queda por confirmar si Railway despliega por integración nativa en cada push a `main` | Que el sistema y la compuerta vivan en `main` |
| D-005 | **Mergear PRs #10 y #12** (una vez verdes y revisados) | pendiente, **no** incluida en la autorización | `#12` trae el CSV de precios de GlowShop = base acordada del catálogo |

## 3. Ficha de O-005 (mutación de CI)

**Goal:** demostrar con una corrida real que la compuerta de CI **puede** salir roja, no solo verde.
**Método:** rama `tmp/mutacion-ci` desde `origin/main`; añadir en una suite **incluida en el paso bloqueante** (no en los 10 patrones excluidos: `geminiService|geminiFallback|auraToolExecutor|contract|biometric|resilience|contextCompressor|fase5|authRoutes|api.cors`) un test que falle a propósito, p. ej. `expect(1).toBe(2)`.
**Evidencia exigida:** URL del run en rojo, nombre del test que lo hundió, y `git push origin --delete tmp/mutacion-ci` + cierre del PR sin merge.
**Por qué importa:** sin esto, "el CI existe y puede fallar" (criterio S3) es una afirmación sin procedencia.

## 4. Cerrado (registro)

| ID | Entrega | Fecha | Evidencia |
|---|---|---|---|
| O-100 | Auditoría del módulo de prestador (12 etapas, C-01..C-05, A-07) | 2026-09-24 | `docs/audit/AUDITORIA-MODULO-PRESTADOR-2026-09-24.md` |
| O-101 | Fase A rondas 1 y 2 auditadas (H-01..H-05, B1..B6) | 2026-09-24 | `docs/audit/AUDITORIA-ENTREGA-FASE-A-*.md` |
| O-102 | Grafo de ramas auditado (D1..D8) | 2026-09-24 | `docs/audit/AUDITORIA-GRAFO-RAMAS-2026-09-24.md` |
| O-103 | Poda: 44 → 9 referencias, 6 → 2 worktrees, 398 entradas rescatadas, 8 tags `archive/*` | 2026-09-24 | `docs/audit/INFORME-PODA-2026-09-24.md` |
