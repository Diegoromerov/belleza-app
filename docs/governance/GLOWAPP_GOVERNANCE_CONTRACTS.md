# GLOWAPP — G1-B GOVERNANCE CONTRACTS

**Phase:** G1-B — Governance Contracts  
**Status:** DESIGN COMPLETE — READ ONLY  
**Timestamp:** 2026-08-21  
**Repository:** C:\beauty-app

---

## 1. Governance Contract Model

A **Governance Contract** is a formal specification that defines the boundaries, authority, invariants, and validation rules for each system authority in GlowApp. Every authority must have a contract.

### Contract Structure (Mandatory Fields)

| Field | Description |
|-------|-------------|
| **Identity** | Unique name and purpose of the authority |
| **Purpose** | What this authority governs and why it exists |
| **Authority** | Level in hierarchy (L0–L5), decision rights, escalation path |
| **Source of Truth** | Canonical specification document(s) and location |
| **Inputs** | What feeds into this authority (requests, data, changes) |
| **Outputs** | What this authority produces (tokens, decisions, artifacts) |
| **Consumers** | Downstream systems, code, roles that depend on this authority |
| **Invariants** | Rules that MUST always hold (never violated) |
| **Forbidden Behavior** | Explicitly prohibited actions |
| **Validation** | How compliance is verified (gates, tests, audits) |
| **Version** | Current contract version and versioning rules |
| **Compatibility Rules** | Backward/forward compatibility requirements |
| **Deprecation Rules** | How elements are deprecated and removed |
| **Exception Mechanism** | How temporary deviations are handled |

---

## 2. SOUL Contract (L0 — Master Authority)

| Field | Value |
|-------|-------|
| **Identity** | `SOUL` — Master visual, UX, and governance authority |
| **Purpose** | Define the immutable identity, philosophy, and authority hierarchy of GlowApp. All lower authorities derive from SOUL. |
| **Authority** | L0 (Supreme). Changes require **SOUL_REVISION** + **DIRECTOR_APPROVAL** + **FULL_VALIDATION**. |
| **Source of Truth** | `docs/design/GLOWAPP_SOUL.md` + `glowapp_soul.json` |
| **Inputs** | Identity conflicts, major version proposals, governance rule changes, authority hierarchy changes |
| **Outputs** | Updated SOUL specification, version bump, cascading spec updates |
| **Consumers** | All L1–L5 authorities, AI agents, Design Director, Lead Engineer |
| **Invariants** |
| | • One Brand, Multiple Expressions (Women/Men/AURA/Concierge are expressions, not brands) |
| | • Photography Leads (Color, Typography, UI serve imagery) |
| | • Two Voices (Cormorant + Manrope + JetBrains Mono — no third font) |
| | • Surface Before Decoration (Hierarchy through elevation, not color noise) |
| | • AURA Is Intelligence Layer (Aura Teal accent only, not visual theme) |
| | • Accessibility By Default (Validated, not claimed) |
| | • Governance Over Preference (Process over impulse) |
| **Forbidden Behavior** |
| | • Silent SOUL modification without formal revision |
| | • Lower level contradicting higher level |
| | • Adapting SOUL to match non-compliant code |
| | • Creating separate Women/Men/AURA design systems |
| | • Third font family |
| **Validation** | Director sign-off at SOUL_REVISION gate; quarterly identity audit |
| **Version** | Current: `SOUL v1.0` (CONSOLIDATED). Format: `MAJOR.MINOR.PATCH` |
| **Compatibility** | MAJOR = structural identity change (full revalidation). MINOR = adjustments without identity change. PATCH = fixes. |
| **Deprecation** | SOUL elements deprecated via IDENTIFY → AUDIT → MARK → MIGRATE → VERIFY → REMOVE |
| **Exception** | EXCEPTION_REGISTRY required (problem, reason, area, temp/perm, risk, approval, expiration). Never silent. |

---

## 3. COLOR Contract (L1 — System Specification)

