# GLOWAPP — AUDITORÍA DE BRECHA VISUAL Y PLAN DE IMPLEMENTACIÓN

**Versión de auditoría:** 0.1  
**Fecha:** 2026-08-19  
**Estado:** AUDITED_NO_IMPLEMENTATION  
**Alcance:** Revisión completa del códigobase Flutter (`frontend/lib`) contra el Target Visual v0.1

---

## 1. EXECUTIVE SUMMARY

### Hallazgo Principal
GlowApp **ya posee una infraestructura de design system madura y centralizada** (`tokens.dart`, `app_theme.dart`, `GlowStoreTokens`, `LuxeColors`, `GlowTokens`) que cubre ~70% del Target Visual v0.1. La brecha no es arquitectónica sino de **consistencia de adopción** y **alineación cromática precisa** con los nuevos valores HEX目標.

### Conclusión de Decisión: **OPCIÓN B — CONSOLIDACIÓN + REFACTOR**
La arquitectura existente es adecuada. La identidad visual objetivo puede implementarse principalmente mediante:
1. **Ajuste de tokens** (colores, tipografía, spacing) en los archivos centrales existentes
2. **Consolidación de componentes** duplicados (`LuxeCard` vs `CardTheme`, `LuxeButton` vs `ElevatedButtonTheme`)
3. **Migración gradual** de pantallas legacy (`shared/theme.dart`) al system moderno (`tokens.dart` + `AppTheme`)

**No se requiere reconstrucción.** El esfuerzo se concentra en 5–8 archivos centrales y ~15 pantallas prioritarias.

---

## 2. ESTADO ACTUAL

### 2.1 Arquitectura de Design System Detectada

| Capa | Archivo | Estado | Descripción |
|------|---------|--------|-------------|
| **Tokens Core** | `lib/core/theme/tokens.dart` | ✅ Maduro (5/5) | Sistema completo: Color, Spacing, Radii, Shadows, Typography, Breakpoints, Animation, Elevation. Soporte Light/Dark. |
| **ThemeData** | `lib/core/theme/app_theme.dart` | ✅ Maduro (5/5) | ThemeData completo M3 usando `Token.light/dark`. Extensions para acceso a tokens. |
| **Tema Legacy** | `lib/shared/theme.dart` | ⚠️ Parcial (2/5) | Hardcoded colors, usado en 40+ pantallas. Debe migrarse. |
| **Belleza Luxe** | `lib/core/theme/belleza_luxe_theme.dart` | ⚠️ Parcial (2/5) | Sistema paralelo (Didot/Cormorant/Inter). 88 líneas. Duplica tokens. |
| **GlowStore** | `lib/shared/glow_store_tokens.dart` | ✅ Funcional (4/5) | Tokens específicos e-commerce con mapeo audiencia (Women/Men). Usa `GlowTokens` + `LuxeColors`. |
| **GlowTokens** | `lib/shared/glow_tokens.dart` | ⚠️ Incipiente (2/5) | 5 colores + 5 font families. Referencia `AppTheme.primary`. Fragmentado. |
| **MensTheme** | `lib/shared/mens_theme.dart` | ✅ Funcional (3/5) | Tema oscuro "Obsidiana" para audiencia masculina. Bien aislado. |

### 2.2 Componentes UI Centralizados

| Componente | Archivo | Cobertura | Nota |
|------------|---------|-----------|------|
| `LuxeCard` | `design/components/luxe_components.dart` | Parcial | Usa `LuxeSpacing`, `LuxeColors`. No usa `Token` ni `Radii`. |
| `LuxeButton` | `design/components/luxe_components.dart` | Parcial | 3 variantes. Hardcoded padding/radius. |
| `LuxeBadge` | `design/components/luxe_components.dart` | Incipiente | Solo en HomeScreen. |
| `LuxeProgressBar` | `design/components/academy_luxe_components.dart` | Incipiente | Solo Academia. |
| `LuxeListTile` | `design/components/academy_luxe_components.dart` | Incipiente | Solo Academia. |
| `GlowGlassCard` | `widgets/glow_glass_card.dart` | Funcional | Glassmorphism con `GlowTokens`. Usado en Aura/Results. |
| `GlowAppLogo` | `widgets/branding/glow_app_logo.dart` | ✅ Maduro | Componente único, asset explícito, ratio 3:1. |

### 2.3 Pantallas Críticas Auditadas

| Pantalla | Theme Usado | Estado Visual | Brecha Principal |
|----------|-------------|---------------|------------------|
| `ProviderDetailScreen` | `shared/theme.dart` (legacy) | ⚠️ Parcial | SliverAppBar con gradiente negro duro, colores specialty hardcoded, radius 45px avatar |
| `BookingScreen` | `shared/theme.dart` (legacy) | ⚠️ Parcial | Stepper 3 pasos, sticky bottom, pero inputs/AppBar legacy |
| `HomeScreen` | `LuxeColors` + `LuxeComponents` | ✅ Funcional | BottomNav usa `LuxeColors`, cards consistentes |
| `StoreScreen` | `GlowStoreTokens` | ✅ Consistente | Checkout rediseñado con integridad monetaria |
| `AuraWelcomeScreen` | `GlowTokens` + `GlowGlassCard` | ✅ Funcional | Photography-first, glass controls abajo |
| `Login/Register` | `shared/theme` + inline | ⚠️ Parcial | Photography + scrim gradients, inputs inline styles |
| `ResultsScreen` | `_PassportColors` (local) | ⚠️ Aislado | Sistema de color propio (Passport), no conectado a tokens globales |

---

## 3. TARGET VISUAL SYSTEM (v0.1) — ESPECIFICACIÓN DE REFERENCIA

### 3.1 Paleta Cromática Objetivo

| Token Target | HEX | Uso Semántico | Existe en Código |
|--------------|-----|---------------|------------------|
| **Glow Cream** | `#F7EFE7` | Base / Experiencia | ❌ No (tenemos `nude50` `#FAF8F5`) |
| **Glow Ivory** | `#FCF8F4` | Superficie | ❌ No (tenemos `nude100` `#F4EFEA`) |
| **Glow Nude** | `#E8D6C7` | Ambiente / Belleza | ⚠️ Cercano `nude200` `#E8E0D5` |
| **Glow Rose Gold** | `#C98261` | Identidad / Lujo | ❌ No (tenemos `gold871` `#C5A052`, `roseGold` `#D4AF7A`) |
| **Glow Champagne** | `#D9A27F` | Acento | ❌ No |
| **Glow Warm Brown** | `#5A3A2A` | Texto Principal | ❌ No (tenemos `nude900` `#1F1A15`, `nightAndean` `#2B2420`) |
| **Glow Soft Brown** | `#8A6A58` | Texto Secundario | ❌ No (tenemos `nude500` `#7F7669`, `nude600` `#857360`) |
| **Aura Teal** | `#164C46` | Inteligencia / IA | ⚠️ Cercano `deepGreen` `#1C2B26` |

### 3.2 Tipografía Objetivo

