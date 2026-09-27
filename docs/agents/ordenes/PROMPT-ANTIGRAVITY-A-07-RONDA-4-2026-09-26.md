# ORDEN A-07 — RONDA 4 (REVISADA) · «La suite hermética y la clase del crash»

**Para:** Antigravity (Ejecutor) · **De:** Hermes (Arquitecto) · **Fecha:** 2026-09-26
**Rama:** seguí en **`fix/gate-clasificado`** (misma rama, un commit propio). Reglas de siempre: un worktree = un agente, sin `--force` ni `--force-with-lease`, sin merge, sin borrar ramas del remoto.
**Leé primero:** `docs/audit/AUDITORIA-ENTREGA-A-07-RONDA-3-2026-09-26.md` **y** `docs/audit/RETRACTACION-GATE-ENTORNO-2026-09-26.md`.

**Tu ronda 3 queda ACEPTADA CON RESIDUOS**, y esta revisión empieza por una corrección **mía**, no tuya:

> **Retracto el Cargo 3 de mi auditoría anterior.** Medí `adminPreciosRoutes` **sin `JWT_SECRET`** en el entorno. La suite firma su token con un fallback propio (`adminPreciosRoutes.test.js:19`: `'beauty_app_super_secret_key_2026_change_in_production'`) mientras la app verifica con `DEFAULT_PROD_SECRET` (`src/config/jwt.js:2,6,8`) ⇒ **sólo pasa si `JWT_SECRET` está en el entorno**, y el CI lo define (`ci.yml:38`). Re-medido con esa variable: **5/5 PASS** ⇒ **tu 5/5 era correcto y el rojo era mi entorno.** El «tercera vez» también era mío: en las rondas 1 y 2 medí igual de mal.

Dicho eso, queda un defecto **real** en esa suite, y es lo que hay que arreglar.

## Cargo 1 — `adminPreciosRoutes` no es hermética

Su resultado **depende de una variable de entorno**: con `JWT_SECRET` ⇒ **5/5**; sin ella ⇒ **4 fallos** (`403 esperado → 400`, `200 esperado → 400`). Una suite cuyo veredicto cambia según el entorno del que la corre **no mide lo que dice medir**: es la misma clase de defecto que la ceguera al CRLF del escáner (CI-31), que ya nos costó una confusión.

**Hacé que la suite fije su propio secreto antes de cargar la app** — `process.env.JWT_SECRET = 'test_secret_para_esta_suite'` en la cabecera del archivo (o en un `beforeAll`) **antes** del `require` de la ruta; o firmá con el mismo `DEFAULT_PROD_SECRET` de `src/config/jwt.js`. Que no quede ningún camino por el que el veredicto dependa de lo que haya en el entorno.

**Prueba exigida (determinista, dos corridas):**
```
npx jest src/tests/adminPreciosRoutes.test.js --runInBand                    # con JWT_SECRET exportado
env -u JWT_SECRET npx jest src/tests/adminPreciosRoutes.test.js --runInBand   # sin JWT_SECRET
```
Las dos tienen que dar **el mismo resultado**. Pegá las dos salidas crudas (`Tests:`).

## Cargo 2 — CI-37: la mitigación del arnés (o una renuncia por escrito)

El productor del crash ya no puede dañar a `ciRagEvaluation`, pero la **clase** sigue abierta: cualquier test que deje un rechazo no serializable puede matar a un worker. Poné un `setupFiles` que convierta rechazos no manejados y excepciones en errores **serializables**, y traé la mutación que lo prueba (un test de prueba que lance un error circular **debe** reportarse legible en vez de matar al worker). Si preferís no hacerlo, escribí la renuncia con su motivo y queda como residuo declarado — pero no lo dejes sin decir nada.

## Cargo 3 — Lo que NO es tuyo (y conviene declararlo en la entrega)

El rojo que queda no es de los tests:
- **4 suites** (`business.integration`, `businessAdminDocs`, `businessHardening`, `businessSystem`) = **cascada de CI-40**: `/documents/generate` exige `BUSINESS_PROFILE:CREATE` y ningún rol lo tiene ⇒ **decisión del Dueño**.
- **`audit360-remediation`** = las 8 credenciales versionadas ⇒ **CI-14, decisión del Dueño**.
- **`ownerMultiSalonDashboard`** = apareció roja en mi corrida con el entorno del CI; si la mirás, mejor (no es obligatorio en esta ronda).

## Compuertas antes de empujar

1. `git status --porcelain` + `git log -1 --format='%h %s'`.
2. La salida cruda de `adminPreciosRoutes` aislada, **antes y después**.
3. `node --check` de todo archivo tocado.
4. Lo que no se pueda medir: **«no medido»** con el motivo. Nunca una hipótesis con formato de informe.
