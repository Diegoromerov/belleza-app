# Wompi Full Integration — Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Replace all simulated Wompi payments/payouts with real Wompi Colombia integration (checkout widget, transaction creation, webhook handling, payouts) and remove simulation code paths.

**Architecture:** 
- Frontend: Integrate Wompi.js checkout widget (WebView/JS bridge) to tokenize payment methods → obtain `payment_source_id` + `acceptance_token` → send to backend
- Backend: `POST /api/bookings/:id/pay` creates real transaction at `api.wompi.co/v1/transactions`; webhook confirms payment; `wompiService.crearPayout()` calls `api.wompi.co/v1/payouts` for provider withdrawals
- Config: Add `WOMPI_PRIVATE_KEY`, `WOMPI_PUBLIC_KEY`, `WOMPI_EVENTS_SECRET`, `WOMPI_INTEGRITY_SECRET` (sandbox → production)

**Tech Stack:** Flutter Web (WebView/JS interop), Node/Express backend, Wompi REST API (sandbox: `https://sandbox.wompi.co/v1`, prod: `https://production.wompi.co/v1`)

---

## Phase 0 — Preparation & Contract

### Task 0.1: Audit current simulation surface (read-only)

**Objective:** Confirm every simulation entry point and data flow before removing any code.

**Files to read:**
- `frontend/lib/widgets/wompi_payment_sheet.dart:116-132` (STORE_ fake payment)
- `frontend/lib/widgets/wompi_payment_sheet.dart:594-730` (PAN/CVV forms)
- `frontend/lib/services/api_service.dart:516-529` (payBooking call)
- `backend/src/controllers/bookingController.js:550-700` (payBooking simulator)
- `backend/src/services/wompiService.js:49-165` (payout simulators)
- `backend/src/routes/paymentRoutes.js:706-857` (withdraw → crearPayout)

**Verification:** grep for `simuladorPermitido`, `rechazarSimulacion`, `STORE_`, `simdev_`, `Future.delayed` in payment contexts — count should drop to 0 after implementation.

---

## Phase 1 — Backend: Real Transaction Creation

### Task 1.1: Add Wompi HTTP client utility

**Objective:** Centralize Wompi API calls (auth, retries, error mapping).

**Files:**
- Create: `backend/src/services/wompiClient.js`
- Modify: `backend/src/services/wompiService.js` (import client)

**Step 1: Write failing test**
```javascript
// backend/src/tests/wompiClient.test.js
const wompiClient = require('../services/wompiClient');

test('createTransaction calls Wompi API with correct payload', async () => {
  const result = await wompiClient.createTransaction({
    amountInCents: 5000000,
    currency: 'COP',
    reference: 'booking-123',
    paymentSourceId: 'src_test_123',
    acceptanceToken: 'acceptance_test_456',
    customerEmail: 'user@test.com'
  });
  expect(result).toHaveProperty('id');
  expect(result.status).toBe('PENDING');
});
```

**Step 2: Run test to verify failure**
```bash
cd backend && npm test -- src/tests/wompiClient.test.js
# Expected: FAIL - wompiClient.createTransaction not defined
```

**Step 3: Write minimal implementation**
```javascript
// backend/src/services/wompiClient.js
const fetch = require('node-fetch');

const WOMPI_BASE = process.env.WOMPI_BASE_URL || 'https://sandbox.wompi.co/v1';
const PRIVATE_KEY = process.env.WOMPI_PRIVATE_KEY;

class WompiClient {
  constructor() {
    if (!PRIVATE_KEY) throw new Error('WOMPI_PRIVATE_KEY not configured');
  }

  async _request(method, path, body) {
    const res = await fetch(`${WOMPI_BASE}${path}`, {
      method,
      headers: {
        'Authorization': `Bearer ${PRIVATE_KEY}`,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: body ? JSON.stringify(body) : undefined
    });
    const data = await res.json();
    if (!res.ok) {
      const err = new Error(data.error?.message || `Wompi ${res.status}`);
      err.status = res.status;
      err.wompiError = data;
      throw err;
    }
    return data.data;
  }

  async createTransaction({ amountInCents, currency, reference, paymentSourceId, acceptanceToken, customerEmail }) {
    return this._request('POST', '/transactions', {
      amount_in_cents: amountInCents,
      currency,
      reference,
      payment_source_id: paymentSourceId,
      acceptance_token: acceptanceToken,
      customer_email: customerEmail,
      redirect_url: `${process.env.FRONTEND_URL}/payment/result`
    });
  }

  async createPayout({ amountInCents, currency, reference, bankAccountId }) {
    return this._request('POST', '/payouts', {
      amount_in_cents: amountInCents,
      currency,
      reference,
      bank_account_id: bankAccountId
    });
  }

  async getTransaction(id) {
    return this._request('GET', `/transactions/${id}`);
  }

  async getPayout(id) {
    return this._request('GET', `/payouts/${id}`);
  }
}

module.exports = new WompiClient();
```

