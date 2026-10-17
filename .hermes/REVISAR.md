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

### W10. Sólo se soportan 2 de los 10 métodos de pago de Wompi — **RESUELTO** (2026-10-16)

- **Cierre previo era falso (2026-10-15).** Se marcó resuelto al extender la *validación* a 6 métodos,
  pero los métodos de redirección eran **incompletables**: `wompiClient.createTransaction()` devolvía
  sólo `{id, status, reference, amountInCents, paymentMethodType, statusMessage}` y **descartaba**
  `payment_method.extra.async_payment_url`, que es donde Wompi publica la URL que el usuario debe abrir
  para autorizar. El controlador tampoco la reenviaba. Resultado: PSE/Bancolombia/Daviplata creaban una
  transacción `PENDING` sin ninguna vía para pagarla — el cliente se quedaba en un callejón sin salida.
  Aceptar un método ≠ poder cobrarlo.
- **Causa raíz corregida:**
  1. `src/services/wompiClient.js`: `createTransaction()` y `getTransaction()` exponen
     `asyncPaymentUrl`, extraído por `_extraerAsyncPaymentUrl()` de `payment_method.extra.async_payment_url`
     (con tolerancia a la forma aplanada). Devuelve `null` cuando Wompi no la manda — nunca se inventa una URL.
  2. `src/controllers/bookingController.js` (`payBooking`): la respuesta 202 incluye `async_payment_url`,
     y el `message` distingue redirección de cobro directo.
  3. `src/controllers/orderController.js` (`payOrder`): igual, dentro de `data`.
  4. Validación de `redirect_url` + `customer_data` (email, full_name, phone_number) — y
     `customer_data.financial_institution_code` en GlowStore — previa a llamar a Wompi.
- **Métodos operativos en backend:** `NEQUI`, `CARD` (directos) y `PSE`, `BANCOLOMBIA_TRANSFER`,
  `DAVIPLATA`, `BANCO_DE_BOGOTA_TRANSFER`, `BANCO_DE_OCCIDENTE_TRANSFER`, `BANCO_AV_VILLAS_TRANSFER`,
  `BANCO_POPULAR_TRANSFER`, `BANCO_PICHINCHA_TRANSFER` (redirección). Sin `async_payment_url` ninguno
  de los de redirección sirve.
- **Verificación:** `src/tests/payBooking.test.js` (+4 casos: PSE devuelve la URL, NEQUI devuelve `null`,
  PSE sin `redirect_url` 400, PSE sin `customer_data` 400) y `src/tests/wompiClient.test.js`
  (+4 casos, incluido el parseo de la forma documentada). OpenAPI 296/296 en sincronía.
- **UI Flutter — HECHA (2026-10-16).** `frontend/lib/widgets/wompi_payment_sheet.dart`:
  - El estado pasó de `_selectedTab` (índice de pestaña 0=Nequi/1=Tarjeta) a `_metodo` (nombre exacto
    de Wompi). Con más de dos métodos el índice dejaba de mapear 1:1 y cada rama duplicaba el mapa.
  - Selector de método (`Wrap` de chips) con `NEQUI`, `CARD`, `PSE`, `BANCOLOMBIA_TRANSFER`, `DAVIPLATA`.
    Las demás transferencias bancarias se añaden con una línea: la rama de redirección ya es común.
  - `_buildRedirectForm()`: recoge `full_name`, `email`, `phone_number` y, sólo para PSE,
    `financial_institution_code` — exactamente lo que el backend exige antes de llamar a Wompi.
  - Si el backend devuelve la URL, se muestra `_buildRedireccionView()`: deja explícito que el cobro
    **NO está pagado** y entrega el enlace. Si el backend NO la devuelve, se lanza excepción (nunca un
    "éxito" falso).
  - `ApiService.payBooking()` acepta `redirectUrl` y `customerData`.
  - `flutter analyze lib/widgets/wompi_payment_sheet.dart lib/services/api_service.dart`: 0 errores,
    0 warnings (2 `info` pre-existentes de `_showCardForm(context)`).