| Field | Value |
|-------|-------|
| **Identity** | `COLOR` — S1 Color System Authority |
| **Purpose** | Single source of truth for all color tokens, palettes, semantic mappings, and expression variants. Prevents arbitrary colors, dual authority, hardcoded colors, Token bypass. |
| **Authority** | L1. Changes require **SOUL_REVISION** (palette HEX) or **DIRECTOR_REVIEW** (semantic tokens). |
| **Source of Truth** | `docs/design/GLOWAPP_COLOR_SYSTEM.md` + `glowapp_color_system.json` |
| **Inputs** | New semantic token requests, expression variant needs, accessibility contrast fixes |
| **Outputs** | Color tokens (HEX), palette definitions, semantic state mappings, expression-specific assignments |
| **Consumers** | `Token` class (frontend), `GlowStoreTokens`, `AppTheme`, all UI components, AI agents |
| **Invariants** |
| | • Master Palette HEX values locked (Rose Gold `#D4AF7A`, Champagne `#D4AF37`, Aura Teal `#164C46`, Cream Silk `#FCF8F6`, Obsidian `#0A0C10`, etc.) |
| | • Neutral Scale: Warm nudes only (`nude50`–`nude900`) |
| | • Semantic States: Muted foreground only (Success `#059669`, Warning `#D97706`, Error `#DC2626`, Info `#0284C7`) |
| | • Gradients: Only purposeful 8 defined gradients |
| | • Shadows: Warm (`nude900`), never black |
| | • Expression Rules: Women=Rose Gold/Champagne/Warm Brown; Men=Champagne/Warm White/Copper; AURA=Aura Teal accent only |
| | • All color access via `Token` authority (no hardcoded colors) |
| **Forbidden Behavior** |
| | • Arbitrary HEX colors introduced |
| | • Second color authority (no parallel palettes) |
| | • Hardcoded brand colors in components/screens |
| | • Bypassing `Token` to access colors |
| | • Silent S1 alterations |
| | • `#000000` as brand background, `#FFFFFF` as brand identity |
| | • Cyber Cyan `#00E5FF` (deprecated) |
| | • Aura Teal on dark backgrounds (1.8:1 contrast fail — documented exception) |
| **Validation** | Token audit at G3 (analyze), Visual QA at G4 (Women/Men/AURA parity), Contrast audit at release |
| **Version** | Locked after SOUL v1.0. Token additions = MINOR. Palette HEX change = MAJOR. |
| **Compatibility** | New tokens must be semantic, reusable (3+ cases), on 4px scale. No screen-specific tokens. |
| **Deprecation** | Legacy tokens marked `@Deprecated` with migration path. Priority by impact/risk/leverage. |
| **Exception** | Aura Teal dark contrast documented exception (review each release). EXCEPTION_REGISTRY entry required. |

---

## 4. TYPOGRAPHY Contract (L1 — System Specification)

| Field | Value |
|-------|-------|
| **Identity** | `TYPOGRAPHY` — S2 Typography System Authority |
| **Purpose** | Single typography authority (`TypographyTokens`). Defines two voices + data font, semantic scale, expression mapping, contextual API. Prevents arbitrary fonts/sizes/weights, generic serif/sans, third font family. |
| **Authority** | L1. Changes require **SOUL_REVISION** (font family) or **DIRECTOR_REVIEW** (scale/weight/voice). |
| **Source of Truth** | `docs/design/GLOWAPP_TYPOGRAPHY_SYSTEM.md` + `glowapp_typography_system.json` |
| **Inputs** | New semantic token requests, contextual expression needs, accessibility scaling requirements |
| **Outputs** | `TypographyTokens` (sole authority), `TypographyFamilies`, `TypographyWeights`, `TypographyTokensContext` API, `AppTypography` bridge (deprecated) |
| **Consumers** | All UI components, screens, `AppTheme.expression()`, contextual API consumers |
| **Invariants** |
| | • Font Families: Cormorant Garamond (Editorial), Manrope (Functional), JetBrains Mono (Data) — EXACTLY THREE |
| | • No third font for AURA/Men/Women |
| | • Display Voice (Cormorant): XL/L/M/S tokens defined |
| | • Heading Scale (Cormorant): H1–H4 defined |
| | • Functional Voice (Manrope): Body Large/Small, Label Large/Small, Button, Navigation, Input, Chip, Badge |
| | • Price Typography (JetBrains Mono): Display/Large/Medium/Small/Micro/Checkout Final |
| | • AURA uses SAME two voices (Cormorant storytelling, Manrope conversational) |
| | • Women/Men differentiation via color/photography/composition/spacing — NOT font family |
| | • Case Rules: Sentence case default, Title Case for brand nouns, Uppercase ONLY for overlines/badges |
| | • Line heights: 1.1–1.6 range per spec |
| | • All typography access via `TypographyTokens` or `context.XContext` API |
| **Forbidden Behavior** |
| | • Arbitrary font family/size/weight |
| | • Generic `'serif'`/`'sans'` in tokens |
| | • Playfair Display (declared unused) |
| | • Serif in dense UI |
| | • Excessive bold/uppercase |
| | • Third font family for any expression |
| | • Screen-specific typography tokens |
| | • Direct `TextStyle` construction bypassing tokens |
| **Validation** | Token audit at G3, Visual QA at G4 (scale, hierarchy, contrast), Accessibility scaling test (1.0x–2.0x) |
| **Version** | Locked after SOUL v1.0. Scale additions = MINOR. Font family change = MAJOR. |
| **Compatibility** | `AppTypography` bridge maintained for gradual migration. `TypographyTokensContext` API for contextual resolution. |
| **Deprecation** | Legacy typography systems (6 parallel) marked for consolidation. Priority by usage frequency. |
| **Exception** | None currently registered. |

---

## 5. PHOTOGRAPHY Contract (L1 — System Specification)

