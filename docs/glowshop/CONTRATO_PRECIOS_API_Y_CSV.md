# CONTRATO DE PRECIOS — API y CSV
### La puerta por donde tu dashboard va a alimentar la tienda

**Fecha**: 2026-09-24 · **Para**: el dashboard de alimentación (manual + CSV) que construirás después de estructurar la tienda
**Por qué existe este documento**: si estructuro la tienda sin fijar esta interfaz, tu dashboard inventará su propio contrato y tendremos dos verdades. Esto se congela **antes** de construir el dashboard.

---

## 1. Orden de ejecución acordado

| # | Etapa | Quién |
|---|---|---|
1 | **A0 · Estructura**: esquema, listas, RLS, roles, costos, historial de precios y **estos endpoints** | yo (estructura) |
2 | **Dashboard de alimentación**: pantalla manual + importación/exportación CSV | tú |
3 | **B · Motor de comercio**: pedido único, pago verificado, stock reservado, liquidación | siguiente fase |

Regla que se mantiene (L27): **todo precio se edita sin desplegar código**. El dashboard es la superficie; estos endpoints, su enchufe.

---

## 2. Modelo de datos que el dashboard verá

```
productos            → id, nombre, sku, costo, stock, imagen, visibilidad, tenant_id
listas_precios       → codigo ('cliente' | 'profesional' | 'negocio'), rol_destino, incluye_iva, estado
precios_producto     → (lista_id, producto_id) → precio, unidad_minima, vigente_desde/hasta
precios_historial    → lista, producto, precio_anterior, precio_nuevo, actor, origen, motivo, fecha
```

`unidad_minima` = 1 en cliente y profesional; **6 en negocio** (venta a salones).

---

## 3. Endpoints (contrato congelado)

### 3.1 Leer el catálogo con sus precios
```
GET /api/admin/precios?lista=negocio&q=shampoo&sin_precio=true&page=1&por_pagina=50
200 →
{ "total": 296, "pagina": 1, "filas": [ {
    "producto_id": 1042, "nombre": "Shampoo de Argán Orgánico", "sku": "SH-ARG-01",
    "costo": 22000.00, "stock": 40,
    "precios": { "cliente": 45000.00, "profesional": null, "negocio": null },
    "unidad_minima": { "cliente": 1, "profesional": 1, "negocio": 6 },
    "avisos": ["sin_precio:profesional", "sin_precio:negocio"]
} ] }
```

### 3.2 Editar un producto (manual)
```
PUT /api/admin/precios/1042
{ "costo": 22000, "precios": [
    { "lista": "cliente",     "precio": 45000 },
    { "lista": "profesional", "precio": 40500 },
    { "lista": "negocio",     "precio": 36000, "unidad_minima": 6 } ],
  "motivo": "ajuste de agosto" }

200 → la fila completa + avisos (los avisos NO impiden guardar: L26)
```
Cada escritura deja fila en `precios_historial` con actor, fecha, origen `manual` y el `motivo` si viene.

### 3.3 Carga masiva por porcentaje (con vista previa obligatoria)
```
PATCH /api/admin/precios/bulk
{ "lista": "profesional", "producto_ids": [1042, 1043, ...],
  "operacion": { "tipo": "porcentaje", "valor": 90 },   // o "fijar" | "delta"
  "preview": true }

preview=true  → NO escribe nada. Devuelve el diff:
{ "afectados": 12, "suben": 3, "bajan": 9, "mayor_cambio_pct": 22.4,
  "detalle": [ { "producto_id": 1042, "antes": 29250, "despues": 40500, "delta_pct": 38.5 } ] }

preview=false → aplica y escribe `precios_historial` con origen `bulk_porcentaje`
```
**El porcentaje solo vive aquí** (L25): es una acción explícita, nunca un recálculo automático.

### 3.4 Exportar
```
GET /api/admin/precios/export.csv?lista=           → CSV (todas las listas si se omite)
GET /api/admin/precios/export.csv?lista=negocio    → CSV de una lista
```

### 3.5 Importar CSV
```
POST /api/admin/precios/import.csv     (multipart: archivo)
?dry_run=true|false   &reemplazar=false|true

dry_run=true (recomendado siempre primero) → NO escribe. Informe:
{ "leidas": 296, "validas": 290, "con_error": 6,
  "errores": [ { "fila": 41, "columna": "precio_negocio", "motivo": "valor no numérico" } ],
  "cambios": { "nuevos": 190, "modificados": 100, "sin_cambio": 6 } }

dry_run=false → aplica en una transacción: o entra todo lo válido, o no entra nada
```
- **Idempotente**: reimportar el mismo archivo no produce cambios (upsert por `lista + producto`).
- **Celda vacía = no tocar ese precio.** Nunca se interpreta como 0 ni como borrado.
- **Borrar** requiere `reemplazar=true` explícito, y aun así se informa qué quedó sin precio.
- Precio 0 o negativo → **error de fila** (no se acepta).

### 3.6 Informe de coherencia (avisos, nunca bloqueos — L26)
```
GET /api/admin/precios/coherencia
200 → { "profesional_mayor_o_igual_que_cliente": [ {producto_id, profesional, cliente} ],
        "negocio_mayor_que_profesional": [...],
        "precio_bajo_costo": [...],
        "sin_costo_cargado": [...],
        "producto_sin_precio_en_lista": [...] }
```

---

## 4. Formato del CSV

```csv
producto_id,sku,nombre,costo,stock,precio_cliente,precio_profesional,precio_negocio,unidad_minima_negocio
1042,SH-ARG-01,Shampoo de Argán Orgánico,22000,40,45000,40500,36000,6
1043,AC-COC-02,Acondicionador de Coco,19000,25,38000,34200,,
```

| Columna | Obligatoria | Regla |
|---|---|---|
`producto_id` | sí, o `sku` | debe existir; si no, error de fila |
`costo`, `stock` | no | vacío = no tocar |
`precio_cliente` | al menos una de las tres | número sin símbolo ni separador de miles |
`precio_profesional` | " | vacío = **no tocar** (no es 0) |
`precio_negocio` | " | vacío = no tocar |
`unidad_minima_negocio` | no | por defecto 6 |

---

## 5. Permisos

| Quién | Puede |
|---|---|
`ADMIN` (tenant de plataforma) | leer, editar, bulk, importar y exportar **el catálogo de plataforma** |
`PRESTADOR` | editar **solo sus propios productos**; intentar tocar el catálogo de plataforma → **403** |
`SALON` · `CLIENTE` | no editan precios (el salón compra, el cliente compra) |

Respuestas de error: `400` con la lista de errores por fila · `403` sin permiso · `404` producto inexistente · `409` conflicto de versión.

---

## 6. Lo que A0 debe entregar para que el dashboard funcione

1. Las tablas `listas_precios`, `precios_producto` y **`precios_historial`**.
2. `costo` en `productos`.
3. Los 6 endpoints de §3, con validación y permisos.
4. El import/export CSV resuelto **en el backend** (una sola validación, un solo camino). El dashboard solo sube el archivo y muestra el informe — así no hay dos implementaciones que se desincronicen.
5. La resolución de precio en la tienda leyendo de `precios_producto` (nada de columnas heredadas).
