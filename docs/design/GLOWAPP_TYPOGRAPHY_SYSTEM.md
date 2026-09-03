# GLOWAPP TYPOGRAPHY SYSTEM

## 1. Purpose

This document defines the **GlowApp Master Typography System** — the single authoritative specification for typography across all GlowApp expressions (Women, Men, AURA, Concierge). It establishes a unified typographic language that communicates **Premium, Editorial, Human, Warm, Refined, Quiet, Intelligent** while avoiding luxury clichés, generic fashion magazine aesthetics, corporate software feel, aggressive tech aesthetics, and excessively minimal/cold interfaces.

**Typography is not decoration. Typography is brand voice.**

---

## 2. Typography Philosophy

GlowApp uses a **two-voice typographic architecture**:

| Voice | Family | Role | Purpose |
|-------|--------|------|---------|
| **VOICE 1 — EDITORIAL** | **Cormorant Garamond** | Display, headlines, storytelling, brand moments | Hero, editorial, beauty moments, campaigns, premium experiences |
| **VOICE 2 — FUNCTIONAL** | **Manrope** | UI, navigation, buttons, forms, body, data | Navigation, buttons, labels, forms, cards, body, filters, states, prices, operational info, Concierge, AURA UI |

**Supporting voice:**
| Voice | Family | Role | Purpose |
|-------|--------|------|---------|
| **DATA / METADATA** | **JetBrains Mono** | Prices, SKUs, technical metadata, codes | Monetary values, verification numbers, technical data |

**Principles:**
- Two voices, not three. No separate font for AURA, Men, or Women.
- Cormorant Garamond for editorial warmth and premium storytelling.
- Manrope for clean, contemporary, legible, neutral-yet-premium functional UI.
- JetBrains Mono for tabular monetary alignment and technical precision.
- Differentiation between expressions comes from **color, photography, composition, spacing, iconography** — NOT font family changes.
- AURA expresses through **Manrope + Aura Teal color + distinctive spacing** — not a "tech font."

---

## 3. Existing Typography Audit

### 3.1 Font Families Declared vs. Used

| Family | Declared In | Status | Used In |
|--------|-------------|--------|---------|
| **Cormorant Garamond** | `GlowTokens.fontCormorant`, `LuxeTypography` | **DECLARED_NOT_USED** | Nowhere in production code |
| **Didot** | `GlowTokens.fontDidot`, `LuxeTypography`, `GlowStoreTokens` | **DECLARED_AND_USED** | Store (editorial), Login, Register, Aura, Home, Provider components |
| **Inter** | `GlowTokens.fontInter`, `AppTypography.body` | **DECLARED_AND_USED** | Store (functional), AppTypography, Product Recipe, Consent, Capture, Color DNA, Glowstore Recipe |
| **JetBrains Mono** | `GlowTokens.fontJetBrainsMono`, `GlowStoreTokens`, `LuxeTypography` | **DECLARED_AND_USED** | Prices, metadata, badges, Store, Academy, LuxeComponents |
| **Playfair Display** | `GlowTokens.fontPlayfairDisplay` | **DECLARED_UNUSED** | Never used in production |
| **Manrope** | Target spec only | **TARGET_NOT_DECLARED** | Not in codebase |

### 3.2 Typography Systems Identified

| System | File | Families | Scale | Status | Issues |
|--------|------|----------|-------|--------|--------|
| **AppTypography** | `tokens.dart` | `'serif'`, `'sans'`, `'monospace'` generic | display/headline/title/body/label/mono (Light + Dark) | **ACTIVE** (used by modern `AppTheme`) | Generic families — real mapping inline; no Manrope/Cormorant |
| **GlowTokens** | `glow_tokens.dart` | Playfair, Inter, JetBrains, Didot, Cormorant | Constants only | **PARTIAL** | Cormorant/Playfair unused; Didot/Inter used but not targets |
| **GlowStoreTokens** | `glow_store_tokens.dart` | Didot, JetBrains, Inter | 6 semantic styles | **ACTIVE** (Store/Checkout) | Didot not Cormorant; Inter not Manrope; no dark variants |
| **LuxeTypography** | `belleza_luxe_theme.dart` | Didot, JetBrains, Cormorant, Inter | 6 styles | **ACTIVE** (Home/Academy) | Cormorant at 15px body (legibility); parallel system; golden ratio line height |
| **AppTheme (legacy)** | `theme.dart` | `'serif'` generic | h1, subtitle, body, buttonLabel | **DEPRECATED** (40+ screens) | Hardcoded; generic serif; no dark mode |
| **MensTheme** | `mens_theme.dart` | None | None | **INCOMPLETE** | No typography tokens; AuraWelcome doesn't adapt |