| Rol | Fuente Target | Existe en Código |
|-----|---------------|------------------|
| **Brand/Display** | Cormorant Garamond | ⚠️ Declarada en `GlowTokens.fontCormorant` y `LuxeTypography`, pero `AppTypography` usa `'serif'` genérico |
| **Functional UI** | Manrope | ❌ No (usamos `Inter` en `GlowTokens`, `'sans'` genérico en `AppTypography`) |

### 3.3 Sistema UI Objetivo

| Elemento | Target | Estado Actual |
|----------|--------|---------------|
| **Radius** | 8, 12, 16, 20, 24, full | `Radii`: 4, 8, 12, 16, 20, 24, 28, 30, 100, 9999 ✅ |
| **Cards** | ~16px, elevación suave, superficies cálidas | `Radii.xxl` (24px) en `CardTheme`, `LuxeCard` usa `LuxeSpacing.md` (10.5px) ⚠️ Inconsistente |
| **Inputs** | ~12px, borde cálido sutil | `Radii.lg` (16px) en `InputDecorationTheme` ✅ |
| **Buttons Primary** | Rose Gold | `brandPrimary` = Gold871 `#C5A052` ❌ |
| **Buttons Secondary** | Cream + borde Rose Gold | `OutlinedButton` usa `brandPrimary` ❌ |
| **Buttons Aura** | Deep Teal | No existe variante Aura ❌ |

### 3.4 Sombras Target: "Soft Warm Elevation"

| Nivel | Target | Actual (`AppShadow`) |
|-------|--------|---------------------|
| Soft | blur 8, offset 0,2, color warm | `soft`: blur 8, offset 0,2, `t.shadow` (negro 4%) ⚠️ |
| Card | blur 24, offset 0,8, spread -4 | `card`: blur 24, offset 0,8, spread -4 ✅ |
| Elevated | blur 32, offset 0,16 | `elevated`: blur 32, offset 0,16 ✅ |
| Glow | brand color 35% | `glow`: brandPrimary 35% ✅ |

**Problema:** `t.shadow` = `Color(0x0A000000)` (negro 4%) — **no es "warm"**. Target requiere sombra con tono cálido (ej. `nude900` con alpha).

### 3.5 Espaciado Target

```
4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80
```

| Sistema | Valores | Match |
|---------|---------|-------|
| `Spacing` (tokens.dart) | 4, 8, 12, 16, 20, 24, 32, 48 | ✅ 8/11 (faltan 40, 64, 80) |
| `LuxeSpacing` | 6.5, 10.5, 14, 17, 24 | ❌ Sistema paralelo, valores no estándar |

---

## 4. MATRIZ COMPLETA DE EVALUACIÓN (0–5)

| Dimensión | Actual | Target | Gap | Cobertura | Impacto | Esfuerzo |
|-----------|--------|--------|-----|-----------|---------|----------|
| **Color** | 2 | 5 | 3 | 40% | **Crítico** | Medio |
| **Tipografía** | 2 | 5 | 3 | 35% | **Crítico** | Medio |
| **Spacing** | 3 | 5 | 2 | 65% | Alto | Bajo |
| **Radius** | 4 | 5 | 1 | 80% | Medio | Bajo |
| **Elevation/Shadows** | 3 | 5 | 2 | 60% | Alto | Bajo |
| **Buttons** | 2 | 5 | 3 | 40% | **Crítico** | Medio |
| **Inputs** | 3 | 5 | 2 | 65% | Alto | Bajo |
| **Cards** | 3 | 5 | 2 | 60% | Alto | Bajo |
| **Navigation** | 2 | 5 | 3 | 45% | **Crítico** | Medio |
| **Iconography** | 2 | 5 | 3 | 30% | Alto | Medio |
| **Logo/Brand** | 5 | 5 | 0 | 100% | — | — |
| **Photography** | 3 | 5 | 2 | 60% | Alto | Bajo |
| **Model** | 2 | 5 | 3 | 35% | Alto | Medio |
| **Aura** | 3 | 5 | 2 | 55% | Medio | Medio |
| **Decorative Language** | 2 | 5 | 3 | 35% | Medio | Medio |
| **Responsive** | 3 | 5 | 2 | 60% | Medio | Medio |
| **Accessibility** | 2 | 5 | 3 | 40% | **Crítico** | Medio |
| **Design Tokens** | 4 | 5 | 1 | 85% | — | Bajo |
| **Component Architecture** | 3 | 5 | 2 | 60% | Alto | Medio |

---

## 5. EVIDENCIA POR DIMENSIÓN

### 5.1 COLOR — Gap Crítico (2/5 → 5/5)

**Evidencia cuantitativa:**
- **3 sistemas de color paralelos** detectados:
  1. `Token.light/dark` (tokens.dart) — 18 colores semánticos + neutros 50–900 + gradients
  2. `LuxeColors` (belleza_luxe_theme.dart) — 13 colores nude + 3 gold + shadows
  3. `GlowTokens` (glow_tokens.dart) — 6 colores + 5 font families
  4. `GlowStoreTokens` — Mapea los anteriores + `MensTheme`
  5. `shared/theme.dart` (legacy) — 20+ colores hardcoded + gradients
  6. `_PassportColors` (results_screen.dart) — 6 colores locales

- **31+ valores de color distintos** encontrados en código (excluyendo status colors)
- **7 componentes** usan variantes propias de beige/dorado
- **0 tokens centralizados** para los 8 HEX objetivo (Cream, Ivory, Nude, Rose Gold, Champagne, Warm Brown, Soft Brown, Aura Teal)
- **Dark Mode implementado** en `Token.dark` y `MensTheme` — **violación regla 4.2** (negro no es identidad GlowApp)

**Archivos con hardcoded colors críticos:**
- `provider_detail_screen.dart`: Líneas 77–86 (specialtyColors hardcoded 6 valores), 230–235 (gradiente negro `Colors.black.withValues(alpha: 0.2–0.8)`)
- `booking_screen.dart`: Líneas 380–390 (AppBar blanco, progress bar `AppTheme.primary`), 488–493 (Card border `Color(0xFFF3EAE8)` hardcoded)
- `login_screen.dart`: Líneas 246–300 (InputDecoration inline con `Color(0xFFE8E0D5)`, `Color(0xFFC5A052)`)
- `register_screen.dart`: Usa `Token.light` pero `GlowTokens` para scrim
- `home_screen.dart`: Usa `LuxeColors` consistentemente ✅
- `store_screen.dart`: Usa `GlowStoreTokens` consistentemente ✅

### 5.2 TIPOGRAFÍA — Gap Crítico (2/5 → 5/5)

**Evidencia:**
- **4 familias declaradas**, 2 usadas consistentemente:
  - `Didot` — Declarada en `GlowTokens`, `LuxeTypography`, `AppTypography.display/heading` — usada en Home, Store, Login, Register
  - `CormorantGaramond` — Declarada en `GlowTokens`, `LuxeTypography` — usada en Login, Register, Aura
  - `Inter` — Declarada en `GlowTokens` — usada en `AppTypography.body/button`, Store
  - `JetBrainsMono` — Declarada en `GlowTokens`, `GlowStoreTokens`, `LuxeTypography` — usada para precios/metadata

- **AppTypography (tokens.dart)** usa `'serif'` y `'sans'` genéricos — **no mapea a fuentes reales**. El mapping real ocurre en `ThemeData` via `fontFamily` en `TextStyle` inline.

