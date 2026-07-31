// backend/tests/ephemeral_upload.test.js
const { getSignedUploadUrl, processUpload } = require('../src/controllers/uploadController');

describe('Ephemeral Upload Controller Tests', () => {
  test('should generate signed upload URL and uploadId', async () => {
    const req = { user: { id: 'user_123' } };
    const res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };

    await getSignedUploadUrl(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        success: true,
        data: expect.objectContaining({
          uploadId: expect.stringMatching(/^upl_/),
          signedUrl: expect.any(String),
        }),
      })
    );
  });

  test('should process and purge ephemeral upload', async () => {
    const reqSign = { user: { id: 'user_123' } };
    let jsonResult = {};
    const resSign = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn((data) => { jsonResult = data; }),
    };

    await getSignedUploadUrl(reqSign, resSign);
    const { uploadId } = jsonResult.data;

    const reqProcess = { body: { uploadId } };
    const resProcess = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };

    await processUpload(reqProcess, resProcess);

    expect(resProcess.status).toHaveBeenCalledWith(200);
    expect(resProcess.json).toHaveBeenCalledWith(
      expect.objectContaining({
        success: true,
        message: expect.stringContaining('purgada'),
      })
    );
  });
});
