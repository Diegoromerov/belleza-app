# GLOWAPP PHASE 2 — CLIENT STATE MATRIX

## 1. UX State Mapping

| SCREEN | STATE | SOURCE | UX REPRESENTATION | USER ACTION |
| :--- | :--- | :--- | :--- | :--- |
| Client Home | `INITIAL` | App Launch | Skeleton Loaders | None |
| Client Home | `SUCCESS` | API `/api/v1/services` | Service Grid & Hero Banners | Tap Service Card |
| Client Home | `EMPTY` | API empty array | `EmptyState` component | Reset Filters |
| Booking Wizard | `LOADING` | Form Submit | Button Spinner + Disabled Form | Wait |
| Booking Wizard | `ERROR` | API 422 | Inline Field Validation Alert | Correct Inputs |
| Booking Tracking | `UNAUTHORIZED` | Expired Token | Auth Guard Alert + Redirect | Login |
