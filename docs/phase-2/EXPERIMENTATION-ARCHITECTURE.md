# GLOWAPP PHASE 2 — EXPERIMENTATION ARCHITECTURE

## 1. A/B Testing Framework
- **Deterministic Assignment:** Hashing `user_id` + `experiment_id` for consistent cohort bucket assignment (`CONTROL` vs `VARIANT_A`).