**Step 4: Run test to verify pass**
```bash
cd backend && npm test -- src/tests/wompiClient.test.js
# Expected: PASS (with mocked fetch or sandbox credentials)
```

**Step 5: Commit**
```bash
git add backend/src/services/wompiClient.js backend/src/tests/wompiClient.test.js
git commit -m "feat(wompi): add Wompi HTTP client with createTransaction/createPayout"
```

---

### Task 1.2: Replace payBooking simulator with real Wompi transaction creation

**Objective:** `POST /api/bookings/:id/pay` creates real transaction in Wompi, returns `payment_source_id` requirement to frontend.

**Files:**
- Modify: `backend/src/controllers/bookingController.js:550-700` (payBooking)
- Modify: `backend/src/services/wompiService.js` (use wompiClient)

**Step 1: Write failing test**
```javascript
// backend/src/tests/payBookingReal.test.js
const request = require('supertest');
const express = require('express');
const bookingController = require('../controllers/bookingController');

test('payBooking returns 400 if payment_source_id missing', async () => {
  const app = express();
  app.use(express.json());
  app.post('/api/bookings/:id/pay', bookingController.payBooking);
  // ... setup auth mock, booking in PENDIENTE_PAGO
  const res = await request(app).post('/api/bookings/booking-123/pay').send({ payment_method: 'NEQUI' });
  expect(res.status).toBe(400);
  expect(res.body.error).toMatch(/payment_source_id/);
});

test('payBooking creates Wompi transaction and returns wompi transaction id', async () => {
  // ... mock wompiClient.createTransaction to return { id: 'tx_wompi_123', status: 'PENDING' }
  const res = await request(app).post('/api/bookings/booking-123/pay').send({ 
    payment_method: 'NEQUI',
    payment_source_id: 'src_test_123',
    acceptance_token: 'acceptance_test_456'
  });
  expect(res.status).toBe(200);
  expect(res.body.wompi_transaction_id).toBe('tx_wompi_123');
  expect(res.body.status).toBe('PENDING');
});
```

**Step 2: Run test to verify failure**
```bash
cd backend && npm test -- src/tests/payBookingReal.test.js
# Expected: FAIL - payBooking still returns simulated response
```

