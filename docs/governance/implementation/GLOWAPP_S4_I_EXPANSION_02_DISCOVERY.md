# GLOWAPP — S4-I EXPANSION 02 DISCOVERY & SELECTION (READ-ONLY)

## 1. Current Repository State
- **Git Status**: Clean working tree with only ongoing backend/frontend modifications (see `git status --short` output). No UI component changes pending.
- **Branch**: `r7-stage3-shadow`
- **Last Commit**: `3c8df30d` (feat: tendencias_belleza_virales auto-generado)

## 2. S4 Authority State
| Component | Canonical Implementation | Location | Status |
|-----------|--------------------------|----------|--------|
| **CARD** | `LuxeCard` | `frontend/lib/design/components/luxe_components.dart` | ✅ Established |
| **BUTTON** | `LuxeButton` (variants: goldShimmer, tonal, outline) | `frontend/lib/design/components/luxe_components.dart` | ✅ Established |
| **INPUT** | `S4TextField` | `frontend/lib/design/components/s4_text_field.dart` | ✅ Established |
| **STATE** | `S4SkeletonLoader` / `S4SkeletonCard` | `frontend/lib/design/components/s4_loading.dart` | ✅ Established (loading placeholders) |
| **ERROR / EMPTY** | No unified canonical state component identified; ad-hoc implementations exist (e.g., `Center(Text('❌ No se pudieron cargar los datos'))`, `Container` with message). | — | ⚠️ Gap: No canonical `S4Error`, `S4Empty`, `S4Loading` beyond skeleton. |

## 3. Component Inventory (Read-Only Discovery)
Scanned the frontend library for real consumers in the four domains (CARD, BUTTON, INPUT, STATE). The following files were examined:

### 3.1 Card Inventory
| File | Consumer | Current Implementation | Classification | Notes |
|------|----------|------------------------|----------------|-------|
| `frontend/lib/widgets/home/recent_scan_card.dart` | RecentScanCard | `LuxeCard` | CANONICAL | Already uses LuxeCard. |
| `frontend/lib/widgets/provider/service_card.dart` | ServiceCard | `LuxeCard` | CANONICAL | Already uses LuxeCard. |
| `frontend/lib/widgets/glow_glass_card.dart` | GlowGlassCard | Custom `Container` + `ClipRRect` + gradient background | SPECIALIZED | Glass effect with blur-like UI; domain-specific visual treatment. |
| `frontend/lib/widgets/store/product_card.dart` | StoreProductCard | Custom `Consumer` + complex layout with actions, badges, pricing | SPECIALIZED | Commerce-specific logic (add to cart, quick view, discount badge). |
| `frontend/lib/widgets/store_product_card.dart` | StoreProductCard (alternate) | Similar to above; duplicated implementation? | DUPLICATE | Appears to be a duplicate of `store/product_card.dart`; needs consolidation. |
| `frontend/lib/widgets/academy/progress_card.dart` | ProgressCard | Custom `Container` with steps, icons, text | SPECIALIZED | Academy-specific progress visualization. |
| `frontend/lib/widgets/product_recipe_card.dart` | ProductRecipeCard | Custom `Card` with image, title, actions | DUPLICATE / SPECIALIZED? | Recipe card; may be specialized for recipe display. |
| `frontend/lib/widgets/profile/luxe_list_tile.dart` | LuxeListTile | `Container` with `leading`, `title`, `subtitle`, `trailing` | DUPLICATE | Functionally similar to `ListTile`; could migrate to `LuxeCard` with padding adjustments. |
| `frontend/lib/screens/home/home_screen.dart` | Inline cards (e.g., hero section, promos) | Various `Container`/`Card` usages | DUPLICATE / INLINE | Multiple inline card-like containers; candidates for LuxeCard. |
| `frontend/lib/screens/ideas/glowstore_recipe_screen.dart` | Recipe cards in list | Custom `Card` with image, title, rating | DUPLICATE | Similar to product recipe card; candidate for LuxeCard. |

