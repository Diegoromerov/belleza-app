# GLOWAPP PHASE 2 — COMPONENT MIGRATION MATRIX

## 1. Migration Mapping

| LEGACY | TARGET | CONSUMERS | RISK | MIGRATION STATUS |
| :--- | :--- | :--- | :--- | :--- |
| Ad-hoc HTML `<button>` | `src/components/ui/button.tsx` | Auth forms, Dashboard pages | Low | IN_PROGRESS |
| Native `alert()` calls | `src/components/ui/dialog.tsx` | Provider action handlers | Medium | PLANNED |
| Blocking Page Spinners | `src/components/ui/skeleton.tsx` | Client booking & Dashboard | Low | IN_PROGRESS |
| Custom `<span>` badges | `src/components/ui/badge.tsx` | Bookings table, Status indicators | Low | COMPLETED |
| Un-styled Data Tables | `src/components/ui/data-table.tsx` | Admin overview, User lists | Medium | PLANNED |
| Inline flutter `BoxDecoration` | Flutter `AppColors` & Theme | Mobile app screens | Medium | PLANNED |
