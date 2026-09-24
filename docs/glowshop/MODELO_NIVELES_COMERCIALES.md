# MODELO DE NIVELES COMERCIALES (MNC) — GlowShop
### La mejor manera de ejecutar tu planteamiento: tres niveles por rol, precio como dato, mínimo de venta por nivel

**Fecha**: 2026-09-24 · **Base**: tu planteamiento (6 respuestas) + auditoría GlowShop + esquema real de la base
**Estado**: propuesta para tu confirmación — no ejecutada

---

## 1. Tu planteamiento, consolidado

| Nivel | Rol del sistema | ¿Para qué compra? | Mínimo de venta | Precio (sobre 100) |
|---|---|---|---|---|
| Consumidor final | `client` | Consumo propio | 1 unidad | 100 |
| Profesional | `provider` | **Revende a sus clientes** y gana la diferencia | 1 unidad *(a confirmar)* | 90 |
| Negocio | `salon` | **Insumo de consumo dentro del salón** | 6 unidades (bloque) | 80 por unidad (480/6) |
| *(futuro)* | — | Aprovisionamiento (comprar a marcas) | — | entra más adelante |

La clave de tu modelo, que antes no estaba clara y ahora sí: **los tres niveles no son tres descuentos del mismo negocio, son tres negocios distintos.** El consumidor consume; el profesional **revende** (es un canal de distribución con su propio margen); el salón **consume insumos** en su operación. Y la tienda solo vende **por bloques a partir de 6 unidades** en el nivel de negocio.

Y tu instrucción operativa: **se venden legalmente con logística de envío** y con factura.

**Lo que se puede vencer**: autorizaste reestructurar las reglas de precio actuales para arrancar limpio. Lo tomo como *"las reglas pueden cambiar, los datos se conservan"*: migración con mapeo explícito y conteo de filas, nunca borrado sin verificación.

---

## 2. El hallazgo que cambia el arranque (necesito tu confirmación)

Medido en la base, sobre un producto real:

| Producto | Cliente hoy | Prestador hoy | Con reserva hoy |
|---|---|---|---|
| Shampoo de Argán Orgánico | 45.000 (100%) | **29.250 (65%)** | 38.250 (85%) |
| Mascarilla de Queratina | 55.000 (100%) | **35.750 (65%)** | 46.750 (85%) |

**Hoy el prestador paga el 65% del precio de lista. Tu modelo dice 90%.** Son 25 puntos de diferencia: el prestador pasaría a pagar **+38% de lo que paga hoy**. Y el salón, que en tu modelo paga el 80%, hoy no existe como comprador en absoluto: en la base hay **41 usuarios `PRESTADOR` y 8 `CLIENTE`, cero `SALON`**, aunque la tabla `salones` y el rol `SALON` ya existen en el sistema (`config/jwt.js:16`) y la tienda todavía no los conoce.

Mi lectura de lo que pasó: el 65% actual **estaba haciendo dos trabajos a la vez** — el de "precio para revender" y el de "precio de insumo del negocio". Tu modelo los separa correctamente (90 para revender, 80 para insumo), y de paso sube el margen de GlowApp. Pero eso es un **cambio comercial con 41 prestadores afectados**, no un detalle de implementación:

- ¿Confirmas que el prestador pasa a 90% (y su ganancia al revender es el 10%)?
- ¿Qué hacemos con los 41 prestadores que hoy tienen 65%: se les respeta temporalmente con una lista de transición, o entran al nuevo esquema desde el día uno?

Y una pieza que falta para saber si el negocio cierra: **no existe el costo de mercancía** en la base. Sin `costo`, nadie puede saber si vender a 80 es rentable. Lo dejo señalado (ver §7).

---

## 3. La mejor manera: el precio como dato, no como columnas

### Por qué no seguir con columnas

Hoy el precio vive en columnas del producto (`precio`, `precio_al_publico`, `precio_con_reserva`, `precio_prestador`) más `comision_prestador` y un `tipo_visibilidad` de dos valores. Con tu modelo eso se rompe por tres lados: **no expresa el mínimo de venta**, **no expresa vigencia** (promociones, ajustes estacionales) y **no escala a una lista negociada por salón** (que dijiste que llegará). Cada nivel nuevo o cada salón con condiciones propias exigiría una migración.