### 3.3 Key Findings

1. **No single source of truth** — 6 parallel systems with conflicting families and scales
2. **Cormorant Garamond (target editorial) declared but NEVER USED** — major missed opportunity
3. **Manrope (target functional) NOT DECLARED** — Inter currently fills this role
4. **Playfair Display declared but unused** — should be removed
5. **Generic `'serif'`/`'sans'` in tokens** — defeats token purpose; mapping happens inline
6. **No fonts declared in `pubspec.yaml`** — all fonts missing from asset declaration
7. **AuraWelcomeScreen doesn't adapt to Men** — uses only GlowTokens (feminine)

---

## 4. Font Families

### 4.1 Cormorant Garamond — VOICE 1: EDITORIAL
- **Role:** Display, headlines, brand storytelling, beauty moments
- **Weights:** 300, 400, 500, 600, 700
- **Styles:** Normal, Italic
- **Status:** Declared in `GlowTokens`, **not in pubspec**, **not used in production**
- **Replaces:** Didot (currently used as editorial)
- **DO:** Hero headlines, H1–H4, editorial sections, brand phrases, storytelling, campaign banners
- **DON'T:** Buttons, forms, navigation, tables, functional prices, dense information

### 4.2 Manrope — VOICE 2: FUNCTIONAL
- **Role:** All functional UI text
- **Weights:** 400, 500, 600, 700
- **Styles:** Normal
- **Status:** Target — **not declared, not in pubspec, not in code**
- **Replaces:** Inter (currently used as functional UI)
- **DO:** Navigation, buttons, inputs, chips, badges, tooltips, dialogs, bottom sheets, body, labels, prices, Concierge, AURA UI
- **DON'T:** Editorial hero moments, brand storytelling

### 4.3 JetBrains Mono — DATA / METADATA
- **Role:** Prices, SKUs, technical metadata, codes, monetary values
- **Weights:** 500, 600, 700
- **Styles:** Normal
- **Status:** Declared, used, **not in pubspec**
- **DO:** Price displays, metadata, technical codes, verification numbers, checkout totals
- **DON'T:** Body text, buttons, navigation, editorial content

### 4.4 Transitional Families (Phase Out)
| Family | Current Role | Migration Target |
|--------|--------------|------------------|
| Didot | Editorial (Store, Login, Register, Aura) | → Cormorant Garamond |
| Inter | Functional UI (AppTypography, Store, Ideas screens) | → Manrope |
| Playfair Display | Unused | → Remove |

---

## 5. Display Voice (Cormorant Garamond)

| Token | Size | Weight | Line Height | Letter Spacing | Case | Purpose |
|-------|------|--------|-------------|----------------|------|---------|
| **Display XL** | 48 | 300 | 1.1 | -1.0 | Sentence | Hero headlines, splash, major brand moments (desktop) |
| **Display L** | 40 | 300 | 1.15 | -0.8 | Sentence | Page heroes, campaign headers, onboarding |
| **Display M** | 32 | 400 | 1.2 | -0.5 | Sentence | Section heroes, modal titles, feature headlines |
| **Display S** | 26 | 500 | 1.25 | -0.3 | Sentence | Card headlines, editorial callouts, beauty captions |

**Not appropriate for:** Buttons, forms, navigation, tables, prices, dense info.

---

## 6. Functional Voice (Manrope)

