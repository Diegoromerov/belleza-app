# GIA-00 — GAP ANALYSIS & ENGINEERING REQUIREMENTS

## 1. ANÁLISIS DE BRECHAS PARA LA CONSTRUCCIÓN DE GLOW IA+

| Dominio | Estado Actual (Baseline) | Estado Objetivo (Glow IA+) | Brecha Técnica (Gap) | Reingeniería Requerida |
|---|---|---|---|---|
| **Modelo de Ciclo** | Diagnóstico puntual en `beauty_profiles` | Ciclos continuos con fecha inicio/fin, metas y estado | Falta modelo relacional de `glow_cycles` y `measurements` | **Media:** Crear migración SQL y servicio `glowCycleService.js`. |
| **Evaluación de Progreso** | No existe comparación entre escaneos previos | Cálculo automatizado de Deltas métricos (`hydration_delta`, etc.) | Falta lógica de comparación longitudinal en Atena | **Baja:** Agregar método `evaluateDelta(prev, current)` en `atenaAgent.js`. |
| **Rutina Adaptativa** | Texto plano de recomendación generado por LLM | Estructura JSON interactiva de pasos AM/PM ligada a productos | Falta formateador estructurado de rutinas | **Media:** Estandarizar prompt y schema JSON de salida en `geminiClient`/`deepseekClient`. |
| **Integración E-Commerce** | `hestiaAgent.js` consulta productos pero no guarda carrito de ciclo | Carrito pre-armado con 1-click checkout para el ciclo | Falta endpoint para convertir plan en orden de compra | **Baja:** Integrar con `productRoutes.js` y `paymentRoutes.js`. |
| **Frontend Dashboard** | Pantalla estática `biometric_history_screen.dart` | Dashboard interactivo "My Glow" con progreso y check-in | Falta pantalla principal de ciclo activo y visualizador de deltas | **Media:** Reingeniería visual de la pantalla de historial a "My Glow Dashboard". |
| **Seguimiento Cron** | `chronosAgent.js` evalúa citas pasadas | Disparo proactivo de recordatorios de re-escaneo a los 15/30 días | Falta cron/worker de alertas de ciclo | **Baja:** Extender `backgroundWorkerService.js` / `loyaltyCron.js`. |
