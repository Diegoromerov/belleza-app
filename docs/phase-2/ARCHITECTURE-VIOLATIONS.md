# ⚠️ Architecture Violation Map — GlowApp Platform

## Clasificación de Violaciones Arquitectónicas

### 🔴 Categoría A (Crítica)
- **Escrituras Concurrentes sin Transacción en POS:** La función `consumeInventoryItem` en `inventoryController.js` realizaba consultas y actualizaciones separadas sin bloqueo de fila. *(Remediado en GOAL 02 agregando transacciones atómicas con `BEGIN`, `SELECT ... FOR UPDATE` y `COMMIT`)*.

### 🟠 Categoría B (Alta Prioridad)
- **Coexistencia Dual de Acceso DB:** Uso simultáneo de `pg pool` y `Sequelize` sin estrategia unificada. *(Documentado y acotado en `DATABASE-ACCESS-STRATEGY.md`)*.

### 🟡 Categoría C (Prioridad Media)
- **Consultas SQL Directas en Controladores:** Algunos controladores contienen SQL en lugar de delegar a capas de repositorio.
- **Invocaciones Axios Directas en Componentes:** Existen componentes que realizan llamadas HTTP sin pasar por el cliente API unificado.
