# GIA-15-L — Abandonment Matrix Report

## 1. FUNNEL DE ABANDONO Y PUNTOS DE DETECCIÓN

| Etapa del Funnel | Tipo de Abandono | Detección | Mitigación Implementada |
|---|---|---|---|
| **Home $\rightarrow$ Consentimiento** | Observable | `user_consents` vacío | Banner contextual en Home |
| **Consentimiento $\rightarrow$ Baseline** | Observable | Sin registro en `glow_cycles` | Flujo de cámara con guía visual |
| **Baseline $\rightarrow$ Plan** | Observable | Tiempo de generación $> 3$s | Cache y motor determinista instantáneo |
| **Día 1 $\rightarrow$ Día 14** | Observable | Ausencia en `checkin_history` | Recordatorios in-app coordinados por Chronos |
| **Día 15 Re-scan** | Observable | Sin medición para `day_number = 15` | Banner destacado de re-escaneo en `/my-glow` |
| **Día 30 Graduación** | Observable | Estado permanece `in_progress` | Modal de celebración de graduación |

## 2. ESTADO DEL GATE
🟢 **PASS**
