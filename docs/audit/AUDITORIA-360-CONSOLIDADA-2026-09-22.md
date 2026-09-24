# AUDITORÍA 360 — Belleza App / GlowApp (INFORME CONSOLIDADO)
**Fecha:** 2026-09-22 · **Modo:** solo lectura (cero modificaciones al código) · **Árbol auditado:** `C:/beauty-app`
**HEAD:** `d018587d` (main) · **Cobertura:** backend Node/Express · admin-dashboard Next.js · frontend Flutter · ai_worker FastAPI · capa SaaS multi-tenant · esquema/DDL · tests · CI/CD · dependencias · higiene del repo
**Anexos:** este informe condensa; el detalle extendido del backend está en `AUDITORIA-360-2026-09-22.md` (mismo directorio) y los informes crudos por subsistema en `raw/`.

### Marcas de evidencia
| Marca | Significado |
|---|---|
| **[V]** | Verificado por mí en esta sesión: comando ejecutado o línea leída directamente. |
| **[S]** | Reportado por un subagente con evidencia citada; **no** re-ejecutado por mí. Hipótesis fuerte, no hecho. |
| **[R]** | **Refutado o corregido** por mi verificación (incluidas dos afirmaciones de subagentes y un falso positivo propio). |

**Advertencia de topología:** el `cwd` de esta sesión (`C:\Users\Compu casa\belleza-app`) es un clon **congelado en 2026-08-04**, 1297 commits atrás. Auditar ahí habría descrito código inexistente. Todo se verificó sobre `C:/beauty-app`.

**Advertencia de árbol en movimiento:** el working tree está sucio y **otro agente (Antigravity) trabaja en paralelo sobre el mismo checkout**. Los conteos de análisis estático pueden variar entre corridas por esa razón; los que cito son los que medí yo, con su comando.

**Regla respetada:** ningún archivo del repositorio fue modificado, creado ni borrado.

---

## 1. Resumen ejecutivo

| Subsistema | Críticos | Altos | Medios | Bajos | Total |
|---|---|---|---|---|---|
| Backend / seguridad / tenancy | 9 | 18 | 15 | 5 | 47 |
| Frontend Flutter | 4 | 10 | 10 | 3 | 27 |
| Admin-dashboard | 4 | 6 | 8 | 9 | 27 |
| IA / RAG / ai_worker | 7 | 13 | 9 | 5 | 34 |
| Repo / CI / dependencias | 3 | 10 | 13 | 8 | 34 |
| **Total** | **27** | **57** | **55** | **30** | **169** |

*(Los subtotales incluyen hallazgos que aparecen en dos subsistemas desde ángulos distintos — p. ej. el simulador de pago es un sitio en el backend y otro en Flutter.)*

### Los 7 que bloquean cualquier afirmación de "listo para producción"
1. **C-01** La migración de rollback se ejecuta **antes** del up en cada arranque y hace `DROP COLUMN embedding` → los embeddings del RAG se destruyen en cada reinicio. **[V]**
2. **C-02** Secretos de producción versionados en git por tres vías independientes (`backend/.env.production`, credenciales de la BD de Railway en 3 scripts trackeados, clave de NVIDIA inline). **[V]**
3. **C-03** Un error transitorio de BD deja el proceso sirviendo **datos fabricados** de forma permanente y silenciosa (`db.js`). **[V]**
4. **C-04** WebSocket sin autenticación: suplantación de cualquier usuario, GPS de cualquier reserva y escritura de la ubicación de cualquier prestador. **[V]**
5. **C-05** El cobro es un **simulador** en cuatro sitios distintos (backend y Flutter): citas, tienda, propina y consola de administración. **[V]** en 3 de 4.
6. **C-07** `/api/v1/beauty-scan` llama a una ruta que **no existe** en `ai_worker` → el escaneo biométrico (funcionalidad central) devuelve 500 en producción. **[V]**
7. **C-08** El "diagnóstico de piel" son **constantes hardcodeadas** en el worker y un mock de respaldo en Flutter, indistinguibles de un resultado real. **[V]** en el worker.

---

## 2. CRÍTICOS

### C-01 — La migración de rollback se ejecuta antes del `up` en CADA arranque y borra la columna de embeddings **[V]**
- **Archivos:** `backend/migrations/035_fix_embedding_dimension_and_hnsw_index.down.sql`, `backend/index.js:1627-1630`, `backend/src/config/migrationRunner.js:15`, `backend/knexfile.js:17`
- **Cadena verificada:**
  1. El archivo `035_….down.sql` existe y **termina en `.sql`**; el filtro del runner es `.filter(file => file.endsWith('.sql')).sort()` (`index.js:1627-1629`, idéntico en `migrationRunner.js:15`).
  2. Orden alfabético real: `ls -1 backend/migrations/ | grep ^035` devuelve **primero** `…index.down.sql` y después `…index.sql` (`'d' < 's'`).
  3. Contenido leído del rollback: `DROP INDEX idx_beauty_knowledge_embedding_hnsw` / `_ivfflat` (23-24), 6 `DROP INDEX` de metadatos (27-32) y, línea **55**, `ALTER TABLE beauty_knowledge_embeddings DROP COLUMN IF EXISTS embedding;` (más `DROP COLUMN` de `skin_type`, `season_station`, `age_range`, `ingredients`, `contraindications`).
  4. Su propio encabezado lo declara: *"ADVERTENCIA: Esta migración DESTRUYE los embeddings de 1024 dimensiones. Los embeddings de 1024d se perderán y deberán regenerarse con NV-Embed-QA."*
  5. El `up` (`035_…sql:78`) hace `ADD COLUMN embedding vector(1024)` → recrea la columna **vacía**.
- **Impacto:** en cada reinicio del backend, cada deploy y cada corrida del runner: se dropean los índices vectoriales, se eliminan las columnas de metadatos y **se borran todos los embeddings del corpus**. La búsqueda semántica de Aura queda sin datos hasta que alguien re-ingeste, y el esquema queda en un estado que depende del momento del reinicio. Es la causa raíz más probable de las degradaciones "inexplicables" del RAG y de las métricas de evaluación en cero.
- **Corrección:** mover los rollbacks fuera del directorio escaneado (`migrations/rollback/`) o renombrarlos a una extensión no capturada; endurecer el filtro a `.filter(f => f.endsWith('.sql') && !f.endsWith('.down.sql'))` en los **tres** runners; tabla `schema_migrations` para no re-ejecutar en cada boot; y **medir antes**: `SELECT count(*), count(embedding) FROM beauty_knowledge_embeddings`.

