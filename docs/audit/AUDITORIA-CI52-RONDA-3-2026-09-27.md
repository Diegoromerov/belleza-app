# Auditoría — CI-52 ronda 3 (rama `fix/ci49-credencial-no-publicada`)

**Auditor:** Hermes (Arquitecto) · **Fecha:** 2026-09-27
**Procedencia:** tip **`358ad3d33`** (3 commits sobre `main`), merge-base **`8ad61234a`**. Worktrees propios, banco intacto.
**Veredicto:** **ACEPTADA** (CI-52 cerrada en lo que pidió) **con una regresión medida** que abre la ronda 4.

---

## 1. Lo pedido vs lo medido

| Criterio | Medido |
|---|---|
| Alcance | ✅ exactamente 2 archivos: el escáner y su test (`11+/0-` y `36+/0-`), **sin ruido de BOM** esta vez |
| Sonda de los dos sentidos | ✅ **20/20**: 7 defectos detectan, 13 legítimos no ⇒ `0 falsos positivos / 0 falsos negativos` (en `main` eran 7 FP y 5 FN) |
| Los 7 negativos de CI-52 | ✅ 0 hallazgos cada uno |
| Los 6 positivos | ✅ ≥1 hallazgo cada uno |
| Compuerta sobre el árbol | ✅ `exit 0` |
| RED + índice limpio | ✅ declarado con `Exit Code: 1` y `git show :… | grep -c Literal123` = 0 |
| Tests del escáner | ✅ **16/16** (medido) |
| Gate, dos líneas | ✅ **esta vez las pegó**, y coinciden exactamente con mi corrida: `4 failed, 74 passed, 78 total` · `23 failed, 1 skipped, 576 passed, 600 total` = base de `main` (`4/23/592`) + tests nuevos, **ningún rojo nuevo** |

## 2. Regresión medida (el filtro 3 se aplica al patrón equivocado)

El tercer filtro —`!WEAK_PASSWORDS.has(val) && /^[a-z_]+$/ && val.length < 12`— se aplica **a los dos patrones**, incluido el de `||`/`??`:

| línea | ronda 2 | ronda 3 |
|---|---|---|
| `const X_PASSWORD = process.env.X_PASSWORD \|\| 'letmein';` | **detectaba** | **no detecta** ❌ |

Es decir: **la forma exacta de CI-49** vuelve a pasar cuando el literal no tiene entropía. La causa está en mi especificación de la ronda 3 (pedí «sin entropía de secreto» sin acotar a qué patrón aplicaba), así que el arreglo va con instrucción explícita: **el filtro de entropía sólo al patrón de asignación directa; el fallback `||`/`??` siempre dispara.** Ronda 4 emitida.

## 3. Estrecheces aceptadas, con costo medido (decisión del Arquitecto, declarada)

| caso | resultado | costo |
|---|---|---|
| `API_KEY_NAME = 'sk-live-9f3b2c7d1e4a'` | no detecta | secreto real con sufijo `_NAME`/`_TYPE` |
| `SECRET_NAME = 'Literal123!'` | no detecta | idem |
| `TOKEN_TYPE = 'eyJhbGciOiJIUzI1NiJ9.abc'` | no detecta | idem |
| `X_PASSWORD = 'letmein'` (asignación directa) | no detecta | valor corto en minúsculas |
| `X_PASSWORD=letmein` (estilo `.env`) | no detecta | idem |

Son el precio de no marcar `SECRET_NAME = 'JWT_SECRET'`, `KEY_ALGO = 'HS256'` y compañía. Se aceptan **por ahora** y la ronda 4 pide que queden como comentario en el código con la nota «sacrificio aceptado (CI-52)», para que no se lean como un olvido.

## 4. Evidencia cruda

`scratch/ci49/`: `aud11.sh` (procedencia, árbol, sonda de los dos sentidos, sonda de los filtros nuevos, tests), `probe3.js` (20 casos), `probe4.js` (11 casos de falso negativo y controles), `gate_r3.txt`.
