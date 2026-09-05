# GLOWAPP PHASE 2 — AUDIT TRAIL ARCHITECTURE

## 1. Immutable Audit Record Schema
Every sensitive administrative or financial mutation logs:
- `id`: UUID (Primary Key)
- `timestamp`: ISO 8601 UTC
- `actor_id`: User ID initiating action
- `actor_role`: `CLIENT`, `PROVIDER`, `ADMIN`, `SYSTEM`
- `action`: Canonical action string (e.g. `KYC_APPROVED`, `REFUND_AUTHORIZED`)
- `resource_type`: Target entity (`user`, `booking`, `payment`, `kyc_doc`)
- `resource_id`: Target entity ID
- `previous_state`: JSON snapshot before mutation
- `new_state`: JSON snapshot after mutation
- `reason`: Mandatory text justification
