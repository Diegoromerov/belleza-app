// backend/src/services/contextResolutionService.js
const { pool } = require('../config/db');

/**
 * Node Contract — Context Resolution v1.0
 * Resolves Available Contexts for an authenticated Identity within its Tenant.
 *
 * @param {number} identityId - Authenticated user ID (from verified JWT / session)
 * @returns {Promise<Object>} Deterministic resolution object
 */
const resolveAvailableContexts = async (identityId) => {
  if (!identityId || isNaN(Number(identityId))) {
    const error = new Error('IDENTITY_NOT_FOUND');
    error.code = 'IDENTITY_NOT_FOUND';
    error.statusCode = 401;
    throw error;
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 1. Server-Side Tenant Resolution from Identity using SECURITY DEFINER function
    const tenantRes = await client.query(
      'SELECT fn_resolve_user_tenant($1) AS tenant_id',
      [identityId]
    );

    const tenantId = tenantRes.rows[0]?.tenant_id;
    if (!tenantId) {
      await client.query('ROLLBACK');
      const error = new Error('IDENTITY_OR_TENANT_NOT_FOUND');
      error.code = 'IDENTITY_NOT_FOUND';
      error.statusCode = 404;
      throw error;
    }

    // 2. Establish Tenant Context for RLS
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    // 3. Query Active Memberships and Related SaaS Entities
    const query = `
      SELECT 
        m.id AS membership_id,
        m.tenant_id,
        t.name AS tenant_name,
        o.id AS organization_id,
        o.legal_name AS organization_legal_name,
        e.id AS establishment_id,
        e.name AS establishment_name,
        e.slug AS establishment_slug,
        e.is_active AS establishment_is_active,
        m.role,
        m.relation_type,
        m.status AS membership_status
      FROM memberships m
      INNER JOIN tenants t ON t.id = m.tenant_id
      INNER JOIN establishments e ON e.id = m.establishment_id AND e.tenant_id = m.tenant_id
      INNER JOIN organizations o ON o.id = e.organization_id AND o.tenant_id = m.tenant_id
      WHERE m.user_id = $1
        AND m.tenant_id = $2
        AND m.status = 'ACTIVE'
      ORDER BY o.legal_name ASC, e.name ASC, m.id ASC;
    `;

    const result = await client.query(query, [identityId, tenantId]);
    await client.query('COMMIT');

    const count = result.rows.length;
    let resolutionStatus = 'NO_CONTEXT';
    if (count === 1) {
      resolutionStatus = 'ONE_CONTEXT';
    } else if (count >= 2) {
      resolutionStatus = 'MULTIPLE_CONTEXTS';
    }

    return {
      resolution_status: resolutionStatus,
      identity_id: Number(identityId),
      tenant_id: Number(tenantId),
      available_contexts_count: count,
      available_contexts: result.rows.map((row) => ({
        membership_id: row.membership_id,
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
      })),
    };
  } catch (err) {
    try {
      await client.query('ROLLBACK');
    } catch (_) {}
    throw err;
  } finally {
    client.release();
  }
};

module.exports = {
  resolveAvailableContexts,
};