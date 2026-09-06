# GLOWAPP PHASE 2 — ADMIN DOMAIN ARCHITECTURE

## 1. Admin Architecture Overview
The Admin domain establishes the Operations, Governance, Trust & Safety, Financial Operations, and Catalog Control Center across Next.js web (`admin-dashboard/src/app/(dashboard)/admin/`) and mobile support modules (`frontend/lib/screens/disputes/`, `frontend/lib/screens/academy/`).

```
ADMIN OPERATIONS UI LAYER (Next.js React 19 / Flutter Admin Views)
   ↓
ADMIN API CLIENT LAYER (Goal 04 REST & Async Contracts)
   ↓
BACKEND CONTROLLER LAYER (Express.js / Node.js)
   ↓
APPLICATION SERVICE LAYER (Goal 02 Modular Monolith)
   ↓
REPOSITORY LAYER (Goal 03 PostgreSQL Persisted Data)
```

## 2. Admin Operations Scope
- **Operations Dashboard & Alert Center:** Operational KPIs, critical alerts, pending KYC, dispute escalations.
- **User & Provider Governance:** User lifecycle, provider verification status, account suspension/reactivation.
- **KYC & Document Operations:** Privacy-controlled verification queue, document inspection, approval/rejection audit trail.
- **Catalog & Service Control:** Categories, service parameters, price ceilings, global status control.
- **Financial & Booking Operations:** Global booking audit, payment exception monitoring, refund/payout reconciliation.
- **Trust, Safety & Support:** Dispute resolution, incident escalation, support ticket queue management.
- **Academy & VTO Management:** Course content administration (`admin/academia`), Virtual Try-On configuration (`admin/vto`).
