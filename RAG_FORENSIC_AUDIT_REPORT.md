# INFORME FORENSE EXHAUSTIVO DEL RAG — BEAUTY-APP

---

## 1. RESUMEN EJECUTIVO

**Estado actual: ESTADO 6 — RAG FUNCIONAL** (baseline productivo operativo)

El sistema RAG está **desplegado en producción** con arquitectura madura:
- **Corpus canónico**: 5,663 chunks (5,619 canónicos + 44 legacy) con trazabilidad completa
- **Embeddings**: NVIDIA `nv-embedqa-e5-v5` (1024 dims, API NIM gestionada) — regenerados en R6-Recovery
- **Vector Store**: PostgreSQL + `pgvector` con índice HNSW (`m=16, ef_construction=64`) operativo
- **Retrieval**: Vector-only (K=50, threshold 0.45) con MRR 0.7222, R@5 0.6156 reproducido (RUN A ≡ RUN B)
- **Integración LLM**: `search_beauty_knowledge_rag` tool expuesta via `auraToolExecutor` → `geminiService` → Flutter WebSocket
- **Observabilidad**: `ragLogger` con traces estructurados, métricas agregadas, circuit breakers

**Problema principal (cuello de botella)**: **REPRESENTATION-BOUND** — 13 VECTOR_MISS canónicos (8 *semantic representation gaps* intrínsecos a e5-v5 para conceptos ultraespecializados: simetría muscular dinámica, Tyndall, SERS/Raman, electrólisis cross-domain, autofagia, LHA, arquitectura muscular facial, psicología percepción; 5 *retrieval instability* por no bit-exactitud NIM). Ninguna capa externa (FTS, reranking, query expansion, corpus expansion) los recupera sin regresión severa.

**Componentes faltantes críticos**: Evidence Layer (Candidate Builder, Evidence Packet, Provenance, Aggregator, Sufficiency Gate) — diseñados pero **NO IMPLEMENTADOS** (postergados hasta retrieval confidence validado). Sufficiency Gate no calibrado → riesgo false UNSUPPORTED/SUFFICIENT.

---

## 2. ESTRUCTURA DEL PROYECTO RELACIONADA CON RAG

```
/c/beauty-app/
├── backend/
│   ├── src/
│   │   ├── config/
│   │   │   └── db.js                     # Pool PostgreSQL + pgvector
│   │   ├── services/
│   │   │   ├── chunkingService.js        # 14K chars — chunking recursivo + heurístico
│   │   │   ├── embeddingService.js       # 8.7K chars — NVIDIA NIM e5-v5 (query/passage)
│   │   │   ├── ragService.js             # 6.4K chars — pipeline principal searchBeautyKnowledge
│   │   │   ├── beautyKnowledgeService.js # 6.2K chars — API legacy (usa ragService internamente)
│   │   │   ├── metadataEnricher.js       # 14K chars — heurísticas + LLM opcional (DeepSeek)
│   │   │   ├── ragEvaluator.js           # 20K chars — métricas RAGAS-like (P@k, R@k, MRR, faithfulness)
│   │   │   ├── ragLogger.js              # 9K chars — traces estructurados + PostgreSQL opcional
│   │   │   ├── semanticCache.js          # 7.6K chars — cache semántico Redis (cosine ≥0.92)
│   │   │   ├── auraToolExecutor.js       # 8.5K chars — tool search_beauty_knowledge_rag para LLM
│   │   │   ├── geminiService.js          # 43K chars — orquestación AURA + RAG trigger keywords
│   │   │   ├── orchestrator.service.js   # 4.5K chars — multi-agente (ATENA, HERMES, CHRONOS, HESTIA, VALKYRIE)
│   │   │   ├── nemotron.client.js        # 3.6K chars — cliente LLM Nemotron
│   │   │   └── ai/                       # exports de servicios IA
│   │   ├── data/
│   │   │   ├── corpus_canonico/
│   │   │   │   ├── corpus_canonico.json  # 13.8 MB — 5,619 chunks canónicos con metadata rica
│   │   │   │   └── corpus_manifest.json  # 31K chars — 328 entradas, fuentes, versiones
│   │   │   ├── eval/                     # 100+ archivos — datasets, baselines, experimentos R5/R6/R7
│   │   │   └── beauty_corpus/            # (vacío en este momento)
│   │   ├── utils/piiSanitizer.js         # Sanitización PII para logs
│   │   ├── middleware/rateLimiter.js     # Cliente Redis para semanticCache
│   │   └── tests/                        # 15+ archivos test (unit, integración, E2E)
│   ├── scripts/
│   │   ├── ingestCanonicalCorpus.js      # Ingesta completa corpus → BD (embeddings + upsert)
│   │   ├── ingest_json_chunks.js         # Ingesta chunks JSON sueltos
│   │   ├── ingestBeautyKnowledge.js      # Ingesta legacy (tabla aura_knowledge)
│   │   ├── verifyRagSchema.js            # Verificación esquema BD (pgvector, HNSW, tablas)
│   │   └── ragDiagnosticR5c0.js          # Diagnóstico rápido estado RAG
│   ├── migrations/
│   │   ├── 031_aura_pgvector_and_knowledge_table.sql      # tabla aura_knowledge + pgvector
│   │   ├── 035_fix_embedding_dimension_and_hnsw_index.sql # ALTER embedding vector(1024) + HNSW
│   │   └── 046_add_rag_chunk_traceability.sql             # tabla rag_chunk_traceability
│   ├── schema.sql                        # Esquema completo (13K chars)
│   ├── .env / .env.local                 # RAG_DATABASE_URL (Railway pgvector-db / local)
│   └── package.json
├── ai_worker/                            # Python worker biométrico (color_analysis, skin_metrics)
└── frontend/
    └── lib/widgets/aura_multi_agent_chat.dart  # UI Flutter WebSocket → tool search_beauty_knowledge_rag
```

---

## 3. ARQUITECTURA REAL DEL RAG

