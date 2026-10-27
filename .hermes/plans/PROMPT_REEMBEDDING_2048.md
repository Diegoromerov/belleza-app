# Prompt para la re-ingesta de embeddings a 2048 (halfvec)

Copia el bloque siguiente tal cual y entrégalo al agente que ejecutará la re-ingesta.

---

## PROMPT

Actúa como ingeniero de datos de GlowApp. Tu tarea es **re-embeder el corpus canónico del RAG** en la base pgvector, porque la columna quedó vacía tras la migración a 2048 dimensiones.

### Contexto (no lo investigues, es verificado)

- Tabla: `beauty_knowledge_embeddings` en la base **RAG** (`RAG_DATABASE_URL`), no en la base principal.
- Columna `embedding` ya es `halfvec(2048)`; el índice `idx_beauty_knowledge_embedding_hnsw` existe.
- Estado actual: **6.420 filas, 0 con embedding** (la migración 076 recreó la columna).
- Modelo vivo: `nvidia/llama-3.2-nv-embedqa-1b-v2`, 2048 dimensiones. `NVIDIA_API_KEY` y `NVIDIA_EMBEDDING_DIMS=2048` están configuradas en el servicio.
- Script correcto: `backend/scripts/ingestCanonicalCorpus.js` (usa `ragPool`). Flags: `--limit=N`, `--dry-run`.
- **NO uses `ingestBeautyKnowledge.js`**: escribe en una tabla vestigial de la base principal (`embedding real[]`, 6 filas) y no alimenta el RAG.
- Repo: `C:\Users\Compu casa\belleza-app-audit`, rama `main`. Servicio Railway: `belleza-app`.

### Restricciones duras

1. No ejecutes `DROP`, `TRUNCATE` ni `DELETE` sobre `beauty_knowledge_embeddings`.
2. No cambies el tipo de la columna ni el índice: ya están correctos.
3. No corras la ingesta contra la base principal (`DATABASE_URL`).
4. Si algo falla, **detente y reporta**; no improvises migraciones.

### Paso 1 — Preflight (obligatorio, antes de gastar una sola llamada a la API)

Ejecuta dentro del contenedor (`railway ssh -s belleza-app -- <comando>`):

```bash
cd /app
node -e "
const {Pool}=require('pg');
const p=new Pool({connectionString:process.env.RAG_DATABASE_URL,ssl:false});
(async()=>{
  const t=await p.query(\"SELECT format_type(atttypid,atttypmod) t FROM pg_attribute WHERE attrelid='beauty_knowledge_embeddings'::regclass AND attname='embedding'\");
  const i=await p.query(\"SELECT indexname FROM pg_indexes WHERE tablename='beauty_knowledge_embeddings' AND indexname LIKE '%hnsw%'\");
  const c=await p.query('SELECT count(*)::int n, count(embedding)::int con FROM beauty_knowledge_embeddings');
  console.log('tipo:',t.rows[0].t,'| hnsw:',i.rows.map(r=>r.indexname),'| filas:',c.rows[0]);
  await p.end();
})();"
```

Criterios de aborto: el tipo debe ser `halfvec(2048)`; el índice HNSW debe existir; `con` debe ser 0 o parcial. Si el tipo NO es `halfvec(2048)`, aborta y reporta.

Verifica también que el corpus está disponible y cuántos chunks tiene:

```bash
node -e "const c=require('/app/src/data/corpus_canonico/corpus_canonico.json'); console.log('chunks:', c.chunks.length)"
```

### Paso 2 — Humo con 20 chunks

```bash
node scripts/ingestCanonicalCorpus.js --limit=20 --dry-run   # sin escribir ni llamar a la API
node scripts/ingestCanonicalCorpus.js --limit=20             # 20 embeddings reales
```

Después verifica que esos 20 quedaron bien:

```sql
SELECT count(*) AS con_vector FROM beauty_knowledge_embeddings WHERE embedding IS NOT NULL;
SELECT vector_dims(embedding) AS dims FROM beauty_knowledge_embeddings WHERE embedding IS NOT NULL LIMIT 1;
```

