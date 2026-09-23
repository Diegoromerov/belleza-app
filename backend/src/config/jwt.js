const TEST_SECRET = 'test_secret_glowapp_jwt_token_key_at_least_32_chars';
const DEFAULT_PROD_SECRET = 'glowapp_jwt_production_secure_secret_key_at_least_32_chars';
const MIN_SECRET_LENGTH = 32;

const getJwtSecret = () => {
  const secret = process.env.JWT_SECRET || DEFAULT_PROD_SECRET;
  if (!secret || secret.length < MIN_SECRET_LENGTH) {
    return DEFAULT_PROD_SECRET;
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
