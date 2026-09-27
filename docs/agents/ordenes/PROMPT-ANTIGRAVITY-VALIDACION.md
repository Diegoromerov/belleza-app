# PROMPT PARA ANTIGRAVITY — Validación independiente + segunda pasada de auditoría
**Regla absoluta: SOLO LECTURA. No modifiques, crees ni borres ningún archivo. No hagas commits.**

---

Eres el agente de implementación del mismo repositorio. Otra sesión de auditoría (Hermes) acaba de producir una **auditoría 360**
sobre `C:/beauty-app` en el commit **`d018587d`** (main, 2026-09-22). No la diste tú y **no la des por buena**: tu trabajo aquí es
doble y ninguno de los dos incluye escribir código.

## 0. Reglas de esta tarea (duras)

1. **Cero modificaciones.** No edites, crees, muevas ni borres archivos. No `git add`, no `git commit`, no `git stash`, no `git checkout`,
   no `git clean`, no `git reset`. No ejecutes formateadores ni `--fix`.
2. **No instales nada** (`npm install`, `pip install`, `flutter pub get`).
3. **No ejecutes nada que escriba en una base de datos.** Prohibido ejecutar `backend/scratch/*.js`, los `seed_*.js` de la raíz,
   `backend/scripts/r6*.js`, `ingestBeautyKnowledge.js` y cualquier script que abra `DATABASE_URL`/`RAG_DATABASE_URL`. Si necesitas
   estado de la BD, **pide el `SELECT`** y márcalo como pendiente; no lo ejecutes.
4. Sí puedes: leer, `grep`/`rg`, `git log`/`git show`/`git ls-files`, `node --check`, `flutter analyze`, `npm test` (jest no escribe en la BD
   con `NODE_ENV=test`), `npm run build`/`npm run lint` del admin.
5. **Los informes viven fuera del repositorio.** Léelos antes de empezar:
   - `C:/Users/Compu casa/auditorias/belleza-app/AUDITORIA-360-CONSOLIDADA-2026-09-22.md` (síntesis: 27 críticos / 57 altos / 55 medios / 30 bajos)
   - `C:/Users/Compu casa/auditorias/belleza-app/AUDITORIA-360-2026-09-22.md` (detalle extendido del backend)
   - `C:/Users/Compu casa/auditorias/belleza-app/raw/01-flutter.txt`, `02-admin-dashboard.txt`, `03-ia-rag.txt`, `04-higiene-ci.txt` (crudos por subsistema)
6. En los informes, **[V]** = verificado por Hermes con comando o lectura directa; **[S]** = reportado por un subagente y **no** re-ejecutado.
   Tu prioridad son los **[V]** (si alguno está mal, es un error grave) y después los **[S]** (si alguno está mal, hay que degradarlo).
7. Declara al principio **el SHA que auditaste** (`git rev-parse HEAD`), el estado de tu árbol (`git status --porcelain`) y si difiere del
   de la auditoría. Sin eso, la comparación no es válida. **Ojo: el árbol se mueve** — otro agente trabaja en el mismo checkout.

---

## 1. ENTREGABLE A — Validación independiente de los hallazgos

Verifica cada hallazgo **por el mecanismo que nombra** (no por plausibilidad): abre el archivo y lee la línea citada, ejecuta el comando,
compara cifras. Para cada uno entrega un veredicto:

- **CONFIRMADO** — reproducido; añade la salida del comando o la línea exacta que lo prueba.
- **REFUTADO** — no se sostiene; adjunta **la evidencia que lo refuta** (comando + salida, o el código real). Esto vale tanto como un confirmado:
  si refutas un **[V]**, dilo sin matices.
- **MATIZADO** — el hecho existe pero el impacto/alcance/severidad está mal calibrado (explica por qué y cuál sería la severidad correcta).
- **BLOQUEADO** — no verificable sin tocar la BD o sin credenciales; di exactamente qué medición lo resolvería.

