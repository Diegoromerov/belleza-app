# D004-RETENTION-OPTIONS-COMPARISON.md

## Comparison of Retention Options for GlowApp RAG Knowledge

This document compares different architectural options for implementing retention, deletion, and lifecycle management for knowledge in GlowApp's RAG system.

### Option 1: Timestamp-Based Soft Delete with Periodic Cron Job

**Description:**
- Add `created_at` and `updated_at` timestamps to `beauty_knowledge_embeddings`.
- Add a `retention_policies` table defining retention periods by knowledge type or scope.
- Implement a cron job that runs periodically to:
  - Identify records where `(now() - updated_at) > retention_period`.
  - Exclude records under legal hold.
  - Perform soft delete by setting a `deleted_at` timestamp or a boolean `is_deleted` flag.
  - Optionally, after a grace period, physically delete the records.

**Advantages:**
- Simple to implement and understand.
- Allows recovery of accidentally deleted data (if soft delete is used).
- Minimal impact on query performance (just an extra WHERE clause).
- Uses existing PostgreSQL features.

**Disadvantages:**
- Requires additional storage for timestamps and flags.
- Soft deleted data still occupies space until physically purged.
- Cron job may miss edge cases if not carefully designed (e.g., concurrent updates).

**Security:**
- No direct security impact; relies on existing access controls.
- Must ensure that soft delete flag is respected in all queries.

**Isolation:**
- Works with both global and tenant-scoped knowledge; retention policies can be scoped by `tenant_id`.

**Complexity:**
- Low to moderate.

**Cost:**
- Low development cost; minimal runtime overhead.

**Scalability:**
- Scales linearly with number of records; cron job duration increases with data volume.

**Operability:**
- Easy to monitor (cron logs); retention periods are configurable.

**Reversibility:**
- High: soft delete can be reversed by unsetting the flag before physical deletion.

**Impact on RAG:**
- Minimal; just adds a filter condition to exclude deleted records.

**Impact on Glow IA+:**
- None; the IA services continue to use the RAG service as before.

**Impact on Multi-tenancy:**
- Retention policies can be defined per tenant or globally.

**Risk of Cross-Tenant Leakage:**
- None if queries properly filter by `tenant_id` and `is_deleted`.

### Option 2: Hard Delete with Archive Table

**Description:**
- Instead of soft deleting, move expired records to an archive table (`beauty_knowledge_embeddings_archive`) before deleting from the main table.
- Archive table has the same schema plus archival metadata (archived_at, reason).
- Retention job moves then deletes.

**Advantages:**
- Maintains a lean main table for better query performance.
- Preserves historical data for audit or legal hold (if archive is protected).
- Clear separation of active and historical data.

**Disadvantages:**
- More complex: requires moving data between tables.
- Archive table must be managed and secured.
- Increases complexity of backup/restore procedures.

**Security:**
- Archive table must be protected with same or higher security as main table.

**Isolation:**
- Same as main table; can be scoped by tenant.

**Complexity:**
- Moderate.

**Cost:**
- Moderate; requires careful ETL-like logic.

**Scalability:**
- Good for query performance on main table; archive grows but is queried less.

**Operability:**
- Requires monitoring of both tables and the move process.

**Reversibility:**
- Possible to restore from archive, but requires manual intervention.

**Impact on RAG:**
- Slightly more complex query to optionally include archive (if needed for historical searches).

**Impact on Glow IA+:**
- None.

**Impact on Multi-tenancy:**
- Archive table should also respect tenant scoping.

**Risk of Cross-Tenant Leakage:**
- None if isolation is maintained in both tables.

### Option 3: Time-To-Live (TTL) via Partitioning

**Description:**
- Partition the `beauty_knowledge_embeddings` table by time range (e.g., monthly partitions).
- Retention job drops old partitions that are past their retention date.
- Requires PostgreSQL declarative partitioning or pg_partman extension.

**Advantages:**
- Very efficient for dropping old data: dropping a partition is fast.
- Query performance can be improved if queries include time constraints.
- Naturally enforces retention by removing old data.

**Disadvantages:**
- Requires changing to a partitioned table (migration complexity).
- Queries must be aware of partitioning to avoid scanning all partitions (unless using constraint exclusion).
- Managing many partitions can add overhead.
- Less flexible for changing retention periods (need to re-partition).

**Security:**
- Same as base table; partitions inherit security.

**Isolation:**
- Works with tenant scoping if partition key includes tenant or if combined with RLS.

**Complexity:**
- High (initial setup) to moderate (ongoing).

**Cost:**
- Higher initial cost; lower long-term maintenance for deletion.

**Scalability:**
- Excellent for time-based deletion; partitioning can improve query performance.

**Operability:**
- Requires monitoring of partition creation and dropping.

