// backend/src/services/emailService.js

/**
 * Enviar correo de recuperación de reserva / carrito abandonado
 */
async function sendAbandonedBookingEmail(toEmail, userName, bookingId, serviceName) {
  const checkoutUrl = `https://glowapp-frontend-production.up.railway.app/#/checkout?booking_id=${bookingId}`;
  
  console.log(`📧 [EMAIL TRANSACCIONAL] Preparando correo de recuperación para ${toEmail} (${userName}):`);
  console.log(`   Asunto: ¡Tu cita de ${serviceName} te espera en GlowApp!`);
  console.log(`   Link de Pago Directo: ${checkoutUrl}`);

  // Integración Nodemailer / SendGrid:
  /*
  const nodemailer = require('nodemailer');
  const transporter = nodemailer.createTransport({...});
  await transporter.sendMail({
    from: '"GlowApp" <no-reply@glowapp.com>',
    to: toEmail,
    subject: `¡No pierdas tu cita de ${serviceName}!`,
    html: `<h1>Hola ${userName}</h1><p>Tu reserva de ${serviceName} vence pronto.</p><a href="${checkoutUrl}">Completar Pago Ahora</a>`
  });
  */

  return true;
}

module.exports = {
  sendAbandonedBookingEmail,
};
