# D-004 CONTEXT PACKAGE

## Estrategia de retención de datos para RAG y conocimiento organizacional

### Contexto Actual
- No hay política de retención ni mecanismo de legal hold para datos de RAG (Retrieval-Augmented Generation) y conocimiento organizacional.
- La tabla `beauty_knowledge_embeddings` se dejó con `tenant_id` NULL (GLOBAL) como parte de D-001, lo que implica que los embeddings son compartidos entre todos los tenants.
- No existe tabla `retention_policies` ni trabajo cron para borrado basado en tiempo.
- No hay mecanismo de legal hold para preservar datos cuando sea necesario por requisitos legales o litigios.

### Qué Falta para Decidir
1. Determinación jurídica sobre períodos de retención requeridos por Ley 1581 art. 8 y SIC Circ. 022/2023 para datos personales utilizados en modelos de IA.
2. Definición de mecanismos de legal hold necesarios para preservar datos cuando se requiera por orden judicial, investigación o cumplimiento normativo.
3. Decisión técnica sobre cómo aplicar la retención: por tipo de dato, por antigüedad, por evento, etc.
4. Definición de si la retención aplica a embeddings, chunks, texto original, metadatos, logs de consulta, etc.
5. Decisión sobre cómo manejar el caso GLOBAL RAG: ¿se aplica retención global o por tenant aunque los datos sean compartidos?

### Opciones de Arquitectura
1. **Tabla de Políticas de Retención**
   - Crear tabla `retention_policies` que defina:
     - `id`, `tenant_id` (NULL para políticas globales), `data_type` (ej: 'embeddings', 'chunks', 'raw_text', 'query_logs'), `retention_period_days`, `legal_hold_flag`, `created_at`, `updated_at`.
   - Añadir columna `created_at` o `updated_at` a las tablas relevantes si no existen.
   - Trabajo cron que evalúe las políticas y elimine o anonimice datos vencidos, respetando legal holds.

2. **Mecanismo de Legal Hold**
   - Tabla `legal_holds` que asocie un hold a un conjunto de datos (por ID, por rango de tiempo, por metadata, etc.).
   - El trabajo cron de retención debe saltarse los datos bajo legal hold.
   - Interfaz para crear, modificar y liberar legal holds (posiblemente mediante API protegida).

3. **Estrategia de Borrado**
   - Borrado físico (DELETE) o borrado lógico (marcar como eliminado, anonimización).
   - Para cumplimiento con Ley 1581, puede requerirse borrado seguro o anonimización que haga imposible la reidentificación.
   - Considerar borrado criptográfico si los datos están cifrados.

4. **Integración con RAG**
   - Al generar embeddings o chunks, registrar metadata de creación y tenant_id (aunque sea NULL para GLOBAL).
   - Al consultar RAG, opcionalmente filtrar por fecha si se implementa retención en tiempo de consulta (menos eficiente).
   - Preferir aplicar retención en capa de almacenamiento (trabajo cron).

### Dependencias
- Depende de D-001 (multi-tenancy) porque las políticas de retención pueden ser por tenant o globales.
- No depende de otras decisiones D-xxx directamente, pero se beneficia de tener tenant_id definido correctamente.
- Puede influir en D-009 (política de retención y eliminación de datos genérica) y D-015 (gestión de consentimientos), ya que la retención de datos de IA puede relacionarse con consentimientos para uso de datos en modelos.

### Impacto
- **MEDIO**: Requiere tabla `retention_policies`, trabajo cron de borrado criptográfico o de eliminación, mecanismo de legal hold.
- Cambios necesarios: migraciones para crear tablas, modificaciones al servicio de RAG para registrar timestamps necesarios, creación de trabajo cron, posibles ajustes en la capa de consulta si se quiere aplicar filtros de tiempo.

### Evidencia Disponible en Repositorio
- Patrones de migración de D-001: 
  - `backend/migrations/055_create_tenants_table.sql`
  - `backend/migrations/056_add_tenant_id_to_core_tables.sql`
  - `backend/migrations/057_backfill_tenant_id.sql`
  - `backend/migrations/058_enable_rls_policies.sql`
- Scripts de validación de D-001: `validate_056.js`, `validate_057.js`, `validate_058.js`.
- Patrón de tabla con timestamps: revisar otras tablas en el esquema para ver si ya existen columnas `created_at` y `updated_at` (ej: tabla `tenants` las tiene).
- La tabla `beauty_knowledge_embeddings` actualmente tiene columnas: (asumir basada en conocimiento previo; si no, se puede inspeccionar).
- Trabajo cron existente: revisar `backend/src/crons/` para ejemplos (hay `automaticRetentionCron.js` que podría ser un punto de partida).

### Próximos Pasos Tras Decisión
1. Crear migración para tabla `retention_policies`.
2. Crear migración para tabla `legal_holds` (si se decide separar).
3. Añadir columnas de timestamp (`created_at`, `updated_at`) a tablas que las falten y sean relevantes para retención (ej: `beauty_knowledge_embeddings` si no las tiene).
4. Crear servicio o trabajo cron que ejecute periódicamente:
   - Lea las políticas de retención.
   - Para cada política, identifique datos vencidos (comparando `created_at` o `updated_at` con `retention_period_days`).
   - Excluya datos bajo legal hold activo.
   - Ejecute la acción de retención (eliminación física, anonimización, etc.).
   - Loggee las acciones para auditoría.
5. Crear API para gestionar políticas de retención y legal holds (probablemente protegida por roles de admin o legal).
6. Actualizar documentación y pruebas.
7. Validar que el mecanismo funcione correctamente y no elimine datos por error.

### Estado Actual de Tabla de Conocimiento (verificar)
Se puede inspeccionar la tabla `beauty_knowledge_embeddings` para ver su estructura actual y decidir qué columnas añadir.

### Notas de Cumplimiento
- Ley 1581 de Protección de Datos Personales, artículo 8: establece el deber de suprimir o destruir los datos cuando sean innecesarios o pertinentes para el fin del tratamiento.
- SIC Circular 022/2023: proporciona lineamientos sobre el tratamiento de datos personales en sistemas de inteligencia artificial.
- El mecanismo de retención debe asegurar que los datos no se conserven más tiempo del necesario para el fin legítimo del tratamiento.
- El legal hold permite una excepción temporal cuando se requiere preservar datos por una obligación legal (ej: orden judicial, investigación).

---
*Este paquete se preparó para apoyar la toma de decisión del Director de Arquitectura + Legal sobre D-004.*
*Fecha de preparación: $(date)*