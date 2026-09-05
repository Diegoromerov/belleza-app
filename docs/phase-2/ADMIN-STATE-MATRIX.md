# GLOWAPP PHASE 2 — ADMIN STATE MATRIX

## 1. UX State Mapping

| SCREEN | STATE | SOURCE | UX REPRESENTATION | USER ACTION |
| :--- | :--- | :--- | :--- | :--- |
| Admin Overview | `INITIAL` | App Launch | Skeleton Loaders | None |
| Admin Overview | `SUCCESS` | API `/api/v1/admin/overview` | KPI Metric Cards & Alert List | Click Alert |
| Admin Academy | `LOADING` | Course Submit | Button Spinner + Disabled Form | Wait |
| Admin Academy | `SUCCESS` | API 200 | Toast Notice + Redirect | Dismiss |
| Disputes List | `PARTIAL_FAILURE` | Partial Widget Error | Localized Alert Banner | Retry Widget |
