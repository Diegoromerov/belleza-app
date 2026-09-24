// backend/src/services/crearDesdeCeroService.js
const { pool } = require('../config/db');

/**
 * Node Contract — Crear Desde Cero v1.0 Service
 * Compiles an in-memory, transient Context Package for handover to Pre-Nodo 01.
 * Consumes Active Context under PostgreSQL multitenant RLS isolation.
 */

/**
 * Compiles the canonical 16-attribute Context Package in memory.
 *
 * @param {number} identityId - Authenticated user ID (req.user.id)
 * @param {number} tenantId - Resolved tenant ID (req.tenantId)
 * @param {string} establishmentId - Validated establishment UUID (req.establishmentId)
 * @param {Object} activeContext - Canonical active context DTO (req.activeContext)
 * @param {Object} clientPayload - In-memory configuration data submitted by client
 * @returns {Promise<Object>} Handover Context Package DTO
 */
const compileContextPackage = async (identityId, tenantId, establishmentId, activeContext, clientPayload = {}) => {
  // 1. Validate mandatory server-side context
  if (!identityId || !tenantId || !establishmentId || !activeContext) {
    const error = new Error('ACTIVE_CONTEXT_REQUIRED');
    error.code = 'ACTIVE_CONTEXT_REQUIRED';
    error.statusCode = 400;
    throw error;
  }

  // 2. Authorize role: strictly OWNER or MANAGER (H-CDC-009)
  const userRole = activeContext.role;
  if (userRole !== 'OWNER' && userRole !== 'MANAGER') {
    const error = new Error('Acceso denegado. Crear Desde Cero requiere rol OWNER o MANAGER.');
    error.code = 'INSUFFICIENT_PROVISIONING_ROLE';
    error.statusCode = 403;
    throw error;
  }

  // 3. Authorize membership status: strictly ACTIVE
  if (activeContext.membership_status !== 'ACTIVE') {
    const error = new Error('Membresía no activa. Se requiere estado ACTIVE.');
    error.code = 'MEMBERSHIP_NOT_ACTIVE';
    error.statusCode = 403;
    throw error;
  }

  const client = await pool.connect();
  const blocks = [];

  try {
    await client.query('BEGIN');

    // 4. Establish Tenant Context for PostgreSQL RLS
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    // 5. Query Establishment & Organization Details
    const estQuery = `
      SELECT 
        e.id AS establishment_id,
        e.name AS establishment_name,
        e.slug AS establishment_slug,
        e.city AS establishment_city,
        e.address AS establishment_address,
        e.phone AS establishment_phone,
        e.operating_hours AS establishment_operating_hours,
        o.id AS organization_id,
        o.legal_name AS organization_legal_name
      FROM establishments e
      INNER JOIN organizations o ON o.id = e.organization_id AND o.tenant_id = e.tenant_id
      WHERE e.id = $1 AND e.tenant_id = $2;
    `;

    const estResult = await client.query(estQuery, [establishmentId, tenantId]);

    if (estResult.rows.length === 0) {
      await client.query('ROLLBACK');
      const error = new Error('ESTABLISHMENT_NOT_FOUND');
      error.code = 'ESTABLISHMENT_NOT_FOUND';
      error.statusCode = 404;
      throw error;
    }

    const estRow = estResult.rows[0];

    // 6. Query Existing ACTIVE Staff Memberships for this establishment
    const staffQuery = `
      SELECT 
        m.id AS membership_id,
        m.user_id,
        u.nombre AS user_name,
        u.email AS user_email,
        m.role,
        m.relation_type,
        m.status
      FROM memberships m
      INNER JOIN usuarios u ON u.id = m.user_id AND u.tenant_id = m.tenant_id
      WHERE m.establishment_id = $1 
        AND m.tenant_id = $2 
        AND m.status = 'ACTIVE'
      ORDER BY m.joined_at ASC;
    `;

    const staffResult = await client.query(staffQuery, [establishmentId, tenantId]);
    await client.query('COMMIT');

    const activeStaffRows = staffResult.rows;
    const activeStaffMap = new Set(activeStaffRows.map((s) => s.membership_id));

    // 7. Validate & Process In-Memory Services (DEC-CDC-001: No DB Persistence)
    const rawServices = Array.isArray(clientPayload.services) ? clientPayload.services : [];
    const relevantServices = [];

    for (const s of rawServices) {
      if (!s || typeof s !== 'object') {
        blocks.push('MALFORMED_SERVICES_PAYLOAD');
        continue;
      }
      const name = typeof s.name === 'string' ? s.name.trim() : '';
      const durationMinutes = Number(s.duration_minutes);
      const price = Number(s.price);

      if (!name || isNaN(durationMinutes) || durationMinutes <= 0 || isNaN(price) || price < 0) {
        blocks.push('MALFORMED_SERVICES_PAYLOAD');
      }

      relevantServices.push({
        name: name || 'Servicio sin nombre',
        category: s.category || 'GENERAL',
        duration_minutes: !isNaN(durationMinutes) && durationMinutes > 0 ? durationMinutes : 30,
        price: !isNaN(price) && price >= 0 ? price : 0.0,
        description: s.description || '',
      });
    }

    // 8. Validate & Process Staff References (DEC-CDC-002: Only pre-existing ACTIVE memberships)
    const rawStaffAssignments = Array.isArray(clientPayload.staff_assignments) ? clientPayload.staff_assignments : [];
    for (const assignment of rawStaffAssignments) {
      if (!assignment || !assignment.membership_id || !activeStaffMap.has(assignment.membership_id)) {
        blocks.push('INVALID_STAFF_REFERENCE');
      }
    }

    const peopleInitialRoles = activeStaffRows.map((staff) => {
      const assignment = rawStaffAssignments.find((a) => a && a.membership_id === staff.membership_id);
      return {
        membership_id: staff.membership_id,
        user_id: staff.user_id,
        user_name: staff.user_name,
        user_email: staff.user_email,
        role: staff.role,
        relation_type: staff.relation_type,
        status: staff.status,
        assigned_categories: assignment && Array.isArray(assignment.assigned_categories) ? assignment.assigned_categories : [],
      };
    });

    // 9. Derive Deterministic State (H-CDC-002)
    let derivedState = 'INITIAL';
    if (blocks.length > 0) {
      derivedState = 'BLOCKED';
    } else if (relevantServices.length > 0 || (clientPayload.activities && clientPayload.activities.length > 0)) {
      derivedState = 'READY_FOR_PRE_NODE_01';
    } else {
      derivedState = 'IN_PROGRESS';
    }

    // 10. Assemble Canonical 16-Attribute Context Package
    const contextPackage = {
      organization: {
        id: estRow.organization_id,
        legal_name: estRow.organization_legal_name,
      },
      establishments: {
        id: estRow.establishment_id,
        name: estRow.establishment_name,
        slug: estRow.establishment_slug,
        city: estRow.establishment_city,
        address: estRow.establishment_address,
        phone: estRow.establishment_phone,
        operating_hours: estRow.establishment_operating_hours || {},
      },
      activities: Array.isArray(clientPayload.activities) ? clientPayload.activities : [],
      relevant_services: relevantServices,
      people_initial_roles: peopleInitialRoles,
      identity: {
        id: identityId,
        role: userRole,
      },
      state: derivedState,
      known_evidence: {
        active_context_verified: true,
        tenant_isolation_verified: true,
        authorized_membership_verified: true,
      },
      decisions: clientPayload.decisions || {
        catalog_mode: 'STANDARD_SETUP',
        provisioning_source: 'CREAR_DESDE_CERO_v1.0',
      },
      applicable_rules: [
        'ARCH-AC-001-HEADER-TRANSPORT',
        'ARCH-RLS-TENANT-ISOLATION',
        'ARCH-OWNER-MANAGER-AUTHORITY',
      ],
      conditions: {
        active_membership_satisfied: true,
        establishment_context_satisfied: true,
      },
      procedures: {
        handover_target: 'PRE_NODE_01',
        handover_type: 'IN_MEMORY_TRANSIENT',
      },
      dependencies: [
        'ACTIVE_ESTABLISHMENT_CONTEXT',
        'ACTIVE_AUTHORIZED_MEMBERSHIP',
      ],
      blocks: [...new Set(blocks)],
      route: 'HUB_SALON -> CREAR_DESDE_CERO -> PRE_NODO_01',
      entry_state: {
        context_source: 'HUB_SALON_ACTIVE_CONTEXT',
        provisioning_mode: 'INITIAL_BOOTSTRAP',
      },
    };

    return {
      context_package: contextPackage,
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
  compileContextPackage,
};
