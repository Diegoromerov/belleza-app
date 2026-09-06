# R6-C13 Corpus Expansion Audit — Informe para ChatGPT

**Proyecto:** GlowApp / belleza-app (Diegoromerov/belleza-app)  
**Ciclo:** R6-C13 completado — Estado: `CORPUS-EXPANSION-DISCONFIRMED`  
**Fecha:** 2026-08-18 | **Modelo:** nvidia/nemotron-3-ultra-550b-a55b

---

## Veredicto en una frase

**La expansión de corpus NO resolverá los 13 VECTOR_MISS**: 0 gaps reales de cobertura, 8 son *semantic representation gaps* (el contenido existe abundantemente pero e5-v5 no lo ancla al query coloquial), 5 son *retrieval instability* (fluctúan dentro/fuera del top-200 por inestabilidad del query-embedding NVIDIA NIM).

---

## Evidencia clave (medida, no asumida)

| Métrica | Valor |
|---------|-------|
| Chunks en BD | 5,663 (0 NULL, HNSW OK) |
| Chunks canónicos | 5,619 |
| 13 VECTOR_MISS | **Todos existen** en BD + canónico con embeddings válidos |
| Cobertura semántica corpus | Simetría 147, Tyndall 59, Láser 183, SERS 113, Autofagia 79, LHA 66 chunks |
| Baseline R6-C11 | MRR 0.7222, R@5 0.6156, R@10 0.6545, VECTOR_MISS 13/58 |

### Rankings reales (NVIDIA NIM + BD local, READ-ONLY)

| Miss | Chunk | Rank | Sim | Clasificación |
|------|-------|------|-----|---------------|
| cejas_004 | musculatura-orbicular | **>3000** | — | **C** Semantic (SEVERO) |
| cejas_004 | arquitectura-muscular | ~1033 | 0.41 | **C** Semantic |
| cejas_004 | envejecimiento-009 | **~5** | 0.52 | **D** Instability |
| cejas_004 | psicologia-007 | ~377 | 0.44 | **C** Semantic |
| cabello_002 | SERS | ~567 | 0.43 | **C** Semantic |
| skincare_003 | LHA | ~1998 | 0.35 | **C** Semantic |
| skincare_007 | autofagia | ~651 | 0.32 | **C** Semantic |
| cejas_008 | laser-erbio-glass | ~1805 | 0.41 | **C** Semantic (cross-domain) |
| cejas_008 | electrolisis-uñas | ~606 | 0.45 | **C** Semantic (cross-domain) |
| cejas_008 | tyndall | ~177 | 0.50 | **D** Instability |
| cejas_005 | fotoproteccion | ~152 | 0.50 | **D** Instability |
| cejas_005 | glucemia | ~172 | 0.49 | **D** Instability |
| cabello_006 | homeostasis | ~83 | 0.37 | **D** Instability |

---

## Hallazgo crítico: cejas_004 = CONTROL NEGATIVO

El chunk **"Análisis de simetría facial dinámica"** (título literal coincidente con el query "cejas asimétricas") obtiene **sim=0.42, rank ~2857 de 5663**. Hay **110+ chunks equivalentes** en el corpus con overlap semántico alto. **Añadir más contenido no acerca el embedding al query** — el gap es de representación semántica del modelo, no de cobertura.

---

## Inestabilidad NVIDIA NIM confirmada

`microblading-envejecimiento-009`: **rank 5 en barrido actual** vs **miss en R6-C11** → el query-embedding NVIDIA **no es bit-exacto entre llamadas** (ya documentado en R6-RECOVERY). Los 5 misses "borderline" (ranks 83-177) fluctúan dentro/fuera del top-200 por esto.

---

## Queda descartado

- ❌ Corpus expansion (0 gaps reales)
- ❌ Fine-tuning NVIDIA (NIM sin pesos, no existe en HF)
- ❌ Cambiar modelo oficial (decisión inmutable)
- ❌ Reranking solo (R6-C11: no rescata chunks fuera del candidate pool)
- ❌ Repetir R6-C7/C8/C9/C11 (cerrados con veredicto definitivo)

---

## Única mejora neta confirmada

**Dense+Sparse (R6-C11)**: **MRR +0.033 determinista, reproducible, 0 regresiones** — no recupera misses pero mejora ranking general.

---

## Próximos pasos viables (requieren decisión Director)

| Opción | Qué hace | Esfuerzo |
|--------|----------|----------|
| **R6-C14 Rediseñado** | 10+ runs idénticos, congelar top-200, medir varianza rank/GOLD → separar artefactos de inestabilidad vs gaps semánticos reales | Medio (READ-ONLY) |
| **R6-C12-A Projection Head** | Entrenar capa proyección (Linear/MLP) sobre embeddings salida NVIDIA con data sintética corpus, GOLD-V5 test puro | Alto (requiere torch/transformers local) |
| **Adoptar Dense+Sparse** | Pipeline retrieval híbrido en producción | Bajo (código existe, solo activar) |
| **Cerrar R6** | Documentar límite conocido e5-v5 para conceptos ultraespecializados | Mínimo |

---

## Artefactos generados (validados, READ-ONLY)

```
backend/src/data/eval/r6c13_corpus_expansion_audit.json      (19.5 KB)
backend/src/data/eval/r6c13_corpus_expansion_proposals.json  (1.2 KB, 0 propuestas)
backend/scripts/r6c13_build_audit.py                         (builder reproducible)
backend/src/data/eval/r6c12_finetuning_feasibility.json      (17.9 KB)
backend/src/data/eval/r6c12_finetuning_feasibility.md        (9.2 KB)
```

---

## Verificación regresión (3 runs frescos)

| Suite | Resultado |
|-------|-----------|
| RAG (embeddingService + rag) | **69/69 PASS** ✅ |
| Global | **261 PASS / 10 FAIL / 1 SKIP** — 8 históricos inmutables + 2 flaky documentados — **cero regresiones nuevas** |

---

## Regla de oro

> **NVIDIA e5-v5 sigue siendo el modelo oficial.**  
> No busques modelo superior. No propongas cambiar modelo por defecto.  
> El límite es la **representación semántica del modelo**, no la cobertura del corpus.

---

## Para continuar en ChatGPT

Pega este informe y di: *"Asumo como Director R6 post-C13. Estado: CORPUS-EXPANSION-DISCONFIRMED. Modelo oficial NVIDIA e5-v5 inmutable. 13 VECTOR_MISS: 8 semantic representation gaps, 5 retrieval instability. Próximo paso: [elige: R6-C14 stability audit / R6-C12-A projection head / Dense+Sparse adoption / cierre R6]"*