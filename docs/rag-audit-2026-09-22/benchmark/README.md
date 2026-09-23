# Banco de pruebas: calidad de recuperación con el modelo vivo (2026-09-22)

Mide **sólo la capa de ranking** (embeddings + ordenamiento), sin base de datos, sin filtros y sin
umbral: es el techo del camino semántico si todo lo demás se arregla.

## Qué corre

`eval_live.js` — réplica del texto que embebe la ingesta productiva
(`(title + '\n\n' + content).slice(0, 1400)`), embeddings **en lote** de 64, vectores normalizados
(coseno = producto punto), y tres variantes de ranking sobre el corpus canónico completo:

| Variante | Descripción |
|---|---|
| `vec` | similitud coseno del modelo vivo |
| `bm25` | léxico puro en JS (k1=1.2, b=0.75, stopwords es, sin acentos) |
| `rrf` | híbrido: Reciprocal Rank Fusion de `vec` + `bm25` (k=60) |

Golden = `evaluation_dataset_v2.json` (30 queries, 18 con gold; 65 ids, **100% presentes** en el
corpus canónico). Métricas por query con recall sobre el conjunto de gold de cada query.

## Resultado (18 queries con gold, índice = 5.619 chunks)

| Variante | R@1 | R@5 | R@10 | R@50 | MRR@10 | misses (fuera de top-50) |
|---|---|---|---|---|---|---|
| `vec` | 1,1% | 16,9% | 38,2% | 61,9% | 0,251 | 2 |
| `bm25` | 12,5% | 24,7% | 29,2% | 66,4% | 0,307 | 2 |
| **`rrf` (híbrido)** | **11,7%** | **28,3%** | **43,1%** | **75,3%** | **0,411** | **1** |

Compuertas que el propio proyecto se exige (`backend/src/config/qualityGates.js:10-14`):
P@5 ≥ 0,70 · R@5 ≥ 0,60 · MRR ≥ 0,65 → **ninguna variante las alcanza**.

## Calibración del umbral (el hallazgo)

| Distribución | p10 | p50 | p90 |
|---|---|---|---|
| similitud de un chunk **gold** | 0,341 | **0,427** | 0,575 |
| similitud máxima de un **no-gold** | 0,376 | **0,477** | 0,578 |

El umbral en uso es **0,45** (`ragService.js:101`): la **mediana de los aciertos no lo alcanza**
(0,427) mientras la **mediana del ruido sí lo supera** (0,477). Separan 0,05 → **ningún umbral
separa aciertos de ruido** con este modelo; filtrar por similitud descarta más aciertos que ruido.

## Coste medido

| Modo | ms por embedding | 5.619 chunks |
|---|---|---|
| 1 input por llamada (lo que hace hoy `ingestCanonicalCorpus.js:41`) | 1.053 | ~98 min |
| lote de 64 | 86 | ~8 min |
| lote de 128 | 69 | ~6,5 min |

La API acepta lotes de hasta 128 inputs. `probe_batch.js` reproduce la medición.

## Cómo reproducir

```bash
cd backend
node ../../docs/rag-audit-2026-09-22/benchmark/eval_live.js
```

Necesita `NVIDIA_API_KEY` (se lee de `C:/beauty-app/.env`) y no toca la base de datos: mantiene los
5.619 × 2.048 floats en memoria (~46 MB). Tarda ~8 min.

## Límites de esta medición (declarados)

- **18 queries con gold** no son una base estadística: sirven para comparar variantes entre sí, no
  para fijar una cifra de calidad del producto.
- **No es comparable 1:1 con las cifras históricas** de los ciclos R5/R6 (MRR 0,7222 / R@5 0,6156):
  el modelo de entonces (`nv-embedqa-e5-v5`) ya no responde, así que no se puede re-ejecutar sobre
  el mismo índice, y la definición exacta de sus métricas y su golden puede diferir.
- El **fallback FTS productivo no es este BM25**: el de producción es
  `plainto_tsquery('spanish')` + `ILIKE '%query%'` con `similarity` fija de 0,5. El `bm25` de aquí
  es una cota superior de lo que un léxico bien hecho aportaría.
- `eval_live.js` conserva las rutas absolutas de la máquina donde corrió (ajustar `B` y `OUT`).
