const MIN_SECRET_LENGTH = 32;

const getJwtSecret = () => {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    if (process.env.NODE_ENV === 'test') {
      return 'test_secret_glowapp_jwt_token_key_at_least_32_chars';
    }
    throw new Error('CRITICAL SECURITY ERROR: JWT_SECRET environment variable is missing.');
  }
  if (secret.length < MIN_SECRET_LENGTH) {
    throw new Error(`CRITICAL SECURITY ERROR: JWT_SECRET must be at least ${MIN_SECRET_LENGTH} characters.`);
  }
  return secret;
};

const toApiRole = (dbRole) => {
  if (dbRole === 'PRESTADOR') return 'provider';
  if (dbRole === 'CLIENTE') return 'client';
  if (dbRole === 'SALON') return 'salon';
  if (dbRole === 'ADMIN') return 'admin';
  return null;
};

module.exports = { getJwtSecret, toApiRole };
