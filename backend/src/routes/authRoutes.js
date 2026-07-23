const express = require('express');
const router = express.Router();
const { register, login, oauth, onboarding, acceptBiometricsConsent, saveFcmToken, getReferralInfo, deleteAccount } = require('../controllers/authController');
const { googleSignIn } = require('../controllers/oauthController');
const authMiddleware = require('../middleware/auth');
const rateLimiter = require('../middleware/rateLimiter');

// Rate limiter específico para endpoints de autenticación (10 intentos por ventana de 15 minutos por IP)
const authLimiter = rateLimiter({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: 'Demasiados intentos de autenticación. Intente de nuevo en 15 minutos.'
});

router.post('/register', authLimiter, register);
router.post('/login', authLimiter, login);
router.post('/oauth', authLimiter, oauth);
router.post('/google', authLimiter, googleSignIn);
router.patch('/onboarding', authMiddleware, onboarding);
router.patch('/biometrics/consent', authMiddleware, acceptBiometricsConsent);
router.post('/fcm-token', authMiddleware, saveFcmToken);
router.get('/referral-info', authMiddleware, getReferralInfo);
router.delete('/delete-account', authMiddleware, deleteAccount);

module.exports = router;

