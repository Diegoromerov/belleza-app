# DIRECTOR DECISION PACK

## RESOLUCIÓN CONTROLADA DE DECISIONES D-001 → D-015

### AUTORIDAD
Esta directiva es emitida por el Director de Arquitectura de GlowApp.
Hermes NO está autorizado a implementar ninguna de las decisiones contenidas en este documento.
Su función en esta etapa es exclusivamente:
CONSOLIDAR EVIDENCIA
→ EXPLICAR DECISIONES
→ IDENTIFICAR IMPACTOS
→ IDENTIFICAR DEPENDENCIAS
→ SEPARAR DECISIONES ARQUITECTÓNICAS DE LEGALES
→ PREPARAR EL PAQUETE PARA DECISIÓN DEL DIRECTOR

---


## D-001 — Estrategia de multi‑tenancy (shared DB/shared schema + RLS vs. separate schema vs. DB por tenant)

### A. Propuesta existente
Definir la estrategia de multi‑tenancy a utilizar en GlowApp: decidir entre una base de datos compartida con esquema compartido y Row Level Security (RLS), esquemas separados por tenant, o una base de datos física por cada tenant.

### B. Evidencia
- Archivo: `.hermes/DECISION-REGISTER.md`, línea 5-6
- Evidencia: "No hay tenant_id en esquema; se requiere decisión de arquitectura"
- Componente: Esquema de base de datos (tablas de negocio: usuarios, perfiles_prestador, services, bookings, transactions, etc.)

### C. Problema que resuelve
Ausencia de aislamiento de datos entre distintos salones (tenants) en la base de datos actual, lo que representa un riesgo de filtración de información y no cumple con el principio de multi‑tenancy requerido para un SaaS B2B.

### D. Impacto arquitectónico
- **Backend**: Cambios en los modelos de datos (añadir columna tenant_id), actualización de consultas y repositorios.
- **Base de datos**: Necesidad de migraciones para añadir tenant_id, crear tabla tenants, posible implementación de RLS o particionamiento.
- **APIs**: Los endpoints deberán filtrar por tenant_id implícitamente (por contexto de autenticación) o explícitamente.
- **Infraestructura**: Posible necesidad de ajustes en estrategias de backup y escalado por tenant.
- **Seguridad**: Asegurar que las políticas de acceso (RLS o similares) impidan el acceso cruzado entre tenants.
- **Tenancy**: Define el modelo de aislamiento de datos.
- **IA/RAG**: Los embeddings y consultas de conocimiento deberán respetar el tenant_id para evitar fugas de información entre salones.
- **Pagos**: Las transacciones deben quedar asociadas al tenant correcto para reportes y conciliación.
- **Observabilidad**: Los logs y métricas deben incluir tenant_id para trazabilidad.
- **SOUL/Governance**: Ningún impacto directo.

### E. Dependencias
- Ninguna dependencia directa de otras decisiones D‑xxx, pero requiere que se defina antes de cualquier cambio de esquema que incluya tenant_id.
- Depende de la disponibilidad de herramientas de migración y de pruebas de backfill de datos existentes.

### F. Riesgos
- **Técnico**: Errores en la migración de datos o en las consultas pueden provocar pérdida o corrupción de información.
- **Operacional**: Downtime durante la aplicación de migraciones si no se hace de forma adecuada.
- **Legal**: Incumplimiento de la Ley 1581 si los datos de distintos tenants no están adecuadamente aislados.
- **Seguridad**: Fugas de datos entre tenants si la implementación de RLS o separación es defectuosa.

### G. Naturaleza de la decisión
ARCHITECTURAL (define la estructura fundamental de los datos y el aislamiento entre tenants).

### H. Autoridad requerida
DIRECTOR (decisión arquitectónica pura).

### I. Estado actual
PENDIENTE

---


## D-002 — Alcance de la oferta de fuerza laboral (si se expande a empleados)

### A. Propuesta existente
Definir si GlowApp ofrecerá funcionalidades de gestión de fuerza laboral (nómina, ausencias, capacitación, etc.) para los salones, lo que implicaría asumir responsabilidades legales relacionadas con empleadores.

### B. Evidencia
- Archivo: `.hermes/DECISION-REGISTER.md`, línea 7-8
- Evidencia: "No hay módulo de nómina ni contratos de empleo en código"
- Componente: Ausencia total de módulos de nómina, gestión de empleados, etc.

### C. Problema que resuelve
Evitar la expansión no autorizada a funcionalidades que implicarían responsabilidades legales adicionales (obligaciones laborales, retenciones, aportes a seguridad sin la debida certificación).

### D. Impacto arquitectónico
- **Backend**: Posible creación de nuevos servicios y tablas (empleados, nóminas, ausencias, capacitaciones).
- **Base de datos**: Nuevas tablas y relaciones.
- **APIs**: Nuevos endpoints para gestión de fuerza laboral.
- **Frontend**: Nuevas pantallas y módulos en la aplicación Flutter para administradores de salones y empleados.
- **Infraestructura**: Posible necesidad de servicios adicionales (ej. servicios de pago para nómina, integración con entidades bancarias).
- **Seguridad**: Manejo de datos sensibles laborales (salarios, información bancaria de empleados, datos de salud laboral).
- **Tenancy**: Los datos de fuerza laboral deben estar aislados por tenant.
- **IA/RAG**: Posible uso para recomendaciones de capacitación, pero con restricciones de datos sensibles.
- **Pagos**: Integración con sistemas de pago para nómina y retenciones.
- **Observabilidad**: Auditoría de acceso a datos laborales.
- **SOUL/Governance**: Impacto en la experiencia de usuario para administradores de salones y empleados.

### E. Dependencias
- Depende de la definición de multi‑tenancy (D-001) para aislar los datos de fuerza laboral por tenant.
- Depende de decisiones de seguridad y consentimiento para manejar datos sensibles laborales.

