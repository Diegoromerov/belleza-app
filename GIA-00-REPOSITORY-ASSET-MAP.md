# GIA-00 — REPOSITORY ASSET MAP & REUSE STRATEGY

## 1. MATRIZ MAESTRA DE ACTIVOS ACTUALES

| Activo Tecnológico | Ubicación en Código | Función Actual | Estado | Valor para Glow IA+ | Decisión Estratégica | Justificación | Dependencias |
|---|---|---|:---:|---|:---:|---|---|
| **YouCam S2S Client** | `backend/src/services/biometric/youcam.client.js` | Análisis facial de 4 pasos (scores dérmicos) | 🟢 Producción | Crítico (Sensor Dermal) | **REUTILIZAR** | Provee métricas cuantitativas reproducibles (0-100) para baselines y deltas. | API Key YouCam, S3 |
| **Gemini 3.1 Client** | `backend/src/services/biometric/gemini.client.js` | Visión multimodal de manos y recomendaciones | 🟢 Producción | Crítico (Sensor Manos) | **REUTILIZAR** | Modelo rápido y económico para interpretación no estructurada de manos. | GEMINI_API_KEY |
| **Biometric Orchestrator** | `backend/src/services/biometric/orchestrator.js` | Orquestación paralela con Circuit Breaker | 🟢 Producción | Muy Alto (Ingesta) | **ADAPTAR** | Requiere evolucionar de guardar sólo un `profile` a crear/actualizar un `GlowCycle`. | Breakers, ProfileService |
| **Profile Service** | `backend/src/services/biometric/profile.service.js` | Cifrado AES-256 y persistencia en `beauty_profiles` e historial | 🟢 Producción | Muy Alto (Persistencia) | **ADAPTAR** | Base sólida para modelar la tabla `glow_cycles` y `cycle_measurements`. | PostgreSQL, Crypto |
| **Resilience & Breakers** | `backend/src/services/resilienceService.js`, `circuitBreakerService.js` | Reintentos, backoff, timeouts y breakers (umbral=3) | 🟢 Producción | Crítico (Infraestructura) | **REUTILIZAR** | Blindaje total ante indisponibilidad de proveedores externos. | Centralized Policy |
| **RAG & Vector Store** | `backend/src/services/ragService.js`, `pgvector` | Búsqueda semántica con NVIDIA Embeddings 1024d | 🟢 Producción | Crítico (Grounding) | **ADAPTAR** | Ampliar corpus a protocolos de evolución dérmica y planes temporales. | PostgreSQL, pgvector, NVIDIA |
| **Atena Agent** | `backend/src/services/agents/atenaAgent.js` | Síntesis biométrica, colorimetría e ingredientes | 🟢 Producción | Muy Alto (Diagnóstico) | **ADAPTAR** | Especialista ideal para generar el diagnóstico inicial y evaluar deltas de progreso. | Redis, Postgres |
| **Hestia Agent** | `backend/src/services/agents/hestiaAgent.js` | Personal shopper y recomendación de productos | 🟢 Producción | Muy Alto (Acción/Tienda) | **ADAPTAR** | Conecta el plan de rutina con SKUs reales de GlowStore. | Base de datos `productos` |
| **Hermes Agent** | `backend/src/services/agents/hermesAgent.js` | Búsqueda PostGIS de prestadores y disponibilidad | 🟢 Producción | Muy Alto (Acción/Servicios)| **ADAPTAR** | Permite incluir servicios profesionales en el plan del ciclo. | PostGIS, `services`, `bookings` |
| **Chronos Agent** | `backend/src/services/agents/chronosAgent.js` | Cadencia de tratamientos y re-booking proactivo | 🟢 Producción | Crítico (Seguimiento) | **ADAPTAR** | Base del motor de seguimiento temporal y alertas de re-escaneo/mantenimiento. | `bookings` |
| **AURA Tool Executor** | `backend/src/services/auraToolExecutor.js` | Function calling para agentes LLM | 🟢 Producción | Muy Alto (Orquestación) | **ADAPTAR** | Añadir herramientas para `create_glow_cycle`, `get_active_cycle`, `log_cycle_progress`. | Agentes especializados |
| **Flutter History Screen** | `frontend/lib/screens/profile/biometric_history_screen.dart` | Visualización estática de registros previos | 🟡 Parcial | Alto (UI/UX) | **REINGENIERIZAR** | Transformar de lista plana a Dashboard Interactivo de Evolución de Ciclo ("My Glow"). | Tokens SOUL |

---

## 2. SOBREDIMENSIONAMIENTOS Y AJUSTES DETECTADOS
1. **Doble Capa de Circuit Breaker:** El orquestador envolvía con `breakers.youcam.execute` llamadas que internamente ya usaban `executeWithResilience`. Está controlado y operativo, pero puede simplificarse.
2. **Academia Desconectada del Consumidor:** La Academia no debe ser forzada como paso del Glow Cycle de usuarios B2C; permanece como herramienta de formación para profesionales B2B.
