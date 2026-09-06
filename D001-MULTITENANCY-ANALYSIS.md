# D001-MULTITENANCY-ANALYSIS.md

# ANÁLISIS DE MULTI-TENANCY PARA D-001

## 1. DESCUBRIMIENTO REAL

Se inspeccionó el código existente en las rutas especificadas:

- `backend/schema.sql` – esquema completo de la base de datos.
- `backend/migrations/` – historial de migraciones.
- `backend/src/` – controladores, servicios, rutas, modelos, configuración.
- `frontend/` – estructura de directorios (no se inspeccionó código Flutter en detalle, pero se verificó existencia).
- `tests/` – pruebas unitarias y de integración.
- Configuración: archivos `.js` en `backend/src/config/`.

## 2. RESPUESTAS A PREGUNTAS CLAVE

### 4.1 ¿Qué entidad representa actualmente al salón?
No existe una entidad explícita "salon" en el modelo de datos. La entidad más cercana es `perfiles_prestador` (provider profile), la cual está vinculada a un `usuario` y contiene campos como `business_name`, `description`, `ubicacion`, etc. En la práctica, cada `perfil_prestador` puede representar un profesional independiente o un salón si se asume una relación uno-a-uno entre profesional y negocio. No hay una entidad que agrupe a múltiples profesionales bajo un mismo salón.

### 4.2 ¿Existe actualmente `tenant`, `tenant_id`, `organization`, `business`, `salon` u otra entidad equivalente?
**NO**. No se encontró ninguna columna denominada `tenant_id`, `organization_id`, `business_id` o `salon_id` en ninguna tabla. El campo `business_name` en `perfiles_prestador` es descriptivo y no sirve como identificador único ni como clave de particionamiento.

### 4.3 ¿Cómo se relacionan actualmente: USER, SALON, PROVIDER, BOOKING, SERVICE, PAYMENT, CLIENT?
- **USER**: tabla `usuarios`. Representa tanto a clientes como a proveedores (según el campo `rol`: 'CLIENTE' o 'PRESTADOR').
- **SALON**: No hay entidad dedicada. El concepto de salón se implícita en `perfiles_prestador` (cuando un usuario tiene rol 'PRESTADOR').
- **PROVIDER**: `perfiles_prestador` (vinculado a `usuarios` mediante `id`).
- **BOOKING**: tabla `bookings`. Tiene `client_id` (FK a `usuarios.id`) y `provider_id` (FK a `perfiles_prestador.id`).
- **SERVICE**: tabla `services`. Tiene `provider_id` (FK a `perfiles_prestador.id`).
- **PAYMENT**: tabla `transactions`. Tiene `booking_id` (FK a `bookings.id`).
- **CLIENT**: `usuarios` con rol 'CLIENTE'.

Flujo típico: Un cliente (usuario) crea una reserva (`booking`) vinculada a un servicio y a un proveedor; el pago se registra en `transacciones` vinculado a la reserva.

### 4.4 ¿Qué tablas son actualmente compartidas?
**Todas las tablas están compartidas en un único esquema público.** No hay particionamiento, esquemas separados ni bases de datos distintas por cualquier notion de tenant.

### 4.5 ¿Qué endpoints permiten acceder a datos?
Los endpoints bajo `backend/src/routes/` filtran datos principalmente por el `id` del usuario autenticado (`req.user.id`) obtenido del JWT. Ejemplos:
- `GET /bookings/provider` → reservas donde `provider_id = req.user.id`.
- `GET /bookings/client` → reservas donde `client_id = req.user.id`.
- `GET /services/provider` → servicios donde `provider_id = req.user.id`.
- Otros endpoints (como `/payments/*`) usan el `booking_id` derivado de la reserva, que a su vez está vinculado al usuario.

No se observaron endpoints que acepten un `provider_id` o `client_id` arbitrario en la URL sin verificar que coincida con el usuario autenticado (aunque se requiere revisión exhaustiva de cada ruta).

