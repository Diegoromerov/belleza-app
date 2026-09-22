# Plan de correcciones — Funcionalidad no real de GlowApp

> **Para Hermes:** plan por fases con gates. No ejecutar una fase sin cerrar la anterior y sin decisión tomada.

**Ruta raíz de trabajo:** `C:\Users\Compu casa\.gemini\antigravity\worktrees\beauty-app\setup_glowguide_architecture`
**Rama:** `baseline-v1-stable` @ `77497a20` — **sin commit, sin push**. Solo working tree + reporte.
**Alcance:** convertir en funcional lo falso o inalcanzable. No es iteración de diseño ni de refactor.

**Reglas no negociables heredadas del prompt original:**
1. Causa raíz, no parche. Si algo se ve bien por datos escritos a mano, el arreglo es quitar los datos a mano.
2. Verificación end-to-end obligatoria: comando + resultado observado + evidencia `archivo:línea` del antes y el después. Sin esto el punto queda **ABIERTO**.
3. Prohibido fabricar éxito: nada de `success: true` local, `Future.delayed` que sustituya una llamada real, ni `catch` que devuelva datos de ejemplo.
4. No avanzar de fase sin gate.
5. No commit, no push.

---

## 0. Estado verificado del inventario

Verificación mecánica completa ejecutada (no lectura). El inventario **se sostiene en sustancia**; las 7 líneas de `main.dart` estaban corridas +5.

| Punto | Estado | Evidencia |
|---|---|---|
| 1.1 tienda cobra sin cobrar | CONFIRMADO | `store_screen.dart:391` genera `STORE_…` · `wompi_payment_sheet.dart:117-125` fabrica `success:true` · `store_screen.dart:397-403` postea el pedido con ese `true` |
| 1.2 propina con temporizador | CONFIRMADO | `client_bookings_screen.dart:196` *(comentario: "Simulación de pasarela")* · `:228` · `:241` `Future.delayed(2500ms)` · `:244` `onSuccess()` · invocada en `:538` |
| 1.3 backend no valida | CONFIRMADO **y peor** | `orderController.js:129-132` → `INSERT … VALUES (…, 'PAGADO', …)`. El pedido **nace pagado**. `wompi=0 transaction=0 verific=0` en el archivo |
| 2 invitación inutilizable | CONFIRMADO | `/accept-invitation` declarada en `main.dart:241`, **0 navegaciones**; 0 refs a `app_links`/`uni_links`/`getInitialLink` |
| 3.1 tablero del salón | CONFIRMADO | `salon_dashboard_screen.dart:61` éxito → `:80-93` inventa `Salón Elegance Studio`/NIT `901888777-1`/`FREE_TRIAL` · `:933-958` servicios a mano · `:602-603` `'Citas Hoy'` = `_bookings.length` |
| 3.2 Business Center | CONFIRMADO | `business_dashboard_screen.dart:19-21`, `:69-75` (`Future.delayed(500ms)` en `onRefresh`), `:96-113`, `:126-130` |
| 4 rutas y archivos muertos | CONFIRMADO | Las 7 rutas sin navegación · 5 archivos con 0 referencias |

**Correcciones al inventario (sustancia intacta):**
- Líneas de `main.dart`: `/accept-invitation` `:241` · `/provider-route` `:261` · `/terms` `:277` · `/medical-validation` `:291` · `/glowup-card` `:292` · `/colorimetria-historial` `:294` · `/wardrobe` `:295`.
- `product_detail.dart` **sí** está referenciado, por `product_list.dart`. El muerto es el **par**, no dos archivos sueltos.
- `/accept-invitation` tiene 2 ocurrencias: la ruta (`main.dart:241`) y la URL del API (`auth_service.dart:301`). Nadie navega, la conclusión se mantiene.
- El 1.3 no es "no valida": es que **escribe el estado pagado a mano**, pisando el `DEFAULT` correcto del esquema (`migrations/010_implement_glowstore_schema.sql:66`).

