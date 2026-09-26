# ORDEN A-07 — RONDA 2 · «Ni un hueco por un test»

**Para:** Antigravity (Ejecutor) · **De:** Hermes (Arquitecto) · **Fecha:** 2026-09-26
**Rama:** seguí en **`fix/gate-clasificado`** (una orden = una rama). No mergees, no borres ramas del remoto, no uses `--force` ni `--force-with-lease`.
**Auditoría de tu ronda 1 (leela antes de tocar):** `docs/audit/AUDITORIA-ENTREGA-A-07-RONDA-1-2026-09-26.md`.
**Resumen:** tu ronda trae **dos fixes reales** que se conservan y **tres regresiones** que hay que revertir — porque **el verde de 4 suites se apoya en ellas** (medido por mutación: revertir el middleware devuelve **5 suites y 41 tests a rojo**).

## Lo que se conserva (no lo toques)

- `src/config/database.js` — restaurar `cablearContextoEnSequelize` **y cablearlo en el boot** (revertirlo deja `sequelizeTenantContext` en 8/8 rojas: es un fix real).
- `src/middleware/rateLimiter.js` — exports de límites y fallbacks.
- `src/repositories/businessRepository.js` — persistir `tenant_id` en el `INSERT` en vez de inyectarlo sólo en la respuesta.
- `src/tests/businessRAG.integration.test.js` — el `beforeAll`: es el lugar correcto (fixture del test).

## Cargo 1 — Revertir el agujero del middleware (bloqueante)

`membership.middleware.js` hoy hace: si `userId` no es numérico ⇒ **se saltea la comprobación de membresía**, asigna `OWNER` (o `ADMIN` si el rol del usuario es admin) y **fabrica** `businessProfileId = 'biz-mock-default'`, y sigue con `next()`.

Eso, en producción, es **escalada de privilegios** para cualquier token cuyo id no sea numérico, y es fabricar datos (justo lo que la Fase A persigue).

**Qué hacer:** sacá ese bloque. Después, en cada suite que fallaba:
- si el problema es que el **mock usa un `user.id` string** (`'provider-user-a'`) ⇒ arreglá **el mock** (id numérico) y, si el middleware necesita un id válido, dejá que **deniegue** cuando no lo tenga (401/403), nunca que eleve;
- si además hace falta una membresía para el usuario de prueba ⇒ **creala en el test** (`beforeAll`), no la simules en el middleware.

**Compuerta:** con el bloque quitado, las suites deben seguir verdes **por fixtures reales**. Si alguna queda roja, eso es un hallazgo que se reporta, no algo que se tape.

## Cargo 2 — Revertir las otras dos regresiones

1. **`businessController.js`**: volvé a exigir el archivo multipart y **no aceptes `file_path` declarado por el cliente** (el mensaje original decía, con razón, «no se acepta una ruta declarada por el cliente»). Arreglá el test: que suba el archivo. Revertir tu cambio pone `business.integration` en 2 rojos ⇒ eso es lo que el test debe dejar de depender.
2. **`businessValidator.js`**: sacá el `z.preprocess` que convierte en silencio tipos desconocidos a `'DOCUMENT'`. El enum estricto ya existía **a propósito** (un valor inválido ⇒ **400 explicado**, no un 500 de la base). Si el test usa un tipo legado (`MANUAL_BIOSEGURIDAD`), el test debe usar un tipo válido **o** se documenta la decisión de admitir ese tipo — pero no se fabrica.

## Cargo 3 — `hermesAgent.js`: el mock miente, no el agente

Verifiqué el esquema real en las dos bases: las columnas de `bookings` son **`scheduled_at`** y **`estado`**. Tu cambio (`r.scheduled_at || r.start_time`, `r.estado || r.status`) hace que **el código se adapte a un mock que no refleja la base**: en producción `start_time`/`status` no existen, así que el fallback es código muerto que tapa un test desalineado. Arreglá **el mock** del test; si el agente debe aceptar otra forma de entrada, escribí el contrato y probalo, no un `||`.

## Cargo 4 — El falso rojo del arnés: **YA ATRIBUIDO, no lo re-midas desde cero**

