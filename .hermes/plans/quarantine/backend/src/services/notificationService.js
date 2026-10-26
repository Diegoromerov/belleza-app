// services/notificationService.js
// Simple stub for sending email/SMS notifications when una oportunidad cambia de etapa.
// En producción integrar con SendGrid, Twilio o servicio similar.

module.exports = {
  async sendStageChangeEmail({ opportunityId, newStage, ownerEmail }) {
    // Aquí se implementaría la lógica real de envío.
    console.log(`[NOTIFY] Oportunidad ${opportunityId} cambió a '${newStage}'. Notificar a ${ownerEmail}`);
    // Simulamos async delay
    return Promise.resolve(true);
  },
};
