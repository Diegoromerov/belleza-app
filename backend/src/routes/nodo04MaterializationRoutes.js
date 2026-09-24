// backend/src/routes/nodo04MaterializationRoutes.js
const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const { activeContextMiddleware } = require('../middleware/activeContextMiddleware');
const nodo04MaterializationController = require('../controllers/nodo04MaterializationController');

/**
 * NODO-04 — Downstream B2C Materialization Adapter Routes
 * Base prefix: /api/v1/saas/hub/materializations/services
 * Protected by authMiddleware + activeContextMiddleware.
 */

// OP-01: POST /api/v1/saas/hub/materializations/services
router.post('/services', authMiddleware, activeContextMiddleware, nodo04MaterializationController.materializeService);

// OP-02: GET /api/v1/saas/hub/materializations/services
router.get('/services', authMiddleware, activeContextMiddleware, nodo04MaterializationController.listMaterializations);

module.exports = router;
