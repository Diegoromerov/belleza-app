# GIA-04-B — Architecture & Temporal Model Report

## 1. MODELO TEMPORAL LONGITUDINAL (LINEA DE EVOLUCIÓN)

```text
[ CICLO ACTIVO: Día 1 a Día 30 ]
   │
   ├── T0 (Día 1)  : Medición Baseline S0 (YouCam / Gemini) -> Generación de Plan Inicial
   ├── T1..14      : Ejecución Diaria de Rutina AM/PM -> Check-ins de Adherencia (A)
   ├── T15 (Día 15): Re-escaneo Intermedio S1 -> Cálculo Δ1 = S1 - S0 -> Decisión Adaptativa
   ├── T16..29     : Ejecución de Rutina Adaptada -> Check-ins
   └── T30 (Día 30): Re-escaneo Final S2 -> Cálculo ΔTotal = S2 - S0 -> Evaluación Cierre & Nuevo Ciclo
```

## 2. ESTRUCTURA DE MEDICIONES SUCESIVAS
Cada registro en `glow_cycle_measurements` mantiene:
- `day_number`: 1, 15, 30, etc.
- `measurement_type`: `baseline`, `milestone_15d`, `final_30d`, `reassessment`.
- `score_delta`: Diferencial exacto respecto al baseline.
- `ai_evaluation_notes`: Diagnóstico de evolución emitido por Atena.

## 3. ESTADO DEL GATE
🟢 **PASS**
