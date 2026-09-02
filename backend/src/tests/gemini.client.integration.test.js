// backend/src/tests/gemini.client.integration.test.js
/**
 * Integration tests for Gemini client focusing on resilience behavior.
 * We mock axios to simulate external failures and verify retry behavior.
 */

jest.mock('axios');
const geminiClient = require('../services/biometric/gemini.client');
const { breakers } = require('../services/circuitBreakerService');

describe('GeminiClient Resilience Integration', () => {
  let axiosMock;

  beforeEach(() => {
    axiosMock = require('axios');
    // Set a dummy API key to avoid early throws
    geminiClient.apiKey = 'test-key';
    // Reset the Gemini circuit breaker to avoid cross-test pollution
    breakers.gemini.reset();
    breakers.gemini.failureThreshold = 10;
  });

  afterEach(() => {
    jest.resetAllMocks();
  });

  test('analyzeHands should retry on network error and return fallback', async () => {
    // Simulate network error on axios.post
    axiosMock.post.mockRejectedValue(new Error('Network Error'));

    const imageBase64 = 'base64image';

    // The method should return the fallback because the resilience service will exhaust retries and throw,
    // and the client catches the error and returns the fallback.
    const result = await geminiClient.analyzeHands(imageBase64);
    expect(result).toEqual({
      manchasSolares: 'leve',
      sequedad: 'moderada',
      cuticulas: 'sanas',
      unas: 'sanas',
      edadAparente: 35,
    });

    // Initial attempt + 3 retries = 4 calls
    expect(axiosMock.post).toHaveBeenCalledTimes(4);
  });

  test('generateRecommendation should retry on network error and return fallback', async () => {
    axiosMock.post.mockRejectedValue(new Error('Network Error'));

    const faceScores = { hydration: 50, wrinkles: 30, spots: 20, pores: 40, subtono: 'cálido', bioAge: 25 };
    const handsDiagnosis = { manchasSolares: 'leve', sequedad: 'moderada', cuticulas: 'sanas', unas: 'sanas', edadAparente: 30 };

    const result = await geminiClient.generateRecommendation(faceScores, handsDiagnosis);
    expect(result).toContain('**Diagnóstico general**');
    expect(result).toContain('¡La constancia es el secreto de una piel saludable!');

    expect(axiosMock.post).toHaveBeenCalledTimes(4);
  });
});