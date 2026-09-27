# ORDEN CI-16 — «El candado declara su alcance y una prueba lo impide erosionar»

**Para:** Antigravity (Ejecutor) · **De:** Hermes (Arquitecto) · **Fecha:** 2026-09-27
**Rama nueva:** `fix/candado-declara-alcance` desde **`main` = `e8243432f`** (el tren ya aterrizó; a partir de ahora las ramas nacen de `main`).
**Regla de la casa:** un test que **primero falla**; sin `--force`, sin `--force-with-lease`, sin merge, una rama = una PR.

## Contexto medido (no hace falta que lo re-midas, pero podés)

El Auditor corrió el backend real con la base caída y midió **12 rutas**: todas responden `503` + `X-GlowApp-Degraded: memory-fallback`, incluidas las de **dinero** (`POST /api/payments/wompi-webhook`, `/api/bookings`, `/api/wallet/balance`) e **identidad** (`/api/auth/login`, `/api/auth/register`, `/api/auth/verify-otp`). La allowlist son 3 rutas exactas y **ninguna es de dinero o identidad**. El comportamiento es el correcto; lo que falta es que **el contrato lo diga** y que **una prueba lo fije**.

Archivos: `backend/src/middleware/degradedLock.js` (contrato en las líneas 114-117; allowlist y reglas C7 en 52-63) · montaje en `backend/index.js:228`.

## Cargo 1 — Declarar el alcance en el contrato (sin cambiar comportamiento)

1. En el comentario de `degradedLockMiddleware`: donde hoy dice «bloquear superficies de datos bajo /api», decir el alcance real — **todas las rutas bajo `/api`**, con **dinero (C-02) e identidad (C-01) nombradas explícitamente**, y la razón de negocio: el webhook de Wompi recibe `503` y **la pasarela reintenta**; es preferible a procesar dinero o identidad contra datos fabricados.
2. En la allowlist, junto a las reglas C7, agregar la regla que hoy no está escrita: **«PROHIBIDO eximir cualquier ruta de dinero o identidad (C-01/C-02/C-03)»**.
3. **Sólo comentarios.** El archivo no debe cambiar de comportamiento: adjuntá `git diff --stat` y verificá que el diff son líneas `+`/`-` de comentario.

## Cargo 2 — La prueba de contrato (nace en rojo)

Nuevo archivo `backend/src/tests/candadoAlcance.test.js`. Sin red y sin base: importá `degradedLockMiddleware`, `decidirBloqueo` y `DEGRADED_ALLOWLIST` y usá dobles de `req`/`res`.

1. **La allowlist no puede crecer hacia el dinero ni la identidad**, ni usar comodines: para cada ruta de la allowlist, `assert(!/(auth|payment|wallet|booking|dispute|ticket|admin|order|refund)/i.test(ruta))` y `assert(!ruta.includes('*'))`.
2. **Cada ruta de dinero e identidad se bloquea en degradado**: con `servingFabricatedData: true` (y también con `pgAvailable: false`, y también con `null` sin datos fabricados ⇒ **NO** se bloquea, que es el caso `UNCHECKED`), el middleware responde `503` y setea `X-GlowApp-Degraded`. Lista mínima: `POST /api/auth/login`, `POST /api/auth/register`, `POST /api/auth/verify-otp`, `POST /api/payments/wompi-webhook`, `GET /api/bookings`, `GET /api/wallet/balance`, `GET /api/disputes`.
3. **Las 3 exentas siguen exentas** (para que el test también falle si alguien *quita* la allowlist sana).

**Demostración de que la prueba puede fallar (obligatoria):** agregá temporalmente `/api/auth/login` a `DEGRADED_ALLOWLIST`, corré el archivo ⇒ **tiene que fallar**, pegá la salida, **revertí el cambio** y corré de nuevo ⇒ verde. Sin esa mutación, la prueba es decorativa.

## Compuertas antes de empujar

1. `git log -1 --format='%h %s'` y `git status --porcelain` (vacío) y `git rev-list --count e8243432f..HEAD`.
2. `node --check backend/src/middleware/degradedLock.js` ⇒ exit 0 · `node backend/scripts/checkNoConflictMarkers.js` ⇒ exit 0.
3. `npx jest src/tests/candadoAlcance.test.js` ⇒ **las dos líneas** (`Test Suites:` y `Tests:`) + la salida de la mutación.
4. No toques `backend/index.js`, ni la matriz de permisos, ni rutas, ni migraciones.

## Fuera de alcance

Cualquier cambio de comportamiento del candado. Si al escribir la prueba descubrís que alguna ruta de dinero o identidad **no** se bloquea, **no la arregles**: paralo y reportalo — eso sería un hallazgo, no una tarea de esta orden.