- **Decisión pendiente (arquitectura, no bug):** el proyecto **no** tiene `url_launcher` ni
  `webview_flutter` (omisión deliberada: `forced_update_dialog.dart` usa el portapapeles "porque no es
  dependencia del proyecto"). Se siguió ese patrón: la URL se copia al portapapeles y se pide abrirla.
  Funciona y no añade dependencias, pero para un pago es UX pobre. Si producto aprueba `url_launcher`,
  el cambio es sustituir `Clipboard.setData` por `launchUrl` en `_mostrarRedireccion()` (un solo punto).
- **Segunda decisión pendiente:** `redirect_url` se fijó a `https://glowapp.co/pago/resultado`
  (`_redirectUrlPago`), apoyado en el dominio público ya usado en
  `provider_detail_screen.dart` (`https://glowapp.co/p/<id>`) y en `FRONTEND_URL` de `backend/.env.example`.
  Requiere una ruta real que reciba el retorno de Wompi; hoy es destino declarado, no una página verificada.
- **Falta:** correr el flujo de redirección contra el sandbox real (`pub_test_`/`prv_test_`) — es lo único
  que prueba que la URL que devuelve Wompi es la que el usuario necesita.

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

### W6. El atajo `NODE_ENV=test` en la verificación de webhooks — **RESUELTO** (2026-10-16)

- **Dónde:** `backend/src/controllers/bookingController.js` y `orderController.js`
  (`verifyWompiSignature`).
- **Qué era:** sin `WOMPI_EVENTS_SECRET` y con `NODE_ENV=test` la verificación devolvía `true`
  para no romper suites heredadas. Fail-OPEN acotado a test, pero fail-open.
- **Arreglo aplicado:** el atajo se eliminó en los DOS controladores. Sin secreto no hay nada que
  verificar y se falla en CERRADO (`wompiClient.verifyEventChecksum` → inválido → 401).
- **Por qué era más que «BAJA»:** el atajo contradecía la sonda de contrato
  (`src/openapi/criticalContract.js`, `POST /api/payments/wompi-webhook` ⇒ 401). En CI —sin
  secreto— el webhook acusaba recibo (200) de eventos sin firma, así que **la compuerta de
  contrato fallaba y abortaba el job ANTES de llegar a la suite completa**. No se veía en local
  porque `.env` define `WOMPI_EVENTS_SECRET` y dotenv no pisa una variable ya presente: mismo
  código, veredicto distinto según el entorno.
- **Verificación:** reproducido con `WOMPI_EVENTS_SECRET=""` (dotenv respeta la variable presente
  aunque esté vacía) → `Expected: 401 / Received: 200`. Tras el arreglo, **49/49 en las dos
  condiciones**, suite completa 160/160, y en CI el paso de contrato ya no falla: el job avanza
  hasta la compuerta completa (138 suites, 1103 tests).
- **Nota:** `src/tests/wompiWebhookSecurity.test.js:148-159` ya esquivaba el atajo cambiando
  `NODE_ENV` a `production` para probar el camino real; ese rodeo queda innecesario.

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
- **`src/tests/jwtProductionGuard.test.js`** — **RESUELTO (2026-10-16)**. Diagnóstico confirmado tal
  como quedó anotado: el test hace `delete process.env.JWT_SECRET` y luego `require('../../index')`
  esperando `FATAL SECURITY ERROR`, pero `index.js:9` ejecuta `require('dotenv').config()` y
  `backend/.env:13` **define** `JWT_SECRET` → la vuelve a cargar → no lanza. El guard es correcto
  (`index.js:15` llama a `getJwtSecret()`; `src/config/jwt.js` lanza en `production` sin secreto o
  con menos de 32 caracteres): lo que estaba mal era el test, que medía el disco y no el código.
  Pasaba en CI (sin `.env`, gitignoreado) y fallaba en local: un verde dependiente del entorno.
  **Arreglo aplicado:** `jest.mock('dotenv', () => ({ config: jest.fn(() => ({ parsed: {} })) }))`
  al inicio del archivo. Verificado **10/10 en verde**, y con JWT_SECRET exportado (el escenario de
  CI) igual.
  **Corrección al procedimiento que quedó escrito aquí:** la vía propuesta
  (`dotenv_config_path` a un archivo vacío) **no sirve** en esta suite — se probó con
  `DOTENV_CONFIG_PATH=/nonexistent/.env` y la suite entera no llega a correr: `src/tests/setupHarness.js:12`
  lanza `"JWT_SECRET environment variable is required but not set"`, porque los `setupFiles` de jest se
  ejecutan **antes** de que nada cargue `.env`. El mock de dotenv sí funciona porque `setupFiles` corre
  antes del archivo de test, así que no le afecta.
- **`src/tests/estadoKBFreshness.test.js`** — no figura en rojo en las corridas completas de
  2026-10-16; se da por resuelto o por fixture ya presente. Re-verificar sólo si reaparece.
- **Ruido aparte:** `biometric-scan.contract.test.js` (SLA <300 ms) y `resilience.service.test.js`
  (backoff) **fallan de forma intermitente bajo carga** y pasan en aislamiento. Comprobado otra vez el
  2026-10-16: en la corrida con `flutter analyze` en paralelo aparecieron rojos; en la corrida limpia,
  no. Son de tiempo, no defectos: conviene subir el umbral o marcarlos como no deterministas.
- **Hallazgo asociado — `setupHarness.js` miente en su comentario (BAJA).** La cabecera dice
  «Fijar JWT_SECRET por defecto para pruebas de Jest si no está definido en el entorno», pero el código
  hace lo contrario: **lanza** si falta. Consecuencia real: `npm test` a secas **no arranca** (0 tests)
  aunque `backend/.env` tenga el secreto, con un mensaje que suena a que hay que configurarlo cuando en
  realidad ya está configurado. **No se cambió**: hacer que el harness cargue `.env` inyectaría
  variables (llaves de Wompi, etc.) en TODAS las suites y podría volver verdes o rojas pruebas que hoy
  dependen de que una variable esté ausente. Es una decisión de política de CI, no un arreglo mecánico.

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
- **Verificación empírica:** ⚠️ en la primera pasada quedó sin reproducir en local (no había
  PostgreSQL ni clientes `psql`/`pg_ctl`, y el daemon de Docker estaba caído), así que la
  conclusión salía de la diferencia de rol prod-vs-CI y de la política 068. **Ya está reproducida
  y medida con Docker — ver `R1-bis` más abajo.**

### R1-bis. VERIFICADO (2026-10-16, con Docker) — y el arreglo queda validado

Reproducido en local con la misma receta que el CI
(`docker run postgis/postgis:16-3.4` + `scripts/prepareRlsDatabase.js`, 13 tablas con FORCE)
y los mismos tres roles:

- **El fallo se reproduce** exactamente igual que en CI:
  `tests/ownerMultiSalonDashboard.test.js` → `Test Suites: 1 failed` · `Tests: 3 failed, 7 passed`,
  los mismos 3 casos con `Expected: 200 / Received: 403`.
- **Política vigente sobre `salones`:**
  `tenant_isolation: (tenant_id IS NOT NULL) AND (tenant_id = app_current_tenant_id())`.
- **Sondas sobre la consulta exacta del guard** (`ownerGuard.js:206-215`):

  | Sonda | Rol (rolbypassrls) | `app.tenant_id` | Filas | Efecto |
  |---|---|---|---|---|
  | A | `app_rls_user` (f) | sin fijar | **0** | el 403 de CI |
  | B | `app_rls_user` (f) | fijado en transacción | **1** | 200 |
  | C | `postgres` (t) | sin fijar | **1** | prod hoy |

  La sonda B sólo devuelve filas **dentro de una transacción real**: con `set_config(..., true)`
  en autocommit el ajuste se evapora con la sentencia — que es justo el defecto #2 descrito en la
  cabecera de `tenantContext.js`.
- **Arreglo validado end-to-end:** añadir `tenantContext` tras `authMiddleware` en las cadenas de
  `src/routes/ownerRoutes.js` (`authMiddleware, tenantContext, requireAnyOwnerSede`) deja el suite
  en **`Test Suites: 1 passed` · `Tests: 10 passed, 10 total`**. El cambio se revirtió después de
  medirlo: `ownerRoutes.js` queda sin tocar.
- **Por qué NO se aplicó:** montarlo sólo en `ownerRoutes` arregla el suite pero deja el resto de
  rutas con `tenant_id` sin contexto — estado a medias. Y en producción abre una transacción por
  petición autenticada esperando el evento `finish` (limitación conocida declarada en la cabecera
  del propio middleware), con efecto real sobre el pool. **Es una decisión de cableado global, no
  un parche de router:** o se monta el contexto en toda la app (y entonces sí tiene sentido quitar
  el superusuario de producción), o se asume que la aplicación no gobierna el aislamiento.

### R1 — estado del pipeline (2026-10-16)

Tras cerrar **W6**, R1 es **el único rojo que queda** en `GlowApp CI / CD Pipeline`
(`Backend Tests & Lint`): los 3 casos de `tests/ownerMultiSalonDashboard.test.js`
(`Expected: 200 / Received: 403`). Antes fallaba también el paso de contrato, que **abortaba el job
antes de llegar aquí** — al arreglarlo, la compuerta completa ya corre (138 suites, 1103 tests) y
expone sólo este fallo.

- **Evidencia de que es preexistente:** el run del commit base `13b45332a` (dos pushes **antes** de
  este bloque de trabajo, ambos sólo de documentación) ya fallaba los mismos 3 casos con los mismos
  números: `1 failed, 126 passed, 127 total` · `3 failed, 978 passed, 981 total`.
- **Trabajo en curso:** PR **#34 `fix/rls-tenant-context`** («montar tenantContext donde se conoce el
  inquilino (authMiddleware)») está **abierto** sobre esta misma área, con su CI también en rojo.
  **No conviene tocarlo desde otro frente:** el arreglo ya está validado en R1-bis y lo que falta es
  una decisión de cableado, no código.
