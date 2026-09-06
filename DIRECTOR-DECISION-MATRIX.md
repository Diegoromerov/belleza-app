# DIRECTOR-DECISION-MATRIX

| ID | Decisión | Tipo | Estado | Director | Legal | Dependencia bloqueante | Implementable |
|----|----------|------|--------|----------|-------|------------------------|---------------|
| D-001 | Estrategia de multi‑tenancy (shared DB/shared schema + RLS vs. separate schema vs. DB por tenant) | ARCHITECTURAL | PENDIENTE | YES | NO | N/A | NO |
| D-002 | Alcance de la oferta de fuerza laboral (si se expande a empleados) | PRODUCT | PENDIENTE | YES | NO | N/A | NO |
| D-003 | Modelo de responsabilidad para facturación electrónica futura | LEGAL | NOT APPLICABLE EN FASE 1 | YES | YES | N/A | NO (not applicable in fase 1) |
| D-004 | Estrategia de retención de datos para RAG y conocimiento organizacional | MIXED | PENDIENTE | YES | YES | D-001 (multi‑tenancy) | NO |
| D-005 | Definir el modelo de comisión y su tratamiento contable (ingreso de GlowApp) y si se aplicará IVA o retención en la fuente | MIXED | PENDIENTE | YES | YES | D-001 (multi‑tenancy) | NO |
| D-006 | Elegibilidad para usar el fiscal adapter (regímenes, montos) | MIXED | PENDIENTE | YES | YES | D-001 (multi‑tenancy) | NO |
| D-007 | Selección de proveedor de pagos alternativos o expansión más allá de NEQUI/Wompi (tarjeta, PSE, efectivo) | MIXED | PENDIENTE | YES | YES | D-001 (multi‑tenancy) | NO |
| D-008 | Definir niveles de servicio y acuerdos de disponibilidad (uptime, ventanas de mantenimiento, tiempo de respuesta de soporte) | MIXED | PENDIENTE | YES | NO | N/A | NO |
| D-009 | Establecer política de retención y eliminación de datos (definir períodos por tipo de dato, mecanismo de legal hold) | MIXED | PENDIENTE | YES | YES | D-001 (multi‑tenancy) | NO |
| D-010 | Definir reglas de activación del fiscal adapter (cuándo un salón debe usar facturación electrónica vía adapter) | MIXED | PENDIENTE | YES | YES | D-001 (multi‑tenancy), D-006 (elegibilidad adapter) | NO |
| D-011 | Seleccionar proveedor de pagos alternativos o expansión más allá de NEQUI/Wompi (tarjeta, PSE, efectivo) y definir lógica de enrutamiento | MIXED | PENDIENTE | YES | YES | D-001 (multi‑tenancy), D-007 (selección de proveedores) | NO |
| D-012 | Establecer política de uso de IA / RAG (filtrado de datos sensibles, registro de interacciones, opt‑out de uso de datos para mejora de modelos) | MIXED | PENDIENTE | YES | YES | D-001 (multi‑tenancy) | NO |
| D-013 | Aprobar el catálogo de funciones permitidas en fase 1 (ver sección 22 HARD BOUNDARY MATRIX) | PRODUCT | APROBADO | YES | NO | N/A | YES |
| D-014 | Definir el modelo de comisión (split‑payment vs factura posterior) y su tratamiento contable (IVA, retención en la fuente) | MIXED | PENDIENTE | YES | YES | D-001 (multi‑tenancy), D-005 (modelo de comisión) | NO |
| D-015 | Establecer procedimientos de gestión de consentimientos específicos por finalidad (otorgamiento, revocación, evidencia, versionado) | MIXED | PENDIENTE | YES | YES | D-001 (multi‑tenancy) | NO |

**Leyenda**:
- Director: YES si se requiere decisión del Director, NO en caso contrario.
- Legal: YES si se requiere revisión/juicio legal, NO en caso contrario.
- Dependencia bloqueante: ID de otra decisión que debe resolverse primero para que ésta pueda considerarse implementable; N/A si no hay dependencia bloqueante.
- Implementable: YES si la decisión está aprobada y no tiene dependencia bloqueante; NO si está pendiente, not applicable o tiene bloqueante; CONDITIONAL si depende de una decisión pendiente pero podría ser considerada implementable una vez resuelta esa dependencia (en esta tabla usamos NO para simplificar, ya que todas las dependientes son de decisiones pendientes).