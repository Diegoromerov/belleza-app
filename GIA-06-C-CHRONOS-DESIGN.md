# GIA-06-C — Chronos Design Report

## 1. MATRIZ DE EVENTOS TEMPORALES & POLÍTICA DE INTERVENCIÓN

| Evento | Trigger Temporal | Condición | Tipo de Intervención | Mensaje Contextual Canónico |
|---|---|---|:---:|---|
| **Rutina AM** | 07:30 - 09:00 | No hay check-in matutino | `HELPFUL` | "☀️ Buen día. Tu piel está lista para el paso 1 de tu rutina matutina." |
| **Rutina PM** | 20:30 - 22:00 | No hay check-in nocturno | `HELPFUL` | "🌙 Hora de descanso. Completa tu rutina nocturna para sellar hidratación." |
| **Hito Día 15 (Re-scan)** | Día $\ge 15$ | Sin medición Día 15 | `REQUIRED` | "📸 Hito de progreso alcanzado. Realiza tu re-escaneo para medir tu evolución." |
| **Hito Día 30 (Cierre)** | Día $\ge 30$ | Ciclo activo | `REQUIRED` | "🎉 ¡Día 30 completado! Descubre tu resultado global y gradúa tu Glow Cycle." |

## 2. PRESERVACIÓN DE PRIVACIDAD
* Cero exposición de scores biométricos en payloads de notificación.
* Totalmente determinista, auditable e idempotente.

## 3. ESTADO DEL GATE
🟢 **PASS**
