# Los números del gate, medidos — y por qué a veces aparece un rojo «fantasma»

**Fecha:** 2026-09-26 · **Autor:** Hermes (Arquitecto/Verificador) · **Rama:** `fase-a/verdad-operativa` @ `b545ef22`
**Condiciones:** checkout **LF**, base limpia `glowtest_gate` (rol de aplicación `app_rls_user`), y el **comando exacto del CI** (paso 8):
`npm test -- --coverage --testPathIgnorePatterns="geminiService|geminiFallback|auraToolExecutor|contract|biometric|resilience|contextCompressor|fase5|authRoutes|api.cors"`

## Lo medido (6 corridas)

| Corrida | suites rojas | tests rojos | tests totales | ocurrencias de `failed to run` |
|---|---|---|---|---|
| 1 | 11 | 59 | 543 | **2** |
| 2 | 12 | 60 | 543 | **2** |
| 3 | **10** | 59 | **551** | 0 |
| 4 | **10** | 59 | **551** | 0 |
| 5 | **10** | 59 | **551** | 0 |
| 6 | **10** | 59 | **551** | 0 |

Nota sobre esa última columna: el bloque «Test suite failed to run» se imprime **inline y otra vez en el resumen final**, así que **2 ocurrencias = 1 suite víctima**. Y en las **3 corridas que crashearon** (comando del CI) la víctima fue **siempre la misma: `ciRagEvaluation.test.js`** — sólo un ensayo previo con `--maxWorkers=2` la movió a `ownerMultiSalonDashboard`. Eso **descarta la lectura de «víctima al azar»** y apunta a que el error circular se produce **en esa suite o en algo que ella comparte** (proveedor de embeddings / breaker), aunque en aislamiento dé 8/8 sin un solo rechazo no manejado.

**El rojo honesto del gate es 10 suites / 59 tests** (10 suites / 58 en la corrida 3, según cómo caiga un test intermitente). Cuando aparece un `Test suite failed to run`, el número sube a 11-12 **y el total de tests baja de 551 a 543**: exactamente los 8 tests de la suite que el arnés dejó de correr. No es un hallazgo: es el arnés.

**Regla:** el número que se cita es el **mínimo medido con 0 `failed-to-run`**, no el peor. Y toda tabla de rojos declara si hubo `failed-to-run`.

## El mecanismo, atribuido (no era el arnés de jest «en general»)

```
FAIL <una suite al azar>
  ● Test suite failed to run
    TypeError: Converting circular structure to JSON
        --> starting at object with constructor 'Error'
        --- property 'error' closes the circle
        at stringify (<anonymous>)
      at messageParent (…/jest-worker/build/workers/messageParent.js:29:19)
```

Cadena medida leyendo el código instalado:
`jest-circus/build/testCaseReportHandler.js` → `jest-runner/build/testWorker.js:102` (`sendMessageToJest`) → `jest-worker/build/workers/messageParent.js:29` → `process.send([PARENT_MESSAGE_CUSTOM, message])` → **JSON.stringify del mensaje**.

⇒ Cuando una suite deja un **rechazo no manejado** cuyo error **no es serializable** (lleva una referencia circular; el ciclo se cierra por una propiedad llamada `error`), el worker **muere al reportarlo**: el error real **nunca llega al reporte** y jest etiqueta como «no pudo correr» a una suite **víctima** (en las 3 corridas registradas, siempre `ciRagEvaluation.test.js`).

**Evidencia de que la nombrada es víctima, no culpable:**
- `ciRagEvaluation.test.js` **en aislamiento: 8/8 verdes**, sin un solo rechazo no manejado (medido con un gancho de `unhandledRejection`).
- La víctima registrada con el comando del CI es **siempre `ciRagEvaluation.test.js`**; el ensayo con `--maxWorkers=2` movió la víctima a `ownerMultiSalonDashboard` ⇒ el defecto **no se arregla con workers**: se mueve.

**Lo que sigue sin atribuir:** **qué** suite produce el error circular (el gancho no llegó a activarse: ese `jest.config.js` no tiene `setupFiles`, así que mi edición no se aplicó — falla mía de método, se puede reintentar con `--setupFiles=` por línea de comandos). El crash se reprodujo en **2 de 6** corridas.

## Lo que esto NO cambia

El núcleo rojo sigue siendo el que ya se clasificó (5×500, 2 contratos rotos, 3 de semántica) — ver `CLASIFICACION-GATE-2026-09-26.md`. Lo que cambia es **cuánto sumar**: cualquier tabla que diga «11/12 rojas» sin declarar `failed-to-run` está inflando el rojo con un defecto del arnés.

## El paso 9 (no bloqueante): todas las suites, sin exclusiones

Dos corridas con la suite completa (`npx jest --silent --ci`, **sin** el comando del gate y sin `--coverage`), LF y base real:

| Corrida | suites rojas | tests rojos | tests totales | failed to run |
|---|---|---|---|---|
| A | 19 | 81 | 614 (1 skipped) | 0 |
| B | 19 | 81 | 614 (1 skipped) | 0 |

**Lectura:** el gate excluye 10 patrones que alcanzan a **13 suites** (81 − 68) y esas 13 aportan **9 de esas 19 rojas** ⇒ el no bloqueante ya corre en 19 y el bloqueante en 10. Al aterrizar, lo que se declara rojo es eso: **10 en el paso que bloquea, 19 en el que no**, y el paso 9 nace con `continue-on-error` a propósito.
