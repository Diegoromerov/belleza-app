# 🗄️ Database Access Strategy — Coexistencia de Sequelize y pg pool

## 1. Estrategia Oficial de Acceso a PostgreSQL
GlowApp mantiene una arquitectura de acceso dual justificada por requisitos de rendimiento y modelado relacional:

```
[ Capa de Aplicación / Controller ]
       │
       ├──> [ Sequelize ORM ] ──> Modelos Relacionales (User, Booking, Service, Transaction)
       │
       └──> [ pg pool Direct ] ──> Consultas de Alto Rendimiento, POS, RAG Vectorial & Transacciones ACID
```

## 2. Reglas de Uso
1. **Sequelize ORM (`config/database.js`):** Utilizado para la definición de esquemas, relaciones, migraciones y consultas orientadas a objetos.
2. **pg pool (`config/db.js`):** Utilizado para transacciones de alto rendimiento en tiempo real (POS, inventario), bloqueos explícitos (`FOR UPDATE`) y consultas vectoriales (`pgvector`).
