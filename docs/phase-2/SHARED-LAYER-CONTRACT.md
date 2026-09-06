# 🤝 Shared Layer Contract — Reglas de la Capa Compartida

## Reglas de Inclusión en `shared/`
1. Se prohíbe colocar lógica de negocio específica de un solo dominio en `shared/`.
2. Componentes permitidos en `shared/`:
   - Middleware de autenticación y autorización (`authMiddleware`).
   - Manejadores universales de errores (`AppError`).
   - Registradores de logs (`logger.js`).
   - Utilidades de fecha y formato.
