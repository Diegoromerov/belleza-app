# GLOWAPP PHASE 2 — PROVIDER STATE MATRIX

## 1. UX State Mapping

| SCREEN | STATE | SOURCE | UX REPRESENTATION | USER ACTION |
| :--- | :--- | :--- | :--- | :--- |
| Provider Dashboard | `INITIAL` | App Launch | Skeleton Loaders | None |
| Provider Dashboard | `SUCCESS` | API `/api/v1/providers` | Appointment Cards & Earnings Metric | Tap Appointment |
| Daily Cash Report | `LOADING` | POS Submit | Button Spinner + Disabled Inputs | Wait |
| Daily Cash Report | `SUCCESS` | API 200 | Cash Report Summary Receipt | Print / Dismiss |
| Appointments List | `CONFLICT` | API 409 | Time Slot Conflict Alert | Reschedule Slot |