### Diagrama textual (componentes reales)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FUENTES DE CONOCIMIENTO                            │
├─────────────────────────────────────────────────────────────────────────────┤
│  corpus_canonico.json (5,619 chunks)  │  1,113 JSONs fuente (backend/data/)  │
│  aura_knowledge (tabla legacy, 31)    │  evaluation_dataset_v2.json (15 gold) │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              INGESTA (scripts/)                              │
├─────────────────────────────────────────────────────────────────────────────┤
│  ingestCanonicalCorpus.js                                                    │
│    ├── Lee corpus_canonico.json                                             │
│    ├── Para cada chunk:                                                      │
│    │   ├── embeddingService.generateEmbedding(chunk.content, 'passage')     │
│    │   │   └── NVIDIA NIM nv-embedqa-e5-v5 (1024d, input_type=passage)      │
│    │   ├── UPSERT beauty_knowledge_embeddings                                │
│    │   │   (ON CONFLICT document_id,chunk_id DO UPDATE embedding=NOW())     │
│    │   └── INSERT rag_chunk_traceability                                     │
│    │       (chunk_id, source_table, source_id, chunk_index, content_hash,   │
│    │        embedding_model, created_at)                                     │
│    └── Commit transacción                                                   │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        VECTOR STORE (PostgreSQL + pgvector)                  │
├─────────────────────────────────────────────────────────────────────────────┤
│  Tabla: beauty_knowledge_embeddings                                          │
│    ├── id (PK serial)                                                        │
│    ├── document_id, chunk_id (UNIQUE)                                        │
│    ├── content (TEXT)                                                        │
│    ├── embedding VECTOR(1024)              ← HNSW index (cosine, m=16)      │
│    ├── metadata JSONB (skin_type, category, ingredients, etc.)               │
│    ├── content_hash (SHA256)                                                 │
│    ├── embedding_model ('nvidia/nv-embedqa-e5-v5')                           │
│    └── created_at, updated_at                                                │
│                                                                              │
│  Tabla: rag_chunk_traceability                                               │
│    ├── chunk_id, source_table, source_id, chunk_index                        │
│    ├── content_hash, embedding_model, created_at                             │
│    └── UNIQUE(chunk_id, source_table)                                        │
│                                                                              │
│  Tabla: aura_knowledge (legacy, sin embeddings)                              │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              RETRIEVAL (ragService.js)                       │
├─────────────────────────────────────────────────────────────────────────────┤
│  searchBeautyKnowledge(query, {topK=5, threshold=0.45, category})           │
│    ├── generateEmbedding(query, 'query')  →  NVIDIA NIM (input_type=query)  │
│    ├── SQL:                                                                  │
│    │   SELECT *, 1 - (embedding <=> $1) AS similarity                       │
│    │   FROM beauty_knowledge_embeddings                                     │
│    │   WHERE 1 - (embedding <=> $1) > $2                                    │
│    │   [AND category = $3]                                                  │
│    │   ORDER BY embedding <=> $1                                            │
│    │   LIMIT $4                                                             │
│    ├── Devuelve: [{id, document_id, chunk_id, content, similarity,         │
│    │              category, skin_type, metadata, source, title, ...}]       │
│    └── formatKnowledgeContext(chunks) → string para LLM                     │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         INTEGRACIÓN LLM (geminiService.js)                   │
├─────────────────────────────────────────────────────────────────────────────┤
│  shouldSearchBeautyKnowledge(text) → 60+ keywords trigger                   │
│    ├── Si trigger: searchBeautyKnowledge(query, {topK:5, threshold:0.45})   │
│    ├── formatKnowledgeContext(chunks) → "CONOCIMIENTO TÉCNICO DE BELLEZA"   │
│    ├── Inyecta en system prompt: "--- CONOCIMIENTO TÉCNICO DE BELLEZA (RAG) ---"│
│    ├── LLM (Gemini/DeepSeek) genera respuesta citando fuentes               │
│    └── Tool search_beauty_knowledge_rag expuesta vía auraToolExecutor       │
└─────────────────────┬───────────────────────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         OBSERVABILIDAD Y CACHE                               │
├─────────────────────────────────────────────────────────────────────────────┤
│  ragLogger.logRagQuery(traceData)                                            │
│    ├── trace_id (UUID), user_id_hash, query_sanitized                       │
│    ├── chunks_retrieved, top_score, filters, llm_used                       │
│    ├── latencias: embedding, retrieval, llm, total                          │
│    ├── circuit_breaker_state, tool_calls                                    │
│    └── Escrito a: archivo (prod) / console (dev) + PostgreSQL opcional      │
│                                                                              │
│  semanticCache (Redis)                                                       │
│    ├── findSimilarInCache(queryEmbedding) → cosine ≥ 0.92                   │
│    └── setCache(queryEmbedding, response, metadata)                         │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. COMPONENTES — MATRIZ COMPLETA

| Componente | Existe | Implementado | Integrado | Ejecutable | Ejecutándose | Evidencia | Estado |
|------------|--------|--------------|-----------|------------|--------------|-----------|--------|
| **Ingesta** | ✅ | ✅ | ✅ | ✅ | ❌ (bajo demanda) | `scripts/ingestCanonicalCorpus.js:1-200` | **ACTIVO** |
| **Parser/Loader** | ✅ | ✅ | ✅ | ✅ | ❌ | `ingestCanonicalCorpus.js:45-80` (lee JSON) | **ACTIVO** |
| **Chunker** | ✅ | ✅ | ⚠️ | ✅ | ❌ | `chunkingService.js` (14K chars) — **no usado en ingesta canónica** | **HUÉRFANO PARCIAL** |
| **Metadata Enricher** | ✅ | ✅ | ⚠️ | ✅ | ❌ | `metadataEnricher.js:312-360` — **no conectado a ingesta** | **HUÉRFANO** |
| **Embeddings** | ✅ | ✅ | ✅ | ✅ | ✅ (en queries) | `embeddingService.js:1-150` — NVIDIA NIM e5-v5 | **ACTIVO** |
| **Vector Store** | ✅ | ✅ | ✅ | ✅ | ✅ | `db.js`, migraciones 031/035/046, `schema.sql` | **ACTIVO** |
| **Retriever** | ✅ | ✅ | ✅ | ✅ | ✅ | `ragService.js:45-120` — `searchBeautyKnowledge` | **ACTIVO** |
| **Reranker** | ❌ | ❌ | ❌ | ❌ | ❌ | No existe (probado en R6-C11, rechazado) | **AUSENTE** |
| **Context Builder** | ✅ | ✅ | ✅ | ✅ | ✅ | `ragService.js:180-220` — `formatKnowledgeContext` | **ACTIVO** |
| **Prompt Builder** | ✅ | ✅ | ✅ | ✅ | ✅ | `geminiService.js:290-310` — inyección RAG en system prompt | **ACTIVO** |
| **LLM** | ✅ | ✅ | ✅ | ✅ | ✅ | `geminiService.js` (Gemini/DeepSeek) + `nemotron.client.js` | **ACTIVO** |
| **API/Tools** | ✅ | ✅ | ✅ | ✅ | ✅ | `auraToolExecutor.js:107-117` — `search_beauty_knowledge_rag` | **ACTIVO** |
| **UI** | ✅ | ✅ | ✅ | ✅ | ✅ | `aura_multi_agent_chat.dart:103-104` — status "Consultando guía técnica" | **ACTIVO** |
| **Evaluación** | ✅ | ✅ | ⚠️ | ✅ | ❌ (bajo demanda) | `ragEvaluator.js` + 30+ datasets en `data/eval/` | **ACTIVO (OFFLINE)** |
| **Monitoring/Logs** | ✅ | ✅ | ✅ | ✅ | ✅ | `ragLogger.js` + `semanticCache.js` + circuit breakers | **ACTIVO** |
| **Evidence Layer** | ⚠️ | ❌ | ❌ | ❌ | ❌ | `r6_final_closure_report.json:202-210` — **DISEÑADO, NO IMPLEMENTADO** | **BLOQUEADO** |
| **Sufficiency Gate** | ⚠️ | ❌ | ❌ | ❌ | ❌ | `ragEvaluator.js` no lo implementa; `r6_final_closure_report:194-196` | **BLOQUEADO** |

---

## 5. FUENTES DE CONOCIMIENTO — INVENTARIO COMPLETO

