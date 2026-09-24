# LINEAMIENTOS DE GLOWSHOP
### El contrato que gobierna la tienda — se construye contra esto, no contra el chat

**Fecha**: 2026-09-24 · **Versión**: 1.0 · **Estado**: vigente desde su publicación
**Regla de este documento**: se **anota**, no se reescribe. Si el código contradice un lineamiento, el código está mal. Cada lineamiento declara su razón, el artefacto que lo hace cumplir y la prueba que lo demuestra.

---

## Bloque I — Identidad y niveles

**L1 · Cuatro roles, ni uno más.**
`CLIENTE` · `PRESTADOR` · `SALON` · `ADMIN`. La base los admite y existe un portero por rol.
*Por qué*: hoy `usuarios.rol` es el enum `tipo_rol` con **solo dos valores (`CLIENTE`, `PRESTADOR`)**: `SALON` y `ADMIN` **no se pueden guardar**, y las ramas correspondientes de `toApiRole` (`config/jwt.js:16-17`) son código muerto. El "salón" existe hoy solo como tipo de trabajador (`tipo_trabajador.ADMIN_SALON`).

> **Anotación 2026-09-24 (corrección de la v1)** — La versión inicial de este lineamiento decía "falta un `CHECK` en `usuarios.rol`". Es **incorrecto**: el vocabulario sí está restringido, pero por **tipo enumerado**, y ese enum es el que está incompleto. La corrección no es un `CHECK`, es `ALTER TYPE tipo_rol ADD VALUE 'SALON', 'ADMIN'` (en migración propia: un valor nuevo de enum no puede usarse en la misma transacción que lo crea).

*Se cumple con*: extensión del enum + middleware por rol. *Se prueba con*: crear un usuario `SALON` y un `ADMIN` y verificar acceso por rol.

**L2 · El rol da la lista, no el precio.**
El rol determina **qué lista de precios** se ve; el nivel comercial es un **dato asignado**, no una condición en el código.
*Por qué*: hoy el precio vive en 4 columnas del producto; añadir un nivel exige migrar.
*Se cumple con*: `listas_precios` + `precios_producto`. *Se prueba con*: asignar una lista distinta a un mismo rol y ver el precio cambiar sin desplegar código.

**L3 · Un solo nivel de compra por cuenta, y el salón es insumo.**
El precio de negocio es para **consumo interno del salón**; la reventa pertenece al nivel profesional.
*Por qué*: si el salón revende al precio de insumo, canibaliza al profesional.
*Se cumple con*: regla de negocio + lista restringida. *Se prueba con*: test que impida asignar lista de negocio a una cuenta de reventa.

**L4 · Tres frentes, un catálogo.**
Consumidor, profesional y negocio son **frentes de la misma tienda**, nunca tres tiendas duplicadas.
*Por qué*: duplicar catálogos ya nos costó un comercio paralelo (`pedidos_tienda` vs `booking_productos`).
*Se cumple con*: un solo endpoint de catálogo que resuelve por lista. *Se prueba con*: test de que los tres frentes leen la misma fuente.

---

## Bloque II — Catálogo y precios

**L5 · Catálogo de plataforma visible para todos (Opción A).**
Leer: *lo mío + lo de plataforma*. Escribir: *solo lo mío*. El administrador pertenece al tenant de plataforma.
*Por qué*: la política actual (`tenant_id = app_current_tenant_id()`) hace invisible el catálogo de GlowApp para todo negocio ajeno: hoy 5 prestadores verían 0 productos.
*Se cumple con*: políticas RLS de lectura/escritura separadas + `tenants.es_plataforma`. *Se prueba con*: un prestador del tenant 1 ve el catálogo de plataforma; no ve el de otro negocio.

**L6 · Prohibido `BYPASSRLS`.**
La política protege de verdad; ninguna cuenta de aplicación esquiva RLS.
*Por qué*: si el rol de producción tiene `BYPASSRLS`, la política es decorativa (hallazgo G-05). *Se cumple con*: rol de conexión sin bypass + verificación al desplegar. *Se prueba con*: consulta de comprobación en el pipeline: `SELECT rolbypassrls FROM pg_roles WHERE rolname = current_user` debe ser `false`.

**L7 · Ningún objeto del comercio existe sin dueño.**
Toda tabla de comercio lleva `tenant_id NOT NULL` + RLS.
*Por qué*: `pedidos_tienda`, `detalles_pedido_tienda`, `scan_product_matches` y `booking_productos` no tienen tenant → datos de negocio sin frontera. *Se cumple con*: migración + `NOT NULL`. *Se prueba con*: `count(*) WHERE tenant_id IS NULL` = 0 en todas.

**L8 · Un solo precio, una sola función.**
`resolverPrecio({rol, tenant, producto, cantidad})` es la única vía de calcular el precio, y la usan **catálogo y checkout**.
*Por qué*: hoy el catálogo (`productController`) y el checkout (`orderController`) calculan el precio por caminos distintos: divergirán.
*Se cumple con*: un único servicio de precios. *Se prueba con*: test que compare el precio mostrado en catálogo y el cobrado en checkout para el mismo carrito.

