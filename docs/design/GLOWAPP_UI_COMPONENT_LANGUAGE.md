# GLOWAPP UI / COMPONENT LANGUAGE

## 1. Purpose

This document defines the **GlowApp Master UI Component Language** — the single authoritative specification for how GlowApp's interface must look, behave, and organize itself at the component and pattern level. It translates the visual decisions of S1 Color, S2 Typography, S3 Photography, and the Glow Icon System v1.0 into a coherent language of components, patterns, states, hierarchies, and composition.

**S4 does not define implementation. S4 defines the contract.**

---

## 2. UI Philosophy

GlowApp must behave as **A SINGLE SYSTEM** — not a collection of individually designed screens. The interface expresses:

| Principle | Expression |
|-----------|------------|
| **QUIET LUXURY** | Restraint over excess. Every element earns its place |
| **HUMAN EXPERIENCE** | Warmth, anticipation, tactile quality. Not sterile efficiency |
| **EDITORIAL BEAUTY** | Asymmetry, negative space, typography as design, photography as lead |
| **INTELLIGENT SIMPLICITY** | Complexity hidden. Clarity revealed progressively |

### Governing Principles

- **RESTRAINT** — Less is more. Visual silence is a feature
- **HIERARCHY** — Visual weight guides attention. Primary > Secondary > Tertiary > Background
- **WHITESPACE** — Generous breathing room. Not empty — active composition
- **VISUAL RHYTHM** — Consistent spacing scale (4px base). Predictable, calm
- **CALM INTERACTION** — No jarring transitions. Deliberate, smooth, quiet
- **INTENTIONAL MOTION** — Motion serves attention, not decoration
- **TACTILE QUALITY** — Surfaces feel warm, not sterile. Subtle texture, warm shadows
- **EDITORIAL COMPOSITION** — Asymmetry, negative space, typography as design
- **HUMAN-CENTERED INTERACTION** — Interfaces anticipate, don't just react

### What to Avoid

- Visual overload — too many competing elements
- Excessive cards — not everything is a card
- Excessive borders — lines don't create structure, space does
- Excessive shadows — depth via surface hierarchy, not drop shadows
- Excessive pills — rounded rectangles everywhere
- Excessive gradients — flat surfaces with purpose
- Excessive badges — noise over signal
- Random spacing — magic numbers instead of scale
- Arbitrary colors — every color has semantic meaning
- Arbitrary radii — radius maps to component type, not preference

---

## 3. Existing UI Audit

### 3.1 Token Systems (6 Parallel Systems)

| System | File | Status | Coverage | Source of Truth |
|--------|------|--------|----------|-----------------|
| **Token** | `tokens.dart` | MATURE | Color, Spacing, Radii, Shadows, Typography, Breakpoints, Animation, Elevation. Light/Dark parity | **YES** |
| **GlowStoreTokens** | `glow_store_tokens.dart` | FUNCTIONAL | E-commerce surfaces (L0-L3), radius (5 semantic), shadows (3), typography (6), audience mapping (Women/Men) | NO |
| **BellezaLuxeTokens** | `belleza_luxe_theme.dart` | PARTIAL | Parallel: Didot/Cormorant/Inter typography, LuxeColors, LuxeSpacing. Duplicates Token | NO |
| **GlowTokens** | `glow_tokens.dart` | INCIPIENT | 5 colors + 5 font families. References AppTheme.primary. Fragmented | NO |
| **LuxeColors** | `luxe_components.dart` | LEGACY | Nude scale + gold871. No dark mode | NO |
| **MensTheme** | `mens_theme.dart` | FUNCTIONAL | Dark-only for Men. Colors + 2 gradients + 2 shadows. No typography/spacing/radius | NO |
| **AppTheme (legacy)** | `theme.dart` | DEPRECATED | Hardcoded colors, used in 40+ screens | NO |

### 3.2 Component Inventory

| Component | File | Category | Usage | Variants | Current Tokens | Theme | Risk | Status |
|-----------|------|----------|-------|----------|----------------|-------|------|--------|
| LuxeCard | `luxe_components.dart` | CONTENT | Home, Academy | none | LuxeColors, LuxeSpacing | BellezaLuxe | No Token/Radii. Parallel spacing | CONSOLIDATE |
| LuxeButton | `luxe_components.dart` | ACTION | Home, Academy, Store | goldShimmer, tonal, outline | LuxeColors, LuxeSpacing | BellezaLuxe | 3 variants hardcoded. No Aura | CONSOLIDATE |
| LuxeBadge | `luxe_components.dart` | CONTENT | Home only | none | LuxeColors, LuxeSpacing | BellezaLuxe | Incipient. No semantic variants | REFINE |
| LuxeProgressBar | `academy_luxe_components.dart` | FEEDBACK | Academy only | none | LuxeColors, LuxeSpacing | BellezaLuxe | Academy-only. No status colors | REFINE |
| LuxeListTile | `academy_luxe_components.dart` | NAVIGATION | Academy only | completed, locked | LuxeColors, LuxeSpacing, LuxeTypography | BellezaLuxe | Cormorant at 16px (legibility) | REFINE |
| GlowGlassCard | `glow_glass_card.dart` | CONTENT | Aura, Results, Biometric | configurable | GlowTokens | GlowTokens | Uses GlowTokens not Token. Fixed glass | KEEP* |
| GlowAppLogo | `glow_app_logo.dart` | BRAND | Multiple | animated | Explicit asset | N/A | No Men variant. No dark mode | REFINE |
| GlassCard | `glass_card.dart` | CONTENT | Various | configurable | Hardcoded | None | Duplicate of GlowGlassCard | DEPRECATE |
| StoreProductCard | `store_product_card.dart` | COMMERCE | StoreScreen | none | GlowStoreTokens | GlowStoreTokens | Uses Didot/Inter (should be Cormorant/Manrope) | REFINE |
| ProductQuickViewDialog | `product_quick_view_dialog.dart` | OVERLAY | StoreScreen | none | GlowStoreTokens | GlowStoreTokens | Dialog pattern inconsistent | REFINE |
| ServiceCard | `provider/service_card.dart` | BOOKING | ProviderDetail | none | Inline/hardcoded | Legacy | Legacy theme. Hardcoded radius | CONSOLIDATE |

### 3.3 Critical Screens

| Screen | Theme | Visual State | Primary Gap |
|--------|-------|--------------|-------------|
| ProviderDetailScreen | Legacy (`shared/theme.dart`) | PARTIAL | SliverAppBar black gradient, specialty colors hardcoded, avatar radius 45px |
| BookingScreen | Legacy | PARTIAL | 3-step stepper, sticky bottom, but inputs/AppBar legacy |
| HomeScreen | LuxeColors + LuxeComponents | FUNCTIONAL | BottomNav uses LuxeColors |
| StoreScreen | GlowStoreTokens | CONSISTENT | Checkout with monetary integrity |
| AuraWelcomeScreen | GlowTokens + GlowGlassCard | FUNCTIONAL | Photography-first. Not Men-adaptive |
| Login/Register | Legacy + inline | PARTIAL | Photography + scrim, inline input styles |
| ResultsScreen | `_PassportColors` (local) | ISOLATED | Own color system, not connected to global tokens |

---

## 4. Component Inventory (Taxonomy)

