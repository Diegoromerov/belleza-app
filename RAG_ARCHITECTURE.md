# RAG Architecture — GlowApp / Belleza App

## Documento Canónico (Single Source of Truth)

> **Última actualización**: 2026-08-13 (Ciclo 05 — Cierre MVP R1-R4)
> **Estado**: MVP RAG AURA R1-R4 CERRADO (validación real LOCAL)

---

## 1. Visión General

El sistema RAG de GlowApp tiene **una única ruta canónica de recuperación** para el orquestador Aura (runtime usuario). Todo lo demás es legacy o dead code.

```
┌─────────────────────────────────────────────────────────────────────┐
│                    ARQUITECTURA RAG CANÓNICA                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   Aura Runtime (DeepSeek + NV-Embed-QA)                            │
│        │                                                             │
│        ▼                                                             │
│   auraToolExecutor.js ──► ragService.searchBeautyKnowledge()       │
│        │                                                             │
│        ▼                                                             │
│   ┌─────────────────────────────────────────┐                       │
│   │           ragService.js                 │                       │
│   │  - HNSW vector search (pgvector 1024d)  │                       │
│   │  - Metadata filters (category, source)  │                       │
│   │  - FTS fallback (tsvector/tsquery)      │                       │
│   │  - Logging → rag_query_logs             │                       │
│   └─────────────────────────────────────────┘                       │
│        │                                                             │
│        ▼                                                             │
│   ragPool (RAG_DATABASE_URL) ──► beauty_knowledge_embeddings       │
│        │         (separate pool)             (canonical table)      │
│        │                                                             │
│        ▼                                                             │
│   embeddingService.generateEmbedding() ──► NVIDIA NV-Embed-QA      │
│        │         (circuit breaker)            1024-dim              │
│        ▼                                                             │
│   Circuit Breaker: nvidiaEmbeddings (3 failures / 30s cooldown)    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. Componentes Canónicos

### 2.1 Tablas (Single Source of Truth)

| Tabla | Migración | Propósito | Pool |
|-------|-----------|-----------|------|
| `beauty_knowledge_embeddings` | 031, 035, **046** | Chunks vectorizados 1024d + metadata + trazabilidad | `ragPool` |
| `rag_query_logs` | 036, **047** | Logs de consultas con trazabilidad completa | `ragPool` |
| `beauty_consents` | 019 | Consentimientos biométricos (no RAG) | `pool` (main) |
| `biometric_consents` | 037 | Consentimientos para AI scan (no RAG) | `pool` (main) |

> **Nota**: `aura_knowledge_chunks` **NO EXISTE** en ninguna migración (001-047). Es referencia legacy eliminada.

### 2.2 Pool Separado: `ragPool`

**Ubicación**: `backend/src/config/db.js`

```javascript
// SOLO se crea si RAG_DATABASE_URL existe
let ragPool = null;
if (process.env.RAG_DATABASE_URL) {
  ragPool = new Pool({ connectionString: process.env.RAG_DATABASE_URL, ... });
}
module.exports = { pool, ragPool };
```

**Propósito**: Aislamiento total del pool principal (`pool`). Permite:
- Diferente conexión (Railway pgvector dedicado vs PostgreSQL general)
- Timeouts/pool sizes optimizados para vector search
- Migraciones RAG independientes

### 2.3 Servicios Canónicos

| Archivo | Responsabilidad | Estado |
|---------|----------------|--------|
| `ragService.js` | Búsqueda HNSW + FTS fallback + logging | ✅ Canónico |
| `embeddingService.js` | NVIDIA NV-Embed-QA 1024d + circuit breaker | ✅ Canónico (R2 fixed) |
| `chunkingService.js` | Chunking semántico 500-800 tokens, overlap 50 | ✅ Canónico |
| `circuitBreakerService.js` | `nvidiaEmbeddings` breaker (3/30s) | ✅ Canónico (R2 fixed) |
| `auraToolExecutor.js` | Tool `search_beauty_knowledge` → `ragService` | ✅ Canónico |

### 2.4 Flujo de Embedding (R2 Fixed)

```
generateEmbedding(text, 'query')
        │
        ▼
