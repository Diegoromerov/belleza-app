# GLOWAPP PHASE 2 — KYC STATE MACHINE SPECIFICATION

## 1. State Machine Schema

```
[ NOT_STARTED ]
       │ (Provider Submits Documents)
       ▼
  [ SUBMITTED ]
       │ (System / Operator Inspection)
       ▼
 [ UNDER_REVIEW ] ──────┬────── (Info Request) ─────► [ MORE_INFO_REQUIRED ]
       │                │                                    │
       │ (Approved)     │ (Rejected)                         │ (Resubmitted)
       ▼                ▼                                    │
  [ APPROVED ]     [ REJECTED ] ◄────────────────────────────┘
       │
       │ (Suspension / Expiry)
       ▼
 [ SUSPENDED / EXPIRED ]
```

## 2. Transition Rules
- **Backend Authority:** State transitions are strictly enforced via Express backend controllers and database transactions.
- **Auditability:** Every transition emits a structured audit log containing `actor`, `timestamp`, `reason`, `evidence_url`, and `previous_state`.