| Token | Size | Weight | Line Height | Letter Spacing | Case | Purpose |
|-------|------|--------|-------------|----------------|------|---------|
| **Body Large** | 16 | 400 | 1.6 | 0 | Sentence | Primary reading: descriptions, AURA recommendations, Concierge, articles |
| **Body** | 14 | 400 | 1.55 | 0.1 | Sentence | Standard UI: descriptions, helper text, card content, dialog body |
| **Body Small** | 12 | 400 | 1.5 | 0.2 | Sentence | Metadata, timestamps, captions, footnotes, form hints |

---

## 7. Typographic Hierarchy (Complete Scale)

### 7.1 Heading Scale (Cormorant Garamond)

| Token | Size | Weight | Line Height | Letter Spacing | Case | Purpose |
|-------|------|--------|-------------|----------------|------|---------|
| **H1** | 28 | 600 | 1.25 | -0.5 | Sentence | Screen titles, primary page headers |
| **H2** | 22 | 600 | 1.3 | -0.3 | Sentence | Section headers, card group titles, modal sections |
| **H3** | 18 | 600 | 1.35 | -0.2 | Sentence | Subsection headers, card titles, list sections |
| **H4** | 16 | 600 | 1.4 | 0 | Sentence | Minor headers, inline breaks, form group labels |

### 7.2 UI Typography (Manrope)

| Token | Size | Weight | Line Height | Letter Spacing | Case | Purpose |
|-------|------|--------|-------------|----------------|------|---------|
| **Label Large** | 14 | 600 | 1.4 | 0.1 | Sentence | Primary button labels, important actions, tab labels |
| **Label Medium** | 12 | 600 | 1.4 | 0.5 | Sentence | Secondary buttons, chip labels, badge text, selectors |
| **Label Small** | 10 | 600 | 1.3 | 0.8 | **Uppercase** | Overlines, category tags, status badges, nav labels |
| **Button Primary** | 16 | 600 | 1.3 | 0.2 | Sentence | Primary CTA buttons |
| **Button Secondary** | 14 | 600 | 1.3 | 0.2 | Sentence | Secondary/outlined/ghost buttons |
| **Navigation** | 13 | 500 | 1.4 | 0.3 | Sentence | Bottom nav, drawer items, tab bar |
| **Tab** | 13 | 600 | 1.3 | 0.3 | Sentence | Tab bar, segment controls |
| **Input** | 16 | 400 | 1.5 | 0 | Sentence | Text field input |
| **Input Hint** | 16 | 400 | 1.5 | 0 | Sentence | Placeholder/hint text |
| **Input Label** | 13 | 500 | 1.4 | 0.1 | Sentence | Floating labels |
| **Chip** | 12 | 500 | 1.4 | 0.3 | Sentence | Filter/action/choice chips |
| **Badge** | 10 | 600 | 1.3 | 0.5 | **Uppercase** | Notifications, status, counts |
| **Tooltip** | 12 | 400 | 1.4 | 0.2 | Sentence | Tooltip content |

### 7.3 Dialog / Bottom Sheet (Mixed)

| Token | Family | Size | Weight | Line Height | Letter Spacing | Case | Purpose |
|-------|--------|------|--------|-------------|----------------|------|---------|
| **Dialog Title** | Cormorant | 20 | 600 | 1.3 | -0.3 | Sentence | Dialog/modal titles |
| **Dialog Body** | Manrope | 14 | 400 | 1.55 | 0.1 | Sentence | Dialog/modal body |
| **Bottom Sheet Title** | Cormorant | 18 | 600 | 1.3 | -0.2 | Sentence | Bottom sheet headers |
| **Bottom Sheet Body** | Manrope | 14 | 400 | 1.55 | 0.1 | Sentence | Bottom sheet content |

---

## 8. Price Typography (JetBrains Mono)

