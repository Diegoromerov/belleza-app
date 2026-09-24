// backend/tests/test_cash_drawer_suite.js
const assert = require('assert');
const saasCashService = require('../src/services/saasCashService');
const saasCashController = require('../src/controllers/saasCashController');
const { pool } = require('../src/config/db');

/**
 * CASH DRAWER / CAJA DOMAIN COMPREHENSIVE TEST SUITE (GO-08.49)
 * Tests all 25 contractual scenarios covering:
 * - Session opening & Anti-Double Opening
 * - Manual movements (CASH_IN / CASH_OUT) & Balance checks
 * - Ticket cash sale imputation & Idempotency
 * - Blind Close for Receptionist vs Owner/Manager visibility
 * - Reconciliation formulas (Balanced, Surplus, Shortage)
 * - RBAC permissions & Cross-establishment / Multi-tenant isolation
 */

function createMockReqRes(options = {}) {
  const activeContext = options.activeContext || {
    tenant_id: options.tenantId || 2,
    establishment_id: options.establishmentId || '11111111-1111-1111-1111-111111111111',
    membership_id: options.membershipId || '22222222-2222-2222-2222-222222222222',
    role: options.role || 'OWNER',
    user_id: options.userId || 1,
  };

  const req = {
    user: options.user !== undefined ? options.user : { id: 1, email: 'owner@test.com' },
    headers: options.headers || {},
    body: options.body || {},
    query: options.query || {},
    params: options.params || {},
    tenantId: activeContext.tenant_id,
    establishmentId: activeContext.establishment_id,
    membershipId: activeContext.membership_id,
    activeContext: activeContext,
    ...options.extraReq,
  };

  let statusCode = 200;
  let jsonBody = null;

  const res = {
    status(code) {
      statusCode = code;
      return this;
    },
    json(data) {
      jsonBody = data;
      return this;
    },
    getStatusCode() {
      return statusCode;
    },
    getBody() {
      return jsonBody;
    },
  };

  return { req, res };
}

// In-Memory Test Store to guarantee self-contained execution
class InMemoryCashDb {
  constructor() {
    this.sessions = [];
    this.movements = [];
    this.users = [
      { id: 1, nombre: 'Ana Propietaria', email: 'owner@test.com' },
      { id: 2, nombre: 'Carlos Manager', email: 'manager@test.com' },
      { id: 3, nombre: 'Beatriz Recepción', email: 'recep@test.com' },
      { id: 4, nombre: 'Pedro Estilista', email: 'prof@test.com' }
    ];
    this.memberships = [
      { id: '22222222-2222-2222-2222-222222222222', user_id: 1, establishment_id: '11111111-1111-1111-1111-111111111111', tenant_id: 2, role: 'OWNER' },
      { id: '33333333-3333-3333-3333-333333333333', user_id: 2, establishment_id: '11111111-1111-1111-1111-111111111111', tenant_id: 2, role: 'MANAGER' },
      { id: '44444444-4444-4444-4444-444444444444', user_id: 3, establishment_id: '11111111-1111-1111-1111-111111111111', tenant_id: 2, role: 'RECEPTIONIST' },
      { id: '55555555-5555-5555-5555-555555555555', user_id: 4, establishment_id: '11111111-1111-1111-1111-111111111111', tenant_id: 2, role: 'PROFESSIONAL' },
      { id: '99999999-9999-9999-9999-999999999999', user_id: 1, establishment_id: '88888888-8888-8888-8888-888888888888', tenant_id: 2, role: 'OWNER' }
    ];
  }