**Hallazgo mayor — el inventario se equivoca en Severidad 5:**
```
bookingController.js:461| await new Promise(resolve => setTimeout(resolve, 1500));   ← latencia fingida
bookingController.js:463| const referenceToken = 'wompi_sim_' + Math.random()…
bookingController.js:467| booking.estado = 'CONFIRMADA';
bookingController.js:468| booking.payment_status = 'paid';
bookingController.js:545| console.log('[WOMPI SIMULATOR SUCCESS] … de forma local.')
```
`POST /api/bookings/:id/pay` **no está condicionado a `NODE_ENV`** y **no llama a Wompi**. `wompiService.js` solo tiene `disbursePayout` (`:10`) y `crearPayout` (`:63`): **no existe ninguna función de cobro en el repo**. `paymentRoutes.js` (14 endpoints) tampoco tiene uno. No hay `.wompi.co`, ni integrity hash, ni `checkout_url` en `src/`.

⇒ **FASE 1.1 no es realizable como está escrita.** La rama de `wompi_payment_sheet.dart` no es la única puerta falsa: es un atajo que ni siquiera llega al simulador del backend, que es igual de falso.

**Lo que sí está bien hecho (y no hay que tocar):**
- `bookingController.js:9-39` `verifyWompiSignature`: fail-closed sin secreto, exige cabecera, HMAC-SHA256 sobre `req.rawBody`, `timingSafeEqual` con chequeo de longitud. **Es serio.**
- `salonController.js:169-187` invitaciones: token de 32 hex, **sha256 en base** (no en claro), `expires_at`.
- `businessRoutes.js:14-36`: la API de cumplimiento **existe y está completa**.

---

## 1. Decisiones que bloquean (con recomendación)

| # | Decisión | Bloquea | Recomendación |
|---|---|---|---|
| **D1** | Dinero: construir pasarela real / hacerlo honesto sin pasarela / solo la tienda | FASE 1 completa | **Honesto sin pasarela**: cierra Gate 1 verificable y no obliga a decidir la pasarela con prisa |
| **D2** | Propina: cobro real o retirar | T1.4 | **Retirar**: no existe endpoint ni columna de propina (0 en todo `backend/src`) |
| **D3** | Invitación: deep link / página web / entrada en la app | FASE 2 completa | **Entrada en la app** ("Tengo un código"): funcional hoy, sin `app_links` ni config nativa |
| **D4** | Business Center: conectar API existente / solo lectura / marcar demo | T3.4 | **Conectar la API real** que ya existe |
| **D5** | Cuáles pantallas de Severidad 4 conservar | FASE 4 | Conservar solo `/terms` (legal, obligatorio) |
| **D6** | `/glowup-card` y `/provider-route` | T4.7 | Eliminar las dos |

---

## 2. Prerrequisitos verificados (riesgos que hay que resolver antes o dentro)

| # | Hallazgo | Impacto | Tarea |
|---|---|---|---|
| **P1** | `migrations/062_optimize_business_saas_postgres.sql` referencia `business_tasks` pero **no lo crea**; en `beauty_db` falla con `relation "business_tasks" does not exist` | T3.4 (`/business/tasks`) devolverá error si conecta a una tabla que no existe | T0.2 |
| **P2** | 4 migraciones rotas en `beauty_db`: `031` (`deleted_at`), `034` (unique constraint academia), `037` (`consent_type`), `062` (`business_tasks`) — preexistentes, ahora visibles | Cualquier feature que toque esas tablas fallará | T0.3 |
| **P3** | **No está probado que `services` tenga `salon_id`**; la búsqueda en `migrations/*.sql` no encontró vínculo salón→servicios | La pestaña "Servicios" (T3.3) no tiene fuente clara | T0.4 |
| **P4** | `salonController.js:227-247` inserta en `salon_miembros` **sin comparar `invitation.email` con el usuario logueado**: cualquier usuario con el token entra | Es exactamente el caso "usuario logueado con otro correo" del punto 2.3, y **no está implementado** | T2.4 |
| **P5** | `.env` no tiene `WOMPI_WEBHOOK_SECRET` (sí `.env.example:9`) | El webhook rechaza todo con 401 en local (`fail-closed`, correcto). En producción debe estar o nada se confirma | T0.5 |
| **P6** | `backend/public/main.dart.js` es un build web de Flutter **obsoleto**; el `inviteLink` apunta a `https://…railway.app/#/accept-invitation` | Si se elige D3=página web, hay que reconstruir y desplegar | T2.1 |

---

## FASE 0 — Andamiaje de verificación (no toca producto)