**Step 3: Write minimal implementation**
```javascript
// In bookingController.js payBooking function - REPLACE lines 550-700:
exports.payBooking = async (req, res) => {
  try {
    const bookingId = req.params.id;
    const clientId = req.user.id;
    const { payment_method, payment_source_id, acceptance_token } = req.body;

    // Validate required fields for real Wompi integration
    if (!payment_source_id || !acceptance_token) {
      return res.status(400).json({
        error: 'MISSING_PAYMENT_SOURCE',
        message: 'payment_source_id y acceptance_token son requeridos para cobro real con Wompi'
      });
    }

    const booking = await Booking.findOne({ where: { id: bookingId, client_id: clientId } });
    if (!booking) return res.status(404).json({ error: 'Cita no encontrada' });
    if (booking.estado !== 'PENDIENTE_PAGO') return res.status(400).json({ error: 'Estado inválido' });

    const amountInCents = Math.round(parseFloat(booking.valor_bruto) * 100);
    const wompiClient = require('../services/wompiClient');

    // Create real transaction in Wompi
    const wompiTx = await wompiClient.createTransaction({
      amountInCents,
      currency: 'COP',
      reference: bookingId,
      paymentSourceId: payment_source_id,
      acceptanceToken: acceptance_token,
      customerEmail: req.user.email
    });

    // Store pending transaction locally (idempotent by booking_id)
    const { Transaction } = require('../models');
    await Transaction.findOrCreate({
      where: { booking_id: bookingId },
      defaults: {
        amount: booking.valor_bruto,
        status: 'pending',
        payment_method: payment_method.toUpperCase(),
        external_id: wompiTx.id,
        wompi_status: wompiTx.status
      }
    });

    res.json({
      success: true,
      status: 'PENDING',
      wompi_transaction_id: wompiTx.id,
      wompi_status: wompiTx.status,
      message: 'Transacción creada en Wompi. Pendiente de confirmación por webhook.'
    });
  } catch (error) {
    console.error('❌ ERROR EN POST /api/bookings/:id/pay:', error);
    if (error.status === 400 && error.wompiError) {
      return res.status(400).json({ error: 'WOMPI_ERROR', detail: error.wompiError });
    }
    res.status(500).json({ error: 'Error interno al crear la transacción' });
  }
};
```

**Step 4: Run test to verify pass**
```bash
cd backend && npm test -- src/tests/payBookingReal.test.js
# Expected: PASS
```

**Step 5: Commit**
```bash
git add backend/src/controllers/bookingController.js backend/src/tests/payBookingReal.test.js
git commit -m "feat(wompi): payBooking creates real Wompi transaction, requires payment_source_id"
```

---

### Task 1.3: Verify webhook handles real Wompi transaction flow

**Objective:** Ensure existing webhook (`procesarWebhookWompi`) correctly processes real Wompi events (already validates HMAC, idempotency, amount).

**Files:**
- Read: `backend/src/controllers/bookingController.js:703-847` (already solid)
- Test: `backend/src/tests/wompiWebhookSecurity.test.js` (already comprehensive)

**Step 1: Write integration test with real Wompi event structure**
```javascript
// backend/src/tests/wompiWebhookRealEvent.test.js
test('webhook processes real Wompi transaction.updated APPROVED event', async () => {
  const payload = {
    event: 'transaction.updated',
    data: {
      transaction: {
        id: 'tx_wompi_real_123',
        reference: 'booking-456',
        status: 'APPROVED',
        amount_in_cents: 5000000,
        payment_method_type: 'NEQUI',
        payment_source_id: 'src_test_123'
      }
    }
  };
  // ... sign with verifyWompiSignature, POST to endpoint
  // Expect: booking CONFIRMADA, transaction status=paid, stock decremented
});
```

**Step 2: Run test**
```bash
cd backend && npm test -- src/tests/wompiWebhookRealEvent.test.js
# Expected: PASS (existing webhook logic should handle it)
```

**Step 3: Commit if changes needed**
```bash
git commit -m "test(wompi): verify webhook handles real APPROVED event"
```

---

## Phase 2 — Backend: Real Payouts (Provider Withdrawals)

### Task 2.1: Map provider bank accounts to Wompi bank_account_id

**Objective:** Providers must register bank accounts in Wompi first (or we create them via API). Store `wompi_bank_account_id` in `provider_wallet`.

**Files:**
- Modify: `backend/src/routes/paymentRoutes.js` (bank account registration → create in Wompi)
- Modify: `backend/config/db.js` or migration (add `wompi_bank_account_id` to `provider_wallet`)

**Step 1: Migration**
```sql
-- backend/migrations/XXX_add_wompi_bank_account_id.sql
ALTER TABLE provider_wallet ADD COLUMN wompi_bank_account_id VARCHAR(100);
```

