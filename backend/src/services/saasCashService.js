// backend/src/services/saasCashService.js
const { pool } = require('../config/db');

const ALLOWED_ROLES = ['OWNER', 'MANAGER', 'RECEPTIONIST'];

class SaasCashService {
  /**
   * Helper: Validates active context and RBAC permissions.
   */
  _validateRbac(activeContext, allowedRoles = ALLOWED_ROLES) {
    if (!activeContext || !activeContext.tenant_id || !activeContext.establishment_id) {
      const err = new Error('Contexto activo requerido (tenant_id y establishment_id).');
      err.statusCode = 400;
      err.code = 'ACTIVE_CONTEXT_REQUIRED';
      throw err;
    }

    const role = (activeContext.role || '').toUpperCase();
    if (!allowedRoles.includes(role)) {
      const err = new Error(`Acceso denegado. Rol ${role} no tiene permisos para operar caja.`);
      err.statusCode = 403;
      err.code = 'FORBIDDEN_ROLE';
      throw err;
    }
  }

  /**
   * GET /api/saas/cash/current
   * Returns the current active session in the establishment.
   */
  async getCurrentSession(activeContext) {
    this._validateRbac(activeContext);
    const { tenant_id, establishment_id, role } = activeContext;

    const sessionQuery = `
      SELECT 
        s.id,
        s.tenant_id,
        s.establishment_id,
        s.opened_by_membership_id,
        s.opened_at,
        s.opening_balance::numeric,
        s.status,
        s.closing_notes,
        s.created_at,
        u.nombre AS opened_by_name,
        u.email AS opened_by_email
      FROM saas_cash_sessions s
      JOIN memberships m ON s.opened_by_membership_id = m.id AND s.establishment_id = m.establishment_id AND s.tenant_id = m.tenant_id
      JOIN usuarios u ON m.user_id = u.id
      WHERE s.establishment_id = $1 
        AND s.tenant_id = $2 
        AND s.status = 'OPEN'
      LIMIT 1;
    `;

    const { rows: sessionRows } = await pool.query(sessionQuery, [establishment_id, tenant_id]);

    if (sessionRows.length === 0) {
      return {
        is_open: false,
        session: null
      };
    }

    const session = sessionRows[0];

    // Compute aggregated metrics for the open session
    const metricsQuery = `
      SELECT 
        COALESCE(SUM(amount) FILTER (WHERE movement_type = 'CASH_SALE'), 0.00)::numeric AS cash_sales_total,
        COALESCE(SUM(amount) FILTER (WHERE movement_type = 'CASH_IN'), 0.00)::numeric AS cash_in_total,
        COALESCE(SUM(amount) FILTER (WHERE movement_type = 'CASH_OUT'), 0.00)::numeric AS cash_out_total,
        COUNT(*)::int AS movements_count
      FROM saas_cash_movements
      WHERE session_id = $1 AND tenant_id = $2;
    `;

    const { rows: metricsRows } = await pool.query(metricsQuery, [session.id, tenant_id]);
    const metrics = metricsRows[0] || {
      cash_sales_total: 0.00,
      cash_in_total: 0.00,
      cash_out_total: 0.00,
      movements_count: 0
    };

    const openingBalance = parseFloat(session.opening_balance);
    const cashSalesTotal = parseFloat(metrics.cash_sales_total);
    const cashInTotal = parseFloat(metrics.cash_in_total);
    const cashOutTotal = parseFloat(metrics.cash_out_total);
    const calculatedExpectedCash = openingBalance + cashSalesTotal + cashInTotal - cashOutTotal;

    const isReceptionist = (role || '').toUpperCase() === 'RECEPTIONIST';

    return {
      is_open: true,
      session: {
        id: session.id,
        opened_at: session.opened_at,
        opening_balance: openingBalance,
        opened_by: {
          membership_id: session.opened_by_membership_id,
          name: session.opened_by_name || 'Operador',
          email: session.opened_by_email
        },
        metrics: {
          cash_sales_total: cashSalesTotal,
          cash_in_total: cashInTotal,
          cash_out_total: cashOutTotal,
          // Blind Close: RECEPTIONIST does not receive expected_cash
          expected_cash: isReceptionist ? null : calculatedExpectedCash,
          movements_count: parseInt(metrics.movements_count, 10)
        }
      }
    };
  }

