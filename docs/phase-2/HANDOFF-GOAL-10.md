# GLOWAPP PHASE 2 — HANDOFF TO GOAL 10 (ADVANCED DOMAIN EXECUTION & FINANCIAL OPERATIONS)

## 1. Handoff Specification

### STABLE FOUNDATIONS
- Admin Experience & Platform Operations Center across Next.js (`admin-dashboard/src/app/(dashboard)/admin/`) and Flutter support modules.
- Operations Overview Dashboard, Academy Course Management (`admin/academia`), VTO Manager (`admin/vto`), Dispute Center, and Audit logging.

### ADMIN ROUTES
- `/(dashboard)/page.tsx`, `/(dashboard)/admin/academia`, `/(dashboard)/admin/academia/[id]`, `/(dashboard)/admin/academia/nuevo`, `/(dashboard)/admin/vto`.

### ADMIN SCREENS
- Admin Overview, Academy Course List, Course Detail Editor, New Course Form, VTO Manager, Disputes List.

### ADMIN COMPONENTS
- `AcademyCourseForm`, `StatCard`, `DataTable`, `AlertCenter`.

### SHARED COMPONENTS
- Reused primitives from `@/components/ui/` (`Button`, `Input`, `Dialog`, `Badge`, `DataTable`, `StatCard`). Zero breaking changes to shared primitives.

### API CONTRACTS
- `/api/v1/admin/*`, `/api/v1/courses`, `/api/v1/vto`, `/api/v1/disputes`.

### DATA CONTRACTS
- `users`, `providers`, `bookings`, `payments`, `courses`, `disputes`, `audit_logs` PostgreSQL tables.

### RBAC
- `ADMIN` role access permissions.

### KYC DEPENDENCIES
- Privacy-controlled KYC document verification workflows.

### BOOKING DEPENDENCIES
- Global booking exception monitoring & audit capabilities.

### PAYMENT DEPENDENCIES
- Transaction audit, refund authorization workflows, and payout queue approvals.

### SAFETY DEPENDENCIES
- Dispute escalation, incident management, and resolution queues.

### NOTIFICATION DEPENDENCIES
- Context-aware admin alerts and system notifications.

### ANALYTICS DEPENDENCIES
- Operational, financial, and product metrics feeds.

### KNOWN LIMITATIONS
- Advanced automated payment reconciliation engines and automated RAG AI features belong to future specialized goals.

### OPEN TECH DEBT
- None in Admin scope.

### UX DEBT
- None in Admin scope.

### CONFLICT ZONES
- `@/components/ui/`, global layout shells, `AppColors.dart`.

### FILES TO PROTECT
- `admin-dashboard/src/app/(dashboard)/page.tsx`, `docs/phase-2/ADMIN-ARCHITECTURE.md`.

### SAFE PARALLELIZATION AREAS
- Future specialized domain modules (Goal 10 Payments/Financial Engine, RAG AI / Aura, Advanced Analytics).

### NEXT GOAL RECOMMENDATION
- **GOAL 10 — ADVANCED DOMAIN EXECUTION & FINANCIAL OPERATIONS Engine:** Deep refactoring of backend payment reconciliation, webhooks, and automated financial audit engines.
