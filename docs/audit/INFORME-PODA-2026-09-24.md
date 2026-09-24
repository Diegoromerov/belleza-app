# Informe de ejecución — Poda de ramas 2026-09-24

**Ejecutado por:** Hermes, bajo autorización explícita de autonomía del dueño ("eres autónomo en la toma de decisión").
**Repo:** `C:/beauty-app` ↔ `github.com/Diegoromerov/belleza-app` · **Base de la medición:** `main = f5a1b4fc`
**Sustituye a:** las Fases 0-3 de `PLAN-SANITIZACION-RAMAS-2026-09-24.md` (ejecutadas, no propuestas).

---

## 1. Resultado

| Métrica | Antes | Después | Comando |
|---|---|---|---|
| Referencias (`heads` + `remotes/origin`) | 44 | **9** | `git for-each-ref refs/heads refs/remotes/origin \| wc -l` |
| Ramas locales | 23 | **4** | `fase-a/verdad-operativa`, `feat/glowshop-niveles-a0`, `feat/glowshop-precios-csv`, `main` |
| Ramas remotas | 19 | **4** | las mismas cuatro |
| Worktrees | 6 | **2** | `C:/beauty-app` + `setup_glowguide_architecture` |
| Ramas con commits fuera de `main` | 9 | **3** | las dos de PR abierto + `fase-a` |
| Tags `archive/*` | 0 | **8 locales / 17 refs remotas** | `git ls-remote --tags origin \| grep -c archive/` |
| PRs abiertos | 2 | **2 (intactos)** | #10 `feat/glowshop-niveles-a0`, #12 `feat/glowshop-precios-csv` |
| `git status` de la copia buena | 2 | **2** (mis 2 planes en `.hermes/plans/`, sin versionar) | `git status --porcelain -uall` |

**Nada se perdió:** las únicas ramas con commits propios son las tres protegidas. Todo lo demás está en `main` (0 commits fuera) o en un tag verificado.

---

## 2. Lo ejecutado, con evidencia

### Fase 0 · Rescate (398 entradas sin commitear que una poda ingenua habría borrado)
| Worktree | Rama | Sucios | Resultado |
|---|---|---|---|
| `database_audit_read_only` | `feature/saas-railway-integrated` | **376** | commit `426fb662` · **369 archivos, 105.798 inserciones, 2.425 borrados** · tag `archive/rescate-database_audit_read_only-2026-09-24` (publicado) |
| `audit_glowapp_architecture_integrity` | idem | 20 | commit `178bfbaf` · 20 archivos, 49.473 inserciones (9 SKILL.md + 9 informes F7/F8 + manual PDF) · tag `archive/rescate-audit_glowapp-2026-09-24` |
| `startup_glowapp_antigravity` | `backup/linea-base-osm-modifications` | 1 | commit `e44648aa` (gitlink del repo embebido) · tag `archive/rescate-startup_glowapp-2026-09-24` |
| `C:/beauty-fix-aura` | `fix/aura-chat-entrega-respuesta` | 1 | commit `4500a6e7` (WO de 201 líneas) · tag `archive/rescate-aura-chat-wo-2026-09-24` |
| Repo **embebido** `.agents/skills/flutter-expert-v2` | (repo propio, 1 commit) | — | hueco detectado: el gitlink no guarda contenido ⇒ bundle de 159 KB en `rescates/` + tag `archive/flutter-expert-v2-main-2026-09-24` |

Cero hallazgos de secretos: 0 por nombre de archivo y 0 por patrones de clave en el contenido staged.
Cada worktree quedó en `sucios = 0` **verificado antes** de retirarlo.

### Fase 1 · Tags de archivo (la red de seguridad)
Creados y **publicados** desde `git rev-parse` en tiempo de ejecución, con contraste contra la tabla medida (el script aborta si no coincide):
`archive/audit-hermes-2026-09-24` (190 commits) · `archive/feature-ai-nail-tryon-legacy-2026-09-24` (25) · `archive/diegoromerov-feature-biometric-hub-2026-09-24` (19) · `archive/codex-rag-aura-r1-r4-2026-09-24` (1) + los 4 de rescate + el del repo embebido.
Prueba de reconstrucción real: `git switch -c prueba-archivo archive/audit-hermes-2026-09-24` → 434f7f21 con **190 commits** fuera de `main` ✓ (rama de prueba borrada después).

### Fase 2 · Poda local
14 ramas borradas con `-D` **tras** comprobar `rev-list --count main..<rama>` = 0 o la cobertura por tag; incluidas las dos que solo contenían mi commit de rescate (`feature/saas-railway-integrated`, `fix/aura-chat-entrega-respuesta`) y las 5 huérfanas locales.
`git remote prune origin` → retiró `origin/pr9` (ref remota obsoleta: la rama ya no existía en GitHub).

### Fase 3 · Worktrees
4 worktrees retirados (`database_audit_read_only`, `audit_glowapp_architecture_integrity`, `beauty-fix-aura` y `startup_glowapp_antigravity`).
El cuarto **no se podía retirar**: `fatal: working trees containing submodules cannot be moved or removed` (el repo embebido que rescaté lo convirtió en submódulo) ⇒ `rm -rf` + `git worktree prune`, con el contenido ya preservado en tag **y** bundle.