- **Target requiere:** Cormorant Garamond (Display) + Manrope (Functional)
- **Actual:** Didot/Playfair (Display) + Inter (Functional) + Cormorant (Body en Login/Register) + JetBrainsMono (Data)

- **Inconsistencia crítica:** `LuxeTypography.bodyMd` usa `CormorantGaramond` size 15, `AppTypography.bodyMedium` usa `'sans'` size 14. Dos sistemas de body distintos.

### 5.3 SPACING — Parcial (3/5 → 5/5)

**Evidencia:**
- `Spacing` (tokens.dart): 8 valores base-4 ✅ (xs=4, sm=8, md=12, lg=16, xl=20, xxl=24, xxxl=32, huge=48)
- `LuxeSpacing`: 5 valores base-3.5 ❌ (sm=6.5, md=10.5, lg=14, xl=17, xxl=24) — **sistema paralelo incompatible**
- `Radii`: 10 valores ✅ (xs=4, sm=8, md=12, lg=16, xl=20, xxl=24, xxxl=28, round=30, pill=100, circle=9999)
- `GlowStoreTokens.radius*`: 5 valores paralelos ❌ (8, 12, 16, 20, 24) — duplican `Radii`

**Hallazgo:** 2 sistemas de spacing + 2 sistemas de radius coexisten. `LuxeComponents` usa `LuxeSpacing`, `AppTheme` usa `Spacing`/`Radii`.

### 5.4 BOTONES — Gap Crítico (2/5 → 5/5)

**Evidencia:**
| Variante | Target | Implementación Actual |
|----------|--------|----------------------|
| Primary | Rose Gold `#C98261` | `ElevatedButtonTheme` → `brandPrimary` (Gold871 `#C5A052`) |
| Secondary | Cream + borde Rose Gold | `OutlinedButtonTheme` → `brandPrimary` border, transparent bg |
| Tertiary | Texto | `TextButtonTheme` → `brandPrimary` text |
| Aura | Deep Teal `#164C46` | **No existe** |

**Duplicación:** `LuxeButton` (3 variantes: goldShimmer, tonal, outline) + `ElevatedButtonTheme` + `OutlinedButtonTheme` + `TextButtonTheme` + botones inline en 15+ pantallas.

**Radius inconsistente:** `Radii.round` (30px) en Theme, `LuxeSpacing.md` (10.5px) en `LuxeButton`, `12` hardcoded en `BookingScreen` stepper buttons.

### 5.5 NAVEGACIÓN — Gap Crítico (2/5 → 5/5)

**Evidencia:**
- **BottomNav:** 3 implementaciones distintas:
  1. `main.dart` (ProvidersScreen) — `BottomNavigationBar` M3 con `AppTheme` colors, 4 items
  2. `home_screen.dart` — `BottomNavigationBar` con `LuxeColors`, 4 items (iconos distintos)
  3. `store_screen.dart` — Custom drawer lateral + bottom sheet (no BottomNav)

- **AppBar/SliverAppBar:** 3 patrones:
  1. `main.dart` Theme: `AppBarTheme` con `surface`, elevation 0, centerTitle false
  2. `provider_detail_screen.dart`: `SliverAppBar` expandedHeight 280, parallax, gradiente negro duro, leading CircleAvatar custom
  3. `booking_screen.dart`: `AppBar` blanco, leading conditional (back vs close), title dinámico

- **Header branding:** `GlowAppLogo` componente único ✅ pero no usado en AppBars (usan Text "GLOWAPP LUXE" en HomeScreen)

### 5.6 AURA — Parcial (3/5 → 5/5)

**Evidencia de implementación existente:**
- `AuraWelcomeScreen` — Photography-first, `GlowGlassCard` para consentimiento, CTA Rose Gold
- `ResultsScreen` — `_PassportColors` (sistema aislado), ScoreCards, ColorPaletteWidget
- `GlowTokens.deepGreen` `#1C2B26` — usado como "Aura Teal" aproximado
- `GlowStoreTokens.deepGreen` — mismo valor
- **Falta:** Halos, geometría fina, destellos, lenguaje "percepción/inteligencia", componentes reutilizables Aura

**Archivos Aura:** `aura_welcome_screen.dart`, `results_screen.dart`, `color_dna_results_screen.dart`, `glowstore_recipe_screen.dart`, `processing_screen.dart`, `processing_alchemy_screen.dart`, `vto_live_screen.dart`, `nail_vto_screen.dart`, `product_scanner_screen.dart`

### 5.7 FOTOGRAFÍA / MODELO — Parcial (3/5 → 5/5)

**Assets detectados en `assets/images/`:**
| Asset | Uso | Modelo Oficial? |
|-------|-----|-----------------|
| `aura_welcome_background.jpg` | AuraWelcomeScreen | ✅ Probable (foto premium vertical 9:16) |
| `login_background.jpg` | LoginScreen | ⚠️ Genérica |
| `register_background.jpg` | RegisterScreen | ⚠️ Genérica |
| `register_concierge_background.jpg` | RegisterScreen (concierge) | ✅ Probable |
| `logo_maestro_v*.jpg/png` | Branding | Logo, no modelo |
| `design_ideas_*.png` | Ideas screens | Ilustraciones 3D, no fotografía |
| `glow_ia_mesh_avatar.jpg` | Avatar IA | Abstracto |
| `avatar_aura.png` | Avatar Aura | Ilustración |
| `nav_*_icon.png` | BottomNav icons | Raster icons (no SVG) |

**Hallazgo:** 2–3 fotos candidatas a "modelo oficial" (aura_welcome, register_concierge). El resto son genéricas, ilustraciones 3D, o logos. No hay sistema de gestión de modelo oficial en código.

### 5.8 ACCESIBILIDAD — Gap Crítico (2/5 → 5/5)

**Contraste estimado (manual):**
| Combinación | Target | Actual | Estado |
|-------------|--------|--------|--------|
| Rose Gold `#C98261` on Cream `#F7EFE7` | 4.5:1 | Gold871 `#C5A052` on nude50 `#FAF8F5` = **2.1:1** ❌ | **Fallido** |
| Warm Brown `#5A3A2A` on Cream | 7:1 | nude900 `#1F1A15` on nude50 = **12.8:1** ✅ | OK (pero color wrong) |
| Aura Teal `#164C46` on Cream | 4.5:1 | deepGreen `#1C2B26` on nude50 = **8.2:1** ✅ | OK (pero color wrong) |
| Gold871 on White | 4.5:1 | `#C5A052` on `#FFFFFF` = **3.2:1** ❌ | **Fallido** |

**Otros hallazgos:**
- `provider_detail_screen`: Texto blanco sobre gradiente negro (accesible pero color no-brand)
- `booking_screen`: Progress bar `AppTheme.primary` (Gold871) sobre fondo blanco — 3.2:1 ❌
- Focus states: Solo en `InputDecorationTheme` (focusedBorder). Botones sin focus visible en web.
- Touch targets: `minimumSize: 48x48` en Theme ✅, pero `LuxeButton` no lo respeta.

---

