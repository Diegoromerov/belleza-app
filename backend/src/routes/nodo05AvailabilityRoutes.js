// backend/src/routes/nodo05AvailabilityRoutes.js
const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const { activeContextMiddleware } = require('../middleware/activeContextMiddleware');
const nodo05AvailabilityController = require('../controllers/nodo05AvailabilityController');

/**
 * NODO-05 — Availability Projection & Booking Slot Engine Routes
 * Base prefix: /api/v1/saas/hub/availability
 * Protected by authMiddleware + activeContextMiddleware.
 */

// GET /api/v1/saas/hub/availability/projection
router.get('/projection', authMiddleware, activeContextMiddleware, nodo05AvailabilityController.getAvailabilityProjection);

module.exports = router;
