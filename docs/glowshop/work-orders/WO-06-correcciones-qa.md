# WORK ORDER 6/6 — Correcciones de la entrega WO-05 (QA)

## REGISTRO DE REGLAS DE PRUEBA Y BASE DE DATOS

### Regla Fundamental de Aislamiento de Catálogo en Pruebas
1. **Ningún script de prueba o guardián borra ni "normaliza" el catálogo global de la base de datos**.
2. Si un borrado o modificación hace falta durante una prueba, debe realizarse de forma estricta utilizando una cláusula `WHERE` sobre las llaves primarias (`id`) creadas exclusivamente por el propio script de prueba dentro de su ciclo de vida execution/cleanup (`finally`).

---

## INCIDENTE DE DATOS — INFORME DE AUDITORÍA Y REMEDIACIÓN

### Contexto del Incidente
Durante la ejecución de las pruebas previas de control de calidad del WO-05, se crearon scripts auxiliares no versionados (`clean_db_baseline.js`, `sync_baseline.js`, `list_prods.js`, `check_plat.js`) con el objetivo de verificar el esquema y estado de las tablas del catálogo.

### Causa Raíz e Impacto
- **Scripts Auxiliares**: Ejecutaron limpiezas y sincronicidades asumiendo un subconjunto de 130 productos de prueba.
- **Impacto en Catálogo**: Esto redujo temporalmente el número de filas de 296 a 130 en la base de datos local de desarrollo, eliminando 6 productos de la línea masculina y reescribiendo 2 precios del nivel cliente.
- **Acción Inmediata**: Los 4 scripts auxiliares fueron eliminados del árbol de trabajo.

### Restauración Realizada
El director ejecutó la restauración completa e idempotente del catálogo mediante el script `docs/glowshop-2026-09-24/restore_catalogo_a0.sql` (commit `3337aadb` en `feat/glowshop-niveles-a0`), dejando la base de datos verificada con:
- **296 productos** en la tabla `productos`.
- **296 precios de nivel cliente** en `precios_producto`.
- **16 nombres distintos** de productos.
- Restablecimiento de los atributos originales y categorías de la línea masculina (`Barba & Bigote`, `Corte & Capilar`, `Grooming`, `Skincare Masculino`) desde `migrations/011_seed_mens_products.sql`.
- Precios de los productos 1 y 2 restaurados a $45,000 y $38,000 respectivamente.

---

## REMEDIACIONES EN CÓDIGO (WO-06)

1. **`backend/src/config/db.js`**:
   - Eliminación completa de `memoryTransactions` y del bloque cortocircuito `if (queryStr.includes('TRANSACTIONS'))` que fabricaba transacciones con estado por defecto `'APPROVED'`.
   - Delegación transparente a `pgMemory.adapter.query` (PostgreSQL real en memoria con tabla `transactions` declarada en esquema SQL).

2. **`backend/scripts/verifyNoFabricatedPayments.js`**:
   - Incorporación de la regla `R5` para detectar cualquier fallback de estado por defecto (`status: <expr> || 'APPROVED'`, `?? 'PAGADO'`, etc.) en la ruta del dinero.
   - Verificación de salida con código de error (exit 1) al detectar fabricación de pagos.

3. **`backend/src/controllers/productController.js`**:
   - Eliminación del fallback `|| 1` en la resolución de `tenantId` en `createProduct`.
   - Si no se puede determinar `tenant_id` del usuario ni del contexto de plataforma (`SELECT app_platform_tenant_id()`), el controlador responde con HTTP 500 explícito en lugar de usar un tenant por defecto.
