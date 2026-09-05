# GLOWAPP PHASE 2 — SCREEN MIGRATION MATRIX

## 1. Migration Strategy Table

| LEGACY SCREEN | TARGET ROUTE | ROLE | DOMAIN | MIGRATION STATUS | ACTION |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `frontend/lib/screens/booking_screen.dart` | `/client/booking` | CLIENT | Bookings | IN_PROGRESS | Refactor to 3-step wizard |
| `frontend/lib/screens/provider/daily_cash_report_screen.dart` | `/provider/dashboard` | PROVIDER | Providers | COMPLETED | Integrate POS dialogs |
| `admin-dashboard/src/app/(dashboard)/page.tsx` | `/admin/overview` | ADMIN | Admin | COMPLETED | Standardize metrics cards |
| `admin-dashboard/src/app/(dashboard)/users/page.tsx` | `/admin/users` | ADMIN | Users | PLANNED | Apply DataTable primitive |
