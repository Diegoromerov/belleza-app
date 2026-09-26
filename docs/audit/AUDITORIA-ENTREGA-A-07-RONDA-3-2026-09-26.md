# Auditoría independiente — Entrega A-07 · Ronda 3

**Fecha:** 2026-09-26 · **Auditor:** Hermes (Arquitecto/Verificador) · **Rama:** `fix/gate-clasificado`
**Procedencia verificada por mí:** remoto = local = `1a9f13efb45fc3996ac273cd39c665e94e913824`; base `b545ef22` ✓; **1 archivo, +24/−6** (`ciRagEvaluation.test.js`).
**Veredicto:** **ACEPTADA CON RESIDUOS** — el fix del crash está bien hecho, con prueba determinista y salida cruda; el hallazgo de producción quedó **verificado por mí**. Queda una **afirmación falsa repetida por tercera ronda** y dos residuos.

## 1. Cargo 1 — el crash del worker: ACEPTADO ✓

Código (leído por mí en el diff): un helper `safeExecSync(cmd, options)` con `timeout: 30000` por defecto que, ante el fallo, **rethrow un `Error` nuevo y serializable** (`code`, `status`, `stdout`, `stderr` como strings) en vez de dejar propagar el error crudo de `execSync`. **Los cuatro `execSync` pasan por él**, incluido el `bash -n` que **no tenía ningún timeout** y ahora tiene 30 s.

Prueba determinista suya (salida cruda, la que faltaba la ronda pasada): con el timeout mutado a 1 ms ⇒
`Tests: 1 failed, 7 passed, 8 total` y el fallo **legible dentro de la suite** (`execSync failed […]: … ETIMEDOUT`) ⇒ **ya no mata al worker**. Con 30 s ⇒ 8/8. Verificado por mí en la receta aislada: **`ciRagEvaluation` PASA**.

Residuo: la mitigación del arnés (**CI-37**) no se hizo. La causa ya no puede dañar a *esta* suite, pero la clase sigue abierta para cualquier otro test que deje un rechazo no serializable.

## 2. Cargo 2 — el 403: HECHO Y **VERIFICADO POR MÍ** ✓ (hallazgo de producción)

Su reporte es correcto y lo confirmé cargando la matriz real:

```js
// src/routes/businessRoutes.js:70-76
router.post('/documents/generate',
  authMiddleware,
  membershipMiddleware,
  requirePermission(RESOURCES.BUSINESS_PROFILE, ACTIONS.CREATE),   // ⇐ nadie lo tiene
  businessController.generateDocument);
```

Medido: **ningún rol de `PERMISSIONS_MATRIX` tiene `BUSINESS_PROFILE:CREATE`** ⇒ **el endpoint devuelve 403 para todo el mundo**: es inalcanzable, para cualquier usuario y cualquier rol. Es un **defecto de producción**, no de los tests (misma familia que «la API de precios es inusable con 0 ADMIN»). De ahí cuelga **casi todo el rojo restante**: 23 de los 27 tests rojos de la receta aislada son la cascada de ese 403.

## 3. Cargo 3 — `adminPreciosRoutes`: **afirmación falsa, tercera ronda consecutiva** ✗

Él declara **«5/5 PASS en modo aislado; usa mocks de pool»**. Medido por mí, aislada, en `1a9f13ef`:

| Configuración | Resultado |
|---|---|
| con entorno de base real (receta del CI) | **4 failed / 1 passed / 5** |
| **sin** entorno de base (sin `DATABASE_URL`/`TEST_DATABASE_URL`) | **4 failed / 1 passed / 5** |

⇒ No es dependiente del entorno: es **rojo en las dos**. Es la tercera ronda seguida con la misma suite declarada verde (r1 «5/5 PASS, medido y verificado»; r2 «5/5 PASS»; r3 «5/5 PASS») y medida roja (4 fallos en las tres). Los fallos son `403 esperado → 400` y `200 esperado → 400`: un **400 en un caso de autorización** merece diagnóstico propio (¿token/usuario admin inexistente en la base de test, o un 400 que debería ser 401/403?).

## 4. Cargo 4 — el cuadro de 10 suites: correcto en lo esencial, con imprecisiones

Mi corrida aislada (LF + base real) sobre `1a9f13ef`: **5 suites rojas / 27 tests rojos / 100 tests**.

| Suite | Él declara (r3) | Yo mido |
|---|---|---|
| `ciRagEvaluation` | 8/8 PASS | **8/8 PASS** ✓ |
| `sequelizeTenantContext` · `rateLimiter` · `sprint2_agents` · `businessRAG` | verdes | **verdes** ✓ |
| `businessHardening` | 0/12 (12 fallos) | **12 fallos** ✓ |
| `businessAdminDocs` | 0/8 (8 fallos) | **8 fallos** ✓ |
| `business.integration` | 10/11 (1 fallo) | **1 fallo** ✓ |
| `businessSystem` | 12/16 (4 fallos) | **2 fallos** ✗ |
| `adminPreciosRoutes` | 5/5 PASS | **4 fallos** ✗ |

⇒ Su tabla es, por primera vez, **rastreable y casi exacta** (dos entradas no cuadran). Ese es el estándar que se le pide: la tabla del cuadro se sostiene; la fila de `adminPreciosRoutes` no.

## 5. Lo que queda (ronda 4, corta)

1. **`adminPreciosRoutes`:** causa raíz de los 400 con evidencia (qué middleware devuelve 400 y por qué). Si falta la fixture del usuario admin, se fabrica **en el test**; si el 400 es un defecto (un caso de autorización que no devuelve 401/403), se reporta como hallazgo. Y **dejar de declararla verde sin la salida cruda de esa suite**.
2. **CI-37:** la mitigación del arnés, o una renuncia justificada por escrito.
3. **Nada más:** el resto del rojo ya no es trabajo de tests — es **CI-35 (decisión del Dueño)** más **CI-14**.

## 6. Reglas nuevas para el registro

- **Repetir una afirmación no la convierte en medición.** `adminPreciosRoutes` fue declarada verde tres rondas seguidas y medida roja en las tres: la tercera declaración ya no es un error, es un patrón.
- **Un `400` en un caso de autorización no es «un test sin fixture»**: o falta el sujeto del permiso, o la ruta contesta el código equivocado. Hay que decidir cuál antes de tocar nada.
