# GLOWAPP SOUL v1.0

## 1. Identity

**GlowApp** is a premium beauty & grooming platform that unifies **Women**, **Men**, **AURA**, and **Concierge** into a single coherent experience.

**Identity Statement**: Quiet luxury that feels human. Editorial beauty that serves function. Intelligence that stays warm.

**Not**: A pink beauty app. A black/gold men's app. A cyberpunk AI interface. A generic ecommerce template. A dashboard. A corporate tool.

---

## 2. Philosophy

| Pillar | Expression |
|--------|------------|
| **QUIET LUXURY** | Restraint over excess. Every element earns its place. Visual silence is a feature. |
| **HUMAN EXPERIENCE** | Warmth, anticipation, tactile quality. Not sterile efficiency. |
| **EDITORIAL BEAUTY** | Asymmetry, negative space, typography as design, photography as lead. |
| **INTELLIGENT SIMPLICITY** | Complexity hidden. Clarity revealed progressively. |
| **PREMIUM RESTRAINT** | Less is more. No excess, no clutter, no loud statements. |
| **HUMAN AUTHENTICITY** | Real skin texture, natural movement, genuine moments over plastic perfection. |

---

## 3. Core Principles

1. **One Brand, Multiple Expressions** — Women, Men, AURA, Concierge are expressions of one system, not separate brands
2. **Photography Leads** — Color, typography, UI serve imagery; never compete
3. **Two Voices, Not Three** — Cormorant Garamond (editorial) + Manrope (functional) + JetBrains Mono (data). No third font for AURA/Men/Women
4. **Surface Before Decoration** — Hierarchy through elevation/texture, not color noise
5. **AURA Is an Intelligence Layer** — Not a visual theme. Appears only when intelligence is relevant. Aura Teal = accent only
6. **Accessibility By Default** — Not claimed, validated
7. **Governance Over Preference** — Changes follow process, not impulse

---

## 4. Authority Hierarchy

```
GLOWAPP SOUL (L0 — Master Authority)
      ↓
S1 COLOR SYSTEM (L1)
S2 TYPOGRAPHY SYSTEM (L1)
S3 PHOTOGRAPHY SYSTEM (L1)
S4 UI / COMPONENT LANGUAGE (L2)
GLOW ICON SYSTEM v1.0 (L1 — LOCKED)
S5 GOVERNANCE (L0 — Self-governing)
      ↓
SCREEN COMPOSITION (L3)
      ↓
IMPLEMENTATION (L4)
      ↓
EXPERIMENTAL (L5 — Isolated, non-shipping)
```

**Rule**: A lower level CANNOT silently contradict a higher level. Conflicts must be escalated via Conflict Resolution process.

---

## 5. Color System

### 5.1 Authority
**Source**: `GLOWAPP_COLOR_SYSTEM.md` + `glowapp_color_system.json` (L1)

### 5.2 Master Palette

| Role | Women | Men | AURA | Shared |
|------|-------|-----|------|--------|
| **Primary** | Rose Gold `#D4AF7A` | Champagne Gold `#D4AF37` | Aura Teal `#164C46` | — |
| **Secondary** | Warm Brown `#5A3A2A` | Warm White `#F2EFEA` | — | — |
| **Tertiary** | Champagne `#D9A27F` | Copper `#B8734A` | — | — |
| **Background (L0)** | Cream Silk `#FCF8F6` | Obsidian `#0A0C10` | Context-aware | — |
| **Surface (L1)** | White `#FFFFFF` | Graphite `#1C1F23` | Cream/White | — |
| **Glass (L2)** | Cream 85% + blur | Graphite 85% + blur | Warm White 85% + blur | — |
| **CTA (L3)** | Rose Gold `#D4AF7A` | Champagne `#C8B08A` | Aura Teal `#164C46` | — |

### 5.3 Neutral Scale (Shared, Warm)
`nude50` `#FAF8F5` → `nude100` `#F5F0EA` → `nude200` `#E8DFD4` → `nude300` `#D4C8B8` → `nude400` `#B8A898` → `nude500` `#9E8C78` → `nude600` `#857360` → `nude700` `#6B5E50` → `nude800` `#5A4D40` → `nude900` `#3A342E`

### 5.4 Semantic States (Muted to Glow Warmth)
- **Success**: `#059669` (fg), muted bg/border/icon
- **Warning**: `#D97706` (fg), muted bg/border/icon
- **Error**: `#DC2626` (fg), muted bg/border/icon
- **Info**: `#0284C7` (fg), muted bg/border/icon
- **In Progress**: Brand primary, muted variants

### 5.5 Gradients (Purposeful Only)
| Gradient | Colors | Purpose |
|----------|--------|---------|
| Premium Light | `#CFBEB5` → `#CFBEB5` → `#FFF8F0` | Hero, onboarding |
| Premium Dark | `#4A3E3D` → `#4A3E3D` → `#2D2523` | Dark mode heroes |
| Rose Gold Satin | `#E8B6AD` → `#B57E74` | Women premium |
| Primary Gold | `#C5A052` → `#B89040` | Brand CTAs |
| Gold Gradient Men | `#D4AF37` → `#AA7C11` | Men CTAs |
| Obsidian Glass | `#CC14171F` → `#E60A0C10` | Men glass |
| AURA Gradient | `#164C46` → `#0D3630` | AURA intelligence |
| Scrim Bottom | Transparent → `#2B242059` | Photo legibility |

### 5.6 Shadows (Warm, Not Black)
- **Soft**: `nude900` 8%, blur 8, offset 0,2
- **Medium**: `nude900` 12%, blur 16, offset 0,6
- **Strong**: `nude900` 16%, blur 24, offset 0,12
- **Aura Glow**: Aura Teal 25%, blur 20, offset 0,8
- **Brand Glow**: Primary 20%, blur 16, offset 0,6

### 5.7 Prohibited
- `#00E5FF` (Cyber Cyan) — DEPRECATED, replace with Aura Teal
- `#000000` as brand background — only shadow base
- `#FFFFFF` as brand identity — use Cream Silk / warm whites
- Hardcoded brand colors, duplicated palettes, screen-specific brand colors

---

## 6. Typography System

### 6.1 Authority
**Source**: `GLOWAPP_TYPOGRAPHY_SYSTEM.md` + `glowapp_typography_system.json` (L1)

### 6.2 Font Families (Two Voices + Data)

| Voice | Family | Role | Status |
|-------|--------|------|--------|
| **EDITORIAL** | **Cormorant Garamond** | Display, headlines, storytelling, brand moments | Declared, NOT USED in production |
| **FUNCTIONAL** | **Manrope** | All UI: nav, buttons, forms, body, labels, prices, AURA UI | Target — NOT DECLARED in code |
| **DATA / METADATA** | **JetBrains Mono** | Prices, SKUs, technical metadata, monetary values | Declared, used, NOT in pubspec |

**Transitional (Phase Out)**:
- Didot → Cormorant Garamond
- Inter → Manrope
- Playfair Display → Remove

### 6.3 Display Voice (Cormorant Garamond)

