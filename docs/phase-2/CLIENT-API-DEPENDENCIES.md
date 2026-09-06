# GLOWAPP PHASE 2 — CLIENT API DEPENDENCY MATRIX

## 1. Client Action to API Mapping

| SCREEN | ACTION | API ENDPOINT | METHOD | AUTH | PERMISSION | RESPONSE | ERROR | OWNER |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Client Home | Fetch Services | `/api/v1/services` | GET | Optional | Public | Service List | 500 Toast | Services |
| Provider Detail | Fetch Provider | `/api/v1/providers/:id` | GET | Optional | Public | Provider Object | 404 EmptyState | Providers |
| Booking Wizard | Create Booking | `/api/v1/bookings` | POST | Required | `CLIENT` | Booking Confirmation | 422 Field Error | Bookings |
| Booking Tracking | Fetch Status | `/api/v1/bookings/:id` | GET | Required | `CLIENT` | Booking Status | 404 Redirect | Bookings |
