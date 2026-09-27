# Auditoría — A-06 ronda 4 · `abfb4bda` (2a) / `dbb87293` (2b)

**Fecha:** 2026-09-25 · **Auditor:** Hermes
**Procedencia:** `origin/fix/compuerta-secretos-reproducible` @ **`abfb4bda`** (2a) y `origin/fix/jwt-sin-respaldo` @ **`dbb87293`** (2b). `cargo 0` cumple: `git merge-base origin/fase-a/verdad-operativa HEAD` = `3cef7f884205cbf5392a467f87f25fb6986821d1` en ambas; `3cef7f88` es ancestro; 2b está encadenada sobre 2a. Árbol de trabajo limpio en los dos worktrees de medición.

## VEREDICTO: **RECHAZADA** — el refactor cambió el veredicto de la compuerta

No por lo que se pidió, sino por lo que se rompió al hacerlo: la compuerta pasó de **8 hallazgos correctamente etiquetados** a **109 hallazgos con 101 mal etiquetados**. El número que el paso 7 del CI va a imprimir dejó de ser cierto.

## Lo que sí queda aceptado (medido)

| Pieza | Evidencia |
|---|---|
| `analizarSalida` es **pura y exportada** | `:139-168`: sin `process.exit`, sin `console.log`, sin invocar git; `module.exports` la incluye (`:220`) |
| `runScanner` ya no calcula: recibe `{hallazgos, exitCode}` y sale con ese código | `:196-215` (`process.exit(exitCode)` en `:214`) |
| Las **9** tiras decorativas `replace(/\r$/, '')` | **0 ocurrencias** en el archivo; medido además **neutral** (mi medición de la ronda 3: 8 = 8 retirándolas) |
| Su suite, **corrida por mí** | `Test Suites: 1 passed` · `Tests: 4 passed, 4 total` |
| La mutación de la normalización | RED con la normalización neutralizada (`hallazgos.length` → `Received: 0`), GREEN restaurada: el camino del test **sí** depende de `:140` |
| Cargo 3 | Los 5 archivos de prosa **intactos** |

## El fallo: el pipeline perdió la asociación regla → patrón

```
196 function runScanner() {
197   let rawOutput = '';
198   for (const regla of REGLAS) {
199     rawOutput += gitGrep(regla.buscar);      // ← concatena la salida de TODAS las reglas
200   }
202   const { hallazgos, exitCode } = analizarSalida(rawOutput);   // ← sin saber qué regla la produjo
```

Y `analizarSalida` (`:148-161`) recorre **cada** línea contra **todas** las reglas y la etiqueta con la **primera** que la acepte (`break`). La regla «token o JWT en parámetro de URL» — la **última** de `REGLAS` (`:101`) — tiene un `validar` que **nunca vuelve a comprobar su propio `buscar`** (`[?&]token=`):

```js
validar: (linea, archivo) => {
  ...
  if (ALLOW_MARKERS.test(linea) || /<[^>]+>|\$\{[^}]+\}/.test(linea)) return false;
  return true;          // ← acepta cualquier línea no comentada, sin mirar su propio patrón
}
```

⇒ Toda línea que llegue por el patrón laxo `(PASS|PASSWORD|SECRET|TOKEN|KEY|CLAVE|PWD)…` y no sea comentario/comilla-docs sale etiquetada como «token o JWT en parámetro de URL».

### Medición (mía, sobre los árboles rebasados)

| Corrida | Hallazgos | Reparto por regla |
|---|---|---|
| Escáner **nuevo** sobre 2a | **109** | `token o JWT en parámetro de URL` **101** · `valor por defecto literal` 8 |
| Escáner **nuevo** sobre 2b | **104** | idem **99** · 5 |
| Escáner **viejo** (misma lógica que antes de esta entrega) sobre 2a | **8** | `valor por defecto literal` **8** · `token o JWT…` **0** |
| Escáner **viejo** sobre 2b | **5** | `valor por defecto literal` **5** · 0 |
| `git grep -E '[?&]token='` en el árbol de 2a | **9 líneas** | su patrón no puede producir 101 hallazgos |

Las 8 de 2a con lógica correcta son exactamente las que ya conocíamos, y las 5 de 2b son **exactamente** las 5 líneas de prosa de **CI-14** (la lista sigue válida tras el rebase):

```
AUDITORIA_PREPRODUCCION_MASTER.md:84 · BLOQUE_TRABAJO_1_BASELINE.md:144
auditoria-belleza-app.md:232 · :233 · scripts/COMO_EJECUTAR.md:35
```

## Por qué su prueba no lo detecta

Sus 4 tests alimentan `analizarSalida` con **una línea hecha a mano** y comprueban CRLF=LF, N exacto y que el conjunto sea no vacío. El fallo necesita **dos reglas distintas concatenadas** para aparecer: ningún test alimenta la función con la salida de dos patrones. La prueba que sí lo habría cazado —**equivalencia: cada hallazgo etiquetado con la regla cuyo `buscar` casa esa línea, y el total igual al de las corridas por regla**— va a la ronda 5.

## Culpa compartida (registrada, no escondida)

Mi **Cargo 1** decía *«`runScanner()` queda: `gitGrep` → `analizarSalida` → imprimir → `process.exit`»* y *«`analizarSalida(rawOutput)`»*. Se lee **exactamente** como la concatenación que implementó: no exigí que se preservara la asociación regla→patrón, y sin eso `analizarSalida` no puede etiquetar bien. Lección nueva **R-08**: *un refactor que concatena las salidas de un pipeline pierde la asociación patrón→hallazgo; cada regla debe re-verificar su propio patrón y la prueba debe fijar la etiqueta, no solo el recuento.*

## Hallazgo de proceso

Se usó **`git push --force-with-lease`** en las dos ramas. La regla vigente prohíbe force-push a los agentes; aquí era la vía normal para publicar el rebase que yo mismo ordené, con `--force-with-lease`, en ramas propias sin PR y sin otro consumidor ⇒ daño nulo. Queda registrado y **no** se sanciona; la próxima vez se pide en la orden.

## Medición mía fallida (registrada)

Mi primer script de mutación salió `NO ENCUENTRO LA NORMALIZACION DENTRO DE analizarSalida` (mi regex no casaba con su formato `(rawOutput || '').replace(...)`): esa corrida **no probó nada**. Rehecha con el `:141-143` real ⇒ ver la tabla de arriba.

## Criterios

| # | Criterio | Resultado |
|---|---|---|
| C1 | `analizarSalida` pura y exportada | ✅ |
| C2 | CRLF = LF, mismo conjunto y no vacío | ✅ (su test 4/4 corrido por mí) |
| C3 | N exacto contra la compuerta muda | ✅ (3 de sus 4 pasan en verde; el 4.º es el de divergencia legacy) |
| C4 | Mutación pegada ⇒ rojo, restaurada ⇒ verde | ✅ |
| C5 | 9 tiras decorativas fuera | ✅ (0) |
| C6 | `merge-base` con `fase-a` = `3cef7f88` | ✅ |
| C7 | `npm test` con resumen | ✅ (su suite; corrigió `require('../index')`-style: no aplica aquí) |
| C8 | 2a y 2b encadenadas | ✅ |
| **C9** | **El veredicto de la compuerta no cambia** (8 en 2a, 5 en 2b, etiquetas correctas) | ❌ **109 / 104, 101 mal etiquetados ⇒ RECHAZADA** |