- **⚠️ Consecuencia operativa (corregida el 2026-10-16):** con la compuerta en rojo **no despliega el
  backend** — `Backend Tests & Lint` precede al despliegue a EKS, así que los commits de este bloque
  están en `main` pero no en EKS. **Pero el frontend sí:** el servicio `glowapp-frontend` de Railway
  despliega en cada push a `main` sin mirar esta compuerta, y hay evidencia directa: el `main.dart.js`
  servido en producción contiene los marcadores `YOUR_*` de `lib/firebase_options.dart`, un archivo
  que **introdujo este bloque de commits** (no existe en `13b45332a`). El bloque llegó a producción
  por la vía web aunque el pipeline esté rojo. Importa antes de empujar.

---

## Push web (FCM) — auditoría 2026-10-16

### F1. La web desplegada inicializa Firebase con la plantilla del CLI — CÓDIGO RESUELTO, faltan variables (2026-10-16)

**Síntoma** (consola del navegador en `glowapp-frontend-production.up.railway.app`):

```
❌ Error obteniendo/registrando FCM token: [firebase_messaging/failed-service-worker-registration]
   Failed to register a ServiceWorker for scope (.../firebase-cloud-messaging-push-scope)
   with script (.../firebase-messaging-sw.js): The script has an unsupported MIME type ('text/html')
✅ FCM Service inicializado          <-- mentira: se imprime aunque el token falle
```

**Diagnóstico verificado contra producción** (comprobado, no inferido):