**Objetivo:** que el gate de FASE 1 sea automático y que sea imposible volver a fabricar un cobro sin que algo se ponga rojo.

### T0.1 — Guard anti-fabricación de pagos
**Crear:** `backend/scripts/verifyNoFabricatedPayments.js`
**Contenido:** escanea y falla (exit 1) si encuentra:
- `Math.random()` en la misma función que escribe `estado`/`payment_status`/`status`
- `'PAGADO'` o `'paid'` como literal en un `INSERT`/`UPDATE` de estado
- `success: true` literal en `frontend/lib/**` fuera de tests
- `Future.delayed`/`setTimeout` inmediatamente antes de una transición a pagado/confirmado

**Verificación:**
```bash
node backend/scripts/verifyNoFabricatedPayments.js; echo "exit=$?"
```
**Esperado HOY: exit 1** con `orderController.js:132`, `wompi_payment_sheet.dart:120`, `bookingController.js:463`, `client_bookings_screen.dart:241`.
*Un guard que nace verde no sirve: tiene que detectar los fakes actuales.*

### T0.2 — Resolver `business_tasks`
**Verificar:** `grep -rn "business_tasks" backend/migrations/ | head`
**Decidir:** ¿qué migración debía crearla? Si el DDL solo existe en Railway, crear la migración idempotente que falta (`CREATE TABLE IF NOT EXISTS`) y **no** depender de la base de Railway.

### T0.3 — Documentar las 4 migraciones rotas
**Verificar (base real):**
```bash
PORT=8080 node backend/index.js 2>&1 | grep "Advertencia en migración"
```
**Esperado:** `031`, `034`, `037`, `062`. No se arreglan en esta iteración salvo que T3.4 lo exija (P1).

### T0.4 — Confirmar el vínculo salón→servicios
```bash
docker exec -i beauty-postgres psql -U admin -d beauty_db -c "\d services" | grep -iE "salon|provider"
curl -s localhost:8080/api/services/provider -H "Authorization: Bearer $TOKEN" | head -c 400
```
**Decidir:** si no hay `salon_id`, T3.3 se hace contra `/api/services/provider` (catálogo del prestador) **y se documenta** que el catálogo es por prestador, no por salón.

### T0.5 — Documentar el secreto de Wompi
Añadir a `.env.example` la nota de que `WOMPI_WEBHOOK_SECRET` **debe** existir en producción (hoy el webhook rechaza con 401, que es el comportamiento correcto pero deja la pasarela muerta en local).

**Gate 0:** T0.1 en exit 1 con los 4 hallazgos, T0.4 respondido, T0.2 decidido.

---

## FASE 1 — Dinero (no se avanza sin cerrar esto)

**Depende de D1 y D2.**

### T1.1 — El pedido deja de nacer pagado (causa raíz de 1.3)
**Modificar:** `backend/src/controllers/orderController.js:129-145`
**Acción:** quitar `'PAGADO'` y la columna `estado` del `INSERT`, dejando que aplique el `DEFAULT 'PENDIENTE_PAGO'` del esquema (`migrations/010_implement_glowstore_schema.sql:66`). **No** aceptar `estado` desde `req.body`.
**Verificación:**
```bash
curl -s -X POST localhost:8080/api/store/checkout -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' -d '{"nombre_entrega":"X","direccion_entrega":"Y","items":[{"id":1,"cantidad":1}]}'
docker exec -i beauty-postgres psql -U admin -d beauty_db \
  -c "SELECT id, estado, creado_en FROM pedidos_tienda ORDER BY creado_en DESC LIMIT 3;"
```
**Esperado:** respuesta `success` y fila con `estado = PENDIENTE_PAGO`. Antes: `PAGADO`.

### T1.2 — Eliminar la rama de pago fabricado (1.1)
**Modificar:** `frontend/lib/widgets/wompi_payment_sheet.dart:117-129`
**Acción:** borrar el bloque `if (widget.bookingId.startsWith('STORE_'))` completo. Todo pago pasa por la ruta real del backend. Si esa ruta no existe (hoy no existe para la tienda), la hoja **muestra error** y no devuelve éxito.
**Verificación:** `grep -rn "STORE_" frontend/lib/` → **0 resultados**. `flutter analyze` limpio.

