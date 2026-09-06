# 🔄 Session Architecture — Modelo de Sesión & Revocación

## 1. Almacenamiento e Interceptor Unificado
- **Frontend Storage:** El token se almacena en `localStorage` bajo las claves `glow_token` y `glow_user`.
- **Cabecera HTTP:** Todas las solicitudes autenticadas adjuntan `Authorization: Bearer <token>`.
- **API Client Layer:** Axios intercepta respuestas `401 Unauthorized` para desloguear limpiamente al usuario y redirigir a `/login`.

## 2. Revocación de Sesión (Blacklist con Redis)
Al ejecutar `POST /api/auth/logout`:
1. Se extrae el token JWT actual de la cabecera.
2. Se calcula el tiempo restante de expiración (`TTL = exp - now`).
3. Se almacena la clave `beauty:token_blacklist:<token>` en Redis con el TTL correspondiente.
4. Cualquier petición posterior con ese token es rechazada inmediatamente con `HTTP 401`.
