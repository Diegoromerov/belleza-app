# Política de ramas y veredictos — Belleza App / GlowApp

**Versión:** 1.0 · **Fecha:** 2026-09-24 · **Destino en el repo:** `docs/policies/ramas.md` + sección resumen en `AGENTS.md`
**Motivo:** 44 referencias de rama y 26 nombres únicos para 3 tareas vivas hicieron que auditorías reales se ejecutaran sobre código obsoleto. Estas reglas existen para que eso no vuelva a pasar.

---

## 1. Nombres permitidos

| Prefijo | Uso |
|---|---|
| `fase-<letra>/<slug>` | trabajo de una fase del plan de integración (ej. `fase-a/verdad-operativa`) |
| `fix/<slug>` | corrección de un defecto |
| `feat/<slug>` | funcionalidad nueva |
| `audit/<slug>` | auditoría o evidencia |
| `docs/<slug>` | documentación |
| `chore/<slug>` | mantenimiento |

**Prohibidos como nombre de rama:** `backup/*`, `baseline-*`, `pr<N>`, `tmp-*`, `test-*`, y cualquier nombre genérico sin tarea asociada. Para conservar historia se usan **tags** (`archive/<rama>-<yyyy-mm-dd>`), no ramas.

## 2. Ciclo de vida

1. **Nacimiento:** `git fetch origin && git switch -c <nombre> origin/main`. **Nunca** desde otra rama. Si de verdad hace falta una rama apilada, se declara su rama padre en el PR.
2. **Una rama = una tarea = un PR.** Cada rama abierta debe tener su PR abierto en las primeras 24 h de trabajo real.
3. **Caducidad:** una rama sin PR abierto a los **5 días** se etiqueta `archive/` y se borra. Toda rama sin PR y con más de **14 días** sin commits es **huérfana por definición** y entra en el triage.
4. **Al mergear:** se borra la rama (botón "Delete branch" + `delete_branch_on_merge=true` en el repositorio). Un merge sin borrado deja basura que parece viva.
5. **Antes de borrar una rama con commits únicos:** `git tag -a archive/<rama>-<yyyy-mm-dd> -m "archivo pre-poda" <tip>` y `git push origin --tags`. **Un tag `archive/*` no se borra nunca.**
6. **Ramas muertas** (0 commits fuera de `main`, verificado con `git rev-list --count main..<rama>` = 0) se borran **sin** tag: su contenido ya está en `main`.

## 3. Protecciones (el triage automático no puede proponerlas)

- Ramas con **PR abierto** (se leen de la API: `state=open`).
- Ramas con commits en los **últimos 14 días**.
- `main`.

## 4. Worktrees

- **Un worktree por tarea**, dentro de `.gemini/antigravity/worktrees/beauty-app/<nombre-de-la-tarea>`.
- Se elimina **con** la tarea (`git worktree remove`), no antes: `remove` falla si hay cambios sin commitear, y ese fallo es la garantía de que no se pierde trabajo.
- **Prohibido** dejar un worktree apuntando a una rama muerta o a un PR ya mergeado.
- Prohibido dejar trabajo sin commitear en un worktree por más de 48 h: o se commitea a su rama, o se copia fuera del repo y se declara.

## 5. Veredictos y procedencia (la regla que evita el problema original)

Todo informe —humano o agente— que afirme algo sobre el código **declara**:
1. repositorio y ruta local usada,
2. rama y **SHA** medidos (`git log -1 --format='%h %ci %s'`),
3. estado del árbol (`git status --porcelain`, y si está sucio, qué es),
4. fecha/hora de la medición,
5. el comando que produce cada número citado.

**Sin procedencia no es evidencia: es rumor.** Un veredicto emitido sobre una copia desalineada se retira explícitamente cuando se descubre, y la retracción se publica (cuesta menos que una corrección sobre código obsoleto).

## 6. La puerta es el PR

- El CI corre en `pull_request` hacia `main`. Nada se da por verificado "en la máquina de alguien" sin declararlo.
- Los chequeos automatizables (esquema, smoke por superficie, alineación de ramas) viven en CI, no en el portátil.
- Lo que no se puede automatizar (credenciales de la pasarela, datos de producción) se declara como **no verificado**, nunca como verde.

## 7. Quién puede hacer qué

| Acción | Dueño (Diego) | Agentes (Antigravity / Hermes) |
|---|---|---|
| Crear rama y PR | sí | sí |
| Mergear | sí | **no** |
| Borrar ramas del **remoto** | sí | **no** |
| Borrar ramas locales ya etiquetadas | sí | sí, con el tag verificado en el remoto |
| `git gc`, `fetch --prune`, `push --force`, rebase de ramas ajenas | sí | **no** (prohibido) |
| Activar ajustes del repositorio | sí | — |

**Excepción de autonomía:** con autorización explícita del dueño, un agente **puede** ejecutar la poda (local y remota) siempre que se cumpla el gate completo: los tags `archive/*` verificados **en el remoto** (`git ls-remote --tags`), `rev-list --count main..<rama>` = 0 para las muertas, y la lista de PRs abiertos leída en la misma corrida. Sin los tres, la poda es del dueño. Poda ejecutada así el 2026-09-24 (44 refs → 9; 16 ramas remotas borradas; ver `INFORME-PODA-2026-09-24.md`).

## 8. Chequeo permanente

`scripts/checkAlignment.sh` (local, antes de cualquier auditoría) y el job semanal de CI deben fallar si:
1. alguna copia local está detrás de su remoto;
2. hay ramas locales sin remoto ni tag;
3. hay ramas mergeadas sin borrar (0 commits fuera de `main` y todavía vivas);
4. algún worktree apunta a una rama muerta;
5. el árbol de la copia auditada está sucio.

## 9. Excepción documentada

Una rama puede sobrevivir a las reglas si su PR lo dice: `EXCEPCIÓN: <motivo>, vence el <fecha>`. Sin texto, no hay excepción: el triage la propone como huérfana.
