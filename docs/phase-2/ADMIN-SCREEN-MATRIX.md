# GLOWAPP PHASE 2 — ADMIN SCREEN MATRIX

## 1. Physical Admin Screen Audit Table

| SCREEN | ROUTE | PURPOSE | ROLE | DOMAIN | STATUS | API | STATE | NAVIGATION | MOBILE | DESKTOP |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Admin Overview | `admin-dashboard/src/app/(dashboard)/page.tsx` | Operational KPIs & alerts | ADMIN | Admin | Active | `/api/v1/admin/overview` | SUCCESS | Sidebar | Responsive | Web Shell |
| Admin Academy | `admin-dashboard/src/app/(dashboard)/admin/academia/page.tsx` | Course management list | ADMIN | Academy | Active | `/api/v1/courses` | SUCCESS | Sidebar | Responsive | Web Shell |
| Admin Course Detail | `admin-dashboard/src/app/(dashboard)/admin/academia/[id]/page.tsx` | Course editor & modules | ADMIN | Academy | Active | `/api/v1/courses/:id` | SUCCESS | Push route | Responsive | Web Shell |
| Admin New Course | `admin-dashboard/src/app/(dashboard)/admin/academia/nuevo/page.tsx` | Course creation form | ADMIN | Academy | Active | `/api/v1/courses` | SUCCESS | Push route | Responsive | Web Shell |
| Admin VTO Manager | `admin-dashboard/src/app/(dashboard)/admin/vto/page.tsx` | Virtual Try-On manager | ADMIN | Growth/AI | Active | `/api/v1/vto` | SUCCESS | Sidebar | Responsive | Web Shell |
| Disputes List | `frontend/lib/screens/disputes/disputes_list.dart` | Incident dispute queue | ADMIN | Safety | Active | `/api/v1/disputes` | SUCCESS | Push route | Native | Responsive |
```
