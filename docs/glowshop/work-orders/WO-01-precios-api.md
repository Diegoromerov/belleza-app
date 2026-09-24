# WORK ORDER 1/4 — El precio deja de ser columna del producto: resolutor único + API de precios

> Pega todo este bloque en Antigravity. Es autocontenido: no depende de ninguna conversación previa.

---

## ROL

Eres el agente implementador del monorepo **belleza-app** (Flutter + Node/Express + Next + FastAPI). Tu tarea es **una**: construir el **servicio único de precios por nivel** y la **API de administración de precios** que consume el modelo ya migrado. No abras otros frentes: hay otros tres trabajos en curso (importación CSV, lectura de la tienda, autorización del catálogo) y no te toca ninguno.

## CONTEXTO — medido, no supuesto

**Lo que ya existe en la base (rama `feat/glowshop-niveles-a0`, migraciones ya aplicadas):**

- `backend/migrations/071_glowshop_niveles_a0.sql` — creó y pobló:
  - `listas_precios(id, codigo, nombre, rol_destino, incluye_iva, vigente_desde, vigente_hasta, estado, tenant_id)`. Tres filas con `codigo` = `'cliente'` (`rol_destino='client'`, IVA incluido), `'profesional'` (`'provider'`, IVA discriminado), `'negocio'` (`'salon'`, IVA discriminado). Todas del tenant de plataforma.
  - `precios_producto(lista_id, producto_id, precio, unidad_minima, vigente_desde, vigente_hasta, tenant_id)` con PK `(lista_id, producto_id)`. `unidad_minima` = **1** en cliente y profesional, **6** en negocio (mínimo de venta **solo** para salones — decisión del usuario). Se sembraron **296 precios de consumidor**; **profesional y negocio están VACÍOS a propósito**: se cargan a mano.
  - `precios_historial(lista_id, producto_id, precio_anterior, precio_nuevo, actor_id, origen, motivo, creado_en, tenant_id)` con `origen IN ('manual','bulk_porcentaje','bulk_fijar','import_csv','migracion')`.
  - Trigger `trg_precio_tenant` (`app_precio_tenant_id()`, `SECURITY DEFINER`): **el `tenant_id` de un precio sale siempre de su lista**, nunca de lo que mande el cliente.
  - Función `app_platform_tenant_id()` — devuelve el id del tenant de plataforma. **Nunca hardcodees ese id** (localmente es 9, en otro entorno será otro).
  - Políticas RLS activas y **forzadas**: `productos` (`productos_lectura/alta/edicion/borrado`) y `listas_precios`, `precios_producto`, `precios_historial` (`precios_lectura/escritura/edicion/borrado`). Regla: **leer = lo mío + lo de plataforma · escribir = solo lo mío**. El administrador pertenece al tenant de plataforma, así que edita el catálogo global por esta misma vía, **sin `BYPASSRLS`**.
  - `productos.costo NUMERIC(10,2)` (nullable, con `CHECK >= 0`) y `productos.sku VARCHAR(40)`; `productos.tenant_id` es **NOT NULL**.

**El contrato que debes implementar ya está escrito y congelado**: `docs/glowshop/CONTRATO_PRECIOS_API_Y_CSV.md` (§3.1 a §3.3 y §3.6). Léelo primero. Las reglas normativas están en `docs/glowshop/LINEAMIENTOS_GLOWSHOP.md` (cita el número de lineamiento en el PR; te afectan **L2, L8, L9, L20, L25, L26, L27**).

**Lo que NO debes romper:**

- `backend/src/config/db.js:597-655` — el `pool` exportado es un **wrapper**: si la petición tiene conexión dedicada (`backend/src/middleware/tenantContext.js:73` la abre con `runInTenantTransaction`), tus consultas se enrutan a ESA conexión sin cambiar nada. No crees un segundo pool ni importes `Pool` de `pg`.
- `backend/src/config/tenantRouting.js:86-131` — `runInTenantTransaction` fija el contexto con `set_config(..., true)` (local a la transacción). No uses `set_config(..., false)`: se filtra entre peticiones que reutilizan conexión del pool.
- `backend/src/middleware/auth.js:44-58` — deja en `req.user`: `role` (API: `client|provider|salon|admin`), `rol` (BD: `CLIENTE|PRESTADOR|SALON|ADMIN`) y `tenant_id`. El enum `tipo_rol` **ya admite los 4 valores** (migración 070).

