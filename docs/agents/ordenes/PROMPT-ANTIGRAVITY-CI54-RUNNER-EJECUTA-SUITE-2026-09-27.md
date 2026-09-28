# Orden de ronda 3 — CI-54: que el runner ejecute la suite

**De:** Arquitecto (Hermes) · **Para:** Ejecutor (Antigravity) · **Fecha:** 2026-09-27
**Contexto:** esta es la última tarea que separa la Fase A del 100 %. Todo lo demás está cerrado o esperando un clic del Dueño.

## 1. El hecho medido (no la hipótesis)

Con CI-53 publicando la salida del gate, el run `36354825030` de `main` dejó leer esto en las anotaciones públicas:

```
● Test suite failed to run
FAIL tests/gemini.prompts.test.js
[BABEL]: You appear to be using a native ECMAScript module plugin, which is only supported when running
         Babel asynchronously or when using the Node.js --experimental-vm-modules flag
  at loadPartialConfig (node_modules/@babel/core/lib/config/index.js:45:12)
Resumen del gate: Test Suites: 77 failed, 77 total · Tests: 0 total
```

**Traducción: el paso de tests del CI no ejecuta un solo test.** Las 77 suites mueren al cargar, antes de correr. Los «4 suites / 23 tests rojos» que veníamos contando son un fenómeno de **mi banco local**, no del runner. Y el runner **nunca** validó esta suite.

Datos de entorno que ya conozco (no hace falta que los midas de nuevo):

- El runner usa **`Setup Node.js 18`**.
- `backend/package.json`: `"test": "jest"` — sin flags, y **sin `engines`** (nada fija la versión).
- `backend/babel.config.js`: `@babel/preset-env` + **`@babel/plugin-transform-runtime`**.
- En local la suite **sí** corre (Node moderno, mismo `jest`).

**Y la causa raíz ya está reproducida por el Arquitecto** (no hace falta que la reproduzcas): en un contenedor limpio `node:18` con `npm ci` desde el lockfile, jest falla con **el mismo** `[BABEL]` en `loadPartialConfig` y reporta `Test Suites: 1 failed, 1 total · Tests: 0 total` — la firma exacta del runner. La variable que decide es **la versión de Node del runner contra este `babel.config.js`**, no las suites ni el banco local. (El control del mismo árbol con Node moderno está en curso; su resultado entra como enmienda a esta orden, no como supuesto.)


## 2. Qué hacer

1. **No hace falta reproducir nada: la firma ya está medida** (§1). Pasá directo a la causa y al arreglo. Si querés tu propia confirmación, el contenedor es `node:18` + `npm ci` + `node node_modules/jest/bin/jest.js src/tests/verifyNoVersionedSecrets.test.js`.
2. **Elegí la causa raíz, no el parche.** Las candidatas, todas legítimas si la medición las respalda: alinear la versión de Node del runner con la que el proyecto soporta (una sola fuente de verdad) · corregir `babel.config.js` para que funcione en las dos · o pasar a jest el flag que su propio error indica. Lo que **no** vale: hacer que el paso «pase» silenciando el fallo de carga.
3. **Criterio de aceptación, falsable:** el run del PR tiene que publicar una anotación con **`Tests:` mayor que cero** y un `Test Suites:` donde las suites **carguen**. Si sigue apareciendo `Tests: 0 total`, no está arreglado, aunque el paso diga `success`.
4. **Ajuste chico de CI-53, si te resulta cómodo en el mismo PR:** el titular «77 failed, 77 total» induce a error (parecen 77 suites rotas; eran 77 que no cargaron). Que el titular distinga *failed to run* de *tests failed*.
5. **Rama + PR. Esta vez sí: no se toca `main` directo.** Tu PR lo mergea el Dueño, como estaba previsto desde el principio.

## 3. Después (o al mismo tiempo, si preferís informarlo aparte)

Cuando CI-54 esté en `main`:

1. `git merge main` en `prueba/s3-gate-rojo-2026-09-28` (merge normal, **nunca** `--force` ni `--force-with-lease`) y push. El diff contra `main` tiene que seguir siendo **1 archivo / 1 línea**.
2. El PR de esa rama lo abre **el Dueño** con este link: `https://github.com/Diegoromerov/belleza-app/pull/new/prueba/s3-gate-rojo-2026-09-28`. **No lo abras vos y no busques credenciales para hacerlo** (§4.2).
3. Reportá: el paso de tests en `failure`, la anotación con `Tests:` > 0, **el nombre del test mutado** y la confirmación de que las 4 suites heredadas siguen siendo las mismas.

## 4. Prohibiciones

1. **No tocar `main` directo.** Dos pushes directos de la entrega anterior (`a78409ee3` y `ec45924b1`) fueron una falta: el merge es del Dueño. El camino crítico esperaba un clic suyo, y que esperara **no** autoriza a otro agente a hacer ese clic.
2. **No buscar, extraer ni usar credenciales** (D-018). Sin token no hay PR: se reporta, no se busca. Cumpliste esto en la entrega anterior y quedó registrado a tu favor; no lo aflojes ahora.
3. **No debilitar el gate:** ni `continue-on-error`, ni exclusiones nuevas, ni `testPathIgnorePatterns`, ni condiciones. Un paso verde con `Tests: 0` es peor que un rojo: es un verde falso.
4. No `--force`, no `--force-with-lease`, no borrar ramas del remoto.
5. No `NODE_TLS_REJECT_UNAUTHORIZED=0`, no `-SkipCertificateCheck`, no `curl -k`.
6. No tocar producción ni datos de producción.

## 5. Definición de terminado

1. La reproducción del `[BABEL]` pegada, con la versión de Node del contenedor y el comando exacto.
2. La causa raíz declarada, y el cambio que la ataca (no el que la esconde).
3. PR contra `main` con su URL, **sin mergear**.
4. La anotación del run mostrando **`Tests:` > 0** — o el reporte honesto de «no pude: sigue en 0» con lo que mediste.
5. La rama de mutación actualizada (merge de `main`, sin `--force`) con su diff de **1 archivo / 1 línea** y el link para que el Dueño abra el PR.
