# ORDEN A-06 · RONDA 5 (corta) — la etiqueta tiene que ser cierta

**Auditoría de la ronda 4:** `docs/audit/AUDITORIA-ENTREGA-A-06-RONDA-4-2026-09-25.md` (**RECHAZADA**)
**Rama:** la misma, `fix/compuerta-secretos-reproducible` (2a). **2b se rebasa encima de nuevo** y sigue encadenada.
> **Nota de citas (re-medidas el 2026-09-25 sobre `b545ef22`, ya en `fase-a`)**: las 5 líneas de prosa de CI-14 siguen **en las mismas líneas** —`scripts/COMO_EJECUTAR.md:35` incluida— y el árbol sigue dando **8** hallazgos con la lógica correcta, así que el Cargo 4 se puede aplicar tal cual.
**Lo aceptado de la ronda 4 (no se rehace):** `analizarSalida` pura y exportada, `runScanner` fuera del cálculo, las 9 tiras decorativas fuera, y tu suite (4/4, corrida por mí) con su mutación RED/GREEN.

## Qué se rompió

`runScanner` (`:196-202`) concatena la salida de **todas** las reglas y se la pasa a `analizarSalida`, que etiqueta cada línea con la primera regla dispuesta a aceptarla — y la regla «token o JWT en parámetro de URL» (`:101`) acepta cualquier línea no comentada **sin volver a mirar su propio `buscar`**.

Medido por mí sobre tus árboles rebasados:

| Corrida | Hallazgos |
|---|---|
| Escáner nuevo sobre 2a | **109** (101 mal etiquetados como «token o JWT en parámetro de URL») |
| Escáner nuevo sobre 2b | **104** (99 mal etiquetados) |
| Lógica anterior (correcta) sobre 2a | **8**, todos «valor por defecto literal» |
| `git grep -E '[?&]token='` en el árbol | **9 líneas** — su patrón no puede dar 101 |

Parte de la culpa es de mi orden: pedí `gitGrep → analizarSalida` sin exigir que se preserve la asociación regla → patrón.

## Cargo 1 — devuelve la asociación (una de las dos vías, elige y justifica)

**(A) Salidas por regla (mínimo cambio):** `analizarSalida(salidasPorRegla, options)` recibe `[{ nombre, crudo }]` — una por regla — y **solo** valida las líneas de cada regla contra esa regla. `runScanner` recolecta `gitGrep(regla.buscar)` por regla y se lo pasa. Sigue siendo pura y testeable.

**(B) Un solo grep + re-verificación propia:** se mantiene el grep unificado, pero **cada `validar` empieza comprobando su propio `buscar`** sobre la línea (la regla «token o JWT» debe volver a probar `[?&]token=`). Equivale a (A) si la re-verificación usa el mismo patrón.

En cualquiera de las dos: **una línea no puede quedar etiquetada con una regla que no la seleccionó.**

## Cargo 2 — la prueba que lo habría cazado (esto es lo que se pide)

La equivalencia, **con la etiqueta**, no solo con el recuento:

1. Fixture con **al menos dos reglas distintas** casando en el mismo blob crudo (p. ej. una línea `PGPASSWORD: "algo"` y otra `?token=abc123`), en CRLF y en LF.
2. Recorre el pipeline real y afirma: (a) cada hallazgo lleva **el nombre de la regla cuyo `buscar` casa esa línea**; (b) el total es **el mismo** que el de correr regla por regla; (c) sigue siendo ≥1 (nada de volver a quedar mudo).
3. **Mutación pegada:** vuelve a concatenar sin re-verificación ⇒ el test **rojo**, con la etiqueta equivocada a la vista. Pega la salida y restaura.

## Cargo 3 — el número real, como criterio

Con tu escáner arreglado, sobre **tu propio árbol**, la corrida tiene que dar **exactamente** esto:

- **2a ⇒ 8 hallazgos**, todos `valor por defecto literal para variable sensible`:
  `AUDITORIA_PREPRODUCCION_MASTER.md:84`, `BLOQUE_TRABAJO_1_BASELINE.md:144`, `auditoria-belleza-app.md:232`, `auditoria-belleza-app.md:233`, `scripts/COMO_EJECUTAR.md:35`, `backend/src/config/jwt.js:1`, `backend/src/config/jwt.js:2`, `backend/src/services/biometricCryptoService.js:18`.
- **2b ⇒ 5 hallazgos** (los mismos 5 de prosa; los 3 literales de código ya no están).

Si te sale otro número, **no lo "arregles" recortando reglas ni añadiendo exenciones**: párate y avísame con la salida.

## Cargo 4 — CONDICIONAL (solo con autorización explícita del Dueño)

Las **5 líneas de prosa** de CI-14 (`:84`, `:144`, `:232`, `:233`, `COMO_EJECUTAR.md:35`): sustituir **solo el valor** por `***` sin reescribir el texto del informe y volver a correr para pegar el conteo nuevo (debe quedar **3** en 2a y **0** en 2b). Sin autorización, **no toques esos archivos**.

## Criterios de cierre

| # | Criterio | Cómo se prueba |
|---|---|---|
| C1 | Ninguna línea puede etiquetarse con una regla que no la seleccionó | lectura + el test de C2 |
| C2 | Fixture multi-regla: etiquetas correctas, total igual a la corrida por regla, ≥1 | salida del test |
| C3 | **Mutación pegada** (volver a concatenar) ⇒ rojo por etiqueta | salida del fallo |
| C4 | `2a ⇒ 8` y `2b ⇒ 5`, con las rutas y líneas listadas arriba | salida cruda del escáner |
| C5 | CRLF = LF sigue verde y `npm test` con su resumen | salida |
| C6 | 2b rebasada encima; `merge-base` con `fase-a` = `3cef7f88` | comando |
| C7 | Sin `--force` sin `--force-with-lease` sin pedirlo antes | declaración |

## Prohibiciones

Recortar reglas, ampliar exenciones o tocar `EXENTAS` para bajar el número a 8 · `break` sobre la primera regla dispuesta sin re-verificación · eximir por prefijo · tocar los 5 archivos de prosa sin autorización · volver a concatenar «porque el agregado es más simple» · `--force`/`--force-with-lease` sin pedirlo en el mensaje.
