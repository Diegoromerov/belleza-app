# 🗺️ Domain Map — Catálogo de Dominios Oficiales

Se han definido **14 dominios oficiales de negocio** para GlowApp Platform:

| ID Dominio | Nombre Dominio | Entidades Clave | Responsabilidad Principal | Dominio Owner (GOAL) |
| :--- | :--- | :--- | :--- | :--- |
| **DOM-01** | `AUTH` | User, Token, Role | Autenticación, JWT, Roles y Permisos | GOAL 01 |
| **DOM-02** | `USERS` | User, Profile, UserConsent | Perfiles de usuario y preferencias | GOAL 01 |
| **DOM-03** | `CLIENTS` | User (Cliente), Booking | Experiencia de consumo de servicios | GOAL 08 |
| **DOM-04** | `PROVIDERS` | User (Prestador), Service | Gestión de profesionales y locales | GOAL 07 |
| **DOM-05** | `SERVICES` | Service, Category | Catálogo de servicios de belleza | GOAL 07 |
| **DOM-06** | `BOOKINGS` | Booking, Transaction | Flujo de agendamiento y estados de citas | GOAL 07 |
| **DOM-07** | `PAYMENTS` | Transaction, Payout | Cobros, pasarela de pagos y liquidaciones | GOAL 09 |
| **DOM-08** | `INVENTORY` | Product, Stock, Lot | Control VTO, productos y caja chica POS | GOAL 07 |
| **DOM-09** | `KYC` | UserConsent, Verification | Verificación de identidad y certificaciones | GOAL 10 |
| **DOM-10** | `SAFETY` | SOS, Incident | Botón de pánico SOS y seguridad en campo | GOAL 10 |
| **DOM-11** | `ACADEMY` | Course, Lesson, Quiz | Cursos, lecciones Markdown y capacitaciones | GOAL 11 |
| **DOM-12** | `GROWTH` | Badge, UserLevel, XpLog | Gamificación, niveles y retención | GOAL 11 |
| **DOM-13** | `ANALYTICS` | AnalyticsEvent | Métricas de negocio y telemetría | GOAL 13 |
| **DOM-14** | `NOTIFICATIONS` | Notification, FCM | Avisos push, email y WebSockets | GOAL 12 |
