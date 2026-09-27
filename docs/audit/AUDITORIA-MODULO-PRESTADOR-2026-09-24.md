# AUDITORÍA — MÓDULO PRESTADOR (end-to-end: contacto → servicio → pago)

**Fecha:** 2026-09-24
**Alcance:** el recorrido completo del prestador: descubrimiento/contacto → agenda → ejecución → cierre con verificación → dinero (wallet, retiro, disputa).
**Árbol auditado:** `C:/beauty-app` @ `feat/glowshop-niveles-a0` (working tree **limpio**; `main` = `e6e116bd`). El clon `C:/Users/Compu casa/belleza-app` (main del 4-ago, 22.036 entradas sucias) quedó **fuera** del alcance.
**Método:** lectura de código + ejecución. Las afirmaciones marcadas **[V]** se comprobaron ejecutando algo (psql sobre el contenedor `beauty-postgres:5435` que replica el esquema/datos de producción, jest, o parser YAML). Las marcadas **[L]** son lectura de código con `archivo:línea`, sin ejecución.

---

## 1. Mapa real del flujo (y dónde se rompe)

| # | Etapa | Backend | App | Estado |
|---|-------|---------|-----|--------|
| 1 | Registro y alta de prestador | `authController.js:301-338` crea `perfiles_prestador` con estatus `PENDIENTE` | onboarding | ✅ funciona |
| 2 | Aprobación (para ser visible) | `admin-glow/admin.model.js:79` (`APROBADO`) | botones "Aceptar/Rechazar" del panel **sin `onClick`** (`admin-dashboard/.../prestador/page.tsx:115-120`) | ⚠️ no hay UI útil |
| 3 | Descubrimiento en el mapa | `GET /api/providers` (`providerController.js:5-174`), exige `estatus_verificacion='APROBADO'`, `is_active`, `ubicacion` | mapa/home | ⚠️ errores silenciados (devuelve 200 vacío) |
| 4 | Contacto | `chatRoutes.js` → `chatController.js` (filtro anti-evasión de teléfonos/correos) | `provider_detail_screen.dart:1509,1643` | ✅ con salvedades (§M5) |
| 5 | Reserva | `POST /api/bookings` (`bookingController.js:42-234`) crea N citas encadenadas en `PENDIENTE_PAGO`, PIN de 4 dígitos | `booking_screen.dart:275` | ✅ |
| 6 | Cobro al cliente | `POST /api/bookings/:id/pay` → **501 en producción** (`bookingController.js:443-468`); el único camino restante es el webhook | `wompi_payment_sheet.dart` | ❌ **no existe cobro** |
| 7 | Notificación al prestador | WS efímero + "SMS" que es un `console.log` (`bookingController.js:205-220`) | — | ❌ no hay canal persistente |
| 8 | Ejecución | `PATCH /bookings/:id/start` (`:805-839`), check-in GPS (`paymentRoutes.js:59-100`) | `provider_dashboard_screen.dart:222` | ✅ |
| 9 | Cierre + verificación | `POST /bookings/:id/complete` → OTP 6 dígitos (`paymentRoutes.js:104-176`); `POST /bookings/:id/confirm-otp` → dispersa al wallet (`:180-397`) | `otp_confirm_screen.dart` / `provider_dashboard_screen.dart:909-939` | ❌ **el OTP no se entrega a nadie** |
| 10 | Wallet | `GET /api/wallet`, `wallet_transactions`, maduración 2 h (`paymentRoutes.js:401-503`, `paymentJobs.js:40-91`) | `wallet_screen.dart` | ⚠️ doble dueño del saldo |
| 11 | Retiro | `POST /api/wallet/withdraw` → `wompiService.crearPayout` (simulado) | `wallet_screen.dart:218` | ❌ en prod el payout se rechaza y el saldo ya está debitado |
| 12 | Reseña | `POST /bookings/:id/review` (`bookingController.js:737-802`) | `client_bookings_screen.dart:175` | ✅ |
| 13 | Disputa | **tres** implementaciones paralelas | `otp_confirm_screen.dart:359` (`/dispute`) | ❌ incoherentes |

