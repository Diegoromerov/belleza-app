> Estado: **PENDIENTE DE CONFIRMACIÓN**. No se ha creado ningún commit.
> Preparado: 2026-10-16 · Rama: `main` · Base: `13b45332a`

# Plan de commits — bloque acumulado en el árbol de trabajo

## Por qué existe este documento

El árbol tenía **137 archivos modificados, 51 sin trackear y 1 borrado** acumulados de varias
sesiones, con tres agentes trabajando sobre el mismo repo local. Antes de este plan, el árbol era
**imposible de revisar**: 5 439 inserciones contra 5 440 borrados en 8 archivos de frontend.

Eso no eran cambios. Era **CRLF**.

## Lo que ya se hizo (paso 0, ejecutado y verificado)

### Normalización de fin de línea — 52 archivos

Medición antes/después por archivo:

| Archivo | "Cambios" aparentes | Cambios reales |
|---|---|---|
| `frontend/lib/core/theme/tokens.dart` | 1 769 + 1 769 | **3 + 3** |
| `frontend/lib/design/icons/glow_icon.dart` | 1 586 + 1 587 | **0 + 1** |
| `frontend/lib/core/theme/app_theme.dart` | 1 252 + 1 252 | **62 + 62** |
| `frontend/lib/screens/auth/login_screen.dart` | 1 175 | **3** |
| `frontend/lib/screens/designs/evolution_dashboard_screen.dart` | 1 150 | **2** |

Total del árbol: de ~16 278+/14 965- (solo frontend) a **5 513+/1 876-**.

**Método y verificación:** por cada archivo se midió su diff real con `git diff --ignore-all-space`
antes y `git diff --numstat` después; los valores deben coincidir. 49 de 52 coincidieron exactamente.

**Las 3 excepciones — y qué revelaron:**

- `frontend/lib/core/theme/belleza_luxe_theme.dart` y `provider_detail_screen.dart`: la versión
  **commiteada** de estos dos archivos ya era CRLF. Convertirlos a LF *creaba* un diff de 188 y 4 783
  líneas respectivamente. Se les **restauró CRLF** para no inflar el commit; quedan en 2+2 y 18+11.
- `frontend/lib/screens/profile/glowstore_orders_screen.dart`: HEAD es LF, así que la conversión es
  correcta (258+62). La discrepancia (308 → 320) es porque `--ignore-all-space` **también oculta
  cambios de solo indentación**; esa métrica es una aproximación, no una igualdad.

⚠️ **El repo tiene fin de línea mixto.** No hay `.gitattributes` que lo cubra para `.dart`/`.ts`:
solo `backend/data/corpus/*.json`, `*.sh`, `*.cron` y `backend/openapi/*.json` fuerzan `eol=lf`.
**Decisión pendiente D-1** (abajo).

---

## Exclusiones — NO se commitean

| Elemento | Motivo |
|---|---|
| `belleza-app.zip` (53 MB) | Artefacto local |
| `belleza2.zip` (1.4 MB) | Artefacto local |
| `belleza-app2/` (15 MB) | **Repo git anidado accidental**: contiene solo un `.git`, nada de código |
| `frontend/lib/services/api_service.dart.partial` | Copia parcial, no es fuente |
| `frontend/android/app/google-services.json` | **Rompe CI. Probado, no teorizado** ↓ |

### La exclusión de `google-services.json` está verificada

`backend/scripts/verifyNoVersionedSecrets.js` es un paso **bloqueante** del CI y tiene la regla
`clave tipo Google API` (`AIza[A-Za-z0-9_-]{30,}`). El archivo tiene una clave `AIza…` en la línea 18.

Comprobación real (staging temporal, después des-stageado):

```
$ git add frontend/android/app/google-services.json
$ node backend/scripts/verifyNoVersionedSecrets.js
❌ 1 credencial(es) en archivos TRACKEADOS (no se imprime ningún valor):
   frontend/android/app/google-services.json:18 — clave tipo Google API

$ git reset frontend/android/app/google-services.json
$ node backend/scripts/verifyNoVersionedSecrets.js
✅ Sin credenciales versionadas en archivos trackeados.
```

**El escáner usa `git grep`, que solo ve archivos trackeados/staged.** Por eso el árbol actual da
verde y aun así el archivo reventaría el pipeline **después** del commit. No basta con que la
compuerta esté verde hoy: hay que excluirlo a mano.

