# Handoff — panel admin de Belleza App: estado de `main` y reglas para continuar

Fecha: 2026-10-08 · describe el estado de `main` en esa fecha. Los commits del §1 y del §2 son
la referencia; ninguno de ellos es «el tip».

Este documento **no fija el SHA de la punta de `main`**: hacerlo garantiza que quede desactualizado
en cuanto se commitea cualquier cosa — pasó con la primera versión. Cite los commits por lo que
cierran, no por «el tip», o actualice el SHA en el mismo commit que lo mueve.

Para el agente que continúa el trabajo. Dice lo que YA está hecho y desplegado, el estado exacto
del repositorio, las operaciones que destruirían trabajo, y las trampas del entorno que ya
costaron rondas. No hace falta redescubrir nada de esto.

## 1. Lo que ya está hecho en `main` — no rehacer

| Commit | Qué cerró |
|---|---|
| `def5cb58d` | **PQRSF F2** — cinco endpoints `/api/admin/tickets` (bandeja con filtros y paginación, métricas, detalle con hilo, cambio de estado/prioridad, respuesta del operador), todos bajo `requireRol('admin')`, con las dos escrituras auditadas. Cerró huecos de F1: escritores de `resuelto_en`/`cerrado_en`, consumo de `ticketSla.js`, validación de `tipo`/`categoria` al crear (antes 500) y prioridad al crear. |
| `a9b42413d` | **PQRSF F4** — pantalla `/admin/pqrsf` (bandeja, filtros, hilo, cambio de estado/prioridad, respuesta) más lo que la UI exigió del backend: el conteo de la bandeja se renombró a `mensajes_total` (en el detalle `mensajes` es el array del hilo) y se añadió `GET /api/admin/tickets/esquema` para que los desplegables no lleven listas escritas en la pantalla. |
| `4d8c4f397` | Plan PQRSF corregido: F4 marcada HECHA, el SHA de F2 arreglado, y F3 con el alcance real del defecto del correo. |
| `dcd53d62f` | **Seguridad en el portero del panel** — `src/middleware.ts` daba por público cualquier camino con extensión (`/admin/pqrsf.json`, `/prestador/datos.json`…). La decisión pasó a `src/lib/portero.ts` y lo público es una lista explícita. Verificado en producción: esos caminos pasaron de 404 a 307. |
| `e23ae4483` | El guardián de ese atajo estaba sobre-escapeado y no podía fallar; reescrito y probado por mutación. |

## 2. Estado verificado del repositorio

- Cadena en `main`: `def5cb58d` → `a9b42413d` → `4d8c4f397` → `dcd53d62f` → `e23ae4483` → `9494e5027` (este documento).
- El árbol compartido (`C:/beauty-app`) está en `main` y **limpio**: `git status` vacío, sin trabajo sin commitear que un barrido pueda llevarse.
- Producción: backend y panel desplegados; el arreglo del portero comprobado en vivo.
- Suites: panel `npm test` 89/89 (0 fallos); backend `adminTickets.test.js` 29/29, `pqrsfSla.test.js` 19/19, guardián de numeración 7/7; integración contra PostgreSQL real 25/25.
- Respaldo fuera del repositorio: `C:/Users/Compu casa/beauty-app-archive/belleza-app-main.bundle` (autocontenido y verificado).

### Trabajo publicado FUERA de `main` — existe y hay que saberlo

`origin/fix/quality-debt-p0` tiene **9 commits publicados** que `main` no incluye y va por detrás de
`main` (**medí la distancia vos mismo**: `git rev-list --count origin/fix/quality-debt-p0..origin/main`).
Cualquier número escrito aquí queda viejo en cuanto alguien commitea — pasó con «12», que ya era 15. No es trabajo perdido ni ajeno: es deuda de backend resuelta en
otra rama. Quien continúe tiene que conocer que existe antes de tocar el backend.

