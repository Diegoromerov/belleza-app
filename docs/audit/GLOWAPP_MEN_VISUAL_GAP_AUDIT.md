# GLOWAPP MEN — AUDITORÍA DE BRECHA VISUAL (FASE M0)

**Modo:** READ-ONLY — NO SE MODIFICÓ NINGÚN ARCHIVO DART/FLUTTER  
**Fecha:** 2026-08-19  
**Repositorio:** `C:\beauty-app\frontend`  
**Auditor:** Senior Product Designer + Design Systems Architect + Flutter UI Auditor

---

## 1. EXECUTIVE SUMMARY

### Estado General
Glow Men **existe técnicamente** como modo de audiencia (`AudienceMode.men`) con un tema dedicado (`MensTheme`) y adaptación de componentes vía `GlowStoreTokens`. Sin embargo, **la identidad visual "Quiet Masculine Luxury" objetivo NO está implementada** — lo que existe es una **estética "Dark Marketplace Genérica" (Obsidian + Cyber Cyan + Champagne Gold)** que contradice varios principios del target.

### Cobertura Global Estimada: **28%**

| Dimensión | Score (0-100) | Estado |
|-----------|--------------|--------|
| **Brand Consistency** | 25 | ❌ Crítico |
| **Color** | 30 | ❌ Crítico |
| **Typography** | 35 | ⚠️ Parcial |
| **Photography** | 0 | ❌ Ausente |
| **Components** | 45 | ⚠️ Parcial |
| **Navigation** | 50 | ⚠️ Parcial |
| **Iconography** | 40 | ⚠️ Parcial |
| **AURA** | 20 | ❌ Crítico |
| **Responsive** | 40 | ⚠️ Parcial |
| **Accessibility** | 35 | ⚠️ Parcial |

### Veredicto Final: **NOT READY — REQUIERE REINGENIERÍA VISUAL (OPCIÓN C)**

> La arquitectura existente permite el switch de audiencia, pero el sistema visual masculino actual es **incompatible** con "Quiet Masculine Luxury". Requiere reemplazo sistemático de paleta, tipografía, fotografía, componentes AURA y assets.

---

## 2. ESTADO ACTUAL — QUÉ EXISTE HOY

### 2.1 Arquitectura de Audiencias
- **`AudienceService`** (`lib/services/audience_service.dart`): `ValueNotifier<AudienceMode>` con persistencia `SharedPreferences`. Modos: `all`, `men`, `women`.
- **`AudienceToggleWidget`** (`lib/widgets/audience_toggle.dart`): Selector 3 estados (Todos/Mujeres/Hombres) con animaciones y styling adaptativo.
- **`MensTheme`** (`lib/shared/mens_theme.dart`): Tema masculino independiente (57 líneas, solo colores + 2 gradientes + 2 sombras).
- **`GlowStoreTokens`** (`lib/shared/glow_store_tokens.dart`): Capa de abstracción que mapea tokens por audiencia (`isMen: bool`).
- **`main.dart`**: `MaterialApp` con `ThemeData` dinámico — `Brightness.dark` para Men, `Brightness.light` para Women.

### 2.2 Pantallas que Consumen `isMen`
| Pantalla | Archivo | Adaptación |
|----------|---------|------------|
| **Home/Providers** | `main.dart` → `ProvidersScreen` | Filtro de proveedores, tema global |
| **Store** | `store_screen.dart` | Categorías Men, filtros, product cards, checkout, cart drawer |
| **Client Bookings** | `client_bookings_screen.dart` | Cards, dialogs, colores |
| **Client Profile** | `client_profile_screen.dart` | Scaffold, AppBar, forms, settings tiles |
| **Aura Welcome** | `aura_welcome_screen.dart` | **NO adapta** — usa solo GlowTokens (femenino) |

### 2.3 MensTheme — Paleta Actual (Fuente: `mens_theme.dart:5-16`)
| Token | Hex | Uso |
|-------|-----|-----|
| `obsidianBg` | `#0A0C10` | Background principal |
| `obsidianCard` | `#14171F` | Superficies / Cards |
| `obsidianCardHover` | `#1E232E` | Hover states |
| `champagneGold` | `#D4AF37` | Primary / Accent / CTA |
| `champagneGoldLight` | `#E5C158` | Hover/light accent |
| `bronzeAccent` | `#C5A059` | Secondary accent |
| `cyberCyan` | `#00E5FF` | **IA/Scanner — PROBLEMA** |
| `cyberCyanGlow` | `#5900E5FF` | Glow IA |
| `textPrimary` | `#F5F6F8` | Texto principal |
| `textSecondary` | `#949AA8` | Texto secundario |
| `textMuted` | `#5F6575` | Texto muted |

**Gradientes:** `goldGradient`, `obsidianGlassGradient`  
**Sombras:** `goldGlow`, `cyanScannerGlow`

---

## 3. TARGET VISUAL SYSTEM — "QUIET MASCULINE LUXURY"

### 3.1 Paleta Objetivo (Target Candidates)
| Nombre | Hex | Semántica |
|--------|-----|-----------|
| **Men Obsidian** | `#0F1114` | Fondo principal / Estructural |
| **Men Graphite** | `#1C1F23` | Superficies elevadas / Cards |
| **Men Warm Stone** | `#3A342E` | Bordes / Divisores / Metadata |
| **Men Taupe** | `#5C5348` | Texto secundario / Placeholders |
| **Men Champagne** | `#C8B08A` | **Primary / Brand / CTA** |
| **Men Sand** | `#D0C9B1` | Superficies claras / Inputs |
| **Men Copper** | `#B8734A` | Accent cálido / Estados activos |
| **Men Warm White** | `#F2EFEA` | Texto principal / Alto contraste |
| **AURA TEAL** | `#164C46` | **Inteligencia / IA / Transversal** |

### 3.2 Principios No Negociables
- ❌ **NO** barbería agresiva / app deportiva / cyberpunk / negro+rojo cliché
- ✅ **SÍ** sofisticación, seguridad, precisión, cuidado personal, elegancia, lujo discreto
- ✅ **SÍ** misma casa GlowApp — diferencia por color, fotografía, materiales, composición
- ✅ **AURA** transversal — **NO** "Aura Men" / "Aura Women" separados

### 3.3 Tipografía Target
| Rol | Fuente | Uso |
|-----|--------|-----|
| **Brand/Display** | Cormorant Garamond | Titulares, Aura, branding, storytelling |
| **Functional UI** | Manrope | Navegación, botones, formularios, datos, componentes |

---

## 4. MATRIZ COMPLETA DE EVALUACIÓN (0–5)