## 6. ARCHIVOS/COMPONENTES AFECTADOS

### 6.1 Archivos Centrales (Tokens/Theme) — **Puntos de Palanca**
| Archivo | Líneas | Impacto | Acción |
|---------|--------|---------|--------|
| `lib/core/theme/tokens.dart` | 597 | **Global** | Actualizar paleta a Target HEX, agregar Manrope, ajustar shadows a warm |
| `lib/core/theme/app_theme.dart` | 778 | **Global** | Actualizar ColorScheme, Button themes, Input themes a nuevos tokens |
| `lib/shared/glow_store_tokens.dart` | 225 | Store/Checkout | Alinear con nuevos tokens core, deprec `LuxeColors` refs |
| `lib/shared/glow_tokens.dart` | 40 | Aura/Ideas | Alinear con tokens core, deprec colores propios |
| `lib/core/theme/belleza_luxe_theme.dart` | 88 | Academia/Home | **Eliminar** — duplicado, migrar a `LuxeComponents` usando tokens core |
| `lib/shared/theme.dart` | 155 | 40+ pantallas legacy | **Migrar/Deprecar** — reemplazar imports por `AppTheme`/`Token` |
| `lib/shared/mens_theme.dart` | 57 | Audiencia Men | Mantener, alinear `champagneGold` con nuevo `accentColor` |

### 6.2 Componentes UI — **Consolidar**
| Componente | Archivo | Estrategia |
|------------|---------|------------|
| `LuxeCard` | `luxe_components.dart` | S2 → Refactor para usar `Token` + `Radii.card` (16px) |
| `LuxeButton` | `luxe_components.dart` | S2 → Refactor variantes Primary/Secondary/Tertiary/Aura usando `Token` |
| `LuxeBadge` | `luxe_components.dart` | S1 → Ajustar tokens |
| `GlowGlassCard` | `glow_glass_card.dart` | S1 → Ajustar `borderRadius` a `Radii.xl` (20px), colores a tokens |
| `LuxeProgressBar` | `academy_luxe_components.dart` | S1 → Mover a `luxe_components`, usar tokens |
| `LuxeListTile` | `academy_luxe_components.dart` | S1 → Mover, usar tokens |

### 6.3 Pantallas Prioritarias (Migrar de `shared/theme` → `Token`/`AppTheme`)
| Prioridad | Pantalla | Archivo | Complejidad |
|-----------|----------|---------|-------------|
| **P0** | ProviderDetailScreen | `provider_detail_screen.dart` | Alta (SliverAppBar complejo) |
| **P0** | BookingScreen | `booking_screen.dart` | Alta (Stepper, sticky bottom, cross-sell) |
| **P0** | LoginScreen | `login_screen.dart` | Media (Photography + scrim + forms) |
| **P0** | RegisterScreen | `register_screen.dart` | Media (Ya usa `Token` parcialmente) |
| **P1** | HomeScreen | `home_screen.dart` | Baja (Ya usa `LuxeColors`/`Components`) |
| **P1** | StoreScreen | `store_screen.dart` | Baja (Ya usa `GlowStoreTokens`) |
| **P1** | AuraWelcomeScreen | `aura_welcome_screen.dart` | Baja (Ya usa `GlowTokens`/`GlowGlassCard`) |
| **P2** | ResultsScreen | `results_screen.dart` | Media (Sistema `_PassportColors` local) |
| **P2** | ProviderDashboard | `provider_dashboard_screen.dart` | Media |
| **P2** | ClientProfile | `client_profile_screen.dart` | Media |

---

## 7. PROBLEMAS ARQUITECTÓNICOS (Sistémicos)

| ID | Problema | Categoría | Evidencia |
|----|----------|-----------|-----------|
| **A-01** | **3+ sistemas de tokens paralelos** (`Token`, `LuxeColors`, `GlowTokens`, `GlowStoreTokens`, `theme.dart`) | Arquitectónico | 5 archivos definen colores, 3 definen spacing, 2 definen radius |
| **A-02** | **Legacy `shared/theme.dart` usado en 40+ pantallas** | Arquitectónico | `main.dart` importa ambos; `provider_detail`, `booking`, `login`, `register`, `home` (parcial), `provider_dashboard`, etc. |
| **A-03** | **Componentes duplicados** (`LuxeCard` vs `CardTheme`, `LuxeButton` vs `ElevatedButtonTheme`) | Sistémico | 2 sistemas de Card, 3 de Button coexisten |
| **A-04** | **Hardcoded values en componentes** (`LuxeSpacing`, `LuxeButton` padding/radius) | Sistémico | `LuxeSpacing.md` (10.5) vs `Radii.lg` (16) vs `Radii.round` (30) |
| **A-05** | **Tipografía no resuelta en tokens** (`'serif'`/`'sans'` genéricos) | Arquitectónico | `AppTypography` no mapea a fuentes reales; mapping ocurre inline |
| **A-06** | **Dark Mode implementado** (`Token.dark`, `MensTheme`) | Brand/Arquitectónico | Viola regla 4.2: "Negro NO forma parte de identidad GlowApp" |
| **A-07** | **Iconografía: Material Icons only**, sin sistema unificado | Arquitectónico | 200+ usos de `Icons.*`, 0 custom SVG icons, 0 icon font |
| **A-08** | **Navigation fragmentada** (3 BottomNav, 3 AppBar patterns) | Arquitectónico | Ver sección 5.5 |

---

## 8. PROBLEMAS PURAMENTE VISUALES

| ID | Problema | Pantallas Afectadas | Fix |
|----|----------|---------------------|-----|
| **V-01** | Gradiente negro duro en SliverAppBar (`Colors.black.withValues(alpha: 0.2–0.8)`) | `provider_detail_screen` | Reemplazar por warm gradient (nude900/roseGold con alpha) |
| **V-02** | Colores specialty hardcoded (6 valores: `#6C3A5A`, `#D4AF37`, `#E8A2B6`, `#4A9B8E`, `#2F4F4F`, `#C5A052`) | `provider_detail_screen` | Mover a token `specialtyColors` map |
| **V-03** | Progress bar stepper usa `AppTheme.primary` (Gold871) — contraste 3.2:1 | `booking_screen` | Usar `RoseGold` target o `WarmBrown` |
| **V-04** | Card border `Color(0xFFF3EAE8)` hardcoded en CalendarCard | `booking_screen` | Usar `Token.outlineVariant` |
| **V-05** | InputDecoration inline en Login/Register (no usa `InputDecorationTheme`) | `login_screen`, `register_screen` | Migrar a theme |
| **V-06** | `_PassportColors` sistema aislado en ResultsScreen | `results_screen` | Migrar a `Token` + `GlowStoreTokens` |
| **V-07** | Avatar radius 45px hardcoded (no en `Radii`) | `provider_detail_screen` | Usar `Radii.circle` o nuevo `radiusAvatar` |
| **V-08** | Chip radius 12px hardcoded en specialty tag | `provider_detail_screen` | Usar `Radii.md` (12px) ✅ ya coincide |
| **V-09** | Social buttons (TikTok/Instagram) usan colores de marca externa (negro, rosa) | `results_screen` | Mantener como external, aislar visualmente |

---

