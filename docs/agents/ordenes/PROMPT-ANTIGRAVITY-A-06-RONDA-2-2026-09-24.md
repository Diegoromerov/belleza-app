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

## Cargo 2 — tres hallazgos de seguridad no son «falsos positivos» (crítico)

`backend/src/config/jwt.js:5-11`, medido en el árbol entregado:

```js
6    const secret = process.env.JWT_SECRET || DEFAULT_PROD_SECRET;
7    if (!secret || secret.length < MIN_SECRET_LENGTH) {
8      return DEFAULT_PROD_SECRET;
```

Sin `JWT_SECRET` (o con menos de 32 caracteres) **todos los tokens se firman con un literal que está publicado en este repositorio público** ⇒ cualquiera puede fabricar un token y `toApiRole` lo mapea a `admin`.

**Qué hacer, fallando cerrado:**
1. `getJwtSecret()` **lanza** si falta el secreto fuera de `NODE_ENV=test` (y en test usa un valor de test explícito, como ya hace `TEST_SECRET`). Eliminar `DEFAULT_PROD_SECRET` del código.
2. `biometricCryptoService.js:18,39,59`: misma decisión para las claves de cifrado — sin respaldo literal; lanza si falta la variable.
3. Si el arranque falla por esto en algún entorno, **eso es el hallazgo**, no un motivo para volver a poner el respaldo. Repórtalo.
4. Actualiza `DEUDA.md` → fila **TEC-53**: el fallback **no** depende de `NODE_ENV` (eso decía la fila); hoy es incondicional. Y añade el cierre con su test.

**Prohibido** aquí: declarar un hallazgo de seguridad como falso positivo, o allowlistear el valor que lo dispara. Un hallazgo de seguridad se arregla o se escala al dueño.

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

## Cargo 5 — C6: la prueba tiene que venir del CI

Paso 7 en verde **y los pasos 8-11 ejecutándose** (ya no `skipped`), con la URL del run en el cuerpo del PR. Abre el PR a `fase-a/verdad-operativa` y pega la URL; si el paso 8 (esquema RLS) cae, **eso ya es la orden A-01 en acción** y no bloquea el cierre de A-06: lo que se exige aquí es que el paso 7 pase y que el 8 corra.

## Criterios de aceptación de la ronda 2

| # | Criterio | Cómo se prueba |
|---|---|---|
| C1 | Una mutación `'glowapp_jwt_production_secure_secret_key_at_least_32_chars'` **falla** el escáner | mutación plantada con `git add` en copia descartable ⇒ `exit 1`, pegado |
| C2 | Las 5 mutaciones que hoy detecta **siguen** detectándose tras el cambio | la tabla completa de la auditoría, re-corrida |
| C3 | `jwt.js`: sin `JWT_SECRET` en `NODE_ENV=production` el proceso **lanza** (o el endpoint de auth falla cerrado) y ningún camino usa un literal | test nuevo + `grep -c DEFAULT_PROD_SECRET backend/src/config/jwt.js` = 0 |
| C4 | `biometricCryptoService.js`: sin la variable de entorno, lanza; cero literales de respaldo | test nuevo + `grep` de los tres sitios |
| C5 | El autotest **falla** si se quita la normalización | demuéstralo: quítala, corre el test, pega el fallo, vuelve a ponerla |
| C6 | Paso 7 verde en CI y pasos 8-11 ejecutados | URL del run del PR |
| C7 | `EXENTAS` sin `^.github/workflows/`, sin prefijos de iniciales y sin eximir código bajo `docs/` | el propio archivo, pegado |
| C8 | `DEUDA.md` con TEC-53 corregida y su cierre | enlace a la fila |

## Prohibiciones (se repiten porque son el motivo del rechazo)

Bajar el paso 7 a no bloqueante · allowlistear el valor que dispara un hallazgo · declarar «falso positivo» un hallazgo de seguridad sin arreglarlo · añadir exenciones por prefijo de nombre de archivo · un test que no pueda fallar · tocar `index.js`.
