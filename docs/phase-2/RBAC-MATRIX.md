# 👥 RBAC Matrix — Modelo de Roles y Control de Acceso

## Matriz Oficial de Roles de la Plataforma

| Rol Oficial (BD) | Alias API | Descripción / Nivel de Acceso | Rutas Permitidas |
| :--- | :--- | :--- | :--- |
| **`ADMIN`** | `admin` | Administrador Global / Super Admin | Acceso Total (`/`, `/admin/*`, `/chat`, `/perfil`, `/vto`) |
| **`PRESTADOR`** | `provider` | Profesional / Salón de Belleza | Acceso Operativo (`/prestador`, `/prestador/citas`, `/vto`, `/chat`, `/perfil`) |
| **`CLIENTE`** | `client` | Usuario Consumidor Final | Acceso Cliente (`/cliente`, `/cliente/citas`, `/cliente/nueva-cita`, `/chat`, `/perfil`) |

## Preparación para Sub-Roles de la Plataforma
- `SUPER_ADMIN`: Gestión de infraestructura y Railway.
- `OPERATIONS`: Atención SOS y monitoreo en vivo.
- `FINANCE`: Aprobación de Payouts y reportes fiscales.
- `SUPPORT`: Atención al cliente vía Concierge Aura IA.