| Comprobación | Resultado |
|---|---|
| `curl -I .../firebase-messaging-sw.js` | `200` con `content-type: text/html` → **es el `index.html` del SPA**: el archivo no existe |
| `frontend/web/` | no contiene ningún `firebase-messaging-sw*` |
| `main.dart.js` desplegado | `YOUR_WEB_API_KEY`, `YOUR_PROJECT_ID`×3, `YOUR_MESSAGING_SENDER_ID`, `YOUR_WEB_APP_ID`; **0** claves `AIza` reales |
| `lib/firebase_options.dart` | 27 marcadores de la plantilla del FlutterFire CLI, sin rellenar |
| Variables del servicio `glowapp-frontend` | sólo `API_BASE_URL` y `GOOGLE_MAPS_API_KEY`; **ninguna** de Firebase |

**Causa raíz:** el build no inyectaba configuración. `lib/main.dart` llamaba a
`Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` con la plantilla tal cual y
**sin guarda**: la app se desplegaba inicializando Firebase con un `apiKey` inválido en silencio, y el
único síntoma aparecía dos pasos después, como un error de service worker.

> El `✅ FCM Service inicializado` no es un problema de orden: se imprime **después** de
> `_registerToken()`, pero ese método **se tragaba su propia excepción**, así que el flujo continuaba
> como si hubiera funcionado.

**Arreglo (commit `2e80cd9a4`):** la configuración entra por `--dart-define`;
`estaConfigurado`/`faltantes` hacen **detectable** un build sin configurar; `main.dart` no inicializa
con valores falsos; `fcm_service` sale temprano si falta configuración, exige `FCM_VAPID_KEY` en web
(antes pasaba `null` y el fallo salía opaco) y deja de imprimir el éxito cuando el token no se
registró; `tool/generate_firebase_sw.dart` genera el service worker **durante** el build (es JS plano:
no puede leer `--dart-define`); los dos Dockerfile declaran los `ARG` y pasan las dart-defines.

**Verificado con build real** (`flutter build web --release` con dart-defines de prueba): **0**
apariciones de `YOUR_` en el bundle, los valores inyectados llegan a `main.dart.js`,
`build/web/firebase-messaging-sw.js` con `node --check` válido, `flutter analyze lib` **0 errores**,
**5/5** en `test/firebase_options_test.dart`.

**PENDIENTE — sólo se cierra con la consola de Firebase y Railway.** Quedan dos valores que **no** se
pueden deducir del repositorio: de `frontend/android/app/google-services.json` salen el proyecto
(`belleza-app-6605f`), el sender (`501450148142`) y un api key, pero **no** salen el **appId web** ni
la **VAPID key**. Hay que definirlos en el servicio `glowapp-frontend`:

`FIREBASE_API_KEY` · `FIREBASE_PROJECT_ID` · `FIREBASE_MESSAGING_SENDER_ID` · `FIREBASE_WEB_APP_ID` · `FCM_VAPID_KEY`

Sin ellas el build sigue funcionando, pero el push queda **deshabilitado y avisado en consola** en vez
de roto en silencio. Nada de esto se versiona: `verifyNoVersionedSecrets.js` (basada en `git grep`)
rechaza claves `AIza...` en archivos trackeados — de hecho `google-services.json` **ya** es rechazado
por esa compuerta, y por eso no está en el repositorio.

**REGRESIÓN de `2e80cd9a4`, corregida en el commit siguiente — la web quedó en PANTALLA EN BLANCO.** Al
dejar de llamar a `Firebase.initializeApp` en un build sin configuración, `FcmService` reventaba al
**construirse**: su campo `final FirebaseMessaging _messaging = FirebaseMessaging.instance;` busca la
app `'[DEFAULT]'` y lanza `[core/no-app]` si no existe. `main()` pide `FcmService.instance` **antes de
`runApp`**, así que la excepción escapaba del `runZonedGuarded` y la app nunca se dibujaba. El campo
pasa a ser perezoso (`??=`). **Lección:** una guarda en un método no protege si el fallo ocurre en el
**inicializador de campo** del objeto, que se evalúa al acceder al singleton — antes que el método.

**No confundir con dos hallazgos vecinos que quedan ABIERTOS:**

- **Meta Pixel:** `web/index.html` llama a `fbq('init','GLOWAPP_PIXEL_ID')` y el navegador responde
  `Invalid PixelID: a non-numeric string`. Es **preexistente** (desde `526faaf5d`, 2026-09-22), no de
  este bloque, y **no se tocó**: es la misma clase de defecto (marcador literal en el artefacto que
  llega al navegador) pero necesita el ID real, que tampoco está en el repositorio.
- **`google_sign_in`:** el plugin usa `signIn()` en web, deprecado; de ahí los avisos
  `Cross-Origin-Opener-Policy`.

### F2. El checkout no declaraba `tenant_id`: 500 en TODA la tienda — **RESUELTO** (2026-10-17)

**Síntoma:** `Error creando pedido: Exception: 500 Error al procesar el checkout` en la UI, con el carrito
lleno. El log del servidor lo decía sin ambigüedad:

```
❌ ERROR EN CHECKOUT DE TIENDA: error: null value in column "tenant_id"
   of relation "pedidos_tienda" violates not-null constraint
```

**Cadena causal (verificada archivo:línea):** `065_multi_tenant_hardening.sql:52` define
`app_current_tenant_id()` como `current_setting('app.tenant_id')` → NULL sin contexto de sesión;
`068_force_rls_strict_isolation.sql:103` hace que `app_assign_tenant_id()` copie **eso** → NULL;
`071_glowshop_niveles_a0.sql:236-268` deja `pedidos_tienda.tenant_id` y `detalles_pedido_tienda.tenant_id`
en **NOT NULL** con ese trigger; y `createOrder` **nunca declaraba `tenant_id`**. Las rutas `/store/*` sólo
llevan `authMiddleware`, sin `tenantContext`. Es **R1 cobrándose una víctima concreta**: no es teoría, es
una caída de producción. La cabecera de 065 ya lo pedía: *«el 100% de los INSERT declaran tenant_id»*.

