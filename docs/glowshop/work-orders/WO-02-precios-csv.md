# WORK ORDER 2/4 — Carga y descarga masiva de precios por archivo (CSV)

> Pega todo este bloque en Antigravity. Es autocontenido: no depende de ninguna conversación previa.

---

## ROL

Eres el agente implementador del monorepo **belleza-app**. Tu tarea es **una**: implementar la **exportación e importación de precios por CSV** de GlowShop, con vista previa y sin capacidad de destruir precios. No abras otros frentes: la API de precios (work order 1), la lectura de la tienda (3) y la autorización del catálogo (4) son trabajos distintos.

## CONTEXTO — medido, no supuesto

Este work order **continúa el nº1**: das por hecho que existen `backend/src/services/precioService.js`, `backend/src/middleware/roles.js` y `backend/src/controllers/adminPreciosController.js` con las rutas `GET/PUT/PATCH /api/admin/precios` y `GET /api/admin/precios/coherencia`, todas tras `authMiddleware` + `requireRol('admin')`. Si no existen, **párate y repórtalo**: tu rama debe partir de `feat/glowshop-precios-api`.

**El contrato ya está escrito y congelado**: `docs/glowshop/CONTRATO_PRECIOS_API_Y_CSV.md` — §3.4 (exportar), §3.5 (importar) y **§4 (formato del CSV)**. Impleméntalo tal cual. Las reglas normativas están en `docs/glowshop/LINEAMIENTOS_GLOWSHOP.md`: te afectan **L22** (conservación de datos), **L25** (precio manual; el porcentaje solo cuando se pide, con vista previa) y **L26** (avisos, no candados).

**Datos reales del modelo para probar** (PostgreSQL local: contenedor `beauty-postgres`, **puerto 5435**; el `.env` dice 5432 y está desactualizado):

- `listas_precios`: tres filas, `codigo` = `cliente` (296 precios), `profesional` (**0**), `negocio` (**0**). El nivel de negocio tiene `unidad_minima = 6`; los otros, 1.
- `productos`: **296** filas, todas del tenant de plataforma; `costo` es **NULL en las 296** (la columna es nueva) y `sku` también.
- `precios_historial` con `origen IN ('manual','bulk_porcentaje','bulk_fijar','import_csv','migracion')`.

**Subida de archivos: ya está en el repo.** `multer` es dependencia y se usa en `backend/index.js:8,113,124` y `backend/src/middleware/evidenceUpload.js`. **Reutilízalo con `multer.memoryStorage()`** (no `diskStorage`: no queremos archivos de usuario en el disco del servidor) y límite de tamaño explícito.

**Aviso sobre tests**: con `NODE_ENV=test` y sin `DATABASE_URL`, `backend/src/config/db.js:557` fuerza **modo memoria**: jest no toca PostgreSQL. Por eso el analizador del CSV debe ser una **función pura testeable con jest** (texto → filas validadas + errores), y la verificación contra la base se hace con el **guardián** (script), no con jest.

Base de tests: **mídela tú** en tu punto de partida y repórtala; compara **por nombre de test**, no por conteo (hay rojos preexistentes en la suite).

## ALCANCE

### A. Crear

1. **`backend/src/services/preciosCsvService.js`** — dos funciones puras y una de aplicación:
   - `exportarPreciosCsv({ lista })` → CSV con encabezado y **una columna por lista** (formato §4).
   - `parsearPreciosCsv(texto)` → `{ filas, errores[] }`, donde cada error lleva `{ fila, columna, motivo }`. **Sin efectos secundarios, sin acceso a base** (por eso es testeable con jest).
   - `aplicarPreciosCsv({ filas, actorId, reemplazar })` → una **sola transacción**: o entra todo lo válido, o no entra nada.
2. **`backend/scripts/verifyImportCsvPrecios.js`** — el guardián (punto 6).

### B. Editar