### 4.6 ¿Dónde se realiza actualmente autorización?
- **Autenticación**: middleware `authMiddleware` que verifica JWT y adjunta `req.user`.
- **Autorización**: verificaciones de rol en los controladores (p. ej., en `bookingController.getProviderBookings` se verifica que `req.user.role` sea 'provider' o 'PRESTADOR'). No hay verificaciones de pertenencia a una entidad de salón más allá del `user_id`.

### 4.7 ¿Existen queries que produzcan acceso horizontal entre salones?
Dado que no hay concepto de salón separado, el acceso horizontal sería entre distintos **usuarios** (proveedores o clientes). En los endpoints inspeccionados, las consultas filtran siempre por el `id` del usuario autenticado (por ejemplo, `WHERE provider_id = $1` con `$1 = req.user.id`). Por lo tanto, **no se encontró evidencia directa de queries que permitan a un usuario ver datos de otro usuario** en los endpoints de reserva, servicio o pago revisados.

Sin embargo, es necesario revisar exhaustivamente todos los endpoints (incluyendo aquellos de administración, configuración, etc.) para descartar cualquier consulta que use un parámetro `:id` sin validar que pertenezca al usuario actual. Hasta que se haga esa revisión, no se puede afirmar la ausencia total de riesgo.

### 4.8 ¿Qué ORM, query builder o mecanismo de acceso a PostgreSQL utiliza realmente el proyecto?
El proyecto utiliza **dos mecanismos de acceso a datos**:
1. **Sequelize** (ORM): se ve en la importación `const { Booking, Service, User, Transaction } = require('../models');` y en operaciones como `Booking.findAll()`, `sequelize.transaction()`, etc.
2. **pgPool** (consultas crudas): se ve en `const { pool } = require('../config/db');` y en llamadas como `await pool.query('SELECT ...', [params]);`.

Ambos se usan simultáneamente según el caso (por ejemplo, reportes complejos usan `pool.query`, mientras que operaciones de CRUD usan los modelos de Sequelize).

## 3. ESTADO ACTUAL DE POSTGRESQL Y EXTENSIONES
- **PostgreSQL**: El esquema incluye `CREATE EXTENSION IF NOT EXISTS postgis;` y `CREATE EXTENSION IF NOT EXISTS vector;` (para pgvector). Por lo tanto, **PostgreSQL está verificado como motor de base de datos**.
- **Row Level Security (RLS)**: No se encontró ninguna instrucción `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` ni creación de políticas en el esquema inspeccionado. **RLS no está implementado actualmente**.
- **Redis**: Se encontró configuración en `/c/beauty-app/backend/src/config/redis.js`, indicando que Redis se usa para caché y/o sesiones. **Redis está presente**.
- **Almacenamiento de archivos**: No se inspeccionó específicamente, pero se observan campos como `foto_url`, `documento_id_url`, etc., que sugieren almacenamiento de URLs (probablemente en un servicio externo como S3 o almacenamiento local). No se vio evidencia de almacenamiento de archivos local en el código inspeccionado.
- **Colas / workers / jobs**: No se encontró evidencia de sistemas de colas (como Bull, RabbitMQ) ni de workers en el código inspeccionado. Se observan funciones de `setTimeout` para simulaciones, pero no workers de fondo.
- **Caché**: Además de Redis, se observó uso de `memory caché` en algunos servicios (por ejemplo, en servicios de IA se menciona caché de embeddings). No se encontró un sistema de caché distribuido más allá de Redis.

## 4. ANÁLISIS DE LAS CUATRO ALTERNATIVAS

### A — Shared Schema + tenant_id
- **Descripción**: Añadir una columna `tenant_id` a todas las tablas relevantes y filtrar por ella en todas las consultas.
- **Evidencia actual**: No existe `tenant_id`. Se necesitaría añadirla a tablas como `usuarios`, `perfiles_prestador`, `services`, `bookings`, `transactions`, etc., y crear una tabla `tenants` para almacenar información del salón.
- **Infraestructura real**: PostgreSQL soporta esta técnica nativamente.
- **Escala esperada**: Adecuado para cientos a miles de tenants con datos relativamente aislados; requiere índices en `tenant_id`.
- **Complejidad**: Baja a media (requiere migraciones y actualización de consultas).
- **Seguridad**: Depende de la correcta aplicación del filtro `tenant_id` en todas las queries; riesgo de olvidar algún filtro.
- **Operación**: Necesita asegurar que todas las nuevas consultas incluyan el filtro; las existentes deben ser auditadas.
- **Costo**: Bajo (no requiere licencias adicionales).
- **Migración**: Requiere backfill de `tenant_id` para datos existentes (asignar un tenant por cada usuario/proveedor basado en alguna regla, posiblemente uno-a-uno con `usuarios.id`).

