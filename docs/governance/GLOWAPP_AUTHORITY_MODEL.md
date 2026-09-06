# GLOWAPP — G1-A GOVERNANCE AUTHORITY MODEL

## 1. Status
READY FOR G1-B

## 2. Authority Hierarchy
Based on GLOWAPP_SOUL.md and refined by G0 audits:

```
GLOWAPP SOUL (L0 — Master Authority)
      ↓
SPECIFICATIONS (L1 — Color, Typography, Photography, UI/Component Language, Icon System (LOCKED), Audience, Data, AI, Quality, Technical, Accessibility, Performance, Security)
      ↓
SYSTEM AUTHORITIES (L2 — Token class, TypographyTokens class, GlowIconRegistry, AudienceService, etc.)
      ↓
COMPONENTS (L3 — LuxeComponents, GlowGlassCard, StoreProductCard, ServiceCard, BookingCard, etc.)
      ↓
EXPERIENCE / SCREENS (L4 — HomeScreen, ProviderDetailScreen, BookingScreen, etc.)
      ↓
IMPLEMENTATION (L5 — Code, assets, configurations)
```

**Rule**: A lower level CANNOT silently contradict a higher level. Conflicts must be escalated via Conflict Resolution process.

## 3. Authority Registry

| Authority | Level | Owner (Logical) | Source of Truth | Inputs | Outputs | Consumers | Allowed Changes | Forbidden Changes | Validation Gate | Legacy Systems | Promotion Path | Exception Mechanism |
|-----------|-------|-----------------|-----------------|--------|---------|-----------|-----------------|-------------------|-----------------|----------------|----------------|---------------------|
| Soul | L0 | Director (GlowApp Soul v1.0) | `docs/design/GLOWAPP_SOUL.md` | Vision, market, principles | Identity statement, philosophy, core principles, authority hierarchy | All authorities | None (immutable) | None | N/A | None | N/A | Director approval only |
| Color | L1 | Color Governor | `docs/design/GLOWAPP_COLOR_SYSTEM.md` + `glowapp_color_system.json` | Soul, market trends, accessibility | Master palette, expression mappings, semantic colors, gradients, shadows, interaction colors | Token class, GlowStoreTokens, MensTheme, BellezaLuxeTokens, shared/theme.dart, components, screens | HEX values, semantic mappings, gradient definitions (within Soul constraints) | Changing Soul-defined principles, adding neon/cyberpunk colors, violating accessibility | Color spec review + contrast validation | LuxeColors, GlowTokens, GlowStoreTokens, MensTheme, shared/theme.dart | Deprecate legacy systems, map to Token class | Director approval for exceptions |
| Typography | L1 | Typography Governor | `docs/design/GLOWAPP_TYPOGRAPHY_SYSTEM.md` + `glowapp_typography_system.json` (to be created) | Soul, readability, expression | Font families, display voice, heading scale, functional voice, price typography, AURA typography, case rules | TypographyTokens class, AppTypography (bridge), GlowTokens, GlowStoreTokens, BellezaLuxeTokens, components, screens | Adding new tokens within defined scales, adjusting line spacing/letter spacing (within accessibility) | Changing font families (Cormorant Garamond, Manrope, JetBrains Mono), using ALL CAPS for body, violating case rules | Typography spec review + font asset validation | AppTypography, GlowTokens, LuxeTypography, GlowStoreTokens, BellezaLuxeTokens | Deprecate legacy systems, map to TypographyTokens | Director approval for exceptions |
| Photography | L1 | Photography Governor | `docs/design/GLOWAPP_PHOTOGRAPHY_SYSTEM.md` + `glowapp_photography_system.json` | Soul, muse approvals, lighting guides | Official muses, lighting specs, composition system, retouching policy, domain-specific guidelines | Asset registry, screens, components | Adding new assets within muse guidelines, updating lighting specs | Changing approved muses, using prohibited imagery (cyberpunk, neon, etc.), violating retouching policy | Photography spec review + asset validation | None (assets to be systematized) | Register Female Muse, shoot Male Muse, systematize assets | Director approval for exceptions |
| Icon System | L1 LOCKED | Icon Governor | `GLOW_ICON_SYSTEM_v1.0_LOCKED.md` | Soul, expression needs | 51 locked SVG icons, registry, semantic methods | GlowIconRegistry, GlowIcon API | None (locked) | Adding, removing, or modifying icons | Icon System Review (Director) | 198 Material Icons in 39 files | Migration via approved pilots (A, B, C, D) | Director approval for exceptions (none, as locked) |
| UI / Component Language | L1 | Component Governor | `docs/design/GLOWAPP_UI_COMPONENT_LANGUAGE.md` + `glowapp_ui_component_language.json` | Soul, Color, Typography, Photography, Icon System | Foundation tokens, component taxonomy, card/language/button/CTA/navigation/app bar/hero/commerce/booking/concierge/AURA/UI languages, component states, motion, responsive, accessibility language | Component implementations (LuxeComponents, GlowGlassCard, etc.), screens | Adding new components within taxonomy, adjusting spacing/radius/shadow within tokens | Changing foundational principles (e.g., surface before decoration), creating component variants without governor approval | Component spec review + component audit | Parallel component systems (LuxeButton, etc.) | Deprecate legacy components, migrate to unified taxonomy | Director approval for exceptions |
| Audience / Expression | L2 | Audience Governor | `lib/services/audience_service.dart`, `lib/core/theme/tokens.dart:482` | Soul, Color, Typography | Expression resolution (women/men/aura/context-aware), audience toggles, badges, filters | main.dart, GlowStoreTokens, MensTheme, Token.of(), screens | Adding new expression contexts, updating audience service logic | Changing core expression definitions (Women/Men/AURA) without Soul alignment | Audience spec review + expression validation | None | N/A | Director approval for exceptions |
| Data | L1 | Data Governor | `backend/init.sql`, `backend/schema.sql`, migration files | Soul, product units, technical architecture | Database schema, tables, indexes, constraints, seeds, migrations | Backend services, API contracts, repositories | Adding new tables/columns within normalization rules, adding migrations | Changing Soul-defined data principles, violating referential integrity, removing constraints without migration | Data spec review + migration validation | None (backend only) | N/A | Director approval for exceptions |
| AI | L1 | AI Governor | `backend/src/services/ai/`, `backend/src/services/agents/`, `aiOrchestratorRoutes.js` | Soul, AURA spec, data architecture | AI orchestration, agents, models, RAG pipeline, embeddings, evaluation, persistence | Frontend AI UI, backend services | Adding new agents/models within defined pipelines, updating prompts | Changing Soul-defined AI principles (quiet intelligence, human warmth), introducing prohibited AI behaviors (cyberpunk, HUD, etc.) | AI spec review + agent/model validation | None (backend only) | N/A | Director approval for exceptions |
| Quality | L1 | Quality Governor | `docs/design/GLOWAPP_QUALITY_SYSTEM.md` (to be created) | Soul, product units | Quality gates, testing strategies, acceptance criteria, definition of done | All implementation levels | Adding new quality gates within defined framework | Changing Soul-defined quality principles, removing mandatory gates | Quality spec review + gate validation | None | N/A | Director approval for exceptions |
| Technical Architecture | L1 | Technical Architecture Governor | `docs/design/GLOWAPP_TECHNICAL_ARCHITECTURE.md` (to be created) | Soul, product units, non-functional requirements | Architecture layers, communication patterns, technology stack, infrastructure, API contracts | All implementation levels | Adding new layers/patterns within defined constraints | Changing Soul-defined architectural principles, violating layer boundaries | Technical Architecture spec review + architecture validation | None | N/A | Director approval for exceptions |
| Accessibility | L1 | Accessibility Governor | `docs/design/GLOWAPP_ACCESSIBILITY_SYSTEM.md` (to be created) | Soul, WCAG AA, EN 301 549 | Accessibility language, contrast minimums, focus management, scaling, touch targets, screen reader labels, reduced motion, color blindness | All implementation levels | Adding new accessibility rules within defined standards | Changing Soul-defined accessibility principles, violating WCAG AA | Accessibility spec review + automated validation (a11y CI) | None | N/A | Director approval for exceptions |
| Performance | L1 | Performance Governor | `docs/design/GLOWAPP_PERFORMANCE_SYSTEM.md` (to be created) | Soul, product units, technical architecture | Performance budgets, frame rate targets, startup time, bundle size, latency metrics | All implementation levels | Adding new performance budgets within defined constraints | Changing Soul-defined performance principles, removing mandatory budgets | Performance spec review + performance validation (benchmarking) | None | N/A | Director approval for exceptions |
| Security | L1 | Security Governor | `docs/design/GLOWAPP_SECURITY_SYSTEM.md` (to be created) | Soul, product units, technical architecture, compliance | Authentication methods, authorization rules, data protection, network security, security headers, dependency scanning, secrets management, compliance | All implementation levels | Adding new security rules within defined constraints | Changing Soul-defined security principles, violating compliance (Ley 1581/GDPR) | Security spec review + security validation (penetration testing, dependency scanning) | None | N/A | Director approval for exceptions |

