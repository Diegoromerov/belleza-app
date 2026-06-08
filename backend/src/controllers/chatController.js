// backend/src/controllers/chatController.js
const { pool } = require('../config/db');
const { processAssistantMessage, AI_USER_ID } = require('../services/geminiService');

// GET /api/chat/conversations → Listar conversaciones activas
exports.getConversations = async (req, res) => {
  try {
    const userId = req.user.id;

    const query = `
      SELECT DISTINCT ON (conversation_partner_id)
        m.conversation_partner_id,
        u.nombre as partner_name,
        u.foto_url as partner_avatar,
        CASE WHEN u.rol = 'PRESTADOR' THEN 'provider' ELSE 'client' END as partner_role,
        m.message as last_message,
        m.created_at as last_message_time,
        m.sender_id,
        (
          SELECT COUNT(*)::int 
          FROM messages 
          WHERE sender_id = m.conversation_partner_id 
            AND receiver_id = $1 
            AND is_read = false
        ) as unread_count
      FROM (
        SELECT 
          CASE WHEN sender_id = $1 THEN receiver_id ELSE sender_id END as conversation_partner_id,
          message,
          created_at,
          sender_id
        FROM messages
        WHERE sender_id = $1 OR receiver_id = $1
        ORDER BY created_at DESC
      ) m
      JOIN usuarios u ON u.id = m.conversation_partner_id
      ORDER BY m.conversation_partner_id, m.created_at DESC;
    `;

    const result = await pool.query(query, [userId]);
    
    const conversations = result.rows.map(row => ({
      ...row,
      conversation_partner_id: row.conversation_partner_id.toString()
    }));

    conversations.sort((a, b) => new Date(b.last_message_time) - new Date(a.last_message_time));

    res.json({
      success: true,
      count: conversations.length,
      data: conversations
    });
  } catch (error) {
    console.error('❌ ERROR EN GET /api/chat/conversations:', error);
    res.status(500).json({ error: 'Error al obtener conversaciones' });
  }
};

// GET /api/chat/messages/:partnerId → Historial de mensajes con un socio
exports.getMessages = async (req, res) => {
  try {
    const userId = req.user.id;
    const partnerId = req.params.partnerId;
    const resolvedPartnerId = (partnerId === '0' || partnerId === '00000000-0000-0000-0000-000000000000' || partnerId === AI_USER_ID.toString()) ? 0 : parseInt(partnerId);

    const query = `
      SELECT id, sender_id, receiver_id, message, is_read, created_at
      FROM messages
      WHERE (sender_id = $1 AND receiver_id = $2)
         OR (sender_id = $2 AND receiver_id = $1)
      ORDER BY created_at ASC;
    `;
    const result = await pool.query(query, [userId, resolvedPartnerId]);
    
    const formattedMessages = result.rows.map(row => ({
      ...row,
      sender_id: row.sender_id.toString(),
      receiver_id: row.receiver_id.toString()
    }));

    res.json({
      success: true,
      count: formattedMessages.length,
      data: formattedMessages
    });
  } catch (error) {
    console.error('❌ ERROR EN GET /api/chat/messages/:partnerId:', error);
    res.status(500).json({ error: 'Error al obtener mensajes' });
  }
};

// POST /api/chat/messages → Enviar un mensaje
exports.sendMessage = async (req, res) => {
  try {
    const senderId = req.user.id;
    const { receiver_id, message, image_path } = req.body;

    if (!receiver_id || !message || message.trim() === '') {
      return res.status(400).json({ error: 'receiver_id y message son obligatorios' });
    }

    const targetReceiver = (receiver_id === '0' || receiver_id === '00000000-0000-0000-0000-000000000000' || receiver_id === AI_USER_ID.toString()) ? 0 : parseInt(receiver_id);

    // Sistema de Detección y Prevención de Evasión (Anti-Circumvention Filter)
    const normalizedMsg = message.replace(/[\s\-\.\(\)]/g, '');
    const containsPhone = /3[0-9]{9}|60[0-9]{8}/.test(normalizedMsg);
    const containsEmail = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/.test(message);
    const containsSocial = /@[a-zA-Z0-9_._]+/.test(message);
    
    const forbiddenPatterns = [
      'por fuera', 'pago directo', 'pago en efectivo', 'efectivo directo', 
      'whatsapp', 'wpp', 'escríbame', 'escribame', 'nequi directo', 
      'transferencia directa', 'llámeme', 'llamame', 'escríbeme', 'escribeme',
      'mi cel', 'mi número', 'mi numero', 'número de contacto', 'numero de contacto'
    ];
    
    const lowerMessage = message.toLowerCase();
    const containsForbiddenPattern = forbiddenPatterns.some(pat => lowerMessage.includes(pat));

    if (targetReceiver !== 0) {
      if (containsPhone || containsEmail || containsSocial || containsForbiddenPattern) {
        return res.status(400).json({ 
          error: 'Por motivos de seguridad y políticas de la plataforma, no está permitido compartir información de contacto directo (teléfonos, correos, redes sociales) ni negociar pagos externos fuera de la aplicación. Por favor, mantenga su comunicación y transacciones dentro de Belleza App.' 
        });
      }
    }

    const query = `
      INSERT INTO messages (sender_id, receiver_id, message)
      VALUES ($1, $2, $3)
      RETURNING id, sender_id, receiver_id, message, is_read, created_at;
    `;
    const result = await pool.query(query, [senderId, targetReceiver, message.trim()]);
    
    const formatted = {
      ...result.rows[0],
      sender_id: result.rows[0].sender_id.toString(),
      receiver_id: result.rows[0].receiver_id.toString()
    };

    res.status(201).json({
      success: true,
      data: formatted
    });

    if (targetReceiver === 0) {
      processAssistantMessage(senderId, message.trim(), image_path).catch(err => {
        console.error('❌ Error en procesamiento asíncrono del Asistente de IA:', err);
      });
    }

  } catch (error) {
    console.error('❌ ERROR EN POST /api/chat/messages:', error);
    res.status(500).json({ error: 'Error al enviar el mensaje' });
  }
};

// PATCH /api/chat/messages/:partnerId/read → Marcar mensajes recibidos como leídos
exports.readMessages = async (req, res) => {
  try {
    const userId = req.user.id;
    const partnerId = req.params.partnerId;
    const resolvedPartnerId = (partnerId === '0' || partnerId === '00000000-0000-0000-0000-000000000000' || partnerId === AI_USER_ID.toString()) ? 0 : parseInt(partnerId);

    const query = `
      UPDATE messages
      SET is_read = true
      WHERE sender_id = $1 AND receiver_id = $2 AND is_read = false
      RETURNING id;
    `;
    const result = await pool.query(query, [resolvedPartnerId, userId]);
    res.json({
      success: true,
      count: result.rows.length
    });
  } catch (error) {
    console.error('❌ ERROR EN PATCH /api/chat/messages/:partnerId/read:', error);
    res.status(500).json({ error: 'Error al marcar mensajes como leídos' });
  }
};
