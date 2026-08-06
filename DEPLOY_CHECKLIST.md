# GlowApp - Deploy Checklist para Railway

## 📋 Información General
- **Proyecto:** GlowApp Backend API
- **Repositorio:** Diegoromerov/belleza-app
- **Branch:** main
- **Fecha:** 2026-08-06
- **Versión:** 1.0.0

---

## 🔴 FASE 1: Verificación Pre-Deploy (Local)

### 1.1 Verificar que el código está listo
- [ ] `git status` → working tree clean
- [ ] `git log --oneline -5` → últimos commits correctos
- [ ] `npm test` → 172/172 tests passing ✅
- [ ] `npm run lint` (si existe) → sin errores

### 1.2 Verificar archivos de configuración
- [ ] `knexfile.js` existe en backend/
- [ ] `package.json` tiene scripts correctos
- [ ] `.env.example` actualizado
- [ ] `scripts/verifyRagSchema.js` existe
- [ ] `scripts/ingestBeautyKnowledge.js` existe

### 1.3 Verificar migraciones locales
- [ ] `ls backend/migrations/` → 031-037 presentes
- [ ] `031_aura_pgvector_and_knowledge_table.sql` → crea beauty_knowledge_embeddings con vector(1024)
- [ ] `032-037` → consentimiento biométrico, rag_query_logs, etc.

---

## 🟡 FASE 2: Deploy en Railway (Dashboard)

### 2.1 Servicios Railway
En Railway Dashboard:
- [ ] **Proyecto:** glowapp (o nombre del proyecto)
- [ ] **Servicios activos:**
  - `api` (Backend Node.js) → UP
  - `frontend` (Flutter Web / Next.js) → UP
  - `postgres` (PostgreSQL + pgVector) → UP
  - `redis` (Redis) → UP

### 2.2 Variables de Entorno (Railway Dashboard → Variables)
| Variable | Valor | Origen |
|----------|-------|--------|
| `DATABASE_URL` | `postgresql://...` | Railway Postgres (auto-inyectada) |
| `REDIS_URL` | `redis://...` | Railway Redis (auto-inyectada) |
| `DEEPSEEK_API_KEY` | `sk-...` | DeepSeek Dashboard |
| `GEMINI_API_KEY` | `...` | Google AI Studio |
| `NVIDIA_API_KEY` | `...` | **KEY DE RECARGO** (NVIDIA NIM) |
| `NVIDIA_EMBED_URL` | `https://integrate.api.nvidia.com/v1` | Fijo |
| `NVIDIA_EMBEDDING_MODEL` | `nvidia/nv-embedqa-e5-v5` | Fijo |
| `ENABLE_BEAUTY_RAG` | `true` | Fijo |
| `JWT_SECRET` | `...` | Generado seguro (32+ chars) |
| `NODE_ENV` | `production` | Fijo |
| `PORT` | `8080` | Railway asigna |

### 2.3 Despliegue
- [ ] Push a `main` → Railway auto-deploy
- [ ] Verificar logs de build: `npm install` → success
- [ ] Verificar logs de start: `node index.js` → "Backend funcionando"
- [ ] Health check: `GET /api/health` → 200 OK

---

## 🟢 FASE 3: Post-Deploy - Migraciones y Verificación

### 3.1 Ejecutar Migraciones (Railway Console)
```bash
# En Railway Dashboard → Project → Service (api) → Console
npx knex migrate:latest
```
**Resultado esperado:**
```
Batch 1 run: 7 migrations
031_aura_pgvector_and_knowledge_table.sql
032_fix_011_insert.sql
033_add_id_academy_certificates.sql
034_add_fks_to_academy_tables.sql
035_fix_embedding_dimension_and_hnsw_index.sql
036_create_rag_query_logs.sql
037_create_biometric_consents.sql
```