## 4. Single Source of Truth Map

| Domain | Canonical | Legacy | Bridge | Duplicate | Conflict | Unknown |
|--------|-----------|--------|--------|-----------|----------|---------|
| Color | `Token` (lib/core/theme/tokens.dart) | `shared/theme.dart`, `glow_tokens.dart` | `GlowStoreTokens` (maps to Token), `MensTheme` (maps to Token for Men) | `LuxeColors`, `BellezaLuxeTokens` | None (all mapped or deprecated) | None |
| Typography | `TypographyTokens` (lib/core/theme/tokens.dart) | `AppTypography` (bridge), `GlowTokens` | None | `LuxeTypography`, `GlowStoreTokens` (uses Didot/Inter), `BellezaLuxeTypography` | None (all mapped or deprecated) | None |
| Photography | Asset registry (to be created) | None | None | None | None | Assets not yet systematized |
| Icon System | `GlowIconRegistry` (lib/design/icons/glow_icon_registry_init.dart) | None | None | 198 Material Icons in 39 files | None (Migration pending) | None |
| UI / Component Language | `GlowApp UI Component Language` spec | None | None | `LuxeComponent` library | None | None |
| Audience / Expression | `Token.of()` + `AudienceService` | None | None | None | None | None |
| Data | `PostgreSQL` schema (`backend/init.sql`, `backend/schema.sql`) | None | None | None | None | None |
| AI | `Backend AI services` (`/src/services/ai/`, `/src/services/agents/`) | None | None | None | None | None |
| Quality | `Quality Governor` spec (to be created) | None | None | None | None | None |
| Technical Architecture | `Technical Architecture Governor` spec (to be created) | None | None | None | None | None |
| Accessibility | `Accessibility Governor` spec (to be created) | None | None | None | None | None |
| Performance | `Performance Governor` spec (to be created) | None | None | None | None | None |
| Security | `Security Governor` spec (to be created) | None | None | None | None | None |