### C-02 — Secretos de producción versionados en git por tres vías **[V]**
- **a) `backend/.env.production` trackeado.** `git ls-files | grep -iE '(^|/)\.env'` → `.env.example` **y `.env.production`**. 11 asignaciones no vacías, longitudes y clasificación no-placeholder: `JWT_SECRET` (33), `ENCRYPTION_KEY` (60), `DATABASE_URL` (56), `REDIS_URL`, `GEMINI_API_KEY`, `YOCAM_API_KEY`, `OPENUV_API_KEY`. El `.gitignore` lista `.env`/`.env.*` (`!.env.example`), pero **ignorar no destrackea**: `git check-ignore -v --no-index` lo marca como coincidente con la regla *y* está en el índice → entró con `git add -f` o antes de la regla (commit `1cc662fd`). Los valores **difieren** de `backend/.env` local (comparé md5 de cada uno) → son credenciales de otro entorno, presumiblemente producción.
- **b) Credenciales de la BD de producción en scripts trackeados.** `backend/scratch/make_pg_dump.js:5`, `verify_after_deploy.js:3`, `verify_real_railway.js:5` contienen la cadena de conexión literal de Railway (`caboose.proxy.rlwy.net:18931`) y los tres están TRACKEADOS (aunque `.gitignore:11` ignora `scratch/`). El segmento de contraseña no son asteriscos. Se suman `backend/scripts/r6c10…:44`, `r6c11…:67`, `docker-compose.prod.yml:32` (POSTGRES_PASSWORD literal) y varios `.md` de gobernanza **[S]**.
- **c) Clave de NVIDIA en un archivo trackeado, y además impresa.** `seed_glowapp_kb.js:2` → `process.env.NVIDIA_API_KEY = 'nvapi-…'` (TRACKEADO, commit `1c1f57f5`). **Agravante que verifiqué:** `seed_glowapp_kb.js:7` → `console.log("CLAVE REAL LEIDA:", process.env.NVIDIA_API_KEY)`.
- **Impacto:** con `JWT_SECRET` se forja un token de cualquier usuario, incluido `ADMIN`; con `ENCRYPTION_KEY` se descifra el cifrado de datos biométricos; con la conexión de Railway se lee/escribe la BD productiva; con la clave de NVIDIA se factura a la cuenta del proyecto. Rotar no borra el historial.
- **Corrección:** rotar **ya** los 7+1 secretos; `git rm --cached`; purgar con `git filter-repo`/BFG y force-push coordinado; valores en secrets del orquestador; `gitleaks`/`trufflehog` bloqueante en CI; quitar el `console.log` de la clave.

### C-03 — Fail-open a datos fabricados: un error de BD degrada el proceso para siempre **[V]**
- **Archivo:** `backend/src/config/db.js:428-497`
- **Evidencia:** `let isPgAvailable = false;` (428, arranca en falso) → `if (isPgAvailable === false) return handleMemoryQuery(text, params);` (443-445, **sin log y sin reintentar la BD real**) → en el `catch` de la query real: `isPgAvailable = false; return handleMemoryQuery(...)` (450-452). `testConnection()` (493-497) pone el flag en falso y **`return true`**. `handleMemoryQuery` tiene 24 ramas con filas inventadas; el caso canónico en `db.js:422`: `return { rows: [{ id: 1, nombre_salon: 'Salón Demo' }] }`. Sin guarda de `NODE_ENV` en ese camino.
- **Impacto:** una sola excepción SQL (migración rota, tabla inexistente, desajuste de dimensión de pgvector) deja **todas** las peticiones del proceso sirviéndose de fixtures en memoria, en cualquier entorno, con un único `console.warn` inicial. El camino de recuperación es inalcanzable mientras el flag esté en falso → el proceso queda así hasta reiniciar. Respuestas 200 con datos ficticios que la app y el usuario tratan como reales.
- **Corrección:** fallback solo con `NODE_ENV === 'test'` o `USE_PG_MEM === 'true'`; si no, propagar el error; `testConnection` devuelve `false` y aborta el arranque; backoff en vez de corto-circuito; exponer el modo degradado en `/health`.

### C-04 — WebSocket sin autenticación: suplantación, GPS ajeno y escritura de ubicación **[V]**
- **Archivo:** `backend/src/services/websocketService.js:60-107`
- **Evidencia:** `61` `new WebSocketServer({ server })` sin `verifyClient` ni token en el handshake; `80-84` `else if (data.userId) { registerClient(data.userId, ws); … }` → **registro como cualquier usuario enviando solo su id**; `87-93` `join_booking_room` acepta cualquier `bookingId` sin comprobar pertenencia; `95-107` `location_update` ejecuta `UPDATE perfiles_prestador SET ubicacion = ST_MakePoint(…) WHERE id = $3` con el `providerId` **que envía el cliente**.
- **Impacto:** suplantación (recibir mensajes/notificaciones de otro usuario), fuga de geolocalización en tiempo real de cualquier reserva y alteración de la ubicación de cualquier prestador (integridad + vector de acoso). Todo sin credenciales.
- **Corrección:** token obligatorio en `register` (eliminar la rama de `userId` plano); validar pertenencia antes de `join_booking_room`; derivar `providerId` del token verificado.

### C-05 — El cobro es un simulador en cuatro sitios distintos **[V]** ×3, **[S]** ×1
| Sitio | Evidencia | Efecto |
|---|---|---|
| Backend, pago de cita | `bookingController.js:462` `setTimeout 1500` → `:464` `'wompi_sim_' + Math.random()` → `:468-470` `estado='CONFIRMADA'`, `payment_status='paid'` → `:546` `[WOMPI SIMULATOR SUCCESS]` → `:550` `'…por el simulador de Wompi'`. **Sin ninguna verificación de `NODE_ENV`** | Cualquier cliente marca su cita como pagada sin pagar; `Transaction` con `status='paid'` y referencia inventada **[V]** |
| Flutter, tienda | `wompi_payment_sheet.dart:117-127`: `if (widget.bookingId.startsWith('STORE_'))` → `Future.delayed(2s)` → `{'success': true, 'status':'APPROVED', 'reference':'wompi_store_<epoch>'}` **sin llamada HTTP**. `store_screen.dart:391` genera ese prefijo siempre que no hay cita | Compra "aprobada" + `logPurchaseSuccess`; el pedido **sí** se persiste después (`POST /store/checkout` existe: `productRoutes.js:38`) → pedido real sin dinero **[V]** |
| Flutter, propina | `client_bookings_screen.dart:228-243`: texto en pantalla *"Simulando pasarela Wompi…"* → `Future.delayed(2500)` → `onSuccess()`. Ninguna llamada a `ApiService` en el método | El cliente cree haber pagado la propina; se ejecuta el callback de éxito **[V]** |
| Admin-dashboard | `admin-dashboard/src/app/page.tsx:186-199`: `handleApproveProvider`/`handleResolveSOS` solo filtran el array local y lanzan `alert()`; el fetch fallido conserva las cifras mock (174-179) | La dirección cree atender SOS y aprobar KYC que no se persisten **[S]** |
- **Agravante [V]:** `backend/package.json` → `"migrate": "node -e \"require('./src/models').sequelize.sync({force:true})\""`; `force:true` hace **DROP TABLE**: un comando llamado "migrate" destruye la base si apunta a producción.
- **Corrección:** en producción devolver `501 PAYMENT_GATEWAY_NOT_INTEGRATED` (comprobación de entorno, no un comentario), integrar la pasarela o retirar el cobro; borrar la rama `STORE_`; crear la orden en `PENDING_PAYMENT` **antes** de abrir la pasarela; renombrar `migrate` con aborto si `NODE_ENV === 'production'`. **Decisión de negocio pendiente:** ¿se integra Wompi o se retira el cobro?

