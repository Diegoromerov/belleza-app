// backend/src/services/hubSalonService.js
const { pool } = require('../config/db');

/**
 * Node Contract — Hub Salón v1.0 Service
 * Fetches cockpit summary and staff overview for the active establishment.
 */

/**
 * Retrieves the operational summary for the active establishment.
 *
 * @param {number} tenantId - Resolved tenant ID from active context
 * @param {string} establishmentId - Validated establishment UUID from active context
 * @param {Object} activeContext - Canonical active context DTO
 * @returns {Promise<Object>} Structured Hub Summary DTO
 */
const getHubSummary = async (tenantId, establishmentId, activeContext) => {
  if (!tenantId || !establishmentId || !activeContext) {
    const error = new Error('ACTIVE_CONTEXT_REQUIRED');
    error.code = 'ACTIVE_CONTEXT_REQUIRED';
    error.statusCode = 400;
    throw error;
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 1. Establish Tenant Context for PostgreSQL RLS
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    // 2. Query Establishment & Organization Details
    const establishmentQuery = `
      SELECT 
        e.id AS establishment_id,
        e.name AS establishment_name,
        e.slug AS establishment_slug,
        e.phone AS establishment_phone,
        e.address AS establishment_address,
        e.city AS establishment_city,
        e.is_active AS establishment_is_active,
        e.operating_hours AS establishment_operating_hours,
        o.id AS organization_id,
        o.legal_name AS organization_legal_name
      FROM establishments e
      INNER JOIN organizations o ON o.id = e.organization_id AND o.tenant_id = e.tenant_id
      WHERE e.id = $1 AND e.tenant_id = $2;
    `;

    const estResult = await client.query(establishmentQuery, [establishmentId, tenantId]);

    if (estResult.rows.length === 0) {
      await client.query('ROLLBACK');
      const error = new Error('ESTABLISHMENT_NOT_FOUND');
      error.code = 'ESTABLISHMENT_NOT_FOUND';
      error.statusCode = 404;
      throw error;
    }

    const estRow = estResult.rows[0];

    // 3. Query Active Staff Count for the establishment
    const staffCountQuery = `
      SELECT COUNT(*)::int AS active_members_count
      FROM memberships
      WHERE establishment_id = $1 AND tenant_id = $2 AND status = 'ACTIVE';
    `;

    const countResult = await client.query(staffCountQuery, [establishmentId, tenantId]);
    await client.query('COMMIT');

    const activeMembersCount = countResult.rows[0]?.active_members_count || 0;

    return {
      summary: {
        establishment: {
          id: estRow.establishment_id,
          name: estRow.establishment_name,
          slug: estRow.establishment_slug,
          phone: estRow.establishment_phone,
          address: estRow.establishment_address,
          city: estRow.establishment_city,
          is_active: Boolean(estRow.establishment_is_active),
          operating_hours: estRow.establishment_operating_hours || {},
        },
        organization: {
          id: estRow.organization_id,
          legal_name: estRow.organization_legal_name,
        },
        active_user_context: {
          membership_id: activeContext.active_membership_id,
          role: activeContext.role,
          relation_type: activeContext.relation_type,
          status: activeContext.membership_status,
        },
        staff_summary: {
          active_members_count: activeMembersCount,
        },
      },
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

/**
 * Retrieves the list of active staff members for the active establishment.
 *
 * @param {number} tenantId - Resolved tenant ID from active context
 * @param {string} establishmentId - Validated establishment UUID from active context
 * @returns {Promise<Object>} Structured Staff Overview DTO
 */
const getHubStaff = async (tenantId, establishmentId) => {
  if (!tenantId || !establishmentId) {
    const error = new Error('ACTIVE_CONTEXT_REQUIRED');
    error.code = 'ACTIVE_CONTEXT_REQUIRED';
    error.statusCode = 400;
    throw error;
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 1. Establish Tenant Context for PostgreSQL RLS
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    // 2. Query ACTIVE memberships for the establishment joined with user identity
    const staffQuery = `
      SELECT 
        m.id AS membership_id,
        m.user_id,
        u.nombre AS user_name,
        u.email AS user_email,
        m.role,
        m.relation_type,
        m.status,
        m.joined_at
      FROM memberships m
      INNER JOIN usuarios u ON u.id = m.user_id AND u.tenant_id = m.tenant_id
      WHERE m.establishment_id = $1 
        AND m.tenant_id = $2 
        AND m.status = 'ACTIVE'
      ORDER BY m.joined_at ASC;
    `;

    const result = await client.query(staffQuery, [establishmentId, tenantId]);
    await client.query('COMMIT');

    return {
      establishment_id: establishmentId,
      staff_count: result.rows.length,
      members: result.rows.map((row) => ({
        membership_id: row.membership_id,
        user_id: row.user_id,
        user_name: row.user_name,
        user_email: row.user_email,
        role: row.role,
        relation_type: row.relation_type,
        status: row.status,
        joined_at: row.joined_at instanceof Date ? row.joined_at.toISOString() : row.joined_at,
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
  getHubSummary,
  getHubStaff,
};