### F. Riesgos
- **Legal**: Alto riesgo si se ofrece funcionalidad de nómina sin las certificaciones requeridas por el Ministerio de Trabajo y seguridad social.
- **Operacional**: Complejidad en la integración con sistemas externos de pago y entidades bancarias.
- **Técnico**: Necesidad de cumplir con estándares de protección de datos laborales (Ley 1581, SIC Circ. 022/2023).
- **Financiero**: Costos de desarrollo y mantenimiento de módulos adicionales.

### G. Naturaleza de la decisión
PRODUCT (define el alcance funcional del producto ofrecido a los salones).

### H. Autoridad requerida
DIRECTOR (decisión de producto).

### I. Estado actual
PENDIENTE

---


## D-003 — Modelo de responsabilidad para facturación electrónica futura

### A. Propuesta existente
Definir el modelo de responsabilidad para la facturación electrónica en fases posteriores (quién será responsable de generar, transmitir y almacenar las facturas electrónicas bajo la normativa DIAN).

### B. Evidencia
- Archivo: `.hermes/DECISION-REGISTER.md`, línea 9-10
- Evidencia: "Prohibido el facturador electrónico en fase 1; decisión futura pertenece a fase posterior"
- Componente: No existe facturación electrónica en la fase actual; se trata de una decisión para fases futuras.

### C. Problema que resuelve
Evitar decisiones prematuras sobre responsabilidad fiscal que podrían generar confusión o trabajo innecesario en la fase 1, donde GlowApp no debe actuar como facturador electrónico ni como proveedor tecnológico DIAN.

### D. Impacto arquitectónico
- **Backend**: Ningún impacto en la fase 1 (se mantiene la prohibición de facturación electrónica).
- **Base de datos**: Ninguna tabla de facturas, CUFE, XML/UBL en la fase 1.
- **APIs**: No se crean endpoints de facturación electrónica en la fase 1.
- **Frontend**: No se implementan UI de facturación electrónica en la fase 1.
- **Infraestructura**: No se requieren cambios en la fase 1.
- **Seguridad**: No se manejan datos fiscales en la fase 1.
- **Tenancy**: No aplica en fase 1.
- **IA/RAG**: No aplica en fase 1.
- **Pagos**: No se generan facturas electrónicas vinculadas a pagos en la fase 1.
- **Observabilidad**: No se registran eventos de facturación electrónica en la fase 1.
- **SOUL/Governance**: Ningún impacto en la fase 1.

### E. Dependencias
- No tiene dependencias en la fase 1, ya que se pospone a fases posteriores.

### F. Riesgos
- **Ninguno en la fase 1**, ya que se mantiene la posición actual de no facturación electrónica.
- Riesgo futuro si se define incorrectamente el modelo de responsabilidad, pero se pospone a fase posterior.

### G. Naturaleza de la decisión
LEGAL (define responsabilidad jurídica futura bajo normativa DIAN).

### H. Autoridad requerida
DIRECTOR + LEGAL (requiere decisión arquitectónica y validación jurídica de la normativa DIAN).

### I. Estado actual
NOT APPLICABLE EN FASE 1

---


## D-004 — Estrategia de retención de datos para RAG y conocimiento organizacional

### A. Propuesta existente
Definir la política de retención y eliminación segura de datos utilizados en los sistemas de RAG (Retrieval-Augmented Generation) y conocimiento organizacional, incluyendo mecanismos de legal hold.

### B. Evidencia
- Archivo: `.hermes/DECISION-REGISTER.md`, línea 11-12
- Evidencia: "No hay política de retención ni mecanismo de legal hold"
- Componente: Ausencia de tabla retention_policies y trabajo cron de borrado criptográfico para datos de RAG y conocimiento.

### C. Problema que resuelve
Evitar la retención indefinida de datos utilizados en modelos de IA y conocimiento organizacional, lo que podría violar el deber de supresión de la Ley 1581 y generar riesgos de exposición de información sensible.

### D. Impacto arquitectónico
- **Backend**: Posible creación de servicio de retención, tabla retention_policies, trabajo cron.
- **Base de datos**: Nuevas tablas para políticas de retención y posiblemente logs de eliminación.
- **APIs**: Endpoints para consulta y actualización de políticas de retención.
- **Frontend**: Posible UI para visualización y gestión de políticas de retención (por administradores del sistema).
- **Infraestructura**: Trabajo cron que requiere infraestructura de programación (ej. servicios en segundo plano o procesos programados).
- **Seguridad**: Asegurar que la eliminación sea criptográfica y que los datos de legal hold no se eliminen por error.
- **Tenancy**: Las políticas de retención pueden ser por tenant o globales; se debe definir.
- **IA/RAG**: Directamente impacta en cuánto se retienen los embeddings, chunks y datos de conocimiento utilizados por los modelos de IA.
- **Pagos**: No aplica directamente.
- **Observabilidad**: Registro de actividades de retención y eliminación.
- **SOUL/Governance**: Impacto en la percepción de cumplimiento y responsabilidad en el manejo de datos de conocimiento.

### E. Dependencias
- Depende de la definición de multi‑tenancy (D-001) si se opta por políticas de retención por tenant.
- Depende de decisiones de seguridad para asegurar el borrado criptográfico.

### F. Riesgos
- **Legal**: Alto riesgo de incumplimiento de la Ley 1581 art. 8 si se retienen datos más allá de su plazo legal sin legal hold.
- **Operacional**: Complejidad en la definición y aplicación correcta de políticas de retención para distintos tipos de datos.
- **Técnico**: Riesgo de eliminación accidental o incompleta de datos si los trabajos cron fallan.
- **Seguridad**: Riesgo de exposición de datos sensibles si la eliminación no es segura (por ejemplo, simple DELETE sin sobrescritura).

### G. Naturaleza de la decisión
MIXED (tiene componentes legales, técnicos y operacionales).

### H. Autoridad requerida
DIRECTOR + LEGAL (requiere decisión sobre la política y validación legal de los plazos y mecanismos).

### I. Estado actual
PENDIENTE

---


## D-005 — Definir el modelo de comisión y su tratamiento contable (ingreso de GlowApp) y si se aplicará IVA o retención en la fuente

