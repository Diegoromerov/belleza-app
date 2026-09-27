# GOAL — Fase A, ronda 2: completar y hacer verificable lo que ya empezaste

**Goal:** terminar la Fase A y entregarla de forma verificable: (a) lo entregado queda commiteado, pusheado y con PR; (b) la mentira de `/api/providers` se cierra **en la capa de datos**, no en el `catch`; (c) las 6 tareas ausentes existen, con el par RED→GREEN del smoke como evidencia principal.

**Rama:** la misma `fase-a/verdad-operativa` (hoy en `f5a1b4fc`, sin commits propios). **Ronda 1 auditada por mí el 2026-09-24** — el detalle con comandos está en `C:/Users/Compu casa/auditorias/belleza-app/AUDITORIA-ENTREGA-FASE-A-2026-09-24.md`. No lo repito aquí; lo que sigue son las correcciones.

---

## 0. Antes de tocar nada: dos bombas

**B1 — el índice de git lleva un marcador de conflicto.** Hoy:
```
git show :backend/scripts/checkNoConflictMarkers.js | grep -n '^<<<<<<<'
→ 6:<<<<<<< HEAD          (dentro de `const dummyMarker = ...`)
git diff -- backend/scripts/checkNoConflictMarkers.js
→ borra esas 4 líneas en el disco
```
La evidencia RED la produjiste insertando el marcador, pero **no reconciliaste el índice**: si commiteas así, tu propia compuerta hace fallar el CI sobre su propio archivo. **Haz `git add` de la versión de disco y verifica** `git show :<archivo> | grep -c '^<<<<<<<'` = 0 **antes** de commitear.

**B2 — nada está commiteado.** `git log -1` sigue en `f5a1b4fc` (= `origin/main`), `git ls-remote --heads origin 'refs/heads/fase-a/*'` está vacío. La ronda 1 se presentó como entregada sin un solo commit, sin PR y sin run de CI. Esta ronda **no está terminada hasta que existan los tres**.

---

## 1. Corrección de lo entregado

### C1 · A1.T3 rehecha: la mentira está en la capa de datos, no en el `catch` · M
**Medición que lo prueba** (servidor en `NODE_ENV=development` con `DATABASE_URL=postgres://nadie:nadie@127.0.0.1:59999/nadie`):
```
GET /api/providers → HTTP=200
{"success":true,"count":7,"data":[{"id":"101","full_name":"Carolina Mendoza Rios","distance_meters":450,...}],
 "debug":{"lat":4.6735,"lon":-74.1422,"radius":50000}}
```
El `catch` que cambiaste **no es el camino que se ejecuta**: el fallback en memoria resuelve la consulta *con éxito* aguas arriba, así que el controlador ni se entera del fallo. Regla a implementar:
1. Si `getDbStatus().servingFabricatedData === true`, `getProviders` **no responde 2xx con datos**: devuelve `503 { success:false, error:'PROVIDER_SEARCH_DEGRADED' }`. Rechaza cualquier tentación de devolver la lista "porque igual sirve": son prestadores inexistentes con distancias inventadas.
2. **No** devuelvas `error.message` al cliente (hoy `providerController.js:172` expone el mensaje del error de base de datos en un endpoint público). El log interno sí lo conserva.
3. Marca el fallback geográfico (`:117-139`) con `degraded: true` y una nota de que las coordenadas son fijas; no lo borres.
**Verificación (pega los dos curl completos):** base inalcanzable ⇒ `503 PROVIDER_SEARCH_DEGRADED`; base viva con ciudad sin prestadores ⇒ `200 count:0`.

### C2 · El `catch` de A1.T3 se queda, pero no es la prueba
No lo reviertas: sigue siendo correcto que un error real devuelva 5xx en vez de 200. Lo que no es correcto es presentarlo como la corrección del defecto: la evidencia de C1 es la que cierra el hallazgo.

---

