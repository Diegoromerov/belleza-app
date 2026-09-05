# 🔀 Concurrency Matrix — Matriz de Aislamiento y Bloqueos

## Matriz de Control de Concurrencia

| Escenario de Concurrencia | Mecanismo de Aislamiento | Prevención de Deadlocks |
| :--- | :--- | :--- |
| **Consumo de Stock en POS** | Transacción atómica `BEGIN` + `SELECT ... FOR UPDATE` + `COMMIT` | Ordenamiento estricto por `id` de producto. |
| **Reserva Doble de Cita** | Transacción condicional `WHERE NOT EXISTS (SELECT 1 FROM reservas WHERE provider_id = X AND fecha = Y)` | Restricción `UNIQUE(provider_id, fecha_inicio)` en DB. |
| **Actualización de Saldo Prestador** | Incremento atómico en base de datos (`saldo = saldo + $1`) | Evita lecturas/escrituras sucias sin bloqueos largos. |
