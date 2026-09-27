# GOAL — Fase A, ronda 3: cerrar las tres vergüenzas que quedaron

**Goal:** (1) que el guardián de la fase **deje de dar el visto bueno a un sistema que miente**; (2) que el cambio de rutas que hiciste sin pedirlo salga del PR; (3) que exista el PR.

**Rama:** la misma `fase-a/verdad-operativa` (pusheada, 5 commits, sin PR). Auditoría de esta ronda con comandos: `C:/Users/Compu casa/auditorias/belleza-app/AUDITORIA-ENTREGA-FASE-A-RONDA-2-2026-09-24.md`.

**Lo que sí quedó bien y NO debes tocar:** los 5 commits existen y están pusheados (`cfec993a`); `checkNoConflictMarkers.js` commiteado sin marcador (`git show 345dfeb9:… | grep -c '^<<<<<<<'` = 0); `ci.yml` con el comentario corregido a 15 suites; y **C1 + A1.T2 funcionan**, verificado por mí con el servidor levantado sin base:
```
curl /api/health    → 503 {"status":"DEGRADED","database":{"pgAvailable":false,"servingFabricatedData":true}}
curl /api/providers → 503  X-GlowApp-Degraded: memory-fallback
                      {"success":false,"error":"PROVIDER_SEARCH_DEGRADED"}
```

---

## B1 · El PR no existe (bloqueante)

La rama está en GitHub (`GET /repos/Diegoromerov/belleza-app/branches/fase-a%2Fverdad-operativa` → HTTP 200), pero **no hay PR**:
```
GET /repos/Diegoromerov/belleza-app/pulls?head=Diegoromerov:fase-a/verdad-operativa&state=all
→ []
```
El walkthrough termina ofreciendo la URL `pull/new/...`, que es la de **crear** el PR: `gh` no está instalado en este Windows, así que `gh pr create` no creó nada. **Entrega la URL real del PR** (créalo por la web o con la API y un token en variable de entorno; nunca en la línea de comandos) y, en su cuerpo, los nombres de las suites rojas heredadas (ver B6).

## B2 · Reviertes tu propio cambio de rutas en `index.js` (bloqueante)

El commit `5f834289` ("fix(backend): enforce 503 degraded search…") **añade 25 mounts** en `index.js:537-561` que nadie pidió:
- **17 son duplicados muertos**: `app.use('/api', paymentRoutes)`, `bookingRoutes`, `serviceRoutes`, `productRoutes`, `providerRoutes`, `analyticsRoutes`, `metricsRoutes`, `portfolioRoutes`, `communityRoutes`, `mentorshipRoutes`, `colorRoutes`, `vtoRoutes`, `biometricRoutes`, `glowProRoutes`, `ticketRoutes`, `disputeRoutes`… **ya estaban montados en `index.js:388-418`**, que corre antes. Express resuelve en orden: los nuevos no se alcanzan nunca.
- **8 introducen rutas base que no existían**: `/api/academy/admin`, `/api/admin/precios`, `/api/membership`, `/api/xp-log` (el original es `/api/xp-logs`), `/api/events`, `/api/event-registrations`, `/api/biometric/consent`, `/api/tickets` — es decir, **caminos nuevos hacia routers de precios, academia, membresía y eventos**, sin una sola prueba y sin declararlo.

Por qué lo hiciste, según la traza: `listRoutes.js` no veía las rutas y en vez de arreglar el lector tocaste la app. **Los mounts ya existían en 388-418**; el lector debía recorrer el stack tal como está. Consecuencia grave: el inventario de 308 rutas incluye alias que **solo existen por tu edición** (`/api/academy/admin/...`, `/api/membership/...`), así que el inventario y el smoke validan una tabla de rutas que no es la que se despliega.
**Acción:** revierte el bloque 537-561 completo. Si `listRoutes.js` necesita algo, se arregla `listRoutes.js`. Y para cada alias que decidas conservar (mi recomendación: ninguno), una prueba: `curl` sin token ⇒ 401/403, en el PR.