| Commit | Qué cierra |
|---|---|
| `a8bc11ab7` | Deuda P0 de calidad: fail-closed, RLS, RBAC y arnés de tests |
| `17a676683` | Documenta la causa raíz del botón Atender (valor de enum inválido) |
| `a15bcacd4` | Crash `Cannot read properties of null (reading 'toLocaleString')` en `/productos` |
| `20bc1d1f0` | La página de precios y el catálogo eran el mismo dato desconectado |
| `082aac9e6` | Violación de supresión biométrica, arnés de consent y firma documental |
| `d3755c960` | C7 — los tests de youcam/gemini congelaban datos clínicos simulados |
| `c587f51b8` | C6 — fixtures de embedding de la era 1024 dims (modelo NVIDIA retirado) |
| `d932df4c4` | Los tests anti-IDOR de aislamiento no comprobaban nada (mock ciego) |
| `00253ba9c` | membership-flow asertaba el contrato de validación previo a Zod |

**Dos peligros concretos al integrarla** (medidos, no supuestos):

- **`20bc1d1f0` y `a15bcacd4` son duplicados de trabajo ya en `main`** — comprobado **archivo por
  archivo**, no por el asunto del commit:
  - `20bc1d1f0` (precios/catálogo): **7/7 archivos idénticos** a `origin/main`.
  - `a15bcacd4` (crash `toLocaleString`): sus dos `page.tsx` son **idénticos al commit `ed451d275`
    de `main`** y solo difieren de `origin/main` porque `main` siguió después (`91f36d9ef`, la
    unificación). Su contenido está en `main`.
  Se descartan los dos sin perder nada. **Regla antes de declarar duplicado un commit:** comparar
  contenido, no asunto — `git diff --quiet origin/main <sha> -- <archivo>` por archivo, y si un
  archivo difiere, `git log origin/main -- <archivo>` para ver si `main` ya lo resolvió en otro
  commit. «Difiere de `main`» **no** significa «no está en `main»: `a15bcacd4` difería y su
  contenido ya estaba.
- **Integrarla con rebase, nunca con merge** (un merge no pierde commits, pero reintroduce
  versiones viejas de archivos). El rebase, además, resuelve solo la pregunta de los duplicados:
  lo que ya está aplicado se cae o conflictúa de forma trivial.

## 3. Lo que NO hay que hacer

1. **Nunca `git push --force` a `main`**, ni `rebase`/`amend` de commits ya publicados, ni borrar la rama remota. Es la única forma real de destruir lo hecho; todo lo demás lo rechaza git solo.
2. **No `git add -A` sin leer antes `git status`.** El árbol es compartido: un barrido se lleva trabajo ajeno a un commit con tu mensaje.
3. **No mergear las ramas `agent/*`** (hay ~336, a ~335 commits por detrás de `main`): rebase, no merge.
4. **No reintroducir el atajo por extensión** en el portero ni volver a decidir "lo público" por la extensión del camino. Lo público es LISTA explícita: si hay que servir un archivo nuevo de `public/`, se declara en `ASSETS_PUBLICOS` (hay un test que compara la lista con el directorio real).
5. **No cambiar el vínculo** middleware → `clasificarCamino`: `tests/middleware.test.mjs` lo fija por texto y `tests/middleware-behavior.test.mjs` ejerce la decisión.
6. **No usar credenciales de producción** para reproducir nada.
7. Antes de tocar `src/lib/portero.ts`, `src/middleware.ts` o sus tests: `git fetch` y rebase sobre `origin/main`.
8. **No dejar worktrees registrados** apuntando a directorios temporales: retirarlos con `git worktree remove`; si no, quedan visibles en `git worktree list` para todos los agentes.

## 4. Trampas del entorno ya pagadas

- **Backticks en bash/MSYS son sustitución de comandos**: nunca dentro de `git commit -m` (usar `-F archivo`), ni al escribir código con template literals (cierran la cadena). Verificar con `node --check`.
- **La suite del panel se corre con `npm test`**, que es `node --test "tests/*.test.mjs"`. `node --test tests/` NO corre la suite.
- **No se puede importar `src/middleware.ts` desde una prueba**: importa `next/server` sin extensión y el resolutor de Node no lo carga (el empaquetador de Next sí). Por eso la decisión vive en `src/lib/portero.ts`, sin dependencias.
- **El arnés de jest del backend exige `JWT_SECRET`** (`src/tests/setupHarness.js:12`) aunque la suite que falla hable justo de su ausencia: sin un valor de prueba, las suites ni arrancan y el rojo que se ve es del arnés, no del defecto.
- **El entorno del espacio de trabajo cambia el veredicto del gate.** Tres casos medidos: el arnés exige `JWT_SECRET`; la suite de observabilidad pasa 6/6 sin `DATABASE_URL` y publica 1 contra un Postgres alcanzable (con la variable presente pero **inalcanzable** también pasa: el disparador es una conexión real, no la variable); y `jwtProductionGuard` pasa donde no hay `.env` y falla donde `dotenv` lo encuentra. Regla: **todo número va con su configuración**, y un test que afirma la *ausencia* de una variable de entorno tiene que aislarse del `.env` (mockear `dotenv`) o no prueba nada estable.
- **`taskkill //F` no funciona** en este MSYS: usar `taskkill /F /PID <pid>`.
- **`node_modules` por junction entre árboles**: el worktree `C:/beauty-app-work` tiene `backend/node_modules` como *junction* a `C:\beauty-app\backend\node_modules` (comprobado: `LinkType: Junction`). Un `npm ci` —o un `npm install` con poda— ahí dentro **borra y reinstala el `node_modules` del árbol compartido** a través del enlace, y la caché de jest pasa a ser la misma para los dos árboles. Si hace falta un árbol de dependencias propio, instaladlo dentro del worktree en vez de enlazarlo.
- **`git bundle create f base..tip` y `f tip --not base`** fallan con "Refusing to create empty bundle" aunque el rango no esté vacío; funcionan `^base tip` o un solo ref.
- **No reportar números que no se puedan reproducir.** Un "66/66" circuló y no se pudo reproducir después: exigir 0 fallos y decir con qué orden se corre.

## 5. Qué queda pendiente

### Los rojos del backend, con su reproducción (verificados de primera mano el 2026-10-08)

Siguen rojos en `main` dos de ellos; el tercero no se reproduce acá. **Uno de los dos rojos no es del código** (ver T-A0 abajo):

| Suite | Qué falla | Debe ser |
|---|---|---|
| `src/tests/jwtProductionGuard.test.js` (T-A0) | El import de `index.js` en producción no lanza **cuando existe `backend/.env`**: `dotenv` reintroduce el secreto y deshace el `delete process.env.JWT_SECRET` del test | El test aislado del `.env`. **El fail-fast ya está en `main` y funciona** (prueba A/B abajo) |
| `src/tests/degradedLockBehavior.test.js` (C6) | `/api/products` con la capa de datos degradada responde **500** | **503** + `X-GlowApp-Degraded: memory-fallback` |
| `tests/infra.observability.prometheus.test.js` | Reportado como rojo desde la rama (1 failed / 5 passed) | **En `main` pasa 6/6**, con y sin `NODE_ENV=test` (dos corridas). El rojo **no se reproduce** acá |

Antes de correrlo: **sin `DATABASE_URL` en el entorno** — con una base alcanzable la suite de observabilidad cambia de veredicto.

```bash
cd backend
NODE_ENV=test JWT_SECRET='<valor de prueba, no una credencial>' \
  npx jest src/tests/degradedLockBehavior.test.js src/tests/jwtProductionGuard.test.js \
           tests/infra.observability.prometheus.test.js --runInBand --forceExit
```

Corrida real de ese comando: `Tests: 2 failed, 18 passed, 20 total` — los dos fallos son las dos
primeras filas de la tabla, y **`prometheus` pasó**.

Sobre `prometheus`: en `main` **pasa las 6 pruebas**, medido dos veces, con y sin `NODE_ENV=test`,
así que el rojo reportado desde `fix/quality-debt-p0` **no se reproduce en `main`**. No hay base
para decir «es la métrica» ni «es el orden de ejecución»: para cerrarlo falta el dato que no trae
esa reproducción — **en qué árbol y en qué commit se midió, y qué variables de entorno estaban
puestas** (los nombres, no los valores). Mientras tanto, en `main` está verde.

**T-A0 no es un rojo del código: es un rojo del test.** Medido de primera mano el 2026-10-09, mismo `require`, mismo `NODE_ENV=production`, sin `JWT_SECRET`:

| Dónde se corre | Resultado |
|---|---|
| cwd `backend/` (ahí vive el `.env`) | **No lanza**: `dotenv` (línea 9 de `index.js`) reintroduce el secreto de 53 caracteres del `.env` antes de que `getJwtSecret()` valide |
| cwd `backend/src/tests/` (sin `.env` a la vista) | **Lanza** `[FATAL SECURITY ERROR] … JWT_SECRET es obligatoria` |

El fail-fast existe y hace lo suyo (`index.js:15` → `src/config/jwt.js:19-20`); en producción real —sin `.env`, con las variables del proveedor— se comporta bien. Lo que no sirve es el guardián: en un espacio de trabajo con `.env` no puede pasar, así que no protege nada. **El arreglo es aislar ese test del `.env`** (mockear `dotenv` o apuntar su `config()` a una ruta inexistente), no tocar `index.js`.

Y cuidado con el atajo: **`fix/t-a0-jwt-hardening` (`5becf6798`) ya es ancestro de `main`** (0 commits fuera de `main`, `git merge-base --is-ancestor` lo confirma), así que ese trabajo ya está integrado y no hay nada que rescatar de ahí. La lección original sigue en pie —mirar ramas locales y todos los remotos antes de declarar que algo no existe— pero en este caso lo que faltaba no era lo que parecía.

### Hay dos «C6», y una rama que conviene leer antes de escribir

El rojo que este documento llama **C6** es `src/tests/degradedLockBehavior.test.js`: `/api/products` con la capa de datos degradada responde **500** y debe responder **503 + `X-GlowApp-Degraded`**. El commit `401f6a146` de la rama se llama igual («C6 — fixtures de embedding de la era 1024 dims») pero arregla otra cosa: fixtures de RAG en `ragService*.test.js`. Su tip **no toca** `degradedLockBehavior.test.js` ni `degradedLock.js`, así que ese rojo sigue en pie. **Al dar un rojo por cerrado, nombrad el archivo de la suite, no la etiqueta.**

Antes de escribir el arreglo de C6, mirad `fix/d01-db-fallback-security-audit` (`1ebab7791`, worktree `C:/d01-work`): toca `backend/src/config/db.js` (+35/−7) y añade `src/tests/dbMemorySecurityGuard.test.js`. Es el mismo asunto —la política de fallo de la base—, está 1 commit adelante de `main` y **82 atrás**, o sea que necesita rebase. Por el asunto no se puede saber si coincide con lo que pide C6 o si lo contradice: hay que leerlo antes de escribir nada nuevo.

### El 500 de `/api/products`, medido (C6): no es de `db.js` ni del candado

Capturado de primera mano en `main`, configuración canónica (`NODE_ENV=test`, `JWT_SECRET` de prueba, **sin** `DATABASE_URL`): de los 4 casos de `src/tests/degradedLockBehavior.test.js` falla **uno**, la línea 19.

```
expect(res.status).toBe(503)   →   Expected: 503   Received: 500
```

El 500 sale de `src/controllers/productController.js:59` (`res.status(500).json({ error: 'Error al obtener productos' })`), disparado por **pg-mem**: `ColumnNotFound: column "p.descripcion" does not exist`. La consulta de `productController.js:13` pide `p.descripcion, p.imagen_url, p.tag_especialidad, p.tipo_visibilidad`, y **la tabla `productos` del esquema en memoria (`src/config/pgMemory.js:251-258`) no tiene ninguna de esas cuatro** — solo `id, nombre, sku, costo, stock, tenant_id`. En el esquema real existen (`migrations/009_create_productos_table.sql:5`). Es decir: **hay tres definiciones distintas de `productos`** (migraciones reales, `init.sql:202`, `pgMemory.js:251`) y la que usan las pruebas es la más desviada.

El candado **no lo bloqueó porque su propia regla lo libera**: con `memoryFallbackAllowed: true` y `NODE_ENV !== 'production'`, `decidirBloqueo` devuelve `shouldBlock: false` (`degradedLock.js:264`) y `normalizarEstadoDependencias` no marca la base como degradada (`degradedLock.js:138-144`). Los otros tres casos pasan porque `/api/health` y `/api/providers` están en la allowlist (`degradedLock.js:60-64`) y **declaran la degradación por su cuenta**.

Consecuencias, en orden:

1. **El arreglo no pertenece a `fix/d01-db-fallback-security-audit`** (no es `config/db.js`) ni es un mapeo de error a 503. Cualquiera que “arregle” `productController.js` para contentar al test estaría adaptando código de producción a un esquema que no existe: eso no se hace.
2. **Es una decisión de producto, no un parche.** El test declara que una superficie de datos debe dar 503 aunque la política permita memoria; el candado dice lo contrario en test/dev. O la superficie se endurece (`/api/products` declara la degradación como health y providers), o se quita `memoryFallbackAllowed` de la condición que libera, o se acepta que el test mide una condición que el código no tiene.
3. **Aparte, y mecánico:** sincronizar el esquema en memoria con el real —o derivarlo de las migraciones—. Mientras `pgMemory.js` sea una copia a mano, toda prueba que toque `productos` está midiendo un esquema que no existe.




### El resto

- **F3 — correo.** Bloqueado por un dato que solo se ve fuera del repositorio: hay que comprobar si el servicio `belleza-app` tiene proveedor de correo en su entorno. Sin proveedor, `email.service.js` simula y devuelve `success:true` — y eso afecta también la **recuperación de contraseña**, no solo PQRSF, así que el arreglo puede no pertenecer a la fase de PQRSF.
- **D3 — festivos.** La fecha límite de ARCO se calcula en días hábiles **sin festivos colombianos** y ya se muestra en la bandeja.
- **F5** — métricas de PQRSF en el dashboard raíz. **F6** — costura para el agente.
- **`/api/categorias` no existe** y `admin/productos/page.tsx` la llama; `categoria_id` es un fantasma en cinco sitios y la taxonomía real es `tag_especialidad`.
- Documentados y sin arreglar: `sanitizeText` hace doble escape en `business/page.tsx` y `cliente/page.tsx`; falta pgvector en la base de producción (las migraciones 035 y 076 no aplican).

## 6. La regla de verificación que se exige aquí

Cada cambio se entrega con el defecto **reproducido antes** de tocar nada, el arreglo, la
comprobación **en vivo** (no solo en local) y una **mutación** que pruebe que el guardián lo caza:
volver a introducir el defecto y exigir rojo. Todo con evidencia `archivo:línea` o salida de
comando. Un verde no prueba nada si el guardián no puede fallar.

El gate del backend tiene **dos runners**: jest para los `*.test.js` y `node --test` para los `*.nodetest.js` (la rama añade el script `test:node` para el segundo). Mientras ese script no esté en `main`, cada número tiene que decir **con cuál de los dos y con qué patrón** se midió.

**El gate del backend son tres pasos de la CI, no uno** (`.github/workflows/ci.yml`): (1) el gate con cobertura, `npm test -- --coverage --testPathIgnorePatterns="geminiService|geminiFallback|auraToolExecutor|contract|biometric|resilience|contextCompressor|fase5|api.cors"` (línea 171); (2) el conjunto complementario, `npm test -- --forceExit --testPathPattern="<las mismas 9>"` (línea 203); (3) los dos de contrato, aparte y con `--runInBand` (línea 108). Las nueve familias **no son una invención de nadie**: son las de la línea 171, y por eso son citables.

Medido hoy en `main` con `npx jest --listTests`: **148 suites coleccionadas** — el propio comentario de la CI (línea 158) dice 92 y quedó viejo —, **127 en el gate** y **24 en el complementario**. No son complementarios exactos: **3 suites corren en los dos pasos** (`reencryptBiometricData.test.js`, `deleteBiometricDataHttpStatus.test.js`, `deleteBiometricDataRealDeletion.test.js`) porque el patrón de exclusión distingue mayúsculas y esas tres llevan «Biometric» con mayúscula, mientras que `--testPathPattern` no las distingue. Comprobado: 21 coincidencias sensibles a mayúsculas contra 24 insensibles, y 127 + 24 − 3 = 148.

Consecuencia práctica: cualquier número del backend tiene que decir **cuál de los tres pasos**, con qué patrón y en qué árbol; y nadie debería sumar los dos pasos como si fueran disjuntos.


## 7. Protocolo para trabajar en paralelo sin pisarse

Dos agentes trabajan sobre el mismo repositorio. Estas reglas son para el que continúa; el otro
lado cumple las mismas. No son cortesía: cada una evita un daño concreto que ya ocurrió o que está
a un comando de distancia.

### Antes de escribir una línea

```bash
cd C:/beauty-app
git fetch origin
git status --short        # si hay algo sucio que no es tuyo, PARA y avisa
git log --oneline -1 origin/main
```

- Si sigues tu rama: **`git rebase origin/main`**, nunca `merge`.
- Si vas a tocar `main`: mira qué commits hay encima antes de commitear.

### Trabaja en tu propio worktree, no en el árbol compartido

```bash
git worktree add --detach "C:/tu-work" origin/main
```

`C:/beauty-app` es de los dos: ahí se LEE el estado, no se trabaja. En tu worktree no hay forma de
pisar a nadie.

### Al commitear

- `git status --short` **primero**, y `git add` con **rutas explícitas**: nunca `-A`. Un barrido se
  lleva el trabajo sin commitear del otro a un commit con tu mensaje.
- Prefijo por área (`fix(backend):`, `test(backend):`, `docs(agents):`) para que el log diga de
  quién es cada cosa.
- **Push a tu rama, no a `main`.** Si algo tiene que llegar a `main`: cherry-pick o PR, y avisa en
  el mismo mensaje.

### Nunca

- `git push --force` a `main`, `rebase`/`amend` de commits ya publicados, ni borrar la rama remota:
  es la única forma real de destruir trabajo ajeno.
- `git reset --hard` ni `checkout -f` en el árbol compartido.
- Merge de las ramas `agent/*` (hay ~336, a ~335 commits por detrás): rebase.
- Dejar worktrees registrados apuntando a directorios temporales: `git worktree remove`.

### Tu rama `fix/quality-debt-p0`, al integrarla

1. **`git rebase origin/main` primero**, y **medí vos mismo la distancia**
   (`git rev-list --count origin/fix/quality-debt-p0..origin/main`): un número escrito en un
   documento queda viejo con el siguiente commit.
2. **`20bc1d1f0` y `a15bcacd4` son duplicados** de trabajo ya en `main`, comprobado archivo por
   archivo — `20bc1d1f0` con 7/7 idénticos, y los dos `page.tsx` de `a15bcacd4` idénticos al commit
   `ed451d275` de `main`. **Antes de declarar duplicado un commit, comparad contenido y no asunto**:
   `git diff --quiet origin/main <sha> -- <archivo>` y, si difiere, `git log origin/main -- <archivo>`.
   «Difiere de `main`» no es «no está en `main`»: `a15bcacd4` difería y su contenido ya estaba.
3. Después del rebase, el gate entero (panel `npm test` y la suite del backend) con **0 fallos**.

### El documento de coordinación

`docs/agents/HANDOFF-panel-admin.md` lo leen los dos. **`git fetch` antes de editarlo**, y las
correcciones de §2 y §5 ya están aplicadas: no las repitas.

### Tus pendientes del backend, con las trampas ya pagadas

- **T-A0**: importar `index.js` con `NODE_ENV=production` **sin** `JWT_SECRET` no lanza; debe lanzar `/FATAL SECURITY ERROR/i`.
- **C6**: `/api/products` con la capa de datos degradada responde **500**; debe ser **503** + `X-GlowApp-Degraded`.
- **prometheus**: en `main` **pasa 6/6**, con y sin `NODE_ENV=test` (dos corridas). Si lo ves rojo,
  el dato que falta es **en qué árbol y commit lo mediste y qué variables de entorno tenías puestas**
  (nombres, no valores). No concluyas que la métrica está mal —ni que está bien— sin eso.

- **El arnés exige `JWT_SECRET`** aunque la suite hable de su ausencia: sin un valor de prueba las suites ni arrancan, y el rojo que se ve es del arnés, no del defecto.
- **Hay trabajo sobre T-A0**: rama **local** `fix/t-a0-jwt-hardening` (commit `5becf6798`,
  «implement T-A0 JWT hardening, fail-fast startup…») y, en el remoto `upstream`,
  `fix/jwt-sin-respaldo`. **Mirá ramas locales y otros remotos, no solo `origin`.**

```bash
cd backend
NODE_ENV=test JWT_SECRET='<valor de prueba, no una credencial>' \
  npx jest src/tests/degradedLockBehavior.test.js src/tests/jwtProductionGuard.test.js \
           tests/infra.observability.prometheus.test.js --runInBand --forceExit
```

### Cómo se entrega aquí

Defecto **reproducido antes** de tocar nada, verificado **en vivo** (no solo en local) y una
**mutación** que pruebe que el guardián lo caza: se vuelve a introducir el defecto y el guardián
tiene que ponerse rojo. Evidencia `archivo:línea` o salida de comando. Un verde no prueba nada si el
guardián no puede fallar.
