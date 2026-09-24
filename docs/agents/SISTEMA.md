# Sistema de agentes — Belleza App / GlowApp

**Versión:** 1.0 · 2026-09-24 · **Ámbito:** todo el monorepo (`backend/`, `frontend/`, `admin-dashboard/`)
**Regla que lo justifica:** el desarrollo no se rompe por falta de talento, se rompe por falta de estructura: cada quien audita una copia distinta, nadie sabe qué está vivo y el conocimiento vive en chats que se compactan. Este documento define quién hace qué, con qué contrato y con qué evidencia.

---

## 1. Los agentes

| Agente | Quién | Autoridad | Prohibido |
|---|---|---|---|
| **Arquitecto** | Hermes | Descompone el trabajo en fases, decide el orden, escribe las órdenes GOAL, mantiene la base de conocimiento, arbitra conflictos entre rondas | Implementar lo que él mismo audita; aprobar su propio plan sin criterios falsables |
| **Ejecutor** | Antigravity | Implementa **una orden = una rama = un PR**; crea y borra ramas locales de su tarea; ejecuta la poda autorizada | Mergear, borrar ramas del remoto, `push --force`, `gc`, tocar `main`, commitear sin test que primero falló |
| **Auditor** | Hermes | Audita la rama **real** (no el relato), corre sondas propias, emite veredicto por criterio y abre la ronda siguiente | Copiar la evidencia del Ejecutor como propia; dar por bueno lo que no midió; ocultar sus propias retracciones |
| **Guardián** | Scripts (sin LLM) | Falla (exit ≠0) cuando se viola una regla. Su veredicto no se discute, se cumple | — (no opina: mide) |
| **Dueño** | Diego | Decide dinero, seguridad, producción y excepciones; mergea; activa ajustes del repositorio | — |

**Guardián — inventario de compuertas:** `backend/scripts/checkNoConflictMarkers.js` · `backend/scripts/verifyNoVersionedSecrets.js` · `backend/scripts/estadoKB.js --check` (alineación y salud de ramas) · superficies (ninguna respuesta 2xx si su consulta falló) · CI por PR (`.github/workflows/ci.yml`).

## 2. El ciclo (bucle de una ronda)

```
Arquitecto: ORDEN-n (GOAL + criterios falsables + NO TOCAR) ──► encolada en COLA.md
      │
Ejecutor: rama `tipo/slug` desde origin/main + test que PRIMERO falla ──► PR
      │
Guardián: compuertas mecánicas en el PR ──► si falla, NO hay auditoría: corrige el Ejecutor
      │
Auditor: sonda propia sobre la rama real ──► veredicto ✓/✗/~ por criterio + retracciones
      │
      ├── ✗ ⇒ escribe ORDEN-(n+1) y vuelve arriba
      └── ✓ ⇒ el Dueño mergea; la rama se borra; se actualiza la KB
```

**Caducidad:** una orden sin PR abierto a los 5 días se etiqueta `archive/` y se replantea. El bucle no se queda esperando a nadie.

## 3. Contratos de entrega

| Artefacto | Quién lo produce | Formato | Qué debe contener |
|---|---|---|---|
| **ORDEN** | Arquitecto | `docs/agents/PLANTILLA-ORDEN.md` | Goal de una frase, contexto medido (con números y su comando), alcance, criterios de aceptación **falsables**, NO TOCAR, rama, caducidad |
| **ENTREGA** | Ejecutor | PR + walkthrough | Rama y SHA, qué cambió, **comandos y salidas crudas**, qué no se pudo verificar, desviaciones del plan |
| **AUDITORÍA** | Auditor | `docs/agents/PLANTILLA-AUDITORIA.md` | Veredicto por criterio, hallazgos con `archivo:línea`, retracciones, orden siguiente o cierre |
| **ESTADO** | Guardián (`estadoKB.js`) | bloque máquina en `docs/knowledge/ESTADO-ACTUAL.md` | Ramas, PRs, tags, worktrees, suites rojas, desalineaciones |

## 4. Reglas duras (no negociables)