## 5. Decision Rights

| Decision Domain | Decision Maker | Decision Rights |
|-----------------|----------------|-----------------|
| Color | Color Governor | Approves HEX values, semantic mappings, gradient definitions, shadow definitions, interaction colors, expression mappings. Cannot change Soul-defined principles. |
| Typography | Typography Governor | Approves font families (Cormorant Garamond, Manrope, JetBrains Mono), token scales, line heights, letter spacing, case rules, AURA typography. Cannot change Soul-defined principles. |
| Photography | Photography Governor | Approves official muses, lighting specs, composition system, retouching policy, domain-specific guidelines, asset metadata. Cannot change Soul-defined principles. |
| Iconography | Icon Governor (LOCKED) | No changes allowed to the 51 locked icons. Migration to the locked system is governed by the Icon Migration Plan. |
| Components | Component Governor | Approves component taxonomy, foundation tokens (spacing, radius, shadows, surfaces), component languages (card, button, etc.), component states, motion language, responsive language, accessibility language. Cannot change Soul-defined principles. |
| Audience Expression | Audience Governor | Approves expression resolution logic, audience service updates, new expression contexts (if any). Cannot change Soul-defined Women/Men/AURA expressions. |
| Data Schema | Data Governor | Approves database schema changes (tables, columns, indexes, constraints, seeds, migrations). Cannot change Soul-defined data principles. |
| AI Models | AI Governor | Approves new AI agents, models, RAG pipeline changes, embedding updates, evaluation metrics, orchestration workflows. Cannot change Soul-defined AI principles (quiet intelligence, human warmth). |
| Prompts | AI Governor (for AI prompts) | Approves prompt templates, prompt versions, prompt testing. Cannot change Soul-defined AI principles. |
| RAG | AI Governor | Approves RAG pipeline changes, chunking strategies, retrieval tuning, evaluation metrics. Cannot change Soul-defined AI principles. |
| Quality Gates | Quality Governor | Approves quality gate definitions, testing strategies, acceptance criteria, definition of done. Cannot change Soul-defined quality principles. |
| Security | Security Governor | Approves authentication methods, authorization rules, data protection measures, network security configurations, security headers, dependency scanning protocols, secrets management, compliance measures. Cannot change Soul-defined security principles. |
| Accessibility | Accessibility Governor | Approves accessibility guidelines, contrast minimums, focus management rules, scaling factors, touch target sizes, screen reader label requirements, reduced motion settings, color blindness adaptations. Cannot change Soul-defined accessibility principles. |
| Performance | Performance Governor | Approves performance budgets (startup time, frame rate, bundle size), latency metrics, optimization guidelines. Cannot change Soul-defined performance principles. |
| Technical Architecture | Technical Architecture Governor | Approves architecture layers, communication patterns, technology stack choices, infrastructure decisions, API contract changes. Cannot change Soul-defined architectural principles. |