**Conclusión de una línea:** las etapas 1-5, 8 y 12 funcionan; el módulo **no cierra** porque el cobro (6), el aviso al prestador (7) y la verificación que libera el dinero (9) no existen en producción, y el retiro (11) descuenta sin pagar.

---

## 2. CRÍTICOS (bloquean el cierre del servicio)

### C-01 — El wallet se puede acreditar sin que nadie pague **[L]**
Cadena verificada línea a línea:
1. `PATCH /api/bookings/:id/status` acepta **cualquier** transición: `validStatuses = ['PENDIENTE_PAGO','CONFIRMADA','EN_PROGRESO',…]` y solo comprueba pertenencia, no el pago (`bookingController.js:309-323`). Un prestador pasa su cita de `PENDIENTE_PAGO` a `EN_PROGRESO`.
2. `POST /bookings/:id/complete` acepta `IN ('CONFIRMADA','CHECKIN_REALIZADO','EN_PROGRESO')` (`paymentRoutes.js:118`) y **no mira `payment_status` ni `transactions`**.
3. `POST /bookings/:id/confirm-otp` **tampoco** valida el pago: solo exige OTP activo + ser el cliente (`paymentRoutes.js:192-211`), y luego escribe `estado='COMPLETADA', payment_status='paid'` (`:284-287`) y acredita `pago_neto_prestador` al wallet (`:289-299`).

Efecto: prestador y cliente cómplices (o simplemente una cita que nunca se pagó) generan saldo retirable. Además `payment_status='paid'` dispara los triggers `trg_client_loyalty_reward` y hace que el panel admin sume `valor_bruto` como "recaudado hoy" (`paymentRoutes.js:1011-1019`): **ingresos fabricados**.
**Advertencia de secuencia:** si se arregla C-03 (entregar el OTP) sin poner la puerta de pago aquí, el agujero pasa de teórico a explotable en producción.

### C-02 — No existe el cobro: la cita se queda en `PENDIENTE_PAGO` para siempre **[V/L]**
- `payBooking` devuelve 501 si `NODE_ENV==='production'` y `ALLOW_PAYMENT_SIMULATOR!=='true'` (`bookingController.js:443-468`). Guarda de regresión: `src/tests/audit360-remediation.test.js:106-110`.
- No hay ninguna llamada de cobro a Wompi en el repo: `grep` de `https?://` en `wompiService.js` → 0 coincidencias (y el propio test lo afirma, `:124-128`); no hay `api.wompi.co`, `acceptance_token` ni creación de transacción en ningún sitio.
- El formulario de la app **recoge número de tarjeta, vencimiento, CVV y titular** (`wompi_payment_sheet.dart:611-684`) y no los manda a ninguna parte: el POST solo lleva `{payment_method}` (`api_service.dart:385-398`). Es una pasarela simulada con apariencia de real — y recoger PAN/CVV en la app sin PCI-DSS y descartarlos es un riesgo de cumplimiento, no solo cosmético.

### C-03 — El OTP que libera el pago no se entrega a nadie **[V-L]**
- `complete` genera el código, guarda **solo el hash** (`paymentRoutes.js:140-150`) y responde *"Se envió el código al cliente"* (`:162-165`) sin enviarlo: no hay nodemailer/SMS/push ni endpoint que lo exponga.
- El único lugar donde el código aparece es la respuesta HTTP, y solo si `NODE_ENV!=='production' **y** EXPOSE_DEV_OTP==='true'` (`:167`).
- `emailService.js` es un `console.log` con el bloque de nodemailer **comentado** (`emailService.js:14-24`) → no hay canal transaccional para nada (ni recuperación de carrito).
- El cliente tiene la pantalla pidiendo el código (`otp_confirm_screen.dart:206-215`: *"el código de 6 dígitos que recibirás en esta app"*) y el prestador recibe el mensaje *"el cliente recibirá su código"* (`provider_dashboard_screen.dart:914-921`). Nadie recibe nada.
⇒ Sin C-03 no hay `COMPLETADA`, no hay wallet, no hay payout. Es **el** bloqueante del módulo.

