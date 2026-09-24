# PROMPT DE CORRECCIÓN PARA ANTIGRAVITY — Auditoría del plan de reparación de la Auditoría 360
**Regla vigente: sigue sin autorización para modificar código. Esta ronda se resuelve leyendo, midiendo y reescribiendo el plan.**

---

Hermes auditó tu "Plan de Reparación de Auditoría 360" contra el repositorio. El plan tiene el orden por olas bien pensado y varios diagnósticos exactos
(WebSocket, fail-closed biométrico, `safe_fallback`, `allowedRoles`), pero **no se puede ejecutar como está**: apunta a un árbol que no es el que se auditó,
propone cambios ya aplicados, y deja fuera dos de los tres peores críticos. Abajo está todo con evidencia. **No empieces a editar hasta cerrar la Sección 0.**

---

## SECCIÓN 0 — Bloqueos de proceso (resuélvelos ANTES de tocar una línea)

**BLOQUEANTE 1 — El plan apunta a un worktree sucio y divergente, no a `main`.**
Todas las URLs de archivo del plan son
`C:/Users/Compu casa/.gemini/antigravity/worktrees/beauty-app/setup_glowguide_architecture/…`
Ese worktree está en la rama **`baseline-v1-stable`**, HEAD **`77497a20` (2026-09-21)**, y `git rev-list --left-right --count origin/main...HEAD` da
**`11  3`**: le faltan 11 commits de `origin/main` (todo el módulo SaaS: *install RBAC middleware chain on business and service routes*,
*anti-tenant-leakage and anti-IDOR data scope isolation*, *team and membership management module with RBAC and OWNER guards*) y tiene 3 que `main` no tiene.
La auditoría se hizo sobre **`main` = `d018587d` (2026-09-22)**, no sobre ese árbol.
**Instrucción:** declara en una línea cuál es el trunk real, y si el plan se aplica sobre `baseline-v1-stable`, explica cómo llega a `main` y cómo se
reconcilian las 11 commits de SaaS/RBAC que ese árbol no tiene. Si la respuesta es "se mergea", eso **es** parte del plan, no un detalle de ejecución.

**BLOQUEANTE 2 — Hay 132 entradas sin commitear en ese worktree (98 archivos, +2.555 / −10.967 líneas).**
Ninguna ola del plan menciona ese trabajo en curso, y varias olas tocan **los mismos archivos** ya modificados ahí (`backend/index.js`, `backend/src/config/db.js`,
`backend/src/config/database.js`, `backend/src/middleware/tenantContext.js`, `admin-dashboard/src/app/(auth)/login/page.tsx`,
`admin-dashboard/src/app/(dashboard)/layout.tsx`, `.github/workflows/ci.yml`, `backend/migrations/058_enable_rls_policies.sql`).
**Instrucción:** antes de proponer nada, haz un **checkpoint**: lista qué está modificado, agrupa por hallazgo y commitea (o `stash` con nombre) eso.
Aplicar nuevas olas encima de 132 cambios sin checkpoint hace imposible atribuir una regresión a un cambio.

**BLOQUEANTE 3 — El plan propone como pendiente trabajo que YA está hecho en ese mismo árbol.**
La corrección 1 (Wave 1.1, C-01) pide excluir los `.down.sql` del filtro. En el árbol al que apunta el plan eso **ya está aplicado**:
`$W/backend/index.js:1645` → `.filter(file => file.endsWith('.sql') && !file.endsWith('.down.sql'))`.
Además ese worktree ya tiene, sin trackear, verificadores de **esta** auditoría:
`backend/scripts/verifyNoFabricatedPayments.js`, `verifyNoVersionedSecrets.js`, `verifyTenantIsolation.js`, `verifyTestBaseline.js`
(y `cleanTestFixtures.js`, `prepareRlsDatabase.js`, `setupRlsRole.sql`, `seedBusinessCatalog.js`).
**Instrucción:** reconcilia el plan con tu propio árbol archivo por archivo. Cada ítem debe decir: `ya aplicado (commit/archivo:línea) | en curso sin commitear | pendiente`.
Un plan que pide hacer lo hecho hace perder una ola completa.

