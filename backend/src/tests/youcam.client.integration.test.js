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

  test('_requestUploadSlot should retry on network error', async () => {
    // Simulate network error on axios.post
    axiosMock.post.mockRejectedValue(new Error('Network Error'));

    const buffer = Buffer.from('test image');

    await expect(youcamClient._requestUploadSlot(buffer))
      .rejects.toThrow('Network Error');

    // Initial attempt + 3 retries = 4 calls
    expect(axiosMock.post).toHaveBeenCalledTimes(4);
  });

  test('_uploadToS3 should retry on network error', async () => {
    axiosMock.put.mockRejectedValue(new Error('Network Error'));

    const uploadUrl = 'https://s3.example.com/upload';
    const uploadHeaders = {};
    const buffer = Buffer.from('test image');

    await expect(youcamClient._uploadToS3(uploadUrl, uploadHeaders, buffer))
      .rejects.toThrow('Network Error');

    expect(axiosMock.put).toHaveBeenCalledTimes(4);
  });

  test('_createAnalysisTask should retry on network error', async () => {
    axiosMock.post.mockRejectedValue(new Error('Network Error'));

    const fileId = 'test-file-id';

    await expect(youcamClient._createAnalysisTask(fileId))
      .rejects.toThrow('Network Error');

    expect(axiosMock.post).toHaveBeenCalledTimes(4);
  });

  test('_pollTaskResult should retry on network error', async () => {
    axiosMock.get.mockRejectedValue(new Error('Network Error'));

    const taskId = 'test-task-id';

    await expect(youcamClient._pollTaskResult(taskId))
      .rejects.toThrow('Network Error');

    expect(axiosMock.get).toHaveBeenCalledTimes(4);
  });
});