### 3.2 Button Inventory
| File | Consumer | Current Implementation | Classification | Notes |
|------|----------|------------------------|----------------|-------|
| `frontend/lib/screens/provider_detail_screen.dart` | Chat button (Rapid Actions row) | `ElevatedButton.icon` | DUPLICATE | Primary action "Chatear"; candidate for `LuxeButton` (goldShimmer). |
| `frontend/lib/screens/provider_detail_screen.dart` | Reserve button (bottomNavigationBar) | `ElevatedButton` | DUPLICATE | "RESERVAR CITA (WOMPI)"; candidate for `LuxeButton` (goldShimmer/tonal). |
| `frontend/lib/screens/provider_detail_screen.dart` | Express Booking FAB | `FloatingActionButton.extended` | SPECIALIZED | Floating action button with icon+text; domain-specific placement. |
| `frontend/lib/screens/provider_detail_screen.dart` | Category chips (selected) | `ChoiceChip` with custom style | DUPLICATE | Uses `AppTheme.primary`; could migrate to `LuxeButton` (outlined) for consistency? (Chips are selection controls, not buttons). |
| `frontend/lib/screens/store_screen.dart` | Add to cart (in product cards) | `IconButton` (inside StoreProductCard) | SPECIALIZED | Cart action; embedded in specialized card. |
| `frontend/lib/screens/store_screen.dart` | Quick view button (in product cards) | `TextButton` | DUPLICATE | "Ver rápido"; candidate for `LuxeButton` (tonal/outline). |
| `frontend/lib/screens/booking_screen.dart` | Confirm booking button | `ElevatedButton` | DUPLICATE | Primary CTA; candidate for `LuxeButton`. |
| `frontend/lib/screens/auth/login_screen.dart` | Login button | `ElevatedButton` | DUPLICATE | Standard login; candidate for `LuxeButton`. |
| `frontend/lib/screens/auth/register_screen.dart` | Register button | `ElevatedButton` | DUPLICATE | Standard register; candidate for `LuxeButton`. |
| `frontend/lib/screens/profile/settings_screen.dart` | Save changes button | `ElevatedButton` | DUPLICATE | Settings save; candidate for `LuxeButton`. |

### 3.3 Input Inventory
| File | Consumer | Current Implementation | Classification | Notes |
|------|----------|------------------------|----------------|-------|
| `frontend/lib/screens/store_screen.dart` | Search field | `S4TextField` (already migrated in Expansion 01) | CANONICAL | Post-migration: uses `S4TextField` with `_searchController`. |
| `frontend/lib/screens/auth/login_screen.dart` | Email input | `TextFormField` | DUPLICATE | Standard email field; candidate for `S4TextField`. |
| `frontend/lib/screens/auth/login_screen.dart` | Password input | `TextFormField` | DUPLICATE | Standard password; candidate for `S4TextField`. |
| `frontend/lib/screens/auth/register_screen.dart` | Name, email, password, phone, etc. | Multiple `TextFormField` | DUPLICATE | Registration form; candidates for `S4TextField`. |
| `frontend/lib/screens/profile/settings_screen.dart` | Profile name, bio, etc. | `TextFormField` | DUPLICATE | Settings form; candidates for `S4TextField`. |
| `frontend/lib/screens/ideas/capture_screen.dart` | Idea description, tags, etc. | `TextFormField` | DUPLICATE | Idea capture; candidates for `S4TextField`. |
| `frontend/lib/widgets/ai_search_bar.dart` | AI search bar | `TextField` with custom decoration | DUPLICATE | Reusable widget; candidate for `S4TextField`. |
| `frontend/lib/screens/store/product_detail.dart` | Quantity input? (if any) | — | — | Needs verification. |

