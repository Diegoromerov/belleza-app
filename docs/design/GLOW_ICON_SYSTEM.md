# GLOW ICON SYSTEM — Specification & Implementation

**Version:** 1.0
**Phase:** I0/I1 FOUNDATION
**Status:** APPROVED
**Date:** 2026-08-19

---

## 1. Propósito

Construir la autoridad central de iconografía para GlowApp que permita una migración controlada y progresiva desde `Icons.*`, `CupertinoIcons`, SVG externos y otros sistemas hacia una familia propia coherente: **GlowIcon**.

**Principio:** CONSISTENCY > COVERAGE

---

## 2. Filosofía Visual

### Lenguaje
- **MONOLINE** — Trazo único, peso consistente
- **REFINED** — Geometría limpia, curvas orgánicas
- **WARM** — Terminales redondeados, proporciones humanas
- **MINIMAL** — Detalles mínimos de belleza, sin ruido
- **PREMIUM** — Calidad a 16–48px, stroke base 1.75px

### Geometría
- Viewport: 24 × 24
- Stroke base: 1.75px (variantes: 1.5 / 1.75 / 2.0)
- Stroke-linecap: round
- Stroke-linejoin: round
- Fill: none (outline style)

### Lo que EVITAMOS
- Estética industrial / mecánica
- Estética infantil / cartoon
- Iconos excesivamente técnicos
- Estética cyberpunk / neon / circuitos

---

## 3. Tamaños

| Token | Valor | Uso |
|-------|-------|-----|
| `xs` | 16px | Iconos pequeños / secundarios |
| `sm` | 20px | Compactos |
| `md` | 24px | **Estándar de interacción** |
| `lg` | 28px | Prominentes |
| `xl` | 32px | Hero / énfasis |
| `xxl` | 40px | Featured |
| `huge` | 48px | Display |

> **Nota:** El tamaño visual ≠ área táctil. Los controles interactivos respetan hit-targets de accesibilidad existentes en el proyecto.

---

## 4. Color Semántico

Los iconos **NO** contienen colores hardcoded. Reciben color vía theme/contexto.

### Roles Semánticos
| Role | Women | Men | AURA | Shared |
|------|-------|-----|------|--------|
| `primary` | Rose Gold `#D4AF7A` | Champagne `#C8B08A` | Aura Teal `#164C46` | — |
| `secondary` | Warm Brown `#5A3A2A` | Warm White `#F2EFEA` | Neutral | — |
| `accent` | Champagne `#D9A27F` | Copper `#B8734A` | Champagne | — |
| `aura` | — | — | **Aura Teal `#164C46`** | — |
| `error` | — | — | — | `#DC2626` |
| `success` | — | — | — | `#059669` |
| `warning` | — | — | — | `#D97706` |
| `neutral` | — | — | — | On-surface |
| `disabled` | — | — | — | Grey 400/600 |

### Integración Theme
```dart
// Extension en BuildContext
context.glowIconColor(GlowIconColorRole.primary)

// Uso directo
GlowIcon.search(colorRole: GlowIconColorRole.primary)
GlowIcon.aura(colorRole: GlowIconColorRole.aura) // Default Aura Teal
```

---

## 5. Women & Men — Geometría Compartida

**REGLA:** Un solo icono por acción semántica.

```dart
// ✅ CORRECTO - Geometría compartida, color por contexto
GlowIcon.search()
GlowIcon.profile()
GlowIcon.heart()

// ❌ INCORRECTO - Iconos separados por género
WomenSearchIcon()
MenSearchIcon()
```

La diferenciación Women/Men ocurre **exclusivamente mediante color semántico** resuelto por `GlowIconThemeExtension` según audiencia activa.

---

## 6. Iconos Core (I0) — 16 P0

| # | Semantic Name | Label (ES) | SVG Asset |
|---|---------------|------------|-----------|
| 1 | `home` | Inicio | `home.svg` |
| 2 | `search` | Buscar | `search.svg` |
| 3 | `menu` | Menú | `menu.svg` |
| 4 | `close` | Cerrar | `close.svg` |
| 5 | `back` | Atrás | `back.svg` |
| 6 | `forward` | Adelante | `forward.svg` |
| 7 | `more` | Más opciones | `more.svg` |
| 8 | `profile` | Perfil | `profile.svg` |
| 9 | `heart` | Favorito | `heart.svg` |
| 10 | `bag` | Bolsa | `bag.svg` |
| 11 | `cart` | Carrito | `cart.svg` |
| 12 | `calendar` | Calendario | `calendar.svg` |
| 13 | `clock` | Reloj | `clock.svg` |
| 14 | `location` | Ubicación | `location.svg` |
| 15 | `settings` | Ajustes | `settings.svg` |
| 16 | `notification` | Notificaciones | `notification.svg` |

---

## 7. Iconos Propietarios (I1) — 6

| # | Semantic Name | Concepto Visual | Label (ES) | SVG Asset |
|---|---------------|-----------------|------------|-----------|
| 1 | `glow` | Núcleo + radiación mínima (brillo/belleza/energía) | Glow | `glow.svg` |
| 2 | `aura` | Núcleo + halo/órbita (inteligencia/percepción) | Aura | `aura.svg` |
| 3 | `concierge` | Silueta humana + servicio (atención/acompañamiento) | Concierge | `concierge.svg` |
| 4 | `beauty_ritual` | Contenedor ritual + punto central (cuidado/experiencia unisex) | Ritual de belleza | `beauty_ritual.svg` |
| 5 | `glow_recommendation` | Compás + reloj + spark (recomendación/personalización) | Recomendación Glow | `glow_recommendation.svg` |
| 6 | `male_grooming` | Perfil masculino + navaja estilizada (grooming sofisticado) | Grooming masculino | `male_grooming.svg` |

---

## 8. Naming Convention

