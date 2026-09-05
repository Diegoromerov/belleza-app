# GLOWAPP PHASE 2 — NAVIGATION CONTRACT

## 1. Architectural Navigation Rules
1. **Role-Aware Routing:** Navigation menus, headers, sidebars, and bottom bars must dynamically render based on verified RBAC roles (`CLIENT`, `PROVIDER`, `ADMIN`).
2. **UI Visibility != Authorization:** Visual menu item suppression is purely a UX optimization. Backend middleware and API routes continue to enforce strict authorization.
3. **Preservation of Context:** When navigating back from detail pages or modals, user context (filters, active tab, scroll position, search query) must be preserved.
4. **Deep Linking Contract:** All primary resources (`service/:id`, `provider/:id`, `booking/:id`, `payment/:id`) must support direct deep-linking with appropriate auth guard fallbacks.
5. **Back Button Behavior:** Browser back, app top bar back, and modal dismiss buttons must resolve consistently without infinite loops or unexpected logouts.
