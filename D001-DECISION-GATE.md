# D001-DECISION-GATE.md

# D-001 MULTI-TENANCY DECISION GATE

## 1. TASK
Ejecutar el análisis técnico de multi-tenancy (D-001) según la directiva del Director, proporcionando evidencia real del código existente, analizando las cuatro alternativas y recomendando una arquitectura, sin implementar nada.

## 2. SCOPE
- Análisis exclusivo de D-001: Estrategia de multi‑tenancy (shared DB/shared schema + RLS vs. separate schema vs. DB por tenant).
- Inspección de código real: backend/schema.sql, backend/migrations/, backend/src/, frontend/, tests/, configuración.
- No se realizó implementación, modificaciones de código, esquemas, APIs, ni instalación de dependencias.
- Se entregó un análisis basado en evidencia real, sin supposiciones ni inventos.

## 3. ACTUAL CODEBASE INSPECTED
Se verificaron los siguientes componentes:
- **Backend**: schema.sql, migraciones, controladores (booking, service, provider, auth, etc.), servicios, modelos, configuración (db, redis, jwt, logger).
- **Frontend**: estructura de directorios bajo frontend/ (se confirmó existencia, pero no se inspeccionó código Flutter en detalle).
- **Tests**: pruebas unitarias y de integración en backend/tests/.
- **Configuración**: archivos .js en backend/src/config/.

## 4. CURRENT TENANCY STATE
- **No existe concepto de tenant explícito** en el modelo de datos.
- **No hay columna tenant_id, organization_id, business_id o salon_id** en ninguna tabla.
- La entidad más cercana a un salón es `perfiles_prestador` (vinculada a `usuarios`), la cual puede representar un profesional independiente o un salón si se asume relación uno-a-uno.
- **Todas las tablas están compartidas en un único esquema público** sin particionamiento.
- El acceso a datos en los endpoints inspeccionados se filtra por `req.user.id` (usuario autenticado), lo que actualmente proporciona un aislamiento implícito por usuario (no por salón).

## 5. CURRENT DATA MODEL
Verificado en `/c/beauty-app/backend/schema.sql`:
- Tablas principales: `usuarios`, `perfiles_prestador`, `services`, `bookings`, `transactions`, `beauty_knowledge_embeddings`, `user_activity_logs`, `platform_config`, etc.
- Relaciones: 
  - `usuarios.id` ←→ `perfiles_prestador.id` (one-to-one, rol = 'PRESTADOR')
  - `perfiles_prestador.id` ←→ `services.provider_id`
  - `usuarios.id` ←→ `bookings.client_id`
  - `perfiles_prestador.id` ←←→ `bookings.provider_id`
  - `bookings.id` ←→ `transactions.booking_id`
- No hay tablas para `tenants`, `salones` ni columnas de identificador de agrupación.

## 6. CURRENT AUTHORIZATION MODEL
- **Autenticación**: JWT verificado por `authMiddleware`, que adjunta `req.user`.
- **Autorización**: 
  - Verificaciones de rol (p. ej., `req.user.role === 'provider'` o `'PRESTADOR'`) en controladores.
  - Verificaciones de ownership explícitas en queries (p. ej., `WHERE provider_id = $1` con `$1 = req.user.id`).
  - No hay verificaciones de pertenencia a una entidad de salón más allá del `user_id`.

## 7. CURRENT API ACCESS MODEL
Los endpoints bajo `backend/src/routes/` filtran principalmente por el ID del usuario autenticado:
- `GET /bookings/provider` → `provider_id = req.user.id`
- `GET /bookings/client` → `client_id = req.user.id`
- `GET /services/provider` → `provider_id = req.user.id`
- Endpoints de pago usan el `booking_id` derivado de la reserva, que a su vez está vinculado al usuario.
- **No se observaron endpoints que acepten IDs arbitrarios sin validación de propiedad** en las rutas inspeccionadas (se requiere auditoría completa para confirmar).

## 8. CURRENT PAYMENT MODEL
- `bookings`: contiene `valor_bruto`, `comision_plataforma`, `impuestos_estado`, `pago_neto_prestador`.
- `transactions`: contiene `amount`, `status`, `payment_method`, `external_id` (referencia al PSP).
- El flujo de pago: cliente paga → se registra en `transactions` vinculado a la reserva → se actualiza el estado de la reserva.
- **No hay asociación explícita a un salón más allá de la reserva y el proveedor.**

## 9. CURRENT RAG MODEL
- Tabla `beauty_knowledge_embeddings` (ver schema.sql líneas 282-291).
- Almacena conocimiento general de belleza (título, categoría, contenido, embedding de 768 dimensiones).
- **No tiene columna tenant_id ni ningún identificador de organización.**
- Se asume actualmente que el conocimiento es global y compartido (no específico por salón), pero se requiere validar el uso previsto.

