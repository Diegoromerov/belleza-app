// backend/src/tests/youcam.client.integration.test.js
/**
 * Integration tests for YouCam client focusing on resilience behavior.
 * We mock axios to simulate external failures and verify retry behavior.
 */

const youcamClient = require('../services/biometric/youcam.client');
const { breakers } = require('../services/circuitBreakerService');

jest.mock('axios');

describe('YouCamClient Resilience Integration', () => {
  let axiosMock;

  beforeEach(() => {
    axiosMock = require('axios');
    // Set a dummy API key to avoid early throws
    youcamClient.apiKey = 'test-key';
    // Reset the YouCam circuit breaker to avoid cross-test pollution
    breakers.youcam.reset();
    breakers.youcam.failureThreshold = 10; // Allow 4 retries without tripping circuit in this mock test
  });

  afterEach(() => {
    jest.resetAllMocks();
  });

  test('_requestUploadSlot should retry on network error and return fallback value', async () => {
    // Simulate network error on axios.post
    axiosMock.post.mockRejectedValue(new Error('Network Error'));

    const buffer = Buffer.from('test image');

    // The function should return the fallback value after retries are exhausted
    const result = await youcamClient._requestUploadSlot(buffer);

    // Expect the result to match the fallback value
    expect(result).toEqual({
      fileId: 'test-file-id',
      uploadUrl: 'https://example.com/upload',
      uploadHeaders: {}
    });

    // Initial attempt + 3 retries = 4 calls
    expect(axiosMock.post).toHaveBeenCalledTimes(4);
  });

  test('_uploadToS3 should retry on network error and return fallback value', async () => {
    axiosMock.put.mockRejectedValue(new Error('Network Error'));

    const uploadUrl = 'https://s3.example.com/upload';
    const uploadHeaders = {};
    const buffer = Buffer.from('test image');

    const result = await youcamClient._uploadToS3(uploadUrl, uploadHeaders, buffer);

    // The fallback function returns undefined
    expect(result).toBeUndefined();

    expect(axiosMock.put).toHaveBeenCalledTimes(4);
  });

  test('_createAnalysisTask should retry on network error and return fallback value', async () => {
    axiosMock.post.mockRejectedValue(new Error('Network Error'));

    const fileId = 'test-file-id';

    const result = await youcamClient._createAnalysisTask(fileId);

    // The fallback function returns an object with task_id in data.result.task_id, but the function returns the taskId string
    expect(result).toEqual('test-task-id');

    expect(axiosMock.post).toHaveBeenCalledTimes(4);
  });

  test('_pollTaskResult should retry on network error and return fallback value', async () => {
    axiosMock.get.mockRejectedValue(new Error('Network Error'));

    const taskId = 'test-task-id';

    const result = await youcamClient._pollTaskResult(taskId);

    // The fallback function returns an object with data.results, but the function returns the results array
    expect(result).toEqual([
      { type: 'hd_moisture', ui_score: 75 },
      { type: 'hd_wrinkle', ui_score: 15 },
      { type: 'hd_age_spot', ui_score: 12 },
      { type: 'hd_pore', ui_score: 25 },
      { type: 'skin_type', value: 'cálido' },
      { type: 'skin_age', ui_score: 28 }
    ]);

    expect(axiosMock.get).toHaveBeenCalledTimes(4);
  }, 10000);
});