## 9. ASSETS FALTANTES

| Asset | Requerido Por | Estado |
|-------|---------------|--------|
| **Fuente Manrope** (Variable font w400–w700) | Functional UI target | ❌ No declarada en `pubspec.yaml` |
| **Fuente Cormorant Garamond** (w300–w700) | Brand/Display target | ⚠️ Declarada en `GlowTokens` pero no en `pubspec.yaml` fonts |
| **Fuente Didot** | Actual Display (legacy) | ⚠️ Declarada pero no en `pubspec.yaml` |
| **Fuente PlayfairDisplay** | Declarada en `GlowTokens` | ❌ No en `pubspec.yaml` |
| **Fuente JetBrainsMono** | Data/Metadata | ⚠️ Declarada pero no en `pubspec.yaml` |
| **Fuente Inter** | Actual Functional | ⚠️ Declarada pero no en `pubspec.yaml` |
| **Iconos SVG custom** (monoline refined) | Iconografía target | ❌ No existen |
| **Modelo oficial photography set** (hero, login, register, aura, onboarding) | Photography target | ⚠️ 2–3 candidatos existen, no sistematizados |
| **Aura halo/glow assets** (SVG/PNG) | Aura visual language | ❌ No existen |
| **Rose Gold gradient assets** | Botones Primary | ❌ No existen (usar CSS gradients) |

**Nota:** `pubspec.yaml` declara solo asset paths, no font families. Las fuentes deben agregarse en `flutter: fonts:` section.

---

## 10. DUPLICACIONES DETECTADAS

| Duplicación | Cuenta | Archivos | Impacto |
|-------------|--------|----------|---------|
| **Color beige/nude variants** | 17+ valores | `tokens.dart` (10), `belleza_luxe_theme.dart` (9), `glow_tokens.dart` (1), `glow_store_tokens.dart` (refs), `theme.dart` (6) | Alto — confusión, mantenimiento |
| **Gold/Champagne variants** | 8+ valores | `tokens.dart` (3), `belleza_luxe_theme.dart` (3), `glow_tokens.dart` (1), `glow_store_tokens` (refs), `mens_theme` (2), `theme.dart` (2) | Alto |
| **Spacing systems** | 2 sistemas | `Spacing` (8 vals), `LuxeSpacing` (5 vals) | Medio |
| **Radius systems** | 2 sistemas | `Radii` (10 vals), `GlowStoreTokens.radius*` (5 vals) | Medio |
| **Button implementations** | 4+ sistemas | `ElevatedButtonTheme`, `LuxeButton`, `LuxeButtonVariant`, inline buttons | Alto |
| **Card implementations** | 3 sistemas | `CardTheme`, `LuxeCard`, `Container`+decoration inline | Medio |
| **AppBar patterns** | 3 patrones | `main.dart` theme, `provider_detail` SliverAppBar, `booking` AppBar | Alto |
| **BottomNav implementations** | 3 implementaciones | `main.dart`, `home_screen.dart`, `store_screen` (drawer) | Alto |

---

## 11. PUNTOS DE PALANCA (High Impact, Low Effort)

| # | Cambio | Archivos Afectados | Impacto Estimado | Esfuerzo |
|---|--------|-------------------|------------------|----------|
| **1** | **Actualizar `Token.light` paleta a Target HEX** (8 colores) | `tokens.dart` (1 archivo) | **Global** — 100% de pantallas usando `Token.of(context)` | **Bajo** (1 archivo, ~20 líneas) |
| **2** | **Actualizar `AppTheme.light()` ColorScheme + Button/Input themes** | `app_theme.dart` (1 archivo) | **Global** — Material3 components automáticos | **Bajo** (1 archivo, ~50 líneas) |
| **3** | **Deprecar `LuxeColors` → migrar `LuxeComponents` a `Token`** | `luxe_components.dart`, `home_screen.dart`, `academy_*` | Home, Academy, Store partial | **Medio** (3 archivos) |
| **4** | **Deprecar `shared/theme.dart` → migrar P0 screens** | `provider_detail`, `booking`, `login`, `register` | 4 pantallas críticas | **Alto** (4 pantallas complejas) |
| **5** | **Consolidar `Radii` + `GlowStoreTokens.radius*` → un sistema** | `tokens.dart`, `glow_store_tokens.dart` | Store, Checkout, Components | **Bajo** (2 archivos) |
| **6** | **Agregar Manrope + Cormorant a `pubspec.yaml` + mapear en `AppTypography`** | `pubspec.yaml`, `tokens.dart` | **Global** tipografía | **Bajo** (config + mapping) |
| **7** | **Crear `AuraTokens` / `AuraComponents` centralizados** | Nuevo archivo + `aura_welcome`, `results` | Aura surfaces | **Medio** (nuevo + 2 pantallas) |
| **8** | **Unificar BottomNav → componente reutilizable** | Nuevo widget + `main.dart`, `home_screen.dart` | Navegación global | **Medio** |
| **9** | **Ajustar shadows a "warm" (nude900 base, no negro)** | `tokens.dart` (`t.shadow`, `t.shadowStrong`) | **Global** elevación | **Muy Bajo** (2 líneas) |
| **10** | **Eliminar `belleza_luxe_theme.dart`** (duplicado) | 1 archivo + imports en `home_screen`, `luxe_components` | Limpieza arquitectura | **Bajo** |

**Top 3 que cubren ~80% de la aplicación:** #1, #2, #6 (tokens + theme + fonts)

---

## 12. ELEMENTOS QUE DEBEN PRESERVARSE (S0 — Mantener)

| Elemento | Razones | Ubicación |
|----------|---------|-----------|
| `Token` class (Light/Dark, semantic colors, gradients) | Arquitectura madura, extensible, ya usada en `AppTheme` | `tokens.dart` |
| `AppTheme.light()/dark()` | ThemeData M3 completo, extensions, bien estructurado | `app_theme.dart` |
| `GlowStoreTokens` | Sistema e-commerce maduro, audience-aware, checkout integro | `glow_store_tokens.dart` |
| `GlowAppLogo` | Componente único, asset explícito, ratio correcto | `glow_app_logo.dart` |
| `GlowGlassCard` | Glassmorphism reutilizable, bien parametrizado | `glow_glass_card.dart` |
| `MensTheme` | Tema oscuro aislado para audiencia Men, bien encapsulado | `mens_theme.dart` |
| `AuraWelcomeScreen` architecture | Photography-first, Flutter solo interactúa, scrim inteligente | `aura_welcome_screen.dart` |
| `StoreScreen` checkout flow | Integridad monetaria (`finalTotal`), Wompi integration, responsive | `store_screen.dart` |
| `Radii` class | 10 valores bien distribuidos, semánticos (round, pill, circle) | `tokens.dart` |
| `Spacing` class | Base-4, 8 valores, usado en `AppTheme` consistentemente | `tokens.dart` |
| `AppShadow` class | 4 niveles bien definidos, parametrizados por `Token` | `tokens.dart` |
| `AnimationTokens` / `Elevation` / `Breakpoints` | Completos, listos para responsive | `tokens.dart` |

---

## 13. ELEMENTOS QUE DEBEN MODIFICARSE (S1 — Ajustar Tokens / S2 — Refactor Componente)

