# ORDEN A-06 · RONDA 2 — la compuerta no puede quedar ciega a los secretos del proyecto

**Auditoría de la ronda 1:** `docs/audit/AUDITORIA-ENTREGA-A-06-2026-09-24.md` (veredicto **✗ rechazada**)
**Rama:** la misma, `fix/compuerta-secretos-reproducible` (un commit más encima del `5020e4df`).
**Se conserva:** la normalización de fin de línea (`gitGrep` + `replace(/\r$/,'')` en cada validador) y la exclusión de prosa. **Eso no se toca.**

---

## GOAL (una frase)

Que la compuerta siga viendo **los secretos de este proyecto** (los que se llaman `glowapp_…`) y que su autotest **pueda fallar** cuando la normalización desaparece.

## Cargo 1 — revertir la allowlist de prefijos (crítico)

Se añadieron `postgres|dev_|glowapp_|default|root` como prefijos exentos de valor. Efecto medido (mutación con `git add` + escáner en checkout LF):

| Valor plantado | Hoy |
|---|---|
| `'glowapp_jwt_production_secure_secret_key_at_least_32_chars'` | **✅ exit 0 — ciega** |
| `'Xk92LmQ7ppQzRt4VbN8wYs3Dd6Ff'` | ❌ exit 1 |
| `'nvapi-…'` · `'sk-…'` · `'ghp_…'` · `postgres://u:clave@host` | ❌ exit 1 |

**Qué hacer:** quitar `glowapp_` y `dev_` de la lista de prefijos (y `default`, que es un nombre genérico). Si hace falta eximir algo, que sea **un valor exacto**, nunca un prefijo que el proyecto use para nombrar secretos. Criterio C1 de abajo.

## Cargo 2 — la compuerta tiene que VER el hallazgo (y el arreglo del código va aparte)

`backend/src/config/jwt.js:5-11`, medido en el árbol entregado:

```js
6    const secret = process.env.JWT_SECRET || DEFAULT_PROD_SECRET;
7    if (!secret || secret.length < MIN_SECRET_LENGTH) {
8      return DEFAULT_PROD_SECRET;
```

Sin `JWT_SECRET` (o con menos de 32 caracteres) todos los tokens se firman con un literal **publicado en este repositorio público** ⇒ cualquiera fabrica un token y `toApiRole` lo mapea a `admin`. La ronda 1 lo declaró «falso positivo dev» y lo eximió. **Un hallazgo de seguridad se arregla o se escala; no se declara falso.**

Se parte en dos, **en dos ramas** — y el motivo de separarlas no es formal:

**2a · en esta rama (`fix/compuerta-secretos-reproducible`) — la compuerta ve; el código de la app no se toca.**
Tras quitar la allowlist (Cargo 1), el escáner debe **disparar `exit 1`** con ese literal. Ese es el entregable de 2a: que el hallazgo **no pueda volver a esconderse** por convención de nombre. Actualiza `DEUDA.md` → fila **TEC-53**: el fallback **no** depende de `NODE_ENV` (eso decía la fila vieja); hoy es incondicional y sigue **abierto**.

**2b · rama nueva `fix/jwt-sin-respaldo` — el arreglo, y NO es mergeable todavía.**
Quitar `DEFAULT_PROD_SECRET` y **fallar cerrado**: `getJwtSecret()` **lanza** si falta el secreto fuera de `NODE_ENV=test` (en test, un valor de test explícito, como `TEST_SECRET`); lo mismo en `biometricCryptoService.js:18,39,59` (cero literales de respaldo).

**La condición que hace que 2b no se mergee sola:** si producción no tiene `JWT_SECRET` definido, ese cambio **tumba la autenticación** en cuanto entre a `main`. Por eso 2b exige, en el cuerpo del PR, **la confirmación del Dueño** de que `JWT_SECRET` (y las claves de cifrado) están definidas en producción — lo verifica el Dueño en Railway, donde ningún agente tiene permiso. Hasta esa confirmación, 2b queda **en rama, sin PR o como draft marcado «no mergear»**. La secuencia segura es esta: **primero el secreto existe; después se retira el respaldo.** Si tu corrida descubre que el arranque falla por esto, **eso es el hallazgo** — repórtalo, no vuelvas a poner el literal.

**Prohibido aquí:** declarar un hallazgo de seguridad como falso positivo · allowlistear el valor que lo dispara · meter 2b dentro del PR de 2a (si el respaldo desaparece antes de que exista la variable, el arreglo *es* el apagón).

## Cargo 3 — el autotest tiene que poder fallar (C5)

El test actual no prueba nada: el nº1 corre el script y exige exit 0 (pasa siempre), el nº2 compara dos `String.replace` de JavaScript **sin llamar al escáner**.