### B — Shared Schema + tenant_id + RLS
- **Descripción**: Como A, pero añadir políticas de Row Level Security en PostgreSQL para enforcar el filtrado a nivel de base de datos, reduciendo riesgo de errores en la aplicación.
- **Evidencia actual**: No hay RLS configurado.
- **Infraestructura real**: PostgreSQL 9.5+ soporta RLS.
- **Escala esperada**: Similar a A, pero con mayor seguridad inherente.
- **Complejidad**: Media (requiere definición de políticas y pruebas).
- **Seguridad**: Alta (la base de datos en sí misma bloquea consultas que no respeten el tenant).
- **Operación**: Menos riesgo de fuga por error de aplicación, pero requiere mantenimiento de políticas.
- **Costo**: Bajo.
- **Migración**: Igual que A, además de crear y probar las políticas RLS.

### C — Schema-per-tenant
- **Descripción**: Cada tenant tiene su propio esquema dentro de la misma base de datos; las tablas se crean en esquemas como `tenant_1`, `tenant_2`, etc.
- **Evidencia actual**: No hay esquemas separados.
- **Infraestructura real**: PostgreSQL soporta múltiples esquemas; se necesitaría un mecanismo de enrutamiento que cambie el `search_path` según el tenant.
- **Escala esperada**: Limitado por el número de esquemas que PostgreSQL maneja eficientemente (decenas a cientos; miles pueden ser problemáticos).
- **Complejidad**: Media-alta (requiere lógica de cambio de esquema, posible uso de `SET search_path` por conexión o transacción).
- **Seguridad**: Buena aislamiento a nivel de esquema, pero depende de correcto enrutamiento.
- **Operación**: Más complejo de gestionar (backups, migraciones deben aplicarse a cada esquema).
- **Costo**: Medio (mayor complejidad operativa).
- **Migración**: Requiriría crear un esquema por cada tenant existente y migrar los datos corrispondientes.

### D — Database-per-tenant
- **Descripción**: Cada tenant tiene su propia base de datos física.
- **Evidencia actual**: Solo una base de datos está configurada.
- **Infraestructura real**: Requiere múltiples conexiones de base de datos y un enrutador que seleccione la DB según el tenant.
- **Espera de escala**: Adecuado para pocos tenants con alta aislación requerida; no escala bien a cientos o miles debido al overhead de conexiones y mantenimiento.
- **Complejidad**: Alta (requiere gestión de múltiples pools de conexiones, migraciones por DB, etc.).
- **Seguridad**: Muy alta (aislamiento total a nivel de instancia).
- **Operación**: Alto overhead operativo (backups, monitoreo, actualizaciones por cada DB).
- **Costo**: Alto (recursos de infraestructura multiplicados).
- **Migración**: Requiriría crear una base de datos por tenant y migrar los datos.

## 5. SECURITY THREAT MAP (BASED ON CODE INSPECTION)

Se inspeccionó el código para identificar riesgos de acceso horizontal. Hasta el punto de inspección, **no se encontró evidencia directa de los siguientes riesgos** en los módulos revisados (controladores de booking, servicios, routes principales). Sin embargo, se debe realizar una revisión completa para confirmar.

