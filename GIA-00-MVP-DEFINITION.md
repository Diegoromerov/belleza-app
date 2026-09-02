# GIA-00 — MVP DEFINITION & ROADMAP PROPOSAL

## 1. DEFINICIÓN DEL MVP (GLOW IA+ V1)

### Must Have (Obligatorio en V1):
1. **Glow Cycle — Skin (30 días):**
   - Ingesta biométrica con YouCam.
   - Creación automática de `glow_cycle` con meta cuantificable (ej: hidratación o manchas).
   - Generación de Rutina AM/PM adaptativa con recomendación de 2 productos en GlowStore (Hestia) y 1 servicio en Marketplace (Hermes).
   - Medición de Re-escaneo a los 15 y 30 días calculando el Delta métrico de progreso.
2. **Dashboard de Evolución "My Glow" en Flutter:**
   - Vista activa del ciclo con barra de progreso temporal y métrica de salud dérmica.
   - Acceso directo a la rutina del día y botón de re-escaneo.
3. **Agente Chronos Activo:**
   - Notificaciones y alertas de re-escaneo y seguimiento del ciclo.

### Should Have (V1.5):
1. **Glow Cycle — Hands:** Integración de evolución de manos y cutículas con Gemini 3.1 Flash-Lite.
2. **Comparador Visual Split-Screen:** Visualización antes/después con auditoría de privacidad cero-huella.

### Could Have (V2):
1. **Glow Cycle — Color & Makeup:** Visajismo y VTO adaptativo según el tono de piel del ciclo.
2. **Glow Cycle — Beauty Goal:** Paquetes multi-dominio (Piel + Manos + Maquillaje para eventos).

### Future (V3):
1. **Glow Cycle — Hair:** Diagnóstico tricológico y capilar.

---

## 2. ROADMAP SECUENCIAL DE IMPLEMENTACIÓN (POST GIA-00)

```text
┌────────────────────────────────────────────────────────┐
│  MISIÓN GIA-01: GLOW CYCLE ENGINE CORE & DATA SCHEMA   │
│  - Creación de tablas glow_cycles y measurements       │
│  - Endpoints REST (/api/glow-cycle/create, /active, etc│
│  - Integración de Atena + Chronos para gestión de ciclo│
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│  MISIÓN GIA-02: ADAPTIVE ROUTINE & COMMERCE CONVERGENCE│
│  - Formulación de planes AM/PM conectados a GlowStore  │
│  - Integración con Hestia y Hermes para compras/citas  │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│  MISIÓN GIA-03: "MY GLOW" FLUTTER EVOLUTION DASHBOARD  │
│  - Reingeniería de biometric_history_screen.dart       │
│  - Visualizador de evolución, deltas y check-in diario │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│  MISIÓN GIA-04: RE-SCANNING, DELTA EVALUATOR & RELEASE │
│  - Pipeline de re-escaneo comparativo a los 15/30 días │
│  - Pruebas E2E de ciclo completo y verificación final  │
└────────────────────────────────────────────────────────┘
```
