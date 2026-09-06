# PROMPT DE TRANSFERENCIA TÉCNICA — GLOWAPP RAG R6-C13 HANDOFF

---

## 1. CONTEXTO DEL PROYECTO

**Repositorio:** `Diegoromerov/belleza-app` (backend en `/c/beauty-app/backend`)  
**Rol actual:** Investigador senior de Retrieval/Embeddings/RAG — ciclos R6-C12 y R6-C13 completados  
**Modelo embeddings oficial (INTOCABLE):** `NVIDIA nv-embedqa-e5-v5` (1024 dimensiones, managed API)  
**Base de datos:** PostgreSQL local `beauty_db` (puerto 5435), tabla `beauty_knowledge_embeddings` — 5,663 chunks, 0 NULL, HNSW `idx_beauty_knowledge_embedding_hnsw`  
**Dataset evaluación:** GOLD-V5 — 15 queries SUPPORTED, 58 GOLD chunks totales  

---

## 2. HISTORIAL DE CICLOS R6 (VERIFICADOS Y CERRADOS)

| Ciclo | Objetivo | Veredicto | Hallazgo Clave |
|-------|----------|-----------|----------------|
| R6-C1/2/3 | Recuperación embeddings históricos / drift | Drift confirmado | Modelo NVIDIA managed no reproduce bit-exacto espacio histórico; GOLD-V5 histórico no comparable directo |
| R6-C4 | Baseline R6 provisional + grouping | Establecido | Grouping mejora R@5/MRR pero no rompe techo retrieval |
| R6-C5 | Sufficiency Gate calibration | DISCONFIRMED | No existe configuración segura que resuelva el problema |
| R6-C7 | K=50→100→200 | AGOTADO | Ampliar K no recupera GOLD nuevos; category boost y light reranking perjudican MRR |
| R6-C8 | Hybrid Vector + FTS | MARGINAL | MRR 0.7222→0.7556; recupera **solo 1 GOLD nuevo**; no resuelve `cejas_004` |
| R6-C9 | Adaptive Hybrid (gates A-E) | DISCONFIRMED | `top1_score` no distingue VECTOR_MISS recuperable de irrecuperable; Gate A pierde `cabello_002`, Gates B-E ≈ HYBRID_ALWAYS |
| R6-C10 | Corpus Expansion + Model Eval (NVIDIA vs mxbai) | **EMBEDDING_LIMITATION_NO_BETTER_MODEL** | **Corpus gap = 0** (58/58 GOLD físicamente presentes); **13 VECTOR_MISS** (existen + embedding pero no en top-200); mxbai PEOR en todo (MRR −0.19, R@5 −0.37) |
| R6-C11 | Retrieval Enhancement alrededor de NVIDIA | **NVIDIA_BASELINE_CONFIRMED** | 7 estrategias evaluadas (Query Expansion, Multi-query, HyDE, Dense+Sparse, Candidate Fusion, Routing, Reranking); **ninguna cumple 8 criterios adopción simultáneamente**; Dense+Sparse mejora MRR +0.033 (determinista) pero 0/13 misses; Candidate Fusion recupera hasta 5/13 PERO MRR −24%, R@5 −37% y **no reproducible** (LLM no determinista) |
| **R6-C12** | Fine-tuning / Domain Adaptation Feasibility | **FEASIBILITY-BLOCKED** | **nv-embedqa-e5-v5 es modelo NVIDIA NIM gestionado SIN pesos accesibles** (no existe en HuggingFace; API solo expone inferencia); **GOLD-V5 = dataset de evaluación (15 queries, 58 pares, 0 negativos, 3 chunks compartidos) — NO sirve para entrenar**; infra ML ausente en repo. Vía viable única: **Projection Head** sobre embeddings salida NVIDIA (entrenada con data sintética del corpus, GOLD-V5 como TEST puro) — diseñada pero NO ejecutada. |
| **R6-C13** | Corpus Expansion & Semantic Coverage Audit | **CORPUS-EXPANSION-DISCONFIRMED** | **0 corpus gaps reales**: los 13 chunks GOLD existen en BD y canónico con embeddings válidos; los conceptos tienen cobertura abundante (simetría 147, Tyndall 59, láser 183, SERS 113, autofagia 79, LHA 66 chunks). Clasificación causal: **8/13 = C_SEMANTIC_REPRESENTATION_GAP** (contenido existe pero e5-v5 no lo acerca al query coloquial); **5/13 = D_RETRIEVAL_GAP** (inestabilidad de frontera top-200 por inestabilidad del query-embedding NVIDIA NIM — confirmado: `envejecimiento` rank 5 en barrido actual vs miss en R6-C11). **cejas_004 es CONTROL NEGATIVO**: chunk "Análisis de simetría facial dinámica" obtiene sim=0.42 (rank ~2857) — gap es de anclaje semántico, NO de cobertura. Expansión de corpus NO resolverá los 8 DEEP_MISS. |

