# D-002 PAYMENT BOUNDARY ANALYSIS

## Analysis of Payment-Related Functionality

### Current State
- The system processes payments for services booked through the platform.
- Payment gateways (Wompi, Nequi) are integrated.
- Commissions are calculated and can be set by the salon (tenant).
- There is no payroll functionality or salary payment processing.

### Evidence
- In `src/controllers/paymentController.js`, there are endpoints for processing payments, refunds, and managing payment methods.
- The `services` table likely stores service prices, and bookings reference services.
- Commission settings are likely stored in a configuration table (e.g., `platform_config` or similar).

### Boundary Analysis
- **SAFE**: Processing payments for services rendered by prestadors (independent contractors) where the salon sets the price and commission, and GlowApp merely facilitates the transaction via a payment gateway.
- **REQUIRES_REVIEW**: Any functionality that would allow GlowApp to hold funds on behalf of the salon for the purpose of paying workers (e.g., a wallet system for workers) would require legal review to ensure it does not make GlowApp an employer or labor intermediary.
- **HIGH_RISK**: Direct payment of salaries or honorarios by GlowApp as an obligor (i.e., GlowApp decides to pay a worker without the salon's explicit instruction per transaction) would be high risk and likely constitute an employment relationship.

### Recommendation
- Maintain the current payment model where GlowApp facilitates payments between the client (salon) and the prestador (service provider) based on the salon's configuration.
- Do not implement any feature that would allow GlowApp to pay workers as an obligor without a clear, per-transaction authorization from the salon.
- If a wallet or held funds feature is desired, it must be structured as the salon's funds held in trust, with GlowApp acting only as a custodian under the salon's direction, and subject to legal review.

---
*Análisis completado el: $(date)*