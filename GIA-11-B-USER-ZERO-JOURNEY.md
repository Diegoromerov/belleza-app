# GIA-11-B — User Zero Journey Report (U00 a U20)

## 1. TRAZABILIDAD DEL JOURNEY DESDE CERO (USUARIO REAL)

| Etapa | Descripción | UI Flutter | API Express | DB Postgres | Estado |
|---|---|:---:|:---:|:---:|:---:|
| **U00** | Apertura de GlowApp | `main.dart` | N/A | N/A | 🟢 VERIFIED |
| **U01** | Autenticación con JWT | `LoginScreen` | `/api/auth/login` | `users` | 🟢 VERIFIED |
| **U02** | Acceso a Glow IA+ | Botón Inteligencia | `/api/glow-cycle/active` | `glow_cycles` | 🟢 VERIFIED |
| **U03** | Consentimiento Cero-Huella | `BiometricConsent` | `/api/biometric/consent` | `user_consents` | 🟢 VERIFIED |
| **U04** | Captura Bio-óptica | Cámara YouCam/Gemini| `/api/biometric/analyze` | Circuit Breaker | 🟢 VERIFIED |
| **U05** | Resultado de Diagnóstico | Scores dérmicos | `transformationEngine` | En memoria | 🟢 VERIFIED |
| **U06** | Creación de Glow Cycle | Pantalla Plan | `/api/glow-cycle/create` | `glow_cycles` (S0) | 🟢 VERIFIED |
| **U07** | Visualización de Meta | `MyGlowDashboard` | `/api/glow-cycle/active` | `glow_cycles` | 🟢 VERIFIED |
| **U08** | Rutina Matutina (AM) | Tarjeta Rutina AM | Local / AppState | Local | 🟢 VERIFIED |
| **U09** | Rutina Nocturna (PM) | Tarjeta Rutina PM | Local / AppState | Local | 🟢 VERIFIED |
| **U10** | Check-in Diario | Checkbox táctil | `/api/glow-cycle/:id/checkin`| `checkin_history` | 🟢 VERIFIED |
| **U11** | Continuidad Temporal | Timeline Hitos | Chronos Agent | `currentDayNumber` | 🟢 VERIFIED |
| **U12** | Hito Re-scan Día 15 | Diálogo Re-scan | `/api/glow-cycle/:id/re-scan` | `measurements` | 🟢 VERIFIED |
| **U13** | Cálculo de Delta $\Delta$ | Delta Visual (+12) | Determinista | `score_delta` | 🟢 VERIFIED |
| **U14** | Interpretación Semántica | Nota explicable | `evaluateDelta` | `ai_notes` | 🟢 VERIFIED |
| **U15** | Adaptación de Rutina | Rutina adaptada | `adaptPlanBasedOnDelta`| `glow_cycles.plan` | 🟢 VERIFIED |
| **U16** | Línea Temporal Evolutiva | Timeline SOUL | `measurements` ASC | Historial S0-S1-S2 | 🟢 VERIFIED |
| **U17** | Re-scan Final Día 30 | Diálogo Re-scan | `/api/glow-cycle/:id/re-scan` | `measurements` | 🟢 VERIFIED |
| **U18** | Graduación del Ciclo | Modal Graduación | `/api/glow-cycle/:id/graduate`| `status='completed'` | 🟢 VERIFIED |
| **U19** | Siguiente Ciclo (Next Glow)| Selector de Meta | `/api/glow-cycle/create` | Nuevo Cycle ID | 🟢 VERIFIED |
| **U20** | Retorno Posterior | Estado Activo | Cache Redis / Postgres | `hasActiveCycle` | 🟢 VERIFIED |

## 2. ESTADO DEL GATE
🟢 **PASS**