**Aviso crítico sobre los tests**: con `NODE_ENV=test` y sin `DATABASE_URL`, `backend/src/config/db.js:557` fuerza **modo memoria**: las suites de jest NO tocan PostgreSQL. Por eso: los tests de jest deben usar dobles del `pool` (nunca una base real), y la comprobación contra la base se hace con el **guardián** (script aparte, punto 6).

Base de tests medida hace tiempo en `cfa99da3`: **73 rojos / 574**. `main` ya avanzó a `7ad01a0f` y esa cifra puede estar vencida: **mídela tú** en tu punto de partida y repórtala; compara **por nombre de test**, no por conteo.

## ALCANCE

### A. Crear

1. **`backend/src/services/precioService.js`** — la **única** función que calcula precios:

   ```
   resolverPrecio({ rol, tenantId, productoId, cantidad })
     → { lista, precio, unidad_minima, incluye_iva }        // camino feliz
     → { estado: 'sin_precio', lista, unidad_minima }        // honesto: no hay precio cargado
   ```
   Reglas:
   - La lista se elige por el **rol** del comprador (`client`→`cliente`, `provider`→`profesional`, `salon`→`negocio`), tomando la lista **vigente** del tenant de plataforma (o la del propio tenant si algún día existe).
   - Si `cantidad < unidad_minima` → error de negocio tipado (p. ej. `MINIMO_NO_CUMPLIDO` con `unidad_minima` y `lista` en el detalle). El mínimo **solo** existe en `negocio`.
   - Si no hay fila en `precios_producto` → **`sin_precio`**. **NUNCA** caigas a las columnas heredadas, ni a un porcentaje, ni a un valor por defecto.
   - Sin `BYPASSRLS` y sin `SET ROLE`.

2. **`backend/src/middleware/roles.js`** — `requireRol(...roles)` que responde **403** y se apoya en `req.user.role`. Un solo portero, reutilizable: no repitas `role !== 'admin'` a mano (hoy hay 19 comparaciones sueltas de `admin` y 8 de `provider`; este archivo no las arregla, pero no añadas más).

3. **`backend/src/routes/adminPreciosRoutes.js`** y su controlador (`backend/src/controllers/adminPreciosController.js`). Monta en `backend/index.js` junto a los demás `app.use('/api/...')`, protegiendo **todas** las rutas con `authMiddleware` + `requireRol('admin')`:

   | Método y ruta | Comportamiento (ver `CONTRATO_PRECIOS_API_CSV.md` §3.1–3.3, §3.6) |
   |---|---|
   | `GET /api/admin/precios` | Listado paginado. Filtros: `lista`, `q`, `sin_precio=true`, `page`, `por_pagina` (máx. 100). Cada fila: `producto_id, nombre, sku, costo, stock, precios{cliente,profesional,negocio}, unidad_minima{...}, avisos[]` |
   | `PUT /api/admin/precios/:productoId` | Edición manual: `costo` y/o `precios[{lista,precio,unidad_minima?}]`. Valida precio ≥ 0 y entero > 0 en `unidad_minima`. **Los avisos NO impiden guardar** (L26). Una transacción por petición |
   | `PATCH /api/admin/precios/bulk` | `{lista, producto_ids[], operacion{tipo: 'porcentaje'\|'fijar'\|'delta', valor}, preview}`. Con `preview: true` **no escribe nada** y devuelve el diff (`afectados`, `suben`, `bajan`, `mayor_cambio_pct`, `detalle[]`). Con `preview: false` aplica y registra historial |
   | `GET /api/admin/precios/coherencia` | Solo lectura. Cinco listas de avisos (ver §3.6) |

4. **`backend/scripts/verifyPreciosPorLista.js`** — el guardián (punto 6).

### B. Editar

1. `backend/index.js` — solo la línea de montaje de la ruta nueva, junto a las existentes (`app.use('/api', ...)`). **No reordenes ni toques otros montajes.**
2. `backend/src/services/precioService.js` es nuevo; si necesitas un helper de contexto para lecturas de plataforma, va **aquí** o en `tenantRouting.js`, nunca un pool nuevo.

### C. NO TOCAR

