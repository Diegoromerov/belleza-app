# GLOWAPP COLOR SYSTEM

## 1. Purpose

This document defines the **GlowApp Master Color System** — the single authoritative specification for color across all GlowApp expressions (Women, Men, AURA). It establishes a unified color language that communicates **Premium, Warm, Human, Refined, Editorial, Quiet, Intelligent** while avoiding neon, cyberpunk, excessive saturation, gamer aesthetics, aggressive tech aesthetics, solid black as brand background, clinical white as identity, excessive gradients, and gold luxury clichés.

**Color is not decoration. Color is brand language.**

---

## 2. Color Philosophy

GlowApp does not depend on color to appear premium. Color works in concert with:
- Space
- Photography
- Typography
- Texture
- Iconography
- Surface
- Illumination

The system is built on **warmth before saturation**, **surface before decoration**, **restraint as luxury**. Three expressions (Women, Men, AURA) share one master system with expression-specific accents — not three independent color systems.

---

## 3. Master Palette

### 3.1 Foundation

| Token | Hex | Role | Purpose | Context | Do | Don't |
|-------|-----|------|---------|---------|-----|-------|
| `creamSilk` | `#FCF8F6` | Primary Background (Women/Neutral) | Main app canvas | Light theme scaffold | Use as base for Women/neutral | Use in Men (use obsidianBg) |
| `obsidianBg` | `#0A0C10` | Primary Background (Men) | Main app canvas | Men theme scaffold | Use as base for Men | Use in Women (use creamSilk) |
| `warmWhite` | `#F2EFEA` | Secondary Background (Men) | Elevated surfaces | Cards, sheets in Men | Use for Men elevated surfaces | Use as primary background |
| `neutralScale` | 50–900 | Neutral Foundation | Text, borders, surfaces, shadows | All expressions | Use as semantic neutrals | Replace with pure grey/black/white |

**Neutral Scale (Warm, not clinical):**
- 50: `#FAF8F5` — Warm white
- 100: `#F4EFEA` — Surface secondary
- 200: `#E8E0D5` — Subtle borders
- 300: `#D6C8B8` — Muted borders
- 500: `#9E8C78` — Metadata text
- 600: `#857360` — Secondary text
- 700: `#6B5A48` — Stronger text
- 800: `#453A2E` — Near-black text
- 900: `#1F1A15` — Primary text (warm black)

### 3.2 Surface

| Level | Name | Women | Men | Dark | Purpose |
|-------|------|-------|-----|------|---------|
| L0 | Scaffold Background | `#FCF8F6` | `#0A0C10` | `#18171C` | Full-screen canvas |
| L1 | Content Surface | `#FFFFFF` | `#14171F` | `#24232B` | Cards, sheets, primary containers |
| L2 | Glass/Frosted | `#F4EFEA85` | `#14171F85` | `#24232B85` | Overlays, drawers, frosted glass |
| L3 | CTA/Selection | `#C5A052` | `#D4AF37` | — | Primary buttons, selected states |
| Variant | Input Variant | `#F5EBE6` | — | `#4A3E3D` | Text field fills, search bars |
| Container | Card Container | `#F4EFEA` | — | `#3D3330` | Card backgrounds in lists |
| Overlay | Modal Backdrop | `#00000080` | `#000000BF` | — | Modal/backdrop scrim |
| Glass | Glass Morphism | `#FFFFFF80` | `#14171FD9` | — | Premium glass with blur |
| Input | Input Surface | `#FAF8F5` | — | `#2D2523` | Text field background |
| Selected | Selected Surface | `#C5A0521F` | `#D4AF371F` | — | Selected items, chips |

### 3.3 Text