---

## 3. ESTADO ACTUAL — POST R6-C13

### Modelo Oficial
- **NVIDIA nv-embedqa-e5-v5** sigue siendo el embedding oficial e intacto
- API: `https://integrate.api.nvidia.com/v1/embeddings` (input_type: "query"/"passage")
- Sin acceso a pesos, tokenizer, checkpoints — inferencia pura

### Corpus y BD
- **5,663 chunks** en BD, **5,619 en corpus canónico** (`src/data/corpus_canonico/corpus_canonico.json`)
- **0 NULL embeddings**, HNSW operacional
- Todos los 13 VECTOR_MISS existen en BD + canónico con contenido íntegro

### Baseline Métricas (R6-C11 NVIDIA_BASELINE_CONFIRMED)
```
MRR: 0.7222
R@5: 0.6156
R@10: 0.6545
R@50: 0.8011
VECTOR_MISS: 13/58 (22.4%)
```

### Mejora Neta Adoptable (Única Confirmada)
- **Dense+Sparse (R6-C11)**: MRR +0.033 (determinista, reproducible) — 0/13 misses recuperados

---

## 4. LOS 13 VECTOR_MISS CANÓNICOS (Fuente: `src/data/eval/r6c11_canonical_misses.json`)

| # | Query | Chunk GOLD | Rank Aprox | Sim | Clasificación Causal |
|---|-------|-----------|------------|-----|---------------------|
| 1 | skincare_003 | LHA descamación | ~1998 | 0.3505 | **C** Semantic Representation |
| 2 | skincare_007 | Autofagia péptidos | ~651 | 0.3157 | **C** Semantic Representation |
| 3 | cabello_002 | SERS diagnóstico | ~567 | 0.4255 | **C** Semantic Representation |
| 4 | cabello_006 | Homeostasis scalp | ~83 | 0.3679 | **D** Retrieval Instability |
| 5 | cejas_004 | Musculatura orbicular | >3000 | — | **C** Semantic Representation (SEVERO) |
| 6 | cejas_004 | Arquitectura muscular | ~1033 | 0.4126 | **C** Semantic Representation |
| 7 | cejas_004 | Envejecimiento/ptosis | ~5 | 0.5194 | **D** Retrieval Instability |
| 8 | cejas_004 | Psicología/sesgos | ~377 | 0.4434 | **C** Semantic Representation |
| 9 | cejas_005 | Fotoprotección post | ~152 | 0.4965 | **D** Retrieval Instability |
| 10 | cejas_005 | Variabilidad glucémica | ~172 | 0.4933 | **D** Retrieval Instability |
| 11 | cejas_008 | Electrólisis (uñas) | ~606 | 0.4486 | **C** Semantic Representation (cross-domain) |
| 12 | cejas_008 | Láser erbio-glass | ~1805 | 0.4105 | **C** Semantic Representation (cross-domain) |
| 13 | cejas_008 | Efecto Tyndall | ~177 | 0.4984 | **D** Retrieval Instability |

**Resumen Clasificación:**
- **A CORPUS_GAP**: 0
- **B PARTIAL_COVERAGE**: 0
- **C SEMANTIC_REPRESENTATION_GAP**: 8 (LHA, autofagia, SERS, musculatura, arquitectura, psicología, electrólisis, láser)
- **D RETRIEVAL_GAP (instability)**: 5 (homeostasis, envejecimiento, fotoprotección, glucemia, Tyndall)
- **E MIXED**: 0
- **F UNKNOWN**: 0

---

## 5. ARTEFACTOS GENERADOS (READ-ONLY / NO PRODUCTIVOS)

### R6-C12
```
backend/src/data/eval/r6c12_finetuning_feasibility.json    (17.9 KB) — Análisis completo factibilidad
backend/src/data/eval/r6c12_finetuning_feasibility.md      (9.2 KB)  — Narrativa técnica
backend/scripts/r6c12_build_feasibility_json.py            — Builder one-shot
```

