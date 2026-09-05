# GLOWAPP PHASE 2 — HANDOFF TO GOAL 06 (CORE BUSINESS DOMAINS)

## 1. Architectural Handoff Rules for Goal 06
Agents working on Goal 06 and subsequent functional domain implementations must adhere strictly to the Design System & UX guidelines established in Goal 05.

---

## 2. Core Mandatory Guidelines for Domain Execution
1. **Design Token Compliance:** All UI components in React/Next.js must use tokenized Tailwind classes. Hardcoding hex colors (`#F43F5E`, `#0F172A`, etc.) is strictly forbidden.
2. **Component Reuse:** Use primitives from `@/components/ui/` (`Button`, `Input`, `Dialog`, `Badge`, `Skeleton`, `Card`) before attempting to construct new custom controls.
3. **Booking Sequence:** Any booking interaction logic must comply with the 3-step progression (Cuándo/Dónde -> Productos -> Pago).
4. **Accessibility First:** Ensure all touch targets are $\ge 44\times 44\text{px}$, colors satisfy WCAG 2.1 AA contrast ($4.5:1$), and interactive elements have keyboard focus states.
5. **No Visual Destruction:** Preserve existing product visual identity while elevating component modularity and responsiveness.
