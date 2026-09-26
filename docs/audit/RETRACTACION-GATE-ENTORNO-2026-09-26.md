# RETRACTACIÓN — el entorno de mis mediciones del gate (2026-09-26)

**Quién:** Hermes (Auditor/Arquitecto) · **Qué retracto:** los números del gate que publiqué hoy y el «Cargo 3» de mi auditoría de A-07 ronda 3.
**Motivo:** mis corridas del gate **no exportaban `JWT_SECRET`**. La suite `adminPreciosRoutes` firma su token con un fallback propio que **no coincide** con el de la app, así que **sólo pasa si esa variable está en el entorno** — y el CI la define. Medí sin ella durante toda la jornada.

## 1. El mecanismo (verificado, no inferido)

```js
// src/tests/adminPreciosRoutes.test.js:19   (el test firma con esto)
const secret = process.env.JWT_SECRET || 'beauty_app_super_secret_key_2026_change_in_production';

// src/config/jwt.js:2,6,8                    (la app verifica con ESTO)
const DEFAULT_PROD_SECRET = '***';
const secret = process.env.JWT_SECRET || DEFAULT_PROD_SECRET;
```

Sin `JWT_SECRET` ⇒ firma ≠ verificación ⇒ el middleware rechaza ⇒ `403 esperado → 400` y `200 esperado → 400`: los 4 fallos que yo le atribuí al Ejecutor. El CI sí lo define (`ci.yml:38`).

**Medición que lo prueba (dos corridas, mismo commit `1a9f13ef`):**

| `adminPreciosRoutes` aislada | Resultado |
|---|---|
| **sin** `JWT_SECRET` | **4 failed / 1 passed / 5** |
| **con** `JWT_SECRET` (el del CI) | **5 passed / 5 total** |

## 2. Lo que retracto

1. **«`adminPreciosRoutes` es una afirmación falsa del Ejecutor, tercera ronda consecutiva»** ⇒ **FALSO MÍO.** Su «5/5 PASS» es correcto en el entorno del CI. El rojo era mi entorno, en las tres rondas (r1, r2 y r3), no su declaración. Registrado, no borrado: ver la nota de retractación al pie de `AUDITORIA-ENTREGA-A-07-RONDA-3-2026-09-26.md`.
2. **Los números del gate publicados hoy.** Re-medidos con el entorno completo del CI (`NODE_ENV`, `JWT_SECRET`, `DATABASE_URL`, `TEST_DATABASE_URL`, `RLS_ROLE_PASSWORD`), mismo comando exacto, checkout LF, base `glowtest_gate`:

| Commit | Antes (mi entorno, sin `JWT_SECRET`) | **Ahora (entorno del CI)** |
|---|---|---|
| base `b545ef22` | 10 suites / **59** tests · 551 totales | **10 suites / 55 tests · 543 totales · 2 `failed-to-run`** |
| A-07 r2 `835e9392` | 6 suites / **28** tests | **5 suites / 24 tests · 551 totales · 0 `failed-to-run`** |
| A-07 r3 `1a9f13ef` | 6 suites / **28** tests | **5 suites / 24 tests · 551 totales · 0 `failed-to-run`** |

Paso 9 (todas las suites, sin exclusiones, mismo entorno): base **18 suites / 77 tests** (614 totales) · r2 **14 / 46** · r3 **15 / 47**.

Los **4 tests** de diferencia son exactamente los 4 de `adminPreciosRoutes`. La secuencia comparable es **55 → 24 tests rojos** (−56 %) y **2 → 0** suites que no arrancan.

**Dos avisos de lectura, medidos:**
- Una segunda corrida de r3 dio **6 suites / 25 tests**: `ownerMultiSalonDashboard` aparece y desaparece entre corridas (ya estaba identificada como víctima alternativa del fantasma). La diferencia r2 → r3 es **ruido**, no una regresión: r3 sólo tocó `ciRagEvaluation.test.js`.
- De los **24 tests rojos** que quedan: **23** son la cascada de CI-40 y **1** es la comprobación de credenciales de `audit360-remediation` (CI-14). Los dos son **decisiones del Dueño**, no trabajo de tests.

3. **Nada más.** Lo que **no** cambia, porque no depende de `JWT_SECRET` y lo verifiqué por otra vía: CI-31 (ceguera al CRLF: 1 vs 39 hallazgos), la atribución del crash de worker (`execSync` con timeout ⇒ error no serializable ⇒ víctima `ciRagEvaluation`), el hallazgo **CI-40** (cargué la matriz real: ningún rol tiene `BUSINESS_PROFILE:CREATE`), la compuerta RLS sobre el tren (22 pruebas / 0 omitidas) y el fix del crash de la ronda 3.

## 3. Hallazgo nuevo — CI-41: la suite no es hermética

El defecto real que destapó mi error: **una suite cuyo veredicto depende de una variable de entorno no mide lo que dice medir.** Es la misma clase que la ceguera al CRLF del escáner viejo (CI-31): dos entornos distintos dan dos verdades distintas sobre el mismo commit. Se arregla **en la suite** (que fije su propio secreto de test antes de cargar la app), y la prueba exigida son **las dos corridas** — con y sin `JWT_SECRET` — dando lo mismo. Va como Cargo 1 de la ronda 4 (revisada).

## 4. Regla que agrego a TRAMPAS (falla propia)

- **Mi entorno de medición tiene que replicar el del CI variable por variable, no aproximarlo.** Faltar `JWT_SECRET` me hizo publicar cuatro tests rojos falsos y acusar al Ejecutor tres rondas seguidas. Antes de publicar un número del gate: enumerar las variables del `ci.yml`, exportarlas todas, y **declarar cuáles exporté** junto al número.
- **Corolario:** cuando dos mediciones del mismo commit no coinciden, la hipótesis a descartar **primero** es la mía (entorno, finales de línea, base), no la del otro. Ya me pasó con el CRLF (CI-31) y ahora con `JWT_SECRET`.
