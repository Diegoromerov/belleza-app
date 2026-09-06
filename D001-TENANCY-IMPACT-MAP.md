# D001-TENANCY-IMPACT-MAP.md

# IMPACT MAP OF MULTI-TENANCY ON GLOWAPP COMPONENTS

| Componente | Impacto de Añadir tenant_id + RLS | Detalles |
|------------|-----------------------------------|----------|
| **Esquema de Base de Datos** | ALTO | Requere añadir columna `tenant_id` a todas las tablas de negocio y crear tabla `tenants`. |
| **Migraciones** | ALTO | Necesario crear migraciones que añadan la columna, establezcan valores por defecto (para datos existentes) y creen la tabla `tenants`. |
| **Consultas (SELECT)** | ALTO | Todas las queries deben incluir filtro `WHERE tenant_id = $tenantId` o equivalente. Esto afecta tanto a Sequelize como a consultas crudas con `pool.query`. |
| **Inserciones (INSERT)** | MEDIO | Al insertar, se debe proporcionar el `tenant_id` correspondiente (obtenido del contexto de autenticación). |
| **Actualizaciones (UPDATE)** | MEDIO | Similar a inserciones, requiere incluir `tenant_id` en la condición WHERE para asegurar que solo se actualicen registros del propio tenant. |
| **Eliminaciones (DELETE)** | MEDIO | Similar a actualizaciones, requiere filtro por `tenant_id`. |
| **Transacciones** | BAJO | Las transacciones existentes pueden continuar funcionando siempre que todas las operaciones dentro de ellas respeten el filtro de tenant. |
| **Índices** | MEDIO | Se recomienda añadir índices en `tenant_id` (y posiblemente en combinación con otras columnas frecuentemente filtradas) para mejorar rendimiento de búsquedas por tenant. |
| **APIs / Endpoints** | BAJO (si ya filtran por usuario) | Los endpoints que actualmente filtran por `req.user.id` (como `/bookings/provider`) continuarán funcionando si se establece que `tenant_id` se deriva del usuario (por ejemplo, uno-a-uno). Si el tenant es distinto del usuario, se requerirá ajustar la lógica de resolución. |
| **Middleware de Autenticación/Autorización** | BAJO | Se puede añadir un middleware que resuelva el `tenant_id` a partir de `req.user.id` (consultando una tabla de mapeo o asumiendo que el usuario es el tenant) y lo haga disponible para downstream (por ejemplo, adjuntándolo a `req` o estableciendo una variable de sesión de PostgreSQL). |
| **ORM (Sequelize)** | MEDIO | Puede requerir configurar un scope global o un hook que añada automáticamente la condición `tenant_id = :tenantId` a todas las queries de los modelos. Alternativamente, revisar cada uso de los modelos para asegurar el filtro. |
| **Consultas Crudas (pgPool)** | ALTO | Todas las llamadas a `pool.query` deben ser revisadas para incluir el parámetro `tenant_id` en la cláusula WHERE cuando corresponda. |
| **Transacciones Financieras (pagos)** | ALTO | Las tablas `bookings` y `transactions` deben incluir `tenant_id` para asegurar que los pagos queden asociados al salón correcto y que los reportes de caja sean por tenant. |
| **Agenda / Reservas** | ALTO | Las tablas `bookings` y relacionados (`services`, `perfiles_prestador`) deben estar aislados por tenant para que un salón solo vea sus propias reservas y servicios. |
| **Perfiles de Prestador** | ALTO | La tabla `perfiles_prestador` debe incluir `tenant_id` si el concepto de tenant es el salón y un salón puede tener múltiples profesionales. Si el tenant es el profesional individual, entonces `tenant_id` podría ser idéntico a `perfiles_prestador.id` o `usuarios.id`. |
| **Servicios** | ALTO | Similar a perfiles_prestador: los servicios deben estar vinculados al tenant para que un salón solo gestione sus propios servicios. |
| **RAG / Conocimiento** | MEDIO | La tabla `beauty_knowledge_embeddings` podría requerir `tenant_id` si el conocimiento es específico por salón (por ejemplo, tratamientos propios, promociones). Si el conocimiento es global y compartido, entonces no se requiere `tenant_id`. Se debe decidir basado en la política de uso de conocimiento. |
| **Logs de Actividad de Usuario** | MEDIO | La tabla `user_activity_logs` podría beneficiarse de `tenant_id` para permitir auditoría por salón. |
| **Configuración de Plataforma** | MEDIO | La tabla `platform_config` podría necesitar `tenant_id` si se permite configuración por salón (por ejemplo, porcentaje de comisión, horarios de trabajo). Si la configuración es global, entonces no se requiere. |
| **Notificaciones** | BAJO | Las notificaciones (por ejemplo, mediante WebSocket o SMS) ya están vinculadas a un usuario específico; si se asume que el usuario pertenece a un solo tenant, entonces no se requiere cambio adicional. |
| **Archivos y Almacenamiento** | BAJO | Si los archivos se almacenan en un servicio externo con URLs que incluyen identificadores, se debe asegurar que esas URLs incluyan contexto de tenant o que el servicio de almacenamiento implemente control de acceso por tenant. |
| **Trabajos de Fondo (Cron / Workers)** | MEDIO | Si existen trabajos de fondo, deben ser diseñados para operar dentro del contexto de un tenant específico (por ejemplo, incluyendo `tenant_id` en el payload del trabajo). |
| **Caché (Redis)** | MEDIO | Las claves de caché deben incluir identificadores de tenant para evitar fugas de datos entre tenants mediante caché compartida. |
| **Reportes y Analíticas** | ALTO | Cualquier reporte que agregue datos debe agrupar por `tenant_id` para asegurar que los resultados sean por salón y no mezclen información de distintos salones. |

---
Fin del impacto map.