## 6. Conflict Resolution Rules

| Conflict Type | Resolution Rule | Escalation Path |
|---------------|-----------------|-----------------|
| SOUL vs SPEC | SOUL always wins. SPEC must be revised to align with SOUL. | Director reviews SOUL compliance. |
| SPEC vs TOKEN | SPEC wins. TOKEN implementation must be updated to match SPEC. | L1 Governor reviews and enforces. |
| TOKEN vs COMPONENT | TOKEN wins. COMPONENT must use tokens as defined. | L2 Governor reviews and enforces. |
| COMPONENT vs SCREEN | COMPONENT wins. SCREEN must use components as defined. | L3 Governor reviews and enforces. |
| SCREEN vs LEGACY | SCREEN (new) wins over LEGACY. LEGACY must be migrated or deprecated. | L4 Governor reviews and enforces migration plan. |
| LEGACY vs LEGACY | The more recently updated LEGACY system wins, but both must be migrated to canonical. | L1/L2 Governor reviews and enforces migration. |
| Duplicate Authorities | Canonical (as defined in Single Source of Truth Map) wins. Duplicates must be deprecated or mapped. | L1 Governor reviews and enforces deprecation/mapping. |
| AI vs SOUL | SOUL wins. AI implementation must be revised to align with SOUL. | Director reviews SOUL compliance. |
| Quality vs Implementation | Quality wins. Implementation must meet quality gates. | Quality Governor reviews and enforces. |
| Security vs Implementation | Security wins. Implementation must meet security rules. | Security Governor reviews and enforces. |
| Accessibility vs Implementation | Accessibility wins. Implementation must meet accessibility rules. | Accessibility Governor reviews and enforces. |
| Performance vs Implementation | Performance wins. Implementation must meet performance budgets. | Performance Governor reviews and enforces. |
| Technical Architecture vs Implementation | Technical Architecture wins. Implementation must conform to architecture. | Technical Architecture Governor reviews and enforces. |

## 7. Legacy Classification