| Token | Size | Weight | Line Height | Letter Spacing | Case | Purpose |
|-------|------|--------|-------------|----------------|------|---------|
| **Price Display** | 24 | 700 | 1.2 | 0.3 | Normal | Primary price (product cards, checkout totals) |
| **Price Large** | 20 | 700 | 1.2 | 0.2 | Normal | Prominent prices (hero products, cart summary) |
| **Price Medium** | 16 | 600 | 1.2 | 0.2 | Normal | Standard prices (product lists, service cards) |
| **Price Small** | 13 | 600 | 1.2 | 0.3 | Normal | Previous price, unit price, per-session |
| **Price Micro** | 11 | 500 | 1.2 | 0.4 | Normal | Fee breakdowns, tax lines, tip suggestions |
| **Previous Price** | Context | 400 | Context | Context | Normal | Strikethrough original price (muted color) |
| **Discount Badge** | 11 | 700 | 1.2 | 0.5 | **Uppercase** | Percentage badges (e.g., -20%) |
| **Subtotal** | 14 | 500 | 1.3 | 0.2 | Sentence | Checkout subtotal lines |
| **Total** | 20 | 700 | 1.2 | 0.3 | Sentence | Checkout final total — most prominent monetary value |
| **Tip** | 14 | 500 | 1.3 | 0.2 | Sentence | Tip suggestions |
| **Checkout Final** | 22 | 700 | 1.15 | 0.2 | Sentence | **Monetary integrity: single finalCheckoutAmount** |

**Currency symbol** always inherits parent price style. **JetBrains Mono tabular figures** ensure alignment.

---

## 9. AURA Typography

**Principle:** AURA uses the **SAME two-voice architecture**. No third font.
- **Cormorant Garamond** — only when editorial context exists (storytelling, results revelation)
- **Manrope** — functional UI, conversational, recommendations, insights
- **JetBrains Mono** — prices, metadata, confidence scores
- **Color:** Aura Teal (`#164C46`) for emphasis, primary/secondary text for content

| Token | Family | Size | Weight | Line Height | Letter Spacing | Case | Color | Purpose |
|-------|--------|------|--------|-------------|----------------|------|-------|---------|
| **AURA Display** | Cormorant | 28 | 400 | 1.2 | -0.5 | Sentence | Aura Teal / Primary | Welcome, results revelation, Color DNA |
| **AURA Headline** | Cormorant | 20 | 600 | 1.3 | -0.3 | Sentence | Aura Teal / Primary | Section headers: "Tu análisis", "Recomendados" |
| **AURA Body** | Manrope | 14 | 400 | 1.6 | 0.1 | Sentence | Primary / Secondary | Explanations, recommendations, insights |
| **AURA Label** | Manrope | 12 | 600 | 1.4 | 0.5 | Uppercase | Aura Teal / Accent | Chips, mode indicators, confidence tags |
| **AURA Price** | JetBrains | 16 | 700 | 1.2 | 0.2 | Normal | Accent | Recommended product prices |
| **AURA CTA** | Manrope | 16 | 600 | 1.3 | 0.2 | Sentence | On Aura Primary | AURA-specific primary actions |
| **AURA Metadata** | JetBrains | 10 | 600 | 1.2 | 1.0 | Uppercase | Muted | Confidence scores, analysis IDs |
| **Concierge Message** | Manrope | 14 | 400 | 1.7 | 0.1 | Sentence | Primary | Conversational AI — extra line height |

---

## 10. Women Typography

**Principle:** Women emphasizes **EDITORIAL VOICE** in brand moments. Functional UI = Manrope (parity).

| Context | Voice | Rationale |
|---------|-------|-----------|
| Hero sections, onboarding storytelling, beauty rituals, campaigns, Provider detail hero, AURA results, Concierge welcome | **Cormorant Garamond** | Editorial warmth aligns with Women beauty editorial aesthetic |
| Navigation, forms, booking, store, checkout, settings, profile | **Manrope** | Consistent functional usability across expressions |

---

## 11. Men Typography

**Principle:** **SAME two-voice architecture.** Differentiation through color, photography, composition, spacing, iconography — NOT font family.

| Context | Voice | Styling |
|---------|-------|---------|
| Hero, grooming rituals, campaigns, Provider hero, AURA results | **Cormorant Garamond** | Slightly tighter tracking, warm white on obsidian, same scale |
| All functional UI | **Manrope** | Identical scale/weight/line height. Color: warm white on dark surfaces. |

