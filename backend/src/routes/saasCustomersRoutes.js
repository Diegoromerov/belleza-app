// backend/src/routes/saasCustomersRoutes.js
const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const { activeContextMiddleware } = require('../middleware/activeContextMiddleware');
const saasCustomersController = require('../controllers/saasCustomersController');

/**
 * NODO: CUSTOMER / CLIENT DIRECTORY ENGINE ROUTES
 * Base mount: /api/saas/customers
 * Protected by authMiddleware + activeContextMiddleware.
 */

// GET /api/saas/customers/search — Búsqueda typeahead contextual
router.get('/search', authMiddleware, activeContextMiddleware, saasCustomersController.searchCustomers);

// GET /api/saas/customers — Listar directorio (scope=establishment por defecto, scope=tenant para admin)
router.get('/', authMiddleware, activeContextMiddleware, saasCustomersController.listCustomers);

// POST /api/saas/customers — Crear cliente atómicamente (+ relación con sede activa)
router.post('/', authMiddleware, activeContextMiddleware, saasCustomersController.createCustomer);

// GET /api/saas/customers/:id — Obtener detalle de cliente y relación local
router.get('/:id', authMiddleware, activeContextMiddleware, saasCustomersController.getCustomerById);

// PATCH /api/saas/customers/:id — Actualizar datos canónicos del cliente
router.patch('/:id', authMiddleware, activeContextMiddleware, saasCustomersController.updateCustomer);

// POST /api/saas/customers/:id/establishments — Asociar cliente existente del tenant a la sede activa
router.post('/:id/establishments', authMiddleware, activeContextMiddleware, saasCustomersController.createEstablishmentRelation);

// PATCH /api/saas/customers/:id/establishments/current — Actualizar relación local de la sede activa
router.patch('/:id/establishments/current', authMiddleware, activeContextMiddleware, saasCustomersController.updateCurrentEstablishmentRelation);

// POST /api/saas/customers/:id/link-user — Vincular explícitamente cuenta de usuario B2C
router.post('/:id/link-user', authMiddleware, activeContextMiddleware, saasCustomersController.linkUser);

// POST /api/saas/customers/:id/unlink-user — Desvincular cuenta de usuario B2C
router.post('/:id/unlink-user', authMiddleware, activeContextMiddleware, saasCustomersController.unlinkUser);

// GET /api/saas/customers/:id/history — Consultar historial derivado (Read-Only)
router.get('/:id/history', authMiddleware, activeContextMiddleware, saasCustomersController.getCustomerHistory);

module.exports = router;
