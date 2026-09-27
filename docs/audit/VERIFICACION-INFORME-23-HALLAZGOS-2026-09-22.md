# Verificación del "INFORME DE AUDITORÍA 360° — BACKEND GLOWAPP" (23 hallazgos)

- **Fecha**: 2026-09-22
- **Verificado por**: auditoría independiente sobre `C:\beauty-app` (repo autoritativo), commit `362b590c`
- **Método**: grep/comandos reales contra el árbol; ninguna afirmación de este documento es inferida sin decirlo
- **Etiquetas**: [V] verificado ejecutando · [L] leído en archivo · [X] falso o mal ubicado

## Cuadro de veredictos

| # | Hallazgo del informe | Veredicto | Evidencia real |
|---|---|---|---|
| 1 | Credenciales hardcoded en `db.js:40-41` | **[V] cierto, pero mal clasificado como crítico por sí solo** | `bcrypt.hash('password123')` / `'Password123!'` en `initDefaultUsers()`. **No inserta en Postgres**: solo `memoryUsers.set(...)` (Map en memoria). Confirmado: 0 coincidencias en el dump de producción. El riesgo real aparece **solo** si la app corre en modo memoria (ver #12). |
| 2 | `JWT_SECRET` con fallback peligroso | **[V] cierto, riesgo condicionado** | `jwt.js:4`: el fallback existe **solo** con `NODE_ENV === 'test'`; además exige ≥32 chars y lanza si falta. El vector real es un `NODE_ENV` mal puesto en producción (arranca con un secreto público). |
| 3 | SSL sin verificación (`rejectUnauthorized: false`) | **[V] cierto y más amplio** | `db.js:23` (conexión principal, se activa **siempre** que exista `DATABASE_URL`), `db.js:667` (pool RAG), `database.js:30` (**vivo**: 31 archivos lo requieren), `index.js:278` (tiles OSM, riesgo bajo), `startup/app.js:163` (código muerto). |
| 4 | Clave biométrica derivada de `JWT_SECRET` | **[X] desactualizado — ya corregido (A360 C-11)** | `biometricCryptoService.js:33`: **lanza error** si se intenta derivar de `JWT_SECRET`; usa `BIOMETRIC_KEY` (`:53`). Solo conserva la derivación legada para descifrar datos antiguos. |
| 5 | Falta de validación en queries SQL | **[X] falso positivo** | Consultas con plantilla interpolada (`` query(`…${ ``) = **0**. Sin `archivo:línea` en el informe. |
| 6 | Archivos muertos `.dart` / `.backup` | **[V] cierto** | 8 `.dart` en `backend/` (3 servicios/controladores + 5 modelos), 5 `.backup`/`.bak` (incl. `backend/.env.backup`, `runMigrations.js.backup`, 2 migraciones). `backend/.env.backup` **no está versionado** (`.gitignore:74 *.backup`) ⇒ sin fuga de secretos. |
| 7 | `contextController.dart` huérfano | **[V] cierto** | Un `.dart` en un backend Node no puede estar montado; 0 referencias. |
| 8 | 689 `console.log` | **[X] cifra falsa** | Medido: **283** (incluyendo tests y scripts); `index.js` 38, `authController.js` 19. El problema existe, la magnitud no. |
| 9 | Manejo inconsistente de errores async | **[V] cierto, subestimado** | **94** handlers `async` en `src/routes/*.js` contra **2** con wrapper. Express 4 no captura rechazos async ⇒ excepción no manejada ⇒ **el proceso muere** (Node ≥15). Ya corregido para academia (`src/utils/expressAsync.js`). |
| 10 | Redis corta reconexión tras 3 intentos | **[V] cierto** | `redis.js`: `if (retries >= 3) return new Error(...)`, y el log de error se emite **una sola vez** (`loggedError`). |
| 11 | Dependencia circular potencial | **[?] no verificable** | Sin `archivo:línea` ni ciclo identificado. No accionable. |
| 12 | `ALLOW_MEMORY_FALLBACK` en `pgMemory.js` | **[V] cierto — es el hallazgo central que el informe no supo leer** | `db.js:695`: `memoryFallbackAllowed()` acepta `ALLOW_MEMORY_FALLBACK === 'true'` **sin ninguna guarda de `NODE_ENV`** ⇒ una variable mal puesta en Railway pone toda la API a servir memoria. Combinado con #1, sirve usuarios demo con contraseña conocida. |
| 13 | Interruptores peligrosos en producción | **[~] mixto** | `ALLOW_MEMORY_FALLBACK`: **sin guarda** (peligroso). `ALLOW_PAYMENT_SIMULATOR`: exigido con `NODE_ENV === 'production'` (`bookingController.js:443`, `designsController.js:1578`, `wompiService.js:10`) ⇒ solo daña si alguien lo activa a propósito. `EXPOSE_DEV_OTP`: requiere `NODE_ENV !== 'production'` (`paymentRoutes.js:165`) ⇒ **no puede** afectar producción. |
| 14 | Rate limiting inconsistente | **[V] cierto en el fondo, con matiz** | Sí existe global: `app.use('/api', globalGeneralLimiter)` (`index.js:347`), pero con **1000 req/15 min por IP**; solo **2 de 39** archivos de rutas montan limitador propio. `login`/OTP/registro quedan cubiertos solo por ese techo laxo ⇒ fuerza bruta viable. |
| 15 | Pooling inadecuado en algunos servicios | **[X] falso positivo** | Única aparición de `new Pool(` fuera de `db.js`: **un comentario** en `tenantContext.js:10` documentando el bug ya removido. |
| 16 | RLS no implementado | **[X] falso — y lo importante es otra cosa** | RLS está en 6 migraciones (`034`, `058`, `062`, `065`, `068` + `manual/069`). `068_force_rls_strict_isolation.sql` (251 líneas) documenta y corrige exactamente los 4 defectos reales: propietario exceptuado sin `FORCE`, políticas permisivas OR-eadas, tablas inexistentes, `current_setting` sin `missing_ok`. Lo accionable: `068` **se aplica en el primer boot tras el deploy** ⇒ hay que verificar `relforcerowsecurity` en producción después. |
| 17 | Índices faltantes (email, tenant_id, created_at) | **[X] falso positivo** | 27 migraciones crean índices; `idx_usuarios_email ON usuarios(email)` existe, igual que compuestos por `tenant_id` y `created_at DESC`. |
| 18 | `execFile` sin sanitización (inyección de comandos) | **[X] sobrevalorado** | `corpusAutoIngest.js:58`: `execFile(process.execPath, [INGEST_SCRIPT, filePath], …)` — **sin shell**, primer argumento constante. No hay inyección de comandos; el único llamador es un `require` dinámico (`index.js:1781`), ningún endpoint le pasa input de usuario. |
| 19 | Blacklist de tokens depende de Redis | **[V] cierto — y es FAIL-OPEN** | `auth.js:16`: `if (redisClient && redisClient.isReady)` + `catch` que solo loguea ⇒ **si Redis cae, los tokens revocados siguen siendo válidos**. Nota: el comentario del propio código dice "FAIL-SAFE", que describe lo contrario de lo que hace. |
| 20 | Falta de headers de seguridad HTTP | **[X] falso positivo** | `helmet@^8.3.0` en `package.json:28` y `app.use(helmet({…}))` en `index.js:218` con CSP de directivas explícitas. Matiz legítimo: esa CSP permite `'unsafe-inline'` y `'unsafe-eval'` en `scriptSrc`. |
| 21 | CORS permisivo en `startup/app.js:98-107` | **[X] mal ubicado** | `startup/app.js` es **código muerto: 0 archivos lo requieren**; el entry real es `index.js`, con CORS por lista blanca (`index.js:181-195`). El archivo muerto sí contiene una debilidad real: `origin.endsWith('.up.railway.app')` (`app.js:120`). |
| 22 | URLs hardcodeadas de producción | **[V] cierto y más amplio** | 46 ocurrencias de `railway.app`; **3 en rutas vivas**: `authController.js:468` (link de referidos), `salonController.js:180` (invitación), `emailService.js:7` (checkout en correo). Deben salir de `FRONTEND_URL`. |
| 23 | APIs externas sin fallback / circuit breaker | **[X] desactualizado** | `backend/src/services/circuitBreakerService.js` existe y lo usan ≥6 servicios (`biometric/*`, `biometricTelemetry`, `contextCompressor`, y el worker NVIDIA ya tiene breaker + fallback). |

## Lo que el informe NO vio (y es más importante que varios de sus hallazgos)

1. **El único "crítico" real es la cadena #12 + #1, no #1 solo**: `ALLOW_MEMORY_FALLBACK` sin guarda de entorno pone la API en modo memoria con datos fabricados, y en ese modo existen usuarios demo con contraseña conocida. Separados parecen moderados; juntos son un backdoor de autenticación.
2. **`backend/src/startup/app.js` es código muerto** (0 requirers) y es precisamente donde el informe ubicó dos hallazgos (#3 y #21). Peor: contiene un CORS más laxo y un agente TLS sin verificación. Debe borrarse: si algún día se monta, entra un CORS que acepta **cualquier** subdominio `*.up.railway.app`.
3. **Los 94 handlers async sin wrapper** (#9) son un camino directo a que el proceso muera; el informe los describe como "inconsistencia" y no mide la escala.
4. **`database.js` duplica la configuración de conexión** de `db.js` (dos fuentes de verdad para SSL/pool) y está vivo (31 requirers): el arreglo de TLS debe cubrir ambos, no uno.
5. **La calidad de evidencia del informe es baja**: los fragmentos de código aparecen como dígitos sueltos ("12", "1"), las métricas están infladas (689 vs 283 logs) y varios hallazgos no traen `archivo:línea` (5, 11). Para poder actuar, cada afirmación necesita `archivo:línea` + comando ejecutado.

## Lo que NO debe tocarse (ya está resuelto; tocarlo es regresión)

Derivación de clave biométrica (#4), circuit breakers (#23), índices (#17), helmet/headers (#20), pools (#15), CORS del entry real (#21), `EXPOSE_DEV_OTP` (#13 parcial), y el flujo de pago simulado tal como está guardado.
