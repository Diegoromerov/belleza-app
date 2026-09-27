# Auditoría — entrega de A-05 por Antigravity (ronda 1)

**Fecha:** 2026-09-25 · **Auditor:** Hermes · **Procedencia verificada:** `origin/fix/ci-procedencia` @ `6268afff`, **1** commit sobre `fase-a/verdad-operativa` @ `c1069e9f` (`merge-base` = `c1069e9f` ✓), 2 archivos, +52/−7.

## Veredicto: **✓ ACEPTADA**

La cifra que era el objeto de la orden (**66 / 13 / 79**) **la verifiqué yo, por otra vía**, y es correcta. Además, esta entrega es la primera del ciclo que obedece la regla 4 sin que haya que pedírselo: donde no hay medición escribió **`NO MEDIDO`** y **`NO VERIFICADO`**, no una cifra.

---

## 1. Verificación independiente del reparto (la hice sobre los archivos, no leyendo su script)

| Qué medí | Resultado |
|---|---|
| Archivos `.test.js` en el árbol | **80** (todos bajo `backend/`) |
| De esos, dentro de un directorio `tests/` o `__tests__/` (= lo que colecciona `jest.config.js:8-10`) | **79** ⇒ su denominador es el correcto |
| Coincidencias por patrón (los 9 activos) | `geminiService` 1 · `geminiFallback` 1 · `auraToolExecutor` 1 · `contract` 1 · `biometric` **4 coleccionables** · `resilience` 3 · `contextCompressor` 1 · `fase5` 1 · `api.cors` 1 |
| **Unión de suites excluidas (distintas)** | **13** ✓ |
| **Dentro del gate** | 79 − 13 = **66** ✓ |
| `authRoutes` | ningún archivo del repo lo contiene ⇒ quitarlo **no** cambia el conjunto, y su 0 coincidencias es correcto |

## 2. C5 — el diff es exactamente lo pedido

`git diff fase-a → fix/ci-procedencia -- .github/workflows/ci.yml`: **solo comentarios** (`:89-93` y `:101-103`) y la **subcadena del patrón inerte** en las dos invocaciones (`:99` y `:108`). `--coverage`, el `continue-on-error: true`, `testMatch` y el **conjunto** de suites excluidas quedan intactos ✓. Los dos comentarios nuevos: `# 66 de 79 suites … 13 quedan excluidas por los 9 patrones activos`, `# Recuento de suites rojas/verdes en CI remoto: NO MEDIDO — bloqueado por el paso 7`, y en el paso no bloqueante `NO VERIFICADO`.

## 3. Retractación declarada — mi sospecha, no su error

Sospeché que el **13** estaba inflado porque en su listado `biometric.integration.test.js` aparecía **dos veces**. Medido: hay **dos archivos distintos con ese mismo basename** (dos rutas, un nombre) y su script imprime `path.basename(t)` ⇒ las dos líneas son dos suites reales. **El 13 es correcto y la sospecha queda retirada.** Lo dejo escrito porque la retracción cuesta y debe quedar en el registro, no desaparecer.

## 4. Cargo menor (proceso, no rechazo)

La salida pegada **no es un volcado crudo**: encabezón `- "biometric": 4 coincidencia(s)` seguido de **3** líneas. El número **reconcilia** (4 coleccionables de 5 archivos que casan), así que no hay error de cuenta — pero una evidencia editada a mano deja de ser evidencia. La regla #1 ya lo dice: un número sin su comando pegado no es un número.

## 5. Hallazgo nuevo — y es exactamente del tipo que A-05 existe para cerrar

**`backend/src/services/biometricCryptoService.test.js` existe y jest NO lo colecciona.** `testMatch` toma `**/tests/**/*.test.js` y `**/__tests__/**/*.test.js`; este archivo vive en `src/services/`. Consecuencia: **una suite completa no corre nunca**, ni en el gate ni en el paso no bloqueante — y el denominador «79» la esconde en silencio (80 archivos, 79 coleccionables). Fila **`CI-12`** en `DEUDA.md`.

**No se toca aquí:** arreglarlo (mover el archivo a `backend/tests/` o ampliar `testMatch`) **añade una suite al gate** y por tanto cambia qué considera verde el CI ⇒ decisión del **Dueño**, no de un agente. La orden de A-05 lo prohibía explícitamente, así que está bien no haberlo hecho.

## 6. Límites de esta auditoría

No corrí `npx jest --listTests` (haría falta el árbol con dependencias y la aprobación se retiró a mitad de la sesión). Mi verificación sale de **los 79 archivos coleccionables y de los patrones aplicados a sus rutas**, que es el mismo criterio que usa jest para `--testPathIgnorePatterns`/`--listTests`; el oráculo definitivo es su corrida, y coincide con la mía. Lo que **no** verifiqué: que en el runner remoto el paso no bloqueante realmente se ejecute (sigue `NO VERIFICADO`, y así está declarado en el propio archivo).

## 7. Qué se conserva

Todo. `ci.yml` queda con procedencia medida, con lo no medido declarado, y con un patrón inerte menos. No hay ronda 2: el único residuo es la decisión `CI-12`, que es del Dueño.
