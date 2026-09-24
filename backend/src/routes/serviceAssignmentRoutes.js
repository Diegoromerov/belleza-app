// backend/src/routes/serviceAssignmentRoutes.js
const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const { activeContextMiddleware } = require('../middleware/activeContextMiddleware');
const serviceAssignmentController = require('../controllers/serviceAssignmentController');

/**
 * NODO-02 — Service Assignment Routes
 * Base prefix: /api/v1/saas/hub/assignments
 * Protected by authMiddleware + activeContextMiddleware.
 * 
 * IMPORTANT: Specific subroutes (/staff/:membership_id, /offer/:service_offer_id)
 * MUST be registered BEFORE parameterized route (/:id) to prevent route collision.
 */

// POST /api/v1/saas/hub/assignments
router.post('/', authMiddleware, activeContextMiddleware, serviceAssignmentController.createAssignment);

// GET /api/v1/saas/hub/assignments
router.get('/', authMiddleware, activeContextMiddleware, serviceAssignmentController.listEstablishmentAssignments);

// GET /api/v1/saas/hub/assignments/staff/:membership_id
router.get('/staff/:membership_id', authMiddleware, activeContextMiddleware, serviceAssignmentController.getAssignmentsByStaff);

// GET /api/v1/saas/hub/assignments/offer/:service_offer_id
router.get('/offer/:service_offer_id', authMiddleware, activeContextMiddleware, serviceAssignmentController.getAssignmentsByOffer);

// DELETE /api/v1/saas/hub/assignments/:id (Pure Unassignment)
router.delete('/:id', authMiddleware, activeContextMiddleware, serviceAssignmentController.deleteAssignment);

module.exports = router;