| Dimensión | Actual | Target | Gap | Cobertura | Impacto | Esfuerzo |
|-----------|--------|--------|-----|-----------|---------|----------|
| **Color** | 1 | 5 | 4 | 20% | Crítico | Alto |
| **Tipografía** | 2 | 5 | 3 | 35% | Alto | Medio |
| **Spacing** | 3 | 5 | 2 | 60% | Medio | Bajo |
| **Radius** | 3 | 5 | 2 | 60% | Medio | Bajo |
| **Elevation/Shadows** | 2 | 5 | 3 | 30% | Alto | Medio |
| **Buttons** | 3 | 5 | 2 | 50% | Alto | Medio |
| **Inputs** | 3 | 5 | 2 | 50% | Medio | Medio |
| **Cards** | 3 | 5 | 2 | 55% | Alto | Medio |
| **Navigation** | 3 | 5 | 2 | 55% | Alto | Medio |
| **Iconography** | 2 | 5 | 3 | 35% | Medio | Medio |
| **Logo/Brand** | 3 | 5 | 2 | 50% | Medio | Bajo |
| **Photography** | 0 | 5 | 5 | 0% | Crítico | Muy Alto |
| **Model** | 0 | 5 | 5 | 0% | Crítico | Muy Alto |
| **AURA** | 1 | 5 | 4 | 15% | Crítico | Alto |
| **Decorative Language** | 1 | 5 | 4 | 15% | Alto | Medio |
| **Responsive** | 3 | 5 | 2 | 50% | Medio | Medio |
| **Accessibility** | 2 | 5 | 3 | 30% | Alto | Medio |
| **Design Tokens** | 2 | 5 | 3 | 30% | Crítico | Alto |
| **Component Architecture** | 3 | 5 | 2 | 55% | Alto | Medio |

**Escala:** 0=Ausente, 1=Incipiente, 2=Parcial, 3=Funcional, 4=Consistente, 5=Maduro

---

## 5. EVIDENCIA POR DIMENSIÓN

### 5.1 COLOR — **GAP CRÍTICO (20%)**

#### Hallazgos
| Actual | Target | Clasificación | Evidencia |
|--------|--------|---------------|-----------|
| `obsidianBg` `#0A0C10` | `Men Obsidian` `#0F1114` | **ADAPT** | Diferencia mínima, usable como base |
| `obsidianCard` `#14171F` | `Men Graphite` `#1C1F23` | **ADAPT** | Graphite más cálido/visible |
| `champagneGold` `#D4AF37` | `Men Champagne` `#C8B08A` | **REPLACE** | Target más apagado/elegante, menos "oro brillante" |
| `bronzeAccent` `#C5A059` | `Men Copper` `#B8734A` | **REPLACE** | Copper más cálido, menos dorado |
| `cyberCyan` `#00E5FF` | `AURA TEAL` `#164C46` | **REPLACE** | **CRIBLE** — Cyberpunk vs Intelligence |
| `textPrimary` `#F5F6F8` | `Men Warm White` `#F2EFEA` | **ADAPT** | Target más cálido |
| — | `Men Warm Stone` `#3A342E` | **MISSING** | Sin equivalente para bordes/divisores |
| — | `Men Taupe` `#5C5348` | **MISSING** | Sin texto secundario cálido |
| — | `Men Sand` `#D0C9B1` | **MISSING** | Sin superficie clara para inputs/modales |

#### Problemas Arquitectónicos
1. **Tres sistemas de color conviven sin unificación**: `AppTheme` (femenino), `MensTheme` (masculino), `GlowStoreTokens` (store), `BellezaLuxeTokens` (premium femenino), `GlowTokens` (base), `LuxeColors` (legacy).
2. **`cyberCyan` hardcodeado en `MensTheme`** — usado en `cyanScannerGlow` y referenciado como "Scanner Facial IA". **Contradicción directa** con principio "NO cyberpunk".
3. **`GlowStoreTokens.secondaryTextColor` para Men devuelve `Colors.grey.shade400`** (línea 210) — no usa tokens masculinos, rompe coherencia.
4. **No hay token para bordes/divisores masculinos** — se usa `bronzeAccent.withValues(alpha: 0.35)` improvisado.

### 5.2 TIPOGRAFÍA — **PARCIAL (35%)**

#### Estado Actual (Fuente: `glow_tokens.dart:35-39`, `glow_store_tokens.dart:116-186`)
| Familia | Definida en | Usada en |
|---------|-------------|----------|
| `PlayfairDisplay` | `GlowTokens.fontPlayfairDisplay` | `AppTheme.h1`, `subtitle` (serif genérico) |
| `Inter` | `GlowTokens.fontInter` | `GlowStoreTokens.fontFunctionalUI` |
| `JetBrainsMono` | `GlowTokens.fontJetBrainsMono` | `GlowStoreTokens.fontPriceDisplay`, `fontMetadata` |
| `Didot` | `GlowTokens.fontDidot` | `GlowStoreTokens.fontEditorialDisplay`, `fontEditorialSection`, `fontProductName` |
| `CormorantGaramond` | `GlowTokens.fontCormorant` | **NO USADA EN NINGÚN LADO** |

#### Análisis
- **Cormorant Garamond (Target Brand/Display) está declarada PERO NUNCA USADA** — oportunidad perdida.
- **Didot se usa como "Editorial" en Store** — pero Didot ≠ Cormorant; Didot es más fashion/editorial clásico, Cormorant más warm/luxury.
- **Inter se usa como Functional UI** — compatible con target Manrope (ambas geometric humanist), pero **Manrope no está declarada ni cargada**.
- **PlayfairDisplay declarada pero `AppTheme` usa `fontFamily: 'serif'` genérico** — no garantiza Playfair.
- **JetBrainsMono para precios/datos** — buena decisión, mantener.

#### Archivos de fuente en `pubspec.yaml` (verificar):
```yaml
fonts:
  - family: PlayfairDisplay
    fonts: [...]
  - family: Inter
    fonts: [...]
  - family: JetBrainsMono
    fonts: [...]
  - family: Didot
    fonts: [...]  # ¿Existe? Didot no es libre
  - family: CormorantGaramond
    fonts: [...]  # Declarada pero ¿assets existen?
```

### 5.3 SPACING & RADIUS — **FUNCIONAL (60%)**

#### GlowStoreTokens (Fuente: `glow_store_tokens.dart:67-80`)
| Token | Valor | Target | Estado |
|-------|-------|--------|--------|
| `radiusControl` | 8px | 8px | ✅ KEEP |
| `radiusCTA` | 12px | 12px | ✅ KEEP |
| `radiusCard` | 16px | 16px | ✅ KEEP |
| `radiusChip` | 20px | 20px | ✅ KEEP |
| `radiusDrawer` | 24px | 24px | ✅ KEEP |

