# 📡 Event Catalog — Catálogo Oficial de Eventos

## Catálogo de Eventos del Sistema GlowApp

| Nombre del Evento | Productor | Consumidor Primario | Payload Clave | Criticidad | Idempotente |
| :--- | :--- | :--- | :--- | :---: | :---: |
| `BOOKING_CREATED` | BookingController | NotificationService | `{ bookingId, clientId, providerId, date }` | **Alta** | Sí |
| `BOOKING_CONFIRMED` | BookingController | FCM Push & Socket.io | `{ bookingId, status }` | **Alta** | Sí |
| `PAYMENT_APPROVED` | PaymentController | InventoryService / POS | `{ transactionId, amount, bookingId }` | **Crítica** | Sí |
| `SOS_TRIGGERED` | SafetyController | Operations Dashboard | `{ incidentId, location, userId }` | **Crítica** | Sí |
| `INVENTORY_CONSUMED`| InventoryController| Analytics & VTO | `{ productId, quantity, providerId }` | **Media** | Sí |
