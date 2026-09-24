# PROMPT DE CORRECCIÓN v2 — Plan de Reparación A360-2026-09-22
**Regla vigente: sin autorización para modificar código. Esta ronda se resuelve midiendo y reescribiendo el plan.**

---

## Lo que aceptaste bien (no lo toques)

Renumeración con prefijo `A360-2026-09-22/*`, los 6 runners identificados, rollbacks fuera del directorio escaneado, `schema_migrations`,
checkpoint previo, trunk declarado (`origin/main` = `d018587d`), solicitud formal de excepción al `AGENTS.md` (Bloqueante 5), y la prueba
de doble arranque. También es correcto que `semanticCache` usa Redis (`getRedisClient()` en `semanticCache.js:8`) — eso lo verificamos y está bien dicho.

Y hay trabajo real en tu árbol que el plan no se atribuye: `backend/migrations/068_force_rls_strict_isolation.sql` (untracked) es una buena
solución al hallazgo de RLS — `NULLIF(current_setting('app.tenant_id', true), '')`, una sola política `FOR ALL` con **USING y WITH CHECK**, y
`FORCE ROW LEVEL SECURITY` (línea 183) con la motivación documentada. El problema es que no está commiteada ni mapeada al hallazgo, no que esté mal hecha.

---

## SECCIÓN 1 — Errores que invalidan el plan como está

### 1.1 **[BLOQUEANTE NUEVO] Tu rama tiene una regresión producida por el propio fix de C-04**
Verificado en tu worktree:
- Servidor: `websocketService.js:82` → si no hay `data.token`, responde `{ error: 'Se requiere token JWT de autenticación' }`; y `:87-88` →
  `if (!ws.authenticatedUserId) return ws.send({ error: 'Debes registrarte con un token antes de unirte a una sala' })`.
- Cliente, **en el mismo worktree**: `frontend/lib/screens/chat_screen.dart:178-181` →
  `jsonEncode({'type': 'register', 'userId': _currentUserId})` — **sin token**.
Conclusión (por lectura de las dos rutas, no por ejecución): tras tu fix, el registro del chat falla, `authenticatedUserId` queda sin setear y el
`join_booking_room` se rechaza → **el chat de Aura y el chat del cliente no unen a la sala**. El fix de servidor es correcto; está a medias.
`booking_tracking_screen.dart` no registra nada (no manda `register` ni token): revísalo en el mismo pase.
**Instrucción:** C-04 no está "YA APLICADO". Marca el estado real y añade al plan el cambio de cliente (`token` en el payload, o token en el handshake)
en el **mismo commit** que el servidor, y los 4 tests de aceptación (registro sin token → rechazado; token ajeno → rechazado; join de una cita ajena →
rechazado; `location_update` ignora el `providerId` del payload y usa el del token).

### 1.2 **Las tres filas "YA APLICADO" son falsas para el trunk**
`main` = `d018587d` sigue con los tres agujeros. Verificado hoy:
- `C-11`: `backend/src/services/biometricCryptoService.js:9-14` → en producción/`RAILWAY_ENVIRONMENT`/sin `NODE_ENV` **sigue derivando** la clave de
  `JWT_SECRET` con un `console.warn`. (Tu worktree sí lo tiene fail-closed; `main` no.)
- `C-04`: `backend/src/services/websocketService.js:80-84` → **sigue** `else if (data.userId) { registerClient(data.userId, ws); … warning: 'No token verification' }`.
- `C-14`: `admin-dashboard/src/app/(auth)/login/page.tsx:24-28` **sigue** redirigiendo por `email === 'admin@glow.app'`, y
  `src/app/(dashboard)/layout.tsx:7` **sigue** con `<ProtectedRoute>` sin `allowedRoles`.
Etiquetar "YA APLICADO" cuando el fix vive sin commitear en un worktree 11 commits por detrás del trunk **oculta que la rama que se despliega sigue
vulnerable**. El estado correcto es `aplicado en worktree, sin commitear, no en main`, y eso implica que el merge a `main` es parte del plan, no un trámite.
**Instrucción:** vuelve a medir cada fila **contra `main`** (`git show main:<archivo>`) y no contra tu árbol de trabajo. Añade una columna `Rama verificada`.

