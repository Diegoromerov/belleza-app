# Auditoría — CI-54 (motor del runner, ronda 1)

**Auditor:** Hermes (Arquitecto) · **Fecha:** 2026-09-28
**Procedencia:** rama `fix/ci54-node-version-runner` @ **`ab3c72752`** (2 commits, base `main` `ec45924b1`)

## Veredicto: **ACEPTADA la dirección, RECHAZADA la evidencia del contraste**

El objetivo **`22.x` es correcto** y el diff es mínimo y limpio. Pero la medición que lo «demuestra» no es una comparación controlada, y así no se puede citar como prueba.

## 1. Lo que sí verifiqué (independiente, API pública sin token)

- Rama `ab3c72752`, `ahead=2 / behind=0` contra `main`, **1 archivo**: `.github/workflows/ci.yml` `+9/-4`.
- Neto del diff: `name: Setup Node.js 18` → `Setup Node.js 22` y `node-version: '18.x'` → `'22.x'`. Nada más toca el gate: su condición y sus exclusiones quedan como estaban.
- El paso de anotaciones (CI-53) ahora rotula según el caso (`suites fallaron al cargar` vs `resumen de ejecucion`). Es cosmético y no altera el veredicto del gate: **aceptable**.
- **No hay PR**: la rama quedó publicada y el link lo dejó el Ejecutor. D-018 respetada: cero búsqueda de tokens.

## 2. Por qué la evidencia del contraste no sirve

El bloque de `node:20` que la entrega presenta como «misma falla que Node 18» **no es la misma falla**:

```
● Test suite failed to run
  Cannot find module '@babel/plugin-transform-runtime'
  Require stack:
  - /root/.npm/_npx/b8d86e6551a4f492/node_modules/@babel/core/lib/config/files/plugins.js
```

- El require stack apunta a **`/root/.npm/_npx/…`**: `npx` se instaló **su propio** `@babel/core` en el contenedor y busca el plugin **fuera del árbol del repo**. El error es de **resolución del arnés**, no del runner.
- El error real del CI es otro: `[BABEL]: You appear to be using a native ECMAScript module plugin…` (medido por mí en las anotaciones del run de `main`). **No se reprodujo.**
- Y las dos corridas **no usan la misma invocación**: la traza muestra `npx jest`, `npm test`, `npm ci --legacy-peer-deps && npx jest` y `node node_modules/jest/bin/jest.js`. Si el `PASS` de `node:22` vino de la corrida con `npm ci --legacy-peer-deps`, entonces cambió **dos variables** (motor y árbol de dependencias) ⇒ el contraste no aísla nada.

**Regla que sale de esto:** `npx` dentro de un contenedor con bind mount **no es un arnés** — instala su propio Babel y resuelve fuera del árbol. La comparación válida usa el binario del propio repo (`node node_modules/jest/bin/jest.js`), y **la misma invocación** en las dos imágenes; si cambia la invocación, no es una comparación. (Mis propios intentos en contenedor cayeron en la misma trampa: `ERR_MODULE_NOT_FOUND` por el mount. La trampa figura registrada para los dos.)

## 3. Por qué igual se acepta

1. El `engines` declarado por los paquetes respalda el objetivo: `@babel/preset-env@8.0.2` y `@babel/plugin-transform-runtime@8.0.1` exigen `^22.18.0 || >=24.11.0` con `type: module`. `22.x` los satisface; `20.x` no.
2. El `PASS` en `node:22` con `Tests: 4 passed, 4 total` es plausible y consistente con el estado local (esa misma suite pasa en mi entorno).
3. **El juez final no es el contenedor: es el CI.** El criterio de aceptación ya está escrito y es medible con lo que construimos: el resumen publicado por el paso de anotaciones debe **dejar de decir `Tests: 0 total`**. Si el merge ocurre y sigue en `0 total`, la dirección estaba mal y se revierte sin haber declarado nada.

## 4. Estado y próximos pasos

| Elemento | Estado |
|---|---|
| `fix/ci54-node-version-runner` @ `ab3c72752` | Lista. **El Dueño abre el PR y lo mergea** |
| `prueba/s3-gate-rojo-2026-09-28` @ `b7a96a4a3` | Lista (1 archivo / 1 línea, `behind=0`). **El Dueño abre el PR** — `ci.yml` no corre en pushes a ramas |
| PR #17 (mutación vieja, run `skipped`) | **Cerrar** |
| S3 / A-07 | 0,90 / 0,95 — medibles, no cerrables hasta que el gate corra tests de verdad |
