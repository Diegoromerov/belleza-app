# GIA-15-B — Real User Journey Matrix

## 1. MATRIZ DE ETAPAS DEL USUARIO REAL (U00 a U20)

| Etapa | UI | API | Backend | DB | Evento | Métrica | Evidencia | Gap |
|---|---|---|---|---|---|---|:---:|:---:|
| **U00** | Splash/Home | N/A | N/A | N/A | `app_open` | Sesiones | **REAL** | Ninguno |
| **U01** | Login | `/api/auth/login` | `authController` | `users` | `user_login` | MAU/DAU | **REAL** | Ninguno |
| **U02** | Consentimiento | `/api/biometric/consent`| `biometricService`| `user_consents` | `consent_given` | Consent Rate | **REAL** | Ninguno |
| **U03** | Baseline S0 | `/api/biometric/analyze`| `youcam/gemini` | In-memory | `baseline_taken` | Baseline Rate | **REAL** | Ninguno |
| **U04** | Goal Select | `/api/glow-cycle/create` | `glowCycleService` | `glow_cycles` | `goal_selected` | Goal Type | **REAL** | Ninguno |
| **U05** | Plan AM/PM | `/api/glow-cycle/create` | `transformationEngine` | `glow_cycles.plan` | `plan_created` | Time to Value | **REAL** | Ninguno |
| **U06** | AM Routine | Dashboard `/my-glow` | `glowCycleService` | `glow_cycles` | `am_viewed` | AM Views | **REAL** | Ninguno |
| **U07** | PM Routine | Dashboard `/my-glow` | `glowCycleService` | `glow_cycles` | `pm_viewed` | PM Views | **REAL** | Ninguno |
| **U08** | Check-in D1 | `/api/glow-cycle/:id/checkin` | `glowCycleService` | `checkin_history` | `checkin_logged` | D1 Adherence | **REAL** | Ninguno |
| **U09** | Continuidad D2-D14 | Dashboard | `chronosAgent` | `glow_cycles` | `streak_updated` | Habit Streaks | **REAL** | Ninguno |
| **U10** | Re-scan D15 S1| `/api/glow-cycle/:id/re-scan` | `glowCycleService` | `measurements` | `rescan_d15` | D15 Rescan Rate | **REAL** | Ninguno |
| **U11** | Delta D15 | Dashboard | `transformationEngine` | `measurements.delta` | `delta_shown` | Delta Promedio | **REAL** | Ninguno |
| **U12** | Adaptación | Dashboard | `transformationEngine` | `glow_cycles.plan` | `plan_adapted` | Adaptation Rate | **REAL** | Ninguno |
| **U13** | Re-scan D30 S2| `/api/glow-cycle/:id/re-scan` | `glowCycleService` | `measurements` | `rescan_d30` | D30 Rescan Rate | **REAL** | Ninguno |
| **U14** | Graduación | `/api/glow-cycle/:id/graduate` | `glowCycleService` | `status='completed'` | `cycle_graduated`| Graduation Rate| **REAL** | Ninguno |
| **U15** | Next Cycle | Selector Meta | `glowCycleService` | `glow_cycles` | `next_cycle_start`| LTV / Cycle 2 | **REAL** | Ninguno |

## 2. ESTADO DEL GATE
🟢 **PASS**
