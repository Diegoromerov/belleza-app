# Registro — Limpieza de filas vestigiales y recuperación del chunk faltante (2026-10-23)

## Autorización

Orden del Director: «aplica b y c» sobre el reporte de estado del re-embedding:
**(b)** borrar las 6.420 filas legacy sin vector y **(c)** re-ingestar el chunk que falló.
El punto (a) —bajar el umbral de 0,45 a 0,40— quedó **fuera** de esta autorización.

## Preflight (base RAG, `RAG_DATABASE_URL`)

| Comprobación | Resultado |
|---|---|
| FKs que apuntan a `beauty_knowledge_embeddings` | **ninguna** (sin riesgo de cascada) |
| Referencias suaves (`%chunk_id%`, `%document_id%`, `%knowledge%` en otras tablas) | **ninguna** |
| Constraints únicos | `beauty_knowledge_embeddings_pkey`, `uk_beauty_knowledge_chunk_identity (document_id, chunk_id)` |
| `beauty_knowledge_title_unique` | ya no existe (se consultó el catálogo; no hay UNIQUE por título) |
| `idx_beauty_knowledge_content_hash` | btree **no único** |

## Respaldo

| | |
|---|---|
| Archivo | `.hermes/backups/legacy_rows_before_delete_20261023.ndjson` |
| Tamaño | 13.027.164 bytes |
| Filas | **6.420** (ids 1–6570, todos únicos) |
| Columnas | todas menos `embedding` (estaba NULL en las 6.420): id, title, category, content, metadata, created_at, updated_at, skin_type, season_station, age_range, ingredients, contraindications, document_id, document_version, chunk_id, content_hash, fuente, seccion |

## Blast radius por dimensión de negocio

El dry-run detectó que la categoría **`skincare` quedaba vacía**. Se investigó antes de borrar:

- `skincare`: **27 filas**, todas legacy, todas tituladas «Sin título - Parte N» (ingesta rota del 2026-08-07).
- Solape de títulos con el corpus canónico: **0**.
- El tema sigue cubierto: `skincare_rutinas_por_tipo_piel` tiene **399** chunks canónicos con vector.

Conclusión: no se pierde contenido sustantivo; se eliminan 27 fragmentos sin título.

## Dry-run

```sql
BEGIN;
DELETE FROM beauty_knowledge_embeddings WHERE embedding IS NULL;  -- rowCount = 6420
SELECT count(*) FROM beauty_knowledge_embeddings;                 -- 5618, con_vector 5618
ROLLBACK;                                                         -- filas_finales = 12038
```

## Ejecución

```sql
BEGIN;
DELETE FROM beauty_knowledge_embeddings WHERE embedding IS NULL;  -- rowCount = 6420 == esperado
COMMIT;
```

Guarda: si `rowCount !== 6420` el script hacía `ROLLBACK` y abortaba. No se disparó.

## Antes / después (conexión nueva, fuera de la transacción)

| | Antes | Después |
|---|---:|---:|
| Filas | 12.038 | **5.619** |
| Con vector | 5.618 | **5.619** |
| Sin vector | 6.420 | **0** |
| Dimensiones | 1024 (legacy) / 2048 | **2048 en las 5.619** |
| Categorías | 13 (`skincare` solo legacy) | 12 |

## (c) Recuperación del chunk faltante

`maquillaje_tecnicas_por_ocasion || maq-evento-microbioma-001`
(«Maquillaje y estabilidad del microbioma en eventos de larga…», 990 caracteres).

Se re-insertó con el mismo SQL del script canónico (`$5::halfvec`, `ON CONFLICT (document_id, chunk_id)`),
generando el embedding con la misma composición de texto que la corrida completa
(`title + '\n\n' + content[:4000]`). Resultado: `inserted: true`, `id = 12229`, 2048 dims.

**Causa del fallo original:** no reproducible. No fue una restricción (no hay UNIQUE por título,
`content_hash` no es único y el chunk no existía en la tabla). Se trató de un error transitorio de
la API de embeddings, el único de 5.619 llamadas.

## Verificación final de cobertura

```
corpus canónico: 5.619 chunks | en BD: 5.619 | faltantes: 0 | sobrantes: 0
```

## Qué NO cubre este cambio

1. **El umbral sigue en 0.45** (`ragService.js:303`). Medición con embeddings reales: una de cada
   seis consultas queda por debajo (melasma: top-1 0,4423) y cae al fallback full-text. Pendiente
   de decisión; el punto (a) no fue autorizado.
2. **Tres scripts pueden repoblar filas con chunking distinto** contra la misma base RAG:
   `scripts/ingest_json_chunks.js`, `scripts/r6Recovery2EmbeddingRebuild.js` y
   `scripts/r6Recovery2FinalRetry{,2}.js` (los tres usan `ragPool`). No están en la ruta de
   ejecución, pero siguen siendo ejecutables. `ingestBeautyKnowledge.js` escribe en la base
   principal, no puede repoblar esta tabla.
3. No hizo falta invalidar cachés: las lecturas del RAG son consultas en vivo.