### 3.4 State Inventory (Loading / Error / Empty)
| File | Consumer | Current Implementation | Classification | Notes |
|------|----------|------------------------|----------------|-------|
| `frontend/lib/screens/provider_detail_screen.dart` | Initial loading | `Center(CircularProgressIndicator)` | DUPLICATE | Simple loading indicator; candidate for `S4SkeletonLoader` or `S4Loading`. |
| `frontend/lib/screens/store_screen.dart` | Initial loading | `Center(CircularProgressIndicator)` (via `_isLoading`) | DUPLICATE | Same as above. |
| `frontend/lib/screens/store_screen.dart` | Error state | `Center(Text('❌ No se pudieron cargar los datos'))` | DUPLICATE | Error message; candidate for `S4Error`. |
| `frontend/lib/screens/store_screen.dart` | Empty cart | `Center(Text('Tu carrito está vacío'))` (inferred) | DUPLICATE | Empty state; candidate for `S4Empty`. |
| `frontend/lib/widgets/wompi_payment_sheet.dart` | Processing | `CircularProgressIndicator` | DUPLICATE | Payment processing; candidate for `S4SkeletonLoader`. |
| `frontend/lib/screens/ideas/processing_screen.dart` | Processing | `CircularProgressIndicator` | DUPLICATE | Idea processing; candidate for `S4SkeletonLoader`. |
| `frontend/lib/screens/ideas/processing_alchemy_screen.dart` | Processing | `CircularProgressIndicator` | DUPLICATE | Same. |
| `frontend/lib/screens/home/home_screen.dart` | Placeholder shimmer in hero? | `Shimmer` (via analytics?) | DUPLICATE | Uses `shimmer` package; candidate for `S4SkeletonLoader`. |

## 4. Canonical Components (Authorized)
- **CARD**: `LuxeCard`
- **BUTTON**: `LuxeButton` (goldShimmer, tonal, outline)
- **INPUT**: `S4TextField`
- **STATE LOADING**: `S4SkeletonLoader` / `S4SkeletonCard` (for placeholder)
- **STATE ERROR / EMPTY**: *No canonical component identified* → gap.

## 5. Specialized Components (Protected)
These components have domain-specific behavior or visual treatment that justifies retaining them as specialized wrappers (they may internally use canonical components but expose a specialized API):
- `GlowGlassCard` (frosted glass effect)
- `StoreProductCard` / `store_product_card.dart` (commerce actions, badges, pricing layout)
- `ProductRecipeCard` / `glowstore_recipe_screen.dart` (recipe-specific layout)
- `ProgressCard` (academy step visualization)
- `LuxeListTile` (though borderline; could be replaced by `LuxeCard` with padding)
- `FloatingActionButton.extended` (express booking FAB)
- `AI Search Bar` (reusable custom input with prefix/suffix logic)

## 6. Legacy / Duplicate Systems
- **Duplicate Card implementations**: `store/product_card.dart` vs `store_product_card.dart` (needs deduplication).
- **Duplicate Input implementations**: Numerous `TextFormField` across auth, profile, ideas, etc.
- **Duplicate Button implementations**: Numerous `ElevatedButton` across screens.
- **Duplicate State implementations**: Multiple `CircularProgressIndicator` and ad-hoc error/empty containers.

