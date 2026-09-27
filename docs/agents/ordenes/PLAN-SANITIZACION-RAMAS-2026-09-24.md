# Plan de saneamiento de ramas — Belleza App / GlowApp

**Fecha de medición:** 2026-09-24 · **Repo bueno:** `C:/beauty-app` ↔ `github.com/Diegoromerov/belleza-app` (`origin`) · **Auditoría previa:** `AUDITORIA-GRAFO-RAMAS-2026-09-24.md`
**Principio rector:** nada se borra sin red de seguridad verificable; ninguna fase arranca sin que la anterior cierre con conteos.

---

## 1. ¿Hay información suficiente? — Sí, con dos huecos y dos sorpresas

### Verificado por mí hoy (base del plan)

| Dato | Valor |
|---|---|
| Referencias totales | **44** (23 locales + 21 remotas) · **26 nombres únicos** |
| Ramas con commits fuera de `main` | **9** — de las cuales **2 tienen PR abierto** y 1 es el trabajo actual |
| Ramas con 0 commits fuera de `main` (muertas) | **15** |
| Commits que viven **solo** en ramas huérfanas | **240** (190 `audit/hermes` + 25 `ai-nail-tryon-legacy` + 19 `biometric-hub` + 4 `backup/osm` + 1 + 1) |
| Worktrees registrados | **6**, de los cuales **4 con trabajo sin commitear**: 12, 142, 1 y 1 entradas |
| Clon fósil | `C:/Users/Compu casa/belleza-app`, `main = 4f803a0b` (2026-08-04), **1.363 commits detrás**, 22.036 archivos versionados borrados |
| PRs abiertos en GitHub | **2**: **#12** `feat/glowshop-precios-csv` → main · **#10** `feat/glowshop-niveles-a0` → main |
| `fase-a/verdad-operativa` | 6 commits, pusheada, **sin PR** (es la única de las tres vivas sin PR) |

### Las dos sorpresas que cambian el plan

