# WORK ORDER 3/4 — La tienda lee del modelo nuevo: catálogo por nivel y checkout

> Pega todo este bloque en Antigravity. Es autocontenido: no depende de ninguna conversación previa.

---

## ROL

Eres el agente implementador del monorepo **belleza-app**. Tu tarea es **una**: hacer que el **catálogo** y el **checkout** de GlowShop calculen el precio con el **servicio único de precios por nivel** ya construido, en lugar de leer las columnas heredadas. No abras otros frentes (CSV y autorización del catálogo son trabajos aparte).

## CONTEXTO — medido, no supuesto

**Das por hecho el work order 1**: existe `backend/src/services/precioService.js` con `resolverPrecio({ rol, tenantId, productoId, cantidad })` → `{ lista, precio, unidad_minima, incluye_iva }` o `{ estado: 'sin_precio', ... }`, y existen `requireRol(...)` en `backend/src/middleware/roles.js`. Si no existen, **párate y repórtalo**: tu rama parte de `feat/glowshop-precios-api`.

**Lo que hay hoy, verificado:**

- `backend/src/controllers/productController.js:14-22` — `getProducts` tiene **dos ramas por rol**: prestador/admin reciben `precio_prestador AS precio` (`:16`) y el cliente recibe `precio_al_publico AS precio, precio_con_reserva` (`:22`). Dos caminos para el mismo dato.
- `backend/src/controllers/productController.js:59` — `getProductById` selecciona las cuatro columnas heredadas; `:86-88` elige `precio_prestador` o `precio_al_publico` según `req.user.role`.
- `backend/src/controllers/orderController.js:57-102` — el precio unitario se decide **otra vez**, en paralelo: `:94` `precio_prestador`, `:100` `precio_al_publico`. Es la divergencia que el lineamiento **L8** prohíbe: catálogo y checkout calculan por caminos distintos.
- `backend/src/routes/productRoutes.js:24,27` — `GET /api/products` y `GET /api/products/:id` **no exigen autenticación** (no llevan `authMiddleware`). Con RLS forzado (migración 071) una petición anónima **no tiene contexto de tenant y devuelve 0 filas**.
- Modelo nuevo ya aplicado (migración 071): `listas_precios` (`cliente` 296 precios · `profesional` 0 · `negocio` 0, con `unidad_minima` 6 **solo** en negocio) y `precios_producto`. La función `app_platform_tenant_id()` da el tenant de plataforma. **Nunca hardcodees ese id** (localmente es 9).
- `backend/src/middleware/tenantContext.js:73` — envuelve la petición autenticada en `runInTenantTransaction`, así que las consultas del `pool` ya van a la conexión con contexto. `backend/src/config/tenantRouting.js:169` expone además `runAsSystem` (**BYPASSRLS**: **prohibido** usarlo aquí, ver trampas).
- `bookings`, `transactions`, `provider_wallet`, `reviews` y los 296 productos **no se tocan** en este trabajo.

**Aviso sobre tests**: con `NODE_ENV=test` y sin `DATABASE_URL`, `backend/src/config/db.js:557` fuerza **modo memoria**: jest no toca PostgreSQL. Los dobles del `pool` son la vía para los tests unitarios; la verificación contra la base va en el guardián. **Mide tú la base de tests** de tu punto de partida y compara **por nombre de test**.

## ALCANCE

### A. Editar

1. **`backend/src/controllers/productController.js`** — `getProducts` (`:14-22`) y `getProductById` (`:59`, `:86-88`):
   - El precio sale de `resolverPrecio` con el rol del comprador (`req.user?.role`; sin sesión → nivel consumidor).
   - **Visibilidad por nivel** (reemplaza a `tipo_visibilidad` como criterio): un producto es visible para un nivel **si y solo si tiene precio en la lista de ese nivel**. Los productos `INSUMO_PRESTADOR` de la semilla (p. ej. `Cera Elástica de Miel (1kg)` y `Kit Pestañas Premium (Melted)`) tienen `precio_al_publico = 0`, así que **no** recibieron precio de consumidor: sigan invisibles para el cliente sin que nadie escriba un `if` por `tipo_visibilidad`. Verifícalo con la consulta del punto 3 de la verificación.
   - Un producto **sin precio en la lista del nivel** no se devuelve con un precio inventado: se omite del listado o se devuelve `{ precio: null, estado: 'sin_precio' }` de forma **consistente** en ambos endpoints.
   - Deja de seleccionar las columnas heredadas en las respuestas.
2. **`backend/src/controllers/orderController.js`** (`:57-102`):
   - El precio unitario sale de **la misma** `resolverPrecio` (mismo rol, misma cantidad): catálogo y checkout deben coincidir **siempre** (L8).
   - Valida `unidad_minima` **antes** de tocar stock o crear el pedido: un salón comprando 5 unidades del nivel negocio → **400** con el mínimo en el mensaje; 6 → pasa (L9).
   - **No cambies** la lógica de envío, IVA, comisión ni descuento de stock: están fuera de alcance (ver preguntas abiertas).
