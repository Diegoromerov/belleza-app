# IMPLEMENTATION-BLOCKERS.md

# BLOQUEADOS PARA IMPLEMENTACIÓN TÉCNICA

Basado en el análisis de dependencias y estado de decisiones, los siguientes elementos bloquean el inicio de la implementación técnica de componentes foundation:

## 1. Decisiones Pendientes (Bloqueadores Principales)

Todas las decisiones D-001 → D-015 que están en estado PENDIENTE o NOT APPLICABLE EN FASE 1 (excepto D-013 APROBADO) bloquean la implementación porque son prerrequisitos para los componentes técnicos identificados en el IMPLEMENTATION MAP.

### Decisiones que bloquean directamente componentes:
- **D-001 (Multi-tenancy)**: Bloquea cualquier componente que requiera aislamiento por tenant (prácticamente todos: gestión de consentimientos, auditoría, retención, pagos mejorados, gobernanza de IA, seguridad básica, flujos de registro/reserva con consentimiento, fiscal adapter).
- **D-004 (Retención RAG)**: Bloquea la estrategia de retención para conocimiento organizacional.
- **D-005 (Modelo de comisión y tratamiento tributario)**: Bloquea la definición clara de cómo se reconocerán los ingresos de GlowApp y el cálculo de comisión.
- **D-006 (Elegibilidad fiscal adapter)**: Bloquea la definición de quién puede usar el adapter.
- **D-007 (Selección de proveedores de pago alternativos)**: Bloquea la expansión más allá de NEQUI.
- **D-008 (SLA/uptime)**: Bloquea la definición de niveles de servicio.
- **D-009 (Política de retención general)**: Bloquea la definición de períodos de retención y legal hold.
- **D-010 (Reglas de activación fiscal adapter)**: Bloquea cuándo se activa el adapter.
- **D-011 (Lógica de enrutamiento de pagos)**: Bloquea la definición de cómo se dirigen transacciones a distintos PSPs.
- **D-012 (Política de uso de IA/RAG)**: Bloquea la implementación de filtrado y registro de interacciones IA.
- **D-014 (Modelo de comisión split vs posterior)**: Bloquea la elección entre los dos modelos específicos de comisión.
- **D-015 (Gestión de consentimientos específicos)**: Bloquea la implementación de tabla de consentimientos, API y middleware.

### Decisiones que no bloquean directamente pero requieren resolución:
- **D-002 (Alcance de fuerza laboral)**: Si se decide ofrecer, requeriría nuevos componentes; si no se ofrece, no bloquea el núcleo actual pero sí define el alcance del producto.
- **D-003 (Responsabilidad facturación electrónica futura)**: NOT APPLICABLE EN FASE 1, no bloquea la fase actual.

## 2. Requerimientos Legales Pendientes (Bloqueadores Secundarios)

Muchas decisiones técnicas dependen de una determinación jurídica previa antes de poder definirse como requisitos arquitectónicos definitivos. Estos incluyen:

- **Consentimiento específico por finalidad (Ley 1581 art. 7)**: Requerido para D-015 y afecta a flujos de registro, reserva, IA, etc.
- **Deber de conservación y supresión (Ley 1581 art. 8)**: Requerido para D-004 y D-009.
- **Deber de seguridad (Ley 1581 art. 10)**: Requerido para D-012 y respalda middleware de seguridad básica.
- **Tratamiento de datos personales en IA (SIC Circ. 022/2023)**: Requerido para D-004 y D-012.
- **Normas de establecimientos de pago (Ley 527/1999) y PCI DSS**: Requerido para D-007 y D-011.
- **Protección contra llamadas comerciales (Ley 2300/2023)**: Requerido si se implementan funcionalidades de marketing (aunque no tiene D específica, está relacionada con decisiones de comunicación).
- **Norma tributaria y DIAN (facturación electrónica)**: Requerido para D-003, D-006, D-010.
- **Ley 2080/2021 (OPSR)**: Requerido para determinar si GlowApp debe reportar transacciones a DIAN.
- **Legislación laboral colombiana**: Requerido para D-002 si se decide ofrecer gestión de fuerza laboral.

Hasta que estas determinaciones legales estén disponibles, las decisiones técnicas que dependen de ellas no pueden aprobarse como requisitos definitivos, lo que bloquea la implementación de los componentes asociados.

## 3. Dependencias Técnicas No Resueltas

Incluso si se tomaran decisiones arquitectónicas, algunas dependencias técnicas permanecen pendientes:

- **Herramientas de migración y backfill**: Necesarias para aplicar cambios de esquema (añadir tenant_id, nuevas tablas).
- **Disponibilidad de PSPs alternativos**: Para decidir qué proveedores integrar.
- **Infraestructura de monitoreo y alertas**: Para implementar SLA y health checks.
- **Servicios de IA externos**: Para integrar la capa de gobernanza de IA (requiere contratos y claves de API).
- **Herramientas de programación de trabajos cron**: Para implementar trabajo cron de retención, eliminación segura y conciliación diaria.

## 4. Conclusión

**No hay ningún componente técnico listo para implementación inmediata** porque:
1. La mayoría dependen de decisiones arquitectónicas pendientes (especialmente D-001).
2. Muchas dependen además de determinaciones jurídicas externas.
3. Algunas requieren recursos o herramientas externas que no están disponibles en el alcance actual.

El trabajo técnico solo puede comenzar después de:
- Resolución de las decisiones pendientes D-001 → D-015 (excepto D-003 y D-013).
- Obtención de las determinaciones jurídicas requeridas.
- Definición de los requisitos técnicos derivados.
- Disponibilidad de las herramientas y recursos necesarios para la implementación.

Hasta entonces, el equipo debe limitarse a actividades de descubrimiento, documentación y preparación, evitando cualquier modificación de código, esquema, configuración o instalación de dependencias.

--- 
Fin del documento.