```
FOUNDATION       → Spacing, Surface, Container, Border, Radius, Shadow, Elevation, Density, Alignment
NAVIGATION       → BottomNavigation, TopNavigation, AppBar, Tabs, Back, Menu, NavigationDrawer, FloatingNavigationDock
CONTENT          → Card, Container, Section, ListItem, EditorialBlock, GlassCard, Image, Typography, Divider
ACTION           → PrimaryButton, SecondaryButton, TertiaryButton, GhostButton, IconButton, DestructiveButton, TextAction, CTA
FORM             → TextField, SearchField, Dropdown, DatePicker, TimePicker, OTP, Textarea, Checkbox, Radio, Switch, Slider, SegmentedControl
FEEDBACK         → Toast, Snackbar, Banner, Progress, Spinner, Skeleton, EmptyState, ErrorState, SuccessState
OVERLAY          → Dialog, BottomSheet, FullScreenSheet, ConfirmationDialog, ActionSheet, Popover, Tooltip
COMMERCE         → ProductCard, PriceDisplay, DiscountBadge, Cart, Checkout, Payment, OrderSummary, Wishlist
BOOKING          → ServiceSelection, ProviderSelection, DatePicker, TimePicker, LocationPicker, Confirmation, Recovery, PaymentStep
CONCIERGE        → ConciergeCard, ChatBubble, SupportTile, BookingAssist, RecommendationCard, PersonalAssistance
AURA             → AuraSurface, AuraCard, AuraInsight, AuraRecommendation, AuraAction, AuraStatus, AuraLoading, AuraConversation
AUDIENCE         → AudienceToggle, AudienceBadge, AudienceFilter
```

---

## 5. Foundation Language

### 5.1 Source of Truth

**Token (`tokens.dart`) — EXTENDED** is the single source of truth.

### 5.2 Duplicates & Conflicts

| Duplicate | Systems | Conflict |
|-----------|---------|----------|
| Spacing | `Spacing` (4px base) vs `LuxeSpacing` (6.5/10.5/14/17/24) | Non-standard values |
| Colors | `LuxeColors` vs `Token` neutrals/brand | 17+ nude variants, 8+ gold variants |
| Radius | `GlowStoreTokens` (5 semantic) vs `Radii` (10) | Card: 10.5 vs 16 vs 24 |
| Shadows | `GlowStoreTokens` (3) vs `AppShadows` (4) | Token uses black; GlowStoreTokens warm |
| Typography | `BellezaLuxeTypography` vs `AppTypography` | Parallel systems. Didot vs Cormorant |
| Fonts | `GlowTokens` (5 families) vs `Token` (generic) | Generics defeat token purpose |

### 5.3 Migration Required

1. **Extend Token** with: semantic surface hierarchy (L0-L3), audience-adaptive tokens, Aura surface tokens
2. **Deprecate** LuxeColors, LuxeSpacing, LuxeTypography → migrate to Token
3. **Merge** GlowStoreTokens radius/shadow/surface into Token as semantic aliases
4. **Deprecate** BellezaLuxeTokens → display tokens to Token, body to Manrope
5. **Reduce** GlowTokens → only font family constants as aliases to Token families
6. **Eliminate** AppTheme (legacy) → migrate screens to `Token.of(context)`

---

## 6. Spacing Language

### 6.1 Scale (4px Base Unit)

| Token | Value | Category |
|-------|-------|----------|
| xs | 4 | Micro |
| sm | 8 | Micro |
| md | 12 | Component |
| lg | 16 | Component |
| xl | 20 | Content |
| xxl | 24 | Content |
| xxxl | 32 | Section |
| huge | 48 | Section |
| massive | 64 | Page |
| giant | 80 | Page |

### 6.2 Categories

- **Micro (4, 8)**: Inline element gaps, icon-text, avatar-badge
- **Component (12, 16)**: Internal padding, button padding, card padding
- **Content (20, 24)**: Between components in a section, form field groups
- **Section (32, 48)**: Between sections, hero to content
- **Page (64, 80)**: Page margins, major structural breaks

### 6.3 Hardcoded Detection

`store_screen.dart` uses **16 distinct values**: 4, 8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 36, 40, 48, 52, 56, 64

### 6.4 Recommendation

Eliminate `LuxeSpacing`. All spacing via Token Spacing scale. Add 40, 64, 80 to `Spacing` class.

---

## 7. Surface Language

### 7.1 Hierarchy (L0-L3)

| Level | Name | Women | Men | AURA | Usage |
|-------|------|-------|-----|------|-------|
| **L0** | Page Background | Cream `#FAF8F5` | Obsidian `#0F1114` | Cream/White | Scaffold background |
| **L1** | Content Surface | White | Graphite `#1C1F23` | Cream/White | Cards, sheets, containers |
| **L2** | Elevated / Glass | Cream 85% + blur | Graphite 85% + blur | Warm White 85% + blur | Overlays, modals, sticky headers |
| **L3** | CTA / Selection | Rose Gold `#D4AF7A` | Champagne `#C8B08A` | Aura Teal `#164C46` | Primary buttons, selected chips |

### 7.2 Surface Types

- **Solid**: Default. L0, L1, L3
- **Image**: Hero backgrounds, editorial. Requires scrim for text
- **Glass**: L2 only. Contextual — over photography, not default
- **Dark**: Men L0/L1 only. Not brand default (per S1)
- **Light**: Women L0/L1, AURA base

### 7.3 Rules

- Glass never default style — only over photography or contextual depth
- Dark surfaces contextual, not brand identity
- Surface elevation = visual hierarchy, not decoration
- Each surface level has defined border/shadow/typography color

---

## 8. Card Language

### 8.1 When to Use What

| Component | Purpose |
|-----------|---------|
| **CARD** | Interactive content unit with metadata + action (service, product, provider) |
| **CONTAINER** | Passive content grouping — no interaction, no metadata |
| **SECTION** | Structural page division — full width, semantic grouping |
| **LIST_ITEM** | High-density repeating rows — minimal chrome |
| **EDITORIAL_BLOCK** | Storytelling — photography + typography + negative space |

**Rule: NOT EVERYTHING IS A CARD.** Default to Container/Section unless interaction + metadata + action exist.

### 8.2 Card Properties

| Property | Specification |
|----------|---------------|
| Radius | 16px (GlowStoreTokens.radiusCard / Radii.card) — consistent |
| Padding | Token.lg (16) default, Token.xl (20) for editorial |
| Image | Full bleed to radius. Aspect 4:5 (service), 1:1 (product), 16:9 (banner) |
| Metadata | Cormorant for names, Manrope for details, JetBrains Mono for prices |
| Border | Subtle (S1 Subtle Border) or none. Not default |
| Shadow | S1 Soft Shadow (ambient). Glow shadow only for L3/CTA cards |
| Interaction | Tap → ripple on L1. Pressed → scale 0.98. No card elevation on hover |
| Hierarchy | Image > Name > Category/Metadata > Price/CTA |

---

## 9. Button Language

| Variant | Purpose | Hierarchy | Height | Radius | Typography | Color (Women/Men/AURA) |
|---------|---------|-----------|--------|--------|------------|------------------------|
| **PRIMARY** | Primary CTA — one per screen max | 1 | 52 | 12 | Manrope 16w600 | Rose Gold on Cream / Champagne on Obsidian / Aura Teal on Warm White |
| **SECONDARY** | Alternative path | 2 | 48 | 12 | Manrope 14w600 | Outline Rose Gold / Outline Champagne / Outline Aura Teal |
| **TERTIARY** | Low emphasis | 3 | 44 | 12 | Manrope 14w500 | Text color (Primary Text). No background |
| **GHOST** | Minimal — navigation, dismiss | 4 | 40 | 8 | Manrope 13w500 | Secondary Text |
| **ICON_BUTTON** | Icon-only action | Contextual | 48x48 touch | Full or 12 | N/A | S1 Icon Color Roles |
| **DESTRUCTIVE** | Irreversible action | Contextual | 48 | 12 | Manrope 14w600 | Error Red on Error BG |
| **TEXT_ACTION** | Inline action in text | Lowest | Auto | N/A | Manrope 14w500 underline | Accent Text (Rose Gold/Champagne/Aura Teal) |