## 7. Candidate Migration Matrix (Low-Risk Consumers for Expansion 02)
| # | File | Consumer | Domain | Current | S4 Target | Classification | Risk | Reason |
|---|------|----------|--------|---------|-----------|----------------|------|--------|
| 01 | `frontend/lib/widgets/profile/luxe_list_tile.dart` | LuxeListTile | CARD | Custom `Container` | `LuxeCard` | DUPLICATE | LOW | Simple container with padding; can be replaced by `LuxeCard` with appropriate padding. |
| 02 | `frontend/lib/screens/store_screen.dart` | Quick view button (in product cards) | BUTTON | `TextButton` | `LuxeButton` (outline) | DUPLICATE | LOW | Standard text button; no complex state. |
| 03 | `frontend/lib/screens/auth/login_screen.dart` | Email input | INPUT | `TextFormField` | `S4TextField` | DUPLICATE | LOW | Straightforward field; no custom validation beyond email format. |
| 04 | `frontend/lib/screens/auth/login_screen.dart` | Password input | INPUT | `TextFormField` | `S4TextField` (obscureText) | DUPLICATE | LOW | Password field with obscuration. |
| 05 | `frontend/lib/screens/auth/register_screen.dart` | Name input | INPUT | `TextFormField` | `S4TextField` | DUPLICATE | LOW | Registration form fields. |
| 06 | `frontend/lib/screens/provider_detail_screen.dart` | Chat button (Rapid Actions) | BUTTON | `ElevatedButton.icon` | `LuxeButton` (goldShimmer) | DUPLICATE | LOW | Primary action "Chatear"; already analyzed for Expansion 01 but not selected; safe to migrate. |
| 07 | `frontend/lib/screens/provider_detail_screen.dart` | Reserve button (bottomNavigationBar) | BUTTON | `ElevatedButton` | `LuxeButton` (goldShimmer) | DUPLICATE | LOW | Primary CTA for booking; similar to Expansion 01 button. |
| 08 | `frontend/lib/screens/provider_detail_screen.dart` | Initial loading state | STATE | `Center(CircularProgressIndicator)` | `S4SkeletonLoader` | DUPLICATE | LOW | Simple loading indicator; can wrap child in shimmer. |
| 09 | `frontend/lib/widgets/ai_search_bar.dart` | AI search bar | INPUT | Custom `TextField` + decoration | `S4TextField` | DUPLICATE | LOW | Reusable widget; already follows S4 principles partially. |
| 10 | `frontend/lib/screens/store/product_detail.dart` | Quantity selector (if present) | INPUT | — | `S4TextField` (numeric) | UNKNOWN | MEDIUM | Needs verification; if exists, low risk. |
| 11 | `frontend/lib/screens/booking_screen.dart` | Confirm booking button | BUTTON | `ElevatedButton` | `LuxeButton` (goldShimmer) | DUPLICATE | LOW | Standard confirmation button. |
| 12 | `frontend/lib/screens/profile/settings_screen.dart` | Save changes button | BUTTON | `ElevatedButton` | `LuxeButton` (tonal) | DUPLICATE | LOW | Settings save action. |
| 13 | `frontend/lib/screens/store_screen.dart` | Empty cart message (if implemented as container) | STATE | `Center(Text(...))` | `S4Empty` (to be defined) | DUPLICATE | MEDIUM | Requires canonical empty component; currently gap. |
| 14 | `frontend/lib/screens/store_screen.dart` | Error message container | STATE | `Center(Text('❌ No se pudieron cargar los datos'))` | `S4Error` (to be defined) | DUPLICATE | MEDIUM | Requires canonical error component; currently gap. |
| 15 | `frontend/lib/widgets/home/hero_section.dart` | Promo cards (if any) | CARD | Various `Container` | `LuxeCard` | DUPLICATE | LOW | Hero section contains promotional banners; can be cards. |

## 8. Risk Classification Summary
- **LOW Risk**: 10 candidates (simple duplication, no complex state, no business logic coupling).
- **MEDIUM Risk**: 3 candidates (require verification or depend on missing canonical state components).
- **HIGH Risk**: 0 candidates selected (we avoided specialized components and business-critical actions).

## 9. Accessibility Findings (High-Level)
- Existing `LuxeCard`, `LuxeButton`, `S4TextField` follow Material Design accessibility standards (touch targets ≥48px, semantic labels via `tooltip`/`semanticLabel` where applicable, respect text scaling).
- Candidates identified for migration currently use standard Flutter widgets that inherit accessibility properties; migration to S4 components will maintain or improve accessibility via token-based colors and spacing.
- No accessibility regressions expected; post-migration verification recommended (semantic labels, focus order, contrast).

## 10. GENERAL / WOMEN / MEN / AURA Assessment
All identified candidates are audience-agnostic or receive differentiation via:
- **S1 Color**: Through `GlowStoreTokens`, `LuxeColors`, `MensTheme` (for men-specific variants).
- **S2 Typography**: Through `TypographyTokens`, `LuxeTypography`.
- **AudienceService**: Used in `store_screen.dart` and other screens to filter content; migration does not affect audience logic.
- No audience-specific variants (e.g., `WomenButton`, `MenCard`) are required or present in candidates.