| Token | Size | Weight | Line Height | Letter Spacing | Case | Purpose |
|-------|------|--------|-------------|----------------|------|---------|
| Display XL | 48 | 300 | 1.1 | -1.0 | Sentence | Hero headlines, splash |
| Display L | 40 | 300 | 1.15 | -0.8 | Sentence | Page heroes, campaigns |
| Display M | 32 | 400 | 1.2 | -0.5 | Sentence | Section heroes, modals |
| Display S | 26 | 500 | 1.25 | -0.3 | Sentence | Card headlines, editorial |

### 6.4 Heading Scale (Cormorant Garamond)

| Token | Size | Weight | Line Height | Letter Spacing | Case |
|-------|------|--------|-------------|----------------|------|
| H1 | 28 | 600 | 1.25 | -0.5 | Sentence |
| H2 | 22 | 600 | 1.3 | -0.3 | Sentence |
| H3 | 18 | 600 | 1.35 | -0.2 | Sentence |
| H4 | 16 | 600 | 1.4 | 0 | Sentence |

### 6.5 Functional Voice (Manrope)

| Token | Size | Weight | Line Height | Letter Spacing | Case | Purpose |
|-------|------|--------|-------------|----------------|------|---------|
| Body Large | 16 | 400 | 1.6 | 0 | Sentence | Primary reading |
| Body | 14 | 400 | 1.55 | 0.1 | Sentence | Standard UI |
| Body Small | 12 | 400 | 1.5 | 0.2 | Sentence | Metadata, captions |
| Label Large | 14 | 600 | 1.4 | 0.1 | Sentence | Primary buttons, tabs |
| Label Medium | 12 | 600 | 1.4 | 0.5 | Sentence | Chips, badges, selectors |
| Label Small | 10 | 600 | 1.3 | 0.8 | **Uppercase** | Overlines, status |
| Button Primary | 16 | 600 | 1.3 | 0.2 | Sentence | Primary CTA |
| Button Secondary | 14 | 600 | 1.3 | 0.2 | Sentence | Secondary buttons |
| Navigation | 13 | 500 | 1.4 | 0.3 | Sentence | Bottom nav, drawer |
| Input | 16 | 400 | 1.5 | 0 | Sentence | Text field input |
| Chip | 12 | 500 | 1.4 | 0.3 | Sentence | Filter chips |
| Badge | 10 | 600 | 1.3 | 0.5 | Uppercase | Notifications |

### 6.6 Price Typography (JetBrains Mono)

| Token | Size | Weight | Purpose |
|-------|------|--------|---------|
| Price Display | 24 | 700 | Primary price, checkout totals |
| Price Large | 20 | 700 | Hero products, cart summary |
| Price Medium | 16 | 600 | Product lists, service cards |
| Price Small | 13 | 600 | Previous price, unit price |
| Price Micro | 11 | 500 | Fee breakdowns, tax lines |
| Checkout Final | 22 | 700 | **Monetary integrity: single finalCheckoutAmount** |

### 6.7 AURA Typography (Same Two Voices)

| Token | Family | Size | Weight | Color | Purpose |
|-------|--------|------|--------|-------|---------|
| AURA Display | Cormorant | 28 | 400 | Aura Teal | Welcome, results revelation |
| AURA Headline | Cormorant | 20 | 600 | Aura Teal | Section headers |
| AURA Body | Manrope | 14 | 400 | Primary | Explanations, insights |
| AURA Label | Manrope | 12 | 600 | Aura Teal | Chips, confidence tags |
| AURA Price | JetBrains | 16 | 700 | Accent | Recommended prices |
| AURA CTA | Manrope | 16 | 600 | On Aura Primary | AURA actions |
| Concierge Message | Manrope | 14 | 400 | Primary | Conversational AI (1.7 line height) |

### 6.8 Women / Men Differentiation
**SAME two-voice architecture**. Differentiation via: color, photography, composition, spacing, iconography — NOT font family.

| Expression | Editorial Voice | Functional Voice |
|------------|-----------------|------------------|
| Women | Cormorant, warmer tracking, Rose Gold/Champagne accents | Manrope, warm brown text on cream |
| Men | Cormorant, tighter tracking, warm white on obsidian | Manrope, warm white on dark surfaces |
| AURA | Cormorant for storytelling, Aura Teal accents | Manrope for conversational UI |

### 6.9 Case Rules
- **Sentence case**: Default for ALL body, headings, buttons, labels, UI text
- **Title Case**: Brand proper nouns, screen titles in navigation, proper names
- **Uppercase**: ONLY overlines, category labels, badge text, metadata codes (≥0.5px letter-spacing)
- **Prohibited**: ALL CAPS for body, buttons, headings, paragraphs, form labels, errors

### 6.10 Critical Gaps (From S2 Audit)
1. No fonts in `pubspec.yaml` — all 3 target families missing
2. Cormorant Garamond declared but NEVER USED
3. Manrope NOT DECLARED in codebase
4. 6 parallel typography systems must consolidate
5. AuraWelcomeScreen doesn't adapt to Men
6. Generic `'serif'`/`'sans'` in AppTypography defeats token purpose

---

## 7. Photography System

### 7.1 Authority
**Source**: `GLOWAPP_PHOTOGRAPHY_SYSTEM.md` + `glowapp_photography_system.json` (L1)

### 7.2 Philosophy
Single photographic language across all expressions. Editorial over commercial. Soft premium depth. Premium restraint. Human authenticity. Composition consistency. Brand warmth.

### 7.3 Official Muses (LOCKED After SOUL v1.0)

| Muse | Status | Characteristics |
|------|--------|-----------------|
| **Female Muse (Phase 1)** | APPROVED | Modern femininity + quiet luxury. Not pink beauty app. Natural texture, warm lighting |
| **Male Muse (Phase 1)** | APPROVED | Arabic/Middle Eastern, bearded, groomed, editorial presence, age 30–35. Quiet masculine luxury |

### 7.4 Women Photography
- **Expression**: Softer, beauty/ritual focus, dewy finish
- **Palette**: Rose Gold, Champagne, Warm Brown, Cream
- **Lighting**: Large diffuse, 45°, 2–3m, warm fill (1:2 ratio), 5200–5600K
- **Background**: Warm neutrals (cream/sand), never solid white/black
- **Skin**: Natural texture at 100% zoom — pores, vellus hair visible. No plastic skin

### 7.5 Men Photography
- **Expression**: Stronger structure, grooming/tailored, matte finish
- **Palette**: Champagne, Warm White, Copper, Warm Stone, Taupe
- **Lighting**: Slightly harder key for structure, Rembrandt/split acceptable, warm fill (1:3), 5000–5400K
- **Background**: Dark neutral (graphite/obsidian) CONTEXTUAL ONLY, warm neutrals, editorial environmental
- **Prohibited**: Solid black as brand default, aggressive macho, generic barbershop tropes, fitness aesthetic, cyberpunk

### 7.6 AURA Photography
**Visual Vocabulary**: Light, perception, transformation, intelligence, human context, abstract organic forms
- **Concentric circles, fine geometry, points, sparkles** — perception/intelligence
- **Light rays through fabric/skin** — transformation
- **Organic gradients, not hard edges**
- **Aura Teal as accent only, never flood**
- **Warm white/cream as base, not dark mode**

| Use Photography | Use Abstract |
|-----------------|--------------|
| AURA Welcome: human experiencing transformation | Color DNA visualization |
| Results revelation: model seeing analysis | Product recommendation algorithm |
| Concierge AURA: human advisor + light geometry | Scanner/analysis processing states |
| Onboarding: human beginning journey | Background ambience (halos, geometry) |

