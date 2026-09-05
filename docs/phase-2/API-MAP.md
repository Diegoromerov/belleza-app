# 🔌 API Map — Catálogo de Endpoints REST & Realtime

## Backend Production API
Base URL: `https://beauty-app-production-bfd4.up.railway.app/api`

### 1. Autenticación & Usuarios (`/auth`, `/users`)
- `POST /api/auth/login` — Autenticación con credenciales y emisión de JWT.
- `POST /api/auth/register` — Registro de nuevos usuarios y asignación de rol.
- `GET /api/auth/me` — Obtención de información del usuario autenticado.

### 2. Reservas y Citas (`/bookings`)
- `GET /api/bookings` — Lista de reservas por rol (cliente/prestador).
- `POST /api/bookings` — Creación de nueva reserva de servicio.
- `PATCH /api/bookings/:id/status` — Actualización del estado de la cita.

### 3. Inventario y POS (`/inventory`)
- `GET /api/inventory/products` — Consulta de stock de productos y alertas VTO.
- `POST /api/inventory/pos/checkout` — Registro de ventas presenciales de caja.

### 4. Academia y Cursos (`/academy`)
- `GET /api/academy/courses` — Lista de cursos activos.
- `POST /api/academy/courses` — Creación de nuevos cursos de capacitación.

### 5. Chat y Asistente IA (`/chat`, `/ai`)
- `POST /api/ai/chat` — Consulta en tiempo real al worker de Aura IA.
