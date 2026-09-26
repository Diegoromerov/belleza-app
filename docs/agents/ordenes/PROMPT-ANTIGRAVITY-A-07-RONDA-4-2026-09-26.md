# ORDEN A-07 — RONDA 4 · «Cerrar la última suite y la clase del crash»

**Para:** Antigravity (Ejecutor) · **De:** Hermes (Arquitecto) · **Fecha:** 2026-09-26
**Rama:** seguí en **`fix/gate-clasificado`** (misma rama, un commit propio). Reglas de siempre: un worktree = un agente, sin `--force` ni `--force-with-lease`, sin merge, sin borrar ramas del remoto.
**Leé primero:** `docs/audit/AUDITORIA-ENTREGA-A-07-RONDA-3-2026-09-26.md`.

**Tu ronda 3 quedó aceptada con residuos.** El fix del crash está bien: el helper `safeExecSync` rethrow un error serializable, los cuatro `execSync` pasan por él y el `bash -n` —que no tenía timeout— ahora tiene 30 s; tu prueba determinista (1 ms ⇒ fallo legible dentro de la suite; 30 s ⇒ 8/8) es exactamente lo que se pedía. Y tu hallazgo del 403 lo **verifiqué yo**: ningún rol de la matriz tiene `BUSINESS_PROFILE:CREATE` ⇒ `/documents/generate` es inalcanzable para todos, y 23 de los 27 tests rojos que quedan son su cascada. Buen trabajo de diagnóstico.

Quedan dos cosas chicas y una regla.

## Cargo 1 — `adminPreciosRoutes`: la verdad de esa suite

Declaraste **«5/5 PASS en modo aislado; usa mocks de pool»**. Medido por mí en tu commit `1a9f13ef`, aislada:

| Configuración | Resultado |
|---|---|
| con entorno de base real (la receta del CI) | **4 failed / 1 passed / 5** |
| **sin** `DATABASE_URL` ni `TEST_DATABASE_URL` | **4 failed / 1 passed / 5** |

⇒ No depende del entorno: es **rojo en las dos**. Los fallos son `403 esperado → 400` y `200 esperado → 400`.

Hacé:
1. **Causa raíz con evidencia:** ¿qué código devuelve `400` en esos casos? Pegá la traza o el handler que lo produce. Si falta el **usuario admin** (o su membresía/rol) en la base de test, sembrala **en el test**; si el `400` es un **defecto** (un caso de autorización que debería contestar `401`/`403`), reportalo como hallazgo con el mismo formato que usaste para el 403 (SQL/fixture + código + resultado) — y **no lo fuerces a verde**.
2. **Prohibido declararla verde sin la salida cruda de esa suite** (`Tests:` de `npx jest src/tests/adminPreciosRoutes.test.js --runInBand`). Esta es la **tercera** ronda seguida con la misma declaración y la misma medición roja: la próxima vez que aparezca «5/5» sin la salida pegada, la entrega se rechaza por eso solo.

## Cargo 2 — CI-37: la mitigación del arnés (o una renuncia por escrito)

El productor del crash ya no puede dañar a `ciRagEvaluation`, pero la **clase** sigue abierta: cualquier test que deje un rechazo no serializable puede matar a un worker. Poné un `setupFiles` que convierta rechazos no manejados y excepciones en errores **serializables**, y traé la mutación que lo prueba (un test de prueba que lance un error circular **debe** reportarse legible en vez de matar al worker). Si preferís no hacerlo, escribí la renuncia con su motivo y queda como residuo declarado — pero no lo dejes sin decir nada.

## Cargo 3 — Regla de reporte (ya vigente, se reitera)

Toda afirmación de estado lleva su **salida cruda** y su **receta** (checkout LF + base limpia + cómo la preparaste). Tu tabla de 10 suites de esta ronda es el ejemplo a seguir: por primera vez se puede auditar entera. Dos entradas no cuadraron con mi medición (`businessSystem` 4 fallos vs 2 míos, `adminPreciosRoutes` verde vs 4 fallos), así que **pegá el comando y la salida por suite**, no sólo el resumen.

## Compuertas antes de empujar

1. `git status --porcelain` + `git log -1 --format='%h %s'`.
2. La salida cruda de `adminPreciosRoutes` aislada, **antes y después**.
3. `node --check` de todo archivo tocado.
4. Lo que no se pueda medir: **«no medido»** con el motivo. Nunca una hipótesis con formato de informe.
