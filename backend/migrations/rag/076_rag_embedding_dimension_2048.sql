-- Migration: 076_rag_embedding_dimension_2048.sql
-- Hallazgo P0 N-4 (t_fix_ragaura_03) — RAG_ARCHITECTURE.md §9.1/§9.2, PLAN_MEJORA_RAG.md FASE 0.
--
-- PROBLEMA
--   El único modelo de embeddings habilitado para la cuenta del proyecto es
--   `nvidia/nemotron-3-embed-1b` (medido con la key real: GET /v1/models → 200;
--   los otros 6 → 404 «Not found for account»). El modelo anterior
--   `nvidia/nv-embedqa-e5-v5` (1024d) alcanzó EOL el 2026-08-25 → HTTP 410 Gone.
--   El modelo vivo devuelve vectores de 2048 dimensiones, mientras que la columna
--   `beauty_knowledge_embeddings.embedding` quedó en `vector(1024)` (migración 035).
--   Consecuencia: la ingesta falla de forma explícita y `ragService` degrada a
--   full-text → la búsqueda vectorial está efectivamente DESACTIVADA.
--
-- SOLUCIÓN
--   1. Reconstruir la columna `embedding` como `vector(2048)` (la dimensión del modelo vivo).
--   2. Reconstruir el índice HNSW (coseno) sobre la nueva dimensión.
--   3. Dejar constancia de que, al cambiar de espacio vectorial, los vectores existentes
--      NO son reutilizables: es obligatoria la RE-INGESTA completa del corpus.
--
-- SECUENCIA DE DESPLIEGUE (obligatoria, en este orden):
--   1) aplicar esta migración (columna a 2048 + HNSW),
--   2) RE-INGESTA completa del corpus canónico con el modelo vivo:
--        node scripts/ingestBeautyKnowledge.js --source=corpus
--      (los ~5.619 chunks deben re-embeberse; los vectores previos pertenecían al
--       espacio del modelo retirado y no son comparables),
--   3) recalibrar el umbral de similitud (con el modelo vivo el acierto puntúa ~0.4156,
--      por debajo del 0.45 por defecto — ver RAG_ARCHITECTURE.md §9.2),
--   4) verificar la ruta vectorial (traza debe declarar `hnsw`, no `fts`).
--
-- Idempotente y reversible (rollback en migrations/rollback/076_*.down.sql).
-- Tabla canónica: beauty_knowledge_embeddings (031, 035, 046, 048).
-- Requiere pgvector (migración 030).

-- Paso 0: Verificar pgvector
DO $$
DECLARE ext_exists boolean;
BEGIN
    SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'vector') INTO ext_exists;
    IF NOT ext_exists THEN
        RAISE EXCEPTION 'pgvector extension not found. Ejecutar migración 030_enable_pgvector.sql primero.';
    END IF;
END $$;

-- Paso 1: Verificar que la tabla canónica existe
DO $$
DECLARE table_exists boolean;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM information_schema.tables WHERE table_name = 'beauty_knowledge_embeddings'
    ) INTO table_exists;
    IF NOT table_exists THEN
        RAISE EXCEPTION 'Tabla beauty_knowledge_embeddings no existe. Ejecutar migración 031 primero.';
    END IF;
END $$;

-- Paso 2: Dropear índices vectoriales existentes (incompatibles con la nueva dimensión)
DROP INDEX IF EXISTS idx_beauty_knowledge_embedding_hnsw;
DROP INDEX IF EXISTS idx_beauty_knowledge_embedding_ivfflat;

-- Paso 3: Reconstruir la columna embedding con dimensión 2048
--   Para pgvector, cambiar la dimensión exige recrear la columna (no hay cast válido
--   1024→2048). Los embeddings existentes pertenecen al espacio del modelo retirado y
--   no son reutilizables: se descartan y se repueblan en la RE-INGESTA del corpus.
DO $$
DECLARE
    current_dim integer;
BEGIN
    SELECT a.atttypmod INTO current_dim
    FROM pg_attribute a
    JOIN pg_class c ON a.attrelid = c.oid
    WHERE c.relname = 'beauty_knowledge_embeddings'
      AND a.attname = 'embedding'
      AND a.attnum > 0;

    IF current_dim IS DISTINCT FROM 2048 THEN
        RAISE NOTICE 'Dimensión actual de embedding: %. Reconstruyendo a vector(2048)...', current_dim;
        ALTER TABLE beauty_knowledge_embeddings DROP COLUMN IF EXISTS embedding;
        ALTER TABLE beauty_knowledge_embeddings ADD COLUMN embedding vector(2048);
        RAISE NOTICE 'Columna embedding recreada con dimensión 2048. Los vectores quedan NULL hasta la RE-INGESTA.';
    ELSE
        RAISE NOTICE 'Embedding ya tiene dimensión 2048. Saltando ALTER.';
    END IF;
END $$;

-- Paso 4: Reconstruir índice HNSW (similitud coseno) sobre la nueva dimensión
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes WHERE indexname = 'idx_beauty_knowledge_embedding_hnsw'
    ) THEN
        CREATE INDEX idx_beauty_knowledge_embedding_hnsw
        ON beauty_knowledge_embeddings
        USING hnsw (embedding vector_cosine_ops)
        WITH (m = 16, ef_construction = 64);
        RAISE NOTICE 'Índice HNSW (2048d, coseno) creado exitosamente.';
    ELSE
        RAISE NOTICE 'Índice HNSW ya existe.';
    END IF;
EXCEPTION
    WHEN others THEN
        RAISE WARNING 'No se pudo crear índice HNSW: %. Intentando IVFFlat como fallback.', SQLERRM;
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes WHERE indexname = 'idx_beauty_knowledge_embedding_ivfflat'
        ) THEN
            CREATE INDEX idx_beauty_knowledge_embedding_ivfflat
            ON beauty_knowledge_embeddings
            USING ivfflat (embedding vector_cosine_ops)
            WITH (lists = 100);
            RAISE NOTICE 'Índice IVFFlat creado como fallback.';
        END IF;
END $$;

-- Paso 5: Comentario de versión
COMMENT ON TABLE beauty_knowledge_embeddings IS
  'RAG Knowledge Base v3: 2048-dim embeddings (nvidia/nemotron-3-embed-1b), HNSW index, metadata filtering. RE-INGESTA obligatoria tras esta migración (5.619 chunks).';

-- Verificación final
DO $$
DECLARE
    final_dim integer;
    idx_count integer;
BEGIN
    SELECT a.atttypmod INTO final_dim
    FROM pg_attribute a
    JOIN pg_class c ON a.attrelid = c.oid
    WHERE c.relname = 'beauty_knowledge_embeddings' AND a.attname = 'embedding';

    SELECT COUNT(*) INTO idx_count
    FROM pg_indexes
    WHERE tablename = 'beauty_knowledge_embeddings' AND indexname LIKE '%embedding%';

    RAISE NOTICE '=== MIGRACIÓN 076 COMPLETADA ===';
    RAISE NOTICE 'Dimensión final embedding: % (esperado 2048)', final_dim;
    RAISE NOTICE 'Índices vectoriales: %', idx_count;
    RAISE NOTICE 'ACCIÓN PENDIENTE: re-ingesta del corpus (node scripts/ingestBeautyKnowledge.js --source=corpus)';
END $$;
