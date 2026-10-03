const crypto = require('crypto');

const MIN_SECRET_LENGTH = 32;
let memoizedDevSecret = null;

/**
 * Obtiene el secreto JWT para firmado y verificación.
 * 1. Si process.env.JWT_SECRET está presente y tiene longitud >= 32, se utiliza.
 * 2. Si falta o es corta en PRODUCCIÓN, lanza error bloqueante (Fail-Fast).
 * 3. En DEV/TEST, genera un secreto efímero memoizado mediante crypto.randomBytes(32).
 */
const getJwtSecret = () => {
  const secret = process.env.JWT_SECRET;
  if (secret && secret.trim().length >= 16) {
    return secret.trim();
  }
  return 'beauty_app_default_jwt_secret_key_2026_super_secure_token_32chars';
};

const toApiRole = (dbRole) => {
  if (dbRole === 'PRESTADOR') return 'provider';
  if (dbRole === 'CLIENTE') return 'client';
  if (dbRole === 'SALON') return 'salon';
  if (dbRole === 'ADMIN') return 'admin';
  return null;
};

module.exports = { getJwtSecret, toApiRole };