3. **La puerta del catálogo público** — `GET /api/products` debe seguir funcionando **sin sesión** (hoy funciona así y hay que preservarlo), pero con **contexto de plataforma explícito del servidor**:
   - Ejecuta ese camino dentro de `runInTenantTransaction({ pool }, <id de app_platform_tenant_id()>, …)`, **nunca** con `runAsSystem` y **nunca** con un `tenant_id` que venga del cliente.
   - Resultado esperado: un invitado ve **el catálogo de plataforma** con el **precio de consumidor**, y nada más. Ni productos de otros negocios, ni precios B2B.
   - Si te resulta más limpio centralizarlo, un helper en `backend/src/services/precioService.js` (p. ej. `conContextoDePlataforma(fn)`); no crees un pool nuevo.

### B. Crear

1. **`backend/scripts/verifyCatalogoPorNivel.js`** — el guardián (punto 6).

### C. NO TOCAR

- ❌ Las **columnas heredadas de precio** (`precio`, `precio_al_publico`, `precio_prestador`, `precio_con_reserva`): no se borran, no se escriben; quedan deprecadas hasta una migración posterior con informe.
- ❌ `backend/src/controllers/productController.js` en sus funciones de **escritura** (`createProduct` `:103-154`, `updateProduct` `:157-216`, `deleteProduct` `:219-239`): son del work order 4.
- ❌ Los seeds `backend/migrations/010_*.sql`, `011_*.sql`, `032_*.sql`, y las migraciones **070/071** (ya aplicadas). Si crees que necesitas esquema nuevo, **párate y repórtalo**.
- ❌ `backend/src/services/ai/`, `backend/src/services/agents/*`, el RAG (`ragService.js`, `geminiService.js`), `.env`, credenciales.
- ❌ El envío (12.000 fijos, `orderController.js:122`), el IVA (`:123`) y la lógica de comisión al prestador.

## CORRECCIONES EXACTAS

| Hoy | Correcto | Cómo verificarlo |
|---|---|---|
| Catálogo: dos ramas por rol con columnas heredadas (`productController.js:14-22`) | Una sola resolución por lista | `grep -n "precio_prestador\|precio_al_publico" backend/src/controllers/productController.js` → 0 líneas en las funciones de lectura |
| Checkout: `orderController.js:94,100` elige columna por rol | `resolverPrecio` (la misma del catálogo) | El guardián compara precio de catálogo vs precio cobrado |
| Sin mínimo de venta | `negocio` exige 6; `cliente`/`profesional`, 1 | 5 unidades como salón → 400 |
| Invitado bajo RLS forzado: 0 filas | Contexto de plataforma fijado por el **servidor** | `curl` sin token → 200 con el catálogo de plataforma |
| `tipo_visibilidad` decidía quién ve qué | Decide la **existencia de precio en la lista** | Los 2 insumos de la semilla no tienen precio de consumidor |

## TRAMPAS

1. **`runAsSystem` compila y "funciona", y está prohibido aquí**: usa `app_system` (`BYPASSRLS`) y mostraría los productos de **todos** los negocios. Para el invitado, el contexto es el **tenant de plataforma**, no un rol privilegiado.
2. **RLS forzado devuelve 0 filas en silencio** cuando falta contexto. Si un endpoint devuelve una lista vacía inesperada, sospecha del contexto antes que de los datos.
3. **El IVA está en dos sitios a la vez y no es tu trabajo arreglarlo**: la lista `cliente` está marcada `incluye_iva = true`, mientras `orderController.js:123` **suma** 19% al subtotal. Hoy el total del consumidor es `precio × 1,19 + envío`. **No cambies esa aritmética en este trabajo**: repórtalo en las preguntas abiertas con los números (sobre un producto de 45.000: hoy paga 53.550 + envío; con la regla de la lista pagaría 45.000 + envío). Es una decisión comercial, no tuya.
4. **No inventes un precio de relleno** cuando la lista no tiene fila: el estado honesto es `sin_precio`.
5. **Los 296 precios de consumidor existen**; los de profesional y negocio **no**. No los siembres para probar.

## VERIFICACIÓN OBLIGATORIA

Pega la salida **real** de cada comando. PostgreSQL local: contenedor `beauty-postgres`, **puerto 5435** (el `.env` dice 5432: desactualizado). Para pruebas de RLS, rol **sin** BypassRLS: `SET ROLE app_rls_user` + `set_config('app.tenant_id', …)`.

