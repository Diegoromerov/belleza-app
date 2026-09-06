# D004-DELETION-AND-OFFBOARDING-ANALYSIS.md

## Deletion and Offboarding Analysis for GlowApp RAG Knowledge

This document analyzes the requirements and implications for deleting knowledge data when a tenant offboards, a user requests deletion, or knowledge becomes obsolete, with a focus on ensuring complete and compliant removal while preserving necessary data for audit or legal hold.

### 1. Deletion Scenarios

#### A. Tenant Offboarding
**Definition:** A tenant cancels their license or service agreement with GlowApp.

**Requirements:**
- All tenant-specific knowledge must be deleted or rendered inaccessible.
- Global knowledge (shared) should remain unaffected.
- Knowledge that was contributed by the tenant but marked as global (if any) should be reviewed: if it contains proprietary information, it may need to be anonymized or removed from the global index.
- Legal hold may apply if there is an ongoing investigation or litigation involving the tenant.

**Considerations:**
- If tenant-scoped knowledge is stored with `tenant_id`, deletion can be done by deleting all records with that `tenant_id`.
- If tenant-specific knowledge was accidentally stored as global (`tenant_id = NULL`), it must be identified and handled separately (e.g., anonymized or moved to a tenant-specific archive before deletion).
- The offboarding process should include a verification step to confirm deletion.

#### B. User Request for Deletion (Right to be Forgotten)
**Definition:** An end-user (client or professional) requests deletion of their personal data under data protection laws (Ley 1581, GDPR-inspired principles).

**Requirements:**
- Any knowledge that contains personally identifiable information (PII) about the user must be deleted or anonymized.
- In the context of RAG, this is unlikely to be a major issue if user-specific knowledge is not stored in the RAG index (as recommended). However, if user-specific notes or preferences were ingested, they must be addressed.
- The request may also involve user data in other tables (usuarios, profiles, etc.), but this analysis focuses on the RAG knowledge.

**Considerations:**
- The RAG system should not store raw user data or session-specific knowledge.
- If any user-specific knowledge is present in the RAG index, it must be deletable by user identifier.
- Anonymization may be preferable to deletion if the knowledge has aggregate value and can be stripped of PII.

#### C. Knowledge Obsolescence
**Definition:** Knowledge becomes outdated, incorrect, or superseded by new information.

**Requirements:**
- Obsolete knowledge should be removed from the active RAG index to prevent misleading outputs.
- Depending on policy, it may be archived for historical reference or physically deleted.
- If the knowledge is part of a legal hold, it cannot be deleted until the hold is lifted.

**Considerations:**
- Retention policies should define when knowledge is considered obsolete (e.g., after a certain period, when a new version is ingested, or when marked as deprecated by an expert).
- The system should provide a way to mark knowledge as obsolete (manually or via automated triggers) and then apply the retention action.

#### D. Legal Hold Activation
**Definition:** A legal hold is placed on certain knowledge data to preserve it for potential litigation, investigation, or audit.

**Requirements:**
- Knowledge under legal hold must be exempt from retention-based deletion.
- The hold should be able to apply to specific knowledge items, tenants, or time ranges.
- The hold should be transparent to normal operations but override deletion processes.
- When the hold is lifted, the knowledge should return to normal retention scheduling.

**Considerations:**
- A legal hold mechanism should be independent of retention policies but integrated with the retention job (which checks for holds before deleting).
- The hold should be auditable: who placed it, when, why, and what data is covered.

### 2. Deletion Methods and Their Implications

#### A. Physical Deletion (DELETE FROM table)
- **Pros:** 
  - Immediate space reclamation.
  - Simple and fast.
- **Cons:** 
  - Irreversible without backup.
  - Makes auditing difficult (proof of deletion may be needed, but the data is gone).
  - If done incorrectly, could lead to accidental loss.
- **Use Case:** 
  - When compliance requires irrevocable destruction of data.
  - After a grace period following soft delete or archiving.

#### B. Soft Delete (Mark as Deleted)
- **Pros:** 
  - Reversible (if needed before physical purge).
  - Allows for audit trail of deletion actions.
  - Simple to implement (add a `deleted_at` timestamp or `is_deleted` boolean).
- **Cons:** 
  - Data remains in the table and indexes until physically purged (storage overhead).
  - Must ensure all queries respect the delete flag.
- **Use Case:** 
  - Standard approach for retention-based deletion.
  - Allows a recovery window for accidental deletions.

#### C. Anonymization / Pseudonymization
- **Pros:** 
  - Retains utility of data for analysis while removing PII.
  - Can satisfy data minimization requirements by reducing identifiability.
