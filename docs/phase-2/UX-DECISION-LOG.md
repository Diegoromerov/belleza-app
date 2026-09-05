# GLOWAPP PHASE 2 — UX DECISION LOG

## 1. Architectural UX Decisions

### UX-DEC-001: Preservation of Rose 500 as Core Brand Identity
- **Date:** Phase 2 Discovery
- **Decision:** Maintain `#F43F5E` (Rose 500) as primary brand accent color.
- **Rationale:** Recognized beauty-tech identity; provides strong contrast when combined with Slate-900 typography and Slate-50 background.

### UX-DEC-002: Mandatory 3-Step Booking Progression
- **Date:** Phase 2 Discovery
- **Decision:** Enforce logical checkout sequence: 1. Cuándo y Dónde -> 2. Productos -> 3. Pago.
- **Rationale:** Reduces drop-off rates, separates decision contexts, and facilitates high-converting upsells.

### UX-DEC-003: Adoption of Skeleton Loaders Over Full-Page Spinners
- **Date:** Phase 2 UI Architecture
- **Decision:** Replace blocking activity indicators with content-shaped skeleton loaders.
- **Rationale:** Provides perceived performance boost and preserves layout stability (prevents layout shift / CLS).

### UX-DEC-004: Minimum 44x44px Touch Targets
- **Date:** Phase 2 Accessibility Audit
- **Decision:** Mandate minimum 44x44px interactive tap area on mobile and responsive web layouts.
- **Rationale:** Ensures WCAG 2.1 AA compliance and improves mobile usability for beauty appointments on the go.
