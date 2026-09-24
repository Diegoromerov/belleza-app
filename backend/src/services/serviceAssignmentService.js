// backend/src/services/serviceAssignmentService.js
const { pool } = require('../config/db');

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function isValidUUID(val) {
  return typeof val === 'string' && UUID_REGEX.test(val);
}

function createError(code, message, statusCode = 400) {
  const err = new Error(message);
  err.code = code;
  err.statusCode = statusCode;
  return err;
}

/**
 * Creates an operational assignment between a Service Offer and a Membership.
 *
 * @param {number} tenantId
 * @param {string} establishmentId
 * @param {Object} activeContext
 * @param {Object} data - { service_offer_id, membership_id }
 */
const createAssignment = async (tenantId, establishmentId, activeContext, data) => {
  if (!tenantId || !establishmentId || !activeContext) {
    throw createError('ACTIVE_CONTEXT_REQUIRED', 'Contexto activo no inicializado o incompleto.', 400);
  }

  // RBAC Check: Only OWNER or MANAGER can create assignments
  if (!['OWNER', 'MANAGER'].includes(activeContext.role)) {
    throw createError('INSUFFICIENT_ROLE_AUTHORITY', 'Se requiere rol OWNER o MANAGER para crear asignaciones.', 403);
  }

  const { service_offer_id, membership_id } = data || {};

  if (!isValidUUID(service_offer_id)) {
    throw createError('INVALID_PAYLOAD', 'El identificador de la oferta (service_offer_id) debe ser un UUID válido.', 400);
  }

  if (!isValidUUID(membership_id)) {
    throw createError('INVALID_PAYLOAD', 'El identificador de la membresía (membership_id) debe ser un UUID válido.', 400);
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Set Tenant Context for PostgreSQL RLS
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    // 2. Verify Service Offer belongs to active establishment & tenant
    const offerQuery = `
      SELECT id FROM service_offers 
      WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3;
    `;
    const offerRes = await client.query(offerQuery, [service_offer_id, establishmentId, tenantId]);
    if (offerRes.rows.length === 0) {
      throw createError('SERVICE_OFFER_NOT_FOUND', 'La oferta de servicio especificada no existe en la sede activa.', 404);
    }

    // 3. Verify Target Membership
    const memQuery = `
      SELECT id, status, role, establishment_id, tenant_id 
      FROM memberships 
      WHERE id = $1;
    `;
    const memRes = await client.query(memQuery, [membership_id]);
    if (memRes.rows.length === 0) {
      throw createError('MEMBERSHIP_NOT_FOUND', 'La membresía destino no existe.', 404);
    }

    const targetMem = memRes.rows[0];

    // Check establishment & tenant match
    if (targetMem.establishment_id !== establishmentId || targetMem.tenant_id !== tenantId) {
      throw createError('CROSS_ESTABLISHMENT_MISMATCH', 'La membresía destino no pertenece al establecimiento activo o tenant.', 422);
    }

    // Check status
    if (targetMem.status !== 'ACTIVE') {
      throw createError('MEMBERSHIP_NOT_ACTIVE', 'La membresía destino no está en estado ACTIVE.', 403);
    }

    // R2: Active Professional Target check
    // Eligible roles for operational service delivery in establishment
    const ELIGIBLE_PROFESSIONAL_ROLES = ['PROFESSIONAL', 'OWNER', 'MANAGER'];
    if (!ELIGIBLE_PROFESSIONAL_ROLES.includes(targetMem.role)) {
      throw createError('INELIGIBLE_PROFESSIONAL_TARGET', 'La membresía destino no representa un contexto profesional elegible para prestar servicios.', 403);
    }

    // 4. Check Duplicate Assignment
    const dupQuery = `
      SELECT id FROM service_assignments
      WHERE service_offer_id = $1 AND membership_id = $2 AND establishment_id = $3 AND tenant_id = $4;
    `;
    const dupRes = await client.query(dupQuery, [service_offer_id, membership_id, establishmentId, tenantId]);
    if (dupRes.rows.length > 0) {
      throw createError('ASSIGNMENT_ALREADY_EXISTS', 'Ya existe una asignación activa entre esta oferta y este colaborador en esta sede.', 409);
    }

    // 5. Insert Assignment
    const insertQuery = `
      INSERT INTO service_assignments (tenant_id, establishment_id, service_offer_id, membership_id)
      VALUES ($1, $2, $3, $4)
      RETURNING id, tenant_id, establishment_id, service_offer_id, membership_id, created_at;
    `;
    const insertRes = await client.query(insertQuery, [tenantId, establishmentId, service_offer_id, membership_id]);

    await client.query('COMMIT');

    const row = insertRes.rows[0];
    return {
      assignment: {
        id: row.id,
        tenant_id: row.tenant_id,
        establishment_id: row.establishment_id,
        service_offer_id: row.service_offer_id,
        membership_id: row.membership_id,
        created_at: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
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
 * Lists all assignments for the active establishment.
 *
 * @param {number} tenantId
 * @param {string} establishmentId
 * @param {Object} activeContext
 */
const listEstablishmentAssignments = async (tenantId, establishmentId, activeContext) => {
  if (!tenantId || !establishmentId || !activeContext) {
    throw createError('ACTIVE_CONTEXT_REQUIRED', 'Contexto activo no inicializado o incompleto.', 400);
  }

  if (!['OWNER', 'MANAGER', 'PROFESSIONAL', 'RECEPTIONIST'].includes(activeContext.role)) {
    throw createError('INSUFFICIENT_ROLE_AUTHORITY', 'No tiene permisos para consultar asignaciones.', 403);
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    const selectQuery = `
      SELECT id, tenant_id, establishment_id, service_offer_id, membership_id, created_at
      FROM service_assignments
      WHERE establishment_id = $1 AND tenant_id = $2
      ORDER BY created_at ASC;
    `;

    const result = await client.query(selectQuery, [establishmentId, tenantId]);
    await client.query('COMMIT');

    return {
      assignments: result.rows.map((row) => ({
        id: row.id,
        tenant_id: row.tenant_id,
        establishment_id: row.establishment_id,
        service_offer_id: row.service_offer_id,
        membership_id: row.membership_id,
        created_at: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
      })),
      count: result.rows.length,
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
 * Retrieves all assignments for a specific staff membership in the active establishment.
 *
 * @param {number} tenantId
 * @param {string} establishmentId
 * @param {Object} activeContext
 * @param {string} membershipId
 */
const getAssignmentsByStaff = async (tenantId, establishmentId, activeContext, membershipId) => {
  if (!tenantId || !establishmentId || !activeContext) {
    throw createError('ACTIVE_CONTEXT_REQUIRED', 'Contexto activo no inicializado o incompleto.', 400);
  }

  if (!isValidUUID(membershipId)) {
    throw createError('INVALID_PAYLOAD', 'El identificador de la membresía debe ser un UUID válido.', 400);
  }

  if (!['OWNER', 'MANAGER', 'PROFESSIONAL', 'RECEPTIONIST'].includes(activeContext.role)) {
    throw createError('INSUFFICIENT_ROLE_AUTHORITY', 'No tiene permisos para consultar asignaciones.', 403);
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    // Verify membership belongs to active establishment
    const memQuery = `
      SELECT id FROM memberships 
      WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3;
    `;
    const memRes = await client.query(memQuery, [membershipId, establishmentId, tenantId]);
    if (memRes.rows.length === 0) {
      throw createError('MEMBERSHIP_NOT_FOUND', 'La membresía no existe en la sede activa.', 404);
    }

    const selectQuery = `
      SELECT id, tenant_id, establishment_id, service_offer_id, membership_id, created_at
      FROM service_assignments
      WHERE membership_id = $1 AND establishment_id = $2 AND tenant_id = $3
      ORDER BY created_at ASC;
    `;

    const result = await client.query(selectQuery, [membershipId, establishmentId, tenantId]);
    await client.query('COMMIT');

    return {
      membership_id: membershipId,
      assignments: result.rows.map((row) => ({
        id: row.id,
        tenant_id: row.tenant_id,
        establishment_id: row.establishment_id,
        service_offer_id: row.service_offer_id,
        membership_id: row.membership_id,
        created_at: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
      })),
      count: result.rows.length,
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
 * Retrieves all assignments for a specific Service Offer in the active establishment.
 *
 * @param {number} tenantId
 * @param {string} establishmentId
 * @param {Object} activeContext
 * @param {string} serviceOfferId
 */
const getAssignmentsByOffer = async (tenantId, establishmentId, activeContext, serviceOfferId) => {
  if (!tenantId || !establishmentId || !activeContext) {
    throw createError('ACTIVE_CONTEXT_REQUIRED', 'Contexto activo no inicializado o incompleto.', 400);
  }

  if (!isValidUUID(serviceOfferId)) {
    throw createError('INVALID_PAYLOAD', 'El identificador de la oferta debe ser un UUID válido.', 400);
  }

  if (!['OWNER', 'MANAGER', 'PROFESSIONAL', 'RECEPTIONIST'].includes(activeContext.role)) {
    throw createError('INSUFFICIENT_ROLE_AUTHORITY', 'No tiene permisos para consultar asignaciones.', 403);
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    // Verify service offer belongs to active establishment
    const offerQuery = `
      SELECT id FROM service_offers 
      WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3;
    `;
    const offerRes = await client.query(offerQuery, [serviceOfferId, establishmentId, tenantId]);
    if (offerRes.rows.length === 0) {
      throw createError('SERVICE_OFFER_NOT_FOUND', 'La oferta de servicio no existe en la sede activa.', 404);
    }

    const selectQuery = `
      SELECT id, tenant_id, establishment_id, service_offer_id, membership_id, created_at
      FROM service_assignments
      WHERE service_offer_id = $1 AND establishment_id = $2 AND tenant_id = $3
      ORDER BY created_at ASC;
    `;

    const result = await client.query(selectQuery, [serviceOfferId, establishmentId, tenantId]);
    await client.query('COMMIT');

    return {
      service_offer_id: serviceOfferId,
      assignments: result.rows.map((row) => ({
        id: row.id,
        tenant_id: row.tenant_id,
        establishment_id: row.establishment_id,
        service_offer_id: row.service_offer_id,
        membership_id: row.membership_id,
        created_at: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
      })),
      count: result.rows.length,
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
 * Pure Unassignment (DEC-AS-012): Deletes the assignment relation only.
 * Leaves Service Offer and Membership completely untouched.
 *
 * @param {number} tenantId
 * @param {string} establishmentId
 * @param {Object} activeContext
 * @param {string} id - Assignment UUID
 */
const deleteAssignment = async (tenantId, establishmentId, activeContext, id) => {
  if (!tenantId || !establishmentId || !activeContext) {
    throw createError('ACTIVE_CONTEXT_REQUIRED', 'Contexto activo no inicializado o incompleto.', 400);
  }

  if (!isValidUUID(id)) {
    throw createError('INVALID_PAYLOAD', 'El identificador de la asignación debe ser un UUID válido.', 400);
  }

  if (!['OWNER', 'MANAGER'].includes(activeContext.role)) {
    throw createError('INSUFFICIENT_ROLE_AUTHORITY', 'Se requiere rol OWNER o MANAGER para eliminar asignaciones.', 403);
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    const deleteQuery = `
      DELETE FROM service_assignments
      WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3
      RETURNING id;
    `;

    const result = await client.query(deleteQuery, [id, establishmentId, tenantId]);

    if (result.rows.length === 0) {
      throw createError('ASSIGNMENT_NOT_FOUND', 'La asignación no existe en la sede activa.', 404);
    }

    await client.query('COMMIT');

    return {
      deleted_id: id,
      unassigned: true,
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
  createAssignment,
  listEstablishmentAssignments,
  getAssignmentsByStaff,
  getAssignmentsByOffer,
  deleteAssignment,
};
