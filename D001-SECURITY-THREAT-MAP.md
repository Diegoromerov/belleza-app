# D001-SECURITY-THREAT-MAP.md

# SECURITY THREAT MAP FOR MULTI-TENANCY IN GLOWAPP

Based on code inspection (controllers, services, routes, models, config), the following threats were analyzed. Where no evidence was found, it is explicitly stated.

| Threat | Evidence Found | Details / Location |
|--------|----------------|--------------------|
| **Horizontal Privilege Escalation** | NO EVIDENCE FOUND | In the inspected endpoints (bookingRoutes, serviceRoutes, providerRoutes, authRoutes, etc.), all queries that access user-specific data filter by `req.user.id` (either directly or via joins). No endpoint was observed that accepts a user/provider ID from the URL or body without verifying it matches the authenticated user. However, a full audit of all endpoints (including admin, configuration, and less-used routes) is required to confirm absence. |
| **Broken Object Level Authorization** | NO EVIDENCE FOUND | Similar to above: endpoints that retrieve, update, or delete objects (e.g., `/bookings/:id/pay`, `/services/:id`) first fetch the object and then check ownership (e.g., ensuring the booking's `client_id` matches `req.user.id` or the service's `provider_id` matches `req.user.id`). No missing ownership checks were observed in the inspected code. |
| **Missing tenant filter** | EVIDENCE FOUND: **NO CURRENT TENANT_ID COLUMN** | Since there is no `tenant_id` column in any table, **all current queries lack a tenant filter**. This is not a bug per se because there is no tenant concept implemented yet, but it means that if multi-tenancy is added, every query will need to be updated to include a `tenant_id` condition. |
| **Cross-tenant JOIN** | NO EVIDENCE FOUND | No JOINs were observed that could combine data from different tenants without an explicit tenant filter, simply because there is no tenant column to filter on. Once tenant_id is added, developers must ensure that JOINs between tables include the tenant_id condition (either explicitly or via shared column) to avoid accidental cross-tenant data combination. |
| **Cross-tenant search** | NO EVIDENCE FOUND | Search operations observed (e.g., in booking listings, service listings) are scoped to the authenticated user's ID. No global search that ignores user context was found in the inspected code. |
| **Cross-tenant report** | NO EVIDENCE FOUND | Reports inspected (e.g., in `analyticsController` – not fully inspected here) were not observed to aggregate data without user scoping. However, any reporting functionality that sums or averages across all users would need to be adjusted to group by tenant_id. |
| **Cross-tenant cache** | NO EVIDENCE FOUND | Redis is used (per `backend/src/config/redis.js`), but the specific usage of Redis keys was not inspected in detail. To prevent cross-tenant data leakage via cache, any cached data must include tenant_id (or a derived user/salon identifier) in the cache key. Without such scoping, cached data from one tenant could be served to another. |
| **Cross-tenant file** | NO EVIDENCE FOUND | No local file storage was observed in the code inspected. Fields like `foto_url`, `documento_id_url` suggest that files are stored externally (likely in a cloud storage bucket) and only URLs are saved. If the external storage does not enforce access controls per tenant (e.g., using signed URLs or bucket policies), then there is a risk that a URL from one tenant could be accessed by another. This requires verification of the external storage configuration. |
| **Cross-tenant background job** | NO EVIDENCE FOUND | No evidence of background job systems (e.g., Bull, Agenda, node-cron) was found in the inspected code (`package.json`, `src/`). If such systems are introduced in the future, they must be designed to carry tenant context (e.g., by including tenant_id in job data) and process data only for the appropriate tenant. |
| **Cross-tenant RAG retrieval** | EVIDENCE FOUND: **RAG TABLE LACKS tenant_id** | The table `beauty_knowledge_embeddings` (lines 282-291 in `backend/schema.sql`) does **not** include a `tenant_id` column. If the RAG system is used to retrieve knowledge that is specific to a tenant (e.g., salon-specific promotions, internal protocols), then there is a risk of cross-tenant retrieval. If the knowledge is intended to be global and shared (e.g., general beauty knowledge), then the risk is low. The intended use of this RAG corpus must be clarified to determine if tenant isolation is required. |

## CONCLUSION

The primary finding is the **absence of a tenant identifier** in the current data model, which means that **all multi-tenancy–related threats are currently latent** (they would manifest only after a tenant concept is introduced and queries are not properly filtered). 

Once a tenant_id column is added, the development team must ensure that:
- All queries (both ORM and raw) include the tenant_id condition.
- JOINs between tables respect tenant_id.
- Cache keys include tenant_id.
- External storage enforces per-tenant access.
- Background jobs process only the appropriate tenant's data.
- RAG retrieval is scoped by tenant if the knowledge is tenant-specific.

Addressing these points will mitigate the identified threats.

--- 
Fin del mapa de amenazas.