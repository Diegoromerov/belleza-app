# LEGAL-ARCHITECTURAL-VALIDATION.md

# VALIDACIÓN JURÍDICA Y ARQUITECTÓNICA DE DECISIONES D-001 → D-015

## METODOLOGÍA
Se intentó verificar jurídicamente cada decisión utilizando fuentes oficiales y verificables (DIAN, Ministerio de Hacienda, SUIN-JURISCOL, Superintendencia de Industria y Comercio, Congreso de Colombia, normativa oficial vigente). Debido a la falta de configuración de la herramienta de búsqueda web en el entorno, no fue posible acceder a fuentes externas para confirmar vigencia, interpretación o aplicación de normas. Por lo tanto, todas las validaciones jurídicas externas se marcaron como `REQUIRES LEGAL COUNSEL` o `UNVERIFIED`.

## RESULTADOS POR DECISIÓN

### D-001 — Estrategia de multi‑tenancy
- **LEGAL STATUS**: UNVERIFIED (requiere verificación externa de Ley 1581 art. 7, 8, 10 y SIC Circ. 022/2023 respecto al aislamiento de datos entre responsables/encargados).
- **ARCHITECTURAL CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Si se determina que GlowApp es encargado o responsable de datos de salones, se requiere aislamiento técnico robusto (tenant_id + RLS o esquemas separados) para evitar fugas de datos entre tenants.
- **IMPLEMENTATION CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Requiere migraciones para añadir tenant_id a tablas de negocio, crear tabla tenants, posible implementación de RLS, actualización de consultas y repositorios.

### D-002 — Alcance de la oferta de fuerza laboral
- **LEGAL STATUS**: UNVERIFIED (requiere verificación externa de legislación laboral colombiana, notamment Código Sustantivo del Trabajo, para determinar si ofrecer funcionalidades de nómina implica asumir responsabilidades de empleador).
- **ARCHITECTURAL CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Si se determina que GlowApp sería considerado empleador o encargado de datos laborales, se requerirían controles adicionales de seguridad y consentimiento para datos sensibles laborales.
- **IMPLEMENTATION CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Requeriría nuevos servicios, tablas y UI para gestión de fuerza laboral (nómina, empleados, ausencias, capacitaciones).

### D-003 — Modelo de responsabilidad para facturación electrónica futura
- **LEGAL STATUS**: NOT APPLICABLE EN FASE 1 (decisión futura prohibida en fase 1).
- **ARCHITECTURAL CONSEQUENCE**: NINGUNO EN FASE 1 (se mantiene la prohibición de facturación electrónica).
- **IMPLEMENTATION CONSEQUENCE**: NINGUNO EN FASE 1.

### D-004 — Estrategia de retención de datos para RAG y conocimiento organizacional
- **LEGAL STATUS**: REQUIRES LEGAL COUNSEL (depende de Ley 1581 art. 8 sobre conservación y supresión, SIC Circ. 022/2023 sobre datos sensibles en IA, y posible aplicación de Ley 2080/2021 si se confirma vigencia).
- **ARCHITECTURAL CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Define cuánto tiempo pueden retenerse embeddings, chunks y datos de conocimiento utilizados por modelos de IA, y qué mecanismos de legal hold son necesarios.
- **IMPLEMENTATION CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Requiere tabla `retention_policies`, trabajo cron de borrado criptográfico, mecanismo de legal hold, posiblemente tablas de logs de eliminación.

### D-005 — Definir el modelo de comisión y su tratamiento contable (ingreso de GlowApp) y si se aplicará IVA o retención en la fuente
- **LEGAL STATUS**: REQUIRES LEGAL COUNSEL (depende de normativa tributaria colombiana (Estatuto Tributario), Leyes de Industria y Comercio, y posibles regulaciones de establecimientos de pago (Ley 527/1999) para determinar si GlowApp actúa como responsable, encargado o intermediario en el manejo de fondos).
- **ARCHITECTURAL CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Determina cómo se reconoce el ingreso de GlowApp y qué retenciones o IVA aplican.
- **IMPLEMENTATION CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Requiere ajustes en la lógica de cálculo de comisión (en trigger o servicio de pagos), posible nueva tabla o columna para registrar tipo de comisión, actualización de `platform_config`.

### D-006 — Elegibilidad para usar el fiscal adapter (regímenes, montos)
- **LEGAL STATUS**: REQUIRES LEGAL COUNSEL (depende de normativa DIAN sobre quién está obligado a facturar electrónicamente, regímenes especiales, y resolución DIAN 000042/2020 o similar).
- **ARCHITECTURAL CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Define qué salones pueden activar el adapter basándose en su régimen tributario y volumen de facturación.
- **IMPLEMENTATION CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Requiere definición de criterios de activación del fiscal adapter, posible tabla o columna para registrar elegibilidad por salón.

### D-007 — Selección de proveedor de pagos alternativos o expansión más allá de NEQUI/Wompi (tarjeta, PSE, efectivo)
- **LEGAL STATUS**: REQUIRES LEGAL COUNSEL (depende de normativa sobre establecimientos de pago (Ley 527/1999), estándares de seguridad como PCI DSS, y regulaciones de los proveedores de pago).
- **ARCHITECTURAL CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Amplía las opciones de pago disponibles para los clientes de los salones.
- **IMPLEMENTATION CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Requiere abstracción del servicio de pagos para soportar múltiples proveedores, posible nueva tabla o columna para `payment_method` ampliada, UI de selección de métodos.

