# GIA-06-B — Continuity Architecture Report

## 1. MÁQUINA DE ESTADOS TEMPORALES DEL GLOW CYCLE

```text
[ INICIO DEL CICLO: Día 1 ] ──> Estado: DAY_1_BASELINE
           │
           ▼
[ DÍAS 2 a 14: Hábitos Diarios ] ──> Estado: IN_PROGRESS_AM_PM
           │
           ▼
[ DÍA 15: Hito Intermedio Re-scan ] ──> Estado: RESCAN_15D_DUE
           │
           ├── (Re-escaneo completado) ──> Estado: IN_PROGRESS_ADAPTED (Días 16 a 29)
           │
           ▼
[ DÍA 30: Hito Final Re-scan ] ──> Estado: RESCAN_30D_DUE
           │
           ▼
[ GRADUACIÓN / CIERRE ] ──> Estado: GRADUATION_READY (Cierre formal)
           │
           ▼
[ TRANSICIÓN ] ──> Estado: NEXT_GLOW_UNLOCKED (Propuesta de nuevo objetivo)
```

## 2. INTEGRACIÓN CON CHRONOS
Chronos se convierte en el orquestador que calcula en tiempo de ejecución:
- `currentDayNumber`: Días transcurridos desde `start_date`.
- `temporalState`: Estado en la máquina de estados.
- `nextMilestone`: Próxima fecha clave y acción requerida (Check-in hoy vs Re-escaneo en Día X).

## 3. ESTADO DEL GATE
🟢 **PASS**
