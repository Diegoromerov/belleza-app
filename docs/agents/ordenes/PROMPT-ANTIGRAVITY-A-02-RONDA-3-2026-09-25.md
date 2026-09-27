# ORDEN A-02 · RONDA 3 (corta) — el mes que miente

**Auditoría de la ronda 2:** `docs/audit/AUDITORIA-ENTREGA-A-02-RONDA-2-2026-09-25.md`
**Rama:** la misma, `fix/admin-metricas-sin-datos` (un commit más; **una tarea = una rama = un PR**).

## Veredicto de la ronda 2: **ACEPTADA** (lo que pedí está y lo medí yo)

- `merge-base` con `fase-a` = **`3cef7f88`** ✓ (C0').
- **Su suite corrida por mí**: `4 passed, 4 total` ✓ (C1'-C4').
- **C5' — mi mutación la pone en rojo**: rellené los meses que faltan con ingresos inventados **sin `Math.random`** ⇒ **`3 failed, 1 passed`** ✓. La que sobrevive es C3' (≥3 meses), camino que la mutación no toca: correcto, porque C3' afirma `toBe(4000)`.
- En `index.js` ya **no queda ningún `Math.random`** salvo el legítimo (`uniqueSuffix`, `:120`), el bucle de fabricación **desapareció** y `projections` se devuelve dentro de `data` (`:842`) ✓.
- `history` conserva los meses reales con 1-2 meses (Cargo 2 cumplido): ya no oculta datos reales ✓.
- C6' ✓ (0 `toContain`; la prueba importa el servicio y afirma sobre lo que devuelve), C7' ✓ (81 coleccionables = 66 verdes + 15 heredadas), C8' ✓ (PR contra `main`).

## Cargo único — el mes proyectado puede ser el equivocado

Medido hoy con **tu propia función**:

```
now=2026-01-15 -> projectedMonth=2026-02   ✅
now=2026-01-31 -> projectedMonth=2026-03   ✗ debe ser 2026-02
now=2026-03-31 -> projectedMonth=2026-05   ✗ debe ser 2026-04
now=2026-08-31 -> projectedMonth=2026-10   ✗ debe ser 2026-09
now=2026-12-31 -> projectedMonth=2027-01   (acierta por casualidad)
```

**Causa:** `nextMonthDate.setMonth(nextMonthDate.getMonth() + 1)` sobre **hoy**. Si hoy es 29, 30 o 31, JavaScript normaliza (31 de enero + 1 mes = 3 de marzo) y la etiqueta **salta un mes de más**. El **importe es correcto**; lo que miente es **el mes que el panel le enseña al admin**.

**Qué se pide:**

1. Deriva el mes proyectado del **índice de meses**, no de aritmética de `Date` sobre el día de hoy: p. ej. a partir del **último mes real** del historial, o fijando el cálculo al **día 1** del mes.
2. **Cuidado con la segunda conversión:** `toISOString()` devuelve **UTC** sobre una fecha local. Si el mes sale de una fecha, hazlo determinista respecto de `now` y **dilo en una línea** del reporte.
3. **Tests de borde, con `now` inyectado** (ya tienes el parámetro — úsalo, no `new Date()` dentro):
   - `now=2026-01-31 ⇒ projectedMonth='2026-02'`
   - `now=2026-03-31 ⇒ projectedMonth='2026-04'`
   - `now=2026-12-31 ⇒ projectedMonth='2027-01'` (cambio de año)
4. **Pega la mutación otra vez**: vuelve al `setMonth` sobre hoy y demuestra que el **nuevo** test se pone **rojo**.

## Criterios de cierre

| # | Criterio | Cómo se prueba |
|---|---|---|
| C1'' | `now=2026-01-31 ⇒ '2026-02'` **y** `now=2026-03-31 ⇒ '2026-04'` | los dos tests |
| C2'' | `now=2026-12-31 ⇒ '2027-01'` (borde de año) | test |
| C3'' | **Mutación pegada**: volver al `setMonth` sobre hoy ⇒ el nuevo test **rojo** | salida del fallo |
| C4'' | Tus C1'-C4' siguen verdes y `npm test` con su resumen (failed/passed/total) | salida |
| C5'' | Commit **en la misma rama**, con SHA | `git log -1` |

## Prohibiciones

Cambiar el **importe** de la proyección (es correcto: no lo toques) · tocar el candado o `degradedLockBehavior.test.js` · meter dependencias de fecha nuevas (`moment`, `luxon`, `date-fns`) · abrir otra rama · «lo probé a mano» sin salida pegada.
