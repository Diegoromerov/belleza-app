# COLA de trabajo — órdenes, decisiones y rondas

**Regla:** nada pendiente vive solo en la cabeza de alguien. Aquí está qué se pidió, en qué estado está y qué lo bloquea. El Arquitecto la actualiza al cerrar cada ronda; una orden sin movimiento a los 5 días se archiva y se replantea.

**Última actualización:** 2026-09-24 · por Hermes (Arquitecto)

---

## 1. Órdenes en curso o pendientes

| ID | Orden | Agente | Rama | Estado | Artefacto / prompt | Bloqueada por |
|---|---|---|---|---|---|---|
| O-001 | **Fase A ronda 3** — S1 (ninguna superficie 2xx si su consulta falló: `/api/products` responde 200 con datos fabricados) y S4 (`smoke:surfaces` sale 0 mientras miente) | Ejecutor | `fase-a/verdad-operativa` (o rama propia si el PR ya está abierto) | **pendiente** | `docs/agents/ordenes/PROMPT-ANTIGRAVITY-FASE-A-RONDA-3-2026-09-24.md` | — |
| O-002 | **Grafo de ramas ronda 2** — 6 aristas nacidas del fondo del tronco, leyenda con conteos hardcodeados, PNG que no se regenera, artefacto commiteado que no se reproduce | Ejecutor | `chore/grafo-rama-2` (rama propia desde `main`) | **pendiente** | `docs/agents/ordenes/PROMPT-ANTIGRAVITY-GRAFO-RONDA-2-2026-09-24.md` | O-001 no la bloquea, pero no conviene abrir dos PR tocando `docs/audit/` a la vez |
| O-003 | **P1 · Triage y alineación** — `branchTriage.js` + `checkAlignment.sh`, solo lectura, con `no verificado` si la API de PRs falla | Ejecutor | `chore/ramas-p1-triage` | **pendiente** | `docs/agents/ordenes/PROMPT-ANTIGRAVITY-RAMAS-P1-TRIAGE-2026-09-24.md` | — |
| O-004 | **P2 · Política en el repo y en CI** — `docs/policies/ramas.md` + sección en `AGENTS.md` + job semanal y chequeo ligero por PR | Ejecutor | `docs/ramas-p2-politica` | **pendiente** | `docs/agents/ordenes/PROMPT-ANTIGRAVITY-RAMAS-P2-POLITICA-2026-09-24.md` | O-003 (el job invoca los scripts de P1) |
| O-005 | **Mutación de CI (S3 falsable)** — probar que la compuerta **puede** fallar: rama con un test roto a propósito dentro del paso bloqueante ⇒ CI rojo ⇒ se cierra | Ejecutor | `tmp/mutacion-ci` (se borra al cerrar) | **pendiente** | esta misma orden, §3 | PR de `fase-a` abierto (si no, no hay run del que observar nada) |
| O-006 | **Sistema de agentes + base de conocimiento** (esta entrega) | Arquitecto (Hermes) | `docs/sistema-agentes` | **en curso** | este repo, `docs/agents/` y `docs/knowledge/` | — |
| O-007 | **P3 · Poda de ramas** | — | — | **ejecutada** 2026-09-24 | `INFORME-PODA-2026-09-24.md` | — |

## 2. Decisiones del Dueño (escaladas)

| ID | Decisión | Estado | Qué desbloquea |
|---|---|---|---|
| D-001 | **Abrir el PR de `fase-a/verdad-operativa`** (`github.com/Diegoromerov/belleza-app/pull/new/fase-a/verdad-operativa`) | **pendiente** | El primer run real de CI en la historia del repo; O-005; el criterio S3 de la Fase A |
| D-002 | `delete_branch_on_merge = on` en Settings → General → Pull Requests | pendiente | Que el merge borre su rama solo |
| D-003 | **Clon fósil**: decidir si algo de sus 331 commits únicos (14 ramas, 5 con nombres sensibles: `migrate-env-to-secrets`, `integrate-secret-manager`…) se publica tras revisión. Hoy está en bundle local de 319 MB, sin publicar (el repo es público) | pendiente | Recuperar o enterrar definitivamente esa línea de trabajo |
| D-004 | **Mergear PRs #10 y #12** (una vez verdes y revisados) | pendiente | `#12` trae el CSV de precios de GlowShop = base acordada del catálogo |

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
