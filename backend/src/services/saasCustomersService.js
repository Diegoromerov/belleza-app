// backend/src/services/saasCustomersService.js
const { pool } = require('../config/db');

/**
 * NODO: CUSTOMER / CLIENT DIRECTORY ENGINE SERVICE
 * 
 * Implements:
 * 1. Multi-Tenant Isolated Customer Management (Tenant-Scoped saas_customers).
 * 2. Operational Establishment Relations (Establishment-Scoped saas_customer_establishments).
 * 3. Human-Confirmed Duplicate Warning (Non-blocking contact match warning).
 * 4. Explicit Reversible User Account Linking (ON DELETE SET NULL multi-tenant protected).
 * 5. Strict Derived Read-Only History (NODO-06 & NODO-08 exact customer_user_id derivation).
 * 6. RBAC & Anti-IDOR server-side validation.
 */

const ALLOWED_STATUSES = ['ACTIVE', 'INACTIVE', 'ARCHIVED'];

/**
 * Helper: Throw standard domain error
 */
function createError(message, status, code, extra = {}) {
  const err = new Error(message);
  err.status = status;
  err.code = code;
  Object.assign(err, extra);
  return err;
}

/**
 * 1. Search / Typeahead
 */
async function searchCustomers(activeContext, query = {}) {
  const { tenant_id, establishment_id, role } = activeContext;
  const q = (query.q || '').trim();

  if (!q || q.length < 3) {
    throw createError('El término de búsqueda debe tener al menos 3 caracteres.', 400, 'INVALID_SEARCH_QUERY');
  }

  const limitVal = Math.min(Math.max(parseInt(query.limit || 10, 10), 1), 30);
  const searchPattern = `%${q}%`;

  const client = await pool.connect();
  try {
    await client.query("SELECT set_config('app.tenant_id', $1, true)", [tenant_id.toString()]);

    const sql = `
      SELECT 
        c.id,
        c.tenant_id,
        c.first_name,
        c.last_name,
        c.phone,
        c.email,
        c.birth_date,
        c.status,
        (c.user_id IS NOT NULL) AS is_linked_to_user,
        (ce.id IS NOT NULL) AS has_local_relation,
        ce.local_notes,
        ce.is_active AS is_active_in_establishment,
        ce.first_visited_at,
        ce.last_visited_at,
        c.created_at
      FROM saas_customers c
      LEFT JOIN saas_customer_establishments ce 
             ON ce.customer_id = c.id 
            AND ce.establishment_id = $2 
            AND ce.tenant_id = $1
      WHERE c.tenant_id = $1
        AND (
          c.phone ILIKE $3 
          OR c.first_name ILIKE $3 
          OR c.last_name ILIKE $3 
          OR (c.first_name || ' ' || c.last_name) ILIKE $3
          OR c.email ILIKE $3
        )
      ORDER BY ce.last_visited_at DESC NULLS LAST, c.created_at DESC
      LIMIT $4;
    `;

    const res = await client.query(sql, [tenant_id, establishment_id, searchPattern, limitVal]);

    return {
      query: q,
      total_matches: res.rows.length,
      results: res.rows
    };
  } finally {
    client.release();
  }
}

/**
 * 2. List Directory
 */
