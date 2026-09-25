# TRAMPAS.md — Catálogo de trampas medidas · Belleza App / GlowApp

**Qué es esto:** el registro de las trampas que este proyecto ya produjo y ya pagó. Cada entrada es un mecanismo concreto que engañó a un auditor o a un ejecutor al menos una vez, con la cita de dónde se midió. No es teoría de buenas prácticas: si una entrada no tiene cita, no está en este archivo.

**Cómo se usa:** antes de emitir un veredicto, de entregar un fix o de creer un número propio, recorrer la sección que aplique. Cada entrada termina en una **Regla** imperativa pensada para copiarse a un prompt de trabajo.

**Fuentes de las citas de este catálogo** (auditorías e informes, `C:/Users/Compu casa/auditorias/belleza-app/`):
`AUDITORIA-MODULO-PRESTADOR-2026-09-24.md` · `AUDITORIA-ENTREGA-FASE-A-2026-09-24.md` · `AUDITORIA-ENTREGA-FASE-A-RONDA-2-2026-09-24.md` · `AUDITORIA-GRAFO-RAMAS-2026-09-24.md` · `INFORME-PODA-2026-09-24.md` · `POLITICA-RAMAS-BELLEZA-APP-2026-09-24.md` · `PROMPT-ANTIGRAVITY-RAMAS-P3-PODA-2026-09-24.md`.
Cuando una trampa solo quedó documentada en la auditoría 360 o en su material crudo, la cita lo dice: `AUDITORIA-360-2026-09-22.md`, `AUDITORIA-ESCUELA-ACADEMIA-2026-09-22.md`, `raw/03-ia-rag.txt`, `raw/04-higiene-ci.txt`, `PROMPT-ANTIGRAVITY-FASE-A-2026-09-24.md`.

**Marcas de evidencia usadas en las fuentes:** `[V]` = comprobado ejecutando algo · `[L]` = lectura de código con `archivo:línea`.

---

## 1. Datos y estado fabricado

### T-01 · El fallback en memoria fabrica filas y el flag no se recupera
- **Síntoma:** la API responde con normalidad mientras Postgres está caído: usuarios demo, `'Salón Demo'`, listas vacías y saldos indistinguibles de la realidad. Un solo `console.warn` en el arranque.
- **Causa raíz:** `backend/src/config/db.js:428,443-445,450-452` — `isPgAvailable` arranca en `false` y el wrapper devuelve `handleMemoryQuery(text, params)` **sin intentar la base real**; `handleMemoryQuery` tiene **24 ramas** `return { rows: […] }` con datos inventados (ejemplo canónico `db.js:422`: `{ id: 1, nombre_salon: 'Salón Demo' }`). El camino de recuperación (`db.js:447`) es inalcanzable mientras el flag está en falso ⇒ el proceso queda en ese estado **hasta reiniciar** (no hay backoff). `testConnection()` (`db.js:493-497`) pone `isPgAvailable = false` y **devuelve `true`**: un arranque sin base se reporta como conexión exitosa. `memoryFallbackAllowed()` (`db.js:695`) acepta `ALLOW_MEMORY_FALLBACK === 'true'` **sin ninguna guarda de `NODE_ENV`**. El indicador que sí dice la verdad es `servingFabricatedData`, y los otros flags (`memoryFallbackAllowed`) pueden declarar `false` mientras el proceso **está** sirviendo memoria: los dos indicadores se contradicen y el que manda es `servingFabricatedData`.
- **Cómo se detectó:** `curl /api/health` con la base caída → `503 {"status":"DEGRADED","database":{"pgAvailable":false,"servingFabricatedData":true,"memoryFallbackAllowed":false}}`; y servidor propio con `DATABASE_URL=127.0.0.1:59999`, `NODE_ENV=development`. (`AUDITORIA-360-2026-09-22.md` §C-06:98-108 · `raw/03-ia-rag.txt:36-41` · `AUDITORIA-ENTREGA-FASE-A-2026-09-24.md:109,113`.)
- **Falso veredicto que produce:** "la API está sana, devuelve datos" y, en el arranque, "la base conectó" (porque `testConnection` devuelve `true`).
- **Regla:** el fallback en memoria no sirve datos fuera de `test`/`USE_PG_MEM`; si se activó, la superficie responde ≠2xx, el estado se declara degradado y `testConnection` falso **aborta el arranque**.

### T-02 · Superficies que responden 200 con datos inventados (y el `catch` que se "arregló" no es el camino que se ejecuta)
- **Síntoma:** `GET /api/providers` responde `200 {"success":true,"count":7,"data":[{"id":"101","full_name":"Carolina Mendoza Rios","distance_meters":450,…}]}` con la base inalcanzable; `/api/products` responde `200 OK` con `X-GlowApp-Degraded: memory-fallback` y 36 bytes de cuerpo.
- **Causa raíz:** el fallback en memoria resuelve la consulta **con éxito aguas arriba** (`db.js`), así que el controlador nunca ve un error y su `catch` (`providerController.js:170-173`) **no se ejecuta** — el fix se hizo sobre el síntoma, no sobre la capa de datos. El mismo `catch` además exponía `error.message` de la base al cliente en la única ruta pública de la fase (`providerController.js:172`). El fallback geográfico (`providerController.js:117-139`) sigue devolviendo lat/lon fijos con `distance_meters` calculados y **sin** `degraded: true`.
- **Cómo se detectó:** `curl -s -o /dev/null -w 'HTTP=%{http_code}' http://127.0.0.1:8099/api/providers` con `DATABASE_URL` inalcanzable → `HTTP=200` + cuerpo fabricado; y `GET /api/products` en el mismo proceso degradado. Tras el fix, `/api/providers` sí quedó en `503 PROVIDER_SEARCH_DEGRADED`.
- **Falso veredicto que produce:** "A1.T3/C1 arreglado: ya no devuelve 200 vacío" ⇒ el cliente sigue recibiendo 200, ahora con 7 prestadores inexistentes y distancias inventadas. Criterio S1 de la fase ("ninguna superficie responde 2xx si su consulta falló"): **✗**. (`AUDITORIA-ENTREGA-FASE-A-2026-09-24.md` H-03,H-06,H-07 · `AUDITORIA-ENTREGA-FASE-A-RONDA-2-2026-09-24.md` B3,§S1.)
- **Regla:** si `servingFabricatedData === true` la superficie **no** responde 2xx con payload, el `error.message` no viaja al cliente y el fallback geográfico se marca degradado; la corrección va en la capa de datos, no en el `catch`.

### T-03 · Éxito fabricado en el arranque: "Migración 001…072 aplicada exitosamente" sin base
- **Síntoma:** el log imprime `✅ Base de datos: Migración 001…072 aplicada exitosamente` para **todas**, mientras el pool avisa `⚠️ [DB] Sin enlace con PostgreSQL (ECONNREFUSED) — se sirve memoria local`.
- **Causa raíz:** `backend/index.js:1636-1637` ejecuta `await pool.query(sql)` por archivo (un `.sql` = **una sola consulta**, `index.js:1625-1629`, sin tabla de control ni transacción) e imprime el ✅; el `catch` de `:1639-1643` solo se activa si `pool.query` **lanza**, pero el wrapper de `db.js:446-452` captura cualquier error y devuelve `handleMemoryQuery(...)` sin re-lanzar ⇒ **desde el primer error, todas las migraciones siguientes reportan éxito** y el error no aparece. Los errores de migración que sí llegan se silencian salvo que contengan `already exists`/`ya existe` y quedan en un `console.warn`: una migración rota (caso medido `FALLA 034_add_fks_to_academy_tables.sql (rc=3)`) falla en **cada boot** sin que nadie lo vea, y el arranque no se detiene. Conviven cuatro invocadores sobre el mismo directorio (`index.js` inline sin tabla, `src/config/migrationRunner.js:15-38` con `schema_migrations`, `runMigrations.js` con su propio parser SQL, knex con `knex_migrations`) + 7 migraciones Sequelize entre 68 `.sql`.
- **Cómo se detectó:** arranque propio con `DATABASE_URL` inalcanzable y lectura del log de arranque; `git ls-files backend/migrations`; `psql` mostrando el `rc=3` de 034.
- **Falso veredicto que produce:** "el esquema está al día" y "el deploy aplicó las migraciones" (y "CI no puede fallar por esquema"). El esquema puede quedarse sin actualizar mientras los logs lo afirman. (`AUDITORIA-ENTREGA-FASE-A-2026-09-24.md` H-10 · `raw/03-ia-rag.txt:156-161` · `raw/04-higiene-ci.txt:117-122` · `AUDITORIA-ESCUELA-ACADEMIA-2026-09-22.md:173-179`.)
- **Regla:** ninguna migración se declara aplicada sin verificarla contra `information_schema`; el arranque no ejecuta DDL y sin base disponible **no hay arranque**.