### C-06 — Credenciales de usuario y claves de API en los logs **[V]**
- `backend/src/controllers/authController.js:87` → `console.log("❌ VALIDACIÓN FALLIDA: Faltan campos. Email:", email, "Password:", password);` → **email y contraseña en claro** en cada registro fallido.
- `seed_glowapp_kb.js:7` → imprime la clave de NVIDIA. · `backend/src/routes/paymentRoutes.js:157` → imprime el OTP de cierre de servicio.
- **Impacto:** cualquiera con acceso a los logs del contenedor obtiene credenciales de usuario y claves de facturación.
- **Corrección:** eliminar las tres líneas; test que falle si un `console.*` interpola `password`/`token`/`otp`/claves.

### C-07 — `/api/v1/beauty-scan` apunta a una ruta que no existe: el escaneo biométrico está muerto **[V]**
- **Evidencia:** `grep -rn "@app\." ai_worker/main.py` → **solo dos rutas**: `@app.post("/api/v1/analyze-skin")` (36) y `@app.post("/v1/ai/consult")` (44). `backend/src/routes/v1/beautyScanRoutes.js:12` `AI_WORKER_URL || 'http://ai-worker:8000'` y `:46` `axios.post(\`${AI_WORKER_URL}/api/v1/beauty-scan\`, formData, …)`. Ese router **sí** está montado en el entry real (`index.js:395`).
- **Impacto:** 404 upstream en cada escaneo → `catch` (`:71`) → HTTP 500. La funcionalidad central y el diferenciador del producto no funcionan, y el error no distingue "servicio caído" de "ruta equivocada".
- **Agravante de contrato [S]:** el emisor envía `multipart/form-data` con 4 archivos (`face_frontal`, `face_lateral`, `hair`, `hand`) mientras el handler espera JSON `{image_base64}` (`ai_worker/models.py:4-5`) y **no devuelve ningún campo de cabello ni de mano**. Aunque se corrija la URL, FastAPI respondería 422 y 3 de las 4 fotos exigidas al usuario (con su consentimiento) no se usarían.
- **Corrección:** unificar el contrato con test contra el `openapi.json` del worker; health check en el arranque que compare rutas invocadas vs expuestas.

### C-08 — Diagnóstico biométrico inventado: constantes en el worker y mock de respaldo en la app **[V]** ×2, **[S]** ×2
- `ai_worker/services/color_analysis.py:40-47` **[V]**: el `return` del camino feliz incluye `'hidratacion': 85.5` y `'sebo': 40.2` **como literales**, idénticos para toda imagen; solo estación/subtono dependen de `warmth_ratio` (2 estados). **[V]** `:48-56`: el `except` "Fallback seguro de contingencia en caso de imagen corrupta" devuelve **el mismo diagnóstico completo** (`94.0 / 85.5 / 40.2`) en vez de un error; `main.py:36-42` lo envuelve en `response_model=BiometricResult` con **HTTP 200**.
- `frontend/lib/services/biometric_service.dart:110-116` **[S]**: ante cualquier no-2xx o excepción devuelve `getMockBiometricJson()` (`profileId: 'glow_mock_profile_2026'`, glowScore 84, bioAge 26, tratamientos concretos).
- `frontend/lib/screens/ideas/processing_screen.dart:88-98` **[S]**: en el `catch` navega a `ResultsScreen` con ese mock, precedido de *"✨ Generando diagnóstico de demostración…"*.
- `backend/src/controllers/designsController.js:1654-1672` **[V]**: `simulateDoctorReview` escribe a los 15 s una **nota clínica aleatoria** (3 literales) en `validaciones_medicas` y marca `estado='revisado'`, con `[SIMULATOR SUCCESS] … revisada por el dermatólogo`.
- **Impacto:** el usuario recibe puntajes de piel, edad biológica, tratamientos y validaciones profesionales que nunca se calcularon, persistidos como mediciones. Riesgo de salud, consumeril y regulatorio.
- **Corrección:** distinguir "no medible" de valor (`null`/HTTP 422); mocks solo tras flag de demo tipado `isMock: true` visible en UI; eliminar `simulateDoctorReview` dejando el estado en `pendiente`.

### C-09 — RLS inerte: `ENABLE` sin `FORCE`, contexto en una conexión arbitraria, middleware no montado **[V]**
- **Evidencia:** `058_enable_rls_policies.sql:30` `ALTER TABLE %s ENABLE ROW LEVEL SECURITY` → conteos del archivo: **ENABLE = 1, FORCE = 0, WITH CHECK = 0**; la única política (61-63) es `FOR ALL USING (tenant_id = current_setting('app.tenant_id')::int)` sin `missing_ok`. `auth.js:43-45` → `await pool.query('SELECT set_config($1,$2,false)', …)` con `is_local = false`, sobre el pool compartido, **sin reset** y sin garantizar que la query siguiente use esa conexión (el comentario de `auth.js:41-42` lo admite). `tenantContext.js:3` crea un **segundo `new Pool()`** y su `set_config(…, true)` fuera de transacción se descarta; `grep -rn tenantContext src/ index.js` → **no está montado en ninguna parte**. `memberships`, `business_profiles`, `salones`, `salon_miembros`, `salon_invitaciones`, `rag_chunks` no están en la lista de RLS.
- **Impacto:** (a) la app es dueña de las tablas que crea en el arranque (`index.js:1636`) y **el dueño bypassa RLS sin `FORCE`** → las políticas no se aplican; (b) el contexto viaja en conexiones arbitrarias y persiste entre peticiones: fuga cross-tenant o error `unrecognized configuration parameter "app.tenant_id"` (500 intermitente). El aislamiento es nominal.
- **Corrección:** `FORCE ROW LEVEL SECURITY`; rol sin privilegios de dueño; transacción por petición con `SET LOCAL` **en la misma conexión** que atiende (o pool por tenant); `current_setting(…, true)` + `USING … WITH CHECK …`; decidir el destino de `tenantContext.js`.

### C-10 — El backfill de tenant asigna todo el histórico a un único tenant `demo` **[V]**
- **Evidencia:** `057_backfill_tenant_id.sql:35` `UPDATE usuarios SET tenant_id = demo_tenant_id WHERE tenant_id IS NULL;` y el mismo patrón en `servicios` (42), `bookings` (49), `transactions` (56), `reviews` (63), `portfolio_items` (70), `messages` (77), con `demo_tenant_id` por `slug = 'demo'` (24) e insertado con id fijo en `055:15-17`.
- **Impacto:** todas las filas legacy de producción quedan en el mismo tenant; cualquier usuario con ese `tenant_id` ve (y con C-09, toca) los datos de todos. Las suites `tenant-isolation` que pasan no describen el estado real de los datos.
- **Corrección:** backfill por dueño real a partir de la pertenencia, un tenant por negocio, y verificación con conteos (`SELECT tenant_id, count(DISTINCT owner) …`) antes de declarar la aislación activa.

