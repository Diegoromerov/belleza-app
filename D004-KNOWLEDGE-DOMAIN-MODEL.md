# D004-KNOWLEDGE-DOMAIN-MODEL.md

## Knowledge Domain Model for GlowApp RAG Retention

This document categorizes the types of knowledge and data in GlowApp's RAG system according to their scope, ownership, and retention requirements.

### 1. Knowledge Domains by Scope

#### A. GLOBAL Knowledge
**Definition:** Knowledge that is intended to be shared across all tenants and users, not associated with any specific tenant or individual.

**Examples in GlowApp:**
- General beauty technical knowledge (skin types, ingredient functions, contraindications, standard protocols).
- Industry-standard guidelines and best practices.
- Foundational educational content about beauty and skincare.
- Pre-trained model knowledge (if any).

**Characteristics:**
- Stored in `beauty_knowledge_embeddings` with `tenant_id = NULL`.
- Accessible to all tenants via RAG queries.
- Not subject to tenant-specific deletion or modification (unless globally obsolete).
- Governed by global retention policies.

**Evidence:** 
- D-001 implementation left `beauty_knowledge_embeddings.tenant_id` as NULL (GLOBAL RAG).
- No tenant-specific filtering observed in RAG service beyond optional metadata filters (skin_type, category, etc.) that are not tenant-scoped.

#### B. TENANT-SCOPED Knowledge
**Definition:** Knowledge that belongs to a specific tenant and must be isolated from other tenants.

**Examples in GlowApp (if implemented):**
- Internal salon protocols and proprietary techniques.
- Custom product formulations unique to a salon.
- Tenant-specific training materials.
- Client-specific notes (if stored in RAG, though likely in other systems).

**Characteristics:**
- Must be stored with a valid `tenant_id` (non-NULL).
- Must be isolated by RLS or query filtering to prevent cross-tenant access.
- Subject to tenant-specific retention and deletion policies.
- Tenant should be able to delete all their knowledge upon offboarding.

**Evidence:**
- No current evidence of tenant-scoped knowledge storage in the RAG system.
- The current RAG service does not include `tenant_id` in its queries (no filtering by tenant in `searchBeautyKnowledge`).
- Therefore, if tenant-scoped knowledge were ingested into the current global table, it would violate isolation.

#### C. USER-SCOPED Knowledge
**Definition:** Knowledge associated with a specific end-user (client or professional) within a tenant.

**Examples:**
- Personalized beauty routines for a client.
- Individual client preferences and history.
- Professional's personal notes or techniques.

**Characteristics:**
- Typically stored in user/profile tables, not in RAG.
- If ever stored in RAG, would require both `tenant_id` and `user_id` for scoping.
- Subject to user-level consent and deletion requests (right to be forgotten).
- Highest sensitivity; requires strict isolation.

**Evidence:**
- No evidence of user-scoped knowledge in the RAG system.
- User data is handled in `usuarios` and related tables (with `tenant_id`).

#### D. SESSION-SCOPED Knowledge
**Definition:** Temporary knowledge relevant only for the duration of a user session or conversation.

**Examples:**
- Context from a current conversation that informs the next turn.
- Intermediate reasoning steps in an AI agent's thought process.
- Short-term memory for maintaining coherence in a dialogue.

**Characteristics:**
- Not persisted beyond the session (or a short timeout).
- Not stored in the permanent RAG index.
- Governed by session management, not retention policies.
- Low risk from a data persistence standpoint.

**Evidence:**
- The AI orchestrator services may maintain conversation state temporarily.
- No indication that session data is written to the RAG embeddings table.

### 2. Knowledge Types by Nature and Retention Needs

| Knowledge Type               | Examples                                      | Scope Options       | Retention Need                          | Deletion Trigger                         |
|------------------------------|-----------------------------------------------|---------------------|-----------------------------------------|------------------------------------------|
| Foundational Beauty Knowledge| Skin biology, ingredient functions            | Global              | Long-term (years)                       | Obsolescence, regulatory change          |
| Industry Standards           | Best practices, safety guidelines             | Global              | Long-term                               | Standard updates                         |
| Salon-Proprietary Protocols  | Custom techniques, unique formulations        | Tenant-scoped       | Medium-term (as long as useful)         | Protocol update, tenant offboarding      |
| Client-Specific Routines     | Personalized care plans                       | User-scoped         | Short-to-medium term                    | Client request, relationship end         |
| Conversation Context         | Current dialogue state                        | Session-scoped      | Ephemeral (minutes/hours)               | Session end                              |
| Interaction-Derived Insights | Learned preferences from chat history         | Tenant/User-scoped  | Debatable (anonymized aggregation ok)   | Consent withdrawal, privacy request      |
| Audit Trails                 | Logs of who accessed/modified knowledge       | Mixed               | Long-term (legal hold possible)         | End of legal hold period                 |
| Training Data                | Examples used to fine-tune models             | Global/Tenant-scoped| Until model retraining                  | Model update, data obsolescence          |

### 3. Implications for RAG Design

- **Global Knowledge:** Can remain in a shared table with `tenant_id = NULL`. Requires global retention policies.
- **Tenant-Scoped Knowledge:** Must be stored with `tenant_id` set and isolated via RLS or query partitioning. If using a shared table, must ensure no cross-tenant leakage.
- **User-Scoped Knowledge:** Should generally NOT be stored in the RAG vector index due to high sensitivity and deletion requirements. If necessary, must be tightly scoped and deletable.
- **Session-Scoped Knowledge:** Should not be persisted to the RAG index at all.

### 4. Recommendations for Knowledge Domain Separation

1. **Maintain RAG Global for Foundational Knowledge:** Keep the current `beauty_knowledge_embeddings` as global (tenant_id = NULL) for industry-standard beauty knowledge.
2. **Create Tenant-Scoped RAG Index (Optional):** If tenants require private knowledge storage, consider:
   - A separate table `tenant_knowledge_embeddings` with `tenant_id` NOT NULL.
   - Or continue using the same table but enforce `tenant_id` IS NOT NULL for tenant-scoped rows and apply RLS.
   - The service would need to know whether to query global, tenant-scoped, or both based on the request context.
3. **Exclude Sensitive User Data:** Ensure that any user-specific or session-specific data is never ingested into the RAG embeddings table.
4. **Implement Metadata for Scoping:** Add a `knowledge_scope` column (ENUM: 'GLOBAL', 'TENANT', 'USER', 'SESSION') or rely on `tenant_id` NULL/NOT NULL combined with `user_id` if needed.
5. **Retention Policies by Domain:** Different knowledge types may have different retention schedules (e.g., global knowledge kept longer than tenant-specific protocols).

### 5. Risks of Mis-scoping

- **Global Contamination:** Tenant-specific knowledge accidentally marked as global (tenant_id = NULL) becomes accessible to all tenants.
- **Over-Restriction:** Global knowledge incorrectly marked as tenant-scoped reduces the utility of the RAG system.
- **Incomplete Deletion:** Failure to delete tenant-scoped knowledge upon offboarding leaves residual data.
- **Compliance Failure:** Inability to prove deletion of user-specific data when requested.

---
*This model is based on the current state of the GlowApp RAG system and the requirements outlined in the D-004 authorization.*
*No modifications to code, database, or configuration were made during this analysis.*