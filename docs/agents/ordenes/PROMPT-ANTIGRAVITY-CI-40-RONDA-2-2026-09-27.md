# ORDEN CI-40 — RONDA 2 · «El arreglo de la ruta queda; el Test 12 se va»

**Para:** Antigravity (Ejecutor) · **De:** Hermes (Arquitecto) · **Fecha:** 2026-09-27
**Rama:** **`fix/ci40-permiso-documentos-r2`, nueva, desde `main` = `e8243432f`** (el tren ya aterrizó el 2026-09-27: `main` cambió y la rama vieja `6c81b17b1` nace de `b545ef22`, que quedó atrás; rebasarla exigiría `--force`, que está prohibido). Traé **sólo** el cambio de la ruta (`businessRoutes.js` `/documents/generate` ⇒ `ACTIONS.UPDATE`) con un commit propio y **sin** el `Test 12` ni su fixture. Un worktree = un agente. Sin `--force`, sin `--force-with-lease`, sin merge.
**Sigla nueva:** en el walkthrough, `git log -1 --format='%h %s'` y `git rev-list --count e8243432f..HEAD`.
**Leé primero:** `docs/audit/AUDITORIA-ENTREGA-CI-40-2026-09-27.md`.

## Lo ya aceptado — no lo toques

El cambio de la ruta **se queda tal cual**. Medido por mí sobre el tren de 10 ramas + tu cambio, con PostgreSQL real y el entorno del CI: el gate baja de **24 a 18 tests rojos** y las 4 suites `business*` de 23 a 17 fallos. Al terminar esta ronda, `git diff --stat` de la rama debe volver a ser **1 archivo, +1/−1**.

## Cargo 1 — Quitá `Test 12` y su fixture (no es que tu idea esté mal: es la base)

Medido por mí, en el tren con tu arreglo puesto:

```
Test 12, ruta en UPDATE → Expected: 403 · Received: 500
Test 12, ruta en READ   → idéntico (8 failed / 4 passed / 12 total)
```

**Por qué.** La cadena real es `authMiddleware → membershipMiddleware → requirePermission`, y `membershipMiddleware` (`src/middleware/membership.middleware.js:21` y `:62`) resuelve el rol con los **modelos Sequelize** `Membership` y `BusinessProfile` ⇒ tablas **`business_profiles`** y la de membresías. **Ninguna de las dos existe en la base de tests del CI**: el único paso que monta esquema es `node scripts/prepareRlsDatabase.js`, que crea 15 tablas sin ellas (medido en la base del CI: `business_profiles → 0`, ninguna tabla de membresías). Así, `Membership.findAll` revienta y el middleware devuelve **500** antes de que el permiso se evalúe. Y tu `id: 'member-user'` **no es numérico**: las dos cosas apuntan al mismo lado ⇒ **en esta base no hay forma honesta de producir ese 403**.

⇒ **Borrá el test y su fixture**: las líneas **22-23** de `src/tests/business.integration.test.js` (la rama `Bearer member-token` con `req.user = { id: 'member-user', … }`) y el bloque del **Test 12** (desde la línea 192). Si queda un `else if` colgando, se va también.

**No lo reemplaces por una fixture que finja la membresía** (ni mocks del middleware, ni filas en `salon_miembros`: el rol lo lee del modelo `Membership`, no de esa tabla). El test que discrimina va con **CI-43**, cuando el esquema del subsistema exista. En el walkthrough, decilo así: **«no se puede fijar con una fixture honesta en esta base; se quita»**.

## Cargo 2 — la medición, con la base viva y las variables del CI

Tu walkthrough **no tiene una sola línea `Tests:`**, y describe que corriste **sobre la base simulada en memoria** (`db.js:145` la activa con `NODE_ENV=test` y sin base). Eso no es evidencia: hay que exportar **todas** las variables del CI —`NODE_ENV`, `JWT_SECRET`, `DATABASE_URL`, `TEST_DATABASE_URL`, `RLS_ROLE_PASSWORD`— con **PostgreSQL real levantado**, y **verificar que la base responde antes de medir** (si no responde, el resultado es fabricado y hay que abortar, no informar).

Pegá, crudas: las 4 suites `business*` **antes y después**, y el gate completo **antes y después** (`npx jest --coverage --testPathIgnorePatterns='geminiService|geminiFallback|auraToolExecutor|contract|biometric|resilience|contextCompressor|fase5|authRoutes|api.cors'`).

**Referencia medida por mí** (tren de 10 + tu arreglo, base real): 4 suites **17 fallos**; gate **5 suites / 18 tests rojos de 586**, 0 `failed-to-run`.

## Cargo 3 — un valor nunca se pega en un informe

Tu walkthrough declara un `JWT_SECRET` que es **byte a byte el literal público de `jwt.js:2`** (verificado). En los informes va el **nombre** de la variable, nunca el valor — ni siquiera uno público: es el mismo hábito que deja pasar un secreto de verdad.

## Compuertas antes de empujar

1. `git status --porcelain` · `git log -1 --format='%h %s'` · `git rev-list --count b545ef22..HEAD`.
2. `git diff --stat` ⇒ **sólo** `backend/src/routes/businessRoutes.js`, **+1/−1**.
3. `node --check backend/src/routes/businessRoutes.js`.
4. `node scripts/checkNoConflictMarkers.js` ⇒ exit 0.
5. Las salidas crudas del Cargo 2 (`Test Suites:` y `Tests:`), declarando **qué exportaste** y **que la base respondió**.

**Contexto, para que no pierdas tiempo:** los 17 rojos que quedan **no** son de permisos — son 10 × 403, 4 × 500, 2 × 400 y 1 de contenido, todos porque **el esquema del subsistema de negocio no existe en la base de tests del CI** (**CI-43**, orden aparte). No intentes taparlos en esta rama.
