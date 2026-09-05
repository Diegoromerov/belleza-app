# 🗄️ Database Inventory — Inventario Oficial de Tablas PostgreSQL

## Inventario Completo de Tablas y Dominios Propietarios

| Tabla PostgreSQL | Dominio Owner | Propósito Principal | Llave Primaria | Integridad / FKs | Tipo de Acceso |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `usuarios` | `AUTH` / `USERS` | Cuentas de usuario, credenciales y roles | `id` (SERIAL/INT) | Ref a `tenants` | `pg pool` & Sequelize |
| `perfiles_prestador` | `PROVIDERS` / `KYC` | Documentos, verificación e información de prestadores | `id` (INT) | FK `usuarios(id)` | `pg pool` |
| `servicios` | `SERVICES` | Catálogo de servicios de belleza | `id` (SERIAL/INT) | FK `usuarios(provider_id)` | Sequelize & `pg pool` |
| `reservas` / `Bookings` | `BOOKINGS` | Citas agendadas y estados de reserva | `id` (SERIAL/INT) | FK `client_id`, `provider_id`, `service_id` | Sequelize & `pg pool` |
| `transacciones` | `PAYMENTS` | Cobros, comprobantes y liquidez de caja | `id` (SERIAL/INT) | FK `booking_id` | Sequelize & `pg pool` |
| `inventario_consignacion_prestador` | `INVENTORY` | Stock de productos en consignación POS | `id` (SERIAL/INT) | FK `provider_id`, `producto_id` | `pg pool` (ACID) |
| `productos` | `INVENTORY` | Catálogo general de insumos y cosméticos | `id` (SERIAL/INT) | PK `id` | `pg pool` |
| `learning_paths` & `path_courses` | `ACADEMY` | Cursos y módulos de capacitación | `id` (INT) | PK `id` | Sequelize |
| `user_badges` & `xp_logs` | `GROWTH` | Medallas, niveles y puntos XP | `id` (INT) | FK `user_id` | Sequelize |
| `analytics_events` | `ANALYTICS` | Eventos de telemetría y métricas | `id` (INT) | FK `user_id` | Sequelize |
| `auditoria_consentimiento_biometrico`| `KYC` / `SAFETY` | Registro legal Habeas Data Ley 1581 | `id` (SERIAL/INT) | FK `user_id` | `pg pool` |
