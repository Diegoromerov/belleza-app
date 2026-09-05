# GLOWAPP PHASE 2 — PRODUCT TEST MATRIX

## 1. Validation Catalog

| TEST NAME | DOMAIN | EXPECTED BEHAVIOR | STATUS |
| :--- | :--- | :--- | :--- |
| Event Schema Validation | Analytics | Rejects event payloads lacking `eventId` or `timestamp` | PASS |
| Anti-Fraud Referral Block | Growth | Rejects referral reward when referrer == referee | PASS |
| Aura RAG Fallback | AI/RAG | Returns graceful fallback when retrieval context is low | PASS |
| Feature Flag Kill-Switch | System | Toggling flag in Redis immediately disables UI entry | PASS |
