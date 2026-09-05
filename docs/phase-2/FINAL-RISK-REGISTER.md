# GLOWAPP PHASE 2 — FINAL RISK REGISTER

## 1. Risk Matrix Overview

| Risk ID | Domain | Risk Description | Severity | Probability | Impact | Mitigation Strategy | Owner | Status |
|---|---|---|---|---|---|---|---|---|
| RSK-01 | Payments | Webhook failure due to external gateway outage | HIGH | LOW | HIGH | Automatic retry with exponential backoff & idempotent queue reconciliation | Payment Ops | MITIGATED |
| RSK-02 | Security | PII leakage via AI worker prompt history | CRITICAL | LOW | CRITICAL | Strict regex PII sanitizer (`ANALYTICS-DATA-GOVERNANCE.md`) in FastAPI worker middleware | Security Team | MITIGATED |
| RSK-03 | Performance| Slow pgvector RAG similarity search under high vector volume | MEDIUM | MEDIUM | MEDIUM | HNSW vector indexing (`pgvector`) with limit top-k=5 | Database Team | MITIGATED |
| RSK-04 | Operations | KYC document spoofing or fraudulent submission | HIGH | LOW | HIGH | Multi-stage document validation + Admin review queue with audit trail | Trust & Safety | MITIGATED |
| RSK-05 | Data | Race condition during concurrent service booking | HIGH | LOW | HIGH | Database transaction locks (`SELECT FOR UPDATE`) on provider availability slots | Backend Team | MITIGATED |

---

## 2. Risk Acceptability Summary
All identified risks are properly mitigated with technical safeguards and operational procedures. Residual risk level is acceptable for production deployment with monitoring.
