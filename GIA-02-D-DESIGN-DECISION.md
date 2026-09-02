# GIA-02-D — Design Decision Report

## 1. DISTRIBUCIÓN DE RESPONSABILIDADES

* **Glow Cycle Core (`glowCycleService.js`):** Persistencia de ciclo, ciclo de vida, mediciones y deltas.
* **Transformation Engine (`transformationEngine.js`):** Orquestador de la formulación del plan. Recibe diagnóstico y meta, convoca a los agentes correspondientes y genera la rutina adaptativa.
* **Atena Agent (`atenaAgent.js`):** Determina prioridades dérmicas e ingredientes activos compatibles.
* **Hestia Agent (`hestiaAgent.js`):** Resuelve los productos de GlowStore que contienen los ingredientes sugeridos.
* **Hermes Agent (`hermesAgent.js`):** Resuelve servicios presenciales del Marketplace si la intervención lo requiere.
* **Chronos Agent (`chronosAgent.js`):** Determina la cadencia diaria (horarios sugeridos AM/PM) y los días de re-escaneo.

## 2. FUENTE DE LA VERDAD (SOURCE OF TRUTH)
* **El plan activo:** `glow_cycles.am_routine` y `glow_cycles.pm_routine`.
* **Las intervenciones y compras:** `glow_cycles.recommended_product_ids` y `glow_cycles.recommended_service_ids`.
* **Las adaptaciones:** Actualizaciones en `glow_cycles` con registro en `glow_cycle_measurements.ai_evaluation_notes`.

## 3. ESTADO DEL GATE
🟢 **PASS**