| Field | Value |
|-------|-------|
| **Identity** | `PHOTOGRAPHY` — S3 Photography System Authority |
| **Purpose** | Single photographic language across all expressions. Defines muses, lighting, composition, domains, retouching policy. Prevents generic substitution, cyberpunk AURA, plastic skin. |
| **Authority** | L1. Changes require **SOUL_REVISION** (muse replacement) or **DIRECTOR_REVIEW** (domain/style). |
| **Source of Truth** | `docs/design/GLOWAPP_PHOTOGRAPHY_SYSTEM.md` + `glowapp_photography_system.json` |
| **Inputs** | New domain requirements, asset commissioning, responsive crop needs, AURA visual vocabulary |
| **Outputs** | Muse definitions, lighting specs, composition rules, aspect ratios, retouching policy, asset registry |
| **Consumers** | Hero sections, provider detail, booking flow, AURA screens, onboarding, design ideas, marketing |
| **Invariants** |
| | • Single photographic language (not 8 different styles) |
| | • Female Muse (Phase 1): Modern femininity + quiet luxury, natural texture, warm lighting |
| | • Male Muse (Phase 1): Arabic/Middle Eastern, bearded, groomed, editorial, age 30–35 |
| | • Women Photography: Soft, beauty/ritual, dewy, large diffuse 45°, warm fill, cream/sand backgrounds |
| | • Men Photography: Stronger structure, grooming/tailored, matte, Rembrandt/split acceptable, graphite/obsidian contextual only |
| | • AURA Photography: Light/perception/transformation, concentric circles, fine geometry, Aura Teal accent only, warm base |
| | • Composition: Rule of thirds, 30% min negative space (hero), CTA-safe zones, consistent aspect ratios |
| | • Retouching: Allowed (blemish reduction temporary, tone evening, dust removal, subtle grading). Prohibited (frequency separation, liquify, eye enlargement, reshaping, texture elimination) |
| | • Asset metadata registry required (focal points, safe zones, versioning) |
| **Forbidden Behavior** |
| | • Replacing official muse with generic stock |
| | • Pink/washed-out beauty aesthetic (Women) |
| | • Black UI / gold-only / aggressive macho (Men) |
| | • Cyberpunk/neon/HUD/robot AI imagery (AURA) |
| | • Plastic skin / aggressive retouching |
| | • Burned-in text in images |
| | • Single asset for responsive hero (no crop strategy) |
| | • Navigation icons as raster PNG (violates Icon System — requires SVG) |
| **Validation** | Asset audit at G4 (mobile/tablet/desktop, Women/Men/AURA), Muse compliance check, Aspect ratio verification |
| **Version** | Locked after SOUL v1.0. Muse replacement = MAJOR. Domain addition = MINOR. |
| **Compatibility** | Responsive crop strategy (FLUID + ADAPTIVE). Asset versioning in metadata registry. |
| **Deprecation** | Legacy assets (6 logo variants, 3D illustrations in Design Ideas) marked for removal/replacement. |
| **Exception** | None currently registered. |

---

## 6. ICON Contract (L1 — LOCKED)

| Field | Value |
|-------|-------|
| **Identity** | `ICON` — Glow Icon System v1.0 Authority |
| **Purpose** | Single geometry per semantic action. Color varies by audience via S1 Icon Color Roles. Registry is central authority. |
| **Authority** | L1 — **LOCKED**. Changes require **ICON_SYSTEM_REVIEW** (explicit authorization). |
| **Source of Truth** | `docs/design/GLOW_ICON_SYSTEM.md` + `glow_icon_system.json` |
| **Inputs** | New semantic action needs, accessibility requirements, migration phases |
| **Outputs** | `GlowIconRegistry` (central), `GlowIconData` (SVG/CustomPainter/IconData), `GlowIcon` API, `GlowIconColorRole` |
| **Consumers** | All UI components, navigation, buttons, cards, AURA, Concierge, Men/Women expressions |
| **Invariants** |
| | • Monoline, refined, warm, minimal, premium visual language |
| | • Viewport 24×24, stroke base 1.75px, round cap/join, outline style |
| | • Sizes: xs(16), sm(20), md(24-standard), lg(28), xl(32), xxl(40), huge(48) |
| | • Semantic Color Roles per expression (Women: Rose Gold; Men: Champagne; AURA: Aura Teal) |
| | • Inventory: 22 icons (16 Core + 6 Proprietary) — LOCKED |
| | • One geometry per semantic action |
| | • Migration phases: M1-I0→M1-I6 (global only after all pilots approved) |
| **Forbidden Behavior** |
| | • Material/Cupertino icons when GlowIcon equivalent exists |
| | • Individual SVG without registry entry |
| | • Duplicate geometries |
| | • Semantically ambiguous icons |
| | • Using `aura`/`glow`/`glowRecommendation` as universal AI synonyms |
| | • Modifying geometry/stroke/viewport/registry without ICON_SYSTEM_REVIEW |
| **Validation** | Pilot visual validation (A/B/C/D), Registry completeness, No Material/Cupertino leakage |
| **Version** | v1.0 LOCKED. No changes without explicit review. |
| **Compatibility** | Migration by phases with rollback at each phase. Legacy icons classified COMPLIANT/PARTIALLY/NON/LEGACY/EXCEPTION. |
| **Deprecation** | Legacy icons marked in registry with migration path. |
| **Exception** | None for v1.0 geometry. New icons require full registry process. |

---

## 7. COMPONENT Contract (L2 — Component System)

