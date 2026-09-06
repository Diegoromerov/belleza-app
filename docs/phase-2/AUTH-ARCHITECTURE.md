# 🔐 Auth Architecture — Infraestructura de Identidad GlowApp

## 1. Visión General
GlowApp Platform opera sobre un modelo unificado de identidad digital centralizado. Se prohíbe la creación de sistemas paralelos de autenticación para roles individuales.

```
[ Cliente Web / App ]  ───( POST /api/auth/login )───> [ Auth Controller ]
[ Prestador Web / POS] ───( Bearer JWT Token )───────> [ Verify Token Middleware ]
[ Admin Command Ctr ]  ───( Check Redis Blacklist )──> [ Controller / Service ]
```

## 2. Emisión y Estructura del JWT
El token JWT se emite utilizando algoritmos HMAC SHA-256 (`HS256`) firmados con la clave secreta `getJwtSecret()` del servidor:

### Payload Claims
```json
{
  "id": "123",
  "email": "usuario@glow.app",
  "role": "client",
  "rol": "CLIENTE",
  "iat": 1757064000,
  "exp": 1757668800
}
```

## 3. Principio de Verificación DB (Fail-Closed)
Aunque el token JWT sea válido sintácticamente, `authMiddleware` consulta en base de datos la vigencia del usuario (`is_active = true`) y obtiene el rol actual de la BD (`usuarios.rol`), impidiendo la manipulación de roles desde el cliente.
