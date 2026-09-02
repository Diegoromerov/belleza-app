# GIA-00 — TARGET ARCHITECTURE & GLOW CYCLE ENGINE (CONCEPTUAL)

## 1. ARQUITECTURA CONCEPTUAL DE GLOW IA+

```text
┌────────────────────────────────────────────────────────────────────────┐
│                          GLOWAPP MOBILE / WEB                          │
│                                                                        │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │                 "MY GLOW" EVOLUTION DASHBOARD                  │   │
│   │  - Visualizador de Ciclo Activo (Día X de 30)                  │   │
│   │  - Comparador Visual Split-Screen (Día 1 vs Día 30)            │   │
│   │  - Rutina Diaria AM/PM interactiva con Check-in                │   │
│   │  - Botón de Compra Rápida (GlowStore) & Reserva Directa (Agenda│   │
│   └───────────────────────────────┬────────────────────────────────┘   │
└───────────────────────────────────┼────────────────────────────────────┘
                                    │ HTTPS (JWT + traceId)
┌───────────────────────────────────▼────────────────────────────────────┐
│                       GLOW CYCLE ENGINE (BACKEND)                      │
│                                                                        │
│   ┌──────────────────────┐  ┌───────────────────┐  ┌────────────────┐  │
│   │   Cycle Controller   │  │ Tracking & Cron   │  │ Delta Evaluator│  │
│   │ (create, get, update)│  │ (alerts, re-scan) │  │ (Atena + RAG)  │  │
│   └──────────┬───────────┘  └─────────┬─────────┘  └────────┬───────┘  │
└──────────────┼────────────────────────┼─────────────────────┼──────────┘
               │                        │                     │
┌──────────────▼────────────────────────▼─────────────────────▼──────────┐
│                   SWARM AGENTS & INTEGRATION LAYER                     │
│                                                                        │
│   - ATENA: Síntesis Dermal, Definición de Metas y Cálculo de Deltas    │
│   - HESTIA: Personal Shopper & Formulación de Rutinas GlowStore        │
│   - HERMES: Localización de Servicios en Marketplace vía PostGIS       │
│   - CHRONOS: Cadencia de Ciclos, Hitos de Medición y Rebooking         │
│   - RAG ENGINE: Grounding técnico con NVIDIA Embeddings 1024 dims      │
└──────────────┬────────────────────────┬─────────────────────┬──────────┘
               │                        │                     │
┌──────────────▼───────────┐  ┌─────────▼───────────┐  ┌──────▼──────────┐
│    BIOMETRIC SENSORS     │  │   ECOSYSTEM STORAGE │  │  CIRCUIT GUARD  │
│  - YouCam Face API       │  │  - PostgreSQL + pgv │  │  - ResilienceSvc│
│  - Gemini 3.1 Hand Vision│  │  - Table: glow_cycle│  │  - Breakers: 3  │
│  - DeepSeek Cosmetic V4  │  │  - Redis Cache & TTL│  │  - Fallbacks    │
└──────────────────────────┘  └─────────────────────┘  └─────────────────┘
```

---

## 2. MODELO DE DATOS CONCEPTUAL PARA GLOW CYCLES

```sql
-- Tabla principal de ciclos de transformación beauty
CREATE TABLE glow_cycles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id INTEGER NOT NULL REFERENCES users(id),
    cycle_type VARCHAR(50) NOT NULL, -- 'skin', 'hands', 'color', 'beauty_goal'
    status VARCHAR(30) NOT NULL DEFAULT 'active', -- 'active', 'completed', 'abandoned'
    target_goal VARCHAR(255) NOT NULL, -- Ej: 'Incrementar hidratación +15% y atenuar manchas'
    target_metric_key VARCHAR(50), -- Ej: 'hydration'
    baseline_value NUMERIC(5,2), -- Ej: 58.00
    target_value NUMERIC(5,2), -- Ej: 75.00
    current_value NUMERIC(5,2), -- Última medición
    duration_days INTEGER NOT NULL DEFAULT 30,
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_date TIMESTAMP WITH TIME ZONE,
    plan_summary TEXT, -- Resumen clínico/cosmetológico
    am_routine JSONB, -- Pasos matutinos
    pm_routine JSONB, -- Pasos nocturnos
    recommended_product_ids JSONB, -- SKUs de GlowStore
    recommended_service_ids JSONB, -- Servicios del Marketplace
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de mediciones y evolución temporal (Deltas)
CREATE TABLE glow_cycle_measurements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cycle_id UUID NOT NULL REFERENCES glow_cycles(id) ON DELETE CASCADE,
    measurement_type VARCHAR(30) NOT NULL, -- 'baseline', 'milestone_15d', 'final_30d', 'checkin'
    day_number INTEGER NOT NULL, -- Día 1, Día 15, Día 30
    encrypted_scores TEXT NOT NULL, -- Scores AES-256 (YouCam / Gemini)
    score_delta JSONB, -- Diferencia respecto al baseline ({ hydration: +12, spots: -5 })
    ai_evaluation_notes TEXT, -- Diagnóstico de evolución por Atena
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```
