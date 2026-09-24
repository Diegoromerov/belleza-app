// backend/src/routes/crearDesdeCeroRoutes.js
const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const { activeContextMiddleware } = require('../middleware/activeContextMiddleware');
const crearDesdeCeroController = require('../controllers/crearDesdeCeroController');

/**
 * Node Contract — Crear Desde Cero v1.0 Routes
 * Provisioning and Handover endpoints protected by authMiddleware and activeContextMiddleware.
 */

// Compilación y Handover del Context Package: POST /bootstrap
router.post('/bootstrap', authMiddleware, activeContextMiddleware, crearDesdeCeroController.bootstrap);

module.exports = router;
