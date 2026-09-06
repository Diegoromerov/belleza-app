# GLOWAPP PHASE 2 — CLIENT COMPONENT MAP

## 1. Shared vs Client-Owned Components

| COMPONENT NAME | PATH / LOCATION | OWNER | TYPE | CONSUMERS | REUSE STATUS |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `Button` | `admin-dashboard/src/components/ui/button.tsx` | Shared UI | Primitive | Client, Provider, Admin | REUSED |
| `Input` | `admin-dashboard/src/components/ui/input.tsx` | Shared UI | Primitive | Client, Provider, Admin | REUSED |
| `Badge` | `admin-dashboard/src/components/ui/badge.tsx` | Shared UI | Primitive | Client, Provider, Admin | REUSED |
| `Skeleton` | `admin-dashboard/src/components/ui/skeleton.tsx` | Shared UI | Primitive | Client, Provider, Admin | REUSED |
| `ServiceCard` | `frontend/lib/screens/home/home_screen.dart` | Client Domain | Molecule | Client Home, Explore | CLIENT OWNED |
| `BookingSummaryCard`| `frontend/lib/screens/booking_screen.dart` | Client Domain | Organism | Booking Wizard | CLIENT OWNED |