## 2. Tareas ausentes (verificadas por mí como inexistentes)

| Tarea | Estado medido | Qué falta |
|---|---|---|
| A1.T2 cabecera de degradación | `grep -rn X-GlowApp-Degraded backend/` → **0 coincidencias** | Filtro en `index.js`: con `servingFabricatedData === true`, `X-GlowApp-Degraded: memory-fallback` en toda respuesta. Evidencia: `curl -si` en los dos modos |
| A1.T4 barrido de `catch` que fingen | `backend/scripts/auditFakeSuccess.js` **no existe**; tampoco `docs/audit/fake-success-2026-09-24.json` | Script + JSON con `archivo:línea` y veredicto `finge`/`legítimo con aviso`. **Córrelo primero contra el árbol sin tus cambios de C1** para tener línea base (debe detectar `providerController.js:170`) |
| A1.T5 frontend honesto | `git status --porcelain frontend/` → **vacío** | Quitar PAN/CVV/Nequi del checkout de cita (`wompi_payment_sheet.dart:594-684`, compartido con la tienda: no rompas su camino de error honesto ni `logInitiateCheckout`), y usar `comision_plataforma`/`impuestos_estado`/`pago_neto_prestador` de la API en vez del `gross * 0.20` hardcodeado (`provider_dashboard_screen.dart:354-355`), borrando la frase "la plataforma asume y reporta este impuesto en tu beneficio" (`:365-374`). **No** reconstruyas el bundle `backend/public` |
| A3.T1 inventario de rutas | `backend/scripts/listRoutes.js` y `docs/audit/routes-2026-09-24.json` **no existen** | Script que lee `app._router.stack` sin `listen()` y emite `{method, path}` de todos los mounts |
| A3.T2 smoke por superficie | `backend/scripts/smokeSurfaces.js` **no existe**; `grep smoke backend/package.json` → nada | Script + `npm run smoke:surfaces`; por ruta: `status`, `empty_like`, `degraded_header`, `wrote_to_db`, `faked_success`; exit ≠0 si hay cualquier `faked_success`; solo métodos seguros por defecto |
| A3.T3 corrida roja | — | Con Postgres detenido, el reporte debe listar `GET /api/providers` como `faked_success` **y** `GET /api/health` como 200 OK en modo degradado **antes** de C1 (por eso C1 va después de capturar el RED) |

**Orden obligatorio:** A3.T1 → A3.T2 → **correr el smoke con la base caída y guardar el RED** (debe salir rojo por `/api/providers` 200 con 7 fabricados y por `/api/health` 200) → recién entonces C1 y A1.T2 → **GREEN**. Si capturas el RED después de arreglar, el guardián no mide nada.

---

## 3. La entrega formal que faltó

1. Commit por tarea en `fase-a/verdad-operativa`, `git add` por rutas explícitas, sin mezclar frontend con backend.
2. `git push -u origin fase-a/verdad-operativa` y **PR contra `main` con URL real**. El workflow dispara en `pull_request` a `main`, así que el run existe: pega su URL.
3. `git log -1 --format='%h padre=%p'` de la rama y el HEAD de `origin/main` con el que la cortaste (`f5a1b4fc`).
4. **El primer run del CI va a ser ROJO, y hay que decirlo con nombres, no con adjetivos.** Medí 15 suites rojas; **8 no están excluidas** por el `testPathIgnorePatterns` del step bloqueante (`ci.yml:98`): `business.integration`, `businessAdminDocs.integration`, `businessHardening.integration`, `businessRAG.integration`, `businessSystem.integration`, `rateLimiter`, `sequelizeTenantContext`, `sprint2_agents`. Además el comentario de `ci.yml:91-92` dice "12 suites rojas heredadas": está desactualizado (hoy son 15) — corrígelo en el mismo PR.
   **Prohibido** "arreglarlo" ampliando la lista de exclusiones: eso es esconder deuda. El rojo heredado se declara así, con los nombres y el comando, y lo decide el dueño.
