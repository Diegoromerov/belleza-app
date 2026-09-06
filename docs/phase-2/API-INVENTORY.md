# 🔌 API Inventory — Inventario Oficial de Endpoints REST & WebSockets

## Catálogo Completo de Endpoints Backend

| Método | Ruta Endpoint | Dominio Owner | Autenticación | Roles Autorizados | Propósito Principal |
| :--- | :--- | :--- | :---: | :--- | :--- |
| `POST` | `/api/auth/register` | `AUTH` | Pública | Todos (`PRESTADOR`/`CLIENTE`) | Registro de nuevos usuarios |
| `POST` | `/api/auth/login` | `AUTH` | Pública | Todos | Inicio de sesión con JWT |
| `POST` | `/api/auth/logout` | `AUTH` | `Bearer JWT` | Todos | Cierre de sesión y revocación en Redis |
| `POST` | `/api/auth/forgot-password` | `AUTH` | Pública | Todos | Solicitud de código OTP |
| `POST` | `/api/auth/reset-password` | `AUTH` | Pública | Todos | Restablecimiento de clave con OTP |
| `GET` | `/api/bookings` | `BOOKINGS` | `Bearer JWT` | Todos | Listado de citas agendadas |
| `POST` | `/api/bookings` | `BOOKINGS` | `Bearer JWT` | `CLIENTE` / `ADMIN` | Creación de nueva cita |
| `PATCH`| `/api/bookings/:id/status` | `BOOKINGS` | `Bearer JWT` | `PRESTADOR` / `ADMIN` | Transición de estado de cita |
| `GET` | `/api/services` | `SERVICES` | Pública | Todos | Catálogo público de servicios |
| `GET` | `/api/inventory/consignacion` | `INVENTORY` | `Bearer JWT` | `PRESTADOR` / `ADMIN` | Stock de consignación POS |
| `POST` | `/api/inventory/consume` | `INVENTORY` | `Bearer JWT` | `PRESTADOR` / `ADMIN` | Consumo atómico de insumos |
| `GET` | `/api/academy/courses` | `ACADEMY` | `Bearer JWT` | Todos | Cursos y capacitaciones |
| `POST` | `/api/academy/courses` | `ACADEMY` | `Bearer JWT` | `ADMIN` | Creación de nuevos cursos |
| `POST` | `/api/ai/chat` | `SAFETY` / `AI` | `Bearer JWT` | Todos | Asistente en vivo Aura IA |
