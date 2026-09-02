# GIA-00 — MASTER DISCOVERY DOCUMENT

## 1. QUÉ TENEMOS
GlowApp posee una infraestructura técnica de primer nivel completamente funcional y validada en resiliencia (F7.001 a F7.009):
- Sensor facial S2S con YouCam API y sensor multimodal de manos con Gemini 3.1 Flash-Lite.
- Swarm de agentes especializados (Atena, Hestia, Hermes, Chronos, Valkyrie) y RAG sobre pgvector con embeddings NVIDIA de 1024 dimensiones.
- E-Commerce (GlowStore) con pasarela Wompi y Marketplace de servicios con geolocalización PostGIS.
- Cifrado AES-256 en reposo y guardias inmutables de consentimiento biométrico.

## 2. QUÉ QUEREMOS CONSTRUIR
Transformar este ecosistema en **Glow IA+**, el primer sistema de **evolución beauty en bucle cerrado basado en Glow Cycles (PHVA de 30 días)**, donde el usuario no solo recibe un escaneo puntual, sino que se compromete con un objetivo medible, ejecuta un plan adaptativo y valida su progreso real con re-escaneos comparativos.

## 3. QUÉ FUNCIONA, QUÉ NO FUNCIONA Y QUÉ FALTA
* **Funciona:** Ingesta biométrica, Circuit Breakers, fallbacks, búsqueda vectorial, recomendación de productos y geolocalización de citas.
* **No Funciona / Falta:** Persistencia de ciclos temporales (`glow_cycles`), cálculo automatizado de deltas evolutivos entre escaneos, y dashboard interactivo de seguimiento de rutina en el cliente Flutter.

## 4. ESTRATEGIA DE REUTILIZACIÓN, ADAPTACIÓN Y REINGENIERÍA
* **Reutilizar (100%):** `youcam.client.js`, `gemini.client.js`, `resilienceService.js`, `circuitBreakerService.js`, `ragService.js`.
* **Adaptar:** `biometricOrchestrator.js`, `atenaAgent.js`, `hestiaAgent.js`, `chronosAgent.js`, `auraToolExecutor.js`.
* **Reingenierizar / Crear:** `glowCycleService.js`, tabla `glow_cycles`, y pantalla "My Glow" en Flutter.

## 5. CÓMO CONSTRUIR EL MVP (GLOW CYCLE — SKIN)
1. Iniciar con **Glow Cycle — Skin de 30 días**: Meta en hidratación/poros/manchas.
2. Formular plan interactivo AM/PM con 2 productos sugeridos de GlowStore y 1 servicio del Marketplace.
3. Hitos de re-escaneo en día 15 y 30 para cálculo de progreso (Delta).

## 6. ROADMAP DE IMPLEMENTACIÓN PROPUESTO
- **GIA-01:** Glow Cycle Engine Core & Data Schema (Backend & Agentes).
- **GIA-02:** Adaptive Routine & Commerce Convergence (GlowStore + Marketplace).
- **GIA-03:** "My Glow" Flutter Evolution Dashboard.
- **GIA-04:** Re-scanning, Delta Evaluator & Release V1.
