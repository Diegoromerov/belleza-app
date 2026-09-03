# D-002 IMPLEMENTATION IMPACT MAP

## Impact Analysis (Conceptual Only - No Implementation)

If workforce management features were to be implemented in the future respecting the D-002 boundary (GlowApp as technology platform only), the following areas would be impacted:

### Database
- Potential new tables: workforce_members, workforce_schedules, workforce_documents, etc.
- All new tables must include tenant_id and have appropriate RLS policies if data is sensitive.
- Existing tables (usuarios, perfiles_prestador) may need extension columns (e.g., worker_type) to differentiate engagement types.
- No changes to existing tenant_id structure or RLS foundations from D-001.

### Backend
- New services/controllers for managing workforce data (if implemented).
- Authorization middleware must ensure tenant isolation.
- Payment/commission services remain facilitative; no new payroll or salary processing.
- Validation layers to ensure data entered is under salon control.

### APIs
- New endpoints for CRUD operations on workforce entities (if implemented).
- All endpoints must require tenant context and validate salon ownership.
- API responses must not include fields that imply GlowApp assumes obligations (e.g., salary, tax_withheld as employer).
- Clear documentation that these are tools for the salon, not GlowApp services.

### Frontend/UI
- New modules/views for managing workforce (if implemented).
- UI must use language that emphasizes salon control (e.g., "Tu equipo", "Gestión de tu personal").
- Avoid terms like "Nuestro equipo", "Empleados de GlowApp", etc.
- Role-based UI elements must be tied to salon-defined roles, not GlowApp internal labor roles.

### UX/Copy
- All copy must reinforce that GlowApp provides tools, not employment services.
- Tooltips, help text, and onboarding should clarify the salon's responsibility.
- Error messages and notifications should not suggest GlowApp is acting as employer.

### Payments/Payouts
- Any payout functionality must be strictly facilitative: GlowApp only executes payments as instructed by the salon (e.g., via payment gateways).
- No held funds or wallet systems for workers without explicit salon direction and legal review.
- Commission calculations remain salon-configured; no automatic salary or benefit deductions.

### Security & Compliance
- Any workforce data must be classified as sensitive and subject to data protection review.
- Legal review required for any feature that stores worker data or facilitates payments to ensure compliance with labor and privacy laws.
- Audit logs should track access to workforce data for accountability.

### Note
This impact map is strictly conceptual and based on the assumption that workforce features might be added in the future. No implementation has been performed, and none is authorized at this time. The current system remains unchanged.

---
*Análisis completado el: $(date)*