| Fuente | Ubicación | Tipo | Tamaño | Formato | Fecha | Origen | Procesada | Chunkificada | Embeddings | Indexada | Recuperable | Clasificación |
|--------|-----------|------|--------|---------|-------|--------|-----------|--------------|------------|----------|-------------|---------------|
| **corpus_canonico.json** | `src/data/corpus_canonico/` | Canónico | 5,619 chunks / 13.8 MB | JSON | 2026-08-13 | Generado automático (commits 3c8df30d7, 224aea91f, fae5dd169) | ✅ | ✅ (5,619) | ✅ (5,619) | ✅ | ✅ | **A. Integrada** |
| **1,113 JSONs fuente** | `backend/data/corpus/` | Primaria | 1,113 archivos | JSON | 2026-08-02 a 2026-08-14 | Generación automática por dominio | ✅ | ✅ (fuente del canónico) | ✅ | ✅ | ✅ | **A. Integrada** |
| **aura_knowledge (legacy)** | BD tabla `aura_knowledge` | Legacy | ~31 filas | SQL/BD | 2026-08-02 | Migración 031 | ✅ | ⚠️ (no chunkificada estándar) | ❌ (sin embedding col) | ❌ | ❌ | **C. Procesada parcialmente** |
| **evaluation_dataset_v2.json** | `src/data/eval/` | Gold/Eval | 15 queries / 58 gold chunks | JSON | 2026-08-13 | Anotación humana experta | ✅ | ✅ (expected_chunks) | ❌ | ❌ | ✅ (para eval) | **A. Integrada (eval)** |
| **identity_map_v2.json** | `src/data/eval/` | Mapeo | 48K chars | JSON | 2026-08-13 | Anotación humana | ✅ | ✅ | ❌ | ❌ | ✅ (para eval) | **A. Integrada (eval)** |
| **seed_beauty_knowledge.sql** | `sql/` | Seed | Solo contenido | SQL | Anterior a R6 | Backup manual | ❌ | ❌ | ❌ | ❌ | ❌ | **E. Referenciada, sin vectores** |

**Nota crítica**: La tabla `aura_knowledge` (migración 031) **NO** es `aura_knowledge_chunks`. No existe tabla `aura_knowledge_chunks` ni `beauty_knowledge_embeddings` en el código actual — la tabla real es `beauty_knowledge_embeddings` (ver migración 035 y `ragService.js`). El grep confirmó 0 matches para nombres asumidos.

---

## 6. CHUNKING — CONFIGURACIÓN EXACTA

### chunkingService.js (archivo principal, 14,015 chars, 400+ líneas)

```javascript
// Configuración real (líneas ~50-80):
const CHUNK_CONFIG = {
  // Estrategia principal: Recursivo por separadores jerárquicos
  separators: [
    '\n\n## ',      // Encabezados H2
    '\n\n### ',     // Encabezados H3
    '\n\n',         // Párrafos
    '\n',           // Líneas
    '. ',           // Oraciones
    ' ',            // Palabras
    ''              // Caracteres
  ],
  chunk_size: 1200,        // Target tokens aprox (no chars)
  chunk_overlap: 200,      // Overlap para preservar contexto
  max_chunk_size: 2000,    // Hard limit
  min_chunk_size: 100,     // Descarta chunks muy pequeños
  
  // Heurísticas específicas dominio belleza:
  preserve_structure: true,     // Mantiene encabezados en chunk
  merge_small_chunks: true,     // Fusiona chunks < min_chunk_size
  respect_boundaries: true,     // No corta en medio de listas/tablas
};

// Algoritmo: RecursiveCharacterTextSplitter-like (implementación propia)
// 1. Split por separadores en orden jerárquico
// 2. Merge chunks adyacentes si < min_chunk_size
// 3. Trunca chunks > max_chunk_size respetando boundaries
// 4. Añade metadata: document_id, chunk_index, content_hash, title, section
```

**Evidencia de uso**: El `chunkingService.js` **NO se usa en `ingestCanonicalCorpus.js`** — la ingesta canónica consume chunks **ya generados** en `corpus_canonico.json`. El chunkingService parece ser para ingesta ad-hoc de documentos nuevos (PDF, web, etc.) pero no está conectado al pipeline canónico.

**Chunking real del corpus canónico**: Generado externamente (commits auto-generados), cada entrada en `corpus_canonico.json` ya tiene `chunk_id`, `content_hash`, `metadata` completa. Tamaño observado: ~800-2000 chars por chunk, con overlap semántico (secciones completas).

---

## 7. INVENTARIO DE CHUNKS

| Métrica | Valor | Evidencia |
|---------|-------|-----------|
| **Documentos totales (corpus canónico)** | 11 dominios (colorimetria_capilar_tinte, cuidado_corporal_y_spa, tendencias_belleza_virales, etc.) | `corpus_manifest.json` — 328 entradas `domain` |
| **Chunks totales en BD** | **5,663** | `r6_recovery1_embedding_forensics.json:9` — `total: 5663` |
| **Chunks canónicos** | **5,619** | `corpus_canonico.json:4` — `"total_chunks": 5619` |
| **Chunks legacy (hash-only chunk_id)** | **44** | `r6_recovery1:19,49` — `legacy_hash_chunk_ids: 31` + diferencia 5663-5619=44 |
| **Chunks con embedding (non-null)** | **5,663** (0 NULL) | `r6_recovery1:10-11` — `nulls: 5663` → tras R6-Recovery: 0 NULL |
| **Chunks indexados (HNSW)** | **5,663** | `r6_recovery1:16` — índice `idx_beauty_knowledge_embedding_hnsw` presente |
| **Chunks recuperables** | **5,663** | `ragService.js` consulta sin filtros restrictivos |
| **Chunks huérfanos** | **0** | Traceability table `rag_chunk_traceability` cubre 100% |
| **Chunks duplicados (content_hash)** | **5 grupos** | `r6_recovery1:12` — `dup_chunk_id_groups: 5` |
| **Chunks sin metadata completa** | **0** | `corpus_canonico.json` tiene metadata rica en todos |
| **Chunks inválidos** | **0** | Validado en R6-Recovery |

**Distribución por dominio** (aproximado desde manifest 328 entradas):
- `colorimetria_capilar_tinte`: ~500 chunks
- `cuidado_corporal_y_spa`: ~400 chunks  
- `tendencias_belleza_virales`: ~350 chunks
- Resto distribuidos en 8 dominios más

---

## 8. CHUNKS FALTANTES — MATRIZ DETALLADA

| Fuente | Documento | Procesado | Chunks | Embeddings | Indexado | Recuperable | Problema |
|--------|-----------|-----------|--------|------------|----------|-------------|----------|
| corpus_canonico.json | 11 dominios | ✅ | 5,619 | ✅ | ✅ | ✅ | **NINGUNO** |
| 1,113 JSONs fuente | 1,113 archivos | ✅ | (fuente) | N/A | N/A | N/A | Fuente cruda, no directa |
| aura_knowledge (legacy) | ~31 filas | ⚠️ | 0 (no chunkificados) | ❌ | ❌ | ❌ | Tabla legacy sin pipeline chunking |
| evaluation gold | 15 queries | ✅ | 58 expected_chunks | ❌ | ❌ | ✅ (eval only) | Solo para evaluación, no en BD principal |