**Espaciado:** No hay sistema de spacing centralizado en `GlowStoreTokens`. `MensTheme` no define spacing. `AppTheme` no define spacing. **Valores hardcodeados en componentes** (ej: `EdgeInsets.symmetric(horizontal: 24, vertical: 16)`, `SizedBox(height: 12/16/20/24/32)`).

**Evidencia de inconsistencia:** En `store_screen.dart` se usan: 4, 8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 36, 40, 48, 52, 56, 64 — **16 valores distintos** sin token centralizado.

### 5.4 ELEVATION/SHADOWS — **PARCIAL (30%)**

#### MensTheme Shadows
```dart
goldGlow: BoxShadow(color: champagneGold.withValues(alpha: 0.3), blurRadius: 16, offset: Offset(0,4))
cyanScannerGlow: BoxShadow(color: cyberCyan.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2)
```

#### GlowStoreTokens Shadows
```dart
shadowAmbient: BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: Offset(0,4))
shadowGoldGlow: BoxShadow(color: gold871.withValues(alpha: 0.18), blurRadius: 16, offset: Offset(0,6))
shadowDrawer: BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: Offset(-6,0))
```

#### AppTheme Shadows (Legacy/Femenino)
```dart
cardShadow: Color(0x0A5C4E4B), blurRadius: 24, offset: Offset(0,8), spreadRadius: -4
softShadow: Color(0x065C4E4B), blurRadius: 16, offset: Offset(0,4)
glassShadow: Color(0x0F000000), blurRadius: 32, offset: Offset(0,16)
```

#### Clasificación
| Sombra | Compatible | Parcial | Incompatible |
|--------|------------|---------|--------------|
| `shadowAmbient` | ✅ | | |
| `shadowGoldGlow` | | ⚠️ (gold871 ≠ Men Champagne) | |
| `shadowDrawer` | ✅ | | |
| `goldGlow` (Mens) | | ⚠️ (champagneGold ≠ target) | |
| `cyanScannerGlow` (Mens) | | | ❌ **REPLACE** — cyberpunk |
| `cardShadow/softShadow/glassShadow` (AppTheme) | | ⚠️ (negro genérico, no warm) | |

**Problema:** 3 sistemas de sombras independientes. `cyanScannerGlow` **debe eliminarse**.

### 5.5 BOTONES — **PARCIAL (50%)**

#### Store (GlowStoreTokens + MensTheme)
- **Primary/CTA:** `surfaceLevel3` → `MensTheme.champagneGold` (Men) / `gold871` (Women) — **REPLACE** color
- **Secondary/Chip:** `ChoiceChip` con `selectedColor: surfaceLevel3`, `backgroundColor: obsidianCard` — **ADAPT** radius/border
- **Checkout Dialog:** `ElevatedButton` con `accentColor` + `foregroundColor: obsidianBg` — **ADAPT**

#### Client Bookings / Profile
- Usan `ElevatedButton` con `AppTheme.primary` (Women) / `MensTheme.champagneGold` (Men) — **ADAPT**
- Radius hardcodeado: `BorderRadius.circular(30)` (pill) — **ADAPT** a `radiusCTA` (12px) o nuevo `radiusPill`

#### Aura Welcome
- `ElevatedButton` con `GlowTokens.roseGold` — **NO ADAPTA A MEN** — **REPLACE**

### 5.6 INPUTS — **PARCIAL (50%)**

#### Store Search Input (`store_screen.dart:1396-1428`)
- Container decorado manualmente: `borderRadius: GlowStoreTokens.borderCTA` (12px) ✅
- Background: `isMen ? MensTheme.obsidianCard : GlowStoreTokens.nude50` — **ADAPT**
- Border: `isMen ? bronzeAccent.withValues(alpha: 0.35) : ...` — **REPLACE** (improvisado)
- **No usa `InputDecoration` unificado** — duplicación

#### Client Profile / Bookings
- `AppTheme.inputDecoration()` — **legacy, solo femenino** — **REPLACE** para Men

#### GlowGlassCard (`glow_glass_card.dart`)
- Glassmorphism card reutilizable — **KEEP** arquitectura, **ADAPT** colores Men

### 5.7 CARDS — **FUNCIONAL (55%)**

#### StoreProductCard (`store_product_card.dart`)
- Usa `GlowStoreTokens.radiusCard` (16px) ✅
- Background: `surfaceLevel1` (adaptativo Men/Women) ✅
- Shadow: `shadowAmbient` ✅
- **Problema:** Imagen ratio hardcodeado, tipografía Didot para nombre, JetBrainsMono para precio — **ADAPT** tipografía

#### ProviderDetailScreen
- `SliverAppBar` con parallax, cover image, gradient overlay negro — **ADAPT** (negro genérico en overlay)
- Service cards: radius 16, border sutil, shadow suave — **KEEP** arquitectura

#### Client Bookings Cards
- Radius 24 (hardcodeado en `main.dart:142` CardTheme) — **ADAPT** a `radiusCard` (16px) o token dedicado

### 5.8 NAVEGACIÓN — **FUNCIONAL (55%)**

#### Bottom Navigation (implícito en `main.dart` routes + `ProvidersScreen`)
- **No hay `BottomNavigationBar` visible en código principal** — navegación por rutas nombradas + mapas
- **StoreScreen** tiene `AudienceToggleWidget` en header — **KEEP** componente, **ADAPT** styling

#### AppBar / SliverAppBar
- `ProviderDetailScreen`: `SliverAppBar` con `pinned: true`, `expandedHeight: 280`, parallax — **KEEP** patrón
- `ClientProfileScreen`: `AppBar` standard con `leading` back — **KEEP**
- **Colores adaptativos** vía `isMen` en `main.dart:151-155` — **KEEP** arquitectura

#### Audience Toggle
- Componente dedicado (`AudienceToggleWidget`) — **KEEP**, **ADAPT** colores a target

### 5.9 ICONOGRAFÍA — **PARCIAL (40%)**

#### Librerías
- **Material Icons** (`Icons.*`) — dominante en todo el código
- **Cupertino Icons** — no detectado uso significativo
- **Custom SVG** — `glow_app_logo.dart` usa `CustomPainter`, no SVG assets
- **Raster icons** — `nav_citas_icon.png`, `nav_glowshop_icon.png`, `nav_perfil_icon.png` en assets

#### Consistencia
- **Stroke weight:** Material Icons default (24px, weight 400) — consistente
- **Tamaños:** Hardcodeados (14, 16, 18, 20, 22, 24, 28, 36) — **8 tamaños distintos** sin tokens
- **Color:** Adaptativo vía `isMen` en la mayoría de casos — **KEEP** patrón
- **Estados:** Solo `selected/unselected` en `AudienceToggleWidget` y `ChoiceChip` — **PARCIAL**

