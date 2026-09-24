# Registro de decisiones (ADR) — Belleza App / GlowApp

Una entrada por decisión no obvia: **qué se decidió, cuándo, por qué, y qué alternativa se descartó**. Sirve para no re-litigar lo ya decidido y para que un agente nuevo no repita el debate.

---

## 2026-09-24 · D-001 · GitHub es la única fuente de verdad; la copia local es banco de trabajo

- **Contexto:** tres copias vivas (`C:/beauty-app`, el clon del cwd y varios worktrees) con estados distintos; auditorías ejecutadas sobre copias obsoletas.
- **Decisión:** la historia y las ramas viven en GitHub; toda rama nace de `git fetch origin && git switch -c <rama> origin/main`; todo veredicto declara su procedencia (repo, rama, SHA, `git status`, fecha).
- **Descartado:** «auditar la copia que tengo a mano» y «sincronizar a mano antes de auditar».
- **Consecuencia medible:** el clon del cwd quedó marcado como fósil (1.363 commits detrás).

## 2026-09-24 · D-002 · Antes de podar, rescatar: ninguna poda destruye trabajo sin commitear

- **Contexto:** 4 worktrees con 398 entradas sin commitear (369 archivos / 105.798 líneas en uno solo).
- **Decisión:** la primera fase de cualquier saneamiento es inventariar y **rescatar a un tag** el trabajo sucio; el borrado viene después. Una rama «muerta» (0 commits fuera de `main`) **no** vuelve inútiles los archivos sin commitear.
- **Descartado:** `git worktree remove --force` y confiar en que «eso ya estaba mergeado».

## 2026-09-24 · D-003 · La historia se conserva en tags, no en ramas

- **Decisión:** antes de borrar una rama con commits propios, `git tag -a archive/<rama>-<fecha>` **publicado** en el remoto. Los tags `archive/*` no se borran.
- **Consecuencia:** 8 tags locales y 17 refs de tag en el remoto sostienen todo lo que se podó.

## 2026-09-24 · D-004 · El gate de la poda es la aritmética, no `git branch -d`

- **Contexto medido:** `git branch -d` compara la rama contra **HEAD**, no contra `main`; se negó con 5 ramas que sí estaban contenidas en `main`.
- **Decisión:** el gate es `git rev-list --count main..<rama>` = 0 **y** `git merge-base --is-ancestor <rama> main`; se borra con `-D` pegado a ese gate impreso.
- **Descartado:** confiar en `-d` como red de seguridad (o atasca sin motivo, o empuja a usar `-D` a ciegas).

## 2026-09-24 · D-005 · No se publica el clon fósil sin revisión (el repo es público)

- **Contexto:** el fósil guarda **331 commits únicos** (14 ramas), cinco con nombres sensibles (`migrate-env-to-secrets`, `integrate-secret-manager`, `implement-encryption-at-rest`…). El repositorio responde sin token ⇒ es público.
- **Decisión:** preservar en **bundle local** de 319 MB y **no** publicar en GitHub hasta que el Dueño revise esas ramas.
- **Descartado:** publicar las ramas como tags para «tener todo centralizado» — habría podido publicar credenciales.

## 2026-09-24 · D-006 · Fase A es honestidad de estado, no negocio

- **Decisión:** mientras dure la Fase A no se toca cobro, OTP, wallet, disputas, migraciones, `index.js` más allá de lo pedido, ni el bundle commiteado `backend/public`.
- **Por qué:** primero que el sistema deje de mentir sobre su estado; después se arregla el negocio con tests que puedan fallar.

## 2026-09-24 · D-007 · El PR es la puerta; el CI corre en `pull_request`

- **Contexto:** `ci.yml` tenía marcadores de conflicto en `main` y **ningún run se había ejecutado nunca**.
- **Decisión:** reparar `ci.yml` conservando el montaje de esquema multi-tenant y los roles RLS y **descartando `sequelize.sync({force:true})`** (`npm run migrate`): las políticas RLS no viven en un modelo.
- **Consecuencia:** en el PR de `fase-a` se ejecutará el primer run real de la historia del repositorio.

## 2026-09-24 · D-008 · Verde por exclusión se escribe con la palabra *exclusión*

- **Contexto:** el paso bloqueante de CI excluye 10 patrones de suite (15 suites rojas heredadas) y las corre en un paso **no bloqueante**.
- **Decisión:** la exclusión es deuda declarada y visible; se documenta en el PR y su estado real no desaparece del tablero. Leer «CI verde» como «verificado» queda prohibido.
- **Pendiente que esto crea:** O-005, la mutación que demuestra que la compuerta **puede** fallar.

## 2026-09-24 · D-009 · Los agentes no mergean ni borran el remoto (con una excepción)

- **Decisión:** por defecto, solo el Dueño borra ramas del remoto, mergea y activa ajustes. **Excepción:** con autorización explícita de autonomía y el gate completo (tags verificados en el remoto + `rev-list --count` + lista de PRs de la misma corrida), un agente puede ejecutar la poda. Así se ejecutó el 2026-09-24.
- **Descartado:** «el agente propone, el humano teclea 16 comandos».

## 2026-09-24 · D-010 · La información relevante vive en el repositorio

- **Decisión:** arquitectura, estado, deuda, trampas y decisiones viven en `docs/knowledge/`; las órdenes en `docs/agents/ordenes/`; las auditorías crudas en `docs/audit/`. La carpeta local `auditorias/` es borrador, no archivo.
- **Por qué:** el conocimiento en un chat se compacta y se pierde; en el repositorio se versiona y se hereda.

## 2026-09-24 · D-011 · Un worktree por tarea, retirado con la tarea

- **Contexto medido:** 6 worktrees, 2 apuntando a ramas muertas, 4 con trabajo sucio de semanas.
- **Decisión:** un worktree por tarea, bajo `.gemini/antigravity/worktrees/beauty-app/<tarea>`; se retira al cerrar la tarea. Prohibido dejar trabajo sin commitear más de 48 h.

## 2026-09-24 · D-012 · Las compuertas mecánicas tienen la última palabra

- **Decisión:** existe un rol **Guardián** sin LLM (`checkNoConflictMarkers.js`, `verifyNoVersionedSecrets.js`, `estadoKB.js --check`, CI por PR). Su veredicto no se discute: se cumple. Un agente no puede declarar «verde» lo que el Guardián marca rojo.
- **Por qué:** la opinión de un modelo no es evidencia; un `exit ≠0` sí.

## 2026-09-24 · D-013 · Las órdenes se escriben como GOAL con criterios falsables

- **Decisión:** una orden = una frase de éxito medible + criterios escritos como test que puede fallar + mutación obligatoria + NO TOCAR + evidencia exigida. Las listas de tareas se descartan como formato.
- **Por qué:** una lista de tareas se puede «cumplir» sin que el resultado sea verdadero.

## 2026-09-24 · D-014 · Todo fix nace de un test que primero falla

- **Decisión:** no se acepta un arreglo sin la corrida en rojo que demuestra el defecto. Sin rojo no hay auditoría, solo opinión.
