# WORK ORDER 4/4 — Autorización del catálogo y el borrado que no borre la historia

> Pega todo este bloque en Antigravity. Es autocontenido: no depende de ninguna conversación previa.

---

## ROL

Eres el agente implementador del monorepo **belleza-app**. Tu tarea es **una**: cerrar la **autorización del catálogo** de GlowShop (hoy cualquier prestador puede crear, editar y borrar productos) y evitar que **borrar un producto destruya su historial de precios**. No abras otros frentes.

## CONTEXTO — medido, no supuesto

**Tres defectos verificados en `backend/src/controllers/productController.js`:**

1. **`createProduct` (`:103-154`) no puede funcionar.** Su INSERT (`:128-131`) escribe 10 columnas y **omite `precio`**, que en el esquema es `NOT NULL` y sin `DEFAULT`. Medido en la base:
   ```
   ERROR:  null value in column "precio" of relation "productos" violates not-null constraint
   ```
   Es decir: el endpoint de alta del catálogo **falla siempre** hoy.
2. **Cualquier `PRESTADOR` puede escribir el catálogo entero.** La comprobación de rol es idéntica en las tres funciones —`if (req.user.role !== 'admin' && req.user.role !== 'provider')`— en `:106` (crear), `:159` (editar) y `:221` (borrar). Y `deleteProduct` ejecuta `DELETE FROM productos WHERE id = $1` (`:226`) **sin verificar propiedad ni tenant**. Con el catálogo de plataforma existiendo (migración 071), un prestador de cualquier negocio puede borrar el catálogo global si RLS no lo impide: **la política sí lo frena hoy** (devuelve `DELETE 0` → 404), pero la autorización de la aplicación no debería depender solo de eso. Lineamiento **L15**.
3. **Borrar un producto borra su historia.** Verificado en el esquema: `precios_historial.producto_id` y `precios_producto.producto_id` referencian `productos(id)` con **`ON DELETE CASCADE`**. Un `DELETE` desde el panel eliminaría los precios y el rastro de quién los cambió. Lineamiento **L22** (conservación).

**Lo que ya existe y debes usar:** `backend/src/middleware/roles.js` con `requireRol(...)` (work order 1); `authMiddleware` deja `req.user.role`, `req.user.rol` y `req.user.tenant_id` (`backend/src/middleware/auth.js:44-58`); el enum `tipo_rol` ya admite `SALON` y `ADMIN` (migración 070); `productos.tenant_id` es `NOT NULL` y el trigger `app_assign_tenant_id` lo rellena desde el contexto de la petición; RLS forzado con la regla **leer = lo mío + lo de plataforma · escribir = solo lo mío**.

**El modelo de precios ya no vive en el producto**: `precios_producto` (migración 071) es la fuente. `docs/glowshop/CONTRATO_PRECIOS_API_Y_CSV.md` define que los precios se editan por `PUT /api/admin/precios/:productoId`.

## ALCANCE

### A. Crear

1. **`backend/migrations/072_catalogo_autorizado_y_historial_protegido.sql`**
   - `ALTER TABLE productos ALTER COLUMN precio DROP NOT NULL;` — la columna está **deprecada** (su valor se conserva, no se borra) y hoy impide toda alta de producto.
   - Recrear las claves foráneas de `precios_historial` (`producto_id` y `lista_id`) con **`ON DELETE RESTRICT`**, para que borrar un producto con historial **falle en voz alta** en vez de destruir el rastro.
   - Comentario de bloque explicando el porqué de cada cambio (estilo de las migraciones 068/071).
   - **Idempotente y autoverificada**: la migración debe poder aplicarse dos veces sin error y terminar con un bloque `DO $$ … RAISE EXCEPTION … $$` que compruebe el resultado (que `precio` admite NULL y que las dos FK del historial son `RESTRICT`).
2. **`backend/scripts/verifyCatalogoAutorizado.js`** — el guardián (punto 6).

### B. Editar

