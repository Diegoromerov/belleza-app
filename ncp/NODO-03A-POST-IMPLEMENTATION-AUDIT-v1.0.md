# NODO-03A — POST-IMPLEMENTATION FORENSIC AUDIT v1.0
## ARCHITECTURAL AUDIT & PHYSICAL STATE REPORT (READ-ONLY)

**NODE IDENTIFIER**: NODO-03A  
**TARGET MODULE**: Staff Operational Availability & Schedule Runtime  
**AUDIT DATE**: 2026-09-11  
**AUDITOR ROLE**: Senior Architecture Auditor  
**AUTHORITY**: Director del Proyecto GlowApp SaaS  
**AUDIT CLASSIFICATION**: READ-ONLY FORENSIC AUDIT — ZERO MUTATION  
**STATUS**: ARCHITECTURAL STOP | VALIDATION BLOCKED | NO REMEDIATION AUTHORIZED 🔒

---

## 1. EXECUTIVE FINDINGS

A forensic, read-only audit of the physical database (`beauty_db` in PostgreSQL 16), backend runtime codebase, and test suites was conducted following the implementation of **NODO-03A**.

### Summary Matrix
- **Physical Schema Accuracy**: The physical table `staff_schedules` implemented in PostgreSQL aligns with `ARCH-BUNDLE-N03A-PHYSICAL-01 (R2)`:
  - `tenant_id` is physically `INTEGER` (`int4`), preserving SaaS Foundation integer isolation.
  - `day_of_week` is physically `SMALLINT` (`int2`) with `CHECK (day_of_week BETWEEN 1 AND 7)`.
  - Column count is exactly **9 columns**; extraneous columns (`is_active`) were **not** created in PostgreSQL.
  - Foreign Keys are strictly composite, referential to `(id, establishment_id, tenant_id)`, and use `ON DELETE RESTRICT`.
  - Row-Level Security (RLS) is active and enforced using `app.tenant_id::integer`.
  - Migration `069_staff_schedules.sql` is formally recorded in `schema_migrations`.
- **Preexisting Systems Integrity**: Zero regressions detected across 86 legacy tests (Foundation, Context Resolution, Active Context, Crear Desde Cero, HUB-SALON, NODO-01, NODO-02).
- **Critical Audit Observations**:
  1. **Documentation Text Errata in Preliminary Implementation Report**: The text in `/ncp/NODO-03A-IMPLEMENTATION-REPORT-v1.0.md` contained typographical description errors (mentioning UUID for tenant_id, 0..6 for days, and is_active in its markdown table) which did not match the actual physical database schema created in PostgreSQL.
  2. **Concurrency Test Gap**: While `staffAvailabilityService.js` implements row locking via `SELECT ... FOR UPDATE` on `memberships`, the automated test suite (`test_staff_availability_suite.js`) runs sequentially and lacks a concurrent multi-connection race test (`Promise.all` stress test) to empirically verify race-condition resistance.

---

## 2. PHYSICAL SCHEMA ACTUAL

Physical schema extracted directly from `information_schema.columns` and PostgreSQL catalogs on table `staff_schedules`:

| # | Column Name | Physical Data Type | UDT Name | Nullable | Default Value |
|---|---|---|---|---|---|
| 1 | `id` | `uuid` | `uuid` | `NO` | `gen_random_uuid()` |
| 2 | `tenant_id` | `integer` | `int4` | `NO` | *None* |
| 3 | `establishment_id` | `uuid` | `uuid` | `NO` | *None* |
| 4 | `membership_id` | `uuid` | `uuid` | `NO` | *None* |
| 5 | `day_of_week` | `smallint` | `int2` | `NO` | *None* |
| 6 | `start_time` | `time without time zone` | `time` | `NO` | *None* |
| 7 | `end_time` | `time without time zone` | `time` | `NO` | *None* |
| 8 | `created_at` | `timestamp with time zone` | `timestamptz` | `NO` | `CURRENT_TIMESTAMP` |
| 9 | `updated_at` | `timestamp with time zone` | `timestamptz` | `NO` | `CURRENT_TIMESTAMP` |

