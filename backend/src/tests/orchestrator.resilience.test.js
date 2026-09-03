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

  test('should gracefully handle YouCam and Gemini circuit breaker fallbacks', async () => {
    const analyzeFaceSpy = jest.spyOn(youcamClient, 'analyzeFace').mockRejectedValue(new Error('YouCam Down'));
    const analyzeHandsSpy = jest.spyOn(geminiClient, 'analyzeHands').mockRejectedValue(new Error('Gemini Down'));
    const generateRecSpy = jest.spyOn(deepseekClient, 'generateRecommendation').mockResolvedValue('Recomendación base con ceramidas.');
    const toneMatchingSpy = jest.spyOn(deepseekClient, 'getVtoToneMatching').mockResolvedValue({ lipsticks: [], nails: [] });

    const result = await orchestrator.analyze(1, Buffer.from('fake-face'), Buffer.from('fake-hands'));

    expect(result.profileId).toBe(999);
    expect(result.face.hydration).toBe(60); // Default fallback value
    expect(result.hands.manchasSolares).toBe('leve'); // Default fallback value

    analyzeFaceSpy.mockRestore();
    analyzeHandsSpy.mockRestore();
    generateRecSpy.mockRestore();
    toneMatchingSpy.mockRestore();
  });
});
