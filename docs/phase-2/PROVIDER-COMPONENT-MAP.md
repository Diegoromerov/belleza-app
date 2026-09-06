# GLOWAPP PHASE 2 — PROVIDER COMPONENT MAP

## 1. Shared vs Provider-Owned Components

| COMPONENT NAME | PATH / LOCATION | OWNER | TYPE | CONSUMERS | REUSE STATUS |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `Button` | `admin-dashboard/src/components/ui/button.tsx` | Shared UI | Primitive | Client, Provider, Admin | REUSED |
| `Input` | `admin-dashboard/src/components/ui/input.tsx` | Shared UI | Primitive | Client, Provider, Admin | REUSED |
| `Badge` | `admin-dashboard/src/components/ui/badge.tsx` | Shared UI | Primitive | Client, Provider, Admin | REUSED |
| `StatCard` | `admin-dashboard/src/components/ui/stat-card.tsx` | Shared UI | Molecule | Provider, Admin | REUSED |
| `DailyCashReportDialog`| `frontend/lib/widgets/provider/` | Provider Domain | Organism | Provider Dashboard | PROVIDER OWNED |
| `POSCheckoutDialog` | `frontend/lib/widgets/provider/` | Provider Domain | Organism | Daily Cash Report | PROVIDER OWNED |