**Arreglo (commit `0a9f287e`):** el tenant se resuelve del **comprador** — la misma regla del relleno de 071
(`pedidos_tienda.tenant_id = usuarios.tenant_id`) — con caída al tenant de plataforma que 071 define. Se
declara `tenant_id` en **los dos** inserts y, sin tenant resoluble, responde 409 con mensaje propio.

**Comprobado contra la base real** (sólo lectura): `tenant_id` es NOT NULL en ambas tablas,
`app_platform_tenant_id()` = 4, y el trigger `trg_assign_tenant_id` está presente. **Y el dato que justificó
la caída:** `usuarios.tenant_id IS NULL` → **3 compradores**; sin ella esos 3 seguirían sin poder pagar.

**Línea base para verificar el arreglo:** `pedidos_tienda` = 11 filas, la última del **2026-08-19**. Un
checkout correcto debe producir la fila 12 con `tenant_id` no nulo.

**Pendiente derivado:** decidir si a esos **3 usuarios sin `tenant_id`** se les asigna uno propio (encaja en
la decisión de cableado de R1: son los que caen al tenant de plataforma). Y `065` decía que 87 de 89 INSERT
no declaraban `tenant_id`: las otras tablas de 071 (`booking_productos`, `scan_product_matches`,
`inventario_consignacion_prestador`) **no tienen ningún INSERT en `src/`**, así que hoy no hay otro camino
caído por esta causa conocida — pero conviene auditar el resto.

### F3. El frontend lee `API_URL`, pero el servicio define `API_BASE_URL` — ABIERTO (2026-10-17)

`frontend/lib/services/api_service.dart:30` hace `String.fromEnvironment('API_URL')`, mientras el servicio
`glowapp-frontend` de Railway define **`API_BASE_URL`**. La variable se ignora en silencio y la app cae en
`stagingUrl`, la constante fija `https://belleza-app-production.up.railway.app` (línea 17). Hoy apunta al
sitio correcto **por casualidad**: cambiar la variable de Railway no hace nada y apuntar el frontend a otro
backend requiere tocar código.

### F4. La pasarela NO está configurada en producción — ABIERTO (2026-10-17)

El checkout ya crea el pedido (F2 resuelto, verificado: `pedidos_tienda` pasó de 11 a **14** filas, todas con
`tenant_id`), pero el paso de pago responde **`PAYMENT_GATEWAY_NOT_CONFIGURED`**:

- `wompiClient.isConfigured()` exige **cuatro** variables (`wompiClient.js:82-84`):
  `WOMPI_PRIVATE_KEY`, `WOMPI_PUBLIC_KEY`, `WOMPI_INTEGRITY_SECRET`, `WOMPI_EVENTS_SECRET`.
- El servicio `belleza-app` de Railway **no tiene ninguna `WOMPI_*`** (comprobado por nombre). Por eso el
  `GET /api/payments/wompi/public-key` y el de acceptance-token responden 503 (`paymentRoutes.js:82-88, 123-129`).
- Las llaves **sí existen** en `backend/.env` local (no versionado) y **siguen vivas**: `npm run verify:wompi
  -- --live` obtuvo token de aceptación de Wompi. Son de **sandbox** (`pub_test_`/`prv_test_`).
- Falta `WOMPI_PAYOUTS_ACCOUNT_ID` (sólo afecta a dispersiones, no a cobrar).

**⚠️ Trampa de configuración:** `wompiClient.js:73-76` deriva el host de `NODE_ENV`, no de la llave. Producción
corre con `NODE_ENV=production` → sin `WOMPI_BASE_URL` el cliente pega contra `production.wompi.co` con llaves
de **prueba** y devuelve un **422 opaco** (el propio `verify:wompi` detecta ese desajuste). Para validar el
sandbox en el servicio de producción hay que definir además `WOMPI_BASE_URL=https://sandbox.wompi.co/v1`.

**Decisión pendiente (de Diego, no de código):** configurar sandbox en producción para cerrar el E2E — con el
efecto de que los pedidos "pagados" serían de prueba — o esperar las llaves `pub_prod_` del dashboard. Mientras
tanto la tienda **toma pedidos que no puede cobrar**: 14 pedidos, todos en `PENDIENTE_PAGO`.

### F5. Deriva de migraciones en producción: 056, 058 y 068 — ABIERTO (2026-10-17)

El arranque del backend lo reporta en cada despliegue:

```
⚠️ Deriva de migración: 058_enable_rls_policies.sql cambió después de aplicarse (5cb56386ca7a8fb3 → c0b43346ec89f915)
⚠️ Deriva de migración: 056_add_tenant_id_to_core_tables.sql cambió después de aplicarse (a2238fa4010f0b0b → cf44b160cd776072)
⚠️ Deriva de migración: 068_force_rls_strict_isolation.sql cambió después de aplicarse (8153d2d27c3e1fa0 → 097783117f40b4d3)
```

