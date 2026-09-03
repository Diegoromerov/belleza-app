# GLOWAPP — R7-S PRODUCTION OBSERVABILITY & CONFIDENCE SPECIFICATION

**Phase:** R7-S — Specification  
**Status:** SPECIFICATION COMPLETE — READ ONLY  
**Timestamp:** 2026-08-21  
**Repository:** C:\beauty-app  

---

## 1. Status

**SPECIFICATION COMPLETE — READY FOR R7-I (IMPLEMENTATION)**

Observability and confidence-calibration specification designed for the existing GlowApp AURA/RAG pipeline. No implementation. No production modifications. Baseline RAG (MRR 0.7222) preserved.

---

## 2. Observability Model

### 2.1 Telemetry Categories (14 Domains)

| Domain | Purpose | Key Signals |
|--------|---------|-------------|
| **Query** | Input characterization | trace_id, timestamp, category, normalized query, filters, mode, top_k, threshold, latency |
| **Embedding** | Vector generation health | latency_ms, dimension, zero_vector_check, circuit_breaker_state, model_version, api_status |
| **Retrieval** | Search quality | top_1_score, score_distribution, score_separation, result_count, mode (hnsw/fts/hybrid) |
| **HNSW** | Vector index behavior | ef_search, candidate_pool_size, recall_at_k, latency_p50/p95, index_health |
| **FTS Fallback** | Fallback activation | trigger_reason, query, result_count, latency, score_distribution |
| **Hybrid Retrieval** | Fusion effectiveness | rrf_weights, vector_contribution, fts_contribution, rank_changes, mrr_delta |
| **Evidence** | Retrieved chunk quality | chunk_ids, provenance (doc_id, version, chunk_id, fuente, seccion), similarity_scores, category_diversity |
| **Sufficiency** | Evidence adequacy gate | gate_input_signals, gate_output (SUFFICIENT/INSUFFICIENT/UNCERTAIN), threshold_used, calibration_version |
| **Response** | Generation quality | llm_used, latency_ms, token_count, citations_included, hallucination_flags, user_feedback |
| **Errors** | Failure taxonomy | error_type, stage, recoverable, circuit_breaker_triggered, fallback_activated, user_visible |
| **Latency** | End-to-end performance | total_p50/p95/p99, embedding_p50/p95, retrieval_p50/p95, llm_p50/p95, breakdown_by_stage |
| **Circuit Breaker** | Resilience monitoring | state (closed/open/half_open), failure_count, success_count, next_attempt, recovery_latency |
| **Confidence** | Calibrated scoring | retrieval_confidence, evidence_confidence, answer_confidence, composite_confidence, band (HIGH/MEDIUM/LOW/ABSTAIN) |
| **User Outcome** | Product impact | action_taken (booking, purchase, re-query, dismiss), satisfaction_signal, task_completion |

### 2.2 Observability Pipeline Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   QUERY     │───▶│  EMBEDDING  │───▶│  RETRIEVAL  │───▶│  EVIDENCE   │───▶│  GENERATION │
│  TELEMETRY  │    │  TELEMETRY  │    │  TELEMETRY  │    │  TELEMETRY  │    │  TELEMETRY  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       │                │                │                │                │
       ▼                ▼                ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    UNIFIED TRACE CONTEXT (trace_id)                              │
│  • Query → Embedding → Retrieval → Evidence → Generation → Response             │
│  • Latency breakdown per stage                                                 │
│  • Error/failure propagation                                                   │
│  • Circuit breaker state at each hop                                           │
└─────────────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
            ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
            │  CONFIDENCE │ │  SUFFICIENCY│ │  USER OUT-  │
            │  CALIBRATION│ │    GATE     │ │    COME     │
            └─────────────┘ └─────────────┘ └─────────────┘
