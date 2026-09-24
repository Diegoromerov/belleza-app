# PROPUESTA DE REINGENIERÍA — GlowShop 360
### La tienda como capa de comercio del circuito completo, no como módulo aparte

**Fecha**: 2026-09-24 · **Autor**: Hermes (auditoría) · **Estado**: propuesta para decisión — no ejecutada
**Base**: auditoría `AUDITORIA-GLOWSHOP.md` (9 hallazgos medidos) + inventario del monorepo + esquema real de la base
**Depende de**: PR de corrección de agentes (contratos honestos: `no_products`, `insufficient_data`)

---

## 1. La tesis

> GlowShop no está rota por falta de código: está rota porque se construyó **al margen** de las dos piezas que ya funcionan en la casa — el **dinero de servicios** y la **inteligencia de los agentes**.

Hoy conviven dos comercios que no se hablan:

| | Servicios (funciona) | Productos (GlowShop) |
|---|---|---|
| Pedido | `bookings` (RLS ✅, `tenant_id` ✅) | `pedidos_tienda` (RLS ❌, sin `tenant_id`) |
| Dinero | `transactions` + `provider_wallet` (escrow con `saldo_pendiente` → `saldo_disponible`, retiros, datos bancarios) | **no existe** |
| Cobro | Webhook Wompi verificado (`bookingRoutes.js:28`) | solo el `true` que devuelve la app |
| Comisión al prestador | al completar el servicio, con ventana de disputa (`paymentRoutes.js:262`) | solo si cuelga de una reserva |
| Stock | n/a (agenda) | se descuenta al crear el pedido y **nunca se libera** |
| Inteligencia | n/a | HESTIA (rota) |

Y sin embargo **las piezas de la integración ya existen, desconectadas**:

- `scan_product_matches(profile_id, product_id, match_score, reasoning)` — el diagnóstico biométrico **ya empareja productos con un score y una razón**, y nadie lo usa para vender.
- `glow_cycles.recommended_product_ids` + `am_routine`/`pm_routine` — la rutina **ya sabe qué productos necesita** el usuario.
- `booking_productos(booking_id, producto_id, cantidad, tipo_comision, comision_causada)` — el producto **ya se puede colgar de una cita**, con comisión, pero sin pedido ni precio pagado.
- `provider_wallet` con `tenant_id` — el bolsillo del prestador **ya es multi-negocio**.
- `precio_con_reserva` (−15%) y envío gratis con cita — la regla que une tienda y servicio **ya está en los datos**.

La reingeniería no es construir una tienda: es **enchufar la tienda al circuito que ya existe** y poner los cinco agentes como la capa que decide *qué* ofrecer y *cuándo*.

---

## 2. El circuito de valor (negocio como unidad)

```
   ┌─────────────────────────────── DESCUBRIMIENTO ───────────────────────────────┐
   │  ATENA          HESTIA                CHRONOS              HERMES           │
   │  diagnóstico →  surtido/carrito  →   rutina y momento  →   dónde y cuándo   │
   │  (scan, piel,   (productos con       de recompra           (salón, agenda,  │
   │   subtono,       stock y precio       (día 15/30,           entrega/retiro) │
   │   ingredientes)  al público)          ciclo, hábitos)                        │
   └───────────────────────────────────┬─────────────────────────────────────────┘
                                       ▼
                        ┌──────────────────────────────┐
                        │  AURA (interfaz)             │
                        │  conversa y ejecuta las 5    │
                        │  herramientas + RAG          │
                        └──────────────┬───────────────┘
                                       ▼
   ┌─────────────────────────── COMERCIO (núcleo único) ──────────────────────────┐
   │  pedido (producto)  +  reserva (servicio)  → mismo modelo de orden,           │
   │  mismo ledger, mismo webhook verificado, misma liquidación al prestador      │
   │  · reserva de stock con expiración   · estados auditables                    │
   │  · precio_con_reserva al comprar con la cita  · entrega en el salón          │
   └───────────────────────────────────┬─────────────────────────────────────────┘
                                       ▼
   ┌──────────────────────── DINERO Y CONFIANZA ──────────────────────────────────┐
   │  transactions (Wompi verificado) → provider_wallet (pendiente → disponible)  │
   │  disputas y devoluciones sobre saldo_en_disputa   · liquidación al ENTREGAR  │
   └───────────────────────────────────┬─────────────────────────────────────────┘
                                       ▼
   ┌──────────────────────── ECONOMÍA DEL SALÓN (VALKYRIE) ───────────────────────┐
   │  demanda por día · stock muerto · promo PROPUESTA (no autorizada) · márgenes │
   └───────────────────────────────────┬─────────────────────────────────────────┘
                                       ▼
                     RECOMPRA (vuelve a ATENA/CHRONOS) ⟳  y el ciclo recomienza
```

