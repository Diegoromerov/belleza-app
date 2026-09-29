-- backend/migrations/080_rag_rls_multi_tenant_hardening.sql
-- FASE 2 RAG: Multi-Tenant Hardening & Forced Row Level Security (RLS)

-- 1. Enable RLS on beauty_knowledge_embeddings
ALTER TABLE public.beauty_knowledge_embeddings ENABLE ROW LEVEL SECURITY;

-- 2. Create RLS Select Policy allowing GLOBAL chunks (tenant_id IS NULL) or tenant matching current_setting
DROP POLICY IF EXISTS rls_beauty_knowledge_select ON public.beauty_knowledge_embeddings;

CREATE POLICY rls_beauty_knowledge_select
ON public.beauty_knowledge_embeddings
FOR SELECT
USING (
    tenant_id IS NULL 
    OR tenant_id::text = current_setting('app.current_tenant_id', true)
);

-- 3. Document policy
COMMENT ON TABLE public.beauty_knowledge_embeddings IS 'Tabla RAG de conocimientos con RLS habilitado (FASE 2 RAG Multi-Tenant Isolation)';
