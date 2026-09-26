# Auditoría independiente — Entrega A-07 · Ronda 4

**Fecha:** 2026-09-26 · **Auditor:** Hermes (Arquitecto/Verificador) · **Rama:** `fix/gate-clasificado`
**Procedencia verificada por mí:** remoto = local = `4e9145ad9b4900ba52b8f6704ec8ef168f4a3313`; base `b545ef22` **es ancestro** ✓; 3 archivos (`jest.config.js` +1 · `src/tests/adminPreciosRoutes.test.js` +3/−1 · `src/tests/setupHarness.js` +21).
**Veredicto:** **ACEPTADA** ⇒ **A-07 CERRADA**, con un residuo declarado (CI-37: mitigación sin demostración).

## 1. Cargo 1 — hermetismo: ACEPTADO ✓ (CI-41 CERRADA)

En vez de fijar un secreto de test, importó **el resolvedor de la propia app** (`getJwtSecret` de `src/config/jwt.js`, que ya lo exportaba en `:5`/`:21`): el test firma con **exactamente** el secreto con el que `authMiddleware` verifica ⇒ la coincidencia queda **por construcción**, no por configuración. Es mejor que la solución que yo había pedido.

**Medición mía, en su commit, aislada:**

| `adminPreciosRoutes` aislada | Resultado |
|---|---|
| **con** `JWT_SECRET` exportado | **5 passed / 5 total** |
| **sin** `JWT_SECRET` | **5 passed / 5 total** |

⇒ El veredicto ya no depende del entorno. **CI-41 CERRADA.**

## 2. Cargo 2 — CI-37: presencia sí, demostración no

El arnés (`src/tests/setupHarness.js`) registra `process.on('unhandledRejection')` y `process.on('uncaughtException')` y **sólo hace `console.error`**; se registra en `setupFiles` (`jest.config.js`). Su efecto real depende de que los *listeners* propios de Jest sigan fallando el test (lo hacen) ⇒ **es inocuo, y está medido que no interfiere**: el gate sobre su commit queda **idéntico** (5 suites / 24 tests, 0 `failed-to-run`, **0 avisos del arnés**).

Lo que **no** está demostrado —y lo digo también de mi propia prueba— es que **impida el crash original**. El crash era un fallo de **serialización worker → proceso padre** (`testCaseReportHandler` → `messageParent` → `process.send` con un error circular). Ninguna de las dos mutaciones llega ahí:

| Mutación | Resultado |
|---|---|
| la suya (rechazo circular dentro de un test) | `Tests: 1 failed, 1 total` — el manejo **normal** de Jest, y su propio test de arnés quedó **en rojo** (el nombre promete «caught and sanitized by harness») |
| la mía (`Promise.reject(circular)` en un test, worker) | `Tests: 1 failed, 1 total` y **0 avisos del arnés** ⇒ el arnés **no se disparó** |
| mi control (mismo test **sin** `setupFiles`) | **idéntico**: `Tests: 1 failed, 1 total` ⇒ la mutación **no discrimina** |

⇒ El arnés, tal como está, **no se activó en ninguna de las dos pruebas**, y la única que podría activarlo exige reproducir el fallo de serialización original — que la ronda 3 ya eliminó en el código. No es un bloqueo; es un residuo que se declara como tal: **mitigación presente, eficacia no demostrada**, y el productor real arreglado por la ronda 3 (`safeExecSync`). Endurecimiento barato que sugiero si algún día se retoma: que el arnés **falle por sí mismo** (marcar el test/el proceso) y no dependa de que Jest lo haga.

## 3. Cargo 3 — alcance declarado: correcto ✓

`business*` (4 suites) = cascada de **CI-40**; `audit360-remediation` = **CI-14**. Ambos **decisiones del Dueño**, ninguna trabajo de tests. Coincide con mi medición independiente: el gate sobre `4e9145ad` da **5 suites / 24 tests rojos** = **23** de la cascada + **1** de credenciales.

## 4. Números del cierre (entorno completo del CI, medidos por mí)

| Commit | paso 8 (gate) | paso 9 (todas) |
|---|---|---|
| base `b545ef22` | 10 suites / **55** tests · 2 `failed-to-run` | 18 / **77** |
| A-07 r1+r2 `835e9392` | 5 suites / **24** | 14 / **46** |
| A-07 r3 `1a9f13ef` | 5 suites / **24** | 15 / **47** |
| **A-07 r4 `4e9145ad`** | **5 suites / 24 tests · 0 `failed-to-run`** | — |

⇒ A-07 llevó el rojo del gate de **55 → 24 tests** (−56 %), las suites que no arrancan de **2 → 0**, y dejó el rojo restante **enteramente** en manos de dos decisiones del Dueño.

## 5. Residuos declarados (no bloquean el cierre)

1. **CI-37**: mitigación sin demostración (arriba).
2. **CI-40 / CI-14**: los 24 tests rojos que quedan.
3. La rama entra al tren de aterrizaje como **décima**.