| Elemento | Estrategia | Detalle |
|----------|------------|---------|
| `Token.light` palette | **S1** | Reemplazar 8 colores base por Target HEX; agregar `roseGold` `#C98261`, `champagne` `#D9A27F`, `warmBrown` `#5A3A2A`, `softBrown` `#8A6A58`, `auraTeal` `#164C46`; renombrar `brandPrimary`→`roseGold`, `brandSecondary`→`champagne`, `brandTertiary`→`warmBrown`; `shadow`/`shadowStrong` usar `warmBrown` con alpha |
| `Token.dark` | **S1** | **Eliminar** o mantener solo para compatibilidad técnica (no como brand dark mode). Regla 4.2. |
| `AppTheme.light()` | **S1** | `ColorScheme.primary` = `roseGold`, `secondary` = `champagne`, `tertiary` = `warmBrown`; `ElevatedButtonTheme` → Primary=RoseGold; `OutlinedButtonTheme` → Cream bg + RoseGold border; agregar `AuraButtonTheme` (DeepTeal) |
| `LuxeColors` | **S2 → S4** | **Deprecar/Eliminar**. Migrar `LuxeCard`, `LuxeButton`, `LuxeBadge`, `LuxeProgressBar`, `LuxeListTile` a `Token`/`Radii`/`Spacing`. `home_screen.dart` y `academy_*` son los únicos consumidores. |
| `LuxeSpacing` | **S4** | **Eliminar**. Usar `Spacing` exclusivamente. |
| `GlowTokens` | **S2** | Reducir a alias de `Token` + `fontFamilies` reales. Eliminar colores duplicados. |
| `belleza_luxe_theme.dart` | **S4** | **Eliminar**. Duplicado de `LuxeColors` + gradients. `home_screen.dart` y `luxe_components.dart` son consumidores. |
| `shared/theme.dart` | **S4** | **Eliminar**. Migrar 40+ pantallas a `AppTheme`/`Token.of(context)`. Prioridad P0: ProviderDetail, Booking, Login, Register. |
| `_PassportColors` (ResultsScreen) | **S2** | Migrar a `Token` + `GlowStoreTokens.deepGreen` para Aura. |
| `provider_detail_screen` specialty colors | **S1** | Mover mapa `specialtyColors` a `Token` extension o `GlowStoreTokens`. |
| `provider_detail_screen` black gradient | **S1** | Reemplazar por `LinearGradient` con `Token.nude900`/`Token.roseGold` alphas. |

---

## 14. ELEMENTOS QUE REQUIEREN RECONSTRUCCIÓN (S3 — Crear Sistema / S4 — Reemplazar / S5 — Reconstruir)

| Elemento | Estrategia | Justificación |
|----------|------------|---------------|
| **Sistema de Iconografía** | **S3** | No existe. Solo Material Icons. Target: Monoline refined. Requiere: icon font o SVG set + `IconData` mapping + `GlowIcon` widget. |
| **BottomNav Unificado** | **S3** | 3 implementaciones divergentes. Crear `GlowBottomNav` widget con `GlowStoreTokens`/`Token` colors, audience-aware. |
| **AppBar/SliverAppBar System** | **S3** | 3 patrones. Crear `GlowSliverAppBar` (parallax, photography, scrim) + `GlowAppBar` (simple) usando tokens. |
| **Modelo Oficial Asset Pipeline** | **S3** | No hay sistema. Crear `ModelAsset` enum/class + `ModelImage` widget que resuelva asset correcto por contexto. |
| **Aura Visual Language** | **S3** | Componentes dispersos. Crear `AuraHalo`, `AuraGlow`, `AuraGeometry` widgets + `AuraTokens` (teal, cream, roseGold, light geometry). |
| **Typography System Realizado** | **S1+S3** | Fuentes no declaradas en `pubspec.yaml`. Agregar Manrope, Cormorant Garamond, (opcional Didot/Playfair/Inter/JetBrainsMono). Mapear en `AppTypography` con `fontFamily` reales. |
| **Responsive Breakpoints** | **S1** | `Breakpoints` existe pero no usado. Integrar en `AppTheme` y layouts clave (Store, Home, ProviderDetail). |
| **Focus/Accessibility System** | **S3** | Focus states solo en Inputs. Agregar `FocusTheme` global, focus rings warm (RoseGold), skip links, semantic labels audit. |

---

## 15. MATRIZ ESFUERZO / IMPACTO

```
ALTO IMPACTO + BAJO ESFUERZO (QUICK WINS)          ALTO IMPACTO + ALTO ESFUERZO (PROYECTOS MAYORES)
├── 1. Token palette update (1 archivo)            ├── 4. Migrar 4 P0 screens legacy → Token
├── 2. AppTheme ColorScheme update (1 archivo)     ├── 7. Aura Visual Language System (nuevo)
├── 6. Fonts en pubspec + AppTypography map        ├── 8. BottomNav/Unified AppBar System
├── 9. Shadows warm (2 líneas)                     ├── 13. Iconography System (nuevo)
├── 5. Consolidar Radius (2 archivos)              └── 14. Modelo Oficial Pipeline
├── 10. Eliminar belleza_luxe_theme.dart
└── 11. Deprecar GlowTokens colors (alias only)

BAJO IMPACTO + BAJO ESFUERZO (LIMPIEZA)            BAJO IMPACTO + ALTO ESFUERZO (EVITAR)
├── 3. Migrar LuxeComponents → Token               └── (Ninguno identificado — todo tiene impacto)
└── Eliminar LuxeSpacing, GlowTokens colors
```

---

## 16. ESTRATEGIA DE IMPLEMENTACIÓN (S0–S5)

| Área | Clasificación | Acción |
|------|---------------|--------|
| **Color Tokens Core** | **S1** | Actualizar `Token.light` a Target HEX v0.1 |
| **Dark Mode / Token.dark** | **S4** | Eliminar como brand; mantener solo compatibilidad técnica si requerida |
| **AppTheme (ColorScheme, Components)** | **S1** | Reconfigurar primary/secondary/tertiary, buttons, inputs |
| **Typography (Fonts + Mapping)** | **S1 + S3** | Agregar fuentes a pubspec; mapear `AppTypography` a familias reales |
| **Spacing System** | **S1** | Eliminar `LuxeSpacing`; usar `Spacing` exclusivamente |
| **Radius System** | **S1** | Eliminar `GlowStoreTokens.radius*`; usar `Radii` exclusivamente |
| **Shadows** | **S1** | Cambiar `shadow`/`shadowStrong` a warm (nude900 base) |
| **Buttons** | **S2** | Refactor `Elevated/Outlined/TextButtonTheme` + crear `AuraButtonTheme`; deprec `LuxeButton` |
| **Cards** | **S2** | Refactor `LuxeCard` → usar `Token` + `Radii.card` (16px); deprec duplicados |
| **Inputs** | **S1** | Ya usan `Radii.lg` (16px) en Theme; verificar colores border/focus |
| **Navigation (BottomNav, AppBar)** | **S3** | Crear componentes unificados `GlowBottomNav`, `GlowSliverAppBar`, `GlowAppBar` |
| **Iconography** | **S3** | Definir set SVG/Font + `GlowIcon` widget |
| **Logo/Brand** | **S0** | Mantener `GlowAppLogo` |
| **Photography/Model** | **S3** | Crear `ModelAsset` system + auditar/reemplazar assets no-oficiales |
| **Aura Visual Language** | **S3** | Crear `AuraTokens` + componentes `AuraHalo`, `AuraGlow`, `AuraCard` |
| **Decorative Language** | **S2** | Auditar `luxe_components` gradients, `belleza_luxe_gradients`; mantener solo Brand Core |
| **Responsive** | **S1** | Usar `Breakpoints` en layouts clave; verificar mobile/tablet/desktop |
| **Accessibility** | **S3** | Focus system, contrast fixes (RoseGold on Cream), touch targets, semantics |
| **Legacy Theme Migration** | **S2/S4** | Pantalla por pantalla: ProviderDetail (S2), Booking (S2), Login (S2), Register (S1), otras (S1) |
| **GlowStoreTokens Alignment** | **S1** | Alinear refs a nuevos `Token` nombres; deprec `LuxeColors` imports |
| **belleza_luxe_theme.dart** | **S4** | Eliminar archivo; migrar `home_screen`, `luxe_components` |
| **shared/theme.dart** | **S4** | Eliminar archivo tras migración completa |
| **_PassportColors** | **S2** | Migrar `results_screen` a `Token` + `GlowStoreTokens` |

