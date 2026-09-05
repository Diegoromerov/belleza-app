# 🔒 Security Baseline & Threat Audit

## Clasificación de Incidencias e Inseguridad

### 🔴 Prioridad P0 (Crítica - Remediar Inmediatamente)
- **Hardcoded Secrets:** Se identificó en versiones previas JWT Secret en fallback. *Remediado vía variables de entorno.*
- **Endpoint Protection:** Todos los endpoints sensibles en `/api/*` requieren validación obligatoria del middleware `verifyToken`.

### 🟠 Prioridad P1 (Alto Riesgo)
- **Rate Limiting:** Implementar Rate Limiter estricto en rutas de autenticación (`/login`, `/register`) para prevenir ataques de fuerza bruta.
- **CORS Policy:** Restringir orígenes permitidos únicamente a los dominios oficiales de Railway y localhost de desarrollo.

### 🟡 Prioridad P2 (Riesgo Medio)
- **Sanitización de Datos (XSS/SQLi):** Garantizar la sanitización de inputs en el Markdown de la Academia para evitar inyecciones.
