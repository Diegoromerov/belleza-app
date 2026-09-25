# Auditoría — entrega de A-01 ronda 2 (cadena RLS 056/058)

**Fecha:** 2026-09-25 · **Auditor:** Hermes
**Procedencia verificada:** `origin/fix/rls-056-058-cadena` @ **`ba06e563`** — 2 commits sobre `fase-a/verdad-operativa` (`16f0cd54` + `ba06e563`), `merge-base` = **`c1069e9f`** ✓. Diff contra `fase-a`: **sólo** las dos migraciones (+25 / −9). Nada más tocado. Árbol auditado limpio; worktree desechable retirado (3 worktrees, como al empezar).

## Veredicto: **✓ ACEPTADA** — la entrega más sólida de la fase

| # | Criterio | Mi medición (no su reporte) |
|---|---|---|
| C1 | `merge-base` con `fase-a` | ✓ **`c1069e9f`**, y no `f5a1b4fc` |
| C2 | `ci.yml` sin marcadores + script anti-marcadores | ✓ **0** ocurrencias de `^<<<<<<<`; `checkNoConflictMarkers.js` presente |
| C3 | `056` sin la línea muerta | ✓ único `services` en **`056:7`**; **cero** `servicios` |
| C4 | Aserción en **los dos** bucles | ✓ `RAISE EXCEPTION` en **`:34`** (bucle `rls_tables`) y **`:72`** (bucle `policy_tables`), y **probada como código vivo** |
| C5 | Evidencia local sostenida | ✓ **re-corrida por mí**, ver abajo |
| C6 | PR + run | ✗ su enlace es `pull/new/…` ⇒ **no hay PR ni run** (frontera de la plataforma: sin `gh`/token no se puede crear; no es su culpa) |

### C4 — la mutación que aísla el segundo bucle

Quité la aserción del **primer** bucle en una copia mía (`058_sin_bucle1.sql`, aserción sustituida por `NULL;`), retiré la columna con `ALTER TABLE productos DROP COLUMN IF EXISTS tenant_id CASCADE;` y mandé el archivo mutado a la base:

```
ERROR:  MIGRATION ASSERTION ERROR (058): La tabla "productos" existe en el esquema pero carece de la columna "tenant_id" para aplicar RLS.
```

Es decir: el segundo bucle **sí** dispara, **nombra la tabla** y está colocado **antes** del `CREATE POLICY` — falla antes de tocar DDL, que es lo correcto. Lo medido no queda en «está el texto»: queda en «el texto hace algo».

### C5 — re-corrida independiente sobre base descartable

Base recreada (`glowtest_audit_a01r2`); credenciales del contenedor tomadas de su propio entorno y **nunca impresas**; contraseña de los roles RLS generada por mí y desechable.

```
PREPARE 1 EXIT=0      (base vacía: init.sql + 055…068)
PREPARE 2 EXIT=0      (idempotente: init.sql omitido, migraciones re-aplicadas)
VERIFY  EXIT=0
✅ AISLAMIENTO MULTI-TENANT VERIFICADO
   tablas con RLS + FORCE + 1 política: 12
   ✅ sin contexto de inquilino se ven 0 filas (falla cerrado, no lanza error)
   ✅ escribir en el inquilino ajeno es RECHAZADO (WITH CHECK en vigor, error 42501 → el handler lo convierte en 403)
```

Coincide con su evidencia y con lo que yo mismo había reproducido en la ronda 1. La base descartable se eliminó al terminar.

## Propiedades que confirmo

1. **`usuarios` sigue siendo la excepción deliberada**: 13 tablas con `tenant_id`, 12 con FORCE y 12 con política. Coincide con `068:39-51` y con `EXENTAS_DE_FORCE` de `prepareRlsDatabase.js`. Su corrección de la cifra (de «14» a «12») es exacta.
2. **Las listas de `056` (11 nombres) y `058` (14) no son la misma, y está bien**: `058` aplica sólo donde la tabla existe, y ahora **falla nombrando** si existe sin la columna. Cuatro de los nombres de `058` no existen en base recién montada (`admin_mfa`, `platform_config`, `sos_alerts`, `user_activity_logs`) — si alguien las crea en el futuro sin `tenant_id`, la aserción lo dirá en vez de dejar un error crudo.
3. **Por qué la aserción importa aquí**: el runner manda cada `.sql` en **una** consulta y sus errores quedan como **warning** (no frenan el arranque). Sin la aserción, un fallo de `058` pasaría como línea amarilla en el log.

## Límites de esta auditoría

1. **C6 no está**: sin PR no hay run, y sin run no hay evidencia de CI de esta rama. Su rebase sí consigue lo que buscábamos (jobs > 0 cuando exista PR), pero eso queda por verse.
2. Esa evidencia de CI, cuando llegue, **morirá en el paso 7** hasta que aterricen A-06 2a+2b: los dos literales reales siguen ahí y el escáner ahora los ve.
3. No toqué su rama, ni creé ni moví ramas. No verifiqué Railway: fuera de mi alcance por decisión del Dueño.