### El modelo propuesto

```
listas_precios
  id · codigo · nombre · rol_destino (client|provider|salon) · incluye_iva
  vigente_desde · vigente_hasta · estado · tenant_id (null = lista global de GlowApp)

precios_producto
  lista_id · producto_id · precio · unidad_minima (1 | 6 | 12 | …)
  vigente_desde · vigente_hasta
```

**Resolución en la compra** (una sola función, un solo camino):
1. el rol del comprador determina **qué lista** ve (nunca otra),
2. la lista da el **precio por producto**,
3. `unidad_minima` valida el bloque (el salón no puede comprar 3),
4. si mañana un salón negocia condiciones, se le asigna **su propia lista** — sin tocar código ni esquema.

**Cómo se llenan los 888 precios (296 productos × 3 niveles)** — nadie teclea eso a mano:
- **Regla por defecto**: multiplicador por lista sobre el precio base (`client 100%`, `provider 90%`, `salon 80%`), configurable.
- **Excepción por producto**: override en `precios_producto` para los que tengan su propio precio negociado.
- Así, cambiar un multiplicador reajusta el catálogo entero; y cada producto puede apartarse de la regla cuando el negocio lo decida.

### Las tres tiendas: un catálogo, tres frentes

**No tres tiendas duplicadas** (sería el mismo error de duplicar el comercio). Es un catálogo con tres frentes, cada uno con su lista, su mínimo de compra y su presentación:

| Frente | Ve | No ve | Acciones |
|---|---|---|---|
| Consumidor | su lista (100), stock, promociones | precios B2B | comprar unidades, comprar con su cita (−15% por reserva) |
| Profesional | su lista (90), **PVP sugerido y su margen calculado** | lista mayorista | comprar por unidad, revender, ver cuánto gana |
| Negocio (salón) | su lista (80) con **unidad mínima 6**, cajas sugeridas | listas inferiores | comprar por bloques, con factura y envío |

Y el detalle de negocio que conviene decidir: **el consumidor ve que existe el nivel profesional** ("¿tienes un salón o atiendes clientas? compra a precio profesional") sin ver sus precios. Es el gancho de captación del canal B2B; sin él, el nivel profesional solo crece por boca a boca.

---

## 4. Las reglas de negocio nuevas

| Regla | Definición propuesta |
|---|---|
| **Precio por rol** | Rol → lista → precio. Nunca se expone otra lista; probado por test de rol |
| **Mínimo de venta** | Por lista: consumidor 1, profesional 1 *(a confirmar)*, negocio 6 |
| **Margen del revendedor** | El prestador ve `PVP sugerido` (lista consumidor) y su margen = PVP − precio profesional |
| **Comisión por venta asistida** | **Separada** del margen de reventa: si el prestador recomienda y el cliente compra en la tienda, gana comisión (hoy `comision_prestador`, 10%, pagada vía `provider_wallet`) |
| **Restricción de uso del nivel negocio** | Precio de insumo, no de reventa: si en el futuro se quiere un salón revendedor, será un acuerdo aparte (evita canibalizar el nivel profesional) |
| **Promociones** | El −15% por comprar con la cita deja de ser una columna de precio y pasa a ser **promoción con vigencia y alcance**: es una regla, no un precio |
| **Impuestos** | Decidir si el precio publicado **incluye IVA** por nivel (retail suele mostrarlo incluido; B2B suele mostrarlo discriminado) |
| **Venta legal** | Factura con datos fiscales del comprador (razón social, NIT, dirección) + envío con costo y guía |
| **Costo y margen** | Introducir `costo` (costo de mercancía) para poder medir rentabilidad por nivel antes de prometer 80 |

---

## 5. Qué se vence del modelo actual y cómo (sin perder información)

