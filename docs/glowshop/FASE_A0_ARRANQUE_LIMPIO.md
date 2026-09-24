# FASE A0 — ARRANQUE LIMPIO DE LA TIENDA
### Qué se borra, qué se conserva y cómo nace el modelo acordado

**Fecha**: 2026-09-24 · **Base**: decisión del usuario ("arrancamos los datos de tienda desde 0; en construcción no daña nada")
**Verificado**: alcance medido en la base local, no supuesto

---

## 1. Alcance real del reinicio (medido)

| Tabla | Filas hoy | Destino |
|---|---|---|
`productos` | **296** (tenant Demo) | **se reconstruye** con el modelo acordado (ver §3) |
`pedidos_tienda` | **1** — `PAGADO`, 57.220, del 2026-09-03 | **se borra** (fósil del bug: nació pagado) |
`detalles_pedido_tienda` | **1** (su línea) | **se borra** |
`scan_product_matches` | 0 | se recrea con `tenant_id` |
`booking_productos` | 0 | se recrea con `tenant_id` |
`inventario_consignacion_prestador` | 0 | se recrea con `tenant_id` |

### Lo que NO se toca (verificado: no son datos de tienda)

| Tabla | Filas | Por qué se conserva |
|---|---|---|
`usuarios` | 49 | cuentas reales |
`bookings` | **83** | servicios: son el negocio vivo |
`transactions` | 3 | dinero de servicios |
`provider_wallet` | 9 | monederos de prestadores |
`reviews` | 3 | **son de servicio** (`booking_id`), no de producto |
`salones` | 0 | el nivel negocio nace vacío, sin migración |

**Dependencias que obligan el orden del borrado**: `detalles_pedido_tienda.producto_id → productos` es `RESTRICT`, igual que `booking_productos` e `inventario_consignacion_prestador`. Con esas tres tablas vacías (0, 0 y 0), borrar `productos` no rompe ninguna referencia. **Comprobado.**

---

## 2. Antes de borrar: conservación

Aunque el reinicio no dañe nada, **se conserva la información** (regla L22):

1. Exportar los 296 precios actuales a `docs/glowshop-2026-09-24/precios_antes.csv` (producto, `precio_al_publico`, `precio_prestador`, `precio_con_reserva`, `comision_prestador`).
2. Guardar el pedido fósil y su línea en `docs/glowshop-2026-09-24/pedido_fosil_pagado.csv`.
3. Ambos quedan versionados: si alguien pregunta "¿qué precios había?", la respuesta está en el repositorio.

---

## 3. Qué significa "de 0" (mi recomendación)

Dos lecturas posibles:

| Opción | Qué hace | Veredicto |
|---|---|---|
**A** · Vaciar todo y sembrar 10-20 productos nuevos | catálogo mínimo de muestra | pierde 296 nombres de producto útiles sin ganar nada |
**B** · **Conservar los 296 productos como catálogo de plataforma, recalcular sus precios desde cero con el modelo nuevo** | catálogo real desde el día uno, precios nuevos, sin arrastrar el 65% heredado | ✅ **recomendada** |

Con B, "empezar de 0" se cumple donde importa: **cero precios heredados, cero pedidos heredados, cero esquema heredado**. Los nombres de producto son datos de catálogo, no deuda técnica.

---

## 4. Cómo nace el modelo (migración única de arranque)

Una migración nueva (nunca editar las existentes):

1. **Tenant de plataforma**: `tenants.es_plataforma` + índice único; se marca el tenant correspondiente.
2. **Catálogo**: los 296 productos pasan al tenant de plataforma y `tenant_id` pasa a `NOT NULL`.
3. **Roles**: `CHECK` en `usuarios.rol` (4 valores).
4. **Listas**: se crean `cliente`, `profesional`, `negocio` con su `unidad_minima` y `incluye_iva`.
5. **Precios**: los 888 precios nacen de una **carga manual inicial** (importación por archivo con los valores que tú decidas) y quedan **editables uno por uno**. El multiplicador (90% / 80%) es solo un **valor de sugerencia** para esa carga, nunca una regla: ningún proceso recalcula un precio por su cuenta. **No** se derivan de las columnas heredadas.
6. **Comercio con dueño**: `tenant_id NOT NULL` en `scan_product_matches`, `booking_productos`, `inventario_consignacion_prestador`.
7. **RLS Opción A**: políticas de lectura (mío + plataforma) y escritura (solo mío).
8. **Contexto por petición**: `authMiddleware` deja de fijar `app.tenant_id` con `set_config(..., false)` y pasa al contexto por petición (`is_local = true`).
9. **Costo**: columna `costo` en `productos` (obligatoria en el alta) — sin ella no hay margen.
10. **Semilla de la migración**: el alta del catálogo en instalaciones nuevas apunta al tenant de plataforma (la semilla actual, `migrations/010`, dejaba el catálogo en el tenant Demo).

**Fuera de alcance de A0** (va en Fase B): el pedido único, el webhook verificado, la reserva de stock con expiración y la liquidación al entregar. A0 deja el **terreno y las reglas**; B construye el motor sobre ellas.

---

## 5. Criterios de aceptación

1. `SELECT count(*) FROM productos WHERE tenant_id IS NULL` = 0.
2. Existen exactamente 3 listas activas, con sus mínimos, y `precios_producto` tiene 296 × 3 filas (o las que correspondan a overrides).
3. Un `CLIENTE` no recibe ningún precio B2B (inspección del JSON completo).
4. Un `SALON` comprando 5 unidades recibe **400**; con 6 pasa.
5. **Un prestador del tenant 1 ve el catálogo de plataforma** (hoy vería 0 filas).
6. Un prestador **no** puede modificar ni borrar productos de otro negocio (403) ni del catálogo de plataforma.
7. Un `ADMIN` (tenant de plataforma) sí puede editar el catálogo de plataforma, **sin `BYPASSRLS`**.
8. `pedidos_tienda` = 0 filas y no existe ninguna fila nacida `PAGADO`.
9. Los CSV de conservación existen y cuadran con los 296 productos y el pedido fósil.
10. El rol de conexión tiene `rolbypassrls = false` (verificación en el pipeline).
11. **Puedo cambiar el precio de un producto y verlo reflejado en la tienda sin desplegar código ni tocar SQL.**
12. **Ningún proceso recalcula un precio por sí solo**: el porcentaje solo actúa cuando se pide, con vista previa de lo que cambia.
13. **El mínimo de 6 se exige solo al nivel negocio**: 5 unidades al profesional → pasa; 5 al negocio → 400.
14. El informe de coherencia **avisa sin bloquear** (precio profesional ≥ consumidor, negocio ≥ profesional, precio < costo, producto sin precio en alguna lista) y el guardado se realiza igual.

---

## 6. Lo que necesito para escribir la migración

1. **La carga inicial de precios**: ¿arranco con los 296 productos tomando su precio de consumidor actual como base y dejo profesional y negocio **en blanco** para que los cargues tú (recomendado: así el 90/80 nunca llega a ser precio real sin tu decisión), o prefieres que venga **pre-cargado con los porcentajes sugeridos** y luego ajustar?
2. **La superficie manual**: ¿archivo de importación/exportación primero (recomendado para cargar 888 precios) y pantalla de edición después, o la quieres en el panel desde el arranque?
3. **¿Aprobado el plan A0 tal cual** (conservar los 296 nombres con precios nuevos) o prefieres vaciar el catálogo y sembrar una muestra?

Con esas tres respuestas la migración queda escrita y probada; el siguiente paso es Fase B (el motor de comercio).
