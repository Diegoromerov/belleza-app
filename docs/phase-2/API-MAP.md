# 🔌 API Map — Catálogo Oficial y Contrato de Comunicación API

## Base URL Oficial de Producción
`https://beauty-app-production-bfd4.up.railway.app/api`

## Formato Estándar de Respuesta DTO
- **Éxito (HTTP 200/201):** `{ "success": true, "data": ..., "requestId": "req_..." }`
- **Error (HTTP 4xx/5xx):** `{ "success": false, "error": { "code": "...", "message": "..." }, "requestId": "req_..." }`

## Gobernanza de Integraciones Externas
1. **AI Worker (FastAPI):** `http://localhost:8000/api/ai` — Fallback Fail-Open.
2. **Push Notifications:** Firebase FCM — Reintentos con Backoff Exponencial.
3. **Webhooks de Pago:** Firma de verificación requerida + Clave de Idempotencia en Redis (`beauty:webhook:processed:<id>`).
