# GLOWAPP PHASE 2 — HANDOFF TO GOAL 08 (PROVIDER EXPERIENCE & DOMAIN EXECUTION)

## 1. Handoff Specification

### WHAT GOAL 07 STABILIZED
- Client Domain Architecture across Flutter (`frontend/lib/screens/`) and Next.js (`admin-dashboard/src/app/(dashboard)/cliente/`).
- Client Navigation, 3-Step Booking Wizard, Booking Tracking, and Profile management.

### CLIENT ROUTES
- `/client/home`, `/client/explore`, `/client/providers/:id`, `/client/booking`, `/client/bookings`, `/client/profile`.

### CLIENT SCREENS
- `home_screen.dart`, `provider_detail_screen.dart`, `booking_screen.dart`, `booking_tracking_screen.dart`, `client_bookings_screen.dart`.

### CLIENT COMPONENTS
- `ServiceCard`, `BookingSummaryCard`, `ClientProfileForm`.

### SHARED COMPONENTS TOUCHED
- Reused primitives from `@/components/ui/` (`Button`, `Input`, `Dialog`, `Badge`, `Skeleton`). No shared primitives were mutated breakingly.

### API CONTRACTS CONSUMED
- `/api/v1/services`, `/api/v1/providers`, `/api/v1/bookings`, `/api/v1/payments`.

### DATA CONTRACTS CONSUMED
- `services`, `providers`, `bookings`, `users` PostgreSQL tables.

### EVENTS CONSUMED
- Booking created, payment confirmed, FCM push notification events.

### PERMISSIONS
- `CLIENT` role access permissions.

### NAVIGATION
- Conforming strictly to Goal 06 Navigation Contract.

### KNOWN LIMITATIONS
- Provider schedule management and live POS cash report features belong to Provider Domain (Goal 08).

### UNRESOLVED UX
- None in Client scope.

### PROVIDER DEPENDENCIES
- Provider details, availability slots, and service pricing feeds from Provider Domain.

### CONFLICT ZONES
- `@/components/ui/`, global layout shells, `AppColors.dart`.

### FILES THAT MUST NOT BE MODIFIED CASUALLY
- `frontend/lib/screens/booking_screen.dart`, `docs/phase-2/CLIENT-ARCHITECTURE.md`.

### SAFE PARALLELIZATION AREAS
- Goal 08 Provider Domain screens inside `frontend/lib/screens/provider/` and `admin-dashboard/src/app/(dashboard)/prestador/`.
