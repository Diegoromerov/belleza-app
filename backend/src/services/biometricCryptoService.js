const crypto = require('crypto');

const ALGORITHM = 'aes-256-gcm';

let dynamicTestKey;
function getDynamicTestKey() {
  if (!dynamicTestKey) {
    dynamicTestKey = crypto.randomBytes(32);
  }
  return dynamicTestKey;
}

const getLegacySecret = () => {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    if (process.env.NODE_ENV === 'test') {
      return getDynamicTestKey().toString('hex');
    }
    throw new Error('CRITICAL SECURITY ERROR: JWT_SECRET required for legacy biometric decryption.');
  }
  return secret;
};

const CLAVE_LEGADA = () =>
  crypto.createHash('sha256')
    .update(getLegacySecret())
    .digest();

let SECRET_KEY;

function initializeKey() {
  const keyEnv = process.env.BIOMETRIC_ENCRYPTION_KEY || process.env.ENCRYPTION_KEY;
  if (!keyEnv || typeof keyEnv !== 'string') {
    if (process.env.NODE_ENV === 'test') {
      SECRET_KEY = getDynamicTestKey();
      return;
    }
    throw new Error(
      'CRITICAL SECURITY ERROR: BIOMETRIC_ENCRYPTION_KEY required. ' +
      'El cifrado de datos biométricos no puede derivar de literales por defecto. ' +
      'Provisiona la clave (o ENCRYPTION_KEY) en las variables de entorno.'
    );
  }

  let keyBuffer;
  if (/^[0-9a-fA-F]{64}$/.test(keyEnv.trim())) {
    keyBuffer = Buffer.from(keyEnv.trim(), 'hex');
  } else if (Buffer.byteLength(keyEnv, 'utf8') === 32) {
    keyBuffer = Buffer.from(keyEnv, 'utf8');
  } else {
    if (process.env.NODE_ENV === 'test') {
      keyBuffer = crypto.createHash('sha256').update(keyEnv).digest();
    } else {
      throw new Error('BIOMETRIC_ENCRYPTION_KEY must be 32 bytes long');
    }
  }

  if (keyBuffer.length !== 32) {
    throw new Error('BIOMETRIC_ENCRYPTION_KEY must be 32 bytes long');
  }
  SECRET_KEY = keyBuffer;
}

// Initialize on module load
initializeKey();

class BiometricCryptoService {
  encrypt(data) {
    if (!data) return null;
    const text = typeof data === 'object' ? JSON.stringify(data) : String(data);

    const iv = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv(ALGORITHM, SECRET_KEY, iv);

    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');

    const authTag = cipher.getAuthTag().toString('hex');

    return `${iv.toString('hex')}:${authTag}:${encrypted}`;
  }

  decrypt(encryptedString) {
    if (!encryptedString || typeof encryptedString !== 'string') {
      return null;
    }
    const parts = encryptedString.split(':');
    if (parts.length !== 3) {
      throw new Error('Invalid ciphertext format');
    }
    const [ivHex, authTagHex, encryptedText] = parts;
    const iv = Buffer.from(ivHex, 'hex');
    const authTag = Buffer.from(authTagHex, 'hex');
    const decipher = crypto.createDecipheriv(ALGORITHM, SECRET_KEY, iv);
    decipher.setAuthTag(authTag);

    let decrypted;
    try {
      decrypted = decipher.update(encryptedText, 'hex', 'utf8');
      decrypted += decipher.final('utf8');
    } catch (err) {
      throw new Error('Decryption failed');
    }

    try {
      return JSON.parse(decrypted);
    } catch (_) {
      return decrypted;
    }
  }

  decryptWithLegacyKey(encryptedString) {
    if (!encryptedString || typeof encryptedString !== 'string') return null;
    const parts = encryptedString.split(':');
    if (parts.length !== 3) throw new Error('Invalid ciphertext format');
    const [ivHex, authTagHex, encryptedText] = parts;
    const decipher = crypto.createDecipheriv(ALGORITHM, CLAVE_LEGADA(), Buffer.from(ivHex, 'hex'));
    decipher.setAuthTag(Buffer.from(authTagHex, 'hex'));
    let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    try {
      return JSON.parse(decrypted);
    } catch (_) {
      return decrypted;
    }
  }

  keyFingerprint() {
    return crypto.createHash('sha256').update(SECRET_KEY).digest('hex').slice(0, 8);
  }
}

module.exports = new BiometricCryptoService();