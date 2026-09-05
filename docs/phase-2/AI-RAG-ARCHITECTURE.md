# GLOWAPP PHASE 2 — AI RAG ARCHITECTURE (AURA AI)

## 1. Aura AI Architecture
- **Worker:** FastAPI AI Worker process.
- **Vector Store:** PostgreSQL `pgvector` extension for semantic embedding storage and retrieval.
- **Chunking & Indexing:** Beauty service descriptions, provider FAQs, and course lessons chunked with metadata tags.
- **Hallucination Control:** Strict prompt context windows requiring explicit source citations for answers.