### T-04 · El bundle Flutter commiteado: lo servido ≠ lo auditado
- **Síntoma:** un fix de frontend no llega a producción aunque el código esté en `frontend/lib`.
- **Causa raíz:** `backend/public` es un artefacto de build **commiteado** (60 archivos trackeados, 52,7 MB; `main.dart.js` de 5.752.502 bytes / 189.468 líneas) pese a que `.gitignore:65` lo declara ignorado: el ignore es **muerto** sobre archivos ya trackeados. El backend sirve ese bundle, no el fuente, así que el binario versionado puede quedar desincronizado con `frontend/lib`. El propio orden de trabajo ordena **no** reconstruirlo en la rama y declarar en el PR "requiere rebuild (decisión del dueño)".
- **Cómo se detectó:** `git ls-files backend/public | wc -l` → 60 trackeados; `git check-ignore -v -- backend/public/main.dart.js` → ignore inefectivo; `git ls-tree -r -l HEAD` sumando el prefijo → 55.285.184 bytes.
- **Falso veredicto que produce:** "el arreglo de la tienda ya está desplegado" (la app servida es un build anterior a la auditoría del fuente).
- **Regla:** un artefacto commiteado no se lee como fuente: o se reconstruye en el pipeline y se declara, o el veredicto dice explícitamente "no desplegado". (`PROMPT-ANTIGRAVITY-FASE-A-2026-09-24.md:104,151` · `raw/04-higiene-ci.txt:84-89`.)

---

## 2. Dinero y pagos

### T-05 · El wallet se puede acreditar sin que nadie pague
- **Síntoma:** aparece saldo retirable en `provider_wallet` sin ninguna transacción pagada; el panel admin suma `valor_bruto` como "recaudado hoy".
- **Causa raíz:** cadena de tres puertas abiertas. (1) `PATCH /api/bookings/:id/status` acepta **cualquier** transición: `validStatuses = ['PENDIENTE_PAGO','CONFIRMADA','EN_PROGRESO',…]` y solo comprueba pertenencia, **no el pago** (`bookingController.js:309-323`). (2) `POST /bookings/:id/complete` acepta `IN ('CONFIRMADA','CHECKIN_REALIZADO','EN_PROGRESO')` (`paymentRoutes.js:118`) y no mira `payment_status` ni `transactions`. (3) `POST /bookings/:id/confirm-otp` tampoco valida el pago —solo exige OTP activo + ser el cliente (`paymentRoutes.js:192-211`)— y escribe `estado='COMPLETADA', payment_status='paid'` (`:284-287`) y acredita `pago_neto_prestador` al wallet (`:289-299`). `payment_status='paid'` además dispara los triggers `trg_client_loyalty_reward` y hace que el admin sume `valor_bruto` como recaudado (`paymentRoutes.js:1011-1019`).
- **Cómo se detectó:** lectura línea a línea de la cadena, más `docker exec beauty-postgres psql -U admin -d beauty_db -c "SELECT count(*) FROM wallet_transactions;"` → **0** y `… FROM otp_validaciones` → **0**: en la base real nadie cerró nunca el flujo; las 3 citas `COMPLETADA` existen por cambio de estado manual.
- **Falso veredicto que produce:** "hay retiros y clientes pagando" (los saldos nacen de transiciones de estado, no de cobros). Advertencia de secuencia en la fuente: si se arregla la entrega del OTP sin poner la puerta de pago, el agujero pasa de teórico a explotable.
- **Regla:** el dinero solo se libera si `bookings.payment_status='paid'` **y** existe una fila `transactions` `status='paid'` con `amount >= valor_bruto`; cualquier otra vía devuelve `409 BOOKING_NOT_PAID` y no escribe en `provider_wallet`. (`AUDITORIA-MODULO-PRESTADOR-2026-09-24.md` C-01,C-03,A-08.)

### T-06 · No existe el cobro, pero la pasarela tiene apariencia de real
- **Síntoma:** la app pide número de tarjeta, vencimiento, CVV y titular; la cita se queda en `PENDIENTE_PAGO` para siempre.
- **Causa raíz:** `payBooking` devuelve **501** si `NODE_ENV==='production'` y `ALLOW_PAYMENT_SIMULATOR!=='true'` (`bookingController.js:443-468`); **no hay ninguna llamada de cobro**: `grep` de `https?://` en `wompiService.js` → 0 coincidencias, sin `api.wompi.co`, sin `acceptance_token`, sin creación de transacción (el test lo afirma en `src/tests/audit360-remediation.test.js:124-128`). El sheet recoge PAN/CVV/titular (`wompi_payment_sheet.dart:611-684`) y el POST solo lleva `{payment_method}` (`api_service.dart:385-398`): datos de tarjeta recogidos sin PCI-DSS y descartados. El corte de la ronda 2 solo cubrió `itemType == 'service'`: con `itemType == 'store'` siguen montándose `_cardCtrl` (`:661`) y `_cvvCtrl` (`:698`), y el texto nuevo **afirma un hecho que el sistema no ejecuta** ("La transacción se confirma sin recolectar credenciales bancarias" / "El pago se procesa directamente en el establecimiento").
- **Cómo se detectó:** `grep` de URLs en `wompiService.js` → 0; guarda de regresión `audit360-remediation.test.js:106-110`; `grep -rn "0\.20\|_cvvCtrl\|_cardCtrl" frontend/lib`.
- **Falso veredicto que produce:** "el pago ya no se recoge en línea" / "se cobra en el establecimiento". Se cambió una mentira por otra en la fase cuyo objetivo era dejar de mentir.
- **Regla:** ningún texto de producto afirma un comportamiento que el código no ejecuta, y sin pasarela integrada no se recogen datos de tarjeta en ninguna tienda. (`AUDITORIA-MODULO-PRESTADOR-2026-09-24.md` C-02 · `AUDITORIA-ENTREGA-FASE-A-RONDA-2-2026-09-24.md` B4.)

### T-07 · El retiro descuenta el saldo y el pago falla siempre en producción
- **Síntoma:** el prestador lee "Retiro solicitado. El dinero llegará en 1-2 días hábiles" y nunca llega; el retiro queda `PROCESANDO`/`FALLIDO` con el saldo ya descontado.
- **Causa raíz:** `POST /api/wallet/withdraw` debita `saldo_disponible`, inserta `retiros(PROCESANDO)` y llama a `crearPayout` **sin esperar** (`paymentRoutes.js:781-825`); en producción `crearPayout` lanza `rechazarSimulacion` (`wompiService.js:9-17,82`) y el `.catch()` solo escribe un log (`:825`). No hay job de reintento (`paymentJobs.js` solo crea retiros nuevos) ni cola, y la conciliación real con Wompi sigue siendo un `TODO` (`paymentJobs.js:235-237`). `disbursePayout` es código muerto (`wompiService.js:26`, 0 referencias) y de ejecutarse sobrescribiría la fila de `transactions` del **cobro** con `payment_method='NEQUI'` (`:44-55`), porque hay una sola fila por `booking_id`.
- **Cómo se detectó:** lectura de `paymentRoutes.js:781-834` + `paymentJobs.js` (sin reintentos) + `SELECT count(*) FROM retiros` → 0 en el snapshot.
- **Falso veredicto que produce:** "el prestador cobró" o "el saldo está bien porque se descontó".
- **Regla:** ningún `saldo_disponible` baja sin una `retiros.referencia_wompi` confirmada; un payout simulado no toca el wallet y un retiro fallido es reintentable. (`AUDITORIA-MODULO-PRESTADOR-2026-09-24.md` A-01,B-05.)

### T-08 · Congelar con `GREATEST(0, …)` permite cobrar dos veces
- **Síntoma:** el prestador ya retiró y aun así se le "congela" y luego se le "libera" el mismo monto.
- **Causa raíz:** `createDispute` hace `saldo_disponible -= monto` **con `GREATEST(0, …)`** y `saldo_en_disputa += monto` sin comprobar que había fondos (`paymentRoutes.js:960-977`); si el prestador ya retiró, el descuento se recorta a 0 pero el monto se acredita igual a `saldo_en_disputa`, y al resolver `FAVOR_PRESTADOR` se suma a `saldo_disponible` (`:1140-1147`) ⇒ cobra dos veces (ya retirado + re-liberado). Falta una máquina de saldo con invariante `pendiente + disponible + en_disputa`.
- **Cómo se detectó:** lectura del bloque de congelamiento y del de resolución, contrastado con el invariante de saldo.
- **Falso veredicto que produce:** "el congelamiento protege el dinero de la plataforma".
- **Regla:** un descuento nunca se recorta a 0 en silencio: sin fondos → `409`, no se acredita `saldo_en_disputa`, y el invariante suma cero antes y después. (`AUDITORIA-MODULO-PRESTADOR-2026-09-24.md` A-05.)