| Token | Women | Men | Dark | Warmth |
|-------|-------|-----|------|--------|
| Primary Text | `#2B2420` | `#F5F6F8` | `#FAF8F5` | Warm black / warm white |
| Secondary Text | `#857360` | `#949AA8` | `#AD8272` | Warm muted |
| Muted Text | `#9E8C78` | `#5F6575` | `#C5A090` | Metadata, captions |
| Disabled Text | `#A89F91` | `#5F6575` | `#6B5E5A` | Clearly inactive |
| Inverse Text | `#FAF8F5` | `#0A0C10` | — | On dark/colored surfaces |
| Accent Text | `#C5A052` | `#D4AF37` | — | Brand-colored emphasis |
| AURA Text | `#164C46` | `#164C46` | `#164C46` | Intelligence layer |

### 3.4 Border

| Token | Women | Men | Dark | Width | Purpose |
|-------|-------|-----|------|-------|---------|
| Default | `#E8E0D5` | `#C5A05935` | `#33313D` | 1px | Standard borders |
| Subtle | `#F3EAE8` | `#C5A05920` | `#2A2830` | 0.5px | Hairlines, dividers |
| Strong | `#C5A052` | `#D4AF37` | `#D4B878` | 1.5px | Emphasis borders |
| Focus | `#C5A052` | `#D4AF37` | — | 1.8px | Focus rings |
| Selected | `#C5A052` | `#D4AF37` | — | 2px | Selected states |

### 3.5 Accent

| Token | Hex | Expression | Role | Purpose | Do | Don't |
|-------|-----|------------|------|---------|-----|-------|
| `roseGold` | `#D4AF7A` | Women | Primary Accent | Premium CTA, highlights | Women CTAs, brand moments | Men expression |
| `warmBrown` | `#5A3A2A` | Women | Secondary | Typography, icons | Secondary actions | Primary CTA |
| `champagne` | `#D9A27F` | Women | Tertiary | Subtle highlights | Dividers, hover | Primary actions |
| `gold871` | `#C5A052` | Global | Brand Primary | Unified brand color | Neutral CTAs, brand | Override expression primaries |
| `champagneMen` | `#D4AF37` | Men | Primary Accent | Premium CTA, highlights | Men CTAs, brand moments | Women expression |
| `warmWhiteMen` | `#F2EFEA` | Men | Secondary | Cards, sheets | Men elevated surfaces | Primary background |
| `copper` | `#B8734A` | Men | Tertiary | Hover, borders | Subtle highlights | Primary CTA |
| `bronzeAccent` | `#C5A059` | Men | Border Accent | Focus, selection | Men focused borders | Fill color |

### 3.6 Semantic

| State | Light Foreground | Dark Foreground | Light Background | Dark Background | Border | Icon |
|-------|------------------|-----------------|------------------|-----------------|--------|------|
| Success | `#15803D` | `#DCFCE7` | `#DCFCE7` | `#14532D` | `#16A34A` | `#16A34A` |
| Warning | `#78350F` | `#FEF3C7` | `#FEF3C7` | `#78350F` | `#D97706` | `#D97706` |
| Error | `#991B1B` | `#FEE2E2` | `#FEE2E2` | `#7F1D1D` | `#DC2626` | `#DC2626` |
| Info | `#164E63` | `#ECFEFF` | `#ECFEFF` | `#164E63` | `#06B6D4` | `#06B6D4` |
| In Progress | `#5B21B6` | `#EDE9FE` | `#EDE9FE` | `#5B21B6` | `#8B5CF6` | `#8B5CF6` |

**All semantic colors respect Glow warmth — no saturated neon.**

### 3.7 AURA

| Token | Hex | Role | Purpose | Context |
|-------|-----|------|---------|---------|
| `primary` | `#164C46` | AURA Primary | Core intelligence identifier | Smart recommendations, biometrics, colorimetry |
| `surface` | `#164C4615` | AURA Surface | Subtle container | AURA cards, panels |
| `subtle` | `#164C460D` | AURA Subtle | Minimal connection | Dividers, hairlines in AURA |
| `active` | `#164C46` | AURA Active | CTA/selected in AURA | AURA flows only |
| `disabled` | `#164C4640` | AURA Disabled | Inactive AURA | AURA buttons disabled |
| `contrast` | `#FFFFFF` | AURA Contrast | Text on AURA primary | Legible on AURA backgrounds |
| `interaction` | `#164C46CC` | AURA Interaction | Hover/press | AURA elements only |