- ❌ **`backend/controllers/productController.js`** (ojo: la ruta real es `backend/src/controllers/productController.js`) — su lectura del precio se arregla en **el work order 3**. Aquí no lo toques.
- ❌ `backend/src/controllers/orderController.js` — work order 3.
- ❌ `backend/migrations/010_implement_glowstore_schema.sql`, `011_seed_mens_products.sql`, `032_fix_011_insert.sql` — insertan en las columnas heredadas de precio. **No los edites.**
- ❌ `backend/migrations/070_*.sql` y `071_*.sql` — **ya están aplicadas**. Si crees que necesitas esquema nuevo, **párate y repórtalo**.
- ❌ Las columnas heredadas (`precio`, `precio_al_publico`, `precio_prestador`, `precio_con_reserva`, `comision_prestador`) **no se borran**: quedan deprecadas hasta una migración posterior con informe. No escribas en ellas y no las borres.
- ❌ `backend/src/services/ai/` (retirado), `backend/src/services/agents/*`, el RAG (`ragService.js`, `geminiService.js`), `.env` y credenciales.

## CORRECCIONES EXACTAS

| Hoy | Correcto | Cómo verificarlo |
|---|---|---|
| El precio vive en 4 columnas de `productos` (`productController.js:14-22`, `:86-88`; `orderController.js:94,100`) | El precio se resuelve **por lista** con `resolverPrecio` | `grep -rn "precio_prestador\|precio_al_publico" backend/src --include=*.js \| grep -v test` → en este work order no debe aumentar; tu servicio **no** los menciona |
| `unidad_minima` no existía | Se valida **antes** de cobrar, solo en la lista `negocio` | `SELECT codigo, min(unidad_minima), max(unidad_minima) FROM precios_producto p JOIN listas_precios l ON l.id=p.lista_id GROUP BY 1` → `negocio` = 6/6 |
| Ningún registro de quién cambió un precio | Cada escritura deja fila en `precios_historial` con `actor_id`, `origen` y `motivo` si viene | `SELECT count(*) FROM precios_historial` antes/después de un `PUT` |
| No hay portero por rol | `requireRol('admin')` en todas las rutas nuevas | Un `CLIENTE` y un `PRESTADOR` → **403** |

Donde falte un valor, **obtenlo**: `CHECK` de la migración, `SELECT DISTINCT`, o `grep` del consumidor. Nunca lo inventes.

## TRAMPAS

1. **No hay pantalla de precios**: el panel (`admin-dashboard/src/app`) no tiene página de productos. Este work order entrega **la API**, no la UI; no crees pantallas.
2. **`precios_producto` tiene `tenant_id` denormalizado con trigger**: no lo mandes desde el cliente ni lo calcules; el trigger lo deriva de la lista. Si el listado te devuelve 0 filas, revisa el **contexto de tenant de la petición** (no es un problema de datos).
3. **RLS forzado**: sin contexto, toda lectura devuelve **0 filas en silencio**. Si obtienes 0 filas donde esperabas datos, sospecha del contexto antes que de los datos.
4. **El nivel profesional y el de negocio no tienen precios**: no los rellenes "para probar" ni dejes que el código invente uno. `sin_precio` es una respuesta válida y la esperada.
5. **Modo memoria en tests**: jest sin `DATABASE_URL` no toca la base (`db.js:557`). Un test que "pasa" contra memoria no prueba nada de esto.

## VERIFICACIÓN OBLIGATORIA

Ejecuta **cada** comando y pega su salida **real** (no la resumas, no la inventes). PostgreSQL local: contenedor `beauty-postgres`, **puerto 5435** (el `.env` dice 5432: está desactualizado). El rol `admin` es superusuario con `BYPASSRLS`, así que **para probar RLS usa un rol sin bypass**:

```bash
# 0. Base de tests en TU punto de partida (antes de tocar nada) — repórtala tal cual
cd backend && npx jest --listTests | wc -l && npm test 2>&1 | tail -4

# 1. Guardián: el ANTES (ROJO) y el DESPUÉS (VERDE), con su salida cruda
node backend/scripts/verifyPreciosPorLista.js; echo "exit=$?"

# 2. Lo que tu código NO debe hacer: no leer las columnas heredadas
grep -rn "precio_prestador\|precio_al_publico\|precio_con_reserva" backend/src/services/precioService.js backend/src/controllers/adminPreciosController.js   # esperado: 0 líneas

# 3. Sesiones SQL reales (psql -U admin -d beauty_db, puerto 5435)
#    a) las tres listas y sus mínimos
SELECT codigo, rol_destino, incluye_iva FROM listas_precios ORDER BY codigo;
SELECT l.codigo, count(*) AS precios, min(p.unidad_minima) AS min_u FROM precios_producto p JOIN listas_precios l ON l.id=p.lista_id GROUP BY 1;
#    b) el historial crece con cada PUT (y no con preview)
SELECT origen, count(*) FROM precios_historial GROUP BY 1;
#    c) RLS: escribir en el catálogo de plataforma con un rol SIN bypass debe dar 0 filas
SET ROLE app_rls_user; SELECT set_config('app.tenant_id','1',false);
UPDATE productos SET stock = stock;             -- esperado: UPDATE 0
INSERT INTO productos (nombre, precio, tag_especialidad, tenant_id)
  VALUES ('x', 1, 'Test', (SELECT app_platform_tenant_id()));  -- esperado: violación de política RLS
RESET ROLE;

# 4. Suite completa: compara contra la base que mediste, NO contra tu memoria
cd backend && npm test 2>&1 | tail -6
# Si el conteo de rojos cambia y no es por tests que tú reescribiste, NO lo escondas: repórtalo crudo.

# 5. Guardianes del repo
node backend/scripts/verifyNoVersionedSecrets.js
```

