# ⚡ Cache Matrix — Estrategia de Caché en Redis

## Matriz de Gestión de Caché

| Tipo de Datos | Clave de Redis | TTL | Estrategia de Invalidación | Comportamiento ante Fallo |
| :--- | :--- | :--- | :--- | :---: |
| **Lista Negra de Tokens** | `beauty:token_blacklist:<token>` | Restante del JWT (Max 7 días) | Expiración automática TTL | **Fail-Closed (HTTP 503)** |
| **Códigos OTP de Recuperación** | `beauty:otp:<email>` | 10 minutos (600s) | Eliminación tras uso exitoso | **Fail-Closed** |
| **Sesión de Usuario** | `beauty:session:<userId>` | 1 hora (3600s) | Invalidados al hacer logout o cambio de clave | **Fail-Open (Consulta DB)** |
| **Catálogo de Servicios** | `beauty:cache:services` | 15 minutos (900s) | Invalidado al actualizar un servicio | **Fail-Open (Consulta DB)** |
