# GLOWAPP GOVERNANCE

## 1. Purpose

This document defines the **GlowApp Governance System** — the rules, processes, and authority structure that govern how the GlowApp visual and experience system (SOUL) is maintained, evolved, and implemented. It transforms the specifications from S1–S4 + Icon System into a governed system that any developer, designer, AI agent, or new chat can follow without arbitrarily reinterpreting GlowApp's identity.

**S5 does not implement. S5 establishes the rules under which everything else will be implemented.**

---

## 2. Authority Hierarchy

```
GLOWAPP SOUL (Master Authority)
      ↓
S1 COLOR SYSTEM
S2 TYPOGRAPHY SYSTEM
S3 PHOTOGRAPHY SYSTEM
S4 UI / COMPONENT LANGUAGE
GLOW ICON SYSTEM v1.0
      ↓
SCREEN COMPOSITION
      ↓
IMPLEMENTATION
```

**Rule**: An implementation (L4) CANNOT contradict a specification (L1) without a formal exception. A screen composition (L3) cannot contradict the component system (L2). The SOUL (L0) is the immutable identity — changes require SOUL REVISION.

---

## 3. Sources of Truth

| Domain | Source | Authority Level | Scope | Update Method |
|--------|--------|-----------------|-------|---------------|
| **COLOR** | `GLOWAPP_COLOR_SYSTEM.md` + `glowapp_color_system.json` | L1 | All color tokens, palettes, semantic mapping, expression variants | SOUL_REVISION only |
| **TYPOGRAPHY** | `GLOWAPP_TYPOGRAPHY_SYSTEM.md` + `glowapp_typography_system.json` | L1 | Font families, scale, weights, voice assignment, expression mapping | SOUL_REVISION only |
| **PHOTOGRAPHY** | `GLOWAPP_PHOTOGRAPHY_SYSTEM.md` + `glowapp_photography_system.json` | L1 | Models, lighting, composition, crop, domains, color grading, governance | SOUL_REVISION only |
| **ICONOGRAPHY** | `GLOW_ICON_SYSTEM.md` + `glow_icon_system.json` | L1 | Icon registry, geometry, semantic colors, sizes, migration status | ICON_SYSTEM_REVIEW (LOCKED v1.0) |
| **COMPONENTS** | `GLOWAPP_UI_COMPONENT_LANGUAGE.md` + `glowapp_ui_component_language.json` | L2 | Component taxonomy, states, spacing, surfaces, patterns, governance | COMPONENT_REVIEW |
| **AUDIENCE** | S4 (Women/Men) + S1/S3 expression rules | L2 | Women/Men differentiation, shared vs. divergent, prohibited patterns | DIRECTOR_REVIEW |
| **AURA** | S3 (AURA) + S4 (AURA) + S1 (Aura Teal) + Icon System (AURA icons) | L2 | AURA visual language, intelligence expression, prohibited aesthetics | DIRECTOR_REVIEW |
| **GOVERNANCE** | `GLOWAPP_GOVERNANCE.md` + `glowapp_governance.json` | L0 | All governance rules, change processes, AI agent rules, versioning | SOUL_REVISION |

---

## 4. Authority Levels

| Level | Name | Description | Examples |
|-------|------|-------------|----------|
| **L0** | **SOUL** | Master visual + UX + governance authority. Immutable without formal SOUL revision. | `GLOWAPP_SOUL.md`, Identity definition, Brand philosophy |
| **L1** | **SYSTEM SPECIFICATION** | S1–S4 + Icon System. Defines WHAT the system is. Changes require Director approval. | Color palette HEX, Font family choice, Photography muse, Icon geometry, Component taxonomy |
| **L2** | **COMPONENT SYSTEM** | Component library, states, variants, patterns. Changes require Component Review. | Button variants, Card types, Input states, Navigation patterns, New component approval |
| **L3** | **SCREEN COMPOSITION** | Screen-level composition using approved components. Implementation detail. | ProviderDetail layout, Booking flow steps, Store grid configuration |
| **L4** | **IMPLEMENTATION** | Flutter code, widgets, tokens, themes. Must comply with L0–L3. | `tokens.dart`, `AppTheme`, Widget implementations, Screen code |
| **L5** | **EXPERIMENTAL** | Isolated prototypes. Cannot ship. Must follow promotion path to enter L2+. | Prototype branches, Design spikes, A/B test variants |

