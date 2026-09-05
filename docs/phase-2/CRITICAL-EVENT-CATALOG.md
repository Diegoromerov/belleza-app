# GLOWAPP PHASE 2 — CRITICAL EVENT CATALOG

## 1. Event & Notification Payload Specification

| EVENT NAME | RECIPIENT | CHANNEL | DEEP LINK | RETRY POLICY |
| :--- | :--- | :--- | :--- | :--- |
| `KYC_SUBMITTED` | Admin Queue | In-App / Email | `/admin/kyc` | 3 Retries |
| `KYC_APPROVED` | Provider | Push (FCM) / Email | `/provider/profile` | 5 Retries |
| `DISPUTE_OPENED` | Admin Safety | In-App / Pager | `/admin/disputes/:id` | Immediate |
| `PAYMENT_APPROVED`| Client & Provider| Push (FCM) | `/client/bookings/:id` | 3 Retries |
