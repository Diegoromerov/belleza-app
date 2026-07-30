# Checklist de Hardening Pre-Escalamiento Biométrico (Sprint 4.1)

Documento de verificación obligatoria antes de habilitar el 100% del tráfico en producción para el Módulo Hub Biométrico Refactorizado (ADR-001).

---

## 📋 Lista de Verificación (Checklist)

### 1. Seguridad & Cumplimiento Legal (GDPR / Ley 1581)
- [x] **Inmutabilidad de Consentimiento:** Transacciones SQL atómicas activadas en `biometricConsentRoutes.js`.
- [x] **Cifrado de PII:** Marcas faciales y métricas guardadas bajo cifrado `AES-256-GCM`.
- [x] **Eliminación de userId Guest:** Todos los endpoints mutantes rechazan peticiones sin Bearer JWT válido.

### 2. Resiliencia & Rendimiento
- [x] **Idempotencia Habilitada:** Encabezado `Idempotency-Key` (UUID v4) obligado en peticiones POST.
- [x] **Circuit-Breakers Activos:** YouCam, Gemini y DeepSeek envueltos en `circuitBreakerService.js`.
- [x] **Índices BD Creados:** Índices `BTREE`, `GIN` e `HNSW` (pgvector) aplicados en migración `029`.

### 3. Operaciones & Monitoreo
- [x] **Smoke Tests Ejecutables:** Script `scripts/smoke_test_prod.js` listo para verificación sintética.
- [x] **Feature Flags Disponibles:** `biometricFeatureFlags.js` configurado para desactivación rápida de emergencia.
- [x] **Runbook de Incidentes:** `docs/RUNBOOK_BIOMETRIC_INCIDENTS.md` publicado.