┌───────────────────────┐
│ breakers.nvidiaEmbeddings.execute()  │
│  - failureThreshold: 3               │
│  - cooldownPeriod: 30000ms           │
└───────────┬───────────┘
            │
     ┌──────┴──────┐
     ▼             ▼
  Success       Failure
     │             │
     ▼             ▼
  return vec    THROW error  ◄── NO dummy fallback!
                    │
                    ▼
            ragService catch
                    │
                    ▼
           FTS FALLBACK (tsvector)
```

**Clave R2**: El dummy embedding (`generateDummyEmbedding`) **existe pero NO se usa en camino productivo**. Solo para tests/manual scripts. El circuit breaker propaga el error; `ragService` hace FTS fallback.

---

## 3. Legacy / Dead Code (No tocar, documentar)

| Archivo | Estado | Problema | Acción Ciclo 02 |
|---------|--------|----------|-----------------|
| `beautyKnowledgeService.js` | **Legacy wrapper** | Usaba `aura_knowledge_chunks` (no existe), dummy embeddings, pool principal | ✅ Convertido a wrapper que delega a `ragService` |
| `generateDummyEmbedding` | **Existe en embeddingService** | Determinístico, cero valor semántico | ✅ Mantenido solo para tests; NO exportado como fallback |

> **Regla**: No eliminar `beautyKnowledgeService.js` (puede haber imports legacy no detectados). Mantener como wrapper documentado que delega a lo canónico.

---

## 4. Trazabilidad R3 (Migraciones 046, 047)

### 4.1 `beauty_knowledge_embeddings` — columnas añadidas (046)

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `document_id` | VARCHAR(255) | ID estable del documento origen (ej: `tratamientos_esteticos_faciales.md`) |
| `document_version` | VARCHAR(50) | Versión del documento (`1.0`, `2.1`, etc.) |
| `chunk_id` | VARCHAR(64) | ID único del chunk dentro del doc (SHA-256 hex) |
| `content_hash` | VARCHAR(64) | SHA-256 del contenido del chunk (idempotencia) |
| `fuente` | VARCHAR(100) | Origen: `corpus`, `sql_seed`, `api`, `manual` |
| `seccion` | VARCHAR(255) | Header/sección del doc (`Niacinamida - El Ingrediente Multiusos`) |

**Índices**: `document_id`, `chunk_id`, `content_hash`, `fuente`, `(document_id, document_version)`
**Constraint único**: `(document_id, chunk_id)` para idempotencia de ingestión

### 4.2 `rag_query_logs` — columnas añadidas (047)

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `category` | VARCHAR(100) | Categoría query: `skincare`, `cabello`, `cejas`, `general` |
| `threshold_used` | NUMERIC(4,3) | Threshold usado (ej: `0.450`, `0.700`) |
| `filters_applied` | JSONB | Filtros metadata: `{"category": "skincare"}` |
| `all_scores` | NUMERIC[] | TODOS los scores candidatos (no solo top-K) |
| `retrieval_mode` | VARCHAR(20) | `hnsw`, `fts`, `hybrid` |
| `fallback_triggered` | BOOLEAN | Si se activó FTS fallback |
| `breaker_state_at_query` | VARCHAR(20) | Estado breaker: `closed`, `open`, `half_open` |

---

## 5. Ingestión Reproducible R4 (Preparado)

### 5.1 Infraestructura Local Requerida

```yaml
# backend/docker-compose.yml (ya existe)
services:
  postgres:
    image: pgvector/pgvector:pg16
    ports: ["5435:5432"]  # Puerto 5435 para evitar conflicto con Railway
    environment:
      POSTGRES_DB: beauty_rag_local
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - pgvector_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]
```

### 5.2 Variables de Entorno Local (`.env.local`)

```bash
# Local development - NO USAR EN PRODUCCIÓN
RAG_DATABASE_URL=postgresql://postgres:postgres@localhost:5435/beauty_rag_local
DATABASE_URL=postgresql://postgres:postgres@localhost:5435/beauty_rag_local
REDIS_URL=redis://localhost:6379

