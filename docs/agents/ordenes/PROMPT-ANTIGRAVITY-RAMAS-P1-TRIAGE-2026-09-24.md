# GOAL P1 — Triage de ramas y chequeo de alineación (solo lectura)

**Goal:** que cualquiera pueda ejecutar **un comando** y saber, con datos verificables, qué copia local está desalineada, qué rama está viva, cuál es huérfana y cuál está muerta — **sin borrar nada**.
**Rama:** `chore/ramas-p1-triage`, nacida de `origin/main` (`git fetch origin && git switch -c chore/ramas-p1-triage origin/main`).
**Contexto medido el 2026-09-24** (no lo re-midas a ojo: son los valores que tus pruebas deben reproducir):

| Dato | Valor |
|---|---|
| Refs totales `refs/heads` + `refs/remotes/origin` | 44 (23 locales + 21 remotas) |
| Nombres únicos | 26 |
| Con commits fuera de `main` | 9: 190 `audit/hermes` · 25 `feature/ai-nail-tryon-legacy` · 19 `origin/diegoromerov-feature-biometric-hub` · 6 `fase-a/verdad-operativa` · 4 `backup/linea-base-osm-modifications` · 1 `feat/glowshop-niveles-a0` · 1 `feat/glowshop-precios-csv` · 1 `codex/rag-aura-r1-r4` · 1 `audit_glowapp_architecture_integrity` |
| Con 0 commits fuera de `main` | 15 |
| PRs abiertos | **2**: #10 `feat/glowshop-niveles-a0` · #12 `feat/glowshop-precios-csv` |
| Worktrees | 6 (2 sobre ramas con 0 commits fuera de `main`: `feature/saas-railway-integrated`, `fix/aura-chat-entrega-respuesta`) |
| Trampa ya vista | `refs/remotes/origin/HEAD` lo abrevia `%(refname:short)` a **`origin`**: no es una rama local |

---

## Entregable 1 · `backend/scripts/branchTriage.js`

Salida doble: **tabla legible** y **JSON** (`docs/audit/ramas-triage-<fecha>.json`) con esta fila por rama:

```
{ nombre, local (bool), remota (bool), tip, fecha_ultimo_commit, commits_fuera_de_main,
  clase: ACTIVA|HUERFANA|MUERTA, worktree: <ruta|null>, pr_abierto: <número|null|"no verificado">,
  tag_archivo: <tag|null>, protegida: bool, motivo_proteccion }
```

**Reglas (implementa exactamente estas y hazlas visibles en la salida):**
1. `commits_fuera_de_main = git rev-list --count main..<ref>` (para la remota: `main..origin/<rama>`). Si es **0** ⇒ `MUERTA`.
2. `ACTIVA` si dentro de **≤14 días**. `HUERFANA` si >14 días. **El worktree ya no decide la clase**: solo se informa (una rama con worktree abandonado hace 19 días es huérfana, no activa). La fecha de referencia es **la del día de la corrida**, no una constante.
3. `protegida = true` si: es `main`, **tiene PR abierto**, o tiene commits en los últimos 14 días. El resto de ramas con commits únicos son **propuestas** de archivo, nunca de borrado.
4. **`refs/remotes/origin/HEAD` se excluye explícitamente** del inventario (o se rotula `origin/HEAD (symref)`, nunca como rama `origin`).
5. Los conteos que imprimas (totales por clase) se **derivan de los datos**, jamás literales en el texto.

## Entregable 2 · PRs abiertos

Consulta `https://api.github.com/repos/Diegoromerov/belleza-app/pulls?state=open&per_page=100` **sin credenciales** (repo público; envía `User-Agent`). Si la respuesta no es 200 o no es JSON ⇒ `pr_abierto: "no verificado"` y **el script no puede proponer ninguna poda** en esa corrida (imprímelo como bloqueo). Nunca inventes `[]` cuando la consulta falló: ese es justo el defecto que estamos corrigiendo.

## Entregable 3 · `scripts/checkAlignment.sh`

Debe fallar (exit ≠0) listando cada violación, si:
1. alguna copia declarada está detrás de su remoto (recibe las rutas por parámetro, p. ej. `C:/beauty-app` y el worktree de la tarea);
2. hay ramas locales sin remoto **ni tag**;
3. hay ramas **muertas vivas** (`rev-list --count main..<rama>` = 0 y la rama existe);
4. algún worktree apunta a una rama muerta;
5. el árbol de una copia auditada está sucio (imprime **qué** está sucio: ruta + si es untracked).
Con todo limpio: exit 0 y un resumen de una línea (`alineado · ramas: N vivas · M propuestas de archivo · K muertas`).

## Verificación obligatoria (mutación → evidencia)

| Mutación (en un clon temporal, **no** en `C:/beauty-app`) | Resultado exigido |
|---|---|
| `git branch tmp-muerta main` (0 fuera de main) | aparece `MUERTA`, `protegida:false`, propuesta de borrado |
| `git branch tmp-viva main && commit` | `ACTIVA` con 1 commit |
| `git branch tmp-vieja <sha>` con fecha de hace 30 días | `HUERFANA` (la clase **no** cambia por tener worktree) |
| `git branch origin`… y `refs/remotes/origin/HEAD` presente | jamás aparece una rama llamada `origin` en la tabla |
| Renombrar temporalmente el remoto para que la API falle… no aplica: cortar la red o usar un `--api-url` apuntando a un host muerto | `pr_abierto: "no verificado"` + el script **se niega** a proponer poda |
| Copia local detrás de su remoto | `checkAlignment.sh` exit ≠0 nombrando la copia |
| Todo limpio | `checkAlignment.sh` exit 0 |

Pega la salida **cruda** de cada caso (comando + resultado), incluido un `head` del JSON.

## NO TOCAR

- **No se borra, mueve ni etiqueta ninguna rama en esta tarea.** Solo lectura sobre el repo.
- Prohibido `git gc`, `git worktree prune`, `git fetch --prune`, `git push --force`, `git branch -D`, `git push origin --delete`.
- No se modifica `main`, ni `.github/workflows/ci.yml`, ni `fase-a/verdad-operativa`.
- Sin dependencias nuevas: Node stdlib (`child_process`, `https`) es suficiente. Si crees que necesitas un paquete, decláralo antes en el PR.
