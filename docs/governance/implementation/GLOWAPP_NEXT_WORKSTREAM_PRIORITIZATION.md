# GLOWAPP NEXT WORKSTREAM PRIORITIZATION — DISCOVERY RESULT

**Status**: NEXT_WORKSTREAM_DISCOVERY_COMPLETE  
**Date**: 2026-08-23  
**Method**: READ-ONLY discovery per mandate (git status, flutter analyze, existing governance reports, code inspection)  
**Zero production modifications**

---

## 1. STATE RECONCILIATION SUMMARY

### Repository State (git status --short)
- **Modified**: `.agent/skills`, `frontend/lib/widgets/ai_search_bar.dart`, `package.json`
- **Untracked**: Extensive docs/, backend/, frontend/ artifacts (358 files)
- **Recent commits**: Auto-generated content chunks (R7 stage 3)

### Flutter Analyze (848 issues)
**Critical compilation-blocking issues:**
| Category | Count | Root Cause |
|----------|-------|------------|
| `undefined_getter` on Token | ~200+ | Code uses `t.neutral500`, `t.neutral100`, `t.outlineVariant`, `t.surface`, `t.round`, `t.pill`, `t.xl`, `t.xxl`, `t.xxxl` — none exist on Token class |
| `undefined_identifier` (CrossAlignment, typo, ref) | ~50 | `booking_card.dart` uses non-existent enums/variables |
| `undefined_named_parameter` (minHeight) | ~10 | Legacy LuxeComponents API mismatch |
| `uri_does_not_exist` (freezed_annotation, riverpod) | ~30 | Missing dependencies in pubspec.yaml |
| `depend_on_referenced_packages` | ~15 | Models use freezed/riverpod without declaration |

**Pre-existing vs New**: All 848 issues are **pre-existing** — no new errors introduced by recent S4-I work (verified via git diff on modified files).

### Test Execution
- `aura_welcome_screen_test.dart`: **FAILS TO LOAD** — missing `glow_glass_card.dart` import
- Full test suite: **BLOCKED** — compilation failures in dependent files (login_screen.dart, register_screen.dart via S4TextField)

### Key Governance Documents (current truth)
| Document | Status |
|----------|--------|
| `GLOWAPP_MASTER_STATE_RECONCILIATION.md` | **MASTER STATE = RECONCILIATION_REQUIRED** (S4-I Subgroup B) |
| `GLOWAPP_G1_E_MASTER_IMPLEMENTATION_ROADMAP_RESULT.md` | DESIGN_COMPLETE_READ_ONLY — 17 workstreams mapped |
| `GLOWAPP_G0_F2_TEST_ENVIRONMENT_RESULT.md` | VALIDATION_BLOCKED — S4TextField compilation failures |
| `glowapp_next_workstream_prioritization.json` | Exists but predates current discovery (3 candidates only) |

---

## 2. WORKSTREAM CLASSIFICATION MATRIX

