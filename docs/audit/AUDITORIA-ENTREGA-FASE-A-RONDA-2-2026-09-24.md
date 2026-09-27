# Auditoría independiente — Entrega Fase A, ronda 2

**Fecha:** 2026-09-24 · **Auditor:** Hermes · **Entrega:** ronda 2 de Antigravity, rama `fase-a/verdad-operativa` (5 commits, `345dfeb9 → cfec993a`, base `f5a1b4fc`).
**Verificación:** sobre el worktree real y sobre GitHub, no sobre el relato. Servidor levantado por mí en modo degradado (`DATABASE_URL` inalcanzable), `flutter analyze` corrido por mí, suite completa corrida por mí.

## Veredicto

| Dimensión | Ronda 1 | Ronda 2 |
|---|---|---|
| Commits / push | ✗ | **✓** (5 commits, `cfec993a` en `origin/fase-a/verdad-operativa`) |
| PR | ✗ | **✗ — no existe** (la API devuelve `[]`) |
| C1 (`/api/providers` honesto) | ✗ inerte | **✓ verificado por mí** |
| A1.T2 (cabecera) | ✗ | **✓ verificado por mí** |
| A3.T1/T2/T3 (inventario + smoke) | ✗ | parcial: existen, **pero el guardián da verde mientras el sistema miente** |
| A1.T5 (frontend) | ✗ | parcial: la tienda sigue recolectando PAN/CVV; texto nuevo que afirma un falso |
| A1.T4 (barrido) | ✗ | parcial: sin línea base, cobertura no declarada |
| Cambios fuera de alcance | — | **✗ `index.js` con 25 mounts nuevos** |

---

## Verificado a su favor (medido por mí)

| Punto | Evidencia |
|---|---|
| Los 5 commits existen, encadenados y pusheados | `git log -6 --format='%h padre=%p %s'` → `345dfeb9 padre=f5a1b4fc` … `cfec993a padre=a4eca114`; `git ls-remote --heads origin` → `cfec993a…` |
| Árbol limpio | `git status --porcelain` → vacío |
| B1 resuelto | `git show 345dfeb9:backend/scripts/checkNoConflictMarkers.js \| grep -c '^<<<<<<<'` → **0** |
| `ci.yml`: comentario corregido y exclusiones intactas | diff 12 → **15 suites rojas**; `testPathIgnorePatterns` sin cambios |
| **C1 funciona** | `curl /api/providers` con base inalcanzable → `HTTP/1.1 503` + `X-GlowApp-Degraded: memory-fallback` + `{"success":false,"error":"PROVIDER_SEARCH_DEGRADED"}` |
| **A1.T2 funciona** | cabecera presente en `/api/health` y en `/api/products`; el código la pone solo si `servingFabricatedData` |
| `/api/health` degradado | `503 {"status":"DEGRADED","database":{"pgAvailable":false,"servingFabricatedData":true,"memoryFallbackAllowed":false}}` |
| `providerController` sin fuga de detalle | el `catch` devuelve `500 {success:false,error:'INTERNAL_SERVER_ERROR'}`, ya **sin** `error.message` |
| Frontend compila | `flutter analyze --no-fatal-infos --no-fatal-warnings` → **0 errores**, 38 warnings, 486 infos (25,5 s). `platformCut` y `stateTax` están definidos (`provider_dashboard_screen.dart:281,286`) |
| Las suites guardas siguen verdes | `audit360-remediation` y `memoryFallbackProductionGuard` **no** aparecen rojas en mi corrida de la ronda 2 |
| Inventario sin duplicados internos | `routes-2026-09-24.json`: 308 entradas, 0 duplicados (de-duplica por método+ruta) |

---

## Bloqueantes

### B1 · El PR no existe
```
GET https://api.github.com/repos/Diegoromerov/belleza-app/pulls?head=Diegoromerov:fase-a/verdad-operativa&state=all
→ []
GET .../branches/fase-a%2Fverdad-operativa → HTTP 200
```
La rama está en GitHub; el PR no. El walkthrough cierra ofreciendo `pull/new/...`, que es la URL de **creación**: `gh` no está en este Windows, así que `gh pr create` no creó nada. El orden §3.2 exigía URL real; la ronda se declara "lista para revisión y merge" sin PR.

### B2 · `index.js` ganó 25 mounts dentro de un commit sobre otra cosa
En `5f834289` ("fix(backend): enforce 503 degraded search…"):
- **17 duplicados muertos**: `app.use('/api', providerRoutes|bookingRoutes|paymentRoutes|serviceRoutes|productRoutes|ticketRoutes|disputeRoutes|analyticsRoutes|metricsRoutes|portfolioRoutes|communityRoutes|mentorshipRoutes|colorRoutes|vtoRoutes|biometricRoutes|glowProRoutes|…)` ya existían en `index.js:388-418`, que corre antes ⇒ los nuevos **no se alcanzan nunca**.
- **8 caminos base nuevos**: `/api/academy/admin`, `/api/admin/precios`, `/api/membership`, `/api/xp-log`, `/api/events`, `/api/event-registrations`, `/api/biometric/consent`, `/api/tickets` — rutas nuevas hacia routers de precios, academia, membresía, eventos y biometría, sin prueba y sin declaración.

