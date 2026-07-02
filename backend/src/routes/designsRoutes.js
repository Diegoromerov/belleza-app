// backend/src/routes/designsRoutes.js
const express = require('express');
const router = express.Router();
const path = require('path');
const multer = require('multer');
const { searchPinterestDesigns, analyzeFaceShape, analyzeDesign, proxyImage, getAIHistory } = require('../controllers/designsController');
const authMiddleware = require('../middleware/auth');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // Límite de 5MB
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif|webp/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype) || file.mimetype === 'application/octet-stream' || !file.mimetype;
    if (extname && mimetype) {
      return cb(null, true);
    } else {
      cb(new Error('Solo se permiten imágenes (.jpeg, .jpg, .png, .gif, .webp)'));
    }
  }
});

router.get('/proxy', proxyImage);
router.get('/history', authMiddleware, getAIHistory);
router.get('/search', authMiddleware, searchPinterestDesigns);
router.post('/face-analysis', authMiddleware, upload.single('image'), analyzeFaceShape);
router.post('/analyze', authMiddleware, upload.single('image'), analyzeDesign);

module.exports = router;
