// backend/src/services/nodo08TicketsService.js
const { pool } = require('../config/db');

/**
 * NODO-08 — SaaS Service Ticket & Financial Checkout Engine Service
 *
 * Implements:
 * 1. Ticket Creation (Guest / Registered) with Atomic Concurrency Folio (DEC-08-03).
 * 2. Unidirectional linkage from NODO-06 Appointments (IN_SERVICE / COMPLETED).
 * 3. 1:N Items Management (SERVICE with NODO-02 assignment check / CUSTOM).
 * 4. Server-side Deterministic Financial Engine (subtotal, discounts, tax, tips, balance).
 * 5. Split Tender Payments (CASH, CARD, TRANSFER, OTHER) with Overpayment Protection (DEC-08-02).
 * 6. Deterministic Mutability State Machine (DRAFT -> OPEN -> PAID -> CLOSED / VOID).
 * 7. RBAC & Multi-Tenant PostgreSQL RLS Isolation.
 */

const ALLOWED_PAYMENT_METHODS = ['CASH', 'CARD', 'TRANSFER', 'OTHER'];
const VALID_TICKET_STATUSES = ['DRAFT', 'OPEN', 'PAID', 'CLOSED', 'VOID'];

/**
 * Helper: Round a numeric value to 2 decimal places
 */
function round2(val) {
  const num = typeof val === 'number' ? val : parseFloat(val || 0);
  return Math.round((num + Number.EPSILON) * 100) / 100;
}

/**
 * Helper: Recalculate ticket totals within an active transaction
 */
async function recalculateTicketTotals(client, ticketId, tenantId, establishmentId) {
  // 1. Calculate sum of items total_amount
  const itemsSumRes = await client.query(`
    SELECT COALESCE(SUM(total_amount), 0.00) AS subtotal
    FROM saas_ticket_items
    WHERE ticket_id = $1 AND tenant_id = $2 AND establishment_id = $3
  `, [ticketId, tenantId, establishmentId]);

  const subtotalAmount = round2(itemsSumRes.rows[0].subtotal);

  // 2. Fetch current ticket adjustment fields
  const ticketRes = await client.query(`
    SELECT discount_amount, tax_amount, tip_amount, status
    FROM saas_service_tickets
    WHERE id = $1 AND tenant_id = $2 AND establishment_id = $3
    FOR UPDATE
  `, [ticketId, tenantId, establishmentId]);

  if (ticketRes.rows.length === 0) {
    const err = new Error('Ticket not found');
    err.status = 404;
    err.code = 'TICKET_NOT_FOUND';
    throw err;
  }

  const ticket = ticketRes.rows[0];
  const discountAmount = round2(ticket.discount_amount);
  const taxAmount = round2(ticket.tax_amount);
  const tipAmount = round2(ticket.tip_amount);

  // Total = subtotal - discount + tax + tip
  let totalAmount = round2(subtotalAmount - discountAmount + taxAmount + tipAmount);
  if (totalAmount < 0.00) totalAmount = 0.00;

  // 3. Calculate sum of payments
  const paymentsSumRes = await client.query(`
    SELECT COALESCE(SUM(amount), 0.00) AS paid
    FROM saas_ticket_payments
    WHERE ticket_id = $1 AND tenant_id = $2 AND establishment_id = $3
  `, [ticketId, tenantId, establishmentId]);

  const paidAmount = round2(paymentsSumRes.rows[0].paid);
  let balanceDue = round2(totalAmount - paidAmount);
  if (balanceDue < 0.00) balanceDue = 0.00;

  // 4. Determine state transition to PAID if OPEN and balance == 0 (and at least 1 payment or total == 0)
  let newStatus = ticket.status;
  if (ticket.status === 'OPEN' && balanceDue === 0.00 && paidAmount >= totalAmount && totalAmount > 0.00) {
    newStatus = 'PAID';
  }

  // 5. Update ticket header
  const updateRes = await client.query(`
    UPDATE saas_service_tickets
    SET subtotal_amount = $1,
        total_amount = $2,
        paid_amount = $3,
        balance_due = $4,
        status = $5,
        updated_at = NOW()
    WHERE id = $6 AND tenant_id = $7 AND establishment_id = $8
    RETURNING *
  `, [subtotalAmount, totalAmount, paidAmount, balanceDue, newStatus, ticketId, tenantId, establishmentId]);

  return updateRes.rows[0];
}

/**
 * 1. CREATE TICKET (POST /api/saas/tickets)
 */
