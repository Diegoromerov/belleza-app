# D-002 WORKFORCE DATA MODEL

## Conceptual Data Model for Workforce (if extended)

If GlowApp decides to store workforce-related data in the future, the following model ensures tenant isolation and clear separation of responsibilities:

### Core Principle
All workforce data belongs to the tenant (salon). GlowApp provides the storage and retrieval mechanisms, but the salon defines the meaning of the data.

### Proposed Entities (Conceptual Only)
1. **workforce_members** - Generic table for any person associated with the salon (whether employee, independent contractor, admin, etc.)
   - id (PK)
   - tenant_id (FK to tenants)
   - user_id (optional FK to usuarios, if linked to a login account)
   - member_type (enum: EMPLOYEE, INDEPENDENT_CONTRACTOR, SALON_ADMIN, OWNER, OTHER) - defines how the salon classifies the person
   - first_name, last_name, contact_info, etc.
   - metadata JSONB for flexible attributes (e.g., hire_date, salary_rate, role, certifications)
   - created_at, updated_at

2. **workforce_schedules** - For tracking availability, shifts, time off
   - id
   - workforce_member_id
   - tenant_id (for denormalization and RLS)
   - start_datetime, end_datetime
   - shift_type, notes
   - created_at, updated_at

3. **workforce_documents** - For storing contracts, certifications, etc.
   - id
   - workforce_member_id
   - tenant_id
   - document_type (contract, certification, ID, etc.)
   - file_url
   - uploaded_at

### Implementation Notes
- Each table must include tenant_id and have RLS policies if the data is sensitive.
- The system should not assign any semantic meaning to member_type beyond what the salon defines.
- No payroll, tax, or legal obligation fields should be stored unless explicitly required and legally reviewed.
- This model is strictly optional and should only be implemented if the salon decides to use GlowApp for workforce administration.

## Current State
No such tables exist in the database. The current model only stores prestador information in perfiles_prestador (which is essentially a workforce member of type INDEPENDENT_CONTRACTOR or SERVICE_PROVIDER).

## Recommendation
Do not implement this model now. Keep the analysis for future reference if the decision evolves.