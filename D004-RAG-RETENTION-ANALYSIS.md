# D004-RAG-RETENTION-ANALYSIS.md

## Analysis of RAG Retention Requirements for GlowApp

### 1. Current State of RAG in GlowApp

**HECHO:** GlowApp utiliza un sistema RAG (Retrieval-Augmented Generation) para recuperar conocimiento técnico de belleza y augmentar los prompts de los modelos de lenguaje.

**EVIDENCIA:** 
- Existe un servicio RAG en `/backend/src/services/ragService.js` que interactúa con la tabla `beauty_knowledge_embeddings`.
- El servicio genera embeddings utilizando la API de NVIDIA y realiza búsquedas vectoriales contra `beauty_knowledge_embeddings`.
- Según el informe de implementación de D-001 (`D-001_IMPLEMENTATION_COMPLETE.report`), la tabla `beauty_knowledge_embeddings` tiene una columna `tenant_id` que se dejó NULL (GLOBAL RAG).

**INTERPRETACIÓN:** 
El RAG de GlowApp está diseñado para ser global (compartido entre todos los tenants) según la decisión tomada en D-001. Esto implica que el conocimiento técnico de belleza es común a todos los salones y no está particionado por tenant.

**RIESGO:** 
Si se requiere retención diferencial por tenant (por ejemplo, por requisitos legales de eliminación de datos específicos de un tenant), el enfoque global actual podría no ser suficiente, ya que eliminar datos de un tenant podría requerir reconstruir el índice global o segregar el conocimiento.

### 2. Requisitos de Retención para RAG Global

**HECHO:** No existe actualmente una política de retención ni mecanismo de eliminación para los datos en `beauty_knowledge_embeddings`.

**EVIDENCIA:**
- No se encontró ninguna tabla de políticas de retención en el esquema (búsqueda de tablas relacionadas con retención no mostró resultados).
- El servicio RAG no incluye lógica para eliminar o anonimizar embeddings basándose en tiempo o eventos.
- El informe D-001 no menciona mecanismos de retención para la tabla de embeddings.

**INTERPRETACIÓN:**
Los embeddings y el conocimiento asociado se conservan indefinidamente hasta una intervención manual. Esto representa un riesgo de cumplimiento con regulaciones como la Ley 1581 (artículo 8) que requiere suprimir o destruir los datos cuando sean innecesarios o pertinentes para el fin del tratamiento.

**RIESGO:**
- No cumplimiento con obligaciones legales de supresión de datos.
- Acumulación indefinida de datos que podría aumentar costos de almacenamiento y degradar el rendimiento de búsqueda con el tiempo.
- Dificultad para atender solicitudes de eliminación de datos (derecho al olvido) si se vinculan a un tenant específico.

### 3. Conocimiento Organizacional Específico de Cada Tenant

**HECHO:** Actualmente, no hay evidencia de que GlowApp almacene conocimiento organizacional específico de cada tenant separado del RAG global.

**EVIDENCIA:**
- No se identificaron tablas o columnas que indiquen almacenamiento de documentos privados por tenant fuera de la tabla global de embeddings.
- Los servicios de ingestión (como `seed_beauty_knowledge_v3.js`) parecen cargar conocimiento de belleza general, no específico de salones.
- La arquitectura descrita en D-001 enfatiza el RAG global y no menciona particionamiento por tenant para conocimiento técnico.

**INTERPRETACIÓN:**
Si los salones requieren mantener protocolos internos, técnicas propietarias o conocimiento que no deba compartirse con otros tenants, el actual enfoque global no lo soporta. Esto obliga a que todo el conocimiento se comparta o que se implemente una capa de filtrado adicional en tiempo de consulta (por ejemplo, mediante metadata de tenant en los embeddings).

**RIESGO:**
- Fuga accidental de conocimiento específico de un tenant al RAG global si se ingiere sin los controles adecuados.
- Incapacidad para ofrecer valor diferencial basado en conocimiento privado si todo se mezcla en el índice global.
- Complejidad para eliminar conocimiento de un tenant específico sin afectar al índice global.

### 4. Embeddings, Documentos Fuente y Información Derivada

**HECHO:** Los embeddings son representaciones vectoriales de documentos fuente, y su retención está vinculada a la retención de los documentos originales y su metadata.

