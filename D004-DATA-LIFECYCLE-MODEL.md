# D004-DATA-LIFECYCLE-MODEL.md

## Data Lifecycle Model for GlowApp RAG Knowledge

This document outlines the lifecycle of knowledge data in GlowApp's RAG system, from creation to deletion, considering the different knowledge domains (global, tenant-scoped, user-scoped, session-scoped) and the requirements for retention, isolation, and compliance.

### 1. Stages of the Data Lifecycle

The lifecycle of a knowledge item (e.g., a beauty protocol, an ingredient description, a salon-specific technique) consists of the following stages:

#### A. Ingestion (Creation / Acquisition)
**Definition:** The process by which knowledge enters the RAG system.
- **Sources:** 
  - Internal: Salon-provided documents, GlowApp's internal beauty knowledge base, licensed third-party content.
  - External: Publicly available beauty standards, scientific literature, regulatory guidelines.
  - Derived: Knowledge generated from interactions (if permitted and anonymized), model fine-tuning outputs.
- **Methods:** 
  - Manual upload via admin interface.
  - Automated ingestion pipelines (e.g., scheduled jobs, APIs).
  - Real-time ingestion from user interactions (if allowed and processed).
- **Evidence:** 
  - The repository contains seed scripts like `seed_beauty_knowledge_v3.js` for initial data loading.
  - No evidence of automated ingestion pipelines for ongoing tenant-specific knowledge.
  - No evidence of real-time knowledge generation from interactions being fed back into RAG.

**Interpretation:** 
  Currently, knowledge ingestion is primarily manual or via predefined seeds. There is no automated, tenant-aware ingestion pipeline for private salon knowledge.

**Risk:** 
  Manual processes are error-prone and do not scale. Lack of automated ingestion hinders the ability to keep knowledge up-to-date and to enforce scoping rules at ingestion time.

#### B. Storage and Indexing
**Definition:** How knowledge is stored, indexed, and made available for retrieval.
- **Storage:** 
  - Raw documents (if stored) in a document management system (not evidenced in current code).
  - Processed knowledge (chunks, embeddings) in database tables (`beauty_knowledge_embeddings`).
- **Indexing:** 
  - Vector embeddings stored with metadata for filtering and similarity search.
  - Current indexing is purely vector-based (pgvector) with optional metadata filters.
- **Scoping:** 
  - Global knowledge: stored with `tenant_id = NULL`.
  - Tenant-scoped knowledge: would require `tenant_id` set and proper isolation.
- **Evidence:** 
  - The `beauty_knowledge_embeddings` table exists and is used by the RAG service.
  - No evidence of separate storage for raw documents or for tenant-scoped knowledge.
  - No evidence of document-level versioning or audit trails in the RAG table.

**Interpretation:** 
  The current storage is optimized for retrieval speed but lacks features for lifecycle management (e.g., timestamps for retention, versioning, soft delete).

**Risk:** 
  Without proper scoping at storage level, tenant-specific knowledge could leak into the global index. Without retention metadata, applying deletion policies is difficult.

#### C. Retrieval and Usage
**Definition:** How knowledge is accessed and used in response to user queries.
- **Process:** 
  - User query → embedding generation → vector search → metadata filtering → result formatting → injection into LLM prompt.
- **Scoping Enforcement:** 
  - Currently, the RAG service does not filter by `tenant_id` (global only).
  - If tenant-scoped knowledge were present, the service would need to add `tenant_id` filtering based on the request context.
- **Evidence:** 
  - The `searchBeautyKnowledge` function in `ragService.js` does not include `tenant_id` in its SQL queries.
  - The function accepts optional `filters` (skin_type, category, etc.) but not tenant_id.
  - Therefore, the current RAG service is global-only and does not support tenant-scoped knowledge retrieval.

**Interpretation:** 
  To support tenant-scoped knowledge, the RAG service must be modified to accept a tenant context and include it in the query (either via `tenant_id` column or via a separate table with RLS).

**Risk:** 
  If tenant-scoped knowledge is stored without proper retrieval scoping, it could be leaked to unauthorized tenants. Conversely, if global knowledge is incorrectly restricted, it reduces the utility of the RAG system.

#### D. Maintenance and Updates
**Definition:** How knowledge is kept current, corrected, or improved over time.
- **Activities:** 
  - Adding new knowledge.
  - Updating existing knowledge (e.g., new findings, corrected information).
  - Deprecating or obsoleting knowledge.
  - Re-generating embeddings when the source text changes.
- **Evidence:** 
  - No evidence of automated update pipelines.
  - The seed scripts suggest a one-time or occasional manual load.
  - No versioning or history of changes to knowledge items is stored.

**Interpretation:** 
  Knowledge becomes stale over time. Without a mechanism to update or retire knowledge, the RAG system may provide outdated or incorrect information.

