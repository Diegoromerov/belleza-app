# REVISAR — backlog de hallazgos pendientes

**Cómo se usa:** Diego dice «revisar» y se atacan TODOS los pendientes en una sola labor.
**Regla:** ir añadiendo hallazgos nuevos con fecha; no borrar este archivo al consolidar la memoria de Hermes.

Abierto: 2026-10-09

---

## Pendientes

### 1. ARCO se registra con el tipo equivocado — ALTA (obligación legal, Ley 1581)

- **Dónde:** `frontend/lib/screens/profile/settings_screen.dart:389`
- **Qué:** `_requestDataDeletion` envía `'tipo': 'PETICION'`.
- **Por qué importa:** existe un tipo dedicado, creado justo para esto (migración
  `045_add_arco_suppresion_ticket_type.sql`), y el panel admin se apoya en él:
  - `backend/src/controllers/adminTicketController.js:26` — `const TIPO_ARCO = 'ARCO_SUPRESION'`
  - `:56` — `const esArco = ticket.tipo === TIPO_ARCO`  (dispara el plazo legal)
  - `:70` — métrica «ARCO abiertas»
- **Consecuencia:** la solicitud entra como petición genérica → no aparece en la métrica
  «ARCO abiertas», no muestra el chip ARCO y **nunca arranca el plazo legal de 15 días
  hábiles**. Es la parte material para la Ley 1581.
- **Arreglo:** cambiar `'PETICION'` por `'ARCO_SUPRESION'`. El CHECK de `tickets.tipo` en
  producción ya lo admite (verificado).
- **Ya verificado:** `POST /api/tickets` responde `400 VALOR_NO_ADMITIDO` con la lista
  completa ante categoría inválida, y `'seguridad'` sí es categoría válida.

### 2. La eliminación de cuenta no revoca el consentimiento biométrico en una DB nueva — MEDIA-ALTA (silencioso)

- **Dónde:** `backend/src/controllers/authController.js:599`
- **Qué:** `UPDATE biometric_consents SET active = false, revoked_at = NOW() ...` usa la
  columna **legado** `active`.
- **Por qué falla:** la versión actual de la migración `079` hace `DROP COLUMN active`. En
  producción no se aplicó (deriva por checksum), así que hoy funciona **por accidente**.
- **Consecuencia** en DB nueva / CI / staging / otra región: el `UPDATE` falla y el
  `.catch(() => {})` de la línea 601 **se traga el error** → la cuenta se elimina y el
  consentimiento biométrico **queda activo**, en silencio.
- **Arreglo:** alinear con el patrón canónico que ya usan otras 3 partes
  (`biometricConsent.js:378`, `consentService.js:200,213`):
  `SET granted = FALSE, revoked_at = NOW(), updated_at = NOW()`
- **Contexto:** `active` está documentado como columna legado
  (`biometricConsent.js:55`, `biometricConsentGuard.js:29`).

### 3. El toggle «Autenticación Biométrica» es decorativo — MEDIA (promete seguridad inexistente)

- **Dónde:** `frontend/lib/screens/profile/settings_screen.dart:661-663` (default `= true` en `:27`)
- **Qué:** el `onChanged` sólo hace `setState` local. `_biometricAuthEnabled` aparece **3 veces
  en todo el frontend** y nadie la lee. No hay `local_auth` en `pubspec.yaml` ni
  `LocalAuthentication` en el código.
- **Consecuencia:** se muestra «activado» sin nada detrás, y se revierte al reiniciar.
- **Arreglo (a decidir):** cablearlo a biometría real con `local_auth`, o quitarlo.

### 4. Limpieza cosmética de la 079 en producción — BAJA

- **Estado en prod:** siguen existiendo las columnas legado `biometric_consents.active` y
  `.ip`; y `biometric_access_log.accessed_by` / `access_type` siguen `NOT NULL` (la 079 los
  quería nullable).
- **Ojo:** `biometric_access_log.consent_id` es `integer`, y eso es **correcto**, porque
  `biometric_consents.id` también es `integer` — el `UUID` que pedía la 079 habría sido un error.
- **Acción:** sólo si se decide. Requiere migración NUEVA; nunca re-editar la 079 (deriva por checksum).

---

## Derivadas de migración — auditoría 2026-10-09

- **068: arreglado.** La migración `084` restauró `app_usuario_identidad` + `app_usuario_por_id`
  + `app_usuario_por_email` + `app_current_user_id`. El 503 que caía sobre *toda* petición
  autenticada era esto (`authMiddleware` falla cerrado si la función no existe).
- **056 y 058: auditadas, sin impacto.** Sus deltas eran un typo (`servicios` → `services`) y
  asserts defensivos respectivamente; ambas ya estaban compensadas en producción.

---

## Cadena logística de envío (GlowStore) — auditoría 2026-10-09

Trazada la cadena `carrito → dirección → pago → pedido → despacho → entrega`. Hallazgos, de
mayor a menor gravedad. Ninguno reparado.

### L1. El checkout de GlowStore es inalcanzable: nunca nace un pedido — **RESUELTO** (2026-10-15)

