# D-002 OPTION COMPARISON

| Criterion                      | Option A: Operativa Inicial (Solo operación del salón) | Option B: Operación + Empleados (Gestión formal de empleados) | Option C: Modelo Híbrido (Preparado para futuro) |
| ------------------------------ | ----------------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------- |
| Complejidad                    | Baja                                                  | Alta                                                         | Media                                             |
| Time-to-market                 | Más rápido                                            | Más lento                                                    | Medio                                             |
| Arquitectura                   | No requiere cambios mayores en el modelo de datos     | Requiere nuevas entidades (empleado, contrato, etc.) y relaciones | Requiere extensión genérica del modelo (worker_type) sin entidades fijas |
| Seguridad                      | Menor superficie de ataque                            | Requiere manejo de datos laborales sensibles                 | Similar a B pero con diseño genérico              |
| Multi-tenancy                  | Ya resuelto por D-001                                 | Debe extenderse a nuevas tablas (empleado, etc.) con tenant_id | Debe asegurar que cualquier nueva tabla tenga tenant_id y RLS si corresponde |
| Operación del salón            | Soportada completamente                               | Soportada, con capacidad adicional de gestión de empleados   | Soportada, con preparación para futura gestión de empleados |
| Profesionales independientes   | Soportados como prestadores                           | Soportados, pero requiere distinguir entre independientes y empleados | Soportados con mecanismo de diferenciación        |
| Empleados                      | No soportados                                         | Soportados completamente                                     | Diseñado para ser añadido fácilmente en el futuro |
| Escalabilidad                  | Alta                                                  | Menor debido a mayor complejidad                             | Alta (diseño genérico)                            |
| UX                             | Más simple                                            | Más complejo (más pantallas, flujos)                         | Medio (interfaz preparada pero no cargada)        |
| Riesgo                         | Bajo (no se asume responsabilidad laboral)            | Alto (potencial responsabilidad legal como empleador)        | Medio (depende de cómo se implementa la preparación) |
| Costo de implementación        | Bajo                                                  | Alto                                                         | Medio                                             |
| Coherencia con SaaS operativo  | Alta (enfocado en operación del salón)                | Menor (desvía enfoque hacia HR)                              | Alta (mantiene enfoque operativo con camino claro) |
| Evolución futura               | Requiere rediseño para añadir empleados               | Ya incluye empleados, pero puede ser sobre-diseñado si no se necesita | Diseñado para evolución suave hacia empleados     |

## CONCLUSIÓN

La opción C (Modelo Híbrido) ofrece el mejor equilibrio entre satisfacer las necesidades actuales y preparar el sistema para una futura expansión hacia la gestión de empleados sin incurrir en los costos y riesgos de una implementación completa ahora.

Se recomienda adoptar un enfoque genérico que permita añadir atributos de empleado (como tipo de trabajador, salario, rol, etc.) cuando sea necesario, sin cambiar radicalmente el modelo de datos actual.