### A. Propuesta existente
Definir cómo GlowApp reconocerá sus ingresos por comisión (ya sea mediante suscripción SaaS fija, comisión posterior facturada al salón, o comisión mediante split payment del PSP) y determinar el tratamiento contable y tributario (aplicación de IVA, retenciones en la fuente, etc.).

### B. Evidencia
- Archivo: `.hermes/DECISION-REGISTER.md`, línea 13-14
- Evidencia: "Comisión actualmente como porcentaje fijo en platform_config; se requiere decisión sobre modelo (suscripción vs posterior vs split) y tratamiento tributario"
- Componente: Campo `comision_plataforma_pct` en la tabla `platform_config`; lógica de cálculo en el trigger `calc_booking_split` (backend/src/services/wompiService.js y similares).

### C. Problema que resuelve
Evitar ambigüedades en el reconocimiento de ingresos que podrían llevar a errores contables, problemas tributarios o malentendidos con los salones sobre qué están pagando y por qué.

### D. Impacto arquitectónico
- **Backend**: Posible cambio en la lógica de cálculo de comisión (en el trigger o en el servicio de pagos), actualización de platform_config, posible nueva tabla o campo para diferenciar tipos de comisión.
- **Base de datos**: Posible necesidad de añadir columnas o tablas para registrar el tipo de comisión aplicada a cada transacción o salón.
- **APIs**: Los endpoints de pago y de configuración podrían necesitar ajustes para reflejar el nuevo modelo.
- **Frontend**: Posible necesidad de mostrar al salón el tipo de comisión que se está aplicando (en pantalla de configuración o facturación).
- **Infraestructura**: Ningún impacto directo.
- **Seguridad**: Ningún impacto directo.
- **Tenancy**: El modelo de comisión puede ser configurable por tenant o global.
- **IA/RAG**: No aplica directamente.
- **Pagos**: Afecta directamente al registro de la comisión en la transacción (se descuenta del valor bruto o se factura posteriormente).
- **Observabilidad**: Registro de ingresos por comisión para reportes financieros.
- **SOUL/Governance**: Impacto en la relación económica entre GlowApp y el salón; debe ser claro y transparente.

### E. Dependencias
- Depende de la definición de multi‑tenancy (D-001) si se permite variar el modelo por tenant.
- Depende de decisiones sobre split payment (D-014) si se considera ese modelo.
- Depende de la definición de comisión posterior (relacionado con D-005 y D-014) para decidir si se factura al salón.

### F. Riesgos
- **Legal/Tributario**: Riesgo de aplicar incorrectamente IVA o retenciones en la fuente, lo que podría llevar a multas o requerimientos de la DIAN.
- **Operacional**: Riesgo de confusiones con los salones si el modelo de comisión no se comunica claramente.
- **Técnico**: Riesgo de errores en la lógica de cálculo que lleven a comisiones incorrectas (sobres o faltantes).
- **Financiero**: Impacto directo en los ingresos de GlowApp y en el flujo de caja de los salones.

### G. Naturaleza de la decisão
MIXED (tiene componentes de producto, técnicos y legales/tributarios).

### H. Autoridad requerida
DIRECTOR + LEGAL (requiere decisión de producto y validación tributaria/contable).

### I. Estado actual
PENDIENTE

---


## D-006 — Elegibilidad para usar el fiscal adapter (regímenes, montos)

### A. Propuesta existente
Definir bajo qué condiciones (regímenes tributarios, montos de facturación, etc.) un salón podrá utilizar el fiscal adapter para conectar con un proveedor tecnológico DIAN habilitado y comenzar a emitir facturas electrónicas a través de GlowApp.

### B. Evidencia
- Archivo: `.hermes/DECISION-REGISTER.md`, línea 15-16
- Evidencia: "Fiscal adapter solo conceptual; se requiere definir reglas de activación"
- Componente: El fiscal adapter se menciona como una abstracción futura inactiva (no implementada aún).

### C. Problema que resuelve
Evitar que salones que no cumplan con los requisitos legales o técnicos intenten usar el adapter, lo que podría generar facturas electrónicas no válidas o exposición a sanciones.

### D. Impacto arquitectónico
- **Backend**: Posible creación de un servicio o módulo que verifique la elegibilidad antes de activar el adapter.
- **Base de datos**: Posible necesidad de almacenar la elegibilidad o el estado de activación por salón (tenant).
- **APIs**: Endpoint para consultar o solicitar activación del adapter.
- **Frontend**: Posible UI en la configuración del salón para ver el estado y solicitar activación.
- **Infraestructura**: Ningún impacto directo.
- **Seguridad**: El adapter solo debe activarse cuando se cumplan los requisitos legales y técnicos.
- **Tenancy**: La elegibilidad se evalúa por salón (tenant).
- **IA/RAG**: No aplica directamente.
- **Pagos**: No aplica directamente (el adapter se ocupa de facturación, no de pago).
- **Observabilidad**: Registro de intentos de activación y éxito/fallo.
- **SOUL/Governance**: Impacto en la experiencia del salón al intentar cumplir con sus obligaciones fiscales.

### E. Dependencias
- Depende de la existencia del adapter (conceptual) y de su diseño futuro.
- Depende de la definición de cuándo un salón está obligado a facturar electrónicamente (relacionado con la normativa DIAN y la decisión D-003 futura).
- Depende de la multi‑tenancy (D-001) para aplicar la elegibilidad por tenant.

### F. Riesgos
- **Legal**: Riesgo de permitir la activación del adapter a salones que no estén obligados o que no cumplan con requisitos técnicos, lo que podría generar facturas no válidas.
- **Operacional**: Complejidad en la verificación de la elegibilidad (requiere acceso a información tributaria del salón o declaración responsable).
- **Técnico**: Riesgo de errores en la lógica de activación que permitan o bloqueen incorrectamente el adapter.
- **Seguridad**: Si se activa incorrectamente, podría haber manejo inadecuado de datos fiscales.

### G. Naturaleza de la decisión
MIXED (tiene componentes de producto, técnicos y legales).