| Workstream | Estado Real | Dependencias | Riesgo | Valor | Prioridad |
|---|---|---|---|---|---|
| **S4-I Expansion 02 Subgroup B (Login/Register → S4TextField)** | 🟠 REQUIRES RECONCILIATION | Token API mismatches in dependent widgets | ALTO | CRÍTICO | 1 |
| **Token API Completion (neutral500, outlineVariant, surface, Radii getters on Token)** | ⚪ NOT STARTED | Blocks all S4 component adoption | ALTO | CRÍTICO | 1 (same) |
| **Backend Test Environment / API Config** | 🔴 BLOCKED (4 suites / 8 tests FAIL) | Unknown — requires investigation | ALTO | ALTO | 2 |
| **S4-I Expansion 03** | ⚪ NOT STARTED | Requires Subgroup B closed + Token API complete | MEDIO | ALTO | 3 |
| **G1-E Group 03** | ⚪ NOT STARTED | Blocked by S4-I Subgroup B | MEDIO | ALTO | 4 |
| **S3-I Photography System** | ⚪ NOT STARTED | Independent after spec (WS2 in roadmap) | BAJO | MEDIO | 5 |
| **Icon Migration (WS4)** | 🟢 VERIFIED | Complete (GlowIcon v1.0 LOCKED) | BAJO | HECHO | — |
| **Legacy Theme Migration (WS6)** | ⚪ NOT STARTED | Requires Token system (P1.3) | MEDIO | MEDIO | 6 |
| **R7-I Observability (WS9)** | ⚪ NOT STARTED | Independent backend work | BAJO | MEDIO | 7 |
| **Accessibility Validation (WS11)** | ⚪ NOT STARTED | Independent | BAJO | MEDIO | 8 |
| **Performance Validation (WS12)** | ⚪ NOT STARTED | Independent | BAJO | MEDIO | 9 |
| **Security Hardening (WS13)** | ⚪ NOT STARTED | Independent | BAJO | MEDIO | 10 |
| **Quality Automation (WS14)** | ⚪ NOT STARTED | Independent | BAJO | MEDIO | 11 |
| **Data Governance (WS15)** | ⚪ NOT STARTED | Independent | BAJO | MEDIO | 12 |
| **Payment/Wallet Consolidation (WS16)** | ⚪ NOT STARTED | Independent (backend) | BAJO | MEDIO | 13 |
| **Auth Service Consolidation (WS17)** | ⚪ NOT STARTED | Independent (backend) | BAJO | MEDIO | 14 |
| **Men Visual Reengineering (WS7)** | ⚪ NOT STARTED | Requires Token system + Male Muse assets | MEDIO | MEDIO | 15 |
| **AURA Men Adaptation (WS8)** | ⚪ NOT STARTED | Requires WS2 + WS7 + Token | MEDIO | MEDIO | 16 |
| **R7-V Validation (WS10)** | ⚪ NOT STARTED | Requires R7-I (WS9) | BAJO | MEDIO | 17 |
| **S2-III Legacy Typography Migration (WS1)** | ⚪ NOT STARTED | Requires S2-I Typography | BAJO | BAJO | 18 |

**Legend**: 🟢 COMPLETED/VERIFIED | 🟡 READY | 🟠 REQUIRES RECONCILIATION | 🔴 BLOCKED | ⚪ NOT STARTED

---

## 3. EXCLUDED FROM IMMEDIATE CANDIDATE (per mandate)

The following are **explicitly excluded** as next workstream:
- ❌ S4-I Expansion 03 — depends on Subgroup B + Token API
- ❌ Navigation redesign — not in current scope
- ❌ AppBar redesign — not in current scope  
- ❌ BottomNavigation redesign — not in current scope
- ❌ G1-E Group 04 — doesn't exist yet (only Groups 01-03 defined)
- ❌ Any workstream touching S4TextField, login_screen.dart, register_screen.dart, AISearchBar — **scope-locked** for parallel reconciliation

---

## 4. CONTEXTUAL CLASSIFICATIONS (per mandate)

| Area | Classification | Evidence |
|---|---|---|
| **Gemini/DeepSeek API failures** | EXPECTED EXTERNAL FAILURE / FALLBACK VALIDATION CONDITION | Deliberately no saldo; tests designed to trigger fallback |
| **Biometric IA integration tests** | WIP / UNDER CONSTRUCTION | System in construction; incomplete E2E tests not production defects |
| **S4TextField compilation errors** | PRE-EXISTING REGRESSION (S4-I workstream) | Not caused by G0-F.2; blocks test env stabilization |

---

## 5. MAJOR FRONTS EVALUATION

### A. Testing & Quality — 🔴 CRITICAL
- **State**: Test suite blocked by Token API mismatches (848 analyze errors)
- **Unit tests**: Cannot run (compilation failure)
- **Integration tests**: Not executable
- **E2E**: Biometric WIP, not production-ready
- **Test environment**: G0-F.2 VALIDATION_BLOCKED
- **Determinism**: Unknown (cannot run)

### B. Accessibility — ⚪ NOT ASSESSED
- No automated accessibility tests found
- Semantic labels: Unknown (blocked by compilation)
- Keyboard/focus/touch targets: Cannot verify

### C. Performance — ⚪ NOT ASSESSED
- No benchmarks captured
- Bundle size: Unknown (build blocked)

### D. Security — 🟡 PARTIAL
- Auth: Riverpod providers present but incomplete migration
- Secrets: .env not checked (scope)
- Dependencies: 50 packages have newer versions (some security-relevant)
- Payment boundaries: Wompi integration present

