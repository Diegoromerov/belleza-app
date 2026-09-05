# 🎯 Auth Threat Model — Modelo de Amenazas OWASP

| Amenaza | Nivel de Riesgo | Control Implementado | Estado |
| :--- | :---: | :--- | :---: |
| **Brute Force en Login** | **P1** | Rate Limiter por IP (30 req / 15 min) | ✅ Implementado |
| **Role Spoofing en Register** | **P0** | Inyección forzada de rol `CLIENTE`/`PRESTADOR` en backend | ✅ Implementado |
| **Token Theft / Revocación** | **P1** | Token Blacklist Fail-Closed en Redis | ✅ Implementado |
| **OTP Prediction / Replay** | **P1** | `crypto.randomInt` criptográfico + TTL 10 min en Redis | ✅ Implementado |
| **Logs con Secretos / OTP** | **P0** | Sanitización estricta de `console.log` en backend | ✅ Implementado |
