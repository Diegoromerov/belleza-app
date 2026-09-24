// backend/src/services/serviceOfferService.js
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
 * Creates a new Service Offer within the active establishment.
 *
 * @param {number} tenantId
 * @param {string} establishmentId
 * @param {Object} activeContext
 * @param {Object} data - { name, description, base_duration, base_price }
 */
const createServiceOffer = async (tenantId, establishmentId, activeContext, data) => {
  if (!tenantId || !establishmentId || !activeContext) {
    throw createError('ACTIVE_CONTEXT_REQUIRED', 'Contexto activo no inicializado o incompleto.', 400);
  }

  // RBAC Check: Only OWNER or MANAGER can create service offers
  if (!['OWNER', 'MANAGER'].includes(activeContext.role)) {
    throw createError('INSUFFICIENT_ROLE_AUTHORITY', 'Se requiere rol OWNER o MANAGER para crear ofertas de servicio.', 403);
  }

  const { name, description, base_duration, base_price } = data || {};

  // Validations
  if (typeof name !== 'string' || name.trim().length === 0 || name.trim().length > 255) {
    throw createError('INVALID_PAYLOAD', 'El nombre de la oferta es obligatorio y debe tener entre 1 y 255 caracteres.', 400);
  }

  if (description !== undefined && description !== null && typeof description !== 'string') {
    throw createError('INVALID_PAYLOAD', 'La descripción debe ser un texto válido.', 400);
  }

  if (typeof description === 'string' && description.length > 2000) {
    throw createError('INVALID_PAYLOAD', 'La descripción no puede exceder los 2000 caracteres.', 400);
  }

  const parsedDuration = parseInt(base_duration, 10);
  if (isNaN(parsedDuration) || parsedDuration <= 0 || parsedDuration > 1440) {
    throw createError('INVALID_PAYLOAD', 'La duración base debe ser un entero estrictamente mayor a 0 y menor o igual a 1440 minutos.', 400);
  }

  const parsedPrice = parseFloat(base_price);
  if (isNaN(parsedPrice) || parsedPrice < 0) {
    throw createError('INVALID_PAYLOAD', 'El precio base debe ser un número mayor o igual a 0.00.', 400);
  }

  const cleanName = name.trim();
  const cleanDescription = description !== undefined && description !== null ? description.trim() : null;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Establish Tenant Context for PostgreSQL RLS
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    const insertQuery = `
      INSERT INTO service_offers (tenant_id, establishment_id, name, description, base_duration, base_price)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING id, tenant_id, establishment_id, name, description, base_duration, base_price, created_at, updated_at;
    `;

    const result = await client.query(insertQuery, [
      tenantId,
      establishmentId,
      cleanName,
      cleanDescription,
      parsedDuration,
      parsedPrice,
    ]);

    await client.query('COMMIT');

    const row = result.rows[0];
    return {
      service_offer: {
        id: row.id,
        tenant_id: row.tenant_id,
        establishment_id: row.establishment_id,
        name: row.name,
        description: row.description,
        base_duration: row.base_duration,
        base_price: typeof row.base_price === 'number' ? row.base_price.toFixed(2) : String(row.base_price),
        created_at: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
        updated_at: row.updated_at instanceof Date ? row.updated_at.toISOString() : row.updated_at,
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
 * Lists all Service Offers for the active establishment.
 *
 * @param {number} tenantId
 * @param {string} establishmentId
 * @param {Object} activeContext
 */
const listServiceOffers = async (tenantId, establishmentId, activeContext) => {
  if (!tenantId || !establishmentId || !activeContext) {
    throw createError('ACTIVE_CONTEXT_REQUIRED', 'Contexto activo no inicializado o incompleto.', 400);
  }

  // RBAC Check
  if (!['OWNER', 'MANAGER', 'PROFESSIONAL', 'RECEPTIONIST'].includes(activeContext.role)) {
    throw createError('INSUFFICIENT_ROLE_AUTHORITY', 'No tiene permisos para consultar ofertas de servicio.', 403);
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    const selectQuery = `
      SELECT id, tenant_id, establishment_id, name, description, base_duration, base_price, created_at, updated_at
      FROM service_offers
      WHERE establishment_id = $1 AND tenant_id = $2
      ORDER BY created_at ASC;
    `;

    const result = await client.query(selectQuery, [establishmentId, tenantId]);
    await client.query('COMMIT');

    return {
      service_offers: result.rows.map((row) => ({
        id: row.id,
        tenant_id: row.tenant_id,
        establishment_id: row.establishment_id,
        name: row.name,
        description: row.description,
        base_duration: row.base_duration,
        base_price: typeof row.base_price === 'number' ? row.base_price.toFixed(2) : String(row.base_price),
        created_at: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
        updated_at: row.updated_at instanceof Date ? row.updated_at.toISOString() : row.updated_at,
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
 * Retrieves a single Service Offer by ID within the active establishment.
 *
 * @param {number} tenantId
 * @param {string} establishmentId
 * @param {Object} activeContext
 * @param {string} id - Service Offer UUID
 */
const getServiceOfferById = async (tenantId, establishmentId, activeContext, id) => {
  if (!tenantId || !establishmentId || !activeContext) {
    throw createError('ACTIVE_CONTEXT_REQUIRED', 'Contexto activo no inicializado o incompleto.', 400);
  }

  if (!isValidUUID(id)) {
    throw createError('INVALID_PAYLOAD', 'El identificador de la oferta debe ser un UUID válido.', 400);
  }

  if (!['OWNER', 'MANAGER', 'PROFESSIONAL', 'RECEPTIONIST'].includes(activeContext.role)) {
    throw createError('INSUFFICIENT_ROLE_AUTHORITY', 'No tiene permisos para consultar ofertas de servicio.', 403);
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    const selectQuery = `
      SELECT id, tenant_id, establishment_id, name, description, base_duration, base_price, created_at, updated_at
      FROM service_offers
      WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3;
    `;

    const result = await client.query(selectQuery, [id, establishmentId, tenantId]);
    await client.query('COMMIT');

    if (result.rows.length === 0) {
      throw createError('SERVICE_OFFER_NOT_FOUND', 'La oferta de servicio no existe en este establecimiento.', 404);
    }

    const row = result.rows[0];
    return {
      service_offer: {
        id: row.id,
        tenant_id: row.tenant_id,
        establishment_id: row.establishment_id,
        name: row.name,
        description: row.description,
        base_duration: row.base_duration,
        base_price: typeof row.base_price === 'number' ? row.base_price.toFixed(2) : String(row.base_price),
        created_at: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
        updated_at: row.updated_at instanceof Date ? row.updated_at.toISOString() : row.updated_at,
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
 * Updates a Service Offer within the active establishment.
 * Enforces strict immutability on id, tenant_id, and establishment_id (R1).
 *
 * @param {number} tenantId
 * @param {string} establishmentId
 * @param {Object} activeContext
 * @param {string} id - Service Offer UUID
 * @param {Object} data - Mutating fields { name, description, base_duration, base_price }
 */
const updateServiceOffer = async (tenantId, establishmentId, activeContext, id, data) => {
  if (!tenantId || !establishmentId || !activeContext) {
    throw createError('ACTIVE_CONTEXT_REQUIRED', 'Contexto activo no inicializado o incompleto.', 400);
  }

  if (!isValidUUID(id)) {
    throw createError('INVALID_PAYLOAD', 'El identificador de la oferta debe ser un UUID válido.', 400);
  }

  if (!['OWNER', 'MANAGER'].includes(activeContext.role)) {
    throw createError('INSUFFICIENT_ROLE_AUTHORITY', 'Se requiere rol OWNER o MANAGER para modificar ofertas de servicio.', 403);
  }

  const payload = data || {};

  // R1: Structural Immutability Enforcement
  if (payload.id !== undefined && payload.id !== id) {
    throw createError('IMMUTABLE_FIELD_MODIFICATION', 'El campo id es inmutable y no puede modificarse.', 400);
  }
  if (payload.tenant_id !== undefined && payload.tenant_id !== tenantId) {
    throw createError('IMMUTABLE_FIELD_MODIFICATION', 'El campo tenant_id es inmutable y no puede modificarse.', 400);
  }
  if (payload.establishment_id !== undefined && payload.establishment_id !== establishmentId) {
    throw createError('IMMUTABLE_FIELD_MODIFICATION', 'El campo establishment_id es inmutable. No se puede mover una oferta entre sedes.', 400);
  }

  // Field validations if present
  let cleanName = undefined;
  if (payload.name !== undefined) {
    if (typeof payload.name !== 'string' || payload.name.trim().length === 0 || payload.name.trim().length > 255) {
      throw createError('INVALID_PAYLOAD', 'El nombre de la oferta debe tener entre 1 y 255 caracteres.', 400);
    }
    cleanName = payload.name.trim();
  }

  let cleanDescription = undefined;
  if (payload.description !== undefined) {
    if (payload.description !== null && typeof payload.description !== 'string') {
      throw createError('INVALID_PAYLOAD', 'La descripción debe ser un texto válido o null.', 400);
    }
    if (typeof payload.description === 'string' && payload.description.length > 2000) {
      throw createError('INVALID_PAYLOAD', 'La descripción no puede exceder los 2000 caracteres.', 400);
    }
    cleanDescription = payload.description !== null ? payload.description.trim() : null;
  }

  let cleanDuration = undefined;
  if (payload.base_duration !== undefined) {
    const parsedDuration = parseInt(payload.base_duration, 10);
    if (isNaN(parsedDuration) || parsedDuration <= 0 || parsedDuration > 1440) {
      throw createError('INVALID_PAYLOAD', 'La duración base debe ser un entero estrictamente mayor a 0 y menor o igual a 1440 minutos.', 400);
    }
    cleanDuration = parsedDuration;
  }

  let cleanPrice = undefined;
  if (payload.base_price !== undefined) {
    const parsedPrice = parseFloat(payload.base_price);
    if (isNaN(parsedPrice) || parsedPrice < 0) {
      throw createError('INVALID_PAYLOAD', 'El precio base debe ser un número mayor o igual a 0.00.', 400);
    }
    cleanPrice = parsedPrice;
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    // Check existence
    const checkQuery = `
      SELECT id, name, description, base_duration, base_price 
      FROM service_offers 
      WHERE id = $1 AND establishment_id = $2 AND tenant_id = $3;
    `;
    const checkRes = await client.query(checkQuery, [id, establishmentId, tenantId]);
    if (checkRes.rows.length === 0) {
      throw createError('SERVICE_OFFER_NOT_FOUND', 'La oferta de servicio no existe en este establecimiento.', 404);
    }

    const current = checkRes.rows[0];
    const finalName = cleanName !== undefined ? cleanName : current.name;
    const finalDescription = cleanDescription !== undefined ? cleanDescription : current.description;
    const finalDuration = cleanDuration !== undefined ? cleanDuration : current.base_duration;
    const finalPrice = cleanPrice !== undefined ? cleanPrice : current.base_price;

    const updateQuery = `
      UPDATE service_offers
      SET name = $1,
          description = $2,
          base_duration = $3,
          base_price = $4,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $5 AND establishment_id = $6 AND tenant_id = $7
      RETURNING id, tenant_id, establishment_id, name, description, base_duration, base_price, created_at, updated_at;
    `;

    const result = await client.query(updateQuery, [
      finalName,
      finalDescription,
      finalDuration,
      finalPrice,
      id,
      establishmentId,
      tenantId,
    ]);

    await client.query('COMMIT');

    const row = result.rows[0];
    return {
      service_offer: {
        id: row.id,
        tenant_id: row.tenant_id,
        establishment_id: row.establishment_id,
        name: row.name,
        description: row.description,
        base_duration: row.base_duration,
        base_price: typeof row.base_price === 'number' ? row.base_price.toFixed(2) : String(row.base_price),
        created_at: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
        updated_at: row.updated_at instanceof Date ? row.updated_at.toISOString() : row.updated_at,
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

module.exports = {
  createServiceOffer,
  listServiceOffers,
  getServiceOfferById,
  updateServiceOffer,
};
