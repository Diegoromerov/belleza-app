---
name: glow-ui-design-director
description: Full-loop Flutter UI/UX Design Director: inspect code, render UI, diagnose, propose, implement in a temporary worktree, compare before/after, validate and export Git patches.
version: 2.0.0
author: GlowApp project
license: MIT
platforms: [windows, macos, linux]
metadata:
  hermes:
    tags: [flutter, ui, ux, design-system, accessibility, visual-regression, patches]
    category: development
    requires_toolsets: [file, terminal, browser, vision]
---

# Glow UI Design Director V2

## Mission

Improve an existing Flutter product through evidence-backed design experiments. The product is mature; do not rebuild it.

## Required loop

DISCOVER
→ STATIC AUDIT
→ BEFORE RENDER
→ DIAGNOSE
→ PROPOSE
→ TEMP WORKTREE
→ IMPLEMENT
→ AFTER RENDER
→ COMPARE
→ REGRESSION CHECK
→ EXPORT PATCH
→ HUMAN REVIEW

## Phase 0 — Safety

Read:
- AGENTS.md
- .ui-audit/config.yaml
- .ui-audit/rubric.yaml

Then:
- `git status`
- verify clean working tree unless user explicitly authorizes otherwise
- identify branch
- do not expose secrets

## Phase 1 — Discovery

Map:
- pubspec.yaml
- lib/
- routes
- theme
- tokens
- shared widgets
- state management
- ProviderDetailScreen
- BookingScreen
- booking flow
- cross-sell flow

Identify:
- hardcoded colors
- arbitrary spacing
- radius inconsistencies
- typography inconsistencies
- duplicate components
- missing states
- responsive issues

## Phase 2 — Runtime

Run `flutter devices`.

Prefer:
1. Flutter Web + browser automation if functional.
2. Android emulator/device + screenshots if available.
3. Static analysis only when rendering is unavailable.

Capture actual rendered UI.

## Phase 3 — Priority audit

### ProviderDetailScreen

Explicitly evaluate:
- SliverAppBar behavior and parallax;
- generic hardcoded cover;
- provider identity/trust;
- service information;
- pricing;
- reviews;
- availability;
- primary CTA;
- information hierarchy;
- scroll behavior.

Do not claim a generic cover is bad merely because it is generic; determine whether it harms trust, personalization or hierarchy.

### BookingScreen

Evaluate cognitive load and task sequencing.

Test the conceptual sequence:
1. Cuándo y Dónde
2. Productos
3. Confirmación/Pago

Evaluate:
- progressive disclosure;
- progress indicator;
- sticky summary;
- price visibility;
- upsell timing;
- validation;
- error recovery;
- incomplete checkout.

Do not change business logic; propose UI/flow changes around it.

## Phase 4 — Evidence-backed diagnosis

For each issue:
- ID
- severity
- category
- screen/widget
- file/location
- evidence
- impact
- recommendation
- confidence
- risk

Never present hypotheses as observed facts.

## Phase 5 — Proposal generation

Generate up to 3 proposals at a time.

Each proposal must include:
- problem;
- current behavior;
- proposed behavior;
- rationale;
- design-system impact;
- accessibility impact;
- responsive impact;
- business-logic impact;
- risk;
- acceptance criteria.

Save proposals under `.ui-audit/proposals/`.

## Phase 6 — Design experiment

For only high-confidence, low-risk proposals:

1. Create a temporary Git worktree outside the main workspace.
2. Implement the UI change there.
3. Do not change backend, API, auth, payment, database or business logic.
4. Run `flutter analyze`.
5. Run relevant tests.
6. Render the changed screen.
7. Capture AFTER evidence.

If rendering is unavailable, mark the experiment as static-only and do not claim visual confirmation.

## Phase 7 — BEFORE → PROPOSAL → AFTER

For every experiment produce:

BEFORE:
- screenshot
- code reference
- diagnosis

PROPOSAL:
- intended visual/UX state
- rationale

AFTER:
- screenshot
- changed files
- observed result

Then compare:
- hierarchy
- spacing
- typography
- color
- contrast
- density
- interaction clarity
- cognitive load
- accessibility
- responsive behavior
- component consistency

## Phase 8 — Regression gate

Reject or revise a proposal if it causes:
- overflow
- clipping
- broken navigation
- broken state
- broken accessibility
- unexpected visual regression
- loss of important provider/service information
- increased cognitive load
- business behavior change

## Phase 9 — Patch export

Export only accepted experiments as Git patches.

Validate:

`git apply --check .ui-audit/patches/<patch>.patch`

Do not apply to the main branch.

Each patch should be small and focused.

## Phase 10 — Final reports

Generate:
- `.ui-audit/reports/design-director.md`
- `.ui-audit/reports/audit-report.md`
- `.ui-audit/reports/visual-diff.md`
- `.ui-audit/reports/change-plan.md`

Also preserve evidence in:
- `.ui-audit/evidence/before/`
- `.ui-audit/evidence/proposal/`
- `.ui-audit/evidence/after/`

## Final response

Report:
1. overall score;
2. top P0/P1 issues;
3. top opportunities;
4. proposals tested;
5. proposals accepted/rejected;
6. files changed in temporary worktrees;
7. patches generated;
8. `git apply --check` result;
9. `flutter analyze` result;
10. test result;
11. limitations.

Never say "users prefer this" unless user testing exists. Say "heuristic expectation" or "design hypothesis".

## Completion criteria

The run is complete only when the audit and reports exist, all generated patches pass validation, and the main working tree remains unchanged.