**Unidad de negocio = el salón/tenant.** Catálogo, stock, pedidos, precios, bolsillo y analítica se leen y escriben por tenant, con RLS forzada y un rol de conexión **sin** `BYPASSRLS` (hoy el rol `admin` la salta — hallazgo G-05).

---

## 3. Los cinco agentes integrados al circuito

Cada agente deja de ser una herramienta suelta del chat y pasa a tener **un eslabón, un contrato y una medición**. Todos con modo de fallo honesto (sin datos inventados: es el PR que ya está en curso).

| Agente | Eslabón | Qué produce (contrato) | Qué consume | Dónde se invoca |
|---|---|---|---|---|
| **ATENA** | Diagnóstico | perfil, subtono, paleta, `recommendedIngredients` | `beauty_profiles` | chat (Aura), resultado de escaneo, inicio de ciclo |
| **HESTIA** | Surtido y carrito | productos con `stock > 0`, **precio al público**, motivo de match; `no_products` si no hay | `productos` (+ ATENA) | chat, tienda, rutina del ciclo |
| **HERMES** | Cumplimiento | salón cercano, disponibilidad, **punto de entrega/retiro y estado del pedido** | `bookings`, `perfiles_prestador` (PostGIS), `pedidos` | chat, checkout, panel del prestador, **job de estados** |
| **CHRONOS** | Continuidad | momento de recompra, rutina am/pm, hitos 15/30 días | `glow_cycles`, `bookings` | ciclo, notificaciones, **job nocturno** |
| **VALKYRIE** | Economía del salón | demanda por día, **stock muerto**, promo y precio sugeridos (con tope y vigencia) | `bookings`, `productos`, `pedidos` | panel del prestador, job semanal |
| **AURA** | Interfaz | conversación + ejecución de herramientas | los 5 + RAG | chat cliente/prestador |

**La función que falta en el circuito**: nadie es dueño del **ciclo de vida del pedido** (creado → pagado → preparando → listo → entregado → cerrado | expirado | cancelado), con incidencias y entrega. Dos opciones — **decisión D-10**:

- **Extender HERMES** con esa responsabilidad (es quien ya tiene logística y geografía). *Recomendado*: un agente menos que mantener, contrato coherente.
- Crear un sexto agente de cumplimiento (nombre propio). Útil solo si el negocio quiere un dominio separado con su propio equipo.

---

## 4. Máquina de estados del pedido (la espina de la reingeniería)

| Estado | Quién lo pone | Regla |
|---|---|---|
| `BORRADOR` | cliente | carrito, no existe en BD |
| `INTENCION_PAGO` | backend | **reserva stock con expiración** (D-04) — aún no descuenta definitivo |
| `PAGADO` | **webhook verificado** (idempotente) | único camino. Se escribe la referencia de pago |
| `EN_PREPARACION` | prestador | el salón alista |
| `LISTO` / `ENTREGADO` | prestador (o HERMES) | entrega/retiro; **dispara la liquidación** (D-07) |
| `CERRADO` | job | tras la ventana de disputa |
| `EXPIRADO` | job | libera stock y cierra la intención |
| `CANCELADO` / `EN_DISPUTA` | cliente/admin | reutiliza `saldo_en_disputa` del wallet |

Regla dura: **ningún estado se escribe desde el cliente**; el pago solo lo mueve el webhook; el stock solo se descuenta definitivo en `PAGADO`; la liquidación solo en `ENTREGADO`.

---

## 5. Decisiones que necesito de ti (con recomendación)

