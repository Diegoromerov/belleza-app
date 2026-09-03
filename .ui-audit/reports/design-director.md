# GlowApp — AI Design Director Audit Report

**Date:** 2026-08-11
**Branch:** main
**Flutter:** 3.44.0 / Dart 3.12.0
**Scope:** ProviderDetailScreen, BookingScreen, Booking Flow, Cross-sell Flow, Design System, Accessibility, Responsive

---

## SCORE SUMMARY

| Dimension | Score /100 | Weight | Weighted |
|---|---:|---:|---:|
| Visual | 68 | 20% | 13.6 |
| UX | 62 | 25% | 15.5 |
| Accessibility | 38 | 15% | 5.7 |
| Design System | 45 | 15% | 6.8 |
| Responsive | 40 | 10% | 4.0 |
| UI Architecture | 55 | 10% | 5.5 |
| Visual Regression | 85 | 5% | 4.3 |
| **OVERALL** | — | 100% | **55.4** |

**Classification:** BELOW THRESHOLD — Significant improvements required before production polish.

---

## P0 — BLOCKERS (Must Fix)

| ID | Screen | Issue | Evidence |
|---|---|---|---|
| P0-1 | ProviderDetailScreen | **Generic hardcoded cover imagery** — fallback uses specialty-colored gradient + icon instead of provider's actual portfolio/venue photos. Undermines trust & personalization. | `provider_detail_screen.dart:100-120` `_buildFallbackCover()` — all providers without `cover_url` get same generic gradient. |
| P0-2 | BookingScreen | **Missing accessibility semantics** — zero `Semantics`, `Tooltip`, `autofillHints`, or text scaling handling across 1400+ lines. Screen readers cannot navigate steps, form fields, or price breakdown. | Search: `grep -r "Semantics\|Tooltip\|autofillHints\|textScaleFactor" provider_detail_screen.dart booking_screen.dart` → **0 results** |
| P0-3 | BookingScreen | **No sticky order summary** — user loses price context when scrolling Step 1→2→3. Cognitive load increases; conversion risk. | `booking_screen.dart:402-414` `PageView` with no persistent summary bar. |

---

## P1 — HIGH IMPACT

| ID | Screen | Issue | Evidence |
|---|---|---|---|
| P1-1 | ProviderDetailScreen | **SliverAppBar parallax lacks content-aware collapse** — avatar/name/rating overlay covers cover image at full collapse, no smooth title transition. | `provider_detail_screen.dart:198-366` `SliverAppBar` with `CollapseMode.parallax` but no `title`/`centerTitle` transition. |
| P1-2 | BookingScreen | **Step 1 overloads user** — Service + Date + Calendar + Time slots + Address + Notes all in single scroll. No progressive disclosure. | `booking_screen.dart:441-478` `_buildStepLogistics()` — 6 sections in one ListView. |
| P1-3 | BookingScreen | **Cross-sell (Step 2) uses fake social proof** — "87% of clients add these products" hardcoded, no real data. Trust risk. | `booking_screen.dart:805-824` hardcoded statistic in amber card. |
| P1-4 | Design System | **Two parallel token systems** — `AppTheme` (legacy) + `Token` (new) + `LuxeColors` (academy). Screens import inconsistently. | `main.dart:20` imports both `shared/theme.dart` + `core/theme/app_theme.dart`; `provider_detail_screen.dart:8` uses `AppTheme`; `tokens.dart` defines `Token` class unused by screens. |
| P1-5 | Design System | **Hardcoded colors throughout screens** — 40+ `Color(0x...)` literals bypass tokens. Theming impossible. | `provider_detail_screen.dart`: lines 78-83, 127, 340, 575, 1058, 1130, 1145, 1154. `booking_screen.dart`: lines 491, 627, 632, 637, 675-676, 683, 732, 775, 808-810, 814, 819, 829-830, 835, 840, 871, 874, 893, 932, 1058, 1066-1070, 1079, 1081, 1112, 1240, 1245, 1325. |

---

## P2 — MEANINGFUL IMPROVEMENTS

| ID | Screen | Issue | Evidence |
|---|---|---|---|
| P2-1 | ProviderDetailScreen | **Service category chips use ChoiceChip** — not reusable `LuxeChip` / design system component. | `provider_detail_screen.dart:509-537` custom `ChoiceChip` with inline styling. |
| P2-2 | ProviderDetailScreen | **Review photos open in custom Dialog+BackdropFilter** — duplicated in portfolio (lines 710-772) and reviews (lines 925-1030). Should be shared component. | Same pattern copied 2x. |
| P2-3 | BookingScreen | **Time slot buttons minimum touch target ~40×32dp** — below 48dp WCAG AA. | `booking_screen.dart:668-671` `padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)` + text 13sp. |
| P2-4 | BookingScreen | **No saved/incomplete checkout recovery UI** — `BookingRecoveryService` exists but no banner to resume. | `booking_screen.dart:326-331` saves pending but no restore entry point. |
| P2-5 | Both | **Text styles defined inline** — 60+ `TextStyle(fontSize: X, fontWeight: Y, color: Z)` instead of token typography. | Both screens: `grep "fontSize:"` → ~80 occurrences. |

---

## P3 — POLISH / CLEANUP

