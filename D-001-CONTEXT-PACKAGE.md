# D-001 CONTEXT PACKAGE

## Estrategia de multi‑tenancy (shared DB/shared schema + RLS vs. separate schema vs. DB por tenant)

### Contexto Actual
- Esquema actual NO tiene columna `tenant_id` en tablas core
- Se requiere decisión de arquitectura para aislamiento de datos entre salones
- Impacta: backend, BD, APIs, infraestructura, seguridad, tenancy, IA/RAG, pagos, observabilidad

### Qué Falta para Decidir
1. Determinación jurídica sobre si GlowApp actúa como responsable o encargado de datos bajo Ley 1581
2. Definición técnica específica de la estrategia (RLS vs esquemas separados vs BD física)

### Opciones de Arquitectura
1. **Shared DB + Shared Schema + RLS**
   - Una base de datos, un esquema, tablas compartidas
   - Aislamiento mediante Row Level Security (políticas de PostgreSQL)
   - Requiere: migraciones para añadir tenant_id, habilitar RLS, crear políticas
   - Ventaja: simplicidad operativa, backup/restore único
   - Desventaja: riesgo de fuga si políticas mal configuradas

2. **Separate Schemas (Mismo DB)**
   - Una base de datos, esquemas diferentes por tenant (ej: tenant1, tenant2)
   - Misma estructura de tablas en cada esquema
   - Requiere: migraciones para crear esquemas, search_path dinámico
   - Ventaja: buen aislamiento, capacidad de tuning por tenant
   - Desventaja: complejidad en migrations y queries

3. **Separate Databases (DB física por tenant)**
   - Base de datos diferente por completo por tenant
   - Requiere: pool de conexiones dinámico, creación automática de DB
   - Ventaja: máximo aislamiento, independencia total
   - Desventaja: complejidad operativa, mayor consumo de recursos

### Dependencias Técnicas
- No depende de ninguna otra decisión D-xxx (es fundamental)
- Habilita: D-004, D-005, D-006, D-007, D-008, D-009, D-010, D-011, D-012, D-014, D-015
- D-002 ya se implementó con suposiciones de tenant_id (por eso se beneficia)

### Archivos Preparados en Repositorio
- `backend/migrations/056_add_tenant_id_to_core_tables.sql`: Añade tenant_id a tablas core
- `backend/migrations/057_backfill_tenant_id.sql`: Backfill de datos existentes
- `backend/migrations/058_enable_rls_policies.sql`: Habilita RLS y crea políticas
- `backend/check_tenant.js`: Script para verificar estado actual de tenant_id
- Patrón de implementación: `src/controllers/workforceController.js` (filtrado por tenant_id)

### Impacto de la Decisión
- **ALTO**: Requiere migraciones, cambios de esquema, afecta todos los componentes de negocio
- Cambios necesarios en: modelos, controladores, servicios, queries, tests
- Necesita actualización de documentación y procedimientos de deployment

### Próximos Pasos Tras Decisión
1. Ejecutar migraciones preparadas (056, 057, 058 según opción elegida)
2. Actualizar todos los modelos para incluir tenant_id donde corresponda
3. Modificar controladores y servicios para filtrar por tenant_id
4. Verificar que las políticas RLS (si se elige) funcionan correctamente
5. Actualizar tests para reflejar el nuevo comportamiento
6. Ejecutar suite completa de pruebas para verificar no regresiones
7. Documentar la decisión y procedimientos operativos

### Estado Actual de Tenant_ID (verificado)
Ejecución de `backend/check_tenant.js` muestra:
- Tabla `tenants`: 2 registros (id 1 y 2)
- Tablas con columna tenant_id: usuarios, servicios, bookings, sos_alerts, user_activity_logs, nail_tryon_jobs, messages, portfolio_items, transactions, reviews, perfiles_prestador (algunas no existen aún)
- En `usuarios`: 3 filas, todas con tenant_id = 2 (no nulo)
- En otras tablas: generalmente 0 filas o tenant_id nulo (porque están vacías)

Esto muestra que la columna tenant_id existe en algunas tablas pero necesita ser estandarizada y poblada correctamente según la estrategia elegida.

---
*Este paquete se preparó para apoyar la toma de decisión del Director de Arquitectura sobre D-001.*
*Fecha de preparación: $(date)*