**Prohibited**: Cyberpunk cyan, neon/circuit/robot imagery, generic AI brain, dark mode default, AURA on every screen

### 7.7 Beauty Domains (Women) — Unified Language
Skincare, Hair, Nails, Makeup, Fragrance, Body, Spa, Wellness — all follow same photographic principles, differentiated by subject/mood/lighting.

### 7.8 Men Photographic Domains
Beard, Shave, Hair, Scalp, Fragrance, Body, Grooming, Wellness — Quiet masculine luxury throughout.

### 7.9 Composition System
- **Rule of thirds** for subject placement
- **Text-safe zones** designed in (min 30% frame negative space)
- **CTA-safe zones** (bottom 15%) kept clear in hero
- **Consistent aspect ratios** per component type
- **No accidental crops**: eyes, face, hands, key product

| Type | Aspect | Negative Space | Use |
|------|--------|----------------|-----|
| PORTRAIT | 3:4, 4:5 | 30% min | Hero, profile, editorial |
| HALF_BODY | 3:4, 4:5 | 25% | Ritual, grooming |
| DETAIL | 1:1, 4:5 | Minimal | Product, texture, skin |
| ENVIRONMENTAL | 16:9, 3:2 | Architectural | Service context, location |
| PRODUCT | 1:1, 4:5 | 20% clean | Store, shelf |

### 7.10 Retouching Policy
**Allowed**: Blemish reduction (temporary), tone evening (not freckles/moles), dust removal, background cleanup, subtle color grading
**Prohibited**: Frequency separation blurring, liquify reshaping, eye enlargement, nose/jaw reshaping, skin texture elimination, teeth whitening beyond natural

### 7.11 Critical Gaps (From S3 Audit)
1. **NO MALE MUSE ASSETS (P0)** — 0% photography coverage for Men
2. **FEMALE MUSE NOT SYSTEMATIZED (P0)** — Candidates exist but not registered
3. **AURA WELCOME NOT MEN-ADAPTIVE (P0)** — Uses only female-model tokens
4. **DESIGN IDEAS = 3D ILLUSTRATIONS (P1)** — 5 assets break photographic unity
5. **ONBOARDING INCONSISTENT (P1)** — Single generic asset, no Men variant
6. **AUTH BACKGROUNDS GENERIC (P1)** — Stock feel, not official muse
7. **NAVIGATION ICONS ARE RASTER (P1)** — Violates locked Icon System (requires SVG)
8. **NO ASSET METADATA REGISTRY (P1)** — No focal points, safe zones, versioning
9. **NO RESPONSIVE CROP STRATEGY (P1)** — Hero images hardcoded single asset

---

## 8. UI / Component Language

### 8.1 Authority
**Source**: `GLOWAPP_UI_COMPONENT_LANGUAGE.md` + `glowapp_ui_component_language.json` (L2)

### 8.2 Foundation Tokens (Source: `tokens.dart` EXTENDED)

| Category | Tokens | Base |
|----------|--------|------|
| **Spacing** | xs:4, sm:8, md:12, lg:16, xl:20, xxl:24, xxxl:32, huge:48, massive:64, giant:80 | 4px |
| **Radius** | xs:4, sm:8, md:12, lg:16, xl:20, xxl:24, full:9999 | Component-mapped |
| **Shadows** | Soft, Medium, Strong, Aura Glow, Brand Glow | Warm neutrals |
| **Surfaces** | L0 (page), L1 (content), L2 (glass/overlay), L3 (CTA) | Expression-adaptive |
| **Glass/Blur** | Tier 1-4 | Contextual only, never default |
| **Motion** | micro:100ms, short:200ms, standard:300ms, long:500ms, hero:800ms | Smooth, quiet, premium |

### 8.3 Component Taxonomy

```
FOUNDATION       → Spacing, Surface, Container, Border, Radius, Shadow, Elevation, Density
NAVIGATION       → BottomNavigation, TopNavigation, AppBar, Tabs, Back, Menu, Drawer
CONTENT          → Card, Container, Section, ListItem, EditorialBlock, GlassCard, Image, Typography
ACTION           → PrimaryButton, SecondaryButton, TertiaryButton, GhostButton, IconButton, DestructiveButton, CTA
FORM             → TextField, SearchField, Dropdown, DatePicker, TimePicker, OTP, Checkbox, Radio, Switch, Slider
FEEDBACK         → Toast, Snackbar, Banner, Progress, Spinner, Skeleton, EmptyState, ErrorState, SuccessState
OVERLAY          → Dialog, BottomSheet, FullScreenSheet, ConfirmationDialog, ActionSheet, Popover, Tooltip
COMMERCE         → ProductCard, PriceDisplay, DiscountBadge, Cart, Checkout, Payment, OrderSummary, Wishlist
BOOKING          → ServiceSelection, ProviderSelection, DatePicker, TimePicker, LocationPicker, Confirmation, Recovery
CONCIERGE        → ConciergeCard, ChatBubble, SupportTile, BookingAssist, RecommendationCard, PersonalAssistance
AURA             → AuraSurface, AuraCard, AuraInsight, AuraRecommendation, AuraAction, AuraStatus, AuraLoading, AuraConversation
AUDIENCE         → AudienceToggle, AudienceBadge, AudienceFilter
```

### 8.4 Card Language
- **CARD**: Interactive content unit with metadata + action (service, product, provider)
- **CONTAINER**: Passive grouping — no interaction, no metadata
- **SECTION**: Structural page division — full width, semantic grouping
- **LIST_ITEM**: High-density repeating rows — minimal chrome
- **EDITORIAL_BLOCK**: Storytelling — photography + typography + negative space

**Rule**: NOT EVERYTHING IS A CARD. Default to Container/Section unless interaction + metadata + action exist.

| Property | Spec |
|----------|------|
| Radius | 16px (lg) — consistent |
| Padding | lg (16) default, xl (20) editorial |
| Image | Full bleed to radius. 4:5 service, 1:1 product, 16:9 banner |
| Metadata | Cormorant names, Manrope details, JetBrains Mono prices |
| Border | Subtle or none. Not default |
| Shadow | Soft (ambient). Brand glow only for L3/CTA cards |
| Interaction | Tap → ripple on L1. Pressed → scale 0.98 |

### 8.5 Button Language

| Variant | Purpose | Hierarchy | Height | Radius | Typography | Color (W/M/A) |
|---------|---------|-----------|--------|--------|------------|---------------|
| PRIMARY | Primary CTA — one per screen max | 1 | 52 | 12 | Manrope 16w600 | Rose Gold / Champagne / Aura Teal |
| SECONDARY | Alternative path | 2 | 48 | 12 | Manrope 14w600 | Outline Rose Gold / Champagne / Aura Teal |
| TERTIARY | Low emphasis | 3 | 44 | 12 | Manrope 14w500 | Text color only |
| GHOST | Minimal — navigation, dismiss | 4 | 40 | 8 | Manrope 13w500 | Secondary Text |
| ICON_BUTTON | Icon-only action | Contextual | 48×48 | Full/12 | N/A | S1 Icon Color Roles |
| DESTRUCTIVE | Irreversible action | Contextual | 48 | 12 | Manrope 14w600 | Error Red on Error BG |

