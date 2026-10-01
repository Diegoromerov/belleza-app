/**
 * backend/src/tests/wompiWebhookSecurity.test.js
 *
 * FASE C — Fix P0 DINERO #4 (t_fix_pagos_04)
 * Hallazgo: el webhook HMAC solo firmaba el payload, sin timestamp ni nonce,
 * lo que permitía un ataque de replay indefinido de un webhook válido capturado.
 *
 * Estos tests exigen, para aceptar un webhook:
 *   1) Firma HMAC que CUBRE timestamp + nonce + rawBody (bind criptográfico).
 *   2) Timestamp dentro de una ventana de tolerancia (rechaza antiguos y futuros).
 *   3) Nonce presente y de un solo uso (idempotencia anti-replay).
 */

const crypto = require('crypto');
const express = require('express');
const request = require('supertest');

const bookingController = require('../controllers/bookingController');

const SECRET = 'test_wompi_webhook_secret_key_12345';
const TOLERANCE_MS = 5 * 60 * 1000; // 5 minutos

function sign(secret, timestamp, nonce, rawBody) {
  return crypto
    .createHmac('sha256', secret)
    .update(`${timestamp}.${nonce}.${rawBody}`)
    .digest('hex');
}

function legacySign(secret, rawBody) {
  // Esquema VULNERABLE anterior: HMAC solo sobre el payload.
  return crypto.createHmac('sha256', secret).update(rawBody).digest('hex');
}

function buildReq({ body, timestamp, nonce, omit = [], signature }) {
  const rawBody = JSON.stringify(body);
  const headers = {};
  if (!omit.includes('signature')) {
    headers['x-wompi-signature'] =
      signature !== undefined ? signature : sign(SECRET, timestamp, nonce, rawBody);
  }
  if (!omit.includes('timestamp')) headers['x-wompi-timestamp'] = String(timestamp);
  if (!omit.includes('nonce')) headers['x-wompi-nonce'] = nonce;

  return {
    body,
    rawBody: Buffer.from(rawBody, 'utf8'),
    headers,
    header(name) {
      return this.headers[String(name).toLowerCase()];
    },
    ip: '127.0.0.1',
  };
}

const PAYLOAD = {
  event: 'transaction.updated',
  data: {
    transaction: {
      id: 'tx_replay_123',
      reference: 'booking_456',
      status: 'APPROVED',
      amount_in_cents: 5000000,
      payment_method_type: 'NEQUI',
    },
  },
};

function buildApp() {
  const app = express();
  app.use(
    express.json({
      verify: (req, _res, buf) => {
        req.rawBody = buf;
      },
    })
  );
  app.post('/api/payments/wompi-webhook', bookingController.wompiWebhook);
  return app;
}

