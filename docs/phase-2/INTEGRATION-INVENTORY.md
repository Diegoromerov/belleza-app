# 🌐 Integration Inventory — Matriz de Integraciones Externas

## Servicios y Proveedores de Terceros Integrados

| Integración | Proveedor | Dominio Owner | Método / Protocolo | Propósito | Modo de Fallo |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **Aura AI Worker** | FastAPI / Python | `AI` / `SAFETY` | HTTP REST (`http://localhost:8000`) | Respuestas en vivo, RAG y asistente Concierge | **Fail-Open (Fallback local)** |
| **Push Notifications** | Firebase FCM | `NOTIFICATIONS` | Google FCM API v1 | Notificaciones push a móviles y web | **Retry con Backoff** |
| **Pasarela de Pagos** | ePayco / Wompi | `PAYMENTS` | REST API & Webhooks | Cobros con TC, PSE y efectivo | **Fail-Safe (No cobro)** |
| **Base de Datos RAG** | PostgreSQL (pgvector) | `AI` | Pool dedicado (`RAG_DATABASE_URL`) | Búsqueda vectorial semántica de belleza | **Fail-Open** |