### C-04 — Dos verificaciones incompatibles: PIN de 4 dígitos que el servidor ignora **[L]**
- La app del prestador pide el `pin_verificacion` de 4 dígitos y lo envía en el body (`api_service.dart:825-852`, `provider_dashboard_screen.dart:3034-3067`); el backend **no lee el body**: genera otro código distinto de 6 dígitos (`paymentRoutes.js:104-176`).
- Ese PIN lo generó el servidor con `Math.random()` en la reserva (`bookingController.js:148`) y el cliente lo ve en la pantalla de seguimiento (`booking_tracking_screen.dart:157`).
- Resultado: el prestador cree que verificó la entrega; el sistema no lo registró. Es exactamente el modelo "PIN+OTP" de Uber mal implementado (debería ser **uno** de los dos, y verificado en servidor).

### C-05 — El prestador no puede gestionar sus servicios (membresía rota) **[V]**
- `/api/services/*` pasa por `membershipMiddleware` + `requirePermission` (`serviceRoutes.js:11-41`).
- El middleware consulta la columna `business_profile_id` (`membership.middleware.js:21-31`, `models/Membership.js:18-22`)… que **no existe** en la tabla real: el snapshot de producción tiene `establishment_id` (+`relation_type`) y 0 columnas con ese nombre.
- Evidencia ejecutada:
  ```
  $ docker exec beauty-postgres psql -U admin -d beauty_db -c 'SELECT "Membership"."business_profile_id" FROM memberships AS "Membership";'
  ERROR:  column Membership.business_profile_id does not exist
  ```
  (consulta literal que emite Sequelize). Y el DDL que la crea —`src/db/migrations/013_memberships.sql`— **nunca se aplica** (los runners solo toman `backend/migrations/*.sql`); `establishment_id` no aparece en **ningún** archivo del repo (`grep`: 0 coincidencias), así que la tabla desplegada se creó a mano.
- Agravante **[V]**: 5 cuentas de prestador (ids 7, 11, 74, 104, 106) tienen **más de una** membresía `ACTIVE`; aun con el nombre correcto, el middleware devuelve `403 MULTIPLE_CONTEXTS_REQUIRE_SELECTION` (`membership.middleware.js:49-58`) porque la app no manda `X-Business-Profile-Id`.
⇒ Con catálogo no editable desde la app, el embudo del prestador nace cerrado (los 133 servicios existentes vienen de semilla).

---

## 3. ALTOS

### A-01 — Retiro: se descuenta el saldo y el pago **siempre** falla en prod **[V/L]**
`POST /api/wallet/withdraw` debita `saldo_disponible`, inserta `retiros(PROCESANDO)` y llama a `crearPayout` **sin esperar** (`paymentRoutes.js:781-825`). `crearPayout` en producción lanza `rechazarSimulacion` (`wompiService.js:9-17, 82`), y el `.catch()` solo escribe un log (`:825`). El retiro queda `PROCESANDO`/`FALLIDO` con el saldo ya descontado y **sin reintento ni cola**: no hay job que reintente retiros fallidos (`paymentJobs.js` solo crea retiros nuevos) y la conciliación real con Wompi sigue siendo un `TODO` (`paymentJobs.js:235-237`). El prestador ve "Retiro solicitado. El dinero llegará en 1-2 días hábiles" (`paymentRoutes.js:827-834`) y nunca llega.

### A-02 — Botón de escape del prestador muerto **[L]**
El diálogo de "liberación manual / reportar caso" llama `updateBookingStatus(id,'EN_DISPUTA')` (`provider_dashboard_screen.dart:833-834`) y `EN_DISPUTA` **no** está en `validStatuses` (`bookingController.js:309-312`) ⇒ **400 "Estado inválido" siempre**. La ruta documentada para el caso "el cliente no puede ver su código" no existe.

### A-03 — El prestador nunca se entera de la reserva **[L]**
`notifyProviderNewBooking` solo emite si ese usuario tiene una conexión WebSocket abierta y registrada con token (`websocketService.js:159-175`); el "SMS" es `console.log('[SMS SENDER] …')` (`bookingController.js:211-216`). No hay push (no hay FCM en el repo), ni email, ni bandeja persistente. Una cita creada mientras el prestador tiene la app cerrada es invisible: depende de que él entre a mirar.