Son **las tres migraciones del aislamiento multi-inquilino** (056 añade `tenant_id`, 058 activa políticas, 068 fuerza RLS
estricto). El runner las detecta por checksum y **no las re-aplica**, así que la base tiene una versión que ya no existe
en el repo. Esto es material para R1: explica por qué un test puede pasar en local y fallar en CI/producción, y por qué
`pedidos_tienda.tenant_id` acabó NOT NULL sin que el código lo supiera (F2). **No se toca aquí**: hay que decidir si se
regulariza el checksum o se escribe una migración de reconciliación con el estado realmente aplicado.

### F6. `payOrder`: NINGÚN método de pago podía completarse — **RESUELTO** (2026-10-17)

Auditoría del camino completo del pago de tienda. El pedido ya se crea (F2) y la pasarela ya está configurada
(F4), pero **pulsar «Pagar» falla con los cinco métodos que ofrece la hoja**. Evidencia:

| # | Defecto | Evidencia |
|---|---|---|
| 1 | `payOrder` usa `redirect_url` y `customer_data` **sin declararlos** → `ReferenceError` → 500 | `orderController.js:430` (no los destructura) vs `:483, :486, :489, :512, :513`. `payBooking` sí los destructura (`bookingController.js:15`) |
| 2 | Con tarjeta manda `payment_source_id` **y** `payment_method='CARD'` → el cliente lanza la exclusión mutua | `orderController.js:510-511` vs `wompiClient.js:331-333` |
| 3 | Con Nequi manda `payment_method: 'NEQUI'` (string) en vez de `{ type:'NEQUI', phone_number }` | `orderController.js:511`; el contrato correcto está documentado en `bookingController.js:84-96` |
| 4 | Exige `customer_data.financial_institution_code` a **todos** los métodos de redirección (Daviplata no lo usa) | `orderController.js:489-491` |
| 5 | El frontend **no puede** enviar `redirect_url` ni `customer_data`: `ApiService.payOrder` no tiene esos parámetros | `api_service.dart:557-565`. (W10 los añadió a `payBooking`, no a `payOrder`) |
| 6 | `payment_method_token` lo envía el frontend pero `payOrder` no lo lee (solo `payment_source_id`) | `api_service.dart:570` vs `orderController.js:430` |
| 7 | `.trim().isEmpty` — idioma **Dart**, en JS `.isEmpty` es `undefined` → los guards nunca disparan | 6 sitios: `bookingController:55`, `orderController` ×3, `workforceController` |

**Cierre del pedido (independiente de lo anterior).** Hay dos webhooks: `POST /api/payments/wompi-webhook`
(solo reservas, `bookingRoutes.js:28`) y `POST /api/payments/store-webhook` (solo pedidos, `productRoutes.js:48`).
Wompi entrega los eventos a **una sola URL** configurada en el dashboard, así que sólo uno de los dos puede
confirmarse. Además el de reservas, ante una referencia `wompi_order_…`, cae en «Reserva no encontrada»
(`bookingController.js:786`) y Wompi reintenta. No existe polling del estado para pedidos, así que sin ese webhook
el pedido se queda en `PENDIENTE_PAGO` para siempre (hoy hay 14 así).

**Plan propuesto (pendiente de aprobación):**
1. `payOrder`: destructurar `redirect_url`/`customer_data`/`payment_method_token`; armar el `paymentMethod` con el
   mismo contrato documentado de `payBooking`; exigir `financial_institution_code` sólo a PSE; `.isEmpty` → `.length === 0`.
2. Unificar los webhooks en **un** endpoint que despache por prefijo de referencia (`wompi_order_` → tienda, resto →
   reserva) y apuntar ahí la URL de eventos de Wompi. Es la única forma de que ambos caminos se confirmen.
3. `api_service.payOrder` + la hoja: enviar `redirect_url` y `customer_data`; mostrar el estado de la transacción
   mientras el usuario autoriza en su banco (polling contra el pedido) en vez de asumir éxito.
4. Tests: los 5 métodos con el contrato esperado + webhook despachando ambos tipos.

**Dos defectos más, encontrados al arreglarlo (ambos bloqueaban el cierre):**

8. `payOrder` guardaba la **referencia** (`wompi_order_…`) en `transactions.external_id`, pero
   `storeWebhook` busca por el **id de Wompi** (`SELECT … WHERE external_id = $1` con `data.id`). Tampoco
   `pedidos_tienda.metadata->>'wompi_external_id'` tenía el id. Resultado: aunque el evento llegara, no
   encontraba ni la transacción ni el pedido → **el pedido no podía pasar a `PAGADO` por ninguna vía**.
9. La hoja de pago (`wompi_payment_sheet.dart`) llamaba **siempre** a `ApiService.payBooking`: la tienda
   (`store_screen.dart:705-712`, que pasa `bookingId: orderId` + `itemType: 'product'`) pegaba contra
   `/bookings/<orderId>/pay`, donde ese id no existe.

**Arreglo aplicado (4 fases):**
1. `payOrder`: destructura `redirect_url`/`customer_data`/`payment_method_token`; arma el `paymentMethod` con
   el contrato documentado de `payBooking` (NEQUI objeto, CARD token, redirección string) garantizando la
   exclusividad con `payment_source_id`; `financial_institution_code` sólo para PSE; `.isEmpty` → `.length === 0`;
   `transactions.external_id` = id de Wompi y `metadata.wompi_external_id` = id de Wompi (referencia aparte);
   errores mapeados 402/502 en vez de 500 opaco.
