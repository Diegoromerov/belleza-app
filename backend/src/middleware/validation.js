// src/middleware/validation.js
const Joi = require('joi');

/**
 * Reutilizable validation middleware factory.
 * Returns a middleware that validates req.body against the provided Joi schema.
 */
function validate(schema) {
  return (req, res, next) => {
    const { error } = schema.validate(req.body, { abortEarly: false });
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }
    next();
  };
}

/**
 * Query params validation middleware factory.
 */
function validateQuery(schema) {
  return (req, res, next) => {
    const { error } = schema.validate(req.query, { abortEarly: false });
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }
    next();
  };
}

/**
 * Params validation middleware factory.
 */
function validateParams(schema) {
  return (req, res, next) => {
    const { error } = schema.validate(req.params, { abortEarly: false });
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }
    next();
  };
}

/**
 * Middleware to validate badge creation payload.
 * Expects a JSON body with `badge_id` (integer, required).
 */
function validateBadge(req, res, next) {
  const schema = Joi.object({
    badge_id: Joi.number().integer().required()
  });

  const { error } = schema.validate(req.body);
  if (error) {
    return res.status(400).json({ error: error.details[0].message });
  }
  next();
}

// ─── Financial endpoint validation schemas ────────────────────────────────────

// POST /wallet/bank-account - Register/update bank account
const bankAccountSchema = Joi.object({
  tipo_cuenta: Joi.string().valid('NEQUI', 'DAVIPLATA', 'AHORROS', 'CORRIENTE', 'BANCARIA').optional(),
  banco: Joi.string().max(100).optional(),
  numero_cuenta: Joi.string().min(6).max(50).required(),
  tipo_cuenta_bancaria: Joi.string().valid('AHORROS', 'CORRIENTE').optional(),
  titular_nombre: Joi.string().max(200).optional(),
  titular_documento_tipo: Joi.string().valid('CC', 'CE', 'NIT', 'PASSPORT').optional(),
  titular_documento_num: Joi.string().max(20).optional()
});

// POST /wallet/withdraw - Withdrawal request
const withdrawSchema = Joi.object({
  monto: Joi.number().positive().required()
    .custom((value, helpers) => {
      if (value % 1 !== 0) {
        const decimals = value.toString().split('.')[1];
        if (decimals && decimals.length > 2) {
          return helpers.error('number.precision', { limit: 2 });
        }
      }
      return value;
    })
    .messages({
      'number.precision': 'must have no more than 2 decimal places'
    })
});

// PUT /wallet/model - Change withdrawal model
const withdrawalModelSchema = Joi.object({
  modelo: Joi.string().valid('DEMANDA', 'QUINCENA', 'MENSUAL').required()
});

// GET /admin/disputes - Query params for disputes listing
const adminDisputesQuerySchema = Joi.object({
  estado: Joi.string().valid('ABIERTA', 'EN_REVISION', 'RESUELTA', 'CERRADA').optional(),
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(100).optional()
});

// POST /disputes - Open dispute
const disputeSchema = Joi.object({
  booking_id: Joi.number().integer().required(),
  tipo: Joi.string().valid('PAGO_NO_RECIBIDO', 'SERVICIO_NO_REALIZADO', 'OTRO').required(),
  descripcion: Joi.string().max(2000).optional(),
  evidencia_urls: Joi.array().items(Joi.string().uri()).max(10).optional()
    .messages({
      'array.max': '{{#label}} must contain no more than 10 items'
    })
});

// POST /admin/disputes/:id/resolve - Resolve dispute
const resolveDisputeSchema = Joi.object({
  resolucion: Joi.string().valid('FAVOR_PRESTADOR', 'REEMBOLSO_TOTAL', 'DIVISION', 'COMPENSACION_PLATAFORMA').required(),
  porcentaje_prestador: Joi.when('resolucion', {
    is: 'DIVISION',
    then: Joi.number().integer().min(0).max(100).required(),
    otherwise: Joi.number().integer().min(0).max(100).optional()
  }),
  nota_resolucion: Joi.string().max(2000).optional()
});

// GET /admin/dashboard - Query params (currently none, but prepared for future)
const adminDashboardQuerySchema = Joi.object({});

module.exports = {
  validate,
  validateQuery,
  validateParams,
  validateBadge,
  // Schemas
  bankAccountSchema,
  withdrawSchema,
  withdrawalModelSchema,
  adminDisputesQuerySchema,
  disputeSchema,
  resolveDisputeSchema,
  adminDashboardQuerySchema
};