```

### 2.3 Trace Context Propagation

Every RAG request carries a `trace_id` (UUID v4) through all stages:
- Generated at entry point (`auraToolExecutor` / `ragService`)
- Passed to `embeddingService`, `ragService`, LLM call, `ragLogger`
- Enables end-to-end correlation in logs, metrics, and dashboards
- Stored in `rag_query_logs` with full traceability

---

## 3. Retrieval Telemetry

### 3.1 Query-Level Metrics (Per Request)

```json
{
  "trace_id": "uuid",
  "timestamp": "ISO8601",
  "query": {
    "original": "sanitized_user_query",
    "normalized": "lowercase_trimmed",
    "category": "skincare|cabello|cejas|general|unknown",
    "filters_applied": {"skin_type": "mixta", "category": "skincare"},
    "retrieval_mode": "hnsw|fts|hybrid",
    "top_k": 50,
    "threshold": 0.45
  }
}
```

### 3.2 Embedding-Level Metrics

```json
{
  "embedding": {
    "latency_ms": 450,
    "dimension": 1024,
    "zero_vector": false,
    "model": "nvidia/nv-embedqa-e5-v5",
    "input_type": "query",
    "circuit_breaker": {"state": "closed", "failure_count": 0},
    "api_status": "success|timeout|rate_limited|error"
  }
}
```

### 3.3 Retrieval-Level Metrics (Core)

```json
{
  "retrieval": {
    "mode": "hnsw",
    "latency_ms": 120,
    "candidate_pool_size": 50,
    "result_count": 5,
    "top_1_score": 0.847,
    "score_distribution": [0.847, 0.792, 0.751, 0.712, 0.689],
    "score_separation": {
      "top1_minus_top2": 0.055,
      "top1_minus_top5": 0.158,
      "top5_minus_top10": 0.087
    },
    "vector_miss": false,
    "retrieval_instability": {
      "score_variance_last_3": 0.002,
      "rank_variance_last_3": 1.2
    }
  }
}
```

### 3.4 HNSW-Specific Metrics

```json
{
  "hnsw": {
    "ef_search": 100,
    "index_size": 5663,
    "dimensions": 1024,
    "recall_at_5": 0.89,
    "recall_at_10": 0.94,
    "avg_candidates_examined": 150,
    "latency_p50_ms": 45,
    "latency_p95_ms": 180
  }
}
```

### 3.5 FTS Fallback Metrics

```json
{
  "fts_fallback": {
    "triggered": false,
    "trigger_reason": "embedding_failure|low_top1_score|threshold_not_met|manual",
    "latency_ms": 85,
    "result_count": 3,
    "score_distribution": [0.5, 0.5, 0.5],
    "query_overlap_with_vector": 0.6
  }
}
```

### 3.6 Hybrid Retrieval Metrics

```json
{
  "hybrid": {
    "enabled": true,
    "fusion_method": "rrf",
    "rrf_k": 60,
    "vector_weight": 1.0,
    "fts_weight": 1.0,
    "vector_results": 50,
    "fts_results": 50,
    "fused_results": 5,
    "rank_changes": 2,
    "mrr_delta_vs_vector_only": 0.033,
    "new_chunks_from_fts": 1
  }
}
```

### 3.7 Evidence-Level Metrics

```json
{
  "evidence": {
    "chunks": [
      {
        "chunk_id": "sha256_hash",
        "document_id": "beauty_corpus_v1",
        "document_version": "1.0",
        "fuente": "corpus",
        "seccion": "skincare_routinas_tipo_piel",
        "similarity": 0.847,
        "category": "skincare",
        "content_hash": "sha256",
        "provenance_complete": true
      }
    ],
    "category_diversity": 2,
    "unique_documents": 3,
    "content_coverage_ratio": 0.87
  }
}
```

### 3.8 Retrieval Instability Detection

```json
{
  "retrieval_instability": {
    "detected": true,
    "type": "score_variance|rank_variance|result_set_jaccard",
    "score_variance_last_10": 0.015,
    "rank_variance_last_10": 3.4,
    "result_set_jaccard_last_10": 0.72,
    "affects_vector_miss_queries": ["cejas_004", "cejas_008", "cabello_002"],
    "mitigation": "embedding_caching|query_dedup|confidence_downgrade"
  }
}
```

---

## 4. Confidence Model

### 4.1 Design Principle

**Retrieval score ≠ Answer confidence.** Confidence is a calibrated composite of multiple signals, not a direct mapping of cosine similarity.

### 4.2 Three-Level Confidence Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ANSWER CONFIDENCE                         │
│  Composite: f(retrieval_confidence, evidence_confidence,    │
│                generation_quality, provenance_completeness) │
│  Output: 0.0-1.0 calibrated → Band: HIGH/MEDIUM/LOW/ABSTAIN │
└─────────────────────────────────────────────────────────────┘
                            ▲
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ RETRIEVAL     │   │ EVIDENCE      │   │ GENERATION    │
│ CONFIDENCE    │   │ CONFIDENCE    │   │ QUALITY       │
├───────────────┤   ├───────────────┤   ├───────────────┤
│ • top_1_score │   │ • chunk_count │   │ • citations   │
│ • score_sep   │   │ • cat_diverse │   │   present     │
│ • margin      │   │ • provenance  │   │ • token_count │
│ • mode        │   │   complete    │   │ • hallucination│
│ • fallback    │   │ • coverage    │   │   check       │
│ • instability │   │ • uniqueness  │   │ • coherence   │
└───────────────┘   └───────────────┘   └───────────────┘
```