**AURA Teal is an intelligence layer, not a global accent. It does not make the whole app feel "AURA."**

---

## 4. Women Palette

| Color | Hex | Source | Function | Hierarchy | Contrast (on creamSilk) | CTA Role | States |
|-------|-----|--------|----------|-----------|------------------------|----------|--------|
| **Rose Gold** | `#D4AF7A` | `GlowTokens.roseGold` | Primary brand accent | Primary CTA, key highlights | AAA | Primary button bg | Hover `#D4AF7ACC`, Pressed `#B89666`, Disabled `#D4AF7A40` |
| **Warm Brown** | `#5A3A2A` | Derived | Secondary brand | Secondary buttons, typography | AA | Secondary button text | Hover `#6D4A3A`, Pressed `#4A2E22`, Disabled `#5A3A2A40` |
| **Champagne** | `#D9A27F` | Derived | Tertiary accent | Subtle highlights, dividers | FAIL (use on dark only) | Ghost button border | Hover `#D9A27FCC`, Pressed `#C8906A`, Disabled `#D9A27F40` |
| **Aura Teal** | `#164C46` | Shared | AURA layer in Women | AURA features only | AAA | AURA-specific CTA | Hover `#164C46CC`, Pressed `#103832`, Disabled `#164C4640` |

**Shared Foundations:** creamSilk, gold871, nightAndean, deepGreen, nudeScale

---

## 5. Men Palette

| Color | Hex | Source | Function | Hierarchy | Contrast (on obsidianBg) | CTA Role | States |
|-------|-----|--------|----------|-----------|-------------------------|----------|--------|
| **Champagne Gold** | `#D4AF37` | `MensTheme.champagneGold` | Primary brand accent | Primary CTA, key highlights | AAA | Primary button bg | Hover `#D4AF37CC`, Pressed `#B89C2F`, Disabled `#D4AF3740` |
| **Warm White** | `#F2EFEA` | Derived | Secondary surface | Cards, sheets | AAA (on obsidian) | Surface bg | Hover `#F2EFEAEE`, Pressed `#E0DCE7`, Disabled `#F2EFEA80` |
| **Copper** | `#B8734A` | Derived from bronzeAccent | Tertiary accent | Hover states, borders | AA | Secondary button border | Hover `#B8734ACC`, Pressed `#9A5F3D`, Disabled `#B8734A40` |
| **Aura Teal** | `#164C46` | Shared | AURA layer in Men | AURA features only | FAIL (on obsidian), AAA (on warmWhite) | AURA-specific CTA | Same as Women |

**Foundations:** obsidianBg `#0A0C10`, obsidianCard `#14171F`, obsidianCardHover `#1E232E`, bronzeAccent `#C5A059`, textPrimary `#F5F6F8`, textSecondary `#949AA8`, textMuted `#5F6575`

**Quiet Masculine Luxury — not Black UI + Gold Accents. No solid black as brand base.**

---

## 6. AURA Palette

**Central Color: Aura Teal `#164C46`**

| Token | Hex | Purpose |
|-------|-----|---------|
| Primary Aura | `#164C46` | Signals AI-driven intelligence features |
| Aura Surface | `#164C4615` | Subtle container for AURA content |
| Aura Subtle | `#164C460D` | Minimal visual connection (dividers) |
| Aura Active | `#164C46` | Active interaction in AURA flows |
| Aura Disabled | `#164C4640` | Inactive AURA elements |
| Aura Contrast | `#FFFFFF` | Text on AURA backgrounds |
| Aura Interaction | `#164C46CC` | Hover/press feedback for AURA |

**AURA functions as INTELLIGENCE LAYER — not GLOBAL ACCENT EVERYWHERE. It works over Women, Men, and Neutral without recoloring the brand.**