**EVIDENCIA:**
- El servicio RAG genera embeddings a partir de texto de entrada (consultas y documentos indexados).
- La tabla `beauty_knowledge_embeddings` probablemente almacene: id, embedding (vector), título, contenido, categoría, y posiblemente metadata como `skin_type`, `ingredients`, etc. (inferido de los filtros en `buildMetadataFilters`).
- No hay evidencia de almacenamiento separado de documentos fuente originales o de un sistema de versionado de embeddings.

**INTERPRETACIÓN:**
Los embeddings son derivados y su utilidad depende de la disponibilidad y corrección de los documentos fuente. Si se eliminan los documentos fuente, los embeddings podrían volverse obsoletos o engañosos si no se actualizan o eliminan correspondiente.

**RIESGO:**
- Incoherencia entre embeddings y documentos fuente si se actualizan unos y no otros.
- Dificultad para rastrear qué documento originó un embedding específico (falta de trazabilidad).
- Riesgo de almacenar embeddings derivados de datos que deberían haber sido eliminados (por ejemplo, si un tenant elimina un documento, su embedding permanece en el índice global).

### 5. Memorias/Conocimiento Generado por Interacción

**HECHO:** No hay evidencia de que GlowApp almacene o utilice conocimientos generados por interacciones de usuarios (como aprendizaje a partir de conversaciones) en su sistema RAG.

**EVIDENCIA:**
- No se identificaron servicios o tablas para almacenar conversaciones, extraer conocimiento de ellas o re-ingestarlo en el RAG.
- Los servicios de IA parece enfocarse en la generación de respuestas basadas en el RAG existente, no en retroalimentar el conocimiento.
- No hay métricas o logs que indiquen un ciclo de aprendizaje continuo del conocimiento a partir de las interacciones.

**INTERPRETACIÓN:**
El conocimiento de GlowApp es estático (actualizado únicamente mediante ingestión manual o semillas predefinidas) y no evoluciona con el uso. Esto limita la capacidad del sistema para adaptarse a tendencias nuevas o a requerimientos específicos de los salones.

**RIESGO:**
- El conocimiento se vuelve obsoleto con el tiempo.
- Se pierde la oportunidad de mejorar el servicio basado en la experiencia real de los usuarios.
- Posible insatisfacción si el RAG no responde adecuanamente a preguntas novas o específicas de un salón.

### 6. Metadatos Asociados y Historial para Trazabilidad

**HECHO:** Los metadatos actuales en `beauty_knowledge_embeddings` incluyen campos como categoría, y posiblemente `skin_type`, `ingredients`, `contraindications` (basado en los filtros del servicio RAG).

**EVIDENCIA:**
- En `ragService.js`, la función `buildMetadataFilters` filtra por `skin_type`, `category`, `contraindications` y `ingredients`.
- Esto sugiere que la tabla tiene columnas para estos campos (o al menos se asume que existen en el contenido que se busca).
- No hay evidencia de campos de auditoría como `created_at`, `updated_at`, `created_by`, o `version`.

**INTERPRETACIÓN:**
Los metadatos permiten filtrado temático pero no trazabilidad completa (cuándo se añadió, quién lo añadió, versiones). Esto dificulta la gobernanza, la auditoría y la aplicación de políticas de retención basadas en la edad o el origen.

**RIESGO:**
- Imposibilidad de saber cuándo se añadió un fragmento de conocimiento, lo que complica la aplicación de retención basada en tiempo.
- Dificultad para atribuir conocimiento a una fuente específica para fines de responsabilidad o actualización.
- Riesgo de no poder cumplir con solicitudes de eliminación que dependan de la fecha de incorporación.

### 7. Conclusión Preliminar

El actual sistema RAG de GlowApp es global, sin particionamiento por tenant, y carece de mecanismos de retención, eliminación o versionado. Para cumplir con requisitos legales y operativos, se necesita:

1. Definir qué conocimiento es realmente global vs. tenant-specific.
2. Implementar una estrategia de retención que permita la eliminación o anonimización de datos basada en tiempo, eventos o solicitudes.
3. Asegurar que el conocimiento tenant-specific no se filtre al RAG global.
4. Considerar el conocimiento generado por interacciones y si debe ser retenido, anonimizado o excluido del RAG.
5. Añadir metadatos de trazabilidad (timestamps, origen) para habilitare políticas de retención informadas.

Los siguientes documentos abordarán estas áreas con más detalle y propondrán opciones arquitectónicas.

---
*Este análisis se basa en la evidencia disponible en el repositorio y en los informes de implementación previos.*
*No se ha modificado código, base de datos ni configuración durante este análisis.*