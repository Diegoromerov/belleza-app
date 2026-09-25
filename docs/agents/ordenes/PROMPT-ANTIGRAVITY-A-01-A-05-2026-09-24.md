# Órdenes para Antigravity — salidas de la auditoría de `ci.yml` / `.gitignore` / `index.js`

**Origen:** `docs/audit/AUDITORIA-CI-INDEX-GITIGNORE-2026-09-24.md` (procedencia: `fase-a/verdad-operativa` @ `c1069e9f`)
**Regla del sistema:** una orden = una rama = un PR. El reporte de cada orden cita los comandos y sus salidas reales, no resúmenes.

---

# ORDEN A-01 · La compuerta del CI tiene que levantarse sobre base vacía  ⟵ **máxima prioridad**

**GOAL (una frase):** que sobre una base **vacía** la secuencia `prepareRlsDatabase.js` + `verifyTenantIsolation.js` termine con **exit 0** en los dos, de forma determinista, sin tocar `index.js` ni la lógica de negocio.

**Rama:** `fix/rls-056-058-cadena` desde `origin/main` (no desde `fase-a`: son cambios de migración, no de Fase A). Si se decide entregarlo junto a la Fase A, entonces rama propia desde `fase-a/verdad-operativa` y PR a `main`.

### Reproducción que debes ver fallar primero (pegar la salida cruda)

```bash
docker exec beauty-postgres psql -U admin -d postgres -c "DROP DATABASE IF EXISTS glowtest_ci;" -c "CREATE DATABASE glowtest_ci;"
cd backend
NODE_ENV=test DATABASE_URL_ADMIN="postgres://admin:***@127.0.0.1:5435/glowtest_ci" RLS_ROLE_PASSWORD=ci_only_password node scripts/prepareRlsDatabase.js; echo "EXIT=$?"
NODE_ENV=test TEST_DATABASE_URL="postgres://app_owner:ci_only_password@127.0.0.1:5435/glowtest_ci" node scripts/verifyTenantIsolation.js; echo "EXIT=$?"
```

Hoy: `❌ migrations/058_enable_rls_policies.sql: column "tenant_id" does not exist`, `EXIT=1`, y después `password authentication failed for user "app_owner"`, `EXIT=2`.

### Causa raíz confirmada y **re-medida hoy** (2026-09-24, base vacía `glowtest_a01`, código de `fase-a` @ `c1069e9f`)

La versión anterior de esta orden citaba `056:6-9` («cuatro tablas») y hablaba de «otra lista». Las dos cosas caducaron (clase **R-05**). Medido hoy:

- `056_add_tenant_id_to_core_tables.sql:6-16` añade la columna a **once** tablas, no a cuatro.
- `056:7` la añade a **`servicios`** — nombre que **no existe** en el esquema: `ALTER TABLE IF EXISTS` lo convierte en una sentencia vacía y silenciosa.
- `058_enable_rls_policies.sql:9-24` y `:39-54` usan **la misma lista de 14 nombres** en sus dos arrays (`rls_tables` y `policy_tables` son idénticos); el bucle de políticas está en `:57-68` y el `CREATE POLICY … USING (tenant_id = current_setting('app.tenant_id')::int)` en `:61-63`.
- **El culpable, nombrado:** tras `055`, `056` y `057`, la única de esas 14 tablas que **existe sin la columna** es **`services`** ⇒ `CREATE POLICY` sobre ella lanza `column "tenant_id" does not exist`. La columna de `services` llega en **`065_multi_tenant_hardening.sql:74`**, tres migraciones más tarde.
- `admin_mfa`, `platform_config`, `productos` y `servicios` **no existen todavía** en ese punto (el `IF EXISTS`/`information_schema` las salta); las otras ocho tienen la columna.
- Consecuencia medida: **0 políticas** `tenant_isolation*` creadas y los roles de la compuerta nunca se crean ⇒ el paso siguiente no puede ni conectar (`password authentication failed for user "app_owner"`).