### A-04 — Disputas: tres implementaciones con tres vocabularios y efectos distintos **[L/V]**
| Ruta | Crea | Congela fondos | Marca la cita | Resoluciones |
|---|---|---|---|---|
| `POST /api/disputes` (`paymentRoutes.js:891-1003`) | sí | sí, si la cita ya estaba `COMPLETADA` (`:960-978`) | `EN_DISPUTA` (`:955-958`) | `FAVOR_PRESTADOR / REEMBOLSO_TOTAL / DIVISION / COMPENSACION_PLATAFORMA` |
| `POST /api/disputas` (`disputeController.js:6-81`) | sí | **no** | **no** | `REEMBOLSO_CLIENTE / LIBERAR_PRESTADOR / PARCIAL` (`:171`) |
| `PATCH /api/admin/disputes/:id/resolve` (`adminRoutes.js:34-82`) | — | **no toca el wallet** | `COMPLETADA` si pct>0 | libre + `porcentaje_prestador` obligatorio |
Y `PUT /api/admin/disputes/:id/resolve` (`paymentRoutes.js:1088-1201`) repite la ruta del anterior sobre otro router: `index.js` monta `paymentRoutes` en `/api` (línea 379) y `adminRoutes` en `/api/admin` (línea 983), así que `GET /api/admin/disputes` lo sirve el primero (devuelve `{disputas,page,limit}`) mientras el panel Next no tienen ninguna pantalla que consuma ninguno de los dos.
Consecuencia concreta: si un admin resuelve por `adminRoutes` o por `disputeController`, el dinero congelado en `saldo_en_disputa` **queda congelado para siempre** (nadie lo devuelve a `saldo_disponible`).
Nota de exactitud: el comentario de `paymentRoutes.js:1161` ("`actualizado_at` no existe en `disputas`") es **falso** en el snapshot — la columna existe (`\d disputas`). El comentario está desactualizado; conviven dos creencias contradictorias en el mismo repo.

### A-05 — Congelar con `GREATEST(0, …)` permite pagar dos veces **[L]**
`createDispute` hace `saldo_disponible -= monto` **con `GREATEST(0, …)`** y `saldo_en_disputa += monto` sin comprobar que había fondos (`paymentRoutes.js:960-977`). Si el prestador ya retiró, el descuento se recorta a 0 pero el monto se acredita igual a `saldo_en_disputa`; al resolver `FAVOR_PRESTADOR` se suma a `saldo_disponible` (`:1140-1147`) ⇒ cobra dos veces (ya retirado + re-liberado). Falta una máquina de saldo que sume cero (pendiente+disponible+disputa) o que rechace el congelamiento sin fondos.

### A-06 — Dos dueños del mismo saldo (y doble acreditación) **[L]**
`GET /api/wallet` madura saldos **en una ruta de lectura**, sin transacción ni `FOR UPDATE`: marca `PENDIENTE→COMPLETADO` (`paymentRoutes.js:405-413`), luego suma `WHERE acreditado IS NULL` (`:415-433`) y después marca `acreditado`. Dos peticiones concurrentes pueden sumar dos veces el mismo crédito. Además el job `madurarSaldosPendientes` (cada 15 min, `paymentJobs.js:40-91`) hace lo mismo por otro camino. Un saldo debería tener **un solo** dueño.

### A-07 — La comisión real no es la que la app comunica **[V]**
- El trigger `calc_booking_split` vigente es la curva continua de `migrations/011_update_commission_trigger.sql`: `max(15%, 28% − 0,00008 × valor_bruto)` **más 8% fijo** en `impuestos_estado`. Verificado en la BD: la función desplegada es esa, y 9 filas reales de 50.000 COP tienen `comision_plataforma=12.000` (24%), `impuestos_estado=4.000`, `pago_neto_prestador=34.000`.
- La app muestra *"Descuento Plataforma (20% total)"* con el 20% **hardcodeado** (`provider_dashboard_screen.dart:354-355`) y una sub-línea `• Comisión Neta Plataforma (12%)`, y afirma *"La plataforma asume y reporta este impuesto en tu beneficio"* (`:365-374`) mientras ese 8% se descuenta al prestador y se contabiliza como ingreso de plataforma (`admin-glow/admin.model.js:142-145`).
- `platform_config.comision_plataforma_pct = 20` **no lo lee nadie** (`grep` en backend + frontend + admin: 0 coincidencias) [V].

