-- backend/migrations/082_rag_feedback_signals.sql
-- Migration 082: Tabla de señales de retroalimentación RLHF/RLAIF para RAG de Aura

CREATE TABLE IF NOT EXISTS public.rag_feedback_signals (
    id SERIAL PRIMARY KEY,
    trace_id VARCHAR(64) NOT NULL,
    user_id_hash VARCHAR(64),
    query_text TEXT NOT NULL,
    rating INT CHECK (rating IN (-1, 1)), -- -1 para Dislike/Incompleto, 1 para Like/Preciso
    feedback_type VARCHAR(64), -- 'clinical_accuracy', 'relevance', 'safety_warning', 'hallucination'
    notes TEXT,
    adjusted_vector_weight DOUBLE PRECISION DEFAULT 0.70,
    adjusted_text_weight DOUBLE PRECISION DEFAULT 0.30,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rag_feedback_trace_id ON public.rag_feedback_signals(trace_id);
CREATE INDEX IF NOT EXISTS idx_rag_feedback_rating ON public.rag_feedback_signals(rating);

COMMENT ON TABLE public.rag_feedback_signals IS 'Señales de retroalimentación RLHF para recalibración autónoma de RAG en Aura';
