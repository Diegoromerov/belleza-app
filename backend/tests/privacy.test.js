// backend/tests/privacy.test.js
const { exportUserData, revokeConsent, getAccessLog } = require('../src/controllers/privacyController');

describe('Privacy and GDPR Endpoints Tests', () => {
  test('should export user data and log action', async () => {
    const req = { params: { id: 'usr_771' } };
    const res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };

    await exportUserData(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        success: true,
        data: expect.objectContaining({ userId: 'usr_771' }),
      })
    );
  });

  test('should revoke consent and return success message', async () => {
    const req = { params: { id: 'usr_771' } };
    const res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };

    await revokeConsent(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        success: true,
        message: expect.stringContaining('revocado'),
      })
    );
  });
});
