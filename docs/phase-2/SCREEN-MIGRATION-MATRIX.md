# GLOWAPP PHASE 2 — SCREEN MIGRATION MATRIX

## 1. Migration Strategy Table

| PHYSICAL SCREEN | SOURCE PATH | TARGET ROUTE | ROLE | MIGRATION STATUS | ACTION |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Client Booking Screen | `frontend/lib/screens/booking_screen.dart` | `/client/booking` | CLIENT | IN_PROGRESS | Refactor to 3-step wizard |
| Daily Cash Report | `frontend/lib/screens/provider/daily_cash_report_screen.dart` | `/provider/dashboard` | PROVIDER | COMPLETED | Integrate POS checkout dialogs |
| Admin Academy List | `admin-dashboard/src/app/(dashboard)/admin/academia/page.tsx` | `/admin/academia` | ADMIN | COMPLETED | Standardize DataTable primitive |
| Admin VTO Manager | `admin-dashboard/src/app/(dashboard)/admin/vto/page.tsx` | `/admin/vto` | ADMIN | COMPLETED | Consolidate Design Tokens |