### T-09 · Dos dueños del mismo saldo (maduración dentro de una ruta de lectura)
- **Síntoma:** `saldo_disponible` duplicado tras dos lecturas concurrentes.
- **Causa raíz:** `GET /api/wallet` madura saldos **en una ruta de lectura**, sin transacción ni `FOR UPDATE`: marca `PENDIENTE→COMPLETADO` (`paymentRoutes.js:405-413`), suma `WHERE acreditado IS NULL` (`:415-433`) y luego marca. El job `madurarSaldosPendientes` (cada 15 min, `paymentJobs.js:40-91`) hace lo mismo por otro camino ⇒ dos peticiones concurrentes suman dos veces el mismo crédito.
- **Cómo se detectó:** lectura de los dos caminos + prueba diseñada con `Promise.all` de dos `GET` concurrentes.
- **Falso veredicto que produce:** "el saldo es consistente porque el cálculo está centralizado".
- **Regla:** un saldo tiene **un solo** dueño (el job, con `FOR UPDATE`); una ruta de lectura no muta nada. (`AUDITORIA-MODULO-PRESTADOR-2026-09-24.md` A-06.)

### T-10 · La comisión real no es la que la app comunica
- **Síntoma:** la UI dice "Descuento Plataforma (20% total)" con una sub-línea "Comisión Neta Plataforma (12%)" y "La plataforma asume y reporta este impuesto en tu beneficio", mientras el prestador recibe **entre 59% y 71%** del bruto.
- **Causa raíz:** el trigger vigente `migrations/011_update_commission_trigger.sql` aplica `max(15%, 28% − 0,00008 × valor_bruto)` **más 8% fijo** en `impuestos_estado`, descontado al prestador y contabilizado como ingreso de plataforma (`admin-glow/admin.model.js:142-145`). La UI lleva el 20% **hardcodeado** (`provider_dashboard_screen.dart:354-355`) con un fallback silencioso `?? (gross * 0.20)` y `?? (gross * 0.08)` (`:285,290`) que sobrevive a un `grep "0\.20"`. Y `platform_config.comision_plataforma_pct = 20` **no lo lee nadie** (`grep` en backend + frontend + admin → 0), igual que `disputa_max_reembolso_pct`, `cancelacion_libre_horas` y `riesgo_suspender_score`: la "cancelación libre 24 h" no se aplica en ningún sitio (`cancelBooking` no mira el tiempo, `bookingController.js:397-435`) y `risk_score` nunca pausa retiros.
- **Cómo se detectó:** contraste del trigger desplegado contra la BD: 9 filas reales de 50.000 COP → `comision_plataforma=12.000` (24%), `impuestos_estado=4.000`, `pago_neto_prestador=34.000`; `grep` de la config → 0 coincidencias en todo el repo.
- **Falso veredicto que produce:** "la comisión es 20% y el prestador se lleva 80%" — la economía real retiene entre 59% y 71%.
- **Regla:** una sola fuente para la comisión (el trigger **o** la config, nunca ambos), la UI muestra el desglose que ya devuelve la API (`comision_plataforma`/`impuestos_estado`/`pago_neto_prestador`), cero porcentajes literales en el cliente y ninguna config publicada que no la lea nadie. (`AUDITORIA-MODULO-PRESTADOR-2026-09-24.md` A-07,A-09 · `AUDITORIA-ENTREGA-FASE-A-RONDA-2-2026-09-24.md` B4.)

### T-11 · Disputas: tres implementaciones y dinero congelado para siempre
- **Síntoma:** una disputa resuelta por el panel admin o por `disputeController` no devuelve el dinero: `saldo_en_disputa` queda congelado para siempre.
- **Causa raíz:** tres rutas con tres vocabularios y efectos distintos: `POST /api/disputes` (`paymentRoutes.js:891-1003`) congela solo si la cita estaba `COMPLETADA` (`:960-978`) y marca `EN_DISPUTA` (`:955-958`), con resoluciones `FAVOR_PRESTADOR / REEMBOLSO_TOTAL / DIVISION / COMPENSACION_PLATAFORMA`; `POST /api/disputas` (`disputeController.js:6-81`) no congela ni marca (`:171`); `PATCH /api/admin/disputes/:id/resolve` (`adminRoutes.js:34-82`) **no toca el wallet**. Además `PUT /api/admin/disputes/:id/resolve` (`paymentRoutes.js:1088-1201`) repite una ruta sobre otro router porque `index.js` monta `paymentRoutes` en `/api` (379) y `adminRoutes` en `/api/admin` (983), así que `GET /api/admin/disputes` lo sirve el primero, y el panel Next no tiene ninguna pantalla que consuma ninguno de los dos. El comentario de `paymentRoutes.js:1161` ("`actualizado_at` no existe en `disputas`") es **falso**: la columna existe (`\d disputas`) — dos creencias contradictorias conviven en el mismo repo.
- **Cómo se detectó:** tabla comparativa de las tres rutas (crea / congela / marca / resoluciones) + `\d disputas` en el contenedor.
- **Falso veredicto que produce:** "el admin resolvió la disputa, el prestador cobró" (el dinero sigue congelado), y "el comentario del código explica el esquema".
- **Regla:** una sola tabla y un solo camino de resolución, y **toda** resolución pasa por el movimiento del wallet (`grep -c "UPDATE disputas"` en un único módulo); un comentario no es evidencia del esquema. (`AUDITORIA-MODULO-PRESTADOR-2026-09-24.md` A-04.)

---

## 3. Multi-tenant y base de datos

### T-12 · El modelo consulta una columna que no existe (y el DDL que la crea nunca se aplica)
- **Síntoma:** el prestador no puede gestionar su catálogo; `/api/services/provider` responde error mientras la consola del backend muestra un `column … does not exist`.
- **Causa raíz:** `membershipMiddleware` consulta `business_profile_id` (`membership.middleware.js:21-31`, `models/Membership.js:18-22`) y la tabla desplegada tiene `establishment_id` (+ `relation_type`): **0 columnas** con ese nombre. El DDL que supuestamente la crea —`src/db/migrations/013_memberships.sql`— **nunca se aplica**, porque los runners solo toman `backend/migrations/*.sql`; y `establishment_id` no aparece en **ningún** archivo del repo (`grep`: 0 coincidencias) ⇒ la tabla desplegada se creó a mano. Agravante: 5 cuentas de prestador (ids 7, 11, 74, 104, 106) tienen **más de una** membresía `ACTIVE`, así que aun con el nombre correcto el middleware devuelve `403 MULTIPLE_CONTEXTS_REQUIRE_SELECTION` (`membership.middleware.js:49-58`) porque la app no manda `X-Business-Profile-Id`.
- **Cómo se detectó:** la consulta literal que emite Sequelize contra el contenedor: `docker exec beauty-postgres psql -U admin -d beauty_db -c 'SELECT "Membership"."business_profile_id" FROM memberships AS "Membership";'` → `ERROR: column Membership.business_profile_id does not exist`; y `grep establishment_id` en el repo → 0.
- **Falso veredicto que produce:** "el middleware de membresía funciona, el problema es del prestador" y "aplicar 013 lo arregla" (el esquema desplegado ya divergió).
- **Regla:** el modelo se alinea con la tabla medida (no al revés) y antes de declarar una migración "aplicable" se comprueba **qué runner la lee**. (`AUDITORIA-MODULO-PRESTADOR-2026-09-24.md` C-05.)

### T-13 · RLS activo pero el tenant se fija en una conexión arbitraria del pool
- **Síntoma:** el panel del prestador devuelve 0 filas en silencio, o el aislamiento simplemente no existe, según la credencial con la que corra la app.
- **Causa raíz:** `bookings`, `provider_wallet`, `wallet_transactions`, `services`, `disputas`, `retiros` y `transactions` están con **RLS + FORCE** y política `tenant_id = app_current_tenant_id()` (`[V] relforcerowsecurity=t`); pero `tenantContextMiddleware` —el que abre una transacción con `set_config(..., true)` por petición— **no está montado** (grep: solo lo referencian sus tests) y `authMiddleware` fija el tenant con `set_config(..., false)` sobre una conexión **arbitraria** del pool (`auth.js:54-58`). Si el rol de la app no salta RLS, las lecturas pueden caer en la conexión del inquilino anterior o devolver 0 filas; si lo salta (superusuario/`BYPASSRLS`), el aislamiento no existe.
- **Cómo se detectó:** consulta a los catálogos del contenedor (`relforcerowsecurity=t`) + `grep -rn tenantContext src/ index.js` → middleware sin montar (código muerto, con `res.on('finish')` que resetea a `''` y reventaría con `''::int`).
- **Falso veredicto que produce:** "hay RLS, luego hay aislamiento" — y su opuesto, "no hay RLS". **No decidible desde el repo:** depende del rol de conexión de producción, que no es legible desde aquí.
- **Regla:** el aislamiento no se declara verde sin la credencial real: se marca **no verificado** y se prueba con un rol sin `BYPASSRLS` y con el middleware montado por petición. (`AUDITORIA-MODULO-PRESTADOR-2026-09-24.md` M-02 · `AUDITORIA-360-2026-09-22.md` §C-07.)

