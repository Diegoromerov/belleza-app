# GLOWAPP PHASE 2 — DESIGN TOKENS SPECIFICATION

## 1. Overview
Design tokens represent the single source of truth for visual decisions across GlowApp web (`admin-dashboard`), mobile (`frontend` Flutter), and landing experiences.

---

## 2. Color Tokens

### 2.1 Brand Palette
- `color-brand-primary`: `#F43F5E` (Rose 500) — Primary CTA, active states, key branding
- `color-brand-primary-hover`: `#E11D48` (Rose 600) — Hover/pressed state
- `color-brand-primary-light`: `#FFE4E6` (Rose 100) — Soft background tint
- `color-brand-secondary`: `#7C3AED` (Violet 600) — Special highlight / promo tag

### 2.2 Neutral Palette (Slate Spectrum)
- `color-neutral-900`: `#0F172A` (Primary Dark Text / Dark Mode Surface)
- `color-neutral-800`: `#1E293B` (Secondary Dark Surface)
- `color-neutral-700`: `#334155` (Muted Dark Text)
- `color-neutral-600`: `#475569` (Subtle Text)
- `color-neutral-500`: `#64748B` (Secondary Text / Placeholder)
- `color-neutral-400`: `#94A3B8` (Disabled Icon / Muted Border)
- `color-neutral-300`: `#CBD5E1` (Border Light)
- `color-neutral-200`: `#E2E8F0` (Divider / Light Border)
- `color-neutral-100`: `#F1F5F9` (Subtle Background)
- `color-neutral-50`:  `#F8FAFC` (App Surface Light Background)
- `color-neutral-0`:   `#FFFFFF` (Card Surface Pure White)

### 2.3 Semantic Feedback Tokens
- `color-success-500`: `#10B981` (Emerald) — Confirmed, Active, Paid
- `color-success-100`: `#D1FAE5` — Success Banner Light
- `color-warning-500`: `#F59E0B` (Amber) — Pending, Low Stock, Warning
- `color-warning-100`: `#FEF3C7` — Warning Banner Light
- `color-error-500`:   `#EF4444` (Red) — Cancelled, Failed, Overdue
- `color-error-100`:   `#FEE2E2` — Error Banner Light
- `color-info-500`:    `#0284C7` (Sky) — Informational Notice

---

## 3. Typography Scale

| Token Name | Font Size | Line Height | Font Weight | Usage |
| :--- | :--- | :--- | :--- | :--- |
| `font-display` | 36px (2.25rem) | 44px | 700 (Bold) | Hero Titles, KPI Highlights |
| `font-h1` | 30px (1.875rem) | 36px | 700 (Bold) | Page Titles |
| `font-h2` | 24px (1.5rem) | 32px | 600 (SemiBold) | Section Headers |
| `font-h3` | 20px (1.25rem) | 28px | 600 (SemiBold) | Card Headers / Subsections |
| `font-body-large` | 18px (1.125rem)| 28px | 400 / 500 | Feature Summaries |
| `font-body-base` | 16px (1.0rem) | 24px | 400 / 500 | Default Body Text, Form Labels |
| `font-body-small` | 14px (0.875rem)| 20px | 400 / 500 | Secondary Info, Table Data |
| `font-caption` | 12px (0.75rem) | 16px | 400 | Badges, Timestamp, Tooltips |

---

## 4. Spacing & Elevation Tokens

### Spacing Scale (4px Base Grid)
- `space-1`: 4px (`0.25rem`)
- `space-2`: 8px (`0.5rem`)
- `space-3`: 12px (`0.75rem`)
- `space-4`: 16px (`1.0rem`)
- `space-6`: 24px (`1.5rem`)
- `space-8`: 32px (`2.0rem`)
- `space-12`: 48px (`3.0rem`)

### Radii Tokens
- `radius-sm`: 4px
- `radius-md`: 8px
- `radius-lg`: 12px
- `radius-xl`: 16px
- `radius-full`: 9999px

### Shadows & Elevation
- `shadow-sm`: `0 1px 2px 0 rgba(0, 0, 0, 0.05)`
- `shadow-md`: `0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)`
- `shadow-lg`: `0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)`