```
glow_icon.dart          → GlowIcon (API principal)
glow_icon_registry.dart → GlowIconRegistry (autoridad central)
glow_icon_registry_init.dart → GlowIconRegistryInit (inicialización)
glow_icon_adapter.dart  → GlowIconAdapter (capa migración)
glow_icon_demo.dart     → GlowIconDemoScreen (validación visual)
icons.dart              → Barrel export
```

Semantic names: `snake_case` (ej: `beauty_ritual`, `glow_recommendation`, `male_grooming`)

---

## 9. Registry

```dart
// Registro (en main.dart antes de runApp)
GlowIconRegistryInit.initialize();

// Resolución
GlowIconRegistry.register('search', GlowIconData(...));
final iconData = GlowIconRegistry.resolve('search');

// Listas conocidas
GlowIconRegistry.coreIcons      // 16 items
GlowIconRegistry.proprietaryIcons // 6 items
GlowIconRegistry.allKnownNames  // 22 items
```

**Prioridad implementación:** SVG asset > CustomPainter > IconData fallback

---

## 10. API Principal

```dart
// Core
GlowIcon.home(size: 24, colorRole: GlowIconColorRole.primary)
GlowIcon.search(size: 24, semanticLabel: 'Buscar')
GlowIcon.menu(size: 28, weight: GlowIconWeight.bold)

// Proprietary
GlowIcon.glow(size: 32)
GlowIcon.aura(size: 28, colorRole: GlowIconColorRole.aura)
GlowIcon.concierge(size: 24)
GlowIcon.beautyRitual(size: 24)
GlowIcon.glowRecommendation(size: 24)
GlowIcon.maleGrooming(size: 24)

// Resolución genérica
GlowIcon.resolve('search', size: 24, color: Colors.red)
```

---

## 11. Adapter (Migración)

```dart
// Drop-in replacement para Icons.*
GlowIconAdapter.search()      // → Icons.search_rounded
GlowIconAdapter.home()        // → Icons.home_rounded
GlowIconAdapter.person()      // → Icons.person_rounded
GlowIconAdapter.favorite()    // → Icons.favorite_rounded
// ... 16 core mappings

// Proprietary (nuevos)
GlowIconAdapter.glow()
GlowIconAdapter.aura()
GlowIconAdapter.concierge()
// ...

// Fallback programático
GlowIconAdapter.resolveOrFallback(Icons.some_icon)
```

**NO se ha realizado migración global.** El adapter permite migración por pantalla.

---

## 12. Theme Extension

```dart
extension GlowIconThemeExtension on BuildContext {
  Color glowIconColor(GlowIconColorRole role)
}
```

Resolución en cadena:
1. `GlowStoreTokens` (si disponible)
2. `Token` / `BellezaLuxeTokens` (fallback)
3. Hardcoded fallback (último recurso)

---

## 13. Accesibilidad

- Todos los métodos aceptan `semanticLabel` (requerido para iconos interactivos)
- Wrapper `Semantics` interno en `_SvgIcon` y `_CustomPaintIcon`
- Iconos decorativos: `semanticLabel: null` para silenciar
- Touch targets manejados externamente (componentes existentes)

---

## 14. Implementación Técnica

### Estructura Archivos
```
lib/design/
├── icons.dart                              # Barrel export
└── icons/
    ├── glow_icon.dart                      # API principal + theme extension
    ├── glow_icon_registry.dart             # Registry central
    ├── glow_icon_registry_init.dart        # Inicialización 22 iconos
    ├── glow_icon_adapter.dart              # Adapter migración
    └── glow_icon_demo.dart                 # Demo visual (no producción)

assets/icons/glow/                          # 22 SVGs
├── home.svg, search.svg, menu.svg...
├── glow.svg, aura.svg, concierge.svg...
```

### Dependencias
- `flutter_svg: ^2.0.9` (ya en pubspec.yaml)
- Assets declarados: `assets/icons/glow/` en pubspec.yaml

---

## 15. Iconos Futuros (I2)

**NO construidos en esta fase.** Dominios recomendados para I2:

| Dominio | Iconos Sugeridos | Prioridad |
|---------|------------------|-----------|
| Beauty (8) | skincare, hair, nails, makeup, fragrance, body, wellness, spa | Alta |
| Men (5) | beard, shave, scalp, fragrance_m, body_m | Alta |
| Concierge (4) | booking, chat, wishlist, support | Media |
| AURA (6) | scan, analyze, learn, predict, evolve, sync | Media |
| System (6) | share, download, upload, filter, sort, qr | Baja |

---

## 16. Estrategia de Migración

```
FASE ACTUAL: I0/I1 FOUNDATION ✅
    ↓
I2 EXTENDED ICON SET (bajo Director approval)
    ↓
PILOT MIGRATION: 1-2 pantallas (BottomNav, AppBar)
    ↓
INCREMENTAL MIGRATION: Por feature/dominio
    ↓
GLOBAL MIGRATION: COMPLETE
```

**Estado actual:** GLOBAL MIGRATION: NOT STARTED

---

## 17. Validación Realizada

### Flutter Analyze
- **Baseline (pre-existente):** 200+ errores freezed/generated code/riverpod/deprecated APIs
- **I0/I1 Introducidos:** 0 errores, ~15 warnings (const constructors, unused imports) — **NO bloqueantes**

### Build
- `flutter build web --release` ✅ SUCCESS
- Assets SVG incluidos correctamente

### SVG Validation (22/22)
- ✅ Todos existen en `assets/icons/glow/`
- ✅ Viewport 24×24 consistente
- ✅ Stroke 1.75px base (con variantes)
- ✅ stroke-linecap/linejoin: round
- ✅ fill: none
- ✅ Paths limpios, sin fills accidentales