### H. Autoridad requerida
DIRECTOR + LEGAL (requiere definición de reglas de producto y validación legal de los regímenes y montos).

### I. Estado actual
PENDIENTE

---


## D-007 — Selección de proveedor de pagos alternativos o expansión más allá de NEQUI/Wompi (tarjeta, PSE, efectivo)

### A. Propuesta existente
Seleccionar uno o más proveedores de pagos adicionales (como tarjetas de crédito/débito, PSE, efectivo mediante corresponsales bancarios) para ampliar las opciones de pago disponibles a los clientes de los salones mediante GlowApp.

### B. Evidencia
- Archivo: `.hermes/DECISION-REGISTER.md`, línea 17-18
- Evidencia: "wompiService.js solo procesa NEQUI; se requiere decisión sobre nuevos medios de pago"
- Componente: El servicio `wompiService.js` actualmente solo maneja el método de pago NEQUI mediante Wompi.

### C. Problema que resuelve
Evitar la limitación a un solo método de pago (NEQUI) que podría reducir la tasa de conversión y la satisfacción del cliente al no ofrecer opciones de pago más comunes como tarjetas, PSE o efectivo.

### D. Impacto arquitectónico
- **Backend**: Necesidad de abstraer el servicio de pagos para soportar múltiples proveedores y métodos, posible implementación de una capa de estrategia o enrutamiento.
- **Base de datos**: Posible necesidad de añadir o cambiar la columna `payment_method` en la tabla `transactions` para reflejar nuevos métodos (se mantiene, pero se amplían los valores válidos).
- **APIs**: Los endpoints de pago podrían necesitar ajustes para aceptar nuevos métodos de pago y devolver la información adecuada.
- **Frontend**: La UI de selección de método de pago deberá actualizarse para incluir las nuevas opciones.
- **Infraestructura**: Posible necesidad de integración con nuevos PSPs o servicios bancarios (requiere credenciales, endpoints, etc.).
- **Seguridad**: Cada nuevo método de pago conlleva sus propios requisitos de seguridad (por ejemplo, cumplimiento PCI DSS para tarjetas, manejo seguro de credenciales para PSE).
- **Tenancy**: Los métodos de pago disponibles pueden ser configurables por tenant o globales.
- **IA/RAG**: No aplica directamente.
- **Pagos**: Afecta directamente al núcleo de la funcionalidad de pago de GlowApp.
- **Observabilidad**: Registro de uso de cada método de pago, tasas de éxito, etc.
- **SOUL/Governance**: Impacto en la experiencia de pago del cliente y en la percepción de flexibilidad del salón.

### E. Dependencias
- Depende de la definición de multi‑tenancy (D-001) si se permite variar los métodos de pago por tenant.
- Depende de decisiones de seguridad para asegurar el cumplimiento de estándares (PCI DSS, etc.) para cada nuevo método.
- Depende de la disponibilidad y costo de integración con los nuevos PSPs.

### F. Riesgos
- **Técnico**: Riesgo de errores en la integración que provoquen fallos en el procesamiento de pagos.
- **Legal/Regulatorio**: Riesgo de no cumplir con los requisitos de seguridad o normativas locales para cada método de pago (por ejemplo, requisitos de almacenamiento de datos de tarjetas).
- **Operacional**: Complejidad en el mantenimiento de múltiples integraciones y en la gestión de credenciales y certificados.
- **Financiero**: Costos de integración, comisiones de los nuevos PSPs, y posibles tarifas de establecimiento.

### G. Naturaleza de la decisión
MIXED (tiene componentes técnicos, de producto y de seguridad).

### H. Autoridad requerida
DIRECTOR + LEGAL (requiere decisión de producto y validación legal/técnica de los nuevos métodos de pago).

### I. Estado actual
PENDIENTE

---


## D-008 — Definir niveles de servicio y acuerdos de disponibilidad (uptime, ventanas de mantenimiento, tiempo de respuesta de soporte)

### A. Propuesta existente
Definir los niveles de servicio (SLAs) que GlowApp ofrecerá a los salones, incluyendo metas de uptime, ventanas de mantenimiento permitido y tiempos esperados de respuesta para el soporte técnico.

### B. Evidencia
- Archivo: `.hermes/DECISION-REGISTER.md`, línea 19-20
- Evidencia: "No hay definición de SLA en documentación ni código"
- Componente: Ausencia de definiciones formales de SLA en documentos de arquitectura, términos de servicio o código de monitoreo.

### C. Problema que resuelve
Evitar expectativas desalineadas entre GlowApp y los salones sobre la disponibilidad de la plataforma y el soporte, lo que podría generar conflictos y percepciones de mala calidad del servicio.

### D. Impacto arquitectónico
- **Backend**: Posible implementación de monitoreo de salud de servicios, métricas de disponibilidad y tiempos de respuesta.
- **Base de datos**: Posible necesidad de tablas para almacenar métricas de desempeño y eventos de mantenimiento.
- **APIs**: Los endpoints de health check y monitoreo podrían necesitar estandarización.
- **Frontend**: Posible UI para que los salones vean el estado del servicio y reportes de disponibilidad.
- **Infraestructura**: Definición de ventanas de mantenimiento que afectan a la programación de actualizaciones y despliegues.
- **Seguridad**: El monitoreo de disponibilidad no afecta directamente la seguridad, pero los tiempos de respuesta de soporte pueden incluir manejo de incidentes de seguridad.
- **Tenancy**: Los SLAs pueden ser por tenant (diferentes niveles de servicio) o globales.
- **IA/RAG**: Posible inclusión de métricas de desempeño de los servicios de IA (latencia, tasa de error).
- **Pagos**: Los SLAs pueden incluir metas específicas para los servicios de pago (por ejemplo, tiempo máximo de procesamiento).
- **Observabilidad**: Central para el cumplimiento de los SLAs; se requieren métricas, alerts y dashboards.
- **SOUL/Governance**: Impacto en la percepción de fiabilidad y confianza en la plataforma por parte de los salones.