### Fase 5 · Poda del remoto (16 ramas)
3 huérfanas (gate: tag verificado en el remoto y `merge-base --is-ancestor origin/<rama> <tag>^{}`) + 12 muertas (gate: `rev-list --count main..origin/<rama>` = 0) + `fix/aura-chat-entrega-respuesta`.
Protegidas y jamás tocadas: `main`, `fase-a/verdad-operativa`, `feat/glowshop-niveles-a0` (#10), `feat/glowshop-precios-csv` (#12) — los dos PRs siguen abiertos y sus ramas presentes.

---

## 3. Hallazgos que cambiaron el plan en plena ejecución

1. **`git branch -d` NO sirve como gate.** Compara contra **HEAD**, no contra `main`: se negó con 5 ramas `feat/glowshop-*` que tenían 0 commits fuera de `main` (porque HEAD era `feat/glowshop-niveles-a0`). El gate correcto es `rev-list --count main..<rama>` = 0 **y** `merge-base --is-ancestor <rama> main`. **El prompt P3 que escribí tenía este fallo; ya está corregido.** Quien se fíe de `-d` o se atasca sin motivo o acaba usando `-D` sin haber comprobado nada.
2. **El clon fósil no era basura: es divergente.** Tras `fetch`, su `main` tiene **29 commits que ya no están en `origin/main`** y el conjunto de sus refs guarda **331 commits únicos** (14 ramas). Además 5 de esas ramas se llaman `feature/implement-encryption-at-rest`, `feature/implement-privacy-endpoints`, `feature/integrate-secret-manager`, `feature/migrate-env-to-secrets`, `feature/secret-manager-selection`. **El repo es público** (la API responde 200 sin token) ⇒ **decisión: NO publicar esas ramas en GitHub**; se preservaron en un bundle local de **319 MB** (`rescates/fosil-belleza-app-HEAD-4f803a0b-2026-09-24.bundle`), verificado clonándolo: 14 ramas + 8 tags dentro, los 14 tips presentes, contenido recuperable (el árbol de `feature/migrate-env-to-secrets` se lista), y el commit divergente `4f803a0b` está dentro. Marcador `FOSSIL.txt` escrito dentro de la carpeta con la cifra correcta (331, no la primera estimación de ~131).
3. **Los worktrees sucios eran trabajo real, no residuo:** 105.798 líneas de backend (incluidas bajas de `salonController.js` y `salonRoutes.js`) que iban a desaparecer con el primer `git worktree remove`.

## 4. Mis propios errores en esta ejecución (declarados)

1. **La comprobación de PRs por API falló en la corrida de la poda remota** (`/tmp_prs.txt: Permission denied`, mapeo de `/tmp` en MSYS). La protección de las dos ramas con PR **no** vino del API sino de la lista fija del script. Repetí la consulta después y confirmé los 2 PRs abiertos y sus ramas intactas — pero el gate que anuncié no era el que operó. En la política queda escrito que la lista de PRs debe leerse **en la misma corrida**.
2. **Moví fuera del repo 5 archivos de `.hermes/plans/`, de los cuales 3 estaban versionados** (`git status` lo delató como ` D`). Restaurados con `git checkout --` y devueltos mis 2 planes: la copia quedó como estaba (2 untracked), sin pérdida.
3. **Mi verificación del bundle estaba mal namespaceada**: conté `refs/heads` de un clon de bundle (siempre 0) y concluí "0 ramas". Corregido: los refs llegan a `refs/remotes/*` → 14 ramas + 8 tags.
4. La primera cifra que puse en `FOSSIL.txt` (~131) sumaba commits por rama; la medida correcta de "lo que se perdería" es **331** (`rev-list --count --all --not origin/main`). Marcador corregido.

## 5. Red de seguridad: cómo recuperar cualquier cosa

| Qué | Cómo |
|---|---|
| Una rama huérfana | `git switch -c <nombre> archive/<nombre>-2026-09-24` |
| El trabajo de un worktree retirado | `git switch -c rescate archive/rescate-<worktree>-2026-09-24` |
| El repo embebido flutter-expert-v2 | `git clone rescates/flutter-expert-v2-2026-09-24.bundle` o `git switch -c x archive/flutter-expert-v2-main-2026-09-24` |
| **331 commits del fósil** | `git clone rescates/fosil-belleza-app-HEAD-4f803a0b-2026-09-24.bundle fosil-restaurado` |
| Una muerta borrada | nada que recuperar: su contenido es ancestro de `main` (0 commits fuera) |

## 6. Pendiente (no lo hice yo)

1. **PR de `fase-a/verdad-operativa`** — es la única rama viva sin PR: `https://github.com/Diegoromerov/belleza-app/pull/new/fase-a/verdad-operativa`
2. **`delete_branch_on_merge = on`** en Settings → General (requiere UI/token del dueño).
3. **P1 y P2 para Antigravity siguen vigentes** (herramientas de triage/alineación y política en CI). **P3 ya está ejecutado**: no hace falta pedírselo; se conserva como registro de procedimiento.
4. Decidir si algo del fósil (331 commits) merece publicarse tras revisar esas 5 ramas con nombres sensibles.