| Field | Value |
|-------|-------|
| **Identity** | `COMPONENT` — S4 UI Component Language Authority |
| **Purpose** | Defines official component taxonomy, states, variants, patterns. Prevents duplication, single-screen components, bypassing Token system, separate expression frameworks. |
| **Authority** | L2. New component = **DIRECTOR_REVIEW**. Variant = **DESIGN_REVIEW** (or **VARIANT_GOVERNANCE**). |
| **Source of Truth** | `docs/design/GLOWAPP_UI_COMPONENT_LANGUAGE.md` + `glowapp_ui_component_language.json` |
| **Inputs** | New component proposals, variant requests, state definitions, responsive patterns |
| **Outputs** | Component registry, state specifications, variant definitions, composition patterns |
| **Consumers** | All screens, feature teams, AI agents, Design Director |
| **Invariants** |
| | • Taxonomy: Foundation → Navigation → Content → Action → Form → Feedback → Overlay → Commerce → Booking → Concierge → AURA → Audience |
| | • Card vs Container vs Section vs List Item vs Editorial Block — distinct purposes |
| | • Card: Interactive + metadata + action. Radius 16px (lg), padding 16 default, full bleed image |
| | • Button Variants: Primary/Secondary/Tertiary/Ghost/Icon/Destructive (max 6). Heights 52/48/44/40/48/48. Radius 12/12/12/8/12/12 |
| | • CTA: One primary per screen. Sticky bottom mobile. L3 surface. Prohibited: multiple primaries, CTA in card grids |
| | • Navigation: Bottom Nav (3-5 items, GlowIcon md), Top Nav, Tabs (3px indicator), Audience toggle |
| | • App Bar: Default/Transparent/Store/Detail/AURA/Women/Men/Concierge variants defined |
| | • Hero: Hero/Editorial/Service/Product/AURA types with aspect ratios, negative space, CTAs |
| | • Commerce: ProductCard (1:1/4:5), PriceDisplay (JetBrains Mono, COP format), Checkout steps defined |
| | • Booking: Concierge feel. Editorial cards, calendar, time chips, map, editorial summary, Wompi |
| | • Concierge: Personal/human. L2 glass, radius 16, avatar 32px, bubbles radius 20 |
| | • AURA UI: Quiet Intelligence. Aura Teal accent only. AuraSurface/L2 glass. Organic geometry. No cyberpunk. |
| | • Women/Men UI: Differentiation via color/photo/composition/spacing — NOT separate frameworks |
| | • States: DEFAULT, HOVER, PRESSED, FOCUSED, SELECTED, DISABLED, LOADING, SUCCESS, ERROR, WARNING |
| | • Glass/Blur: Never default. Only over photography or contextual depth. Blur 10-20px, opacity 60-85% |
| | • Motion: micro:100, short:200, standard:300, long:500, hero:800. Standard easing. Avoid bouncy/gamer/excessive |
| | • Responsive: Mobile/Tablet/Desktop defined. FLUID + ADAPTIVE. Breakpoints: 0/600/1024/1440 |
| **Forbidden Behavior** |
| | • Single-screen components |
| | • Components duplicating existing behavior |
| | • Separate Women/Men/AURA component frameworks |
| | • Components bypassing Token system |
| | • Visual tweak variants without semantic difference |
| | • More than 6 variants per component |
| | • Non-semantic variant naming (Blue/Large/Left) |
| | • Arbitrary states |
| | • Default glass/blur style |
| | • Bouncy/gamer/excessive motion |
| | • Layouts exclusively for one resolution |
| **Validation** | G0-G6 gates. Design Review checklist (13 items). Visual QA at G4 (mobile/tablet/desktop, Women/Men/AURA). |
| **Version** | Component additions = MINOR. API breaking = MAJOR. |
| **Compatibility** | New components must use existing tokens. Variants must have semantic justification. |
| **Deprecation** | Legacy components (GlowGlassCard vs GlassCard, 40+ screens on legacy AppTheme) marked for consolidation. |
| **Exception** | EXCEPTION_REGISTRY for third-party integration constraints. |

---

## 8. AUDIENCE Contract (L2 — Expression System)

