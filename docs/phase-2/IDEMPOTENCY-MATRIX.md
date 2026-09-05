# 🔁 Idempotency Matrix — Control de Operaciones Repetidas

## Matriz de Idempotencia por Operación

| Operación de Negocio | Clave de Idempotencia | Almacenamiento TTL | Comportamiento en Reintento |
| :--- | :--- | :--- | :--- |
| **Procesar Cobro / Pago** | `idempotency_key` (UUID v4) | Redis (`beauty:idempotency:pay:<key>`, 24h) | Retorna el resultado original sin duplicar el cobro. |
| **Consumo de Inventario POS** | `transaction_reference` | PostgreSQL (`inventario_consignacion_prestador`) | Bloqueo de fila `FOR UPDATE` atómico. |
| **Solicitud de Payout** | `payout_request_id` | Redis / PostgreSQL | Estado `PENDIENTE` impide solicitudes duplicadas. |
| **Confirmar Cita** | `booking_id` + `status` | PostgreSQL (`reservas`) | Actualización condicional idempotente `WHERE status = 'PENDIENTE'`. |
