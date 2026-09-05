# 🗄️ Data Map — Modelo de Datos y PostgreSQL Schema

## Tablas y Modelos Principales (Sequelize)
1. `Users` — Usuarios del sistema (email, password_hash, rol, nombre, teléfono).
2. `Services` — Catálogo de servicios ofrecidos por prestadores.
3. `Bookings` — Citas agendadas (client_id, provider_id, service_id, date, status).
4. `Transactions` — Registro de pagos y transacciones de caja.
5. `LearningPaths` & `PathCourses` — Cursos y rutas de aprendizaje de la Academia.
6. `UserBadges` & `XpLogs` — Gamificación, insignia y puntos de experiencia.
7. `AnalyticsEvents` — Eventos de telemetría y uso de la plataforma.

## Constraints & Concurrencia
- **Foreign Keys:** `Bookings` mantiene relación estricta con `Users` (`client_id`, `provider_id`) y `Services` (`service_id`).
- **Riesgo Identificado:** Operaciones de actualización de stock en inventario requieren transacciones atómicas (`ACID`) para evitar race conditions en horas pico.
