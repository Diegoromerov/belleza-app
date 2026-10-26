/**
 * SaaS CRM routes for beauty salons.
 * Provides CRUD for Leads and Opportunities.
 * Swagger JSDoc annotations are included for API docs.
 */
const express = require('express');
const router = express.Router();
const leadController = require('../../controllers/leadController');
const opportunityController = require('../../controllers/opportunityController');

// Middleware placeholder to ensure req.user is set (auth)
// Assuming existing auth middleware is applied globally in app.js

// Leads
router.post('/leads', leadController.create);
router.get('/leads', leadController.list);
router.get('/leads/:id', leadController.get);
router.put('/leads/:id', leadController.update);
router.delete('/leads/:id', leadController.delete);

// Opportunities
router.post('/opportunities', opportunityController.create);
router.get('/opportunities', opportunityController.list);
router.get('/opportunities/:id', opportunityController.get);
router.put('/opportunities/:id', opportunityController.update);
router.delete('/opportunities/:id', opportunityController.delete);
router.post('/opportunities/:id/transition', opportunityController.transition);

module.exports = router;
