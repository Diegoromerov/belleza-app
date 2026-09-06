# GLOWAPP PHASE 2 — PROVIDER API DEPENDENCY MATRIX

## 1. Provider Action to API Mapping

| SCREEN | ACTION | API ENDPOINT | METHOD | AUTH | PERMISSION | RESPONSE | ERROR | OWNER |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Provider Dashboard | Fetch Overview | `/api/v1/providers/dashboard` | GET | Required | `PRESTADOR` | Overview Metrics | 500 Toast | Providers |
| Daily Cash Report | Submit POS Report | `/api/v1/inventory/cash-report` | POST | Required | `PRESTADOR` | Cash Receipt Object| 422 Error Alert| Inventory |
| Appointments List | Accept Booking | `/api/v1/bookings/:id/accept` | POST | Required | `PRESTADOR` | Status: CONFIRMED | 409 Conflict | Bookings |
| Provider Services | Save Service | `/api/v1/services` | POST | Required | `PRESTADOR` | Service Object | 422 Error Alert| Services |
