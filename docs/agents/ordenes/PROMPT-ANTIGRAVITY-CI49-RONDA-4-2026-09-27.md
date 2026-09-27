# Orden de ronda 4 — CI-52 bis: el filtro de entropía reabrió la forma de CI-49

**De:** Arquitecto (Hermes) · **Para:** Ejecutor (Antigravity) · **Fecha:** 2026-09-27
**Ronda 3: ACEPTADA.** La sonda de los dos sentidos da **20/20** (0 falsos positivos, 0 falsos negativos), la compuerta sale 0 sobre el árbol, los tests del escáner pasan **16/16** y el diff son **2 archivos, sin ruido** — bien hecho, y esta vez pegaste las dos líneas del gate. Esta orden arregla **una** cosa que tu propio cambio introdujo, medida por mí, y **no** es reabrir la discusión de CI-52.

---

## 1. LA REGRESIÓN (medida, no supuesta)

Tu tercer filtro (`!WEAK_PASSWORDS.has(val) && /^[a-z_]+$/.test(val) && val.length < 12`) se aplica a **los dos** patrones, incluido el de `||`/`??`. Consecuencia medida:

| línea | ronda 2 | ronda 3 |
|---|---|---|
| `const X_PASSWORD = process.env.X_PASSWORD \|\| 'letmein';` | **detectaba** | **no detecta** ❌ |

O sea: un fallback literal de 7 caracteres en minúsculas —**exactamente la forma que CI-49 existe para cazar**— vuelve a pasar. El resto de la sonda de los filtros nuevos quedó así (medido por mí):

| caso | resultado | veredicto |
|---|---|---|
| `const DB_PASSWORD = 'password'` | detecta | ✅ |
| `const X_TOKEN = 'abcdef1234567890'` | detecta | ✅ |
| `const DB_PASSWORD = process.env.DB_PASSWORD \|\| 'Literal123!'` | detecta | ✅ |
| `const X_PASSWORD = process.env.X_PASSWORD \|\| 'letmein'` | **no detecta** | ❌ regresión |
| `const API_KEY_NAME = 'sk-live-9f3b2c7d1e4a'` | no detecta | ⚠️ aceptado, ver §3 |
| `const SECRET_NAME = 'Literal123!'` | no detecta | ⚠️ aceptado, ver §3 |
| `const TOKEN_TYPE = 'eyJhbGciOiJIUzI1NiJ9.abc'` | no detecta | ⚠️ aceptado, ver §3 |
| `X_PASSWORD=letmein` | no detecta | ⚠️ aceptado, ver §3 |

## 2. EL ARREGLO (el más chico posible)

**El filtro 3 no puede aplicarse al patrón del fallback.** Un literal que aparece a la derecha de un `||`/`??` sobre una variable sensible **es el defecto**, tenga o no entropía: el operador ya declaró que ahí iba un secreto y el código puso una constante en su lugar. Los filtros 1 y 2 (sufijos de metadato y vocabulario técnico) pueden seguir aplicándose a los dos patrones; el 3, sólo al segundo (asignación directa).

- **Archivo:** `backend/scripts/verifyNoVersionedSecrets.js`, sólo el bloque de filtros de la regla 7.
- **Test:** `backend/src/tests/verifyNoVersionedSecrets.test.js` — agregá como **caso positivo** `const X_PASSWORD = process.env.X_PASSWORD || 'letmein';` (y si querés, `?? 'secret'`). No toques los 7 negativos ni los 6 positivos que ya están.
- **NO TOCAR** nada más. Ni las otras reglas, ni las exenciones, ni los archivos ya limpiados.

## 3. LO QUE SE ACEPTA, DECLARADO (para que no lo redescubras ni lo "arregles" de más)

Dos estrecheces son **consecuencia de mi propia especificación** y las doy por buenas **por ahora**, con el costo medido:

1. **Sufijos `_NAME` / `_TYPE`:** un secreto real con ese sufijo (`API_KEY_NAME = 'sk-live-…'`) no se detecta. Lo acepto porque es el precio de no marcar `SECRET_NAME = 'JWT_SECRET'`, y queda escrito en la ficha.
2. **Valores en minúsculas de menos de 12 caracteres en asignación directa:** `X_PASSWORD = 'letmein'` no se detecta.

Lo que **sí** te pido: que esos dos queden como **comentario en el código** junto al filtro, con una línea de "sacrificio aceptado (CI-52)", para que el próximo que lo lea no lo tome por un olvido. No los arregles.

## 4. VERIFICACIÓN (números medidos; si no coinciden, PARÁ y reportá)

1. **Sonda de los dos sentidos, pegada completa** sobre el árbol de tu rama: los **7 defectos detectan** y los **13 legítimos no** ⇒ `en desacuerdo: 0`.
2. **El caso de la regresión, explícito:** `const X_PASSWORD = process.env.X_PASSWORD || 'letmein';` ⇒ **1 hallazgo**. Pegalo.
3. **Mutación:** deshabilitá el arreglo (volvé a aplicar el filtro 3 al primer patrón), corré el test nuevo, pegá el fallo, restaurá.
4. **Compuerta sobre el árbol:** `exit 0`.
5. **RED:** plantá `const X_SECRET = process.env.X_SECRET || 'Literal123!';` en un archivo versionado ⇒ **exit ≠ 0**; borralo del árbol **y del índice** y verificá `git show :<archivo> | grep -c 'Literal123'` = `0`.
6. **Gate, las dos líneas.** Base de `main` medida por mí hoy, misma máquina y sesión: `4 failed, 73 passed, 77 total` · `23 failed, 1 skipped, 568 passed, 592 total`. En tu ronda 3 la rama daba `4 failed, 74 passed, 78 total` · `23 failed, 1 skipped, 576 passed, 600 total`. Tu criterio: **esas 4 suites rojas y ninguna más**.
7. Tests del escáner: las dos líneas, en verde (eran **16/16** en tu ronda 3).

## 5. ENTREGA

Misma rama `fix/ci49-credencial-no-publicada`, **commit encima**, sin `--force`. PR con: la tabla del §1 antes/después, la sonda pegada, la mutación, el RED/GREEN, las dos líneas del gate y los dos comentarios del §3 en el código.

**Prohibiciones:** las mismas de siempre — sin `--force`, sin push a `main`, sin tocar datos de producción, sin `NODE_TLS_REJECT_UNAUTHORIZED=0`, sin ampliar `EXENTAS`/`VENDOR`, sin borrar ni saltear tests para bajar conteos.