**Chunks que DEBERÍAN existir pero FALTAN**:
- **Legacy → Canónico**: 31 filas `aura_knowledge` no migradas a `beauty_knowledge_embeddings` (tienen `chunk_id` hash puro, sin embedding). `r6_recovery1:19,49` confirma 31 `legacy_hash_chunk_ids` con contenido en BD pero sin vector.
- **Cobertura conceptual**: 13 VECTOR_MISS (8 representation-bound + 5 instability) — **no son chunks faltantes**, son **conceptos que el embedding no ancla** (ver sección 17).

---

## 9. EMBEDDINGS — AUDITORÍA PROFUNDA

| Parámetro | Valor | Evidencia |
|-----------|-------|-----------|
| **Proveedor** | NVIDIA NIM (managed API) | `embeddingService.js:15-25`, `r6_final_closure:13` |
| **Modelo** | `nvidia/nv-embedqa-e5-v5` | `embeddingService.js:18`, `r6_final_closure:13,212` |
| **Dimensión** | **1024** | Migración 035: `ALTER COLUMN embedding TYPE vector(1024)` |
| **Input types** | `query` / `passage` (native) | `embeddingService.js:45-60` — `input_type` param |
| **API endpoint** | Variable `NVIDIA_NIM_URL` / `NVIDIA_API_KEY` | `.env.example` no lo incluye — configurado en Railway |
| **Generación** | `embeddingService.js:generateEmbedding(text, options)` | Llamado desde `ingestCanonicalCorpus.js` y `ragService.js` |
| **Almacenamiento** | Columna `embedding VECTOR(1024)` en `beauty_knowledge_embeddings` | Migración 035, `schema.sql` |
| **Identificación** | `embedding_model` column = `'nvidia/nv-embedqa-e5-v5'` | `rag_chunk_traceability.embedding_model`, `beauty_knowledge_embeddings.embedding_model` |
| **Versión modelo** | **NIM managed** → **NO versionable localmente** | `r6_final_closure:106,214` — "NIM no expone pesos, no bit-exacto entre llamadas" |
| **Compatibilidad dim** | ✅ 1024d = HNSW vector(1024) | Migración 035 confirmada |

**Inconsistencia crítica detectada**:
- El modelo NVIDIA NIM **no garantiza bit-exactitud** entre llamadas (managed API, posible drift silencioso)
- `r6_final_closure:170` — "Inestabilidad query-embedding NIM: misma query produce embeddings no idénticos → frontier top-200 fluctúa (5 misses borderline afectados)"
- **No existe mecanismo de versionado/regeneración/invalidación/migración** de embeddings — solo re-ingesta completa via `ingestCanonicalCorpus.js`

---

## 10. VECTOR STORE — AUDITORÍA COMPLETA

| Aspecto | Detalle | Evidencia |
|---------|---------|-----------|
| **Tecnología** | PostgreSQL + `pgvector` extension | `db.js`, migración 031: `CREATE EXTENSION IF NOT EXISTS vector` |
| **Tabla principal** | `beauty_knowledge_embeddings` | Migración 035, `ragService.js:55` |
| **Columna vector** | `embedding VECTOR(1024)` | Migración 035: `ALTER COLUMN embedding TYPE vector(1024)` |
| **Índice** | **HNSW** `idx_beauty_knowledge_embedding_hnsw` (m=16, ef_construction=64, cosine) | Migración 035: `CREATE INDEX ... USING hnsw (embedding vector_cosine_ops)` |
| **Métrica** | Cosine similarity (`1 - (embedding <=> query_vec)`) | `ragService.js:70-85`, migración 035 `vector_cosine_ops` |
| **Persistencia** | ✅ Tabla regular PostgreSQL, WAL, backup | Docker volume `beauty-postgres` (845c7a4...) |
| **Datos actuales** | 5,663 filas, 0 NULL embeddings, 45 MB (sin vectores: ~22 MB) | `r6_recovery1:9-11,20` |
| **Accesibilidad** | ✅ Pool `pg` en `db.js`, Railway pgvector-db / local | `.env`: `RAG_DATABASE_URL` |
| **Carga/consulta** | ✅ `ragService.js` usa `pool.query` con parámetros | `ragService.js:65-95` |
| **Actualización** | ✅ UPSERT en ingesta (`ON CONFLICT DO UPDATE`) | `ingestCanonicalCorpus.js:120-140` |
| **Trazabilidad** | ✅ `rag_chunk_traceability` (migración 046) | Migración 046, `ingestCanonicalCorpus.js:150-170` |

**Estado**: **POBLADO Y OPERACIONAL** — No confundir "configurado" con "poblado": 5,663 vectores 1024d + HNSW funcional.

---

## 11. RETRIEVAL — FLUJO Y CONFIGURACIÓN

```javascript
// ragService.js:45-120 — searchBeautyKnowledge(query, options)
async function searchBeautyKnowledge(query, options = {}) {
  const { topK = 5, threshold = 0.45, category } = options;
  
  // 1. Embedding de query (input_type='query')
  const queryEmbedding = await generateEmbedding(query, { input_type: 'query' });
  
  // 2. Consulta vectorial pgvector (cosine distance <=> )
  const sql = `
    SELECT 
      id, document_id, chunk_id, content, 
      1 - (embedding <=> $1) AS similarity,
      category, skin_type, metadata, source, title, 
      content_hash, embedding_model, created_at
    FROM beauty_knowledge_embeddings
    WHERE 1 - (embedding <=> $1) > $2
    ${category ? 'AND category = $3' : ''}
    ORDER BY embedding <=> $1
    LIMIT $4
  `;
  
  // 3. Parámetros: [queryEmbedding, threshold, category?, topK]
  // 4. Devuelve array de chunks con similarity score
}
```

**Configuración efectiva**:
- `topK`: **5** (default en `geminiService.js:292,611` y `auraToolExecutor.js:221`)
- `threshold`: **0.45** (default en `geminiService.js`) — más permisivo que 0.65 de evaluación
- `category filter`: Opcional (string exact match en metadata.category)
- **NO hay**: BM25, hybrid search, reranker, deduplicación post-retrieval
- **NO hay**: Query expansion, HyDE, multi-query (probados en R6-C11, rechazados)

**Evidencia de funcionamiento**: 
- Baseline R6: MRR 0.7222, R@5 0.6156, R@10 0.6545, R@20 0.7156
- Latencia retrieval: ~200-500ms p50 (embedding API + pgvector)
- 13 VECTOR_MISS de 58 gold chunks (22.4% miss rate)

---

## 12. CONTEXT BUILDING — CÓMO LLEGA LA INFO AL LLM

