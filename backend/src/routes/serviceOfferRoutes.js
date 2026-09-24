// backend/src/routes/serviceOfferRoutes.js
const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const { activeContextMiddleware } = require('../middleware/activeContextMiddleware');
const serviceOfferController = require('../controllers/serviceOfferController');

/**
 * NODO-02 — Service Offer Routes
 * Base prefix: /api/v1/saas/hub/services
 * Protected by authMiddleware + activeContextMiddleware.
 */

// POST /api/v1/saas/hub/services
router.post('/', authMiddleware, activeContextMiddleware, serviceOfferController.createServiceOffer);

// GET /api/v1/saas/hub/services
router.get('/', authMiddleware, activeContextMiddleware, serviceOfferController.listServiceOffers);

// GET /api/v1/saas/hub/services/:id
router.get('/:id', authMiddleware, activeContextMiddleware, serviceOfferController.getServiceOfferById);

// PUT /api/v1/saas/hub/services/:id
router.put('/:id', authMiddleware, activeContextMiddleware, serviceOfferController.updateServiceOffer);

module.exports = router;