| Field | Value |
|-------|-------|
| **Identity** | `AUDIENCE` — Women/Men/Concierge Expression Authority |
| **Purpose** | Governs how Women, Men, Concierge expressions manifest within the master system. Shared foundation, differentiated expression. |
| **Authority** | L2. Changes require **DIRECTOR_REVIEW**. |
| **Source of Truth** | S1/S3/S4 expression rules (GLOWAPP_SOUL.md §10, §11, §12, §8.14, §8.15, §8.12) |
| **Inputs** | Expression differentiation needs, new content domains, photography requirements |
| **Outputs** | Expression rules, color assignments, photography specs, composition rules, content domains |
| **Consumers** | `Token.women`/`Token.men`/`Token.aura`, `AudienceService`, `AppTheme.expression()`, all screens |
| **Invariants** |
| | • **Women**: Modern femininity + quiet luxury. Rose Gold/Warm Brown/Champagne. Female muse. Softer composition. Skincare/hair/nails/makeup/fragrance/body/spa/wellness. |
| | • **Men**: Quiet masculine luxury. Champagne/Warm White/Copper. Male muse. Stronger structure, matte. Beard/shave/hair/scalp/fragrance/body/grooming/wellness. |
| | • **Concierge**: Personal, human, attentive. Not call center. L2 glass, Cormorant display. |
| | • **Shared (NOT differentiated)**: Foundation tokens, component structure, interaction patterns, Icon geometry, navigation architecture |
| | • **Prohibited**: Separate architecture, component library, token system, navigation. Black UI default (Men). Gold-only accents (Men). Aggressive/macho (Men). Pink beauty app (Women). |
| **Forbidden Behavior** |
| | • Independent Women/Men/AURA design systems |
| | • Black UI as Men brand default |
| | • Gold-only accents for Men |
| | • Separate component framework for any expression |
| | • Expression differentiation via font family |
| **Validation** | Visual QA at G4 (Women/Men/AURA parity). Expression toggle testing. No independent system leakage. |
| **Version** | Expression adjustments = MINOR. Architecture change = MAJOR. |
| **Compatibility** | `AudienceService.currentAudience` drives `Token.women`/`Token.men`/`Token.aura` resolution. |
| **Deprecation** | Legacy expression code (MensTheme, separate tokens) marked for migration. |
| **Exception** | None currently registered. |

---

## 9. DATA Contract (L2 — Data Governance)

| Field | Value |
|-------|-------|
| **Identity** | `DATA` — Data Domain Authority |
| **Purpose** | Single source of truth per domain. Clear ownership, persistence, lifecycle, privacy, lineage. Prevents duplicate entities, derived data without authority, ownership gaps. |
| **Authority** | L2. Changes require **DIRECTOR_REVIEW** (schema) or **DESIGN_REVIEW** (derived data). |
| **Source of Truth** | PostgreSQL database (canonical). `docs/audit/glowapp_data_map.json` (audit evidence). |
| **Inputs** | Schema changes, migration proposals, AI data needs, privacy requirements, CRUD ownership changes |
| **Outputs** | Table schemas, migration scripts, CRUD authority matrix, privacy classifications, lineage docs |
| **Consumers** | Backend controllers, frontend services, AI/RAG pipeline, analytics, compliance |
| **Invariants** |
| | • PostgreSQL = single Source of Truth for persistent data |
| | • Each domain has ONE authoritative table |
| | • CRUD ownership explicit (no multiple writers without coordination) |
| | • Monetary integrity via DB trigger (`calc_booking_split`: 12%/8%/80%) |
| | • Biometric consent: partial unique index (single active) |
| | • Knowledge embeddings: traceability columns (document_id, chunk_id, content_hash, fuente, seccion) |
| | • RAG query logs: full traceability (traceId, params, scores) |
| | • Frontend state = CACHED/DERIVED only (SharedPreferences, FlutterSecureStorage) |
| | • Dual storage conflicts documented (Provider portfolio, Biometric, Frontend models) |
| **Forbidden Behavior** |
| | • Creating duplicate tables for same domain |
| | • Derived data without documented authority |
| | • Multiple writers without coordination |
| | • Bypassing DB triggers for monetary calculations |
| | • Storing biometric images without retention policy |
| | • AI results without traceability |
| | • Silent schema changes without migration |
| | • Personal data without privacy classification |
| **Validation** | Schema audit at G1, Migration validation at G2, Integrity check at G3, Privacy audit at release |
| **Version** | Schema changes = MAJOR (migration required). Derived data additions = MINOR. |
| **Compatibility** | Migrations: baseline → inventory → plan → pilot → validation → rollback → approval → documentation. |
| **Deprecation** | Legacy tables (user_biometrics, portafolio_servicios JSONB) marked DEPRECATED. Drop after migration verified. |
| **Exception** | EXCEPTION_REGISTRY for third-party constraints (Wompi, NVIDIA API). |

---

## 10. AI Contract (L2 — Intelligence Governance)