### T1.3 — La tienda no registra pedido sin pago aprobado
**Modificar:** `frontend/lib/screens/store_screen.dart:389-411`
**Acción:** `POST /api/store/checkout` solo si el pago devolvió una referencia **verificable**; en cualquier otro caso, error visible y el carrito intacto. Quitar el `paymentResult == true` local como condición suficiente.
**Verificación:** con el cobro no disponible, la compra **no** crea fila y el usuario ve error:
```bash
docker exec -i beauty-postgres psql -U admin -d beauty_db -c "SELECT count(*) FROM pedidos_tienda;"
```
**Esperado:** el conteo no sube tras intentar comprar.

### T1.4 — Propina (según D2)
**Si se retira:** `frontend/lib/screens/client_bookings_screen.dart`
- Borrar `_runWompiCheckout` (`:196-246`), el módulo de propinas (`:253`, `:422-448`), y la llamada en `:538`; el flujo de reseña sigue funcionando sin propina.
- Verificación: `grep -n "propina\|Propina" frontend/lib/screens/client_bookings_screen.dart` → 0. `flutter analyze` limpio.
**Si se cobra real:** requiere endpoint + columna (no existe ninguna) ⇒ **fase propia**, no cabe en esta iteración.

### T1.5 — (Solo si D1 = construir pasarela) Integración de cobro real
Fuera de alcance de este plan hasta que se decida. Requiere: endpoint de creación de transacción con firma de integridad, `checkout_url`, y que el webhook (`bookingRoutes.js:27`) sea el único que mueva a `PAGADO`; aplicarlo **también** a `bookingController.js:435-558`.

**Gate 1:** con la pasarela simulada caída o errada, la compra **NO** se registra como pagada y el usuario ve el error. Evidencia: petición + respuesta + fila en BD.

---

## FASE 2 — Invitación de equipo de punta a punta

**Depende de D3.**

### T2.1 — Entrada en la app (si D3 = entrada in-app)
**Modificar:** pantalla de login/perfil + `frontend/lib/screens/auth/accept_invitation_screen.dart`
**Acción:** campo "Tengo un código de invitación" que acepte el token de 32 hex **o la URL completa** (extraer el token de `?token=`); navegar a `/accept-invitation` con ese token. Esa es la navegación que hoy no existe (`main.dart:241` tiene la ruta y nadie la usa).

### T2.2 — Cerrar el flujo contra datos reales
```bash
# 1. dueño invita
curl -s -X POST localhost:8080/api/salon/invite -H "Authorization: Bearer $TOKEN_DUENO" \
  -H 'Content-Type: application/json' -d '{"salon_id":1,"email":"colab@test.com","sub_rol":"EMPLEADO"}'
# 2. colaborador acepta con ese token
curl -s -X POST localhost:8080/api/salon/accept-invitation -H "Authorization: Bearer $TOKEN_COLAB" \
  -H 'Content-Type: application/json' -d '{"token":"<32 hex>"}'
# 3. aparece en Equipo
curl -s localhost:8080/api/salon/members -H "Authorization: Bearer $TOKEN_DUENO"
```
**Esperado:** el tercer paso lista al colaborador con `sub_rol = EMPLEADO`.

### T2.3 — Errores reales
Vencido y ya usado **ya funcionan** en el backend (`salonController.js:219-224`). Verificar con:
```bash
# token vencido: exigir expires_at en el pasado
docker exec -i beauty-postgres psql -U admin -d beauty_db \
  -c "UPDATE salon_invitaciones SET expires_at = NOW() - interval '1 day' WHERE email='colab@test.com';"
# reintentar aceptar → esperado: 400 'La invitación es inválida, ya fue usada o ha expirado.'
```

### T2.4 — P4: el correo no se compara
**Modificar:** `backend/src/controllers/salonController.js:227-247`
**Acción:** comparar `invitation.email` con `req.user.email` y rechazar con mensaje explícito si no coincide (el caso "logueado con otro correo" del punto 2.3 **no está implementado**). Envolver el `INSERT` + `UPDATE usado` en una transacción (hoy no lo están: un fallo entre ambos deja la invitación reutilizable).
**Verificación:** aceptar con un usuario de correo distinto → **400**, y `salon_miembros` sin fila nueva.

**Gate 2:** invitación generada → aceptada desde un dispositivo limpio → el colaborador aparece en "Equipo" con su rol. Evidencia del flujo completo.

---

