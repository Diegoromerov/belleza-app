# IMPLEMENTATION DISCOVERY

## Current System State (as of commit HEAD)

### Backend Schema (PostgreSQL)
- Tables present: `usuarios`, `perfiles_prestador`, `services`, `bookings`, `transactions`, `beauty_knowledge_embeddings`, `user_activity_logs`, `platform_config`, `admin_mfa`, `productos`, `reviews`, `portfolio_items`, `messages`, `nail_tryon_jobs`, `sos_alerts`.
- Missing tables for foundation: `tenants`, `consentimientos`, `audit_log`, `retention_policies`, `legal_documents`, `data_requests`, `retractos`, `lista_robinson`, `notificaciones`.
- Missing columns: `tenant_id` in business tables (`usuarios`, `perfiles_prestador`, `services`, `bookings`, `transactions`, etc.).
- No explicit multi-tenancy enforcement (RLS or separate schema).

### Backend Services
- Payment service (`wompiService.js`) handles payout and crearPayout but lacks HMAC verification, idempotency checks, and reconciliation.
- No service layer for consent management, audit logging, retention, legal documents.

### Frontend
- Flutter web and mobile modules present; authentication, booking, provider detail screens exist.
- No UI for consent management, data subject requests, legal document acceptance.

### Configuration
- `.env` exists but not inspected for secrets; `WOMPI_WEBHOOK_SECRET` present in `.env.example`.
- No rate limiting, CSP, HSTS headers configured in code observed.

### Tests
- Some unit and integration tests exist (e.g., bookingController, auraToolExecutor).
- No tests for consent, audit, retention.

### Documentation
- Architecture freeze documents (F7.004 series) define approved scope.
- Commerce V1 architectural freeze approved (READY FOR ARCHITECTURAL APPROVAL).

## Decisions Approved (from Decision Register)
- Multi-tenancy strategy: PENDING (requires director decision).
- Consent management: PENDING.
- Audit log: PENDING (but user_activity_logs exists for screen interactions).
- Retention policies: PENDING.
- Legal documents versioning: PENDING.
- Commission model: PENDING (subscription approved, posterior commission and split payment require director decision).
- Fiscal adapter: PENDING (conceptual only).
- Alternative payment providers: PENDING.
- SLA/uptime definitions: PENDING.
- IA/RAG governance: PENDING.

## Work Ready for Execution
- None: all foundation items require director decisions or are undefined.
- However, baseline tables (users, services, bookings, payments) exist and can be extended.

## Dependencies
- Database schema changes require migration scripts.
- Backend services require new modules (consent, audit, retention, legal).
- Frontend requires new UI flows for consent, data requests, legal acceptance.
- Configuration requires new env vars (e.g., for rate limits, legal doc storage).

## Risks
- Adding tenant_id without backfilling data could break existing references.
- Implementing consent without proper UI may lead to non-compliance.
- Adding audit_log must capture who changed what, when, why (not just screen activity).

## Recommended Execution Order
1. Approve foundation decisions (multi-tenancy, consent, audit, retention, legal docs).
2. Create migration scripts to add `tenant_id` and new tables.
3. Implement backend services for consent, audit, retention, legal docs.
4. Implement frontend UI for consent management, data subject requests, legal document presentation.
5. Add security headers, rate limiting.
6. Update payment service with HMAC verification, idempotency, reconciliation (once legal review complete).
7. Add tests for new components.
8. Update documentation.