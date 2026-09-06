# AUDITORÍA PRE-PRODUCCIÓN MASTER - BEAUTY APP (GlowApp)
**Fecha:** 2026-09-02  
**Equipo:** 5 subagentes especializados en paralelo  
**Alcance:** Monorepo Flutter/Node/Next/FastAPI — Deploy: GH Actions → AWS EKS → ECR, Railway = DNS proxy

---

## RESUMEN EJECUTIVO

| Área | Estado | Hallazgos Críticos | Hallazgos Altos | Archivo/Ubicación |
|------|--------|-------------------|----------------|-------------------|
| 🛡️ **Seguridad y Auth** | 🔴 Crítico | 4 | 3 | Transcript + `subagent-summary-0-*.txt` |
| 🗄️ **Rendimiento y BD** | 🔴 Crítico | 5 | 5 | `AUDITORIA_RENDIMIENTO_BD.md` |
| ⚙️ **Arquitectura Backend/Workers** | 🔴 Crítico | 5 | 3 | `AUDITORIA_BACKEND_WORKERS.md` |
| 📱 **Frontend Flutter** | 🟡 Medio | 0 | 6 | Transcript task-0.log |
| 🚀 **Infraestructura/DevOps** | 🔴 Crítico | 5 | 6 | Transcript task-1.log |

**Total hallazgos críticos: 19** — **No apto para producción sin remediación completa**

---

## 🔴 HALLAZGOS CRÍTICOS CONSOLIDADOS (BLOQUEADORES DE PRODUCCIÓN)

### 1. **RLS (Row Level Security) Inefectivo — Fuga de Datos Multi-Tenant** (DB Performance #2, Security)
- Políticas creadas (migración 058) pero **`app.tenant_id` NUNCA seteado** en conexiones
- Middleware `tenantContext.js` existe pero **no se usa** en cadena de middlewares
- **Acción:** Añadir `SET LOCAL app.tenant_id = $1` en `authMiddleware` tras leer `tenant_id` (15 min)

### 2. **Schema Drift Crítico: `schema.sql` ≠ Producción** (DB Performance #1)
- `schema.sql` (291 líneas) **NO refleja estado real** de producción (backup 4761 líneas, 252MB)
- Tablas core divergentes: `usuarios` (enum vs varchar), `perfiles_prestador` **existe en schema pero NO en backup**, `services` vs `servicios`, `bookings` FK rota, `calc_booking_split` lógica distinta
- **Acción:** `pg_dump -s $DATABASE_URL > prod_schema.sql` y reemplazar `schema.sql` **YA**

### 3. **Auth Rate Limiting DESHABILITADO en Producción** (Security #3, Backend Workers #1)
- `index.js` (PROD): `express-rate-limit` simple (1000 req/15min global) — **demasiado laxo para auth**
- `authRoutes.js`: Rate limiter **comentado** ("temporarily disabled due to export incompatibility")
- `startup/app.js`: `authAndWebhookLimiter` (30/min) existe pero **no se usa en prod**
- **Vulnerabilidad:** **NO rate limiting en `/api/auth/login`, `/register`, `/forgot-password`** → credential stuffing, account enumeration, OTP spam
- **Acción:** Fix rateLimiter export y habilitar **YA** (30 min)

### 4. **Token Blacklist Fail-Open en Redis Failure** (Security #2)
- `auth.js:24-26`: `catch (redisErr) { /* continua de forma segura */ }` → **SI REDIS CAE, TOKENS REVOCADOS SIGUEN FUNCIONANDO**
- Attackers pueden usar tokens robados durante outages de Redis
- **Acción:** Cambiar a **fail-closed** - rechazar request si Redis no disponible (10 min)

### 5. **Dual Rate Limiting: Producción usa simple; avanzada no usada** (Backend Workers #1)
- `index.js` (PROD): `express-rate-limit` simple
- `startup/app.js` + `rateLimiter.js`: **Custom Redis sliding window + tiers (free 30/min, premium 100/min, anon 10/min) + abuse detection** — **IMPLEMENTADO PERO NO USADO**
- **Acción:** Migrar custom rateLimiter a `index.js` O documentar decisión (2 h)