### 4.3 Retrieval Confidence Signals

| Signal | Range | Weight | Description |
|--------|-------|--------|-------------|
| **top_1_score** | [0, 1] | 0.30 | Primary similarity score |
| **score_margin** | [0, 1] | 0.25 | top1 - top2 (separation from ambiguity) |
| **top5_mean** | [0, 1] | 0.15 | Average of top-5 (depth of evidence) |
| **retrieval_mode** | {hnsw: 1.0, hybrid: 0.95, fts: 0.7} | 0.10 | Method reliability |
| **instability_penalty** | [0, -0.3] | 0.10 | Negative weight for detected instability |
| **fallback_penalty** | [0, -0.2] | 0.10 | FTS fallback activated |

**Formula:** `retrieval_confidence = clamp(Σ(w_i × signal_i), 0, 1)`

### 4.4 Evidence Confidence Signals

| Signal | Range | Weight | Description |
|--------|-------|--------|-------------|
| **chunk_count** | [0, 1] | 0.25 | Normalized (1→0.2, 3→0.6, 5→1.0) |
| **category_diversity** | [0, 1] | 0.20 | Unique categories / max_categories |
| **provenance_completeness** | [0, 1] | 0.25 | % chunks with full traceability (doc_id, version, chunk_id, fuente, seccion) |
| **content_coverage** | [0, 1] | 0.15 | Unique document coverage ratio |
| **uniqueness** | [0, 1] | 0.15 | 1 - duplicate_ratio |

### 4.5 Generation Quality Signals

| Signal | Range | Weight | Description |
|--------|-------|--------|-------------|
| **citations_present** | {0, 1} | 0.30 | At least one citation per claim |
| **citation_coverage** | [0, 1] | 0.25 | Claims with citations / total claims |
| **hallucination_check** | {0, 1} | 0.25 | No unsupported claims (via self-consistency) |
| **coherence_score** | [0, 1] | 0.20 | Semantic coherence of response |

### 4.6 Composite Confidence & Bands

```python
def compute_composite_confidence(retrieval_c, evidence_c, generation_c):
    # Weighted combination
    composite = 0.4 * retrieval_c + 0.35 * evidence_c + 0.25 * generation_c
    
    # Calibration based on production data (R7-I)
    # For now: direct mapping
    return composite

# Confidence Bands (thresholds to be calibrated in R7-I with production data)
CONFIDENCE_BANDS = {
    "HIGH":      (0.80, 1.00),  # Strong evidence, proceed with generation
    "MEDIUM":    (0.60, 0.80),  # Adequate evidence, generate with caveats
    "LOW":       (0.40, 0.60),  # Weak evidence, request clarification
    "ABSTAIN":   (0.00, 0.40)   # Insufficient evidence, safe fallback
}
```

