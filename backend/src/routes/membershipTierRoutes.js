// backend/src/routes/membershipTierRoutes.js
const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const MembershipTierService = require('../services/membershipTierService');
const { wrapRouterAsync } = require('../utils/expressAsync');

/**
 * GET /api/membership-tier/profile
 * Obtiene el perfil completo de membresía del usuario autenticado
 */
router.get('/profile', authMiddleware, async (req, res) => {
  const userId = req.user.id;
  const data = await MembershipTierService.getUserTierProfile(userId);
  res.json({ success: true, data });
});

/**
 * POST /api/membership-tier/award-xp
 * Registra eventos de otorgamiento de XP
 */
router.post('/award-xp', authMiddleware, async (req, res) => {
  const userId = req.user.id;
  const { eventType, xpAmount, referenceId, metadata } = req.body;

  if (!eventType || !xpAmount) {
    return res.status(400).json({ error: 'eventType y xpAmount son obligatorios' });
  }

  const result = await MembershipTierService.awardXp({
    userId,
    eventType,
    xpAmount: parseInt(xpAmount, 10),
    referenceId,
    metadata,
  });

  res.json(result);
});

/**
 * POST /api/membership-tier/redeem-coins
 * Canjear Aura Coins por cupones de descuento
 */
router.post('/redeem-coins', authMiddleware, async (req, res) => {
  const userId = req.user.id;
  const { coinsToRedeem } = req.body;

  if (!coinsToRedeem || coinsToRedeem <= 0) {
    return res.status(400).json({ error: 'coinsToRedeem debe ser mayor a 0' });
  }

  const result = await MembershipTierService.redeemAuraCoins({
    userId,
    coinsToRedeem: parseInt(coinsToRedeem, 10),
  });

  res.json(result);
});

wrapRouterAsync(router);
module.exports = router;
