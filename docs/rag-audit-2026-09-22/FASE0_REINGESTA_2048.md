# FASE 0 — Re-ingesta obligatoria del corpus tras la migración a 2048 dimensiones

**Origen**: hallazgo P0 N-4 (`t_fix_ragaura_03`) · `RAG_ARCHITECTURE.md` §9.1/§9.2/§9.9 ·
`docs/rag-audit-2026-09-22/PLAN_MEJORA_RAG.md` FASE 0.

## Por qué la re-ingesta es obligatoria (no opcional)

El corpus se indexó con `nvidia/nv-embedqa-e5-v5` (**1024 dimensiones**, retirado — EOL 2026-08-25,
HTTP 410 Gone). La migración `073_rag_embedding_dimension_2048.sql` reconstruye la columna
`beauty_knowledge_embeddings.embedding` como `halfvec(2048)` para el modelo vivo
`nvidia/nemotron-3-embed-1b` (2048 dimensiones).

Un embedding **no es un dato neutral**: cada modelo define su propio *espacio vectorial*. Los
vectores viejos (1024d) **no son comparables** con los nuevos (2048d) — ni por dimensión ni
semánticamente. Por eso es imposible "convertir" los vectores existentes: hay que **re-embeder** los
~5.619 chunks del corpus canónico con el modelo vivo. La migración deja la columna con vectores
`NULL` hasta que la re-ingesta los repoble.

## Orden de despliegue (obligatorio)

```
1. Migración   → 076_rag_embedding_dimension_2048.sql   (columna halfvec(2048) + HNSW coseno 2048d)
2. Re-ingesta  → node scripts/ingestCanonicalCorpus.js
3. Umbral      → recalibrar (ver §"Umbral")
4. Verificación→ traza debe declarar `hnsw` (ruta vectorial), no `fts`
```

> Migrar **antes** de re-ingestar. Re-ingestar antes de la migración hace fallar cada chunk con
> `Dimensión embedding incorrecta: esperado 2048, recibido ...` o con el error de cast de pgvector.

## Paso 2 — Re-ingesta del corpus

```bash
cd backend
# Dry-run primero (sin escribir): valida chunking, metadata y límites
node scripts/ingestCanonicalCorpus.js --dry-run
# Ingesta real (idempotente por (document_id, chunk_id); rate-limited 10 chunks/seg)
node scripts/ingestCanonicalCorpus.js
```

Salida esperada: los ~5.619 chunks re-embebidos sin errores. El upsert es idempotente por
`(document_id, chunk_id)` y usa `content_hash` para detectar cambios, así que re-ejecutar es seguro.

### Requisitos previos
- `NVIDIA_API_KEY` visible para el proceso del backend (el backend hace `dotenv.config()` desde su
  cwd → el `.env` debe estar en `backend/.env`; ver `RAG_ARCHITECTURE.md` §9.6 #5).
- pgvector presente; migración 073 aplicada (`schema_migrations` la registra).
- Circuit breaker `nvidiaEmbeddings` sano (3 fallos/30s → OPEN).

## Paso 3 — Umbral de similitud

Con el modelo vivo el documento correcto puntuó **0.4156** (2º: 0.1988), por debajo del umbral por
defecto `0.45` en `ragService.runVectorSearch`. Debe recalibrarse (p. ej. `0.35–0.40`) tras medir
con el set GOLD; hasta entonces la respuesta correcta puede quedar filtrada. Ver §9.2.

## Paso 4 — Verificación

```sql
-- La columna debe ser 2048 y TODOS los embeddings no nulos
SELECT atttypmod AS dim FROM pg_attribute a JOIN pg_class c ON a.attrelid=c.oid
 WHERE c.relname='beauty_knowledge_embeddings' AND a.attname='embedding';   -- → 2048
SELECT count(*) total, count(embedding) con_vector FROM beauty_knowledge_embeddings; -- total == con_vector
```

```bash
# Traza de una búsqueda real: mode debe ser `hnsw` (vectorial), no `fts` (fallback)
node scripts/evaluateRag.js    # o el probe de retrieval disponible
```

## Evidencia en el repo
- Migración: `backend/migrations/073_rag_embedding_dimension_2048.sql` (+ rollback en `rollback/`).
- Código: `embeddingService.js` (`expectedDimension: 2048`, modelo vivo), `ragService.js` (`EXPECTED_DIMS = 2048`).
- Test de no-regresión: `backend/tests/rag.embedding-dimension.test.js` (comparación estática DDL ↔ código ↔ modelo).

---

## Nota de implementación (2026-10-23): `halfvec`, no `vector`

`vector(2048)` con índice HNSW **no es posible**: pgvector limita HNSW e IVFFlat a 2000
dimensiones para el tipo `vector`, y la migración fallaba con
`column cannot have more than 2000 dimensions for ivfflat index` (la rama de fallback
también fallaba). Por eso nunca se había aplicado y la búsqueda vectorial seguía en 1024d
con un modelo retirado.

La columna se reconstruye como **`halfvec(2048)`** e índice
`USING hnsw (embedding halfvec_cosine_ops)`. Requiere pgvector ≥ 0.7 (producción: 0.8.6).
Consecuencia en código: las consultas castean el parámetro a `::halfvec`; un `halfvec`
no es comparable con un `vector` sin cast explícito.

### Corrección de script (2026-10-23)

El script correcto es **`scripts/ingestCanonicalCorpus.js`**, no `ingestBeautyKnowledge.js`:
este último usa el `pool` de la base PRINCIPAL y escribe en su tabla vestigial
`beauty_knowledge_embeddings` (`embedding real[]`, 6 filas). El corpus real (6.420 chunks en
`vector(1024)`) vive en la base RAG (`RAG_DATABASE_URL`) y `ingestCanonicalCorpus.js` es el
único que usa `ragPool`. Flags: `--limit=N`, `--dry-run`. El guard de seguridad acepta
`railway.internal`, así que se ejecuta dentro del contenedor.