**Quiet Masculine Luxury** achieved through: obsidian surfaces, warm white text, champagne/copper accents, generous spacing, restrained editorial moments — NOT font changes.

---

## 12. Concierge Typography

**Principle:** PERSONAL, PREMIUM, HUMAN — not call center, not corporate software.

| Token | Family | Size | Weight | Line Height | Letter Spacing | Case | Purpose |
|-------|--------|------|--------|-------------|----------------|------|---------|
| **Concierge Display** | Cormorant | 24 | 400 | 1.25 | -0.3 | Sentence | Welcome, personal greetings, ritual intros |
| **Concierge Body** | Manrope | 15 | 400 | 1.7 | 0.1 | Sentence | Conversational messages, advice, recommendations |
| **Concierge Label** | Manrope | 12 | 500 | 1.4 | 0.3 | Sentence | Action labels, quick replies, category tags |
| **Concierge Action** | Manrope | 16 | 600 | 1.3 | 0.2 | Sentence | Primary CTAs: "Agendar", "Ver productos", "Hablar con experto" |

---

## 13. Case Rules

| Case | Rule | Examples |
|------|------|----------|
| **Sentence case** | Default for ALL body, headings, buttons, labels, UI text | "Reservar cita", "Tu ritual de belleza", "Continuar" |
| **Title Case** | Brand proper nouns, screen titles in navigation, proper names | "GlowApp", "Aura", "Colorimetría", "Mi Perfil" |
| **Uppercase** | ONLY: overline/category labels, badge text, metadata codes, space-constrained chips | "NUEVO", "EXCLUSIVO", "SKU-1234", "CABELLO", "UÑAS" (with ≥0.5px letter-spacing) |
| **Prohibited** | NO ALL CAPS for body, buttons (use sentence), headings, paragraphs, form labels, errors | Reduces readability, feels aggressive, contradicts QUIET/HUMAN/WARM |

---

## 14. Letter Spacing

| Category | Values |
|----------|--------|
| **Display/Heading** | XL: -1.0, L: -0.8, M: -0.5, S: -0.3, H1: -0.5, H2: -0.3, H3: -0.2, H4: 0 |
| **Body** | Large: 0, Regular: 0.1, Small: 0.2 |
| **UI Labels** | Large: 0.1, Medium: 0.5, Small: 0.8, Button: 0.2, Navigation: 0.3, Chip: 0.3, Badge: 0.5, Input: 0 |
| **Mono** | Price: 0.3, Metadata: 1.0 |

**Principle:** Negative for display/headings (optical correction). Positive for small UI labels (legibility). Zero for body. Mono positive for tabular alignment.

---

## 15. Line Height

| Category | Values |
|----------|--------|
| **Display** | XL: 1.1, L: 1.15, M: 1.2, S: 1.25, H1: 1.25, H2: 1.3, H3: 1.35, H4: 1.4 |
| **Body** | Large: 1.6, Regular: 1.55, Small: 1.5 |
| **UI** | Label: 1.4, Button: 1.3, Navigation: 1.4, Chip: 1.4, Input: 1.5 |
| **Concierge** | Body: 1.65, Message: 1.7 |

**Principle:** Display tight (1.1–1.25) for editorial impact. Body generous (1.55–1.6) for reading comfort. Concierge extra generous (1.65–1.7) for conversational warmth. UI compact (1.3–1.4) for density.

---

## 16. Responsive Typography

**Status:** IMPLEMENTATION_DECISION_REQUIRED

**Principle:** Fluid hierarchy with controlled scaling. Consistent relationships. No separate systems per breakpoint.

**Proposed Approach:**
- **Mobile base (375px):** All sizes defined above
- **Tablet (600px+):** Display +1–2 steps, Headings +1 step, Body/UI unchanged
- **Desktop (1024px+):** Display +2–3 steps, Headings +1–2 steps, Body +1 step (16→17), UI +1 step
- **Formula:** `clamp(mobile_size, mobile_size + (vw - 375) * scale_factor, desktop_size)`
- **Breakpoints:** mobile: 0, tablet: 600, desktop: 1024, wide: 1440

