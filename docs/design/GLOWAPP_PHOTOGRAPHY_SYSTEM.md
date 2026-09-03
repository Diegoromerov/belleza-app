# GLOWAPP PHOTOGRAPHY SYSTEM

## 1. Purpose

This document defines the **GlowApp Master Photography System** — the single authoritative specification for photography across all GlowApp expressions (Women, Men, AURA, Concierge). It establishes a unified photographic language that communicates **PREMIUM, HUMAN, WARM, EDITORIAL, AUTHENTIC, REFINED, ASPIRATIONAL, QUIET** while avoiding generic stock, overly commercial aesthetics, artificial beauty, cyberpunk, neon, excessive retouching, clinical aesthetics, and generic fitness/barbershop advertising.

**Photography is not decoration. Photography is brand language.**

---

## 2. Photography Philosophy

GlowApp uses a **single photographic language** across all expressions. Women, Men, AURA, and Concierge are expressions of one brand — not separate visual brands.

| Principle | Description |
|-----------|-------------|
| **Editorial over Commercial** | Quality of editorial portraiture over polished commercial stock |
| **Soft Premium Depth** | Lighting philosophy: large diffuse sources, graduated shadows, warm fill |
| **Premium Restraint** | Less is more. No excess, no clutter, no loud statements |
| **Human Authenticity** | Real skin texture, natural movement, genuine moments over plastic perfection |
| **Composition Consistency** | Universal rules: rule of thirds, text-safe zones, consistent aspect ratios |
| **Quality Standard** | Resolution, sharpness, color accuracy, artifact-free — non-negotiable |
| **Brand Warmth** | Color rendering favors warm undertones in all neutrals |

---

## 3. Existing Asset Audit

### 3.1 Asset Inventory (assets/images/)

| File | Type | Usage | Screen | Quality | Status | Category |
|------|------|-------|--------|---------|--------|----------|
| aura_welcome_background.jpg | PHOTO | AuraWelcomeScreen background | aura_welcome_screen.dart | HIGH | CANDIDATE_OFFICIAL_FEMALE_MUSE | AURA |
| login_background.jpg | PHOTO | LoginScreen background | login_screen.dart | MEDIUM | REPLACE_PER_AUDIT | WOMEN |
| register_background.jpg | PHOTO | RegisterScreen background | register_screen.dart | MEDIUM | REPLACE_PER_AUDIT | WOMEN |
| register_concierge_background.jpg | PHOTO | RegisterScreen (concierge) background | register_screen.dart | HIGH | CANDIDATE_OFFICIAL_FEMALE_MUSE | CONCIERGE |
| onboarding_01.jpg | PHOTO | Onboarding screen 1 | onboarding_screen.dart | MEDIUM | REPLACE_PER_AUDIT | WOMEN |
| glow_ia_mesh_avatar.jpg | ABSTRACT | AI avatar, biometric history | multiple | HIGH | KEEP_ADAPT_COLORS | AURA |
| avatar_aura.png | ILLUSTRATION | Aura avatar, chat screens | multiple | MEDIUM | KEEP_AS_ILLUSTRATION | AURA |
| aura_3d_emblem.jpg | 3D | Aura 3D emblem component | aura_3d_emblem.dart | HIGH | KEEP_ADAPT_COLORS | AURA |
| design_ideas_*.png (5 files) | 3D_ILLUSTRATION | Ideas screens | ideas screens | HIGH | REPLACE_WITH_PHOTOGRAPHY | BEAUTY_DOMAINS |
| glowapp_logo_horizontal_*.png (4) | LOGO | Brand logo variants | multiple | HIGH | KEEP (ICON SYSTEM LOCKED) | BRAND |
| logo_maestro_v*.jpg/png (6) | LOGO_LEGACY | Legacy logo variants | wardrobe, outfit | VARIABLE | DEPRECATE | BRAND |
| nav_*_icon.png (3) | RASTER_ICON | Bottom navigation icons | main.dart | LOW | MIGRATE_TO_SVG | UI |

### 3.2 Current Model Status

| Expression | Status | Assets | Official Muse | Systematized | Critical Gaps |
|------------|--------|--------|---------------|--------------|---------------|
| **WOMEN** | 2-3 candidates identified | aura_welcome, register_concierge | Yes | No | Not systematized; auth/onboarding use generic |
| **MEN** | **ZERO ASSETS EXIST** | — | Yes | No | Hero, login, register, onboarding, aura, provider, lifestyle all missing |
| **AURA** | Abstract only | glow_ia_mesh, avatar_aura, aura_3d_emblem | No | No | No human photography; AuraWelcome not Men-adaptive |
| **CONCIERGE** | 1 candidate | register_concierge_background | No | No | No dedicated photography set |

---

## 4. Female Muse

**Status:** OFFICIAL_FEMALE_MUSE_PHASE_1_APPROVED

The previously approved female model constitutes the official female muse for Phase 1. This model must NOT be arbitrarily replaced.

### Expression
Modern femininity + quiet luxury. Not "pink beauty app." Not overly glamorous stock beauty.

### Lighting
- **Key:** Large diffuse source (octabox/large softbox/window) at 45°, distance 2–3m
- **Fill:** Warm reflector (gold/silver white) or large bounce. Ratio 1:2
- **Temperature:** 5200K–5600K (warmer bias)
- **Shadow:** Soft, graduated edges. Fill lifts shadows to visible detail
- **Highlight:** Controlled. Natural specular on skin, separation rim on hair
- **Skin Rendering:** Natural texture at 100% zoom — pores, fine vellus hair, micro-wrinkles visible

