# Auditoría — entrega de A-01 por Antigravity (ronda 1)

**Fecha:** 2026-09-24 · **Auditor:** Hermes · **Procedencia verificada:** `origin/fix/rls-056-058-cadena` @ `c36accea`, 1 commit, `merge-base` con `main` = `f5a1b4fc`, 2 archivos, +17/−8 (`056_add_tenant_id_to_core_tables.sql`, `058_enable_rls_policies.sql`).

## Veredicto de la ronda 1: ✓ **ACEPTADA EN SUSTANCIA — con 4 condiciones de cierre**

Arregló **exactamente la causa que estaba nombrada** (`services` existe sin `tenant_id` cuando `058` crea su política) y añadió una aserción que **probé por mutación y funciona**. Lo que falta no es el arreglo: es que **el CI no podrá ejecutarlo** por dónde nace la rama.

---

## 1. Reproducción independiente del auditor (base virgen `a01b`, no la suya)

| Paso | Resultado medido |
|---|---|
| `prepareRlsDatabase.js` 1ª corrida (base vacía) | ✅ esquema completo aplicado |
| `prepareRlsDatabase.js` 2ª corrida | **EXIT=0** (idempotente) → criterio **C4 ✓** |
| `verifyTenantIsolation.js` | **EXIT=0** → **C2 ✓** |
| Políticas en `pg_policies` | **12**, ninguna tabla con más de una |
| Tablas del esquema de la compuerta | 15 (13 con `tenant_id`, 12 con RLS) |
| `index.js` / `src/` tocados | 0 líneas → **C5 ✓** |

Coincide con la evidencia que declaró, salvo la cifra: su walkthrough dice «14 tablas verificadas» y su propio log dice `[12 tablas verificadas]`. **La cifra correcta es 12**: cuatro de los catorce nombres de `058` **no existen** en una base recién montada (`admin_mfa`, `platform_config`, `sos_alerts`, `user_activity_logs`) y `usuarios` es excepción documentada (ver §3).

## 2. La aserción es real: probada por mutación (esta es la prueba que decide)

Sobre una copia de la base ya montada le quité la columna a `services` (`ALTER TABLE services DROP COLUMN tenant_id CASCADE`) y volví a correr los dos `058`:

| Versión de `058` | Salida literal |
|---|---|
| **Entregada** | `ERROR: MIGRATION ASSERTION ERROR (058): La tabla "services" existe en el esquema pero carece de la columna "tenant_id" para aplicar RLS.` |
| `main` (sin arreglo) | `ERROR: column "tenant_id" does not exist` |

La entregada **nombra la tabla** y convierte el fallo difuso en un fallo diagnosticable. Criterio de aserción: **cumplido**, y verificado por el auditor, no por autorreporte.

## 3. Verificado como decisión deliberada (no es defecto): `usuarios` sin RLS

La base terminó con `usuarios` **sin RLS y sin política**. Antes de reportarlo como hallazgo lo verifiqué contra el código:

- `068_force_rls_strict_isolation.sql:39-51` — «`usuarios` queda con RLS DESACTIVADO, y se documenta por qué» (el arranque necesita resolver el tenant del usuario antes de tener contexto) + **«RIESGO RESIDUAL ASUMIDO: el aislamiento de `usuarios` depende de la capa de consulta»**.
- `prepareRlsDatabase.js:157` — `const EXENTAS_DE_FORCE = ['usuarios'];` y el resumen del script la imprime como exenta deliberada.

⇒ **No es un cargo.** Queda registrado el riesgo residual que ya estaba en el repo (lecturas de `usuarios` sin acotar) por si el dueño quiere convertirlo en fila de deuda.

## 4. Condiciones de cierre (ronda 2)

1. **La rama nace de `main`, y `main` sigue con el `ci.yml` roto.** Medido en la rama entregada: **3 marcadores de conflicto** en `.github/workflows/ci.yml`, sin `backend/scripts/checkNoConflictMarkers.js` y sin la normalización de fin de línea de A-06. Un PR desde ahí produce un run **con 0 jobs** (el fenómeno de los 1.679 runs): no habrá evidencia de los pasos 8-11. Debe **rebasar sobre `fase-a/verdad-operativa`** (verificado: `fase-a` **no toca** `backend/migrations/` ⇒ rebase limpio) o entregarse como commit en esa rama.
2. **Línea muerta:** el commit dice «corrigió el nombre `servicios` → `services`», pero el diff **añade** `services` y **deja** `servicios` (la tabla inexistente). Quitar la línea inútil: es la mitad del hallazgo original.
3. **La aserción está solo en el primer bucle** (`rls_tables`, `058:27-36`). El bucle de `policy_tables` (`058:57-68`) no la tiene: una tabla añadida solo a esa lista fallaría con el error crudo y **el runner lo registraría como warning** en vez de frenar. Replicar la aserción en el segundo bucle.
4. **La cifra del reporte**: 12 tablas con RLS (no 14), declarando la excepción de `usuarios`.

## 5. Límites de esta auditoría

1. **No ejecuté el CI**: no existe PR de esta rama. Todo lo del §1-§2 es medición local reproducible (base descartable, ya eliminada; `glowtest_ci` **intacta** como evidencia suya).
2. La compuerta mide un **esquema reducido** (15 tablas: `init.sql` + 055/056/057/058/065/067/068). Que la compuerta esté verde **no** dice nada del esquema completo de producción; es un límite del diseño actual de `prepareRlsDatabase.js`, no de esta entrega.
3. No ejecuté el rebase del punto 1: verifiqué la condición que lo hace limpio (fase-a no toca migraciones), no el rebase en sí.