Economía real (calculada con el trigger y las retenciones de `confirm-otp`, `paymentRoutes.js:262-277`):

| Bruto | Comisión plataforma | "Impuestos estado" 8% | Neto del prestador (bruto) | Retenciones (4% + 0,414% + IVA 15% s/comisión) | **Acreditado al wallet** | % del bruto que se queda el prestador |
|---|---|---|---|---|---|---|
| 30.000 | 25,6% → 7.680 | 2.400 | 19.920 | 2.031 | 17.889 | **59,6%** |
| 50.000 | 24,0% → 12.000 | 4.000 | 34.000 | 3.301 | 30.699 | **61,4%** |
| 100.000 | 20,0% → 20.000 | 8.000 | 72.000 | 6.178 | 65.822 | **65,8%** |
| 200.000 | 15,0% → 30.000 | 16.000 | 154.000 | 11.298 | 142.702 | **71,4%** |

El prestador retiene entre **59% y 71%** del valor publicado, mientras la UI le dice 80%.

### A-08 — Transiciones de estado sin máquina de estados **[L]**
`updateBookingStatus` permite cualquier salto (`PENDIENTE_PAGO → COMPLETADA`, `CONFIRMADA → PENDIENTE_PAGO`, etc.) sin tocar `payment_status` ni auditar (`bookingController.js:292-339`). De ahí salen tres efectos: reseñas sobre citas no cobradas (`createReview` solo exige `COMPLETADA`, `:756`), KPIs de admin contando servicios no pagados, y la cadena de C-01.

### A-09 — Config que promete comportamiento inexistente **[V]**
`platform_config` tiene `comision_plataforma_pct`, `disputa_max_reembolso_pct`, `cancelacion_libre_horas`, `riesgo_suspender_score`… y **ninguna** se lee en el repo (grep: 0 coincidencias). Consecuencias concretas: la "cancelación libre 24 h" no se aplica en ningún sitio (`cancelBooking` no mira el tiempo, `bookingController.js:397-435`) y `risk_score` nunca pausa retiros (`retiros_pausados` solo lo pone un humano).

---

## 4. MEDIOS