2. Webhooks: `bookingController.wompiWebhook` despacha por prefijo (`wompi_order_` → `orderController.storeWebhook`),
   así una sola URL de eventos cubre reservas y pedidos.
3. Frontend: `ApiService.payOrder` acepta `redirect_url`/`customer_data`; la hoja elige endpoint según
   `itemType` (`_crearTransaccion`) y **espera la confirmación** consultando el pedido (`_esperarConfirmacionPedido`)
   en vez de declarar éxito al crear la transacción.
4. Tests: `tests/payOrder.contract.test.js` (12 casos: los seis métodos, exclusividad, `external_id`, 402/500,
   idempotencia) + 2 casos de despacho de webhook. Comprobados por mutación: revertir la destructuración rompe
   6 casos y volver a guardar la referencia rompe el del `external_id`.

**Verificado:** 12/12 y 28/28 en los archivos tocados; suite completa y `flutter analyze lib` sin cambios
respecto de la línea base.

**Defecto 10 (encontrado probando el endpoint desplegado, no leyendo el código):** `storeWebhook` leía el tipo
de evento como `event.event.type`, pero Wompi manda `"event": "transaction.updated"` como **string**
(docs.wompi.co → Eventos → Cuerpo de un evento). `eventType` quedaba `undefined` y el handler respondía **400 a
todo evento real**: Wompi reintentaba 3 veces (30 min, 3 h, 24 h) y el pedido no se cerraba nunca. Corregido en
`orderController.js` (acepta string y, por compatibilidad, `{type}`) y fijado en
`tests/storeWebhook.contract.test.js` (6 casos, comprobado por mutación: el parseo viejo rompe 3).

**Defecto 11 (destapado al arreglar el 1):** `payOrder` insertaba en `transactions` con 15 columnas, pero en
producción la tabla tenía **8** (`id`, `booking_id`, `amount`, `status`, `payment_method`, `external_id`,
`created_en`, `tenant_id`) y `booking_id` era **NOT NULL**: una venta de tienda no cabía. Síntoma real:
`error: column "client_id" of relation "transactions" does not exist` → 500 después de crear el pedido. Ninguna
migración ni el modelo Sequelize (`src/models/Transaction.js`) declaraban esas columnas: el INSERT se escribió
contra un esquema imaginario. Corregido con `migrations/095_extend_transactions_for_store_orders.sql` (aditiva e
idempotente: 10 columnas + `booking_id` nullable + índice por `external_id`). Validada contra producción dentro de
una transacción y revertida (8 → 18 → 8 columnas).

**Defecto 12:** el `UPDATE` de `metadata` usaba `to_jsonb($2)` con el parámetro sin tipo. `to_jsonb()` es
**polimórfica**, así que Postgres respondía `could not determine polymorphic type because input has type unknown`
→ 500 en el pago. Estaba en el código original; sólo se hizo alcanzable al arreglar los anteriores. Corregido con
`to_jsonb($2::text)` y `to_jsonb($3::text)`. Se probó **la secuencia completa de `payOrder`** (INSERT en
`transactions` + UPDATE de metadata) contra producción en una transacción: 22 → 22 filas y metadata restaurada.
Nota de método: la primera sonda probó el INSERT y el UPDATE del webhook pero **no** esta sentencia; por eso el
fallo llegó a producción. La sonda ahora cubre la secuencia entera.

### F7. `storeWebhook` usa `pool.query('BEGIN'/'COMMIT')` — ABIERTO (2026-10-17)

`orderController.storeWebhook` abre la transacción con `pool.query('BEGIN')` y la cierra con `pool.query('COMMIT')`
sobre el **pool**: cada llamada puede ir por una conexión distinta, así que el `BEGIN` no envuelve nada y el
`ROLLBACK` no deshace lo ya escrito. En el camino feliz el `UPDATE` persiste igual (autocommit), pero ante un fallo
a mitad queda estado parcial. Hay que tomarlo con `pool.connect()` y usar ese cliente para las tres sentencias.
No se tocó porque excede el alcance de F6 y el camino feliz funciona.

### F9. Cierre del E2E de tienda: tres defectos de la última captura — RESUELTO (2026-10-17)

Tras cerrar el circuito con una transacción aprobada, la captura del intento real mostró
«Pago en proceso». La causa y lo corregido:

1. **El número de prueba estaba mal.** `3111111111` **no es** número de sandbox: Wompi
   respondió `ERROR — Número no válido en Sandbox`. Los válidos son **`3991111111`**
   (aprobado) y `3992222222` (rechazado), Daviplata OTP `574829`/`932015`, tarjeta
   `4242…`/`4111…`. No es un defecto de código, pero costó dos intentos.
2. **`getOrderById` no exponía el estado del cobro.** El pedido sigue `PENDIENTE_PAGO`
   tanto si el pago fue rechazado como si el webhook aún no llegó, así que la app no
   podía distinguirlos. Ahora devuelve `pago: { status, estado_pago }`.
3. **La hoja leía `data['estado']`** y el endpoint responde `{data: {order, items}}`:
   el estado llegaba `undefined` y **siempre** caía en «pago en proceso», incluso con un
   rechazo. Ahora lee `data.order` + `data.pago` y muestra «El pago fue rechazado».
