# Runbook de Operaciones e Incidentes: Hub Biométrico (Sprint 4.3)

Procedimientos operativos estándar (SOP) y respuestas ante incidentes para el módulo biométrico refactorizado en producción.

---

## 🚨 Escenarios de Incidente & Respuesta

### 1. Falla masiva o latencia >3s en YouCam / Gemini API
- **Síntomas:** Incremento en el log `[CIRCUIT_BREAKER] YouCam SDK ABIERTO` o demoras en la respuesta.
- **Acción Automática:** El `circuitBreakerService` conmuta automáticamente a los fallbacks locales precalculados sin tumbar la API (HTTP 201 degradado).
- **Procedimiento Manual:**
  1. Verificar estado de API externa.
  2. Si requiere apagado forzado, ajustar variable de entorno `FF_BIOMETRIC_CIRCUIT_BREAKER=true` o toggle en `biometricFeatureFlags.js`.

### 2. Violación de SLO de Latencia (<500ms p99)
- **Síntomas:** Alertamiento en telemetría por latencia promedio superior a 500ms.
- **Acción:**
  1. Consultar estado de las conexiones de base de datos PostgreSQL.
  2. Verificar índices `BTREE`, `GIN` e `HNSW` ejecutando `ANALYZE user_biometrics;`.

---

## 🔄 Procedimiento de Rollback de Emergencia

En caso de fallo crítico en el release de producción:
1. Cambiar las Feature Flags en `biometricFeatureFlags.js`:
   - `ENABLE_IDEMPOTENCY_GUARD = false`
   - `ENABLE_ZOD_VALIDATION = false`
2. Reiniciar el proceso Node.js / Railway service (`npm restart` / redeploy previo tag).
3. Tiempo objetivo de recuperación (RTO): **< 5 minutos**.
