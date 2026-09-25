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

**Origen / re-medido 2026-09-25** sobre `fase-a/verdad-operativa` @ `c1069e9f`. Esta orden citaba `812-820`; hoy el bloque está **`813-822`**, con el `Math.random()` en la **`:819`** y la proyección en la **`:840`** (el endpoint arranca en la **`:725`**). Clase **R-05**: la cita caducó, el defecto no.

**GOAL:** que `GET /api/admin/metrics` **no** devuelva ingresos ni proyecciones cuando no hay historial real — que declare insuficiencia de datos — y que ningún camino de una métrica de dinero pase por azar.

**Rama:** `fix/admin-metricas-sin-datos` **desde `fase-a/verdad-operativa`** (no desde `main`: conserva el `ci.yml` con marcadores y todo PR nacido de ahí sale con 0 jobs — **CI-10**). `main` y `fase-a` difieren en 33 líneas de `index.js`; la base es `fase-a`.

### Lo medido hoy (`backend/index.js` en `fase-a` @ `c1069e9f`)

| Qué | Dónde |
|---|---|
| `app.get('/api/admin/metrics', authMiddleware, adminMiddleware, …)` | `:725` |
| `if (history.length < 3) { … }` — fabrica **5 meses** con `450000 + (4-i)*120000 + Math.floor(Math.random()*60000)` | `:813-822` (el azar, **`:819`**) |
| `projectedRevenue = Math.max(0, Math.round(slope * nextMonthIndex + intercept))` — proyecta **sobre ese historial fabricado** | `:840` |
| Respuesta | `:846+` (`success: true, data: { …, projectedRevenue, … }`) |

El patrón honesto que **ya existe en este mismo archivo** y hay que imitar en vez de inventar: `:220-221` → `if (getDbStatus().servingFabricatedData === true) res.setHeader('X-GlowApp-Degraded', 'memory-fallback')`, y `:429-430` para el estado degradado.

### Qué exactamente hay que arreglar

1. **Con menos de 3 meses reales:** `history: []`, `projectedRevenue: null` y un campo explícito `data_status: 'insuficiente'` (con `meses_con_datos`). **No se inventa ni un mes.**
2. **Con 3+ meses reales:** las cifras salen **solo** de la base y la proyección usa la misma fórmula que hoy, sobre datos reales.
3. **Datos degradados** (`getDbStatus().servingFabricatedData === true` o `pgAvailable === false`): la respuesta **no** es 200 con ceros — es `503` con `X-GlowApp-Degraded`, igual que `/api/health`.
4. **Ningún `Math.random()` en un camino de dinero.** Ojo: el archivo tiene otro en `:119` (`uniqueSuffix` de subidas) que **es legítimo y no se toca**. La compuerta tiene que ser específica, no un `grep` global.
5. **Contrato del panel:** no borres `projectedRevenue`, pásalo a `null`. Medido hoy: `grep -rn "projectedRevenue" admin-dashboard lib` → **0 resultados**; confirma tú quién lo lee antes de cambiar la forma de la respuesta y declara el resultado en el PR.

### Criterios de aceptación (todos falsables, con salida pegada)

| # | Criterio | Cómo se prueba |
|---|---|---|
| C1 | 0-2 meses de reservas `COMPLETADA`: `history: []`, `projectedRevenue: null`, `data_status: 'insuficiente'` | test nuevo con base de prueba sembrada a mano |
| C2 | 3+ meses reales: cada cifra cuadra contra un `SUM` independiente | el mismo test, comparando contra la consulta SQL suelta |
| C3 | Base degradada: **503** + `X-GlowApp-Degraded` (nunca 200 con ceros) | test con `getDbStatus().servingFabricatedData = true` |
| C4 | Reintroducir el azar en ese camino pone el test en rojo | mutación: devuelve la línea de `Math.random` y muestra el fallo |
| C5 | `Math.random()` en `:819` ya no existe y el de `:119` sigue ahí | `grep -n "Math.random" backend/index.js` → solo `:119` |
| C6 | Nada más cambia: la ruta sigue detrás de `authMiddleware` + `adminMiddleware` | `git diff --stat` en el reporte |