**States**: Hover +4% opacity, Pressed -4%/scale 0.98, Focused 2px focus border +4px offset, Disabled 38% opacity

### 8.6 CTA Language
- **Primary**: One per screen. Sticky bottom (mobile), inline (desktop). L3 surface. Highest visual weight
- **Secondary**: Supporting action. Above primary (stacked) or trailing. Outline/Ghost
- **Prohibited**: CTA everywhere, primary CTA in card grids, multiple primaries per viewport

### 8.7 Navigation Language
- **Bottom Nav**: 3-5 items. GlowIcon md (24px). S2 Navigation (Manrope 13w500). Active: primary color role + filled weight
- **Top Nav**: Screen-level actions. L1 or Transparent. GlowIcon.back leading
- **Tabs**: Content filtering. S2 Tab (Manrope 13w600). Active: primary + 3px bottom indicator
- **Audience**: Women: Rose Gold active. Men: Champagne active. AURA: Aura Teal active

### 8.8 App Bar Language
| Variant | Purpose | Surface | Typography | Audience |
|---------|---------|---------|------------|----------|
| DEFAULT | Standard header | L1 | H3 (Cormorant 18w600) | Shared |
| TRANSPARENT | Hero/editorial | Transparent → L1 on scroll | H2 or Display S | Inverse text |
| STORE | Store with search | L1 + shadow | H3 + AudienceToggle | Shared |
| DETAIL | Parallax content | Transparent → L1 | Hidden expanded / H3 collapsed | Shared |
| AURA | Intelligence screens | L2 glass or Transparent | H3 + Aura Teal | AURA |
| WOMEN | Women-expression | Per variant | Women emphasis | Women |
| MEN | Men-expression | Per variant (dark) | Men voice | Men |
| CONCIERGE | Concierge touchpoints | L1 or L2 | Concierge Display (Cormorant 24w400) | Shared |

### 8.9 Hero System
| Hero Type | Image | Text | CTA | Negative Space | Height | Overlay |
|-----------|-------|------|-----|----------------|--------|---------|
| HERO | S3 Hero (9:16/16:9) | Display XL/L + Body Large | Primary sticky | 35% min | 60-70vh | Scrim 40% |
| EDITORIAL_HERO | S3 Editorial | Display L/M + Concierge Body | Ghost/Secondary | 50%+ | Variable | Minimal |
| SERVICE_HERO | S3 Service (4:5) | H2 + Body + Metadata | Primary (Book) | Below image | Image 40% | None |
| PRODUCT_HERO | S3 Product (1:1/4:5) | H2 + Price + Body | Primary (Add) | Around product | Image 50% | None |
| AURA_HERO | S3 AURA (abstract+human) | AURA Display + Body | AURA CTA | 40% geometry | 60-70vh | Subtle geometry |

### 8.10 Commerce Language
- **Principles**: Premium commerce feel. Heart (wishlist) ≠ Bag (save) ≠ Cart (checkout)
- **ProductCard**: 1:1 isolation / 4:5 contextual. L1 surface. Radius 16. Name: Cormorant 15w700. Price: JetBrains Mono 16w700
- **PriceDisplay**: JetBrains Mono. COP format `$ 1.234.567` (spaces as thousand separators)
- **Checkout**: Steps: 1) Cuándo y Dónde → 2) Productos → 3) Confirmación/Pago. Sticky summary. Wompi — monetary integrity

### 8.11 Booking Language
**Feels like CONCIERGE, not form wizard**
1. ServiceSelection: Editorial cards (4:5), tap to select
2. ProviderSelection: Cards with avatar, specialty, rating
3. Date: Calendar picker (Month view). Highlighted = L3
4. Time: Chips (radiusChip). Available=L1, Selected=L3
5. Location: Map + autocomplete. GlowIcon.location
6. Confirmation: Editorial summary. Cormorant headline. Price prominent
7. Recovery: Save draft, resume from step
8. Payment: Wompi integration. Single finalCheckoutAmount

### 8.12 Concierge Language
**PERSONAL, HUMAN, ATTENTIVE** — Not call center
- **ConciergeCard**: L2 glass or L1. Radius 16. Avatar: photo or GlowIcon.concierge (32px)
- **Chat**: Bubble L1, radius 20 (not full pill). User: L3 + Inverse. Concierge: L1 + Primary
- **BookingAssist**: Conversational → structured. Manrope throughout
- **RecommendationCard**: Image 4:5 + Cormorant headline + AURA insight badge (Aura Teal)

### 8.13 AURA UI Language
**QUIET INTELLIGENCE. NO cyberpunk, neon, robot, HUD, circuits, generic AI robotics.**
- **Color**: Aura Teal `#164C46` — accent only
- **AuraSurface**: L0 Warm White/Cream + subtle geometry. Not dark mode default
- **AuraCard**: L1 + Aura Teal accent border + fine geometry background
- **AuraInsight**: Editorial block: Cormorant headline + Manrope body + geometry
- **AuraRecommendation**: Product/Service card + "Why this matches" (Aura Teal label)
- **AuraAction**: Primary CTA in Aura Teal. Ghost Secondary
- **AuraStatus**: Pulse animation (organic, 2s). Concentric circles. Not spinner
- **AuraLoading**: Expanding rings (Aura Teal 20%), light particles. 2s ease-out. No rotation
- **AuraConversation**: Chat with GlowIcon.aura avatar. Manrope. Aura Teal accents

**Prohibited**: Cyberpunk cyan, neon glows, circuit patterns, robot avatars, HUD overlays, matrix rain, generic AI brain imagery

### 8.14 Women UI Language
**Differentiation via** (not separate framework):
- Color: Rose Gold, Champagne, Warm Brown
- Photography: Women muse, beauty/ritual
- Composition: Softer, more negative space, dewy
- Editorial Emphasis: Cormorant in brand moments
- Content: Skincare, hair, nails, fragrance, spa, wellness

### 8.15 Men UI Language
**Expression**: QUIET MASCULINE LUXURY
**Differentiation via** (not separate framework):
- Color: Champagne, Warm White, Copper, Warm Stone, Taupe
- Photography: Men muse, grooming/tailored
- Composition: Stronger structure, defined shadows, matte
- Spacing: Same scale, more generous in cards
- Content: Beard, shave, hair, scalp, fragrance, body, grooming, wellness

**Prohibited**: Black UI as default, Gold-only accents, Separate Men component framework, Aggressive/macho visual language

### 8.16 Component States (Official)

| State | Specification |
|-------|---------------|
| DEFAULT | Base appearance per component spec |
| HOVER | Desktop only. +4% opacity or L2 surface fill. 150ms ease |
| PRESSED | Scale 0.98 (cards/buttons) or -4% brightness. 50ms |
| FOCUSED | 2px Focus Border (S1) + 4px offset. Always visible |
| SELECTED | L3 surface background + Primary Border. Icon filled weight |
| DISABLED | 38% opacity. No interaction. Disabled Text color |
| LOADING | Skeleton (L1→L2 shimmer) or Spinner (S1 Primary). No layout shift |
| SUCCESS | Success color (S1) + GlowIcon.check. Toast or inline |
| ERROR | Error color (S1) + GlowIcon.alert. Inline or Card/Full screen |
| WARNING | Warning color (S1) + GlowIcon.warning. Banner or Toast |

