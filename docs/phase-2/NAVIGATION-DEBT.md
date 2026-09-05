# GLOWAPP PHASE 2 — NAVIGATION DEBT INVENTORY

## 1. Navigation Debt Audit

| DEBT ID | PORTAL | DESCRIPTION | SEVERITY | REMEDIATION |
| :--- | :--- | :--- | :--- | :--- |
| **DEBT-NAV-001** | Client Mobile | Redundant header back button causing loop on root tabs | P1 | Normalize back stack in bottom nav |
| **DEBT-NAV-002** | Admin Dashboard | Missing breadcrumbs on nested user detail screens | P2 | Add dynamic breadcrumbs primitive |
| **DEBT-NAV-003** | Provider Mobile | Ambiguous cash report exit button returning to login | P0 | Fix exit route to point to `/provider/dashboard` |
| **DEBT-NAV-004** | Client Web | Deep link to deleted service throwing unhandled 500 | P1 | Catch 404 and present `EmptyState` with category fallbacks |