### R6-C13
```
backend/src/data/eval/r6c13_corpus_expansion_audit.json    (19.5 KB) — Auditoría completa
backend/src/data/eval/r6c13_corpus_expansion_proposals.json (1.2 KB)  — 0 propuestas justificadas
backend/scripts/r6c13_build_audit.py                       — Builder one-shot
```

### Evidencia de Integridad
- **NVIDIA e5-v5**: Inalterado (API inferencia only)
- **BD**: 0 writes, 0 schema changes
- **Railway**: No contactada
- **Producción**: Intacta
- **Embeddings**: Sin re-generar
- **Corpus**: Sin modificar

---

## 6. EXPERIMENTOS EJECUTADOS (READ-ONLY)

### Barridos Vectoriales Reales (NVIDIA NIM, BD local)
Ejecutados via `scripts/r6c13_build_audit.py` → llamadas directas a NVIDIA API + PostgreSQL:
- Queries reales embebidas con `input_type: 'query'`
- Top-3000 rankings obtenidos via `embedding <=> $1::vector`
- Ranks reales vs R6-C11 checkpoint confirmados
- **Descubrimiento crítico**: `microblading-envejecimiento-009` rank 5 (actual) vs miss en R6-C11 → **inestabilidad query-embedding NVIDIA NIM confirmada**

### Análisis Cobertura Corpus
- Keyword sweep sobre 5,619 chunks canónicos
- Búsqueda chunks equivalentes (overlap ≥3 términos significativos)
- cejas_004: 110-111 chunks equivalentes para musculatura/arquitectura, 55 para psicología, 8 para envejecimiento
- **Conclusión**: Contenido existe abundantemente; e5-v5 no lo ancla al query coloquial

---

## 7. VERIFICACIÓN DE REGRESIÓN (Obligatoria)

### RAG Suite (embeddingService + rag)
```
Test Suites: 5 passed, 5 total
Tests:       69 passed, 69 total
```
✅ Sin regresiones

### Global Suite
```
Test Suites: 6 failed, 29 passed, 35 total
Tests:       10 failed, 1 skipped, 261 passed, 272 total
```
**FAILs idénticos al baseline histórico (cero nuevos):**
- 8 históricos inmutables: `biometric.integration` (3), `biometricE2E`, `contract/biometric-scan` (3), `geminiFallback`
- 2 flaky documentados: `fase5_e2e_integration`, `geminiService`

---

## 8. LO QUE NO SE DEBE HACER (Restricciones Vigentes)

| ❌ PROHIBIDO | Razón |
|--------------|-------|
| Cambiar NVIDIA e5-v5 | Decisión arquitectónica inmutable |
| Fine-tuning productivo | NIM no expone pesos |
| Re-ingesta productiva | Corpus intacto, embeddings válidos |
| Modificar embeddings actuales | 5,663 chunks con embeddings NVIDIA históricos |
| Modificar Railway | Entorno productivo intocable |
| Modificar producción | Cero cambios autorizados |
| Repetir R6-C7/C8/C9/C11 | Cerrados con veredicto definitivo |
| Intentar rescatar VECTOR_MISS solo via reranking | R6-C11: reranker no rescata chunks fuera del candidate pool |
| Construir Evidence Aggregator | Fuera de scope R6 |
| Inventar evidencia médica/cosmética | Regla de oro R6-C13 |

---

## 9. LO QUE SÍ SE PUEDE INVESTIGAR (Próximos Pasos Viables)

### Opción A: R6-C14 REDISEÑADO — Query-Embedding Stability Audit + Frontier Analysis
**Objetivo:** Cuantificar cuántos de los 13 "misses" son artefactos de inestabilidad del query-embedding NVIDIA NIM vs gaps semánticos reales irrecuperables.

**Diseño:**
1. Ejecutar **N runs (N≥10)** del mismo set de 7 queries con NVIDIA NIM
2. Congelar top-200 completo por run
3. Medir varianza de rank por chunk GOLD (desviación estándar, % runs dentro/fuera top-200)
4. Clasificar: `STABLE_MISS` (siempre fuera) vs `UNSTABLE_BORDERLINE` (fluctúa)
5. Solo los `STABLE_MISS` son verdaderos representation gaps

