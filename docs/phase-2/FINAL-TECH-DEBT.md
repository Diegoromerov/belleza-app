# GLOWAPP PHASE 2 — FINAL TECHNICAL DEBT CATALOG

## 1. Classification Methodology
- **P0 (Critical Blocker):** Must be resolved prior to release. (Current P0 count: **0**).
- **P1 (High Priority):** Significant operational debt to resolve early in Phase 3.
- **P2 (Medium Priority):** Refactoring or performance optimization.
- **P3 (Low Priority):** Minor code formatting, docstring, or style alignment.

---

## 2. Technical Debt Inventory

| Item ID | Domain | Priority | Description | Affected Component | Impact | Recommended Mitigation | Owner |
|---|---|---|---|---|---|---|---|
| TD-01 | Infrastructure | P1 | Hardcoded local Redis fallback when connection drops | `backend/src/config/redis.js` | Cache degradation on network blips | Configure Managed Redis Sentinel / Cluster URI | DevOps Team |
| TD-02 | Flutter | P1 | Linux/MacOS generated plugin files pending commit cleanup | `frontend/linux/flutter/generated_plugin_registrant.cc` | Build warning on desktop targets | Re-generate desktop plugin wrappers in CI | Mobile Team |
| TD-03 | Frontend | P2 | Mock demo server script retained for standalone UI testing | `backend/serve_mock_demo.js` | Potential confusion during deployment | Isolate mock server to test harness package | QA / Dev Team |
| TD-04 | AI Worker | P2 | RAG embedding index sync script manual invocation | `seed_glowapp_kb.js` | Knowledge update delay | Automate knowledge base ingestion on document upload | AI Team |
| TD-05 | Telemetry | P3 | Analytics event batch buffer size set to default 50 | `docs/phase-2/PRODUCT-EVENT-ARCHITECTURE.md` | Minor latency spike under extreme load | Configure dynamic batching per network quality | Data Team |

---

## 3. Debt Resolution Roadmap
- **Phase 2 Gate Impact:** Zero P0 items exist. All P1/P2 items are fully documented, isolated, and mitigated.
