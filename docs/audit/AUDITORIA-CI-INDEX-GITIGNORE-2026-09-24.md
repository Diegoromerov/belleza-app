# Auditoría — `ci.yml`, `.gitignore` y `backend/index.js` (entrega de archivos del Dueño)

**Fecha:** 2026-09-24 · **Auditor:** Hermes (Arquitecto/Auditor) · **Procedencia auditada:** rama `fase-a/verdad-operativa` @ `c1069e9f`, árbol limpio (`git status --porcelain` = 0 entradas). El `index.js` pegado trae **14** montajes `app.use('/api', …)` y coincide con esa rama (en la copia de trabajo hay 9). **Nada de esto se declara cerrado sin la evidencia de abajo, y ninguna línea se cita de memoria: todas se leyeron del árbol.**

---

## Hallazgo principal (A-01) — la compuerta nueva del CI **no puede pasar**: muere en el esquema multi-tenant

No es una opinión: se reprodujo. Con una base **descartable y vacía** (`glowtest_ci` en el contenedor local, PostgreSQL 16.15 — el runner usa `postgis/postgis:16-3.4`, también 16) y las mismas variables que el job:

```
NODE_ENV=test DATABASE_URL_ADMIN=postgres://admin:***@127.0.0.1:5435/glowtest_ci \
RLS_ROLE_PASSWORD=ci_only_password node scripts/prepareRlsDatabase.js
   📦 Base vacía: se aplica el esquema completo (init.sql incluido).
      ✅ init.sql
      ✅ migrations/055_create_tenants_table.sql
      ✅ migrations/056_add_tenant_id_to_core_tables.sql
      ✅ migrations/057_backfill_tenant_id.sql
      ❌ migrations/058_enable_rls_policies.sql: column "tenant_id" does not exist
   >>> EXIT=1
```

Y el paso siguiente del job, la compuerta de aislamiento, no llega ni a conectar:

```
NODE_ENV=test TEST_DATABASE_URL=postgres://app_owner:ci_only_password@127.0.0.1:5435/glowtest_ci \
node scripts/verifyTenantIsolation.js
   ❌ No se pudo conectar a la base de datos: password authentication failed for user "app_owner"
   >>> EXIT=2
```

**Causa raíz (medida en el código, no inferida):** la lista de tablas de `058` no coincide con la de `056`.

- `056_add_tenant_id_to_core_tables.sql` añade `tenant_id` **a cuatro tablas**: `usuarios`, `servicios`, `bookings`, `transactions` (líneas 6-9).
- `058_enable_rls_policies.sql` **recorre una lista de tablas** y por cada una hace `ALTER TABLE … ENABLE ROW LEVEL SECURITY` y `CREATE POLICY … USING (tenant_id = current_setting('app.tenant_id')::int)` (líneas 30 y 61-63). PostgreSQL rechaza la política si la tabla no tiene la columna ⇒ `column "tenant_id" does not exist`.

**Es determinista, no flaky:** se reprodujo en los dos modos del script (base vacía → `init.sql` + migraciones; base ya inicializada → solo idempotentes) y siempre en el mismo punto. `schema_migrations` no existe en este camino (`prepareRlsDatabase.js` no registra aplicadas), así que en un runner nuevo el resultado es el mismo **cada** vez.

**Consecuencia operativa, que es lo que importa para la decisión D-001:** el primer run de CI de la historia del repo **saldrá ROJO en el segundo paso**, antes de ejecutar un solo test, y por una causa que **no** son los criterios de la Fase A. El arreglo del CI funciona: detectó una rotura real y preexistente de la cadena de migraciones. Pero mientras no se arregle, el PR de Fase A exhibirá una X que no dice nada sobre S1/S2/S3/S4.

**Criterio de aceptación (falsable):** sobre base vacía, `prepareRlsDatabase.js` (exit 0) + `verifyTenantIsolation.js` (exit 0) + los datos de prueba RLS pasan; y el SQL de `058` **deriva** su lista de tablas de las que realmente tienen `tenant_id` (o `056` se amplía a la lista de `058` con su FK a `tenants`), con una aserción explícita que falle si las dos listas divergen.

---

