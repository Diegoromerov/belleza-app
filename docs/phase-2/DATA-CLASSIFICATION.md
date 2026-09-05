# 🔒 Data Classification — Clasificación y Protección PII

## Categorías de Confidencialidad de Datos

| Nivel de Clasificación | Tipo de Datos | Campos Específicos | Política de Almacenamiento & Exposición |
| :--- | :--- | :--- | :--- |
| **SENSITIVE / PII** | Datos Personales & Biométricos | `password_hash`, `documento_id_url`, `rut_url`, `habeas_data_ip` | **Estrictamente Confidencial.** Prohibido imprimir en logs del servidor o exponer en DTOs públicos. |
| **CONFIDENTIAL** | Datos Monetarios & Financieros | `monto_total`, `comision_glow`, `saldo_consignado`, `cuenta_bancaria` | Accesible únicamente por el titular autenticado o rol `ADMIN` / `FINANCE`. |
| **INTERNAL** | Datos Operativos | `booking_id`, `status`, `fcm_token`, `stock_disponible` | Uso interno de la plataforma y servicios backend. |
| **PUBLIC** | Datos del Catálogo | `nombre_servicio`, `precio_publico`, `nombre_prestador`, `foto_url` | Dominio público para navegación del cliente marketplace. |
