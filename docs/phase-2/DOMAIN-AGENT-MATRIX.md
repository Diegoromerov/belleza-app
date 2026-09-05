# GLOWAPP PHASE 2 — DOMAIN AGENT PARALLELIZATION MATRIX

## 1. Parallelization Assignment Table

| DOMAIN | AGENT | ROUTES | SCREENS | JOURNEYS | API DEPENDENCIES | SHARED COMPONENTS | PARALLEL READY |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **AUTH** | Agent 01 | `/auth/*` | Login, Register | Login, Onboarding | `/api/v1/auth` | Input, Button | YES |
| **CLIENTS** | Agent B | `/client/*` | Home, Profile | Discovery, Booking | `/api/v1/clients` | Card, Avatar | YES |
| **PROVIDERS**| Agent C | `/provider/*` | Dashboard, POS | Service Execution | `/api/v1/providers` | StatCard, Dialog | YES |
| **BOOKINGS** | Agent D | `/client/booking` | Wizard, History | 3-step Booking | `/api/v1/bookings` | Wizard, Toast | YES |
| **PAYMENTS** | Agent E | `/payments/*` | Checkout, Payouts | Payment Processing| `/api/v1/payments` | Button, Badge | YES |
