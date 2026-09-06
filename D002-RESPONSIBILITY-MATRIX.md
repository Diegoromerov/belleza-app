# D-002 RESPONSIBILITY MATRIX

## MATRIZ DE RESPONSABILIDADES

| Responsabilidad                     | Glowapp (SaaS) | Cliente (Salón) | Evidencia / Comentario |
|-------------------------------------|----------------|-----------------|------------------------|
| Contratación de personal            | ❌             | ✅              | No existen funcionalidades para publicar vacantes, recibir aplicaciones o realizar contratación. El sistema solo permite registrar usuarios que se autoadministran como prestadores o clientes. |
| Clasificación laboral (empleado vs independiente) | ❌ | ✅ | El sistema actualmente no distingue entre empleado y prestador independiente. Todos los prestadores se tratan igual en términos de tenant_id. La decisión de si una persona es empleado o independiente corresponde al salón. |
| Pago de salarios                    | ❌             | ✅              | No existen funcionalidades de nómina, pago de salarios o retenciones. Los pagos que maneja el sistema son relacionados con servicios prestados por prestadores (comisiones) y no como empleador. |
| Pago de honorarios a prestadores    | ✅ (facilitador) | ✅ (responsable) | El sistema procesa pagos mediante servicios de pago externos (Wompi, Nequi) y permite configurar comisiones. Sin embargo, el salón es quien determina el monto y la responsabilidad del pago recae en él. Glowapp solo facilita la transacción. |
| Afiliación a seguridad social       | ❌             | ✅              | No existen funcionalidades para registrar aportes a seguridad social, pensiones, etc. |
| Administración de relaciones laborales | ❌ | ✅ | No existen funcionalidades para gestionar contratos laborales, vacaciones, incapacidades, etc. |
| Determinación de servicios ofrecidos | ✅ (catálogo) | ✅ (definición) | Glowapp permite crear y gestionar un catálogo de servicios, pero el salón decide qué servicios ofrece y sus precios. |
| Gestión de agendas y disponibilidad | ✅ (herramienta) | ✅ (configuración) | El sistema proporciona una agenda para gestionar citas, pero el salón define la disponibilidad de sus profesionales y prestadores. |
| Asignación de servicios a profesionales | ✅ (herramienta) | ✅ (decisión) | El sistema permite asignar un servicio a un prestador en una cita, pero el salón decide qué prestador realiza qué servicio. |
| Gestión de comisiones               | ✅ (cálculo) | ✅ (configuración) | Glowapp calcula comisiones basado en reglas configurables, pero el salón define el porcentaje y las reglas de comisión. |
| Gestión de permisos y roles         | ✅ (infraestructura) | ✅ (asignación) | El sistema tiene roles (cliente, prestador, admin) y permisos, pero el salón asigna qué usuario tiene qué rol dentro de su tenant. |
| Registro de información contractual | ✅ (almacenamiento) | ✅ (contenido) | El sistema permite almacenar documentos (por ejemplo, URLs a certificaciones), pero el contenido y la validez de los contratos corresponde al salón. |
| Seguimiento operativo (métricas)    | ✅ (reportes) | ✅ (interpretación) | Glowapp proporciona métricas de operación (número de citas, ingresos, etc.), pero el salón es responsable de interpretar y actuar sobre esos datos. |
| Cumplimiento de licencias y certificaciones profesionales | ❌ | ✅ | El sistema permite almacenar URLs a certificaciones, pero no verifica su validez ni asegura que el profesional esté licenciado. |
| Pago de impuestos por servicios       | ✅ (retención) | ✅ (declaración) | El sistema puede retener impuestos (como se indica en los comentarios del código) pero el salón es responsable de la declaración y pago final de impuestos. |
| Terminación de relaciones laborales | ❌ | ✅ | No existen funcionalidades para gestionar despidos, finiquitos, etc. |
| Gestión disciplinaria               | ❌ | ✅ | No existen funcionalidades para aplicar sanciones o advertencias laborales. |
| Protección de datos de los trabajadores | ✅ (seguridad de plataforma) | ✅ (manejo interno) | Glowapp protege los datos almacenados en su plataforma (seguridad de la infraestructura y aplicación), pero el salón es responsable de cómo usa esos datos internamente y de cumplir con leyes de protección de datos respecto a sus empleados. |
| Administración de información (CRUD) | ✅ (herramientas) | ✅ (uso) | Glowapp proporciona las herramientas para crear, leer, actualizar y eliminar datos (usuarios, prestadores, servicios, citas, etc.), pero el salón decide qué datos ingresa y cómo los usa. |

## CONCLUSIONES

- Glowapp actúa exclusivamente como un facilitador tecnológico que proporciona herramientas para la operación del salón.
- Todas las responsabilidades laborales, contractuales y regulatorias corresponden al salón (cliente).
- No existe evidencia en el códigobase de que Glowapp asuma responsabilidad alguna como empleador, intermediario laboral o agente de contratación.
- La arquitectura multi-tenant (D-001) asegura que los datos de cada salón estén aislados, pero no implica responsabilidad sobre los datos mismos más allá de proporcionar almacenamiento seguro y acceso controlado.

## ADVERTENCIA

Cualquier funcionalidad que se parezca a un proceso de empleo (por ejemplo, un módulo de "empleados") debe ser claramente documentada como una herramienta que el salón puede usar para administrar su propio personal, y no como un servicio de empleo proporcionado por Glowapp.

---
*Análisis completado el: $(date)*