**Expected outcome:** Los 5 borderline (homeostasis, envejecimiento, fotoprotección, glucemia, Tyndall) probablemente `UNSTABLE_BORDERLINE`. Los 8 DEEP_MISS probablemente `STABLE_MISS`.

### Opción B: Projection Head Prototype (R6-C12-A) — Fuera de Producción
**Objetivo:** Entrenar capa de proyección (Linear/MLP 1024→1024) sobre embeddings salida NVIDIA usando:
- Train: Pares sintéticos del corpus (título→chunk + hard negatives intra-categoría) — ~5000+ pares
- Val: Subset GOLD-V5 separado por categoría (solo monitoreo)
- Test: GOLD-V5 completo (TEST PURO, nunca en train)
- Loss: InfoNCE contrastive
- Baseline: Identidad (sin proyección)

**Requisitos:** Infra ML local (torch/transformers — NO instalados en repo; instalación experimental permitida local).

**Riesgo:** Data sintética (títulos) puede no capturar gap semántico-cognitivo (Tyndall, SERS, simetría muscular).

### Opción C: Dense+Sparse Production Adoption
Única mejora neta confirmada: **+0.033 MRR determinista, 0 regresiones**. Requiere decisión del Director para adoptar en producción (añade BM25/FTS al pipeline retrieval).

### Opción D: Cierre R6 — Documentar Límite Conocido
Aceptar que e5-v5 tiene techo de representación para conceptos ultraespecializados (Tyndall, SERS, simetría muscular dinámica, psicología de la percepción) y documentar como limitación conocida del modelo oficial.

---

## 10. CRITERIOS DE DECISIÓN PARA EL PRÓXIMO DIRECTOR

| Si el Director quiere... | Acción Recomendada |
|---------------------------|-------------------|
| Medir inestabilidad real antes de decidir | **Ejecutar R6-C14 REDISEÑADO** (10+ runs, estadísticas de frontera) |
| Explorar adaptación sin tocar NVIDIA | **Ejecutar R6-C12-A** (Projection Head, infra ML local, GOLD test puro) |
| Adoptar única mejora neta confirmada | **Adoptar Dense+Sparse** en producción (requiere approval Director) |
| Cerrar investigación R6 | **Documentar límite** y pasar a siguiente fase producto |

---

## 11. COMANDOS DE VERIFICACIÓN POST-TRANSFERENCIA

```bash
# 1. JSON parse
cd /c/beauty-app/backend
python3 -c "
import json
a = json.load(open('src/data/eval/r6c13_corpus_expansion_audit.json', encoding='utf-8'))
p = json.load(open('src/data/eval/r6c13_corpus_expansion_proposals.json', encoding='utf-8'))
assert a['status'] == 'CORPUS-EXPANSION-DISCONFIRMED'
assert len(a['canonical_misses']) == 13
assert p['proposed_chunks'] == []
print('ARTIFACTS: OK')
"

# 2. RAG Suite
npm test -- --testPathPattern="(embeddingService|rag)" 2>&1 | grep -E "^(Test Suites:|Tests:)"

# 3. Global Suite (baseline check)
npm run test 2>&1 | grep -E "^(Test Suites:|Tests:)"

# 4. BD Integrity
node -e "
const {Pool}=require('pg');
const p=new Pool({connectionString:'postgresql://admin:admin123@localhost:5435/beauty_db'});
p.query('SELECT COUNT(*) t, COUNT(*) FILTER (WHERE embedding IS NULL) n FROM beauty_knowledge_embeddings')
  .then(r=>console.log('BD:',r.rows[0])).catch(e=>console.error(e));
"

# 5. Git status (solo artefactos nuevos untracked)
git status --short | grep "^??"
```

---

## 12. INFORME EJECUTIVO FINAL — PARA EL NUEVO DIRECTOR

### VEREDICTO R6-C13
**`CORPUS-EXPANSION-DISCONFIRMED`**

### Resumen Cuantitativo
- **13 VECTOR_MISS** analizados con rankings reales (NVIDIA NIM + BD local)
- **0** son CORPUS_GAP real (A)
- **0** son PARTIAL_COVERAGE (B)
- **8** son SEMANTIC_REPRESENTATION_GAP (C) — contenido existe abundantemente, e5-v5 no lo ancla
- **5** son RETRIEVAL_GAP por inestabilidad frontera (D) — fluctuaron dentro/fuera top-200 entre ejecuciones
- **0** MIXED / UNKNOWN

