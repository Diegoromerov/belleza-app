// backend/tests/crypto.test.js
const { encrypt, decrypt } = require('../src/utils/cryptoHelper');

describe('AES-256-GCM Encryption at Rest Tests', () => {
  test('should encrypt and decrypt string data matching original input', () => {
    const sensitiveData = 'biometric_vector_mesh_3d_user_data_9981';
    const encrypted = encrypt(sensitiveData);

    expect(encrypted).not.toBe(sensitiveData);
    expect(encrypted).toContain(':');

    const decrypted = decrypt(encrypted);
    expect(decrypted).toBe(sensitiveData);
  });

  test('should handle empty or null values gracefully', () => {
    expect(encrypt(null)).toBeNull();
    expect(decrypt(null)).toBeNull();
  });
});
