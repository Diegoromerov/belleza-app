# F7.002-A Discovery Evidence

## F7.002-A Discovery Summary

### RAG Components Found:
- backend/src/services/ragService.js: Servicio RAG que usa pgvector y NVIDIA API para embeddings.
- backend/src/services/beautyKnowledgeService.js: Servicio de conocimiento de belleza con embeddings y fallback.
- backend/src/services/ragEvaluator.js, ragLogger.js, ragMetrics.js, ragObservability.js: Servicios de soporte para RAG.
- backend/src/tests/ciRagEvaluation.test.js: Pruebas de evaluación de RAG.
- backend/scripts/: varios scripts de evaluación y ingestión de conocimiento RAG (r5c*.js, r6c*.js).
- backend/src/data/beauty_corpus/: corpus de belleza para RAG.

### Knowledge Service Components Found:
- backend/src/services/beautyKnowledgeService.js: También actúa como servicio de conocimiento.
- backend/src/services/metadataEnricher.js: Enriquecimiento de metadata.
- backend/src/services/semanticCache.js: Caché semántico.
- backend/src/services/corpusAutoIngest.js: Ingestión automática de corpus.

### Event Bus Components Found:
- backend/src/controllers/eventController.js: Controlador de eventos.
- backend/src/controllers/eventRegistrationController.js: Controlador de registro de eventos.
- backend/src/routes/eventRoutes.js: Rutas de eventos.
- backend/src/routes/eventRegistrationRoutes.js: Rutas de registro de eventos.
## Evidence for RAG Service

### File: backend/src/services/ragService.js
- E0: Service exists and contains functions for generating embeddings (using NVIDIA API) and searching beauty knowledge.
- E0: Uses environment variables: NVIDIA_API_KEY, NVIDIA_API_URL, NVIDIA_EMBEDDING_MODEL, EXPECTED_DIMS.
- E0: Has a fallback to full-text search if vector search fails.
- E0: Exports searchBeautyKnowledge, formatKnowledgeContext, generateEmbedding.

### Test File: backend/src/tests/ragEvaluator.test.js
- E0: Test file exists for ragEvaluator (which uses ragService).
- E1: We can run the test to see if it passes (but note: we are in discovery, we can run tests as they are non-destructive).