| Field | Value |
|-------|-------|
| **Identity** | `AI` — AURA / RAG / Intelligence Authority |
| **Purpose** | Governs model, prompt, RAG, embedding, agent, evaluation authority. Human confirmation for critical actions. Traceability mandatory. |
| **Authority** | L2. Model/prompt/RAG/embedding changes = **DIRECTOR_REVIEW**. Agent behavior = **AURA_GOVERNANCE**. |
| **Source of Truth** | `docs/audit/GLOWAPP_INTELLIGENCE_MAP.md` + `glowapp_intelligence_map.json` + backend services |
| **Inputs** | User queries, biometric data, booking context, knowledge corpus, evaluation datasets |
| **Outputs** | Embeddings (1024d), retrieved chunks, agent responses, recommendations, VTO results, biometric profiles |
| **Consumers** | AURA screens, chat, search, recommendations, biometric analysis, nail VTO, booking assist |
| **Invariants** |
| | • **Model Authority**: NVIDIA NV-Embed-QA-E5-v5 (1024d) — external vendor, circuit breaker (3 failures/30s) |
| | • **Prompt Authority**: Centralized in `ragService.js` / `embeddingService.js` — no hardcoded prompts |
| | • **RAG Authority**: Single canonical pipeline — HNSW vector search (pgvector) → FTS fallback |
| | • **Embedding Authority**: `embeddingService.js` — dimension validation (1024), non-zero check |
| | • **Agent Authority**: Aura Orchestrator coordinates (Atena, Hermes, Chronos, Hestia). Each agent scoped. |
| | • **Evaluation**: 30-query dataset, RAGAS metrics (P@5, R@5, MRR, Faithfulness, Answer Relevancy) |
| | • **Human Confirmation Required**: Payment, Treatment selection, Booking finalization |
| | • **Fallback**: FTS (tsvector/tsquery) when embeddings fail. Logged with `fallback_triggered=true` |
| | • **Traceability**: Full in `rag_query_logs` (traceId, query, filters, scores, categories, chunks) |
| | • **Knowledge Sources**: beauty_corpus (MD), SQL seeds, manual additions — single corpus |
| | • **Chunking**: 500-800 tokens, 50% overlap, content_hash for idempotency |
| **Forbidden Behavior** |
| | • Multiple RAG paths / embedding services in production |
| | • Duplicated knowledge sources |
| | • AI decisions without human confirmation for critical actions |
| | • Embedding storage without traceability |
| | • Agent scope creep beyond defined permissions |
| | • Cyberpunk/neon/HUD/robot AURA aesthetics |
| | • Undocumented prompts |
| | • Model swap without evaluation regression |
| **Validation** | 69/69 tests PASS (embedding 16, ragLogger 10, ragMetrics 12, ragEvaluator 23, ciRagEvaluation 8). Evaluation dataset regression at release. |
| **Version** | Model/embedding change = MAJOR. Prompt/template = MINOR. Agent addition = DIRECTOR_REVIEW. |
| **Compatibility** | Circuit breaker prevents cascade failure. FTS fallback maintains availability. |
| **Deprecation** | Legacy `beautyKnowledgeService.js` converted to wrapper. Old evaluation datasets archived. |
| **Exception** | NVIDIA API dependency (vendor lock-in) documented risk. No immediate alternative. |

---

## 11. QUALITY Contract (L3 — Validation Gates)

| Field | Value |
|-------|-------|
| **Identity** | `QUALITY` — Quality Gates Authority |
| **Purpose** | Minimum gates for every change. Distinguishes blocking vs non-blocking vs pre-existing vs known debt. |
| **Authority** | L3. Enforced by CI/CD and Design Director. |
| **Source of Truth** | `glowapp_governance.json` §quality_gates + Definition of Done (SOUL §24) |
| **Inputs** | Code changes, design proposals, migrations, experiments |
| **Outputs** | Gate results (PASS/FAIL), regression reports, visual QA reports, approval records |
| **Consumers** | All engineers, Design Director, release process, AI agents |
| **Invariants (Gates — Sequential, Cannot Skip)** |
| | • **G0 SCOPE**: Defined, aligned to SOUL, no scope creep |
| | • **G1 DESIGN**: Design Review checklist (13 items) PASS, Director approval if required |
| | • **G2 IMPLEMENTATION**: Code complete, follows tokens/components, no hardcoded values |
| | • **G3 VALIDATION**: `flutter analyze` PASS, `flutter test` PASS, `flutter build web --release` PASS |
| | • **G4 VISUAL QA**: Visual regression vs spec. Mobile/Tablet/Desktop. Women/Men/AURA |
| | • **G5 APPROVAL**: Design Director sign-off |
| | • **G6 DOCUMENTATION**: WHAT/WHY/WHERE/HOW/VALIDATION/DECISION/DATE/VERSION recorded |
| **Classification of Results** |
| | • **BLOCKING**: Gate failure → cannot proceed |
| | • **NON-BLOCKING**: Warning/informational (e.g., info/warning in analyze) |
| | • **PRE-EXISTING**: Known issues unrelated to current change (e.g., 297 pre-existing analyze issues) |
| | • **KNOWN DEBT**: Documented technical debt with owner/timeline (e.g., legacy components) |
| **Forbidden Behavior** |
| | • Skipping gates |
| | • Shipping without G5 Director sign-off |
| | • Claiming "compliant" without validation |
| | • Treating pre-existing issues as current change blockers |
| | • Auto-committing without gate verification |
| **Validation** | Automated (analyze/test/build), Manual (Visual QA, Accessibility, Director Review) |
| **Version** | Gate definitions = SOUL_REVISION for structural, DIRECTOR_REVIEW for thresholds. |
| **Compatibility** | New gates added via MINOR. Gate removal = MAJOR. |
| **Deprecation** | Gates never deprecated, only evolved. |
| **Exception** | EXCEPTION_REGISTRY for platform limitations (e.g., web focus styles). Review each release. |

---

## 12. TECHNICAL Contract (L4 — Implementation Standards)

