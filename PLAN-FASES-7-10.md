# GLOWAPP SAAS B2B - PLAN FASES 7-10 (Post-Deploy)

## Contexto
- FASES 1-5: Código completo, commit `d5d8ad78` en main
- FASE 6: Deploy bloqueado (Railway pausado)
- Objetivo: Avanzar trabajo independiente del deploy

---

## FASE 7: TESTS AUTOMATIZADOS (Prioridad ALTA)
**Objetivo:** Cobertura crítica antes de prod

| Tarea | Archivo | Criterio de éxito |
|-------|---------|-------------------|
| 7.1 Unit tests middlewares | `src/middleware/__tests__/saasContext.test.js` | 100% branches |
| 7.2 Unit tests featureGate | `src/middleware/__tests__/featureGate.test.js` | 100% branches |
| 7.3 Unit tests subscriptionService | `src/services/__tests__/subscriptionService.test.js` | Mock Stripe/Wompi |
| 7.4 Unit tests usageMeteringService | `src/services/__tests__/usageMeteringService.test.js` | Límites + alertas |
| 7.5 Integration tests rutas SaaS | `src/routes/__tests__/saasTeamRoutes.test.js` | SuperTest + BD test |
| 7.6 Integration tests SuperAdmin | `src/routes/__tests__/superAdminRoutes.test.js` | Auth + datos agregados |
| 7.7 Config Jest + CI | `jest.config.js`, `.github/workflows/test.yml` | Pipeline verde |

---

## FASE 8: EMAIL NOTIFICATIONS (Prioridad ALTA)
**Objetivo:** Completar flujos trial/dunning/invites que requieren email real

| Tarea | Archivo | Detalle |
|-------|---------|---------|
| 8.1 Email service base | `src/services/emailService.js` | Nodemailer + templates |
| 8.2 Template: trial ending (3 días) | `src/templates/trialEnding.hbs` | HTML + texto |
| 8.3 Trial expired downgrade | `src/templates/trialExpired.hbs` | |
| 8.4 Invoice emitted | `src/templates/invoiceEmitted.hbs` | Adjuntar PDF |
| 8.5 Dunning notice (vencida) | `src/templates/dunningNotice.hbs` | Listado facturas |
| 8.6 Subscription canceled | `src/templates/subscriptionCanceled.hbs` | |
| 8.7 Team invite | `src/templates/teamInvite.hbs` | Link accept |
| 8.8 Integrar en jobs + servicios | `trialDunningCron.js`, `subscriptionService.js` | Llamadas reales |

---

## FASE 9: FRONTEND INTEGRATION PREP (Prioridad MEDIA)
**Objetivo:** Desbloquear equipo frontend

| Tarea | Archivo | Detalle |
|-------|---------|---------|
| 9.1 Types TypeScript | `types/saas.d.ts` | Tenant, Plan, Usage, Invoice, ApiKey |
| 9.2 React hooks | `frontend/hooks/useSaas.ts` | useTenant, useUsage, useBilling, useTeam |
| 9.3 API client | `frontend/lib/saasApi.ts` | Axios + interceptors auth |
| 9.4 SuperAdmin hooks | `frontend/hooks/useSuperAdmin.ts` | Dashboard, tenants, revenue |
| 9.5 Storybook docs | `frontend/stories/Saas.stories.tsx` | Componentes demo |

---

## FASE 10: PRODUCCIÓN ROBUSTA (Prioridad MEDIA)
**Objetivo:** Resiliencia webhook, observabilidad, seguridad

| Tarea | Archivo | Detalle |
|-------|---------|---------|
| 10.1 Webhook retry queue | `src/jobs/webhookRetryQueue.js` | Bull/Redis + backoff |
| 10.2 Dead letter + replay API | `src/routes/webhookAdminRoutes.js` | SuperAdmin only |
| 10.3 Rate limiting por tenant | `src/middleware/tenantRateLimit.js` | Token bucket |
| 10.4 Audit log enrichment | `src/services/auditService.js` | Contexto request |
| 10.5 Metrics Prometheus SaaS | `src/metrics/saasMetrics.js` | MRR, churn, usage, trials |
| 10.6 Security headers + CSP | `src/middleware/securityHeaders.js` | Helmet tuneado |

---

## ORDEN DE EJECUCIÓN RECOMENDADO

1. **FASE 7.1-7.4** (Tests unitarios core) → Base sólida
2. **FASE 8.1-8.8** (Emails) → Completa flujos críticos
3. **FASE 7.5-7.7** (Tests integración + CI) → Pipeline
4. **FASE 9** (Frontend prep) → En paralelo con frontend team
5. **FASE 10** (Hardening) → Post-deploy estable

---

## CRITERIOS DE "DONE" POR FASE
- Tests: `npm test` pasa, coverage > 80% en código nuevo
- Emails: Se envían en staging, templates renderizan
- Frontend: Types compilan, hooks funcionan en Storybook
- Hardening: Webhook retry probado, metrics expuestas en `/metrics`