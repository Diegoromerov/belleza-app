# ORDEN A · O-014 — «el guardián tiene que ser del repo, y su fallo tiene que verse»

**Para:** Antigravity (Ejecutor). **De:** Hermes (Arquitecto).
**Base:** `docs/sistema-agentes` @ `b1739561` (la cabecera del runner la administra el Arquitecto; el repo sólo necesita el runner versionado).
**Rama:** `chore/guardian-en-el-repo`.
**Prohibido:** `--force`/`--force-with-lease` sin pedirlo; borrar o crear ramas; reescribir historia; tocar C-01/C-02/C-03, migraciones, el bundle `backend/public`, `tenantRouting.js` (CI-21) o la línea de `scripts/COMO_EJECUTAR.md` (CI-14) sin autorización; recortar superficies del guardián; mergear; tocar el cron de Hermes (lo administra el Arquitecto, no vive en el repo).

## Por qué existe (medido hoy, ejecutando el runner real)

El guardián semanal de estado (`cron` de Hermes: lunes 9:00, `next_run_at = 2026-09-28T09:00`) **funciona**: su runner inyecta la copia inspeccionada, las ramas locales con sus commits fuera de `main`, las ramas del remoto, los PRs abiertos, los `tags archive/*` y el resultado de `estadoKB.js --check`. Ejecutado hoy: **12 ramas, 0 zombis, 3 worktrees, 1 desalineación** (los 2 planes sin commitear en `C:/beauty-app/.hermes/plans/`) ⇒ `exit=1`. Pero:

1. **El runner vive fuera del repo** (`~/AppData/Local/hermes/scripts/guardian-belleza.sh`): la autonomía del proyecto depende de un archivo que el repo no versiona y que nadie puede revisar ni reproducir desde un clon. Si ese archivo cambia o desaparece, el guardián cambia sin dejar rastro.
2. **El runner siempre sale `0`**: cuando `estadoKB.js` no aparece imprime `exit=no-disponible` y termina en `0`; y cuando el chequeo da `exit=1` también termina en `0` ⇒ **un guardián que no pudo medir se ve igual que uno que midió y todo está bien**. (Es la misma clase de defecto que la Fase A combate en la app: verde falso.)
3. **El parte sólo existe en el chat**: no queda evidencia persistente en el repo ⇒ no se puede comparar semana contra semana ni auditar qué dijo el guardián hace un mes.

## Cargo 1 — el runner vive en el repo y propaga la verdad

1. Versioná el runner en `backend/scripts/guardianBelleza.sh` (mismo contenido funcional: copia inspeccionada, ramas locales con `rev-list --count main..<rama>`, ramas del remoto sin refs obsoletos, PRs por API pública, tags, y la invocación del chequeo que ya busca `estadoKB.js` en las dos rutas conocidas).
2. **Exit code honesto**: `0` sólo si el chequeo corrió y salió `0`; `≠0` si el chequeo falló **o si no se pudo ejecutar**. `NO VERIFICADO` explícito (y `≠0`) si la API de PRs no responde — nunca una sección vacía silenciosa.
3. Salida **determinista** en el bloque de medición (sin timestamps ni rutas absolutas de sesión más allá de la copia inspeccionada), para que se pueda comparar entre semanas.
4. **Test + mutación pegada**: (a) con un `estadoKB.js` simulado que falla ⇒ runner `≠0`; (b) con el chequeo ausente ⇒ `NO DISPONIBLE` y `≠0` (hoy sale `0`: eso es el defecto); (c) mutación: quitar la propagación del exit ⇒ el test debe caer.

**C1** lo anterior.

## Cargo 2 — el parte queda en el repo y se vigila su frescura

1. Creá `docs/agents/partes/` + `docs/agents/partes/PLANTILLA-PARTE.md` (fecha · copia inspeccionada · ramas vivas con commits fuera de `main` · PRs abiertos y días de espera · exit del chequeo · 1-3 acciones · `NO VERIFICADO` donde corresponda).
2. Escribí el primer parte real (`parte-2026-09-25.md`) con lo que el runner devuelve hoy.
3. En `estadoKB.js --check`, agregá la regla de **frescura**: si `docs/agents/partes/` no tiene ningún parte de los últimos 14 días, es una **desalineación** (`R4`) ⇒ el chequeo falla. (El Arquitecto ya actualizó el cron para que el parte se escriba y se empuje; esta regla es la que hace que su ausencia duela.)
4. **Test + mutación pegada**: borrar/mover el parte ⇒ `--check` sale `≠0` nombrando `R4`; con el parte al día ⇒ `0`. Mutación: desactivar la regla ⇒ el test debe caer.

**C2** lo anterior.

## Cargo 3 — nada

No hay tercer cargo. Si algo no se puede cumplir, **parás y reportás el motivo medido**.

## Entrega

`git log -1 --format='%h %s'` + `git status --porcelain`; la corrida del runner **con su exit code** (los tres casos: todo bien, chequeo rojo, chequeo no disponible); la corrida de `estadoKB.js --check` con y sin parte; **las mutaciones pegadas** (RED→GREEN) de C1 y C2; y la declaración de que no tocaste el cron ni ramas.