  async mockQuery(text, params = []) {
    const trimmed = text.trim();

    // 1. SELECT current OPEN session
    if (trimmed.includes('FROM saas_cash_sessions s') && trimmed.includes("s.status = 'OPEN'")) {
      const estId = params[0];
      const tenantId = params[1];
      const open = this.sessions.find(s => s.establishment_id === estId && s.tenant_id === tenantId && s.status === 'OPEN');
      if (!open) return { rows: [] };
      const user = this.users.find(u => u.id === (open.opened_by_user_id || 1)) || { nombre: 'Operador', email: 'op@test.com' };
      return {
        rows: [{
          ...open,
          opened_by_name: user.nombre,
          opened_by_email: user.email
        }]
      };
    }

    // 2. SUM metrics for session
    if (trimmed.includes('FROM saas_cash_movements') && trimmed.includes('WHERE session_id = $1')) {
      const sessionId = params[0];
      const tenantId = params[1];
      const sessionMovements = this.movements.filter(m => m.session_id === sessionId && m.tenant_id === tenantId);
      let sales = 0, cashIn = 0, cashOut = 0;
      sessionMovements.forEach(m => {
        if (m.movement_type === 'CASH_SALE') sales += parseFloat(m.amount);
        if (m.movement_type === 'CASH_IN') cashIn += parseFloat(m.amount);
        if (m.movement_type === 'CASH_OUT') cashOut += parseFloat(m.amount);
      });
      return {
        rows: [{
          cash_sales_total: sales,
          cash_in_total: cashIn,
          cash_out_total: cashOut,
          sales,
          cash_in: cashIn,
          cash_out: cashOut,
          movements_count: sessionMovements.length
        }]
      };
    }

    // 3. Check OPEN session (id, opening_balance)
    if (trimmed.includes('SELECT id, opening_balance FROM saas_cash_sessions') || trimmed.includes('SELECT id FROM saas_cash_sessions')) {
      const estId = params[0];
      const tenantId = params[1];
      const open = this.sessions.find(s => s.establishment_id === estId && s.tenant_id === tenantId && s.status === 'OPEN');
      return { rows: open ? [open] : [] };
    }

    // 4. INSERT INTO saas_cash_sessions
    if (trimmed.startsWith('INSERT INTO saas_cash_sessions')) {
      const [tenant_id, establishment_id, opened_by_membership_id, opening_balance, closing_notes] = params;
      // Enforce unique partial index: only 1 OPEN session per establishment
      const existingOpen = this.sessions.find(s => s.establishment_id === establishment_id && s.tenant_id === tenant_id && s.status === 'OPEN');
      if (existingOpen) {
        const err = new Error('duplicate key value violates unique constraint "idx_unique_open_cash_session_per_est"');
        err.code = '23505';
        throw err;
      }
      const newSession = {
        id: 'sess-' + Math.random().toString(36).substring(2, 10),
        tenant_id,
        establishment_id,
        opened_by_membership_id,
        opening_balance: parseFloat(opening_balance),
        closing_notes,
        status: 'OPEN',
        opened_at: new Date().toISOString(),
        created_at: new Date().toISOString()
      };
      this.sessions.push(newSession);
      return { rows: [newSession] };
    }

    // 5. INSERT INTO saas_cash_movements
    if (trimmed.startsWith('INSERT INTO saas_cash_movements')) {
      let session_id, tenant_id, establishment_id, movement_type, category, amount, reason, performed_by_membership_id, ticket_payment_id;
      if (params.length === 8) {
        [session_id, tenant_id, establishment_id, movement_type, category, amount, reason, performed_by_membership_id] = params;
      } else {
        [session_id, tenant_id, establishment_id, amount, reason, performed_by_membership_id, ticket_payment_id] = params;
        movement_type = 'CASH_SALE';
        category = 'TICKET_PAYMENT';
      }

      // Check unique index on ticket_payment_id
      if (ticket_payment_id) {
        const dup = this.movements.find(m => m.ticket_payment_id === ticket_payment_id);
        if (dup) {
          // ON CONFLICT DO NOTHING
          return { rows: [] };
        }
      }

      const newMovement = {
        id: 'mov-' + Math.random().toString(36).substring(2, 10),
        session_id,
        tenant_id,
        establishment_id,
        movement_type,
        category,
        amount: parseFloat(amount),
        reason,
        performed_by_membership_id,
        ticket_payment_id: ticket_payment_id || null,
        created_at: new Date().toISOString()
      };
      this.movements.push(newMovement);
      return { rows: [newMovement] };
    }

    // 6. SELECT FOR UPDATE in closeSession
    if (trimmed.includes('SELECT * FROM saas_cash_sessions') && trimmed.includes('FOR UPDATE')) {
      const estId = params[0];
      const tenantId = params[1];
      const open = this.sessions.find(s => s.establishment_id === estId && s.tenant_id === tenantId && s.status === 'OPEN');
      return { rows: open ? [open] : [] };
    }

    // 7. UPDATE saas_cash_sessions (close)
    if (trimmed.startsWith('UPDATE saas_cash_sessions')) {
      const [closed_by_membership_id, expected_cash, counted_cash, difference, closing_notes, id, tenant_id] = params;
      const session = this.sessions.find(s => s.id === id && s.tenant_id === tenant_id);
      if (session) {
        session.status = 'CLOSED';
        session.closed_by_membership_id = closed_by_membership_id;
        session.closed_at = new Date().toISOString();
        session.expected_cash = parseFloat(expected_cash);
        session.counted_cash = parseFloat(counted_cash);
        session.difference = parseFloat(difference);
        session.closing_notes = closing_notes;
        return { rows: [session] };
      }
      return { rows: [] };
    }

    // 8. SELECT session by ID (simple check)
    if (trimmed.includes('SELECT id, establishment_id, tenant_id FROM saas_cash_sessions WHERE id = $1')) {
      const id = params[0];
      const tenantId = params[1];
      const session = this.sessions.find(s => s.id === id && s.tenant_id === tenantId);
      return { rows: session ? [session] : [] };
    }

    // 9. List movements for session
    if (trimmed.includes('FROM saas_cash_movements m') && trimmed.includes('WHERE m.session_id = $1')) {
      const sessionId = params[0];
      const tenantId = params[1];
      const movs = this.movements
        .filter(m => m.session_id === sessionId && m.tenant_id === tenantId)
        .map(m => ({
          ...m,
          performed_by_name: 'Operador',
          performed_by_email: 'op@test.com'
        }));
      return { rows: movs };
    }

    // 10. History count query
    if (trimmed.includes('COUNT(*)') && trimmed.includes('saas_cash_sessions')) {
      const estId = params[0];
      const tenantId = params[1];
      const closed = this.sessions.filter(s => s.establishment_id === estId && s.tenant_id === tenantId && s.status === 'CLOSED');
      return { rows: [{ total: closed.length }] };
    }

    // 11. History list query
    if (trimmed.includes('FROM saas_cash_sessions s') && trimmed.includes("status = 'CLOSED'")) {
      const estId = params[0];
      const tenantId = params[1];
      const closed = this.sessions.filter(s => s.establishment_id === estId && s.tenant_id === tenantId && s.status === 'CLOSED');
      return {
        rows: closed.map(s => ({
          ...s,
          opened_by_name: 'Operador',
          closed_by_name: 'Operador'
        }))
      };
    }

    // 12. Single session getSessionById detail
    if (trimmed.includes('FROM saas_cash_sessions s') && trimmed.includes('WHERE s.id = $1 AND s.tenant_id = $2')) {
      const id = params[0];
      const tenantId = params[1];
      const s = this.sessions.find(sess => sess.id === id && sess.tenant_id === tenantId);
      if (!s) return { rows: [] };
      return {
        rows: [{
          ...s,
          opened_by_name: 'Operador',
          opened_by_email: 'op@test.com',
          closed_by_name: s.closed_by_membership_id ? 'Operador' : null,
          closed_by_email: s.closed_by_membership_id ? 'op@test.com' : null
        }]
      };
    }

    return { rows: [] };
  }
}