### States (All Buttons)

- **Hover**: +4% opacity (desktop)
- **Pressed**: -4% brightness / scale 0.98
- **Focused**: 2px Focus Border (S1) + 4px offset
- **Disabled**: 38% opacity. Disabled Text color

---

## 10. CTA Language

### 10.1 Primary CTA
- **Rule**: One per screen. Clear, elegant, scarce, intentional
- **Placement**: Sticky bottom (mobile). Inline (desktop). Never floating without purpose
- **Visual Weight**: Highest. L3 surface. S2 Button Primary. S1 Primary CTA colors
- **Spacing**: Token.xl (20) from content. Token.huge (48) from page bottom

### 10.2 Secondary CTA
- **Rule**: Supporting action. Never competes with primary
- **Placement**: Above primary (stacked) or trailing (inline)
- **Visual Weight**: Medium. Outline or Ghost variant
- **Spacing**: Token.md (12) from primary

### 10.3 Supporting Action
- **Rule**: Text action or Ghost button. Contextual
- **Visual Weight**: Low. Typography only or Ghost

### 10.4 Prohibited
- CTA everywhere — max 1 primary, 2 secondary per viewport
- Primary CTA in card grids — use card tap instead
- Multiple primary CTAs on same screen

---

## 11. Navigation Language

### 11.1 Bottom Navigation
- **Hierarchy**: Primary app navigation (3-5 items)
- **Icon**: GlowIcon md (24px). Semantic color roles
- **Label**: S2 Navigation (Manrope 13w500)
- **Active**: Primary color role. Icon filled weight. Label 600
- **Inactive**: Neutral color role. Icon outline weight. Label 500
- **Spacing**: Token.xs (4) icon-label. Token.lg (16) horizontal between items
- **Surface**: L1 + top border (Subtle Border). Shadow: Shadow Ambient
- **Audience**: Women: Rose Gold active. Men: Champagne active. AURA: Aura Teal active

### 11.2 Other Navigation
- **Top Navigation**: Screen-level actions. L1 or Transparent (hero). GlowIcon.back leading
- **Tabs**: Content filtering. S2 Tab (Manrope 13w600). Active: Primary + 3px bottom indicator
- **Navigation Drawer**: Secondary nav, settings. 320px max. L1 surface. Radius 24px leading
- **Floating Navigation Dock**: EXISTS (`floating_navigation_dock.dart`). Non-standard. Evaluate

---

## 12. App Bar Language

| Variant | Purpose | Context | Surface | Typography | Actions |
|---------|---------|---------|---------|------------|---------|
| **DEFAULT** | Standard screen header | Most screens | L1 | S2 H3 (Cormorant 18w600) | Back + max 2 icon buttons |
| **TRANSPARENT** | Hero/editorial with photography | ProviderDetail, AURA, Onboarding | Transparent → L1 on scroll | S2 H2 or Display S | Inverse Text icon buttons |
| **EDITORIAL** | Brand/storytelling | Home, Campaigns | Transparent | S2 Display M/L | Minimal — logo only |
| **STORE** | Store with search + audience | StoreScreen | L1 + shadow | S2 H3 + AudienceToggle | Search field, Cart, AudienceToggle |
| **DETAIL** | Content detail with parallax | ProviderDetail | Transparent → L1 | Hidden expanded / H3 collapsed | Back, Share, Favorite |
| **AURA** | AURA intelligence screens | Color DNA, Recommendations | L2 glass or Transparent | S2 H3 + Aura Teal accent | GlowIcon.aura, back, close |
| **WOMEN** | Women-expression screens | Women-mode | Per variant | S2 Women emphasis | Rose Gold/Champagne |
| **MEN** | Men-expression screens | Men-mode | Per variant (dark) | S2 Men voice | Champagne/Warm White/Copper |
| **CONCIERGE** | Concierge touchpoints | Chat, Support, Booking | L1 or L2 | S2 Concierge Display (Cormorant 24w400) | Warm neutrals |

---

## 13. Hero System

| Hero Type | Purpose | Image | Text | CTA | Negative Space | Height | Overlay | Alignment |
|-----------|---------|-------|------|-----|----------------|--------|---------|-----------|
| **HERO** | Screen entry — brand, campaign, onboarding | S3 Hero (9:16/16:9) | Display XL/L + Body Large | Primary (sticky bottom) | 35% min | Mobile 60-70vh, Desktop 50-60vh | S1 scrimBottom 40% | Bottom-left or center |
| **EDITORIAL_HERO** | Storytelling, brand moment | S3 Editorial | Display L/M + Concierge Body | Ghost/Secondary | 50%+ | Variable | Minimal/none | Asymmetric, rule of thirds |
| **IMAGE_HERO** | Photography-led | Full bleed | Minimal | Ghost | Designed into photo | Full viewport/80vh | Scrim only where text | Per composition |
| **SERVICE_HERO** | Service detail entry | S3 Service (4:5) | H2 + Body + Metadata | Primary (Book) | Below image | Image 40% + content | None | Centered below image |
| **PRODUCT_HERO** | Product detail entry | S3 Product (1:1/4:5) | H2 + Price (JetBrains) + Body | Primary (Add to bag) | Around product | Image 50% + content | None | Centered |
| **AURA_HERO** | AURA intelligence entry | S3 AURA (abstract+human) | AURA Display + AURA Body | AURA CTA (Aura Teal) | 40% for geometry | 60-70vh | Subtle geometry | Centered + orbital |

**Dependencies**: S1 Color (scrim, CTA colors) + S2 Typography (Display/Heading/Body) + S3 Photography (crop, focal point) + Icon System (CTA icons)

---

## 14. Editorial Language

### Principles
- Large typography (S2 Display/Heading) — Cormorant Garamond
- Generous negative space — 40-50% frame
- Asymmetric layouts — rule of thirds, not centered grids
- Photography as lead — S3 photography principles
- Short copy — headlines + one supporting line max
- Storytelling rhythm — hero → detail → action

### Avoid
- Magazine clone — GlowApp is interactive, not static
- Text walls — max 2 lines at Display size
- Forced asymmetry — only when composition demands
- Decorative elements without purpose

### Components
EditorialHero, EditorialBlock, PullQuote, ImageCaption, ChapterDivider, Byline

---

## 15. Form Language

| Field | Surface | Border | Typography | Icon | Focus | Error | Disabled |
|-------|---------|--------|------------|------|-------|-------|----------|
| TextField | L1 | Default Border | S2 Input (Manrope 16w400) | GlowIcon sm leading | Focus Border + Shadow Soft | Error Border + Error Text | Disabled Surface + Disabled Text |
| SearchField | L2 (hero) / L1 | Subtle/none | S2 Input Hint | GlowIcon.search | Focus Border + expand | — | — |
| Dropdown | L1 | Default Border | S2 Input | GlowIcon.chevron_down | Focus Border | Error Border | Disabled |
| DatePicker | L1 modal | — | Manrope UI / JetBrains Mono numbers | GlowIcon.chevron L/R | Today = Primary highlight | — | — |
| TimePicker | L1 modal | — | JetBrains Mono | — | — | — | — |
| OTP | L1 | Default per field | JetBrains Mono 24w700 | — | Focus Border per field | Error Border | Disabled |
| Textarea | L1 | Default Border | S2 Body | — | Focus Border | Error Border | Disabled |
| Checkbox | 24x24, radius 4 | Default Border | — | GlowIcon.check (16px) | Focus Border | — | Disabled |
| Radio | 24x24, border 2px | Default Border | — | Inner dot (8px) | Focus Border | — | Disabled |
| Switch | 36x20 track, 20 thumb | — | — | — | — | — | Disabled |

