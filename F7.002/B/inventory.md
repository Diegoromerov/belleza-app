# F7.002-B Inventory of Components and Dependencies

## RAG Components

### Services
- `backend/src/services/ragService.js`
  - Purpose: Servicio RAG (Retrieval-Augmented Generation) que busca conocimiento técnico de belleza en la base de datos pgvector.
  - Dependencies: 
    - `../config/db` (for ragPool)
    - `axios` (for NVIDIA API calls)
    - Environment variables: `NVIDIA_API_KEY`, `NVIDIA_API_URL`, `NVIDIA_EMBEDDING_MODEL`, `EXPECTED_DIMS`
  - Exports: `searchBeautyKnowledge`, `formatKnowledgeContext`, `generateEmbedding`
  - Notes: Tiene un fallback a búsqueda full-text si la búsqueda vectorial falla.

- `backend/src/services/beautyKnowledgeService.js`
  - Purpose: Servicio de conocimiento de belleza que también utiliza embeddings (NVIDIA) y tiene un mecanismo de fallback y circuit breaker.
  - Dependencies:
    - `../config/db` (for pool)
    - `axios`
    - Environment variables: `EMBEDDING_PROVIDER`, `ENABLE_BEAUTY_RAG`, `NVIDIA_EMBED_URL`, `NVIDIA_EMBEDDING_MODEL`, `NVIDIA_API_KEY`
  - Exports: `searchBeautyKnowledge`, `formatKnowledgeContext`, `ENABLE_BEAUTY_RAG`
  - Notes: Incluye un mecanismo de circuit breaker para fallos de NVIDIA y un embedding dummy determinístico.

### Supporting Services
- `backend/src/services/ragEvaluator.js`
- `backend/src/services/ragLogger.js`
- `backend/src/services/ragMetrics.js`
- `backend/src/services/ragObservability.js`
- `backend/src/services/semanticCache.js`
- `backend/src/services/metadataEnricher.js`
- `backend/src/services/corpusAutoIngest.js`

### Tests
- `backend/src/tests/ragEvaluator.test.js`
- `backend/src/tests/ragLogger.test.js`
- `backend/src/tests/ragMetrics.test.js`
- `backend/src/tests/ciRagEvaluation.test.js` (evaluación de RAG)

### Scripts
- `backend/scripts/ingestBeautyKnowledge.js`
- `backend/scripts/ingestCanonicalCorpus.js`
- `backend/scripts/purgeRagKnowledge.js`
- `backend/scripts/r5c*.js` (various RAG experiments)
- `backend/scripts/r6c*.js` (various RAG experiments)
- `backend/scripts/ragDiagnosticR5c0.js`
- `backend/scripts/validateDatasetV3.js`
- `backend/scripts/verifyRagSchema.js`

### Data
- `backend/src/data/beauty_corpus/` (corpus de belleza para RAG)

### Configuration
- `backend/src/config/db.js` (configura la conexión a la base de datos y el pool para RAG)
- `backend/src/config/qualityGates.js` (posiblemente contiene umbrales de calidad para RAG)

### Environment Variables (related to RAG)
- `NVIDIA_API_KEY`: Clave para la API de NVIDIA (requerida para embeddings)
- `NVIDIA_API_URL`: URL de la API de NVIDIA (default: 'https://integrate.api.nvidia.com/v1/embeddings')
- `NVIDIA_EMBEDDING_MODEL`: Modelo de embedding a usar (default: 'nvidia/nv-embedqa-e5-v5')
- `EXPECTED_DIMS`: Dimensiones esperadas del embedding (default: 1024)
- `EMBEDDING_PROVIDER`: Proveedor de embeddings (default: 'nvidia')
- `ENABLE_BEAUTY_RAG`: Bandera para habilitar/deshabilitar el RAG de belleza (default: 'true'?)
- `NVIDIA_EMBED_URL`: URL base para NVIDIA embeddings (usado en beautyKnowledgeService)

## Knowledge Service Components

Note: In this codebase, the beautyKnowledgeService also acts as a knowledge service. Additionally, we have:

- `backend/src/services/beautyKnowledgeService.js` (as above)
- `backend/src/services/metadataEnricher.js` (enriquece metadata de conocimiento)
- `backend/src/services/semanticCache.js` (caché semántico para conocimiento)
- `backend/src/services/corpusAutoIngest.js` (ingesta automática de corpus de conocimiento)

## Event Bus Components

### Controllers
- `backend/src/controllers/eventController.js`
- `backend/src/controllers/eventRegistrationController.js`

### Routes
- `backend/src/routes/eventRoutes.js`
- `backend/src/routes/eventRegistrationRoutes.js`

### Possible Models or Services (to be verified)
We need to check if there is an event service, event store, or similar.

Let's search for event-related services or models.