### Visual Validation (GlowIconDemoScreen)
- ✅ 16 Core + 6 Proprietary renderizados
- ✅ Tamaños: 16, 20, 24, 28, 32, 40px
- ✅ Roles: 9 roles semánticos
- ✅ Contextos: Women / Men toggle
- ✅ Registry state: 22/22 registrados

### Context Validation

| Context | Primary | Secondary | Accent | Aura | Verdict |
|---------|---------|-----------|--------|------|---------|
| **Women** | Rose Gold ✅ | Warm Brown ✅ | Champagne ✅ | Aura Teal ✅ | **COHERENTE** |
| **Men** | Champagne ✅ | Warm White ✅ | Copper ✅ | Aura Teal ✅ | **COHERENTE** |
| **AURA** | — | — | — | Aura Teal ✅ | **COHERENTE** |

### Proprietary Icons Review

| Icon | Identidad Propia | 16px | 24px | 32px | Light/Dark | Parece Glow | No Material-like | Decisión |
|------|------------------|------|------|------|------------|-------------|------------------|----------|
| `glow` | ✅ Núcleo+radio | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **APROBADO** |
| `aura` | ✅ Núcleo+halo | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **APROBADO** |
| `concierge` | ✅ Silueta+servicio | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **APROBADO** |
| `beauty_ritual` | ✅ Contenedor+punto | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **APROBADO** |
| `glow_recommendation` | ✅ Compás+spark | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **APROBADO** |
| `male_grooming` | ✅ Perfil+navaja | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **APROBADO** |

---

## 18. Issues Introducidos por I0/I1

| Archivo | Issue | Severidad | Fix |
|---------|-------|-----------|-----|
| `glow_icon_demo.dart` | 8 `prefer_const_constructors` | Info | Cosmético |
| `glow_icon_demo.dart` | 1 `prefer_const_literals_to_create_immutables` | Info | Cosmético |
| `glow_icon_registry_init.dart` | 1 `unused_import` (material.dart) | Warning | **FIXED in I1.5** |
| `glow_icon_registry_init.dart` | 19 `prefer_const_constructors` | Info | **FIXED in I1.5** (const added) |

**Total:** 0 errores, ~30 warnings/info — **Ninguno bloqueante, ninguno arquitectónico**

---

## 19. Decisión Final

### ✅ I0/I1 APPROVED

**Fixes menores aplicados en I1.5:**
1. ✅ `const` constructors añadidos a 22 registros en `glow_icon_registry_init.dart`
2. ✅ Import unused `material.dart` removido de `glow_icon_registry_init.dart`

**No afectan:**
- Arquitectura
- API pública
- Consumers
- Runtime
- SVG loading
- Accesibilidad
- Registry

---

## 20. Próxima Fase Recomendada

### I2 — Extended Icon Set

**Dominios prioritarios:**
1. **Beauty (8)** — Skincare, Hair, Nails, Makeup, Fragrance, Body, Wellness, Spa
2. **Men (5)** — Beard, Shave, Scalp, Fragrance M, Body M
3. **Concierge (4)** — Booking, Chat, Wishlist, Support

**Criterios I2:**
- Misma geometría monoline 1.75px
- Mismo registry pattern
- Validación visual en demo antes de aprobar
- NO migración global hasta I2 validado

---

**Firma:** GlowIcon System Authority
**Cierre:** I0/I1 FOUNDATION — LOCKED

---

## 21. I2-A — Beauty Extended Set

**Estado:** APPROVED
**Fase:** I2_A_BEAUTY_VALIDATION
**Fecha:** 2026-08-19

### Iconos Beauty (8)

| # | Semantic Name | Concepto Visual | Label (ES) | SVG Asset |
|---|---------------|-----------------|------------|-----------|
| 1 | `skincare` | Rostro simplificado + gota de cuidado (piel/tratamiento/ritual) | Cuidado de la piel | `skincare.svg` |
| 2 | `hair` | Mechón fluido orgánico (cabello/styling/cuidado capilar) | Cabello | `hair.svg` |
| 3 | `nails` | Silueta uña minimalista en yema del dedo (manicure/cuidado) | Manicure | `nails.svg` |
| 4 | `makeup` | Trazo de brocha formando marca de belleza (maquillaje/aplicación) | Maquillaje | `makeup.svg` |
| 5 | `fragrance` | Frasco editorial simplificado + vapor sutil (perfume/aroma/lujo/ritual) | Fragancia | `fragrance.svg` |
| 6 | `body` | Silueta corporal abstracta + gesto de cuidado (body care/bienestar físico/ritual) | Cuidado corporal | `body.svg` |
| 7 | `wellness` | Formas equilibradas simétricas (equilibrio/bienestar/autocuidado/tranquilidad) | Bienestar | `wellness.svg` |
| 8 | `spa` | Piedra orgánica + vapor ritual (relajación/tratamiento/experiencia spa) | Spa | `spa.svg` |

### API Beauty

```dart
// Beauty Extended (I2-A)
GlowIcon.skincare(size: 24, colorRole: GlowIconColorRole.primary)
GlowIcon.hair(size: 24, semanticLabel: 'Cabello')
GlowIcon.nails(size: 24)
GlowIcon.makeup(size: 28)
GlowIcon.fragrance(size: 24)
GlowIcon.body(size: 24)
GlowIcon.wellness(size: 24)
GlowIcon.spa(size: 24)
```

### Registry Actualizado

```dart
GlowIconRegistry.coreIcons        // 16 items
GlowIconRegistry.proprietaryIcons // 6 items
GlowIconRegistry.beautyIcons      // 8 items (I2-A)
GlowIconRegistry.allKnownNames    // 30 items
```

### Validación I2-A

| Validación | Resultado |
|------------|-----------|
| 8 SVGs creados | ✅ |
| Viewport 24×24 | ✅ |
| Stroke 1.75px consistente | ✅ |
| Registry 30/30 | ✅ |
| API funcional | ✅ |
| Demo actualizada | ✅ |
| Women context | ✅ |
| Men context | ✅ |
| AURA role | ✅ |
| Build web release | ✅ |
| Tests pasan | ✅ |