### D-008 — Definir niveles de servicio y acuerdos de disponibilidad (uptime, ventanas de mantenimiento, tiempo de respuesta de soporte)
- **LEGAL STATUS**: LEGAL STATUS INTERNO VERIFICABLE (no depende de normativa externa específica; es una decisión de producto y operacional).
- **ARCHITECTURAL CONSEQUENCE**: Define las metas de desempeño que la plataforma debe cumplir para generar confianza en los salones.
- **IMPLEMENTATION CONSEQUENCE**: Requiere definición de SLA, implementación de monitoreo de salud, métricas de disponibilidad y tiempos de respuesta, posiblemente UI de estado del servicio.

### D-009 — Establecer política de retención y eliminación de datos (definir períodos por tipo de dato, mecanismo de legal hold)
- **LEGAL STATUS**: REQUIRES LEGAL COUNSEL (depende de Ley 1581 art. 8 sobre conservación y supresión de datos personales).
- **ARCHITECTURAL CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Define los períodos de retención por tipo de dato y el mecanismo de legal hold para preservar datos cuando sea necesario por requisitos legales o litigios.
- **IMPLEMENTATION CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Requiere tabla `retention_policies`, trabajo cron de borrado criptográfico, mecanismo de legal hold.

### D-010 — Definir reglas de activación del fiscal adapter (cuándo un salón debe usar facturación electrónica vía adapter)
- **LEGAL STATUS**: REQUIRES LEGAL COUNSEL (depende de normativa DIAN sobre facturación electrónica obligatoria, resolución DIAN 000042/2020 y similares, y Ley 2080/2021 si se confirma vigencia).
- **ARCHITECTURAL CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Define las reglas concretas que determinen cuándo un salón debe activar el fiscal adapter.
- **IMPLEMENTATION CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Requiere servicio o módulo que evalúe las reglas de activación y gestione el estado del adapter por salón.

### D-011 — Seleccionar proveedor de pagos alternativos o expansión más allá de NEQUI/Wompi (tarjeta, PSE, efectivo) y definir lógica de enrutamiento
- **LEGAL STATUS**: REQUIRES LEGAL COUNSEL (depende de normativa sobre establecimientos de pago (Ley 527/1999), estándares de seguridad como PCI DSS, y regulaciones de los proveedores de pago).
- **ARCHITECTURAL CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Determina cómo se dirige cada transacción de pago al proveedor apropiado.
- **IMPLEMENTATION CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Requiere capa de enrutamiento que seleccione proveedor basado en método, monto, región, etc., posible tabla para almacenar decisión de enrutamiento por transacción.

### D-012 — Establecer política de uso de IA / RAG (filtrado de datos sensibles, registro de interacciones, opt‑out de uso de datos para mejora de modelos)
- **LEGAL STATUS**: REQUIRES LEGAL COUNSEL (depende de Ley 1581 art. 10 sobre deber de seguridad y SIC Circ. 022/2023 sobre tratamiento de datos personales en sistemas de información).
- **ARCHITECTURAL CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Define cómo se filtran o anonimizan datos sensibles antes de enviar a LLMs externos, y cómo se registran las interacciones para auditoría.
- **IMPLEMENTATION CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Requiere middleware o servicio que filtre o anonimice datos sensibles antes de enviarlos a LLMs externos, y que registre las interacciones.

### D-013 — Aprobar el catálogo de funciones permitidas en fase 1 (ver sección 22 HARD BOUNDARY MATRIX)
- **LEGAL STATUS**: APROBADO (ya aprobado en informe de fase 1.5.11, no requiere nueva decisión jurídica).
- **ARCHITECTURAL CONSEQUENCE**: YA DEFINIDO. Establece el alcance funcional permitido en fase 1.
- **IMPLEMENTATION CONSEQUENCE**: NINGUNO ADICIONAL (define lo que puede implementarse, no requiere cambios adicionales por sí mismo).

### D-014 — Definir el modelo de comisión (split‑payment vs factura posterior) y su tratamiento contable (IVA, retención en la fuente)
- **LEGAL STATUS**: REQUIRES LEGAL COUNSEL (similar a D-005, depende de normativa tributaria y de establecimientos de pago para determinar la naturaleza jurídica de cada modelo).
- **ARCHITECTURAL CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Define si la comisión se aplica mediante split payment del PSP o mediante factura posterior al salón.
- **IMPLEMENTATION CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Requiere elección entre split payment y factura posterior, ajustes en lógica de comisión, posible nueva tabla o columna para tipo de comisión.

### D-015 — Establecer procedimientos de gestión de consentimientos específicos por finalidad (otorgamiento, revocación, evidencia, versionado)
- **LEGAL STATUS**: REQUIRES LEGAL COUNSEL (depende de Ley 1581 art. 7 sobre consentimiento específico, informado y separado por finalidad).
- **ARCHITECTURAL CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Define los procesos concretos para otorgamiento, revocación, registro de evidencia y versionado de los consentimientos.
- **IMPLEMENTATION CONSEQUENCE**: PENDIENTE DE LEGAL STATUS. Requiere tabla `consentimientos`, API de otorgamiento/revocación, middleware de verificación de consentimiento, UI para gestión de consentimientos.

## CONCLUSIÓN GENERAL
Todas las decisiones que requieren validación jurídica externa permanecen en estado de revisión requerida. Solo D-003 (no aplicable en fase 1), D-008 (verificable internamente) y D-013 (ya aprobado) tienen un estado determinado sin necesidad de verificación externa inmediata.

La próxima etapa requiere la intervención de asesores jurídicos externos para determinar el estatus jurídico de las decisiones marcadas como REQUIRES LEGAL COUNSEL o UNVERIFIED.