// backend/src/services/nodo04MaterializationService.js
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
 * OP-01: Materializes a SaaS Service Assignment downstream into B2C public.services
 * and persists the technical mapping into saas_service_materializations.
 *
 * @param {number} tenantId
 * @param {string} establishmentId
 * @param {Object} activeContext - { tenant_id, establishment_id, role, status, membership_id }
 * @param {Object} data - { service_offer_id, membership_id }
 * @param {Object} user - Authenticated user { id, email }
 */
const materializeServiceAssignment = async (tenantId, establishmentId, activeContext, data, user) => {
  if (!tenantId || !establishmentId || !activeContext) {
    throw createError('ACTIVE_CONTEXT_REQUIRED', 'Contexto activo no inicializado o incompleto.', 400);
  }

  // RBAC Check: Only OWNER or MANAGER can authorize materialization (DEC-AS-003)
  if (!['OWNER', 'MANAGER'].includes(activeContext.role)) {
    throw createError('INSUFFICIENT_ROLE_AUTHORITY', 'Se requiere rol OWNER o MANAGER para autorizar la materialización.', 403);
  }

  const { service_offer_id, membership_id } = data || {};

  if (!isValidUUID(service_offer_id) || !isValidUUID(membership_id)) {
    throw createError('INVALID_PAYLOAD', 'service_offer_id y membership_id deben ser UUIDs válidos.', 400);
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Set Tenant Context for PostgreSQL RLS
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    // 2. Lock & Validate Service Offer in Active Establishment
    const offerQuery = `
      SELECT id, name, description, base_price, base_duration
      FROM public.service_offers
      WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3
      FOR SHARE;
    `;
    const offerRes = await client.query(offerQuery, [service_offer_id, establishmentId, tenantId]);
    if (offerRes.rows.length === 0) {
      throw createError('SERVICE_OFFER_NOT_FOUND', 'La oferta de servicio especificada no existe en la sede activa.', 404);
    }
    const offer = offerRes.rows[0];

    const priceNum = parseFloat(offer.base_price);
    const durationNum = parseInt(offer.base_duration, 10);
    if (isNaN(priceNum) || priceNum < 0 || isNaN(durationNum) || durationNum <= 0) {
      throw createError('INVALID_SERVICE_OFFER', 'La oferta de servicio posee duración o precio inválidos.', 400);
    }

    // 3. Lock & Validate Membership in Active Establishment
    const memberQuery = `
      SELECT id, user_id, role, status
      FROM public.memberships
      WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3
      FOR SHARE;
    `;
    const memberRes = await client.query(memberQuery, [membership_id, establishmentId, tenantId]);
    if (memberRes.rows.length === 0) {
      throw createError('MEMBERSHIP_NOT_FOUND', 'La membresía especificada no existe en la sede activa.', 404);
    }
    const membership = memberRes.rows[0];

    if (membership.status !== 'ACTIVE' || membership.role !== 'PROFESSIONAL') {
      throw createError('NON_OPERABLE_STAFF_MEMBER', 'El colaborador debe poseer membresía ACTIVE con rol PROFESSIONAL.', 422);
    }

    // 4. Verify Service Assignment Exists
    const assignmentQuery = `
      SELECT id
      FROM public.service_assignments
      WHERE service_offer_id = $1 AND membership_id = $2;
    `;
    const assignmentRes = await client.query(assignmentQuery, [service_offer_id, membership_id]);
    if (assignmentRes.rows.length === 0) {
      throw createError('SERVICE_ASSIGNMENT_NOT_FOUND', 'No existe una asignación operativa previa para esta oferta y colaborador.', 404);
    }

    // 5. Verify Provider Profile Pre-Existence (DEC-B: Auto-Provisioning REJECTED)
    const providerQuery = `
      SELECT id
      FROM public.perfiles_prestador
      WHERE id = $1 AND tenant_id = $2;
    `;
    const providerRes = await client.query(providerQuery, [membership.user_id, tenantId]);
    if (providerRes.rows.length === 0) {
      throw createError('MATERIALIZATION_NOT_EXECUTABLE', 'El colaborador no posee un perfil previo en perfiles_prestador.', 422);
    }

    // 6. Check Existing Materialization (RE-MATERIALIZATION BEHAVIOR = OPEN)
    const existingMatQuery = `
      SELECT id, service_id
      FROM public.saas_service_materializations
      WHERE establishment_id = $1 AND service_offer_id = $2 AND membership_id = $3;
    `;
    const existingMatRes = await client.query(existingMatQuery, [establishmentId, service_offer_id, membership_id]);
    if (existingMatRes.rows.length > 0) {
      // RE-MATERIALIZATION BEHAVIOR is OPEN. Must NOT update, duplicate, sync or no-op.
      // Abort with explicit message acknowledging OPEN decision requirement.
      throw createError(
        'RE_MATERIALIZATION_NOT_AUTHORIZED',
        'La materialización ya existe. La re-materialización (actualización/sincronización/reemplazo) permanece como una decisión arquitectónica OPEN no autorizada.',
        409
      );
    }

    // 7. Insert Downstream into public.services
    // NOTE: is_active defaults per physical schema default (true), NODO-04 does not manage activation.
    const insertServiceQuery = `
      INSERT INTO public.services (
        id, provider_id, name, description, price, duration_minutes, tenant_id
      ) VALUES (
        gen_random_uuid(), $1, $2, $3, $4, $5, $6
      )
      RETURNING id, provider_id, name, description, price, duration_minutes, created_at;
    `;
    const serviceRes = await client.query(insertServiceQuery, [
      membership.user_id,
      offer.name,
      offer.description,
      offer.base_price,
      offer.base_duration,
      tenantId
    ]);
    const createdService = serviceRes.rows[0];

    // 8. Insert into public.saas_service_materializations
    const insertMatQuery = `
      INSERT INTO public.saas_service_materializations (
        tenant_id, establishment_id, service_offer_id, membership_id,
        service_id
      ) VALUES (
        $1, $2, $3, $4, $5
      )
      RETURNING id;
    `;
    const matRes = await client.query(insertMatQuery, [
      tenantId,
      establishmentId,
      service_offer_id,
      membership_id,
      createdService.id
    ]);
    const createdMat = matRes.rows[0];

    await client.query('COMMIT');

    return {
      materialization_id: createdMat.id,
      service_id: createdService.id,
      tenant_id: tenantId,
      establishment_id: establishmentId,
      service_offer_id: service_offer_id,
      membership_id: membership_id,
      provider_id: membership.user_id,
      projected_service: {
        name: createdService.name,
        description: createdService.description,
        price: createdService.price,
        duration_minutes: createdService.duration_minutes,
      },
    };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

/**
 * OP-02: List materialized services for the active establishment and tenant.
 *
 * @param {number} tenantId
 * @param {string} establishmentId
 * @param {Object} activeContext
 */
const listMaterializations = async (tenantId, establishmentId, activeContext) => {
  if (!tenantId || !establishmentId || !activeContext) {
    throw createError('ACTIVE_CONTEXT_REQUIRED', 'Contexto activo no inicializado o incompleto.', 400);
  }

  // Allowed roles for read: OWNER, MANAGER, PROFESSIONAL, RECEPTIONIST
  if (!['OWNER', 'MANAGER', 'PROFESSIONAL', 'RECEPTIONIST'].includes(activeContext.role)) {
    throw createError('INSUFFICIENT_ROLE_AUTHORITY', 'Rol no autorizado para consultar materializaciones.', 403);
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    const query = `
      SELECT 
        m.id AS materialization_id,
        m.service_offer_id,
        so.name AS service_offer_name,
        m.membership_id,
        u.nombre AS professional_name,
        m.service_id,
        s.price AS b2c_price,
        s.duration_minutes AS b2c_duration,
        s.is_active AS b2c_is_active
      FROM public.saas_service_materializations m
      JOIN public.service_offers so ON m.service_offer_id = so.id
      JOIN public.memberships mem ON m.membership_id = mem.id
      JOIN public.usuarios u ON mem.user_id = u.id
      JOIN public.services s ON m.service_id = s.id
      WHERE m.establishment_id = $1 AND m.tenant_id = $2
      ORDER BY m.id DESC;
    `;
    const res = await client.query(query, [establishmentId, tenantId]);
    await client.query('COMMIT');
    return res.rows;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

module.exports = {
  materializeServiceAssignment,
  listMaterializations,
};