**Step 2: Update bank account registration to create Wompi bank account**
```javascript
// In paymentRoutes.js handleSaveBankAccount - after saving locally:
const wompiClient = require('../services/wompiClient');
const wompiBankAccount = await wompiClient.createBankAccount({
  bank_code: bancoNormalizado, // map to Wompi bank codes
  account_type: tipoCuentaFinal === 'AHORROS' ? 'SAVINGS' : 'CHECKING',
  account_number: numero_cuenta.trim(),
  holder_name: titular_nombre,
  holder_type: 'PERSON',
  holder_id: titular_documento_num
});
await pool.query('UPDATE provider_wallet SET wompi_bank_account_id = $1 WHERE provider_id = $2', [wompiBankAccount.id, req.user.id]);
```

**Step 3: Test and commit**

---

### Task 2.2: Replace crearPayout simulator with real Wompi payout

**Objective:** `wompiService.crearPayout()` calls Wompi Payouts API, updates `retiros` with real `referencia_wompi`.

**Files:**
- Modify: `backend/src/services/wompiService.js:104-165` (crearPayout)
- Modify: `backend/src/routes/paymentRoutes.js:833-840` (call crearPayout)

**Step 1: Write failing test**
```javascript
// backend/src/tests/wompiPayoutReal.test.js
const wompiService = require('../services/wompiService');
const wompiClient = require('../services/wompiClient');

test('crearPayout calls Wompi payouts API and stores reference', async () => {
  jest.spyOn(wompiClient, 'createPayout').mockResolvedValue({ id: 'payout_wompi_789', status: 'PENDING' });
  
  await wompiService.crearPayout({
    retiroId: 'retiro-123',
    providerId: 'prov-456',
    amount: 100000,
    numeroCuenta: '3001234567',
    banco: 'NEQUI',
    automatico: false
  });
  
  expect(wompiClient.createPayout).toHaveBeenCalledWith(expect.objectContaining({
    amountInCents: 10000000,
    reference: expect.stringMatching(/^wompi_ret_/),
    bankAccountId: expect.any(String)
  }));
  
  // Verify retiros.estado = 'COMPLETADO' and referencia_wompi = 'payout_wompi_789'
});
```

**Step 2: Run test to verify failure**
```bash
cd backend && npm test -- src/tests/wompiPayoutReal.test.js
# Expected: FAIL - crearPayout still uses setTimeout simulator
```

**Step 3: Write minimal implementation**
```javascript
// wompiService.js - REPLACE crearPayout (lines 104-165):
exports.crearPayout = async ({ retiroId, providerId, amount, numeroCuenta, banco, automatico = false }) => {
  if (!simuladorPermitido()) rechazarSimulacion('retiro', retiroId);
  
  const wompiClient = require('./wompiClient');
  const { pool } = require('../config/db');
  
  try {
    console.log(`\n💸 [WOMPI PAYOUT REAL] Procesando dispersión de retiro (${automatico ? 'AUTOMÁTICO' : 'DEMANDA'}):`);
    console.log(`   - Retiro ID: ${retiroId}`);
    console.log(`   - Monto: $${amount} COP`);
    
    // Get provider's Wompi bank account ID
    const { rows } = await pool.query(
      'SELECT wompi_bank_account_id FROM provider_wallet WHERE provider_id = $1',
      [providerId]
    );
    if (!rows.length || !rows[0].wompi_bank_account_id) {
      throw new Error('Proveedor no tiene cuenta bancaria registrada en Wompi');
    }
    const bankAccountId = rows[0].wompi_bank_account_id;
    
    const amountInCents = Math.round(amount * 100);
    const referenceToken = generarReferenciaIdempotente('wompi_ret', retiroId, providerId, amount);
    
    // Real Wompi payout
    const wompiPayout = await wompiClient.createPayout({
      amountInCents,
      currency: 'COP',
      reference: referenceToken,
      bankAccountId
    });
    
    // Update retiro with real Wompi reference
    await pool.query(
      `UPDATE retiros SET estado = 'COMPLETADO', referencia_wompi = $2, procesado_at = NOW() WHERE id = $1`,
      [retiroId, wompiPayout.id]
    );
    
    // Ledger event
    await pool.query(
      `INSERT INTO wallet_ledger_events (tx_id, provider_id, evento, detalle)
       SELECT wt.id, wt.provider_id, 'RETIRO_COMPLETADO', jsonb_build_object('referencia_wompi', $2::text)
       FROM wallet_transactions wt
       WHERE wt.provider_id = $1 AND wt.tipo = 'DEBITO_RETIRO' AND (wt.metadata->>'retiro_id')::uuid = $3`,
      [providerId, wompiPayout.id, retiroId]
    );
    
    console.log(`✅ [WOMPI PAYOUT REAL] Retiro ${retiroId} dispersado. Ref Wompi: ${wompiPayout.id}`);
  } catch (err) {
    console.error(`❌ [WOMPI PAYOUT REAL ERROR] Fallo al dispersar retiro ${retiroId}:`, err.message);
    await pool.query(
      `UPDATE retiros SET estado = 'FALLIDO', error_wompi = $2, procesado_at = NOW() WHERE id = $1`,
      [retiroId, err.message]
    );
    // Ledger failed event
    await pool.query(
      `INSERT INTO wallet_ledger_events (tx_id, provider_id, evento, detalle)
       SELECT wt.id, wt.provider_id, 'RETIRO_FALLIDO', jsonb_build_object('error', $3::text)
       FROM wallet_transactions wt
       WHERE wt.provider_id = $1 AND wt.tipo = 'DEBITO_RETIRO' AND (wt.metadata->>'retiro_id')::uuid = $2`,
      [providerId, retiroId, err.message]
    );
    throw err; // Re-throw so caller can handle
  }
};
```