async function createTicket(activeContext, data) {
  const { tenant_id: tenantId, establishment_id: establishmentId, active_membership_id: callerMembershipId, role: callerRole } = activeContext;

  // RBAC: OWNER, MANAGER, RECEPTIONIST only
  if (!['OWNER', 'MANAGER', 'RECEPTIONIST'].includes(callerRole)) {
    const err = new Error(`Role ${callerRole} is not authorized to create service tickets`);
    err.status = 403;
    err.code = 'UNAUTHORIZED_ROLE';
    throw err;
  }

  const {
    appointment_id,
    client_mode = 'GUEST',
    customer_user_id,
    guest_name,
    guest_phone,
    guest_email,
    notes
  } = data;

  // Client mode validation (XOR)
  if (client_mode === 'REGISTERED') {
    if (!customer_user_id || isNaN(Number(customer_user_id))) {
      const err = new Error('REGISTERED client mode requires a valid customer_user_id');
      err.status = 400;
      err.code = 'INVALID_CLIENT_MODE';
      throw err;
    }
    if (guest_name || guest_phone || guest_email) {
      const err = new Error('REGISTERED client mode must not include guest snapshot fields');
      err.status = 400;
      err.code = 'INVALID_CLIENT_MODE';
      throw err;
    }
  } else if (client_mode === 'GUEST') {
    if (customer_user_id) {
      const err = new Error('GUEST client mode must not include customer_user_id');
      err.status = 400;
      err.code = 'INVALID_CLIENT_MODE';
      throw err;
    }
    if (!guest_name || typeof guest_name !== 'string' || !guest_name.trim()) {
      const err = new Error('GUEST client mode requires guest_name');
      err.status = 400;
      err.code = 'INVALID_CLIENT_MODE';
      throw err;
    }
  } else {
    const err = new Error("client_mode must be 'GUEST' or 'REGISTERED'");
    err.status = 400;
    err.code = 'INVALID_CLIENT_MODE';
    throw err;
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    // Validate Registered customer existence
    if (client_mode === 'REGISTERED') {
      const userRes = await client.query('SELECT id FROM usuarios WHERE id = $1', [customer_user_id]);
      if (userRes.rows.length === 0) {
        const err = new Error(`Customer user ${customer_user_id} not found`);
        err.status = 404;
        err.code = 'CUSTOMER_NOT_FOUND';
        throw err;
      }
    }

    // Validate Appointment Origin if provided (NODO-06 rules)
    if (appointment_id) {
      const apptRes = await client.query(`
        SELECT id, tenant_id, establishment_id, status, customer_user_id, guest_name, guest_phone, guest_email
        FROM saas_appointments
        WHERE id = $1 AND tenant_id = $2 AND establishment_id = $3
      `, [appointment_id, tenantId, establishmentId]);

      if (apptRes.rows.length === 0) {
        const err = new Error(`Appointment ${appointment_id} not found in current active context`);
        err.status = 404;
        err.code = 'APPOINTMENT_NOT_FOUND';
        throw err;
      }

      const appt = apptRes.rows[0];
      if (!['IN_SERVICE', 'COMPLETED'].includes(appt.status)) {
        const err = new Error(`Ticket can only be created from appointments in 'IN_SERVICE' or 'COMPLETED' status (current: ${appt.status})`);
        err.status = 422;
        err.code = 'INVALID_APPOINTMENT_STATUS';
        throw err;
      }

      // Check if an active ticket already exists for this appointment
      const activeTicketRes = await client.query(`
        SELECT id, ticket_number, status
        FROM saas_service_tickets
        WHERE appointment_id = $1 AND status != 'VOID'
      `, [appointment_id]);

      if (activeTicketRes.rows.length > 0) {
        const err = new Error(`Appointment ${appointment_id} already has an active ticket (${activeTicketRes.rows[0].ticket_number})`);
        err.status = 409;
        err.code = 'APPOINTMENT_ALREADY_TICKETED';
        throw err;
      }
    }

    // Atomic Consecutive Folio Generation (DEC-08-03)
    const seqRes = await client.query(`
      INSERT INTO saas_establishment_ticket_sequences (establishment_id, last_sequence_number, updated_at)
      VALUES ($1, 1, NOW())
      ON CONFLICT (establishment_id)
      DO UPDATE SET
          last_sequence_number = saas_establishment_ticket_sequences.last_sequence_number + 1,
          updated_at = NOW()
      RETURNING last_sequence_number;
    `, [establishmentId]);

    const seqNum = seqRes.rows[0].last_sequence_number;
    const ticketNumber = `TICK-${String(seqNum).padStart(6, '0')}`;

    // Insert Service Ticket in DRAFT
    const insertRes = await client.query(`
      INSERT INTO saas_service_tickets (
        tenant_id,
        establishment_id,
        ticket_number,
        appointment_id,
        client_mode,
        customer_user_id,
        guest_name_snapshot,
        guest_phone_snapshot,
        guest_email_snapshot,
        status,
        subtotal_amount,
        discount_amount,
        discount_reason,
        tax_amount,
        tip_amount,
        total_amount,
        paid_amount,
        balance_due,
        notes,
        created_by_membership_id
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, 'DRAFT',
        0.00, 0.00, NULL, 0.00, 0.00, 0.00, 0.00, 0.00,
        $10, $11
      )
      RETURNING *;
    `, [
      tenantId,
      establishmentId,
      ticketNumber,
      appointment_id || null,
      client_mode,
      client_mode === 'REGISTERED' ? customer_user_id : null,
      client_mode === 'GUEST' ? (guest_name ? guest_name.trim() : null) : null,
      client_mode === 'GUEST' ? (guest_phone ? guest_phone.trim() : null) : null,
      client_mode === 'GUEST' ? (guest_email ? guest_email.trim() : null) : null,
      notes ? notes.trim() : null,
      callerMembershipId
    ]);

    await client.query('COMMIT');
    return insertRes.rows[0];
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * 2. ADD ITEM TO TICKET (POST /api/saas/tickets/:id/items)
 */
async function addItem(activeContext, ticketId, data) {
  const { tenant_id: tenantId, establishment_id: establishmentId, active_membership_id: callerMembershipId, role: callerRole } = activeContext;

  const {
    item_type = 'SERVICE',
    service_offer_id,
    performed_by_membership_id,
    quantity = 1,
    title,
    unit_price,
    discount_amount = 0.00
  } = data;

  if (!['SERVICE', 'CUSTOM'].includes(item_type)) {
    const err = new Error("item_type must be 'SERVICE' or 'CUSTOM'");
    err.status = 400;
    err.code = 'INVALID_ITEM_TYPE';
    throw err;
  }

  const numQty = parseInt(quantity, 10);
  if (isNaN(numQty) || numQty < 1) {
    const err = new Error('quantity must be an integer >= 1');
    err.status = 400;
    err.code = 'INVALID_QUANTITY';
    throw err;
  }

  const numDiscount = round2(discount_amount);
  if (numDiscount < 0) {
    const err = new Error('discount_amount must be >= 0.00');
    err.status = 400;
    err.code = 'INVALID_DISCOUNT';
    throw err;
  }

  if (!performed_by_membership_id) {
    const err = new Error('performed_by_membership_id is required');
    err.status = 400;
    err.code = 'MISSING_PERFORMED_BY_MEMBERSHIP';
    throw err;
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    // Fetch ticket and check mutability status
    const ticketRes = await client.query(`
      SELECT id, status
      FROM saas_service_tickets
      WHERE id = $1 AND tenant_id = $2 AND establishment_id = $3
      FOR UPDATE
    `, [ticketId, tenantId, establishmentId]);

    if (ticketRes.rows.length === 0) {
      const err = new Error('Ticket not found');
      err.status = 404;
      err.code = 'TICKET_NOT_FOUND';
      throw err;
    }

    const ticket = ticketRes.rows[0];

    // Status & RBAC validation
    if (ticket.status === 'DRAFT') {
      if (!['OWNER', 'MANAGER', 'RECEPTIONIST'].includes(callerRole)) {
        const err = new Error(`Role ${callerRole} is not authorized to add items to DRAFT tickets`);
        err.status = 403;
        err.code = 'UNAUTHORIZED_ROLE';
        throw err;
      }
    } else if (ticket.status === 'OPEN') {
      if (!['OWNER', 'MANAGER'].includes(callerRole)) {
        const err = new Error(`Only OWNER or MANAGER can add items to OPEN tickets`);
        err.status = 403;
        err.code = 'UNAUTHORIZED_ROLE';
        throw err;
      }
    } else {
      const err = new Error(`Cannot add items to ticket in ${ticket.status} status`);
      err.status = 422;
      err.code = 'IMMUTABLE_TICKET_STATUS';
      throw err;
    }

    // Validate Performer Membership (Must be ACTIVE and in same tenant/establishment)
    const memberRes = await client.query(`
      SELECT id, status, role
      FROM memberships
      WHERE id = $1 AND tenant_id = $2 AND establishment_id = $3
    `, [performed_by_membership_id, tenantId, establishmentId]);

    if (memberRes.rows.length === 0) {
      const err = new Error(`Performer membership ${performed_by_membership_id} not found in active establishment`);
      err.status = 422;
      err.code = 'MEMBERSHIP_NOT_FOUND';
      throw err;
    }

    if (memberRes.rows[0].status !== 'ACTIVE') {
      const err = new Error(`Performer membership ${performed_by_membership_id} is not ACTIVE (current: ${memberRes.rows[0].status})`);
      err.status = 422;
      err.code = 'INACTIVE_MEMBERSHIP';
      throw err;
    }

    let titleSnapshot = '';
    let unitPriceSnapshot = 0.00;

    if (item_type === 'SERVICE') {
      if (!service_offer_id) {
        const err = new Error('service_offer_id is required for SERVICE items');
        err.status = 400;
        err.code = 'MISSING_SERVICE_OFFER';
        throw err;
      }

      // Fetch Service Offer
      const offerRes = await client.query(`
        SELECT id, name, base_price
        FROM service_offers
        WHERE id = $1 AND tenant_id = $2 AND establishment_id = $3
      `, [service_offer_id, tenantId, establishmentId]);

      if (offerRes.rows.length === 0) {
        const err = new Error(`Service offer ${service_offer_id} not found in establishment`);
        err.status = 404;
        err.code = 'SERVICE_OFFER_NOT_FOUND';
        throw err;
      }

      const offer = offerRes.rows[0];
      titleSnapshot = offer.name;
      unitPriceSnapshot = round2(offer.base_price);

      // Validate Service Assignment (NODO-02 / DEC-AS-014)
      const assignRes = await client.query(`
        SELECT id
        FROM service_assignments
        WHERE service_offer_id = $1 AND membership_id = $2
          AND tenant_id = $3 AND establishment_id = $4
      `, [service_offer_id, performed_by_membership_id, tenantId, establishmentId]);

      if (assignRes.rows.length === 0) {
        const err = new Error(`Professional ${performed_by_membership_id} has no valid service assignment for offer ${service_offer_id}`);
        err.status = 422;
        err.code = 'INVALID_SERVICE_ASSIGNMENT';
        throw err;
      }
    } else {
      // CUSTOM item
      if (service_offer_id) {
        const err = new Error('CUSTOM item cannot have service_offer_id');
        err.status = 400;
        err.code = 'INVALID_CUSTOM_ITEM';
        throw err;
      }
      if (!title || typeof title !== 'string' || !title.trim()) {
        const err = new Error('CUSTOM item requires a title');
        err.status = 400;
        err.code = 'INVALID_CUSTOM_ITEM';
        throw err;
      }
      if (unit_price === undefined || unit_price === null || isNaN(Number(unit_price)) || Number(unit_price) < 0) {
        const err = new Error('CUSTOM item requires unit_price >= 0.00');
        err.status = 400;
        err.code = 'INVALID_CUSTOM_PRICE';
        throw err;
      }

      titleSnapshot = title.trim();
      unitPriceSnapshot = round2(unit_price);
    }

    // Calculate Item Total
    let itemTotal = round2(numQty * unitPriceSnapshot - numDiscount);
    if (itemTotal < 0.00) itemTotal = 0.00;

    // Insert Item
    const itemInsertRes = await client.query(`
      INSERT INTO saas_ticket_items (
        ticket_id,
        tenant_id,
        establishment_id,
        item_type,
        service_offer_id,
        performed_by_membership_id,
        title_snapshot,
        quantity,
        unit_price_snapshot,
        discount_amount,
        total_amount
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
      )
      RETURNING *;
    `, [
      ticketId,
      tenantId,
      establishmentId,
      item_type,
      item_type === 'SERVICE' ? service_offer_id : null,
      performed_by_membership_id,
      titleSnapshot,
      numQty,
      unitPriceSnapshot,
      numDiscount,
      itemTotal
    ]);

    const createdItem = itemInsertRes.rows[0];

    // Recalculate Ticket Totals
    const updatedTicket = await recalculateTicketTotals(client, ticketId, tenantId, establishmentId);

    await client.query('COMMIT');
    return {
      item: createdItem,
      ticket: updatedTicket
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * 3. UPDATE ITEM (PATCH /api/saas/tickets/:id/items/:itemId)
 */
async function updateItem(activeContext, ticketId, itemId, data) {
  const { tenant_id: tenantId, establishment_id: establishmentId, role: callerRole } = activeContext;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    // Fetch ticket
    const ticketRes = await client.query(`
      SELECT id, status
      FROM saas_service_tickets
      WHERE id = $1 AND tenant_id = $2 AND establishment_id = $3
      FOR UPDATE
    `, [ticketId, tenantId, establishmentId]);

    if (ticketRes.rows.length === 0) {
      const err = new Error('Ticket not found');
      err.status = 404;
      err.code = 'TICKET_NOT_FOUND';
      throw err;
    }

    const ticket = ticketRes.rows[0];

    if (ticket.status === 'DRAFT') {
      if (!['OWNER', 'MANAGER', 'RECEPTIONIST'].includes(callerRole)) {
        const err = new Error(`Role ${callerRole} is not authorized to edit items in DRAFT`);
        err.status = 403;
        err.code = 'UNAUTHORIZED_ROLE';
        throw err;
      }
    } else if (ticket.status === 'OPEN') {
      if (!['OWNER', 'MANAGER'].includes(callerRole)) {
        const err = new Error(`Only OWNER or MANAGER can edit items in OPEN status`);
        err.status = 403;
        err.code = 'UNAUTHORIZED_ROLE';
        throw err;
      }
    } else {
      const err = new Error(`Cannot modify items on ticket in ${ticket.status} status`);
      err.status = 422;
      err.code = 'IMMUTABLE_TICKET_STATUS';
      throw err;
    }

    // Fetch existing item
    const itemRes = await client.query(`
      SELECT *
      FROM saas_ticket_items
      WHERE id = $1 AND ticket_id = $2 AND tenant_id = $3 AND establishment_id = $4
      FOR UPDATE
    `, [itemId, ticketId, tenantId, establishmentId]);

    if (itemRes.rows.length === 0) {
      const err = new Error('Ticket item not found');
      err.status = 404;
      err.code = 'ITEM_NOT_FOUND';
      throw err;
    }

    const existingItem = itemRes.rows[0];

    let newQuantity = existingItem.quantity;
    if (data.quantity !== undefined) {
      const q = parseInt(data.quantity, 10);
      if (isNaN(q) || q < 1) {
        const err = new Error('quantity must be an integer >= 1');
        err.status = 400;
        err.code = 'INVALID_QUANTITY';
        throw err;
      }
      newQuantity = q;
    }

    let newDiscount = round2(existingItem.discount_amount);
    if (data.discount_amount !== undefined) {
      const d = round2(data.discount_amount);
      if (d < 0) {
        const err = new Error('discount_amount must be >= 0.00');
        err.status = 400;
        err.code = 'INVALID_DISCOUNT';
        throw err;
      }
      newDiscount = d;
    }

    let newTitle = existingItem.title_snapshot;
    let newUnitPrice = round2(existingItem.unit_price_snapshot);

    if (existingItem.item_type === 'CUSTOM') {
      if (data.title !== undefined) {
        if (!data.title || typeof data.title !== 'string' || !data.title.trim()) {
          const err = new Error('CUSTOM item title cannot be empty');
          err.status = 400;
          err.code = 'INVALID_CUSTOM_ITEM';
          throw err;
        }
        newTitle = data.title.trim();
      }
      if (data.unit_price !== undefined) {
        const p = round2(data.unit_price);
        if (p < 0) {
          const err = new Error('unit_price must be >= 0.00');
          err.status = 400;
          err.code = 'INVALID_CUSTOM_PRICE';
          throw err;
        }
        newUnitPrice = p;
      }
    } else {
      // SERVICE item: cannot change title or unit price
      if (data.title !== undefined || data.unit_price !== undefined || data.service_offer_id !== undefined) {
        const err = new Error('Cannot modify service_offer_id, title, or unit_price on SERVICE items');
        err.status = 400;
        err.code = 'INVALID_SERVICE_ITEM_MODIFICATION';
        throw err;
      }
    }

    let newTotal = round2(newQuantity * newUnitPrice - newDiscount);
    if (newTotal < 0.00) newTotal = 0.00;

    const updateItemRes = await client.query(`
      UPDATE saas_ticket_items
      SET quantity = $1,
          discount_amount = $2,
          title_snapshot = $3,
          unit_price_snapshot = $4,
          total_amount = $5,
          updated_at = NOW()
      WHERE id = $6 AND ticket_id = $7 AND tenant_id = $8 AND establishment_id = $9
      RETURNING *
    `, [newQuantity, newDiscount, newTitle, newUnitPrice, newTotal, itemId, ticketId, tenantId, establishmentId]);

    const updatedItem = updateItemRes.rows[0];

    // Recalculate ticket totals
    const updatedTicket = await recalculateTicketTotals(client, ticketId, tenantId, establishmentId);

    await client.query('COMMIT');
    return {
      item: updatedItem,
      ticket: updatedTicket
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * 4. DELETE ITEM (DELETE /api/saas/tickets/:id/items/:itemId)
 */
async function deleteItem(activeContext, ticketId, itemId) {
  const { tenant_id: tenantId, establishment_id: establishmentId, role: callerRole } = activeContext;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    const ticketRes = await client.query(`
      SELECT id, status
      FROM saas_service_tickets
      WHERE id = $1 AND tenant_id = $2 AND establishment_id = $3
      FOR UPDATE
    `, [ticketId, tenantId, establishmentId]);

    if (ticketRes.rows.length === 0) {
      const err = new Error('Ticket not found');
      err.status = 404;
      err.code = 'TICKET_NOT_FOUND';
      throw err;
    }

    const ticket = ticketRes.rows[0];

    // Deletion allowed only in DRAFT
    if (ticket.status !== 'DRAFT') {
      const err = new Error(`Items can only be deleted while ticket is in DRAFT (current: ${ticket.status})`);
      err.status = 422;
      err.code = 'IMMUTABLE_TICKET_STATUS';
      throw err;
    }

    if (!['OWNER', 'MANAGER', 'RECEPTIONIST'].includes(callerRole)) {
      const err = new Error(`Role ${callerRole} is not authorized to delete items`);
      err.status = 403;
      err.code = 'UNAUTHORIZED_ROLE';
      throw err;
    }

    const deleteRes = await client.query(`
      DELETE FROM saas_ticket_items
      WHERE id = $1 AND ticket_id = $2 AND tenant_id = $3 AND establishment_id = $4
      RETURNING id;
    `, [itemId, ticketId, tenantId, establishmentId]);

    if (deleteRes.rows.length === 0) {
      const err = new Error('Ticket item not found');
      err.status = 404;
      err.code = 'ITEM_NOT_FOUND';
      throw err;
    }

    // Recalculate ticket totals
    const updatedTicket = await recalculateTicketTotals(client, ticketId, tenantId, establishmentId);

    await client.query('COMMIT');
    return {
      deleted: true,
      ticket: updatedTicket
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * 5. APPLY ADJUSTMENTS (PATCH /api/saas/tickets/:id/adjustments)
 */
async function applyAdjustments(activeContext, ticketId, data) {
  const { tenant_id: tenantId, establishment_id: establishmentId, role: callerRole } = activeContext;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    const ticketRes = await client.query(`
      SELECT *
      FROM saas_service_tickets
      WHERE id = $1 AND tenant_id = $2 AND establishment_id = $3
      FOR UPDATE
    `, [ticketId, tenantId, establishmentId]);

    if (ticketRes.rows.length === 0) {
      const err = new Error('Ticket not found');
      err.status = 404;
      err.code = 'TICKET_NOT_FOUND';
      throw err;
    }

    const ticket = ticketRes.rows[0];

    if (ticket.status === 'DRAFT') {
      if (!['OWNER', 'MANAGER', 'RECEPTIONIST'].includes(callerRole)) {
        const err = new Error(`Role ${callerRole} is not authorized to apply adjustments in DRAFT`);
        err.status = 403;
        err.code = 'UNAUTHORIZED_ROLE';
        throw err;
      }
    } else if (ticket.status === 'OPEN') {
      if (!['OWNER', 'MANAGER'].includes(callerRole)) {
        const err = new Error(`Only OWNER or MANAGER can apply adjustments in OPEN status`);
        err.status = 403;
        err.code = 'UNAUTHORIZED_ROLE';
        throw err;
      }
    } else {
      const err = new Error(`Cannot apply adjustments to ticket in ${ticket.status} status`);
      err.status = 422;
      err.code = 'IMMUTABLE_TICKET_STATUS';
      throw err;
    }

    let newDiscount = round2(ticket.discount_amount);
    let newDiscountReason = ticket.discount_reason;
    if (data.discount_amount !== undefined) {
      const d = round2(data.discount_amount);
      if (d < 0) {
        const err = new Error('discount_amount must be >= 0.00');
        err.status = 400;
        err.code = 'INVALID_DISCOUNT';
        throw err;
      }
      newDiscount = d;
      newDiscountReason = data.discount_reason ? data.discount_reason.trim() : null;
    }

    let newTip = round2(ticket.tip_amount);
    if (data.tip_amount !== undefined) {
      const t = round2(data.tip_amount);
      if (t < 0) {
        const err = new Error('tip_amount must be >= 0.00');
        err.status = 400;
        err.code = 'INVALID_TIP';
        throw err;
      }
      newTip = t;
    }

    let newTax = round2(ticket.tax_amount);
    if (data.tax_amount !== undefined) {
      const tx = round2(data.tax_amount);
      if (tx < 0) {
        const err = new Error('tax_amount must be >= 0.00');
        err.status = 400;
        err.code = 'INVALID_TAX';
        throw err;
      }
      newTax = tx;
    }

    let newNotes = ticket.notes;
    if (data.notes !== undefined) {
      newNotes = data.notes ? data.notes.trim() : null;
    }

    // Update adjustments on ticket
    await client.query(`
      UPDATE saas_service_tickets
      SET discount_amount = $1,
          discount_reason = $2,
          tip_amount = $3,
          tax_amount = $4,
          notes = $5,
          updated_at = NOW()
      WHERE id = $6 AND tenant_id = $7 AND establishment_id = $8
    `, [newDiscount, newDiscountReason, newTip, newTax, newNotes, ticketId, tenantId, establishmentId]);

    // Recalculate totals
    const updatedTicket = await recalculateTicketTotals(client, ticketId, tenantId, establishmentId);

    await client.query('COMMIT');
    return updatedTicket;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * 6. CONFIRM TICKET (POST /api/saas/tickets/:id/confirm)
 */
async function confirmTicket(activeContext, ticketId) {
  const { tenant_id: tenantId, establishment_id: establishmentId, role: callerRole } = activeContext;

  if (!['OWNER', 'MANAGER', 'RECEPTIONIST'].includes(callerRole)) {
    const err = new Error(`Role ${callerRole} is not authorized to confirm tickets`);
    err.status = 403;
    err.code = 'UNAUTHORIZED_ROLE';
    throw err;
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    const ticketRes = await client.query(`
      SELECT id, status
      FROM saas_service_tickets
      WHERE id = $1 AND tenant_id = $2 AND establishment_id = $3
      FOR UPDATE
    `, [ticketId, tenantId, establishmentId]);

    if (ticketRes.rows.length === 0) {
      const err = new Error('Ticket not found');
      err.status = 404;
      err.code = 'TICKET_NOT_FOUND';
      throw err;
    }

    const ticket = ticketRes.rows[0];

    if (ticket.status !== 'DRAFT') {
      const err = new Error(`Only tickets in DRAFT status can be confirmed (current: ${ticket.status})`);
      err.status = 422;
      err.code = 'INVALID_STATUS_TRANSITION';
      throw err;
    }

    // Must have at least 1 item
    const itemCountRes = await client.query(`
      SELECT COUNT(*)::int AS count
      FROM saas_ticket_items
      WHERE ticket_id = $1 AND tenant_id = $2 AND establishment_id = $3
    `, [ticketId, tenantId, establishmentId]);

    if (itemCountRes.rows[0].count < 1) {
      const err = new Error('Cannot confirm ticket without any items');
      err.status = 422;
      err.code = 'EMPTY_TICKET';
      throw err;
    }

    // Transition to OPEN
    await client.query(`
      UPDATE saas_service_tickets
      SET status = 'OPEN',
          updated_at = NOW()
      WHERE id = $1 AND tenant_id = $2 AND establishment_id = $3
    `, [ticketId, tenantId, establishmentId]);

    // Recalculate totals
    const updatedTicket = await recalculateTicketTotals(client, ticketId, tenantId, establishmentId);

    await client.query('COMMIT');
    return updatedTicket;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * 7. ADD PAYMENT (POST /api/saas/tickets/:id/payments)
 */
async function addPayment(activeContext, ticketId, data) {
  const { tenant_id: tenantId, establishment_id: establishmentId, active_membership_id: callerMembershipId, role: callerRole } = activeContext;

  if (!['OWNER', 'MANAGER', 'RECEPTIONIST'].includes(callerRole)) {
    const err = new Error(`Role ${callerRole} is not authorized to register payments`);
    err.status = 403;
    err.code = 'UNAUTHORIZED_ROLE';
    throw err;
  }

  const { payment_method, amount, reference_code } = data;

  if (!ALLOWED_PAYMENT_METHODS.includes(payment_method)) {
    const err = new Error(`Invalid payment_method. Allowed: ${ALLOWED_PAYMENT_METHODS.join(', ')}`);
    err.status = 400;
    err.code = 'INVALID_PAYMENT_METHOD';
    throw err;
  }

  const paymentAmount = round2(amount);
  if (paymentAmount <= 0) {
    const err = new Error('Payment amount must be > 0.00');
    err.status = 400;
    err.code = 'INVALID_PAYMENT_AMOUNT';
    throw err;
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    const ticketRes = await client.query(`
      SELECT id, status, total_amount, paid_amount, balance_due
      FROM saas_service_tickets
      WHERE id = $1 AND tenant_id = $2 AND establishment_id = $3
      FOR UPDATE
    `, [ticketId, tenantId, establishmentId]);

    if (ticketRes.rows.length === 0) {
      const err = new Error('Ticket not found');
      err.status = 404;
      err.code = 'TICKET_NOT_FOUND';
      throw err;
    }

    const ticket = ticketRes.rows[0];

    if (ticket.status !== 'OPEN') {
      const err = new Error(`Payments can only be registered on OPEN tickets (current: ${ticket.status})`);
      err.status = 422;
      err.code = 'INVALID_STATUS_FOR_PAYMENT';
      throw err;
    }

    const currentBalance = round2(ticket.balance_due);

    // Overpayment check
    if (paymentAmount > currentBalance + 0.001) {
      const err = new Error(`Payment amount (${paymentAmount}) exceeds remaining balance (${currentBalance})`);
      err.status = 422;
      err.code = 'OVERPAYMENT_NOT_ALLOWED';
      throw err;
    }

    // Insert Payment record
    const payInsertRes = await client.query(`
      INSERT INTO saas_ticket_payments (
        ticket_id,
        tenant_id,
        establishment_id,
        payment_method,
        amount,
        reference_code,
        received_by_membership_id
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7
      )
      RETURNING *;
    `, [
      ticketId,
      tenantId,
      establishmentId,
      payment_method,
      paymentAmount,
      reference_code ? reference_code.trim() : null,
      callerMembershipId
    ]);

    const payment = payInsertRes.rows[0];

    // Recalculate totals and check automatic transition to PAID
    const updatedTicket = await recalculateTicketTotals(client, ticketId, tenantId, establishmentId);

    await client.query('COMMIT');
    return {
      payment,
      ticket: updatedTicket
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * 8. CLOSE TICKET (POST /api/saas/tickets/:id/close)
 */
async function closeTicket(activeContext, ticketId) {
  const { tenant_id: tenantId, establishment_id: establishmentId, active_membership_id: callerMembershipId, role: callerRole } = activeContext;

  if (!['OWNER', 'MANAGER', 'RECEPTIONIST'].includes(callerRole)) {
    const err = new Error(`Role ${callerRole} is not authorized to close tickets`);
    err.status = 403;
    err.code = 'UNAUTHORIZED_ROLE';
    throw err;
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    const ticketRes = await client.query(`
      SELECT id, status, balance_due
      FROM saas_service_tickets
      WHERE id = $1 AND tenant_id = $2 AND establishment_id = $3
      FOR UPDATE
    `, [ticketId, tenantId, establishmentId]);

    if (ticketRes.rows.length === 0) {
      const err = new Error('Ticket not found');
      err.status = 404;
      err.code = 'TICKET_NOT_FOUND';
      throw err;
    }

    const ticket = ticketRes.rows[0];

    if (ticket.status !== 'PAID') {
      const err = new Error(`Only PAID tickets can be closed (current: ${ticket.status})`);
      err.status = 422;
      err.code = 'INVALID_STATUS_FOR_CLOSE';
      throw err;
    }

    const updateRes = await client.query(`
      UPDATE saas_service_tickets
      SET status = 'CLOSED',
          closed_by_membership_id = $1,
          closed_at = NOW(),
          updated_at = NOW()
      WHERE id = $2 AND tenant_id = $3 AND establishment_id = $4
      RETURNING *;
    `, [callerMembershipId, ticketId, tenantId, establishmentId]);

    await client.query('COMMIT');
    return updateRes.rows[0];
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * 9. VOID TICKET (POST /api/saas/tickets/:id/void)
 */
async function voidTicket(activeContext, ticketId, data) {
  const { tenant_id: tenantId, establishment_id: establishmentId, active_membership_id: callerMembershipId, role: callerRole } = activeContext;

  // RBAC: ONLY OWNER or MANAGER
  if (!['OWNER', 'MANAGER'].includes(callerRole)) {
    const err = new Error(`Role ${callerRole} is not authorized to void tickets. Requires OWNER or MANAGER.`);
    err.status = 403;
    err.code = 'UNAUTHORIZED_ROLE';
    throw err;
  }

  const { reason } = data || {};
  if (!reason || typeof reason !== 'string' || !reason.trim()) {
    const err = new Error('A valid reason is required to void a ticket');
    err.status = 400;
    err.code = 'MISSING_VOID_REASON';
    throw err;
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    const ticketRes = await client.query(`
      SELECT id, status
      FROM saas_service_tickets
      WHERE id = $1 AND tenant_id = $2 AND establishment_id = $3
      FOR UPDATE
    `, [ticketId, tenantId, establishmentId]);

    if (ticketRes.rows.length === 0) {
      const err = new Error('Ticket not found');
      err.status = 404;
      err.code = 'TICKET_NOT_FOUND';
      throw err;
    }

    const ticket = ticketRes.rows[0];

    // Allowed from DRAFT or OPEN only
    if (!['DRAFT', 'OPEN'].includes(ticket.status)) {
      const err = new Error(`Cannot void ticket in ${ticket.status} status`);
      err.status = 422;
      err.code = 'CANNOT_VOID_STATUS';
      throw err;
    }

    const updateRes = await client.query(`
      UPDATE saas_service_tickets
      SET status = 'VOID',
          voided_by_membership_id = $1,
          void_reason = $2,
          voided_at = NOW(),
          updated_at = NOW()
      WHERE id = $3 AND tenant_id = $4 AND establishment_id = $5
      RETURNING *;
    `, [callerMembershipId, reason.trim(), ticketId, tenantId, establishmentId]);

    await client.query('COMMIT');
    return updateRes.rows[0];
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * 10. GET TICKET BY ID (GET /api/saas/tickets/:id)
 */
async function getTicketById(activeContext, ticketId) {
  const { tenant_id: tenantId, establishment_id: establishmentId, active_membership_id: callerMembershipId, role: callerRole } = activeContext;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    const ticketRes = await client.query(`
      SELECT t.*,
             u.nombre AS customer_name,
             u.email AS customer_email,
             u.phone AS customer_phone
      FROM saas_service_tickets t
      LEFT JOIN usuarios u ON u.id = t.customer_user_id
      WHERE t.id = $1 AND t.tenant_id = $2 AND t.establishment_id = $3
    `, [ticketId, tenantId, establishmentId]);

    if (ticketRes.rows.length === 0) {
      await client.query('COMMIT');
      const err = new Error('Ticket not found');
      err.status = 404;
      err.code = 'TICKET_NOT_FOUND';
      throw err;
    }

    const ticket = ticketRes.rows[0];

    // Fetch items
    const itemsRes = await client.query(`
      SELECT i.*,
             u.nombre AS performer_name
      FROM saas_ticket_items i
      LEFT JOIN memberships m ON m.id = i.performed_by_membership_id
      LEFT JOIN usuarios u ON u.id = m.user_id
      WHERE i.ticket_id = $1 AND i.tenant_id = $2 AND i.establishment_id = $3
      ORDER BY i.created_at ASC
    `, [ticketId, tenantId, establishmentId]);

    // Fetch payments
    const paymentsRes = await client.query(`
      SELECT p.*,
             u.nombre AS receiver_name
      FROM saas_ticket_payments p
      LEFT JOIN memberships m ON m.id = p.received_by_membership_id
      LEFT JOIN usuarios u ON u.id = m.user_id
      WHERE p.ticket_id = $1 AND p.tenant_id = $2 AND p.establishment_id = $3
      ORDER BY p.created_at ASC
    `, [ticketId, tenantId, establishmentId]);

    await client.query('COMMIT');

    // RBAC: If PROFESSIONAL, must have performed at least one item on this ticket
    if (callerRole === 'PROFESSIONAL') {
      const ownItems = itemsRes.rows.filter(i => i.performed_by_membership_id === callerMembershipId);
      if (ownItems.length === 0) {
        const err = new Error('Professional is not authorized to view this ticket (no assigned items)');
        err.status = 403;
        err.code = 'UNAUTHORIZED_ROLE';
        throw err;
      }
      // Return filtered items for professional
      return {
        ...ticket,
        items: ownItems,
        payments: [] // Professional does not see payments details
      };
    }

    return {
      ...ticket,
      items: itemsRes.rows,
      payments: paymentsRes.rows
    };
  } catch (err) {
    try {
      await client.query('ROLLBACK');
    } catch (rbErr) {
      // ignore
    }
    throw err;
  } finally {
    client.release();
  }
}

/**
 * 11. LIST TICKETS (GET /api/saas/tickets)
 */
async function listTickets(activeContext, query = {}) {
  const { tenant_id: tenantId, establishment_id: establishmentId, role: callerRole } = activeContext;

  // RBAC: OWNER, MANAGER, RECEPTIONIST only
  if (!['OWNER', 'MANAGER', 'RECEPTIONIST'].includes(callerRole)) {
    const err = new Error(`Role ${callerRole} is not authorized to list establishment tickets`);
    err.status = 403;
    err.code = 'UNAUTHORIZED_ROLE';
    throw err;
  }

  const { status, date_from, date_to, page = 1, limit = 20 } = query || {};

  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 20));
  const offset = (pageNum - 1) * limitNum;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query("SELECT set_config('app.tenant_id', $1, true);", [tenantId.toString()]);

    let whereClause = 'WHERE t.tenant_id = $1 AND t.establishment_id = $2';
    const params = [tenantId, establishmentId];
    let paramIdx = 3;

    if (status && VALID_TICKET_STATUSES.includes(status.toUpperCase())) {
      whereClause += ` AND t.status = $${paramIdx++}`;
      params.push(status.toUpperCase());
    }

    if (date_from) {
      whereClause += ` AND t.created_at >= $${paramIdx++}`;
      params.push(new Date(date_from).toISOString());
    }

    if (date_to) {
      whereClause += ` AND t.created_at <= $${paramIdx++}`;
      params.push(new Date(date_to).toISOString());
    }

    const countRes = await client.query(`
      SELECT COUNT(*)::int AS total
      FROM saas_service_tickets t
      ${whereClause}
    `, params);

    const total = countRes.rows[0].total;

    const listParams = [...params, limitNum, offset];
    const dataRes = await client.query(`
      SELECT t.*,
             u.nombre AS customer_name,
             u.email AS customer_email,
             (SELECT COUNT(*)::int FROM saas_ticket_items i WHERE i.ticket_id = t.id) AS items_count,
             (SELECT COUNT(*)::int FROM saas_ticket_payments p WHERE p.ticket_id = t.id) AS payments_count
      FROM saas_service_tickets t
      LEFT JOIN usuarios u ON u.id = t.customer_user_id
      ${whereClause}
      ORDER BY t.created_at DESC
      LIMIT $${paramIdx++} OFFSET $${paramIdx++}
    `, listParams);

    await client.query('COMMIT');

    return {
      tickets: dataRes.rows,
      pagination: {
        total,
        page: pageNum,
        limit: limitNum,
        totalPages: Math.ceil(total / limitNum)
      }
    };
  } catch (err) {
    try {
      await client.query('ROLLBACK');
    } catch (rbErr) {
      // ignore
    }
    throw err;
  } finally {
    client.release();
  }
}

module.exports = {
  createTicket,
  addItem,
  updateItem,
  deleteItem,
  applyAdjustments,
  confirmTicket,
  addPayment,
  closeTicket,
  voidTicket,
  getTicketById,
  listTickets
};