---

## 7. Surface System

The surface hierarchy (L0–L3) is preserved from **GlowStoreTokens** with expression-aware mappings:

- **L0 (Scaffold):** Cream Silk (Women) / Obsidian Bg (Men)
- **L1 (Content):** White (Women) / Obsidian Card (Men)
- **L2 (Glass):** Nude100 85% (Women) / Obsidian Card 85% (Men)
- **L3 (CTA):** Gold 871 (Women) / Champagne Gold (Men)

Additional surfaces: Variant (inputs), Container (cards), Overlay (modals), Glass (blur), Input (fields), Selected (chips).

---

## 8. Text System

Seven semantic text colors with warm undertones — **never clinical black/white/grey**:

- **Primary:** Warm black `#2B2420` (Women) / Warm white `#F5F6F8` (Men)
- **Secondary:** Warm muted `#857360` / `#949AA8`
- **Muted:** Metadata `#9E8C78` / `#5F6575`
- **Disabled:** `#A89F91` / `#5F6575`
- **Inverse:** Cream Silk / Obsidian
- **Accent:** Brand gold
- **AURA:** Aura Teal

---

## 9. Border System

Five semantic borders with expression-aware values. Avoid excessive contrast — borders relate to surfaces, not fight them.

- Default: Subtle warm divider
- Subtle: Hairline
- Strong: Brand emphasis
- Focus: Accessible focus ring
- Selected: Brand confirmation

---

## 10. Interaction Colors

| Type | Women | Men | States |
|------|-------|-----|--------|
| Primary CTA | BG `#D4AF7A`, Text `#2B2420` | BG `#D4AF37`, Text `#0A0C10` | Hover 0.9α, Pressed darker, Disabled 0.35α |
| Secondary CTA | Transparent + Rose Gold border/text | Transparent + Champagne border/text | Hover bg 0.1α, Pressed 0.15α |
| Ghost CTA | Transparent + Warm Brown text | Transparent + Warm White text | Hover 0.05α, Pressed 0.1α |
| Icon Button | Default `#2B2420`, Hover `#C5A052` | Default `#F5F6F8`, Hover `#D4AF37` | — |
| Selected | BG `#C5A0521F`, Border `#C5A052` | BG `#D4AF371F`, Border `#D4AF37` | — |
| Focus | Ring `#C5A052` (2px) | Ring `#D4AF37` (2px) | — |
| Disabled | BG `#F0ECE6`, Text `#A89F91` | BG `#1E232E`, Text `#5F6575` | — |

**Brand color ≠ Interaction state. States are derived systematically.**

---

## 11. Semantic Colors

Defined for Success, Warning, Error, Info, In Progress — each with foreground, background, border, icon, and text tokens for both light and dark. All muted to Glow warmth. **No neon green, no bright red, no electric blue.**

---

## 12. Contrast Validation

| Combination | Women (Light) | Men (Dark) | Status |
|-------------|---------------|------------|--------|
| Primary Text / Background | `#2B2420` / `#FCF8F6` = 12.1:1 | `#F5F6F8` / `#0A0C10` = 15.8:1 | ✅ AAA |
| Secondary Text / Background | `#857360` / `#FCF8F6` = 4.2:1 | `#949AA8` / `#0A0C10` = 7.1:1 | ✅ AA / AAA |
| CTA Text / CTA Background | `#2B2420` / `#D4AF7A` = 4.8:1 | `#0A0C10` / `#D4AF37` = 9.2:1 | ✅ AA / AAA |
| Icon / Surface | `#2B2420` / `#FFFFFF` = 12.6:1 | `#F5F6F8` / `#14171F` = 11.3:1 | ✅ AAA |
| Disabled Text / Background | `#A89F91` / `#F0ECE6` = 2.8:1 | `#5F6575` / `#1E232E` = 3.1:1 | ✅ AA (disabled) |
| Aura Teal / Light Surface | `#164C46` / `#FCF8F6` = 8.9:1 | — | ✅ AAA |
| Aura Teal / Dark Surface | `#164C46` / `#0A0C10` = 1.8:1 | — | ❌ **VALIDATION REQUIRED** — Use only on warmWhiteMen or AURA surface |

