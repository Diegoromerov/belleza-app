# GIA-05-D — Architecture Evolution Report

## 1. ARQUITECTURA ACTUAL (V1 POST-GIA-04)

```text
[ Flutter: MyGlowDashboardScreen ]
         │ (HTTP / JWT)
         ▼
[ Express Router: glowCycleRoutes.js ]
         │
         ├── [ glowCycleService.js ] ── (AES-256) ──> [ PostgreSQL: glow_cycles / glow_cycle_measurements ]
         │         │
         │         ├──> [ Redis Cache ]
         │         └──> [ transformationEngine.js ]
         │                     │
         │                     ├──> [ atenaAgent.js ]
         │                     ├──> [ hestiaAgent.js ] (Opcional GlowStore)
         │                     └──> [ hermesAgent.js ] (Opcional Marketplace)
         │
         └── [ biometricRoutes.js ] ──> [ Orchestrator ] ──> [ YouCam / Gemini ]
```

## 2. ARQUITECTURA EVOLUTIVA RECOMENDADA (V2)
1. **Separación Limpia de Capas:** Mantener `transformationEngine` como orquestador puro desacoplado de la base de datos.
2. **Eventos Asíncronos para Notificaciones:** Conectar `chronosAgent` con notificaciones push en Flutter para recordar rutinas AM/PM y re-escaneos.
3. **Cero Deuda y Cero Dependencias Innecesarias.**
