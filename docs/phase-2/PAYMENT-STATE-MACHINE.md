# GLOWAPP PHASE 2 — PAYMENT STATE MACHINE SPECIFICATION

## 1. Financial State Machine Schema

```
[ CREATED ] ──► [ PENDING ] ──► [ AUTHORIZED ] ──► [ APPROVED ] ──► [ RECONCILED ]
                     │                 │                  │
                     ▼                 ▼                  ▼
                [ FAILED ]       [ CANCELLED ]      [ REFUNDED ]
```

## 2. Financial Safety Rules
- **Idempotency Key:** Mandatory header `X-Idempotency-Key` on all payment mutations.
- **No Double-Charge:** Unique transaction constraint enforced on `booking_id` + `payment_intent_id`.
- **Backend Authority:** Frontend never sets payment status directly.
