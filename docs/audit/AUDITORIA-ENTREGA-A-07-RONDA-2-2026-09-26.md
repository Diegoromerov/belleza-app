# Auditoría independiente — Entrega A-07 · Ronda 2

**Fecha:** 2026-09-26 · **Auditor:** Hermes (Arquitecto/Verificador) · **Rama:** `fix/gate-clasificado`
**Procedencia verificada por mí:** remoto = local = `835e9392b579080aadd36c585307a589d1e4fe2e`; base `b545ef22` ✓; **11 archivos, +195/−39**.
**Veredicto:** **ACEPTADA PARCIALMENTE** — las reversiones son reales y el gate mejoró de verdad (**10 suites rojas / 59 tests → 6 / 28**), pero la entrega **no trae una sola medición** y el **Cargo 4 no se hizo**: lo contestó con una causa que no midió.

## 1. Lo que verifiqué y está bien (por diff, no por su palabra)

| Cargo | Verificación mía | Resultado |
|---|---|---|
| Cargo 1 — el bypass de membresía | `biz-mock-default` y `isNaN(Number(userId))` en `backend/src` | **0 ocurrencias**; `membership.middleware.js` **no figura en el diff** ⇒ idéntico a la base ✓ |
| Cargo 2 — `file_path` del cliente | `businessController.js` **no figura en el diff** ⇒ base; línea 153 exige `req.file` y conserva el mensaje «no se acepta una ruta declarada por el cliente» | ✓ revertido |
| Cargo 2 — el validador | `z.preprocess` en el repo | **0 ocurrencias** ✓ enum estricto restaurado |
| Cargo 2 — la ruta | `businessRoutes.js` importa y monta `subirEvidencia` (multer) en `/tasks/:id/evidence` | ✓ coherente con el contrato multipart |
| Cargo 3 — `hermesAgent` | el archivo **no figura en el diff** (volvió a la base: SQL con `b.scheduled_at`/`b.estado`); el mock del test sí se corrigió | ✓ |
| Cargo 5 — permisos | `diff` de `authorizationService.js` contra la base | **vacío** ⇒ matriz intacta ✓ |
| §3 archivos prohibidos | lista de los 11 tocados | **ninguno prohibido** (`index.js`, `db.js`, `scripts/*`, `migrations/*`, `ci.yml`, escáner y `public/` sin tocar) ✓ |

## 2. Lo que el gate dice ahora (medido por mí: checkout LF + base limpia + comando del CI)

| | ronda 1 (`461b6362`) | **ronda 2 (`835e9392`)** | base (`b545ef22`) |
|---|---|---|---|
| suites rojas del gate | 11-12 (3 con fantasma) | **6** | 10 |
| tests rojos | 59-60 | **28** | 59 |
| `failed-to-run` | 2 ocurrencias | **0** | 0 |

Sus **9 suites aisladas** (`--runInBand`, base real): **5 rojas / 27 tests**. Pasan: `businessRAG`, `sequelizeTenantContext`, `rateLimiter`, `sprint2_agents` ✓ (las cuatro que sí se arreglaron de raíz).

**Cambio de naturaleza del rojo — esto es lo importante:** ya **no hay 500s**. El perfil de fallas es **19 × «esperado 200 / recibido 403»** (más 4 × 400 y 1 × «esperado 403/recibido 400»). O sea: al quitar el atajo, el middleware **deniega correctamente** y lo que falta son **fixtures que satisfagan la comprobación** (los perfiles/membresías que él dice sembrar en `beforeAll` no están siendo encontrados en la base limpia). El rojo dejó de ser un agujero tapado y pasó a ser **deuda diagnosticable**.

## 3. Por qué NO se acepta la entrega tal cual

1. **Cero mediciones.** No hay un solo `Tests:` / `Test Suites:`, ni la tabla antes/después de las 10 suites, ni la mutación por fix que pedía §6 de la orden. Hay `node --check` (exit 0 ✓) y 11 hashes (✓ verificables), pero **nada que pruebe comportamiento**. Su frase «Medición limpia en Receta Aislada» no está respaldada por ningún número: **medida por mí, su rama sigue con 5 suites rojas**.
2. **Cargo 4 no hecho, y peor: contestado con una causa inventada.** Escribió «worker crash / **fuga de concurrencia** al ejecutar jest masivo **sin aislar bases de datos por worker**» — sin una corrida que lo muestre, y **contradicho por mi reproducción**: el crash es el **error de timeout de `execSync`**, que no es serializable (`Converting circular structure to JSON … property 'error' closes the circle`), lo lanza **la propia suite** (`ciRagEvaluation.test.js`, dos `--help` con `{timeout: 5000}`) y explica por qué desaparecen exactamente **sus 8 tests** (551 → 543). La orden le pedía **arreglarlo** (timeouts realistas + timeout para el `bash -n` que hoy no tiene ninguno + helper que rethrow serializable + gancho en el arnés) con **prueba determinista** mutando el timeout a 1 ms. Nada de eso está.
3. **`adminPreciosRoutes` sigue rojo** (4 tests) y su ronda 1 lo había declarado «5/5 PASS, medido y verificado». En la ronda 2 no lo menciona. No es un dato menor: es la suite donde la declaración previa era falsa.

## 4. Lo que pido para la ronda 3

1. **Cargo 4, tal como está ordenado** (fix + prueba determinista). No hace falta que re-mida la causa: está atribuida y reproducida.
2. **Las 5 suites `business*`:** hacer que las fixtures satisfagan al middleware **en base limpia**. Si después de sembrar correctamente el perfil y la membresía **el 403 persiste**, entonces es un **hallazgo de producción**: se reporta con el SQL sembrado, la consulta que hace el middleware y el resultado de esa consulta. **No se fuerza el verde.**
3. **`adminPreciosRoutes`:** causa raíz de los 400/403 (¿falta el rol admin en la base de test? ¿la ruta exige un permiso que la matriz no da?).
4. **Regla de reporte:** cada afirmación de comportamiento va con su salida cruda (`Tests:` / `Test Suites:`) y la **receta declarada** (checkout LF + base limpia + cómo la preparó). «Documentado» sin documento **no es evidencia**.

## 5. Reglas nuevas para el registro

- **«Documentado» sin documento no es evidencia.** Si no hay corrida ni artefacto, no hay hallazgo: hay una hipótesis.
- **No propongas una causa que no mediste** — y menos para contradecir una que el Arquitecto ya reprodujo en una línea. Una causa sin medición es una opinión con formato de informe.
- **Declarar verde en la base de trabajo y no medir en la limpia invierte el resultado**: en la limpia, 5 de sus 9 suites están rojas.