---

## 17. ORDEN RECOMENDADO DE IMPLEMENTACIÓN

### FASE 1: FOUNDATION (Tokens + Theme + Fonts) — **Semana 1**
1. `pubspec.yaml` → Agregar fuentes: **Manrope** (Variable), **Cormorant Garamond**, **JetBrains Mono**, **Inter** (opcional, mantener compat)
2. `tokens.dart` → Actualizar `Token.light` palette a 8 Target HEX; renombrar semantic names; `shadow`/`shadowStrong` warm; agregar `roseGold`, `champagne`, `warmBrown`, `softBrown`, `auraTeal`; **eliminar `Token.dark` brand colors** (mantener solo technical)
3. `tokens.dart` → `AppTypography` mapear `fontFamily` reales: `display/heading` = `'CormorantGaramond'`, `body/button` = `'Manrope'`, `mono` = `'JetBrainsMono'`
4. `app_theme.dart` → `ColorScheme.primary=roseGold`, `secondary=champagne`, `tertiary=warmBrown`; actualizar `Elevated/Outlined/TextButtonTheme`, `InputDecorationTheme`, `CardTheme` (radius 16px), `AppBarTheme`, `BottomNavigationBarTheme`
5. `tokens.dart` → Eliminar `LuxeSpacing` refs (no usado en core); verificar `Spacing` coverage

### FASE 2: COMPONENT CONSOLIDATION — **Semana 1-2**
6. `luxe_components.dart` → Migrar `LuxeCard`/`LuxeButton`/`LuxeBadge` a `Token` + `Radii` + `Spacing`; agregar variante `Aura` en `LuxeButton`
7. `academy_luxe_components.dart` → Mover `LuxeProgressBar`/`LuxeListTile` a `luxe_components.dart`; migrar a tokens
8. `glow_store_tokens.dart` → Reemplazar `LuxeColors`/`GlowTokens` refs por `Token`/`GlowTokens(fonts)`; alinear `surfaceLevel*` nombres
9. `glow_tokens.dart` → Reducir a `fontFamilies` + alias a `Token` colors; eliminar colores duplicados
10. `belleza_luxe_theme.dart` → **Eliminar**; actualizar imports en `home_screen.dart`, `luxe_components.dart`
11. `glow_glass_card.dart` → `borderRadius` = `Radii.xl` (20px); colores → `Token`

### FASE 3: P0 SCREENS MIGRATION — **Semana 2-3**
12. `register_screen.dart` → Ya usa `Token` parcialmente; completar migración (inputs, buttons, scrim)
13. `login_screen.dart` → Migrar `InputDecoration` inline → `InputDecorationTheme`; scrim → `Token` colors; button → `ElevatedButton` theme
14. `provider_detail_screen.dart` → **Complejo**: SliverAppBar parallax mantener; reemplazar gradiente negro → warm gradient (`Token.nude900`/`Token.roseGold`); `specialtyColors` → token map; avatar radius → `Radii.circle`; chips → `Radii.md`; botones → theme
15. `booking_screen.dart` → **Complejo**: AppBar → theme; ProgressBar stepper → `Token.roseGold`; CalendarCard border → `Token.outlineVariant`; Inputs → theme; Buttons → theme; Sticky bottom → `Token` colors

### FASE 4: AURA + NAVIGATION + ICONOGRAPHY — **Semana 3-4**
16. Crear `aura_tokens.dart` + `aura_components.dart` (`AuraHalo`, `AuraGlow`, `AuraCard`)
17. Migrar `aura_welcome_screen.dart`, `results_screen.dart` → `AuraTokens` + `Token`
18. Crear `glow_bottom_nav.dart` + `glow_app_bar.dart` + `glow_sliver_app_bar.dart`
19. Migrar `main.dart` (ProvidersScreen), `home_screen.dart` → `GlowBottomNav`
20. Iconografía: Definir set SVG monoline → `glow_icons.dart` + `GlowIcon` widget; migrar usages progresivamente

### FASE 5: RESPONSIVE + ACCESSIBILITY + CLEANUP — **Semana 4**
21. Integrar `Breakpoints` en `StoreScreen`, `HomeScreen`, `ProviderDetailScreen` layouts
22. Focus system: `FocusTheme` global, focus rings `Token.roseGold`, semantic labels audit
23. Contraste: Verificar `roseGold` on `creamSilk` ≥ 4.5:1 (ajustar HEX si necesario)
24. Eliminar `shared/theme.dart` tras confirmar 0 imports
25. Eliminar `Token.dark` brand colors (mantener technical si needed)
26. Documentar `DESIGN_TOKENS.md` con valores finales

---

## 18. RIESGOS

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| **R-01:** Cambio de `Token.light` rompe pantallas no migradas | Alta | Alto | Migrar P0 screens en misma fase; feature flag `isModernTheme` ya existe en `AppTheme` |
| **R-02:** Contraste RoseGold `#C98261` on Cream `#F7EFE7` < 4.5:1 | Media | Crítico (a11y) | Testear con herramienta WCAG; si falla, ajustar HEX a `#B87354` (más oscuro) o `Cream` a `#F5EBE3` |
| **R-03:** Fuentes Manrope/Cormorant no renderizan en web (licencia/CORS) | Baja | Medio | Usar `google_fonts` package o self-host en `assets/fonts/`; testear `flutter build web` |
| **R-04:** `provider_detail_screen` SliverAppBar parallax se rompe con nuevo gradient | Media | Alto | Probar en device real; mantener `CollapseMode.parallax`; gradient solo cambia colores |
| **R-05:** `MensTheme` (audience Men) se desincroniza de nuevos tokens | Media | Medio | `MensTheme` es aislado; alinear solo `champagneGold` → nuevo `accentColor`; documentar |
| **R-06:** `GlowStoreTokens` `surfaceLevel0` para Men usa `obsidianBg` (negro) | Media | Brand (regla 4.2) | Evaluar: ¿Men audience requiere dark? Si sí, documentar excepción; si no, migrar a warm dark |
| **R-07:** Icon migration rompe semantic labels / accessibility | Baja | Medio | `GlowIcon` wrapper mantiene `semanticLabel` param; testear screen readers |
| **R-08:** `flutter build web --release` falla por font loading | Baja | Alto | Pre-build test en CI; `flutter test` + `flutter analyze` gates |

