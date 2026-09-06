# GLOWAPP PHASE 2 — OPERATIONAL OBSERVABILITY SPECIFICATION

## 1. Observability Matrix

| DOMAIN | CRITICAL EVENT | SEVERITY | LOG LEVEL | METRIC NAME | ALERT TRIGGER |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Payments | Payment Failure | HIGH | WARN | `payments_failed_total` | > 5 failures in 5 min |
| Webhooks | Signature Invalid | CRITICAL | ERROR | `webhooks_invalid_sig` | Immediate Alert |
| KYC | Verification Backlog | MEDIUM | INFO | `kyc_pending_count` | > 20 pending > 24h |
| Safety | Critical Incident | CRITICAL | ERROR | `safety_incident_critical` | Immediate Pager Alert |