1. **`backend/src/controllers/productController.js`** — `createProduct` (`:103-154`), `updateProduct` (`:157-216`), `deleteProduct` (`:219-239`):
   - Autorización: sustituye las tres comprobaciones manuales por **`requireRol('admin')`** en la ruta (`backend/src/routes/productRoutes.js:30,33,36`). Regla de hoy: **solo el administrador escribe el catálogo de plataforma**. Deja un comentario con la extensión futura (cuando un negocio venda productos propios, el guard será `admin || (provider && tenant propietario)` y el aislamiento por fila lo hace RLS) — **no la implementes ahora**.
   - **Dejan de aceptar y de escribir las columnas heredadas de precio** (`precio_al_publico`, `precio_con_reserva`, `precio_prestador`, `comision_prestador`) y `tipo_visibilidad` deja de ser criterio de visibilidad: se conserva el campo por compatibilidad, documentado como deprecado, con el valor por defecto `'PUBLICO'` (decisión diferida al work order 3).
   - `createProduct` acepta y **exige `costo`** (lineamiento **L21**) junto a `nombre`, `tag_especialidad`, `stock`, `imagen_url`, `descripcion` y `sku` opcional; **no** acepta `tenant_id` del cliente (lo pone el trigger desde el contexto; ignóralo si viene y anótalo en el PR).
   - `updateProduct` actualiza **solo** campos del producto (nombre, descripción, stock, imagen, tag, costo, sku). El precio se cambia por `PUT /api/admin/precios/:productoId`.
   - `deleteProduct`: si la operación viola la nueva FK `RESTRICT` (el producto tiene historial), responde **409** con un mensaje claro del tipo *"el producto tiene historial de precios; desactívalo en vez de borrarlo"*. No lo conviertas en un 500.
2. **`backend/src/routes/productRoutes.js`** (`:30,33,36`) — aplicar `requireRol('admin')` (mantén `authMiddleware`).

### C. NO TOCAR

- ❌ `getProducts` (`:14-22`) y `getProductById` (`:59`, `:86-88`): son del work order 3.
- ❌ `backend/src/controllers/orderController.js`.
- ❌ Los seeds `010_*.sql`, `011_*.sql`, `032_*.sql` y las migraciones **070/071** (ya aplicadas).
- ❌ Las columnas heredadas de precio: **no se borran** ni se limpian sus valores.
- ❌ `backend/src/services/precioService.js`, `adminPreciosController.js`, `preciosCsvService.js` (otros work orders).
- ❌ `backend/src/services/ai/`, `agents/*`, el RAG, `.env`, credenciales.

## CORRECCIONES EXACTAS

| Actual | Correcto | Cómo verificarlo |
|---|---|---|
| `if (req.user.role !== 'admin' && req.user.role !== 'provider')` en `:106`, `:159`, `:221` | `requireRol('admin')` en las tres rutas | Un `PRESTADOR` recibe **403** en POST/PUT/DELETE |
| `INSERT … 10 columnas` sin `precio` (`:128-131`) | Alta que **funciona**: sin columnas heredadas, con `costo` obligatorio | `POST` como admin → 201 y el producto aparece en el listado |
| `DELETE FROM productos WHERE id = $1` (`:226`) | Igual, pero con FK `RESTRICT` en el historial y **409** explicativo | Borrar un producto con historial → 409 y el historial intacto |
| `ON DELETE CASCADE` en `precios_historial` | `ON DELETE RESTRICT` | Consulta a `referential_constraints`: `delete_rule = 'RESTRICT'` |
| `productos.precio NOT NULL` | `DROP NOT NULL` (columna deprecada) | `information_schema.columns.is_nullable = 'YES'` |

Donde falte un dato, obténlo del esquema o del `grep` del consumidor. No lo inventes.

## TRAMPAS

1. **`precios_producto` mantiene `CASCADE`**: es correcto ahí (un precio actual de un producto inexistente no significa nada). Lo que se protege es el **historial**. No cambies ambos por igual.
2. **No crees un `DELETE` en cascada "manual"**: si el borrado falla por la FK, la respuesta es 409, no un borrado previo de precios.
3. **La autorización de la aplicación y RLS son dos capas, no una**: hoy el `DELETE` del prestador devuelve 404 porque RLS filtra las filas (`DELETE 0`). Eso **no** es autorización suficiente: el guard debe dar 403 sin llegar a la base.
4. **`tenant_id` no se acepta del cliente** (ni en el body ni como query). El trigger lo pone.
5. **`createProduct` con `precio` eliminado del INSERT**: no añadas `precio: 0` para callar el error; la columna deja de ser obligatoria en la migración 072.

## VERIFICACIÓN OBLIGATORIA

Pega la salida **real** de cada comando. PostgreSQL local: contenedor `beauty-postgres`, **puerto 5435** (el `.env` dice 5432: desactualizado).

