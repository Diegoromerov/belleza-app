# GLOWAPP PHASE 2 — WEBHOOK RESILIENCE SPECIFICATION

## 1. Processing Pipeline
`RECEIVED` → `VALIDATED (Signature & Timestamp)` → `PROCESSING (Idempotency Check)` → `PROCESSED` / `DUPLICATE` / `FAILED`

## 2. Replay & Deduplication Protection
- Webhook Event IDs cached in Redis for 7 days (`webhook:event:{id}`).
- Replayed webhook events return immediate `HTTP 200` with status `DUPLICATE`.