**BLOQUEANTE 4 — Colisión de identificadores entre dos auditorías.**
Tu rama tiene commits con etiquetas `C1…C17` de **otra** auditoría:
`de647417 fix(security): close authentication backdoors (C1, C2, C3), quota bypasses (C7), and harden JWT secret handling (C17)`,
`77497a20 … harden Wompi webhooks (C4, C5), block unverified premium (C6), fix payouts (C8), balance disputes (C9), fix SQL migrations (C13, C14)…`
En esa numeración, **C13/C14 = migraciones SQL**; en la auditoría de Hermes, **C-13 = `safe_fallback` persistido** y **C-14 = login del admin**.
Cualquiera que lea "C-14 corregido" no puede saber cuál de los dos es.
**Instrucción:** renumera todo con el prefijo de la auditoría de origen — `A360-2026-09-22/C-01` para los hallazgos de Hermes y el prefijo que corresponda a los
tuyos — y usa ese mismo prefijo en los mensajes de commit y en los nombres de test.

**BLOQUEANTE 5 — El plan sale del alcance declarado por tu propio contrato.**
El `AGENTS.md` de ese worktree dice: *"Avoid: authentication; payments; backend; database; API contracts; financial/business logic … unless explicitly requested"*
y *"Never apply patches to the main branch automatically"*, con misión de diseño (ProviderDetailScreen, BookingScreen, design system, accesibilidad).
El plan toca autenticación (WS), claves de cifrado, guards de admin, runner de migraciones, SQL de backfill y pasarela de pagos.
**Instrucción:** no decidas tú si eso está autorizado. Pídeselo por escrito al director indicando exactamente qué queda fuera del contrato, y **no** empieces
por los ítems de pago/BD hasta que lo confirme.

---

## SECCIÓN 1 — Correcciones al plan, ítem por ítem

### Wave 1.1 (C-01) — el arreglo está en 1 de 6 lugares: corrige la clase, no el sitio
El filtro que ejecuta los rollbacks existe en **seis** archivos, no en uno:
`backend/index.js:1628`, `backend/check_and_migrate.js:58`, `backend/run_all_migrations.js:36`, `backend/run_migrations_ordered.js:36`,
`backend/run_migrations_until_ready.js:58`, `backend/src/config/migrationRunner.js:15` (más `knexfile.js:17`, que usa el runner de knex por su cuenta).
Cualquiera de los cinco que no arregles reproduce el `DROP COLUMN IF EXISTS embedding`.
**Y falta la parte que importa:** los rollbacks deben **salir del directorio escaneado** (p. ej. `migrations/rollback/`), porque el filtro es una defensa por
convención de nombre: el próximo archivo `*_algo.down.sql` o cualquier `.sql` auxiliar vuelve a entrar. Además: **sin tabla de control de migraciones**
(`grep -c schema_migrations backend/index.js` → 0; `knexfile.js` → 0) todo se re-ejecuta en cada arranque.
Instrucción: excluir `.down.sql` en los 6, mover los rollbacks fuera del directorio, y añadir `schema_migrations` (o adoptar knex como runner único:
hoy conviven 4 mecanismos). **Criterio de aceptación:** arrancar el backend dos veces y comprobar que el conteo de embeddings no cambia y que la salida del
runner no menciona ningún `.down.sql`.

### Wave 1.2 (C-02, C-06) — C-02 no son logs, y falta el peor de los logs
C-02 es **secretos versionados en git**. El plan solo borra dos `console.log` y no toca ninguno de los tres vectores:
1. `backend/.env.production` **trackeado** (11 valores no-placeholder, incluidos `JWT_SECRET` y `ENCRYPTION_KEY`) → `git rm --cached` + purga de historial.
2. `backend/scratch/{make_pg_dump,verify_after_deploy,verify_real_railway}.js` con la cadena de conexión de producción de Railway → mismo tratamiento.
3. `seed_glowapp_kb.js:2` → **el literal de la clave de NVIDIA**. Tu plan solo propone borrar el `console.log`, que **está en la línea 7**, no en la 13
   (la 13 es `console.log('🔍 Verificando entorno local...')`). El crítico es la clave commiteada, no solo su impresión.
4. **No hay rotación en el plan.** Es la única acción que reduce el daño ya materializado: rotar `JWT_SECRET`, `ENCRYPTION_KEY`, la password de Postgres,
   las 3 API keys y la clave de NVIDIA. Va con nombre de responsable y fecha, o no ocurre.
Y de C-06 falta **el peor**: `backend/src/controllers/authController.js:87` → `console.log("❌ VALIDACIÓN FALLIDA: … Email:", email, "Password:", password)`
imprime la **contraseña en claro** en cada registro fallido. Verificado hoy, sigue ahí y no está en ninguna ola.
**Criterio de aceptación:** `git ls-files | grep -E '(^|/)\.env($|\.)'` → solo `.env.example`; `grep -rn "Password:" backend/src` → 0;
`grep -rn "nvapi-" .` → 0 (fuera de la historia reescrita); y los 6 secretos rotados con fecha.