```javascript
// ragService.js:180-220 — formatKnowledgeContext(chunks)
function formatKnowledgeContext(chunks) {
  if (!chunks || chunks.length === 0) return '';
  
  return chunks.map((chunk, i) => {
    const meta = chunk.metadata || {};
    const sourceLine = chunk.source ? ` [Fuente: ${chunk.source}]` : '';
    const catLine = chunk.category ? ` [Categoría: ${chunk.category}]` : '';
    return `[Chunk ${i+1}]${sourceLine}${catLine}\n${chunk.content}`;
  }).join('\n\n---\n\n');
}

// geminiService.js:290-310 — Inyección en prompt
if (shouldSearchBeautyKnowledge(userMessageText)) {
  const beautyChunks = await searchBeautyKnowledge(userMessageText, { 
    topK: 5, threshold: 0.45 
  });
  const beautyKnowledge = formatKnowledgeContext(beautyChunks);
  // Se inyecta en system prompt como sección:
  // "--- CONOCIMIENTO TÉCNICO DE BELLEZA (RAG) ---\n${beautyKnowledge}"
}
```

**Parámetros de contexto**:
- **Max chunks**: 5 (topK hardcoded en geminiService)
- **Longitud contexto**: Variable (~500-2000 chars por chunk × 5 = 2.5K-10K chars)
- **Truncamiento**: No hay truncamiento explícito en `formatKnowledgeContext` — depende de LLM context window
- **Orden**: Por similarity descendente (más relevante primero)
- **Separación**: `\n\n---\n\n` entre chunks
- **Metadata incluida**: source, category, (metadata JSONB no se expone completo)
- **Citas**: LLM instruido a citar resoluciones/números exactos del RAG (`systemPrompts.js` + `geminiService.js` BASE_SYSTEM_INSTRUCTION)

**Verificación crítica**: **SÍ, el contexto llega al LLM** — `geminiService.js` inyecta RAG en system prompt y `auraToolExecutor` expone tool `search_beauty_knowledge_rag` para function calling. Flutter UI muestra status "Consultando la guía técnica de belleza..." (`aura_multi_agent_chat.dart:103-104`).

---

## 13. LLM — MODELO E INTEGRACIÓN

| Aspecto | Detalle | Evidencia |
|---------|---------|-----------|
| **Modelo primario** | Gemini (via `@google/generative-ai`) | `geminiService.js:2-3`, `GEMINI_FALLBACK_MODEL=gemini-3.1-flash-lite` |
| **Modelo fallback** | DeepSeek (`deepseek-v4-flash`) | `geminiService.js:4-6`, `DEEPSEEK_API_KEY` en .env |
| **Modelo alternativo** | Nemotron (NVIDIA) | `nemotron.client.js`, `orchestrator.service.js` |
| **Integración RAG** | System prompt injection + Function Calling tool | `geminiService.js:290-310`, `auraToolExecutor.js:107-117` |
| **Contexto RAG** | Sección obligatoria "--- CONOCIMIENTO TÉCNICO DE BELLEZA (RAG) ---" | `geminiService.js:100-130` BASE_SYSTEM_INSTRUCTION |
| **Regla de oro RAG** | "Esa sección es la FUENTE DE VERDAD... RAG gana SIEMPRE" | `geminiService.js:115-125` |
| **Formato respuesta** | Estructurado (Estilo Recomendado, Tratamiento, Profesional, Precio, ID) | `geminiService.js:108-118` |

---

## 14. EJECUCIÓN REAL — COMANDOS Y PROCESOS

| Comando/Proceso | Descripción | Estado |
|-----------------|-------------|--------|
| **Ingesta completa** | `node scripts/ingestCanonicalCorpus.js` | ✅ Ejecutable, probado en R6-Recovery |
| **Ingesta chunks sueltos** | `node scripts/ingest_json_chunks.js <dir>` | ✅ Ejecutable |
| **Ingesta legacy** | `node scripts/ingestBeautyKnowledge.js` | ✅ Ejecutable (tabla `aura_knowledge`) |
| **Verificación esquema** | `node scripts/verifyRagSchema.js` | ✅ Ejecutable — valida pgvector, HNSW, tablas |
| **Diagnóstico rápido** | `node scripts/ragDiagnosticR5c0.js` | ✅ Ejecutable — health check RAG |
| **Evaluación RAG** | `ragEvaluator.runEvaluationSuite(dataset, {topK, generateAnswers})` | ✅ Ejecutable — usado en 30+ experimentos R5/R6 |
| **Servicio backend** | `npm start` / `node src/index.js` | ✅ En producción (Railway) |
| **Worker Python** | `python ai_worker/main.py` (puerto 8000) | ✅ Para análisis biométrico (ATENA), NO para RAG |
| **WebSocket Flutter** | `ws://host:3000` → `geminiService` → `auraToolExecutor` | ✅ En producción |

**Logs y evidencia de ejecución**:
- `rag_traces.log` (via `ragLogger.js`) — traces estructurados por query
- `rag_query_logs` table (PostgreSQL opcional) — métricas agregadas
- 30+ archivos `evaluation_real_*.json` en `data/eval/` — ejecuciones reales con métricas
- `r6_final_closure_report.json` — cierre fase R6 con baseline validado

**NO hay**: Cron jobs, workers dedicados RAG, procesos automáticos de re-embedding. Todo es **bajo demanda** (query-time) o **manual** (ingesta).

---

## 15. PRUEBAS — EXISTENTES Y REALIZADAS

| Test Suite | Archivo | Cobertura | Estado |
|------------|---------|-----------|--------|
| **Unit: auraToolExecutor** | `src/tests/auraToolExecutor.test.js` | Tool definitions, search_beauty_knowledge_rag mock | ✅ Pasa |
| **Unit: ragLogger** | `src/tests/ragLogger.test.js` | sanitize, formatToolCalls, logRagQuery | ✅ Pasa |
| **Unit: semanticCache** | `src/tests/semanticCache.test.js` | cosineSimilarity, cache key, find/set | ✅ Pasa |
| **Integración: geminiFallback** | `src/tests/geminiFallback.test.js` | RAG trigger, fallback DeepSeek, tool calls | ✅ Pasa |
| **Integración: ragEvaluator** | `src/tests/ragEvaluator.test.js` | Retrieval metrics, faithfulness, answer relevancy | ✅ Pasa |
| **E2E: fase5** | `src/tests/fase5_e2e_integration.test.js` | Flujo completo WebSocket → AURA → tools → RAG | ✅ Pasa |
| **Sprint 2-4 agents** | `src/tests/sprint{2,3,4}_agents.test.js` | Integración multi-agente + RAG tool | ✅ Pasa |

**Pruebas realizadas (evidencia histórica)**:
- **R5**: Baseline histórico perdido (embeddings borrados), recuperado en R6-Recovery
- **R6-C1 a C13**: 13 sub-ciclos experimentales documentados en `data/eval/r6c*.json`
- **R6-Recovery 1-3**: Forensics embedding loss, rebuild, drift analysis
- **R7 Stage 3**: Production deployment report (`r7_stage3_production_deployment_report.json`)

**Métricas validadas (RUN A ≡ RUN B)**:
- MRR: **0.7222**
- R@5: **0.6156**
- R@10: **0.6545**
- R@20: **0.7156**
- R@50: **0.8011**
- Vector misses: **13/58** (22.4%)
- Latencia p50: **~500ms**

---

## 16. CÓDIGO HUÉRFANO / LEGACY / DUPLICADO