- **M-01 · Un prestador nuevo es invisible y no hay flujo de aprobación completo.** `GET /api/providers` exige `estatus_verificacion='APROBADO'` **y** `ubicacion IS NOT NULL` (`providerController.js:68-69`); el onboarding crea `PENDIENTE` (`authController.js:329`). En el snapshot: **9 perfiles para 41 cuentas PRESTADOR**, 5 `APROBADO` y 4 `PENDIENTE` [V]. Los botones de aprobación del panel Next no tienen `onClick` (`prestador/page.tsx:115-120`).
- **M-02 · El tenant de la petición no se fija donde debe.** `bookings`, `provider_wallet`, `wallet_transactions`, `services`, `disputas`, `retiros`, `transactions` están con **RLS + FORCE** y política `tenant_id = app_current_tenant_id()` [V, `relforcerowsecurity=t`]; pero `tenantContextMiddleware` —el que abre una transacción con `set_config(..., true)` por petición— **no está montado** (grep: solo lo referencian sus tests) y `authMiddleware` fija el tenant con `set_config(..., false)` sobre una conexión **arbitraria** del pool (`auth.js:54-58`). Si el rol de la app no salta RLS, el panel del prestador puede devolver 0 filas en silencio; si lo salta (superusuario/BYPASSRLS), el aislamiento no existe. No decidible desde el repo: depende de la credencial de producción, que no es legible (ver §6).
- **M-03 · Chat con la persona equivocada.** `GET /api/bookings/client` no devuelve `provider_id` (`bookingController.js:346-361`) y la app lo usa para (a) abrir el chat del prestador desde el seguimiento → cae al literal `'2'` (`booking_tracking_screen.dart:158, 353-354`) y (b) "Reprogramar" → pasa `null` a `/provider-detail` (`client_bookings_screen.dart:1069-1073`).
- **M-04 · El PIN del cliente no es un control.** Se genera con `Math.random()` y se guarda en claro; el servidor nunca lo valida (solo lo pinta la UI). El OTP real está hasheado con bcrypt — bien — pero es el que no llega (C-03).
- **M-05 · Panel del prestador sin filtro de estado.** `getProviderBookings` devuelve **todas** las citas del prestador, incluidas `PENDIENTE_PAGO` (sin cobro) y `CANCELADA`, mezcladas (`bookingController.js:246-260`); el panel Next les pone "Aceptar/Rechazar" muertos encima. El `client_phone` del cliente se expone al prestador sin necesidad operativa.
- **M-06 · `requireAdmin` por email literal.** Además del rol, acepta `admin@beautyapp.com` o `admin` (`paymentRoutes.js:48-55`): identidad privilegiada por cadena, no por RBAC.
- **M-07 · `pilaCheck` es un guardián que nadie alimenta.** Bloquea agendamiento si `suspension_pila` o `pila_estado_verificacion='VENCIDO'` (`pilaCheck.js:23`), pero ningún job/endpoint actualiza esos campos (grep: 0 escrituras) ⇒ nunca suspende por sí solo. Su mensaje cita cláusulas del contrato ("Cláusula Décima"): una suspensión automática sin proceso de aviso/descargo es riesgo legal.
- **M-08 · El webhook no cumple el contrato de Wompi** **[V contra documentación oficial]**. El código valida **HMAC-SHA256 del cuerpo** con un secreto compartido leído de un header propio (`x-wompi-signature`/`x-signature`, `bookingController.js:9-39`); Wompi usa **SHA-256 del concatenado de las propiedades de `signature.properties` + `timestamp` + el secreto de eventos**, expuesto en `X-Event-Checksum` / `signature.checksum` (docs.wompi.co, "Eventos → Validación de integridad"). Además `req.rawBody` **no lo produce nadie** (`grep`: solo se lee) ⇒ hashea `JSON.stringify(req.body)`, con orden de claves no garantizado. Hoy no se nota porque no hay cobros; el día que se integre la pasarela, el webhook rechazará (401) todos los eventos legítimos. Nota: la parte buena es que es *fail-closed* sin secreto.
- **M-09 · Los "tests de integración" del módulo no tocan el módulo** **[V]**. `tests/booking.test.js` levanta su propia app Express con handlers inline (`:6-43`) sin importar `bookingController`; `tests/payment.test.js` define y prueba una función local de firma que **no es** la de producción (`:10-30`) — usa el esquema correcto de Wompi, así que el verde incluso documenta un contrato que el código no implementa. Corrida real: `npx jest tests/booking.test.js tests/payment.test.js src/tests/provider_schedule.test.js` → **3 suites, 8 tests, 0 fallos** sin ejercitar una sola línea del flujo.

---

## 5. BAJOS / HIGIENE

- **B-01 [V] · El CI está muerto por marcadores de conflicto commiteados.** `.github/workflows/ci.yml` tiene `<<<<<<< HEAD` / `=======` / `>>>>>>> origin/main` en las líneas 60/84/90 **dentro de `main`** (`git show main:.github/workflows/ci.yml`), y `.gitignore` en 32/36/37 y 84/85/94. Comprobado con un parser YAML: `ScannerError: while scanning a simple key … line 60, column 1`. Un workflow inválido no lo carga el runner ⇒ **no corren tests, ni `flutter analyze`, ni el escáner de secretos** desde que se mergeó así. Esto invalida cualquier afirmación de "CI en verde" sobre este repo.
- **B-02 · `GET /api/providers` se come los errores** y responde `200 {count:0,data:[]}` (`providerController.js:170-173`): mapa vacío indistinguible de "no hay prestadores cerca".
- **B-03 · El fallback geográfico miente**: ignora radio y verificación y devuelve lat/lon fijos (`providerController.js:119-138`).
- **B-04 · El seguimiento simula al prestador acercándose** con un `Timer` e interpolación si no hay GPS real (`booking_tracking_screen.dart:125-148`).
- **B-05 · `disbursePayout` es código muerto**: definido y nunca llamado (`wompiService.js:26`; 0 referencias), y de hacerlo sobrescribiría la fila de `transactions` del **cobro** con `payment_method='NEQUI'` (`:44-55`), porque hay una sola fila por `booking_id`.
- **B-06 · `providerRoutes` no valida rol** en `/provider/schedule` (GET/PUT usan `id = req.user.id` sin comprobar que sea prestador; `providerRoutes.js:15-71`).

