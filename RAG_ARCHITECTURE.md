# RAG Architecture — GlowApp / Belleza App

## Documento Canónico (Single Source of Truth)

> **Última actualización**: 2026-08-13 (Ciclo 05 — Cierre MVP R1-R4)
> **Estado**: MVP RAG AURA R1-R4 CERRADO (validación real LOCAL)
>
> **Actualización 2026-09-22** (auditoría independiente + PR #6): ⚠️ la **ruta vectorial no está
> operativa**. El modelo `nvidia/nv-embedqa-e5-v5` alcanzó su *end of life* el **2026-08-25** y la
> API responde `410 Gone`. Ver **§9** al final: hallazgo, mediciones antes/después y plan P0.
> Las secciones 1-8 se conservan como registro histórico; §9 indica qué dejó de ser cierto.

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
| `embeddingService.js` | NVIDIA NV-Embed-QA 1024d + circuit breaker | ✅ Canónico (R2 fixed) — ⚠️ modelo EOL 2026-08-25, ver §9.1 |
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

> **Verificado 2026-09-22 (§9.3)**: afirmación cierta **desde PR #6**. Antes de ese merge
> `embeddingService.generateEmbedding` devolvía `generateDummyEmbedding` como fallback (y el
> retrieval sin `NVIDIA_API_KEY` construía un vector determinístico): resultado, 0 filas en
> silencio y una traza que declaraba `retrieval_mode=hnsw`.

---

## 3. Legacy / Dead Code (No tocar, documentar)

| Archivo | Estado | Problema | Acción Ciclo 02 |
|---------|--------|----------|-----------------|
| `beautyKnowledgeService.js` | **Legacy wrapper** | Usaba `aura_knowledge_chunks` (no existe), dummy embeddings, pool principal | ✅ Convertido a wrapper que delega a `ragService`. **Verificado 2026-09-22**: la conversión ocurrió en PR #6; hasta ese merge el archivo seguía consultando `aura_knowledge_chunks`. Conserva el flag `ENABLE_BEAUTY_RAG` y sus exports |
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
| `category` | VARCHAR(100) | Categoría del conocimiento. **Vocabulario canónico (12 valores, `config/knowledgeCategories.js`)**: `colorimetria_capilar_tinte`, `colorimetria_piel_undertone`, `cuidado_corporal_y_spa`, `diagnostico_capilar`, `guias_unas`, `ingredientes_activos_contraindicaciones`, `maquillaje_tecnicas_por_ocasion`, `skincare_rutinas_por_tipo_piel`, `tendencias_belleza_virales`, `textura_poros`, `tratamientos_esteticos_faciales`, `visajismo_cejas_microblading`. *(Antes decía `skincare`, `cabello`, `cejas`, `general`: esos valores NO existen en el corpus y filtrar por ellos devolvía 0 chunks — corregido en Fase 1.)* |
| `threshold_used` | NUMERIC(4,3) | Threshold usado (ej: `0.450`, `0.700`) |
| `filters_applied` | JSONB | Filtros metadata que se aplicaron realmente: `{"category": "guias_unas"}` (vacío `{}` si el valor no pertenece al vocabulario y se descartó, ver `filters_dropped` en la traza JSON) |
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
RAG_DATABASE_URL=postgresql://postgres:***@localhost:5435/beauty_rag_local
DATABASE_URL=postgresql://postgres:***@localhost:5435/beauty_rag_local
REDIS_URL=redis://localhost:6379

# NVIDIA (requerido para embeddings reales)
NVIDIA_API_KEY=tu_nvidia_api_key
NVIDIA_EMBED_URL=https://integrate.api.nvidia.com/v1
NVIDIA_EMBEDDING_MODEL=nvidia/nv-embedqa-e5-v5   # ⚠️ EOL 2026-08-25 (410 Gone) — ver §9.1
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
RAG_DATABASE_URL=postgresql://postgres:***@localhost:5435/beauty_rag_local \
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
5. **Migraciones RAG**: 031, 035, 046 y **048** ejecutadas (LOCAL). ~~036/047 APLAZADAS~~ — **corregido 2026-09-22**: 036 y 047 **también están aplicadas** (`rag_query_logs` existe con sus 16 columnas; verificado en la BD local). Lo que falta no es ejecutarlas sino **poblarlas**: **RESUELTO en Fase 1 (PR #8, 2026-09-23)** —
`ragLogger.saveToPostgres` inserta las 16 columnas (`category`, `threshold_used`, `filters_applied`,
`all_scores`, `retrieval_mode`, `fallback_triggered`, `breaker_state_at_query`), verificado
escribiendo y leyendo una fila real: 0 columnas en NULL. La traza JSON añade `filters_dropped` y
`filters_relaxed`, y el umbral registrado es el realmente usado (antes: `0.72` en la traza con `0.45`
en la consulta). Ver §9.8.
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
| **R2 — Embeddings reales** | ✅ PASS (histórico) | NVIDIA `nv-embedqa-e5-v5` 1024-dim. Circuit breaker `nvidiaEmbeddings` (3 fallos/30s). Error propagado, **dummy ausente del camino productivo**. FTS fallback en `ragService`. ⚠️ **Superado 2026-08-25**: el modelo alcanzó end-of-life y la API responde 410 → ver §9. La parte de "dummy ausente" se hizo cierta en PR #6 (§9.3) |
| **R3 — Trazabilidad** | ✅ PASS | Migración 046: `document_id`, `document_version`, `chunk_id`, `content_hash`, `fuente`, `seccion` + constraint `UNIQUE(document_id, chunk_id)`. Backfill 44 filas históricas. 0 NULLs |
| **R4 — Ingestion idempotente** | ✅ PASS | Ingestion real #1 = 31 inserts; #2 = 0 inserts. 0 duplicados. SHA-256 determinista. `ragPool` + `RAG_DATABASE_URL` local |

### Identidad de chunk (decisión R3)

- **Constraint**: `UNIQUE(document_id, chunk_id)` — `document_id` = basename del archivo fuente (estable entre versiones); `chunk_id` = SHA-256 del contenido del chunk.
- **Compatible con ingestion**: el upsert usa exactamente `ON CONFLICT (document_id, chunk_id)`.
- **Segunda ingesta** (mismo contenido): mismo `chunk_id` → `UPDATE` inofensivo → **0 duplicados**.
- **Nueva versión documental** (contenido modificado): nuevo SHA-256 → nuevo `chunk_id` → INSERT legítimo; la versión anterior permanece como histórico (no se borra). `document_version` registra la versión activa.

### Verificaciones de cierre (Ciclo 05)

- Suite RAG: **5 suites, 69/69 tests PASS** (embeddingService 16, ragLogger 10, ragMetrics 12, ragEvaluator 23, ciRagEvaluation 8)
- BD local: 44 filas, 44/44 `document_id`, 44/44 `chunk_id`, 44/44 `content_hash`, 31 hashes reales SHA-256, 0 NULLs, 0 duplicados `(document_id, chunk_id)` — *estado del Ciclo 05. **Verificado 2026-09-22**: la BD local que sirve la app tiene hoy **0 filas**; el corpus canónico (5.619 chunks) está en el repo pero sin embeber*
- Retrieval vectorial real: query niacinamida → similarity **0.5238** — *medido con el modelo vivo; hoy no reproducible (410, §9.1)*
- FTS fallback real: NVIDIA 401 simulado → full-text → similarity **0.5** — *valor histórico: el fallback inyectaba `0.5` como constante. Desde Fase 1 (PR #8) devuelve `similarity = null` con `retrieval_mode = 'fts'`: no se presenta una similitud que no se midió*
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
ls backend/migrations/ | grep -E "^(03[156]|04[678])_"

# Verificar circuit breaker
grep -A5 "nvidiaEmbeddings" backend/src/services/circuitBreakerService.js

# Verificar que el modelo de embeddings sigue VIVO (410 = ruta vectorial caída, ver §9.1)
curl -s -o /dev/null -w "%{http_code}\n" -X POST https://integrate.api.nvidia.com/v1/embeddings \
  -H "Authorization: Bearer $NVIDIA_API_KEY" -H 'Content-Type: application/json' \
  -d '{"input":["test"],"model":"nvidia/nv-embedqa-e5-v5","input_type":"query"}'

# Dimensiones exigidas por código y esquema (deben coincidir con el modelo elegido)
grep -n "expectedDimension\|EXPECTED_DIMS" backend/src/services/embeddingService.js backend/src/services/ragService.js
```

---

## 9. Estado verificado 2026-09-22 (auditoría independiente + PR #6)

> Esta sección **no reemplaza** lo anterior: lo fecha. Las afirmaciones de los ciclos 02-05 se
> conservan como registro histórico; aquí se indica cuáles dejaron de ser ciertas, con la medición
> que lo demuestra. Evidencia ejecutable en `docs/rag-audit-2026-09-22/`.

### 9.1 Hallazgo crítico: el modelo de embeddings está retirado

| Verificación | Resultado |
|---|---|
| `GET https://integrate.api.nvidia.com/v1/models` con la key del proyecto | **HTTP 200** → la key es válida |
| `POST /v1/embeddings` con `nvidia/nv-embedqa-e5-v5` | **HTTP 410 Gone** |

Respuesta literal de la API:

```json
{"type":"about:blank","title":"Gone","status":410,
 "detail":"The model 'nvidia/nv-embedqa-e5-v5' has reached its end of life on 2026-08-25T09:00:00Z and is no longer available."}
```

**Desde el 2026-08-25 la ruta vectorial no puede producir embeddings con este modelo.** De los 7
modelos de embedding que lista la API, con esta cuenta de NVIDIA responde **solo uno**:
`nvidia/nemotron-3-embed-1b` (los otros 6 → `404 Not found for account`: el catálogo es global,
el entitlement es por cuenta).

### 9.2 Dos bloqueos adicionales (medidos)

| Bloqueo | Evidencia |
|---|---|
| El código y el esquema exigen 1024 dims | `embeddingService.js` `expectedDimension: 1024`; `ragService.js` `EXPECTED_DIMS = 1024`; columna `vector(1024)` (migración 035) |
| El único modelo vivo devuelve **2048** | medido: documentos (`passage`) y consulta (`query`) → 2048 dims |
| El umbral `0.45` descarta la respuesta correcta | con el modelo vivo, el documento correcto puntuó **0.4156** (2º: 0.1988, separación 2×) → quedaría filtrado |

### 9.3 Comportamiento medido antes/después de PR #6

Ejecutando el código **extraído del propio repositorio** (`git show <sha>:…`), contra la BD local,
con la key real:

| Escenario | Antes (`43170150`) | Después (PR #6) |
|---|---|---|
| Ingesta con key (modelo EOL) | **vector dummy fabricado, sin error** → el corpus se indexa con vectores sin valor semántico | lanza `410` → el chunk se marca fallido y no se guarda |
| Ingesta sin key | vector dummy fabricado, sin error | lanza error |
| Retrieval con key | FTS fallback (`similarity=0.5`) | FTS fallback (`similarity=0.5`) |
| Retrieval sin key | **0 filas, sin fallback** → Aura responde sin conocimiento y la traza declara `hnsw` | FTS fallback (1 fila) |

### 9.4 Aislamiento multi-tenant (BUS-RAG-001) — corregido en PR #6

`tenantId` se interpolaba en el SQL (`tenant_id::text = '${tenantId}'`). Con
`tenantId = "10') OR TRUE --"` se cerraba el predicado y se leían documentos de **otros tenants**
y filas **borradas** (reproducido: 4 filas devueltas, incluidas ajenas y con `deleted_at`). Ahora el
tenant viaja como parámetro ligado (`$n`) en la ruta vectorial y en el fallback FTS; el mismo
payload devuelve 1 fila (solo GLOBAL) y el scoping legítimo sigue funcionando en ambos sentidos.

### 9.5 Correcciones aplicadas (PR #6, mergeado)

- `embeddingService.generateEmbedding`: sin fallback dummy; el error se propaga.
- `circuitBreakerService`: `nvidiaEmbeddings` **registrado** (antes: 0 apariciones, pese a lo que afirmaba §2.3).
- `ragService`: embedding vía `embeddingService` + validación de dimensiones; `tenantId` parametrizado.
- `beautyKnowledgeService`: fachada sobre `ragService`, conservando `ENABLE_BEAUTY_RAG` y sus exports.
- `auraToolExecutor`: la categoría viaja en `filters.category` (antes se descartaba en silencio).
- `ingestBeautyKnowledge`: upsert por `(document_id, chunk_id)` (antes `ON CONFLICT (title)`, que no coincide con ninguna constraint → duplicaba filas en cada re-ingesta).

### 9.6 Pendiente P0 (no resuelto por PR #6)

| # | Acción | Detalle |
|---|---|---|
| 1 | Elegir modelo vivo | `nvidia/nemotron-3-embed-1b` es el único habilitado para esta cuenta |
| 2 | Migración de dimensiones | `expectedDimension 1024→2048`, columna `vector(2048)`, reconstruir índice HNSW |
| 3 | Re-ingesta completa | los **5.619 chunks** del corpus canónico deben re-embeberse: los vectores existentes pertenecen al espacio del modelo retirado y no son reutilizables |
| 4 | Recalibrar umbral | con el modelo vivo el acierto puntúa 0.4156, por debajo del `0.45` actual |
| 5 | Config de despliegue | `NVIDIA_API_KEY` sólo existe en el `.env` de la raíz; el backend hace `dotenv.config()` desde su cwd (`backend/.env`). Verificar que el servicio desplegado realmente la ve |
| 6 | Trazabilidad | **RESUELTO en Fase 1 (PR #8)**: 16/16 columnas pobladas y verificadas escribiendo/leyendo una fila real. La traza añade `filters_dropped`, `filters_relaxed` y el umbral realmente usado (§9.8) |
| 7 | Rol en el ejecutor | `executeAuraTool` recibe `userRole` y **no lo usa**: un cliente corre con el rol por defecto `provider` |

### 9.7 Cobertura funcional medida (rúbrica de 17 compuertas, evidencia por compuerta)

| Columna | Resultado |
|---|---|
| Implementación en el repo | **73,5%** (12,5/17) |
| Operativo con el código anterior | 58,8% (10/17) |
| **Operativo tras PR #6** | **73,5%** (12,5/17) |
| **Operativo tras Fase 1 (PR #8, 2026-09-23)** | **79,4%** (13,5/17) — la compuerta `trazabilidad` pasa de 0,5 a 1: 16/16 columnas verificadas |
| Búsqueda **semántica** (embeddings + vectorial) | **0%** — modelo retirado |
| Tras aplicar §9.6 (modelo + dims + re-ingesta + umbral) | ~97% (queda la trazabilidad) |

Compuertas rojas hoy: `embeddings reales`, `retrieval vectorial`, `datos cargados` (0 filas),
`config de despliegue`. A medias: ninguna (`trazabilidad` quedó cerrada en Fase 1).

> Las compuertas son un checklist declarado, no una métrica instrumentada: cada una se puntúa 1 /
> 0,5 / 0 con la evidencia citada en esta sección.

### 9.8 Correcciones aplicadas en Fase 1 (PR #8, 2026-09-23)

Los filtros de metadata apuntaban a campos que la ingesta canónica **nunca escribe** o a un
vocabulario que **no existe** en el corpus: cada filtro devolvía 0 chunks con apariencia de "no hay
información". Medido contra Postgres con el código anterior y el nuevo:

| Filtro | Antes | Después |
|---|---|---|
| `category='Piel'` / `'Uñas'` (etiquetas humanas) | **0 chunks** | resultados, con el filtro **descartado y registrado** (`filters_dropped`) |
| `category='Guías Uñas'` | **0 chunks** | 2 chunks (normalizado a `guias_unas`) |
| `skin_type='seca'` | **0 chunks** (filtraba por la columna `skin_type`, NULL en toda la ingesta) | 4 chunks (`seca` + contenido universal `all`) |
| `domain='diagnostico_capilar'` | **0 chunks** (`metadata->>'domain'` no existe en 5.619/5.619) | 2 chunks |
| `domain='BUSINESS'` (regulatorio) | **0 chunks** | 0 chunks **estricto**: el corpus no tiene documentos regulatorios y **no se relaja** el alcance |

Además: `chunk_id`/`document_id`/`fuente`/`seccion` en el SELECT (citas verificables con la fila de
la BD), el fallback full-text **ya no inventa** `similarity = 0.5`, y `rag_query_logs` se puebla con
**16/16** columnas incluido el umbral realmente usado (antes la traza decía `0.72` con `0.45` en uso).

Evidencia y límites: `docs/rag-audit-2026-09-22/FASE1_ENTREGA.md` y `probes/probe_fase1.js`,
`probes/probe_traza.js`. Suite completa: mismos 73 rojos preexistentes, 0 nuevos (comparado por nombre).

---

*Fin del documento — RAG_ARCHITECTURE.md v1.0 (Ciclo 02) · §9 añadido en la actualización 2026-09-22*