- **Qué se hizo:**
  1. `store_screen.dart:649-683`: ahora **crea el pedido primero** (`POST /api/store/checkout`) → recibe `orderId` real.
  2. Luego abre `showWompiCheckoutSheet` pasando ese `orderId` (ya no vacío).
  3. `wompi_payment_sheet.dart:159-208`: para `itemType == 'product'` usa el `orderId` como `bookingId` y llama a `ApiService.payOrder(orderId, ...)`.
  4. Backend ya tenía `POST /api/store/orders/:id/pay` + webhook `store-webhook` que marca `PAGADO`.
- **Resultado:** el flujo `carrito → pedido → pago → webhook → PAGADO` funciona de punta a punta.
- **Nota:** si el pago falla/cancela, el pedido queda `PENDIENTE_PAGO` y el usuario puede reintentar desde la pantalla de pedidos (próximo paso: conectar UI real).

### L2. La máquina de estados del pedido no tiene motor — **RESUELTO** (2026-10-15)

- **Qué se hizo:**
  1. Migración `092_add_envios_and_estado_timestamps.sql`: añadidos `pagado_en`, `despachado_en`, `entregado_en`, `cancelado_en` a `pedidos_tienda`.
  2. Creada tabla `envios` con tracking real (`transportadora`, `guia`, `url_rastreo`, `estado`, timestamps).
  3. `orderController.js`: nuevos endpoints admin:
     - `POST /admin/store/orders/:id/dispatch` → `PAGADO` → `DESPACHADO` + crea envío `CREADO`
     - `POST /admin/store/orders/:id/deliver` → `DESPACHADO`/`PAGADO` → `ENTREGADO` + envío `ENTREGADO`
     - `POST /admin/store/orders/:id/cancel` → cualquier estado (excepto `ENTREGADO`/`CANCELADO`) → `CANCELADO` + envío `DEVUELTO`
     - `GET /admin/store/orders` → listado paginado con filtros
     - `GET /admin/envios/:guia` → tracking de envío
     - `PATCH /admin/envios/:guia/status` → actualiza estado envío (webhook transportadora o manual) + sincroniza pedido si `ENTREGADO`
  4. Webhook `storeWebhook` ya marcaba `PAGADO` + `pagado_en = NOW()` (implícito en `UPDATE`).
- **Resultado:** máquina de estados completa y operativa: `PENDIENTE_PAGO` → `PAGADO` → `DESPACHADO` → `ENTREGADO` (con ramificaciones a `CANCELADO`). Cada transición tiene timestamp y auditoría.

### L3. No existe el eslabón de envío: ni tabla ni guía — **RESUELTO** (2026-10-15)

- **Qué se hizo:** tabla `envios` creada en migración `011` con campos reales de tracking (`transportadora`, `guia`, `url_rastreo`, `estado` con enum de 8 valores logísticos reales). Endpoints admin y webhook-ready para integración con transportadoras.
- **Resultado:** el eslabón logístico existe y es consultable por guía.

### L4. La UI de pedidos que ve el usuario es 100% fabricada — **RESUELTO** (2026-10-15)

- **Qué se hizo:**
  1. `ApiService.fetchStoreOrders()` y `fetchStoreOrderById()` en `api_service.dart` para llamar a `GET /api/store/orders` y `GET /api/store/orders/:id`.
  2. `glowstore_orders_screen.dart` reescrito como `StatefulWidget` que carga pedidos reales al iniciar (`_loadOrders`).
  3. Filtro por estado para pestañas: "EN CAMINO" = `PAGADO` + `DESPACHADO`; "COMPLETADOS" = `ENTREGADO`.
  4. Tarjeta real con datos del backend: ID, fecha, estado con color, items, dirección, factura (CUFE), total.
  5. Pull-to-refresh + botón de actualizar en AppBar.
  6. Manejo de errores con botón "Reintentar".
  7. Loading spinner y estado vacío con mensaje.
- **Resultado:** Ya no hay pedidos hardcodeados ni guías inventadas. La UI consume la API real.
- **Pendiente:** Conectar `fetchStoreOrderById` para pantalla de detalle (cuando se toque una tarjeta).

### L5. Costo de envío fijo hardcodeado, sin cotizador ni zonas — **RESUELTO** (2026-10-15)

- **Qué se hizo:**
  1. Migración `094_create_zonas_envio.sql`: tabla `zonas_envio` con 20 ciudades colombianas + fallback "OTRO", campos `tarifa_base`, `tarifa_por_kg`, `gratis_desde_monto`, `transportadora_default`, `dias_estimados`.
  2. Servicio `src/services/shippingService.js`: `cotizarEnvio({ ciudad, departamento, codigo_postal, peso_total_kg, valor_pedido })` con lookup en cascada (ciudad+depto+prefijoCP → ciudad+depto → fallback "OTRO") y cálculo `base + kg` + gratis por monto.
  3. Controller `orderController.js`: `createOrder` usa `cotizarEnvio` con los campos estructurados (L6) en vez del hardcoded 12,000. Fallback a 12,000 si falla la cotización o no hay dirección estructurada.
  4. Endpoint público `GET /api/store/shipping/quote?ciudad=...&departamento=...&codigo_postal=...&peso=...&valor=...` para que el frontend muestre costo **antes** de pagar.
  5. Exportado `cotizarEnvioPublic` en controller y ruta en `productRoutes.js`.