**L9 · Mínimo de venta, solo para el nivel negocio.**
El bloque mínimo (`unidad_minima`) aplica **únicamente a la venta a salones de belleza**; consumidor y profesional compran por unidad. Se valida en el carrito y en el checkout.
*Por qué*: es una condición comercial del nivel mayorista, no de la tienda entera. *Se cumple con*: `precios_producto.unidad_minima` (6 en la lista de negocio, 1 en las otras) + validación. *Se prueba con*: 5 unidades al nivel negocio → 400; 6 → pasa; y 1 unidad al nivel profesional → pasa.

---

## Bloque III — Comercio y dinero

**L10 · Un pedido nace impago y nadie lo marca pagado sin transacción verificada.**
*Por qué*: el INSERT ya nació `PAGADO` una vez (fósil detectado en la base: pedido del 2026-09-03, 57.220). *Se cumple con*: `DEFAULT 'PENDIENTE_PAGO'` + guardián `scripts/verifyNoFabricatedPayments.js`. *Se prueba con*: el guardián en CI + test de que ningún camino marca `PAGADO` sin transacción.

**L11 · Una sola puerta de pago, idempotente y verificada.**
El estado de pago lo cambia **el webhook con firma válida**, no el cliente ni el teléfono.
*Por qué*: hoy la única prueba de pago es `paymentResult == true` del dispositivo, y no hay webhook para pedidos. *Se cumple con*: webhook verificado + llave de idempotencia. *Se prueba con*: repetir el webhook 3 veces → 1 solo pago registrado.

**L12 · El stock se reserva con expiración y se libera.**
Nunca se descuenta stock definitivo antes de la confirmación de pago.
*Por qué*: hoy se descuenta al crear el pedido y no se libera nunca (ni por cancelación ni por expiración). *Se cumple con*: reserva con vencimiento + job de liberación. *Se prueba con*: pedido impago expirado → stock idéntico al inicial.

**L13 · Liquidación al entregar, no al pagar.**
El prestador cobra cuando el pedido se entrega, con la ventana de disputa ya existente en el monedero.
*Por qué*: el monedero (`provider_wallet`) ya modela pendiente/disponible/disputa; la tienda debe reutilizarlo, no inventar otro. *Se cumple con*: transición de estado → movimiento de monedero. *Se prueba con*: pedido entregado → saldo pasa de pendiente a disponible en la ventana configurada.

**L14 · Margen de reventa y comisión por venta asistida son cosas distintas.**
El primero es la diferencia de precio del nivel profesional; la segunda es el pago por recomendar (la `comision_prestador` actual).
*Por qué*: mezclarlas hace imposible saber cuánto gana el prestador y cuánto le cuesta a GlowApp. *Se cumple con*: dos conceptos separados en el modelo. *Se prueba con*: liquidación correcta en ambos casos.

**L15 · Ningún prestador toca el catálogo ajeno.**
El CRUD del catálogo está restringido a su dueño (o al administrador en el catálogo de plataforma).
*Por qué*: hallazgo G-04 — hoy cualquier prestador puede editar y borrar todo el catálogo. *Se cumple con*: guard por rol + RLS de escritura. *Se prueba con*: prestador A intenta borrar producto de B → 403.

---

## Bloque IV — Inteligencia (agentes)

**L16 · Ningún agente inventa datos.**
Si no hay datos, el agente devuelve **fallo honesto** (`sin_datos`, `sin_productos`), nunca `success: true` con contenido fabricado.
*Por qué*: HESTIA servía `prod-001`/`prod-002` y VALKYRIE una promoción `GLOW-MARTES-15` inventadas.
*Se cumple con*: contratos de los 5 agentes (ATENA, HERMES, CHRONOS, HESTIA, VALKYRIE). *Se prueba con*: test que exija `sin_datos` cuando la consulta no devuelve filas.

**L17 · Cada agente declara su eslabón del circuito.**
Diagnóstico (ATENA) → surtido (HESTIA) → cumplimiento (HERMES) → continuidad (CHRONOS) → economía del negocio (VALKYRIE), con AURA como puerta.
*Por qué*: un agente sin eslabón es código decorativo. *Se cumple con*: contrato de entrada/salida por agente. *Se prueba con*: prueba de integración por eslabón.

**L18 · La inteligencia no decide el dinero.**
VALKYRIE **propone** promociones y precios con límites y vigencia; aprobarlas es humano.
*Por qué*: un descuento autorizado por un modelo es un riesgo comercial y contable. *Se cumple con*: flujo de propuesta/aprobación. *Se prueba con*: test de que un descuento propuesto sin aprobación no afecta precios.

---

## Bloque V — Verdad legal y trazabilidad

**L19 · Toda venta es una venta legal.**
Factura con datos fiscales del comprador, IVA según la lista, y envío con costo real.
*Por qué*: el mayorista vende con factura; hoy el envío son 12.000 fijos en el código y no hay facturación.
*Se cumple con*: datos fiscales en el comprador + costo de envío configurable. *Se prueba con*: pedido B2B con factura y costo de envío calculado.

