// backend/src/tests/orchestrator.resilience.test.js
const orchestrator = require('../services/biometric/orchestrator');
const youcamClient = require('../services/biometric/youcam.client');
const geminiClient = require('../services/biometric/gemini.client');
const deepseekClient = require('../services/biometric/deepseek.client');
const profileService = require('../services/biometric/profile.service');
const { breakers } = require('../services/circuitBreakerService');

jest.mock('../services/biometric/profile.service');

describe('Biometric Orchestrator - Resilience & TraceId Propagation', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    breakers.youcam.reset();
    breakers.gemini.reset();
    breakers.deepseek.reset();

    profileService.saveProfile.mockResolvedValue({
      id: 999,
      createdAt: new Date().toISOString()
    });
  });

  test('should propagate traceId to YouCam, Gemini, and DeepSeek clients', async () => {
    const traceId = 'test-trace-uuid-12345';
    const analyzeFaceSpy = jest.spyOn(youcamClient, 'analyzeFace').mockResolvedValue({
      hydration: 80, wrinkles: 10, spots: 10, pores: 20, subtono: 'cálido', bioAge: 25
    });
    const analyzeHandsSpy = jest.spyOn(geminiClient, 'analyzeHands').mockResolvedValue({
      manchasSolares: 'leve', sequedad: 'leve', cuticulas: 'sanas', unas: 'sanas', edadAparente: 25
    });
    const generateRecSpy = jest.spyOn(deepseekClient, 'generateRecommendation').mockResolvedValue(
      'Usa ácido hialurónico y protector solar.'
    );
    const toneMatchingSpy = jest.spyOn(deepseekClient, 'getVtoToneMatching').mockResolvedValue({
      lipsticks: [], nails: []
    });

    const result = await orchestrator.analyze(
      1,
      Buffer.from('fake-face'),
      Buffer.from('fake-hands'),
      'ideas',
      null,
      null,
      traceId
    );

    expect(result.profileId).toBe(999);
    expect(analyzeFaceSpy).toHaveBeenCalledWith(expect.any(Buffer), traceId);
    expect(analyzeHandsSpy).toHaveBeenCalledWith(expect.any(Buffer), traceId);

    analyzeFaceSpy.mockRestore();
    analyzeHandsSpy.mockRestore();
    generateRecSpy.mockRestore();
    toneMatchingSpy.mockRestore();
  });

  // El test esperaba "valores por defecto" (hydration 60, manchas 'leve') cuando los dos
  // proveedores caian: DATOS CLINICOS INVENTADOS. Es justo lo que 94b199b45 ("remove
  // simulated results") elimino a proposito. Hoy el orquestador NO fabrica un diagnostico:
  // lanza BIOMETRIC_ANALYSIS_UNAVAILABLE con statusCode 503 (orchestrator.js:28/49/61), que
  // las rutas ya mapean (biometricRoutes.js:95, niaBeautyRoutes.js:47). Devolver una hidratacion
  // de 60 inventada es peor que decir que el analisis no esta disponible.
  // Decision de Diego: ejecutar en su nombre conservando el mejor uso del codigo. Alinear el
  // test al contrato endurecido es lo correcto y no toca produccion.
  test('debe rechazar con BIOMETRIC_ANALYSIS_UNAVAILABLE cuando los dos proveedores caen', async () => {
    const analyzeFaceSpy = jest.spyOn(youcamClient, 'analyzeFace').mockRejectedValue(new Error('YouCam Down'));
    const analyzeHandsSpy = jest.spyOn(geminiClient, 'analyzeHands').mockRejectedValue(new Error('Gemini Down'));

    await expect(
      orchestrator.analyze(1, Buffer.from('fake-face'), Buffer.from('fake-hands'))
    ).rejects.toMatchObject({
      code: 'BIOMETRIC_ANALYSIS_UNAVAILABLE',
      statusCode: 503,
    });

    analyzeFaceSpy.mockRestore();
    analyzeHandsSpy.mockRestore();
  });
});
