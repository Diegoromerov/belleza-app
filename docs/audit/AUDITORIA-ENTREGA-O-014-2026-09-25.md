# AUDITORÍA — ORDEN A · O-014 «el guardián tiene que ser del repo, y su fallo tiene que verse»

**Auditor:** Hermes (Arquitecto). **Fecha:** 2026-09-25.
**Entrega:** rama `chore/guardian-en-el-repo` @ **`0a32f718`** (`chore(guardian): version runner in repo, honest exit codes, weekly partes and 14-day freshness rule (O-014)`).
**Procedencia verificada:** `git merge-base --is-ancestor b1739561 HEAD` ⇒ **SÍ** (base declarada correcta); `git status --porcelain` ⇒ **0 entradas**; **no** contiene `c888ac1f` (mi último commit de KB) ⇒ rebasar antes de mergear (sin solape de archivos: él tocó `estadoKB.js`, `guardianBelleza.sh`, 2 tests y `docs/agents/partes/*`; yo `DEUDA/ESTADO-ACTUAL/COLA`).
**Diff:** 6 archivos, +286 −0.

## Veredicto: **RECHAZADA** — Cargo 1 (runner) · Cargo 2 (R4) **aceptado en sustancia** y conservable

No es un rechazo de forma: el versionado está bien hecho, el exit honesto está en el código y R4 funciona —medido—. Se rechaza porque **el runner no puede ejecutar el chequeo en el único entorno donde corre** (git-bash/MSYS) y porque **ningún test cubre ese camino real**, de modo que el verde del walkthrough (`exit=0`) **no se reproduce**: con su propio comando, en su propio worktree, da **`EXIT=1`**.

## 1. Cargo 1 — el runner existe y es honesto en el papel, pero el camino real está roto

Lo que está bien (`backend/scripts/guardianBelleza.sh`, 68 líneas):

- Versionado en el repo, sin tocar el cron ni el perfil.
- Exit honesto en el código: `exit $KB_EXIT` cuando el chequeo corre, **`exit 1`** cuando no está disponible, y `NO VERIFICADO (la API no respondió)` / `NO VERIFICADO (la consulta ls-remote no respondió)` en las secciones de red — nada de secciones vacías silenciosas. Cumple lo pedido.

Lo que está mal — **la causa raíz**:

```bash
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"     # ⇒ /c/Users/Compu casa/...  (ruta MSYS)
...
"$NODE_CMD" "$S" --check                        # $S = /c/Users/.../estadoKB.js
```

`pwd` en MSYS devuelve `/c/...`; `node.exe` es un programa **nativo Windows** que no entiende esa forma y la resuelve como relativa ⇒ `CANNOT FIND MODULE 'C:\c\Users\...\backend\scripts\estadoKB.js'`.

**Medido por mí, en SU worktree, con SU comando del walkthrough** (que él publica con `exit=0`):

| Comando | Salida al final | ¿Cita su walkthrough? |
|---|---|---|
| `cd setup_glowguide_architecture && bash backend/scripts/guardianBelleza.sh` | `Node.js v24.19.0` · **`exit=1`** | Su §2 «Case 1» dice `exit=0` ⇒ **no reproducible** |
| `bash C:/.../setup_glowguide_architecture/backend/scripts/guardianBelleza.sh` | `Error: Cannot find module 'C:\c\Users\...\estadoKB.js'` · **`exit=1`** | — |
| `cd .../backend && node scripts/estadoKB.js --check` | **`EXIT=0`**, `desalineaciones=0` | ⇒ el defecto está **en el runner**, no en el chequeo |

**Y el hueco de prueba es la causa de que haya pasado invisible:** los **tres** casos de `guardianBelleza.test.js` —incluido el «Caso Verde»— fijan `ESTADO_KB_SCRIPT` a un **mock**; **ningún** caso ejecuta el chequeo real. El único camino no cubierto es exactamente el roto. Es **R-07** otra vez: *un test que no ejercita el camino real no cierra la tarea*.

## 2. Cargo 2 — Regla de frescura R4: **✓ correcta y probada**

Medido por mí (worktree detachado en `0a32f718`, suite aparte):

| Prueba | Resultado |
|---|---|
| Su suite `estadoKBFreshness.test.js` | **2/2 PASS** ✓ |
| Mi mutación: `parte-2026-09-25.md` ⇒ `parte-2026-08-01.md` | `--check` **EXIT=1** con `| R4 | «docs/agents/partes/» no tiene ningún parte de estado en los últimos 14 días |` ✓ (la 2ª desalineación era `R1` por mis propios archivos movidos) |
| Restaurado el parte al día | `--check` **EXIT=0**, `desalineaciones=0` ✓ |
| `estadoKB.js:45 process.chdir(root)` | la regla mira la raíz del repo aunque el cwd sea `backend/` ✓ |
| ¿`estadoKB --check` cableado en CI o en npm scripts? | **No** (solo lo invoca el runner) ⇒ **R4 no puede romper el pipeline** ✓ (riesgo descartado) |