### Bloque 1 — Críticos (verifica en este orden)
| ID | Qué se afirma | Dónde mirar |
|---|---|---|
| C-01 | El runner ejecuta `035_….down.sql` **antes** del `up` en cada arranque y el rollback hace `DROP COLUMN IF EXISTS embedding` → los embeddings del RAG se borran en cada reinicio | `backend/index.js:1627-1630`, `backend/src/config/migrationRunner.js:15`, `backend/knexfile.js:17`, `backend/migrations/035_fix_embedding_dimension_and_hnsw_index.down.sql:55` |
| C-02 | Secretos de producción versionados: `backend/.env.production` (11 valores no-placeholder), password de la BD de Railway en `backend/scratch/{make_pg_dump,verify_after_deploy,verify_real_railway}.js`, y clave de NVIDIA en `seed_glowapp_kb.js:2` (que además se imprime en `:7`) | `git ls-files \| grep -iE '(^\|/)\.env'`, `git check-ignore -v --no-index <f>`, `git ls-files --error-unmatch <f>` |
| C-03 | Un error transitorio de BD deja el proceso sirviendo datos fabricados **para siempre** (`isPgAvailable` arranca en `false`, el camino de recuperación es inalcanzable, `testConnection` devuelve `true` al fallar) | `backend/src/config/db.js:428-497` |
| C-04 | WebSocket sin autenticación: registro con `userId` plano sin token, `join_booking_room` sin validar pertenencia, `location_update` escribe la ubicación con el `providerId` del cliente | `backend/src/services/websocketService.js:61-107` |
| C-05 | El cobro es un simulador en 4 sitios (cita backend sin guarda de `NODE_ENV`; tienda y propina en Flutter; SOS/KYC del admin) y el pedido de tienda **sí** se persiste | `backend/src/controllers/bookingController.js:440-553`; `frontend/lib/widgets/wompi_payment_sheet.dart:117-127`; `frontend/lib/screens/client_bookings_screen.dart:228-243`; `admin-dashboard/src/app/page.tsx:186-199` |
| C-06 | Credenciales en logs: `authController.js:87` imprime `email` **y `password`**; `seed_glowapp_kb.js:7` imprime la clave de NVIDIA; `paymentRoutes.js:157` imprime el OTP | esos tres archivos |
| C-07 | `/api/v1/beauty-scan` llama a una ruta **inexistente** en `ai_worker` (solo hay `/api/v1/analyze-skin` y `/v1/ai/consult`) → 500 en producción; y el contrato emisor (multipart, 4 fotos) no coincide con el receptor (JSON `{image_base64}`) | `backend/src/routes/v1/beautyScanRoutes.js:12,46`; `ai_worker/main.py:36,44`; `ai_worker/models.py:4-13` |
| C-08 | Diagnóstico biométrico inventado: `hidratacion: 85.5` y `sebo: 40.2` hardcodeados; el `except` de imagen corrupta devuelve un diagnóstico completo con HTTP 200; en Flutter hay mock de respaldo y la pantalla de proceso navega a Resultados con él; `simulateDoctorReview` escribe una nota clínica aleatoria a los 15 s | `ai_worker/services/color_analysis.py:40-56`; `frontend/lib/services/biometric_service.dart:110-116`; `frontend/lib/screens/ideas/processing_screen.dart:88-98`; `backend/src/controllers/designsController.js:1654-1672` |
| C-09 | RLS inerte: `ENABLE` sin `FORCE` (0 `WITH CHECK`), `set_config(..., false)` en conexión arbitraria del pool sin reset, `tenantContext.js` crea un segundo `Pool` y **no está montado en ninguna parte**; 6 tablas con datos de tenant quedan fuera de la lista de RLS | `backend/migrations/058_enable_rls_policies.sql:30,61-63`; `backend/src/middleware/auth.js:43-45`; `backend/src/middleware/tenantContext.js` |
| C-10 | El backfill asigna **todo** el histórico (`usuarios`, `servicios`, `bookings`, `transactions`, `reviews`, `portfolio_items`, `messages`) a un único tenant `demo` | `backend/migrations/057_backfill_tenant_id.sql:35-77`; `055_create_tenants_table.sql:15-17` |
| C-11 | La clave AES de datos biométricos se **deriva de `JWT_SECRET`** cuando falta `BIOMETRIC_ENCRYPTION_KEY`, sin abortar, en producción | `backend/src/services/biometricCryptoService.js:9-17` |
| C-12 | El caché semántico no incluye identidad: `generateCacheKey(embedding)`, `findSimilarInCache(queryEmbedding)`, `setCache(queryEmbedding, response, metadata)` → un usuario puede recibir la respuesta cacheada de otro | `backend/src/services/semanticCache.js:42,54,106`; `backend/src/services/geminiService.js:331-369` |
| C-13 | El fallback `safe_fallback` de Aura (tip de aceite de argán) se envía **y se persiste** como respuesta cuando fallan todos los LLM | `backend/src/services/geminiService.js:880-908` |
| C-14 | Admin: el login redirige **por email y al revés** (`admin@glow.app → '/'`, el resto → `/admin/academia`); `<ProtectedRoute>` se usa **sin `allowedRoles`** (el chequeo de rol nunca corre); `NEXT_PUBLIC_ADMIN_TOKEN` llega al bundle; el dashboard raíz sirve métricas financieras y SOS simulados | `admin-dashboard/src/app/(auth)/login/page.tsx:24-28`; `src/app/(dashboard)/layout.tsx:7`; `src/components/auth/ProtectedRoute.tsx:20`; `src/app/page.tsx:44-112,152-154` |