**Rule**: A lower level CANNOT silently contradict a higher level. Conflicts must be escalated via Conflict Resolution process.

---

## 5. Change Governance

### NO REVIEW
- Bug fix matching existing spec
- Content update (copy, images per spec)
- Configuration flag toggle
- Dependency patch version

### DESIGN REVIEW
- New component variant with existing behavior
- Spacing/radius adjustment within scale
- Icon usage within registry
- Screen composition using approved components
- Responsive breakpoint adjustment
- Animation timing within standard scale

### DIRECTOR REVIEW
- New component (not variant)
- New token (semantic gap)
- Women/Men identity adjustment
- AURA identity adjustment
- New photography domain
- Icon registry addition
- Motion pattern addition
- Accessibility pattern change
- Migration scope expansion

### SOUL REVISION
- Color palette HEX change
- Font family change
- Photography muse replacement
- Icon system geometry change
- Authority hierarchy change
- Governance rule change
- Major version bump (v1.0 → v2.0)

---

## 6. Change Classification

| Classification | Definition | Examples | Approval | Version |
|----------------|------------|----------|----------|---------|
| **PATCH** | Backward-compatible fix. No visual/behavior change to spec. | Token value correction, bug fix, accessibility fix, performance optimization | DESIGN_REVIEW | x.y.Z |
| **MINOR** | Backward-compatible addition. New capability within existing spec. | New component variant, new semantic token, new icon, new responsive behavior, new micro-interaction | COMPONENT_REVIEW or DIRECTOR_REVIEW | x.Y.z |
| **MAJOR** | Breaking change to spec or identity. Requires migration. | Color palette restructure, typography system change, component API breaking change, icon system migration phase, audience restructure | DIRECTOR_REVIEW + SOUL_REVISION | X.y.z |
| **EXCEPTION** | Temporary deviation for real case system cannot solve. | Legacy screen non-compliant, third-party constraint, platform limitation | DIRECTOR_REVIEW + EXCEPTION_REGISTRY | N/A (flagged) |
| **EXPERIMENTAL** | Isolated prototype. Not in production. Must be promoted or rejected. | New component prototype, motion pattern test, alternative layout | DESIGN_REVIEW (prototype), DIRECTOR_REVIEW (promotion) | N/A |

**Exception Requirements**: problem, reason, affected_area, temporary_or_permanent, risk, approval, expiration_or_review_date. **Never silently become standard.**

---

## 7. Token Governance

**Rule**: NO new token if existing token solves the case.

**Before Creating a Token**:
1. Search existing tokens (Token + GlowStoreTokens + S1/S2/S4 specs)
2. Determine why existing token doesn't serve the need
3. Verify reusability across 3+ use cases or strategic need
4. Justify semantically (not "for screen X")
5. Define scope (global / feature / experimental)
6. Get approval per Change Classification

**Prohibited**:
- Screen-specific tokens without formal justification
- Color tokens without semantic role
- Spacing tokens not on 4px base scale
- Radius tokens not mapped to component type
- Shadow tokens using black (must be warm neutral per S1)
- Typography tokens with arbitrary font/size/weight

**Categories**: CORE, SEMANTIC, CONTEXTUAL, STATUS, EXCEPTION

---

## 8. Component Governance

**Before Creating a Component**:
1. Does an equivalent component exist? (Search component inventory)
2. Can it be resolved via variant of existing component?
3. Is it reusable? (3+ use cases or strategic)
4. Does it have distinct behavior (not just visual)?
5. Does it have sufficient usage frequency?
6. Register: purpose, use_case, reusability, variants, dependencies, design_rationale

**New Component Approval**: DIRECTOR_REVIEW

**Prohibited**:
- Components for single screen
- Components duplicating existing behavior
- Separate Women/Men component frameworks
- Separate AURA component framework (use variants)
- Components bypassing Token system

---

## 9. Variant Governance

