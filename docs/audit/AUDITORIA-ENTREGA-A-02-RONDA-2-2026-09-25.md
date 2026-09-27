# Auditoría — A-02 ronda 2 (métricas de admin y servicio puro) · `f565037c`

**Fecha:** 2026-09-25 · **Auditor:** Hermes
**Procedencia:** `origin/fix/admin-metricas-sin-datos` @ **`f565037c`** (2 commits sobre `fase-a`), `merge-base` con `fase-a` = **`3cef7f88`** y `--is-ancestor` ✅ ⇒ **C0' cumplido** (rebasada). Worktree desechable propio; mutación aplicada por mí dentro de él.

## Veredicto: **ACEPTADO** — el cargo grave está cerrado y la prueba ahora prueba. Un hallazgo nuevo y menor (§Hallazgo).

---

## Lo medido por mí

| Criterio | Resultado |
|---|---|
| **C1'/C2'/C3'/C4'** | ✅ **Su suite corrida por mí**: `Test Suites: 1 passed · Tests: 4 passed, 4 total` |
| **C5' (el que importaba)** | ✅ **Mi mutación la pone en rojo.** Reintroduje la fabricación **sin `Math.random`** (rellenar los meses que faltan con `revenue: 912345` dentro del `if (count < 3)`) ⇒ **`3 failed, 1 passed`**. La que pasa es C3' (≥3 meses), camino que mi mutación no toca: correcto, no un hueco — C3' comprueba `toBe(4000)`, así que una cifra inventada en ese camino también caería |
| **C6'** | ✅ 0 aserciones sobre el texto: la suite **importa el servicio** y afirma sobre lo que devuelve (`toBeNull`, `toEqual`, `toBe(4000)`); la matemática esperada está recalculada en el test, no copiada de la fórmula |
| **C7'** | ✅ **El denominador cuadra**: 81 suites coleccionables en su rama (`jest --listTests`) = sus **66 verdes + 15 rojas heredadas**; su rama añade **exactamente 1** archivo de test vs `fase-a`. *(Las 15 rojas no las medí yo: la suite completa necesita base; queda como declarado, no verificado.)* |
| **C8'** | ✅ PR contra `main` (enlace `pull/new/...`); el PR no existe por la frontera de plataforma (CI-10/frontera), no por él |

## La ruta: el pecado original, extirpado

- `index.js:827` llama `buildProjections(realHistory)`; `index.js:842` **devuelve `projections`** dentro de `data` ⇒ el panel recibe `data_status`, `meses_con_datos`, `history`, `projectedMonth`, `projectedRevenue` y `trend` ✓.
- **Grep de `Math.random` en toda la ruta: solo `:120` (`uniqueSuffix`)**, el legítimo. El bucle que fabricaba ingresos con `450000 + (4 - i) * 120000 + Math.floor(Math.random() * 60000)` **ya no existe** ✓.
- Su servicio cumple lo pedido: `<3` meses ⇒ `insuficiente`, `projectedRevenue: null`, `projectedMonth: null`, `trend: 'INSUFICIENTE'` **y `history` con los meses reales** (Cargo 2 cumplido: ya no oculta datos reales); `≥3` ⇒ regresión determinista y **no negativa** (`Math.max(0, …)`) ✓.
- Verifiqué la aritmética por fuera: serie 1000/2000/3000 ⇒ `slope=1000`, `intercept=0`, x=4 ⇒ **4000** ✓ coincide con la prueba y con mi cálculo independiente.
- Su C4' respeta la instrucción de la orden: no duplica el test del candado; declara que el 503 es del middleware ✓ (el chequeo interno de la ruta queda inalcanzable por HTTP, como avisé).

## Hallazgo (nuevo, mío, y es real)

**El mes proyectado puede ser el equivocado.** `adminMetricsService.js:54-56` calcula el próximo mes con `nextMonthDate.setMonth(nextMonthDate.getMonth() + 1)` sobre **hoy**: si hoy es 29, 30 o 31, JavaScript normaliza al mes siguiente y la etiqueta **salta un mes de más**. Medido con la función de la entrega:

```
now=2026-01-15 -> projectedMonth=2026-02   ✅
now=2026-01-31 -> projectedMonth=2026-03   ✗ (debería 2026-02)
now=2026-03-31 -> projectedMonth=2026-05   ✗ (debería 2026-04)
now=2026-08-31 -> projectedMonth=2026-10   ✗ (debería 2026-09)
now=2026-12-31 -> projectedMonth=2027-01   (acierta por casualidad)
```

El **importe** es correcto; lo que miente es **el mes que el panel le enseña al admin**. Root cause: aritmética de `Date` sobre el día del mes en vez del índice de meses. En la misma línea hay una segunda conversión (`toISOString()` = UTC sobre una fecha local) que **no medí** y declaro como latente, no como defecto. → **CI-18**, con **ronda 3 corta** emitida (no merece una orden larga, pero un panel que etiqueta el mes equivocado es exactamente lo que esta fase persigue).

## Límites

- No corrí la suite completa (necesita base): los «15 fallos heredados» son declaración suya; el conteo que sí verifiqué es el denominador.
- No medí el endpoint por HTTP: el candado lo tapa en degradado y el cálculo vive ahora en una función pura que sí probé.
- Corroboración lateral: 82 archivos `.test.js` en el árbol y **81 coleccionables** ⇒ una suite nunca se colecta (lo que ya dice **CI-12**).