### T-14 · El esquema vive solo en el servidor (y cuatro caminos dicen aplicarlo)
- **Síntoma:** nadie puede reproducir el esquema en un entorno nuevo ni en CI; cualquier `ALTER` propuesto es una apuesta, y las suites `business*` no pueden ser de integración real.
- **Causa raíz:** tablas consultadas por el código **sin DDL en el repositorio** (`salones`, `salon_miembros`, `salon_invitaciones`, `providers`, `rag_chunks`, `aura_knowledge_chunks`); `memberships` y `business_profiles` solo en `backend/src/db/migrations/012,013`, que **nunca se aplican**; `bookings`/`usuarios` solo en `init.sql`, `create_required_tables.sql` y `backup_beauty_db.sql`, que ningún arranque ejecuta. Y cuatro invocadores sobre el mismo directorio (`index.js:1625-1629` sin tabla de control, `migrationRunner.js` con `schema_migrations`, `runMigrations.js` con parser propio, knex con `knex_migrations`), cada uno ignorando lo que hizo el otro.
- **Cómo se detectó:** barrido de `migrations/*.sql` buscando el `CREATE TABLE` de cada tabla que el código consulta + `git ls-files backend/migrations` (68 `.sql` + 7 `.js` + 3 backups).
- **Falso veredicto que produce:** "las migraciones existen, luego el esquema está versionado" — en realidad el estado de la base vive solo en el servidor.
- **Regla:** un solo runner, con tabla de control, ejecutado como paso del pipeline y **no** como efecto del arranque; y `pg_dump --schema-only` como base de las migraciones que falten. (`AUDITORIA-360-2026-09-22.md` A-15 · `raw/04-higiene-ci.txt:117-122`.)

---

## 4. Git, ramas y copias

### T-15 · `git branch -d` compara contra HEAD, no contra `main`
- **Síntoma:** `git branch -d` **se niega** a borrar ramas que sí están contenidas en `main`: se negó con **5 ramas `feat/glowshop-*` que tenían 0 commits fuera de `main`**, porque HEAD era otra rama.
- **Causa raíz:** `-d` comprueba ancestralidad respecto de **HEAD**, no de la rama base de la poda. El propio prompt P3 llevaba el fallo y se corrigió al medirlo.
- **Cómo se detectó:** `git branch -d` negándose, contra `git rev-list --count main..<rama>` → `0` **y** `git merge-base --is-ancestor <rama> main`.
- **Falso veredicto que produce:** "esa rama tiene trabajo propio, hay que conservarla" — o, al revés, el operador se cansa y pasa a `-D` sin haber comprobado nada, que es la otra mitad del mismo engaño.
- **Regla:** el gate de borrado es `git rev-list --count main..<rama>` = 0 **y** `merge-base --is-ancestor <rama> main`; `-d` nunca es el gate y `-D` exige esa medición pegada en el registro. (`INFORME-PODA-2026-09-24.md` §3.1 · `PROMPT-ANTIGRAVITY-RAMAS-P3-PODA-2026-09-24.md:47`.)

### T-16 · `%(refname:short)` convierte `refs/remotes/origin/HEAD` en una rama llamada `origin`
- **Síntoma:** el inventario y la imagen listan una rama `origin` que no existe; el gráfico la rotula "referencia suelta local origin".
- **Causa raíz:** `%(refname:short)` abrevia `refs/remotes/origin/HEAD` a **`origin`**; el generador la toma como nombre de rama, la clasifica `BASE` y la describe con un literal (`branchGraph.js:373`). Comprobado: `refs/heads` = 23 y `refs/remotes/origin` = 21 ⇒ ninguna rama local `origin` existió nunca. Contamina `BASE=2` y `nombres únicos = 26`.
- **Cómo se detectó:** `git for-each-ref refs/heads refs/remotes/origin` listando nombres y contando por namespace.
- **Falso veredicto que produce:** "existe una rama local `origin`" y, en la siguiente medición, "esa rama desapareció" (fue un error de la sonda, no del repositorio).
- **Regla:** excluir `refs/remotes/origin/HEAD` del inventario o rotularlo `origin/HEAD (symref)`; un symref no es una rama. (`AUDITORIA-GRAFO-RAMAS-2026-09-24.md` D4 y retracción 3.)

### T-17 · Confundir el **tip** de una rama con su **merge-base**
- **Síntoma:** un tag `archive/*` queda apuntando al commit equivocado, o la rama "nace" en un sitio que no es.
- **Causa raíz:** en `codex/rag-aura-r1-r4` el merge-base con `main` es `0ee1eb37` y el **tip** es `68ce4b4e`; intercambiarlos etiqueta otro commit. El generador usa ambos para cosas distintas: `git merge-base main <ref>` (`branchGraph.js:138`) y `git rev-list --count main..<ref>` (`:135`).
- **Cómo se detectó:** comparar `git rev-parse <rama>` (tip) contra `git merge-base main <rama>` y contra la tabla de valores medidos, que el script aborta si no coincide.
- **Falso veredicto que produce:** "la rama nace en X" o "el tag contiene el trabajo de la rama".
- **Regla:** el SHA de rescate sale siempre de `git rev-parse <rama>` **en el momento de ejecutar**; el merge-base solo sirve para dibujar o relacionar, nunca para etiquetar. (`PROMPT-ANTIGRAVITY-RAMAS-P3-PODA-2026-09-24.md:29-40` · `AUDITORIA-GRAFO-RAMAS-2026-09-24.md` §a favor.)

### T-18 · Un clon "atrasado" que en realidad está **divergente** (y que se habría destruido)
- **Síntoma:** el clon local parecía basura de agosto de 2026; "atrasado", candidato a borrar. Tras `fetch`, su `main` tiene **29 commits que ya no están en `origin/main`** y el conjunto de sus refs guarda **331 commits únicos** (14 ramas).
- **Causa raíz:** "estar detrás" y "estar divergente" se ven idénticos desde la fecha del último commit y desde `git status`; y `git rev-list --count main..<rama>` sobre el clon viejo mide contra *su* `main`, que ya no es el de `origin`.
- **Cómo se detectó:** `git fetch` de diagnóstico y `git rev-list --count --all --not origin/main` → **331**; bundle de respaldo de 319 MB clonado y verificado (14 ramas + 8 tags, los 14 tips presentes, el árbol de `feature/migrate-env-to-secrets` recuperable, el commit divergente `4f803a0b` dentro) y `FOSSIL.txt` corregido a la cifra medida.
- **Falso veredicto que produce:** "está atrasado, se puede borrar o rebobinar" ⇒ destrucción de 331 commits y 14 ramas.
- **Regla:** antes de borrar o rebobinar un clon, `rev-list --count --all --not origin/main` y un bundle de respaldo verificado clonándolo; "atrasado" es una hipótesis, no un veredicto. (`INFORME-PODA-2026-09-24.md` §3.2, §4.4.)

### T-19 · El repo es **público** y había ramas con nombres de secretos
- **Síntoma:** ninguno, hasta que se publica una rama con historia sensible.
- **Causa raíz:** la API de GitHub responde **200 sin token** (repo `Diegoromerov/belleza-app` es público) y el clon fósil contenía 5 ramas con nombres de trabajo sensible: `feature/implement-encryption-at-rest`, `feature/implement-privacy-endpoints`, `feature/integrate-secret-manager`, `feature/migrate-env-to-secrets`, `feature/secret-manager-selection`.
- **Cómo se detectó:** consulta a la API sin token → 200; listado de refs del fósil antes de decidir el rescate.
- **Falso veredicto que produce:** "publicar el rescate en GitHub es más seguro que dejarlo en un bundle local" — exactamente al revés: en un repo público, un `push` de esas ramas publica credenciales si las hay.
- **Regla:** en un repositorio público ninguna rama se publica como rescate: bundle local + tag verificado, y solo tras revisar la historia por secretos. (`INFORME-PODA-2026-09-24.md` §3.2, §6.4.)