**Total Columns**: Exactly 9.

### Check Constraints (Catalog: `pg_constraint`)
- `chk_staff_schedules_day_range`: `CHECK (((day_of_week >= 1) AND (day_of_week <= 7)))`
- `chk_staff_schedules_time_order`: `CHECK ((start_time < end_time))`

### Unique Constraints (Catalog: `pg_constraint`)
- `uq_staff_schedules_exact_interval`: `UNIQUE (establishment_id, membership_id, day_of_week, start_time)`

---

## 3. EXPECTED ARCHITECTURE

Reference: `ARCH-BUNDLE-N03A-PHYSICAL-01 (R2)` & `NODO-03A-IMPLEMENTATION-CONTRACT-v1.0.md (R1)`:

1. **Tenant ID Type**: `INTEGER` (matching `tenants.id` and SaaS Foundation).
2. **Day Range**: `1..7` (ISO weekday / Monday=1 ... Sunday=7).
3. **Column Count**: Exactly 9 (`id`, `tenant_id`, `establishment_id`, `membership_id`, `day_of_week`, `start_time`, `end_time`, `created_at`, `updated_at`).
4. **Foreign Keys**:
   - `tenant_id -> tenants(id) ON DELETE RESTRICT`
   - `(establishment_id, tenant_id) -> establishments(id, tenant_id) ON DELETE RESTRICT`
   - `(membership_id, establishment_id, tenant_id) -> memberships(id, establishment_id, tenant_id) ON DELETE RESTRICT`
   - Zero speculative direct `membership_id -> memberships(id)` bypass.
   - Zero `ON DELETE CASCADE`.
5. **Indexes**:
   - Primary key on `id`.
   - Unique index on `(establishment_id, membership_id, day_of_week, start_time)`.
   - BTree on `tenant_id`.
   - BTree on `(establishment_id, tenant_id)`.
   - BTree on `(membership_id, establishment_id)`.
6. **RLS**: Row-Level Security enabled with `tenant_isolation_staff_schedules` casting `current_setting('app.tenant_id', true)` to `integer`.

---

## 4. DEVIATION MATRIX

| Architectural Aspect | Expected Architecture | Physical Implementation (Actual) | Deviation Assessment |
|---|---|---|---|
| **`tenant_id` Data Type** | `INTEGER` (`int4`) | `INTEGER` (`int4`) | **CONFORMANT** (0 deviation) |
| **`day_of_week` Range** | `1..7` (`smallint`) | `1..7` (`smallint`, CHECK `1 AND 7`) | **CONFORMANT** (0 deviation) |
| **Column Count** | Exactly 9 columns | Exactly 9 columns | **CONFORMANT** (0 deviation) |
| **`is_active` Column** | **Forbidden** (not in design) | **Absent** (not created) | **CONFORMANT** (0 deviation) |
| **Foreign Keys & Delete Action** | 3 Composite FKs with `ON DELETE RESTRICT` | 3 Composite FKs with `ON DELETE RESTRICT` | **CONFORMANT** (0 deviation) |
| **Indexes** | 3 Secondary + 1 UQ + 1 PK | 3 Secondary + 1 UQ + 1 PK | **CONFORMANT** (0 deviation) |
| **RLS Policy Cast** | `::integer` | `::integer` | **CONFORMANT** (0 deviation) |
| **Migration Registry** | Registered in `schema_migrations` | Recorded as ID 5 (`069_staff_schedules.sql`) | **CONFORMANT** (0 deviation) |
| **Implementation Report Sync** | Accurate reflection of DB | Contained markdown errata (UUID / 0..6 / is_active) | **DOCUMENTATION DRIFT** |
| **Concurrency Verification** | Stress-tested under parallel race | Tested sequentially (20/20) without parallel race test | **TEST COVERAGE GAP** |

---

## 5. RLS AUDIT

