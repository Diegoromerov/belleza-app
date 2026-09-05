# GLOWAPP PHASE 2 — PROVIDER TEST MATRIX

## 1. Validation & Test Catalog

| TEST NAME | TARGET SCREEN | ROLE | EXPECTED RESULT | STATUS |
| :--- | :--- | :--- | :--- | :--- |
| Provider Login to Dashboard | `auth/login_screen.dart` -> `provider_dashboard.dart` | PRESTADOR | Successful session & Dashboard metrics render | PASS |
| POS Cash Register Report | `daily_cash_report_screen.dart` | PRESTADOR | Cash reconciliation calculation & POST submit | PASS |
| Booking Acceptance Flow | `appointments_list.dart` | PRESTADOR | Booking status transitions to CONFIRMED | PASS |
| Service Catalog Update | `provider_services_screen.dart` | PRESTADOR | Service price update & DB persistence | PASS |