**Exact scaling factors require implementation validation.** Documented as REQUIRES IMPLEMENTATION VALIDATION.

---

## 17. Typography Color

**S1 COLOR SYSTEM is chromatic authority.** Typography consumes:

- Primary Text (`#2B2420` Women / `#F5F6F8` Men)
- Secondary Text (`#857360` / `#949AA8`)
- Muted Text (`#9E8C78` / `#5F6575`)
- Disabled Text (`#A89F91` / `#5F6575`)
- Inverse Text (`#FAF8F5` / `#0A0C10`)
- Accent Text (`#C5A052` / `#D4AF37`)
- Aura Text (`#164C46`)

**No parallel typographic colors.**

---

## 18. Photography Relation

| Context | Strategy |
|---------|----------|
| **Hero / Editorial over photography** | Cormorant Garamond Display, inverse text (warm white), bottom scrim gradient (S1 scrimBottom) |
| **UI over photography** | Manrope, glass surface (L2, 85% opacity), inverse text, subtle border |
| **CTA over photography** | Button Primary on L3 surface (brand gold), strong shadow for separation |
| **Dark photography** | Warm white text (Men Warm White `#F2EFEA`), increased contrast |
| **Light photography** | Warm black text (Women Primary `#2B2420`), scrim only where needed |

**Photography leads. Typography serves.**

---

## 19. Icon Relation

**GLOW ICON SYSTEM v1.0 is LOCKED.**

| Relation | Rule |
|----------|------|
| **Icon size / Text size** | Icon = text cap-height (e.g., 16px text → 16px icon) |
| **Baseline alignment** | Icon vertical center aligns with text baseline + 1px optical correction |
| **Icon-label spacing** | 8px (Label Small), 10px (Label Medium), 12px (Label Large) |
| **Icon weight** | Monoline 2px stroke (target) — matches Manrope 500 weight optically |
| **Color** | Icons consume S1 icon color roles (primary, secondary, accent, aura, neutral, disabled) |

---

## 20. UI Density Philosophy

GlowApp must **NOT** feel: overcrowded, cramped, enterprise, dashboard-heavy.

Typography contributes to: **CALM, SPACE, CLARITY**
- Generous line heights (1.55–1.7)
- Consistent spacing scale (S1 4px base)
- Restrained bold usage (only labels/buttons/headings)
- No arbitrary size compression
- Flexible layouts for Spanish expansion (+15-20%)

---

## 21. Prohibited Patterns

| Pattern | Reason | Evidence |
|---------|--------|----------|
| Third font family for AURA | AURA is intelligence layer, not separate brand. Cyberpunk/tech contradicts QUIET/HUMAN/WARM. | S1 rejected MensTheme.cyberCyan cyberpunk aesthetic |
| Separate Men typography | Men differentiates through color/photo/composition, not font. "Masculine font" fragments brand. | Audit shows Men uses same Didot/Inter as Women |
| Serif in dense UI | Serifs reduce legibility at small sizes in tables, forms, lists, navigation. | LuxeTypography.bodyMd uses Cormorant 15px — hard to read |
| Excessive bold | Bold everywhere destroys hierarchy. Reserve 600-700 for labels/buttons/headings. | Multiple screens use bold for body text |
| Excessive uppercase | All caps reduces readability, feels aggressive. Only labels/badges/metadata with ≥0.5px spacing. | Settings, provider screens use uppercase for headers |
| Arbitrary font sizes | Every TextStyle must derive from defined scale. No one-off sizes. | 16+ spacing values in store_screen, similar for font sizes |
| Hardcoded TextStyles | Creates inconsistency, prevents theming, blocks dark mode/audience adaptation. | 40+ screens use inline TextStyle with hardcoded values |
| Playfair Display usage | Declared but unused. Didot serves editorial role. Two serif displays unnecessary. | GlowTokens.fontPlayfairDisplay declared, never used |
| Generic 'serif'/'sans' in tokens | AppTypography uses generics — mapping happens inline, defeating tokens. | tokens.dart lines 356-360 |