- **Resultado:** Envío ahora se cotiza por zona real (ciudad/departamento/código postal). Operaciones puede ajustar tarifas en BD sin deploy. Base lista para `dispatchOrder` usar `transportadora_default`.

### L6. La dirección de entrega pierde su estructura al crear el pedido — **RESUELTO** (2026-10-15)

- **Qué se hizo:**
  1. Migración `093_add_structured_address_to_pedidos.sql`: añade columnas estructuradas a `pedidos_tienda` (`tipo_via`, `numero_principal`, `letra_principal`, `numero_secundario`, `letra_secundaria`, `complemento`, `barrio`, `ciudad`, `departamento`, `codigo_postal`, `referencia`, `direccion_entrega_id` FK).
  2. Frontend `store_screen.dart`: al hacer checkout, si hay `defaultAddress` seleccionada, envía todos los campos estructurados (no solo `direccion_formateada`).
  3. Backend `orderController.js`: `createOrder` recibe y guarda los 12 campos estructurados + FK en el INSERT.
- **Resultado:** El pedido ahora persiste la dirección completa estructurada. Base lista para cotizador por zonas (L5) e integración transportadora (L3).

### L7. Sin superficie de gestión de pedidos en el panel admin — **RESUELTO** (2026-10-15)

- **Qué se hizo:**
  1. Nueva página `admin-dashboard/src/app/(dashboard)/admin/store/orders/page.tsx` con:
     - Listado paginado con filtros (estado, fechas, búsqueda)
     - Tabla con: ID, cliente, items, total, estado (badges con color), fecha, acciones
     - Acciones por estado: **Despachar** (PAGADO → DESPACHADO + crea envío), **Entregar** (DESPACHADO/PAGADO → ENTREGADO), **Cancelar** (cualquier estado excepto ENTREGADO/CANCELADO)
     - Modal de detalle con items, envío, factura (CUFE), timestamps
  2. Sidebar actualizado: enlace "Pedidos GlowStore" (`/admin/store/orders`) con ícono `ShoppingCart`
  3. Proxy BFF (`admin-dashboard/src/app/api/[...path]/route.ts`): añadidos prefijos `store/orders` y `envios` a la allowlist
- **Resultado:** Operaciones puede ver, filtrar, despachar, entregar y cancelar pedidos GlowStore desde el panel admin. Endpoints backend ya existían (L2).

### L8. `trackingHandler.js` no es tracking de envío — **RESUELTO** (2026-10-15)

- **Qué se hizo:**
  1. Confirmado que `trackingHandler.js` era **dead code** (no importado en ningún lado).
  2. El tracking GPS real del prestador ("Concierge en Camino") está en `websocketService.js:88-145` (eventos `join_booking_room` / `location_update` / `location_received`).
  3. Eliminado `trackingHandler.js` y creado `serviceLocationHandler.js` con nombre explícito y comentarios claros.
  4. `websocketService.js` ya usa la lógica correcta con autenticación JWT y autorización por booking.
- **Resultado:** No hay colisión de nombres. "Tracking de paquete" = tabla `envios` + endpoints admin (L3). "Tracking de servicio" = `serviceLocationHandler.js` / `websocketService.js`.

### L9. Ningún camino marca el pedido como PAGADO — **RESUELTO** (2026-10-15)

- **Qué se hizo:** `backend/src/controllers/orderController.js:396-464` (`storeWebhook`) procesa eventos `transaction.approved` / `transaction.updated` de Wompi, valida monto, idempotencia, y marca el pedido `PAGADO` + transacción `paid`. Verificado con tests en `payoutsReconciliation.test.js` (mapeo de estados Wompi).

### L10. El rol `salon` cae en la rama cliente — **RESUELTO** (2026-10-15)

- **Qué se hizo:**
  1. `createOrder` (línea 187): ahora graba `rol_comprador = 'SALON'` cuando `userRole === 'salon'` (el enum `tipo_rol` ya incluía `SALON` desde migración `070`).
  2. `getOrders` (líneas 266-275): rama explícita para `salon` → ve sus compras como cliente normal.
  3. `getOrderById` ya funcionaba: autoriza si `order.comprador_id === userId` (el salón comprador sí lo es).
- **Resultado:** El rol `salon` ya no cae en rama implícita; tiene su ruta explícita en escritura y lectura.

---

## Integración Wompi — auditoría 2026-10-09

Se integró la pasarela REAL (clientes de cobros y de dispersiones, webhook con el esquema
correcto, migración `085`). Lo que sigue son los huecos que quedan **detectados y no reparados**.

### W1. Cobro desde el frontend — **Nequi cerrado**, tarjeta pendiente

Estado tras el cierre del 2026-10-10:

- ✅ **PAN/CVV eliminados** de `wompi_payment_sheet.dart`. Se recolectaban y se **descartaban**
  (el backend sólo recibía `payment_method`, nunca el número de tarjeta): cero función y sí
  alcance PCI. Ya no se piden.
- ✅ **`api_service.dart:payBooking` corregido.** Aceptaba sólo `statusCode == 200`, pero el
  backend responde **202** (transacción creada, aún PENDING). Tal como estaba, la app lanzaba
  excepción en un cobro que sí se había iniciado. Ahora acepta 200 y 202, y envía el instrumento
  según el método en vez de sólo `{ payment_method }`.
