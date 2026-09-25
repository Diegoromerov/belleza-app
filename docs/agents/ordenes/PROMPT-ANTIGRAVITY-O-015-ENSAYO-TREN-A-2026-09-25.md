# ORDEN A · O-015 — «el tren tiene que encajar antes de aterrizar»

**Para:** Antigravity (Ejecutor). **De:** Hermes (Arquitecto).
**Base:** `fase-a/verdad-operativa` @ **`b545ef22`** (el vehículo, PR #16) — **no** se toca.
**Rama de trabajo:** `integracion/tren-a`, **local, sin push** (desechable).
**Prohibido:** mergear a `main`; tocar `fase-a/verdad-operativa`; `--force`/`--force-with-lease`; borrar o crear ramas del remoto; reescribir historia; tocar C-01/C-02/C-03, migraciones, `backend/public`.

## Para qué (y por qué ahora)

Hoy hay **cinco entregas aceptadas que viven fuera del vehículo**. Cuando el CI se desbloquee y el Dueño decida el aterrizaje, tienen que entrar **juntas** — y nadie sabe todavía si encajan entre sí: una de ellas (`fix/admin-metricas-sin-datos`) ni siquiera está rebasada (su `merge-base` con `fase-a` es `c1069e9f`, viejo), y tres tocan `backend/index.js`. El objetivo es producir, **antes** de decidir, el mapa de integrabilidad y el orden de aterrizaje.

**Tren a ensayar** (todas verificadas y aceptadas por mí):

| Orden propuesto | Rama | SHA | Qué es | Estado |
|---|---|---|---|---|
| 1 | `fix/ci-procedencia` | `6268afff` | A-05: procedencia declarada | ✓ aceptada |
| 2 | `fix/rls-056-058-cadena` | `ba06e563` | A-01 r2: cadena RLS 056/058 | ✓ aceptada |
| 3 | `fix/montajes-unicos` | `38a9afe9` | A-03: montajes canónicos | ✓ aceptada (hoy) |
| 4 | `fix/admin-metricas-sin-datos` | `f565037c` | A-02 r2: proyecciones honestas | ✓ aceptada (**sin rebasar**) |
| 5 | `fix/arranque-y-estado-honesto` | `07e7225e` | Fase A r6: arranque y estado honesto | ✓ aceptada |

**Fuera del tren** (no las toques): `fix/compuerta-secretos-reproducible` y `fix/jwt-sin-respaldo` (A-06 r4 RECHAZADA, r5 sin entregar), `chore/guardian-en-el-repo` (O-014 r1 rechazada), `feat/glowshop-*` (decisión del Dueño).

## Cargo 1 — el ensayo, con evidencia por merge

1. Desde `b545ef22` creá la rama **local** `integracion/tren-a` en un worktree aparte.
2. Mergeá **en el orden de la tabla** (o justificá otro orden con un motivo medido: p. ej. la que menos archivos comparte primero).
3. **Después de cada merge**, registrá: `git status --porcelain`, los archivos en conflicto si los hubo, y el resultado de las suites afectadas (al menos `routing.contract`, `dbStatusLock`, `degradedLockBehavior`, `audit360-remediation`, `memoryFallbackProductionGuard`, más las que cada rama haya tocado). Pegá el resumen por merge.
4. **Si un merge da conflicto: `git merge --abort`, documentá el conflicto** con los archivos y las líneas enfrentadas, **y seguí con las otras ramas**. El valor del ensayo es el mapa, no el resultado.

**C1** el mapa por merge con su evidencia.

## Cargo 2 — la recomendación de aterrizaje

1. Con el mapa: **orden recomendado de aterrizaje en `fase-a`** (o «no aterrizar tal cual» si algo choca), indicando por rama: ¿necesita rebase? ¿qué archivos comparte con quién? ¿qué suite valida que entró?
2. Dejá el mapa escrito en `docs/agents/ordenes/ENSAYO-TREN-A-<fecha>.md` (en tu rama de ensayo, y si querés también como documento en `docs/`) — **sin** tocar `fase-a`.
3. Verificá explícitamente que **no** empujaste nada a `fase-a/verdad-operativa` ni a `main` y que las ramas del tren siguen **intactas**: `git rev-parse` de las 5 == los SHA de la tabla.

**C2** lo anterior.

## Cargo 3 — nada

No hay tercer cargo. Si algo no se puede cumplir, **parás y reportás el motivo medido**.

## Entrega

`git log --oneline -1` de `integracion/tren-a` + `git status --porcelain`; los SHA de las 5 ramas antes y después (deben coincidir); el mapa de merges con sus suites; el documento del ensayo; y la declaración de que `fase-a` y `main` no se movieron (`git rev-parse` de ambas antes y después).
