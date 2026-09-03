# D004-SECURITY-AND-ISOLATION-ANALYSIS.md

## Security and Isolation Analysis for GlowApp RAG Retention

This document analyzes the security implications and isolation requirements for implementing retention policies in GlowApp's RAG system, with a focus on preventing cross-tenant data leakage and ensuring proper access controls.

### 1. Current Security State of GlowApp RAG

**HECHO:** The current RAG service does not enforce tenant isolation in its queries.

**EVIDENCIA:**
- The `searchBeautyKnowledge` function in `/backend/src/services/ragService.js` does not include `tenant_id` in its SQL queries.
- The function accepts optional `filters` (skin_type, category, etc.) but not tenant_id.
- Therefore, if tenant-scoped knowledge were present in the `beauty_knowledge_embeddings` table, it would be accessible to all tenants.

**INTERPRETACIÓN:** 
The current RAG implementation is designed for global knowledge only (as decided in D-001). It assumes that all knowledge in `beauty_knowledge_embeddings` is global (tenant_id = NULL). If the system is to support tenant-scoped knowledge, the retrieval layer must be modified to enforce tenant isolation.

**RIESGO:** 
High risk of cross-tenant data leakage if tenant-scoped knowledge is ingested without proper retrieval scoping.

### 2. Security Requirements for Tenant-Scoped Knowledge

If GlowApp decides to support tenant-scoped knowledge in the RAG system, the following security measures are necessary:

#### A. Storage-Level Isolation
- **Requirement:** Tenant-scoped knowledge must be stored with a valid `tenant_id` (non-NULL).
- **Implementation:** 
  - The `beauty_knowledge_embeddings` table must have a `tenant_id` column (nullable to allow both global and tenant-scoped rows).
  - Ingestion processes must ensure that tenant-scoped knowledge is stored with the correct `tenant_id`.
- **Risk if not implemented:** 
  - Tenant-scoped knowledge stored with `tenant_id = NULL` becomes globally accessible.
  - Tenant-scoped knowledge stored with wrong `tenant_id` leaks to another tenant.

#### B. Retrieval-Level Isolation
- **Requirement:** The RAG service must filter by `tenant_id` when serving tenant-scoped knowledge.
- **Implementation:** 
  - Modify `searchBeautyKnowledge` to accept a `tenant_id` parameter (from the request context via middleware).
  - In the SQL query, add a condition: `tenant_id = $param` for tenant-scoped requests.
  - For global requests, either omit the condition or set `tenant_id IS NULL`.
  - If supporting a combined view (global + tenant), use: `(tenant_id IS NULL OR tenant_id = $param)`.
- **Risk if not implemented:** 
  - Queries ignore tenant context and return all matching records, leading to cross-tenant leakage.

#### C. Row Level Security (RLS) as an Alternative or Supplement
- **Requirement:** Consider using PostgreSQL RLS to enforce isolation at the database level.
- **Implementation:** 
  - Enable RLS on `beauty_knowledge_embeddings`.
  - Create a policy that uses `current_setting('app.tenant_id')::int` to filter rows.
  - Ensure the middleware (or connection pool) sets the `app.tenant_id` GUC for each connection.
- **Risk if not implemented:** 
  - Reliance solely on application-level filtering introduces risk if any code path forgets to apply the filter.
  - RLS provides defense-in-depth.

#### D. Ingestion and Update Controls
- **Requirement:** Ensure that knowledge is ingested with the correct `tenant_id` and that updates do not allow changing the `tenant_id` to escape isolation.
- **Implementation:** 
  - Ingestion APIs must validate and set `tenant_id` based on the authenticated tenant.
  - Update operations must not allow modifying `tenant_id` (or must validate that the new value matches the current tenant).
- **Risk if not implemented:** 
  - A malicious or buggy update could change a record's `tenant_id` to access another tenant's data.

#### E. Access Control for Retention and Deletion Operations
- **Requirement:** Retention jobs, legal hold management, and manual deletion operations must respect tenant boundaries.
- **Implementation:** 
  - Retention jobs should operate per tenant (if using tenant-scoped policies) or globally (for global policies).
  - Legal hold interfaces must ensure that a tenant can only place holds on their own knowledge.
  - Audit logs must record which tenant performed which action.
- **Risk if not implemented:** 
  - A retention job could accidentally delete data from another tenant if scoped incorrectly.
  - A tenant could place a legal hold on global knowledge or another tenant's knowledge.

### 3. Security Analysis of Proposed Retention Options

All retention options from `D004-RETENTION-OPTIONS-COMPARISON.md` must be evaluated for their impact on security and isolation.

#### Option 1: Timestamp-Based Soft Delete with Periodic Cron Job
- **Security Impact:** 
  - The cron job must respect tenant scoping when evaluating retention policies and applying deletions.
  - If using a `retention_policies` table scoped by `tenant_id`, the job should join on `tenant_id`.
  - The soft delete flag (`is_deleted` or `deleted_at`) must be included in all queries to exclude deleted records.
- **Isolation:** 
  - Maintains isolation if queries properly filter by `tenant_id` and `is_deleted`.
  - Risk: If the cron job misses the tenant filter, it could apply retention to the wrong tenant's data.