| Regla vigente hoy | Destino | Conservación |
|---|---|---|
| `precio_al_publico` | lista `client` (100%) | migrado 1:1 |
| `precio_prestador` (65%) | **decisión §2**: lista `provider` al 90% (nueva) o transición que respete el 65% | se conserva el valor histórico en el mapeo y en un informe de diferencias |
| `precio_con_reserva` (85%) | promoción "compra con tu cita" con vigencia | el valor se conserva como 15% de descuento |
| `comision_prestador` (10%) | se mantiene como **comisión por venta asistida** | sin cambio de semántica |
| `tipo_visibilidad` (`PUBLICO`/`INSUMO_PRESTADOR`) | pasa a ser visibilidad **por lista** | se traduce al nuevo modelo |
| `pedidos_tienda` sin cobro ni tenant | absorbida por el **pedido único** del núcleo de comercio | doble lectura durante la transición |

Reglas duras: **migración con conteo de filas antes/después**, doble lectura mientras convive, y ningún borrado de columna hasta que el informe de diferencias esté firmado.

---

## 6. Plan por fases

### FASE A — Precio y niveles *(S/M · arranca ya, no depende del cobro)*
1. `listas_precios` + `precios_producto` con `unidad_minima` y vigencias.
2. Migración desde las 4 columnas actuales, con informe de diferencias (cuántos productos cambian de precio y cuánto).
3. La API de catálogo resuelve por lista del rol; **prohibido** devolver otra lista; `unidad_minima` se valida en el carrito y en el checkout.
4. Activar el rol `SALON` en la tienda (existe el rol, la tienda no lo conoce).
5. El frente profesional muestra PVP sugerido y margen.

**Aceptación**: un consumidor no puede ver ni pedir precios B2B (test por rol); el salón no puede comprar 5 unidades; un cambio de multiplicador se refleja en todo el catálogo sin migración; el informe de diferencias cuadra contra los valores actuales.

### FASE B — Núcleo de comercio *(L · el corazón)*
El pedido único con `tenant_id` + RLS, webhook de pago verificado e idempotente, reserva de stock con expiración y liberación, liquidación al prestador al entregar, traza de estados. Es la fase ya planteada en la propuesta 360, ahora con el precio resuelto por lista.

**Aceptación**: pagar mueve el pedido sin intervención del cliente; repetir el webhook no duplica; un pedido impago expira y devuelve stock; comisión al prestador liquidada por nivel correcto.

### FASE C — B2B real *(M)*
Factura con datos fiscales, IVA configurable por lista, envío con costo real y guía (hoy son 12.000 fijos en el código), libreta de direcciones por comprador, dashboard del prestador con su margen y su comisión, y la vista de "convertirse en profesional".

### FASE D — Mayorista de verdad *(futuro, cuando lo decidas)*
Aprovisionamiento (proveedores, órdenes de compra, costo de mercancía, bodegas), listas negociadas por salón, crédito, y márgenes por canal.

---

## 7. Supuestos que tomo salvo que me corrijas

1. **Mínimo de venta**: consumidor 1, profesional 1, negocio 6 (tu ejemplo tiene al profesional comprando 1 unidad a 90; si el mínimo de 6 también aplica al profesional, dímelo y lo subo).
2. **IVA**: se muestra **incluido** al consumidor y **discriminado** a profesional y negocio.
3. **Factura**: al inicio, factura interna con datos fiscales completos; la facturación electrónica (DIAN) entra con su proveedor en Fase C.
4. **Comisión por venta asistida**: se mantiene separada del margen de reventa.
5. **Costo de mercancía**: falta en el sistema; lo propongo como campo obligatorio en Fase A para poder medir rentabilidad por nivel antes de comprometer el 80%.

---

## 8. Lo que necesito de ti para cerrar la Fase A

1. **¿Confirmas el salto del prestador de 65% a 90%?** Y si sí: ¿los 41 prestadores actuales entran al nuevo esquema desde el día uno o con una lista de transición?
2. **¿El mínimo de 6 unidades aplica solo al nivel negocio, o también al profesional?**
3. **¿El gancho "compra a precio profesional" se muestra al consumidor?** (mi recomendación: sí, sin mostrar precios)

Con esas tres respuestas, la Fase A queda especificada y lista para ejecutar.
