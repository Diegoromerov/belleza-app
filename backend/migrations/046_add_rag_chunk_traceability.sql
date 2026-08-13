-- Migration 046: minimum traceability and database-backed identity for Aura RAG.
-- Canonical table only: beauty_knowledge_embeddings.

ALTER TABLE beauty_knowledge_embeddings
  ADD COLUMN IF NOT EXISTS document_id TEXT,
  ADD COLUMN IF NOT EXISTS document_version TEXT,
  ADD COLUMN IF NOT EXISTS chunk_id TEXT,
  ADD COLUMN IF NOT EXISTS content_hash TEXT,
  ADD COLUMN IF NOT EXISTS fuente TEXT,
  ADD COLUMN IF NOT EXISTS seccion TEXT;

-- Historical rows are retained. Their provenance was not captured by older writers,
-- so mark it explicitly instead of inventing a source or section.
UPDATE beauty_knowledge_embeddings
SET
  document_id = COALESCE(document_id, 'legacy:' || id::text),
  document_version = COALESCE(document_version, 'unknown'),
  chunk_id = COALESCE(chunk_id, 'legacy:' || id::text),
  content_hash = COALESCE(content_hash, md5(content)),
  fuente = COALESCE(fuente, 'unknown'),
  seccion = COALESCE(seccion, 'unknown')
WHERE document_id IS NULL
   OR document_version IS NULL
   OR chunk_id IS NULL
   OR content_hash IS NULL
   OR fuente IS NULL
   OR seccion IS NULL;

ALTER TABLE beauty_knowledge_embeddings
  ALTER COLUMN document_id SET NOT NULL,
  ALTER COLUMN document_version SET NOT NULL,
  ALTER COLUMN chunk_id SET NOT NULL,
  ALTER COLUMN content_hash SET NOT NULL,
  ALTER COLUMN fuente SET NOT NULL,
  ALTER COLUMN seccion SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_beauty_knowledge_document_chunk
  ON beauty_knowledge_embeddings (document_id, document_version, chunk_id);

CREATE INDEX IF NOT EXISTS idx_beauty_knowledge_content_hash
  ON beauty_knowledge_embeddings (content_hash);

COMMENT ON COLUMN beauty_knowledge_embeddings.document_id IS 'Stable SHA-256 identity of the real source document.';
COMMENT ON COLUMN beauty_knowledge_embeddings.document_version IS 'Source-supplied version or SHA-256 of the source document.';
COMMENT ON COLUMN beauty_knowledge_embeddings.chunk_id IS 'Stable SHA-256 identity of the chunk within its document version.';
COMMENT ON COLUMN beauty_knowledge_embeddings.content_hash IS 'Deterministic hash of chunk content; canonical ingestion uses SHA-256.';
COMMENT ON COLUMN beauty_knowledge_embeddings.fuente IS 'Actual source identifier; unknown only for historical rows without provenance.';
COMMENT ON COLUMN beauty_knowledge_embeddings.seccion IS 'Actual source section; unknown only when unavailable.';