describe('Wompi webhook — verificación HMAC con timestamp + nonce (anti-replay)', () => {
  let verifyWompiSignature;

  beforeAll(() => {
    verifyWompiSignature = bookingController.verifyWompiSignature;
  });

  beforeEach(() => {
    process.env.WOMPI_WEBHOOK_SECRET = SECRET;
    process.env.NODE_ENV = 'test';
    if (typeof bookingController.resetWompiNonceStore === 'function') {
      bookingController.resetWompiNonceStore();
    }
  });

  afterEach(() => {
    delete process.env.WOMPI_WEBHOOK_SECRET;
  });

  test('expone verifyWompiSignature para poder verificarlo de forma aislada', () => {
    expect(typeof verifyWompiSignature).toBe('function');
  });

  describe('Camino feliz', () => {
    test('acepta un webhook con firma válida, timestamp fresco y nonce nuevo', () => {
      const now = Date.now();
      const req = buildReq({ body: PAYLOAD, timestamp: now, nonce: 'nonce-fresh-1' });
      expect(verifyWompiSignature(req)).toBe(true);
    });

    test('acepta el mismo payload con otro nonce (no bloquea pagos legítimos)', () => {
      const now = Date.now();
      expect(verifyWompiSignature(buildReq({ body: PAYLOAD, timestamp: now, nonce: 'n-a' }))).toBe(true);
      expect(verifyWompiSignature(buildReq({ body: PAYLOAD, timestamp: now, nonce: 'n-b' }))).toBe(true);
    });
  });

  describe('Cabeceras obligatorias', () => {
    test('rechaza webhook sin cabecera de firma', () => {
      const now = Date.now();
      const req = buildReq({ body: PAYLOAD, timestamp: now, nonce: 'n-1', omit: ['signature'] });
      expect(verifyWompiSignature(req)).toBe(false);
    });

    test('rechaza webhook sin timestamp', () => {
      const now = Date.now();
      const req = buildReq({ body: PAYLOAD, timestamp: now, nonce: 'n-2', omit: ['timestamp'] });
      expect(verifyWompiSignature(req)).toBe(false);
    });

    test('rechaza webhook sin nonce', () => {
      const now = Date.now();
      const req = buildReq({ body: PAYLOAD, timestamp: now, nonce: 'n-3', omit: ['nonce'] });
      expect(verifyWompiSignature(req)).toBe(false);
    });

    test('rechaza timestamp no numérico', () => {
      const now = Date.now();
      const req = buildReq({ body: PAYLOAD, timestamp: now, nonce: 'n-bad-ts' });
      req.headers['x-wompi-timestamp'] = 'not-a-number';
      // La firma se calculó con el valor real; el timestamp inválido debe rechazarse por sí mismo.
      expect(verifyWompiSignature(req)).toBe(false);
    });
  });

  describe('Vulnerabilidad de replay (binding criptográfico)', () => {
    test('RECHAZA una firma estilo antiguo (HMAC solo del payload) aunque vengan timestamp y nonce', () => {
      const now = Date.now();
      const rawBody = JSON.stringify(PAYLOAD);
      const req = buildReq({
        body: PAYLOAD,
        timestamp: now,
        nonce: 'n-legacy',
        signature: legacySign(SECRET, rawBody), // firma sin cubrir ts/nonce
      });
      expect(verifyWompiSignature(req)).toBe(false);
    });

    test('RECHAZA si se altera el timestamp sin recalcular la firma (evita saltarse la ventana)', () => {
      const now = Date.now();
      const rawBody = JSON.stringify(PAYLOAD);
      const nonce = 'n-tamper-ts';
      // Firma legítima del instante real...
      const signature = sign(SECRET, now, nonce, rawBody);
      // ...pero el atacante reenvía con un timestamp "fresco" distinto.
      const req = buildReq({ body: PAYLOAD, timestamp: now + 1000, nonce, signature });
      expect(verifyWompiSignature(req)).toBe(false);
    });

    test('RECHAZA reutilizar el mismo nonce (replay)', () => {
      const now = Date.now();
      const first = buildReq({ body: PAYLOAD, timestamp: now, nonce: 'n-replay' });
      const second = buildReq({ body: PAYLOAD, timestamp: now, nonce: 'n-replay' });

      expect(verifyWompiSignature(first)).toBe(true);
      expect(verifyWompiSignature(second)).toBe(false); // replay bloqueado
    });
  });

  describe('Ventana temporal', () => {
    test('rechaza timestamp más antiguo que la tolerancia (5 min)', () => {
      const old = Date.now() - TOLERANCE_MS - 1000;
      const req = buildReq({ body: PAYLOAD, timestamp: old, nonce: 'n-old' });
      expect(verifyWompiSignature(req)).toBe(false);
    });

    test('rechaza timestamp en el futuro más allá de la tolerancia (clock skew)', () => {
      const future = Date.now() + TOLERANCE_MS + 1000;
      const req = buildReq({ body: PAYLOAD, timestamp: future, nonce: 'n-future' });
      expect(verifyWompiSignature(req)).toBe(false);
    });

    test('acepta timestamp dentro de la tolerancia (borde cercano)', () => {
      const recent = Date.now() - TOLERANCE_MS + 5000;
      const req = buildReq({ body: PAYLOAD, timestamp: recent, nonce: 'n-edge' });
      expect(verifyWompiSignature(req)).toBe(true);
    });
  });

  describe('Integración HTTP (endpoint /api/payments/wompi-webhook)', () => {
    function post(app, payload, { timestamp, nonce, omit = [] }) {
      const raw = JSON.stringify(payload);
      const r = request(app)
        .post('/api/payments/wompi-webhook')
        .set('Content-Type', 'application/json');
      if (!omit.includes('timestamp')) r.set('x-wompi-timestamp', String(timestamp));
      if (!omit.includes('nonce')) r.set('x-wompi-nonce', nonce);
      if (!omit.includes('signature')) r.set('x-wompi-signature', sign(SECRET, timestamp, nonce, raw));
      return r.send(raw);
    }

    test('responde 401 cuando faltan timestamp/nonce (firma solo del payload)', async () => {
      const app = buildApp();
      const raw = JSON.stringify(PAYLOAD);
      const res = await request(app)
        .post('/api/payments/wompi-webhook')
        .set('Content-Type', 'application/json')
        .set('x-wompi-signature', legacySign(SECRET, raw))
        .send(raw);
      expect(res.status).toBe(401);
    });

    test('responde 401 al reintentar el mismo webhook (replay)', async () => {
      const app = buildApp();
      const now = Date.now();
      const nonce = 'n-http-replay';

      const first = await post(app, { event: 'ping' }, { timestamp: now, nonce });
      expect(first.status).toBe(200);

      const second = await post(app, { event: 'ping' }, { timestamp: now, nonce });
      expect(second.status).toBe(401);
    });

    test('acepta un webhook correctamente firmado con timestamp y nonce frescos', async () => {
      const app = buildApp();
      const res = await post(
        app,
        { event: 'ping' },
        { timestamp: Date.now(), nonce: 'n-http-ok' }
      );
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });
});