---

## 6. Verificado con ejecución / no verificable

Comandos reproducibles (desde `C:/beauty-app`):

```bash
# Estado del árbol auditado
git log --oneline -1 && git status --porcelain | wc -l          # limpio
git show main:.github/workflows/ci.yml | grep -n '^<<<<<<<'    # 60
python -c "import yaml,sys; yaml.safe_load(open(...))"          # ScannerError

# Esquema/datos reales (contenedor con el snapshot de producción)
docker exec beauty-postgres psql -U admin -d beauty_db -c "SELECT count(*) FROM perfiles_prestador;"      # 9 (41 cuentas PRESTADOR)
docker exec beauty-postgres psql -U admin -d beauty_db -c "SELECT estado, count(*) FROM bookings GROUP BY 1;"  # 78 CANCELADA, 3 COMPLETADA, 1 EN_PROGRESO, 1 CONFIRMADA
docker exec beauty-postgres psql -U admin -d beauty_db -c "SELECT count(*) FROM otp_validaciones;"        # 0
docker exec beauty-postgres psql -U admin -d beauty_db -c "SELECT count(*) FROM wallet_transactions;"     # 0
docker exec beauty-postgres psql -U admin -d beauty_db -c "SELECT count(*) FROM disputas;"                # 0
docker exec beauty-postgres psql -U admin -d beauty_db -c 'SELECT "Membership"."business_profile_id" FROM memberships;'  # ERROR: no existe

# Suites que "cubren" el módulo
cd backend && NODE_ENV=test npx jest tests/booking.test.js tests/payment.test.js src/tests/provider_schedule.test.js
```

Lectura de los datos del snapshot: **0 OTP generados, 0 transacciones de wallet, 0 retiros, 0 disputas, 3 reseñas** ⇒ en la base real **nadie ha completado nunca el flujo de cierre**; solo hay 3 citas `COMPLETADA`, presumiblemente por cambio de estado manual (A-08).

**No verificable desde aquí** (y no se debe asumir): el `NODE_ENV`/`ALLOW_PAYMENT_SIMULATOR`/`EXPOSE_DEV_OTP`/`WOMPI_WEBHOOK_SECRET` reales de producción, el rol de conexión de la app a Postgres (decide si RLS filtra o no), y si `068_force_rls_strict_isolation.sql` está aplicada en Railway. Requiere consola de Railway; el CLI del entorno no tiene permisos de lectura de variables.

---

## 7. Orden de corrección propuesto (para pasar al ejecutor)

Fase 0 — **Limpieza que desbloquea la verificación**
1. Resolver los marcadores de conflicto de `.github/workflows/ci.yml` y `.gitignore` en `main` (el CI no corre). Aceptación: `python -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"` sin error y un run verde en GitHub Actions.

Fase 1 — **Una sola puerta de dinero (antes de tocar el OTP)**
2. `confirm-otp` debe exigir: `bookings.payment_status='paid'` **y** una fila `transactions` `status='paid'` con `amount >= valor_bruto`. Sin eso → 409 `BOOKING_NOT_PAID`. Mutación: intentar la cadena C-01 (`PATCH status → EN_PROGRESO` → `complete` → `confirm-otp`) debe devolver 409 y **no** escribir en `provider_wallet`.
3. `updateBookingStatus`: matriz de transiciones explícita por rol (el prestador solo `CONFIRMADA→EN_PROGRESO`, `EN_PROGRESO→FINALIZADA_PRESTADOR`; nada hacia `COMPLETADA`/`PENDIENTE_PAGO`), y `EN_DISPUTA` fuera de las transiciones del prestador (o `EN_DISPUTA` añadido con su endpoint propio). Mutación: los 6 saltos inválidos deben dar 409 con Estado actual y permitidos.