- **Mitigation:** 
  - Write the retention job to explicitly include `tenant_id` in its queries.
  - Test with tenant-scoped data to ensure correct behavior.

#### Option 2: Hard Delete with Archive Table
- **Security Impact:** 
  - The archive table must have the same security protections as the main table.
  - The move operation must preserve `tenant_id` and not allow cross-tenant leakage.
  - Queries to the archive table (if any) must filter by `tenant_id`.
- **Isolation:** 
  - Same as main table if the archive table is identically secured.
  - Risk: If the archive table is less protected, it could become a leakage vector.
- **Mitigation:** 
  - Apply the same RLS policies and access controls to the archive table.
  - Ensure the move operation is atomic and preserves all columns.

#### Option 3: Time-To-Live (TTL) via Partitioning
- **Security Impact:** 
  - If partitioning includes `tenant_id` in the partition key (e.g., range on time, list on tenant), isolation is inherent.
  - If partitioning is only by time, then each partition must still be protected by RLS or application filtering.
- **Isolation:** 
  - Depends on partitioning strategy.
  - Risk: If partitions are not isolated, tenants could access each other's data within a time partition.
- **Mitigation:** 
  - Consider composite partitioning (time + tenant) if tenant-scoped data is present.
  - Otherwise, rely on RLS/application filtering within each partition.

#### Option 4: Application-Level Retention with Tombstones
- **Security Impact:** 
  - Similar to Option 1: the tombstone status must be respected in all queries.
  - The retention job must set the tombstone correctly per tenant.
- **Isolation:** 
  - Maintains isolation if queries filter by `tenant_id` and tombstone status.
  - Risk: If the tombstone check is missed, deleted data could be returned.
- **Mitigation:** 
  - Ensure all query paths include the tombstone check.

#### Option 5: Event-Driven Retention via Triggers
- **Security Impact:** 
  - Triggers must be written to respect tenant scoping.
  - A trigger that deletes based on a time condition must include `tenant_id` in its WHERE clause if the time condition is evaluated per tenant.
  - Triggers run with the privileges of the triggering user; must be secure against privilege escalation.
- **Isolation:** 
  - High risk if trigger logic is flawed and allows cross-tenant operations.
  - Triggers can be complex to audit for correctness.
- **Mitigation:** 
  - Avoid complex retention logic in triggers; prefer scheduled jobs.
  - If using triggers, rigorously test and review them.

### 4. Recommendations for Secure Implementation

1. **Decide on Knowledge Scoping:** 
   - Determine whether GlowApp will support tenant-scoped knowledge in RAG.
   - If yes, proceed with the following recommendations. If no, the current global-only approach is sufficient, but retention must still be applied to global knowledge.

2. **Implement Storage-Level Tenant ID:** 
   - Ensure `beauty_knowledge_embeddings` has a `tenant_id` column (nullable).
   - For global knowledge, keep `tenant_id = NULL`.
   - For tenant-scoped knowledge, set `tenant_id` to the appropriate value.

3. **Enforce Retrieval-Level Isolation:** 
   - Modify the RAG service to accept `tenant_id` from the request context (via middleware or authentication token).
   - In `searchBeautyKnowledge`, add a condition based on the desired scope:
     - Global-only: `WHERE tenant_id IS NULL`
     - Tenant-scoped: `WHERE tenant_id = $tenantId`
     - Combined: `WHERE tenant_id IS NULL OR tenant_id = $tenantId`
   - Ensure that the condition is applied consistently in all query paths (including fallback full-text search).

4. **Consider Row Level Security (RLS) for Defense-in-Depth:** 
   - Enable RLS on `beauty_knowledge_embeddings`.
   - Create a policy that uses `current_setting('app.tenant_id')::int` to filter rows.
   - Ensure the middleware sets the `app.tenant_id` GUC for each database connection.
   - This provides a safety net if application-level filtering is missed.

5. **Secure the Retention Mechanism:** 
   - Whatever retention option is chosen, ensure that:
     - The retention job or process respects `tenant_id` when applying policies.
     - Legal hold operations are scoped to the correct tenant.
     - Audit logs record the `tenant_id` for all actions.
     - Access to retention management interfaces is restricted to authorized roles (e.g., admin, legal).

6. **Audit and Monitor:** 
   - Implement audit logging for knowledge creation, modification, access, and deletion.
   - Monitor for attempts to access knowledge outside the tenant's scope.
   - Regularly verify that isolation is working as expected.

### 5. Conclusion

The security of the RAG retention system hinges on proper tenant isolation at both the storage and retrieval layers. If GlowApp intends to support tenant-scoped knowledge, it must implement:

- A `tenant_id` column in the knowledge table.
- Retrieval queries that filter by `tenant_id` based on the request context.
- Consideration of RLS for defense-in-depth.
- Secure retention mechanisms that respect tenant boundaries.

Without these measures, there is a significant risk of cross-tenant data leakage, which could lead to privacy violations, loss of proprietary information, and non-compliance with data protection regulations.

---
*No modifications to code, database, or configuration were made during this analysis.*