---

## 19. DEPENDENCIAS

| Dependencia | Tipo | Detalle |
|-------------|------|---------|
| **Fuentes (Manrope, Cormorant, JetBrainsMono, Inter)** | Externa | Licencias OFL/SIL; alojar en `assets/fonts/` o `google_fonts` |
| **Icon Set (Monoline Refined)** | Diseño | Requiere deliverable de diseño (SVG set 100+ icons) |
| **Modelo Oficial Photography Set** | Diseño/Producción | 8–12 fotos hero/login/register/aura/onboarding en 9:16 y 3:2 |
| **Aura Halo/Geometry Assets** | Diseño | SVG/PNG para halos, círculos concéntricos, puntos, destellos |
| **WCAG Contrast Validation** | Herramienta | `flutter_test` + `axe-core` o manual en Figma/DevTools |
| **Flutter 3.24+ / Material 3** | Framework | Ya en uso (`useMaterial3: true`) ✅ |

---

## 20. RECOMENDACIÓN FINAL

### Respuestas Obligatorias (Sección 31)

**A. ¿Cuánto de la identidad visual objetivo ya está implementado?**
~**40%** (Tokens core, ThemeData M3, GlowStoreTokens, GlowAppLogo, GlowGlassCard, Radii, Spacing, Shadows architecture)

**B. ¿Cuánto está implementado pero fragmentado?**
~**35%** (3 sistemas de color, 2 de spacing, 2 de radius, 4 de buttons, 3 de navigation, tipografía declarada pero no resuelta)

**C. ¿Cuánto falta?**
~**25%** (Target HEX exactos, Manrope/Cormorant fonts, Iconografía monoline, Aura visual language, Modelo oficial pipeline, Accessibility focus system, Responsive breakpoints usage)

**D. Top 10 Gaps Más Importantes:**
1. Paleta cromática: 8 Target HEX no existen en `Token.light`
2. Tipografía: Manrope + Cormorant no declaradas/mapeadas
3. Botones: Primary=RoseGold, Secondary=Cream+RoseGold, Aura=Teal no implementados
4. Navegación: 3 BottomNav + 3 AppBar patterns fragmentados
5. Sombras: `t.shadow` usa negro (no warm)
6. Legacy `shared/theme.dart` en 40+ pantallas
7. Iconografía: Solo Material Icons, sin sistema propio
8. Modelo oficial: No sistematizado, assets mezclados
9. Accesibilidad: Contraste Gold871/Cream falla WCAG AA
10. Aura: Lenguaje visual disperso, sin componentes reutilizables

**E. Top 10 Cambios de Mayor Impacto:**
1. Actualizar `Token.light` palette (1 archivo, global)
2. Actualizar `AppTheme` ColorScheme + Component Themes (1 archivo, global)
3. Agregar fuentes a `pubspec.yaml` + mapear en `AppTypography` (config + 1 archivo, global)
4. Migrar `provider_detail_screen` + `booking_screen` a `Token` (2 pantallas P0, alto impacto UX)
5. Consolidar `LuxeComponents` → `Token` (Home, Academy, Store partial)
6. Crear `GlowBottomNav` + `GlowAppBar` unificados (navegación global)
7. Ajustar shadows a warm (2 líneas, global)
8. Crear `AuraTokens` + componentes (Aura surfaces)
9. Eliminar `belleza_luxe_theme.dart` + `shared/theme.dart` (limpieza arquitectura)
10. Iconografía system (base para consistencia futura)

**F. ¿Qué partes NO deberían tocarse?**
- `Token` class structure (Light/Dark, semantic maps, gradients, extensions)
- `AppTheme.light()/dark()` ThemeData M3 structure
- `GlowStoreTokens` (audience-aware, checkout integrity)
- `GlowAppLogo` (asset management correcto)
- `GlowGlassCard` (glassmorphism parametrizado)
- `MensTheme` (audience Men aislado)
- `Radii`, `Spacing`, `AppShadow`, `AnimationTokens`, `Elevation`, `Breakpoints` classes
- `AuraWelcomeScreen` architecture (photography-first principle)
- `StoreScreen` checkout flow (monetary integrity)

**G. ¿La aplicación necesita: ajuste / refactor / design system / reconstrucción parcial / reconstrucción significativa?**
→ **CONSOLIDACIÓN + REFACTOR (Opción B)**
La arquitectura de design system (`Token` + `AppTheme`) es **madura y adecuada**. El trabajo es:
- **Ajuste de tokens** (colores, tipografía, sombras) — 3 archivos centrales
- **Refactor de componentes** (LuxeCard/Button, Navigation) — 5–8 archivos
- **Migración de pantallas legacy** — 4 P0 + ~10 P1/P2
- **Creación de sistemas faltantes** (Iconografía, Aura, Modelo, Responsive, A11y) — 4–5 nuevos módulos

**NO requiere reconstrucción de arquitectura ni lógica de negocio.**

**H. Orden óptimo de implementación:**
Ver **Sección 17** (4 fases, ~4 semanas). Fases 1–2 (Foundation + Components) desbloquean el 80% del impacto visual. Fases 3–4 completan pantallas críticas y sistemas faltantes.

---

## 21. CRITERIO DE DECISIÓN — VEREDICTO FINAL

> **OPCIÓN B — CONSOLIDACIÓN + REFACTOR**
>
> **Evidencia de respaldo:**
> - `Token` + `AppTheme` constituyen un design system **maduro (4-5/5)** con soporte Light/Dark, semantic colors, gradients, spacing, radii, shadows, typography tokens, breakpoints, animations, elevations.
> - `GlowStoreTokens` demuestra **implementación exitosa audience-aware** con integridad monetaria en checkout.
> - **31+ colores hardcoded** y **2 sistemas spacing/radius paralelos** confirman fragmentación, no ausencia de arquitectura.
> - **40+ pantallas** usan `shared/theme.dart` legacy — migración incremental factible sin romper negocio.
> - **0 cambios a backend/API/autenticación/pagos** requeridos (cumple reglas no-negociables).
> - **Top 3 palancas** (Token palette, AppTheme, Fonts) son **< 5 archivos** y afectan **100% de la app**.

**Próximo paso recomendado:** Ejecutar **Fase 1** (Foundation) en branch `feat/visual-gap-audit-f1`, validar con `flutter analyze` + `flutter test` + `flutter build web --release`, y presentar evidencia visual (screenshots mobile/tablet/desktop) antes de Fase 2.

---

## ANEXO: ENTREGABLE MACHINE-READABLE

Ver archivo complementario: `docs/audit/glowapp_visual_gap_audit.json`