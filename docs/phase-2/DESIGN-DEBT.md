# GLOWAPP PHASE 2 — DESIGN DEBT INVENTORY

## 1. Summary of Identified Design Debt
During the Goal 05 audit, several areas of visual and structural design debt were identified across `admin-dashboard` and `frontend` (Flutter):

---

## 2. Itemized Design Debt Inventory

| Debt ID | Module | Description | Severity | Remediation Plan |
| :--- | :--- | :--- | :--- | :--- |
| **DEBT-UI-001** | Admin Dashboard | Hardcoded hex color codes in inline styles (`#10b981`, `#f43f5e`) | Medium | Replace with Tailwind design token classes |
| **DEBT-UI-002** | Flutter Frontend | Non-standard paddings (e.g. `EdgeInsets.all(13.5)`) | Low | Normalize to 4px grid tokens (8px, 12px, 16px, 24px) |
| **DEBT-UI-003** | Admin Dashboard | Missing explicit empty states in table views | Medium | Implement standard `EmptyState` component with actionable CTA |
| **DEBT-UI-004** | Flutter Frontend | Inconsistent button tap heights below 44px | High | Enforce minimum button height of 44px in `ThemeData` |
| **DEBT-UI-005** | Admin Dashboard | Unhandled loading transitions in forms | Medium | Standardize with form submission spinners and disable state |