## B3 · El guardián de la fase da el visto bueno mientras el sistema miente (bloqueante)

Medición mía, con el servidor en modo degradado (base inalcanzable) y **su propio smoke**:
```
$ npm run smoke:surfaces
📋 Resumen de Smoke Test (122 superficies probadas):
- Faked Success Totales: 0
✅ SMOKE TEST EXITOSO: Ninguna superficie fingió éxito.        EXIT=0
```
Y al mismo tiempo, en el mismo proceso:
```
GET /api/products → HTTP/1.1 200 OK   (X-GlowApp-Degraded: memory-fallback)   cuerpo de 36 bytes
```
Un endpoint de datos responde **200 con la capa de datos fabricada** y el guardián de la Fase A sale **verde**. Causas, en `backend/scripts/smokeSurfaces.js`:
1. `faked_success` solo se evalúa para **dos rutas hardcodeadas** (`/api/providers` y `/api/health`, líneas 78-87). Cualquier otra superficie que finja es invisible: el guardián no puede encontrar un caso nuevo.
2. `isServerDegraded` se deriva **de `/api/health`** (línea 56): si el health miente, el veredicto se apaga. El guardián depende del mismo endpoint que vigila.
3. `empty_like` se calcula (línea 72) y **nunca decide nada**: el 200 con `data: []` estando degradado —el defecto original de la ronda 1— pasa como bueno.
4. `wrote_to_db: false` está **hardcodeado** (línea 100): el guardián antifabricación publica una métrica fabricada.
5. No escribe informe: el orden pedía `docs/audit/smoke-<fecha>.json` y no existe ninguno (`ls docs/audit` → sin `smoke-*`). El par RED→GREEN de tu entrega es prosa.

**Acción:** que la condición de fallo sea **de clase, no de ruta**: `2xx en una ruta de datos mientras la capa de datos está degradada/fabricada` ⇒ `faked_success` (usa `X-GlowApp-Degraded` o el estado capturado **una vez al inicio**), `empty_like` decide fallo, `wrote_to_db` real o eliminado, y el informe se escribe siempre a `docs/audit/smoke-<fecha>.json`. Con la versión nueva, la corrida degradada **debe** salir roja y nombrando `/api/products` y compañía: **ese es el RED que faltó**; guárdalo. Después de C1 solo `/api/providers` queda cubierto, así que el smoke rojo nombrando al resto es el entregable que convierte la Fase C en una lista con evidencia.

## B4 · A1.T5 sigue filtrando datos de tarjeta, y el texto nuevo afirma un falso (bloqueante)

En `frontend/lib/widgets/wompi_payment_sheet.dart` el corte es solo para `itemType == 'service'`: la **tienda** (`store_screen.dart`) sigue montando los formularios con `_cardCtrl` (línea 661) y `_cvvCtrl` (línea 698) — se siguen recolectando PAN/CVV sin pasarela. Y el texto nuevo dice:
> "La transacción se confirma sin recolectar credenciales bancarias." / "El pago se procesa directamente en el establecimiento."

Eso **afirma un hecho que el sistema no ejecuta** (`payBooking` responde 501 en producción, la reserva queda en `PENDIENTE_PAGO`) e **inventa una política de producto** que no te corresponde decidir. Cambiaste una mentira por otra.
En `frontend/lib/screens/provider_dashboard_screen.dart:285,290` el fallback silencioso sobrevive: `platformCut = double.tryParse(...) ?? (gross * 0.20)` y `stateTax = ... ?? (gross * 0.08)`. Mi criterio de aceptación (`grep "0\.20"` en rutas de cobro = 0) **falla**; y el rótulo sigue diciendo "(20% total)" con un valor que ya no es 20%.
**Acción:** quita los campos de tarjeta en **ambos** caminos; texto honesto y sin inventar política ("el cobro en línea aún no está disponible"); sin constantes de relleno (si falta el dato, muestra el desglose solo cuando la API lo traiga, o "no disponible"); y el rótulo debe reflejar lo que muestra.

