// backend/src/services/agents/chronosAgent.js
const { pool } = require('../../config/db');
const { ESTADO_COMPLETADO } = require('./bookingStateConstants');

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
   * @param {number|string} userId - ID del usuario
   * @returns {Promise<Object>} Análisis de tratamientos a re-agendar
   */
  async evaluateUserRebooking(userId) {
    const parsedUserId = parseInt(userId, 10);
    if (isNaN(parsedUserId)) {
      return { status: 'error', message: 'userId inválido' };
    }

    const query = `
      SELECT b.id as booking_id, b.scheduled_at as booking_date, b.estado as status, s.name as service_name, s.tag_especialidad as category
      FROM bookings b
      JOIN services s ON b.service_id = s.id
      WHERE b.client_id = $1 AND b.estado = $2
      ORDER BY b.scheduled_at DESC
      LIMIT 5;
    `;

    try {
      const res = await pool.query(query, [parsedUserId, ESTADO_COMPLETADO]);
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
        userId: parsedUserId,
        hasPendingMaintenance: pendingMaintenance.length > 0,
        treatmentsDue: pendingMaintenance
      };
    } catch (err) {
      console.error('❌ [CHRONOS Agent] Error evaluando re-agendamiento:', err.message);
      return { status: 'error', message: err.message };
    }
  }

  /**
   * Obtiene la fecha local en formato YYYY-MM-DD para la zona horaria especificada (por defecto Colombia)
   * @param {Date|string|number} date 
   * @param {string} timeZone 
   * @returns {string} Fecha en formato YYYY-MM-DD
   */
  getLocalDateString(date = new Date(), timeZone = 'America/Bogota') {
    const d = date instanceof Date ? date : new Date(date);
    return new Intl.DateTimeFormat('sv-SE', { timeZone }).format(d);
  }

  /**
   * Evalúa la continuidad temporal de un Glow Cycle activo o en re-evaluación
   * @param {Object} cycle - Entidad GlowCycle
   * @returns {Object} Estado temporal, recordatorios pendientes e hitos
   */
  evaluateCycleContinuity(cycle) {
    const ALLOWED_STATUSES = ['active', 'reassessment_due'];
    if (!cycle || !ALLOWED_STATUSES.includes(cycle.status)) {
      return {
        hasActiveContinuity: false,
        temporalState: cycle?.status === 'completed' ? 'GRADUATION_READY' : 'NO_CYCLE',
        message: 'No hay ciclo activo en curso.'
      };
    }

    const startDate = new Date(cycle.start_date || cycle.created_at || Date.now());
    const now = new Date();
    const currentDay = Math.max(1, Math.floor((now - startDate) / (1000 * 60 * 60 * 24)) + 1);
    const durationDays = cycle.duration_days || 30;

    // Evaluar check-in de hoy en zona horaria local (America/Bogota)
    const todayStr = this.getLocalDateString(now, 'America/Bogota');
    const checkins = Array.isArray(cycle.checkin_history) ? cycle.checkin_history : [];
    const todayCheckin = checkins.find(c => {
      if (!c) return false;
      const cDate = c.date ? this.getLocalDateString(c.date, 'America/Bogota') : null;
      return cDate === todayStr || c.date === todayStr;
    });

    const isAmCompleted = !!(todayCheckin && (todayCheckin.amCompleted === true || todayCheckin.am_completed === true));
    const isPmCompleted = !!(todayCheckin && (todayCheckin.pmCompleted === true || todayCheckin.pm_completed === true));
    const isStatusCompleted = !!(todayCheckin && (todayCheckin.status === 'completed' || todayCheckin.estado === 'completed'));

    const isTodayCheckinCompleted = isStatusCompleted || (isAmCompleted && isPmCompleted);
    const isPartialCheckin = (isAmCompleted && !isPmCompleted) || (!isAmCompleted && isPmCompleted);

    // Verificar si los hitos de re-scan ya fueron registrados en la entidad cycle
    const hasDay15Rescan = !!(
      (Array.isArray(cycle.rescan_history) && cycle.rescan_history.some(r => r && (r.day === 15 || r.milestone === 15 || r.type === 'day15'))) ||
      (Array.isArray(cycle.rescan_dates) && cycle.rescan_dates.some(d => String(d).includes('day15') || d?.day === 15)) ||
      (Array.isArray(cycle.rescans) && cycle.rescans.some(r => r && (r.day === 15 || r.milestone === 15))) ||
      (Array.isArray(cycle.measurements) && cycle.measurements.some(m => m && (m.day === 15 || m.milestone === 15 || m.day_number === 15 || (m.day_number >= 14 && m.day_number <= 18))))
    );

    const hasDay30Rescan = !!(
      (Array.isArray(cycle.rescan_history) && cycle.rescan_history.some(r => r && (r.day === 30 || r.milestone === 30 || r.type === 'day30' || r.is_final))) ||
      (Array.isArray(cycle.rescan_dates) && cycle.rescan_dates.some(d => String(d).includes('day30') || d?.day === 30)) ||
      (Array.isArray(cycle.rescans) && cycle.rescans.some(r => r && (r.day === 30 || r.milestone === 30))) ||
      (Array.isArray(cycle.measurements) && cycle.measurements.some(m => m && (m.day === 30 || m.milestone === 30 || m.day_number >= 30)))
    );

    let temporalState = 'IN_PROGRESS_AM_PM';
    let actionRequired = 'today_routine_checkin';
    let reminderMessage = 'Recuerda completar los pasos de tu rutina AM/PM de hoy.';

    if (cycle.status === 'reassessment_due') {
      temporalState = 'REASSESSMENT_REQUIRED';
      actionRequired = 'perform_reassessment';
      reminderMessage = 'Se requiere una re-evaluación del ciclo para ajustar tu tratamiento.';
    } else if (currentDay >= durationDays) {
      if (hasDay30Rescan) {
        temporalState = 'GRADUATION_READY';
        actionRequired = 'graduation_review';
        reminderMessage = 'Re-escaneo final completado. Tu ciclo está listo para graduación.';
      } else {
        temporalState = 'DAY_30_FINAL_RESCAN';
        actionRequired = 'final_rescan_and_graduation';
        reminderMessage = '¡Día 30 alcanzado! Realiza tu re-escaneo final para graduar tu ciclo.';
      }
    } else if (currentDay >= 15 && currentDay < 18) {
      if (hasDay15Rescan) {
        temporalState = 'MILESTONE_15D_COMPLETED';
        actionRequired = 'today_routine_checkin';
        reminderMessage = 'Hito del Día 15 completado exitosamente. Continúa con tu rutina AM/PM.';
      } else {
        temporalState = 'DAY_15_RESCAN_DUE';
        actionRequired = 'milestone_15d_rescan';
        reminderMessage = 'Hito del Día 15 listo: realiza tu re-escaneo para evaluar el avance y adaptar tu rutina.';
      }
    } else if (currentDay === 1) {
      temporalState = 'DAY_1_BASELINE';
      actionRequired = 'initial_habits_start';
      reminderMessage = 'Primer día de tu Glow Cycle. Inicia con tu rutina matutina y nocturna.';
    }

    return {
      hasActiveContinuity: true,
      cycleId: cycle.id,
      currentDayNumber: currentDay,
      durationDays,
      temporalState,
      actionRequired,
      reminderMessage,
      isTodayCheckinCompleted,
      isAmCompleted,
      isPmCompleted,
      isPartialCheckin,
      nextMilestoneDay: currentDay < 15 ? 15 : (currentDay < durationDays ? durationDays : durationDays)
    };
  }
}

module.exports = new ChronosAgent();