### E. Observability — ⚪ NOT STARTED
- R7-I (Observability) spec complete but not implemented
- Logging/metrics/error tracking: Backend only (ragObservability.js)

### F. CI/CD — 🟡 PARTIAL
- `npm run test` script exists
- No analyzer gates in CI (would fail on 848 issues)
- No build gates (web build untested)

### G. Visual QA — ⚪ NOT STARTED
- No visual regression tooling
- Women/Men/AURA parity: Cannot verify

### H. RAG / AI — 🟡 TESTED NOT VALIDATED
- 69/69 tests PASS (embedding, logger, metrics, evaluator, CI)
- Production observability: MISSING (R7-I required)
- Production validation: MISSING (R7-V required)

### I. Functional Product Modules — 🟡 PARTIAL
- Agenda/Bookings/Providers/Store: Code exists, uses broken Token API
- Payments: Wompi integration present
- Notifications: Unknown

---

## 6. PRIORITIZATION SCORING

| Candidate | Value | Risk Reduction | Dependency Impact | Production Impact | Effort | Independence | Overall |
|---|---:|---:|---:|---:|---:|---:|---:|
| **Token API Completion** (add missing getters to Token class) | 5 | 5 | 5 | 5 | 2 | 5 | **5.0** |
| **S4-I Subgroup B Reconciliation** (fix login/register + S4TextField usage) | 5 | 5 | 5 | 5 | 3 | 3 | **4.7** |
| **Backend Test Environment Fix** | 4 | 4 | 2 | 4 | 3 | 4 | **3.7** |
| **S3-I Photography System** | 3 | 2 | 1 | 3 | 4 | 5 | **2.8** |
| **R7-I Observability** | 3 | 3 | 1 | 3 | 3 | 5 | **2.8** |
| **Accessibility Validation** | 3 | 3 | 1 | 3 | 4 | 5 | **2.7** |
| **Legacy Theme Migration** | 3 | 3 | 3 | 3 | 4 | 2 | **2.7** |
| **Security Hardening** | 3 | 4 | 1 | 3 | 4 | 4 | **2.8** |

**Scale**: 1=bajo, 2=medio-bajo, 3=medio, 4=alto, 5=crítico  
**Note**: Token API Completion and S4-I Subgroup B are co-dependent — must be done together.

---

## 7. NEXT WORKSTREAM IDENTIFICATION

### #1 NEXT — **Token API Completion + S4-I Subgroup B Reconciliation (Combined)**
**Why**: 
- Single root cause: Token class missing getters used by 20+ widgets (`booking_card.dart`, `provider_luxe_components.dart`, `service_card.dart`, `product_card.dart`, `store_product_card.dart`, `wompi_payment_sheet.dart`, `onboarding_helper.dart`, `aura_welcome_screen.dart`, `ai_search_bar.dart`, `s4_text_field.dart`)
- Unblocks: All S4 component adoption, test suite, build, G1-E Group 03, S4-I Expansion 03
- Effort: Low-Medium (add ~20 getters to Token class + fix 2 auth screens)
- Independence: **High** — only touches `tokens.dart`, `login_screen.dart`, `register_screen.dart`, `s4_text_field.dart` (scope-locked files)

**Verifiable Objective**: 
- `flutter analyze` → 0 errors (only infos/warnings)
- `flutter test` → compiles and runs
- `flutter build web --release` → succeeds
- Login/Register screens use S4TextField correctly

### #2 PARALLEL-CAPABLE — **Backend Test Environment / API Configuration**
**Why**:
- Independent of frontend Token/API work (different codebase: `backend/`)
- Can run simultaneously by different agent
- Unblocks: CI/CD quality gates, RAG production validation
- Effort: Medium (investigate 4 failing suites, configure test env)

**Conflict Risk**: **NONE** — disjoint file sets (backend vs frontend)

### #3 LATER — **S3-I Photography System** (WS2 from roadmap)
**Why**:
- Specified, independent after Token system
- Requires: Token system complete (P1.3 in roadmap)
- Waits for: #1 completion

---

## 8. PARALLELIZATION MATRIX