## 10. CURRENT STORAGE MODEL
- No se observó código de subida o almacenamiento directo de archivos.
- Campos como `foto_url`, `documento_id_url` sugieren almacenamiento externo (probablemente en la nube) con solo URLs guardadas.
- **No se vio evidencia de almacenamiento local de archivos** en el código inspeccionado.
- Riesgo de fuga entre tenants por almacenamiento externo **requiere verificación de la configuración del servicio de almacenamiento** (no inspeccionado en esta fase).

## 11. CURRENT CACHE MODEL
- Redis configurado en `/c/beauty-app/backend/src/config/redis.js`.
- Se usó en algunos servicios (por ejemplo, servicios de IA mencionan caché de embeddings).
- **No se inspectó el uso específico de Redis**, pero se requiere verificar que las claves de caché incluyan identificadores de tenant (o usuario) para evitar fugas mediante caché compartida.

## 12. CURRENT BACKGROUND JOB MODEL
- **No se encontró evidencia de sistemas de colas** (Bull, Agenda, node-cron) ni de workers en el código inspeccionado.
- Se observan `setTimeout` para simulaciones de latencia, pero no workers de fondo.
- Si se introducen trabajadores en el futuro, deberán ser diseñados para trasportar contexto de tenant.

## 13. MULTI-BRANCH ANALYSIS
- No se encontró entidad `sucursal` o `branch` en el esquema.
- El modelo actual asume un único lugar de operación por profesional (ubicacion en `perfiles_prestador`).
- La discusión entre `tenant_id` únicamente vs. `tenant_id + branch_id` es prematura sin un concepto definido de salón o sucursal.
- Para el análisis actual, se asume que el tenant representa el salón (negocio) y que cada salón tiene una ubicación (o que la ubicación es un atributo del salón).

## 14. ARCHITECTURE A: Shared Schema + tenant_id
- **Descripción**: Añadir columna tenant_id a tablas y filtrar en la aplicación.
- **Evidencia**: No existe tenant_id.
- **Ventajas**: Simple, usa infraestructura existente, buen punto de partida.
- **Desventajas**: Depende de correcto filtrado en aplicación (riesgo de olvido).
- **Impacto en código**: Revisar todas las queries para añadir condición `tenant_id = :tenantId`.
- **Impacto en DB**: Añadir columna tenant_id a tablas de negocio, crear tabla tenants, backfill de datos existentes.
- **Impacto en seguridad**: Medio (depende de aplicación).
- **Migración estimada**: Media (requiere migración y actualización de queries).

## 15. ARCHITECTURE B: Shared Schema + tenant_id + RLS
- **Descripción**: Como A, pero añadir políticas de Row Level Security en PostgreSQL.
- **Evidencia**: No existe tenant_id ni RLS.
- **Ventajas**: La BD enforca el filtrado, reduciendo riesgo de error de aplicación.
- **Desventajas**: Requiere definir y mantener políticas RLS.
- **Impacto en código**: Similar a A, plus posible uso de variables de sesión para establecer tenant_id en la BD.
- **Impacto en DB**: Igual que A, plus creación de políticas RLS para cada tabla afectada.
- **Impacto en seguridad**: Alto (aislamiento garantizado a nivel de fila).
- **Migración estimada**: Media-Alta (debido a definición y prueba de políticas).

## 16. ARCHITECTURE C: Schema-per-tenant
- **Descripción**: Cada tenant tiene su propio esquema dentro de la misma BD.
- **Evidencia**: No existen esquemas separados.
- **Ventajas**: Buen aislamiento a nivel de esquema.
- **Desventajas**: Complejidad en gestión de esquemas, límites en número de esquemas, backups y migraciones más complejos.
- **Impacto en código**: Requiere lógica de cambio de esquema (SET search_path o similares).
- **Impacto en DB**: Migración de datos a esquemas separados.
- **Impacto en seguridad**: Bueno (depende de correcto enrutamiento).
- **Migración estimada**: Media-Alta (lógica de enrutamiento y migración por esquema).

## 17. ARCHITECTURE D: Database-per-tenant
- **Descripción**: Cada tenant tiene su propia base de datos física.
- **Evidencia**: Solo una BD configurada.
- **Ventajas**: Máximo aislamiento a nivel de instancia.
- **Desventajas**: Alto overhead operativo (múltiples conexiones, backups, mantenimiento).
- **Impacto en código**: Requiere múltiples pools de conexión y selección dinámica de BD.
- **Impacto en DB**: Creación de una BD por tenant y migración de datos.
- **Impacto en seguridad**: Muy alto.
- **Migración estimada**: Alta (gestionar múltiples pools, migraciones por DB).

## 18. COMPARISON
Ver documento completo en `/c/beauty-app/D001-MULTITENANCY-COMPARISON.md`.
Resumen: La opción B (Shared Schema + tenant_id + RLS) ofrece el mejor equilibrio entre simplicidad, seguridad y costo para el escenario esperado de GlowApp (SaaS B2B para salones de belleza).

