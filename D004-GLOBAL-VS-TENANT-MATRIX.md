# D004-GLOBAL-VS-TENANT-MATRIX.md

## Comparison: Global vs Tenant-Scoped Knowledge in GlowApp RAG

This matrix compares the characteristics, implications, and requirements for global knowledge (shared across all tenants) and tenant-scoped knowledge (isolated per tenant) in the context of GlowApp's RAG system.

| Aspect | Global Knowledge (tenant_id = NULL) | Tenant-Scoped Knowledge (tenant_id ≠ NULL) |
|--------|-------------------------------------|--------------------------------------------|
| **Definition** | Knowledge intended to be shared across all tenants. | Knowledge that belongs to a specific tenant and must be isolated from others. |
| **Examples** | - General beauty science (skin types, ingredient functions).<br>- Industry-standard protocols and safety guidelines.<br>- Foundational educational content. | - Salon-proprietary techniques and protocols.<br>- Custom product formulations unique to a salon.<br>- Tenant-specific training materials.<br>- Internal operational procedures. |
| **Storage** | Stored in `beauty_knowledge_embeddings` with `tenant_id = NULL`. | Stored with a valid `tenant_id` (non-NULL). Requires either:<br>- Same table with RLS policies, or<br>- Separate table/schema per tenant. |
| **Retrieval** | Accessible to all tenants via RAG queries (no tenant filtering). | Must be filtered by `tenant_id` at query time to ensure isolation.<br>Requires the RAG service to accept and apply tenant context. |
| **Isolation** | None by design; all tenants see the same global knowledge. | Must be enforced via:<br>- Row Level Security (RLS) policies, or<br>- Query scoping (adding `tenant_id` = current tenant), or<br>- Physical separation (different tables/databases). |
| **Retention Policies** | Can be defined globally (applies to all tenants).<br>Example: "Keep foundational knowledge for 5 years." | Can be defined per tenant or globally with tenant scope.<br>Example: "Tenant-specific protocols retained for duration of contract + 1 year." |
| **Deletion Requests** | - Global obsolescence: remove when knowledge is outdated or incorrect.<br>- Legal deletion: rare, but possible if global knowledge is found non-compliant. | - Tenant offboarding: delete all knowledge for that tenant.<br>- Tenant request: delete specific knowledge items (right to be forgotten).<br>- Obsolescence: remove outdated tenant-specific protocols. |
| **Risk of Leakage** | Low (by design, it's meant to be shared). | High if isolation fails:<br>- Accidental ingestion without tenant_id.<br>- Misconfigured RLS or query scoping.<br>- Cross-tenant queries due to bugs. |
| **Risk of Over-Isolation** | None (it's global by intent). | High if global knowledge is mistakenly marked as tenant-scoped:<br>- Reduces the utility of the RAG system.<br>- Increases storage and maintenance overhead. |
| **Operational Complexity** | Lower: single index to maintain, simpler ingestion and querying. | Higher: requires tenant context management, more complex ingestion (assigning tenant_id), and querying (filtering). |
| **Scalability** | Scales well with number of tenants (same index size). | Scales linearly with number of tenants (more data to store and index). |
| **Cost** | Lower storage and query costs (shared index). | Higher storage and query costs (more data, more indexes). |
| **Reversibility** | Easy to change a piece of knowledge from global to tenant-scoped (by setting tenant_id) if isolation is in place. | Easy to change from tenant-scoped to global (by setting tenant_id = NULL) if the knowledge is deemed appropriate for sharing. |
| **Compliance (Ley 1581)** | Must still comply with data minimization: delete when no longer needed. | Must comply per tenant: ability to delete tenant-specific data upon request or contract end. |
| **Impact on RAG Quality** | High-quality, broad knowledge base benefits all tenants. | Enables differentiation and proprietary value per tenant, but may fragment the knowledge base. |
| **Implementation Effort** | Lower: current system is already global-only. | Higher: requires changes to ingestion, storage, retrieval, and potentially the data model. |

### Recommendation for GlowApp

Based on the analysis, GlowApp should maintain a **dual-mode approach**:

1. **Global Knowledge Tier:** 
   - Keep the current `beauty_knowledge_embeddings` as global (tenant_id = NULL) for foundational beauty knowledge that is truly common to all tenants.
   - This preserves the existing investment and simplicity.

2. **Tenant-Scoped Knowledge Tier (Optional but Recommended for Differentiation):**
   - If tenants require the ability to store and retrieve proprietary knowledge, implement a tenant-scoped tier.
   - This can be done by:
     - Adding a `tenant_id` column to `beauty_knowledge_embeddings` (making it nullable to support both global and tenant-scoped rows).
     - Ensuring that the RAG service can be queried in two modes: global-only, tenant-scoped, or combined (based on request context).
     - Applying RLS or query filtering to isolate tenant-scoped rows.
   - This approach allows a gradual migration: start with global-only, then add tenant-scoped capability as needed.

### Risk Mitigation

- To prevent leakage of tenant-scoped knowledge into the global tier, enforce that:
  - Any knowledge ingested with a specific tenant context must have `tenant_id` set.
  - The RAG service, when in tenant-scoped mode, MUST include `tenant_id` filtering.
  - Regular audits should verify that no tenant-scoped knowledge appears as global (tenant_id = NULL) unless explicitly intended.

### Conclusion

The choice between global and tenant-scoped is not binary; GlowApp can support both, with clear guidelines on what belongs where. The global tier should remain for foundational knowledge, while the tenant-scoped tier enables differentiation and compliance with tenant-specific data ownership requirements.

---
*This matrix is based on the current state of the GlowApp RAG system and the requirements outlined in the D-004 authorization.*
*No modifications to code, database, or configuration were made during this analysis.*