### 1.3 **Segunda referencia a un endpoint que no existe**
Ola 3, ítem 9: "conectar la confirmación del widget a la API real del backend (`/api/payments/wompi/transaction`), procesando la firma HMAC".
Ese endpoint **no existe**. Lo único que hay es `POST /api/payments/wompi-webhook` (`backend/src/routes/bookingRoutes.js:27`, montado en
`backend/index.js:375`), que es un **receptor** de webhooks, no un creador de transacciones. Y `backend/src/services/wompiService.js` (120 líneas,
leído completo) no contiene **ninguna** llamada a la API de Wompi: es simulador puro.
Es el mismo defecto que la referencia `@file:'app.post("/api/v1/beauty-scan")'` de la Ola 2, que el propio contexto te vuelve a marcar como
`file not found`. **Dos olas apuntando a artefactos inexistentes.**
**Instrucción:** antes de escribir un endpoint en el plan, compruébalo con `grep -rn "<ruta>" backend/src backend/index.js`. Si no existe, la ola
no es "conectar": es **decidir si se construye**.

### 1.4 **C-05 sigue recortado a un cuarto del problema**
La tabla de reconciliación define C-05 como "Eliminación simulación `STORE_` Flutter". El hallazgo son **cuatro** simuladores, y el más grave es de backend:
- `backend/src/controllers/bookingController.js:440-553`: `payBooking` marca `payment_status='paid'` con `wompi_sim_*` **sin guarda de `NODE_ENV`**.
- `backend/src/services/wompiService.js:10` (`disbursePayout`) y `:64` (`crearPayout`): generan `'wompi_ref_' + Math.random()` / `'wompi_ret_' + Math.random()`
  y escriben `status='paid'` en `transactions` y `estado='COMPLETADO'` en `retiros` **sin llamar a ninguna API**. Esto es dinero que sale del sistema
  marcado como pagado. No aparece en ninguna ola.
- `frontend/lib/screens/client_bookings_screen.dart:228-243`: propina simulada con el texto "Simulando pasarela Wompi" en pantalla.
- `admin-dashboard/src/app/page.tsx:186-199`: SOS y aprobación de KYC simulados.
Y **falta la decisión**: mientras no se decida integrar o retirar el cobro, la instrucción correcta es un guard de entorno que devuelva
`501 PAYMENT_GATEWAY_NOT_INTEGRATED` y **elimine las ramas simuladas**, no "conectar" a algo inexistente.

### 1.5 **C-03 y C-09 siguen fuera del plan (tercera vez), y hay trabajo tuyo sin mapear**
Tu lista de identificadores tiene 12 entradas; la auditoría tiene 14 críticos. Faltan:
- **`A360-2026-09-22/C-03`** — `backend/src/config/db.js:428-497`: `isPgAvailable` arranca en `false`, un error deja el proceso sirviendo
  `handleMemoryQuery` **para siempre** (24 ramas de datos inventados, `'Salón Demo'` en `:422`/`496`), y `testConnection()` devuelve `true` al fallar.
  Sin esto, **cualquier verificación puede estar corriendo contra datos fabricados** — es el crítico que invalida a los demás. En tu worktree hay trabajo
  en curso (`db.js:503+` "Módulo aislado a propósito…"), sin commitear y sin crédito en el plan.
- **`A360-2026-09-22/C-09`** — tu `068_force_rls_strict_isolation.sql` **lo resuelve en la parte de RLS** (FORCE + `missing_ok` + WITH CHECK), pero está
  **untracked** y el plan no lo menciona; y falta el resto del hallazgo: `backend/src/middleware/auth.js:43-45` fija el contexto con
  `set_config($1,$2,false)` (`is_local = false`) sobre el pool compartido **sin reset ni transacción**, y `tenantContext.js` crea un **segundo `Pool`**
  que **no está montado en ninguna parte**.
**Instrucción:** intégralos con su identificador, su estado real (incluido lo que ya hay en 068) y su posición en la secuencia. C-03 va **antes** de
cualquier verificación funcional, por la razón del párrafo anterior.

### 1.6 **El fix de C-12 es la variante equivocada (segunda vez)**
Anteponer `${tenant_id}:${user_id}:` a la **clave** no aísla nada, porque el hit se decide por similitud vectorial sobre un índice **global**:
`semanticCache.js:75` → `redis.lRange(indexKey, 0, 99)` (últimos 100 de todos), y `:78` recupera cada entrada y compara cosenos. Las entradas de otros
usuarios siguen en la lista y siguen compitiendo; con similitud ≥ 0.92 devuelves, otra vez, la respuesta de otro.
**Instrucción:** filtra el **conjunto de candidatos** por identidad — índice separado por usuario/tenant (`semantic:index:<tenant>:<user>`), o guarda la
identidad en la entrada y descarta las que no coincidan antes de comparar. Aprovecha para arreglar el otro problema del mismo diseño: un anillo global de
100 entradas se desaloja entre usuarios, así que el caché es a la vez **fugable e inefectivo**, y en un despliegue sin Redis configurado
(`getRedisClient()` devuelve `null` → `if (!redis) return null`) es directamente **no-op** — confirma en qué entorno está activo antes de llamarlo "aislado".

