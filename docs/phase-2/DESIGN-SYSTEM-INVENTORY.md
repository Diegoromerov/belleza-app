# GLOWAPP PHASE 2 — DESIGN SYSTEM INVENTORY

## 1. Executive Summary
Comprehensive inventory of all UI components, tokens, typography rules, layout patterns, and interaction states across `admin-dashboard`, `frontend` Flutter app, and `landing`.

---

## 2. Component Inventory Matrix

| NAME | PATH | PURPOSE | DOMAIN | VARIANTS | CONSUMERS | DUPLICATES | CURRENT_STATUS | RECOMMENDATION |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `Button` | `admin-dashboard/src/components/ui/button.tsx` | Primary visual action CTA | Shared UI | default, outline, ghost, destructive, icon | Admin pages, Auth forms | Ad-hoc HTML `<button>` | CONSOLIDATE | EVOLVE to primary design system atom |
| `Input` | `admin-dashboard/src/components/ui/input.tsx` | Text & form data entry | Shared UI | text, password, email, search, number | Forms, Login, Search | Custom input fields | CONSOLIDATE | KEEP & enforce focus ring tokens |
| `Dialog` | `admin-dashboard/src/components/ui/dialog.tsx` | Modal popups & confirmations | Shared UI | alert, form-dialog, confirmation | Delete action, Forms | Native `alert()` calls | CONSOLIDATE | REPLACE ad-hoc modals with Dialog primitive |
| `Badge` | `admin-dashboard/src/components/ui/badge.tsx` | Status & tag indicator | Shared UI | success, warning, error, info, neutral | Tables, Cards, Header | Custom `<span>` elements | KEEP | EVOLVE with unified status tokens |
| `Avatar` | `admin-dashboard/src/components/ui/avatar.tsx` | User & provider profile image | Shared UI | sm, md, lg, xl, fallback | Header, Profile, Reviews | Raw `<img>` elements | KEEP | CONSOLIDATE to handle missing image fallbacks |
| `Skeleton` | `admin-dashboard/src/components/ui/skeleton.tsx` | Content loading placeholder | Shared UI | card-skeleton, text-skeleton, avatar-skeleton | Dashboard, Booking | Full-page spinners | EVOLVE | REPLACE blocking spinners with content skeletons |
| `Toast` | `admin-dashboard/src/components/ui/toast.tsx` | Asynchronous user notifications | Shared UI | success, error, warning, info | Global layout | Alert popups | CONSOLIDATE | KEEP as single toast provider |
| `Card` | `admin-dashboard/src/components/ui/card.tsx` | Container for grouped content | Shared UI | default, hoverable, bordered, elevated | Overview, Analytics | Ad-hoc border `<div>` | KEEP | EVOLVE to standardize padding & radius |
| `DataTable` | `admin-dashboard/src/components/ui/data-table.tsx` | Tabular data display | Shared UI | default, paginated, searchable | Users, Bookings, Services | Standard `<table>` | EVOLVE | CONSOLIDATE pagination & mobile stack view |
| `StatCard` | `admin-dashboard/src/components/ui/stat-card.tsx` | KPI metrics display | Admin Domain | default, trend-positive, trend-negative | Dashboard overview | Custom metric divs | CONSOLIDATE | KEEP & expose as shared admin component |