Forensic verification from `pg_class` and `pg_policy`:
- **RLS Enabled (`relrowsecurity`)**: `true`
- **Force RLS (`relforcerowsecurity`)**: `false`
- **Policy Name**: `tenant_isolation_staff_schedules`
- **Permissive Mode**: `PERMISSIVE` (`polcmd = '*'`)
- **Expression (`qual`)**:
  ```sql
  (tenant_id = (NULLIF(current_setting('app.tenant_id'::text, true), ''::text))::integer)
  ```
- **With Check (`with_check`)**:
  ```sql
  (tenant_id = (NULLIF(current_setting('app.tenant_id'::text, true), ''::text))::integer)
  ```
- **Audit Conclusion**: Fully conformant with SaaS Foundation multitenant RLS isolation standard.

---

## 6. FOREIGN KEYS AUDIT

Forensic verification from `pg_constraint`:

1. **`fk_staff_schedules_tenant`**:
   `FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT`
2. **`fk_staff_schedules_establishment`**:
   `FOREIGN KEY (establishment_id, tenant_id) REFERENCES establishments(id, tenant_id) ON DELETE RESTRICT`
3. **`fk_staff_schedules_membership`**:
   `FOREIGN KEY (membership_id, establishment_id, tenant_id) REFERENCES memberships(id, establishment_id, tenant_id) ON DELETE RESTRICT`

- **Direct standalone FKs**: None.
- **Delete Actions**: All 3 keys enforce `ON DELETE RESTRICT`.
- **Audit Conclusion**: 100% compliant with DEC-FC-001 and Physical Architecture R2.

---

## 7. INDEX AUDIT

Forensic verification from `pg_indexes`:

| Index Name | Indexed Columns | Type / Unique | Purpose |
|---|---|---|---|
| `staff_schedules_pkey` | `(id)` | `btree` (UNIQUE) | Primary Key lookups |
| `uq_staff_schedules_exact_interval` | `(establishment_id, membership_id, day_of_week, start_time)` | `btree` (UNIQUE) | Collision avoidance on exact interval starts |
| `idx_staff_schedules_tenant_id` | `(tenant_id)` | `btree` | RLS filtering and tenant scoping |
| `idx_staff_schedules_establishment_tenant` | `(establishment_id, tenant_id)` | `btree` | Establishment-scoped schedule retrieval |
| `idx_staff_schedules_membership_establishment` | `(membership_id, establishment_id)` | `btree` | Staff-specific schedule lookups |

- **Audit Conclusion**: All indexes match the non-speculative physical index specification.

---

## 8. RUNTIME AUDIT (`staffAvailabilityService.js`)

Inspection of runtime implementation:
1. **Tenant Resolution**: Tenant ID is passed from active context, cast, and set in session via `SELECT set_config('app.tenant_id', $1, true)`.
2. **Active Context**: Evaluates `activeContext.active_membership_id || activeContext.membershipId`, role, and membership status.
3. **Membership Validation**: Verifies target membership exists, belongs to `(tenant_id, establishment_id)`, and is `status = 'ACTIVE'`. Rejects inactive with `422 INACTIVE_MEMBERSHIP`.
4. **Concurrency Locking (`FOR UPDATE`)**: Employs `SELECT id, status, role, establishment_id, tenant_id FROM memberships WHERE id = $1 FOR UPDATE` inside `BEGIN ... COMMIT` block.
5. **Transaction Boundaries**: Wrapped in explicit `BEGIN ... COMMIT` with `ROLLBACK` on error.
6. **Temporal Overlap Validation**: In-memory half-open interval validation `[start, end)` detects overlap and rejects with `400 OVERLAPPING_INTERVALS`.
7. **Atomic Replacement**: Issues `DELETE FROM staff_schedules WHERE establishment_id = $1 AND membership_id = $2 AND tenant_id = $3` followed by batch `INSERT` within the same transaction.
8. **Delete Semantics**: `deleteStaffSchedule` removes rows from `staff_schedules` only, leaving `memberships` records untouched.
9. **Operating Hours Warning**: Evaluates against `establishment.operating_hours`, calculating `out_of_operating_hours_warning: true` without blocking persistence.
10. **RBAC Authorization**: Restricts `PROFESSIONAL` to bounded self-management; blocks `RECEPTIONIST` and other roles from mutations.

