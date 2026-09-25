# ORDEN A-02 · RONDA 2 — el dinero no se protege leyendo el archivo

**Auditoría de la ronda 1:** `docs/audit/AUDITORIA-ENTREGA-A-02-2026-09-24.md`
**Rama:** `fix/admin-metricas-sin-datos` (un commit más encima de `6edd4aff`).
**Veredicto:** el `index.js` entregado **se conserva tal cual** (503 + `X-GlowApp-Degraded`, sin bucle de fabricación, `projectedRevenue: null`, regresión solo con ≥3 meses reales). Lo que se rehace es **la prueba**.

> **Citas re-medidas hoy (2026-09-25) sobre `fase-a/verdad-operativa @ 3cef7f88`**, no sobre `c1069e9f`: el endpoint es **`index.js:730`**, el `Math.random` del bucle está en **`:824`**, la proyección en **`:845`** y la respuesta en **`:867`**; el `Math.random` legítimo (`uniqueSuffix`) sigue en **`:119`**. Los números de la ronda 1 estaban corridos por los commits `9a86a902` y `3cef7f88`.

## Cargo 0 — rebasa antes de tocar nada

Tu rama sigue colgando de `c1069e9f` (`git merge-base origin/fase-a/verdad-operativa fix/admin-metricas-sin-datos` lo confirma). `fase-a` ya tiene **dos commits más** (el candado de degradación en `index.js:228` y el guardián reescrito), así que rebasa sobre **`origin/fase-a/verdad-operativa` (`3cef7f88`)** antes de empezar. Sigue en pie **CI-10**: una rama nacida de otra base no produce evidencia.

## Cargo 1 (el único grave) — tu test no puede fallar

Tu suite lee `index.js` como texto (`expect(indexContent).toContain(…)`) y cuenta ocurrencias de `Math.random()`. Medido sobre tu rama:

- Baseline: `2 passed, 2 total`.
- **Mutación: `let history = []` → dos meses inventados (sin `Math.random`)** ⇒ **`2 passed, 2 total`**.
- Ningún otro test del repo toca `/api/admin/metrics`.

Es decir: alguien puede volver a fabricar ingresos y la compuerta dice verde. Se arregla así:

1. **Extrae la decisión a una función pura y pruébala por comportamiento.** Algo como `buildProjections(realHistory, ahora)` (en `backend/src/config/` o `backend/src/services/`, como prefieras) que devuelva `{ history, data_status, meses_con_datos, projectedMonth, projectedRevenue, trend }` **sin tocar la base ni `res`**. La ruta de `index.js:730` pasa a llamarla. Con eso el test ejercita **comportamiento**, no texto:
   - `buildProjections([], ahora)` ⇒ `history: []`, `projectedRevenue: null`, `data_status: 'insuficiente'`, `meses_con_datos: 0`.
   - `buildProjections([1 mes], ahora)` ⇒ `projectedRevenue: null`, `data_status: 'insuficiente'`, y `history` con ese mes real.
   - `buildProjections([3+ meses reales], ahora)` ⇒ `data_status: 'completo'` y cada cifra **cuadra contra un `SUM` calculado a mano en el test** (no contra la misma fórmula).
2. **Elimina las aserciones sobre el texto del archivo.** `expect(contenido).toContain(...)` y el conteo de `Math.random()` **no cuentan como prueba** (el de `Math.random` puede quedarse como *comprobación de compuerta* en el script de guardián, nunca como test de la lógica).
3. **La mutación es obligatoria y hay que pegarla:** reintroduce la fabricación **sin** `Math.random` (p. ej. `history = [{ month: '2026-01', revenue: 912345 }]` con menos de 3 meses) y demuestra que tu test se pone **rojo**. Si no se pone rojo, la tarea no está hecha.
4. **Caso degradado (C4'): ojo, cambió de dueño.** Desde `9a86a902` el 503 degradado de `/api/admin/metrics` lo pone el **candado global** (`index.js:228`), no tu ruta: por HTTP tu chequeo interno queda **inalcanzable** y el candado ya tiene su propia prueba (`src/tests/degradedLockBehavior.test.js`). Entonces:
   - **No dupliques** el test del candado ni lo toques.
   - Lo que tú pruebas es la **honestidad del cálculo**: `buildProjections` con meses reales nunca inventa, y con <3 meses `projectedRevenue` es `null`.
   - Si tu chequeo interno queda inalcanzable, **dilo en una línea del reporte**; no lo refactorices en esta rama.

## Cargo 2 — coherencia de la respuesta (defecto de mi orden, se corrige)

Con **1 o 2 meses reales** devuelves `history: []` y `meses_con_datos: 2`: se contradice y esconde datos reales. Devuelve **los meses reales que existan** (`history: realHistory`) con `data_status: 'insuficiente'` y `projectedRevenue: null`. Ocultar datos reales no es honestidad: es otra forma de mentir.

## Cargo 3 — antes de commitear, la suite completa

Pega el resumen de `npm test` (**Test Suites: X failed, Y passed, Z total**) en el reporte. Tu ronda 1 commiteó con la suite «finishing in the background»; sin ese número, «0 regresiones» no existe.

## Cargo 4 — el PR debe apuntar a `main`

Tu enlace crea un PR **contra `fase-a`**, y `ci.yml` solo escucha PRs con base `main`/`staging`: ese PR **no dispara ningún run**. Abre el PR contra **`main`** (o entrega el commit dentro de `fase-a/verdad-operativa`, como se hizo en la ronda 4 de Fase A). Sigue en pie **CI-10**: sin run no hay evidencia.

## Criterios de cierre de la ronda 2

| # | Criterio | Cómo se prueba |
|---|---|---|
| C0' | La rama está rebasada: `git merge-base origin/fase-a/verdad-operativa HEAD` = `3cef7f88…` | salida del comando |
| C1' | `buildProjections([], ·)` ⇒ insuficiente real: `history: []`, `projectedRevenue: null`, `meses_con_datos: 0` | test de la función pura |
| C2' | 1-2 meses reales ⇒ `history` **con esos meses**, `projectedRevenue: null`, `data_status: 'insuficiente'` | test de la función pura |
| C3' | 3+ meses reales ⇒ `data_status: 'completo'` y cifras que cuadran contra un `SUM` independiente escrito en el test | test de la función pura |
| C4' | La **honestidad del cálculo** queda probada (meses reales nunca inventan; <3 meses ⇒ `null`); el 503 degradado **no** se re-prueba aquí (es del candado) | test de la función pura + una línea declarando el chequeo interno inalcanzable |
| C5' | **Mutación pegada**: fabricación sin `Math.random` ⇒ test **rojo** | salida del fallo en el reporte |
| C6' | Cero aserciones sobre el texto de `index.js` | `grep -c "toContain" backend/src/tests/adminMetricsDataStatus.test.js` = 0 |
| C7' | `npm test` completo pegado (suites failed/passed/total) | salida del comando |
| C8' | PR contra `main` (o commit en `fase-a`) con la URL | enlace del PR |

## Prohibiciones

`expect(archivo).toContain(...)` como prueba · tests que cuentan ocurrencias en el código fuente · «lo probé a mano» sin salida pegada · mover el número inventado a otro sitio (seed fijo, `0`, promedio) · devolver `history: []` cuando hay meses reales · dejar `Math.random` detrás de `NODE_ENV !== 'production'` · tocar el candado o `degradedLockBehavior.test.js` · usar `main` como base de la rama.