### Chunks Nuevos Propuestos
**0** — La auditoría determinó que NO hay corpus gaps reales. Proponer chunks sería duplicación de contenido ya presente (simetría 147 chunks, Tyndall 59, láser 183, SERS 113, autofagia 79, LHA 66) con riesgo de contaminación de categorías y sin efecto sobre el espacio semántico e5-v5.

### Impacto Esperado de Corpus Expansion
**0/13** recuperación esperada vía expansión de corpus. Los 8 DEEP_MISS requieren cambio de representación semántica (bloqueado por decisión de mantener NVIDIA). Los 5 borderline podrían recuperarse estabilizando retrieval (K mayor + rerank determinista, o cache de query-embedding).

### Lo que NO Puede Resolver Corpus Expansion
- Gap semántico entre "cejas asimétricas" (coloquial) y "dinámica muscular orbicular" (técnico)
- Términos ultraespecializados: Tyndall, SERS, electrólisis cross-domain, arquitectura muscular
- Conexiones conceptuales indirectas: decoloración → daño proteico → SERS
- Inestabilidad intrínseca del query-embedding NVIDIA NIM (no bit-exacto entre llamadas)

### ¿Procede R6-C14?
**SÍ, pero REDISEÑADO**: No "Corpus Expansion Controlled Re-embedding" (ya desacreditado), sino **"Query-Embedding Stability Audit + Frontier Analysis"** para separar artefactos de inestabilidad de gaps semánticos reales.

### Qué Debe Hacer el Director Después
1. **Decidir prioridad**: Estabilidad (R6-C14 rediseñado) vs Adaptación (R6-C12-A Projection Head) vs Adopción (Dense+Sparse) vs Cierre
2. **Si elige R6-C14**: Ejecutar 10+ runs idénticos, congelar top-200, medir varianza rank por GOLD chunk
3. **Si elige R6-C12-A**: Instalar torch/transformers local, entrenar proyección con data sintética, validar en GOLD test puro
4. **Si elige Dense+Sparse**: Aprobar adopción en pipeline retrieval (única mejora neta +0.033 MRR confirmada)
5. **En todos los casos**: NVIDIA e5-v5 permanece oficial; producción/BD/Railway intactos

### Estado de Producción / BD / Railway
- **Producción**: INTACTA (0 cambios)
- **BD**: 5,663 chunks, 0 NULL, HNSW operacional, 0 writes
- **Railway**: NO contactada
- **NVIDIA e5-v5**: Modelo oficial sin modificar

---

## 13. REGLA DE ORO (Inmutable)

> **NVIDIA e5-v5 sigue siendo el modelo oficial.**
> No busques un modelo superior.
> No propongas cambiar el modelo como solución por defecto.
> La pregunta de R6 ya no es "qué modelo", sino: **¿cómo hacemos que el corpus y el retrieval funcionen MEJOR para el modelo que YA decidimos conservar?**
> 
> R6-C13 respondió: **el corpus ya es óptimo para e5-v5; el límite es la representación semántica del modelo, no la cobertura del contenido.**

---

## 14. ARCHIVOS CLAVE PARA LEER (Orden Recomendado)

1. `backend/src/data/eval/r6c13_corpus_expansion_audit.json` — Evidencia completa
2. `backend/src/data/eval/r6c12_finetuning_feasibility.json` — Por qué fine-tuning bloqueado
3. `backend/src/data/eval/r6c11_canonical_misses.json` — 13 misses canónicos (dataset central)
4. `backend/src/data/eval/r6c11_causal_decision.json` — Veredicto NVIDIA_BASELINE_CONFIRMED
5. `backend/src/services/embeddingService.js` — Arquitectura NVIDIA NIM (L1-L180)
5. `backend/scripts/r6c13_build_audit.py` — Código que generó la auditoría (reproducible)

---

**FIN DEL PROMPT DE TRANSFERENCIA**  
*Generado 2026-08-18 — Estado verificado: R6-C12 FEASIBILITY-BLOCKED, R6-C13 CORPUS-EXPANSION-DISCONFIRMED*  
*Modelo activo: nvidia/nemotron-3-ultra-550b-a55b via NVIDIA*  
*RAG Suite: 69/69 PASS | Global: 261/10/1 (baseline histórico intacto)*  
*Producción/BD/Railway: INTACTOS*