`frontend/lib/firebase_options.dart` **sí** se puede versionar: usa placeholders `YOUR_…`, que la
propia compuerta exenta vía `ALLOW_MARKERS`.

---

## Estructura propuesta de commits

Orden pensado para que cada commit deje el repo coherente. Mensajes en el estilo del historial
(`fix(ci):`, `feat(checkout):`, `docs(revisar):`).

### C1 — `chore(repo): ignorar artefactos y repo anidado; normalizar fin de línea`

Primero, porque sin esto los commits siguientes son irrevisables.

```
.gitignore                                        (añadir zip, *.partial, belleza-app2/, google-services.json, failures/)
frontend/android/app/google-services.json         (NO — solo .gitignore)
```

Los 52 archivos ya normalizados **entran solos** en este commit (van como cambios de EOL, o quedan
sin diff si su único cambio era eso). Recomendado: `git add -A` de los archivos normalizados cuyo
diff real se haya anulado... **ver decisión D-2**.

### C2 — `feat(fiscal): responsabilidad de IVA del prestador y facturación DIAN`

Backend y modelo de datos:
```
backend/src/utils/iva.js                             (nuevo)
backend/src/services/ivaPrestador.js                 (nuevo)
backend/src/services/dianClient.js                   (nuevo)
backend/src/services/dianInvoiceClient.js            (nuevo)
backend/migrations/086_add_iva_configuration.sql     (nuevo)
backend/migrations/086_add_iva_configuration.down.sql
backend/migrations/087_add_provider_rut_responsibility.sql (nuevo)
backend/migrations/087_add_provider_rut_responsibility.down.sql
backend/migrations/091_add_dian_invoice_fields.sql   (nuevo)
backend/src/models/User.js
backend/src/models/Booking.js
backend/src/routes/providerRoutes.js
backend/src/routes/adminRoutes.js
backend/src/controllers/authController.js
backend/.env.example                                 (vars DIAN)
.hermes/compliance/iva-colombia.md                   (nuevo)
.hermes/plans/2026-10-10_captura-responsabilidad-iva-onboarding.md (nuevo)
```
Tests: `iva.test.js`, `ivaModeloBooking.test.js`, `ivaPrestador.test.js`, `providerFiscalIva.test.js`,
`adminProviderFiscal.test.js`, `dianInvoiceClient.test.js`.

Frontend asociado: `frontend/lib/widgets/provider/fiscal_iva_section.dart` (nuevo).

> ⚠️ `frontend/lib/screens/provider/business/*`, `screens/profile/settings_screen.dart` y
> `user_profile.dart` **pueden** pertenecer aquí (captura de responsabilidad IVA en onboarding) o a
> su propio commit. Requiere mirar el diff antes de decidir — ver **D-3**.

### C3 — `feat(pagos): cobro y dispersión con Wompi`

```
backend/src/services/wompiClient.js                  (nuevo)
backend/src/services/wompiPayoutsClient.js           (nuevo)
backend/src/services/wompiService.js
backend/migrations/085_add_titular_identity_to_provider_wallet.sql (nuevo)
backend/migrations/085_add_titular_identity_to_provider_wallet.down.sql
backend/src/routes/paymentRoutes.js
backend/src/jobs/paymentJobs.js
backend/src/controllers/bookingController.js         (payBooking)
backend/src/tests/wompiWebhookSecurity.test.js
backend/scripts/verifyWompiCredentials.js            (nuevo)
backend/scripts/sandboxWompiE2E.js                   (nuevo)
.hermes/plans/2026-10-09_143000-wompi-full-integration.md (nuevo)
```
Tests: `payBooking.test.js`, `wompiClient.test.js`, `wompiPayoutsClient.test.js`,
`wompiAcceptanceTokenEndpoint.test.js`, `backend/tests/payment.money.cents.test.js`.

Frontend: `frontend/lib/widgets/wompi_payment_sheet.dart`, `frontend/lib/services/api_service.dart`.

> Este commit cierra **W10** (métodos de redirección PSE/Bancolombia/Daviplata). Se deja constancia
> en el mensaje de que quedan dos decisiones abiertas (ver D-4).

### C4 — `feat(glowstore): pedidos con dirección estructurada, envíos y cotización por zonas`