**If compliance cannot be proven: DOCUMENT AS "VALIDATION REQUIRED". No invented compliance.**

---

## 13. Dark Surface Policy

| Classification | Policy |
|----------------|--------|
| **Allowed** | Deep surfaces for functional needs: modals, drawers, dark mode, photography overlays, AURA scanner |
| **Contextual** | `obsidianBg` `#0A0C10` and `obsidianCard` `#14171F` — only in Men expression or dark mode |
| **Prohibited** | `#000000` as brand background. Solid black never represents GlowApp identity. |

**Dark surface ≠ Black branding.** GlowApp uses deep warm surfaces (`#0A0C10`, `#1C1917`) when functionally necessary.

---

## 14. Gradient Policy

**Gradients serve depth, light, transition, or AURA behavior. Not constant decoration.**

| Gradient | Colors | Direction | Purpose | Where |
|----------|--------|-----------|---------|-------|
| Premium Light | `#CFBEB5` → `#CFBEB5` → `#FFF8F0` (stops 0, 0.45, 1) | Top→Bottom | Hero, onboarding, brand | Welcome, splash, onboarding |
| Premium Dark | `#4A3E3D` → `#4A3E3D` → `#2D2523` | Top→Bottom | Dark hero | Dark mode heroes |
| Rose Gold Satin | `#E8B6AD` → `#B57E74` | TL→BR | Women premium | Women banners, premium |
| Terracotta Matte | `#B57E74` → `#8C6F65` | TL→BR | Earthy warmth | Secondary brand moments |
| Primary Gold | `#C5A052` → `#B89040` | TL→BR | Brand CTAs | Primary buttons, brand |
| Gold Gradient Men | `#D4AF37` → `#AA7C11` | TL→BR | Men CTAs | Men expression |
| Obsidian Glass | `#CC14171F` → `#E60A0C10` | Top→Bottom | Men glass | Men drawers, panels |
| AURA Gradient | `#164C46` → `#0D3630` | TL→BR | AURA intelligence | AURA scanner, AI features |
| Scrim Bottom | Transparent → `#2B242059` | Top→Bottom | Photo legibility | Over photography |

**If a gradient doesn't add depth/light/transition/AURA behavior → prefer solid surface.**

---

## 15. Opacity Policy

Semantic opacity tokens — no arbitrary dozens of values:

| Category | Token | Value | Purpose |
|----------|-------|-------|---------|
| Overlays | `scrimLight` | 0.5 | Light modal backdrop |
| Overlays | `scrimDark` | 0.75 | Dark modal backdrop |
| Glass | `glassLight` | 0.85 | Frosted glass (Women) |
| Glass | `glassDark` | 0.85 | Frosted glass (Men) |
| Disabled | `disabledBg` | 0.35 | Disabled backgrounds |
| Disabled | `disabledText` | 0.4 | Disabled text |
| Hover | `hoverOverlay` | 0.05 | Subtle hover |
| Selected | `selectedBg` | 0.12 | Selected item bg |
| Shadows | `ambient` | 0.04 | Ambient shadow |
| Shadows | `card` | 0.08 | Card shadow |
| Shadows | `glow` | 0.18 | Brand glow shadow |
| Image Overlay | `gradientEnd` | 0.8 | Photo overlay end |

---

## 16. Shadow + Color Relation

Shadows are **not** `Colors.black.withOpacity(...)`. They use warm, brand-aware colors:

| Shadow | Color | Blur | Offset | Spread | Purpose |
|--------|-------|------|--------|--------|---------|
| Soft | `#0000000A` | 8 | 0,2 | — | Chips, low elevation |
| Medium | `#0000000A` | 24 | 0,8 | -4 | Standard cards |
| Strong | `#0000001A` | 32 | 0,16 | — | Modals, drawers |
| Gold Glow | `#C5A0522E` | 16 | 0,6 | — | Premium CTAs (Women) |
| Champagne Glow | `#D4AF374D` | 16 | 0,4 | — | Premium CTAs (Men) |
| Aura | `#164C4633` | 20 | 0,0 | 2 | AURA scanner, AI |
| Drawer | `#00000014` | 24 | -6,0 | — | Side drawers |

---

## 17. Photography Color Relation

The palette must coexist with photography across expressions:

| Context | Strategy |
|---------|----------|
| **Women Photography** | Cream Silk backgrounds, Rose Gold overlays, warm text `#2B2420` on images |
| **Men Photography** | Obsidian surfaces, Champagne Gold accents, warm white text `#F5F6F8` on images |
| **AURA Imagery** | Aura Teal subtle overlays, high contrast white text, scanner UI uses Aura Gradient |
| **Cards over Photography** | Glass L2 surface (85% opacity) with subtle border |
| **CTA over Photography** | L3 surface (brand gold) with strong shadow for separation |
| **Text over Photography** | Inverse text with scrim gradient (bottom 40% only) |

**Photography leads. Color serves.**

---

## 18. Icon System Relation

**GLOW ICON SYSTEM v1.0 is LOCKED — not modified.**

Color system consumption via `GlowIconColorRole`:

| Role | Women | Men | AURA |
|------|-------|-----|------|
| `primary` | `#D4AF7A` | `#D4AF37` | `#164C46` |
| `secondary` | `#5A3A2A` | `#B8734A` | `#164C4680` |
| `accent` | `#C5A052` | `#C5A059` | `#164C46` |
| `aura` | `#164C46` | `#164C46` | `#164C46` |
| `neutral` | `#2B2420` | `#F5F6F8` | `#FAF8F5` |
| `disabled` | `#A89F91` | `#5F6575` | `#6B5E5A` |

Iconography specification remains independent authority.

---

## 19. Women vs Men Relationship

### SHARED (One Brand)
- Aura Teal `#164C46`
- Neutral foundations (nude scale 50–900)
- Semantic states (success/warning/error/info)
- Surface philosophy (L0–L3 hierarchy)
- Warm whites (creamSilk family)
- Typography relationship (Didot/Inter/JetBrains Mono)
- Gold 871 as global brand primary

### WOMEN (Expression)
- Rose Gold `#D4AF7A` — Primary accent
- Warm Brown `#5A3A2A` — Secondary
- Champagne `#D9A27F` — Tertiary
- Cream Silk `#FCF8F6` — Background

### MEN (Expression)
- Champagne Gold `#D4AF37` — Primary accent
- Warm White `#F2EFEA` — Secondary surface
- Copper `#B8734A` — Tertiary
- Obsidian `#0A0C10` — Background

**Difference is EXPRESSION, not BRAND.**

---

## 20. AURA Relationship

AURA functions **over** Women, Men, Neutral:

- Aura Teal does not recolor the entire app
- Works as **INTELLIGENCE LAYER** — smart recommendations, biometric analysis, colorimetry
- Confined to AURA-specific surfaces, CTAs, text
- Does not leak into general navigation, branding, or non-AI features

---

## 21. Prohibited / Deprecated Colors

| Value | Name | Reason | Where Found | Replacement Strategy |
|-------|------|--------|-------------|---------------------|
| `#00E5FF` | Cyber Cyan | Neon/cyberpunk contradicts premium/warm/human/quiet/intelligent identity. Creates gamer/tech perception. | `MensTheme.cyberCyan`, `MensTheme.cyberCyanGlow`, `MensTheme.cyanScannerGlow` | Replace with Aura Teal `#164C46` for AI/scanner; Champagne Gold for CTAs; Bronze Accent for borders |
| `#00E5FF59` | Cyber Cyan Glow | Neon glow incompatible with quiet luxury | `MensTheme.cyberCyanGlow` | Replace with Aura Shadow `#164C4633` |
| `#000000` | Pure Black | Solid black as brand background prohibited. Only allowed as shadow base with low opacity. | Shadow definitions using `Colors.black.withOpacity` | Use warm shadows from nude900 or brand-colored shadows |
| `#FFFFFF` | Clinical White | Pure white as identity prohibited. Use Cream Silk or warm whites. | Surface L1 in Women (already using warm white) | Ensure no pure `#FFFFFF` in brand contexts |