### 3.2 Verificar Esquema RAG
```bash
# En Railway Console
node scripts/verifyRagSchema.js
```
**Resultado esperado:**
```
=== VERIFICACIÓN ESQUEMA RAG (beauty_knowledge_embeddings) ===

✅ Embedding: tipo=vector, dimensión=1024
✅ Índice HNSW encontrado: idx_beauty_knowledge_embedding_hnsw con vector_cosine_ops
✅ Columna metadata: category (character varying)
✅ Columna metadata: skin_type (character varying)
✅ Columna metadata: season_station (character varying)
✅ Columna metadata: age_range (character varying)
✅ Columna metadata: ingredients (_text)
✅ Columna metadata: contraindications (_text)
✅ Índice metadata: idx_beauty_knowledge_category
✅ Índice metadata: idx_beauty_knowledge_skin_type
✅ Índice metadata: idx_beauty_knowledge_season_station
✅ Índice metadata: idx_beauty_knowledge_age_range
✅ Índice metadata: idx_beauty_knowledge_ingredients
✅ Índice metadata: idx_beauty_knowledge_contraindications

✅ VERIFICACIÓN EXITOSA: Esquema RAG correcto
Exit code: 0
```

### 3.3 Verificar Tablas de Consentimiento
```bash
# En Railway Console (psql o similar)
\dt biometric_consents biometric_access_log
```
**Resultado esperado:**
```
biometric_consents (con UNIQUE user_id, consent_type, version_terms)
biometric_access_log (con índices user_id, accessed_at)
```

---

## 🔵 FASE 4: Ingesta Real de Conocimiento

### 4.1 Verificar Corpus
```bash
ls -la backend/src/data/beauty_corpus/
# 001_skincare_basics.md (5 artículos con frontmatter YAML)
```

### 4.2 Dry-Run de Ingesta
```bash
# En Railway Console
node scripts/ingestBeautyKnowledge.js --source=corpus --dry-run
```
**Resultado esperado:**
```
=== INGESTA RAG: DRY-RUN ===
Fuente: corpus
Documentos detectados: 5
001_skincare_basics.md
  Artículos: 5
  Chunks estimados: ~25
  Metadata a extraer: category, skin_type, season_station, age_range, ingredients, contraindications
Tiempo estimado: ~30 segundos
DRY-RUN: No se escriben datos en BD
```

### 4.3 Ingesta Real
```bash
# En Railway Console
node scripts/ingestBeautyKnowledge.js --source=corpus
```
**Resultado esperado (logs):**
```
[1/25] Procesando chunk: bakuchiol_what_is (score: 0.92)
[2/25] Procesando chunk: bakuchiol_pregnancy_safety (score: 0.88)
...
[25/25] Procesando chunk: contraindications_retinol (score: 0.85)

✅ Ingesta completada: 25 chunks insertados
📊 Embeddings generados: 25 (1024d)
⏱️ Tiempo total: 45s
```

### 4.4 Verificar Ingesta
```sql
-- En Railway Console (psql)
SELECT COUNT(*) FROM beauty_knowledge_embeddings;
SELECT category, COUNT(*) FROM beauty_knowledge_embeddings GROUP BY category;
```
**Resultado esperado:**
```
 count 
-------
    25
(1 row)

 category   | count 
------------+-------
 ingredientes |    8
 contraindicaciones |    6
 rutinas |    5
 protección solar |    3
 limpieza |    3
(5 rows)
```

---

## 🟣 FASE 5: Generar Baseline de Métricas

