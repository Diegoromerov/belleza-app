# GLOWAPP PHASE 2 — UX PRINCIPLES & GUIDELINES

## 1. Core Principles

### 1.1 Beauty-Tech Premium Elegance
- Clean, uncluttered layouts with adequate whitespace (`space-6` or `space-8`).
- Soft shadows (`shadow-sm`, `shadow-md`) and gentle border radii (`rounded-lg`, `rounded-xl`).
- High quality photography and avatar presentation.

### 1.2 Cognitive Load Minimization
- Progressive disclosure of complex form inputs.
- Clear visual hierarchy with bold titles and muted supporting labels.
- Unambiguous primary CTAs (maximum 1 primary button per visible viewport context).

### 1.3 Booking Flow Logical Sequence
The checkout sequence across mobile and web must adhere strictly to:
1. **Cuándo y Dónde** (Date, Time Slot, Salon/Home location)
2. **Productos & Add-ons** (Cross-sell products, service add-ons)
3. **Pago & Confirmación** (Summary sticky header/footer, payment method, instant confirmation)

---

## 2. Accessibility Guidelines (WCAG 2.1 AA)
- **Contrast Ratios:** Text to background contrast ratio minimum `4.5:1` for body text, `3:1` for large headers and icons.
- **Touch Target Size:** Interactive elements on touch devices must be at least `44x44px`.
- **Keyboard Navigation:** All interactive web components must support `:focus-visible` outline (`ring-2 ring-rose-500`).
- **Screen Reader Labels:** Form inputs must have corresponding `<label>` or `aria-label`. Icons without text must provide `aria-hidden="true"` or fallback text.

---

## 3. State Management & Responsive Behavior
- **Loading States:** Use skeleton loaders (`src/components/ui/skeleton.tsx`) instead of generic full-page blocking spinners.
- **Empty States:** Clear illustrations or icons with actionable text (e.g. "No appointments found — Book your first appointment").
- **Responsive Breakpoints:**
  - `sm`: `640px` (Mobile landscape)
  - `md`: `768px` (Tablet)
  - `lg`: `1024px` (Desktop Small)
  - `xl`: `1280px` (Desktop Large)
