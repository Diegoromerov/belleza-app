/**
 * GLOWAPP BUSINESS ROUTES
 * Express router for GlowApp Business Engine REST API (/api/v1/business).
 */

const express = require('express');
const router = express.Router();
const businessController = require('../controllers/businessController');

// Public catalog route
router.get('/verticals', businessController.getVerticals);

// Business Profile & Diagnostic
router.post('/diagnostic', businessController.runDiagnostic);
router.get('/summary', businessController.getSummary);

// Tasks & Guided Workflows
router.get('/tasks', businessController.getTasks);
router.post('/tasks/:id/advance', businessController.advanceTask);
router.post('/tasks/:id/evidence', businessController.submitEvidence);

// Document Generator
router.get('/templates', businessController.getTemplates);
router.post('/documents/generate', businessController.generateDocument);

module.exports = router;
