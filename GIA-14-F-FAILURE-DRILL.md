# GIA-14-F — Production Failure Drill Report

## 1. SIMULACIÓN DE ESCENARIOS DE FALLO OPERACIONAL (F01 a F15)

* **F01 a F02 (Indisponibilidad de BD / Redis):** Conexión protegida con pool y bypass automático de Redis hacia PostgreSQL.
* **F03 a F05 (Timeouts de YouCam / Gemini / APIs externas):** Circuit Breaker aísla el servicio degradado en 3 fallos y retorna fallback de seguridad.
* **F06 a F08 (Interrupciones de red y app kill):** Estado persistente en PostgreSQL. Al reconectar, la app reanuda exactamente donde quedó.
* **F09 a F11 (Idempotencia y JWT expirado):** Solicitudes duplicadas de check-in actualizan la entrada sin duplicar. Tokens inválidos retornan 401 estructurado.
* **F12 a F15 (Acceso cruzado e integridad):** Aislamiento estricto `WHERE id = $1 AND user_id = $2`.

## 2. ESTADO DEL GATE
🟢 **PASS**
