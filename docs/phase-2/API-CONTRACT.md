# 📄 API Contract — Estándar de Comunicación DTO & Respuestas HTTP

## 1. Formato Único de Respuestas HTTP

### Respuesta Exitosa (`HTTP 200 / 201`)
```json
{
  "success": true,
  "data": {
    "id": "123",
    "nombre": "Corte y Peinado"
  },
  "requestId": "req_8f9a2b1c"
}
```

### Respuesta de Error (`HTTP 4xx / 5xx`)
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Faltan campos obligatorios",
    "details": ["email es requerido"]
  },
  "requestId": "req_8f9a2b1c"
}
```

## 2. Códigos de Estado HTTP Estandarizados
- `200 OK`: Operación exitosa de consulta o actualización.
- `201 Created`: Recurso creado exitosamente.
- `400 Bad Request`: Error de validación de entrada.
- `401 Unauthorized`: Autenticación requerida o token revocado.
- `403 Forbidden`: Permisos o rol insuficiente.
- `404 Not Found`: Recurso no encontrado.
- `409 Conflict`: Conflicto de estado o duplicidad.
- `429 Too Many Requests`: Límite de velocidad superado (Rate Limit).
- `500 Internal Server Error`: Error no controlado en servidor.