### Diferenciación Semántica

| Icono | Diferenciador Clave |
|-------|---------------------|
| `beauty_ritual` | Concepto general de ritual GlowApp |
| `spa` | Experiencia/tratamiento spa específico |
| `wellness` | Estado/experiencia de bienestar holístico |
| `body` | Categoría de cuidado corporal |
| `skincare` | Cuidado específico de piel facial |
| `hair` | Cuidado específico de cabello |
| `nails` | Cuidado específico de uñas |
| `makeup` | Maquillaje/aplicación |
| `fragrance` | Perfume/fragancia |

No se permite intercambiabilidad sin contexto.

### Women / Men

Geometría compartida para los 8 iconos. Color resuelto por contexto:

| Role | Women | Men |
|------|-------|-----|
| `primary` | Rose Gold `#D4AF7A` | Champagne `#C8B08A` |
| `secondary` | Warm Brown `#5A3A2A` | Warm White `#F2EFEA` |
| `accent` | Champagne `#D9A27F` | Copper `#B8734A` |
| `aura` | Aura Teal `#164C46` | Aura Teal `#164C46` |

### AURA

Los 8 iconos Beauty aceptan `GlowIconColorRole.aura` sin romperse visualmente.
No se introdujeron efectos glow en los SVGs base.

### Migración

GLOBAL MIGRATION: NOT STARTED

---

## 22. Próximas Fases Recomendadas

### I2-B — Men (5 iconos)
- beard, shave, scalp, fragrance_m, body_m

### I2-C — Concierge (4 iconos)
- booking, chat, wishlist, support

### I2-D — AURA (6 iconos)
- scan, analyze, learn, predict, evolve, sync

### I2-E — System (6 iconos)
- share, download, upload, filter, sort, qr

**Criterios I2-C/D/E:** Misma geometría monoline 1.75px, mismo registry pattern, validación visual en demo antes de aprobar, NO migración global hasta I2 completo validado.

---

## 25. I2-C — Concierge Extended Set

**Estado:** APPROVED
**Fase:** I2_C_CONCIERGE_VALIDATION
**Fecha:** 2026-08-19

### Identidad Visual: PREMIUM PERSONAL SERVICE

Principios: atención personalizada, acompañamiento, confianza, servicio, relación humana, asistencia, descubrimiento, facilidad, experiencia premium.

No es: software empresarial, help desk genérico, chatbot genérico, marketplace, aplicación bancaria, sistema administrativo.

### Iconos Concierge (4)

| # | Semantic Name | Concepto Visual | Label (ES) | SVG Asset |
|---|---------------|-----------------|------------|-----------|
| 1 | `booking` | Calendario minimal + check sutil (reservar/acción/experiencia de reserva) | Reserva | `booking.svg` |
| 2 | `chat` | Dos burbujas conversacionales (diálogo/comunicación/interacción humana) | Chat | `chat.svg` |
| 3 | `wishlist` | Marcador de colección + heart minimal (lista de deseos/colección personal) | Lista de deseos | `wishlist.svg` |
| 4 | `support` | Escudo suave + gesto de acompañamiento (asistencia/apoyo/humano/premium) | Soporte | `support.svg` |

### API Concierge

```dart
// Concierge Extended (I2-C)
GlowIcon.booking(size: 24, colorRole: GlowIconColorRole.primary)
GlowIcon.chat(size: 24, semanticLabel: 'Chat')
GlowIcon.wishlist(size: 24)
GlowIcon.support(size: 24)
```

### Registry Actualizado

```dart
GlowIconRegistry.coreIcons        // 16 items
GlowIconRegistry.proprietaryIcons // 6 items
GlowIconRegistry.beautyIcons      // 8 items (I2-A)
GlowIconRegistry.menIcons         // 5 items (I2-B)
GlowIconRegistry.conciergeIcons   // 4 items (I2-C)
GlowIconRegistry.allKnownNames    // 39 items
```

### Relación con concierge existente

| Icono | Rol |
|-------|-----|
| `concierge` | Concepto general / identidad servicio personalizado (propietario) |
| `booking` | Función: reserva |
| `chat` | Función: conversación |
| `wishlist` | Función: colección personal |
| `support` | Función: asistencia |

`concierge` = identidad de marca; los 4 nuevos = funciones operacionales.

### Diferenciación Semántica Crítica

| Par | Diferenciador |
|-----|---------------|
| `booking` ↔ `calendar` | calendar = estructura temporal; booking = acción/experiencia de reservar |
| `wishlist` ↔ `heart` | heart = favorito/acción de marcar; wishlist = colección personal/lista |
| `chat` ↔ `support` | chat = hablar/conversar; support = recibir ayuda/asistencia |
| `support` ↔ `concierge` | concierge = servicio personalizado/identidad; support = ayuda/asistencia |

No duplicación semántica. Cada icono tiene propósito inequívoco.

### Validación I2-C

| Validación | Resultado |
|------------|-----------|
| 4 SVGs creados | ✅ |
| Viewport 24×24 | ✅ |
| Stroke 1.75px consistente | ✅ |
| Registry 39/39 | ✅ |
| API funcional | ✅ |
| Demo actualizada | ✅ |
| Women context no roto | ✅ |
| Men context funciona | ✅ |
| AURA role funciona | ✅ |
| Build web release | ✅ |
| Tests pasan | ✅ |

### Visual Validation

Comparaciones obligatorias realizadas:

- `booking` ↔ `calendar` → Distintos: estructura vs acción
- `wishlist` ↔ `heart` → Distintos: colección vs favorito
- `chat` ↔ `support` → Distintos: conversación vs ayuda
- `support` ↔ `concierge` → Distintos: asistencia vs identidad de marca

