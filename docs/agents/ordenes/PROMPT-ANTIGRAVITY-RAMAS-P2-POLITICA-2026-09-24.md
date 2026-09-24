# GOAL P2 — La política vive en el repo y el chequeo corre en CI

**Goal:** que las reglas de ramas dejen de estar en un chat y estén en el repositorio, aplicadas por un job que falla cuando se violan — **sin bloquear los PRs de los demás**.
**Rama:** `docs/ramas-p2-politica`, nacida de `origin/main`.
**Depende de:** P1 (`scripts/branchTriage.js`, `scripts/checkAlignment.sh`). Si P1 no está mergeado, este PR se abre contra la rama de P1 declarándolo en el PR (una sola excepción permitida a la regla "nunca desde otra rama", y se dice).

---

## Entregable 1 · `docs/policies/ramas.md`

Copia el contenido de la política adjunta (te la paso completa en el mensaje) adaptando rutas y sin inventar nada. Debe contener, como mínimo, estas secciones: nombres permitidos y prohibidos · ciclo de vida (nacimiento desde `origin/main`, una rama = una tarea = un PR, caducidad 5/14 días, borrado al mergear, tag `archive/<rama>-<yyyy-mm-dd>` antes de borrar algo con commits únicos) · protecciones (PR abierto, ≤14 días, `main`) · worktrees (uno por tarea, se retira con la tarea, `remove` falla si hay trabajo sin commitear) · **procedencia obligatoria del veredicto** (repo, rama, SHA, `git status`, fecha, comando por cada número) · la puerta es el PR · quién puede hacer qué · qué chequea `checkAlignment.sh`.

## Entregable 2 · `AGENTS.md`

Añade una sección corta (≤25 líneas) al principio, con el resumen operativo y el enlace a `docs/policies/ramas.md`. **No reescribas `AGENTS.md`**: añades una sección y respetas lo que ya dice (rama + PR, prohibido commitear a `main`).

## Entregable 3 · CI

Dos piezas, y **no una sola**:

1. **Job semanal + manual** (`.github/workflows/branch-hygiene.yml`): `on: schedule` (semanal) + `workflow_dispatch`, que corre `checkAlignment.sh` con `continue-on-error: false`. Aquí **sí** falla por el estado global de las ramas: es un informe, no una puerta de PR.
2. **Chequeo por PR, ligero** (paso dentro del workflow existente o job aparte en `pull_request`): que **no** mire el estado global de ramas (eso bloquearía a todo el mundo cuando una rama vieja esté sucia) y solo verifique lo que el autor controla:
   - la rama del PR nace de `origin/main` (`git merge-base --is-ancestor origin/main HEAD` falla ⇒ aviso, no error, si el PR declara rama padre),
   - no hay marcadores de conflicto (reutiliza `checkNoConflictMarkers.js`),
   - no se versionan secretos (reutiliza `verifyNoVersionedSecrets.js`).
   **Prohibido** que este job ejecute los 5 chequeos de `checkAlignment.sh`: bloquearía los PRs por basura ajena.

**Trampa a evitar (ya nos pasó):** `ci.yml` tuvo marcadores de conflicto en las líneas 60/84/90 y por eso **nunca corrió un run**. Valida con `python -c "import yaml;yaml.safe_load(open('<archivo>'));print('YAML OK')"` **y** con `workflow_dispatch` disparado de verdad desde la UI, pegando el run y su URL.

## Entregable 4 · Lista de acciones del dueño (no las ejecutes)

En el cuerpo del PR, un checklist verificable para Diego:
- [ ] Settings → General → Pull Requests → **`delete_branch_on_merge` = on**
- [ ] `git config --global fetch.prune true`
- [ ] (opcional) `git config --global alias.triage '!git fetch -p && node backend/scripts/branchTriage.js'`
- [ ] Abrir el PR de `fase-a/verdad-operativa` (es la única rama viva **sin** PR)

## Verificación obligatoria (mutación → evidencia)

| Mutación | Resultado exigido |
|---|---|
| Poner un marcador `<<<<<<< HEAD` en un archivo versionado y abrir/actualizar el PR | el job por PR falla con el archivo y la línea |
| Dejar una rama muerta viva en el repo y disparar el job semanal a mano (`workflow_dispatch`) | el job falla nombrando la rama y su conteo |
| Revertir ambas | los dos jobs verdes, con la URL del run pegada |
| `yaml.safe_load` de los dos workflows | `YAML OK` |

## NO TOCAR

- No modifiques los pasos de RLS/tenant ya reparados en `ci.yml` (`prepareRlsDatabase.js`, `verifyTenantIsolation.js`).
- No borres ramas ni ejecutes la poda: esta tarea **solo escribe política y CI**.
- No agregues acciones de terceros sin fijar la versión (`@v4`, no `@main`).
- No toques `main` directamente: todo por PR.
