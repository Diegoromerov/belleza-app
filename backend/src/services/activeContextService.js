// backend/src/services/activeContextService.js
const { pool } = require('../config/db');

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * Node Contract — Active Context v1.0
 * Validates and derives the Active Context DTO from an explicit membership selection.
 *
 * @param {number|string} identityId - Authenticated user ID (server-side identity)
 * @param {string} membershipId - Explicitly selected membership UUID
 * @returns {Promise<Object>} Canonical Active Context DTO
 */
const validateAndResolveActiveContext = async (identityId, membershipId) => {
  // 1. Input Validation
  if (!identityId || isNaN(Number(identityId))) {
    const error = new Error('IDENTITY_NOT_FOUND');
    error.code = 'IDENTITY_NOT_FOUND';
    error.statusCode = 401;
    throw error;
  }

  if (!membershipId || typeof membershipId !== 'string' || !membershipId.trim()) {
    const error = new Error('MEMBERSHIP_SELECTION_REQUIRED');
    error.code = 'MEMBERSHIP_SELECTION_REQUIRED';
    error.statusCode = 400;
    throw error;
  }

  const cleanMembershipId = membershipId.trim();
  if (!UUID_REGEX.test(cleanMembershipId)) {
    const error = new Error('INVALID_MEMBERSHIP_UUID');
    error.code = 'INVALID_MEMBERSHIP_UUID';
    error.statusCode = 400;
    throw error;
  }

  const numericIdentityId = Number(identityId);
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 2. Server-Side Tenant Resolution via SECURITY DEFINER function (ARCH-CR-001/002)
    const tenantRes = await client.query(
      'SELECT fn_resolve_user_tenant($1) AS tenant_id',
      [numericIdentityId]
    );

    const tenantId = tenantRes.rows[0]?.tenant_id;
    if (!tenantId) {
      await client.query('ROLLBACK');
      const error = new Error('IDENTITY_OR_TENANT_NOT_FOUND');
      error.code = 'IDENTITY_NOT_FOUND';
      error.statusCode = 404;
      throw error;
    }

    // 3. Establish Tenant Isolation Context for PostgreSQL RLS
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    // 4. Query Membership and Relational Chain: Membership -> Establishment -> Organization
    const membershipQuery = `
      SELECT 
        m.id AS membership_id,
        m.tenant_id,
        m.user_id,
        m.role,
        m.relation_type,
        m.status AS membership_status,
        t.name AS tenant_name,
        e.id AS establishment_id,
        e.name AS establishment_name,
        e.slug AS establishment_slug,
        e.is_active AS establishment_is_active,
        o.id AS organization_id,
        o.legal_name AS organization_legal_name
      FROM memberships m
      INNER JOIN tenants t ON t.id = m.tenant_id
      INNER JOIN establishments e ON e.id = m.establishment_id AND e.tenant_id = m.tenant_id
      INNER JOIN organizations o ON o.id = e.organization_id AND o.tenant_id = m.tenant_id
      WHERE m.id = $1;
    `;

    const result = await client.query(membershipQuery, [cleanMembershipId]);
    await client.query('COMMIT');

    if (result.rows.length === 0) {
      // Check if membership belongs to another user/tenant or does not exist
      const error = new Error('MEMBERSHIP_NOT_FOUND');
      error.code = 'MEMBERSHIP_NOT_FOUND';
      error.statusCode = 404;
      throw error;
    }

    const row = result.rows[0];

    // 5. Anti-Impersonation Check: Identity must own the membership
    if (row.user_id !== numericIdentityId) {
      const error = new Error('MEMBERSHIP_ACCESS_DENIED');
      error.code = 'MEMBERSHIP_ACCESS_DENIED';
      error.statusCode = 403;
      throw error;
    }

    // 6. Anti-Cross-Tenant Check: Membership must match server-resolved tenant
    if (row.tenant_id !== tenantId) {
      const error = new Error('TENANT_MISMATCH');
      error.code = 'TENANT_MISMATCH';
      error.statusCode = 403;
      throw error;
    }

    // 7. Status Check: Only ACTIVE memberships are eligible for Active Context
    if (row.membership_status !== 'ACTIVE') {
      const error = new Error('MEMBERSHIP_NOT_ACTIVE');
      error.code = 'MEMBERSHIP_NOT_ACTIVE';
      error.statusCode = 403;
      throw error;
    }

    // 8. Construct Canonical Active Context DTO (Derived server-side)
    return {
      active_membership_id: row.membership_id,
      tenant_id: row.tenant_id,
      tenant_name: row.tenant_name,
      organization_id: row.organization_id,
      organization_legal_name: row.organization_legal_name,
      establishment_id: row.establishment_id,
      establishment_name: row.establishment_name,
      establishment_slug: row.establishment_slug,
      establishment_is_active: Boolean(row.establishment_is_active),
      role: row.role,
      relation_type: row.relation_type,
      membership_status: row.membership_status,
      activated_at: new Date().toISOString(),
    };
  } catch (err) {
    try {
      await client.query('ROLLBACK');
    } catch (rbErr) {
      // ignore rollback errors if connection was closed
    }
    throw err;
  } finally {
    client.release();
  }
};

module.exports = {
  validateAndResolveActiveContext,
};
