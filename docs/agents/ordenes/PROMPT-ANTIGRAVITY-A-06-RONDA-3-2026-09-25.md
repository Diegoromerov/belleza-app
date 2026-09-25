# ORDEN A-06 · RONDA 3 (corta) — cerrar lo que quedó abierto en la compuerta

**Auditoría que la origina:** `docs/audit/AUDITORIA-ENTREGA-A-06-RONDA-2-2026-09-24.md`
**Ramas:** `fix/compuerta-secretos-reproducible` (2a) y `fix/jwt-sin-respaldo` (2b, encadenada sobre 2a).
**Veredicto de la ronda 2:** **ACEPTADA EN SUSTANCIA** — el objetivo está cumplido y lo probé con mi propia mutación: un valor `'glowapp_jwt_production_secure_secret_key_at_least_32_chars'` plantado y `git add`eado ahora **sale detectado** (antes `exit 0`, ciega). **No rehagas la compuerta.** Quedan cuatro cosas, y las cuatro son de cierre.

## Los 4 pendientes

1. **C5, ahora sí con el rojo pegado.** Tu «prueba de mutación» **pasa**: asevera una desigualdad con un flag (`normalize=false`). Lo pedido es el test **rojo**: quita la normalización **del camino real** (`replace(/\r$/, '')` en `validarLinea`), corre el test, **pega la salida del fallo**, y vuelve a ponerla. Un test que asevera que el código normaliza no es lo mismo que un test que cae cuando el código deja de normalizar.

2. **C7 acotado — y son DOS sitios, no uno.** El `.md` quedó exento de forma global en:
   - `verifyNoVersionedSecrets.js:124` → `EXENTAS` con `/\.md$/i`;
   - `verifyNoVersionedSecrets.js:110` → un salto duro dentro de otra función (`if (archivo.endsWith('.md')) return false;`).

   Lo pedido era **`docs/**/*.md`**. Al acotarlo, **pega el listado de los hallazgos que aparezcan en los `.md` de la raíz** (hoy son invisibles). Con esa lista el Dueño decide, y se decide **por tipo y con motivo escrito**, nunca por prefijos ni por iniciales.

3. **C8: fuera el `DEUDA.md` de la raíz** en las dos ramas. La KB tiene una sola ruta y un solo dueño (`docs/knowledge/`, rama `docs/sistema-agentes`); la fila TEC-53 ya está actualizada por mí. Si quieres dejar constancia de algo, va en el cuerpo del PR.

4. **Cerrar CI-08 de fondo: que no haya literal.** El literal de test que introdujiste aparece **tres veces** (medido): `backend/src/config/jwt.js:7`, `backend/src/services/biometricCryptoService.js:9` y `backend/src/services/biometricCryptoService.js:27` (esta última, semilla del `createHash`). Es **invisible** para la compuerta: un valor que empieza por `test` no se ve (medido). No lo arregles eximiéndolo: **quítalo del código** — genera la clave de test en tiempo de ejecución (`crypto.randomBytes(32)`) o léela del entorno de test — y entonces **saca `test` de las exenciones**, que hoy está en **dos** reglas: `:97` y `:161` (`/^(…|PLACEHOLDER|xxx|example|admin123|test|ci_|dummy|…)/i`). Así la clase de CI-08 queda cerrada, no estrechada.

## Criterios de cierre

| # | Criterio | Cómo se prueba |
|---|---|---|
| C1 | La normalización está **probada por caída**, no por aserción | salida del test en rojo al quitarla, pegada, y el test en verde al restaurarla |
| C2 | Los **dos** saltos de `.md` acotados a `docs/**/*.md` | `grep -nE "\.md" backend/scripts/verifyNoVersionedSecrets.js` pegado, con `:110` y `:124` ya corregidos |
| C3 | Listado de hallazgos que aparecen en las `.md` de la raíz | salida del escáner, cruda |
| C4 | Cero literales de clave en código, incluido el de test | `git grep -n "test_secret_glowapp_jwt_token_key" -- backend` ⇒ **vacío** *y* la clave de test generada en tiempo de ejecución |
| C5 | `test` fuera de las **dos** reglas de exención | `grep -nE "admin123\|test\|ci_" backend/scripts/verifyNoVersionedSecrets.js` ⇒ sin `test` en `:97` ni en `:161` |
| C6 | `DEUDA.md` de la raíz ausente en las dos ramas | `git ls-tree` de la raíz, pegado |

## Prohibiciones

Eximir el literal de test «porque es de test» · volver a poner prefijos de valor en la allowlist · reactivar `^\.github/workflows/` o `^docs/` completos · fusionar 2b antes de la confirmación del Dueño en Railway · tocar `index.js`.

## Nota de contexto (por qué esto no se cierra antes)

El paso 7 del CI **no puede** estar verde mientras existan los dos literales reales que la compuerta ahora ve (`jwt.js:2`, `biometricCryptoService.js:18`). Eso es mejor que antes, no peor: el rojo ahora tiene motivo. Su desaparición (2b) es lo que abre los pasos 8-11, y 2b espera la confirmación del Dueño.