### E. Dependencias
- No tiene dependencias fuertes de otras decisiones D‑xxx, pero se beneficia de tener definido el multi‑tenancy (D-001) para aplicar SLAs por tenant si se desea.
- Depende de la disponibilidad de herramientas de monitoreo y alertas.

### F. Riesgos
- **Operacional**: Riesgo de no poder cumplir con los SLAs prometidos, lo que podría llevar a multas contractuales o pérdida de confianza.
- **Técnico**: Riesgo de falta de visibilidad real en el desempeño del sistema si el monitoreo no es adecuado.
- **Financiero**: Posibles costos asociados al cumplimiento de SLAs (inversión en infraestructura, personal de soporte, etc.).

### G. Naturaleza de la decisión
MIXED (tiene componentes de producto, técnicos y operacionales).

### H. Autoridad requerida
DIRECTOR (decisión de producto y operacional).

### I. Estado actual
PENDIENTE

---


## D-009 — Establecer política de retención y eliminación de datos (definir períodos por tipo de dato, mecanismo de legal hold)

### A. Propuesta existente
Definir la política general de retención y eliminación segura de datos personales y operacionales en GlowApp, especificando los períodos de retención por tipo de dato y el mecanismo de legal hold para preservar datos cuando sea necesario por requisitos legales o litigios.

### B. Evidencia
- Archivo: `.hermes/DECISION-REGISTER.md`, línea 21-22
- Evidencia: "No hay tabla retention_policies ni trabajo cron"
- Componente: Ausencia de tabla `retention_policies` y de trabajo cron de borrado criptográfico.

### C. Problema que resuelve
Evitar la retención indefinida de datos que viole el deber de supresión de la Ley 1581 y el riesgo de exposición de información sensible o personal más allá de lo necesario.

### D. Impacto arquitectónico
- **Backend**: Posible creación de servicio de retención, tabla `retention_policies`, trabajo cron de borrado criptográfico.
- **Base de datos**: Nueva tabla `retention_policies` y posiblemente una tabla de registro de actividades de eliminación o legal hold.
- **APIs**: Endpoints para consulta, actualización y posiblemente solicitud de legal hold.
- **Frontend**: Posible UI para que los administradores del sistema (o los salones, si corresponde) vean y gestionen las políticas de retención.
- **Infraestructura**: Trabajo cron que requiere infraestructura de programación (servicios en segundo plano o procesos programados).
- **Seguridad**: Asegurar que la eliminación sea criptográfica y que los datos bajo legal hold no se eliminen por error.
- **Tenancy**: Las políticas pueden ser por tenant o globales; se debe definir.
- **IA/RAG**: Afecta a los datos utilizados por los sistemas de RAG y conocimiento (ver D-004).
- **Pagos**: Afecta a los datos de pago (monto, método, referencia externa) que deben conservarse según requerimientos contables y fiscales.
- **Observabilidad**: Registro de actividades de retención y eliminación.
- **SOUL/Governance**: Impacto en la percepción de cumplimiento y responsabilidad en el manejo de datos personales y operacionales.

### E. Dependencias
- Depende de la definición de multi‑tenancy (D-001) si se opta por políticas de retención por tenant.
- Depende de decisiones de seguridad para asegurar el borrado criptográfico.

### F. Riesgos
- **Legal**: Alto riesgo de incumplimiento de la Ley 1581 art. 8 si se retienen datos más allá de su plazo legal sin legal hold.
- **Operacional**: Complejidad en la definición y aplicación correcta de políticas de retención para distintos tipos de datos (personales, de pago, operacionales, etc.).
- **Técnico**: Riesgo de eliminación accidental o incompleta de datos si los trabajos cron fallan.
- **Seguridad**: Riesgo de exposición de datos sensibles si la eliminación no es segura (por ejemplo, simple DELETE sin sobrescritura).

### G. Naturaleza de la decisión
MIXED (tiene componentes legales, técnicos y operacionales).

### H. Autoridad requerida
DIRECTOR + LEGAL (requiere decisión sobre los períodos y mecanismos y validación legal de los plazos y requisitos).

### I. Estado actual
PENDIENTE

---


## D-010 — Definir reglas de activación del fiscal adapter (cuándo un salón debe usar facturación electrónica vía adapter)

### A. Propuesta existente
Definir las reglas concretas que determinen cuándo un salón debe activar el fiscal adapter para comenzar a usar facturación electrónica a través de GlowApp (por ejemplo, basado en régimen tributario, volumen de facturación, etc.).

### B. Evidencia
- Archivo: `.hermes/DECISION-REGISTER.md`, línea 23-24
- Evidencia: "Fiscal adapter inactivo; se requiere definir cuándo activarse"
- Componente: El fiscal adapter se mantiene como una abstracción conceptual e inactiva.

### C. Problema que resuelve
Evitar la activación prematura o incorrecta del fiscal adapter, lo que podría llevar a facturas electrónicas no válidas, exposición a sanciones o pérdida de confianza por parte de los salones.

### D. Impacto arquitectónico
- **Backend**: Posible creación de un servicio o módulo que evalúe las reglas de activación y gestione el estado del adapter por salón.
- **Base de datos**: Posible necesidad de almacenar el estado de activación o elegibilidad del adapter por tenant (salon).
- **APIs**: Endpoint para consultar o solicitar la activación del adapter.
- **Frontend**: Posible UI en la configuración del salón para ver el estado y solicitar activación.
- **Infraestructura**: Ningún impacto directo.
- **Seguridad**: El adapter solo debe activarse cuando se cumplan los requisitos legales y técnicos.
- **Tenancy**: La elegibilidad se evalúa por salón (tenant).
- **IA/RAG**: No aplica directamente.
- **Pagos**: No aplica directamente (el adapter se ocupa de facturación, no de pago).
- **Observabilidad**: Registro de intentos de activación y éxito/fallo.
- **SOUL/Governance**: Impacto en la experiencia del salón al intentar cumplir con sus obligaciones fiscales.