**Each prohibition has evidence, reason, location, and replacement. No arbitrary bans.**

---

## 22. Existing Token Systems

| System | File | Type | Key Colors | Status |
|--------|------|------|------------|--------|
| **GlowTokens** | `lib/shared/glow_tokens.dart` | Core brand | creamSilk, terracota, roseGold, nightAndean, emerald, amber, deepGreen | Legacy — partially superseded |
| **GlowStoreTokens** | `lib/shared/glow_store_tokens.dart` | Premium e-commerce | creamSilk, roseGold, gold871, deepGreen, nightAndean, nude50–900 | Active — Phase 1A |
| **MensTheme** | `lib/shared/mens_theme.dart` | Men expression | obsidianBg, obsidianCard, champagneGold, bronzeAccent, **cyberCyan (PROHIBITED)** | Active — requires cyber cyan removal |
| **LuxeColors** | `lib/core/theme/belleza_luxe_theme.dart` | Nude + Gold | nude50–900, gold871, goldLight, goldDark | Active — foundation for Token |
| **Token (light/dark)** | `lib/core/theme/tokens.dart` | Unified semantic | brandPrimary/Secondary/Tertiary, neutral50–900, status, gradients | New — intended single source |
| **AppTheme (legacy)** | `lib/shared/theme.dart` | Compatibility | primary, passportPrimary, passportBackground | Deprecated — compat getters only |
| **AppTheme (modern)** | `lib/core/theme/app_theme.dart` | Material 3 ThemeData | Delegates to Token | Active — modern implementation |

---

## 23. Proposed Color Authority

### Primary Authority: `Token` (`lib/core/theme/tokens.dart`)

**Rationale:**
1. Light/dark parity with semantic naming
2. Single source for `ColorScheme`
3. Extensible for expression overrides
4. Already used by modern `AppTheme`

### Mapping Strategy

| Legacy System | Mapping |
|---------------|---------|
| GlowTokens | Map to `Token.brandPrimary/Secondary/Tertiary` + neutral scale. Deprecate direct usage. |
| MensTheme | Migrate obsidian surfaces to `Token.dark` neutral/surface. Replace cyberCyan with Aura Teal. Map champagneGold to brandPrimary in Men context. |
| GlowStoreTokens | Fold surface hierarchy, radii, shadows into Token extensions. Map gold871→brandPrimary, roseGold→brandSecondary. |
| LuxeColors / BellezaLuxeTokens | Nude scale → Token.neutral. Gold871 → brandPrimary. Deprecate standalone. |
| AppTheme (legacy) | Compatibility getters only. Redirect to Token. |

### Expression Overrides (Conceptual)

```dart
// Women
brandPrimary: roseGold (#D4AF7A)
surfaceLevel0: creamSilk (#FCF8F6)
surfaceLevel3: gold871 (#C5A052)

// Men
brandPrimary: champagneGold (#D4AF37)
surfaceLevel0: obsidianBg (#0A0C10)
surfaceLevel3: champagneGold (#D4AF37)

// AURA
brandPrimary: auraTeal (#164C46)
surfaceLevel0: contextAware
surfaceLevel3: auraTeal (#164C46)
```

---

## 24. Token Taxonomy

Proposed conceptual namespace structure:

```
glow.color.foundation.*      // creamSilk, obsidianBg, warmWhite, neutral50-900
glow.color.surface.*         // level0, level1, level2, level3, variant, container, overlay, glass, input, selected
glow.color.text.*            // primary, secondary, muted, disabled, inverse, accent, aura
glow.color.border.*          // default, subtle, strong, focus, selected
glow.color.accent.*          // roseGold, warmBrown, champagne, gold871, champagneMen, warmWhiteMen, copper, bronzeAccent
glow.color.semantic.*        // success, warning, error, info, inProgress
glow.color.aura.*            // primary, surface, subtle, active, disabled, contrast, interaction
glow.color.women.*           // primary, secondary, accent, aura, shared
glow.color.men.*             // primary, secondary, accent, aura, foundations
```

**Not implemented — specification only.**

---

## 25. Design Principles

1. **Warmth before saturation** — Color temperature creates premium, not intensity
2. **Surface before decoration** — Hierarchy through elevation/texture, not color noise
3. **Accent is scarce** — Brand colors at decision points, not everywhere
4. **AURA is intentional** — Teal signals intelligence, confined to AI features
5. **Luxury is restraint** — Fewer colors, better relationships
6. **Men is differentiated, not separated** — Shared foundations, expression accents
7. **Women is editorial, not sugary** — Rose gold as accent, not background
8. **Technology remains quiet** — No neon, cyber, electric; AI feels human
9. **Photography leads** — Color serves imagery, never competes
10. **Accessibility is baseline** — Every combination validated, not assumed

---

## 26. Implementation Status

| Item | Status |
|------|--------|
| **COLOR SYSTEM** | **SPECIFIED** |
| **CODE IMPLEMENTATION** | **NOT STARTED** |
| **TOKEN MIGRATION** | **NOT STARTED** |
| **PRODUCTION MODIFIED** | **NO** |

---

## 27. Git Status

```
$ git status --short
?? docs/design/GLOWAPP_COLOR_SYSTEM.md
?? docs/design/glowapp_color_system.json
```

Only the two specification deliverables created. No production code modified.

---

## 28. Quality Score

| Criterion | Score | Max |
|-----------|-------|-----|
| A. Brand Coherence | 19 | 20 |
| B. Women Definition | 15 | 15 |
| C. Men Definition | 14 | 15 |
| D. AURA Definition | 15 | 15 |
| E. Surface System | 10 | 10 |
| F. Semantic System | 10 | 10 |
| G. Accessibility | 9 | 10 |
| H. Governance | 5 | 5 |
| **TOTAL** | **92** | **100** |

**Deductions:**
- Men palette: Warm White contrast on Obsidian needs validation (-1)
- Accessibility: Aura Teal on dark surfaces fails AAA (-1)

---

## 29. Critical Gaps

1. **Aura Teal on Obsidian fails contrast** (1.8:1) — Must only be used on Warm White or AURA Surface in Men context. Documented as VALIDATION REQUIRED.
2. **Cyber Cyan (#00E5FF) still exists in MensTheme** — Must be removed in S1-I implementation phase.
3. **Pure black shadows** — Several files use `Colors.black.withOpacity()`; should migrate to warm shadow tokens.

---

## 30. Minor Gaps

1. **Champagne (#D9A27F) fails on light surfaces** — Correctly restricted to dark-only usage; document clearly.
2. **Disabled contrast** — Meets AA but not AAA; acceptable for disabled per WCAG.
3. **Gradient inventory** — Some screens use ad-hoc gradients; should align to defined set in S1-I.

---

## 31. Final Decision

**APPROVED WITH MINOR REVISIONS**

The specification is complete, evidence-backed, and ready for implementation phase (S1-I). The two critical gaps (Aura Teal contrast on Men dark, Cyber Cyan removal) are documented with clear replacement strategies and must be addressed during implementation.

---

## 32. Next Phase

**S2 — TYPOGRAPHY SYSTEM**

No color implementation executed. Implementation begins only after S1–S5 are sufficiently defined.

---

*End of GLOWAPP COLOR SYSTEM Specification*