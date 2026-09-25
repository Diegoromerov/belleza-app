const fs = require('fs');
const path = require('path');
const { getJwtSecret } = require('../config/jwt');

describe('Cargo 2b / C3 — Invarianza de secretos en jwt.js', () => {
  const jwtFilePath = path.resolve(__dirname, '../config/jwt.js');
  const jwtFileContent = fs.readFileSync(jwtFilePath, 'utf8');

  test('C3: Ocurrencias de DEFAULT_PROD_SECRET en jwt.js debe ser exactamente 0', () => {
    const matches = (jwtFileContent.match(/DEFAULT_PROD_SECRET/g) || []).length;
    expect(matches).toBe(0);
  });

  test('C3: getJwtSecret() lanza excepción crítica si JWT_SECRET no está definida en producción', () => {
    const originalEnv = process.env.NODE_ENV;
    const originalSecret = process.env.JWT_SECRET;
    try {
      process.env.NODE_ENV = 'production';
      delete process.env.JWT_SECRET;
      expect(() => getJwtSecret()).toThrow('CRITICAL SECURITY ERROR: JWT_SECRET environment variable is missing.');
    } finally {
      process.env.NODE_ENV = originalEnv;
      process.env.JWT_SECRET = originalSecret;
    }
  });
});