```
backend/src/controllers/orderController.js
backend/src/services/shippingService.js              (nuevo)
backend/src/routes/productRoutes.js
backend/migrations/090_add_metadata_to_pedidos_tienda.sql (nuevo)
backend/migrations/092_add_envios_and_estado_timestamps.sql (nuevo)
backend/migrations/093_add_structured_address_to_pedidos.sql (nuevo)
backend/migrations/094_create_zonas_envio.sql        (nuevo)
backend/src/sockets/serviceLocationHandler.js        (nuevo)
backend/src/sockets/trackingHandler.js               (BORRADO)
```
Frontend: `screens/store_screen.dart`, `screens/profile/glowstore_orders_screen.dart`,
`widgets/store/product_card.dart`, `widgets/store_product_card.dart`,
`widgets/product_quick_view_dialog.dart`,
`widgets/profile/colombian_address_builder.dart`, `widgets/profile/delivery_addresses_section.dart`.

Admin: `admin-dashboard/src/app/(dashboard)/admin/store/**` (nuevo), `Sidebar.tsx`.

> ⚠️ Las 4 migraciones 092-094 se **renumeraron** en esta sesión (eran 011/012/013 y colisionaban con
> números legacy). Y se **borró** `091_envios_tracking_pedidos.sql`: duplicaba el número 091 y creaba
> `envios` con un esquema (`numero_guia`/`estado_envio`) que ningún código usa — habría hecho fallar
> el runner. Mencionarlo en el cuerpo del commit.

### C5 — `test(harness): arreglar suites que medían el entorno en vez del código`

```
backend/src/config/pgMemory.js
backend/src/tests/jwtProductionGuard.test.js
backend/src/tests/pgMemorySchema.test.js
backend/test/payment.money.cents.test.js   → (ruta real: backend/tests/payment.money.cents.test.js)
backend/src/tests/audit360-remediation.test.js
```
Cierra **W11**. Suite completa: **160/160 suites, 1246 passed, 5 skipped, 1251 total**.

### C6 — `feat(push): notificaciones FCM`

```
frontend/lib/services/fcm_service.dart               (nuevo)
frontend/lib/services/notification_service.dart
frontend/lib/firebase_options.dart                   (nuevo; placeholders, seguro)
frontend/android/app/build.gradle.kts
frontend/android/build.gradle.kts
frontend/android/app/src/main/AndroidManifest.xml
frontend/android/app/src/main/res/values/colors.xml  (nuevo)
frontend/ios/Runner/Info.plist
frontend/ios/Runner/GoogleService-Info.plist.template (nuevo)
frontend/macos/Flutter/GeneratedPluginRegistrant.swift
frontend/windows/flutter/generated_plugin_registrant.cc
frontend/windows/flutter/generated_plugins.cmake
frontend/pubspec.yaml, frontend/pubspec.lock
```

### C7 — `style(frontend): rediseño del sistema de diseño`

```
frontend/lib/core/theme/app_theme.dart
frontend/lib/core/theme/belleza_luxe_theme.dart
frontend/lib/core/theme/tokens.dart
frontend/lib/design/components/academy_luxe_components.dart
frontend/lib/design/components/s4_loading.dart
frontend/lib/design/components/s4_text_field.dart
frontend/lib/design/icons/glow_icon.dart
frontend/lib/design/icons/glow_icon_demo.dart
frontend/lib/shared/glow_store_tokens.dart
frontend/lib/l10n/**  (5 archivos)
frontend/lib/main.dart
frontend/lib/widgets/aura_3d_emblem.dart
frontend/lib/widgets/profile/luxe_list_tile.dart
frontend/lib/widgets/voice_input.dart
```

### C8 — `feat(frontend): pantallas (academia, VTO, glowguide, perfil)`

El bloque más voluminoso y el que **menos certeza tiene mi agrupación** (70 archivos repartidos en
9 subdirectorios). Ver **D-3**: conviene partirlo en 2-4 commits por feature (`academy`,
`ideas/VTO`, `glowguide`, `perfil`) tras leer los diffs.