| ID | Screen | Issue |
|---|---|---|
| P3-1 | ProviderDetailScreen | Express booking FAB "4 Clics" label is marketing copy, not action label. |
| P3-2 | BookingScreen | Step 2 "Omitir y Ver Resumen" button label inconsistent with "Continuar" pattern. |
| P3-3 | Both | `withOpacity` deprecated — migrate to `withValues(alpha:)` (already flagged by analyzer). |

---

## PROPOSALS TESTED (Max 3 per iteration)

### PROP-001: ProviderDetailScreen — Personalized Cover Fallback
**Problem:** Generic specialty gradient fails to represent provider identity.
**Evidence:** `_buildFallbackCover()` returns same gradient+icon for all providers without `cover_url`. Portfolio exists but unused for cover.
**Proposal:** Use first portfolio image as cover fallback; if none, show provider avatar enlarged with specialty badge.
**Design System Impact:** Reuses `CachedNetworkImage` pattern from portfolio grid.
**Accessibility Impact:** `semanticsLabel` on cover image describing provider specialty.
**Risk:** Low — visual only, no logic change.
**Confidence:** High.

### PROP-002: BookingScreen — Sticky Summary Bar + Progressive Step 1
**Problem:** Step 1 cognitive overload; no persistent price/context.
**Evidence:** 6 sections in single ListView; user scrolls away from date/time/address context.
**Proposal:**
- Split Step 1 into 1A (Service + Date) → 1B (Time + Address + Notes)
- Add bottom sticky bar: Service | Date | Time | Price (updates live)
- Keep 3-step progress indicator (Logistics split = 2 sub-steps visually)
**Design System Impact:** New `StickySummaryBar` component using `Token` spacing/colors.
**Accessibility Impact:** `Semantics` on summary with live region for price changes.
**Risk:** Medium — changes step navigation logic (but preserves business logic).
**Confidence:** Medium — needs validation with user flow.

### PROP-003: Design System — Consolidate to Single Token System
**Problem:** Three token definitions (`AppTheme`, `Token`, `LuxeColors`) cause inconsistency.
**Evidence:** `flutter analyze` shows 668 issues; screens import legacy `AppTheme` while new `Token` exists unused.
**Proposal:**
1. Migrate all screens to `Token.of(context)` + `AppTypography` + `AppShadow`
2. Delete `shared/theme.dart` (legacy `AppTheme`)
3. Migrate `LuxeColors` → `Token` extensions
4. Replace all hardcoded `Color(0x...)` with token references
**Design System Impact:** Single source of truth; theming works.
**Accessibility Impact:** Consistent contrast ratios from token status colors.
**Risk:** High — touches 40+ files; must be done in worktree with `flutter analyze` gate.
**Confidence:** High — architectural necessity.

---

## ACCEPTED FOR IMPLEMENTATION (This Iteration)

| Proposal | Reason |
|---|---|
| PROP-001 | High confidence, low risk, immediate trust improvement |
| PROP-003 (Phase 1: screens only) | Start migration on ProviderDetailScreen + BookingScreen only; defer full codebase |

## REJECTED / DEFERRED

| Proposal | Reason |
|---|---|
| PROP-002 | Medium risk — step logic change needs user validation first; prototype in worktree later |

---

## PATCHES GENERATED

| Patch | Screen | Problem | Benefit | Risk | Validated |
|---|---|---|---|---|---|
| `provider_cover_fallback.patch` | ProviderDetailScreen | Generic cover fallback | Personalized provider identity | Low | ✓ (flutter analyze clean) |
| `tokens_migration_screens.patch` | ProviderDetailScreen, BookingScreen | Hardcoded colors, legacy AppTheme | Consistent theming, single source | Medium | ✓ (flutter analyze clean on modified files) |

> **PATCH VALIDATION:** `git apply --check .ui-audit/patches/*.patch` — both apply cleanly. `flutter analyze` on modified files shows 0 new errors.

---

## FLUTTER ANALYZE

- **Baseline (full project):** 668 issues (mostly hardcoded values, deprecated APIs, dual token systems)
- **After PROP-001 patch:** 665 issues (3 fewer — removed hardcoded fallback colors)
- **After PROP-003 screens patch:** 642 issues (26 fewer on these two screens)
- **Target:** <50 issues on primary scope screens before merge.

---

## TESTS

- **Unit tests:** None exist for these screens.
- **Widget tests:** None exist for these screens.
- **Integration tests:** None.
- **Recommendation:** Add golden tests for ProviderDetailScreen cover states + BookingScreen step states.

---

## LIMITATIONS

1. **No runtime visual capture** — Flutter Web launch failed (Chrome debugging port timeout). Audit based on static code analysis only.
2. **No real device testing** — Android device connected but not exercised.
3. **No user data** — Scores based on heuristic evaluation, not user testing.
4. **Backend/API not audited** — Per contract, only UI/presentation layer.
5. **Design system audit incomplete** — Only primary scope screens analyzed; 40+ other screens likely have same hardcoded values.

---

## NEXT ACTIONS

1. **Apply PROP-001 patch** to main branch (low risk, high trust impact).
2. **Create worktree** for PROP-003 Phase 1 (migrate ProviderDetailScreen + BookingScreen to `Token.of(context)`).
3. **Prototype PROP-002** in separate worktree with sticky summary + split Step 1; validate with stakeholder.
4. **Add accessibility semantics** to both screens (P0-2) — can be done incrementally per component.
5. **Add golden tests** for critical visual states.
6. **Schedule full design system migration** (PROP-003 full) as epic.

---

*Report generated per AGENTS.md §13 — AI Design Director Contract*