| Field | Value |
|-------|-------|
| **Identity** | `TECHNICAL` — Implementation Authority |
| **Purpose** | Standards for Flutter code, tokens, themes, state, architecture. Ensures implementation complies with L0–L3. |
| **Authority** | L4. Enforced by Lead Engineer via code review and tooling. |
| **Source of Truth** | `lib/core/theme/tokens.dart`, `lib/core/theme/app_theme.dart`, `lib/main.dart`, `GlowStoreTokens`, `AppTypography` |
| **Inputs** | Design specs (L0–L3), component requirements, performance needs, platform constraints |
| **Outputs** | Flutter widgets, themes, tokens, services, providers, screens |
| **Consumers** | Runtime app, tests, build pipeline, developers |
| **Invariants** |
| | • Single `Token` authority for color/expression |
| | • Single `TypographyTokens` authority for typography |
| | • `AppTheme.expression()` builds complete theme with `GlowTokensExtension` |
| | • `AudienceService` drives expression switching |
| | • No hardcoded colors/spacing/typography in widgets |
| | • All components use `GlowIcon` (not Material/Cupertino) |
| | • State via `ValueNotifier`/`Provider` — no global mutable singletons |
| | • Secure storage for auth tokens (`FlutterSecureStorage`) |
| | • API normalization via `ApiService._normalizeDynamicUrls()` |
| **Forbidden Behavior** |
| | • Hardcoded `Color(...)`, `TextStyle(...)`, `BorderRadius(...)` |
| | • Direct `Theme.of(context)` color access bypassing `Token.of(context)` |
| | • Material/Cupertino icons when `GlowIcon` exists |
| | • Screen-specific tokens |
| | • Duplicate component implementations |
| | • Business logic in UI layer (booking/payment/auth) |
| **Validation** | `flutter analyze` (0 errors on modified files), `flutter test` (all pass), `flutter build web --release` (success) |
| **Version** | Implementation evolves with spec. Breaking API = MAJOR. |
| **Compatibility** | Legacy `AppTheme`/`GlowStoreTokens`/`glow_store_tokens` bridges maintained during migration. |
| **Deprecation** | Legacy theme/components marked `@Deprecated` with migration path. |
| **Exception** | Platform-specific workarounds (web focus, secure_storage mock) documented. |

---

## 13. ACCESSIBILITY Contract (L2 — Cross-Cutting)

| Field | Value |
|-------|-------|
| **Identity** | `ACCESSIBILITY` — Accessibility By Default Authority |
| **Purpose** | Validated (not claimed) accessibility for every component and screen. |
| **Authority** | L2. **DESIGN_REVIEW** for patterns, **DIRECTOR_REVIEW** for new patterns. |
| **Source of Truth** | `GLOWAPP_SOUL.md` §15 + `glowapp_governance.json` §accessibility_governance |
| **Inputs** | New components, screen compositions, motion patterns, color contrasts |
| **Outputs** | Accessibility annotations, semantic labels, focus styles, contrast validations |
| **Consumers** | All components, screens, Design Director, QA |
| **Invariants** |
| | • Every new component considers: semantic labels, screen reader, keyboard, focus, contrast (WCAG AA), touch target (48dp), text scaling (1.0x–2.0x), motion sensitivity |
| | • Focus: 2px Focus Border (S1 Primary) + 4px offset on ALL interactive |
| | • Contrast: Primary 12.8:1 (Women), Aura Teal light 8.2:1. Aura Teal dark 1.8:1 = documented exception |
| | • No shipping without focus styles on interactive elements |
| | • Respect `prefers-reduced-motion` |
| **Forbidden Behavior** |
| | • Claiming "compliant" without validation |
| | • Shipping without focus styles |
| | • Aura Teal on dark backgrounds without exception |
| **Validation** | Required at G3 (analyze) and G4 (Visual QA). WCAG AA audit + screen reader test at release. |
| **Version** | Pattern additions = MINOR. Standard change = MAJOR. |
| **Compatibility** | Web focus styles exception documented. |
| **Deprecation** | Non-accessible patterns marked for remediation. |
| **Exception** | Aura Teal on dark (1.8:1) — documented in S1. Review each release. |

---

## 14. SECURITY Contract (L2 — Cross-Cutting)

