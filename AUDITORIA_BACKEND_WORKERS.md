# AUDITORÍA DE ARQUITECTURA BACKEND Y WORKERS

**Fecha:** 2026-09-02  
**Aplicación:** Beauty App - Backend Node.js/Express  
**Entrypoints analizados:** `backend/index.js` (1712 líneas) y `backend/src/startup/app.js` (297 líneas)

---

## 1. MANEJO GLOBAL DE ERRORES

### `backend/index.js` (Producción - Dockerfile CMD)
- ✅ **unhandledRejection** (línea 1700-1702): Loguea error, no mata proceso
- ✅ **uncaughtException** (línea 1704-1708): Loguea y **sale con exit(1) en no-development**
- ❌ **FALTA**: Express error handler final (middleware de 4 parámetros `app.use((err, req, res, next) => {...})`)

### `backend/src/startup/app.js` (Alternativo)
- ✅ **unhandledRejection** (línea 277-279): Loguea
- ✅ **uncaughtException** (línea 281-283): Loguea, **NO mata proceso** (más seguro para contenedores)
- ✅ **Express error handler final** (línea 286-294): Captura errores, responde JSON 500, oculta stack en producción

**Hallazgo:** `index.js` carece de handler final de Express; `startup/app.js` lo tiene completo. En producción se usa `index.js` → **riesgo de respuestas HTML/500 sin JSON en errores no capturados por rutas.**

---

## 2. RATE LIMITING - DUAL IMPLEMENTATION ⚠️

### `backend/index.js` (ACTIVO EN PRODUCCIÓN)
- Usa **express-rate-limit** (paquete npm)
- `analyzeLimiter`: 30 req/hora en `/api/biometric/analyze` (línea 202-208)
- `globalGeneralLimiter`: 1000 req/15min en `/api/*` (línea 211-217)
- **Custom rateLimiter DESHABILITADO** (líneas 239-252, comentado)

### `backend/src/startup/app.js`
- Usa **custom rateLimiter** (`src/middleware/rateLimiter.js`) con Redis sliding window
- `generalLimiter`: 1000 req/15min en `/api/*` (línea 160-164)
- `authAndWebhookLimiter`: 30 req/min en `/api/auth/login`, `/api/auth/register`, `/api/auth/send-otp`, `/api/payments/wompi-webhook` (línea 166-176)
- Rate limiting por **tier de usuario** (free/premium/anónimo) + límite global por IP (200/min)