### E. Dependencias
- Depende de la existencia del adapter (conceptual) y de su diseño futuro.
- Depende de la definición de cuándo un salón está obligado a facturar electrónicamente (relacionado con la normativa DIAN y la decisión D-003 futura).
- Depende de la multi‑tenancy (D-001) para aplicar las reglas por tenant.

### F. Riesgos
- **Legal**: Riesgo de permitir la activación del adapter a salones que no estén obligados o que no cumplan con requisitos técnicos, lo que podría generar facturas no válidas.
- **Operacional**: Complejidad en la verificación de la elegibilidad (requiere acceso a información tributaria del salón o declaración responsable).
- **Técnico**: Riesgo de errores en la lógica de activación que permitan o bloqueen incorrectamente el adapter.
- **Seguridad**: Si se activa incorrectamente, podría haber manejo inadecuado de datos fiscales.

### G. Naturaleza de la decisión
MIXED (tiene componentes de producto, técnicos y legales).

### H. Autoridad requerida
DIRECTOR + LEGAL (requiere definición de reglas de producto y validación legal de los regímenes y condiciones).

### I. Estado actual
PENDIENTE

---


## D-011 — Seleccionar proveedor de pagos alternativos o expansión más allá de NEQUI/Wompi (tarjeta, PSE, efectivo) y definir lógica de enrutamiento

### A. Propuesta existente
Seleccionar proveedores de pagos adicionales y definir la lógica de enrutamiento que determine cómo se dirige cada transacción de pago al proveedor apropiado (basado en método de pago, monto, región, etc.).

### B. Evidencia
- Archivo: `.hermes/DECISION-REGISTER.md`, línea 25-26
- Evidencia: "Duplica D-007 pero con énfasis en lógica de enrutamiento"
- Componente: Similar a D-007, pero se enfatiza en la lógica que decide a qué proveedor enviarse cada solicitud de pago.

### C. Problema que resuelve
Evitar una implementación caótica o inconsistente del enrutamiento de pagos que podría llevar a errores, fallos o favoritismo injustificado hacia ciertos proveedores.

### D. Impacto arquitectónico
- **Backend**: Necesidad de definir una capa de enrutamiento o estrategia que seleccione el proveedor de pago apropiado para cada transacción.
- **Base de datos**: Posible necesidad de almacenar la decisión de enrutamiento o el proveedor utilizado para cada transacción (puede ir en metadata o en un campo dedicado).
- **APIs**: Los endpoints de pago deben delegar al enrutador y devolver el resultado del proveedor seleccionado.
- **Frontend**: No hay impacto directo en la UI de selección de método de pago (ese sigue siendo el mismo), pero el resultado del pago dependerá del enrutamiento.
- **Infraestructura**: Posible necesidad de integración con múltiples PSPs, cada uno con sus propios requisitos de conexión y credenciales.
- **Seguridad**: Cada proveedor en el enrutamiento debe cumplir con los estándares de seguridad requeridos.
- **Tenancy**: La lógica de enrutamiento puede ser configurable por tenant o global.
- **IA/RAG**: No aplica directamente.
- **Pagos**: Afecta directamente al núcleo de la funcionalidad de pago de GlowApp.
- **Observabilidad**: Registro de qué proveedor se usó para cada transacción, tasas de éxito por proveedor, etc.
- **SOUL/Governance**: Impacto en la experiencia de pago del cliente y en la percepción de fiabilidad del sistema de pagos.

### E. Dependencias
- Depende de la selección de proveedores de pagos alternativos (D-007).
- Depende de la definición de multi‑tenancy (D-001) si se permite variar el enrutamiento por tenant.
- Depende de decisiones de seguridad para asegurar el cumplimiento de estándares para cada nuevo proveedor.

### F. Riesgos
- **Técnico**: Riesgo de errores en la lógica de enrutamiento que envíen transacciones al proveedor equivocado o que fallen en el proceso.
- **Legal/Regulatorio**: Riesgo de no cumplir con los requisitos de seguridad o normativas locales para cada método de pago en el enrutamiento.
- **Operacional**: Complejidad en el mantenimiento de la lógica de enrutamiento y en la gestión de múltiples integraciones.
- **Financiero**: Posibles diferencias en costos y comisiones entre los proveedores en el enrutamiento.

### G. Naturaleza de la decisión
MIXED (tiene componentes técnicos, de producto y de seguridad).

### H. Autoridad requerida
DIRECTOR + LEGAL (requiere decisión de producto y validación legal/técnica de los nuevos métodos de pago y su lógica de enrutamiento).

### I. Estado actual
PENDIENTE

---


## D-012 — Establecer política de uso de IA / RAG (filtrado de datos sensibles, registro de interacciones, opt‑out de uso de datos para mejora de modelos)

### A. Propuesta existente
Establecer una política que regule el uso de IA y RAG en GlowApp, incluyendo el filtrado o anonimización de datos sensibles antes de enviar a modelos externos, el registro estructurado de interacciones (prompt, respuesta, latencia, tokens) y la posibilidad de opt‑out de que los datos se usen para mejorar los modelos de IA.

### B. Evidencia
- Archivo: `.hermes/DECISION-REGISTER.md`, línea 27-28
- Evidencia: "No hay capa de gobernanza de IA ni registro de interacciones"
- Componente: Ausencia de capa de gobernanza de IA y de registro estructurado de interacciones con modelos de IA.

### C. Problema que resuelve
Evitar la exposición no autorizada o accidental de datos sensibles (personales, de salud, biométricos, financieros) a modelos de IA externos, y asegurar la trazabilidad y el consentimiento en el uso de IA para mejora de modelos.

