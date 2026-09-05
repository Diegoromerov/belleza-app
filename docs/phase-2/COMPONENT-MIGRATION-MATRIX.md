# GLOWAPP PHASE 2 — COMPONENT MIGRATION MATRIX

## 1. Migration Overview
This matrix identifies legacy or ad-hoc UI components across the platform and defines their migration target into the standardized GlowApp Design System.

---

## 2. Component Migration Schedule

| Legacy Component | Source File | Migration Target | Priority | Risk Level | Strategy |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Ad-hoc Buttons | `admin-dashboard/src/app/**` | `src/components/ui/button.tsx` | P0 | Low | Replace inline button classes with standardized `Button` component |
| Custom Modal Dialogs | Various admin pages | `src/components/ui/dialog.tsx` | P0 | Medium | Wrap with Radix/Shadcn dialog primitive |
| Inline Loading Spinners | Various pages | `src/components/ui/skeleton.tsx` | P1 | Low | Standardize loading placeholders |
| Un-styled Data Tables | `admin-dashboard/src/app/(dashboard)/*/page.tsx` | `src/components/ui/data-table.tsx` | P0 | Medium | Extract to reusable tanstack data table component |
| Custom Flutter Cards | `frontend/lib/screens/*` | `AppCard` / Standardized Flutter Theme | P1 | Medium | Refactor inline `BoxDecoration` to use `AppColors` and theme radius |
| Provider Booking Form | `frontend/lib/screens/booking_screen.dart` | Structured 3-step Wizard Component | P0 | High | Refactor to follow 1. Cuándo/Dónde -> 2. Productos -> 3. Pago sequence |
