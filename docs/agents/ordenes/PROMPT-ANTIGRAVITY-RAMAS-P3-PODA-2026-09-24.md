# GOAL P3 — Rescate y poda: bajar de 44 referencias a 11 sin perder nada

**Goal:** que el repositorio quede con las 3 tareas vivas + `main`, con los 240 commits únicos preservados en tags verificados en el remoto, y que **ninguna** de las 156 piezas de trabajo sin commitear de los worktrees sucios se pierda.
**Rama:** `chore/ramas-p3-poda`, nacida de `origin/main`.
**Depende de:** P1 (el triage es el que decide). Si P1 no está, esta tarea lo invoca.

**Estado medido el 2026-09-24 (no lo re-descubras: reprodúcelo):** 44 refs · 26 nombres · 23 locales / 19 remotas · 6 worktrees · 2 PRs abiertos.

---

## Orden obligatorio (cada paso con su verificación antes del siguiente)

### Paso 1 · Rescate de los 4 worktrees con trabajo sin commitear  ⟵ *antes de cualquier borrado*
| Worktree | Rama | Sucios | Fecha |
|---|---|---|---|
| `.gemini/antigravity/worktrees/beauty-app/database_audit_read_only` | `feature/saas-railway-integrated` (**muerta**, 0 commits fuera de main) | **142** | 2026-09-08 |
| `.gemini/antigravity/worktrees/beauty-app/audit_glowapp_architecture_integrity` | `audit_glowapp_architecture_integrity` (huérfana, 1) | **12** | 2026-09-05 |
| `.gemini/antigravity/worktrees/beauty-app/startup_glowapp_antigravity` | `backup/linea-base-osm-modifications` (huérfana, 4) | **1** | 2026-09-07 |
| `C:/beauty-fix-aura` | `fix/aura-chat-entrega-respuesta` (**muerta**, 0) | **1** | 2026-09-24 |

Que la rama esté muerta **no** vuelve inútiles los archivos sin commitear: `rev-list --count` mide commits, no el árbol de trabajo. Para cada worktree:
1. `git -C <wt> status --porcelain -uall` y `git -C <wt> diff --stat` ⇒ lista completa (pega el `head -20` de cada uno).
2. `node backend/scripts/verifyNoVersionedSecrets.js` ⇒ si encuentra algo con pinta de credencial, **detente**: no commitees, reporta los nombres y deja el worktree intacto.
3. En un **worktree nuevo** creado desde el HEAD de esa rama (`git worktree add ../rescate-<nombre> -b archive/<nombre>-2026-09-24 <rama>`), copia el árbol de trabajo sucio (`git -C <origen> diff > /tmp/<nombre>.patch` para lo versionado y copia explícita de los untracked), `git add -A && git commit -m "archive: rescate <worktree> 2026-09-24"`, y `git push -u origin archive/<nombre>-2026-09-24`.
4. Verifica con `git -C <wt> status --porcelain -uall | wc -l` = **0** antes de pasar al worktree siguiente.
Si decides **descartar** algún archivo, escríbelo: `DESCARTADO: <ruta> — motivo` en el cuerpo del PR. Silencio no es una decisión.

### Paso 2 · Tags de archivo de las 6 ramas con commits únicos (ninguna de ellas es `main`/`fase-a`/los 2 PRs)
**Toma siempre el SHA de `git rev-parse <rama>` en el momento de ejecutar**, nunca de una lista escrita a mano. Estos son los valores medidos el 2026-09-24 y sirven **solo como contraste**:

| Rama | commits fuera de `main` | tip medido 2026-09-24 | fecha |
|---|---|---|---|
| `audit/hermes` | 190 | `434f7f21` | 2026-07-19 |
| `feature/ai-nail-tryon-legacy` | 25 | `a1c7002d` | 2026-06-08 |
| `origin/diegoromerov-feature-biometric-hub` | 19 | `d99ed223` | 2026-08-01 |
| `backup/linea-base-osm-modifications` | 4 | `ea8077bb` | 2026-09-07 |
| `codex/rag-aura-r1-r4` | 1 | `68ce4b4e` | 2026-08-13 |
| `audit_glowapp_architecture_integrity` | 1 | `7dd6fff3` | 2026-09-05 |

**Si tu `git rev-parse` no coincide con estos valores, detente y repórtalo** (la lista cambió y hay que reclasificar). Trampa ya vista: no confundas el **tip** de la rama con su **merge-base** con `main` (en `codex/rag-aura-r1-r4` el merge-base es `0ee1eb37` y el tip `68ce4b4e`; intercambiarlos etiqueta el commit equivocado).

`git tag -a archive/<rama-slug>-2026-09-24 -m "archivo pre-poda 2026-09-24 (<n> commits únicos)" $(git rev-parse <rama>)` y `git push origin --tags`.
**Verificación obligatoria antes de seguir:** `git ls-remote --tags origin | grep -c 'archive/'` ≥ **6**, y una prueba real de reconstrucción: `git switch -c prueba-archivo archive/audit/hermes-2026-09-24 && git log --oneline -1 && git switch main && git branch -d prueba-archivo`.

