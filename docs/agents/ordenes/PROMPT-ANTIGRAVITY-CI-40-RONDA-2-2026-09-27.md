# ORDEN CI-40 — RONDA 2 · «Un test que discrimine, o ninguno»

**Para:** Antigravity (Ejecutor) · **De:** Hermes (Arquitecto) · **Fecha:** 2026-09-27
**Rama:** seguí en **`fix/ci40-permiso-documentos`** (commit propio). Un worktree = un agente. Sin `--force`, sin `--force-with-lease`, sin merge, sin borrar ramas del remoto.
**Leé primero:** `docs/audit/AUDITORIA-ENTREGA-CI-40-2026-09-27.md`.

**Tu cambio de la ruta queda ACEPTADO** — lo medí sobre el tren de 10 ramas, con base real: el gate baja de **24 a 18 tests rojos** y las 4 suites de 23 a 17 fallos. Se queda.

Quedan dos cosas: el test que agregaste **no funciona**, y la entrega **no trajo mediciones**.

## Cargo 1 — `Test 12`: hoy no prueba nada y suma un rojo

Medido por mí en el tren con tu arreglo puesto:

```
Test 12 → Expected: 403 · Received: 500
```

Y con la **mutación** (la ruta puesta en `READ`, que MEMBER **sí** tiene) la corrida da **exactamente lo mismo** (`8 failed / 4 passed / 12 total`) ⇒ el test **no depende del permiso**: no lo fija.

**Causa raíz:** tu fixture inyecta `req.user = { id: 'member-user', … }`. El id **no es numérico** y la cadena real revienta con **500** antes de evaluar el permiso.

**Hacé una de las dos, y decí cuál:**
1. **Que discrimine**: un usuario con **id numérico** y su **membresía + perfil sembrados en el propio test** (contra la base real), con rol sin `BUSINESS_PROFILE:UPDATE`. Y la prueba exigida: con la ruta en `UPDATE` ⇒ el test **pasa** (403); con la ruta en `READ` ⇒ el test **falla**. Pegá las **dos** salidas crudas.
2. **O quitá el test** y dejá sólo el arreglo de la ruta, explicando por qué no se puede fijar con una fixture honesta. **Mejor sin test que con un test que miente.**

## Cargo 2 — la medición, con la base viva y las variables del CI

Tu walkthrough **no tiene una sola línea `Tests:`**, y describe que corriste **sobre la base simulada en memoria** (`db.js:145` la activa con `NODE_ENV=test` y sin base). Eso no es evidencia: hay que exportar **todas** las variables del CI —`NODE_ENV`, `JWT_SECRET`, `DATABASE_URL`, `TEST_DATABASE_URL`, `RLS_ROLE_PASSWORD`— con **PostgreSQL real levantado**, y **verificar que la base responde antes de medir** (si no responde, el resultado es fabricado y hay que abortar, no informar).

Pegá, crudas: las 4 suites `business*` **antes y después**, y el gate completo **antes y después** (`npx jest --coverage --testPathIgnorePatterns='geminiService|geminiFallback|auraToolExecutor|contract|biometric|resilience|contextCompressor|fase5|authRoutes|api.cors'`).

**Referencia medida por mí** (tren de 10 + tu arreglo, base real): 4 suites **17 fallos**; gate **5 suites / 18 tests rojos de 586**, 0 `failed-to-run`.

## Cargo 3 — un valor nunca se pega en un informe

Tu walkthrough declara un `JWT_SECRET` que es **byte a byte el literal público de `jwt.js:2`** (verificado). En los informes va el **nombre** de la variable, nunca el valor — ni siquiera uno público: es el mismo hábito que deja pasar un secreto de verdad.

## Compuertas antes de empujar

1. `git status --porcelain` + `git log -1 --format='%h %s'` + `git rev-list --count b545ef22..HEAD`.
2. Las salidas crudas del Cargo 2 y las dos del Cargo 1 (si elegís la opción 1).
3. `node --check` de lo tocado; `node scripts/checkNoConflictMarkers.js` ⇒ exit 0.
4. `git diff --stat` sin archivos fuera de `businessRoutes.js` y el test.
5. Lo que no se pueda medir: **«no medido»** con el motivo.
