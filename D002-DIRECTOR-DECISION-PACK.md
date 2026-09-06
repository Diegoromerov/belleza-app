# D-002 DIRECTOR DECISION PACK

## Executive Summary

**Decision**: GlowApp will remain a pure technology SaaS platform and will not assume any labor obligations, act as an employer, or intermediate labor relationships.

**Rationale**: 
- Avoids legal risks associated with employer status under Colombian labor law.
- Maintains focus on core value proposition: providing operational software for salons.
- Keeps architecture simple and tenant-isolated.
- Allows salons to retain full control over worker classification and relationships.

**Approach**: 
- Adopt a Modelo Híbrido (Option C): Extend the current model generically to support future workforce features without implementing them now.
- No changes to code, database, or architecture during this analysis phase.
- All workforce-related data, if stored in the future, must be tenant-isolated and clearly under salon control.

**Next Steps**: 
Await explicit Director authorization for implementation of any workforce management features. Do not proceed to D-003 without such authorization.

## Key Evidence
- No employee/table/column found in codebase or schema.
- Current model distinguishes only CLIENTE and PRESTADOR.
- Multi-tenancy (D-001) provides foundation for isolating future workforce data.
- Payment processing is facilitative (salon-configured commissions via gateways).
- Admin role exists in code but not fully stored in DB (latent concept).

## Recommendations for Future Implementation (if authorized)
1. If workforce features are added, use generic terms (e.g., `worker_type`, `engagement_type`) and avoid implying GlowApp assumes obligations.
2. Ensure any new tables include `tenant_id` and are subject to RLS if sensitive.
3. Clearly separate platform roles (e.g., salon admin) from labor roles in UI/API.
4. Legal review required for any feature handling worker data or payments.

---
*Prepared for Director review*