---

## 9. CONCURRENCY TEST AUDIT

Inspection of `test_staff_availability_suite.js`:
- **Sequential Tests**: 20 tests validating RBAC, validation rules, RLS isolation, atomic single-thread replacement, and delete semantics.
- **Race Condition Testing**: **ABSENT**. The test suite does not include a concurrent race test where multiple parallel database connections issue simultaneous `setStaffSchedule` calls on the same `(establishment_id, membership_id)` to verify lock queueing under true asynchronous stress.

---

## 10. MIGRATION STATE

Queried from `schema_migrations`:
- `schema_migrations` table exists in PostgreSQL.
- Entry:
  - `id`: `5`
  - `filename`: `069_staff_schedules.sql`
  - `applied_at`: `2026-09-11 12:45:36.261 +0000`
- Physical migration is active and verified in database.

---

## 11. DATA STATE

- `SELECT count(*) FROM staff_schedules;` -> **0 rows**.
- Database is clean of test debris; all test fixtures were cleared during teardown.

---

## 12. GIT SCOPE

Inspection of working tree status:
- **Modified files**:
  - `backend/index.js` (Route mounting for `/api/v1/saas/hub/staff`)
  - `backend/docker-compose.yml` (Preexisting test environment configuration)
  - `backend/init.sql` (Preexisting test environment configuration)
- **New files (NODO-03A)**:
  - `backend/migrations/069_staff_schedules.sql`
  - `backend/src/services/staffAvailabilityService.js`
  - `backend/src/controllers/staffAvailabilityController.js`
  - `backend/src/routes/staffAvailabilityRoutes.js`
  - `backend/tests/test_staff_availability_suite.js`
  - `ncp/NODO-03A-IMPLEMENTATION-REPORT-v1.0.md`
- **Unexpected files**: Zero.

---

## 13. PROTECTED ASSETS VERIFICATION

All protected assets remain unmodified and 100% compliant:
- Foundation migrations `065`, `066`: Untouched.
- NODO-01 & NODO-02 migrations `067`, `068`: Untouched.
- B2C legacy tables and schemas: Untouched.
- Regression test suites (86/86 tests): 100% PASS with 0 failures.

---

## 14. BLOCKERS & ARCHITECTURAL GAPS

1. **Audit Blocker 1 (Documentation Drift)**: Preliminary report `/ncp/NODO-03A-IMPLEMENTATION-REPORT-v1.0.md` contains erroneous textual descriptions that conflict with the actual physical database schema.
2. **Audit Blocker 2 (Empirical Concurrency Verification)**: Absence of an automated concurrent race-condition test demonstrating that parallel racing requests on the same membership serialize properly without deadlocks or corrupted state.

---

## 15. RECOMMENDATION

1. **Do NOT close NODO-03A** at this gate.
2. Maintain `ARCHITECTURAL STOP` status.
3. Keep physical PostgreSQL schema intact (since DDL `069_staff_schedules.sql` is physically conformant with `ARCH-BUNDLE-N03A-PHYSICAL-01 R2`).
4. Reconcile `/ncp/NODO-03A-IMPLEMENTATION-REPORT-v1.0.md` text to reflect the true physical schema (`INTEGER`, `1..7`, 9 columns).
5. Author a dedicated concurrency stress test in a future authorized remediation step before Director closure.

---

## 16. DECISION REQUIRED

The Director del Proyecto must determine:
- **Option 1**: Authorize formal remediation of documentation drift in `/ncp/NODO-03A-IMPLEMENTATION-REPORT-v1.0.md` and authorize adding a true parallel concurrency test to the test suite.
- **Option 2**: Maintain architectural stop and request structural redesign.

---

```text
================================================================================
  STATUS: ARCHITECTURAL STOP | VALIDATION BLOCKED | NO REMEDIATION AUTHORIZED 🔒
================================================================================
```