### C-11 — Clave AES de datos biométricos derivada del `JWT_SECRET` (que está commiteado) **[V]**
- **Archivo:** `backend/src/services/biometricCryptoService.js:6-24`
- **Evidencia:** `9-17`: si falta `BIOMETRIC_ENCRYPTION_KEY` y `NODE_ENV === 'production' || RAILWAY_ENVIRONMENT || !NODE_ENV` → `console.warn('[SECURITY WARNING] … Derivando clave AES-256 desde JWT_SECRET para evitar caida del servidor')` y `SECRET_KEY = sha256(JWT_SECRET || 'glowapp_biometric_fallback_key_32_bytes!')` → **continúa en lugar de fallar**.
- **Impacto:** el mismo secreto cifra biometría y firma sesiones (una fuga compromete ambas); ese `JWT_SECRET` está en el repositorio (C-02); rotarlo deja la biometría indescifrable sin aviso; el criterio `!process.env.NODE_ENV → producción` es **inverso** al de `paymentRoutes.js:164`.
- **Corrección:** exigir la clave y **abortar el arranque** si falta en producción; clave en KMS/Secrets, nunca derivada; plan de rotación con re-cifrado.

### C-12 — Fuga cross-usuario del caché semántico de Aura **[V]**
- **Archivo:** `backend/src/services/semanticCache.js:42-135` + `geminiService.js:331-369`
- **Evidencia (firmas verificadas):** `generateCacheKey(embedding)` (42) hashea solo el embedding; `findSimilarInCache(queryEmbedding)` (54) y `setCache(queryEmbedding, response, metadata)` (106) **no reciben identidad**; el hit se acepta con similitud ≥ 0.92 y la respuesta cacheada se inserta en el hilo del usuario que consulta. **[S]**: TTL 24 h y el contenido puede incluir "Estilo Recomendado / ID Prestador / Precio".
- **Impacto:** un usuario recibe como propia una respuesta generada para otro (fuga entre cuentas + personalización incorrecta), sin auditoría del origen.
- **Corrección:** `user_id`/`tenant_id` en la clave y en la entrada, rechazo del hit si el origen no coincide, y no cachear respuestas con datos personales.

### C-13 — El fallback de Aura se envía y se persiste como respuesta clínica **[S]**
- **Archivo:** `backend/src/services/geminiService.js:880-908`
- **Evidencia citada:** `if (!aiResponseText) { aiResponseText = '¡Hola! … aplica aceite de argán…'; llmUsed = 'safe_fallback'; errorMessage = 'All LLMs failed'; }`, seguido de `INSERT INTO messages` (891-896) y envío por WebSocket (908); el comentario de 870 confirma la intención ("Fallback silencioso - no colapsar").
- **Impacto:** si DeepSeek y Gemini fallan, el usuario recibe un consejo genérico con la misma apariencia que una respuesta real, queda almacenado como historial y la degradación es invisible desde el producto.
- **Corrección:** mensaje de indisponibilidad explícito, no persistido como respuesta clínica; exponer `llm_used` y alertar en el punto del fallo.

### C-14 — Consola de administración: enrutado invertido, sin gate de rol y con token de admin en el bundle **[V]**
- **Login invertido por email [V]:** `admin-dashboard/src/app/(auth)/login/page.tsx:24-28` → `if (email.toLowerCase() === 'admin@glow.app') { window.location.href = '/' } else { window.location.href = '/admin/academia' }`. El rol devuelto por `login()` se ignora. **El admin real va al dashboard raíz sin control de acceso y cualquier usuario no-admin entra al panel de administración.**
- **Sin gate de rol [V]:** `src/app/(dashboard)/layout.tsx:7` envuelve con `<ProtectedRoute>` **sin `allowedRoles`**; en `ProtectedRoute.tsx:20` el chequeo vive dentro de `else if (allowedRoles && …)` → nunca se evalúa. Solo 4 pantallas hacen su propio chequeo (y `admin/vto` ninguna). `src/middleware.ts:4-23` calcula `publicPaths`/`isPublicPath` y **no los usa**: los 3 caminos hacen `NextResponse.next()`.
- **Token de admin en el cliente [V]:** `src/app/page.tsx:152-154` `localStorage.getItem('adminToken') || process.env.NEXT_PUBLIC_ADMIN_TOKEN` → cualquier `NEXT_PUBLIC_*` se inlinea en el bundle público: si la variable existe en el build, el JWT de administrador queda embebido en el JS.
- **Dashboard con datos simulados [S]:** `src/app/page.tsx:44-112` GMV 1.845.000, comisión 221.400, SOS con nombres y teléfonos, KYC pendiente; si el fetch falla (174-179) solo cambia el rótulo a "Modo Simulación" y **conserva las cifras**.
- **Corrección:** redirigir por rol con el valor de `login()`; `allowedRoles={['ADMIN']}` + verificación server-side en middleware/RSC; sacar el token del cliente (cookie httpOnly + Route Handler); eliminar los mocks y mostrar estado vacío/error.

---

## 3. ALTOS

