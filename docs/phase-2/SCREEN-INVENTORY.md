# GLOWAPP PHASE 2 — SCREEN INVENTORY (REAL AUDIT)

## 1. Physical Codebase Screen Catalog

| SCREEN NAME | PHYSICAL FILE PATH | ROLE | DOMAIN | PURPOSE | CURRENT STATUS | RECOMMENDATION |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Client Home | `frontend/lib/screens/home/home_screen.dart` | CLIENT | Clients | Discovery, hero banners & service categories | Physical / Active | KEEP |
| Provider Detail | `frontend/lib/screens/provider_detail_screen.dart` | CLIENT | Providers | Provider bio, portfolio & service list | Physical / Active | KEEP |
| Booking Screen | `frontend/lib/screens/booking_screen.dart` | CLIENT | Bookings | Appointment scheduling & confirmation | Physical / Active | REFACTOR to 3-step |
| Booking Tracking | `frontend/lib/screens/booking_tracking_screen.dart` | CLIENT | Bookings | Real-time appointment status tracker | Physical / Active | KEEP |
| Client Bookings | `frontend/lib/screens/client_bookings_screen.dart` | CLIENT | Bookings | Appointment history & status list | Physical / Active | KEEP |
| Provider Dashboard | `frontend/lib/screens/provider/provider_dashboard.dart` | PROVIDER | Providers | Provider metrics, appointments & quick POS | Physical / Active | KEEP |
| Daily Cash Report | `frontend/lib/screens/provider/daily_cash_report_screen.dart` | PROVIDER | Providers | POS register reconciliation & cash report | Physical / Active | KEEP |
| Next.js Client Dashboard | `admin-dashboard/src/app/(dashboard)/cliente/page.tsx` | CLIENT | Clients | Web client dashboard overview | Physical / Active | KEEP |
| Next.js New Booking | `admin-dashboard/src/app/(dashboard)/cliente/nueva-cita/page.tsx` | CLIENT | Bookings | Web appointment scheduling form | Physical / Active | EVOLVE |
| Next.js Provider Dashboard | `admin-dashboard/src/app/(dashboard)/prestador/page.tsx` | PROVIDER | Providers | Web provider metrics & appointments | Physical / Active | KEEP |
| Next.js Admin Academy | `admin-dashboard/src/app/(dashboard)/admin/academia/page.tsx` | ADMIN | Academy | Admin course management list | Physical / Active | KEEP |
| Next.js Admin VTO | `admin-dashboard/src/app/(dashboard)/admin/vto/page.tsx` | ADMIN | Growth/AI | Virtual Try-On configuration dashboard | Physical / Active | KEEP |
| Admin Operations Queue | Target (Unbuilt) | ADMIN | Admin | Platform-wide operational dispute & KYC queue | TARGET / CREATE | CREATE in Goal 09 |