### T-20 · `git worktree remove` falla con submódulos
- **Síntoma:** `fatal: working trees containing submodules cannot be moved or removed`.
- **Causa raíz:** al rescatar el worktree, un repo **embebido** (`.agents/skills/flutter-expert-v2`) quedó como gitlink y convirtió el worktree en uno con submódulos, que `remove` no toca. El gitlink no guarda contenido: el repo embebido necesita su propio bundle (159 KB) y su tag. Salida aplicada: `rm -rf` + `git worktree prune`, con el contenido ya preservado en tag **y** bundle.
- **Cómo se detectó:** `git worktree remove <ruta>` → el fatal, después de haber verificado `git -C <wt> status --porcelain -uall | wc -l` = 0 y rescatar el trabajo sucio (376 y 20 entradas) en commits y tags.
- **Falso veredicto que produce:** "el worktree está limpio, no se pierde nada" — el gitlink no guarda contenido, así que el repo embebido se pierde aunque el worktree parezca vacío.
- **Regla:** no se retira un worktree con submódulos hasta que el repo embebido tenga tag/bundle propio; y si `remove` se queja de **cambios sin commitear**, ese fallo es la garantía — se vuelve al rescate, nunca se usa `--force`. (`INFORME-PODA-2026-09-24.md` Fase 3 · `PROMPT-ANTIGRAVITY-RAMAS-P3-PODA-2026-09-24.md:52` · `POLITICA-RAMAS-BELLEZA-APP-2026-09-24.md` §4.)

### T-21 · Clonar un bundle deja los refs en `refs/remotes/*` (contar `refs/heads` da 0)
- **Síntoma:** el respaldo parece vacío: "0 ramas dentro".
- **Causa raíz:** al clonar un bundle, las refs aterrizan en `refs/remotes/*`; contar `refs/heads` devuelve **siempre 0**.
- **Cómo se detectó:** clon del bundle + `for-each-ref refs/heads | wc -l` → 0 (conclusión falsa); recuento corregido sobre `refs/remotes/*` → **14 ramas + 8 tags**, con los 14 tips presentes.
- **Falso veredicto que produce:** "el respaldo no sirve, hay que rehacerlo" ⇒ se descarta un respaldo bueno (o se repite trabajo de rescate ya hecho).
- **Regla:** al verificar un bundle se cuentan **todas** las refs (`for-each-ref` sin filtro o `refs/remotes/*`), nunca solo `refs/heads`. (`INFORME-PODA-2026-09-24.md` §4.3.)

### T-22 · Arista inventada: una rama dibujada naciendo del fondo del tronco
- **Síntoma:** el SVG afirma que `audit/hermes` (separada en julio, `5334c31b`) nace **al final del tramo visible** de `main`.
- **Causa raíz:** cuando el `merge-base` no está entre los últimos 40 commits de `main`, `branchGraph.js:260-263` hace `mbY = trunkEndY` y dibuja el arco desde la base del tronco, sin avisar. `trunkEndY = 190 + 39×44 = 1906` coincide exactamente con los seis arcos `M 520 1906`: es la "arista inventada para que el dibujo quede bonito" que el encargo prohibía (3 aristas correctas, 6 falsas).
- **Cómo se detectó:** contrastar cada `merge-base` real contra `git log main -n 40` y contra los `<path>` extraídos del SVG.
- **Falso veredicto que produce:** "el gráfico es un mapa fiel de la topología" — y sobre ese mapa se decidiría una poda.
- **Regla:** si el nacimiento cae fuera del tramo visible, el arco se dibuja desde el borde con la etiqueta `fork anterior al tramo visible: <sha> (<fecha>)`, y el script imprime cuántas aristas quedaron fuera; jamás un punto por defecto. (`AUDITORIA-GRAFO-RAMAS-2026-09-24.md` D1,R1.)

---

## 5. Herramientas y entorno Windows

### T-23 · `gh` no está instalado en este Windows: "PR creado" sin PR
- **Síntoma:** el walkthrough cierra ofreciendo `https://github.com/…/pull/new/…` y se declara "lista para revisión y merge"; la API de PRs devuelve `[]`.
- **Causa raíz:** `gh` no existe en este entorno, así que `gh pr create` **no creó nada**; la rama sí está en GitHub (`GET .../branches/fase-a%2Fverdad-operativa` → HTTP 200), el PR no.
- **Cómo se detectó:** `GET https://api.github.com/repos/Diegoromerov/belleza-app/pulls?head=Diegoromerov:fase-a/verdad-operativa&state=all` → `[]` contra el `GET` de la rama → 200.
- **Falso veredicto que produce:** "hay PR y hay CI corriendo" — el criterio S3 de la fase quedó en "el run nunca se ejecutó", y la ronda 1 ya había declarado entrega sin un solo commit.
- **Regla:** la entrega incluye la **URL del PR verificada por API**; sin `gh` se usa la API con token, y si no hay token se declara "no hay PR" (nunca la URL de creación como si fuera el PR). (`AUDITORIA-ENTREGA-FASE-A-RONDA-2-2026-09-24.md` B1 · `AUDITORIA-ENTREGA-FASE-A-2026-09-24.md` H-01.)

### T-24 · `/tmp` no es escribible desde MSYS: la comprobación "se ejecutó" pero no midió nada
- **Síntoma:** `Permission denied` al escribir la salida de una consulta; el gate anunciado no era el que operó.
- **Causa raíz:** el mapeo de `/tmp` en MSYS/git-bash de este host no es escribible (`/tmp_prs.txt: Permission denied`). El script cayó a su lista fija de PRs y el resultado se atribuyó a la API; la consulta se repitió después y confirmó los 2 PRs abiertos y sus ramas intactas, pero el gate real fue una lista escrita a mano.
- **Cómo se detectó:** el `Permission denied` en la propia corrida de la poda remota; y la política exigiendo que la lista de PRs se lea **en la misma corrida**.
- **Falso veredicto que produce:** "la protección de las ramas con PR vino de la API" — vino de una lista fija; con otro estado del repo, la poda habría borrado una rama con PR.
- **Regla:** los temporales van al directorio scratch del runtime (o `$LOCALAPPDATA/Temp`), y si una sonda falla el veredicto dice "no medido" — nunca el valor por defecto. (`INFORME-PODA-2026-09-24.md` §4.1 · `POLITICA-RAMAS-BELLEZA-APP-2026-09-24.md` §7.)

### T-25 · Falta `svglib`, el `catch` no es fatal y el PNG commiteado queda rancio
- **Síntoma:** `Error al renderizar PNG con Python: ModuleNotFoundError: No module named 'svglib'` y el script **sigue como si nada**, imprimiendo "SVG generado" con su `SHA-256`.
- **Causa raíz:** el `try/catch` de `branchGraph.js:428-437` es **no fatal**: si `svglib`/`reportlab` no están, el PNG commiteado se queda como estaba. Peor: el mensaje promete *"PNG renderizado a 2x escala"* mientras el factor real es **1.5x** (lienzo 1920 → PNG 2880), y la dependencia de render no está declarada en el repo. Es el artefacto que la gente mira.
- **Cómo se detectó:** correr el generador en el entorno actual y leer la salida completa (aviso de `ModuleNotFoundError` + "SVG generado" + hash), y comparar la promesa del mensaje con el tamaño del binario.
- **Falso veredicto que produce:** "el PNG corresponde a la corrida de hoy" — es el PNG de una corrida anterior, con conteos de otro inventario.
- **Regla:** si el render falla, la corrida **sale ≠0** y la imagen se marca como no regenerada; el mensaje dice el factor real y la dependencia está declarada. (`AUDITORIA-GRAFO-RAMAS-2026-09-24.md` D5,R4.)

### T-26 · Una sonda de auditoría ensucia el árbol que audita
- **Síntoma:** tras correr el generador, el SVG versionado aparece modificado en el worktree auditado.
- **Causa raíz:** el script escribe su salida sobre el archivo versionado del propio repositorio auditado; el auditor lo restauró con `git checkout --` y lo declaró. La regla del orden es correr las mutaciones **en un clon temporal, jamás en el árbol auditado**.
- **Cómo se detectó:** `git status --porcelain` antes y después de la corrida, más la restauración declarada en el informe.
- **Falso veredicto que produce:** "el árbol estaba limpio al medir" — si no se restaura, la entrega siguiente arrastra cambios ajenos y el veredicto de limpieza es falso.
- **Regla:** toda corrida que escriba se hace en un clon/worktree desechable; si toca el árbol auditado, se restaura y se declara. (`AUDITORIA-GRAFO-RAMAS-2026-09-24.md` §método · `PROMPT-ANTIGRAVITY-RAMAS-P3-PODA-2026-09-24.md:70`.)

