// backend/src/routes/activeContextRoutes.js
const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const { activeContextMiddleware } = require('../middleware/activeContextMiddleware');
const activeContextController = require('../controllers/activeContextController');

/**
 * Node Contract — Active Context v1.0 Routes
 */

// Explicit Activation: POST /api/v1/saas/context/activate
router.post('/activate', authMiddleware, activeContextController.activateContext);

// Active Context Inspection: GET /api/v1/saas/context/active
router.get('/active', authMiddleware, activeContextMiddleware, activeContextController.getActiveContext);

module.exports = router;