async function runCashDrawerSuite() {
  console.log('================================================================================');
  console.log('       CASH DRAWER / CAJA DOMAIN — COMPREHENSIVE TEST SUITE (GO-08.49)');
  console.log('================================================================================\n');

  let passed = 0;
  let failed = 0;

  async function test(name, fn) {
    try {
      await fn();
      console.log(`  ✓ PASS: ${name}`);
      passed++;
    } catch (err) {
      console.error(`  ✗ FAIL: ${name}`);
      console.error(`    Error: ${err.message}`);
      if (err.stack) {
        console.error(err.stack.split('\n').slice(1, 4).join('\n'));
      }
      failed++;
    }
  }

  // Setup In-Memory / Mock database for deterministic unit testing
  const mockDb = new InMemoryCashDb();
  const origQuery = pool.query;
  const origConnect = pool.connect;

  pool.query = async (text, params) => mockDb.mockQuery(text, params);
  pool.connect = async () => ({
    query: async (text, params) => mockDb.mockQuery(text, params),
    release: () => {}
  });

  const tenantId = 2;
  const estA_id = '11111111-1111-1111-1111-111111111111';
  const estB_id = '88888888-8888-8888-8888-888888888888';

  const ownerContext = {
    tenant_id: tenantId,
    establishment_id: estA_id,
    membership_id: '22222222-2222-2222-2222-222222222222',
    role: 'OWNER',
    user_id: 1
  };

  const managerContext = {
    tenant_id: tenantId,
    establishment_id: estA_id,
    membership_id: '33333333-3333-3333-3333-333333333333',
    role: 'MANAGER',
    user_id: 2
  };

  const receptionistContext = {
    tenant_id: tenantId,
    establishment_id: estA_id,
    membership_id: '44444444-4444-4444-4444-444444444444',
    role: 'RECEPTIONIST',
    user_id: 3
  };

  const professionalContext = {
    tenant_id: tenantId,
    establishment_id: estA_id,
    membership_id: '55555555-5555-5555-5555-555555555555',
    role: 'PROFESSIONAL',
    user_id: 4
  };

  const estB_OwnerContext = {
    tenant_id: tenantId,
    establishment_id: estB_id,
    membership_id: '99999999-9999-9999-9999-999999999999',
    role: 'OWNER',
    user_id: 1
  };

  // 1. Initial State: No open session
  await test('1. GET /api/saas/cash/current returns is_open: false when no session is open', async () => {
    const { req, res } = createMockReqRes({ activeContext: ownerContext });
    await saasCashController.getCurrentSession(req, res);
    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert.strictEqual(body.is_open, false);
    assert.strictEqual(body.session, null);
  });

  // 2. Reject Open with negative opening balance
  await test('2. POST /api/saas/cash/open rejects negative opening balance (400)', async () => {
    const { req, res } = createMockReqRes({
      activeContext: ownerContext,
      body: { opening_balance: -50000, notes: 'Invalid base' }
    });
    await saasCashController.openSession(req, res);
    assert.strictEqual(res.getStatusCode(), 400);
    assert.strictEqual(res.getBody().code, 'INVALID_OPENING_BALANCE');
  });

  // 3. Reject Open for PROFESSIONAL role (RBAC)
  await test('3. POST /api/saas/cash/open rejects PROFESSIONAL role (403)', async () => {
    const { req, res } = createMockReqRes({
      activeContext: professionalContext,
      body: { opening_balance: 100000 }
    });
    await saasCashController.openSession(req, res);
    assert.strictEqual(res.getStatusCode(), 403);
    assert.strictEqual(res.getBody().code, 'FORBIDDEN_ROLE');
  });

  // 4. Open session successfully by Receptionist
  let openSessionId = null;
  await test('4. POST /api/saas/cash/open opens a session with opening_balance = 150000', async () => {
    const { req, res } = createMockReqRes({
      activeContext: receptionistContext,
      body: { opening_balance: 150000, notes: 'Base inicial billetes de baja denominación' }
    });
    await saasCashController.openSession(req, res);
    assert.strictEqual(res.getStatusCode(), 201);
    const body = res.getBody();
    assert.strictEqual(body.success, true);
    assert.strictEqual(body.session.status, 'OPEN');
    assert.strictEqual(body.session.opening_balance, 150000);
    openSessionId = body.session.id;
  });

  // 5. Anti-Double Opening: Reject 2nd open in same establishment
  await test('5. POST /api/saas/cash/open rejects 2nd open session in same establishment (409)', async () => {
    const { req, res } = createMockReqRes({
      activeContext: ownerContext,
      body: { opening_balance: 200000 }
    });
    await saasCashController.openSession(req, res);
    assert.strictEqual(res.getStatusCode(), 409);
    assert.strictEqual(res.getBody().code, 'CASH_SESSION_ALREADY_OPEN');
  });

  // 6. Blind Close Verification: RECEPTIONIST does NOT see expected_cash
  await test('6. GET /api/saas/cash/current as RECEPTIONIST hides expected_cash (Blind Close)', async () => {
    const { req, res } = createMockReqRes({ activeContext: receptionistContext });
    await saasCashController.getCurrentSession(req, res);
    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert.strictEqual(body.is_open, true);
    assert.strictEqual(body.session.metrics.expected_cash, null, 'RECEPTIONIST expected_cash must be null');
  });

  // 7. Owner/Manager live audit: OWNER sees expected_cash
  await test('7. GET /api/saas/cash/current as OWNER reveals expected_cash in real time', async () => {
    const { req, res } = createMockReqRes({ activeContext: ownerContext });
    await saasCashController.getCurrentSession(req, res);
    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert.strictEqual(body.is_open, true);
    assert.strictEqual(body.session.metrics.expected_cash, 150000);
  });

  // 8. Manual Movement: CASH_IN (Base Adicional)
  await test('8. POST /api/saas/cash/movements records CASH_IN ($50.000)', async () => {
    const { req, res } = createMockReqRes({
      activeContext: receptionistContext,
      body: {
        movement_type: 'CASH_IN',
        category: 'BASE_ADICIONAL',
        amount: 50000,
        reason: 'Sencillo adicional traído de caja principal'
      }
    });
    await saasCashController.recordManualMovement(req, res);
    assert.strictEqual(res.getStatusCode(), 201);
    const body = res.getBody();
    assert.strictEqual(body.success, true);
    assert.strictEqual(body.movement.amount, 50000);
    assert.strictEqual(body.movement.movement_type, 'CASH_IN');
  });

  // 9. Manual Movement: CASH_OUT (Gasto Menor)
  await test('9. POST /api/saas/cash/movements records CASH_OUT ($20.000)', async () => {
    const { req, res } = createMockReqRes({
      activeContext: receptionistContext,
      body: {
        movement_type: 'CASH_OUT',
        category: 'GASTO_MENOR',
        amount: 20000,
        reason: 'Compra de insumos de cafetería'
      }
    });
    await saasCashController.recordManualMovement(req, res);
    assert.strictEqual(res.getStatusCode(), 201);
    const body = res.getBody();
    assert.strictEqual(body.success, true);
    assert.strictEqual(body.movement.amount, 20000);
    assert.strictEqual(body.movement.movement_type, 'CASH_OUT');
  });

  // 10. Reject CASH_OUT exceeding available drawer funds
  await test('10. POST /api/saas/cash/movements rejects CASH_OUT exceeding drawer funds (422)', async () => {
    // Current available: 150000 + 50000 - 20000 = 180000
    const { req, res } = createMockReqRes({
      activeContext: receptionistContext,
      body: {
        movement_type: 'CASH_OUT',
        category: 'RETIRO_BANCO',
        amount: 300000,
        reason: 'Retiro mayor al efectivo en gaveta'
      }
    });
    await saasCashController.recordManualMovement(req, res);
    assert.strictEqual(res.getStatusCode(), 422);
    assert.strictEqual(res.getBody().code, 'INSUFFICIENT_CASH_IN_DRAWER');
  });

  // 11. Reject movement with invalid type
  await test('11. POST /api/saas/cash/movements rejects invalid movement type (400)', async () => {
    const { req, res } = createMockReqRes({
      activeContext: receptionistContext,
      body: {
        movement_type: 'INVALID_TYPE',
        amount: 10000,
        reason: 'Prueba inválida'
      }
    });
    await saasCashController.recordManualMovement(req, res);
    assert.strictEqual(res.getStatusCode(), 400);
    assert.strictEqual(res.getBody().code, 'INVALID_MOVEMENT_TYPE');
  });

  // 12. Reject movement with empty reason
  await test('12. POST /api/saas/cash/movements rejects empty reason (400)', async () => {
    const { req, res } = createMockReqRes({
      activeContext: receptionistContext,
      body: {
        movement_type: 'CASH_IN',
        amount: 10000,
        reason: '   '
      }
    });
    await saasCashController.recordManualMovement(req, res);
    assert.strictEqual(res.getStatusCode(), 400);
    assert.strictEqual(res.getBody().code, 'REASON_REQUIRED');
  });

  // 13. Record Cash Sale (Ticket Payment Integration)
  const ticketPaymentId = 'pay-' + Math.random().toString(36).substring(2, 8);
  await test('13. recordCashSale creates CASH_SALE movement linked to ticket_payment_id', async () => {
    const result = await saasCashService.recordCashSale(receptionistContext, {
      ticketPaymentId,
      ticketId: 'tkt-001',
      amount: 120000,
      performedByMembershipId: receptionistContext.membership_id
    });
    assert.strictEqual(result.success, true);
    assert.ok(result.movement);
    assert.strictEqual(result.movement.movement_type, 'CASH_SALE');
    assert.strictEqual(result.movement.amount, 120000);
    assert.strictEqual(result.movement.ticket_payment_id, ticketPaymentId);
  });

  // 14. Idempotency: Duplicate Cash Sale payment ignored
  await test('14. recordCashSale ignores duplicate payment (ON CONFLICT DO NOTHING)', async () => {
    const result = await saasCashService.recordCashSale(receptionistContext, {
      ticketPaymentId,
      ticketId: 'tkt-001',
      amount: 120000,
      performedByMembershipId: receptionistContext.membership_id
    });
    assert.strictEqual(result.success, true);
    assert.strictEqual(result.movement, null, 'Duplicate ticket payment movement must be ignored');
  });

  // 15. Verify Cumulative Balance Calculation
  // Expected = 150000 (Base) + 50000 (In) - 20000 (Out) + 120000 (Sale) = 300000
  await test('15. Expected cash calculated exactly: 150.000 + 50.000 - 20.000 + 120.000 = 300.000', async () => {
    const { req, res } = createMockReqRes({ activeContext: ownerContext });
    await saasCashController.getCurrentSession(req, res);
    const body = res.getBody();
    assert.strictEqual(body.session.metrics.expected_cash, 300000);
    assert.strictEqual(body.session.metrics.cash_sales_total, 120000);
    assert.strictEqual(body.session.metrics.cash_in_total, 50000);
    assert.strictEqual(body.session.metrics.cash_out_total, 20000);
    assert.strictEqual(body.session.metrics.movements_count, 3);
  });

  // 16. List movements for session
  await test('16. GET /api/saas/cash/sessions/:id/movements returns all 3 atomic movements', async () => {
    const { req, res } = createMockReqRes({
      activeContext: ownerContext,
      params: { id: openSessionId }
    });
    await saasCashController.listMovements(req, res);
    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert.strictEqual(body.count, 3);
    assert.strictEqual(body.movements.length, 3);
  });

  // 17. Reject Close with negative counted cash
  await test('17. POST /api/saas/cash/close rejects negative counted cash (400)', async () => {
    const { req, res } = createMockReqRes({
      activeContext: receptionistContext,
      body: { counted_cash: -1000, closing_notes: 'Negative' }
    });
    await saasCashController.closeSession(req, res);
    assert.strictEqual(res.getStatusCode(), 400);
    assert.strictEqual(res.getBody().code, 'INVALID_COUNTED_AMOUNT');
  });

  // 18. Close Session with Surplus (Counted 305.000 > Expected 300.000 -> Diff +5.000 SURPLUS)
  await test('18. POST /api/saas/cash/close with Counted > Expected computes SURPLUS', async () => {
    const { req, res } = createMockReqRes({
      activeContext: receptionistContext,
      body: {
        counted_cash: 305000,
        closing_notes: 'Cierre turno tarde con sobrante de $5.000'
      }
    });
    await saasCashController.closeSession(req, res);
    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert.strictEqual(body.success, true);
    assert.strictEqual(body.session.status, 'CLOSED');
    assert.strictEqual(body.session.expected_cash, 300000);
    assert.strictEqual(body.session.counted_cash, 305000);
    assert.strictEqual(body.session.difference, 5000);
    assert.strictEqual(body.session.reconciliation_status, 'SURPLUS');
  });

  // 19. Reject movements on closed session
  await test('19. POST /api/saas/cash/movements rejected when session is CLOSED (422)', async () => {
    const { req, res } = createMockReqRes({
      activeContext: receptionistContext,
      body: { movement_type: 'CASH_IN', amount: 10000, reason: 'Intento post-cierre' }
    });
    await saasCashController.recordManualMovement(req, res);
    assert.strictEqual(res.getStatusCode(), 422);
    assert.strictEqual(res.getBody().code, 'CASH_DRAWER_NOT_OPEN');
  });

  // 20. Reject 2nd close on already closed session
  await test('20. POST /api/saas/cash/close rejected when already CLOSED (422)', async () => {
    const { req, res } = createMockReqRes({
      activeContext: receptionistContext,
      body: { counted_cash: 300000 }
    });
    await saasCashController.closeSession(req, res);
    assert.strictEqual(res.getStatusCode(), 422);
    assert.strictEqual(res.getBody().code, 'CASH_DRAWER_NOT_OPEN');
  });

  // 21. Open new session and test BALANCED reconciliation (Difference = 0.00)
  await test('21. New Session closed with exact count produces BALANCED status', async () => {
    // Open session with 100.000
    await saasCashService.openSession(managerContext, { opening_balance: 100000 });
    // Close with exactly 100.000
    const closeRes = await saasCashService.closeSession(managerContext, {
      counted_cash: 100000,
      closing_notes: 'Cuadre perfecto'
    });
    assert.strictEqual(closeRes.session.status, 'CLOSED');
    assert.strictEqual(closeRes.session.difference, 0);
    assert.strictEqual(closeRes.session.reconciliation_status, 'BALANCED');
  });

  // 22. Open new session and test SHORTAGE reconciliation (Difference < 0)
  await test('22. New Session closed with count < expected produces SHORTAGE status', async () => {
    // Open session with 200.000
    await saasCashService.openSession(ownerContext, { opening_balance: 200000 });
    // Close with 190.000 (Faltante 10.000)
    const closeRes = await saasCashService.closeSession(ownerContext, {
      counted_cash: 190000,
      closing_notes: 'Faltante de 10.000 por registrar'
    });
    assert.strictEqual(closeRes.session.status, 'CLOSED');
    assert.strictEqual(closeRes.session.difference, -10000);
    assert.strictEqual(closeRes.session.reconciliation_status, 'SHORTAGE');
  });

  // 23. History listing for OWNER/MANAGER
  await test('23. GET /api/saas/cash/history lists closed sessions with pagination', async () => {
    const { req, res } = createMockReqRes({
      activeContext: ownerContext,
      query: { page: 1, limit: 10 }
    });
    await saasCashController.getSessionHistory(req, res);
    assert.strictEqual(res.getStatusCode(), 200);
    const body = res.getBody();
    assert.strictEqual(body.success, true);
    assert.strictEqual(body.sessions.length, 3);
    assert.strictEqual(body.total, 3);
  });

  // 24. History listing forbidden for RECEPTIONIST (RBAC)
  await test('24. GET /api/saas/cash/history forbidden for RECEPTIONIST (403)', async () => {
    const { req, res } = createMockReqRes({ activeContext: receptionistContext });
    await saasCashController.getSessionHistory(req, res);
    assert.strictEqual(res.getStatusCode(), 403);
    assert.strictEqual(res.getBody().code, 'FORBIDDEN_ROLE');
  });

  // 25. Cross-establishment isolation
  await test('25. Cross-establishment isolation: Establishment B cannot access Establishment A session', async () => {
    const { req, res } = createMockReqRes({
      activeContext: estB_OwnerContext,
      params: { id: openSessionId }
    });
    await saasCashController.getSessionById(req, res);
    assert.strictEqual(res.getStatusCode(), 403);
    assert.strictEqual(res.getBody().code, 'FORBIDDEN_CROSS_ESTABLISHMENT');
  });

  // Restore pool
  pool.query = origQuery;
  pool.connect = origConnect;

  console.log('\n================================================================================');
  console.log(`RESULTS: ${passed} PASSED | ${failed} FAILED | TOTAL: ${passed + failed}`);
  console.log('================================================================================\n');

  if (failed > 0) {
    process.exit(1);
  }
}

if (require.main === module) {
  runCashDrawerSuite()
    .then(() => {
      console.log('✅ Cash Drawer Comprehensive Test Suite completed successfully.');
      process.exit(0);
    })
    .catch(err => {
      console.error('💥 Fatal error running test suite:', err);
      process.exit(1);
    });
}

module.exports = { runCashDrawerSuite };
