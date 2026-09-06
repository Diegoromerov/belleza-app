// backend/src/tests/auraToolExecutor.test.js
jest.mock('../services/agents/atenaAgent');
jest.mock('../services/agents/hestiaAgent');
jest.mock('../services/agents/hermesAgent');
jest.mock('../services/agents/chronosAgent');
jest.mock('../services/agents/valkyrieAgent');
jest.mock('../services/ragService');
jest.mock('../config/db');
jest.mock('../config/redis');
jest.mock('../services/consentService');

let executeAuraTool;
let AURA_TOOLS_DEFINITIONS;
let atenaAgent;
let hestiaAgent;
let hermesAgent;
let chronosAgent;
let valkyrieAgent;
let ragService;
let dbPool;
let redisMock;
let consentService;

beforeEach(() => {
  jest.clearAllMocks();
  process.env.BIOMETRIC_ENCRYPTION_KEY = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  // Require the module after mocks are set
  const auraToolExecutor = require('../services/auraToolExecutor');
  executeAuraTool = auraToolExecutor.executeAuraTool;
  AURA_TOOLS_DEFINITIONS = auraToolExecutor.AURA_TOOLS_DEFINITIONS;

  // Get mocks
  atenaAgent = require('../services/agents/atenaAgent');
  hestiaAgent = require('../services/agents/hestiaAgent');
  hermesAgent = require('../services/agents/hermesAgent');
  chronosAgent = require('../services/agents/chronosAgent');
  valkyrieAgent = require('../services/agents/valkyrieAgent');
  ragService = require('../services/ragService');
  dbPool = require('../config/db');
  redisMock = require('../config/redis');
  consentService = require('../services/consentService');
});

