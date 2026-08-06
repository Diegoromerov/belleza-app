// backend/src/tests/auraToolExecutor.test.js
const { pool } = require('../config/db');
const { executeAuraTool, AURA_TOOLS_DEFINITIONS } = require('../services/auraToolExecutor');
const { checkConsent, logAccess } = require('../services/consentService');

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

jest.mock('../services/consentService', () => ({
  checkConsent: jest.fn(),
  logAccess: jest.fn().mockResolvedValue(undefined),
}));

describe('Pruebas unitarias de AURA Tool Executor (auraToolExecutor.js)', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('Debería tener definidas las 8 herramientas principales para el ecosistema de AURA', () => {
    expect(AURA_TOOLS_DEFINITIONS.length).toBe(8);
    const toolNames = AURA_TOOLS_DEFINITIONS.map(t => t.function.name);
    expect(toolNames).toContain('query_user_biometric_profile');
    expect(toolNames).toContain('search_nearby_services');
    expect(toolNames).toContain('check_provider_availability');
    expect(toolNames).toContain('evaluate_user_rebooking');
    expect(toolNames).toContain('recommend_glowstore_products');
    expect(toolNames).toContain('get_provider_b2b_insights');
    expect(toolNames).toContain('search_beauty_knowledge_rag');
    expect(toolNames).toContain('trigger_ui_redirection');
  });

  test('Debería ejecutar trigger_ui_redirection y devolver la etiqueta correcta', async () => {
    const result = await executeAuraTool('trigger_ui_redirection', { moduleKey: 'eyebrow-visagism' }, 1);
    expect(result.status).toBe('success');
    expect(result.redirectionTag).toBe('Redirección Módulo Ideas: eyebrow-visagism');
  });

  test('Debería ejecutar query_user_biometric_profile delegando en ATENA', async () => {
    // Mock consent check
    checkConsent.mockResolvedValue({ granted: true, grantedAt: new Date(), version: '1.0' });
    logAccess.mockResolvedValue(undefined);
    
    pool.query.mockResolvedValueOnce({
      rows: [
        {
          id: 'prof-123',
          user_id: 1,
          face_scores: { hydration: 80 },
          recommendation: 'Usar hidratante facial'
        }
      ]
    });

    const result = await executeAuraTool('query_user_biometric_profile', { userId: 1 }, 1);
    expect(pool.query).toHaveBeenCalled();
    expect(result.status).toBe('success');
    expect(result.recommendationText).toBe('Usar hidratante facial');
  });

  test('Debería ejecutar query_user_biometric_profile y retornar error si no hay consentimiento', async () => {
    // Mock consent check - no consent
    checkConsent.mockResolvedValue({ granted: false });
    logAccess.mockResolvedValue(undefined);
    
    const result = await executeAuraTool('query_user_biometric_profile', { userId: 1 }, 1);
    expect(result.error).toBe('consent_required');
    expect(result.message).toContain('consentimiento biométrico');
  });

  test('Debería ejecutar search_nearby_services delegando en HERMES con PostGIS', async () => {
    pool.query.mockResolvedValueOnce({
      rows: [
        {
          service_id: 'serv-1',
          name: 'Manicura Semipermanente',
          price: 45000,
          business_name: 'Sonia Spa',
          distance_km: 1.2
        }
      ]
    });

    const result = await executeAuraTool('search_nearby_services', { latitude: 4.6097, longitude: -74.0817, category: 'Uñas' }, 1);
    expect(pool.query).toHaveBeenCalled();
    expect(result.status).toBe('success');
    expect(result.foundCount).toBe(1);
    expect(result.services[0].business_name).toBe('Sonia Spa');
  });
});