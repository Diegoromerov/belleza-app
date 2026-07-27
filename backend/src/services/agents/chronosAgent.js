// backend/src/services/agents/chronosAgent.js
const { pool } = require('../../config/db');

/**
 * AGENTE CHRONOS: Especialista en Ciclo de Vida del Tratamiento, Hábitos y Re-Booking Proactivo
 */
class ChronosAgent {
  // Cadencia por defecto por categoría de servicio en días
  TREATMENT_LIFECYCLE_DAYS = {
    'uñas': 21,
    'manicura': 21,
    'pedicura': 21,
    'cabello': 30,
    'corte': 30,
    'tinte': 30,
    'piel': 45,
    'limpieza facial': 45,
    'cejas': 21,
    'visajismo': 21
  };

  /**
   * Evalúa si un usuario tiene tratamientos que vencieron o requieren mantenimiento
   * @param {number} userId - ID del usuario
   * @returns {Promise<Object>} Análisis de tratamientos a re-agendar
   */
  async evaluateUserRebooking(userId) {
    const query = `
      SELECT b.id as booking_id, b.booking_date, b.status, s.name as service_name, s.category
      FROM bookings b
      JOIN services s ON b.service_id = s.id
      WHERE b.user_id = $1 AND b.status = 'completed'
      ORDER BY b.booking_date DESC
      LIMIT 5;
    `;

    try {
      const res = await pool.query(query, [userId]);
      if (res.rows.length === 0) {
        return { status: 'no_history', message: 'El usuario no tiene reservas completadas previas.' };
      }

      const now = new Date();
      const pendingMaintenance = [];

      for (const booking of res.rows) {
        const bookingDate = new Date(booking.booking_date);
        const diffDays = Math.floor((now - bookingDate) / (1000 * 60 * 60 * 24));
        const categoryLower = (booking.category || '').toLowerCase();
        
        // Encontrar ciclo en días para esta categoría
        let cycleDays = 30; // por defecto 30 días
        for (const [key, days] of Object.entries(this.TREATMENT_LIFECYCLE_DAYS)) {
          if (categoryLower.includes(key) || booking.service_name.toLowerCase().includes(key)) {
            cycleDays = days;
            break;
          }
        }

        if (diffDays >= cycleDays) {
          pendingMaintenance.push({
            serviceName: booking.service_name,
            category: booking.category,
            daysSinceService: diffDays,
            recommendedCycleDays: cycleDays,
            urgency: diffDays > (cycleDays + 7) ? 'alta' : 'media'
          });
        }
      }

      return {
        status: 'success',
        userId,
        hasPendingMaintenance: pendingMaintenance.length > 0,
        treatmentsDue: pendingMaintenance
      };
    } catch (err) {
      console.error('❌ [CHRONOS Agent] Error evaluando re-agendamiento:', err.message);
      return { status: 'error', message: err.message };
    }
  }
}

module.exports = new ChronosAgent();
