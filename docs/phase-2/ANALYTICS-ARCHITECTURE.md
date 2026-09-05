# GLOWAPP PHASE 2 — ANALYTICS ARCHITECTURE

## 1. Real-Time & Aggregate Analytics Engine
- **Event Aggregation:** Real-time event ingestion mapped to PostgreSQL aggregation tables and Redis metrics counters.
- **Privacy & PII Protection:** Event payloads strip sensitive PII (passwords, JWTs, full credit card numbers) before storage.
