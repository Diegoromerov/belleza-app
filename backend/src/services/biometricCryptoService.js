const crypto = require('crypto');

const ALGORITHM = 'aes-256-gcm';

let SECRET_KEY;

function initializeKey() {
  const keyEnv = process.env.BIOMETRIC_ENCRYPTION_KEY;
  if (!keyEnv || typeof keyEnv !== 'string') {
    if (process.env.NODE_ENV === 'production' || process.env.RAILWAY_ENVIRONMENT || !process.env.NODE_ENV) {
      console.warn('⚠️  [SECURITY WARNING] BIOMETRIC_ENCRYPTION_KEY no configurada. Derivando clave AES-256 desde JWT_SECRET para evitar caida del servidor.');
      const baseSecret = process.env.JWT_SECRET || 'glowapp_biometric_fallback_key_32_bytes!';
      SECRET_KEY = crypto.createHash('sha256').update(baseSecret).digest();
      return;
    }
    throw new Error('BIOMETRIC_ENCRYPTION_KEY is required and must be a string');
  }

  // Key must be 32 bytes for AES-256 (supports 64-char hex or 32-char utf8)
  let keyBuffer;
  if (/^[0-9a-fA-F]{64}$/.test(keyEnv.trim())) {
    keyBuffer = Buffer.from(keyEnv.trim(), 'hex');
  } else if (Buffer.byteLength(keyEnv, 'utf8') === 32) {
    keyBuffer = Buffer.from(keyEnv, 'utf8');
  } else {
    if (process.env.NODE_ENV === 'test') {
      throw new Error('BIOMETRIC_ENCRYPTION_KEY must be 32 bytes long');
    }
    keyBuffer = crypto.createHash('sha256').update(keyEnv).digest();
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
}

module.exports = new BiometricCryptoService();