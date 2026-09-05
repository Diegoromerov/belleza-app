# GLOWAPP PHASE 2 — INFORMATION ARCHITECTURE

## 1. Master Portal Hierarchy

```
GLOWAPP PRODUCT IA
├── 1. PUBLIC PORTAL (Landing, Marketing, Service Discovery)
│   ├── / (Home / Hero)
│   ├── /services (Public Service Catalog)
│   ├── /providers (Public Provider Directory)
│   └── /legal (Terms, Privacy, Safety)
│
├── 2. AUTHENTICATION PORTAL (Goal 01 Contracts)
│   ├── /auth/login
│   ├── /auth/register
│   ├── /auth/forgot-password
│   └── /auth/verify-phone
│
├── 3. CLIENT PORTAL (Consumer Journey)
│   ├── /client/home (Discovery & Recommendations)
│   ├── /client/explore (Search & Category Filters)
│   ├── /client/providers/:id (Provider Detail & Portfolio)
│   ├── /client/booking (3-step Wizard: Cuándo/Dónde -> Productos -> Pago)
│   ├── /client/bookings (Active & Historical Bookings)
│   ├── /client/messages (Provider Communication)
│   └── /client/profile (Preferences, Saved Payment Methods)
│
├── 4. PROVIDER PORTAL (Beauty Professional / Salon)
│   ├── /provider/dashboard (Daily Overview & Cash Report)
│   ├── /provider/schedule (Calendar & Time Off)
│   ├── /provider/bookings (Appointment Lifecycle Management)
│   ├── /provider/services (Service Catalog Management)
│   ├── /provider/inventory (Product Stock & POS Checkout)
│   ├── /provider/earnings (Payout Requests & Bank Account)
│   └── /provider/kyc (Verification & Documents)
│
└── 5. ADMIN PORTAL (Platform Operations)
    ├── /admin/overview (System Metrics & KPIs)
    ├── /admin/users (Client & Provider Governance)
    ├── /admin/bookings (Global Booking Audit)
    ├── /admin/payments (Financial Audit & Payout Approvals)
    ├── /admin/kyc (Verification Queues)
    └── /admin/safety (Incident Escalation & Support)
```
