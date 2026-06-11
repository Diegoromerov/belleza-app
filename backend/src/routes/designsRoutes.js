// backend/src/routes/designsRoutes.js
const express = require('express');
const router = express.Router();
const { searchPinterestDesigns } = require('../controllers/designsController');
const authMiddleware = require('../middleware/auth');

router.get('/search', authMiddleware, searchPinterestDesigns);

module.exports = router;
