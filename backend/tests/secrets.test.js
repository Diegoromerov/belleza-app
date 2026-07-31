// backend/tests/secrets.test.js
const { SecretManager } = require('../src/config/secrets');

describe('SecretManager Provider Tests', () => {
  beforeEach(() => {
    delete process.env.TEST_SECRET_KEY;
  });

  test('should return environment variable value when provider is env', async () => {
    process.env.TEST_SECRET_KEY = 'super_secure_env_value';
    const manager = new SecretManager('env');
    const value = await manager.getSecret('TEST_SECRET_KEY');
    expect(value).toBe('super_secure_env_value');
  });

  test('should return mock secret value when provider is mock', async () => {
    const manager = new SecretManager('mock');
    const value = await manager.getSecret('JWT_SECRET');
    expect(value).toBe('mock_secret_val_JWT_SECRET');
  });

  test('should fallback to defaultValue if environment variable is missing', async () => {
    const manager = new SecretManager('env');
    const value = await manager.getSecret('NON_EXISTENT_KEY', 'default_fallback');
    expect(value).toBe('default_fallback');
  });
});