1. **Ningún veredicto sin procedencia.** Todo informe declara repositorio, ruta, rama, SHA, `git status` y fecha, y el comando que produce cada número. Sin eso no es evidencia, es rumor.
2. **Ningún fix sin mutación previa.** El test que demuestra el defecto se escribe primero y se pega en rojo. Un fix sin rojo no se audita.
3. **Un número sin comando es un número inventado.** Si una cifra no tiene el comando que la produjo, se borra del informe.
4. **La información relevante vive en el repositorio** (`docs/knowledge/`), no en el chat ni en carpetas locales. Una auditoría que no llega al repo es una auditoría que se perderá.
5. **Un worktree por tarea**, retirado con la tarea. Nunca un worktree apuntando a una rama muerta.
6. **Nada de `main` directo.** Rama + PR. El PR es la puerta: si el CI no corre, no hay verificación.
7. **Los agentes no mergean, no borran ramas del remoto y no reescriben historia.** La poda la ejecuta el Dueño o un agente con autonomía explícita y el gate completo (tags en el remoto + `rev-list --count` + lista de PRs de la misma corrida).
8. **Si un veredicto se emitió sobre una copia desalineada, se retira en público.** La retracción es parte del trabajo, no una vergüenza: cuesta menos que una corrección sobre código obsoleto.
9. **Caducidad de 5/14 días** (ver `docs/policies/ramas.md`): una rama sin PR a los 5 días se archiva; sin commits en 14 días es huérfana por definición.
10. **La deuda se declara, no se esconde.** Una suite roja excluida del gate sigue ejecutándose en un paso no bloqueante; el verde obtenido por exclusión se escribe con la palabra *exclusión* en el PR.

## 5. Autonomía y escalado

El sistema **se ejecuta sin intervención humana** mientras no aparezca una de estas cuatro condiciones; en ese caso escala al Dueño con la decisión ya tomada y las opciones ordenadas:

| Escala cuando… | Ejemplo |
|---|---|
| hay dinero, seguridad o producción en juego | activar cobro real, publicar ramas con credenciales |
| hace falta una excepción a la política | conservar una rama que contradice la caducidad |
| dos rondas seguidas sin progreso medible | el mismo defecto reaparece con otra forma |
| la acción es destructiva fuera de lo autorizado | borrar el clon fósil, reescribir historia |

Todo lo demás —planificar, implementar, auditar, podar ramas muertas, rescatar trabajo, actualizar la KB, encolar la ronda siguiente— se decide y se ejecuta.

## 6. Conservación de la información (el punto que originó este sistema)

| Capa | Dónde vive | Qué conserva | Quién la mantiene |
|---|---|---|---|
| **Base de conocimiento** | `docs/knowledge/` | Arquitectura real, estado actual, deuda trazable, decisiones, trampas medidas | Arquitecto (obligatorio al cerrar cada ronda) |
| **Órdenes y cola** | `docs/agents/` | Qué se pidió, en qué estado está, qué quedó pendiente y por qué | Arquitecto |
| **Auditorías crudas** | `docs/audit/` (y carpeta local `auditorias/` como borrador) | La evidencia y las retracciones | Auditor |
| **Historia de ramas** | tags `archive/*` en GitHub | Todo commit que no está en `main`, con su fecha | Cualquiera de los tres, con el gate |
| **Trabajo rescatado** | tags `archive/rescate-*` + bundles | Lo que estaba sin commitear en worktrees | El que retira el worktree |
| **Estado máquina** | bloque generado en `ESTADO-ACTUAL.md` | Ramas, PRs, tags, suites rojas | `estadoKB.js` |

**Prueba de que la información se conserva:** un agente nuevo (o un humano nuevo) debe poder responder, leyendo solo el repositorio: qué hace la app, qué está roto, quién lo está arreglando, qué se decidió y por qué, y qué no se puede tocar. Si no puede, la KB está incompleta.

## 7. Arranque del sistema (esto ya está hecho)

- [x] Repositorio saneado: 44 referencias → 9; 6 worktrees → 2; todo lo huérfano en tags con su fecha (`INFORME-PODA-2026-09-24.md`).
- [x] Política de ramas escrita (`docs/policies/ramas.md`).
- [x] Base de conocimiento creada (`docs/knowledge/`).
- [x] Cola de trabajo con las órdenes pendientes (`docs/agents/COLA.md`).
- [ ] PR de `fase-a/verdad-operativa` abierto por el Dueño ⇒ *primera corrida real de CI de la historia del repo*.