### 5.1 Ejecutar Evaluación RAG
```bash
# En Railway Console
node scripts/evaluateRag.js --dataset=src/data/eval/evaluation_dataset.json --baseline=src/data/eval/baseline_metrics.json --output=src/data/eval/production_baseline.json --verbose
```
**Resultado esperado:**
```
🧪 GlowApp RAG Evaluation Suite
Dataset: 30 queries
Top-K: 5

📋 Query 1/30 [skincare/easy]: ¿Qué es el bakuchiol y para qué sirve?
  📊 Retrieval: P@5=0.80, R@5=0.75, MRR=0.85
  📊 Generation: Faithfulness=0.92, Relevancy=0.88
  📊 Context: Precision=0.85, Recall=0.80
  ⏱️ Latency: 2200ms

...
✅ Evaluación completada: 30/30 queries exitosas

📊 RESUMEN:
  Retrieval: P@5=0.78, R@5=0.70, MRR=0.75
  Generation: Faithfulness=0.88, Relevancy=0.85
  Latency: P50=2100ms, P95=5800ms, P99=11000ms

💾 Baseline actualizado en: src/data/eval/baseline_metrics.json
```

### 5.2 Verificar Quality Gates
```bash
node scripts/ciRagEvaluation.sh
```
**Resultado esperado:**
```
╔═══════════════════════════════════════════════════════════════╗
║     GlowApp RAG Evaluation - CI/CD Pipeline                  ║
╚═══════════════════════════════════════════════════════════════╝

[SUCCESS] ✅ Todos los Quality Gates PASARON

════════════════════════════════════════════════════════════════
                    RESUMEN DE EVALUACIÓN
════════════════════════════════════════════════════════════════
Total Queries:        30
Exitosas:             30
Precision@5:          0.78
Recall@5:             0.70
Faithfulness:         0.88
Answer Relevancy:     0.85
Duración:             45s
════════════════════════════════════════════════════════════════
Exit code: 0
```

---

## 🟠 FASE 6: Prueba End-to-End (E2E)

### 6.1 Prueba RAG - Bakuchiol
```bash
curl -X POST https://glowapp-api.railway.app/api/chat/message \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"message": "¿De qué planta se deriva el bakuchiol y por qué es recomendado en el embarazo?"}'
```
**Resultado esperado:**
```json
{
  "message": "El bakuchiol se deriva de la planta **Psoralea corylifolia** (babchi) y es una alternativa natural al retinol. Se recomienda en el embarazo porque **no es teratogénico** como el retinol (vitamina A), y ofrece beneficios anti-envejecimiento similares sin riesgos para el feto. ✨",
  "rag_context_used": true,
  "chunks_retrieved": 2
}
```

### 6.2 Prueba Tool Calling - ATENA
```bash
curl -X POST https://glowapp-api.railway.app/api/chat/message \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"message": "¿Qué tipo de piel tengo según mi perfil?"}'
```
**Resultado esperado:**
```json
{
  "message": "Según tu perfil biométrico, tienes **piel mixta** con tendencia a grasa en zona T...",
  "tool_calls": [
    {"name": "query_user_biometric_profile", "args": {"userId": "123"}}
  ]
}
```

### 6.3 Prueba Consentimiento
```bash
# Sin consentimiento
curl -X POST https://glowapp-api.railway.app/api/chat/message \
  -H "Authorization: Bearer <TOKEN_SIN_CONSENTIMIENTO>" \
  -d '{"message": "Analiza mi foto de piel"}'

# Resultado esperado: 403
{
  "error": "consent_required",
  "consent_type": "skin_scan",
  "message": "Para usar esta función, necesitas otorgar consentimiento para el procesamiento de tus datos biométricos..."
}
```

### 6.4 Prueba Rate Limiting
```bash
# Enviar 31 requests en < 1 min (Free tier = 30/min)
for i in {1..31}; do curl -X POST ...; done

# Request 31 debe retornar:
{
  "error": "rate_limit_exceeded",
  "retry_after": 45,
  "message": "Demasiadas solicitudes. Intenta de nuevo en 45 segundos."
}
Headers: Retry-After: 45
```

### 6.5 Prueba PII Sanitization
```bash
curl -X POST ... -d '{"message": "Mi email es test@test.com, ¿qué rutina me recomiendas?"}'

# Verificar logs NO contienen "test@test.com"
# Respuesta no debe exponer el email
```

