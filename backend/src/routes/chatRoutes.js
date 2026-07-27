// backend/src/routes/chatRoutes.js
const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const chatController = require('../controllers/chatController');
const rateLimiter = require('../middleware/rateLimiter');

// Rate limiter específico para mensajes de chat (30 mensajes por ventana de 1 minuto por usuario)
const chatLimiter = rateLimiter({
  windowMs: 60 * 1000,
  max: 30,
  message: 'Has enviado demasiados mensajes en poco tiempo. Por favor espera un minuto.'
});

router.get('/chat/conversations', authMiddleware, chatController.getConversations);
router.get('/chat/messages/:partnerId', authMiddleware, chatController.getMessages);
router.post('/chat/messages', authMiddleware, chatLimiter, chatController.sendMessage);
router.patch('/chat/messages/:partnerId/read', authMiddleware, chatController.readMessages);

module.exports = router;