**Risk:** 
  Stale knowledge can lead to poor user experience, incorrect advice, and potential liability. Lack of update mechanisms increases manual burden.

#### E. Retention and Deletion
**Definition:** How knowledge is retained for a required period and then deleted or anonymized.
- **Retention Policies:** 
  - Define how long different types of knowledge should be kept (based on legal, operational, or business requirements).
  - May be time-based (e.g., keep for 2 years after last use) or event-based (e.g., delete when superseded by new standard).
- **Deletion Methods:** 
  - Physical deletion (DELETE from table).
  - Logical deletion (mark as deleted, hide from queries).
  - Anonymization (remove or obscure personally identifiable information).
  - For embeddings: may require re-computation if source text changes, or deletion if the source is removed.
- **Evidence:** 
  - No retention policies or deletion mechanisms are evident in the current system.
  - The `beauty_knowledge_embeddings` table lacks timestamps (`created_at`, `updated_at`) that would enable time-based retention.
  - No evidence of a retention scheduler or cron job.

**Interpretation:** 
  Currently, knowledge is retained indefinitely until manual intervention. This poses compliance risks and operational challenges.

**Risk:** 
  - Non-compliance with data minimization principles (Ley 1581 art. 8).
  - Accumulation of obsolete or incorrect knowledge.
  - Inability to satisfy user requests for data deletion (right to be forgotten).

#### F. Archiving and Audit
**Definition:** How knowledge is preserved for historical, legal, or audit purposes after its active use period.
- **Archiving:** 
  - Moving knowledge to a cold storage area for long-term retention.
  - Keeping a snapshot of knowledge at a point in time.
- **Audit Trails:** 
  - Recording who added, modified, or deleted knowledge and when.
  - Essential for compliance and forensic analysis.
- **Evidence:** 
  - No archiving mechanism is evident.
  - No audit trail fields (e.g., `created_by`, `updated_at`, `change_log`) in the RAG table.
  - No evidence of logging knowledge changes to a separate audit table.

**Interpretation:** 
  Without audit trails, it is impossible to reconstruct the history of knowledge changes or to prove compliance with retention policies.

**Risk:** 
  - Inability to pass audits or investigations.
  - Lack of accountability for knowledge changes.
  - Risk of undetected data corruption or unauthorized modifications.

### 2. Lifecycle Models by Knowledge Domain

