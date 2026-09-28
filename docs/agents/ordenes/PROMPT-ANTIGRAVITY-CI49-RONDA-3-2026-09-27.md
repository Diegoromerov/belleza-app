# Orden de ronda 3 — CI-52: la compuerta no puede marcar código legítimo

**De:** Arquitecto (Hermes) · **Para:** Ejecutor (Antigravity) · **Fecha:** 2026-09-27
**Ronda 2: ACEPTADA.** El default literal ya se detecta (0 falsos negativos, medido por mí) y los 13 literales del árbol se fueron con el diff mínimo. **No reescribas nada de eso.** Esta orden arregla lo único que quedó: la anchura de la regla 7. Tu `socialService.js` fue un buen hallazgo: quedó incorporado a CI-51.

---

## 1. EL PROBLEMA (medido en las dos revisiones)

La regla 7 marca **constantes legítimas** sólo porque su nombre contiene `KEY/SECRET/TOKEN/PASS`. Sonda de 20 casos, corriendo el árbol de `main` y el tuyo: **7 falsos positivos en los dos** (o sea: ya existían, esta ronda no los empeora, pero es la clase de defecto que hace que el equipo aprenda a ampliar exenciones — lo que esta serie de órdenes prohíbe).

Casos que **deben dejar de disparar**:

| línea | por qué es legítima |
|---|---|
| `const SECRET_HEADER = 'authorization';` | nombre de cabecera HTTP |
| `const KEY_ALGO = 'HS256';` | nombre de algoritmo |
| `const TOKEN_TYPE = 'Bearer';` | esquema de autorización |
| `const API_KEY_HEADER = 'x-api-key';` | nombre de cabecera |
| `const DB_PASSWORD_FIELD = 'password_hash';` | nombre de columna |
| `const TOKEN_KEY = 'glow_token';` | clave de almacenamiento, no secreto |
| `const SECRET_NAME = 'JWT_SECRET';` | el **nombre** de una variable |

Y estos **deben seguir disparando** (los que ya funcionan, no los rompas): `process.env.X_PASSWORD || 'Literal123!'`, `?? 'live_key_…'`, `NAME=Literal123!`, `process.env.DB_PASSWORD || 'postgres'`, `KYC_WEBHOOK_SECRET || 'glowapp_…'`, `const ADMIN_SECRET = 'SuperSecret123!';`.

## 2. EL CRITERIO (la decisión de diseño es tuya, el criterio no)

Un valor es sospechoso cuando **parece un secreto**, no cuando el nombre de la variable lo sugiere. Al menos una de estas condiciones tiene que dejar de provocar el hallazgo:

- el nombre termina en `_HEADER`, `_NAME`, `_FIELD`, `_TYPE`, `_ALGO`, `_SCOPE`, `_PARAM` (son **nombres de cosas**, no el secreto);
- el valor es una palabra de vocabulario técnica conocida (`authorization`, `bearer`, `x-api-key`, `HS256`, `RS256`, `basic`, `password_hash`, …);
- el valor no tiene entropía de secreto (sin dígitos ni símbolos, en minúsculas, < 12 caracteres).

No hace falta implementar las tres: elegí una y **fundamentá en el PR** por qué descarta los 7 casos sin tocar los 6 que deben disparar. Si preferís una lista blanca de valores conocidos, mantenela corta y **versionada con su razón**.

## 3. ALCANCE

| Acción | Dónde |
|---|---|
| **Editar** | `backend/scripts/verifyNoVersionedSecrets.js` — sólo los filtros de la regla 7 |
| **Editar** | `backend/src/tests/verifyNoVersionedSecrets.test.js` — los 7 casos negativos **y** los 6 positivos, uno por uno |
| **NO TOCAR** | nada más. En particular: no toques las reglas 1-6 ni 8, no amplíes `EXENTAS`/`VENDOR`, no toques `seed.sql`, `seedRunner.js`, `index.js` ni ninguno de los 13 archivos ya limpiados |

## 4. VERIFICACIÓN

1. **Sonda de los dos sentidos, pegada completa:** los 7 legítimos ⇒ **0 hallazgos**; los 6 defectos ⇒ **≥1 hallazgo**. Corrida sobre el árbol de tu rama, no sobre un mock.
2. **Mutación por filtro:** quitá el filtro nuevo, corré los casos negativos, pegá el fallo, restaurá.
3. **Compuerta sobre el árbol real:** `node backend/scripts/verifyNoVersionedSecrets.js` ⇒ **exit 0**.
4. **RED sigue vivo:** plantá `const X_SECRET = process.env.X_SECRET || 'Literal123!';` en un archivo versionado ⇒ **exit ≠ 0**; borralo del árbol **y del índice** y verificá `git show :<archivo> | grep -c 'Literal123'` = `0`.
5. **Gate, las dos líneas** (esto faltó en la ronda 2 y lo tuve que medir yo): `Test Suites:` y `Tests:` completas, con el comando del CI. Base medida hoy en `main`, misma máquina y misma sesión: `4 failed, 73 passed, 77 total` · `23 failed, 1 skipped, 568 passed, 592 total`. En mi corrida de tu ronda 2 la rama daba `4 failed, 74 passed, 78 total` · `23 failed, 1 skipped, 574 passed, 598 total`. Tu criterio: **esas 4 suites rojas y ninguna más**.
6. Tests del escáner: los dos archivos, **las dos líneas**, en verde.

## 5. ENTREGA

Misma rama `fix/ci49-credencial-no-publicada`, **commit encima**, sin `--force`. Cuerpo del PR: la tabla de los 7+6 casos con el resultado antes/después, la mutación pegada, las dos líneas del gate y la corrida de la compuerta. Si algo no lo pudiste medir: **«no pude medirlo»** y por qué.

**Prohibiciones:** las mismas de las rondas 1 y 2 — sin `--force`, sin push a `main`, sin tocar datos de producción, sin `NODE_TLS_REJECT_UNAUTHORIZED=0`, sin ampliar exenciones y sin borrar ni saltear tests para bajar conteos.