#### Target: Monoline/Refined Line
- Material Icons **NO son monoline** — son filled/outlined/rounded/sharp
- **REQUIERE** migración a set monoline (ej: Lucide, Phosphor, o custom SVG) para "Quiet Luxury"

### 5.10 LOGO & BRAND ASSETS — **FUNCIONAL (50%)**

#### Assets Encontrados (`assets/images/branding/`)
| Asset | Tipo | Uso |
|-------|------|-----|
| `glowapp_logo_horizontal_primary.png` | Raster | Primary |
| `glowapp_logo_horizontal_primary1.png` | Raster | Variant |
| `glowapp_logo_horizontal_compact.png` | Raster | Compact |
| `glowapp_logo_horizontal_primary_dark.png` | Raster | **Dark mode** — **PROBLEMA** (negro no es brand) |
| `logo_maestro.jpg/v2/v3/v4/v5.png` | Raster | Legacy/variants |

#### `GlowAppLogo` Widget (`lib/widgets/branding/glow_app_logo.dart`)
- `CustomPainter` animado — **KEEP** arquitectura
- **No tiene variante Men** — usa mismos colores (roseGold/terracota)
- **No hay versión monocromática Obsidian/Champagne** — **MISSING**

### 5.11 FOTOGRAFÍA & MODELO — **AUSENTE (0%)**

#### Assets Actuales (`assets/images/`)
| Asset | Tipo | Género | Clasif. |
|-------|------|--------|---------|
| `aura_welcome_background.jpg` | Foto | Femenino (modelo mujer) | **REPLACE** |
| `onboarding/onboarding_01.jpg` | Foto | Femenino | **REPLACE** |
| `auth/login_background.jpg` | Foto | Femenino/Neutro | **ADAPT** |
| `auth/register_background.jpg` | Foto | Femenino/Neutro | **ADAPT** |
| `auth/register_concierge_background.jpg` | Foto | Femenino | **REPLACE** |
| `design_ideas_*.png` | Ilustración | Femenino (uñas, cejas, piel) | **REPLACE** |
| `glow_ia_mesh_avatar.jpg` | Abstracto | IA/Aura | **ADAPT** (colores) |
| `avatar_aura.png` | Ilustración | IA/Aura | **ADAPT** |
| `aura_3d_emblem.jpg` | 3D | IA/Aura | **ADAPT** |

#### Modelo Masculino Oficial (Target)
- Hombre árabe/medio oriente, 30-35 años, cabello negro ondulado, ojos marrones, piel cálida, barba cuidada, complexión atlética, expresión serena.

#### Estado: **NINGÚN ASSET MASCULINO EXISTE EN REPOSITORIO**
- **MISSING:** Hero/background Men, Login/Register Men, Onboarding Men, Aura Men, Provider covers Men, Product lifestyle Men

### 5.12 AURA — **CRÍTICO (15%)**

#### Implementación Actual
| Componente | Archivo | Audiencia | Estado |
|------------|---------|-----------|--------|
| `AuraWelcomeScreen` | `aura_welcome_screen.dart` | **Solo Women** (usa `GlowTokens.creamSilk`, `terracota`, `roseGold`) | **REPLACE** — no adapta a Men |
| `GlowGlassCard` | `glow_glass_card.dart` | Neutral | **ADAPT** colores |
| `Aura3DEmblem` | `aura_3d_emblem.dart` | Neutral | **ADAPT** colores |
| `AuraMultiAgentChat` | `aura_multi_agent_chat.dart` | Neutral | **AUDITAR** |
| Scanner Facial | Referencias en `MensTheme.cyberCyan` | Men-only | **REPLACE** — cyberpunk |

#### Target AURA para Men
- **Colores:** Cream/White + Aura Teal `#164C46` + Men Champagne `#C8B08A` + Light Geometry
- **Halo:** Círculos concéntricos, geometría fina, puntos, destellos — percepción/inteligencia
- **NO:** Cyberpunk, neon, circuitos, robots, estética tecnológica fría

#### Hallazgo Crítico
`MensTheme.cyberCyan` (`#00E5FF`) + `cyanScannerGlow` **SON CYBERPUNK** — contradicción directa con identidad objetivo. **DEBE ELIMINARSE/REEMPLAZARSE** por `AURA TEAL`.

### 5.13 RESPONSIVE — **FUNCIONAL (50%)**

#### Breakpoints Observados
| Comportamiento | Código | Breakpoint |
|----------------|--------|------------|
| Store Grid | `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 260)` | ~260px/item |
| Checkout Dialog | `isMobile = screenWidth < 680` → Column vs Row | 680px |
| Cart Drawer | `drawerWidth = screenWidth > 380 ? 380 : screenWidth` | 380px |
| AudienceToggle | `compact` prop | Manual |

#### Falta
- No hay sistema de breakpoints centralizado (`Breakpoints` class)
- No hay tests visuales documentados para tablet/desktop Men
- `ProviderDetailScreen` SliverAppBar parallax — verificar en mobile

### 5.14 ACCESIBILIDAD — **PARCIAL (35%)**

#### Contraste (Estimado — requiere medición real)
| Combinación | Actual | Target | Riesgo |
|-------------|--------|--------|--------|
| Champagne `#D4AF37` sobre Obsidian `#0A0C10` | ~4.2:1 | Champagne `#C8B08A` sobre Obsidian `#0F1114` | ⚠️ Límite AA (4.5:1) |
| Copper `#B8734A` sobre Graphite `#1C1F23` | N/A | Target | ❓ Desconocido |
| Warm Stone `#3A342E` sobre Obsidian | N/A | Target | ❓ Desconocido |
| Aura Teal `#164C46` sobre Warm White `#F2EFEA` | N/A | Target | ❓ Desconocido |
| CyberCyan `#00E5FF` sobre Obsidian | ~3.8:1 | **REMOVE** | ❌ Fallo AA |

#### Otros
- **Touch targets:** Mínimo 48dp — mayormente cumplido (botones 52-56px)
- **Focus states:** `FocusableActionDetector` no usado sistemáticamente — **PARCIAL**
- **Semantic labels:** `AudienceToggleWidget` tiene `Tooltip` implícito por icon+label — **OK**
- **Icon-only controls:** `IconButton` en AppBar back — **REQUIERE** `tooltip`/`semanticLabel`

---

## 6. ARCHIVOS/COMPONENTES AFECTADOS