### Qué exactamente hay que arreglar

1. **Una sola fuente para la lista de tablas multi-tenant, y que el orden respete las dependencias.** `056` debe cubrir **`services`** (hoy se le escapa: su columna llega en `065`) **o** el bloque de columna de `065:74` debe ejecutarse antes que `058`; y el nombre inexistente `servicios` sale de `056:7`. Con **aserción explícita**: si la lista de `056` y la de `058` divergen, la migración **falla nombrando la tabla** que falta. Prohibido resolverlo con `IF EXISTS` a secas: eso es lo que ya tapó este error.
2. **Idempotencia real** (regla del runner: cada `.sql` se manda en **una** consulta y su error queda como warning; los errores de este camino se comen la compuerta en silencio). La migración debe poder correr dos veces seguidas sobre la misma base sin error ni duplicación de políticas.
3. **La compuerta de roles**: que `app_owner` y `app_rls_user` queden creados con la contraseña de `RLS_ROLE_PASSWORD` **antes** de que algo intente conectarse como ellos, y que `verifyTenantIsolation.js` lo verifique en vez de reventar con un error de autenticación.
4. **Autoverificación**: al terminar, el script imprime una línea por tabla (`tabla → RLS activo, FORCE, nº de políticas`) y **falla** si alguna no tiene exactamente una política de aislamiento.

### Criterios de aceptación (todos falsables, con salida pegada)

| # | Criterio | Cómo se prueba |
|---|---|---|
| C1 | Base vacía ⇒ `prepareRlsDatabase.js` **exit 0** | el bloque de arriba, dos corridas seguidas sobre la misma base |
| C2 | `verifyTenantIsolation.js` **exit 0** tras C1 | el bloque de arriba |
| C3 | Ninguna tabla con política RLS sin `tenant_id`; ninguna tabla multi-tenant sin política | la autoverificación del punto 4 |
| C4 | Doble corrida seguida = sin errores y sin políticas duplicadas | correr C1 dos veces y contar `pg_policies` |
| C5 | Sin tocar `index.js`, sin tocar controllers, sin tocar tests existentes | `git diff --stat` en el reporte |

### Prohibiciones

`IF EXISTS` como arreglo único · `DROP TABLE`/`DROP COLUMN` · tocar `index.js` · desactivar RLS para que pase · `FORCE RLS` sobre tablas sin `tenant_id` · commitear la contraseña de los roles.

---

# ORDEN A-02 · Una métrica de dinero no se inventa

**GOAL:** que `GET /api/admin/metrics` **no** devuelva ingresos ni proyecciones cuando no hay historial suficiente, sino un estado explícito de datos insuficientes.

**Rama:** `fix/admin-metricas-sin-datos` desde `fase-a/verdad-operativa` (o desde `main`, a elección del ejecutor, declarándolo).

### Lo que hay que tocar

`backend/index.js:812-820` (bloque `if (history.length < 3)` con `Math.random()`) y `:840` (`projectedRevenue` por regresión sobre ese historial).

### Criterios de aceptación

| # | Criterio | Cómo se prueba |
|---|---|---|
| C1 | Con 0-2 meses de reservas completadas: `history: []`, `projectedRevenue: null`, y un campo explícito (p. ej. `data_status: 'insuficiente'`) o `503` | test nuevo con base de prueba sin reservas completadas |
| C2 | Con 3+ meses reales: los números salen **solo** de la base (test que compara contra un `SUM` independiente) | el mismo test, con datos sembrados |
| C3 | `Math.random` no aparece en ningún camino de una métrica de dinero | `grep -n Math.random backend/index.js` sin resultados en esas líneas + el test de C1 en rojo si alguien lo reintroduce |
| C4 | Si la capa de datos está degradada, la respuesta lo declara (mismo patrón que `/api/health`: 503 + `X-GlowApp-Degraded`) | test con `getDbStatus().servingFabricatedData === true` |