**Reversibility:**
- Low: dropping a partition is irreversible without backup restore.

**Impact on RAG:**
- Queries may need to be adjusted to work with partitions (though often transparent).

**Impact on Glow IA+:**
- None.

**Impact on Multi-tenancy:**
- Can combine with tenant_id in partition key (e.g., range on time, list on tenant) or use separate partitioning strategies.

**Risk of Cross-Tenant Leakage:**
- None if isolation is maintained.

### Option 4: Application-Level Retention with Tombstones

**Description:**
- Keep data in the table indefinitely but mark it as retired via a `status` field (e.g., 'active', 'retired', 'deleted').
- The RAG service, when retrieving knowledge, filters out retired items unless overridden by an admin or legal hold.
- Retirement can be based on time, events, or manual action.

**Advantages:**
- Simple implementation: just add a status field.
- Allows for different states (e.g., retired vs deleted).
- Easy to implement in the application layer without changing deletion semantics.

**Disadvantages:**
- Data never leaves the table, leading to unbounded growth.
- Requires the application to consistently respect the status field.
- Retired data still occupies space and is still indexed (unless index excludes it, which is complex).

**Security:**
- Must ensure all code paths respect the status.

**Isolation:**
- Works with tenant scoping.

**Complexity:**
- Low.

**Cost:**
- Low development; high storage cost over time.

**Scalability:**
- Poor: storage grows indefinitely.

**Operability:**
- Simple to implement but requires vigilance to avoid forgetting to filter.

**Reversibility:**
- High: can change status back to active.

**Impact on RAG:**
- Requires modifying the search query to include status filter.

**Impact on Glow IA+:**
- None.

**Impact on Multi-tenancy:**
- Status field can be combined with tenant_id.

**Risk of Cross-Tenant Leakage:**
- None if queries filter by status and tenant_id.

### Option 5: Event-Driven Retention via Triggers

**Description:**
- Use database triggers to automatically delete or archive records when certain events occur (e.g., a tenant is deleted, a legal hold is lifted, or a retention period is calculated via a generated column).
- Less common; retention is usually better handled by a scheduled job.

**Advantages:**
- Retention happens immediately when the event occurs.
- No need for a separate cron job.

**Disadvantages:**
- Triggers can complicate database operations and make it harder to reason about data flow.
- Risk of trigger cascades or performance issues.
- Difficult to implement complex retention logic (e.g., based on multiple factors) in triggers.
- Harder to test and maintain.

**Security:**
- Triggers run with the privileges of the triggering user; must be secure.

**Isolation:**
- Can be designed to respect tenant scoping.

**Complexity:**
- High.

**Cost:**
- Moderate to high.

**Scalability:**
- Depends on trigger efficiency; can slow down write operations.

**Operability:**
- Harder to debug and monitor than a cron job.

**Reversibility:**
- Low to medium; depends on whether the trigger action is reversible.

**Impact on RAG:**
- Minimal if triggers only affect deletion.

**Impact on Glow IA+:**
- None.

**Impact on Multi-tenancy:**
- Must ensure triggers do not leak data across tenants.

**Risk of Cross-Tenant Leakage:**
- Possible if trigger logic is flawed.

### Summary Matrix

| Option | Simplicity | Performance | Storage Efficiency | Reversibility | Isolation Support | Complexity | Cost |
|--------|------------|-------------|--------------------|---------------|-------------------|------------|------|
| 1. Soft Delete + Cron | High | Good (minor filter) | Medium (soft delete until purge) | High | Yes | Low-Med | Low |
| 2. Hard Delete + Archive | Med | Good (smaller main table) | High (data moved) | Med (restore from archive) | Yes | Med | Med |
| 3. Partitioning + Drop | Med | Very Good (partition prune) | High (old partitions dropped) | Low (needs backup) | Yes | High | Med-High |
| 4. Application Tombstone | High | Good (extra filter) | Low (data never removed) | High | Yes | Low | Low-High (long term) |
| 5. Trigger-Based | Low | Variable (trigger overhead) | Med | Low-Med | Yes | High | Med-High |

### Recommendation

**Option 1 (Timestamp-Based Soft Delete with Periodic Cron Job)** is recommended for GlowApp because it offers a good balance of simplicity, safety, and functionality. It allows for recovery, is easy to understand and implement, and provides sufficient performance for the expected scale. The soft delete grace period can be configured to meet operational needs before physical deletion.

This option should be combined with:
- A `retention_policies` table to define retention periods by knowledge type and tenant scope.
- A `legal_holds` table to override retention when necessary.
- Proper indexing on the timestamp columns to make the cron job efficient.
- Ensuring all RAG queries respect the soft delete flag.

---
*No modifications to code, database, or configuration were made during this analysis.*