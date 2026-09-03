# D001-MULTITENANCY-COMPARISON.md

# COMPARISON OF MULTI-TENANCY ARCHITECTURES FOR GLOWAPP

| Criterio | A – Shared Schema + tenant_id | B – Shared Schema + tenant_id + RLS | C – Schema-per-tenant | D – Database-per-tenant |
|----------|-------------------------------|--------------------------------------|------------------------|--------------------------|
| **Descripción** | Añadir columna tenant_id a tablas y filtrar en la aplicación. | Como A, pero añadir políticas de Row Level Security en PostgreSQL. | Cada tenant tiene su propio esquema dentro de la misma BD. | Cada tenant tiene su propia base de datos física. |
| **Evidencia actual** | No existe tenant_id. | No existe tenant_id ni RLS. | No existen esquemas separados. | Solo una BD configurada. |
| **Infraestructura requerida** | PostgreSQL (ya presente). | PostgreSQL con RLS (versión 9.5+). | PostgreSQL con capacidad de múltiples esquemas. | múltiples instancias de PostgreSQL o múltiples bases de datos. |
| **Escalabilidad (número de tenants)** | Alta (miles a decenas de miles con buen índice). | Alta (similar a A). | Media-Baja (cientos a pocos miles; miles de esquemas pueden overhead). | Baja-Media (decenas a cientos de tenants; overhead de conexiones y mantenimiento). |
| **Complejidad de implementación** | Baja-Media (migraciones, actualización de queries). | Media (además de A, definir y probar políticas RLS). | Media-Alta (lógica de cambio de esquema, posible uso de SET search_path). | Alta (gestionar múltiples pools de conexión, migraciones por DB). |
| **Costo de infraestructura** | Bajo (usa recursos existentes). | Bajo (usa recursos existentes). | Medio (más complejo de gestionar esquemas). | Alto (requiere múltiples instancias o BDs). |
| **Costo operativo** | Bajo (backups, monitoreo simples). | Bajo (similar a A, plus revisión de políticas). | Medio (backups y migraciones por esquema). | Alto (backups, monitoreo, actualizaciones por cada BD). |
| **Seguridad contra acceso horizontal** | Depende de correcto filtrado en aplicación (riesgo si se omite un where). | Alta (la BD en sí misma enforca el filtrado; reduce riesgo de error de aplicación). | Buena (aislamiento a nivel de esquema, depende de correcto enrutamiento). | Muy Alta (aislamiento total a nivel de instancia). |
| **Facilidad de hacer consultas cruzadas entre tenants** | Fácil (misma tabla, pero requiere filtrado explícito si se quiere). | Fácil (similar a A). | Difícil (requiere cambiar de esquema o usar union). | Muy difícil (requiere federación o ETL). |
| **Facilidad de cambiar de estrategia en el futuro** | Media (se puede añadir RLS luego). | Baja (ya tiene RLS; quitarlo sería regresivo). | Media (se puede migrar a shared schema o DB-per-tenant). | Baja (cambiar a otra estrategia implica gran esfuerzo). |
| **Impacto en rendimiento de lectura** | Bueno con índice en tenant_id. | Bueno (RLS agrega pequeña sobrecarga). | Bueno (cada esquema es independiente). | Bueno (cada BD es independiente). |
| **Impacto en rendimiento de escritura** | Bueno. | Bueno. | Bueno. | Bueno. |
| **Necesidad de backfill de datos existentes** | Sí (añadir tenant_id y poblarlo). | Sí (igual que A). | Sí (migrar datos a esquemas separados). | Sí (migrar datos a nuevas BDs). |
| **Ejemplos de uso en industria** | SaaS medio-grande (ej. aplicaciones de gestión con cientos de clientes). | SaaS que requiere alta seguridad (ej. fintech, salud). | Menos común; usado cuando se necesita aislamiento parcial pero no total. | Alto aislamiento requerido (ej. instituciones financieras, gobiernos). |
| **Compatibilidad con herramientas existentes (Sequelize, pgPool)** | Alta (solo añadir condición where). | Alta (igual que A, plus posible uso de variables de sesión). | Media (requiere cambiar search_path o usar esquemas en nombre de tabla). | Media-Alta (requiere múltiples pools de conexión y selección dinámica). |
| **Complejidad de pruebas** | Media (probar que el filtro se aplique en todas las queries). | Media (además de A, probar políticas RLS). | Media-Alta (probar enrutamiento de esquema y aislado). | Alta (probar múltiples pools, aislado y consistencia). |
| **Dependencia de versión de PostgreSQL** | Cualquier versión soportada. | 9.5+ para RLS. | Cualquier versión. | Cualquier versión. |
| **Conclusión rápida** | Buen punto de partida si se quiere simplicidad y se puede garantizar filtrado en aplicación. | Recomendado cuando se busca equilibrio entre simplicidad, seguridad y costo. | Útil cuando se necesita algún nivel de aislamiento pero se quiere evitar múltiples BDs. | Sólo cuando se requiere el máximo aislamiento y se acepta el costo operativo. |

---
Fin de la comparación.