  /**
   * POST /api/saas/cash/open
   * Opens a new cash session for the establishment.
   */
  async openSession(activeContext, { opening_balance, notes }) {
    this._validateRbac(activeContext);
    const { tenant_id, establishment_id, membership_id } = activeContext;

    const balanceNum = parseFloat(opening_balance !== undefined ? opening_balance : 0);
    if (isNaN(balanceNum) || balanceNum < 0) {
      const err = new Error('El monto de apertura debe ser un número mayor o igual a 0.00.');
      err.statusCode = 400;
      err.code = 'INVALID_OPENING_BALANCE';
      throw err;
    }

    try {
      const insertQuery = `
        INSERT INTO saas_cash_sessions (
          tenant_id,
          establishment_id,
          opened_by_membership_id,
          opening_balance,
          closing_notes,
          status
        ) VALUES ($1, $2, $3, $4, $5, 'OPEN')
        RETURNING *;
      `;

      const { rows } = await pool.query(insertQuery, [
        tenant_id,
        establishment_id,
        membership_id,
        balanceNum,
        notes || null
      ]);

      const createdSession = rows[0];

      return {
        success: true,
        message: 'Sesión de caja abierta exitosamente.',
        session: {
          id: createdSession.id,
          establishment_id: createdSession.establishment_id,
          opened_by_membership_id: createdSession.opened_by_membership_id,
          opened_at: createdSession.opened_at,
          opening_balance: parseFloat(createdSession.opening_balance),
          status: createdSession.status
        }
      };
    } catch (dbError) {
      if (dbError.code === '23505') { // Unique violation
        const err = new Error('Ya existe una sesión de caja abierta en este establecimiento.');
        err.statusCode = 409;
        err.code = 'CASH_SESSION_ALREADY_OPEN';
        throw err;
      }
      throw dbError;
    }
  }