**Step 4: Run test to verify pass**
```bash
cd backend && npm test -- src/tests/wompiPayoutReal.test.js
# Expected: PASS
```

**Step 5: Commit**
```bash
git add backend/src/services/wompiService.js backend/src/tests/wompiPayoutReal.test.js
git commit -m "feat(wompi): crearPayout uses real Wompi Payouts API"
```

---

### Task 2.3: Add payout status reconciliation job

**Objective:** Periodic job to check pending payouts in Wompi and update local status (Wompi payouts are async).

**Files:**
- Create: `backend/src/jobs/payoutReconciliationJob.js`
- Modify: `backend/src/jobs/index.js` (register cron)

**Implementation:**
```javascript
// backend/src/jobs/payoutReconciliationJob.js
const { pool } = require('../config/db');
const wompiClient = require('../services/wompiClient');

async function reconcilePayouts() {
  const { rows } = await pool.query(
    `SELECT r.id, r.referencia_wompi, r.provider_id, r.monto
     FROM retiros r
     WHERE r.estado IN ('PROCESANDO', 'PENDIENTE') AND r.referencia_wompi IS NOT NULL`
  );
  
  for (const retiro of rows) {
    try {
      const wompiPayout = await wompiClient.getPayout(retiro.referencia_wompi);
      let newEstado = retiro.estado;
      if (wompiPayout.status === 'APPROVED' || wompiPayout.status === 'COMPLETED') newEstado = 'COMPLETADO';
      else if (wompiPayout.status === 'FAILED' || wompiPayout.status === 'REJECTED') newEstado = 'FALLIDO';
      
      if (newEstado !== retiro.estado) {
        await pool.query('UPDATE retiros SET estado = $1, procesado_at = NOW() WHERE id = $2', [newEstado, retiro.id]);
        // Ledger event...
      }
    } catch (err) {
      console.error(`Payout reconciliation failed for ${retiro.id}:`, err.message);
    }
  }
}

module.exports = { reconcilePayouts };
```

---

## Phase 3 — Frontend: Wompi Checkout Widget Integration

### Task 3.1: Add Wompi.js checkout widget via WebView/JS interop

**Objective:** Replace PAN/CVV forms with Wompi's secure checkout widget that returns `payment_source_id` + `acceptance_token`.

**Files:**
- Modify: `frontend/lib/widgets/wompi_payment_sheet.dart` (replace `_buildCardForm`, `_buildNequiForm`)
- Create: `frontend/lib/services/wompi_checkout_service.dart` (JS interop)
- Modify: `frontend/web/index.html` (load Wompi.js)