## FASE 3 — Quitar los datos fabricados

### T3.1 — Tablero del salón: fuera el salón inventado
**Modificar:** `frontend/lib/screens/salon_dashboard_screen.dart:80-93`
**Acción:** borrar el bloque `else if (mounted)` que asigna `'Salón Elegance Studio'`. Estado vacío o de error honesto, con botón de reintento.
**Verificación:** con el backend apagado, la pantalla **no** muestra NINGÚN nombre de negocio:
```bash
# detener el backend y abrir el tablero
grep -n "Salón Elegance\|901888777" frontend/lib/screens/salon_dashboard_screen.dart   # → 0
```

### T3.2 — KPI honesto
**Modificar:** `salon_dashboard_screen.dart:602-603`
**Acción:** filtrar `_bookings` por fecha de hoy, o renombrar la etiqueta a lo que realmente mide ("Citas activas"). No dejar `'Citas Hoy'` midiendo `_bookings.length`.

### T3.3 — Servicios contra el catálogo real
**Modificar:** `salon_dashboard_screen.dart:933-958`
**Acción (sujeta a T0.4):** borrar la lista de 4 servicios a mano y leer el catálogo real; lectura y edición con `GET /api/services/provider`, `POST /api/services`, `PUT/DELETE /api/services/:id` (`serviceRoutes.js:7-10`).
**Verificación:** los servicios mostrados coinciden con la base:
```bash
docker exec -i beauty-postgres psql -U admin -d beauty_db -c "SELECT id, nombre FROM services LIMIT 5;"
```

### T3.4 — Business Center real (según D4)
**Modificar:** `frontend/lib/screens/provider/business/business_dashboard_screen.dart:19-21`, `:69-75`, `:96-113`, `:126-130`
**Acción:** sustituir puntaje, etapa, tareas y hallazgos por `GET /api/business/summary` y `GET /api/business/tasks`; avanzar tareas con `POST /api/business/tasks/:id/advance` y evidencia con `POST /api/business/tasks/:id/evidence` (`businessRoutes.js:18-23`). El refresh (`:69-75`) llama a las fuentes reales o desaparece.
**Prerrequisito:** P1/T0.2 resuelto — si `business_tasks` no existe, la pantalla mostrará error y hay que decirlo, no taparlo.
**Verificación:** `curl -s localhost:8080/api/business/summary -H "Authorization: Bearer $TOKEN"` → datos reales; la pantalla los pinta.

**Gate 3:** con el backend caído, **ninguna** pantalla muestra datos de un negocio que no es del usuario. Evidencia: prueba con backend apagado.

---

## FASE 4 — Destino de las pantallas inalcanzables

**Depende de D5 y D6.** Por cada ruta: se engancha con evidencia de que el usuario llega desde la UI, o se elimina con su ruta.

| Ruta | Línea | Acción propuesta |
|---|---|---|
| `/accept-invitation` | `main.dart:241` | **Enganchar** en FASE 2 |
| `/terms` | `main.dart:277` | **Enganchar**: enlace en registro/login y en perfil |
| `/medical-validation` | `main.dart:291` | Eliminar (o enganchar si el flujo biométrico la alcanza) |
| `/colorimetria-historial` | `main.dart:294` | Eliminar junto con `/palette-card` (`colorimetria_historial_screen.dart:180`) |
| `/wardrobe` | `main.dart:295` | Eliminar junto con `/outfit-result` (`wardrobe_dashboard_screen.dart:152`) |
| `/glowup-card` | `main.dart:292` | Eliminar |
| `/provider-route` | `main.dart:261` | Eliminar |

**Archivos a borrar (0 referencias):**
- `frontend/lib/screens/home/home_screen.dart` (`onPressed: () {}` en `:78`, `:211`, `:255`)
- `frontend/lib/widgets/floating_navigation_dock.dart`
- `frontend/lib/screens/provider/provider_dashboard.dart` (citas de "Carlos Mendoza", botón muerto en `:264`)
- `frontend/lib/screens/store/product_list.dart` **+** `product_detail.dart` (el par; botón muerto en `product_detail.dart:63`)

**Gate 4:**
```bash
flutter analyze                                   # limpio, 0 errores
node frontend/scripts/verifyFlutterBaseline.js    # 587 / 0 / 0
# cada ruta de main.dart debe tener al menos 1 navegación en lib/ (o no existir)
```
Cero rutas declaradas sin navegación; cero archivos de pantalla sin referencia.