# NVIDIA (requerido para embeddings reales)
NVIDIA_API_KEY=tu_nvidia_api_key
NVIDIA_EMBED_URL=https://integrate.api.nvidia.com/v1
NVIDIA_EMBEDDING_MODEL=nvidia/nv-embedqa-e5-v5
```

### 5.3 Script de Ingestión

**Archivo**: `backend/scripts/ingestBeautyKnowledge.js`

Características:
- Idempotente por `content_hash` (SHA-256)
- Rate limited: 10 chunks/seg, batch 10
- Lee corpus de `backend/src/data/beauty_corpus/*.md`
- Usa `chunkingService` (semántico 500-800 tokens)
- Inserta en `beauty_knowledge_embeddings` via `ragPool`
- Popula todas las columnas de trazabilidad (046)

### 5.4 Pasos R4 (Ejecutar cuando Docker disponible)

```bash
# 1. Levantar infraestructura local
cd backend && docker-compose up -d postgres redis

# 2. Verificar salud
docker-compose exec postgres pg_isready
docker-compose exec redis redis-cli ping

# 3. Aplicar migraciones (incluye 046, 047)
npm run migrate

# 4. Configurar .env.local
cp .env.example .env.local
# Editar .env.local con RAG_DATABASE_URL local + NVIDIA_API_KEY

# 5. Ejecutar ingestión
RAG_DATABASE_URL=postgresql://postgres:postgres@localhost:5435/beauty_rag_local \
NVIDIA_API_KEY=xxx \
node scripts/ingestBeautyKnowledge.js

# 6. Verificar
psql $RAG_DATABASE_URL -c "SELECT count(*), fuente FROM beauty_knowledge_embeddings GROUP BY fuente;"
```

---

## 6. Reglas de Oro (No Negociables)

1. **NUNCA** usar `RAG_DATABASE_URL` de producción (Railway) para migraciones, ingestión, o writes destructivos
2. **ÚNICA** ruta de recuperación para Aura: `auraToolExecutor` → `ragService.searchBeautyKnowledge` → `ragPool` → `beauty_knowledge_embeddings`
3. **NO** dummy embeddings en camino productivo. Circuit breaker propaga error → `ragService` hace FTS fallback
4. **Pool separado**: `ragPool` para RAG, `pool` para resto. No mezclar.
5. **Migraciones RAG**: 031, 035, 046 ejecutadas (LOCAL). **036/047 APLAZADAS** — el runtime no requiere `rag_query_logs` (logger tiene fallback silencioso a archivo); 047 es observabilidad futura. No ejecutar 036/047 hasta que un requerimiento lo justifique.
6. **Trazabilidad**: Todas las columnas dedicadas (no solo JSONB) para queries analíticas eficientes
7. **Tests**: Suite RAG usa mocks. Validación real requiere infra local + eval dataset (30 queries)

---

## 7. Próximos Pasos (Bloque Siguiente — Referencia, NO implementar en este ciclo)

| Fase | Descripción | Bloqueador |
|------|-------------|------------|
| R5 | Evaluación RAGAS real (no mock) contra eval dataset | Infra R1-R4 ya estable (lista) |
| Brecha #1-#5 | Mejoras calidad: re-ranking, hybrid search, etc. | R5 baseline |
| CI/CD | Gates automáticos en pipeline | R5 passing |
| Profile filters | Filtros por perfil usuario en retrieval | Requiere user_preferences integration |

---

## 7b. Estado MVP R1-R4 (Cierre — Ciclo 05)

> **Validación realizada 100% en infraestructura LOCAL**:
> Docker Desktop + `beauty-postgres` (pgvector/pgvector:pg16, puerto 5435, DB `beauty_db`, user `admin`).
> **Railway producción NO fue utilizado** para ninguna prueba destructiva de ingestion/migración.

### Resultados por requerimiento

| Requerimiento | Estado | Evidencia |
|---------------|--------|-----------|
| **R1 — Arquitectura canónica** | ✅ PASS | `auraToolExecutor` → `ragService` → `ragPool` → `beauty_knowledge_embeddings`. `beautyKnowledgeService` = wrapper de compatibilidad (0 retrieval propio). `aura_knowledge_chunks` = 0 referencias activas |
| **R2 — Embeddings reales** | ✅ PASS | NVIDIA `nv-embedqa-e5-v5` 1024-dim. Circuit breaker `nvidiaEmbeddings` (3 fallos/30s). Error propagado, **dummy ausente del camino productivo**. FTS fallback en `ragService` |
| **R3 — Trazabilidad** | ✅ PASS | Migración 046: `document_id`, `document_version`, `chunk_id`, `content_hash`, `fuente`, `seccion` + constraint `UNIQUE(document_id, chunk_id)`. Backfill 44 filas históricas. 0 NULLs |
| **R4 — Ingestion idempotente** | ✅ PASS | Ingestion real #1 = 31 inserts; #2 = 0 inserts. 0 duplicados. SHA-256 determinista. `ragPool` + `RAG_DATABASE_URL` local |

### Identidad de chunk (decisión R3)

- **Constraint**: `UNIQUE(document_id, chunk_id)` — `document_id` = basename del archivo fuente (estable entre versiones); `chunk_id` = SHA-256 del contenido del chunk.
- **Compatible con ingestion**: el upsert usa exactamente `ON CONFLICT (document_id, chunk_id)`.
- **Segunda ingesta** (mismo contenido): mismo `chunk_id` → `UPDATE` inofensivo → **0 duplicados**.
- **Nueva versión documental** (contenido modificado): nuevo SHA-256 → nuevo `chunk_id` → INSERT legítimo; la versión anterior permanece como histórico (no se borra). `document_version` registra la versión activa.

### Verificaciones de cierre (Ciclo 05)

- Suite RAG: **5 suites, 69/69 tests PASS** (embeddingService 16, ragLogger 10, ragMetrics 12, ragEvaluator 23, ciRagEvaluation 8)
- BD local: 44 filas, 44/44 `document_id`, 44/44 `chunk_id`, 44/44 `content_hash`, 31 hashes reales SHA-256, 0 NULLs, 0 duplicados `(document_id, chunk_id)`
- Retrieval vectorial real: query niacinamida → similarity **0.5238**
- FTS fallback real: NVIDIA 401 simulado → full-text → similarity **0.5**
- Suite global backend: 263 passed / 8 failed / 1 skipped — los 8 fallos son **FUERA DE ALCANCE / PREEXISTENTES** (biométricos E2E + geminiFallback), NO se reparan en este bloque

### Nota sobre baselines

Los valores P@5, R@5, MRR, Faithfulness, Answer Relevancy **NO** constituyen baseline oficial nuevo en este ciclo. La evaluación comparativa (R5AS/benchmark) pertenece al siguiente bloque, sobre esta infraestructura ya estable.

---

## 8. Verificación Rápida (Checklist)

```bash
# Verificar arquitectura canónica
grep -r "ragService.searchBeautyKnowledge" backend/src/       # Debe existir en auraToolExecutor
grep -r "beauty_knowledge_embeddings" backend/src/            # Debe existir en ragService, db config
grep -r "ragPool" backend/src/config/db.js                     # Debe exportarse
grep -r "aura_knowledge_chunks" backend/src/                  # DEBE dar 0 resultados
grep -r "generateDummyEmbedding" backend/src/services/embeddingService.js  # Existe pero NO como fallback

# Verificar migraciones
ls backend/migrations/ | grep -E "^(03[156]|04[67])_"

# Verificar circuit breaker
grep -A5 "nvidiaEmbeddings" backend/src/services/circuitBreakerService.js
```

---

*Fin del documento — RAG_ARCHITECTURE.md v1.0 (Ciclo 02)*