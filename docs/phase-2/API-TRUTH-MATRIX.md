# GLOWAPP PHASE 2 — API TRUTH MATRIX

## 1. API Verification Baseline
- **Base URL:** `http://localhost:5000/api/v1` (Express Core Monolith) / `http://localhost:8000` (FastAPI Aura AI Worker).
- **Security Protocols:** JWT Bearer tokens, HTTP-Only Cookies, Rate Limiting, Role Middleware (RBAC), Idempotency Headers.

---

## 2. API Endpoint Truth Inventory

| Method | Path | Auth Required | RBAC Role | Middleware | Validation | Implemented File | Empirical Status |
|---|---|---|---|---|---|---|---|
| POST | `/api/v1/auth/login` | NO | NONE | RateLimit | Joi Schema | `backend/src/routes/authRoutes.js` | ACTIVE |
| POST | `/api/v1/auth/register` | NO | NONE | RateLimit | Joi Schema | `backend/src/routes/authRoutes.js` | ACTIVE |
| POST | `/api/v1/auth/refresh` | YES | ALL | AuthGuard | Refresh Token | `backend/src/routes/authRoutes.js` | ACTIVE |
| GET | `/api/v1/services` | NO | NONE | CacheHeaders | Query Filter | `backend/src/routes/serviceRoutes.js` | ACTIVE |
| POST | `/api/v1/bookings` | YES | CLIENT | AuthGuard, Idempotency | Booking Validation | `backend/src/routes/bookingRoutes.js` | ACTIVE |
| GET | `/api/v1/bookings/:id` | YES | CLIENT, PROVIDER | AuthGuard, Ownership | UUID Param | `backend/src/routes/bookingRoutes.js` | ACTIVE |
| POST | `/api/v1/payments/intent` | YES | CLIENT | AuthGuard, Idempotency | Payment Body | `backend/src/routes/paymentRoutes.js` | ACTIVE |
| POST | `/api/v1/payments/webhook` | NO (Sig Verification) | SYSTEM | WebhookSig, Denuplication | Stripe/MercadoPago Sig | `backend/src/routes/webhookRoutes.js` | ACTIVE |
| GET | `/api/v1/provider/payouts` | YES | PROVIDER | AuthGuard | Date Query | `backend/src/routes/payoutRoutes.js` | ACTIVE |
| POST | `/api/v1/kyc/submit` | YES | PROVIDER | AuthGuard | Multipart Form | `backend/src/routes/kycRoutes.js` | ACTIVE |
| PUT | `/api/v1/admin/kyc/:id/review` | YES | ADMIN | AuthGuard, AdminGuard | Review Body | `backend/src/routes/adminRoutes.js` | ACTIVE |
| POST | `/api/v1/safety/incidents` | YES | ALL | AuthGuard | Incident Body | `backend/src/routes/safetyRoutes.js` | ACTIVE |
| POST | `/v1/ai/consult` | YES | CLIENT, PROVIDER | Bearer Auth | Prompt Schema | `ai_worker/main.py` | ACTIVE |
| GET | `/api/v1/academy/courses` | YES | PROVIDER | AuthGuard | Query Filter | `backend/src/routes/academyRoutes.js` | ACTIVE |

---

## 3. Webhook Deduplication & Security Audit
- **Replay Protection:** Redis TTL key lookup (`webhook_event:{event_id}`) enforced.
- **Signature Verification:** HMAC-SHA256 signature verification active.