### Backend
| # | Hallazgo | Evidencia |
|---|---|---|
| A-01 | `req.user.rol` no existe (auth.js no lo setea) pero se usa: guard de admin que nunca pasa y rol de BD mal reportado | `auth.js:47-54`; `biometricConsentRoutes.js:234`; `authController.js:810` **[V]** |
| A-02 | El contexto SaaS seleccionado no se usa para el scoping: la membresía valida y el controlador consulta por `req.user.id` | `membership.middleware.js:82-84` vs `businessController.js:45-46,74-75,95-96,113-114` **[V]** |
| A-03 | IDOR/bypass por nombre (`startsWith('demo')`) y escritura por id sin scoping de dueño | `businessRepository.js:292`, `:302-307` **[V]** |
| A-04 | CSP anulada (`connectSrc *`, `imgSrc *`, `unsafe-inline`, `unsafe-eval`) | `index.js:222,251,223-227` **[V]** |
| A-05 | TLS deshabilitado en llamadas salientes | `index.js:278` **[V]** |
| A-06 | Diagnóstico sin auth (`/status`, `/api-docs`) y `/api/health` que **escribe** (`setval`) en cada probe y responde 200 con la BD caída | `index.js:95,97-105,420-431` **[V]** |
| A-07 | `/uploads` sin autenticación desde disco local (no compartido entre réplicas → enlaces rotos en EKS) | `index.js:108-145,349` **[V]** |
| A-08 | Notificaciones push simuladas devolviendo `success: true` | `fcmNotificationService.js:86` **[V]** |
| A-09 | OTP de cierre: en logs y devuelto al cliente salvo `NODE_ENV === 'production'` exacto; sin envío real | `paymentRoutes.js:157,164` **[V]** |
| A-10 | `npm run migrate` → `sync({force:true})` (DROP TABLE) | `backend/package.json` **[V]** |
| A-11 | `main` en rojo: 5-6 suites / 37 tests fallan con el patrón **exacto** de CI; run completo 13 suites / 57 tests. Falla no determinista por crash del worker de Jest (`ciRagEvaluation.test.js`, `Converting circular structure to JSON`) | mis ejecuciones de jest **[V]** |
| A-12 | CI escribe en la BD remota (`knex migrate:latest` + ingest con `secrets.RAILWAY_DATABASE_URL`, **sin bloque `services:`**: `grep -c services:` = 0) y su job de lint ejecuta `npm run lint` cuando ese script **no existe** → éxito sin medir | `rag-evaluation.yml:27,125,131,60`; `backend/package.json` **[V]** |
| A-13 | El "Deploy Gate" no despliega: la condición del paso usa `secrets` en `steps[*].if` (contexto no disponible ahí) y apunta a un webhook de **Railway**; `grep -niE 'eks\|ecr\|aws-actions' .github/workflows/*.yml` → **0 coincidencias**: el pipeline real a EKS/ECR no está versionado, sin health check ni rollback | `rag-evaluation.yml:232-242` **[V]** |
| A-14 | El gate de calidad RAG se invoca con el intérprete equivocado (`node scripts/ciRagEvaluation.sh`; el propio `package.json` declara `bash …`) → nunca bloquea | `rag-evaluation.yml:155`; `package.json:14` **[V]** |
| A-15 | CI excluye 14 suites por patrón de nombre (~23% de 61 archivos), incluidas **todas** las de biometría, contratos y resiliencia | `.github/workflows/ci.yml:36` **[S]** (los archivos: **[V]**) |
| A-16 | Esquema no versionado: `salones`, `salon_miembros`, `salon_invitaciones`, `providers`, `rag_chunks`, `aura_knowledge_chunks` **sin `CREATE TABLE`** en el repo; `memberships`/`business_profiles` solo en `src/db/migrations/012,013`, que el runner **nunca lee** | greps por tabla **[V]** |
| A-17 | `POST /api/ai/orchestrate` sin autenticación, con herramientas decididas por el modelo; el guard de traversal resuelve a la raíz del sistema (`path.resolve(process.cwd(), '../../')`) y no acota nada. Alcance real: hoy devuelve `{file, contentLength}`, **no el contenido** → sin exfiltración actual, sí endpoint abierto al abuso | `aiOrchestratorRoutes.js`; `orchestrator.service.js:9-30,56-95`; `index.js:416` **[V]** |
| A-18 | `adminMiddleware` triplicado con políticas distintas (uno consulta la BD en cada request, otro confía en el token, un tercero lo replica) | `index.js:44-62`; `middleware/auth.js:63-73`; `middleware/admin.js:4-14` **[V]** |
| A-19 | `ReferenceError` en el camino de consentimiento biométrico: `logAccess` se usa pero no se importa (solo `checkConsent`) y el error se traga en el `catch` "fallback silencioso" | `geminiService.js:805` vs `:12` **[V]** |
| A-20 | Interpolación de `tenantId` en SQL del retrieval RAG (único punto sin parametrizar) | `ragService.js:103,152` **[S]** |
| A-21 | El chat de Aura nunca propaga `tenantId` (conocimiento propio inalcanzable) y el filtro `category` que envía el ejecutor no existe en el receptor (se descarta en silencio) | `geminiService.js:297,532,829`; `auraToolExecutor.js:277`; `ragService.js:86` **[S]** |
| A-22 | En el fallback de Gemini los nombres de los argumentos de las herramientas no coinciden con los que lee el ejecutor → herramientas clave se invocan con `undefined` | `geminiService.js:636-697` vs `auraToolExecutor.js:236-272` **[S]** |

### Frontend Flutter
| # | Hallazgo | Evidencia |
|---|---|---|
| F-01 | Cuatro navegaciones a rutas **no declaradas** (`/wallet`, `/settings`, `/glowaipremium`, `/provider-detail`) → `Could not find a generator for route` | `my_glow_dashboard_screen.dart:171,178`; `wardrobe_dashboard_screen.dart:204`; `client_bookings_screen.dart:1085`; ausencia verificada en `main.dart` (32 rutas declaradas) **[V]** |
| F-02 | `salonId ?? 1`: el OWNER invita a un miembro al salón **1** (otro tenant) si los datos aún no cargaron | `salon_dashboard_screen.dart:307` **[S]** |
| F-03 | Seguimiento "en vivo" del prestador = interpolación lineal local (llega "siempre" en ~40 s), no GPS | `booking_tracking_screen.dart:56,115-139` **[S]** |
| F-04 | La ruta del prestador se simula (~20 s) y habilita el botón de llegada por tiempo, no por geocerca | `provider_route_screen.dart:45,60-88` **[S]** |
| F-05 | Generador de notificaciones **falsas** cada 45 s (ofertas y nombres concretos), timer que no se cancela y `navigatorKey` distinto al de `MaterialApp` → nunca se ven y consumen batería | `notification_service.dart:9-11,24-34,49-53` vs `main.dart:163` **[S]** |
| F-06 | Desglose de pagos del prestador con cuenta Nequi y referencia Wompi **inventadas** (campo que el backend no devuelve) | `provider_dashboard_screen.dart:296-300`; `bookingController.js:266-283` **[S]** |
| F-07 | El rol del JWT se decodifica y **nunca se lee** (`_userRole`, `_hasToken` sin uso): sin gateo por rol, sin validar `exp`, sin manejo de 401 (0 ocurrencias) | `main.dart:328-329,838-858` **[S]** |
| F-08 | JWT guardado además en `SharedPreferences` en claro | `auth_service.dart:43-44,353-354` **[S]** |
| F-09 | Identificador de pedido fabricado en el cliente (`STORE_<epoch>`) usado como referencia de transacción y de analytics | `store_screen.dart:391` **[S]** |
| F-10 | **2 errores de compilación** en `lib/`: `undefined_method` (`fetchConsignmentInventory`, `consumeInventoryItem`) | `flutter analyze lib` → `2 error`, `535 info`, **0 warnings** **[V]** |