| Riesgo | Evidencia encontrada | Comentario |
|--------|----------------------|------------|
| Horizontal Privilege Escalation | NO EVIDENCE FOUND (en endpoints inspeccionados) | Se requiere revisión de todos los endpoints que usen `:id` sin validación de propiedad. |
| Broken Object Level Authorization | NO EVIDENCE FOUND | Las rutas inspeccionadas filtran por `req.user.id`. |
| Missing tenant filter | APLICABLE (no hay tenant_id) | Todas las queries actuales carecen de filtro de tenant porque no existe la columna. |
| Cross-tenant JOIN | NO EVIDENCE FOUND | No se observaron joins que pudieran combinar datos de distintos usuarios sin filtro explícito. |
| Cross-tenant search | NO EVIDENCE FOUND | Las búsquedas inspeccionadas están acotadas al usuario autenticado. |
| Cross-tenant report | NO EVIDENCE FOUND | Los reportes inspeccionados (por ejemplo, en `analyticsController`) aún no fueron revisados a fondo. |
| Cross-tenant cache | NO EVIDENCE FOUND | Se usa Redis; se necesita inspeccionar si las claves de caché incluyen contexto de usuario/tenant. |
| Cross-tenant file | NO EVIDENCE FOUND | No se observó almacenamiento de archivos local; se asume que los URLs apuntan a un almacenamiento externo que debería aislar por tenant. |
| Cross-tenant background job | NO EVIDENCE FOUND | No se observaron workers de fondo en el código inspeccionado. |
| Cross-tenant RAG retrieval | NO EVIDENCE FOUND | La tabla `beauty_knowledge_embeddings` no tiene `tenant_id`; si se usa para RAG global, podría haber fuga. Esto se analiza en la sección 9. |

## 6. TENANT BOUNDARY

Con base en el flujo actual de autenticación y autorización:

```
REQUEST
 ↓
AUTHENTICATION (authMiddleware → req.user)
 ↓
USER (usuarios.id, rol)
 ↓
TENANT RESOLUTION (actualmente: el propio usuario actúa como tenant implícito si se considera un profesional independiente)
 ↓
AUTHORIZATION (verificación de rol y, en algunos casos, de ownership explícito en queries)
 ↓
SERVICE (controlador)
 ↓
REPOSITORY (modelos Sequelize o queries directas)
 ↓
DATABASE
```

Actualmente, **no existe una etapa explícita de "TENANT RESOLUTION"** más allá de identificar al usuario autenticado. Si se decide que el tenant es el salón (negocio), se necesitaría una fase de resolución que mapee `req.user.id` → `salon_id` (potencialmente a través de `perfiles_prestador` o una futura tabla `salones`). Si el tenant es el usuario profesional, entonces la resolución es trivial (el propio `user.id`).

## 7. IMPACTO DE MULTI-TENANCY SOBRE RAG

Se inspeccionó la tabla `beauty_knowledge_embeddings` (líneas 282-291 del schema). No contiene columna `tenant_id` ni ningún otro identificador de organización. El contenido parece ser conocimiento general de belleza (posiblemente extraído de fuentes públicas o provisto por la plataforma). 

- **¿Existe RAG?** Sí, la tabla sugiere un sistema de embeddings para búsqueda semántica.
- **¿Dónde está?** En la base de datos, tabla `beauty_knowledge_embeddings`.
- **¿Qué almacena?** Títulos, categorías, contenido textual y embeddings de 768 dimensiones.
- **¿Cómo recupera información?** No se inspeccionó el código de recuperación, pero presumiblemente se hacen búsquedas de similitud de vectores.
- **¿Tiene metadata tenant?** No.
- **¿Existe riesgo de cross-tenant retrieval?** **SÍ**, si el RAG se utiliza para proporcionar conocimiento específico de cada salón (por ejemplo, tratamientos propios, promociones) y no se filtra por tenant, entonces un salón podría ver el conocimiento de otro. Si el conocimiento es global y compartido (como enciclopedía de belleza), entonces el riesgo es bajo. Se necesita determinar si el conocimiento es tenant-agnóstico o tenant-específico.

Dado que no se vio lógica de filtrado en los servicios de IA inspeccionados (por ejemplo, `geminiService.js`), se asume actualmente que el conocimiento es global.

## 8. ANÁLISIS DE PAYMENTS