### 8.17 Glass / Blur
- **NEVER default GlowApp style**
- Only over photography (S3) or contextual depth (modals, sticky headers)
- Blur: 10-20px max. Surface opacity: 60-85%
- Border: Subtle (S1) in Primary/Accent at 20-30% opacity
- Text on glass: Inverse Text or Primary Text with scrim

### 8.18 Motion Language
| Category | Specification |
|----------|---------------|
| **Duration** | micro:100ms, short:200ms, standard:300ms, long:500ms, hero:800ms |
| **Easing** | standard: `cubic-bezier(0.4,0,0.2,1)`, entrance: `cubic-bezier(0,0,0.2,1)`, exit: `cubic-bezier(0.4,0,1,1)`, spring: `cubic-bezier(0.34,1.56,0.64,1)` |
| **Entrance** | fade:300ms, slide_up:300ms, scale:200ms spring, stagger:50ms/item |
| **Exit** | fade:200ms, slide_down:200ms, scale:150ms |

**Avoid**: Bouncy (overshoot >1.2), Gamer (fast/flashy), Excessive (motion on everything), Fast (<150ms content)

### 8.19 Responsive Language
**Breakpoints**: Mobile:0, Tablet:600, Desktop:1024, Wide:1440
**Approach**: FLUID + ADAPTIVE (not duplicate components)

| Component | Mobile | Tablet | Desktop |
|-----------|--------|--------|---------|
| Navigation | Bottom Nav | Rail | Sidebar |
| Hero | 9:16 | 4:3 | 16:9 |
| Cards | Stack | Grid 2 | Grid 3-4 |
| Forms | Stacked | Side-by-side | Side-by-side |
| Sheets | Full-screen | Bottom sheet | Dialog |

### 8.20 Accessibility Language
| Area | Status | Notes |
|------|--------|-------|
| Touch Targets | VERIFIED | Min 48dp. Buttons 52-56px |
| Contrast | PARTIAL | Primary: 12.8:1 (W), ~4.2:1 (M target). CTA on brand: REQUIRES_VALIDATION. Aura Teal light: 8.2:1. Aura Teal dark: FAIL 1.8:1 |
| Focus | PARTIAL | 2px Focus Border required on ALL interactive. Buttons lack visible focus on web |
| Keyboard | REQUIRES_IMPLEMENTATION | Tab/Shift+Tab, Enter/Space, Escape dismiss, focus trap |
| Screen Reader | REQUIRES_IMPLEMENTATION | Semantic labels on icon-only controls. Live regions. S2 heading hierarchy |
| Text Scaling | REQUIRES_IMPLEMENTATION_VALIDATION | Test 1.0x, 1.3x, 1.5x, 2.0x. Flexible maxLines |
| Motion Sensitivity | REQUIRES_IMPLEMENTATION | Respect `prefers-reduced-motion` |

---

## 9. Icon System

### 9.1 Authority
**Source**: `GLOW_ICON_SYSTEM.md` + `glow_icon_system.json` (L1 — LOCKED)

### 9.2 Status
**GLOW ICON SYSTEM v1.0 — LOCKED**

### 9.3 Visual Language
- **MONOLINE** — Single stroke, consistent weight
- **REFINED** — Clean geometry, organic curves
- **WARM** — Rounded terminals, human proportions
- **MINIMAL** — Minimal beauty details, no noise
- **PREMIUM** — Quality at 16-48px, stroke base 1.75px

### 9.4 Geometry
- Viewport: 24×24
- Stroke base: 1.75px (variants: 1.5/1.75/2.0)
- Stroke-linecap: round
- Stroke-linejoin: round
- Fill: none (outline style)

### 9.5 Sizes
| Token | Value | Use |
|-------|-------|-----|
| xs | 16px | Small/secondary |
| sm | 20px | Compact |
| md | 24px | **Standard interaction** |
| lg | 28px | Prominent |
| xl | 32px | Hero/emphasis |
| xxl | 40px | Featured |
| huge | 48px | Display |

### 9.6 Semantic Color Roles
| Role | Women | Men | AURA |
|------|-------|-----|------|
| primary | Rose Gold `#D4AF7A` | Champagne `#C8B08A` | Aura Teal `#164C46` |
| secondary | Warm Brown `#5A3A2A` | Warm White `#F2EFEA` | Neutral |
| accent | Champagne `#D9A27F` | Copper `#B8734A` | Champagne |
| aura | — | — | **Aura Teal `#164C46`** |
| error | — | — | `#DC2626` |
| success | — | — | `#059669` |
| warning | — | — | `#D97706` |
| neutral | — | — | On-surface |
| disabled | — | — | Grey 400/600 |

### 9.7 Icon Inventory (v1.0 — 22 Icons)

**Core (16)**: home, search, menu, close, back, forward, more, profile, heart, bag, cart, calendar, clock, location, settings, notification

**Proprietary (6)**: glow, aura, concierge, beauty_ritual, glow_recommendation, male_grooming

### 9.8 Rules
- **One geometry per semantic action** — color varies by audience via S1 Icon Color Roles
- NO Material/Cupertino when GlowIcon equivalent exists
- NO individual SVG without registry entry
- NO duplicate geometries
- NO semantically ambiguous icons
- NO using `aura`/`glow`/`glowRecommendation` as universal AI synonyms
- Each new icon requires: semantic name, purpose, geometry, context, accessibility, theme behavior, registry entry, documentation, visual validation

### 9.9 Migration Status
| Phase | Name | Status |
|-------|------|--------|
| M1-I0 | Audit & Map | COMPLETED |
| M1-I1 | Pilot Plan | COMPLETED |
| M1-I2 | Pilot A (Home/Nav) | APPROVED |
| M1-I3 | Pilot B (Store/Women/Men) | APPROVED (97/100) |
| M1-I4 | Pilot C (Booking/Concierge) | PENDING |
| M1-I5 | Pilot D (Provider Dashboard) | PENDING |
| M1-I6 | Global Migration | NOT STARTED (condition: all pilots approved) |

---

## 10. Women Identity

### 10.1 Principle
Women belongs to **GLOWAPP MASTER SYSTEM**. No independent design system.

### 10.2 Expression
Modern femininity + quiet luxury. Not "pink beauty app." Not overly glamorous stock beauty.

### 10.3 Differentiation Allowed
- Color: Rose Gold primary, Warm Brown secondary, Champagne tertiary
- Photography: Female muse, beauty/ritual moments, softer contrast
- Composition: More negative space, dewy/soft finish
- Editorial Emphasis: Cormorant in brand moments
- Content: Skincare, hair, nails, makeup, fragrance, body, spa, wellness

### 10.4 Shared (Not Differentiated)
All foundation tokens, component structure, interaction patterns, Icon System geometry, navigation architecture

---

## 11. Men Identity

### 11.1 Principle
Men belongs to **GLOWAPP MASTER SYSTEM**. Must express **QUIET MASCULINE LUXURY**.

### 11.2 Expression
Stronger structure. Grooming, tailored styling, restrained masculinity. Not black everything. Not aggressive macho. Not generic barbershop. Not sports advertising. Not cyberpunk.