### 6.1 Core Theme Files (Modificación Requerida)
| Archivo | Rol | Acción |
|---------|-----|--------|
| `lib/shared/mens_theme.dart` | Tema masculino | **REFACTOR** → Alinear a target palette |
| `lib/shared/glow_store_tokens.dart` | Tokens Store | **REFACTOR** → Integrar target Men tokens |
| `lib/shared/glow_tokens.dart` | Tokens base | **EXTEND** → Añadir Cormorant, Manrope, Men palette |
| `lib/shared/theme.dart` | Legacy theme | **DEPRECATE** → Migrar a tokens unificados |
| `lib/core/theme/tokens.dart` | BellezaLuxeTokens | **AUDITAR** — sistema femenino paralelo |
| `lib/core/theme/app_theme.dart` | ThemeData builders | **EXTEND** → Soporte Men target |

### 6.2 Screens Requiring Visual Updates
| Pantalla | Archivo | Prioridad |
|----------|---------|-----------|
| Store | `store_screen.dart` | P0 |
| Home/Providers | `main.dart` → `ProvidersScreen` | P0 |
| Client Bookings | `client_bookings_screen.dart` | P1 |
| Client Profile | `client_profile_screen.dart` | P1 |
| Aura Welcome | `aura_welcome_screen.dart` | P0 |
| Provider Detail | `provider_detail_screen.dart` | P1 |
| Login/Register | `login_screen.dart`, `register_screen.dart` | P1 |

### 6.3 Components
| Componente | Archivo | Acción |
|------------|---------|--------|
| `AudienceToggleWidget` | `lib/widgets/audience_toggle.dart` | ADAPT colors |
| `StoreProductCard` | `lib/widgets/store_product_card.dart` | ADAPT typography/colors |
| `ProductQuickViewDialog` | `lib/widgets/product_quick_view_dialog.dart` | ADAPT |
| `GlowGlassCard` | `lib/widgets/glow_glass_card.dart` | ADAPT Men colors |
| `GlowAppLogo` | `lib/widgets/branding/glow_app_logo.dart` | ADD Men variant |
| `LuxeComponents` | `lib/design/components/luxe_components.dart` | AUDIT Men parity |
| `AcademyLuxeComponents` | `lib/design/components/academy_luxe_components.dart` | AUDIT Men parity |

---

## 7. PROBLEMAS ARQUITECTÓNICOS

| # | Problema | Severidad | Descripción |
|---|----------|-----------|-------------|
| **A1** | **3+ sistemas de tokens paralelos** | Crítico | `AppTheme`, `MensTheme`, `GlowStoreTokens`, `BellezaLuxeTokens`, `GlowTokens`, `LuxeColors` — sin fuente única |
| **A2** | **MensTheme incompleto** | Crítico | Solo colores + 2 gradientes + 2 sombras. **Falta:** spacing, radius, elevation, tipografía, breakpoints, component overrides |
| **A3** | **Cyberpunk hardcodeado en Men** | Crítico | `cyberCyan` + `cyanScannerGlow` en `MensTheme` — contradice "Quiet Luxury" |
| **A4** | **Aura Welcome no adapta a Men** | Alto | Usa solo `GlowTokens` (femenino) — ignora `isMen` |
| **A5** | **No hay sistema de spacing centralizado** | Alto | 16+ valores hardcodeados en `store_screen.dart` |
| **A6** | **Tipografía fragmentada** | Medio | 5 familias declaradas, 3 usadas, 1 target (Cormorant) no usada, 1 target (Manrope) no declarada |
| **A7** | **Assets 100% femeninos/neutrales** | Crítico | 0 assets masculinos en repositorio |
| **A8** | **Duplicación de componentes** | Medio | `LuxeComponents` vs `AcademyLuxeComponents` vs `GlowStoreTokens` components vs inline en screens |

---

## 8. PROBLEMAS PURAMENTE VISUALES

| # | Problema | Archivo/Línea | Clasificación |
|---|----------|---------------|---------------|
| V1 | CyberCyan glow en scanner IA | `mens_theme.dart:14-15, 50-56` | **REPLACE** |
| V2 | Champagne Gold demasiado brillante/saturado | `mens_theme.dart:9` | **REPLACE** → Men Champagne `#C8B08A` |
| V3 | Overlay negro genérico en ProviderDetail | `provider_detail_screen.dart:231-235` | **ADAPT** → Warm gradient |
| V4 | Border improvised `bronzeAccent.withValues(alpha: 0.35)` | `glow_store_tokens.dart:221` | **REPLACE** → Men Warm Stone token |
| V5 | `Colors.grey.shade400` para texto secundario Men | `glow_store_tokens.dart:210` | **REPLACE** → Men Taupe token |
| V6 | `AppTheme.inputDecoration` solo femenino | `theme.dart:92-122` | **REPLACE** → Tokenizado |
| V7 | CardTheme radius 24 hardcodeado | `main.dart:142` | **ADAPT** → `radiusCard` (16) |
| V8 | Didot usada como "Editorial" en lugar de Cormorant | `glow_store_tokens.dart:118, 129, 140` | **REPLACE** → Cormorant |
| V9 | Aura Welcome CTA usa `roseGold` (femenino) | `aura_welcome_screen.dart:372` | **REPLACE** → Men Champagne |
| V10 | `glowapp_logo_horizontal_primary_dark.png` existe | `assets/images/branding/` | **REPLACE** → Men variant |

---

## 9. ASSETS FALTANTES (MISSING)

| Asset | Target Role | Prioridad |
|-------|-------------|-----------|
| Hero/Background Men (Home) | Landing masculino | P0 |
| Login Background Men | Auth masculino | P0 |
| Register Background Men | Auth masculino | P0 |
| Onboarding Men (3-5 screens) | Primer uso | P0 |
| Aura Welcome Background Men | IA masculine | P0 |
| Provider Cover Images Men | Barbería/Grooming/Skincare | P1 |
| Product Lifestyle Men | Store product cards | P1 |
| Male Muse Oficial (retrato) | Brand identity | P0 |
| GlowApp Logo Men Variant (Obsidian/Champagne) | Branding | P1 |
| Icon Set Monoline (SVG) | Navegación/UI | P1 |

---

## 10. DUPLICACIONES DETECTADAS

| Qué | Dónde | Impacto |
|-----|-------|---------|
| **Color Systems** | `AppTheme`, `MensTheme`, `GlowStoreTokens`, `BellezaLuxeTokens`, `GlowTokens`, `LuxeColors` | Confusión, inconsistencia, mantenimiento 6x |
| **Typography** | `GlowTokens` (5 familias) + `AppTheme` (serif genérico) + `GlowStoreTokens` (3 funcionales) | 3 sistemas, Cormorant no usada |
| **Shadows** | `MensTheme` (2) + `GlowStoreTokens` (3) + `AppTheme` (3) | 8 sombras, 3 sistemas |
| **Card Components** | `LuxeCard`, `AcademyLuxeCard`, `GlowGlassCard`, `StoreProductCard`, inline Cards | 5+ implementaciones |
| **Button Styles** | `LuxeButton`, `AcademyLuxeButton`, `ElevatedButton` inline, `GlowStoreTokens` CTA | 4+ sistemas |
| **Input Decoration** | `AppTheme.inputDecoration`, inline en Store, `LuxeTextField` | 3+ sistemas |