Se inspeccionaron las entidades relacionadas con pago:

- `bookings`: contiene `valor_bruto`, `comision_plataforma`, `impuestos_estado`, `pago_neto_prestador`.
- `transactions`: contiene `amount`, `status`, `payment_method`, `external_id`.
- No hay columna `tenant_id` en ninguna de estas tablas.
- Para asociar pagos a un tenant, sería necesario añadir `tenant_id` a `bookings` (y por ende a `transactions` através de la FK) o directamente a `transactions`.

## 9. ALMACENAMIENTO / ARCHIVOS

No se observó código que gestione la subida o almacenamiento directo de archivos (por ejemplo, usando `multer` o similares). Los campos como `foto_url`, `documento_id_url` sugieren que los archivos se almacenan en un servicio externo (probablemente en la nube) y solo se guarda la URL. 

- **¿Existe riesgo de Tenant A → File Tenant B?** **NO EVIDENCE FOUND** en el código inspeccionado, pero se requiere verificar el servicio externo de almacenamiento para asegurar que las URLs no sean predecibles o que el servicio implemente control de acceso por tenant (por ejemplo, usando firmas temporales o políticas de bucket). 

## 10. BACKGROUND JOBS

Se buscó evidencia de cron, workers, queues o tareas programadas:

- No se encontró uso de bibliotecas como `bull`, `agenda`, `node-cron` en `package.json` ni en el código inspeccionado.
- Se observan `setTimeout` en algunos lugares (por ejemplo, en `payBooking` para simular latencia), pero no workers de fondo.

**CONCLUSIÓN**: No se encontró evidencia de background jobs en el código inspeccionado. Si existieran, sería necesario asegurar que trasporten el contexto de tenant (por ejemplo, incluyendo `tenant_id` en el payload del job).

## 11. CACHE

Se encontró configuración de Redis en `backend/src/config/redis.js`. Se usó en algunos servicios (por ejemplo, en servicios de IA se menciona caché de embeddings). 

- **¿Se analizan las claves y contexto tenant?** No se inspeccionó el uso específico de Redis, pero se requiere verificar que las claves de caché incluyan identificadores de tenant (o usuario) para evitar fugas de datos entre tenants mediante caché compartida.

## 12. ANÁLISIS MULTI-BRANCH

No se encontró entidad `sucursal` o `branch` en el esquema. El modelo actual asume un único lugar de operación por profesional (ubicacion en `perfiles_prestador`). 

- **Comparar `tenant_id` únicamente vs. `tenant_id + branch_id`**: Dado que no hay concepto de salón ni de sucursal, la discusión es prematura. Si en el futuro se quisiera soportar múltiples sucursales bajo un mismo negocio, se necesitaría una entidad `sucursal` vinculada al salón y luego decidir si el tenant es el salón o la sucursal. Para el análisis actual, se asume que el tenant representa el salón (negocio) y que cada salón tiene una única ubicación (o que la ubicación es un atributo del salón).

## 13. MODELO RECOMENDADO

**MODELO**: Shared Schema + tenant_id + RLS (Opción B)

**RAZÓN**: 
- Proporciona buen equilibrio entre simplicidad, seguridad y costo.
- El uso de RLS en la base de datos reduce el riesgo de errores en la aplicación que puedan provocar filtración de datos entre tenants.
- Es escalable para el número esperado de salones (decenas a cientos de miles) y permite consultas eficientes con índices en `tenant_id`.
- Aprovecha la infraestructura existente de PostgreSQL sin requerir múltiples bases de datos o esquemas.

**EVIDENCIA**: 
- No existe actualmente `tenant_id` ni RLS; se requiere añadir ambos.
- El proyecto ya usa PostgreSQL y tiene capacidad para ejecutar migraciones y definir políticas.

**VENTAJAS**:
- Aislamiento de datos a nivel de fila garantizado por la base de datos.
- Menor riesgo de errores de aplicación en comparación con solo Shared Schema.
- Consulta única y transacciones simples (no se necesita cambiar de esquema o de base de datos).
- Compatibilidad con herramientas existentes (Sequelize, pgPool) mediante adición de condición `WHERE tenant_id = $`.

