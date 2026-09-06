# 🗄️ Data Map — Modelo de Datos, Concurrencia y Fuentes de Verdad

## Fuente de Verdad Persistente
PostgreSQL es la **única fuente persistente de verdad** de GlowApp Platform. El frontend, `localStorage`, cookies o memoria temporal NUNCA constituirán fuentes de verdad para estados de cuenta, reservas o cobros.

## Tablas y Modelos Principales (Domain Ownership)
1. `usuarios` (`AUTH` / `USERS`) — Cuentas, credenciales y roles.
2. `perfiles_prestador` (`PROVIDERS` / `KYC`) — Información de prestadores y documentos.
3. `servicios` (`SERVICES`) — Catálogo de servicios de belleza.
4. `reservas` / `Bookings` (`BOOKINGS`) — Citas agendadas y estados.
5. `transacciones` (`PAYMENTS`) — Registro de pagos y facturación.
6. `inventario_consignacion_prestador` (`INVENTORY`) — Stock POS en consignación (Transacciones ACID atómicas).
7. `productos` (`INVENTORY`) — Catálogo general de insumos.
8. `auditoria_consentimiento_biometrico` (`KYC` / `SAFETY`) — Registro legal Habeas Data Ley 1581.

## Reglas de Integridad y Concurrencia
- **Cero Consultas en Controladores:** Invocaciones SQL aisladas deben migrarse a capas de repositorio por dominio.
- **Parametrización Estricta:** Todas las consultas raw SQL deben utilizar marcadores parametrizados (`$1`, `$2`) previniendo inyecciones.
