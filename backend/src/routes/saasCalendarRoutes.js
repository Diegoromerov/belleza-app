// backend/src/routes/saasCalendarRoutes.js
const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const { activeContextMiddleware } = require('../middleware/activeContextMiddleware');
const saasCalendarController = require('../controllers/saasCalendarController');

/**
 * Public ICS Feed endpoint (Token-based authentication without session)
 */
router.get('/feed/:token', saasCalendarController.getIcsFeed);

/**
 * Protected SaaS Staff Calendar Management Endpoints
 */
router.get('/staff/:membershipId/status', authMiddleware, activeContextMiddleware, saasCalendarController.getStaffStatus);
router.get('/staff/:membershipId/google/auth-url', authMiddleware, activeContextMiddleware, saasCalendarController.getGoogleAuthUrl);
router.post('/staff/:membershipId/ics/token', authMiddleware, activeContextMiddleware, saasCalendarController.generateIcsToken);
router.delete('/staff/:membershipId/ics/token', authMiddleware, activeContextMiddleware, saasCalendarController.revokeIcsToken);
router.post('/staff/:membershipId/google/connect', authMiddleware, activeContextMiddleware, saasCalendarController.connectGoogle);
router.post('/staff/:membershipId/google/disconnect', authMiddleware, activeContextMiddleware, saasCalendarController.disconnectGoogle);

module.exports = router;