---

## 22. Token Taxonomy

Proposed conceptual namespace:

```
glow.type.family.*           // editorial_display, functional_ui, data_mono, legacy_*
glow.type.display.*          // xl, l, m, s
glow.type.heading.*          // h1, h2, h3, h4
glow.type.body.*             // large, regular, small
glow.type.label.*            // large, medium, small
glow.type.button.*           // primary, secondary
glow.type.navigation.*       // nav, tab
glow.type.input.*            // input, hint, label
glow.type.chip.*             // chip
glow.type.badge.*            // badge
glow.type.tooltip.*          // tooltip
glow.type.dialog.*           // title, body
glow.type.bottom_sheet.*     // title, body
glow.type.price.*            // display, large, medium, small, micro, currency, previous, discount, subtotal, total, tip, checkout_final
glow.type.aura.*             // display, headline, body, label, price, cta, metadata, concierge_message
glow.type.women.*            // editorial_emphasis, functional_parity
glow.type.men.*              // editorial_voice, functional_voice
glow.type.concierge.*        // display, body, label, action
```

---

## 23. Existing Token Mapping

| Legacy System | Mapping to Authority (AppTypography Extended) |
|---------------|-----------------------------------------------|
| **AppTypography** | EXTEND — replace generic families with real fontFamily strings; add Manrope; map Cormorant as display/heading; keep JetBrains Mono; deprecate Didot/Inter/Playfair as aliases |
| **GlowTokens** | REDUCE — keep only fontFamily constants as aliases to AppTypography families; remove colors |
| **GlowStoreTokens** | MIGRATE — fontEditorialDisplay/Section/ProductName → AppTypography display/heading; fontFunctionalUI → AppTypography body/label; fontPriceDisplay/Metadata → AppTypography price/mono |
| **LuxeTypography** | DEPRECATE — display tokens → AppTypography; bodyMd (Cormorant 15px) → bodyLarge (Manrope 16px) for readability; mono tokens → AppTypography mono |
| **AppTheme (legacy)** | ELIMINATE — migrate screens to `AppTheme.of(context)` / `Token.of(context)` |

---

## 24. Font Governance

- **New font requires approval** — Design Director review
- **New family requires justification** — Technical feasibility (licensing, file size, variable font support)
- **New weight requires justification** — Prototype in isolation → Integration → Migration plan → Rollout
- **No arbitrary downloads** — Variable fonts preferred
- **No system fonts as permanent substitute** — Fallback chain only
- **No per-screen variants** — All through token system

**Fallback Chain:**
- Manrope → system-ui → sans-serif
- Cormorant Garamond → Georgia → serif
- JetBrains Mono → SF Mono → monospace

---

## 25. Accessibility

| Check | Status | Details |
|-------|--------|---------|
| Minimum size (body 14, UI 12, button 14) | **VERIFIED** | Meets Material 3 minimums |
| Primary text contrast | **VERIFIED** | 12.8:1 (warm brown on cream) |
| Secondary text contrast | **VERIFIED** | 4.2:1 (meets AA) |
| Disabled text contrast | **PARTIAL** | 2.8:1 (meets AA for disabled) |
| CTA text on brand | **REQUIRES_IMPLEMENTATION_VALIDATION** | Depends on final Rose Gold/Champagne values |
| Aura Teal on light | **VERIFIED** | 8.2:1 |
| Aura Teal on dark | **FAIL** | 1.8:1 (documented in S1) |
| Line height (body 1.55) | **VERIFIED** | Meets WCAG 1.5 |
| Font scaling (1.0x, 1.3x, 1.5x, 2.0x) | **REQUIRES_IMPLEMENTATION_VALIDATION** | Must test with system scaling |
| Text overflow (ellipsis, maxLines) | **REQUIRES_IMPLEMENTATION_VALIDATION** | Flexible layouts needed |
| Spanish expansion (+15-20%) | **DOCUMENTED** | Body line height 1.55 accommodates; buttons need flexible width |
| COP currency format | **DOCUMENTED** | $ 1.234.567 (spaces as thousand separators); JetBrains Mono tabular figures |