## A-02 — El panel de administración **fabrica ingresos** y proyecta una tendencia sobre datos inventados

`GET /api/admin/metrics` (`backend/index.js:812-840`):

```js
// Fallback dinámico si no hay historial suficiente en desarrollo local/staging
if (history.length < 3) {
  ...
  const simRevenue = 450000 + (4 - i) * 120000 + Math.floor(Math.random() * 60000);
  history.push({ month: monthStr, revenue: simRevenue });
}
...
const projectedRevenue = Math.max(0, Math.round(slope * nextMonthIndex + intercept));
```

Tres cosas medidas:
1. **No hay comprobación de entorno.** El comentario dice «desarrollo local/staging», pero la única condición es `history.length < 3`. En producción, un negocio con menos de 3 meses de reservas completadas recibe **cinco meses de ingresos aleatorios** y una proyección del mes siguiente derivada de ellos, con `trend: 'CRECIENTE' | 'DECRECIENTE'` y `success: true`.
2. **No lleva bandera de degradación.** La app ya sabe hacerlo bien: `/api/health` responde 503 `DEGRADED` + `X-GlowApp-Degraded: memory-fallback`. Esta superficie devuelve 200 y datos simulados **sin marcar**.
3. **Sobrevive a la Fase A.** Es exactamente la clase de defecto que S1 persigue («ninguna superficie 2xx si su consulta falló»), y la entrega de `c1069e9f` no lo tocó: sigue en el árbol auditado.

**Criterio de aceptación:** con menos de 3 meses de historial, la respuesta lleva `history: []`, `projectedRevenue: null` y un campo explícito de datos insuficientes (o 503); y un test falla si aparece `Math.random` en el camino de una métrica de dinero.

---

## A-03 — Superficies duplicadas: 17 montajes muertos y 5 routers con **dos prefijos** (uno de ellos con prefijo absurdo)

Medido con `grep -nE "^app\.use\(" backend/index.js`:

| Clase | Cuántos | Evidencia |
|---|---|---|
| Routers montados **dos veces en el mismo prefijo** (el segundo es inerte) | 17 | `payment` 388 y 541 · `booking` 389 y 538 · `service` 390 y 539 · `product` 392 y 540 · `provider` 393 y 537 · `vto` · `business` · `salon` · `portfolio` · `metrics` · `mentorship` · `glowPro` · `community` · `color` · `biometric` · `analytics` · `academy` |
| Routers montados en **dos prefijos distintos** (las dos superficies están vivas) | 5 | `academyAdminRoutes` 408 `/api/admin/academy` + 543 `/api/academy/admin` · `eventRoutes` 411 `/api/glow-pro/events` + 560 `/api/events` · `xpLogRoutes` 418 `/api/xp-logs` + 559 `/api/xp-log` · `membershipRoutes` 424 `/api/v1/memberships` + 546 `/api/membership` · `adminPreciosRoutes` 409 `/api/admin` + 544 `/api/admin/precios` |

El caso peor es el de precios, porque el propio router ya incluye `/precios` en sus rutas (`src/routes/adminPreciosRoutes.js:25-30`: `/precios`, `/precios/coherencia`, `/precios/historial`, `/precios/export.csv`, `/precios/import.csv`, `/precios/:productoId`). Así que:
- línea 409 → `/api/admin/precios` ✅ (la superficie correcta)
- línea 544 → `/api/admin/precios/precios`, `/api/admin/precios/precios/coherencia`, … ❌ **superficie absurda**, sin test y sin dueño.

Nadie lo nota porque no hay ninguna prueba que enumere los montajes: `smokeSurfaces.js` mira dos rutas fijas.

**Criterio de aceptación:** un test que enumere los montajes y falle si un router aparece dos veces; un prefijo por router; y ningún camino con segmento repetido.

---

## A-04 — El bundle de Flutter está **congelado por su propia regla de ignore** (refina TEC-68)

TEC-68 dice: «`backend/public/` está trackeado … criterio: `backend/public/` fuera del índice y en `.gitignore`». Medido hoy:

```
.gitignore:68:backend/public/
git check-ignore -v --no-index backend/public/main.dart.js        → .gitignore:68
git check-ignore -v --no-index backend/public/NADA_NUEVO.js       → .gitignore:68
git ls-files backend/public | wc -l                               → 192
```