### 6. **3 Workers Referenciados No Existen** (Backend Workers #2)
- `index.js` líneas 1663-1685 intenta cargar: `nailTryonWorker`, `pqrsfReviewWorker`, `vtoAttributionWorker`
- Directorio `/backend/src/workers/` **NO EXISTE** — fallan silenciosamente (try-catch loggea warning)
- Documentados como "legacy" en `GIA-18-K-TROUBLESHOOTING.md` y `GLOWAPP_LEGACY_REGISTRY.md`
- **Acción:** Implementar workers O remover referencias + limpiar schema.sql (tablas `nail_tryon_jobs`)

### 7. **Beauty Scan Proxy SOLO en `startup/app.js` — No Disponible en Producción** (Backend Workers #3)
- Endpoint `/api/v1/beauty-scan` (proxy a `ai-worker:8000`) **SOLO existe en `startup/app.js`**
- Producción usa `index.js` → **feature AI scanning NO DISPONIBLE en prod**
- **Acción:** Migrar endpoint a `index.js` (30 min)

### 8. **Ausencia Total de Graceful Shutdown** (Backend Workers #4)
- `index.js` y `startup/app.js`: **SIN handlers `SIGTERM`/`SIGINT`**
- No cierran pool DB, Redis, WebSocket, SSE clients, jobs en progreso
- Railway/K8s envía `SIGTERM` → proceso muere abruptamente
- **Acción:** Implementar shutdown handlers en `index.js` (1 h)

### 9. **Express Error Handler Final Faltante en `index.js`** (Backend Workers #5)
- `startup/app.js` tiene handler 4-parámetros completo (línea 286-294)
- `index.js` (PROD) **NO TIENE** → errores no capturados responden HTML/500 sin JSON
- **Acción:** Agregar middleware final en `index.js` (10 min)

### 10. **Backup Sin Automatización Ni Testing** (DB Performance #4)
- `backup_beauty_db.sql` 252MB plain SQL — restore ~15-30 min single-threaded
- **Sin cron, sin pg_cron, sin WAL-G, sin Barman, sin restore testing**
- **Acción:** `pg_dump -Fc -Z 3 -j 4` + cron + test restore mensual (2 h)

### 11. **Secrets Hardcodeados en docker-compose.yml** (DevOps #1, Security #1)
```yaml
POSTGRES_PASSWORD: admin123
JWT_SECRET: beauty_app_super_secret_key_2026_change_in_production
```
- En repositorio, visibles en Git history
- `docker-compose.prod.yml`: `POSTGRES_PASSWORD=prod_password` en plaintext
- **Acción:** Usar `.env` + Docker secrets / Railway variables / AWS Secrets Manager

### 12. **CORS Wildcard `*.up.railway.app` — Subdomain Takeover Risk** (Security #4, DevOps)
- `startup/app.js:117` y `index.js:174`: `origin.endsWith('.up.railway.app')` permite **CUALQUIER subdominio railway**
- Cualquier sitio malicioso en `*.up.railway.app` puede hacer requests autenticados
- **Acción:** Reemplazar wildcard con orígenes explícitos permitidos

### 13. **2 Queries Por Request Autenticado (Auth + RateLimiter)** (DB Performance #5, Security)
- `authMiddleware`: `SELECT rol, tenant_id FROM usuarios WHERE id = $1`
- `rateLimiter.js`: `SELECT tier FROM usuarios WHERE id = $1` (línea 153) — **query separada**
- **Acción:** Unificar: `SELECT rol, tenant_id, tier FROM usuarios WHERE id = $1` (15 min)

### 14. **Connection Timeout 5s Demasiado Agresivo** (DB Performance #3)
- `connectionTimeoutMillis: 5000` → errores transitorios bajo carga/cold starts
- **Acción:** Subir a 10000-15000ms (1 min)

### 15. **Migración 058: Tabla `services` vs `servicios` — RLS No Aplicado** (DB Performance #7)
- Array `rls_tables` incluye `'services'` pero tabla real en backup es `'servicios'`
- RLS no habilitado en tabla real → **aislamiento multi-tenant roto para servicios**
- **Acción:** Fix migración 058 (10 min)