  /**
   * POST /api/saas/cash/movements
   * Records a manual cash movement (CASH_IN or CASH_OUT).
   */
  async recordManualMovement(activeContext, { movement_type, category, amount, reason }) {
    this._validateRbac(activeContext);
    const { tenant_id, establishment_id, membership_id } = activeContext;

    const validTypes = ['CASH_IN', 'CASH_OUT'];
    const typeUpper = (movement_type || '').toUpperCase();
    if (!validTypes.includes(typeUpper)) {
      const err = new Error('Tipo de movimiento inválido. Debe ser CASH_IN o CASH_OUT.');
      err.statusCode = 400;
      err.code = 'INVALID_MOVEMENT_TYPE';
      throw err;
    }

    const amountNum = parseFloat(amount);
    if (isNaN(amountNum) || amountNum <= 0) {
      const err = new Error('El monto del movimiento debe ser un número estrictamente mayor a 0.00.');
      err.statusCode = 400;
      err.code = 'INVALID_MOVEMENT_AMOUNT';
      throw err;
    }

    const trimmedReason = (reason || '').trim();
    if (!trimmedReason) {
      const err = new Error('El motivo del movimiento es obligatorio.');
      err.statusCode = 400;
      err.code = 'REASON_REQUIRED';
      throw err;
    }

    const trimmedCategory = (category || (typeUpper === 'CASH_IN' ? 'BASE_ADICIONAL' : 'GASTO_MENOR')).trim();

    // Check if there is an active session
    const activeSessionRes = await pool.query(
      `SELECT id, opening_balance FROM saas_cash_sessions WHERE establishment_id = $1 AND tenant_id = $2 AND status = 'OPEN' LIMIT 1;`,
      [establishment_id, tenant_id]
    );

    if (activeSessionRes.rows.length === 0) {
      const err = new Error('No hay una sesión de caja abierta en este establecimiento para registrar movimientos.');
      err.statusCode = 422;
      err.code = 'CASH_DRAWER_NOT_OPEN';
      throw err;
    }

    const sessionId = activeSessionRes.rows[0].id;
    const openingBalance = parseFloat(activeSessionRes.rows[0].opening_balance);

    // If CASH_OUT, verify drawer funds sufficiency
    if (typeUpper === 'CASH_OUT') {
      const sumQuery = `
        SELECT 
          COALESCE(SUM(amount) FILTER (WHERE movement_type = 'CASH_SALE'), 0.00)::numeric AS sales,
          COALESCE(SUM(amount) FILTER (WHERE movement_type = 'CASH_IN'), 0.00)::numeric AS cash_in,
          COALESCE(SUM(amount) FILTER (WHERE movement_type = 'CASH_OUT'), 0.00)::numeric AS cash_out
        FROM saas_cash_movements
        WHERE session_id = $1 AND tenant_id = $2;
      `;
      const { rows: sumRows } = await pool.query(sumQuery, [sessionId, tenant_id]);
      const currentCash = openingBalance + parseFloat(sumRows[0].sales) + parseFloat(sumRows[0].cash_in) - parseFloat(sumRows[0].cash_out);

      if (amountNum > currentCash) {
        const err = new Error(`Fondos insuficientes en caja para realizar este egreso. Disponible estimado: $${currentCash.toFixed(2)}, Solicitado: $${amountNum.toFixed(2)}`);
        err.statusCode = 422;
        err.code = 'INSUFFICIENT_CASH_IN_DRAWER';
        throw err;
      }
    }

    const insertMovementQuery = `
      INSERT INTO saas_cash_movements (
        session_id,
        tenant_id,
        establishment_id,
        movement_type,
        category,
        amount,
        reason,
        performed_by_membership_id
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *;
    `;

    const { rows: movementRows } = await pool.query(insertMovementQuery, [
      sessionId,
      tenant_id,
      establishment_id,
      typeUpper,
      trimmedCategory,
      amountNum,
      trimmedReason,
      membership_id
    ]);

    const movement = movementRows[0];

    return {
      success: true,
      message: 'Movimiento de caja registrado exitosamente.',
      movement: {
        id: movement.id,
        session_id: movement.session_id,
        movement_type: movement.movement_type,
        category: movement.category,
        amount: parseFloat(movement.amount),
        reason: movement.reason,
        performed_by_membership_id: movement.performed_by_membership_id,
        created_at: movement.created_at
      }
    };
  }

  /**
   * Internal / Orchestrated Method: recordCashSale
   * Triggered when a ticket payment with payment_method = 'CASH' is confirmed.
   */
  async recordCashSale(activeContext, { ticketPaymentId, ticketId, amount, performedByMembershipId }) {
    if (!activeContext || !activeContext.tenant_id || !activeContext.establishment_id) {
      const err = new Error('Contexto activo requerido.');
      err.statusCode = 400;
      err.code = 'ACTIVE_CONTEXT_REQUIRED';
      throw err;
    }

    const { tenant_id, establishment_id, membership_id } = activeContext;
    const performer = performedByMembershipId || membership_id;
    const amountNum = parseFloat(amount);

    if (isNaN(amountNum) || amountNum <= 0) {
      const err = new Error('Monto de venta en efectivo inválido.');
      err.statusCode = 400;
      err.code = 'INVALID_AMOUNT';
      throw err;
    }

    // Check if active cash session exists
    const activeSessionRes = await pool.query(
      `SELECT id FROM saas_cash_sessions WHERE establishment_id = $1 AND tenant_id = $2 AND status = 'OPEN' LIMIT 1;`,
      [establishment_id, tenant_id]
    );

    if (activeSessionRes.rows.length === 0) {
      const err = new Error('No hay una sesión de caja abierta en este establecimiento para imputar el pago en efectivo.');
      err.statusCode = 422;
      err.code = 'CASH_DRAWER_NOT_OPEN';
      throw err;
    }

    const sessionId = activeSessionRes.rows[0].id;

    // Insert movement with idempotency on ticket_payment_id
    const insertQuery = `
      INSERT INTO saas_cash_movements (
        session_id,
        tenant_id,
        establishment_id,
        movement_type,
        category,
        amount,
        reason,
        performed_by_membership_id,
        ticket_payment_id
      ) VALUES ($1, $2, $3, 'CASH_SALE', 'TICKET_PAYMENT', $4, $5, $6, $7)
      ON CONFLICT (ticket_payment_id) DO NOTHING
      RETURNING *;
    `;

    const reasonStr = `Cobro de Ticket #${ticketId ? ticketId.substring(0, 8) : ''}`;
    const { rows } = await pool.query(insertQuery, [
      sessionId,
      tenant_id,
      establishment_id,
      amountNum,
      reasonStr,
      performer,
      ticketPaymentId || null
    ]);

    return {
      success: true,
      movement: rows[0] || null
    };
  }

