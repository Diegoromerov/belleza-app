# 🪝 Webhook Architecture — Arquitectura de Webhooks

## 1. Principios de Seguridad en Webhooks
- **Verificación de Firma:** Todo webhook entrante (ej. pasarelas de pago) verifica la firma criptográfica enviada en la cabecera HTTP (`x-signature` / `x-sha256`).
- **Control de Idempotencia:** Se extrae el identificador del evento (`event_id`) y se registra en Redis (`beauty:webhook:processed:<eventId>`) con TTL de 72 horas para prevenir doble procesamiento.
- **Respuesta Inmediata:** El endpoint responde `HTTP 200 OK` inmediatamente tras encolar o procesar la transacción para evitar reintentos del proveedor.

## 2. Diagrama de Procesamiento
```
[ Pasarela Externa ] ───( POST /api/payments/webhook )───> [ Webhook Handler ]
                                                                   │
                                                      ┌────────────┴────────────┐
                                                      ▼                         ▼
                                            [ Validar Firma ]        [ Check Idempotencia ]
                                                      │                         │
                                                      └────────────┬────────────┘
                                                                   ▼
                                                       [ Ejecutar Transacción ]
```