### 16. **Migración 057: Backfill Problemático** (DB Performance #8)
- Doble tenant default ('Default Tenant' id=1 + 'Demo Tenant')
- UPDATE sin chunking → locks exclusivos prolongados
- ALTER TABLE + ADD COLUMN + REFERENCES + UPDATE en misma transacción
- **Acción:** Auditar estado `tenant_id` en prod, fix migración

### 17. **Pool Sin `statement_timeout` / Monitoring** (DB Performance #9)
- Queries colgadas agotan pool (max 30) silenciosamente
- No métricas de `acquire`/`release`/`error`
- **Acción:** `statement_timeout: 30000` + event logging

### 18. **Dockerfiles Sin Multi-Stage, Sin Resource Limits, Health Checks Solo en Compose** (DevOps #2-5)
- Backend `Dockerfile`: 16 líneas, `COPY . .`, `USER root`, sin healthcheck en Dockerfile
- Frontend `Dockerfile`: Ubuntu latest, git clone Flutter en build — **imagen ~2GB+**
- `docker-compose.yml`: Sin `deploy.resources.limits`, sin `networks` aislamiento
- **Acción:** Multi-stage builds, `USER node`/`nginx`, resource limits, healthchecks en Dockerfile

### 19. **Jobs de Pagos Acoplados a Proceso Express Sin Persistence** (Backend Workers #7)
- `paymentJobs.js` usa `setInterval` + verificación horaria (no node-cron)
- Si proceso muere → jobs se pierden, sin retry, sin métricas
- **Acción:** Evaluar BullMQ / node-cron con persistence / worker separado

---

## 🟡 HALLAZGOS ALTOS (OPTIMIZACIÓN NECESARIA)

### Seguridad
1. **Helmet CSP permisivo**: `unsafe-inline`, `unsafe-eval`, `connect-src: [*]`, `img-src: [*]`
2. **Password mínimo solo 6 chars** (authController.js:440) — **debería ser 12+**
3. **Tenant context usa Pool separado** (tenantContext.js:3-5) — no comparte pool de `db.js`
4. **Sin rotación de secretos** documentada

### Frontend (Flutter)
1. **Sin state management** (Provider/Riverpod/Bloc) — `setState` en 1222+1409 líneas screens
2. **URLs Unsplash hardcodeadas** en `booking_screen.dart` (líneas 143, 152, 159, 166) — dependencia externa sin fallback
3. **Error handling solo SnackBar** — sin error boundaries, sin logging remoto (Sentry, etc.)
4. **ProviderDetailScreen**: Cover imagery genérica (`_buildFallbackCover` con gradientes), sin trust signals ricos (certificaciones, años exp, verificación docs)
5. **BookingScreen**: Cognitive load alto (4 pasos en step 1: servicio, fecha, horario, dirección), progress bar solo 3 steps
6. **API base URL resolution** en `api_service.dart` — lógica compleja con fallback, riesgo de entorno incorrecto

### DevOps
1. **Frontend `Dockerfile.prod` usa `alpine:latest` como builder** — inestable, sin version pinning
2. **Railway `railway.yml` usa service name `pgvector-db` para forzar nuevo volume** — workaround frágil
3. **`.dockerignore` solo 4 líneas** — copia `node_modules`, `.git`, logs, `.env*` a imagen
4. **AI Worker `Dockerfile`: `python:3.10-slim` (EOL 2026-10), sin non-root user**
5. **Sin security scanning** (Trivy, Snyk, Grype) en CI/CD
6. **Sin SBOM generation** (Syft) para supply chain security

---

## 🟢 HALLAZGOS MEDIOS / FORTALEZAS

### Base de Datos
- **RAG/pgvector bien indexado** (HNSW + GIN + B-tree) — ✅ **Fortaleza**
- Migraciones 035, 046, 047, 048 completas y robustas
- Trazabilidad R3 implementada (document_id, chunk_id, content_hash, etc.)