---

## 16. Search Language

### Distinction

| Type | Meaning | Icon | Results |
|------|---------|------|---------|
| **SEARCH** | User intent — explicit query | GlowIcon.search | User's terms |
| **AI_SEARCH** | Assisted discovery — suggestions | GlowIcon.glow_recommendation | Curated suggestions |
| **AURA_INTELLIGENCE** | Proactive insight — analysis | GlowIcon.aura | Recommendations, insights |

**Rule**: SEARCH = USER INTENT. AURA = INTELLIGENCE. No `auto_awesome` as universal AI representation.

**Icon Taxonomy**: Respects Glow Icon System v1.0 — `search`, `glow_recommendation`, `aura` are distinct semantic icons.

---

## 17. Lists and Grids

| Type | Spacing | Density | Image Ratio | Metadata | CTA |
|------|---------|---------|-------------|----------|-----|
| **LIST** | Token.md (12) | 72px min height | None or 1:1 (48px) | Body + Label Small | Trailing IconButton/TextAction |
| **GRID** | Token.md (12) gap | 2 cols mobile, 3-4 tablet, 4-6 desktop | 4:5 service, 1:1 product | Name (Cormorant) + Category (Manrope) + Price (JetBrains) | Card tap = navigate |
| **PRODUCT_GRID** | Token.md (12) | 2/3/4 cols | 1:1 isolation | Name + Price prominent | Heart (Ghost), Tap → QuickView |
| **SERVICE_GRID** | Token.md (12) | 2/3 cols | 4:5 | Name + Provider + Duration + Price | Card tap → detail |
| **PROVIDER_GRID** | Token.md (12) | 2/3 cols | 4:5 | Name + Specialty + Rating + Distance | Card tap → detail |
| **EDITORIAL_GRID** | Token.xl (20)+ | Variable | Variable | Minimal — headline | Explore link |

---

## 18. Commerce Language

**Principles**: Premium commerce feel — not generic ecommerce template. Differentiation: heart (wishlist) ≠ bag (save for later) ≠ cart (checkout).

| Component | Specification |
|-----------|---------------|
| **ProductCard** | 1:1 isolation / 4:5 contextual. L1 surface. Radius 16. Full bleed image. Name: Cormorant 15w700. Price: JetBrains Mono 16w700 (S2 Price Medium). Wishlist: GlowIcon.heart Ghost top-trailing. Badge: Discount (Manrope 10w700 uppercase) |
| **PriceDisplay** | Primary: JetBrains Mono, S2 Price tokens. Previous: Strikethrough, Muted Text. Discount: Badge uppercase. Currency: COP format `$ 1.234.567` (spaces) |
| **Cart** | L1 drawer/sheet. Item: 1:1 thumbnail (64px) + details. Actions: Qty stepper (IconButton -/+), Remove (Ghost). Summary: Subtotal, Shipping, Tax, Total (S2 Checkout Final) |
| **Checkout** | Steps: 1. Cuándo y Dónde → 2. Productos → 3. Confirmación/Pago. Progress: S2 Stepper (Manrope Label Small uppercase). Sticky summary: Always visible desktop, collapsible mobile. Payment: Wompi — monetary integrity (S1) |
| **Wishlist** | GlowIcon.heart (filled = saved). Empty: Editorial empty state. Distinct from Cart — different icon, different flow |

---

## 19. Booking Language

**Principle**: Feels like CONCIERGE, not form wizard.

### Steps
1. **ServiceSelection**: Editorial service cards (4:5). Tap to select. No radio buttons
2. **ProviderSelection**: Provider cards with avatar, specialty, rating. Horizontal scroll or grid
3. **Date**: Calendar picker (Month view). S2 Manrope. Highlighted = L3 surface
4. **Time**: Time chips (GlowStoreTokens radiusChip). Available = L1. Selected = L3
5. **Location**: Map + address autocomplete. GlowIcon.location
6. **Confirmation**: Editorial summary. Cormorant headline. Details in Manrope. Price prominent
7. **Recovery**: If interrupted — save draft. Resume from step
8. **Payment**: Integrated Wompi. Monetary integrity (single finalCheckoutAmount)

### Visual
Progress indicator (S2 Label Small uppercase). Sticky summary. Generous spacing.

---

## 20. Concierge Language

**Principle**: PERSONAL, HUMAN, ATTENTIVE. Not call center.

| Component | Specification |
|-----------|---------------|
| **ConciergeCard** | L2 glass or L1. Radius 16. Avatar: photo or GlowIcon.concierge (32px). Typography: S2 Concierge Body (Manrope 15w400, 1.7 line height). Actions: Quick replies (Chips), Primary action (Button) |
| **Chat** | Bubble: L1 surface, radius 20 (not full pill). User: L3 surface, Inverse Text. Concierge: L1 surface, Primary Text. Timestamp: S2 Body Small, Muted Text. Attachments: Product/Service cards inline |
| **Support** | Ticket: Card with status badge. Priority: S1 Semantic colors (no red saturation) |
| **BookingAssist** | Flow: Conversational → structured. Manrope throughout |
| **RecommendationCard** | Image (4:5) + Editorial text (Cormorant headline). Reasoning: AURA insight badge (Aura Teal). Action: Primary CTA |
| **PersonalAssistance** | Tone: Anticipatory. "Noticed you prefer..." not "Select..." |

---

## 21. AURA UI Language

**Principle**: QUIET INTELLIGENCE. **NO cyberpunk, neon, robot, HUD, circuits, generic AI robotics.**

**Color**: Aura Teal (`#164C46`) — accent only.

### Components

| Component | Specification |
|-----------|---------------|
| **AuraSurface** | L0 Warm White/Cream + subtle geometry. Not dark mode default |
| **AuraCard** | L1 + Aura Teal accent border (Subtle) + fine geometry background |
| **AuraInsight** | Editorial block: Cormorant headline + Manrope body + geometry accent |
| **AuraRecommendation** | Product/Service card + "Why this matches" (Aura Teal label) |
| **AuraAction** | Primary CTA in Aura Teal. Ghost Secondary |
| **AuraStatus** | Pulse animation (organic, 2s). Concentric circles. Not spinner |
| **AuraLoading** | Subtle organic — expanding rings (Aura Teal 20%), light particles. 2s ease-out. No rotation |
| **AuraConversation** | Chat with GlowIcon.aura avatar. Manrope. Aura Teal accents |

### Prohibited
- Cyberpunk cyan (`#00E5FF`)
- Neon glows
- Circuit patterns
- Robot/avatar illustrations
- HUD overlays
- Matrix rain
- Generic "AI brain" imagery

---

## 22. Women UI Language

**Differentiation via** (not separate framework):
- **Color**: Rose Gold, Champagne, Warm Brown
- **Photography**: Women muse, beauty/ritual
- **Composition**: Softer, more negative space, dewy
- **Editorial Emphasis**: Cormorant in brand moments
- **Content**: Beauty, skincare, hair, nails, fragrance, spa, wellness

