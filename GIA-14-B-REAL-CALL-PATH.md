# GIA-14-B — Real Call Path Report

## 1. TRAZABILIDAD Y CLASIFICACIÓN DE CADA ETAPA DEL CALL PATH

| Etapa | Componente Responsable | Ejecución Real | Clasificación |
|---|---|---|:---:|
| **1. UI Trigger** | `main.dart` (Icons.auto_awesome) | Navegación a `/my-glow` | **REAL** |
| **2. Auth Layer** | `middleware/auth.js` | Validación token JWT (`req.user.id`) | **REAL** |
| **3. API Routing** | `routes/glowCycleRoutes.js` | Enrutamiento Express con traceId | **REAL** |
| **4. Cycle Service** | `services/glowCycleService.js` | Lógica de negocio y persistencia | **REAL** |
| **5. Engine & Atena**| `services/transformationEngine.js` | Generación y adaptación de rutinas | **REAL** |
| **6. Chronos Agent**| `services/agents/chronosAgent.js` | Evaluación de hitos de continuidad | **REAL** |
| **7. Hestia / Hermes**| `services/transformationEngine.js` | Productos y servicios subordinados | **REAL** |
| **8. Bio Ingestion** | `youcam.client.js` / `gemini.client.js` | Circuit breakers con fallback seguro | **REAL** |
| **9. Persistencia** | PostgreSQL (`pool.query`) | Inserción/actualización con ACID | **REAL** |
| **10. Caché** | Redis (`CYCLE_CACHE_TTL = 3600`) | Aceleración de lectura con bypass | **REAL** |
| **11. Observabilidad**| Winston Logger (`logger.js`) | Logs estructurados con `traceId` | **REAL** |
| **12. Knowledge RAG** | `pgvector` en PostgreSQL | Búsqueda semántica para catálogo | **DORMANT** |

## 2. ESTADO DEL GATE
🟢 **PASS**