Fase 2 — **Cerrar el hueco de entrega de la verificación (una sola, verificada en servidor)**
4. Elegir **una** de las dos: (a) OTP de 6 dígitos entregado de verdad (canal transaccional real) o (b) PIN de 4 dígitos validado en servidor contra `bookings.pin_verificacion`. Eliminar la otra de la UI. Si se opta por (a), el canal debe existir **antes** de exponer el código; si (b), quitar `otp_validaciones` del camino y dejar el check-in GPS como evidencia.
5. Añadir el aviso persistente al prestador (notificación en bandeja + push si hay canal); el WebSocket puede quedar como mejora, no como único canal.

Fase 3 — **Dinero consistente**
6. Un solo dueño de la maduración (solo el job, con `FOR UPDATE`); que `GET /wallet` no mutile saldos. Aceptación: dos GET concurrentes no duplican `saldo_disponible` (test con `Promise.all`).
7. Congelamiento de disputa sin `GREATEST(0, …)`: si no hay fondos, 409 y no se acredita `saldo_en_disputa`; invariante `pendiente+disponible+en_disputa` verificada antes/después.
8. Unificar las disputas en **un** flujo (tablas y vocabulario únicos) y hacer que toda resolución pase por el movimiento del wallet; migrar/cerrar las rutas duplicadas. Aceptación: `grep -c "UPDATE disputas"` en un solo módulo y ningún endpoint que resuelva sin tocar `provider_wallet`.
9. Retiros: si `ALLOW_PAYMENT_SIMULATOR` no está activo, **no debitar** el wallet antes de una dispersión confirmada (o dejar el retiro en un estado reintentable con job). Aceptación: ningúna `saldo_disponible` baja sin una `retiros.referencia_wompi`.

Fase 4 — **Coherencia de lo que se comunica**
10. Comisión: una sola fuente (leer `platform_config.comision_plataforma_pct` **o** el trigger, nunca ambos) y que la UI muestre el desglose real (`comision_plataforma`, `impuestos_estado`, `pago_neto_prestador` que ya devuelve `/bookings/provider`), eliminando el `gross*0.20` hardcodeado y el texto del "8% asumido en tu beneficio".
11. Aplicar o retirar `cancelacion_libre_horas`, `disputa_max_reembolso_pct`, `riesgo_suspender_score`: una config que no hace nada es una promesa incumplida.

Fase 5 — **Membresía y visibilidad**
12. Alinear `models/Membership.js` con la tabla desplegada (`establishment_id`, role/status reales) **o** desplegar `013_memberships.sql`; y que la app mande el contexto de negocio (`X-Business-Profile-Id`) cuando haya más de uno. Aceptación: `GET /api/services/provider` responde 200 para los 5 prestadores con membresías múltiples.
13. `GET /api/bookings/client` debe devolver `b.provider_id` (rompe chat y reprogramar); el fallback `'2'` en la app debe desaparecer.

Fase 6 — **La pasarela real (proyecto aparte)**
14. Creación de transacción en Wompi + `redirect_url`/widget, y webhook reescrito al contrato real (`X-Event-Checksum`, `signature.properties` + `timestamp` + secreto de eventos) con `rawBody` capturado en `express.json({verify})`. Aceptación: firma de un evento de ejemplo de la documentación validada y un evento duplicado ignorado.

---

### Anexo — reglas de evidencia usadas

- **[V ejecutado]** = se corrió un comando/herramienta y está en §6. **[V-L]** = evidencia mixta (grep/psql + lectura).
- **[L]** = lectura de código con `archivo:línea`; reproducible por cualquiera sin base de datos.
- Ningún hallazgo de este informe se apoya en memoria ni en el informe A360 previo: donde coinciden, está re-verificado aquí.
