# GIA-11-H — Security Red Team Report (S01 a S15)

## 1. RESULTADOS DE LAS PRUEBAS DE SEGURIDAD RED TEAM

| ID | Prueba de Intrusión / Estrés | Resultado | Evidencia |
|---|---|:---:|---|
| **S01** | Acceso a ciclo de otro usuario | 🟢 PASS | Bloqueado 404/403 por cláusula `user_id = $2` |
| **S02** | Modificar ciclo ajeno | 🟢 PASS | Bloqueado por validación de JWT y ownership |
| **S03** | Registrar check-in ajeno | 🟢 PASS | Bloqueado por validación de JWT y ownership |
| **S04** | Enviar re-scan ajeno | 🟢 PASS | Bloqueado por validación de JWT y ownership |
| **S05** | Graduar ciclo ajeno | 🟢 PASS | Bloqueado por validación de JWT y ownership |
| **S06** | Manipular `user_id` en body | 🟢 PASS | Ignorado; se toma `req.user.id` del token JWT |
| **S07** | Manipular `cycle_id` en URL | 🟢 PASS | Validación contra `user_id` previene acceso |
| **S08** | Replay de request | 🟢 PASS | Idempotencia en check-in previene duplicados |
| **S09** | Duplicación de check-in diario | 🟢 PASS | Actualiza entrada del día sin crear registros dobles |
| **S10** | Request sin autenticación | 🟢 PASS | 401 Unauthorized devuelto inmediatamente |
| **S11** | Token JWT inválido / expirado | 🟢 PASS | 401 Unauthorized devuelto inmediatamente |
| **S12** | Payload malformado | 🟢 PASS | 400 / 500 estructurado sin volcar stacktrace |
| **S13** | Rate limiting | 🟢 PASS | Middleware de rate limiting activo |
| **S14** | Caída forzada de Redis | 🟢 PASS | Fallback transparente a base de datos PostgreSQL |
| **S15** | Fallo de proveedor IA bio-óptico | 🟢 PASS | Circuit breaker y degradación elegante |

## 2. ESTADO DEL GATE
🟢 **PASS**
