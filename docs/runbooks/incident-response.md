# Runbooks - GlowApp Incident Response

## Índice
1. [High Error Rate](#1-high-error-rate)
2. [High Latency](#2-high-latency)
3. [DB Pool Exhausted](#3-db-pool-exhausted)
4. [Firebase Quota Exceeded](#4-firebase-quota-exceeded)
5. [Deploy Rollback](#5-deploy-rollback)
6. [Auth Outage](#6-auth-outage)
7. [RAG Pipeline Failure](#7-rag-pipeline-failure)

---

## 1. High Error Rate

**Alerta**: `HighErrorRate` — Error rate (5xx) > 1% por 2 min

### Síntomas
- Usuarios reportan errores 500/502/503
- Dashboard System Health: gauge "Error Rate" en rojo
- Logs muestran stack traces en backend

### Diagnóstico Rápido (2 min)
```bash
# 1. Ver logs recientes en Loki (Grafana Explore)
{app="glowapp-backend"} |= "error" | json | level="error"

# 2. Verificar qué endpoints fallan
sum by (route) (rate(http_requests_total{status_code=~"5.."}[5m]))

# 3. Verificar dependencias externas
sum by (service) (rate(external_api_calls_total{status="error"}[5m]))
```

### Causas Comunes
| Causa | Indicador | Acción |
|-------|-----------|--------|
| DB connection pool agotado | `DBPoolExhausted` alert también disparada | Reiniciar backend, revisar queries lentas |
| Firebase Auth caído | `firebase_auth_operations{result="error"}` spike | Verificar status Firebase, usar fallback |
| Stripe/Wompi timeout | `external_api_calls_total{service="stripe",status="error"}` | Reintentar con backoff, contactar soporte |
| Migración BD fallida | Logs muestran error migración | Rollback migración, revisar `schema_migrations` |

### Resolución
1. **Si es DB**: `docker restart glowapp-backend` (Railway: redeploy)
2. **Si es Firebase**: Verificar [Firebase Status](https://status.firebase.google.com/)
3. **Si es Stripe/Wompi**: Revisar dashboard del proveedor, activar modo degradado
4. **Si es código**: Revertir último deploy (`git revert` + push a main)

### Post-Incidente
- Añadir test de regresión para endpoint afectado
- Actualizar alertas si umbral fue incorrecto
- Documentar en postmortem

---

## 2. High Latency

**Alerta**: `HighLatency` — P95 > 2s por 5 min

### Síntomas
- Usuarios reportan lentitud
- Dashboard: gauge "Latency P95" en amarillo/rojo
- Timeouts en frontend

### Diagnóstico Rápido
```bash
# 1. Identificar endpoints lentos
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, route, app_audience))

# 2. Verificar DB queries lentas
histogram_quantile(0.95, sum(rate(db_query_duration_seconds_bucket[5m])) by (le, operation, table))

# 3. Verificar APIs externas
histogram_quantile(0.95, sum(rate(external_api_duration_seconds_bucket[5m])) by (le, service))
```

### Causas Comunes
| Causa | Indicador | Acción |
|-------|-----------|--------|
| Query BD sin índice | `db_query_duration_seconds` alta en tabla específica | Añadir índice, `EXPLAIN ANALYZE` |
| Firebase cold start | `external_api_duration_seconds{service="firebase"}` spike | Pre-calentar funciones, aumentar instancias mínimas |
| RAG pipeline lento | `rag_query_duration_seconds` > 5s | Revisar embeddings, reducir chunks |
| Event loop bloqueado | `nodejs_eventloop_lag_seconds` > 0.1s | Mover CPU-intensive a worker threads |

### Resolución
1. **Query BD**: Añadir índice → deploy hotfix
2. **Firebase**: Aumentar `minInstances` en Cloud Functions
3. **RAG**: Reducir `RAG_SIMILARITY_THRESHOLD` o `max_chunks`
4. **CPU**: Offload a Bull queue + workers

---

## 3. DB Pool Exhausted

**Alerta**: `DBPoolExhausted` — Pool usage > 80% por 5 min

### Síntomas
- Requests se quedan colgados
- Errores `Connection pool exhausted`
- Latencia crece exponencialmente

### Diagnóstico
```bash
# Ver conexiones activas
db_pool_connections{state="active"}

# Ver queries que no liberan conexión
# Buscar en logs: "connection leaked" o queries > 30s
```

### Resolución Inmediata
1. Reiniciar backend (libera pool)
2. Aumentar `DB_POOL_MAX` temporalmente (ej: 20 → 50)
3. Identificar query fugadora: revisar `db_query_duration_seconds` con status=running

### Fix Permanente
- Auditar todos los `pool.query()` → asegurar `try/finally` con `client.release()`
- Añadir timeout a queries: `statement_timeout = '30s'`
- Implementar circuit breaker para DB

---

## 4. Firebase Quota Exceeded

**Alerta**: `FirebaseQuotaExceeded` (custom) — Daily quota > 90%

### Síntomas
- Errores `QUOTA_EXCEEDED` en Auth/Firestore/Storage
- Usuarios no pueden login/registrar

### Diagnóstico
```bash
# Ver uso en Firebase Console > Usage
# O via API:
gcloud firebase projects get-project --project=glowapp-client
```

### Límites Comunes (Spark Plan)
| Servicio | Límite Diario |
|----------|---------------|
| Auth sign-ins | 50,000 |
| Firestore reads | 50,000 |
| Firestore writes | 20,000 |
| Storage downloads | 1 GB |

### Resolución
1. **Corto plazo**: Upgrade a Blaze Plan (pay-as-you-go)
2. **Mediano**: Optimizar queries Firestore (caché, reducir reads)
3. **Auth**: Implementar rate limiting en login endpoints

---

## 5. Deploy Rollback

**Cuándo**: Deploy roto en producción (errores 5xx inmediatos, health check falla)

### Procedimiento (1 min)
```bash
# Opción A: Git revert (recomendado)
git checkout main
git log --oneline -5  # identificar commit malo
git revert <bad-commit-sha>
git push origin main  # dispara pipeline → rollback automático

# Opción B: Railway rollback (UI)
# Railway Dashboard > Service > Deployments > Rollback to previous
```

### Verificación Post-Rollback
1. `curl https://glowapp-client.web.app` → 200
2. `curl https://glowapp-provider.web.app` → 200
3. `curl https://api.glowapp.com/api/health` → healthy
4. Dashboard System Health → todos los gauges verdes

---

## 6. Auth Outage

**Síntomas**: Usuarios no pueden iniciar sesión, `authAttemptsTotal{result="failure"}` spike

### Diagnóstico
```bash
# Verificar Firebase Auth
sum by (method, result) (rate(firebase_auth_operations_total[5m]))

# Verificar JWT secret
# Si rotaron secret sin redeploy: tokens inválidos
```

### Resolución
1. **Firebase caído**: Verificar status, esperar resolución
2. **JWT secret mismatch**: Redeploy backend con secret correcto
3. **Clock skew**: Verificar NTP en servidores Railway

---

## 7. RAG Pipeline Failure

**Alerta**: `RAGErrorsSpike` — RAG error rate > 5%

### Síntomas
- Chat/asistente devuelve errores o respuestas vacías
- Fallback rate alto

### Diagnóstico
```bash
# Verificar embeddings
rate(rag_queries_total{result="error"}[5m])

# Verificar Gemini API
rate(external_api_calls_total{service="gemini",status="error"}[5m])

# Verificar pgvector
SELECT * FROM pg_stat_statements WHERE query LIKE '%embedding%' ORDER BY mean_time DESC LIMIT 5;
```

### Resolución
1. **Gemini API**: Verificar cuota, activar fallback local
2. **pgvector**: Reindexar (`REINDEX TABLE embeddings`), verificar dimensión 2048
3. **Embeddings corruptos**: Re-ejecutar `npm run ingest:rag`

---

## Contactos de Escalación

| Nivel | Contacto | Canal | Tiempo Respuesta |
|-------|----------|-------|------------------|
| L1 | On-call DevOps | PagerDuty / Slack #alerts | 5 min |
| L2 | Backend Lead | Slack DM / Call | 15 min |
| L3 | CTO | Teléfono directo | 30 min |

---

## Enlaces Útiles
- [Grafana Dashboards](https://grafana.glowapp.com)
- [Loki Logs](https://grafana.glowapp.com/explore)
- [Railway Dashboard](https://railway.com/project/glowapp)
- [Firebase Console](https://console.firebase.google.com/project/glowapp-client)
- [Stripe Dashboard](https://dashboard.stripe.com)
- [Wompi Dashboard](https://dashboard.wompi.co)