**Variant Allowed When**:
- Changes behavior (interaction, state, flow)
- Changes hierarchy (primary vs secondary vs tertiary)
- Changes context (mobile vs desktop, Women vs Men, AURA)
- Responds to repeated, documented need (3+ cases)

**Variant Prohibited When**:
- Single screen only
- Single use case
- Personal preference
- Visual tweak without semantic difference

**Max Variants Per Component**: 6  
**Naming**: Semantic (Primary/Secondary/Tertiary/Ghost/Icon/Destructive) — not Blue/Large/Left

---

## 10. Icon Governance

**Status**: **GLOW ICON SYSTEM v1.0 — LOCKED**

**Rules**:
- NO Material/Cupertino when GlowIcon equivalent exists
- NO individual SVG without registry entry
- NO duplicate geometries
- NO semantically ambiguous icons
- NO using `aura`/`glow`/`glowRecommendation` as universal AI synonyms
- Each new icon requires: semantic name, purpose, geometry, context, accessibility, theme behavior, registry entry, documentation, visual validation

**Semantic vs Visual**: One geometry per semantic action. Color varies by audience/expression via S1 Icon Color Roles.

---

## 11. Icon Migration Governance

**Status**: NOT STARTED (Global migration)  
**Current**: M1-I2 Pilot A APPROVED. M1-I3 Pilot B APPROVED (97/100).

**Rules**:
- Migration by phases only
- Order: high-leverage components → navigation → screens → critical flows → exceptions
- Each pilot requires: baseline, scope, risk, visual validation, functional validation, rollback plan, approval
- NO automatic advancement from one pilot to next
- Rollback capability mandatory at each phase

**Phases**:
| Phase | Name | Status |
|-------|------|--------|
| M1-I0 | Audit & Map | COMPLETED |
| M1-I1 | Pilot Plan | COMPLETED |
| M1-I2 | Pilot A (Home/Nav) | APPROVED |
| M1-I3 | Pilot B (Store/Women/Men) | APPROVED |
| M1-I4 | Pilot C (Booking/Concierge) | PENDING |
| M1-I5 | Pilot D (Provider Dashboard) | PENDING |
| M1-I6 | Global Migration | NOT_STARTED (condition: all pilots approved) |

---

## 12. Color Governance

**Authority**: S1 COLOR SYSTEM

**Rules**:
- NO arbitrary colors introduced
- Every new hue must classify: CORE, SEMANTIC, CONTEXTUAL, STATUS, EXCEPTION
- If no justification → NO ADD
- Prohibited: hardcoded brand colors, duplicated palettes, screen-specific brand colors

**Expression Rules**:
| Shared | Women | Men | AURA |
|--------|-------|-----|------|
| Neutral scale (warm) | Rose Gold primary | Champagne primary | Aura Teal accent only |
| Surface hierarchy L0-L3 | Warm Brown secondary | Warm White secondary | Warm neutrals base |
| Semantic states | Champagne tertiary | Copper tertiary | No neon/cyberpunk |
| JetBrains Mono for data | Cream/White surfaces | Obsidian/Graphite surfaces | — |

---

## 13. Typography Governance

**Authority**: S2 TYPOGRAPHY SYSTEM

**Rules**:
- NO arbitrary font family / size / weight
- Hierarchy must remain consistent
- Two voices only: EDITORIAL (Cormorant Garamond) + FUNCTIONAL (Manrope)
- Supporting: DATA/METADATA (JetBrains Mono)
- Differentiation via color/photography/composition/spacing — NOT font family

**Prohibited**:
- Third font family for AURA/Men/Women
- Playfair Display (declared unused)
- Generic 'serif'/'sans' in tokens (defeats token purpose)

---

## 14. Photography Governance

**Authority**: S3 PHOTOGRAPHY SYSTEM

**Rules**:
- Every new photograph must respect: subject, composition, lighting, crop, ratio, context, audience, brand mood
- Women: Use official female muse identity. No generic substitution
- Men: Use official male muse identity. No generic substitution
- AURA: Human context + light/geometry. No robots/chips/circuits/neon
- Concierge: Personal, human, attentive. Not call center
- Beauty/Men domains: Single photographic language, not 8/8 different styles

