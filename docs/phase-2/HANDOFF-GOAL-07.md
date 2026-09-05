# GLOWAPP PHASE 2 — HANDOFF TO GOAL 07 (DOMAINS & AGENT PARALLELIZATION)

## 1. Handoff Specification

### WHAT IS NOW STABLE
- Information Architecture for Public, Auth, Client, Provider, and Admin portals.
- Role-aware Navigation Contracts and Deep-linking guidelines (`docs/phase-2/NAVIGATION-CONTRACT.md`).
- Domain Agent Parallelization Matrix (`docs/phase-2/DOMAIN-AGENT-MATRIX.md`).

### WHAT IS IMPLEMENTED
- Information Architecture schemas, User Journey Maps, Screen Inventories, and Product Terminology standards.
- Updated Agent Governance Contract (`docs/phase-2/AGENT-CONTRACT.md`).

### WHAT FUTURE AGENTS MAY MODIFY
- Domain-specific feature components in `@/features/[domain]/components/`.
- Screen-level view models and API integrations within assigned domain boundaries.

### WHAT FUTURE AGENTS MUST NOT MODIFY
- Shared UI primitives (`@/components/ui/`).
- Global layout shells, core routing configurations, or Design Tokens.

### DOMAIN OWNERSHIP
- `AUTH`: Agent 01
- `CLIENTS`: Agent B
- `PROVIDERS`: Agent C
- `BOOKINGS`: Agent D
- `PAYMENTS`: Agent E

### SHARED COMPONENT OWNERSHIP
- Core Design System team / Goal 05 Contracts.

### ROUTE OWNERSHIP
- Assigned strictly per Domain Agent Matrix (`docs/phase-2/DOMAIN-AGENT-MATRIX.md`).

### API DEPENDENCIES
- Goal 04 API Contracts (`/api/v1/*`).

### DATA DEPENDENCIES
- PostgreSQL schema & Goal 03 Data Architecture.

### EVENT DEPENDENCIES
- Goal 04 Event Catalog.

### PERMISSION DEPENDENCIES
- Goal 01 Auth & RBAC Matrix (`CLIENT`, `PROVIDER`, `ADMIN`).

### CONFLICT ZONES
- `@/components/ui/`, global layout shells, `tailwind.config.ts`, `AppColors.dart`.

### PARALLELIZATION PLAN
- Autonomous domain agents may execute in parallel provided they stay strictly within their assigned route and feature folder boundaries.
