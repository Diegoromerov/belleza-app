# GLOWAPP PHASE 2 — CLIENT SCREEN MATRIX

## 1. Physical Client Screen Audit Table

| SCREEN | ROUTE | PURPOSE | ROLE | DOMAIN | STATUS | API | STATE | NAVIGATION | MOBILE | DESKTOP |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Client Home | `frontend/lib/screens/home/home_screen.dart` | Discovery & hero search | CLIENT | Clients | Active | `/api/v1/services` | SUCCESS | Bottom Nav | Native | Responsive |
| Provider Detail | `frontend/lib/screens/provider_detail_screen.dart` | Bio, portfolio & services | CLIENT | Providers | Active | `/api/v1/providers/:id` | SUCCESS | Push route | Native | Responsive |
| Booking Screen | `frontend/lib/screens/booking_screen.dart` | 3-step checkout wizard | CLIENT | Bookings | Active | `/api/v1/bookings` | SUCCESS | Wizard step | Native | Responsive |
| Booking Tracking | `frontend/lib/screens/booking_tracking_screen.dart` | Real-time status tracker | CLIENT | Bookings | Active | `/api/v1/bookings/:id` | SUCCESS | Deep link | Native | Responsive |
| Client Bookings | `frontend/lib/screens/client_bookings_screen.dart` | Appointment history | CLIENT | Bookings | Active | `/api/v1/bookings/user` | SUCCESS | Bottom Nav | Native | Responsive |
| Next.js Client Dashboard | `admin-dashboard/src/app/(dashboard)/cliente/page.tsx` | Web client overview | CLIENT | Clients | Active | `/api/v1/clients` | SUCCESS | Sidebar | Responsive | Web Shell |
| Next.js New Booking | `admin-dashboard/src/app/(dashboard)/cliente/nueva-cita/page.tsx` | Web appointment form | CLIENT | Bookings | Active | `/api/v1/bookings` | SUCCESS | Push route | Responsive | Web Shell |