## GUARDIÁN

`backend/scripts/verifyPreciosPorLista.js` debe comprobar, contra la base real y con salida legible:

1. existen las 3 listas y **profesional/negocio tienen 0 precios**;
2. escribir un precio con la ruta `PUT` (o el servicio) aparece luego en `GET`;
3. `resolverPrecio` con `cantidad = 5` y rol `salon` → **error de mínimo**; con 6 → precio;
4. `resolverPrecio` de un producto sin precio en `profesional` → **`sin_precio`** (no un valor inventado);
5. un `CLIENTE` y un `PRESTADOR` reciben **403** en las rutas nuevas;
6. cada escritura deja **exactamente una** fila nueva en `precios_historial`, y `preview` deja **cero**;
7. `activar/desactivar` (si lo implementas) no borra filas de precio.

**Debe fallar antes del trabajo (las rutas no existen) y pasar después.** Pega las dos salidas.

## ENTREGA

- Punto de partida: rama **`feat/glowshop-niveles-a0`** (`ef9deafe`, ya pusheada). Rama nueva desde ahí: **`feat/glowshop-precios-api`**. Nunca commit a `main`.
- Commits pequeños, mensajes en español, con el porqué (no "wip").
- PR contra `main` con: qué se cambió, salida **ROJA → VERDE** del guardián, los conteos reales de la suite (base y después), y las preguntas abiertas de abajo.
- Formato de evidencia: **`archivo:línea` antes/después + la salida real del comando**. Sin "todo funciona", sin "69/69 PASS" como único argumento.

## PROHIBICIONES

- No inventes salidas de comandos ni conteos de tests. Si algo falla, repórtalo tal cual.
- No rellenes precios de profesional/negocio "para que se vea funcionando".
- No caigas a las columnas heredadas ni a porcentajes por defecto: el estado honesto es **`sin_precio`**.
- No hagas migraciones ni `ALTER TABLE` para acomodar el código.
- No uses `BYPASSRLS`, ni `SET ROLE`, ni un pool nuevo para "que se vean los datos".
- No toques `.env`, credenciales, ni los módulos del punto C.
- Si encuentras un consumidor de precios que este prompt no lista, **párate y repórtalo**.

## PREGUNTAS ABIERTAS QUE DEBES DEVOLVER EN EL PR

1. ¿El `PATCH bulk` debe permitir operar sobre **todos** los productos (`producto_ids: []` = todos) o exigir siempre una selección explícita? (No lo decidas: implementa la opción segura —selección explícita— y déjalo anotado.)
2. ¿La edición de precios debe permitir **programar** una vigencia futura (`vigente_desde`), o el contrato de hoy basta?

## DEFINICIÓN DE TERMINADO

1. `precioService.js` es la única vía de cálculo de precio y **no** conoce las columnas heredadas.
2. Las 4 rutas existen, con `authMiddleware` + `requireRol('admin')`, y responden según `docs/glowshop/CONTRATO_PRECIOS_API_Y_CSV.md`.
3. Cada escritura deja historial (con `actor_id`, `origen`, `motivo` si viene); `preview` no escribe.
4. El guardián: **ROJO antes, VERDE después**, con ambas salidas pegadas.
5. Suite completa: la base que mediste, con cualquier cambio explicado por nombre de test.
6. PR abierto contra `main` con la evidencia cruda y las preguntas abiertas.
7. **Cero** líneas nuevas que mencionen las columnas heredadas de precio.