5. Suite completa con **nombres**: `BASE = <fallidas>/<total>` y `TU RAMA = <fallidas>/<total>`, con `NODE_ENV=test npx jest --maxWorkers=2 --silent`, la lista de nombres de suites fallidas en ambos lados y el desglose de tests. Tu BASE fue `15 suites, 70 tests fallidos`; **mi medición de tu rama dio `15 suites, 71 tests fallidos, 606 total`**. Ese test de diferencia queda sin atribuir: dime si venía en tu BASE (con nombres) o si lo introdujo el cambio en `db.js`. **No** lo expliques como flake sin probarlo: `resilience.test.js` aislada da `4 failed, 5 passed, 9 total` en tres corridas idénticas, o sea que es rojo estable, no inestable.
6. Declara si la superficie es **usable con los datos de hoy** (rol/tenant/usuario existentes), separado de "entregado".

---

## 4. Lo que ya está bien (no lo toques)

- `ci.yml`: la resolución del conflicto es la pedida — dos jobs, PostGIS, `prepareRlsDatabase.js`, `verifyTenantIsolation.js`, escaneo de secretos, compuerta nueva, y **`sequelize.sync` descartado**. Parseado por mí: YAML OK, 0 marcadores.
- `.gitignore`: fusión correcta de ambos lados.
- `db.js` A1.T1: funciona y está verificado por mí — `curl /api/health` con la base caída devuelve `503 {"status":"DEGRADED","database":{"pgAvailable":false,"servingFabricatedData":true,"memoryFallbackAllowed":false}}`. **No reescribas ese mecanismo**; solo añade lo de C1/A1.T2 encima.
- Las 3 suites trampa (`memoryFallbackProductionGuard`, `audit360-remediation`, `pgMemorySchema`) siguen verdes con tus cambios: 3 suites / 22 tests. (Las corrí yo porque no aparecían en tu reporte.)

---

## 5. NO TOCAR

- `paymentRoutes.js`, `bookingController.payBooking`, `wompiService.js`, `disputeController.js`: **C-01/C-02/C-03 siguen fuera de Fase A**.
- Ninguna migración, ninguna columna, ningún ajuste del dataset.
- El bundle `backend/public` y los artefactos Flutter.
- `main`, las ramas de otros agentes, `push --force`, y el `testPathIgnorePatterns` (ver §3.4).
- `error.message` al cliente en cualquier ruta pública.

## 6. Terminado = (falsable)

1. `git show :backend/scripts/checkNoConflictMarkers.js | grep -c '^<<<<<<<'` = 0 **y** existe al menos un commit propio en la rama.
2. PR con URL real y run de CI visible.
3. Smoke: RED capturado antes de C1 (con `/api/providers` `faked_success` y `/api/health` 200) y GREEN después (cero `faked_success`, providers 503, health 503), los dos JSON pegados, conteos de `bookings`/`services` intactos.
4. `GET /api/providers` con base caída ⇒ 503 sin `error.message`; con base viva y ciudad vacía ⇒ 200 `count:0`; `degraded:true` en el fallback geográfico.
5. Cabecera `X-GlowApp-Degraded` presente en modo memoria y ausente con base viva.
6. `auditFakeSuccess.js` + `docs/audit/fake-success-2026-09-24.json` + `listRoutes.js` + `routes-2026-09-24.json` + `smokeSurfaces.js` + `npm run smoke:surfaces` existen y corren.
7. Frontend: `grep -rn "0\.20\|_cvvCtrl\|_cardCtrl" frontend/lib` en rutas de cobro de cita = 0.
8. Números de suite con nombres, BASE y rama, y el delta de 1 test explicado o declarado.
9. Las 8 suites rojas heredadas declaradas en el PR con nombres, y el comentario de `ci.yml` actualizado a 15.