```
frontend/lib/screens/academy/**            (9)
frontend/lib/screens/ideas/**              (9, incl. widgets/*_painter.dart)
frontend/lib/glowguide/**                  (3)
frontend/lib/screens/profile/**            (5)
frontend/lib/screens/auth/**               (3)
frontend/lib/screens/salon/salon_hub_screen.dart
frontend/lib/screens/provider*/**.dart
frontend/lib/screens/booking_screen.dart
frontend/lib/screens/designs/evolution_dashboard_screen.dart
frontend/lib/screens/support/terms_conditions_screen.dart
frontend/lib/services/{auth_service,social_share_service}.dart
frontend/lib/shared/onboarding_helper.dart
frontend/lib/widgets/provider/provider_schedule_dialog.dart
frontend/lib/widgets/profile/{delivery_addresses_section,colombian_address_builder}.dart
```

### C9 — `test(frontend): baseline de goldens y tests de pantalla`

```
frontend/test/golden/phase5_goldens_test.dart
frontend/test/golden/after/*.png                     (5 modificados + 2 nuevos)
frontend/test/screens/booking_screen_test.dart       (nuevo)
frontend/test/screens/booking_screen_overflow_test.dart
frontend/test/aura_welcome_screen_test.dart
```
Ver **D-4** sobre `frontend/test/golden/failures/**` (20 PNG **ya trackeados** y modificados):
son artefactos generados por corrida. Recomiendo `git rm --cached` + `.gitignore` en vez de
seguirlos versionando.

### C10 — `chore(deps): dependencias y contrato`

```
backend/package.json, backend/package-lock.json
backend/openapi/openapi.json
backend/src/openapi/criticalContract.js
admin-dashboard/package.json, admin-dashboard/package-lock.json
admin-dashboard/src/app/api/[...path]/route.ts
admin-dashboard/src/components/dashboard/Sidebar.tsx
```

### C11 — `docs(revisar): cerrar W10 y W11 con evidencia`

```
.hermes/REVISAR.md
```

---

## Decisiones que necesito de ti antes de ejecutar

**D-1 — ¿Se añade un guard de fin de línea a `.gitattributes`?**
El repo tiene EOL mixto y algo (un editor, otro agente) reescribió 52 archivos en CRLF, lo que produjo
16 278 líneas de ruido. Opciones: (a) añadir `* text=auto eol=lf` y normalizar todo de una vez
—un commit grande, único—; (b) cubrir solo `*.dart`/`*.ts`/`*.tsx`; (c) no hacer nada y volver a
limpiarlo a mano la próxima vez. **Recomiendo (a)**, pero es una decisión de política del repo.

**D-2 — ¿El commit C1 incluye los 52 archivos normalizados, aunque su único cambio sea EOL?**
Tras la normalización, la mayoría de esos archivos **siguen teniendo cambios reales**, así que van en
su commit temático (C2-C8) ya sin el ruido. Solo hay que confirmar si quieres un commit C1 aparte con
los que quedaron en diff cero.

**D-3 — El frontend: ¿C8 partido por feature o en bloque?**
Mi agrupación de `frontend/lib` (70 archivos) es **por directorio, no por lectura del diff**. Para
partirlo bien hay que leer los diffs de `screens/academy`, `screens/ideas`, `glowguide` y
`screens/profile`. Dime si quieres ese trabajo o si prefieres revisarlos tú.

**D-4 — W10 deja dos decisiones abiertas** (registradas en `REVISAR.md`): `url_launcher` para abrir la
URL de pago, y la ruta real que reciba el retorno de Wompi en `https://glowapp.co/pago/resultado`.
¿Se commitea tal cual y se decide después, o prefieres resolverlas antes de C3?

---

## Cómo se ejecutaría (y cómo se verifica)

Cada commit se haría con `git add <rutas explícitas>` (nunca `git add -A`, para que las exclusiones
no se cuelen) y `git commit -F <archivo>` — **nunca `-m`**, porque en este MSYS las comillas
invertidas del shell rompen el mensaje.

Compuertas a correr antes del primer commit y después del último:

```bash
cd backend
node scripts/checkNoConflictMarkers.js      # bloqueante
node scripts/verifyNoVersionedSecrets.js    # bloqueante  ← vigilar google-services.json
node ../backend/tests/migrationsNoDuplicateNumbers.test.js
JWT_SECRET=t npx jest --runInBand --forceExit   # 160/160, ~267 s
npm run openapi:check
cd ../frontend && flutter analyze lib       # 0 errores
```
