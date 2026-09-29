// backend/tests/validation-financial.test.js
// Tests para validación Joi/Zod en endpoints financieros (P2-5)
const request = require('supertest');
const express = require('express');
const Joi = require('joi');
const {
  validate,
  validateQuery,
  validateParams,
  bankAccountSchema,
  withdrawSchema,
  withdrawalModelSchema,
  adminDisputesQuerySchema,
  disputeSchema,
  resolveDisputeSchema,
  adminDashboardQuerySchema
} = require('../src/middleware/validation');

// Helper para crear app de test con middleware de validación
function createTestApp(routes) {
  const app = express();
  app.use(express.json());
  routes(app);
  return app;
}

describe('Financial Endpoint Validation (P2-5)', () => {
  describe('validate() middleware factory', () => {
    test('should call next() when body matches schema', async () => {
      const schema = Joi.object({ name: Joi.string().required() });
      const app = createTestApp((app) => {
        app.post('/test', validate(schema), (req, res) => res.json({ ok: true }));
      });

      await request(app)
        .post('/test')
        .send({ name: 'test' })
        .expect(200)
        .expect({ ok: true });
    });

    test('should return 400 when body fails validation', async () => {
      const schema = Joi.object({ name: Joi.string().required() });
      const app = createTestApp((app) => {
        app.post('/test', validate(schema), (req, res) => res.json({ ok: true }));
      });

      await request(app)
        .post('/test')
        .send({})
        .expect(400)
        .expect({ error: '"name" is required' });
    });

    test('should return first validation error with abortEarly: false', async () => {
      const schema = Joi.object({
        name: Joi.string().required(),
        age: Joi.number().integer().min(18).required()
      });
      const app = createTestApp((app) => {
        app.post('/test', validate(schema), (req, res) => res.json({ ok: true }));
      });

      await request(app)
        .post('/test')
        .send({ name: 'test' }) // missing age
        .expect(400)
        .expect({ error: '"age" is required' });
    });
  });

  describe('validateQuery() middleware factory', () => {
    test('should validate query params', async () => {
      const schema = Joi.object({ page: Joi.number().integer().min(1).optional() });
      const app = createTestApp((app) => {
        app.get('/test', validateQuery(schema), (req, res) => res.json({ page: req.query.page }));
      });

      await request(app)
        .get('/test?page=2')
        .expect(200)
        .expect({ page: '2' });
    });

    test('should return 400 for invalid query params', async () => {
      const schema = Joi.object({ page: Joi.number().integer().min(1).optional() });
      const app = createTestApp((app) => {
        app.get('/test', validateQuery(schema), (req, res) => res.json({ page: req.query.page }));
      });

      await request(app)
        .get('/test?page=0')
        .expect(400)
        .expect({ error: '"page" must be greater than or equal to 1' });
    });
  });

  describe('bankAccountSchema', () => {
    test('should accept valid NEQUI account', () => {
      const { error } = bankAccountSchema.validate({
        tipo_cuenta: 'NEQUI',
        numero_cuenta: '3001234567'
      });
      expect(error).toBeUndefined();
    });

    test('should accept valid DAVIPLATA account', () => {
      const { error } = bankAccountSchema.validate({
        tipo_cuenta: 'DAVIPLATA',
        numero_cuenta: '3001234567'
      });
      expect(error).toBeUndefined();
    });

    test('should accept valid BANCARIA account with all fields', () => {
      const { error } = bankAccountSchema.validate({
        tipo_cuenta: 'BANCARIA',
        banco: 'Bancolombia',
        numero_cuenta: '1234567890123456',
        tipo_cuenta_bancaria: 'AHORROS',
        titular_nombre: 'Juan Pérez',
        titular_documento_tipo: 'CC',
        titular_documento_num: '1234567890'
      });
      expect(error).toBeUndefined();
    });

    test('should reject account with numero_cuenta too short', () => {
      const { error } = bankAccountSchema.validate({
        numero_cuenta: '12345' // menos de 6 chars
      });
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('length must be at least 6 characters long');
    });

    test('should reject invalid tipo_cuenta', () => {
      const { error } = bankAccountSchema.validate({
        tipo_cuenta: 'INVALIDO',
        numero_cuenta: '3001234567'
      });
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('must be one of');
    });

    test('should reject invalid tipo_cuenta_bancaria', () => {
      const { error } = bankAccountSchema.validate({
        tipo_cuenta: 'BANCARIA',
        numero_cuenta: '123456789',
        tipo_cuenta_bancaria: 'INVALIDO'
      });
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('must be one of');
    });

    test('should reject invalid titular_documento_tipo', () => {
      const { error } = bankAccountSchema.validate({
        numero_cuenta: '123456789',
        titular_documento_tipo: 'INVALIDO'
      });
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('must be one of');
    });
  });

  describe('withdrawSchema', () => {
    test('should accept valid positive amount', () => {
      const { error } = withdrawSchema.validate({ monto: 50000 });
      expect(error).toBeUndefined();
    });

    test('should accept decimal amount with 2 decimals', () => {
      const { error } = withdrawSchema.validate({ monto: 50000.50 });
      expect(error).toBeUndefined();
    });

    test('should reject zero amount', () => {
      const { error } = withdrawSchema.validate({ monto: 0 });
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('must be a positive number');
    });

    test('should reject negative amount', () => {
      const { error } = withdrawSchema.validate({ monto: -100 });
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('must be a positive number');
    });

    test('should reject missing monto', () => {
      const { error } = withdrawSchema.validate({});
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('is required');
    });

    test('should reject non-numeric monto', () => {
      const { error } = withdrawSchema.validate({ monto: 'abc' });
      expect(error).toBeDefined();
    });

    test('should reject more than 2 decimal places', () => {
      const { error } = withdrawSchema.validate({ monto: 50000.123 });
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('must have no more than 2 decimal places');
    });
  });

  describe('withdrawalModelSchema', () => {
    test('should accept DEMANDA', () => {
      const { error } = withdrawalModelSchema.validate({ modelo: 'DEMANDA' });
      expect(error).toBeUndefined();
    });

    test('should accept QUINCENA', () => {
      const { error } = withdrawalModelSchema.validate({ modelo: 'QUINCENA' });
      expect(error).toBeUndefined();
    });

    test('should accept MENSUAL', () => {
      const { error } = withdrawalModelSchema.validate({ modelo: 'MENSUAL' });
      expect(error).toBeUndefined();
    });

    test('should reject invalid modelo', () => {
      const { error } = withdrawalModelSchema.validate({ modelo: 'INVALIDO' });
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('must be one of');
    });

    test('should reject missing modelo', () => {
      const { error } = withdrawalModelSchema.validate({});
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('is required');
    });
  });

  describe('adminDisputesQuerySchema', () => {
    test('should accept valid query params', () => {
      const { error } = adminDisputesQuerySchema.validate({
        estado: 'ABIERTA',
        page: 1,
        limit: 20
      });
      expect(error).toBeUndefined();
    });

    test('should accept empty query', () => {
      const { error } = adminDisputesQuerySchema.validate({});
      expect(error).toBeUndefined();
    });

    test('should reject invalid estado', () => {
      const { error } = adminDisputesQuerySchema.validate({ estado: 'INVALIDO' });
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('must be one of');
    });

    test('should reject page < 1', () => {
      const { error } = adminDisputesQuerySchema.validate({ page: 0 });
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('must be greater than or equal to 1');
    });

    test('should reject limit > 100', () => {
      const { error } = adminDisputesQuerySchema.validate({ limit: 101 });
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('must be less than or equal to 100');
    });
  });

  describe('disputeSchema', () => {
    test('should accept valid dispute', () => {
      const { error } = disputeSchema.validate({
        booking_id: 123,
        tipo: 'PAGO_NO_RECIBIDO',
        descripcion: 'No recibí el pago',
        evidencia_urls: ['https://example.com/evidence.jpg']
      });
      expect(error).toBeUndefined();
    });

    test('should accept minimal valid dispute', () => {
      const { error } = disputeSchema.validate({
        booking_id: 123,
        tipo: 'SERVICIO_NO_REALIZADO'
      });
      expect(error).toBeUndefined();
    });

    test('should reject missing booking_id', () => {
      const { error } = disputeSchema.validate({ tipo: 'PAGO_NO_RECIBIDO' });
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('is required');
    });

    test('should reject missing tipo', () => {
      const { error } = disputeSchema.validate({ booking_id: 123 });
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('is required');
    });

    test('should reject invalid tipo', () => {
      const { error } = disputeSchema.validate({
        booking_id: 123,
        tipo: 'INVALIDO'
      });
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('must be one of');
    });

    test('should reject non-integer booking_id', () => {
      const { error } = disputeSchema.validate({
        booking_id: 'abc',
        tipo: 'PAGO_NO_RECIBIDO'
      });
      expect(error).toBeDefined();
    });

    test('should reject descripcion too long', () => {
      const { error } = disputeSchema.validate({
        booking_id: 123,
        tipo: 'PAGO_NO_RECIBIDO',
        descripcion: 'a'.repeat(2001)
      });
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('must be less than or equal to 2000');
    });

    test('should reject non-URI evidencia_urls', () => {
      const { error } = disputeSchema.validate({
        booking_id: 123,
        tipo: 'PAGO_NO_RECIBIDO',
        evidencia_urls: ['not-a-url']
      });
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('must be a valid uri');
    });

    test('should reject more than 10 evidencia_urls', () => {
      const urls = Array(11).fill('https://example.com/evidence.jpg');
      const { error } = disputeSchema.validate({
        booking_id: 123,
        tipo: 'PAGO_NO_RECIBIDO',
        evidencia_urls: urls
      });
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('must contain no more than 10 items');
    });
  });

  describe('resolveDisputeSchema', () => {
    test('should accept FAVOR_PRESTADOR without porcentaje', () => {
      const { error } = resolveDisputeSchema.validate({
        resolucion: 'FAVOR_PRESTADOR',
        nota_resolucion: 'Pago verificado'
      });
      expect(error).toBeUndefined();
    });

    test('should accept REEMBOLSO_TOTAL without porcentaje', () => {
      const { error } = resolveDisputeSchema.validate({
        resolucion: 'REEMBOLSO_TOTAL'
      });
      expect(error).toBeUndefined();
    });

    test('should accept COMPENSACION_PLATAFORMA without porcentaje', () => {
      const { error } = resolveDisputeSchema.validate({
        resolucion: 'COMPENSACION_PLATAFORMA'
      });
      expect(error).toBeUndefined();
    });

    test('should require porcentaje_prestador for DIVISION', () => {
      const { error } = resolveDisputeSchema.validate({
        resolucion: 'DIVISION'
      });
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('is required');
    });

    test('should accept valid porcentaje_prestador for DIVISION', () => {
      const { error } = resolveDisputeSchema.validate({
        resolucion: 'DIVISION',
        porcentaje_prestador: 50
      });
      expect(error).toBeUndefined();
    });

    test('should reject porcentaje_prestador < 0 for DIVISION', () => {
      const { error } = resolveDisputeSchema.validate({
        resolucion: 'DIVISION',
        porcentaje_prestador: -1
      });
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('must be greater than or equal to 0');
    });

    test('should reject porcentaje_prestador > 100 for DIVISION', () => {
      const { error } = resolveDisputeSchema.validate({
        resolucion: 'DIVISION',
        porcentaje_prestador: 101
      });
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('must be less than or equal to 100');
    });

    test('should reject invalid resolucion', () => {
      const { error } = resolveDisputeSchema.validate({
        resolucion: 'INVALIDO'
      });
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('must be one of');
    });

    test('should reject non-integer porcentaje_prestador', () => {
      const { error } = resolveDisputeSchema.validate({
        resolucion: 'DIVISION',
        porcentaje_prestador: 50.5
      });
      expect(error).toBeDefined();
    });

    test('should reject nota_resolucion too long', () => {
      const { error } = resolveDisputeSchema.validate({
        resolucion: 'FAVOR_PRESTADOR',
        nota_resolucion: 'a'.repeat(2001)
      });
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('must be less than or equal to 2000');
    });
  });

  describe('adminDashboardQuerySchema', () => {
    test('should accept empty query', () => {
      const { error } = adminDashboardQuerySchema.validate({});
      expect(error).toBeUndefined();
    });

    test('should reject unexpected query params (Joi 17+ forbids unknown by default)', () => {
      const { error } = adminDashboardQuerySchema.validate({ unexpected: 'value' });
      expect(error).toBeDefined();
      expect(error.details[0].message).toContain('is not allowed');
    });
  });

  describe('Integration: Full route validation flow', () => {
    test('POST /wallet/bank-account with valid data', async () => {
      const app = createTestApp((app) => {
        app.post('/wallet/bank-account', validate(bankAccountSchema), (req, res) => {
          res.json({ ok: true, received: req.body });
        });
      });

      await request(app)
        .post('/wallet/bank-account')
        .send({
          tipo_cuenta: 'NEQUI',
          numero_cuenta: '3001234567'
        })
        .expect(200)
        .expect(res => {
          expect(res.body.ok).toBe(true);
          expect(res.body.received.tipo_cuenta).toBe('NEQUI');
        });
    });

    test('POST /wallet/bank-account rejects invalid data', async () => {
      const app = createTestApp((app) => {
        app.post('/wallet/bank-account', validate(bankAccountSchema), (req, res) => {
          res.json({ ok: true });
        });
      });

      await request(app)
        .post('/wallet/bank-account')
        .send({
          numero_cuenta: '123' // too short
        })
        .expect(400);
    });

    test('POST /wallet/withdraw with valid amount', async () => {
      const app = createTestApp((app) => {
        app.post('/wallet/withdraw', validate(withdrawSchema), (req, res) => {
          res.json({ ok: true, monto: req.body.monto });
        });
      });

      await request(app)
        .post('/wallet/withdraw')
        .send({ monto: 50000 })
        .expect(200)
        .expect(res => {
          expect(res.body.ok).toBe(true);
          expect(res.body.monto).toBe(50000);
        });
    });

    test('POST /wallet/withdraw rejects negative amount', async () => {
      const app = createTestApp((app) => {
        app.post('/wallet/withdraw', validate(withdrawSchema), (req, res) => {
          res.json({ ok: true });
        });
      });

      await request(app)
        .post('/wallet/withdraw')
        .send({ monto: -100 })
        .expect(400);
    });

    test('PUT /wallet/model with valid model', async () => {
      const app = createTestApp((app) => {
        app.put('/wallet/model', validate(withdrawalModelSchema), (req, res) => {
          res.json({ ok: true, modelo: req.body.modelo });
        });
      });

      await request(app)
        .put('/wallet/model')
        .send({ modelo: 'QUINCENA' })
        .expect(200)
        .expect(res => {
          expect(res.body.ok).toBe(true);
          expect(res.body.modelo).toBe('QUINCENA');
        });
    });

    test('POST /disputes with valid data', async () => {
      const app = createTestApp((app) => {
        app.post('/disputes', validate(disputeSchema), (req, res) => {
          res.json({ ok: true, dispute: req.body });
        });
      });

      await request(app)
        .post('/disputes')
        .send({
          booking_id: 123,
          tipo: 'PAGO_NO_RECIBIDO',
          descripcion: 'El pago no llegó'
        })
        .expect(200);
    });

    test('GET /admin/disputes with valid query', async () => {
      const app = createTestApp((app) => {
        app.get('/admin/disputes', validateQuery(adminDisputesQuerySchema), (req, res) => {
          res.json({ ok: true, query: req.query });
        });
      });

      await request(app)
        .get('/admin/disputes?estado=ABIERTA&page=1&limit=10')
        .expect(200);
    });

    test('GET /admin/dashboard with valid query', async () => {
      const app = createTestApp((app) => {
        app.get('/admin/dashboard', validateQuery(adminDashboardQuerySchema), (req, res) => {
          res.json({ ok: true });
        });
      });

      await request(app)
        .get('/admin/dashboard')
        .expect(200);
    });

    test('PUT /admin/disputes/:id/resolve with valid data', async () => {
      const app = createTestApp((app) => {
        app.put('/admin/disputes/:id/resolve', validateParams(Joi.object({ id: Joi.number().integer().required() })), validate(resolveDisputeSchema), (req, res) => {
          res.json({ ok: true, id: req.params.id, resolution: req.body.resolucion });
        });
      });

      await request(app)
        .put('/admin/disputes/456/resolve')
        .send({
          resolucion: 'FAVOR_PRESTADOR',
          nota_resolucion: 'Verificado'
        })
        .expect(200);
    });
  });
});