**Prohibido:** mover el número inventado a un valor «más creíble» (un seed fijo, un `0`, un promedio) · dejar el `Math.random` detrás de `NODE_ENV !== 'production'` — la salida es **decir que no hay datos**, no inventarlos en otro entorno · devolver `null` sin el campo de estado · tocar `index.js` fuera de esa ruta · usar `main` como base.

---

# ORDEN A-03 · Un router, un prefijo

**Origen / re-medido 2026-09-25** sobre `fase-a/verdad-operativa` @ `c1069e9f` (`backend/index.js`, 1.886 líneas; Express **4.18.2**). La orden vieja decía «17 montajes repetidos **+ 5** routers con dos prefijos»: los 17 se sostienen exactos, los de dos prefijos hoy son **9** (clase **R-05**).

**GOAL:** que cada router se monte **una sola vez** y con **un solo prefijo**, y que ningún path final repita un segmento — **sin cambiar el contrato**: toda ruta que hoy responde debe seguir respondiendo igual.

**Rama:** `fix/montajes-unicos` **desde `fase-a/verdad-operativa`**; el PR apunta a **`main`** (con base `fase-a` no dispara ningún run — CI-10).

### Lo medido hoy

Dos bloques de montaje (`:388-424` y `:532-561`) más la cola (`:1018`, `:1379`).

**1) 17 routers montados dos veces con el MISMO prefijo** (el segundo montaje es inerte; se conserva el primero y se borra el otro): `paymentRoutes 388/541` · `bookingRoutes 389/538` · `serviceRoutes 390/539` · `productRoutes 392/540` · `providerRoutes 393/537` · `salonRoutes 396/533` · `biometricRoutes 400/547` · `vtoRoutes 405/549` · `colorRoutes 406/550` · `academyRoutes 407/542` · `glowProRoutes 410/553` · `analyticsRoutes 413/554` · `metricsRoutes 414/555` · `portfolioRoutes 415/556` · `communityRoutes 416/557` · `mentorshipRoutes 417/558` · `businessRoutes 423/545`.

**2) 9 routers con DOS prefijos distintos** — aquí no decide el gusto, decide el código. Medido, incluida la ruta interna de cada router:

| Router | Montaje A | Montaje B | Ruta interna declarada | Path final de cada uno | Se conserva |
|---|---|---|---|---|---|
| `adminPreciosRoutes` | `:409` `/api/admin` | `:544` `/api/admin/precios` | `'/precios'` | A → `/api/admin/precios` ✓ · B → `/api/admin/precios/precios` ✗ | **A (:409)** |
| `ticketRoutes` | `:394` `/api` | `:551` `/api/tickets` | `'/tickets'` | A → `/api/tickets` ✓ · B → `/api/tickets/tickets` ✗ | **A (:394)** |
| `disputeRoutes` | `:395` `/api` | `:552` `/api/disputes` | `'/disputas'` | A → `/api/disputas` ✓ · B → `/api/disputes/disputas` ✗ | **A (:395)** |
| `academyAdminRoutes` | `:408` `/api/admin/academy` | `:543` `/api/academy/admin` | `'/courses'` | A → `/api/admin/academy/courses` (**11 consumidores**) · B → `/api/academy/admin/courses` (0) | **A (:408)** |
| `eventRoutes` | `:411` `/api/glow-pro/events` | `:560` `/api/events` | `'/'`, `'/:id'` | A → `/api/glow-pro/events` (0) · B → `/api/events` (**4 consumidores**) | **B (:560)** |
| `eventRegistrationRoutes` | `:412` `/api/glow-pro/event-registrations` | `:561` `/api/event-registrations` | `'/events/:id/register'` | ninguno es canónico: el path real es `/api/events/:id/register` ⇒ **montar en `/api`** | `/api` |
| `biometricConsentRoutes` | `:397` `/api/consent` | `:548` `/api/biometric/consent` | `'/biometric'` | A → `/api/consent/biometric` · B → `/api/biometric/consent/biometric` (absurdo) | **A (:397)** |
| `xpLogRoutes` | `:418` `/api/xp-logs` | `:559` `/api/xp-log` | `'/'`, `'/convert-cashback'` | A → `/api/xp-logs/…` · B → `/api/xp-log/…` | **A (:418)**; si un cliente usa el singular, alias **declarado**, no dos montajes |
| `membershipRoutes` | `:424` `/api/v1/memberships` | `:546` `/api/membership` | declaraciones **multilínea** (`membershipRoutes.js:14-32`) | — | **lo decides tú** leyendo esas 3 rutas y buscando consumidores, y lo dices en el reporte |

