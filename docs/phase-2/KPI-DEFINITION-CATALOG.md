# GLOWAPP PHASE 2 — KPI DEFINITION CATALOG

## 1. Single Source of Truth for Platform KPIs

| KPI NAME | DOMAIN | FORMULA / CALCULATION | DATA SOURCE | FREQUENCY | ALERT THRESHOLD |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Booking Conversion Rate** | Marketplace | `(booking_completed / search_started) * 100` | Analytics Event Stream | Daily | < 5% |
| **Provider Acceptance Rate**| Provider | `(booking_accepted / booking_requested) * 100` | Booking Domain DB | Daily | < 85% |
| **Gross Merchandise Value** | Financial | `SUM(booking_total_price)` | Payment Transactions DB| Daily / Monthly| Drops > 15% WoW |
| **Customer Retention (30d)** | Growth | `(users_booking_day30 / cohort_size) * 100` | Cohort Analytics Engine | Monthly | < 25% |
