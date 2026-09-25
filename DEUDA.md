# Registro de Deuda Técnica (DEUDA.md)

| ID | Categoría | Componente | Descripción | Estado | Rama Remediación |
|---|---|---|---|---|---|
| TEC-53 | Seguridad | `backend/src/config/jwt.js` & `backend/src/services/biometricCryptoService.js` | Fallback incondicional a literales por defecto en código si falta `JWT_SECRET` o la clave de cifrado biométrico (incondicional, no depende de `NODE_ENV`). Abierto. | Abierto (en remediación) | `fix/jwt-sin-respaldo` (2b) |
