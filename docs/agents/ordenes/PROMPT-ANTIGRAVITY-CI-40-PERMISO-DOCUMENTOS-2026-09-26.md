# ORDEN CI-40 — «El endpoint de documentos vuelve a ser alcanzable»

**Para:** Antigravity (Ejecutor) · **De:** Hermes (Arquitecto) · **Fecha:** 2026-09-26
**Rama:** nueva, **`fix/ci40-permiso-documentos`**, nacida de `fase-a/verdad-operativa` (`b545ef22`). Un worktree = un agente; mismo worktree de siempre, rama nueva. Sin `--force`, sin `--force-with-lease`, sin merge, sin borrar ramas del remoto.
**Decisión del Dueño ya tomada:** CI-35 se resuelve por la **opción (a)** — cambiar el permiso que exige la ruta. **La matriz NO se toca.**

## El hallazgo, verificado por el Arquitecto

`POST /api/v1/business/documents/generate` exige `requirePermission(RESOURCES.BUSINESS_PROFILE, ACTIONS.CREATE)` (`backend/src/routes/businessRoutes.js:72`) y **ningún rol de `PERMISSIONS_MATRIX` tiene `BUSINESS_PROFILE:CREATE`** (medido cargando la matriz: OWNER tiene READ/UPDATE/DELETE_BUSINESS/TRANSFER_OWNERSHIP; ADMIN tiene READ/UPDATE; MANAGER/MEMBER/VIEWER sólo READ) ⇒ **403 para todo el mundo**. De ahí cuelgan **23 de los 24 tests rojos** del gate.

**Por qué `UPDATE` y no otra cosa — el precedente medido:**

| Ruta | Acción que exige |
|---|---|
| `POST /diagnostic` | `UPDATE` |
| `POST /tasks/:id/advance` | `UPDATE` |
| `POST /tasks/:id/evidence` | `UPDATE` |
| **`POST /documents/generate`** | **`CREATE`** ← el único outlier de 7 rutas POST |
| `POST /documents/:id/request-signature` | `UPDATE` |
| `POST /documents/:id/sign` | `UPDATE` |
| `POST /documents/:id/version` | `UPDATE` |

Las **tres rutas hermanas de documentos** usan `UPDATE`. Además el controlador está comentado como **«(Private Provider)»** y usa `req.user.id`/`req.user.tenant_id`, y quien lo llama es el panel (`admin-dashboard/src/app/(dashboard)/admin/business/page.tsx:135`) y el bundle de Flutter. `UPDATE` lo tienen **exactamente OWNER y ADMIN** ⇒ la audiencia es la misma que tendría la opción (b) **sin ampliar la matriz**.

## Cargo 1 — el cambio (una línea)

En `backend/src/routes/businessRoutes.js`, ruta `/documents/generate`:

```diff
-  requirePermission(RESOURCES.BUSINESS_PROFILE, ACTIONS.CREATE),
+  requirePermission(RESOURCES.BUSINESS_PROFILE, ACTIONS.UPDATE),
```

**Prohibido en esta orden:** tocar `authorizationService.js` o `PERMISSIONS_MATRIX`, tocar las otras rutas, tocar fixtures para «forzar» el verde, o cualquier cambio fuera de esa línea.

## Cargo 2 — un test que impida que vuelva a pasar

Agregá la aserción que **habría cazado CI-40**: en `src/tests/business.integration.test.js` (que ya tiene la fixture real y su test 11 consigue `200`), un caso hermano con **un rol que NO tiene `BUSINESS_PROFILE:UPDATE`** (MEMBER/VIEWER) ⇒ debe responder **403**. Si esa fixture no se puede conseguir barato en la base de test, **declaralo como «no medido» con el motivo** — no inventes la fixture ni relajes la aserción. (Si preferís un archivo nuevo y enfocado, `src/tests/businessDocumentsPermission.test.js`, vale igual.)

## Cargo 3 — la medición (esto es la entrega)

Con el **entorno completo del CI** exportado —`NODE_ENV`, `JWT_SECRET`, `DATABASE_URL`, `TEST_DATABASE_URL`, `RLS_ROLE_PASSWORD`— checkout **LF** y base limpia, pegá las salidas crudas **antes y después** de:

```
# las 4 suites afectadas
npx jest src/tests/business.integration.test.js src/tests/businessAdminDocs.integration.test.js \
         src/tests/businessHardening.integration.test.js src/tests/businessSystem.integration.test.js --runInBand

# el gate completo (comando del CI)
npx jest --coverage --testPathIgnorePatterns='geminiService|geminiFallback|auraToolExecutor|contract|biometric|resilience|contextCompressor|fase5|authRoutes|api.cors'
```

**Esperado (medido por mí en la base, con el entorno del CI):** antes = 4 suites / **23 tests rojos**; después = **0**. Y el gate: antes **5 suites / 24 tests rojos** de 586 ⇒ después **1 suite / 1 test** (sólo `audit360-remediation`, que es CI-14, decisión del Dueño). Si no da eso, **no lo maquilles**: pegalo y explicá.

⚠️ **No medí sin `JWT_SECRET`** — hacerlo dio 4 rojos falsos durante una jornada entera (`docs/audit/RETRACTACION-GATE-ENTORNO-2026-09-26.md`). Declará qué variables exportaste.

## Compuertas antes de empujar

1. `git status --porcelain` + `git log -1 --format='%h %s'` + `git rev-list --count b545ef22..HEAD`.
2. Las salidas crudas de arriba (antes y después), con el `Tests:` de cada una.
3. `node --check` del archivo tocado.
4. `git diff --stat` mostrando **una línea** de cambio en `businessRoutes.js` (+ el test, si lo agregás).
5. Lo que no se pueda medir: **«no medido»** con el motivo.
