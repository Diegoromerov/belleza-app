# GLOWAPP PHASE 2 — ADMIN SECURITY MATRIX

## 1. Security & RBAC Controls
- **Minimum Privilege:** `ADMIN` role authorization validated via JWT on every backend API request.
- **PII Protection:** Sensitive user/provider documents (KYC IDs, bank accounts) obscured in UI views and accessible only via time-bound signed URLs.
- **No UI Security:** Hiding UI buttons is purely a UX feature. Backend middleware remains sole security authority.
