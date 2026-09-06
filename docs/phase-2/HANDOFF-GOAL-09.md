# GLOWAPP PHASE 2 — HANDOFF TO GOAL 09 (ADMIN & PLATFORM OPERATIONS)

## 1. Handoff Specification

### STABLE FOUNDATIONS
- Provider Domain Architecture across Flutter (`frontend/lib/screens/provider/`) and Next.js (`admin-dashboard/src/app/(dashboard)/prestador/`).
- Provider Operations, POS cash report reconciliation, Schedule management, and Earnings payouts.

### PROVIDER ROUTES
- `/provider/dashboard`, `/provider/schedule`, `/provider/bookings`, `/provider/services`, `/provider/earnings`, `/provider/kyc`.

### PROVIDER SCREENS
- `provider_dashboard.dart`, `daily_cash_report_screen.dart`, `appointments_list.dart`, `provider_services_screen.dart`, `earnings_view.dart`.

### PROVIDER COMPONENTS
- `DailyCashReportDialog`, `POSCheckoutDialog`, `ProviderScheduleDialog`.

### SHARED COMPONENTS
- Reused primitives from `@/components/ui/` (`Button`, `Input`, `Dialog`, `Badge`, `StatCard`). Zero breaking changes to shared primitives.

### API CONTRACTS
- `/api/v1/providers`, `/api/v1/services`, `/api/v1/bookings`, `/api/v1/inventory`, `/api/v1/payments`.

### DATA CONTRACTS
- `providers`, `services`, `bookings`, `inventory`, `payments` PostgreSQL tables.

### EVENTS
- Booking accepted, service completed, payout requested, cash report submitted.

### PERMISSIONS
- `PRESTADOR` role access permissions.

### NAVIGATION
- Conforming strictly to Goal 06 Navigation Contract.

### KNOWN LIMITATIONS
- Platform-wide user management, global KYC document approval queues, and financial audit logs belong to Admin Domain (Goal 09).

### UNRESOLVED UX
- None in Provider scope.

### BOOKING DEPENDENCIES
- Booking state machine transitions (`CONFIRMED`, `IN_PROGRESS`, `COMPLETED`).

### PAYMENT DEPENDENCIES
- Payment reconciliation and payout approval queues from Payments/Admin domain.

### CONFLICT ZONES
- `@/components/ui/`, global layout shells, `AppColors.dart`.

### FILES TO PROTECT
- `frontend/lib/screens/provider/provider_dashboard.dart`, `docs/phase-2/PROVIDER-ARCHITECTURE.md`.

### SAFE PARALLELIZATION AREAS
- Goal 09 Admin Domain screens inside `admin-dashboard/src/app/(dashboard)/admin/`.