1. `backend/src/controllers/adminPreciosController.js` — **solo** añadir los dos manejadores nuevos.
2. `backend/src/routes/adminPreciosRoutes.js` — **solo** añadir:
   - `GET /api/admin/precios/export.csv?lista=`
   - `POST /api/admin/precios/import.csv?dry_run=true|false&reemplazar=false|true` (con el `upload.single('archivo')` de multer en memoria)
   Ambas tras `authMiddleware` + `requireRol('admin')`.
3. `backend/src/services/preciosCsvService.js` — si necesitas registrar historial, usa el mismo camino que el `PUT` del work order 1 (`precios_historial` con `origen = 'import_csv'`).

### C. NO TOCAR

- ❌ `backend/src/controllers/productController.js` y `orderController.js` (work order 3).
- ❌ Las columnas heredadas de precio (`precio_al_publico`, `precio_prestador`, `precio_con_reserva`, `comision_prestador`): el CSV **no** las lee ni las escribe.
- ❌ `backend/migrations/010_*.sql`, `011_*.sql`, `032_*.sql`, ni **070/071** (ya aplicadas; si crees que necesitas esquema nuevo, párate y repórtalo).
- ❌ `backend/src/services/ai/`, `agents/*`, el RAG, `.env`, credenciales.

## CORRECCIONES EXACTAS — el comportamiento del CSV

| Caso | Correcto | Por qué |
|---|---|---|
| Celda **vacía** en `precio_profesional` (etc.) | **No tocar ese precio** (ni 0 ni borrado) | Un archivo a medias no puede vaciar una lista |
| `precio = 0` o negativo | **Error de fila**, no se aplica | Un precio 0 no es un precio |
| `precio` con `$`, espacios o separador de miles | Error de fila con motivo claro | Se evita interpretar `1.234` como 1,234 |
| Decimales | Punto decimal (`45000.00`). Si hay **coma y no hay punto**, se interpreta como decimal (`45000,00`) | Excel en español exporta así |
| `producto_id` inexistente | Error de fila (no un 500) | El informe debe explicar qué fila falló |
| Encabezado distinto | Error claro; se aceptan variantes de orden pero **no** columnas desconocidas obligatorias | Trazabilidad |
| `dry_run=true` | **Cero escrituras**, informe con `leidas`, `validas`, `con_error`, `errores[]`, `cambios{nuevos,modificados,sin_cambio}` | Vista previa antes de tocar 888 precios |
| `dry_run=false` con filas inválidas | Se aplican **solo las válidas** en una transacción, o no se aplica nada si el informe se pide estricto; el informe siempre se devuelve | Nunca aplicación parcial silenciosa |
| Reimportar el mismo archivo | **0 cambios** (upsert por `(lista, producto)`) | Idempotencia |
| Borrar un precio | Solo con `reemplazar=true` **explícito**, y el informe dice qué quedó sin precio | Nunca por omisión |
| BOM de Excel (`\ufeff`) y CRLF | Se limpian antes de parsear | El archivo real de Diego saldrá de Excel |
| Filas > límite (define y documenta, p. ej. 5000) | Error claro y no se aplica | Evita un POST que tumbe el proceso |

## TRAMPAS

1. **No escribas el archivo a disco.** `multer.diskStorage` ya existe en `index.js:113` para evidencias: no lo reutilices aquí.
2. **No uses `split(',')` para parsear.** Necesitas comillas, comas dentro de comillas y saltos de línea; si no quieres dependencias nuevas, escribe un analizador pequeño y pruébalo con jest (comillas, BOM, CRLF, última línea sin salto).
3. **El `tenant_id` del precio lo pone el trigger** desde la lista (`app_precio_tenant_id`): nunca lo mandes ni lo derives del archivo.
4. **RLS forzado**: si lees 0 filas donde esperabas datos, sospecha del contexto de tenant de la petición antes que de los datos.
5. **`costo` es NULL en los 296 productos**: un export que incluya `costo` saldrá con la celda vacía en todas. Eso es correcto, no un fallo de tu exportación.
6. **No añadas dependencias** sin pararte a reportarlo.

## VERIFICACIÓN OBLIGATORIA

Pega la salida **real** de cada comando (no la resumas, no la inventes):