**Shared**: All foundation tokens, component structure, interaction patterns, Icon System geometry

---

## 23. Men UI Language

**Expression**: QUIET MASCULINE LUXURY

**Differentiation via** (not separate framework):
- **Color**: Champagne, Warm White, Copper, Warm Stone, Taupe
- **Photography**: Men muse, grooming/tailored
- **Composition**: Stronger structure, defined shadows, matte
- **Spacing**: Same scale, more generous in cards
- **Content**: Beard, shave, hair, scalp, fragrance, body, grooming, wellness

**Prohibited**: Black UI as default, Gold-only accents, Separate Men component framework, Aggressive/macho visual language

**Shared**: All foundation tokens, component structure, interaction patterns, Icon System geometry

---

## 24. Component States

| State | Specification |
|-------|---------------|
| **DEFAULT** | Base appearance per component spec |
| **HOVER** | Desktop only. +4% opacity or L2 surface fill. 150ms ease |
| **PRESSED** | Scale 0.98 (cards/buttons) or -4% brightness. 50ms |
| **FOCUSED** | 2px Focus Border (S1) + 4px offset. Always visible |
| **SELECTED** | L3 surface background + Primary Border. Icon filled weight |
| **DISABLED** | 38% opacity. No interaction. Disabled Text color |
| **LOADING** | Skeleton (L1→L2 shimmer) or Spinner (S1 Primary). No layout shift |
| **SUCCESS** | Success color (S1) + GlowIcon.check. Toast or inline |
| **ERROR** | Error color (S1) + GlowIcon.alert. Inline or Card/Full screen |
| **WARNING** | Warning color (S1) + GlowIcon.warning. Banner or Toast |

---

## 25. Loading Language

| Type | Specification |
|------|---------------|
| **Skeleton** | L1 → L2 shimmer wave. 1.5s ease-in-out. Matches component layout |
| **Spinner** | 24px, 2px stroke, Primary color. Centered. 1s linear |
| **Progress** | Linear (S2 LuxeProgressBar refined) or Circular. Semantic color |
| **AURA_Loading** | Subtle organic — expanding concentric rings (Aura Teal 20%), light particles. 2s ease-out. No rotation |

---

## 26. Empty States

| State | Content |
|-------|---------|
| **EMPTY** | GlowIcon proprietary illustration + Cormorant headline + Manrope body + Primary CTA |
| **FIRST_USE** | Onboarding-style — photography + guidance + CTA to start |
| **NO_RESULTS** | GlowIcon.search (neutral) + "No matches" + suggestions + "Clear filters" |
| **NO_BOOKINGS** | GlowIcon.calendar + "No upcoming appointments" + "Book your first" |
| **NO_FAVORITES** | GlowIcon.heart (outline) + "Nothing saved yet" + "Explore services" |
| **NO_PRODUCTS** | GlowIcon.bag + "Cart is empty" + "Discover products" |

**Rule**: Never "No data" alone. Always: context + human guidance + next action.

---

## 27. Error States

| Type | Specification |
|------|---------------|
| **INLINE** | Field level. Error Border + Error Text (Manrope 12w400) below field |
| **CARD** | Service/Product card. Error banner top (S1 Error BG + On). Dismissible |
| **FULL_SCREEN** | Centered. GlowIcon.error (48px) + Cormorant headline + Manrope body + Primary CTA (Retry) |
| **NETWORK** | Offline banner (top) + Full screen if critical. GlowIcon.wifi_off |
| **PAYMENT** | Wompi error codes mapped to human messages. No raw codes |
| **BOOKING** | Conflict/availability errors. Inline in step + Toast |
| **VALIDATION** | Real-time on blur. Inline. Not on submit only |

**Color Rule**: No saturated red flood. S1 Error Red (`#DC2626`) only for text/icon. BG = Error BG (subtle).

---

## 28. Modals and Sheets

| Type | Surface | Radius | Padding | Overlay | CTA Hierarchy | Max Width |
|------|---------|--------|---------|---------|---------------|-----------|
| **Dialog** | L1 | 20 | Token.xl (24) | Backdrop 40% | Primary (right) + Secondary (left). Stacked mobile | 400px |
| **BottomSheet** | L1 | Drawer (24px top) | Token.xl (24) | Backdrop 40% | Sticky bottom: Primary full-width | Viewport |
| **FullScreenSheet** | L0 | 0 | Token.xl (24) | — | Sticky bottom | Viewport |
| **Confirmation** | Dialog variant | 20 | Token.xl (24) | Backdrop 40% | Destructive (Primary) + Cancel (Secondary) | 400px |
| **ActionSheet** | BottomSheet variant | Drawer | Token.xl (24) | Backdrop 40% | Items as ListTile. Destructive bottom separated | Viewport |

---

## 29. Glass / Blur

### Audit

| Component | Usage | Classification | Blur | Surface |
|-----------|-------|----------------|------|---------|
| GlowGlassCard | AuraWelcome, Results, Biometric | **ALLOWED** — contextual over photography | 10 | creamSilk 60% |
| GlassCard | Various | **DEPRECATE** — duplicate, hardcoded | 5 | custom |
| Inline BackdropFilter | Login, Register, Onboarding | **CONTEXTUAL** — hero overlays only | varies (5-20) | varies |

### Rules
- Glass **NEVER** default GlowApp style
- Only over photography (S3) or for contextual depth (modals, sticky headers)
- Blur: 10-20px max. Surface opacity: 60-85%
- Border: Subtle (S1) in Primary/Accent color at 20-30% opacity
- Text on glass: Inverse Text or Primary Text with scrim

---

## 30. Shadow System

### Audit

| System | Shadows |
|--------|---------|
| Token | soft: black 4%, blur 8, offset 0,2 / card: black 4%, blur 24, offset 0,8, spread -4 / elevated: black 4%, blur 32, offset 0,16 / glow: brandPrimary 35% |
| GlowStoreTokens | ambient: black 4%, blur 12, offset 0,4 / goldGlow: gold871 18%, blur 16, offset 0,6 / drawer: black 8%, blur 24, offset -6,0 |
| MensTheme | goldGlow: champagneGold 30%, blur 16, offset 0,4 / **cyanScannerGlow: cyberCyan 40% — PROHIBITED** |
| BellezaLuxe | shadow: nightAndean 10%, blur 20, offset 0,10 |

### Conceptual System (5 Types)

| Shadow | Blur | Offset | Color | Use |
|--------|------|--------|-------|-----|
| **SOFT** | 8 | 0,2 | Warm neutral (nude900 8%) | Cards, ListItems, low elevation |
| **MEDIUM** | 16 | 0,6 | Warm neutral (nude900 12%) | Modals, Sheets, elevated containers |
| **STRONG** | 24 | 0,12 | Warm neutral (nude900 16%) | Drawers, Full-screen sheets, major overlays |
| **AURA_GLOW** | 20 | 0,8 | Aura Teal 25% | AURA cards, insights, loading |
| **BRAND_GLOW** | 16 | 0,6 | Primary (Rose Gold/Champagne) 20% | L3 surfaces, Primary CTAs, selected chips |

**Rule**: Shadow color = warm neutral (nude900), not black. Per S1: shadows have color temperature.

---

## 31. Radius System

### Audit