**Step 1: Add Wompi.js to web/index.html**
```html
<!-- frontend/web/index.html - in <head> -->
<script src="https://checkout.wompi.co/widget.js" data-public-key="YOUR_PUBLIC_KEY"></script>
```

**Step 2: Create Wompi checkout service (JS interop)**
```dart
// frontend/lib/services/wompi_checkout_service.dart
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';

class WompiCheckoutService {
  static bool get _isWeb => kIsWeb;
  
  /// Opens Wompi checkout widget and returns [paymentSourceId, acceptanceToken]
  static Future<({String paymentSourceId, String acceptanceToken})?> openCheckout({
    required int amountInCents,
    required String currency,
    required String reference,
    required String publicKey,
    String? acceptanceToken, // Pre-fetched acceptance token
  }) async {
    if (!_isWeb) throw UnsupportedError('Wompi widget only available on web');
    
    final completer = Completer<({String paymentSourceId, String acceptanceToken})>();
    
    // Call Wompi widget via JS interop
    final wompiCheckout = (globalThis as dynamic).WompiCheckout;
    if (wompiCheckout == null) {
      throw StateError('WompiCheckout not loaded. Check widget.js script.');
    }
    
    wompiCheckout.open({
      'publicKey': publicKey.toJS,
      'amountInCents': amountInCents.toJS,
      'currency': currency.toJS,
      'reference': reference.toJS,
      'acceptanceToken': (acceptanceToken ?? '').toJS,
      'onSuccess': (data) => completer.complete((
        paymentSourceId: (data['paymentSourceId'] as JSString).toDartString(),
        acceptanceToken: (data['acceptanceToken'] as JSString).toDartString(),
      )),
      'onError': (error) => completer.completeError(Exception('Wompi error: $error')),
      'onClose': () => completer.completeError(Exception('User closed checkout')),
    }.jsify());
    
    return completer.future;
  }
  
  /// Fetches acceptance token from Wompi (terms & conditions)
  static Future<String> fetchAcceptanceToken(String publicKey) async {
    if (!_isWeb) throw UnsupportedError('Only on web');
    // Call Wompi API to get acceptance token
    final response = await fetch('https://sandbox.wompi.co/v1/merchants/$publicKey'.toJS).toDart;
    final data = await response.json();
    return (data['data']['presigned_acceptance']['acceptance_token'] as JSString).toDartString();
  }
}
```

**Step 3: Update wompi_payment_sheet.dart to use widget**
```dart
// In _handlePayment() - REPLACE lines 117-176:
Future<void> _handlePayment() async {
  if (!_formKey.currentState!.validate()) return;
  
  if (widget.bookingId.trim().isEmpty) {
    // ... existing error for store purchases without gateway
    return;
  }
  
  setState(() { _isProcessing = true; _errorMsg = null; });
  
  try {
    final amountInCents = (_computedPrice * 100).round();
    final publicKey = const String.fromEnvironment('WOMPI_PUBLIC_KEY');
    if (publicKey.isEmpty) throw Exception('WOMPI_PUBLIC_KEY not configured');
    
    // Fetch acceptance token (cache it)
    String acceptanceToken = await WompiCheckoutService.fetchAcceptanceToken(publicKey);
    
    // Open Wompi widget
    final result = await WompiCheckoutService.openCheckout(
      amountInCents: amountInCents,
      currency: 'COP',
      reference: widget.bookingId,
      publicKey: publicKey,
      acceptanceToken: acceptanceToken,
    );
    
    if (result == null) throw Exception('Checkout cancelado');
    
    // Send payment_source_id + acceptance_token to backend
    final res = await ApiService.payBooking(
      widget.bookingId, 
      _selectedTab == 0 ? 'NEQUI' : 'CARD',
      paymentSourceId: result.paymentSourceId,
      acceptanceToken: result.acceptanceToken,
    );
    
    // ... existing success handling
  } catch (e) {
    // ... existing error handling
  }
}
```

