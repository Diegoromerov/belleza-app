# GLOWAPP PHASE 2 — INFORMATION ARCHITECTURE (REAL vs TARGET)

## 1. Current Physical Information Architecture

```
PHYSICAL GLOWAPP CODEBASE IA
├── 1. PUBLIC & MARKETING (Flutter & Next.js Root)
│   └── Next.js: / (page.tsx)
│
├── 2. AUTHENTICATION PORTAL (Goal 01 Contracts)
│   ├── Next.js: /(auth)/login, /(auth)/register
│   └── Flutter: auth/login_screen.dart, auth/register_screen.dart, auth/onboarding_screen.dart
│
├── 3. CLIENT PORTAL
│   ├── Next.js: /(dashboard)/cliente (page.tsx), /(dashboard)/cliente/citas, /(dashboard)/cliente/nueva-cita
│   └── Flutter: home/home_screen.dart, provider_detail_screen.dart, booking_screen.dart, client_bookings_screen.dart
│
├── 4. PROVIDER PORTAL
│   ├── Next.js: /(dashboard)/prestador (page.tsx), /(dashboard)/prestador/citas
│   └── Flutter: provider/provider_dashboard.dart, provider/daily_cash_report_screen.dart, provider_services_screen.dart
│
└── 5. ADMIN & ACADEMY PORTAL
    ├── Next.js: /(dashboard)/admin/academia (page.tsx, [id]/page.tsx, nuevo/page.tsx, vto/page.tsx)
    └── Flutter: academy/academy_screen.dart, course_detail_screen.dart
```

## 2. Documentation / Implementation Drift
- **Drift Item 1:** Prior docs specified `/admin/kyc`, `/admin/payments`, and `/admin/safety`. Physical Audit shows these functions are integrated via backend APIs and support forms (`support/support_center_screen.dart`, `disputes/open_dispute_screen.dart`). Marked as `TARGET / CREATE`.
- **Drift Item 2:** Client discovery is physically implemented across `home/home_screen.dart` (Flutter) and `/(dashboard)/cliente/nueva-cita` (Next.js).