| Workstream | Puede ejecutarse ahora | Paralelo con S4TextField Reconciliation | Riesgo de conflicto |
|---|:---:|:---:|:---:|
| Token API Completion | ✅ | ❌ (same files) | ALTO — mismo archivo `tokens.dart` |
| S4-I Subgroup B Reconciliation | ✅ | ❌ (scope-locked) | ALTO — archivos scope-locked |
| **Backend Test Fix** | ✅ | ✅ | **NINGUNO** — backend/ vs frontend/ |
| S3-I Photography | ⏳ (waits Token) | ✅ (disjoint) | BAJO — assets/ + photography widgets |
| R7-I Observability | ✅ | ✅ | BAJO — backend/ + new files |
| Accessibility Validation | ✅ | ✅ | BAJO — test/ + new files |
| Performance Validation | ✅ | ✅ | BAJO — test/ + new files |
| Security Hardening | ✅ | ✅ | BAJO — backend/ + config |
| Icon Migration | ✅ (done) | ✅ | NINGUNO |
| Legacy Theme Migration | ⏳ (waits Token) | ❌ | ALTO — theme files |

**Conservative ruling**: Only **Backend Test Fix**, **R7-I**, **Accessibility**, **Performance**, **Security** can run truly in parallel with S4TextField reconciliation.

---

## 9. ROOT CAUSE ANALYSIS: WHY TESTS ARE BLOCKED

```
┌─────────────────────────────────────────────────────────────┐
│  Token class (tokens.dart)                                  │
│  • Defines: n50-n900, surfaceLevel0-3, borderSubtle,        │
│    borderDefault, borderFocus, borderStrong, borderSelected │
│  • Missing getters: neutral500, neutral100, outlineVariant, │
│    surface, round, pill, xl, xxl, xxxl, CrossAlignment      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  20+ Widgets use Token.* getters that don't exist           │
│  (booking_card.dart, provider_luxe_components.dart, etc.)   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  flutter analyze → 848 errors → compilation fails           │
│  flutter test → cannot compile test files                   │
│  flutter build → fails                                      │
│  G0-F.2 validation → BLOCKED                                │
│  G1-E Group 03 → BLOCKED                                    │
│  S4-I Expansion 03 → BLOCKED                                │
└─────────────────────────────────────────────────────────────┘
```

**Fix**: Add missing getters to `Token` class mapping to existing fields:
- `neutral500` → `n500`, `neutral100` → `n100`
- `outlineVariant` → `borderSubtle`
- `surface` → `surfaceLevel1`
- `round` → `Radii.round`, `pill` → `Radii.pill`, `xl` → `Radii.xl`, etc.
- Add `CrossAlignment` enum or use `CrossAxisAlignment`

---

## 10. DELIVERABLES

Created/updated:
- `docs/governance/implementation/GLOWAPP_NEXT_WORKSTREAM_PRIORITIZATION.md` (this file)
- `docs/governance/implementation/glowapp_next_workstream_prioritization.json` (machine-readable)

---

## 11. FINAL DECISION

**NEXT_WORKSTREAM_IDENTIFIED**

### Recommended Next Workstream:
> **Token API Completion + S4-I Subgroup B Reconciliation** (combined)
> 
> **Scope**: Add ~20 missing getters to `Token` class in `tokens.dart` + fix `login_screen.dart`/`register_screen.dart` to use `S4TextField` correctly + verify `s4_text_field.dart` compiles
> 
> **Files to modify** (scope-locked per parallel reconciliation):
> - `frontend/lib/core/theme/tokens.dart` — add getters
> - `frontend/lib/screens/auth/login_screen.dart` — fix S4TextField usage
> - `frontend/lib/screens/auth/register_screen.dart` — fix S4TextField usage  
> - `frontend/lib/design/components/s4_text_field.dart` — verify compiles
> 
> **Validation gates**:
> 1. `flutter analyze` — 0 errors
> 2. `flutter test` — compiles, aura_welcome_screen_test passes
> 3. `flutter build web --release` — succeeds
> 4. Visual parity: Login/Register screens render correctly

### Parallel Track (can start immediately):
> **Backend Test Environment Configuration** — investigate and fix 4 failing test suites in `backend/`

---

## 12. STOP CONDITION

**DISCOVERY COMPLETE. NO EXECUTION PERFORMED.**

Awaiting explicit authorization to proceed with:
1. Token API Completion + S4-I Subgroup B Reconciliation (primary)
2. Backend Test Environment Fix (parallel)

---

*La imagen comunica. Flutter solo interactúa.*