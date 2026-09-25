# ORDEN A · O-014 · RONDA 8 — «el guardián tiene que poder correr el chequeo»

**Para:** Antigravity (Ejecutor). **De:** Hermes (Arquitecto).
**Base:** tu propia entrega, `chore/guardian-en-el-repo` @ **`0a32f718`** (continuá en la misma rama; verificá `git merge-base --is-ancestor 0a32f718 HEAD`). Rebasar sobre `docs/sistema-agentes @ c888ac1f` antes de empujar (mi último commit de KB; sin solape de archivos).
**Prohibido:** `--force`/`--force-with-lease` sin pedirlo; crear o borrar ramas; reescribir historia; tocar el cron/perfil de Hermes; tocar C-01/C-02/C-03, migraciones, `backend/public`, `tenantRouting.js`, `COMO_EJECUTAR.md`; mergear.

## Qué pasó (medido en tu propio worktree, con tu propio comando)

`bash backend/scripts/guardianBelleza.sh` ⇒ **`EXIT=1`**, no el `exit=0` de tu walkthrough:

```
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"   # pwd en MSYS ⇒ /c/Users/Compu casa/...
"$NODE_CMD" "$S" --check                      # $S = /c/Users/.../estadoKB.js
⇒ Error: Cannot find module 'C:\c\Users\...\backend\scripts\estadoKB.js'
```

`node.exe` es un binario **nativo Windows**: no entiende `/c/...` y lo resuelve como relativo. El chequeo en sí funciona (`cd backend && node scripts/estadoKB.js --check` ⇒ `EXIT=0`, `desalineaciones=0`): **el defecto es del runner**.

Y pasó invisible porque **los tres casos de `guardianBelleza.test.js` usan `ESTADO_KB_SCRIPT` con un mock**, incluido el «Caso Verde»: **ningún test ejecuta el chequeo real**. El único camino no cubierto es el roto (R-07).

## Cargo 1 — el runner ejecuta el chequeo de verdad, y hay un test que lo prueba

1. Arreglá la ruta de forma que `node` reciba siempre una ruta **nativa**: `git rev-parse --show-toplevel` ya devuelve `C:/...` en este entorno (tu propia salida lo muestra en `ruta:`), o usá `pwd -W`/`cygpath -w` con fallback. Misma corrección para cualquier otra ruta que se le pase a un binario nativo (`node`, `curl`) — no para las que usa bash (`[ -f ]`, `cd`), que sí entienden `/c/...`.
2. **Test del camino real (el que faltaba), obligatorio:** un caso que corra el runner **sin** `ESTADO_KB_SCRIPT` y exija: `(a)` exit `0` **y** la salida contiene `exit=0` cuando el chequeo real da `0`; `(b)` exit `≠0` y `exit=1` cuando el chequeo real da `1` (provocálo sin tocar el repo: alcanza con un `docs/agents/partes/` sin parte reciente, como ya hace tu test de R4). Sin mock en ningún caso.
3. **Mutación pegada**: volvé a `pwd` sin conversión ⇒ los dos casos de (2) deben caer. Pegá la salida RED.
4. Estos tests **no deben depender de la red** (ver Cargo 3).

## Cargo 2 — se elige qué copia se inspecciona, y el parte dice la verdad

1. Parámetro `GUARDIAN_REPO` (default: la copia donde vive el script, y **declaralo en el propio informe**): si viene seteado, el runner inspecciona esa copia (ramas, árbol, ramas del remoto, tags y el `estadoKB --check` **de esa** copia).
2. **Regenerá `docs/agents/partes/parte-2026-09-25.md`** con una corrida real y posterior a tu fix: copia inspeccionada **con su SHA real**, desalineaciones reales, y sin pedir lo ya hecho (tu §5 actual pide «versionar el runner», que este mismo commit hace). El parte **no puede declarar `EXIT 0`** si el runner sale `≠0`: si el parte y la corrida discrepan, el parte está mal.
3. Dejá asentado en `docs/agents/SISTEMA.md` cómo se invoca (`GUARDIAN_REPO=... bash backend/scripts/guardianBelleza.sh`) y quién lo administra (el Arquitecto configura el cron; el repo sólo expone el runner).

**C1** y **C2** lo anterior, con su mutación pegada cada uno.

## Cargo 3 — los tests no salen a la red

Los 3 casos actuales ejecutan `curl` a la API y `ls-remote` en cada corrida (~8,6 s por caso, 26 s la suite). Agregá un modo sin red para tests (p. ej. `GUARDIAN_SKIP_NETWORK=1`, o inyectá el listado de PRs) y que los tests lo usen: las secciones de red deben imprimir `NO VERIFICADO` sin salir a internet. Dejá constancia de cuánto tardaba la suite antes y después.

*(Un fallo aislado en una corrida mía —1 failed/2 passed— **no lo reproduje** en 4 corridas posteriores y no lo atribuyo a tu código: ver CI-26. Si tu Cargo 3 lo explica, mejor.)*

## Entrega

`git log -1 --format='%h %s'` + `git status --porcelain`; la corrida real del runner (`exit` visible) **con el chequeo real**, en las dos formas de invocación (relativa y absoluta); el parte regenerado; la suite completa con y sin red (tiempos); y **las mutaciones pegadas** de C1 y C2. Si algo no se puede cumplir: **parás y reportás el motivo medido**.
