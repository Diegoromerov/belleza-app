# GLOWAPP PHASE 2 — JOURNEY CONTRACT SPECIFICATION

## 1. Journey Contract Schema

### Journey 01: Client Appointment Booking
- **Actor:** Client
- **Entry Point:** Service Detail Page / Provider Profile (`/client/explore`)
- **Preconditions:** Authenticated Client session (or inline Auth prompt during checkout).
- **Steps:**
  1. *Step 1 (Cuándo/Dónde):* Select date, time slot, and location preference (salon / home service).
  2. *Step 2 (Productos & Add-ons):* Optional cross-sell product selection.
  3. *Step 3 (Pago & Confirmación):* Review sticky summary, apply promo code, execute payment.
- **System Response:** Instant booking receipt, FCM push notification to Provider, status set to `CONFIRMED`.
- **Success:** Redirect to `/client/bookings/:id` with real-time tracker.
- **Error:** Payment failure banner with retry CTA; preserves selected date/time slot draft.
- **Exit:** Booking status view or Client Home.
- **Dependencies:** Auth (Goal 01), API Contracts (Goal 04), Design System (Goal 05).
- **Owner:** Bookings & Client Domain.