Todos pertenecen a la misma familia visual GlowApp.

### Women / Men

Geometría compartida. Color resuelto por contexto:

| Role | Women | Men |
|------|-------|-----|
| `primary` | Rose Gold `#D4AF7A` | Champagne `#C8B08A` |
| `secondary` | Warm Brown `#5A3A2A` | Warm White `#F2EFEA` |
| `accent` | Champagne `#D9A27F` | Copper `#B8734A` |
| `aura` | Aura Teal `#164C46` | Aura Teal `#164C46` |

### AURA Compatibility

Los 4 iconos Concierge aceptan `GlowIconColorRole.aura` sin romperse visualmente.

### Migración

GLOBAL MIGRATION: NOT STARTED

---

## 26. Próximas Fases Recomendadas

### I2-D — AURA (6 iconos)
- scan, analyze, learn, predict, evolve, sync

### I2-E — System (6 iconos)
- share, download, upload, filter, sort, qr

**Criterios I2-D/E:** Misma geometría monoline 1.75px, mismo registry pattern, validación visual en demo antes de aprobar, NO migración global hasta I2 completo validado.

---

## 26. I2-D — AURA Extended Set

**Estado:** APPROVED
**Fase:** I2_D_AURA_VALIDATION
**Fecha:** 2026-08-19

### Identidad Visual: QUIET INTELLIGENCE

Principios: percepción, comprensión, aprendizaje, anticipación, evolución, sincronización, personalización, inteligencia discreta.

No es: technical, cyberpunk, robotic, neon, sci-fi cliché, herramienta de programación.

### Jerarquía AURA

| Icono | Rol |
|-------|-----|
| `aura` | Identidad de la inteligencia GlowApp (propietario) |
| `scan` | Capacidad: percibir/leer información |
| `analyze` | Capacidad: interpretar/comprender |
| `learn` | Capacidad: incorporar conocimiento |
| `predict` | Capacidad: anticipar |
| `evolve` | Capacidad: transformarse con el usuario |
| `sync` | Capacidad: alinear/sincronizar |

### Iconos AURA (6)

| # | Semantic Name | Concepto Visual | Label (ES) | SVG Asset |
|---|---------------|-----------------|------------|-----------|
| 1 | `scan` | Campo de percepción + núcleo observando (AURA percibe/lee información) | Escanear | `scan.svg` |
| 2 | `analyze` | Núcleo con relaciones en capas (AURA interpreta/comprende) | Analizar | `analyze.svg` |
| 3 | `learn` | Núcleo + órbitas expandiéndose (AURA incorpora conocimiento) | Aprender | `learn.svg` |
| 4 | `predict` | Trayectoria convergiendo a punto futuro (AURA anticipa) | Predecir | `predict.svg` |
| 5 | `evolve` | Forma transformándose progresivamente (AURA evoluciona con el usuario) | Evolucionar | `evolve.svg` |
| 6 | `sync` | Dos órbitas alineándose (AURA sincroniza/coordinación) | Sincronizar | `sync.svg` |

### API AURA

```dart
// AURA Extended (I2-D)
GlowIcon.scan(size: 24, colorRole: GlowIconColorRole.aura)
GlowIcon.analyze(size: 24, semanticLabel: 'Analizar')
GlowIcon.learn(size: 24)
GlowIcon.predict(size: 24)
GlowIcon.evolve(size: 24)
GlowIcon.sync(size: 24)
```

### Registry Actualizado

```dart
GlowIconRegistry.coreIcons        // 16 items
GlowIconRegistry.proprietaryIcons // 6 items
GlowIconRegistry.beautyIcons      // 8 items (I2-A)
GlowIconRegistry.menIcons         // 5 items (I2-B)
GlowIconRegistry.conciergeIcons   // 4 items (I2-C)
GlowIconRegistry.auraIcons        // 6 items (I2-D)
GlowIconRegistry.allKnownNames    // 45 items
```

### Diferenciación Semántica Crítica

| Par | Diferenciador |
|-----|---------------|
| `scan` ↔ `search` | search = usuario busca; scan = AURA percibe/lee |
| `analyze` | Núcleo + relaciones = comprensión (no lupa/microscopio) |
| `learn` | Órbitas expandiéndose = adquisición (no libro/educación) |
| `predict` | Trayectoria convergente = anticipación (no bola de cristal) |
| `evolve` ↔ `sync` | evolve = transformación; sync = alineación/coordinación |
| `aura` vs capacidades | aura = identidad; 6 iconos = funciones |

No duplicación semántica. Cada capacidad tiene propósito inequívoco.

### Validación I2-D

| Validación | Resultado |
|------------|-----------|
| 6 SVGs creados | ✅ |
| Viewport 24×24 | ✅ |
| Stroke 1.75px consistente | ✅ |
| Registry 45/45 | ✅ |
| API funcional | ✅ |
| Demo actualizada | ✅ |
| Women context no roto | ✅ |
| Men context funciona | ✅ |
| AURA role (Aura Teal) funciona | ✅ |
| Build web release | ✅ |
| Tests pasan | ✅ |

### AURA Coherence

Los 6 iconos comparten gramática visual:
- Núcleo central recurrente
- Órbitas/relaciones espaciales
- Trayectorias/movimiento sutil
- Transformación orgánica
- Sin estética cyberpunk/neon/robot
- Familia coherente de "Quiet Intelligence"

### Visual Validation

Comparaciones obligatorias realizadas:

- `scan` ↔ `search` → Distintos: usuario vs inteligencia
- `analyze` vs `settings`/`glow` → Distintos: comprensión vs configuración
- `learn` ↔ `beauty_ritual`/`aura` → Distintos: adquisición vs ritual/identidad
- `predict` ↔ `calendar` → Distintos: anticipación vs estructura temporal
- `evolve` ↔ `sync` → Distintos: transformación vs alineación
- `aura` vs 6 capacidades → Distintos: identidad vs funciones

