# GIA-02-B — Domain & Architecture Design Report

## 1. DEFINICIÓN DEL MODELO DE TRANSFORMACIÓN ADAPTATIVA

```text
               ┌─────────────────────────────────────────┐
               │         DIAGNOSIS (Atena / YouCam)      │
               │  - Scores: Hidratación 54, Poros 42     │
               └────────────────────┬────────────────────┘
                                    │
                                    ▼
               ┌─────────────────────────────────────────┐
               │           GOAL & PRIORITIES             │
               │  - Meta: Elevar Hidratación a 75        │
               │  - Prioridad: Barrera cutánea + Poros   │
               └────────────────────┬────────────────────┘
                                    │
                                    ▼
               ┌─────────────────────────────────────────┐
               │      INTERVENTION (Plan de Acción)      │
               │  - Principios Activos: Ácido Hialurónico│
               │  - Estrategia: Doble Hidratación AM/PM  │
               └────────────────────┬────────────────────┘
                                    │
         ┌──────────────────────────┴──────────────────────────┐
         │                                                     │
         ▼                                                     ▼
┌─────────────────────────────────┐           ┌─────────────────────────────────┐
│       AM / PM ROUTINE           │           │   COMMERCE CONVERGENCE (OPCIONAL│
│ - 08:00 Limpieza suave + Sérum  │           │ - Producto GlowStore (Hestia)   │
│ - 20:00 Emulsión + Niacinamida  │           │ - Servicio Marketplace (Hermes) │
└─────────────────────────────────┘           └─────────────────────────────────┘
```

## 2. REGLAS DE DOMINIO
1. **Subordinación Comercial:** Si el objetivo se logra mediante cambios de hábito (ej. agua, protección solar básica), no se fuerza producto.
2. **Explicabilidad:** Cada paso de la rutina y cada producto recomendado incluye una razón cosmetológica explícita (`reason`).
3. **Persistencia en el Ciclo:** El plan generado se inyecta directamente en `glow_cycles.am_routine`, `glow_cycles.pm_routine`, `glow_cycles.recommended_product_ids` y `glow_cycles.recommended_service_ids`.

## 3. ESTADO DEL GATE
🟢 **PASS**
