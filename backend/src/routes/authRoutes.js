const express = require('express');
const router = express.Router();
const { register, login, logout, forgotPassword, resetPassword, oauth, onboarding, acceptBiometricsConsent, saveFcmToken, getReferralInfo, deleteAccount } = require('../controllers/authController');
const { googleSignIn } = require('../controllers/oauthController');
const { authMiddleware, adminMiddleware } = require('../middleware/auth');

// Rate limiter temporalmente deshabilitado por incompatibilidad de exportación
// const rateLimiter = require('../middleware/rateLimiter');
// const authLimiter = rateLimiter({
//   windowMs: 15 * 60 * 1000,
//   max: 10,
//   message: 'Demasiados intentos de autenticación. Intente de nuevo en 15 minutos.'
// });

router.post('/register', register);
router.post('/login', login);
router.post('/logout', authMiddleware, logout);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);
router.post('/oauth', oauth);
router.post('/google', googleSignIn);
router.patch('/onboarding', authMiddleware, onboarding);
router.patch('/biometrics/consent', authMiddleware, acceptBiometricsConsent);
router.post('/fcm-token', authMiddleware, saveFcmToken);
router.get('/referral-info', authMiddleware, getReferralInfo);
router.delete('/delete-account', authMiddleware, deleteAccount);

module.exports = router;