**DESVENTAJAS**:
- Requiere migración de datos existentes para poblar `tenant_id`.
- Requiere definición y mantenimiento de políticas RLS.
- Si se comete un error en la política, podría bloquear el acceso legítimo o permitir acceso no autorizado.

**RIESGOS**:
- Error en la definición de políticas RLS que otorgue acceso excesivo o insuficiente.
- Olvido de añadir `tenant_id` a alguna tabla nueva o a alguna query.
- Complejidad operativa en la gestión de políticas (aunque mínima comparada con otras opciones).

**IMPACTO EN CÓDIGO**:
- Se debe revisar y actualizar todas las queries (tanto de Sequelize como de pgPool) para incluir la condición `tenant_id = :tenantId` donde `:tenantId` se obtenga del contexto de autenticación (por ejemplo, mediante un middleware que resuelva el tenant a partir de `req.user.id` y lo adjunte a la request o a la conexión de base de datos).
- Los modelos de Sequelize pueden necesitar un scope global o un hook que añada automáticamente la condición.
- Los servicios que usan `pool.query` deben modificarse para aceptar el parámetro adicional.

**IMPACTO EN DB**:
- Añadir columna `tenant_id` (tipo INTEGER o UUID) a las tablas: `usuarios`, `perfiles_prestador`, `services`, `bookings`, `transactions`, `beauty_knowledge_embeddings` (si el conocimiento es tenant-específico), `user_activity_logs`, `platform_config` (si la configuración es por tenant), y posiblemente otras tablas de auditoría y logs.
- Crear tabla `tenants` con información del salón (id, nombre, etc.).
- Crear políticas RLS para cada tabla afectada: `USING (tenant_id = current_setting('app.tenant_id')::INTEGER)` o similar usando una variable de sesión de PostgreSQL.
- Añadir índices en `tenant_id` para mejorar rendimiento.

**IMPACTO EN SEGURIDAD**:
- Mejora significativa al prevenir acceso accidental a datos de otros tenants mediante errores de aplicación.
- Reduce la superficie de ataque relacionada con Broken Object Level Authorization.

**MIGRACIÓN ESTIMADA**: 
- **Complejidad**: Media-Alta (debido a la necesidad de backfill y definición de políticas).
- **Riesgo**: Medio (si se realiza en un entorno de mantenimiento y se verifican las políticas tras la migración).
- **Esfuerzo relativo**: Alto en términos de planificación y ejecución cuidadosa, pero no requiere cambios arquitectónicos profundos más allá de la adición de la columna y el filtrado.

## 14. CONSIDERACIONES LEGALES

- El aislamiento de datos entre tenants es un requisito implícito de la Ley 1581 de 2012 (protección de datos personales) si se determina que GlowApp actúa como encargado o responsable de los datos de los salones. El modelo propuesto (Shared Schema + tenant_id + RLS) ayuda a cumplir con el deber de seguridad y evitar fugas de datos entre responsables.
- Se requiere validación jurídica externa para determinar si GlowApp es encargado o responsable y, por lo tanto, si el aislamiento de datos es obligatorio. Sin embargo, desde una perspectiva de buena práctica técnica, el aislamiento es recomendable incluso si no se exige legalmente.

## 15. BLOQUEADORES

- Falta de decisión jurídica sobre el rol de GlowApp (encargado vs responsable) que afecta la necesidad y el alcance del aislamiento de datos.
- Necesidad de definir claramente qué constituye un tenant (¿el salón, el profesional, o el usuario?) antes de implementar la columna `tenant_id`.
- Disponibilidad de recursos para realizar la migración de datos y probar las políticas RLS en un entorno de staging antes de producción.

## 16. CONCLUSION

Tras el análisis del código real y la evidencia disponible, se recomienda adoptar el modelo **Shared Schema + tenant_id + RLS** como foundation para multi-tenancy en GlowApp, sujeto a la resolución jurídica correspondiente y a la definición precisa de la entidad tenant.

--- 
Fin del análisis.