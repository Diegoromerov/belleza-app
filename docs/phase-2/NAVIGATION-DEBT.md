# GLOWAPP PHASE 2 — NAVIGATION DEBT INVENTORY

## 1. Audit Findings

| DEBT ID | SOURCE FILE | DESCRIPTION | SEVERITY | REMEDIATION |
| :--- | :--- | :--- | :--- | :--- |
| **DEBT-NAV-001** | `frontend/lib/screens/provider/daily_cash_report_screen.dart` | Exit button occasionally redirects to root login instead of dashboard | P0 | Normalize exit route to `/provider/dashboard` |
| **DEBT-NAV-002** | `admin-dashboard/src/app/(dashboard)/cliente/nueva-cita/page.tsx` | Missing breadcrumbs on step 2 form view | P2 | Add dynamic breadcrumb navigation |
| **DEBT-NAV-003** | `frontend/lib/screens/booking_screen.dart` | Back button on payment step drops selected service state | P1 | Preserve draft state in navigation arguments |