### Admin-dashboard
| # | Hallazgo | Evidencia |
|---|---|---|
| D-01 | El endpoint que consume el dashboard raíz no está montado en el entry real (`grep -c glow-admin index.js` → 0; solo en el `app.js` muerto) → **404 permanente** que el panel disfraza de "Modo Simulación" | `src/app/page.tsx:161`; `backend/index.js`; `backend/src/startup/app.js:253` **[V]** |
| D-02 | `GET /api/bookings` no existe (solo `/bookings/provider` y `/bookings/client`) → "Mis Citas" vacías | `api-client.ts:43`; `bookingRoutes.js:9,12,15` **[V]** |
| D-03 | El error de `useBookings` se captura y nunca se renderiza (los 404 se muestran como "sin citas") | `useBookings.ts:15,23-25`; 4 consumidores **[S]** |
| D-04 | `@ts-nocheck` en la pantalla admin más grande (CRUD de Academia con 10 mutaciones) + 33 `any` | `admin/academia/[id]/page.tsx:1` **[S]** |
| D-05 | `npm run lint` **exit 2** (config ESLint 9 + `eslint-config-next` 15.x incompatible) y `eslint.ignoreDuringBuilds: true` → **0 reglas aplicadas**, build siempre verde | medí `npm run lint` → `exit=2` **[V]**; causa en `eslint.config.mjs:6` **[S]** |
| D-06 | Guard de `/admin/business` usa la bandera de **datos** en vez de la de auth y envía `Bearer 'admin-token'` literal cuando no hay sesión | `admin/business/page.tsx:48-62,70,106,138` **[V]** (el token literal) |
| D-07 | 4 endpoints de chat que el panel usa no existen (`/api/chats*`) y la pantalla responde con `setTimeout` | `api-client.ts:60,65,70` vs `chatRoutes.js:10-13` **[S]** |
| D-08 | `PUT /api/users/profile` cuando el backend solo acepta `PATCH`, y el submit del perfil no llama a ninguna API | `api-client.ts:76` vs `index.js:1138`; `perfil/page.tsx:9-17` **[V]** (los métodos) |
| D-09 | `/register` y `/nueva-cita` son simulaciones (`setTimeout` + `alert`) que no invocan la API | `register/page.tsx:16-23`; `cliente/nueva-cita/page.tsx:17-33` **[S]** |
| D-10 | Dos tokens en `localStorage` (`glow_token` y `adminToken`) como fuentes de verdad paralelas, y 3 variables de entorno distintas para la URL del API | `AuthContext.tsx:58-62`; `business/page.tsx:55`; `app/page.tsx:151` **[S]** |
| D-11 | Pre-existencias del informe anterior **confirmadas/corregidas**: el redirect por rol está *agravado* (es por **email**, invertido) y `react-hooks/set-state-in-effect` **no es reproducible** | **[V]** el redirect; **[S]** el resto |