```bash
# 0. Base de tests en tu punto de partida
cd backend && npm test 2>&1 | tail -4

# 1. Guardián: ANTES (ROJO) y DESPUÉS (VERDE)
node backend/scripts/verifyCatalogoAutorizado.js; echo "exit=$?"

# 2. Sin autorización manual en el controlador
grep -n "role !== 'admin'" backend/src/controllers/productController.js   # esperado: 0 líneas

# 3. Esquema después de 072 (sesión SQL real)
SELECT column_name, is_nullable FROM information_schema.columns WHERE table_name='productos' AND column_name='precio';
SELECT tc.table_name, kcu.column_name, rc.delete_rule
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu ON tc.constraint_name=kcu.constraint_name
  JOIN information_schema.referential_constraints rc ON tc.constraint_name=rc.constraint_name
 WHERE tc.constraint_type='FOREIGN KEY' AND tc.table_name IN ('precios_historial','precios_producto');
-- esperado: precio YES · precios_historial RESTRICT · precios_producto CASCADE

# 4. La migración es idempotente: aplícala dos veces y reporta ambas salidas
# 5. Suite completa comparada por NOMBRE de test contra tu base medida
cd backend && npm test 2>&1 | tail -6
# 6. Guardián de secretos
node backend/scripts/verifyNoVersionedSecrets.js
```

## GUARDIÁN

`backend/scripts/verifyCatalogoAutorizado.js` debe comprobar, contra la base real:

1. **`PRESTADOR` → 403** en `POST`, `PUT` y `DELETE /api/admin/products…` (y lo mismo para `CLIENTE` y `SALON`);
2. **`ADMIN` → 201** al crear un producto con `costo`, y el producto aparece en el listado **sin valores en las columnas heredadas de precio**;
3. crear **sin `costo`** → **400** (L21);
4. un `tenant_id` enviado en el cuerpo **se ignora**: el producto queda con el tenant del contexto;
5. borrar un producto **con historial** → **409** y `SELECT count(*) FROM precios_historial` **sin cambios**;
6. borrar un producto **sin historial** → 204/200, y el borrado no afecta a otros productos;
7. la migración 072 aplicada dos veces no falla (idempotencia).

**Debe fallar antes del trabajo (hoy el prestador pasa y el alta revienta) y pasar después.** Pega las dos salidas.

## ENTREGA

- Rama nueva desde **`feat/glowshop-niveles-a0`** (`ef9deafe`): **`feat/glowshop-catalogo-autorizado`**. Nunca commit a `main`.
- Commits pequeños en español con el porqué.
- PR contra `main` con: qué se cambió, salida ROJA → VERDE, el antes/después del esquema tras 072, la salida cruda de la suite y las preguntas abiertas.
- Evidencia: `archivo:línea` antes/después + salida real. Sin "todo funciona".

## PROHIBICIONES

- No inventes salidas de comandos ni conteos de tests.
- No borres ni limpies valores de las columnas heredadas.
- No cambies `precios_producto` a `RESTRICT` (solo el historial).
- No introduzcas datos de relleno ni un `costo` por defecto.
- No toques `.env`, credenciales, ni los módulos del punto C.
- Si encuentras otro camino que escriba el catálogo (por ejemplo el panel de administración o un script de carga), **párate y repórtalo** con `archivo:línea` antes de arreglarlo.

## PREGUNTAS ABIERTAS QUE DEBES DEVOLVER EN EL PR

1. **Borrado de productos**: con el historial protegido, un producto con precios ya no se puede borrar. ¿Se introduce **desactivación** (una columna `activo` + filtro en la tienda) en una migración posterior, o el borrado queda prohibido para siempre? (No lo decidas: implementa 409 + mensaje claro y déjalo anotado.)
2. **¿Quién más debería poder escribir el catálogo?** Hoy solo `admin`. Cuando un negocio venda productos propios habrá que decidir si es `provider`, `salon` o ambos (y con qué límites).

## DEFINICIÓN DE TERMINADO

1. Las tres rutas de escritura del catálogo exigen `requireRol('admin')` y **no** queda ninguna comprobación de rol manual en el controlador.
2. `createProduct` funciona (201) y **no** escribe columnas heredadas; exige `costo`.
3. Borrar un producto con historial devuelve **409** y **no** destruye `precios_historial`.
4. Migración 072 idempotente, autoverificada y aplicada (con su salida pegada).
5. Guardián ROJO antes / VERDE después, ambas salidas pegadas.
6. Suite comparada por nombre de test contra la base que mediste.
7. PR abierto con evidencia cruda y las dos preguntas abiertas.
