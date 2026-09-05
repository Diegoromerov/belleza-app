/**
 * GLOWAPP BUSINESS ROUTES
 * Express router for GlowApp Business Engine REST API (/api/v1/business).
 * 
 * BUS-SEC-001 Security Patch: Installed authMiddleware on all private routes.
 */

const express = require('express');
const router = express.Router();
const businessController = require('../controllers/businessController');
const { authMiddleware, adminMiddleware } = require('../middleware/auth');

// 1. Public catalog route (Legitimately public for onboarding discovery)
router.get('/verticals', businessController.getVerticals);

// 2. Private Provider Business Routes (Protected by authMiddleware)
router.post('/diagnostic', authMiddleware, businessController.runDiagnostic);
router.get('/summary', authMiddleware, businessController.getSummary);

// Tasks & Guided Workflows (Protected by authMiddleware)
router.get('/tasks', authMiddleware, businessController.getTasks);
router.post('/tasks/:id/advance', authMiddleware, businessController.advanceTask);
router.post('/tasks/:id/evidence', authMiddleware, businessController.submitEvidence);

// Document Generator (Protected by authMiddleware)
router.get('/templates', authMiddleware, businessController.getTemplates);
router.post('/documents/generate', authMiddleware, businessController.generateDocument);

// 3. Admin Business Routes (Protected by authMiddleware & adminMiddleware)
router.get('/admin/queue', authMiddleware, adminMiddleware, businessController.getAdminQueue);
router.put('/admin/evidence/:id', authMiddleware, adminMiddleware, businessController.reviewEvidence);

module.exports = router;