**La regla que sale de la tabla (es el hallazgo, no un criterio de estilo):** el prefijo **no debe repetir el segmento que el router ya declara** — `adminPreciosRoutes`, `ticketRoutes` y `disputeRoutes` declaran el segmento (`/precios`, `/tickets`, `/disputas`), así que el montaje «largo» produce `/x/x`. Y cuando el router declara rutas **desnudas** (`'/'`, `'/courses'`), el segmento **solo** existe si el prefijo lo pone.

### Evidencia de consumidores que ya tienes medida

`grep -rl <path> lib admin-dashboard` → `/api/admin/academy` = **11** · `/api/events` = **4** · **el resto = 0**. Cuidado: **cero no es muerto**. La app Flutter puede construir la URL sobre una base que ya incluya `/api`; antes de borrar un prefijo con 0 consumidores, busca la base en `lib/` (`baseUrl`, `apiUrl`, `dio.options.baseUrl`) y **repite la búsqueda con el path sin `/api`**. Si aparece algo, se conserva **un** montaje y el otro se declara retirado (o alias explícito) en el PR.

### Criterios de aceptación (todos falsables, con salida pegada)

| # | Criterio | Cómo se prueba |
|---|---|---|
| C1 | **Inventario en runtime**, no lectura del texto: 0 duplicados (mismo par router+prefijo) y 0 paths con segmento repetido | `backend/scripts/listRoutes.js` **ya existe**: míralo, hace la función; pega su salida antes y después |
| C2 | Ninguna ruta con consumidores deja de responder: mismo `status` antes y después en `/api/admin/academy/courses`, `/api/events`, `/api/admin/precios` | dos corridas pegadas (una sobre la rama base, otra sobre la tuya) |
| C3 | El defecto no puede volver: la compuerta **falla** si un router se monta dos veces | **mutación pegada**: añade un `app.use` duplicado y muestra el rojo |
| C4 | El caso concreto queda demostrado: `/api/admin/precios` responde y `/api/admin/precios/precios` da **404** | petición real, con su código de estado |
| C5 | Sin efectos colaterales: solo `index.js` (+ el script/test que añadas); 0 cambios en `lib/`, `admin-dashboard/`, `backend/public/` | `git diff --stat` |

**Prohibido:** renombrar rutas o mover segmentos (`disputeRoutes` declara `/disputas` en español bajo un prefijo `/disputes`: **se declara, no se arregla aquí**) · borrar un prefijo sin haber buscado consumidor en `lib/` y `admin-dashboard` · tocar el catch-all `app.use('/api/*', …)` de `:1379` (Express 4 lo acepta) · reconstruir `backend/public` · «alias» sin declarar en el reporte · base `main`.

---

# ORDEN A-05 · Procedencia de las cifras en `ci.yml`

**Origen / re-medido 2026-09-25** sobre `fase-a/verdad-operativa` @ `c1069e9f`. **Corrección de la orden vieja:** decía «bloqueada por A-01» — solo lo está en una parte. El reparto de suites y la procedencia de cada cifra **se miden hoy**; lo que espera a A-01/A-06 es *cuántas están rojas*. La orden vieja tampoco citaba línea: hoy sí.

**GOAL:** que ninguna cifra de resultado viva sin origen en `ci.yml`, y que el gate diga exactamente qué corre y qué no.

**Rama:** `fix/ci-procedencia` **desde `fase-a/verdad-operativa`**; PR a **`main`** (CI-10).

### Lo medido hoy (`.github/workflows/ci.yml` en `fase-a`)

| Qué | Dónde |
|---|---|
| Comentario `# … mismo resultado con PostgreSQL real que con pg-mem (mismas 15 suites rojas …` | `:91-92` |
| Paso bloqueante: `npm test -- --coverage --testPathIgnorePatterns="geminiService\|geminiFallback\|auraToolExecutor\|contract\|biometric\|resilience\|contextCompressor\|fase5\|authRoutes\|api.cors"` (10 patrones) | `:93-98` |
| Comentario `# Deuda visible, no oculta: las suites excluidas del gate se ejecutan igual` | `:100` |
| Paso **no bloqueante** (`continue-on-error: true`) con `--testPathPattern="…"` (los mismos 10 patrones) | `:102-106` |
| `authRoutes` en todo el archivo | **solo** `:98` y `:106` |
| Colección de suites: `testMatch: ['**/tests/**/*.test.js','**/__tests__/**/*.test.js']` | `backend/jest.config.js:8-10` |
| Suites `.test.js` en el repo | **80** (`git ls-tree -r --name-only <R> \| grep -c '\.test\.js$'`) |