  /**
   * POST /api/saas/cash/close
   * Performs count, reconciliation, and closes the active cash session.
   */
  async closeSession(activeContext, { counted_cash, closing_notes }) {
    this._validateRbac(activeContext);
    const { tenant_id, establishment_id, membership_id } = activeContext;

    const countedNum = parseFloat(counted_cash);
    if (isNaN(countedNum) || countedNum < 0) {
      const err = new Error('El monto de efectivo contado debe ser un número mayor o igual a 0.00.');
      err.statusCode = 400;
      err.code = 'INVALID_COUNTED_AMOUNT';
      throw err;
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Lock open session for update
      const sessionRes = await client.query(
        `SELECT * FROM saas_cash_sessions 
         WHERE establishment_id = $1 AND tenant_id = $2 AND status = 'OPEN' 
         FOR UPDATE;`,
        [establishment_id, tenant_id]
      );

      if (sessionRes.rows.length === 0) {
        const err = new Error('No hay una sesión de caja abierta en este establecimiento para cerrar.');
        err.statusCode = 422;
        err.code = 'CASH_DRAWER_NOT_OPEN';
        throw err;
      }

      const session = sessionRes.rows[0];

      // Sum all movements
      const sumQuery = `
        SELECT 
          COALESCE(SUM(amount) FILTER (WHERE movement_type = 'CASH_SALE'), 0.00)::numeric AS sales,
          COALESCE(SUM(amount) FILTER (WHERE movement_type = 'CASH_IN'), 0.00)::numeric AS cash_in,
          COALESCE(SUM(amount) FILTER (WHERE movement_type = 'CASH_OUT'), 0.00)::numeric AS cash_out
        FROM saas_cash_movements
        WHERE session_id = $1 AND tenant_id = $2;
      `;
      const sumRes = await client.query(sumQuery, [session.id, tenant_id]);
      const metrics = sumRes.rows[0];

      const openingBalance = parseFloat(session.opening_balance);
      const salesTotal = parseFloat(metrics.sales);
      const inTotal = parseFloat(metrics.cash_in);
      const outTotal = parseFloat(metrics.cash_out);

      const expectedCash = openingBalance + salesTotal + inTotal - outTotal;
      const difference = countedNum - expectedCash;

      let reconciliationStatus = 'BALANCED';
      if (difference > 0) {
        reconciliationStatus = 'SURPLUS';
      } else if (difference < 0) {
        reconciliationStatus = 'SHORTAGE';
      }

      // Update session to CLOSED
      const updateQuery = `
        UPDATE saas_cash_sessions
        SET 
          status = 'CLOSED',
          closed_by_membership_id = $1,
          closed_at = CURRENT_TIMESTAMP,
          expected_cash = $2,
          counted_cash = $3,
          difference = $4,
          closing_notes = $5,
          updated_at = CURRENT_TIMESTAMP
        WHERE id = $6 AND tenant_id = $7
        RETURNING *;
      `;

      const updateRes = await client.query(updateQuery, [
        membership_id,
        expectedCash,
        countedNum,
        difference,
        closing_notes || null,
        session.id,
        tenant_id
      ]);

      await client.query('COMMIT');

      const closedSession = updateRes.rows[0];

      return {
        success: true,
        message: 'Sesión de caja cerrada y arqueada exitosamente.',
        session: {
          id: closedSession.id,
          status: closedSession.status,
          opened_at: closedSession.opened_at,
          closed_at: closedSession.closed_at,
          opening_balance: parseFloat(closedSession.opening_balance),
          expected_cash: parseFloat(closedSession.expected_cash),
          counted_cash: parseFloat(closedSession.counted_cash),
          difference: parseFloat(closedSession.difference),
          reconciliation_status: reconciliationStatus,
          closing_notes: closedSession.closing_notes
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
   * GET /api/saas/cash/sessions/:id/movements
   * Lists atomic movements for a cash session.
   */
  async listMovements(activeContext, sessionId) {
    this._validateRbac(activeContext);
    const { tenant_id, establishment_id } = activeContext;

    // Verify session belongs to active context
    const sessionRes = await pool.query(
      `SELECT id, establishment_id, tenant_id FROM saas_cash_sessions WHERE id = $1 AND tenant_id = $2;`,
      [sessionId, tenant_id]
    );

    if (sessionRes.rows.length === 0) {
      const err = new Error('Sesión de caja no encontrada.');
      err.statusCode = 404;
      err.code = 'CASH_SESSION_NOT_FOUND';
      throw err;
    }

    if (sessionRes.rows[0].establishment_id !== establishment_id) {
      const err = new Error('Acceso denegado a sesión de otro establecimiento.');
      err.statusCode = 403;
      err.code = 'FORBIDDEN_CROSS_ESTABLISHMENT';
      throw err;
    }

    const query = `
      SELECT 
        m.id,
        m.session_id,
        m.movement_type,
        m.category,
        m.amount::numeric,
        m.reason,
        m.performed_by_membership_id,
        m.ticket_payment_id,
        m.created_at,
        u.nombre AS performed_by_name,
        u.email AS performed_by_email
      FROM saas_cash_movements m
      JOIN memberships mem ON m.performed_by_membership_id = mem.id AND m.establishment_id = mem.establishment_id AND m.tenant_id = mem.tenant_id
      JOIN usuarios u ON mem.user_id = u.id
      WHERE m.session_id = $1 AND m.tenant_id = $2
      ORDER BY m.created_at ASC;
    `;

    const { rows } = await pool.query(query, [sessionId, tenant_id]);

    const movements = rows.map(r => ({
      id: r.id,
      session_id: r.session_id,
      movement_type: r.movement_type,
      category: r.category,
      amount: parseFloat(r.amount),
      reason: r.reason,
      performed_by: {
        membership_id: r.performed_by_membership_id,
        name: r.performed_by_name || 'Operador',
        email: r.performed_by_email
      },
      ticket_payment_id: r.ticket_payment_id,
      created_at: r.created_at
    }));

    return {
      success: true,
      session_id: sessionId,
      count: movements.length,
      movements
    };
  }

  /**
   * GET /api/saas/cash/history
   * Lists past closed sessions for the active establishment (OWNER and MANAGER only).
   */
  async getSessionHistory(activeContext, { page = 1, limit = 20, date_from, date_to } = {}) {
    this._validateRbac(activeContext, ['OWNER', 'MANAGER']);
    const { tenant_id, establishment_id } = activeContext;

    const pageNum = Math.max(1, parseInt(page, 10) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 20));
    const offset = (pageNum - 1) * limitNum;

    const params = [establishment_id, tenant_id];
    let whereClauses = `WHERE s.establishment_id = $1 AND s.tenant_id = $2 AND s.status = 'CLOSED'`;

    if (date_from) {
      params.push(date_from);
      whereClauses += ` AND s.opened_at >= $${params.length}`;
    }

    if (date_to) {
      params.push(date_to);
      whereClauses += ` AND s.opened_at <= $${params.length}`;
    }

    const countQuery = `
      SELECT COUNT(*)::int AS total 
      FROM saas_cash_sessions s 
      ${whereClauses};
    `;

    const { rows: countRows } = await pool.query(countQuery, params);
    const totalRecords = countRows[0] ? parseInt(countRows[0].total, 10) : 0;

    const dataParams = [...params, limitNum, offset];
    const dataQuery = `
      SELECT 
        s.id,
        s.opened_at,
        s.closed_at,
        s.opening_balance::numeric,
        s.expected_cash::numeric,
        s.counted_cash::numeric,
        s.difference::numeric,
        s.status,
        s.closing_notes,
        uo.nombre AS opened_by_name,
        uc.nombre AS closed_by_name
      FROM saas_cash_sessions s
      LEFT JOIN memberships mo ON s.opened_by_membership_id = mo.id
      LEFT JOIN usuarios uo ON mo.user_id = uo.id
      LEFT JOIN memberships mc ON s.closed_by_membership_id = mc.id
      LEFT JOIN usuarios uc ON mc.user_id = uc.id
      ${whereClauses}
      ORDER BY s.closed_at DESC
      LIMIT $${params.length + 1} OFFSET $${params.length + 2};
    `;

    const { rows } = await pool.query(dataQuery, dataParams);

    const sessions = rows.map(r => {
      const diff = parseFloat(r.difference || 0);
      let reconciliationStatus = 'BALANCED';
      if (diff > 0) reconciliationStatus = 'SURPLUS';
      else if (diff < 0) reconciliationStatus = 'SHORTAGE';

      return {
        id: r.id,
        opened_at: r.opened_at,
        closed_at: r.closed_at,
        opening_balance: parseFloat(r.opening_balance),
        expected_cash: parseFloat(r.expected_cash),
        counted_cash: parseFloat(r.counted_cash),
        difference: diff,
        reconciliation_status: reconciliationStatus,
        opened_by_name: r.opened_by_name || 'Operador',
        closed_by_name: r.closed_by_name || 'Operador',
        closing_notes: r.closing_notes
      };
    });

    return {
      success: true,
      page: pageNum,
      limit: limitNum,
      total: totalRecords,
      sessions
    };
  }

  /**
   * GET /api/saas/cash/sessions/:id
   * Gets single session detail.
   */
  async getSessionById(activeContext, sessionId) {
    this._validateRbac(activeContext, ['OWNER', 'MANAGER']);
    const { tenant_id, establishment_id } = activeContext;

    const query = `
      SELECT 
        s.*,
        uo.nombre AS opened_by_name,
        uo.email AS opened_by_email,
        uc.nombre AS closed_by_name,
        uc.email AS closed_by_email
      FROM saas_cash_sessions s
      LEFT JOIN memberships mo ON s.opened_by_membership_id = mo.id
      LEFT JOIN usuarios uo ON mo.user_id = uo.id
      LEFT JOIN memberships mc ON s.closed_by_membership_id = mc.id
      LEFT JOIN usuarios uc ON mc.user_id = uc.id
      WHERE s.id = $1 AND s.tenant_id = $2;
    `;

    const { rows } = await pool.query(query, [sessionId, tenant_id]);

    if (rows.length === 0) {
      const err = new Error('Sesión de caja no encontrada.');
      err.statusCode = 404;
      err.code = 'CASH_SESSION_NOT_FOUND';
      throw err;
    }

    const session = rows[0];
    if (session.establishment_id !== establishment_id) {
      const err = new Error('Acceso denegado a sesión de otro establecimiento.');
      err.statusCode = 403;
      err.code = 'FORBIDDEN_CROSS_ESTABLISHMENT';
      throw err;
    }

    return {
      success: true,
      session: {
        id: session.id,
        establishment_id: session.establishment_id,
        status: session.status,
        opened_at: session.opened_at,
        closed_at: session.closed_at,
        opening_balance: parseFloat(session.opening_balance),
        expected_cash: session.expected_cash !== null ? parseFloat(session.expected_cash) : null,
        counted_cash: session.counted_cash !== null ? parseFloat(session.counted_cash) : null,
        difference: session.difference !== null ? parseFloat(session.difference) : null,
        closing_notes: session.closing_notes,
        opened_by: {
          membership_id: session.opened_by_membership_id,
          name: session.opened_by_name,
          email: session.opened_by_email
        },
        closed_by: session.closed_by_membership_id ? {
          membership_id: session.closed_by_membership_id,
          name: session.closed_by_name,
          email: session.closed_by_email
        } : null
      }
    };
  }
}

module.exports = new SaasCashService();
