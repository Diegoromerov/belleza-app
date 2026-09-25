# Auditoría — entrega de A-06 ronda 3 (cierre de la compuerta)

**Fecha:** 2026-09-25 · **Auditor:** Hermes
**Procedencia verificada:** 2a `origin/fix/compuerta-secretos-reproducible` @ **`08a1fb99`** (3 commits sobre `fase-a`, `merge-base` = `c1069e9f` ✓) · 2b `origin/fix/jwt-sin-respaldo` @ **`049fcc0e`** (5 commits, encadenada sobre 2a ✓). Worktrees desechables retirados (3, como al empezar); ramas intactas.

## Veredicto: **ACEPTADA** — con 1 criterio **mal formulado por mí**, 1 cifra suya incompleta y **1 retracción mía**

| # | Criterio | Mi medición |
|---|---|---|
| C2 | Dos saltos de `.md` acotados | ✓ `:111` y `:125`, ambos `/^docs\/.*\.md$/i` |
| C4 | Cero literales, incluido el de test | ✓ `git grep "test_secret_glowapp_jwt_token_key"` = **0**; clave generada con `crypto.randomBytes(32)` y **memoizada** (`jwt.js:4-10`, `biometricCryptoService.js:5-11`) ⇒ firma/verificación y cifrado/descifrado siguen siendo coherentes dentro de un proceso; sus dos suites pasan (`4 passed`) |
| C5 | `test` fuera de las exenciones | ✓ fuera de las **tres** reglas de valor: `:32`, `:98`, `:162` |
| C6 | `DEUDA.md` de la raíz | ✓ ausente en 2a y en 2b |
| C3 | Listado de hallazgos | ⚠ **su cifra es 5; la real es 8** |
| C1 | La normalización probada por caída | ✗ **y el criterio era mío y estaba mal formulado** |

### C3 — la cifra que se queda corta, y por qué importa

Escáner sobre la rama 2a (la que se entrega): **8** hallazgos, `EXIT=1`.

```
AUDITORIA_PREPRODUCCION_MASTER.md:84         BLOQUE_TRABAJO_1_BASELINE.md:144
auditoria-belleza-app.md:232                 auditoria-belleza-app.md:233
backend/src/config/jwt.js:1                  backend/src/config/jwt.js:2
backend/src/services/biometricCryptoService.js:18
scripts/COMO_EJECUTAR.md:35
```

Su lista de 5 es exactamente **la que sale con 2b ya aplicado** (los 3 de código desaparecen con 2b). Sobre lo que se entrega en 2a son 8, y la diferencia no es cosmética: son los tres literales que importan.

### C1 — me equivoqué yo al pedirlo

Pedí un test **rojo** al retirar la normalización del camino real. Medido, en cuatro corridas sobre el mismo commit `08a1fb99`:

| Mutación | Hallazgos |
|---|---|
| normalización por línea **ON** (9 sitios) | **8** |
| normalización por línea **OFF** (9/9 retirados) | **8** |

⇒ Los nueve `replace(/\r$/, '')` son **decorativos**: no cambian un solo hallazgo. Ningún test puede ponerse rojo por retirarlos, y su autotest (que asevera una desigualdad con un flag) tampoco. **Mi criterio era imposible de cumplir.**

La normalización que **sí** carga el peso es otra, y la encontré:

```js
// verifyNoVersionedSecrets.js:140
return rawOutput.replace(/\r\n/g, '\n').replace(/\r/g, '\n');
```

Retirándola: **`EXIT=0` con las 8 credenciales en el árbol** — la compuerta queda **muda**. Ese es el sitio que hay que probar, y ningún test de los entregados lo toca.

## Retracción mía (R-06): «2b abrirá el paso 7» era **falso**

Con 2a+2b, los 3 literales de código desaparecen, pero **los 5 hallazgos en prosa se quedan**. El paso 7 seguirá rojo después de 2a+2b hasta que esas 5 líneas se resuelvan. Lo dije mal en la auditoría de la ronda 2 y quedó dicho también al Dueño: **queda retractado aquí**, no borrado.

## Límites de esta auditoría

1. **No corrí la suite completa** de 2b: sólo las dos suites del código cambiado (`jwtNoFallback`, `biometricNoFallback`). Con `JWT_SECRET` presente (como en CI) el camino de código es idéntico al anterior, así que el riesgo de regresión está acotado al uso local sin variable.
2. **Mi primera medición CRLF/LF fue un artefacto mío**: rompí el índice de una copia con `git rm --cached` y salió 0 hallazgos. Publico la comparación de **la misma copia con y sin normalización**, no la de dos árboles distintos. Dato relevante para futuras mediciones: **los blobs del repo ya son CRLF** (1886 CR en el blob de `index.js`), así que un checkout «LF» en Windows no existe sin reescribir contenido.