## 19. SECURITY THREAT MAP
Ver documento completo en `/c/beauty-app/D001-SECURITY-THREAT-MAP.md`.
Principales amenazas latentes debido a ausencia de tenant_id:
- Missing tenant filter (todas las queries actuales carecen de filtro).
- Cross-tenant RAG retrieval (la tabla de embeddings lacks tenant_id).
- Riesgos de caché, archivos externos y background jobs requieren verificación adicional.

## 20. TENANCY IMPACT MAP
Ver documento completo en `/c/beauty-app/D001-TENANCY-IMPACT-MAP.md`.
Componentes con alto impacto: esquema de BD, migraciones, consultas, transacciones financieras, agenda/reservas, perfiles de prestador, servicios, reportes y analíticas.

## 21. RECOMMENDED ARCHITECTURE
Shared Schema + tenant_id + RLS (Opción B)
- **Razón**: Equilibrio entre simplicidad, seguridad y costo; la BD enforca el filtrado reduciendo riesgo de error de aplicación.
- **Evidencia**: No existe tenant_id ni RLS; se requiere añadir ambos. PostgreSQL soporta esta técnica nativamente.
- **Ventajas**: Aislamiento de datos a nivel de fila garantizado por la BD, menor riesgo de errores de aplicación, compatibilidad con herramientas existentes.
- **Desventajas**: Requiere migración de datos, definición y mantenimiento de políticas RLS.
- **Riesgos**: Error en políticas RLS, olvido de añadir tenant_id a alguna tabla o query.
- **Impacto en código**: Revisar todas las queries (ORM y crudas) para incluir condición tenant_id.
- **Impacto en DB**: Añadir tenant_id a tablas de negocio, crear tabla tenants, crear políticas RLS, añadir índices en tenant_id.
- **Impacto en seguridad**: Mejora significativa al prevenir acceso accidental a datos de otros tenants.
- **Migración estimada**: Media-Alta (debido a backfill y definición de políticas, pero factible con planeación cuidadosa).

## 22. LEGAL CONSIDERATIONS
- El aislamiento de datos entre tenants es un requisito implícito de la Ley 1581 de 2012 si se determina que GlowApp actúa como encargado o responsable de los datos de los salones.
- El modelo propuesto ayuda a cumplir con el deber de seguridad y evitar fugas de datos entre responsables.
- Se requiere validación jurídica externa para determinar si GlowApp es encargado o responsable y, por lo tanto, si el aislamiento de datos es obligatorio. Sin embargo, desde una perspectiva de buena práctica técnica, el aislamiento es recomendable incluso si no se exige legalmente.

## 23. RISKS
- **Técnico**: Errores en la migración de datos o en las consultas pueden provocar pérdida o corrupción de información.
- **Operacional**: Downtime durante la aplicación de migraciones si no se hace de forma adecuada.
- **Legal**: Incumplimiento de la Ley 1581 si los datos de distintos tenants no están adecuadamente aislados (pendiente de validación externa).
- **Seguridad**: Fugas de datos entre tenants si la implementación de RLS o separación es defectuosa.
- **Operacional**: Complejidad en la definición y aplicación correcta de políticas RLS.

## 24. BLOCKERS
- Falta de decisión jurídica sobre el rol de GlowApp (encargado vs responsable) que afecta la necesidad y el alcance del aislamiento de datos.
- Necesidad de definir claramente qué constituye un tenant (¿el salón, el profesional, o el usuario?) antes de implementar la columna tenant_id.
- Disponibilidad de recursos para realizar la migración de datos y probar las políticas RLS en un entorno de staging antes de producción.

## 25. FILES CREATED
- `/c/beauty-app/D001-MULTITENANCY-ANALYSIS.md`
- `/c/beauty-app/D001-MULTITENANCY-COMPARISON.md`
- `/c/beauty-app/D001-TENANCY-IMPACT-MAP.md`
- `/c/beauty-app/D001-SECURITY-THREAT-MAP.md`
- `/c/beauty-app/D001-DECISION-GATE.md`

## 26. FILES MODIFIED
Ninguno (no se modificó código fuente, esquema, configuración, ni se instalaron dependencias).

## 27. CODE CHANGES
Ninguno.

## 28. DATABASE CHANGES
Ninguno (no se ejecutaron migraciones ni se alteró el esquema).

## 29. TESTS
No se ejecutaron ni se crearon nuevos tests durante esta fase. Los tests existentes permanecen sin cambios.

## 30. FINAL GATE
**🟢 D001 DECISION READY**
El análisis de D-001 está completo y basado en evidencia real del código existente. Se ha proporcionado una recomendación técnica fundamentada (Shared Schema + tenant_id + RLS) con sus ventajas, desventajas, riesgos y impacto estimado. 

El trabajo de descubrimiento y análisis ha sido realizado sin implementar nada, respetando la directiva de solo lectura y análisis.

El Director ahora cuenta con la información necesaria para tomar una decisión sobre la estrategia de multi-tenancy.

--- 
Fin del gate.