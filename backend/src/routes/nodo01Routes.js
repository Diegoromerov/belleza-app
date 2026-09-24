// backend/src/routes/nodo01Routes.js
const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const { activeContextMiddleware } = require('../middleware/activeContextMiddleware');
const nodo01Controller = require('../controllers/nodo01Controller');

/**
 * Node Contract — NODO-01-v1.0 Routes
 * Handover Ingestion endpoint protected by authMiddleware and activeContextMiddleware.
 */

// Ingestión y adaptación semántica in-memory: POST /ingest
router.post('/ingest', authMiddleware, activeContextMiddleware, nodo01Controller.ingest);

module.exports = router;
