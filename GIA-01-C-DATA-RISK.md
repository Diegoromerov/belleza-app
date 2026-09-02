# GIA-01-C — Data Model & Risk Report

## 1. ESPECIFICACIÓN DEL ESQUEMA PERSISTENTE

Para evitar sobre-normalización, consolidamos el motor en dos tablas de alta eficiencia:
1. `glow_cycles`: Contiene la identidad, estado, tipo, meta cuantificable, fechas, resumen del plan, rutina AM/PM (JSONB), productos y servicios asociados.
2. `glow_cycle_measurements`: Contiene los hitos de medición, scores cifrados (AES-256), deltas calculados y notas clínicas de Atena.

## 2. MATRIZ DE RIESGOS TÉCNICOS Y DE DATOS

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| **R-01: Múltiples ciclos activos conflictivos del mismo tipo** | Baja | Media | Constraint condicional / regla de negocio: Máximo 1 ciclo activo por tipo por usuario. |
| **R-02: Exposición de scores biométricos en reposo** | Baja | Alta | Reutilización estricta de `biometricCryptoService.js` (cifrado AES-256-GCM). |
| **R-03: Pérdida de integridad referencial al borrar usuario** | Baja | Alta | `ON DELETE CASCADE` con `usuarios(id)` respetando Habeas Data. |
| **R-04: Degradación en cálculo de Deltas si el baseline es nulo** | Baja | Media | Fallback algorítmico determinista: Si no hay baseline previo, $\Delta = 0$ y se registra como medición 1. |

## 3. ESTADO DEL GATE
🟢 **PASS**
