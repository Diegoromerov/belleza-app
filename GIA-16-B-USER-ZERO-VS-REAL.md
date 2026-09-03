# GIA-16-B — User Zero vs Real User Reality Report

## 1. COMPARATIVA RIGUROSA: SIMULACIÓN VS USUARIO REAL

| Etapa | Capacidad en User Zero (Simulado / E2/E3) | Estado con Usuario Real (E4/E5) |
|---|---|---|
| **U00 Apertura** | Test harness / router a `/my-glow` | `Icons.auto_awesome` listo en UI |
| **U01 Auth** | JWT generado en test suite | Login real en producción |
| **U02 Consent** | Inserción en `user_consents` | Pantalla Cero-Huella interactiva |
| **U03 Baseline S0** | Score numérico insertado (50) | Ingesta YouCam/Gemini |
| **U04 Plan AM/PM** | Generación por `transformationEngine` | Rutina visible en Flutter |
| **U05 Check-in D1** | Entrada JSON en `checkin_history` | Checkbox táctil en UI |
| **U10 Re-scan D15** | Delta calculado ($\Delta = +14$) | Flujo de cámara en Día 15 |
| **U15 Graduación** | Transición a `completed` | Desbloqueo de siguiente meta |

## 2. ESTADO DEL GATE
🟢 **PASS**