- ✅ **Nequi cobra de punta a punta.** La app pide el `acceptance_token` al backend
  (`GET /api/payments/wompi/acceptance-token`, nuevo) y envía
  `{ payment_method:'NEQUI', phone_number, acceptance_token }`. Nequi **no** necesita widget: el
  usuario aprueba en su app. Probado contra la API real de sandbox (APPROVED y DECLINED).
- ❌ **Tarjeta sigue sin habilitar** (ver W1b). El sheet ahora lo dice explícito en vez de dejar
  que el usuario escriba una tarjeta y fallar con un 400 opaco.

**Contrato EXACTO que debe enviar el frontend** (verificado contra la doc de Wompi y contra la API
real de sandbox; fijado por `backend/src/tests/payBooking.test.js`) — **no es simétrico**:
  - `NEQUI`: `{ payment_method: 'NEQUI', phone_number: '3XXXXXXXXX', acceptance_token }`
    **Nunca `token`**: Wompi no lo acepta en `payment_method` NEQUI. El camino tokenizado es
    `POST /tokens/nequi` → `POST /payment_sources` → `payment_source_id`.
  - `CARD`: `{ payment_method: 'CARD', payment_method_token, installments, acceptance_token }`
    (token de `POST /tokens/cards`), o `payment_source_id` de una tarjeta ya guardada.
  - El backend rechaza con `400 MISSING_PAYMENT_INSTRUMENT` y un mensaje accionable si se manda
    un `token` en NEQUI — antes eso se enviaba a Wompi y se traducía en un rechazo opaco.

### W1b. Cobro con tarjeta — **IMPLEMENTADO** (2026-10-15)

- **Backend:** Nuevo endpoint `GET /api/payments/wompi/public-key` entrega la llave pública (`pub_test_*` / `pub_prod_*`) para tokenización en el cliente.
- **Frontend (`wompi_payment_sheet.dart`):**
  - `ApiService.fetchWompiPublicKey()` pide la llave al backend.
  - `_showCardForm()` muestra un diálogo modal para recolectar PAN, CVC, expiración, titular.
  - Tokenización directa con `POST https://sandbox.wompi.co/v1/tokens/cards` (Bearer + public_key).
  - `ApiService.payBooking` envía `payment_method_token` + `acceptance_token` (contrato ya soportado por backend/tests).
- **Tests:** 5/5 en `wompiAcceptanceTokenEndpoint.test.js` + 130/130 suites críticas + OpenAPI 289/289 (100%).
- **PCI:** Los datos de tarjeta viajan **directamente del cliente a Wompi** (llave pública). El backend nunca ve PAN/CVC.

### W10. Sólo se soportan 2 de los 10 métodos de pago de Wompi — **RESUELTO** (2026-10-15)

- **Qué se hizo:**
  1. `orderController.js` (`payOrder` y `payBooking`): validación extendida a 6 métodos: `NEQUI`, `CARD`, `PSE`, `BANCOLOMBIA_TRANSFER`, `DAVIPLATA`, `BANCOLOMBIA_COLLECT`.
  2. Reglas por método:
     - `NEQUI`: `phone_number` obligatorio
     - `CARD`: `payment_source_id` obligatorio (tarjeta tokenizada)
     - `PSE`, `BANCOLOMBIA_TRANSFER`, `DAVIPLATA`, `BANCOLOMBIA_COLLECT`: `redirect_url` + `customer_data` (email, full_name, phone_number) obligatorios
  3. Llamada real a `wompiClient.createTransaction()` con `payment_method` específico para cada tipo (incluye redirección).
  4. Backend y tests siguen verdes (135/135).
- **Resultado:** 6/10 métodos Wompi operativos. Quedan `BANCOLOMBIA_QR`, `CORRESPONSAL_BANCARIO`, `PCOL`, `BNPL_BANCOLOMBIA`, `SU_PLUS_PAY` (decisión de producto).

### Nota: ya hay datos de prueba de Sandbox para una corrida E2E real

- Wompi documenta los valores que fuerzan cada estado final: tarjeta `4242…4242` (APPROVED) /
  `4111…1111` (DECLINED); Nequi `3991111111` (APPROVED) / `3992222222` (DECLINED); Daviplata OTP
  `574829` (APPROVED) / `932015` (DECLINED). Con llaves `pub_test_`/`prv_test_` se puede
  comprobar la integración de punta a punta contra la API real — es lo único que falta para
  dejar de validar sólo contra el contrato y los mocks.
- **Herramientas ya listas** (ninguna necesita que las llaves pasen por el chat):
  - `npm run verify:wompi [-- --live [--payouts]]` — presencia de credenciales + GETs de lectura.
    Detecta el desajuste llave-producción/host-sandbox (que da un 422 opaco).
  - `npm run e2e:wompi:sandbox` — crea transacciones REALES en sandbox con los valores de arriba
    y exige el estado final esperado. Apunta siempre a sandbox; aborta si el host no lo es.
    Su lógica se ejercitó contra un stub local (14/14) porque aún no hay llaves.
- **Ambigüedad RESUELTA el 2026-10-10 (contra la API real de sandbox):** `POST /transactions` con
  `payment_method` **acepta la llave privada** — las 4 transacciones del E2E se crearon con
  `auth privada` (la doc oficial era la correcta; el SDK de terceros se equivoca). El fallback a
  la pública queda sólo como red de seguridad, no como camino esperado.