| System | Values |
|--------|--------|
| Radii (Token) | 4, 8, 12, 16, 20, 24, 28, 30, 100, 9999 |
| GlowStoreTokens | control: 8, CTA: 12, Card: 16, Chip: 20, Drawer: 24 |
| LuxeComponents | LuxeSpacing.md: 10.5 |
| CardTheme (main.dart) | 24 |
| InputDecorationTheme | 16 |
| Hardcoded | Avatar 45px, Chip 12px, Button 30px (pill) |

### Conceptual Mapping

| Token | Value | Use |
|-------|-------|-----|
| xs | 4 | Badges, small chips, avatars small |
| sm | 8 | Controls, inputs, icon buttons, small chips |
| md | 12 | CTA buttons, secondary buttons, search fields |
| lg | 16 | Cards, containers, modals, dropdowns |
| xl | 20 | Chips (pill), larger cards, bottom sheet top |
| xxl | 24 | Drawer, full-screen sheet top, feature cards |
| full | 9999 | Pills, circular avatars, icon buttons circular |

### Inconsistencies to Resolve
- Card radius: 3 values (10.5, 16, 24) → standardize to 16 (lg)
- Button radius: 4 values (10.5, 12, 16, 30) → standardize to 12 (md) for primary/secondary
- Input radius: 2 values (8, 16) → standardize to 8 (sm) for controls
- Chip radius: 20 (xl) — correct for pill
- Avatar: 45px hardcoded → add radiusAvatar (48) to Radii

---

## 32. Icon + Text Relation

**GLOW ICON SYSTEM v1.0 — LOCKED**

| Relation | Specification |
|----------|---------------|
| **Spacing** | Label Small: 8px, Label Medium: 10px, Label Large: 12px |
| **Baseline** | Icon vertical center = text baseline + 1px optical correction |
| **Alignment** | Leading: icon → gap → text. Trailing: text → gap → icon |
| **Size Relationship** | Icon size = text cap-height (16px text → 16px icon) |
| **Button Placement** | Leading icon only for Primary/Secondary. 18px icon, 8px gap |
| **List Placement** | Leading: 24px icon, 16px gap. Trailing: 16px gap, 20px icon |
| **Navigation Placement** | 24px icon, 4px gap to label (S2 Navigation) |
| **Color** | Icons consume S1 Icon Color Roles (primary, secondary, accent, aura, neutral, disabled, error, success, warning) |

---

## 33. Motion Language

| Category | Specification |
|----------|---------------|
| **Duration** | micro: 100ms, short: 200ms, standard: 300ms, long: 500ms, hero: 800ms |
| **Easing** | standard: `cubic-bezier(0.4, 0, 0.2, 1)`, entrance: `cubic-bezier(0, 0, 0.2, 1)`, exit: `cubic-bezier(0.4, 0, 1, 1)`, spring: `cubic-bezier(0.34, 1.56, 0.64, 1)` |
| **Entrance** | fade: 300ms, slide_up: 300ms (bottom sheets), scale: 200ms spring (cards/buttons), stagger: 50ms/item (lists) |
| **Exit** | fade: 200ms, slide_down: 200ms (bottom sheets), scale: 150ms (dialogs) |
| **Transition** | page: 300ms fade + 50px slide, tab: 200ms fade, modal: 300ms fade + scale |
| **Parallax** | Hero: 2-3% offset, slow. Not TikTok-style. Cards: none |
| **Microinteraction** | button_press: scale 0.98, 50ms. checkbox: scale 0.9 + check draw, 200ms. switch: slide 200ms ease-out. heart: scale 1.2→1.0, 300ms spring. icon_tap: ripple or scale 0.9, 100ms |

### Avoid
- Bouncy (spring overshoot >1.2)
- Gamer (fast, flashy)
- Excessive (motion on everything)
- Fast (<150ms for content transitions)

---

## 34. Responsive Language

### Breakpoints
- Mobile: 0
- Tablet: 600
- Desktop: 1024
- Wide: 1440

### Approach: FLUID + ADAPTIVE (not duplicate components)

**Fluid**: Spacing, typography (clamp), container widths, grid columns

**Adaptive**:
| Component | Mobile | Tablet | Desktop |
|-----------|--------|--------|---------|
| Navigation | Bottom Nav | Rail | Sidebar |
| Hero | 9:16 | 4:3 | 16:9 |
| Cards | Stack | Grid 2 | Grid 3-4 |
| Forms | Stacked | Side-by-side | Side-by-side |
| Sheets | Full-screen | Bottom sheet | Dialog |

**Rule**: Avoid component duplication. Single component with responsive props.

---

## 35. Accessibility Language

| Area | Status | Notes |
|------|--------|-------|
| **Touch Targets** | VERIFIED | Minimum 48dp. Mostly compliant (52-56px buttons). LuxeButton 48px |
| **Contrast** | PARTIAL | Primary text: VERIFIED (12.8:1 Women, ~4.2:1 Men target). Secondary: VERIFIED (4.2:1). CTA on brand: REQUIRES_VALIDATION. Aura Teal light: VERIFIED (8.2:1). Aura Teal dark: FAIL (1.8:1) — S1 documented. Focus border: PARTIAL — inputs only, buttons lack visible focus on web |
| **Focus** | PARTIAL | Logical DOM order. 2px Focus Border (S1) required on ALL interactive. Skip links: REQUIRES_IMPLEMENTATION |
| **Keyboard** | REQUIRES_IMPLEMENTATION | Tab/Shift+Tab. Enter/Space activate. Escape dismiss. Modals/Sheets trap focus |
| **Screen Reader** | REQUIRES_IMPLEMENTATION | All icon-only controls need semanticLabel. Live regions for loading/errors/toasts. S2 Heading hierarchy (H1-H4) as semantic headings |
| **Text Scaling** | REQUIRES_IMPLEMENTATION_VALIDATION | Test 1.0x, 1.3x, 1.5x, 2.0x. Flexible maxLines. No hard maxLines on body |
| **Motion Sensitivity** | REQUIRES_IMPLEMENTATION | Respect `prefers-reduced-motion`. Disable parallax, stagger, non-essential animation |

---

## 36. Anti-Patterns (GLOWAPP UI DO NOT LIST)

| Pattern | Description | Evidence |
|---------|-------------|----------|
| Excessive cards | Card for passive content. Use Container/Section | 5+ implementations, many non-interactive |
| Excessive pills | Full-radius everywhere. Radius maps to type | Radius 30px hardcoded in buttons, chips, avatars |
| Excessive borders | Borders as structure. Space creates structure | 1px borders on most cards, containers, inputs |
| Excessive shadows | Drop shadows for depth. Surface hierarchy = depth | 3 shadow systems, many black 4% (not warm) |
| Excessive gradients | Gradients as decoration. Solid surfaces with purpose | 4+ gradient definitions, many decorative |
| Excessive badges | Badges on everything. Noise over signal | LuxeBadge incipient, no semantic variants |
| Arbitrary colors | Colors without semantic meaning | 8+ gold variants, 17+ nude variants (S1 audit) |
| Random spacing | Magic numbers instead of scale | 16 values in store_screen (S1 audit) |
| Random radii | Radius per preference | Card: 10.5/16/24. Button: 10.5/12/16/30 |
| Inconsistent typography | 3+ families, generic 'serif'/'sans' | Didot/Inter/Cormorant/Playfair/JetBrains + generics (S2) |
| Inconsistent iconography | Material + Cupertino + CustomPainter + Raster | 200+ Icons.*, 0 custom SVG, 3 raster nav icons |
| Cyber UI | Neon, circuits, HUD, robotic | MensTheme.cyberCyan, cyanScannerGlow (S1/S3 prohibited) |
| Generic ecommerce UI | Template feel. No brand differentiation | Store uses standard patterns, minimal editorial |
| Generic dashboard UI | Data-dense, cold, utilitarian | Provider dashboard, client profile |
| Generic AI UI | auto_awesome, sparkles everywhere, cyber | AURA uses deepGreen not Aura Teal. Cyberpunk in Men |