### Qué exactamente hay que arreglar

1. **La cifra `:91-92`**: o se reemplaza por una remisión verificable (URL del run + SHA + fecha) o se elimina. Prohibido dejarla como prosa.
2. **El reparto real de suites**: `npm test -- --listTests` **con** el `--testPathIgnorePatterns` del paso bloqueante y **sin** él; pega **los dos números y los nombres**. El reporte debe decir «N de 80 dentro del gate, M fuera», no «≈66».
3. **Todo patrón que no case con ningún archivo** (medido: `authRoutes` aparece solo en las dos invocaciones, no como nombre de archivo): o se corrige para que excluya lo que dice, o se quita — y se dice cuál de las dos. Vale para los 10 patrones, uno por uno.
4. **El comentario `:100`**: verifica que el paso no bloqueante realmente ejecuta las excluidas (`continue-on-error: true` hace que un rojo no tumbe el run, pero el run debe *correr*) y describe el mecanismo real. Hoy ningún run ha mostrado ese camino funcionando (`jobs=0` por CI-10), así que no lo afirmes sin verlo: si no puedes verlo, escríbelo como **NO VERIFICADO**.
5. **La parte que sigue bloqueada:** cuántas suites están **rojas** no se puede contar hasta que (a) la compuerta de secretos deje de morir en el paso 7 y (b) el esquema se levante. Mientras tanto se escribe `NO MEDIDO — bloqueado por el paso 7` con el enlace al run. **La cifra no se inventa.**

### Criterios de aceptación (todos falsables, con salida pegada)

| # | Criterio | Cómo se prueba |
|---|---|---|
| C1 | Cada cifra del archivo tiene comando o enlace que la produce | `grep -nE '[0-9]+ (suites\|tests\|fallos\|rojas)' .github/workflows/ci.yml` → una línea por cifra con su procedencia |
| C2 | El paso bloqueante declara cuántas suites corre y coincide con la corrida real | salida de `--listTests` con y sin el filtro, pegada |
| C3 | Todo patrón de exclusión casa con ≥1 archivo o se elimina | el mismo listado, patrón por patrón |
| C4 | Los comentarios describen el mecanismo real; lo no visto queda `NO VERIFICADO` | diff del archivo + enlace al run |
| C5 | Cero cambios en el *conjunto* de suites excluidas | `git diff` del archivo: solo comentarios y, si acaso, un patrón corregido (declarado) |

**Prohibido:** poner cifras nuevas sin el comando que las produce · borrar el paso no bloqueante «para simplificar» · cambiar qué suites se excluyen (eso **cambia el gate**: es otra tarea y necesita decisión del Dueño) · medir sobre `main` (su `ci.yml` tiene marcadores de conflicto) · base `main`.

---

# ESCALADO AL DUEÑO (no lo resuelve un agente) — A-04 / TEC-68

`backend/public/` está en `.gitignore:68` **y** sus 192 archivos están versionados. Consecuencia verificada: cualquier build nuevo entra en el olvido (`git check-ignore --no-index backend/public/<archivo nuevo>` devuelve la regla) ⇒ el bundle desplegado no puede actualizarse por el camino normal. Eso explica el `NO VERIFICADO` de ARQUITECTURA.

**Decisión requerida (una de dos, ambas válidas, ninguna reversible sin costo):**
- **(a) Artefacto commiteado:** quitar la regla del `.gitignore`, documentar el rebuild y añadir una compuerta que compare un hash del build fresco contra lo versionado. Es lo coherente con «el Dockerfile no compila Flutter».
- **(b) Artefacto derivado:** sacar los 192 archivos del índice y compilarlo en el pipeline (exige añadir Flutter al Dockerfile o un job que publique el build).

Hasta que se decida: **nadie toca `backend/public/` a mano**.