```bash
# 0. Base de tests en tu punto de partida
cd backend && npm test 2>&1 | tail -4

# 1. Guardián: ANTES (ROJO) y DESPUÉS (VERDE)
node backend/scripts/verifyImportCsvPrecios.js; echo "exit=$?"

# 2. Prueba de idempotencia EN REAL (exporta y reimporta el mismo archivo):
#    a) exportar   → count de filas del CSV (296 productos, 3 columnas de precio)
#    b) reimportar con dry_run=false → informe con cambios.nuevos=0, modificados=0
#    c) SELECT count(*) FROM precios_historial  → no creció por filas sin cambio
# 3. Prueba de destrucción imposible:
#    a) importar un CSV con la columna precio_profesional vacía → profesional sigue en 0 filas
#    b) importar un CSV con un precio en 0 → error de fila, 0 escrituras
#    c) importar con reemplazar=false y una fila que falta → esa lista conserva sus precios
# 4. dry_run no escribe:
SELECT count(*) FROM precios_historial;   -- antes de un dry_run y después: idéntico

# 5. Suite completa: compara por NOMBRE de test contra la base que mediste
cd backend && npm test 2>&1 | tail -6

# 6. Guardianes del repo
node backend/scripts/verifyNoVersionedSecrets.js
```

## GUARDIÁN

`backend/scripts/verifyImportCsvPrecios.js` debe comprobar, contra la base real:

1. `GET export.csv` devuelve 296 filas + encabezado, con una columna por lista;
2. reimportar ese mismo CSV **no cambia nada** (`cambios.nuevos=0`, `modificados=0`) y **no** añade filas a `precios_historial`;
3. un CSV con una fila inválida (precio 0) → error reportado **con fila y motivo**, y **0** escrituras;
4. un CSV que solo toca `precio_profesional` **no modifica** los precios de consumidor (comparar `count(*)` y una suma de precios antes/después);
5. celda vacía = **no tocar** (comparar suma de la lista afectada antes/después);
6. `dry_run=true` deja `precios_historial` intacto;
7. las rutas responden **403** a `CLIENTE` y `PRESTADOR`.

**Debe fallar antes del trabajo (las rutas no existen) y pasar después.** Pega las dos salidas.

## ENTREGA

- Rama nueva desde **`feat/glowshop-precios-api`**: **`feat/glowshop-precios-csv`**. Nunca commit a `main`.
- Commits pequeños en español, con el porqué.
- PR contra `main` (deja anotado en el cuerpo que depende del PR de la API de precios).
- Evidencia: `archivo:línea` antes/después + salida real. Sin "todo funciona".

## PROHIBICIONES

- No inventes salidas ni conteos.
- No escribas archivos a disco ni añadas dependencias.
- No dejes que una fila inválida haga fallar el lote entero **sin informe**: el informe es la entrega.
- No hagas migraciones de esquema ni `ALTER TABLE`.
- No toques `.env`, credenciales, ni los módulos del punto C.
- Si aparece un consumidor de precios que este prompt no lista, **párate y repórtalo**.

## PREGUNTAS ABIERTAS QUE DEBES DEVOLVER EN EL PR

1. ¿El import debe poder **crear productos nuevos** si el `sku` no existe, o solo actualizar precios de productos existentes? (Implementa **solo actualizar** y déjalo anotado: crear productos por CSV tiene implicaciones de catálogo que no son de este trabajo.)
2. Límite máximo de filas y de tamaño de archivo que consideres prudente, con su justificación.

## DEFINICIÓN DE TERMINADO

1. Export e import funcionan según `docs/glowshop/CONTRATO_PRECIOS_API_Y_CSV.md` §3.4, §3.5 y §4.
2. Celda vacía **nunca** borra un precio; reimportar es idempotente; `dry_run` no escribe.
3. El analizador del CSV es una función pura con tests de jest (comillas, BOM, CRLF, decimales).
4. Guardián ROJO antes / VERDE después, con ambas salidas pegadas.
5. Suite completa comparada por nombre de test contra la base medida por ti.
6. PR abierto con evidencia cruda y las preguntas abiertas.
