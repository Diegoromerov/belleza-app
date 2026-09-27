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
  if (secret && secret.length >= MIN_SECRET_LENGTH) {
    return secret;
  }

  if (process.env.NODE_ENV === 'production') {
    throw new Error('JWT_SECRET no configurada o demasiado corta (mínimo 32 caracteres) en entorno de producción.');
  }

  if (!memoizedDevSecret) {
    memoizedDevSecret = crypto.randomBytes(32).toString('hex');
  }
  return memoizedDevSecret;
};

const toApiRole = (dbRole) => {
  if (dbRole === 'PRESTADOR') return 'provider';
  if (dbRole === 'CLIENTE') return 'client';
  if (dbRole === 'SALON') return 'salon';
  if (dbRole === 'ADMIN') return 'admin';
  return null;
};

module.exports = { getJwtSecret, toApiRole };
