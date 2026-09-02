# GIA-13-F — Failure Injection Report (F01 a F15)

## 1. EVALUACIÓN DE INYECCIÓN DE FALLOS Y CONTENCIÓN

| ID | Fallo Inyectado | Detección | Contención | Recuperación | Resultado |
|---|---|---|---|---|:---:|
| **F01** | PostgreSQL temporalmente no disponible | Pool error | 500 estructurado | Reintento automático en cliente | 🟢 PASS |
| **F02** | Redis no disponible | Connection error | Bypass a PostgreSQL | Transparente al usuario | 🟢 PASS |
| **F03** | YouCam timeout / 5xx | Circuit Breaker | Abre circuito tras 3 fallos | Fallback controlado | 🟢 PASS |
| **F04** | Gemini timeout / 5xx | Circuit Breaker | Abre circuito | Fallback controlado | 🟢 PASS |
| **F05** | API timeout | Client timeout | Muestra botón 'Reintentar'| Reintento manual | 🟢 PASS |
| **F06** | App cerrada en medio del ciclo | N/A | Estado en PostgreSQL | Cero pérdida al reabrir | 🟢 PASS |
| **F07** | Pérdida de red en check-in | Socket error | Mensaje amigable | Check-in persistible al volver | 🟢 PASS |
| **F08** | Token JWT expirado | 401 Unauthorized | Redirección a Login | Cero filtración de datos | 🟢 PASS |
| **F09** | Request duplicado (Check-in) | Idempotencia | Actualiza sin duplicar | Mismo registro conservado | 🟢 PASS |
| **F10** | Request concurrente | Transacción BD | ACID en PostgreSQL | Consistencia garantizada | 🟢 PASS |
| **F11** | Acceso a ciclo ajeno (IDOR) | `user_id = $2` | 404 / 403 retornado | Bloqueado completamente | 🟢 PASS |
| **F12** | Modificación de measurement ajeno | `user_id = $2` | 404 / 403 retornado | Bloqueado completamente | 🟢 PASS |
| **F13** | Re-scan duplicado el mismo día | Day Check | Actualiza medición del día | Evita duplicidad de deltas | 🟢 PASS |
| **F14** | Graduación duplicada | Status check | Retorna ciclo ya graduado | Idempotente | 🟢 PASS |
| **F15** | Payload JSON corrupto | Body parser | 400 Bad Request | Rechazado sin crash | 🟢 PASS |

## 2. ESTADO DEL GATE
🟢 **PASS**
