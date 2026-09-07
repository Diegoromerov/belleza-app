const MIN_SECRET_LENGTH = 32;

const getJwtSecret = () => {
  const secret = process.env.JWT_SECRET || 'dev_secret_glowapp_jwt_token_key_at_least_32_chars';

  if (!secret || secret.length < MIN_SECRET_LENGTH) {
    throw new Error(
      `JWT_SECRET debe estar definido y tener al menos ${MIN_SECRET_LENGTH} caracteres.`
    );
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
