const express = require('express');
const router = express.Router();
const { createSalon, inviteMember, acceptInvitation, getSalonMembers, getMySalon } = require('../controllers/salonController');
const { authMiddleware } = require('../middleware/auth');

router.get('/my-salon', authMiddleware, getMySalon);
router.post('/create', authMiddleware, createSalon);
router.post('/invite', authMiddleware, inviteMember);
router.post('/accept-invitation', authMiddleware, acceptInvitation);
router.get('/:salonId/members', authMiddleware, getSalonMembers);

module.exports = router;