### 1.7 **Ola 1 y Ola 4 se contradicen entre sí**
Añadir `schema_migrations` significa ejecutar-una-sola-vez. Pero Ola 4 propone **reescribir `057_backfill_tenant_id.sql`**, que **ya se ejecutó** en
producción: quedará registrado como aplicado y **nunca se volverá a ejecutar**. La reescritura es inerte en producción: no reasigna nada.
**Instrucción:** el backfill va en una **migración nueva** (p. ej. `069_reassign_tenant_id_by_owner.sql`), con conteos antes y después
(`SELECT tenant_id, count(*) FROM usuarios GROUP BY 1`) y regla explícita de **no ejecutarla contra producción sin copia de seguridad previa**.
`salones.id_dueno` es la columna correcta (lo usan `authController.js:127` y otros), eso está bien elegido.

### 1.8 **C-06: tercera omisión del peor log, y la línea que citas no es la que es**
Sigue sin aparecer `backend/src/controllers/authController.js:87` →
`console.log("❌ VALIDACIÓN FALLIDA: Faltan campos. Email:", email, "Password:", password)` — **la contraseña en claro**, el peor de los tres.
Y describes la línea a borrar como `const NVIDIA_KEY = "nvapi-…"`, pero la línea 2 real es `process.env.NVIDIA_API_KEY = 'nvapi-…'`; el `console.log`
de la clave está en la **línea 7** (la 13 es `'🔍 Verificando entorno local...'`). Abre el archivo antes de escribir el ítem.
Añade además la **rotación con responsable y fecha**: es lo único que reduce el daño ya materializado, y sigue sin estar en el plan.

### 1.9 **C-11: falta el re-cifrado y el orden de despliegue (segunda vez)**
Hay datos cifrados con la clave vieja: `backend/src/services/biometric/profile.service.js:24-25` cifra `face_scores` y `hands_diagnosis` (y `:123-124` los
descifra), `glowCycleService.js:106,225` cifra `encrypted_scores`; las columnas son `004_isolate_phi_schema.sql:11` y `061_create_glow_cycle_engine.sql:35`.
Al pasar a fail-closed sin versionado de clave, **esos registros quedan indescifrables** y la lectura falla.
**Instrucción:** plan de re-cifrado con la clave vieja para leer y la nueva para escribir (o decisión explícita y documentada de descartarlos), y **orden**:
provisionar el secreto → desplegar → re-cifrar. Un fail-closed desplegado antes de que exista el secreto tumba el arranque.
Ojo también con un efecto colateral de tu cambio: la constante de desarrollo pasó de `'glowapp_biometric_fallback_key_32_bytes!'` a
`'dev_test_biometric_fallback_key_32_bytes!'`, así que **cualquier dato cifrado antes en local/dev deja de descifrarse**.

### 1.10 **C-14: sigue faltando la mitad**
Correcto el rol y `allowedRoles`. Faltan: `src/app/page.tsx:152-154` (`NEXT_PUBLIC_ADMIN_TOKEN` se inlinea en el bundle público → el JWT de admin viaja
en el JS), `src/app/page.tsx:44-112` (GMV, comisión, SOS con teléfonos y KYC son **datos simulados**, y si el fetch falla `:174-179` solo cambia el rótulo y
conserva las cifras) y `src/middleware.ts:4-23` (calcula `publicPaths`/`isPublicPath` y **no los usa**; sin guard server-side, ocultar el panel es cosmético).

### 1.11 **C-07 y C-08 siguen sin decisión**
- **C-07:** "implementar el endpoint **o** adaptar la pasarela" no es un plan, es una duda; y la referencia de archivo sigue rota. Decide **un** contrato y
  fíjalo con un test contra el `openapi.json` del worker.
- **C-08:** "algoritmos de extracción cuantitativa sobre los canales de color" no define **ninguna** métrica. Escribe de qué señal sale la hidratación y el
  sebo, o devuelve `null`/422 con "no medible" en la UI. Y siguen fuera los otros dos frentes del hallazgo: los mocks de Flutter
  (`biometric_service.dart:110-116` y `processing_screen.dart:88-98`, que **navega a Resultados con datos de demostración**) y `simulateDoctorReview`
  (`designsController.js:1654-1672`), que firma una nota clínica falsa como dermatólogo.