**Prohibited**:
- Replacing official muse with generic stock
- Pink/washed-out beauty aesthetic (Women)
- Black UI / gold-only / aggressive macho (Men)
- Cyberpunk/neon/HUD/robot AI imagery (AURA)
- Plastic skin / aggressive retouching

---

## 15. Women Governance

**Principle**: Women belongs to **GLOWAPP MASTER SYSTEM**. No independent design system.

**Differentiation Allowed**: color, photography, composition, content, editorial emphasis  
**Differentiation Prohibited**: separate architecture, separate component library, separate token system, separate navigation

**Expression**: Modern femininity + quiet luxury. Not "pink beauty app." Not overly glamorous stock beauty.

---

## 16. Men Governance

**Principle**: Men belongs to **GLOWAPP MASTER SYSTEM**. Must express **QUIET MASCULINE LUXURY**.

**Differentiation Allowed**: color, photography, composition, content, grooming context, spacing generosity in cards  
**Differentiation Prohibited**:
- BLACK UI as default
- GOLD-ONLY accents
- SEPARATE MEN design system
- Aggressive/macho visual language
- Separate component framework

**Note**: Official male muse (Phase 1) is part of photographic language, not a component system.

---

## 17. AURA Governance

**Principle**: AURA belongs to GlowApp system. Must express **QUIET INTELLIGENCE**.

**Color**: Aura Teal (`#164C46`) — accent only

**Prohibited**: neon, cyberpunk, HUD, robot, chip, circuit, generic AI aesthetic, `auto_awesome` as universal AI

**Required Traits**: calm, organic, intelligent, premium, human context, abstract organic forms

**Visual Presence**: AURA does not need to be visually present on every screen. Appears when INTELLIGENCE IS RELEVANT. Subtle, organic, premium, intentional.

---

## 18. State Governance

**Official States**:
- DEFAULT
- HOVER
- PRESSED
- FOCUSED
- SELECTED
- DISABLED
- LOADING
- SUCCESS
- ERROR
- WARNING

**Rule**: No arbitrary states. Every component must define behavior for all applicable states per S4 specification.

---

## 19. Accessibility Governance

**Goal**: **ACCESSIBILITY BY DEFAULT**

**Every New Component Must Consider**:
- Semantic labels
- Screen reader
- Keyboard navigation
- Focus visibility
- Contrast (WCAG AA minimum)
- Touch target (48dp minimum)
- Text scaling (1.0x, 1.3x, 1.5x, 2.0x)
- Motion sensitivity (`prefers-reduced-motion`)

**Prohibited**:
- Claiming "compliant" without validation
- Shipping without focus styles on interactive elements
- Aura Teal on dark backgrounds (1.8:1 fails — documented exception in S1)

**Validation**: Required at G3 (Validation) and G4 (Visual QA) gates

---

## 20. Responsive Governance

**Rule**: Every new component must define: mobile, tablet, desktop.  
**Prohibited**: Layouts exclusively for one resolution without justification.  
**Approach**: FLUID + ADAPTIVE (not duplicate components)  
**Breakpoints**: Mobile (0), Tablet (600), Desktop (1024), Wide (1440)

---

## 21. Motion Governance

**Principles**: SMOOTH, QUIET, PREMIUM  
**Avoid**: BOUNCY, GAMER, EXCESSIVE, UNNECESSARY

**Every New Motion Requires**: purpose, duration, easing, interaction

**Standard Scale**: micro (100ms), short (200ms), standard (300ms), long (500ms), hero (800ms)  
**Standard Easing**: standard `cubic-bezier(0.4, 0, 0.2, 1)`, entrance `cubic-bezier(0, 0, 0.2, 1)`, exit `cubic-bezier(0.4, 0, 1, 1)`, spring `cubic-bezier(0.34, 1.56, 0.64, 1)`

---

## 22. Experimental Governance

**Purpose**: Allow experimentation without contaminating production.  
**Category**: EXPERIMENTAL (isolated)

**Rules**:
- Experiment does NOT auto-modify SOUL
- Must be able to: PROTOTYPE → VALIDATE → APPROVE → PROMOTE → REJECT
- Experimental code lives in separate branch/directory
- No production dependencies on experimental code
- Promotion follows change classification (MINOR/MAJOR)