### D. Impacto arquitectónico
- **Backend**: Posible creación de middleware o servicio que filtre o anonimice datos sensibles antes de enviarlos a LLMs externos, y que registre las interacciones.
- **Base de datos**: Posible necesidad de tablas para almacenar las interacciones de IA (prompt, respuesta, latencia, tokens, metadata).
- **APIs**: Los endpoints que invoquen a LLMs externos deberán pasar por el filtro de gobernanza.
- **Frontend**: Posible UI para que los administradores del sistema o los salones vean y gestionen la política de uso de IA (por ejemplo, activar/desactivar opt‑out).
- **Infraestructura**: Ningún impacto directo.
- **Seguridad**: Asegurar que los datos sensibles no salgan sin el filtrado o anonimización apropiado.
- **Tenancy**: El filtrado y registro deben respetar el tenant_id para evitar fugas entre salones.
- **IA/RAG**: Es el núcleo de la decisión; define cómo se usa la IA y el RAG de forma segura y conforme.
- **Pagos**: No aplica directamente, pero si se usan datos de pago en IA, deben filtrarse.
- **Observabilidad**: Registro de interacciones de IA para auditoría y mejora.
- **SOUL/Governance**: Impacto en la percepción de responsabilidad y ética en el uso de IA y en la confianza de los usuarios y salones.

### E. Dependencias
- Depende de la definición de multi‑tenancy (D-001) si se aplica el filtrado y registro por tenant.
- Depende de decisiones de seguridad y consentimiento para definir qué se considera dato sensible y cómo se maneja el consentimiento para uso de IA.

### F. Riesgos
- **Legal**: Alto riesgo de incumplimiento de la Ley 1581 art. 10 y del SIC Circ. 022/2023 si se exponen datos sensibles a terceros sin el consentimiento adecuado.
- **Operacional**: Complejidad en la definición y aplicación correcta de qué se considera dato sensible y cómo se filtra o anonimiza.
- **Técnico**: Riesgo de que el filtrado sea ineficaz o que el registro no capture toda la información necesaria.
- **Seguridad**: Riesgo de exposición de datos sensibles si el filtrado falla o se omite.
- **Reputacional**: Riesgo de pérdida de confianza si se descubre que se usaron datos de forma inadecuada para mejorar modelos.

### G. Naturaleza de la decisión
MIXED (tiene componentes legales, técnicos y de producto).

### H. Autoridad requerida
DIRECTOR + LEGAL (requiere decisión sobre la política de uso de IA y validación legal de los requisitos de protección de datos).

### I. Estado actual
PENDIENTE

---


## D-013 — Aprobar el catálogo de funciones permitidas en fase 1 (ver sección 22 HARD BOUNDARY MATRIX)

### A. Propuesta existente
Aprobar el conjunto de funciones que están permitidas para ser implementadas en la fase 1 de GlowApp, tal como se define en la sección 22 HARD BOUNDARY MATRIX del informe de fase 1.5.11.

### B. Evidencia
- Archivo: `.hermes/DECISION-REGISTER.md`, línea 29-30
- Evidencia: "Definido en informe de fase 1.5.11 (HERMES EXECUTION REPORT)"
- Componente: El catálogo de funciones permitidas en fase 1 está listado en la HARD BOUNDARY MATRIX (ver sección 22 del informe de fase 1.5.11).

### C. Problema que resuelve
Establecer claramente qué funcionalidades pueden ser desarrolladas en la fase 1 sin cambiar la naturaleza SaaS operativo de GlowApp ni activar obligaciones legales adicionales, proporcionando una guía clara para el trabajo de implementación.

### D. Impacto arquitectónico
- **Backend**: Define qué servicios, tablas y lógica pueden ser creados o modificados en la fase 1.
- **Base de datos**: Define qué columnas y tablas pueden añadirse o modificarse en la fase 1.
- **APIs**: Define qué endpoints pueden ser creados o modificados en la fase 1.
- **Frontend**: Define qué UI y componentes pueden ser creados o modificados en la fase 1.
- **Infraestructura**: Define qué cambios en infraestructura son permitidos en la fase 1.
- **Seguridad**: Define qué controles de seguridad pueden implementarse en la fase 1.
- **Tenancy**: La multi‑tenancy (D-001) se menciona como una decisión pendiente, pero el catálogo de fase 1 asume que se trabajará en la base actual sin tenant_id aún.
- **IA/RAG**: Define qué aspectos de IA y RAG pueden abordarse en la fase 1 (por ejemplo, uso de modelos externos con filtrado, pero no entrenamiento con datos sensibles).
- **Pagos**: Define qué aspectos de pago pueden abordarse en la fase 1 (registro de pagos, verificación HMAC futura, idempotencia, etc.).
- **Observabilidad**: Define qué aspectos de logging, monitoreo y alertas pueden abordarse en la fase 1.
- **SOUL/Governance**: Define qué aspectos de la experiencia de usuario y la gobernanza pueden abordarse en la fase 1.

### E. Dependencias
- No tiene dependencias de otras decisiones D‑xxx para su definición, ya que es una conclusión basada en el análisis previo.
- Sin embargo, la implementación de las funciones aprobadas depende de las decisiones pendientes (D-001 a D-015, excepto D-013) para estar completa y conforme.

### F. Riesgos
- **Ninguno directo** por ser una definición de alcance; el riesgo radica en no respetar el límite y avanzar en funciones no aprobadas.

### G. Naturaleza de la decisión
PRODUCT (define el alcance funcional aprobado para la fase 1).

### H. Autoridad requerida
ALREADY APPROVED (se aprobó en el informe de fase 1.5.11).

### I. Estado actual
APROBADO

---


## D-014 — Definir el modelo de comisión (split‑payment vs factura posterior) y su tratamiento contable (IVA, retención en la fuente)

### A. Propuesta existente
Definir si la comisión de GlowApp se aplicará mediante split payment (el PSP divide el pago entre salón y GlowApp) o mediante factura posterior al salón, y determinar el tratamiento contable y tributario correspondiente (aplicación de IVA, retenciones en la fuente, etc.).

### B. Evidencia
- Archivo: `.hermes/DECISION-REGISTER.md`, línea 31-32
- Evidencia: "Duplica D-005 pero enfocado en split vs posterior"
- Componente: Similar a D-005, pero se centra en la comparación entre los dos modelos de comisión específicos.