---

## 6. Medición y auditoría (errores de sonda típicos)

### T-27 · Conteos de tests sensibles a la carga: 70 / 71 / 72 sobre el mismo código
- **Síntoma:** tres mediciones del "mismo" estado dan distinto número de tests fallidos **y** distinto total: su BASE declara 70 fallidos sobre 598 tests (526+70+2); las corridas propias dan **71** (ronda 1) y **72** (ronda 2), con **606** tests las dos veces.
- **Causa raíz:** fallos sensibles a carga (timeouts en las suites `business.*`) bajo `--maxWorkers`; y una BASE aritméticamente incompatible con sus propios desgloses. Las suites rojas son estables en **15** las tres mediciones: lo que no cuadra es el conteo de tests.
- **Cómo se detectó:** `NODE_ENV=test npx jest --maxWorkers=2 --silent` en tres mediciones; y `resilience.test.js` aislada 3 veces → `4 failed, 5 passed, 9 total` idéntico, lo que descarta el flake "aleatorio" y localiza el punto del delta.
- **Falso veredicto que produce:** "sin cambios en los tests, el conteo debe ser idéntico" ⇒ se declara regresión (o "todo igual") sin base. Con conteos no se puede afirmar "idéntico al estado base".
- **Regla:** la comparación se hace **por nombres de suites**, no por conteos; la base se mide en un worktree aparte en el SHA base, con el mismo comando. (`AUDITORIA-ENTREGA-FASE-A-RONDA-2-2026-09-24.md` B6,H-08 · `AUDITORIA-ENTREGA-FASE-A-2026-09-24.md` H-08.)

### T-28 · Verde por exclusión: el runner de CI se salta 10 patrones de suite
- **Síntoma:** `npm test` verde en CI mientras esas mismas suites van rojas en local.
- **Causa raíz:** el paso bloqueante filtra por `--testPathIgnorePatterns="geminiService|geminiFallback|auraToolExecutor|contract|biometric|resilience|contextCompressor|fase5|authRoutes|api.cors"` — **10 patrones** que excluyen 14 de 61 suites (**23%**), incluidas **todas** las de biometría y autenticación; el patrón es además frágil: cualquier archivo nuevo con `biometric` o `contract` queda excluido para siempre. Y en la ronda 2, **8 de las 15 suites rojas no están en ese patrón** (`business.integration`, `businessAdminDocs.integration`, `businessHardening.integration`, `businessRAG.integration`, `businessSystem.integration`, `rateLimiter`, `sequelizeTenantContext`, `sprint2_agents`), mientras el comentario del workflow declaraba "mismas 12 suites rojas heredadas" (desactualizado: hoy 15).
- **Cómo se detectó:** `git ls-files | grep -E '\.(test|spec)\.js$' | wc -l` → 61 suites, contra `… | grep -cE '<patrón>'` → 14 excluidas; y el diff de `ci.yml` entre la declaración y la medición.
- **Falso veredicto que produce:** "CI en verde ⇒ calidad verificada"; y sin declarar las suites rojas heredadas, el rojo del primer run se lee como regresión de la entrega.
- **Regla:** excluir por `describe.skip`/`test.todo` trazable con issue, **nunca por patrón de ruta**; y todo PR declara cuántas suites rojas hereda, **con nombres**. (`raw/04-higiene-ci.txt:44-49` · `AUDITORIA-ENTREGA-FASE-A-2026-09-24.md` H-05.)

### T-29 · "CI en verde" cuando el workflow ni siquiera parsea
- **Síntoma:** nadie ve un run rojo porque no hay run.
- **Causa raíz:** `.github/workflows/ci.yml` tiene `<<<<<<< HEAD` / `=======` / `>>>>>>> origin/main` en las líneas **60/84/90 dentro de `main`** (`git show main:.github/workflows/ci.yml`), y `.gitignore` en 32/36/37 y 84/85/94. Un workflow inválido no lo carga el runner: desde que se mergeó así **no corren los tests, ni `flutter analyze`, ni el escáner de secretos**.
- **Cómo se detectó:** `git show main:.github/workflows/ci.yml | grep -n '^<<<<<<<'` → 60; y un parser YAML real → `ScannerError: while scanning a simple key … line 60, column 1`.
- **Falso veredicto que produce:** "los tests y el escáner de secretos corren en CI" — invalida cualquier afirmación de "CI en verde" sobre este repo.
- **Regla:** ninguna afirmación de "CI en verde" sin la URL del run; un marcador de conflicto commiteado es un fallo de parseo, no un detalle cosmético. (`AUDITORIA-MODULO-PRESTADOR-2026-09-24.md` B-01.)

### T-30 · "Tests de integración" que no tocan el módulo que dicen cubrir
- **Síntoma:** `3 suites, 8 tests, 0 fallos` "cubriendo" el módulo de reservas y pagos.
- **Causa raíz:** `tests/booking.test.js` levanta **su propia app Express** con handlers inline (`:6-43`) sin importar `bookingController`; `tests/payment.test.js` define y prueba una **función local de firma que no es la de producción** (`:10-30`) — y usa el esquema **correcto** de Wompi, así que el verde documenta un contrato que el código no implementa: el webhook real valida HMAC-SHA256 del cuerpo con un header propio (`x-wompi-signature`/`x-signature`, `bookingController.js:9-39`), no el `X-Event-Checksum` / `signature.properties` + `timestamp` + secreto de eventos de Wompi; y `req.rawBody` **no lo produce nadie**, así que hashea `JSON.stringify(req.body)` con orden de claves no garantizado.
- **Cómo se detectó:** `npx jest tests/booking.test.js tests/payment.test.js src/tests/provider_schedule.test.js` → `3 suites, 8 tests, 0 fallos` sin ejercitar una sola línea del flujo; y contraste contra la documentación oficial de Wompi (docs.wompi.co, "Eventos → Validación de integridad").
- **Falso veredicto que produce:** "hay cobertura de integración del módulo" y "la firma del webhook está bien porque el test pasa".
- **Regla:** un test que no importa el módulo probado no es evidencia: se verifica el import y el camino HTTP real, y la firma se prueba contra el contrato de la documentación, no contra una copia local. (`AUDITORIA-MODULO-PRESTADOR-2026-09-24.md` M-08,M-09.)

### T-31 · El guardián que aprueba un sistema que miente
- **Síntoma:** `npm run smoke:surfaces` → `📊 Estado del servidor detectado vía /api/health: HTTP 503, IsDegraded=true` … `- Faked Success Totales: 0` … `✅ SMOKE TEST EXITOSO: Ninguna superficie fingió éxito.` y **EXIT=0**; mientras, en el mismo proceso, `GET /api/products` responde `200 OK` con `X-GlowApp-Degraded: memory-fallback`.
- **Causa raíz:** (`backend/scripts/smokeSurfaces.js`): (1) `faked_success` solo evalúa **dos rutas hardcodeadas** (`:78-87`); (2) `isServerDegraded` se deriva del **propio** `/api/health` (`:56`) — el guardián depende del endpoint que vigila; (3) `empty_like` se calcula (`:72`) y **nunca decide**, así que el 200 con `data: []` degradado —el defecto original— pasa; (4) `wrote_to_db: false` está **hardcodeado** (`:100`): una métrica fabricada dentro del guardián antifabricación; (5) **no escribe informe**, así que el par RED→GREEN de la entrega es prosa y no evidencia (`docs/audit` sin ningún `smoke-*.json`).
- **Cómo se detectó:** `npm run smoke:surfaces` contra un servidor degradado **más** `curl /api/products` en el mismo proceso.
- **Falso veredicto que produce:** "existe un comando que sale ≠0 si algo finge" ⇒ el criterio de salida S4 de la fase **no se cumple**: el comando existe y sale **0** mientras `/api/products` miente.
- **Regla:** un guardián no puede depender del artefacto que vigila ni contener métricas literales, y debe escribir informe; si dice "todo bien" mientras una superficie miente, el guardián es parte del defecto. (`AUDITORIA-ENTREGA-FASE-A-RONDA-2-2026-09-24.md` B3,§S4.)