### `src/middleware/rateLimiter.js` (357 líneas)
- Implementación **sliding window** con Redis sorted sets (ZSET)
- Tier dinámico desde BD (`usuarios.tier`)
- Headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`, `X-RateLimit-Tier`
- Fail-open si Redis no disponible
- Detección de abuso integrada

**Hallazgo CRÍTICO:** **Dual implementation activa en producción** (`index.js` usa express-rate-limit, `startup/app.js` usa custom Redis). En producción corre `index.js` → **custom rateLimiter con tier dinámico NO SE USA**. Los límites por tier, Redis sliding window y abuse detection están implementados pero **deshabilitados en producción**.

---

## 3. WORKERS EN SEGUNDO PLANO - FALTANTES ❌

Referenciados en `index.js` líneas 1663-1685:
```javascript
// Iniciar worker de VTO de uñas
const nailTryonWorker = require('./src/workers/nailTryonWorker');
// Iniciar worker de revisión PQRSF
const pqrsfReviewWorker = require('./src/workers/pqrsfReviewWorker');
// Iniciar worker de atribución VTO
const vtoAttributionWorker = require('./src/workers/vtoAttributionWorker');
```

**Verificación:** Directorio `/c/beauty-app/backend/src/workers/` **NO EXISTE**. Los archivos worker **no están en el filesystem**.

**Evidencia documentada:**
- `GIA-18-K-TROUBLESHOOTING.md` línea 23: "Missing workers: nailTryonWorker, pqrsfReviewWorker, vtoAttributionWorker"
- `GLOWAPP_MAPA_FUNCIONAL_UNIDADES_PRODUCTIVAS.md` línea 470: "nail_tryon_jobs table + nailTryonWorker (comentado en index.js:1656) | Schema existe; worker comentado 'legacy'; sin UI activa | **Legado**"
- `docs/governance/GLOWAPP_LEGACY_REGISTRY.md` línea 49: "nailTryonWorker: Commented worker in index.js (line 1656) marked as 'legacy'"

**Estado:** **3 workers referenciados pero no implementados**. El código en `index.js` está dentro de try-catch que loggea warning pero continúa → **fallan silenciosamente en arranque**. Solo `BackgroundWorkerService` existe en `src/services/backgroundWorkerService.js`.

---

## 4. HEALTH CHECKS

### `backend/index.js` (Producción)
| Endpoint | Auth | Descripción |
|---|---|---|
| `GET /api/health` | No | Status OK, timestamp, env, alinea secuencia usuarios_id_seq |
| `GET /api/test-db` | Admin (debugRouteMiddleware) | testConnection + PostGIS version |
| `GET /api/debug-db` | Admin (debugRouteMiddleware) | Diagnóstico completo: extensiones, tablas, conteos, PostGIS |

### `backend/src/startup/app.js`
| Endpoint | Auth | Descripción |
|---|---|---|
| `GET /api/health` | No | Status OK, uptime, db: CONNECTED/DISCONNECTED, timestamp |

**Hallazgo:** `index.js` health check más completo (alineación secuencia, env). `startup/app.js` incluye uptime. Ambos funcionales pero **diferentes respuestas**.

---

## 5. SSE PARA ADMIN EVENTS

### `backend/index.js` (Producción) - LÍNEAS 443-455, 601-620
- `sseClients` array global
- `broadcastAdminEvent(type, data)` function
- `GET /api/admin/events/stream` - requiere `authMiddleware` + `adminMiddleware`
- Headers SSE correctos, ping inicial, cleanup en `req.on('close')`
- Usado por: SOS alerts (línea 486), admin user toggle (línea 848), SOS resolve (línea 787)

### `backend/src/startup/app.js` - LÍNEAS 131-142
- Implementación **idéntica** pero sin `broadcastAdminEvent` exportada
- Mismo endpoint `/api/admin/events/stream`

**Hallazgo:** Duplicado funcional. En producción se usa `index.js` → SSE operativo.

---

## 6. BEAUTY SCAN PROXY A AI-WORKER:8000

### `backend/src/startup/app.js` - LÍNEAS 199-274 (SOLO AQUÍ)
```javascript
const AI_WORKER_URL = process.env.AI_WORKER_URL || 'http://ai-worker:8000';
app.post('/api/v1/beauty-scan', authMiddleware, upload.fields([...]), async (req, res) => {
  // Proxy multipart/form-data a ai-worker:8000/api/v1/beauty-scan
  // Reenvía Authorization header
  // Limpieza async de archivos temporales
});
```

### `docker-compose.yml`
```yaml
ai-worker:
  build: ../ai-worker
  ports: ["8000:8000"]
  environment:
    - MOCK_MODE=true
