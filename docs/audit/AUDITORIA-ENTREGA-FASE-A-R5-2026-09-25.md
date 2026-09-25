# Auditoría — Fase A · ronda 5 (S4 residuos) · `b545ef22`

**Fecha:** 2026-09-25 · **Auditor:** Hermes
**Procedencia:** `origin/fase-a/verdad-operativa` @ **`b545ef22`** (sobre `3cef7f88`), 4 archivos, +453/−284. `git diff 3cef7f88 b545ef22 -- backend/index.js` = **vacío** (la ruta plantada para C7 fue revertida) y `git grep '__smoke_ronda5_fake\|__hermes'` en el árbol = **0**. Árbol de trabajo limpio en el worktree de medición.

## VEREDICTO: **ACEPTADA** — con dos residuos nuevos (CI-20, CI-21)

Medido por mí, no leído de su informe. Detalle de lo que **no** re-medí: declarado al final.

## Criterios

| # | Criterio | Resultado (medición mía) |
|---|---|---|
| C1 | Sin entry vivo ⇒ `exit 1` nombrando el motivo; nunca verde desde el inventario | ✅ **mutación mía A**: neutralicé el `require('../index')` (que era `require('../index')`, reemplazado por un módulo inexistente) ⇒ `❌ ERROR CRÍTICO EN GUARDIA: no se pudo cargar el entry vivo de la app; el inventario NO sustituye la medición` + `📄 (Diagnóstico: inventario respaldado contiene 308 rutas, pero se aborta con exit 1)` + **exit 1** |
| C2 | `decidirRutas` pura y exportada, tres casos | ✅ `smokeSurfaces.js:112-140` (`express_stack` ⇒ 0 · `inventario` ⇒ 1 + `error` · `ninguna` ⇒ 1), exportada junto a `extractRoutes`; su suite **corrida por mí: 4/4** |
| C3 | Mutación pegada ⇒ rojo | ✅ **mutación mía B** (rama del inventario a `exitCode: 0`, anclada en el código) ⇒ `Tests: 2 failed, 2 passed, 4 total` (`Expected: 1 · Received: 0`) y archivo restaurado sin diff |
| C4 | Comando documentado con el error esperado | ✅ `scripts/COMO_EJECUTAR.md` (+21) y cabecera del guardián, con `DB_HOST=127.0.0.1`, el mensaje de SSL sin él y la nota de que `testConnection()` devuelve `true` también en modo memoria. **La contraseña va como `***`** (no entró al repo) |
| C5 | Corrida sana pegada | ✅ **reproducida por mí** desde el checkout: `🔍 Descubiertas dinámicamente 308 rutas`, `122 superficies probadas`, `Faked Success Totales: 0`, `✅ SMOKE TEST EXITOSO`, `EXIT=0` ⇒ **CI-17 CERRADA** |
| C6 | Rechazo sin dueño atribuido | ✅ atribuido a `backend/src/config/tenantRouting.js:170` (`runAsSystem` → `deps.pool.connect()`), declarado **código de la app** y no tocado ⇒ registrado como **CI-21** |
| C7 | Una ruta plantada sigue marcándose | ⚠️ **NO re-medido por mí** (declarado): `extractRoutes` y la regla de clase están **sin cambios** frente a `3cef7f88` (el diff solo los envuelve en `decidirRutas` y los exporta) y esa medición la hice yo en la ronda 4 sobre el mismo código. Su corrida reporta 309 rutas (308 + la suya) con `FAKED SUCCESS` y `exit 1` |
| — | Su edición de `COMO_EJECUTAR.md` no altera la compuerta | ✅ escáner (lógica correcta) sobre `b545ef22`: **8 hallazgos**, `scripts/COMO_EJECUTAR.md:35` **en la misma línea** ⇒ las citas de CI-14 y del Cargo 4 de A-06 r5 siguen válidas |

## Residuo nuevo 1 · **CI-20** — el guardián llama «degradado» a un servidor sano (y su par de informes es irrecuperable)

Mi corrida **sana** (base arriba, `exit 0`, 0 fakes) escribió `docs/audit/smoke-2026-09-25-**degraded**.json` con `"server_degraded": true`: `isServerDegraded` cuenta **Redis no configurado** como degradación (el log de la corrida lo dice: `[REDIS STATUS] DISABLED / NOT_CONFIGURED`). Consecuencias medidas:

- El informe de una corrida sana se llama «degraded» ⇒ **el nombre miente**, y el `-ok.json` solo se puede producir con Redis configurado (inalcanzable en local).
- El `docs/audit/smoke-2026-09-25-ok.json` **commiteado está rancio**: es de la ronda 4, **no tiene `routes_source`** y ya no es reproducible por el código actual (el formato cambió en esta entrega). Un artefacto que el código de hoy no puede regenerar no es evidencia (familia TEC-64).
- El par RED→GREEN que pide HON-02 no se puede producir en este entorno.

## Residuo nuevo 2 · **CI-21** — rechazo sin dueño desde código de la app