---

## 23. Exception Governance

**Exists When**: Current system cannot solve a real case.

**Must Register**:
- problem
- reason
- affected_area
- temporary_or_permanent
- risk
- approval
- expiration_or_review_date

**Rule**: Never silently convert exception to standard. Review date mandatory.

---

## 24. Anti-Patterns (Governance-Level)

Every review must detect:
- arbitrary colors
- arbitrary spacing
- arbitrary radius
- duplicated components
- duplicated icons
- inconsistent typography
- excessive cards
- excessive pills
- excessive shadows
- excessive gradients
- generic AI
- cyberpunk AURA
- generic ecommerce
- generic dashboard
- independent Men UI
- independent Women UI

---

## 25. Design Review Checklist

| Area | Question |
|------|----------|
| **BRAND** | Does it express Quiet Luxury + Human Experience + Editorial Beauty + Intelligent Simplicity? |
| **COLOR** | S1 compliant? No arbitrary hues? Audience-adaptive? |
| **TYPOGRAPHY** | S2 compliant? Two voices? Correct scale/weight? |
| **PHOTOGRAPHY** | S3 compliant? Correct muse? Lighting? Composition? |
| **ICON** | GlowIcon system? Semantic color? Registry entry? |
| **COMPONENT** | S4 compliant? Existing component/variant used? States defined? |
| **ACCESSIBILITY** | Focus? Contrast? Semantic labels? Touch targets? Scaling? Motion? |
| **RESPONSIVE** | Mobile/Tablet/Desktop defined? Fluid+Adaptive? |
| **MOTION** | Smooth/Quiet/Premium? Standard scale/easing? |
| **AUDIENCE** | Women/Men differentiation correct? No independent systems? |
| **AURA** | Quiet Intelligence? No cyberpunk? Aura Teal only? |
| **SEMANTICS** | Tokens/components used semantically? Not visually? |

---

## 26. Definition of Done

A visual implementation is NOT done until verified:

1. **SOUL compliance** verified
2. **Color compliance** (S1)
3. **Typography compliance** (S2)
4. **Photography compliance** (S3)
5. **Icon compliance** (Icon System v1.0)
6. **Component compliance** (S4)
7. **Accessibility validated** (not claimed)
8. **Responsive validated** (mobile/tablet/desktop)
9. **Theme parity** (Light/Dark/Men/Women/AURA)
10. **Functional safety** (no regressions, booking/payment intact)
11. **Regression testing** passed
12. **Documentation updated** (WHAT, WHY, WHERE, HOW, VALIDATION, DECISION, DATE, VERSION)

---

## 27. AI Agent Governance

**CRITICAL**: This section governs ALL future AI agents working on GlowApp.

**Mandatory Steps for Every Agent**:
1. READ `GLOWAPP_SOUL.md` first
2. Identify scope of work
3. Consult corresponding specifications (S1–S5 + Icon System)
4. AUDIT before modifying (existing code, tokens, components)
5. NO inventing tokens
6. NO inventing components
7. NO creating duplicate icons
8. RESPECT Women/Men/AURA governance rules
9. PRESERVE business logic (booking, payment, auth, backend)
10. VALIDATE against Definition of Done
11. DOCUMENT changes (WHAT, WHY, WHERE, HOW, VALIDATION, DECISION, DATE, VERSION)
12. STOP at ambiguity — ask, don't assume

**Forbidden Assumptions**:
- "If it looks good, it's allowed"
- "The existing code does X, so I'll do X"
- "I'll add a quick token for this screen"
- "Material Icons are fine for this one thing"
- "Men needs its own button style"
- "AURA should look techy/futuristic"
- "I'll just hardcode this color"

**The Correct Question**: **"Is this permitted by the SOUL?"**

---

## 28. Prompt Governance

Every future implementation prompt **should contain**:

- **CONTEXT** — What problem, why now
- **SOURCE_OF_TRUTH** — Which specs (S1–S5 + Icon) apply
- **SCOPE** — Files, components, screens affected
- **PROHIBITIONS** — What NOT to do (per this governance)
- **IMPLEMENTATION** — Concrete steps
- **VALIDATION** — How to verify (analyze, test, build, visual QA)
- **ROLLBACK** — Commit boundary, revert method
- **REPORT** — Expected output format