### Bloque 2 — Altos: valida al menos estos, que son los que más condicionan el plan
- `req.user.rol` **no existe** (auth.js no lo setea) y se lee en `biometricConsentRoutes.js:234` y `authController.js:810`.
- El contexto SaaS seleccionado **no se usa** para el scoping: `membership.middleware.js:82-84` vs `businessController.js:45-46,74-75`.
- Bypass de autorización por nombre: `businessRepository.js:292` (`providerId.startsWith('demo')`) y `UPDATE … WHERE id = $1` sin dueño en `:302-307`.
- `adminMiddleware` **triplicado** con políticas distintas: `index.js:44-62`, `middleware/auth.js:63-73`, `middleware/admin.js:4-14`.
- `POST /api/ai/orchestrate` **sin auth**, con herramientas ejecutadas por el modelo; el guard de path resuelve a la raíz del sistema (`path.resolve(process.cwd(), '../../')`).
- `/api/health` **escribe** (`setval`) en cada probe y responde 200 con la BD caída; `/status` y `/api-docs` sin auth. `/uploads` servido sin autenticación desde disco local.
- `npm run migrate` = `sequelize.sync({force:true})` → **DROP TABLE**.
- `main` en rojo: con el patrón **exacto** de `ci.yml:36`, jest da `5-6 suites / 37 tests` fallidos; run completo `13 suites / 57 tests`. Hay una suite que a veces **no se ejecuta** (crash del worker de Jest en `ciRagEvaluation.test.js`).
- CI escribe en la BD remota (`knex migrate:latest` + ingest con `secrets.RAILWAY_DATABASE_URL`, **sin** bloque `services:`) y su job de lint llama a un script `lint` que no existe.
- El "Deploy Gate" no despliega: `if: ${{ secrets.RAILWAY_DEPLOY_HOOK }}` en un `step` (contexto no disponible ahí) y apunta a Railway; **no hay** workflow a EKS/ECR.
- El gate de calidad RAG se invoca con el intérprete equivocado: `node scripts/ciRagEvaluation.sh`.
- Esquema no versionado: sin `CREATE TABLE` en el repo para `salones`, `salon_miembros`, `salon_invitaciones`, `providers`, `rag_chunks`, `aura_knowledge_chunks`; `memberships`/`business_profiles` solo en `backend/src/db/migrations/012,013`, que el runner **nunca lee**.
- Flutter: 4 navegaciones a rutas **no declaradas** (`/wallet`, `/settings`, `/glowaipremium`, `/provider-detail`); `salonId ?? 1` invita a otro tenant; seguimiento y ruta del prestador simulados por temporizador; notificaciones falsas cada 45 s; `2 errores` de `undefined_method` en `flutter analyze lib`.
- Admin: `GET /api/bookings` y `/api/glow-admin/*` no existen en el entry real (404); `npm run lint` sale con **exit 2** y `ignoreDuringBuilds: true` (cero reglas aplicadas); `@ts-nocheck` en el CRUD de Academia.
- Repo: `frontend/android/gradle/wrapper` **trackeado** (22.043 archivos / 532 MB); `backend/public/main.dart.js` de 189.468 líneas trackeado; 672 `.md` sueltos en la raíz.

*(El detalle con `archivo:línea` y comandos de cada uno está en los informes del punto 0.5. Consúltalos antes de responder.)*

### Formato de salida del Entregable A
Tabla con: `ID | veredicto (CONFIRMADO/REFUTADO/MATIZADO/BLOQUEADO) | evidencia que lo prueba (comando + salida, o archivo:línea) | corrección propuesta si aplica`.
Al final: **(a)** la lista de **[V] que refutes** (si hay alguna, es lo más importante de tu entrega y va primero);
**(b)** la lista de **[S] que confirmes** (los que dejan de ser hipótesis); **(c)** los que queden **BLOQUEADOS** y por qué.

---

## 2. ENTREGABLE B — Segunda pasada de auditoría: hallazgos **nuevos**

Objetivo: encontrar lo que la primera pasada **no** miró. **No repitas lo ya reportado** (si lo repites, no cuenta como hallazgo nuevo).
Regla de oro: **la superficie no cubierta está en la lista de abajo**; empieza por ahí y amplía con criterio propio.

