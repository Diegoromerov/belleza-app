-- Migration: 031_aura_pgvector_and_knowledge_table.sql
-- Description: Creates beauty_knowledge_embeddings table for RAG beauty search
-- Depends on: 030_enable_pgvector.sql (creates pgvector extension)

CREATE TABLE IF NOT EXISTS beauty_knowledge_embeddings (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    embedding vector(768),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_beauty_knowledge_category ON beauty_knowledge_embeddings(category);
