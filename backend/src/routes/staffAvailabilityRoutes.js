// backend/src/routes/staffAvailabilityRoutes.js
const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const { activeContextMiddleware } = require('../middleware/activeContextMiddleware');
const staffAvailabilityController = require('../controllers/staffAvailabilityController');

/**
 * NODO-03A — Staff Operational Availability & Schedule Routes
 * Base prefix: /api/v1/saas/hub/staff
 * Protected by authMiddleware + activeContextMiddleware.
 * 
 * IMPORTANT: Specific subroutes (/schedules) MUST be registered BEFORE
 * parameterized routes (/:membership_id/schedule) to prevent route collisions.
 */

// OP-03: GET /api/v1/saas/hub/staff/schedules
router.get('/schedules', authMiddleware, activeContextMiddleware, staffAvailabilityController.listEstablishmentStaffSchedules);

// OP-02: GET /api/v1/saas/hub/staff/:membership_id/schedule
router.get('/:membership_id/schedule', authMiddleware, activeContextMiddleware, staffAvailabilityController.getStaffSchedule);

// OP-01: PUT /api/v1/saas/hub/staff/:membership_id/schedule
router.put('/:membership_id/schedule', authMiddleware, activeContextMiddleware, staffAvailabilityController.setStaffSchedule);

// OP-04: DELETE /api/v1/saas/hub/staff/:membership_id/schedule
router.delete('/:membership_id/schedule', authMiddleware, activeContextMiddleware, staffAvailabilityController.deleteStaffSchedule);

module.exports = router;
