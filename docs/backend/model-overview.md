# Visión General de los Modelos Existentes

Este documento describe brevemente los modelos clave que ya existen en **GlowApp** y que pueden reutilizarse para el CRM de salones de belleza.

| Modelo | Archivo | Propósito principal | Relaciones relevantes |
|--------|---------|---------------------|-----------------------|
| **User** | `backend/src/models/User.js` | Representa a los usuarios de la plataforma (clientes, staff, administradores). | Tiene relaciones con `Booking`, `UserBadge`, `UserPreferences`, `UserConsent`. |
| **Provider** | `backend/src/models/Provider.js` | Información del profesional o negocio que ofrece servicios de belleza. | Relacionado con `Salon`, `Service` y `Booking`. |
| **Salon** | `backend/src/models/Salon.js` | Ubicación física del negocio, datos de contacto, horarios. | Posee múltiples `Service` y `Provider`. |
| **Service** | `backend/src/models/Service.js` | Descripción de los servicios ofrecidos (corte, manicure, etc.) con precio y duración. | Asociado a `Salon` y `Booking`. |
| **Booking** | `backend/src/models/Booking.js` | Reserva de cita entre un `User` y un `Service` dentro de un `Salon`. | Enlaza `User`, `Service`, `Salon` y, opcionalmente, `Provider`. |
| **Transaction** | `backend/src/models/Transaction.js` | Registro de pagos asociados a una `Booking`. | Vinculado a `Booking` y `User`. |
| **Lead** | `backend/src/models/Lead.js` | Representa a un cliente potencial para el salón. | Relacionado con `User` (creador) y `Salon`. |
| **Opportunity** | `backend/src/models/Opportunity.js` | Posible venta derivada de un Lead. | Relacionado con `Lead`, `User` (owner) y `Salon`. |

### Observaciones para el CRM
- La **estructura relacional** ya soporta la mayoría de los conceptos de un CRM (clientes → leads, proveedores → salones, oportunidades → bookings).
- Para el CRM añadiremos nuevos modelos (`Lead`, `Opportunity`) que tendrán **FK** a `User` (creador) y a `Salon` (destino).
- Los modelos actuales están versionados mediante migraciones de Sequelize, lo que facilita la extensión sin romper la aplicación existente.
