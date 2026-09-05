# GLOWAPP PHASE 2 — DESIGN SYSTEM ARCHITECTURE

## 1. Architectural Philosophy
The GlowApp Design System follows **Atomic Design** principles adapted for modern Next.js 15 (App Router) and Flutter multi-platform ecosystems.

```
src/
├── components/
│   ├── ui/               # ATOMS & PRIMITIVES (Button, Input, Badge, Dialog)
│   ├── common/           # MOLECULES & COMPOSITE (SearchBar, StatCard, EmptyState)
│   └── layout/           # ORGANISMS & LAYOUT (Header, Sidebar, Shell)
└── features/
    └── [feature_name]/   # FEATURE ORGANISMS (BookingCard, ProviderProfileHeader)
        └── components/
```

---

## 2. Tailwind CSS & Utility Enforcement
- Configuration managed in `admin-dashboard/tailwind.config.ts`.
- Direct hex color hardcoding is strictly forbidden in components. Use tokenized Tailwind classes (`bg-rose-500`, `text-slate-900`, `border-slate-200`).
- Class merger utility `cn(...)` (`clsx` + `tailwind-merge`) must be used for conditional class assignment.

---

## 3. Flutter Design System Mapping
- Theme configuration centralized in `frontend/lib/config/theme.dart` (or `AppColors` / `AppTextStyles`).
- Color mappings:
  - `AppColors.primary` -> `Color(0xFFF43F5E)` (Rose 500)
  - `AppColors.surface` -> `Color(0xFFF8FAFC)` (Slate 50)
  - `AppColors.textDark` -> `Color(0xFF0F172A)` (Slate 900)
- Component wrappers standardizing touch targets (`minimumSize: Size(44, 44)`).
