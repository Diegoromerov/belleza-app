# GLOWAPP PHASE 2 — CLIENT TEST MATRIX

## 1. Validation & Test Catalog

| TEST NAME | TARGET SCREEN | ROLE | EXPECTED RESULT | STATUS |
| :--- | :--- | :--- | :--- | :--- |
| Client Login to Home | `auth/login_screen.dart` -> `home_screen.dart` | CLIENT | Successful JWT session & Home feed render | PASS |
| Service Search & Filter | `home_screen.dart` | CLIENT | Filter grid updates without layout shift | PASS |
| 3-Step Booking Wizard | `booking_screen.dart` | CLIENT | Sequential validation & booking receipt creation | PASS |
| Booking Status Tracking | `booking_tracking_screen.dart` | CLIENT | Real-time status update & FCM push trigger | PASS |
