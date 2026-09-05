# GLOWAPP PHASE 2 — PROVIDER SCREEN MATRIX

## 1. Physical Provider Screen Audit Table

| SCREEN | ROUTE | PURPOSE | ROLE | DOMAIN | STATUS | API | STATE | NAVIGATION | MOBILE | DESKTOP |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Provider Dashboard | `frontend/lib/screens/provider/provider_dashboard.dart` | Overview & quick POS | PRESTADOR | Providers | Active | `/api/v1/providers` | SUCCESS | Bottom Nav | Native | Responsive |
| Daily Cash Report | `frontend/lib/screens/provider/daily_cash_report_screen.dart` | POS register reconciliation | PRESTADOR | Providers | Active | `/api/v1/inventory` | SUCCESS | Push route | Native | Responsive |
| Appointments List | `frontend/lib/screens/provider/appointments_list.dart` | Manage bookings | PRESTADOR | Bookings | Active | `/api/v1/bookings` | SUCCESS | Push route | Native | Responsive |
| Provider Services | `frontend/lib/screens/provider_services_screen.dart` | Service catalog & prices | PRESTADOR | Services | Active | `/api/v1/services` | SUCCESS | Push route | Native | Responsive |
| Provider Earnings | `frontend/lib/screens/provider/earnings_view.dart` | Earnings & payouts | PRESTADOR | Payments | Active | `/api/v1/payments` | SUCCESS | Push route | Native | Responsive |
| Next.js Provider Dashboard | `admin-dashboard/src/app/(dashboard)/prestador/page.tsx` | Web provider metrics | PRESTADOR | Providers | Active | `/api/v1/providers` | SUCCESS | Sidebar | Responsive | Web Shell |