- **Cons:** 
  - Complex to implement correctly (risk of re-identification).
  - May not be sufficient if the data itself is the issue (not just PII).
  - Embeddings may be difficult to anonymize without losing meaning.
- **Use Case:** 
  - When the knowledge has aggregate value but contains PII that needs to be removed.
  - For logs or metadata where the text can be sanitized.

#### D. Archiving (Move to Archive Table)
- **Pros:** 
  - Preserves data for audit or historical reference.
  - Keeps the main table lean for performance.
  - Allows controlled access to archived data (if needed).
- **Cons:** 
  - Requires managing an additional table.
  - Archive must be secured with same or higher protection.
  - Increases complexity of backup/restore.
- **Use Case:** 
  - When data must be retained for longer than the operational retention period (e.g., for legal or audit purposes).
  - As a step before physical deletion.

### 3. Offboarding Process for a Tenant

The offboarding process should include the following steps related to RAG knowledge:

1. **Identify Tenant-Scoped Knowledge:** 
   - Query for all knowledge with `tenant_id` = the tenant's ID.
   - If using a combined table, this is straightforward.
   - If tenant-specific knowledge was stored elsewhere, identify those locations.

2. **Check for Legal Hold:** 
   - Determine if any of the tenant's knowledge is under legal hold.
   - If yes, those items cannot be deleted until the hold is lifted.
   - The tenant should be notified, and offboarding may be delayed or partial.

3. **Apply Deletion Method:** 
   - For knowledge not under legal hold, apply the selected deletion method (soft delete, then physical delete after grace period, or direct physical delete if policy allows).
   - If anonymization is chosen, anonymize the data instead of deleting.

4. **Handle Global Knowledge Contributions:** 
   - Review any knowledge that the tenant contributed but that was stored as global (`tenant_id = NULL`).
   - If the knowledge is truly general and not proprietary, it may remain.
   - If it contains proprietary information, consider:
     - Anonymizing it to remove tenant-specific details.
     - Moving it to a tenant-specific archive before deletion from the global index.
     - Deleting it if it is not suitable for global sharing and the tenant requests removal.

5. **Verify Deletion:** 
   - After the deletion process, verify that no tenant-specific knowledge remains accessible via the RAG service.
   - Attempt to query for knowledge that should have been deleted and confirm it is not returned.

6. **Log and Audit:** 
   - Record the offboarding event, the knowledge that was deleted or anonymized, and the date.
   - Retain logs for compliance and audit purposes.

### 4. Risks and Mitigations

| Risk | Description | Mitigation |
|------|-------------|------------|
| Incomplete Deletion | Some tenant-specific knowledge remains accessible after offboarding. | Implement a verification step; use automated scans to ensure no records with the tenant ID remain in queryable form. |
| Accidental Deletion of Global Knowledge | A deletion operation meant for tenant-scoped data affects global knowledge. | Scope deletion operations strictly by `tenant_id`; ensure global knowledge (`tenant_id = NULL`) is not included unless intended. |
| Legal Hold Violation | Deleting data that is under legal hold. | Integrate legal hold check into the retention and deletion workflow; prohibit deletion if a hold exists. |
| Inability to Prove Deletion | Lack of evidence that deletion occurred for compliance purposes. | Maintain audit logs of deletion actions; consider using write-once storage for logs or digital signatures. |
| Data Residual in Indexes or Backups | Deleted data persists in database indexes, backups, or replication slaves. | For physical deletion, ensure indexes are updated; consider how backups handle deletion (point-in-time recovery may still have data). For strict destruction, cryptographic shredding may be needed. |
| Retention Policy Misapplication | Wrong retention period applied, leading to premature or delayed deletion. | Validate retention policies; have a review process; test with known data sets. |

### 5. Conclusion

Deletion and offboarding are critical components of a compliant knowledge lifecycle. GlowApp must implement:

- A clear process for identifying and deleting tenant-specific knowledge upon offboarding.
- Mechanisms to handle user deletion requests (right to be forgotten) if user-specific data is present in the RAG index.
- Retirement and deletion of obsolete knowledge based on retention policies.
- A legal hold mechanism to override deletion when necessary.
- Audit trails to track all knowledge lifecycle actions.

The chosen deletion method (soft delete with periodic cron job is recommended) should be applied consistently, with proper scoping to prevent cross-tenant leakage and to respect legal holds.

By integrating these capabilities, GlowApp can ensure that its RAG system remains compliant, secure, and trustworthy.

---
*No modifications to code, database, or configuration were made during this analysis.*