# GLOWAPP PHASE 2 — KYC OPERATIONS MATRIX

## 1. Operator Schema

| STATE | PERMITTED ACTOR | REQUIRED PERMISSION | OPERATOR ACTION | SYSTEM RESPONSE | AUDIT EVENT |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `SUBMITTED` | System / Operator | `ADMIN` / System | Initiate Inspection | Set `UNDER_REVIEW` | `KYC_REVIEW_STARTED` |
| `UNDER_REVIEW` | Admin Operator | `ADMIN` | Approve Verification | Set `APPROVED` + Notify | `KYC_APPROVED` |
| `UNDER_REVIEW` | Admin Operator | `ADMIN` | Reject (with Reason) | Set `REJECTED` + Notify | `KYC_REJECTED` |
| `APPROVED` | Safety Operator | `ADMIN` | Suspend Credentials | Set `SUSPENDED` + Hold | `KYC_SUSPENDED` |