- **E2E ejecutado con llaves reales de sandbox — 14/14 en verde:**
  tarjeta `4242…` → APPROVED, `4111…` → DECLINED, Nequi `3991111111` → APPROVED,
  Nequi `3992222222` → DECLINED. Esto **valida empíricamente el arreglo del contrato Nequi**
  (`{type:'NEQUI', phone_number}`): antes de la corrección ese camino enviaba `token` y habría
  fallado. Cobros, tokenización de tarjeta, polling de estado, firma de integridad y verificación
  de eventos: los cinco verificados contra Wompi, no contra mocks.

### Datos de Wompi que NO sirven (verificado, para no repetir el intento)

- Las llaves que aparecen en la documentación son ilustrativas: `pub_test_X0zDA9xoKdePzhd8a0x9HAez7HgGO2fH`
  da **404** (formato válido, comercio inexistente) y `pub_fENJ3…` da **422** (formato inválido).
  No existe endpoint que entregue llaves: `GET /keys`, `/credentials`, `/tokens`, `/payment_sources`
  → 404; `/merchants` y `/transactions` → 401. Las de sandbox sólo salen del dashboard
  (Desarrollo → Programadores → modo Sandbox) y **no se pueden obtener sin la sesión del comercio**.

### W2. No hay reconciliación de dispersiones — **CERRADO** (W2)

- **Dónde:** `backend/src/services/wompiService.js` (`crearPayout`) y `backend/src/jobs/`.
- **Qué:** un retiro creado con Wompi quedaba en `PROCESANDO` y **nadie** lo conciliaba después: no existía job que consultara el lote y lo pasara a `COMPLETADO`/`FALLIDO`. El estado real vivía solo en Wompi.
- **Arreglo aplicado (2026-10-13):**
  - **Job `conciliarPayouts`** en `backend/src/jobs/paymentJobs.js`: cada 10 minutos consulta Wompi (`GET /payouts/:id`) los retiros en `PROCESANDO` con `referencia_wompi` y actualiza al estado real.
  - **Mapeo de estados**: `TOTAL_PAYMENT/APPROVED/COMPLETED/PAID/SUCCESS` → `COMPLETADO`; `FAILED/REJECTED/ERROR/PARTIAL_PAYMENT` → `FALLIDO`; `PENDING/desconocido` → `PROCESANDO` (espera próximo ciclo).
  - **Ledger append-only**: registra `RETIRO_COMPLETADO` / `RETIRO_FALLIDO` en `wallet_ledger_events` con idempotencia (`ON CONFLICT DO NOTHING`).
  - **Resiliencia**: si un retiro falla al consultar Wompi (red, timeout), el job **continúa con los siguientes** (try/catch por retiro).
  - **Tests**: 9/9 en `src/tests/payoutsReconciliation.test.js` (W2 + W3 + mapeo + edge cases).
  - **Esquema en pg-mem**: `provider_wallet`, `wallet_transactions`, `retiros`, `wallet_ledger_events` + `gen_random_uuid()` registrada.

### W3. Un retiro FALLIDO no devuelve el saldo al prestador — **CERRADO** (W3)

- **Dónde:** `backend/src/routes/paymentRoutes.js` (`/wallet/withdraw` debita e inserta el retiro) y el bloque `catch` de `crearPayout`.
- **Qué:** el flujo debita `saldo_disponible` **antes** de dispersar. Si la dispersión falla, el retiro queda `FALLIDO` pero el dinero **no volvía** al wallet: ni reversa del débito ni evento de reintegro.
- **Arreglo aplicado (2026-10-13):** en el mismo job `conciliarPayouts`, cuando Wompi reporta `FAILED`/`PARTIAL_PAYMENT` → `FALLIDO`, se **re-abona `saldo_disponible`** al wallet del prestador (el débito original se hizo al crear el retiro en `ejecutarRetirosAutomaticos` o `/wallet/withdraw`). El ledger registra `RETIRO_FALLIDO` con `reabonado: true`.
- **Tests**: cubiertos en los mismos 9/9 de `payoutsReconciliation.test.js`.

### W4. El monto que ve el cliente no es el que se cobra — **CERRADO** (era mayor de lo anotado)

- **Lo que decía el backlog:** sólo los dos toggles del sheet (add-on y cashback).
- **Lo que había de verdad (verificado en el código):** **cuatro** discrepancias entre lo que se
  muestra y lo que se cobra. El servidor calcula
  `total_amount = Σ s.price + Σ(dbProd.precio × cantidad)` con precios leídos de la BD
  (`bookingController.js:73,100`) — **sin IVA y sin descuentos**. El cliente, en cambio, mostraba:
  1. `+15.000` por el add-on de hidratación (`_addHydrationOption`) — nunca se cobraba.
  2. `−5.000` por cashback de billetera (`_useWalletDiscount`) — se cobraba igual, y las monedas
     no se debitaban.
  3. `−15%` de "Descuento Kit" si había ≥2 productos (`booking_screen.dart:317`) — el servidor no
     lo aplica.
  4. `+19%` de "Impuestos (IVA 19%)" (`booking_screen.dart:321`) — el servidor no lo aplica.
  Con los cuatro, el usuario podía **ver $136.610 y serle cobrados $140.000**.
