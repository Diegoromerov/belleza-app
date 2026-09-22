# PROMPT DE TRABAJO — Funcionalidad no real de GlowApp (inventario verificado)

> Uso: pegar tal cual en el agente. Nada de este inventario es especulativo: cada punto tiene archivo:línea.
> Regla base: **no crear mocks nuevos, no maquillar pantallas**. Si algo no se puede hacer real en esta iteración, se retira de la UI y se documenta.

---

## 0. Contexto y regla de trabajo

Repo: monorepo Belleza App (Flutter `frontend/`, Node `backend/`, Next `admin-dashboard/`).
Alcance de esta iteración: **convertir en funcional lo que hoy es falso o inalcanzable**, en el orden de severidad de abajo. No es una iteración de diseño ni de refactor.

Reglas no negociables:
1. **Causa raíz, no parche.** Si algo se ve bien porque hay datos escritos a mano, el arreglo es quitar los datos a mano, no reemplazarlos por otros datos a mano.
2. **Verificación end-to-end obligatoria.** Cada punto se cierra con: comando ejecutado + resultado observado + evidencia archivo:línea del antes y el después. Sin esto, el punto queda ABIERTO.
3. **Nada de fabricar éxito:** prohibido `success: true` local, `Future.delayed` que sustituya una llamada real, o catch que devuelva datos de ejemplo. Si el backend no responde, la UI muestra error o vacío.
4. **No avanzar de fase sin gate.** Cada fase tiene su gate al final; hasta que no pase, la siguiente no se toca.
5. **No commit, no push.** Solo cambios en working tree + reporte.

---

## 1. Inventario de lo que NO es funcional (verificado)

### 🔴 Severidad 1 — Ruta del dinero (falso cobro)

**1.1 La tienda "cobra" sin cobrar.**
- `frontend/lib/screens/store_screen.dart:389-395` → al pagar llama `showWompiCheckoutSheet(bookingId: widget.bookingId ?? 'STORE_${DateTime.now().millisecondsSinceEpoch}', ...)`. Cuando la tienda se abre desde la barra inferior (GlowShop, sin `bookingId`), el id es `STORE_...`.
- `frontend/lib/widgets/wompi_payment_sheet.dart:116-124` → si el `bookingId` empieza con `STORE_`, **no llama a la pasarela**: espera 2 segundos y fabrica `{'success': true, 'status': 'APPROVED', 'reference': 'wompi_store_<millis>'}`.
- `frontend/lib/screens/store_screen.dart:404` → con ese `true` local, registra el pedido real en `POST /api/store/checkout` y muestra "pedido exitoso".
- Resultado para el usuario: compra aprobada, pedido creado, **cero dinero cobrado**. El backend nunca ve una transacción.

**1.2 La propina se "cobra" con un temporizador.**
- `frontend/lib/screens/client_bookings_screen.dart:197-245` → `_runWompiCheckout()` es una simulación explícita: muestra "Simulando pasarela Wompi...", espera 2.5 s y ejecuta `onSuccess()` sin ninguna llamada de pago.

**1.3 Nada en el backend impide un pedido pagado sin transacción.** (a verificar en `backend/` en cuanto se toque 1.1: el endpoint `/api/store/checkout` debe exigir referencia de pasarela válida y no confiar en el cliente).

### 🟠 Severidad 2 — Invitación de equipo inutilizable

- `frontend/lib/screens/salon_dashboard_screen.dart:308-320` → el dueño invita por correo y la app genera `invite_link` (se copia al portapapeles).
- `frontend/lib/screens/auth/accept_invitation_screen.dart` existe y la ruta `/accept-invitation` está declarada (`main.dart:242-246`), **pero ninguna parte de la app navega a ella**: es la única ocurrencia del literal en todo `lib/`.
- **No hay manejo de deep links en absoluto**: 0 referencias a `app_links`, `uni_links`, `getInitialLink` en `frontend/lib`.
- Resultado: el enlace de invitación no puede consumirse en la app. El colaborador invitado nunca aparece en la pestaña "Equipo".

### 🟠 Severidad 3 — Pantallas con datos fabricados

**3.1 Tablero del salón (el SaaS que se le vende al dueño).**
- `frontend/lib/screens/salon_dashboard_screen.dart:82-92` → si la respuesta del backend no trae `success: true`, inventa un salón: `nombre_salon: 'Salón Elegance Studio'`, `nit: '901888777-1'`, `plan_saas: 'FREE_TRIAL'`. El dueño ve **el negocio de otro**.
- `frontend/lib/screens/salon_dashboard_screen.dart:933-958` → la pestaña "Servicios" es una lista escrita a mano (Balayage $280.000, etc.): no lee ni escribe el catálogo real.
- `frontend/lib/screens/salon_dashboard_screen.dart:601-609` → el KPI "Citas Hoy" usa `_bookings.length` (todas las citas del prestador, sin filtrar por fecha) → etiqueta mentirosa.

**3.2 Business Center (cumplimiento legal).**
- `frontend/lib/screens/provider/business/business_dashboard_screen.dart:19-21` → `_complianceScore = 0.65`, `_businessName = 'Mi Peluquería Studio'`, etapa fija.
- `:96-113` tareas y `:126-130` hallazgos de auditoría escritos a mano.
- `:69-75` → "desliza para actualizar" solo espera 500 ms: el refresh **no refresca nada**.

### 🟡 Severidad 4 — Rutas y archivos muertos (UI real que el usuario no puede alcanzar)

Rutas declaradas en `frontend/lib/main.dart` sin ninguna navegación en todo `lib/`:

| Ruta | Definición | Estado |
|---|---|---|
| `/accept-invitation` | main.dart:242 | inalcanzable (ver 2) |
| `/terms` | main.dart:282 | inalcanzable — **los términos y condiciones no se pueden abrir** |
| `/medical-validation` | main.dart:296 | inalcanzable |
| `/colorimetria-historial` | main.dart:299 | inalcanzable (y de ahí cuelga `/palette-card`, `colorimetria_historial_screen.dart:180`) |
| `/wardrobe` | main.dart:300 | inalcanzable (y de ahí cuelga `/outfit-result`, `wardrobe_dashboard_screen.dart:152`) |
| `/glowup-card` | main.dart:297 | inalcanzable |
| `/provider-route` | main.dart:266 | inalcanzable |

Archivos completos sin ninguna referencia (código muerto con pantalla construida):
- `frontend/lib/screens/home/home_screen.dart` (0 referencias; trae su propio navbar y `onPressed: () {}` en :78, :211, :255)
- `frontend/lib/widgets/floating_navigation_dock.dart` (0 referencias; navbar de 5 botones por rol que **no es la navegación real**)
- `frontend/lib/screens/provider/provider_dashboard.dart` (nunca importado; contiene un segundo tablero hardcodeado — citas de "Carlos Mendoza" — y un botón sin acción en :264)
- `frontend/lib/screens/store/product_list.dart` + `frontend/lib/screens/store/product_detail.dart` (nunca importados por `store_screen.dart`, que usa sus propios widgets; botón sin acción en `product_detail.dart:63`)

### 🟢 Severidad 5 — Lo que sí funciona (no tocar)

Panel del prestador (`screens/provider_dashboard_screen.dart`, API real: bookings, status en línea, start/complete, SOS, wallet embebido), mapa y catálogo del cliente (`main.dart` `ProvidersScreen`), agenda de citas del cliente, chat, flujo de reserva con OTP, disputas, PQRSF, biometría/IA. Cualquier cambio aquí debe justificarse aparte.

---

## 2. Plan de ejecución por fases

### FASE 1 — Dinero (no se avanza sin cerrar esto)
**1.1** Eliminar la rama de pago fabricado del checkout de tienda (`wompi_payment_sheet.dart:116-124`). Todo pago pasa por la pasarela real, incluida la compra sin cita asociada.
**1.2** La propina: cobro real por pasarela o **se retira de la UI** hasta que exista.
**1.3** Endurecer `POST /api/store/checkout` en `backend/`: un pedido solo puede quedar pagado con referencia de transacción verificable; validación en servidor, no en el cliente.
**Gate 1:** con la pasarela simulada caída/errada, la compra NO se registra como pagada y el usuario ve el error. Evidencia: petición + respuesta + fila del pedido en BD.

### FASE 2 — Invitación de equipo de punta a punta
**2.1** Decidir el transporte (ver Decisiones) e implementar el consumo del enlace → pantalla `/accept-invitation` con token.
**2.2** Al aceptar: vincular al usuario al local con su sub-rol y reflejarlo en la pestaña "Equipo".
**2.3** Manejar los errores reales de UX: token vencido, token ya usado, usuario logueado con otro correo.
**Gate 2:** invitación generada → abierta desde un dispositivo limpio → colaborador aparece en "Equipo" del dueño, con su rol correcto. Evidencia: captura/registro del flujo completo.

### FASE 3 — Quitar los datos fabricados
**3.1** Tablero del salón: eliminar el fallback inventado → estado vacío/error honesto; "Servicios" conectado al catálogo real (leer y editar); KPI "Citas Hoy" filtrando por fecha o renombrado a lo que realmente mide.
**3.2** Business Center: sustituir puntaje, etapa, tareas y hallazgos por su fuente real, o marcarlo visiblemente como **demostración** si el backend aún no existe. El refresh debe refrescar o desaparecer.
**Gate 3:** con el backend caído, ninguna pantalla muestra datos de un negocio que no es el del usuario. Evidencia: prueba con backend apagado.

### FASE 4 — Decidir el destino de las pantallas inalcanzables
Por cada una de la tabla de severidad 4: **o se engancha a un flujo real (con evidencia de que el usuario llega desde la UI) o se elimina** junto con su ruta. Nada queda "definido pero invisible".
**Gate 4:** cero rutas declaradas sin navegación; cero archivos de pantalla sin referencia; `flutter analyze` limpio.

### FASE 5 — Cierre
Reporte único con: qué se hizo real, qué se retiró de la UI y por qué, qué sigue pendiente con su motivo, y la lista de rutas/archivos eliminados.

---

## 3. Decisiones que necesito antes de ejecutar
1. **Propina (1.2):** ¿se implementa el cobro real ahora o se retira de la UI en esta iteración?
2. **Invitación (2.1):** ¿el enlace apunta a la app (deep link, requiere `app_links` + configuración iOS/Android) o a una página web en `admin-dashboard` que abra la app? La primera es más trabajo de plataforma; la segunda es más rápida pero añade un paso.
3. **Business Center (3.2):** ¿existe o existirá API de cumplimiento, o se marca como demo ahora y se implementa después?
4. **Pantallas de severidad 4:** ¿hay alguna que quieras conservar y enganchar sí o sí (p. ej. `/terms`)? Marca la lista.

---

## 4. Formato del reporte de vuelta
Por cada punto: `archivo:línea` antes → después · comando de verificación usado · resultado observado · estado (CERRADO / ABIERTO con motivo). Y al final: lista de "no funcional restante" honesta, sin adornos.