`tenantRouting.js:170` (`runAsSystem` → `deps.pool.connect()`) genera un `Unhandled Rejection: The server does not support SSL connections` cuando la base no responde y el proceso no hereda `DB_HOST`. Atribuido por el ejecutor, **no tocado** (fuera del alcance de la Fase A) ⇒ queda como deuda con su `archivo:línea`.

## Mediciones mías fallidas (registradas, no borradas)

1. **Mi primera corrida se colgó 420 s** y luego falló con `Cannot find module 'pg'` (omitió `NODE_PATH` en mi invocación) — lo leí un instante como «el fail-fast funcionó»: **no lo era**, era mi entorno. Rehecho con `NODE_PATH` y perro guardián propio.
2. **Mi mutación B cayó en el JSDoc**: anclé en `fuente: 'inventario'`, que aparece **primero en el comentario** de `decidirRutas` (`:105`) ⇒ muté un comentario y su suite salió **verde** (falso verde de mi propia sonda). Reanclada en `const backupRoutes` ⇒ rojo limpio. Regla nueva en `TRAMPAS.md §6`.
3. Jest en este entorno **imprime el resumen y luego se queda** (terminó por `SIGTERM` de mi `timeout`, código 143): los resultados son válidos, pero conviene envolverlo.

## Señal de proceso

Su informe pega la contraseña local de la base (`admin:admin123`) en el texto del walkthrough. No entró al repo (en `COMO_EJECUTAR.md` va como `***`) y es el valor por defecto del contenedor local, ya presente en la allowlist del escáner ⇒ **sin daño**, pero no debe repetirse: los informes son documentos que se comparten.

---

## §Corrección (2026-09-25, después de publicar esta auditoría) — **retracto mi cierre de CI-17 y mi lectura de C5**

**Qué dije y qué mide el entorno (R-06: se registra, no se borra):**

1. Publiqué «CI-17 **CERRADA** — el caso sano es reproducible con `DB_HOST=127.0.0.1`» y pegué una corrida con `EXIT=0`, 308 rutas y 0 fakes. **Eso era una corrida DEGRADADA, no sana**: la línea de mi propia salida dice `📊 Estado del servidor detectado (probes inicio): IsDegraded=true, HealthStatus=503`, y el informe que escribió fue `smoke-2026-09-25-degraded.json` (`server_degraded: true`). Lo di por sano porque el guardián salió 0 y no hubo fakes: **confundí «no finge éxito» con «está sano»**.
2. La causa real **no** es Redis (mi primera atribución de CI-20, falsa) ni la contraseña: es que el guardián **nunca ejecuta el arranque de la app**. `smokeSurfaces.js:21` fuerza `NODE_ENV=test`; la app solo arranca bajo `NODE_ENV !== 'test'` (`index.js:1811`) y `await testConnection()` / `await initDatabase()` viven **dentro** de ese callback (`:1826-1828`); el guardián llama `app.listen(PORT)` por su cuenta (`:203`). Sin ese callback, `getDbStatus()` devuelve `pgAvailable: false` **para siempre** (sondeado 20 s seguidos, sin transición) ⇒ `/api/health` 503 y toda `/api` bloqueada.
3. **Prueba en contrario, medida hoy**: con la credencial de desarrollo y la base arriba, la app arrancada **como en producción** (`NODE_ENV=development PORT=3958 node index.js`) responde `/api/health` **200 OK** con `database: {pgAvailable: true, servingFabricatedData: false}`, `/api/test-db` **200** `PostgreSQL conectado` (PostGIS 3.6) y `/api/products` **200 con `count: 296`** — el catálogo real. La app **sí** dice la verdad cuando la arranca su propio camino.
4. **C5 de esta ronda, releído**: su corrida tampoco era sana (el artefacto que commiteó dice `server_degraded: true`, 123 superficies, `routes_source: express_stack`). No se lo imputo: **mi orden pedía una corrida sana sin haber comprobado que el arnés pudiera producirla** — el C5 era imposible tal como lo escribí. Queda como lección en `TRAMPAS.md §7`: *no exigir evidencia que el arnés no puede producir*.
5. **Alcance sobre veredictos anteriores (importante)**: los 503 medidos en las rondas 3 y 4 (`DATA_LAYER_DEGRADED`, `X-GlowApp-Degraded: memory-fallback`) probaban que el candado bloquea cuando `pgAvailable === false`, **no** que la base estuviera caída. La discriminación «con la base arriba la app sirve / con la base caída bloquea» **nunca quedó demostrada en el arnés** ⇒ **CI-22**.
6. Lo que **no** cambia: el fail-fast del respaldo al inventario (`decidirRutas` + mutación A/B) sigue ✓ verificado; `index.js` sin su ruta plantada ✓; la compuerta de secretos sigue en 8 hallazgos ✓. El veredicto de la entrega se mantiene **ACEPTADA**; se corrigen **mi cierre de CI-17**, **mi atribución de CI-20** y **mi lectura de C5**.

**Consecuencia operativa:** ninguna orden nueva es «la del caso sano» hasta que el guardián arranque la app como la arranca la app ⇒ **Ronda 6 de Fase A** (`PROMPT-ANTIGRAVITY-FASE-A-RONDA-6-2026-09-25.md`).
