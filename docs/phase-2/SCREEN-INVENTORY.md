# GLOWAPP PHASE 2 — SCREEN INVENTORY

## 1. Screen Audit Catalog

| SCREEN | ROUTE | ROLE | DOMAIN | PURPOSE | ENTRY | EXIT | DEPENDENCIES | STATUS | ACTION |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Client Home | `/client/home` | CLIENT | Clients | Hero search, categories & recommendations | App launch / Auth | Explore, Service Detail | API /services | Active | KEEP |
| Explore Services | `/client/explore` | CLIENT | Services | Search & category filtered grid | Client Home, Bottom Nav | Service Detail | API /explore | Active | EVOLVE |
| Provider Detail | `/client/providers/:id` | CLIENT | Providers | Provider portfolio, reviews & services | Explore, Search | Booking Wizard | API /providers | Active | KEEP |
| Booking Wizard | `/client/booking` | CLIENT | Bookings | 3-step checkout (Cuándo/Dónde -> Productos -> Pago) | Provider Detail | Booking Status | Goal 04 API | Active | REFACTOR |
| Provider Dashboard | `/provider/dashboard` | PROVIDER | Providers | Overview, POS checkout & cash report | Provider Login | Schedule, Earnings | Backend POS | Active | KEEP |
| Provider Schedule | `/provider/schedule` | PROVIDER | Bookings | Calendar schedule & appointment slots | Dashboard, Sidebar | Appointment Detail | API /schedule | Active | KEEP |
| Admin Overview | `/admin/overview` | ADMIN | Admin | Platform metrics & operational alerts | Admin Login | Users, Bookings | Analytics API | Active | KEEP |
