# GLOWAPP PHASE 2 — DESIGN SYSTEM ARCHITECTURE

## 1. Structural Tiers
```
FOUNDATION (Tokens: Color, Typography, Spacing, Radius, Shadow)
   ↓
PRIMITIVES (Atoms: Button, Input, Badge, Dialog, Skeleton, Toast)
   ↓
COMPOSED COMPONENTS (Molecules: SearchBar, StatCard, EmptyState, FormField)
   ↓
DOMAIN COMPONENTS (Organisms: BookingCard, ServiceGrid, ProviderProfileHeader)
   ↓
SCREENS / PAGES (Layouts & Viewport Orchestration)
```

---

## 2. Ownership & Governance Rules
- **Shared UI:** Owned by core Design System team. Located in `@/components/ui/` and `@/components/common/`.
- **Domain UI:** Owned by domain teams. Located in `@/features/[domain]/components/`.
- **Creation Rule:** Agents must check existing primitives before creating custom components. Duplicate creation is prohibited.
