# GLOWAPP PHASE 2 — DESIGN DEBT INVENTORY

## 1. Itemized Debt Inventory

| DEBT ID | MODULE | DESCRIPTION | SEVERITY | REMEDIATION PLAN |
| :--- | :--- | :--- | :--- | :--- |
| **DEBT-UI-001** | Admin Dashboard | Hardcoded hex color codes in inline styles (`#10b981`, `#f43f5e`) | P1 | Replace with Tailwind design token classes |
| **DEBT-UI-002** | Flutter Frontend | Non-standard paddings (e.g. `EdgeInsets.all(13.5)`) | P2 | Normalize to 4px grid tokens (8px, 12px, 16px, 24px) |
| **DEBT-UI-003** | Admin Dashboard | Missing explicit empty states in table views | P1 | Implement standard `EmptyState` component with actionable CTA |
| **DEBT-UI-004** | Flutter Frontend | Inconsistent button tap heights below 44px | P0 | Enforce minimum button height of 44px in `ThemeData` |
| **DEBT-UI-005** | Admin Dashboard | Unhandled loading transitions in forms | P1 | Standardize with form submission spinners and disable state |