### 11.3 Differentiation Allowed
- Color: Champagne Gold primary, Warm White secondary, Copper tertiary
- Photography: Male muse, beard/grooming rituals, structured wardrobe
- Composition: Higher contrast, defined shadows, matte finish
- Spacing: Same scale, more generous in cards
- Content: Beard, shave, hair, scalp, fragrance, body, grooming, wellness

### 11.5 Prohibited
- BLACK UI as default
- GOLD-ONLY accents
- SEPARATE MEN design system
- Aggressive/macho visual language
- Separate component framework

### 11.6 Implementation Status (From Audits)
**MEN VISUAL IDENTITY = SPECIFIED**  
**MEN IMPLEMENTATION = PARTIAL / PENDING**

---

## 12. AURA Identity

### 12.1 Principle
AURA belongs to GlowApp system. Must express **QUIET INTELLIGENCE**.

### 12.2 Color
**Aura Teal**: `#164C46` — accent only. Does not recolor entire app.

### 12.3 Required Traits
- Calm
- Organic
- Intelligent
- Premium
- Human context
- Abstract organic forms

### 12.4 Prohibited
- Neon
- Cyberpunk
- HUD
- Robot
- Chip
- Circuit
- Generic AI aesthetic
- `auto_awesome` as universal AI representation
- Dark mode as AURA default

### 12.5 Visual Presence
AURA does NOT need to be visually present on every screen. Appears when **INTELLIGENCE IS RELEVANT**. Subtle, organic, premium, intentional.

---

## 13. Interaction & Motion

### 13.1 Motion Principles
**SMOOTH, QUIET, PREMIUM** — Avoid: BOUNCY, GAMER, EXCESSIVE, UNNECESSARY

### 13.2 Standard Scale
- micro: 100ms
- short: 200ms
- standard: 300ms
- long: 500ms
- hero: 800ms

### 13.3 Standard Easing
- standard: `cubic-bezier(0.4, 0, 0.2, 1)`
- entrance: `cubic-bezier(0, 0, 0.2, 1)`
- exit: `cubic-bezier(0.4, 0, 1, 1)`
- spring: `cubic-bezier(0.34, 1.56, 0.64, 1)`

### 13.4 Every New Motion Requires
purpose, duration, easing, interaction

---

## 14. Responsive Principles

| Breakpoint | Value |
|------------|-------|
| Mobile | 0 |
| Tablet | 600 |
| Desktop | 1024 |
| Wide | 1440 |

**Rule**: Every new component must define: mobile, tablet, desktop. No layouts exclusively for one resolution without justification. FLUID + ADAPTIVE approach.

---

## 15. Accessibility

**Goal**: **ACCESSIBILITY BY DEFAULT**

### 15.1 Every New Component Must Consider
- Semantic labels
- Screen reader support
- Keyboard navigation
- Focus visibility
- Contrast (WCAG AA minimum)
- Touch target (48dp minimum)
- Text scaling (1.0x, 1.3x, 1.5x, 2.0x)
- Motion sensitivity (`prefers-reduced-motion`)

### 15.2 Prohibited
- Claiming "compliant" without validation
- Shipping without focus styles on interactive elements
- Aura Teal on dark backgrounds (1.8:1 fails — documented exception in S1)

### 15.3 Validation Required
At G3 (Validation) and G4 (Visual QA) gates

---

## 16. Anti-Patterns (Consolidated)

- Arbitrary colors / spacing / radius
- Duplicated components / icons
- Inconsistent typography (3+ families, generic 'serif'/'sans')
- Excessive cards / pills / shadows / gradients / badges
- Generic AI imagery (cyberpunk, neon, robot, HUD, circuits, brain)
- Generic ecommerce / dashboard UI
- Independent Men UI / Women UI
- Black UI as brand default for Men
- Pink/washed-out aesthetic for Women
- Plastic skin / aggressive retouching
- Burned-in text in images
- Hardcoded TextStyles / colors / spacing
- Screen-specific tokens without justification
- Third font family for AURA/Men/Women
- Playfair Display usage (declared unused)
- Serif in dense UI (legibility)
- Excessive bold / uppercase

---

## 17. Governance

### 17.1 Authority
**Source**: `GLOWAPP_GOVERNANCE.md` + `glowapp_governance.json` (L0)

### 17.2 Sources of Truth

| Domain | Source | Authority | Update Method |
|--------|--------|-----------|---------------|
| COLOR | Color System spec + JSON | L1 | SOUL_REVISION only |
| TYPOGRAPHY | Typography System spec + JSON | L1 | SOUL_REVISION only |
| PHOTOGRAPHY | Photography System spec + JSON | L1 | SOUL_REVISION only |
| ICONOGRAPHY | Icon System spec + JSON | L1 | ICON_SYSTEM_REVIEW (LOCKED v1.0) |
| COMPONENTS | UI Component Language spec + JSON | L2 | COMPONENT_REVIEW |
| AUDIENCE | S1/S3/S4 expression rules | L2 | DIRECTOR_REVIEW |
| AURA | S1/S3/S4 + Icon System | L2 | DIRECTOR_REVIEW |
| GOVERNANCE | Governance spec + JSON | L0 | SOUL_REVISION |

### 17.3 Change Governance

| Level | What | Examples | Approval |
|-------|------|----------|----------|
| **NO REVIEW** | Bug fix matching spec, content update, config toggle, dep patch | — | — |
| **DESIGN REVIEW** | New variant, spacing/radius adjustment, icon usage, screen composition, responsive adjustment, animation timing | — | DESIGN_REVIEW |
| **DIRECTOR REVIEW** | New component, new token, Women/Men/AURA identity, photography domain, icon addition, motion pattern, accessibility pattern, migration scope | — | DIRECTOR_REVIEW |
| **SOUL REVISION** | Color palette HEX, font family, photography muse, icon geometry, authority hierarchy, governance rules, major version | — | SOUL_REVISION + DIRECTOR_APPROVAL |

### 17.4 Change Classification

| Classification | Definition | Approval | Version |
|----------------|------------|----------|---------|
| **PATCH** | Backward-compatible fix, no visual/behavior change | DESIGN_REVIEW | x.y.Z |
| **MINOR** | Backward-compatible addition within spec | COMPONENT/DIRECTOR_REVIEW | x.Y.z |
| **MAJOR** | Breaking change to spec/identity, requires migration | DIRECTOR_REVIEW + SOUL_REVISION | X.y.z |
| **EXCEPTION** | Temporary deviation for unsolvable case | DIRECTOR_REVIEW + EXCEPTION_REGISTRY | N/A (flagged) |
| **EXPERIMENTAL** | Isolated prototype, not in production | DESIGN_REVIEW (proto), DIRECTOR_REVIEW (promote) | N/A |

**Exception Requirements**: problem, reason, affected_area, temporary_or_permanent, risk, approval, expiration_or_review_date. Never silently become standard.

### 17.5 Token Governance
**Rule**: NO new token if existing token solves the case.
**Before Creating**: 1) Search existing, 2) Determine why insufficient, 3) Verify reusability (3+ cases), 4) Justify semantically, 5) Define scope, 6) Approve per classification.
**Prohibited**: Screen-specific tokens, colors without semantic role, spacing off 4px scale, radius not component-mapped, shadows using black, arbitrary typography tokens.