#### A. Global Knowledge Lifecycle
1. **Ingestion:** Manual or scheduled loads of foundational beauty knowledge (e.g., from GlowApp's internal beauty team, licensed sources).
2. **Storage:** Stored in `beauty_knowledge_embeddings` with `tenant_id = NULL`.
3. **Retrieval:** Accessible to all tenants via RAG service (no tenant filtering).
4. **Maintenance:** Periodic updates by GlowApp's beauty team to reflect new standards or corrections.
5. **Retention:** 
   - Foundational knowledge: long-term (e.g., 5+ years) or until superseded by a new global standard.
   - Industry standards: retained as long as they are current, then archived.
6. **Deletion:** 
   - Global obsolescence: remove or archive when knowledge is no longer correct or relevant.
   - Legal requirement: delete if found to be non-compliant (rare for foundational beauty knowledge).
7. **Archiving:** 
   - Optionally archive old versions for historical reference or audit.
8. **Audit Trail:** 
   - Track global knowledge changes via a change log or version history (not currently implemented).

#### B. Tenant-Scoped Knowledge Lifecycle (if implemented)
1. **Ingestion:** 
   - Tenant uploads proprietary protocols, techniques, or product information.
   - Ingestion process must validate and assign the correct `tenant_id`.
2. **Storage:** 
   - Stored with `tenant_id` set (non-NULL) in the same table (if using shared schema with RLS) or in a tenant-scoped table/table set.
3. **Retrieval:** 
   - RAG service filters by `tenant_id` from the request context (via middleware or token).
   - Ensures isolation: tenants only see their own knowledge.
4. **Maintenance:** 
   - Tenant updates their own knowledge as protocols evolve.
   - GlowApp may provide tools to help tenants manage their knowledge.
5. **Retention:** 
   - Defined by the tenant or by GlowApp's policies (e.g., keep for duration of contract plus grace period).
   - May be tied to the tenant's subscription or license.
6. **Deletion:** 
   - Upon tenant offboarding: delete all tenant-scoped knowledge (or transfer to archive if required).
   - Upon tenant request: delete specific knowledge items (right to be forgotten).
   - Automated deletion based on retention policy.
7. **Archiving:** 
   - Optionally archive knowledge upon tenant offboarding for legal or historical reasons (if permitted by contract).
8. **Audit Trail:** 
   - Track who added/modified/deleted knowledge within the tenant.
   - Log retention and deletion actions for compliance.

#### C. User-Scoped Knowledge (Not Recommended for RAG)
**General Advice:** 
  Avoid storing user-specific knowledge (e.g., personal client routines, individual preferences) in the RAG vector index due to high sensitivity and deletion complexity.
- If absolutely necessary, must be tightly scoped (`tenant_id` + `user_id`) and subject to immediate deletion upon user request.
- Better to store such data in user/profile tables with proper access controls.

#### D. Session-Scoped Knowledge
- **Not stored in RAG:** 
  - Session context should remain in memory or a temporary store (e.g., Redis) for the duration of the session.
  - Never persisted to the RAG embeddings table to avoid privacy risks and unnecessary complexity.

### 3. Data Lifecycle Requirements

To support a compliant and operable knowledge lifecycle, the system should provide:

#### A. Metadata for Lifecycle Management
- `created_at`: timestamp when the knowledge item was ingested or created.
- `updated_at`: timestamp when the knowledge item was last modified.
- `created_by`: reference to the user or tenant who added the knowledge.
- `version` or `source_version`: to track updates to source documents.
- `expires_at`: optional timestamp for time-based retention (can be computed from `created_at` + retention period).
- `is_deleted`: soft delete flag (if using logical deletion).
- `deletion_reason`: reason for deletion (obsolescence, legal request, etc.).
- `knowledge_scope`: ENUM ('GLOBAL', 'TENANT', 'USER', 'SESSION') to explicitly define scope.

#### B. Retention Policy Engine
- A table `retention_policies` defining:
  - `id`, `tenant_id` (NULL for global policies), `knowledge_type` (or scope), `retention_period_days`, `legal_hold_override`, `created_at`, `updated_at`.
- A scheduled job (cron) that:
  - Evaluates each knowledge item against its applicable retention policy.
  - Skips items under legal hold.
  - Performs the retention action (e.g., flag for deletion, anonymize, or physically delete) on expired items.
  - Logs actions for audit.

#### C. Legal Hold Mechanism
- A table `legal_holds` that can tag knowledge items (by ID, by range, by metadata) to prevent deletion.
- Integrated with the retention job: items under legal hold are excluded from deletion actions.
- Interface to create, view, and release legal holds (restricted to authorized roles).

#### D. Deletion and Anonymization Options
- **Physical Deletion:** `DELETE FROM table WHERE ...` (fast, but irreversible).
- **Logical Deletion:** Set `is_deleted = true` and filter out in queries (reversible until purged).
- **Anonymization:** Replace or remove sensitive fields (e.g., change specific salon names to generic placeholders) while retaining utility for aggregate analysis.
- For embeddings: if the source text changes, the embedding must be re-generated; if the source is deleted, the embedding should be deleted or marked as invalid.

#### E. Audit Logging
- Table `knowledge_audit_log` recording:
  - `id`, `knowledge_id`, `action` (CREATE, UPDATE, DELETE, ANONYMIZE), `performed_by`, `tenant_id`, `timestamp`, `details` (e.g., old/new values).
- Essential for tracking compliance and investigating incidents.

### 4. Risks of Poor Lifecycle Management

| Risk Area               | Specific Risk                                                                 | Mitigation                                                                 |
|-------------------------|-------------------------------------------------------------------------------|----------------------------------------------------------------------------|
| Compliance              | Failure to delete data when required by law (Ley 1581 art. 8).               | Implement retention policies and automated deletion.                       |
| Privacy                 | Tenant-specific knowledge leaking to other tenants.                          | Enforce scoping at storage and retrieval level (tenant_id + RLS).          |
| Operability             | Stale or incorrect knowledge leading to poor user experience.                | Implement regular knowledge review and update cycles.                     |
| Auditability            | Inability to prove what knowledge existed at a point in time.                | Implement audit trails and versioning.                                    |
| Security                | Unauthorized modification or deletion of knowledge.                          | Implement role-based access control and audit logging.                    |
| Cost                    | Indefinite growth of storage due to lack of deletion.                        | Implement retention policies to remove obsolete knowledge.                |
| Legal Hold              | Inability to preserve data when needed for litigation or investigation.      | Implement legal hold mechanism that overrides retention policies.         |

### 5. Conclusion

The current GlowApp RAG system lacks a comprehensive data lifecycle management framework. To meet legal, operational, and user expectations, the system must evolve to include:

1. Explicit scoping of knowledge (global, tenant-scoped, etc.).
2. Metadata to support retention, auditing, and lifecycle management.
3. Automated retention and deletion mechanisms.
4. Legal hold capabilities.
5. Audit trails for knowledge changes.
6. Clear procedures for knowledge ingestion, update, and retirement.

The next steps involve defining specific retention policies, designing the necessary schema changes, and prototyping the retention job—all subject to further authorization.

---
*This model is based on the current state of the GlowApp RAG system and the requirements outlined in the D-004 authorization.*
*No modifications to code, database, or configuration were made during this analysis.*