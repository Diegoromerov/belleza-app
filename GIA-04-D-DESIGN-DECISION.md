# GIA-04-D — Design Decision Report

## 1. ESPECIFICACIÓN DE ENDPOINTS Y CONTROLADORES

### A. Endpoint de Re-Scanning & Evaluación
* **Ruta:** `POST /api/glow-cycle/:id/re-scan`
* **Entrada:** `faceImage`, `handsImage`, `dayNumber` (ej. 15 o 30).
* **Flujo Interno:**
  1. Ejecuta análisis bio-óptico con YouCam / Gemini bajo resiliencia.
  2. Extrae scores numéricos.
  3. Consulta baseline $S_0$ y cálculo de adherencia $A$ desde `checkin_history`.
  4. Calcula Delta y genera decisión con `transformationEngine.js`.
  5. Inserta registro en `glow_cycle_measurements`.
  6. Actualiza `glow_cycles` con nuevo estado y rutina adaptada.

### B. Endpoint de Transición / Cierre
* **Ruta:** `POST /api/glow-cycle/:id/graduate`
* **Función:** Cierra formalmente un ciclo completado y permite iniciar el siguiente ciclo secuencial con un nuevo objetivo.

## 2. ESTADO DEL GATE
🟢 **PASS**