| # | Decisión | Recomendación | Por qué |
|---|---|---|---|
| **D-01** | ¿Quién cobra al cliente: GlowApp (marketplace) o cada salón? | **GlowApp cobra y liquida al prestador** con el wallet existente | ya tiene escrow, retiros, disputas y datos bancarios; cobrar por salón sería construir un segundo sistema de pagos |
| **D-02** | ¿Cómo se entrega? | **Entrega/retiro en el salón** primero; domicilio después con costo configurable | usa una capacidad que ya existe (el salón y la cita); hoy el envío son 12.000 fijos en el código (`orderController.js:124`) |
| **D-03** | ¿De quién es el catálogo? | **Híbrido**: catálogo global de GlowApp + catálogo por salón (insumos y propios), con `tipo_visibilidad` como ya está | el esquema ya distingue `PUBLICO`/`INSUMO_PRESTADOR`; falta dueño por fila |
| **D-04** | Política de stock | **Reserva con expiración (15-30 min) + liberación automática** | hoy el stock se descuenta antes de cobrar y no vuelve nunca (G-03) |
| **D-05** | Poder de VALKYRIE | **Propone, no autoriza**: sugiere promo, el salón o el admin aprueba, con tope y vigencia | hoy "autoriza" un 15% desde una consulta fallida (G-07/auditoría de agentes) |
| **D-06** | Devoluciones de producto | Reutilizar `disputes` + `saldo_en_disputa` con ventana y causal explícitas | el mecanismo ya existe para servicios |
| **D-07** | ¿Cuándo se le paga al prestador? | **Al entregar**, con la ventana de disputa existente (`wallet_ventana_pendiente_horas`) | protege al comprador y da al salón una razón para cerrar el pedido |
| **D-08** | Membresías en producto | Fase posterior; dejar el pedido listo para descuentos por membresía | `memberships` ya existe, pero sin núcleo de comercio no hay dónde aplicarlo |
| **D-09** | Catálogo afiliado (`affiliate_products`) | **Misma caja, liquidación aparte** (no mezclar con el wallet de prestadores) | un mismo pedido puede traer producto propio + afiliado; el dinero de terceros no debe caer en el bolsillo del salón |
| **D-10** | ¿Quién ejecuta el cumplimiento? | **Extender HERMES** | ya tiene logística, geografía y agenda |

---

## 6. Plan por fases

### FASE 0 — Verdad y contención *(S · 1-2 días · sin dependencias)*
Detener la hemorragia antes de rediseñar. Cuatro cosas:
1. **Medir el rol de conexión** (`SELECT current_user, rolbypassrls …`) — decide todo el diseño de aislamiento (G-05).
2. **Cerrar G-04**: el guard de `/admin/products` pasa a `admin` (hoy cualquier prestador borra el catálogo).
3. **Bloquear la compra sin pago** (G-02): el checkout deja de descontar stock y crea una *intención* — no se puede ampliar la fuga mientras se diseña la solución.
4. **Respuestas de decisión** D-01 a D-04 (sin ellas no se puede diseñar el núcleo).

**Aceptación**: existe evidencia de las 4; ningún pedido nuevo descuenta stock sin pago; el catálogo no es escribible por no-admin.

### FASE 1 — Núcleo de comercio *(L · el corazón de la reingeniería)*
Un solo modelo de orden con `tenant_id` + RLS, y el dinero reutilizando lo que ya existe:
- tabla `pedidos` unificada (absorbe `pedidos_tienda` y `booking_productos`), con `origen`, `booking_id` opcional, `tenant_id`, `referencia_pago`, `external_id`;
- `payment_intents` + webhook Wompi **verificado por firma e idempotente** (mismo patrón que `bookingRoutes.js:28`);
- reserva de stock con expiración y liberación (job);
- liquidación al prestador **al entregar**, escribiendo en `provider_wallet`/`wallet_transactions` por tenant;
- migración con **doble lectura** (`pedidos_tienda` sigue respondiendo mientras convive) — nunca big-bang;
- traza de estados auditable (`pedido_eventos`: quién, cuándo, por qué) — el mismo principio que `rag_query_logs`.

**Aceptación**: (a) un pago confirmado por webhook mueve el pedido sin intervención del cliente; (b) repetir el webhook no duplica; (c) un pedido impago expira y **devuelve el stock** (test que cuenta stock antes/después); (d) cero pedidos `PENDIENTE_PAGO` más viejos que la ventana; (e) aislamiento verificado con un tenant distinto.