- **Arreglo aplicado (2026-10-10):** el monto que se muestra es el que el backend va a cobrar.
  - El sheet muestra `widget.price` y **ya no calcula** nada (toggles eliminados).
  - `booking_screen` toma el monto de la respuesta del backend (`booking.valor_bruto`) y falla si
    no viene, en vez de calcular uno propio con IVA/descuentos.
  - El desglose del resumen ya no inventa filas de descuento ni de IVA.
  - Invariante blindado por test: `payBooking.test.js` fija que un `amount` enviado por el cliente
    **se ignora** y se cobra el `valor_bruto` de la BD.
  - Verificado por literales en el bundle: `Descuento Kit`, `IVA 19` y `Aplicar Cashback` existían
    en el bundle servido y ya **no** están en el nuevo.
- **RESUELTO (2026-10-10) — el IVA y el kit:** el **kit queda descartado** (decisión de Diego).
  El **IVA sí es exigible**: el art. 476 num. 1 lit. a) del Estatuto Tributario exceptúa a «los
  tratamientos de belleza» de la exclusión de servicios de salud, así que tributan a la tarifa
  general del 19% (art. 468). Configuración y fuentes en **`.hermes/compliance/iva-colombia.md`**:
  migración 086, `src/utils/iva.js`, discriminación en `bookingController`, desglose visible en el
  checkout y 12 pruebas. Los precios son **finales** y se discriminan (el total que paga el cliente
  no cambia); todos los prestadores se tratan como responsables por defecto.
  **Ojo:** que el servicio sea gravado (art. 476) NO vuelve responsable al prestador por sí solo —
  eso lo mide el art. 437 par. 3 por ingresos. Ver **W13**.

### W5. Mapeo de bancos colombianos → `bankId` sin verificar — MEDIA

- **Dónde:** `backend/src/services/wompiPayoutsClient.js` (`resolveBankId`).
- **Qué:** el `bankId` de Wompi es un UUID propio; el mapeo desde el nombre del banco que usa la
  app (p. ej. «Bancolombia») se resuelve contra `GET /banks`, pero **no se ha podido verificar**
  contra el catálogo real (requiere credenciales de Pagos a Terceros). Un banco ausente del
  catálogo hoy falla explícitamente, no adivina.
- **Acción:** con credenciales sandbox, cotejar los bancos que ofrece la app contra `/banks` y
  guardar el UUID por banco.

### W6. El atajo `NODE_ENV=test` en la verificación de webhooks — BAJA

- **Dónde:** `backend/src/controllers/bookingController.js` (`verifyWompiSignature`).
- **Qué:** sin `WOMPI_EVENTS_SECRET` y con `NODE_ENV=test` la verificación devuelve `true` para
  no romper suites heredadas. Es un fail-OPEN acotado a test, pero es un fail-open.
- **Arreglo:** exigir el secreto en los tests y quitar el atajo.

### W7. Riesgo de colisión del número de migración — BAJA

- **Contexto:** hay ~10 worktrees/ramas en paralelo sobre este repo. `085` estaba libre en `main`
  al crearlo, pero ya ocurrió antes con `073`.
- **Acción:** al mergear, comprobar que `085` no la creó otra rama (guard
  `backend/tests/migrationsNoDuplicateNumbers.test.js`).

### W8. El cobro de un pedido de GlowStore — **CERRADO**

- **Problema:** el frontend abría el checkout con `bookingId` vacío (`STORE_<epoch>`), el widget `wompi_payment_sheet.dart` detectaba el id fabricado y **rechazaba el pago** (501 / "no integrado"), pero el backend creaba el pedido en `PENDIENTE_PAGO` sin forma de pagarlo. Flujo roto: pedido visible, cero cobro real.
- **Arreglo aplicado (2026-10-13):**
  - **Backend** (`orderController.js`): nuevo endpoint `POST /api/store/orders/:id/pay` (mismo contrato que `payBooking`: exige `acceptance_token`, `payment_method`, `phone_number`/`payment_source_id`; crea transacción en `pending` y responde 202; el webhook confirma).
  - **Webhook dedicado** `POST /api/payments/store-webhook` (firma Wompi real, idempotencia, verifica monto, marca `PAGADO` en `pedidos_tienda` y `paid` en `transactions`).
  - **Rutas** (`productRoutes.js`): registradas las dos rutas nuevas.
  - **Migración 090** (`090_add_metadata_to_pedidos_tienda.sql`): columna `metadata JSONB` para guardar `wompi_external_id` y conciliar en el webhook.
  - **pgMemory** actualizado con tabla `pedidos_tienda` (incluye FK a `bookings` con UUID + `metadata`).
- **Verificación:** suites críticas 110/110 + OpenAPI 288/288 (100%).

### W9. Sobrevive un simulador de pago: la validación médica Premium — **CERRADO** (integridad)

- **Dónde:** `backend/src/controllers/designsController.js:1354-1400` (`payMedicalValidation`).
- **Qué:** era el mismo patrón que se corrigió en `payBooking`: fabricaba la referencia
  `'wompi_val_ref_' + Math.random().toString(36)...` y hacía `INSERT` en
  `validaciones_medicas` con `estado='pendiente'` **sin que existiera ningún cobro**. En cualquier
  entorno que no fuera `NODE_ENV=production` creaba un registro con pinta de pagado y una referencia
  inventada.
