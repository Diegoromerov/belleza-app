const express = require('express');
const router = express.Router();
const { createSalon, inviteMember, acceptInvitation, getSalonMembers } = require('../controllers/salonController');
const { authMiddleware } = require('../middleware/auth');

router.post('/create', authMiddleware, createSalon);
router.post('/invite', authMiddleware, inviteMember);
router.post('/accept-invitation', authMiddleware, acceptInvitation);
router.get('/:salonId/members', authMiddleware, getSalonMembers);

module.exports = router;
