// backend/src/routes/designsRoutes.js
const express = require('express');
const router = express.Router();
const path = require('path');
const multer = require('multer');
const { searchPinterestDesigns, analyzeFaceShape, analyzeDesign, proxyImage, getAIHistory, compareDesigns, getSkinProfile, checkGlowAIQuota, subscribePremium, checkInStreak, getShareCode, redirectReferral, getRecommendedDoctors } = require('../controllers/designsController');
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
router.get('/profile', authMiddleware, getSkinProfile);
router.get('/search', authMiddleware, searchPinterestDesigns);
router.get('/share/code', authMiddleware, getShareCode);
router.get('/share/go/:code', redirectReferral);
router.get('/profesionales/recommend', authMiddleware, getRecommendedDoctors);
router.post('/face-analysis', authMiddleware, upload.single('image'), analyzeFaceShape);
router.post('/analyze', authMiddleware, checkGlowAIQuota, upload.single('image'), analyzeDesign);
router.post('/compare', authMiddleware, upload.fields([{ name: 'imageBefore', maxCount: 1 }, { name: 'imageAfter', maxCount: 1 }]), compareDesigns);
router.post('/payments/glowai-premium', authMiddleware, subscribePremium);
router.post('/streak/check-in', authMiddleware, checkInStreak);

module.exports = router;
