# D004-DIRECTOR-DECISION-PACK.md

# Director Decision Pack: D-004 - Estrategia de retención de datos para RAG y conocimiento organizacional

## Executive Summary

This decision pack provides the Director with all necessary information to make an informed decision regarding D-004: Estrategia de retención de datos para RAG y conocimiento organizacional.

After conducting a forensic analysis post-D-002, we have confirmed that:
- D-001 (multi-tenancy) is IMPLEMENTED, VALIDATED, and CLOSED
- D-002 (workforce) is IMPLEMENTED, VALIDATED, and CLOSED
- Therefore, D-004 is the next architectural decision to be made

## Key Findings

### Current State
- GlowApp uses a global RAG system (`beauty_knowledge_embeddings` with `tenant_id = NULL`)
- No retention policies, deletion mechanisms, or lifecycle management exist for knowledge data
- Knowledge is retained indefinitely until manual intervention
- No mechanism to distinguish between global knowledge and tenant-specific knowledge in the RAG index
- No audit trail or versioning for knowledge changes

### Critical Requirements
1. **Legal Compliance:** Must comply with Ley 1581 art. 8 (data minimization) and SIC Circ. 022/2023 (AI data handling)
2. **Security Isolation:** Tenant data must never leak into global knowledge, and vice versa
3. **Operational Needs:** Ability to remove obsolete knowledge, handle offboarding, and respond to deletion requests
4. **Auditability:** Must be able to track knowledge changes for compliance and investigations

### Recommended Approach
Based on the analysis, we recommend a **phased implementation**:

**Phase 1: Foundation**
- Add metadata columns (`created_at`, `updated_at`) to `beauty_knowledge_embeddings`
- Create `retention_policies` table to define retention periods
- Create `legal_holds` table to override retention when necessary
- Implement a retention cron job that evaluates policies and flags expired knowledge
- Modify RAG service to respect deletion flags in queries

**Phase 2: Tenant-Scoped Capability (Optional)**
- Modify system to support tenant-scoped knowledge in RAG (if business requires it)
- Add proper tenant isolation at storage and retrieval layers
- Extend retention policies to support tenant-scoped rules

**Phase 3: Advanced Features**
- Implement anonymization/pseudonymization capabilities
- Add audit trail for knowledge changes
- Develop self-service portal for tenants to manage their knowledge lifecycle

## Decision Options

The Director must decide on the following:

### A. Knowledge Scoping Model
1. **Global-Only:** Maintain current approach where all knowledge is shared (tenant_id = NULL)
2. **Hybrid Model:** Support both global knowledge (tenant_id = NULL) and tenant-scoped knowledge (tenant_id ≠ NULL) in the same table
3. **Separate Indexes:** Use separate tables or schemas for global vs tenant-scoped knowledge

### B. Retention Mechanism
1. **Soft Delete + Cron Job:** Mark as deleted, then physically delete after grace period (RECOMMENDED)
2. **Hard Delete + Archive:** Move to archive table before deletion
3. **Time-Based Partitioning:** Drop old partitions
4. **Application Tombstone:** Never physically delete, just mark status
5. **Trigger-Based:** Use database triggers for immediate deletion

### C. Legal Hold Implementation
1. **Simple Hold Table:** Basic table to flag knowledge under hold
2. **Sophisticated Hold System:** Support complex hold definitions (by date, by metadata, etc.)

### D. Audit Trail Requirements
1. **Basic Logging:** Log creation/modification/deletion events
2. **Comprehensive Audit:** Full before/after snapshots with user context
3. **No Audit Trail:** Not recommended (non-compliant)

## Risks of Inaction

If no decision is made and no retention strategy is implemented:

1. **Legal Non-Compliance:** Violation of Ley 1581 art. 8 (data minimization principle)
2. **Security Risks:** Increased attack surface due to indefinite data retention
3. **Operational Inefficiencies:** Growing storage costs and potential performance degradation
4. **Privacy Violations:** Inability to satisfy user deletion requests (right to be forgotten)
5. **Audit Failures:** Inability to prove data handling practices to regulators or auditors
6. **Liability Exposure:** Potential legal action from improper data handling

## Dependencies

D-004 depends on:
- **D-001 (Multi-tenancy):** Essential for proper tenant-scoped implementation
- No other D-xxx decisions are strictly required, but D-004 informs and may influence:
  - D-005/D-014 (Commission model - if retention affects financial data)
  - D-006/D-010 (Fiscal adapter - if retention affects tax documents)
  - D-009 (Generic data retention policy - should align with RAG retention)
  - D-015 (Consent management - retention may relate to consent withdrawal)

## Readiness Assessment

✅ **Prerequisites Met:**
- D-001 is implemented and validated (multi-tenancy foundation)
- Database connection is healthy and verified
- Migration framework is in place and functional
- Basic RAG service is operational

🟡 **Items Requiring Attention:**
- Need to verify exact schema of `beauty_knowledge_embeddings` table
- Should confirm current retention practices (if any) in other parts of the system
- Legal review required for retention period recommendations

## Recommended Decision

**APPROVE** the implementation of a retention strategy for GlowApp's RAG system with the following characteristics:

1. **Knowledge Scoping:** Hybrid Model supporting both global and tenant-scoped knowledge
2. **Retention Mechanism:** Timestamp-Based Soft Delete with Periodic Cron Job (Option 1)
3. **Legal Hold:** Simple hold table to override retention when necessary
4. **Audit Trail:** Basic logging of knowledge lifecycle events
5. **Phased Implementation:** Start with foundation, then add advanced features as needed

This approach balances compliance, security, operability, and cost while providing a clear path for evolution.

## Next Steps Upon Approval

If approved, the following steps would be authorized for implementation:
1. Create detailed technical specification
2. Develop migration scripts for schema changes
3. Implement retention policy engine and cron job
4. Modify RAG service to respect retention flags
5. Create validation and test procedures
6. Execute in a controlled environment following standard procedures

---
*This decision pack is based on the forensic analysis conducted post-D-002 and represents the current state of the GlowApp system as of the analysis date.*
*No implementation actions have been taken as part of this analysis.*