### C. Problema que resuelve
Evitar ambigüedades en el modelo de comisión que puedan llevar a incoherencias contables, problemas tributarios o malentendidos con los salones sobre cómo se calcula y paga la comisión.

### D. Impacto arquitectónico
- **Backend**: Posible cambio en la lógica de cálculo de comisión (en el trigger o en el servicio de pagos) para soportar split payment o factura posterior.
- **Base de datos**: Posible necesidad de añadir columnas o tablas para registrar el tipo de comisión aplicada a cada transacción o salón.
- **APIs**: Los endpoints de pago y de configuración podrían necesitar ajustes para reflejar el nuevo modelo.
- **Frontend**: Posible necesidad de mostrar al salón el tipo de comisión que se está aplicando (en pantalla de configuración o facturación).
- **Infraestructura**: Ningún impacto directo.
- **Seguridad**: Ningún impacto directo.
- **Tenancy**: El modelo de comisión puede ser configurable por tenant o global.
- **IA/RAG**: No aplica directamente.
- **Pagos**: Afecta directamente al registro de la comisión en la transacción (se descuenta del valor bruto o se factura posteriormente).
- **Observabilidad**: Registro de ingresos por comisión para reportes financieros.
- **SOUL/Governance**: Impacto en la relación económica entre GlowApp y el salón; debe ser claro y transparente.

### E. Dependencias
- Depende de la definición de multi‑tenancy (D-001) si se permite variar el modelo por tenant.
- Depende de la definición de la comisión posterior (relacionado con D-005) para decidir si se factura al salón.
- Depende de la disponibilidad del PSP para soportar split payment (requiere que el PSP ofrezca esa funcionalidad).

### F. Riesgos
- **Legal/Tributario**: Riesgo de aplicar incorrectamente IVA o retenciones en la fuente, lo que podría llevar a multas o requerimientos de la DIAN.
- **Operacional**: Riesgo de confusiones con los salones si el modelo de comisión no se comunica claramente.
- **Técnico**: Riesgo de errores en la lógica de cálculo que lleven a comisiones incorrectas (sobres o faltantes).
- **Financiero**: Impacto directo en los ingresos de GlowApp y en el flujo de caja de los salones.

### G. Naturaleza de la decisión
MIXED (tiene componentes de producto, técnicos y legales/tributarios).

### H. Autoridad requerida
DIRECTOR + LEGAL (requiere decisión de producto y validación tributaria/contable).

### I. Estado actual
PENDIENTE

---


## D-015 — Establecer procedimientos de gestión de consentimientos específicos por finalidad (otorgamiento, revocación, evidencia, versionado)

### A. Propuesta existente
Establecer los procedimientos concretos para la gestión de consentimientos específicos por finalidad en GlowApp, incluyendo los procesos de otorgamiento, revocación, registro de evidencia y versionado de los consentimientos.

### B. Evidencia
- Archivo: `.hermes/DECISION-REGISTER.md`, línea 33-34
- Evidencia: "No hay tabla consentimientos ni flujo de otorgamiento/revocación"
- Componente: Ausencia de tabla `consentimientos` y de flujo definido para otorgamiento, revocación, evidencia y versionado.

### C. Problema que resuelve
Evitar el manejo inconsistente o no conforme de los consentimientos, lo que podría violar el deber de obtener consentimiento específico, informado y separado por finalidad establecido en la Ley 1581 art. 7.

### D. Impacto arquitectónico
- **Backend**: Posible creación de tabla `consentimientos`, API de otorgamiento y revocación, middleware de verificación de consentimiento antes de tratar datos sensibles.
- **Base de datos**: Nueva tabla `consentimientos` con columnas para finalidad, estado, timestamps de otorgamiento y revocación, evidencia y versionado.
- **APIs**: Endpoints para otorgar, revocar y consultar consentimientos.
- **Frontend**: Posible UI para que los usuarios otorguen y revoken consentimientos para distintos fines (por ejemplo, uso de imagen, biométricos, marketing, IA).
- **Infraestructura**: Ningún impacto directo.
- **Seguridad**: Asegurar que la evidencia de consentimiento se almacene de forma segura y que los datos sensibles solo se traten cuando se tenga un consentimiento válido.
- **Tenancy**: Los consentimientos deben estar aislados por tenant (salon).
- **IA/RAG**: Directamente relacionado, ya que el uso de IA con datos personales requiere un consentimiento específico por finalidad.
- **Pagos**: Los datos de pago pueden requerir consentimiento específico si se usan para fines distintos al registro de la transacción (por ejemplo, análisis de gasto).
- **Observabilidad**: Registro de actividades de otorgamiento, revocación y versionado de consentimientos.
- **SOUL/Governance**: Impacto en la percepción de respeto a la privacidad y en la confianza de los usuarios y salones al saber que sus datos solo se usan con su permiso explícito.

### E. Dependencias
- Depende de la definición de multi‑tenancy (D-001) para aplicar los consentimientos por tenant.
- Depende de decisiones de seguridad para asegurar el almacenamiento seguro de la evidencia de consentimiento.

### F. Riesgos
- **Legal**: Alto riesgo de incumplimiento de la Ley 1581 art. 7 si se tratan datos personales sin el consentimiento específico, informado y separado por finalidad.
- **Operacional**: Complejidad en la definición y aplicación correcta de los procedimientos de otorgamiento, revocación, evidencia y versionado.
- **Técnico**: Riesgo de errores en la lógica que permitan tratamientos de datos sin consentimiento válido o que no registren correctamente la evidencia.
- **Seguridad**: Riesgo de exposición de datos sensibles si se accede a ellos sin un consentimiento válido y verifico.
- **Reputacional**: Riesgo de pérdida de confianza si se descubre que se usaron datos sin el consentimiento adecuado.

### G. Naturaleza de la decisión
MIXED (tiene componentes legales, técnicos y de producto).

### H. Autoridad requerida
DIRECTOR + LEGAL (requiere decisión sobre los procedimientos y validación legal de los requisitos de consentimiento específico).

### I. Estado actual
PENDIENTE

---


---
# FIN DE DIRECTOR DECISION PACK