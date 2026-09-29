-- Migration: 049_alter_embedding_dimension_to_2048.sql
-- Description:
--   1. Cambia la dimensión de embeddings de 1024 a 2048 (compatible con nemotron-3-embed-1b)
--   2. Recrea índice HNSW para búsqueda vectorial por similitud coseno
--   3. Idempotente y reversible
--
-- Tabla canónica: beauty_knowledge_embeddings
-- NOTA: Requiere pgvector extension (ver migración 030_enable_pgvector.sql)
-- NOTA: Los vectores existentes (modelo EOL nvidia/nv-embedqa-e5-v5, 1024 dims) NO son reutilizables
--       y se pierden al recrear la columna. La re-ingesta completa del corpus canónico
--       (5.619 chunks) debe ejecutarse tras aplicar esta migración.

-- Paso 0: Verificar si pgvector está disponible
DO $$
DECLARE
    ext_exists boolean;
BEGIN
    SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'vector') INTO ext_exists;
    IF NOT ext_exists THEN
        RAISE EXCEPTION 'pgvector extension not found. Execute migration 030_enable_pgvector.sql first.';
    END IF;
END $$;

-- Paso 1: Verificar si la tabla existe
DO $$
DECLARE
    table_exists boolean;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'beauty_knowledge_embeddings'
    ) INTO table_exists;

    IF NOT table_exists THEN
        RAISE EXCEPTION 'Tabla beauty_knowledge_embeddings no existe. Ejecutar migración 031 primero.';
    END IF;
END $$;

-- Paso 2: Dropear índice HNSW/IVFFlat existente (incompatible con cambio de dimensión)
DROP INDEX IF EXISTS idx_beauty_knowledge_embedding_hnsw;
DROP INDEX IF EXISTS idx_beauty_knowledge_embedding_ivfflat;

-- Paso 3: Cambiar dimensión de embedding a 2048
-- Nota: USING no funciona para cambiar dimensión de vector; requiere recrear columna
DO $$
BEGIN
    -- Si la dimensión ya es 2048, no hacer nada
    IF EXISTS (
        SELECT 1 FROM pg_attribute a
        JOIN pg_class c ON a.attrelid = c.oid
        WHERE c.relname = 'beauty_knowledge_embeddings'
        AND a.attname = 'embedding'
        AND a.atttypmod = 2048
    ) THEN
        RAISE NOTICE 'Embedding ya tiene dimensión 2048. Saltando ALTER.';
    ELSE
        -- Recrear columna con nueva dimensión (los datos existentes se pierden)
        ALTER TABLE beauty_knowledge_embeddings
        DROP COLUMN embedding;

        ALTER TABLE beauty_knowledge_embeddings
        ADD COLUMN embedding vector(2048);

        RAISE NOTICE 'Columna embedding recreada con dimensión 2048. Vectores previos (modelo EOL) perdidos - requiere re-ingesta completa.';
    END IF;
END $$;

-- Paso 4: Crear índice HNSW para búsqueda vectorial por similitud coseno
-- Solo si pgvector versión lo soporta (PostgreSQL 15+ con pgvector 0.5+)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE indexname = 'idx_beauty_knowledge_embedding_hnsw'
    ) THEN
        CREATE INDEX idx_beauty_knowledge_embedding_hnsw
        ON beauty_knowledge_embeddings
        USING hnsw (embedding vector_cosine_ops)
        WITH (m = 16, ef_construction = 64);

        RAISE NOTICE 'Índice HNSW creado exitosamente.';
    ELSE
        RAISE NOTICE 'Índice HNSW ya existe.';
    END IF;
EXCEPTION
    WHEN others THEN
        RAISE WARNING 'No se pudo crear índice HNSW: %. Intentando IVFFlat como fallback.', SQLERRM;
        -- Fallback a IVFFlat si HNSW no disponible
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes
            WHERE indexname = 'idx_beauty_knowledge_embedding_ivfflat'
        ) THEN
            CREATE INDEX idx_beauty_knowledge_embedding_ivfflat
            ON beauty_knowledge_embeddings
            USING ivfflat (embedding vector_cosine_ops)
            WITH (lists = 100);

            RAISE NOTICE 'Índice IVFFlat creado como fallback.';
        END IF;
END $$;

-- Paso 5: Comentario de versión
COMMENT ON TABLE beauty_knowledge_embeddings IS 'RAG Knowledge Base v3: 2048-dim embeddings (nemotron-3-embed-1b), HNSW index, metadata filtering';

-- Verificación final
DO $$
DECLARE
    final_dim integer;
    idx_count integer;
BEGIN
    SELECT a.atttypmod INTO final_dim
    FROM pg_attribute a
    JOIN pg_class c ON a.attrelid = c.oid
    WHERE c.relname = 'beauty_knowledge_embeddings'
    AND a.attname = 'embedding';

    SELECT COUNT(*) INTO idx_count
    FROM pg_indexes
    WHERE tablename = 'beauty_knowledge_embeddings'
    AND indexname LIKE '%embedding%';

    RAISE NOTICE '=== MIGRACIÓN 049 COMPLETADA ===';
    RAISE NOTICE 'Dimensión final embedding: %', final_dim;
    RAISE NOTICE 'Índices vectoriales: %', idx_count;
    RAISE NOTICE 'Tabla: beauty_knowledge_embeddings (canónica)';
    RAISE NOTICE 'ACCION REQUERIDA: Re-ingesta completa del corpus (5.619 chunks) y recalibración umbral (0.45 → ~0.4156)';
END $$;