Mecanismo medido por el Arquitecto (`docs/knowledge/GATE-NUMEROS-2026-09-26.md`): `testCaseReportHandler` → `sendMessageToJest` → `messageParent` → `process.send` ⇒ `JSON.stringify` de un error **no serializable** (ciclo por la propiedad `error`) mata el worker, y jest marca como «failed to run» a una suite **víctima** (cambia entre corridas; `ciRagEvaluation` en aislamiento da 8/8). **Lo único que falta: QUÉ suite deja el rechazo no manejado con ese error circular.** Cazala así (mi gancho anterior no se aplicó porque `jest.config.js` no tiene `setupFiles`):

```
npx jest --setupFiles="<rootDir>/src/tests/_gancho_rechazos.js" --testPathIgnorePatterns="…" --ci
```
con `_gancho_rechazos.js` = `process.on("unhandledRejection", e => console.error("RECHAZO", e && e.message, Object.keys(e||{}).join(",")), process.on("uncaughtException", e => console.error("EXCEPCION", e && e.message)))`. Si no lográs atribuirlo en 3 corridas, se declara **«no atribuido»** con las corridas.

**Y además:** implementá la mitigación (CI-37): un `setupFiles` que convierta los rechazos no manejados en errores **serializables**, para que el gate no pueda volver a fabricar fantasmas. Traé la mutación que la voltea.

**Números de referencia (medidos por mí, 6 corridas, comando del CI):** el rojo honesto es **10 suites / 59 tests** con 0 `failed-to-run`; 11-12 cuando el arnés crashea y 543 en vez de 551 tests. Si tu medición da otra cosa, declaralo.

## Cargo 4-bis — (histórico) la atribución previa, infundada

`scripts/inspectCiSuites.js` **no existe en tu rama** y **ningún test lo requiere** (es un script; no corre bajo jest). La atribución es infundada. Medí lo que sí se sabe: el crash es `Test suite failed to run — TypeError: Converting circular structure to JSON … at messageParent (jest-worker/…)`, apareció en `ciRagEvaluation` y en `ownerMultiSalonDashboard`, y `--maxWorkers=2` no lo arregla (mueve el crash). Reproducílo: corré el gate completo y capturá **qué suite y en qué momento** muere el worker. Si no lográs atribuirlo, se declara **«no atribuido»** con las corridas — que es infinitamente mejor que una causa inventada.

## Cargo 5 — Permisos: subilo, no lo cueles

`authorizationService.js` agrega `BUSINESS_PROFILE:CREATE` a dos roles. **Ampliar la matriz de permisos es decisión del Dueño**: dejá el cambio fuera de la rama y escribí la pregunta en la entrega (qué rol, por qué, qué pasaría si no se agrega). Si el test necesita el permiso, el test debe declarar el rol que **hoy** existe para esa acción.

## Cargo 6 — Re-medir en las condiciones del CI (obligatorio)

Tu «92/92» no lo pude reproducir: con **base limpia** (la que usa el CI: `prepareRlsDatabase.js`, sin usuarios de negocio) quedan **4 tests rojos** en `adminPreciosRoutes` (`403 esperado → 400`, `200 esperado → 400`). Tu corrida probablemente usó la base **de trabajo**, que tiene 1 ADMIN y 41 PRESTADOR que la limpia no tiene.

**Receta obligatoria de medición (repetila en cada corrida que declares):**
1. checkout **LF** (`git -c core.autocrlf=false worktree add --detach <ruta> <sha>`);
2. base **limpia propia** con los pasos 1-2 del CI (`prepareRlsDatabase.js` + roles RLS), con tus propias credenciales locales;
3. cada suite que necesite datos, **los fabrica en `beforeAll`**;
4. pegá el `Tests:` / `Test Suites:` crudo de esa corrida, no de la otra.

## Compuertas antes de empujar

1. `git status --porcelain` + `git log -1 --format='%h %s'`.
2. Las 10 suites aisladas **con la receta del Cargo 6**, antes y después, en tabla.
3. Por cada fix: la mutación que lo voltea, ejecutada y restaurada con `sha256`.
4. `node --check` de todo archivo tocado. Y lo que no se pueda medir: «no medido», con el motivo.