Debe dar `con_vector = 20` y `dims = 2048`. Si `dims` no es 2048, **aborta**: el modelo configurado no es el esperado.

### Paso 3 — Ingesta completa

6.420 chunks a ~120 ms de delay + latencia de la API: estima **entre 40 y 70 minutos**. Lánzala desacoplada de la sesión SSH y sigue el log:

```bash
railway ssh -s belleza-app -- 'cd /app && nohup node scripts/ingestCanonicalCorpus.js > /tmp/ingest-2048.log 2>&1 & echo started'
# progreso
railway ssh -s belleza-app -- 'tail -5 /tmp/ingest-2048.log'
```

El script imprime `[n/total] +insertados ~actualizados err=N (Xs)` y un resumen final con insertados, actualizados y errores.

### Paso 4 — Fallos y reintentos

- Si aparecen errores `429` o timeouts: son límites de la API. **Re-ejecuta el mismo comando**; el script hace upsert idempotente (`ON CONFLICT (document_id, chunk_id)`), así que solo completa lo que falta.
- Si el proceso muere: relánzalo igual; no borres nada.
- Criterio de éxito: `count(embedding)` igual al total de filas y `err=0` en el resumen.

### Paso 5 — Verificación final (todo con evidencia)

```sql
-- 1. Cobertura
SELECT count(*) AS filas, count(embedding) AS con_vector FROM beauty_knowledge_embeddings;

-- 2. Dimensión
SELECT vector_dims(embedding) AS dims, count(*) FROM beauty_knowledge_embeddings
WHERE embedding IS NOT NULL GROUP BY 1;

-- 3. El índice se usa de verdad (debe decir Index Scan using ..._hnsw)
SET enable_seqscan = off;
EXPLAIN (ANALYZE, COSTS OFF)
SELECT id FROM beauty_knowledge_embeddings
ORDER BY embedding <=> (SELECT embedding FROM beauty_knowledge_embeddings WHERE embedding IS NOT NULL LIMIT 1)
LIMIT 5;

-- 4. Similitud real (no debe dar NaN ni valores absurdos)
SELECT 1 - (embedding <=> (SELECT embedding FROM beauty_knowledge_embeddings WHERE embedding IS NOT NULL LIMIT 1)) AS sim
FROM beauty_knowledge_embeddings WHERE embedding IS NOT NULL LIMIT 3;
```

Y una búsqueda de extremo a extremo: la traza del `ragService` debe declarar `mode: hnsw` (ruta vectorial), no `fts` (fallback full-text). Si sigue en `fts`, la re-ingesta o el índice no están sirviendo: repórtalo.

### Paso 6 — Calibración del umbral

Con el modelo vivo, los aciertos puntúan alrededor de **0,4156**, por debajo del umbral por defecto de 0,45: si no se recalibra, la búsqueda vectorial devuelve 0 resultados y cae a full-text otra vez. Ajusta el umbral del RAG a ~0,38–0,40, vuelve a probar 3 consultas reales y deja constancia del valor anterior y el nuevo.

### Formato del reporte final

1. Preflight: tipo de columna, índice, filas antes.
2. Humo 20: `con_vector` y `dims` observados.
3. Ingesta completa: insertados, actualizados, errores, duración real.
4. Verificación: los 4 queries con su salida resumida (cobertura, dims, plan con HNSW, similitudes).
5. Traza del RAG: `hnsw` o `fts`.
6. Umbral: antes → después.
7. Cualquier desviación, con el mensaje de error literal. No maquilles un fallo como éxito.

---

## Nota de estado (para quien lea esto después)

La migración 076 se aplicó el 2026-10-23: `embedding` es `halfvec(2048)` con índice HNSW, y las 6.420 filas quedaron con `embedding NULL`. Hasta que se ejecute esta re-ingesta, **la búsqueda vectorial del RAG no devuelve resultados** y el servicio opera por full-text.