**L20 · Toda transición de estado deja traza.**
Quién, cuándo y por qué cambió el estado de un pedido.
*Por qué*: hoy existen `pedidos_tienda` sin un solo `UPDATE` en el repositorio y sin historial. *Se cumple con*: tabla de traza (mismo patrón que `rag_query_logs`). *Se prueba con*: cada cambio de estado produce exactamente una fila.

**L21 · El costo de mercancía es dato obligatorio.**
Sin `costo` no se puede saber si un nivel es rentable. *Por qué*: hoy no existe en el esquema. *Se cumple con*: campo `costo` + validación. *Se prueba con*: informe de margen por nivel.

---

## Bloque VI — Disciplina de datos y pruebas

**L22 · Ninguna migración borra datos sin informe de diferencias.**
Se conserva el valor anterior, se cuentan las filas antes y después, y el borrado de columnas va en una migración posterior aprobada.
*Por qué*: es la regla que ya salvó el corpus del RAG. *Se prueba con*: informe firmado por migración de datos.

**L23 · Las pruebas afirman el lineamiento, no el comportamiento actual.**
Un test que consagra un defecto se reescribe con el lineamiento.
*Por qué*: hay 3 bloques de tests que hoy afirman el comportamiento defectuoso de los agentes.
*Se prueba con*: revisión de que ningún test afirme un comportamiento contrario a este documento.

**L24 · Este documento se anota, no se reescribe.**
Los cambios se añaden con fecha y motivo; nunca se borra lo acordado.
*Se prueba con*: historial del archivo.

---

## Bloque VII — Precios manuales

**L25 · El precio es un dato escrito a mano; el porcentaje es una ayuda, nunca una regla.**
Cada producto tiene su precio por lista, editado manualmente. El multiplicador existe solo como *sugerencia de carga* (por ejemplo "aplicar 90% a esta lista"), se ejecuta como una acción explícita del usuario, **con vista previa de lo que va a cambiar**, y no impone ninguna relación entre listas.
*Por qué*: los porcentajes son estimaciones comerciales, no leyes; el negocio decide cada precio. *Se cumple con*: `precios_producto.precio` como fuente de verdad + acción de carga masiva separada y trazada. *Se prueba con*: editar un precio a mano y comprobar que ningún proceso lo recalcula; aplicar un porcentaje y comprobar que solo cambia lo que estaba seleccionado, con registro de quién y cuándo.

**L26 · Avisos, no candados.**
Un precio fuera de lo razonable **se señala**, nunca se bloquea: precio profesional igual o mayor que el de consumidor (el revendedor no gana), precio de negocio mayor que el profesional (el salón paga más que un revendedor), precio por debajo del costo (margen negativo), insumo sin costo cargado, producto sin precio en alguna lista.
*Por qué*: bloquear impide decisiones comerciales legítimas (liquidaciones, acuerdos puntuales). *Se cumple con*: informe de coherencia de precios. *Se prueba con*: cargar un precio que dispare cada aviso y comprobar que el guardado se realiza igual.

**L27 · Todo precio debe poder editarse sin desplegar código.**
Debe existir una superficie real para cargar y editar precios: pantalla de catálogo con los precios por lista, y carga/exportación masiva por archivo.
*Por qué*: hoy los precios solo se escriben por API o por semillas SQL; el panel de administración no tiene pantalla de productos, así que "poner el precio a mano" no tiene dónde hacerse. *Se cumple con*: pantalla de precios + importación/exportación. *Se prueba con*: cambiar un precio y verlo reflejado en la tienda sin tocar la base ni desplegar.

---

## Estado de cumplimiento hoy (la brecha a cerrar)

| # | Lineamiento | Hoy |
|---|---|---|
| L1 | Cuatro roles con `CHECK` | ❌ sin restricción |
| L2 | Rol da la lista | ❌ precio por rol en columnas |
| L5 | Catálogo de plataforma | ❌ bloqueado por RLS |
| L6 | Sin `BYPASSRLS` | ❓ sin verificar en producción |
| L7 | Comercio con dueño | ❌ 4 tablas sin `tenant_id` |
| L8 | Un solo precio | ❌ dos caminos distintos |
| L9 | Mínimo de venta (6, solo negocio) | ❌ no existe ningún mínimo |
| L10 | Pedido nace impago | ✅ corregido + guardián |
| L11 | Puerta de pago única | ❌ sin webhook de pedidos |
| L12 | Reserva con expiración | ❌ descuenta y nunca libera |
| L13 | Liquidación al entregar | ❌ nada llega a `PAGADO` |
| L15 | Catálogo protegido | ❌ G-04 |
| L16 | Agentes honestos | ❌ 2 fabrican datos |
| L19 | Venta legal | ❌ envío fijo, sin factura |
| L20 | Traza de estados | ❌ sin historial |
| L21 | Costo de mercancía | ❌ no existe |
| L22 | Conservación de datos | ✅ precedente RAG |
| L25 | Precio manual, % como ayuda | ❌ hoy el % (65/85) es la regla forzosa |
| L26 | Avisos, no candados | ❌ no existe informe de coherencia |
| L27 | Editar precios sin desplegar | ❌ el panel no tiene pantalla de productos |
