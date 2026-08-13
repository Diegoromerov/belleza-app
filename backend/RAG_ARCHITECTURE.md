# Aura RAG architecture (R1-R4)

## Canonical path

Aura retrieves knowledge only through `src/services/ragService.js`, which reads
`beauty_knowledge_embeddings` via `ragPool`. Query embeddings use NVIDIA
`nvidia/nv-embedqa-e5-v5` at 1024 dimensions. If NVIDIA cannot create a query
embedding, `ragService` logs the event and uses PostgreSQL full-text search on
the same canonical table. It never searches with a dummy vector.

`RAG_DATABASE_URL` creates `ragPool`. The general `DATABASE_URL` creates
`pool`; it is deliberately excluded from all canonical RAG retrieval and
ingestion code.

## Ingestion and traceability

The official writer is `scripts/ingestBeautyKnowledge.js --source=corpus`.
It reads `src/data/beauty_corpus`, chunks content with the existing chunking
service, creates NVIDIA passage embeddings, and upserts through `ragPool`.
An embedding error records the affected error and prevents that chunk from
being inserted. Identity is deterministic: source-relative document path,
source version (or SHA-256 of the raw document), chunk position, and normalized
chunk content yield `document_id`, `document_version`, `chunk_id`, and
`content_hash`. Migration `046_add_rag_chunk_traceability.sql` adds those
fields plus `fuente` and `seccion`, and enforces a unique document/chunk
identity.

`scripts/ingest_json_chunks.js`, SQL seed files, and root seed scripts are
historical/auxiliary writers and are not part of the canonical Aura ingestion
path. They require migration before being used for new canonical corpus data.

## Legacy

`beautyKnowledgeService.js` remains as a deprecated compatibility facade, but
delegates to `ragService`; it no longer reads `aura_knowledge_chunks` or creates
embeddings. `aura_knowledge_chunks` is retained without destructive changes and
is outside Aura's active retrieval path.

## R1-R4 limits

This scope covers the canonical path, NVIDIA/FTS fallback, minimum
traceability, deterministic upsert, and reproducible ingestion only. It does
not implement benchmark/evaluation work, advanced grounding or metadata,
personalization, hybrid/reranked search, CI/CD, or advanced observability.
