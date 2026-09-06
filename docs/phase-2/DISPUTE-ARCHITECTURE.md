# GLOWAPP PHASE 2 — DISPUTE ARCHITECTURE

## 1. Dispute Handling Lifecycle
- **States:** `OPEN` → `UNDER_REVIEW` → `WAITING_FOR_CLIENT` → `WAITING_FOR_PROVIDER` → `ESCALATED` → `RESOLVED` / `REJECTED`
- **Audit Requirement:** Every dispute action writes an append-only log in `audit_logs` and emits a FCM push notification to affected participants.