| Componente | Archivo | Clasificación | Evidencia |
|------------|---------|---------------|-----------|
| **chunkingService.js** | `src/services/chunkingService.js` | **HUÉRFANO PARCIAL** | Implementado (14K chars) pero **no usado en ingesta canónica** — solo para ingesta ad-hoc futura |
| **metadataEnricher.js** | `src/services/metadataEnricher.js` | **HUÉRFANO** | Enriquecimiento heurístico+LLM completo, **no conectado a pipeline ingesta** |
| **beautyKnowledgeService.js** | `src/services/beautyKnowledgeService.js` | **LEGACY WRAPPER** | Exporta `searchBeautyKnowledge` que **delega a ragService.js** — mantener para compatibilidad |
| **aura_knowledge (tabla)** | Migración 031, BD | **LEGACY** | Tabla original sin embeddings, 31 filas con chunk_id hash — no migrada a canónico |
| **ingestBeautyKnowledge.js** | `scripts/ingestBeautyKnowledge.js` | **LEGACY** | Ingesta a tabla `aura_knowledge` (sin embeddings) |
| **aiOrchestrator.js** | `src/services/aiOrchestrator.js` | **LEGACY** | Solo `processBiometricScan` → Python worker, **no relacionado con RAG** |
| **nemotron.client.js** | `src/services/ai/nemotron.client.js` | **PARCIALMENTE ACTIVO** | Cliente LLM alternativo, no usado en flujo RAG principal |
| **systemPrompts.js** | `src/services/ai/systemPrompts.js` | **ACTIVO** | Prompts base, importado por geminiService |

**Implementaciones duplicadas**: 
- `beautyKnowledgeService.searchBeautyKnowledge` → wrapper de `ragService.searchBeautyKnowledge` (intencional para compatibilidad)
- `embeddingService.generateEmbedding` usado por: `ragService`, `ingestCanonicalCorpus`, `ragEvaluator`, `semanticCache` — **único generador, correcto**

---

## 17. MATRIZ DE INTEGRACIÓN — CADENA COMPLETA

| Componente | Existe | Conectado al anterior | Conectado al siguiente | Ejecutable | Estado |
|------------|--------|----------------------|------------------------|------------|--------|
| Fuentes (JSONs) | ✅ | — | ✅ (ingestCanonicalCorpus) | ✅ | **OK** |
| Ingesta (script) | ✅ | ✅ (lee JSONs) | ✅ (llama embeddingService) | ✅ | **OK** |
| Embedding Service | ✅ | ✅ (recibe texto) | ✅ (devuelve vector → UPSERT) | ✅ | **OK** |
| Vector Store (BD) | ✅ | ✅ (recibe UPSERT) | ✅ (consultado por ragService) | ✅ | **OK** |
| Retriever (ragService) | ✅ | ✅ (query → embedding → SQL) | ✅ (devuelve chunks → formatKnowledgeContext) | ✅ | **OK** |
| Context Builder | ✅ | ✅ (recibe chunks) | ✅ (string → geminiService) | ✅ | **OK** |
| Prompt Builder (geminiService) | ✅ | ✅ (recibe context string) | ✅ (inyecta en system prompt → LLM) | ✅ | **OK** |
| LLM (Gemini/DeepSeek) | ✅ | ✅ (recibe prompt + RAG) | ✅ (respuesta → usuario) | ✅ | **OK** |
| Tool Executor (auraToolExecutor) | ✅ | ✅ (expone search_beauty_knowledge_rag) | ✅ (llamado por LLM function calling) | ✅ | **OK** |
| UI (Flutter WebSocket) | ✅ | ✅ (recibe chat_message + aura_status) | — | ✅ | **OK** |
| **Evidence Layer** | ⚠️ Diseñado | ❌ (no conectado a retriever) | ❌ (no conectado a LLM) | ❌ | **BLOQUEADO** |
| **Sufficiency Gate** | ⚠️ Diseñado | ❌ | ❌ | ❌ | **BLOQUEADO** |

**La cadena está COMPLETA y FUNCIONAL desde Fuentes → LLM**. El único gap es la **Evidence Layer post-retrieval** (diseñada en R6-C1 a C4, postergada en R6-C10, C12, C13).

---

## 18. MATRIZ DE FALTANTES — PRIORIZADA

| Elemento faltante | Impacto | Evidencia | Dependencia | Prioridad | Acción necesaria |
|-------------------|---------|-----------|-------------|-----------|------------------|
| **Evidence Packet / Provenance** | CRÍTICO | `r6_final_closure:202-209` — diseñados, no implementados | Retrieval confidence calibrado | **CRÍTICO** | Implementar `EvidencePacket` class con `chunk_id, score, source, metadata`; conectar a `ragService` output |
| **Sufficiency Gate calibrado** | CRÍTICO | `r6_final_closure:194-196,156` — "no validado → riesgo false UNSUPPORTED/SUFFICIENT" | Evidence Packet + datos producción | **CRÍTICO** | Calibrar umbrales con 1000+ queries reales (R7 objetivo) |
| **Aggregator multi-chunk** | ALTO | `r6_final_closure:207` — "postergado hasta representation improves" | Evidence Packet + Sufficiency Gate | **ALTO** | Diseñar aggregator que fusione evidence packets sin alucinar |
| **Candidate Builder** | ALTO | `r6_final_closure:203` — "B_DESIGNED_NOT_IMPLEMENTED" | Retrieval estable | **ALTO** | Implementar candidate pool expansion + grouping (R6-C4 probado, marginal) |
| **Migración legacy aura_knowledge → canónico** | MEDIO | `r6_recovery1:19,49` — 31 filas legacy sin embedding | Script de migración | **MEDIO** | Ejecutar migración única: leer aura_knowledge, chunkificar, embedder, upsert |
| **ChunkingService integración** | MEDIO | `chunkingService.js` huérfano | Nueva ingesta documentos | **MEDIO** | Conectar a pipeline ingesta ad-hoc (PDF, web) |
| **MetadataEnricher integración** | MEDIO | `metadataEnricher.js` huérfano | Ingesta canónica/ad-hoc | **MEDIO** | Llamar `enrichChunkMetadata` durante ingesta |
| **Hybrid Dense+Sparse (opcional)** | BAJO | `r6_final_closure:185-192` — "+0.033 MRR determinista, +300ms, reversible" | Director approval | **BAJO** | Añadir FTS tsvector + RRF fusion en `ragService` (opcional) |
| **Reranker cross-encoder** | BAJO | `r6_final_closure:137,163` — rechazado (fuera candidate pool) | — | **BAJO** | No implementar (confirmado inefectivo) |
| **Fine-tuning / Projection Head** | BAJO | `r6_final_closure:106-109,216` — bloqueado (NIM sin pesos) | Acceso pesos modelo | **BAJO** | Solo teórico: Projection Head post-NVIDIA (fuera producción) |

---

## 19. DIAGRAMA DEL FLUJO REAL (FUENTE → RESPUESTA)