### 17.6 Component Governance
**Before Creating**: 1) Equivalent exists? 2) Resolvable via variant? 3) Reusable? 4) Distinct behavior? 5) Sufficient frequency? 6) Register: purpose, use_case, reusability, variants, dependencies, design_rationale.
**Prohibited**: Single-screen components, duplicating behavior, separate Women/Men/AURA frameworks, bypassing Token system.

### 17.7 Variant Governance
**Allowed When**: Changes behavior/hierarchy/context, or repeated documented need (3+ cases).
**Prohibited When**: Single screen, single case, personal preference, visual tweak without semantic difference.
**Max Variants**: 6 per component. **Naming**: Semantic (Primary/Secondary/Tertiary/Ghost/Icon/Destructive).

### 17.8 Migration Governance
**Every Migration Must Have**: baseline, inventory, plan, pilot, validation, rollback, approval, documentation.
**Prohibited**: "Big bang migration" without explicit authorization.
**Current**: ICON_MIGRATION IN_PROGRESS (M1-I3 Pilot B). TOKEN_CONSOLIDATION NOT_STARTED. MEN_VISUAL_REENGINEERING NOT_STARTED.

### 17.9 Quality Gates

| Gate | Name | Requirement |
|------|------|-------------|
| **G0** | Scope | Defined, aligned to SOUL, no scope creep |
| **G1** | Design | Design review passed, Director approval if required |
| **G2** | Implementation | Code complete, follows tokens/components, no hardcoded values |
| **G3** | Validation | `flutter analyze` PASS, `flutter test` PASS, `flutter build web --release` PASS |
| **G4** | Visual QA | Visual regression vs spec. Mobile/Tablet/Desktop. Women/Men/AURA |
| **G5** | Approval | Design Director sign-off |
| **G6** | Documentation | WHAT/WHY/WHERE/HOW/VALIDATION/DECISION/DATE/VERSION recorded |

**Rule**: Cannot pass to next gate without completing current gate.

---

## 18. AI Agent Operating Contract

### 18.1 Mandatory Steps for EVERY Agent
1. **READ** `GLOWAPP_SOUL.md` first
2. **IDENTIFY** scope of work
3. **CONSULT** corresponding specifications (S1–S5 + Icon System)
4. **AUDIT** before modifying (existing code, tokens, components)
5. **NO inventing** tokens
6. **NO inventing** components
7. **NO creating** duplicate icons
8. **RESPECT** Women/Men/AURA governance rules
9. **PRESERVE** business logic (booking, payment, auth, backend)
10. **VALIDATE** against Definition of Done
11. **DOCUMENT** changes (WHAT, WHY, WHERE, HOW, VALIDATION, DECISION, DATE, VERSION)
12. **STOP** at ambiguity — ask, don't assume

### 18.2 Forbidden Assumptions
- "If it looks good, it's allowed"
- "The existing code does X, so I'll do X"
- "I'll add a quick token for this screen"
- "Material Icons are fine for this one thing"
- "Men needs its own button style"
- "AURA should look techy/futuristic"
- "I'll just hardcode this color"

### 18.3 The Correct Question
**"Is this permitted by the SOUL?"**

---

## 19. Implementation Status Matrix

| Area | Specification | Implementation | Status | Source |
|------|---------------|----------------|--------|--------|
| Color | SPECIFIED (S1) | NOT STARTED | SPECIFIED | S1 |
| Typography | SPECIFIED (S2) | NOT STARTED | SPECIFIED | S2 |
| Photography | SPECIFIED (S3) | NOT STARTED | SPECIFIED | S3 |
| UI Components | SPECIFIED (S4) | NOT STARTED | SPECIFIED | S4 |
| Icons | LOCKED (v1.0) | PILOT B APPROVED (M1-I3) | PARTIAL | Icon System |
| Women | SPECIFIED (S1/S3/S4) | PARTIAL (legacy) | SPECIFIED | S1/S3/S4 |
| Men | SPECIFIED (S1/S3/S4) | 0% photography, partial theme | SPECIFIED | S1/S3/S4 + Audits |
| AURA | SPECIFIED (S1/S3/S4) | PARTIAL (legacy cyberpunk) | SPECIFIED | S1/S3/S4 |
| Governance | SPECIFIED (S5) | NOT STARTED | SPECIFIED | S5 |

---

## 20. Known Implementation Gaps