---

## FASE 5 — Cierre

Reporte único por punto, en el formato pedido:
`archivo:línea` antes → después · comando de verificación · resultado observado · estado (CERRADO / ABIERTO con motivo).
Al final: lista honesta de "no funcional restante" y lista de rutas/archivos eliminados.

---

## 3. Gates de regresión transversales (correr en cada fase)

```bash
cd backend
node scripts/verifyNoFabricatedPayments.js      # nuevo (T0.1) — exit 0 tras FASE 1
node scripts/verifyTestBaseline.js             # exit 0 y 0 fallos nuevos
node scripts/verifyTenantIsolation.js          # exit 0
node --check src/controllers/orderController.js
cd ../frontend
flutter analyze                                # sin errores de compilación
node scripts/verifyFlutterBaseline.js          # 587 / 0 / 0
```
**Prohibido `--update-baseline`.** Si un gate se pone rojo, es un issue nuevo real: se corrige.

---

## 4. Archivos que se van a tocar

**Backend:** `src/controllers/orderController.js` · `src/controllers/salonController.js` · `src/controllers/bookingController.js` *(solo si D1=pasarela)* · `scripts/verifyNoFabricatedPayments.js` *(nuevo)* · `.env.example` · migración nueva solo si T0.2 la exige.
**Flutter:** `screens/store_screen.dart` · `widgets/wompi_payment_sheet.dart` · `screens/client_bookings_screen.dart` · `screens/salon_dashboard_screen.dart` · `screens/provider/business/business_dashboard_screen.dart` · `screens/auth/accept_invitation_screen.dart` · `main.dart`.
**Borrados:** los 4 archivos/pares listados en FASE 4.

**No se toca:** panel del prestador (`provider_dashboard_screen.dart`), mapa y catálogo del cliente, agenda, chat, reserva con OTP, disputas, PQRSF, biometría/IA, `Wompi` payouts (`wompiService.js`), esquema de tablas existentes. `.env` (nunca se imprime ni se commitea).

---

## 5. Riesgos y trade-offs

1. **Cambiar `estado` de `PAGADO` a `PENDIENTE_PAGO`** puede romper pantallas que asumen pedido pagado (`/store/orders`). *Mitigación:* revisar los consumidores de `pedidos_tienda` antes de T1.1 (`paymentRoutes.js:326` ya lo consulta).
2. **Si D1 = pasarela real**, el plan crece y toca el corazón de pagos: requiere secreto de integridad, montos en centavos y pruebas contra el sandbox de Wompi. Por eso se separa.
3. **T3.4 contra una tabla inexistente** (P1) puede convertir un dato falso en un error visible. Eso es una mejora, pero hay que avisarlo antes, no después.
4. **Borrar `floating_navigation_dock.dart`** elimina el navbar "de 5 botones por rol". No es la navegación real (0 refs), pero es un artefacto visual que quizá quieras revisar antes de que desaparezca: conviene mirarlo una vez en pantalla.
5. **El build web obsoleto** (`backend/public/main.dart.js`) sirve la app en `https://…railway.app`. Si D3 = página web, hay que reconstruir; si no, queda como artefacto viejo y **debería documentarse**.
6. **Sin commits**: todo el trabajo queda en el working tree. Si algo sale mal, el rollback es `git checkout -- <archivo>` por archivo (no hay punto de restauración).

---

## 6. Preguntas abiertas

1. **D1–D6** (§1) — sin D1 y D2 no arranca FASE 1; sin D3 no arranca FASE 2; sin D4 no arranca T3.4; sin D5/D6 no arranca FASE 4.
2. ¿El catálogo de servicios del salón debe ser **por salón** o por prestador? Hoy no hay vínculo probado (P3). Si es por salón, es un cambio de esquema y sale de esta iteración.
3. ¿Se arreglan las 4 migraciones rotas (`031`, `034`, `037`, `062`) en esta iteración o aparte? T3.4 depende de `062`.
4. ¿El flujo de pago de citas (el simulador de `bookingController.js:435-558`) entra en este plan o se documenta como deuda? Hoy la respuesta del prompt es "Severidad 5 — no tocar", pero **no es cierto que funcione**.