```
/c/beauty-app/backend/src/data/corpus_canonico/corpus_canonico.json (5,619 chunks)
                              │
                              ▼
scripts/ingestCanonicalCorpus.js (node)
                              │
                              ▼
embeddingService.generateEmbedding(content, {input_type:'passage'})
                              │
                              ▼
NVIDIA NIM: nvidia/nv-embedqa-e5-v5 (1024d, managed API)
                              │
                              ▼
UPSERT beauty_knowledge_embeddings
  (id, document_id, chunk_id, content, embedding VECTOR(1024), 
   metadata JSONB, content_hash, embedding_model, created_at, updated_at)
  ON CONFLICT (document_id, chunk_id) DO UPDATE SET embedding=EXCLUDED.embedding, updated_at=NOW()
                              │
                              ▼
INSERT rag_chunk_traceability
  (chunk_id, source_table='beauty_knowledge_embeddings', source_id, chunk_index,
   content_hash, embedding_model='nvidia/nv-embedqa-e5-v5', created_at)
                              │
                              ▼
PostgreSQL + pgvector (Railway pgvector-db / local)
  Table: beauty_knowledge_embeddings (5,663 rows, 0 NULL embeddings)
  Index: idx_beauty_knowledge_embedding_hnsw (HNSW, m=16, ef=64, cosine)
                              │
                              ▼
ragService.searchBeautyKnowledge(query, {topK=5, threshold=0.45, category?})
  │
  ├── generateEmbedding(query, {input_type:'query'}) → NVIDIA NIM (query)
  │
  ├── SQL: SELECT *, 1-(embedding <=> $1) AS similarity 
  │        FROM beauty_knowledge_embeddings 
  │        WHERE 1-(embedding <=> $1) > $2 [AND category=$3] 
  │        ORDER BY embedding <=> $1 LIMIT $4
  │
  ▼
Chunks[] con {id, document_id, chunk_id, content, similarity, category, metadata, source, title}
                              │
                              ▼
ragService.formatKnowledgeContext(chunks) → String contextual
                              │
                              ▼
geminiService.processAssistantMessage(userId, message)
  │
  ├── shouldSearchBeautyKnowledge(message) → 60+ keywords trigger
  │
  ├── searchBeautyKnowledge(message, {topK:5, threshold:0.45})
  │
  ├── formatKnowledgeContext(chunks) → "CONOCIMIENTO TÉCNICO DE BELLEZA"
  │
  ├── System Prompt Injection:
  │   "--- CONOCIMIENTO TÉCNICO DE BELLEZA (RAG) ---\n{context}"
  │   "Esta sección es la FUENTE DE VERDAD... RAG gana SIEMPRE"
  │
  ├── LLM Call (Gemini/DeepSeek/Nemotron) con tools [search_beauty_knowledge_rag]
  │
  ▼
Respuesta estructurada con citas + tool calls si aplica
                              │
                              ▼
auraToolExecutor.executeAuraTool('search_beauty_knowledge_rag', args, userId)
  │
  ├── searchBeautyKnowledge(args.queryText, args.category)
  │
  ▼
Return {status: 'success', knowledge: chunks[]}
                              │
                              ▼
WebSocket → Flutter (aura_multi_agent_chat.dart)
  Status: "📖 Consultando la guía técnica de belleza..."
  Message: respuesta AURA con citas + redirección módulo ideas
                              │
                              ▼
ragLogger.logRagQuery(traceData) [async, no bloqueante]
  trace_id, user_id_hash, query_sanitized, chunks_retrieved, top_score,
  llm_used, latencias, circuit_breaker_state, tool_calls
  → archivo/console + PostgreSQL opcional (rag_query_logs)
                              │
                              ▼
semanticCache.setCache(queryEmbedding, response, metadata) [Redis]
```

---

## 20. ESTADO FINAL DEL RAG

### **ESTADO 6 — RAG FUNCIONAL**

**Justificación con evidencia**:

✅ **Fuentes integradas**: corpus_canonico.json (5,619 chunks) + 1,113 JSONs fuente → ingesta funcional  
✅ **Ingesta funcional**: `ingestCanonicalCorpus.js` ejecuta pipeline completo end-to-end  
✅ **Chunking**: Chunks existen con metadata rica, content_hash, trazabilidad (5,663 en BD)  
✅ **Embeddings**: 5,663 vectores 1024d NVIDIA e5-v5, 0 NULL, regenerados en R6-Recovery  
✅ **Vector Store**: PostgreSQL + pgvector + HNSW índice operativo  
✅ **Retrieval funcional**: `searchBeautyKnowledge` recupera chunks con similarity scores, MRR 0.7222 reproducido  
✅ **Contexto llega al LLM**: System prompt injection + function calling tool `search_beauty_knowledge_rag`  
✅ **RAG integrado a la app**: Flutter WebSocket → geminiService → auraToolExecutor → ragService  
✅ **Observabilidad**: ragLogger traces, semanticCache, circuit breakers, métricas agregadas  

❌ **NO Estado 7**: Evidence Layer (Candidate Builder, Evidence Packet, Aggregator, Sufficiency Gate) **diseñados pero NO IMPLEMENTADOS** — postergados hasta retrieval confidence validado  
❌ **NO Estado 8**: Sin mecanismos de actualización automática, re-embedding programado, ni validación continua en producción (R7 Stage 3 iniciado para esto)

---

## 21. BLOQUEOS CRÍTICOS (PRIORIZADOS)

| # | Bloqueo | Severidad | Evidencia | Acción Inmediata |
|---|---------|-----------|-----------|------------------|
| 1 | **Evidence Layer no implementado** | CRÍTICO | `r6_final_closure:202-210` — B_DESIGNED_NOT_IMPLEMENTED / C_POSTPONED | Implementar `EvidencePacket` + `CandidateBuilder` en `ragService` output |
| 2 | **Sufficiency Gate no calibrado** | CRÍTICO | `r6_final_closure:156,194-196` — "riesgo false UNSUPPORTED/SUFFICIENT" | Recolectar 1000+ queries producción (R7) para calibrar umbrales |
| 3 | **13 VECTOR_MISS irrecuperables (8 representation-bound)** | ALTO | `r6_final_closure:148-151,169` — conceptos ultraespecializados no anclados por e5-v5 | Aceptar límite; documentar gaps; no prometer cobertura total |
| 4 | **Inestabilidad query-embedding NIM (5 misses borderline)** | ALTO | `r6_final_closure:170` — "misma query produce embeddings no idénticos" | Evaluar cache semántico para estabilizar; documentar varianza |
| 5 | **Legacy aura_knowledge no migrado (31 filas)** | MEDIO | `r6_recovery1:19,49` — chunk_id hash puro, contenido en BD sin vector | Script migración única legacy → canónico |
| 6 | **chunkingService + metadataEnricher huérfanos** | MEDIO | Código completo sin conectar a pipeline | Integrar en ingesta ad-hoc o deprecarlos |

---

## 22. RECOMENDACIONES

### INMEDIATAS (Para completar funcionamiento RAG productivo)
1. **Implementar EvidencePacket class** en `ragService.js` — wrapper estructurado para cada chunk recuperado: `{chunk_id, content, similarity, metadata, source, provenance: {document_id, chunk_index, content_hash, embedding_model}}`
2. **Modificar `searchBeautyKnowledge`** para devolver `EvidencePacket[]` en lugar de chunks crudos
3. **Actualizar `auraToolExecutor.js:221`** para envolver resultado en EvidencePacket (hoy devuelve chunks crudos)
4. **Migrar 31 filas legacy** `aura_knowledge` → `beauty_knowledge_embeddings` con script dedicado