---

## 11. PUNTOS DE PALANCA (HIGH IMPACT, LOW EFFORT)

| # | Palanca | Archivos Afectados | Impacto Estimado | Esfuerzo |
|---|---------|-------------------|------------------|----------|
| **1** | **Unificar tokens en `GlowStoreTokens` + extender `MensTheme`** | `mens_theme.dart`, `glow_store_tokens.dart`, `glow_tokens.dart` | 80% de superficies/colores | Medio |
| **2** | **Eliminar `cyberCyan` / añadir `AURA TEAL` token** | `mens_theme.dart`, `glow_store_tokens.dart`, `aura_welcome_screen.dart` | Identidad IA transversal | Bajo |
| **3** | **Centralizar spacing/radius en `GlowStoreTokens`** | `glow_store_tokens.dart` + todos los screens | Consistencia global | Bajo |
| **4** | **Declarar/cargar Cormorant Garamond + Manrope** | `pubspec.yaml`, `glow_tokens.dart`, `glow_store_tokens.dart` | Brand voice + UI consistency | Medio |
| **5** | **Crear `MenAssetManifest` + pipeline fotografía** | Nuevo archivo + assets | Photography gap 0% → 100% | Muy Alto |
| **6** | **Adaptar `AuraWelcomeScreen` a `isMen`** | `aura_welcome_screen.dart` | AURA transversal real | Medio |
| **7** | **Tokenizar `InputDecoration` unificado Men/Women** | `glow_store_tokens.dart` + nuevo `GlowInputDecoration` | Forms consistency | Medio |
| **8** | **Consolidar Card/Button en componentes únicos** | `luxe_components.dart`, `academy_luxe_components.dart`, `glow_store_tokens.dart` | Maintenance -60% | Alto |

---

## 12. ELEMENTOS QUE DEBEN PRESERVARSE (KEEP)

| Elemento | Archivo | Razón |
|----------|---------|-------|
| `AudienceService` + `AudienceMode` enum | `audience_service.dart` | Arquitectura sólida, persistente, reactiva |
| `AudienceToggleWidget` | `audience_toggle.dart` | UX clara, animada, accesible |
| `GlowStoreTokens` surface hierarchy | `glow_store_tokens.dart:37-62` | Niveles 0-3 bien definidos, adaptativos |
| `GlowStoreTokens` radius system | `glow_store_tokens.dart:67-80` | 5 radii semánticos, consistentes |
| `GlowStoreTokens` shadow system | `glow_store_tokens.dart:85-110` | 3 sombras semánticas, no genéricas |
| `GlowGlassCard` | `glow_glass_card.dart` | Glassmorphism reutilizable, bien arquitecturado |
| `GlowAppLogo` (CustomPainter) | `glow_app_logo.dart` | Brand animation única, no raster |
| `SliverAppBar` parallax pattern | `provider_detail_screen.dart:198-366` | UX premium, mantener |
| `StoreScreen` cart drawer + checkout flow | `store_screen.dart:1046-1187, 214-397` | Lógica de negocio compleja, intacta |
| `ClientBookingsScreen` OTP/Review flow | `client_bookings_screen.dart` | Business logic crítica |
| `JetBrainsMono` para precios/datos | `glow_store_tokens.dart:149-168` | Correcto, mantener |
| `ValueListenableBuilder<AudienceMode>` pattern | `main.dart`, screens | Reactive, performante |

---

## 13. ELEMENTOS QUE DEBEN MODIFICARSE (ADAPT/REFACTOR)

| Elemento | Acción | Archivos |
|----------|--------|----------|
| `MensTheme` palette | **REFACTOR** → Target palette | `mens_theme.dart` |
| `GlowStoreTokens` color mapping | **REFACTOR** → Integrar Men target | `glow_store_tokens.dart` |
| `GlowStoreTokens.secondaryTextColor` Men | **REPLACE** → Men Taupe token | `glow_store_tokens.dart:209-213` |
| `GlowStoreTokens.borderColor` Men | **REPLACE** → Men Warm Stone token | `glow_store_tokens.dart:220-224` |
| `AuraWelcomeScreen` | **ADAPT** → `isMen` branch | `aura_welcome_screen.dart` |
| `ProviderDetailScreen` overlay | **ADAPT** → Warm gradient (no negro) | `provider_detail_screen.dart:231-235` |
| `StoreProductCard` typography | **ADAPT** → Cormorant/Manrope | `store_product_card.dart` |
| `ClientProfileScreen` forms | **ADAPT** → Men tokens | `client_profile_screen.dart` |
| `ClientBookingsScreen` dialogs | **ADAPT** → Men tokens | `client_bookings_screen.dart` |
| `main.dart` CardTheme | **ADAPT** → `radiusCard` token | `main.dart:142` |
| `glow_app_logo.dart` | **ADD** Men variant | `glow_app_logo.dart` |

---

## 14. ELEMENTOS QUE REQUIEREN RECONSTRUCCIÓN (REPLACE/REBUILD)

| Elemento | Estrategia | Razón |
|----------|------------|-------|
| **Sistema de color masculino completo** | **REPLACE** | `MensTheme` actual incompatible con target (cyberpunk, oro brillante) |
| **Fotografía masculina** | **REBUILD** | 0 assets existen — requiere shoot/producción |
| **AURA visual language Men** | **REBUILD** | Actual = femenino; cyberpunk en MenTheme |
| **Iconografía** | **REPLACE** | Material Icons → Monoline SVG set |
| **Tipografía Brand/Display** | **REPLACE** | Didot → Cormorant Garamond (cargar + usar) |
| **Tipografía Functional UI** | **REPLACE** | Inter → Manrope (cargar + usar) |
| **Login/Register/Onboarding Men** | **REBUILD** | Pantallas completas con identidad masculina |
| **Asset pipeline** | **CREATE** | No existe proceso para assets Men |

---

## 15. MATRIZ ESFUERZO/IMPACTO

