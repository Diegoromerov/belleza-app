# ORDEN Fase A · RONDA 4 (corta) — que el guardián vea lo que la app tiene

**Auditoría que la origina:** `docs/audit/AUDITORIA-ENTREGA-FASE-A-R3-S1-S4-2026-09-25.md`
**Veredicto de la ronda 3:** **S1 ✓ ACEPTADO** — y lo verifiqué yo, corriendo el servidor con la base muerta: `/api/products` ⇒ **503 + `X-GlowApp-Degraded`**, `/api/health` y `/api/providers` ⇒ 503 con su propia semántica, `/` (estáticos) ⇒ **200**, y el candado montado **antes** de los routers (`index.js:227` vs `391+`). **No toques el candado.** S4 quedó a medias por una razón concreta que medí.

## Cargo 1 (el único grave) — el guardián no ve las rutas nuevas de la app

Medición mía sobre tu commit `9a86a902`: planté `GET /api/__hermes_fake` (responde 200 con la base muerta, registrada **antes** del candado) y corrí `npm run smoke:surfaces` **sin tocar una línea de tu código**:

```
📊 Estado del servidor detectado (probes inicio): IsDegraded=true, HealthStatus=503
📋 Resumen de Smoke Test (122 superficies probadas): Faked Success Totales: 0
✅ SMOKE TEST EXITOSO                                   EXIT=0
```

Mi ruta **no aparece**, ni en la salida ni en el informe. Por qué: el guardián recorre el **inventario commiteado** (`docs/audit/routes-2026-09-24.json`, **308** rutas) y mi ruta tiene **0** ocurrencias ahí. Tu corrida roja declaró **123** superficies ⇒ para aquella prueba **regeneraste el inventario a mano**: el guardián ve lo que el inventario dice, **no lo que la app tiene**. Es exactamente la clase de defecto que S4 venía a cerrar (la cobertura la define un artefacto estático).

**Qué se pide (una de las dos, elige y justifica):**
- **(a) Inventario generado al inicio:** el smoke obtiene la lista del **stack vivo** — `listRoutes.js` ya lo hace (`require('../index')` + `app._router.stack`) — y prueba **esa** lista; el JSON commiteado queda como registro histórico con su fecha de generación.
- **(b) Chequeo de deriva:** el smoke calcula el conteo vivo y **falla** si el inventario no coincide, **nombrando** lo que falta y lo que sobra.

## Cargo 2 — `empty_like`: fuera

Se calcula (`smokeSurfaces.js:80`) y **no decide nada** (`:115`). Con la regla de clase es redundante. Elimínalo del resultado, o hazlo decidir y dilo. Se pidió en la ronda 3 y no se hizo.

## Cargo 3 — el informe rojo no puede perderse

Un único nombre `smoke-<fecha>.json` ⇒ tu corrida **verde sobrescribió la roja**, y lo que quedó commiteado es el verde. Lo rojo es la evidencia que importa. Usa sufijo por estado (`smoke-<fecha>-degraded.json` / `smoke-<fecha>-ok.json`) o conserva los dos.

## Cargo 4 — la allowlist no puede eximir de ser mirada

Hoy sólo `/api/health` y `/api/providers` tienen comprobación dentro de la rama de allowlist; cualquier otra ruta exenta (hoy `/api/test-db`) queda **sin verificar** si responde 2xx estando degradada. Que la comprobación sea **de clase también dentro de la allowlist**: exenta del candado, **no** exenta de ser mirada.

## Cargo 5 — declarar el alcance del candado (para el Dueño)

Con la base muerta, el candado responde 503 también en superficies de **C-01/C-02/C-03** — medido: `/api/payments/wompi-webhook` (POST incluido), `/api/disputes`, `/api/tickets`, `/api/auth/login`, `/api/admin/metrics`. Que el webhook reciba 503 y Wompi reintente es defendible, **pero es una decisión de dinero**: deja escrito en el PR/commit **qué superficies de dinero e identidad quedan tras el candado y con qué semántica**, para la firma del Dueño (**CI-16**). No decides tú si eso se queda así; lo declaras.

## Criterios de cierre

| # | Criterio | Cómo se prueba |
|---|---|---|
| C1 | El guardián nombra una ruta que la app tiene y el inventario **no**, sin regenerar el inventario a mano ni tocar el guardián | mi ruta plantada (`/api/__hermes_fake`) aparece en su salida, con la prueba corriéndola yo |
| C2 | Con la base arriba: **`exit 0`** | salida pegada |
| C3 | Informe **rojo y verde**, los dos, en `docs/audit/` | los dos archivos |
| C4 | `empty_like` fuera del resultado (o decidiendo) | el JSON del informe |
| C5 | Ninguna ruta exenta queda sin comprobación de 2xx engañoso | el bloque de allowlist, pegado |
| C6 | Alcance del candado sobre C-01/C-02/C-03 declarado | el texto, en el PR o el commit |

## Prohibiciones

Revertir o mover el candado · recortar el universo de superficies · tocar `paymentRoutes.js`, wallet, disputas u OTP (**C-01/C-02/C-03**) · **regenerar el inventario a mano para hacer pasar C1** (si se regenera, que lo haga el propio smoke en su arranque, no tu mano) · ampliar `testPathIgnorePatterns`.