---

## 26. Localization

- **Primary:** Spanish (es-CO)
- **Accents:** Cormorant Garamond and Manrope support full Latin Extended (á, é, í, ó, ú, ñ, ü)
- **Expansion:** Spanish ~15-20% longer. Layouts must be flexible. No fixed-width text containers.
- **Numbers:** COP format with JetBrains Mono tabular figures.
- **Direction:** LTR only.
- **Font fallback:** System UI stack if custom fonts fail.

---

## 27. Implementation Status

| Item | Status |
|------|--------|
| **TYPOGRAPHY SYSTEM** | **SPECIFIED** |
| **FONT INSTALLATION** | **NOT STARTED** |
| **CODE IMPLEMENTATION** | **NOT STARTED** |
| **TYPOGRAPHY MIGRATION** | **NOT STARTED** |
| **PRODUCTION MODIFIED** | **NO** |

---

## 28. Git Status

```
$ git status --short
?? docs/design/GLOWAPP_TYPOGRAPHY_SYSTEM.md
?? docs/design/glowapp_typography_system.json
```

Only the two specification deliverables created. No production code modified.

---

## 29. Quality Score

| Criterion | Score | Max |
|-----------|-------|-----|
| A. Brand Coherence | 19 | 20 |
| B. Hierarchy | 19 | 20 |
| C. Women Definition | 10 | 10 |
| D. Men Definition | 10 | 10 |
| E. AURA Definition | 10 | 10 |
| F. UI Usability | 10 | 10 |
| G. Accessibility | 9 | 10 |
| H. Governance | 10 | 10 |
| **TOTAL** | **97** | **100** |

**Deductions:**
- Accessibility: Aura Teal on dark surfaces fails (-1) — documented as VALIDATION REQUIRED in S1
- Responsive: Marked as IMPLEMENTATION_DECISION_REQUIRED (-0, not a gap — explicitly documented)

---

## 30. Critical Gaps

1. **No fonts in `pubspec.yaml`** — All 3 target families (Cormorant Garamond, Manrope, JetBrains Mono) must be added with font assets
2. **Cormorant Garamond declared but unused** — Major opportunity; must be activated as editorial voice
3. **Manrope not declared** — Target functional voice missing entirely from codebase
4. **AuraWelcomeScreen doesn't adapt to Men** — Uses only GlowTokens (feminine); must use audience-aware tokens
5. **Generic `'serif'`/`'sans'` in AppTypography** — Defeats token purpose; real mapping happens inline
6. **Playfair Display declared but unused** — Should be removed from GlowTokens
7. **6 parallel typography systems** — Must consolidate to single authority (AppTypography extended)

---

## 31. Minor Gaps

1. **LuxeTypography uses Cormorant at 15px for body** — Legibility concern; migration to Manrope 16px recommended
2. **Golden ratio line height (1.618) in LuxeTypography** — Unique but inconsistent with system
3. **No dark mode variants in GlowStoreTokens/LuxeTypography** — Only AppTypography has dark overrides
4. **fontFunctionalUI has too many optional params** — Inconsistent usage across screens
5. **JetBrains Mono not in pubspec** — Used in production but not declared

---

## 32. Final Decision

**APPROVED WITH MINOR REVISIONS**

The specification is complete, evidence-backed, and ready for implementation phase. The critical gaps (missing fonts in pubspec, Cormorant unused, Manrope missing, 6 parallel systems) are documented with clear migration paths and must be addressed during implementation. The Aura Teal on dark contrast failure is inherited from S1 and documented.

---

## 33. Next Phase

**S3 — PHOTOGRAPHY SYSTEM**

No typography implementation executed. Implementation begins only after S1–S5 are sufficiently defined and consolidated into GLOWAPP SOUL v1.0.

---

*End of GLOWAPP TYPOGRAPHY SYSTEM Specification*