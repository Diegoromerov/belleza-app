// backend/src/services/pushNotificationService.js
const { pool } = require('../config/db');

/**
 * Enviar notificación Push a un usuario específico mediante su fcm_token almacenado
 */
async function sendPushToUser(userId, title, body, dataPayload = {}) {
  try {
    const userRes = await pool.query(
      `SELECT id, email, fcm_token FROM usuarios WHERE id = $1 AND is_active = true`,
      [userId]
    );

    if (userRes.rows.length === 0 || !userRes.rows[0].fcm_token) {
      console.log(`⚠️ Push no enviado: Usuario ID ${userId} no tiene token FCM registrado.`);
      return false;
    }

    const fcmToken = userRes.rows[0].fcm_token;
    console.log(`🚀 [Push Notification Payload] Enviando a User ${userId} (Token: ${fcmToken.substring(0, 15)}...):`);
    console.log(`   Título: "${title}" | Cuerpo: "${body}"`);

    return true;
  } catch (err) {
    console.error(`❌ Error enviando Push Notification a usuario ID ${userId}:`, err.message);
    return false;
  }
}

/**
 * Enviar notificación Push masiva por rol (ej: PRESTADOR o CLIENTE)
 */
async function sendPushToRole(role, title, body, dataPayload = {}) {
  try {
    const res = await pool.query(
      `SELECT id, fcm_token FROM usuarios WHERE rol = $1 AND fcm_token IS NOT NULL AND is_active = true`,
      [role.toUpperCase()]
    );

    console.log(`📢 [Push Masivo FCM] Enviando notificación a ${res.rows.length} usuarios con rol ${role}`);
    for (let u of res.rows) {
      await sendPushToUser(u.id, title, body, dataPayload);
    }
    return res.rows.length;
  } catch (err) {
    console.error(`❌ Error en envío masivo de Push Notification por rol ${role}:`, err.message);
    return 0;
  }
}

module.exports = {
  sendPushToUser,
  sendPushToRole,
};