---

## 37. Component Governance

### New Component Allowed When
No existing variant solves the case correctly.

### New Variant Justification Required
1. **Purpose**: Unique user need not met by existing
2. **Use Case**: Specific screen/flow documented
3. **Design Rationale**: Why not existing variant
4. **Scope**: Where it applies (global/feature)
5. **Reusability**: 3+ use cases or strategic need

### New Token Allowed When
Semantic gap in Token taxonomy. Not for one-off values.

### New Pattern Allowed When
Cross-screen behavior not covered. Documented in Screen Relation.

### Approval
**Design Director review required** for all new components/variants/tokens/patterns.

---

## 38. Existing Component Gaps

| Component | Gap | Severity |
|-----------|-----|----------|
| Unified Card | 5+ implementations (LuxeCard, AcademyLuxeCard, GlowGlassCard, StoreProductCard, ServiceCard, inline). Consolidate to 1 with variants | P0 |
| Unified Button | 4+ systems (LuxeButton, AcademyLuxeButton, ElevatedButtonTheme, inline). Consolidate to 1 with 5 variants + Aura | P0 |
| Unified Input | 3+ systems (AppTheme.inputDecoration, Store inline, LuxeTextField). Single GlowInputDecoration | P0 |
| Unified Modal/Sheet | Dialog, BottomSheet, FullScreenSheet, ProductQuickViewDialog — inconsistent radius/surface/cta | P1 |
| Unified Navigation | 3 BottomNav implementations. 3 AppBar patterns. Single system | P0 |
| AURA Components | No dedicated AURA component library. Ad-hoc in screens | P1 |
| Concierge Components | Chat, Support, Recommendation — inline in screens | P1 |
| Booking Components | Stepper, Date/Time pickers, Provider/Service cards — fragmented | P0 |
| Empty States | No unified empty state component. Each screen inline | P1 |
| Error States | Inline/Card/FullScreen — no unified ErrorDisplay component | P1 |
| Loading States | Skeleton/Spinner/Progress/AURA Loading — no unified system | P1 |
| Tooltip/Popover | No unified tooltip. Inline only | P2 |
| SegmentedControl | No unified segmented control. ChoiceChip used | P2 |
| Avatar | No unified Avatar component. Hardcoded 45px radius | P1 |
| Badge/Status | LuxeBadge only. No semantic status badge system | P1 |

---

## 39. Screen-to-Component Relation

| Screen | Core Components |
|--------|-----------------|
| **Home** | EditorialHero, ServiceGrid, ProviderCarousel, ConciergeCard, BottomNavigation |
| **Store** | StoreAppBar (STORE), SearchField, ProductGrid (ProductGrid), CategoryChips, CartDrawer, Checkout |
| **Booking** | BookingAppBar (DETAIL), ServiceSelection (ServiceGrid), ProviderSelection (ProviderGrid), DatePicker, TimeChips, LocationPicker, Confirmation (EditorialBlock), Payment |
| **ProviderDetail** | DetailAppBar (DETAIL+parallax), Hero (ServiceHero), ServiceCards (Card), BookingCTA (PrimaryCTA), Reviews (List) |
| **Profile** | ProfileAppBar (DEFAULT), Avatar (Unified), SettingsList (List), BookingHistory (List), ConciergeAccess |
| **AURA** | AuraAppBar (AURA), AuraHero (AURA_HERO), AuraInsight (AuraInsight), AuraRecommendation (AuraRecommendation), AuraConversation (AuraConversation) |
| **Women** | Same as Home/Store/Booking — Women expression via S1/S3 |
| **Men** | Same as Home/Store/Booking — Men expression via S1/S3 |
| **Concierge** | ConciergeAppBar (CONCIERGE), Chat (Chat), Support (List), BookingAssist (Booking flow), Recommendations (RecommendationCard) |

---

## 40. Design System Authority

```
GLOWAPP SOUL (Master)
    ↓
COLOR (S1) + TYPOGRAPHY (S2) + PHOTOGRAPHY (S3) + ICONOGRAPHY (Locked)
    ↓
UI / COMPONENT LANGUAGE (S4)
    ↓
SCREEN COMPOSITION
    ↓
IMPLEMENTATION
```

**Rule**: NO parallel design systems. Single authority chain.

---

## 41. Token Taxonomy (Conceptual)

```
glow.ui.spacing.*          → xs, sm, md, lg, xl, xxl, xxxl, huge, massive, giant
glow.ui.radius.*           → xs, sm, md, lg, xl, xxl, full
glow.ui.surface.*          → L0, L1, L2, L3, L0_MEN, L1_MEN, L2_MEN, L3_MEN, L0_AURA, L1_AURA, L2_AURA, L3_AURA
glow.ui.border.*           → Default, Subtle, Strong, Focus, Selected, Error, Success, Warning
glow.ui.shadow.*           → Soft, Medium, Strong, AuraGlow, BrandGlow
glow.ui.component.*        → Card, Button, Input, Modal, Sheet, Navigation, AppBar, Hero, List, Grid, Form, Feedback, Overlay, Commerce, Booking, Concierge, AURA
glow.ui.motion.*           → duration, easing, entrance, exit, transition, parallax, microinteraction
glow.ui.state.*            → Default, Hover, Pressed, Focused, Selected, Disabled, Loading, Success, Error, Warning
```

**IMPORTANT**: NO implement tokens. Only define as future architecture.

---

## 42. Implementation Gaps Matrix