**Step 4: Update ApiService.payBooking signature**
```dart
// frontend/lib/services/api_service.dart:516-529
static Future<Map<String, dynamic>> payBooking(
    String bookingId, String paymentMethod, {
    required String paymentSourceId,
    required String acceptanceToken,
  }) async {
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl$_apiPath/bookings/$bookingId/pay'),
      headers: headers,
      body: json.encode({
        'payment_method': paymentMethod,
        'payment_source_id': paymentSourceId,
        'acceptance_token': acceptanceToken,
      }),
    ).timeout(requestTimeout);
    return _decodeResponse(response);
  }
```

**Step 5: Remove PAN/CVV form code** (lines 634-730) — Nequi form for services shows info only (line 595-615), store purchases use widget.

**Step 6: Test and commit**
```bash
cd frontend && flutter test test/widgets/wompi_payment_sheet_test.dart
git add frontend/lib/widgets/wompi_payment_sheet.dart frontend/lib/services/wompi_checkout_service.dart frontend/lib/services/api_service.dart frontend/web/index.html
git commit -m "feat(wompi): integrate Wompi.js checkout widget, remove PAN/CVV forms"
```

---

### Task 3.2: Handle store purchases (GlowShop) — require real booking or redirect

**Objective:** `store_screen.dart` currently fabricates `STORE_` booking IDs. Either create real booking first or integrate store checkout with Wompi directly.

**Files:**
- Modify: `frontend/lib/screens/store_screen.dart:389-404`

**Implementation:** Create a real "store order" booking type or use Wompi widget with `reference: STORE_ORDER_<timestamp>` and handle in backend.

---

## Phase 4 — Configuration & Environment

### Task 4.1: Add Wompi environment variables

**Files:**
- `backend/.env.example` (document required vars)
- Railway/Production env vars

**Required variables:**
```bash
# Wompi credentials (sandbox for dev, production for prod)
WOMPI_PRIVATE_KEY=prv_test_xxx / prv_prod_xxx
WOMPI_PUBLIC_KEY=pub_test_xxx / pub_prod_xxx
WOMPI_EVENTS_SECRET=webhook_secret_from_wompi_dashboard
WOMPI_INTEGRITY_SECRET=integrity_secret_from_wompi_dashboard
WOMPI_BASE_URL=https://sandbox.wompi.co/v1  # or production.wompi.co/v1
FRONTEND_URL=https://glowapp-frontend.up.railway.app  # for redirect_url
```

### Task 4.2: Configure Wompi dashboard webhooks

**Manual step:** In Wompi dashboard (sandbox/production):
- Webhook URL: `https://belleza-app-production.up.railway.app/api/payments/wompi-webhook`
- Events: `transaction.updated`, `payout.updated`
- Secret: use `WOMPI_EVENTS_SECRET` value

---

## Phase 5 — Cleanup: Remove All Simulation Code

### Task 5.1: Remove simulator from payBooking

**Files:** `backend/src/controllers/bookingController.js` — delete lines 556-581 (production guard + simulator block)

### Task 5.2: Remove simulator from wompiService

**Files:** `backend/src/services/wompiService.js` — delete `simuladorPermitido()`, `rechazarSimulacion()`, `setTimeout` wrappers in `disbursePayout` and `crearPayout`

### Task 5.3: Remove fake payment branch in frontend

**Files:** `frontend/lib/widgets/wompi_payment_sheet.dart:116-132` (STORE_ fake payment block)

### Task 5.4: Remove PAN/CVV form code

**Files:** `frontend/lib/widgets/wompi_payment_sheet.dart:634-730` (_buildCardForm PAN/CVV fields)

### Task 5.5: Update tests to match real flow

**Files:** 
- `backend/src/tests/payment.test.js` — update to test real flow with mocked wompiClient
- `backend/src/tests/wompiService.test.js` — update for real payout calls

---

## Phase 6 — End-to-End Verification

### Task 6.1: Sandbox integration test (full flow)

