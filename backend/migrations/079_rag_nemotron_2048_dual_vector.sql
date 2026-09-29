-- backend/migrations/079_rag_nemotron_2048_dual_vector.sql
-- Migration 079: FASE 0 RAG - Enable 2048-dim dual vector column for active model nvidia/nemotron-3-embed-1b

-- 1. Create dual vector column embedding_next if not exists
ALTER TABLE public.beauty_knowledge_embeddings 
ADD COLUMN IF NOT EXISTS embedding_next vector(2048);

-- 2. Document column purpose
COMMENT ON COLUMN public.beauty_knowledge_embeddings.embedding_next IS 'Vector(2048) para el modelo activo nvidia/nemotron-3-embed-1b (RAG FASE 0)';