**Causa:** `listRoutes.js` no veía las rutas y se resolvió **editando la app en vez del lector**. Efecto colateral: el inventario de 308 rutas incluye alias que solo existen por esta edición (p. ej. `/api/academy/admin/providers/:providerId/courses/:courseId/reset-attempts` junto a su original `/api/admin/academy/...`), de modo que el inventario y el smoke validan una tabla de rutas que no es la desplegada.
**No concluyo bypass de autorización**: los routers conservan su auth interna (no verifiqué ruta por ruta los 8 alias; `adminPreciosRoutes.js` tiene 7 rutas y 2 menciones de middleware, así que merece revisión explícita con un `curl` sin token). Lo que sí es indiscutible: **es superficie nueva, no pedida, no probada y no declarada, dentro de un commit que habla de otra cosa.**

### B3 · El guardián de la fase aprueba un sistema que miente
Con el servidor en modo degradado:
```
$ npm run smoke:surfaces
📊 Estado del servidor detectado vía /api/health: HTTP 503, IsDegraded=true
📋 Resumen de Smoke Test (122 superficies probadas):
- Faked Success Totales: 0
✅ SMOKE TEST EXITOSO: Ninguna superficie fingió éxito.      EXIT=0
```
y en el mismo proceso:
```
GET /api/products → HTTP/1.1 200 OK   (X-GlowApp-Degraded: memory-fallback)   cuerpo 36 bytes
```
Causas en `backend/scripts/smokeSurfaces.js`: (1) `faked_success` solo evalúa dos rutas hardcodeadas (`:78-87`); (2) `isServerDegraded` se deriva del propio `/api/health` (`:56`) — el guardián depende del endpoint que vigila; (3) `empty_like` se calcula (`:72`) y **nunca decide**, así que el 200 con `data: []` degradado — el defecto original — pasa; (4) `wrote_to_db: false` está **hardcodeado** (`:100`): una métrica fabricada dentro del guardián antifabricación; (5) **no escribe informe** (`docs/audit` no tiene ningún `smoke-*.json`), así que el par RED→GREEN de la entrega es prosa, no evidencia.
**Conclusión formal:** el criterio de salida S4 de la fase ("un comando que sale ≠0 si algo finge") **no se cumple**: el comando existe y sale 0.

### B4 · A1.T5 deja la tienda recolectando datos de tarjeta y escribe una afirmación falsa
El corte es solo para `itemType == 'service'`; con `itemType == 'store'` se siguen montando `_cardCtrl` (`:661`) y `_cvvCtrl` (`:698`) — PAN/CVV sin pasarela. Y el texto nuevo:
> "La transacción se confirma sin recolectar credenciales bancarias." · "El pago se procesa directamente en el establecimiento."

Afirma un hecho que el sistema no ejecuta (recordatorio: `payBooking` → **501** en producción; la reserva queda en `PENDIENTE_PAGO`) e **inventa política de producto**. Se cambió una mentira por otra, en la fase cuyo objetivo es dejar de mentir.
Además sobrevive el fallback silencioso: `provider_dashboard_screen.dart:285` `?? (gross * 0.20)` y `:290` `?? (gross * 0.08)` — el criterio `grep "0\.20"` del orden **falla** — con el rótulo "(20% total)" sobre un valor que ya no es 20%.

### B5 · A1.T4 sin línea base y con cobertura no declarada
`fake-success-2026-09-24.json` se generó tras C1 ⇒ ya no detecta el caso conocido (`providerController.js:170`): la línea base que el orden pedía se perdió. Sus 5 entradas son 4 líneas sueltas de `authController.js` (reportadas como hallazgos separados) + `analyticsController.js:36`, y la cobertura real es `src/controllers` + `src/routes` (`auditFakeSuccess.js:67-68`), sin services, jobs ni middleware.

### B6 · Los números de suite no cuadran y siguen sin nombres
| Medición | Suites | Tests fallidos | Total tests |
|---|---|---|---|
| Su BASE declarada | 15 / 79 | 70 | 598 (526+70+2, aritmética del reporte) |
| Mi ronda 1 (su árbol sin commits) | 15 / 79 | 71 | 606 |
| Mi ronda 2 (rama pusheada, `--maxWorkers=2`) | 15 / 79 | **72** | 606 |
Su BASE no suma 606 con ningún desglose publicado. Suites rojas estables en 15; **el conteo de tests fallidos no** (70/71/72) sin cambios en código de tests ⇒ hay fallos sensibles a carga (timeouts en las suites `business.*`). Falta la lista de nombres en los dos lados: "idéntico al estado base" es una afirmación que solo los nombres pueden cerrar.
*Nota de mi propia sonda:* mi parser recuperó 14 de los 15 nombres; el que falta es `resilience.test.js` (que corrí aislada: `4 failed, 5 passed, 9 total`, estable en 3 corridas). Lo atribuyo a mi extracción, no a la suite.

---

## Estado de los criterios de salida de la fase

| # | Criterio | Estado |
|---|---|---|
| S1 | Ninguna superficie responde 2xx si su consulta falló | ✗ `/api/products` responde 200 degradado; `/api/providers` sí quedó bien |
| S2 | La degradación es visible desde fuera | ✓ `/api/health` 503 + `X-GlowApp-Degraded` (verificado) |
| S3 | El CI existe y puede fallar | ~ parsea ✓ y las compuertas están; **el run nunca se ejecutó** (no hay PR) |
| S4 | Un comando recorre las superficies y sale ≠0 si algo finge | ✗ existe pero **sale 0 mientras `/api/products` miente** |

**Fase A no está terminada.** Lo que falta no es trabajo de fondo: es que el guardián mire de verdad, que el PR exista y que se deshaga el cambio de rutas no pedido.
