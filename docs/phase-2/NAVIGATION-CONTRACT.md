# GLOWAPP PHASE 2 — NAVIGATION CONTRACT

## 1. Physical Codebase Navigation Audit & Rules
1. **Source of Truth:** Architecture derived directly from `admin-dashboard/src/app` (Next.js 15) and `frontend/lib/screens` (Flutter).
2. **Role-Aware Navigation:**
   - **CLIENT:** Mobile Bottom Nav (`home`, `store`, `client_bookings`, `client_profile`).
   - **PROVIDER:** Mobile Navigation & Next.js dashboard (`(dashboard)/prestador`, `provider_dashboard_screen.dart`, `daily_cash_report_screen.dart`).
   - **ADMIN:** Next.js Admin Portal (`(dashboard)/admin/academia`, `vto`).
3. **UI Visibility vs Authorization:** Menu filtering is UX disclosure. Route protection is strictly governed by `(auth)` guards and backend JWT middleware.
4. **Preservation of Context:** Back navigation from detail views (`provider_detail_screen.dart`, `/admin/academia/[id]`) preserves parent search filters and active tab state.
5. **Deep Linking Contract:** Deep links to services, bookings, and provider profiles must fall back gracefully to the login guard if unauthenticated.