describe('Pruebas unitarias de AURA Tool Executor (auraToolExecutor.js)', () => {
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
    consentService.checkConsent.mockResolvedValue({ granted: true, grantedAt: new Date(), version: '1.0' });
    consentService.logAccess.mockResolvedValue(undefined);

    const mockProfile = {
      id: 'prof-123',
      user_id: 1,
      face_scores: { hydration: 80 },
      recommendation: 'Usar hidratante facial'
    };
    atenaAgent.getBiometricDiagnosis.mockResolvedValue(mockProfile);

    // Note: The implementation does NOT use pool.query for this tool; it calls the agent directly.
    const result = await executeAuraTool('query_user_biometric_profile', { userId: 1 }, 1);
    expect(atenaAgent.getBiometricDiagnosis).toHaveBeenCalledWith(1);
    expect(result.status).toBe('success');
    expect(result.recommendationText).toBe('Usar hidratante facial');
  });

  test('Debería ejecutar query_user_biometric_profile y retornar error si no hay consentimiento', async () => {
    // Mock consent check - no consent
    consentService.checkConsent.mockResolvedValue({ granted: false });
    consentService.logAccess.mockResolvedValue(undefined);

    const result = await executeAuraTool('query_user_biometric_profile', { userId: 1 }, 1);
    expect(result.error).toBe('consent_required');
    expect(result.message).toContain('consentimiento biométrico');
  });

  // NEW: Ownership test for query_user_biometric_profile - should fail when userId in args does not match context userId
  test('Debería denegar query_user_biometric_profile cuando el userId solicitado no coincide con el contexto de autenticación', async () => {
    // Context userId is 1 (third argument), but args.userId is 2
    const result = await executeAuraTool('query_user_biometric_profile', { userId: 2 }, 1);
    expect(result.error).toBe('ownership_required');
    expect(result.message).toBe('No tienes permisos para acceder a los datos biométricos de otro usuario.');
    // Ensure no further processing (consent check, agent call, DB query)
    expect(consentService.checkConsent).not.toHaveBeenCalled();
    expect(atenaAgent.getBiometricDiagnosis).not.toHaveBeenCalled();
    expect(dbPool.query).not.toHaveBeenCalled();
  });

  test('Debería ejecutar search_nearby_services delegando en HERMES con PostGIS', async () => {
    // Mock the agent
    hermesAgent.findNearbyServices.mockResolvedValue({
      status: 'success',
      foundCount: 1,
      services: [
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
    expect(hermesAgent.findNearbyServices).toHaveBeenCalledWith({
      latitude: 4.6097,
      longitude: -74.0817,
      category: 'Uñas',
      maxDistanceKm: undefined // default
    });
    expect(result.status).toBe('success');
    expect(result.foundCount).toBe(1);
    expect(result.services[0].business_name).toBe('Sonia Spa');
  });

  // NEW: Test for recommend_glowstore_products (positive case - own user)
  test('Debería ejecutar recommend_glowstore_products delegando en HESTIA (usuario propio)', async () => {
    // Mock consent check for the biometric profile query (internal call) - actually, recommend_glowstore_products does NOT check consent, only ownership.
    // We'll still mock it to avoid any accidental calls, but we expect it not to be called.
    consentService.checkConsent.mockResolvedValue({ granted: true, grantedAt: new Date(), version: '1.0' });
    consentService.logAccess.mockResolvedValue(undefined);

    // Mock the agent: atenaAgent.getBiometricDiagnosis (called internally by hestiaAgent)
    atenaAgent.getBiometricDiagnosis.mockResolvedValue({
      faceScores: { hydration: 70, spots: 20, wrinkles: 10 },
      recommendation: 'Usar hidratante facial'
    });

    // Mock the agent: hestiaAgent.recommendProducts
    const recommendedProducts = [
      { id: 1, name: 'Product A', brand: 'BrandX' },
      { id: 2, name: 'Product B', brand: 'BrandY' }
    ];
    hestiaAgent.recommendProducts.mockResolvedValue(recommendedProducts);

    // Execute the tool: context userId = 1, args.userId = 1 (own user)
    const result = await executeAuraTool('recommend_glowstore_products', { userId: 1, /* other args */ }, 1);

    // Expect success: the result is the array of products (as returned by hestiaAgent)
    expect(result).toEqual(recommendedProducts);

    // Verify internal calls: 
    // 1. Ownership check passed, so we proceeded to call atenaAgent.getBiometricDiagnosis with the userId (1)
    expect(atenaAgent.getBiometricDiagnosis).toHaveBeenCalledWith(1);
    // 2. Then hestiaAgent.recommendProducts was called with the result from atenaAgent (which includes userId? 
    //    Actually, in auraToolExecutor.js we do:
    //      const biometricProfile = await atenaAgent.getBiometricDiagnosis(userId);
    //      return hestiaAgent.recommendProducts({ userId, ...biometricProfile });
    //    So we expect hestiaAgent.recommendProducts to be called with an object that has userId: 1 and the faceScores, etc.
    expect(hestiaAgent.recommendProducts).toHaveBeenCalledWith(
      expect.objectContaining({ userId: 1 })
    );
  });

  // NEW: Ownership test for recommend_glowstore_products - should fail when userId in args does not match context userId
  test('Debería denegar recommend_glowstore_products cuando el userId solicitado no coincide con el contexto de autenticación', async () => {
    // Context userId is 1 (third argument), but args.userId is 2
    const result = await executeAuraTool('recommend_glowstore_products', { userId: 2 }, 1);
    expect(result.error).toBe('ownership_required');
    expect(result.message).toBe('No tienes permisos para acceder a los datos biométricos de otro usuario.');
    // Ensure no further processing
    expect(consentService.checkConsent).not.toHaveBeenCalled();
    expect(atenaAgent.getBiometricDiagnosis).not.toHaveBeenCalled();
    expect(hestiaAgent.recommendProducts).not.toHaveBeenCalled();
  });

  // Additional tests for other tools can be added if needed, but the focus is on ownership.
});