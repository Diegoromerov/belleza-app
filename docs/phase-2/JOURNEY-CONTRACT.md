# GLOWAPP PHASE 2 — JOURNEY CONTRACT SPECIFICATION

## 1. Physical Journey Contract Schema

### Journey 01: Client Booking Flow
- **Actor:** Client
- **Entry Point:** `provider_detail_screen.dart` / `/(dashboard)/cliente/nueva-cita`
- **Preconditions:** Authenticated Client session.
- **Current Steps (Physical Code):**
  1. Select service & provider in `booking_screen.dart`.
  2. Choose date & time slot.
  3. Submit booking request.
- **Target Steps:** 3-step wizard (1. Cuándo/Dónde → 2. Productos → 3. Pago).
- **System Response:** FCM push notification via `fcmNotificationService.js`, DB insertion in `bookings` table.
- **Success:** Redirect to `booking_tracking_screen.dart`.
- **Error:** Error toast display; preserves selected service & date draft.
- **Dependencies:** `backend/src/routes/bookingRoutes.js`, `frontend/lib/screens/booking_screen.dart`.
- **Owner:** Bookings Domain.