### Wave 1.3 (C-04) — falta el otro lado del cable: así como está, rompe Aura y el chat
Verificado en el cliente Flutter, y **no es simétrico**:
- `frontend/lib/screens/provider_dashboard_screen.dart:86-89` → `{'type': 'register', 'token': token}` (ya manda token; hay hasta un comentario "enviando el token").
- `frontend/lib/screens/chat_screen.dart:178-181` → `{'type': 'register', 'userId': _currentUserId}` (**solo userId, sin token**).
Exigir token en el servidor **sin tocar `chat_screen.dart` en el mismo commit** mata el chat de Aura y el chat del cliente. El plan no incluye **ningún** cambio
de cliente Flutter.
Además: `authMiddleware` corta en `if (req.user) return next()` (`src/middleware/auth.js:10`), y el WebSocket **no pasa por Express** — la verificación tiene que
ser explícita en el handshake/registro (token del handshake o del payload, verificado con `jsonwebtoken`), no "envolver con authMiddleware".
Falta también `booking_tracking_screen.dart`, que usa `providerId` con fallback `?? '2'` (línea 148) sobre datos del booking.
**Criterio de aceptación:** un test que abra la conexión y verifique (a) registro sin token → rechazado y desconectado; (b) registro con token ajeno → rechazado;
(c) `join_booking_room` de una cita que no es tuya → rechazado; (d) `location_update` ignora el `providerId` del payload y usa el del token. Y los tres clientes
Flutter actualizados en el mismo commit.

### Wave 1.4 (C-11) — falta el plan de re-cifrado: hay datos cifrados en producción con la clave vieja
El servicio ya lanza error si la clave falta o no mide 32 bytes (líneas 16/27/33) — eso está bien. Pero **hay datos cifrados con la clave derivada**:
`backend/src/services/biometric/profile.service.js:24-25` cifra `face_scores` y `hands_diagnosis` y `:123-124` los descifra; `glowCycleService.js:106,225` cifra
`encrypted_scores`; las columnas existen (`004_isolate_phi_schema.sql:11 face_mesh_encrypted`, `061_create_glow_cycle_engine.sql:35 encrypted_scores`).
Hoy esos registros se cifraron con `sha256(JWT_SECRET + 'glowapp_biometric_fallback_key_32_bytes!')`. Al cambiar el origen de la clave, **esos registros quedan
indescifrables** y `decrypt` falla en lectura.
**Instrucción:** añade (a) versionado de clave + script de re-cifrado con lectura por clave vieja y escritura por clave nueva, **o** la decisión explícita y
documentada de descartar esos datos, con su costo; (b) el **orden de despliegue**: provisionar el secreto → desplegar → re-cifrar. Un fail-closed desplegado antes
de que el secreto exista tumba el arranque.

### Wave 1.5 (C-14) — falta la mitad
Correcto el redirect por rol y `allowedRoles={['ADMIN']}`. Falta:
- `src/app/page.tsx:152-154` → `localStorage.getItem('adminToken') || process.env.NEXT_PUBLIC_ADMIN_TOKEN`: todo `NEXT_PUBLIC_*` se inlinea en el bundle público.
  Si esa variable existe en el build, el JWT de admin viaja en el JS. Hay que sacarlo del cliente (cookie httpOnly + Route Handler) y borrar la variable del build.
- `src/app/page.tsx:44-112` → GMV, comisión, SOS con nombres y teléfonos y KYC pendiente son **datos simulados**; si el fetch falla (`:174-179`) solo cambia el
  rótulo a "Modo Simulación" y **conserva las cifras**. Falta eliminarlos.
- `src/middleware.ts:4-23` calcula `publicPaths`/`isPublicPath` y **no los usa**: los tres caminos hacen `NextResponse.next()`. Sin guard server-side, ocultar el
  panel es cosmético.

### Wave 1.6 (roles y orch) — dos matices
- `req.user.rol`: exponer `role` y `rol` a la vez es un parche de compatibilidad. Decide **un** nombre canónico y migra los ~2 lectores
  (`biometricConsentRoutes.js:234`, `authController.js:810`). Ojo: al setear `rol`, el guard de consentimiento biométrico empieza a **pasar** (antes nunca pasaba):
  eso cambia comportamiento y necesita test propio, no un "por compatibilidad".