**Ya cubierto (no repitas):** wiring del entry real, secretos versionados, RLS/tenancy, simuladores de pago, fail-open de `db.js`,
WebSocket, mocks del frontend Flutter, contrato worker↔backend, caché semántico, higiene de la raíz, CI/CD, migraciones, panel admin.

**Superficie NO auditada — busca aquí:**
1. **Controladores de negocio que la primera pasada no abrió:** `bookingController`, `serviceController`, `productController`,
   `disputeController`, `orderController`, `walletController`, `shopController` y sus pares. Busca la **clase** de bug, no el sitio:
   filtros por `req.user.id` que no se aplican, transiciones de estado irreversibles sin guarda, montos calculados en dos sitios distintos,
   `req.body` usado como fuente de identidad, paginación sin límite, concurrencia sin `FOR UPDATE`.
2. **Ciclo de vida del consentimiento y datos personales:** `consentService`, `biometricConsentGuard`, `AutomaticRetentionService`,
   `retentionNotification`, tickets ARCO (`045_add_arco_suppresion_ticket_type.sql`), borrado y portabilidad. ¿Se cumple lo que la UI promete?
   ¿Hay ruta de supresión efectiva o solo un flag?
3. **Dinero más allá del cobro:** comisiones (`comision_plataforma`, `impuestos_estado`, `pago_neto_prestador`), wallet y retiros,
   conciliación de pagos vs webhooks, redondeo, doble contabilización, y si hay **una sola** fórmula de comisión o varias.
4. **Planillas y cumplimiento:** `pilaCheck`, nómina de trabajadores (`060_add_worker_type_to_usuarios.sql`), obligaciones legales
   (`docs/legal/`, `FISCAL-BOUNDARY.md`) frente a lo que el código realmente hace.
5. **Los dos modelos de tenancy que conviven:** `salones`/`salon_miembros`/`salon_invitaciones` vs `business_profiles`/`memberships`.
   ¿Cuál usa cada pantalla y cada endpoint? ¿Pueden divergir? ¿Qué pasa si un mismo usuario pertenece a los dos?
6. **Borde de los servicios externos:** `yocam.client`, `wompiService`, `youcam`/`openuv`/`fcm` — timeouts, reintentos, circuit breaker,
   idempotencia, qué pasa si el proveedor responde 200 con `success: false`.
7. **Observabilidad real:** ¿hay métricas, trazas y alertas, o solo `console.log`? `traceId`, `ragLogger`, `ragObservability`, Sentry.
   ¿Se puede reconstruir un incidente con lo que se registra hoy? ¿Se registran datos personales?
8. **Rendimiento y BD:** índices faltantes en las consultas más frecuentes, consultas N+1, `SELECT *` en tablas grandes,
   ausencia de límites, tamaño y crecimiento de las tablas de logs, coste de las migraciones en cada arranque.
9. **Frontend más allá de los simuladores:** estado y ciclo de vida (mounted/dispose en todos los `Timer`/`StreamSubscription`),
   accesibilidad (labels, contraste, tamaño táctil), internacionalización, manejo de offline y reintentos, tamaño del bundle y assets.
10. **admin-dashboard más allá de los 404:** contratos de tipos con el backend, validación de formularios, XSS por `dangerouslySetInnerHTML`,
    permisos por acción, y si el panel puede escribir algo que no debería.
11. **Proceso y seguridad operativa:** `docker-compose.prod.yml`, `Dockerfile`s, `railway.yml`, secretos en variables de build,
    puertos expuestos, usuario root en los contenedores, tamaño de imagen, y qué se despliega realmente.
12. **Rutas huérfanas y superficie muerta que la primera pasada no enumeró:** cruza `src/routes/*` con los montajes reales de `index.js`
    y con lo que el frontend/admin llaman de verdad; reporta endpoints declarados y nunca invocados, y viceversa.

### Formato de salida del Entregable B
Un informe con un hallazgo por entrada: `título | severidad (Crítico/Alto/Medio/Bajo) | archivo:línea | evidencia (comando/grep/lectura) |
impacto concreto | corrección propuesta`. Los conteos deben salir de comandos, no de lectura a ojo. Ordena por severidad y cierra con
una tabla de conteo. **Marca explícitamente si alguno es de una clase de bug que la primera pasada no contemplaba** — eso es lo más valioso.
Si un área de las 12 resulta limpia, dilo con la evidencia de que lo está (el "no encontré nada" sin comando no sirve).

---

## 3. Cierre
- Si un hallazgo de la primera pasada te parece exagerado, dilo con números; si te parece **subestimado**, también.
- No propongas un refactor grande como "hallazgo": los hallazgos son defectos verificables con evidencia.
- No escribas ni un archivo. Todo lo que produzcas va en tu respuesta.