### FASE 2 — El circuito 360 *(M · aquí se ve el negocio como unidad)*
Conectar los eslabones que ya existen:
- `scan_product_matches` → **carrito sugerido**: el diagnóstico ya trae `match_score` y `reasoning`; convertirlo en "comprar mi rutina" es traducir, no inventar;
- `glow_cycles.recommended_product_ids` → carrito de la rutina, y CHRONOS marca **cuándo** recomprar;
- compra **con cita** aplicando `precio_con_reserva` y entrega en el salón (HERMES);
- una sola superficie de compra reutilizada por chat (Aura), tienda, dashboard del prestador y panel admin — **un núcleo, muchas puertas**;
- `origen` en cada pedido (`rutina`, `diagnostico`, `chat`, `tienda`, `cita`) para poder medir qué eslabón vende.

**Aceptación**: un usuario con diagnóstico y ciclo activo recibe en el chat un carrito sugerido con los mismos productos que el match; se ve la conversión por `origen`.

### FASE 3 — Inteligencia y economía *(M)*
- **VALKYRIE con límites** (D-05): demanda, stock muerto (>60 días), promo **propuesta** con tope y vigencia, con aprobación del salón;
- **unit economics por pedido, por prestador y por tenant**: margen, comisión, costo de entrega, IVA, devoluciones;
- observabilidad del comercio (mismo patrón que RAG): transiciones, tiempos por estado, pedidos por origen, tasa de expiración;
- catálogo de KPIs 360 (abajo) instrumentado en el panel admin.

**Aceptación**: VALKYRIE no puede autorizar nada sin aprobación (test que lo demuestra) y el panel muestra margen por pedido con datos reales.

### FASE 4 — Escala multi-salón *(L)*
Catálogo por salón con dueño por fila, insumos y precios propios, wallet por tenant con retiros independientes, reglas de afiliados (D-09) y RLS sin `BYPASSRLS` en todo el camino.

### FASE 5 — Confianza *(M)*
Devoluciones y garantía con `saldo_en_disputa`, facturación/IVA correctos, y auditoría de cambios de precio y stock (quién cambió qué y por qué).

---

## 7. KPIs 360 (cómo se mide que esto funciona)

| Dimensión | Indicador | De dónde sale |
|---|---|---|
| Conversión por eslabón | diagnóstico → match → carrito → pago → entrega | `origen` en `pedidos` |
| Economía unitaria | margen, comisión, envío, IVA por pedido y por tenant | `pedidos` + `wallet_transactions` |
| Inventario | rotación, stock muerto >60 días, tasa de expiración de reservas | `productos.stock` + `pedido_eventos` |
| Continuidad | recompra a 30/60/90 días, cumplimiento de rutina | CHRONOS (`glow_cycles.checkin_history`) |
| Salud del marketplace | pedidos con cita vs sin cita, comisión causada vs liquidada | `pedidos` + `provider_wallet` |
| Aislamiento | 0 filas visibles de otro tenant en cada superficie | pruebas por rol y tenant |

---

## 8. Qué NO hacer

1. **No crear un segundo motor de pedidos**: si aparece `pedidos_v2`, la reingeniería falló.
2. **No construir un cobro por salón** (D-01) mientras el escrow de GlowApp funciona.
3. **No migrar de golpe**: siempre doble lectura + migración con evidencia de filas contadas.
4. **No poner la inteligencia en el frontend**: los agentes deciden en el backend; la app solo muestra.
5. **No dejar la tienda fuera de RLS**: si algo no puede vivir con `tenant_id`, es que el diseño está mal.
6. **No activar la compra para usuarios sin que Fase 1 esté cerrada** (hoy se puede comprar sin pagar).

---

## 9. Secuencia propuesta de PRs

```
PR #13  FASE 0  contención + medición del rol            ← puede empezar ya
PR #14  FASE 1a núcleo de pedidos + estados + stock       ← depende de D-01/D-03/D-04
PR #15  FASE 1b cobro verificado + liquidación al entregar ← depende de D-07
PR #16  FASE 2  circuito 360 (match, ciclo, cita, origen)  ← depende del PR de agentes
PR #17  FASE 3  VALKYRIE con límites + economía unitaria   ← paralelizable con #16
PR #18  FASE 4/5 multi-salón, afiliados, confianza
```

**Lo único que bloquea el arranque es Fase 0**, y no depende de ninguna decisión de negocio excepto D-01… D-04 para poder diseñar Fase 1. Las demás decisiones las puedes tomar en paralelo.