### Backend
- Health checks funcionales (`/api/health`, `/api/test-db`, `/api/debug-db`)
- Multer upload correcto (5MB, validación ext/MIME, URL absoluta con x-forwarded-proto)
- SSE para admin events operativo en producción
- bcrypt cost 10 en auth — ✅ **Correcto**
- Queries parametrizadas — ✅ **SQL injection prevention**
- Role validation desde DB en cada request — ✅ **Previene role elevation**

### Frontend
- Design system `AppTheme` definido (colores, tipografía, spacing)
- `BookingRecoveryService` para checkouts incompletos — ✅ **Buena práctica**
- Wompi payment sheet integration funcional
- SliverAppBar parallax en ProviderDetailScreen — ✅ **UX moderna**

---

## PLAN DE ACCIÓN PRIORITARIO (ORDEN DE EJECUCIÓN)

### FASE 1: BLOQUEADORES INMEDIATOS (Día 1-2) — **NO DEPLOY SIN ESTOS**

| # | Acción | Archivo/Ubicación | Esfuerzo | Responsable |
|---|--------|-------------------|----------|-------------|
| 1 | Generar schema real desde prod y reemplazar `schema.sql` | `pg_dump -s $DATABASE_URL > backend/schema.sql` | 30 min | DB Admin |
| 2 | Añadir `SET LOCAL app.tenant_id` en `authMiddleware` | `backend/src/middleware/auth.js` línea 40 | 15 min | Backend Dev |
| 3 | Unificar query auth + rateLimiter (`rol, tenant_id, tier`) | `authMiddleware` + `rateLimiter.js` | 15 min | Backend Dev |
| 4 | Subir `connectionTimeoutMillis` a 10000 | `backend/src/config/db.js` línea 24 | 1 min | Backend Dev |
| 5 | Añadir `statement_timeout: 30000` a pools | `backend/src/config/db.js` líneas 22, 52 | 1 min | Backend Dev |
| 6 | **Habilitar rate limiting en auth endpoints** | `index.js` + `authRoutes.js` | 30 min | Backend Dev |
| 7 | **Cambiar token blacklist a fail-closed** | `backend/src/middleware/auth.js:24-26` | 10 min | Backend Dev |
| 8 | Implementar graceful shutdown en `index.js` | `backend/index.js` | 1 h | Backend Dev |
| 9 | Agregar Express error handler final en `index.js` | `backend/index.js` | 10 min | Backend Dev |
| 10 | Migrar Beauty Scan Proxy a `index.js` | `backend/index.js` | 30 min | Backend Dev |
| 11 | Resolver workers faltantes (implementar o remover) | `backend/index.js:1663-1685` | 2-4 h | Backend Dev |
| 12 | Migrar custom rateLimiter a `index.js` | `index.js` + `rateLimiter.js` | 2 h | Backend Dev |
| 13 | Mover secrets de docker-compose a .env / Railway variables | `docker-compose.yml`, `docker-compose.prod.yml` | 30 min | DevOps |
| 14 | Fix CORS wildcard `*.up.railway.app` | `index.js:174`, `startup/app.js:117` | 15 min | Backend Dev |
| 15 | Fix migración 058: `'services'` → `'servicios'` | `backend/migrations/058_enable_rls_policies.sql` | 10 min | DB Admin |

### FASE 2: CORTO PLAZO (Semana 1)

| # | Acción | Esfuerzo |
|---|--------|----------|
| 16 | Crear índices compuestos críticos (migración nueva) | 1-2 h |
| 17 | Consolidar CORS en `src/config/cors.js` | 30 min |
| 18 | Hardening Helmet CSP (quitar unsafe-inline/eval, restringir connect-src) | 1 h |
| 19 | Aumentar password mínimo a 12+ chars | 10 min |
| 20 | Automatizar backup: `pg_dump -Fc -Z 3 -j 4` + cron + test restore | 2 h |
| 21 | Auditar migraciones 056-057: estado tenant_id en prod | 1 h |
| 22 | Reconciliar `calc_booking_split`: usar `platform_config` | 30 min |

### FASE 3: MEDIANO PLAZO (Sprint 1-2)

