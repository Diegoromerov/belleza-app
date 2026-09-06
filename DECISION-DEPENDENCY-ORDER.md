# DECISION-DEPENDENCY-ORDER.md

# ORDER OF DECISION RESOLUTION

Based on the dependency analysis, the following order is proposed for resolving decisions D-001 → D-015:

## 1. Foundational Decision (No Dependencies)
- **D-001**: Estrategia de multi‑tenancy (shared DB/shared schema + RLS vs. separate schema vs. DB por tenant)
  - Reason: Many other decisions depend on having a tenancy strategy defined (for isolating data, applying policies per tenant, etc.).
  - Can be resolved independently (does not depend on any other D-xxx decision).

## 2. Decisions Depending Solely on D-001
Once D-001 is resolved, the following can be addressed (they depend only on D-001):
- **D-004**: Estrategia de retención de datos para RAG y conocimiento organizacional
- **D-005**: Definir el modelo de comisión y su tratamiento contable (ingreso de GlowApp) y si se aplicará IVA o retención en la fuente
- **D-006**: Elegibilidad para usar el fiscal adapter (regímenes, montos)
- **D-007**: Selección de proveedor de pagos alternativos o expansión más allá de NEQUI/Wompi (tarjeta, PSE, efectivo)
- **D-009**: Establecer política de retención y eliminación de datos (definir períodos por tipo de dato, mecanismo de legal hold)
- **D-010**: Definir reglas de activación del fiscal adapter (cuándo un salón debe usar facturación electrónica vía adapter) – also depends on D-006
- **D-011**: Seleccionar proveedor de pagos alternativos o expansión más allá de NEQUI/Wompi (tarjeta, PSE, efectivo) y definir lógica de enrutamiento – also depends on D-007
- **D-012**: Establecer política de uso de IA / RAG (filtrado de datos sensibles, registro de interacciones, opt‑out de uso de datos para mejora de modelos)
- **D-014**: Definir el modelo de comisión (split‑payment vs factura posterior) y su tratamiento contable (IVA, retención en la fuente) – also depends on D-005
- **D-015**: Establecer procedimientos de gestión de consentimientos específicos por finalidad (otorgamiento, revocación, evidencia, versionado)

## 3. Decisions with Additional Dependencies
- **D-010**: also depends on D-006 (elegibilidad del adapter)
- **D-011**: also depends on D-007 (selección de proveedores de pago)
- **D-014**: also depends on D-005 (modelo de comisión)
- **D-008**: Definir niveles de servicio y acuerdos de disponibilidad (uptime, ventanas de mantenimiento, tiempo de respuesta de soporte) – no strong dependencies, but can benefit from D-001 if applying SLAs per tenant.

## 4. Independent Decisions (Can Be Resolved Anytime)
- **D-002**: Alcance de la oferta de fuerza laboral (si se expande a empleados) – no technical dependencies, but may benefit from D-001 for tenant isolation of labor data.
- **D-003**: Modelo de responsabilidad para facturación electrónica futura – NOT APPLICABLE EN FASE 1, no action needed now.
- **D-013**: Aprobar el catálogo de funciones permitidas en fase 1 – ALREADY APPROVED, no action needed.

## 5. Summary of Dependency Chain
- D-001 → (enables) D-004, D-005, D-006, D-007, D-008 (optional), D-009, D-010, D-011, D-012, D-014, D-015
- D-005 → D-014
- D-006 → D-010
- D-007 → D-011

## 6. Recommended Resolution Path
1. Resolve D-001 (multi‑tenancy strategy).
2. With D-001 resolved, resolve D-002, D-004, D-005, D-006, D-007, D-008, D-009, D-012, D-015 (these depend only on D-001 or are independent).
3. After D-005 is resolved, resolve D-014.
4. After D-006 is resolved, resolve D-010.
5. After D-007 is resolved, resolve D-011.
6. D-003 remains NOT APPLICABLE EN FASE 1.
7. D-013 is already APPROVED.

--- 
Note: This order assumes that legal reviews (where required) can proceed in parallel with architectural decisions, but the final approval of a decision as architecturally binding requires both the architectural choice and the legal determination to be available.