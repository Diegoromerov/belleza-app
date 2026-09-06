# GLOWAPP PHASE 2 — DESIGN TOKENS SPECIFICATION

## 1. Overview
Single source of truth for visual decisions across web (`admin-dashboard`), mobile (`frontend` Flutter), and marketing (`landing`).

---

## 2. Categorized Tokens

### 2.1 Color Tokens
- **Brand Tokens:**
  - `color-brand-primary`: `#F43F5E` (Rose 500)
  - `color-brand-primary-hover`: `#E11D48` (Rose 600)
  - `color-brand-primary-light`: `#FFE4E6` (Rose 100)
  - `color-brand-secondary`: `#7C3AED` (Violet 600)
- **Neutral Tokens (Slate Spectrum):**
  - `color-neutral-900`: `#0F172A` (Text Primary / Dark Surface)
  - `color-neutral-800`: `#1E293B`
  - `color-neutral-700`: `#334155`
  - `color-neutral-600`: `#475569`
  - `color-neutral-500`: `#64748B` (Muted Text / Placeholder)
  - `color-neutral-400`: `#94A3B8`
  - `color-neutral-300`: `#CBD5E1` (Border Light)
  - `color-neutral-200`: `#E2E8F0` (Divider)
  - `color-neutral-100`: `#F1F5F9` (Subtle Background)
  - `color-neutral-50`:  `#F8FAFC` (App Light Background)
- **Semantic Feedback Tokens:**
  - `color-success-500`: `#10B981` (Emerald) — Confirmed, Active, Paid
  - `color-warning-500`: `#F59E0B` (Amber) — Pending, Low Stock
  - `color-error-500`:   `#EF4444` (Red) — Cancelled, Failed, Overdue
  - `color-info-500`:    `#0284C7` (Sky) — Informational Notice

### 2.2 Typography Tokens
- `font-family-sans`: Inter, Geist, system-ui, sans-serif
- `font-size-display`: 36px / Line Height: 44px / Weight: 700
- `font-size-h1`: 30px / Line Height: 36px / Weight: 700
- `font-size-h2`: 24px / Line Height: 32px / Weight: 600
- `font-size-h3`: 20px / Line Height: 28px / Weight: 600
- `font-size-h4`: 18px / Line Height: 26px / Weight: 600
- `font-size-body`: 16px / Line Height: 24px / Weight: 400
- `font-size-small`: 14px / Line Height: 20px / Weight: 400
- `font-size-caption`: 12px / Line Height: 16px / Weight: 400

### 2.3 Spacing, Radius & Elevation Tokens
- **Spacing (4px base grid):** 4px (`space-1`), 8px (`space-2`), 12px (`space-3`), 16px (`space-4`), 24px (`space-6`), 32px (`space-8`), 48px (`space-12`).
- **Radius:** 4px (`radius-sm`), 8px (`radius-md`), 12px (`radius-lg`), 16px (`radius-xl`), 9999px (`radius-full`).
- **Shadows:** `shadow-sm`, `shadow-md`, `shadow-lg`, `shadow-xl`.
- **Breakpoints:** `sm: 640px`, `md: 768px`, `lg: 1024px`, `xl: 1280px`.
- **Z-Index:** `z-dropdown: 1000`, `z-sticky: 1100`, `z-modal: 1300`, `z-toast: 1500`.
- **Motion:** `duration-fast: 150ms`, `duration-normal: 250ms`, `duration-slow: 350ms`, `easing-standard: cubic-bezier(0.4, 0, 0.2, 1)`.