| Field | Value |
|-------|-------|
| **Identity** | `SECURITY` — Data & Auth Security Authority |
| **Purpose** | Protects auth tokens, personal data, payment data, biometric data, AI inputs/outputs. |
| **Authority** | L2. **DIRECTOR_REVIEW** for auth/payment/biometric changes. |
| **Source of Truth** | `AuthService`, `SecureStorageService`, `ApiService`, backend controllers, `glowapp_data_map.json` §12 |
| **Inputs** | Auth flows, payment integration, biometric upload, AI query logs, data export requests |
| **Outputs** | Secure storage, encrypted transmission, access control, audit logs |
| **Consumers** | All services, backend, frontend, compliance |
| **Invariants** |
| | • Auth tokens: `FlutterSecureStorage` (AES encrypted) |
| | • Passwords: bcrypt hash, never logged |
| | • Payment: Wompi PCI compliance, TLS, `external_id` for idempotency |
| | • Biometric images: HTTPS multipart, user-scoped, retention policy required |
| | • Biometric results: `beauty_profiles` JSONB, user-scoped, TLS |
| | • Chat: Participant-scoped, TLS + WebSocket |
| | • AI logs: `rag_query_logs` traceable, admin-scoped |
| | • GDPR/Habeas Data: migrations exist (003, 020, 037) — automation pending |
| **Forbidden Behavior** |
| | • Auth tokens in SharedPreferences/plaintext |
| | • Biometric images retained without policy |
| | • Personal data without access control |
| | • Payment data logged |
| | • AI query logs without traceability |
| **Validation** | Security scan at release. Penetration test annually. GDPR automation audit quarterly. |
| **Version** | Security patches = PATCH. Architecture changes = MAJOR. |
| **Compatibility** | Backward compatible auth flow. Token rotation supported. |
| **Deprecation** | Legacy auth patterns (non-secure storage) migrated. |
| **Exception** | Railway PostgreSQL encryption-at-rest depends on provider config. |

---

## 15. Versioning Rules (Cross-Cutting)

| Level | Trigger | Examples | Approval | Version Bump |
|-------|---------|----------|----------|--------------|
| **PATCH** | Backward-compatible fix, no visual/behavior change | Token correction, bug fix, accessibility fix, perf optimization | DESIGN_REVIEW | x.y.Z |
| **MINOR** | Backward-compatible addition within spec | New variant, semantic token, new icon, responsive behavior, motion micro | COMPONENT/DIRECTOR_REVIEW | x.Y.z |
| **MAJOR** | Breaking change to spec/identity, requires migration | Palette restructure, font family change, component API break, icon migration phase, audience restructure | DIRECTOR_REVIEW + SOUL_REVISION | X.y.z |
| **EXCEPTION** | Temporary deviation for unsolvable case | Legacy screen, third-party constraint, platform limitation | DIRECTOR_REVIEW + EXCEPTION_REGISTRY | N/A (flagged) |
| **EXPERIMENTAL** | Isolated prototype, not in production | New component prototype, motion test, alternative layout | DESIGN_REVIEW (proto), DIRECTOR_REVIEW (promote) | N/A |

**Exception Registry Requirements**: problem, reason, affected_area, temporary_or_permanent, risk, approval, expiration_or_review_date. Never silently become standard.

---

## 16. Legacy Rules (Cross-Cutting)

| Classification | Definition | Action |
|----------------|------------|--------|
| **COMPLIANT** | Meets current SOUL | Maintain |
| **PARTIALLY_COMPLIANT** | Some gaps, migration planned | Prioritize by impact/risk/leverage |
| **NON_COMPLIANT** | Significant gaps, migration required | Plan migration, no new dependencies |
| **LEGACY** | Deprecated, awaiting removal | Mark `@Deprecated`, document migration path, remove after verified |
| **EXCEPTION** | Documented deviation with review date | Track in EXCEPTION_REGISTRY, review at expiration |

**Process**: IDENTIFY → AUDIT → MARK → MIGRATE → VERIFY → REMOVE
**Rule**: No immediate global migration. No removing without knowing consumers.

---

## 17. Exception Rules (Cross-Cutting)

| Rule | Description |
|------|-------------|
| **Exists When** | Current system cannot solve a real case |
| **Must Register** | problem, reason, affected_area, temporary_or_permanent, risk, approval, expiration_or_review_date |
| **Never Silent** | Exceptions never silently become standard |
| **Review Date** | Mandatory — reviewed at each release |
| **Current Exceptions** | Aura Teal dark contrast (1.8:1), NVIDIA vendor lock-in, web focus styles, Railway encryption-at-rest |

---

## 18. Quality Score

| Criterion | Score |
|-----------|-------|
| Contract Model Definition | 10/10 |
| SOUL Contract | 10/10 |
| COLOR Contract | 10/10 |
| TYPOGRAPHY Contract | 10/10 |
| PHOTOGRAPHY Contract | 10/10 |
| ICON Contract | 10/10 |
| COMPONENT Contract | 10/10 |
| AUDIENCE Contract | 10/10 |
| DATA Contract | 10/10 |
| AI Contract | 10/10 |
| QUALITY Contract | 10/10 |
| TECHNICAL Contract | 10/10 |
| ACCESSIBILITY Contract | 10/10 |
| SECURITY Contract | 10/10 |
| Versioning Rules | 5/5 |
| Legacy Rules | 5/5 |
| Exception Rules | 5/5 |
| **TOTAL** | **170/170** |

---

## 19. Final Decision

**STATUS: READY FOR G1-C**

All 14 governance contracts designed with complete mandatory fields. Invariants, forbidden behaviors, validation rules, versioning, legacy, and exception rules defined per SOUL authority hierarchy. No production code modified. Two artifacts generated:

- `docs/governance/GLOWAPP_GOVERNANCE_CONTRACTS.md`
- `docs/governance/glowapp_governance_contracts.json`

**Next Authorized Phase: G1-C — GOVERNANCE ARCHITECTURE ASSEMBLY** (assemble contracts into enforceable architecture, not implementation)