## B5 · A1.T4 quedó sin línea base y con cobertura no declarada

`docs/audit/fake-success-2026-09-24.json` se generó **después** de C1, así que ya no puede detectar el caso conocido (`providerController.js:170`): se perdió exactamente la evidencia que el orden pedía capturar antes. Además sus 5 entradas son 4 líneas sueltas de `authController.js` (`res.json({` y `success: true,` como "hallazgos" separados) más `analyticsController.js:36`, y la cobertura real son solo `src/controllers` y `src/routes` (`auditFakeSuccess.js:67-68`), sin services, jobs ni middleware.
**Acción:** córrelo contra `f5a1b4fc` (sin tocar tu árbol: `git show f5a1b4fc:backend/src/controllers/providerController.js > ` un temporal, o un worktree aparte en la base) y agrupa por **sitio**, no por línea, con veredicto `finge` / `legítimo con aviso` y una nota de qué directorios escanea. `analyticsController.js:36` queda como pregunta abierta del PR, no como veredicto tuyo.

## B6 · Los números de suite siguen sin nombres, y no son estables

Mi medición con `NODE_ENV=test npx jest --maxWorkers=2 --silent` sobre tu rama pusheada: `15 failed, 64 passed, 79 total` · `72 failed, 2 skipped, 532 passed, 606 total`. La medición de la ronda 1 (mismo árbol, sin tus commits): `15 / 71 fallidos / 533 pasados`. Tu BASE declara 70 fallidos sobre 598 tests totales (526+70+2), pero mis dos corridas dan **606** tests: tu BASE no cuadra. Suites rojas estables en 15 las tres mediciones; **el conteo de tests fallidos no** (70 / 71 / 72) sin cambios en el código de tests ⇒ hay fallos sensibles a carga (timeouts en las suites `business.*`).
**Acción:** mide la base **en un worktree aparte en `f5a1b4fc`** con el mismo comando y entrega **las dos listas de nombres** de suites fallidas. "Idéntico al estado base" no se puede afirmar con conteos; solo con nombres. Y el desglose de tests con su total, para poder cuadrar los 606.
**Prohibido** ampliar `testPathIgnorePatterns` para ponerlo verde.

---

## NO TOCAR (recordatorio)

`paymentRoutes.js`, `bookingController.payBooking`, `wompiService.js`, `disputeController.js` (C-01/C-02/C-03 = Fase C) · migraciones y esquema · el dataset · el bundle `backend/public` · `main` y las ramas de otros agentes · `error.message` al cliente en rutas públicas · la lista de exclusiones del CI.

## Terminado = (falsable)

1. URL real del PR, y el cuerpo con las 8 suites rojas heredadas por nombre.
2. `index.js`: bloque 537-561 revertido; `git diff f5a1b4fc..HEAD -- backend/index.js` sin mounts duplicados; cero alias nuevos sin prueba `curl` sin token ⇒ 401/403.
3. Smoke: con la base caída nombra al menos `/api/products` y `/api/health`/`/api/providers` según corresponda, sale **≠0**, y escribe `docs/audit/smoke-<fecha>.json`. Con la base arriba: verde. Los dos informes pegados.
4. `wompi_payment_sheet.dart`: ningún camino renderiza PAN/CVV (`grep -n "_cvvCtrl"` solo en su declaración/dispose, no en un `TextFormField`); sin frases que afirmen transacción confirmada ni política inventada.
5. `provider_dashboard_screen.dart`: `grep -n "gross \* 0\.20\|gross \* 0\.08"` = 0 y rótulo coherente con el valor.
6. `fake-success-*.json` regenerado contra la base, agrupado por sitio, con cobertura declarada.
7. Las dos listas de nombres de suites (base y rama) + desglose con total.