| Acción | Impacto | Esfuerzo | Cuadrante |
|--------|---------|----------|-----------|
| Unificar tokens (GlowStoreTokens + MensTheme) | 🔴 Crítico | 🟡 Medio | **DO FIRST** |
| Eliminar cyberCyan / añadir Aura Teal | 🔴 Crítico | 🟢 Bajo | **QUICK WIN** |
| Centralizar spacing/radius | 🟠 Alto | 🟢 Bajo | **QUICK WIN** |
| Cargar Cormorant + Manrope | 🟠 Alto | 🟡 Medio | **PLAN** |
| Adaptar AuraWelcomeScreen a Men | 🔴 Crítico | 🟡 Medio | **DO FIRST** |
| Fotografía masculina (producción) | 🔴 Crítico | 🔴 Muy Alto | **STRATEGIC** |
| Reemplazar iconografía a monoline | 🟠 Alto | 🟠 Alto | **PLAN** |
| Consolidar componentes (Card/Button/Input) | 🟠 Alto | 🔴 Alto | **PHASE 2** |
| Reconstruir Login/Register/Onboarding Men | 🟠 Alto | 🔴 Alto | **PHASE 2** |
| Adaptar ProviderDetail overlay | 🟡 Medio | 🟢 Bajo | **QUICK WIN** |

---

## 16. ESTRATEGIA DE IMPLEMENTACIÓN (S0–S5)

| Área | Estrategia | Justificación |
|------|------------|---------------|
| **Audience Architecture** | **S0 — Mantener** | Funciona, probada, reactiva |
| **GlowStoreTokens Surface/Radius/Shadow** | **S0 — Mantener** | Bien arquitecturado, semántico |
| **MensTheme Palette** | **S4 — Reemplazar** | Incompatible con target (cyberpunk, oro brillante) |
| **Color Mapping (GlowStoreTokens)** | **S2 — Refactorizar** | Arquitectura sirve, solo mapeo a nuevos tokens |
| **Typography System** | **S3 — Crear Sistema** | No existe sistema unificado; Cormorant/Manrope faltan |
| **Spacing System** | **S3 — Crear Sistema** | No existe; 16+ valores hardcodeados |
| **AURA Visual Language** | **S4 — Reemplazar** | Actual = femenino + cyberpunk Men |
| **Iconography** | **S4 — Reemplazar** | Material Icons ≠ Monoline Quiet Luxury |
| **Photography/Assets** | **S5 — Reconstruir** | 0% cobertura masculina |
| **Login/Register/Onboarding Men** | **S4 — Reemplazar** | Pantallas completas femeninas |
| **ProviderDetail Overlay** | **S1 — Ajustar Tokens** | Solo gradient overlay |
| **Store Components** | **S2 — Refactorizar** | Usan GlowStoreTokens, adaptar mapeo |
| **Client Bookings/Profile** | **S2 — Refactorizar** | Usan MensTheme directo, migrar a GlowStoreTokens |
| **GlowAppLogo** | **S2 — Refactorizar** | Añadir variante Men |
| **Component Library** | **S3 — Crear Sistema** | 5+ implementaciones duplicadas |

---

## 17. ORDEN RECOMENDADO DE IMPLEMENTACIÓN

### FASE M1 — FOUNDATION (Semanas 1-2) — **CRÍTICO**
1. **M1.1** Definir `MenTokens` como extensión de `GlowStoreTokens` con paleta target completa
2. **M1.2** Eliminar `cyberCyan`/`cyanScannerGlow` de `MensTheme`; añadir `auraTeal` + `auraTealGlow`
3. **M1.3** Centralizar `spacing` (4-80 scale) + `radius` (8-24-full) en `GlowStoreTokens`
4. **M1.4** Declarar/cargar fuentes: **Cormorant Garamond** (Display) + **Manrope** (UI) en `pubspec.yaml` + `GlowTokens`
5. **M1.5** Actualizar `GlowStoreTokens` typography mappings → Cormorant/Manrope + mantener JetBrainsMono

### FASE M2 — CORE COMPONENTS (Semanas 2-3) — **ALTO**
6. **M2.1** Adaptar `AuraWelcomeScreen` → branch `isMen` con colores/backgrounds Men
7. **M2.2** Tokenizar `InputDecoration` unificado en `GlowStoreTokens` (Men/Women)
8. **M2.3** Actualizar `StoreProductCard`, `ProductQuickViewDialog` → nuevos tokens tipografía/color
9. **M2.4** Adaptar `AudienceToggleWidget` → target colors
10. **M2.5** Actualizar `main.dart` CardTheme/AppBarTheme → tokens centralizados

### FASE M3 — SCREENS (Semanas 3-4) — **ALTO**
11. **M3.1** `StoreScreen` — verificar todo flujo con nuevos tokens
12. **M3.2** `ClientBookingsScreen` — migrar de `MensTheme` directo a `GlowStoreTokens(isMen:true)`
13. **M3.3** `ClientProfileScreen` — idem
14. **M3.4** `ProviderDetailScreen` — overlay gradient cálido (no negro)
15. **M3.5** `GlowAppLogo` — variante Men (Obsidian/Champagne)

### FASE M4 — AURA & ICONOGRAPHY (Semanas 4-5) — **MEDIO**
16. **M4.1** Diseñar/implementar AURA Men: halos, geometría, Teal + Champagne + Light Geometry
17. **M4.2** Auditar `AuraMultiAgentChat`, `Aura3DEmblem` → adaptar a Men
18. **M4.3** Seleccionar/cargar set iconos monoline (Lucide/Phosphor/Custom SVG)
19. **M4.4** Migrar iconos críticos (nav, actions, categories) al nuevo set

### FASE M5 — PHOTOGRAPHY & POLISH (Semanas 5-8) — **ESTRATÉGICO**
20. **M5.1** Producción fotográfica Male Muse Oficial (hero, auth, onboarding, aura, providers, products)
21. **M5.2** Pipeline assets: naming, optimization, responsive variants, CDN
22. **M5.3** Reconstruir `LoginScreen`/`RegisterScreen`/`OnboardingScreen` variantes Men
23. **M5.4** Accessibility audit: contraste, touch targets, focus, semantics
24. **M5.5** Responsive testing: mobile/tablet/desktop Men flows
25. **M5.6** Visual regression testing + stakeholder sign-off

---

## 18. RIESGOS

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| **R1:** Fotografía Male Muse no disponible a tiempo | Alta | Crítico | Plan B: Stock photography curated + generative AI placeholders temporal |
| **R2:** Cormorant/Manrope licensing/issues de carga web | Media | Alto | Verificar licencias (Google Fonts = libres); fallback a Inter/Playfair |
| **R3:** Romper Women al refactorizar tokens compartidos | Media | Crítico | Tests visuales automatizados; feature flag `isMen` en cada cambio |
| **R4:** `cyberCyan` referenciado en código no auditado | Media | Alto | `grep -r cyberCyan` exhaustivo antes de eliminar |
| **R5:** Icon migration scope creep | Alta | Medio | Fase 4 solo iconos críticos (nav, CTA, category); resto fase posterior |
| **R6:** Performance regression en web (fuentes nuevas) | Baja | Medio | Preload fonts; `fontDisplay: swap`; medir LCP |
| **R7:** AURA transversal se rompe en Women al cambiar Men | Media | Alto | AURA tokens en `GlowStoreTokens`/`GlowTokens` base, no en `MensTheme` |

