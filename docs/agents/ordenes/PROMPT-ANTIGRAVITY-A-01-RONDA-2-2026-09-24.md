# ORDEN A-01 · RONDA 2 (ligera) — el arreglo está aprobado; falta que el CI pueda ejecutarlo

**Auditoría de la ronda 1:** `docs/audit/AUDITORIA-ENTREGA-A-01-2026-09-24.md`
**Rama:** `fix/rls-056-058-cadena` (misma rama, rebasada).
**Veredicto:** ✓ aceptada en sustancia — la causa raíz que arreglaste es la correcta y **la aserción quedó probada por mutación** (quitando `tenant_id` a `services`, el `058` entregado falla nombrando la tabla; el de `main` falla con un error crudo). Reproduje tu evidencia en base virgen: `PREPARE ×2 = 0`, `VERIFY = 0`, 12 políticas, 0 duplicadas. **No rehagas nada de eso.**

## Los 4 pendientes

1. **Rebasa sobre `fase-a/verdad-operativa`** (o entrega el mismo commit en esa rama). Tu rama nace de `origin/main`, y `main` conserva **3 marcadores de conflicto** en `.github/workflows/ci.yml` ⇒ el PR saldrá **con 0 jobs** y no habrá run que muestre los pasos 8-11. Comprobado: la rama hereda esos 3 marcadores, no trae `backend/scripts/checkNoConflictMarkers.js` ni la normalización de fin de línea de A-06. `fase-a` **no toca** `backend/migrations/` (diff vacío), así que el rebase es limpio.
   ```
   git fetch origin && git rebase origin/fase-a/verdad-operativa
   ```
   Si aparece cualquier conflicto fuera de esos dos archivos, **párate y repórtalo**.
2. **Quita la línea muerta de `056`.** El commit dice «corrigió `servicios` a `services`», pero el diff **añade** `services` y **deja** `servicios` (tabla inexistente que `IF EXISTS` vuelve una sentencia vacía). Fuera esa línea: la mitad del hallazgo original es que el nombre en español nunca existió.
3. **Replica la aserción en el segundo bucle de `058`** (el de `policy_tables`, líneas ~57-68). Hoy solo está en el de `rls_tables`. Como el runner manda cada `.sql` en una consulta y **sus errores quedan como warning**, un fallo en el segundo bucle pasaría por alto; con la aserción, nombra la tabla. Mismo texto, mismo `RAISE EXCEPTION`.
4. **Corrige la cifra en tu reporte:** son **12** tablas con RLS + FORCE + 1 política, y declara explícitamente que **`usuarios` es excepción deliberada** (documentada en `068:39-51` y `EXENTAS_DE_FORCE` en `prepareRlsDatabase.js:157`). Cuatro de los catorce nombres de `058` no existen en base recién montada: `admin_mfa`, `platform_config`, `sos_alerts`, `user_activity_logs`.

## Criterios de cierre

| # | Criterio | Cómo se prueba |
|---|---|---|
| C1 | `merge-base` con `fase-a/verdad-operativa` = `c1069e9f` (o posterior) y no con `f5a1b4fc` | `git merge-base origin/fase-a/verdad-operativa HEAD` |
| C2 | La rama tiene `ci.yml` **sin** marcadores y con `checkNoConflictMarkers.js` | `grep -c "^<<<<<<<" .github/workflows/ci.yml` = 0 · el script existe |
| C3 | `056` sin la línea de `servicios` | el propio archivo, pegado |
| C4 | Aserción presente en **los dos** bucles de `058` | pegar las dos ocurrencias de `RAISE EXCEPTION` |
| C5 | La evidencia local sigue igual tras el rebase | `PREPARE ×2 = 0` y `VERIFY = 0` sobre base descartable, pegado otra vez |
| C6 | URL del PR **a `main`** y su estado por paso. **Expectativa real (medido 2026-09-25):** con el rebase el run **sí existirá** (jobs > 0, ya no los 0 jobs de CI-10), pero **seguirá muriendo en el paso 7** — la compuerta de secretos, que hoy ve **2 literales reales** (`jwt.js:2`, `biometricCryptoService.js:18`) y sólo se pondrá verde cuando aterricen A-06 2a+2b. Lo exigido aquí **no es un verde**: es que el run exista, que el **único rojo sea el paso 7** y que los pasos 8-11 queden identificados como `skipped` por esa causa | URL del run + estado paso por paso |

## Prohibiciones

Rehacer la migración desde cero · quitar la aserción «porque ya pasa» · cambiar el nombre de la tabla `services` a `servicios` «para unificar» · tocar `index.js` · dejar la rama nacida de `main` «porque ya está pusheada».
