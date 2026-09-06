# GLOWAPP PHASE 2 — PROVIDER DOMAIN ARCHITECTURE

## 1. Provider Architecture Overview
The Provider domain establishes the operational management layer across Flutter mobile (`frontend/lib/screens/provider/`, `frontend/lib/screens/provider_*.dart`) and Next.js web (`admin-dashboard/src/app/(dashboard)/prestador/`).

```
PROVIDER UI LAYER (Flutter / Next.js React 19)
   ↓
PROVIDER API CLIENT LAYER (Goal 04 REST & Async Contracts)
   ↓
BACKEND CONTROLLER LAYER (Express.js / Node.js)
   ↓
APPLICATION SERVICE LAYER (Goal 02 Modular Monolith)
   ↓
REPOSITORY LAYER (Goal 03 PostgreSQL Persisted Data)
```

## 2. Provider Domain Scope
- **Provider Operations & Dashboard:** Daily overview, POS checkout, cash report reconciliation.
- **Calendar & Schedule:** Working hours, appointment slots, time-off blocking.
- **Appointments & Booking Management:** Booking acceptance, rejection, rescheduling, service execution.
- **Services & Pricing:** Service catalog management, price setting, duration configuration.
- **Earnings & Payouts:** Earnings snapshot, payout requests, bank account configuration.
- **Profile, Support & Safety:** Professional bio, verification status, incident support.