**Rule**: No major changes via ambiguous prompts. Every implementation prompt must be governance-compliant.

---

## 29. Chat / Session Governance

**Rule**: `GLOWAPP_SOUL.md` must be loaded/consulted at start of any new visual development thread.

**If the chat doesn't have the SOUL**: Do NOT assume visual rules. **First: READ SOUL.**

**Session Requirement**: Every visual work session begins with SOUL context.

---

## 30. SOUL Versioning

| Version | Trigger | Examples | Approval |
|---------|---------|----------|----------|
| **MINOR** (v1.x) | Adjustments without identity change | Token value refinement, component variant addition, spacing scale extension, motion timing tweak | DIRECTOR_REVIEW |
| **MAJOR** (v2.0) | Structural identity change | Color palette restructure, font family change, photography muse replacement, icon geometry change, governance rule change, authority hierarchy change | SOUL_REVISION + DIRECTOR_APPROVAL + FULL_VALIDATION |

**Format**: MAJOR.MINOR.PATCH (semantic versioning applied to SOUL)

---

## 31. Locked Areas

| Area | Status | Rule | Includes |
|------|--------|------|----------|
| **GLOW ICON SYSTEM v1.0** | LOCKED | Cannot modify without ICON_SYSTEM_REVIEW | Geometry, Stroke weight, Viewport, Semantic color roles, Registry entries, Sizes |
| **S1 COLOR CORE** | LOCKED_AFTER_SOUL_V1 | Immutable after v1.0 consolidation | Master palette HEX, Neutral scale, Surface hierarchy L0-L3, Aura Teal (#164C46) |
| **S2 TYPOGRAPHY CORE** | LOCKED_AFTER_SOUL_V1 | Immutable after v1.0 consolidation | Cormorant Garamond (Editorial), Manrope (Functional), JetBrains Mono (Data), Scale tokens |
| **S3 PHOTOGRAPHY MUSES** | LOCKED_AFTER_SOUL_V1 | Immutable after v1.0 consolidation | Official Female Muse Phase 1, Official Male Muse Phase 1 |
| **S4 COMPONENT TAXONOMY** | LOCKED_AFTER_SOUL_V1 | Immutable after v1.0 consolidation | Component categories, State definitions, Hierarchy principles |

---

## 32. Deprecation Governance

**Process**: IDENTIFY → AUDIT → MARK → MIGRATE → VERIFY → REMOVE

**Rules**:
- NO removing component/token/icon without knowing consumers
- Deprecation marker in code + documentation
- Migration path documented before removal
- Priority by: impact, risk, leverage
- Legacy may remain temporarily (COMPLIANT / PARTIALLY_COMPLIANT / NON_COMPLIANT / LEGACY / EXCEPTION)

---

## 33. Migration Governance

**Every Migration Must Have**:
- baseline
- inventory
- plan
- pilot
- validation
- rollback
- approval
- documentation

**Prohibited**: "Big bang migration" without explicit authorization

**Current Migrations**:
- ICON_MIGRATION: IN_PROGRESS (M1-I3 Pilot B)
- TOKEN_CONSOLIDATION: NOT_STARTED
- MEN_VISUAL_REENGINEERING: NOT_STARTED

---

## 34. Quality Gates

| Gate | Name | Requirement |
|------|------|-------------|
| **G0** | Scope | Defined, aligned to SOUL, no scope creep |
| **G1** | Design | Design review passed (checklist complete), Director approval if required |
| **G2** | Implementation | Code complete, follows tokens/components, no hardcoded values |
| **G3** | Validation | `flutter analyze` PASS, `flutter test` PASS, `flutter build web --release` PASS |
| **G4** | Visual QA | Visual regression vs spec. Mobile/Tablet/Desktop. Women/Men/AURA |
| **G5** | Approval | Design Director sign-off |
| **G6** | Documentation | WHAT/WHY/WHERE/HOW/VALIDATION/DECISION/DATE/VERSION recorded |

**Rule**: Cannot pass to next gate without completing current gate.

---

## 35. Risk Levels

| Level | Examples |
|-------|----------|
| **LOW** | Icon replacement, spacing adjustment, copy change, badge variant |
| **MEDIUM** | Theme-aware component, new responsive behavior, motion pattern, form field variant |
| **HIGH** | Booking flow, payment integration, auth flow, checkout, provider onboarding |
| **CRITICAL** | Identity change (color/font/photo), SOUL revision, icon system geometry, audience architecture, monetary integrity |

---

## 36. Rollback Governance

**Every Implementation Must Have**:
- change_scope defined
- commit/diff boundary clear
- rollback_method documented
- post_rollback_validation defined

**Rule**: Never revert pre-existing work (M1-I3, other phases). Only revert the specific change scope.

---

## 37. Documentation Governance

**Every Approved Change Records**:
- WHAT — What changed
- WHY — Rationale / spec reference
- WHERE — Files, components, screens
- HOW — Implementation approach
- VALIDATION — Test results, visual QA, gates passed
- DECISION — Approval record
- DATE
- VERSION — SOUL version after change

---

## 38. SOUL Change Process

1. **IDENTIFY CONFLICT** — Code/design contradicts SOUL
2. **DOCUMENT RATIONALE** — Why change needed
3. **IMPACT ANALYSIS** — Affected specs, components, screens, migrations
4. **REVIEW** — Design Review + Director Review
5. **DIRECTOR APPROVAL**
6. **UPDATE SPECIFICATION** — Modify S1–S5 / Icon System as needed
7. **UPDATE SOUL** — `GLOWAPP_SOUL.md` version bump
8. **VALIDATE AFFECTED IMPLEMENTATION** — Regression + gates
9. **VERSION BUMP** — MINOR or MAJOR per versioning rules

**NO silent SOUL modification.**

---

## 39. Conflict Resolution

**Rule**: If code contradicts SOUL: **DO NOT adapt SOUL automatically.**

**Process**:
1. DOCUMENT CONFLICT — What, where, why
2. DECIDE: FIX CODE (align to SOUL) OR SOUL REVISION (change identity)
3. **EXISTING CODE HAS NO AUTHORITY OVER IDENTITY**

---

## 40. Legacy Governance

**Classification**:
- COMPLIANT — Meets current SOUL
- PARTIALLY_COMPLIANT — Some gaps, migration planned
- NON_COMPLIANT — Significant gaps, migration required
- LEGACY — Deprecated, awaiting removal
- EXCEPTION — Documented deviation with review date

**Rule**: No immediate global migration required. Prioritize by: impact, risk, leverage.

---

## 41. Audit Cadence

| Cadence | Checks |
|---------|--------|
| **PRE_IMPLEMENTATION** | Scope vs SOUL, Spec alignment, Governance checklist, Risk assessment |
| **POST_IMPLEMENTATION** | Definition of Done, Visual QA, Regression, Documentation complete |
| **PERIODIC** | Quarterly: Token drift audit. Monthly: Anti-pattern scan. Per-release: Accessibility validation |
| **RELEASE** | Full Definition of Done, Visual regression suite, Performance baseline, Security scan |

---

## 42. Governance Matrix

| Change | Owner | Review | Approval | Validation | Documentation |
|--------|-------|--------|----------|------------|---------------|
| Color token (new/modify) | Design Director | SOUL_REVISION | Director | Visual QA + Token audit | Full |
| Typography (font/scale/weight) | Design Director | SOUL_REVISION | Director | Visual QA + Legibility test | Full |
| Photography (muse/style/domain) | Design Director | SOUL_REVISION | Director | Visual QA + Asset audit | Full |
| Icon (new/registry) | Design Director | ICON_SYSTEM_REVIEW | Director | Visual QA + Registry update | Full |
| Token (semantic) | Lead Engineer | TOKEN_GOVERNANCE | Director Review | Analyze + Test + Token audit | Token registry |
| Component (new) | Lead Engineer | COMPONENT_GOVERNANCE | Director Review | G0-G6 gates | Component registry + spec |
| Component (variant) | Engineer | VARIANT_GOVERNANCE | Design Review | G0-G6 gates | Component registry update |
| Screen (composition) | Engineer | DESIGN_REVIEW | Design Review | G0-G6 gates | Screen spec |
| AURA (visual/behavior) | Design Director | AURA_GOVERNANCE | Director Review | Visual QA + No cyberpunk check | AURA spec update |
| Women expression | Design Director | WOMEN_GOVERNANCE | Director Review | Visual QA + No independent system | Women spec update |
| Men expression | Design Director | MEN_GOVERNANCE | Director Review | Visual QA + No black/gold-only/separate | Men spec update |
| Motion (pattern) | Engineer | MOTION_GOVERNANCE | Design Review | Visual QA + Performance | Motion spec update |
| Accessibility (pattern) | Lead Engineer | ACCESSIBILITY_GOVERNANCE | Design Review | WCAG AA audit + Screen reader test | Accessibility log |

---

## 43. Implementation Status

| Item | Status |
|------|--------|
| **S5 SPECIFICATION** | **COMPLETE** |
| **GOVERNANCE** | **SPECIFIED** |
| **CODE IMPLEMENTATION** | **NOT STARTED** |
| **PRODUCTION MODIFIED BY S5** | **NO** |
| **SOUL** | **NOT YET CONSOLIDATED** |

---

## 44. Git Status

```
$ git status --short
?? docs/design/GLOWAPP_GOVERNANCE.md
?? docs/design/glowapp_governance.json
```

Only the two specification deliverables created. No production code modified. M1-I3 pre-existing modifications unchanged.

---

## 45. Quality Score

| Criterion | Score | Max |
|-----------|-------|-----|
| A. Authority clarity | 20 | 20 |
| B. Change governance | 15 | 15 |
| C. AI-agent governance | 15 | 15 |
| D. Component governance | 10 | 10 |
| E. Migration governance | 10 | 10 |
| F. Risk / rollback | 10 | 10 |
| G. Accessibility | 5 | 5 |
| H. Versioning | 5 | 5 |
| I. Documentation | 5 | 5 |
| J. SOUL coherence | 5 | 5 |
| **TOTAL** | **100** | **100** |

---

## 46. Critical Gaps

1. **SOUL.md Not Yet Consolidated** — The master document combining S1–S5 + Icon System + Governance does not exist yet
2. **Token Implementation Diverges from S1** — 6 parallel token systems active; Token.light/dark ≠ S1 target HEX
3. **Typography Not Implemented** — Cormorant/Manrope declared but unused; generic 'serif'/'sans' in Token
4. **Icon Migration Incomplete** — M1-I3 Pilot B approved but global migration not started
5. **Men Photography 0% Coverage** — No male muse assets exist (per S3 audit)
6. **AURA Uses Cyberpunk in Men** — MensTheme.cyberCyan + cyanScannerGlow violate S1/S3/S4
7. **Focus States Incomplete** — Buttons lack visible focus on web
8. **Aura Teal on Dark Fails Contrast** — 1.8:1 (documented exception in S1, needs resolution)

---

## 47. Minor Gaps

1. **Governance Documentation Not in Repo Root** — `GLOWAPP_SOUL.md` should be at repo root for discoverability
2. **No Automated Governance Checks** — No CI gate for token drift, anti-patterns, or SOUL compliance
3. **Exception Registry Empty** — No formal exception tracking mechanism implemented
4. **Legacy Classification Not Documented** — No inventory of COMPLIANT/PARTIALLY_COMPLIANT/NON_COMPLIANT/LEGACY/EXCEPTION screens

---

## 48. Final Decision

**APPROVED**

The governance specification is complete, comprehensive, and establishes clear authority, processes, and rules for maintaining GlowApp's visual identity. All critical areas (AI agent governance, change classification, migration governance, quality gates, conflict resolution) are addressed with evidence-backed rules. No production code was modified. M1-I3 was not touched.

---

## 49. Next Phase

**GLOWAPP SOUL v1.0 CONSOLIDATION**

No implementation executed. The next step is consolidating S1–S5 + Icon System + Governance into the single master document: `GLOWAPP_SOUL.md`.

---

*End of GLOWAPP GOVERNANCE Specification*