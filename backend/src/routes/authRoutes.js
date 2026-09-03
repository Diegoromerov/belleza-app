const express = require('express');
const router = express.Router();
const { register, login, logout, forgotPassword, resetPassword, oauth, onboarding, acceptBiometricsConsent, saveFcmToken, getReferralInfo, deleteAccount, changePassword } = require('../controllers/authController');
const { googleSignIn } = require('../controllers/oauthController');
const { authMiddleware, adminMiddleware } = require('../middleware/auth');

const { rateLimitByIP } = require('../middleware/rateLimiter');
const authLimiter = rateLimitByIP({
  windowMs: 15 * 60 * 1000, // 15 minutos
  limit: 30, // 30 intentos (basado en auditoría)
});

router.post('/register', authLimiter, register);
router.post('/login', authLimiter, login);
router.post('/logout', authMiddleware, logout);
router.post('/forgot-password', authLimiter, forgotPassword);
router.post('/reset-password', authLimiter, resetPassword);
router.post('/oauth', authLimiter, oauth);
router.post('/google', authLimiter, googleSignIn);
router.patch('/onboarding', authMiddleware, onboarding);
router.patch('/biometrics/consent', authMiddleware, acceptBiometricsConsent);
router.post('/fcm-token', authMiddleware, saveFcmToken);
router.get('/referral-info', authMiddleware, getReferralInfo);
router.delete('/delete-account', authMiddleware, deleteAccount);
router.patch('/change-password', authMiddleware, changePassword);

module.exports = router;