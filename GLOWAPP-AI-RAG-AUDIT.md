# GLOWAPP — AI & RAG DEEP AUDIT

## 1. COMPONENTES DEL SISTEMA RAG Y AGENTES AURA

| Módulo | Componente | Tecnología / Modelo | Estado |
|---|---|---|:---:|
| **Ingesta & Normalización** | `corpusAutoIngest.js`, `chunkingService.js` | Chunking recursivo, normalización de markdown | 🟢 FUNCIONAL |
| **Embeddings** | `embeddingService.js`, `ragService.js` | NVIDIA `nvidia/nv-embedqa-e5-v5` (1024 dims) | 🟢 EN PRODUCCIÓN |
| **Vector Store** | PostgreSQL + pgvector (`knowledge_chunks`) | Índice HNSW / IVFFLAT en Supabase | 🟢 FUNCIONAL |
| **Recuperación (Retrieval)** | `ragService.js` (`searchKnowledge`) | Similitud coseno + filtros por `skin_type`, `category` | 🟢 FUNCIONAL |
| **Caché & Optimización** | `semanticCache.js`, `contextCompressor.js` | Redis + Compresión de prompt | 🟢 FUNCIONAL |
| **Observabilidad & Métricas**| `ragObservability.js`, `ragEvaluator.js` | Logging estructurado y métricas de relevancia | 🟢 IMPLEMENTADO |
| **Orquestación Multi-Agente**| `aiOrchestrator.js`, `agents/` | Atena (Diagnóstico), Hestia (Productos), Apolo (Color) | 🟢 FUNCIONAL |

## 2. EVALUACIÓN DE ROBUSTEZ Y GROUNDING
* **Grounding:** Los prompts de los agentes obligan a citar fuentes de la base de conocimiento y prohíben alucinaciones de ingredientes no corroborados.
* **Resiliencia de IA:** Integración de fallback a Gemini 3.1 Flash-Lite cuando DeepSeek está inaccesible o saturado.