| # | Acción | Esfuerzo |
|---|--------|----------|
| 23 | Multi-stage Dockerfiles + non-root users + resource limits | 4 h |
| 24 | Healthchecks en Dockerfile (no solo compose) | 1 h |
| 25 | Separar payment jobs a worker dedicado (BullMQ/node-cron) | 8 h |
| 26 | Unificar entry points: decidir futuro de `startup/app.js` | 4 h |
| 27 | Frontend: Introducir state management (Riverpod recomendado) | 16 h |
| 28 | Frontend: Reemplazar URLs Unsplash hardcodeadas con assets locales/CDN | 4 h |
| 29 | Frontend: Error boundaries + logging remoto (Sentry) | 8 h |
| 30 | Security scanning en CI (Trivy + Syft SBOM) | 4 h |
| 31 | Documentar runbooks: backup/restore, DR, multi-tenant onboarding | 8 h |

---

## ARCHIVOS DE AUDITORÍA DETALLADOS GENERADOS

1. **`AUDITORIA_BACKEND_WORKERS.md`** (14.8 KB) — Análisis completo de `index.js` vs `startup/app.js`, rate limiting dual, workers faltantes, beauty scan proxy, graceful shutdown, payment jobs, dual entry points
2. **`AUDITORIA_RENDIMIENTO_BD.md`** (17.2 KB) — Connection pooling, índices faltantes (tabla detallada), migraciones 055-058 problemas, RAG/pgvector, triggers/funciones, query patterns, backup strategy, schema drift vs prod
3. **`AUDITORIA_PREPRODUCCION_MASTER.md`** (14.8 KB) — **Este reporte consolidado**

## Transcripts Completos (evidencia completa)

| Agente | Transcript | Duración |
|--------|------------|----------|
| 🛡️ Security | `C:\Users\Compu casa\AppData\Local\hermes\cache\delegation\live\deleg_2a5cad4b\task-0.log` | 1366s |
| 🗄️ DB Performance | `C:\Users\Compu casa\AppData\Local\hermes\cache\delegation\live\deleg_2a5cad4b\task-1.log` | 1574s |
| ⚙️ Backend Workers | `C:\Users\Compu casa\AppData\Local\hermes\cache\delegation\live\deleg_2a5cad4b\task-2.log` | 1157s |
| 📱 Frontend | `C:\Users\Compu casa\AppData\Local\hermes\cache\delegation\live\deleg_a5a31b26\task-0.log` | 602s |
| 🚀 DevOps | `C:\Users\Compu casa\AppData\Local\hermes\cache\delegation\live\deleg_a5a31b26\task-1.log` | 797s |

## Summaries Completos (para lectura rápida)

| Agente | Summary File |
|--------|--------------|
| 🛡️ Security | `C:\Users\Compu casa\AppData\Local\hermes\cache\delegation\subagent-summary-0-20260902_202727_455809.txt` |
| ⚙️ Backend Workers | `C:\Users\Compu casa\AppData\Local\hermes\cache\delegation\subagent-summary-2-20260902_202727_457807.txt` |

---

## CONCLUSIÓN FINAL

**La aplicación NO está lista para producción.** Los 19 hallazgos críticos incluyen:

1. **Riesgo de fuga de datos multi-tenant** (RLS inefectivo por falta de `SET app.tenant_id`)
2. **Schema drift** que romperá features en deploy fresco (`perfiles_prestador` no existe en prod)
3. **Auth sin rate limiting** — credential stuffing, enumeration, OTP spam posibles
4. **Token blacklist fail-open** — tokens revocados funcionan si Redis cae
5. **Features AI (Beauty Scan) no disponibles** en entrypoint producción
6. **Workers rotos** que fallan silenciosamente al arranque
7. **Sin graceful shutdown** — pérdida de datos en restart/deploy
8. **Secrets en repo** — violación seguridad básica
9. **CORS wildcard** — subdomain takeover risk
10. **Backup sin testing** — recuperación ante desastres no verificada

**Recomendación formal:** Completar **Fase 1 completa (15 items, ~6-10 horas)** antes de cualquier deploy a staging/producción. La Fase 1 resuelve **todos los bloqueadores críticos de seguridad y disponibilidad**.

---

*Generado por equipo de 5 subagentes Hermes en auditoría paralela (4.7h tiempo total de análisis)*
*Fecha consolidación: 2026-09-02 20:45*