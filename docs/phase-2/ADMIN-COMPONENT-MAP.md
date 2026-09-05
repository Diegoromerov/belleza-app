# GLOWAPP PHASE 2 — ADMIN COMPONENT MAP

## 1. Shared vs Admin-Owned Components

| COMPONENT NAME | PATH / LOCATION | OWNER | TYPE | CONSUMERS | REUSE STATUS |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `Button` | `admin-dashboard/src/components/ui/button.tsx` | Shared UI | Primitive | Client, Provider, Admin | REUSED |
| `Input` | `admin-dashboard/src/components/ui/input.tsx` | Shared UI | Primitive | Client, Provider, Admin | REUSED |
| `Badge` | `admin-dashboard/src/components/ui/badge.tsx` | Shared UI | Primitive | Client, Provider, Admin | REUSED |
| `DataTable` | `admin-dashboard/src/components/ui/data-table.tsx` | Shared UI | Molecule | Admin, Provider | REUSED |
| `StatCard` | `admin-dashboard/src/components/ui/stat-card.tsx` | Shared UI | Molecule | Admin, Provider | REUSED |
| `AcademyCourseForm` | `admin-dashboard/src/app/(dashboard)/admin/academia/` | Admin Domain | Organism | Admin Academy | ADMIN OWNED |