### 1.12 **El checkpoint puede meter secretos NUEVOS en el historial, justo antes de purgarlo**
De las 132 entradas que propones commitear, dos son nuevas y contienen credenciales:
`backend/scripts/prepareRlsDatabase.js` (**5** coincidencias de `password`/`postgresql://`/`rlwy.net`/`secret`; contiene una cadena
`postgresql://admin…`) y `backend/scripts/setupRlsRole.sql` (**1**). Ninguna está trackeada hoy.
Si el checkpoint las commitea, la purga de historial pasa a tener que cubrir también esas, y el daño crece.
**Instrucción:** el checkpoint va **precedido** por un escaneo de secretos (`gitleaks detect --no-git` o `grep -rniE "password|postgresql://|rlwy\.net|nvapi-|sk-"`),
y las rutas de los verificadores toman la cadena de conexión de `process.env`, nunca literal.
Detalle que delata la mezcla de árboles: marcas `[DELETE] backend/.env.production`, pero en **tu** worktree ese archivo **no está trackeado**
(`git ls-files | grep -E '\.env'` → solo `backend/.env.example`): el `.env.production` entró a `main` en un commit posterior al del worktree.
Bórralo/desindexa **sobre `main`**, no en tu rama.

### 1.13 **La verificación sigue sin baseline y con un paso peligroso**
1. No hay **`npx jest`**: el repo tiene **37 tests rojos** con el patrón exacto de `ci.yml:36` (run completo: 13 suites / 57 tests). Sin esa línea base, "sin regresiones" es incomprobable.
2. No hay **`flutter analyze`** como baseline: hoy da **2 errores** (`undefined_method`) + 535 `info`, exit ≠ 0. Como criterio sin número, no mide nada.
3. **No hay ni un test nuevo** en ninguna ola: ni para el filtro de migraciones, ni para el WS, ni para el caché, ni para pagos. Un fix sin test que falle antes no está terminado.
4. Falta la **mutación** en tenancy: forzar la política a `USING (true)` y comprobar que el test se pone rojo.
5. `node backend/index.js` dos veces **arranca el entry real → ejecuta el runner contra el `DATABASE_URL` configurado**. Con 68 migraciones y un backfill
   reescrito, eso puede **escribir en una base real**. Hazlo contra una BD **efímera** (contenedor pgvector) y dilo explícitamente; y usa
   `SELECT count(*), count(embedding) FROM beauty_knowledge_embeddings` antes/después como medición.

---

## SECCIÓN 2 — Las 8 decisiones siguen sin estar sobre la mesa

Solo pides la excepción de alcance (bien). Pero el plan **decide en silencio** dos cosas que no son tuyas —Ola 3 asume que Wompi **se integra**, y Ola 4
asume que la tenancy se resuelve por `salones.id_dueno`— y no menciona ninguna de estas:

1. Cobro: ¿integrar Wompi (cobro **y** dispersión) o retirar el cobro?
2. Tenancy: ¿`salones`/`salon_miembros` o `business_profiles`/`memberships`? ¿Se retira el modelo perdedor?
3. Esquema: ¿`pg_dump --schema-only` de la BD real como fuente de verdad (6 tablas en uso no tienen DDL en el repo)?
4. `beauty-scan`: ¿contrato real de 4 fotos o se retira la función?
5. Rotación de secretos: ¿quién y cuándo, sabiendo que implica re-cifrar biometría?
6. Purga de historial y `git rm --cached` del gradle wrapper (22.043 archivos / 532 MB): ¿ahora o al final?
7. Rama/trunk: (**resuelto por ti**, `origin/main`) — falta cómo se reconcilian los 3 commits y las 132 entradas con los 11 de SaaS/RBAC.
8. Modo demo: ¿se conserva algún entorno con datos simulados o se elimina?

---

## SECCIÓN 3 — Formato de la respuesta

1. **Tabla de estados corregida por rama:** cada uno de los 14 críticos con `archivo:línea` **en `main`** y en tu worktree, y estado
   `aplicado en main / aplicado solo en worktree sin commitear / en curso / pendiente`. Sin eso, no sé qué falta de verdad.
2. **Plan v3** con los 14 identificadores, C-03 y C-09 incluidos y mapeados a lo que ya existe (`068`, el módulo de `db.js:503+`), C-05 completo (los 4 simuladores
   + los payouts), C-04 con su cambio de cliente, C-11 con re-cifrado y orden de despliegue, C-10 como migración nueva, y las 8 decisiones marcadas.
3. **Verificación** con las 5 correcciones de 1.13 y las salidas de comando como prueba de cierre.
4. **Lo que refutes de este prompt, con su comando y su salida.** Si algo de aquí es incorrecto, demuéstralo: vale igual que un "de acuerdo".

**Sin autorización para modificar código. Esta respuesta es un plan.**
