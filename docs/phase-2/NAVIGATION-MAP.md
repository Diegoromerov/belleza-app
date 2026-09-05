# ⛵ Navigation Map — Matriz de Navegación por Roles

## Modelo de Navegación Dinámica
`Navegación = Rol de Usuario + Permisos Directos + Feature Flags + Contexto de Sesión`

### 1. Rol: Super Admin
- Dashboard Global (`/`)
- Academia GlowAdmin (`/admin/academia`)
- Control Inventario VTO (`/admin/vto`)
- Centro de Mensajes (`/chat`)
- Mi Perfil (`/perfil`)

### 2. Rol: Prestador de Servicios
- Dashboard Prestador (`/prestador`)
- Mis Citas (`/prestador/citas`)
- Inventario VTO (`/admin/vto`)
- Mensajes Concierge (`/chat`)
- Mi Perfil (`/perfil`)

### 3. Rol: Cliente Final
- Dashboard Cliente (`/cliente`)
- Mis Citas (`/cliente/citas`)
- Nueva Cita (`/cliente/nueva-cita`)
- Chat Aura IA (`/chat`)
- Mi Perfil (`/perfil`)