---

## 🟤 FASE 7: Verificación de Calidad

### 7.1 Quality Gates
```bash
# En Railway Console
node scripts/ciRagEvaluation.sh
# Exit code: 0 ✅
```

### 7.2 Logging y Auditoría
```sql
-- Verificar rag_query_logs
SELECT COUNT(*) FROM rag_query_logs WHERE created_at > NOW() - INTERVAL '1 hour';

-- Verificar biometric_access_log
SELECT * FROM biometric_access_log ORDER BY accessed_at DESC LIMIT 10;

-- Verificar biometric_consents
SELECT * FROM biometric_consents WHERE user_id = '<TEST_USER_ID>';
```

---

## 📋 FASE 8: Documentación

### 8.1 DEPLOY_CHECKLIST.md
Este archivo se genera al completar todas las fases.

---

## ⚠️ ISSUES CONOCIDOS Y FIXES PROPUESTOS

| Severidad | Issue | Fix Propuesto |
|-----------|-------|---------------|
| 🔴 Crítico | PostgreSQL local no disponible | Usar Railway Postgres managed; no testear local |
| 🟡 Warning | knexfile.js necesita DATABASE_URL | Configurar en Railway Dashboard antes de migrate |
| 🟡 Warning | NVIDIA API Key expuesta en .env.example | Usar key de recambio, no la real |
| 🟢 Info | Tests E2E requieren Railway real | Ejecutar solo en Railway Console |

---

## 📞 CONTACTO DE EMERGENCIA
- **DevOps:** Diego (Diegoromerov)
- **Railway Support:** support@railway.app
- **NVIDIA NIM Support:** https://www.nvidia.com/en-us/support/

---

## 📊 MÉTRICAS A MONITOREAR (Primeras 24h)
| Métrica | Threshold | Acción |
|---------|-----------|--------|
| Error rate | > 5% | Alertar on-call |
| Latencia P95 | > 8s | Revisar embeddings/RAG |
| Fallback rate | > 20% | Verificar DeepSeek API |
| Chunks retrieved | < 2 avg | Revisar threshold/ingesta |
| RAG queries/hora | < 10 | Verificar tráfico |

---

## 🔄 ROLLBACK PROCEDURE
```bash
# 1. Railway Dashboard → Service → Rollback a deploy anterior
# 2. Si migraciones problemáticas:
npx knex migrate:down  # Revierte última migración
# 3. Si datos corruptos:
# Restaurar backup de Postgres (Railway → Postgres → Backups)
# 4. Verificar health check
curl https://glowapp-api.railway.app/api/health
```

---

## ✅ CRITERIOS DE ACEPTACIÓN FINAL

- [ ] Todos los servicios Railway UP
- [ ] Variables de entorno verificadas (NVIDIA key de recambio)
- [ ] Migraciones 031-037 aplicadas sin error
- [ ] `verifyRagSchema.js` → exit code 0
- [ ] Ingesta dry-run detecta 5 artículos
- [ ] Ingesta real inserta >0 chunks con embeddings 1024d
- [ ] Tabla `beauty_knowledge_embeddings` tiene > 0 chunks
- [ ] Evaluación RAG ejecuta 30 queries sin error
- [ ] Quality gates pasan (exit code 0)
- [ ] Prueba E2E bakuchiol → "Psoralea corylifolia"
- [ ] Tool calling funciona (ATENA invocado)
- [ ] Fallback Gemini funciona
- [ ] Rate limiting → 429 en request 31
- [ ] Consentimiento → 403 sin autorización
- [ ] PII sanitizada en logs
- [ ] `rag_query_logs` tiene registros
- [ ] `biometric_access_log` tiene registros
- [ ] `DEPLOY_CHECKLIST.md` creado

---

**FIRMA:** _________________ **FECHA:** _________________
**DEPLOY APROBADO:** ☐ SÍ ☐ NO (ver issues)