**La regla ya existe y los 192 archivos siguen versionados**: la mitad del criterio de TEC-68 se cumplió (la regla) y la otra no (sacar del índice). Y eso produce un efecto peor que el original: como la regla está activa, **cualquier archivo nuevo que produzca un rebuild entra en el olvido** — `git add -A` lo ignora en silencio, mientras los 192 viejos siguen ahí. Es el mecanismo que explica el `NO VERIFICADO` de ARQUITECTURA («¿`backend/public` corresponde al HEAD de frontend?»): el artefacto no *puede* actualizarse por el camino normal.

**Criterio de aceptación:** decidir y declarar una de las dos, y verificarlo con un comando, no con una intención:
- **(a) artefacto commiteado** → quitar `backend/public/` de `.gitignore`, documentar el procedimiento de rebuild y añadir una compuerta que compare un hash del build contra lo versionado; o
- **(b) derivado** → sacar los 192 archivos del índice y construirlo en el pipeline.

Mientras no se decida: prohibido tocar `backend/public/` a mano.

---

## A-05 — La cifra «15 suites rojas heredadas, 0 fallos nuevos» del comentario de `ci.yml` no tiene procedencia en el archivo

El comentario afirma un resultado medido y no dice dónde. Además, la aritmética del gate, medida hoy:

- suites `.test.js` fuera de `node_modules`: **80**
- archivos que casan alguno de los 10 patrones excluidos: **14** (biometric 5, resilience 3, y 1 por cada uno de los otros ocho; `authRoutes` **0**, o sea que ese patrón no excluye nada hoy)
- ⇒ el paso bloqueante corre ≈66 suites.

**No pude re-medir los rojos** — y eso es el hallazgo: la secuencia del job muere antes, en A-01. Cualquier número que se afirme hoy sobre «cuántas suites rojas» carece de procedencia hasta que el esquema se levante.

**Criterio de aceptación:** el reporte de la entrega cita la URL del run y el número de suites rojas sale del propio run (o de una corrida local declarada con su comando), nunca de un comentario.

---

## Retracciones y límites de esta auditoría (para que nadie la cite de más)

1. **No ejecuté el run de CI.** Simulé su secuencia localmente contra **una base descartable** (`glowtest_ci`, ya se elimina), con PostgreSQL 16.15 y el usuario `admin` del contenedor local, no con `postgis/postgis:16-3.4` ni con el usuario `postgres` del runner. La migración es el mismo SQL del repo y falló en los dos modos del script ⇒ la conclusión sobre A-01 se sostiene; lo que **no** afirmo es el resto de pasos del job (tests, cobertura).
2. **No medí** cuántas de las 80 suites están rojas en esta rama: lo impide A-01. Las cifras de rondas anteriores (15 rojas) siguen sin verificar por mí.
3. **No toqué `beauty_db`**: la simulación usó una base nueva en el mismo contenedor. No modifiqué código, ni migraciones, ni `index.js`.
4. Los `.gitignore` que pegaste aparecen dos veces (idénticos): el del repo y el de `backend/`; la regla relevante (`backend/public/`) está en el **raíz**, línea 68.
5. `adminRoutes` sólo define `/disputes` y `/disputes/:id/resolve`, así que **no** hay colisión real con `adminPreciosRoutes`; lo de A-03 es superficie duplicada, no shadowing de handlers.

## Prioridad que propongo

1. **A-01** — sin esto no hay compuerta: cualquier PR sale rojo por una causa que no es la suya, y el sistema no puede vigilar nada. **Bloquea la utilidad de D-001, no su apertura.**
2. **A-02** — dinero inventado en un panel de administración, en producción y sin bandera. Un dueño que decide sobre ingresos ficticios es el peor caso de esta app.
3. **A-04** — el artefacto desplegado no puede actualizarse; explica un `NO VERIFICADO` abierto y congela el frontend en producción.
4. **A-03** — contrato de API duplicado; barato de cerrar y evita sorpresas en el panel.
5. **A-05** — disciplina de evidencia; se cierra sola cuando A-01 deje correr el job.