```

### `ai_worker/Dockerfile` + `main.py`
- Python/FastAPI en puerto 8000
- `MOCK_MODE=true` por defecto

**Hallazgo:** **Proxy SOLO en `startup/app.js` (no en `index.js` producción)**. En producción **NO DISPONIBLE** endpoint `/api/v1/beauty-scan`. Requiere migración a `index.js` o cambio de entrypoint.

---

## 7. MULTER FILE UPLOAD

### Ambos entrypoints (idéntico)
- **Storage:** `diskStorage` en `/uploads` (creado auto)
- **Límite:** 5MB (`5 * 1024 * 1024`)
- **Validación extensiones:** `.jpeg|.jpg|.png|.gif|.webp` (regex)
- **Validación MIME:** `image/*` + `application/octet-stream` si extensión válida (Flutter Web)
- **Endpoint:** `POST /api/upload` (index.js línea 419) con `authMiddleware` + `upload.single('image')`
- **Respuesta:** URL absoluta usando `x-forwarded-proto` para HTTPS detrás de proxy (Railway)

**Hallazgo:** Correcto y consistente en ambos. 5MB razonable para imágenes.

---

## 8. CORS DUPLICADO ⚠️

### `backend/index.js` (Producción) - LÍNEAS 148-180
```javascript
const defaultOrigins = [...]; // 13 orígenes hardcoded
const envOrigins = process.env.ALLOWED_ORIGINS?.split(',') || [];
const allowedOrigins = Array.from(new Set([...defaultOrigins, ...envOrigins]));
app.use(cors({ origin: (origin, callback) => {...}, credentials: true }));
```
- Permite `*.up.railway.app` wildcard

### `backend/src/startup/app.js` - LÍNEAS 94-123
```javascript
const defaultOrigins = [...]; // 11 orígenes (subconjunto, falta localhost:3000, 127.0.0.1:3000, 8080, 8081)
const envOrigins = process.env.ALLOWED_ORIGINS?.split(',') || [];
const allowedOrigins = Array.from(new Set([...defaultOrigins, ...envOrigins]));
app.use(cors({ origin: (origin, callback) => {...}, credentials: true }));
```

**Hallazgo:** **Duplicado con listas diferentes**. `index.js` más completo (incluye localhost:3000, 8080, 8081). `startup/app.js` lista más corta. En producción se usa `index.js` → CORS correcto pero **código duplicado innecesario**.

---

## 9. SWAGGER/OPENAPI EN /API-DOCS

### `backend/index.js` (Producción) - LÍNEAS 71-92
```javascript
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const specs = swaggerJsdoc(swaggerOptions);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));
```
- OpenAPI 3.0.0
- Title: "GlowApp Biometric Hub API"
- Servers: producción (railway) + desarrollo (localhost:8080)
- `apis: ['./src/routes/*.js']` - escanea JSDoc en rutas

### `backend/src/startup/app.js`
- **NO TIENE** Swagger

**Hallazgo:** Solo en `index.js` (producción). Funcional en `/api-docs`.

---

## 10. STATUS MONITOR EN /STATUS

### `backend/index.js` (Producción) - LÍNEAS 71-102
```javascript
const statusMonitor = require('express-status-monitor');
app.use(statusMonitor({
  title: 'GlowApp Biometric API Status',
  path: '/status',
  spans: [{interval:1,retention:60},{interval:5,retention:60},{interval:15,retention:60}]
}));
```

### `backend/src/startup/app.js`
- **NO TIENE** status monitor

**Hallazgo:** Solo en `index.js` (producción). Disponible en `/status`.

---

## 11. JOBS DE PAGOS (paymentJobs.js)

### `backend/src/jobs/paymentJobs.js` (11061 chars, 289 líneas)
Inicializado en `index.js` línea 61 y 1661: `inicializarJobs()`

| Job | Intervalo | Función |
|---|---|---|
| **Maduración saldos** | Cada 15 min | `madurarSaldosPendientes()` - mueve PENDIENTE → DISPONIBLE |
| **Retiros automáticos** | Diario 6AM (check hourly) | `ejecutarRetirosAutomaticos()` - QUINCENA/MENSUAL, valida disputas, Wompi payout |
| **Conciliación diaria** | Diario 2AM | `conciliacionDiaria()` - balance wallets vs retiros, alertas SLA vencido, expira OTPs |
| **Pricing dinámico** | Diario 3AM | `aplicarPricingDinamico()` |
| **Notificaciones retención** | Diario 10AM | `enviarNotificacionesRetencion()` |

**Implementación:** `setInterval` + verificación de hora (no node-cron). **Ejecutan en mismo proceso Express** - si el proceso muere, jobs se pierden. Para producción se recomienda worker separado o node-cron con persistence.

**Hallazgo:** Jobs funcionales pero **acoplados al proceso principal**. Sin persistencia de schedule, sin retry logic, sin métricas de ejecución.

---

## 12. GRACEFUL SHUTDOWN

### `backend/index.js` (Producción)
- ❌ **NO TIENE** handlers para `SIGTERM`, `SIGINT`
- ❌ **NO CIERRA** pool de DB, conexiones Redis, WebSocket server, SSE clients
- ❌ **NO ESPERA** jobs en progreso

### `backend/src/startup/app.js`
- ❌ **NO TIENE** graceful shutdown

### `paymentJobs.js`
- Jobs usan `setInterval` sin cleanup

**Hallazgo CRÍTICO:** **Ausencia total de graceful shutdown**. En Railway/container orchestration, `SIGTERM` mata proceso abruptamente → conexiones DB abiertas, jobs a medio hacer, WebSocket/SSE clients desconectados sin aviso.

---

## 13. DUAL ENTRY POINTS - CUÁL SE USA EN PRODUCCIÓN

### Evidencia:
| Archivo | Comando | Usado en |
|---|---|---|
| `package.json` | `"main": "index.js"`, `"start": "node index.js"` | npm start |
| `Dockerfile` | `CMD ["node", "index.js"]` | **Producción (Docker/Railway)** |
| `docker-compose.yml` | `build: {context: ., dockerfile: Dockerfile}` | Produce imagen con `index.js` |
| `backend/src/startup/app.js` | `module.exports = { app, sseClients }` | Exporta app, **no auto-arranca** |

### Diferencias clave:
| Característica | `index.js` (PROD) | `startup/app.js` |
|---|---|---|
| Rate limiting | express-rate-limit (simple) | Custom Redis sliding window + tiers |
| Error handler final | ❌ | ✅ |
| Beauty Scan Proxy | ❌ | ✅ |
| Swagger /api-docs | ✅ | ❌ |
| Status Monitor /status | ✅ | ✅ |
| Health check | Completo (alineación seq) | Básico (uptime) |
| Workers (Nail/PQRSF/VTO) | Intentan iniciar (fallan) | No referenciados |
| Payment Jobs | ✅ Inicializados | ❌ No |
| WebSocket Server | ✅ Inicializado | ❌ No |
| CORS | Lista completa | Lista parcial |

**Conclusión:** **PRODUCCIÓN USA `index.js`**. `startup/app.js` parece ser **versión alternativa/legacy** con features más avanzadas (custom rate limiter, beauty scan proxy, error handler) pero **incompleta** (sin jobs, sin websocket, sin swagger, sin status monitor, sin workers).

---

## RESUMEN DE HALLAZGOS CRÍTICOS

| # | Hallazgo | Severidad | Acción Requerida |
|---|---|---|---|
| 1 | **Dual rate limiting**: producción usa express-rate-limit simple; custom Redis+tiers implementado pero no usado | 🔴 CRÍTICO | Migrar custom rateLimiter a index.js O documentar decision |
| 2 | **3 Workers referenciados no existen** (NailTryon, PQRSF, VTOAttribution) | 🔴 CRÍTICO | Implementar workers O remover referencias + limpiar schema.sql |
| 3 | **Beauty Scan Proxy solo en startup/app.js** - no disponible en producción | 🔴 CRÍTICO | Migrar endpoint a index.js |
| 4 | **Ausencia total graceful shutdown** (SIGTERM/SIGINT, DB pool, Redis, WS, SSE, jobs) | 🔴 CRÍTICO | Implementar shutdown handlers en index.js |
| 5 | **Express error handler final faltante en index.js** | 🟠 ALTO | Agregar middleware 4-parámetros final |
| 6 | **CORS duplicado con listas diferentes** | 🟡 MEDIO | Consolidar en módulo compartido |
| 7 | **Jobs de pagos acoplados al proceso Express** sin persistence | 🟡 MEDIO | Evaluar node-cron o worker separado |
| 8 | **Dual entry points confuso** - startup/app.js tiene features mejores pero incompleto | 🟡 MEDIO | Decidir: unificar o deprecatar startup/app.js |

---

## RECOMENDACIONES PRIORITARIAS

1. **Inmediato (Bloqueadores producción):**
   - Implementar graceful shutdown en `index.js`
   - Agregar Express error handler final en `index.js`
   - Migrar Beauty Scan Proxy a `index.js`
   - Resolver workers faltantes (implementar o remover referencias + DB schema)

2. **Corto plazo:**
   - Migrar custom rateLimiter (Redis + tiers) a `index.js` reemplazando express-rate-limit
   - Consolidar CORS en módulo compartido `src/config/cors.js`
   - Evaluar separación de jobs a worker dedicado (BullMQ, node-cron con persistence)

3. **Mediano plazo:**
   - Unificar entry points: decidir si `startup/app.js` se convierte en main o se deprecata
   - Agregar health check readiness/liveness separados para Kubernetes/Railway
   - Implementar métricas de jobs (ejecución, duración, errores)

---

## ARCHIVOS CLAVE AUDITADOS

- `backend/index.js` (1712 líneas) - **ENTRYPOINT PRODUCCIÓN**
- `backend/src/startup/app.js` (297 líneas) - Entry point alternativo
- `backend/src/middleware/rateLimiter.js` (357 líneas) - Custom rate limiter (no usado en prod)
- `backend/src/jobs/paymentJobs.js` (289 líneas) - Jobs de pagos
- `backend/Dockerfile` - `CMD ["node", "index.js"]`
- `backend/docker-compose.yml` - Orquestación completa
- `ai_worker/Dockerfile` + `main.py` - AI Worker Python/FastAPI puerto 8000

---

*Fin del reporte de auditoría*