### Paso 3 · Poda local de las 15 muertas
`baseline-v1-stable`, `chore/retirar-orquestador-legado`, `docs/rag-eol-corrections-2026-09-22`, `feat/glowshop-catalogo-autorizado`, `feat/glowshop-catalogo-niveles`, `feat/glowshop-correcciones-a0`, `feat/glowshop-precios-api`, `feat/glowshop-tienda-operable-b01`, `feature/saas-railway-integrated`, `fix/agentes-esquema-columnas`, `fix/audit-360-remediation`, `fix/aura-chat-entrega-respuesta`, `fix/rag-filtros-citas-trazas`, `fix/rag-p0-port-r1` (+ la remota `pr9`).
- **Gate correcto (lección medida hoy):** `git rev-list --count main..<rama>` = **0** ⇒ borrar con `-D`. **NO uses `git branch -d` como gate**: `-d` compara contra **HEAD**, no contra `main`, así que se niega con ramas que sí están contenidas en `main` (hoy se negó con 5 `feat/glowshop-*` que tenían 0 commits fuera de `main`, porque HEAD era otra rama). Si te fías de `-d`, o paras la fase sin motivo o acabas usando `-D` sin haber comprobado nada. Comprueba con `--is-ancestor` y `rev-list --count`, pega la salida, y borra con `-D`.
- Antes de cada borrado: `git rev-list --count main..<rama>` debe imprimir **0**. Pega la salida.
- Worktrees primero: ninguna de estas ramas se borra si aún tiene worktree (Paso 4).

### Paso 4 · Worktrees y huérfanas locales
`git worktree remove <ruta>` para los 4 rescatados + `git worktree prune`. **Si `remove` se queja de cambios sin commitear, no uses `--force`: vuelve al Paso 1.**
Luego `git branch -D` de las huérfanas locales ya etiquetadas en el Paso 2 (`audit/hermes`, `audit_glowapp_architecture_integrity`, `backup/linea-base-osm-modifications`, `codex/rag-aura-r1-r4`, `feature/ai-nail-tryon-legacy`).

### Paso 5 · Lista de borrados del REMOTO (no la ejecutes: la ejecuta el dueño)
Emite un bloque de comandos exactos, uno por rama remota a borrar (13 muertas + `pr9` + 3 huérfanas), precedido de la verificación por rama (`git ls-remote --heads origin <rama>` y `git rev-list --count main..origin/<rama>`). **Prohibido `git push origin --delete` en esta tarea.**

---

## Estado final exigido

| Métrica | Hoy | Objetivo | Comando |
|---|---|---|---|
| refs (`heads` + `remotes/origin`) | 44 | 11 | `git for-each-ref refs/heads refs/remotes/origin \| wc -l` |
| locales | 23 | 5 | `git for-each-ref refs/heads \| wc -l` |
| worktrees | 6 | 2 | `git worktree list \| wc -l` |
| tags `archive/*` (locales y remotos) | 0 | ≥ 6 / ≥ 6 | `git tag -l 'archive/*' \| wc -l` · `git ls-remote --tags origin \| grep -c archive/` |
| ramas con commits únicos fuera de main | 9 | **3** (las 2 con PR + `fase-a`) | `commits_fuera_de_main > 0` |

## Verificación por mutación (en un **clon temporal**, jamás en `C:/beauty-app`)

| Mutación | Resultado exigido |
|---|---|
| `git branch tmp-muerta main` + intento de poda | se borra con `-d` sin tag (0 commits fuera de main) |
| `git branch tmp-unica main` + 1 commit + intento de poda | **se niega** a borrarla como muerta; exige tag primero |
| `git branch tmp-unica2 main` + 1 commit + tag **solo local** | `git branch -D` **se niega**: exige el tag en el remoto |
| `git worktree add ../tmp-wt tmp-unica2` + archivo modificado + `git worktree remove ../tmp-wt` | falla nombrando el archivo sucio (evidencia de la guarda) |
| Intento de podar `fase-a/verdad-operativa`, `feat/glowshop-niveles-a0` o `feat/glowshop-precios-csv` | **se niega** por PR abierto / rama protegida |
Sin el clon temporal, la mutación no vale.

## NO TOCAR (violación = tarea rechazada)

- **No borres nada del remoto** (`push --delete`), no hagas `gc`, `worktree prune` a ciegas, `push --force`, ni rebase de ramas ajenas.
- **Intocables:** `main`, `fase-a/verdad-operativa` (trabajo vivo, le falta PR), `feat/glowshop-niveles-a0` (**PR #10**), `feat/glowshop-precios-csv` (**PR #12**).
- No toques el clon fósil (`C:/Users/Compu casa/belleza-app`) más allá del `fetch` de diagnóstico que Diego autorice; **no** lo borres.
- No toques `ci.yml` ni la Fase A; esta tarea no arregla código.