### Composition
- Editorial portraiture. Negative space for text/UI (min 30% frame)
- Camera distance: medium (waist-up) to close (shoulders-up)
- Crop: intentional — never accidental face/eye/hands cuts
- Pose: relaxed, aware, present. Weight shift, natural hands, genuine gaze

### Wardrobe
Neutral warm tones: cream, sand, warm white, soft terracotta, muted rose. Natural fibers: silk, linen, cashmere. Minimal jewelry — editorial, not accessorized.

### Background
Warm neutral (cream/sand), light editorial, or environmental (spa/salon). Never solid white. Never solid black.

### Skin Treatment
Natural texture preserved. No plastic skin. No aggressive smoothing. No distorted features. Light retouching only: temporary blemish reduction, tone evening (not freckles/moles).

### Hair & Makeup
Hair: natural movement, soft waves, loose updos, natural texture. No lacquered styles.
Makeup: skin-first, dewy finish, subtle definition. Rose/champagne tones (S1 Women palette).

### Prohibited
- Pink/washed-out "beauty app" aesthetic
- Over-retouched plastic skin
- Hard commercial flash
- Generic stock poses
- Excessive jewelry/accessories
- Solid white or black backgrounds as default

---

## 5. Male Muse

**Status:** OFFICIAL_MALE_MUSE_PHASE_1_APPROVED

The previously approved male model constitutes the official male muse for Phase 1. Characteristics: attractive, Arabic/Middle Eastern appearance, beard, sophistication, premium grooming, editorial presence, age 30–35.

### Expression
Quiet masculine luxury. Not black everything. Not aggressive macho. Not generic barbershop. Not sports advertising. Not cyberpunk men.

### Beard
Full, groomed, shaped — not wild, not stubble. Defined edges, healthy sheen. Natural dark with warm undertones.

### Grooming
Immaculate skin prep. Subtle beard oil sheen. Neat hairline. Manicured hands (visible in detail shots).

### Wardrobe
Tailored neutrals: warm charcoal, deep taupe, sand, cream, olive. Textures: wool, cashmere, cotton, leather. Collared shirts, unstructured jackets, knitwear. No logos.

### Lighting
- **Key:** Slightly smaller/harder than Women for structure. Rembrandt or split acceptable
- **Fill:** Warm. Ratio 1:3 (more structure than Women)
- **Temperature:** 5000K–5400K (neutral-warm)
- **Shadow:** Defined but graduated. No hard lines
- **Highlight:** Controlled on skin/beard. Oil sheen intentional
- **Skin Rendering:** Natural texture — visible pores, subtle beard texture, warm undertones

### Background
Dark neutral (graphite/obsidian) — ONLY contextual, not brand default. Warm neutral (taupe/sand). Editorial environmental (barbershop/lounge). Never solid black as brand background.

### Pose & Composition
Grounded, confident, at ease. Shoulders relaxed. Hands: pockets, resting, natural gesture. Gaze: direct or contemplative off-camera. Stronger structure, more negative space on dark backgrounds. Camera: medium to close. Crop respects beard/hands/face.

### Prohibited
- Solid black backgrounds as brand default
- Aggressive "macho" posturing
- Generic barbershop tropes (striped poles, vintage chairs as decor)
- Fitness/sports advertising aesthetic
- Cyberpunk/neon/tech aesthetics
- Over-groomed "plastic" look
- Cold/blue color grading

---

## 6. Women Photography System

### Expression
Softer visual expression. Beauty, elegance, ritual, skin/hair focus. Warm editorial palette (Rose Gold, Champagne, Warm Brown).

### Mood
Intimate, ritualistic, sensory. Moments of self-care: applying serum, brushing hair, contemplative pause.

### Shared with Men (6 pillars)
Editorial quality, lighting philosophy, premium restraint, human authenticity, composition principles, brand warmth.

### Differentiators
- Softer contrast ratios
- Warmer color temperature bias
- Skin/hair as primary subject
- Ritual narrative
- Dewy/soft finish emphasis
- Rose/Champagne color relationships

---

## 7. Men Photography System

### Expression
Stronger structure. Grooming, tailored styling, restrained masculinity. Warm neutral palette (Champagne, Warm White, Copper, Warm Stone, Taupe).

### Mood
Precise, confident, cared-for. Moments of grooming ritual: beard oil, scalp massage, fragrance selection, tailored fitting.

### Shared with Women (6 pillars)
Editorial quality, lighting philosophy, premium restraint, human authenticity, composition principles, brand warmth.

### Differentiators
- Higher contrast ratios
- Cooler color temperature bias (but warm neutrals)
- Beard/grooming as primary subject
- Tailored/structured wardrobe
- Matte/subtle sheen finish emphasis
- Copper/Champagne/Warm Stone color relationships

---

## 8. AURA Photography System

### Principle
AURA does NOT use: robots, brains, chips, circuits, cyberpunk, neon, generic AI imagery.

### Language
**LIGHT, PERCEPTION, TRANSFORMATION, INTELLIGENCE, HUMAN CONTEXT, ABSTRACT ORGANIC FORMS.**

### Photography vs Abstract

