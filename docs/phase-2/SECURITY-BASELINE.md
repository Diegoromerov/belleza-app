# 🔒 Security Baseline & Threat Audit — GlowApp Platform

## Clasificación de Incidencias e Inseguridad

### 🔴 Prioridad P0 (Crítica - Remediar Inmediatamente)
- **Hardcoded Secrets:** Remediado vía variables de entorno aisladas en Railway (`.env`).
- **Endpoint Protection:** Todos los endpoints sensibles en `/api/*` requieren validación obligatoria del middleware `authMiddleware`.
- **OTP Generation & Logs:** Migrada la generación de OTP a PRNG criptográfico seguro (`crypto.randomInt`) y eliminada la exposición de códigos OTP en los logs de producción (`authController.js`). *(Remediado en GOAL 01)*

### 🟠 Prioridad P1 (Alto Riesgo)
- **Rate Limiting:** Rate Limiting por IP configurado en endpoints de autenticación (`/register`, `/login`, `/forgot-password`, `/reset-password`, `/oauth`). *(Remediado en GOAL 01)*
- **CORS Policy:** Restringir orígenes permitidos únicamente a los dominios oficiales de Railway y localhost de desarrollo.
- **Token Blacklisting:** Verificación Fail-Closed contra la lista negra de Redis (`beauty:token_blacklist:<token>`) para revocación inmediata en logout. *(Remediado en GOAL 01)*

### 🟡 Prioridad P2 (Riesgo Medio)
- **Sanitización de Datos (XSS/SQLi):** Garantizar la sanitización de inputs en el Markdown de la Academia para evitar inyecciones.