### 4.7 Abstention & Clarification Behavior

| Band | Action | User Message |
|------|--------|--------------|
| **HIGH** | Generate answer with citations | Normal response |
| **MEDIUM** | Generate with "Based on available information..." prefix | Soft hedge |
| **LOW** | Request clarification / suggest alternatives | "Could you clarify...?" or "I found related info about X, Y..." |
| **ABSTAIN** | Safe fallback: "I don't have enough reliable information..." | Honest limitation acknowledgment |

### 4.8 Confidence Calibration Process (R7-I)

1. **Collect** 1000+ production queries with confidence scores
2. **Label** human-evaluated subset (SUPPORTED/UNSUPPORTED)
3. **Calibrate** isotonic regression / Platt scaling per band
4. **Validate** precision@band > 0.85 for HIGH, recall for ABSTAIN
5. **Deploy** calibrated thresholds with feature flag
6. **Monitor** weekly recalibration

---

## 5. Production Distribution

### 5.1 Query Distribution Monitoring

```json
{
  "production_distribution": {
    "total_queries_daily": "metric",
    "by_category": {
      "skincare": 0.35,
      "cabello": 0.25,
      "cejas": 0.15,
      "general": 0.20,
      "unknown": 0.05
    },
    "by_intent": {
      "recommendation": 0.40,
      "information": 0.30,
      "troubleshooting": 0.15,
      "booking_assist": 0.10,
      "other": 0.05
    },
    "by_complexity": {
      "simple": 0.50,
      "moderate": 0.35,
      "complex": 0.10,
      "ultra_specialized": 0.05
    }
  }
}
```

### 5.2 VECTOR_MISS Distribution

```json
{
  "vector_miss_distribution": {
    "total_rate": 0.12,
    "by_category": {
      "cejas": 0.35,
      "skincare": 0.25,
      "cabello": 0.20,
      "general": 0.20
    },
    "by_type": {
      "semantic_representation_gap": 0.62,
      "retrieval_instability": 0.38
    },
    "top_miss_concepts": [
      "simetria_muscular_dinamica",
      "efecto_tyndall",
      "sers_raman",
      "electrolisis_cross_domain",
      "arquitectura_muscular_facial"
    ]
  }
```

### 5.3 Retrieval Failure Taxonomy

| Failure Type | Definition | Detection | Rate Target |
|--------------|------------|-----------|-------------|
| **EMBEDDING_FAILURE** | NVIDIA API error/timeout | Circuit breaker open | < 0.5% |
| **ZERO_VECTOR** | All-zero embedding returned | Dimension check | < 0.1% |
| **VECTOR_MISS** | No chunk > threshold | top_1_score < threshold | ~12% (known) |
| **FTS_FALLBACK** | FTS activated | fallback_triggered=true | < 5% |
| **HYBRID_DEGRADED** | Hybrid worse than vector | mrr_delta < 0 | < 1% |
| **NO_RESULTS** | Zero chunks returned | result_count = 0 | < 0.5% |

### 5.4 Out-of-Domain Detection

```json
{
  "ood_detection": {
    "method": "top_1_score_threshold + category_confidence",
    "threshold": 0.35,
    "signals": [
      "top_1_score < 0.35",
      "category = unknown",
      "query_embedding_norm < 0.5",
      "max_category_score < 0.2"
    ],
    "action": "ABSTAIN + suggest reformulation"
  }
}
```

### 5.5 Ambiguous Query Detection

```json
{
  "ambiguity_detection": {
    "signals": [
      "score_margin < 0.05",
      "top5_entropy > 2.0",
      "category_distribution_flat"
    ],
    "action": "LOW confidence band → clarification request"
  }
}
```

