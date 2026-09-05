# GLOWAPP PHASE 2 — PAYMENT RESILIENCE SPECIFICATION

## 1. Resilience & Recovery Rules
- **Gateway Timeouts:** Automatic exponential backoff retry for transient gateway errors (HTTP 502/503/504).
- **Degraded Mode:** If payment gateway is unreachable, active booking draft is held in `PENDING_PAYMENT` state for 15 minutes before expiration.
- **Partial Failure Handling:** Local transaction rollback guarantees database consistency if webhook notification fails.