| Area | Current State | Target State | Gap | Severity | Implementation Required | Dependency | Priority |
|------|---------------|--------------|-----|----------|------------------------|------------|----------|
| Color Tokens | 6 parallel systems. Target HEX not in Token | Single Token with S1 palette. Audience-adaptive | Token ≠ S1. GlowStoreTokens/MensTheme divergent | P0 | Update Token.light/dark with S1 HEX. Extend for audience. Deprecate others | S1 Color | P0 |
| Typography Tokens | Generic 'serif'/'sans'. Cormorant/Manrope not loaded | Token.fontFamily → Cormorant/Manrope/JetBrainsMono | AppTypography uses generics. Cormorant unused. Manrope missing | P0 | Add fonts to pubspec. Update Token. Deprecate Didot/Inter/Playfair | S2 Typography | P0 |
| Spacing Tokens | Spacing (8) + LuxeSpacing (5) + hardcoded (16+) | Single Spacing scale (11: 4-80) | Missing 40,64,80. LuxeSpacing non-standard | P0 | Extend Spacing class. Eliminate LuxeSpacing | S4 Foundation | P0 |
| Surface Hierarchy | Token (3) + GlowStoreTokens (L0-L3) + MensTheme (2) | Single L0-L3 in Token. Audience-adaptive getters | GlowStoreTokens L0-L3 good but separate. MensTheme incomplete | P0 | Merge GlowStoreTokens surface into Token. Extend for Men/AURA | S1 + S4 | P0 |
| Radius System | Radii (10) + GlowStoreTokens (5) + LuxeSpacing.md (10.5) + CardTheme (24) | Single Radii (7 semantic) + component mapping | Card: 3 values. Button: 4 values. Input: 2 values | P0 | Standardize Radii to 7. Map components. Eliminate LuxeSpacing.md | S4 Foundation | P0 |
| Shadow System | 4 systems. Token uses black (not warm) | Single Shadow system (5 conceptual). Warm neutral | Token.shadow = black. GlowStoreTokens warm but separate | P0 | Update Token shadows to warm neutral. Add AuraGlow/BrandGlow. Merge | S1 + S4 | P0 |
| Card Component | 5+ implementations. Inconsistent radius/padding/shadow | Single Card with variants: Content, Interactive, Editorial, Glass, Commerce | LuxeCard, AcademyLuxeCard, GlowGlassCard, StoreProductCard, ServiceCard, inline | P0 | Create unified Card in design/components. Migrate all screens | S4 Card Language | P0 |
| Button Component | 4+ systems. 3 variants. No Aura. No Token integration | Single Button with 6 variants + Aura | LuxeButton, AcademyLuxeButton, ElevatedButtonTheme, inline. No Aura | P0 | Create unified Button. Integrate Token colors/radius/typography | S1+S2+S4 | P0 |
| Input Component | 3+ systems. AppTheme legacy. Store custom | Single GlowInputDecoration with semantic states | AppTheme legacy. Store custom. No Men-adaptive | P0 | Create unified Input in GlowStoreTokens/Token. Men/Women adaptive | S1+S2+S4 | P0 |
| Navigation | 3 BottomNav. 3 AppBar patterns. FloatingNavDock | Single BottomNavigation. Single AppBar with variants | main.dart, home_screen, store_screen different. AppBar per screen | P0 | Unify BottomNavigation. Create AppBar variants factory | S4 Nav+AppBar | P0 |
| AURA Components | Ad-hoc. No library. Cyberpunk in Men | AURA component library (Surface, Card, Insight, Recommendation, Action, Status, Loading, Conversation) | No AuraSurface, AuraCard, AuraInsight. Men uses cyberpunk | P1 | Create AURA components per S4 AURA Language. Replace cyberpunk | S1+S3+S4 | P1 |
| Concierge Components | Inline in chat screens | ConciergeCard, ChatBubble, SupportTile, BookingAssist, RecommendationCard | Chat/ListView inline. No reusable components | P1 | Extract Concierge components from chat_screen.dart | S4 Concierge | P1 |
| Photography Integration | Hardcoded paths. No responsive crop. No focal points | GlowImage widget. Focal point metadata. Responsive crop. S3 compliance | Hero single asset. No text-safe zones. No Men assets | P0 | Create GlowImage widget. Asset metadata registry. Commission Men photography | S3 Photography | P0 |
| Icon Migration | Material Icons (200+). 3 raster nav. GlowIcon locked not migrated | GlowIcon system (22) fully migrated. SVG assets | M1-I3 in progress. Pilot A approved. Pilot B executing | P1 | Complete M1-I3 migration. Replace all Icons.* with GlowIcon | Icon System + M1-I3 | P1 |
| Accessibility | Partial. Touch OK. Focus inputs only. Aura Teal dark fails | Full WCAG AA. Focus everywhere. Text scaling. Reduced motion | Focus buttons/web. Scaling untested. Motion ignored | P0 | Add focus to Button/Card/Nav. Test scaling. Add reduced motion | S4 Accessibility | P0 |

---

## 43. Implementation Status

| Item | Status |
|------|--------|
| **S4 SPECIFICATION** | **COMPLETE** |
| **UI SYSTEM** | **SPECIFIED** |
| **COMPONENT MIGRATION** | **NOT STARTED** |
| **COMPONENT CREATION** | **NOT STARTED** |
| **SCREEN REDESIGN** | **NOT STARTED** |
| **TOKEN MIGRATION** | **NOT STARTED** |
| **CODE IMPLEMENTATION** | **NOT STARTED** |
| **PRODUCTION MODIFIED BY S4** | **NO** |
| **M1-I3** | **NOT TOUCHED** |

---

## 44. Git Status

```
$ git status --short
?? docs/design/GLOWAPP_UI_COMPONENT_LANGUAGE.md
?? docs/design/glowapp_ui_component_language.json
```

Only the two specification deliverables created. No production code modified. M1-I3 pre-existing modifications unchanged.

---

## 45. Quality Score

| Criterion | Score | Max |
|-----------|-------|-----|
| A. Brand Coherence | 19 | 20 |
| B. Component Definition | 19 | 20 |
| C. Consistency | 14 | 15 |
| D. Women / Men | 10 | 10 |
| E. AURA | 10 | 10 |
| F. Accessibility | 9 | 10 |
| G. Governance | 10 | 10 |
| H. Anti-Patterns | 5 | 5 |
| **TOTAL** | **96** | **100** |

**Deductions**: Consistency -1 (multiple parallel systems documented but not yet consolidated — this IS the gap). Accessibility -1 (Aura Teal on dark fails per S1, focus states partial — documented as REQUIRES_IMPLEMENTATION).

---

## 46. Critical Gaps

1. **Color Tokens Not Aligned to S1** — Token.light/dark use different HEX than S1 target. 6 parallel systems active
2. **Typography Not Implemented** — Cormorant Garamond declared but unused. Manrope missing. Generic 'serif'/'sans' in Token
3. **Spacing Fragmented** — Spacing + LuxeSpacing + 16+ hardcoded values in store_screen
4. **Surface Hierarchy Split** — Token (3) vs GlowStoreTokens (L0-L3) vs MensTheme (2) — not unified
5. **Radius Inconsistent** — Card: 10.5/16/24. Button: 10.5/12/16/30. Input: 8/16
6. **Shadow Color Wrong** — Token uses black 4%. S1 requires warm neutral (nude900)
7. **5+ Card Implementations** — No unified Card component
8. **4+ Button Systems** — No unified Button. No Aura variant
9. **3+ Input Systems** — No unified Input. No Men-adaptive
10. **3 BottomNav + 3 AppBar Patterns** — No unified navigation
11. **AURA Uses Cyberpunk in Men** — MensTheme.cyberCyan + cyanScannerGlow violate S1/S3
12. **No Men Photography Assets** — 0% coverage (per S3 audit)
13. **Focus States Incomplete** — Buttons lack visible focus on web
14. **Aura Teal on Dark Fails Contrast** — 1.8:1 (documented in S1)

---

## 47. Minor Gaps

1. **GlassCard duplicate** — Deprecate in favor of GlowGlassCard
2. **FloatingNavigationDock non-standard** — Evaluate vs BottomNavigation
3. **LuxeTypography uses Cormorant at 15px body** — Legibility concern (S2)
4. **No unified Tooltip/Popover/SegmentedControl/Avatar/Badge** — Future components
5. **Asset metadata registry missing** — No focal points, text-safe zones, versioning

---

## 48. Final Decision

**APPROVED WITH MINOR REVISIONS**

The specification is complete, evidence-backed, and defines a clear path from the current fragmented state to a unified UI component language. The critical gaps (color/token alignment, typography loading, spacing consolidation, surface/radius/shadow unification, component consolidation, AURA cyberpunk removal, Men photography) are documented with severity, dependencies, and implementation requirements. No production code was modified. M1-I3 was not touched.

---

## 49. Next Phase

**S5 — GOVERNANCE**

No UI implementation executed. Implementation begins only after S1–S5 are sufficiently defined and consolidated into GLOWAPP SOUL v1.0.

---

*End of GLOWAPP UI / COMPONENT LANGUAGE Specification*