### CORTO PLAZO (Mejoras necesarias)
5. **Calibrar Sufficiency Gate** con datos reales producción (R7 objetivo: 1000+ queries) — definir umbrales `top1_score`, `margin`, `coverage` para clasificar SUPPORTED/UNSUPPORTED/EVIDENCE_INSUFFICIENT
6. **Implementar Candidate Builder** (diseño R6-C4) — pool expansion + grouping semántico por categoría
7. **Conectar `metadataEnricher`** a ingesta canónica/ad-hoc para enriquecer metadata automáticamente
8. **Opcional (Director approval)**: Activar Dense+Sparse (FTS + RRF) en `ragService` — +0.033 MRR determinista, +300ms, reversible
9. **Estabilizar query embeddings** — usar `semanticCache` para reutilizar embeddings de queries idénticas/similares

### POSTERIORES (Optimización y robustez)
10. **Projection Head experimental** (fuera producción) — única vía teórica para adaptar e5-v5 sin pesos (diseñada en R6-C12, no ejecutada)
11. **Re-embedding programado** — evaluar necesidad tras 6-12 meses de drift NIM; requeriría re-ingesta completa + validación GOLD-V5
12. **Dataset de entrenamiento real** — si NVIDIA expone pesos en futuro, usar queries producción + feedback para fine-tuning/LoRA
13. **Evaluación continua** — pipeline automático nightly: sample queries producción → run ragEvaluator → alerta si MRR < 0.65 o Vector_MISS rate > 25%

---

## 23. CONCLUSIÓN

> **Si tuviera que continuar el desarrollo del RAG desde este punto, exactamente qué está listo, qué está incompleto y qué tendría que hacer primero.**

### ✅ **LISTO Y FUNCIONANDO (No tocar)**
- Pipeline completo Fuentes → Ingesta → Embeddings → Vector Store → Retrieval → LLM → Usuario
- 5,663 chunks con embeddings 1024d, HNSW operativo, 0 NULL
- Baseline MRR 0.7222 reproducido (RUN A ≡ RUN B)
- Integración Flutter ↔ Backend via WebSocket + Function Calling
- Observabilidad: traces, métricas, cache semántico, circuit breakers
- Evaluación offline robusta (30+ experimentos documentados)

### ⚠️ **INCOMPLETO (Bloquea Evidence Layer y confianza en producción)**
1. **EvidencePacket** — salida estructurada de `searchBeautyKnowledge` con provenance completa
2. **Sufficiency Gate** — guard para decidir cuándo hay evidencia suficiente (sin calibrar)
3. **Candidate Builder / Aggregator** — fusión multi-chunk sin alucinar
4. **Migración legacy** — 31 filas `aura_knowledge` sin vector

### 🎯 **PRIMERO QUE HARÍA (Orden exacto)**
1. **Crear `EvidencePacket` class** en `ragService.js` (30 min) — wrapper tipado para chunks
2. **Cambiar return de `searchBeautyKnowledge`** a `EvidencePacket[]` (15 min) — breaking change controlado
3. **Actualizar `auraToolExecutor.js:221`** para usar EvidencePacket (10 min)
4. **Script migración legacy** `aura_knowledge` → canónico (1 hora) — 31 filas, una sola vez
5. **Deploy shadow 2 semanas** — validar que no rompe LLM ni UI
6. **Iniciar recolección queries producción** para calibrar Sufficiency Gate (R7 objetivo)

**Veredicto final**: El RAG está **operativo en producción** con calidad aceptable (MRR 0.72). El trabajo restante no es "arreglar el RAG" sino **completar la capa de evidencia post-retrieval** para dar confianza calibrada y trazabilidad completa. Los 13 VECTOR_MISS son límite intrínseco del embedding actual — no se resuelven con más ingeniería de retrieval.

---

## ANEXO: HALLAZGOS CLASIFICADOS POR EVIDENCIA

### [CRÍTICO] Evidence Layer no implementado
- **Descripción**: Candidate Builder, Evidence Packet, Provenance, Aggregator, Sufficiency Gate diseñados en R6-C1..C4 pero no codificados
- **Evidencia**: `r6_final_closure_report.json:202-210` — todos marcados `B_DESIGNED_NOT_IMPLEMENTED` o `C_POSTPONED`
- **Impacto**: Sin provenance trazable, sin gate de suficiencia, riesgo alucinación silenciosa
- **Archivo**: `src/services/ragService.js` (modificar `searchBeautyKnowledge` return type)
- **Acción**: Implementar `EvidencePacket` class + modificar retorno

### [CRÍTICO] Sufficiency Gate no calibrado
- **Descripción**: Umbrales para clasificar SUPPORTED/UNSUPPORTED/EVIDENCE_INSUFFICIENT no validados
- **Evidencia**: `r6_final_closure:156,194-196` — "riesgo false UNSUPPORTED/SUFFICIENT en producción"
- **Impacto**: Generación sin evidencia suficiente o bloqueo falso de respuestas válidas
- **Archivo**: `src/services/ragEvaluator.js` (añadir calibración)
- **Acción**: Recolectar 1000+ queries producción (R7) → calibrar umbrales

### [ALTO] 13 VECTOR_MISS (8 representation-bound)
- **Descripción**: Conceptos ultraespecializados no anclados por e5-v5: simetría muscular, Tyndall, SERS, electrólisis cross-domain, autofagia, LHA, arquitectura muscular facial, psicología percepción
- **Evidencia**: `r6_final_closure:148-151,169` — cejas_004 control negativo: 147 chunks "simetría", 223 "musculatura", título literal → sim 0.42 rank ~2857
- **Impacto**: 22.4% miss rate en gold set; no recuperables con embedding actual
- **Causa**: Gap semántico intrínseco de e5-v5, no cobertura de corpus
- **Acción**: Documentar gaps; no prometer cobertura total; evaluar Projection Head experimental

### [ALTO] Inestabilidad query-embedding NIM
- **Descripción**: Misma query produce embeddings no idénticos entre llamadas (managed API)
- **Evidencia**: `r6_final_closure:170` — "frontier top-200 fluctúa (5 misses borderline afectados)"
- **Impacto**: Retrieval no determinista; 5/13 misses son inestabilidad frontera
- **Acción**: Usar semanticCache para reutilizar embeddings; documentar varianza

### [MEDIO] Legacy aura_knowledge no migrado
- **Descripción**: 31 filas en tabla legacy con chunk_id hash puro, contenido intacto pero sin embedding
- **Evidencia**: `r6_recovery1:19,49` — `legacy_hash_chunk_ids: 31`
- **Acción**: Script migración única: SELECT * FROM aura_knowledge → chunkificar → embedder → UPSERT beauty_knowledge_embeddings + INSERT rag_chunk_traceability

### [MEDIO] chunkingService + metadataEnricher huérfanos
- **Descripción**: Código completo (14K + 14K chars) sin conectar a pipeline
- **Evidencia**: No importados en `ingestCanonicalCorpus.js` ni `ragService.js`
- **Acción**: Integrar en ingesta ad-hoc (PDF, web) o deprecarlos con comentario

---

**FIN DEL INFORME FORENSE**