- `/api/ai/orchestrate`: envolverlo en `authMiddleware` **no** arregla el segundo problema — el guard anti-traversal es decorativo
  (`path.resolve(process.cwd(), '../../')` resuelve a la raíz del sistema, así que `startsWith(basePath)` no acota nada). Corrige ambos en el mismo ítem.

### Wave 2.7 (C-07) — está planteado como "o esto o aquello": hay que decidir
El plan deja el contrato sin cerrar ("implementar el endpoint … O adaptar la ruta"). Además su referencia de archivo no resolvió (el propio aviso de contexto:
`@file:'app.post("/api/v1/beauty-scan")`': file not found`) — no planifiques sobre un archivo que no pudiste leer.
Decide **un** contrato, escríbelo en el plan, y acompáñalo de un test que lo fije: si se adopta el multipart de 4 fotos, el worker **tiene** que calcular algo con
cabello y manos (hoy no devuelve ningún campo de ninguno de los dos, y esas fotos se piden al usuario con su consentimiento). Si no, se retira la funcionalidad.

### Wave 2.8 (C-08) — "sustituir por cálculos" no es un cambio, es un deseo
No defines de qué señal sale la hidratación ni el sebo, con qué modelo, ni qué pasa cuando no se puede medir. Y el crítico tiene **tres** frentes, no uno:
falta el mock de Flutter (`frontend/lib/services/biometric_service.dart:110-116` devuelve `getMockBiometricJson()` ante cualquier no-2xx o excepción y
`frontend/lib/screens/ideas/processing_screen.dart:88-98` **navega a Resultados con esos datos**, precedido de "✨ Generando diagnóstico de demostración…")
y falta `backend/src/controllers/designsController.js:1654-1672` (`simulateDoctorReview` escribe una **nota clínica aleatoria** a los 15 s en `validaciones_medicas`
y marca `estado='revisado'`).
**Instrucción:** define por escrito la fuente de cada métrica, o devuelve `null`/422 y muestra "no medible" en la UI. Los mocks solo tras un flag de demo tipado y
visible. `simulateDoctorReview` se elimina y el estado queda en `pendiente`.

### Wave 2.9 (C-12) — falta la invalidación
Correcto incluir identidad en la clave. Falta: (a) `setCache` también debe **almacenar** la identidad para poder rechazar el hit si el origen no coincide;
(b) las entradas ya cacheadas sin identidad hay que invalidarlas en el despliegue (si no, siguen siendo servibles); (c) las claves que hashea el `generateCacheKey`
actual son embeddings: **no** metas el `userId` dentro del vector hasheado sin cambiar también `findSimilarInCache`, o el caché deja de acertar nunca.

### Wave 2.10 (C-13) — correcto, con un añadido
Muy bien no persistir el fallback. Añade que la degradación sea **visible**: devolver un estado de indisponibilidad y registrar/alertar el fallo de los proveedores,
porque hoy un `safe_fallback` es indistinguible de una respuesta real.

### Wave 3.11 (C-05) — cubre 1 de los 4 simuladores, y el endpoint "real" no existe
Tu Ola 3 dice "conectar la confirmación de pago de la tienda al endpoint real del backend". Verificado: **ese endpoint no existe**. Los endpoints de
`backend/src/routes/paymentRoutes.js` son checkin / complete / confirm-otp / wallet / wallet-transactions / bank-account / withdraw / disputes / admin-*;
el cobro vive en el simulador de `bookingController.js:440-553` (marca `payment_status='paid'` con `wompi_sim_*` **sin guarda de `NODE_ENV`**).
Y `backend/src/services/wompiService.js` (120 líneas, leído completo) **también es simulador**: `disbursePayout` (línea 10) y `crearPayout` (línea 64) generan
`'wompi_ref_' + Math.random()` / `'wompi_ret_' + Math.random()` y escriben `status='paid'` en `transactions` y `estado='COMPLETADO'` en `retiros` **sin llamar a
ninguna API de Wompi** (0 URLs en el archivo). Es decir: el dinero de salida queda marcado como pagado sin salir.
Faltan además la propina simulada en Flutter (`client_bookings_screen.dart:228-243`, con el texto "Simulando pasarela Wompi" en pantalla) y los SOS/KYC simulados
del admin (`admin-dashboard/src/app/page.tsx:186-199`).
**Instrucción:** la Ola 3 pasa a ser **decisión de producto**, no deuda técnica: integrar Wompi (cobro **y** dispersión) o **retirar el cobro** del producto.
Mientras no se decida: guarda de entorno que devuelva `501 PAYMENT_GATEWAY_NOT_INTEGRATED` y elimine las ramas simuladas. No dejes "conectar con el endpoint real"
como tarea: no hay a qué conectar.

### Wave 4.12 (C-10) — el mecanismo elegido no reasigna nada
Editar `057_backfill_tenant_id.sql` **no cambia datos**: la migración ya se ejecutó en producción y `UPDATE … WHERE tenant_id IS NULL` no vuelve a encontrar filas.
Bien elegido `salones.id_dueno` (existe: `authController.js:127` lo usa). Pero hace falta **una migración nueva** de reasignación por dueño real, con
**antes/después medidos**: `SELECT tenant_id, count(*) FROM usuarios GROUP BY 1` y el equivalente por tabla, más la verificación de que ninguna fila queda en `demo`
por accidente. Y la regla de que esto **no** se ejecuta contra producción sin copia de seguridad previa.
Ojo con el efecto colateral: si la tenancy se resuelve por `salones.id_dueno` y otra parte del sistema resuelve por `business_profiles`/`memberships`
(**dos modelos que conviven**), la reasignación puede dejar la mitad de la app sin ver sus datos. Eso es decisión del director, no tuya.

---

## SECCIÓN 2 — Críticos AUSENTES del plan (entran sí o sí)

**A360-2026-09-22/C-03 — Fail-open a datos fabricados (`backend/src/config/db.js:428-497`).**
`let isPgAvailable = false;` (428) → `if (isPgAvailable === false) return handleMemoryQuery(text, params);` (443-445, sin log y sin reintentar la BD real);
en el `catch` de la query real, `isPgAvailable = false` (450-452); `testConnection()` (493-497) devuelve **`true`** al fallar; 24 ramas de datos inventados, con
`'Salón Demo'` en `db.js:422`. Una sola excepción SQL deja **todo el proceso** sirviendo fixtures en memoria, para siempre y en cualquier entorno.
Es el crítico que **invalida cualquier verificación**: si el backend no está hablando con la BD, tus pruebas pueden estar pasando contra datos fabricados.
Propuesta: fallback solo con `NODE_ENV === 'test'`/flag explícito; si no, propagar el error; `testConnection` → `false` y abortar el arranque; exponer el modo
degradado en `/health`.

**A360-2026-09-22/C-09 — RLS inerte (`058_enable_rls_policies.sql:30`, `auth.js:43-45`, `tenantContext.js`).**
`ENABLE` sin `FORCE` (conteo del archivo: ENABLE=1, FORCE=0, `WITH CHECK`=0): el dueño de las tablas — que es la app, porque las crea en el arranque
(`index.js:1636`) — **bypassa las políticas**. El contexto se fija con `set_config($1,$2,false)` (`is_local = false`) sobre el pool compartido y **nunca se
resetea**: la query siguiente puede caer en otra conexión (fuga cross-tenant) o en la config vieja. `tenantContext.js` crea un **segundo `Pool`** y
**no está montado en ninguna parte** (`grep -rn tenantContext src/ index.js`). Y `memberships`, `business_profiles`, `salones`, `salon_miembros`,
`salon_invitaciones`, `rag_chunks` no están en la lista de RLS.
Sin esto, la Ola 4 (backfill) y cualquier promesa de aislamiento multi-tenant son nominales. Propuesta: `FORCE ROW LEVEL SECURITY`, rol de app sin privilegios de
dueño, `SET LOCAL` dentro de la transacción que atiende la petición (o pool por tenant), `current_setting(…, true)` + `USING … WITH CHECK …`, y decidir el destino
de `tenantContext.js`.

---

## SECCIÓN 3 — Plan de verificación (reemplaza al propuesto)

El actual no es ejecutable: `verifyTestBaseline.js` y `verifyTenantIsolation.js` **no existen en `main`** (verificado:
`ls backend/scripts/verifyTestBaseline.js` → *No such file or directory*; el único `verify*` trackeado en `main` es `verifyRagSchema.js`). Viven, sin trackear, en tu
worktree. Un plan de verificación que cita scripts que no están en la rama que despliega no verifica nada.

1. **Baselines con número, antes del primer cambio.** `cd backend && npx jest` (patrón exacto de `ci.yml:36`) → hoy **5-6 suites / 37 tests rojos**; run completo →
   **13 suites / 57 tests**. `cd frontend && flutter analyze lib` → hoy **2 errores** (`undefined_method`) + **535 info**, **0 warnings**, exit ≠ 0. Guarda esas 4
   cifras como línea base; sin ellas "no hay regresiones" es incomprobable.
2. **Un test por corrección, que falle antes del fix.** Obligatorios: filtro de migraciones (arranque doble: el conteo de embeddings no cambia), WS (los 4 casos de
   Wave 1.3), aislamiento de caché (dos usuarios, misma consulta, respuestas distintas), `safe_fallback` no persistido, `payBooking` → 501 en producción,
   PII fuera de logs. Un fix sin test no está terminado.
3. **Mutación obligatoria en tenancy.** Fuerza la política a `USING (true)` y comprueba que el test de aislamiento **se pone rojo**. Si sigue verde, el test no
   prueba aislamiento.
4. **Verificación de datos, no solo de código.** Antes y después de C-01/C-09/C-10: `SELECT count(*), count(embedding) FROM beauty_knowledge_embeddings`,
   `SELECT relrowsecurity, relforcerowsecurity FROM pg_class WHERE relname = 'usuarios'`, `SELECT tenant_id, count(*) FROM usuarios GROUP BY 1`.
   Son las mediciones que prueban que el daño se detuvo.
5. **Nada de "verificado" sin salida de comando.** Cada ítem del plan cierra con el comando ejecutado y su salida textual, o queda marcado **NO VERIFICADO**.
   Y si algo se refuta, va primero y sin adornos.

---

## SECCIÓN 4 — Decisiones que NO puedes tomar tú (márcalas como bloqueantes en el plan)

El plan **decide en silencio** dos cosas que son del director: la Ola 3 asume que Wompi **se integra** (no lo dice, pero toda la ola depende de eso), y la Ola 4
asume que la tenancy se resuelve por `salones.id_dueno` (eligiendo ese modelo sobre `business_profiles`/`memberships`). Marca las dos como decisiones abiertas.
Lista completa de decisiones que el plan necesita del director antes de ejecutarse:

1. **Cobro:** ¿integrar Wompi de verdad (cobro y dispersión) o retirar el cobro del producto?
2. **Tenancy:** ¿`salones`/`salon_miembros` o `business_profiles`/`memberships`? ¿Se retira el modelo perdedor?
3. **Esquema:** ¿se toma `pg_dump --schema-only` de la BD real como fuente de verdad versionada (6 tablas en uso no tienen DDL en el repo)?
4. **beauty-scan:** ¿se implementa el contrato real (4 fotos → worker) o se retira la función hasta tener worker que la sostenga?
5. **Rotación de secretos:** quién y cuándo, sabiendo que implica re-cifrado de biometría.
6. **Historial de git:** ¿purga de secretos y `git rm --cached` del gradle wrapper (22.043 archivos / 532 MB) ahora, con force-push coordinado, o al final?
   Esto condiciona todas las ramas de trabajo, incluidas las tuyas.
7. **Rama/trunk:** cuál es la línea de verdad y cómo se reconcilia `baseline-v1-stable` (11 commits atrás) con `main`.
8. **Modo demo:** ¿se conserva algún entorno con datos simulados o se elimina por completo?

---

## SECCIÓN 5 — Formato de la respuesta

Devuelve, **sin escribir ni un archivo**:

1. **Reconciliación (Bloqueante 1-3):** trunk declarado, checkpoint del árbol (qué está modificado y a qué hallazgo pertenece), y tabla
   `ítem del plan → ya aplicado / en curso / pendiente` con `archivo:línea` o commit.
2. **Plan v2** en olas, con: identificador renumerado (`A360-2026-09-22/C-xx`), archivo:línea, **la clase completa** del bug (todos los sitios, no uno),
   criterio de aceptación medible, test nuevo que falla antes del fix, y **decisiones abiertas marcadas como bloqueantes**.
3. **Los dos críticos ausentes (C-03, C-09) integrados**, con su ubicación en la secuencia y por qué van antes de lo que ya tenías.
4. **Lo que descartes de este prompt, con tu evidencia.** Si algo de lo que digo aquí es incorrecto, demuéstralo con el comando y su salida — vale tanto como un
   "de acuerdo", y prefiero un refutación bien medida a una aceptación sumisa.

**Recuerda: sigue sin autorización para modificar código.** Esta respuesta es un plan, no una ejecución.