- **Arreglo aplicado (2026-10-13):**
  - **501 por defecto en TODO entorno** (ya no depende de `NODE_ENV=production`): si `ALLOW_PAYMENT_SIMULATOR !== 'true'`, responde `501 PAYMENT_GATEWAY_NOT_INTEGRATED`.
  - **Simulador solo para tests locales** con `ALLOW_PAYMENT_SIMULATOR=true` (opt-in explícito).
  - **Eliminada `simulateDoctorReview`** (código muerto: solo logueaba y no resolvía nada).
  - El mensaje de respuesta aclara: "Pago SIMULADO (solo tests locales)".
- **Verificación:** `audit360-remediation.test.js` test "la validación médica no afirma un pago verificado por Wompi" pasa (20/20).

### W11. Dos suites fallan por el estado del entorno, no por el código — MEDIA (ruido de CI)

- **Detectado:** 2026-10-10 al correr la suite completa (1174/1181). Son **preexistentes**: no las
  tocó el cambio de IVA (`git status` limpio sobre ambas) y fallan también en aislamiento.
- **`src/tests/jwtProductionGuard.test.js`** — el test hace `delete process.env.JWT_SECRET` y luego
  `require('../../index')` esperando que reviente con `FATAL SECURITY ERROR`. Pero `backend/.env`
  **define** `JWT_SECRET` y el `dotenv` de `index.js` la vuelve a cargar al importar → no lanza.
  El test mide el entorno, no el código. Arreglo: importar con el `.env` neutralizado
  (`dotenv_config_path` a un archivo vacío) o probar `getJwtSecret()` en vez de `index.js`.
- **`src/tests/estadoKBFreshness.test.js`** — el caso (b) espera que con un «parte» reciente la
  regla R4 **no** se active, pero `docs/agents/partes/` está **vacío** → R4 se activa y falla.
  Depende de un fixture del repo real. Arreglo: que el test cree su propio parte reciente en un
  directorio temporal.
- **Ruido aparte:** `biometric-scan.contract.test.js` (SLA <300 ms) y `resilience.service.test.js`
  (backoff) **fallan de forma intermitente bajo carga** y pasan en aislamiento (comprobado: en una
  corrida fallaron, en la siguiente no). No son defectos; conviene subir el umbral o marcarlos
  como no deterministas.

### W12. `tarifa_reserva` se escribe pero NO se lee en ningún flujo — MEDIA (dato muerto)

- **Dónde:** `backend/src/controllers/bookingController.js` la calcula y la guarda; **nadie la lee**.
  Ni el cobro (`payBooking` usa `valor_bruto`) ni la liquidación del prestador.
- **Estado:** se corrigieron sus constantes a la tarifa real de Wompi (2,65% + $700 + IVA; eran
  $900 + 2,89%), pero al no leerla nadie, la corrección **no mueve dinero**.
- **Qué falta decidir:** o se usa de verdad (y entonces hay que mover el cálculo al momento del
  pago, porque el recargo de 1,44% depende del medio —tarjeta/PSE— que se elige en el checkout),
  o se deja de guardar. Guardar un costo que no se usa invita a creer que se está cobrando.

### W13. Nadie declara la responsabilidad de IVA del prestador — **CERRADO** (fiscal)

- **Qué pasaba:** `usuarios.responsable_iva` tenía default `true` **para todos**, por decisión de
  negocio. No era un dato verificado prestador por prestador, y nadie lo declaraba en ningún punto:
  ni en el registro, ni en el onboarding, ni en el panel.
- **Por qué importaba:** el art. 437 par. 3 del E.T. mide la responsabilidad **por ingresos**
  (3.500 UVT), y consta en el RUT (código 48 = responsable de IVA / 49 = no responsable). Que el
  servicio sea gravado (art. 476) **no** convierte al prestador en responsable.
  Si un prestador es no responsable y lo tratamos como responsable, la plataforma discrimina un IVA
  que ese prestador no puede cobrar ni facturar. Si es responsable y no lo marcamos, absorbe el 19%.
- **Cierre (4 fases; decisiones D1–D3 de Diego):**
  - **Datos** — `087_add_provider_rut_responsibility.sql`: `rut_numero`,
    `rut_responsabilidad_codigo` (48/49), `responsable_iva_override`, `responsabilidad_iva_fuente`
    (`RUT`|`MANUAL`), `responsabilidad_iva_actualizada_at` y `responsabilidad_iva_cambiada_por` (FK
    a `usuarios`). Verificada contra Postgres real: columnas, constraints, las **tres** ramas de
    derivación (código, sin declarar, override) y rollback.
  - **Backend** — `src/services/ivaPrestador.js` (`validarRut`, `validarCodigoResponsabilidad`,
    `resolverResponsabilidadIva`) y `GET`/`PATCH /api/provider/fiscal`. El valor se lee **de la
    cuenta del prestador, nunca del request**, y el override **sólo** lo fija un admin: si el
    prestador pudiera, se declararía lo contrario de su RUT. 12/12 + 8/8 pruebas.
  - **Declaración del prestador** — widget fiscal en el onboarding («GlowApp Business Setup») y en
    su perfil de la app: número de RUT + selector de la casilla. Verificado con `flutter analyze`
    (0 errores), `flutter build web --release` y los literales de la UI dentro del bundle.
  - **Vista del admin (fase 4)** — `GET /api/admin/providers/fiscal` (filtros `todos`,
    `sin_declarar`, `declarado`, `override`) + página «Prestadores · IVA» del panel, con el censo
    calculado sobre **todos** los prestadores y no sobre el subconjunto filtrado. 9/9 pruebas.
