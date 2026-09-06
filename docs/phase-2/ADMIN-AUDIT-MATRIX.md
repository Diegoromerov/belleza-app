# GLOWAPP PHASE 2 — ADMIN AUDIT MATRIX

## 1. Audit Logging Requirements
- **Required Fields:** `timestamp`, `admin_user_id`, `action_type`, `target_resource_type`, `target_resource_id`, `reason_text`, `ip_address`, `previous_state`, `new_state`.
- **Immutability:** Audit records are written to PostgreSQL `audit_logs` table with append-only access.
