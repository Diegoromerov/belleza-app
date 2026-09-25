const fs = require('fs');
const path = require('path');

describe('Cargo 2b / C4 — Invarianza de secretos en biometricCryptoService.js', () => {
  const serviceFilePath = path.resolve(__dirname, '../services/biometricCryptoService.js');
  const serviceFileContent = fs.readFileSync(serviceFilePath, 'utf8');

  test('C4: Cero literales de respaldo hardcodeados en biometricCryptoService.js', () => {
    expect(serviceFileContent).not.toContain('glowapp_biometric_fallback');
    expect(serviceFileContent).not.toContain('dev_test_biometric_fallback');
  });

  test('C4: Servicio biométrico falla si falta clave en producción', () => {
    const originalEnv = process.env.NODE_ENV;
    const originalKey = process.env.BIOMETRIC_ENCRYPTION_KEY;
    const originalEnc = process.env.ENCRYPTION_KEY;

    try {
      process.env.NODE_ENV = 'production';
      delete process.env.BIOMETRIC_ENCRYPTION_KEY;
      delete process.env.ENCRYPTION_KEY;

      jest.isolateModules(() => {
        expect(() => {
          require('../services/biometricCryptoService');
        }).toThrow('CRITICAL SECURITY ERROR: BIOMETRIC_ENCRYPTION_KEY required');
      });
    } finally {
      process.env.NODE_ENV = originalEnv;
      if (originalKey) process.env.BIOMETRIC_ENCRYPTION_KEY = originalKey;
      if (originalEnc) process.env.ENCRYPTION_KEY = originalEnc;
    }
  });
});