---

## 6. Privacy

### 6.1 Allowed Telemetry

| Data | Allowed | Processing |
|------|---------|------------|
| `trace_id` | ✅ | UUID, no PII |
| `user_id_hash` | ✅ | SHA-256 hash, irreversible |
| `query_sanitized` | ✅ | PII stripped via `piiSanitizer` |
| `query_category` | ✅ | Enum, no content |
| `filters_applied` | ✅ | Enum values only |
| `retrieval_mode` | ✅ | Enum |
| `top_k`, `threshold` | ✅ | Config params |
| `latency_ms` | ✅ | Performance only |
| `scores` | ✅ | Float arrays, no content |
| `chunk_metadata` | ✅ | IDs, categories, provenance only |
| `error_type` | ✅ | Enum, no stack traces with PII |
| `circuit_breaker_state` | ✅ | Operational |
| `confidence_band` | ✅ | Enum |
| `user_action` | ✅ | Enum (booking, purchase, re-query, dismiss) |

### 6.2 Prohibited Telemetry

| Data | Prohibited | Reason |
|------|------------|--------|
| Raw user query (unsanitized) | ❌ | PII, sensitive health/beauty data |
| User ID (raw) | ❌ | Direct identifier |
| Chunk content | ❌ | Proprietary knowledge, potential PII |
| LLM response full text | ❌ | May contain PII, proprietary |
| IP address | ❌ | Direct identifier |
| Device fingerprint | ❌ | Tracking |
| Session replay data | ❌ | Over-collection |

### 6.3 Anonymization Pipeline

```javascript
// Applied in ragLogger.js before any persistence
function sanitizeForLog(input) {
  // 1. Remove emails, phones, IDs, names (via piiSanitizer)
  // 2. Truncate to 500 chars max
  // 3. Replace proper nouns with [ENTITY]
  // 4. Hash any remaining identifiers
  return sanitized;
}
```

### 6.4 Retention Policy

| Data Type | Retention | Deletion Trigger |
|-----------|-----------|------------------|
| `rag_traces.log` (file) | 30 days | Automatic rotation |
| `rag_query_logs` (PostgreSQL) | 90 days | Scheduled cleanup job |
| Aggregated metrics | 365 days | Annual archive |
| Calibration datasets | Indefinite | Version-controlled |

### 6.5 Access Control

| Role | Access |
|------|--------|
| **Data Engineer** | Full read (traces, metrics, calibration) |
| **ML Engineer** | Read + calibration write |
| **Director** | Read + approval |
| **Support** | Aggregated metrics only (no traces) |
| **External** | None |

### 6.6 Auditability

- All telemetry writes logged to audit trail (`telemetry_audit_log`)
- Schema changes require migration + Director approval
- Deletion requests (GDPR) trigger trace removal within 72h
- Quarterly privacy review of telemetry schema

---

## 7. Decision Rules

### 7.1 Evidence Thresholds for Architectural Changes

| Decision | Required Evidence | Minimum Standard |
|----------|-------------------|------------------|
| **Threshold change** (similarity, top_k) | A/B shadow 2 weeks + MRR delta > 0.01 + no regression on VECTOR_MISS | Statistical significance p < 0.05, 1000+ queries |
| **Corpus expansion** | VECTOR_MISS analysis showing corpus gaps (A>0) + cost/benefit > 2x | R6-C13 disproved; requires new gap evidence |
| **Reranking** | Cross-encoder improves MRR > 0.02 on VECTOR_MISS subset + latency < 500ms | Must not regress general queries |
| **Retrieval change** (HNSW params, hybrid weights) | A/B shows MRR gain > 0.015 + p95 latency < 2s | Reversible within 1 hour |
| **Sufficiency calibration** | Precision@HIGH > 0.85 + ABSTAIN recall > 0.70 on 500+ labeled | Human-labeled production data |
| **Embedding investigation** | Production distribution shift > 20% from GOLD-V5 + confidence failure rate > 30% | Quantified shift, not anecdotal |
| **Embedding replacement** | Alternative model beats NVIDIA on VECTOR_MISS recovery + MRR > 0.75 + no regression | Must pass full R6-style evaluation suite |

