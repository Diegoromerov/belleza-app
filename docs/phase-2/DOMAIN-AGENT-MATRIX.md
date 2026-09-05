# GLOWAPP PHASE 2 — DOMAIN AGENT PARALLELIZATION MATRIX

## 1. Real Codebase Parallelization Table

| DOMAIN | OWNER AGENT | PHYSICAL ROUTES | PHYSICAL SCREENS | API DEPENDENCIES | PARALLEL READY |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **AUTH** | Agent 01 | `/(auth)/login`, `/(auth)/register` | `login_screen.dart` | `/api/v1/auth` | YES |
| **CLIENTS** | Agent B | `/(dashboard)/cliente/*` | `home_screen.dart` | `/api/v1/clients` | YES |
| **PROVIDERS**| Agent C | `/(dashboard)/prestador/*` | `provider_dashboard.dart` | `/api/v1/providers` | YES |
| **BOOKINGS** | Agent D | `/(dashboard)/cliente/citas` | `booking_screen.dart` | `/api/v1/bookings` | YES |
| **ACADEMY** | Agent F | `/(dashboard)/admin/academia` | `academy_screen.dart` | `/api/v1/courses` | YES |

ADMIN | Agent Admin | /(dashboard)/admin/* | page.tsx | /api/v1/admin/* | COMPLETED
TRUST_SAFETY_PAYMENTS | Agent Trust | /api/v1/trust/* | kyc_state_machine.js | /api/v1/payments | COMPLETED
PRODUCT_INTELLIGENCE | Agent Intelligence | /api/v1/analytics/* | product_events.js | /api/v1/growth | COMPLETED