async function listCustomers(activeContext, query = {}) {
  const { tenant_id, establishment_id, role } = activeContext;
  const scope = (query.scope || 'establishment').toLowerCase();
  const page = Math.max(parseInt(query.page || 1, 10), 1);
  const limit = Math.min(Math.max(parseInt(query.limit || 20, 10), 1), 50);
  const offset = (page - 1) * limit;
  const statusFilter = query.status ? query.status.toUpperCase() : null;

  if (statusFilter && !ALLOWED_STATUSES.includes(statusFilter)) {
    throw createError(`Status inválido: ${statusFilter}. Debe ser uno de: ${ALLOWED_STATUSES.join(', ')}`, 400, 'INVALID_CUSTOMER_STATUS');
  }

  // Scope tenant authorization check
  if (scope === 'tenant') {
    if (!['OWNER', 'MANAGER'].includes(role)) {
      throw createError('Acceso denegado. Se requiere rol OWNER o MANAGER para consultar el directorio corporativo.', 403, 'FORBIDDEN_TENANT_SCOPE');
    }
  }

  const client = await pool.connect();
  try {
    await client.query("SELECT set_config('app.tenant_id', $1, true)", [tenant_id.toString()]);

    let rowsQuery, countQuery, params, countParams;

    if (scope === 'tenant') {
      rowsQuery = `
        SELECT 
          c.id,
          c.tenant_id,
          c.first_name,
          c.last_name,
          c.phone,
          c.email,
          c.birth_date,
          c.status,
          (c.user_id IS NOT NULL) AS is_linked_to_user,
          (ce.id IS NOT NULL) AS has_local_relation,
          ce.local_notes,
          ce.is_active AS is_active_in_establishment,
          ce.first_visited_at,
          ce.last_visited_at,
          c.created_at
        FROM saas_customers c
        LEFT JOIN saas_customer_establishments ce 
               ON ce.customer_id = c.id 
              AND ce.establishment_id = $2 
              AND ce.tenant_id = $1
        WHERE c.tenant_id = $1
          AND ($3::varchar IS NULL OR c.status = $3)
        ORDER BY c.created_at DESC
        LIMIT $4 OFFSET $5;
      `;
      params = [tenant_id, establishment_id, statusFilter, limit, offset];

      countQuery = `
        SELECT count(*) AS total 
        FROM saas_customers c
        WHERE c.tenant_id = $1
          AND ($2::varchar IS NULL OR c.status = $2);
      `;
      countParams = [tenant_id, statusFilter];
    } else {
      // scope === 'establishment'
      rowsQuery = `
        SELECT 
          c.id,
          c.tenant_id,
          c.first_name,
          c.last_name,
          c.phone,
          c.email,
          c.birth_date,
          c.status,
          (c.user_id IS NOT NULL) AS is_linked_to_user,
          true AS has_local_relation,
          ce.local_notes,
          ce.is_active AS is_active_in_establishment,
          ce.first_visited_at,
          ce.last_visited_at,
          c.created_at
        FROM saas_customer_establishments ce
        JOIN saas_customers c ON c.id = ce.customer_id AND c.tenant_id = ce.tenant_id
        WHERE ce.tenant_id = $1 
          AND ce.establishment_id = $2
          AND ($3::varchar IS NULL OR c.status = $3)
        ORDER BY ce.last_visited_at DESC, ce.created_at DESC
        LIMIT $4 OFFSET $5;
      `;
      params = [tenant_id, establishment_id, statusFilter, limit, offset];

      countQuery = `
        SELECT count(*) AS total 
        FROM saas_customer_establishments ce
        JOIN saas_customers c ON c.id = ce.customer_id AND c.tenant_id = ce.tenant_id
        WHERE ce.tenant_id = $1 
          AND ce.establishment_id = $2
          AND ($3::varchar IS NULL OR c.status = $3);
      `;
      countParams = [tenant_id, establishment_id, statusFilter];
    }

    const [rowsRes, countRes] = await Promise.all([
      client.query(rowsQuery, params),
      client.query(countQuery, countParams),
    ]);

    const total = parseInt(countRes.rows[0].total, 10);

    return {
      scope,
      page,
      limit,
      total,
      total_pages: Math.ceil(total / limit) || 1,
      customers: rowsRes.rows
    };
  } finally {
    client.release();
  }
}

/**
 * 3. Create Customer (+ Establishment Relation Atomic)
 */
