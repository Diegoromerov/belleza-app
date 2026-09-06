# GLOWAPP PHASE 2 — ADMIN OPERATIONS MATRIX

## 1. Operational Action Risk & Confirmation Schema

| ACTION NAME | DOMAIN | RISK LEVEL | CONFIRMATION REQ | AUDIT LOGGED | BACKEND ENDPOINT |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Approve KYC Document | KYC | High | Explicit Modal | YES | `/api/v1/admin/kyc/:id/approve` |
| Suspend User Account | Users | Critical | Double Confirm + Reason | YES | `/api/v1/admin/users/:id/suspend` |
| Authorize Refund | Payments | Critical | Double Confirm + Password | YES | `/api/v1/admin/payments/:id/refund` |
| Modify Category Status | Catalog | Medium | Modal Notice | YES | `/api/v1/admin/categories/:id` |
