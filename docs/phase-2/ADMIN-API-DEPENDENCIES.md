# GLOWAPP PHASE 2 — ADMIN API DEPENDENCY MATRIX

## 1. Admin Action to API Mapping

| SCREEN | ACTION | API ENDPOINT | METHOD | AUTH | PERMISSION | RESPONSE | ERROR | OWNER |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Admin Overview | Fetch Metrics | `/api/v1/admin/overview` | GET | Required | `ADMIN` | Overview Object | 500 Toast | Admin |
| Admin Academy | Create Course | `/api/v1/courses` | POST | Required | `ADMIN` | Course Object | 422 Error Alert| Academy |
| Admin VTO Manager | Save VTO Config | `/api/v1/vto` | POST | Required | `ADMIN` | VTO Receipt | 422 Error Alert| Growth/AI |
| Disputes List | Resolve Dispute | `/api/v1/disputes/:id/resolve` | POST | Required | `ADMIN` | Dispute Status | 409 Conflict | Safety |