4. **El modal mostraba el total sin envío.** Pasaba el total del carrito ($40.317)
   mientras `createOrder` cobraba $55.717,20 (subtotal 33.880 + envío 15.400 + IVA
   6.437,20): el cliente iba a pagar $15.400 más de lo que veía. Ahora usa el `total`
   del pedido que devuelve el servidor.
5. **`cotizarEnvio` no toleraba tildes.** Comparaba con `lower()` en SQL ("bogota" ≠
   "Bogotá") y caía al fallback `OTRO` (15.400 en vez de 9.000). Ahora lee el catálogo
   en una consulta y empareja normalizando (NFD sin marcas combinantes). Verificado
   contra el catálogo real: `bogota` → Bogotá, **9.200**.

Cubierto por `tests/storeOrderDetail.contract.test.js` (3) y `tests/shippingService.test.js`
(8, probados por mutación). Suite: 164/164, 1281 passed.

### F8. La factura electrónica DIAN no se emite en ninguna venta — ABIERTO (2026-10-17)

Al cerrarse el primer pago completo de tienda (pedido `5dc47fe3…`, E2E en sandbox), el log mostró:

```
[DIAN INVOICE] Cliente no configurado (falta certificado/NIT). Saltando factura para pedido 5dc47fe3-…
```

`dianInvoiceClient.isConfigured()` es falso en producción, así que **toda venta pagada se queda sin factura electrónica** y
el webhook la salta en silencio (por diseño: no rompe el pago). En Colombia la facturación electrónica es obligatoria
para ventas; esto no bloquea el cobro pero sí la operación real. Falta cargar certificado, NIT y resolución en el
servicio `belleza-app`, o decidir explícitamente que se factura por fuera. **No confundir con un fallo de pago.**

**Estado del E2E de tienda tras F6:** cerrado y verificado en producción. Pedido → transacción en Wompi (sandbox,
Nequi `3991111111`) → evento → `pedidos_tienda.estado = PAGADO` y `transactions.status = 'paid'` en 10 s. Requiere la
URL de eventos de cobros configurada en el dashboard (Sandbox): las de «Pagos a Terceros» son otra cosa.

### Nota operativa: `railway variables` volcó credenciales en la sesión

Durante este diagnóstico, `railway variables --service belleza-app --kv` imprimió valores en claro
(`DATABASE_URL`, `PGPASSWORD`, y antes `GEMINI_API_KEY`, `JWT_SECRET`, `ENCRYPTION_KEY` de
`.env.production.txt`). El archivo **no está versionado** (`.gitignore:7` → `.env.*`), así que **no hay fuga
en el repo**; el riesgo es el historial de la sesión. **No volver a invocar `railway variables` sin filtrar
por nombre** y rotar los valores expuestos.

## Acceso al panel admin — censo de credenciales (2026-10-17)

### S1. Seis cuentas ADMIN activas en producción con contraseña de diccionario — ALTA

Censo medido **autenticando**, no comparando hashes (bcrypt lleva sal; ver `docs/knowledge/TRAMPAS.md:510`):
`POST https://admin-dashboard-production-4183.up.railway.app/api/admin/auth/login` (con `Origin`/`Referer`,
el BFF rechaza mutaciones sin ellos: 403 CSRF).

- `admin@glow.app` (id 999, "Administrador Glow", `is_active=true`) → **HTTP 200**. Contraseña de diccionario
  (`admin123`). Es la cuenta que sostiene el panel: rotarla antes de cualquier otra cosa.
- Cinco cuentas de prueba `*@glowapp.test` (ids 1020-1024: `spike-img-…`, `spike-admin-…`, `spike-preview-…` ×2,
  `test-…`) con rol **ADMIN** y `is_active=true`, contraseña `Password123!` → **HTTP 200** cada una. Son residuos de
  los spikes de octubre: ninguna debería existir en producción, menos con rol ADMIN.
- `admin@beautyapp.com` (id 1) sí quedó `is_active=false` tras CI-48: el cierre de puerta se sostuvo.
- `diegomartinromero@gmail.com` (id 7) y `escuela@glow.app` (id 998) son ADMIN activos cuya contraseña **no** está en
  la lista de débiles: sanas por ahora, pero no hay registro de cuándo se rotaron.

Arreglo: desactivar (no borrar) las cinco `@glowapp.test`, rotar `admin@glow.app`, y añadir al gate de despliegue un
chequeo de "cuentas ADMIN activas" — hoy nadie vigila cuántas hay. No se tocó nada: es producción y la orden era
leer.

### S2. Nota operativa: `PGPASSWORD` de Postgres volvió a quedar en el historial de sesión (2026-10-17)

Para este censo se invocó `railway variables --service postgres --json` **sin filtrar por nombre**, que imprimió
`PGPASSWORD` en claro (misma falta que la nota de más arriba con `belleza-app`). El valor permite conexión externa
(`crossover.proxy.rlwy.net:51506`, usuario `postgres`, DB `railway`): es acceso total a producción, no un secreto de
servicio. **Rotarla** y, de aquí en adelante, `railway variables --service <svc> --json | jq 'keys'` (sólo nombres)
o `jq -r '.DATABASE_URL'` acotado. Las credenciales del censo NO se escribieron en este archivo.
