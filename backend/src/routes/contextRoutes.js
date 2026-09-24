// backend/src/routes/contextRoutes.js
const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const contextController = require('../controllers/contextController');

router.get('/available', authMiddleware, contextController.getAvailableContexts);

module.exports = router;