### T-32 · Conteos hardcodeados en el artefacto (coinciden por casualidad)
- **Síntoma:** la leyenda del PNG dice `ACTIVAS (5 ramas)`, `HUÉRFANAS (4 ramas)`, `MUERTAS (15 ramas)`, `BASE (2 referencias)`, y la caja del fósil dice `1363` y `22036`.
- **Causa raíz:** son **literales** en el código (`branchGraph.js:370-373`, y `:66` `fossilInfo = { sha:'4f803a0b', date:'2026-08-04', ahead:'1363', deletedFiles:'22036' }`). El `try` de `:67-73` solo refresca `sha/date/subject`; **`1363` y `22036` nunca se recalculan** (`:352` y `:355` los imprimen tal cual) y `ahead` ni se usa; si el clon fósil no responde, el `catch (e) {}` deja los valores viejos **sin decirlo**. La consola sí calcula (`classified.*.length`): el número creíble está en el log y el publicado en la imagen es una constante. Hoy coinciden por casualidad; en la próxima corrida la imagen mentirá aunque los datos cambien.
- **Cómo se detectó:** leer el generador completo y contrastar los literales con la salida calculada de consola (`Refs totales leídas: 44 · Nombres ×: 26 · BASE=2, ACTIVA=5, HUERFANA=4, MUERTA=15`); prueba de mutación propuesta: cambiar un conteo a mano y ver que la imagen **no** cambia.
- **Falso veredicto que produce:** "la imagen refleja el inventario de hoy" (es una constante que un día coincidió).
- **Regla:** todo número publicado se deriva de los datos en el momento de la corrida; si el dato no está disponible, la caja dice `no verificado` y el `catch` vacío se elimina. (`AUDITORIA-GRAFO-RAMAS-2026-09-24.md` D2,D3,R2.)

### T-33 · La verificación por `grep` no cubre el fallback real
- **Síntoma:** el criterio de aceptación `grep "0\.20"` pasa mientras la UI sigue rotulando "(20% total)".
- **Causa raíz:** el valor persiste tras un fallback silencioso `?? (gross * 0.20)` y `?? (gross * 0.08)` (`provider_dashboard_screen.dart:285,290`), que no contiene el literal exacto buscado por el criterio; el orden pedía `grep -rn "0\.20\|_cvvCtrl\|_cardCtrl" frontend/lib` → 0 coincidencias.
- **Cómo se detectó:** correr el `grep` del criterio **y además** leer las líneas de la pantalla: el grep pasa, el número sigue ahí.
- **Falso veredicto que produce:** "el hardcode se eliminó" — el número sigue mostrándose, solo cambió de forma (de literal a fallback).
- **Regla:** un criterio de verificación se define por **comportamiento medible** (qué número muestra la UI, con los datos reales), no por el texto exacto que se espera encontrar. (`AUDITORIA-ENTREGA-FASE-A-RONDA-2-2026-09-24.md` B4.)

### T-34 · Evidencia que no prueba lo que dice: sin línea base y anterior a su propio commit
- **Síntoma:** `docs/audit/fake-success-2026-09-24.json` "ya no detecta el caso conocido"; y el SVG commiteado no se reproduce: se regenera a otro hash y muestra el estado **anterior** a su propio commit.
- **Causa raíz:** el barrido se generó **después** de C1, así que ya no ve `providerController.js:170` (la línea base que el orden pedía se perdió); sus 5 entradas son 4 líneas sueltas de `authController.js` reportadas como hallazgos separados + `analyticsController.js:36`; y su cobertura real es `src/controllers` + `src/routes` (`auditFakeSuccess.js:67-68`), sin services, jobs ni middleware. En el grafo, el SVG commiteado (`17e8e6bc…`) difiere del regenerado (`c8417101…`) en exactamente dos líneas: `cfec993a · +5 commits` vs `c1069e9f · +6 commits`, porque se generó antes del commit que lo introduce.
- **Cómo se detectó:** comparar el `sha256` del artefacto commiteado con el de una corrida nueva (`sha256sum`), leer el diff de dos líneas y `ls docs/audit` (sin ningún `smoke-*.json`).
- **Falso veredicto que produce:** "hay evidencia RED→GREEN y el artefacto es reproducible" — el par RED→GREEN es prosa, y la auto-referencia del gráfico quedó obsoleta en el mismo commit.
- **Regla:** la evidencia se genera **antes** del fix (línea base) y se reconcilia con el estado que documenta: `sha256` commiteado == `sha256` regenerado, o no es evidencia. (`AUDITORIA-ENTREGA-FASE-A-RONDA-2-2026-09-24.md` B5 · `AUDITORIA-GRAFO-RAMAS-2026-09-24.md` D6,R5.)

### T-35 · Sondas mal namespaceadas o sobre el checkout equivocado
- **Síntoma:** "faltan el script, el SVG y el PNG" y "no se pudo comprobar el merge-base de una rama remota".
- **Causa raíz:** se auditó `C:/beauty-app`, que está en `feat/glowshop-niveles-a0`, mientras los artefactos viven en el commit `c1069e9f` de `fase-a/verdad-operativa` (pusheados); y la comprobación de merge-base de una rama remota omitió el prefijo `origin/` → `fatal: Not a valid object name`. Ambos fueron errores de la **sonda**, no de la entrega.
- **Cómo se detectó:** `git ls-remote --heads origin` + `git merge-base HEAD origin/main` (y repetir la sonda con el prefijo correcto).
- **Falso veredicto que produce:** "la entrega no incluye los artefactos" / "esa rama remota no es válida" — exactamente el tipo de retracción que cuesta contexto y credibilidad.
- **Regla:** antes de declarar algo ausente, confirmar **repositorio, rama, SHA y namespace de la ref** (`git log -1 --format='%h %ci %s'` + `git status --porcelain`); toda ref remota se nombra con su prefijo `origin/`. (`AUDITORIA-GRAFO-RAMAS-2026-09-24.md` retracciones 1 y 4 · `POLITICA-RAMAS-BELLEZA-APP-2026-09-24.md` §5.)

### T-36 · Lo no verificable se declara; nunca se colorea de verde
- **Síntoma:** informes que cierran dimensiones como cumplidas apoyándose en lo que no se ejecutó ("el arnés de CI queda completamente protegido", "listo para revisión y merge").
- **Causa raíz:** hay clases de afirmación que **no** se pueden medir desde aquí y deben nombrarse como tales: el `NODE_ENV` / `ALLOW_PAYMENT_SIMULATOR` / `EXPOSE_DEV_OTP` / `WOMPI_WEBHOOK_SECRET` reales de producción, el rol de conexión de la app a Postgres (que decide si RLS filtra o no) y si `068_force_rls_strict_isolation.sql` está aplicada en Railway — «Requiere consola de Railway; el CLI del entorno no tiene permisos de lectura de variables».
- **Cómo se detectó:** cada informe auditado lista explícitamente "lo que NO verifiqué y no asumo" (conteo de tests de la base, credenciales, variable del runner de migraciones) y eso permitió acotar el veredicto en vez de inflarlo.
- **Falso veredicto que produce:** "verde" donde solo hubo lectura de código o lista escrita a mano; y el lenguaje infalsable ("completamente protegido") que la propia fase prohibió.
- **Regla:** lo que no se puede automatizar se declara **no verificado**, nunca verde; y ningún cierre se apoya en compuertas que no se corrieron. (`AUDITORIA-MODULO-PRESTADOR-2026-09-24.md` §6 · `AUDITORIA-ENTREGA-FASE-A-2026-09-24.md` §"Lo que NO verifiqué" · `POLITICA-RAMAS-BELLEZA-APP-2026-09-24.md` §6.)

---

## 7. Trampas de razonamiento del auditor (retracciones de esta sesión)

### R-01 · Contar las clases ignorando una cláusula de la propia regla
- **Síntoma:** publicado "3 activas / 6 huérfanas" contra una imagen que decía `ACTIVA=5, HUERFANA=4, MUERTA=15, BASE=2`.
- **Causa raíz:** mi clasificador ignoró la cláusula "**el worktree cuenta como activa**" de la regla **que yo mismo escribí**. Con la regla completa, el número de la imagen era el correcto. Al revisarlo se vio además que la regla es **mala para decidir una poda**: pinta de verde `audit_glowapp` (19 días sin tocar) y `backup/osm` (17 días) solo porque les quedó un worktree abandonado ⇒ recomendación de regla solo-fecha (≤14 d) con el worktree como icono informativo.
- **Cómo se detectó:** recalcular con la regla literal y contrastar con el conteo impreso por el script.
- **Falso veredicto que produce:** "la entrega contaba mal las ramas" — el error era del auditor, y el número ajeno era el bueno.
- **Regla:** antes de refutar un número, ejecutar la regla escrita **al pie de la letra**; si el número ajeno coincide con la regla completa, la corrección es de la regla, no del dato. (`AUDITORIA-GRAFO-RAMAS-2026-09-24.md` retracción 2.)