### IA / RAG
| # | Hallazgo | Evidencia |
|---|---|---|
| R-01 | Métricas clínicas constantes y fallback que devuelve diagnóstico ante imagen corrupta (ver C-08) | `color_analysis.py:40-56`; `main.py:36-42` **[V]** |
| R-02 | El caché semántico no incluye usuario (ver C-12) | `semanticCache.js:42,54,106` **[V]** |
| R-03 | `safe_fallback` de Aura servido y persistido como respuesta (ver C-13) | `geminiService.js:880-908` **[S]** |
| R-04 | Incompatibilidad de contrato worker↔backend (ver C-07) | **[V]** URLs; **[S]** campos |
| R-05 | El análisis facial "simulado" se devuelve como resultado si falta `GEMINI_API_KEY`, con referencias de validación inventadas en proceso | `designsController.js:434,565,1582` **[V]** |
| R-06 | Respuestas de benchmark/`schema` **simuladas** servidas como datos del orquestador | `orchestrator.service.js:40,48` **[V]** |
| R-07 | `logAccess` no importado (ver A-19) y `tenantId`/`category` no propagados (A-20, A-21, A-22) | **[V]**/**[S]** |
| R-08 | `skin_metrics.py` importa `SkinMetricsResponse`, que no existe en `models.py`; el módulo no se importa desde `main.py` → capacidad aparente pero inutilizable | `ai_worker/services/skin_metrics.py:3,7` **[S]** |
| R-09 | CORS del worker con `allow_origins=['*']` + `allow_credentials=True` (combinación que el navegador rechaza) | `ai_worker/main.py` **[S]** |
| R-10 | Maquinaria `beautyScanWorker` declarada y no usada | **[S]** |
| R-11 | Coste/eficiencia: embeddings sin caché, llamadas en serie donde cabría batch y timeouts dispares (5 s vs 240 s) | **[S]** |
| R-12 | Baselines de evaluación incompatibles con el mapeo actual (`baseline_real_r5b.json`: `precision_at_k=0.1556` frente a un evaluador que daría 0) → sugiere otro esquema en la generación | **[S]** |
| R-13 | `/v1/ai/consult` no tiene ningún llamador en el repositorio (superficie muerta expuesta) | **[S]** |

### Repositorio / CI / dependencias
| # | Hallazgo | Evidencia |
|---|---|---|
| H-01 | **Wrapper de Gradle versionado: 22.043 archivos / 532 MB** en `frontend/android/gradle/` (javadoc e imágenes del wrapper) | `git ls-files frontend/android/gradle/wrapper \| wc -l` → **22043**; `du -sh` → **532M** **[V]** |
| H-02 | El rollback `.down.sql` se aplica antes del up (ver C-01) | **[V]** |
| H-03 | CI rojo + 14 suites excluidas (ver A-11, A-15) | **[V]** |
| H-04 | Deploy inexistente/muerto y sin EKS/ECR (ver A-13) | **[V]** |
| H-05 | Gate de calidad RAG roto por intérprete (ver A-14) y **errores de migración silenciados** (se registran como advertencia y el runner sigue) | `migrationRunner.js:43-46`; `index.js:1638-1645` **[V]** |
| H-06 | Bloat de la raíz: **672 `.md`** sueltos (221 `F7.*`, 303 `GIA-*`, 65 `D00*`, 12 `D-00*`, 71 otros) + 5 scripts sueltos + `test_face.jpg` + `0)ls` + 4 `.report`; **691 archivos / 2,53 MB** | conteo del subagente **[S]** |
| H-07 | `backend/public/` **trackeado** con 60 archivos / 52,7 MB, incluido `main.dart.js` de **189.468 líneas** (build de Flutter Web versionado como fuente) | `main.dart.js` y tamaño **[V]** |
| H-08 | `.hermes/` **trackeado** (14 archivos) con un volcado de sesión de 588 KB y un `.pyc` — **sin credenciales reales** (ver §5) | **[V]** |
| H-09 | 8 vulnerabilidades `high` en dependencias de producción del backend; `admin-dashboard` **sin `package-lock.json`** (npm audit imposible: ENOLOCK) | **[S]** |
| H-10 | 4 sistemas de migración conviviendo (`index.js` inline, `migrationRunner.js`, `knexfile.js`, `src/db/migrations/` huérfano) sin tabla de tracking, + 3 backups `.bak`/`.backup` en el directorio + prefijos duplicados `056_*` | **[V]** los archivos; **[S]** el inventario |

---

## 4. MEDIOS Y BAJOS (condensado)

**Backend — medios:** sanitizador inefectivo y destructivo (`sanitizer.js:29-40`; asignar `req.query`/`req.params` es no-op en Express 4) **[V]** · pagos sin idempotencia (el middleware solo se monta en endpoints biométricos) y webhook sin reconciliar `amount` contra `valor_bruto` **[V]** · `/api/salon` montado dos veces (`index.js:388,529`) **[V]** · apagado ordenado roto: `const server` en scope de bloque (1728) referenciado en 1781 → `ReferenceError` en SIGTERM **[V]** · 11 endpoints inalcanzables en 5 routers huérfanos (`inventoryRoutes`, `learningPathRoutes`, `userLevelRoutes`, `b2bCoPilotRoutes`, `shortcutRoutes`) **[V]** · `src/startup/app.js` (364 líneas) es un entry falso: 29 mounts vs 43, y 3 rutas que el real no tiene **[V]** · monolito de 1807 líneas con 24 endpoints inline **[V]** · rate limit global 1000 req/15 min para todo `/api` **[V]** · logs no estructurados (winston `json` sobreescrito por `colorize().simple()`) **[V]** · `NODE_ENV` como único interruptor de seguridad con criterios contradictorios **[V]** · firma de webhook sobre `JSON.stringify(req.body)` en vez del cuerpo crudo **[V]** · `express.json({limit:'50mb'})` **[V]** · `queue.service.js` muerto con cola en memoria **[V]**.

**Frontend — medios/bajos:** baseline `2 error + 535 info` (0 warnings) **[V]** · 87 usos de `withOpacity` (deprecado) **[S]** · 56 archivos `.dart` sin importador alcanzable **[S]** · `stagingUrl` apuntando a producción **[S]** · JWT y payload en logs de debug **[S]** · `catch` vacíos que tragan errores **[S]** · tres `late final` sin inicializar (`main.dart:341-343`, motores de audio/persistencia de GlowGuide) **[S]** · 12 rutas declaradas y nunca navegadas por nombre **[S]** · 9 `print` en producción y `ws://10.0.2.2:3000` embebido en un widget inalcanzable **[S]** · un único TODO real (`s4_text_field.dart:99`, tokens de tema fijos en claro) **[S]**.

**Admin — medios:** sin paginación (`SELECT` sin `LIMIT`, `academyAdminRoutes.js:17`) y filtro `showOnlyActive` declarado pero inerte (`academia/page.tsx:44`) **[V]/[S]** · 5 warnings de `react-hooks/exhaustive-deps` **[S]** · `useSocket` sin reconexión y sin consumidores **[S]** · `middleware.ts` no-op **[V]** · `/admin/vto` sin chequeo de rol **[S]**.

**IA/RAG — medios:** dependencias Python sin auditar (6 paquetes fijados) **[S]** · código muerto duplicado en el worker **[S]** · dimensión de embedding y UK de título sin verificar contra la BD **[S]**.

**Repo — medios/bajos:** 3 backups `.bak`/`.backup` versionados dentro de `backend/migrations/` **[V]** · APK de 111,5 MB y ~3,3 GB de `build/`/`.next/`/`coverage/` **sin** trackear (correcto) **[S]** · `.git` de 1,3 GB **[S]** · `registry` npm por defecto = espejo sin endpoint de auditoría **[V]** · `node_modules/` en la raíz del repo **[V]**.

---

## 5. Anexo de verificación — qué reverifiqué y qué refuté

| Afirmación original | Estado | Evidencia de mi verificación |
|---|---|---|
| "El volcado en `.hermes/desktop-attachments/*.json` contiene una cadena de conexión de producción **con contraseña real**" (subagente 4, marcado **Crítico**) | **🔴 REFUTADA** | La contraseña en ese archivo es **literalmente `***`** (redactada al exportar): `grep -c 'postgresql://postgres:\*\*\*@' <archivo>` → **4**. El archivo sigue siendo basura versionada (H-08), pero **no expone una credencial**. Degradado de Crítico a Bajo. |
| "`npm run lint` de admin-dashboard reporta **98 errores / 5 warnings**" | **🟡 MATIZADA** | Esa cifra viene de un **proxy** ESLint escrito fuera del repo: el `npm run lint` real **sale con exit 2** y no aplica ninguna regla. Los 98 miden el proxy, no el proyecto. |
| "`react-hooks/set-state-in-effect` es un error preexistente del admin" (informe anterior) | **🔴 NO REPRODUCIBLE** | El plugin instalado (5.2.0) solo expone `rules-of-hooks` y `exhaustive-deps`. |
| "El `cwd` es el repo del proyecto" | **🔴 CORREGIDO** | Está 1297 commits atrás (congelado 2026-08-04). Auditoría hecha sobre `C:/beauty-app`. |
| "`academyAdminRoutes.js` tiene 17 rutas sin autorización" (mi propio escáner, primera pasada) | **🔴 FALSO POSITIVO MÍO, retractado** | `academyAdminRoutes.js:10` → `router.use(authMiddleware, adminMiddleware)`: **sí** está protegido. Mi escáner no leía los `router.use` a nivel de archivo. |

**Re-verifiqué yo (confirman el hallazgo del subagente):** pago falso de la tienda y propina simulada (`wompi_payment_sheet.dart:117-127`, `client_bookings_screen.dart:228-243`) **[V]** · ausencia de `/wallet`, `/settings`, `/glowaipremium`, `/provider-detail` en `main.dart` **[V]** · los dos `undefined_method` del analyzer **[V]** · el endpoint inexistente en `ai_worker` y la URL que llama el backend **[V]** · las constantes `85.5/40.2` y el fallback que devuelve diagnóstico **[V]** · la clave de NVIDIA trackeada y además impresa **[V]** · el orden `.down.sql` antes del `.up` y el `DROP COLUMN embedding` **[V]** · el login del admin invertido por email **[V]** · `<ProtectedRoute>` sin `allowedRoles` **[V]** · `NEXT_PUBLIC_ADMIN_TOKEN` **[V]** · `npm run lint` → exit 2 **[V]** · `GET /api/bookings` inexistente **[V]** · `POST /store/checkout` **sí** existe (el pedido se persiste sin cobro) **[V]** · `/api/glow-admin` no montado en el entry real **[V]** · gradle wrapper de 22.043 archivos / 532 MB **[V]** · `node scripts/ciRagEvaluation.sh` **[V]** · ausencia de bloque `services:` y de toda referencia a EKS/ECR **[V]**.

---

## 6. No medido / hipótesis (y qué medición lo resuelve)

1. **Estado real de las bases de datos.** No se ejecutó ninguna conexión (regla de solo lectura). Todo lo relativo a RLS efectivo, filas con `tenant_id = demo`, claves foráneas inexistentes y **cuántos embeddings sobreviven** es **hipótesis**. Medición: `SELECT count(*), count(embedding) FROM beauty_knowledge_embeddings`; `SELECT tenant_id, count(*) FROM usuarios GROUP BY 1`; `SELECT relrowsecurity, relforcerowsecurity FROM pg_class WHERE relname IN ('usuarios','bookings')`.
2. **El contrato real del worker (C-07).** Verifiqué las URLs y leí el modelo, pero no ejecuté un request contra `ai_worker`. Medición: `curl -X POST http://localhost:8000/api/v1/analyze-skin` con el body que envía el proxy y comprobar 422.
3. **Vigencia de las claves expuestas.** No hice llamadas de red con credenciales ni puedo saber si ya fueron rotadas. Medición: probar/rotar en cada proveedor.
4. **El pipeline de despliegue real.** No hay workflow de deploy versionado; si existe configuración externa (EKS, Helm, aprobaciones de entorno) no es auditable desde el repositorio y `gh` no está disponible en Windows. Medición: consola de GitHub/AWS.
5. **Cumplimiento del esquema real con lo que el código asume** (`bookings.comision_plataforma` NULL vs no NULL, existencia de `salones`/`salon_miembros`, `memberships.user_id` INTEGER). Decide si parte de la UI muestra 0 y si varias suites pueden ser de integración real. Medición: `information_schema.columns`.
6. **Vulnerabilidades de dependencias.** Los 8 `high` del backend los reporta el subagente; **no** re-ejecuté la auditoría de paquetes. `admin-dashboard` no se puede auditar (sin lockfile); tampoco Python ni Dart.
7. **Ejecución en runtime.** No se levantó la app ni el backend; ningún hallazgo describe comportamiento observado en producción, solo código y configuración. La excepción son los conteos de test y de análisis estático, que sí ejecuté.

---

## 7. Prompt de corrección (fases, para el agente implementador)

> Trabaja sobre `C:/beauty-app`, rama nueva, un commit por fase. **No toques el esquema ni las rutas de dinero/IA/biometría sin cerrar la fase 0.** Los hallazgos marcados **[S]** provienen de subagentes: verifícalos en la fase 0 antes de actuar sobre ellos, y **no** ejecutes nada que escriba en la base de datos real.
>
> **Fase 0 — verificación read-only (sin una línea de código).** Para cada Crítico, ejecuta el comando de evidencia del informe y devuelve una tabla `confirmado / refutado / bloqueado` con `archivo:línea`. Atención especial a C-01: **antes de tocar migraciones**, consulta `SELECT count(*), count(embedding) FROM beauty_knowledge_embeddings` y reporta cuántos embeddings quedan.
>
> **Fase 1 — contención de secretos (C-02, C-06).** Rotar `JWT_SECRET`, `ENCRYPTION_KEY`, contraseña de Postgres, `GEMINI_API_KEY`, `YOCAM_API_KEY`, `OPENUV_API_KEY`, clave de NVIDIA. `git rm --cached backend/.env.production` y los tres `backend/scratch/*.js`; borrar el `console.log` de `seed_glowapp_kb.js:7` y el literal de la línea 2; purgar historial con `git filter-repo`. `gitleaks` bloqueante en CI. Criterio: `git log -p --all -- backend/.env.production | wc -c` → 0 y `grep -rn "Password:" backend/src` → 0.
>
> **Fase 2 — runner de migraciones y operaciones destructivas (C-01, A-10, H-05).** Excluir `.down.sql` en los tres runners, mover los rollbacks fuera del directorio, añadir `schema_migrations` y hacer que un error de migración **falle el arranque** en vez de advertir. Renombrar el script `migrate` (`sync({force:true})`) con aborto si `NODE_ENV === 'production'`. Criterio: arrancar el backend dos veces seguidas y comprobar que `SELECT count(*) FROM beauty_knowledge_embeddings` **no cambia**, y que la salida del runner no menciona ningún `.down.sql`.
>
> **Fase 3 — dinero (C-05).** `payBooking` devuelve `501 PAYMENT_GATEWAY_NOT_INTEGRATED` cuando `NODE_ENV === 'production'`; borrar la rama `STORE_` de `wompi_payment_sheet.dart`; eliminar el texto "Simulando pasarela Wompi" y la simulación de la propina; crear la orden en `PENDING_PAYMENT` **antes** de abrir la pasarela; idempotencia en el pago y en el webhook; comparar `amount` contra `valor_bruto`. **Decisión del director pendiente:** integrar Wompi o retirar el cobro — no la tomes tú.
>
> **Fase 4 — autenticación y tenancy (C-04, C-09, C-10, C-11, A-01, A-02, A-03).** WS con token obligatorio y `providerId` del token; `FORCE ROW LEVEL SECURITY` + rol sin privilegios de dueño + `SET LOCAL` en la misma conexión; backfill de tenant por dueño real; clave biométrica propia con aborto en producción; setear `req.user.rol` o eliminar sus usos; scoping por el `businessProfileId` validado por membresía; quitar el bypass `startsWith('demo')`. Criterio: test de dos tenants concurrentes que falle si aparece una fila ajena. **Mutación obligatoria:** fuerza la política a `USING (true)` y comprueba que ese test se pone rojo (un rojo por el lado equivocado no prueba nada).
>
> **Fase 5 — IA/biometría honesta (C-07, C-08, C-12, C-13, R-*).** Unificar el contrato con `ai_worker` (una sola fuente de verdad + test contra `openapi.json`); devolver `null`/422 cuando la imagen no es analizable (fuera el `85.5`/`40.2` constante); retirar `simulateDoctorReview` y los mocks de producción; `user_id`/`tenant_id` en la clave del caché semántico; fuera el `safe_fallback` persistido; importar `logAccess`; parametrizar `tenantId` en SQL; corregir los nombres de argumentos de las herramientas de Gemini.
>
> **Fase 6 — CI y despliegue (A-11 a A-15, H-01, H-03, H-04).** Arreglar las suites `business*` **solo en el lado de test** (fixture con id numérico → perfil → membresía ACTIVA); quitar `--forceExit`; eliminar `--testPathIgnorePatterns` (arreglar o `describe.skip` explícito y trazable); BD efímera `pgvector` en el workflow de RAG; crear el workflow real de deploy a ECR/EKS con health check sobre `/healthz` y `kubectl rollout undo`; `bash` en vez de `node` para el gate RAG; quitar `ignoreDuringBuilds` y arreglar `eslint.config.mjs`. Criterio: `main` verde con el patrón exacto de `ci.yml` y `Tests: 0 failed`.
>
> **Fase 7 — limpieza (sin refactor funcional).** Sacar del índice el gradle wrapper (532 MB), `backend/public/` (build de Flutter Web), los `.md` de gobernanza de la raíz (a `docs/governance/` con índice), los backups `.bak`, `.hermes/desktop-attachments/`, el APK, `test_face.jpg`, `0)ls`; unificar los tres `adminMiddleware`, los cuatro runners de migración y el entry falso `src/startup/app.js`.
>
> **Reglas permanentes:** ningún secreto en el repositorio ni en logs; nada de `success: true` ni de datos clínicos fabricados; cada fase cierra con la medición que la prueba (no con una descripción); ningún cambio en archivos no relacionados; si un hallazgo resultó refutado, dilo con la evidencia que lo refuta — este informe contiene una refutación, una matización y un falso positivo propio, todos marcados como tales.

---

## 8. Anexos

- Detalle extendido del backend (prosa larga, misma evidencia): `AUDITORIA-360-2026-09-22.md`
- Informes crudos por subsistema (169 hallazgos en detalle, incluidos los aquí condensados): `raw/01-flutter.txt` (42 KB), `raw/02-admin-dashboard.txt` (44 KB), `raw/03-ia-rag.txt` (62 KB), `raw/04-higiene-ci.txt` (74 KB)
- Todo está en `C:/Users/Compu casa/auditorias/belleza-app/`, **fuera del repositorio**: el código no fue tocado en ningún momento.