## 3. Hallazgo de alcance — a quién inspecciona el guardián

El runner versionado inspecciona **la copia donde vive el script** (`ROOT_DIR = $SCRIPT_DIR/../..`), no la copia desde la que se lo invoca ni `C:/beauty-app`:

| Invocación | «copia inspeccionada» | Desalineación |
|---|---|---|
| runner **del perfil** (`~/AppData/Local/hermes/scripts/guardian-belleza.sh`) | **`C:/beauty-app`** (`feat/glowshop-niveles-a0`) | **`R1`: los 2 planes de `.hermes/plans/`** ⇒ `exit=1` |
| runner **versionado** invocado desde el worktree KB | mi **worktree de medición** (`scratch/o014/wt`) | `exit=1` (por la ruta rota, no por el repo) |
| el parte commiteado, sobre su propio worktree | `setup_glowguide_architecture` | «Desalineaciones: **Ninguna**» |

⇒ Si el cron lo invoca (workdir = worktree de la KB), el parte dirá **«0 desalineaciones»** mientras el **banco de trabajo del Dueño** (`C:/beauty-app`) tiene `R1`. El parte declara qué copia inspeccionó ✓ (honesto), pero el sistema quedaría **sin vigilar la copia que importa**. Falta un parámetro (`GUARDIAN_REPO`) y una decisión explícita de default.

Además, el parte commiteado nace obsoleto: cita `rama chore/guardian-en-el-repo @ b1739561` (el commit que lo contiene es `0a32f718`), declara `EXIT 0 (Alineado)` —**no reproducible: el runner da `EXIT 1`**— y su §5 pide «versionar el runner», que es justamente lo que ese mismo commit hace.

## 4. Suites, y un fallo que **no** pude atribuir

| Corrida | Resultado |
|---|---|
| `guardianBelleza.test.js` en **su** worktree | **3/3 PASS** ✓ |
| `guardianBelleza.test.js` en mi worktree, 1ª corrida | **1 failed / 2 passed** ✗ |
| La misma, 4 corridas posteriores (mi worktree y el suyo) | **3/3 PASS** las cuatro ✓ |

**Declaro el fallo como NO ATRIBUIDO**: la salida de esa primera corrida no quedó en el log (mi error de instrumentación). Hipótesis no probada: cada caso ejecuta el runner completo, que hace `curl` a la API y `git ls-remote` en **cada** uno (~8,6 s por caso) ⇒ candidato a flakiness por red; y **no hay modo sin red**. Se registra como **CI-26**, no como defecto de su entrega.

## 5. Declaración de no infracción

Cumplida: no tocó el cron ni el perfil (los 6 archivos son del repo), no creó ni borró ramas, no usó `--force` ni `--force-with-lease`, no tocó migraciones, C-01/C-02/C-03, `backend/public`, `tenantRouting.js` ni `COMO_EJECUTAR.md`. `git status --porcelain` limpio al entregar. Los mocks temporales del walkthrough (`backend/src/tests/tmp_mocks/`) **no** están versionados: los crea y borra el propio test ✓ (por eso los casos 2 y 3 del walkthrough no quedan como archivos del repo).

## 6. Deuda que abre esta entrega

- **CI-25** — el runner no puede invocar el chequeo cuando `ROOT_DIR` sale en formato MSYS (`pwd` ⇒ `/c/...`) y se lo pasa a `node.exe`; y sus tests **solo** cubren caminos con mock ⇒ el camino real nunca se probó. Los verdes del runner en git-bash son falsos hasta que se corrija. (ronda 8)
- **CI-26** — los 3 casos del runner dependen de la red (`curl` a la API + `ls-remote`) en cada ejecución: ~8,6 s por caso, 26 s la suite, candidato a flakiness. Falta un modo sin red para los tests.
- **CI-27** — el guardián inspecciona **la copia donde vive el script**: si el cron lo invoca desde el worktree de la KB, el banco de trabajo del Dueño (`C:/beauty-app`) queda sin vigilar y el parte dirá «0 desalineaciones». Falta `GUARDIAN_REPO` + default declarado.

**Veredicto: Cargo 1 RECHAZADO (CI-25) · Cargo 2 ACEPTADO (conservar R4 y sus tests) ⇒ ronda 8 emitida.**