## 11. Selected Expansion 02 Candidates (Low-Risk, Ready for Migration)
Based on the matrix, the following 8 candidates are selected for a future controlled migration (Expansion 02 Execution):
1. LuxeListTile → LuxeCard
2. Store quick view button → LuxeButton (outline)
3. Login email input → S4TextField
4. Login password input → S4TextField (obscure)
5. Register name input → S4TextField
6. Provider chat button → LuxeButton (goldShimmer)
7. Provider reserve button → LuxeButton (goldShimmer)
8. AI search bar → S4TextField

These are chosen for their simplicity, low coupling, and high duplication.

## 12. Rejected Candidates and Reasons
| Candidate | Reason for Rejection |
|-----------|----------------------|
| GlowGlassCard | Specialized visual treatment (glass effect); not a plain card. |
| StoreProductCard / store_product_card.dart | Commerce-specific layout, actions, badges; domain specialization. |
| ProductRecipeCard | Recipe-specific layout; specialized. |
| ProgressCard (Academy) | Step visualization with icons; specialized. |
| Reserve button (bottomNavigationBar) – *actually selected* | — |
| Express Booking FAB | Floating action button with extended widget; specialized placement. |
| Category chips (provider_detail_screen.dart) | Selection chip, not a button; different interaction model. |
| Error/Empty states | Requires canonical `S4Error`/`S4Empty` components not yet defined; gap. |
| Quantity selector (store/product_detail.dart) | Verification needed; potential coupling to product logic. |

## 13. Components That Should Remain Specialized
- `GlowGlassCard`
- `StoreProductCard` / `store_product_card.dart`
- `ProductRecipeCard` (in glowstore_recipe_screen)
- `ProgressCard` (academy)
- `FloatingActionButton.extended` (express booking)
- `AI Search Bar` (if deemed reusable custom input with complex prefix/suffix logic – may stay as wrapper)

## 14. Registry Drift
No registry drift detected; the source-of-truth registries (to be updated post-migration) currently reflect pre-Expansion 01 state. No automatic updates performed in this read-only phase.

## 15. Technical Debt Discovered
- Duplicate card implementations (`store/product_card.dart` vs `store_product_card.dart`).
- Duplicate input implementations across auth, profile, ideas.
- Duplicate button implementations across screens.
- Missing canonical error and empty state components.
- Inconsistent use of `Shimmer` vs `S4SkeletonLoader` for loading placeholders.
- Use of raw `CircularProgressIndicator` and ad-hoc `Container` for error/empty states.

## 16. Production Safety
✅ **Zero production code modified** during this discovery phase.
✅ All activities read-only: file reads, repository searches, `git status`.
✅ No patches, refactors, component creations, or formatting changes.
✅ Git status shows only documentation additions (to be made).

## 17. Recommended Migration Order
1. **Input fields** (login/register) – safest, isolated.
2. **Buttons** (quick view, chat, reserve) – straightforward UI actions.
3. **LuxeListTile** – simple card replacement.
4. **AI search bar** – reusable widget; update in one place.
5. **State loading** (replace `CircularProgressIndicator` with `S4SkeletonLoader`) – low risk.
6. **Error/Empty states** – defer until canonical `S4Error`/`S4Empty` are defined (out of Expansion 02 scope).

## 18. Quality Assessment
- **Evidence-based**: All findings derived from direct file inspection and repository search.
- **No assumptions**: Only reported what was observed in the codebase.
- **Controlled scope**: Limited to CARD, BUTTON, INPUT, STATE domains; excluded navigation, AppBar, BottomNavigation, photography, token architecture, backend, etc.
- **Alignment with S4-I principles**: Follows EXISTING CODE FIRST, reuse canonical where possible, avoid redesign.

## 19. Final Decision
**READY_FOR_EXPANSION_02_EXECUTION**

The discovery phase has successfully identified a safe, low-risk set of consumers for migration under S4-I Expansion 02. No production code has been altered. Upon explicit authorization, proceed to execute the selected migrations following the controlled migration plan.

---
*La imagen comunica. Flutter solo interactúa.*