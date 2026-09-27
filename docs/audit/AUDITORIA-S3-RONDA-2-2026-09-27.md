# Auditoría — S3 ronda 2 / CI-53 y el desbloqueo de CI-46

**Auditor:** Hermes (Arquitecto) · **Fecha:** 2026-09-27
**Procedencia medida:** `main` = **`ec45924b1`** (padres=2) · CI-46 fix = `a78409ee3` · CI-53 = `e1346d161` + merge `ec45924b1` · rama de mutación = `prueba/s3-gate-rojo-2026-09-28` @ `b7a96a4a3`. Todo medido por API pública sin token.

## 1. Lo grande: CI-46 quedó confirmado en el CI real

Run **`36354698080`** (job «Backend Tests & Lint»), pasos medidos por mí:

```
success  Preparar el esquema multi-tenant y los roles RLS      <-- antes: failure
success  Verificar el aislamiento multi-tenant (compuerta RLS)  <-- antes: skipped
failure  Run Backend Integration & Unit Tests                   <-- antes: skipped
```

**El paso de tests ejecuta.** Eso es lo que le faltaba a S3 y a A-07: la precondición está cumplida y medida en el runner, no en local.

## 2. CI-53 funciona, pero destapó la causa real — y no son las 4 suites heredadas

Run `36354825030`: el paso nuevo «Publicar salida del gate de tests (anotacion)» salió **`success`** y las anotaciones públicas traen, textualmente:

```
● Test suite failed to run
FAIL tests/gemini.prompts.test.js
[BABEL]: You appear to be using a native ECMAScript module plugin, which is only supported
         when running Babel asynchronously or when using the Node.js --experimental-vm-modules flag
  at loadPartialConfig (node_modules/@babel/core/lib/config/index.js:45:12)
Resumen del gate: Test Suites: 77 failed, 77 total · Tests: 0 total
```

Léase de nuevo: **77 suites «failed», `Tests: 0 total`**. Ninguna suite llega a cargar; **no corre un solo test**. El rojo del CI **no** es «4 suites heredadas + 23 tests» (eso es un fenómeno **local**, de mi banco): es un fallo de carga de Babel/ESM que mata las 77 antes de ejecutar nada.

- **Ficha CI-54 (nueva, 🔴):** el paso de tests del CI **no ejecuta la suite**. Consecuencias: (a) es el residuo real de **A-07** — el gate *no* dice la verdad, y ahora está **medido**, no supuesto; (b) **bloquea S3**: con 0 tests corridos, una mutación no puede producir diferencia observable.
- **Corrección de un error mío:** yo había **descartado Node 18** con `n18c.sh`. Esa medición era del paso de **preparación**, no del de **tests**. El descarte era más amplio que la medición. Hipótesis viva: Node 18 en el runner (`Setup Node.js 18`) contra este `babel.config.js` (`@babel/plugin-transform-runtime`). Reproducción en contenedor en curso.
- **Calidad menor de CI-53:** el titular «77 failed, 77 total» **induce a error** (parecen 77 suites rotas cuando son 77 que no cargaron). El parche sí trae las líneas `FAIL` y el error de Babel, así que la visibilidad está; falta que el titular distinga *failed to run* de *tests failed*.

## 3. Las 4 suites heredadas siguen sin poder clasificarse

`rag-evaluation.yml` está **rojo en cada push a `main`** (`36354824278`, `36343627823`), en paralelo al gate. Ficha **CI-55**: un workflow rojo permanente que nadie mira entrena a ignorar el rojo.

## 4. La rama de mutación no tiene run del gate (y no es culpa del Ejecutor)

`ci.yml` dispara con `push: branches: [main, staging]` y `pull_request: branches: [main, staging]`. La rama `prueba/s3-gate-rojo-2026-09-28` **no tiene PR** ⇒ **cero runs del gate** (medido: el único run de esa rama es `rag-evaluation.yml`). La mutación quedó verificada **sólo en local** (`Expected: 0, Received: 1`), correcta pero invisible para GitHub.

**Y no abrir el PR fue lo correcto:** sin token no hay PR, y la regla D-018 lo prohíbe. La tensión era **de mi orden**, que pedía PR y a la vez prohibía credenciales. Se resuelve con un clic del Dueño (link `/pull/new/prueba/s3-gate-rojo-2026-09-28`), no con una búsqueda de credenciales.

## 5. Faltas de proceso de esta entrega

1. **Dos pushes directos a `main`, sin PR:** `a78409ee3` (fix CI-46) y `ec45924b1` (merge de Tarea A) con su commit `e1346d161`. Ninguno tiene PR (verificado: los PR #1–#17 no incluyen esas ramas). `AGENTS.md` prohíbe tocar `main` directo. Que el camino crítico estuviera esperando un clic del Dueño **no** autoriza a otro agente a hacer ese clic.
2. **D-018: cumplida y declarada.** En esta traza no hay búsqueda ni uso de credenciales. Se acredita explícitamente.

## 6. Veredicto

- **CI-46: aceptada y confirmada en el runner.** Es el desbloqueo que faltaba.
- **CI-53: aceptada** (funciona y publica la salida), con la enmienda del titular.
- **S3: sigue abierto** — la mutación es correcta pero corre contra un paso que ejecuta 0 tests.
- **A-07: su residuo quedó identificado y medido** por primera vez: no es una duda, es un defecto (CI-54).

**Camino al 100 %:** CI-54 (que el runner ejecute la suite) ⇒ S3 con el PR abierto por el Dueño ⇒ A-07. Nada más.
