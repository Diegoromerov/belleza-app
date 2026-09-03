# GIA-03-D — Integration Design Report

## 1. FLUJO DE INTEGRACIÓN FLUTTER $\leftrightarrow$ BACKEND

```text
[ MyGlowDashboardScreen ]
         │
         ▼  (Llamada asíncrona con JWT)
[ ApiService.getActiveGlowCycle() ]
         │
         ▼  GET /api/glow-cycle/active
[ Backend: glowCycleRoutes.js -> glowCycleService.js ]
         │
         ▼  Retorna JSON de ciclo + rutina AM/PM + productos + check-in
[ MyGlowDashboardScreen ]
         │
         ├── Renderiza Estado "Active Cycle" con barra de progreso
         ├── Permite Check-in con POST /api/glow-cycle/:id/checkin
         └── Si hasActiveCycle == false -> Muestra Estado "No Cycle" con botón "Iniciar Glow Cycle"
```

## 2. MODELO DE DATOS EN FLUTTER (`glow_cycle_model.dart`)
- `GlowCycle`: `id`, `cycleType`, `status`, `targetGoal`, `targetMetricKey`, `baselineValue`, `currentValue`, `targetValue`, `durationDays`, `amRoutine`, `pmRoutine`, `recommendedProducts`, `recommendedServices`.

## 3. ESTADO DEL GATE
🟢 **PASS**