async function createCustomer(activeContext, payload = {}) {
  const { tenant_id, establishment_id, active_membership_id, role } = activeContext;

  if (!['OWNER', 'MANAGER', 'RECEPTIONIST'].includes(role)) {
    throw createError('No autorizado para crear clientes. Se requiere rol OWNER, MANAGER o RECEPTIONIST.', 403, 'FORBIDDEN_ROLE');
  }

  const firstName = (payload.first_name || '').trim();
  const lastName = (payload.last_name || '').trim();
  const phone = (payload.phone || '').trim();
  const email = payload.email ? payload.email.trim().toLowerCase() : null;
  const birthDate = payload.birth_date ? payload.birth_date : null;
  const localNotes = payload.local_notes ? payload.local_notes.trim() : null;
  const confirmDuplicate = payload.confirm_duplicate === true;

  if (!firstName || firstName.length < 2) {
    throw createError('El nombre del cliente (first_name) es obligatorio y debe tener al menos 2 caracteres.', 400, 'INVALID_CUSTOMER_NAME');
  }

  if (!phone || phone.length < 5) {
    throw createError('El teléfono de contacto (phone) es obligatorio y debe tener al menos 5 caracteres.', 400, 'INVALID_CUSTOMER_PHONE');
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true)", [tenant_id.toString()]);

    // Check duplicates in tenant if not explicitly confirmed
    if (!confirmDuplicate) {
      let dupSql = `
        SELECT id, first_name, last_name, phone, email, status, created_at
        FROM saas_customers
        WHERE tenant_id = $1 
          AND (phone = $2 ${email ? 'OR email = $3' : ''})
        LIMIT 5;
      `;
      const dupParams = email ? [tenant_id, phone, email] : [tenant_id, phone];
      const dupRes = await client.query(dupSql, dupParams);

      if (dupRes.rows.length > 0) {
        throw createError(
          'Se encontraron coincidencias de contacto existentes en la organización. Verifique si es un cliente existente o confirme la creación.',
          409,
          'POSSIBLE_DUPLICATE_FOUND',
          { candidates: dupRes.rows }
        );
      }
    }

    // 1. Insert saas_customers
    const insertCustomerSql = `
      INSERT INTO saas_customers (
        tenant_id,
        first_name,
        last_name,
        phone,
        email,
        birth_date,
        status,
        created_by_membership_id
      ) VALUES ($1, $2, $3, $4, $5, $6, 'ACTIVE', $7)
      RETURNING *;
    `;
    const custRes = await client.query(insertCustomerSql, [
      tenant_id,
      firstName,
      lastName,
      phone,
      email,
      birthDate,
      active_membership_id
    ]);
    const newCustomer = custRes.rows[0];

    // 2. Insert saas_customer_establishments
    const insertRelationSql = `
      INSERT INTO saas_customer_establishments (
        tenant_id,
        customer_id,
        establishment_id,
        local_notes,
        is_active
      ) VALUES ($1, $2, $3, $4, true)
      RETURNING *;
    `;
    const relRes = await client.query(insertRelationSql, [
      tenant_id,
      newCustomer.id,
      establishment_id,
      localNotes
    ]);
    const newRelation = relRes.rows[0];

    await client.query('COMMIT');

    return {
      ...newCustomer,
      is_linked_to_user: false,
      establishment_relation: newRelation
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * 4. Get Customer by ID (Anti-IDOR)
 */
async function getCustomerById(activeContext, customerId) {
  const { tenant_id, establishment_id } = activeContext;

  const client = await pool.connect();
  try {
    await client.query("SELECT set_config('app.tenant_id', $1, true)", [tenant_id.toString()]);

    const sql = `
      SELECT 
        c.id,
        c.tenant_id,
        c.user_id,
        c.first_name,
        c.last_name,
        c.phone,
        c.email,
        c.birth_date,
        c.status,
        c.created_by_membership_id,
        (c.user_id IS NOT NULL) AS is_linked_to_user,
        ce.id AS relation_id,
        ce.establishment_id,
        ce.local_notes,
        ce.is_active AS is_active_in_establishment,
        ce.first_visited_at,
        ce.last_visited_at,
        c.created_at,
        c.updated_at
      FROM saas_customers c
      LEFT JOIN saas_customer_establishments ce 
             ON ce.customer_id = c.id 
            AND ce.establishment_id = $2 
            AND ce.tenant_id = $1
      WHERE c.id = $3 AND c.tenant_id = $1;
    `;
    const res = await client.query(sql, [tenant_id, establishment_id, customerId]);

    if (res.rows.length === 0) {
      throw createError('Cliente no encontrado en la organización.', 404, 'CUSTOMER_NOT_FOUND');
    }

    const row = res.rows[0];
    const establishmentRelation = row.relation_id ? {
      id: row.relation_id,
      establishment_id: row.establishment_id,
      local_notes: row.local_notes,
      is_active: row.is_active_in_establishment,
      first_visited_at: row.first_visited_at,
      last_visited_at: row.last_visited_at
    } : null;

    delete row.relation_id;
    delete row.local_notes;
    delete row.is_active_in_establishment;
    delete row.first_visited_at;
    delete row.last_visited_at;

    return {
      ...row,
      has_local_relation: establishmentRelation !== null,
      establishment_relation: establishmentRelation
    };
  } finally {
    client.release();
  }
}

/**
 * 5. Update Customer (Canonical Data)
 */
async function updateCustomer(activeContext, customerId, payload = {}) {
  const { tenant_id, role } = activeContext;

  if (!['OWNER', 'MANAGER', 'RECEPTIONIST'].includes(role)) {
    throw createError('No autorizado para actualizar clientes.', 403, 'FORBIDDEN_ROLE');
  }

  // Status changes restricted to OWNER / MANAGER
  if (payload.status !== undefined) {
    if (!['OWNER', 'MANAGER'].includes(role)) {
      throw createError('Solo OWNER o MANAGER pueden modificar el estado del cliente.', 403, 'UNAUTHORIZED_STATUS_CHANGE');
    }
    const st = payload.status.toUpperCase();
    if (!ALLOWED_STATUSES.includes(st)) {
      throw createError(`Status inválido: ${payload.status}. Valores permitidos: ${ALLOWED_STATUSES.join(', ')}`, 400, 'INVALID_CUSTOMER_STATUS');
    }
    payload.status = st;
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true)", [tenant_id.toString()]);

    // Check existence and anti-IDOR
    const checkRes = await client.query(`
      SELECT id, first_name, last_name, phone, email, birth_date, status, user_id
      FROM saas_customers
      WHERE id = $1 AND tenant_id = $2
      FOR UPDATE;
    `, [customerId, tenant_id]);

    if (checkRes.rows.length === 0) {
      throw createError('Cliente no encontrado en la organización.', 404, 'CUSTOMER_NOT_FOUND');
    }

    const current = checkRes.rows[0];
    const newFirstName = payload.first_name !== undefined ? payload.first_name.trim() : current.first_name;
    const newLastName = payload.last_name !== undefined ? payload.last_name.trim() : current.last_name;
    const newPhone = payload.phone !== undefined ? payload.phone.trim() : current.phone;
    const newEmail = payload.email !== undefined ? (payload.email ? payload.email.trim().toLowerCase() : null) : current.email;
    const newBirthDate = payload.birth_date !== undefined ? payload.birth_date : current.birth_date;
    const newStatus = payload.status !== undefined ? payload.status : current.status;

    if (!newFirstName || newFirstName.length < 2) {
      throw createError('El nombre no puede estar vacío.', 400, 'INVALID_CUSTOMER_NAME');
    }
    if (!newPhone || newPhone.length < 5) {
      throw createError('El teléfono no puede estar vacío.', 400, 'INVALID_CUSTOMER_PHONE');
    }

    const updateSql = `
      UPDATE saas_customers
      SET first_name = $1,
          last_name = $2,
          phone = $3,
          email = $4,
          birth_date = $5,
          status = $6,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $7 AND tenant_id = $8
      RETURNING *;
    `;
    const updRes = await client.query(updateSql, [
      newFirstName,
      newLastName,
      newPhone,
      newEmail,
      newBirthDate,
      newStatus,
      customerId,
      tenant_id
    ]);

    await client.query('COMMIT');
    return updRes.rows[0];
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * 6. Create Establishment Relation for Existing Customer
 */
async function createEstablishmentRelation(activeContext, customerId, payload = {}) {
  const { tenant_id, establishment_id, role } = activeContext;

  if (!['OWNER', 'MANAGER', 'RECEPTIONIST'].includes(role)) {
    throw createError('No autorizado para afiliar clientes a la sede.', 403, 'FORBIDDEN_ROLE');
  }

  const localNotes = payload.local_notes ? payload.local_notes.trim() : null;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true)", [tenant_id.toString()]);

    // Check customer in tenant
    const custRes = await client.query(`
      SELECT id FROM saas_customers WHERE id = $1 AND tenant_id = $2;
    `, [customerId, tenant_id]);

    if (custRes.rows.length === 0) {
      throw createError('Cliente no encontrado en la organización.', 404, 'CUSTOMER_NOT_FOUND');
    }

    // Check if already related
    const relCheck = await client.query(`
      SELECT id FROM saas_customer_establishments 
      WHERE customer_id = $1 AND establishment_id = $2 AND tenant_id = $3;
    `, [customerId, establishment_id, tenant_id]);

    if (relCheck.rows.length > 0) {
      throw createError('El cliente ya se encuentra asociado a este establecimiento.', 409, 'CUSTOMER_ALREADY_RELATED');
    }

    const insertSql = `
      INSERT INTO saas_customer_establishments (
        tenant_id,
        customer_id,
        establishment_id,
        local_notes,
        is_active
      ) VALUES ($1, $2, $3, $4, true)
      RETURNING *;
    `;
    const res = await client.query(insertSql, [tenant_id, customerId, establishment_id, localNotes]);

    await client.query('COMMIT');
    return res.rows[0];
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * 7. Update Current Establishment Relation (Local Notes & Active)
 */
async function updateCurrentEstablishmentRelation(activeContext, customerId, payload = {}) {
  const { tenant_id, establishment_id, role } = activeContext;

  if (!['OWNER', 'MANAGER', 'RECEPTIONIST', 'PROFESSIONAL'].includes(role)) {
    throw createError('No autorizado para modificar datos locales de cliente.', 403, 'FORBIDDEN_ROLE');
  }

  // is_active change restricted from PROFESSIONAL
  if (payload.is_active !== undefined && role === 'PROFESSIONAL') {
    throw createError('El rol PROFESSIONAL no puede alterar el estado de activación de relación.', 403, 'FORBIDDEN_ROLE');
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true)", [tenant_id.toString()]);

    const relRes = await client.query(`
      SELECT id, local_notes, is_active
      FROM saas_customer_establishments
      WHERE customer_id = $1 AND establishment_id = $2 AND tenant_id = $3
      FOR UPDATE;
    `, [customerId, establishment_id, tenant_id]);

    if (relRes.rows.length === 0) {
      throw createError('El cliente no tiene relación registrada con este establecimiento.', 404, 'CUSTOMER_RELATION_NOT_FOUND');
    }

    const current = relRes.rows[0];
    const newNotes = payload.local_notes !== undefined ? payload.local_notes : current.local_notes;
    const newIsActive = payload.is_active !== undefined ? Boolean(payload.is_active) : current.is_active;

    const updSql = `
      UPDATE saas_customer_establishments
      SET local_notes = $1,
          is_active = $2,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $3 AND tenant_id = $4
      RETURNING *;
    `;
    const res = await client.query(updSql, [newNotes, newIsActive, current.id, tenant_id]);

    await client.query('COMMIT');
    return res.rows[0];
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * 8. Link User Account (Explicit & Reversible)
 */
async function linkUser(activeContext, customerId, payload = {}) {
  const { tenant_id, role } = activeContext;

  if (!['OWNER', 'MANAGER'].includes(role)) {
    throw createError('Solo OWNER o MANAGER pueden vincular cuentas de usuario global.', 403, 'FORBIDDEN_ROLE');
  }

  if (payload.user_id === undefined || payload.user_id === null || isNaN(parseInt(payload.user_id, 10))) {
    throw createError('Identificador de usuario (user_id) inválido o ausente.', 400, 'INVALID_USER_LINK');
  }
  const userId = parseInt(payload.user_id, 10);

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true)", [tenant_id.toString()]);

    // 1. Verify customer exists in tenant
    const custRes = await client.query(`
      SELECT id, user_id FROM saas_customers WHERE id = $1 AND tenant_id = $2 FOR UPDATE;
    `, [customerId, tenant_id]);

    if (custRes.rows.length === 0) {
      throw createError('Cliente no encontrado en la organización.', 404, 'CUSTOMER_NOT_FOUND');
    }

    // 2. Verify user exists in usuarios and belongs to the EXACT SAME tenant_id
    const userRes = await client.query(`
      SELECT id, tenant_id, nombre, email FROM usuarios WHERE id = $1;
    `, [userId]);

    if (userRes.rows.length === 0) {
      throw createError('La cuenta de usuario especificada no existe.', 404, 'USER_NOT_FOUND');
    }

    const user = userRes.rows[0];
    if (user.tenant_id !== tenant_id) {
      throw createError('Violación de aislamiento multi-tenant. El usuario pertenece a otra organización.', 403, 'USER_CROSS_TENANT');
    }

    // 3. Update saas_customers.user_id
    const updRes = await client.query(`
      UPDATE saas_customers
      SET user_id = $1,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $2 AND tenant_id = $3
      RETURNING *;
    `, [userId, customerId, tenant_id]);

    await client.query('COMMIT');
    return {
      ...updRes.rows[0],
      linked_user: {
        id: user.id,
        nombre: user.nombre,
        email: user.email
      }
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * 9. Unlink User Account (Explicit & Reversible)
 */
async function unlinkUser(activeContext, customerId) {
  const { tenant_id, role } = activeContext;

  if (!['OWNER', 'MANAGER'].includes(role)) {
    throw createError('Solo OWNER o MANAGER pueden desvincular cuentas de usuario global.', 403, 'FORBIDDEN_ROLE');
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true)", [tenant_id.toString()]);

    const custRes = await client.query(`
      SELECT id, user_id FROM saas_customers WHERE id = $1 AND tenant_id = $2 FOR UPDATE;
    `, [customerId, tenant_id]);

    if (custRes.rows.length === 0) {
      throw createError('Cliente no encontrado en la organización.', 404, 'CUSTOMER_NOT_FOUND');
    }

    const updRes = await client.query(`
      UPDATE saas_customers
      SET user_id = NULL,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $1 AND tenant_id = $2
      RETURNING *;
    `, [customerId, tenant_id]);

    await client.query('COMMIT');
    return {
      ...updRes.rows[0],
      unlinked: true
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * 10. Get Customer History (Strictly Derived Read-Only)
 */
async function getCustomerHistory(activeContext, customerId) {
  const { tenant_id } = activeContext;

  const client = await pool.connect();
  try {
    await client.query("SELECT set_config('app.tenant_id', $1, true)", [tenant_id.toString()]);

    // 1. Get customer
    const custRes = await client.query(`
      SELECT id, user_id, first_name, last_name, phone, email, status
      FROM saas_customers
      WHERE id = $1 AND tenant_id = $2;
    `, [customerId, tenant_id]);

    if (custRes.rows.length === 0) {
      throw createError('Cliente no encontrado en la organización.', 404, 'CUSTOMER_NOT_FOUND');
    }

    const customer = custRes.rows[0];

    // CASE A: Customer has NO linked user account -> ZERO GUEST attribution
    if (customer.user_id === null) {
      return {
        customer_id: customer.id,
        user_id: null,
        attribution_status: 'UNLINKED_NO_ATTRIBUTED_HISTORY',
        summary: {
          total_attributed_appointments: 0,
          total_attributed_tickets: 0,
          total_spend: '0.00',
          last_service_date: null
        },
        appointments: [],
        tickets: []
      };
    }

    // CASE B: Customer has linked user account -> Derive exact history from NODO-06 and NODO-08
    const [appRes, tktRes] = await Promise.all([
      client.query(`
        SELECT 
          id,
          'NODO-06' AS source_node,
          establishment_id,
          service_offer_id,
          service_name_snapshot,
          duration_minutes_snapshot,
          price_snapshot,
          scheduled_at,
          end_time,
          status,
          created_at
        FROM saas_appointments
        WHERE tenant_id = $1 AND customer_user_id = $2
        ORDER BY scheduled_at DESC
        LIMIT 50;
      `, [tenant_id, customer.user_id]),
      client.query(`
        SELECT 
          id,
          'NODO-08' AS source_node,
          ticket_number,
          ticket_number AS folio,
          establishment_id,
          appointment_id,
          status,
          subtotal_amount,
          discount_amount,
          tax_amount,
          tip_amount,
          total_amount,
          paid_amount,
          balance_due AS balance_amount,
          created_at
        FROM saas_service_tickets
        WHERE tenant_id = $1 AND customer_user_id = $2
        ORDER BY created_at DESC
        LIMIT 50;
      `, [tenant_id, customer.user_id])
    ]);

    const appointments = appRes.rows;
    const tickets = tktRes.rows;

    let totalSpend = 0.0;
    let lastServiceDate = null;

    for (const t of tickets) {
      if (['PAID', 'CLOSED'].includes(t.status)) {
        totalSpend += parseFloat(t.total_amount || 0);
      }
    }

    if (appointments.length > 0) {
      lastServiceDate = appointments[0].scheduled_at;
    } else if (tickets.length > 0) {
      lastServiceDate = tickets[0].created_at;
    }

    return {
      customer_id: customer.id,
      user_id: customer.user_id,
      attribution_status: 'ATTRIBUTED_VIA_USER_ACCOUNT',
      summary: {
        total_attributed_appointments: appointments.length,
        total_attributed_tickets: tickets.length,
        total_spend: totalSpend.toFixed(2),
        last_service_date: lastServiceDate
      },
      appointments,
      tickets
    };
  } finally {
    client.release();
  }
}

module.exports = {
  searchCustomers,
  listCustomers,
  createCustomer,
  getCustomerById,
  updateCustomer,
  createEstablishmentRelation,
  updateCurrentEstablishmentRelation,
  linkUser,
  unlinkUser,
  getCustomerHistory,
};