1. **Hay 2 PRs abiertos y ninguna de las ramas "activas" que yo había marcado por fecha es basura.** `feat/glowshop-niveles-a0` (#10) y `feat/glowshop-precios-csv` (#12) **quedan protegidas**: el triage automático debe leer `state=open` de la API antes de proponer un borrado. Sin ese chequeo, la poda habría borrado dos PRs vivos.
2. **Cuatro worktrees tienen trabajo sin commitear** (12, 142, 1 y 1 entradas) y dos de ellos llevan ~3 semanas parados (`audit_glowapp_architecture_integrity` 2026-09-05 con 12, `database_audit_read_only` 2026-09-08 con **142**). Borrarlos sin rescatar sería destruir trabajo. **Por eso la Fase 0 es rescate, no poda.**

### Los dos huecos que solo puede cerrar Diego (o un token)

- **Ajustes del repositorio en GitHub**: si `delete_branch_on_merge` está activo. No puedo leerlo sin credencial. Se activa en Settings → General → Pull Requests.
- **El clon fósil**: sus refs remotas están congeladas en agosto, así que **no se puede saber si guarda commits locales únicos** sin un `git fetch`. Ese fetch es la Fase 0.3, antes de tocarlo.

---

## 2. Plan por fases

### Fase 0 — Rescate y congelación (NO se borra nada) · 0,5 día
| # | Acción | Comando | Criterio de cierre |
|---|---|---|---|
| 0.1 | Inventariar el trabajo sin commitear de los 4 worktrees sucios | `for w in <4 rutas>; do git -C "$w" status --porcelain \| wc -l; git -C "$w" diff --stat; done` | Lista con archivo y tamaño por worktree |
| 0.2 | Decidir por cada uno: commitear a `archive/<worktree>-2026-09-24`, copiar fuera del repo, o descartar (declarándolo por escrito) | según decisión | Los 156 archivos sin commitear tienen destino escrito |
| 0.3 | **Fetch en el clon fósil** y comprobar si guarda algo único | `git -C "C:/Users/Compu casa/belleza-app" fetch origin && git -C … branch --no-merged origin/main && git -C … rev-list --count origin/main..HEAD` | Si hay commits únicos → `git bundle create fosil-2026-08.bundle --all` (o push de `archive/fosil-2026-09-24`) antes de abandonarlo |
| 0.4 | Congelar el fósil | renombrar a `belleza-app-FOSSIL-2026-08-04` o dejar `FOSSIL.txt` con fecha y regla "no usar" | Ningún agente vuelve a leerlo; queda escrito en el repo |
**Puerta:** ningún borrado hasta que 0.1-0.4 cierren.

### Fase 1 — Red de seguridad: tags de archivo · 0,25 día
| # | Acción | Comando | Criterio de cierre |
|---|---|---|---|
| 1.1 | Etiquetar las **6 huérfanas** (las que tienen commits únicos y ningún PR) | `git tag -a archive/<rama>-2026-09-24 -m "archivo pre-poda" <tip>` (para la remota: `origin/<rama>`) | 6 tags creados |
| 1.2 | Publicar los tags | `git push origin --tags` | `git ls-remote --tags origin \| grep -c archive/` ≥ 6 |
| 1.3 | Probar la recuperabilidad | `git switch -c prueba-archivo archive/audit/hermes-2026-09-24 && git log -1` y borrar la prueba | Se puede reconstruir la rama desde el tag |
**Puerta:** los tags deben existir **en el remoto** antes de cualquier `--delete`.

### Fase 2 — Poda de las muertas (0 commits fuera de `main`) · 0,25 día
| # | Acción | Comando | Criterio de cierre |
|---|---|---|---|
| 2.1 | Borrar en local (nunca `-D`: `-d` falla si la rama no está mergeada, y ese fallo es la red) | `git branch -d <rama>` | 23 → 8 refs locales |
| 2.2 | Borrar en el remoto desde la GitHub UI (o `git push origin --delete <rama>` con token en variable de entorno) | 13 ramas + `pr9` (ref residual del PR #9) | `git ls-remote --heads origin \| wc -l` 19 → 6 |
| 2.3 | Verificar | `git for-each-ref refs/heads \| wc -l` · `git ls-remote --heads origin \| wc -l` | 8 y 6 |
**Regla de oro justo antes de cada borrado:** `git rev-list --count main..<rama>` debe dar **0**; si da otra cosa, se detiene la fase.
**PROTEGIDAS — no se tocan:** `feat/glowshop-niveles-a0` (**PR #10**), `feat/glowshop-precios-csv` (**PR #12**), `fase-a/verdad-operativa` (trabajo vivo, **falta su PR**).

### Fase 3 — Worktrees y ramas huérfanas · 0,5 día
| # | Acción | Comando | Criterio de cierre |
|---|---|---|---|
| 3.1 | Retirar los worktrees (falla si están sucios: esa es la garantía de que el rescate de Fase 0 se hizo) | `git worktree remove <ruta>` · `git worktree prune` | `git worktree list` = 2 (objetivo) |
| 3.2 | Borrar las ramas huérfanas locales, ya etiquetadas | `git branch -D <rama>` (aquí sí `-D`: no están mergeadas y el tag es la red) | 8 → 4 refs locales |
| 3.3 | Borrar las huérfanas del remoto (solo 3 lo están): `audit/hermes`, `codex/rag-aura-r1-r4`, `diegoromerov-feature-biometric-hub` | GitHub UI / token | 6 → 3 remotas |
| 3.4 | Verificación final | ver §3 | — |

### Fase 4 — No reincidir · 0,5 día
| # | Acción | Quién | Criterio |
|---|---|---|---|
| 4.1 | `scripts/branchTriage.js` (clasifica + dry-run, consulta PRs abiertos) y `scripts/checkAlignment.sh` | Antigravity (prompt P1) | Falla ≠0 si hay desalineación, ramas mergeadas sin borrar, o local sin remoto ni tag |
| 4.2 | Política escrita en el repo (`docs/policies/ramas.md` + sección en `AGENTS.md`) + cableado del chequeo en CI semanal | Antigravity (prompt P2) | El CI corre el chequeo y falla cuando corresponde |
| 4.3 | `delete_branch_on_merge=true` · `git config --global fetch.prune true` | **Diego** (UI) | El PR mergeado borra su rama solo |
| 4.4 | Protocolo de procedencia en `AGENTS.md` (todo veredicto declara repo/rama/sha/estado) | Antigravity (P2) | Un informe sin procedencia se rechaza |

---

## 3. Estado final objetivo y verificación

| Métrica | Hoy | Objetivo | Comando |
|---|---|---|---|
| Referencias de rama | 44 | **11** | `git for-each-ref refs/heads refs/remotes/origin \| wc -l` |
| Nombres únicos | 26 | **5** (`main`, `fase-a/verdad-operativa`, `feat/glowshop-niveles-a0`, `feat/glowshop-precios-csv`, `origin/HEAD`) | `… --format='%(refname:short)' \| sort -u \| wc -l` |
| Ramas locales | 23 | **5** | `git for-each-ref refs/heads \| wc -l` |
| Ramas remotas | 19 | **4** | `git ls-remote --heads origin \| wc -l` |
| Worktrees | 6 | **2** | `git worktree list \| wc -l` |
| Commits preservados | 240 solo en huérfanas | **240 en 6 tags `archive/*`** | `git tag -l 'archive/*'` |

**Reversión:** cada borrado de rama con commits únicos es recuperable con `git switch -c <rama> archive/<rama>-2026-09-24`. Una rama con 0 commits fuera de `main` no necesita reversión: su contenido ya está en `main`. El clon fósil no se destruye hasta que 0.3 cierre.

## 4. Reparto de responsabilidades

| Rol | Hace | No hace |
|---|---|---|
| **Diego** (dueño) | Decide sobre las 6 huérfanas y el fósil; borra ramas del **remoto**; activa el setting; mergea PRs | — |
| **Antigravity** | Fase 0.1-0.2 (rescate, con la lista revisada por Diego), Fase 4 (herramientas y política). Es el ejecutor de P1/P2/P3 | No borra ramas, no hace `gc`/`prune`/`force-push`, no toca el remoto sin que Diego lo autorice |
| **Hermes** | Audita cada fase con conteos antes/después; produce los prompts | No borra nada ni escribe en ramas ajenas |