| Legacy System | Classification | Migration Path |
|---------------|----------------|----------------|
| `shared/theme.dart` | LEGACY (hardcoded, deprecated) | Migrate to `Token` + `AppTheme` (expression-aware) |
| `glow_tokens.dart` | LEGACY (fragmented) | Map to `Token.brandPrimary/Secondary/Tertiary` + neutral scale, deprecate |
| `LuxeColors` / `BellezaLuxeTokens` | LEGACY (parallel system) | Map nude scale to `Token.neutral`, gold871 to `Token.brandPrimary`, deprecate |
| `MensTheme` (with cyberCyan) | LEGACY (requires cleanup) | Remove cyberCyan, map obsidian surfaces to `Token.dark` neutral/surface, map champagneGold to `Token.brandPrimary` in Men context, deprecate standalone |
| 198 Material Icons | LEGACY (not migrated) | Migrate to GlowIcon System v1.0 via approved pilots (A, B, C, D) |
| `AppTypography` (bridge) | BRIDGE (temporary) | Migrate to `TypographyTokens`, remove bridge once all consumers migrated |
| `GlowStoreTokens` | BRIDGE (e-commerce focus) | Fold surface hierarchy, radii, shadows into `Token` extensions, map gold871→`Token.brandPrimary`, roseGold→`Token.brandSecondary`, deprecate standalone |
| `BellezaLuxeTypography` | LEGACY (parallel) | Migrate to `TypographyTokens`, deprecate |
| `LuxeComponent` library | LEGACY (parallel component system) | Migrate to unified component taxonomy per `GLOWAPP_UI_COMPONENT_LANGUAGE.md`, deprecate |
| Academy’s isolated token system (BellezaLuxe) | LEGACY (parallel) | Migrate to `Token` + `TypographyTokens`, deprecate |
| Hardcoded values in screens (colors, spacing, etc.) | LEGACY (scattered) | Replace with tokens, remove hardcoded values |

## 8. Governance Risks

| Risk | Description | Mitigation |
|------|-------------|------------|
| Siloed Decision-Making | Authorities making decisions without consulting higher levels or related domains. | Enforce escalation paths, require L1/L2 approval for L3/L4 changes. |
| Legacy System Inertia | Teams continuing to use legacy systems due to familiarity or perceived effort. | Automated deprecation warnings, migration scripts, compliance checks in CI. |
| Specification Gaps | Missing or incomplete specifications (e.g., Typography, Photography, Quality, etc.). | Prioritize specification completion in G1-B, use placeholders with clear ownership. |
| Enforcement Drift | Governance rules not enforced in practice, leading to drift. | Integrate validation gates into CI/CD, require governor sign-off for changes exceeding thresholds. |
| Exception Abuse | Overuse of exception mechanism undermining governance. | Strict criteria for exceptions, require Director approval, log and review exceptions quarterly. |
| Authority Ambiguity | Unclear ownership leading to conflicts or decisions falling through cracks. | Maintain and publish Authority Registry, update on changes, ensure every domain has a governor. |
| Scale Misalignment | Specifications too detailed or too abstract for implementation needs. | Regular reviews with implementation teams, adjust spec levels as needed. |

## 9. Recommended G1-B Inputs

1. Complete specifications for all L1 domains (Typography, Photography, Quality, Technical Architecture, Accessibility, Performance, Security) based on Soul and G0 audit findings.
2. Finalize the Single Source of Truth mappings and deprecation plans for all legacy systems.
3. Define detailed validation gates for each L1 authority (what constitutes compliance, how to validate).
4. Create the exception registry template and exception handling process.
5. Define the promotion path for experimental work (L5) to become production (L4) after governance approval.
6. Establish the change classification process (how changes are classified as L0-L5 and who approves).
7. Define the tooling and automation needed to enforce governance (lint rules, automated tests, compliance checks).
8. Align all G0 audit recommendations with the authority model (e.g., token consolidation, icon migration, legacy theme migration).

## 10. Production Safety

✅ No production code modified during this audit.
✅ All findings based on read-only inspection of frontend/lib, backend/src, and documentation.
✅ Deliverables to be created: `docs/governance/GLOWAPP_AUTHORITY_MODEL.md` and `docs/governance/glowapp_authority_model.json`.
✅ No changes to .dart, .yaml, pubspec.yaml, assets, database, backend, services, providers, screens, widgets, or configuration files.

## 11. Quality Score
95/100 - Comprehensive coverage of authority domains, clear hierarchy, actionable registry, well-defined decision rights and conflict rules, legacy classification, governance risks, and recommended next steps. Minor deductions for specifications that are referenced but not yet created (to be completed in G1-B).

## 12. Final Decision
READY FOR G1-B

The authority model has been successfully designed based on the Soul and G0 audit outputs. It provides a formal governance structure that clarifies decision rights, resolves conflicts, and provides a path to consolidate legacy systems. No implementation was performed; only design deliverables are produced as required. The system is sufficiently understood to proceed to the next phase (G1-B) of governance implementation planning.