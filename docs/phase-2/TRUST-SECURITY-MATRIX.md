# GLOWAPP PHASE 2 — TRUST SECURITY MATRIX

## 1. Security Controls & Privilege Enforcement
- **No Role Spoofing:** JWT token claim validation on every route.
- **Immutable Authorization:** Backend controllers re-verify user role and resource ownership independently of UI state.
- **Signed Storage URLs:** Time-bound (15-minute expiration) signed URLs used for all KYC document viewing.