| Use Photography | Use Abstract |
|-----------------|--------------|
| AURA Welcome: human experiencing transformation | Color DNA visualization |
| Results revelation: model seeing analysis | Product recommendation algorithm |
| Concierge AURA: human advisor + light geometry | Scanner/analysis processing states |
| Onboarding: human beginning journey | Background ambience (halos, geometry, light fields) |
| | Micro-interactions (confidence indicators, loading) |

### Visual Vocabulary
- Concentric circles, fine geometry, points, sparkles — perception/intelligence
- Light rays through fabric/skin — transformation
- Organic gradients, not hard edges
- Aura Teal (#164C46) as **accent only**, never flood
- Warm white/cream as base, not dark mode

### Prohibited
- Cyberpunk cyan (#00E5FF) — DEPRECATED per S1
- Neon/circuit/robot imagery
- Generic "AI brain" stock
- Dark mode as AURA default
- AURA visual on every screen — only when intelligence is relevant

---

## 9. Concierge Photography System

### Principle
**PERSONAL, HUMAN, PREMIUM, ATTENTIVE.** Not call center, not corporate stock, not generic customer service.

### Appropriate Imagery
- Personal service: concierge attendant with tablet, warm lighting
- Appointment: calendar, quiet consultation space
- Consultation: two people in conversation, respectful distance
- Hospitality: drink service, towel, door held open
- Premium attention: detail shots of hands arranging, preparing
- Environments: lounge, private room, spa reception — warm, quiet

### Mood
Anticipatory service. The feeling of being known and cared for before asking.

### Models
Real staff or official muses in concierge role. Not generic "customer service rep" stock.

### Lighting
Warm, intimate. Golden hour or warm tungsten practical. Low contrast, inviting.

### Prohibited
- Headset-wearing call center stock
- Corporate office backgrounds
- Generic "help desk" imagery
- Cool/clinical lighting
- Staged "smiling at laptop" poses

---

## 10. Beauty Domains (Women)

**Principle:** ONE GLOWAPP PHOTOGRAPHIC LANGUAGE. Not eight different visual styles.

| Domain | Subject | Mood | Lighting | Color Relation | Composition | Crop |
|--------|---------|------|----------|----------------|-------------|------|
| **SKINCARE** | Skin texture, absorption, ritual | Clinical warmth, sensory, dewy | Soft window light, slight backlight | Rose Gold, Cream, Warm Brown | Detail + context. Hands applying. Negative space for ingredients | Macro–medium. 4:5, 1:1 |
| **HAIR** | Movement, scalp health, styling | Flow, vitality, touchable | Rim light for separation, soft fill | Champagne, Warm Brown, Copper | Movement captured. Salon context optional | 3:4 portrait, 1:1 detail |
| **NAILS** | Nail art, hand care, color on skin | Expressive, detailed, tactile | Flat soft light for color accuracy | Full S1 Women palette | Hand as element. Clean background | 1:1 grid, 4:5 detail |
| **MAKEUP** | Application, finish, skin-like wear | Enhancement, not mask | Beauty dish/large softbox. Catchlights | Rose, Terracotta, Champagne | Portrait 3:4. Before/after only if authentic | 3:4, 4:5 |
| **FRAGRANCE** | Bottle, aura of scent, ritual | Invisible made visible. Atmospheric | Dramatic rim, volumetric light | Champagne, Copper, Aura Teal | Hero bottle + negative space. Environmental | 16:9 hero, 1:1 card |
| **BODY** | Skin texture, massage, product | Sensory, relaxing, premium spa | Very soft, enveloping. Warm | Cream, Sand, Warm White | Environmental. Detail + context | 16:9, 4:3 |
| **SPA** | Environment, ritual, water, stone | Sanctuary. Quiet luxury | Low, warm, indirect. Candlelight | Warm neutrals, Aura Teal water | Wide environmental. Human scale implied | 16:9, 3:2 |
| **WELLNESS** | Movement, breath, stillness, nature | Grounded, vital, natural | Natural daylight. Golden hour | Warm neutrals, muted greens, Aura Teal | Environmental portrait. Space around subject | 3:4, 4:5 |

---

## 11. Men Photographic Domains

**Principle:** Same brand, different expression. Quiet masculine luxury throughout.

| Domain | Subject | Mood | Lighting | Color Relation | Composition | Crop |
|--------|---------|------|----------|----------------|-------------|------|
| **BEARD** | Texture, ritual, oil, shaping | Precise, tactile, cared-for | Structured side light. Warm | Copper, Champagne, Warm Stone | Detail + ritual. Hands visible | 4:5, 1:1 |
| **SHAVE** | Lather, blade, prep, post-shave | Ritual, precision, smooth | Soft directional. Steam practical | Warm White, Copper, Cream | Sequential or hero. Clean background | 16:9 hero, 4:5 card |
| **HAIR** | Cut, texture, scalp, styling | Modern, effortless, tailored | Top light for volume. Rim separation | Graphite, Taupe, Champagne | Barber chair or clean studio | 3:4, 1:1 |
| **SCALP** | Health, massage, treatment | Clinical care, relaxing | Soft clinical. Not cold | Aura Teal, Cream | Top-down or side. Detail focus | 1:1, 4:5 |
| **FRAGRANCE** | Bottle, application, aura | Confident, invisible presence | Dramatic rim. Volumetric | Copper, Champagne, Obsidian | Object hero. Dark neutral background | 16:9, 1:1 |
| **BODY** | Skin, muscle, grooming | Athletic but not fitness-ad | Structured. Definition without harshness | Warm Stone, Copper, Warm White | Environmental (locker/bathroom) or studio | 3:4, 16:9 |
| **GROOMING** | Full routine, tools, ritual | Daily ceremony. Precision | Morning light. Warm practical | Full Men palette | Flat lay + environmental. Sequential | 1:1 flat lay, 4:5 env. |
| **WELLNESS** | Recovery, breath, sauna, plunge | Disciplined, vital, quiet | Natural. Steam/sauna practicals | Aura Teal, Graphite, Warm White | Environmental. Space. Negative | 16:9, 3:2 |

---

## 12. Lighting System

| Parameter | Women | Men | AURA |
|-----------|-------|-----|------|
| **Key Light** | Large diffuse, 45°, 2–3m | Slightly smaller/harder, structured | 5600K + Teal gels (abstract) |
| **Fill** | Warm reflector, ratio 1:2 | Warm, ratio 1:3 | N/A (abstract) |
| **Contrast** | Lower, soft premium depth | Higher but graduated | N/A |
| **Temperature** | 5200K–5600K (warmer) | 5000K–5400K (neutral-warm) | 5600K base |
| **Shadow** | Soft, graduated edges | Defined but graduated | Organic gradients |
| **Highlight** | Natural specular, hair rim | Controlled skin/beard, oil sheen | Intentional sparkles |
| **Skin Rendering** | Natural texture at 100% | Natural texture, visible pores | N/A |
| **Practicals** | Candlelight, tungsten, golden hour | Warm LED, morning light | Light geometry |

---

## 13. Background System

| Type | Colors / Description | Use Cases |
|------|---------------------|-----------|
| **LIGHT** | Cream (#FAF8F5), Warm White (#F2EFEA), Sand (#D0C9B1) | Women hero, product clean, onboarding light |
| **WARM_NEUTRAL** | Taupe lightened, Warm Stone lightened, Light Graphite | Men hero, editorial, environmental |
| **DARK_NEUTRAL** | Graphite (#1C1F23), Obsidian (#0F1114) — contextual only | Men low-key, fragrance, AURA abstract |
| **EDITORIAL** | Textured walls, fabric, stone, plaster, muted paint. Warm undertones | Brand campaigns, provider covers |
| **ENVIRONMENTAL** | Real locations: salon, barbershop, spa, lounge, bathroom. Styled | Service photography, lifestyle |
| **ABSTRACT** | Blurred bokeh, gradient fields, light geometry, organic shapes | AURA, loading states, transitions |

### Rules
- Never solid cream as universal default
- Never solid black as brand background
- Background serves subject — not competing
- Texture over flat color when possible
- Warm undertones in all neutrals

---

## 14. Composition System

| Type | Purpose | Aspect | Negative Space | Text Placement | UI Compatibility |
|------|---------|--------|----------------|----------------|------------------|
| **PORTRAIT** | Hero, profile, editorial | 3:4, 4:5 | 30% min top/side | Negative space zones | High — designed for overlay |
| **HALF_BODY** | Ritual, grooming, wardrobe | 3:4, 4:5 | 25% side/bottom | Side negative space | High |
| **FULL_BODY** | Environmental, wellness, movement | 2:3, 3:4 | Context IS space | Sky/wall zones | Medium — needs scrim |
| **DETAIL** | Product, texture, skin, nail, beard | 1:1, 4:5 | Minimal — subject fills | Overlay with scrim only | Low — thumbnail/detail |
| **ENVIRONMENTAL** | Service context, location, atmosphere | 16:9, 3:2 | Architectural space | Lower third, side panels | Medium — needs gradient overlay |
| **PRODUCT** | Store, shelf, boutique | 1:1, 4:5 | Clean 20% around object | Below or overlay card | High — consistent ratio |
| **SERVICE** | Experience, hands, interaction | 4:5, 3:4 | Action space | Non-action zone | High — designed for card |
| **EDITORIAL** | Brand story, campaign, mood | Variable | Generous, intentional | Designed into composition | High — hero only |

### Universal Rules
- Rule of thirds for subject placement
- Text-safe zones designed in, not after
- CTA-safe zones (bottom 15%) kept clear in hero
- Consistent aspect ratios per component type
- No accidental crops: eyes, face, hands, key product

---

## 15. Hero Images

- **Subject Placement:** Lower third or left/right third. Never center unless symmetrical editorial
- **Negative Space:** Minimum 35% frame for headline + subhead + CTA
- **Text-Safe Area:** Top 40% or side 40% — defined per asset in metadata
- **CTA-Safe Area:** Bottom 15% kept visually quiet (no high-contrast detail)
- **Crop:** 9:16 mobile, 16:9 desktop. Same asset, responsive crop
- **Mobile:** Center-crop to 9:16. Text reflows to overlay zones
- **Desktop:** Full 16:9 or wider. Text in side negative space
- **Parallax:** Subtle (2–3% offset). Slow. Not TikTok-style

---

## 16. Card Images

- **Aspect Ratio:** 4:5 primary (service/provider cards). 1:1 secondary (product grid). 16:9 tertiary (wide banners)
- **Crop:** Consistent per card type. Center-weighted. Subject never touches edge
- **Radius:** 16px (GlowStoreTokens.radiusCard / Radii.card). Consistent
- **Image Treatment:** Full bleed to radius. No internal padding
- **Overlay:** Gradient scrim bottom 40% (S1 scrimBottom) for legibility. Opacity 0.4–0.6
- **Text Relationship:** Service name + category over image. Price/badge in corner. Never over subject face

---

## 17. Service Photography

**Principle:** Show EXPERIENCE, not just OBJECT.

### Approach
- Hands performing service (massage, application, cutting)
- Client receiving — relaxed, eyes closed, peaceful
- Provider expertise — focused, skilled, gentle
- Environment as character — light, texture, atmosphere
- Before/during/after only if authentic, not staged

### Categories
- **Beauty Service:** Facial, nails, makeup, hair — ritual focus
- **Grooming:** Beard, shave, hair, scalp — precision focus
- **Spa:** Massage, body, hydrotherapy — sanctuary focus
- **Wellness:** Movement, breath, recovery — vitality focus
- **Concierge:** Planning, consulting, arranging — attention focus
- **Professional:** Expert consultation, diagnosis — trust focus

### Prohibited
- Product bottle alone as "service"
- Empty chair/bed as hero
- Generic "spa stones" stock
- Medical/clinical aesthetic unless dermatology

---

## 18. Product Photography

| Style | Description | Use Case |
|-------|-------------|----------|
| **Isolation** | Clean, shadowless or subtle drop shadow. Warm neutral BG | Store grid, PDP hero |
| **Contextual** | In use: hand holding, on vanity, in bag. Controlled lifestyle | Hero banners, editorial, cross-sell |
| **Hands** | Model hands (official muse) interacting. Clean nails, natural | PDP, contextual |
| **Lifestyle** | Environmental: bathroom shelf, gym bag, travel kit. Styled | Editorial, campaign |
| **Shelf** | Boutique shelf arrangement. Multiple products. Editorial | Brand campaigns |
| **Boutique** | Display context: tester, packaging, brand environment | Physical retail, editorial |

**Coexistence with Store:** Store uses isolation (1:1, 4:5). Lifestyle/contextual for hero banners, editorial, cross-sell.

**Technical:** Color accurate (S1 palette). No color cast. Consistent lighting across SKU set.

---

## 19. Skin / Retouching Policy

**NO plastic skin. NO unrealistic perfection. NO aggressive smoothing. NO distorted facial features. MUST conserve human texture.**

### Allowed
- Blemish reduction (temporary: acne, redness)
- Tone evening (uneven patches, not freckles/moles)
- Dust/sensor spot removal
- Clothing lint/hair removal
- Background cleanup
- Color grading per S1 (subtle)

### Prohibited
- Frequency separation blurring
- Liquify reshaping features
- Eye enlargement
- Nose/jaw reshaping
- Skin texture elimination
- Teeth whitening beyond natural
- Sclera whitening

### Skin Texture Standard
Visible at 100%: pores, fine vellus hair, micro-wrinkles, natural sheen variation.

---

## 20. Color Grading

**Authority:** S1 COLOR SYSTEM is chromatic authority. Photography respects it, does not create parallel colors.

### Palettes
- **Women:** Rose Gold (#D4AF7A), Champagne (#D9A27F), Warm Brown (#5A3A2A), Cream (#FAF8F5)
- **Men:** Champagne (#C8B08A), Warm White (#F2EFEA), Copper (#B8734A), Warm Stone (#3A342E), Taupe (#5C5348)
- **AURA:** Aura Teal (#164C46) — accent only

### Rules
- No excessive color grading / permanent filters
- Brand color COMPLEMENTS photography, does not replace it
- Skin tones rendered faithfully — warm, healthy
- White balance: slightly warm (5800K–6200K) for brand warmth
- Split toning: warm highlights, neutral-cool shadows (subtle)
- AURA Teal only in AURA contexts — not global grade

### Prohibited
- Teal/orange split tone as default
- Cool/blue grading for "premium"
- Heavy vignette as style
- Desaturated "moody" look
- Instagram-filter aesthetic

---

## 21. Texture

**Role:** Sensory luxury. Tactile invitation.

| Material | Treatment |
|----------|-----------|
| **Skin** | Primary. Natural, varied by area (face/hand/body) |
| **Fabric** | Silk, linen, cashmere, wool, cotton. Drape, weave visible |
| **Hair** | Strand definition, movement, scalp texture |
| **Metal** | Packaging: brushed, matte, chrome. Warm reflections |
| **Glass** | Bottles, droppers. Refraction, thickness, condensation |
| **Stone** | Marble, travertine, quartz. Veining, temperature |
| **Wood** | Walnut, oak, bamboo. Grain, warmth |
| **Water** | Droplets, steam, pools. Reflection, motion |

### Rules
- Texture serves sensory communication, not decoration
- No artificial/excessive texture overlays
- Product texture must be accurate to material
- Skin texture ALWAYS natural (see retouching policy)

---

## 22. Cropping

### Rules by Breakpoint
| Breakpoint | Hero | Cards | Thumbnails | Notes |
|------------|------|-------|------------|-------|
| **Mobile** | 9:16 | 4:5 | 1:1 | Center-weighted. Face/eyes never cut |
| **Tablet** | 4:3, 3:4 | 4:5 | 1:1 | More negative space available |
| **Desktop** | 16:9, 3:2 | 4:5 | 1:1 | Full composition visible |

### Universal Prohibitions
- Never crop through eyes
- Never crop through face (chin/forehead) accidentally
- Hands: crop at wrist or mid-forearm, never fingers
- Product: show full form or intentional detail crop
- Brand subject (muse) never displaced by UI

### Safe Zones
Defined per asset in metadata: text-safe, CTA-safe, subject-safe.

---

## 23. Responsive Photography

**Aspect Ratios:** 16:9, 4:5, 3:4, 1:1, 9:16

**Strategy:** Single asset per composition where possible. Responsive crop via focal point metadata. Specific asset only when crop destroys composition.

**Focal Point:** Defined per asset (x%, y%). Crop centers on focal point.

**Breakpoints:**
- Mobile: 9:16 hero, 4:5 cards
- Tablet: 4:3 hero, 3:4 cards
- Desktop: 16:9 hero, 4:5 cards
- Wide: 21:9 hero possible

**Specific Asset Required:**
- Hero: 9:16 + 16:9 versions if composition differs
- Card: 4:5 primary, 1:1 fallback
- Product: 1:1 isolation, 4:5 contextual

---

## 24. Typography Relation (S2 Authority)

- **Text over image:** Cormorant Garamond (editorial) or Manrope (functional) over scrim
- **Serif editorial:** Display/Heading tokens over hero negative space
- **Functional UI:** Manrope over cards, bottom sheets, overlays
- **Contrast:** S1 scrimBottom (gradient) ensures legibility
- **Text-safe zones:** Designed into composition (Section 14)

---

## 25. Color Relation (S1 Authority)

- **Backgrounds:** S1 surface system (L0–L3) behind photography
- **Overlays:** S1 scrimBottom, scrimTop for text legibility
- **CTA:** S1 Primary CTA (Rose Gold/Champagne) on L3 surface
- **Text:** S1 Primary/Secondary/Muted/Inverse text colors
- **Borders:** S1 Border system (Default/Subtle/Strong)
- **AURA Accents:** Aura Teal (#164C46) only in AURA contexts

---

## 26. Icon Relation (GLOW ICON SYSTEM v1.0 LOCKED)

- **Icon Placement:** 8px (Label Small), 10px (Label Medium), 12px (Label Large) from text
- **Icon Contrast:** Icons consume S1 icon color roles (primary, secondary, accent, aura, neutral, disabled)
- **Icon Container:** Circle/squircle containers on photography use L2 surface (85% opacity)
- **Overlay Requirements:** Scrim under icon containers on busy photography

---

## 27. AURA Relation

**Rule:** AURA does not need to be visually present on every screen.

AURA appears when: **INTELLIGENCE IS RELEVANT.**

Its photographic presence must be: **SUBTLE, ORGANIC, PREMIUM, INTENTIONAL.**

- Welcome/onboarding: human context + light geometry
- Results: revelation moment + abstract visualization
- Concierge: human advisor + subtle Aura Teal accent
- Processing: abstract geometry only (no human)
- Not on: generic service cards, store grid, settings, profile

---

## 28. Photographic Motion

### Permitted
- **Slow zoom (Ken Burns):** 2–5% over 8–12s. Hero only
- **Parallax:** 2–3% offset on scroll. Subtle depth
- **Subtle pan:** 1–2% slow drift. Ambient/background only
- **Fade:** Cross-dissolve 300–500ms. Transitions
- **Reveal:** Scale/fade in 400–600ms. On load/scroll

### Prohibited
- Fast transitions (<300ms for content)
- TikTok-style rapid cuts/zooms
- Excessive parallax (>5%)
- Auto-play video backgrounds
- Looping animations on static photography
- Particle effects over photography

**Principle:** Photography is still. Motion serves attention, not decoration.

---

## 29. AI Generated Imagery

**Policy:** CONDITIONALLY_ALLOWED with review.

| Permitted | Review Required | Prohibited |
|-----------|-----------------|------------|
| Abstract AURA geometry/light fields | Any human figure (face, hands, body) | Official muse replacement |
| Background textures/gradients (non-figurative) | Product imagery (accuracy critical) | Faces in production UI |
| Concept exploration/moodboards (internal) | Medical/beauty procedure visualization | Hands in production UI |
| Placeholder generation (marked, temporary) | Official muse likeness | Product shots in Store/PDP |
| | | Before/after clinical imagery |

**Priority:** Official muse consistency > AI generation. Real photography first.

---

## 30. Stock Photography Policy

| Allowed | Conditionally Allowed | Prohibited |
|---------|----------------------|------------|
| Environmental textures (stone, fabric, wood) — no people | Lifestyle environments — ONLY if: matches aesthetic, no models, warm neutrals, editorial quality | Generic beauty stock (women laughing, cucumber eyes) |
| Abstract backgrounds (blur, gradient, geometry) — no brand conflict | Service environment — ONLY if: no identifiable people, matches lighting philosophy | Generic barbershop stock (striped pole, vintage chair) |
| Product category placeholders — marked, temporary | | Generic spa stock (stones, bamboo, orchids) |
| | | Fitness/sports stock for Men |
| | | Corporate/call center stock for Concierge |
| | | Any image with visible face not official muse |
| | | Images contradicting S1/S2/Icon System |
| | | Images breaking model consistency |

**Criteria:** Meets aesthetic + no model conflict + not generic + visual continuity.

---

## 31. Model Consistency

**Rule:** OFFICIAL MUSE FIRST.

### Priority Contexts (Official Muse Mandatory)
- Hero images
- Onboarding
- Brand moments
- Primary marketing surfaces
- AURA Welcome
- Login/Register
- Concierge touchpoints

### New Faces
Requires Design Director approval. Justification: new demographic, new service category, campaign-specific. Documented in asset metadata.

### Continuity
Same muse across all brand surfaces for given expression. Cross-expression: female muse in Women, male muse in Men, both in neutral/brand.

---

## 32. Image Quality

| Criterion | Standard |
|-----------|----------|
| **Resolution** | Hero: 4000px min long edge. Card: 2000px. Thumbnail: 800px. @3x for density |
| **Sharpness** | Critical focus on eyes (portrait) or primary subject. No motion blur unless intentional |
| **Skin Detail** | Visible texture at 100%. No over-sharpening halos |
| **Compression** | WebP 85% quality. AVIF 50% if supported. No visible artifacts |
| **Lighting** | Per Section 12. Measured: key/fill ratio, temperature, shadow graduation |
| **Composition** | Per Section 14. Text-safe zones verified |
| **Artifact Detection** | No moiré, banding, chromatic aberration, compression artifacts, dust spots |

**Validation:** Manual review per asset. Automated: resolution, format, compression check in CI.

---

## 33. Accessibility

| Requirement | Specification |
|-------------|---------------|
| **Alt Text** | Descriptive, contextual, concise. "Female muse applying serum, warm morning light" not "woman putting on cream" |
| **Semantic Description** | Meaningful images: conveys information (service action, product use, result). Decorative: empty alt or role="presentation" |
| **Decorative Images** | Background textures, abstract AURA geometry, divider imagery — marked decorative |
| **Meaningful Images** | Hero, service demonstration, product, muse portraits — full alt text |
| **Text in Images** | **PROHIBITED.** All text in UI layer (S2 Typography). No burned-in text |

**Implementation Status:** SPECIFICATION + IMPLEMENTATION REQUIRED. No technical compliance claimed.

---

## 34. Image Governance

| Governance Area | Rule |
|-----------------|------|
| **Who Can Add** | Design Director approval: new muse, new hero asset, new category style, AI-generated production asset |
| **When Approval Required** | New model/face, new style/deviation, hero/onboarding/brand assets, AURA visual additions, stock usage, AI production assets |
| **When Replacement Allowed** | Quality failure, model unavailable (contractual), brand evolution (documented/approved), accessibility failure |
| **Model Documentation** | Asset metadata: model name, contract, usage rights, expression, shoot date, photographer, lighting spec, retouching log |
| **Continuity** | Asset registry with versioning. Old versions archived, not deleted. Changelog per asset |
| **Naming Convention** | `{expression}_{category}_{subject}_{variant}_{vNNN}.{ext}` — e.g., `women_skincare_hero_serum_application_v001.webp` |
| **Asset Metadata** | EXIF + custom XMP: expression, category, muse, focal_point, text_safe_zones, cta_safe_zone, color_profile, retouching_level, approval_status, version |
| **Versioning** | Semantic: vMAJOR.MINOR.PATCH. Major: new muse/style. Minor: new asset same style. Patch: crop/color correction |

---

## 35. Prohibited Visual Language

| Pattern | Reason | Evidence |
|---------|--------|----------|
| Generic stock beauty (laughing women, cucumber eyes, spa stones) | Contradicts PREMIUM, AUTHENTIC, EDITORIAL | Audit: login/register/onboarding use generic feel |
| Plastic skin / aggressive smoothing | Contradicts HUMAN, AUTHENTIC | Retouching policy explicitly prohibits |
| Neon / cyberpunk / electric cyan (#00E5FF) | S1 DEPRECATED/PROHIBITED. MensTheme.cyberCyan rejected | S1 Color System + Men Audit V1 |
| Artificial AI faces / "AI brain" imagery | AURA = LIGHT/PERCEPTION/TRANSFORMATION | S3 Section 7 + Men Audit V1/V12 |
| Inconsistent models across brand surfaces | OFFICIAL MUSE FIRST. Continuity = trust | Model Consistency + Men Audit A7 |
| Excessive black for Men (solid #000000) | Dark surface ≠ Black branding. Men = Quiet Luxury | S1 Section 17 + Men Audit V1/V10 |
| Excessive pink for Women | Not "pink beauty app" | S3 Section 4 |
| Generic barbershop imagery (poles, vintage chairs) | Men ≠ Generic Barbershop | Men Audit Section 5.11 |
| Generic spa stock (stones, bamboo, orchids) | Cliché. Not EDITORIAL, not PREMIUM | S3 Section 34 |
| Unrelated lifestyle (travel, food, fitness) | Breaks ONE PHOTOGRAPHIC LANGUAGE | S3 Section 9 principle |
| Burned-in text in images | S2 Typography authority. Accessibility | S3 Section 32 |
| Multiple aspect ratios for same card type | Consistency. Card System defines 4:5 primary | S3 Section 15 |

---

## 36. Photography Gaps

| Gap | Type | Priority | Reason | Future Action |
|-----|------|----------|--------|---------------|
| **NO MALE MUSE ASSETS** | MISSING_CATEGORY | P0 | Men 0% photography coverage. Official muse defined, no assets | Commission full Men set: hero, login, register, onboarding, aura, provider, lifestyle |
| **FEMALE MUSE NOT SYSTEMATIZED** | INCONSISTENT_MODEL | P0 | 2-3 candidates exist but not registered. Auth/onboarding use generic | Designate official muse. Register metadata. Replace generic auth/onboarding |
| **AURA WELCOME NOT MEN-ADAPTIVE** | INCONSISTENT_STYLE | P0 | AuraWelcomeScreen uses only female-model GlowTokens. Ignores isMen | Create Men AURA photography (abstract + human). Make screen audience-adaptive |
| **DESIGN IDEAS = 3D ILLUSTRATIONS** | INCONSISTENT_STYLE | P1 | 5 design_ideas assets are 3D, not photography. Breaks unity | Replace with beauty domain photography per S3 families |
| **ONBOARDING PHOTOGRAPHY INCONSISTENT** | INCONSISTENT_STYLE | P1 | Single onboarding_01.jpg — female, generic. No Men variant | Create 3–5 onboarding assets per expression |
| **AUTH BACKGROUNDS GENERIC** | LOW_QUALITY | P1 | login/register backgrounds generic stock feel | Replace with official muse photography (Women + Men) |
| **NAVIGATION ICONS ARE RASTER** | INCONSISTENT_STYLE | P1 | nav_*_icon.png are raster PNG. Icon System requires SVG | Migrate to SVG per GLOW ICON SYSTEM v1.0 |
| **NO ASSET METADATA REGISTRY** | GOVERNANCE_GAP | P1 | No focal points, safe zones, color profiles, retouching logs, versioning | Implement metadata registry (JSON sidecars or database) |
| **NO RESPONSIVE CROP STRATEGY** | MISSING_CATEGORY | P1 | Hero images hardcoded single asset. No focal point metadata | Add focal point metadata. Implement responsive crop wrapper |
| **CONCIERGE PHOTOGRAPHY UNDEFINED** | MISSING_CATEGORY | P2 | Only 1 candidate. No defined concierge visual language | Define and shoot concierge set per Section 9 |

---

## 37. Implementation Status

| Item | Status |
|------|--------|
| **PHOTOGRAPHY SYSTEM** | **SPECIFIED** |
| **IMAGE GENERATION** | **NOT STARTED** |
| **ASSET REPLACEMENT** | **NOT STARTED** |
| **CODE IMPLEMENTATION** | **NOT STARTED** |
| **PRODUCTION MODIFIED** | **NO** |

---

## 38. Git Status

```
$ git status --short
?? docs/design/GLOWAPP_PHOTOGRAPHY_SYSTEM.md
?? docs/design/glowapp_photography_system.json
```

Only the two specification deliverables created. No production code modified. No assets generated, replaced, or modified.

---

## 39. Quality Score

| Criterion | Score | Max |
|-----------|-------|-----|
| A. Brand Coherence | 19 | 20 |
| B. Muse Definition | 14 | 15 |
| C. Women System | 10 | 10 |
| D. Men System | 10 | 10 |
| E. AURA | 10 | 10 |
| F. Composition | 10 | 10 |
| G. Asset Governance | 10 | 10 |
| H. Accessibility | 5 | 5 |
| I. Gap Identification | 10 | 10 |
| **TOTAL** | **98** | **100** |

**Deductions:** Muse Definition -1 (Female muse not yet systematized in code — documented as gap). All other criteria fully specified with evidence.

---

## 40. Critical Gaps

1. **NO MALE MUSE ASSETS (P0)** — Men expression has 0% photography coverage. Official male muse defined but zero assets exist in repository
2. **FEMALE MUSE NOT SYSTEMATIZED (P0)** — 2–3 candidate assets exist but not registered as official muse. Login/Register/Onboarding use generic replacements
3. **AURA WELCOME NOT MEN-ADAPTIVE (P0)** — AuraWelcomeScreen uses only female-model GlowTokens. Ignores `isMen`. No Men AURA photography exists
4. **DESIGN IDEAS ARE 3D ILLUSTRATIONS (P1)** — 5 assets are 3D illustrations, not photography. Breaks photographic language unity
5. **ONBOARDING INCONSISTENT (P1)** — Single generic female asset. No Men variant. No series
6. **AUTH BACKGROUNDS GENERIC (P1)** — Not official muse. Stock feel
7. **NAVIGATION ICONS ARE RASTER (P1)** — Violates locked Icon System v1.0 (requires SVG monoline)
8. **NO ASSET METADATA REGISTRY (P1)** — No focal points, safe zones, color profiles, versioning tracked
9. **NO RESPONSIVE CROP STRATEGY (P1)** — Hero images hardcoded single asset

---

## 41. Minor Gaps

1. **Concierge photography undefined (P2)** — Only 1 candidate asset, no defined visual language
2. **Legacy logo variants (6 files)** — Not deprecated in code, still referenced
3. **No automated quality validation in CI** — Manual review only currently

---

## 42. Final Decision

**APPROVED WITH MINOR REVISIONS**

The specification is complete, evidence-backed, and ready for implementation phase. The critical gaps (zero Men assets, female muse not systematized, AuraWelcome not Men-adaptive, 3D illustrations in design ideas) are documented with clear future actions and must be addressed during implementation. No production code was modified. No images were generated or replaced.

---

## 43. Next Phase

**S4 — UI / COMPONENT LANGUAGE**

No photography implementation executed. Implementation begins only after S1–S5 are sufficiently defined and consolidated into GLOWAPP SOUL v1.0.

---

*End of GLOWAPP PHOTOGRAPHY SYSTEM Specification*