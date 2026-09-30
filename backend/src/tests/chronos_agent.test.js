// backend/src/tests/chronos_agent.test.js
const chronosAgent = require('../services/agents/chronosAgent');

describe('CHRONOS Agent — Suite de Refactorización Técnica (Glow IA+)', () => {
  describe('1. Zona Horaria Local (America/Bogota)', () => {
    test('getLocalDateString debería retornar formato YYYY-MM-DD en la zona horaria de Colombia', () => {
      // 2026-09-30T03:00:00.000Z es 2026-09-29T22:00:00.000-05:00 en Colombia
      const dateUtc = new Date('2026-09-30T03:00:00.000Z');
      const dateStringBogota = chronosAgent.getLocalDateString(dateUtc, 'America/Bogota');
      expect(dateStringBogota).toBe('2026-09-29');
    });
  });

  describe('2. Verificación de Hito de Re-scan Realizado', () => {
    test('Un ciclo en día 16 con re-scan del hito 15 registrado NO debe exigir DAY_15_RESCAN_DUE', () => {
      const sixteenDaysAgo = new Date(Date.now() - 16 * 24 * 60 * 60 * 1000);
      const cycle = {
        id: 'cycle-101',
        status: 'active',
        start_date: sixteenDaysAgo.toISOString(),
        duration_days: 30,
        measurements: [{ milestone: 15, date: '2026-09-29' }]
      };

      const result = chronosAgent.evaluateCycleContinuity(cycle);
      expect(result.hasActiveContinuity).toBe(true);
      expect(result.temporalState).toBe('MILESTONE_15D_COMPLETED');
      expect(result.actionRequired).not.toBe('milestone_15d_rescan');
    });

    test('Un ciclo en día 30 con re-scan final registrado debe retornar GRADUATION_READY', () => {
      const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      const cycle = {
        id: 'cycle-300',
        status: 'active',
        start_date: thirtyDaysAgo.toISOString(),
        duration_days: 30,
        rescan_history: [{ day: 30, is_final: true }]
      };

      const result = chronosAgent.evaluateCycleContinuity(cycle);
      expect(result.hasActiveContinuity).toBe(true);
      expect(result.temporalState).toBe('GRADUATION_READY');
      expect(result.actionRequired).toBe('graduation_review');
    });
  });

  describe('3. Verificación Efectiva de Check-in AM/PM', () => {
    test('Un check-in parcial (solo AM completado) debe retornar isTodayCheckinCompleted: false e isPartialCheckin: true', () => {
      const todayStr = chronosAgent.getLocalDateString(new Date(), 'America/Bogota');
      const cycle = {
        id: 'cycle-102',
        status: 'active',
        start_date: new Date().toISOString(),
        duration_days: 30,
        checkin_history: [
          { date: todayStr, amCompleted: true, pmCompleted: false }
        ]
      };

      const result = chronosAgent.evaluateCycleContinuity(cycle);
      expect(result.isTodayCheckinCompleted).toBe(false);
      expect(result.isAmCompleted).toBe(true);
      expect(result.isPmCompleted).toBe(false);
      expect(result.isPartialCheckin).toBe(true);
    });

    test('Un check-in completo (AM y PM) debe retornar isTodayCheckinCompleted: true e isPartialCheckin: false', () => {
      const todayStr = chronosAgent.getLocalDateString(new Date(), 'America/Bogota');
      const cycle = {
        id: 'cycle-103',
        status: 'active',
        start_date: new Date().toISOString(),
        duration_days: 30,
        checkin_history: [
          { date: todayStr, amCompleted: true, pmCompleted: true }
        ]
      };

      const result = chronosAgent.evaluateCycleContinuity(cycle);
      expect(result.isTodayCheckinCompleted).toBe(true);
      expect(result.isAmCompleted).toBe(true);
      expect(result.isPmCompleted).toBe(true);
      expect(result.isPartialCheckin).toBe(false);
    });
  });

  describe('4. Soporte de Estados de Ciclo (active y reassessment_due)', () => {
    test('Un ciclo con estado reassessment_due debe ser aceptado y retornar REASSESSMENT_REQUIRED', () => {
      const cycle = {
        id: 'cycle-104',
        status: 'reassessment_due',
        start_date: new Date().toISOString(),
        duration_days: 30
      };

      const result = chronosAgent.evaluateCycleContinuity(cycle);
      expect(result.hasActiveContinuity).toBe(true);
      expect(result.temporalState).toBe('REASSESSMENT_REQUIRED');
      expect(result.actionRequired).toBe('perform_reassessment');
    });

    test('Un ciclo con estado inactivo o desconocido debe retornar hasActiveContinuity: false', () => {
      const cycle = {
        id: 'cycle-105',
        status: 'paused',
        start_date: new Date().toISOString()
      };

      const result = chronosAgent.evaluateCycleContinuity(cycle);
      expect(result.hasActiveContinuity).toBe(false);
      expect(result.temporalState).toBe('NO_CYCLE');
    });
  });
});
