# Auditoría — CI-49 ronda 2 (rama `fix/ci49-credencial-no-publicada`)

**Auditor:** Hermes (Arquitecto) · **Fecha:** 2026-09-27
**Procedencia:** tip **`df295942c`** (2 commits sobre `main`), merge-base **`8ad61234a`** = `origin/main`. Medido en worktrees propios (`scratch/ci49/wt`, `wtmain`), sin tocar el banco ni la rama del Ejecutor.
**Veredicto:** **ACEPTADA** — el hueco de la ronda 1 está cerrado y medido. Queda una ficha nueva (CI-52, preexistente, no de esta entrega) y una omisión de documentación.

---

## 1. Lo que pedía la orden y lo que se midió

| Criterio pedido | Medido |
|---|---|
| Las 4 formas del default literal **detectan** | ✅ Sonda de 7 defectos: **0 falsos negativos** (en `main` eran **5**) |
| Las 4 formas legítimas **no** disparan (control negativo) | ⚠️ **7 de 13 disparan** — pero **idénticos en `main`** ⇒ **preexistentes**, no los introduce esta ronda ⇒ ficha **CI-52** |
| Las 12 ocurrencias pierden el literal | ✅ 13 archivos; el diff es de **una línea por archivo**: se va el literal, queda la variable. Sin compensaciones ni defaults nuevos |
| La regla de prosa acepta las dos grafías | ✅ `contraseña` y `contrasena` |
| Compuerta sobre el árbol | ✅ `exit 0` · «Sin credenciales versionadas en archivos trackeados» |
| RED con el patrón plantado | ✅ declarado con `Exit Code: 1` sobre `db.js` |
| `prepareRlsDatabase.js` con la variable puesta | ✅ el workflow **define `RLS_ROLE_PASSWORD` y `DATABASE_URL_ADMIN`** (`ci.yml:40,43`) ⇒ quitar el default no rompe el paso. Y sin la variable el script sale **exit 2** en `main` **y** en la rama (guard correcto, preexistente) |
| Tests del escáner | ✅ **14/14** (los dos archivos, medidos) |
| Gate, las dos líneas | ⚠️ **no las pegó** («0 delta» sin cifras) ⇒ **las medí yo**: `4 failed / 74 passed / 78 total` · `23 failed / 1 skipped / 574 passed / 598 total` |

**Gate: el delta es el correcto.** Baseline de `main` en esta misma sesión: `4 failed / 73 passed / 77 total` · `23 failed / 1 skipped / 568 passed / 592 total`. La rama agrega **una suite** (`seedRunner`) y **6 tests** y **ningún rojo nuevo** ⇒ su «0 delta» era cierto, sólo faltaba pegarlo.

## 2. Hallazgo propio de esta ronda (crédito del Ejecutor)

Encontró y limpió algo que mi orden no listaba: **`backend/services/socialService.js` publicaba una clave de cifrado de 32 caracteres** (`SOCIAL_ENCRYPTION_KEY || '12345678901234567890123456789012'`). Medido por mí: **el módulo no lo requiere nadie** (sin `require`, sin montaje de router) y **`SOCIAL_ENCRYPTION_KEY` está AUSENTE en producción** ⇒ es la misma clase que CI-51 (secreto publicado + variable ausente ⇒ sería el valor vivo si el módulo se usara) y por eso se **funde en CI-51**, con la severidad medida baja de código muerto.

## 3. Ruido declarado

Los dos archivos `frontend/backend/**` traen además la **eliminación del BOM** (`-const bcrypt` → `+const bcrypt`), sin relación con la tarea. Inocuo, pero es un cambio no pedido: va declarado, no borrado.

## 4. Ficha nueva: CI-52 (preexistente, no de esta entrega)

La regla 7 marca **constantes legítimas** cuyo nombre contiene `KEY/SECRET/TOKEN/PASS` y cuyo valor es una cadena ≥4 caracteres. Medido (idéntico en `main` y en la rama):

`const SECRET_HEADER = 'authorization';` · `const KEY_ALGO = 'HS256';` · `const TOKEN_TYPE = 'Bearer';` · `const API_KEY_HEADER = 'x-api-key';` · `const DB_PASSWORD_FIELD = 'password_hash';` · `const TOKEN_KEY = 'glow_token';` · `const SECRET_NAME = 'JWT_SECRET';`

No dispara hoy en el árbol (sale 0), así que el CI no está roto: el riesgo es el de siempre — **una compuerta que marca código legítimo enseña al equipo a ampliar exenciones**, que es exactamente lo que esta orden prohíbe. Se arregla en la ronda 3.

## 5. Errores propios de esta auditoría (R-06)

1. Leí `exit=0` de `prepareRlsDatabase.js` cuando el `exit` que estaba midiendo era el de `tail` al final de un pipe. Con la captura correcta (sin pipe) el script sale **2** en las dos revisiones. Tercera vez en el día que el artefacto era mío.
2. Mi orden pidió correr `prepareRlsDatabase.js` contra base fresca, y **mi entorno no tiene `DATABASE_URL_ADMIN`** ⇒ no pude reproducir esa corrida en local (el CI sí la tiene, medido en `ci.yml`). Queda declarado como **no pude medirlo en local**, no como medido.

## 6. Evidencia cruda

`scratch/ci49/`: `aud4.sh` (procedencia, alcance, barrido de literales, la regla 7 tal como quedó), `probe3.js` (sonda de 20 casos, los dos sentidos), `aud5.sh` / `aud6.sh` (probe contra la rama y contra `main`), `aud8.sh` (los 12 diffs), `aud9.sh` (uso de `socialService` + variables de producción), `aud10.sh` (`prep_main.txt`, `prep_rama.txt`, `prep_bad.txt`), `gate_r2.txt`.