**Qué hacer:** un test que ejerza la **lógica del escáner** y no el lenguaje:
- Construye una línea con `\r` al final y otra sin él, con un valor que **sí** debe detectarse (`MI_CLAVE_SECRETA = 'Xk92…'`), y exige **el mismo veredicto** en ambos casos.
- Añade la **prueba de mutación del propio test**: con la normalización quitada (simulable extrayendo la función de validación, o con un parámetro/flag de test), el test debe **fallar**. Si no logras hacerlo fallar, es que sigue siendo tautológico.
- Nada de `execFileSync` sobre el repo real como aserción: el repositorio limpio no demuestra nada sobre el escáner.

## Cargo 4 — acotar la allowlist de rutas

- **`^\.github/workflows/` sale de `EXENTAS`.** La exención era para los valores efímeros del runner, no para el directorio. Si hay que eximir `POSTGRES_PASSWORD: postgres` y las cadenas a `localhost/glowtest`, hazlo **en la regla y por valor**, con el motivo escrito al lado.
- **`^docs/`** exime código que vive bajo `docs/` (`docs/rag-audit-2026-09-22/probes/*.js`): exime `docs/**/*.md` y deja el resto a juicio de las reglas.
- **`^F7`, `^RAG_`, `^D001`, `^BLOQUE_`, `^AUDITORIA`, `^README`, `^auditoria`**: son los nombres de los informes de hoy. Sustitúyelos por una regla que hable del **tipo** (documento en la raíz: `.md` de nivel raíz), no de sus iniciales.

## Cargo 5 — C6: la prueba tiene que venir del CI (**corregido: la base del PR estaba mal**)

> ⚠️ Esta orden decía «abre el PR a `fase-a/verdad-operativa`». **Eso no dispara ningún run**: `ci.yml` solo escucha `pull_request` contra **`main`** y `staging`. Medido y registrado como **CI-10**. Si entregas así, C6 es imposible de cumplir — y ya pasó una vez en este ciclo.

Para tener evidencia del paso 7, elige una:
- **Opción A (recomendada):** PR contra **`main`**. Traerá dentro los 6 commits de Fase A + el tuyo; el run correrá los pasos 7 a 11.
- **Opción B:** que tu commit entre en `fase-a/verdad-operativa` (push a esa rama) ⇒ **PR #16 se re-ejecuta solo** y ahí se ve el paso 7.

Lo exigido: **paso 7 en verde y pasos 8-11 ejecutándose** (ya no `skipped`), con la **URL del run** en el cuerpo del PR. Si el paso 8 (esquema RLS) cae, **eso es A-01 en acción** y no bloquea el cierre de A-06: aquí se exige que el 7 pase y que el 8 **corra**.

## Criterios de aceptación de la ronda 2

| # | Criterio | Cómo se prueba |
|---|---|---|
| C1 | Una mutación `'glowapp_jwt_production_secure_secret_key_at_least_32_chars'` **falla** el escáner | mutación plantada con `git add` en copia descartable ⇒ `exit 1`, pegado |
| C2 | Las 5 mutaciones que hoy detecta **siguen** detectándose tras el cambio | la tabla completa de la auditoría, re-corrida |
| C3 | **2b, rama aparte**: `jwt.js` sin `JWT_SECRET` en `NODE_ENV=production` **lanza** y ningún camino usa un literal | test nuevo + `grep -c DEFAULT_PROD_SECRET backend/src/config/jwt.js` = 0 |
| C4 | **2b, rama aparte**: `biometricCryptoService.js` sin la variable de entorno lanza; cero literales de respaldo | test nuevo + `grep` de los tres sitios |
| C5 | El autotest **falla** si se quita la normalización | demuéstralo: quítala, corre el test, pega el fallo, vuelve a ponerla |
| C6 | Paso 7 verde en CI y pasos 8-11 ejecutados | **PR contra `main`** (o commit dentro de `fase-a`) + URL del run |
| C7 | `EXENTAS` sin `^.github/workflows/`, sin prefijos de iniciales y sin eximir código bajo `docs/` | el propio archivo, pegado |
| C8 | `DEUDA.md` con **TEC-53 corregida** (hoy dice que depende de `NODE_ENV`; es incondicional) y **abierta**, apuntando a 2b | enlace a la fila |
| C9 | 2b entregada **sin mergear** (rama, o PR en draft) y con la condición del Dueño escrita en el cuerpo | enlace del PR |

## Prohibiciones (se repiten porque son el motivo del rechazo)

Bajar el paso 7 a no bloqueante · allowlistear el valor que dispara un hallazgo · declarar «falso positivo» un hallazgo de seguridad sin arreglarlo · añadir exenciones por prefijo de nombre de archivo · un test que no pueda fallar · tocar `index.js`.