### 7.2 Hard Constraints (Never Justified By)

- Anecdotal queries alone
- Single user complaints
- "Feels better" subjective assessment
- Competitor feature parity
- Vendor marketing claims

### 7.3 Decision Authority

| Decision Level | Authority | Process |
|----------------|-----------|---------|
| Threshold tuning | Lead Engineer | DESIGN_REVIEW + A/B shadow |
| Corpus changes | Director | DIRECTOR_REVIEW + evidence |
| Retrieval architecture | Director + ML Engineer | SOUL_REVISION if representation |
| Sufficiency gate | Director | DIRECTOR_REVIEW + calibration data |
| Embedding model | Director + Architecture | SOUL_REVISION + full evaluation |
| Confidence bands | Lead Engineer | DESIGN_REVIEW + calibration validation |

### 7.4 Change Classification (Per G1 Governance)

| Classification | Example | Approval |
|----------------|---------|----------|
| **PATCH** | Threshold 0.45 → 0.47 | DESIGN_REVIEW |
| **MINOR** | Add FTS weight parameter | COMPONENT/DIRECTOR_REVIEW |
| **MAJOR** | New retrieval strategy | DIRECTOR_REVIEW + SOUL_REVISION |
| **EXCEPTION** | Temporary threshold for campaign | EXCEPTION_REGISTRY |
| **EXPERIMENTAL** | Projection Head prototype | DESIGN_REVIEW (proto) |

---

## 8. Acceptance Gates (R7)

### 8.1 Telemetry Completeness Gate

| Requirement | Metric | Threshold |
|-------------|--------|-----------|
| Query telemetry coverage | % requests with full query telemetry | 100% |
| Embedding telemetry coverage | % requests with embedding metrics | 100% |
| Retrieval telemetry coverage | % requests with retrieval metrics | 100% |
| Evidence telemetry coverage | % requests with chunk provenance | 100% |
| Confidence telemetry coverage | % requests with confidence band | 100% |
| Error telemetry coverage | % errors with full context | 100% |
| Latency breakdown coverage | % requests with stage breakdown | 95% |

### 8.2 Retrieval Observability Gate

| Requirement | Metric | Threshold |
|-------------|--------|-----------|
| VECTOR_MISS detection | Real-time flagging of top_1_score < threshold | 100% |
| Instability detection | Weekly scan for score/rank variance | 100% detection |
| FTS fallback tracking | % fallbacks with trigger reason | 100% |
| Hybrid effectiveness | MRR delta tracked per query | 100% |
| Score distribution logging | Top-10 scores per query | 100% |

### 8.3 Confidence Gate

| Requirement | Metric | Threshold |
|-------------|--------|-----------|
| Retrieval confidence computed | % queries with retrieval_c | 100% |
| Evidence confidence computed | % queries with evidence_c | 100% |
| Composite confidence computed | % queries with composite_c | 100% |
| Band assignment | % queries with HIGH/MEDIUM/LOW/ABSTAIN | 100% |
| Calibration validation | Precision@HIGH on labeled data | > 0.85 |
| Abstention safety | False ABSTAIN rate (supported queries marked ABSTAIN) | < 5% |
| Coverage | EVIDENCE_INSUFFICIENT (LOW+ABSTAIN) rate | < 15% |

### 8.4 Production Distribution Gate

| Requirement | Metric | Threshold |
|-------------|--------|-----------|
| Category distribution tracked | Daily category breakdown | 100% |
| VECTOR_MISS distribution tracked | Daily by category/type | 100% |
| OOD detection rate | % queries flagged OOD | < 10% |
| Ambiguity detection rate | % queries flagged ambiguous | < 20% |
| Fallback frequency | FTS fallback rate | < 5% |
| Latency SLA | p95 end-to-end | < 2000ms |