```bash
# 0. Base de tests en tu punto de partida (repórtala tal cual)
cd backend && npm test 2>&1 | tail -4

# 1. Guardián: ANTES (ROJO) y DESPUÉS (VERDE)
node backend/scripts/verifyCatalogoPorNivel.js; echo "exit=$?"

# 2. Las columnas heredadas ya no se leen en el camino de lectura
grep -n "precio_al_publico\|precio_prestador\|precio_con_reserva" backend/src/controllers/productController.js   # esperado: 0 líneas
grep -n "precio_al_publico\|precio_prestador" backend/src/controllers/orderController.js                       # esperado: 0 líneas

# 3. Semillas y visibilidad (sesión SQL real)
SELECT codigo, count(*) FROM precios_producto p JOIN listas_precios l ON l.id=p.lista_id GROUP BY 1;
-- Los 2 insumos de prestador NO deben tener precio en la lista 'cliente':
SELECT p.id, p.nombre FROM productos p WHERE p.tipo_visibilidad='INSUMO_PRESTADOR'
  AND EXISTS (SELECT 1 FROM precios_producto pp JOIN listas_precios l ON l.id=pp.lista_id
              WHERE pp.producto_id=p.id AND l.codigo='cliente');   -- esperado: 0 filas

# 4. Guardián de secretos y suite
node backend/scripts/verifyNoVersionedSecrets.js
cd backend && npm test 2>&1 | tail -6
```

## GUARDIÁN

`backend/scripts/verifyCatalogoPorNivel.js` debe comprobar, contra la base real y contra la API levantada:

1. **invitado** (`GET /api/products` sin token): 200, y el JSON **no** contiene ninguna clave de precio B2B, ni productos de un negocio ajeno;
2. **cliente**: recibe el precio de la lista `cliente`; ninguna clave de precio profesional/negocio;
3. **prestador**: recibe el precio de `profesional`; **no** el de `negocio` (no puede ver la lista mayorista);
4. **salón**: recibe el precio de `negocio` y su `unidad_minima` = 6;
5. **mínimo de venta**: 5 unidades como salón en el checkout → **400** con el mínimo; 6 → acepta;
6. **L8 — un solo precio**: para el mismo producto y nivel, el precio del **catálogo** y el que usa el **checkout** son **idénticos** (compáralos en el script, no a ojo);
7. **sin precio** en un nivel → `sin_precio`/null consistente, sin valor inventado.

**Debe fallar antes del trabajo y pasar después.** Pega las dos salidas.

## ENTREGA

- Rama nueva desde **`feat/glowshop-precios-api`**: **`feat/glowshop-catalogo-niveles`**. Nunca commit a `main`.
- Commits pequeños en español con el porqué.
- PR contra `main`, con la dependencia del PR de precios anotada en el cuerpo.
- Evidencia: `archivo:línea` antes/después + salida real. Sin "todo funciona".

## PROHIBICIONES

- No inventes precios, ni caigas a las columnas heredadas, ni a porcentajes.
- No uses `runAsSystem`, `BYPASSRLS`, `SET ROLE` ni un pool nuevo "para que se vean los datos".
- No cambies la aritmética de envío, IVA ni comisión.
- No hagas migraciones de esquema.
- No toques `.env`, credenciales, ni los módulos del punto C.
- Si aparece un consumidor de precios que este prompt no lista (por ejemplo, el chat de Aura o las recomendaciones de HESTIA), **párate y repórtalo** con `archivo:línea`.

## PREGUNTAS ABIERTAS QUE DEBES DEVOLVER EN EL PR

1. **El IVA del consumidor**: la lista dice `incluye_iva = true`, el checkout suma 19% (`orderController.js:123`). ¿El precio publicado incluye IVA (el total baja a `precio + envío`) o se discrimina al cobrar (queda como hoy)? **No lo decidas**: reporta los dos totales de un producto real.
2. **`tipo_visibilidad`**: queda vestigial (manda la existencia de precio en la lista). ¿Se retira en una migración posterior o se conserva como etiqueta informativa?
3. **Envío**: hoy son 12.000 fijos (`orderController.js:122`) para todos los niveles. ¿El nivel de salón lleva otro costo o retiro en tienda?

## DEFINICIÓN DE TERMINADO

1. Catálogo y checkout obtienen el precio de `resolverPrecio`; **cero** lecturas de columnas heredadas en esos dos archivos.
2. El invitado ve el catálogo de plataforma a precio de consumidor, sin que el cliente aporte contexto de tenant.
3. El mínimo de 6 se exige **solo** al nivel de salón (400 con 5, OK con 6).
4. Guardián ROJO antes / VERDE después, con ambas salidas pegadas.
5. Suite comparada por nombre de test contra la base medida por ti.
6. PR abierto con evidencia cruda y las tres preguntas abiertas.
