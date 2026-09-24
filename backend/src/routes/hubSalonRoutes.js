// backend/src/routes/hubSalonRoutes.js
const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const { activeContextMiddleware } = require('../middleware/activeContextMiddleware');
const hubSalonController = require('../controllers/hubSalonController');

/**
 * Node Contract — Hub Salón v1.0 Routes
 * Operational Cockpit endpoints protected by authMiddleware and activeContextMiddleware.
 */

// Resumen del establecimiento activo: GET /api/v1/saas/hub/summary
router.get('/summary', authMiddleware, activeContextMiddleware, hubSalonController.getSummary);

// Equipo activo de la sede: GET /api/v1/saas/hub/staff
router.get('/staff', authMiddleware, activeContextMiddleware, hubSalonController.getStaff);

module.exports = router;