### 8.5 Privacy Gate

| Requirement | Metric | Threshold |
|-------------|--------|-----------|
| PII sanitization | % traces with raw PII | 0% |
| Prohibited fields | Presence of prohibited fields | 0 |
| Retention compliance | % data past retention | 0% |
| Access audit | Unauthorized access attempts | 0 |
| Deletion SLA | GDPR deletion request fulfillment | < 72h |

### 8.6 Performance Gate

| Requirement | Metric | Threshold |
|-------------|--------|-----------|
| Embedding latency | p95 | < 2000ms |
| Retrieval latency | p95 | < 500ms |
| Total RAG latency | p95 | < 2000ms |
| Circuit breaker recovery | Mean time to close | < 60s |
| Error rate | Total RAG errors / queries | < 1% |

### 8.7 Regression Gate

| Requirement | Metric | Threshold |
|-------------|--------|-----------|
| MRR stability | Weekly MRR vs baseline | > 0.70 (no drop > 0.02) |
| R@5 stability | Weekly R@5 vs baseline | > 0.58 |
| VECTOR_MISS rate stability | Weekly rate vs baseline | < 15% |
| Calibration drift | Band precision weekly delta | < 0.03 |

### 8.8 Evidence Sufficiency Gate

| Requirement | Metric | Threshold |
|-------------|--------|-----------|
| Provenance completeness | % chunks with full provenance | 100% |
| Citation coverage | % generated answers with citations | 100% |
| Hallucination rate | Human-evaluated unsupported claims | 0% |
| Evidence packet completeness | % packets with all required fields | 100% |

---

## 9. Deliverables

1. **`docs/r7/GLOWAPP_R7_OBSERVABILITY_SPEC.md`** (this document)
2. **`docs/r7/glowapp_r7_observability_spec.json`** (machine-readable specification)
3. **Telemetry schema definitions** (JSON Schema for each domain)
4. **Confidence calibration procedure** (R7-I implementation guide)
5. **Privacy compliance checklist** (for implementation review)

---

## 10. Production Safety

```bash
git status --short
# Only new files in docs/r7/
# Zero backend/, frontend/, database/ modifications
```

---

## 11. Remaining Gaps (Post-R7-I)

| Gap | Priority | Description |
|-----|----------|-------------|
| Real confidence calibration | HIGH | Requires 1000+ production queries with human labels |
| Distribution shift quantification | HIGH | Compare production query distribution vs GOLD-V5 |
| Sufficiency gate validation | MEDIUM | Calibrate with production false positive/negative rates |
| Evidence packet schema | MEDIUM | Define and implement structured evidence packets |
| Dashboard implementation | LOW | Grafana/Loki dashboards for RAG observability |
| Alerting rules | LOW | PagerDuty/Slack alerts for anomaly thresholds |

---

## 12. Next Phase

**R7-I — IMPLEMENTATION**

Build the observability instrumentation, confidence scoring, and calibration pipeline per this specification. Constraints:
- NVIDIA e5-v5 immutable
- No re-embedding without Director approval
- Dense+Sparse optional (Director approval)
- A/B shadow 2 weeks for any threshold change
- Evidence Layer only after confidence validated

---

## 13. Final Decision

**STATUS: SPECIFICATION COMPLETE — READY FOR R7-I IMPLEMENTATION**

All 14 telemetry domains specified. Confidence model designed (three-level: retrieval, evidence, generation → composite bands). Production distribution monitoring defined. Privacy framework complete (allowed/prohibited, anonymization, retention, access). Decision rules evidence-based with hard constraints. 8 acceptance gates with objective thresholds. Zero production modifications.

**Next Authorized Phase: R7-I — IMPLEMENTATION** (instrumentation, calibration pipeline, dashboard, alerting)