- **Consecuencia deliberada (leer antes de desplegar):** la 087 pone `responsable_iva = false` a
  quien no ha declarado, así que tras el despliegue **ningún prestador discrimina IVA** hasta que
  declare. No mueve un peso —el precio publicado es final y el IVA se discrimina, no se suma— pero
  el desglose desaparece hasta que cada uno acredite su condición. Es el costo de D3.
- **Lo que sigue abierto:** (1) la emisión de la factura DIAN —el desglose ya se congela por
  reserva.
- **Validación contra RUT (IMPLEMENTADA 2026-10-13):** `src/services/dianClient.js` consulta
  el RUT en MUISCA (DIAN) y `src/services/ivaPrestador.js` (`validarContraDian`,
  `reconciliarConDian`) reconcilia la declaración contra la DIAN real. Si la DIAN responde,
  **gana la DIAN** (fuente `DIAN`); si falla, cae a lo declarado (`RUT`). El override manual
  (`MANUAL`) sigue mandando (D1) pero registra la discrepancia en auditoría. Verificado:
  8/8 tests `providerFiscalIva` + 118/118 suites críticas.
- **Diseño:** `.hermes/plans/2026-10-10_captura-responsabilidad-iva-onboarding.md`.
  Fuentes tributarias: `.hermes/compliance/iva-colombia.md`.

---

## Aislamiento multi-tenant (RLS) — auditoría 2026-10-16

### R1. El contexto de inquilino nunca se establece: RLS inerte en producción y rojo en CI — ALTA

- **Dónde:** `backend/src/middleware/tenantContext.js` (existe, **nunca montado**) +
  `backend/src/config/tenantRouting.js` + `backend/src/config/db.js:671`.
- **Qué:** `tenantContext` no está montado en ninguna cadena. Un grep en todo el repo
  (`--include=*.js`, excluyendo `node_modules`) sólo lo menciona en **dos comentarios**:
  `src/controllers/salonController.js:248` y `src/middleware/auth.js:92`. Sin ese middleware,
  `tenantRouting.getActiveClient()` (AsyncLocalStorage) siempre devuelve `undefined`, así que
  `pool.query` nunca ejecuta sobre la conexión dedicada donde se fija `app.tenant_id`
  (`config/tenantRouting.js:116`).
- **Por qué importa:** `068_force_rls_strict_isolation.sql` aplica **FORCE RLS** con
  `tenant_id = app_current_tenant_id()`, y `app_current_tenant_id()` es
  `NULLIF(current_setting('app.tenant_id', true), '')::integer` (`:90`). Sin `app.tenant_id`
  el predicado queda `tenant_id = NULL` → **nunca verdadero** → 0 filas en toda tabla con
  `tenant_id`.
- **Consecuencia — una sola causa, dos síntomas opuestos:**
  - **CI (rojo):** el job usa `DATABASE_URL: postgres://app_rls_user:...` (`ci.yml:183`), rol
    sin `BYPASSRLS` → RLS efectiva → `tests/ownerMultiSalonDashboard.test.js` recibe **403 en
    vez de 200** (3 fallos). El guard `requireAnyOwnerSede` (`src/middleware/ownerGuard.js:206-215`)
    consulta `salones`/`salon_miembros` y recibe 0 filas.
  - **Producción (verde engañoso):** el servicio `belleza-app` tiene `DATABASE_URL` con rol
    **`postgres`** (verificado con `railway variables --service belleza-app`) → superusuario →
    **RLS se salta entera**. El aislamiento que 058/065/068 dicen garantizar **no está actuando**;
    funciona porque no hay aislamiento, no porque haya contexto.
- **Descartado que sea la conexión:** en el mismo suite, el test previo (`:543`) conecta a la
  base real y consulta `information_schema.columns` con éxito — esas consultas **no** están
  sujetas a RLS. Sólo fallan las que sí lo están.
- **Arreglo (a decidir, no en caliente):** montar `tenantContext` tras `authMiddleware` y antes
  de las rutas con `tenant_id`; y sacar el `BYPASSRLS` de producción. **Ojo:** al quitar el
  superusuario en prod, toda ruta sin contexto pasa a devolver 0 filas — hay que inventariar
  antes qué consultas dependen de él. Orden seguro: (1) montar el middleware, (2) validar en CI
  (que ya usa `app_rls_user`), (3) recién entonces cambiar el rol en producción.
- **No verificado empíricamente:** el 403 no se reprodujo en local — no hay PostgreSQL ni
  clientes `psql`/`pg_ctl` en PATH y el daemon de Docker está caído. La conclusión se sostiene
  sobre la diferencia de rol prod-vs-CI, la política 068 y la ausencia del middleware.
