# GLOWAPP PHASE 2 — ADMIN DATA DEPENDENCIES

## 1. PostgreSQL Schema & Audit Dependencies
- **Core Entities:** `users`, `providers`, `bookings`, `payments`, `courses`, `disputes`, `audit_logs`.
- **Read/Write Authority:** Backend RBAC middleware enforces `ADMIN` role scope before executing data mutations.
- **Audit Logging:** Every sensitive administrative action (KYC approval, user suspension, refund authorization) writes an immutable entry to `audit_logs`.