**Prohibido:** mover el número inventado a un valor «más creíble», o dejar el `Math.random` detrás de `NODE_ENV !== 'production'` — la salida es *decir que no hay datos*, no inventarlos en otro entorno.

---

# ORDEN A-03 · Un router, un prefijo

**GOAL:** que ningún router quede montado dos veces, ni en el mismo prefijo ni en prefijos distintos.

**Rama:** `fix/montajes-duplicados` desde `fase-a/verdad-operativa`.

### Lo medido

17 montajes duplicados en el mismo prefijo (`payment` 388/541, `booking` 389/538, `service` 390/539, `product` 392/540, `provider` 393/537, `vto`, `business`, `salon`, `portfolio`, `metrics`, `mentorship`, `glowPro`, `community`, `color`, `biometric`, `analytics`, `academy`) y 5 routers con dos prefijos vivos: `academyAdminRoutes` (408/543), `eventRoutes` (411/560), `xpLogRoutes` (418/559), `membershipRoutes` (424/546), `adminPreciosRoutes` (409/544 — el router ya incluye `/precios` en sus rutas ⇒ la línea 544 produce `/api/admin/precios/precios`).

### Criterios de aceptación

| # | Criterio | Cómo se prueba |
|---|---|---|
| C1 | Un test enumera los montajes y **falla** si un router aparece dos veces (mismo prefijo o distinto) | `backend/tests/routing.contract.test.js` nuevo, incluido en el paso bloqueante |
| C2 | Se elimina el montaje sobrante de cada duplicado, declarando en el PR **cuál** se conservó y por qué (ninguno de los dos si el prefijo correcto es otro) | lista en el cuerpo del PR |
| C3 | Ninguna ruta final contiene un segmento repetido (`/precios/precios`) | el mismo test, sobre las rutas registradas |
| C4 | El contrato no cambia para lo que el panel ya llama: las rutas que el dashboard usa hoy siguen respondiendo | `smoke:surfaces` + las 2 rutas que ya mira, más las de precios, verificadas a mano con su código de estado |

**Prohibido:** borrar un montaje «que parece duplicado» sin comprobar cuál usa el frontend/admin-dashboard; romper una ruta existente para satisfacer el test.

---

# ORDEN A-05 · Procedencia de las cifras en `ci.yml`

**GOAL:** que ninguna afirmación de resultado viva como comentario sin origen.

- El comentario del paso de tests afirma «mismas 15 suites rojas heredadas, 0 fallos nuevos». O se reemplaza por una remisión a la evidencia (URL del run o comando + fecha), o se elimina.
- El paso bloqueante corre ≈66 de las 80 suites (14 archivos casan patrones excluidos; el patrón `authRoutes` hoy **no excluye nada**: corregirlo o quitarlo, y decir cuál).
- **Bloqueada por A-01**: no se puede medir cuántas suites están rojas hasta que el esquema se levante. No se inventa la cifra mientras tanto.

---

# ESCALADO AL DUEÑO (no lo resuelve un agente) — A-04 / TEC-68

`backend/public/` está en `.gitignore:68` **y** sus 192 archivos están versionados. Consecuencia verificada: cualquier build nuevo entra en el olvido (`git check-ignore --no-index backend/public/<archivo nuevo>` devuelve la regla) ⇒ el bundle desplegado no puede actualizarse por el camino normal. Eso explica el `NO VERIFICADO` de ARQUITECTURA.

**Decisión requerida (una de dos, ambas válidas, ninguna reversible sin costo):**
- **(a) Artefacto commiteado:** quitar la regla del `.gitignore`, documentar el rebuild y añadir una compuerta que compare un hash del build fresco contra lo versionado. Es lo coherente con «el Dockerfile no compila Flutter».
- **(b) Artefacto derivado:** sacar los 192 archivos del índice y compilarlo en el pipeline (exige añadir Flutter al Dockerfile o un job que publique el build).

Hasta que se decida: **nadie toca `backend/public/` a mano**.