Todos pertenecen a la misma familia visual GlowApp. Lenguaje: QUIET INTELLIGENCE.

### Women / Men

Geometría compartida. Color resuelto por contexto:

| Role | Women | Men |
|------|-------|-----|
| `primary` | Rose Gold `#D4AF7A` | Champagne `#C8B08A` |
| `secondary` | Warm Brown `#5A3A2A` | Warm White `#F2EFEA` |
| `accent` | Champagne `#D9A27F` | Copper `#B8734A` |
| `aura` | Aura Teal `#164C46` | Aura Teal `#164C46` |

### AURA Compatibility

Los 6 iconos AURA tienen `color_role_default: "aura"` (Aura Teal #164C46) pero aceptan todos los roles semánticos sin romperse visualmente.

### Migración

GLOBAL MIGRATION: NOT STARTED

---

## 27. Próximas Fases Recomendadas

### I2-E — System (6 iconos)
- share, download, upload, filter, sort, qr

**Criterios I2-E:** Misma geometría monoline 1.75px, mismo registry pattern, validación visual en demo antes de aprobar, NO migración global hasta I2 completo validado.

---

## 27. I2-E — System Extended Set

**Estado:** APPROVED
**Fase:** I2_E_SYSTEM_VALIDATION
**Fecha:** 2026-08-19

### Identidad Visual: GLOWAPP SYSTEM

Principios: claridad, consistencia, discreción, funcionalidad.

No es: library genérica, estética tecnológica pesada, iconos industriales.

### Iconos System (6)

| # | Semantic Name | Concepto Visual | Label (ES) | SVG Asset |
|---|---------------|-----------------|------------|-----------|
| 1 | `share` | Tres nodos conectados (compartir/distribuir/neutral) | Compartir | `share.svg` |
| 2 | `download` | Flecha en contenedor - contenido entrando al dispositivo | Descargar | `download.svg` |
| 3 | `upload` | Flecha desde contenedor - contenido saliendo del dispositivo | Subir | `upload.svg` |
| 4 | `filter` | Líneas progresivas convergiendo - seleccionar qué mostrar | Filtrar | `filter.svg` |
| 5 | `sort` | Líneas de diferentes longitudes con orden - organizar secuencia | Ordenar | `sort.svg` |
| 6 | `qr` | Símbolo QR minimal - tecnología/medio de acceso (no scanner) | Código QR | `qr.svg` |

### API System

```dart
// System Extended (I2-E)
GlowIcon.share(size: 24, colorRole: GlowIconColorRole.primary)
GlowIcon.download(size: 24, semanticLabel: 'Descargar')
GlowIcon.upload(size: 24)
GlowIcon.filter(size: 24)
GlowIcon.sort(size: 24)
GlowIcon.qr(size: 24)
```

### Registry Actualizado

```dart
GlowIconRegistry.coreIcons        // 16 items
GlowIconRegistry.proprietaryIcons // 6 items
GlowIconRegistry.beautyIcons      // 8 items (I2-A)
GlowIconRegistry.menIcons         // 5 items (I2-B)
GlowIconRegistry.conciergeIcons   // 4 items (I2-C)
GlowIconRegistry.auraIcons        // 6 items (I2-D)
GlowIconRegistry.systemIcons      // 6 items (I2-E)
GlowIconRegistry.allKnownNames    // 51 items
```

### Diferenciación Semántica Crítica

| Par | Diferenciador |
|-----|---------------|
| `download` ↔ `upload` | download = contenido entra; upload = contenido sale |
| `filter` ↔ `sort` | filter = qué elementos; sort = en qué orden |
| `qr` ↔ `scan` | qr = tecnología/medio de acceso; scan = capacidad AURA |

No duplicación semántica. Cada icono tiene propósito inequívoco.

### Validación I2-E

| Validación | Resultado |
|------------|-----------|
| 6 SVGs creados | ✅ |
| Viewport 24×24 | ✅ |
| Stroke 1.75px consistente | ✅ |
| Registry 51/51 | ✅ |
| API funcional | ✅ |
| Demo actualizada | ✅ |
| Women context no roto | ✅ |
| Men context funciona | ✅ |
| AURA role funciona | ✅ |
| Build web release | ✅ |
| Tests pasan | ✅ |

### System Coherence

Los 6 iconos son discretos frente a iconos propietarios (glow, aura, concierge, male_grooming). No compiten visualmente. Lenguaje: funcional, minimal, consistente.

### Visual Validation

Comparaciones obligatorias realizadas:

- `download` ↔ `upload` → Distintos: dirección, peso óptico, legible a 16px
- `filter` ↔ `sort` → Distintos: convergencia vs secuencia ordenada
- `qr` ↔ `scan` → Distintos: símbolo acceso vs capacidad inteligencia

Todos pertenecen a la misma familia visual GlowApp. Discreción intencional.

### Women / Men

Geometría compartida. Color resuelto por contexto:

| Role | Women | Men |
|------|-------|-----|
| `primary` | Rose Gold `#D4AF7A` | Champagne `#C8B08A` |
| `secondary` | Warm Brown `#5A3A2A` | Warm White `#F2EFEA` |
| `accent` | Champagne `#D9A27F` | Copper `#B8734A` |
| `aura` | Aura Teal `#164C46` | Aura Teal `#164C46` |

### AURA Compatibility

Los 6 iconos System aceptan `GlowIconColorRole.aura` sin romperse visualmente. No adquieren características visuales de AURA (no órbitas, no núcleos, no halos).

### Migración

GLOBAL MIGRATION: NOT STARTED

---

## 28. Final Inventory Check

Confirmado:

| Categoría | Count |
|-----------|-------|
| CORE | 16 |
| PROPRIETARY | 6 |
| BEAUTY | 8 |
| MEN | 5 |
| CONCIERGE | 4 |
| AURA | 6 |
| SYSTEM | 6 |
| **TOTAL** | **51** |

No aceptar otro número.

---

## 29. Próxima Fase Recomendada

### FINAL ICON SYSTEM VALIDATION

Comparación holística de los 51 iconos como UNA SOLA FAMILIA.

**NO ejecutarla automáticamente.** Requiere Director approval.

---

# GLOW ICON SYSTEM v1.0 — FINAL LOCK

**Version:** 1.0.0
**Status:** LOCKED
**Phase:** FINAL_LOCK
**Date:** 2026-08-20

---

## 30. Inventario Oficial — 51 Iconos

| Categoría | Count | Iconos |
|-----------|-------|--------|
| CORE | 16 | home, search, menu, close, back, forward, more, profile, heart, bag, cart, calendar, clock, location, settings, notification |
| PROPRIETARY | 6 | glow, aura, concierge, beauty_ritual, glow_recommendation, male_grooming |
| BEAUTY | 8 | skincare, hair, nails, makeup, fragrance, body, wellness, spa |
| MEN | 5 | beard, shave, scalp, mens_fragrance, mens_body |
| CONCIERGE | 4 | booking, chat, wishlist, support |
| AURA | 6 | scan, analyze, learn, predict, evolve, sync |
| SYSTEM | 6 | share, download, upload, filter, sort, qr |
| **TOTAL** | **51** | |

---

## 31. Arquitectura Congelada

```
GlowIcon
    ↓
GlowIconRegistry
    ↓
GlowIconData
    ↓
SVG / implementación
    ↓
Theme / semantic color
```

**Mantenidos:**
- Registry pattern
- Semantic naming
- SVG-first architecture
- Theme-aware colors
- Accessibility
- Adapter layer

No sustituir sin versión mayor.

---

## 32. SVG Specification Lock

| Parámetro | Valor |
|-----------|-------|
| Viewport | 24 × 24 |
| Stroke base | 1.75 px |
| Variantes | 1.5 px, 2.0 px |
| Linecap | round |
| Linejoin | round |
| Fill | none |

**Prohibido en futuras modificaciones:** gradients, shadows, glow effects, neon, raster, efectos dentro del SVG.

---

## 33. Visual Language Lock

**Lenguaje oficial:**
- MONOLINE
- REFINED
- WARM
- MINIMAL
- PREMIUM

**Características:** geometría limpia, curvas orgánicas, negative space, peso óptico controlado, reconocimiento rápido, sofisticación discreta.

---

## 34. Women Lock

| Role | Color |
|------|-------|
| Primary | Rose Gold #D4AF7A |
| Secondary | Warm Brown #5A3A2A |
| Accent | Champagne #D9A27F |
| Aura | Aura Teal #164C46 |

Sin nuevas variantes sin modificación formal.

---

## 35. Men Lock

| Role | Color |
|------|-------|
| Primary | Champagne #C8B08A |
| Secondary | Warm White #F2EFEA |
| Accent | Copper #B8734A |
| Aura | Aura Teal #164C46 |

**Dirección:** QUIET MASCULINE LUXURY

**Prohibido:** cyberpunk, neon, barbershop cliché, agresividad, estética deportiva, negro/dorado cliché.

---

## 36. AURA Lock

**Color:** Aura Teal #164C46
**Identidad:** QUIET INTELLIGENCE

**Prohibido como lenguaje AURA:** robots, chips, cerebros, circuitos, cyberpunk, neon, HUD, AI cliché.

**Jerarquía:**
- `aura` = IDENTIDAD
- `scan`, `analyze`, `learn`, `predict`, `evolve`, `sync` = CAPACIDADES

---

## 37. Proprietary Lock

Iconos propietarios: glow, aura, concierge, beauty_ritual, glow_recommendation, male_grooming

No reutilizarlos indiscriminadamente como iconos funcionales. Su función: reforzar identidad y conceptos propios de GlowApp.

---

## 38. Semantic Lock

Diferencias congeladas:

| Icono | Significado |
|-------|-------------|
| search | usuario busca |
| scan | AURA percibe |
| calendar | fecha/estructura temporal |
| booking | reserva de servicio |
| heart | favorito |
| wishlist | colección personal |
| hair | cabello |
| scalp | cuero cabelludo |
| fragrance | fragancia general |
| mens_fragrance | fragancia Glow Men |
| body | cuidado corporal general |
| mens_body | cuidado corporal Glow Men |
| concierge | servicio personalizado |
| support | asistencia |
| chat | conversación |
| evolve | transformación |
| sync | alineación |
| filter | selección |
| sort | orden |
| qr | medio de acceso |

---

## 39. API Lock

API pública: `GlowIcon.*` congelada en v1.0.

No crear aliases innecesarios.
No cambiar semantic names.
No APIs paralelas: `MenIcon`, `AuraIcon`, `BeautyIcon`, `SystemIcon`.

---

## 40. Accessibility Lock

Congelado: `semanticLabel`, `Semantics`, `decorative null`

Touch targets a nivel del componente consumidor.

---

## 41. Demo Lock

`GlowIconDemoScreen` = VALIDATION TOOL (no productiva).
Mantener disponible para regresiones. Debe representar 51/51.

---

## 42. Adapter Lock

`GlowIconAdapter` disponible para migración gradual. Propósito: compatibilidad temporal.

Nueva UI → `GlowIcon.*` (preferido)
Migración existente → puede usar Adapter.

---

## 43. Migration Status

**GLOBAL MIGRATION: NOT STARTED**

No modificar pantallas productivas. No reemplazar `Icons.*` todavía.

---

## 44. Change Control

| Tipo | Definición |
|------|------------|
| PATCH | Correcciones documentales que no alteran diseño |
| MINOR | Adiciones compatibles que no rompen el sistema |
| MAJOR | Cambios en geometría, naming, semántica, stroke, arquitectura, color, estructura — **requiere revisión formal** |

---

## 45. Icon Addition Policy

Después de v1.0, NO agregar iconos por necesidad de pantalla.

Prerequisites:
1. Necesidad semántica real
2. Inexistencia de equivalente
3. Necesidad reutilizable
4. Coherencia con el sistema
5. Impacto sobre inventario
6. Impacto sobre API
7. Impacto sobre documentación

Proceso: DESIGN PROPOSAL → SEMANTIC REVIEW → VISUAL REVIEW → IMPLEMENTATION → VALIDATION → VERSION UPDATE

---

## 46. Icon Usage Policy

Nuevas pantallas: **PREFERIDO** `GlowIcon.*`
**NO PREFERIDO** `Icons.*`

EXCEPCIÓN: Material icon solo cuando no exista equivalente, sea temporal, esté documentado y exista intención de reemplazo.

---

## 47. Lock Artifacts

- `docs/design/GLOW_ICON_SYSTEM.md` (actualizado)
- `docs/design/glow_icon_system.json` (v1.0.0, LOCKED, FINAL_LOCK)
- `docs/audit/GLOWAPP_ICON_SYSTEM_V1_LOCK.md` (este reporte)
- `docs/audit/glowapp_icon_system_v1_lock.json` (JSON de lock)

---

## 48. Asset Inventory / Checksums

| Filename | Semantic | Category | Size (bytes) |
|----------|----------|----------|--------------|
| home.svg | home | core | 274 |
| search.svg | search | core | 312 |
| menu.svg | menu | core | 298 |
| close.svg | close | core | 267 |
| back.svg | back | core | 267 |
| forward.svg | forward | core | 298 |
| more.svg | more | core | 267 |
| profile.svg | profile | core | 345 |
| heart.svg | heart | core | 298 |
| bag.svg | bag | core | 312 |
| cart.svg | cart | core | 345 |
| calendar.svg | calendar | core | 378 |
| clock.svg | clock | core | 345 |
| location.svg | location | core | 334 |
| settings.svg | settings | core | 345 |
| notification.svg | notification | core | 378 |
| glow.svg | glow | proprietary | 397 |
| aura.svg | aura | proprietary | 345 |
| concierge.svg | concierge | proprietary | 427 |
| beauty_ritual.svg | beauty_ritual | proprietary | 339 |
| glow_recommendation.svg | glow_recommendation | proprietary | 489 |
| male_grooming.svg | male_grooming | proprietary | 567 |
| skincare.svg | skincare | beauty | 713 |
| hair.svg | hair | beauty | 589 |
| nails.svg | nails | beauty | 489 |
| makeup.svg | makeup | beauty | 567 |
| fragrance.svg | fragrance | beauty | 582 |
| body.svg | body | beauty | 623 |
| wellness.svg | wellness | beauty | 534 |
| spa.svg | spa | beauty | 545 |
| beard.svg | beard | men | 775 |
| shave.svg | shave | men | 623 |
| scalp.svg | scalp | men | 689 |
| mens_fragrance.svg | mens_fragrance | men | 773 |
| mens_body.svg | mens_body | men | 645 |
| booking.svg | booking | concierge | 456 |
| chat.svg | chat | concierge | 389 |
| wishlist.svg | wishlist | concierge | 467 |
| support.svg | support | concierge | 478 |
| scan.svg | scan | aura | 403 |
| analyze.svg | analyze | aura | 467 |
| learn.svg | learn | aura | 434 |
| predict.svg | predict | aura | 445 |
| evolve.svg | evolve | aura | 456 |
| sync.svg | sync | aura | 378 |
| share.svg | share | system | 380 |
| download.svg | download | system | 356 |
| upload.svg | upload | system | 356 |
| filter.svg | filter | system | 334 |
| sort.svg | sort | system | 367 |
| qr.svg | qr | system | 412 |

**TOTAL:** 51 files, ~20KB combined

---

## 49. Validación Técnica Final

| Comando | Resultado |
|---------|-----------|
| `flutter test` | ✅ 7/7 PASSED |
| `flutter analyze lib/design/icons/` | ✅ 0 errors (8 info cosmetic) |
| `flutter build web --release` | ✅ SUCCESS |
| `python -m json.tool docs/design/glow_icon_system.json` | ✅ JSON VALID |

**Baseline (pre-existing):** 200+ errors freezed/generated/riverpod/deprecated — **NO atribuidos al Icon System**

**Icon System:** 0 errores, 8 info (prefer_const_constructors en demo)

---

## 50. Git Status

Icon System files: **untracked (nuevos)**
- `frontend/lib/design/icons/`
- `frontend/assets/icons/glow/`
- `docs/design/GLOW_ICON_SYSTEM.md`
- `docs/design/glow_icon_system.json`
- `docs/audit/GLOWAPP_ICON_SYSTEM_FINAL_VALIDATION.md`
- `docs/audit/glowapp_icon_system_final_validation.json`
- `docs/audit/GLOWAPP_ICON_SYSTEM_V1_LOCK.md`
- `docs/audit/glowapp_icon_system_v1_lock.json`

Pre-existing modifications: Múltiples archivos backend/frontend **unrelated** al Icon System.

---

## 51. Production Safety

| Componente | Estado |
|------------|--------|
| Pantallas productivas | ✅ Intactas |
| Navegación | ✅ Intacta |
| Providers | ✅ Intactos |
| Servicios | ✅ Intactos |
| Backend | ✅ Intacto |
| Database | ✅ Intacta |
| Booking | ✅ Intacto |
| Store | ✅ Intacto |
| AURA productivo | ✅ Intacto |

**GLOBAL MIGRATION: NOT STARTED** ✅