**Script:** Create `scripts/test-wompi-full-flow.js` that:
1. Creates test booking via API
2. Opens Wompi widget (headless/puppeteer or manual)
3. Completes test payment with Wompi test cards
4. Verifies webhook receives APPROVED
5. Verifies booking CONFIRMADA, transaction paid
6. Requests provider withdrawal
7. Verifies payout created in Wompi sandbox
8. Runs reconciliation job

### Task 6.2: Production readiness checklist

- [ ] All `WOMPI_*` vars set in Railway production
- [ ] Webhook URL updated to production domain
- [ ] `WOMPI_BASE_URL` = `https://production.wompi.co/v1`
- [ ] PCI SAQ-A compliance (no PAN touches our servers) ✅ by design
- [ ] Error handling: declined cards, insufficient funds, network errors
- [ ] Idempotency: retry-safe on all endpoints
- [ ] Monitoring: alerts on webhook failures, payout failures

---

## Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| Wompi sandbox differs from production | High | Test full flow in sandbox first; keep feature flag for simulation during transition |
| Provider bank account mapping to Wompi bank codes | Medium | Build mapping table `banco` → Wompi `bank_code`; validate on registration |
| Webhook replay in multi-instance (nonce store in memory) | High | Move `wompiUsedNonces` to Redis (shared) before production |
| Frontend WebView/JS interop breaks on mobile web | Medium | Test on iOS Safari, Android Chrome; fallback to redirect checkout if needed |
| Payout async status (PENDING → APPROVED) | Medium | Reconciliation job runs every 5 min; UI shows "En proceso" until COMPLETADO |

---

## Acceptance Criteria (Gate)

**Gate 1 (Backend):** `POST /api/bookings/:id/pay` with valid `payment_source_id` + `acceptance_token` creates Wompi transaction → returns `wompi_transaction_id` + `status: PENDING`. Webhook `APPROVED` → booking `CONFIRMADA`, transaction `paid`, stock decremented.

**Gate 2 (Frontend):** Payment sheet opens Wompi widget, user pays with test card (4242 4242 4242 4242), receives success, booking confirmed. No PAN/CVV fields visible.

**Gate 3 (Payouts):** Provider requests withdrawal → `crearPayout` creates Wompi payout → `retiros.referencia_wompi` = Wompi payout ID → reconciliation job marks `COMPLETADO` when Wompi approves.

**Gate 4 (Cleanup):** Zero occurrences of `simuladorPermitido`, `rechazarSimulacion`, `STORE_`, `simdev_`, `Future.delayed` in payment code. `flutter analyze` clean. All tests pass.

---

## Execution Order

1. Phase 0 → 1.1 → 1.2 → 1.3 (Backend transaction creation)
2. Phase 2.1 → 2.2 → 2.3 (Backend payouts)
3. Phase 3.1 → 3.2 (Frontend widget)
4. Phase 4 (Config)
5. Phase 5 (Cleanup)
6. Phase 6 (E2E verification)

---

## Files Summary

| File | Change Type |
|------|-------------|
| `backend/src/services/wompiClient.js` | CREATE |
| `backend/src/controllers/bookingController.js` | MODIFY (payBooking) |
| `backend/src/services/wompiService.js` | MODIFY (crearPayout, disbursePayout) |
| `backend/src/routes/paymentRoutes.js` | MODIFY (bank account → Wompi bank_account) |
| `backend/migrations/XXX_add_wompi_bank_account_id.sql` | CREATE |
| `backend/src/jobs/payoutReconciliationJob.js` | CREATE |
| `frontend/lib/services/wompi_checkout_service.dart` | CREATE |
| `frontend/lib/widgets/wompi_payment_sheet.dart` | MODIFY (major: widget integration, remove PAN/CVV) |
| `frontend/lib/services/api_service.dart` | MODIFY (payBooking signature) |
| `frontend/web/index.html` | MODIFY (Wompi.js script) |
| `frontend/lib/screens/store_screen.dart` | MODIFY (real checkout) |
| `backend/.env.example` | MODIFY |
| Multiple test files | CREATE/MODIFY |