---

## 19. DEPENDENCIAS

| Dependencia | Bloquea | Resolución |
|-------------|---------|------------|
| `pubspec.yaml` fonts (Cormorant, Manrope) | M1.4, M2.1+ | Inmediato — 1 commit |
| Male Muse photography assets | M5.1, M5.2, M5.3 | Externa — coordinar con Creative/Photo |
| Icon set selection (Lucide vs Phosphor vs Custom) | M4.3 | Decisión diseño — 1 día |
| `flutter analyze` baseline limpio | Todas las fases | Pre-existente: 790 issues (freezed, riverpod, deprecations) — **NO BLOQUEA** visual audit |
| Backend API `gender_target` filtering | Store Men categories | Ya implementado (`store_screen.dart:115-125`) |

---

## 20. RECOMENDACIÓN FINAL

### Conclusión de Ingeniería Visual
> **Glow Men está a 28% de "Quiet Masculine Luxury". La arquitectura de switch de audiencia es sólida (S0), pero el sistema visual masculino actual es una "Dark Mode genérica con acento dorado y cyberpunk" que contradice la identidad objetivo en 4 dimensiones críticas: Color (cyberCyan), Tipografía (Cormorant ausente), Fotografía (0%), AURA (femenina + cyberpunk).**

### Decisión: **OPCIÓN C — REINGENIERÍA VISUAL**

> *"Existe una base funcional (audience switch, GlowStoreTokens, componentes adaptativos), pero la arquitectura visual actual no permite mantener coherentemente el nuevo sistema Quiet Masculine Luxury sin reemplazo sistemático de paleta, tipografía, fotografía, AURA e iconografía."*

### Próxima Fase Recomendada: **FASE M1 — FOUNDATION**
> Ejecutar pasos M1.1–M1.5 para establecer **fuente única de verdad visual masculina** antes de tocar cualquier pantalla. Esto desbloquea Fases M2-M3 con cambios tokenizados, no hardcodeados.

---

## 21. CIERRE OBLIGATORIO DEL REPORTE

### A. VEREDICTO
**NOT READY** — Requiere Reingeniería Visual (Opción C)

### B. TOP 10 PRIORIDADES
1. **Unificar tokens** → `GlowStoreTokens` + `MenTokens` con paleta target completa
2. **Eliminar `cyberCyan`** → Reemplazar por `AURA TEAL #164C46` en todo el código
3. **Centralizar spacing/radius** → Tokens semánticos en `GlowStoreTokens`
4. **Cargar Cormorant Garamond + Manrope** → `pubspec.yaml` + `GlowTokens`
5. **Adaptar `AuraWelcomeScreen` a `isMen`** → AURA transversal real
6. **Producir fotografía Male Muse Oficial** → 0% coverage actual
7. **Tokenizar `InputDecoration` unificado** → Forms consistentes Men/Women
8. **Migrar `StoreScreen`/`ClientBookings`/`ClientProfile` a `GlowStoreTokens(isMen:true)`** → Eliminar `MensTheme` directo
9. **Seleccionar/cargar icon set monoline** → Quiet Luxury consistency
10. **Reconstruir Login/Register/Onboarding Men** → Primera impresión masculina

### C. KEEP LIST
- `AudienceService` + `AudienceToggleWidget`
- `GlowStoreTokens` surface hierarchy (Level 0-3)
- `GlowStoreTokens` radius system (5 radii)
- `GlowStoreTokens` shadow system (3 semantic shadows)
- `GlowGlassCard` architecture
- `GlowAppLogo` CustomPainter
- `SliverAppBar` parallax pattern
- `StoreScreen` cart/checkout logic
- `JetBrainsMono` para precios/datos
- `ValueListenableBuilder<AudienceMode>` reactive pattern

### D. ADAPT LIST
- `GlowStoreTokens` color mapping Men → target palette
- `ProviderDetailScreen` overlay gradient → warm
- `StoreProductCard` typography → Cormorant/Manrope
- `AudienceToggleWidget` colors → target
- `main.dart` CardTheme radius → token
- `GlowAppLogo` → add Men variant

### E. REFACTOR LIST
- `MensTheme` → align to target (rename to `MenTokens`?)
- `GlowStoreTokens.secondaryTextColor` Men → Men Taupe
- `GlowStoreTokens.borderColor` Men → Men Warm Stone
- Component library consolidation (Luxe/Academy/Store/Glass)

### F. REPLACE LIST
- `MensTheme.cyberCyan` + `cyanScannerGlow` → **ELIMINAR**
- `MensTheme.champagneGold` → Men Champagne `#C8B08A`
- `MensTheme.bronzeAccent` → Men Copper `#B8734A`
- `Didot` (Editorial) → `Cormorant Garamond`
- `Inter` (Functional) → `Manrope`
- Material Icons → Monoline SVG set
- `AuraWelcomeScreen` (Women-only) → Dual audience
- `glowapp_logo_horizontal_primary_dark.png` → Men variant

### G. MISSING LIST
- Male Muse Oficial photography (hero, auth, onboarding, aura, providers, products)
- Men Champagne / Copper / Warm Stone / Taupe / Sand / Graphite / Warm White tokens
- Cormorant Garamond + Manrope font files
- Monoline icon set (SVG)
- Men-specific Login/Register/Onboarding/Aura screens
- `MenTokens` class completa (spacing, radius, elevation, typography, gradients, shadows, component overrides)

### H. DEPENDENCIAS
- Photography production (external)
- Font licensing verification (Google Fonts = free)
- Icon set design decision (1 day)
- Backend gender filtering (already done)

### I. RIESGOS PRINCIPALES
- R1: Photography timeline (external dependency)
- R3: Women regression during token refactor (mitigate: visual tests + feature flags)
- R4: `cyberCyan` hidden references (mitigate: exhaustive grep)
- R5: Icon migration scope creep (mitigate: phased, critical-only first)

### J. PRÓXIMA FASE RECOMENDADA
> **FASE M1 — FOUNDATION (Semanas 1-2)**
> Establecer `MenTokens` + `GlowStoreTokens` unificados con paleta target, spacing, radius, tipografía (Cormorant/Manrope), eliminación de `cyberCyan`, adición de `AURA TEAL`. **NO tocar pantallas todavía** — solo infraestructura visual. Validar con `flutter analyze` + build web + smoke test audiencia Men/Women.