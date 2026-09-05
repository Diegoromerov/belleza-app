# GLOWAPP PHASE 2 — HANDOFF TO GOAL 07 (DOMAINS & AGENT PARALLELIZATION)

## 1. Handoff Specification

### WHAT IS NOW STABLE
- Information Architecture derived from physical audit of Next.js 15 App Router (`admin-dashboard/src/app`) and Flutter (`frontend/lib/screens`).
- Navigation Contracts and Back-stack rules (`docs/phase-2/NAVIGATION-CONTRACT.md`).
- Domain Agent Parallelization Matrix (`docs/phase-2/DOMAIN-AGENT-MATRIX.md`).

### WHAT IS IMPLEMENTED
- Information Architecture, User Journey Maps, Screen Inventory (30+ physical screens), and Product Terminology standards.
- Updated Agent Governance Contract (`docs/phase-2/AGENT-CONTRACT.md`).

### WHAT FUTURE AGENTS MAY MODIFY
- Domain feature components inside `@/features/[domain]/components/` and `frontend/lib/screens/[domain]/`.

### WHAT FUTURE AGENTS MUST NOT MODIFY
- Shared UI primitives (`@/components/ui/`).
- Global layout shells, core routing configurations, or Design System tokens.

### DOMAIN OWNERSHIP
- `AUTH`: Agent 01
- `CLIENTS`: Agent B
- `PROVIDERS`: Agent C
- `BOOKINGS`: Agent D
- `ACADEMY`: Agent F

### PARALLELIZATION PLAN
- Autonomous domain agents may execute in parallel provided they stay strictly within their assigned route and feature folder boundaries.
