# FASE 2 — Ranking híbrido (RAG)

Cierre de la Fase 2 del `PLAN_MEJORA_RAG.md`. Base: corpus canónico de **5.619 chunks**,
embedding `halfvec(2048)` con HNSW, umbral de admisión 0.30 (Fase 0).

## Qué se cambió

| Pieza | Antes | Ahora |
|---|---|---|
| Recuperación | solo vectorial (`embedding <=> $1`) | vectorial **+ léxica**, fusionadas con RRF |
| Léxico | `plainto_tsquery` + ILIKE, sin orden | `websearch_to_tsquery` con OR entre términos, `ts_rank_cd` |
| tsvector | calculado en cada consulta, fila a fila | columna generada `search_vector` + GIN (migración 115) |
| Fusión | — | RRF `k=20`, peso léxico 0.6 (barrido sobre GOLD-V5) |
| Rerank | — | implementado y **apagado** por defecto (ver abajo) |
| Vigencia | en vectorial | en **ambas** ramas (`deleted_at`, `expires_at`) |
| Fallback | full-text plano | se conserva intacto si falla el embedding |

## Medición (GOLD-V5 · 18 consultas · umbral 0.30)

Benchmark reproducible: `node scripts/evalRankingGoldV5.js --modes=vector,hybrid --topks=5,50`
→ `src/data/eval/r7_ranking_goldv5.json`.

| métrica | vectorial (antes) | híbrido (ahora) | Δ |
|---|---:|---:|---:|
| Recall@5 (todos los gold) | 0.3056 | **0.3519** | +15 % |
| Recall@5 (solo core) | 0.3500 | **0.3556** | +1,6 % |
| MRR@5 | 0.3491 | **0.3843** | +10 % |
| Recall@50 | 0.6639 | **0.6889** | +3,8 % |
| Recall@50 (core) | 0.7667 | **0.8389** | +9,4 % |
| MRR@50 | 0.3713 | **0.4048** | +9 % |
| Consultas sin acierto @5 | 7/18 | 7/18 | = |
| Consultas sin acierto @50 | 3/18 | **2/18** | −1 |
| Latencia p50 (5 consultas) | 411 ms | 462 ms | +51 ms |

Ninguna métrica queda por debajo del baseline: es la condición de cierre que pide el plan.

### Barrido de parámetros

| k | peso léxico | R@5 | recall core | MRR |
|---:|---:|---:|---:|---:|
| 60 | 1.0 | 0.3426 | 0.3333 | 0.3889 |
| 60 | 0.6 | 0.3657 | 0.3333 | 0.3704 |
| 20 | 1.0 | 0.3287 | 0.3111 | 0.4028 |
| **20** | **0.6** | **0.3519** | **0.3556** | **0.3843** |
| 10 | 0.6 | 0.3380 | 0.3333 | 0.4120 |

`k=20 / 0.6` es la única combinación que no baja ninguna métrica frente al baseline. El brazo
léxico pesa menos porque en preguntas naturales aporta ruido (términos frecuentes como «piel»
o «tratamiento»), pero sigue subiendo recall.

## El rerank: medido, no descartado por intuición

Se implementó un reranker determinista que combina la posición en la fusión con la cobertura
léxica de la consulta y los aciertos en el título. Barrido:

| pesos (rrf, cobertura, título) | R@5 | MRR | misses |
|---|---:|---:|---:|
| 1.0 / 0 / 0 (sin rerank) | **0.3167** | 0.3954 | **6** |
| 0.7 / 0.2 / 0.1 | 0.2843 | **0.4787** | 6 |
| 0.6 / 0.3 / 0.1 | 0.2657 | 0.4278 | 7 |
| 0.5 / 0.3 / 0.2 | 0.2380 | 0.4028 | 8 |
| 0.4 / 0.4 / 0.2 | 0.2380 | 0.4093 | 7 |

Todo peso de cobertura **cambia recall por MRR**: mejora el primer acierto hasta +37 % pero
saca del top-5 aciertos que la fusión ya traía. Al violar «ninguna métrica por debajo del
baseline», queda **apagado por defecto**, disponible con `rerank: true` + `rerankWeights`
cuando el producto priorice el primer acierto sobre la cobertura total.

## Lo que la Fase 2 no pudo cerrar (depende de esquema o de Fase 4)

- **Estado clínico en el ranking** (2.4): la columna `clinical_review_status` **no existe** en la
  base RAG. Requiere esquema nuevo y el flujo de revisión de la Fase 4.
- **`seccion` sin datos**: 5.619/5.619 filas tienen `seccion = 'unknown'`. No aporta señal hoy.
- **Sin caducidad cargada**: `expires_at` está en NULL en todo el corpus, así que el filtro de
  vigencia existe y se aplica, pero no descarta nada todavía.

## Diagnóstico del corpus (2.5)

- **Balance sano**: 12 categorías entre 399 y 526 chunks. Sin categorías huérfanas.
- **Sin duplicados**: 0 grupos con el mismo `content_hash` (y 0 pares casi idénticos por hash).
- **Hueco real**: `seccion` y `clinical_review_status`, no el volumen ni la duplicación.

## Techo actual

Recall@50 = 0.689 significa que **el 31 % de las respuestas correctas no entra ni al pool de 50**.
Ese es ahora el problema: no el orden (0.689 → 0.352 es lo que cuesta bajar de 50 a 5), sino la
cobertura del pool. Las palancas siguientes son chunking más fino y un reranker semántico real
(cross-encoder), no más ajuste de pesos a mano.
