// backend/src/tests/sprint3_agents.test.js
const { pool } = require('../config/db');
const chronosAgent = require('../services/agents/chronosAgent');
const hestiaAgent = require('../services/agents/hestiaAgent');
const { executeAuraTool, AURA_TOOLS_DEFINITIONS } = require('../services/auraToolExecutor');

jest.mock('../config/db', () => ({
  pool: {
    query: jest.fn()
  }
}));

jest.mock('../config/redis', () => ({
  isOpen: false,
  get: jest.fn(),
  set: jest.fn()
}));

describe('Pruebas unitarias de Sprint 3 (Agente CHRONOS y Agente HESTIA)', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Agente CHRONOS (Re-booking y Ciclo de Tratamientos)', () => {
    test('Debería identificar cuando una manicura de hace 25 días requiere re-agendamiento (ciclo 21 días)', async () => {
      const pastDate = new Date();
      pastDate.setDate(pastDate.getDate() - 25);

      pool.query.mockResolvedValueOnce({
        rows: [
          {
            booking_id: 'book-999',
            booking_date: pastDate.toISOString(),
            status: 'completed',
            service_name: 'Manicura Semipermanente',
            category: 'Uñas'
          }
        ]
      });

      const result = await chronosAgent.evaluateUserRebooking(1);

      expect(result.status).toBe('success');
      expect(result.hasPendingMaintenance).toBe(true);
      expect(result.treatmentsDue.length).toBe(1);
      expect(result.treatmentsDue[0].serviceName).toBe('Manicura Semipermanente');
      expect(result.treatmentsDue[0].recommendedCycleDays).toBe(21);
    });

    test('Debería manejar usuarios sin historial de citas completadas', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });

      const result = await chronosAgent.evaluateUserRebooking(555);
      expect(result.status).toBe('no_history');
    });
  });

  describe('Agente HESTIA (GlowStore Personal Shopper)', () => {
    test('Debería recomendar productos e-commerce de la tienda', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] }); // Simular fallback de DB

      const result = await hestiaAgent.recommendProducts({ userId: 1, queryText: 'hidratante', category: 'Piel' });

      expect(result.status).toBe('success');
      expect(result.products.length).toBeGreaterThan(0);
      expect(result.products[0].nombre).toContain('Sérum Facial');
    });
  });

  describe('Integración con auraToolExecutor para Sprint 3', () => {
    test('Debería tener registradas al menos 7 herramientas', () => {
      expect(AURA_TOOLS_DEFINITIONS.length).toBeGreaterThanOrEqual(7);
      const names = AURA_TOOLS_DEFINITIONS.map(t => t.function.name);
      expect(names).toContain('evaluate_user_rebooking');
      expect(names).toContain('recommend_glowstore_products');
    });

    test('executeAuraTool debería delegar evaluate_user_rebooking a CHRONOS', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });

      const result = await executeAuraTool('evaluate_user_rebooking', { userId: 3 }, 3);
      expect(result.status).toBe('no_history');
    });

    test('executeAuraTool debería delegar recommend_glowstore_products a HESTIA', async () => {
      pool.query.mockResolvedValueOnce({ rows: [] });

      const result = await executeAuraTool('recommend_glowstore_products', { queryText: 'uñas' }, 3);
      expect(result.status).toBe('success');
      expect(result.products.length).toBeGreaterThan(0);
    });
  });
});