### 20.1 Critical (P0)
| Gap | Type | Source |
|-----|------|--------|
| No fonts in pubspec.yaml (Cormorant, Manrope, JetBrains Mono) | ASSET_GAP | S2 |
| Cormorant Garamond declared but never used | IMPLEMENTATION_GAP | S2 |
| Manrope not declared in codebase | IMPLEMENTATION_GAP | S2 |
| 6 parallel typography systems | IMPLEMENTATION_GAP | S2 |
| NO MALE MUSE ASSETS (0% Men photography) | ASSET_GAP | S3 |
| Female muse not systematized | ASSET_GAP | S3 |
| AuraWelcomeScreen not Men-adaptive | IMPLEMENTATION_GAP | S3 |
| Cyber Cyan (#00E5FF) in MensTheme | IMPLEMENTATION_GAP | S1/S3/S4 |
| Aura Teal on dark surfaces fails contrast (1.8:1) | DESIGN_GAP | S1 |
| 6 parallel token systems active | IMPLEMENTATION_GAP | S4 |
| Unified components not consolidated (Card, Button, Input, Nav, Modal) | IMPLEMENTATION_GAP | S4 |
| Focus states incomplete (buttons lack visible focus on web) | ACCESSIBILITY_GAP | S4 |

### 20.2 High (P1)
| Gap | Type | Source |
|-----|------|--------|
| Design Ideas = 3D illustrations (5 assets) | IMPLEMENTATION_GAP | S3 |
| Onboarding photography inconsistent | ASSET_GAP | S3 |
| Auth backgrounds generic | ASSET_GAP | S3 |
| Navigation icons are raster PNG | MIGRATION_GAP | S3/Icon System |
| No asset metadata registry | GOVERNANCE_GAP | S3 |
| No responsive crop strategy | IMPLEMENTATION_GAP | S3 |
| Concierge photography undefined | ASSET_GAP | S3 |
| GlowGlassCard vs GlassCard duplicate | IMPLEMENTATION_GAP | S4 |
| Legacy AppTheme in 40+ screens | IMPLEMENTATION_GAP | S4 |

### 20.3 Medium (P2)
| Gap | Type | Source |
|-----|------|--------|
| Legacy logo variants (6 files) not deprecated | DEPRECATION_GAP | S3 |
| No automated quality validation in CI | GOVERNANCE_GAP | S5 |
| Exception registry empty | GOVERNANCE_GAP | S5 |
| Legacy classification not documented | GOVERNANCE_GAP | S5 |
| No unified Avatar component | COMPONENT_GAP | S4 |
| No unified Badge/Status system | COMPONENT_GAP | S4 |
| No unified Tooltip/Popover | COMPONENT_GAP | S4 |
| No unified SegmentedControl | COMPONENT_GAP | S4 |

---

## 21. Migration Status

| Migration | Status | Notes |
|-----------|--------|-------|
| **Glow Icon System v1.0** | LOCKED | Geometry, stroke, viewport, registry frozen |
| **Pilot A (Home/Nav)** | APPROVED | M1-I2 complete |
| **Pilot B (Store/Women/Men)** | APPROVED | M1-I3 complete (97/100) |
| **Pilot C (Booking/Concierge)** | NOT EXECUTED | M1-I4 pending |
| **Pilot D (Provider Dashboard)** | NOT EXECUTED | M1-I5 pending |
| **Global Icon Migration** | NOT STARTED | Condition: all pilots approved |
| **Token Consolidation** | NOT STARTED | 6 systems → Token |
| **Typography Migration** | NOT STARTED | Fonts in pubspec, Cormorant/Manrope activation |
| **Men Visual Reengineering** | NOT STARTED | Photography + theme + components |

---

## 22. Future Work

### REQUIRED (Blockers for Implementation)
- Add 3 font families to `pubspec.yaml` with assets
- Consolidate 6 token systems → single `Token` authority
- Consolidate 6 typography systems → `AppTypography` extended
- Commission Men photography (P0)
- Systematize Female muse (P0)
- Remove Cyber Cyan from MensTheme (P0)
- Resolve Aura Teal on dark contrast (P0)

### PLANNED (Post-SOUL Consolidation)
- Pilot C icon migration (Booking/Concierge)
- Pilot D icon migration (Provider Dashboard)
- Global icon migration (after all pilots)
- Unified component library implementation
- AURA component library
- Concierge component library
- Booking component library

### OPTIONAL (Nice to Have)
- I2 Extended Icon Set (Beauty 8, Men 5, Concierge 4, AURA 6, System 6)
- Automated governance CI gates
- Visual regression test suite
- Design token Figma sync

### NOT AUTHORIZED
- Separate Women/Men/AURA design systems
- Cyberpunk/neon AURA aesthetics
- Black UI as Men brand default
- Third font family
- Big bang migrations

---

## 23. Versioning

| Version | Status | Meaning |
|---------|--------|---------|
| **SOUL v1.0** | CONSOLIDATED | Master specification locked for implementation |
| **Specification** | LOCKED FOR IMPLEMENTATION | No silent changes. Changes require governance process |
| **Implementation** | NOT COMPLETE | Production code diverges from specification |

**LOCKED** = specification must not change silently. **NOT** = implementation is complete.

### Version Rules
- **MINOR (v1.x)**: Adjustments without identity change (token refinement, variant addition, spacing extension, motion tweak) → DIRECTOR_REVIEW
- **MAJOR (v2.0)**: Structural identity change (palette restructure, font family change, muse replacement, icon geometry, governance change) → SOUL_REVISION + DIRECTOR_APPROVAL + FULL_VALIDATION

---

## 24. Definition of Done

A visual implementation is **NOT DONE** until verified:

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

## 25. Source Registry

| Section | Source Document | Authority | Last Verified | Status |
|---------|-----------------|-----------|---------------|--------|
| Identity/Philosophy | S1, S2, S3, S4, S5, Icon System | L0 | 2026-08-20 | CONSOLIDATED |
| Authority Hierarchy | S5 Governance | L0 | 2026-08-20 | CONSOLIDATED |
| Color System | S1 Color System | L1 | 2026-08-20 | CONSOLIDATED |
| Typography System | S2 Typography System | L1 | 2026-08-20 | CONSOLIDATED |
| Photography System | S3 Photography System | L1 | 2026-08-20 | CONSOLIDATED |
| UI Component Language | S4 UI Component Language | L2 | 2026-08-20 | CONSOLIDATED |
| Icon System | Glow Icon System v1.0 | L1 (LOCKED) | 2026-08-19 | CONSOLIDATED |
| Women Identity | S1/S3/S4 | L2 | 2026-08-20 | CONSOLIDATED |
| Men Identity | S1/S3/S4 + Men Audit | L2 | 2026-08-20 | CONSOLIDATED |
| AURA Identity | S1/S3/S4 + Icon System | L2 | 2026-08-20 | CONSOLIDATED |
| Interaction/Motion | S4 + S5 | L2 | 2026-08-20 | CONSOLIDATED |
| Responsive | S4 + S5 | L2 | 2026-08-20 | CONSOLIDATED |
| Accessibility | S4 + S5 | L2 | 2026-08-20 | CONSOLIDATED |
| Anti-Patterns | S4 + S5 | L2 | 2026-08-20 | CONSOLIDATED |
| Governance | S5 Governance | L0 | 2026-08-20 | CONSOLIDATED |
| AI Agent Contract | S5 Governance | L0 | 2026-08-20 | CONSOLIDATED |
| Implementation Status | All specs + audits | L3/L4 | 2026-08-20 | CONSOLIDATED |
| Known Gaps | All audits | L3/L4 | 2026-08-20 | CONSOLIDATED |
| Migration Status | Icon System + S5 | L2 | 2026-08-20 | CONSOLIDATED |
| Future Work | S5 + Director guidance | L0 | 2026-08-20 | CONSOLIDATED |

---

## 26. Consolidation Notes

### 26.1 What Was Consolidated
All six specification phases (S1–S5) + Glow Icon System v1.0 into single master authority document with machine-readable JSON counterpart.

### 26.2 What Remains Specification-Only
**All of it**. This phase (SOUL consolidation) is documentation only. No code, tokens, components, themes, screens, assets, or migrations were created or modified.

### 26.3 What Remains Unimplemented
- All token changes (6 systems → 1)
- Typography activation (Cormorant, Manrope, JetBrains Mono in pubspec)
- Photography assets (Male muse 0%, Female muse unsystematized)
- Component consolidation (5+ Card, 4+ Button, 3+ Input, 3+ Nav, 4+ Modal systems)
- Icon global migration (Pilots A/B approved, C/D pending, global not started)
- Men visual reengineering
- AURA cyberpunk removal

### 26.4 Conflicts Detected
| Conflict | Source A | Source B | Impact | Required Decision |
|----------|----------|----------|--------|-------------------|
| Aura Teal on dark contrast (1.8:1) | S1 Color (FAIL) | S3 AURA (requires Aura Teal on dark) | AURA components on Men surfaces | Director: use Warm White Men surface or AURA Surface only |
| Cyber Cyan in MensTheme | S1 (PROHIBITED) | MensTheme (active) | Men expression identity | Remove Cyber Cyan → Aura Teal for scanner, Champagne for CTAs |
| 6 parallel token systems | Token (target) | 5 legacy systems | Implementation divergence | Migration plan required (NOT in SOUL scope) |
| 6 parallel typography systems | S2 (target) | 5 legacy systems | Inconsistent fonts in production | Migration plan required (NOT in SOUL scope) |

### 26.5 Missing Sources
None — all 6 primary specifications + Icon System + 4 audit documents read and consolidated.

### 26.6 Decisions Requiring Director Approval
1. Aura Teal on dark surfaces resolution (use Warm White Men / AURA Surface only)
2. Men photography commission scope and timeline
3. Token consolidation migration sequence
4. Typography migration sequence (fonts in pubspec first)
5. Global icon migration authorization (after Pilot C/D)
6. Legacy screen classification inventory

---

*End of GLOWAPP SOUL v1.0 — Master Visual + UX + Governance Authority*

---

**GLOWAPP SOUL v1.0**  
**Status**: CONSOLIDATED  
**Specification**: LOCKED FOR IMPLEMENTATION  
**Implementation**: NOT COMPLETE  
**Date**: 2026-08-20  
**Sources**: S1–S5 + Glow Icon System v1.0 + Visual/Men/Icon Migration Audits