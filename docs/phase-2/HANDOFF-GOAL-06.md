# GLOWAPP PHASE 2 — HANDOFF TO GOAL 06 (CORE BUSINESS DOMAINS)

## 1. Handoff Specification

### WHAT WAS ESTABLISHED
- Complete Design System Inventory & Token Specification (`docs/phase-2/DESIGN-TOKENS.md`).
- Unified UI Component Architecture & Primitives (`Button`, `Input`, `Dialog`, `Badge`, `Skeleton`, `Toast`).
- Product UX Principles, Accessibility Guidelines (WCAG 2.1 AA), and Mobile-First Touch Standards.

### WHAT WAS IMPLEMENTED
- Centralized Tailwind CSS design tokens and Flutter theme tokens mapping.
- Core UI component primitives and form input standardization.
- Agent UI Contract rules appended to `docs/phase-2/AGENT-CONTRACT.md`.

### WHAT REMAINS
- Execution of domain-specific business screens (Bookings, Payments, Inventory, KYC, Provider Dashboard) under Goal 06+.

### WHAT MUST NOT BE REDONE
- Do NOT recreate brand colors, design tokens, typography scales, or core UI primitives.
- Do NOT alter the 3-step booking logical progression contract (1. Cuándo/Dónde -> 2. Productos -> 3. Pago).

### WHAT GOAL 06 MAY CHANGE
- Domain-specific feature components inside `@/features/[domain]/components/`.
- Screen layouts and business workflow state handlers.

### WHAT GOAL 06 MUST NOT CHANGE
- Shared UI primitives inside `@/components/ui/`.
- Brand identity tokens, primary colors (`#F43F5E`), or core typography scales.

### DEPENDENCIES
- GOAL 00 (Governance), GOAL 01 (Auth), GOAL 02 (Core Arch), GOAL 03 (Data), GOAL 04 (API), GOAL 05 (Design System).

### KNOWN RISKS
- Potential layout breakage if future agents hardcode custom inline styles instead of using design tokens.