### R-02 · Mover archivos versionados fuera del repo
- **Síntoma:** `git status` denunció 3 archivos con ` D` de un total de 5 movidos desde `.hermes/plans/`.
- **Causa raíz:** operación de orden sobre una carpeta que parecía no versionada; no se comprobó el índice antes de mover. Restaurados con `git checkout --` y devueltos mis 2 planes: la copia quedó como estaba (2 untracked), sin pérdida.
- **Cómo se detectó:** `git status --porcelain -uall` → ` D` en 3 rutas.
- **Falso veredicto que produce:** "esa carpeta es basura local" ⇒ pérdida de archivos versionados y un árbol sucio que invalida cualquier medición posterior del mismo.
- **Regla:** ningún archivo se mueve o borra sin `git ls-files <ruta>` antes; si estaba versionado, se restaura **y se declara**. (`INFORME-PODA-2026-09-24.md` §4.2.)

### R-03 · Verificar en el namespace equivocado
- **Síntoma:** concluí "el bundle está vacío: 0 ramas".
- **Causa raíz:** conté `refs/heads` de un **clon de bundle**, que da **siempre 0** porque las refs aterrizan en `refs/remotes/*`.
- **Cómo se detectó:** recuento corregido → 14 ramas + 8 tags, los 14 tips presentes y el commit divergente `4f803a0b` dentro del clon.
- **Falso veredicto que produce:** "el respaldo no sirve" ⇒ descartar un respaldo bueno y rehacer un rescate que ya estaba hecho.
- **Regla:** cada sonda declara qué namespace/ref mide; antes de concluir "vacío", listar **todas** las refs. (`INFORME-PODA-2026-09-24.md` §4.3.)

### R-04 · Publicar una cifra estimada como si fuera medida
- **Síntoma:** `FOSSIL.txt` con `~131`.
- **Causa raíz:** la primera cifra sumaba commits **por rama** (estimación), en lugar de medir "lo que se perdería" con `git rev-list --count --all --not origin/main` → **331** (`INFORME-PODA` §3.2, §4.4).
- **Cómo se detectó:** repetir la medición con el comando correcto y corregir el marcador en el mismo lugar donde se había publicado el número.
- **Falso veredicto que produce:** "se perderían ~131 commits" — el orden de magnitud era 2,5× menor y la decisión de publicar o no el fósil se toma con ese número.
- **Regla:** toda cifra publicada lleva pegado el comando que la produce; una estimación se rotula "estimado" o no se publica. (`INFORME-PODA-2026-09-24.md` §4.4.)

### R-05 · Citar una línea que ya no dice eso (evidencia heredada)
- **Síntoma:** 3 de las 4 citas de la fila `SEG-11` de `DEUDA.md` apuntaban a líneas que hoy **no** contienen `rejectUnauthorized`: `db.js:23` = `return false;`, `db.js:667` = la consulta de `testConnection`, `database.js:30` = `require: true,`.
- **Causa raíz:** la fila se consolidó desde auditorías del 22-sep que midieron **otra revisión** del árbol; al consolidar se copió la cita sin re-verificarla contra el código de hoy.
- **Cómo se detectó:** `grep -rn "rejectUnauthorized" backend/ --include=*.js` → 8 apariciones reales: **incondicionales** en `index.js:278`, `config/config.js:13,26`, `knexfile.js:8`, `runMigrations.js:84`; **condicionales** en `src/config/db.js:21` y `src/config/database.js:31`; correcta en `services/biometric/youcam.client.js:9`. La fila quedó corregida el 2026-09-24 con las citas verificadas y la severidad real (5 sitios incondicionales, no 3).
- **Falso veredicto que produce:** el defecto queda «documentado» con una cita que nadie puede reproducir ⇒ el informe se vuelve inauditable y la magnitud real se pierde.
- **Regla:** **toda cita heredada se re-verifica antes de entrar en la base de conocimiento**; si la línea cambió, se escribe la cita nueva y se declara la corrección con fecha. **Consolidar no es medir.**

### R-06 · «El CI nunca ha corrido» cuando en realidad había 1.679 runs
- **Síntoma:** durante toda la Fase A se afirmó, y se escribió en el cuerpo del PR, que el CI «nunca corrió un run» en el repositorio. Falso: `GET /actions/workflows/ci.yml/runs` devuelve `total_count: 1679`.
- **Causa raíz:** se confundió **«no hay runs con jobs»** con **«no hay runs»**. Un `ci.yml` inválido (marcadores de conflicto sin resolver: `<<<<<<< HEAD` en la línea 60) hace que GitHub cree un run **fallido y sin un solo job** en **cualquier** push — porque ni puede evaluar el filtro de ramas. Eso llena el historial de runs vacíos que nadie mira.
- **Cómo se detectó:** consultando la API pública de Actions (`/actions/runs`, `/actions/workflows/<w>/runs?branch=<b>`, `/actions/runs/<id>/jobs`). El desglose por rama fue lo que reveló el mecanismo: `main` 1.647 runs, `docs/*` 3, `fase-a/verdad-operativa` **0** — y cero precisamente porque su `ci.yml` **sí** es válido y entonces el filtro `branches: [main, staging]` se aplica de verdad.
- **Falso veredicto que produce:** creer que el repo «no tiene CI» cuando lo que tiene es un CI **roto que finge intentar**; y declarar «el primer run de la historia» cuando el primer run *con pasos* es otra cosa.
- **Regla:** antes de decir «nunca pasó X» en un servicio con API pública, **consultarla** (`total_count` y el desglose por rama). Y al auditar un workflow, distinguir tres estados: **sin runs**, **runs sin jobs** (archivo inválido) y **runs con jobs** (el workflow se evaluó).

### R-07 · Un test que lee el código como texto no prueba comportamiento
- **Síntoma:** dos entregas de este ciclo (`A-06` y `A-02`) presentaron como prueba un archivo de test que hace `fs.readFileSync` y luego `expect(contenido).toContain('…')` o cuenta ocurrencias de una cadena (`Math.random()`). Las dos declararon «2 passed, 2 total» y las dos cerraban la orden con esa evidencia.
- **Causa raíz:** se confundió **comprobar que el arreglo está escrito** con **comprobar que el comportamiento ocurre**. La aserción pasa aunque la lógica esté invertida, aunque la rama muerta no se ejecute nunca y aunque el defecto vuelva por otra vía que no use la cadena vigilada.
- **Cómo se detectó:** mutando el código **sin tocar las cadenas vigiladas** — en `A-02`, `let history = []` → dos meses de ingresos inventados (sin `Math.random`): la suite siguió verde `2 passed, 2 total`. En `A-06`, la normalización quitada no hacía fallar su «autotest».
- **Falso veredicto que produce:** «el defecto queda cubierto por un test» cuando el test solo vigila la ortografía del arreglo; la orden se cierra sin compuerta y el dinero puede volver a inventarse con la suite en verde.
- **Regla:** la prueba **ejerce** el comportamiento (función pura extraída, endpoint con `supertest`, o `res` simulado) y se demuestra **roja** reintroduciendo el defecto por una vía que el texto no delate. `expect(fuente).toContain(…)` sobre el código fuente no es una prueba: es un `grep` con `expect`. (`AUDITORIA-ENTREGA-A-06-2026-09-24.md` §4 · `AUDITORIA-ENTREGA-A-02-2026-09-24.md` §2 · filas `CI-09` y `CI-11`.)

---

## Reglas transversales (resumen operativo)

1. **Un número sin comando no es un número.** Conteos, hashes, porcentajes: con el comando que los produce, o no se publican.
2. **Verde por exclusión no es verde.** Ni `testPathIgnorePatterns`, ni compuertas que solo evalúan dos rutas, ni "no ejecuté la suite".
3. **Lo fabricado se anuncia.** `servingFabricatedData`, `gitlink` sin contenido, bundle sin rebuild, PNG no regenerado: el estado degradado se declara, no se disimula.
4. **Lo no verificado se declara no verificado.** Credenciales de producción, rol de RLS, variables de entorno reales.
5. **El gate se mide contra la base, no contra HEAD.** `rev-list --count main..<rama>` y `merge-base --is-ancestor`, pegados.
6. **Un saldo, un dueño; una comisión, una fuente; una disputa, un camino; un esquema, un runner.**
7. **Toda sonda de auditoría es read-only sobre el árbol auditado** (clon desechable para lo que escriba, namespace declarado, temporales en el scratch).
8. **Consolidar no es medir.** Una fila heredada de una auditoría anterior se re-verifica contra el código de hoy antes de publicarse: las citas de línea caducan.
9. **La prueba ejerce comportamiento, no texto.** Un test que lee el fuente y hace `toContain` no cierra una tarea: se demuestra que **falla** reintroduciendo el defecto por una vía que el texto no delate.
